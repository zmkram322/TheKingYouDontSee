---
name: Phase 2 Math — Cloud's Retail Position Paper
status: panel-paper
date: 2026-05-03
panelist: Cloud Dragonborn (Game Architect)
inputs_read:
  - phase-2-math-brief-retail.md
  - phase-2-math-mary-economic-vetting.md
  - phase-2-math-directive.md (Section 1)
  - tkyds-game/scripts/ (current code)
purpose: |
  Architecture-side position on retail clearing, price formation, affordability,
  carry-forward semantics, and the strategy-enum scaffold. Reaction to Mary's
  hand-off (fold/defer recommendations).
---

# Cloud's Retail Position Paper

## Reaction to Mary's hand-off

**Rec 1 — Set e_g = 0.4 for grain. AGREE-FOLD.**
This is a pure config constant. It lives in `GoodConfig` (or its v0 stand-in, the constant block at the top of `RetailMarket` or a companion resource). The seam is just a named field — `const GRAIN_ELASTICITY: float = 0.4`. No architectural concern; fold it.

**Rec 2 — Confirm A is per-actor, not aggregate. AGREE-FOLD.**
Mary is right that aggregate A breaks on any actor-count change and per-actor A doesn't. This directly answers R3 — see that section. Fold the decision; the constant placement is the only architectural question remaining.

**Rec 3 — Guard Q_s = 0 before computing P*. AGREE-FOLD.**
`RetailMarket.compute_equilibrium_price()` must return `0.0` and skip clearing if supply pool is empty. This is a one-liner guard clause. It belongs in the directive as a mandatory code constraint, not an afterthought.

**Rec 4 — Name `Merchant.min_retail_margin` on MercantileInterest, set to 0.0. AGREE-FOLD.**
The seam must exist even at 0.0. Mary's failure mode analysis (merchant goes insolvent in 8 weeks at δ_retail = -0.1) confirms this is load-bearing. The field belongs on `MercantileInterest`, not on `RetailMarket` — the merchant decides their floor, the market just clears at whatever price the merchant posts. Field name: `@export var min_retail_margin: float = 0.0`.

**Rec 5 — Affordability at clearing, hybrid R2-c approach. AGREE-FOLD.**
Architecture agrees. See R2 below.

**Rec 6 — Cap outstanding_demand at this-week's Q_d, not carry forever. AGREE-FOLD.**
Architecture agrees. See R5 below.

**Rec 7 — δ_wholesale stays 0.0 for v0. AGREE-FOLD.**
Architecture agrees. See R8 below.

**Rec 8 — Single-merchant scope for v0. AGREE-FOLD.**
Architecture agrees. See R7 below.

**Rec 9 — Document monopoly markup property in trace expectations. AGREE-DEFER (PHASE 3+).**
Not a Phase 2 code concern. One-paragraph note in the Phase 3+ section of the architecture log is sufficient; no code seam needed now.

**Rec 10 — Cross-price elasticity note when second goods arrive. AGREE-DEFER (PHASE 3+).**
Making `e_g` a per-good config constant (already the direction) is the correct seam. No additional work for Section 2.

**Rec 11 — Double marginalization flag for when δ_wholesale turns on. AGREE-DEFER (PHASE 3+).**
Flag for the session that turns on δ_wholesale. The architecture already isolates `ProductionInterest.current_delta`, which is the right seam. No Phase 2 action.

**Rec 12 — Giffen good behavior. AGREE-DROP.**
Requires replacing the isoelastic form. Way out of scope. Drop.

**Structural flag from Mary's Section 3 (the demand-then-markup two-pass):**
Mary correctly identifies that at any δ_retail ≥ 0, Q_d(P_m) ≤ Q_s always holds, so the merchant never sells out in the single-merchant case. Rationing in v0 therefore only enters via affordability (R2-c). This is not a bug — it is the design. The directive should state it plainly so the trace-reader doesn't interpret unsold inventory as broken code.

---

## R1 — Where does rationing arise?

**Position: Constrain v0 to δ_retail ≥ 0. Affordability rationing only.**

