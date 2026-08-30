extends GoToStep

# Walking to a man instead of to a place.
#
# EXTENDS GoToStep RATHER THAN REIMPLEMENTING IT. That file calls itself "the
# only thing in the game that moves a body", and a second copy of the hand
# integration here would make that false — two places to get the tick scaling
# wrong, two places Decision 4's ban on move_and_slide has to be remembered.
# `walk_toward_point` was split out of `walk_toward` for exactly this: the
# movement with no opinion about why, and the place bookkeeping left behind in
# the caller that has a place.
#
# HE STOPS BESIDE THE MAN, NOT ON HIM, AND THAT IS NOT A RADIUS. The target is a
# point `closes_to` metres short of the summoner, and the inherited overshoot
# clamp lands him exactly on it. So there is no "within N metres" test doing the
# arriving — Decision 10's objection is to arrival BY THRESHOLD, which flickers
# at its own edge and lands differently at different tick rates. Asking for a
# point that is short of something keeps the clamp doing the work.
#
# THE ONE COMPARISON THAT IS A DISTANCE is the guard below, and it is there so a
# man ALREADY closer than `closes_to` does not walk backwards to reach a point
# behind him. That is a degenerate-geometry guard, not an arrival test.


# He is doing this because somebody called; the caller is on the Action above.
# Read fresh every tick rather than cached, so a summoner who is freed, or a
# beckon that was answered and cleared, stops this immediately.
func _get_summons() -> Node:
	return get_parent()


func is_done(person: Person) -> bool:
	var summons := _get_summons()
	if summons == null:
		return true
	var who: Person = summons.summoner
	if not is_instance_valid(who):
		return true
	var closes_to: float = summons.closes_to
	return _get_gap(person, who) <= closes_to


func advance(person: Person, hours: float) -> bool:
	var summons := _get_summons()
	if summons == null:
		return true
	var who: Person = summons.summoner
	if not is_instance_valid(who):
		return true

	# Pulled into typed locals rather than read inline. `summons` is annotated
	# Node — no script under workbench/ takes a class_name — so every property
	# read off it is a Variant, and CLAUDE.md's gotcha bites: an expression with a
	# Variant in it infers Variant and fails the build under warnings-as-errors.
	var closes_to: float = summons.closes_to
	var gap := _get_gap(person, who)
	if gap <= closes_to:
		return _arrive(summons)

	# The point he is actually walking to: short of the man, on the line between
	# them. Recomputed every tick, so a summoner who walks away is chased and one
	# who stands still is arrived at exactly once.
	var toward := who.global_position - person.global_position
	toward.y = 0.0
	var stop_at: Vector3 = who.global_position - toward / gap * closes_to
	stop_at.y = person.global_position.y

	# HIS PACE COMES OFF THE GAP, and it is the summons that decides how — this
	# step asks and does not work it out. So "he walks when you walk and runs when
	# you run" is not implemented anywhere: it falls out of him being further
	# behind a running man than a walking one. See come_along.get_pace.
	var pace: float = summons.get_pace(gap)
	if not walk_toward_point(person, stop_at, hours, pace):
		return false
	return _arrive(summons)


# ANSWERED. A beckon clears who called, which shuts its own gate — the summons
# is over because there is no longer anybody summoning. A follow keeps the name
# and simply stands there until the man moves again.
func _arrive(summons: Node) -> bool:
	var stays: bool = summons.stays_with_him
	if not stays:
		summons.summoner = null
	return true


# Flat distance. The y axis is dropped because one of them may be mid-jump — the
# workbench player has gravity (W7) — and a man should not read as far away
# because the person who called him is in the air.
func _get_gap(person: Person, who: Person) -> float:
	var toward := who.global_position - person.global_position
	toward.y = 0.0
	return toward.length()


func describe(person: Person) -> String:
	var summons := _get_summons()
	if summons == null or not is_instance_valid(summons.summoner):
		return ""
	if is_done(person):
		return "standing with %s" % summons.summoner.person_name
	return "on his way to %s" % summons.summoner.person_name
