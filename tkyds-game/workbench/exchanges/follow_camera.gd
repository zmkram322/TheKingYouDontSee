extends Node3D

# A mouse-look boom. Parent it to whatever it should ride — it holds no
# reference to a body, reads nothing about one, and moves nothing: the
# transform it inherits from its parent is the whole of how it follows.
#
# That is why it is its own scene rather than nodes inside
# person_with_exchange.tscn. The person scene stays camera-free, so the
# mannequin standing across the grass can instance the same body without a
# second Camera3D quietly stealing `current` from this one.
#
# THIS NODE IS THE YAW PIVOT ITSELF. Yaw turns this node, pitch turns the
# child, and the camera hangs off the child looking back down the boom. Two
# nodes rather than one because the two axes are clamped differently: yaw is
# free and wraps forever, pitch has to stop before the camera goes through
# the floor or over the top of the man's head.
#
# RE-DERIVED FROM workbench/tutorial_character.gd, NOT COPIED. That file
# accumulated mouse deltas into members and applied them in _process, which
# then needs a zeroing step every single frame or the pivots spin forever at
# the last delta they saw — a bug it had, and fixed, and left the fix visible.
# Rotating inside the event handler deletes the member, the reset AND the
# whole bug class with it: no delta outlives the event that carried it.

# Radians of rotation per pixel of mouse travel. Exported so it gets dragged
# rather than edited, and so a second rig can feel different without a fork.
@export var mouse_sensitivity := 0.0025

# How far the camera may look down and up, in DEGREES — because degrees are
# what somebody picking these by watching can actually reason about. Converted
# once, at the clamp. Down is negative: swinging the pitch child negatively
# lifts the boom and points the camera down at the body.
@export var looks_down_to := -60.0
@export var looks_up_to := 30.0

var _pitch: Node3D


func _ready() -> void:
	# Said out loud rather than guarded silently. CLAUDE.md's standing rule:
	# a missing wire that returns quietly is indistinguishable from "nothing
	# is happening yet", and that silence once shipped a dead day/night cycle
	# through two commits.
	_pitch = get_node_or_null(^"PitchPivot") as Node3D
	if _pitch == null:
		push_warning("a follow camera has no PitchPivot under it — it can only look sideways")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# What whoever is steering should treat as "forward", so that pushing the
# stick away from you means away from the CAMERA rather than along some fixed
# world axis. That difference is the whole difference between a camera you
# look with and a camera you drive with.
#
# YAW ONLY, and deliberately. This rig's own basis carries the pitch as well,
# and multiplying a movement vector by that would drive the body into the
# ground every time you looked down at it.
#
# Reading local `rotation.y` is honest here because this node's parent is a
# Person, and person.gd's rule is "turn the BODY, never the man" — the man's
# own rotation is always zero, so local yaw and world yaw are the same number.
# If a person ever starts rotating, this line is the one that breaks.
func get_steering_basis() -> Basis:
	return Basis(Vector3.UP, rotation.y)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		rotate_y(-motion.relative.x * mouse_sensitivity)
		if _pitch != null:
			_pitch.rotation.x = clamp(
				_pitch.rotation.x - motion.relative.y * mouse_sensitivity,
				deg_to_rad(looks_down_to),
				deg_to_rad(looks_up_to)
			)
		return
	# Let go with Escape, take it back with a click. The tutorial rig only ever
	# let go — once released there was no way back into the view short of
	# restarting the scene.
	if event.is_action_pressed(&"ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
