---
name: Phase 2 Math — Wages + Wholesale Brief
status: brief-for-panel
date: 2026-05-02
panel: Cloud Dragonborn (Game Architect), Samus Shepard (Game Designer)
inputs_to_read:
  - _bmad-output/phase-2-math-observations.md  (full context, 10 open questions, 14-day walk)
  - _bmad-output/phase-2-architecture-directive.md  (architecture is locked — math drops into these shapes)
  - tkyds-game/scripts/  (post-refactor code: where math lands)
  - C:\Users\zachm\.claude\projects\Z--TheKingYouDontSee\memory\project_labor_strategy.md  (labor clearing strategy = regional/lordly hook)
purpose: |
  Author has run elicitation and locked positions on roughly half the open questions.
  The remaining open questions need a position from the panel before the math
  directive can be drafted. This brief restates the locked positions for context,
  then poses the open questions explicitly. Retail is held for a separate round.
out_of_scope:
  - Retail clearing math (separate round; see "retail-deferred attributes" section)
  - Aptitudes / skills / XP system itself (phase 3+; only seams matter here)
  - Hunger system (phase 3+; only seams matter here)
---

# Brief for Cloud + Samus — Wages & Wholesale Math

## What's locked (don't relitigate)

These positions are settled from author elicitation. Don't argue them — work from them.

### Timing & sequencing

- **Q1 (day-1 startup):** Accept the lag. Week 1's day-1 morning burst is mostly empty (no payables, no grain, no inventory). World populates during days 1–7. Week 2 onward is the first "real" burst.
- **Burst timing:** Weekly burst fires at **day 1 EARLY_MORNING**, not day 7 EARLY_MORNING. Empty-bucket guard clauses print "nothing to clear" and move on.
- **Burst order (locked):**
  ```
  Day 1 EARLY_MORNING burst:
    1. wages_due           (settle last week's payables)
    2. wholesale clear     (last week's producer grain → merchant)
    3. retail clear        (last week's merchant inventory → consumers)
    4. labor market clear  (this week's contracts written)
  ```
  This order also resolves Q4 — wages settle BEFORE retail, so workers shop with last week's pay starting in week 2.

### Wage formula

```
wage = skill_value × scarcity_multiplier

skill_value = base_skill × (1 − e^(−XP / X_0))^a       (Form B — `a` shapes the saturation curve, not the asymptote)

scarcity_multiplier = 2 / (1 + e^(k × (supply − S_0)))  (centered on 1: equilibrium wage = base_skill × skill_factor)
```

- `S_0` (baseline supply) starts as a constant for v0; phase 3+ derives it from regional capacity (e.g., farmable land).
- `k` is a sensitivity ballast.
- `base_skill` is per-job-category.
- `a` is the learning-curve shape parameter.

### Wholesale price formula

```
wholesale_price = cost_per_grain × (1 + delta)

cost_per_grain = (labor_cost + seed_cost + tool_cost + land_tax) / grain_produced
                  ↑ non-zero v0    ↑ all 0 placeholders for v0

delta — for v0: static constant (0.5 proposed). Phase 3+ becomes dynamic with
        inertia/pressures/smoothing per `phase-2-math-observations.md` notes.
```

### Merchant willingness-to-pay

- `Merchant.max_wholesale_price` is a configured ceiling. Constant for v0.
- Merchant buys up to `target_inventory` at any ask ≤ ceiling, walks away if ask exceeds.
- Phase 3+ derives ceiling from observed retail price and target retail margin.

### Labor market matching

- Draft-style: each round, employers pick their #1 remaining candidate by `expected_productivity / asked_wage` (descending). Repeat until positions filled or workers exhausted.
- **`LaborMarket.clearing_strategy` enum** governs employer ordering and tie-breaking:
  - `RANDOM` — shuffle employers, random tie-break (v0 default)
  - `FIFO` — order by post-jobs arrival
  - `CHARISMA_PICK`, `PRODUCTIVITY_RANK` — phase 3+ (lord-archetype-driven)
- v0 implements `RANDOM` (and possibly `FIFO`, since both are trivial).

### Settled seam decisions (Q6, Q7, Q8, Q9, Q10)

- **Q6 Payable shape:** `Payable.slots_worked: int` accumulates daily; `pay_outstanding_wages()` multiplies by current rate at settlement (so weekly wage re-eval works without rebuilding the data shape).
- **Q7 `WageCalculator.calculate_wage()`:** signature already calls into the wage formula above; reads `worker.accounts.skills.get(&"farming", 1.0)` with default 1.0.
- **Q8 `WorkingInterest.compute_slot_output()`:** helper exists in v0 returning constant 1. Phase 3+ reads hunger + skill.
- **Q9 `GrainInterest.compute_daily_demand()`:** helper exists in v0 returning constant 2. Phase 3+ reads hunger.
- **Q10 `accounts.skills: Dictionary = {}`:** introduced empty in v0. Math reads via `.get(skill_name, 1.0)`.

