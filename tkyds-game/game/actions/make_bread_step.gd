class_name MakeBreadStep
extends ActionStep

# The baking itself. ONE TICK: take grain_per_loaf grain, add one loaf of
# bread — a CREATION and a DESTRUCTION through their own doors (Inventory's
# take() and add()), never hand_over. That is deliberate: this is not a
# transfer between two inventories, it is grain being consumed and bread
# being made, so the world's total grain legitimately falls here and the
# world's total bread legitimately rises, both at once, both through the door
# that exists for exactly that. See probe claim 37.

# Three grain for one loaf — crude and dear. This ratio IS the make-or-buy
# gap: a baker's oven arrives at rung 9b at one-to-one, and that efficiency
# difference is the entire reason a baker is worth employing rather than a
# formality nobody would ever choose over doing it himself. No extra
# mechanism needed to make baking worse than buying — the number already
# says so.
@export var grain_per_loaf := 3


# NOT A WORKSTATION, and that is a constraint rather than an oversight.
# WorkStep.YIELD_NAME is a const, and rung 5 refused to export it on stated
# grounds: a station making something other than grain "comes from a Recipe
# (rung 9a), which owns the output and the time it takes together." A hearth
# here would land 9a's Recipe five gates early against that recorded refusal.
#
# WHICH IS WHY THIS CANNOT COST WORLD TIME YET. Duration needs somewhere to
# bank the fraction — that is a station, and a station is the Recipe this
# rung is refusing to build early. So the cost is paid in grain, not hours,
# until 9b: _hours is unused for the identical reason EatStep's is — a loaf
# baked is an impulse, not a duration in progress.
func advance(person: Person, _hours: float) -> bool:
	var inventory := person.get_inventory()
	if inventory == null:
		return true
	if not inventory.take(WorkStep.YIELD_NAME, grain_per_loaf):
		# Not enough grain for even one loaf. Nothing else happens — a failed
		# take marks the CANDIDATE, never the world (Decision 23, same as
		# EatStep's refusal).
		return true
	inventory.add(Eat.BREAD_NAME, 1)
	return true


func describe(_person: Person) -> String:
	return "baking"
