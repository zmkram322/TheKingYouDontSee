# The King You Don't See — Architectural Requirements

**Status:** Pre-implementation design decisions. These must be resolved before prototyping begins. Each item is load-bearing — deferring any of these creates retrofit debt.

**Revision note:** Updated after GDD completion (Steps 10–14) to incorporate locked decisions from Technical Specifications, Epic Structure, and Success Metrics. Closed open specs are marked. Remaining open specs are consolidated in the final section.

---

## 1. Dual-Clock Architecture

**Decision:** The simulation uses two independent, separately-tickable clocks.

| Clock | Purpose | Rate |
|---|---|---|
| Active game time | Player experience, day/night cycle, real-time world feel | Compressed real-time (configurable) |
| Simulation time | Hidden NPC decision-making, economic resolution, burn-in | Dramatically faster — can run N weeks between player actions |

**Requirement:** The two clocks must not share a tick. They read from each other but write to their own domains. If they share a tick, burn-in cannot run at accelerated rate without breaking the active layer.

### SimClock Signal Architecture (Locked)

The simulation clock emits three typed signals. All sim logic is driven exclusively by these signals — nothing runs unless the clock fires.

| Signal | Cadence | Domain |
|---|---|---|
| `week_tick` | Once per in-game week | Lord strategic decisions |
| `day_tick` | Once per in-game day | Lower lord / steward execution, labor contracts, market cadence |
| `event_interrupt` | On demand | Random events, player actions, cascade triggers |

**Provisional tick rate:** 500ms regional heartbeat. Daily tick = 1 real-time minute at standard time compression. These rates must be finalized before the simulation prototype is built — everything downstream (fidelity transitions, burn-in speed, AI responsiveness) is load-bearing against them.

**Hard constraint — Zero `_process()` in the simulation layer.** This is a structural rule, not a performance guideline. Per-frame polling in the sim layer is a design failure. All sim logic is cadence-driven via SimClock signals. Sim actors subscribe to the signals they need.

### Player Action Injection Contract (Locked)

Player actions do not receive a privileged path into the simulation. They inject as `SimEvent` objects into the same queue as NPC-generated events. The queue drains at tick boundaries with a configurable cap. Player actions do not fire mid-frame. This is a causality decision, not a performance optimization.

### Day/Night Mechanical Significance

- Black markets, dark connections (bandit commissioning, shadow alliances), high-influence covert actions → night only
- Actors operating across both cycles accumulate rest deficits → productivity trade-offs
- Night/day distinction must be queryable by NPC decision functions within the sim layer
- **Open spec:** How time-of-day is represented in sim state (enum, float 0–1, SimClock field) and whether sim actors make decisions based on it (if stewards behave differently at night, that is a sim concern, not a visual one, and must be in the schema)

### Clock Coherence (Largely Resolved)

The original "open specification" on clock coherence is substantially resolved by the SimEvent queue architecture: player actions and NPC events are `event_interrupt` signals, drained at tick boundaries. "What fires immediately vs. deferred to next tick" is answered by the queue drain model.

**Remaining open:** See Open Specifications §13.1 and §13.2.

---

## 2. Fidelity Tier Architecture

**Three tiers:**

| Tier | Scope | Sim Fidelity | Rendering | When |
|---|---|---|---|---|
| Near | Player's local zone | Full actor simulation per tick | Small set of specific NPCs drawn individually | Player present |
| Regional | Surrounding regions | Aggregate floats only (grain supply, coin flow, stability index) | No individual actors drawn | Always |
| Distant | Far territories | Statistical drift | No individual actors | Always |

**Important distinction:** Near fidelity sim runs for the small set of specific NPCs whose aggregate state matches the regional sim — not for every actor in range. "Rendered" and "simulated at full fidelity" are the same set. This is load-bearing for the performance model.

**Burn-in fidelity:** Burn-in runs at **Regional fidelity** (aggregate floats), not full actor fidelity. Full fidelity has nothing to anchor to without a player in the near zone.

