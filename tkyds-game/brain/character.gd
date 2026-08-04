class_name Character
extends RefCounted

# Someone the world can hold: a name, the facts about them actions read, the
# actions they know how to do, and a brain to pick between those actions.
#
# The split is worth stating plainly. What a character knows how to do is part
# of who they are, so the catalog lives here and is edited here. Which of
# those they'd pick right now is a judgment, so that lives in the brain. The
# character hands its actions over when it asks — the brain never reaches in
# for them, which is what keeps the brain usable by any subject at all.

var character_name: String
var stats := {}                    # the readable facts actions gate and score on
var actions: Array[Action] = []    # what this character knows how to do
var brain: DecisionBrain


# Known actions are copied, not adopted: characters are commonly seeded from
# one shared starting list, and teaching this character something new must not
# quietly teach it to everyone else. The Action objects themselves stay shared
# — it's only the list that's private.
func _init(new_name: String, new_stats: Dictionary, known_actions: Array[Action] = []) -> void:
	character_name = new_name
	stats = new_stats
	actions = known_actions.duplicate()
	brain = DecisionBrain.new(self)


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

# Re-decide and commit: the best of everything open to them right now, whether
# that's something they know how to do or something they owe. Poke this
# whenever the world changes in a way that might change their mind.
func decide_action() -> Action:
	return brain.reconsider(actions)


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
	if brain.active_action == null:
		decide_action()
		if brain.active_action == null:
			return   # nothing open to them at all

	var body := brain.active_action.body

	# There's no way to get on with it — every inn shut, no grain to be had.
	# Stop pursuing it without settling it: an obligation stays owed, and a
	# need stays unmet. Nothing is re-decided this slice, because the world
	# hasn't changed since the decision that landed here; the next poke will
	# find something else, or the same thing once it becomes possible again.
	if not body.is_possible(self):
		brain.abandon_active_action()
		return

	if body.advance(self, delta):
		brain.finish_active_action()
		decide_action()


# What they'd be seen doing right now.
func doing_label() -> String:
	var doing := brain.active_action
	if doing == null:
		return "deciding…"
	return doing.body.describe(self)
