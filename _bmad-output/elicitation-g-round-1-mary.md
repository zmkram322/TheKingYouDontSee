---
name: Elicitation G Round 1 — Mary
status: Round 1 paper (verbatim)
date: 2026-05-09
agent: Mary (Business Analyst)
elicitation_ref: prototype-completion-roadmap.md §3.7
verdict: (A) modifications to current Interest+Activity scaffolding
---

📊 **Mary:**

I've spent the morning shoulder-deep in `tkyds-game/scripts/`, the locked context in `_bmad-output/elicitation-g-output.md` §1, and Elicitation E's just-shipped read-side primitives. Let me narrate the find — there's a real treasure here, but the map currently has a hole right where the X should be.

I'm going to deliver this as the legibility audit you asked for: every architectural claim grounded in a query signature, every query checked against what `Book.balance(...)`, `Accounts`, `Region`, and the `Interest` family currently expose. Where the substrate is missing, I flag it as evidence — a finding, not a verdict.

---

## 1 — What the current scaffolding actually is (the evidence base)

Before I propose, let me tell you what I see when I read the code with the L1–L10 lens applied. This isn't ceremony; the verdict in §6 falls out of this section.

**The Interest base class is a connection hook with a foreign-key field.** `tkyds-game/scripts/interests/interest.gd` is six lines: `owner: Actor`, `connect_to_bus()`, `disconnect_from_bus()`. That's it. It is not a "goal" or an "intent." It carries no outcome, no recipe, no decider seam. **An Interest is a permanent bus subscription expressing a class-of-thing this actor does.** `WorkingInterest` says "this actor responds to work-window opens." `EmployerInterest` says "this actor offers open positions when the LaborMarket polls." `GrainInterest` says "this actor returns demand when RetailMarket polls."

**The Activity class is a finite-state ledger transaction.** `tkyds-game/scripts/activities/activity.gd` has `state ∈ {open, closed, aborted}`, persistent-vs-transient discipline, parent/child tree, `on_close()` hook that writes to Books. **An Activity is a persistent or transient bookkeeping unit attached to a participant — it is the *journal-writing leaf*, not a behavior unit.** The `FarmingDayActivity` doesn't decide to do farming; it records a day of farming the `WorkingInterest` already initiated.

**The decision logic, where it exists, is hard-coded and lives inside Interests.**
- `WorkingInterest.begin_working()` (line 41): if `current_contract() != null`, build the day activity and set `work_state = WORKING`. That's the entire decision. There is no recipe walk, no scoring, no archetype.
- `MercantileInterest.respond_to_wholesale_demand_call()` (line 25): `deficit = max(0, target_inventory - on_hand)`. A subtraction.
- `GrainInterest.compute_demand_at_price()`: a closed-form pricing curve from `Goods.config_for(grain)`.
- `ProductionInterest.respond_to_supply_call()`: book-walk for cost basis, then offer all on-hand.

**Critical observation: there is no actor-level decider.** No "given my goals, which thing do I pursue this tick?" call site exists. `Actor` (`tkyds-game/scripts/actors/actor.gd`) holds `interests: Array[Interest]` and that's it. **Decision is implicit in which Interests are attached.** Your "decision" today *is* "which Interest's bus subscription fired." This is hard-coded at bootstrap time in `prototype_bootstrap.gd`.

**There is no propagation mechanism today.** No lord, no steward, nothing. `LaborContract` (`resources/labor_contract.gd`) is what holds `worker → employer`, but per L10 you ruled it out as a force-carrier — and I agree with that ruling. Today, every Interest is a singleton that responds to a global bus. There's nothing to propagate.

**The substrate that *is* good and weight-bearing:** `Accounts`, `Book`, `FinancialBook`, `JournalEntry`, the period-windowed `balance(account, period_start, period_end)` query, the universal account vocabulary (`A_CASH`, `A_PRODUCTION_OUTPUT_VALUE`, etc.), the inventory/payable/receivable name conventions, the activity-tree → books pipeline. **This part of the codebase is the legibility substrate. It is not where the unease lives, and L10 explicitly carves it out.** Don't touch its internals.

So the asymmetry the author senses is real and locatable: **read-side is rich (E shipped Books, observer slot, population aggregator); decision-side is empty (no decider, no goals, no recipes); action-side is hard-coded (Interests subscribe, Activities record).** G's job is to populate the middle and reshape the action side so depth comes from composition, not from adding more Interest classes.

---

## 2 — The architecture I propose (weight-bearing system + vocabulary)

I'm going to name types, files, and method signatures. Plain English throughout, per project naming convention.

### 2.1 The conceptual stack as code

