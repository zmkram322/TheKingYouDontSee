---
name: Phase 2.5 — Books, Activity, & Force Carriers Architecture Directive
status: directive (authoritative — triggers coding-pass rebuild)
date: 2026-05-04
supersedes:
  - _bmad-output/phase-2-architecture-directive.md (partially — see Section 0.2)
  - The A2/A3/A4 architectural decisions in C:/Users/zachm/.claude/plans/drifting-dazzling-flask.md
preserves:
  - _bmad-output/phase-2-math-directive.md (sections 1+2 — math is unchanged)
  - The Phase 2 acceptance criteria (5 ACs — must reproduce numerically)
  - The persistence-vs-transience principle (re-framed: Books are now persistent ledger, Interest still transient behavior)
session_inputs:
  - _bmad-output/phase-2.5-activity-architecture-brief.md
  - _bmad-output/phase-2.5-round-1-cloud-architecture.md
  - _bmad-output/phase-2.5-round-1-samus-player-facing.md
  - _bmad-output/phase-2.5-round-2-cloud-d1-revision.md
  - _bmad-output/phase-2.5-round-2-samus-d1-revision.md
  - Author's macro-legibility framing (this session, post-Round-2)
  - Author's persistent-vs-transient activity pattern decision (this session)
authors:
  - Cloud Dragonborn (Game Architect)
  - Samus Shepard (Game Designer)
  - Author adjudication (Zach)
---

# Phase 2.5 — Books, Activity, & Force Carriers Architecture Directive

## 0. Preamble

### 0.1 What this directive is

This directive authorizes a **coding-pass rebuild** that consolidates three architectural primitives the Phase 2 implementation surfaced as missing:

1. **Per-actor books** (parallel ledgers per category — financial, skills, vitals).
2. **Activity as a first-class primitive** (the only mechanism that mutates state).
3. **Force carriers** (every effect category has an architectural source — activities producing book entries).

The Phase 2 implementation works arithmetically — all five acceptance criteria pass on the 14-day headless trace — but is architecturally hollow: state mutates through Interest method calls with no durable record of why; causality lives only in signal-emit order; and any coordination mechanism more complex than "fire signals in the right sequence" breaks silently. The cost-basis bug (a user-driven orchestrator reorder produced `wholesale_price=0.00` silently) was the symptom that surfaced this.

This rebuild **replaces** the Phase 2 implementation, not extends it. The math is preserved; the recording mechanism is rebuilt.

### 0.2 What this directive supersedes

From `phase-2-architecture-directive.md`:
- "Accounts as persistent ledger" — re-framed: **Books are the persistent ledger**. The `Accounts` resource is decomposed into per-category Books.
- The Interest = transient behavior principle survives unchanged.
- Persistence-vs-transience as the overarching design grammar survives unchanged.

From `drifting-dazzling-flask.md` (Phase 2 implementation plan):
- **A2** (cost-basis cache on `ProductionInterest`) — deleted.
- **A3** (`weekly_books_close` signal) — deleted.
- **A4** (`settle_weekly_production` method) — deleted.
- The remaining decisions (A1, A5–A9) are preserved or absorbed naturally.

What is **not** superseded:
- `phase-2-math-directive.md` (sections 1+2) — all formulas (wage clearing, wholesale clearing, retail equilibrium) remain authoritative. The rebuild carries the same math; it changes where math results are recorded.
- The five Phase 2 acceptance criteria — must hold numerically under the new model (Section 8).

---

## 1. The Foundational Design Stance

### 1.1 Macro-legibility orientation (load-bearing)

The player-facing target for this game is **macro-pattern legibility**, not per-moment detail. The patterns that matter:

- "The workers at this mill are usually well fed."
- "There's been high turnover at this farm."
- "This lord has been operating at a loss for two months — someone has been loaning him money."

These patterns are **time-aggregated** (8-week trends, "two months straight") and **population-aggregated** ("the workers at this mill", plural). They are not per-slot per-day records. The architecture must prioritize:

1. **Multi-period queries** as the primary legibility primitive — `book.balance(account, weeks_ago(8), now)` and trend-shape variants.
2. **Cross-actor / population queries** as a first-class concern — aggregating books across population members (a mill's workers, a lord's domain, a region).
3. **Coarser write granularity by default** — a day is a meaningful unit; a slot is not. Slot-level data exists at runtime as computation, not as durable record.

This stance resolves D1 (slot-vs-day aggregation): **day-level resolution is correct. Per-slot writes are over-engineering for v0.** Slot-level visibility may become a player-investment-gated feature when influence grows (steward/advisor systems), but does not constrain the v0 architecture.

### 1.2 The three pillars are one primitive expressed three ways

- **Books** are the system of record (queryable state).
- **Activities** are the only thing that mutates books (force carriers).
- **Force carriers** is the rule that links them: every effect category has an architectural source, and that source is an activity that closes and writes journal entries.

