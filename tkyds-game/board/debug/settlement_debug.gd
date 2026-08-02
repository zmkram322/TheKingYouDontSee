extends Node2D

# Visual verification harness for one settlement layout, the micro-hex
# counterpart to board_debug.gd. Reads the board ONLY through
# SettlementLayout's narrow accessors (occupied_micro_hexes, is_occupied,
# template_at, tags_at, instance_at, cast_slots_of, all_instances),
# SettlementGenerator's two public entry points (grow_settlement,
# disc_radius_for), SettlementTemplate's public library readers (names,
# has_template, ...), and Hex's static geometry helpers — nothing reaches
# past those into either file's private storage.
#
# Run with F6 (this scene set as the one to run), or:
#   Godot --path tkyds-game res://board/debug/settlement_debug.tscn
#
# Controls:
#   Left click        — inspect the micro-hex under the cursor
#   Mouse wheel        — zoom toward the cursor
#   Middle/right drag  — pan
#   Seed / Size / Wealth fields + Regenerate button — regrow the settlement

const HEX_PIXEL_SIZE := 20.0

const DEFAULT_SEED := 12345
const DEFAULT_SIZE := SettlementGenerator.SettlementSize.VILLAGE
const DEFAULT_WEALTH := 0.5

const SIZE_NAMES := ["HAMLET", "VILLAGE", "TOWN"]

const MIN_ZOOM := 0.1
const MAX_ZOOM := 8.0
const ZOOM_STEP := 1.1
const INITIAL_ZOOM := Vector2(1.4, 1.4)

const OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const OUTLINE_WIDTH := 1.0
const SELECTED_OUTLINE_COLOR := Color(1.0, 1.0, 0.0, 0.9)
const SELECTED_OUTLINE_WIDTH := 3.0
const EMPTY_MICRO_HEX_COLOR := Color(0.85, 0.85, 0.80)

const BOUNDARY_COLOR := Color(0.5, 0.5, 0.5, 0.6)
const BOUNDARY_DASH_LENGTH := 6.0
const BOUNDARY_WIDTH := 1.5

const ANCHOR_DOT_COLOR := Color(0.0, 0.0, 0.0, 0.75)
const ANCHOR_DOT_RADIUS := 3.5

# How far an instance's fill color drifts from its template's base color,
# picked deterministically from the instance's anchor — this is what makes
# two adjacent cottages read as separate buildings instead of one blob.
const INSTANCE_BRIGHTNESS_VARIANCE := 0.18

const TEMPLATE_COLORS := {
	"tavern": Color(0.75, 0.15, 0.15),
	"town_square": Color(0.65, 0.65, 0.62),
	"cottage": Color(0.45, 0.28, 0.12),
	"church": Color(0.45, 0.35, 0.50),
	"market_stall": Color(0.90, 0.50, 0.10),
	"well": Color(0.15, 0.45, 0.85),
	"field": Color(0.85, 0.75, 0.25),
}
const FALLBACK_TEMPLATE_COLOR := Color(0.9, 0.1, 0.7)

const DEFAULT_INSPECTOR_TEXT := "Click a micro-hex to inspect it."

var _layout: SettlementLayout
var _current_size: SettlementGenerator.SettlementSize = DEFAULT_SIZE
var _selected_hex: Variant = null  # Vector2i once a hex has been clicked, else null

var _camera: Camera2D
var _seed_field: LineEdit
var _size_dropdown: OptionButton
var _wealth_slider: HSlider
var _wealth_value_label: Label
var _inspector_label: Label

var _panning := false

@onready var _ui_layer: CanvasLayer = $UI


func _ready() -> void:
	_camera = Camera2D.new()
	_camera.zoom = INITIAL_ZOOM
	add_child(_camera)
	_camera.make_current()

	_build_ui()
	_generate(DEFAULT_SEED, DEFAULT_SIZE, DEFAULT_WEALTH)


func _generate(seed_value: int, size: SettlementGenerator.SettlementSize, wealth: float) -> void:
	_layout = SettlementGenerator.grow_settlement(seed_value, size, wealth)
	_current_size = size
	_selected_hex = null
	_inspector_label.text = DEFAULT_INSPECTOR_TEXT
	_camera.position = Vector2.ZERO
	_camera.zoom = INITIAL_ZOOM
	queue_redraw()


# --- UI -----------------------------------------------------------------

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(8, 8)
	_ui_layer.add_child(panel)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	panel.add_child(columns)

	columns.add_child(_build_controls_column())
	columns.add_child(_build_legend_column())
	columns.add_child(_build_inspector_column())


