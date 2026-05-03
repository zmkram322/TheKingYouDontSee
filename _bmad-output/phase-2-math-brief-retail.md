---
name: Phase 2 Math — Retail Brief
status: brief-for-panel
date: 2026-05-03
panel: Cloud Dragonborn (Game Architect), Samus Shepard (Game Designer)
inputs_to_read:
  - _bmad-output/phase-2-math-directive.md  (Section 1 — wages + wholesale, locked)
  - _bmad-output/phase-2-math-observations.md  (original 10-question gap doc; retail context starts in "Walk through 14 days" and Q2/Q3/Q5)
  - _bmad-output/phase-2-architecture-directive.md  (architecture is locked — math drops into these shapes)
  - tkyds-game/scripts/markets/retail_market.gd  (current state — print-only stub; clearing math lands here)
  - tkyds-game/scripts/interests/grain_interest.gd  (queues retail demand daily; outstanding_demand accumulates)
  - tkyds-game/scripts/interests/mercantile_interest.gd  (queues retail supply at clearing; uses send_inventory_to_retail)
  - C:\Users\zachm\.claude\projects\Z--TheKingYouDontSee\memory\project_labor_strategy.md  (clearing strategy as regional/lordly hook — same pattern likely fits retail)
purpose: |
  Section 1 of the math directive (wages + wholesale) shipped 2026-05-02. Section 2
  closes out retail. The author has supplied raw retail notes — they propose an
  isoelastic demand curve, demand-driven equilibrium pricing, and a multi-merchant
  clearing-strategy enum. The notes are strong on the economic core but leave eight
  ambiguities that need positions before the directive can be written.

  The author has explicitly asked the panel to opine on ALL eight — not to wait for
  author elicitation to close half first. The panel's job is to pick which CLASS
  carries which RESPONSIBILITY (and what the function signature looks like). Concrete
  values, calibration constants, and even strategy implementations can be filled in
  later as long as the right seams land in the right place.
seam_first_directive: |
  Numbers can move. Strategies can be added. What matters now: function signatures,
  where state lives, which interest owns which decision, where computation fires.
  When in doubt, lean toward "name the seam, stub the body" over "pick the value."
out_of_scope:
  - Aptitudes / skills / XP system itself (phase 3+; only seams matter here)
  - Hunger system (phase 3+; only seams matter here)
  - Multi-region retail (phase 3+; v0 single global retail market)
---

# Brief for Cloud + Samus — Retail Math (Section 2)

## What's locked from Section 1 (don't relitigate)

These are settled. Work from them, don't re-argue.

### Burst order (re-stated for retail context)

```
Day 1 EARLY_MORNING burst:
  1. wages_due           (settle last week's payables)
  2. merchant_restock    (merchants queue wholesale demand)
  3. wholesale clear     (last week's producer grain → merchant)
  4. send_inventory_to_retail (merchants queue retail supply)
  5. retail clear        ← THIS SECTION'S TARGET
  6. labor_market clear  (this week's contracts written)
```

Wages settle BEFORE retail clears. Workers shop with last week's pay starting in week 2.

### Wholesale price formula (Section 1)

```
wholesale_price = cost_per_grain × (1 + δ_wholesale)
cost_per_grain = wages_paid / grain_produced       (other costs are 0 placeholders)
δ_wholesale = static `current_delta` field on ProductionInterest, v0 = 0.0
```

v0 wholesale price = 1.0 coin/grain at break-even. **WS2 (Section 1) deferred picking the actual δ_wholesale value to this round** — once retail prices are designed, panel should back-solve a defensible δ_wholesale.

### Section 1 v0 calibration (for context)

| Constant | Value |
|---|---|
| `MINIMUM_WAGE` | 1.0 coin/slot |
| `BASE_SKILL` | 2.0 |
| Workers | 2 |
| Days/week worked | 5 (days 1–7 minus weekends? actually 7) → 7 × 4 slots × 2 workers = 56 slots/week |
| Wages/week (v0 floor) | 56 coin |
| Grain/week | 56 grain |
| `wholesale_cost_basis` | 56/56 = 1.0 coin/grain |
| `Merchant.target_inventory` | 60 |
| `Merchant.max_wholesale_price` | 2.0 |
| `GrainInterest.daily_demand` | 2 grain/day |
| Retail consumers | 4 (LandOwner + Merchant + 2 workers) — all-flows-through-markets is locked |