---

## Open questions for the panel

### W1 — Zero-XP wage floor
**The bug:** at XP=0, `(1 − e^(−0/X_0))^a = 0^a = 0`. Fresh workers earn 0 coins. v0 must not have this.

Three candidate fixes:
- **(a) Floor at minimum_wage:** `wage = max(minimum_wage, skill_value × scarcity)`. Adds a constant. Easy.
- **(b) Bootstrap workers with non-zero starting XP:** workers begin life with `XP = X_0 × ln(some_factor)` or similar. Avoids the formula edit but conflates "I've been working a while" with "I exist."
- **(c) Reformulate skill_value:** `skill_value = base_skill × (min_fraction + (1 − min_fraction) × (1 − e^(−XP/X_0))^a)`. Asymptote unchanged at base_skill, but XP=0 yields `min_fraction × base_skill`. Cleanest mathematically, ugliest formula.

Pick one and justify briefly. Cloud, comment on which is most stable as the formula evolves in phase 3+.

### W2 — Calibration of v0 values

With 2 workers + 1 employer in v0, what's a defensible calibration for `{base_skill, X_0, k, S_0, a, minimum_wage (if W1=a)}`?

**Constraint to honor:** the build-spec's existing acceptance-criteria numbers assume wage ≈ 1 coin/slot. Calibration should preserve that *at v0 conditions*, so a fresh worker in a balanced market earns ≈1 coin/slot. (Variation can emerge later as XP grows or supply shifts.)

Samus, comment on whether v0 wage ≈ 1 feels right for "starting peasant pay." Cloud, comment on whether the chosen X_0 makes XP-driven divergence visible within the 14-day prototype trace or is too slow to observe.

### W3 — Wage re-evaluation frequency
Author says wage gets evaluated "when LMW clears AND weekly." Question: does the weekly evaluation re-rate **all active contracts**, or **only newly-formed contracts**?

- Re-rate all → workers see XP-growth and scarcity-shifts reflected in pay weekly. Strong incentive loop. But active contracts become unstable — the wage you signed for changes weekly.
- Only new → contracts are stable but workers must quit and re-bid to capture skill gains. Real-world feel.

Connects to Q6 (Payable shape): if all contracts re-rate weekly, Payable.slots_worked + rate-at-settlement is the only correct shape (already locked). If only new, current rate stays per-contract.

### W4 — Definition of `supply` in scarcity multiplier
What value goes into `2 / (1 + e^(k × (supply − S_0)))`?

- **Heads at this LMW clear:** number of workers queuing supply this clearing. Fluctuates clearing-to-clearing.
- **Slot-units offered:** heads × 8 slots (more granular but couples timing).
- **Active-region workers (employed + seeking):** structural baseline, smoother. Phase 3+ when region exists.
- **Something else:** open to the panel.

For v0 (single LaborMarket, 2 workers), pick what scales cleanly to phase 3+ regions.

### WS1 — Cost calc denominator timing
`cost_per_grain = (labor_cost + ...) / grain_produced` — when does this fire?

- **Per shipment:** each batch of grain shipped to wholesale carries a cost basis computed at shipment time (using week-to-date wages and grain).
- **Per week:** locked at end-of-week, applies to all wholesale clearings of that week.
- **Continuous rolling:** recomputed at every wholesale clear over a rolling N-week window.

For v0 with single weekly burst, "per week" is the obvious choice. But the seam matters for phase 3+ when multiple shipments per week may exist.

### WS2 — Static delta = 0.5?
Author proposed `delta = 0.5` for v0. Resulting wholesale price = 1.5 × cost.

With v0 cost ≈ 1 coin/grain (8 wages / 8 grain/week), wholesale price = 1.5. Then retail (per build-spec) is 1.0 coin/grain — **wholesale would be MORE expensive than retail.** That's broken.

Two ways out:
- v0 delta = 0 (wholesale = cost = 1), with retail at 1 (no merchant margin in v0). Math works but flatness erases the merchant's role.
- v0 delta is small (say 0.25 or 0.1), retail price gets revisited in retail round to ensure wholesale < retail.

Or a third I'm missing. Pick one and justify, or flag as "must wait for retail round."

### WS3 — Merchant target_inventory under leftovers
If merchant has leftover inventory from last week, do they:

- **(a) Demand `target_inventory − leftover_inventory`** (stockpile to target, account for what they have).
- **(b) Demand unconditional `target_inventory`** (re-buy each week regardless of stock).

(a) is economically sensible. (b) is dumber but simpler. v0 can use (a) with no extra complexity. Confirming.

### WS4 — Partial-fill rule (the original Q2)
When market supply ≠ market demand, who gets what? Apply at wholesale (and later retail).

Candidates:
- **Proportional:** each demander gets `(my_demand / total_demand) × total_supply`. Fractional rounding question.
- **FIFO by demand-arrival order:** first to queue full demand gets full fill until supply runs out.
- **Equal share with rationing:** `min(my_demand, supply / N_demanders)`. Re-distribute leftover.
- **Coin-weighted:** higher-bid takes priority. Collapses to FIFO when prices are flat.

For wholesale specifically, with v0 = 1 supplier + 1 demander, this is moot. **But the seam must scale to N suppliers + M demanders.**

### WS5 — Self-consumption (Q5)
Does the LandOwner eat their own grain? Two intuitions clash:

- **All flows route through markets.** LandOwner ships ALL grain to wholesale. Buys back from retail to feed self/workers. Cleaner economic model. Silly path (grain leaves and comes back).
- **Self-consumption is direct.** Before grain leaves the farm, LandOwner subtracts daily intake. Grain shipped to wholesale = production − self-consumption. Realistic but introduces a "private subtraction" path that markets don't see.

Same question for Merchant (eats own retail inventory or buys from self?).

Author leans **all-routes-through-markets** for simulation hygiene. But if retail in week 1 has supply=40 and only LandOwner can afford to buy (workers have 0 coin), LandOwner ends up buying 12 of their own grain at retail price. That's funny.

Samus, take the lead — this is more economic-feel than architecture. Cloud, weigh in on whether self-consumption introduces accounting paths that violate the persistence-vs-transience principle.

### WS6 — Dynamic delta seam state
v0 = static `delta = constant`. Phase 3+ adds inertia/pressures/smoothing. What named state should v0 introduce on Producer to make the phase 3+ plug-in clean (i.e., the seam is *named state*, not just stub functions)?

Candidate fields on a producer (or on `ProductionInterest`):
- `current_delta: float` — present, read by `compute_supplier_delta()`
- `target_profit: float` — placeholder for profit-pressure component
- `inventory_baseline: float` — placeholder for low/high inventory pressure
- `state_factor: float` — per-producer reactivity scalar
- `smoothing_lambda: float` — EMA blend weight for delta updates
- `pressure_history: Array` — empty in v0; phase 3+ tracks observed pressures

Cloud, take the lead — which of these are *actually* needed as named v0 state vs which can wait until phase 3 lands?

### WS7 — Architecture nit: enum vs Strategy pattern for `clearing_strategy`
`LaborMarket.clearing_strategy` as enum + match dispatch is simplest for v0. As strategies grow (CHARISMA_PICK, PRODUCTIVITY_RANK, ...), some prefer migrating to a Strategy object pattern (one class per strategy, polymorphic dispatch).

Cloud's call. Stay with enum for both v0 and phase 3+? Migrate at some threshold? Skip it entirely (the matching logic stays in LaborMarket regardless)?

---

## Retail-deferred attributes (flagging for the next round)

These attributes' meaning lives in retail design, but wholesale and wages will need to read them once retail lands. Math directive should introduce them as **named state with v0 stubs**, so the retail round only fills in computation:

**On Merchant:**
- `target_retail_margin: float` — drives `max_wholesale_price`
- `expected_retail_price: float` — drives `max_wholesale_price`; retail round computes from observed clearings
- `observed_retail_quantity_demanded: int` — drives next-week `target_inventory`

**On Producer (LandOwner):**
- `self_consumption_target: int` — Q5 still open; affects cost denominator
- `target_profit: float` — drives profit-pressure in dynamic delta (already in WS6)

**Cross-cutting:**
- `outstanding_demand` carry-forward semantics — Q3 is a retail-side decision

The panel can flag any I missed.

---

## What I want from each of you

A short position paper (under 500 words) addressing **W1, W3, W4, WS1, WS3, WS4, WS5, WS6** — the 8 must-answer questions. Touch W2, WS2, WS7 if you have a strong take, otherwise punt.

Format your answer as one bullet per question with: position chosen + 1–2 sentence rationale. Flag any disagreement you see with the locked positions (don't relitigate, but if you spot a genuine conflict, surface it). End with one paragraph: "what I'd want to be sure of before the math directive is drafted."

After both papers land, I'll synthesize. Round 2 only on points where you disagree load-bearingly.
