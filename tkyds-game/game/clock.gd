class_name Clock
extends Node

# The one thing that moves time. Everything else in game/ reads it and draws;
# nothing else advances it.
#
# It holds exactly one fact — how many seconds this world has been running —
# and derives the rest on read. A stored "which day is it" counter could only
# ever agree with `seconds` or be a bug, so there isn't one. Same discipline
# the older world/ code used, just living on a Node now so you can watch it in
# the inspector while it runs.
#
# day_length_seconds is the slider: how long a day FEELS. Changing it mid-run
# is safe and does what you'd expect — the day gets longer or shorter from
# this moment on. It deliberately does not rescale the elapsed clock, so
# `day()` won't jump backwards when you drag it; only the pace of what's
# ahead changes.

# @export_range gives you the drag-slider in the inspector rather than a bare
# number field. Floor of 1s so a full day can be watched in a blink while
# tuning; ceiling of 600s (ten real minutes) so a day can also be slow enough
# to sit and watch. The `or_greater` lets you type past the ceiling anyway.
@export_range(1.0, 600.0, 0.5, "or_greater") var day_length_seconds := 60.0

# Seconds since this world started running. The only stored fact here.
var seconds := 0.0


func _process(delta: float) -> void:
	seconds += delta


# How far through the current day, in [0, 1). 0.0 is midnight, 0.5 is midday.
# This is what the daylight reads, and what any later day-curve hangs off.
func time_of_day() -> float:
	return fmod(seconds, day_length_seconds) / day_length_seconds


# Which day it is, counting from day 0.
func day() -> int:
	return int(seconds / day_length_seconds)


# "day 3 — 14:20", for anything that wants to show the time to a human.
# Worked out like everything else here; nothing is stored to make it.
func get_text() -> String:
	var total_minutes := int(time_of_day() * 24.0 * 60.0)
	return "day %d — %02d:%02d" % [day(), total_minutes / 60, total_minutes % 60]
