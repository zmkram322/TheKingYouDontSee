class_name Brain
extends Node

# What one person knows how to do, and which of it wins right now.
#
# His repertoire is this node's children — every Action under here is something
# he knows. That's the whole of teaching him something: drop the action scene
# in. It is NOT how you gate what he can do this second; that's each action's
# own can_do, asked every tick. Nodes move when someone learns or forgets,
# never when someone falls asleep.
#
# The picking itself lives in Judgment, which holds nothing about anybody and
# could be swapped without touching this file.

var person: Person
var judgment := Judgment.new()

# What he's doing right now. Kept ONLY so you can see it over his head — never
# fed back into the decision. Every tick re-picks from scratch over current
# facts, so this is a readout, not a memory.
var doing: Action

var _known: Array[Action] = []


func _ready() -> void:
	person = get_parent() as Person
	if person == null:
		push_warning("a Brain's parent must be a Person — it has nobody to think for")
	relearn()


# Re-read his repertoire off the children. Once at startup, and again after
# teaching him something. Cached rather than rebuilt every tick because what he
# KNOWS changes rarely, even though what he can do right now changes constantly.
func relearn() -> void:
	_known.clear()
	for child in get_children():
		if child is Action:
			_known.append(child)


# One slice of thinking and doing.
#
# Deliberately re-decides every tick instead of committing to something. With
# nothing stored, an interruption costs nothing — the next tick simply picks
# again from wherever he now is. Whether that flickers is a real question, and
# the answer is meant to be the two thresholds on the actions themselves (see
# game/actions/): sleep starts winning high and stops winning low, so there's a
# gap between "start" and "stop" rather than one line to sit on and jitter.
#
# An action that says it can't be got on with is dropped for this tick rather
# than forced. Nothing else is tried, because the world hasn't changed since
# the decision that landed here; next tick will find something or find the same
# thing once it's possible again.
func tick(delta: float) -> void:
	if person == null:
		return
	doing = judgment.choose(person, _known)
	if doing == null or doing.body == null:
		return
	if not doing.body.is_possible(person):
		return
	doing.body.work_on(person, delta)


# What he'd be seen doing, both halves. The Action says why — "sleep" — and the
# Step says what — "clearing the day off". Reporting only one of them throws
# away the half a reader actually needs.
func doing_label() -> String:
	if doing == null:
		return "…"
	var why: String = doing.label if not doing.label.is_empty() else String(doing.name)
	var what: String = doing.body.describe(person) if doing.body != null else ""
	return why if what.is_empty() else "%s — %s" % [why, what]
