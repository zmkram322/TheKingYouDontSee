class_name SettlementPlacer
extends RefCounted

# Decides WHERE settlements sit on the kingdom map, WHAT size and wealth they
# get, and the seed their layout will eventually grow from — planning only.
# This is the cheap global macro layer described in the design bible:
# settlement micro-detail (SettlementGenerator.grow_settlement) is generated
# lazily on first attention, never here. This file must never call
# grow_settlement and must never produce micro-hex content.
#
# PUBLIC CONTRACT
#   SettlementPlacer.plan_settlements(map: HexMap, seed: int) -> Array[Dictionary]
#   Each entry:
#     {
#       "hex": Vector2i,                              # strategic-map site
#       "size": SettlementGenerator.SettlementSize,   # HAMLET / VILLAGE / TOWN
#       "wealth": float,                              # in [WEALTH_FLOOR, WEALTH_CEILING]
#       "layout_seed": int,                           # stable per (map, seed, hex)
#     }
#   Deterministic: the same (map, seed) always produces an identical plan.
#
# Pure data/logic — no rendering, no Node/scene-tree dependencies, no imports
# from town/ or sim/. Reads the map only through HexMap's public accessors.

# --- Tunable placement constants --------------------------------------------
# Grouped, named, one place to retune the whole placer by hand.

# Local-richness scoring window (in hexes) around a candidate site.
const SCORE_RADIUS := 4
# Points awarded per DISTINCT resource family present within SCORE_RADIUS —
# weighted heavily so diversity beats raw volume of any one family.
const FAMILY_WEIGHT := 10
# Minimum hex distance required between any two accepted sites.
const MIN_SETTLEMENT_SPACING := 6
# Target site count is land_hex_count / LAND_HEXES_PER_SETTLEMENT, floored at 1.
const LAND_HEXES_PER_SETTLEMENT := 120
# Fraction of accepted sites (after the top TOWN) that become VILLAGE, rounded
# up; the remainder are HAMLET.
const VILLAGE_FRACTION := 0.3
# Wealth is normalized across the accepted set into this range.
const WEALTH_FLOOR := 0.25
const WEALTH_CEILING := 0.9
# Large, distinct primes used to fold a site's (q, r) into its layout seed.
const _LAYOUT_SEED_PRIME_Q := 73856093
const _LAYOUT_SEED_PRIME_R := 19349663

# Resource capability tags, grouped into the families the score cares about.
# can_mine_ore and can_quarry_stone both count toward "mineral" — a hex is
# only counted once for the family even if it happens to carry both.
const _FAMILY_TAGS := {
	"grain": ["can_grow_grain"],
	"lumber": ["can_cut_lumber"],
	"mineral": ["can_mine_ore", "can_quarry_stone"],
	"fish": ["can_fish"],
}


# --- Public entry point ------------------------------------------------------

static func plan_settlements(map: HexMap, seed: int) -> Array[Dictionary]:
	var candidates := _find_candidates(map)

	var scores: Dictionary = {}
	for hex: Vector2i in candidates:
		scores[hex] = _score_candidate(map, hex)

	var land_hex_count: int = _land_hex_count(map)
	var target_count: int = max(1, land_hex_count / LAND_HEXES_PER_SETTLEMENT)

	var accepted: Array[Vector2i] = _select_sites(candidates, scores, target_count)
	var sizes: Dictionary = _assign_sizes(accepted, scores)
	var wealth: Dictionary = _assign_wealth(accepted, scores)

	var plan: Array[Dictionary] = []
	for hex: Vector2i in accepted:
		plan.append({
			"hex": hex,
			"size": sizes[hex],
			"wealth": wealth[hex],
			"layout_seed": _layout_seed_for(hex, seed),
		})
	return plan


# --- Step 1: candidates -------------------------------------------------------

# Same rule the terrain generator's playability dial uses to find a
# settlement anchor (PLAINS with a RIVER/LAKE neighbor), re-derived here via
# public accessors only — terrain_generator.gd's private helpers stay private.
static func _find_candidates(map: HexMap) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for hex: Vector2i in map.all_hexes():
		if map.biome_at(hex) != HexMap.Biome.PLAINS:
			continue
		if _has_fresh_water_neighbor(map, hex):
			result.append(hex)
	return result


static func _has_fresh_water_neighbor(map: HexMap, hex: Vector2i) -> bool:
	for neighbor: Vector2i in Hex.neighbors_of(hex):
		if not map.has_hex(neighbor):
			continue
		var water: HexMap.Water = map.water_at(neighbor)
		if water == HexMap.Water.RIVER or water == HexMap.Water.LAKE:
			return true
	return false


static func _land_hex_count(map: HexMap) -> int:
	var count := 0
	for hex: Vector2i in map.all_hexes():
		if map.biome_at(hex) != HexMap.Biome.OCEAN:
			count += 1
	return count


