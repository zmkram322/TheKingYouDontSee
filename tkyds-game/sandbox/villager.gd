class_name Villager
extends RefCounted

# Pairs a sim Actor with what the sandbox adds: a body in space and a queue
# of goals. Identity and stats stay entirely in Actor/StatStore — this class
# only carries what the sandbox needed on top (position, the goal queue).

var actor: Actor
var position: Vector2
var goal_queue: Array[Goal] = []     # front = running now; rest = paused or waiting their turn
var last_decision: UtilityBrain.Decision = null   # kept so the inspector can show why


func _init(new_actor: Actor, start_position: Vector2) -> void:
	actor = new_actor
	position = start_position


func current_goal() -> Goal:
	return goal_queue[0] if not goal_queue.is_empty() else null


func doing_label() -> String:
	var goal := current_goal()
	if goal == null or not goal.started:
		return "choosing…"
	return goal.doing.describe()


# The pre-emption entry point: forces a fresh decision now. world.choose()
# handles what happens to whatever's currently running — if the fresh winner
# differs, the current goal is paused (pushed back one slot, not discarded)
# rather than abandoned, so it resumes exactly where it left off once the
# new goal clears. Takes world rather than storing a back-reference, so
# Villager stays constructible without one.
func reconsider(world: SandboxWorld) -> void:
	world.choose(self)