If a state mutation does not flow through an activity-close → book-entry pathway, it does not exist in this rebuild. This is the architectural constraint that makes the books trustworthy.

---

## 2. Pillar 1 — Books

### 2.1 `Book` base class

Shared base for all book types. Same query interface across financial, skills, and vitals.

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
        total += e.amount
    return total

func entries(account: StringName, period_start: int, period_end: int) -> Array[JournalEntry]:
    var out: Array[JournalEntry] = []
    for e in _journal:
        if e.account == account and e.tick >= period_start and e.tick <= period_end:
            out.append(e)
    return out
```

`JournalEntry` is a `Resource` with: `account: StringName`, `amount: float` (credit-positive convention), `tick: int`, `activity_ref: StringName`, `note: StringName` (optional).

**Sign convention:** positive amount = credit; negative amount = debit. Unifies across all book types.

### 2.2 `FinancialBook`

Extends `Book`. Adds `commit_transaction(entries: Array[JournalEntry]) -> bool` which validates the transaction is balanced (sum of all entry amounts == 0) before writing. Unbalanced transactions fail with `push_error` and return `false` — no partial writes.

**Decision:** Strict double-entry **for FinancialBook only**. Skills and Vitals use the shared `Book` interface without balance enforcement. (Brief P1.Q1 / P1.Q4 — option (a) shared base, financial-only enforcement.)

**Universal chart of accounts (v0):**

*Assets (credit increases):*
- `Cash` — coin held
- `Inventory:{good_id}` — parameterized by good (`Inventory:grain`, future `Inventory:cloth`, etc.)
- `Receivable:{counterparty}` — coin owed to this actor

*Liabilities (debit increases):*
- `Payable:{counterparty}` — coin this actor owes

*Equity:*
- `Owner_Equity` — initial capitalization

*Revenue (credit increases):*
- `Wages_Income`
- `Sales_Revenue`

*Expenses (debit increases):*
- `Wages_Expense`
- `Cost_of_Goods_Sold`
- `Lord_Tax_Expense`
- `Production_Output_Value` (the credit side of inventory accrual at production close)

**One universal chart, not per-actor-type.** Every actor has the same account vocabulary; unused accounts have zero balance. Adding a new account category in phase 3+ is a one-string change, not a chart refactor.

**Counterparty identifiers are opaque `StringName` keys.** `Payable:rival_lord_castellan` is a record of the counterparty's *identifier*, not their display name. Display-name resolution is gated through a separate (future) player-knowledge system. **This is a deliberate gameplay seam** — Section 5.3.

### 2.3 `SkillsBook` and `VitalsBook`

Both extend `Book` without balance enforcement. Same interface as FinancialBook (just `write_entry` / `balance` / `entries`).

**`SkillsBook`** — accounts are skill identifiers (`farming`, `bartering`, `market_perception`, `charisma`, etc.). Entries credit XP earned. Force carriers: activity-close at the persistent activity level (e.g., `WorkDayActivity` writes day-aggregated farming XP; `SocializeActivity` writes per-event charisma XP).

**`VitalsBook`** — accounts are vital identifiers (`hunger`, `fatigue`, `morale`). Sign convention: positive balance = satisfied; negative entry = depletion. `VitalsBook.balance("hunger")` is the actor's current hunger level. Force carriers: activity-close at the persistent activity level (work depletes; eating replenishes (when implemented); socializing replenishes morale and depletes fatigue).

### 2.4 Actor `books` field

The Phase 2 `Accounts` resource is decomposed:

```gdscript
class_name Accounts
extends Resource

@export var books: Dictionary = {}    # StringName → Book
@export var contracts: Array[LaborContract] = []
@export var owned_resources: Array[OwnedResource] = []
```

`actor.accounts.books["financial"]` is the `FinancialBook`. `actor.accounts.books["skills"]` is the `SkillsBook`. `actor.accounts.books["vitals"]` is the `VitalsBook`.

**Removed from `Accounts`** (now live in books): `coin`, `inventory`, `payables`, `receivables`, `weekly_costs`, `weekly_outputs`, `skills` Dictionary.

**Preserved on `Accounts`**: `contracts` (these are not journal entries; they're persistent agreements), `owned_resources` (parcels, mills, etc. — persistent assets, not flow records).

The `Payable` resource is **deleted** — replaced by `Payable:{counterparty}` accounts in the FinancialBook.

### 2.5 Query primitives (first-class for macro legibility)

The query interface explicitly supports macro-pattern reads. v0 implements these directly; phase 3+ adds indexing for performance.

**Multi-period queries:**
```gdscript
book.balance(account, period_start, period_end)               # period activity
book.balance(account, -1, current_tick)                       # all-time balance
book.entries(account, period_start, period_end)               # raw entries in period
```

Phase 3+ adds:
```gdscript
book.balance_trend(account, window_size, num_windows) -> Array[float]   # rolling-window trend
```

**Cross-actor population queries** — Section 5.2 below. This is a **new architectural primitive** that neither Round 1 paper addressed; it requires its own design pass before v0 lands the population-aggregation use cases. v0 ships the per-actor query interface; population queries are a v0.5 add-on.

---

## 3. Pillar 2 — Activity

### 3.1 `Activity` base class

```gdscript
class_name Activity
extends Resource

