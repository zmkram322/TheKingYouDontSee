class_name Eat
extends Action

# Eat a loaf of his own bread. The first want in the game with BOTH halves of
# Decision 20's shape alive at once — want = weight × gap^bite, with a real
# weight AND a real exponent — where StayUp, WorkTheField and Sleep each ship
# with one half switched off (gap = 1, or bite = 1 and weight = 100).
#
# IT TAKES FROM HIS OWN INVENTORY, AND NOTHING ELSE. No transfer, no place, no
# owner, no trade — get_inventory() and the one door take() opens. See
# eat_step.gd for the doing.

# One item name in one place. The step reads this as Eat.BREAD_NAME rather
# than carrying its own copy of the string.
const BREAD_NAME := &"bread"

# What starving is worth — the weight in weight × gap^bite. This is the
# number that decides whether a meal can EVER interrupt work: work peaks at
# 103 (see work_the_field.gd's header), so unless this clears 103 a starving
# man could never outbid a day's labour, no matter how hungry he got. 130 is
# illustrative — the author's tuning board, not a specification.
@export var starving_worth := 130.0

# How sharply it bites — the exponent. This is what makes A BIT hungry mean
# keep working: a low bite lets a small gap score close to its ceiling and he
# nibbles all day, while a higher one keeps the score small until the gap has
# opened most of the way, so he stays at the plough until hunger is genuinely
# large. Higher bite reads as MORE STOIC, never as more prompt — it changes
# how far the gap has to open before he acts, not how often it opens. 3 is
# illustrative, same as starving_worth.
@export var bite := 3.0


# Awake and holding bread. NEVER hunger — "not hungry enough" is want, not
# possibility, and a gate that reads want is barring in a new coat, the same
# mistake stay_up.gd's header already warns about in its own case.
func is_available_to(person: Person) -> bool:
	# REQUIRED, not a candidate question. Without it a man whose hunger
	# crosses at 03:00 gets up and eats in the dark, and on a graph that
	# presents as a broken sleep cycle rather than as a missing gate — the
	# same reason StayUp and WorkTheField both gate on this.
	if not person.brain.is_awake():
		return false
	# A CANDIDATE question: does he have anything that could serve this want.
	# An empty sack takes Eat off the ballot entirely rather than leaving it
	# scored and losing — see probe claim 33.
	if person.get_inventory() == null:
		return false
	return person.get_inventory().has_at_least(BREAD_NAME, 1)


# NON-LINEAR, AND THAT IS ARITHMETIC, NOT OPINION. A straight line —
# starving_worth × hunger/100 — gives exactly the wrong day:
#
#   It can never reach work's 103 at any hunger, because a 100-ceiling stat
#   scored linearly tops out at starving_worth itself. So a meal could never
#   interrupt work, at any hunger, no matter how the weight was tuned.
#
#   And half-empty at 22:00 already scores half of starving_worth, which at
#   any illustrative weight above 100 already beats StayUp's 50.0 — so a
#   linear score has him nibbling bread every evening and never once eating
#   during the working day.
#
# Raising the gap to a power fixes both at once: a small gap stays small (half
# hunger scores far below half of starving_worth), and a large gap closes in
# on the full weight fast enough to clear work's peak. See
# proving-scene-decisions.md Decision 20 for the general shape this reads as
# want = weight × gap^bite.
func get_utility_score(person: Person) -> float:
	var hungry: float = person.stats.get_stat(&"hunger")
	return starving_worth * pow(hungry / 100.0, bite)
