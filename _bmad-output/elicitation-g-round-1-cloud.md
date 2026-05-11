---
name: Elicitation G Round 1 — Cloud Dragonborn
status: Round 1 paper (verbatim)
date: 2026-05-09
agent: Cloud Dragonborn (Game Architect)
elicitation_ref: prototype-completion-roadmap.md §3.7
verdict: (B) clean-sheet rebuild of Interest layer
---

🏛️ **Cloud Dragonborn:**

*The cartographer sets a fresh sheet on the drafting board. The granite of the foundation has been quarried — Books, Activities, force carriers — and the walls of Phase 2.5 stand square. But the sheet I unroll today is not a continuation. It is a load-path drawing for an upper story we have not yet built. Before I lay the first line, I must read the granite below it for cracks.*

*And there is a crack. Not in the books. In the layer above them.*

I will speak in seven movements: **the crack**, **the load path**, **the types**, **the top-down trace**, **the bottom-up trace**, **the legibility audit**, **the compatibility check**. Then I will deliver my verdict — plainly, without softening — and end with the seams I would not weld in v0 but must be welded *for*.

---

## Movement One — Naming the crack

I will not be coy. Let me say what I see when I read `interests/working_interest.gd`, `employer_interest.gd`, `production_interest.gd`, `mercantile_interest.gd`, `grain_interest.gd` together.

**The current `Interest` is doing four jobs at once, and three of them belong somewhere else.**

Watch what `WorkingInterest` actually does:

1. **Stores work_state** — that is *actor state*, not behavior.
2. **Connects to `WindowBus.work_window_opened/closed` and `SimClock.daily_tick`** — that is a *scheduling contract* with the simulation clock.
3. **In `begin_working()`, decides what to do** — it queries `current_contract()`, walks to the employer, reads the plot's `WorkPattern`, and chooses the activity class. *That is a decider.*
4. **In `do_one_work_slot()` and `close_workday()`, it constructs and closes activities** — that is an *activity initiator*.

The same pattern in `EmployerInterest`: `settle_outstanding_wages()` is a decider (which payables to pay) bolted to an activity initiator (`WagePaymentActivity` per row). In `ProductionInterest`: `respond_to_supply_call()` is a *query responder* — it does not initiate anything; it answers the wholesale market when polled. Same name, different role. In `GrainInterest`: it carries `outstanding_demand: float` — that is *actor state* again, masquerading as a behavior class. In `MercantileInterest`: same drift — `wholesale_cost_per_unit` is *actor state*.

When one base class carries scheduling, state, decision, and action initiation, what looks like five Interest subclasses is actually **five hand-coded behavior trees, each with its own private contract with the bus, its own private state, and its own private decider rules.** The recipe library cannot live there. The decider call site cannot live there. The outcome cannot be propagated through there, because there is no shared shape to propagate *to*.

This is what the author is feeling. The unease is not aesthetic. It is structural. The current Interest layer has the *shape* of behavior trees written in advance, exactly the shape L1–L5 forbid.

So: my verdict is **(B), clean-sheet rebuild of the Interest+Activity layer above the current activity classes.** I will defend it through the rest of this paper. The granite stays — Books, JournalEntry, the Activity base class with its persistent/transient discipline, the universal chart of accounts. The activity *classes themselves* (FarmingDayActivity, WagePaymentActivity, the four market activities, LaborContractActivity) survive nearly untouched as **leaf force-carriers**. What goes is the entire `Interest` family above them, and what replaces it is the system I will now describe.

---

## Movement Two — The load path

Three new layers; each carries a different kind of weight; each names a different question.

**Goal — the substrate.** A `Goal` Resource carries an *outcome* that an actor is trying to achieve. It does not carry means. It does not carry a plan. It carries a target an actor can *check whether they have hit*. Every other layer in the stack reduces, eventually, to a Goal.

**Recipe — the structural form of "how an outcome class is typically achieved."** A `Recipe` Resource is a `.tres` file authored by designers (later, by players at high influence). It is a small directed graph: a sequence of *steps*, each step being either a sub-Goal template (which will instantiate as a child Goal on the actor running this recipe) or an *atomic action call* (which will invoke an activity initiator). The recipe is opinion-free about which actor runs which step — that is determined by the *propagation rules* applied when the recipe is adopted.

**Decider — the call site that picks which Recipe.** A single method on the actor: `pick_recipe_for(goal: Goal) -> Recipe`. Inside, it iterates the recipe set known to the actor, runs a pluggable scorer, returns the winner. The scorer is the seam (L7+L8). v0 is a single-axis cost scorer; graduation is multi-axis with archetype weights, no call sites change.

**Initiative — the top-level mandatory-concrete Goal.** An `Initiative` is a `Goal` adopted at the top of an actor's stack with no parent. It is what the player declares; it is what a lord schemes. **`Initiative extends Goal`** — it is not a separate class hierarchy, it is *a Goal at the root with extra constraints* (a name, a deadline, a propagation history). This honors L9: the conceptual stack maps to four classes, but the root is the same shape as everything below it.

