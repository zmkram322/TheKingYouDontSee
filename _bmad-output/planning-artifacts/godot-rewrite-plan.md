# Godot Prototype Rewrite Plan — The King You Don't See

> **⚠ SUPERSEDED (2026-05-01):**
> This plan was written against `supplement-prototype-gaps.md`, which has been marked superseded for v0 prototype scope. The S-01..S-N stories below target the aptitude/skill/morale architecture that is now deferred to Epic 2+.
>
> **Use `_bmad-output/prototype-build-spec.md` as the canonical build target for v0.** A new story plan against the build-spec will be written in a follow-up session. The stories in this document are reference material for *future* work, not next steps.
>
> Existing `tkyds-game/scripts/` code targeting the prior architecture should be archived to `tkyds-game/scripts/_archived/` rather than mixed with the new build.

**Author:** Indie (gds-agent-game-solo-dev)
**Date:** 2026-04-29 (superseded 2026-05-01)
**Design reference:** `_bmad-output/supplement-prototype-gaps.md` *(superseded for v0)*
**Existing code:** `tkyds-game/scripts/`

---

## Overview

The existing prototype proved the skeleton works — processors fire, market clears, debug view renders. Now we rebuild it properly: component actor model, 8-slot clock, two-tier market, and the three validation loops.

**Do not delete old files until the story that replaces them passes its acceptance criteria.** Rewrite in place or alongside, then delete when green.

---

## File Location Conventions

```
tkyds-game/scripts/
  resources/      ← new Resource subclasses (S-01)
  nodes/          ← non-autoload Nodes (BehaviorSchedule)
  sim/            ← base classes, enums (keep existing structure)
  processors/     ← processors (keep existing structure)
  autoloads/      ← autoloads (keep existing structure)
  ui/             ← debug view (keep existing structure)
```

---

## Validation Loops

| Loop | Description | Completed by |
|---|---|---|
| (a) | Aptitude → XP → measurable skill divergence | S-07 |
| (b) | Needs → demand signals → emergent price | S-12 |
| (c) | Labor supply shock → wage + price cascade | S-13 |

---

## Stories

---

### S-01 — Resource Data Layer

**Pure data. No behavior. No processors. Just fields.**

#### Files
| Action | Path |
|---|---|
| NEW | `scripts/resources/aptitude_profile.gd` |
| NEW | `scripts/resources/skill_ledger.gd` |
| NEW | `scripts/resources/economic_profile.gd` |
| NEW | `scripts/resources/need_entry.gd` |
| NEW | `scripts/resources/needs_state.gd` |
| NEW | `scripts/resources/contract_state.gd` |
| NEW | `scripts/resources/lord_directive.gd` |
| NEW | `scripts/resources/lord_tax_policy.gd` |
| NEW | `scripts/resources/market_entry.gd` |
| NEW | `scripts/resources/owner_inventory.gd` |
| NEW | `scripts/resources/merchant_inventory.gd` |
| NEW | `scripts/resources/merchant_pricing_model.gd` |
| NEW | `scripts/sim/enums.gd` |

#### Build

`enums.gd` — all shared enums, no class_name conflicts:
```gdscript
# TimeSlot, PhaseActivity, MarketType, SkillDomain, ConditionFlag, WorkIncapacityCause
enum TimeSlot { EARLY_MORNING, MID_MORNING, LATE_MORNING, EARLY_AFTERNOON,
                LATE_AFTERNOON, EARLY_EVENING, LATE_EVENING, MIDDLE_OF_NIGHT }
enum PhaseActivity { WORKING, RESTING, SOCIALIZING, TRAVELING, BUYING, SELLING, IDLE }
enum MarketType { GOODS, SERVICE_LABOR }
enum SkillDomain { LABOR, COMBAT, MARKET_PERCEPTION, BARTERING }
enum ConditionFlag { HUNGRY, BROKE, UNABLE_TO_WORK, MARKET_SEEKING }
enum WorkIncapacityCause { NONE, MORALE_COLLAPSE, FOOD_ABSENT, FOOD_UNAFFORDABLE, COMPOUNDING }
```

`aptitude_profile.gd`:
```gdscript
class_name AptitudeProfile extends Resource
@export var athleticism: int = 5   # ATH 1–10
@export var charisma: int = 5      # CHA 1–10
@export var intelligence: int = 5  # INT 1–10
```

`need_entry.gd`:
```gdscript
class_name NeedEntry extends Resource
@export var current_level: float = 1.0       # 1.0 = fully satisfied
@export var deficit_accumulated: float = 0.0
@export var last_resolution_tick: int = 0
```

`needs_state.gd`:
```gdscript
class_name NeedsState extends Resource
@export var hunger: NeedEntry    # invert: 1.0 = full, 0.0 = starving
@export var health: NeedEntry
@export var rest: NeedEntry
@export var morale: NeedEntry
var condition_flags: int = 0     # bitmask of ConditionFlag values
var incapacity_cause: int = 0    # WorkIncapacityCause value
func _init() -> void:
    hunger = NeedEntry.new(); health = NeedEntry.new()
    rest   = NeedEntry.new(); morale = NeedEntry.new()
```

