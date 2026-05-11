---
name: Elicitation G Round 1 — Indie
status: Round 1 paper (verbatim)
date: 2026-05-09
agent: Indie (Game Solo Dev)
elicitation_ref: prototype-completion-roadmap.md §3.7
verdict: (B) clean-sheet rebuild of Interest+Activity decision-side layer (with generous keeper-list)
---

🎮 **Indie:**

Alright. I've been through the locked context, and I just spent a chunk of time staring at every Interest, every Activity, the orchestrator, and the bootstrap. I'm going to be straight with you because that's what you asked for.

The current scaffolding solves a *different problem* than the one G is asking us to solve. Phase 2.5 nailed the **bookkeeping spine** — Activities-write-to-Books is gold, and L10 explicitly carves it out as keeper. But the layer above the Books — the layer that decides *which Activity to even create* — is essentially missing. Right now "deciding" is hardcoded inside the Interest class itself: `WorkingInterest` listens to a bus signal and *unconditionally* spins up a `FarmingDayActivity` if it has a contract (`Z:\TheKingYouDontSee\tkyds-game\scripts\interests\working_interest.gd:41-67`). `MercantileInterest` decides what to buy by comparing `on_hand` to `target_inventory` (`mercantile_interest.gd:25-30`). `EmployerInterest.desired_workers` is `@export var desired_workers: int = 2` (`employer_interest.gd:4`) — it's just a number on a Resource. There's no goal, no recipe, no decider — and there's nowhere to *put* one without forcing it through an Interest type that wasn't designed to hold it.

So my verdict, up front, in headline form, before the body:

> **(B) — clean-sheet rebuild of the Interest+Activity decision-side layer.**
> Keep Books, keep Activities-as-bookkeeping (the leaves). Rebuild *above* them. Interests in their current form get retired as a control structure; what survives of them becomes a market-registration manifest, nothing more.

That's a B with a generous keeper-list. It is not a from-zero rewrite. I'll show you what I'd write if I were starting today.

---

## 1. The architecture I'd build

### 1.1 The vocabulary first (because it's load-bearing — L9)

Solo dev has to type these a thousand times. Here's the names. None of them need a comment to be understood, and that's the test.

| Name | What it is | Why this name |
|---|---|---|
| **`Goal`** | Resource. The "what" — outcome only. | Plain English; matches L3. Not "directive" (sounds bureaucratic), not "objective" (sounds CS-textbook). |
| **`Recipe`** | Resource. Sub-goal template list + cost estimator. | L5 — author's word. |
| **`Plan`** | Runtime instance: a Goal + the Recipe chosen to pursue it + the live sub-Goals that decomposed out. | Plain English. Replaces what an OOP brain would call "PlanInstance" or "Strategy." |
| **`pick_plan_for(goal)`** | The decider. One method on `Actor`. Iterates Recipes, scores each, picks one, instantiates as a Plan. | Verb. Reads like a sentence: *land_owner_1.pick_plan_for(stockpile_30_days)*. |
| **`score_recipe(recipe, goal, context)`** | The pluggable scorer slot. v0 = `cost_only_scorer.gd`. | "score" is the right verb. The scorer is a `RecipeScorer` Resource on the Actor; swap the resource, get archetype variation. No call sites change (L7, L8). |
| **`is_satisfied(goal)`** | Boolean predicate that the Goal carries with it. Decider re-checks at each tier-tick. | Plain English. Not "evaluate," not "check_completion." |
| **`Initiative`** | `Goal` adopted at tier-top by a lord (or by player-as-lord later). Vocabulary alias for "the root Goal of a Plan tree." | GDD term (L9). Not a separate class — it's a Goal at the top of the tree. The class hierarchy stays flat; the *vocabulary* honors the GDD. |
| **`Action`** | Leaf method-call on the actor's body. Returns true if it produced an Activity. The verb. | Plain English. Distinct from Activity (which is the bookkeeping record left behind). |

The conceptual stack reads, end-to-end, in plain English:

> *"A lord adopts an **Initiative** (a Goal). The decider runs **`pick_plan_for(goal)`** — iterates **Recipes**, scores each via **`score_recipe`**, picks one, instantiates as a **Plan** with sub-Goals. Sub-Goals propagate to subordinates, who run their own `pick_plan_for`. At the leaf, an Action fires. The Action emits an **Activity**, which writes to **Books**."*

