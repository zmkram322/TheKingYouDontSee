---
name: Phase 2 Math Observations
status: notes-in-progress
date: 2026-05-02
purpose: Surface the math/clearing gaps the build-spec leaves open, and the seams that future systems (skills/XP/aptitudes, hunger) will plug into. Fed to party-mode to produce a directive (`phase-2-math-directive.md`) for the next coding pass.
---

# Phase 2 Math Observations

## Briefing for the next session

### Goal of the session

Walk the math/clearing gaps in the build-spec's Phase 2 section, surface the open questions that the actual Phase 1 trace exposes, and produce a directive that locks (a) clearing rules under partial fill, (b) settlement order and timing, (c) the *shape* of state and computation seams that future systems (skills, hunger, aptitudes) will plug into. We are NOT implementing math/clearing this session. We are deciding the shape against real numbers first.

### What to read, in this order

1. **This file** — the gap list and the seam-thinking. The "Open questions" sections are the load-bearing parts. The "Walk through 14 days with real numbers" section is what makes the gaps concrete; party-mode should be able to point to specific scenarios.
2. **`_bmad-output/prototype-build-spec.md`** — Phase 2 stub-math section (lines 435-445) and the five acceptance criteria (lines 466-470). The spec's intent. Some of it is contradicted by what Phase 1 actually does; flagged below.
3. **`_bmad-output/phase-2-architecture-directive.md`** — the architecture is now locked. Math drops into the shapes this directive defines (Interest-owns-wiring, persistence-on-accounts, `current_contract()` derived, `EmployerInterest.filled_positions()` derived).
4. **`tkyds-game/scripts/`** — the actual code post-refactor. `clear()` and per-slot computation methods are the targets the math fills in.
5. *(Optional)* `_bmad-output/supplement-prototype-gaps.md` and `_bmad-output/supplement-economic-model.md` — the older designs that defined aptitudes/skills/XP and the production formula. Useful when picking seam *shapes* (so phase 3 docks cleanly), not for pulling the systems in now.

### Background party-mode should hold while reading

- **Phase 1 prints clean** for 14 days. **Phase 1.5 architecture refactor is shipped** — flat Actor, Interest-owns-wiring, persistence-vs-transience principle. Math drops into a stable foundation.
- **Math pass scope is "stub math":** flat wage = 1 coin/slot, flat wholesale price = 1 coin/grain, flat retail price = 1 coin/grain, flat 1 grain per work-slot. The point is to make the loop self-consistent and the five acceptance criteria observable.
- **Author's seam-thinking constraint.** Aptitude/skill/XP and hunger are out of scope for *implementation* in this pass — but the *shape* of code (function signatures, where values get computed, where state lives) must be designed so phase 3 plugs in without rebuilding wage flow or per-slot output. Specific seams listed below.
- **Phase 1.5 principle (carry forward):** anything that survives Interest removal lives on `accounts`. Anything purely behavioral lives on the Interest. Math additions should respect this.
- **Author preferences:** plain-English method names, no CS jargon. Composition. Same as before.

### What's to be evaluated

The questions in "Open questions" below. Specifically:

1. **Spec contradiction surfaced by Phase 1:** the build-spec's acceptance criteria assume work happens day 1, but the daily flow puts LMW at LATE_EVENING (after WW closes), so contracts only exist from day 2 onward. Either reorder day 1, accept startup lag, or bootstrap day-0 contracts.
2. **Partial-fill clearing rules.** Wholesale supply (~40) < merchant demand (60). Retail supply (~40) < aggregated retail demand (~48). Who gets what when supply < demand? Proportional, FIFO, coin-weighted, something else?
3. **`outstanding_demand` semantics on partial receipt.** Carries forward, decays, capped at affordability?
4. **Settlement order in weekly burst.** Wages_due fires *after* retail clears — workers have 0 coin at retail in week 1 because they haven't been paid yet. Is that intentional (1-week startup lag) or a sequencing bug?
5. **Self-consumption.** LandOwner produces grain via workers, ships *all* to wholesale, then has to *buy back* via retail to feed themselves (they have a GrainInterest). Intentional? Same question for Merchant — do they eat their own inventory or buy from themselves?
6. **Payable shape (Seam #1).** Today: locked coin amount at creation. For phase 3 skill-driven wage reassessment, locking at WW close is wrong. Slots-worked + rate-at-settlement is the cleaner shape.
7. **WageCalculator signature (Seam #2).** Per-slot rate vs total amount. Where does the multiplication happen.
8. **`do_one_work_slot()` output computation (Seam #3).** Hard-coded `+1` vs computed by helper. Hunger/skill plug into the helper later.
9. **`GrainInterest.daily_demand` computation (Seam #4).** Constant vs computed. Hunger drives this later.
10. **Skill state shape (Seam #5).** Whether to introduce an empty `accounts.skills: Dictionary` now, or punt entirely to phase 3.

### What we want out of the session

A directive at `_bmad-output/phase-2-math-directive.md` that:

- **Takes positions** on each open question above. Pick one and justify briefly.
- **Lists concrete refactor/extension steps** for the math coding pass: function signatures, Payable structure changes, settlement-order fixes, partial-fill algorithm, every place a "stub" needs to land.
- **Names the seams explicitly** with their phase-3 plug-in pattern, so the math pass is forward-compatible without phase-3 work happening now.
- **Flags any acceptance-criterion revision** the spec needs (especially #3, the day-1 work claim).
- **Stays scoped to math.** Aptitudes/skills/XP/hunger themselves stay deferred. Just the seams.

---

## What the build-spec already locks (recap)

**Stub math targets (build-spec lines 437-444):**

1. `LaborMarket.clear()` creates real LaborContracts, FIFO match, `WageCalculator.calculate_wage()` returns flat 1. *(Already done at v0 — Phase 1 implementation has this.)*
2. `WorkingInterest.do_one_work_slot()` adds 1 grain to worker inventory.
3. WW close actually transfers grain worker→landowner and creates a `Payable`.
4. `WholesaleMarket.clear()` moves grain and coin at flat price.
5. `RetailMarket.clear()` moves grain and coin at flat price; updates `outstanding_demand`.
6. `LandOwner.pay_outstanding_wages()` (now `EmployerInterest.pay_outstanding_wages()` post-refactor) walks payables and pays.

**Five v0 acceptance criteria (build-spec lines 466-470):**

1. Workers gain employment by day 1 LMW close.
2. LaborContracts consistent on both parties' accounts.
3. By end of day 1: LandOwner inventory has 8 grain, 4-coin payables to each worker. By day 7 wages_due: LandOwner coin -56, each worker +28.
4. Day 7 WMW: grain owner→merchant, coin reverse, at flat price.
5. Day 7 RMW: grain merchant→consumers, coin reverse, `outstanding_demand` decremented.

---

## Spec contradictions surfaced by Phase 1's actual trace

### Day 1 has no work — acceptance criterion #3 is wrong

The build-spec daily flow puts `WindowBus.open_labor_market()` at `LATE_EVENING`, which is *after* `close_work_window()` at `EARLY_EVENING`. Contracts get written at end of day 1. First work happens day 2 MID_MORNING.

The Phase 1 trace confirms: day 1's WW open/close emits no `do_one_work_slot()` lines — workers had no `active_contract` so `begin_working` skipped, `work_state` stayed IDLE, and the slot helper bailed.

This contradicts AC #3's "by end of day 1, LandOwner inventory holds 8 grain." It also contradicts the day-7 number — by `wages_due` on day 7 EARLY_MORNING, only **5 days** of work have happened (days 2-6), not 7. That's 5 × 8 = 40 grain produced, 5 × 8 = 40 coin owed. Not 56.

**Three candidate fixes:**

(a) Reorder day 1 specifically: LMW at EARLY_MORNING for day 1 only, then normal flow. Day 1 becomes special.

(b) Accept the lag: rewrite AC #3 with correct numbers (40 instead of 56, day 2 instead of day 1 for first inventory, etc.). The economy has a 1-day startup lag.

(c) Bootstrap actors with day-0 contracts already in place — `prototype_bootstrap.gd` writes the LaborContract directly into accounts before sim starts, no day 1 LMW needed for first round.

### Wages_due fires *after* retail clears

`WindowOrchestrator.fire_weekly_burst()` order: `merchant_restock` → wholesale open/close → retail open/close → `wages_due`.

Result: at retail clearing time on day 7, workers have **0 coin** (they haven't been paid yet for week 1's work). Even if RetailMarket honors their demand, they can't afford to pay the merchant. Week 1 retail is effectively LandOwner + Merchant only.

Build-spec didn't flag this. Either it's an intentional 1-week startup lag (real economies have payment cycles too), or wages_due should move *before* retail open. Decision needed.

---

## Open questions for the math pass

### Q1 — Day-1 startup: reorder, accept lag, or bootstrap contracts?

Each option has costs:
- **Reorder day 1:** clean acceptance criteria, but day 1 is now a special case in the orchestrator. Fragile.
- **Accept lag:** clean orchestrator, but acceptance criteria need rewriting and the economy has a startup transient that's mildly confusing.
- **Bootstrap contracts:** clean orchestrator AND clean ACs, but the LaborMarket flow on day 1 is bypassed (workers don't *find* their first job — it's handed to them). Phase 2's "loop runs every cycle" property is violated for cycle 1.

### Q2 — Partial-fill rule for clearing markets

Wholesale clear day 7: supply ≈ 40 grain (5 days of work × 8 grain), demand = 60 (merchant target_inventory). Supply < demand by 20.

Retail clear day 7: supply = whatever merchant got = 40, demand = 6 days × 4 actors × 2 grain = 48. Supply < demand by 8.

When supply < demand, who gets what?

Candidate rules (pick one for v0; defer the harder ones):
- **Proportional fill:** each demander gets `(my_demand / total_demand) × total_supply`. Fractional grain rounds how?
- **FIFO by demand-arrival order:** first to queue demand gets full fill until supply runs out.
- **Equal share with rationing:** `min(my_demand, supply / N_demanders)`. Leftover supply re-distributes.
- **Coin-weighted (retail only):** higher-bid takes priority. v0 has flat prices so this collapses to FIFO.

### Q3 — `outstanding_demand` semantics on partial receipt

GrainInterest tracks cumulative outstanding demand. Today (Phase 1 print-only), it grows by `daily_demand` daily and is never decremented because RetailMarket.clear is a no-op.

After math: when retail clears with partial fill, `record_receipt(qty)` decrements by qty. But:

- Does outstanding_demand decay over time, or accumulate forever? An actor who can't afford retail for 5 weeks shouldn't owe themselves 70 grain when they finally can.
- Does demand placed at retail get *capped* by the actor's current coin (you can't ask for what you can't pay for)?
- Does `place_grain_order` add to outstanding_demand even if the actor has 0 coin to spend?

This intersects with self-consumption (Q5) — workers in week 1 want grain but can't pay; LandOwner can pay; LandOwner ends up with grain they could have eaten from their own inventory.

### Q4 — Settlement order: `wages_due` before or after retail clear?

Today's order forces a 1-week startup lag for workers' retail purchasing. Two camps:

- **Keep as-is.** Lag is real-world-plausible (payday is end-of-week). Workers participate fully starting week 2. Acceptance criterion #5 needs to be tolerant: "Workers (and other consumers) have grain in inventory" applies to anyone who could afford it.
- **Move `wages_due` before retail open.** Workers can buy in week 1. The loop closes faster. But then daily Payable accumulation has to still settle weekly (this is fine — Q6 below covers it).

### Q5 — Self-consumption: does LandOwner eat their own grain?

LandOwner has `GrainInterest` (built into bootstrap). Their `place_grain_order` queues retail demand. After a week of producing 40 grain → ships ALL to wholesale → merchant sells 40 to retail → LandOwner buys some of their own grain back at flat price.

Two intuitions clash:
- **The world routes everything through markets.** Cleaner economic model. LandOwner's own grain is "production," not "consumption" — different accounting category. Retail is where consumption happens.
- **Self-consumption is direct.** Before grain leaves the farm, the LandOwner takes their own daily intake. Grain shipped to wholesale = production - self-consumption.

Same question applies to Merchant (eats from own inventory? buys retail from themselves?). The build-spec footnoted this as "edge case ignored for v0; demand is small enough not to matter" — but with real numbers, 14 grain per fortnight per actor is non-trivial relative to 40-60 grain pools.

### Q6 — Payable shape (Seam #1)

Today the build-spec implies `Payable.amount: int` — coin owed, locked at WW close. Phase 3 will reassess wage weekly based on accumulated skill. If wages are locked at WW close, week-end skill accrual doesn't move the needle on this week's wages.

Two shapes:

(a) **Slots-worked Payable.** `Payable.slots_worked: int` accumulates daily; `pay_outstanding_wages()` multiplies by current rate at settlement. Phase 3 swap is one line in the rate function.

(b) **Coin Payable, recomputed weekly.** `Payable.amount: int` updated daily; `pay_outstanding_wages()` overrides at settlement. More mutable state, less clean.

Recommend (a). Decide now so v0's payable shape is forward-compatible.

### Q7 — `WageCalculator.calculate_wage` signature (Seam #2)

Today returns flat 1. The signature today is `calculate_wage(employer, worker) -> int`. For phase 3:

```gdscript
func calculate_wage(employer: Actor, worker: Actor) -> int:
    var skill_rate := worker.accounts.skills.get(&"farming", 1.0)
    var employer_factor := 1.0   # later: employer wealth, scarcity, etc.
    return int(skill_rate * employer_factor)
```

For v0 the skills dictionary lookup returns 1.0 default (because no skills exist yet) and the function returns 1. **Same value, but the seam is in place.**

### Q8 — `do_one_work_slot()` output computation (Seam #3)

Today (proposed for math pass): `worker.accounts.inventory[&"grain"] += 1`. Hard-coded.

Seam shape: `compute_slot_output() -> int` (or float) helper inside `WorkingInterest`. v0 returns 1. Phase 3 with hunger:

```gdscript
func compute_slot_output() -> int:
    if owner.accounts.hunger > HUNGER_INCAPACITATING_THRESHOLD: return 0
    var skill := owner.accounts.skills.get(&"farming", 1.0)
    return int(skill)
```

Decide now whether the helper exists in v0 (returning constant 1) or only gets introduced in phase 3.

### Q9 — `GrainInterest.daily_demand` computation (Seam #4)

Today: `@export var daily_demand: int = 2`. Constant.

Phase 3 with hunger: demand might rise when hungry, fall when satiated. Seam shape: a `compute_daily_demand() -> int` method instead of (or alongside) the constant. v0 returns 2.

Same Q as #8: introduce the helper now (returning constant) or only when needed.

### Q10 — Skill state shape (Seam #5)

Today: `accounts.skills` doesn't exist. Phase 3 needs it.

Two paths:
- **Introduce empty `skills: Dictionary` on Accounts now.** Math doesn't read it (or reads it via WageCalculator with `.get(&"farming", 1.0)`). Phase 3 just starts populating it.
- **Punt entirely.** Add to Accounts when phase 3 lands.

The first option costs 1 line in `accounts.gd` + 1 line in `WageCalculator`. Trivial. Probably worth doing now for the seam.

---

## Walk through 14 days with real numbers

Starting state: 2 workers (0 coin each), LandOwner (200 coin, 0 grain), Merchant (100 coin, 0 grain). Flat values throughout.

**Day 1.** WW: no work (no contracts yet). LMW: 2 supply, 2 demand. Clear: 2 contracts written. GrainInterest places: 4 actors × 2 = 8 grain demand to retail pool.

**Day 2-6.** Each day: 4 work slots × 2 workers = 8 grain produced. Daily WW close: 8 grain transfers worker→LandOwner; 8 slot-units accrued as Payables (Q6 — see above). LandOwner ships 8 grain to wholesale pool. Daily LATE_EVENING: 4 × 2 = 8 grain demand to retail pool. After 5 days: LandOwner has 40 grain, 0 coin movement, payables = 40 slot-units (= 40 coin if rate=1). Wholesale supply pool = 40. Retail demand pool = 6 × 8 = 48 (days 1-6).

**Day 7 EARLY_MORNING (weekly burst).**

- `merchant_restock`: Merchant places wholesale demand of 60 (target_inventory).
- `wholesale_market.clear()`: supply = 40, demand = 60. **Partial fill (Q2).** Say proportional or FIFO settles to: Merchant gets 40 grain. LandOwner inventory grain → 0. Merchant pays LandOwner 40 coin. Coin balances: LandOwner 240, Merchant 60.
- Merchant `send_inventory_to_retail`: 40 grain to retail supply pool.
- `retail_market.clear()`: supply = 40, demand = 48. **Partial fill (Q2).** Pre-distribution coin: workers 0, LandOwner 240, Merchant 60 (own retail demand of 12 from days 1-6).
  - **Affordability question (Q3):** workers can't pay. Do they get filled and create a payable? Demanded but no-coin? Skipped?
  - LandOwner can afford 12 grain (their 6-day demand). Cost: 12 coin. LandOwner: 228 coin, 12 grain.
  - Merchant could "buy from themselves" — Q5.
  - Workers' demand (12 each = 24 total) goes unfilled because they can't pay. `outstanding_demand` stays at 12.
  - Net: of the 40 supply, only 12 was demanded by a paying actor. **28 grain leftover at the merchant.** What happens to it? Stays in pool until next week? Spoils? Resets?
- `wages_due`: LandOwner pays 40 coin (5 days × 8 slot-units × 1 rate). Each worker +20. Coin: LandOwner 188, Worker_1 20, Worker_2 20.

**End of day 7:** Workers have 20 coin each. Retail is closed for the week. Day 7 LATE_EVENING places more demand.

**Day 7 MID_MORNING through EARLY_EVENING (after weekly burst).** Day 7 itself has WW. 8 more grain produced and shipped to wholesale pool.

**Day 8-13.** Same as 2-6. 6 more days of work. 6 × 8 = 48 grain produced. Wholesale supply pool: 8 (from day 7) + 48 = 56 grain.

**Day 14 EARLY_MORNING (weekly burst).**

- Merchant places wholesale demand 60 (target). They have 28 grain leftover from week 1 if it carries forward, so demand = 60 - 28 = 32? Or unconditional 60? **Spec gap.**
- Wholesale clear: supply = 56, demand = 60 (or 32). Either way: full fill if 32, partial if 60.
- Retail demand pool = 7 × 8 = 56 (days 7-13, with day 7 LATE_EVENING included). Plus carryover from week 1's unfilled outstanding_demand (varies by Q3 answer).
- Retail clear: supply varies by wholesale outcome; demand = 56 + carryover. Workers now have coin (20 each from week 1's wages). Real participation possible.
- Wages_due: 7 days × 8 slot-units = 56 coin owed. LandOwner -56, each worker +28.

The week 2 numbers are the ones that match build-spec acceptance criterion #3 in spirit (28 coin per worker) — but only because a 1-week startup lag is in effect.

---

## Surprises in the spec that this walk reveals

- **Coin doesn't conserve cleanly without a clear settlement-order decision.** LandOwner pays merchants for grain they grew, then pays workers, then their workers go buy that same grain back from the merchant. Multiple round-trips per week. With flat prices the books balance, but the path is silly — Q5 (self-consumption).
- **The merchant's retail leftover problem.** When supply > demand at retail, the merchant ends the week with grain on hand. Reset pools clears the *pool* (the demand/supply queue), not the merchant's *inventory*. So Merchant accumulates grain across weeks. Is that intentional inventory carry, or a bug?
- **`outstanding_demand` is not actually a "demand placed at market"** — it's a per-actor running tally. It grows monotonically in Phase 1 because nothing decrements it. After math, it should decrement on receipt — but the carry-forward semantics are unspecified.
- **Acceptance criterion #3's numbers don't fit any consistent timeline interpretation.** They assume work starts day 1 (8 grain by EOD 1) AND wage-times-7 by day 7 (56 coin). But the daily flow makes day 1 work impossible. Real numbers under either fix (reorder day 1, accept lag, bootstrap contracts) come out differently.

---

## Notes on phase 3 (out of scope, but seams must accommodate)

The math pass should leave seams for these systems without implementing them:

- **Aptitudes (`traits: Aptitudes` on Actor or Accounts):** static traits ATH/CHA/INT. Static field, no behavior. Only matters as input to XP-gain calculations and (later) production formulas. **Not an Interest** — it's data.
- **Skills (`accounts.skills: Dictionary`):** maps skill name → level (float). Level updated by XP gain during activity. Read by `WageCalculator.calculate_wage`, by `WorkingInterest.compute_slot_output`, etc.
- **XP gain:** during `do_one_work_slot`, the activity emits XP weighted by relevant traits. Updates `accounts.skills[skill_name]`.
- **HungerInterest:** new Interest. Reads `accounts.inventory[&"grain"]` daily, mutates `accounts.hunger` on a curve. Affects `compute_slot_output` (productivity drop) and `compute_daily_demand` (eat more / panic-buy when hungry). **Is an Interest** — it's behavior tied to bus signals. State (`hunger`) lives on `accounts`.

Math-pass seams that enable each:

| Phase 3 system | v0 math seam |
|---|---|
| Aptitudes | nothing — pure data; introduce `traits` field on Actor when phase 3 lands |
| Skills | `accounts.skills: Dictionary = {}` introduced in math pass; `WageCalculator` reads it with default 1.0 |
| XP gain | `WorkingInterest.do_one_work_slot()` calls `compute_slot_output()`; phase 3 adds an XP-emit line alongside |
| Hunger affecting productivity | `WorkingInterest.compute_slot_output()` is a method, not a hard-coded `+1` |
| Hunger affecting demand | `GrainInterest.compute_daily_demand()` is a method, not a constant |

**Architectural principle (from Phase 1.5) carries forward:** state that survives Interest removal lives on `accounts`. So `skills`, `hunger`, `traits` all go on Accounts (or directly on Actor for things that aren't ledgers, like static traits — open to debate). Behavior lives on the Interest.

---

## Candidate Phase 2 directive structure (for the next session's output)

After party-mode lands, the directive should cover:

1. **Spec amendments.** Acceptance criterion #3 numbers updated, day-1 startup decision, settlement order decision.
2. **Clearing algorithm.** Pseudocode for partial-fill in WholesaleMarket and RetailMarket.
3. **Payable shape change.** Slots-worked vs amount; pseudocode for `pay_outstanding_wages`.
4. **Method signatures.** `WageCalculator.calculate_wage`, `WorkingInterest.compute_slot_output`, `GrainInterest.compute_daily_demand` — all the seams, with v0 bodies.
5. **Accounts shape.** `skills: Dictionary` (or punt), `inventory` semantics, where unfilled `outstanding_demand` lives.
6. **Trace expectations.** What the 14-day post-math run should print and total to. Numbers per day per actor.
7. **What's deferred to phase 3** (carrying forward the seam plug-in patterns above).

---



# Market Math (Raw Notes)

## Wages

we want the job itself to convey a base wage that also has a decay factor driven by XP. then a scarcity multiplier.  

wage = skill value * scarcity multiplier
skill value = (base skill * (1 - e^-(XP/X_0)))^a
scarcity multipliler = 1 / (1 + e^(k*(supply - S_0)))
we'll have to calibrate X_0 and baseline supply (S_0), k, base skill, etc., ask ourselves how to derive S_0.. we can leave a seam to calculate it.. like if there's a certain amount of farmable land, that drives S_0 dynamically.  we'll use k as a ballaste factor to make sure it's not too sensitively calibrated for any job type.  

wage will get evaluated when the labor market clears and weekly *i.e., at the beginning of the week, so we should probably move our weekly tick to the early morning tick on day 1 of the week, not on day 7.  how exactly does the labor market clear when there's multiple possible workers, a higher wage worker might produce more profit b/c they are more productive so the extra expense may be worth it - do we make it random, do we have some form of intelligence baked in, there's likely going to be multiple job markets firing at once so we'll want the labor market to clear rationally.

## wholesale markets

we should keep these somewhat simple (meaning I don't think these markets should behave like a retail market).  those with the interest obviously want to sell all of their supply, above their costs with a particular profit margin.  this will require them to have an understanding of their costs (think we'll need a cost determination seam).  the margin mark-up will be a delta, such that:

wholesale price = cost to produce * (1 + delta)
delta likely needs some inertia mechanics, state mechanics (driven by the wholesale suppliers behaviors), profit pressures, inventory pressures (both low and high)

for any given producer, p
delta_p,t+1 = delta_p,t + state factor * alpha * sum(pressures)
pressures could be driven by having a low supply inventory relative to some baseline, profit pressure could be due to recognizing that the desired profit is not being met, and some relief valve if supply inventory is too high.. we should figure out what's good baseline math for the systems and iterate from there.

from that raw delta_p,t mechanic -- we could choose to clamp it even more with a factor of lamba, (1-lambda)* delta_p,t+1 + lambda * delta_p,t

# Retail markets

## demand formula
e_g = elasticity for a good
Q_d(P) = quantity demanded for a given price
A = baseline demand
Q_d(P) = A * P^-e_g

we'll need a config (i think) for the elasticity of goods, maybe a tier for inelastic, normal goods, and luxury goods?

## computing equillibrium price

Q_s = quantity in local region supply
Q_d(P*) = quantity demanded at equillibrium price
Q_d(P*) = Q_s, solve for P*
P* = (A/Q_s)^(1/e_g)
P* is the market price before any merchant markup/markdown

## merchant price
now we have a second pass where P_m = merchant price.
P_m = P* x (1+delta)
Q_d(P_m) = A * P_m^-e_g

Q_p = actual quantity purchased
Q_p = min(Q_s, Q_d(P_m))

## market clearing

when Q_p = Q_d, simple clearing at P_m
if Q_p < Q_d, need to clear based on strategy.  one could be everyone gets factor applied to their own quantity demanded of Q_p / Q_d.  Or FIFO.  or a strategy where customers demand is lined up by a stat min/max.  any other strategies we can think of are welcome here.. so each P_m will be different by merchant, so we need our strategies to consider how the market clears in that situation.  One strategy is to line up the sellers prices with their inventory spread horizontally, and then line up consumers by market perception (a skill based on XP), such that the ones with the best market perception get cleared first.  there's other thoughts and strategies around how charisma or a stat related to charisma (like a bartering skill) comes into play (**will want samus's guidance on this**)