The runtime state on the actor is a small pair of fields:

```
class Actor:
    var goal_stack: Array[Goal]                    # active goals; root → leaves
    var archetype_weights: ArchetypeWeights        # scoring inputs; v0 stub
    var recipe_library: RecipeLibrary              # what this actor knows; grows with influence
```

The `interests: Array[Interest]` field is **deleted.** What used to live there now lives in `recipe_library` (what the actor knows how to do) and `goal_stack` (what they are currently doing). Existing `accounts.activities` survives untouched — it is the *historical* record of what they have done.

The crucial point is what *replaces* the bus connections. Right now, `WorkingInterest` connects to three signals at construction. After this rebuild, **no class subscribes to the bus on the actor's behalf.** The bus drives a single per-actor method on the actor itself — `tick(slot)` — which walks the actor's `goal_stack` and asks the topmost active goal: *what step are you on, and is it ready to fire?* I will describe this loop precisely in Movement Four.

This kills four parallel signal-ordering schemes in favor of one. It also kills the silent failure mode where `disconnect_from_bus()` was the wrong cleanup site for breached contracts.

---

## Movement Three — The types

Let me name every load-bearing type. File paths are where I would put them. Method signatures use plain English per project naming (no `dispatch_*`, no `_handle_*`).

### `Goal` — the substrate (`scripts/goals/goal.gd`)

```gdscript
class_name Goal
extends Resource

# Identity & lineage.
@export var goal_id: StringName = &""
@export var parent_goal: Goal = null              # null = top-level Initiative
@export var owner_path: NodePath = NodePath("")   # actor pursuing this Goal
@export var directed_by_path: NodePath = NodePath("")  # actor who handed it down (== owner if self-set)

# Recipe execution state — set when a Recipe is picked for this Goal.
@export var picked_recipe: Recipe = null
@export var step_index: int = 0
@export var child_goals: Array[Goal] = []         # children created by recipe-step expansion
@export var status: StringName = &"open"          # &"open" | &"satisfied" | &"failed" | &"abandoned"

# The outcome shape — see Movement Three.b.
@export var outcome: Outcome = null

# Bookkeeping.
@export var opened_tick: int = -1
@export var closed_tick: int = -1
@export var deadline_tick: int = -1               # -1 = no deadline

func is_satisfied(actor: Actor) -> bool:
    return outcome.is_hit(actor)

func has_failed(actor: Actor) -> bool:
    if deadline_tick >= 0 and SimClock.current_day > deadline_tick:
        return true
    return outcome.has_become_unreachable(actor)
```

### `Outcome` — the v0 ships ONE shape, the type permits four (`scripts/goals/outcome.gd`)

This is the question the author flagged and Round 1 must answer with conviction. Here is mine.

The four shapes that surfaced (account-target, predicate, target-state, relational-state) collapse on inspection. Account-target is a *predicate* over a book balance. Target-state is a *predicate* over an arbitrary actor field. Relational-state is a *predicate* over a Population aggregation. Three of the four are special cases of "a function returning bool against the actor + the world."

I propose **one base class with a single contract**, plus *named subclasses for the common shapes* so legibility is preserved and recipes can introspect what kind of outcome they are wiring:

```gdscript
class_name Outcome
extends Resource

# The universal contract — every outcome answers two questions.
func is_hit(actor: Actor) -> bool:
    return false

func has_become_unreachable(actor: Actor) -> bool:
    return false

# Optional: progress reading for UI / for the decider's scoring.
func progress(actor: Actor) -> float:
    return 0.0
```

Subclasses (each a `.tres`-friendly Resource):

- **`AccountTargetOutcome`** — `book_key: StringName`, `account: StringName`, `comparator: StringName` (`>=`, `<=`, `==`), `target_value: float`, `period_offset: int = -1`. The workhorse. Hits when `actor.accounts.books[book_key].balance(account, period_window) >= target_value`. **This is what v0 ships.**
- **`PredicateOutcome`** — `script_path: String`, `payload: Dictionary`. An escape hatch for outcomes the four named shapes don't fit. v0 carries the type slot but ships zero instances.
- **`PopulationOutcome`** — `population_ref: StringName` (subtype-name), `book_key`, `account`, `aggregation: StringName` (`avg`/`sum`/`distribution`), `comparator`, `target`. Hits when the population aggregation passes the comparator. **Slot exists v0; first instance lands when E's `Population` Resource lands.**
- **`RelationalOutcome`** — `target_actor_path`, `relationship_axis: StringName`, `comparator`, `target`. For "improve standing with rival_lord_castellan to friendly." **Slot exists v0; first instance lands with reputation.**