That sentence is the architecture. If a future me can't speak it without stumbling, the vocab is wrong. I think it sings.

### 1.2 `Goal` Resource — outcome shapes

Per L3, `Goal` ships day one with multiple outcome shapes inside the same Resource. Not a class hierarchy of outcome types — that's CS-textbook over-engineering and it bites you when you want a Goal to be *both* "balance ≥ X" *and* "by week N." One Resource, multiple optional fields, an `outcome_kind` discriminator.

```gdscript
class_name Goal
extends Resource

enum Kind {
    ACCOUNT_TARGET,    # ship in v0
    PREDICATE,         # ship in v0 (catch-all for anything not ACCOUNT_TARGET)
    TARGET_STATE,      # POST-V0
    RELATIONAL_STATE,  # POST-V0
}

@export var kind: Kind = Kind.ACCOUNT_TARGET
@export var label: StringName = &""               # diegetic — "Stockpile cash for taxes"
@export var owner_path: NodePath                   # who is pursuing this
@export var deadline_day: int = -1                 # -1 = no deadline

# ACCOUNT_TARGET shape
@export var account: StringName = &""              # e.g., "Cash", "Inventory:grain"
@export var book_kind: StringName = &"financial"   # which Book
@export var min_balance: float = NAN
@export var max_balance: float = NAN

# PREDICATE shape — Callable on (actor, goal) → bool
var predicate: Callable = Callable()

# Bookkeeping
@export var parent_goal: Goal = null               # for sub-goals propagated downward
@export var assignee_path: NodePath                # who's responsible (may differ from owner)

func is_satisfied() -> bool:
    match kind:
        Kind.ACCOUNT_TARGET: return _check_account_target()
        Kind.PREDICATE:      return predicate.is_valid() and predicate.call(self)
        _: return false
```

**Why ship only ACCOUNT_TARGET + PREDICATE in v0:** ACCOUNT_TARGET hits 80% of the lord-cares-about-this surface for free, because Books are the legibility substrate (L10). "30 days of cash reserves" is `min_balance` on `Cash`. "60 grain stockpiled" is `min_balance` on `Inventory:grain`. PREDICATE is the *escape hatch* — if you can't express it as an account target, write a Callable. We don't need TARGET_STATE or RELATIONAL_STATE until War or Reputation lands; they're seams (the enum values exist) but no code path branches on them yet. **L8 in action.**

That's the seam-then-ship play. The `Kind` enum has all four; only two have code paths. Adding the others is a `match` arm, not a refactor.

### 1.3 Recipe — `.tres` shape

```gdscript
class_name Recipe
extends Resource

@export var recipe_id: StringName = &""
@export var label: StringName = &""                # diegetic
@export var produces_outcome_kind: Goal.Kind       # what kinds of Goal this addresses
@export var addresses_account: StringName = &""    # for ACCOUNT_TARGET match (e.g., "Cash")

# The decomposition. Each entry is a "how to make a sub-Goal from THIS Goal + context."
@export var sub_goal_templates: Array[SubGoalTemplate] = []

# A *minimum-viable* leaf hook. If a Recipe has no sub-goals (it's a terminal recipe),
# it names an Action — a verb on the actor.
@export var leaf_action: StringName = &""          # e.g., "post_labor_demand", "buy_grain_at_retail"

# Pluggable cost — but the *recipe* declares its own cost-estimator method name.
# v0 single-axis: returns one float. Post-v0: returns Vector or Dictionary.
@export var estimator_method: StringName = &"estimate_cost_default"
```

```gdscript
class_name SubGoalTemplate
extends Resource

@export var goal_kind: Goal.Kind
@export var account: StringName = &""
@export var min_balance_expr: StringName = &""     # e.g., "parent.min_balance * 0.5"
@export var assignee_role: StringName = &""        # e.g., "steward", "self", "any_employee"
@export var deadline_offset_days: int = 0
@export var label_template: StringName = &""
```

The `min_balance_expr` is a small string-expression because expressions on Resources stay editable in the inspector and stay in the `.tres`. v0 evaluator is a 30-line `expr_eval.gd` that handles `parent.field`, `+`, `-`, `*`, constants. Anything fancier, defer.

A v0 Recipe `.tres` for *"stockpile cash"*:

```
recipe_id = "stockpile_cash_via_grain_sales"
addresses_account = "Cash"
produces_outcome_kind = ACCOUNT_TARGET
sub_goal_templates = [
    { goal_kind=ACCOUNT_TARGET, account="Inventory:grain", min_balance_expr="parent.min_balance * 0.6", assignee_role="self", label_template="Stockpile {parent.min_balance * 0.6} grain" },
]
leaf_action = ""   # has sub-goals, not terminal
estimator_method = "estimate_cost_via_recent_grain_price"
```

A v0 Recipe `.tres` for *"stockpile grain"*:

```
recipe_id = "stockpile_grain_via_self_production"
addresses_account = "Inventory:grain"
produces_outcome_kind = ACCOUNT_TARGET
sub_goal_templates = [
    { goal_kind=ACCOUNT_TARGET, account="Cash_for_wages", min_balance_expr="parent.min_balance * recent_wage_per_unit", assignee_role="self" },
    { goal_kind=PREDICATE, predicate_id="has_workers_employed", min_balance_expr="2", assignee_role="self" },
]
leaf_action = "ensure_employment_and_let_workdays_run"
```

Recipe library lives at `tkyds-game/scripts/economy/recipes/*.tres`. New recipe = new file. **This is the Factorio bit you're after** — content discipline, not architecture work (L6).

### 1.4 The decider — one method on Actor

```gdscript
# actor.gd, additions:

@export var goals: Array[Goal] = []                # things this actor pursues
@export var plans: Array[Plan] = []                # active Plans (Goal → Recipe → sub-Goals)
@export var recipe_book: RecipeBook = null         # available Recipes for this actor
@export var scorer: RecipeScorer = null            # pluggable; v0 = CostOnlyScorer

func adopt_goal(goal: Goal) -> void:
    goals.append(goal)
    pick_plan_for(goal)

func pick_plan_for(goal: Goal) -> Plan:
    var candidates: Array[Recipe] = recipe_book.recipes_for(goal)
    if candidates.is_empty():
        push_warning("%s has no recipe for goal %s" % [actor_id, goal.label])
        return null
    var best: Recipe = null
    var best_score: float = INF
    for r in candidates:
        var s: float = scorer.score_recipe(self, r, goal)
        if s < best_score:
            best_score = s
            best = r
    var plan := Plan.new()
    plan.goal = goal
    plan.recipe = best
    plan.expand_sub_goals(self)         # walks templates → instantiated sub-Goals
    plans.append(plan)
    return plan

func tick_goals(day: int) -> void:
    # Called by the orchestrator once per day.
    for plan in plans.duplicate():
        if plan.goal.is_satisfied():
            plans.erase(plan)
            continue
        plan.advance(self, day)
```

`Plan.advance` is where propagation happens. It looks at each sub-goal: if `assignee_role == "self"`, the actor adopts it (recursion: `pick_plan_for` again, picks a smaller recipe). If the role is `"steward"` or `"any_employee"`, it propagates to a subordinate via the **propagation channel**, which is *not* a Contract (L10). I'll get to that in 1.5.

The recursion terminates when a Recipe has `leaf_action != ""`. At that point, the Plan calls the named Action on the actor — which is just `actor.call(action_name, plan)`. The Action method does whatever it does; importantly, a leaf Action can also be **"do nothing, just register myself as a market participant and wait."** That's the case for working — `WorkingInterest` today already does the right work *given* an active labor contract. The leaf Action is "be available for hire and accept work that comes." We don't replace the Activity classes; we replace the *thing that adopts working as a sub-goal*.

### 1.5 Propagation lord → steward (NOT via Contract)

Author called it: Contracts are husk + visibility, not force-carrier. So how does a lord push a Goal to a steward?

**The simple shape: subordinates have a `received_goals_inbox: Array[Goal]` on their Actor.** When a Plan's sub-goal has `assignee_role` resolving to another actor, the parent actor calls `subordinate.receive_goal(sub_goal)`, which appends to the inbox. Each tick, the subordinate drains the inbox by calling `pick_plan_for(goal)` on each.

```gdscript
# actor.gd:
@export var received_goals_inbox: Array[Goal] = []

func receive_goal(g: Goal) -> void:
    received_goals_inbox.append(g)

func tick_goals(day: int) -> void:
    while not received_goals_inbox.is_empty():
        adopt_goal(received_goals_inbox.pop_front())
    for plan in plans.duplicate():
        if plan.goal.is_satisfied(): plans.erase(plan); continue
        plan.advance(self, day)
```