`skill_ledger.gd`:
```gdscript
class_name SkillLedger extends Resource
# key: SkillDomain int, value: float xp
var skill_xp: Dictionary = {}
func get_xp(domain: int) -> float:
    return skill_xp.get(domain, 0.0)
func add_xp(domain: int, amount: float) -> void:
    skill_xp[domain] = get_xp(domain) + amount
```

`economic_profile.gd`:
```gdscript
class_name EconomicProfile extends Resource
@export var coin: float = 0.0
```

`contract_state.gd`:
```gdscript
class_name ContractState extends Resource
@export var employer_id: StringName = &""
@export var wage: float = 0.0
@export var contract_status: StringName = &"active"
```

`lord_directive.gd`:
```gdscript
class_name LordDirective extends Resource
@export var routine_variant: StringName = &"STANDARD_ROUTINE"
```

`lord_tax_policy.gd`:
```gdscript
class_name LordTaxPolicy extends Resource
@export var tax_rate: float = 0.1
```

`market_entry.gd`:
```gdscript
class_name MarketEntry extends Resource
@export var good_id: StringName = &""
@export var market_type: int = 0          # MarketType value
@export var supply: float = 0.0
@export var demand: float = 0.0
@export var equilibrium_price: float = 1.0
@export var base_price: float = 1.0
@export var price_elasticity: float = 1.0
@export var supply_source_count: int = 0
```

`owner_inventory.gd`:
```gdscript
class_name OwnerInventory extends Resource
var goods: Dictionary = {}   # StringName → float
func add(good_id: StringName, amount: float) -> void:
    goods[good_id] = goods.get(good_id, 0.0) + amount
func take(good_id: StringName, amount: float) -> float:
    var held: float = goods.get(good_id, 0.0)
    var taken: float = minf(held, amount)
    goods[good_id] = held - taken
    return taken
```

`merchant_inventory.gd`: same pattern as OwnerInventory plus `cost_basis: Dictionary`.

`merchant_pricing_model.gd`:
```gdscript
class_name MerchantPricingModel extends Resource
@export var target_margin: float = 0.15
@export var expected_sale_price: float = 1.0   # updated each week from retail price
@export var last_farm_gate_price: float = 0.7
```

#### Acceptance Criteria
- All resource classes instantiate without errors in a blank `_ready()` test.
- `NeedsState` correctly nests four `NeedEntry` instances.
- `SkillLedger.add_xp` and `OwnerInventory.add/take` behave correctly in isolation.

---

### S-02 — SimClock: 8-Slot Rewrite

#### Files
| Action | Path |
|---|---|
| REWRITE | `scripts/autoloads/sim_clock.gd` |

#### Build

Replace `DayPhase` enum with `TimeSlot` from `enums.gd`. One tick per slot; 8 slots = 1 day; 56 slots = 1 week.

```gdscript
extends Node

signal slot_tick(slot: int, day_index: int)
signal week_tick(week_index: int)
signal event_interrupt(event: SimEvent)

const SLOTS_PER_DAY: int = 8
const DAYS_PER_WEEK: int = 7
const SLOT_SECONDS: float = 0.5

var slot_index: int = 0   # 0–7 within current day
var day_index: int = 0
var week_index: int = 0

var _paused: bool = false
var _heartbeat: Timer
var _slot_processors: Array       # Array[Array[SimProcessor]], indexed by slot
var _week_processors: Array[SimProcessor] = []
var _pending_interrupt: SimEvent = null

func _ready() -> void:
    _slot_processors.resize(8)
    for i in 8:
        _slot_processors[i] = []
    _heartbeat = Timer.new()
    _heartbeat.wait_time = SLOT_SECONDS
    _heartbeat.autostart = true
    add_child(_heartbeat)
    _heartbeat.timeout.connect(_on_slot_tick)

func _on_slot_tick() -> void:
    if _paused:
        return
    if _pending_interrupt:
        event_interrupt.emit(_pending_interrupt)
        _pending_interrupt = null
    for p in _slot_processors[slot_index]:
        p.execute(SimWorld)
    slot_tick.emit(slot_index, day_index)
    slot_index = (slot_index + 1) % SLOTS_PER_DAY
    if slot_index == 0:
        day_index += 1
        if day_index % DAYS_PER_WEEK == 0:
            week_index += 1
            for p in _week_processors:
                p.execute(SimWorld)
            week_tick.emit(week_index)

func register_slot_processor(slot: int, processor: SimProcessor) -> void:
    _slot_processors[slot].append(processor)

func register_all_slots(processor: SimProcessor) -> void:
    for i in 8:
        _slot_processors[i].append(processor)

func register_week_processor(processor: SimProcessor) -> void:
    _week_processors.append(processor)
```

**Remove** all `DayPhase` references. Old `day_open/activity/day_close` signals are gone.

#### Acceptance Criteria
- Console output logs slot name (use `enums.gd` TimeSlot keys) advancing EARLY_MORNING → ... → MIDDLE_OF_NIGHT each 0.5s.
- After 56 slot-ticks `week_tick` fires exactly once.
- Pause and time_scale still function.

---

### S-03 — Actor Node + Component Assembly + SimWorld + Bootstrap

**The biggest structural change. Take your time here.**

#### Files
| Action | Path |
|---|---|
| NEW | `scripts/sim/actor.gd` |
| DELETE (after green) | `scripts/sim/actor_state.gd` |
| REWRITE | `scripts/autoloads/sim_world.gd` |
| REWRITE | `scripts/autoloads/sim_bootstrap.gd` |

