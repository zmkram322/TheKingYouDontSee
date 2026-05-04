---
name: Phase 2.5 Round 1 — Cloud Dragonborn Architecture Paper
status: round-1 paper (pre-revision)
date: 2026-05-03
author: Cloud Dragonborn (Game Architect)
session: phase-2.5-books-activity-forces
round: 1 (independent, blind to Samus)
inputs:
  - _bmad-output/phase-2.5-activity-architecture-brief.md
  - _bmad-output/phase-2-architecture-directive.md
  - _bmad-output/phase-2-math-directive.md
  - C:/Users/zachm/.claude/plans/drifting-dazzling-flask.md
  - tkyds-game/scripts/ (Phase 2 code)
---

# Phase 2.5 Books-Activity-Forces Architecture Paper

**Cloud Dragonborn, Game Architect**
*The King You Don't See — Round 1, Phase 2.5 Session*
*2026-05-03*

---

## Thesis

My thesis for this rebuild is: **the three missing primitives — books, activities, and force carriers — are one primitive expressed three ways, and the architecture paper's job is to make that identity undeniable.** The Phase 2 implementation works arithmetically but is architecturally hollow: state mutates through method calls with no durable record of why, causality lives only in signal-emit order, and any coordination mechanism more complex than "fire signals in the right sequence" breaks silently. The rebuild does not add a new layer on top of Phase 2; it replaces the interior. Every ledger mutation becomes a journal entry written by an activity that closes. The books become the only source of truth. The burst orchestrator becomes an activity initiator, not a signal emitter. Nothing in this design precludes Samus's player-legibility goals — in fact, auditable books and observable in-flight activities are *more* player-legible than mutation calls on Interests, not less.

---

## Section 1 — The Books Primitive

### 1.1 Base Class: `Book`

**Decision (P1.Q1):** Strict double-entry for `FinancialBook`. Looser single-entry for `SkillsBook` and `VitalsBook` — but via the same interface. Option **(a)** from the brief: shared base class, enforcement only on `FinancialBook`.

The reasoning: the cost of strict double-entry is designing a coherent chart of accounts. That cost is worth paying for financial state — it eliminates an entire class of bugs (the cost-basis bug being exhibit A). It is not worth paying for XP, which genuinely has no counterparty: work produces XP from nothing, and inventing a "Void" debit account (option c) is accounting theater that adds complexity with zero semantic value. The shared base class means the query interface is identical across all books; code that queries a `SkillsBook` and code that queries a `FinancialBook` use the same method signatures.

```gdscript
class_name Book
extends Resource

var _journal: Array[JournalEntry] = []

func write_entry(entry: JournalEntry) -> void:
    _journal.append(entry)

func balance(account: StringName, period_start: int = -1, period_end: int = -1) -> float:
    var total := 0.0
    for e in _journal:
        if e.account != account: continue
        if period_start >= 0 and e.tick < period_start: continue
        if period_end >= 0 and e.tick > period_end: continue
        total += e.amount   # positive = credit, negative = debit by convention
    return total

func entries(account: StringName, period_start: int, period_end: int) -> Array[JournalEntry]:
    var out: Array[JournalEntry] = []
    for e in _journal:
        if e.account == account and e.tick >= period_start and e.tick <= period_end:
            out.append(e)
    return out
```

`JournalEntry` is a `Resource` with fields: `account: StringName`, `amount: float` (credit-positive convention), `tick: int`, `activity_ref: StringName` (the activity type that wrote it), `note: StringName` (optional human-readable label).

**P1.Q3 (query performance):** Walking the full journal is O(n). For v0 (14 days, single actor, ~hundreds of entries) this is fine. For phase 3+ (multi-year, multi-actor), add a per-account running-balance cache and a period-boundary index. Note as deferred — do not implement in v0.

**Save/load shape:** Books are Resources; the journal is an `Array[JournalEntry]` of Resources. Godot's resource serialization handles this directly. The tradeoff (save file grows with entries) is accepted. Phase 3+ pruning policy: roll up entries older than N weeks into period-checkpoint entries that preserve account balances without raw entry detail. Defer.

### 1.2 `FinancialBook` — Chart of Accounts, v0

