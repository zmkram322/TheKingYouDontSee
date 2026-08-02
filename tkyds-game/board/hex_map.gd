class_name HexMap
extends RefCounted

# Pure-data terrain grid, keyed by axial hex (Vector2i(q, r) — see hex.gd for
# the coordinate convention). Storage is a Dictionary of per-hex field
# dictionaries today; every read or write goes through the accessors below,
# so it may graduate to packed arrays later without any call site changing.
#
# tags_at(hex) is the board half of the location -> tags eligibility lookup
# (Situational Action Gating in the PRD) — nothing outside this file should
# reach past it into raw storage.
#
# A hex must be claim_hex()'d before any other accessor touches it; that's
# the terrain generator's job (next work package), not this file's.

enum Water { NONE, RIVER, LAKE, SEA }
enum Biome { OCEAN, PLAINS, FOREST, HILLS, MOUNTAINS, MARSH }

var _hexes := {}  # Vector2i -> {elevation, water, flow_direction, biome, tags}


func has_hex(hex: Vector2i) -> bool:
	return _hexes.has(hex)


func all_hexes() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for hex: Vector2i in _hexes:
		result.append(hex)
	return result


func elevation_at(hex: Vector2i) -> float:
	return _field(hex, "elevation")


func water_at(hex: Vector2i) -> Water:
	return _field(hex, "water")


func biome_at(hex: Vector2i) -> Biome:
	return _field(hex, "biome")


func flow_direction_at(hex: Vector2i) -> Vector2i:
	return _field(hex, "flow_direction")


func tags_at(hex: Vector2i) -> PackedStringArray:
	return _field(hex, "tags")


# Idempotent: claiming an already-claimed hex is a no-op, existing fields untouched.
func claim_hex(hex: Vector2i) -> void:
	if _hexes.has(hex):
		return
	_hexes[hex] = {
		"elevation": 0.0,
		"water": Water.NONE,
		"flow_direction": Vector2i.ZERO,
		"biome": Biome.PLAINS,
		"tags": PackedStringArray(),
	}


func set_elevation(hex: Vector2i, value: float) -> void:
	_entry(hex)["elevation"] = value


func set_water(hex: Vector2i, kind: Water) -> void:
	_entry(hex)["water"] = kind


func set_flow_direction(hex: Vector2i, dir: Vector2i) -> void:
	_entry(hex)["flow_direction"] = dir


func set_biome(hex: Vector2i, kind: Biome) -> void:
	_entry(hex)["biome"] = kind


func add_tag(hex: Vector2i, tag: String) -> void:
	var tags: PackedStringArray = _entry(hex)["tags"]
	if not tags.has(tag):
		tags.append(tag)
		_entry(hex)["tags"] = tags


func _entry(hex: Vector2i) -> Dictionary:
	assert(has_hex(hex), "Hex %s was never claimed" % hex)
	return _hexes[hex]


func _field(hex: Vector2i, key: String) -> Variant:
	return _entry(hex)[key]
