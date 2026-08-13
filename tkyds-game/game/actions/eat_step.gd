class_name EatStep
extends ActionStep

# The eating itself. ONE TICK, ONE LOAF: take(Eat.BREAD_NAME, 1), and if that
# succeeds hunger drops by an authored amount, all in a single tick. No
# fraction anywhere, no remainder to store.
#
# A timed meal would need somewhere to hold the meal-in-progress, and that is
# the identical missing thing as the fractional loaf's home over on
# Workstation.output_part_made (Decision 23): one absence, two symptoms. It
# also makes Eat a natural SPIKE rather than a hold — it can win the ballot
# for exactly the one tick it takes to eat, which is what keeps bedtime still
# (see eat.gd's header on the score, and the rung's Moment prediction).

# What one loaf fixes. With Brain.base_hunger_per_hour = 4.0 that's two meals
# a day, and the cadence is forced by conservation — meals/day = 24 × rate ÷
# loaf — so eat.gd's bite changes WHEN he eats, never how often.
@export var hunger_a_loaf_fixes := 50.0


# _hours is deliberately unused — a meal is an impulse, not a duration, unlike
# WorkStep which scales its yield by however long the tick was.
func advance(person: Person, _hours: float) -> bool:
	var inventory := person.get_inventory()
	if inventory == null:
		return true
	if not inventory.take(Eat.BREAD_NAME, 1):
		# No bread, no meal, nothing else happens. A failed take marks the
		# CANDIDATE — he tried and couldn't — never the world (Decision 23).
		return true
	# HUNGER WRITTEN HERE IS AN EFFECT, NOT UPKEEP, and the design permits it:
	# eating is why he chose this action. Hunger is written from exactly one
	# other place in the whole codebase — brain.gd's upkeep line — and this is
	# the one exemption to that rule. See probe claim 35.
	var hungry: float = person.stats.get_stat(&"hunger")
	person.stats.set_stat(&"hunger", maxf(hungry - hunger_a_loaf_fixes, 0.0))
	return true


func describe(_person: Person) -> String:
	return "eating"
