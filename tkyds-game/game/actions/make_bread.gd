class_name MakeBread
extends Action

# Turn grain into bread, crude and dear, at his own hands rather than a
# baker's oven. The first closed loop in the project: work → grain → bread →
# eat → work, with no authored fiction anywhere in the chain — see
# make_bread_step.gd for why it costs grain rather than time.
#
# ANYONE WITH GRAIN CAN DO THIS. No hearth, no station, no owner, no trade —
# get_inventory() and the two doors take() and add() open, same as Eat reaches
# for exactly one door. The badness of the rate (see the step's
# grain_per_loaf) is what makes a baker's one-to-one oven worth employing at
# rung 9b rather than a formality nobody would ever pick over this.

# Item names come from where they already live — one name, one place, and
# this is not a second copy of either string. Bread is Eat's to name because
# eating is bread's whole reason for existing; grain is WorkStep's to name
# because a plot is the one thing that makes it. Reusing both is what keeps
# "bread" and "grain" each spelled in exactly one file in the whole project.
# (BREAD_NAME lives on Eat, not here, for the same reason: MakeBread produces
# it but does not get to rename what it means to a hungry man.)


# Awake and holding enough grain for a loaf. NEVER "not hungry enough" — see
# eat.gd's header for the same argument against a want-shaped gate; it applies
# here word for word.
func is_available_to(person: Person) -> bool:
	# REQUIRED, not a candidate question, and for the identical reason Eat and
	# WorkTheField both gate on it: without this a man whose hunger crosses at
	# 03:00 gets up and bakes in the dark, and it reads as a broken sleep cycle
	# rather than as a missing gate.
	if not person.brain.is_awake():
		return false
	if person.get_inventory() == null:
		return false
	# The grain half is the CANDIDATE question — does he have the makings.
	# Read off the step's own export rather than a second copy of the number,
	# so retuning grain_per_loaf on the board can never leave the gate and the
	# step disagreeing about what "enough" means.
	var making := step as MakeBreadStep
	if making == null:
		return false
	return person.get_inventory().has_at_least(WorkStep.YIELD_NAME, making.grain_per_loaf)


# What baking is worth — the weight in weight × gap^bite. Read this against
# TWO other numbers at once, and both comparisons are the point:
#
#   BELOW Eat's 130. When bread and grain are both in the bag, eating has to
#   win — you bake because you cannot eat, never the other way round. A lower
#   weight at the same hunger and the same exponent guarantees Eat outscores
#   this everywhere the two are ever both open.
#
#   ABOVE work's 103 peak, for the identical reason Eat's weight clears it: a
#   starving man holding grain has to be able to stop working to bake, or the
#   loop this rung exists to close would have a gap in it exactly where
#   Zoogs needs it — the man with grain and no bread, mid-morning, still has
#   to be able to interrupt himself.
#
# 115 and 3 are illustrative, same as every number on Eat — the author's
# tuning board, not a specification.
@export var baking_worth := 115.0
@export var bite := 3.0


func get_utility_score(person: Person) -> float:
	var hungry: float = person.stats.get_stat(&"hunger")
	return baking_worth * pow(hungry / 100.0, bite)
