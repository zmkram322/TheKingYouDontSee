extends Node2D

# Visual verification harness for the terrain generator, and proof that the
# generator is presentation-agnostic: this file reads the board ONLY through
# HexMap's accessors (elevation_at, water_at, biome_at, flow_direction_at,
# tags_at, all_hexes), the two public TerrainGenerator entry points, and
# SettlementPlacer.plan_settlements (planning only — this file never calls
# grow_settlement, so it never touches settlement micro-detail). If this
# renders a kingdom, the skin seam works.
#
# Run with F6 (this scene set as the one to run), or:
#   Godot --path tkyds-game res://board/debug/board_debug.tscn
#
# Controls:
#   Left click        — inspect the hex under the cursor
#   Mouse wheel        — zoom toward the cursor
#   Middle/right drag  — pan
#   Seed / Radius / Dial fields + Regenerate button — rebuild the kingdom
#   Settlements checkbox — toggle the planned-site markers on/off

const HEX_PIXEL_SIZE := 14.0

const DEFAULT_SEED := 12345
const DEFAULT_RADIUS := 24
const DEFAULT_DIAL := 0.5

const MIN_ZOOM := 0.05
const MAX_ZOOM := 8.0
const ZOOM_STEP := 1.1
const INITIAL_ZOOM := Vector2(0.55, 0.55)

const OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const OUTLINE_WIDTH := 1.0
const SELECTED_OUTLINE_COLOR := Color(1.0, 1.0, 0.0, 0.9)
const SELECTED_OUTLINE_WIDTH := 3.0

const LAKE_COLOR := Color(0.10, 0.35, 0.85)
const RIVER_COLOR := Color(0.15, 0.45, 0.95)
const RIVER_WIDTH := 3.0

# Elevation lightens the biome fill toward white; kept under 1.0 so the
# highest hexes stay tinted rather than washing out to pure white.
const ELEVATION_LIGHTEN_STRENGTH := 0.55

const BIOME_COLORS := {
	HexMap.Biome.OCEAN: Color(0.05, 0.15, 0.45),
	HexMap.Biome.PLAINS: Color(0.55, 0.75, 0.35),
	HexMap.Biome.FOREST: Color(0.10, 0.35, 0.12),
	HexMap.Biome.HILLS: Color(0.75, 0.65, 0.40),
	HexMap.Biome.MOUNTAINS: Color(0.45, 0.40, 0.35),
	HexMap.Biome.MARSH: Color(0.35, 0.45, 0.35),
}

# Fixed offsets (in pixels, relative to hex center) so each capability tag
# always draws in the same spot inside every hex — lets the eye pattern-match
# "dot in the top-left corner = ore" across the whole map at a glance.
const TAG_OFFSETS := {
	"can_mine_ore": Vector2(-5, -5),
	"can_quarry_stone": Vector2(5, -5),
	"can_cut_lumber": Vector2(-5, 5),
	"can_grow_grain": Vector2(5, 5),
	"can_fish": Vector2(0, 0),
}
const TAG_COLORS := {
	"can_mine_ore": Color(0.05, 0.05, 0.05),
	"can_quarry_stone": Color(0.6, 0.6, 0.6),
	"can_cut_lumber": Color(0.45, 0.28, 0.12),
	"can_grow_grain": Color(0.95, 0.85, 0.2),
	"can_fish": Color(0.2, 0.9, 0.9),
}
const FALLBACK_TAG_OFFSET := Vector2(0, -9)
const FALLBACK_TAG_COLOR := Color(0.9, 0.1, 0.7)
const TAG_DOT_RADIUS := 2.2

# Planned-settlement markers: dark fill with a light halo/outline so every
# marker reads against any biome color underneath it.
const MARKER_DARK_COLOR := Color(0.05, 0.05, 0.05, 0.95)
const MARKER_LIGHT_COLOR := Color(0.95, 0.95, 0.85, 0.95)
const MARKER_ARC_SEGMENTS := 32

const HAMLET_MARKER_RADIUS := 3.0
const HAMLET_MARKER_HALO_WIDTH := 1.5

const VILLAGE_MARKER_RADIUS := 6.0
const VILLAGE_MARKER_RING_WIDTH := 2.5
const VILLAGE_MARKER_HALO_EXTRA_WIDTH := 2.0

const TOWN_MARKER_OUTER_RADIUS := 9.0
const TOWN_MARKER_INNER_RADIUS := 5.5
const TOWN_MARKER_RING_WIDTH := 2.2
const TOWN_MARKER_HALO_EXTRA_WIDTH := 2.0

const DEFAULT_INSPECTOR_TEXT := "Click a hex to inspect it."