func _build_controls_column() -> VBoxContainer:
	var column := VBoxContainer.new()

	var seed_row := HBoxContainer.new()
	column.add_child(seed_row)
	var seed_label := Label.new()
	seed_label.text = "Seed:"
	seed_row.add_child(seed_label)
	_seed_field = LineEdit.new()
	_seed_field.text = str(DEFAULT_SEED)
	_seed_field.custom_minimum_size = Vector2(90, 0)
	seed_row.add_child(_seed_field)

	var size_row := HBoxContainer.new()
	column.add_child(size_row)
	var size_label := Label.new()
	size_label.text = "Size:"
	size_row.add_child(size_label)
	_size_dropdown = OptionButton.new()
	for size_name in SIZE_NAMES:
		_size_dropdown.add_item(size_name)
	_size_dropdown.select(int(DEFAULT_SIZE))
	size_row.add_child(_size_dropdown)

	var wealth_row := HBoxContainer.new()
	column.add_child(wealth_row)
	var wealth_label := Label.new()
	wealth_label.text = "Wealth:"
	wealth_row.add_child(wealth_label)
	_wealth_slider = HSlider.new()
	_wealth_slider.min_value = 0.0
	_wealth_slider.max_value = 1.0
	_wealth_slider.step = 0.01
	_wealth_slider.value = DEFAULT_WEALTH
	_wealth_slider.custom_minimum_size = Vector2(120, 0)
	_wealth_slider.value_changed.connect(_on_wealth_changed)
	wealth_row.add_child(_wealth_slider)
	_wealth_value_label = Label.new()
	_wealth_value_label.text = "%.2f" % DEFAULT_WEALTH
	_wealth_value_label.custom_minimum_size = Vector2(36, 0)
	wealth_row.add_child(_wealth_value_label)

	var regenerate_button := Button.new()
	regenerate_button.text = "Regenerate"
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	column.add_child(regenerate_button)

	return column


func _build_legend_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	var title := Label.new()
	title.text = "Legend"
	column.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	column.add_child(grid)

	for template_name: String in SettlementTemplate.names():
		var color: Color = TEMPLATE_COLORS.get(template_name, FALLBACK_TEMPLATE_COLOR)
		_add_legend_row(grid, color, template_name)

	var anchor_note := Label.new()
	anchor_note.text = "Dark dot = instance anchor"
	column.add_child(anchor_note)
	var brightness_note := Label.new()
	brightness_note.text = "(brightness varies per instance)"
	column.add_child(brightness_note)
	var boundary_note := Label.new()
	boundary_note.text = "Grey dashed ring = disc boundary"
	column.add_child(boundary_note)

	return column


func _add_legend_row(grid: GridContainer, color: Color, text: String) -> void:
	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = Vector2(12, 12)
	grid.add_child(swatch)
	var label := Label.new()
	label.text = text
	grid.add_child(label)


func _build_inspector_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	var title := Label.new()
	title.text = "Inspector"
	column.add_child(title)
	_inspector_label = Label.new()
	_inspector_label.text = DEFAULT_INSPECTOR_TEXT
	_inspector_label.custom_minimum_size = Vector2(240, 0)
	_inspector_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	column.add_child(_inspector_label)
	return column


func _on_wealth_changed(value: float) -> void:
	_wealth_value_label.text = "%.2f" % value


func _on_regenerate_pressed() -> void:
	var seed_text := _seed_field.text.strip_edges()
	var seed_value: int = DEFAULT_SEED
	if seed_text.is_valid_int():
		seed_value = int(seed_text)
	var size_index: int = _size_dropdown.selected
	var size: SettlementGenerator.SettlementSize = size_index as SettlementGenerator.SettlementSize
	var wealth: float = float(_wealth_slider.value)
	_generate(seed_value, size, wealth)


# --- Picking, pan, zoom ----------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(get_global_mouse_position(), ZOOM_STEP)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(get_global_mouse_position(), 1.0 / ZOOM_STEP)
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_select_hex_at(get_global_mouse_position())
		elif mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			_panning = mb.pressed
	elif event is InputEventMouseMotion and _panning:
		var mm := event as InputEventMouseMotion
		_camera.position -= mm.relative / _camera.zoom


func _zoom_at(world_point: Vector2, factor: float) -> void:
	var old_zoom: Vector2 = _camera.zoom
	var new_zoom_x: float = clampf(old_zoom.x * factor, MIN_ZOOM, MAX_ZOOM)
	var new_zoom_y: float = clampf(old_zoom.y * factor, MIN_ZOOM, MAX_ZOOM)
	var applied_factor: float = new_zoom_x / old_zoom.x
	_camera.position = world_point + (_camera.position - world_point) / applied_factor
	_camera.zoom = Vector2(new_zoom_x, new_zoom_y)