The "who's my steward?" lookup is a query on the actor — for v0, it's "any actor with a `StewardRole` component" (or just by-actor-id lookup). When the Vassal/Steward layer gets fleshed out in a later phase, the resolution upgrades; the call site doesn't change. **L8.**

Crucially: the Goal carried in the inbox carries **outcome only** (account, min_balance, deadline). The means stays with the receiver. The receiver has its *own* `recipe_book` and may pick a different Recipe than the sender would have. **L1 enforced structurally** because Recipe lives on the receiver, not on the Goal.

### 1.6 Goal satisfaction check — polling, dirt-cheap

`tick_goals` runs once per day per actor. `is_satisfied()` on an ACCOUNT_TARGET is one Book balance read. With 4 actors × maybe 5-10 Plans each × one balance read, this is microseconds. Don't over-engineer. **No event-driven `goal_completed` signals in v0.** When archetype variation and large actor counts come online, *then* consider event-driven; right now, polling is the right call (L8 again).

### 1.7 Leaf shape — not Activity-instances, not Task-union, just method calls

Author's three options were leaves-as-Activity, leaves-as-Task-union, leaves-as-method-calls. **My pick: method calls** — i.e., `actor.call(action_name, plan)`.

Why: Activities already exist as *bookkeeping records of stuff that happened*. They're persistent or transient, they write to Books, they sit on `accounts.activities`. That's beautiful. Don't pollute that role with "thing the decider decides to do." A `Task` union (option b) is OOP greenfield ceremony — it's another class hierarchy parallel to Activity, easy to over-build. A named method on the actor is the smallest possible thing that works, and the Action method's *side effect* is to produce an Activity (or queue a market offer). One direction of dependency: **Action → Activity**, never the reverse.

Concretely for the v0 grain demo, the action library on `Actor`:
- `post_labor_demand(plan)` — sets `EmployerInterest.desired_workers` from `plan.goal.min_balance` (or wraps it). Already today, market clearing handles the rest. Activity emitted: `LaborContractActivity` (already exists).
- `seek_employment(plan)` — sets `WorkingInterest.is_seeking_work()` to true (already true by default; this becomes a no-op-by-default in v0, real method when a worker has reasons NOT to seek). Activity emitted: `LaborContractActivity` on clearing.
- `produce_with_workers(plan)` — registers as wholesale supplier (already happens). Activity: `WholesaleSaleActivity`.
- `restock_grain(plan)` — sets `MercantileInterest.target_inventory` from sub-goal min_balance.
- `buy_grain_at_retail(plan)` — registers as retail demander. Activity: `RetailPurchaseActivity`.

Notice: **most of v0's leaf actions are "tell an Interest a number, then let market clearing do its thing."** The Interest classes survive — but as **market-registration manifests**, not as decision-makers. Their decision-making code (`MercantileInterest.respond_to_wholesale_demand_call` reading `target_inventory` directly) becomes a thin getter over Plan-derived state. That's a *modification* of Interest, not deletion. So the keeper-list is real.

### 1.8 What survives of Interest, what gets retired

| File | Today | Future |
|---|---|---|
| `working_interest.gd` | Decision (decides to work) + execution (creates FarmingDayActivity tree) + bus listener | **Execution + bus listener only.** Decision moves to a Plan. The "begin_working / do_one_work_slot / close_workday" lifecycle stays — that's good code. |
| `employer_interest.gd` | `desired_workers @export int = 2` is the goal | `desired_workers` becomes a getter computed from the actor's active Plans (sum of "I need N workers" sub-goals). Settle-wages logic stays — that's execution. |
| `production_interest.gd` | `respond_to_supply_call` is fine — it's already a query over Books | **Keep as-is.** It's an execution leaf already. |
| `mercantile_interest.gd` | `target_inventory @export int = 60` | Same treatment as `desired_workers` — derive from Plans. |
| `grain_interest.gd` | Demand at retail | **Keep as-is — but recognize it's modeling consumption needs, which arguably is itself a low-tier Goal.** Phase later: a Worker has a perpetual `ACCOUNT_TARGET` Goal of `Inventory:grain >= some_floor` driven by VitalsBook. For now: keep. |

