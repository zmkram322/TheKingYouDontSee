extends SceneTree

# Headless smoke test for board/settlement_placer.gd — pure data/logic, no
# scene to load, so this just runs assertions and prints PASS/FAIL lines (same
# convention as tests/board_smoke.gd).
# Usage: godot --headless --path tkyds-game --script res://tests/placement_smoke.gd

const KINGDOM_RADIUS := 24
const KINGDOM_SEEDS: Array[int] = [11, 202, 3033]
const BAND_SEEDS: Array[int] = [11, 202, 3033, 44444, 5]

var _failures: Array[String] = []


func _initialize() -> void:
	_check_determinism()
	_check_every_site_is_a_valid_candidate()
	_check_pairwise_spacing()
	_check_exactly_one_town_and_size_ranking()
	_check_wealth_bounds_and_town_max()
	_check_plan_size_band()
	_check_layout_seed_stability_and_uniqueness()

	print("")
	if _failures.is_empty():
		print("=== PLACEMENT SMOKE PASS ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== PLACEMENT SMOKE FAIL ===")
		quit(1)


func _check_determinism() -> void:
	var any_difference := false
	for kingdom_seed in KINGDOM_SEEDS:
		var map := TerrainGenerator.generate_kingdom_with_overrides(kingdom_seed, {"radius": KINGDOM_RADIUS})
		var plan_a := SettlementPlacer.plan_settlements(map, 111)
		var plan_b := SettlementPlacer.plan_settlements(map, 111)
		_expect(_signature_of(plan_a) == _signature_of(plan_b), "kingdom seed %d: same plan seed twice should produce identical plans" % kingdom_seed)

		var plan_c := SettlementPlacer.plan_settlements(map, 222)
		if _signature_of(plan_a) != _signature_of(plan_c):
			any_difference = true

	_expect(any_difference, "a different plan seed should produce some difference in at least one tested kingdom")


func _check_every_site_is_a_valid_candidate() -> void:
	for kingdom_seed in KINGDOM_SEEDS:
		var map := TerrainGenerator.generate_kingdom_with_overrides(kingdom_seed, {"radius": KINGDOM_RADIUS})
		var plan := SettlementPlacer.plan_settlements(map, 1)
		for entry: Dictionary in plan:
			var hex: Vector2i = entry["hex"]
			_expect(map.biome_at(hex) == HexMap.Biome.PLAINS, "kingdom seed %d: planned hex %s should be PLAINS, got %d" % [kingdom_seed, hex, map.biome_at(hex)])
			_expect(_has_fresh_water_neighbor(map, hex), "kingdom seed %d: planned hex %s should have a RIVER/LAKE neighbor" % [kingdom_seed, hex])


func _check_pairwise_spacing() -> void:
	for kingdom_seed in KINGDOM_SEEDS:
		var map := TerrainGenerator.generate_kingdom_with_overrides(kingdom_seed, {"radius": KINGDOM_RADIUS})
		var plan := SettlementPlacer.plan_settlements(map, 1)
		for i in range(plan.size()):
			for j in range(i + 1, plan.size()):
				var hex_a: Vector2i = plan[i]["hex"]
				var hex_b: Vector2i = plan[j]["hex"]
				var distance := Hex.distance_between(hex_a, hex_b)
				_expect(distance >= SettlementPlacer.MIN_SETTLEMENT_SPACING, "kingdom seed %d: sites %s and %s should be >= %d apart, got %d" % [kingdom_seed, hex_a, hex_b, SettlementPlacer.MIN_SETTLEMENT_SPACING, distance])


func _check_exactly_one_town_and_size_ranking() -> void:
	for kingdom_seed in KINGDOM_SEEDS:
		var map := TerrainGenerator.generate_kingdom_with_overrides(kingdom_seed, {"radius": KINGDOM_RADIUS})
		var plan := SettlementPlacer.plan_settlements(map, 1)
		if plan.is_empty():
			continue

		var town_count := 0
		var town_score := -1
		var village_scores: Array[int] = []
		var hamlet_scores: Array[int] = []
		for entry: Dictionary in plan:
			var hex: Vector2i = entry["hex"]
			var size: int = entry["size"]
			var score: int = _score_of(map, hex)
			match size:
				SettlementGenerator.SettlementSize.TOWN:
					town_count += 1
					town_score = score
				SettlementGenerator.SettlementSize.VILLAGE:
					village_scores.append(score)
				SettlementGenerator.SettlementSize.HAMLET:
					hamlet_scores.append(score)

		_expect(town_count == 1, "kingdom seed %d: plan should have exactly one TOWN, found %d" % [kingdom_seed, town_count])

		for village_score in village_scores:
			_expect(town_score >= village_score, "kingdom seed %d: TOWN score %d should be >= VILLAGE score %d" % [kingdom_seed, town_score, village_score])
		for hamlet_score in hamlet_scores:
			for village_score in village_scores:
				_expect(village_score >= hamlet_score, "kingdom seed %d: VILLAGE score %d should be >= HAMLET score %d (no HAMLET outranks a VILLAGE)" % [kingdom_seed, village_score, hamlet_score])
			_expect(town_score >= hamlet_score, "kingdom seed %d: TOWN score %d should be >= HAMLET score %d" % [kingdom_seed, town_score, hamlet_score])


