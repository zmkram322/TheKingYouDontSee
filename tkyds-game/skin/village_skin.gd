class_name VillageSkin
extends Node3D

# The watchable surface over world/village.gd. Everything below either reads
# `world` to decide what to draw, or passes one piece of player input
# straight through to it (the scare key, S — the same precedent
# sandbox/sandbox.gd sets with its own Scare button). Nothing else here ever
# writes to the world; `world.advance(delta)` in _process is the only thing
# that moves it, exactly the way tests/village_smoke.gd moves it, because
# this is the same VillageWorld that proof runs, not a second one.
#
# Position mapping: world positions are 2D pixels (see world/village.gd's
# FIELD_AT/MILL_AT/INN_AT/HOME_AT). POSITION_SCALE of 0.05 lands the whole
# cast on a ground plane spanning about 35 metres end to end — small enough
# to read as a village in one shot from the fixed camera below, without
# needing an orbit rig or a scale that makes the walk from home to the field
# feel like crossing a county.
#
# The verb FSM is deliberately dumb, per the brief: a verb maps to a clip
# name, AnimationPlayer.play() does the rest, and a clip is only replayed
# when it's actually finished (see _drive_animation) rather than restarted
# every frame — the one bit of bookkeeping needed to tell "loop this" from
# "hold on the last frame", which is what turns a single non-looping SitDown
# clip into both "sleeping" (holds) and "eating" (holds, then hands off to a
# second loop) without ever touching the clip itself.

const POSITION_SCALE := 0.05
const ASSET_ROOT := "res://skin/assets/"
const MOVE_EPSILON := 0.01   # world-position units; below this, "moving" is float noise, not a walk

# --- The verb vocabulary -> clip table -----------------------------------------
# See brain/step.gd's verb() and world/*.gd's leaves for where each of these
# is actually emitted. Anything arriving here that ISN'T one of these names
# is a real gap — see _resolve_clip's fallback, which logs it once rather
# than spamming a warning every frame.
const CLIP_WALK := "Walk"
const CLIP_WALK_CARRY := "Walk_Carry"
const CLIP_RUN := "Run"
const CLIP_PICKUP := "PickUp"
const CLIP_SIT := "SitDown"
const CLIP_IDLE := "Idle"

# Clips that read as continuous motion get restarted the instant they finish
# — the "looped" half of "PickUp (looped)" in the brief. SitDown is
# deliberately absent: it holds on its last frame, which is exactly what
# "sleeping -> SitDown held" and the first half of "eating -> SitDown then
# loop something sensible" both need.
const LOOPING_CLIPS := [CLIP_WALK, CLIP_WALK_CARRY, CLIP_RUN, CLIP_PICKUP, CLIP_IDLE]

const CHARACTER_MODEL_PATHS := {
	"Tam": ASSET_ROOT + "quaternius-ultimate-animated-character/glTF/Worker_Male.gltf",
	"Ivo": ASSET_ROOT + "quaternius-ultimate-animated-character/glTF/Worker_Male.gltf",
	"Cade": ASSET_ROOT + "quaternius-ultimate-animated-character/glTF/Worker_Male.gltf",
	"Osric": ASSET_ROOT + "quaternius-ultimate-animated-character/glTF/Worker_Male.gltf",
	"Maren": ASSET_ROOT + "quaternius-ultimate-animated-character/glTF/Worker_Female.gltf",
}

# Tints on the "Shirt" material surface only — enough to tell three men in
# the same base model apart at a glance without touching Skin/Pants/Hat/Face,
# which stay the pack's own flat colours.
const CHARACTER_TINTS := {
	"Tam": Color(0.80, 0.30, 0.28),
	"Ivo": Color(0.28, 0.55, 0.80),
	"Cade": Color(0.80, 0.62, 0.20),
	"Osric": Color(0.45, 0.42, 0.48),
	"Maren": Color(0.68, 0.32, 0.50),
}

var world: VillageWorld
var time_scale := 4.0
var labels_visible := true

var _avatars := {}            # String (character_name) -> SkinAvatar
var _warned_verbs := {}       # StringName -> true, so an unmapped verb is logged once, not every frame
var _sun: DirectionalLight3D
var _clock_label: Label
var _camera: Camera3D
var _camera_presets: Array[Dictionary] = []
var _camera_preset_index := 0

# A standing, kept-not-temporary version of key D's dump, fired on a plain
# real-time interval rather than a keypress — the same information the D key
# prints, just also available to a headless run (this session's own
# `--quit-after` proof included) with nobody at the keyboard to press it.
var _dump_accum := 0.0
const DUMP_INTERVAL_SECONDS := 2.0


