class_name CarryStock
extends Step

# Carries a stock from one place to another over time — flour from the mill
# to the inn, grain from the field to the mill, both the same shape: drain
# one place-fact, fill another, at a plain rate, nothing stored beyond the
# facts themselves. Same reasoning as ConvertStock: one leaf, not two, for
# what is really one idea done twice with different endpoints.
#
# Deliberately says nothing about getting there — pair it after a WalkTo in
# a Sequence, the same way emit_smoke.gd's DeliverFlour always followed one.
# This Step only knows how to move stock once whoever's carrying it is
# standing in the right place; being there is somebody else's job.

var world: VillageWorld
var from_place: StringName
var from_stat: StringName
var to_place: StringName
var to_stat: StringName
var rate: float
var _description: String


func _init(new_world: VillageWorld, new_from_place: StringName, new_from_stat: StringName,
		new_to_place: StringName, new_to_stat: StringName, new_rate: float,
		new_description: String) -> void:
	world = new_world
	from_place = new_from_place
	from_stat = new_from_stat
	to_place = new_to_place
	to_stat = new_to_stat
	rate = new_rate
	_description = new_description


func is_satisfied(_who) -> bool:
	return world.place_stat(from_place, from_stat) <= 0.0


func advance(_who, delta: float) -> bool:
	var have: float = world.place_stat(from_place, from_stat)
	var take: float = minf(have, rate * delta)
	world.set_place_stat(from_place, from_stat, have - take)
	world.set_place_stat(to_place, to_stat, world.place_stat(to_place, to_stat) + take)
	return is_satisfied(_who)


func describe(_who) -> String:
	return _description


func verb(_who) -> StringName:
	return &"carrying"
