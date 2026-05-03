---
name: Phase 2 Math — Samus's Retail Position Paper
status: panel-paper
date: 2026-05-03
panelist: Samus Shepard (Game Designer)
inputs_read:
  - phase-2-math-brief-retail.md
  - phase-2-math-mary-economic-vetting.md
  - phase-2-math-directive.md (Section 1)
  - game-brief.md
  - supplement-prototype-gaps.md
purpose: |
  Game-design position on retail mechanics — what reads in the trace, what
  produces signature moments, what feels silly. Reaction to Mary's hand-off.
  Authoritative voice on charisma / bartering / market-perception strategies.
---

# Samus's Retail Position Paper

## Reaction to Mary's hand-off

Mary's paper is excellent and mostly correctly aimed. Going through her 12 recommendations:

**Rec 1 — e_g = 0.4 for grain:** AGREE-FOLD. The trace *needs* grain to feel sticky. If e_g is 1.0, price doublings halve demand neatly, which reads as "simulation working correctly" but not as "people are desperate." 0.4 is the number where the trace says "price went up 80%, demand only dropped 28% — these people are trying." That's the texture we want to see in v0.

**Rec 2 — A is per-actor, not aggregate:** AGREE-FOLD. Per-actor A is not just architecturally correct — it's the only design that lets individual hunger stories be told later. When a lord's workers have different A values (one is a big eater, one is frail), that's a legible difference in the ledger. Aggregate A is a shortcut that forecloses the character layer.

**Rec 3 — Guard Q_s = 0:** AGREE-FOLD. This is a trivial implementation note. If it's not in the directive, it won't be in the code and we'll get a crash on the first week with a disrupted supply chain. Name the guard. Put it in.

**Rec 4 — Name Merchant.min_retail_margin, set to 0.0:** AGREE-FOLD. Even at 0.0, the field existing forces the question every time someone touches merchant pricing. That's good design hygiene. See R6 below for more.

**Rec 5 — Hybrid affordability (R2-c):** AGREE-FOLD. This is the right call. See R2 below.

**Rec 6 — Cap outstanding_demand at this-week's Q_d (R5-c):** DISAGREE-FOLD. Mary's economic reasoning is correct but the game-design case goes the other way. See R5 below — I'm taking R5-b (decay) over R5-c (cap/reset).

**Rec 7 — δ_wholesale = 0.0 for v0:** AGREE-FOLD. See R8. Cleaner trace.

**Rec 8 — Single-merchant scope for v0 (R7-a):** AGREE-FOLD. Single-merchant demonstrates the price formula. Multi-merchant demonstrates the strategy enum. Those are two different demos. Do one first.

**Rec 9 — Document monopoly markup property:** AGREE-DEFER. File a note when dynamic δ lands. Not now.

**Rec 10 — Cross-price elasticity note for second goods:** AGREE-DEFER. Correct and low priority.

**Rec 11 — Double marginalization flag:** AGREE-DEFER. The directive should have a one-liner: "when δ_wholesale turns on, combined markup is multiplicative, not additive." That's enough.

**Rec 12 — Giffen behavior:** DROP. Correct call.

**Mary's structural concern (Q_d(P_m) ≤ Q_s at δ ≥ 0):** This is the most important thing she flagged. What it means for the v0 trace: with a single merchant and any positive δ_retail, the merchant *always* ends the week with leftover grain. The clearing print will read "Merchant sold 54 grain, 2 remain." Every. Week. That's fine for v0 — it demonstrates the math — but it can't read as the story. The story comes from affordability (R2-c) producing "Worker_1 wanted 14 grain, could only afford 9." That's the line that matters. The slight merchant surplus is noise. We need to make sure the print surface makes the demand-side story legible, not just the supply-side arithmetic.

---

## R1 — Where does rationing arise?

**Position: (c) affordability rationing only for v0. No δ_retail < 0. δ_retail strictly non-negative.**

Merchant markdowns (δ_retail < 0) are a later-phase story — "merchant panicking to clear inventory before it spoils" requires a merchant with enough intelligence to recognize their position. That's phase 3 behavior. In v0, a merchant slashing prices below wholesale cost reads to the player as either a bug or as the merchant being generous, neither of which is the simulation signal we want. Lock δ_retail ≥ 0 explicitly in v0. The code should enforce `delta_retail = max(0.0, delta_retail)` or document the constraint.

The rationing story in v0 is: some actors wanted grain and could not pay. The trace should surface that, not invent scarcity that the math doesn't produce.

