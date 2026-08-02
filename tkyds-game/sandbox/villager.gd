class_name Villager
extends RefCounted

# Pairs a sim Actor with what the sandbox adds: a body in space and a current
# doing. Identity and stats stay entirely in Actor/StatStore — this class
# only carries what the sandbox needed on top (position, activity, plan).

var actor: Actor
var position: Vector2
var doing: Activity = null           # what they're doing right now (null = about to choose)
var plan: Array[Activity] = []       # what comes after; kept as a simple queue, not a combinator
var last_decision: UtilityBrain.Decision = null   # kept so the inspector can show why


func _init(new_actor: Actor, start_position: Vector2) -> void:
	actor = new_actor
	position = start_position


func doing_label() -> String:
	if doing == null:
		return "choosing…"
	return doing.describe()


# The pre-emption entry point: forces a fresh decision now, abandoning
# whatever's in progress, rather than waiting for the current Activity to
# finish. world.choose() already rebuilds doing/plan unconditionally, so
# there's no special cancel path needed — reconsidering mid-walk just
# re-routes from the current position, and reconsidering mid-Perform simply
# never applies that Perform's effect (nothing partial to unwind). Takes
# world rather than storing a back-reference, so Villager stays constructible
# without one.
func reconsider(world: SandboxWorld) -> void:
	world.choose(self)