var _map: HexMap
var _selected_hex: Variant = null  # Vector2i once a hex has been clicked, else null

# One entry per SettlementPlacer.plan_settlements() result: {hex, size,
# wealth, layout_seed}. Planning only — never fed into grow_settlement here.
var _settlement_plan: Array[Dictionary] = []
var _settlement_plan_by_hex: Dictionary = {}  # Vector2i -> plan entry, for O(1) click lookup
var _show_settlements := true

var _camera: Camera2D
var _seed_field: LineEdit
var _radius_field: SpinBox
var _dial_slider: HSlider
var _dial_value_label: Label
var _settlements_checkbox: CheckBox
var _inspector_label: Label

var _panning := false

@onready var _ui_layer: CanvasLayer = $UI


func _ready() -> void:
	_camera = Camera2D.new()
	_camera.zoom = INITIAL_ZOOM
	add_child(_camera)
	_camera.make_current()

	_build_ui()
	_generate(DEFAULT_SEED, DEFAULT_RADIUS, DEFAULT_DIAL)


func _generate(seed_value: int, radius: int, dial: float) -> void:
	_map = TerrainGenerator.generate_kingdom_with_overrides(seed_value, {
		"radius": radius,
		"dial": dial,
	})
	_settlement_plan = SettlementPlacer.plan_settlements(_map, seed_value)
	_settlement_plan_by_hex = {}
	for entry: Dictionary in _settlement_plan:
		_settlement_plan_by_hex[entry["hex"]] = entry

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

	var radius_row := HBoxContainer.new()
	column.add_child(radius_row)
	var radius_label := Label.new()
	radius_label.text = "Radius:"
	radius_row.add_child(radius_label)
	_radius_field = SpinBox.new()
	_radius_field.min_value = 1
	_radius_field.max_value = 60
	_radius_field.step = 1
	_radius_field.value = DEFAULT_RADIUS
	radius_row.add_child(_radius_field)

	var dial_row := HBoxContainer.new()
	column.add_child(dial_row)
	var dial_label := Label.new()
	dial_label.text = "Dial:"
	dial_row.add_child(dial_label)
	_dial_slider = HSlider.new()
	_dial_slider.min_value = 0.0
	_dial_slider.max_value = 1.0
	_dial_slider.step = 0.01
	_dial_slider.value = DEFAULT_DIAL
	_dial_slider.custom_minimum_size = Vector2(120, 0)
	_dial_slider.value_changed.connect(_on_dial_changed)
	dial_row.add_child(_dial_slider)
	_dial_value_label = Label.new()
	_dial_value_label.text = "%.2f" % DEFAULT_DIAL
	_dial_value_label.custom_minimum_size = Vector2(36, 0)
	dial_row.add_child(_dial_value_label)

	var regenerate_button := Button.new()
	regenerate_button.text = "Regenerate"
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	column.add_child(regenerate_button)

	_settlements_checkbox = CheckBox.new()
	_settlements_checkbox.text = "Settlements"
	_settlements_checkbox.button_pressed = true
	_settlements_checkbox.toggled.connect(_on_settlements_toggled)
	column.add_child(_settlements_checkbox)

	return column


func _build_legend_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	var title := Label.new()
	title.text = "Legend"
	column.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	column.add_child(grid)

	_add_legend_row(grid, BIOME_COLORS[HexMap.Biome.OCEAN], "Ocean")
	_add_legend_row(grid, BIOME_COLORS[HexMap.Biome.PLAINS], "Plains")
	_add_legend_row(grid, BIOME_COLORS[HexMap.Biome.FOREST], "Forest")
	_add_legend_row(grid, BIOME_COLORS[HexMap.Biome.HILLS], "Hills")
	_add_legend_row(grid, BIOME_COLORS[HexMap.Biome.MOUNTAINS], "Mountains")
	_add_legend_row(grid, BIOME_COLORS[HexMap.Biome.MARSH], "Marsh")
	_add_legend_row(grid, LAKE_COLOR, "Lake (fill)")
	_add_legend_row(grid, RIVER_COLOR, "River (line)")
	_add_legend_row(grid, TAG_COLORS["can_mine_ore"], "Ore dot")
	_add_legend_row(grid, TAG_COLORS["can_quarry_stone"], "Stone dot")
	_add_legend_row(grid, TAG_COLORS["can_cut_lumber"], "Lumber dot")
	_add_legend_row(grid, TAG_COLORS["can_grow_grain"], "Grain dot")
	_add_legend_row(grid, TAG_COLORS["can_fish"], "Fish dot")
	_add_legend_row(grid, FALLBACK_TAG_COLOR, "Other tag")
	_add_legend_row(grid, MARKER_DARK_COLOR, "Town (double ring)")
	_add_legend_row(grid, MARKER_DARK_COLOR, "Village (ring)")
	_add_legend_row(grid, MARKER_DARK_COLOR, "Hamlet (dot)")

	var note := Label.new()
	note.text = "(lighter fill = higher elevation)"
	column.add_child(note)

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
	_inspector_label.custom_minimum_size = Vector2(220, 0)
	_inspector_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	column.add_child(_inspector_label)
	return column


