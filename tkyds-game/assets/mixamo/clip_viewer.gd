extends Node3D

# A room with a light, a floor and the rig in it, plus a button per clip.
# Discovers what to show by asking the AnimationPlayer, so adding a Mixamo
# file never means editing this file -- same reflex as verb_list.

const CHARACTER := "res://assets/mixamo/y_bot.tscn"

var _player: AnimationPlayer = null
var _now_playing: Label = null
var _looping: CheckBox = null


func _ready() -> void:
	var character: Node3D = (load(CHARACTER) as PackedScene).instantiate()
	add_child(character)
	_player = _find_animation_player(character)
	if _player == null:
		push_error("clip_viewer: %s has no AnimationPlayer." % CHARACTER)
		return
	_player.animation_finished.connect(_on_clip_finished)

	_build_room()
	_build_panel()
	_play_clip("idle" if _player.has_animation("idle") else _first_clip())


func _build_room() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, -35.0, 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)

	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_horizon_color = Color(0.55, 0.58, 0.62)
	sky_material.ground_horizon_color = Color(0.4, 0.4, 0.42)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.6
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(12.0, 12.0)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.32, 0.34, 0.33)
	floor_mesh.material = floor_material
	var ground := MeshInstance3D.new()
	ground.mesh = floor_mesh
	add_child(ground)

	# A metre-spaced grid so a clip that still drifts is obvious by eye,
	# not only in the drift column of report_clips.gd.
	for step in 13:
		var offset: float = float(step) - 6.0
		_add_grid_line(Vector3(offset, 0.01, 0.0), Vector3(0.02, 0.02, 12.0))
		_add_grid_line(Vector3(0.0, 0.01, offset), Vector3(12.0, 0.02, 0.02))

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.15, 3.4)
	camera.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
	add_child(camera)


func _add_grid_line(where: Vector3, size: Vector3) -> void:
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.42, 0.44, 0.43)
	box.material = material
	var line := MeshInstance3D.new()
	line.mesh = box
	line.position = where
	add_child(line)


func _build_panel() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	layer.add_child(margin)

	var column := VBoxContainer.new()
	margin.add_child(column)

	_now_playing = Label.new()
	_now_playing.add_theme_font_size_override("font_size", 20)
	column.add_child(_now_playing)

	_looping = CheckBox.new()
	_looping.text = "hold clip"
	_looping.button_pressed = true
	_looping.tooltip_text = "Replay one-shot clips instead of settling back to idle."
	column.add_child(_looping)

	var scroller := ScrollContainer.new()
	scroller.custom_minimum_size = Vector2(190.0, 460.0)
	column.add_child(scroller)

	var buttons := VBoxContainer.new()
	scroller.add_child(buttons)
	var clip_names: PackedStringArray = _player.get_animation_list()
	for clip_name in clip_names:
		var button := Button.new()
		button.text = clip_name
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_play_clip.bind(clip_name))
		buttons.add_child(button)


func _play_clip(clip_name: String) -> void:
	_player.play(clip_name)
	var animation: Animation = _player.get_animation(clip_name)
	var loops: String = "loops" if animation.loop_mode != Animation.LOOP_NONE else "one-shot"
	_now_playing.text = "%s\n%.2fs, %s" % [clip_name, animation.length, loops]


func _on_clip_finished(clip_name: StringName) -> void:
	if _looping != null and _looping.button_pressed:
		_play_clip(String(clip_name))
	elif _player.has_animation("idle"):
		_play_clip("idle")


func _first_clip() -> String:
	var clip_names: PackedStringArray = _player.get_animation_list()
	return String(clip_names[0]) if clip_names.size() > 0 else ""


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null
