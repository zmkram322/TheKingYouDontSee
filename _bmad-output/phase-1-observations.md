---
name: Phase 1 Observations
status: notes-in-progress
date: 2026-05-02
purpose: Capture observations from the Phase 1 prototype before Phase 2 (math/clearing). Will be fed to party-mode along with the prototype scripts to produce a directive artifact for the next coding pass.
---

# Phase 1 Observations

## Briefing for the next session

### Goal of the session

Use these observations + a read of the actual prototype code to run **party-mode** (multi-agent architectural critique) and produce a **directive artifact** for the Phase 2 coding pass. We are NOT implementing math/clearing in this session. We are deciding what the architecture should look like *before* math goes in. Math/clearing is a subsequent session.

### What to read, in this order

1. **This file (`_bmad-output/phase-1-observations.md`)** — observations and open questions. The `What feels off`, `Surprises`, and `Questions to put to party-mode` sections are the load-bearing ones. The questions are deliberately open; party-mode is being asked to take positions, not just summarize.
2. **`_bmad-output/prototype-build-spec.md`** — canonical Phase 1 spec. The intent we built against. It's been built; the question now is whether the spec's design itself needs revision before Phase 2.
3. **`tkyds-game/scripts/`** — the actual Phase 1 implementation. Read enough of it to ground claims in concrete files (`actors/`, `interests/`, `markets/`, `autoloads/`, `bootstrap/`). Don't accept claims about the code without checking — the observations in this file are the author's read, not necessarily the ground truth.
4. *(Optional)* `_bmad-output/gdd.md` — higher-level design context. Useful if a question turns on world-design intent.

### Background party-mode should hold while reading

- **Phase 1 ran cleanly.** A 14-day simulated run produces ~728 lines of correctly-ordered console trace. The bus / orchestrator / window architecture works. No errors, no warnings.
- **Phase 1 is print-only.** Methods print what they would do. There is one small exception: `LaborMarket.clear()` actually creates `LaborContract` instances and assigns them to workers — just enough state mutation to make day 2+ daily prints legible (without contracts, work_state never enters WORKING and the daily flow is silent). No grain or coin actually moves.
- **The break-point we're at.** Phase 2 was originally going to drop in math against the existing class shapes. The author has surfaced architectural concerns that, if valid, mean the class shapes themselves should change before math lands. That's what this session is for.
- **Author preferences.** Plain-English method names; no CS-textbook jargon (`dispatch`, `transition_to`, `_on_enter`, etc.). Composition over inheritance is the leaning, but it should be earned, not asserted.

### What's to be evaluated

The questions in `Questions to put to party-mode` below. Specifically:

1. **Composition vs. inheritance for Actor identity.** Worker / LandOwner / Merchant subclasses, or Actor-only with role being a description of the current Interest+Resource bundle? What does that imply for `_wire_signals()` ownership — Actor or Interest?
2. **Interest decomposition.** Is `ProductionInterest` overloaded? Should `EmployerInterest` exist as a separate concern? Does the proposed *resource-shaped vs. market-shaped Interests* pattern hold up, or is it overfitting?
3. **Generic dispatch pattern.** How do Interests declare what signals they care about? What's the verb? Tradeoffs between named methods (readable at call sites) and generic dispatch (composable).
4. **Concrete bug.** `ProductionInterest.post_jobs()` ignores filled positions. Trivial fix, but where the fix lives depends on Q2.
5. **Print labeling.** Daily-vs-weekly pool semantics — small but worth a recommendation.

### What we want out of the session

A directive artifact at `_bmad-output/phase-2-architecture-directive.md` that:

- **Takes a position** on each question above (not "consider both options"; pick one and justify briefly).
- **Lists concrete refactor steps** for the Phase 2 coding pass: file moves, class renames, method relocations, signature changes. Specific enough that a coding agent can execute it without re-deriving intent.
- **Calls out anything party-mode wants the author to confirm** before code starts moving — e.g. "we recommend X but it conflicts with build-spec line Y; confirm before proceeding."
- **Stays scoped to architecture.** Math, clearing logic, and acceptance-criteria work belong to the session after this one.

---

## What works as expected


## What feels off (architecture, naming, signal flow, ordering)

### Interests array vs. typed slots — composition is leaking
GrainInterest should technically be part of the `interests` array, not a special-cased typed field on Actor. Right now it's stored both ways (`grain_interest: GrainInterest` AND `interests: [working, grain]`), and the Actor handlers special-case each interest by name (`grain_interest.place_grain_order`, `working_interest.do_one_work_slot`).

We need a default method that **applies / runs / exercises / ??? interests** — verb TBD; this is the question I want party-mode to weigh in on. Specific named methods are fine for clarity at call sites, but the dispatch itself should be composition-based: each Interest knows which signals/slots it cares about and what to do, and the Actor just iterates and asks each interest to do its thing. That way adding a new Interest is one file, not edits to every Actor subclass.

