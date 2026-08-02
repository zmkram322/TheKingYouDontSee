extends SceneTree

# Headless smoke test for the town scene: loads it, checks the two TileMapLayer
# nodes actually painted cells, checks the player exists, then drives the player
# via velocity toward the world-edge tree ring and asserts it gets stopped by
# collision rather than walking off the map.
# Usage: godot --headless --path tkyds-game --script res://tests/town_smoke.gd

const TILE_SIZE := 16
const DRIVE_FRAMES := 240
const FRAME_DELTA := 1.0 / 60.0

var _failures: Array[String] = []


func _initialize() -> void:
	var town_scene: PackedScene = load("res://town/town.tscn")
	var town := town_scene.instantiate() as Node2D
	root.add_child(town)

	# NOTIFICATION_READY (and physics-server sync for the freshly-added
	# collision shapes) is queued, not immediate — wait a couple of real
	# frames so town.gd's _ready() has actually run before we inspect it.
	for i in range(2):
		await process_frame

	var ground_layer := town.get_node_or_null("GroundLayer") as TileMapLayer
	var props_layer := town.get_node_or_null("World/PropsLayer") as TileMapLayer
	_expect(ground_layer != null, "GroundLayer TileMapLayer should exist")
	_expect(props_layer != null, "PropsLayer TileMapLayer should exist")
	if ground_layer:
		_expect(ground_layer.get_used_cells().size() > 0, "GroundLayer should have painted cells")
	if props_layer:
		_expect(props_layer.get_used_cells().size() > 0, "PropsLayer should have painted cells")

	var player := town.get_node_or_null("World/Player") as CharacterBody2D
	_expect(player != null, "Player node should exist under World")

	if player:
		_expect(player.position != Vector2.ZERO, "Player should be spawned at a real position, not the origin")
		var start_position := player.position

		# Drive the player straight up (toward the world-edge tree ring) for a
		# long time and confirm it actually moved, then confirm it got stopped
		# well short of walking through the border.
		for i in range(DRIVE_FRAMES):
			player.velocity = Vector2(0, -player.MOVE_SPEED)
			player.move_and_slide()

		_expect(player.position != start_position, "Player should have moved when driven with velocity")
		_expect(player.position.y > TILE_SIZE * 0.5, "Player should be stopped by the border collision, not pushed past tile row 0")

	print("")
	if _failures.is_empty():
		print("=== TOWN SMOKE PASS ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== TOWN SMOKE FAIL ===")
		quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)
