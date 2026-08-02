extends SceneTree

# Headless smoke test for board/hex.gd and board/hex_map.gd — pure data/logic,
# no scene to load, so this just runs assertions and prints PASS/FAIL lines.
# Usage: godot --headless --path tkyds-game --script res://tests/board_smoke.gd

var _failures: Array[String] = []


func _initialize() -> void:
	_check_distance_symmetry_and_triangle_inequality()
	_check_neighbors_of()
	_check_ring_around()
	_check_hexes_within()
	_check_world_position_round_trip()
	_check_hex_map_round_trips()

	print("")
	if _failures.is_empty():
		print("=== BOARD SMOKE PASS ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== BOARD SMOKE FAIL ===")
		quit(1)


func _check_distance_symmetry_and_triangle_inequality() -> void:
	var samples: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(3, -2), Vector2i(-4, 1), Vector2i(5, 5), Vector2i(-3, -3), Vector2i(0, 7),
	]
	for a in samples:
		for b in samples:
			var ab := Hex.distance_between(a, b)
			var ba := Hex.distance_between(b, a)
			_expect(ab == ba, "distance_between should be symmetric: %s <-> %s (%d vs %d)" % [a, b, ab, ba])
			for c in samples:
				var ac := Hex.distance_between(a, c)
				var cb := Hex.distance_between(c, b)
				_expect(ab <= ac + cb, "triangle inequality should hold: %s->%s (%d) via %s (%d + %d)" % [a, b, ab, c, ac, cb])
	_expect(Hex.distance_between(Vector2i(0, 0), Vector2i(0, 0)) == 0, "distance from a hex to itself should be 0")


func _check_neighbors_of() -> void:
	var center := Vector2i(2, -1)
	var neighbors := Hex.neighbors_of(center)
	_expect(neighbors.size() == 6, "neighbors_of should return 6 hexes, got %d" % neighbors.size())

	var seen := {}
	for n in neighbors:
		seen[n] = true
		_expect(Hex.distance_between(center, n) == 1, "neighbor %s should be at distance 1 from %s" % [n, center])
	_expect(seen.size() == 6, "neighbors_of should return 6 distinct hexes, got %d distinct" % seen.size())


func _check_ring_around() -> void:
	var center := Vector2i(-1, 4)
	for radius in range(1, 5):
		var ring := Hex.ring_around(center, radius)
		_expect(ring.size() == 6 * radius, "ring_around(%d) should have %d hexes, got %d" % [radius, 6 * radius, ring.size()])
		for h in ring:
			_expect(Hex.distance_between(center, h) == radius, "ring_around(%d) hex %s should be at distance %d, got %d" % [radius, h, radius, Hex.distance_between(center, h)])

	var ring0 := Hex.ring_around(center, 0)
	_expect(ring0.size() == 1 and ring0[0] == center, "ring_around(0) should be just the center")


func _check_hexes_within() -> void:
	var center := Vector2i(3, 3)
	for radius in range(0, 5):
		var disc := Hex.hexes_within(center, radius)
		var expected_count := 1 + 3 * radius * (radius + 1)
		_expect(disc.size() == expected_count, "hexes_within(%d) should have %d hexes, got %d" % [radius, expected_count, disc.size()])
		var seen := {}
		for h in disc:
			seen[h] = true
			_expect(Hex.distance_between(center, h) <= radius, "hexes_within(%d) hex %s should be within radius" % [radius, h])
		_expect(seen.size() == disc.size(), "hexes_within(%d) should have no duplicate hexes" % radius)
		_expect(disc.has(center), "hexes_within(%d) should include the center" % radius)


func _check_world_position_round_trip() -> void:
	var hex_size := 24.0
	for q in range(-4, 5):
		for r in range(-4, 5):
			var hex := Vector2i(q, r)
			var world := Hex.world_position_of(hex, hex_size)
			var back := Hex.hex_at_world(world, hex_size)
			_expect(back == hex, "world round-trip should return %s, got %s (via %s)" % [hex, back, world])


func _check_hex_map_round_trips() -> void:
	var map := HexMap.new()
	var hex := Vector2i(1, -2)

	_expect(not map.has_hex(hex), "an unclaimed hex should report has_hex() == false")
	map.claim_hex(hex)
	_expect(map.has_hex(hex), "a claimed hex should report has_hex() == true")

	map.set_elevation(hex, 0.75)
	_expect(is_equal_approx(map.elevation_at(hex), 0.75), "elevation_at should read back what set_elevation wrote")

	map.set_water(hex, HexMap.Water.RIVER)
	_expect(map.water_at(hex) == HexMap.Water.RIVER, "water_at should read back what set_water wrote")

	map.set_biome(hex, HexMap.Biome.HILLS)
	_expect(map.biome_at(hex) == HexMap.Biome.HILLS, "biome_at should read back what set_biome wrote")

	map.set_flow_direction(hex, Vector2i(1, -1))
	_expect(map.flow_direction_at(hex) == Vector2i(1, -1), "flow_direction_at should read back what set_flow_direction wrote")

	map.add_tag(hex, "riverbank")
	map.add_tag(hex, "riverbank")  # duplicate add should not double up
	map.add_tag(hex, "fertile")
	var tags := map.tags_at(hex)
	_expect(tags.size() == 2, "tags_at should have 2 distinct tags after two adds and one duplicate, got %d" % tags.size())
	_expect(tags.has("riverbank") and tags.has("fertile"), "tags_at should contain every tag that was added")

	_expect(map.all_hexes().size() == 1, "all_hexes should report exactly the 1 claimed hex, got %d" % map.all_hexes().size())

	map.claim_hex(hex)  # re-claiming should be a no-op, not reset fields
	_expect(map.biome_at(hex) == HexMap.Biome.HILLS, "re-claiming an already-claimed hex should not reset its fields")


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)