# --- Step 2: score -------------------------------------------------------------

static func _score_candidate(map: HexMap, hex: Vector2i) -> int:
	var family_counts: Dictionary = {}
	for family: String in _FAMILY_TAGS:
		family_counts[family] = 0

	for nearby: Vector2i in Hex.hexes_within(hex, SCORE_RADIUS):
		if not map.has_hex(nearby):
			continue
		var tags: PackedStringArray = map.tags_at(nearby)
		for family: String in _FAMILY_TAGS:
			var family_tags: Array = _FAMILY_TAGS[family]
			for tag: String in family_tags:
				if tags.has(tag):
					family_counts[family] = int(family_counts[family]) + 1
					break  # count this hex once per family, even if it carries both mineral tags

	var distinct_families := 0
	var total_tagged := 0
	for family: String in family_counts:
		var count: int = int(family_counts[family])
		if count > 0:
			distinct_families += 1
		total_tagged += count

	return distinct_families * FAMILY_WEIGHT + total_tagged


# --- Step 3: select ------------------------------------------------------------

# Greedy by descending score (ties broken by (q, r) so ordering is total and
# deterministic): accept a candidate only if it clears MIN_SETTLEMENT_SPACING
# from every already-accepted site. Stops at target_count; running out of
# spacing-eligible candidates first yields a shorter plan, which is correct.
static func _select_sites(candidates: Array[Vector2i], scores: Dictionary, target_count: int) -> Array[Vector2i]:
	var ordered: Array[Vector2i] = candidates.duplicate()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _by_score_then_position(a, b, scores)
	)

	var accepted: Array[Vector2i] = []
	for candidate: Vector2i in ordered:
		if accepted.size() >= target_count:
			break
		var far_enough := true
		for site: Vector2i in accepted:
			if Hex.distance_between(candidate, site) < MIN_SETTLEMENT_SPACING:
				far_enough = false
				break
		if far_enough:
			accepted.append(candidate)
	return accepted


static func _by_score_then_position(a: Vector2i, b: Vector2i, scores: Dictionary) -> bool:
	var score_a: int = int(scores[a])
	var score_b: int = int(scores[b])
	if score_a != score_b:
		return score_a > score_b
	if a.x != b.x:
		return a.x < b.x
	return a.y < b.y


# --- Step 4: size ----------------------------------------------------------------

# accepted[] arrives already sorted descending by score (that's the order
# _select_sites consumed it in); re-sorting here just keeps this step
# independently correct if that ever changes.
static func _assign_sizes(accepted: Array[Vector2i], scores: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	if accepted.is_empty():
		return result

	var ranked: Array[Vector2i] = accepted.duplicate()
	ranked.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _by_score_then_position(a, b, scores)
	)

	var site_count: int = ranked.size()
	result[ranked[0]] = SettlementGenerator.SettlementSize.TOWN

	var remaining: int = site_count - 1
	var village_count: int = 0
	if remaining > 0:
		village_count = clampi(int(ceil(VILLAGE_FRACTION * float(site_count))), 0, remaining)

	for i in range(1, site_count):
		if i <= village_count:
			result[ranked[i]] = SettlementGenerator.SettlementSize.VILLAGE
		else:
			result[ranked[i]] = SettlementGenerator.SettlementSize.HAMLET
	return result


# --- Step 5: wealth --------------------------------------------------------------

# Min-max normalizes score across the accepted set into [WEALTH_FLOOR,
# WEALTH_CEILING]. A single site, or a set of sites that all tied on score,
# has no span to normalize across, so every site in that case gets the
# midpoint.
static func _assign_wealth(accepted: Array[Vector2i], scores: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	if accepted.is_empty():
		return result

	var min_score: int = int(scores[accepted[0]])
	var max_score: int = int(scores[accepted[0]])
	for site: Vector2i in accepted:
		var value: int = int(scores[site])
		if value < min_score:
			min_score = value
		if value > max_score:
			max_score = value

	var span: int = max_score - min_score
	var midpoint: float = (WEALTH_FLOOR + WEALTH_CEILING) / 2.0
	for site: Vector2i in accepted:
		if span <= 0:
			result[site] = midpoint
		else:
			var value: int = int(scores[site])
			var normalized: float = float(value - min_score) / float(span)
			result[site] = WEALTH_FLOOR + normalized * (WEALTH_CEILING - WEALTH_FLOOR)
	return result


# --- Step 6: layout seed -----------------------------------------------------------

# Folds the plan seed together with the site's (q, r) via distinct large
# primes, so every site in a plan gets its own stable seed to grow its layout
# from later, without needing to store anything beyond this one int.
static func _layout_seed_for(hex: Vector2i, plan_seed: int) -> int:
	return plan_seed ^ (hex.x * _LAYOUT_SEED_PRIME_Q) ^ (hex.y * _LAYOUT_SEED_PRIME_R)
