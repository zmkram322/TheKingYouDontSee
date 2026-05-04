class_name WorkSlotActivity
extends Activity

# Transient — contributes deltas to its WorkDayActivity parent and is then
# discarded. Class-level constants are this activity-class's calibration;
# different work-activity classes (BlacksmithSlotActivity, etc.) declare
# their own. Phase 2 calibration: 1 grain/slot, no XP/calorie wiring yet.

const W_ATH := 0.7
const W_CHA := 0.0
const W_INT := 0.3
const BASE_GRAIN := 1.0          # v0: matches Phase 2 (4 grain/day per worker)
const BASE_XP := 0.0             # v0: aptitudes not yet integrated
const BASE_CALORIES := 0.0       # v0: hunger system deferred (R2.4)
const BASE_FATIGUE := 0.0        # v0: fatigue system deferred
const SLOTS_PER_DAY := 4

# Set at construction by WorkingInterest.
var worker: Actor
var contract: LaborContract

func on_close() -> bool:
	if parent_activity_ref == null:
		push_error("WorkSlotActivity must have a parent (WorkDayActivity).")
		return false
	var day := parent_activity_ref as WorkDayActivity
	if day == null:
		push_error("WorkSlotActivity parent must be a WorkDayActivity.")
		return false

	var aptitude_factor: float = _aptitude_factor()
	var slot_grain: float = BASE_GRAIN * (1.0 + _variance(aptitude_factor))
	var slot_xp: float = BASE_XP * aptitude_factor
	var slot_calories: float = BASE_CALORIES
	var slot_fatigue: float = BASE_FATIGUE
	var slot_wage: float = (contract.wage_per_slot if contract != null else 0.0)

	day.grain_produced_today += slot_grain
	day.farming_xp_earned += slot_xp
	day.calories_burned += slot_calories
	day.fatigue_incurred += slot_fatigue
	day.wages_accrued += slot_wage
	day.slots_worked += 1
	return true

func _aptitude_factor() -> float:
	# v0 placeholder: aptitude integration is post-Phase-2.5. Returning 0.0
	# preserves Phase 2 numerics (no productivity modulation).
	return 0.0

func _variance(_factor: float) -> float:
	# v0 deterministic: no roll. Phase 3+ ties this to the math directive's
	# variance band; gated on aptitude integration.
	return 0.0