`FinancialBook` extends `Book` and adds a `commit_transaction(entries: Array[JournalEntry]) -> bool` method that validates the transaction is balanced (sum of all entry amounts == 0, with credits positive and debits negative) before writing. Unbalanced transactions fail with `push_error` and return `false` — no partial writes.

**v0 Chart of Accounts:**

*Asset accounts (credit increases, debit decreases):*
- `Cash` — coin held by the actor
- `Inventory:grain` — grain held; parameterized by good_id, so `Inventory:cloth` etc. follow the same pattern
- `Receivable:*` — coin owed to this actor by a named counterparty (parameterized)

*Liability accounts (debit increases, credit decreases — amount stored as negative float):*
- `Payable:*` — coin this actor owes a named counterparty (parameterized)

*Equity account:*
- `Owner_Equity` — initial capitalization at bootstrap

*Revenue accounts (credit increases):*
- `Wages_Income` — wage receipts (workers)
- `Sales_Revenue` — sale proceeds from wholesale or retail transactions

*Expense accounts (debit decreases — amount stored as negative):*
- `Wages_Expense` — wages paid by employers
- `Cost_of_Goods_Sold` — cost basis of goods sold (recorded when inventory is sold)
- `Lord_Tax_Expense` — tax paid to lord

Actor types do not get separate charts. Every actor has the same account names available. Accounts with no entries have zero balance — no runtime cost. A worker never sees `Wages_Expense` move; a pure worker never sees `Sales_Revenue`. The ledger is universal; the chart of accounts is the full vocabulary of what *can* appear.

**Why one universal chart:** Polymorphism at query time would require knowing which actor type you're querying to know which accounts exist. "Give me the wages expense for any actor" becomes a two-line query, not a type-switch. Phase 3+ additions (seed cost, equipment depreciation) become one new account string, not a chart-refactor.

**Parameterized accounts:** `Inventory:grain`, `Receivable:alice_farmer`, `Payable:bob_worker` are `StringName` keys composed at write time. The `balance()` method accepts exact account name or a prefix-glob (`Inventory:*` → sum all inventory accounts). The glob is a phase 3+ concern; document the seam, don't implement yet.

### 1.3 `SkillsBook` and `VitalsBook`

Both extend `Book` without balance enforcement. They use the same `write_entry()` / `balance()` / `entries()` interface.

**`SkillsBook`** — Account names are skill identifiers: `farming`, `bartering`, `market_perception`. Every entry is a credit of +N XP attributed to a `WorkSlotActivity` close. Balance at any account = cumulative XP for that skill. This directly replaces `accounts.skills: Dictionary` which currently holds the same data without journal, without history, and without the ability to ask "how much XP did I earn this week?"

**`VitalsBook`** — Account names are vital identifiers: `hunger`, `fatigue`, `morale`. Eating activities credit hunger (reduce deficit); time-without-eating debits it (increases deficit). The sign convention: a *positive* hunger balance means the actor is fed (hunger is satisfied); positive entries credit satisfaction. `VitalsBook.balance("hunger")` is the actor's current hunger level. This fits the credit-positive convention without gymnastics. Fatigue and morale follow identically.

**Actor `books` field:** The Phase 2 `Accounts` resource grows a `books: Dictionary[StringName, Book]` field. `actor.books["financial"]` is the `FinancialBook`. `actor.books["skills"]` is the `SkillsBook`. `actor.books["vitals"]` is the `VitalsBook`. `Accounts` is not deleted — it continues to hold `contracts` and `owned_resources`, which are not ledger entries. The old `coin`, `inventory`, `payables`, `receivables`, `weekly_costs`, `weekly_outputs`, and `skills` fields are removed; those states now live in the books. This is the migration seam.

---

## Section 2 — The Activity Primitive

### 2.1 Base Class: `Activity extends Resource` (P2.Q1)

**Decision:** Option **(b)** — `class_name Activity extends Resource`.

The reason is save/load. In-flight activities (an ongoing work contract, a multi-day merchant journey) must survive save/load. `RefCounted` objects are not serializable by Godot's resource system without extra infrastructure. Making `Activity` a `Resource` gives persistence for free, makes hierarchical activity trees (parent Resource → children Array[Resource]) naturally serializable, and the cost is small: `Resource` has essentially the same runtime overhead as `RefCounted` for these objects.

