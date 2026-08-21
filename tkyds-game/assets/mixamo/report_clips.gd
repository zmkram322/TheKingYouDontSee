extends SceneTree

# Temporary. Reports what every Mixamo import actually produced: the clip name
# after renaming, its length, whether it loops, and how far the Hips travel
# horizontally across the clip. That last number is the "In Place" check --
# anything above a few centimetres will drag the model off the CharacterBody3D.

const FOLDER := "res://assets/mixamo/"


func _init() -> void:
	var names: PackedStringArray = DirAccess.get_files_at(FOLDER)
	var sources: Array[String] = []
	for file_name in names:
		if file_name.get_extension().to_lower() == "fbx":
			sources.append(file_name)
	sources.sort()

	print("%-30s %-12s %7s %6s %9s %8s" % [
		"source", "clip", "length", "loop", "drift", "turn"])
	print("-".repeat(80))
	for file_name in sources:
		var loaded: Resource = load(FOLDER + file_name)
		if loaded == null:
			print("%-30s LOAD FAILED" % file_name)
			continue
		for entry in _describe(loaded):
			print("%-30s %-12s %6.2fs %6s %8.3fm %5.0f deg" % [
				file_name, entry[0], entry[1], entry[2], entry[3], entry[4]])
	_report_character()
	quit()


# The capsule in person.tscn is 1.7 m tall standing on a root at the feet.
# The rig has to match both numbers or he floats or sinks.
func _report_character() -> void:
	print("")
	print("character scene: Breathing Idle.fbx")
	var packed: PackedScene = load(FOLDER + "Breathing Idle.fbx")
	if packed == null:
		print("  LOAD FAILED")
		return
	var scene: Node = packed.instantiate()
	_print_tree(scene, "  ")
	for node in _every_node(scene):
		if node is MeshInstance3D:
			var box: AABB = (node as MeshInstance3D).get_aabb()
			print("  mesh %s -> height %.3f m, floor at y=%.3f" % [
				node.name, box.size.y, box.position.y])
	scene.queue_free()


func _print_tree(node: Node, indent: String) -> void:
	print("%s%s (%s)" % [indent, node.name, node.get_class()])
	for child in node.get_children():
		_print_tree(child, indent + "  ")


func _every_node(node: Node) -> Array[Node]:
	var found: Array[Node] = [node]
	for child in node.get_children():
		found.append_array(_every_node(child))
	return found


# Returns [clip_name, length, loops, horizontal_drift] per animation, whether
# the file imported as a bare AnimationLibrary or as a Scene carrying one.
func _describe(loaded: Resource) -> Array:
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

	var rows: Array = []
	for clip_name in library.get_animation_list():
		var animation: Animation = library.get_animation(clip_name)
		rows.append([
			clip_name,
			animation.length,
			animation.loop_mode != Animation.LOOP_NONE,
			_measure_horizontal_drift(animation),
			_measure_turn(animation),
		])
	return rows


# Total yaw the Hips sweep across the clip. A run cycle reads near zero; a
# 180-degree turn reads near 180. This is what tells a mislabelled download
# apart from the clip it claims to be.
func _measure_turn(animation: Animation) -> float:
	for track in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_ROTATION_3D:
			continue
		if not str(animation.track_get_path(track)).ends_with("Hips"):
			continue
		var swept := 0.0
		var previous := 0.0
		for step in 60:
			var sampled: Quaternion = animation.rotation_track_interpolate(
				track, animation.length * float(step) / 59.0)
			var yaw: float = sampled.get_euler().y
			if step > 0:
				swept += wrapf(yaw - previous, -PI, PI)
			previous = yaw
		return abs(rad_to_deg(swept))
	return 0.0


func _measure_horizontal_drift(animation: Animation) -> float:
	for track in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_POSITION_3D:
			continue
		if not str(animation.track_get_path(track)).ends_with("Hips"):
			continue
		var lowest := Vector2.ZERO
		var highest := Vector2.ZERO
		var seeded := false
		for step in 40:
			var sampled: Vector3 = animation.position_track_interpolate(
				track, animation.length * float(step) / 39.0)
			var flat := Vector2(sampled.x, sampled.z)
			if not seeded:
				lowest = flat
				highest = flat
				seeded = true
			lowest = lowest.min(flat)
			highest = highest.max(flat)
		return (highest - lowest).length()
	return 0.0


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null