### Self-consumption (WS5 — Section 1)

**All-flows-through-markets is locked for v0.** LandOwner + Merchant queue retail demand daily and (when retail clears) buy grain back. Section 2 should not reopen this — but it MAY surface a "private subtraction" flag for revisit when intermediate products land later.

### Settled seam decisions (Section 1, carried forward)

- `Payable.slots_worked: int` accumulates daily; `EmployerInterest.pay_outstanding_wages()` multiplies by current rate at settlement
- `accounts.skills: Dictionary = {}` exists; read with `.get(skill_name, 0.0 or 1.0)` defaults
- `compute_slot_output()` and `compute_daily_demand()` helpers exist in v0 (return constants); phase 3+ swaps bodies
- `clearing_strategy` enum on each market (RANDOM v0; phase 3+ adds CHARISMA, PRODUCTIVITY_RANK, etc.)

---

## What's locked from author's retail notes (don't relitigate either)

The author handed in retail notes 2026-05-03. These positions are settled by the notes:

### Demand functional form

```
Q_d(P) = A · P^(-e_g)
```

- Isoelastic — constant elasticity across the price range.
- Per-good elasticity `e_g` (config). Tiers: inelastic (e < 1, e.g. grain), normal (e ≈ 1), luxury (e > 1).
- Baseline demand `A` (calibration TBD — see R3).

### Demand-driven equilibrium price

```
P* = (A / Q_s)^(1 / e_g)
```

Solves `Q_d(P*) = Q_s`. This is the "market price before any merchant markup."

### Merchant markup

```
P_m = P* × (1 + δ_retail)
Q_p = min(Q_s, Q_d(P_m))      ← actual quantity purchased
```

Recompute Q_d at the marked-up price. Excess on one side is leftover.

### Multi-merchant clearing via strategy enum

Same shape as `LaborMarket.clearing_strategy`. Strategies on the table:
- PROPORTIONAL — each demander gets `Q_p × (my_demand / total_demand)`
- FIFO — order of demand arrival
- MARKET_PERCEPTION_RANK — XP-based skill ("I notice the cheapest stall first")
- CHARISMA_RANK / BARTERING_RANK — stat-based ("merchant likes me" or "I haggle")
- *plus the supply-ladder × consumer-rank multi-merchant strategy the author sketched*

The strategy enum is **the seam**. Specific strategies can be added later. Author wants Samus's lead on the charisma/bartering vocabulary.

---

## Open questions for the panel

The author has asked you to opine on ALL of these. Pick positions. Justify briefly. Where you disagree with each other, the author adjudicates after.

### R1 — Where does rationing actually arise?

With δ_retail ≥ 0 and isoelastic demand, P_m ≥ P* always implies Q_d(P_m) ≤ Q_s — the merchant always has leftover inventory at single-merchant. So "rationing" only happens via:

- (a) **δ_retail < 0** — the merchant prices below equilibrium. Why would they? (Liquidation? Spoilage pressure? Loss leader? Phase 3+ behavior?)
- (b) **Multi-merchant supply split** — different merchants at different P_m. Cheap merchant runs out before expensive merchant; consumers ration to the cheap stalls first.
- (c) **Affordability rationing** — consumers want grain at P_m but can't pay. Demand is expressed but unpurchaseable. (See R2.)

Do we model (a) at all in v0? If not, can δ_retail be defined as `max(0, …)` or strictly non-negative? If yes, what drives a merchant to mark down?

**Cloud** — speak to whether the math model handles rationing cleanly when it can come from any of (a), (b), (c) simultaneously, or whether v0 should constrain to one source. **Samus** — speak to whether merchant markdowns should ever exist in v0 from a player-readable-trace standpoint.

### R2 — Affordability: where does coin enter the demand expression?

`Q_d(P) = A · P^(-e_g)` is preference-only. It doesn't see wallets. Three places coin can enter:

- **(a) At demand expression.** `GrainInterest.place_grain_order()` queues `min(Q_d(expected_P), coin / expected_P)`. Workers with 0 coin queue 0 demand. The market never sees their hunger.
- **(b) At clearing.** Demand expressed raw (full Q_d). Clearing skips demanders who can't pay. Their `outstanding_demand` carries forward (see R5).
- **(c) Hybrid.** Express raw need. Clearing transfers what coin allows. Remainder goes to `outstanding_demand` and (later phases) emits a hunger-pressure signal.

