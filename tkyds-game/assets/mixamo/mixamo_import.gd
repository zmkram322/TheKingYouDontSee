@tool
extends EditorScenePostImport

# Runs on every reimport of a Mixamo .fbx. Mixamo hands us four problems and
# this is the one place all four are answered:
#
#   1. Every clip is named "mixamo_com" (Godot sanitizes Mixamo's "mixamo.com").
#   2. Every file carries a second clip, "Take 001", holding no motion at all.
#   3. Loop mode always imports as none, so an idle hitches once per cycle.
#   4. Locomotion downloaded WITHOUT "In Place" drags the Hips forward, off the
#      CharacterBody3D the brain is steering.
#
# GOTCHA: Godot tracks import_script/path but NOT this script's contents, so
# editing the table below does not invalidate the import cache and a reimport
# is a silent no-op. Force it:
#
#   sed -i '/^uid=/d; /^path=/d; /^dest_files=/d; /^importer_version=/d' assets/mixamo/*.fbx.import
#
# then run the editor import pass, then assets/mixamo/build_character.gd.
#
# Keyed by source filename so the mapping is readable next to the files it
# describes. A file missing from the table still imports -- it just keeps the
# raw clip name, which shows up as "mixamo_com" and is meant to be noticed.

const RAW_CLIP := "mixamo_com"
const EMPTY_TAKE := "Take 001"

# clip_name, loops, holds_position
#   holds_position = true strips horizontal Hips travel, standing in for the
#   "In Place" checkbox nobody ticked on mixamo.com.
const CLIPS := {
	"Breathing Idle.fbx": ["idle", true, false],
	"Walking.fbx": ["walk", true, true],
	"Running.fbx": ["run", true, true],
	"Run Backward.fbx": ["run_back", true, true],
	"Left Strafe Walking.fbx": ["strafe_left", true, true],
	"Right Strafe Walking.fbx": ["strafe_right", true, true],
	"Walking Backwards.fbx": ["walk_back", true, true],
	"Walking Turn 180.fbx": ["turn_walk", false, true],
	"Running Turn 180.fbx": ["turn_run", false, true],
	"Sitting.fbx": ["sit", true, false],
	"Stand Up-From-Sitting.fbx": ["stand_up", false, true],
	"Sleeping Idle.fbx": ["sleep", true, false],
	"Drinking.fbx": ["drink", false, false],
	"Sitting Drinking.fbx": ["sit_drink", true, true],
	"Picking Up-Working-Field.fbx": ["work_field", true, false],
	"Waving-Get-Attention.fbx": ["beckon", false, false],
	"Waving-Neutral-Wave.fbx": ["greet", false, false],
	"Waving-Nice-Wave.fbx": ["greet_warm", false, false],
	"Frisbee Throw.fbx": ["hand_over", false, true],
	"Jumping.fbx": ["jump", false, true],
	"Jumping Down.fbx": ["jump_down", false, true],
	"Running Jump.fbx": ["run_jump", false, true],
	# --- Added 2026-08-21 for the exchanges workbench. These are not
	# locomotion: they are the vocabulary of an ASK and an ANSWER — assent,
	# refusal, and the gestures that point one person at another. All seven
	# hold position because every one of them is performed standing still.
	"Head Nod Yes.fbx": ["nod", false, true],
	"Hard Head Nod.fbx": ["nod_hard", false, true],
	"Shaking Head No.fbx": ["shake_head", false, true],
	"Annoyed Head Shake.fbx": ["shake_head_annoyed", false, true],
	"Pointing.fbx": ["point", false, true],
	"Clapping.fbx": ["clap", true, true],
	"Cheering.fbx": ["cheer", true, true],
	"Quick Formal Bow.fbx": ["bow", false, true],
	"Shaking Hands 2.fbx": ["handshake", false, true],
	"Shake Fist.fbx": ["shake_fist", false, true],
	# --- Added 2026-08-30 for the exchanges workbench. Reaching into a
	# container and coming away with what was in it. Holds position for the
	# same reason every gesture above does: he performs it standing still,
	# and any Hips travel in the download would drag him off the body the
	# brain is steering.
	"Taking Item.fbx": ["take_item", false, true],
}


func _post_import(scene: Node) -> Object:
	var source_name: String = get_source_file().get_file()
	var player: AnimationPlayer = _find_animation_player(scene)
	if player == null:
		push_warning("Mixamo import: %s has no AnimationPlayer." % source_name)
		return scene

	var library: AnimationLibrary = player.get_animation_library("")
	if library == null:
		push_warning("Mixamo import: %s has no default animation library." % source_name)
		return scene

	if library.has_animation(EMPTY_TAKE):
		library.remove_animation(EMPTY_TAKE)

	if not CLIPS.has(source_name):
		push_warning("Mixamo import: %s is not in the CLIPS table." % source_name)
		return scene

	var settings: Array = CLIPS[source_name]
	var clip_name: String = settings[0]
	var loops: bool = settings[1]
	var holds_position: bool = settings[2]

	if not library.has_animation(RAW_CLIP):
		push_warning("Mixamo import: %s has no \"%s\" clip." % [source_name, RAW_CLIP])
		return scene

	var animation: Animation = library.get_animation(RAW_CLIP)
	animation.loop_mode = Animation.LOOP_LINEAR if loops else Animation.LOOP_NONE
	if holds_position:
		_hold_hips_in_place(animation)

	library.remove_animation(RAW_CLIP)
	library.add_animation(clip_name, animation)
	return scene


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null


# Pins the Hips over the origin horizontally while leaving the vertical bob
# alone -- a walk still rises and falls, it just no longer travels.
func _hold_hips_in_place(animation: Animation) -> void:
	for track in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_POSITION_3D:
			continue
		if not str(animation.track_get_path(track)).ends_with("Hips"):
			continue
		for key in animation.track_get_key_count(track):
			var position: Vector3 = animation.track_get_key_value(track, key)
			animation.track_set_key_value(track, key, Vector3(0.0, position.y, 0.0))