```gdscript
class_name Activity
extends Resource

@export var activity_type: StringName = &""
@export var participants: Array[NodePath] = []
@export var started_tick: int = -1
@export var closed_tick: int = -1
@export var parent_activity: NodePath = NodePath("")  # empty = root activity
@export var child_activities: Array[Activity] = []
@export var state: StringName = &"open"  # "open" | "closed" | "aborted"

func begin(tick: int) -> void:
    started_tick = tick
    state = &"open"
    on_begin()

func close(tick: int) -> bool:
    if state != &"open":
        push_error("Activity.close() called on non-open activity: %s" % activity_type)
        return false
    for child in child_activities:
        if child.state == &"open":
            child.close(tick)       # cascade — see P2.Q3 decision
    closed_tick = tick
    state = &"closed"
    return on_close()

func abort(tick: int) -> void:
    state = &"aborted"
    for child in child_activities:
        if child.state == &"open":
            child.abort(tick)
    on_abort()

func on_begin() -> void:
    pass  # override in subclass

func on_close() -> bool:
    pass  # override; return false to signal failure (entries not written)

func on_abort() -> void:
    pass
```

### 2.2 Lifecycle Semantics (P2.Q2)

**Decision:** All book entries are written atomically in `on_close()`. No progressive writes during the activity's lifetime.

The brief's proposal to accumulate effects in-flight and write atomically at `end()` is correct. The win is transactional integrity: either the activity closes and all its entries land, or it aborts and no entries land. Books always reconcile.

The cost is acknowledged: `on_close()` is the load-bearing method and can grow complex for activities with many effects. The mitigation is that each concrete activity subclass owns exactly its own entries — `WorkSlotActivity.on_close()` knows it writes XP and nothing else. Complexity stays local.

**What `begin()` does:** Records `started_tick`, sets state to `open`, runs `on_begin()` for any setup the subclass needs (e.g., `LaborContractActivity.on_begin()` might record which plot the worker is assigned to). `begin()` does NOT write book entries.

**What `on_close()` does:** Resolves all participants via `NodePath` → Actor lookup, computes all entry amounts, writes entries to the relevant books via `book.write_entry()` or `financial_book.commit_transaction()`. Returns `false` if preconditions fail (insufficient funds on a payment activity). Caller is responsible for branching on failure.

### 2.3 Hierarchical Activities — Cascade Rules (P2.Q3)

**Decision:** Day-activity close cascades to close any open child slot-activities first. Slot effects are NOT written independently; they propagate to the parent via in-memory fields before the parent writes entries.

This is the design disagreement the brief anticipates. Samus will want each slot to be independently observable — a player watching a worker should see slot-by-slot progress, not one batch write at day close. My position: **independent writes and independent observability are not the same thing.** The player can observe `WorkSlotActivity` objects as they are created, track `started_tick`, and display slot-by-slot progress without those activities writing to books. The activity's existence is observable; its book effects are deferred to close. This keeps the books clean and gives Samus everything she needs for player display.

**Concrete cascade rule:**

`WorkDayActivity.on_close()`:
1. Calls `child.close(tick)` on any open `WorkSlotActivity` children.
2. Each `WorkSlotActivity.on_close()` writes only to `SkillsBook` (XP) and accumulates `grain_produced` in a field on itself — it does NOT write to `FinancialBook`.
3. After all children are closed, `WorkDayActivity.on_close()` reads `child.grain_produced` across all slots, sums them, and commits one balanced `FinancialBook` transaction: `debit Inventory:grain +N` / `credit Production_Output_Value +N`.
4. Then a second balanced transaction: `debit Wages_Expense +slots` / `credit Payable:{worker} +slots` (the wage accrual).

**Why aggregate at parent:** The `FinancialBook` entry for "grain produced" belongs to the work-day event, not to the individual slot. Auditors (and players) reading the FinancialBook see meaningful events: "WorkDay closed, 28 grain produced," not 28 individual one-grain entries per slot. Per-slot detail lives in the SkillsBook and in the activity tree itself, which is queryable.

