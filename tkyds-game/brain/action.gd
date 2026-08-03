class_name Action
extends RefCounted

# One thing a subject could choose to do: gated by `eligible`, ranked by
# `score`, carried out by `body`. Those first two are supplied by whoever
# builds the action — this class only carries the shape, never the judgment.
#
# An Action is choosable; a Step is doable. Keeping them separate types is
# what lets them alternate: a Step can be a Choice that ranks further Actions,
# each with a body of its own, nesting as deep as the work does.

var label: String
var eligible: Callable   # (subject) -> bool
var score: Callable      # (subject) -> float
var body: Step           # how it's actually carried out; null if it isn't yet


func _init(new_label: String, new_eligible: Callable, new_score: Callable, new_body: Step = null) -> void:
	label = new_label
	eligible = new_eligible
	score = new_score
	body = new_body