#### Build

`actor.gd` — Node base class. Components are child resources, not flat fields:
```gdscript
class_name Actor extends Node

@export var actor_id: StringName = &""
@export var actor_role: StringName = &""   # "farmer", "merchant", "lord", "doctor"

# Components — assigned at construction, queried by processors
var aptitude: AptitudeProfile
var skills: SkillLedger
var economy: EconomicProfile
var needs: NeedsState
var contract: ContractState        # workers + lords
var directive: LordDirective       # workers only; null on merchant
var inventory: OwnerInventory      # lords/landowners only; null on others
var merchant_inv: MerchantInventory     # merchants only
var merchant_pricing: MerchantPricingModel  # merchants only
var tax_policy: LordTaxPolicy      # lords only
# behavior_schedule added in S-05
```

`sim_world.gd`:
```gdscript
extends Node

var actors: Array[Actor] = []
var market_entries: Dictionary = {}   # StringName → MarketEntry

func get_actors_by_role(role: StringName) -> Array[Actor]:
    return actors.filter(func(a): return a.actor_role == role)

func get_actor(id: StringName) -> Actor:
    for a in actors:
        if a.actor_id == id: return a
    return null

func get_market(good_id: StringName) -> MarketEntry:
    return market_entries.get(good_id, null)
```

`sim_bootstrap.gd` — construct one farmer, one merchant, one lord using component model:
```gdscript
func _seed_world() -> void:
    var farmer := _make_actor(&"farmer_01", &"farmer")
    farmer.aptitude = AptitudeProfile.new()
    farmer.aptitude.athleticism = 8; farmer.aptitude.charisma = 3; farmer.aptitude.intelligence = 3
    farmer.skills = SkillLedger.new()
    farmer.economy = EconomicProfile.new(); farmer.economy.coin = 20.0
    farmer.needs = NeedsState.new()
    farmer.needs.hunger.current_level = 0.9
    farmer.needs.rest.current_level = 0.9
    farmer.contract = ContractState.new(); farmer.contract.wage = 5.0
    farmer.directive = LordDirective.new()
    farmer.inventory = OwnerInventory.new()
    # land_area goes on OwnerInventory for prototype
    farmer.inventory.goods[&"land_area"] = 3.0
    SimWorld.actors.append(farmer)
    # ... merchant and lord similarly

func _make_actor(id: StringName, role: StringName) -> Actor:
    var a := Actor.new(); a.actor_id = id; a.actor_role = role
    SimWorld.add_child(a)
    return a
```

Also seed a second farmer with low ATH (ATH=3, CHA=7, INT=5) for Loop (a) validation.

#### Acceptance Criteria
- `SimWorld.get_actors_by_role("farmer")` returns both farmers.
- Accessing `farmer.aptitude.athleticism` returns correct value.
- No `actor_state.gd` references remain in any processor.

---

### S-04 — Debug View Refresh

#### Files
| Action | Path |
|---|---|
| UPDATE | `scripts/sim/visual_state_descriptor.gd` |
| UPDATE | `scripts/autoloads/readout_mapper.gd` |
| UPDATE | `scripts/ui/debug_view.gd` |

#### Build

`visual_state_descriptor.gd` — expand fields:
```gdscript
var actor_id: StringName = &""
var actor_role: StringName = &""
var current_slot: int = 0
var current_activity: int = 0       # PhaseActivity value
var hunger_level: float = 1.0
var rest_level: float = 1.0
var morale_level: float = 1.0
var coin: float = 0.0
var labor_skill_xp: float = 0.0
var condition_flags: int = 0
var incapacity_cause: int = 0
```

`readout_mapper.gd` — connect to `SimClock.slot_tick`, read new component model:
```gdscript
func _on_slot_tick(slot: int, _day: int) -> void:
    var result: Array[VisualStateDescriptor] = []
    for actor in SimWorld.actors:
        var d := VisualStateDescriptor.new()
        d.actor_id = actor.actor_id
        d.actor_role = actor.actor_role
        d.current_slot = slot
        if actor.needs:
            d.hunger_level = actor.needs.hunger.current_level
            d.rest_level   = actor.needs.rest.current_level
            d.morale_level = actor.needs.morale.current_level
            d.condition_flags = actor.needs.condition_flags
        if actor.economy:
            d.coin = actor.economy.coin
        if actor.skills:
            d.labor_skill_xp = actor.skills.get_xp(SkillDomain.LABOR)
        result.append(d)
    descriptors_updated.emit(result)
```

#### Acceptance Criteria
- Running game shows per-slot updates in UI.
- Both farmers visible with correct ATH values readable via debug print.

---

### S-05 — BehaviorSchedule + Routine System

#### Files
| Action | Path |
|---|---|
| NEW | `scripts/nodes/behavior_schedule.gd` |
| UPDATE | `scripts/sim/actor.gd` (add `schedule` field) |
| UPDATE | `scripts/autoloads/sim_bootstrap.gd` (assign routines) |

#### Build

