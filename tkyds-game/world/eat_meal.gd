class_name EatMeal
extends Step

# Take a meal where you're standing. World-specific content, not brain/'s
# business: the brain suites keep their own inner "Eat" as a test fixture
# (see brain_choice_smoke.gd) — this is that same shape given a real home,
# under a different name on purpose. Godot resolves a name collision between
# a global class_name and an inner class silently and in whichever direction
# scan order happens to land, so "Eat" was already spoken for the moment this
# folder tried to claim it too; see brain_choice_smoke.gd's inner class,
# which is a fixture and stays exactly as it is.
#
# Satisfaction is a plain fact about the character — hunger at zero or below
# — nothing stored, nothing to restore if the meal is interrupted. advance()
# drains hunger at WorldTune.EAT_RATE, the same rate the shared scoring scale
# is priced against, so an author tuning obligations against NEED_FULL is
# also tuning how long a meal takes.


func is_satisfied(who) -> bool:
	return who.stat(&"hunger") <= 0.0


func advance(who, delta: float) -> bool:
	who.set_stat(&"hunger", maxf(0.0, who.stat(&"hunger") - WorldTune.EAT_RATE * delta))
	return is_satisfied(who)


func describe(_who) -> String:
	return "eating"


func verb(_who) -> StringName:
	return &"eating"