**Fidelity transition budget (locked):** Near ↔ Regional transitions must complete within 5 seconds. This is a load budget, not a soft target.

### Local Instantiation (First-Class System)

When the player enters a region and the near zone inflates, specific actors are generated whose aggregate properties are consistent with the regional state. This is not a load event — it is a *generation event*.

**Reconstruction contract (locked as deterministic):** Given the same world seed and the same regional aggregate at the moment of entry, you get the same set of actors. The contract is deterministic, not probabilistic.

- Each actor generated at near-zone entry must have state consistent with the regional aggregate (e.g., if regional grain supply float is depleted, generated farmers must reflect that)
- Actor generation reads from Regional aggregate floats and a seed. Output is pure value types (GDScript `Resource` objects or dictionaries). No scene tree involvement in the generation step.
- Local instantiation is a designed system requiring its own spec before implementation

**Remaining open:** See Open Specifications §13.3 and §13.4.

---

## 3. Influence State Architecture

**Scope note (locked):** Influence is Epic 6 territory. This architecture is valid but implementation is deferred until after the vertical slice (end of Epic 5). Ownership (Epic 5) is the accounting layer that influence will be built on top of. Influence is not implemented until ownership is stable. Stub influence fields in the sim schema during Epic 1 design — do not leave them unplanned, do not implement them early.

### Two-Axis Model

| Axis | Update domain | Update timing |
|---|---|---|
| Direct influence (coin-based: contracts, employees) | Active-time events | Updated when contracts signed/broken, employment changes |
| Indirect influence (stats/exp-based: reputation, capability) | Compressed-time ticks | Updated on simulation tick, not on player action |

**Reconciliation rule:** The two axes read from each other but do not write to each other mid-tick. They reconcile at period boundaries (like two ledger columns that balance at end-of-period, not live-linked variables). The specific boundary signal (`day_tick` or `week_tick`) must be defined when implementation begins.

### Threshold Listener Layer

The simulation does not rely on pure emergence to surface new interaction classes as influence grows. A threshold detection layer watches the influence axes cross soft thresholds and weights the probability of new NPC interaction classes entering the decision pool.

Requirements:
- Thresholds are designer-authored (not emergent)
- The threshold layer produces a probability weight, not a hard gate
- The player never sees a threshold crossed — they see the world behaving differently
- Threshold crossing must be observable in simulation logs (for tuning)

**Remaining open:** Where threshold weights are evaluated (at drain time? at SimProcessor execution? as a separate pass?) must be specified before implementation.

---

## 4. Simulation Schema (First Artifact)

**Must be designed before any prototyping.** The schema defines the interface contracts everything else depends on.

**All schema types are pure value types:** GDScript `Resource` objects or dictionaries. No node tree references. No `get_node()`. Schema must be serializable to a structured format without custom logic. This is a constraint on the schema design session, not just on implementation.

### Schema Artifacts — Prioritized Build Order

**First — must exist before prototype begins:**

- **SimClock signal schema** — the three signal types, their emission conditions, and their domain ownership rules
- **SimEvent queue schema** — the shape of a `SimEvent` object (player-injected or NPC-generated), the drain contract, the cap parameter, and event ordering within a single drain pass
- **NPC state schema** — every field, every flag. What does a fully-specified actor look like in memory?
- **SimProcessor interface boundary** — what does a `SimProcessor` see? What can it write? What is off-limits? Execution order when multiple processors affect the same actor must be declared.

**Second — after first burn-in loop, before Epic 2:**

- **Fidelity tier rules** — when does an NPC drop to low-fidelity simulation? What information is preserved vs. approximated?
- **Knowledge tracking schema** — what does the player's information log track? Queries must be designed before schema (query-first design). Minimum decisions: what is a knowledge atom (fact, rumor, observation), does knowledge have a confidence value, does it expire, does it propagate on sim tick or on event?
- **Outcome state taxonomy** — what states can combat produce? (destroyed, incapacitated, disrupted, revealed — and their simulation-layer meanings). Magic/elemental deferred; combat outcomes needed by Epic 4.