### Actor subclasses are inheritance, not composition
The Worker / LandOwner / Merchant subclasses are inheritance-based identity, but identity in this world should be fluid — an Actor can switch from worker to merchant, or be both. The "tasks specific to a LandOwner" (post_open_jobs, send_supply_to_wholesale, pay_outstanding_wages) aren't really LandOwner traits — they're consequences of having particular Interests. Strip the Interest off and the tasks should disappear with it.

The cohesion/coupling case worth designing around:
- **Actor with ProductionInterest but no LandPlot** → fine, production has no input, nothing produces
- **Actor owning a LandPlot but no ProductionInterest** → also fine, land just sits there

Both should be valid states. The role label ("worker", "merchant", "land owner") should be a *description* of the Interest+Resource bundle, not a class. This probably means the actor.gd / worker.gd / land_owner.gd / merchant.gd subclass split is wrong; signal wiring should come from Interests, not from Actor subclasses overriding `_wire_signals()`.

### "Employer" is its own concern, separate from "produces on land"
`pay_outstanding_wages` is currently on `LandOwner` directly. But it isn't a LandOwner trait — it's a consequence of *being an employer of workers*. Same for `post_open_jobs`: the act of hiring is "I have an EmployerInterest", not "I have a ProductionInterest". A merchant who employs shop hands needs the same wage-settlement behavior; a self-employed producer who works their own land needs the production behavior without the employer behavior.

Proposed split for party-mode to evaluate:

| Current | Proposed |
|---|---|
| `ProductionInterest.post_jobs()` | `EmployerInterest.post_open_jobs()` (driven by labor_market_opened) |
| `LandOwner.pay_outstanding_wages()` | `EmployerInterest.pay_outstanding_wages()` (driven by wages_due) |
| `ProductionInterest.send_grain_to_wholesale()` | stays on ProductionInterest (or moves to a `WholesaleVendorInterest` — open question) |

A pattern starts to emerge: each Interest is a relationship between this Actor and one part of the world. Two flavors:
- **Resource-shaped Interests** — "I own/work a productive thing" (ProductionInterest with a LandPlot)
- **Market-shaped Interests** — "I participate in market X in role Y" (WorkingInterest = LMW seller side, EmployerInterest = LMW buyer side, MercantileInterest = WMW buyer + RMW seller, GrainInterest = RMW buyer)

If that pattern holds, MercantileInterest itself probably wants to split into a WMW-side and an RMW-side, but that's a refinement to defer until party-mode confirms the framing.

### LaborMarket demand is static, not based on filled positions
Every day the LandOwner posts `open_positions=2`, even after both workers have active contracts. The spec actually says "open positions = desired_workers - filled" but `ProductionInterest.post_jobs()` currently uses `desired_workers` directly. Fix: subtract count of active contracts pointing at this employer (or count of filled slots tracked some other way). Probably the static `desired_workers` constant approach is what's hiding this — should be derived from current state.


## Surprises in the console output

### WMW / RMW window prints — observed missing on the daily flow
First read of the output: I don't see WholesaleMarket open/close/clearing or RetailMarket window opening/clearing/closing prints; looks like demand is being processed as it's emitted.

*(Verified after the fact: the open/close/clear prints DO fire, but only on day 7 and day 14 during the weekly burst — daily `take_supply`/`take_demand` calls accumulate into the pools, weekly close fires the clear. The daily prints make pool accumulation look like processing because the verb "take_demand" reads like "consume demand" rather than "queue demand into pool". This is a labeling/UX-of-prints concern more than a logic bug — phase 2 should make the difference between "queued to pool" and "cleared / actually transacted" obvious in the trace.)*


## Gaps the spec didn't anticipate


## Questions to put to party-mode

1. **Generic interest dispatch + actor identity.** What's the right shape for Actor → Interest dispatch so it's composition-based instead of named-method-per-Interest? What's the right verb (apply / exercise / run / tick / act-on / drive / something else)? How do Interests declare which signals they care about — subscription registry inside each Interest, or a manifest the Actor reads at wire time? And the deeper question this opens: should Worker/LandOwner/Merchant exist as Actor subclasses at all, or is "Actor" the only class, with role being just a label for the current bundle of Interests + owned Resources? How do you handle cohesion/coupling so that ProductionInterest-without-LandPlot and LandPlot-without-ProductionInterest are both clean valid states (and Actor-switches-from-worker-to-merchant is a runtime swap, not a re-typing)? Trade-offs in readability, testability, and the spec's "the actor is the sum of its interests" framing.

2. **LaborMarket demand correctness.** Is "filled positions" tracked on the LandOwner (count of active LaborContracts), on the LaborMarket (registry of who's hired), or derived on demand? Phase 2 will need to answer this when wages_due actually walks contracts.

3. **Daily-vs-weekly pool legibility.** How should the prints distinguish "demand queued into a weekly-clearing pool" from "demand cleared, transaction happened"? Affects observability without affecting the architecture.


## Candidate Phase 2 changes (before math)

- Generic interest-dispatch pattern (depends on party-mode answer)
- Fix `ProductionInterest.post_jobs()` to subtract filled positions
- Tighten print labels so daily pool-accumulation is visually distinct from weekly clearing


## Notes on the math/clearing pass itself


