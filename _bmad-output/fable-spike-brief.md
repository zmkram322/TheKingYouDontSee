# Spike Brief — Social Layer Prototype

*Work order for an exploratory coding pass. Authored 2026-07-27. Target: a runnable prototype of the PRD's proving scene, plus a written record of the decisions the code forced.*

---

## 0. What this pass is for

**The product of this spike is understanding, not shippable code.**

The design is well specified at the *what* level (see `_bmad-output/planning-artifacts/prd.md`) and unspecified at the *how* level. Rather than write an architecture document against guesses, we want to see the systems actually programmed, and find out where the model has to be made concrete.

Two deliverables, and the second matters at least as much as the first:

1. **A running prototype** of the proving scene (§2).
2. **A decisions document** — every place you had to make the model concrete, what you chose, what the alternatives were, and how confident you are. Including the places where the PRD is wrong, incoherent, or silent.

You are expected to finish with a list of things we got wrong. If you finish without one, you were being too polite.

---

## 1. The game, in three sentences

A living medieval kingdom where nothing is scripted and everything is scored. The player begins powerless and climbs until their decisions propagate through people they never personally touch — **power is defined as how many people fall under the shadow of your decisions.** The skill is reading people and orchestrating consequence; there is no combat execution.

---

## 2. What to build — the proving scene

One scene, exercising the whole spine at depth 1:

1. The player, living in a needs substrate (hunger → food → labour → money), earns coin and makes a small **direct investment** in actor A — which raises a channel A holds toward the player.
2. Later in the same scene, actor B escalates against the player. The player is **outmatched**; drawdown begins.
3. The player's **demand for aid is emitted by the sim** — not commanded by the player.
4. **A, in proximity and now held, resolves it** — visibly, attributably, after a beat that reads as a decision rather than a trigger. A must be able to refuse.
5. B's evaluation changes; aggression subsides.
6. **If the player did not invest — or invested in the wrong actor — nobody resolves the demand and the player yields.**

**What must be true for the spike to count:**

- **No goals exist anywhere in this scene.** Not for the player, not for A, not for B. B escalates from *state* (disposition, opportunity against a weak target). If you find yourself authoring a goal to make B aggressive, the substrate is not doing its job and that is a finding worth reporting.
- **The fail branch must actually fail.** A scene where the good outcome happens regardless proves nothing.
- **A's decision must be genuine** — a real evaluation that could have gone the other way, not a threshold trip dressed up in prose.
- **Two actors must differ in what they want.** The player should be able to invest in the wrong person. This is the seed of the whole reading game (see §5, per-actor drivers).

The fiction — a pub, a drink, names — is disposable. The *structure* is the requirement.

---

## 3. Codebase reality (verified 2026-07-27)

Branch `poc-v2`. **666 lines total**, four files. Read all of it; it fits in context.

| File | Lines | What it is |
|---|---|---|
| `tkyds-game/sim/actor.gd` | 42 | Plain data. Public fields: `hunger`, `food`, `coin`, `willingness`, `role`, producer bookkeeping. |
| `tkyds-game/sim/demand.gd` | 36 | The atom. Four kinds: `FOOD`, `ROLE`, `BUY_GOOD`, `EMPLOYMENT`. |
| `tkyds-game/sim/simulation.gd` | 412 | Tick loop, four hand-written resolvers with phase state machines, tunable-constants block. |
| `tkyds-game/main.gd` | 176 | Debug UI: step / step-5 / reset buttons, actor panel, demand queue panel, event log. |

**What exists and works:** the demand-resolver atom — a demand hits a resolver each tick; the resolver satisfies it or emits a child demand and waits. A food/labour/money economy bootstraps its entire supply chain from an all-idle start with **zero authored goals**. This is real, observed behaviour, not a claim.

**What does not exist — all of it greenfield:**