`behavior_schedule.gd`:
```gdscript
class_name BehaviorSchedule extends Node

# Each slot holds an Array[int] of PhaseActivity values (sequential within slot)
var routine: Array = []   # Array[Array[int]], length 8

var current_slot: int = 0
var current_phase_index: int = 0

const STANDARD_ROUTINE: Array = [
    [PhaseActivity.WORKING],                    # EARLY_MORNING
    [PhaseActivity.WORKING],                    # MID_MORNING
    [PhaseActivity.WORKING],                    # LATE_MORNING
    [PhaseActivity.WORKING],                    # EARLY_AFTERNOON
    [PhaseActivity.WORKING],                    # LATE_AFTERNOON
    [PhaseActivity.SOCIALIZING],                # EARLY_EVENING
    [PhaseActivity.SOCIALIZING, PhaseActivity.RESTING],  # LATE_EVENING
    [PhaseActivity.RESTING],                    # MIDDLE_OF_NIGHT
]

const DOUBLE_SHIFT_ROUTINE: Array = [
    [PhaseActivity.WORKING], [PhaseActivity.WORKING],
    [PhaseActivity.WORKING], [PhaseActivity.WORKING],
    [PhaseActivity.WORKING], [PhaseActivity.WORKING],
    [PhaseActivity.RESTING], [PhaseActivity.RESTING],
]

func advance_slot(new_slot: int) -> void:
    current_slot = new_slot
    current_phase_index = 0

func current_activity() -> int:
    if routine.is_empty(): return PhaseActivity.IDLE
    var slot_list: Array = routine[current_slot]
    if slot_list.is_empty(): return PhaseActivity.IDLE
    return slot_list[clamp(current_phase_index, 0, slot_list.size() - 1)]

func assign_routine(variant: StringName) -> void:
    match variant:
        &"STANDARD_ROUTINE":   routine = STANDARD_ROUTINE.duplicate(true)
        &"DOUBLE_SHIFT_ROUTINE": routine = DOUBLE_SHIFT_ROUTINE.duplicate(true)
        _: routine = STANDARD_ROUTINE.duplicate(true)
```

Register a `ScheduleAdvanceProcessor` (all slots) that calls `actor.schedule.advance_slot(current_slot)` — runs first in every slot.

#### Acceptance Criteria
- Debug view shows correct activity per slot for both STANDARD and DOUBLE_SHIFT routines.
- Changing directive to DOUBLE_SHIFT shows no SOCIALIZING slots.

---

### S-06 — NeedsDecayProcessor (replaces TallyProcessor)

#### Files
| Action | Path |
|---|---|
| NEW | `scripts/processors/needs_decay_processor.gd` |
| DELETE (after green) | `scripts/processors/tally_processor.gd` |
| UPDATE | `scripts/autoloads/sim_bootstrap.gd` |

#### Build

Registered for all 8 slots via `SimClock.register_all_slots()`. Runs after `ScheduleAdvanceProcessor`.

```gdscript
class_name NeedsDecayProcessor extends SimProcessor

const HUNGER_DECAY_PER_SLOT: float = 0.05 / 8.0
const REST_WORK_COST_PER_SLOT: float = 0.08 / 8.0
const REST_IDLE_RECOVERY_PER_SLOT: float = 0.12 / 8.0
const MORALE_WORK_COST: float = 0.03       # per WORKING slot
const MORALE_SOCIAL_RECOVERY: float = 0.05  # per SOCIALIZING slot
const HUNGRY_THRESHOLD: float = 0.3
const UNABLE_MORALE_THRESHOLD: float = 0.1

func execute(world) -> void:
    for actor in world.actors:
        if not actor.needs: continue
        var activity: int = actor.schedule.current_activity() if actor.schedule else PhaseActivity.IDLE

        # Hunger: constant decay
        actor.needs.hunger.current_level = maxf(
            actor.needs.hunger.current_level - HUNGER_DECAY_PER_SLOT, 0.0)

        # Rest: activity-dependent
        match activity:
            PhaseActivity.WORKING:
                actor.needs.rest.current_level = maxf(
                    actor.needs.rest.current_level - REST_WORK_COST_PER_SLOT, 0.0)
                actor.needs.morale.current_level = maxf(
                    actor.needs.morale.current_level - MORALE_WORK_COST, 0.0)
            PhaseActivity.RESTING:
                actor.needs.rest.current_level = minf(
                    actor.needs.rest.current_level + REST_IDLE_RECOVERY_PER_SLOT, 1.0)
            PhaseActivity.SOCIALIZING:
                actor.needs.morale.current_level = minf(
                    actor.needs.morale.current_level + MORALE_SOCIAL_RECOVERY, 1.0)

        # Deficit accumulation
        if actor.needs.hunger.current_level < HUNGRY_THRESHOLD:
            actor.needs.hunger.deficit_accumulated += (HUNGRY_THRESHOLD - actor.needs.hunger.current_level)

        # Condition flags
        _update_conditions(actor)

func _update_conditions(actor: Actor) -> void:
    var flags: int = 0
    if actor.needs.hunger.current_level < HUNGRY_THRESHOLD:
        flags |= ConditionFlag.HUNGRY
    if actor.needs.morale.current_level < UNABLE_MORALE_THRESHOLD:
        flags |= ConditionFlag.UNABLE_TO_WORK
        actor.needs.incapacity_cause = WorkIncapacityCause.MORALE_COLLAPSE
    actor.needs.condition_flags = flags
```

