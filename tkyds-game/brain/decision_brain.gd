class_name DecisionBrain
extends RefCounted

# How a subject decides: which of the actions it's handed are open to them,
# what each is worth, and which one wins. It holds nothing — every method takes
# the subject it is deciding for. That is what makes it shareable in exactly
# the way a Step is: it's a description of how to judge, not a record of anyone
# having judged.
#
# It deliberately does NOT hold the subject. An earlier version did, which made
# a brain and its character point at each other, and two RefCounted objects
# pointing at each other never reach zero — every headless run leaked them. The
# fix isn't a weak reference, which would put a dereference on the hot path to
# patch a construction-time mistake; it's noticing that this class was two
# things wearing one name. What a subject owes and what they're pursuing are
# facts about that subject, and now live on them. What's left here is judgment,
# which belongs to nobody.
#
# The subject is opaque here: this class never reads a field off it, it only
# hands it to an action's own gate and curve. Actions are allowed to know what
# a subject is — they're world-specific content. This file isn't.
#
# Availability and ranking are kept apart on purpose: determine_available_actions
# never scores, highest_scoring never gates. choose_action is just the two of
# them composed, so either half can be used — or tested — on its own.


# --- Availability -----------------------------------------------------------

# Is this action open to the subject right now? An action rules itself out
# through its own gate, never through a special case in here.
#
# The one exception is the protected set — the handful of survival and direct
# interpersonal actions everyone may always attempt. Their gates are not
# consulted at all, which is what makes the guarantee structural: it cannot be
# undone by authoring, only outbid by weight. Note this protects the category,
# never the instance: a starving man must always be able to attempt to eat, but
# he is not owed a scoring pass over every inn in the region.
func is_available(who, action: Action) -> bool:
	if action.protected:
		return true
	return action.eligible.call(who)


# The subset of a list that's open to the subject right now. Worked out fresh
# each time it's asked rather than stored, because availability moves with the
# subject: coin earned, fear risen, somewhere new stood — any of those can
# change the answer between one moment and the next.
func determine_available_actions(who, from: Array[Action]) -> Array[Action]:
	var open: Array[Action] = []
	for action in from:
		if is_available(who, action):
			open.append(action)
	return open


# --- Ranking ----------------------------------------------------------------

# What is this action worth to the subject right now? The whole of "how much
# do I want this" lives in the action's own curve; this just asks it.
func score(who, action: Action) -> float:
	return action.score.call(who)


# The highest-scoring action in a list, or null if the list is empty. Ranks
# whatever it's handed and asks no questions about availability — filtering
# happened before this, or not at all. Deterministic: ties go to the earlier
# action, so the same subject in the same state always lands the same winner.
#
# A score that isn't a real number is refused rather than ranked. Two ways that
# happens and both are bugs worth being loud about: a curve reading a stat that
# was never set produces NaN, and every comparison against NaN is false, so the
# action loses silently forever and the subject stands there with nothing said.
# Minus infinity is the same story from the other end — it's the idiomatic
# "never do this", and it should lose to a real score rather than sneak past
# the opening -INF and win an otherwise empty list.
func highest_scoring(who, from: Array[Action]) -> Action:
	var best: Action = null
	var best_score := -INF
	for action in from:
		var value := score(who, action)
		if not is_finite(value):
			push_warning("%s scored %f — a stat is missing or a curve is broken" % [action.label, value])
			continue
		if best == null or value > best_score:
			best_score = value
			best = action
	return best


# The best of what's open to the subject, out of the actions handed in.
func choose_action(who, from: Array[Action]) -> Action:
	return highest_scoring(who, determine_available_actions(who, from))
