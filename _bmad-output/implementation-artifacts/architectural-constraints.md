# The King You Don't See — Architectural Constraints

**Session type:** Pre-prototype structural constraints. Not a full architecture document.
**Date:** 2026-04-27
**Scope:** 4 structural decisions + 5 Epic-1-blocking open specs. Everything else deferred to post-prototype full architecture session.
**Engine:** Godot 4.x / GDScript primary

---

## Decision 1 — SimClock Architecture

**Owner:** `SimClock` Autoload singleton. Lives for the entire game lifetime, survives scene transitions, runs during headless burn-in with no scene loaded.

**Signal set — day-phase model:**

| Signal | Phase | Domain |
|---|---|---|
| `day_open(day_index)` | Planning | NPCs declare intended activity |
| `activity(day_index)` | Execution | One activity executes; one interrupt slot fires first |
| `day_close(day_index)` | Tally | Supply accumulates; hunger/restfulness stats update |
| `week_tick(week_index)` | Weekly | Lord decisions, market week-end sequence |
| `event_interrupt(event)` | On demand | Single pending interrupt, drains at start of activity phase |

**Day cycle phase order:** `day_open → activity → day_close`. `week_tick` fires after `day_close` when `day_index % 7 == 0`.

**Advancement:** Internal `Timer` node only (500ms per phase, `PHASE_SECONDS` constant). Two public control methods: `set_paused(bool)` and `set_time_scale(float)`. No external code can force a tick.

**Event slot:** Single `_pending_interrupt: SimEvent`. Not a queue. Last enqueued wins. Prototype cap = 1 interrupt per activity phase.

**No `_process()` enforcement:** SimProcessors extend `RefCounted` — the `_process()` callback does not exist on `RefCounted`. Enforcement is structural, not by convention.

**Day/night (open spec 13.8 — closed):** Not a separate field. The day cycle is the full active period. Night mechanical significance (black markets, rest deficits) is handled by SimProcessors reading `day_index` parity or a `time_of_day` field added to SimClock when night behaviors are implemented. For the prototype, one cycle per day is sufficient.

```gdscript
# scripts/autoloads/sim_clock.gd
class_name SimClock
extends Node  # Autoload

signal week_tick(week_index: int)
signal day_open(day_index: int)
signal activity(day_index: int)
signal day_close(day_index: int)
signal event_interrupt(event: SimEvent)

enum DayPhase { OPEN, ACTIVITY, CLOSE }

const PHASE_SECONDS: float = 0.5
const DRAIN_CAP: int = 1  # prototype: one interrupt per activity phase

var day_index: int = 0
var week_index: int = 0

var _paused: bool = false
var _phase: DayPhase = DayPhase.OPEN
var _pending_interrupt: SimEvent = null

var _open_processors: Array[SimProcessor] = []
var _activity_processors: Array[SimProcessor] = []
var _close_processors: Array[SimProcessor] = []
var _week_processors: Array[SimProcessor] = []

@onready var _heartbeat: Timer = $Heartbeat

func _ready() -> void:
    _heartbeat.wait_time = PHASE_SECONDS
    _heartbeat.autostart = true
    _heartbeat.timeout.connect(_on_phase_tick)

func _on_phase_tick() -> void:
    if _paused:
        return
    match _phase:
        DayPhase.OPEN:
            for p in _open_processors:
                p.execute(SimWorld)
            day_open.emit(day_index)
            _phase = DayPhase.ACTIVITY
        DayPhase.ACTIVITY:
            if _pending_interrupt != null:
                event_interrupt.emit(_pending_interrupt)
                _pending_interrupt = null
            for p in _activity_processors:
                p.execute(SimWorld)
            activity.emit(day_index)
            _phase = DayPhase.CLOSE
        DayPhase.CLOSE:
            for p in _close_processors:
                p.execute(SimWorld)
            day_close.emit(day_index)
            day_index += 1
            if day_index % 7 == 0:
                week_index += 1
                for p in _week_processors:
                    p.execute(SimWorld)
                week_tick.emit(week_index)
            _phase = DayPhase.OPEN

func enqueue_event(event: SimEvent) -> void:
    _pending_interrupt = event  # last enqueued wins

func set_paused(paused: bool) -> void:
    _paused = paused

func set_time_scale(scale: float) -> void:
    _heartbeat.wait_time = PHASE_SECONDS / clampf(scale, 0.1, 100.0)

func register_processor(phase: DayPhase, processor: SimProcessor) -> void:
    match phase:
        DayPhase.OPEN:     _open_processors.append(processor)
        DayPhase.ACTIVITY: _activity_processors.append(processor)
        DayPhase.CLOSE:    _close_processors.append(processor)
```

---

## Decision 2 — Sim Data Architecture

**Actor state:** `Resource` subclasses for all declared sim state. `Dictionary` only for ad-hoc/ephemeral data (event parameters, runtime modifier bags).