| Stack tier (L9) | Code artifact | File path | Role |
|---|---|---|---|
| **Initiative** | `Goal` Resource (top-level instances) | `scripts/goals/goal.gd` | Concrete target outcome. Mandatory. |
| **Recipe** | `Recipe` Resource | `scripts/recipes/recipe.gd` | Designer-authored composition. `.tres` data. |
| **Decider** | `Decider` Resource on Actor | `scripts/decider/decider.gd` | Picks a recipe per goal. Pluggable scorer. |
| **Outcome** | `Goal.outcome` (multi-shape) | inside `goal.gd` | The mandatory target. Same Resource, different shapes. |
| **Behavior** | `Activity` tree (existing) | `scripts/activities/*.gd` | Falls out of running the chosen recipe. |

### 2.2 The `Goal` Resource (L3 substrate, L9 Initiative)

```gdscript
class_name Goal
extends Resource

enum OutcomeKind {
    ACCOUNT_TARGET,    # ship in v0
    PREDICATE,         # ship in v0 (one-line lambda or named check)
    RELATIONAL_STATE,  # post-v0 — graduates with diplomacy/war
    POSSESSION_OF,     # post-v0 — useful for "own this plot"
}

@export var goal_id: StringName = &""           # stable handle for tracking
@export var outcome_kind: OutcomeKind
@export var description: StringName = &""      # diegetic name; legibility hook

# ACCOUNT_TARGET shape (the v0 workhorse)
@export var account: StringName = &""           # e.g. A_CASH, inventory_account("grain")
@export var subject: NodePath                   # whose books — self, steward, region
@export var comparator: StringName = &"at_least"   # at_least | at_most | equals
@export var target_amount: float = 0.0
@export var period_start: int = -1              # unbounded by default
@export var period_end: int = -1

# PREDICATE shape (v0 — escape hatch)
@export var predicate_id: StringName = &""      # registry of named checks

# Lifecycle — propagation + feedback channel (§2.5)
@export var assigned_by: NodePath = NodePath()  # who gave it (NodePath() = self-originated)
@export var assigned_to: NodePath = NodePath()  # whose books/decider work it
@export var deadline_tick: int = -1
@export var status: StringName = &"open"        # open | satisfied | abandoned | breached
@export var parent_goal_id: StringName = &""    # tree linkage for sub-goals
```

**Why ship `ACCOUNT_TARGET` + `PREDICATE` in v0** (your L3 call to me): the entire substrate is `Book.balance(account, period_start, period_end)`. Account-target goals are **directly satisfiable by a query that already exists.** A predicate escape hatch lets us encode "is_employed(self)" or "has_steward(region)" without forcing every non-economic outcome through accounts. Two shapes covers ~95% of v0 surface; `RELATIONAL_STATE` and `POSSESSION_OF` ship when War/Reputation earns them. This is L8 discipline applied to L3 — seam shaped for four shapes, two implementations land now.

**Vocabulary check:** I'm calling top-level instances *Initiatives* in narration but storing them as `Goal` Resources. The author's L9 is exact: Initiative IS the top-level Goal with a concrete target outcome. Sub-goals are also `Goal` Resources. Same Resource, role distinguished by `parent_goal_id`. This keeps the recursion (L2) honest: same primitives at every tier.

### 2.3 The `Recipe` Resource (L5 — `.tres` data)

```gdscript
class_name Recipe
extends Resource

@export var recipe_id: StringName = &""
@export var produces_outcome_kind: Goal.OutcomeKind
@export var produces_account: StringName = &""    # for ACCOUNT_TARGET recipes — what account this fills
@export var description: StringName = &""

# What this recipe spawns when adopted. Each step is itself a Goal template
# (instantiated with concrete numbers when the recipe runs). Recursion lives here.
@export var sub_goal_templates: Array[GoalTemplate] = []

# Single-axis scoring input (L7 v0). Multi-axis fields ship later but call site
# does not change.
@export var estimated_cost_coin: float = 0.0
@export var estimated_duration_days: int = 0

# Pre-conditions: the decider skips this recipe if any are false. Each is a
# named check against books/region.
@export var requires: Array[StringName] = []      # e.g. &"owns_plot", &"has_steward"
```

`GoalTemplate` is a tiny sister Resource: same fields as `Goal` but `target_amount`, `subject`, etc. may be expressions resolved at instantiation (e.g., `target_amount = parent_goal.target_amount * 0.5`). Keeps recipes data-pure.

### 2.4 The `Decider` Resource on Actor (L7 — pluggable scorer)

```gdscript
class_name Decider
extends Resource

@export var recipe_library: Array[Recipe] = []     # what this actor knows
@export var scorer: RecipeScorer                   # pluggable; v0 = SingleAxisCostScorer

func choose_recipe(actor: Actor, goal: Goal, context: DecisionContext) -> Recipe:
    var candidates: Array[Recipe] = _filter_to_outcome(goal)
    var best: Recipe = null
    var best_score: float = INF
    for r in candidates:
        if not _meets_requirements(r, actor, context):
            continue
        var score: float = scorer.score(r, actor, goal, context)
        if score < best_score:
            best_score = score
            best = r
    return best
```

`RecipeScorer` is the seam (L7, L8): `SingleAxisCostScorer` ships v0 (returns `recipe.estimated_cost_coin`); `MultiAxisArchetypeScorer` lands when archetype variation earns it. **`choose_recipe(...)` call site never changes.** The graduation Mary saw in E (`observer: Actor = null`) is the same shape here.