#### Acceptance Criteria
- Over 56 slot-ticks (1 week) with no food, hunger drains to ~0.3 (7 days × 0.05 = 0.35 total decay from 0.9 start).
- DOUBLE_SHIFT farmer's morale drops faster than STANDARD farmer.
- UNABLE_TO_WORK flag triggers when morale crosses threshold; cause = MORALE_COLLAPSE.

---

### S-07 — XP Accumulation — VALIDATES LOOP (a)

#### Files
| Action | Path |
|---|---|
| NEW | `scripts/processors/xp_accumulation_processor.gd` |
| UPDATE | `scripts/autoloads/sim_bootstrap.gd` |

#### Build

Registered for all 8 slots. Runs after `NeedsDecayProcessor`. Only accumulates XP during WORKING phase.

Weight vectors (from Section 2.1 of supplement):
```
LABOR:            [w_ATH=0.8, w_CHA=0.1, w_INT=0.1]
MARKET_PERCEPTION:[w_ATH=0.05,w_CHA=0.15,w_INT=0.8]
BARTERING:        [w_ATH=0.1, w_CHA=0.7, w_INT=0.2]
```

```gdscript
class_name XpAccumulationProcessor extends SimProcessor

const BASE_XP_PER_SLOT: float = 10.0

const SKILL_WEIGHTS: Dictionary = {
    SkillDomain.LABOR:              [0.8, 0.1, 0.1],
    SkillDomain.MARKET_PERCEPTION:  [0.05, 0.15, 0.8],
    SkillDomain.BARTERING:          [0.1, 0.7, 0.2],
}

const ACTIVITY_TO_SKILL: Dictionary = {
    PhaseActivity.WORKING:  SkillDomain.LABOR,
    PhaseActivity.SELLING:  SkillDomain.BARTERING,
    PhaseActivity.BUYING:   SkillDomain.MARKET_PERCEPTION,
}

func execute(world) -> void:
    for actor in world.actors:
        if not actor.skills or not actor.aptitude or not actor.schedule: continue
        if not actor.needs or actor.needs.condition_flags & ConditionFlag.UNABLE_TO_WORK: continue

        var activity: int = actor.schedule.current_activity()
        if not ACTIVITY_TO_SKILL.has(activity): continue

        var domain: int = ACTIVITY_TO_SKILL[activity]
        var weights: Array = SKILL_WEIGHTS.get(domain, [0.33, 0.33, 0.34])
        var multiplier: float = (
            weights[0] * actor.aptitude.athleticism +
            weights[1] * actor.aptitude.charisma +
            weights[2] * actor.aptitude.intelligence
        )
        actor.skills.add_xp(domain, BASE_XP_PER_SLOT * multiplier)
```

**Bootstrap:** seed two farmers for the divergence test:
- `farmer_01`: ATH=8, CHA=3, INT=3 (high physical)
- `farmer_02`: ATH=3, CHA=3, INT=8 (low physical, high INT)

After 7 days, labor XP divergence should be clearly visible in debug output.

#### Acceptance Criteria
- farmer_01 has significantly higher `labor skill_xp` than farmer_02 after 7 days.
- Neither farmer gains XP when UNABLE_TO_WORK flag is set.
- Market perception XP only grows during BUYING/SELLING phases (merchant test).
- **Loop (a) complete.**

---

### S-08 — ProductionProcessor Rewrite

#### Files
| Action | Path |
|---|---|
| REWRITE | `scripts/processors/production_processor.gd` |

#### Build

Runs only during WORKING slots (check `BehaviorSchedule.current_activity()`).

```gdscript
class_name ProductionProcessor extends SimProcessor

const BASE_YIELD_PER_SLOT: float = 0.4   # grain per land_area unit per WORKING slot

func execute(world) -> void:
    # Group workers by employer for plot productivity cap
    var plot_contributions: Dictionary = {}   # employer_id → float (summed productivity)

    for actor in world.actors:
        if actor.actor_role != &"farmer": continue
        if not actor.schedule or actor.schedule.current_activity() != PhaseActivity.WORKING: continue
        if not actor.needs or actor.needs.condition_flags & ConditionFlag.UNABLE_TO_WORK: continue

        var employer_id: StringName = actor.contract.employer_id if actor.contract else &""
        var wp: float = _worker_productivity(actor)
        plot_contributions[employer_id] = plot_contributions.get(employer_id, 0.0) + wp

    # Apply output per lord/owner, capped at 1.0
    for actor in world.actors:
        if actor.actor_role != &"lord" or not actor.inventory: continue
        var land: float = actor.inventory.goods.get(&"land_area", 0.0)
        if land <= 0.0: continue
        var plot_prod: float = minf(plot_contributions.get(actor.actor_id, 0.0), 1.0)
        var output: float = land * BASE_YIELD_PER_SLOT * plot_prod
        actor.inventory.add(&"grain", output)

func _worker_productivity(actor: Actor) -> float:
    var skill_xp: float = actor.skills.get_xp(SkillDomain.LABOR) if actor.skills else 0.0
    var skill_contrib: float = _skill_contribution(skill_xp)
    var morale: float = actor.needs.morale.current_level if actor.needs else 1.0
    var morale_frac: float = _morale_fraction(morale)
    return skill_contrib * morale_frac

func _skill_contribution(xp: float) -> float:
    # LOGARITHMIC placeholder: approaches 1.0, floor at ~0.3
    return 0.3 + 0.7 * (1.0 - exp(-xp / 5000.0))

func _morale_fraction(morale: float) -> float:
    # Linear degradation below 0.5; full at >= 0.5
    return clampf(morale / 0.5, 0.1, 1.0)
```

