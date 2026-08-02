class_name TerrainGenerator
extends RefCounted

# One-way seeded pipeline: generate_kingdom(seed) hands back a fully
# populated HexMap and nothing else. No regeneration hooks, no reference back
# to the map is kept here, no coupling to any live simulation — call it once
# at world-build time and hand the result off.
#
# DETERMINISM: every number that varies with the seed comes from a seeded
# FastNoiseLite. No Godot global RNG is ever touched. Given the same seed and
# the same overrides, two calls produce byte-identical HexMap contents.
#
# Resource tags are CAPABILITY TAGS ("can_mine_ore", ...), never quantities.
# This file never invents a stockpile or an amount — that's the economy's job
# once it reads tags_at() off the map this file returns.
#
# Pure data/logic: no rendering, no Node/scene-tree dependencies, no imports
# from town/ or sim/.

# --- Tunable terrain constants ----------------------------------------------
# Grouped, named, one place to retune the whole generator by hand.

# Provisional: ~1,800 hexes (Hex.hexes_within radius 24 = 1 + 3*24*25 = 1801).
# Flagged provisional pending playtesting on how big a kingdom should feel.
const KINGDOM_RADIUS := 24

# --- Elevation ---
const NOISE_FREQUENCY := 0.035
const NOISE_OCTAVES := 3
const NOISE_LACUNARITY := 2.0
const NOISE_GAIN := 0.4
# Normalized distance-to-edge (0 at center, 1 at the outermost ring) past
# which the radial falloff starts eating into elevation, so the kingdom is
# ringed by sea rather than noise deciding the edge on its own.
const ELEVATION_FALLOFF_START := 0.55
const ELEVATION_FALLOFF_POWER := 3.0

# --- Water bodies & hydrology ---
const SEA_LEVEL := 0.38
const RIVER_ACCUMULATION_THRESHOLD := 12
# A land pit that can't drain to sea pools into a lake; the flood only grows
# to neighbors within this much elevation of the pit, and only up to this
# many hexes — small and legible, not a real watershed solver.
const LAKE_SPILL_MARGIN := 0.02
const LAKE_MAX_FILL_HEXES := 6

# --- Biome ---
# Regional humidity comes from its own noise channel, decoupled from
# distance to water (see _measure_moisture for why). MOISTURE_SEED_OFFSET
# keeps it decorrelated from the elevation noise using the same seed.
const MOISTURE_SEED_OFFSET := 97711
const MOISTURE_NOISE_FREQUENCY := 0.05
const MOISTURE_NOISE_OCTAVES := 2
const MOUNTAIN_ELEVATION := 0.88
const HILLS_ELEVATION := 0.72
# Marsh only forms this close above sea level (low ground) and wet enough.
const MARSH_ELEVATION_MARGIN := 0.06
const MARSH_MOISTURE_MIN := 0.75
const FOREST_MOISTURE_MIN := 0.5

# --- Playability dial ---
const PLAYABILITY_DIAL_DEFAULT := 0.5
const DIAL_SEARCH_RADIUS_MIN := 3
const DIAL_SEARCH_RADIUS_MAX := 9


# --- Public entry points ----------------------------------------------------

static func generate_kingdom(seed: int) -> HexMap:
	return generate_kingdom_with_overrides(seed, {})


# overrides supports "radius" (int) and "dial" (float, 0..1); anything absent
# falls back to the named constants above.
static func generate_kingdom_with_overrides(seed: int, overrides: Dictionary) -> HexMap:
	var radius: int = int(overrides.get("radius", KINGDOM_RADIUS))
	var dial: float = float(overrides.get("dial", PLAYABILITY_DIAL_DEFAULT))

	var map := HexMap.new()
	var all_hexes := _claim_kingdom(map, radius)
	_sculpt_elevation(map, all_hexes, radius, seed)
	_flood_oceans(map, all_hexes)

	var land_hexes := _land_hexes_of(map, all_hexes)
	_stretch_land_elevation(map, land_hexes)
	_trace_flow_directions(map, land_hexes)
	_pool_lakes(map, land_hexes)
	_carve_rivers(map, land_hexes)

	var moisture := _measure_moisture(all_hexes, seed)
	_classify_biomes(map, land_hexes, moisture)
	_tag_resources(map, land_hexes)
	_balance_playability(map, land_hexes, dial)

	return map


