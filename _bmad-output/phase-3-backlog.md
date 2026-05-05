---
name: Phase 3+ Backlog
status: running-list
date_started: 2026-05-03
purpose: |
  Items deferred from Phase 2 directive scope that should be revisited later.
  Each entry: what it is, why it was deferred, where the seam lives in v0 code,
  and what triggers the revisit. This is the canonical "what we're punting on
  and intend to return to" doc — not a wish list, not aspirational design.
---

# Phase 3+ Backlog

Each item lists:
- **What:** the deferred concern
- **Why deferred:** what made it phase-3+ scope
- **Seam:** where v0 leaves the hook
- **Trigger:** what session / event surfaces it for revisit

---

## Economy — markets & pricing

### Private subtraction (self-consumption shortcut)

**What:** When a producer or merchant consumes their own goods, the v0 model routes everything through markets — LandOwner ships ALL grain to wholesale, then buys some back from retail to feed self. Cleaner economic model but produces a trace where actors pay themselves; reads silly to a new viewer (Samus's concern, Section 1).

**Why deferred:** With v0's single good (grain), the round-trip overhead is small and the all-flows-through-markets property is load-bearing for trace integrity. The case for "private subtraction" gets stronger when intermediate products land (LandOwner produces grain, Baker turns it into bread — does the Baker subtract their own bread before sending to retail, or buy it back?).

**Seam:** None in v0. WS5 (Section 1) explicitly locked all-flows-through-markets without a subtraction path.

**Trigger:** When intermediate-products design begins (Baker + bread, or any chained production). At that point, design a `private_consumption: int` field on `ProductionInterest` that subtracts from output before market shipment, with corresponding accounting on the consuming Interest.

---

### Multi-merchant clearing strategies (bodies)

**What:** `RetailMarket.ClearingStrategy` enum entries `SUPPLY_LADDER`, `MARKET_PERCEPTION`, `CHARISMA_FAVOR`, `BARTERING` are named in v0 but only `PROPORTIONAL` and `FIFO` have working bodies. Multi-merchant rationing logic (cheap-merchant-first, perception-based search, charisma-driven priority, bartering-driven price discount) is unimplemented.

**Why deferred:** v0 has one merchant by design. Writing N-merchant logic now produces untestable code.

**Seam:** Enum entries exist with stub bodies. Function-on-market dispatch pattern matches `LaborMarket`. Strategy bodies read `actor.accounts.skills` for the relevant skill (`market_perception`, `charisma`, `bartering`) — reads default to 0.0 today, populated when XP/skills land.

**Trigger:** Second merchant arrives in the world OR when phase-3 skills/XP land and the design wants player-visible character differentiation in market access.

---

### Per-actor demand multiplier

**What:** Today every actor has the same baseline demand for grain (uniform `A_per_actor_daily`). Phase 3+ may want a `demand_multiplier: float = 1.0` on `GrainInterest` so big-eaters and small-eaters become distinguishable in trace.

**Why deferred:** v0 actors are archetypes (LandOwner, Merchant, Worker), not characters. Per-actor variation is character-layer signal, not class-layer signal.

**Seam:** `compute_demand_at_price()` reads from `Goods.config_for(&"grain").a_per_actor_daily` directly. Phase 3+ multiplier is one extra read: `cfg.a_per_actor_daily * demand_multiplier`.

**Trigger:** When named actors with personality data land (likely with aptitudes pass) OR when player-visible "this actor eats more" needs to surface.

---

### Multi-producer wholesale cost aggregation

**What:** `WholesaleMarket.clear()` in v0 (with Section 2's amendment) writes a single `wholesale_cost_per_unit` to the merchant. With multiple producers, each producer has a different cost basis; merchant's effective cost is a weighted average across what they bought from each.

**Why deferred:** v0 has one producer.

**Seam:** Section 2's amendment to `WholesaleMarket.clear()` writes `merchant_interest.wholesale_cost_per_unit = price`. Phase 3+ replaces with weighted-average computation across the per-producer subtransfers in the same clearing.

**Trigger:** Second producer arrives.

---

### Dynamic δ_retail (inertia / pressure / smoothing)

**What:** Today merchant `delta_retail: float = 0.1` is static. Phase 3+ would compute it from observed margin pressure, inventory state, competitive positioning, etc. — same shape as the dynamic δ_wholesale Section 1 deferred for producers.

**Why deferred:** Static value lets v0 calibrate retail prices without learning logic. Designing the smoother now would risk naming wrong fields (Samus's WS6 concern from Section 1, applies symmetrically).

**Seam:** `MercantileInterest.delta_retail` field exists. `compute_retail_price()` reads it directly. Phase 3+ adds a `compute_retail_delta()` method that returns dynamic value; the field stays as the latest-computed cache.

**Trigger:** When merchant-learning logic is designed (likely after multi-merchant arrives and competition becomes meaningful).

---

### Dynamic δ_wholesale + multiplicative-markup documentation

**What:** Section 1's WS2 deferred picking δ_wholesale; Section 2 locked it at 0.0 to avoid double-marginalization. When δ_wholesale > 0 lands, combined markup is multiplicative `(1 + δ_w)(1 + δ_r)`, NOT additive. This needs to be documented and the trace expectations updated.

**Why deferred:** v0 isolates retail margin as the only margin in the trace.

**Seam:** `ProductionInterest.current_delta` field exists, currently 0.0. `compute_supplier_delta()` returns it directly. Phase 3+ reads inertia/pressure state.

**Trigger:** When producer-learning logic is designed OR when the trace needs to show producer margin (e.g., to demonstrate "lord squeezes producer's margin" gameplay scenario).

---

### Negative δ_retail (markdown / liquidation)

**What:** v0 clamps `δ_retail ≥ 0` (no markdowns). "Merchant slashes prices to clear inventory" requires a merchant smart enough to recognize their position — phase 3+ behavior.

**Why deferred:** No spoilage / loss-leader / inventory-pressure mechanics in v0. Markdowns would have no driving cause.

**Seam:** The `max(0.0, delta_retail)` clamp in `compute_retail_price()`. Removing the clamp + adding markdown logic = phase 3+ change.

**Trigger:** When inventory-aging / spoilage / merchant-strategy mechanics land.

---

### Merchant inventory aging / spoilage

**What:** Today leftover grain stays with the merchant indefinitely. No spoilage, no insurance, no merchant decision to discard. Mary's recommendation 9 also flagged this.

**Why deferred:** Adds another mechanic to a v0 already running long; not load-bearing for the math demonstration.

**Seam:** None in v0 — leftover just sits in `merchant.accounts.inventory[good_id]`. Phase 3+ would add an aging tally per stack OR a daily decay tick on inventory.

**Trigger:** When first food spoilage scenario is needed for narrative (likely tied to hunger or famine cascade work).

---

### Monopoly markup property (documentation)

**What:** With grain at e_g=0.4 (inelastic), profit-maximizing markup for a monopoly merchant is unbounded except by affordability. Mary flagged this in her Section 4. Not a v0 concern (δ_retail is hand-set, not optimized), but should be documented when dynamic δ_retail lands.

**Why deferred:** No phase 3+ dynamic merchant-strategy logic yet.

**Seam:** None needed in v0.

**Trigger:** When dynamic δ_retail logic is designed.

---

## Tooling

### Market tuning scene (live slider sim)

Already tracked in project memory `project_market_tuning_tool.md`. Build after Phase 2 implementation stabilizes; before aptitudes/hunger add more parameters to tune.

---

## Architecture (regional, multi-region)

### Regional `LaborMarket` (multi-region)

**What:** v0 has a single global `LaborMarket`. Phase 3+ has per-region markets with regional supply counts driving wage scarcity.

**Seam:** Section 1's `LaborMarket.supply_for_scarcity()` returns hardcoded 2 in v0; phase 3+ swap is one method body. `S_0` baseline derived from regional capacity.

**Trigger:** When second region exists in the world.

---

### Employer-learning logic

**What:** Phase 3+ employers reason about wage gradients, learn over time. If/when this lands, revisit Section 1's `MINIMUM_WAGE` floor (W1) — the floor was chosen partly because no employer-learning exists yet to make a smooth-formula version necessary (Cloud's preference at W1).

**Seam:** `WageCalculator.calculate_wage_per_slot()` is stateless. Employer learning would wrap or shadow it.

**Trigger:** When employer-strategy / behavior session begins.

---

### Wage-policy: recomputed-at-settlement

**What:** v0 locks `LaborContractActivity.wage_policy = LOCKED_AT_CONTRACT` — the wage rate is computed at strike-time using current scarcity and the worker's then-skill, and never revisited for the contract's life. A worker who grows skills mid-contract is paid at the strike-time rate. This is a deliberate design choice: it makes contracts a real tradable object and surfaces labor arbitrage as a dynamic.

**Why deferred:** v0 keeps the policy single-valued so the trace is unambiguous about wage flow. Phase 3+ may want a sibling `RECOMPUTED_AT_SETTLEMENT` policy that re-reads the rate at each `WagePaymentActivity`, for negotiated contracts (e.g., guild apprenticeships) or short-term seasonal labor.

**Seam:** `WagePolicy` enum on `LaborContractActivity`. Match dispatch in `on_close()` already gates which branch runs. Adding a sibling = one enum entry + one match arm + (likely) deferring contract field initialization until first WagePaymentActivity reads.

**Trigger:** When a non-locked wage scenario is designed (e.g., apprenticeship rate-step on skill threshold, or seasonal renegotiation).

---

## How to use this file

When a new phase-3+ session starts, read this file's relevant section first. Each item has the trigger that should bring it in. Don't pull items in early — the seams exist exactly so the items can wait without architectural debt.

When a phase-3+ item is implemented, **delete the entry from this file** and update the relevant directive / project memory to reflect the new state.