**Why this doesn't preclude Samus's goals:** The activity tree is the audit trail at the slot level. `actor.books["financial"].entries("Inventory:grain", start, end)` returns the day-level summaries. `actor.active_activities` (a list maintained on the Actor) gives the running tree. Player UI that wants slot-by-slot detail reads the activity tree; player UI that wants financial summary reads the books. Both are first-class reads.

### 2.4 Pull-on-Open Mechanism for Market Supply (P2.Q4)

**Decision:** Producers register with their wholesale market at bootstrap. When the market opens, it calls `respond_to_supply_call()` on each registered supplier. The market proceeds with whoever responds — non-response is treated as "no supply offered this period."

```gdscript
# WholesaleMarket

var registered_suppliers: Array[NodePath] = []

func open_market(tick: int) -> void:
    for supplier_path in registered_suppliers:
        var supplier := get_node(supplier_path) as Actor
        if supplier == null: continue
        var offer := supplier.find_interest(ProductionInterest).respond_to_supply_call(self, tick)
        if offer.quantity > 0:
            queue_supply(supplier, offer.quantity, offer.cost_basis)

# ProductionInterest

func respond_to_supply_call(market: WholesaleMarket, tick: int) -> SupplyOffer:
    # The WeeklyProductionActivity has already closed (burst step ordering guarantees this)
    # The FinancialBook holds the period's output. Query it.
    var output := owner.books["financial"].balance("Production_Output_Value", _period_start_tick, tick)
    var wages := owner.books["financial"].balance("Wages_Expense", _period_start_tick, tick)
    var cost_basis := wages / output if output > 0.0 else 0.0
    return SupplyOffer.new(output, cost_basis)
```

`SupplyOffer` is a simple `RefCounted` with `quantity: float` and `cost_basis: float`. No persistence needed — it's ephemeral.

**The key insight here:** `respond_to_supply_call()` no longer needs a cached `weekly_cost_basis` field on `ProductionInterest`. It queries the `FinancialBook` directly. The cost-basis bug cannot recur because there is no cache to be stale. The books are always current.

**Non-response behavior:** If a supplier's `ProductionInterest` is absent, or `output == 0`, `SupplyOffer.quantity == 0` and the market skips them. Market proceeds. This replaces the current signal-driven push (which required `settle_weekly_production` to fire in the right order) with a market-controlled pull that is ordering-safe by construction.

---

## Section 3 — Force Carriers Map

### 3.1 Activity-to-Book-Entry Map, v0

Every state change in the simulation flows through this table. If an effect is not in this table, it has no architectural home and should not exist in v0.

| Activity | On close, writes to: | Entries |
|---|---|---|
| `WorkSlotActivity` | Worker SkillsBook | `credit farming +base_xp * aptitude_factor` |
| `WorkDayActivity` | Employer FinancialBook (2 transactions) | Tx1: `debit Inventory:grain +N, credit Production_Output_Value +N`. Tx2: `debit Wages_Expense +slots, credit Payable:{worker} +slots`. |
| `WagePaymentActivity` | Employer + Worker FinancialBook (1 joint transaction each) | Employer: `debit Payable:{worker} -coin, credit Cash -coin`. Worker: `debit Cash +coin, credit Wages_Income +coin`. |
| `WholesaleSaleActivity` | Producer + Merchant FinancialBook | Producer: `debit Cash +revenue, credit Inventory:grain -N, credit Cost_of_Goods_Sold +cost_basis*N`. Merchant: `debit Inventory:grain +N, debit Cash -price*N, credit Sales_Revenue -price*N` (net zero). |
| `RetailPurchaseActivity` | Merchant + Buyer FinancialBook | Merchant: `debit Cash +price, credit Inventory:grain -1, credit Cost_of_Goods_Sold +wholesale_cost`. Buyer: `debit Inventory:grain +1, credit Cash -price`. |
| `EatGrainActivity` | Buyer FinancialBook + VitalsBook | Financial: `debit Inventory:grain -1, credit Cost_of_Goods_Sold +0` (grain consumed, not sold). Vitals: `credit hunger +satiation_value`. |
| `LaborContractActivity` | Neither (long-running activity; no immediate entries) | Contract written to `accounts.contracts`; entries written by downstream activities. |
| `TaxPaymentActivity` | Actor + Lord FinancialBook | Actor: `debit Lord_Tax_Expense -tax, credit Cash -tax`. Lord: `debit Cash +tax, credit Taxes_Revenue +tax`. |

