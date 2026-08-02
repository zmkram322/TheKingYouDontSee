# Refactor Brief — Decision-Model & Eligibility Pass

*Work order for a fresh coding session. Companion to `fable-spike-brief.md` and `fable-spike-decisions.md`. Authored 2026-07-27 (session 2). Target: refactor the shipped proving-scene code onto the decision model the PRD now specifies, plus a written record of what the refactor forced.*

---

## 0. What this pass is for

**This is a refactor, not a fresh spike.** Same proving scene, same codebase (`poc-v2`, `tkyds-game/`). The first spike (`fable-spike-brief.md`) built the scene and reported its findings (`fable-spike-decisions.md`). Those findings — specifically that FR1 described neither the shipped economy nor the code you wrote — went to a party-mode architecture roundtable (four independent agent perspectives, two rounds) and then to the PRD author directly. The result is a settled decision model, now written into the PRD, that this pass implements and pressure-tests.

**You are not the one deciding the architecture this time — you're the one finding out if it holds.** Build it, and report every place it doesn't.

Two deliverables:

1. **Refactored code.** The existing ~1,460 lines brought into line with the model in §1. This is not precious — you wrote most of it three days ago as a spike. Restructure freely where the new model calls for it. Do not preserve current structure out of deference.
2. **A decisions document** (`fable-refactor-decisions.md`) — same spirit as last time: what you had to make concrete, what surprised you, and what in the PRD — now twice-revised — is still wrong, incoherent, or silent. If you finish without a finding, you were being too polite.

---

## 1. Where we landed (read this before touching code)

The PRD (`_bmad-output/planning-artifacts/prd.md`) now specifies, in **Core Mechanical Model** and **FR1, FR84–FR87**:

- **One shared weighted-scoring pass, three decision points.** Not "utility loop vs. demand queue" as competing architectures. An actor's decision — whether to *pursue* an unmet need, whether to *answer* another actor's unmet need, or whether to take an immediate *contested action* — all score through the same weighted pass over that actor's current stats.
- **A demand is a re-derived read, not a persistent object with memory.** The thing that persists is the underlying *stat* (hunger keeps decaying whether or not anyone's addressing it) — "still wanting X" is recomputed fresh at each check, the same way a derived stat is lazy-with-version rather than stored. Your `Demand` class currently carries `phase`, `backers`, `child`, `satisfied` — some of that is legitimate in-progress-resolution bookkeeping (see §3c); some of it may be storing something a derived read should be giving you for free. Find out which.
- **Eligibility gates the candidate pool — goals never do.** Before anything is scored, filter to the actions an actor is eligible for: a cheap, structural precondition (role/faction/possession/position), not a scoring judgement. A **protected universal core** — survival and direct interpersonal actions (eat, flee, confront, beg, steal, hold ground) — is eligible to *every* actor, always, and cannot be excluded by any predicate. Specialised actions (a throne claim, a guild vote) declare their own eligibility as data. Goals bias weight *within* whatever pool eligibility already produced; they never add or remove eligibility.
- **Survival outbids by weight, never by a checked-first gate.** This was already true in the PRD, now stated more precisely: all competing drives score in the *same* pass. If a threshold produces flicker, the fix is a two-threshold hysteresis band on that stat (data), never a priority branch and never a memory mechanism.

None of this is proven in code. It was designed and locked by a roundtable working from your own §9 findings, not built. That's this pass's job.

**Read, in order:** `prd.md` → Core Mechanical Model in full (especially "The atom," the new "Eligibility" subsection, and "Arbitration"), FR1–FR14, FR84–FR87, the Performance NFR, and the Game-Specific "Technical Architecture Considerations" bullets on eligibility-as-a-seam and demands-have-no-persistence-layer. Then `fable-spike-decisions.md` in full — read it for the *evidence*, not the conclusion; §1's proposal ("demand = persistent memory of unmet need") is the thing the roundtable revised, and understanding why will save you from re-deriving the same dead end.

---

## 2. Codebase reality (verified 2026-07-27, session 2)

Branch `poc-v2`. **1,462 lines, eight files** — up from 666/four at the first spike:

| File | Lines | What it is |
|---|---|---|
| `tkyds-game/sim/actor.gd` | 27 | Plain data. |
| `tkyds-game/sim/demand.gd` | 41 | The atom. Six kinds now: `FOOD`, `ROLE`, `BUY_GOOD`, `EMPLOYMENT`, `PRESS`, `AID`. |
| `tkyds-game/sim/simulation.gd` | 823 | Tick loop, resolvers, phase machines, `_press_score` / `_aid_score`. |
| `tkyds-game/sim/stats.gd` | 35 | Stat name constants. |
| `tkyds-game/sim/stat_store.gd` | 108 | The accessor — `get_primary` / `write_primary` / `get_derived`, sparse storage, lazy-with-version derived cache. |
| `tkyds-game/sim/tuning.gd` | 74 | The one constants block. |
| `tkyds-game/main.gd` | 252 | Debug UI. |
| `tkyds-game/tests/headless_scene.gd` | 82 | Proves the proving scene's three branches headless. |

**What exists now that didn't at the first spike:** the narrow stat accessor is real and in use; a named tuning-constants block; a headless test harness. Good foundations — keep them.

**What's still one-off, not generalised:** `press` and `aid` are scored by two dedicated functions (`_press_score`, `_aid_score`), not through any shared eligibility-then-scoring surface — there is no eligibility mechanism anywhere in the code (grepped: zero occurrences of eligibility, precondition, or candidate pool). Notably, `Demand` already has `PRESS` and `AID` as kinds sitting alongside the economy's four — worth understanding *why* that shape was chosen before deciding whether it survives under the new model, or whether it's quietly conflating "an in-progress resolution that needs sequencing" with "the moment-to-moment decision to act," which the PRD now says are different things.

---

## 3. What to build

**a) A real eligibility check ahead of scoring.** Every action — the four economy demands and press/aid, however you end up carving them — gets an optional precondition, defaulting to universally-eligible. Make the protected-core guarantee a property you can point at, not just an intent: e.g., a test asserting a peasant-role actor still scores press/confront/flee/eat every tick, untouched by any role tag.

