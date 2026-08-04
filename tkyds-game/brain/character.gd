class_name Character
extends RefCounted

# Someone the world can hold: a name, the facts about them actions read, the
# actions they know how to do, what they owe, what they're pursuing, and a
# brain to pick between it all.
#
# The split is worth stating plainly. What a character knows how to do, what
# they owe, and what they're getting on with are all facts about this person,
# so they live here. Which of them wins right now is a judgment, so that lives
# in the brain — which holds nothing and could be shared by everyone in the
# world, the same way a Step is.

var character_name: String
var stats := {}                    # the readable facts actions gate and score on
var actions: Array[Action] = []    # what this character knows how to do
var brain: DecisionBrain

# Obligations handed in from outside — an order taken, an errand given. Only
# things scoring can't regenerate belong here: a self-directed choice is never
# queued, because re-deciding brings it back on its own. Deliberately a plain
# array so it can be reordered, cancelled, or inserted into later (a lord
# re-prioritising someone's work) without fighting a wrapper.
var queue: Array[Action] = []

# What they're pursuing right now. May be one of their own capabilities or one
# of the obligations in the queue — a queued action being active does NOT
# remove it from the queue, because owing something and working on it are
# separate facts. It leaves the queue when it's discharged, not when it starts.
var active_action: Action = null


# Known actions are copied, not adopted: characters are commonly seeded from
# one shared starting list, and teaching this character something new must not
# quietly teach it to everyone else. The Action objects themselves stay shared
# — it's only the list that's private.
func _init(new_name: String, new_stats: Dictionary, known_actions: Array[Action] = []) -> void:
	character_name = new_name
	stats = new_stats
	actions = known_actions.duplicate()
	brain = DecisionBrain.new()


# --- The facts about them ---------------------------------------------------

# Every read and write of a character's state goes through these two, and the
# Dictionary behind them is an implementation detail nobody outside should
# reach past them to touch.
#
# It is a Dictionary today because that is the simplest thing that works, and
# the loop has not yet earned anything more. What it will eventually need is
# derived values — "how hungry does she look to someone watching" — computed on
# read and never served stale. That is a change to these two methods and to
# nothing else, but only while everything goes through them. Every gate and
# curve in the world is about to be written against this, and each one that
# reaches into the Dictionary directly is one more call site a later swap has
# to find.
#
# `fallback` is the seam's other half: an unset stat reads as its default
# rather than as an error, so only what actually differs has to be stored.
func stat(what: StringName, fallback = 0.0) -> Variant:
	return stats.get(what, fallback)


func set_stat(what: StringName, value) -> void:
	stats[what] = value


# --- What they know how to do -----------------------------------------------

func has_action(action: Action) -> bool:
	return actions.has(action)


# Adding what they already know is a no-op rather than a second copy — a
# duplicate would be scored twice and could win against itself.
func add_action(action: Action) -> void:
	if not has_action(action):
		actions.append(action)


# Dropping something they never knew is fine and does nothing.
func drop_action(action: Action) -> void:
	actions.erase(action)


# --- Deciding ---------------------------------------------------------------

# Everything that could win right now: what they know how to do, plus what they
# owe. An obligation isn't worked off by some separate mechanism — it competes
# directly, on its own merits, against every ordinary need. That's what lets
# exhaustion outbid a lord's order without anything granting sleep special
# status, and lets the order still be owed afterwards.
func candidate_actions() -> Array[Action]:
	var candidates: Array[Action] = actions.duplicate()
	candidates.append_array(queue)
	return candidates


# Re-decide from scratch and commit to the winner: the best of everything open
# to them, whether that's something they know how to do or something they owe.
# Poke this whenever the world changes in a way that might change their mind —
# a fright, someone walking past, the work finishing. Re-deciding is always
# safe: it's a fresh pass over current facts, so a winner that's still winning
# simply stays.
func decide_action() -> Action:
	active_action = brain.choose_action(self, candidate_actions())
	return active_action


# --- What they owe ----------------------------------------------------------

# Being queued is not a way to jump the scoring — it's only a way to be
# remembered. The queue holds what they owe; whether they're working on it
# right now is a separate fact, held by active_action. An obligation stays
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


# Is this work already owed? Asked by whoever is about to hand work over, so
# they don't hand it over twice. This is the reason an Obligation says what
# it's about: without it the only way to answer would be to remember having
# asked, and a remembered intention is the one thing the design refuses to
# keep. Looking at what someone currently owes is reading the world, not
# remembering.
func owes_anything_about(about: StringName) -> bool:
	return find_obligation_about(about) != null


func find_obligation_about(about: StringName) -> Obligation:
	for action in queue:
		if action is Obligation and action.about == about:
			return action
	return null


# Called off from outside — a lord changing his mind, an order withdrawn. It
# stops being owed whether or not it was ever carried out; the queue only ever
# knew that it was waiting.
func clear_assigned_action(action: Action) -> void:
	queue.erase(action)
	if active_action == action:
		active_action = null


# The active action is done. Discharges it if it was owed — finishing a lord's
# errand should settle the debt — and stops pursuing it either way, leaving
# them free to decide afresh.
func finish_active_action() -> void:
	if active_action == null:
		return
	queue.erase(active_action)
	active_action = null


# The active action can't be got on with — every inn shut, no grain to be had.
# Deliberately NOT the same as finishing: the work was never done, so an
# obligation stays owed and only stops being pursued. Collapsing the two would
# let a debt nobody could serve quietly pay itself off.
func abandon_active_action() -> void:
	active_action = null


# --- Doing ------------------------------------------------------------------

# One slice of living: get on with whatever's being pursued, and when it's
# done, settle it and decide afresh.
#
# Deliberately does NOT re-decide every slice. A decision is re-made when
# something happens — a fright, a passer-by, the work finishing — not sixty
# times a second, which would be both wasteful and twitchy. Everything else
# pokes decide_action() when it has a reason to.
#
# The work is asked about exactly once per slice. Asking twice — once before
# advancing and once after — re-runs the whole tree over world state the
# advance has just changed, so the answer can come back from a different option
# than the one that did the work.
func act(delta: float) -> void:
	if active_action == null:
		decide_action()
		if active_action == null:
			return   # nothing open to them at all

	var body := active_action.body

	# There's no way to get on with it — every inn shut, no grain to be had.
	# Stop pursuing it without settling it: an obligation stays owed, and a
	# need stays unmet. Nothing is re-decided this slice, because the world
	# hasn't changed since the decision that landed here; the next poke will
	# find something else, or the same thing once it becomes possible again.
	if not body.is_possible(self):
		abandon_active_action()
		return

	if body.advance(self, delta):
		finish_active_action()
		decide_action()


# What they'd be seen doing right now. Both halves are wanted: the action says
# WHY — "flee to the woods" — and the body says WHAT, "walking to (0, -220)".
# Reporting only the body throws the reason away and leaves a coordinate pair,
# which is the one thing a reader can't do anything with. Same shape a nested
# Choice already uses, so a decision at any depth reads as one sentence.
func doing_label() -> String:
	if active_action == null:
		return "deciding…"
	var inner := active_action.body.describe(self)
	return active_action.label if inner.is_empty() else "%s — %s" % [active_action.label, inner]