func _on_dial_changed(value: float) -> void:
	_dial_value_label.text = "%.2f" % value


func _on_settlements_toggled(pressed: bool) -> void:
	_show_settlements = pressed
	queue_redraw()


func _on_regenerate_pressed() -> void:
	var seed_text := _seed_field.text.strip_edges()
	var seed_value: int = DEFAULT_SEED
	if seed_text.is_valid_int():
		seed_value = int(seed_text)
	var radius: int = int(_radius_field.value)
	var dial: float = float(_dial_slider.value)
	_generate(seed_value, radius, dial)


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
	if _map == null:
		return
	var local_point := to_local(world_point)
	var hex := Hex.hex_at_world(local_point, HEX_PIXEL_SIZE)
	if not _map.has_hex(hex):
		_selected_hex = null
		_inspector_label.text = "No hex at (%d, %d)." % [hex.x, hex.y]
		queue_redraw()
		return

	_selected_hex = hex
	var elevation: float = _map.elevation_at(hex)
	var water: HexMap.Water = _map.water_at(hex)
	var biome: HexMap.Biome = _map.biome_at(hex)
	var flow: Vector2i = _map.flow_direction_at(hex)
	var tags: PackedStringArray = _map.tags_at(hex)

	var tags_text: String
	if tags.size() > 0:
		tags_text = ", ".join(tags)
	else:
		tags_text = "(none)"

	var inspector_text := "Hex (%d, %d)\nElevation: %.3f\nWater: %s\nBiome: %s\nFlow: %s\nTags: %s" % [
		hex.x, hex.y, elevation, _water_name(water), _biome_name(biome), flow, tags_text,
	]

	if _settlement_plan_by_hex.has(hex):
		var plan_entry: Dictionary = _settlement_plan_by_hex[hex]
		var size: SettlementGenerator.SettlementSize = plan_entry["size"]
		var wealth: float = plan_entry["wealth"]
		var layout_seed: int = plan_entry["layout_seed"]
		inspector_text += "\nPlanned settlement: %s\nWealth: %.2f\nLayout seed: %d" % [
			_settlement_size_name(size), wealth, layout_seed,
		]

	_inspector_label.text = inspector_text
	queue_redraw()


func _water_name(water: HexMap.Water) -> String:
	match water:
		HexMap.Water.NONE:
			return "none"
		HexMap.Water.RIVER:
			return "river"
		HexMap.Water.LAKE:
			return "lake"
		HexMap.Water.SEA:
			return "sea"
		_:
			return "unknown"


func _biome_name(biome: HexMap.Biome) -> String:
	match biome:
		HexMap.Biome.OCEAN:
			return "ocean"
		HexMap.Biome.PLAINS:
			return "plains"
		HexMap.Biome.FOREST:
			return "forest"
		HexMap.Biome.HILLS:
			return "hills"
		HexMap.Biome.MOUNTAINS:
			return "mountains"
		HexMap.Biome.MARSH:
			return "marsh"
		_:
			return "unknown"


func _settlement_size_name(size: SettlementGenerator.SettlementSize) -> String:
	match size:
		SettlementGenerator.SettlementSize.HAMLET:
			return "hamlet"
		SettlementGenerator.SettlementSize.VILLAGE:
			return "village"
		SettlementGenerator.SettlementSize.TOWN:
			return "town"
		_:
			return "unknown"


# --- Rendering ---------------------------------------------------------

