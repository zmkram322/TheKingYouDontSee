class_name Goal
extends RefCounted

# One chosen ActionOption in flight: the option itself, plus its own local
# execution state (current Activity + remaining steps). A villager's queue
# holds these — the front one is what's actually running; anything behind it
# is either paused (interrupted mid-flight, resumes untouched when it's next
# again) or queued (assigned from outside, not yet started). `started`
# distinguishes those two waiting states: begin() is only ever called once
# per goal, so resuming a paused goal never re-runs its Activity's begin().

var option: ActionOption
var doing: Activity = null
var plan: Array[Activity] = []
var started := false


func _init(new_option: ActionOption) -> void:
	option = new_option


func begin() -> void:
	started = true
	doing.begin()


# Called when doing.finished but plan still has steps — advances to the next
# local step of this same goal (e.g. WalkTo finished, Perform is next).
func advance_step() -> void:
	doing = plan.pop_front()
	doing.begin()


func is_complete() -> bool:
	return started and doing.finished and plan.is_empty()


func label() -> String:
	if not started:
		return "queued: " + option.label
	return doing.describe()