**b) One shared scoring surface for pursue / answer / act — if it composes.** This is the same reconciliation the first brief left open, now with a concrete target instead of a hypothesis. Try it. If it composes cleanly, show it. If it doesn't — if press and the economy genuinely need different shapes — say so plainly and explain why, the way you called out FR1 last time. A clean "it doesn't compose, here's the real boundary" is exactly as valuable as making it fit.

**c) Confirm or break the demand-as-derived-read claim.** Show that "still hungry" needs nothing beyond the hunger stat itself — no separate stored intent — the same way the derived-stat cache already proves staleness isn't a problem. Where `Demand`'s extra fields (`phase`, `backers`, `child`) turn out to be genuinely necessary, that's fine — they're sequencing state for a resolution already in flight, which the PRD's Core Mechanical Model still keeps ("phases stay"). Where they're not — say which ones and why.

**Optional, only if cheap:** your own decisions doc flagged multi-driver arbitration as never having been forced (§9.7 — nothing yet competes hard enough to test "weighting, not override" for real). If the eligibility work naturally surfaces a second competing drive, take the shot. Not a requirement.

---

## 4. Constraints

**Carried over, unchanged:**
- All stat access through the accessor. (Already true — keep it true.)
- No hard-fail states, no categorical overrides. Survival outbids by weight; a hard-checked gate deadlocked the sim once already and stays dead.
- No code may name a playstyle.
- Every invented tuning value in the one constants block.
- Discrete, categorical relationship readouts — never continuous.

**New this pass:**
- **Eligibility is a data field, not a system.** An optional predicate on each action definition, default true. Do not build a general tag-resolution or pool-caching framework this pass — the PRD's own architecture note says ship the seam, defer the system, and the current action count doesn't justify more than that.
- **The protected universal core is not negotiable.** If your refactor makes it possible to author an action that excludes something like `flee` or `confront` from some role, that's a defect against FR86, not a design choice.

---

## 5. Out of scope

Same as the first brief: no routes/value-chains, no installed goals/cascade/hierarchy, no trust/promotion, no information agents, no LOD, no far-region tiers, no save/load, no art.

Also out of scope this pass: the **proximity/space model** (still a stub — `fable-spike-decisions.md` §9.6 — leave it alone unless eligibility work genuinely forces the question) and **demand expiry/abandonment** (§9.4 — mention it in the decisions doc if it blocks you, but it's not a build target unless it turns out to be cheap).

---

## 6. What to decide and report

1. **Did the three decision points actually become one scoring surface**, or did press/aid stay structurally distinct from the economy? Either answer is a valid finding — report which, and why.
2. **Is `Demand`'s extra bookkeeping legitimate phase-sequencing, or partly redundant** with what a derived read now gives you for free?
3. Whatever you found trying (or not trying) to force multi-driver arbitration.
4. Anything in the PRD — now revised twice — that's still wrong, incoherent, or silent when you tried to build against it.

---

## 7. The one-line version

*Build the eligibility-then-scoring model the roundtable settled on, on top of the codebase your own first spike produced. Treat that code as disposable. Come back with what still doesn't hold.*
