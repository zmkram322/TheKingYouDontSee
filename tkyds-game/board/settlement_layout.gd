class_name SettlementLayout
extends RefCounted

# Pure-data result of SettlementGenerator.grow_settlement(): which micro-hexes
# are occupied, what template/tags sit on each, and the cast slots each
# placed instance actually resolved to (counts, not just declared ranges).
# Narrow accessors only, mirroring HexMap's discipline in board/hex_map.gd —
# nothing outside this file should reach past them into _occupied/_instances.
#
# An "instance" is a Dictionary: {template, anchor, variant_index, footprint,
# capacity, cast_slots, tags}. It's handed back out through all_instances()
# and fed back into cast_slots_of() — kept as a Dictionary rather than a
# class because this is pure data with no behavior of its own.

var _occupied: Dictionary = {}  # Vector2i -> index into _instances
var _instances: Array[Dictionary] = []


func occupied_micro_hexes() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for hex: Vector2i in _occupied:
		result.append(hex)
	return result


func is_occupied(hex: Vector2i) -> bool:
	return _occupied.has(hex)


func template_at(hex: Vector2i) -> String:
	if not _occupied.has(hex):
		return ""
	return String(_instances[_occupied[hex]]["template"])


func tags_at(hex: Vector2i) -> PackedStringArray:
	if not _occupied.has(hex):
		return PackedStringArray()
	return _instances[_occupied[hex]]["tags"]


func instance_at(hex: Vector2i) -> Dictionary:
	assert(_occupied.has(hex), "Micro-hex %s has no instance" % hex)
	return _instances[_occupied[hex]]


func cast_slots_of(instance: Dictionary) -> Dictionary:
	return instance["cast_slots"]


func all_instances() -> Array[Dictionary]:
	return _instances.duplicate()


# Called only by SettlementGenerator while it builds a layout: footprint is
# the instance's absolute (already-anchored) list of micro-hexes. The
# generator's placement search must guarantee none of them are occupied
# before calling here; this just asserts that guarantee held.
func add_instance(template: String, anchor: Vector2i, variant_index: int, footprint: Array[Vector2i], capacity: int, cast_slots: Dictionary) -> void:
	var tags: PackedStringArray = PackedStringArray(SettlementTemplate.tags_of(template))
	var index: int = _instances.size()
	_instances.append({
		"template": template,
		"anchor": anchor,
		"variant_index": variant_index,
		"footprint": footprint.duplicate(),
		"capacity": capacity,
		"cast_slots": cast_slots,
		"tags": tags,
	})
	for hex: Vector2i in footprint:
		assert(not _occupied.has(hex), "Footprint overlap at %s" % hex)
		_occupied[hex] = index
