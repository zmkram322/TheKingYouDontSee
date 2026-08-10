class_name Person
extends CharacterBody3D

# One person in the world. A scene of its own (person.tscn) rather than nodes
# built inline in game.tscn, so that everyone who ever lives here is the same
# thing instanced again — Zoogs is not a special class, he is this scene with
# a name typed into it.
#
# What makes an instance somebody in particular is the exports below and the
# starting values on their Stats node, both overridable per instance straight
# from the inspector. When someone eventually needs a node nobody else has,
# that's what Godot's inherited scenes are for; nothing here has to change to
# allow it.
#
# The body itself doesn't move yet — no walking, nowhere to walk. It's a
# CharacterBody3D now rather than a Node3D so that when movement arrives it
# lands on the node already carrying `velocity` and `move_and_slide`, instead
# of a scene-wide retype.

@export var person_name := "Someone"

# Enough to tell people apart at a glance once there's more than one. Applied
# to the capsule in _ready rather than authored into person.tscn's material,
# so every instance can differ without needing a material file apiece.
@export var tint := Color(0.78, 0.74, 0.68)

@onready var stats: Stats = $Stats
@onready var brain: Brain = $Brain
@onready var readout: Label3D = $Readout

@onready var _shape: MeshInstance3D = $Shape


func _ready() -> void:
	_apply_tint()
	# Says so out loud rather than standing there quietly not living. Nothing
	# here drives itself any more — a person dropped into a scene without a
	# Population above him never thinks, never tires and never sleeps, and
	# without this that is indistinguishable from a man who is merely well
	# rested. It is the same silence that shipped a dead day/night cycle.
	if get_parent() as Population == null:
		push_warning("%s has no Population above him — he will never think" % person_name)


# One slice of living, in world HOURS. Not called from here: Population walks
# its people and hands each of them the same slice, having read the Clock once
# for all of them. That is the seam — everything later about WHO thinks and
# HOW OFTEN installs up there, at one call site, rather than in every body.
#
# It takes hours, not a real delta, because everything below Clock does. Kept
# as its own method rather than folded into the caller so that a harness
# pumping a day in a fraction of a second advances him by exactly the path the
# game uses, rather than by a second route that can quietly diverge from it.
func think_and_act(hours: float) -> void:
	brain.think_and_act(hours)


# What's over his head, and nothing else. The readout deliberately does NOT
# ride think_and_act: it is presentation, so it should redraw once per frame
# the eye sees, not once per slice of simulated time. Fold it in and a harness
# pumping a thousand ticks would rebuild a label a thousand times for nobody —
# and the day Population starts thinking for him every fourth frame, the text
# above his head would freeze between thoughts.
func _process(_delta: float) -> void:
	readout.text = _readout_text()


func _apply_tint() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 1.0
	_shape.material_override = material


# What's floating over his head: his name, what he's doing, and every stat he
# has. The stats are listed rather than named one by one so that adding one to
# Stats makes it show up here without this file changing.
func _readout_text() -> String:
	var lines := [person_name, brain.describe_current_action()]
	# Asked for by name rather than picked up off the stat list, because being
	# awake isn't a stat he carries — see Brain.is_awake.
	lines.append("awake %s" % ["yes" if brain.is_awake() else "no"])
	for stat_name in stats.get_stat_names():
		var value: Variant = stats.get_stat(stat_name)
		lines.append("%s %s" % [stat_name, _as_text(value)])
	return "\n".join(lines)


# Numbers get a decimal place; yes/no stats read as words. Anything else falls
# back to however it prints itself.
func _as_text(value: Variant) -> String:
	if value is float or value is int:
		return "%.1f" % value
	if value is bool:
		return "yes" if value else "no"
	return str(value)
