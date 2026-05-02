# The King You Don't See — Simulation Prototype Spec

**Status:** Pre-implementation reference. This document defines the minimum viable prototype for proving emergence before any additional systems are built.

**Governing rule:** Load the game, walk away for five minutes, come back, and the world has moved. When that is true — proceed.

---

## Actor Set (3 actors)

| Actor | Role | Needs |
|---|---|---|
| Farmer / Worker | Produces grain, earns wages, buys food | Food (Tier 1), Coin (wages) |
| Merchant | Buys grain at farm gate, sells to consumers | Food (Tier 1), Profit margin |
| Lord | Collects flat tax on transactions | N/A (abstracted in prototype — rate float only) |

The player is a fourth actor running on the same system as the Farmer/Worker.

---

## Resource Set (1 resource + 1 exchange medium)

- **Grain** — the single produced resource. One resource per plot of land.
- **Coin** — universal exchange medium. Enables the circular flow.

No other resources in prototype. Second resources added only after emergence is proven.

---

## Production Model

```
Output = A · g(t) · ∏(p(s))

A       = land area (scalar)
g(t)    = base yield function (time-dependent, deterministic or seeded random)
∏(p(s)) = product of all productivity factors

Worker productivity:
  p(w) = min(Σ p_i(workers), 1)
  NOTE: This is a CAP (min), not a floor (max). Confirm before implementing.
  Overstaffing adds nothing. If p(w) = 0 (no workers or active strike) → output = 0.

Other modifiers:
  Weather, tools, morale — each a multiplier in the product set.
  Prototype: implement weather as a simple seasonal modifier, defer tools and morale.
```

**Worker state (daily cycle):**
- Needs food to maintain productivity
- Needs sleep (rest metric) to maintain productivity
- Deprivation → productivity debuff accumulates
- Hunger + morale below threshold → **hunger strike** (productivity = 0, all workers on plot)

---

## Market Model (weekly cadence)

**Week end sequence:**
1. Grain output transported to market (disruption check — can be intercepted)
2. Merchant evaluates purchase: buy if `(expected_sale_price − farm_gate_price − lord_tax) ≥ target_margin`
3. If merchant buys: grain enters merchant inventory, coin transfers to landowner
4. Market day: all buyers transact simultaneously
5. Price clears: aggregate demand curve vs. supply
6. Lord tax extracted as flat rate on each transaction (coin exits circulation)
7. Workers purchase food from merchant at cleared price

**Price clearing (simple mechanism):**
- If supply ≥ total demand at current price → price drops
- If supply < total demand → price rises (buyers with lowest budget priced out first)
- Iterate until clearing or floor/ceiling hit

**Multi-market (minimal):**
- At least 2 markets with independent supply/demand
- Consumers travel if: `(price_local − price_nonlocal) × quantity_needed > travel_cost`
- Travel cost = time (1 day productivity lost) + flat road risk modifier
- Actors at subsistence cannot afford travel time (trapped in local market)

---

## Demand Model

```
Per actor, per week:
  Q_demanded = min(preferred_quantity, budget_remaining / price)
  
  budget_remaining = weekly_wage − other_fixed_costs
  
  If Q_demanded ≥ minimum_quantity → need satisfied
  If Q_demanded < minimum_quantity → need_deficit accumulates
  
  Need deficit accumulation → productivity debuff (daily)
  Debuff threshold crossed → hunger strike trigger
```

**Budget priority:** Tier 1 needs (food) get first claim on available coin. Coin spent on food before any Tier 2 expenditure.

---

## Five Emergence Validation Targets

The prototype must demonstrate these behaviors naturally (not triggered by developer input) before any additional systems are built:

1. **Famine cascade** — bad harvest → supply drop → price rise → workers priced out → hunger debuff → productivity loss → smaller next harvest → price rises further → spiral
2. **Labor drain** — wage differential between farms causes worker contract migration, collapsing supply at origin farms
3. **Merchant margin capture** — merchant protecting profit margin during scarcity converts supply shortage into artificial price spike independent of actual production collapse
4. **Hunger strike contagion** — one farm's strike reduces regional supply, raising prices at neighboring farms and triggering further strikes
5. **Black market emergence** — when official market prices exceed affordable thresholds, shadow transactions emerge (prototype: trigger at night cycle, no formal market structure needed)

**Emergence is proven when:** A playtester observing the simulation (not playing) can describe a causal chain they weren't told about.

---

## Prototype Architecture Constraints

- **Dual-clock must be first-class from day one.** Burn-in requires headless simulation decoupled from rendering. If both clocks share a tick, burn-in cannot run at accelerated rate. Implement dual-clock before implementing anything else.
- **Burn-in phase:** Run simulation at regional fidelity (aggregate floats, not full actor sim) for N ticks before scene load. Target: stable equilibrium across 90%+ of test seeds.
- **Burn-in failure modes to guard against:**
  - Runaway accumulation (one actor monopolizes a resource before player arrival) — add stability threshold check
  - Oscillation without damping (supply/demand chase each other) — use moving averages for price memory, not spot-price reactive logic
- **Burn-in monitoring:** Log simulation state at regular intervals during burn-in (not just final snapshot). This is required to diagnose instability — a stable final state and a chaotic state that happened to land somewhere reasonable are indistinguishable without mid-run observability.

---

## Prototype Success Criteria

1. All five emergence behaviors observable in unsupervised simulation run
2. Famine cascade traceable end-to-end in simulation logs
3. 90%+ of world seeds produce a stable (non-degenerate) burn-in equilibrium
4. Circular flow (grain → coin → food → productivity → grain) completes at least 4 weekly cycles without developer intervention
5. At least one multi-market arbitrage event occurs in a 10-cycle run

**Not required for prototype:**
- Art, audio, or animation of any kind
- Player character or active input
- Combat system
- Management UI
- Any resource beyond grain + coin