@export var activity_type: StringName = &""
@export var participants: Array[NodePath] = []
@export var started_tick: int = -1
@export var closed_tick: int = -1
@export var state: StringName = &"open"  # "open" | "closed" | "aborted"
@export var parent_activity_ref: NodePath = NodePath("")  # empty = root activity
@export var child_activities: Array[Activity] = []

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
            child.close(tick)
    closed_tick = tick
    state = &"closed"
    return on_close()

func abort(tick: int) -> void:
    state = &"aborted"
    for child in child_activities:
        if child.state == &"open":
            child.abort(tick)
    on_abort()

func on_begin() -> void: pass
func on_close() -> bool: return true
func on_abort() -> void: pass
```

**Decision:** `Activity extends Resource` (brief P2.Q1, option (b)). In-flight activities survive save/load. Hierarchical activity trees serialize naturally. `Resource` overhead vs `RefCounted` is negligible at this scale.

### 3.2 The persistent-vs-transient activity rule

**Each activity type declares whether it is persistent or transient.** This rule resolves the resolution question across the whole simulation, not just for work.

**Persistent activity:**
- Survives in the activity tree after close (saved with the game).
- Writes book entries at close.
- Has its own outcome fields readable by the activity-tree query path.
- Is something the player or simulation can ask about later by name ("what was Bob's WorkDay on day 5?").

**Transient activity:**
- Discarded after close. Does not persist.
- Writes nothing to books on its own.
- Computes effects, then **adds them to its parent's accumulator fields**.
- Has no individual identity worth remembering ("slot 2 of day 5" is not a meaningful retrievable thing).

The simulation rule:
- If an activity has no parent → it must be persistent.
- If an activity has a parent → it must be transient (its parent records it).
- A persistent activity may have transient children, but transient children always belong to a persistent parent.

### 3.3 Lifecycle semantics

**Persistent activities:** All book entries are written atomically in `on_close()`. No progressive writes during the activity's lifetime. Either the activity closes and all its entries land, or it aborts and no entries land. **Books always reconcile.**

**Transient activities:** Compute deltas in `on_close()` and add them to the parent's accumulator fields. No book writes. After the parent reads the deltas (at parent's `on_close()`), the transient instance is no longer referenced and is discarded.

**Transactional integrity** (persistent activities): If `on_close()` fails (e.g., insufficient funds for a payment), it returns `false` and writes nothing. The caller branches on the failure.

### 3.4 Worked example — Work activity hierarchy

This is the canonical example of the persistent-vs-transient pattern.

**`WorkDayActivity`** (persistent):
```gdscript
class_name WorkDayActivity
extends Activity

# Tally fields — accumulated by transient WorkSlotActivity children.
@export var grain_produced_today: float = 0.0
@export var farming_xp_earned: float = 0.0
@export var calories_burned: float = 0.0
@export var fatigue_incurred: float = 0.0
@export var wages_accrued: float = 0.0

# Participants: [worker_path, employer_path]

func on_close() -> bool:
    var employer := _resolve(participants[1])
    var worker := _resolve(participants[0])

    # FinancialBook (employer) — two balanced transactions.
    var grain_tx: Array[JournalEntry] = [
        JournalEntry.new("Inventory:grain", grain_produced_today, closed_tick, &"WorkDayActivity"),
        JournalEntry.new("Production_Output_Value", -grain_produced_today, closed_tick, &"WorkDayActivity"),
    ]
    employer.accounts.books["financial"].commit_transaction(grain_tx)

    var wage_tx: Array[JournalEntry] = [
        JournalEntry.new("Wages_Expense", -wages_accrued, closed_tick, &"WorkDayActivity"),
        JournalEntry.new("Payable:%s" % worker.id, wages_accrued, closed_tick, &"WorkDayActivity"),
    ]
    employer.accounts.books["financial"].commit_transaction(wage_tx)

    # SkillsBook (worker) — one entry per day.
    worker.accounts.books["skills"].write_entry(
        JournalEntry.new("farming", farming_xp_earned, closed_tick, &"WorkDayActivity")
    )

    # VitalsBook (worker) — depletion entries.
    worker.accounts.books["vitals"].write_entry(
        JournalEntry.new("hunger", -calories_burned, closed_tick, &"WorkDayActivity")
    )
    worker.accounts.books["vitals"].write_entry(
        JournalEntry.new("fatigue", -fatigue_incurred, closed_tick, &"WorkDayActivity")
    )

    return true
```

**`WorkSlotActivity`** (transient):
```gdscript
class_name WorkSlotActivity
extends Activity