- **No stat accessor.** `get_primary` / `get_derived` / `write_primary` — zero occurrences. Everything reads `a.hunger` directly off public fields.
- **No social layer whatsoever.** No relationships, edges, standing, channels, trust, or disposition. Grep for standing/relation/social/trust/loyal/fear/channel returns nothing.
- **No derived stats.** No caching, no versioning, no derivation of any kind.
- **No utility scoring.** The four resolvers are hand-authored phase machines, not scored choices.
- **No player.** The sim is fully autonomous; no input, no LOOK/GREET verbs.
- **No time of day.** Integer ticks, manually stepped.

**Useful as-is:** the debug UI is already close to the prototype presentation the design calls for (portraits/icons/text, no floating bars). Build onto it rather than replacing it. The `# --- Tunable feel constants ---` block in `simulation.gd` is the pattern to follow.

---

## 4. Your authority, and the open architecture question

**You have authority to design these systems as you judge best, including restructuring what exists.** Design them elegantly. Do not preserve current structure out of deference.

**The central open question, explicitly delegated to you:**

> The PRD's FR1 says actors run "one shared **utility-AI loop** over primary and derived stats." The code is a **demand-resolver** with hand-authored phase machines. These are different architectures, and the PRD conflates them.

The author's own instinct, passed on verbatim: *"the demand resolver may be getting in the way of better code based on what we're trying to build here."*

So: **decide, and justify.** Extend the resolver, add utility scoring alongside it, subordinate one to the other, or replace the atom outright. All are on the table.

Two things to weigh honestly before discarding the resolver:

- **What it bought is evidence, not theory.** An economy assembling itself from nothing, with no triggers and no goals, is a real property that a naive utility loop does not automatically give you. Understand *why* it works before replacing it.
- **A possible reconciliation, offered as a hypothesis to test rather than a mandate:** a demand may be the right representation of *unmet need*, with **utility deciding who picks it up**. The design's central claim about acting through others is "delegation is provider-matching where the provider chose you" — which reads as provider-matching filtered by social state. If that composes cleanly in code, both mechanisms survive with distinct jobs. If it doesn't, say so plainly; that is exactly the kind of finding this spike is for.

---

## 5. Hard constraints

Few, and each has a reason. Everything not listed here is yours.

**1. All stat access goes through a narrow accessor.**
`get_primary` / `get_derived` / `write_primary` — nothing else touches storage, ever. Backing store can be the humblest thing that works.
*Why, and why this overrides what you see:* the existing code does the opposite, and normally you should follow local convention. Not here. This boundary is what lets storage graduate (Dictionary → packed arrays → native) without rewriting call sites, and the design docs identify it as the single wall that, if wrong, forces a month-long rewrite. **Retrofitting the existing 666 lines is in scope and encouraged.**

**2. No hard-fail states, and no categorical overrides.**
Motivation is a composite of competing drives. Survival **outbids** — weighted steeply enough to dominate in the common case — but never *overrides* by rule.
*Why:* a hard survival override was built once and deadlocked the sim; that build never recovered. It also creates actors who cannot be moved, which contradicts the premise that everyone has a price.

**3. No code may name a playstyle.**
No `coercer`, `patron`, `spymaster`, `warlord` in any identifier, branch, or filename. Path-specific needs become generic primitives that at least two hypothetical paths could use, or they don't ship.
*Why:* it is the only thing keeping several data configurations from becoming several codebases. It's a grep and a habit.

**4. Every invented tuning value goes in one marked constants block.**
You will have to invent many (drawdown rate, yield threshold, proximity radius, accrual per favour, decay rates, trust update, action-decision threshold). Invent freely — but they must be visible in one place and named, not scattered as literals.
*Why:* the author tunes these by hand, and they are the difference between the scene working and not.

**5. Discrete, categorical relationship readouts.**
Any state the player is meant to notice changes in **rungs**, never a continuous gradient. Intensity, when it matters later, belongs in a separate channel.
*Why:* a continuous value is an unreadable volume knob, and the entire legibility pillar depends on deltas being perceptible.

---

## 6. Strong defaults — deviate if you have a reason, and say so

