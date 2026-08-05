class_name Action
extends Node

# One thing a person could choose to do. An Action is the WHY — "sleep",
# "work the field" — and it is choosable: gated by can_do, ranked by wants.
#
# What it doesn't do is the work. That belongs to the Step underneath it (its
# only Step child), and keeping the two apart is what lets them alternate: a
# Step can itself hold further Actions and rank between them, so a decision
# can sit at any depth. "Go eat" is an Action; what it *does* can be "walk
# there, then eat", and "walk there" can be another decision about which inn.
#
# An Action with no Step is a room you can walk into and never leave — it wins
# the pass, gets pursued, and never does anything. That's an authoring mistake
# and it says so out loud in _ready rather than failing quietly.

# What this reads as when you're watching him.
@export var label := ""

# Marks one of the handful of things a person may always attempt — eat, flee,
# run. can_do is never asked of these, so no amount of gating elsewhere can
# make someone unable to run away. Being asleep gates the ordinary actions;
# this is what keeps "bolts awake when the house catches fire" free once
# there's a fire to bolt from.
#
# Deliberately a mark you have to write, rather than "an action with no gate
# is universal" — under that rule, forgetting to write a gate would silently
# promote something into everyone's protected set, which fails in the more
# dangerous direction.
@export var always_allowed := false

# The Step that actually does it. Found once from the children rather than
# dragged in, because an Action's body is structurally its child — there is
# nowhere else it could be.
var body: Step


func _ready() -> void:
	for child in get_children():
		if child is Step:
			body = child
			return
	push_warning("\"%s\" has no Step under it — he could choose it and then do nothing" % name)


# Is this open to him right now? Default yes — only an action that can
# genuinely be shut off says otherwise.
func can_do(_who: Person) -> bool:
	return true


# How much he wants it, on the one scale everything is scored against.
# Highest wins. Default zero: an action that never says what it's worth should
# lose to anything that does.
func wants(_who: Person) -> float:
	return 0.0
