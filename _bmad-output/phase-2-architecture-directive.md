---
name: Phase 2 Architecture Directive
status: directive
date: 2026-05-02
inputs:
  - _bmad-output/phase-1-observations.md
  - _bmad-output/prototype-build-spec.md
  - tkyds-game/scripts/ (Phase 1 implementation)
  - party-mode rounds 1 & 2 (Cloud Dragonborn, Link Freeman, Indie, Samus Shepard)
purpose: Concrete architectural refactor steps to land before Phase 2 math/clearing. This directive is scoped to architecture only — math, clearing logic, and the five v0 acceptance criteria belong to the session after this one.
supersedes_for_phase_2_scope:
  - "_bmad-output/prototype-build-spec.md (Phase 2 section, the class-shapes parts)"
---

# Phase 2 Architecture Directive

## How to read this

Five questions were put to party-mode in `phase-1-observations.md`. The room reached agreement on all five after two rounds, then a third focused round refined Q2 and Q4 around a persistence-vs-transience principle the author surfaced post-synthesis. **Positions taken** below summarizes the decisions and the load-bearing reasoning. **Architectural principle** captures the rule that arbitrates state placement. **Refactor steps** is the change list a coding agent can execute.

The Phase 1 spec (`prototype-build-spec.md`) is mostly preserved; this directive amends specific class shapes. Where they conflict, this directive wins for the Phase 2 coding pass.

---

## Architectural principle: persistence vs transience

This rule arbitrates "what state lives where" across all Interests and Actors:

> **Anything that survives Interest removal lives on `accounts`. Anything purely behavioral lives on the Interest. Side effects of removal are written to `accounts` by the Interest's own cleanup logic before it disconnects.**

In practice:

- `Accounts` is the persistent ledger of an Actor: coin, inventory, owned_resources, contracts, payables, receivables. It survives every Interest add/remove.
- An Interest is a transient behavior — code that reacts to bus signals and mutates the ledger. State that has no meaning without the Interest (e.g., "am I currently working") lives on the Interest and evaporates with it.
- When an Interest is removed mid-flight, its `disconnect_from_bus()` is responsible for leaving the ledger in a consistent state (e.g., marking a still-ACTIVE contract as BREACHED). The Interest settles its tab before exiting.

For v0, Interest removal is not a feature — `Actor._exit_tree()` calls `disconnect_from_bus()` only on shutdown. But the principle informs which fields are derived and which are stored, which is what determines the class shapes Phase 2 commits to. The cleanup-on-removal clause is documentation for now; it becomes load-bearing in Phase 3+ when runtime identity swap is real.

**One discipline note (Cloud):** multi-Interest dependencies are the place this rule can mislead. If Interest A reads a value Interest B is responsible for writing, removing B mid-tick can produce stale reads. Tick ordering has to honor the principle — accounts must be settled before derived reads happen. Flag in design notes any time two Interests touch the same ledger entries within one tick.

---

## Positions taken

### Q1 — Actor identity is composition. Flatten the subclasses.

**Decision.** One `Actor` class. Delete `Worker`, `LandOwner`, `Merchant` subclass files. An actor's role is whatever bundle of Interests + owned Resources it currently holds.

**Reasoning.** Indie's framing was the strongest case for v0 specifically: `_wire_signals()` is the only thing the subclasses override that does load-bearing work. Once wiring moves to Interests (Q3), the subclasses become empty shells. Shipping empty shells is the YAGNI violation, not deleting them. Samus's identity-fluidity argument (the detective fantasy needs emergent role-changes) and Cloud's multiple-inheritance-trap argument both reinforce the call but the v0 forcing function is the empty-shell problem.

**Subclass-specific state migrates to its Interest.** `Worker.work_state` and `Worker.active_contract` move to `WorkingInterest`. `LandOwner.production_interest` typed slot is gone — it's just one entry in `interests`. Merchant has no specific state beyond its Interest. The `LandPlot` reference is already on `ProductionInterest` and stays there.

### Q2 — Split `ProductionInterest`. `EmployerInterest` exists.

**Decision.** Unanimous in the room.

