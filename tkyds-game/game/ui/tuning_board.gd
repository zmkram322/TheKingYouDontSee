class_name TuningBoard
extends PanelContainer

# Sliders for every number worth dragging, built by asking the nodes what
# numbers they have. Point it at a list of nodes and it finds their exported
# floats and ints, reads the min and max out of their @export_range hints, and
# puts a labelled slider on each one.
#
# Nothing here names a knob. Add an @export to a script, or a new action to the
# library, and its numbers turn up on the board with this file unchanged —
# which is the whole point, because a board that needs a line of wiring per
# slider stops getting updated about a week in.
#
# Its own scene, like the graph, so it can be dropped anywhere. In a 3D scene
# it needs a CanvasLayer parent.
#
# Pair it with the graph: drag a number here, watch the shape change there.
# That's the loop this exists for.

# The nodes whose exported numbers become sliders, in the order they appear.
#
# Paths rather than node references because an Array[Node] export doesn't get
# its paths resolved when a scene loads — it hands you back raw NodePaths and
# fails on first use. One typed Array[NodePath] and an explicit lookup is the
# honest version of the same thing.
@export var watching: Array[NodePath] = []

@export var title := "tuning"

# Sliders for a number with no @export_range hint have to guess a range. This
# is the guess: zero to whatever multiple of its starting value.
@export var unbounded_headroom := 3.0

var _defaults := {}     # Node -> { property_name: starting value }
var _rows: Array[Dictionary] = []


func _ready() -> void:
	_build()


func _process(_delta: float) -> void:
	# Labels are refreshed rather than written once, so a number changed by
	# anything other than its own slider still reads correctly here. A board
	# that can lie about the current value is worse than no board.
	for row in _rows:
		var value: Variant = row.node.get(row.property)
		row.readout.text = "%.2f" % float(value)
		if not row.slider.has_focus():
			row.slider.set_value_no_signal(float(value))


# --- Building ---------------------------------------------------------------------

func _build() -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	scroll.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var heading := Label.new()
	heading.text = title
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var reset_button := Button.new()
	reset_button.text = "reset all"
	reset_button.pressed.connect(reset_all)
	header.add_child(reset_button)

	for path in watching:
		var node := get_node_or_null(path)
		if node == null:
			push_warning("nothing at \"%s\" — a tuning-board path is stale" % path)
			continue
		var numbers := _find_numbers(node)
		if numbers.is_empty():
			continue
		column.add_child(_make_group_label(node.name))
		_defaults[node] = {}
		for property in numbers:
			_defaults[node][property.name] = node.get(property.name)
			column.add_child(_make_row(node, property))


# Every EXPORTED number on a node's own script.
#
# Two filters and both earn their place. Only the node's own script, because a
# board offering to drag a Node3D's rotation is noise, not tuning. And only
# exported vars — PROPERTY_USAGE_SCRIPT_VARIABLE alone catches plain internal
# state too, which put Clock.seconds on the board as a slider you could drag to
# yank time sideways. An @export is the author saying "this is a number someone
# should set"; that is exactly the question this board is asking, so it's the
# right test. PROPERTY_USAGE_EDITOR is what distinguishes the two.
func _find_numbers(node: Node) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var script: Variant = node.get_script()
	if script == null:
		return found
	for property in script.get_script_property_list():
		if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if not (property.usage & PROPERTY_USAGE_EDITOR):
			continue
		if property.type != TYPE_FLOAT and property.type != TYPE_INT:
			continue
		found.append(property)
	return found


func _make_group_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.55, 0.72, 0.95))
	return label


func _make_row(node: Node, property: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var name_label := Label.new()
	name_label.text = String(property.name).replace("_", " ")
	name_label.custom_minimum_size = Vector2(190, 0)
	name_label.add_theme_font_size_override("font_size", 11)
	row.add_child(name_label)

	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(120, 0)
	var bounds := _get_bounds(node, property)
	slider.min_value = bounds.low
	slider.max_value = bounds.high
	slider.step = bounds.step
	slider.value = float(node.get(property.name))
	slider.value_changed.connect(func(value: float) -> void:
		node.set(property.name, int(value) if property.type == TYPE_INT else value))
	row.add_child(slider)

	var readout := Label.new()
	readout.custom_minimum_size = Vector2(52, 0)
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	readout.add_theme_font_size_override("font_size", 11)
	row.add_child(readout)

	_rows.append({"node": node, "property": property.name, "slider": slider, "readout": readout})
	return row


# Range comes from the @export_range hint where the author wrote one — they
# already said what sensible looks like, and second-guessing it here would mean
# two answers to the same question. Without a hint, guess from the starting
# value, which is at least in the right order of magnitude.
func _get_bounds(node: Node, property: Dictionary) -> Dictionary:
	if property.hint == PROPERTY_HINT_RANGE:
		var parts := String(property.hint_string).split(",")
		if parts.size() >= 2 and parts[0].is_valid_float() and parts[1].is_valid_float():
			var step := 0.01
			if parts.size() >= 3 and parts[2].is_valid_float():
				step = float(parts[2])
			return {"low": float(parts[0]), "high": float(parts[1]), "step": step}

	var starting := absf(float(node.get(property.name)))
	var high := maxf(starting * unbounded_headroom, 1.0)
	return {"low": 0.0, "high": high, "step": 0.01 if property.type == TYPE_FLOAT else 1.0}


# Put every number back where it started. For when you've dragged things into
# nonsense and want the baseline back without restarting.
func reset_all() -> void:
	for node in _defaults:
		for property_name in _defaults[node]:
			node.set(property_name, _defaults[node][property_name])
