class_name Clock
extends Node

# The one thing that moves time, and the ONE place real seconds are ever
# converted into world time. Everything else in game/ reads it and draws;
# nothing else advances it, and nothing else is allowed to interpret a
# real-time delta.
#
# It holds exactly one fact — how many world HOURS this world has been running
# — and derives the rest on read. A stored "which day is it" counter could only
# ever agree with `hours_elapsed` or be a bug, so there isn't one. Same
# discipline the older world/ code used, just living on a Node now so you can
# watch it in the inspector while it runs.
#
# The stored fact is hours rather than real seconds on purpose. Real time
# enters at get_hours_elapsed() and is never seen again — so the elapsed clock
# is denominated in the same unit as every rate in the game, and dragging the
# day-length slider cannot make the calendar jump. (It could, when this stored
# seconds and divided on read: dragging 60s → 10s turned day 1 into day 6.)
#
# day_length_seconds is the slider: how long a day FEELS. Changing it mid-run
# is safe and does what you'd expect — the day gets longer or shorter from
# this moment on. Now that the body is denominated in hours too, dragging it
# scales the WHOLE world together: the sun, sleep pressure and the calendar all
# speed up as one. That is what its comment always claimed and what it now
# actually does.

# @export_range gives you the drag-slider in the inspector rather than a bare
# number field. Floor of 1s so a full day can be watched in a blink while
# tuning; ceiling of 600s (ten real minutes) so a day can also be slow enough
# to sit and watch. The `or_greater` lets you type past the ceiling anyway.
@export_range(1.0, 600.0, 0.5, "or_greater") var day_length_seconds := 60.0

# World hours since this world started running. The only stored fact here.
var hours_elapsed := 0.0


# THE converter. The single line in the project where real time becomes world
# time — everything downstream takes hours and never sees a real delta again.
# Keep it that way: a second caller doing its own division is how the body and
# the sun drifted apart in the first place.
func get_hours_elapsed(real_delta: float) -> float:
	return real_delta / day_length_seconds * 24.0


# Move the world on. Takes hours, like everything else below the converter, so
# a harness pumping the simulation by hand advances the clock in the same unit
# it advances people — and cannot desynchronise the two by accident.
func advance(hours: float) -> void:
	hours_elapsed += hours


func _process(delta: float) -> void:
	advance(get_hours_elapsed(delta))


# How far through the current day, in [0, 1). 0.0 is midnight, 0.5 is midday.
# This is what the daylight reads, and what any later day-curve hangs off.
func time_of_day() -> float:
	return fmod(hours_elapsed, 24.0) / 24.0


# Which day it is, counting from day 0.
func day() -> int:
	return int(hours_elapsed / 24.0)


# "day 3 — 14:20", for anything that wants to show the time to a human.
# Worked out like everything else here; nothing is stored to make it.
func get_text() -> String:
	var total_minutes := int(time_of_day() * 24.0 * 60.0)
	return "day %d — %02d:%02d" % [day(), total_minutes / 60, total_minutes % 60]
