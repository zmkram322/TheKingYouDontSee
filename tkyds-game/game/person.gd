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

# Where real time becomes world time for this man. Dragged in from the
# inspector rather than found by path, so moving either node doesn't silently
# break the link — Godot repoints the reference for you.
#
# It is here only until Population exists. Rung 1 hoists the conversion into
# Population.think_for_everyone, one clock read for the whole town instead of
# one per body, and this export goes away with it.
#
# Note for whoever wires this in a .tscn by hand: it needs
# `node_paths=PackedStringArray("clock")` on the node's own header line, or the
# loader assigns the raw NodePath to a typed field and you get null.
@export var clock: Clock

@onready var stats: Stats = $Stats
@onready var brain: Brain = $Brain
@onready var readout: Label3D = $Readout

@onready var _shape: MeshInstance3D = $Shape


func _ready() -> void:
	_apply_tint()
	# Says so out loud rather than standing there quietly doing nothing. A man
	# with no clock never thinks, and without this that is indistinguishable
	# from a man who simply isn't tired yet.
	if clock == null:
		push_warning("%s has no Clock — he will never think" % person_name)


# One slice of living, in world HOURS. Extracted out of _process so that
# anything driving the simulation by hand — a harness pumping a day in a
# fraction of a second — advances him by exactly the same path the game does,
# rather than by a second route that can quietly diverge from it.
#
# It takes hours, not a real delta, because everything below Clock does. Rung 1
# moves the caller: Population reads the clock once and hands the same `hours`
# to everybody. Nothing in here changes when that happens.
func think_and_act(hours: float) -> void:
	brain.think_and_act(hours)


# The one place a person's thinking is driven from, and the one place a real
# frame delta is turned into world time for him. It sits here rather than in
# Brain's own _process so that later, when there are more people than a frame
# can afford to think for, one driver can take this over and spread them out —
# turning off a Person's processing is a smaller change than unpicking a
# _process from every Brain in the world.
#
# The readout stays on _process and deliberately does NOT ride think_and_act.
# It is presentation: it should redraw once per frame the eye sees, not once
# per slice of simulated time. Fold it in and a harness pumping a thousand
# ticks would rebuild a label a thousand times for nobody, and a rung 1
# stagger that thinks every fourth frame would freeze the text above his head.
func _process(delta: float) -> void:
	if clock != null:
		think_and_act(clock.get_hours_elapsed(delta))
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
