class_name Activity
extends Resource

# Persistent activities survive in the activity tree (saved with the game),
# write book entries at close, are queryable by name. Transient activities
# discard after close, contribute deltas to their parent's accumulator fields.
#   - if parent_activity_ref == null → must be persistent
#   - if parent_activity_ref != null → must be transient

@export var activity_type: StringName = &""
@export var participants: Array[NodePath] = []
@export var started_tick: int = -1
@export var closed_tick: int = -1
@export var state: StringName = &"open"            # &"open" | &"closed" | &"aborted"
@export var display_name: StringName = &""         # reserved for diegetic UI surfacing
@export var parent_activity_ref: Activity = null
@export var child_activities: Array[Activity] = []

func is_persistent() -> bool:
	return parent_activity_ref == null

func begin(tick: int) -> void:
	started_tick = tick
	state = &"open"
	on_begin()

func close(tick: int) -> bool:
	if state != &"open":
		push_error("Activity.close called on non-open activity: %s (state=%s)" % [activity_type, state])
		return false
	# Children close first so transient deltas land on this activity's accumulators
	# before this activity's on_close reads them.
	for child in child_activities:
		if child.state == &"open":
			child.close(tick)
	closed_tick = tick
	var ok: bool = on_close()
	state = &"closed" if ok else &"aborted"
	return ok

func abort(tick: int) -> void:
	state = &"aborted"
	closed_tick = tick
	for child in child_activities:
		if child.state == &"open":
			child.abort(tick)
	on_abort()

# Hooks — concrete activities override these.
func on_begin() -> void:
	pass

func on_close() -> bool:
	return true

func on_abort() -> void:
	pass

# Helpers for concrete activities.
func resolve(idx: int, scene_root: Node) -> Actor:
	if idx < 0 or idx >= participants.size():
		return null
	return scene_root.get_node_or_null(participants[idx]) as Actor