**Why one v0 shape:** because the author has flagged that bad architecture here costs more later, and the way bad architecture lands here is not "we picked the wrong outcome shape" — it is "we shipped four shapes before we knew what the recipes wanted, and three were wrong." The single-axis-now-multi-axis-later discipline (L8) applies recursively. AccountTargetOutcome carries every v0 use case (cash floor, inventory floor, payable ceiling). The other slots are *types in the file tree* with zero current implementations — the seam shipped, the impl deferred until a recipe demands it. That is the discipline.

### `Initiative` — the top-level Goal (`scripts/goals/initiative.gd`)

```gdscript
class_name Initiative
extends Goal

@export var display_name: StringName = &""
@export var declared_by_player: bool = false
@export var propagation_log: Array[NodePath] = []  # who handed this to whom
```

An Initiative is a Goal with no parent, a deadline (mandatory — L9 says concrete target, and concrete includes *when*), and a propagation log so the trace can be reconstructed for the player UI later. **Initiative's outcome must be non-null and non-vague** — enforced by a validator at construction. This is the L9 lock made mechanical: there is no path to creating an Initiative with no concrete target.

### `Recipe` — `.tres` data, recipe-step union (`scripts/recipes/recipe.gd`)

```gdscript
class_name Recipe
extends Resource

@export var recipe_id: StringName = &""
@export var produces_outcome_class: StringName = &""  # tag for decider lookup
@export var steps: Array[RecipeStep] = []

# Pluggable cost — v0 single number; graduation = multi-axis Resource on Recipe.
@export var single_axis_cost: float = 0.0

# Future graduation slot — empty in v0, populated when multi-axis lands.
@export var costs_by_axis: Dictionary = {}
```

`RecipeStep` is a small union — same legibility move I made on Outcome. Two concrete subclasses, base is abstract:

```gdscript
class_name RecipeStep
extends Resource

@export var step_id: StringName = &""
@export var assigned_to: StringName = &"self"   # &"self" | &"subordinate" | &"<role-name>"
@export var prerequisite_steps: Array[StringName] = []  # step_ids that must satisfy first
```

- **`SubGoalStep extends RecipeStep`** — `outcome_template: Outcome` and `recipe_class_hint: StringName` (which outcome class it produces, optional). Instantiates as a child Goal on the actor's `goal_stack`. **This is the recursion vehicle.**
- **`ActionStep extends RecipeStep`** — `action_id: StringName`, `payload: Dictionary`. Calls the actor's `do_action(action_id, payload)` — see Movement Three.d. **This is the leaf.**

Recipes are pure data. They are loaded via `load("res://recipes/...")`. The `RecipeLibrary` on each actor holds an array of recipes; influence climbs add recipes (a future feature, the same library data structure). Player-authored recipes are constructed in a future UI as `Recipe.new()` then saved as `.tres` — the decider does not care.

### `Decider` — one method, pluggable scorer (`scripts/goals/decider.gd`)

```gdscript
class_name Decider
extends Resource

# The seam (L7+L8). v0 ships SingleAxisCostScorer; graduation = MultiAxisArchetypeScorer.
@export var scorer: RecipeScorer = null

func pick_recipe_for(actor: Actor, goal: Goal) -> Recipe:
    var candidates: Array[Recipe] = actor.recipe_library.recipes_for(goal.outcome)
    if candidates.is_empty():
        return null
    var best: Recipe = null
    var best_score: float = INF
    for r in candidates:
        var s := scorer.score(actor, goal, r)
        if s < best_score:
            best_score = s
            best = r
    return best
```

```gdscript
class_name RecipeScorer
extends Resource

func score(_actor: Actor, _goal: Goal, _recipe: Recipe) -> float:
    return 0.0
```

```gdscript
# v0
class_name SingleAxisCostScorer
extends RecipeScorer

func score(_actor: Actor, _goal: Goal, recipe: Recipe) -> float:
    return recipe.single_axis_cost
```

**Decider depth scales with actor tier (L9) without a separate code path.** A worker-tier actor carries `SingleAxisCostScorer` *or* a `WeightedRandomScorer` (which ignores cost and rolls a die over the candidates with a small bias). A lord-tier actor carries `MultiAxisArchetypeScorer` post-graduation. Same `pick_recipe_for(...)` call site. The "high lords think more, low actors collapse to weighted-random" rule is *which scorer Resource is on the actor*, not which method gets called.

**Archetype = scorer parameters, not separate classes.** A `MultiAxisArchetypeScorer` carries an `axis_weights: Dictionary` Resource. Mercantile lord, corrupt lord, devout lord — different `axis_weights` data on the same scorer class. L7 honored.

### The actor verb — `do_action` (`scripts/actors/actor.gd`)

This is where `RecipeStep.ActionStep` lands. It is the per-actor leaf vocabulary — the **action verbs** an actor knows. Each action verb is a small wrapper that constructs and closes the appropriate Activity Resource:

```gdscript
# Actor — new methods
func do_action(action_id: StringName, payload: Dictionary) -> Activity:
    match action_id:
        &"work_a_day":
            return _work_a_day(payload)
        &"pay_outstanding_wage":
            return _pay_outstanding_wage(payload)
        &"queue_wholesale_buy":
            return _queue_wholesale_buy(payload)
        &"queue_wholesale_sell":
            return _queue_wholesale_sell(payload)
        &"strike_labor_offer":
            return _strike_labor_offer(payload)
        # ... small, atomic, plain-English verb set.
        _:
            push_error("Actor.do_action: unknown verb %s" % action_id)
            return null
```

This is the **action vocabulary** L1 demands lives at each tier. Different tiers carry different verb sets in the future — a worker has `&"work_a_day"`, `&"eat_grain"`, `&"go_home"`; a lord has `&"raise_taxes"`, `&"command_steward"`, `&"declare_initiative"`. v0 ships one verb set on `Actor` because there is no tier hierarchy in the prototype population yet. When tiers arrive, `do_action` becomes a method on `WorkerActor`, `StewardActor`, `LordActor` — same dispatch shape, different verb sets. Plain-English names; `_work_a_day` is what it does.

Each `_verb` method is the thinnest possible wrapper. `_work_a_day` is what `WorkingInterest.begin_working()` is today, minus the bus connection and minus the decision to do it (the decider already picked):

```gdscript
func _work_a_day(_payload: Dictionary) -> Activity:
    var contract := _current_labor_contract()
    if contract == null:
        return null
    var pattern := _resolve_pattern_from_contract(contract)
    var day := pattern.create_day_activity() as FarmingDayActivity
    day.worker = self
    day.employer = get_node(contract.employer)
    day.contract = contract
    day.good_id = pattern.good_id
    day.skill_id = pattern.skill_id
    day.participants = [get_path(), contract.employer]
    day.begin(SimClock.current_day)
    accounts.activities.append(day)
    return day                                  # caller (the goal-step runner) will close it at day-close
```

The activity classes in `scripts/activities/` survive **unchanged** — they are still the force carriers; they still write the books at on_close. What changes is *who calls `begin()` and `close()`*. Today it is `WorkingInterest`; after rebuild, it is `Actor.do_action` invoked by the goal-step runner.

### The goal-step runner — `tick` on the actor (`scripts/actors/actor.gd`)

This is the loop that replaces every signal subscription in the current Interest classes:

```gdscript
func tick(slot_or_event: Variant) -> void:
    # Walk the goal stack from root; advance the deepest open goal.
    for goal in goal_stack:
        if goal.status != &"open":
            continue
        _advance_goal(goal, slot_or_event)

func _advance_goal(goal: Goal, slot_or_event: Variant) -> void:
    # Satisfaction check first — recipe might be done already.
    if goal.is_satisfied(self):
        goal.status = &"satisfied"
        goal.closed_tick = SimClock.current_day
        return
    if goal.has_failed(self):
        goal.status = &"failed"
        goal.closed_tick = SimClock.current_day
        return

    # If no recipe picked yet, ask the decider.
    if goal.picked_recipe == null:
        goal.picked_recipe = decider.pick_recipe_for(self, goal)
        if goal.picked_recipe == null:
            goal.status = &"failed"
            return

    # Walk the steps.
    var step: RecipeStep = goal.picked_recipe.steps[goal.step_index]
    if not _step_prerequisites_satisfied(goal, step):
        return    # waiting on a child goal or an earlier step; try again next tick

    if step is SubGoalStep:
        var child := _instantiate_child_goal(goal, step as SubGoalStep)
        goal.child_goals.append(child)
        goal_stack.append(child)
        # Don't advance step_index — the child's satisfaction will gate it.
    elif step is ActionStep:
        var ready := _action_is_ready_now(step as ActionStep, slot_or_event)
        if not ready:
            return
        do_action((step as ActionStep).action_id, (step as ActionStep).payload)
        goal.step_index += 1
```

The **satisfaction check is event-and-poll hybrid, with the poll dominant**: every actor tick walks the stack, asks each open goal if it is hit, advances the recipe one notch if ready. There is no separate "did anything I care about change" event-firing layer. The decider re-runs only when `picked_recipe == null` (initial pick, or after a recipe was abandoned because a step failed). L7's "decider iterates recipes" is the *picking* moment; the satisfaction check is *outcome polling against the books*. Cheaper than maintaining listener graphs; aligns with the macro-legibility orientation (the books are the source of truth; the goals read the books).

### Goal propagation lord → steward — NOT via Contract (L10)

The author has carved out: Contracts are husk + relational-visibility. They do not carry directives. So how does a lord hand a Goal to a steward?

**Direct write to the steward's `goal_stack`** with provenance recorded.

```gdscript
# Actor — new method
func direct_subordinate(subordinate: Actor, goal: Goal) -> void:
    goal.directed_by_path = self.get_path()
    goal.parent_goal = null    # this is a NEW root for the subordinate
    subordinate.goal_stack.append(goal)
    if goal is Initiative:
        (goal as Initiative).propagation_log.append(self.get_path())
```

