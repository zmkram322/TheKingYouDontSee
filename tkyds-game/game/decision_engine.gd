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


# What the last full pass made of each action, keyed by node name: its score,
# or NAN if it wasn't on the ballot at all.
#
# Purely a readout — the graph draws it and nothing else touches it. Keeping it
# doesn't break the rule about storing nothing you can work out again, because
# nothing reads it back: it's a record of a pass that already happened, not a
# memory that changes the next one. Delete it and every decision comes out
# identical.
#
# Both halves write into it, which is also why it's only trustworthy after a
# full pass — that's where it gets cleared. A pass is started by
# open_the_ballot, below, whichever kind of brain calls it.
var _last_scores := {}


func get_last_scores() -> Dictionary:
	return _last_scores


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
		else:
			# Recorded as "wasn't on the ballot" rather than scored, because
			# scoring something that was gated shut would be work nobody asked
			# for and an answer nobody used. The graph draws it as a gap.
			_last_scores[action.name] = NAN
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
		_last_scores[action.name] = score
		if not is_finite(score):
			push_warning("\"%s\" scored %f — a stat is missing or the sum is broken" % [action.label, score])
			continue
		if winner == null or score > winning_score:
			winning_score = score
			winner = action
	return winner


# Starts a pass and hands back the open list — the half a player's hand picks
# from, and the half a Brain's own automatic pick starts from too. The clear
# lives here, in the one spot every kind of brain is guaranteed to call, so
# that whichever of them starts a pass, the readout the LAST one left behind
# is gone before this one writes a single score into it.
#
# THERE IS DELIBERATELY NO ONE-CALL SHORTCUT THAT DOES BOTH HALVES. There was
# — choose(), which opened the ballot and returned get_highest_scoring in one
# line — and it was deleted when Brain grew pick_from_the_ballot, because it
# had no caller left and because a shortcut here is a trap rather than a
# convenience: a brain that called it would get the score-driven winner with
# the fork silently skipped, and nothing would say so. Same reasoning as
# Inventory having exactly one transfer path — a second way to do the whole
# thing is a second place for the wrong half to happen.
#
# So: open the ballot here, pick the winner in the Brain. Two calls, one
# clear, and no way to accidentally do the automatic thing for a body
# somebody is steering.
func open_the_ballot(person: Person, actions: Array[Action]) -> Array[Action]:
	_last_scores.clear()
	return get_available(person, actions)
