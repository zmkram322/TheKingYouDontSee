class_name Orchestrator
extends RefCounted

# Owns one actor's execution: the Goal stack (front = running now; the rest
# are paused — interrupted mid-flight, resume untouched — or queued —
# assigned from outside, not yet started) and the top-level decision of
# which Goal is active. Promote-not-rebuild and pause-not-discard are the
# trickiest invariants in the whole sandbox, so they live in one place with
# their own name instead of being smeared across call sites.
#
# Generic on purpose — nothing here names a specific option, State, or
# world. Turning a chosen ActionOption into an execution State, and writing
# a log line, both need world-specific knowledge this file must not have;
# they're supplied as Callables at construction, the same "behavior is data,
# not code" rule ActionOption's own appeal/eligible/effect already follow.

var stack: Array[Goal] = []
var last_decision: UtilityBrain.Decision = null

var _actor: Actor
var _stats: StatStore
var _options: Array[ActionOption]
var _build_goal: Callable   # (Actor, ActionOption) -> Goal
var _log: Callable          # (String) -> void


func _init(actor: Actor, stats: StatStore, options: Array[ActionOption], build_goal: Callable, log: Callable) -> void:
	_actor = actor
	_stats = stats
	_options = options
	_build_goal = build_goal
	_log = log


func current() -> Goal:
	return stack[0] if not stack.is_empty() else null


# Advances whatever's running, choosing something if nothing is, and
# retiring a goal the instant its root State reports finished. This is the
# whole per-frame contract — nothing outside this method decides when to
# reconsider.
func tick(delta: float) -> void:
	var goal := current()
	if goal == null:
		choose()
		goal = current()
	elif goal.is_complete():
		stack.pop_front()
		goal = current()
		if goal == null:
			choose()
			goal = current()
		elif not goal.started:
			goal.begin()
	goal.root.advance(delta)


# The self-directed decision point: score everything, and if the winner is
# already what's running, leave it alone — this is what makes routing a
# resumed goal back through choose() safe, it comes back out a no-op unless
# something genuinely outscored it. Otherwise the winner takes the front and
# whatever was there — if anything — waits its turn instead of being
# discarded. One rule covers both "stack was empty, fill it" and "something
# just interrupted."
func choose() -> void:
	last_decision = UtilityBrain.decide(_stats, _actor, _options)
	var option: ActionOption = last_decision.chosen
	assert(option != null, "no eligible option for %s" % _actor.person_name)

	var running := current()
	if running != null and running.option == option:
		return

	# The winner might already be sitting paused further back in the stack
	# (an earlier interrupt shelved it) rather than genuinely new — promote
	# that same Goal instead of building a duplicate, or a goal that was
	# mid-walk would silently restart from scratch every time it's re-picked.
	for i in range(1, stack.size()):
		if stack[i].option == option:
			var existing: Goal = stack[i]
			stack.remove_at(i)
			stack.push_front(existing)
			_log.call("%s returns to: %s" % [_actor.person_name, option.label])
			return

	var goal: Goal = _build_goal.call(_actor, option)
	goal.begin()
	stack.push_front(goal)

	var score := 0.0
	for entry in last_decision.considered:
		if entry.option == option:
			score = entry.score
			break
	var verb := "decides" if running == null else "interrupts itself"
	_log.call("%s %s: %s (score %.1f; best of %d)" % [_actor.person_name, verb, option.label, score, last_decision.considered.size()])


# The externally-assigned counterpart to choose(): not a competition this
# actor's own scoring runs, but an obligation handed to them (e.g. a
# provider asked to serve someone else's demand). Queues behind whatever
# they're already doing rather than preempting it.
func assign_goal(option: ActionOption) -> void:
	var goal: Goal = _build_goal.call(_actor, option)
	var was_empty := stack.is_empty()
	stack.push_back(goal)
	if was_empty:
		goal.begin()
	_log.call("%s is asked to: %s (%s)" % [_actor.person_name, option.label, "starting now" if was_empty else "queued behind current work"])
