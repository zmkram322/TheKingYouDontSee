class_name Action
extends Node

# One thing a person could choose to do. An Action is the WHY — "sleep", "work
# the field" — and it is choosable: gated by is_available_to, ranked by
# get_utility_score.
#
# What it doesn't do is the work. That belongs to the ActionStep underneath it
# (its only ActionStep child), and keeping the two apart is what lets them
# alternate: a step can itself hold further Actions and rank between them, so a
# decision can sit at any depth. "Go eat" is an Action; what it *does* can be
# "walk there, then eat", and "walk there" can be another decision about which
# inn.
#
# An Action with no step is a room you can walk into and never leave — it wins
# the pass, gets pursued, and never does anything. That's an authoring mistake
# and it says so out loud rather than failing quietly.

# What this reads as when you're watching him.
@export var label := ""

# Note what is NOT here: a flag marking an action as always available. There was
# one, and it was ceremony — its only real effect was to ignore a gate someone
# wrote later, which means an author writes a gate and it silently does nothing.
# That's a worse trap than the one it guarded against.
#
# The guarantee it was reaching for — nobody can be made unable to eat or run
# away — lives in composition instead: eat and flee are in every person scene,
# so they're in everyone's repertoire and can only be outbid, never pruned.
# Whether flee is doable *this second* (he's tied up) is what a gate is for, and
# it should work normally.

# Does doing this mean he's asleep? True on Sleep and nothing else.
#
# This is how the brain knows whether he's awake — it looks at what he's doing
# rather than at a stored flag, so the two can never disagree. It also means
# nothing has to remember to wake him: the first tick anything else wins — a
# fire, a fright, a shout — he's awake, because he's no longer doing the thing
# that made him asleep.
#
# A flag rather than "is this the Sleep action?" because there will be more
# than one way to be out: a nap, a faint, drugged, knocked cold. They all want
# the same answer and none of them are Sleep.
@export var counts_as_asleep := false

# The step that actually does it. Found once from the children rather than
# dragged in, because an action's step is structurally its child — there is
# nowhere else it could be.
var step: ActionStep


func _ready() -> void:
	for child in get_children():
		if child is ActionStep:
			step = child
			return
	push_warning("\"%s\" has no ActionStep under it — he could choose it and then do nothing" % name)


# Is this open to him right now? Default yes — only an action that can
# genuinely be shut off says otherwise.
func is_available_to(_person: Person) -> bool:
	return true


# How much he wants it, on the one scale everything is scored against. Highest
# wins. Default zero: an action that never says what it's worth should lose to
# anything that does.
func get_utility_score(_person: Person) -> float:
	return 0.0