func _ready() -> void:
	world = Village.build()
	_build_environment()
	_build_buildings_and_props()
	_spawn_avatars()
	_build_clock_readout()


func _process(delta: float) -> void:
	world.advance(delta * time_scale)
	for character_name in _all_names():
		_update_avatar(character_name, Village.find(world, character_name))
	_update_sun()
	_update_clock_label()

	_dump_accum += delta
	if _dump_accum >= DUMP_INTERVAL_SECONDS:
		_dump_accum = 0.0
		_dump_doing_labels()


# The known content↔world reference cycle (chores, offers, and every
# action's eligible/score closures all close over `world`) only breaks if
# something calls close_down() — see world/world.gd's own docs on why. Both
# hooks below call it: WM_CLOSE_REQUEST for a windowed run, _exit_tree for
# the headless --quit-after path this session's own proof run uses. Calling
# it twice is harmless — close_down() just clears already-empty arrays the
# second time.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		world.close_down()
		get_tree().quit()


func _exit_tree() -> void:
	world.close_down()


# --- Input: one sanctioned write-through, three read-only conveniences -----------

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1:
			time_scale = 1.0
		KEY_2:
			time_scale = 4.0
		KEY_3:
			time_scale = 10.0
		KEY_L:
			labels_visible = not labels_visible
			_set_labels_visible(labels_visible)
		KEY_C:
			_cycle_camera()
		KEY_S:
			_scare_the_miller()
		KEY_D:
			_dump_doing_labels()


func _set_labels_visible(visible_now: bool) -> void:
	for character_name in _avatars:
		var avatar: SkinAvatar = _avatars[character_name]
		avatar.name_label.visible = visible_now
		avatar.doing_label.visible = visible_now


func _cycle_camera() -> void:
	if _camera_presets.is_empty():
		return
	_camera_preset_index = (_camera_preset_index + 1) % _camera_presets.size()
	var preset: Dictionary = _camera_presets[_camera_preset_index]
	_camera.position = preset.position
	_camera.look_at(preset.look_at, Vector3.UP)


# The one sanctioned write: player input passing straight through to the
# world, the same shape sandbox/sandbox.gd's own Scare button uses. Nothing
# else in this file ever calls set_stat or reconsider.
func _scare_the_miller() -> void:
	var osric := Village.find(world, Village.MILLER_NAME)
	if osric == null:
		return
	osric.set_stat(&"fear", 100.0)
	world.reconsider(osric)
	print("village skin: scared %s — fear set to 100" % Village.MILLER_NAME)


func _dump_doing_labels() -> void:
	print("--- doing, at t=%.2f (day %d) ---" % [world.time_of_day(), world.day()])
	for character_name in _all_names():
		var who := Village.find(world, character_name)
		print("  %s: %s" % [character_name, who.doing_label()])


# Every resident's name, in the same order Village itself builds them —
# asked for fresh each time rather than held anywhere, same reasoning as
# calling Village.find() every frame instead of keeping a Character.
func _all_names() -> Array[String]:
	var names: Array[String] = []
	for farmhand_name in Village.FARMHAND_NAMES:
		names.append(farmhand_name)
	names.append(Village.MILLER_NAME)
	names.append(Village.INNKEEPER_NAME)
	return names


func _world_to_3d(at: Vector2) -> Vector3:
	return Vector3(at.x * POSITION_SCALE, 0.0, at.y * POSITION_SCALE)


# --- The set: ground, light, camera, one place apiece ---------------------------

func _build_environment() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60.0, 40.0)
	ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	# Flat colour on purpose — no ground texture was sourced (see CREDITS.md's
	# own note on why), and flat matches every other flat-shaded surface in
	# this asset set rather than sticking out as the one textured thing.
	ground_material.albedo_color = Color(0.36, 0.52, 0.32)
	ground_material.roughness = 1.0
	ground.material_override = ground_material
	ground.position = Vector3(2.5, -0.02, 5.5)
	add_child(ground)

	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.55, 0.68, 0.78)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.60, 0.65)
	environment.ambient_light_energy = 0.6
	environment_node.environment = environment
	add_child(environment_node)

	_sun = DirectionalLight3D.new()
	_sun.light_energy = 1.0
	_sun.shadow_enabled = false
	add_child(_sun)

	_camera = Camera3D.new()
	add_child(_camera)
	_camera_presets = [
		{"position": Vector3(0.0, 18.0, 30.0), "look_at": Vector3(2.5, 0.0, 5.5)},   # angled three-quarter view, the default
		{"position": Vector3(2.5, 32.0, 6.5), "look_at": Vector3(2.5, 0.0, 5.5)},    # near-overhead, for reading the whole layout at once
	]
	var default_preset: Dictionary = _camera_presets[0]
	_camera.position = default_preset.position
	_camera.fov = 50.0
	_camera.look_at(default_preset.look_at, Vector3.UP)
	_camera.current = true


