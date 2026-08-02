class_name Hex
extends RefCounted

# Static helpers over axial hex coordinates, stored as Vector2i(q, r).
# Orientation is pointy-top. World space is Godot's normal 2D space (x right,
# y down) — the pixel formulas below are the standard pointy-top axial ones
# and don't care which way "down" points, only that q/r/pixel agree with
# each other, which is all any caller needs.
#
# neighbors_of() and ring_around() share one direction order:
#   0: +q        (east)
#   1: +q -r     (northeast)
#   2:    -r     (northwest)
#   3: -q        (west)
#   4: -q +r     (southwest)
#   5:    +r     (southeast)
# Each entry is 60 degrees from its neighbors in the list, which is what
# ring_around() relies on to walk a ring side by side.

const _DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]


static func neighbors_of(hex: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in _DIRECTIONS:
		result.append(hex + dir)
	return result


static func distance_between(a: Vector2i, b: Vector2i) -> int:
	var dq := a.x - b.x
	var dr := a.y - b.y
	return (abs(dq) + abs(dq + dr) + abs(dr)) / 2


# All hexes exactly radius steps from center. radius <= 0 yields [] except
# radius == 0, which yields [center].
static func ring_around(center: Vector2i, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if radius < 0:
		return result
	if radius == 0:
		result.append(center)
		return result
	var hex := center + _DIRECTIONS[4] * radius
	for side in range(6):
		for _step in range(radius):
			result.append(hex)
			hex += _DIRECTIONS[side]
	return result


# Filled disc of hexes within radius steps of center, center included.
static func hexes_within(center: Vector2i, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dq in range(-radius, radius + 1):
		var r_min: int = max(-radius, -dq - radius)
		var r_max: int = min(radius, -dq + radius)
		for dr in range(r_min, r_max + 1):
			result.append(center + Vector2i(dq, dr))
	return result


static func world_position_of(hex: Vector2i, hex_size: float) -> Vector2:
	var x := hex_size * (sqrt(3.0) * hex.x + sqrt(3.0) / 2.0 * hex.y)
	var y := hex_size * (3.0 / 2.0 * hex.y)
	return Vector2(x, y)


# Inverse of world_position_of, snapped to the nearest hex via cube rounding
# (plain float->int rounding of q/r independently picks the wrong hex near
# edges — cube rounding is the standard fix).
static func hex_at_world(point: Vector2, hex_size: float) -> Vector2i:
	var frac_q := (sqrt(3.0) / 3.0 * point.x - 1.0 / 3.0 * point.y) / hex_size
	var frac_r := (2.0 / 3.0 * point.y) / hex_size
	return _round_to_hex(frac_q, frac_r)


static func _round_to_hex(frac_q: float, frac_r: float) -> Vector2i:
	var x := frac_q
	var z := frac_r
	var y := -x - z
	var rx: float = round(x)
	var ry: float = round(y)
	var rz: float = round(z)
	var x_diff: float = abs(rx - x)
	var y_diff: float = abs(ry - y)
	var z_diff: float = abs(rz - z)
	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector2i(int(rx), int(rz))