**Third — stub now, implement Epic 6:**

- **Influence/control state model** — what does "high influence" mean as a data structure? Stub with typed null fields and comments in the schema during Epic 1. Do not implement until ownership is stable.

---

## 5. Observability Requirements

**Governing principle:** A procedural world is a specification of a space of possible worlds. You cannot author a specification you cannot read. Observability is not a feature — it is the design medium.

**Three required capabilities (build order matters):**

### 5a. Metrics Layer (Build First)

Every significant simulation decision emits a lightweight telemetry record. This runs during burn-in AND during play.

Minimum events to instrument:
- Resource scarcity events (any resource below subsistence threshold for any actor)
- Price spikes (price crosses N× baseline)
- Lord consolidation events (any actor exceeds resource monopoly threshold)
- Trade route formations and breaks
- Hunger strike triggers and resolutions
- Influence threshold crossings *(Epic 6 — instrument the hook from Epic 1, wire it in Epic 6)*
- Actor contract formations and breaks
- **Achievement trigger evaluations** (pass and fail — not just pass). Achievement events are first-class simulation telemetry from Epic 1, not post-hoc retrofits. The metrics layer must treat them as first-class emitters.

**This is not player telemetry. It is simulation telemetry.** It must exist before you have anything interesting to tune.

**Telemetry emitter location:** The `SimProcessor` pattern means the sim layer is pure data. The telemetry emitter must not violate sim purity. The architecture session must decide: does telemetry emit from inside `SimProcessor` (sim layer owns it), or from a separate observer that watches `SimProcessor` output (sim layer stays pure)? These have different coupling trade-offs.

**Weekly tracking (dev habit, not a system):** Sim tick time in ms, crash rate per hour of VS play, systems touched per playtester session. Simple spreadsheet. This catches performance debt and invisible systems early.

### 5b. Replay and Fast-Forward (Build Second)

Ability to take a world seed, run it to burn-in completion, then run N simulated trajectories through it and aggregate results.

Requirements:
- Fast-forward must run at significantly accelerated rate. At 500ms regional heartbeat and 1 daily tick per real-time minute, 1 simulated week ≈ 84 tick cycles (7 days × 12 ticks/day). **Target: 1 simulated week in < 1 second on dev hardware** — this is achievable given the hierarchy-driven architecture but must be validated against actual tick times.
- Replay must hold seed constant while varying parameters
- Aggregate results must be queryable by metric type

Without fast-forward, you cannot run N trajectories. Without replay, you cannot isolate parameter effects.

*Solo dev note: The full replay tooling is post-prototype. The log substrate (§7) is the prerequisite. Build the log first; the replay system grows from it once you know what you need to replay.*

### 5c. Parameter Sensitivity Interface (Build Third)

A designed tool (not a debug menu) that answers: "If I change parameter X by Y%, which simulation outcomes change and by how much?"

This is a local finite-difference analysis on the parameter space. It does not need to be sophisticated — it needs to be fast enough to use within a design session.

**Build this only after the metrics layer is rich enough to know what you are actually trying to tune.**

---

## 6. Burn-In Stability Requirements

**Target:** 90%+ of generated world seeds produce a stable equilibrium state (non-degenerate, non-monopoly, non-oscillating) after burn-in.

*Note: This is a test acceptance criterion, not an architectural constraint. It belongs on a QA checklist but is documented here because it shapes architectural decisions about the stability threshold check and the moving average implementation.*

**Failure mode 1 — Runaway accumulation:**
- Symptom: One actor controls > threshold% of a critical resource after burn-in
- Cause: Lord or merchant archetype too aggressive at extraction
- Mitigation: Stability threshold check fires during burn-in. If any single actor exceeds the threshold, apply corrective pressure (price floor, regulatory response, competing actor generated) before player arrival.

