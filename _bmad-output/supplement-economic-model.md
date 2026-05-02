# The King You Don't See — Economic Model Reference

**Status:** Developer reference. Prototype-scope only. Full economy built incrementally after emergence is proven. Do not implement beyond this spec until the prototype validation targets are met.

---

## Production Model

```
Output = A · g(t) · ∏(p(s))
```

| Variable | Definition |
|---|---|
| `A` | Land area (scalar, set at land generation) |
| `g(t)` | Base resource generating function — time-dependent. Can be seasonal (sinusoidal), event-driven (bad weather), or seeded deterministic. |
| `∏(p(s))` | Product of all productivity factors in the set p(s) |

**Worker productivity factor:**
```
p(w) = min(Σ p_i(workers), 1)
```
- Capped at 1 — overstaffing yields no additional output
- If no workers assigned: p(w) = 0 → total output = 0
- ⚠️ IMPLEMENTATION NOTE: This is `min()`, not `max()`. Original design notes had a typo. Confirm before implementing.

**Other productivity factors (prototype):**
- Weather modifier: simple seasonal scalar (e.g., 0.6 in winter, 1.2 in summer)
- Morale modifier: deferred to post-prototype

**If any factor in p(s) = 0 → total output = 0** (e.g., active hunger strike wipes all worker productivity)

---

## Worker State Model (Daily Cycle)

```
productivity_modifier = base_productivity × hunger_modifier × rest_modifier × morale_modifier

hunger_modifier:
  fully_fed    → 1.0
  underfed     → linear decay over days without sufficient food
  starving     → 0.0

rest_modifier:
  rested       → 1.0
  tired        → linear decay
  exhausted    → 0.0 (also triggers other debuffs)

Hunger strike trigger:
  IF hunger_modifier < hunger_threshold AND morale_modifier < morale_threshold
  THEN worker enters strike (productivity = 0, contract technically active but output nil)
  Strike ends when: hunger needs met AND morale recovers above threshold
```

**Worker experience:**
- Workers gain exp from working a plot
- Exp improves base_productivity up to a cap (to be tuned per archetype)
- This creates incentive for landowners to maintain stable workforce (invested workers are more productive)

---

## Demand Model

```
Per actor, per market day:
  budget_remaining = weekly_wage − fixed_obligations
  Q_demanded       = min(preferred_quantity, budget_remaining / market_price)
  
  IF Q_demanded ≥ minimum_quantity  → need satisfied, no debuff
  IF Q_demanded < minimum_quantity  → need_deficit += (minimum_quantity − Q_demanded)
  
  need_deficit threshold reached → productivity debuff applied
  need_deficit critical threshold → hunger strike trigger
```

**Budget priority (in order):**
1. Tier 1 needs (food) — mandatory spend, paid first
2. Tier 2 needs — only if Tier 1 satisfied and budget remains
3. Tier 3 — deferred to post-prototype

**Preferred vs minimum quantities:**
- `minimum_quantity`: subsistence floor. Actor debuffs if not met.
- `preferred_quantity`: comfortable level. Morale boost if met consistently (post-prototype).
- Prototype: implement minimum only. Preferred quantity tuned after emergence proven.

---

## Market Clearing Mechanism (Weekly)

**Step 1 — Aggregate demand:**
Sum all actors' Q_demanded at each candidate price → demand curve

**Step 2 — Compare to supply:**
Total merchant inventory available for sale = supply

**Step 3 — Clear:**
```
IF supply ≥ total_demand_at_current_price:
  price decreases (to floor or until supply = demand)
ELSE:
  price increases (until demand drops to match supply)
  actors with lowest budget_remaining are priced out first
```

**Simple implementation (prototype):** Single-iteration binary search between price floor and ceiling. Sufficient to demonstrate emergence. Do not over-engineer price clearing before emergence is validated.

---

## Merchant Decision Model

The merchant is a simulated actor with its own state, not an abstracted clearing function.

**Buying decision (farm gate):**
```
Buy if:
  (expected_sale_price − farm_gate_offer − lord_tax_rate × farm_gate_offer) ≥ target_margin
  
  expected_sale_price: merchant's estimate based on recent market prices (moving average)
  farm_gate_offer:     price landowner is willing to accept
  target_margin:       merchant's minimum acceptable profit rate (tunable per archetype)
```

**Selling decision (market day):**
- Merchant sets ask price based on current supply vs. estimated aggregate demand
- If supply > demand → lower ask
- If supply < demand → raise ask (up to ceiling)
- Merchant's ask is the supply input to market clearing

**Merchant basic needs:**
- Merchant has own food requirements (satisfies from own inventory at cost, or purchases from another market)
- Merchant coin must cover own needs + operational costs or merchant starts hoarding supply

**Key behavior:** Supply the merchant won't buy at unprofitable prices never reaches the market. Merchant margin behavior is the mechanism that converts farm-gate pressure into consumer price spikes.

---

## Lord Tax Model (Prototype)

```
tax_collected = transaction_value × lord_tax_rate

Applied to:
  - Every market transaction within the lord's domain
  - Coin exits circulation (lord holds it)
  
Lord's tax rate: flat, set at world generation, does not change in prototype.
Lord AI: none in prototype. Rate float only.
```

**Structural tension (emergent, not scripted):**
Above a threshold tax rate: prices rise → workers priced out → production drops → fewer transactions → lord collects less despite higher rate. Self-defeating. This behavior must emerge from the model — do not author it.

---

## Circular Flow (Prototype)

```
[Land] → grain output → [Market]
                            ↓
                    Merchant buys (coin to Landowner)
                            ↓
                    Merchant sells on Market Day (coin to Merchant)
                            ↓
                    Workers buy food (coin from Worker budget)
                            ↓
                    Food → Hunger satisfied → Productivity maintained
                            ↓
                    Workers labor → [Land] → grain output → [Market]
                    
Lord tax extracted at each transaction → coin exits circular flow
```

**Prototype leakage points (coin sinks):**
- Lord tax (primary)
- Worker food purchases when production is insufficient (workers spend coin on food that wasn't locally produced — coin leaves to another market)

**Prototype injection points (coin sources):**
- Player sells labor or goods
- Starting coin seeded at world generation

---

## Multi-Market Dynamics

**Travel decision:**
```
Travel to non-local market IF:
  (price_local − price_nonlocal) × quantity_needed > travel_cost
  
travel_cost = time_cost + road_risk_cost + coin_cost
time_cost   = days_travel × daily_productivity_value (opportunity cost)
road_risk   = crime_score × risk_multiplier (configurable)
coin_cost   = transport_fee (flat per trip)
```

**Stratification effect (emergent):**
- Subsistence actors: cannot afford time_cost → trapped in local market
- Higher-income actors: surplus budget → can and will arbitrage
- This produces natural inequality: poor actors absorb bad local conditions, wealthy actors escape them
- Political instability emerges from this stratification without authorship

---

## Prototype Economic Scope

**In prototype:**
- Grain (one produced resource)
- Coin (exchange medium)
- Workers, landowners, merchants, lords (abstracted)
- Weekly market cadence
- Two markets minimum (to demonstrate multi-market dynamics)
- Simple price clearing (binary search)
- Merchant as simulated actor
- Lord as flat tax rate

**Explicitly deferred:**
- Non-food resources (tools, wood, luxury goods)
- Full demand curves for Tier 2/3 needs
- Wartime vs. peacetime economic dynamics
- Enterprise-level resource flows
- Trade route infrastructure
- Currency inflation mechanics
- Full lord AI (budget-pressure responses)

**Rule:** Do not expand economic scope until the five emergence validation targets are met with the prototype model.
