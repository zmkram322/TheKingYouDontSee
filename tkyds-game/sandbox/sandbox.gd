class_name Sandbox
extends Node2D

# The behavior sandbox's scene layer: a walkable toy world on the left, a
# utility inspector on the right. Everything here is a skin over the headless
# SandboxWorld — this file draws places and bodies and reads the brain's
# decisions back out for the inspector; it never invents behavior of its own.

const VILLAGER_COLORS := [
	Color(0.85, 0.32, 0.32),
	Color(0.30, 0.62, 0.88),
	Color(0.86, 0.68, 0.20),
	Color(0.58, 0.42, 0.85),
	Color(0.38, 0.78, 0.48),
]

var world := SandboxWorld.new()

var paused := false
var speed := 1.0

var _bodies: Array[VillagerBody] = []
var _selected: Villager = null
var _selected_body: VillagerBody = null

# --- UI refs, built once in _build_ui ---
var _time_label: Label
var _pause_button: Button
var _speed_buttons: Array[Button] = []
var _speed_values: Array[float] = [1.0, 2.0, 4.0]
var _villager_list: ItemList
var _scare_button: Button
var _doing_value_label: Label
var _plan_value_label: Label
var _stats_value_label: Label
var _live_pass_label: Label
var _last_committed_label: Label
var _log_label: RichTextLabel
var _refresh_timer: Timer


func _ready() -> void:
	world.reset()
	_build_ui()
	_build_world_markers()
	_spawn_bodies()
	_refresh_inspector()


func _process(delta: float) -> void:
	if not paused:
		world.advance(delta * speed)
	_time_label.text = "t = %.1fs" % world.time
	for body in _bodies:
		body.refresh()


# --- World skin -----------------------------------------------------------

func _build_world_markers() -> void:
	for place_name: StringName in world.places.keys():
		var pos: Vector2 = world.places[place_name]

		var marker := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = _place_color(place_name)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		marker.add_theme_stylebox_override("panel", style)
		marker.size = Vector2(44, 44)
		marker.position = pos - Vector2(22, 22)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(marker)

		var label := Label.new()
		label.text = String(place_name)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(80, 0)
		label.position = pos + Vector2(-40, 24)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)


# Muted, distinct colors per place — destination markers, not art.
func _place_color(place_name: StringName) -> Color:
	match place_name:
		&"home":
			return Color(0.52, 0.48, 0.44, 0.9)
		&"field":
			return Color(0.33, 0.52, 0.30, 0.9)
		&"inn":
			return Color(0.58, 0.44, 0.20, 0.9)
		&"well":
			return Color(0.28, 0.44, 0.60, 0.9)
		_:
			return Color(0.4, 0.4, 0.4, 0.9)


func _spawn_bodies() -> void:
	for body in _bodies:
		body.queue_free()
	_bodies.clear()
	for i in world.villagers.size():
		var v: Villager = world.villagers[i]
		var body := VillagerBody.new()
		body.setup(v, VILLAGER_COLORS[i % VILLAGER_COLORS.size()])
		add_child(body)
		_bodies.append(body)


# --- UI ---------------------------------------------------------------------

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	# Full-rect but IGNOREd so empty ground still reaches _unhandled_input for
	# click-to-select; the widgets placed on top catch their own clicks.
	var ui_root := Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui_root)

	_build_top_bar(ui_root)
	_build_right_panel(ui_root)

	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 0.25
	_refresh_timer.autostart = true
	_refresh_timer.timeout.connect(_refresh_inspector)
	add_child(_refresh_timer)


func _build_top_bar(parent: Control) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	bar.position = Vector2(8, 8)
	parent.add_child(bar)

	_time_label = Label.new()
	_time_label.custom_minimum_size = Vector2(90, 0)
	_time_label.add_theme_font_size_override("font_size", 18)
	bar.add_child(_time_label)

	_pause_button = Button.new()
	_pause_button.text = "Pause"
	_pause_button.pressed.connect(_on_pause_pressed)
	bar.add_child(_pause_button)

	for mult in _speed_values:
		var btn := Button.new()
		btn.text = "%d×" % int(mult)
		btn.toggle_mode = true
		btn.pressed.connect(_on_speed_pressed.bind(mult))
		bar.add_child(btn)
		_speed_buttons.append(btn)

	var reset_btn := Button.new()
	reset_btn.text = "Reset"
	reset_btn.pressed.connect(_on_reset_pressed)
	bar.add_child(reset_btn)

	_update_speed_buttons()


func _build_right_panel(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -340
	parent.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)

	col.add_child(_make_header("VILLAGERS"))
	_villager_list = ItemList.new()
	_villager_list.custom_minimum_size = Vector2(0, 110)
	_villager_list.item_selected.connect(_on_villager_list_selected)
	col.add_child(_villager_list)
	_rebuild_villager_list()

	_scare_button = Button.new()
	_scare_button.text = "Scare Selected"
	_scare_button.pressed.connect(_on_scare_pressed)
	col.add_child(_scare_button)

	col.add_child(HSeparator.new())

	_doing_value_label = Label.new()
	_doing_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_doing_value_label)

	_plan_value_label = Label.new()
	_plan_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_plan_value_label)

	col.add_child(HSeparator.new())
	col.add_child(_make_header("STATS"))
	_stats_value_label = Label.new()
	col.add_child(_stats_value_label)

	col.add_child(HSeparator.new())
	col.add_child(_make_header("IF THEY CHOSE RIGHT NOW"))
	_live_pass_label = Label.new()
	col.add_child(_live_pass_label)

	col.add_child(HSeparator.new())
	col.add_child(_make_header("LAST COMMITTED"))
	_last_committed_label = Label.new()
	col.add_child(_last_committed_label)
	var note := Label.new()
	note.text = "(a decision sticks until its activities finish)"
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	col.add_child(note)

	col.add_child(HSeparator.new())
	col.add_child(_make_header("LOG"))
	_log_label = RichTextLabel.new()
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_label.scroll_following = true
	_log_label.bbcode_enabled = false
	col.add_child(_log_label)