| Today | After |
|---|---|
| `ProductionInterest` (plot, output, post_jobs, send_grain_to_wholesale, desired_workers) | `ProductionInterest` (plot, output, send_grain_to_wholesale, wholesale_market) |
| `LandOwner.pay_outstanding_wages()` | `EmployerInterest.pay_outstanding_wages()` |
| `ProductionInterest.post_jobs()` | `EmployerInterest.post_open_jobs()` (with the Q4 fix) |
| (no concept) | `EmployerInterest` (desired_workers, labor_market, post_open_jobs, pay_outstanding_wages) |

**Composition.** A large landowner holds `ProductionInterest + EmployerInterest`. A self-employed smallholder holds `ProductionInterest` only. A merchant who hires shop hands holds `EmployerInterest + MercantileInterest` without `ProductionInterest`. Each combination is a clean valid state.

**Resource-shaped vs Market-shaped is a naming heuristic, not a type hierarchy.** Don't add `ResourceInterest` / `MarketInterest` abstract base classes. Use the framing when picking names for new Interests; don't bake it into inheritance.

**Refinement after author's persistence-vs-transience principle (round 3).** `WorkingInterest` does NOT hold an `active_contract` field. The contract lives in `accounts.contracts` (it's already written there by `LaborMarket.clear()` per the build-spec). Any callsite that needs the worker's current contract uses a derived lookup: `working_interest.current_contract()`, which filters `owner.accounts.contracts`. Same principle applies to `EmployerInterest` — it does not cache filled positions; `filled_positions()` is a derived filter over the same ledger. `work_state` stays on `WorkingInterest` because it's purely behavioral — no Interest, no work state, by definition. See "Architectural principle" above for the full rule.

### Q3 — Interest owns the wiring. `connect_to_bus()` / `disconnect_from_bus()`.

**Decision.** Each `Interest` subclass implements two methods:

- `connect_to_bus() -> void` — connects whatever signals it cares about, on whichever autoload(s), to its own named methods.
- `disconnect_from_bus() -> void` — mirror.

No argument. The Interest imports `WindowBus` and `SimClock` directly (both are autoloads, single-instance, no benefit from injection).

The Actor calls `interest.connect_to_bus()` for every interest in its bundle at `_ready()` (or at `add_interest()` for runtime additions), and `interest.disconnect_from_bus()` at `_exit_tree()` (or `remove_interest()`).

**Reasoning.** Cloud's case held after both rounds: `signal_subscriptions()` returning a list of pairs makes the Actor a manifest-reader and reintroduces the indirection the composition refactor was supposed to eliminate. Two named methods on the Interest keep all wiring knowledge inside the Interest's file. Link conceded that Godot's RefCounted signal cleanup handles most lifetime concerns automatically, and explicit `disconnect_from_bus()` covers the remaining edge case where something else still holds the Resource after the Actor frees.

