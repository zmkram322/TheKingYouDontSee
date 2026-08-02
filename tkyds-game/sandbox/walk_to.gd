class_name WalkTo
extends Activity

# Walking is an Activity like any other — nothing about the sandbox loop
# treats movement as special. Arriving writes the PLACE stat, so
# position-as-fact (the location + tags model the rest of the sim reads)
# stays true even while the body's motion through space is pure skin.

const ARRIVE_EPSILON := 4.0   # a few px — "close enough" without float-equality games

var _villager: Villager
var _world: SandboxWorld
var _place: StringName


func _init(villager: Villager, world: SandboxWorld, place: StringName) -> void:
	_villager = villager
	_world = world
	_place = place


func advance(delta: float) -> void:
	var target: Vector2 = _world.places[_place]
	var to_target := target - _villager.position
	var step := SandboxTune.WALK_SPEED * delta
	if to_target.length() <= maxf(step, ARRIVE_EPSILON):
		_arrive(target)
		return
	_villager.position += to_target.normalized() * step


func _arrive(target: Vector2) -> void:
	_villager.position = target
	_world.stats.write_primary(_villager.actor, Stat.PLACE, _place)
	finished = true


func describe() -> String:
	return "→ " + String(_place)
