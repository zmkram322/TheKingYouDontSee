class_name WalkTo
extends Step

# Get to a place on foot. The first leaf, and a deliberate choice as the first
# one: being somewhere is a fact the world already holds, so satisfaction is
# just "am I standing there?" — nothing to store, nothing to restore.
#
# Reads and writes the subject's position through its stat accessor, which
# doubles as the blackboard. Nothing about a specific world is named here: hand
# it any subject that answers to `position` and it works.

const ARRIVE_EPSILON := 4.0   # close enough, without float-equality games

var target: Vector2
var speed: float


func _init(new_target: Vector2, new_speed: float = 90.0) -> void:
	target = new_target
	speed = new_speed


func is_satisfied(who) -> bool:
	return who.stat(&"position").distance_to(target) <= ARRIVE_EPSILON


func advance(who, delta: float) -> bool:
	var here: Vector2 = who.stat(&"position")
	var to_target := target - here
	var stride := speed * delta
	if to_target.length() <= stride:
		who.set_stat(&"position", target)
		return true
	who.set_stat(&"position", here + to_target.normalized() * stride)
	return is_satisfied(who)


func describe(_who) -> String:
	return "walking to (%.0f, %.0f)" % [target.x, target.y]
