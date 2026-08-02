extends SceneTree

# Headless smoke test for board/terrain_generator.gd — pure data/logic, no
# scene to load, so this just runs assertions and prints PASS/FAIL lines.
# Usage: godot --headless --path tkyds-game --script res://tests/terrain_smoke.gd

const TEST_RADIUS := 14

# A kingdom this small starves biome diversity often enough that the natural
# (dial=0) mix around a settlement candidate frequently comes up short —
# exactly the condition that should force the dial=1 nudge pass to fire.
const SMALL_RADIUS := 6
# Generous, fixed check radius for the nudge-firing probe: bigger than the
# generator's own internal dial-scaled search radius ever gets (max 9), so
# "satisfied at this radius" is a safe superset of "satisfied at whatever
# radius the generator actually used internally."
const MIX_CHECK_RADIUS := 12

var _failures: Array[String] = []


func _initialize() -> void:
	_check_determinism()

	var default_map := TerrainGenerator.generate_kingdom_with_overrides(303, {"radius": TEST_RADIUS})
	_check_core_invariants(default_map, TEST_RADIUS, "default dial")
	_check_has_rivers(default_map, "default dial")

	_check_dial_behavior()
	_check_nudge_pass_fires()

	print("")
	if _failures.is_empty():
		print("=== TERRAIN SMOKE PASS ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== TERRAIN SMOKE FAIL ===")
		quit(1)


func _check_determinism() -> void:
	var map_a := TerrainGenerator.generate_kingdom_with_overrides(1234, {"radius": TEST_RADIUS})
	var map_b := TerrainGenerator.generate_kingdom_with_overrides(1234, {"radius": TEST_RADIUS})

	_expect(map_a.all_hexes().size() == map_b.all_hexes().size(), "same seed should claim the same number of hexes")

	var identical := true
	for hex in map_a.all_hexes():
		if not map_b.has_hex(hex):
			identical = false
			break
		if not is_equal_approx(map_a.elevation_at(hex), map_b.elevation_at(hex)):
			identical = false
			break
		if map_a.water_at(hex) != map_b.water_at(hex):
			identical = false
			break
		if map_a.biome_at(hex) != map_b.biome_at(hex):
			identical = false
			break
		if map_a.flow_direction_at(hex) != map_b.flow_direction_at(hex):
			identical = false
			break
		if map_a.tags_at(hex) != map_b.tags_at(hex):
			identical = false
			break
	_expect(identical, "same seed should produce byte-identical HexMap contents in all five fields")

	var map_c := TerrainGenerator.generate_kingdom_with_overrides(9999, {"radius": TEST_RADIUS})
	var any_difference := false
	for hex in map_a.all_hexes():
		if map_c.has_hex(hex) and not is_equal_approx(map_a.elevation_at(hex), map_c.elevation_at(hex)):
			any_difference = true
			break
	_expect(any_difference, "a different seed should produce at least one different elevation value")


func _check_dial_behavior() -> void:
	var map_full_dial := TerrainGenerator.generate_kingdom_with_overrides(2026, {"radius": TEST_RADIUS, "dial": 1.0})
	_check_core_invariants(map_full_dial, TEST_RADIUS, "dial 1.0")
	_check_has_rivers(map_full_dial, "dial 1.0")

	var candidates := _settlement_candidates(map_full_dial)
	_expect(not candidates.is_empty(), "dial=1.0 should leave at least one PLAINS-near-fresh-water candidate site")

	var satisfied := false
	for site in candidates:
		if _has_coherent_mix(map_full_dial, site, TEST_RADIUS):
			satisfied = true
			break
	_expect(satisfied, "dial=1.0 should guarantee a coherent resource mix (grain+lumber+ore-or-stone) near at least one candidate site")

	var map_zero_dial := TerrainGenerator.generate_kingdom_with_overrides(2026, {"radius": TEST_RADIUS, "dial": 0.0})
	_expect(map_zero_dial.all_hexes().size() == map_full_dial.all_hexes().size(), "dial=0.0 should still complete generation with the full hex count")
	_check_core_invariants(map_zero_dial, TEST_RADIUS, "dial 0.0")
	_check_has_rivers(map_zero_dial, "dial 0.0")


