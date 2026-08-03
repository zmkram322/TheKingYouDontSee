class_name Villager
extends RefCounted

# Pairs a sim Actor with what the sandbox adds: a body in space and an
# Orchestrator managing what it's doing. Identity and stats stay entirely in
# Actor/StatStore — this class only carries what the sandbox needed on top
# (position, the orchestrator). SandboxWorld._spawn wires up the
# orchestrator once construction needs (stats, options) are available.

var actor: Actor
var position: Vector2
var orchestrator: Orchestrator


func _init(new_actor: Actor, start_position: Vector2) -> void:
	actor = new_actor
	position = start_position


func current_goal() -> Goal:
	return orchestrator.current()


func doing_label() -> String:
	var goal := orchestrator.current()
	if goal == null or not goal.started:
		return "choosing…"
	return goal.root.describe()


# The pre-emption entry point: forces a fresh decision now. What happens to
# whatever's currently running is Orchestrator.choose()'s call — if the
# fresh winner differs, the current goal is paused (pushed back one slot,
# not discarded) rather than abandoned, so it resumes exactly where it left
# off once the new goal clears.
func reconsider() -> void:
	orchestrator.choose()