# --- Stage A: claim ----------------------------------------------------------

static func _claim_kingdom(map: HexMap, radius: int) -> Array[Vector2i]:
	var hexes := Hex.hexes_within(Vector2i.ZERO, radius)
	for hex: Vector2i in hexes:
		map.claim_hex(hex)
	return hexes


# --- Stage B: elevation ------------------------------------------------------

static func _sculpt_elevation(map: HexMap, hexes: Array[Vector2i], radius: int, seed: int) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = NOISE_FREQUENCY
	noise.fractal_octaves = NOISE_OCTAVES
	noise.fractal_lacunarity = NOISE_LACUNARITY
	noise.fractal_gain = NOISE_GAIN

	for hex: Vector2i in hexes:
		var world := Hex.world_position_of(hex, 1.0)
		var raw: float = (noise.get_noise_2d(world.x, world.y) + 1.0) / 2.0
		raw = clampf(raw, 0.0, 1.0)
		var falloff: float = _edge_falloff(hex, radius)
		var elevation: float = clampf(raw - falloff, 0.0, 1.0)
		map.set_elevation(hex, elevation)


# 0 near the center, ramps up to exactly 1.0 at the outermost ring so every
# hex out there is forced below sea level regardless of what the noise rolled.
static func _edge_falloff(hex: Vector2i, radius: int) -> float:
	var safe_radius: float = float(max(radius, 1))
	var distance: int = Hex.distance_between(hex, Vector2i.ZERO)
	var normalized: float = float(distance) / safe_radius
	if normalized <= ELEVATION_FALLOFF_START:
		return 0.0
	var t: float = (normalized - ELEVATION_FALLOFF_START) / (1.0 - ELEVATION_FALLOFF_START)
	return pow(t, ELEVATION_FALLOFF_POWER)


# --- Stage C: water bodies ----------------------------------------------------

static func _flood_oceans(map: HexMap, hexes: Array[Vector2i]) -> void:
	for hex: Vector2i in hexes:
		if map.elevation_at(hex) < SEA_LEVEL:
			map.set_biome(hex, HexMap.Biome.OCEAN)
			map.set_water(hex, HexMap.Water.SEA)