#### Acceptance Criteria
- Owner inventory grain increases each WORKING slot.
- High-skill farmer produces more per slot than novice.
- Two farmers both working one lord's land do not exceed 1.0 combined productivity.
- UNABLE_TO_WORK farmer produces nothing.

---

### S-09 — RoleRegistry + WageCalculator

#### Files
| Action | Path |
|---|---|
| NEW | `scripts/autoloads/role_registry.gd` |
| NEW | `scripts/autoloads/wage_calculator.gd` |
| UPDATE | `scripts/autoloads/sim_bootstrap.gd` |
| UPDATE | `project.godot` (register new autoloads) |

#### Build

`role_registry.gd`:
```gdscript
extends Node

# StringName(role_id) → { active_count: int, capacity_per_unit: float, baseline_count: int }
var _roles: Dictionary = {}

func register_role(role_id: StringName, capacity: float, baseline: int) -> void:
    _roles[role_id] = { active_count = 0, capacity_per_unit = capacity, baseline_count = baseline }

func increment(role_id: StringName) -> void:
    if _roles.has(role_id): _roles[role_id].active_count += 1

func decrement(role_id: StringName) -> void:
    if _roles.has(role_id): _roles[role_id].active_count = maxi(_roles[role_id].active_count - 1, 0)

func get_scarcity(role_id: StringName) -> float:
    # scarcity > 1.0 = fewer workers than baseline → wages rise
    if not _roles.has(role_id): return 1.0
    var entry: Dictionary = _roles[role_id]
    if entry.active_count == 0: return 5.0   # cap scarcity at 5×
    return float(entry.baseline_count) / float(entry.active_count)

func get_service_supply(role_id: StringName) -> float:
    if not _roles.has(role_id): return 0.0
    var e: Dictionary = _roles[role_id]
    return e.active_count * e.capacity_per_unit
```

`wage_calculator.gd` (pure function autoload):
```gdscript
extends Node

const BASE_WAGES: Dictionary = {
    &"farmer":  5.0,
    &"doctor":  15.0,
    &"merchant": 0.0,   # self-employed
}

func calculate_wage(actor: Actor, region_id: StringName) -> float:
    var base: float = BASE_WAGES.get(actor.actor_role, 5.0)
    var skill_xp: float = actor.skills.get_xp(SkillDomain.LABOR) if actor.skills else 0.0
    var skill_mod: float = _skill_modifier(skill_xp)
    var scarcity: float = RoleRegistry.get_scarcity(actor.actor_role)
    var scarcity_mod: float = _scarcity_modifier(scarcity)
    return base * skill_mod * scarcity_mod

func _skill_modifier(xp: float) -> float:
    return 0.5 + 0.5 * (1.0 - exp(-xp / 3000.0))

func _scarcity_modifier(scarcity: float) -> float:
    return clampf(scarcity, 0.5, 3.0)
```

Register a `WageAssessmentProcessor` on the week processor list that iterates all actors with `ContractState` and calls `WageCalculator.calculate_wage()`.

Seed in bootstrap: 3 doctors. Add a debug action (button or key) to `RoleRegistry.decrement("doctor")` — needed for Loop (c) test.

#### Acceptance Criteria
- Initial 3 doctors: wage = base × 1.0 scarcity modifier.
- Decrement 1 doctor: scarcity = 3/2 = 1.5; next week_tick doctor wage increases by ~1.5×.
- Decrement 2 doctors: scarcity = 3/1 = 3.0 (cap); wage at 3× base.

---

### S-10 — Demand Signals + MarketEntry Accumulation

#### Files
| Action | Path |
|---|---|
| NEW | `scripts/processors/demand_signal_processor.gd` |
| UPDATE | `scripts/autoloads/sim_world.gd` (seed market entries) |
| UPDATE | `scripts/autoloads/sim_bootstrap.gd` |

#### Build

Demand signals fire once per day (register on slot 7: MIDDLE_OF_NIGHT) to avoid 8× overcounting per day.

```gdscript
class_name DemandSignalProcessor extends SimProcessor

const PREFERRED_WEEKLY_FOOD: float = 5.0

func execute(world) -> void:
    var grain_retail: MarketEntry = world.get_market(&"grain_retail")
    if not grain_retail: return

    for actor in world.actors:
        if not actor.needs: continue
        # Demand = preferred weekly food weighted by hunger urgency
        var urgency: float = 1.0 + (1.0 - actor.needs.hunger.current_level)
        grain_retail.demand += PREFERRED_WEEKLY_FOOD * urgency
```

Seed in bootstrap:
```gdscript
var grain_wholesale := MarketEntry.new()
grain_wholesale.good_id = &"grain_wholesale"
grain_wholesale.market_type = MarketType.GOODS
grain_wholesale.base_price = 0.7; grain_wholesale.price_elasticity = 0.8
SimWorld.market_entries[&"grain_wholesale"] = grain_wholesale

var grain_retail := MarketEntry.new()
grain_retail.good_id = &"grain_retail"
grain_retail.market_type = MarketType.GOODS
grain_retail.base_price = 1.0; grain_retail.price_elasticity = 0.6   # more inelastic
SimWorld.market_entries[&"grain_retail"] = grain_retail

var healthcare := MarketEntry.new()
healthcare.good_id = &"healthcare"
healthcare.market_type = MarketType.SERVICE_LABOR
healthcare.base_price = 5.0; healthcare.price_elasticity = 0.4       # very inelastic
SimWorld.market_entries[&"healthcare"] = healthcare
```