func _make_header(title: String) -> Label:
	var h := Label.new()
	h.text = title
	h.add_theme_font_size_override("font_size", 14)
	h.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	return h


func _rebuild_villager_list() -> void:
	_villager_list.clear()
	for v in world.villagers:
		_villager_list.add_item(v.actor.person_name)


# --- Top bar actions ----------------------------------------------------

func _on_pause_pressed() -> void:
	paused = not paused
	_pause_button.text = "Resume" if paused else "Pause"


func _on_speed_pressed(mult: float) -> void:
	speed = mult
	_update_speed_buttons()


func _update_speed_buttons() -> void:
	for i in _speed_buttons.size():
		_speed_buttons[i].button_pressed = is_equal_approx(_speed_values[i], speed)


func _on_reset_pressed() -> void:
	world.reset()
	_deselect()
	_spawn_bodies()
	_rebuild_villager_list()
	_refresh_inspector()


# --- Selection ------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var picked := _pick_villager_near(get_global_mouse_position())
		if picked != null:
			_select_villager(picked)
		else:
			_deselect()


func _pick_villager_near(point: Vector2) -> Villager:
	var nearest: Villager = null
	var nearest_dist := 24.0
	for v in world.villagers:
		var dist := v.position.distance_to(point)
		if dist <= nearest_dist:
			nearest_dist = dist
			nearest = v
	return nearest


func _on_scare_pressed() -> void:
	if _selected == null:
		return
	world.scare(_selected)
	_refresh_inspector()


func _on_villager_list_selected(index: int) -> void:
	if index >= 0 and index < world.villagers.size():
		_select_villager(world.villagers[index])


func _select_villager(v: Villager) -> void:
	if _selected_body != null:
		_selected_body.selected = false
	_selected = v
	_selected_body = null
	var idx := world.villagers.find(v)
	if idx >= 0:
		if idx < _bodies.size():
			_selected_body = _bodies[idx]
			_selected_body.selected = true
		_villager_list.select(idx)
	_refresh_inspector()


func _deselect() -> void:
	if _selected_body != null:
		_selected_body.selected = false
	_selected = null
	_selected_body = null
	_villager_list.deselect_all()
	_refresh_inspector()


# --- Inspector --------------------------------------------------------------

func _refresh_inspector() -> void:
	var start := maxi(0, world.log_lines.size() - 12)
	_log_label.text = "\n".join(world.log_lines.slice(start))

	if _selected == null:
		_doing_value_label.text = "Doing: (nothing selected)"
		_plan_value_label.text = "Plan: —"
		_stats_value_label.text = ""
		_live_pass_label.text = ""
		_last_committed_label.text = ""
		return

	var v := _selected
	_doing_value_label.text = "Doing: %s" % v.doing_label()
	_plan_value_label.text = "Plan: %s" % _plan_summary(v)
	_stats_value_label.text = _format_stats(v)

	var live := UtilityBrain.decide(world.stats, v.actor, world.options)
	_live_pass_label.text = _format_decision(live)

	if v.last_decision != null:
		_last_committed_label.text = _format_decision(v.last_decision)
	else:
		_last_committed_label.text = "(no decision committed yet)"


func _plan_summary(v: Villager) -> String:
	var goal := v.current_goal()
	if goal == null or not goal.started:
		return "choosing…"
	var parts: Array[String] = [goal.doing.describe()]
	for step in goal.plan:
		parts.append(step.describe())
	for i in range(1, v.goal_queue.size()):
		var queued: Goal = v.goal_queue[i]
		parts.append("[queued] " + queued.option.label)
	return ", then ".join(parts)


func _format_stats(v: Villager) -> String:
	var hunger: float = world.stats.get_primary(v.actor, Stat.HUNGER)
	var energy: float = world.stats.get_primary(v.actor, Stat.ENERGY)
	var coin: int = world.stats.get_primary(v.actor, Stat.COIN)
	var vigor: float = world.stats.get_derived(v.actor, Stat.VIGOR)
	var place: StringName = world.stats.get_primary(v.actor, Stat.PLACE)
	var fear: float = world.stats.get_primary(v.actor, Stat.FEAR)
	var threatened: bool = world.stats.get_derived(v.actor, Stat.THREATENED)
	return "hunger: %.1f\nenergy: %.1f\ncoin: %d\nvigor: %.2f\nplace: %s\nfear: %.1f\nthreatened: %s" % [hunger, energy, coin, vigor, String(place), fear, threatened]


# Same rendering for the live pass and the last committed decision so the two
# are visually comparable at a glance: one line per option, catalog order.
func _format_decision(decision: UtilityBrain.Decision) -> String:
	var lines: Array[String] = []
	for entry in decision.considered:
		var option: ActionOption = entry.option
		var eligible: bool = entry.eligible
		var marker := "▶" if option == decision.chosen else " "
		if eligible:
			lines.append("%s %6.1f  %s" % [marker, entry.score, option.label])
		else:
			lines.append("%s    —   %s  (can't attempt)" % [marker, option.label])
	return "\n".join(lines)