**Failure mode 2 — Oscillation without damping:**
- Symptom: Supply and demand chasing each other in burn-in logs without converging
- Cause: Spot-price reactive logic without memory
- Mitigation: Regional price floats use moving averages (last N weeks), not spot-price reactions. The economy must have memory. "N weeks" maps to N × 12 `day_tick` signals at the locked tick rate — implement against tick count, not wall-clock duration.

**Burn-in monitoring requirement:**
Simulation state logged at regular intervals during burn-in (not just final snapshot). A stable final state and a wildly oscillating state that landed somewhere reasonable are indistinguishable without mid-run observability. The metrics layer (5a above) satisfies this requirement if built first.

**Remaining open:** The 90% target requires a defined seed corpus with an explicit denominator. What set of seeds defines "90%"? This must be specified before the target is testable.

---

## 7. Log Substrate (Prerequisite for Tail Events)

Before implementing tail events as a game feature, the simulation must have a logging substrate:
- Every significant simulation decision writes a lightweight record
- The record includes: **sim_tick_index, active_time_index**, actor IDs, event type, **signal_type** (which SimClock signal triggered this entry — `week_tick`, `day_tick`, or `event_interrupt`), resource states, outcome
- Records are queryable: "show me all hunger strike events in region X over the last 10 weeks"

**Why `signal_type` and both tick indices matter:** When a bug appears in sim output, the first question is "which tick did this happen in?" Without clock context in the log, reconstructing causality is guesswork. This costs nothing to add at design time and saves hours of debugging.

**Purpose:** Understanding the simulation's own distribution of outcomes. When the developer can look at the log and describe what the normal distribution looks like — then the tail event layer can be built.

**Log query mechanism:** Must be decided before the architecture session. Options: in-memory ring buffer (fast, volatile), structured file (persistent, needs I/O budget), SQLite sidecar (queryable, adds dependency). The choice affects performance, replay capability, and the parameter sensitivity interface in 5c. This is a consequential decision.

**Tail event architecture (when substrate is ready):**
1. Probability tracker reading from log
2. Threshold watchers (same system as influence threshold listeners in §3 above)
3. Curated set of authored event templates instantiated when probability conditions are met

Estimated scope once log substrate exists: 2–3 weeks focused work.

---

## 8. Language and Data Architecture (New)

**GDScript primary.** C# only if a specific function becomes a *measured* bottleneck — decided at the chokepoint, not in advance. The hierarchy-driven, cadenced architecture does not require C# performance headroom. If it does, that is a signal the architecture is wrong, not that the language is wrong.

**Sim state lives in pure value types:** GDScript `Resource` objects or dictionaries. Not node trees. Not scene-tree-resident objects. No `get_node()` anywhere in the simulation stack.

**Lords are data containers.** A separate `SimProcessor` reads them and writes decisions back. The simulation is accounting and scheduling, not behavior trees. Memory stays flat, iteration stays predictable, serialization stays trivial.

**SimProcessor execution order:** When multiple SimProcessors affect the same actor within a single tick, execution order must be declared before the first processor is written. Two processors writing to the same actor field in the same tick need a defined resolution strategy — ordered execution (first writer wins, or last writer wins) or a merge strategy (additive? dominant?). This cannot be left implicit.

**Serialization:** Because sim state is pure value types, serialization to a structured format requires no custom logic. Config schema and save format must be versioned together. A config change that breaks old saves is a data integrity failure, not a compatibility inconvenience.

**Save format versioning strategy:** The principle "config schema + save format versioned together" is correct but is not a migration strategy. Before the architecture session, decide: forward-only migrations with a version int in the save file, or "saves before version X are unsupported." For a sim-heavy game with a complex schema, an unexpected breaking schema change six months in can permanently damage player trust.

**GDScript Resource serialization gotcha:** GDScript Resources serialize automatically by default, which is both a gift and a trap — Godot will happily save fields you didn't mean to save, and load data that is now the wrong version. Add explicit `_get_property_list()` control to core sim Resources before writing the first save file.