**Where state lives:** `SimWorld` Autoload holds all `ActorState` Resources in flat arrays. Not the scene tree. No node holds sim data.

**SimProcessor pattern:** Extend `RefCounted`. SimClock calls `execute(world: SimWorld)` on each registered processor in declared order. Processors mutate Resources directly — no return value for the prototype.

**Serialization boundary:** `@export var` fields serialize to disk. Plain `var` fields (computed/runtime-only) do not. `productivity` is computed — never exported, never saved. Before writing the first real save file, audit all `var` declarations without `@export` to confirm intent — that is the `_get_property_list()` discipline the supplement requires, achieved here with simpler syntax.

```gdscript
# scripts/sim/actor_state.gd
class_name ActorState
extends Resource

enum Role { FARMER, MERCHANT, LORD }

@export var actor_id: StringName
@export var role: Role = Role.FARMER
@export var grain: float = 0.0
@export var coin: float = 0.0
@export var hunger: float = 0.0        # 0 = full, 1 = starving
@export var restfulness: float = 1.0   # 1 = rested, 0 = exhausted
@export var employer_id: StringName = &""
@export var wage: float = 0.0

# Epic 6 stubs — zero, serialized, not implemented
@export var influence_direct: float = 0.0
@export var influence_indirect: float = 0.0

# Computed — plain var, never serialized
var productivity: float = 1.0

func compute_productivity() -> void:
    productivity = (1.0 - hunger) * restfulness
```

```gdscript
# scripts/autoloads/sim_world.gd
class_name SimWorld
extends Node  # Autoload

var actors: Array[ActorState] = []
var regional_grain_supply: float = 0.0
var regional_coin_supply: float = 0.0
var current_market_price: float = 1.0

func get_actors_by_role(role: ActorState.Role) -> Array[ActorState]:
    return actors.filter(func(a): return a.role == role)
```

```gdscript
# scripts/sim/sim_processor.gd
class_name SimProcessor
extends RefCounted  # No _process(). Structurally impossible.

func execute(world: SimWorld) -> void:
    pass
```

---

## Decision 3 — ReadoutMapper Bridge

**Owner:** `ReadoutMapper` Autoload. The only object in the codebase with a reference to `SimWorld`. Render nodes never see `ActorState`, grain floats, or hunger values.

**When it runs:** Connects to `SimClock.day_close`. State is settled after tally — descriptors update once per day, not per render frame. Render nodes connect to `ReadoutMapper.descriptors_updated` signal.

**Boundary enforcement:** `SimWorld` reference is a private `_sim_world` field inside ReadoutMapper. The public API exposes only typed `VisualStateDescriptor` arrays. Render scripts have no import path to `ActorState`.

**Pipelines:**

```
SimClock.day_close
    └──▶ ReadoutMapper
              ├──[private]──▶ SimWorld (reads)
              │
              ├──▶ VisualStateDescriptor[]  ──descriptors_updated──▶ Render Nodes
              │
              ├──▶ WorldStateAggregator ──▶ MoodVector ──▶ AudioMixerParameters
              │    (stub — Epic 3)
              │
              └──▶ ZoneStateAggregator  ──▶ EnvironmentLightingParameters
                   (stub — Epic 3)
```

**Open spec 13.5 (ReadoutMapper update timing) — closed:** Fires on `day_close`. Not polled. Not per-frame.

```gdscript
# scripts/sim/visual_state_descriptor.gd
class_name VisualStateDescriptor
extends Resource

enum MoodCategory { CONTENT, STRESSED, DESPERATE }

# Visual-domain types only — no sim types, no grain floats
var actor_id: StringName
var mood: MoodCategory = MoodCategory.CONTENT
var productivity_normalized: float = 1.0
var is_on_strike: bool = false
```

```gdscript
# scripts/autoloads/readout_mapper.gd
class_name ReadoutMapper
extends Node  # Autoload

signal descriptors_updated(descriptors: Array[VisualStateDescriptor])

var _sim_world: SimWorld  # private — render layer never touches this

func _ready() -> void:
    _sim_world = SimWorld
    SimClock.day_close.connect(_on_day_close)

func _on_day_close(_day_index: int) -> void:
    var result: Array[VisualStateDescriptor] = []
    for actor in _sim_world.actors:
        var desc := VisualStateDescriptor.new()
        desc.actor_id = actor.actor_id
        desc.productivity_normalized = actor.productivity
        desc.is_on_strike = actor.hunger >= 0.8 and actor.restfulness <= 0.2
        desc.mood = _classify_mood(actor)
        result.append(desc)
    descriptors_updated.emit(result)

func _classify_mood(actor: ActorState) -> VisualStateDescriptor.MoodCategory:
    if actor.hunger > 0.7:
        return VisualStateDescriptor.MoodCategory.DESPERATE
    if actor.hunger > 0.4 or actor.restfulness < 0.4:
        return VisualStateDescriptor.MoodCategory.STRESSED
    return VisualStateDescriptor.MoodCategory.CONTENT
```