static func _land_hexes_of(map: HexMap, hexes: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for hex: Vector2i in hexes:
		if map.water_at(hex) != HexMap.Water.SEA:
			result.append(hex)
	return result


# Land elevation from the noise+falloff rarely spans the full 0..1 range in
# practice (observed land max often sits well under 1.0), so a fixed
# threshold like MOUNTAIN_ELEVATION sees almost no land cross it. This
# stretches THIS map's actual land elevation span to fill [SEA_LEVEL, 1.0].
# It's order-preserving (a strictly increasing remap), so it changes no
# neighbor-is-lower comparison hydrology already relies on — only the
# thresholds in stage E, which is the point. Deterministic: min/max come
# from this map's own land hexes, nothing external.
static func _stretch_land_elevation(map: HexMap, land_hexes: Array[Vector2i]) -> void:
	if land_hexes.is_empty():
		return

	var land_min: float = 1.0
	var land_max: float = 0.0
	for hex: Vector2i in land_hexes:
		var elevation: float = map.elevation_at(hex)
		if elevation < land_min:
			land_min = elevation
		if elevation > land_max:
			land_max = elevation

	var span: float = land_max - land_min
	if span <= 0.0001:
		return  # degenerate (near-flat land) — nothing meaningful to stretch

	for hex: Vector2i in land_hexes:
		var elevation: float = map.elevation_at(hex)
		var stretched: float = SEA_LEVEL + (elevation - land_min) / span * (1.0 - SEA_LEVEL)
		map.set_elevation(hex, clampf(stretched, SEA_LEVEL, 1.0))


# --- Stage D: hydrology -------------------------------------------------------

static func _trace_flow_directions(map: HexMap, land_hexes: Array[Vector2i]) -> void:
	for hex: Vector2i in land_hexes:
		var here_elevation: float = map.elevation_at(hex)
		var best_direction := Vector2i.ZERO
		var best_elevation: float = here_elevation
		for neighbor: Vector2i in Hex.neighbors_of(hex):
			if not map.has_hex(neighbor):
				continue
			var neighbor_elevation: float = map.elevation_at(neighbor)
			if neighbor_elevation < best_elevation:
				best_elevation = neighbor_elevation
				best_direction = neighbor - hex
		map.set_flow_direction(hex, best_direction)


static func _pool_lakes(map: HexMap, land_hexes: Array[Vector2i]) -> void:
	for hex: Vector2i in land_hexes:
		if map.water_at(hex) != HexMap.Water.NONE:
			continue
		if map.flow_direction_at(hex) != Vector2i.ZERO:
			continue
		_flood_fill_lake(map, hex)


static func _flood_fill_lake(map: HexMap, pit: Vector2i) -> void:
	var pit_elevation: float = map.elevation_at(pit)
	var basin: Array[Vector2i] = [pit]
	var seen: Dictionary = {pit: true}
	var frontier: Array[Vector2i] = [pit]

	while not frontier.is_empty() and basin.size() < LAKE_MAX_FILL_HEXES:
		var current: Vector2i = frontier.pop_front()
		for neighbor: Vector2i in Hex.neighbors_of(current):
			if seen.has(neighbor) or not map.has_hex(neighbor):
				continue
			seen[neighbor] = true
			if map.water_at(neighbor) == HexMap.Water.SEA:
				continue
			var neighbor_elevation: float = map.elevation_at(neighbor)
			if neighbor_elevation <= pit_elevation + LAKE_SPILL_MARGIN:
				basin.append(neighbor)
				frontier.append(neighbor)
				if basin.size() >= LAKE_MAX_FILL_HEXES:
					break

	for hex: Vector2i in basin:
		map.set_water(hex, HexMap.Water.LAKE)


static func _carve_rivers(map: HexMap, land_hexes: Array[Vector2i]) -> void:
	var by_elevation_descending := land_hexes.duplicate()
	by_elevation_descending.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var elevation_a: float = map.elevation_at(a)
		var elevation_b: float = map.elevation_at(b)
		if is_equal_approx(elevation_a, elevation_b):
			if a.x == b.x:
				return a.y < b.y
			return a.x < b.x
		return elevation_a > elevation_b
	)

	var accumulation: Dictionary = {}
	for hex: Vector2i in by_elevation_descending:
		accumulation[hex] = 1

	# Highest first: by the time a hex is visited, every upstream neighbor
	# (strictly higher, so already visited) has already pushed its water in.
	for hex: Vector2i in by_elevation_descending:
		var here_accumulation: int = accumulation[hex]
		var direction: Vector2i = map.flow_direction_at(hex)
		if direction == Vector2i.ZERO:
			continue
		var target: Vector2i = hex + direction
		if accumulation.has(target):
			accumulation[target] = int(accumulation[target]) + here_accumulation

	for hex: Vector2i in land_hexes:
		if map.water_at(hex) != HexMap.Water.NONE:
			continue
		var total: int = accumulation[hex]
		if total > RIVER_ACCUMULATION_THRESHOLD:
			map.set_water(hex, HexMap.Water.RIVER)


# --- Stage E: biome -----------------------------------------------------------

# Regional humidity from its own seeded noise channel — deliberately NOT a
# function of distance to water. An earlier version measured moisture as
# falloff-from-nearest-water; since the kingdom is deliberately ringed by
# sea, that read nearly all land as maximally wet and FOREST swallowed the
# interior, and it also meant hexes right at a river or lake's edge — the
# hexes can_grow_grain needs to be PLAINS — read as the WETTEST hexes on the
# map, actively working against grain instead of encouraging it. A
# regional-humidity field uncorrelated with water proximity lets river/lake
# shores land in PLAINS territory as often as chance puts them there,
# instead of never.
static func _measure_moisture(all_hexes: Array[Vector2i], seed: int) -> Dictionary:
	var noise := FastNoiseLite.new()
	noise.seed = seed + MOISTURE_SEED_OFFSET
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = MOISTURE_NOISE_FREQUENCY
	noise.fractal_octaves = MOISTURE_NOISE_OCTAVES
	noise.fractal_lacunarity = NOISE_LACUNARITY
	noise.fractal_gain = NOISE_GAIN

	var moisture: Dictionary = {}
	for hex: Vector2i in all_hexes:
		var world := Hex.world_position_of(hex, 1.0)
		var raw: float = (noise.get_noise_2d(world.x, world.y) + 1.0) / 2.0
		moisture[hex] = clampf(raw, 0.0, 1.0)
	return moisture


