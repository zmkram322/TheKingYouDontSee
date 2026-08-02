class_name SettlementGenerator
extends RefCounted

# Grows one settlement layout, once, from the authored template library in
# settlement_template.gd. Deterministic per (seed, size, wealth): all
# randomness comes from a RandomNumberGenerator seeded right here, never the
# global RNG. Pure data/logic — no rendering, no Node/scene-tree
# dependencies, no coupling to the strategic-map layer (that's another
# system; settlements only know their own local micro-hex frame, origin at
# the settlement's own center).

enum SettlementSize { HAMLET, VILLAGE, TOWN }

# How many micro-hexes typically compose one strategic-zoom hex. This is an
# open question in the PRD (hex-board PRD, "micro-hex-per-strategic-hex
# scale" — not pinned down); nothing in this file uses the constant, it's
# just parked here as the one named place downstream code can look once the
# question is answered. PROVISIONAL / UNPINNED.
const MICRO_HEXES_PER_STRATEGIC_HEX := 37

# Radius (in micro-hexes, centered on the settlement origin) that all of a
# settlement's instances must fit inside. Scales with size so a TOWN has
# visibly more room to grow into than a HAMLET.
const _DISC_RADIUS := {
	SettlementSize.HAMLET: 3,
	SettlementSize.VILLAGE: 5,
	SettlementSize.TOWN: 8,
}


static func disc_radius_for(size: SettlementSize) -> int:
	return _DISC_RADIUS[size]


static func grow_settlement(seed: int, size: SettlementSize, wealth: float) -> SettlementLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var radius: int = _DISC_RADIUS[size]
	var layout := SettlementLayout.new()

	# The first instance anchors the settlement at the origin and gives
	# every later instance something to grow adjacent to. VILLAGE/TOWN
	# anchor on the town square; a HAMLET may skip the square (per spec),
	# so it anchors on its well instead — a judgment call: some single
	# required instance has to occupy the origin first, and well is the
	# one HAMLET always has.
	var anchor_template: String = "well" if size == SettlementSize.HAMLET else "town_square"
	_place_instance(layout, anchor_template, Vector2i.ZERO, wealth, rng)

	var remaining: Array[String] = _remaining_templates_for(size, anchor_template, wealth, rng)
	for template_name: String in remaining:
		var tier: Dictionary = SettlementTemplate.wealth_tier_for(template_name, wealth)
		var variant_index: int = tier["footprint_variant"]
		var offsets: Array = SettlementTemplate.footprint_variant_of(template_name, variant_index)
		var attempt: Dictionary = _find_anchor(layout, offsets, radius, rng)
		if not attempt["found"]:
			continue  # disc too small for this instance; skip rather than overlap or escape the disc
		_place_instance(layout, template_name, attempt["anchor"], wealth, rng)

	return layout


# Required templates for this size, minus whichever one was already placed
# as the origin anchor, ordered so bigger footprints (tavern, church, field)
# get first pick of open frontier space and small ones (cottage, well,
# market_stall) slot into whatever nooks are left — placing a big footprint
# after the frontier is already crowded with small ones tends to leave it
# nowhere to fit. Seed-driven shuffle still decides tie-breaking order among
# templates of equal footprint size.
static func _remaining_templates_for(size: SettlementSize, anchor_template: String, wealth: float, rng: RandomNumberGenerator) -> Array[String]:
	var counts: Dictionary = {}
	match size:
		SettlementSize.HAMLET:
			counts = {
				"cottage": rng.randi_range(2, 4),
				"well": 1,
			}
		SettlementSize.VILLAGE:
			counts = {
				"well": 1,
				"tavern": 1,
				"market_stall": rng.randi_range(1, 2),
				"field": rng.randi_range(1, 2),
				"cottage": rng.randi_range(3, 6),
			}
		SettlementSize.TOWN:
			counts = {
				"well": 1,
				"tavern": 1,
				"church": 1,
				"market_stall": rng.randi_range(2, 4),
				"field": rng.randi_range(2, 3),
				"cottage": rng.randi_range(6, 10),
			}

	var list: Array[String] = []
	for template_name: String in counts:
		if template_name == anchor_template:
			continue
		var count: int = int(counts[template_name])
		for _i in range(count):
			list.append(template_name)

	var shuffled_list: Array[String] = _shuffled(list, rng)
	shuffled_list.sort_custom(func(a: String, b: String) -> bool:
		return _footprint_size_at(a, wealth) > _footprint_size_at(b, wealth)
	)
	return shuffled_list


