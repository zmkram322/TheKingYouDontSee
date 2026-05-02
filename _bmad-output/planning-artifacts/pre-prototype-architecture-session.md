# Pre-Prototype Architecture Session Plan

**Purpose:** Lock the 4 structural decisions that are genuinely expensive to retrofit before writing a line of Epic 1 code. This is not a full architecture session — it is a focused constraints session. The full `/gds-game-architecture` workflow runs *after* the prototype proves emergence.

**Time budget:** ~90 minutes.

**Output artifact:** `implementation-artifacts/architectural-constraints.md` — a short document (not a full architecture doc) capturing the locked structural decisions and their rationale.

---

## Why This Session Before Prototype

Most architecture decisions will be answered better by the prototype than by any document. But four structural decisions are genuinely load-bearing: starting wrong on these means weeks of refactor, not hours. Everything else can be discovered in the build.

The prototype will teach you:
- Exact NPC state schema fields
- Actual tick rate tuning (provisional values must be measured)
- Knowledge tracking atom shape
- Template metadata needs
- Drain cap and event ordering values

The prototype cannot easily fix:
- A sim layer built with `_process()` (everything re-architected)
- Sim state coupled to the node tree (serialization and fidelity transitions become nightmares)
- Render and sim layers coupled directly (ReadoutMapper pattern impossible to retrofit cleanly)
- No declared SimProcessor pattern (debugging emergent behavior without it is guesswork)

---

## The 4 Decisions to Lock

### Decision 1 — SimClock Architecture

**Question:** How is the simulation clock structured in Godot? Who owns it, who can advance it, and how does it enforce the no-`_process()` rule?

**What to decide:**
- Which Godot construct owns SimClock (Autoload singleton is the likely answer — why or why not?)
- How `week_tick`, `day_tick`, and `event_interrupt` signals are emitted and who can listen
- Who is allowed to advance the clock (and whether the player can pause or fast-forward it)
- How the no-`_process()` rule is enforced structurally, not by convention

**Locked context going in:**
- Signal types: `week_tick`, `day_tick`, `event_interrupt`
- Provisional tick rate: 500ms regional heartbeat, daily tick = 1 real-time minute
- Player actions inject as `SimEvent` objects into the same queue as NPC events, drained at tick boundaries

**Output:** One paragraph + a Godot pseudo-code stub showing SimClock ownership and signal emission.

---

### Decision 2 — Sim Data Architecture

**Question:** What is the exact Godot implementation of "pure value types, no node dependencies"?

**What to decide:**
- GDScript `Resource` subclass vs. plain `Dictionary` — which, when, and why
- How SimProcessor reads from and writes to actor Resources without node coupling
- How `_get_property_list()` is used to control serialization explicitly (prevents Godot from silently saving/loading the wrong fields)
- Where Resources live in memory (not in the scene tree)

**Locked context going in:**
- Lords are data containers; a separate SimProcessor reads and writes decisions back
- No `get_node()` anywhere in the sim layer
- GDScript primary; C# only at a measured bottleneck

**Output:** A brief data contract definition showing a minimal actor Resource and the SimProcessor interface boundary.

---

### Decision 3 — ReadoutMapper Bridge

**Question:** How is the sim-to-render bridge structured so neither layer ever knows about the other?

**What to decide:**
- Where ReadoutMapper lives in the Godot scene/autoload hierarchy
- When it runs (after which SimClock signal? after every SimProcessor pass? on a render-frame poll?)
- What `VisualStateDescriptor` looks like as a minimum viable struct
- How to structurally prevent the render layer from reaching into sim state directly

**Locked context going in:**
- `SimulationState → ReadoutMapper → VisualStateDescriptor → RenderParameters`
- `SimulationState → WorldStateAggregator → MoodVector → AudioMixerParameters`
- Sim layer does not know about shaders or audio; render/audio layer does not know about needs tiers or grain supply

**Output:** A diagram or pseudo-code showing the three pipelines and the boundary enforcement mechanism.

---

### Decision 4 — SimProcessor Execution Model

**Question:** How do multiple SimProcessors interact in a single tick without producing non-deterministic or conflicting results?

**What to decide:**
- Declared execution order for processors that run in the same tick (e.g., does the lord processor run before or after the steward processor?)
- What happens when two processors write to the same actor field in the same tick — ordered execution (last writer wins?) or a merge strategy
- How `event_interrupt` processing is sequenced relative to the `day_tick` and `week_tick` processor passes

**Locked context going in:**
- Lords are data containers; SimProcessor reads and writes back
- SimEvent queue drains at tick boundaries with a configurable cap
- Hierarchy: lords weekly, stewards daily, events propagate upward

**Output:** An execution order declaration + conflict resolution rule (one sentence each).

---

## Open Specs to Resolve in This Session

From the supplement's consolidated open specifications (§13), these are the ones blocking Epic 1:

| # | Question | Why it blocks Epic 1 |
|---|---|---|
| 13.1 | SimEvent drain cap — value, and what happens to overflow events | Can't write the event queue without it |
| 13.2 | `event_interrupt` propagation — same drain pass or next `week_tick`? | Determines how responsive the hierarchy is to disruption |
| 13.7 | SimProcessor execution order | Can't write the first processor without a declared order |
| 13.8 | Day/night representation in sim state | Needed in the schema for hunger strike and black market triggers |
| 13.11 | SimClock ownership in Godot | Can't structure the project without knowing where the clock lives |

The remaining open specs (13.3, 13.4, 13.5, 13.6, 13.9, 13.10, 13.12) are deferred — they block Epic 2 or later, or will be answered by the prototype itself.

---

## What This Session Does NOT Produce

Deliberately out of scope for this session:

- Full NPC state schema (the prototype will reveal what's actually needed)
- Knowledge tracking schema (same — can't design it without seeing how NPCs use it)
- Full SimEvent vocabulary (start with the minimum, expand as needed)
- Influence/control state model (Epic 6 territory — stub fields, don't design)
- Template metadata merge/override rules (Epic 3 territory)
- Full architecture document (that comes after prototype proves emergence)

---

## After This Session — Start Building

Once the 4 structural decisions are locked and the 5 open specs are resolved:

1. Write `implementation-artifacts/architectural-constraints.md` (the output of this session)
2. Begin Epic 1 prototype per `supplement-prototype-spec.md`
3. Let the prototype answer the remaining open specs
4. Return to `/gds-game-architecture` after Epic 1 proves emergence — the full architecture document is most valuable written *after* the prototype has taught you what you actually need

---

## Triggering the Full Architecture Session

Run `/gds-game-architecture` when:
- Epic 1 prototype is complete (all 5 emergence behaviors observable)
- You have real questions the prototype raised that need architectural answers
- You're ready to commit to the full build on top of a proven simulation foundation

The full architecture document is a commitment artifact. You write it when you know what you're committing to.