# Class-level (script constants on the type itself):
const W_ATH := 0.7
const W_CHA := 0.0
const W_INT := 0.3
const BASE_GRAIN := 7.0
const BASE_XP := 12.0
const BASE_CALORIES := 90.0
const BASE_FATIGUE := 0.25
const SLOTS_PER_DAY := 4

func on_close() -> bool:
    var worker := _resolve(participants[0])
    var aptitude := worker.aptitude_profile
    var aptitude_factor := W_ATH * aptitude.ATH + W_CHA * aptitude.CHA + W_INT * aptitude.INT

    var slot_grain := BASE_GRAIN * (1.0 + _variance(aptitude_factor))
    var slot_xp := BASE_XP * aptitude_factor
    var slot_calories := BASE_CALORIES
    var slot_fatigue := BASE_FATIGUE
    var slot_wage := worker.find_active_contract().day_wage / SLOTS_PER_DAY

    var parent: WorkDayActivity = parent_activity_ref as WorkDayActivity
    parent.grain_produced_today += slot_grain
    parent.farming_xp_earned += slot_xp
    parent.calories_burned += slot_calories
    parent.fatigue_incurred += slot_fatigue
    parent.wages_accrued += slot_wage

    return true   # transient — no book writes

func _variance(_factor: float) -> float:
    # roll based on aptitude_factor; details in Phase 2 math directive
    return 0.0
```

**Key points:**
- Aptitude weights live as **class-level constants on `WorkSlotActivity`** (R2.1 adjudication). Different work-activity classes (e.g., a future `BlacksmithSlotActivity`) declare their own weights for their own skill XP.
- `WorkSlotActivity` does no book writes. It mutates the parent's accumulator fields.
- `WorkDayActivity` is the persistent unit — its outcome fields survive in the activity tree; it writes books at close.

### 3.5 Pull-on-open mechanism for market supply

When `wholesale_market.open_market()` fires, the market polls registered suppliers via `respond_to_supply_call()`. Cost basis is computed as a `FinancialBook` query, not a cached field.

```gdscript
# WholesaleMarket
var registered_suppliers: Array[NodePath] = []

func open_market(tick: int) -> void:
    for supplier_path in registered_suppliers:
        var supplier := get_node(supplier_path) as Actor
        if supplier == null: continue
        var production := supplier.find_interest(ProductionInterest)
        if production == null: continue
        var offer := production.respond_to_supply_call(self, tick)
        if offer.quantity > 0:
            queue_supply(supplier, offer.quantity, offer.cost_basis)
        else:
            # D3: partial-supply state is player-readable.
            _record_non_response(supplier, tick)

# ProductionInterest
func respond_to_supply_call(market: WholesaleMarket, tick: int) -> SupplyOffer:
    var book := owner.accounts.books["financial"]
    var period_start := tick - market.period_length
    var output := book.balance("Production_Output_Value", period_start, tick)
    var wages := -book.balance("Wages_Expense", period_start, tick)  # expense stored negative
    var cost_basis := wages / output if output > 0.0 else 0.0
    return SupplyOffer.new(output, cost_basis)