#### Acceptance Criteria
- `grain_retail.demand` grows each day; resets to 0 after weekly clearance (S-11/12 prerequisite).
- Hungry actors contribute higher demand than well-fed actors.
- Debug view shows demand accumulating in market entries.

---

### S-11 — WholesaleMarketProcessor

#### Files
| Action | Path |
|---|---|
| NEW | `scripts/processors/wholesale_market_processor.gd` |
| DELETE (after green) | `scripts/processors/market_processor.gd` |

#### Build

Runs on week_tick.

```gdscript
class_name WholesaleMarketProcessor extends SimProcessor

const EPSILON: float = 0.01

func execute(world) -> void:
    var market: MarketEntry = world.get_market(&"grain_wholesale")
    if not market: return

    # Step 1: owners push surplus grain to wholesale supply
    for actor in world.actors:
        if not actor.inventory: continue
        var grain: float = actor.inventory.goods.get(&"grain", 0.0)
        var subsistence_reserve: float = 2.0   # owner keeps this, rest goes to market
        var surplus: float = maxf(grain - subsistence_reserve, 0.0)
        market.supply += surplus
        market.supply_source_count += (1 if surplus > 0.0 else 0)

    # Step 2: clear wholesale price
    market.equilibrium_price = _clear_price(market)

    # Step 3: merchant buys at wholesale (if margin clears)
    for actor in world.actors:
        if actor.actor_role != &"merchant" or not actor.merchant_inv: continue
        if not actor.merchant_pricing: continue
        var expected_retail: float = actor.merchant_pricing.expected_sale_price
        var projected_margin: float = expected_retail - market.equilibrium_price
        if projected_margin >= actor.merchant_pricing.target_margin * expected_retail:
            var affordable: float = actor.economy.coin / market.equilibrium_price if actor.economy else 0.0
            var buy_qty: float = minf(market.supply, affordable)
            actor.economy.coin -= buy_qty * market.equilibrium_price
            actor.merchant_inv.add(&"grain", buy_qty)
            actor.merchant_pricing.last_farm_gate_price = market.equilibrium_price
            market.supply -= buy_qty

    # Step 4: owners receive coin for sold grain (proportional split)
    # simplified: credit each owner proportional to contribution
    # (full settlement ledger deferred)

    # Reset demand accumulator for next week
    market.demand = 0.0

func _clear_price(market: MarketEntry) -> float:
    if market.supply <= 0.0: return market.base_price * 2.0
    var ratio: float = market.demand / (market.supply + EPSILON)
    return market.base_price * pow(ratio, 1.0 / market.price_elasticity)
```

#### Acceptance Criteria
- With abundant grain supply, wholesale price trends down over multiple weeks.
- With no grain production, wholesale price spikes.
- Merchant inventory fills after clearance if margin clears.

---

### S-12 — RetailMarketProcessor + Consumer Purchase — VALIDATES LOOP (b)

#### Files
| Action | Path |
|---|---|
| NEW | `scripts/processors/retail_market_processor.gd` |

#### Build

Runs on week_tick, after WholesaleMarketProcessor.

```gdscript
class_name RetailMarketProcessor extends SimProcessor

func execute(world) -> void:
    var market: MarketEntry = world.get_market(&"grain_retail")
    if not market: return

    # Merchant pushes inventory to retail supply
    for actor in world.actors:
        if actor.actor_role != &"merchant" or not actor.merchant_inv: continue
        var qty: float = actor.merchant_inv.goods.get(&"grain", 0.0)
        market.supply += qty
        actor.merchant_pricing.expected_sale_price = market.equilibrium_price  # update for next week

    # Clear retail price
    market.equilibrium_price = _clear_price(market)

    # Consumer purchase
    for actor in world.actors:
        if not actor.needs or not actor.economy: continue
        var budget: float = actor.economy.coin
        var qty_wanted: float = _demand_quantity(actor, market.equilibrium_price)
        var qty_buy: float = minf(qty_wanted, budget / market.equilibrium_price)
        var cost: float = qty_buy * market.equilibrium_price

        # Find a merchant with stock
        for seller in world.get_actors_by_role(&"merchant"):
            if not seller.merchant_inv: continue
            var available: float = seller.merchant_inv.goods.get(&"grain", 0.0)
            var actual: float = minf(qty_buy, available)
            if actual <= 0.0: continue
            actor.economy.coin -= actual * market.equilibrium_price
            seller.economy.coin += actual * market.equilibrium_price
            seller.merchant_inv.take(&"grain", actual)
            # Resolve hunger need
            var satiation: float = actual / qty_wanted if qty_wanted > 0.0 else 0.0
            actor.needs.hunger.current_level = minf(
                actor.needs.hunger.current_level + satiation * 0.5, 1.0)
            actor.needs.hunger.deficit_accumulated = maxf(
                actor.needs.hunger.deficit_accumulated - satiation * 0.2, 0.0)
            break

    market.demand = 0.0; market.supply = 0.0

func _demand_quantity(actor: Actor, price: float) -> float:
    var preferred: float = 5.0
    return minf(preferred, actor.economy.coin / price) if price > 0.0 else preferred

func _clear_price(market: MarketEntry) -> float:
    if market.supply <= 0.0: return market.base_price * 2.0
    var ratio: float = market.demand / (market.supply + 0.01)
    return market.base_price * pow(ratio, 1.0 / market.price_elasticity)
```

