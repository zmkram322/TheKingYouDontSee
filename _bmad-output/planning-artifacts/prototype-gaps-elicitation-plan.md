# Prototype Gaps — Party Mode Elicitation Plan

**Trigger:** Epic 1 emergence proven. Prototype surfaced design gaps that must be resolved before the formal architecture session runs.

**Format:** `/bmad-party-mode` with Cloud Dragonborn, Samus Shepard, and Indie. One gap per round. Facilitator drives questions; agents disagree freely.

**Output:** A supplement document (`supplement-prototype-gaps.md`) capturing decisions on each gap — input to `/gds-game-architecture`.

---

## Gap 1 — NPC Decision Model

**What the prototype exposed:** `LaborPlanningProcessor` uses a single AND condition (hunger ≥ 0.8 AND restfulness ≤ 0.2). Strike never triggers in practice because both thresholds must be hit simultaneously. Real NPC behavior needs multiple axes and a resolution function.

**Questions to put to agents:**
- What are the decision axes for a worker? (hunger, wages vs. cost-of-living, morale, peer pressure, memory of recent treatment)
- Is the decision function a weighted sum, a priority stack, or a threshold ladder?
- How does social contagion work — does one striking farmer lower the threshold for neighboring farmers?
- How much of this is data-driven (archetype config) vs. hardcoded logic?
- What is the minimum decision model that produces the 5 emergence behaviors from the spec?

**Decision needed:** A decision function shape — not an implementation, just the inputs, weights, and resolution rule that processors will evaluate.

---

## Gap 2 — Actor State Decomposition

**What the prototype exposed:** `ActorState` mixes economic floats (`grain`, `coin`), needs state (`hunger`, `restfulness`), contract state (`employer_id`, `wage`), and role-specific fields (`tax_rate`, `target_margin`, `land_area`) in one flat resource. Fields with different update cadences and owners sit next to each other with no separation.

**Questions to put to agents:**
- What are the natural decomposition boundaries? (economic, needs, contract/relationship, behavioral/decision)
- Do different concerns warrant separate Resource subclasses, or a single resource with grouped sections?
- Which fields update on `day_tick` vs. `week_tick` vs. `event_interrupt`? Does that cadence difference drive the decomposition?
- How do role-specific fields (lord tax rate, merchant margin) get handled — subclasses, or an archetype config resource that actors carry?
- What does a fully-specified actor look like in memory for Epic 2 vs. prototype?

**Decision needed:** A decomposition boundary map — which fields belong together and why, what the top-level Resource shape looks like for Epic 2.

---

## Gap 3 — World Construction Grammar

**What the prototype exposed:** The prototype hard-seeds 3 actors with hand-tuned values. The GDD describes lords, stewards, workers, and regions but never specifies how a world seed produces them. The architecture can't design a `SimWorld` Autoload or a fidelity tier manager without knowing the construction shape.

**Questions to put to agents:**
- What does a world seed produce first — lord network, regional resource profiles, or both simultaneously?
- How is the lord hierarchy typed and configured? Is each lord an `ActorState` with an archetype resource, or a separate `LordState` subtype?
- How do regional resource profiles (grain supply, trade routes, population density) constrain the actors instantiated into them?
- What is the minimum world construction needed for Epic 2's multi-market dynamics?
- How does burn-in differ when running at regional fidelity (aggregate floats) vs. full actor fidelity?

**Decision needed:** A world construction sequence — what gets created in what order, what drives each step, and what data structures the construction process writes into.

---

## Gap 4 — Actor Archetype Extensibility

**What the prototype exposed:** `LaborPlanningProcessor` checks `ActorState.Role.FARMER` directly. When there are 12 lord archetypes with different behavioral weights, role-switching inside processors doesn't scale. There's no mechanism for behavioral configuration separate from the processor logic.

**Questions to put to agents:**
- Should archetypes be a data resource that actors carry (archetype config loaded at instantiation) or a strategy object that processors look up?
- What behavioral properties vary by archetype vs. what is universal to all actors?
- How does a new archetype get added without modifying existing processors?
- Is the archetype system Epic 2 scope or can it be stubbed correctly now?

**Decision needed:** An extensibility contract — how processors access archetype-specific behavior, and where that configuration lives.

---

## Session Structure

**Round 1:** Gap 1 (NPC decision model) — Cloud Dragonborn + Samus Shepard
- Dragonborn: what decision model shape doesn't become an O(n²) bottleneck at scale
- Samus: what decision inputs produce the player-observable behaviors from the emergence spec

**Round 2:** Gap 2 (actor state decomposition) — Cloud Dragonborn + Indie
- Dragonborn: decomposition boundaries and update cadence alignment
- Indie: what decomposition won't triple the work of adding a new actor type

**Round 3:** Gap 3 (world construction) — all three
- Hardest gap, most unknowns, benefits from all three perspectives

**Round 4:** Gap 4 (archetype extensibility) — Cloud Dragonborn + Indie
- Naturally follows from Round 2 decisions

---

## What This Session Does NOT Produce

- Full NPC state schema (prototype will continue to inform this)
- Full world generation system design
- Implementation specs or stories
- Any code

The output is design decisions that unblock the formal architecture session. Four gaps, four decisions, one supplement document.
