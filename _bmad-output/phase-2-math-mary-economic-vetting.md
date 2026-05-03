---
name: Phase 2 Math — Mary's Economic Vetting (Retail)
status: panel-paper
date: 2026-05-03
panelist: Mary (BMad strategic business analyst)
purpose: |
  Outside-game economic vetting of the retail design proposed in
  phase-2-math-brief-retail.md. Hand-off to Cloud + Samus for game-feel
  and architecture decisions; they decide what to fold into Section 2 vs
  defer to a later session.
---

# Mary's Economic Vetting — Retail Design

## 1. Defensible starting elasticity values

**Grain (inelastic subsistence good):** e_g = 0.3–0.5.

Real-world staple food elasticities from agricultural economics: bread and cereals sit at 0.1–0.3 in modern high-income economies, but shift sharply toward 0.4–0.7 in low-income and pre-industrial contexts where food consumes 60–80% of household spending. The key medieval-subsistence adjustment: when grain is your primary caloric source and substitutes are absent or seasonal, demand stays inelastic even as price rises — you pay because you must. However, at extreme price levels (3x–4x normal), even subsistence demand does compress: people forage, eat seed grain, or simply starve. The isoelastic form doesn't capture that cliff, but for the price range v0 will see (P_m roughly 1.0–2.5), an elasticity of **0.4** is defensible and produces readable behavior. The demand curve won't flatten to zero at high prices, which is actually correct for a subsistence good — people are still trying to buy even when they can't afford it.

**Generic normal good:** e_g = 0.8–1.2. For v0 purposes, **1.0** is the clean calibration — at unit elasticity the isoelastic curve is Q_d = A/P, so total expenditure (P × Q_d) is constant regardless of price. This is a useful anchor for "ordinary goods" because it makes the merchant's revenue invariant to price in the absence of quantity constraints. Real empirical ranges for processed food and basic goods: 0.5–0.9. Luxury manufactured goods: 1.2–2.0. The team's tier taxonomy (inelastic / normal / luxury) maps cleanly onto 0.3–0.5 / 0.8–1.2 / 1.5–2.5.

**Luxury tier:** e_g = 1.5–2.5. **2.0** as a placeholder. Empirical luxury goods elasticities from modern consumer research: 1.5 (wine, restaurant meals) to 3.0+ (jewelry, fine art). For a medieval-fantasy game, things like spices, fine cloth, and entertainment would plausibly sit at 2.0. The important property is that at e_g > 1, a price increase reduces total expenditure — merchants pricing luxury goods too high genuinely hurt their revenue, not just volume. This is the mechanism that makes "merchant reads demand wrong" legible to the player.

**The missing medieval adjustment:** subsistence economies have a higher effective elasticity for everything that isn't grain, because when grain prices spike, budget remaining for non-grain goods collapses. The cross-price effect is severe. v0 with single-good grain won't surface this, but the team should flag it when second goods land.

**Proposed v0 constants:**

| Good tier | e_g | Notes |
|---|---|---|
| Grain (inelastic) | 0.4 | Subsistence; no substitutes |
| Normal good | 1.0 | Clean unit-elasticity anchor |
| Luxury | 2.0 | Phase 3+; included for completeness |

---

## 2. Does elasticity change over time?

**Three mechanisms that shift elasticity in real markets — and whether v0 needs to model them:**

**Income effects (Engel's Law):** As worker incomes rise, the fraction of income spent on food falls, and the effective price elasticity of grain demand decreases (workers become less price-sensitive for staples because grain is a smaller share of their budget). In the v0 regime, workers start at 28 coin/week wages and grain at roughly 1.0 coin/grain — 14 grain would consume half their paycheck. At that income level, grain elasticity would be at the higher end of the inelastic range (closer to 0.5 than 0.3). If wages doubled in a later phase, grain elasticity would compress toward 0.2. **Safe to ignore in v0 — hold constant at 0.4.** Flag for phase 3+ when wages diverge meaningfully across actor classes.

**Substitution availability:** Isoelastic demand implicitly assumes a fixed substitute landscape. If oats enter the market as a substitute for grain, the effective elasticity of grain rises. v0 has only grain, so this is moot. But the team should know that when a second food good lands, grain's e_g should increase — demand becomes more elastic because people now have somewhere to go.

**Scarcity-driven shifts (Giffen behavior):** At extreme scarcity, staple goods can exhibit *positive* price elasticity — people buy more as price rises because they can no longer afford higher-preference foods and are forced to maximize caloric density. This is the Giffen good paradox, documented empirically for Irish potatoes (1840s) and Chinese rice (1990s rural studies). It won't arise in v0 (supply disruptions aren't severe enough), but it's the correct intuition for why constant elasticity eventually breaks.