```

**The cost-basis bug cannot recur** — there is no cache. The books are always current, and `respond_to_supply_call()` queries them directly. Order-independent by construction.

**D3 — Partial-supply visibility:** When a supplier returns `quantity == 0`, the market records a **non-response event** that is player-readable as part of the market-clearing event-log. "Some suppliers had not delivered yet" is never silent. Concrete shape: `WholesaleMarket` carries a `last_clearing_event: MarketClearingEvent` Resource that lists responding suppliers, non-responders, total supply, total demand, and clearing price. Player UI reads this directly.

---

## 4. Pillar 3 — Force Carriers

### 4.1 Activity-to-book-entry map (v0)

Every state mutation in v0 flows through this table. If an effect is not here, it has no architectural home and must not exist in v0 code.

| Activity | Persistent? | On close, writes to: |
|---|---|---|
| `WorkSlotActivity` | **Transient** | Nothing — accumulates deltas on `WorkDayActivity` parent. |
| `WorkDayActivity` | Persistent | Employer FinancialBook (grain Tx + wage accrual Tx); Worker SkillsBook (farming XP); Worker VitalsBook (hunger, fatigue). |
| `WagePaymentActivity` | Persistent | Employer FinancialBook (`debit Payable:{w}, credit Cash`); Worker FinancialBook (`debit Cash, credit Wages_Income`). |
| `WholesaleSaleActivity` | Persistent | Producer FinancialBook (`debit Cash, credit Inventory:grain, credit Cost_of_Goods_Sold`); Merchant FinancialBook (`debit Inventory:grain, credit Cash, debit Sales_Revenue`). |
| `RetailPurchaseActivity` | Persistent | Merchant FinancialBook (`debit Cash, credit Inventory:grain, credit COGS`); Buyer FinancialBook (`debit Inventory:grain, credit Cash`). |
| `LaborContractActivity` | Persistent (long-running) | No financial entries on creation; writes contract to both parties' `accounts.contracts`. Downstream activities (`WorkDayActivity`, `WagePaymentActivity`) write entries. |
| `TaxPaymentActivity` | Persistent | Actor FinancialBook (`debit Lord_Tax_Expense, credit Cash`); Lord FinancialBook (`debit Cash, credit Taxes_Revenue` — new revenue account). |
| `SocializeActivity` | Persistent | Initiator VitalsBook (`credit morale, debit fatigue`); Initiator SkillsBook (`credit charisma`); partner books symmetrically. |
| `EatGrainActivity` | **Deferred** | R2.4 — eating becomes its own consumption system when hunger/Caloric Intake VitalsBook lands in a later phase. Not in v0. |

### 4.2 Force carrier rule of thumb (P3.Q2)

An effect deserves its **own activity** when:
- It has a named initiator.
- It has a discrete trigger point.
- It has meaningful audit value (the player or simulation should be able to ask "when did this happen and who caused it").

An effect is a **continuous function / period-close hook** when:
- It is physically continuous.
- It has no named initiator.
- It would produce thousands of trivial entries at per-instance granularity.

**Applied to v0:**
- **Lord tax** → `TaxPaymentActivity` (named initiator, discrete moment, audit value).
- **Inventory spoilage** (phase 3+) → period-close hook writing one `Spoilage_Expense` entry per period. Not a per-unit activity.
- **Hunger drift** (when implemented in the hunger phase) → daily-close hook writing one VitalsBook entry per day. Not per-tick.

**The one-sentence rule:** *If the player should care who triggered it and why, it's an activity. If the player should only care that it accumulated, it's a periodic function writing a summary entry.*

### 4.3 The persistent-vs-transient pattern recurs

The work-day / work-slot pattern is **the first instance** of a recurring architectural pattern. Future systems will exhibit it:

| Domain | Persistent (writes books) | Transient (computes, rolls up) |
|---|---|---|
| Work | `WorkDayActivity` | `WorkSlotActivity` |
| Travel | `JourneyActivity` (whole trip) | `TravelDayActivity` (each day's leg) |
| Construction | `BuildingProjectActivity` | `ConstructionDayActivity` (or `ConstructionWeekActivity`) |
| Harvest | `HarvestSeasonActivity` | `HarvestDayActivity` |
| Military | `CampaignActivity` | `BattleActivity`, `MarchActivity` |
| Negotiation | `NegotiationActivity` (final terms) | `NegotiationRoundActivity` (each exchange) |
| Investigation | `InvestigationActivity` | `InquiryActivity` (each conversation/ledger-read) |

**v0 implements only the work pattern.** The directive lifts the rule to a first-class architectural concept so future systems inherit the same vocabulary and the resolution-question is never re-litigated per-system.

**Some activities have no transient sub-pattern.** One-shot events — `SocializeActivity`, `WagePaymentActivity`, `WholesaleSaleActivity`, `RetailPurchaseActivity`, `TaxPaymentActivity` — are themselves the smallest persistent unit. Don't force the pattern where it doesn't fit.

---

## 5. Author's Architectural Additions

These three elements are not in either Round 1 paper. They emerged from author adjudication and must be encoded in v0 (or flagged for v0.5).

### 5.1 Multi-period queries are the central legibility primitive

Phrases like "operating at a loss for two months straight" and "high turnover at this farm" are queries over a **time window**. The Book API supports this directly via `period_start` / `period_end` parameters. v0 ships these.

**Player-facing query patterns the architecture supports** (UI implementation is post-v0):
- "Last N weeks of cash flow": `book.balance("Cash", weeks_ago(N), now)` then trend-shape.
- "Operating at a loss?": `book.balance("Sales_Revenue", weeks_ago(N), now) + book.balance("Wages_Expense", weeks_ago(N), now)` — sign-tested.
- "Turnover": count of `LaborContractActivity` close events over a period (queries the activity tree, not a book — but same period-window primitive).

**Phase 3+ adds:** trend-shape helpers (`balance_trend`, `entries_grouped_by_period`), and indexing for performance once the journal grows.

### 5.2 Cross-actor / population queries — new primitive (v0.5)

"The workers at this mill are usually well fed" requires aggregating `VitalsBook.hunger` across the mill's worker pool. **Neither Round 1 paper addressed this**, and the per-actor book interface alone does not deliver it.

**v0 does not ship this primitive.** v0 ships per-actor books and the foundational activity model. Population aggregation lands in **v0.5**, after the books are in place and we know what the actual query patterns look like.

**v0.5 design seam (preserved, not implemented):**
- A `Population` interface that wraps a queryable group of actors (mill workers, lord's domain, region).
- A query primitive: `population.balance_avg(book_type, account, period)`, `population.balance_distribution(book_type, account, period)`, `population.entries_aggregated(book_type, account, period)`.
- Concrete population types likely needed: `MillWorkers`, `RegionalActors`, `LordsDomain`. Each owns the rule for "who is in this population" (a mill knows its employed workers; a region knows its inhabitants; a lord knows their subjects).

**v0 architecture must not preclude this.** Specifically: actors must be discoverable as a population (not just by `NodePath`). A mill must have a way to enumerate its workers. The directive flags this as a v0 design constraint: **employment relationships and place-of-work must be queryable as populations from day one**, even if no v0 code aggregates over them yet.

### 5.3 Counterparty mystery as a preserved gameplay seam

When a player reads Lord Harwick's `FinancialBook` and sees `Payable:rival_lord_castellan +500`, two things must be true:

1. The book entry carries the **counterparty identifier** (`rival_lord_castellan`), a `StringName`.
2. Resolving "who is rival_lord_castellan and why are they loaning Harwick money?" goes through a **separate gate** — the player's social/knowledge graph (a future system).

**v0 architecture commitment:** Counterparty identifiers in book entries are opaque `StringName` keys, not display names or actor references. Display-name resolution and "do I know who this is?" gating live in a future system that v0 must not block.

This gives free gameplay surface: **the books say what happened; figuring out *who* is the player's investigation work**. No code is written for this in v0; the architecture is friendly to it because counterparties are already opaque identifiers in the chart of accounts.

---

## 6. Player-Legibility Framework (Samus's domain)

These are the player-facing commitments the architecture must support. v0 may not implement the UI; the architecture must not preclude it.

### 6.1 Activity visibility (proximity-and-attention gated)

**Activities are observable to anyone physically present and looking.** The fact that an actor is doing work, the type of work, and rough progress are not gated by skill or relationship — they are gated by *being there and looking*.

**In-flight observability is first-class** (D4). The activity tree's open activities are queryable in real time. The player observation system reads activities by NodePath query: `actor.current_activities() -> Array[Activity]`. This is not a save/load side-effect — it is a primary use case.

### 6.2 Book access (skill / relationship / diegetic gated)

The four books have **different access costs**, codified in the architecture as separate read paths the future UI/gameplay layer will gate independently:

| Book | Access cost | Player verb |
|---|---|---|
| `SkillsBook` | Cheap (behavioral) | Watch them work; small `market_perception` check for precision |
| `VitalsBook` | Moderate (behavioral) | Read posture/mood; relationship gives precise numbers |
| `ReputationBook` (phase 3+) | Network (gossip-flavored, decays with source contact) | Cultivate sources, spend time in taverns |
| `FinancialBook` | Expensive (legal/private) | Steward on payroll, bribed tax-roll, high `market_perception` for inference |

**The player-character's own books are always free to read, completely.** This is the reference point — you know exactly why you're in your position; the work is understanding why everyone else is in theirs.

**Architecture commitment:** v0 does not gate book reads; the gates live in the future UI/gameplay layer. But the architecture must cleanly support **read-with-precision-level** — `book.balance(account)` returns the precise number; future inference layer can wrap that with "approximately N" / "between A and B" / "appears prosperous" based on the reader's investment.

### 6.3 Vocabulary policy

**No internal class names surface in player-facing UI:**
- `WorkSlotActivity`, `WorkDayActivity`, `FinancialBook`, `SkillsBook`, `VitalsBook`, `JournalEntry` — all internal.
- Diegetic equivalents: *work, day's labor, accounts, records, condition, entry, line in the accounts.*
- `Activity` → never the word "activity" — always *work, deal, payment, errand, contract, delivery.*
- `Force carrier` → entirely internal; no player equivalent needed.

**Words that are player-safe with care:**
- "Skill" — natural vocabulary.
- "Slot" — only as temporal language ("morning slot", not "slot 2 of 4"). Often replaced entirely with time-of-day phrasing.
- "Cost basis" — internal. The player sees the gap between cost and revenue, not the term.

The architecture carries a `display_name: StringName` field on the `Activity` base class for UI surfacing. Diegetic naming lands at UI implementation time — the architecture does not enforce specific words but reserves the field.

---

## 7. Migration & Burst Orchestrator

### 7.1 Phase 2 method → new structure

| Phase 2 method | Becomes | Books written |
|---|---|---|
| `WorkingInterest.do_one_work_slot()` | `WorkSlotActivity` (transient) | None directly — accumulates to parent `WorkDayActivity` |
| `WorkingInterest.deliver_grain_and_bill()` | `WorkDayActivity.on_close()` | Employer FinancialBook (grain Tx + wage Tx); Worker SkillsBook + VitalsBook |
| `EmployerInterest.pay_outstanding_wages()` | `WagePaymentActivity` per payable | Employer + Worker FinancialBook |
| `ProductionInterest.settle_weekly_production()` | **Deleted** | Cost basis is now a FinancialBook query in `respond_to_supply_call()` |
| `MercantileInterest.place_buy_order_at_wholesale()` | Demand push (declarative; no activity) | None at push; `WholesaleSaleActivity` writes at clearing |
| `MercantileInterest.send_inventory_to_retail()` | Supply push (declarative; no activity) | None at push; `RetailPurchaseActivity` writes at clearing |
| `WholesaleMarket.clear()` | Creates+closes `WholesaleSaleActivity` per match | Producer + Merchant FinancialBook |
| `RetailMarket.clear()` | Creates+closes `RetailPurchaseActivity` per match | Merchant + Buyer FinancialBook |
| `LaborMarket.clear()` | Creates `LaborContractActivity` per match (long-running) | None at creation; downstream activities write |
| `WindowBus.fire_weekly_books_close()` + A3 signal | **Deleted** | Coordination is structural now |
| `accounts.weekly_costs` / `weekly_outputs` | **Deleted** | Replaced by FinancialBook period queries |
| `accounts.skills: Dictionary` | **Deleted** | Replaced by SkillsBook |
| `Payable` resource | **Deleted** | Replaced by `Payable:{counterparty}` accounts |
| `accounts.coin`, `accounts.inventory`, `accounts.payables`, `accounts.receivables` | **Deleted** | All in FinancialBook |

### 7.2 Burst orchestrator — activity initiator, not signal emitter

```gdscript
# WindowOrchestrator
func fire_weekly_burst() -> void:
    var burst := WeeklyBurstActivity.new()
    burst.begin(SimClock.current_tick)

    # Step 1 — wage settlement (every employer pays its outstanding payables)
    for actor in region.all_actors():
        var ei := actor.find_interest(EmployerInterest)
        if ei == null: continue
        for worker_path in ei.get_payable_workers():
            var wage_act := WagePaymentActivity.new()
            wage_act.participants = [actor.get_path(), worker_path]
            burst.child_activities.append(wage_act)
            wage_act.begin(SimClock.current_tick)
            wage_act.close(SimClock.current_tick)

    # Step 2 — wholesale market (pulls supply via respond_to_supply_call)
    wholesale_market.open_market(SimClock.current_tick)
    wholesale_market.clear_market(SimClock.current_tick)

    # Step 3 — retail market
    retail_market.open_market(SimClock.current_tick)
    retail_market.clear_market(SimClock.current_tick)

    # Step 4 — labor market
    labor_market.open_market(SimClock.current_tick)
    labor_market.clear_market(SimClock.current_tick)

    burst.close(SimClock.current_tick)