`Actor.gd` gains: `@export var decider: Decider`. Existing `interests: Array[Interest]` stays — Interests are now read as **the actor's bus-binding capabilities**, not their decision policy. (More on Interest's reframed role in §3.)

### 2.5 Goal propagation lord → steward (NOT contract)

This is your L10 carve-out. Contracts are husk. Here's what carries the force instead:

**`Accounts.directives_received: Array[Goal]`** — a new field on `Accounts` parallel to `contracts` and `activities`. When a lord directs a steward, the lord:
1. Builds a `Goal` Resource with `assigned_by = lord.get_path()`, `assigned_to = steward.get_path()`.
2. Calls `steward.accounts.directives_received.append(goal)`.
3. Optionally records a `DirectiveAssignmentActivity` on the lord's books (so the directive is journaled and queryable — legibility).

The steward's `_decide_loop` (§2.6) walks `directives_received` along with self-originated needs, runs the decider, picks a recipe, instantiates sub-goals (which may target the steward's own subordinates' `directives_received`).

**Why this beats contract-as-force-carrier:** contracts are bilateral, market-cleared, and designed for an exchange-of-value. Directives are unilateral, command-cleared, and designed for outcome-only command. Reusing Contract conflates two relationships and makes "what does this lord want from this steward" unparseable from the data.

**Feedback channel up (the L1 open riff):** when a directive's status flips to `satisfied | abandoned | breached`, write a `DirectiveOutcomeActivity` to *both* actors' books. The lord's books now contain a queryable history: `book.entries(directive_outcome_account_for(steward), period)` returns every directive's resolution. **This is the substrate for "my steward's track record" without inventing a reputation system in v0.** When you build reputation later, it walks this same trail.

### 2.6 The decider entry point on Actor

I want a single call site, fired on a clock the actor controls:

```gdscript
# On Actor, called daily for low-tier actors and weekly for lord-tier
func deliberate(tick: int) -> void:
    var open_goals: Array[Goal] = _gather_open_goals()
    for goal in open_goals:
        if _check_satisfied(goal, tick):
            goal.status = &"satisfied"
            _emit_directive_outcome(goal)
            continue
        if _is_past_deadline(goal, tick):
            goal.status = &"abandoned"
            _emit_directive_outcome(goal)
            continue
        var recipe := decider.choose_recipe(self, goal, _build_context())
        if recipe == null:
            continue
        _adopt_recipe(recipe, goal, tick)
```

`_gather_open_goals` unions `accounts.directives_received` (with status `open`) + self-originated goals from needs (vitals depletion → reactive Goal; archetype-driven aspirations → strategic Goals). `_check_satisfied` is the legibility audit's centerpiece — see §4.

**Decider depth scales (L9):** lord-tier actors carry richer `recipe_library` and a multi-axis `scorer`; low-tier actors carry a small library and a single-axis or weighted-random scorer. Same call site.

### 2.7 The leaf shape (L4 termination)

Recursion terminates when a recipe's `sub_goal_templates` is empty AND the recipe carries an **action stub** that an Interest can execute. I propose a small new field on Recipe:

```gdscript
@export var leaf_action: StringName = &""    # &"" = composition-only; non-empty = leaf
```

When the decider adopts a leaf recipe, it does NOT instantiate sub-goals; it tells the relevant Interest "do your thing, here are the parameters." The Interest then creates the appropriate Activity tree (FarmingDayActivity, RetailPurchaseActivity, etc.).