func _build_buildings_and_props() -> void:
	_place_model(ASSET_ROOT + "quaternius-medieval-village/Buildings/Inn.fbx", Village.INN_AT, 200.0)
	_place_model(ASSET_ROOT + "quaternius-medieval-village/Buildings/Mill.fbx", Village.MILL_AT, 340.0)
	_place_model(ASSET_ROOT + "quaternius-medieval-village/Buildings/House_1.fbx", Village.HOME_AT, 160.0)
	_place_model(ASSET_ROOT + "quaternius-ultimate-furniture/BedDouble.fbx", Village.HOME_AT, 0.0, Vector3(1.4, 0.0, -1.2))

	# The field earns a patch of crops, not one lonely stalk — it's what
	# three farmhands' whole morning goes into.
	var rows := 3
	var cols := 3
	var spacing := 1.4
	for row in rows:
		for col in cols:
			var offset := Vector3((col - 1) * spacing, 0.0, (row - 1) * spacing)
			_place_model(ASSET_ROOT + "quaternius-ultimate-crops/Wheat_1.fbx", Village.FIELD_AT,
				randf() * 360.0, offset)

	# Sparse dressing, for grounding rather than clutter.
	_place_model(ASSET_ROOT + "quaternius-medieval-village/Props/Well.fbx", Village.MILL_AT, 0.0, Vector3(3.0, 0.0, 2.0))
	_place_model(ASSET_ROOT + "quaternius-medieval-village/Props/Barrel.fbx", Village.INN_AT, 0.0, Vector3(2.0, 0.0, 1.4))
	_place_model(ASSET_ROOT + "quaternius-medieval-village/Props/Barrel.fbx", Village.INN_AT, 0.0, Vector3(2.6, 0.0, 0.9))
	_place_model(ASSET_ROOT + "quaternius-medieval-village/Props/Fence.fbx", Village.FIELD_AT, 90.0, Vector3(-3.2, 0.0, -3.2))
	_place_model(ASSET_ROOT + "quaternius-medieval-village/Props/Fence.fbx", Village.FIELD_AT, 90.0, Vector3(-1.8, 0.0, -3.2))


func _place_model(path: String, at: Vector2, y_rotation_deg: float, extra_offset: Vector3 = Vector3.ZERO) -> Node3D:
	var scene: PackedScene = load(path)
	var instance := scene.instantiate() as Node3D
	add_child(instance)
	instance.position = _world_to_3d(at) + extra_offset
	instance.rotation_degrees.y = y_rotation_deg
	return instance


func _update_sun() -> void:
	var t := world.time_of_day()
	# One full arc per day, driven straight off the world's own clock: below
	# the horizon at midnight, overhead at midday. Cheap and read-only, which
	# is the whole point — this is what makes dawn/midday/dusk/night legible
	# at a glance without a second schedule to keep in sync with WorldTune's.
	_sun.rotation.x = t * TAU - PI / 2.0
	var height := sin(t * TAU)   # -1 at midnight, +1 at midday
	var warmth := clampf(1.0 - absf(height), 0.0, 1.0)
	_sun.light_color = Color(1.0, 1.0 - 0.25 * warmth, 1.0 - 0.5 * warmth)
	_sun.light_energy = clampf(0.15 + maxf(height, 0.0), 0.15, 1.15)


# --- The clock readout, honest-but-ugly per the brief ---------------------------

func _build_clock_readout() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	_clock_label = Label.new()
	_clock_label.position = Vector2(8, 8)
	_clock_label.add_theme_font_size_override("font_size", 18)
	canvas.add_child(_clock_label)


func _update_clock_label() -> void:
	var t := world.time_of_day()
	var total_minutes := int(t * 24.0 * 60.0)
	_clock_label.text = "day %d — %02d:%02d" % [world.day(), total_minutes / 60, total_minutes % 60]


# --- The five avatars -------------------------------------------------------------