So the rebuild verdict is: **the Interest layer's decision side gets gutted; its market-registration / bus-listener / book-writing side stays.** That's why I called it a (B) with a generous keeper-list. If that sounds like a soft (A), I'll fight it: the decision-side layer is being replaced wholesale, not refactored. New types (Goal, Recipe, Plan, RecipeScorer, RecipeBook), new method on Actor (`pick_plan_for`), new propagation channel (`received_goals_inbox`). That's not "modify existing." That's "the layer that owns deciding is being built from scratch." Hence (B).

### 1.9 Connection points to existing systems

- **Books (writes):** unchanged. Activities still write. The chain is now `pick_plan_for → Action → Activity → Book`. Books don't know about Plans, which is correct — they're substrate.
- **Markets (offer queueing):** unchanged in shape. The leaf Action either *registers an actor as a market participant* (which already happens at bootstrap and I'd keep that) or *adjusts the parameters they offer at* (e.g., setting `target_inventory` from a sub-goal). The market's pull-on-open still polls Interests; Interests now report numbers derived from Plans rather than from `@export` constants.
- **Contract creation:** `LaborContractActivity` is the bookkeeping record of a labor-market clearing. **That's its job and that's all.** It is no longer the "thing that signals a worker should work tomorrow" because there's no force-carrier role to play — the `WorkingInterest.begin_working` already keys off `current_contract()`, which is fine, that's the husk-as-visibility. Lord-pushes-goal-to-steward goes through `received_goals_inbox`, not through Contract. **L10 honored.**

---

## 2. Top-down trace: *"Lord wants 30 days of cash reserves stockpiled in the manor before tax season."*

I'll use `land_owner_1` as the lord-stand-in (in v0 there's no separate lord, but the architecture doesn't care — same primitives at every tier, L2).

**Day 1, week 1:**

1. **Initiative adopted.** Player or scripted seed calls:
   ```
   land_owner_1.adopt_goal(Goal{
       kind=ACCOUNT_TARGET, account="Cash",
       min_balance=600.0, deadline_day=30,
       label="Stockpile 30 days of cash reserves"
   })
   ```

2. **Decider runs.** `pick_plan_for(goal)`:
   - `recipe_book.recipes_for(goal)` returns `[stockpile_cash_via_grain_sales, stockpile_cash_via_borrow]` (the latter being a hypothetical second recipe for L6 content variety).
   - `scorer.score_recipe(self, r, goal)` is `CostOnlyScorer` → for v0 simply returns `r.estimator_method` evaluated against the Books. `stockpile_cash_via_grain_sales` estimates cost as projected wage-cash-out vs. revenue (`recent_grain_price * needed_qty - wages`); `stockpile_cash_via_borrow` estimates cost as interest expense.
   - Cheapest wins; let's say grain sales.

3. **Plan instantiates.** `Plan.expand_sub_goals(self)`:
   - Sub-goal: `Goal{ kind=ACCOUNT_TARGET, account="Inventory:grain", min_balance=parent.min_balance * 0.6 = 360.0, assignee_role="self", deadline_day=23 }`. Adopted by `land_owner_1`.
   - The lord adopts this sub-goal → `pick_plan_for` again, recursive.

4. **Tier 2 decision.** For `stockpile_grain`, recipes_for returns `[stockpile_grain_via_self_production, stockpile_grain_via_buying]`.
   - Scorer says self-production is cheaper (already owns the plot).
   - Sub-goals expand:
     - `Goal{ ACCOUNT_TARGET, "Cash_for_wages", min_balance=N, assignee_role="self" }` — i.e., make sure there's enough cash to actually pay wages. In v0 the lord has $200 seeded, and recent wages are tracked in Books, so the predicate's already approximately satisfied. (If not, recurse: a sub-recipe might be "delay payment via Payable accrual" — already what FarmingDayActivity does!)
     - `Goal{ PREDICATE "has_workers_employed", min_balance=2, assignee_role="self" }` — lord adopts this.

5. **Tier 3 decision.** `pick_plan_for(has_workers_employed_2)`:
   - Recipe: `hire_workers_via_labor_market`.
   - Sub-goals: empty. `leaf_action = "post_labor_demand"`.
   - Lord calls `self.post_labor_demand(plan)` → which adjusts `EmployerInterest.desired_workers` getter to return 2.
   - That's it. **The decision tree's leaf action just sets a number that the LaborMarket polls on weekly clearing.**

6. **Weekly burst (existing code path).** `WindowOrchestrator.fire_weekly_burst()` → labor market opens, sees workers seeking + employer with 2 open positions, clears, two `LaborContractActivity` instances close, two `LaborContract` resources written to `accounts.contracts`. *Everything from this point is unchanged code.*

7. **Daily ticks.** `WorkingInterest.begin_working` fires per existing logic. `FarmingDayActivity` produces grain. `Inventory:grain` climbs. After ~enough days the sub-goal `min_balance >= 360.0` is satisfied.

8. **Wholesale + retail.** Other recipes route the grain → wholesale sale → cash. `Cash` rises toward 600.0.

9. **Top goal `is_satisfied()` returns true.** `tick_goals` removes the Plan. Done.

Key thing about this trace: **at every tier, the actor was reading from Books to evaluate satisfaction and to score recipes.** That's L9's "legibility is the test" — and the queries used were:
- `accounts.cash()` (`Z:\TheKingYouDontSee\tkyds-game\scripts\resources\accounts.gd:52`)
- `accounts.inventory_of(good_id)` (`accounts.gd:59`)
- `fb.balance(account, period_start, tick)` (used today by `production_interest.gd:26`)
- For "recent_grain_price" — *new query needed*: `fb.average_price(period)` doesn't exist yet. I'll flag that in §4.

Also note: **the recursion bottomed out in three tiers for v0** (top initiative → grain stockpile → workers employed → leaf). Higher tiers (Lord → Steward → Worker) just add a propagation hop via `received_goals_inbox`, which I haven't traced because v0 has no separate steward. The architecture supports it via the propagation mechanism.

---

## 3. Bottom-up trace: a worker takes a farming hour

Start at the atomic verb and walk up.

1. **Atomic verb:** `FarmingSlotActivity.on_close()` runs, contributing 1 grain output, slot wage to `wages_accrued`. (`farming_slot_activity.gd:25-47`.) This is the bedrock.

2. **Composes into:** `FarmingDayActivity` (the persistent parent). At day end, accumulators commit to Books — inventory up, payable up. (`farming_day_activity.gd:30-78`.)

3. **The day was created by:** `WorkingInterest.begin_working()`, which is the leaf execution code triggered by the bus signal. (`working_interest.gd:41`.) Today, this fires unconditionally if `current_contract()` exists. **Under the rebuild, this is still fine** — the `WorkingInterest` is the execution leaf, and "I have a contract" is the precondition.

4. **The contract was created by:** `LaborContractActivity.on_close()` during weekly labor market clearing. (`labor_contract_activity.gd:30-54`.) The clearing was triggered by `LaborMarket.clear_market`, opened by `WindowOrchestrator.fire_weekly_burst`.

5. **The clearing matched a worker offer to an employer demand.** The employer's `desired_workers > 0` came from… today: `@export var desired_workers: int = 2` on the Resource (`employer_interest.gd:4`). **Under the rebuild: it came from the lord's active Plans summing "needs 2 workers" sub-goals.**

6. **The Plan came from:** `pick_plan_for(has_workers_employed_2)`, which was a sub-goal that came from `pick_plan_for(stockpile_grain)`, which was a sub-goal that came from `pick_plan_for(stockpile_cash)`, which was the Initiative.

7. **The Initiative came from:** the lord's adoption — either scripted seed (v0) or, eventually, player input through the Initiative UI.

The bottom-up trace **terminates cleanly at "the lord adopted a goal."** No mystery layer. Same primitives all the way up. **L2 satisfied.**

The thing this trace *also* surfaces: **the existing `FarmingSlotActivity` / `FarmingDayActivity` / `LaborContractActivity` / `WagePaymentActivity` / `WholesaleSaleActivity` / `RetailPurchaseActivity` machinery is exactly the leaf vocabulary I want.** The rebuild is *above* this, not around it. That's important — it constrains the (B) verdict to just the decision layer.

---

## 4. Legibility audit — queries per tier, gaps named

At each `pick_plan_for` call, the actor needs to evaluate:
1. Does this Goal's `is_satisfied()` already hold? (Answer: no, or we wouldn't be in pick_plan_for.)
2. Which Recipes in `recipe_book` match this Goal? (Trivial: filter by `addresses_account` and `produces_outcome_kind`.)
3. For each candidate Recipe, what's the score?