func _draw() -> void:
	if _map == null:
		return

	for hex in _map.all_hexes():
		var center := Hex.world_position_of(hex, HEX_PIXEL_SIZE)
		var corners := _hex_corners(center)

		var water: HexMap.Water = _map.water_at(hex)
		var biome: HexMap.Biome = _map.biome_at(hex)
		var elevation: float = _map.elevation_at(hex)

		var fill_color: Color
		if water == HexMap.Water.LAKE:
			fill_color = LAKE_COLOR
		else:
			var base_color: Color = BIOME_COLORS[biome]
			fill_color = base_color.lightened(elevation * ELEVATION_LIGHTEN_STRENGTH)
		draw_colored_polygon(corners, fill_color)

		var closed_outline := corners.duplicate()
		closed_outline.append(corners[0])
		draw_polyline(closed_outline, OUTLINE_COLOR, OUTLINE_WIDTH)

		if water == HexMap.Water.RIVER:
			var flow: Vector2i = _map.flow_direction_at(hex)
			if flow != Vector2i.ZERO:
				var downstream_center := Hex.world_position_of(hex + flow, HEX_PIXEL_SIZE)
				draw_line(center, downstream_center, RIVER_COLOR, RIVER_WIDTH)

		for tag in _map.tags_at(hex):
			var offset: Vector2 = TAG_OFFSETS.get(tag, FALLBACK_TAG_OFFSET)
			var dot_color: Color = TAG_COLORS.get(tag, FALLBACK_TAG_COLOR)
			draw_circle(center + offset, TAG_DOT_RADIUS, dot_color)

	if _selected_hex != null and _map.has_hex(_selected_hex):
		var selected_center := Hex.world_position_of(_selected_hex, HEX_PIXEL_SIZE)
		var selected_corners := _hex_corners(selected_center)
		var closed_selected := selected_corners.duplicate()
		closed_selected.append(selected_corners[0])
		draw_polyline(closed_selected, SELECTED_OUTLINE_COLOR, SELECTED_OUTLINE_WIDTH)

	if _show_settlements:
		_draw_settlement_markers()


# Draws one marker per planned settlement site, on top of every hex fill,
# river line, and resource dot — always the topmost layer so sites never get
# lost under terrain detail.
func _draw_settlement_markers() -> void:
	for entry: Dictionary in _settlement_plan:
		var hex: Vector2i = entry["hex"]
		var size: SettlementGenerator.SettlementSize = entry["size"]
		var center := Hex.world_position_of(hex, HEX_PIXEL_SIZE)
		match size:
			SettlementGenerator.SettlementSize.TOWN:
				_draw_town_marker(center)
			SettlementGenerator.SettlementSize.VILLAGE:
				_draw_village_marker(center)
			SettlementGenerator.SettlementSize.HAMLET:
				_draw_hamlet_marker(center)


func _draw_hamlet_marker(center: Vector2) -> void:
	draw_circle(center, HAMLET_MARKER_RADIUS + HAMLET_MARKER_HALO_WIDTH, MARKER_LIGHT_COLOR)
	draw_circle(center, HAMLET_MARKER_RADIUS, MARKER_DARK_COLOR)


func _draw_village_marker(center: Vector2) -> void:
	var halo_width: float = VILLAGE_MARKER_RING_WIDTH + VILLAGE_MARKER_HALO_EXTRA_WIDTH
	draw_arc(center, VILLAGE_MARKER_RADIUS, 0.0, TAU, MARKER_ARC_SEGMENTS, MARKER_LIGHT_COLOR, halo_width, true)
	draw_arc(center, VILLAGE_MARKER_RADIUS, 0.0, TAU, MARKER_ARC_SEGMENTS, MARKER_DARK_COLOR, VILLAGE_MARKER_RING_WIDTH, true)


func _draw_town_marker(center: Vector2) -> void:
	var halo_width: float = TOWN_MARKER_RING_WIDTH + TOWN_MARKER_HALO_EXTRA_WIDTH
	draw_arc(center, TOWN_MARKER_OUTER_RADIUS, 0.0, TAU, MARKER_ARC_SEGMENTS, MARKER_LIGHT_COLOR, halo_width, true)
	draw_arc(center, TOWN_MARKER_OUTER_RADIUS, 0.0, TAU, MARKER_ARC_SEGMENTS, MARKER_DARK_COLOR, TOWN_MARKER_RING_WIDTH, true)
	draw_arc(center, TOWN_MARKER_INNER_RADIUS, 0.0, TAU, MARKER_ARC_SEGMENTS, MARKER_LIGHT_COLOR, halo_width, true)
	draw_arc(center, TOWN_MARKER_INNER_RADIUS, 0.0, TAU, MARKER_ARC_SEGMENTS, MARKER_DARK_COLOR, TOWN_MARKER_RING_WIDTH, true)


# Six corners of a pointy-top hex, matching Hex.world_position_of's
# orientation (first corner points east-of-north-east, standard axial layout).
func _hex_corners(center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(6):
		var angle_deg: float = 60.0 * i - 30.0
		var angle_rad: float = deg_to_rad(angle_deg)
		points.append(center + Vector2(HEX_PIXEL_SIZE * cos(angle_rad), HEX_PIXEL_SIZE * sin(angle_rad)))
	return points
