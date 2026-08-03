class_name Goal
extends RefCounted

# One chosen ActionOption in flight: the option, plus its own execution
# state as a single State (almost always a SequenceState — see
# SandboxWorld.build_goal). An actor's Orchestrator holds a stack of these —
# the front one is what's actually running; anything behind it is either
# paused (interrupted mid-flight, resumes untouched when it's next again) or
# queued (assigned from outside, not yet started). `started` distinguishes
# those two waiting states: begin() is only ever called once per goal, so
# resuming a paused goal never re-runs its root's begin().

var option: ActionOption
var root: State = null
var started := false


func _init(new_option: ActionOption) -> void:
	option = new_option


func begin() -> void:
	started = true
	root.begin()


func is_complete() -> bool:
	return started and root.finished


func label() -> String:
	if not started:
		return "queued: " + option.label
	return root.describe()
