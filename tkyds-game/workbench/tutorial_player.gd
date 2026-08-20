extends RigidBody3D
## Embodied third-person player rig prototype. Mouse-look pivots + a
## physics-driven capsule. See the numbered defect list this file was
## reworked against for the reasoning behind each choice below.
##
## PHYSICS INTERPOLATION (verified against a live Godot 4.7.2-mono build via
## ProjectSettings.get_property_list() and Node.PhysicsInterpolationMode —
## not from memory): this body's transform only updates once per physics
## tick (default 60 Hz), so at any render framerate that doesn't line up
## with the physics rate, the whole camera rig judders. Godot ships a fix
## for exactly this, off by default project-wide. This script cannot edit
## project.godot, so add this by hand:
##
##   [physics]
##   common/physics_interpolation=true
##
## Once that's on, physics_interpolation_mode = ON (set on this node in
## tutorial_player.tscn) takes effect and the whole child hierarchy
## (TwistPivot/PitchPivot/Camera3D) rides the smoothed transform for free —
## a plain child Node3D under an interpolated body needs no interpolation
## code of its own, it composes on top of the parent's smoothed transform.
## Per-node physics_interpolation_mode CANNOT turn interpolation on by
## itself — it only opts a subtree out of an already-enabled global system.
##
## Caveat I could not verify by playtest: TwistPivot/PitchPivot are rotated
## every _process frame (see below), not every physics tick. Godot's
## interpolation samples a node's transform at physics-tick boundaries: if
## a child's own local transform changes off that cadence, its rotation
## may read one tick stale relative to the smoothly-interpolated parent.
## Whether that's visible at typical mouse-look speeds needs an actual
## playtest with the project setting on. If it reads janky, the fix is
## either (a) move the rotate_y/rotate_x calls into _physics_process too
## (caps look responsiveness at the physics tick rate), (b) decouple the
## camera rig from this body entirely — see the report for that tradeoff —
## or (c) TRY THIS ONE FIRST: set physics_interpolation_mode = OFF on
## TwistPivot, so the pivots opt OUT of the interpolation their parent opts
## into. Interpolation exists to smooth transforms that only change on the
## physics tick; these two change every frame already, so there is nothing
## for it to reconstruct and having it sample them at tick boundaries is
## what would make the look lag. Body interpolated for smooth POSITION,
## pivots un-interpolated for immediate ROTATION, is the shape that wants
## to be right here — but it is reasoning, not a measurement, and this
## whole block stays open until somebody actually plays it.

var mouse_sensitivity := 0.001
var twist_input := 0.0
var pitch_input := 0.0

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(_delta: float) -> void:
	# apply_central_force is a continuous force, not an impulse: verified
	# against the 4.7.2 RigidBody3D docs — "A force is time dependent and
	# meant to be applied every physics update." The physics engine
	# integrates it over the fixed physics timestep itself, once per tick.
	# Calling it from _process (as this did before) stacks several frames'
	# worth of force into one physics tick at high FPS and starves physics
	# ticks of any force at low FPS, because _process and physics ticks run
	# at different, uncorrelated rates. Moved here so it's called exactly
	# once per physics tick, and the `* delta` multiply is dropped — that
	# multiply doesn't belong on a per-tick force call, it was accidentally
	# papering over the accumulator bug, not fixing it.
	var move_direction := Vector3.ZERO
	move_direction.x = Input.get_axis("move_left", "move_right")
	move_direction.z = Input.get_axis("move_up", "move_down") # forward/back, despite the name
	# 20.0 N: the old `1200.0 * delta` only ever contributed ~1200/60 = 20
	# to a physics tick when render and physics rates coincided at 60 Hz —
	# this is that same reference magnitude, now the actual per-tick force
	# instead of an accident of the old bug. Unverified by playtest; retune
	# to taste once this can actually be run.
	apply_central_force(twist_pivot.basis * move_direction * 20.0)
	

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	# PitchPivot's rest pose now carries the 20 deg downward tilt that used
	# to be baked into TwistPivot's basis (see tutorial_player.tscn), so
	# the old +/-30 deg clamp (measured from a 0 rest) is shifted by that
	# same 20 deg to preserve the original look range: -10 deg .. 50 deg.
	pitch_pivot.rotation.x = clamp(
		pitch_pivot.rotation.x,
		deg_to_rad(-10),
		deg_to_rad(50)
	)

	# Consume this frame's mouse-look delta and zero it. _unhandled_input
	# only fires while the mouse is actually moving, so without this reset
	# the pivots keep rotating every frame at the last delta forever — this
	# was the runaway-rotation bug.
	twist_input = 0.0
	pitch_input = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		twist_input = -event.relative.x * mouse_sensitivity
		pitch_input = -event.relative.y * mouse_sensitivity
	elif event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		# Mouse capture was only ever released (ui_cancel), never
		# recaptured — clicking back into the view now recaptures it.
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