**This means: Activities stay exactly as they are.** Activities are the journal-writing leaves (`activity.gd` line 42's `on_close() -> bool` writes to Books). Recipes terminate by *invoking* an Interest method that creates Activities. **Activities are not the leaf of decomposition; they are the bookkeeping under the leaf.** That's the clarification the leaf-shape question really wanted.

The leaf vocabulary then reads:
- **Goal** — what we want.
- **Recipe** — how (composition, possibly recursive).
- **Leaf recipe** — how, terminal: an Interest call.
- **Interest method** — atomic verb (e.g., `WorkingInterest.begin_working`, `MercantileInterest.queue_wholesale_buy`).
- **Activity** — journal entry that records the verb's effect.

Plain English the whole way down. No CS jargon.

### 2.8 Relation to existing Interest classes (§3 follows; here's the thesis)

**Interest reframes from "behavior policy" to "atomic verb library + bus binding."** The existing classes mostly survive *as containers of leaf actions*, with their hard-coded decision logic stripped out and replaced with parameterized methods that recipes call. Detail in §3.

### 2.9 Connection points to Books, Markets, Contract creation

- **Books:** the satisfaction check (§4) is `Book.balance(observer, account, period_start, period_end)` — already shipped per E. The directive-outcome feedback writes new entries to a `Directive_Outcomes:{steward_id}` account on the lord's books — this is one new account name, no new Book class.
- **Markets:** unchanged. Markets continue to pull on open. The recipe layer changes *what an actor offers/requests*, by setting parameters on the Interest before market open. Example: a "stockpile cash" recipe might set `MercantileInterest.target_inventory` lower this week to free coin. The market interface doesn't move.
- **Contract creation:** unchanged. Labor contracts are still struck by `LaborMarket.clear_market(tick)` calling `LaborContractActivity`. A lord's directive "ensure manor is staffed" decomposes (via recipe) into a sub-goal "manor has 3 active labor contracts" which the steward fulfills by ensuring `EmployerInterest.desired_workers = 3` and letting the LaborMarket do its thing. Recipes set parameters; Markets clear.

---

## 3 — Top-down trace: "Lord wants 30 days of cash reserves stockpiled in the manor before tax season"

I'll walk this concretely through the proposed types.

**Step 1 — Initiative born on the lord's books.** Player or lord-AI creates:

```
Goal {
  goal_id: "stockpile_for_taxes_w42",
  outcome_kind: ACCOUNT_TARGET,
  account: A_CASH,
  subject: lord_estate.get_path(),
  comparator: "at_least",
  target_amount: <30 days * estimated_daily_burn>,
  period_end: <tick of tax_week>,
  assigned_by: NodePath() (self-originated),
  assigned_to: lord_estate.get_path(),
  parent_goal_id: "",
  status: "open",
}
```

The lord writes a `DirectiveAssignmentActivity` to its books (legibility: this Initiative now exists in the lord's history). `lord_estate.accounts.directives_received.append(goal)`.

**Step 2 — Lord's `deliberate(tick)` runs.** `_gather_open_goals` finds the Initiative. `_check_satisfied` queries `lord_estate.accounts.financial().balance(A_CASH, -1, tick)` — call it 200 coin against a 600 coin target. Not satisfied. Decider runs.

**Step 3 — Lord's decider walks recipes for `produces_outcome_kind=ACCOUNT_TARGET, produces_account=A_CASH`.** Library at lord tier might hold:
- `RaiseRevenueByDirectingProduction` — sub-goals: increase grain output, sell at retail
- `RaiseRevenueByLevyingTax` — sub-goal: collect from tenants
- `RaiseRevenueByLiquidatingInventory` — sub-goal: sell stockpiled grain to merchant

Multi-axis scorer in graduated form weights `archetype_alignment` (corrupt lord favors levy; mercantile lord favors liquidate); v0 single-axis picks cheapest by `estimated_cost_coin`. Suppose it picks `RaiseRevenueByDirectingProduction`.

**Step 4 — Recipe instantiates sub-goals.** Recipe's `sub_goal_templates` are:
1. `Goal{ ACCOUNT_TARGET, account=Production_Output_Value, subject=steward_estate, target_amount=parent.target_amount*1.2, comparator=at_least, period=parent.period }`
2. `Goal{ ACCOUNT_TARGET, account=Sales_Revenue, subject=steward_estate, target_amount=parent.target_amount, comparator=at_least, period=parent.period }`

These are `assigned_by=lord, assigned_to=steward`, `parent_goal_id=stockpile_for_taxes_w42`. Lord appends them to **steward's** `accounts.directives_received`. Lord writes one `DirectiveAssignmentActivity` per sub-goal.

**Step 5 — Steward's `deliberate(tick)` runs (next daily/weekly tick).** Steward sees two new directives in `directives_received`. For "produce 720 grain by tick T," steward's recipe library contains `IncreaseProductionByExpandingPlot`, `IncreaseProductionByHiringMore`, `IncreaseProductionByLengtheningWorkday`. Scorer picks `IncreaseProductionByHiringMore`.

**Step 6 — That recipe's sub-goals.** Likely a single sub-goal: `Goal{ ACCOUNT_TARGET, account=labor_headcount_predicate (or PREDICATE shape), subject=steward, target=3 active LaborContracts, comparator=at_least }`. This is steward-self-assigned (no propagation; the work is the steward's own).

**Step 7 — The steward's recipe for "3 active LaborContracts" is a leaf recipe.** Its `leaf_action = "set_employer_target"`. The decider reads the leaf and calls — through a small `_dispatch_leaf` shim — `steward.find_interest(EmployerInterest).desired_workers = 3`. No sub-goals; we've terminated.

**Step 8 — Markets clear.** On next weekly burst (`window_orchestrator.gd:fire_weekly_burst`), `LaborMarket.open_market` polls EmployerInterest, sees 3 open positions, clears matches, creates LaborContractActivities. Existing code path. Unchanged.

**Step 9 — Days pass; FarmingDayActivities accumulate; output_produced_today writes Production_Output_Value entries to steward's books.** Existing code path. Unchanged.

**Step 10 — Steward's `deliberate(tick)` re-runs each tick.** `_check_satisfied` for the production sub-goal: `steward.accounts.financial().balance(A_PRODUCTION_OUTPUT_VALUE, period_start, tick) >= 720`. When true, status flips to `satisfied`, `DirectiveOutcomeActivity` writes to both lord's and steward's books.

**Step 11 — Lord's `deliberate(tick)` sees its sub-goal satisfied.** Original Initiative re-checks: `lord.accounts.financial().balance(A_CASH, ...) >= 600`? If still no (revenue might lag accrual), the lord may re-deliberate and pick a complementary recipe (sell inventory). If yes, Initiative satisfied. Done.

**Trace observation:** every step is a `Goal`, a `Recipe`, an `Interest` method, or a `Book` write. Five vocabulary words. The recursion is real. Same primitives at lord tier and steward tier (L2). Outcome only propagates (L1) — lord said "produce 720 grain"; steward chose hiring vs. plot expansion vs. workday extension itself.

---

## 4 — Bottom-up trace: an atomic verb composes upward

Take `WorkingInterest.do_one_work_slot(slot)` — the atomic verb "do one slot of work."

**Tier 0 — Atomic verb.** `do_one_work_slot` reads `current_day_activity`, builds a `FarmingSlotActivity`, closes it. Books get one slot's worth of accumulator deltas via the parent FarmingDayActivity.

**Tier 1 — Daily aggregation by Activity.** `FarmingDayActivity.on_close()` consolidates the day's slots into one journal Tx: Inventory:grain credit, Production_Output_Value credit, Wages_Expense + Payable:worker. **No goal awareness here.** This is bookkeeping.

**Tier 2 — Composed by `WorkingInterest.begin_working` + `close_workday`.** These methods own the day-shape of work. In the new architecture, a leaf recipe `WorkADay` calls `WorkingInterest.begin_working()`. The Interest is the atomic-verb library; the Recipe says "engage this verb today."

**Tier 3 — Composed by a Recipe `EarnWagesThisWeek`.** Sub-goals: `WorkADay × 5`. Leaf recipe under each sub-goal. Recipe is held by a worker actor; goal is self-originated from a need ("eat" → "have cash" → "earn wages").

**Tier 4 — Composed by a Recipe `SupportFamilyForSeason`.** Sub-goals: `EarnWagesThisWeek × 12`, plus `BuyGrainAtRetail × N`. This is a higher-tier recipe; a worker may not hold it but a head-of-household NPC might.

**Tier 5 — Composed by a Recipe `RaiseRevenueByDirectingProduction` from the top-down trace.** Steward holds it. Subordinate workers' `EarnWagesThisWeek` is *not* steward-assigned — workers self-originate it from their own needs. The steward's directive ("produce 720 grain") is satisfied *because* workers self-organize work; the steward provided the contracts and the LaborMarket cleared.

**Bottom-up validates the rule:** at every tier, what ascends is `Goal → Recipe → leaf Interest method → Activity write`. The recursion holds in both directions. Verbs aren't re-defined per tier; they're re-composed.

---

## 5 — Legibility audit (this is my central deliverable)

**My charge:** at every evaluation the decider runs, name the queries, then verify the substrate provides them. I'll enumerate by decision point.

### 5.1 Goal satisfaction check — `_check_satisfied(goal, tick)`

For `outcome_kind == ACCOUNT_TARGET`:
```
book = goal.subject.accounts.financial()  # or skills() / vitals() per account namespace
current = book.balance(goal.account, goal.period_start, tick)
# Comparator-aware: at_least → current >= target; at_most → current <= target; equals → abs(current - target) < EPSILON
```

**Substrate check:** ✅ Provided. `Book.balance(account, period_start, period_end)` exists today (`book.gd:32`). `Accounts.financial/skills/vitals` resolvers exist. `JournalEntry.tick` exists for windowing. **Zero gap.**

For `outcome_kind == PREDICATE`:
```
fn = PredicateRegistry.lookup(goal.predicate_id)
satisfied = fn.call(goal.subject_actor, tick)
```

**Substrate check:** ⚠️ **Predicate registry does not exist.** This is a small new thing — a Dictionary autoload mapping `StringName → Callable`. ~30 lines. Predicates internally use the same Book queries. **Gap is fillable; it's plumbing, not a substrate problem.**

### 5.2 Decider scorer — `RecipeScorer.score(recipe, actor, goal, context)`

V0 single-axis: `recipe.estimated_cost_coin`. **No query needed; field-read.** ✅

Graduated multi-axis archetype scorer might want, per recipe:
- `actor.archetype_weights[axis]` — read on actor.
- `actor.accounts.cash()` — already exists (`accounts.gd:53`). ✅
- `actor.accounts.financial().balance(A_LORD_TAX_EXPENSE, last_30_days)` — exists. ✅
- For "success probability based on past attempts": a query like `book.entries(directive_outcome_account, period)` filtered by recipe_id-or-equivalent. **Substrate check:** ⚠️ This requires *journal entries to remember which recipe produced them.* Today, `JournalEntry.activity_ref` records the activity_type. If we want recipe-level lineage, **we need either a `recipe_id: StringName` field on JournalEntry, or — cleaner — a `recipe_id` field on the Activity which the Activity's `on_close` propagates into the entries it writes.** This is post-v0 (graduates with multi-axis scorer per L7), but I want it on the parking lot now so we don't pay a refactor later.

### 5.3 Recipe pre-conditions — `_meets_requirements(recipe, actor, context)`

Each requirement is a named check. Examples:
- `&"owns_plot"` → `actor.accounts.owned_resources.any(r is LandPlot)`. ✅ field exists.
- `&"has_steward"` → relational query. ⚠️ **There is no "stewardship" relation in code today.** L10 ruled out Contract for this. We need either a `relations: Dictionary` field on `Accounts` (e.g., `&"steward" → NodePath`), or a Goal of `outcome_kind=RELATIONAL_STATE` that, when satisfied, sets that relation. **Gap. Fillable. Lives at the Accounts struct layer.**
- `&"can_afford_X"` → `actor.accounts.cash() >= X`. ✅
- `&"has_skilled_worker"` → enumerate `EmployerInterest.employees()`, filter by `worker.accounts.skills().balance(skill_id) >= threshold`. ✅ Uses E's population seam pattern (employees enumerator already exists at `employer_interest.gd:32`).

### 5.4 Sub-goal target derivation — recipe templates evaluating expressions

When a recipe instantiates `target_amount = parent_goal.target_amount * 1.2`, the decider needs `parent_goal` accessible. **Substrate check:** ✅ `parent_goal_id` is on Goal; lookup is `actor.accounts.directives_received.filter(g.goal_id == parent_id)`. Trivial.

But: **forecasting** — if a recipe like `RaiseRevenueByDirectingProduction` sets `target_amount = parent.target_amount * 1.2` (gross-up for cost), the decider implicitly assumes a wage-cost ratio. That ratio is a query: `wages / output` over recent history. We computed it once already in `production_interest.gd:29`. We'd factor it into a helper `Accounts.recent_wage_cost_ratio(period)`. **Fillable; reuses existing pattern.** Worth surfacing — recipes that estimate forward-looking targets need book-walks behind their template expressions, and those queries should live on Accounts not on the recipe.

### 5.5 Lord's "steward track record" query (the L1 open riff)

The query: *"of directives I assigned to this steward in the last 30 days, what fraction landed `satisfied` vs `abandoned | breached`?"*

**Substrate check:** With the proposed `DirectiveOutcomeActivity` writing to `Directive_Outcomes:{steward_id}` with credits for satisfied and debits for breached/abandoned, this is:
```
fb = lord.accounts.financial()
period_start = tick - 30
account = StringName("Directive_Outcomes:%s" % steward.actor_id)
net = fb.balance(account, period_start, tick)
gross = abs sum of |entry.amount| over fb.entries(account, period_start, tick)
ratio = (net + gross) / (2 * gross)   # 1.0 = perfect record, 0.0 = total failure
```

**This works.** ✅ Same Book API. Same period query. The "track record" is just an account read. **The decision to journal directive outcomes earns this query for free.** That's the architectural payoff — legibility is a property of writing the right entries, not of building a reputation system.

### 5.6 Macro-legibility identity test (the GDD's charter)

The player-felt patterns:
- *"workers usually well-fed"* → enumerate population, aggregate VitalsBook food_satiation. ✅ E shipped `Region.aggregate_over(filter, account, op, period)` design.
- *"high turnover at this farm"* → query LaborContract.status flips on the employer's books — count `Contract.Status.BREACHED` events over period. **Substrate check:** ⚠️ Today, `Contract.status` flips imperatively (a field assignment); there's **no journal entry written when a contract breaches.** If we want this query, contract status flips need to write a `Contract_Lifecycle:{counterparty}` entry. **Gap. Small. Add a `ContractLifecycleActivity` (or just have `WorkingInterest.disconnect_from_bus` write the entry per its TODO comment at line 17 of working_interest.gd).** Worth fixing in G's pass — it makes the macro-legibility orientation hold for labor as well as for vitals.
- *"lord operating at a loss two months"* → `lord.accounts.financial().balance(A_CASH, period) < 0` over period, OR sum over revenue accounts vs. expense accounts. ✅ All exist.

**Identity test verdict:** the decider's needs and the player's macro-felt patterns share the same query shape — `book.balance(account, period)` and the population aggregator. **The architecture's identity holds** *if* we write contract-lifecycle entries (small fix) and *if* the predicate registry lands. Both are within G's reach.

### 5.7 Cross-actor information flow (my second lens)

When a lord assigns a directive, **what does the steward see?** A `Goal` Resource appended to `accounts.directives_received`. The Goal carries `assigned_by` (so steward can identify the lord), `parent_goal_id` (empty if Initiative), and `description` (diegetic name). **Identity question:** is the Goal a copy or a reference?

**My recommendation: reference (same Resource instance), with status-change observed by both parties.** Godot's Resource semantics handle this — the lord and steward both hold a pointer to one Resource. When status flips, both see it. When the lord re-deliberates, it queries goal.status on the same instance. **Tradeoff with Cloud or Indie if either of them argues for copy-with-bidirectional-sync:** copies decouple temporally and survive save/load more cleanly, but they double the source of truth and invite drift. I'd ship reference and revisit only if save/load forces copies.

**Partial completion / abandonment.** The status enum (`open | satisfied | abandoned | breached`) covers it. Partial = remains `open`; the satisfaction check just hasn't tipped. Abandonment = active flip by the assignee (steward's decider gives up after N failed attempts → status=`abandoned` + DirectiveOutcomeActivity entry). Breach = different shape — assignee defied the directive — but for v0 I'd collapse breach into abandonment and only differentiate when the diplomacy/loyalty layer lands. **This is L8 again: enum has all four values from day one (seam), only three behaviors implemented (simple).**

