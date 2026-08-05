class_name ConvertStock
extends Step

# Turns one place-fact into another over time, one batch at a time, with the
# batch's own progress kept as a fact on the PLACE being worked — never on
# this Step, and never on whoever happens to be doing the work. An
# interruption loses nothing: grinding grain or baking bread simply resumes
# from whatever the place itself already remembers next time someone picks
# the work back up, the same discipline WalkTo already uses for "where am I
# standing".
#
# One leaf covers both the mill's grinding (grain -> flour_ground) and the
# inn's baking (flour -> bread) — same shape, different place and stats,
# rather than two near-identical classes for what is really one idea:
# something here is slowly turning one stock into another. See
# world/village.gd for both places it's put to work, and WorldTune for the
# batch sizes and durations each is tuned with.

var world: VillageWorld
var place: StringName
var from_stat: StringName
var to_stat: StringName
var progress_stat: StringName
var seconds_per_batch: float
var batch_size: float
var _description: String
var _verb: StringName


func _init(new_world: VillageWorld, new_place: StringName, new_from_stat: StringName,
		new_to_stat: StringName, new_progress_stat: StringName, new_seconds_per_batch: float,
		new_batch_size: float, new_description: String, new_verb: StringName) -> void:
	world = new_world
	place = new_place
	from_stat = new_from_stat
	to_stat = new_to_stat
	progress_stat = new_progress_stat
	seconds_per_batch = new_seconds_per_batch
	batch_size = new_batch_size
	_description = new_description
	_verb = new_verb


func is_satisfied(_who) -> bool:
	return world.place_stat(place, from_stat) <= 0.0


func advance(_who, delta: float) -> bool:
	if world.place_stat(place, from_stat) <= 0.0:
		return true
	var progress: float = world.place_stat(place, progress_stat) + delta
	while progress >= seconds_per_batch and world.place_stat(place, from_stat) > 0.0:
		progress -= seconds_per_batch
		var take: float = minf(batch_size, world.place_stat(place, from_stat))
		world.set_place_stat(place, from_stat, world.place_stat(place, from_stat) - take)
		world.set_place_stat(place, to_stat, world.place_stat(place, to_stat) + take)
	world.set_place_stat(place, progress_stat, progress)
	return is_satisfied(_who)


func describe(_who) -> String:
	return _description


func verb(_who) -> StringName:
	return _verb
