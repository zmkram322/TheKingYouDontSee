class_name DecisionEngine
extends RefCounted

# How to pick. Holds nothing about anybody — hand it a person and a list of
# things they could do, and it says which one wins.
#
# It's an object rather than a set of plain functions so a Brain can one day be
# handed a differently-tempered one — someone rash, someone cautious — without
# a single call site changing. Today everybody gets the same one.
#
# Two halves kept strictly apart: get_available never scores,
# get_highest_scoring never gates. Worth the extra method because the two go
# wrong in different ways, and when he picks something daft you want to be able
# to look at them separately.


# The ones open to him right now. Worked out fresh every time rather than kept,
# because it moves with him — falling asleep changes the answer.
#
# Every gate is asked, with no exceptions and no override. The rule that nobody
# can be made unable to eat or run away is kept by those actions being in every
# person scene, not by a flag here that discards what an author wrote.
func get_available(person: Person, actions: Array[Action]) -> Array[Action]:
	var open: Array[Action] = []
	for action in actions:
		if action.is_available_to(person):
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
func get_highest_scoring(person: Person, actions: Array[Action]) -> Action:
	var winner: Action = null
	var winning_score := -INF
	for action in actions:
		var score := action.get_utility_score(person)
		if not is_finite(score):
			push_warning("\"%s\" scored %f — a stat is missing or the sum is broken" % [action.label, score])
			continue
		if winner == null or score > winning_score:
			winning_score = score
			winner = action
	return winner


func choose(person: Person, actions: Array[Action]) -> Action:
	return get_highest_scoring(person, get_available(person, actions))