static func _classify_biomes(map: HexMap, land_hexes: Array[Vector2i], moisture: Dictionary) -> void:
	for hex: Vector2i in land_hexes:
		var elevation: float = map.elevation_at(hex)
		var wetness: float = moisture[hex]
		var biome: HexMap.Biome
		if elevation >= MOUNTAIN_ELEVATION:
			biome = HexMap.Biome.MOUNTAINS
		elif elevation >= HILLS_ELEVATION:
			biome = HexMap.Biome.HILLS
		elif elevation <= SEA_LEVEL + MARSH_ELEVATION_MARGIN and wetness >= MARSH_MOISTURE_MIN:
			biome = HexMap.Biome.MARSH
		elif wetness >= FOREST_MOISTURE_MIN:
			biome = HexMap.Biome.FOREST
		else:
			biome = HexMap.Biome.PLAINS
		map.set_biome(hex, biome)


# --- Stage F: resource tags ---------------------------------------------------

static func _tag_resources(map: HexMap, land_hexes: Array[Vector2i]) -> void:
	for hex: Vector2i in land_hexes:
		var biome: HexMap.Biome = map.biome_at(hex)
		match biome:
			HexMap.Biome.MOUNTAINS:
				map.add_tag(hex, "can_mine_ore")
				map.add_tag(hex, "can_quarry_stone")
			HexMap.Biome.HILLS:
				map.add_tag(hex, "can_quarry_stone")
			HexMap.Biome.FOREST:
				map.add_tag(hex, "can_cut_lumber")
		if biome == HexMap.Biome.PLAINS and _adjacent_to_fresh_water(map, hex):
			map.add_tag(hex, "can_grow_grain")
		if _adjacent_to_any_water(map, hex):
			map.add_tag(hex, "can_fish")


static func _adjacent_to_fresh_water(map: HexMap, hex: Vector2i) -> bool:
	for neighbor: Vector2i in Hex.neighbors_of(hex):
		if not map.has_hex(neighbor):
			continue
		var water: HexMap.Water = map.water_at(neighbor)
		if water == HexMap.Water.RIVER or water == HexMap.Water.LAKE:
			return true
	return false


static func _adjacent_to_any_water(map: HexMap, hex: Vector2i) -> bool:
	for neighbor: Vector2i in Hex.neighbors_of(hex):
		if not map.has_hex(neighbor):
			continue
		if map.water_at(neighbor) != HexMap.Water.NONE:
			return true
	return false


# --- Stage G: playability dial -------------------------------------------------

# At dial <= 0, the map is whatever the noise rolled. Above 0, this checks
# whether a coherent starting mix (grain + lumber + ore-or-stone) already
# exists within a dial-scaled radius of some PLAINS-near-fresh-water site; if
# not, it nudges the fewest hexes it can to make that true for one site.
static func _balance_playability(map: HexMap, land_hexes: Array[Vector2i], dial: float) -> void:
	if dial <= 0.0:
		return

	var clamped_dial: float = clampf(dial, 0.0, 1.0)
	var search_radius: int = int(round(lerpf(float(DIAL_SEARCH_RADIUS_MIN), float(DIAL_SEARCH_RADIUS_MAX), clamped_dial)))

	var candidates := _settlement_candidates(map, land_hexes)
	if candidates.is_empty():
		candidates = [_force_settlement_candidate(map, land_hexes)]

	for site: Vector2i in candidates:
		if _has_coherent_mix(map, site, search_radius):
			return

	_nudge_coherent_mix(map, candidates[0], search_radius, land_hexes)