#### Acceptance Criteria
- With adequate production, consumer hunger stays near full each week.
- Kill all production: retail price climbs each week, hunger deficits accumulate.
- Price responds to supply/demand ratio — not assigned directly.
- **Loop (b) complete.**

---

### S-13 — Labor Cascade Validation — VALIDATES LOOP (c)

#### Files
| Action | Path |
|---|---|
| NEW | `scripts/processors/service_labor_market_processor.gd` |
| UPDATE | `scripts/autoloads/sim_bootstrap.gd` (3 doctors) |
| UPDATE | `scripts/ui/debug_view.gd` (cascade readout) |

#### Build

`service_labor_market_processor.gd` — runs on week_tick:
```gdscript
class_name ServiceLaborMarketProcessor extends SimProcessor

func execute(world) -> void:
    var healthcare: MarketEntry = world.get_market(&"healthcare")
    if not healthcare: return

    # SERVICE_LABOR: supply recalculated from RoleRegistry each tick (no carryover)
    healthcare.supply = RoleRegistry.get_service_supply(&"doctor")
    healthcare.supply_source_count = RoleRegistry._roles.get(&"doctor", {}).get("active_count", 0)

    # Clear price
    if healthcare.supply <= 0.0:
        healthcare.equilibrium_price = healthcare.base_price * 5.0
    else:
        var ratio: float = healthcare.demand / (healthcare.supply + 0.01)
        healthcare.equilibrium_price = healthcare.base_price * pow(ratio, 1.0 / healthcare.price_elasticity)

    # Consumers purchase healthcare (same purchase pattern as retail)
    for actor in world.actors:
        if not actor.needs or not actor.economy: continue
        var can_afford: bool = actor.economy.coin >= healthcare.equilibrium_price
        if can_afford:
            actor.economy.coin -= healthcare.equilibrium_price
            actor.needs.health.current_level = minf(actor.needs.health.current_level + 0.3, 1.0)
        else:
            actor.needs.health.deficit_accumulated += 0.1
            # Health deficit → productivity penalty (read by ProductionProcessor)

    healthcare.demand = 0.0
```

Bootstrap: seed 3 doctors with role registered in RoleRegistry. Debug UI: add a "Kill Doctor" button that calls `RoleRegistry.decrement("doctor")`.

**Cascade to verify manually:**
1. Press "Kill Doctor" × 2 → RoleRegistry active_count: 3 → 1
2. Next week_tick: healthcare supply drops to 1/3
3. Healthcare price spikes (~3× due to SERVICE_LABOR inelasticity)
4. Actors who can't afford healthcare: health deficit accumulates
5. Health deficit → reduced productivity (extend `_worker_productivity` in ProductionProcessor to read health)
6. Reduced GOODS supply → food price shifts upward
7. Doctor's wage spikes via WageCalculator (scarcity = 3.0 cap)

Extend `ProductionProcessor._worker_productivity()`:
```gdscript
func _worker_productivity(actor: Actor) -> float:
    var skill_contrib: float = _skill_contribution(actor.skills.get_xp(SkillDomain.LABOR) if actor.skills else 0.0)
    var morale_frac: float = _morale_fraction(actor.needs.morale.current_level if actor.needs else 1.0)
    var health_frac: float = clampf(actor.needs.health.current_level if actor.needs else 1.0, 0.1, 1.0)
    return skill_contrib * morale_frac * health_frac
```

#### Acceptance Criteria
- Kill 2 doctors: next week doctor wage is ~3× base.
- Healthcare price spikes; actors with insufficient coin show health deficits accumulating.
- After 3 weeks without healthcare, productivity drops → grain supply drops → food price rises.
- All three cascade chains visible in debug output without any scripted triggers.
- **Loop (c) complete.**

---

## Summary Table

| Story | Title | Depends On | Validates |
|---|---|---|---|
| S-01 | Resource Data Layer | — | — |
| S-02 | SimClock 8-Slot | — | — |
| S-03 | Actor Component Model + Bootstrap | S-01, S-02 | — |
| S-04 | Debug View Refresh | S-03 | — |
| S-05 | BehaviorSchedule + Routines | S-02, S-03 | — |
| S-06 | NeedsDecayProcessor | S-05 | — |
| S-07 | XP Accumulation | S-05, S-06 | **(a)** |
| S-08 | ProductionProcessor Rewrite | S-05, S-06 | — |
| S-09 | RoleRegistry + WageCalculator | S-03 | — |
| S-10 | Demand Signals + MarketEntry | S-06, S-03 | — |
| S-11 | WholesaleMarketProcessor | S-08, S-10 | — |
| S-12 | RetailMarketProcessor | S-11, S-09 | **(b)** |
| S-13 | Labor Cascade Validation | S-09, S-12 | **(c)** |

---

*Written by Indie — ship it.*