---

## R2 — Affordability: where does coin enter?

**Position: (c) hybrid. Express raw demand. Clear what coin allows. Remainder to outstanding_demand.**

Option (a) — workers with 0 coin queue 0 demand — produces a trace that reads as "nothing happened." Week 1, the retail print would show 2 consumers (LandOwner + Merchant) buying grain and 0 demand from workers. An observer watching that trace cannot infer that workers were hungry. The simulation is hiding the thing that matters.

Option (c) produces: "Worker_1 placed demand for 14 grain. Worker_1 could afford 0. 14 grain outstanding." That is a legible story. The market can see what actors want; it just can't give it to them. When the hunger system arrives in phase 3, it plugs directly into outstanding_demand and the cause chain is already in the data.

The print at clearing should emit the delta explicitly: "Worker_1: wanted 14, could afford 9, received 9. 5 outstanding." That's the trace texture we need.

---

## R3 — A calibration (per-actor differences matter for v0?)

**Position: uniform appetite in v0 is fine. Per-actor A matters when actors are characters, not when they are archetypes.**

In v0, the four actors are archetypes standing in for classes. The interesting signal isn't "this specific LandOwner eats more than that specific Merchant" — it's "the worker class can't afford grain when the merchant marks up." Per-actor A differences are a character signal, not an economic class signal. They belong in phase 3+ when individual actors have named personalities.

For v0: A_per_actor = 14 (at P=1, e_g=0.4), confirmed by Mary's calibration arithmetic. Uniform across all four actors. Stored on GoodConfig per Mary's recommendation; per-actor multiplier seam exists for later.

---

## R4 — Period of Q_d

**Position: (a) Q_d is per-clearing. A is calibrated to weekly aggregate.**

Option (b) forecloses nothing. When retail goes daily in a later phase, A becomes the daily constant and the formula stays identical. (a) is the cleaner seam and does not foreclose any phase-3 design move I care about.

---

## R5 — outstanding_demand carry-forward

**Position: (b) decay. `outstanding_demand × (1 − λ)` per week, λ in config, v0 start around 0.3.**

Mary recommends (c) — cap/reset. I disagree on game-design grounds.

Cap/reset produces a trace where every week starts fresh. An actor who went hungry for three consecutive weeks shows the same outstanding_demand as one who went hungry once. The simulation forgets. That's wrong for this game, where consequences accumulate. "Workers have been undersupplied for four weeks" should be a different situation than "workers went without grain this week."

Carry-forever (a) is too aggressive — 70 grain of backlogged "owed grain" becomes unreadable. Decay (b) is the correct middle: hunger pressure fades if unaddressed, but slowly. λ ≈ 0.3 means outstanding_demand halves roughly every two missed weeks. When phase 3 hunger arrives, it reads accumulated pressure from this field, not a fresh reset number. The semantics are: this is how hard the actor is pushing to get grain, not how much grain the universe owes them.

The print difference: "Worker_1.outstanding_demand = 18 (decayed from 22)" tells a different story than "Worker_1.outstanding_demand = 14 (reset to this week's need)."

---

## R6 — Merchant break-even floor

**Position: name Merchant.min_retail_margin on MercantileInterest, set to 0.0 for v0. Seam is load-bearing; value is not.**

"Merchant goes bankrupt because demand is too soft" is absolutely a v0-era story — eventually, when the player manipulates supply. When a player restricts grain, P* spikes, Merchant marks up, workers can't afford grain, demand collapses, P* drops below Merchant's cost basis — that's a three-act cascade. The third act requires min_retail_margin to exist as a seam even at 0.0, or we can't print "Merchant is selling below cost" when it happens.

Name the field. Guard in clearing math. Value 0.0.

---

## R7 — Single vs multi-merchant scope for v0

**Position: (a) single-merchant math + strategy enum scaffold.**

The v0 trace doesn't need multi-merchant to feel right. It needs the price formula to produce a legible number and the affordability story to print clearly. Both work with N=1. What the scaffold *does* need: enum entries with stubbed bodies for all named strategies, because naming them now is costless and renaming later is expensive. See strategy vocabulary below.

---

## R8 — δ_wholesale calibration value

**Position: δ_wholesale = 0.0 for v0.**

Isolate the retail math first. With δ_wholesale = 0.0, the v0 trace tells one story: the merchant's markup is the only margin in the system. When δ_wholesale turns on, note in the directive that combined markup is (1 + δ_w) × (1 + δ_r), not additive. One sentence is enough.