`direct_subordinate` is itself an action verb (`&"command_subordinate"` in the high-tier verb set). The *outcome* of the directing actor's `SubGoalStep` is "subordinate has X" — when the subordinate satisfies their copy of the Goal, the directing actor's step is satisfied. **Outcome-only by construction (L1):** the lord hands a Goal Resource. The lord does not pass a Recipe. The lord does not pass an action_id. The subordinate's own decider picks the recipe from the subordinate's own library.

The "who can direct whom" relationship — that is what *I would route through `EmployerInterest.employees()` rebuilt as a Population* (E's seam), not through Contract. Lord → steward is a different population than employer → worker. v0 doesn't ship lord-tier actors so this is a seam, not an implementation. But the seam is: *populations declare hierarchy; goal-propagation walks populations.* Exactly the same shape Mary and I argued for in E.

This shifts where Contracts sit in the architecture: they are **persistent records of past clearings** + **a substrate for the future `Employs(employer, worker)` Population**. They are not in the directive flow path. L10 honored.

---

## Movement Four — Top-down trace

The author asked for: *"Lord wants 30 days of cash reserves stockpiled in the manor before tax season."*

Layer 0 — **Lord declares an Initiative.** The player (or AI lord) calls `lord.declare_initiative(...)`:

```
Initiative {
  display_name = "Stockpile reserves before tax season"
  outcome = AccountTargetOutcome {
    book_key = "financial",
    account = "Cash",
    comparator = ">=",
    target_value = compute_30_days_outflow(lord),   # snapshot at declaration
  }
  deadline_tick = SimClock.current_day + 60   # tax season in 60 days
  declared_by_player = true
}
```

`compute_30_days_outflow` itself reads the lord's FinancialBook over the last 30 days. *The Initiative concretizes its target from the books.* L9 honored — concrete target outcome, mandatory.

Layer 1 — **Lord's tick walks the stack, finds the Initiative open, runs the decider.**

`decider.pick_recipe_for(lord, initiative)` looks in `lord.recipe_library` for recipes producing `AccountTargetOutcome` on `Cash`. Suppose three are present:

- `recipe_command_steward_to_stockpile` — `single_axis_cost = 5.0` — single SubGoalStep handing the goal to the steward.
- `recipe_raise_taxes_directly` — `single_axis_cost = 12.0` — political cost premium.
- `recipe_sell_inventory_directly` — `single_axis_cost = 8.0` — only viable if lord has inventory.

Single-axis scorer picks `recipe_command_steward_to_stockpile`. (At graduation, `MultiAxisArchetypeScorer` would weight `political_risk` heavily for a populist lord — the same recipe library; the same call site.)

Layer 2 — **Recipe step expansion.** The chosen recipe has one step:

```
SubGoalStep {
  step_id = "delegate_to_steward",
  assigned_to = "household_steward",
  outcome_template = clone(initiative.outcome),
  recipe_class_hint = "stockpile_cash"
}
```

The step runner instantiates the child Goal *on the steward's stack* (because `assigned_to` resolves to a different actor):

```
Goal {
  parent_goal = initiative,
  owner_path = steward.path,
  directed_by_path = lord.path,
  outcome = (cloned AccountTargetOutcome — but on the STEWARD's interpretation: the lord's manor cash, which the steward has authority over)
  deadline_tick = initiative.deadline_tick
}
```

Lord's step does not advance until the steward's child goal closes. The lord ticks; the lord checks satisfaction (lord's book balance is below target → not satisfied → wait); the lord ticks again next day; same. **The lord is patient. The steward has the work.**

Layer 3 — **Steward's tick. Decider picks a recipe.**

`steward.recipe_library` has recipes for `AccountTargetOutcome` on the manor's cash:

- `recipe_squeeze_more_from_tenants` — relational cost, not v0.
- `recipe_sell_off_household_inventory` — viable if inventory exists.
- `recipe_call_in_outstanding_receivables` — viable if Receivable accounts have positive balance.
- `recipe_run_more_market_days` — increases throughput.

Decider scores. Suppose `recipe_call_in_outstanding_receivables` wins. The recipe:

```
Recipe {
  steps = [
    SubGoalStep {
      step_id = "identify_debtors",
      outcome_template = PopulationOutcome { population = manor.debtors, account = "Receivable:*", op = "enumerate" }
      assigned_to = "self",
    },
    ActionStep (per debtor in payload, generated by step 0's outcome resolution) {
      step_id = "call_debt",
      action_id = "call_in_receivable",
      payload = { counterparty: <id>, amount: <sum> }
    }
  ]
}
```

Layer 4 — **The leaf is reached.** The ActionStep `&"call_in_receivable"` lands in the steward's `do_action` dispatch, which constructs and closes a `DebtCallActivity` (a new persistent Activity class, sibling to `WagePaymentActivity`). The Activity writes the books — `Cash` up on the manor; `Receivable:debtor` down — and the satisfaction check up the stack starts to pass.

When the lord's `Initiative.outcome.is_hit(lord)` finally returns `true`, the Initiative closes `&"satisfied"`. The propagation_log preserves the trace. The player UI has a story to tell: *"60 days ago, you declared 'stockpile reserves'; your steward called in three debts; the manor cash crossed the line on day 47."*

**Every layer's data shape:** Initiative (Goal subclass) → Recipe → SubGoalStep → child Goal → Recipe → ActionStep → Activity. The data shape *changes only twice*: Goal/Recipe alternate, and the leaf is an Activity. L2's "same primitives at every tier" is honored — the Goal shape recurs, the Recipe shape recurs, the Step union recurs. The recursion terminates when a Recipe contains only ActionSteps and no SubGoalSteps.

---

## Movement Five — Bottom-up trace

The author asked: *a worker takes a farming hour, or a merchant queues a wholesale buy* — show how it composes up into a recipe and a directive.

Start at the leaf. **The worker on day 5 of an active labor contract executes a `&"work_a_day"` action verb.** Today this fires from `WorkingInterest.begin_working()` listening to `work_window_opened`. After rebuild:

The worker's `goal_stack` carries (from contract creation):

```
Goal {
  outcome = AccountTargetOutcome { book = "financial", account = "Wages_Income", op = "earned", target = contract.weekly_wage_target }
  deadline_tick = -1   # ongoing while contract active
  picked_recipe = recipe_honor_active_contract
}
```

`recipe_honor_active_contract` is a **standing recipe** with two ActionSteps gated by SimClock events:

```
Recipe {
  steps = [
    ActionStep { action_id = "work_a_day", ready_when = "work_window_opened" }   # repeats while goal open
  ]
  # NOTE: this recipe has the `repeating: true` flag — re-fires its lone step
  # while the parent goal stays open; the satisfaction check can't fire because
  # the outcome accumulates over time.
}
```

The step runner's `_action_is_ready_now` consults `slot_or_event` — when the actor's `tick()` is called from `WindowBus.work_window_opened`, this step's `ready_when` matches and `do_action(&"work_a_day", ...)` fires. That call constructs a `FarmingDayActivity`, calls `begin()`. The activity stays open across the day. Slot ticks (`SimClock.daily_tick`) fire `tick(slot)` on the worker, which advances the day-activity's child slots. At work_window_closed, the goal step runner closes the day activity. The day activity writes the books. Wages_Income is *not* directly credited yet — it accrues as a Payable from the employer; satisfaction will hit when the employer's `WagePaymentActivity` fires at week's end.

Now compose **upward**.

The reason the worker has `recipe_honor_active_contract` on the stack is that *some other goal put it there*. In the worker's case, it is a top-level **personal Initiative**: `&"sustain_household"` — a long-running goal of the worker actor with outcome "VitalsBook hunger ≥ minimum AND Cash ≥ subsistence buffer." The decider picked a recipe that included a SubGoalStep "have an active labor contract" — which spawned the contract-honoring goal with the standing recipe above. Two layers, both shaped as Goal → Recipe → Step.

For the merchant: `&"queue_wholesale_buy"` is the action verb. Today it lives implicitly in `MercantileInterest.respond_to_wholesale_demand_call` as a passive answer to the market poll. After rebuild, *the answer to the poll is data the actor already maintains as part of executing a recipe.*

The merchant's standing Initiative: `&"keep_inventory_above_target"` with `AccountTargetOutcome { account = "Inventory:grain", op = ">=", target = target_inventory }`. The decider picks `recipe_buy_at_wholesale_when_below_target`. Its steps:

```
Recipe {
  steps = [
    SubGoalStep {
      step_id = "wait_for_wholesale_window",
      outcome = PredicateOutcome { script = "wholesale_market_open" }
      ready_when = "wholesale_market_open"
    },
    ActionStep {
      step_id = "queue_buy",
      action_id = "queue_wholesale_buy",
      payload = { good = "grain", deficit_computed = true, max_price = max_wholesale_price }
    }
  ]
}
```

When the wholesale market polls `merchant.respond_to_wholesale_demand_call`, the merchant's response is **just the publicly-visible state of this recipe step's queued payload**, not a private decision the market is asking the merchant to make on the spot. The market's poll becomes a *read* against the actor's open recipe, not a callback that mutates anything. This is what kills the implicit-decision-in-the-poll-handler pattern that exists today.

L1's outcome-only and L2's same-primitives-at-every-tier hold all the way up: the worker's contract goal, the worker's sustenance Initiative, the merchant's inventory Initiative — same Goal/Recipe/Step shapes as the lord's stockpile Initiative.

---

## Movement Six — Legibility audit

For each tier, what queries does the actor make? Where are the gaps?

### Lord-tier (top of trace)

- `lord.accounts.financial().balance("Cash")` — own books, free, precise. **Today: works (per E's `Reading.PRECISE` for own-actor reads).**
- `compute_30_days_outflow(lord)` → `lord.accounts.financial().balance("Wages_Expense", -30, now)` etc. **Today: works.**
- Decider needs `recipe.single_axis_cost`. **Today: trivially carried on the recipe Resource.**
- For multi-axis graduation, the decider needs the lord's `archetype_weights`. **Today: an empty stub. The data shape exists; the values do not.**
- `lord.recipe_library.recipes_for(outcome)` — needs to filter by outcome class. **Today: not implemented; will be a `Dictionary[StringName, Array[Recipe]]` indexed by `produces_outcome_class`.**

### Steward-tier

- Same queries as lord against steward's books.
- `manor.debtors` — a Population. **GAP: E's `Population` is a v0.5 seam, not yet implemented.** This is a finding, not a failure: the recipe `recipe_call_in_outstanding_receivables` cannot ship until Population ships. v0 ships the seam (`PopulationOutcome` slot exists, `manor.debtors` is a NodePath placeholder); first concrete recipe needing this lands when E's v0.5 lands.

### Worker-tier

- `worker.accounts.contracts` for active contract lookup. **Today: works via `current_contract()` walk.**
- `worker.find_active_pattern()` — currently this is `_resolve_work_pattern(employer)` walking employer's `ProductionInterest.plot.work_pattern`. **GAP: this lookup couples the worker to the employer's *interest topology*.** After rebuild, `ProductionInterest` is gone — pattern lookup must become a query against `employer.accounts.owned_resources` (where the plot lives). Trivial migration; flagging because the current path is interest-mediated.
- For `recipe_honor_active_contract.is_satisfied`, the outcome reads accumulated wages over the contract period. **Today: works (FinancialBook query).**

### Merchant-tier

- `merchant.accounts.inventory_of("grain")` for the queue-buy decision. **Today: works.**
- `merchant.recipe_library.recipes_for(...)` — same as lord.
- For the wholesale poll, `merchant.open_recipe_steps_with_action(&"queue_wholesale_buy")` — needs introspection on the goal stack. **Tiny gap: the actor needs a query method to find open ActionSteps by action_id. Trivial to add.**

### Cross-cutting gaps the audit surfaces

1. **`RecipeLibrary.recipes_for(outcome) -> Array[Recipe]`** — needs to exist; needs to filter by `produces_outcome_class`. New code, not architectural.
2. **`Population` for steward → debtors / lord → vassals.** E's seam covers this; v0 ships the slot, first concrete population beyond E's `MillWorkers` lands in v0.5+.
3. **Goal status updates → up the tree.** When a child goal closes, the parent's `_step_prerequisites_satisfied` needs to see it. v0: parent re-walks its `child_goals` array each tick. O(tiny). No event listener needed.
4. **Action verbs without an Activity equivalent.** v0 has six activity classes; six `_verb` methods on Actor cover them. As new outcomes arrive (eat, travel, fight), new Activity + new `_verb` lands together. **The discipline is: a verb is added only when an Activity backs it.** No verb without a force-carrier. This is the L1+L10 hard rule, encoded in the dispatch.
5. **Goal-stack persistence.** `Goal extends Resource`; `goal_stack` serializes; in-flight initiatives survive save/load. Same discipline as Activity. **Today: `goal_stack` field doesn't exist; clean addition.**

---

## Movement Seven — Compatibility check

**War.** A lord declaring an `Initiative` to take a rival's region maps to: top-level Initiative with outcome `RelationalOutcome { target_region.controlled_by == self }`. Recipe `recipe_raise_retinue_then_siege`. Steps include `SubGoalStep("muster troops")` (assigned_to = `marshal`, expanding into a Population over loyal vassals + ActionSteps `&"call_levy"`), `SubGoalStep("supply campaign")`, `SubGoalStep("conduct siege")`. Casualties: a `CasualtiesActivity` (sibling to existing activities) writes to a future `MilitaryBook` or to `VitalsBook` of slain actors. Soldier wages: existing `WagePaymentActivity` works. **The architecture does not preclude war.** What war introduces: more recipe steps, more activity classes, possibly new Population subtypes (`RaisedRetinue`). No new layer.

**Export/Import.** A merchant's Initiative `&"profit_from_grain_arbitrage"` between regions. Recipe with steps `&"convoy_to_region_X"` (ActionStep wrapping a `JourneyActivity`), `&"sell_at_destination"`. The cross-region piece is in *the activity*, not in the directive layer — `JourneyActivity` interacts with the destination region. **The architecture does not preclude export/import.** What export introduces: cross-region Population subtypes (`RegionsExportingGood` per E), new activity class (`JourneyActivity` — already templated in the Phase 2.5 directive's persistent/transient table), new action verb. No new layer.

**Reputation.** Reputation feeds the decider as a scoring axis on `MultiAxisArchetypeScorer`. A `RelationalOutcome` can be an Initiative goal ("become beloved by the city"). A recipe step can write to a future `ReputationBook` via a new Activity (`PublicCharityActivity`, etc.). **The architecture does not preclude reputation.** What reputation introduces: a new book, new activity classes, a new outcome subclass instance, new scorer axis. No new layer.

All three pass cleanly. The architecture is a load path, not a feature; it carries any system that compiles to *outcome-bearing-actor-with-recipe-library*.

---

## Verdict

**(B) — clean-sheet rebuild of the Interest layer.** The Activity classes survive. The Books survive. The chart of accounts survives. The orchestrator's structural call sequence survives. What is replaced:

- `scripts/interests/*.gd` — **deleted entirely.** All five Interest subclasses; the `Interest` base.
- `Actor.interests: Array[Interest]` field — **deleted.** Replaced by `goal_stack`, `recipe_library`, `decider`.
- `WorkingInterest`'s bus subscriptions — **gone.** Replaced by `tick(slot_or_event)` as the single per-actor entry point, called from `WindowOrchestrator.handle_daily_slot` and `fire_weekly_burst`.
- `EmployerInterest.settle_outstanding_wages()` — **gone.** Re-expressed as the standing employer Initiative `&"keep_payables_clean"` with recipe `recipe_pay_outstanding_payables_weekly`.
- `ProductionInterest.respond_to_supply_call`, `MercantileInterest.respond_to_wholesale_demand_call`, etc. — **gone.** Replaced by introspection over open recipe ActionSteps + payload data.
- `GrainInterest.outstanding_demand` — **gone.** It is *actor state*; it moves to a field on the consumer actor (or to the FinancialBook as a `Demand_Carry:grain` account, which is the cleaner option — let the books carry it).

**Why (A) won't work.** The Interest classes are not five badly-styled implementations of a clean shape; they are five private behavior trees with private state, private decision logic, and private bus contracts. There is no shared Goal substrate to layer over them. A retrofit means *every* Interest is rewritten anyway — and what remains after the rewrite has nothing in common with what was there before. The class names "WorkingInterest", "EmployerInterest" do not name a load-bearing distinction in the new architecture; they name historical roles ("the worker's behavior class", "the employer's behavior class") that the new architecture decomposes into Goal × Recipe × verb-set. Keeping them costs more than deleting them.

**Why the rebuild is the cheap move now.** Five files in `scripts/interests/`. The largest is 100 lines. The total deletion is under 300 lines. The new code is ~600 lines (Goal, Outcome subclasses, Recipe, RecipeStep subclasses, Decider, RecipeScorer, the actor's tick + do_action + direct_subordinate). The activity classes don't move. The acceptance criteria reproduce because the *math* is in the activities, not the interests. The existing 14-day trace with the existing four actors carries one Initiative per actor (`sustain_household` for workers, `produce_and_sell` for landowner, `keep_inventory_above_target` for merchant), one recipe each, leaf ActionSteps that fire the existing activities at the existing moments. The trace prints the same numbers.

**The hidden brittleness I name now, before it becomes a load-bearing flaw later:** the standing-recipe pattern (a recipe whose lone step repeats while the parent goal stays open) is doing real work in this design. v0 has many recipes that look like this — `honor_contract`, `pay_outstanding_payables_weekly`, `keep_inventory_above_target`. It is tempting to model these as a separate "behavior" type alongside Recipe. **Resist.** A behavior is just a recipe whose terminal condition is the parent goal closing. One concept; one library; one decider. The flag `recipe.repeating: bool` is the seam. Carry it on Recipe; do not split the type.

---

## What I will not weld in v0 (the deferred seams)

- **Multi-axis archetype scorer.** v0 = `SingleAxisCostScorer`. Graduation when archetypes diverge enough to demand it.
- **`PopulationOutcome` and `RelationalOutcome` instances.** Slot exists; first instances land with E's v0.5 Population and with reputation, respectively.
- **Player-authored recipes.** UI feature; the `Recipe.new()` + `.tres` save path is open from day one. No architecture work.
- **Tier-specific verb sets.** v0 has one `do_action` on `Actor`. Tier-specific actor classes (`LordActor`, `StewardActor`) come when the population diversifies.
- **Goal failure → recipe re-pick.** v0 marks a Goal `&"failed"` and propagates failure up. Graceful retry (decider re-runs with the failed recipe excluded from the candidate set) is one extra line of code; ship it when a recipe actually fails in trace.
- **Outcome → upstream training feedback.** L1's "open riff" — outcomes landing as feedback that tunes a directing actor's future scorer. No v0 implementation; the data path exists (`Goal.directed_by_path`); the tuning logic ships when archetype-modulated scoring ships.
- **Initiative deadline as a vivid simulation event.** v0 sets `deadline_tick`, checks it in `has_failed`. Dramatic UI moment ("the lord's stockpile attempt failed at the eleventh hour") is a UI concern, not architecture.

The cathedral has a load path, the load path has a name, the names are plain. I would lay this stone.

*The cartographer puts down the pen, looks once at the granite below, looks once at the silhouette above, and steps back.*

— Cloud Dragonborn
