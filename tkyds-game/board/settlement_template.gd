class_name SettlementTemplate
extends RefCounted

# The authored settlement template library, as data (mirrors town_map.gd's
# LEGEND: data-as-code, not a class hierarchy). A template is a fixed shape
# and cast; only numbers and which authored arrangement gets picked vary
# between instances (PARAMETRIC), never the shape itself (no STRUCTURAL
# variation — see settlement_generator.gd for the placement algorithm that
# reads this data).
#
# footprint_variants: each entry is one authored arrangement, a fixed list of
#   micro-hex offsets (relative to the instance's own anchor, not the
#   settlement origin) that the instance occupies. Offset (0,0) is always
#   included and is where cast slots/tags anchor conceptually.
# cast_slots: named roles the fiction requires here. "min"/"max" bound how
#   many of that role exist; a fixed role (keeper) has min == max == 1.
#   Actual counts within [min, max] are chosen by the generator from wealth.
# tags: emitted on every occupied micro-hex of this instance (mirrors
#   HexMap.tags_at's seam — settlement code reads this the same way board
#   code reads HexMap tags).
# wealth_tiers: ordered low -> high; each entry names the footprint_variant
#   index legal at that tier and the capacity range legal at that tier. The
#   generator picks the tier for the instance's wealth and never lets a
#   higher wealth roll a smaller variant/capacity than a lower one would
#   (monotonicity is enforced by keeping variant micro-hex counts and
#   capacity ranges non-decreasing across the tier list — see
#   _check_library_is_monotonic in tests/settlement_smoke.gd).

const LIBRARY := {
	"town_square": {
		"footprint_variants": [
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)],
		],
		"cast_slots": {},
		"tags": ["town_square", "gathering_place"],
		"wealth_tiers": [
			{"min_wealth": 0.0, "footprint_variant": 0, "capacity_range": Vector2i(0, 0)},
		],
	},
	"tavern": {
		"footprint_variants": [
			# variant 0: hamlet-scale, 5 micro-hexes
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1)],
			# variant 1: village-scale, 6 micro-hexes
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1)],
			# variant 2: town-scale, 7 micro-hexes (full ring + center)
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)],
		],
		# The tavern MUST always carry its cast: Journey-1's proving scene
		# depends on a tavern always having a keeper and patron seats.
		"cast_slots": {
			"keeper": {"min": 1, "max": 1},
			"patron": {"min": 2, "max": 12},
		},
		"tags": ["tavern", "indoor", "social"],
		"wealth_tiers": [
			{"min_wealth": 0.0, "footprint_variant": 0, "capacity_range": Vector2i(2, 4)},
			{"min_wealth": 0.35, "footprint_variant": 1, "capacity_range": Vector2i(4, 8)},
			{"min_wealth": 0.7, "footprint_variant": 2, "capacity_range": Vector2i(8, 12)},
		],
	},
	"cottage": {
		"footprint_variants": [
			[Vector2i(0, 0)],
			[Vector2i(0, 0), Vector2i(1, 0)],
		],
		"cast_slots": {
			"resident": {"min": 1, "max": 4},
		},
		"tags": ["cottage", "dwelling", "indoor"],
		"wealth_tiers": [
			{"min_wealth": 0.0, "footprint_variant": 0, "capacity_range": Vector2i(1, 2)},
			{"min_wealth": 0.5, "footprint_variant": 1, "capacity_range": Vector2i(2, 4)},
		],
	},
	"church": {
		"footprint_variants": [
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0)],
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1)],
		],
		"cast_slots": {
			"priest": {"min": 1, "max": 1},
			"worshipper": {"min": 0, "max": 6},
		},
		"tags": ["church", "indoor", "sacred"],
		"wealth_tiers": [
			{"min_wealth": 0.0, "footprint_variant": 0, "capacity_range": Vector2i(0, 3)},
			{"min_wealth": 0.5, "footprint_variant": 1, "capacity_range": Vector2i(3, 6)},
		],
	},
	"market_stall": {
		"footprint_variants": [
			[Vector2i(0, 0)],
		],
		"cast_slots": {
			"merchant": {"min": 1, "max": 1},
		},
		"tags": ["market_stall", "outdoor", "trade"],
		"wealth_tiers": [
			{"min_wealth": 0.0, "footprint_variant": 0, "capacity_range": Vector2i(1, 1)},
		],
	},
	"well": {
		"footprint_variants": [
			[Vector2i(0, 0)],
		],
		"cast_slots": {},
		"tags": ["well", "outdoor", "utility"],
		"wealth_tiers": [
			{"min_wealth": 0.0, "footprint_variant": 0, "capacity_range": Vector2i(0, 0)},
		],
	},
	"field": {
		"footprint_variants": [
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, -1)],
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1)],
		],
		"cast_slots": {
			"farmhand": {"min": 0, "max": 3},
		},
		"tags": ["field", "outdoor", "farmland"],
		"wealth_tiers": [
			{"min_wealth": 0.0, "footprint_variant": 0, "capacity_range": Vector2i(0, 1)},
			{"min_wealth": 0.4, "footprint_variant": 1, "capacity_range": Vector2i(1, 3)},
		],
	},
}


static func names() -> Array[String]:
	var result: Array[String] = []
	for key: String in LIBRARY:
		result.append(key)
	return result


static func has_template(name: String) -> bool:
	return LIBRARY.has(name)


static func footprint_variants_of(name: String) -> Array:
	return LIBRARY[name]["footprint_variants"]


static func footprint_variant_of(name: String, variant_index: int) -> Array:
	return LIBRARY[name]["footprint_variants"][variant_index]


static func cast_slots_of(name: String) -> Dictionary:
	return LIBRARY[name]["cast_slots"]


static func tags_of(name: String) -> Array:
	return LIBRARY[name]["tags"]


static func wealth_tiers_of(name: String) -> Array:
	return LIBRARY[name]["wealth_tiers"]


# The tier that applies at the given wealth: the highest tier whose
# min_wealth is <= wealth. wealth_tiers_of must be ordered low -> high.
static func wealth_tier_for(name: String, wealth: float) -> Dictionary:
	var tiers: Array = wealth_tiers_of(name)
	var chosen: Dictionary = tiers[0]
	for tier: Dictionary in tiers:
		if wealth >= float(tier["min_wealth"]):
			chosen = tier
	return chosen