static func _settlement_candidates(map: HexMap, land_hexes: Array[Vector2i]) -> Array[Vector2i]:
	var sites: Array[Vector2i] = []
	for hex: Vector2i in land_hexes:
		if map.biome_at(hex) == HexMap.Biome.PLAINS and _adjacent_to_fresh_water(map, hex):
			sites.append(hex)
	sites.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.x == b.x:
			return a.y < b.y
		return a.x < b.x
	)
	return sites


# Fallback for the (unlikely, at kingdom scale) case where no natural
# PLAINS-near-water site exists at all: anchor on the land hex closest to the
# origin, force it to PLAINS, and force one neighbor to fresh water.
static func _force_settlement_candidate(map: HexMap, land_hexes: Array[Vector2i]) -> Vector2i:
	var by_distance_to_center := land_hexes.duplicate()
	by_distance_to_center.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var distance_a: int = Hex.distance_between(a, Vector2i.ZERO)
		var distance_b: int = Hex.distance_between(b, Vector2i.ZERO)
		if distance_a == distance_b:
			if a.x == b.x:
				return a.y < b.y
			return a.x < b.x
		return distance_a < distance_b
	)

	var anchor: Vector2i = by_distance_to_center[0]
	for hex: Vector2i in by_distance_to_center:
		if _hex_keeps_tags_if_rebiomed(map, hex, HexMap.Biome.PLAINS):
			anchor = hex
			break

	if map.biome_at(anchor) != HexMap.Biome.PLAINS:
		map.set_biome(anchor, HexMap.Biome.PLAINS)
	if not _adjacent_to_fresh_water(map, anchor):
		_force_fresh_water_neighbor(map, anchor)
	map.add_tag(anchor, "can_grow_grain")
	return anchor


# True if none of the tags already sitting on hex would become ungated (i.e.
# no longer match their biome-gating rule) if hex's biome changed to
# new_biome. can_fish carries no biome requirement, so it never blocks a
# re-biome; the other four tags each pin one specific biome (or, for
# can_quarry_stone, either of two).
static func _hex_keeps_tags_if_rebiomed(map: HexMap, hex: Vector2i, new_biome: HexMap.Biome) -> bool:
	var tags := map.tags_at(hex)
	if tags.has("can_mine_ore") and new_biome != HexMap.Biome.MOUNTAINS:
		return false
	if tags.has("can_quarry_stone") and new_biome != HexMap.Biome.MOUNTAINS and new_biome != HexMap.Biome.HILLS:
		return false
	if tags.has("can_cut_lumber") and new_biome != HexMap.Biome.FOREST:
		return false
	if tags.has("can_grow_grain") and new_biome != HexMap.Biome.PLAINS:
		return false
	return true


# A single-hex lake, not a river: a lake terminates by definition (no flow
# consistency to maintain), and still satisfies _adjacent_to_fresh_water. A
# forced river would need a flow_direction chain that actually reaches a sea
# or lake, which this local, single-hex nudge has no way to guarantee.
static func _force_fresh_water_neighbor(map: HexMap, hex: Vector2i) -> void:
	for neighbor: Vector2i in Hex.neighbors_of(hex):
		if map.has_hex(neighbor) and map.biome_at(neighbor) != HexMap.Biome.OCEAN:
			map.set_water(neighbor, HexMap.Water.LAKE)
			return


static func _has_coherent_mix(map: HexMap, site: Vector2i, radius: int) -> bool:
	var has_grain := false
	var has_lumber := false
	var has_mineral := false
	for hex: Vector2i in Hex.hexes_within(site, radius):
		if not map.has_hex(hex):
			continue
		var tags := map.tags_at(hex)
		if tags.has("can_grow_grain"):
			has_grain = true
		if tags.has("can_cut_lumber"):
			has_lumber = true
		if tags.has("can_mine_ore") or tags.has("can_quarry_stone"):
			has_mineral = true
		if has_grain and has_lumber and has_mineral:
			return true
	return false