```

**Coordination is structural now**, not signal-ordering. The market's `open_market()` queries the FinancialBook, which was written by Step 1 wage settlement. Order is enforced by call sequence in `fire_weekly_burst()`, not by `weekly_books_close` signal emit order. Reorder anything within the burst and the books still reconcile (because cost basis is a query, not a snapshot).

**The signal bus is not deleted.** `WindowBus` still carries broadcast signals for events with multiple unrelated listeners (work window open/close for daily slots). What's deleted is using bus signals for *coordination ordering* — that role is now structural.

### 7.3 Daily orchestrator — work activities

The daily slot cadence creates and closes `WorkSlotActivity` instances throughout the day; closes the `WorkDayActivity` at end of day. Concrete shape (sketch — implementation may refine):

```gdscript
# Daily orchestrator (per worker with an active LaborContract)
func fire_daily_work(worker: Actor) -> void:
    var contract := worker.find_active_contract()
    if contract == null: return

    var day_activity := WorkDayActivity.new()
    day_activity.participants = [worker.get_path(), contract.employer_path]
    day_activity.begin(SimClock.current_tick)

    for slot_idx in range(WorkSlotActivity.SLOTS_PER_DAY):
        var slot := WorkSlotActivity.new()
        slot.participants = [worker.get_path()]
        slot.parent_activity_ref = day_activity.get_path()
        day_activity.child_activities.append(slot)
        slot.begin(SimClock.current_tick)
        # ... time elapses; slot close happens at slot boundary
        slot.close(SimClock.current_tick)

    day_activity.close(SimClock.current_tick)
