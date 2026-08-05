class_name SkinAvatar
extends RefCounted

# One character's presentation on screen — never the character itself. The
# nodes here (the model, its AnimationPlayer, the two floating labels) are
# scene furniture the skin owns outright; the two plain fields below them
# are the skin's own memory of its last frame, kept for exactly the reason
# village_skin.gd's own docs allow it: where they stood a moment ago, so
# facing and "are they moving" can be derived, and how far into the eating
# gesture they've gotten. None of it is a fact the world would recognise —
# ask world.characters for that, always fresh, never held here.

var root: Node3D
var model: Node3D
var anim: AnimationPlayer
var name_label: Label3D
var doing_label: Label3D

var last_position: Vector2
var eating_phase := ""   # "" not eating, "sitting" mid-SitDown, "loop" settled into the eating loop


func _init(new_root: Node3D, new_model: Node3D, new_anim: AnimationPlayer,
		new_name_label: Label3D, new_doing_label: Label3D, starting_position: Vector2) -> void:
	root = new_root
	model = new_model
	anim = new_anim
	name_label = new_name_label
	doing_label = new_doing_label
	last_position = starting_position