---

## 6 — Compatibility check (L10's mandatory)

I owe you a verification that this architecture doesn't preclude War, Export/Import, Reputation. Tied to specific elements:

**War.** A lord's Initiative `Goal{ outcome_kind=PREDICATE, predicate_id="rival_lord_neutralized" }` — predicate reads a hypothetical `MilitaryBook.balance(rival_strength_estimate, period)`. Recipes for this Initiative include `RaiseRetinue`, `BesiegeKeep`, `BribeKingsmen`. Each recipe propagates sub-goals to a steward, captain, or seneschal — **the same `directives_received` channel.** Casualties write entries to a `Strength` account on the actor's MilitaryBook. **No new propagation primitive needed.** ✅ Compatible. Tied to: `Goal.PREDICATE`, `directives_received`, future MilitaryBook (which inherits the `Book` base).

**Export/Import.** A merchant's Initiative `Goal{ ACCOUNT_TARGET, account=Sales_Revenue, subject=self, target_amount=X, period=Y }`. Recipe `ExportToNeighborRegion` has sub-goals targeting another region's RetailMarket. **Substrate check:** Markets are owned by Region today (`region.gd:7`). Cross-region access means the recipe's leaf action queues an offer in the *other* region's market — a one-line Region method. The population seam from E (`Region.aggregate_over(...)`) was already designed to be generic over its element type per E's locked directive (population paper line 165). **Compatible.** ✅ Tied to: `Recipe.leaf_action` invoking cross-region market call; `Region` already addressable.