**Score evaluation is where legibility gets stress-tested.** Today's Books support these queries (all already in code):
- `fb.balance(account, period_start, period_end)` — `book.gd` / `production_interest.gd:26`. ✓
- `accounts.cash()` / `accounts.inventory_of(good)` / `accounts.payable_to(cp)` / `accounts.outstanding_payables()`. ✓ All in `accounts.gd:52-90`.

What the v0 recipe scorers will want that **doesn't exist yet:**

| Query needed | Where | Gap action |
|---|---|---|
| **Recent average price of good X.** "How much does grain currently sell for?" Needed to project revenue from `stockpile_cash_via_grain_sales`. | A new `Book.average_price(good_id, period)` walking journal entries with account=`Sales_Revenue` and matching `Inventory:grain` legs of the same Tx | New method on `FinancialBook`. Roughly 20 LOC. **Add as part of Phase 3 directive.** |
| **Recent average wage paid.** Needed to estimate cash outflow for "have N workers employed." | Period balance on `Wages_Expense` / period count of `WagePaymentActivity` | Use existing `balance(account, start, end)` divided by activity count — composable from existing primitives. Just need a helper like `accounts.recent_wage_per_slot(period)`. |
| **Population query: "how many actors in this region match X?"** Needed for archetype scoring later (e.g., a steward checking which workers are aligned). | Population aggregator from Elicitation E (already designed but not on Plan-side yet). | E shipped read-side primitives; G needs to *use* them. Already in scope per L10 ("connections outward to Books"). |
| **"Is there a labor market with workers available?"** Needed for `hire_workers_via_labor_market` to estimate feasibility. | `region.labor_market.registered_suppliers.size()` minus contracted. | Already accessible. Just needs a tidy helper on Region. |