**Fashion and luxury goods:** Veblen goods (conspicuous consumption) exhibit positive elasticity — higher price increases demand. Medieval luxury markets had this property (a lord's expensive fabric signals status; cheap fabric signals low status, less desirable). Phase 3+ concern only.

**Verdict:** Hold elasticity constant in v0 and through Phase 3 until income levels or substitute goods make the variance meaningful. When it changes, the right model is income-bracket-specific elasticity, not time-varying — the parameter shifts based on actor state, not calendar time. The seam to preserve is making e_g a per-good config constant (which the author's notes already propose) so it can be parameterized per actor class later.

---

## 3. How real markets work vs game simplifications

**What the isoelastic + cost-plus model omits, and whether it matters for v0:**

**Price discovery is iterative in real markets, not solved analytically.** Real merchants don't compute P* from aggregate supply and then apply a markup — they post a price, observe sales velocity, and adjust next period. The P* formula assumes the merchant knows A and Q_s and can compute equilibrium. In v0 this is a reasonable omniscience simplification: the simulation has access to all state, so letting the market "see" aggregate supply is fine. The danger is when merchants have multiple goods at different elasticities and the author wants price-setting behavior to feel like merchant decision-making rather than market mechanics. Safe for v0.

**Inventory dynamics.** In real retail, unsold inventory creates markdown pressure. A merchant sitting on 28 grain at end of week will lower price next week to move it. The proposed design addresses this only partially — P* adjusts naturally if Q_s stays elevated (higher supply → lower P*), but the merchant's δ_retail doesn't respond to inventory levels at all in v0. This means a merchant can repeatedly fail to clear and never adjust behavior. For v0 with a single merchant and stable supply, this won't break anything — the numbers will just show inventory accumulating. When merchant inventory dynamics become a design target (phase 3+), the δ_retail dynamic formula needs to be the pressure release valve.

**Credit and debt.** Real pre-modern markets extensively used credit — workers bought on account, merchants extended trade credit to regular customers. The model has no debt mechanism. The consequence: workers with 0 coin at retail simply can't buy. This is actually appropriate for v0 and produces the right emergent signal (workers go without grain when wages haven't cleared yet). When the hunger system lands, this will be the mechanism that creates real stakes. Safe simplification.

**Search costs and information asymmetry.** In real markets, buyers don't instantly find the cheapest seller. Search costs (time, effort) mean buyers often pay more than the competitive price. The multi-merchant clearing strategies (MARKET_PERCEPTION_RANK) gesture at this correctly — actors with higher market perception "find" the good stall faster. The economic interpretation is: market perception skill is a search cost reducer. This is a sound real-world parallel and should be preserved in the strategy enum vocabulary.

**Dangerous simplification — the demand-then-markup two-pass:** The sequence of first computing P* from supply (Q_s) and then applying merchant markup (δ_retail) to get P_m creates a subtle but important structural issue. P* is the price at which Q_d = Q_s, so by definition there is no excess supply at P*. When the merchant marks up to P_m, Q_d falls below Q_s. The model then computes Q_p = min(Q_s, Q_d(P_m)), which always equals Q_d(P_m) — the merchant always has leftover inventory at any positive δ_retail. This is mathematically correct but means the merchant never sells out at full demand in steady state. **The team should know**: "rationing" in this design comes only from multi-merchant splitting (R1-b) or affordability (R1-c), not from supply shortage at the posted price. The design should not be calibrated expecting single-merchant scarcity rationing at δ_retail > 0 — it won't happen.

---

## 4. Game theory food-for-thought

**Items the brief doesn't surface that the team should at minimum know they're punting on:**

**Double marginalization.** When a supply chain has multiple markup layers (here: producer takes margin at wholesale, merchant takes margin at retail), total markup exceeds what either actor would charge alone. Each actor maximizes their own margin without internalizing the demand destruction they cause at the next layer. In v0: wholesale price = 1.0 (no producer margin), retail price = P* × (1 + δ_retail). If the author later turns on δ_wholesale > 0, the combined effect on retail P_m will be multiplicative, not additive — and total demand destruction will be larger than expected. For v0 with δ_wholesale = 0.0, this doesn't bite. **Flag for when δ_wholesale turns on.**

**Strategic withholding.** A merchant who knows that grain is scarce this week might hold inventory off the market, wait for price to rise, then sell next week at a higher P*. Nothing in the current design prevents this — in fact, the merchant naturally accumulates inventory when it can't clear at P_m, and that inventory reduces their restock demand next week (WS3 deficit mechanic), which leaves more grain in the wholesale pool, depressing wholesale price. The irony is the design creates an accidental hoarding equilibrium: merchant holds back → wholesale supply stays high → wholesale price stays low → merchant's cost basis stays low → merchant can afford to hold back longer. This is emergent economic behavior the team might actually want. **Not a bug — surface it when tracing week 3+ behavior.**

**Posted prices vs auction mechanics.** The design uses posted prices (merchant announces P_m, consumers take or leave). In real pre-modern markets, negotiated prices were common — a wealthy buyer might pay a premium for first pick, a regular customer might get a loyalty discount. The CHARISMA_RANK and BARTERING_RANK clearing strategies gesture at this. From an economic standpoint, the distinction matters: posted-price markets are prone to coordination failures (everyone waits for the other to blink when supply and demand are close), while negotiated markets are more efficient but computationally expensive to model. The clearing strategies the author sketched resolve this correctly — the strategy enum picks the market's "social norm" for how prices get finalized. Sound design.

**Monopoly markup and consumer surplus.** The single-merchant case in v0 is a monopoly retail market. A rational monopolist maximizes profit by setting P where marginal revenue = marginal cost, which for an isoelastic demand curve with constant elasticity e_g gives the Lerner index: (P_m - MC) / P_m = 1/e_g. For grain (e_g = 0.4), the profit-maximizing markup is (P_m - MC)/P_m = 2.5, meaning P_m = MC / (1 - 2.5) — which is negative, meaning the monopolist's optimal markup is unbounded for inelastic goods. In practice this is constrained by what consumers can actually pay (affordability rationing), not by demand elasticity. **The merchant's δ_retail in v0 is a hardcoded constant, so this doesn't fire spontaneously. But if the author ever makes δ_retail endogenous (merchant learns to raise prices when demand is inelastic), the monopoly markup problem will drive the merchant to extract maximum coin from workers until they starve. This is narratively correct for a corrupt merchant — and the design should treat it as a feature, not a bug, when it lands.**

**Race-to-the-bottom in multi-merchant case.** When multiple merchants sell identical grain, each has incentive to undercut the other's P_m to capture more Q_p. In equilibrium, this drives P_m toward wholesale cost (Bertrand competition). The supply-ladder strategy the author sketched handles this correctly — it is essentially a Bertrand auction where consumers pick the cheapest stall first. The implication is: with two competing merchants both sourcing at the same wholesale price, their retail margins compress to near zero in equilibrium. The only escape is product differentiation (one merchant sells higher-quality grain, one sells lower) or information asymmetry (consumers don't know both prices). Both are phase 3+ concerns. **For v0 single-merchant, no race-to-the-bottom. For Section 3 multi-merchant, the team should expect competitive pressure to erode margins unless differentiation exists.**