func _select_hex_at(world_point: Vector2) -> void:
	if _layout == null:
		return
	var local_point := to_local(world_point)
	var hex := Hex.hex_at_world(local_point, HEX_PIXEL_SIZE)
	_selected_hex = hex

	if not _layout.is_occupied(hex):
		_inspector_label.text = "Micro-hex (%d, %d)\n(empty — no building here)" % [hex.x, hex.y]
		queue_redraw()
		return

	var instance: Dictionary = _layout.instance_at(hex)
	var template_name: String = String(instance["template"])
	var anchor: Vector2i = instance["anchor"]
	var capacity: int = instance["capacity"]
	var cast_slots: Dictionary = _layout.cast_slots_of(instance)
	var tags: PackedStringArray = _layout.tags_at(hex)

	var cast_slots_text: String
	if cast_slots.is_empty():
		cast_slots_text = "(none)"
	else:
		var parts: Array[String] = []
		for role: String in cast_slots:
			parts.append("%s: %d" % [role, int(cast_slots[role])])
		cast_slots_text = ", ".join(parts)

	var tags_text: String
	if tags.size() > 0:
		tags_text = ", ".join(tags)
	else:
		tags_text = "(none)"

	_inspector_label.text = "Micro-hex (%d, %d)\nTemplate: %s\nInstance anchor: (%d, %d)\nCapacity: %d\nCast slots: %s\nTags: %s" % [
		hex.x, hex.y, template_name, anchor.x, anchor.y, capacity, cast_slots_text, tags_text,
	]
	queue_redraw()


# --- Rendering ---------------------------------------------------------

func _draw() -> void:
	if _layout == null:
		return

	var radius: int = SettlementGenerator.disc_radius_for(_current_size)
	for hex in Hex.hexes_within(Vector2i.ZERO, radius):
		if _layout.is_occupied(hex):
			continue
		var empty_center := Hex.world_position_of(hex, HEX_PIXEL_SIZE)
		var empty_corners := _hex_corners(empty_center)
		draw_colored_polygon(empty_corners, EMPTY_MICRO_HEX_COLOR)
		var closed_empty := empty_corners.duplicate()
		closed_empty.append(empty_corners[0])
		draw_polyline(closed_empty, OUTLINE_COLOR, OUTLINE_WIDTH)

	for hex in _layout.occupied_micro_hexes():
		var center := Hex.world_position_of(hex, HEX_PIXEL_SIZE)
		var corners := _hex_corners(center)

		var instance: Dictionary = _layout.instance_at(hex)
		var template_name: String = String(instance["template"])
		var anchor: Vector2i = instance["anchor"]

		var fill_color := _instance_fill_color(template_name, anchor)
		draw_colored_polygon(corners, fill_color)

		var closed_outline := corners.duplicate()
		closed_outline.append(corners[0])
		draw_polyline(closed_outline, OUTLINE_COLOR, OUTLINE_WIDTH)

		if hex == anchor:
			draw_circle(center, ANCHOR_DOT_RADIUS, ANCHOR_DOT_COLOR)

	if _selected_hex != null:
		var selected_center := Hex.world_position_of(_selected_hex, HEX_PIXEL_SIZE)
		var selected_corners := _hex_corners(selected_center)
		var closed_selected := selected_corners.duplicate()
		closed_selected.append(selected_corners[0])
		draw_polyline(closed_selected, SELECTED_OUTLINE_COLOR, SELECTED_OUTLINE_WIDTH)

	_draw_disc_boundary(radius)


func _draw_disc_boundary(radius: int) -> void:
	if radius <= 0:
		return
	var ring := Hex.ring_around(Vector2i.ZERO, radius)
	if ring.size() < 6:
		return

	# ring_around walks the boundary side by side, `radius` hexes per side —
	# the start of each side is one of the disc's six corners.
	var corner_points := PackedVector2Array()
	for side in range(6):
		var corner_hex: Vector2i = ring[side * radius]
		corner_points.append(Hex.world_position_of(corner_hex, HEX_PIXEL_SIZE))

	for i in range(6):
		var from_point: Vector2 = corner_points[i]
		var to_point: Vector2 = corner_points[(i + 1) % 6]
		draw_dashed_line(from_point, to_point, BOUNDARY_COLOR, BOUNDARY_WIDTH, BOUNDARY_DASH_LENGTH)


# Deterministic per-instance brightness drift, keyed off the instance's own
# anchor hex, so two instances of the same template never render identically
# even though they share a base color.
func _instance_fill_color(template_name: String, anchor: Vector2i) -> Color:
	var base_color: Color = TEMPLATE_COLORS.get(template_name, FALLBACK_TEMPLATE_COLOR)
	var hash_value: int = absi(hash(anchor))
	var unit: float = float(hash_value % 1000) / 1000.0  # deterministic pseudo-random in [0, 1)
	var offset: float = (unit - 0.5) * 2.0 * INSTANCE_BRIGHTNESS_VARIANCE
	if offset >= 0.0:
		return base_color.lightened(offset)
	return base_color.darkened(-offset)


# Six corners of a pointy-top hex, matching Hex.world_position_of's
# orientation (first corner points east-of-north-east, standard axial layout).
func _hex_corners(center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(6):
		var angle_deg: float = 60.0 * i - 30.0
		var angle_rad: float = deg_to_rad(angle_deg)
		points.append(center + Vector2(HEX_PIXEL_SIZE * cos(angle_rad), HEX_PIXEL_SIZE * sin(angle_rad)))
	return points
