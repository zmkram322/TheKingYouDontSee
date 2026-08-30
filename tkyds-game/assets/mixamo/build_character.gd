extends SceneTree

# Temporary build step. Merges the 21 per-file Mixamo AnimationLibraries into
# ONE library so clips are addressed by bare name -- "walk", not "walk/walk" --
# then saves a character scene carrying it.
#
# Re-run whenever a clip is added or mixamo_import.gd changes.

const FOLDER := "res://assets/mixamo/"
const RIG := "res://assets/mixamo/Breathing Idle.fbx"
const LIBRARY_PATH := "res://assets/mixamo/y_bot_animations.res"
const SCENE_PATH := "res://assets/mixamo/y_bot.tscn"
# The rig faces +Z; Godot forward is -Z, so the scene turns it 180 degrees
# once, here, and look_at() works everywhere downstream.
const IMPORT_SCRIPT := "res://assets/mixamo/mixamo_import.gd"
const RIG_UID := "uid://btd14bwx3pseq"
# The SCENE's own uid, distinct from the rig's. Written back on every
# rebuild because game/person.tscn references y_bot.tscn BY uid — omit it
# and every reimport prints "invalid UID ... using text path instead" and
# quietly demotes a resolved reference to a string match.
const SCENE_UID := "uid://can6b81y2aedd"


func _init() -> void:
	var merged := AnimationLibrary.new()
	var names: PackedStringArray = DirAccess.get_files_at(FOLDER)
	var sources: Array[String] = []
	for file_name in names:
		if file_name.get_extension().to_lower() == "fbx":
			sources.append(file_name)
	sources.sort()

	for file_name in sources:
		_warn_if_unwired(file_name)
		for pair in _animations_in(load(FOLDER + file_name)):
			if merged.has_animation(pair[0]):
				print("COLLISION: two clips named \"%s\"" % pair[0])
				continue
			merged.add_animation(pair[0], pair[1])

	var saved: int = ResourceSaver.save(merged, LIBRARY_PATH)
	if saved != OK:
		print("FAILED saving library: %d" % saved)
		quit()
		return
	print("saved %d clips to %s" % [merged.get_animation_list().size(), LIBRARY_PATH])

	_write_character_scene()
	quit()


# Written as text rather than packed. PackedScene.pack() on an instantiated rig
# serialises the whole mesh inline -- a ten megabyte scene that churns in git
# every rebuild. An inherited scene referencing the .fbx is a few hundred bytes
# and stays correct when the import is redone.
func _write_character_scene() -> void:
	var text := """[gd_scene load_steps=3 format=3 uid="%s"]

[ext_resource type="PackedScene" uid="%s" path="%s" id="1_rig"]
[ext_resource type="AnimationLibrary" path="%s" id="2_anims"]

[node name="YBot" instance=ExtResource("1_rig")]
transform = Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0)

[node name="AnimationPlayer" parent="." index="1"]
libraries = {
"": ExtResource("2_anims")
}
""" % [SCENE_UID, RIG_UID, RIG, LIBRARY_PATH]
	var handle := FileAccess.open(SCENE_PATH, FileAccess.WRITE)
	if handle == null:
		print("FAILED opening %s" % SCENE_PATH)
		return
	handle.store_string(text)
	handle.close()
	print("wrote character scene to %s" % SCENE_PATH)


# Deleting a .fbx.import makes Godot regenerate it with DEFAULTS -- plain
# scene, no import script -- so the clip silently keeps its raw "mixamo_com"
# name and the merged library quietly grows a stranger. Say so by name.
func _warn_if_unwired(file_name: String) -> void:
	var config := ConfigFile.new()
	if config.load(FOLDER + file_name + ".import") != OK:
		print("UNWIRED: %s has no .import file" % file_name)
		return
	var script_path: String = str(config.get_value("params", "import_script/path", ""))
	if script_path != IMPORT_SCRIPT:
		print("UNWIRED: %s is not using %s -- rewrite its .import" % [
			file_name, IMPORT_SCRIPT])


func _animations_in(loaded: Resource) -> Array:
	var library: AnimationLibrary = null
	if loaded is AnimationLibrary:
		library = loaded
	elif loaded is PackedScene:
		var scene: Node = (loaded as PackedScene).instantiate()
		var player: AnimationPlayer = _find_animation_player(scene)
		if player != null:
			library = player.get_animation_library("")
		scene.queue_free()
	if library == null:
		return []
	var pairs: Array = []
	for clip_name in library.get_animation_list():
		pairs.append([clip_name, library.get_animation(clip_name).duplicate(true)])
	return pairs


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null