# Proves the nudge pass actually runs, rather than just asserting outcomes a
# lucky seed could satisfy on its own: shrink the kingdom so biome diversity
# is scarce, generate the SAME seed at dial 0 and dial 1, and look for at
# least one seed where the natural (dial=0) map has no candidate site with a
# coherent mix but the dial=1 map does. That transition can only happen if
# the nudge pass fired and changed the map. Every dial=1 probe map generated
# along the way also gets the full invariant sweep, at the radius it was
# actually built with — this is the scenario FIX 1/FIX 2 were about, so it's
# the one that has to stay green.
func _check_nudge_pass_fires() -> void:
	var fired := false
	for seed in range(1, 26):
		var natural_map := TerrainGenerator.generate_kingdom_with_overrides(seed, {"radius": SMALL_RADIUS, "dial": 0.0})
		var nudged_map := TerrainGenerator.generate_kingdom_with_overrides(seed, {"radius": SMALL_RADIUS, "dial": 1.0})

		_check_core_invariants(nudged_map, SMALL_RADIUS, "nudge-probe seed %d dial 1.0" % seed)

		var natural_satisfied := _any_candidate_has_mix(natural_map, MIX_CHECK_RADIUS)
		var nudged_satisfied := _any_candidate_has_mix(nudged_map, MIX_CHECK_RADIUS)
		if not natural_satisfied and nudged_satisfied:
			fired = true

	_expect(fired, "at least one small-radius seed should show dial=1.0 turning an unsatisfied natural mix into a satisfied one (proves the nudge pass fired, not just a lucky roll)")


func _any_candidate_has_mix(map: HexMap, radius: int) -> bool:
	for site in _settlement_candidates(map):
		if _has_coherent_mix(map, site, radius):
			return true
	return false


# Flow sanity + river termination + ocean ring + biome/tag gating, run
# together against one generated map so every dial/seed combination we
# exercise gets the full invariant sweep.
func _check_core_invariants(map: HexMap, radius: int, label: String) -> void:
	_check_flow_sanity(map, label)
	_check_river_termination(map, label)
	_check_ocean_ring(map, radius, label)
	_check_biome_tag_gating(map, label)


func _check_flow_sanity(map: HexMap, label: String) -> void:
	for hex in map.all_hexes():
		if map.biome_at(hex) == HexMap.Biome.OCEAN:
			continue
		var direction: Vector2i = map.flow_direction_at(hex)
		if direction != Vector2i.ZERO:
			var target := hex + direction
			_expect(map.has_hex(target), "[%s] flow target %s of %s should be a claimed hex" % [label, target, hex])
			if map.has_hex(target):
				_expect(map.elevation_at(target) < map.elevation_at(hex), "[%s] flow from %s (%f) should go to a strictly lower neighbor, got %s (%f)" % [label, hex, map.elevation_at(hex), target, map.elevation_at(target)])
		else:
			var has_lower_neighbor := false
			for neighbor in Hex.neighbors_of(hex):
				if map.has_hex(neighbor) and map.elevation_at(neighbor) < map.elevation_at(hex):
					has_lower_neighbor = true
					break
			_expect(not has_lower_neighbor, "[%s] flow_direction ZERO at %s should mean no strictly-lower neighbor exists" % [label, hex])
			_expect(map.water_at(hex) == HexMap.Water.LAKE, "[%s] a land pit with ZERO flow should be marked LAKE, got %s at %s" % [label, map.water_at(hex), hex])


# Terminates every RIVER hex's flow chain at SEA/LAKE. Deliberately does NOT
# assert a river exists at all — that's not a stated invariant, and small
# kingdoms (the nudge-firing probe uses SMALL_RADIUS) may have watersheds too
# small to ever cross RIVER_ACCUMULATION_THRESHOLD. Vacuously true when there
# are no rivers, which is correct: nothing to terminate, nothing to check.
# _check_has_rivers below asserts existence separately, only where the
# kingdom is big enough to make that a meaningful expectation.
func _check_river_termination(map: HexMap, label: String) -> void:
	var hex_count := map.all_hexes().size()
	var river_hexes: Array[Vector2i] = []
	for hex in map.all_hexes():
		if map.water_at(hex) == HexMap.Water.RIVER:
			river_hexes.append(hex)

	for start in river_hexes:
		var current := start
		var steps := 0
		var reached_terminus := false
		while steps <= hex_count:
			var water := map.water_at(current)
			if water == HexMap.Water.SEA or water == HexMap.Water.LAKE:
				reached_terminus = true
				break
			var direction: Vector2i = map.flow_direction_at(current)
			if direction == Vector2i.ZERO:
				break
			current += direction
			if not map.has_hex(current):
				break
			steps += 1
		_expect(reached_terminus, "[%s] flow from RIVER hex %s should reach SEA or LAKE within %d steps" % [label, start, hex_count])


