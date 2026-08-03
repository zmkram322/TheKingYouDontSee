class_name DecisionBrain
extends RefCounted

# How one subject decides: which of the actions it's handed are open to them,
# what each is worth, and which one wins. Belongs to a single subject — it
# holds that subject, so nothing has to keep passing it in — but it owns no
# catalog of its own: what a character knows how to do belongs to the
# character, and gets handed in when they ask.
#
# The subject is deliberately opaque here: this class never reads a field off
# it, it only hands it to an action's own gate and curve. Actions are allowed
# to know what a subject is — they're world-specific content. This file isn't.
#
# Availability and ranking are kept apart on purpose: determine_available_actions
# never scores, highest_scoring never gates. choose_action is just the two of
# them composed, so either half can be used — or tested — on its own.

var subject   # who this brain decides for


func _init(new_subject) -> void:
	subject = new_subject


# --- Availability -----------------------------------------------------------

# Is this action open to the subject right now? An action rules itself out
# through its own gate, never through a special case in here.
func is_available(action: Action) -> bool:
	return action.eligible.call(subject)


# The subset of a list that's open to the subject right now. Worked out fresh
# each time it's asked rather than stored, because availability moves with the
# subject: coin earned, fear risen, somewhere new stood — any of those can
# change the answer between one moment and the next.
func determine_available_actions(from: Array[Action]) -> Array[Action]:
	var open: Array[Action] = []
	for action in from:
		if is_available(action):
			open.append(action)
	return open


# --- Ranking ----------------------------------------------------------------

# What is this action worth to the subject right now? The whole of "how much
# do I want this" lives in the action's own curve; this just asks it.
func score(action: Action) -> float:
	return action.score.call(subject)


# The highest-scoring action in a list, or null if the list is empty. Ranks
# whatever it's handed and asks no questions about availability — filtering
# happened before this, or not at all. Deterministic: ties go to the earlier
# action, so the same subject in the same state always lands the same winner.
func highest_scoring(from: Array[Action]) -> Action:
	var best: Action = null
	var best_score := -INF
	for action in from:
		var value := score(action)
		if value > best_score:
			best_score = value
			best = action
	return best


# The best of what's open to the subject, out of the actions handed in.
func choose_action(from: Array[Action]) -> Action:
	return highest_scoring(determine_available_actions(from))