---

## 5. Where the proposed model might break

**Concrete failure modes under v0 calibration (4 actors, 56 grain/week, wholesale cost = 1.0):**

**A calibration failure.** With e_g = 0.4 and Q_s = 56 grain/week (all 4 actors' aggregate demand), P* = (A / 56)^(1/0.4) = (A / 56)^2.5. For P* to equal 1.0 coin/grain (the wholesale cost basis), A must satisfy: 1.0 = (A/56)^2.5, so A = 56. Now with δ_retail = 0.1: P_m = 1.1. Q_d(1.1) = 56 × 1.1^(-0.4) = 56 × 0.962 = 53.9 grain. Q_p = min(56, 53.9) = 53.9. So the merchant sells 54 grain and holds 2. That's fine. But if supply were 30 (a bad week): P* = (56/30)^2.5 = 1.867^2.5 = 4.79. P_m = 4.79 × 1.1 = 5.27. Workers with 28 coin can afford 5.3 grain each, far below their 14-grain weekly need. This is actually the correct narrative behavior (harvest failure → workers can't afford food), but the team should **calibrate A carefully** — if A is set wrong, P* will be wrong at normal supply levels and the whole regime drifts.

**The self-consumption coin leak.** Under all-flows-through-markets, LandOwner produces grain, sells it to the merchant at 1.0 coin/grain, then buys it back at P_m ≥ 1.0 coin/grain. In steady state, the LandOwner is net paying the merchant's markup on their own grain. With δ_retail = 0.1 and LandOwner buying 14 grain/week: LandOwner pays 14 × 0.1 = 1.4 coin/week to the merchant in excess of wholesale cost. This coin comes from somewhere — either the LandOwner's initial endowment drains over time, or the LandOwner earns it back as profit from the wholesale sale (which they don't, since δ_wholesale = 0). Net result: the LandOwner is a slow coin sink, subsidizing the merchant's margin by the amount of grain they personally consume. At 14-grain weekly self-consumption, this is 1.4 coin/week drain on LandOwner's 200-coin endowment — 143 weeks to depletion, so not an urgent v0 concern, but the team should trace it.

**The A = aggregate or per-actor ambiguity.** If A is treated as aggregate (A = 56 for 4 actors), then adding a fifth actor doesn't change A — demand suddenly appears without A adjusting. If A is per-actor (A = 14 per actor, summed at clearing), adding an actor correctly scales demand. The brief's R3 surfaces this correctly. The **safe choice is per-actor A**, because aggregate A breaks under any actor-count change. The numerical regime above assumes A_aggregate = 56 (A_per_actor = 14 at P=1 with e_g=0.4), which requires confirmation.

**Degenerate case: Q_s → 0.** If the merchant has no inventory to ship to retail (they failed to restock, or last week's carryover was consumed), Q_s = 0 and P* = (A/0)^(1/e_g) → infinity. The formula blows up. The code needs a guard clause: if Q_s = 0, retail does not clear (or clears with P_m = infinity, Q_p = 0). This is trivial to handle but must be handled.

**Degenerate case: δ_retail drives P_m below wholesale cost.** If δ_retail is allowed to go negative and reaches -1.0, P_m = 0 and the merchant gives grain away. More practically, at δ_retail = -0.1, P_m = 0.9 while wholesale_cost = 1.0 — merchant loses 0.1 coin/grain. In the v0 regime with 56 grain sold weekly, that's 5.6 coin/week bleeding from the merchant's 44-coin balance (after week 2 wholesale purchase). Merchant goes insolvent in 8 weeks. This is the R6 scenario — the break-even floor is not cosmetic. **Name the seam (Merchant.min_retail_margin) and set it to 0.0 for v0. The field must exist.**

---

## 6. Recommendations to hand off

1. **Set e_g = 0.4 for grain in GoodConfig (or its v0 equivalent).** FOLD INTO SECTION 2. This is the calibration constant the P* formula requires. Leaving it at 1.0 (unit elasticity) will produce unintuitive price behavior for the subsistence good the entire prototype is built around.

2. **Confirm A is per-actor, not aggregate.** FOLD INTO SECTION 2. Per-actor A (stored on GrainInterest or GoodConfig with a per-actor multiplier) is the only form that survives actor-count changes. Aggregate A breaks when a fifth actor is added. R3 and S1 can both be answered by: A_per_actor in GoodConfig, summed at clearing by RetailMarket.

3. **Guard against Q_s = 0 before computing P*.** FOLD INTO SECTION 2. RetailMarket.compute_equilibrium_price() must return 0.0 (or skip clearing) if the supply pool is empty. One missing guard produces a division-by-zero or infinity propagating through Q_d into Q_p.

4. **Name Merchant.min_retail_margin on MercantileInterest, set to 0.0 for v0.** FOLD INTO SECTION 2. The R6 seam is load-bearing — a merchant who prices below cost will drain coin from the system. Even if the v0 value is 0.0 (no floor), the field must exist and be checked before the merchant ships inventory to retail.

5. **Affordability rationing at clearing (R2) should use the hybrid approach: express raw demand, skip at clearing if coin = 0.** FOLD INTO SECTION 2. The "express raw need, clear what coin allows, carry remainder to outstanding_demand" design (R2-c) is the right economic model — it separates *preference* from *purchasing power*, which is the distinction that makes the hunger system legible when it arrives. The market can see what actors want; it just can't give it to them without coin.

6. **outstanding_demand should cap at this-week's Q_d, not carry forever (R5).** FOLD INTO SECTION 2. R5-option (c) — reset or cap at each clearing — is the economically correct model for a weekly market. Carrying unmet demand from 10 weeks ago as "still-owed grain" has no real-world parallel; what actually happens is demand is re-expressed each period at the current price, and the unfulfilled need shows up as declining welfare (hunger system), not as a growing IOY balance. Carry-forever (option a) will produce a growing outstanding_demand number that makes traces hard to read and phase-3 hunger calibration harder.

7. **δ_wholesale should stay 0.0 for v0.** FOLD INTO SECTION 2. Once the retail price regime is calibrated, back-solve: if LandOwner charges δ_wholesale = 0.1, merchant's cost basis rises to 1.1, P* shifts upward, and workers get priced harder. That's a legitimate design move — but it should be conscious. For the first retail-clearing trace, start with δ_wholesale = 0.0 so retail math is isolated, then turn the wholesale margin knob in phase 3+.

8. **Single-merchant scope for v0 (R7-a).** FOLD INTO SECTION 2. The multi-merchant supply-ladder logic is architecturally interesting but won't fire with one merchant. Scaffold the clearing_strategy enum with PROPORTIONAL as the wired v0 strategy; leave the N-merchant ladder as a named but unimplemented enum entry. Implementing N-merchant logic now front-loads work with zero trace payoff.

9. **Document the monopoly markup property in the trace expectations.** PHASE 3+ FOOD. The single merchant in v0 is a monopolist. When merchant behavior becomes dynamic (δ_retail adjusts to observed demand), the monopoly markup dynamic (Section 4 above) will produce emergent price extraction that the team should recognize as intended behavior, not a bug. Write a one-page note when dynamic δ lands.

10. **Cross-price elasticity note when second goods arrive.** PHASE 3+ FOOD. Adding a second food good (or any good competing for worker budget) invalidates the constant-elasticity assumption for grain. At that point, e_g for grain should increase because substitutes exist. A one-line config change, but it won't be obvious without this flag.

11. **Double marginalization flag for when δ_wholesale turns on.** PHASE 3+ FOOD. Multiplicative markups at wholesale and retail will produce larger-than-intended retail price spikes. The combined markup is (1 + δ_wholesale) × (1 + δ_retail), not additive. At δ_w = 0.1 and δ_r = 0.1, the combined markup is 1.21 (21%), not 20%. Matters when both are non-trivial.

12. **Giffen good behavior at extreme scarcity.** DROP. Interesting real-world phenomenon but would require the isoelastic form to be replaced with a piecewise or non-parametric demand curve. Not worth modeling until the game explicitly targets famine mechanics.