static func _nudge_coherent_mix(map: HexMap, site: Vector2i, radius: int, land_hexes: Array[Vector2i]) -> void:
	var nearby := _land_hexes_within(map, site, radius, land_hexes)

	# Hexes this pass has already claimed for one tag are off-limits to the
	# rest of the pass — re-bioming a hex a second time would strand
	# whatever it was just gated for. The site itself is reserved too: it's
	# the PLAINS-near-water settlement anchor and must stay that way.
	var reserved: Dictionary = {site: true}

	if not _any_has_tag(map, nearby, "can_grow_grain"):
		var grain_target := _nudge_grain(map, site, nearby, reserved)
		reserved[grain_target] = true
	if not _any_has_tag(map, nearby, "can_cut_lumber"):
		var lumber_target := _nudge_biome_tag(map, site, nearby, "can_cut_lumber", HexMap.Biome.FOREST, reserved)
		reserved[lumber_target] = true
	if not (_any_has_tag(map, nearby, "can_mine_ore") or _any_has_tag(map, nearby, "can_quarry_stone")):
		_nudge_biome_tag(map, site, nearby, "can_quarry_stone", HexMap.Biome.HILLS, reserved)


static func _land_hexes_within(map: HexMap, site: Vector2i, radius: int, land_hexes: Array[Vector2i]) -> Array[Vector2i]:
	var land_set: Dictionary = {}
	for hex: Vector2i in land_hexes:
		land_set[hex] = true

	var result: Array[Vector2i] = []
	for hex: Vector2i in Hex.hexes_within(site, radius):
		if land_set.has(hex):
			result.append(hex)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var distance_a: int = Hex.distance_between(site, a)
		var distance_b: int = Hex.distance_between(site, b)
		if distance_a == distance_b:
			if a.x == b.x:
				return a.y < b.y
			return a.x < b.x
		return distance_a < distance_b
	)
	return result


static func _any_has_tag(map: HexMap, hexes: Array[Vector2i], tag: String) -> bool:
	for hex: Vector2i in hexes:
		if map.tags_at(hex).has(tag):
			return true
	return false


# Lumber/stone ARE gated (can_cut_lumber -> FOREST, can_quarry_stone ->
# HILLS or MOUNTAINS) — the board renders biome, so a tagged hex must look
# the part. The nudge picks the nearest eligible, unreserved hex whose
# current tags survive the re-biome (_hex_keeps_tags_if_rebiomed), sets its
# biome to match, and tags it together in the same breath. Falls back to the
# site itself only if nothing else in range qualifies; if even the site
# isn't safe to touch, this is a no-op — legibility over completeness in
# that vanishingly rare corner.
static func _nudge_biome_tag(map: HexMap, site: Vector2i, nearby: Array[Vector2i], tag: String, biome: HexMap.Biome, reserved: Dictionary) -> Vector2i:
	var target := site
	var found := false
	for hex: Vector2i in nearby:
		if reserved.has(hex):
			continue
		if _hex_keeps_tags_if_rebiomed(map, hex, biome):
			target = hex
			found = true
			break

	if not found:
		if reserved.has(site) or not _hex_keeps_tags_if_rebiomed(map, site, biome):
			return site
		target = site

	if map.biome_at(target) != biome:
		map.set_biome(target, biome)
	map.add_tag(target, tag)
	return target


# Grain is gated (must be PLAINS + adjacent fresh water), so the nudge picks
# the nearest eligible, unreserved hex whose current tags survive becoming
# PLAINS (_hex_keeps_tags_if_rebiomed — e.g. skips a HILLS hex already
# tagged can_quarry_stone), forces it to PLAINS, and forces one of its
# neighbors to fresh water if none is already.
static func _nudge_grain(map: HexMap, site: Vector2i, nearby: Array[Vector2i], reserved: Dictionary) -> Vector2i:
	var target := site
	for hex: Vector2i in nearby:
		if reserved.has(hex):
			continue
		if _hex_keeps_tags_if_rebiomed(map, hex, HexMap.Biome.PLAINS):
			target = hex
			break

	if map.biome_at(target) != HexMap.Biome.PLAINS:
		map.set_biome(target, HexMap.Biome.PLAINS)
	if not _adjacent_to_fresh_water(map, target):
		_force_fresh_water_neighbor(map, target)
	map.add_tag(target, "can_grow_grain")
	return target