**The big legibility risk** is *forward-looking* queries — "how much grain WILL I produce next week given current employees and pattern?" That's what `recent_grain_price * projected_qty` requires. v0 can fake this with last-period actuals (Books-readable). When archetype variation lands and lords disagree about projections, that's when a real "projection model" gets considered. **Defer with a seam.** The scorer takes the projection model as a strategy slot — `RecipeScorer` can hold a `projector: Projector` resource, default `projector = LastPeriodProjector` (just reads Books). Swap projector when graduated. No call-site changes (L8).

**No legibility gaps that break v0.** Two new helpers to add (`average_price`, `recent_wage_per_slot`). That's it.

---

## 5. Compatibility check — War, Export/Import, Reputation

- **War.** Initiative: `Goal{kind=PREDICATE, predicate=enemy_lord_capitulated}`. Recipe: `weaken_via_economic_pressure_then_offer_protection` with sub-goals "buy out their grain supply" + "fund mercenaries." Sub-goals propagate to merchant-stewards and military-stewards. Same primitives. **Compatible.** Notes: predicate Goals carry their own queries; the predicate `enemy_lord_capitulated` will need a `region.relationship_to(other_lord)` query that's RELATIONAL_STATE territory — but the Goal layer doesn't care, the predicate just calls it. The TARGET_STATE / RELATIONAL_STATE Kinds in the enum are now earning their seat.
- **Export/Import.** A Goal `Inventory:grain @ remote_region >= X`. Recipes: "buy grain in region A and route via merchant convoy to region B." Sub-goals propagate to merchants in different regions. The `assignee_role` resolution mechanism scales: `"any_merchant_in_region:B"`. **Compatible** with one extension to assignee resolution. No architectural change.
- **Reputation.** A `ReputationBook` lands as a fourth Book kind. ACCOUNT_TARGET goals naturally point at it: `Goal{kind=ACCOUNT_TARGET, book_kind="reputation", account="Standing:village_X", min_balance=50}`. Recipes for raising standing: throw feasts, fund chapels, etc. **Compatible.** Reputation as a Book is exactly L10's "Books are legibility substrate." This shape pre-validates that we don't have to retrofit reputation later.

All three pass.

---

## 6. Where Cloud and Mary will probably push back

Anticipating disagreement so the author can adjudicate without a Round 2:

