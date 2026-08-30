extends PlayerBrain

# The steered fork, moved off the world clock and onto the physics tick.
#
# WHAT THIS EXPERIMENT ACTUALLY IS. PlayerBrain integrates the player's
# position by hand, in WORLD HOURS, inside think_and_act — no velocity, no
# gravity, and Decision 4 forbids move_and_slide outright. That trade buys one
# thing and it is not a small thing: dragging day_length_seconds cannot change
# how fast the player walks relative to the NPCs beside him, because he and
# they are measured in the same hours. What it costs is everything that needs
# a physics body — falling, being airborne at all, jumping, sliding along a
# wall instead of stopping dead against it.
#
# This file takes the other side of that trade, in a workbench, where taking
# it wrong is free. Movement happens in _physics_process against a REAL delta.
#
# IF IT READS WELL, what carries back into game/ is this file's
# _physics_process plus person_with_exchange.gd's _show_the_body — and the
# first question to answer before either moves is what the hour-based probe
# claims about player movement become, because claim 66 pins movement by
# driving real frame deltas through Clock.get_hours_elapsed at two different
# day lengths, and that claim is measuring a thing this file stops doing.
#
# NOTHING IN game/ IS EDITED BY THIS FILE. It only extends.

# Typed against the script rather than against Node3D, so get_steering_basis()
# resolves at parse time instead of erroring on a bare Node3D. preload'd as a
# const because no script under workbench/ takes a class_name — those are
# project-global and there is no reason to burn one on an experiment.
const FollowCamera := preload("res://workbench/exchanges/follow_camera.gd")

# METRES PER SECOND, both of them, and NOT convertible to person.gd's
# walk_speed — that number is units per WORLD HOUR and means nothing on a
# physics tick. Authored by watching, which is the only way numbers like these
# ever get picked, and exported so watching is how they get changed.
@export var walk_speed := 2.2
@export var run_speed := 5.5

# The one upward shove a jump is. Higher is floatier; gravity below is what it
# is fighting, and the arc only means anything as the pair.
@export var jump_speed := 4.8

# Its own number rather than a read of ProjectSettings, so it can be dragged
# against jump_speed while watching. A workbench is exactly where a physically
# wrong number that feels right is allowed to win.
@export var gravity := 12.0

# How fast he sheds speed when nothing is pushing him, in metres per second
# per second.
@export var braking := 24.0

# THE GESTURE HE IS STANDING STILL FOR. Press a verb and the stick goes dead
# until his body has got through the clip that verb's own step declares — so a
# take is a man reaching into a basket rather than a man sliding away from one
# mid-reach, and a greeting cannot be walked out of halfway through the wave.
#
# A CLIP NAME AND NOT A TIMER, and W11b is why: a second number counting down
# beside the animation is a number that races it, and dragging any tuning slider
# makes them disagree. The AnimationPlayer already knows when a clip has run
# out — Person.is_gesture_pending asks it — so there is exactly one answer and
# nothing to keep in step.
#
# IT CANNOT STICK. Three separate things end it: the clip finishing, the chosen
# verb being dropped out from under him, and a clip that loops never being
# pending in the first place (so telling a man to work the ground does not weld
# his feet to the floor). A man frozen for ever by a UI is the failure this is
# most worth guarding, and it is guarded by the hold being DERIVED rather than
# remembered — this field is a question, not a state.
var _gesturing: StringName = &""

# Which rig says where forward is.
#
# THE NOTE THAT WAS HERE WAS WRONG, AND IT WAS WRONG BECAUSE IT BELIEVED THE
# PROBE OVER THE ENGINE. It read: "CORRECTED 2026-08-21 after probe claim 4 went
# red on exactly this: a BARE NodePath export needs node_paths on the .tscn node
# header too, not just a Node-typed one — the earlier note here claimed otherwise
# and was wrong." The note it called wrong was right.
#
# MEASURED 2026-08-30, decisively. person_with_exchange.tscn was given
# `steered_by_camera = NodePath("../DecisiveTestValue")` — deliberately DIFFERENT
# from the default below, so a dropped value could not hide behind it — and the
# instantiated Brain read it back intact and non-empty. A bare NodePath export
# stores a NodePath and needs no resolution, so `node_paths` does not apply to
# it; that list exists for properties typed as a NODE, where the loader has to
# turn a path into an object. get_node_or_null() below does the resolving here,
# at runtime, which is the whole reason the type is NodePath in the first place.
#
# SO PROBE CLAIM 4 HAS A FALSE POSITIVE, and it is the mirror of the blind spot
# already recorded in DECISIONS.md: it flags any NodePath(...) assignment missing
# from node_paths, which is only a bug when the property is Node-typed. Claim 4
# is red on this file today and the wire is fine. Left for the author to rule on
# rather than quietly patched — it is the project's standing green.
@export var steered_by_camera := NodePath("../FollowCamera")