func _spawn_avatars() -> void:
	for character_name in _all_names():
		var who := Village.find(world, character_name)
		var model_scene: PackedScene = load(CHARACTER_MODEL_PATHS[character_name])
		var model := model_scene.instantiate() as Node3D
		_tint_character(model, CHARACTER_TINTS[character_name])
		var anim := _find_animation_player(model)

		var root := Node3D.new()
		root.name = "avatar_%s" % character_name
		add_child(root)
		root.position = _world_to_3d(who.stat(&"position"))
		root.add_child(model)

		var name_label := Label3D.new()
		name_label.text = character_name
		name_label.position = Vector3(0.0, 2.2, 0.0)
		name_label.font_size = 32
		name_label.outline_size = 6
		name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		root.add_child(name_label)

		var doing_label := Label3D.new()
		doing_label.position = Vector3(0.0, 1.9, 0.0)
		doing_label.font_size = 20
		doing_label.modulate = Color(0.85, 0.85, 0.85)
		doing_label.outline_size = 4
		doing_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		root.add_child(doing_label)

		_avatars[character_name] = SkinAvatar.new(root, model, anim, name_label, doing_label,
			who.stat(&"position"))

		if anim != null:
			anim.play(CLIP_IDLE)


func _tint_character(model: Node3D, tint: Color) -> void:
	var mesh_instance := _find_mesh_instance(model)
	if mesh_instance == null or mesh_instance.mesh == null:
		return
	for i in mesh_instance.mesh.get_surface_count():
		var surface_material := mesh_instance.mesh.surface_get_material(i)
		if surface_material != null and surface_material.resource_name == "Shirt":
			var tinted: Material = surface_material.duplicate()
			tinted.albedo_color = tint
			mesh_instance.set_surface_override_material(i, tinted)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _find_mesh_instance(child)
		if found != null:
			return found
	return null


# One avatar, one frame: read where they are and what they're doing, draw
# that. `who` is looked up fresh by the caller every frame rather than held
# — see _all_names()'s own note.
func _update_avatar(character_name: String, who: Character) -> void:
	var avatar: SkinAvatar = _avatars[character_name]

	var current_position: Vector2 = who.stat(&"position")
	var moved: Vector2 = current_position - avatar.last_position
	var moving := moved.length() > MOVE_EPSILON

	avatar.root.position = _world_to_3d(current_position)
	if moving:
		avatar.root.look_at(avatar.root.position + Vector3(moved.x, 0.0, moved.y), Vector3.UP)
	avatar.last_position = current_position

	var verb: StringName = &""
	if who.active_action != null:
		verb = who.active_action.body.verb(who)
	_drive_animation(avatar, verb, moving)

	avatar.doing_label.text = who.doing_label()


# The verb FSM. Advances eating's own two-phase state (sitting -> loop) and
# then plays whatever clip that state resolves to, restarting it only if
# it's both a looping clip and has actually finished — see LOOPING_CLIPS'
# own comment for why SitDown is excluded from that restart.
func _drive_animation(avatar: SkinAvatar, verb: StringName, moving: bool) -> void:
	if avatar.anim == null:
		return

	if verb != &"eating":
		avatar.eating_phase = ""
	elif avatar.eating_phase == "":
		avatar.eating_phase = "sitting"
	elif avatar.eating_phase == "sitting" and avatar.anim.current_animation == CLIP_SIT \
			and not avatar.anim.is_playing():
		avatar.eating_phase = "loop"

	var clip := _resolve_clip(avatar, verb, moving)
	if avatar.anim.current_animation != clip:
		avatar.anim.play(clip)
	elif clip in LOOPING_CLIPS and not avatar.anim.is_playing():
		avatar.anim.play(clip)


func _resolve_clip(avatar: SkinAvatar, verb: StringName, moving: bool) -> String:
	match verb:
		&"walking":
			return CLIP_WALK
		&"carrying":
			return CLIP_WALK_CARRY if moving else CLIP_PICKUP
		&"fleeing":
			return CLIP_RUN
		&"working", &"grinding", &"baking":
			return CLIP_PICKUP
		&"eating":
			return CLIP_SIT if avatar.eating_phase == "sitting" else CLIP_PICKUP
		&"sleeping":
			return CLIP_SIT
		&"idling", &"":
			return CLIP_IDLE
		_:
			if not _warned_verbs.has(verb):
				_warned_verbs[verb] = true
				push_warning("village skin: no clip mapped for verb \"%s\" — defaulting to Idle" % verb)
			return CLIP_IDLE