- **Cloud will probably propose a more layered class hierarchy** (Strategy / Plan / Step / Action as separate types, possibly). My take: he's not wrong about it being more "load-bearing-correct"; he's wrong about it being right *for v0*. My one-Resource-with-Kind-discriminator approach is uglier in OOP-aesthetic terms but **takes 3 days less to implement and survives the same evolution paths**. If Cloud's structure earns its weight at War, switch then. Soft disagreement: I'll defer if the author wants more structural rigor day one, but I'd flag it as overcooked.
- **Mary will probably zero in on the legibility / query layer hard** — and rightly so. Her audit will likely find more gaps than my four. **I welcome that.** The Goal architecture I'm proposing assumes the actor *can* answer "should I pick this recipe?" — Mary's job is to verify it actually *can*. If she finds gaps I didn't, those are real and need landing in the phase directive. My answer: most should be deferred-with-seam (L8), but if any one breaks v0 I'll back off the proposal.
- **Cloud may push for event-driven goal satisfaction over polling.** Polling is cheaper, simpler, and the daily granularity is fine for v0. Event-driven looks great until you have to debug a Plan that didn't terminate because two listeners got out of sync. Polling = the ship-simple play. Disagreement ledged.
- **Both may push back on "method calls on Actor as the leaf"** vs. a Task class hierarchy. I claim the Task class hierarchy is OOP ceremony in disguise — what does a `BuyGrainTask` give you that `actor.buy_grain_at_retail(plan)` doesn't? An override hierarchy. We don't need it. If subclassing earns its weight (e.g., we want hot-pluggable Tasks defined as `.tres`), revisit. **L8 again.**

---

## 7. Verdict — explicit

**(B) — clean-sheet rebuild of the Interest+Activity *decision* layer.**

Restated for clarity:
- **Keep:** Books (whole layer), Activities (whole layer including persistent/transient discipline), Markets (interface and pull-on-open), `Accounts` struct, `Contract`/`LaborContract` Resources (as husk-and-visibility per L10), `Region`, `SimClock`, `WindowBus.work_window_opened/closed` (it's a useful daily heartbeat). All the bookkeeping spine survives.
- **Retire as decision-makers:** all five `*_interest.gd` classes' decision logic. The classes themselves remain as thin market-registration / bus-listener manifests (renamed could be `WorkerRole`, `EmployerRole`, `ProducerRole`, `MerchantRole`, `ConsumerRole`).
- **New:** `Goal` Resource (`scripts/resources/goal.gd`), `Recipe` Resource (`scripts/resources/recipe.gd`), `SubGoalTemplate` (`scripts/resources/sub_goal_template.gd`), `Plan` Resource (`scripts/resources/plan.gd`), `RecipeBook` Resource (`scripts/resources/recipe_book.gd`), `RecipeScorer` Resource + `cost_only_scorer.gd` impl (`scripts/sim/`), `received_goals_inbox` field + `pick_plan_for` / `tick_goals` / `adopt_goal` / `receive_goal` methods on `Actor`, `Action` library on `Actor` (the named methods).
- **Recipe content:** `scripts/economy/recipes/*.tres` — start with maybe 4 recipes for the v0 grain demo; this is content work after the architecture lands.
- **Orchestrator change:** `WindowOrchestrator` adds a daily-tick step that calls `actor.tick_goals(day)` on every actor before the existing slot/market work. Tiny addition (`window_orchestrator.gd:17-24`).

**Why not (A):** because what's there isn't a half-built version of the right thing — it's a complete version of a *different* thing (Phase 2.5 was right to ship what it shipped; G is just a different layer). Trying to graft Plan/Goal/Recipe into existing Interests would leave you with weird vestigial logic in five places that has to keep being worked around. Cleaner to gut the decision side, slot in Plan-driven state, and let Interests become the thin role-tags they should always have been.

**Why this isn't founder syndrome:** the keeper-list is real and large. Books stay. Activities stay. Markets stay. The new code surface is roughly **6 small Resources and 4 methods on Actor** — that's a 2-day implementation, not a 2-week rewrite. The rebuild is concentrated, not sprawling.

**The vocab gut-check, one more time:** I'd type `lord.adopt_goal(...)` → `pick_plan_for` → `score_recipe` → `is_satisfied` → `Action` → `Activity` → `Book` a thousand times and never wince. That's the test. Author, if any of those names make YOU wince, that's the load-bearing feedback you wanted from me — name them now, not after they're in 200 places.

That's the paper. Ship it or push back on it; either way the architecture's exposed for adjudication.