**Naming.** `connect_to_bus()` / `disconnect_from_bus()` is the recommended pair. Cloud's first cut was `hook_up(bus)` / `unhook(bus)`. If you prefer `start_listening()` / `stop_listening()` or `hook_up()` / `unhook()`, swap the verbs — the mechanics don't change. (Confirm-before-code item #1.)

### Q4 — `filled_positions` derived from contract list on `EmployerInterest`.

**Decision.** `EmployerInterest.post_open_jobs()` posts `desired_workers - filled_positions(employer)`, where `filled_positions(employer)` walks `employer.accounts.contracts` and counts entries that are `LaborContract` with `status == ACTIVE` and `employer == owner.get_path()`.

```gdscript
func filled_positions(employer: Actor) -> int:
    var count := 0
    for c in employer.accounts.contracts:
        if c is LaborContract and c.status == Contract.Status.ACTIVE and c.employer == employer.get_path():
            count += 1
    return count
```

No new signal, no separate registry. Reading from `accounts.contracts` keeps a single source of truth.

**Why not Link's reactive counter.** Link's "EmployerInterest subscribes to a `job_filled` signal and increments a counter" works but introduces a new bus signal and a piece of derived state that can drift out of sync if a contract gets `BREACHED` outside the normal flow. Reading from the list is O(n) where n is "contracts the employer has" (small), and the truth lives in one place. If reconciliation becomes a hot-path problem in Phase 3+, the reactive counter is the upgrade path.

### Q5 — Rename Market verbs and add a print prefix.

**Decision.** Both renames AND prefix tags. The misleading verbs are the root cause; the tags make the day-vs-week distinction scannable in 728-line traces.

- `Market.take_supply` → `Market.queue_supply`
- `Market.take_demand` → `Market.queue_demand`
- Each `queue_*` print line gets a `[QUEUE]` prefix
- Each `clear()` print line gets a `[CLEAR]` prefix

Indie's "punt" loses to "the cost is two find-replaces." Doing it now is cheaper than doing it later when the misleading verbs have spread to math callsites.

---

## Concrete refactor steps

Land in this order. Step 1 unblocks Step 3 (subclass deletion needs `pay_outstanding_wages` already moved). Steps 4 and 5 are independent and can land anywhere.

### Step 1 — Split `ProductionInterest` into `ProductionInterest` + `EmployerInterest`

**New file: `tkyds-game/scripts/interests/employer_interest.gd`**

```gdscript
class_name EmployerInterest
extends Interest

var labor_market: LaborMarket
@export var desired_workers: int = 2

func connect_to_bus() -> void:
    WindowBus.labor_market_opened.connect(post_open_jobs)
    WindowBus.wages_due.connect(pay_outstanding_wages)

func disconnect_from_bus() -> void:
    WindowBus.labor_market_opened.disconnect(post_open_jobs)
    WindowBus.wages_due.disconnect(pay_outstanding_wages)

func post_open_jobs() -> void:
    var open := desired_workers - filled_positions()
    print("    %s.EmployerInterest.post_open_jobs() — desired=%d filled=%d open=%d" % [owner.actor_id, desired_workers, filled_positions(), open])
    if open <= 0 or labor_market == null:
        return
    labor_market.queue_demand(owner, open)

func pay_outstanding_wages() -> void:
    var n := owner.accounts.payables.size() if owner.accounts != null else 0
    print("    %s.EmployerInterest.pay_outstanding_wages() — walk %d payable(s); decrement coin; pay each worker; clear payables" % [owner.actor_id, n])
    # Math lands in the next session. Print-only for now.

func filled_positions() -> int:
    if owner == null or owner.accounts == null:
        return 0
    var count := 0
    for c in owner.accounts.contracts:
        if c is LaborContract and c.status == Contract.Status.ACTIVE and c.employer == owner.get_path():
            count += 1
    return count
```

**Edit `tkyds-game/scripts/interests/production_interest.gd`** — remove employer concerns:

```gdscript
class_name ProductionInterest
extends Interest

@export var plot: LandPlot
var wholesale_market: WholesaleMarket

func connect_to_bus() -> void:
    WindowBus.work_window_closed.connect(send_grain_to_wholesale)

func disconnect_from_bus() -> void:
    WindowBus.work_window_closed.disconnect(send_grain_to_wholesale)

func send_grain_to_wholesale() -> void:
    print("    %s.ProductionInterest.send_grain_to_wholesale() — emit grain supply" % owner.actor_id)
    if wholesale_market != null:
        wholesale_market.queue_supply(owner, 0)
```

**Removed from `ProductionInterest`:** `labor_market`, `desired_workers`, `post_jobs()`. (All migrate to `EmployerInterest`.)

### Step 2 — Add `connect_to_bus()` / `disconnect_from_bus()` to all remaining Interests

**`tkyds-game/scripts/interests/interest.gd`** — base no-op + owner field:

```gdscript
class_name Interest
extends Resource

var owner: Actor

func connect_to_bus() -> void:
    pass

func disconnect_from_bus() -> void:
    pass
```

**`working_interest.gd`** — absorbs `work_state` from `Worker`. **Does NOT take `active_contract`**; the contract lives in `accounts.contracts` and is looked up via `current_contract()`:

```gdscript
class_name WorkingInterest
extends Interest

@export var work_state: SimEnums.WorkState = SimEnums.WorkState.IDLE
var labor_market: LaborMarket

func connect_to_bus() -> void:
    WindowBus.labor_market_opened.connect(look_for_work)
    WindowBus.work_window_opened.connect(begin_working)
    WindowBus.work_window_closed.connect(deliver_grain_and_bill)
    SimClock.daily_tick.connect(do_one_work_slot)

func disconnect_from_bus() -> void:
    WindowBus.labor_market_opened.disconnect(look_for_work)
    WindowBus.work_window_opened.disconnect(begin_working)
    WindowBus.work_window_closed.disconnect(deliver_grain_and_bill)
    SimClock.daily_tick.disconnect(do_one_work_slot)
    # Phase 3+ cleanup clause (documented now, not implemented at v0):
    # if there is a still-ACTIVE contract for this worker, mark it BREACHED here.

func current_contract() -> LaborContract:
    if owner == null or owner.accounts == null:
        return null
    for c in owner.accounts.contracts:
        if c is LaborContract and c.worker == owner.get_path() and c.status == Contract.Status.ACTIVE:
            return c
    return null

func look_for_work() -> void:
    if work_state != SimEnums.WorkState.IDLE: return
    print("    %s.WorkingInterest.look_for_work() — offering self to LaborMarket" % owner.actor_id)
    if labor_market != null:
        labor_market.queue_supply(owner, 1)

func begin_working() -> void:
    if current_contract() != null:
        work_state = SimEnums.WorkState.WORKING
        print("    %s.work_state → WORKING" % owner.actor_id)

func do_one_work_slot(slot: int) -> void:
    # Filter internally — only do work during a work-window slot AND when WORKING.
    if work_state != SimEnums.WorkState.WORKING: return
    if slot < SimEnums.TimeSlot.MID_MORNING or slot > SimEnums.TimeSlot.LATE_AFTERNOON: return
    print("    %s.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory" % owner.actor_id)

func deliver_grain_and_bill() -> void:
    if current_contract() == null: return
    print("    %s.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)" % owner.actor_id)
    work_state = SimEnums.WorkState.EMPLOYED_NOT_WORKING
    print("    %s.work_state → EMPLOYED_NOT_WORKING" % owner.actor_id)
```

**`LaborMarket.clear()` change (existing file).** Today the market sets `worker.active_contract = contract`. After this directive, **delete that line.** The contract is still appended to both `worker.accounts.contracts` and `employer.accounts.contracts` (which is the existing behavior); nothing else changes about the market. WorkingInterest finds the contract via `current_contract()` lookup.

**v0 scope note:** `accounts.contracts` is treated as **current-only** at v0 — no historical/terminated entries. The 14-day prototype only ever creates contracts (never breaches them), so the filter is trivially fast. Historical contract retention is a Phase 3+ design problem.

**`grain_interest.gd`** — connects to SimClock directly:

```gdscript
class_name GrainInterest
extends Interest

var retail_market: RetailMarket
@export var daily_demand: int = 2
var outstanding_demand: int = 0

func connect_to_bus() -> void:
    SimClock.daily_tick.connect(_consider_placing_order)

func disconnect_from_bus() -> void:
    SimClock.daily_tick.disconnect(_consider_placing_order)

func _consider_placing_order(slot: int) -> void:
    if slot != SimEnums.TimeSlot.LATE_EVENING: return
    place_grain_order()

func place_grain_order() -> void:
    outstanding_demand += daily_demand
    print("    %s.GrainInterest.place_grain_order() — +%d grain demand (outstanding=%d)" % [owner.actor_id, daily_demand, outstanding_demand])
    if retail_market != null:
        retail_market.queue_demand(owner, daily_demand)

func record_receipt(qty: int) -> void:
    outstanding_demand = max(0, outstanding_demand - qty)
    print("    GrainInterest.record_receipt(%d) — outstanding_demand now %d" % [qty, outstanding_demand])
```

(The leading-underscore on `_consider_placing_order` here is just "private slot-filter helper"; if even that reads as Godot-conventional jargon to the author, rename to `place_grain_order_at_late_evening` or similar. Not load-bearing.)

**`mercantile_interest.gd`**:

```gdscript
class_name MercantileInterest
extends Interest

var wholesale_market: WholesaleMarket
var retail_market: RetailMarket
@export var good_id: StringName = &"grain"
@export var target_inventory: int = 60

func connect_to_bus() -> void:
    WindowBus.merchant_restock.connect(place_buy_order_at_wholesale)
    WindowBus.wholesale_market_closed.connect(send_inventory_to_retail)

func disconnect_from_bus() -> void:
    WindowBus.merchant_restock.disconnect(place_buy_order_at_wholesale)
    WindowBus.wholesale_market_closed.disconnect(send_inventory_to_retail)

func place_buy_order_at_wholesale() -> void:
    var deficit := target_inventory
    print("    %s.MercantileInterest.place_buy_order_at_wholesale() — emit demand for %d %s" % [owner.actor_id, deficit, good_id])
    if wholesale_market != null:
        wholesale_market.queue_demand(owner, deficit)

func send_inventory_to_retail() -> void:
    print("    %s.MercantileInterest.send_inventory_to_retail() — emit %s supply to RetailMarket" % [owner.actor_id, good_id])
    if retail_market != null:
        retail_market.queue_supply(owner, 0)
```

### Step 3 — Flatten `Actor`, delete the subclass files

**Edit `tkyds-game/scripts/actors/actor.gd`:**

```gdscript
class_name Actor
extends Node

@export var actor_id: StringName = &""
@export var accounts: Accounts
@export var interests: Array[Interest] = []

func _ready() -> void:
    for interest in interests:
        interest.owner = self
        interest.connect_to_bus()
        print("[Wire] %s attached %s" % [actor_id, interest.get_class()])

func _exit_tree() -> void:
    for interest in interests:
        interest.disconnect_from_bus()
        interest.owner = null

func add_interest(interest: Interest) -> void:
    interests.append(interest)
    interest.owner = self
    interest.connect_to_bus()

func remove_interest(interest: Interest) -> void:
    interest.disconnect_from_bus()
    interest.owner = null
    interests.erase(interest)

func find_interest(type: Variant) -> Interest:
    for i in interests:
        if is_instance_of(i, type):
            return i
    return null
```

**Delete:**
- `tkyds-game/scripts/actors/worker.gd`
- `tkyds-game/scripts/actors/land_owner.gd`
- `tkyds-game/scripts/actors/merchant.gd`

(The typed-Interest fields `grain_interest`, `working_interest`, `production_interest`, `mercantile_interest` go away with them. Lookup is via `interests` array; if a callsite needs typed access, it uses `actor.find_interest(WorkingInterest)`.)

### Step 4 — Update bootstrap

**Edit `tkyds-game/scripts/bootstrap/prototype_bootstrap.gd`:**

Replace `Worker.new()` / `LandOwner.new()` / `Merchant.new()` with `Actor.new()` everywhere. Build the Interest bundle for each actor and assign to `interests` BEFORE adding the Actor to the scene tree (so `_ready()` finds the interests already populated).

```gdscript
func _make_worker(id, labor_market, retail_market) -> Actor:
    var w := Actor.new()
    w.name = String(id)
    w.actor_id = id
    w.accounts = Accounts.new()
    var working := WorkingInterest.new()
    working.labor_market = labor_market
    var grain := GrainInterest.new()
    grain.retail_market = retail_market
    w.interests = [working, grain]
    return w

func _make_land_owner(id, plot, labor_market, wholesale_market, retail_market) -> Actor:
    var lo := Actor.new()
    lo.name = String(id)
    lo.actor_id = id
    lo.accounts = Accounts.new()
    lo.accounts.coin = 200
    lo.accounts.owned_resources = [plot]
    var production := ProductionInterest.new()
    production.plot = plot
    production.wholesale_market = wholesale_market
    var employer := EmployerInterest.new()
    employer.labor_market = labor_market
    employer.desired_workers = 2
    var grain := GrainInterest.new()
    grain.retail_market = retail_market
    lo.interests = [production, employer, grain]
    return lo

func _make_merchant(id, wholesale_market, retail_market) -> Actor:
    var m := Actor.new()
    m.name = String(id)
    m.actor_id = id
    m.accounts = Accounts.new()
    m.accounts.coin = 100
    var mercantile := MercantileInterest.new()
    mercantile.wholesale_market = wholesale_market
    mercantile.retail_market = retail_market
    var grain := GrainInterest.new()
    grain.retail_market = retail_market
    m.interests = [mercantile, grain]
    return m
```

Note the new bundle for the land owner: `[ProductionInterest, EmployerInterest, GrainInterest]`. Three Interests instead of two.

### Step 5 — Rename Market verbs, add print prefixes

**Edit `tkyds-game/scripts/markets/market.gd`:**

```gdscript
func queue_supply(actor: Actor, qty: int) -> void:
    supply_pool[actor.get_path()] = supply_pool.get(actor.get_path(), 0) + qty
    print("[QUEUE]    %s.queue_supply(%s, %d)" % [name, actor.actor_id, qty])

func queue_demand(actor: Actor, qty: int) -> void:
    demand_pool[actor.get_path()] = demand_pool.get(actor.get_path(), 0) + qty
    print("[QUEUE]    %s.queue_demand(%s, %d)" % [name, actor.actor_id, qty])

func clear() -> void:
    print("[CLEAR]    %s.clear() — base no-op" % name)
```

**Edit `labor_market.gd`, `wholesale_market.gd`, `retail_market.gd`** — prefix each `clear()` print with `[CLEAR]`. Update all callsites that called `take_supply` / `take_demand` to use the new names. (Step 1 and Step 2 already use the new names in the snippets above.)

### Verification after all steps

Re-run the 14-day prototype. Acceptance for this directive (architecture, not math):

1. Console output still shows daily and weekly flows in correct order (the same ~728 lines of trace, give or take wording changes from the renames).
2. `[QUEUE]` and `[CLEAR]` tags appear on the right lines — daily emissions tagged `[QUEUE]`, weekly clearings tagged `[CLEAR]`.
3. The land owner's `EmployerInterest.post_open_jobs()` shows `open=2` on day 1 (no contracts yet), `open=0` on day 2+ (both contracts active). This is the Q4 fix becoming visible.
4. No `Worker`/`LandOwner`/`Merchant` class names remain anywhere in `scripts/`.
5. No errors, no warnings.

If those five hold, architecture is in place and the next session can drop math into the Interest method bodies.

---

## Confirm before code moves

Six items the author should sign off before a coding agent starts.

1. **Verb naming for `connect_to_bus()` / `disconnect_from_bus()`.** Directive picks this pair. Cloud and Link both accepted the underlying mechanics; if you prefer `hook_up()` / `unhook()` (Cloud's first cut) or `start_listening()` / `stop_listening()` (more plain-English), swap and proceed. The mechanics are identical; only the names differ.

2. **`work_state` migrates from `Worker` to `WorkingInterest`. `active_contract` is deleted entirely.** Resolved in round 3 against the persistence-vs-transience principle. `work_state` is purely behavioral and lives on the Interest. `active_contract` was redundant with `accounts.contracts` (where the contract is already written by `LaborMarket.clear()`); it's replaced by a derived `current_contract()` lookup on `WorkingInterest`. See "Architectural principle" section.

3. **`Interest.owner` field.** Directive adds `var owner: Actor` to base `Interest` and sets it in `Actor._ready()` / `add_interest()` so Interests can read `owner.accounts`, `owner.actor_id`, etc. without method parameters threading through. Save/load (when it lands later) will need to handle this — probably as a `NodePath` that resolves on load. Note for v0; not a blocker.

4. **`accounts.contracts` is single source of truth for `filled_positions`.** Directive has `EmployerInterest.filled_positions()` filter `owner.accounts.contracts`. Alternative: `EmployerInterest` keeps its own contract list separate from `Accounts`. Single source is simpler; confirm before Step 1.

5. **Resource-shaped vs Market-shaped is documentation, not types.** Directive treats the pattern as a naming heuristic only — no `ResourceInterest` / `MarketInterest` abstract base classes. If you wanted the pattern as actual type structure, say so before Step 1 and the directive will need to expand.

6. **Samus's "weight on identity swap" concern is parked.** Samus argued runtime identity swaps need cost (time/capital/social friction), or the world drifts to "everyone is everything." The flat-Actor architecture *enables* swaps but doesn't *cost* anything for them. That's a Phase 3+ concern; flagging here so it doesn't get lost. No action needed in Phase 2.

---

## Out of scope for this directive

Belongs to the next session, after the architecture above lands:

- LaborMarket / WholesaleMarket / RetailMarket clearing math (real transfers of grain and coin)
- WageCalculator beyond the flat-1 placeholder
- The five v0 acceptance criteria from `prototype-build-spec.md` becoming testable end-to-end
- Save/load, resource serialization for `Interest.owner`
- Multi-region, multi-good, multi-plot generalization
- Aptitudes, needs, morale, lord AI, anything from `prototype-build-spec.md` Phase 3 list

---

## Provenance

This directive is the synthesis of party-mode. Two rounds of multi-agent discussion. Round 1: each agent took independent positions on all 5 questions. Round 2: Cloud and Link cross-examined on Q3; Indie was given a clean shot at defending or yielding on Q1. All three converged on the positions above. Samus did not participate in round 2 (her round 1 contribution was world-design framing, which feeds Q1 reasoning but didn't need a follow-up).

Anywhere this directive's recommendation feels wrong, it can be overruled — the agents' reasoning is in the round-1 and round-2 transcripts (in the original conversation) and the disagreements were real, not papered over.
