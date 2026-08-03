class_name Wait
extends State

# The generic "let real time pass" leaf — a duration with no destination and
# no effect. Same shape as WalkTo/Perform: nothing outside this file knows
# it's just a countdown.

var _seconds: float
var _elapsed := 0.0


func _init(seconds: float) -> void:
	_seconds = seconds


func advance(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _seconds:
		finished = true


func describe() -> String:
	return "…"
