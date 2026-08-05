class_name EatBread
extends Step

# Take a meal from the inn's own bread stock — the farmhands' half of the
# demand chain the miller and innkeeper feed. Distinct from EatMeal (which
# only drains the eater's own hunger at a hearth with no stock behind it):
# this one also drains a place fact, which is exactly what makes a farmhand
# eating pull the whole chain three deep. Consumption and relief move
# together at the same rate, one point of bread for one point of hunger
# cleared, so a hungry village really does eat the inn's larder down.
#
# is_possible is the seam that keeps this honest when the loaves run out
# mid-meal: already satisfied is always possible (there's nothing left to
# do), and otherwise possible only for as long as there's bread on the
# shelf. A farmhand caught with an empty larder abandons rather than
# standing there having "finished" a meal she never got — see Character's
# own note on abandon vs finish.

var world: VillageWorld
var inn: StringName
var bread_stat: StringName
var rate: float


func _init(new_world: VillageWorld, new_inn: StringName, new_bread_stat: StringName,
		new_rate: float) -> void:
	world = new_world
	inn = new_inn
	bread_stat = new_bread_stat
	rate = new_rate


func is_satisfied(who) -> bool:
	return who.stat(&"hunger") <= 0.0


func is_possible(who) -> bool:
	return is_satisfied(who) or world.place_stat(inn, bread_stat) > 0.0


func advance(who, delta: float) -> bool:
	var hunger: float = who.stat(&"hunger")
	var bread: float = world.place_stat(inn, bread_stat)
	var take: float = minf(rate * delta, minf(hunger, bread))
	who.set_stat(&"hunger", hunger - take)
	world.set_place_stat(inn, bread_stat, bread - take)
	return is_satisfied(who)


func describe(_who) -> String:
	return "eating bread at the inn"


func verb(_who) -> StringName:
	return &"eating"