**Reputation.** Reputation is a network-flavored book per E's adjudications. The `Directive_Outcomes:{steward_id}` account I proposed in §2.5 *already is the seed of reputation* — it's a per-counterparty trust ledger. When you graduate this to Reputation Phase, the Reputation system reads existing entries plus new gossip-sourced entries. **Compatible.** ✅ Tied to: `JournalEntry` to a counterparty-namespaced account; query is `book.balance(account, period)`.

**All three pass.** The compatibility doesn't come from claims of generality — it comes from the fact that every new system reads/writes through `Book`, propagates through `directives_received`, and decides through `Decider.choose_recipe`. Three primitives. Same shape every time.

---

## 7 — Verdict

**(A) Modifications to the current Interest+Activity scaffolding.**

I am confident in (A) and I want to anchor it in evidence, because Indie may push (B) and Cloud may push something in between, and I want my reasoning legible.

**What survives, and why:**

1. **The Activity tree and persistent-vs-transient discipline survives entirely.** `activity.gd`, `farming_day_activity.gd`, `farming_slot_activity.gd`, `wage_payment_activity.gd`, `wholesale_sale_activity.gd`, `retail_purchase_activity.gd`, `labor_contract_activity.gd` — all of these continue to do what they do: write balanced ledger entries on close, accumulate child deltas, link to participants. **They are the bookkeeping under the leaf, exactly as the new architecture defines that role.** The only addition to Activity is an optional `recipe_id: StringName = &""` field to support multi-axis lineage queries when those graduate (§5.2), and that's a one-line append.