static func _footprint_size_at(template_name: String, wealth: float) -> int:
	var tier: Dictionary = SettlementTemplate.wealth_tier_for(template_name, wealth)
	var variant_index: int = tier["footprint_variant"]
	return SettlementTemplate.footprint_variant_of(template_name, variant_index).size()


static func _shuffled(list: Array[String], rng: RandomNumberGenerator) -> Array[String]:
	var pool: Array[String] = list.duplicate()
	var result: Array[String] = []
	while not pool.is_empty():
		var index: int = rng.randi_range(0, pool.size() - 1)
		result.append(pool[index])
		pool.remove_at(index)
	return result


static func _place_instance(layout: SettlementLayout, template_name: String, anchor: Vector2i, wealth: float, rng: RandomNumberGenerator) -> void:
	var tier: Dictionary = SettlementTemplate.wealth_tier_for(template_name, wealth)
	var variant_index: int = tier["footprint_variant"]
	var offsets: Array = SettlementTemplate.footprint_variant_of(template_name, variant_index)
	var capacity_range: Vector2i = tier["capacity_range"]
	var capacity: int = rng.randi_range(capacity_range.x, capacity_range.y)
	var cast_slots: Dictionary = _resolve_cast_slots(template_name, capacity)

	var footprint: Array[Vector2i] = []
	for offset: Vector2i in offsets:
		footprint.append(anchor + offset)

	layout.add_instance(template_name, anchor, variant_index, footprint, capacity, cast_slots)


# Fixed roles (min == max, e.g. tavern keeper, church priest, stall
# merchant) are always guaranteed at their fixed count. Variable roles
# (tavern patron, cottage resident, church worshipper, field farmhand) scale
# with the instance's resolved capacity, clamped to the role's declared
# bounds as a defensive floor/ceiling (the library's capacity_range tiers
# are authored to already sit inside those bounds).
static func _resolve_cast_slots(template_name: String, capacity: int) -> Dictionary:
	var declared: Dictionary = SettlementTemplate.cast_slots_of(template_name)
	var resolved: Dictionary = {}
	for role: String in declared:
		var bounds: Dictionary = declared[role]
		var min_count: int = bounds["min"]
		var max_count: int = bounds["max"]
		if min_count == max_count:
			resolved[role] = min_count
		else:
			resolved[role] = clampi(capacity, min_count, max_count)
	return resolved


# Picks a placement for a footprint somewhere among the disc's free
# micro-hexes, requiring that at least one of the footprint's own cells
# ends up adjacent to an already-occupied cell (see _touches_occupied) —
# that's what keeps the whole layout contiguous. Deliberately does NOT
# require the anchor itself (offset (0,0)) to be the cell that touches:
# a disc-shaped footprint (e.g. the full-ring tavern/town_square variant)
# can never have its anchor directly touching another disc-shaped
# footprint's territory without overlapping it, so the anchor needs room
# to sit one ring further out while one of its own arms reaches back to
# touch the existing blob. Returns {"found": bool, "anchor": Vector2i}
# rather than a nullable Vector2i to keep every local explicitly typed.
static func _find_anchor(layout: SettlementLayout, offsets: Array, radius: int, rng: RandomNumberGenerator) -> Dictionary:
	var candidates: Array[Vector2i] = []
	for hex: Vector2i in Hex.hexes_within(Vector2i.ZERO, radius):
		if not layout.is_occupied(hex):
			candidates.append(hex)
	return _search(candidates, offsets, layout, radius, rng)


static func _search(candidates: Array[Vector2i], offsets: Array, layout: SettlementLayout, radius: int, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array[Vector2i] = candidates.duplicate()
	while not pool.is_empty():
		var index: int = rng.randi_range(0, pool.size() - 1)
		var anchor: Vector2i = pool[index]
		pool.remove_at(index)
		if _fits(anchor, offsets, layout, radius) and _touches_occupied(anchor, offsets, layout):
			return {"found": true, "anchor": anchor}
	return {"found": false, "anchor": Vector2i.ZERO}


static func _fits(anchor: Vector2i, offsets: Array, layout: SettlementLayout, radius: int) -> bool:
	for offset: Vector2i in offsets:
		var cell: Vector2i = anchor + offset
		if Hex.distance_between(Vector2i.ZERO, cell) > radius:
			return false
		if layout.is_occupied(cell):
			return false
	return true


static func _touches_occupied(anchor: Vector2i, offsets: Array, layout: SettlementLayout) -> bool:
	for offset: Vector2i in offsets:
		var cell: Vector2i = anchor + offset
		for neighbor: Vector2i in Hex.neighbors_of(cell):
			if layout.is_occupied(neighbor):
				return true
	return false