var _camera: FollowCamera


func _ready() -> void:
	super()
	_camera = get_node_or_null(steered_by_camera) as FollowCamera
	if _camera == null:
		push_warning("an exchange brain has no camera to steer by — forward will mean north, forever")


# Movement has exactly ONE writer in this body, and it is this function.
#
# PlayerBrain's hour-integrated walk is emptied rather than left alone, because
# leaving it would be a trap rather than dead code: the whole reason for
# keeping the real substrate underneath is that a Population can be wired above
# this scene later, and the moment one is, think_and_act starts running and
# this body would be moved twice on the same frame — once in hours, once in
# seconds — by two writers that disagree. Same one-writer rule person.gd states
# for current_place, applied to position instead.
func _walk_where_he_is_pointed(_hours: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	if person == null:
		return

	var moving := person.velocity

	if not person.is_on_floor():
		moving.y -= gravity * delta
	elif moving.y < 0.0:
		# Parked rather than left to run away. is_on_floor() only holds while
		# the body keeps being pressed into the floor, and an ever-growing
		# negative y is what makes a grounded body report airborne on alternate
		# ticks — which would strobe the falling clip at a man standing still.
		moving.y = 0.0

	# ONE SHOVE, ON THE PRESS. tutorial_character.gd read BOTH
	# is_action_just_pressed AND is_action_pressed and added lift on each, so
	# holding the key flew. just_pressed alone is the whole of a jump.
	if person.is_on_floor() and not _is_still_gesturing() and Input.is_action_just_pressed(&"ui_jump"):
		moving.y = jump_speed

	# THE STICK, AND WHETHER HE STILL HAS IT. Asked before the input is read
	# rather than after, so a held man never has a direction worked out for him
	# and then thrown away.
	var steer := Vector2.ZERO
	if _is_still_gesturing():
		# Braking is left running below, so he COASTS TO A STOP rather than
		# stopping dead on the keypress. A body that halts in one frame reads as
		# a dropped input; a body that settles reads as a man planting his feet.
		pass
	else:
		steer = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var pointed := Vector3(steer.x, 0.0, steer.y)
	if _camera != null:
		pointed = _camera.get_steering_basis() * pointed

	var speed := run_speed if Input.is_action_pressed(&"sprint") else walk_speed
	if pointed.length_squared() > 0.0:
		pointed = pointed.normalized()
		moving.x = pointed.x * speed
		moving.z = pointed.z * speed
	else:
		# PER SECOND, not per tick. move_toward's third argument is a distance,
		# so handing it a bare speed — as the tutorial rig did — makes how fast
		# he stops depend on the physics rate rather than on the number.
		moving.x = move_toward(moving.x, 0.0, braking * delta)
		moving.z = move_toward(moving.z, 0.0, braking * delta)

	person.velocity = moving
	person.move_and_slide()

# WATCH, DON'T FIX: he can still be steered while asleep, and for the same
# reason PlayerBrain gives — nothing here gates movement on is_awake, because
# Decision 33 leaves open whether the player's own drives ever constrain him,
# and a movement function is the wrong place to answer that quietly. It is
# no longer moot: exchanges.tscn now has a Population, so he genuinely does
# tire, and steering a sleeping man is a thing you can actually watch here.


# Is he mid-gesture — and, every time it is asked, is that still TRUE? The field
# is cleared here rather than anywhere else, so there is one place a hold can end
# and no way to leave one standing.
func _is_still_gesturing() -> bool:
	if _gesturing.is_empty():
		return false
	if person == null or get_chosen_verb() == null 			or not person.is_gesture_pending(_gesturing):
		_gesturing = &""
		return false
	return true


# A PRESS IS WHAT STARTS ONE, which is the whole reason this override exists.
# choose_verb is already the one door a hand comes through (Decision 33: the
# command is a bid), so the hold is picked up exactly where the intent is and
# nowhere else — the arc does not know this happens and did not have to change.
func choose_verb(action: Action) -> void:
	super(action)
	_gesturing = &""
	if person == null or action == null:
		return
	# Said again out loud, because he may have made this very gesture a moment
	# ago and a spent one would read as already finished.
	person.start_gesture_again()
	_gesturing = _find_declared_clip(action)


# Whatever the action's own step says his body does. Read off the step rather
# than off a table here, for the reason the whole body layer exists: a file in
# game/ mapping a verb to an animation is code naming verbs. This does not know
# what it found and does not look.
func _find_declared_clip(action: Action) -> StringName:
	for child in action.get_children():
		var step := child as ActionStep
		if step != null and not step.clip.is_empty():
			return step.clip
	return &""