**Cost basis becomes a query:** `employer.books["financial"].balance("Wages_Expense", period_start, period_end) / employer.books["financial"].balance("Production_Output_Value", period_start, period_end)`. No cache. No snapshot. Order-independent.

### 3.2 Non-Activity-Driven Effects — Rule of Thumb (P3.Q2)

Three cases from the brief: taxes, spoilage, hunger drift.

**Rule:** An effect deserves its own activity when it has a named initiator, a discrete trigger point, and a meaningful audit trail. It should be a continuous function when it is physically continuous, has no meaningful per-instance identity, and would produce thousands of trivial entries.

Applied:

**Lord tax** → `TaxPaymentActivity`, initiated by the lord. Rationale: tax has a named initiator (the lord), a discrete moment (weekly settlement), and clear audit value ("when did the lord tax me and how much?"). The player's ability to see a `TaxPaymentActivity` in their books is a gameplay feature, not implementation overhead. Lord taxes become activities.

**Inventory spoilage** (phase 3+) → Continuous decay applied at period close, not a per-unit activity. Rationale: spoilage is physically continuous, has no named initiator, and 56 grain rotting over 7 days does not have 56 meaningful events — it has one: "this week's spoilage." Model as a single `SpoilageEntry` written to the FinancialBook at period close, applied as `debit Inventory:grain -N_spoiled, credit Spoilage_Expense +N_spoiled`. The entry is written by a period-close hook, not a discrete activity. This keeps the journal clean while preserving audit.

**Hunger drift** → Continuous decay applied at daily close, written as a single `VitalsBook` entry per day: `debit hunger -daily_rate`. Not a `HungerTickActivity` — the hunger tick has no initiator, no discrete meaning, and doing it per-slot would produce 56 trivial entries per actor per week. A single daily debit is enough for audit and debugging.

**The rule of thumb in one sentence:** If the player should care *who triggered it and why*, it's an activity; if the player should only care *that it accumulated*, it's a periodic function that writes a summary entry.

---

## Section 4 — Migration

### 4.1 Phase 2 Method → Activity Map (P4.Q1)