---

## Multi-merchant strategy vocabulary (my territory)

The ClearingStrategy enum for RetailMarket needs these entries, even if most bodies are stubs:

```gdscript
enum ClearingStrategy {
    PROPORTIONAL,       # v0 wired: each demander gets Q_p × (my_demand / total_demand)
    FIFO,               # stub: demand-arrival order
    SUPPLY_LADDER,      # stub: merchants sorted by P_m ascending; consumers fill from cheapest
                        #       until that merchant's inventory is exhausted, then overflow to next
    MARKET_PERCEPTION,  # stub: consumers sorted by perception skill descending; high-perception
                        #       actors find the cheapest available stall first
    CHARISMA_FAVOR,     # stub: merchant preference — high-CHA actors get priority fill from a
                        #       merchant, regardless of queue position
    BARTERING,          # stub: high bartering skill reduces effective P_m for that actor;
                        #       they pay less per grain than other demanders at the same stall
}
```

**These are distinct concepts, not substrategies.**

SUPPLY_LADDER is a *market structure* strategy — it describes how competing merchants are ordered. It belongs to the market. The supply-ladder × consumer-rank sketch from the author's notes is SUPPLY_LADDER combined with MARKET_PERCEPTION: merchants sorted by P_m, consumers sorted by perception skill. Two enum entries that combine at runtime, not one entry with sub-options.

MARKET_PERCEPTION is search-cost reduction (Mary's framing is correct). A high-perception actor "finds" the cheapest stall first. In v0 single-merchant this does nothing. The seam exists for phase 3.

**CHARISMA_FAVOR and BARTERING are separate axes:**

CHARISMA_FAVOR affects fill *priority* — a merchant who likes you serves you before other customers of equal standing. This is the merchant's decision, driven by the actor's CHA stat. High-CHA actors get first pick from a favored merchant. This is social capital as market access.

BARTERING affects *price paid* — a skilled barterer pays less per unit at the posted stall. Mechanically: `effective_P_m = P_m × (1 − barter_discount(bartering_skill))`. The actor still goes to the same stall but pays a different rate. This is economic skill as margin compression.

The player-facing distinction: Charisma gets you to the front of the line. Bartering gets you a better deal once you're there. A high-CHA low-BARTERING actor gets served first but pays full price. A low-CHA high-BARTERING actor waits their turn but pays less. Both are interesting characters. They should not be the same enum entry.

Phase 3 wiring: CHARISMA_FAVOR reads `actor.accounts.skills.get("charisma", 0.0)` to sort the demander queue. BARTERING reads `actor.accounts.skills.get("bartering", 0.0)` to compute a per-actor price discount before coin transfer. Neither requires changes to the clearing seam — just different reads inside the strategy body.

**What v0 should wire:** PROPORTIONAL only. The others get enum entries and empty stubs with a comment: `# phase 3: wire to skill reads`.

---

## S-questions (S1–S4)

Cloud has the architecture lead. One flag per question:

**S1:** Option (iii) — DemandCurve on GoodConfig — is the shape I'd want long-term. The design move to preserve: a lord who has upgraded workers' "grain quality expectations" should be able to raise A without touching the good config. That argues for per-actor multiplier seam from day one, even if v0 multiplier is 1.0.

**S2:** RetailMarket.compute_equilibrium_price(). No objection.

**S3:** Per-merchant on MercantileInterest. Design move that requires this: future merchant who price-discriminates by customer relationship. That only works if P_m computation lives on the merchant.

**S4:** Cloud calls it. My only constraint: strategies should be swappable at runtime without a code deploy. The author testing "what if this market runs FIFO" is a design experiment that should cost a config change, not a rebuild.

---

## What I'd want to be sure of before the directive's Section 2 is drafted

The game-feel risk that would bite hardest: the v0 trace reads as a math exercise rather than a world. "supply=56, demand=53.9, price=1.10" is correct but inert. What makes retail matter is the human side of the ledger — "Worker_1 placed demand for 14 grain, could afford 9, received 9; 5 outstanding." If the directive specifies the equilibrium formula without specifying the *print surface* of the affordability failure, the implementation will produce correct numbers and a dead trace. Before Section 2 is drafted, I want the trace expectations section to include the exact format of the affordability failure line — not just the math, but the sentence the player or a watching developer reads when a worker can't eat. That sentence is where this game lives.
