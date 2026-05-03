---
name: Phase 2 Math Directive
status: directive (complete — Section 1 wages+wholesale + Section 2 retail)
date_section_1: 2026-05-02
date_section_2: 2026-05-03
sections:
  - 1 of 2 — Wages + Wholesale (shipped 2026-05-02)
  - 2 of 2 — Retail (shipped 2026-05-03)
inputs:
  - _bmad-output/phase-2-math-observations.md
  - _bmad-output/phase-2-math-brief-wages-wholesale.md
  - _bmad-output/phase-2-math-brief-retail.md
  - _bmad-output/phase-2-math-mary-economic-vetting.md
  - _bmad-output/phase-2-math-cloud-retail.md
  - _bmad-output/phase-2-math-samus-retail.md
  - _bmad-output/phase-2-architecture-directive.md
  - tkyds-game/scripts/ (post-refactor code)
  - party-mode round 1 (Cloud Dragonborn, Samus Shepard) — wages + wholesale
  - panel round 2 (Mary economic vetting → Cloud + Samus reaction) — retail
  - author elicitation + adjudication passes (Zach + Claude orchestrator)
purpose: |
  Concrete math/clearing decisions for the entire Phase 2 economy, ready to be
  implemented in the next coding pass. Section 1 covers wages + wholesale; Section 2
  covers retail (clearing, pricing, affordability, decay). Both sections lock seams
  and v0 calibration values; phase 3+ work plugs into the named seams without
  rebuilding the math layer.
supersedes:
  - "_bmad-output/prototype-build-spec.md (Phase 2 stub-math sections — both wages/wholesale and retail)"
  - "_bmad-output/phase-2-architecture-directive.md (weekly burst timing — see Section 1 Spec Amendments)"
---

# Phase 2 Math Directive — Section 1: Wages & Wholesale

## How to read this

Author ran an elicitation pass with Claude on `phase-2-math-observations.md`'s 10 open questions and locked roughly half through direct conversation. The remaining open questions went to a focused 2-person panel (Cloud + Samus). Both papers landed; three real disagreements were adjudicated by the author. **Positions** below summarizes what's locked. **Refactor steps** is the change list a coding agent can execute. **Trace expectations** is the testable acceptance check.

This section retires the math gaps in *wages* and *wholesale* only. Retail is handled in Section 2 (separate session). Where this directive conflicts with prior docs, this directive wins for wages + wholesale scope.

---

## Spec amendments

These change prior commitments. Read carefully.

### Weekly burst moves to **day 1 EARLY_MORNING** (was day 7 EARLY_MORNING)

The build-spec and architecture directive had the weekly burst firing at **day 7 EARLY_MORNING**. This directive moves it to **day 1 EARLY_MORNING**. Effect: each week begins with all settlements and clearings; days 1–7 then run their daily work cycle.

**New burst order (day 1 EARLY_MORNING):**

```
1. wages_due           — settle last week's payables (uses CURRENT rate at settlement)
2. merchant_restock    — merchants queue wholesale demand (target_inventory − leftover)
3. wholesale clear     — proportional fill, transfer grain + coin
4. send_inventory_to_retail — merchants queue retail supply (full inventory)
5. retail clear        — DEFERRED to Section 2; print-only at v0 first-pass
6. labor_market_opened — employers post, workers offer
7. labor_market clear  — draft matching, write new contracts
```

Steps 6 and 7 may be one logical phase (the bus signal `labor_market_opened` triggers `EmployerInterest.post_open_jobs` and `WorkingInterest.look_for_work`; then `LaborMarket.clear()` runs the draft).

### Labor market becomes **weekly**, not daily

Build-spec had `labor_market_opened` firing daily at LATE_EVENING. After this directive, `labor_market_opened` fires **once a week**, inside the day-1 burst (step 6 above). Workers find jobs once per week. Employers post once per week. The daily LMW signal is removed from `WindowOrchestrator`'s daily emit cycle.

### Q1 (day-1 startup): **accept the lag**

Week 1's day-1 burst is mostly empty. No payables to settle, no producer grain, no merchant inventory, no consumer pools. Each step prints "nothing to clear yet" via guard clauses and moves on. Then days 1–7 produce. By week 2's day-1 burst, all four flows have something to do.

This means the build-spec's **acceptance criterion #3** is wrong as written. Updated numbers below (Trace expectations).

### Q4 (settlement order): resolved by burst order

The new order has `wages_due` first, retail clear later. Workers receive last week's pay BEFORE retail clears, so from week 2 onward they shop with last week's wages. The Q4 question "wages_due before or after retail clear" gets answered by step ordering.

---

## Positions taken

### Wage formula (locked)

```
wage_per_slot = max(minimum_wage, skill_value × scarcity_multiplier)

skill_value = base_skill × (1 − e^(−XP/X_0))^a

scarcity_multiplier = 2 / (1 + e^(k × (supply − S_0)))
```

- `minimum_wage` is the design knob (W1 = (a) per author). Configurable per-job-category. Floor applies after skill × scarcity is computed.
- `skill_value` form is locked Form B — `a` shapes the saturation curve only; the asymptote stays at `base_skill`.
- `scarcity_multiplier` is the centered form — equilibrium (`supply == S_0`) → 1; oversupply → 0; scarcity → 2.

**Why minimum_wage floor (a) over reformulation (c).** Author chose (a) for player legibility — workers can read a "this is the bottom" number on a pay stub. Cloud preferred (c) for mathematical smoothness; Samus preferred (a) for the same legibility reason as the author. Cloud's smoothness concern is acknowledged but parked: phase 3+ employer-learning logic (which would reason about wage gradients) doesn't exist yet, and if it lands, the floor can be re-examined then.

### Wage calculator (W7 — already locked from observations)

```gdscript
# autoload (or pure-static class)
class_name WageCalculator

const MINIMUM_WAGE: float = 0.5    # configurable; v0 = 0.5
const BASE_SKILL: float = 1.0      # per-job; v0 single-job = 1.0
const X_0: float = 100.0           # XP scale; v0 calibration target — see W2
const A: float = 1.0               # learning curve shape; v0 = 1.0 (standard saturating)
const K: float = 1.0               # scarcity sensitivity; v0 = 1.0
const S_0: float = 2.0             # equilibrium supply baseline; v0 = 2 workers in region
                                    # phase 3+ derived from regional capacity (e.g., farmable land)

static func calculate_wage_per_slot(employer: Actor, worker: Actor, supply: int) -> float:
    var xp: float = worker.accounts.skills.get(&"farming", 0.0)
    var skill_factor: float = pow(1.0 - exp(-xp / X_0), A)
    var skill_value: float = BASE_SKILL * skill_factor
    var scarcity: float = 2.0 / (1.0 + exp(K * (float(supply) - S_0)))
    return max(MINIMUM_WAGE, skill_value * scarcity)
```

**v0 numerical behavior:** `skill_factor = 0` at XP=0, so `skill_value = 0`, so the wage stays floored at 0.5 throughout the 14-day prototype (workers can earn at most ~40 XP in 5 days × 8 slots, which gives `skill_factor ≈ 0.33`, still below 0.5 floor). Wage is effectively constant 0.5 coin/slot at v0. **This is correct** — calibration emerges as XP grows past the threshold; v0's role is to prove the seams.

**Wait — author's calibration target was 1 coin/slot, not 0.5.** Two ways to land that:

1. **`MINIMUM_WAGE = 1.0`.** Floor at 1 coin/slot. Worker earns 1 coin/slot until skill curve exceeds 1 (which won't happen with `BASE_SKILL = 1` — asymptote is 1). So wage is constant 1.
2. **`BASE_SKILL = 2.0`, `MINIMUM_WAGE = 1.0`.** Floor at 1, asymptote at 2. Skilled workers eventually earn 2x the floor. Phase 3+ tunable.

Recommend option (2) so there's headroom for skill-driven divergence to be visible in phase 3+ traces. **Confirm before code moves** (#1).

**Re-rate-all-weekly (W3):** `calculate_wage_per_slot` is called fresh each time it's needed — at LMW clearing time (to determine asked_wage for ranking) and at `wages_due` settlement time (to multiply against `slots_worked`). No rate is cached on the contract. Worker XP and supply count are read at each call. The Q6 Payable shape (slots-worked + rate-at-settlement) is the *same decision* as W3's re-rate-all — they are two views of one design.

### `supply` definition (W4)

`supply` in the scarcity multiplier = **count of active workers in region** (employed + seeking). Not heads-at-clearing (too jittery) nor slot-units (couples capacity into scarcity).

For v0 with single global LaborMarket and 2 workers, supply is hardcoded 2. Phase 3+ replaces the count source via the seam:

```gdscript
# LaborMarket
func supply_for_scarcity() -> int:
    # v0: hardcoded global headcount
    return 2
    # phase 3+: count active workers in this region
    # return RegionRegistry.workers_in_region(region_id)
```

### Payable shape (Q6 — already locked)

```gdscript
class_name Payable
extends Resource

@export var worker: NodePath
@export var slots_worked: int = 0    # accumulated daily by deliver_grain_and_bill
@export var contract: NodePath        # references LaborContract for rate-at-settlement lookup
```

**No `amount` field.** Coin owed is computed at `pay_outstanding_wages()` time:

```gdscript
# EmployerInterest
func pay_outstanding_wages() -> void:
    var n := owner.accounts.payables.size() if owner.accounts != null else 0
    if n == 0:
        print("    %s.EmployerInterest.pay_outstanding_wages() — nothing to settle" % owner.actor_id)
        return
    print("    %s.EmployerInterest.pay_outstanding_wages() — settling %d payable(s)" % [owner.actor_id, n])
    var supply := _global_labor_supply()  # phase 3+ regional
    for payable in owner.accounts.payables:
        var worker := get_node(payable.worker) as Actor
        var rate := WageCalculator.calculate_wage_per_slot(owner, worker, supply)
        var coin_owed := int(round(payable.slots_worked * rate))
        owner.accounts.coin -= coin_owed
        worker.accounts.coin += coin_owed
        print("    paid %s: %d slots × %.2f rate = %d coin" % [worker.actor_id, payable.slots_worked, rate, coin_owed])
    owner.accounts.payables.clear()
```

`int(round(...))` keeps the ledger in whole coins. Sub-coin precision is calibration noise.

### Daily payable accumulation

```gdscript
# WorkingInterest.deliver_grain_and_bill (replaces the print-only stub)
func deliver_grain_and_bill() -> void:
    var contract := current_contract()
    if contract == null:
        return
    var employer := get_node(contract.employer) as Actor
    var slots_today := _slots_worked_today()  # 4 in v0 (MID_MORNING + EARLY_AFTERNOON + LATE_AFTERNOON + ?)
    # transfer grain
    var grain := owner.accounts.inventory.get(&"grain", 0)
    employer.accounts.inventory[&"grain"] = employer.accounts.inventory.get(&"grain", 0) + grain
    owner.accounts.inventory[&"grain"] = 0
    # accumulate Payable
    var payable := _find_or_create_payable(employer, contract, owner)
    payable.slots_worked += slots_today
    print("    %s.WorkingInterest.deliver_grain_and_bill() — %d grain to %s; +%d slots on payable (now %d)" %
        [owner.actor_id, grain, employer.actor_id, slots_today, payable.slots_worked])
    work_state = SimEnums.WorkState.EMPLOYED_NOT_WORKING
```

`_find_or_create_payable` looks up an existing Payable for `(employer, worker, contract)` on `employer.accounts.payables` and either increments it or creates a new one. One Payable per worker-contract pair per settlement period.

### `accounts.skills` introduced empty (Q10 — already locked)

```gdscript
# Accounts (existing class, add field)
@export var skills: Dictionary = {}    # StringName → float (XP)
```

`WageCalculator` reads with default 0.0: `worker.accounts.skills.get(&"farming", 0.0)`. v0 never writes; phase 3+ XP-emit code populates.

### Labor market clearing (W5 — strategy enum, draft matching)

```gdscript
class_name LaborMarket
extends Market

enum ClearingStrategy { RANDOM, FIFO }

@export var clearing_strategy: ClearingStrategy = ClearingStrategy.RANDOM

func clear() -> void:
    var employers := demand_pool.keys()
    var workers := supply_pool.keys()
    var supply := workers.size()

    if employers.is_empty() or workers.is_empty():
        print("[CLEAR]    %s.clear() — nothing to match (employers=%d, workers=%d)" % [name, employers.size(), workers.size()])
        supply_pool.clear()
        demand_pool.clear()
        return

    # Step 1: each employer ranks candidates by expected_productivity / asked_wage
    var rankings := {}
    for employer_path in employers:
        var employer := get_node(employer_path) as Actor
        var ranked: Array = []
        for worker_path in workers:
            var worker := get_node(worker_path) as Actor
            var asked_wage := WageCalculator.calculate_wage_per_slot(employer, worker, supply)
            var expected_productivity := 1.0    # v0: uniform; phase 3+ reads worker.accounts.skills
            var ratio := expected_productivity / max(asked_wage, 0.01)
            ranked.append({"worker": worker_path, "ratio": ratio})
        ranked.sort_custom(func(a, b): return a["ratio"] > b["ratio"])
        ranked.shuffle()    # v0 random tiebreak (within employer's preference)
        rankings[employer_path] = ranked

    # Step 2: pick order via clearing_strategy
    var pick_order := employers.duplicate()
    match clearing_strategy:
        ClearingStrategy.RANDOM: pick_order.shuffle()
        ClearingStrategy.FIFO:   pass    # already in queue order
        # phase 3+: CHARISMA_PICK reads each employer's charisma; PRODUCTIVITY_RANK reads worker skills

    # Step 3: draft loop
    var unmatched := workers.duplicate()
    var positions_remaining := {}
    for employer_path in employers:
        positions_remaining[employer_path] = demand_pool[employer_path]

    while true:
        var any_picked := false
        for employer_path in pick_order:
            if positions_remaining[employer_path] <= 0:
                continue
            for entry in rankings[employer_path]:
                var worker_path = entry["worker"]
                if worker_path not in unmatched:
                    continue
                _write_contract(employer_path, worker_path)
                unmatched.erase(worker_path)
                positions_remaining[employer_path] -= 1
                any_picked = true
                break
        if not any_picked:
            break

    # Print remainders
    for employer_path in employers:
        if positions_remaining[employer_path] > 0:
            var employer := get_node(employer_path) as Actor
            print("[CLEAR]    %s left with %d open positions" % [employer.actor_id, positions_remaining[employer_path]])
    for worker_path in unmatched:
        var worker := get_node(worker_path) as Actor
        print("[CLEAR]    %s left without contract" % worker.actor_id)

    supply_pool.clear()
    demand_pool.clear()
```

**`_write_contract`** creates a `LaborContract` and appends to both parties' `accounts.contracts` (existing build-spec behavior, no change).

**WS7 (enum vs Strategy pattern):** stay enum. Both Cloud and Samus agreed. The `match` block is small even at four strategies; migrate to a Strategy object only if a future strategy needs private state.

### Wholesale price formula (locked)

```
wholesale_price_per_grain = cost_per_grain × (1 + delta)
```

Computed per producer at clearing time:

```gdscript
# ProductionInterest
@export var current_delta: float = 0.0    # v0 placeholder (final value awaits Section 2)

func compute_supplier_delta() -> float:
    return current_delta
    # phase 3+: reads inertia/pressure/smoothing state and recomputes
```

**WS6 (delta seam state):** v0 lands ONLY `current_delta` on `ProductionInterest`. Other fields (`target_profit`, `inventory_baseline`, `state_factor`, `smoothing_lambda`, `pressure_history`) are speculative state for systems we haven't designed; per Samus, naming them now risks naming them wrong. Phase 3+ adds whatever fields the chosen smoother actually needs.

**WS2 (delta value): deferred to Section 2.** v0 uses `current_delta = 0.0` (cost pass-through, wholesale price = cost) until Section 2 picks the calibrated value alongside retail prices. Both panelists flagged that picking delta in isolation from retail produces broken numbers.

### Cost calculation (WS1)

```gdscript
# ProductionInterest (or Producer)
@export var weekly_cost_basis: float = 0.0    # locked at end-of-week, read during burst

func compute_week_cost_basis(grain_produced: int, wages_paid: int) -> float:
    if grain_produced <= 0:
        return 0.0    # no production this week
    var labor_cost := float(wages_paid)
    var seed_cost := 0.0       # v0 placeholder
    var tool_cost := 0.0       # v0 placeholder
    var land_tax := 0.0        # v0 placeholder
    return (labor_cost + seed_cost + tool_cost + land_tax) / float(grain_produced)
```

**Timing:** computed at week boundary (end of last week / start of new week), inside the burst before wholesale clearing. Producer reads `wages_paid` from the `Payable` totals just settled and `grain_produced` from the inventory delta.

For v0 with `wages_paid = 40 coin` (5 days × 8 slot-units × 1 coin/slot — see calibration above) and `grain_produced = 40 grain`, `weekly_cost_basis = 1.0 coin/grain`. With `current_delta = 0.0`, wholesale price = 1.0.

### Merchant willingness-to-pay

```gdscript
# MercantileInterest
@export var max_wholesale_price: float = 2.0    # v0 ceiling; phase 3+ derived from retail expectations
```

At wholesale clearing, the merchant's demand is honored only if `wholesale_price ≤ max_wholesale_price`. If the ask exceeds the ceiling, the merchant walks away (queues 0 demand for that clearing). With v0 wholesale price = 1.0 and ceiling 2.0, this clears trivially.

### Merchant target_inventory under leftovers (WS3)

```gdscript
# MercantileInterest.place_buy_order_at_wholesale
func place_buy_order_at_wholesale() -> void:
    var on_hand := owner.accounts.inventory.get(good_id, 0)
    var deficit: int = max(0, target_inventory - on_hand)
    print("    %s.MercantileInterest.place_buy_order_at_wholesale() — on_hand=%d, target=%d, queueing demand=%d" %
        [owner.actor_id, on_hand, target_inventory, deficit])
    if deficit == 0 or wholesale_market == null:
        return
    if wholesale_market.compute_clearing_price() > max_wholesale_price:
        print("    %s walks away — wholesale ask exceeds ceiling" % owner.actor_id)
        return
    wholesale_market.queue_demand(owner, deficit)
```

`compute_clearing_price()` on the market peeks at the producer's would-be ask without actually clearing.

### Wholesale clearing — proportional partial fill (WS4)

```gdscript
# WholesaleMarket
func clear() -> void:
    var total_supply: int = 0
    for actor_path in supply_pool.keys():
        total_supply += supply_pool[actor_path]
    var total_demand: int = 0
    for actor_path in demand_pool.keys():
        total_demand += demand_pool[actor_path]

    if total_supply == 0 or total_demand == 0:
        print("[CLEAR]    %s.clear() — nothing to clear (supply=%d, demand=%d)" % [name, total_supply, total_demand])
        supply_pool.clear()
        demand_pool.clear()
        return

    var price := compute_clearing_price()
    print("[CLEAR]    %s.clear() — supply=%d, demand=%d, price=%.2f" % [name, total_supply, total_demand, price])

    # Proportional fill: each demander gets floor(my_demand / total_demand × total_supply), capped by my_demand and by my_coin
    var allocations := {}
    for demander_path in demand_pool.keys():
        var my_demand: int = demand_pool[demander_path]
        var raw: int = int(floor(float(my_demand) * float(total_supply) / float(total_demand)))
        var capped_by_demand: int = min(raw, my_demand)
        var demander := get_node(demander_path) as Actor
        var coin_cap: int = int(floor(float(demander.accounts.coin) / price))
        allocations[demander_path] = min(capped_by_demand, coin_cap)

    # Transfer grain + coin
    for demander_path in allocations.keys():
        var qty: int = allocations[demander_path]
        if qty == 0:
            continue
        var demander := get_node(demander_path) as Actor
        var total_paid: int = int(round(float(qty) * price))
        demander.accounts.inventory[&"grain"] = demander.accounts.inventory.get(&"grain", 0) + qty
        demander.accounts.coin -= total_paid

        # Distribute payment to suppliers proportionally to their share of total_supply
        for supplier_path in supply_pool.keys():
            var supplier_share: float = float(supply_pool[supplier_path]) / float(total_supply)
            var supplier_qty: int = int(round(float(qty) * supplier_share))
            var supplier_payment: int = int(round(float(supplier_qty) * price))
            var supplier := get_node(supplier_path) as Actor
            supplier.accounts.coin += supplier_payment
            supplier.accounts.inventory[&"grain"] = supplier.accounts.inventory.get(&"grain", 0) - supplier_qty
            print("    %s sold %d grain to %s for %d coin" % [supplier.actor_id, supplier_qty, demander.actor_id, supplier_payment])

    # Leftover supply (from floor-rounding) stays in pool for next clear; clear demand
    var allocated_total: int = 0
    for qty in allocations.values():
        allocated_total += qty
    var leftover: int = total_supply - allocated_total
    if leftover > 0:
        print("[CLEAR]    %d grain remained in supply pool (floor-rounding)" % leftover)
    # Note: do NOT clear supply_pool; leftover carries to next clear
    demand_pool.clear()


func compute_clearing_price() -> float:
    # v0: single producer. Phase 3+ multi-producer needs aggregation strategy.
    var producers := supply_pool.keys()
    if producers.is_empty():
        return 0.0
    var supplier := get_node(producers[0]) as Actor
    var production := supplier.find_interest(ProductionInterest) as ProductionInterest
    if production == null:
        return 0.0
    return production.weekly_cost_basis * (1.0 + production.compute_supplier_delta())
```

**Floor-rounding rule:** each demander gets `floor(my_demand × supply / demand)`. Integer remainder (`total_supply - sum(allocations)`) stays in `supply_pool` for the next clear. This avoids phantom grain (giving more than was offered) and avoids forcing odd ratios.

**v0 N=1 + M=1 case:** algorithm collapses to "merchant gets `min(demand, supply)`, leftover supply stays."

### Self-consumption (WS5)

**Decision:** all-flows-through-markets for v0. LandOwner ships ALL grain to wholesale. LandOwner's `GrainInterest` queues retail demand daily and (when retail clearing lands in Section 2) buys grain back. Same for Merchant.

**Flag:** the `_bmad-output` notes for Section 2 (and any future intermediate-products work) should revisit self-consumption shortcuts. The "LandOwner buys their own bread" path is mechanically clean but produces a trace that reads as silly to a new viewer (Samus's concern). Consider a "private subtraction" path when intermediate products land — at that point the accounting cost is justified by avoiding the round-trip.

**No code change in this directive** — `GrainInterest.place_grain_order` and `ProductionInterest.send_grain_to_wholesale` already implement the all-flows-through-markets shape.

---

## v0 calibration values

Proposed constants for `WageCalculator` and surrounding state:

| Constant | Value | Rationale |
|---|---|---|
| `MINIMUM_WAGE` | 1.0 | Floor at 1 coin/slot — preserves build-spec acceptance numbers; matches "starting peasant pay" feel |
| `BASE_SKILL` | 2.0 | Asymptote at 2x floor — gives phase 3+ skill-divergence headroom visible in trace |
| `X_0` | 100.0 | XP scale; a worker reaches half-asymptote at XP=70 (with `a=1`), which corresponds to ~70 slots = ~17 days work |
| `A` | 1.0 | Standard saturating curve, no S-shape; phase 3+ may tune to add competence-threshold feel |
| `K` | 1.0 | Scarcity sensitivity; gentle ramp around equilibrium |
| `S_0` | 2.0 | v0 = 2 workers in region; phase 3+ derived from regional capacity |
| `MerchantInterest.target_inventory` | 60 | unchanged from build-spec |
| `MerchantInterest.max_wholesale_price` | 2.0 | comfortable ceiling against v0 cost ≈ 1.0 |
| `ProductionInterest.current_delta` | 0.0 | placeholder — Section 2 sets calibrated value |
| `GrainInterest.daily_demand` | 2 | unchanged from build-spec |

**Confirm before code moves** (#1) — author should sign off on `MINIMUM_WAGE = 1.0` + `BASE_SKILL = 2.0` (vs `MINIMUM_WAGE = 0.5` + `BASE_SKILL = 1.0`) before this lands. Samus argued for headroom; Cloud agnostic. Either is internally consistent.

---

## Trace expectations (14-day post-directive run, partial — retail still print-only)

These numbers assume the calibration above (`MINIMUM_WAGE = 1.0`, `BASE_SKILL = 2.0`, `current_delta = 0.0`, `target_inventory = 60`, `max_wholesale_price = 2.0`) and **all-flows-through-markets** (LandOwner queues retail demand daily but retail does not clear).

### Bootstrap

- `w_1`, `w_2`: 0 coin, 0 grain, 0 XP, no contract
- `LandOwner`: 200 coin, 0 grain, owns LandPlot
- `Merchant`: 100 coin, 0 grain
- All markets empty

### Week 1, Day 1 EARLY_MORNING (burst)

```
[BURST]  Week 1 Day 1 EARLY_MORNING
  wages_due           — nothing to settle (no payables)
  merchant_restock    — Merchant queues wholesale demand=60 (target=60, on_hand=0)
  wholesale_clear     — supply=0, demand=60, nothing to clear
  retail_to_supply    — Merchant on_hand=0, no inventory to ship
  retail_clear        — DEFERRED (Section 2)
  labor_market_open   — LandOwner posts open=2; w_1, w_2 offer self
  labor_market_clear  — supply=2, demand=2, RANDOM strategy, 2 contracts written
                        (rate at write: 1.0 coin/slot — floor; both workers XP=0)
```

Net coin: unchanged. Net grain: unchanged. Net contracts: 2 created.

### Week 1, Day 1 MID_MORNING through Day 7 LATE_EVENING

Days 1–7: each work day produces `2 workers × 4 slots × 1 grain = 8 grain`. Daily WW close: `+8 grain` to LandOwner; `+4 slots_worked` accumulated on each worker's Payable. Daily LATE_EVENING: each of 4 actors places retail demand=2 (LandOwner, Merchant, w_1, w_2). Retail demand pool grows but never clears.

By end of Day 7 LATE_EVENING:

- `LandOwner.accounts.inventory[grain] = 56` (7 × 8)
- `LandOwner.accounts.payables`: 2 entries, each with `slots_worked = 28` (7 × 4)
- `w_1.accounts.inventory[grain] = 0`, `w_2.accounts.inventory[grain] = 0` (delivered to LandOwner each evening)
- All workers/owner/merchant: 0 movement on coin
- Retail demand pool: 7 days × 4 actors × 2 grain = 56 grain demand (queued, not cleared)

**Note:** the build-spec's AC #3 said "by end of day 1, LandOwner inventory has 8 grain" — this is wrong because work doesn't start day 1 (LMW writes contracts on day 1 morning, work begins day 1 MID_MORNING, so day 1 *does* produce 8 grain). Actually let me re-check the daily flow: Day 1 EARLY_MORNING burst → Day 1 MID_MORNING work_window_opened → days 1 MID_MORNING through LATE_AFTERNOON: 4 slots → Day 1 EARLY_EVENING work_window_closed.

So day 1 *does* have work after the burst. By end of day 1: LandOwner has 8 grain, payables = 4 slots each. By end of day 7: 56 grain, 28 slots each. Build-spec's day 7 number was 56 coin — that comes from the *settlement* on day 8 (week 2 day 1), not "by day 7."

Updated AC #3 (see "Acceptance criteria revision" below) reflects this.

### Week 2, Day 1 EARLY_MORNING (burst)

```
[BURST]  Week 2 Day 1 EARLY_MORNING
  wages_due           — settle 2 payables, each 28 slots × 1.0 rate = 28 coin
                        LandOwner: -56 coin (now 144)
                        w_1: +28 coin (now 28); w_2: +28 coin (now 28)
                        payables cleared
  merchant_restock    — Merchant queues wholesale demand = max(0, 60-0) = 60
                        Merchant peeks wholesale price = cost(1.0) × (1 + delta(0.0)) = 1.0
                        1.0 ≤ ceiling(2.0); merchant proceeds with demand 60
  wholesale_clear     — supply=56, demand=60, price=1.0
                        Allocation = floor(60 × 56/60) = floor(56) = 56
                        Coin cap: Merchant has 100 coin / 1.0 = 100; capped at 56
                        Merchant: +56 grain (now 56), -56 coin (now 44)
                        LandOwner: -56 grain (now 0), +56 coin (now 200)
                        leftover supply = 0
  retail_to_supply    — Merchant ships 56 grain to retail supply pool
  retail_clear        — DEFERRED
  labor_market_open   — LandOwner posts open=0 (both contracts still ACTIVE)
                        w_1, w_2 don't offer (already employed)
  labor_market_clear  — nothing to match
```

Net Week 1→2 transition: LandOwner 200→144→200 coin, 56→0 grain. Workers 0→28 coin each. Merchant 100→44 coin, 0→56 grain. Day-1 burst is *real* this time.

### Week 2, Day 1 MID_MORNING through Day 7

Days 1–7: another 56 grain produced, 28 slots accumulated on each Payable. By Day 7 LATE_EVENING:

- LandOwner: 200 coin, 56 grain, 2 payables (28 slots each)
- w_1, w_2: 28 coin, 0 grain
- Merchant: 44 coin, 56 grain
- Retail demand pool: 7×4×2 = 56 grain *new* this week (plus carryover from week 1; carryover semantics open until Section 2 — Q3)

### Week 3, Day 1 EARLY_MORNING (burst) — should be steady-state

Same shape as Week 2's burst. LandOwner pays 56 coin to workers (28 each), buys 56 grain back to wholesale. By inspection the loop closes.

If retail clearing were active (Section 2): retail demand from Week 1+2 (~112 grain pooled) far exceeds Week 2's 56 supply → partial fill, workers can finally afford grain (28 coin each). All-flows-through-markets works numerically.

### Coin conservation check

Per week (steady state, week 2+):
- LandOwner pays 56 coin in wages → −56
- LandOwner sells 56 grain at 1.0 → +56 (net 0)
- Merchant buys 56 grain at 1.0 → −56
- Merchant sells (Section 2) at retail price ≥ 1.0 → +N (where N depends on retail margin)
- Workers receive 56 coin → +56

Books balance once retail clears at retail_price = wholesale_price (1.0). With non-zero merchant margin (Section 2's delta tuning), books shift but stay closed. Confirmed pre-retail.

---

## Acceptance criteria revision

The build-spec's five v0 acceptance criteria need updating for the day-1-burst timing and partial fill. New criteria for **Section 1 scope** (AC #1–4):

1. **AC #1 — Workers gain employment by Week 1 Day 1 burst.** Both `w_1` and `w_2` have `LaborContract` entries in `accounts.contracts` with `status = ACTIVE` after Week 1 Day 1 EARLY_MORNING burst completes.

2. **AC #2 — LaborContracts consistent on both parties.** Each contract written by `LaborMarket.clear()` appears in BOTH `worker.accounts.contracts` AND `employer.accounts.contracts` with matching `worker`/`employer` paths and `ACTIVE` status.

3. **AC #3 (revised) — End of Week 1 Day 7 LATE_EVENING:**
   - `LandOwner.accounts.inventory[grain] = 56`
   - `LandOwner.accounts.payables.size() = 2`, each with `slots_worked = 28`
   - All actors' coin unchanged from bootstrap (`LandOwner = 200`, others as initial)

   **End of Week 2 Day 1 EARLY_MORNING burst:**
   - `LandOwner.accounts.coin = 200` (after −56 wages, +56 wholesale)
   - `w_1.accounts.coin = 28`; `w_2.accounts.coin = 28`
   - `Merchant.accounts.coin = 44` (100 − 56 wholesale buy)
   - `LandOwner.accounts.payables` is empty
   - `LandOwner.accounts.inventory[grain] = 0` (all sold to merchant)
   - `Merchant.accounts.inventory[grain] = 56`

4. **AC #4 (revised) — Wholesale clearing on Week 2 Day 1 burst:**
   - 56 grain transfers from `LandOwner` to `Merchant`
   - 56 coin transfers reverse direction
   - Wholesale `supply_pool` empty after clear (no leftover at this calibration)
   - Print line `[CLEAR] WholesaleMarket.clear() — supply=56, demand=60, price=1.00` appears

5. **AC #5 — DEFERRED to Section 2.**

---

## Out of scope (Section 2 territory)

These belong to the retail directive's session:

- Retail clearing math (transfer logic, partial-fill at retail with consumer affordability)
- Retail price formula (cost-plus from merchant? sigmoid demand? flat?)
- Q3 outstanding_demand carry-forward semantics (decay? cap by coin? unbounded?)
- Q5 self-consumption shortcuts (revisit when intermediate products land)
- WS2 wholesale `delta` calibration value (depends on retail prices)
- Build-spec AC #5

These belong to phase 3+ (well after Section 2):

- Aptitudes (`traits: Aptitudes` on Actor) — static data, no behavior
- XP-emit on `do_one_work_slot()` — populates `accounts.skills`
- Hunger system — reads inventory, mutates hunger, affects `compute_slot_output` and `compute_daily_demand`
- Dynamic delta (inertia, pressures, smoothing) on `ProductionInterest`
- Regional `LaborMarket` (multi-region; replaces single global)
- `CHARISMA_PICK` / `PRODUCTIVITY_RANK` clearing strategies wired to lord archetypes
- Multi-producer wholesale clearing (per-producer pricing, buyer chooses cheapest)
- Employer-learning logic (would reason about wage gradients — revisit minimum_wage floor at that point)

---

## Confirm before code moves — RESOLVED 2026-05-03

Author signed off on all three:

1. **`MINIMUM_WAGE = 1.0`, `BASE_SKILL = 2.0`** — confirmed. Headroom for phase 3+ skill-divergence visibility.

2. **Strategy enum: `RANDOM` + `FIFO` both wired in v0.** Default `RANDOM`; `FIFO` available via the `clearing_strategy` `@export`. The `match` block already implements both — `FIFO` is the "no-op" branch (pick_order stays in employer-queue arrival order).

3. **The "private subtraction" flag — both surfaces.** Section 2 directive includes it in its self-consumption discussion AND it lands in `_bmad-output/phase-3-backlog.md` for revisit when intermediate products are designed.

---

## Provenance

This directive synthesizes:

1. Author elicitation pass with Claude (orchestrator) — settled Q1, burst timing, burst order, Q4, Q6, Q7, Q8, Q9, Q10, wage formula form, wholesale formula form, merchant ceiling shape, cost calculation shape, draft-style matching, `clearing_strategy` enum.
2. Two-person panel round (Cloud Dragonborn, Samus Shepard) — addressed W1, W2, W3, W4, WS1, WS3, WS4, WS5, WS6, WS7. Both panelists agreed on six; author adjudicated three disagreements (W1 → (a) per Samus; WS5 → all-routes-through-markets per Cloud, with phase-2 flag per Samus; WS6 → minimal state per Samus).
3. Project memory `project_labor_strategy.md` — labor clearing strategy as regional/lordly hook (threads economy ↔ influence track).

Anywhere this directive feels wrong, it can be overruled — the panel papers are in the conversation transcript and the disagreements were real, not papered over.

---
---

# Phase 2 Math Directive — Section 2: Retail

## How to read this

Author handed in raw retail notes (isoelastic demand + cost-plus + multi-merchant strategy enum) on 2026-05-03. Mary (BMad strategic business analyst, NOT a regular panelist) was brought in for outside-game economic vetting first, as a separate pass. Her paper informed the panel briefing. Cloud + Samus then produced reaction papers in parallel, each opining on R1–R8 + S1–S4 and reacting to Mary's 12 tagged recommendations. Author adjudicated four real disagreements between Cloud and Samus.

This section retires the math gaps in *retail* — clearing math, demand formula, price formation, affordability, carry-forward semantics, strategy scaffold, and the wholesale `δ_wholesale` value held back from Section 1's WS2. Where Section 2 amends Section 1's commitments, the amendments are flagged in "Spec amendments" below.

---

## Spec amendments

These change Section 1 commitments. Read carefully.

### Wholesale clearing must write `wholesale_cost_per_unit` back to merchants

Section 1's `WholesaleMarket.clear()` transfers grain and coin but does not record per-unit cost on the merchant. Section 2's `min_retail_margin` floor on `MercantileInterest` needs that field populated, otherwise the floor compares against zero and the guard does nothing.

**Required addition to `WholesaleMarket.clear()`** (after each demander's transfer):

```gdscript
# After: demander.accounts.coin -= total_paid
var merchant_interest := demander.find_interest(MercantileInterest) as MercantileInterest
if merchant_interest != null:
    merchant_interest.wholesale_cost_per_unit = price    # the clearing price for this round
```

This means the merchant always knows their last per-unit acquisition cost. With v0's single producer + single merchant, this is unambiguous. Phase 3+ multi-producer wholesale will need a weighted-average across producers — flagged below in "Out of scope."

### `MercantileInterest.send_inventory_to_retail()` must queue actual quantity

The current code in the repo:

```gdscript
func send_inventory_to_retail() -> void:
    print("    %s.MercantileInterest.send_inventory_to_retail() — emit %s supply to RetailMarket" % [owner.actor_id, good_id])
    if retail_market != null:
        retail_market.queue_supply(owner, 0)    # <— placeholder zero
```

**Required change:**

```gdscript
func send_inventory_to_retail() -> void:
    var qty: int = owner.accounts.inventory.get(good_id, 0)
    print("    %s.MercantileInterest.send_inventory_to_retail() — supplying %d %s to RetailMarket" % [owner.actor_id, qty, good_id])
    if retail_market != null and qty > 0:
        retail_market.queue_supply(owner, qty)
```

Section 1 left this as a stub. Section 2 closes it.

### `GrainInterest.daily_demand` field is removed

Replaced by `compute_demand_at_price(price, days)` which derives demand from the formula. The existing `daily_demand: int = 2` field gave constant per-day demand independent of price; the new model has demand respond to merchant pricing at clearing time. The numeric calibration target (≈2 grain/day per actor at P=1) is preserved — see `GoodConfig.GRAIN_A_PER_ACTOR_DAILY = 2.0` below.

### `GrainInterest.place_grain_order()` is removed; replaced by `_register_demand()`

Demand quantity is no longer accumulated daily into `outstanding_demand`. Instead, on the `retail_market_opened` burst signal, each `GrainInterest` registers itself with the market. The market polls each registered demander for actual demand at clearing time using the formula.

`outstanding_demand` semantics change: it now holds **post-clearing unmet need only**, not a daily-accumulating tally. Daily firings no longer change it.

### Burst order — retail clear is no longer print-only

Section 1's day-1 burst order:
```
1. wages_due
2. merchant_restock
3. wholesale clear
4. send_inventory_to_retail
5. retail clear         ← was DEFERRED; Section 2 wires it
6. labor_market clear
```

Step 5 now executes the full retail clearing math. A new sub-step lands between (4) and (5):

```
4a. retail_market_opened    ← new burst signal; GrainInterest holders register as demanders
```

`WindowBus.retail_market_opened` already exists and triggers `RetailMarket.clear` indirectly through `retail_market_closed` in Section 1's wiring. The wiring needs a small adjustment:

- `WindowBus.retail_market_opened.connect(GrainInterest._register_demand)` — fires before clearing
- `WindowBus.retail_market_closed.connect(RetailMarket.clear)` — fires after registration

If the existing wiring uses different signal names, adapt accordingly. The sequence requirement is: register-before-clear.

---

## Positions taken

### Demand formula (locked, per author + Mary + Cloud + Samus)

```
Q_d_per_actor(P, days) = A_per_actor_daily × P^(−e_g) × days
```

Per-actor, per-good. `A_per_actor_daily` and `e_g` live on `GoodConfig`. Aggregate market demand at clearing time = sum across all demanders.

### Equilibrium price (locked)

```
P* = (A_total / Q_s)^(1 / e_g)
```

Solved by `RetailMarket.compute_equilibrium_price(good_id)`. **Q_s = 0 guard:** if total supply pool is empty, return 0.0 and skip clearing.

```gdscript
# RetailMarket
func compute_equilibrium_price(good_id: StringName) -> float:
    var total_supply: float = 0.0
    for actor_path in supply_pool.keys():
        total_supply += float(supply_pool[actor_path])
    if total_supply <= 0.0:
        return 0.0    # Mary's Rec 3 guard

    var a_total: float = 0.0
    var e_g: float = GoodConfig.elasticity(good_id)
    for actor_path in demand_pool.keys():
        var actor := get_node(actor_path) as Actor
        a_total += GoodConfig.a_per_actor_daily(good_id) * 7.0    # weekly aggregation; days=7 in v0

    return pow(a_total / total_supply, 1.0 / e_g)
```

### Merchant retail price (locked, per Cloud)

```
P_m = max(floor_price, P* × (1 + δ_retail))
floor_price = wholesale_cost_per_unit × (1 + min_retail_margin)
δ_retail clamped ≥ 0
```

Computed per-merchant on `MercantileInterest.compute_retail_price(p_star)`.

```gdscript
# MercantileInterest (new fields)
@export var delta_retail: float = 0.1            # v0 starting markup; clamped ≥ 0 in compute
@export var min_retail_margin: float = 0.0       # R6 seam; merchant won't sell below cost × (1 + this)
var wholesale_cost_per_unit: float = 0.0         # written by WholesaleMarket.clear()

func compute_retail_price(p_star: float) -> float:
    var clamped_delta: float = max(0.0, delta_retail)    # R1: no markdowns in v0
    var unclamped: float = p_star * (1.0 + clamped_delta)
    var floor_price: float = wholesale_cost_per_unit * (1.0 + min_retail_margin)
    return max(floor_price, unclamped)
```

### Affordability (locked R2-c, hybrid)

`GrainInterest` queues raw demand at clearing time. `RetailMarket.clear()` checks each demander's coin balance: if affordable < want, partial transfer happens and the unfilled remainder becomes new outstanding_demand. The print surface explicitly reports affordability failures (per Samus's emphasis).

### outstanding_demand carry-forward (locked R5-b, **per-good decay**)

Author adjudicated to Samus's decay over Mary+Cloud's cap-weekly. Generalized: each good carries its own decay rate so that "demand for services has λ ≈ 1 (clears each period)" lands cleanly. v0 grain uses λ = 0.3 (slow decay; carry halves roughly every two missed clearings).

**At clearing, decay is applied destructively before reading. Post-clearing, anything wanted but not received becomes the new outstanding_demand:**

```gdscript
# GrainInterest
var outstanding_demand: float = 0.0    # post-clearing unmet need; decayed at next clearing

func compute_demand_at_price(price: float, days: int) -> float:
    var a := GoodConfig.a_per_actor_daily(&"grain")
    var e := GoodConfig.elasticity(&"grain")
    return a * pow(price, -e) * float(days)

func decay_carried_demand() -> float:
    # destructive: applies decay, returns new outstanding_demand value
    var lambda := GoodConfig.decay_lambda(&"grain")
    outstanding_demand *= (1.0 - lambda)
    return outstanding_demand

func record_clearing(wanted: float, received: float) -> void:
    outstanding_demand = max(0.0, wanted - received)
    print("    %s.GrainInterest.record_clearing() — wanted %.1f, received %.1f, %.1f outstanding" %
        [owner.actor_id, wanted, received, outstanding_demand])

func _register_demand() -> void:
    if retail_market != null:
        retail_market.queue_demand(owner, 0)    # registration only; qty resolved at clearing
        print("    %s.GrainInterest._register_demand() — registered as grain demander" % owner.actor_id)
```

### `δ_wholesale = 0.0` for v0 (Section 1's WS2, now locked)

Section 1 deferred this value because it depended on retail design. Now resolved: `δ_wholesale = 0.0` in v0. Reasons:
1. Avoids double-marginalization — combined markup `(1 + δ_w)(1 + δ_r)` would compound and break v0's clean 1.0 cost basis
2. Isolates the retail markup as the only margin in the v0 trace
3. Coin conservation holds cleanly

When `δ_wholesale` turns on (phase 3+), the directive should note: combined markup is **multiplicative, not additive** — `(1 + δ_w)(1 + δ_r)`, not `(1 + δ_w + δ_r)`.

### `GoodConfig` Resource + `Goods` autoload (per-good Resource pattern, landed early)

Author confirmed shipping the per-good Resource pattern at v0 instead of an autoload-with-branches. v0 cost is one extra file (`grain.tres`); phase 3+ benefit is "add a new good = drop a `*.tres`, register it once."

**Resource definition:**

```gdscript
# scripts/economy/good_config.gd
class_name GoodConfig
extends Resource

@export var good_id: StringName = &""
@export var elasticity: float = 1.0          # e_g — demand elasticity (low = inelastic / sticky)
@export var a_per_actor_daily: float = 1.0   # baseline daily demand per actor at P=1
@export var decay_lambda: float = 1.0        # outstanding_demand carry decay; 0.0=carry forever, 1.0=clears each period
```

**v0 grain instance** (`scripts/economy/goods/grain.tres`):

```
[gd_resource type="Resource" script_class="GoodConfig" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/economy/good_config.gd" id="1"]

[resource]
script = ExtResource("1")
good_id = &"grain"
elasticity = 0.4
a_per_actor_daily = 2.0
decay_lambda = 0.3
```

**Registry autoload** (`scripts/economy/good_registry.gd`, autoloaded as `Goods`):

```gdscript
extends Node

@export var configs: Array[GoodConfig] = []
var _by_id: Dictionary = {}    # StringName → GoodConfig

func _ready() -> void:
    for cfg in configs:
        if cfg == null: continue
        _by_id[cfg.good_id] = cfg
        print("[Wire] Goods registered: %s (e_g=%.2f, A=%.1f, λ=%.2f)" %
            [cfg.good_id, cfg.elasticity, cfg.a_per_actor_daily, cfg.decay_lambda])

func config_for(good_id: StringName) -> GoodConfig:
    var cfg: GoodConfig = _by_id.get(good_id, null)
    if cfg == null:
        push_error("Goods.config_for(): unknown good %s" % good_id)
    return cfg
```

The `Goods` autoload's `configs` Array is populated in the editor — drag `grain.tres` in. Phase 3+: drop `services.tres`, `bread.tres`, etc. into `goods/`, drag them in, done.

**Decay-lambda guidance per good type** (per author):
- `0.0` — carry forever (theoretical; no v0 use case)
- `0.3` — slow decay (grain v0; outstanding need fades but persists for several missed clearings)
- `1.0` — clears each period (services — you don't carry "missed haircuts" forward; default for new goods)
- intermediate values — tune per good's "memory of unmet need" feel

**Call-site shape:** anywhere Section 2 says `GoodConfig.elasticity(&"grain")` etc., replace with `Goods.config_for(&"grain").elasticity`. Equivalent example for the demand formula:

```gdscript
# GrainInterest.compute_demand_at_price
func compute_demand_at_price(price: float, days: int) -> float:
    var cfg := Goods.config_for(&"grain")
    return cfg.a_per_actor_daily * pow(price, -cfg.elasticity) * float(days)

func decay_carried_demand() -> float:
    var cfg := Goods.config_for(&"grain")
    outstanding_demand *= (1.0 - cfg.decay_lambda)
    return outstanding_demand
```

Same pattern in `RetailMarket.compute_equilibrium_price()` — read `cfg.elasticity` and `cfg.a_per_actor_daily` from the resource.

### Retail clearing — proportional + strategy enum scaffold

Single-merchant scope locked (per Cloud + Samus + Mary). Multi-merchant strategies named in the enum but bodies are stubs.

```gdscript
class_name RetailMarket
extends Market

@export var good_id: StringName = &"grain"

enum ClearingStrategy {
    PROPORTIONAL,        # v0 wired
    FIFO,                # stub
    SUPPLY_LADDER,       # stub: merchants by P_m ascending; consumers fill from cheapest
    MARKET_PERCEPTION,   # stub: consumers by perception skill descending
    CHARISMA_FAVOR,      # stub: merchant prefers high-CHA actors → fill priority
    BARTERING,           # stub: high-bartering actors get per-actor price discount
}

@export var clearing_strategy: ClearingStrategy = ClearingStrategy.PROPORTIONAL

func _ready() -> void:
    WindowBus.retail_market_closed.connect(clear)
    print("[Wire] RetailMarket.clear ← WindowBus.retail_market_closed")

func clear() -> void:
    match clearing_strategy:
        ClearingStrategy.PROPORTIONAL: _clear_proportional()
        ClearingStrategy.FIFO:         _clear_fifo()
        _: push_error("RetailMarket: unimplemented clearing strategy %d" % clearing_strategy)

func _clear_proportional() -> void:
    var total_supply: float = 0.0
    for actor_path in supply_pool.keys():
        total_supply += float(supply_pool[actor_path])

    if total_supply <= 0.0 or demand_pool.is_empty():
        print("[CLEAR]    %s.clear() — nothing to clear (supply=%.1f, demanders=%d)" % [name, total_supply, demand_pool.size()])
        supply_pool.clear()
        demand_pool.clear()
        return

    # Single-merchant v0: one supplier in supply_pool
    var merchant_path: NodePath = supply_pool.keys()[0]
    var merchant := get_node(merchant_path) as Actor
    var merchant_interest := merchant.find_interest(MercantileInterest) as MercantileInterest

    # Compute equilibrium and merchant markup
    var p_star: float = compute_equilibrium_price(good_id)
    var p_m: float = merchant_interest.compute_retail_price(p_star)
    print("[CLEAR]    %s.clear() — supply=%.1f, P*=%.2f, P_m=%.2f" % [name, total_supply, p_star, p_m])

    # Per-actor demand resolution: decay carry, add this week's demand
    var actor_wants: Dictionary = {}     # actor_path → float (raw want)
    var total_want: float = 0.0
    for actor_path in demand_pool.keys():
        var actor := get_node(actor_path) as Actor
        var gi := actor.find_interest(GrainInterest) as GrainInterest
        if gi == null:
            continue
        gi.decay_carried_demand()    # destructive
        var this_week: float = gi.compute_demand_at_price(p_m, 7)
        var want: float = this_week + gi.outstanding_demand
        actor_wants[actor_path] = want
        total_want += want

    if total_want <= 0.0:
        print("[CLEAR]    %s.clear() — no demand expressed" % name)
        supply_pool.clear()
        demand_pool.clear()
        return

    # Allocate proportionally, then cap by affordability per actor
    for actor_path in actor_wants.keys():
        var actor := get_node(actor_path) as Actor
        var gi := actor.find_interest(GrainInterest) as GrainInterest
        var want: float = actor_wants[actor_path]
        var supply_share: float = total_supply * (want / total_want)
        var affordable: float = float(actor.accounts.coin) / max(p_m, 0.001)
        var received: float = min(want, min(supply_share, affordable))
        var coin_paid: int = int(round(received * p_m))
        var grain_received: int = int(round(received))

        # Transfer
        actor.accounts.inventory[good_id] = actor.accounts.inventory.get(good_id, 0) + grain_received
        actor.accounts.coin -= coin_paid
        merchant.accounts.inventory[good_id] = merchant.accounts.inventory.get(good_id, 0) - grain_received
        merchant.accounts.coin += coin_paid

        # Affordability failure surface (Samus's emphasis)
        if affordable < want:
            print("    %s: wanted %.1f, could afford %.1f, received %.1f. %.1f outstanding." %
                [actor.actor_id, want, affordable, float(received), max(0.0, want - received)])
        else:
            print("    %s: wanted %.1f, received %.1f. %.1f outstanding." %
                [actor.actor_id, want, float(received), max(0.0, want - received)])

        gi.record_clearing(want, received)

    # Leftover supply stays with merchant (carries inventory across weeks)
    var allocated: float = 0.0
    for actor_path in actor_wants.keys():
        allocated += min(actor_wants[actor_path], total_supply * (actor_wants[actor_path] / total_want))
    var leftover: float = total_supply - allocated
    if leftover > 0.5:
        print("[CLEAR]    %s leftover with merchant: %.1f grain" % [name, leftover])

    supply_pool.clear()
    demand_pool.clear()

func _clear_fifo() -> void:
    push_error("RetailMarket: FIFO strategy not implemented in v0")
```

**Strategy enum vocabulary** (per Samus's distinctions, locked):

- `PROPORTIONAL` — v0 wired. Each demander gets `total_supply × (my_want / total_want)`, capped by affordability.
- `FIFO` — stub. Demand-arrival order.
- `SUPPLY_LADDER` — stub. Multi-merchant only; merchants sorted by P_m ascending; consumers fill from cheapest until exhausted, overflow to next.
- `MARKET_PERCEPTION` — stub. Consumers sorted by perception skill descending; high-perception actors find cheapest available stall first. Reads `actor.accounts.skills.get(&"market_perception", 0.0)`.
- `CHARISMA_FAVOR` — stub. Merchant fill priority — high-CHA actors get served first regardless of queue position. Reads `actor.accounts.skills.get(&"charisma", 0.0)`. Affects allocation order, not price.
- `BARTERING` — stub. Per-actor price discount: `effective_P_m = P_m × (1 − barter_discount(skill))`. Reads `actor.accounts.skills.get(&"bartering", 0.0)`. Affects price paid, not allocation order.

`CHARISMA_FAVOR` and `BARTERING` are intentionally separate enum entries — different mechanics, different design intent. SUPPLY_LADDER + MARKET_PERCEPTION combine at runtime when both are needed; not a single entry.

---

## v0 calibration values

Section 2 additions (Section 1 values from the table at line 449 still apply):

| Constant | Value | Rationale |
|---|---|---|
| `GoodConfig.GRAIN_ELASTICITY` | 0.4 | Mary: pre-industrial subsistence elasticity ranges 0.4–0.7; 0.4 produces "people are trying" texture in trace |
| `GoodConfig.GRAIN_A_PER_ACTOR_DAILY` | 2.0 | Calibrated to preserve old `daily_demand=2` numerical regime; aggregates to 14 grain/week per actor |
| `GoodConfig.GRAIN_DECAY_LAMBDA` | 0.3 | Slow decay: outstanding_demand halves roughly every two missed clearings; texture of accumulating consequence |
| `MercantileInterest.delta_retail` | 0.1 | Modest markup; produces P_m ≈ 1.1 against v0 wholesale_cost ≈ 1.0 |
| `MercantileInterest.min_retail_margin` | 0.0 | Seam exists at zero; merchant won't sell below wholesale cost in v0 (when combined with R1's δ_retail ≥ 0 clamp) |
| `MercantileInterest.wholesale_cost_per_unit` | 0.0 (initial) | Written by `WholesaleMarket.clear()` after first wholesale transfer |
| `ProductionInterest.current_delta` (Section 1's WS2) | 0.0 | δ_wholesale resolved here; producer earns no margin in v0; turn on when phase 3+ profit-pressure logic exists |

---

## Trace expectations (14-day post-Section-2 run, retail now active)

These numbers assume the calibrations above plus Section 1's (`MINIMUM_WAGE = 1.0`, `BASE_SKILL = 2.0`, `target_inventory = 60`, `max_wholesale_price = 2.0`) and **all-flows-through-markets** (LandOwner, Merchant, w_1, w_2 all consume retail).

### Week 1, Day 1 EARLY_MORNING (burst)

```
[BURST]  Week 1 Day 1 EARLY_MORNING
  wages_due           — nothing to settle
  merchant_restock    — Merchant queues wholesale demand=60 (target=60, on_hand=0)
  wholesale_clear     — supply=0, demand=60, nothing to clear
                        (wholesale_cost_per_unit on Merchant remains 0.0)
  retail_to_supply    — Merchant on_hand=0, no inventory queued (qty=0 guard skips queue)
  retail_register     — 4 GrainInterests register as demanders (LandOwner, Merchant, w_1, w_2)
  retail_clear        — supply=0.0, demanders=4, nothing to clear (Q_s = 0 guard)
  labor_market_open   — LandOwner posts open=2; w_1, w_2 offer self
  labor_market_clear  — 2 contracts written at 1.0 coin/slot
```

### Week 1, Days 1–7 production

Days 1–7 produce 56 grain at LandOwner (8 grain/day × 7 days). Daily WW close transfers grain worker→LandOwner, accrues Payable slots. **No daily retail demand accumulation** (place_grain_order removed; `_register_demand` only fires on `retail_market_opened` burst signal). `outstanding_demand` stays at 0 across all actors.

**End of Week 1 Day 7 LATE_EVENING:**
- LandOwner: 200 coin, 56 grain, 2 payables (28 slots each)
- w_1, w_2: 0 coin, 0 grain
- Merchant: 100 coin, 0 grain, `wholesale_cost_per_unit = 0.0`
- All `outstanding_demand = 0`

### Week 2, Day 1 EARLY_MORNING (burst — first real retail clear)

```
[BURST]  Week 2 Day 1 EARLY_MORNING
  wages_due           — settle 2 payables, 28 slots × 1.0 = 28 coin each
                        LandOwner: 200 → 144 coin
                        w_1: 0 → 28 coin; w_2: 0 → 28 coin
  merchant_restock    — Merchant queues wholesale demand=60
                        wholesale_price peek = cost(1.0) × (1 + δ_w(0.0)) = 1.0
                        ≤ ceiling 2.0; merchant proceeds
  wholesale_clear     — supply=56, demand=60, price=1.0
                        proportional fill: floor(60 × 56/60) = 56
                        Merchant: 144→44 coin, 0→56 grain
                        LandOwner: 144→200 coin, 56→0 grain
                        Merchant.wholesale_cost_per_unit = 1.0    ← NEW (Section 2 amendment)
  retail_to_supply    — Merchant queues 56 grain to retail supply
  retail_register     — 4 GrainInterests register
  retail_clear        — supply=56.0, 4 demanders
                        compute_equilibrium_price(grain):
                          A_total = 4 × 2.0 × 7 = 56
                          P* = (56/56)^(1/0.4) = 1.0^2.5 = 1.0
                        compute_retail_price(1.0):
                          δ_retail = 0.1 (clamped ≥ 0 → 0.1)
                          unclamped = 1.0 × 1.1 = 1.1
                          floor = 1.0 × (1 + 0.0) = 1.0
                          P_m = max(1.0, 1.1) = 1.1
                        per-actor demand:
                          decay_carried_demand: outstanding_demand × 0.7 = 0
                          this_week = 2.0 × 1.1^(-0.4) × 7 = 14 × 0.962 = 13.47
                          want = 13.47 each, total_want = 53.87
                        per-actor allocation:
                          supply_share = 56 × (13.47/53.87) = 14.0 each (proportional)
                          affordable check:
                            LandOwner: 144 / 1.1 = 130.9 → can afford want
                            w_1: 28 / 1.1 = 25.45 → can afford want
                            w_2: 25.45 → can afford
                            Merchant: 44 / 1.1 = 40 → can afford
                          received = min(13.47, 14.0, affordable) = 13.47 each
                          rounded: each gets 13 grain at 14 coin, or 14 grain at 15 coin
                          (rounding decision — see "Rounding policy" below)
                        Print per-actor:
                          "LandOwner: wanted 13.5, received 13. 0.5 outstanding."
                          (similar for others)
                        leftover with merchant: 56 - 53.87 ≈ 2.1 grain
  labor_market_open   — both contracts ACTIVE; nothing to match
```

### Week 2, Days 1–7

Same daily flow as Week 1: 56 more grain produced at LandOwner. Workers earn slots. Retail demand is NOT being expressed daily (registered only at next burst). `outstanding_demand` per actor is ~0.5 from Week 2's small unmet need.

### Week 3, Day 1 EARLY_MORNING (steady state)

Should look like Week 2's burst with minor variation. Workers' coin grows: 28 + 13 = 41 coin (had 28, paid 14 at retail, earned 28 wages). Merchant is sitting on ~2 leftover grain from last week + 56 new = 58 grain. Wholesale clears 56 grain again. Retail supply ≈ 58, P* slightly lower (more supply, same demand). Workers can afford easily. Leftover accumulates slowly at merchant.

**Coin flow per week (steady state):**
- Wages: LandOwner −56, workers +28 each
- Wholesale: LandOwner +56, Merchant −56
- Retail: LandOwner −15, Merchant +15, w_1 −15, w_2 −15, Merchant collects all 4 = +60
  - Wait: each of 4 actors pays ~15 to merchant at P_m=1.1 for ~13.5 grain
  - LandOwner: −15, w_1: −15, w_2: −15, Merchant: −15 (own consumption) + +60 received = +45 net
  - Hmm — Merchant pays themselves? See Mary's self-consumption coin-leak note.

**Mary's self-consumption coin-leak:** In all-flows-through-markets (Section 1 WS5 lock), Merchant buys their own retail grain. That's a wash on the merchant's own coin — they pay themselves. But because of `int(round(...))` rounding, the 4 actors' payments don't exactly sum to merchant inflows. Drift is ~1 coin/week. Over the 14-day prototype this is ≤ 2 coin total — does not threaten conservation visibly.

### Coin conservation check (Week 2, steady state)

- LandOwner: −56 (wages) +56 (wholesale) −15 (retail) = −15
- Merchant: −56 (wholesale buy) +60 (retail revenue from 4 buyers) −15 (own retail consumption, paid to self) = −11... hmm
- w_1: +28 (wages) −15 (retail) = +13
- w_2: +13
- Total system: −15 + −11 + 13 + 13 = 0 ✓ (within ~2 coin of int rounding noise)

Books balance approximately. The slow merchant drain Mary flagged (1.4 coin/week at δ_retail=0.1) is the rounding-noise contribution; it's a real but small effect that becomes interesting in long-running sims, not the 14-day prototype.

### Rounding policy

Grain quantities resolve to integers (matches Section 1's wholesale convention). Demand and price computations use floats; transfers use `int(round(x))`. The print surface shows the float demand and the integer transfer side-by-side so the rounding is legible:

```
"LandOwner: wanted 13.5, received 13. 0.5 outstanding."
```

The 0.5 stays in `outstanding_demand` as a float. After decay it's 0.35 next week, plus this week's 13.5 = 13.85 want. The float carry makes decay smooth; integer transfers keep the ledger clean.

---

## Acceptance criteria revision

Section 1's AC #5 was DEFERRED. Section 2 now lands it.

5. **AC #5 (revised) — Retail clears on Week 2 Day 1 burst:**
   - `RetailMarket._clear_proportional()` runs; print line `[CLEAR] RetailMarket.clear() — supply=56.0, P*=1.00, P_m=1.10` appears
   - All 4 actors receive grain in proportion to their want, capped by affordability
   - Each actor's print line follows the format `"<name>: wanted X.X, received X. X.X outstanding."`
   - LandOwner, Merchant, w_1, w_2 all have non-zero `accounts.inventory[&"grain"]` after clear
   - Merchant's coin balance reflects net retail revenue (within rounding noise)
   - Retail `supply_pool` and `demand_pool` are cleared (leftover stays with merchant via inventory carry, not pool carry)

Section 1's AC #1–4 are unchanged.

---

## Out of scope (phase 3+ territory)

- **Multi-merchant clearing.** Strategy enum entries SUPPLY_LADDER, MARKET_PERCEPTION, CHARISMA_FAVOR, BARTERING are named but not wired. Phase 3+ implements bodies.
- **Multi-good economy.** `GoodConfig` autoload supports per-good lookup but only grain has values. Adding a second good means populating `GoodConfig` for that good; cross-price elasticity is a separate design concern.
- **Per-actor demand multiplier.** `GrainInterest.demand_multiplier: float = 1.0` is the seam for "this actor eats more/less than baseline" — not implemented in v0 (uniform A across actors per Samus R3). Phase 3+ wires multiplier reads.
- **Per-good `GoodConfig` Resource migration.** v0 uses an autoload with `if good_id == &"grain"` branches. Phase 3+ replaces with `Resource` per good loaded from `*.tres` files.
- **Multi-producer wholesale `wholesale_cost_per_unit` aggregation.** v0 has 1 producer; Section 2's amendment writes a single price. Phase 3+ multi-producer needs weighted-average cost per merchant per round.
- **Dynamic δ_retail.** `MercantileInterest.delta_retail` is static. Phase 3+ adds inertia/pressure/smoothing seams (mirror of Section 1's `current_delta` for producers).
- **Dynamic δ_wholesale (already locked-deferred from Section 1).** When δ_wholesale > 0 lands, document combined markup as multiplicative `(1 + δ_w)(1 + δ_r)`.
- **Negative δ_retail (markdown / liquidation).** Locked at 0 in v0 per R1. Revisit when spoilage / loss-leader mechanics land.
- **Merchant inventory carry-across-weeks behavior.** Leftover grain stays with merchant; this is the behavior, but no spoilage, no insurance, no "merchant decides whether to discard" logic. Phase 3+ may add inventory aging.
- **Hunger pressure from outstanding_demand.** Field exists, decays, accumulates in v0 — but phase-3+ hunger reads and reacts. v0 trace has the data; nothing acts on it yet.
- **Monopoly markup property.** With grain at e_g=0.4, optimal monopoly markup is unbounded (constrained only by affordability). Document when dynamic δ_retail lands; not a v0 concern.
- **Market tuning scene.** Author's planned debug tool (sliders + live re-clearing) — see project memory `project_market_tuning_tool.md`. Tooling pass after Phase 2 implementation stabilizes.

---

## Confirm before code moves — RESOLVED 2026-05-03

Author signed off on both:

1. **`GoodConfig` shape: per-good Resource pattern landed early.** v0 ships `grain.tres` + `Goods` autoload with Array-driven registry. See "GoodConfig Resource + Goods autoload" above. Phase 3+ just adds more `*.tres` files.

2. **`outstanding_demand` field: float.** Per-good decay generalization (λ = 0.0 / 0.3 / 1.0 / anything between) produces fractional results; float is the natural fit. Decay where it matters (grain), no decay where it doesn't (services clear with λ=1.0), full configurability per `GoodConfig.decay_lambda`.

---

## Provenance

This section synthesizes:

1. Author's raw retail notes (delivered 2026-05-03) — locked the isoelastic demand form, equilibrium price, merchant markup formula, and multi-merchant strategy intuition.
2. Mary (BMad strategic business analyst, single-pass economic vetting) — `phase-2-math-mary-economic-vetting.md`. 12 tagged recommendations across elasticity values, time-varying elasticity, real-vs-game simplifications, game theory, failure modes. Key contributions: e_g = 0.4 calibration, structural Q_d ≤ Q_s flag at δ ≥ 0, monopoly markup warning, double marginalization flag.
3. Cloud Dragonborn (Game Architect) — `phase-2-math-cloud-retail.md`. Architectural seam decisions, function signatures, S1–S4 placement, surfaced wholesale_cost_per_unit write-back as load-bearing.
4. Samus Shepard (Game Designer) — `phase-2-math-samus-retail.md`. Game-feel positions, R5 decay over cap-weekly, multi-merchant strategy vocabulary distinction (CHARISMA_FAVOR vs BARTERING as separate axes), trace surface emphasis (affordability failure print line).
5. Author adjudication of four Cloud-vs-Samus disagreements (D1–D4):
   - D1 (R5 carry-forward): Samus's decay wins, generalized to per-good λ on `GoodConfig`. Services would carry λ=1 (clears each period); grain v0 = 0.3.
   - D2 (R4 period of Q_d): Cloud's per-day with explicit period multiplier wins.
   - D3 (δ_retail starting value): Cloud's 0.1 accepted. Author flagged the slider-tuning scene as the right place to revisit; saved as `project_market_tuning_tool.md` memory.
   - D4 (multi-merchant strategy vocabulary): Samus's CHARISMA_FAVOR vs BARTERING distinction wins; six strategy enum entries locked.

Anywhere this section feels wrong, it can be overruled — Mary, Cloud, and Samus's papers are in `_bmad-output/`, the disagreements were real, and the adjudications are recoverable.
