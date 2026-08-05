class_name WorkField
extends Step

# Working the field: grain piles up on the FIELD place for as long as
# someone is out there doing it, capped so an unhauled pile doesn't grow
# without bound. Never satisfied and never impossible on its own — same
# shape as curve_smoke.gd's NeverFinishes — because there is no natural end
# to a day's labour; only losing the decision (dusk falling, hunger rising)
# ever ends it, exactly the way the day arc is meant to work.
#
# The yield is a fact about the FIELD, not about whoever is working it or
# about this Step — three farmhands can each hold their own WorkField and
# all three add to the same pile, the same sharing WalkTo already relies on
# for "where am I" being a fact about the character, not the Step.

var world: VillageWorld
var field: StringName
var stat_name: StringName
var yield_rate: float
var cap: float


func _init(new_world: VillageWorld, new_field: StringName, new_stat_name: StringName,
		new_yield_rate: float, new_cap: float) -> void:
	world = new_world
	field = new_field
	stat_name = new_stat_name
	yield_rate = new_yield_rate
	cap = new_cap


func is_satisfied(_who) -> bool:
	return false


func advance(_who, delta: float) -> bool:
	var have: float = world.place_stat(field, stat_name)
	if have < cap:
		world.set_place_stat(field, stat_name, minf(cap, have + yield_rate * delta))
	return false


func describe(_who) -> String:
	return "working the field"


func verb(_who) -> StringName:
	return &"working"