---

## 9. ReadoutMapper Architecture (New)

The ReadoutMapper is the sole bridge between simulation truth and visual/audio representation. It does not exist in the original supplement and must be designed before any rendering work that depends on sim state.

```
SimulationState → ReadoutMapper → VisualStateDescriptor → RenderParameters
SimulationState → WorldStateAggregator → MoodVector → AudioMixerParameters
ZoneState      → ZoneStateAggregator  → EnvironmentLightingParameters
```

**Sim layer contract:** Does not know about shaders, audio buses, or render parameters. Emits state. That is all.

**Render/audio layer contract:** Does not know about needs tiers, grain supply, or influence axes. Reads descriptors. That is all.

**Boundary rule:** Any visual or audio element that needs to reflect sim state must go through a mapper. A renderer reading sim state directly, or a shader reacting to a lord's hunger level, is an architectural violation. No exceptions. Solo devs especially: this boundary erodes fast when you're the only one watching. Enforce it by making sim state inaccessible from the render layer at the class level, not by convention.

**ReadoutMapper update timing (open spec):** The mapper must have a defined update contract: does it poll on `day_tick`? On `week_tick`? After every `SimProcessor` pass? On `event_interrupt` only for render-relevant changes? Without this, ad-hoc mapper calls will scatter throughout the codebase and visual desync bugs follow. This must be decided at the architecture session.

**ReadoutMapper scope risk:** The ReadoutMapper easily grows into a god object as features are added. Enforce a hard rule early: ReadoutMapper only reads fields explicitly typed and documented in the `VisualStateDescriptor` schema. Never let it reach into raw sim state directly.

**Schema requirement:** The `VisualStateDescriptor` schema and `MoodVector` schema must be defined before any rendering work begins that depends on sim state.

---

## 10. SimEvent Queue Architecture (New)

All simulation decisions and player actions are `SimEvent` objects. There is no privileged path for player input.

**Queue drain contract:**
- Queue drains at tick boundaries
- Events do not fire mid-frame
- Drain cap is configurable (value TBD — see Open Specifications)
- Player actions inject as `event_interrupt`-typed events, indistinguishable from NPC-generated interrupt events except by source tag

**What "configurable cap" means operationally:** Events that do not drain in a given tick must have a defined fate — queued to next tick, dropped, or flagged as overflow. Without this definition, influence spam from a player (six rapid actions in one tick) will produce unpredictable behavior and bugs that are hard to reproduce. This is the most common drain contract failure.

**Ordering within a single drain pass:** Two events in the same drain pass — what is their relative order? FIFO? Priority-weighted by event type? This has observable consequences for fairness between player and NPC actions in the same tick. Must be decided.

**`event_interrupt` propagation up the hierarchy:** When a random event fires at labor level, does it propagate to lord level on the same tick (within the drain pass), or is it scheduled for the next `week_tick`? This is an ordering problem with observable consequences for how responsive the hierarchy feels to disruption.

**Open specs:** Drain cap value, drain overflow behavior, ordering within a drain pass, interrupt propagation contract. See Open Specifications §13.1 and §13.2.

---

## 11. Template Metadata Schema (New)

Each environment module carries typed simulation metadata. This is not decorative — it is the sim layer's ground truth for spatial economics and social modeling.

**Required metadata fields per module (minimum):** capacity, ownership state, condition, navmesh tags, economy node tags, social space definitions.

**Schema defined before the assembler is built.** Retrofitting metadata onto assembled environments produces merge ambiguity and will require a full rebuild of the assembly system. This is a common solo dev trap — the modular kit feels fast to build without the metadata, until the sim layer needs it.

**Merge/override rules:** When modules combine, their metadata merges. The rules for conflict resolution (additive, dominant, error-on-conflict) must be specified before the first assembly pass. Two economy nodes in the same assembled space need a declared owner.

**Open spec:** Merge/override rules for metadata when modules combine. See Open Specifications §13.9.

---

