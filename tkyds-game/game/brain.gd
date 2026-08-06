class_name Brain
extends Node

# What one person knows how to do, which of it wins right now, and the body
# bookkeeping that happens to him whether he decides it or not.
#
# His repertoire is this node's children — every Action under here is something
# he knows. That's the whole of teaching him something: drop the action scene
# in. It is NOT how you gate what he can do this second; that's each action's
# own is_available_to, asked every tick. Nodes move when someone learns or
# forgets, never when someone falls asleep.
#
# The picking itself lives in DecisionEngine, which holds nothing about anybody
# and could be swapped without touching this file.

var person: Person
var decision_engine := DecisionEngine.new()

# What he's doing right now. Kept ONLY so you can see it over his head and so
# is_awake can read it — never fed back into the ranking. Every tick re-picks
# from scratch over current facts, so this is a readout, not a memory.
var current_action: Action

var _known_actions: Array[Action] = []


func _ready() -> void:
	person = get_parent() as Person
	if person == null:
		push_warning("a Brain's parent must be a Person — it has nobody to think for")
	reload_known_actions()


# --- What he knows ---------------------------------------------------------------

# Learning and forgetting are first-class, not housekeeping. Growing reach
# unlocking new actions is the shape of progression, and what someone can do at
# all is most of what makes them a different person from the man beside them.
# It just doesn't happen every tick — which is why the list is cached here and
# re-read on the rare occasion it changes, rather than rebuilt sixty times a
# second.
#
# What this is NOT is how you gate what he can do right now. That's each
# action's own is_available_to, asked every tick. Nodes move when he learns or
# forgets, never when he falls asleep.

# Teach him something. Takes the action's scene from the library, so he gets his
# own copy and tuning one man's sleep doesn't change everybody's.
func learn(action_scene: PackedScene) -> Action:
	var action := action_scene.instantiate() as Action
	if action == null:
		push_warning("that scene isn't an Action — nothing learned")
		return null
	add_child(action)
	reload_known_actions()
	return action


# Take something away — a trade lost, a limb lost, a rank stripped. If it's what
# he's doing right now, he stops doing it; next tick he picks again from
# whatever's left.
func forget(action: Action) -> void:
	if action == null or action.get_parent() != self:
		return
	if current_action == action:
		current_action = null
	remove_child(action)
	action.queue_free()
	reload_known_actions()


# Re-read his repertoire off the children. Once at startup, and again whenever
# he learns or forgets.
func reload_known_actions() -> void:
	_known_actions.clear()
	for child in get_children():
		if child is Action:
			_known_actions.append(child)


# Is he awake? Read off what he's doing rather than kept as a stat, so the two
# can never disagree — there is no flag to forget to clear.
#
# Doing nothing counts as awake. On the very first tick he hasn't decided
# anything yet, and "hasn't decided" must not read as "unconscious".
func is_awake() -> bool:
	return current_action == null or not current_action.counts_as_asleep


# One slice of thinking and doing. Three things, in this order, and the order
# matters:
#
#   1. Decide. Gates read what he WAS doing — that's what lets Wake be on the
#      ballot only while he's already asleep, which is half the reason the sleep
#      cycle doesn't twitch.
#   2. Update the body, using what he's NOW doing, so the tick he decides to
#      turn in is the tick adenosine starts falling.
#   3. Do the work.
#
# Deliberately re-decides every tick instead of committing. With nothing
# stored, an interruption costs nothing — the next tick picks again from
# wherever he now is. It doesn't flicker because of the two thresholds on the
# actions themselves (see game/actions/): sleep starts winning high and stops
# winning low, so there's a wide gap between "start" and "stop" rather than one
# line to sit on and jitter across.
func think_and_act(delta: float) -> void:
	if person == null:
		return
	current_action = decision_engine.choose(person, _known_actions)
	_update_body(delta)
	if current_action == null or current_action.step == null:
		return
	if not current_action.step.is_doable(person):
		return
	current_action.step.advance(person, delta)


# --- The body ------------------------------------------------------------------

# What happens to him whether he decides it or not.
#
# This lives here rather than inside the actions on purpose. Adenosine is the
# waste left over from the brain spending energy — it piles up for as long as
# he's up, no matter WHAT he's up doing. Put it inside "stay up" and the day
# you add "work the field" you get a farmhand who never gets tired, and you
# find out three atoms later. Nothing an action does should be required for
# this to be true.
#
# Every drift that arrives later — hunger, fear fading, a wound — is one more
# line here, and every action ever written inherits all of them for free.
@export_group("Body")
@export var adenosine_per_second := 1.0              # while awake
@export var adenosine_cleared_per_second := 2.5      # while asleep
@export var adenosine_ceiling := 100.0

func _update_body(delta: float) -> void:
	var tired: float = person.stats.get_stat(&"adenosine")
	if is_awake():
		tired += adenosine_per_second * delta
	else:
		tired -= adenosine_cleared_per_second * delta
	person.stats.set_stat(&"adenosine", clampf(tired, 0.0, adenosine_ceiling))


# What he'd be seen doing, both halves. The Action says why — "sleep" — and the
# step says what — "out cold". Reporting only one of them throws away the half
# a reader actually needs.
func describe_current_action() -> String:
	if current_action == null:
		return "…"
	var why: String = current_action.label if not current_action.label.is_empty() else String(current_action.name)
	var what: String = current_action.step.describe(person) if current_action.step != null else ""
	return why if what.is_empty() else "%s — %s" % [why, what]