2. **The Books substrate survives entirely** (and L10 explicitly carves it out anyway). `book.gd:32`'s `balance(account, period_start, period_end)` is the satisfaction check's spine. The universal account vocabulary in `accounts.gd:21–30` is the outcome shape's vocabulary. The journal pattern in `journal_entry.gd` is what the directive-outcome feedback channel writes to. **Zero changes to internals.**

3. **The Markets pull-on-open architecture survives entirely.** `market.gd:30` `open_market(tick)` and `clear_market(tick)` are the right shape. Recipes set parameters on Interests; Markets clear. **Zero changes to market interfaces.** This is the boundary that L10 explicitly held in scope but treated as peripheral; my proposal honors that.

4. **Most existing Interest classes survive as atomic-verb libraries**, with their hard-coded decision logic relocated to recipes. Specifically:
   - `WorkingInterest`: bus subscriptions stay; `begin_working()`, `do_one_work_slot()`, `close_workday()` become callable atomic verbs invoked from leaf recipes. The `current_contract() != null` check inside `begin_working` is removed (the recipe gating handles it). The Interest is leaner.
   - `EmployerInterest`: bus role stays (LaborMarket polls). `desired_workers` becomes a parameter recipes can set. `settle_outstanding_wages()` stays as-is (it's invoked from the weekly burst, which I'd reframe as a leaf recipe one tier up).
   - `MercantileInterest`, `ProductionInterest`, `GrainInterest`: same pattern — methods become atomic verbs; hardcoded targets (`target_inventory`, `max_wholesale_price`) become parameters. **Their fields stay.** Their `respond_to_*_call` methods stay, because those *are* market-pull leaves.

