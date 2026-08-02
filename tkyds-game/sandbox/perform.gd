class_name Perform
extends Activity

# Doing the chosen action where it happens: count down the duration, then
# apply the effect exactly once and log it. The Activity doesn't know or
# care what the effect does — that's the catalog's business (data, not code).

var _villager: Villager
var _world: SandboxWorld
var _option: ActionOption
var _elapsed := 0.0


func _init(villager: Villager, world: SandboxWorld, option: ActionOption) -> void:
	_villager = villager
	_world = world
	_option = option


func advance(delta: float) -> void:
	_elapsed += delta
	if _elapsed < _option.duration:
		return
	_option.finish(_world.stats, _villager.actor)
	_world.log_lines.append("%s finishes %s." % [_villager.actor.person_name, _option.label])
	finished = true


func describe() -> String:
	return _option.label
