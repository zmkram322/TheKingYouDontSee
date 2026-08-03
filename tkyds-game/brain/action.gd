class_name Action
extends RefCounted

# One thing a subject could choose to do: gated by `eligible`, ranked by
# `score`. Both are supplied by whoever builds the action — this class only
# carries the shape, never the judgment itself.

var label: String
var eligible: Callable   # (subject) -> bool
var score: Callable      # (subject) -> float


func _init(new_label: String, new_eligible: Callable, new_score: Callable) -> void:
	label = new_label
	eligible = new_eligible
	score = new_score