With δ_retail clamped to non-negative values (enforce via `max(0.0, delta_retail)` at P_m computation), rationing in the single-merchant v0 case comes only from R1-c (consumers want grain, can't pay). That is the one path that needs to work in v0. R1-b (multi-merchant split) is deferred. R1-a (merchant marks down) requires a mechanism we haven't designed (spoilage pressure, loss-leader intent) and produces a semantically different clearing path. Allowing δ_retail < 0 in v0 would make the single-merchant mark-down path accidentally reachable with no guard logic to catch it. Lock δ_retail ≥ 0 by clamping at compute time; revisit if liquidation mechanics land in a later phase.

---

## R2 — Affordability: where does coin enter?

**Position: (c) hybrid — express raw demand, skip at clearing if coin insufficient, carry remainder to outstanding_demand.**

This is the only shape that keeps the seam clean for phase 3+. Option (a) buries purchasing-power failure inside `GrainInterest.place_grain_order()` — the market never sees the want, only the affordable slice. When hunger lands, there is nothing to read. Option (b) expresses raw demand but clearing skips actors with 0 coin; the skipped demand is visible in `outstanding_demand`. Option (c) is (b) plus the explicit remainder path. The distinction from (b): clearing transfers what coin allows (partial fills are possible), remainder goes to `outstanding_demand`, and a hunger-pressure signal can be emitted from `record_receipt()` when the fill is less than what was asked.

Concretely: `GrainInterest.place_grain_order()` queues the full `Q_d(expected_P)` — no coin check here. `RetailMarket.clear()` checks each demander's coin balance before transferring; partial transfers are honored; the unfilled quantity is left in `outstanding_demand` on the consumer's `GrainInterest`. This keeps `place_grain_order()` ignorant of wallet state, which is correct — the interest expresses need, the market resolves capacity.

---

## R3 — A calibration (per-actor or aggregate, which class owns)

**Position: A is per-actor, owned on GoodConfig. GrainInterest reads it; RetailMarket sums across demanders.**

Mary's analysis confirms: A_per_actor = 14 at P=1 with e_g=0.4 calibrates correctly against v0's 4-actor, 56-grain-per-week regime. The field lives on `GoodConfig` (or its v0 equivalent — a constants block in `RetailMarket` or a companion `GrainConfig` resource). `GrainInterest` does not own A directly; it holds `daily_demand` which is a stub. At clearing, `RetailMarket.compute_equilibrium_price()` sums Q_d across all demanders using the per-actor A from config. This means adding a fifth actor automatically scales aggregate demand — no config change required.

The per-actor multiplier (option iii in the brief) is the phase 3+ upgrade path: `GrainInterest` would carry a `demand_multiplier: float = 1.0` that GoodConfig's base A is scaled by. Name the field now, value stays 1.0.

---

## R4 — Period of Q_d (per-clearing or per-day-aggregated)

**Position: (b) Q_d is per-day; weekly aggregate = 7 × Σ_actors Q_d_per_day(P_m).**

This maps cleanly to `GrainInterest.daily_demand` already on the class. A is calibrated as a daily figure; at clearing, `RetailMarket.clear()` multiplies by 7 (days in clearing period). When retail goes more frequent in a later phase, that multiplier becomes a parameter. The alternative (A calibrated weekly from the start) embeds the 7-day period into the constant and makes it harder to change the clearing frequency later. Daily-A with explicit day-count multiplier is the seam-first choice.

---

## R5 — outstanding_demand carry-forward

**Position: (c) cap at this-week's preferred Q_d. Reset at each clearing.**

Mary's economic argument and the architectural argument converge here. Option (a) produces an ever-growing integer that makes traces hard to read and poisons phase 3+ hunger calibration (actors "owe themselves" grain from three months ago). Option (b) decay requires a new parameter (λ) with no v0 payoff. Option (d) couples R2 and R5 unnecessarily — affordability is already handled at clearing; outstanding_demand should capture *unmet need*, not *unaffordable need* specifically.

Option (c): at the start of each clearing, `GrainInterest.outstanding_demand` is capped to `Q_d(expected_P)` for this week. In practice: immediately before `RetailMarket.clear()` fires, or as part of `place_grain_order()`'s weekly reset logic, clamp `outstanding_demand = min(outstanding_demand, weekly_Q_d)`. Post-clearing, `record_receipt()` decrements normally. Whatever remains is this week's unmet need, readable as a hunger-pressure signal in phase 3+.

This interacts cleanly with R2-c: the clearing fills what coin allows; the remainder stays in `outstanding_demand` as genuine unmet need, capped to this period's demand so it doesn't compound into fiction.

---

## R6 — Merchant break-even floor

**Position: field lives on MercantileInterest, not RetailMarket. Default v0 = 0.0.**

`@export var min_retail_margin: float = 0.0` on `MercantileInterest`. The floor is a merchant policy, not a market rule — RetailMarket should not know what constitutes a loss for the merchant. At `compute_retail_price()` time (inside `MercantileInterest`), the merchant clamps: `P_m = max(wholesale_cost_per_unit * (1.0 + min_retail_margin), P_star * (1.0 + delta_retail))`. The market then clears at whatever `P_m` the merchant posts. If the author ever wants the market to impose a floor (regulatory price floor), that's a separate field on `RetailMarket` — the two are distinct concepts and should stay separate.

The seam exists. Value is 0.0. Mary's insolvency scenario at δ_retail = -0.1 is what the floor prevents; at 0.0 the merchant won't go negative by accident (since we're also clamping δ_retail ≥ 0 per R1).

---

## R7 — Single vs multi-merchant scope for v0

**Position: (a) single-merchant math plus strategy enum scaffold. Multi-merchant clearing deferred.**

There is one merchant in v0. Writing N-merchant supply-ladder logic now means writing code that is untestable in the 14-day trace and whose correctness can't be verified until phase 3+. The architectural debt of option (a) is: the clearing loop will need to be generalized later. That's real but bounded — the strategy enum is the seam, and the PROPORTIONAL strategy body can be written to handle N=1 trivially (all supply goes to the one merchant's pool). The N>1 branch is a named-but-unimplemented enum entry.

Enum: `enum ClearingStrategy { PROPORTIONAL, FIFO, SUPPLY_LADDER, MARKET_PERCEPTION_RANK, CHARISMA_RANK, BARTERING_RANK }`. v0 wires only PROPORTIONAL. The naming cost is zero; the implementation cost of the unimplemented branches is deferred.

---

## R8 — δ_wholesale calibration value

**Position: 0.0 for v0.**

Mary flags the double-marginalization risk: turning on δ_wholesale > 0 while δ_retail > 0 produces a multiplicative combined markup of `(1 + δ_w)(1 + δ_r)` — larger than intended. With δ_wholesale = 0.0, the retail math is isolated, the trace is readable, and coin conservation holds as confirmed in Section 1. The LandOwner self-consumption coin leak Mary identifies (1.4 coin/week at δ_retail = 0.1) is a slow drain that doesn't threaten the 14-day prototype but is the right thing to note in trace expectations for Section 2.

If the author wants a non-zero producer margin visible in v0, the correct lever is raising the initial endowment or adjusting the trace acceptance criteria, not turning on δ_wholesale before the retail regime is calibrated and stable.

---

## S1 — Q_d(P) function placement

**Position: method on GrainInterest; RetailMarket calls it per demander.**

```gdscript
# GrainInterest
func compute_demand_at_price(price: float, days_in_period: int) -> float:
    var a_per_actor: float = GoodConfig.GRAIN_A_PER_ACTOR  # or passed in
    return a_per_actor * pow(price, -GoodConfig.GRAIN_ELASTICITY) * float(days_in_period)
```

Each consumer computes their own Q_d. `RetailMarket.clear()` calls this on each demander in the demand pool and sums. This is option (ii) from the brief — smallest v0 footprint, and it co-locates the demand logic with the interest that owns the demand state. The phase 3+ upgrade to a `DemandCurve` resource (option iii) is achieved by moving the constants out of `GoodConfig` into a proper resource; the method signature on `GrainInterest` doesn't change.

---

## S2 — P* (equilibrium price) placement

**Confirm: `RetailMarket.compute_equilibrium_price(good_id: StringName) -> float`.**

```gdscript
# RetailMarket
func compute_equilibrium_price(good_id: StringName) -> float:
    var total_supply: float = _sum_supply_pool()
    if total_supply <= 0.0:
        return 0.0  # guard: Mary's Rec 3
    var a_total: float = _sum_actor_demand_at_price_1(good_id)
    var e_g: float = GoodConfig.elasticity_for(good_id)
    return pow(a_total / total_supply, 1.0 / e_g)
```

The market owns the equilibrium solve because it is the only place that sees aggregate supply and can sum across demanders. This is the right seam. The guard clause handles Q_s = 0.

---

## S3 — P_m (merchant markup) placement

**Position: per-merchant, method on MercantileInterest.**

```gdscript
# MercantileInterest
func compute_retail_price(p_star: float) -> float:
    var unclamped: float = p_star * (1.0 + delta_retail)
    var floor_price: float = wholesale_cost_per_unit * (1.0 + min_retail_margin)
    return max(floor_price, unclamped)
```

The per-merchant signature is what generalizes to N merchants. For v0 with one merchant, `RetailMarket.clear()` calls `mercantile_interest.compute_retail_price(p_star)` on the one merchant in its supply pool. The market does not own markup logic — it asks the merchant what price they'll post. Keeping markup on the merchant keeps the market generic and is consistent with how `WholesaleMarket` lets each producer own their own `compute_supplier_delta()`.

New fields needed on `MercantileInterest`:
```gdscript
@export var delta_retail: float = 0.1        # v0 starting value; adjust in calibration pass
@export var min_retail_margin: float = 0.0   # R6 seam
var wholesale_cost_per_unit: float = 0.0     # written by WholesaleMarket.clear() on grain receipt
```

---

## S4 — Strategy file structure

**Position: (c) strategy functions on RetailMarket, dispatched by enum. Same pattern as LaborMarket.**

```gdscript
# RetailMarket
enum ClearingStrategy { PROPORTIONAL, FIFO, SUPPLY_LADDER, MARKET_PERCEPTION_RANK, CHARISMA_RANK, BARTERING_RANK }
@export var clearing_strategy: ClearingStrategy = ClearingStrategy.PROPORTIONAL

func clear() -> void:
    match clearing_strategy:
        ClearingStrategy.PROPORTIONAL: _clear_proportional()
        ClearingStrategy.FIFO:         _clear_fifo()
        # phase 3+: SUPPLY_LADDER, MARKET_PERCEPTION_RANK, etc.
        _: push_error("RetailMarket: unimplemented clearing strategy %d" % clearing_strategy)

func _clear_proportional() -> void:
    # v0 body
    pass

func _clear_fifo() -> void:
    # stub — enum entry exists, body deferred
    pass
```

This is consistent with `LaborMarket.ClearingStrategy`. If the team ever decides a strategy needs private state (e.g., SUPPLY_LADDER needs a sorted stall list it maintains across ticks), that strategy can be extracted to its own object at that point. Until then, inline functions are flat, readable, and consistent with the pattern already locked in Section 1.

---

## Disagreements with Section 1 (if any)

One mild friction point, not a contradiction: Section 1 locked `send_inventory_to_retail` as the step where the merchant ships grain to `RetailMarket`'s supply pool. The current `MercantileInterest.send_inventory_to_retail()` calls `retail_market.queue_supply(owner, 0)` — the 0 is a placeholder. Section 2 must fill in the actual quantity: `owner.accounts.inventory.get(good_id, 0)`. That's not a conflict, just an open stub that the directive needs to close explicitly. Make sure the directive calls this out as a required edit to `MercantileInterest`, not just a new RetailMarket body.

Also: `MercantileInterest` needs to record `wholesale_cost_per_unit` after wholesale clearing so `compute_retail_price()` can enforce `min_retail_margin`. The `WholesaleMarket.clear()` currently does not write cost-per-unit back to the merchant. Section 2 needs to add this: after transferring grain, wholesale clearing writes `mercantile_interest.wholesale_cost_per_unit = clearing_price` on each merchant demander. This is a small but necessary seam.

---

## What I'd want to be sure of before the directive's Section 2 is drafted

The risk that bites hardest is `wholesale_cost_per_unit` not being available on `MercantileInterest` at the time `compute_retail_price()` runs. If that field is 0.0 at clearing time (because wholesale hasn't written it yet, or the merchant received partial fill and the per-unit cost is ambiguous), the `min_retail_margin` floor computes against zero and the guard does nothing. The burst order says wholesale clears before retail, so the write-back can happen cleanly in `WholesaleMarket.clear()` — but it must be in the directive explicitly, not left as an implied consequence. The second thing I want confirmed before drafting: the `A_per_actor` constant and `e_g` live somewhere concrete (even if it's just a constant block at the top of `RetailMarket.gd` for v0), not as magic numbers scattered across `compute_equilibrium_price()` and `compute_demand_at_price()`. Name the home before the directive is written; the coding agent needs one authoritative place to find those values.