func _check_wealth_bounds_and_town_max() -> void:
	for kingdom_seed in KINGDOM_SEEDS:
		var map := TerrainGenerator.generate_kingdom_with_overrides(kingdom_seed, {"radius": KINGDOM_RADIUS})
		var plan := SettlementPlacer.plan_settlements(map, 1)
		if plan.is_empty():
			continue

		var max_wealth: float = -1.0
		var town_wealth: float = -1.0
		for entry: Dictionary in plan:
			var wealth: float = entry["wealth"]
			_expect(wealth >= SettlementPlacer.WEALTH_FLOOR and wealth <= SettlementPlacer.WEALTH_CEILING, "kingdom seed %d: wealth %f for %s should be within [%f, %f]" % [kingdom_seed, wealth, entry["hex"], SettlementPlacer.WEALTH_FLOOR, SettlementPlacer.WEALTH_CEILING])
			if wealth > max_wealth:
				max_wealth = wealth
			if int(entry["size"]) == SettlementGenerator.SettlementSize.TOWN:
				town_wealth = wealth

		_expect(is_equal_approx(town_wealth, max_wealth), "kingdom seed %d: TOWN wealth (%f) should equal the plan's max wealth (%f)" % [kingdom_seed, town_wealth, max_wealth])


func _check_plan_size_band() -> void:
	for kingdom_seed in BAND_SEEDS:
		var map := TerrainGenerator.generate_kingdom(kingdom_seed)  # default radius (24) and default dial
		var plan := SettlementPlacer.plan_settlements(map, 1)
		_expect(not plan.is_empty(), "kingdom seed %d: default-dial radius-24 plan should be non-empty" % kingdom_seed)
		_expect(plan.size() >= 1 and plan.size() <= 30, "kingdom seed %d: plan size %d should fall within the sane band 1..30" % [kingdom_seed, plan.size()])


func _check_layout_seed_stability_and_uniqueness() -> void:
	for kingdom_seed in KINGDOM_SEEDS:
		var map := TerrainGenerator.generate_kingdom_with_overrides(kingdom_seed, {"radius": KINGDOM_RADIUS})
		var plan_a := SettlementPlacer.plan_settlements(map, 77)
		var plan_b := SettlementPlacer.plan_settlements(map, 77)

		var seeds_a: Dictionary = {}
		for entry: Dictionary in plan_a:
			seeds_a[entry["hex"]] = entry["layout_seed"]
		for entry: Dictionary in plan_b:
			var hex: Vector2i = entry["hex"]
			_expect(seeds_a.has(hex) and int(seeds_a[hex]) == int(entry["layout_seed"]), "kingdom seed %d: layout_seed for %s should be stable across two plans of the same inputs" % [kingdom_seed, hex])

		if plan_a.size() >= 2:
			var distinct_seeds: Dictionary = {}
			for entry: Dictionary in plan_a:
				distinct_seeds[int(entry["layout_seed"])] = true
			_expect(distinct_seeds.size() == plan_a.size(), "kingdom seed %d: layout_seed should differ between different sites in one plan (%d distinct among %d sites)" % [kingdom_seed, distinct_seeds.size(), plan_a.size()])


# --- Local reimplementations, kept independent of settlement_placer.gd's
# private helpers so this test verifies the observable outcome, not the
# internal mechanism (same discipline as tests/terrain_smoke.gd). Reuses the
# placer's public tunable constants (SCORE_RADIUS, FAMILY_WEIGHT) since those
# are the documented tuning surface, not internal mechanism. ---

const _FAMILY_TAGS := {
	"grain": ["can_grow_grain"],
	"lumber": ["can_cut_lumber"],
	"mineral": ["can_mine_ore", "can_quarry_stone"],
	"fish": ["can_fish"],
}


func _score_of(map: HexMap, hex: Vector2i) -> int:
	var family_counts: Dictionary = {}
	for family: String in _FAMILY_TAGS:
		family_counts[family] = 0

	for nearby: Vector2i in Hex.hexes_within(hex, SettlementPlacer.SCORE_RADIUS):
		if not map.has_hex(nearby):
			continue
		var tags: PackedStringArray = map.tags_at(nearby)
		for family: String in _FAMILY_TAGS:
			var family_tags: Array = _FAMILY_TAGS[family]
			for tag: String in family_tags:
				if tags.has(tag):
					family_counts[family] = int(family_counts[family]) + 1
					break

	var distinct_families := 0
	var total_tagged := 0
	for family: String in family_counts:
		var count: int = int(family_counts[family])
		if count > 0:
			distinct_families += 1
		total_tagged += count

	return distinct_families * SettlementPlacer.FAMILY_WEIGHT + total_tagged


func _has_fresh_water_neighbor(map: HexMap, hex: Vector2i) -> bool:
	for neighbor: Vector2i in Hex.neighbors_of(hex):
		if not map.has_hex(neighbor):
			continue
		var water: HexMap.Water = map.water_at(neighbor)
		if water == HexMap.Water.RIVER or water == HexMap.Water.LAKE:
			return true
	return false


func _signature_of(plan: Array[Dictionary]) -> String:
	var entries: Array[Dictionary] = plan.duplicate()
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var hex_a: Vector2i = a["hex"]
		var hex_b: Vector2i = b["hex"]
		if hex_a.x != hex_b.x:
			return hex_a.x < hex_b.x
		return hex_a.y < hex_b.y
	)
	var parts: Array[String] = []
	for entry: Dictionary in entries:
		parts.append("%s:%d:%.6f:%d" % [entry["hex"], entry["size"], entry["wealth"], entry["layout_seed"]])
	return ",".join(parts)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)
