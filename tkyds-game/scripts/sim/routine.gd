class_name Routine
extends Resource

# A routine is a dict of BehaviorState, with keys that are enums.
# Keys: E.TimeSlot (int)  →  Value: Array of E.PhaseActivity (int)

var routine_id: String = ""
var _slots: Dictionary = {}

func _init() -> void:
	#for slot in E.TimeSlot.values():
		#_slots[slot] = []
	pass
	
func set_slot(slot: int, activities: Array) -> void:
	_slots[slot] = activities.duplicate()

func get_activities(slot: int) -> Array:
	return _slots.get(slot, [])

func add_activity(slot: int, activity: int) -> void:
	_slots[slot].append(activity)

func clear_slot(slot: int) -> void:
	_slots[slot] = []