(a) is economically pure. (b) preserves "the world sees what actors want." (c) is where phase-3 hunger plugs in cleanly.

**Cloud** — which is most stable as hunger / subsistence floor systems land later? **Samus** — which produces the most legible trace ("workers wanted grain, couldn't pay, went hungry" vs "workers didn't even ask")?

### R3 — `A` calibration (per-actor or aggregate? at what reference price?)

`A` is the baseline demand parameter. To make the formula concrete:

- Is `A` per-actor or aggregate?
- At what reference price does Q_d = A? (`P = 1`?)
- How does `A` connect to the existing `GrainInterest.daily_demand = 2`? My read: A_per_actor at P=1 with e_g=1 gives Q_d = A grain. To match v0's daily_demand = 2 weekly aggregated to 14, A_per_actor_weekly ≈ 14, A_total (4 actors) ≈ 56. Confirm or correct.

**Cloud** — which class owns `A`? Three candidates:
- (i) Per-actor on `GrainInterest` (each consumer carries their own baseline)
- (ii) Per-good in a `GoodConfig` resource (`grain.A_per_actor = 14`, market multiplies by demander count)
- (iii) Hybrid — base on GoodConfig, per-actor multiplier on GrainInterest

(iii) is the obvious phase-3-friendly answer (different actors have different appetites). But (ii) gets v0 to a clean trace fastest. **Samus** — do per-actor appetite differences matter for v0 trace legibility?

### R4 — Period of Q_d

Retail clears weekly. Q_d as written has no time dimension. Two readings:

- **(a) Q_d is per-clearing.** `A` is calibrated to the weekly aggregate. `daily_demand` is a per-day stub that aggregates to A at clearing time.
- **(b) Q_d is per-day, multiplied by 7 at clearing.** `A` is daily; `Q_d_total_weekly = 7 × Σ_actors Q_d_per_day(P_m)`.

Cloud — which is cleaner architecturally? Samus — does either one foreclose phase-3 work (e.g., consumers buying mid-week if retail goes more frequent)?

### R5 — Q3 (outstanding_demand carry-forward) — the long-deferred question

`GrainInterest.outstanding_demand: int` accumulates daily, decrements only on `record_receipt()`. In Phase 1 it grows monotonically because retail doesn't clear. After this section it'll decrement, but:

- **(a) Carry forever.** Workers locked out for 5 weeks owe themselves 70 grain when paid. Pressure builds.
- **(b) Decay.** `outstanding_demand × (1 − λ)` per week. Old unmet demand fades — actor "gave up" on missed weeks.
- **(c) Cap at this-week's preferred Q_d.** Reset (or capped) at start of each clearing period. Each week is a fresh demand statement.
- **(d) Cap at coin / expected_price.** Demand can't exceed what you can afford to buy. Rolls R2 and R5 together.

Tied to R2 — if R2 = (a), outstanding_demand barely grows because consumers don't queue what they can't afford.

**Both panelists weigh in.** Decay rate, carry semantics, and "where does hunger pressure live in the data" all live here.

### R6 — Merchant break-even floor

`P_m = P* × (1 + δ_retail)` is demand-driven. If `A` is small relative to `Q_s`, P* is low and P_m may sit below `wholesale_cost_per_grain`. Merchant takes a loss.

Mirror of Section 1's `Merchant.max_wholesale_price` ceiling — but inverted. Should there be:

- **`Merchant.min_retail_margin: float`** — refuse to sell below `wholesale_cost × (1 + min_margin)`. Carry inventory across weeks until pricing supports it.
- **No floor.** Merchant always clears at P_m even at loss. Coin drains; merchant goes bankrupt eventually (a *signal*, not a bug).
- **Soft floor via δ_retail dynamic.** Phase 3+ — merchant adjusts δ_retail upward when margins compress.

For v0: name the field on MercantileInterest. Even if the value is `0.0` (no floor), the seam exists.

**Cloud** — which class owns the floor decision (Merchant or Market)? **Samus** — is "merchant goes bankrupt because demand is too soft" a story we want to surface in v0 trace?