---

## Decision 4 — SimProcessor Execution Model

**Execution order declaration:**

```
PHASE: day_open
  1. LaborPlanningProcessor    — farmers decide to work or strike (reads hunger, restfulness)
  2. MerchantPlanningProcessor — merchant evaluates buy threshold

PHASE: activity  (interrupt drains first, then processors)
  0. [event_interrupt drain]   — pending event fires, mutates SimWorld
  1. ProductionProcessor       — grain output = land × g(t) × productivity
  2. TravelProcessor           — stub (multi-market arbitrage, Epic 2)

PHASE: day_close
  1. TallyProcessor            — hunger += rate, restfulness -= cost,
                                 productivity recompute, grain → regional_grain_supply

PHASE: week_tick  (fires after day_close on day % 7 == 0)
  1. MarketProcessor           — week-end sequence: buy eval, price clear,
                                 tax extraction, worker food purchase
  2. LordProcessor             — stub (tax rate / strategic decisions, Epic 2+)
```

**Conflict resolution rule:** Declared order, last writer wins — the processor listed later in its phase registry is authoritative for any field written by multiple processors in that phase.

**event_interrupt sequencing rule:** Events drain at the start of the activity phase, before activity processors run. Within-day propagation — an event that fires during a day affects that same day's production, not the next `week_tick`.

```gdscript
# scripts/autoloads/sim_bootstrap.gd  — Autoload
# Canonical processor registry. Read this file to understand execution order.
extends Node

func _ready() -> void:
    SimClock.register_processor(SimClock.DayPhase.OPEN,     LaborPlanningProcessor.new())
    SimClock.register_processor(SimClock.DayPhase.OPEN,     MerchantPlanningProcessor.new())
    SimClock.register_processor(SimClock.DayPhase.ACTIVITY, ProductionProcessor.new())
    SimClock.register_processor(SimClock.DayPhase.ACTIVITY, TravelProcessor.new())
    SimClock.register_processor(SimClock.DayPhase.CLOSE,    TallyProcessor.new())
    SimClock._week_processors = [MarketProcessor.new(), LordProcessor.new()]
```

---

## Open Specifications — Status

### Closed in This Session (Epic 1 blockers)

| # | Spec | Resolution |
|---|---|---|
| 13.1 | SimEvent drain cap | Cap = 1 per activity phase (prototype). Overflow = last enqueued replaces pending. Revisit post-emergence. |
| 13.2 | `event_interrupt` propagation | Drains at start of activity phase, same day. Within-day propagation — not deferred to next `week_tick`. |
| 13.5 | ReadoutMapper update timing | Fires on `day_close`. Not polled. Not per-frame. |
| 13.7 | SimProcessor execution order | Declared in `SimBootstrap`. Last-writer-wins within phase. See Decision 4 above. |
| 13.8 | Day/night representation | One cycle per day for prototype. Night mechanics added as `time_of_day` field on SimClock when night-specific behaviors are implemented (black markets, rest deficits). |
| 13.11 | SimClock ownership in Godot | `SimClock` Autoload singleton. Internal `Timer` only. Two public control methods. |

### Deferred (Not Epic 1 Blockers)

| # | Spec | Blocks |
|---|---|---|
| 13.3 | Near re-entry seed persistence | Epic 2 fidelity transitions |
| 13.4 | Fidelity transition mechanism | Epic 2 fidelity transitions |
| 13.6 | Log substrate query mechanism | Epic 1 metrics layer — decide before writing first processor |
| 13.9 | Template metadata merge/override rules | Epic 3 procedural region |
| 13.10 | Burn-in stability seed corpus | Epic 1 burn-in validation |
| 13.12 | Influence reconciliation period boundary | Epic 6 |

---

## Autoload Load Order

Autoloads must load in this order (Project Settings > Autoloads):

1. `SimWorld` — actor state container
2. `SimClock` — phase clock, processor registry
3. `SimBootstrap` — registers processors (reads SimClock)
4. `ReadoutMapper` — connects to SimClock.day_close (reads SimWorld, SimClock)
5. `WorldStateAggregator` — stub
6. `ZoneStateAggregator` — stub

---

## What This Document Is Not

Deliberately out of scope — deferred to post-prototype full architecture session:

- Full NPC state schema (prototype will reveal what's actually needed)
- Knowledge tracking schema
- Full SimEvent vocabulary
- Influence/control state model
- Template metadata merge rules
- Fidelity transition architecture
- Log substrate implementation
- Full architecture document

---

*These constraints are load-bearing walls. Everything in Epic 1 builds on top of them. Run the prototype. Let it teach you what the full architecture session should cover.*
