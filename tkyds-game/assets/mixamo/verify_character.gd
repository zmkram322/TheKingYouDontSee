extends SceneTree

# Temporary. Loads the built character the way the game will and checks three
# things that all fail SILENTLY: that every clip is addressable by bare name,
# that the rig faces Godot's forward, and that playing a clip actually moves
# a bone -- a library bound to a mismatched skeleton plays happily and does
# nothing at all.

const SCENE := "res://assets/mixamo/y_bot.tscn"

const EXPECTED := [
	"idle", "walk", "run", "run_back", "strafe_left", "strafe_right", "walk_back",
	"turn_walk", "turn_run", "sit", "stand_up", "sleep", "drink",
	"sit_drink", "work_field", "beckon", "greet", "greet_warm",
	"hand_over", "jump", "jump_down", "run_jump",
]

var _failures := 0


func _init() -> void:
	var character: Node3D = (load(SCENE) as PackedScene).instantiate()
	root.add_child(character)

	var player: AnimationPlayer = _find_animation_player(character)
	var skeleton: Skeleton3D = _find_skeleton(character)
	_check(player != null, "character has an AnimationPlayer")
	_check(skeleton != null, "character has a Skeleton3D")
	if player == null or skeleton == null:
		_finish()
		return

	var present: PackedStringArray = player.get_animation_list()
	_check(present.size() == EXPECTED.size(),
		"holds %d clips (found %d)" % [EXPECTED.size(), present.size()])
	for clip_name in EXPECTED:
		_check(player.has_animation(clip_name), "clip \"%s\" is addressable" % clip_name)

	var facing: Vector3 = -character.transform.basis.z
	_check(facing.z > 0.9,
		"rig faces Godot forward (-Z basis points %s)" % facing.snapped(Vector3.ONE * 0.01))

	var bone: int = skeleton.find_bone("mixamorig_LeftLeg")
	_check(bone != -1, "skeleton has mixamorig_LeftLeg")
	if bone != -1:
		player.play("walk")
		player.advance(0.0)
		var at_start: Quaternion = skeleton.get_bone_pose_rotation(bone)
		player.advance(0.5)
		var mid_stride: Quaternion = skeleton.get_bone_pose_rotation(bone)
		var swing: float = rad_to_deg(at_start.angle_to(mid_stride))
		_check(swing > 5.0, "playing \"walk\" swings the left leg (%.1f deg)" % swing)

	_finish()


func _check(passed: bool, claim: String) -> void:
	if passed:
		print("  ok   %s" % claim)
	else:
		print("  FAIL %s" % claim)
		_failures += 1


func _finish() -> void:
	print("")
	print("FAILED (%d)" % _failures if _failures > 0 else "ALL GREEN")
	quit(1 if _failures > 0 else 0)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null:
			return found
	return null
