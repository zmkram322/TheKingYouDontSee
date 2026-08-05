class_name Judgment
extends RefCounted

# How to pick. Holds nothing about anybody — hand it a person and a list of
# things they could do, and it says which one wins.
#
# It's an object rather than a set of plain functions so a Brain can one day be
# handed a differently-tempered one — someone rash, someone cautious — without
# a single call site changing. Today everybody gets the same one.
#
# Two halves kept strictly apart: allowed() never scores, best() never gates.
# Worth the extra method because the two go wrong in different ways, and when
# he picks something daft you want to be able to look at them separately.


# The ones open to him right now. Worked out fresh every time rather than kept,
# because it moves with him — falling asleep changes the answer.
#
# An always_allowed action skips can_do entirely. That's what makes the
# guarantee real: it can't be undone by whoever writes the action, only outbid
# by something he wants more.
func allowed(who: Person, from: Array[Action]) -> Array[Action]:
	var open: Array[Action] = []
	for action in from:
		if action.always_allowed or action.can_do(who):
			open.append(action)
	return open


# The one he wants most, or null if the list is empty. Ties go to whichever
# came first, so the same person in the same state always picks the same thing.
#
# A score that isn't a real number is thrown out loudly rather than ranked.
# Both ways that happens are bugs worth hearing about: reading a stat that was
# never set gives NaN, and every comparison against NaN is false — so the
# action would lose silently forever and he'd just stand there with nothing
# said. Negative infinity is the same story from the other end.
func best(who: Person, from: Array[Action]) -> Action:
	var winner: Action = null
	var winning_score := -INF
	for action in from:
		var score := action.wants(who)
		if not is_finite(score):
			push_warning("\"%s\" scored %f — a stat is missing or the sum is broken" % [action.label, score])
			continue
		if winner == null or score > winning_score:
			winning_score = score
			winner = action
	return winner


func choose(who: Person, from: Array[Action]) -> Action:
	return best(who, allowed(who, from))