```

The day-activity persists; slot instances are discarded after the day-activity reads their accumulated deltas.

---

## 8. Phase 2 Acceptance Criteria — Reproduction

The five Phase 2 acceptance criteria must hold numerically under the rebuild. The math directive's formulas are unchanged; only the recording mechanism changes.

| AC | Test | Reproduction path |
|---|---|---|
| **AC #1** | Both workers have ACTIVE LaborContracts after Week 1 burst | `LaborMarket.clear_market()` creates `LaborContractActivity` per match; `on_close()` writes contract to `actor.accounts.contracts`. Identical outcome. |
| **AC #2** | Contracts appear on both parties' accounts | `LaborContractActivity.on_close()` writes to both participant `accounts.contracts`. Identical. |
| **AC #3** | Trace numbers — LandOwner 200 coin, workers 28 each, merchant ~44 | `WagePaymentActivity.on_close()` transfers coin via balanced FinancialBook transactions. `book.balance("Cash")` = the actor's coin. Math is identical; only recording changes. |
| **AC #4** | WholesaleMarket clears at price 1.00, supply=56 | `WholesaleSaleActivity` per match. Clearing price formula unchanged. Print line emitted at `clear_market()`. |
| **AC #5** | RetailMarket clears at P_m≈1.10, all actors receive grain | `RetailPurchaseActivity` per buyer. Math unchanged. |

Acceptance criteria test math outcomes, not implementation internals. All five hold.

---

## 9. Save / Load and Pruning Policy

### 9.1 What gets serialized (v0)

- Per-actor books (FinancialBook, SkillsBook, VitalsBook) — Resources with journal arrays of JournalEntry Resources.
- Persistent activities (in-flight and closed) — Resources, with full hierarchical structure.
- `Accounts.contracts` and `Accounts.owned_resources`.

Transient activities (`WorkSlotActivity`) are **never serialized** — by design, they have no persistent state.

### 9.2 Save-file growth

Books grow with population × playtime × entries-per-period. Activity trees grow similarly. Author has accepted this tradeoff (brief preamble). v0 makes no pruning effort — the prototype trace is 14 days, single-region, low actor count.

### 9.3 Pruning policy (phase 3+, deferred but priority-ordered)

**D2 adjudication: when pruning becomes necessary, prune in this priority order:**

1. **FinancialBook entries** are pruned first — compress to period-checkpoint summaries that preserve account balances without raw entry detail. Old wage-tx entries roll up into "Q3 wages: 156 total."
2. **VitalsBook and SkillsBook entries** are pruned later — these are observational records the player or AI may want at finer granularity.
3. **Activity histories** prune last — they are the causal-chain substrate that makes tail-event reconstruction possible. A player asking "why did Harwick fall six weeks ago?" needs the activity tree intact.

This order is fixed (Samus's staked position #3, accepted by author). When pruning lands, the activity-tree retention horizon must always be ≥ SkillsBook retention horizon.

---

## 10. Deferred to Phase 3+ (Explicit List)

These items are deliberately not in v0. Each has a documented seam.

- **`EatGrainActivity` and the consumption system.** R2.4 — eating, hunger drift, and the Caloric Intake VitalsBook discipline are their own phase. v0 does not write to VitalsBook hunger except via `WorkDayActivity` calorie burn.
- **`ReputationBook`.** Phase 3+ social system; account slot exists in the actor's `books` dictionary as `null` placeholder.
- **Inventory spoilage.** Period-close hook; not a per-unit activity. Phase 3+.
- **Trend-shape query helpers.** `book.balance_trend()` etc.; v0 does period queries only.
- **Indexing for query performance.** v0's O(n) journal walks are fine for the 14-day trace; phase 3+ adds per-account running-balance caches.
- **Cross-actor population queries.** v0.5 — see Section 5.2 above. v0 does NOT implement `Population.balance_avg()` etc., but v0 architecture must expose populations as enumerable (Section 5.2's "actors must be discoverable as a population" constraint).
- **Player-knowledge graph for counterparty mystery.** v0 architecture preserves the seam (counterparty identifiers are opaque); the resolution layer is its own future system.
- **Display-name / vocabulary surfacing.** `Activity.display_name` field exists; UI layer that consumes it is post-v0.
- **Pruning policy implementation.** Order is fixed (Section 9.3); implementation deferred.
- **Save/load test coverage at scale.** v0 ships save/load that works on the trace; resilience under multi-year sims is phase 3+.

---

## 11. Coding-Pass Authorization

This directive authorizes a **clean coding pass that replaces** the Phase 2 implementation. The implementation plan must:

1. **Delete** the Phase 2 A2/A3/A4 architectural pieces:
   - `accounts.weekly_costs`, `accounts.weekly_outputs`, `accounts.skills`, `accounts.coin`, `accounts.inventory`, `accounts.payables`, `accounts.receivables`.
   - `Payable` resource.
   - `ProductionInterest.settle_weekly_production()` method.
   - `WindowBus.fire_weekly_books_close()` signal and its emit-site.
   - `ProductionInterest`'s cached `weekly_cost_basis` field.

2. **Implement** the new primitives:
   - `Book` base class + `FinancialBook` (with strict double-entry) + `SkillsBook` + `VitalsBook` + `JournalEntry` Resource.
   - `Activity` base class + the persistent-vs-transient discipline.
   - Concrete activity classes per Section 4.1.
   - `Population` interface stubs for the Section 5.2 v0.5 seam (employment / place-of-work as enumerable).

3. **Migrate** the burst orchestrator and daily orchestrator per Section 7.

4. **Reproduce** all 5 Phase 2 acceptance criteria numerically (Section 8) on the same 14-day trace.

5. **Preserve** the gameplay seams in Sections 5.2 (population queries), 5.3 (counterparty mystery), and 6 (book access gates) — v0 does not implement these but must not preclude them.

When the coding pass passes its acceptance criteria, the rebuild is complete and Phase 2.5 is shipped. Subsequent gameplay phases (eating/consumption, ReputationBook, population queries, etc.) build on this foundation.

— Cloud Dragonborn (Game Architect), Samus Shepard (Game Designer), Author adjudication
