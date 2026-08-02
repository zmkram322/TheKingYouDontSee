extends SceneTree

# Headless smoke test for board/settlement_template.gd, board/settlement_generator.gd
# and board/settlement_layout.gd — pure data/logic, no scene to load, so this
# just runs assertions and prints PASS/FAIL lines (same convention as
# tests/board_smoke.gd).
# Usage: godot --headless --path tkyds-game --script res://tests/settlement_smoke.gd

var _failures: Array[String] = []

const _SIZES: Array = [
	SettlementGenerator.SettlementSize.HAMLET,
	SettlementGenerator.SettlementSize.VILLAGE,
	SettlementGenerator.SettlementSize.TOWN,
]


func _initialize() -> void:
	_check_generates_without_error_for_several_seeds()
	_check_determinism()
	_check_different_seed_differs_at_town()
	_check_no_overlap_and_within_disc()
	_check_layout_is_contiguous()
	_check_every_village_and_town_has_one_tavern_with_cast()
	_check_parametric_values_within_declared_ranges()
	_check_wealth_monotonicity()
	_check_structural_variation_guard()

	print("")
	if _failures.is_empty():
		print("=== SETTLEMENT SMOKE PASS ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== SETTLEMENT SMOKE FAIL ===")
		quit(1)


func _check_generates_without_error_for_several_seeds() -> void:
	for size: int in _SIZES:
		for seed_value in range(1, 6):
			var layout: SettlementLayout = SettlementGenerator.grow_settlement(seed_value, size, 0.5)
			_expect(layout.all_instances().size() > 0, "size %d seed %d should produce at least one instance" % [size, seed_value])


func _check_determinism() -> void:
	for size: int in _SIZES:
		var a: SettlementLayout = SettlementGenerator.grow_settlement(42, size, 0.6)
		var b: SettlementLayout = SettlementGenerator.grow_settlement(42, size, 0.6)
		_expect(_signature_of(a) == _signature_of(b), "same (seed, size, wealth) should produce identical layouts for size %d" % size)


func _check_different_seed_differs_at_town() -> void:
	var seeds: Array = [1, 2, 3, 4]
	var signatures: Array[String] = []
	for seed_value in seeds:
		var layout: SettlementLayout = SettlementGenerator.grow_settlement(seed_value, SettlementGenerator.SettlementSize.TOWN, 0.5)
		signatures.append(_signature_of(layout))
	var all_same := true
	for i in range(1, signatures.size()):
		if signatures[i] != signatures[0]:
			all_same = false
	_expect(not all_same, "different seeds should produce at least one different TOWN layout among %s" % [seeds])


func _check_no_overlap_and_within_disc() -> void:
	for size: int in _SIZES:
		var radius: int = SettlementGenerator.disc_radius_for(size)
		for seed_value in range(1, 4):
			var layout: SettlementLayout = SettlementGenerator.grow_settlement(seed_value, size, 0.5)
			var footprint_total := 0
			for instance: Dictionary in layout.all_instances():
				var footprint: Array = instance["footprint"]
				footprint_total += footprint.size()
				for hex: Vector2i in footprint:
					_expect(Hex.distance_between(Vector2i.ZERO, hex) <= radius, "hex %s of a %s instance should be within disc radius %d for size %d" % [hex, instance["template"], radius, size])
			var occupied_count: int = layout.occupied_micro_hexes().size()
			_expect(footprint_total == occupied_count, "sum of footprint sizes (%d) should equal occupied micro-hex count (%d) — no overlaps, for size %d seed %d" % [footprint_total, occupied_count, size, seed_value])


func _check_layout_is_contiguous() -> void:
	for size: int in _SIZES:
		for seed_value in range(1, 4):
			var layout: SettlementLayout = SettlementGenerator.grow_settlement(seed_value, size, 0.5)
			var occupied: Array[Vector2i] = layout.occupied_micro_hexes()
			if occupied.is_empty():
				continue
			var occupied_set: Dictionary = {}
			for hex: Vector2i in occupied:
				occupied_set[hex] = true

			var visited: Dictionary = {}
			var stack: Array[Vector2i] = [occupied[0]]
			visited[occupied[0]] = true
			while not stack.is_empty():
				var current: Vector2i = stack.pop_back()
				for neighbor: Vector2i in Hex.neighbors_of(current):
					if occupied_set.has(neighbor) and not visited.has(neighbor):
						visited[neighbor] = true
						stack.append(neighbor)

			_expect(visited.size() == occupied.size(), "layout should be one contiguous blob (flood fill reached %d of %d hexes) for size %d seed %d" % [visited.size(), occupied.size(), size, seed_value])