### R7 — Single vs multi-merchant scope for v0

v0 has 1 merchant. Multi-merchant strategies (the supply-ladder + consumer-rank machinery, charisma/bartering, market perception) are real and exciting but won't fire in v0.

- **(a) Single-merchant math + strategy enum scaffold.** Implement clearing for N=1 case. Enum lives but only one strategy (RANDOM or PROPORTIONAL) is wired. Multi-merchant clearing logic deferred to Section 3 or phase 3+.
- **(b) Full multi-merchant clearing in Section 2.** Implement N-merchant supply-ladder logic now. Author sketched the basic shape; v0 trace just won't exercise it.

(a) ships faster and lets v0 trace land clean. (b) front-loads work that won't be visible until phase 3.

**Cloud** — which has lower architectural debt? **Samus** — does the Section 2 trace need multi-merchant to feel right, or does single-merchant carry the demonstration?

### R8 — Land δ_wholesale calibration value (Section 1's WS2)

Section 1 deferred picking the actual δ_wholesale value because it depends on retail design. Now we can land it.

With v0 cost = 1.0 and retail-side numbers in flight:
- δ_wholesale = 0.0 → producer earns no margin, only covers labor cost. Sustainable but boring.
- δ_wholesale = 0.1 → wholesale price 1.1, producer earns ~10% over cost.
- δ_wholesale = 0.25 → wholesale price 1.25.

Pick a number, **OR** declare that v0 ships with `δ_wholesale = 0.0` and δ becomes interesting in phase 3+ when producer profit-pressure logic exists.

**Cloud** — does picking δ_wholesale > 0 introduce coin leakage that breaks conservation, or does the LandOwner's retail self-consumption close the loop? **Samus** — does a non-zero producer margin matter for v0 trace?

---

## Cross-cutting seam questions (please address even if briefly)

### S1 — Where does Q_d(P) live as a function?

Candidates:
- (i) Static method on `RetailMarket` — market computes equilibrium and asks each demander for their `A_per_actor`
- (ii) Method on `GrainInterest` — each consumer computes their own `Q_d(P)` given their elasticity
- (iii) Pure function on a `DemandCurve` resource attached to `GoodConfig` — consumer asks "what's my Q_d at this P," resource returns

(iii) is the canonical phase-3-friendly shape. (ii) is the smallest v0 footprint. (i) couples market to actor internals.

### S2 — Where does P* (equilibrium price) get computed?

Almost certainly `RetailMarket.compute_equilibrium_price()`. Confirm — or argue otherwise.

### S3 — Where does P_m (merchant markup) get computed?

Candidates:
- `MercantileInterest.compute_retail_markup(P_star) -> float` (per-merchant)
- `RetailMarket.compute_merchant_price(merchant, P_star) -> float`

Per-merchant markup is the multi-merchant case (R7). For v0 single-merchant, both shapes are equivalent — but the per-merchant signature is what scales.

### S4 — Where do strategies live (file structure)?

- (a) Inline in `RetailMarket.clear()` as a `match` block, like Section 1 labor matching
- (b) One file per strategy (`scripts/markets/strategies/proportional.gd`, etc.)
- (c) Strategy *functions* on `RetailMarket` itself, dispatched by enum

Cloud — call it. Same answer should probably propagate back to LaborMarket if we want consistency.

---

## What I want from each of you

A short position paper (under 700 words) addressing **R1, R2, R5, R6, R7** at minimum (these are the load-bearing decisions). Touch R3, R4, R8 if you have a strong take. Then weigh in on **S1, S2, S3, S4** — these are pure architectural seam questions and Cloud is the natural lead, but Samus should flag if any seam choice would foreclose a design move you care about.

Format: one bullet per question with **position chosen + 1–2 sentence rationale**. Flag any disagreement you see with Section 1's locked decisions (don't relitigate, but if you spot a genuine conflict, surface it). End with one paragraph: **"what I'd want to be sure of before the math directive's Section 2 is drafted."**

After both papers land, the author adjudicates. Round 2 only on points where you disagree load-bearingly.

**Reminder:** the seam matters more than the value. If you're 70% sure on a strategy choice, name the *enum entry* and let the body be a stub. The next coding pass fills bodies; the directive locks shapes.