# Only meaningful at kingdom scale (TEST_RADIUS), where a river network is
# expected to form; SMALL_RADIUS probe kingdoms are deliberately too tiny to
# guarantee that.
func _check_has_rivers(map: HexMap, label: String) -> void:
	var has_river := false
	for hex in map.all_hexes():
		if map.water_at(hex) == HexMap.Water.RIVER:
			has_river = true
			break
	_expect(has_river, "[%s] expected at least one RIVER hex to exist" % label)


func _check_ocean_ring(map: HexMap, radius: int, label: String) -> void:
	var outer_ring := Hex.ring_around(Vector2i.ZERO, radius)
	for hex in outer_ring:
		_expect(map.biome_at(hex) == HexMap.Biome.OCEAN, "[%s] outermost ring hex %s should be OCEAN, got %d" % [label, hex, map.biome_at(hex)])
		_expect(map.water_at(hex) == HexMap.Water.SEA, "[%s] outermost ring hex %s should have water SEA" % [label, hex])


func _check_biome_tag_gating(map: HexMap, label: String) -> void:
	for hex in map.all_hexes():
		var tags := map.tags_at(hex)
		var biome: HexMap.Biome = map.biome_at(hex)
		if biome == HexMap.Biome.OCEAN:
			_expect(tags.size() == 0, "[%s] OCEAN hex %s should have no tags, got %s" % [label, hex, tags])
			continue
		if tags.has("can_mine_ore"):
			_expect(biome == HexMap.Biome.MOUNTAINS, "[%s] can_mine_ore at %s should only appear on MOUNTAINS, got %d" % [label, hex, biome])
		if tags.has("can_quarry_stone"):
			_expect(biome == HexMap.Biome.HILLS or biome == HexMap.Biome.MOUNTAINS, "[%s] can_quarry_stone at %s should only appear on HILLS or MOUNTAINS, got %d" % [label, hex, biome])
		if tags.has("can_cut_lumber"):
			_expect(biome == HexMap.Biome.FOREST, "[%s] can_cut_lumber at %s should only appear on FOREST, got %d" % [label, hex, biome])
		if tags.has("can_grow_grain"):
			_expect(biome == HexMap.Biome.PLAINS, "[%s] can_grow_grain at %s should only appear on PLAINS, got %d" % [label, hex, biome])
			_expect(_adjacent_to_fresh_water(map, hex), "[%s] can_grow_grain at %s should be adjacent to river or lake" % [label, hex])


# --- Local reimplementations of the dial-guarantee query, kept independent
# of terrain_generator.gd's private helpers so this test verifies the
# observable outcome, not the internal mechanism. ---

func _settlement_candidates(map: HexMap) -> Array[Vector2i]:
	var sites: Array[Vector2i] = []
	for hex in map.all_hexes():
		if map.biome_at(hex) == HexMap.Biome.PLAINS and _adjacent_to_fresh_water(map, hex):
			sites.append(hex)
	return sites


func _has_coherent_mix(map: HexMap, site: Vector2i, radius: int) -> bool:
	var has_grain := false
	var has_lumber := false
	var has_mineral := false
	for hex in Hex.hexes_within(site, radius):
		if not map.has_hex(hex):
			continue
		var tags := map.tags_at(hex)
		if tags.has("can_grow_grain"):
			has_grain = true
		if tags.has("can_cut_lumber"):
			has_lumber = true
		if tags.has("can_mine_ore") or tags.has("can_quarry_stone"):
			has_mineral = true
	return has_grain and has_lumber and has_mineral


func _adjacent_to_fresh_water(map: HexMap, hex: Vector2i) -> bool:
	for neighbor in Hex.neighbors_of(hex):
		if map.has_hex(neighbor):
			var water: HexMap.Water = map.water_at(neighbor)
			if water == HexMap.Water.RIVER or water == HexMap.Water.LAKE:
				return true
	return false


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)