| Phase 2 method | Becomes | Books written |
|---|---|---|
| `WorkingInterest.do_one_work_slot()` | Creates + closes `WorkSlotActivity` | Worker SkillsBook (XP) |
| `WorkingInterest.deliver_grain_and_bill()` | Closes `WorkDayActivity` | Employer FinancialBook (grain inventory + wages accrual) |
| `EmployerInterest.pay_outstanding_wages()` | Creates + closes `WagePaymentActivity` per payable | Employer + Worker FinancialBook |
| `ProductionInterest.settle_weekly_production()` | **Deleted.** | Its job: cost-basis computation → FinancialBook query. Supply push → `respond_to_supply_call()` on market open. Period reset → no longer needed (books don't reset; period filtering is a query parameter). |
| `MercantileInterest.place_buy_order_at_wholesale()` | Demand push unchanged; creates no activity (declarative intent, not an event with effects) | None at push time; `WholesaleSaleActivity` writes entries at clearing |
| `WholesaleMarket.clear()` | For each match: creates + closes `WholesaleSaleActivity` | Producer + Merchant FinancialBook |
| `RetailMarket.clear()` | For each match: creates + closes `RetailPurchaseActivity` | Merchant + Buyer FinancialBook |
| `LaborMarket.clear()` | For each match: creates `LaborContractActivity` (long-running, stays open until contract ends) | No entries at creation; downstream activities write entries |
| `WindowBus.fire_weekly_books_close()` + A3 signal | **Deleted.** | Replaced by market's pull-on-open mechanism and FinancialBook queries. |
| `accounts.weekly_costs` / `accounts.weekly_outputs` | **Deleted.** | Replaced by FinancialBook `balance("Wages_Expense", period)` / `balance("Production_Output_Value", period)`. |
| `accounts.skills: Dictionary` | **Deleted.** | Replaced by `SkillsBook`. |
| `Payable` resource | **Deleted.** | Replaced by `Payable:{worker}` account in employer's FinancialBook. |

**The A2/A3/A4 pattern (cost-basis cache + `weekly_books_close` signal + `settle_weekly_production`) is entirely replaced.** These three architectural decisions from the Phase 2 implementation plan are the exact brittleness the rebuild eliminates. They go away together.

### 4.2 Rebuild, Not Extension (P4.Q2)

**Confirmed: this rebuild replaces Phase 2 implementation, not extends it.**

Migration-in-place would require the new activity layer and the old Interest-mutation model to coexist, which means two sources of truth for every ledger value. That's worse than either alone. The rebuild proceeds as a clean pass. What is preserved:

- **Phase 2 math directive** — all formulas (wage, wholesale clearing, retail equilibrium) remain authoritative. The rebuild carries the same math; it changes where math results are recorded, not what the math computes.
- **Phase 2 architecture directive** — the persistence-vs-transience principle survives, but the "Accounts as persistent ledger" clause now means "Books are the persistent ledger." Interest remains transient behavior. The class shapes change; the principle does not.
- **The 5 acceptance criteria** — still hold (see 4.4 below).

What is not preserved: `weekly_costs`, `weekly_outputs`, `skills` Dictionary on `Accounts`; `Payable` resource; `settle_weekly_production` method; `weekly_books_close` signal.

### 4.3 Burst Orchestrator's New Role (P4.Q3)

The `WindowOrchestrator` becomes an activity initiator, not a signal emitter.

```gdscript
func fire_weekly_burst() -> void:
    var burst := WeeklyBurstActivity.new()
    burst.begin(SimClock.current_tick)

    # Step 1 — wage settlement
    for actor in region.all_actors():
        var ei := actor.find_interest(EmployerInterest)
        if ei == null: continue
        for worker_path in ei.get_payable_workers():
            var wage_act := WagePaymentActivity.new()
            wage_act.participants = [actor.get_path(), worker_path]
            burst.child_activities.append(wage_act)
            wage_act.begin(SimClock.current_tick)
            wage_act.close(SimClock.current_tick)

    # Step 2 — wholesale market opens (pull model)
    wholesale_market.open_market(SimClock.current_tick)  # pulls supply internally
    wholesale_market.clear_market(SimClock.current_tick)  # creates WholesaleSaleActivity per match

    # Step 3 — retail clear (similar pattern)
    retail_market.open_market(SimClock.current_tick)
    retail_market.clear_market(SimClock.current_tick)

    # Step 4 — labor market
    labor_market.open_market(SimClock.current_tick)
    labor_market.clear_market(SimClock.current_tick)

    burst.close(SimClock.current_tick)
```

**The signal bus does not go away entirely.** `WindowBus` continues to carry signals for events that need true broadcast (work window open/close for daily slots, which many Interests react to). What goes away is using bus signals for *coordination ordering* — the `weekly_books_close` signal that existed solely to ensure cost-basis ran before supply push. That coordination is now structural: the market's `open_market()` pulls supply, which reads the FinancialBook, which was written by wage settlement in the step before. Order is enforced by call sequence within `fire_weekly_burst()`, not by signal emit order that any human can accidentally reorder.

**The burst orchestrator's job is now:** sequence the week's activities in the right order, initiating and closing them. It does not emit "something happened" signals and hope the right listeners are wired. It calls things directly, in order, and each thing closes itself.

### 4.4 Phase 2 Acceptance Criteria — Reproduction

The five acceptance criteria from the Phase 2 implementation plan remain the target. Under the new model:

**AC #1** (both workers have ACTIVE LaborContracts after Week 1 burst): `LaborMarket.clear_market()` creates `LaborContractActivity` objects, which write `LaborContract` resources to `accounts.contracts`. Same outcome, different path.

**AC #2** (contracts appear on both parties' accounts): `LaborContractActivity.on_close()` writes the contract to both participants' `accounts.contracts`. Identical behavior.

**AC #3** (trace numbers — LandOwner 200 coin, workers 28 each, merchant ~44): `WagePaymentActivity.on_close()` transfers coin and writes FinancialBook entries. `FinancialBook.balance("Cash")` is the actor's coin. The numbers are identical because the math is identical; only the recording mechanism changes.

**AC #4** (WholesaleMarket clears at price 1.00, supply=56): `WholesaleSaleActivity` is created during `wholesale_market.clear_market()`. The clearing price formula is unchanged. Print line comes from the activity close.

**AC #5** (RetailMarket clears at P_m≈1.10, all actors receive grain): `RetailPurchaseActivity` per buyer. Math unchanged. The acceptance criteria test math outcomes, not implementation internals — all five continue to hold.

---

## Closing Punch List

### Decisions Made (committed, no Round 2 needed)

1. **`Book` base class** with `write_entry()` / `balance()` / `entries()` interface — shared by all book types.
2. **Strict double-entry in `FinancialBook` only** — `commit_transaction()` enforces balanced entries; `SkillsBook` and `VitalsBook` use the same interface without balance enforcement.
3. **Universal chart of accounts** — all actors share one vocabulary; unused accounts have zero balance. Parameterized account names (`Inventory:grain`, `Payable:bob`) compose at write time.
4. **`Activity extends Resource`** — in-flight activities survive save/load; hierarchical tree is naturally serializable.
5. **Atomic writes at `on_close()`** — no progressive entries; transactional semantics; books always reconcile.
6. **Day-activity cascades, slot-effects propagate to parent before FinancialBook write** — SkillsBook entries written at slot close; FinancialBook entries written at day close from aggregated slot data.
7. **Pull-on-open for wholesale supply** — market calls `respond_to_supply_call()` on registered suppliers; cost-basis is a FinancialBook query, not a cached field.
8. **Force carrier rule of thumb** — named initiator + discrete trigger + audit value → activity; physically continuous + no meaningful per-instance identity → periodic function writing a summary entry.
9. **A2/A3/A4 pattern deleted entirely** — `weekly_costs`, `weekly_outputs`, `weekly_books_close` signal, `settle_weekly_production`, `Payable` resource all removed.
10. **Rebuild replaces, does not extend** — clean pass; Phase 2 math and architecture principles preserved, implementation replaced.
11. **Burst orchestrator becomes activity initiator** — calls things directly in order; coordination is structural, not signal-ordering.
12. **All 5 Phase 2 acceptance criteria reproduced** — math unchanged; recording mechanism changed; criteria still hold.

### Round 2 Dependencies (flagged for author adjudication)

- **R2.1 — Aptitude factor in `WorkSlotActivity` XP formula.** The `supplement-prototype-gaps.md` XP formula is `xp_gain = base_xp * (w_ATH * ATH + w_CHA * CHA + w_INT * INT)`. Does `WorkSlotActivity.on_close()` read `AptitudeProfile` from the actor now, or does the skill formula land in a later phase? I recommend it reads the profile now (the seam exists, the math is locked), but this requires `AptitudeProfile` to exist on actors in the rebuild. If Zach wants to defer aptitudes, `WorkSlotActivity` uses `base_xp` flat. Needs author call.

- **R2.2 — `WholesaleSaleActivity` double-book balancing.** The producer's COGS entry (`credit Cost_of_Goods_Sold`) requires the cost basis to be known at sale time. The rebuild computes this via FinancialBook query. If the query returns zero (first-week edge case, same as Phase 2's guard clause), COGS entry is zero. This is correct behavior but should be explicitly validated in the trace.

- **R2.3 — Player legibility of activity tree.** I have stated my position: activity objects are observable without writing to books. Samus's paper will have a position on what the player UI *calls* activities, how they're surfaced, and what access cost looks like. Her framing may require `Activity` to carry a `display_name: StringName` and a `is_player_visible: bool` field. I'm fine with that — it's additive. But the field names and player-facing vocabulary are hers to define, not mine. Round 2 adjudication needed on this interface.

- **R2.4 — `EatGrainActivity` trigger.** The brief lists `EatGrainActivity` as writing to both FinancialBook and VitalsBook. Who initiates it? In Phase 2, grain interest placed a demand order; the retail market cleared it. Under the new model, the `RetailPurchaseActivity` closes and grain enters inventory. The subsequent eating is a separate decision the actor makes. Does eating happen automatically (every actor eats whatever grain they hold at end of day, up to their daily need)? Or is it a deliberate activity the actor schedules? This connects to Samus's routine/behavior design. Flag for Round 2.
