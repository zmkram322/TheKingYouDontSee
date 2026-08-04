class_name Action
extends RefCounted

# One thing a subject could choose to do: gated by `eligible`, ranked by
# `score`, carried out by `body`. The first two are supplied by whoever builds
# the action — this class only carries the shape, never the judgment.
#
# An Action is choosable; a Step is doable. Keeping them separate types is
# what lets them alternate: a Step can be a Choice that ranks further Actions,
# each with a body of its own, nesting as deep as the work does.
#
# `body` is required. An action nobody can carry out has no business being
# choosable: it would win the pass, be pursued, and never finish or fail —
# a room the character can walk into and never leave. Work that takes time
# without changing the world is still a body; it is a Step that says it isn't
# satisfied yet.

var label: String
var eligible: Callable   # (subject) -> bool
var score: Callable      # (subject) -> float
var body: Step           # how it's actually carried out

# Marks one of the survival and direct interpersonal actions every subject may
# always attempt — eat, flee, confront, beg, steal, hold ground. A protected
# action's gate is never consulted, so no author can quietly make a person
# unable to run away.
#
# Deliberately an explicit mark rather than "no gate means universal": under
# that rule, forgetting to write a gate silently promotes an action into every
# subject's protected set, which fails in the more dangerous direction. Saying
# it out loud costs one word and cannot be done by accident.
var protected := false


func _init(new_label: String, new_eligible: Callable, new_score: Callable, new_body: Step) -> void:
	label = new_label
	eligible = new_eligible
	score = new_score
	body = new_body


# The same action, marked protected. A helper rather than a constructor
# argument because it reads at the call site as what it is, and because the
# protected set is a short fixed list — around ten actions in the whole world.
func always_available() -> Action:
	protected = true
	return self
