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


# The one place a person's thinking is driven from. It sits here rather than in
# Brain's own _process so that later, when there are more people than a frame
# can afford to think for, one driver can take this over and spread them out —
# turning off a Person's processing is a smaller change than unpicking a
# _process from every Brain in the world.
func _process(delta: float) -> void:
	brain.tick(delta)
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
	var lines := [person_name, brain.doing_label()]
	for what in stats.names():
		var value: Variant = stats.value_of(what)
		lines.append("%s %s" % [what, _read(value)])
	return "\n".join(lines)


# Numbers get a decimal place; yes/no stats read as words. Anything else falls
# back to however it prints itself.
func _read(value: Variant) -> String:
	if value is float or value is int:
		return "%.1f" % value
	if value is bool:
		return "yes" if value else "no"
	return str(value)