## 12. Platform and Performance Targets (New)

**Platform:** PC Steam primary.

**Minimum specification:**

| Component | Minimum |
|---|---|
| GPU | NVIDIA RTX 3060 / AMD RX 6600 |
| CPU | Intel Core i5-12400 / AMD Ryzen 5 5600 |
| RAM | 16GB |
| Storage | SSD recommended |
| OS | Windows 10/11 64-bit |

**Bottleneck profile:** CPU is the expected performance bottleneck. GPU load is not the primary profiling concern. Sim tick performance is measured against CPU budget, not frame budget.

**Frame rate floor:** 60fps is a hard floor on the active layer. Sim tick cadence (500ms heartbeat) must not cause frame drops on minimum spec. If a tick overruns, it does not steal from the render frame — the tick is the unit of work, the frame is not. The architectural discipline that makes this possible is the `SimClock` cadence model: nothing in the sim runs between ticks.

**Profiling discipline:** Do not optimize what has not been measured. C# extensions, threading, and other performance interventions are decided at measured chokepoints, not in advance. The hierarchy-driven architecture exists precisely to avoid the need for per-frame optimization of NPC behavior.

**RegionalToNear transition timing:** The 5-second transition budget is a user-facing target. In Godot, if actor generation runs on the main thread and takes 3+ seconds, there will be a visible hitch. The architecture session must declare a strategy — background thread, async generation, or progressive population — before the transition system is written. This is a Godot-specific gotcha that solo devs often hit late.

---

## 13. Open Specifications (Consolidated)

These remain genuinely unresolved. Each must be decided at or before the architecture session. They are ordered by how early in the build sequence they become blocking.

| # | Open Spec | Blocks |
|---|---|---|
| 13.1 | **SimEvent drain cap** — value, ownership, and what happens to overflow events (queue to next tick? drop? flag?) | Epic 1 sim prototype |
| 13.2 | **`event_interrupt` propagation contract** — does a labor-level event propagate to lord level within the same drain pass, or scheduled for the next `week_tick`? | Epic 1 sim prototype |
| 13.3 | **Near re-entry seed persistence** — on second entry to a region, does the seed persist (same baker) or regenerate from current regional state (consistent baker)? Different gameplay contracts. | Epic 2 fidelity transitions |
| 13.4 | **Fidelity transition mechanism** — loading screen, fade, progressive population? Technical architecture differs significantly by choice. | Epic 2 fidelity transitions |
| 13.5 | **ReadoutMapper update timing** — when does the mapper run relative to SimClock signals and SimProcessor execution? | Epic 3 (first visual output) |
| 13.6 | **Log substrate query mechanism** — in-memory ring buffer, structured file, or SQLite sidecar? Affects performance, replay, and parameter sensitivity interface. | Epic 1 metrics layer |
| 13.7 | **SimProcessor execution order** — when multiple processors affect the same actor within a tick, declared order or declared merge strategy? | Epic 1 sim prototype |
| 13.8 | **Day/night representation in sim state** — enum, float 0–1, SimClock field? Does it affect sim actor decisions (not just visuals)? | Epic 1 sim schema |
| 13.9 | **Template metadata merge/override rules** — when modules combine, conflict resolution strategy (additive, dominant, error)? | Epic 3 procedural region |
| 13.10 | **Burn-in stability seed corpus** — what is the denominator for "90% of seeds"? Corpus size and composition must be defined before the target is testable. | Epic 1 burn-in validation |
| 13.11 | **SimClock ownership in Godot** — which node or autoload owns SimClock? Who is allowed to advance it? Can the player fast-forward or pause it? | Epic 1 sim prototype |
| 13.12 | **Influence reconciliation period boundary** — does the two-axis reconciliation fire on `day_tick` or `week_tick`? | Epic 6 influence implementation |

---

*Decisions locked in this document are load-bearing walls. Open specifications are the joints that must be set before the walls go up. Bring the open specifications to the architecture session as the agenda.*
