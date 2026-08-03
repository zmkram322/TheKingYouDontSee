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
#
# The brain also keeps the queue of assigned work (see the bottom of this
# file). It holds what you intend and what you owe; it never advances time or
# touches the world.

var subject   # who this brain decides for

# Obligations handed in from outside — an order taken, an errand given. Only
# things scoring can't regenerate belong here: a self-directed choice is never
# queued, because re-deciding brings it back on its own. Deliberately a plain
# array so it can be reordered, cancelled, or inserted into later (a lord
# re-prioritising someone's work) without fighting a wrapper.
var queue: Array[Action] = []

# What the subject is pursuing right now. May be one of their own capabilities
# or one of the obligations in the queue — a queued action being active does
# NOT remove it from the queue, because owing something and working on it are
# separate facts. It leaves the queue when it's discharged, not when it starts.
var active_action: Action = null


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


# --- Deciding what to pursue ------------------------------------------------

# Everything that could win right now: what the subject knows how to do, plus
# what they owe. An obligation isn't worked off by some separate mechanism —
# it competes directly, on its own merits, against every ordinary need. That's
# what lets exhaustion outbid a lord's order without anything granting sleep
# special status, and lets the order still be owed afterwards.
func candidate_actions(known: Array[Action]) -> Array[Action]:
	var candidates: Array[Action] = known.duplicate()
	candidates.append_array(queue)
	return candidates


# Re-decide from scratch and keep the winner. This is the one entry point
# anything outside pokes — a fright, someone walking past, the runner finishing
# a step. Re-deciding is always safe: it's a fresh pass over current facts, so
# a winner that's still winning simply stays.
func reconsider(known: Array[Action]) -> Action:
	active_action = choose_action(candidate_actions(known))
	return active_action


# --- Assigned work ----------------------------------------------------------

# Being queued is not a way to jump the scoring — it's only a way to be
# remembered. The queue holds what the subject owes; whether they're working on
# it right now is a separate fact, held by active_action. An obligation stays
# queued while it's being worked on, so an interruption costs nothing: it's
# still owed, and re-deciding picks it up again on its own.

# Take on an obligation, behind whatever's already waiting.
func assign_action(action: Action) -> void:
	queue.append(action)


# The obligation that's been waiting longest, or null if there are none. Note
# this is not "the one they'll do next" — that's whatever scores highest, which
# may well be a fresher obligation that's grown more urgent.
func next_assigned_action() -> Action:
	return queue[0] if not queue.is_empty() else null


func assigned_count() -> int:
	return queue.size()


# Done with it, or called off — either way it stops being owed. Named for what
# the queue knows, which is only that it's no longer waiting; whether it was
# actually carried out is the runner's business, not the brain's.
func clear_assigned_action(action: Action) -> void:
	queue.erase(action)
	if active_action == action:
		active_action = null