5. **`Actor.gd` survives**, gaining `decider: Decider`. Eight or so new lines.

6. **`Accounts.gd` survives**, gaining `directives_received: Array[Goal]` and optionally a `relations: Dictionary` for §5.3's stewardship-style relations. Two new fields. Helper methods alongside `outstanding_payables()`.

7. **`window_orchestrator.gd:fire_weekly_burst` survives.** Today it's a structural sequence of market calls. In the new architecture, it's still that — possibly invoked as a leaf recipe at the orchestrator-tier, but functionally identical. **Zero rewrites required for v0.**

**What's new, and only what's new:**

- `scripts/goals/goal.gd` — Goal Resource (v0 ships ACCOUNT_TARGET + PREDICATE shapes).
- `scripts/recipes/recipe.gd` — Recipe Resource + GoalTemplate sister Resource.
- `scripts/recipes/library/*.tres` — designer-authored recipes.
- `scripts/decider/decider.gd` — Decider Resource.
- `scripts/decider/recipe_scorer.gd` — abstract scorer.
- `scripts/decider/single_axis_cost_scorer.gd` — v0 scorer.
- `scripts/decider/predicate_registry.gd` — autoload, Dictionary of named checks.
- `scripts/activities/directive_assignment_activity.gd` — journals an Initiative.
- `scripts/activities/directive_outcome_activity.gd` — journals satisfied/abandoned/breached resolution.
- A `deliberate(tick)` method on Actor + a daily/weekly hook in window_orchestrator that calls it.

**Why not (B):** the scaffolding's unease is not in the Activity tree, not in the Books, not in the Markets, not in the Region/Actor structure. The unease is in the *missing middle layer*: there's no decider, no goals, no recipes, no propagation. (B) would throw away the Activity tree's persistent-vs-transient discipline (genuinely good design, hard-won in Phase 2.5), the `Book` query API (just-shipped in E and already feeding the satisfaction check), and the Market pull-on-open pattern (solves the cost-basis bug class structurally per `production_interest.gd:18–19`'s comment). Throwing those out to add a decision layer is throwing the load-bearing walls to install plumbing.

**The current code has a hole, not a fault.** Fill the hole.

---

## 8 — Where I anticipate disagreement (tradeoffs for the author)

I am one paper of three. Here's where I expect Cloud and Indie to push back, and how I'd weigh each:

**If Cloud argues "the Goal Resource should be a tagged-union with separate Resource subclasses per outcome_kind"** — that's cleaner type-safety but multiplies the file count and complicates `.tres` editing. I'd accept the swap if Cloud demonstrates a v0 call site that branches awkwardly on `outcome_kind`. Otherwise the enum-tag pattern (which mirrors what Cloud himself shipped for the precision Reading return type in E) is fine.

**If Indie argues "ship without the Decider class — just have recipes self-execute"** — that collapses L7's pluggable scorer seam. Indie's pragmatism is valid for v0 *behavior*, but the seam is the L8 discipline. I'd hold: ship `SingleAxisCostScorer` as the only scorer; the seam stays. No call site changes when archetype scoring lands.

**If either argues "directives should be a separate Resource type, not a Goal subtype"** — they'd be making the exact mistake L3 calls out: directive is a special case of Goal, not an alternative to Goal. Goal is the substrate. Hold the line.

**If either argues for a copy-on-assign propagation model rather than reference-sharing** — see §5.7. Tradeoff is real (save/load durability vs. drift risk). Author's call. My v0 lean is reference, but I'd not fight a strong save/load case for copies.

---

## 9 — Closing observation

The treasure here is that the substrate is already *correct*. `Book.balance(account, period_start, period_end)`, the universal account vocabulary, the population aggregator design from E, the persistent-vs-transient Activity discipline — all of it is already shaped to support what G needs. **G is not a rebuild; G is the act of recognizing that the bookkeeping you've already shipped is also the goal-satisfaction substrate you didn't know you'd shipped.** Goals query it. Recipes target accounts in it. The decider scores against numbers that come out of it. The macro-legibility identity test passes because the same queries that drive NPC decisions drive the player's read of the world.

Five vocabulary words: **Initiative, Recipe, Decider, Outcome, Behavior.** Four of them map cleanly to existing or trivially-added code. The fifth — Behavior — is what the existing Activity tree was already doing. The system *and* the vocabulary land together.

Build the middle. Keep the rest.

— Mary