func _check_every_village_and_town_has_one_tavern_with_cast() -> void:
	for size: int in [SettlementGenerator.SettlementSize.VILLAGE, SettlementGenerator.SettlementSize.TOWN]:
		for seed_value in range(1, 4):
			var layout: SettlementLayout = SettlementGenerator.grow_settlement(seed_value, size, 0.5)
			var taverns: Array[Dictionary] = []
			for instance: Dictionary in layout.all_instances():
				if instance["template"] == "tavern":
					taverns.append(instance)
			_expect(taverns.size() == 1, "size %d seed %d should have exactly one tavern, found %d" % [size, seed_value, taverns.size()])
			if taverns.is_empty():
				continue
			var cast_slots: Dictionary = layout.cast_slots_of(taverns[0])
			_expect(cast_slots.has("keeper") and int(cast_slots["keeper"]) == 1, "tavern cast should include exactly 1 keeper, got %s" % [cast_slots])
			_expect(cast_slots.has("patron") and int(cast_slots["patron"]) >= 2, "tavern cast should include >= 2 patron slots, got %s" % [cast_slots])


func _check_parametric_values_within_declared_ranges() -> void:
	for size: int in _SIZES:
		for seed_value in range(1, 4):
			for wealth in [0.0, 0.3, 0.6, 1.0]:
				var layout: SettlementLayout = SettlementGenerator.grow_settlement(seed_value, size, wealth)
				for instance: Dictionary in layout.all_instances():
					var template_name: String = instance["template"]
					var tier: Dictionary = SettlementTemplate.wealth_tier_for(template_name, wealth)
					var capacity_range: Vector2i = tier["capacity_range"]
					var capacity: int = instance["capacity"]
					_expect(capacity >= capacity_range.x and capacity <= capacity_range.y, "%s capacity %d should be within declared range %s at wealth %f" % [template_name, capacity, capacity_range, wealth])

					var declared_slots: Dictionary = SettlementTemplate.cast_slots_of(template_name)
					var resolved_slots: Dictionary = instance["cast_slots"]
					for role: String in declared_slots:
						var bounds: Dictionary = declared_slots[role]
						var count: int = int(resolved_slots[role])
						_expect(count >= int(bounds["min"]) and count <= int(bounds["max"]), "%s role %s count %d should be within declared bounds %s" % [template_name, role, count, bounds])


func _check_wealth_monotonicity() -> void:
	for seed_value in range(1, 6):
		var low: SettlementLayout = SettlementGenerator.grow_settlement(seed_value, SettlementGenerator.SettlementSize.TOWN, 0.1)
		var high: SettlementLayout = SettlementGenerator.grow_settlement(seed_value, SettlementGenerator.SettlementSize.TOWN, 0.9)
		var low_tavern: Dictionary = _find_tavern(low)
		var high_tavern: Dictionary = _find_tavern(high)
		if low_tavern.is_empty() or high_tavern.is_empty():
			_expect(false, "seed %d should have a tavern at both wealth 0.1 and 0.9" % seed_value)
			continue
		var low_footprint: Array = low_tavern["footprint"]
		var high_footprint: Array = high_tavern["footprint"]
		_expect(int(high_tavern["capacity"]) >= int(low_tavern["capacity"]), "seed %d: tavern capacity at wealth 0.9 (%d) should be >= at wealth 0.1 (%d)" % [seed_value, high_tavern["capacity"], low_tavern["capacity"]])
		_expect(high_footprint.size() >= low_footprint.size(), "seed %d: tavern footprint at wealth 0.9 (%d hexes) should be >= at wealth 0.1 (%d hexes)" % [seed_value, high_footprint.size(), low_footprint.size()])


func _check_structural_variation_guard() -> void:
	for size: int in _SIZES:
		for seed_value in range(1, 4):
			for wealth in [0.0, 0.5, 1.0]:
				var layout: SettlementLayout = SettlementGenerator.grow_settlement(seed_value, size, wealth)
				for instance: Dictionary in layout.all_instances():
					var template_name: String = instance["template"]
					var anchor: Vector2i = instance["anchor"]
					var footprint: Array = instance["footprint"]
					var offsets: Array[Vector2i] = []
					for hex: Vector2i in footprint:
						offsets.append(hex - anchor)
					var matches_some_variant := false
					for variant: Array in SettlementTemplate.footprint_variants_of(template_name):
						if _offsets_match(offsets, variant):
							matches_some_variant = true
							break
					_expect(matches_some_variant, "%s instance footprint offsets %s should exactly match one authored variant" % [template_name, offsets])


func _find_tavern(layout: SettlementLayout) -> Dictionary:
	for instance: Dictionary in layout.all_instances():
		if instance["template"] == "tavern":
			return instance
	return {}


func _offsets_match(a: Array[Vector2i], b: Array) -> bool:
	if a.size() != b.size():
		return false
	for offset: Vector2i in a:
		if not b.has(offset):
			return false
	return true


func _signature_of(layout: SettlementLayout) -> String:
	var hexes: Array[Vector2i] = layout.occupied_micro_hexes()
	hexes.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.x != b.x:
			return a.x < b.x
		return a.y < b.y
	)
	var parts: Array[String] = []
	for hex: Vector2i in hexes:
		parts.append("%s:%s" % [hex, layout.template_at(hex)])
	return ",".join(parts)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)
