class_name WalkTo
extends Step

# Get to a place on foot. The first leaf, and a deliberate choice as the first
# one: being somewhere is a fact the world already holds, so satisfaction is
# just "am I standing there?" — nothing to store, nothing to restore.
#
# Reads and writes the subject's position through its stats, which doubles as
# the blackboard. Nothing about a specific world is named here: hand it any
# subject with a `stats.position` and it works.

const ARRIVE_EPSILON := 4.0   # close enough, without float-equality games

var target: Vector2
var speed: float


func _init(new_target: Vector2, new_speed: float = 90.0) -> void:
	target = new_target
	speed = new_speed


func is_satisfied(who) -> bool:
	return who.stats.position.distance_to(target) <= ARRIVE_EPSILON


func advance(who, delta: float) -> void:
	var here: Vector2 = who.stats.position
	var to_target := target - here
	var stride := speed * delta
	if to_target.length() <= stride:
		who.stats.position = target
		return
	who.stats.position = here + to_target.normalized() * stride


func describe(_who) -> String:
	return "walking to (%.0f, %.0f)" % [target.x, target.y]