- **Derived stats are computed, not stored** — recomputed on read against a dirty-stamp, so they are never stale but never recomputed for everyone every tick.
- **The social graph is sparse with inheritance** — store only *deviating* relationships as explicit edges; everything else inherits a faction-level default. The player may be a high-degree hub; a dense mesh is the failure mode to avoid.
- **Channel persistence has two shapes.** *Transactional* — evaluated against the actor's current state, held only while relieving a currently-unmet need, computed rather than stored. *Accrual* — accumulates on the relationship edge and decays slowly. Which shape applies is a property of the **driver**, not of the actor.
- **Per-actor drivers.** Different actors' channels run on different needs — one on wealth above a threshold, another on standing, another on safety. This is not flavour; it is the content of the reading skill, and it is what lets the player invest in the wrong person.
- **Headless-first.** Get it correct in the sim with log output, then surface it in the existing debug UI. Presentation should read semantic signals from the sim, never own state.

---

## 7. What to decide and report

The decisions document should cover at least these. Each is currently unspecified, and each is a real design question the code forces:

1. **The architecture question** (§4) — what you chose and why.
2. **Tick and time model.** Existing ticks are discrete manual steps; the scene spans minutes. Same tick? Real-time or stepped? This was flagged in the design notes as unresolved and "load-bearing for feel."
3. **The action set.** What is an "action," concretely, and what is the minimum set for this scene?
4. **Conflict resolution.** What stats contest, at what rate does drawdown accrue, what triggers yield?
5. **Demand emission for aid.** What emits it, at what threshold, with what proximity rule, and how are candidate providers ranked?
6. **Channel maths.** What a favour is worth, decay rates, and how a held channel enters an actor's evaluation.
7. **Driver inference surface.** What the player can actually perceive that lets them infer what an actor needs.
8. **Where the player sits.** Is the player an `Actor` running the same loop with an input seam, or something else? The design wants "same loop"; find out what that costs.
9. **Anything in the PRD that turned out to be incoherent, unbuildable, or silent** when you tried to write it.

---

## 8. Out of scope

Do not build: routes or value-chains; installed goals, cascade, or hierarchy; trust and promotion; information agents; promote/collapse LOD; far-region tiers; save/load; 3D or art; narrative content beyond the minimum to make the scene legible.

Several of these are specified in the PRD as later phases. They are listed here so you know they exist and can leave seams where cheap — **but leaving a seam must not cost you elegance now.** A clean thing that needs extending later beats a general thing that does nothing yet. The project has been burned before by abstraction machinery built ahead of a proven loop.

---

## 9. Reading list, in order

1. `_bmad-output/planning-artifacts/prd.md` — read **Core Mechanical Model**, **Product Scope**, **Explicit Non-Goals**, **Functional Requirements** (FR1–FR83), **Non-Functional Requirements**, and **Journey 1**. These are current.
   **Skip or treat as stale:** Journeys 2–4, Domain-Specific Requirements, Innovation & Novel Patterns, Game-Specific Requirements, Project Scoping — all still carry superseded single-pass draft content. *(Game-Specific does contain architecture considerations, but it predates the Core Mechanical Model; §5 above supersedes it where they disagree.)*
2. `tkyds-game/` — all 666 lines.
3. `_bmad-output/poc-v2-system-spirit.md` — the substrate tenets and, more usefully, the open tensions at the end. Note which tenets are marked *evidence* versus *belief*: the economy bootstrapping is observed; plural drivers are assumed. Weight them accordingly.
4. `_bmad-output/design-session-2026-07-24-social-political-layer.md` — §3 (legibility), §4 (onboarding), §7 (architecture), §8 (off-screen truth). **§1 is marked superseded in-source; §0, §10 and Next Steps still carry the superseded framing and have not been cleaned up.** Read §1's re-litigation note before trusting anything else in that file about leverage.

---

## 10. The one-line version

*Build the proving scene. Redesign whatever needs redesigning to do it well, including the atom. Put every invented number in one block, run every stat through an accessor, and come back with the list of things the PRD got wrong.*
