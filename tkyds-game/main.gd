extends Control

# Watches the food cascade breathe. Everything is built in code — no art,
# no hand-authored scene graph. Press Step to advance one tick and watch the
# demand-wave crawl down the chain and satisfaction crawl back up.

var sim := Simulation.new()

var _tick_label: Label
var _actors_box: VBoxContainer
var _demands_box: VBoxContainer
var _log_label: RichTextLabel


func _ready() -> void:
	_build_ui()
	sim.reset()
	_render()


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	# --- Top control bar ---
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	root.add_child(bar)

	_tick_label = Label.new()
	_tick_label.add_theme_font_size_override("font_size", 20)
	_tick_label.custom_minimum_size = Vector2(140, 0)
	bar.add_child(_tick_label)

	var step_btn := Button.new()
	step_btn.text = "Step (1 tick)"
	step_btn.pressed.connect(_on_step)
	bar.add_child(step_btn)

	var step5_btn := Button.new()
	step5_btn.text = "Step ×5"
	step5_btn.pressed.connect(func() -> void:
		for i in range(5):
			sim.advance_one_tick()
		_render())
	bar.add_child(step5_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Reset"
	reset_btn.pressed.connect(func() -> void:
		sim.reset()
		_render())
	bar.add_child(reset_btn)

	# Player verb buttons: intents queue and take effect on the next Step —
	# same clock as everyone else, no instant world writes from here.
	var go_pub_btn := Button.new()
	go_pub_btn.text = "Go to pub"
	go_pub_btn.pressed.connect(func() -> void:
		sim.queue_intent(&"go_to", &"pub"))
	bar.add_child(go_pub_btn)

	var go_town_btn := Button.new()
	go_town_btn.text = "Go to town"
	go_town_btn.pressed.connect(func() -> void:
		sim.queue_intent(&"go_to", &"town"))
	bar.add_child(go_town_btn)

	# --- Three panels ---
	var panels := HBoxContainer.new()
	panels.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panels.add_theme_constant_override("separation", 8)
	root.add_child(panels)

	_actors_box = _make_panel(panels, "PEOPLE", 2.0)
	_demands_box = _make_panel(panels, "OPEN DEMANDS", 2.0)

	# Event log panel (uses a RichTextLabel instead of a rebuilt list)
	var log_panel := PanelContainer.new()
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_panel.size_flags_stretch_ratio = 3.0
	panels.add_child(log_panel)
	var log_col := VBoxContainer.new()
	log_panel.add_child(log_col)
	log_col.add_child(_make_header("EVENT LOG"))
	_log_label = RichTextLabel.new()
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_label.scroll_following = true
	_log_label.bbcode_enabled = false
	log_col.add_child(_log_label)


func _make_panel(parent: Node, title: String, ratio: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = ratio
	parent.add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)
	col.add_child(_make_header(title))
	var list := VBoxContainer.new()
	list.name = "List"
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	col.add_child(list)
	return list


func _make_header(title: String) -> Label:
	var h := Label.new()
	h.text = title
	h.add_theme_font_size_override("font_size", 16)
	h.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	return h


func _on_step() -> void:
	sim.advance_one_tick()
	_render()


# --- Rendering --------------------------------------------------------------

func _render() -> void:
	_tick_label.text = "Tick: %d" % sim.tick
	_render_actors()
	_render_demands()
	_log_label.text = "\n".join(sim.log_lines)


func _render_actors() -> void:
	for c in _actors_box.get_children():
		c.queue_free()
	for a in sim.actors:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 1)

		var place: StringName = sim.stats.get_primary(a, Stat.PLACE)
		var display_name := "%s (you)" % a.person_name if a == sim.player else a.person_name
		var line := Label.new()
		line.text = "%s — [%s] %s" % [display_name, place, a.state_text]
		line.add_theme_color_override("font_color", _state_color(a))
		row.add_child(line)

		var social_label := Label.new()
		social_label.text = _social_line(a)
		social_label.add_theme_font_size_override("font_size", 12)
		social_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		row.add_child(social_label)

		var poise: float = sim.stats.get_primary(a, Stat.POISE)
		if poise < Tune.POISE_DEFAULT:
			var poise_bar := ProgressBar.new()
			poise_bar.max_value = Tune.POISE_DEFAULT
			poise_bar.value = poise
			poise_bar.show_percentage = false
			poise_bar.custom_minimum_size = Vector2(0, 6)
			row.add_child(poise_bar)

		if _eats(a):
			var bar := ProgressBar.new()
			bar.max_value = Tune.HUNGER_MAX
			bar.value = sim.stats.get_primary(a, Stat.HUNGER)
			bar.show_percentage = false
			bar.custom_minimum_size = Vector2(0, 10)
			row.add_child(bar)
		if sim.stats.get_primary(a, Stat.ROLE) == Actor.ROLE_FARM_WORKER:
			# Second bar = willingness to keep working (green = happy, red = about to quit).
			var wbar := ProgressBar.new()
			wbar.max_value = Tune.WILLINGNESS_MAX
			wbar.value = sim.stats.get_primary(a, Stat.WILLINGNESS)
			wbar.show_percentage = false
			wbar.custom_minimum_size = Vector2(0, 6)
			row.add_child(wbar)

		if a != sim.player:
			var actions := HBoxContainer.new()
			actions.add_theme_constant_override("separation", 4)
			var look_btn := Button.new()
			look_btn.text = "Look"
			look_btn.pressed.connect(func() -> void:
				sim.look(a)
				_render())
			actions.add_child(look_btn)
			var greet_btn := Button.new()
			greet_btn.text = "Greet"
			greet_btn.pressed.connect(func() -> void:
				sim.greet(a)
				_render())
			actions.add_child(greet_btn)
			var round_btn := Button.new()
			round_btn.text = "Round"
			round_btn.pressed.connect(func() -> void:
				sim.queue_intent(&"share_drink", a))
			actions.add_child(round_btn)
			row.add_child(actions)

		_actors_box.add_child(row)


func _social_line(a: Actor) -> String:
	var standing: float = sim.stats.get_primary(a, Stat.STANDING)
	var text := "standing %d" % int(standing)
	var seen: StringName = sim.stats.get_primary(sim.player, Stat.SEEN_RUNG, a)
	if seen != &"":
		text += "  ·  seen: %s" % seen
	return text


func _render_demands() -> void:
	for c in _demands_box.get_children():
		c.queue_free()
	if sim.demands.is_empty():
		var none := Label.new()
		none.text = "(none — everyone is satisfied)"
		none.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_demands_box.add_child(none)
		return
	for d in sim.demands:
		var lbl := Label.new()
		lbl.text = d.label()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_demands_box.add_child(lbl)


func _eats(a: Actor) -> bool:
	var role: StringName = sim.stats.get_primary(a, Stat.ROLE)
	return role == Actor.ROLE_CONSUMER or role == Actor.ROLE_FARM_WORKER


func _state_color(a: Actor) -> Color:
	if _is_press_target(a):
		return Color(1.0, 0.3, 0.3)
	if _eats(a):
		var hunger: float = sim.stats.get_primary(a, Stat.HUNGER)
		if hunger >= Tune.HUNGER_MAX:
			return Color(1.0, 0.3, 0.3)
		if hunger >= Tune.HUNGER_NEED_THRESHOLD:
			return Color(1.0, 0.7, 0.3)
		return Color(0.5, 1.0, 0.5)
	if sim.stats.get_primary(a, Stat.ROLE) == Actor.ROLE_IDLE:
		return Color(0.6, 0.6, 0.6)
	return Color(0.8, 0.85, 1.0)


func _is_press_target(a: Actor) -> bool:
	for d in sim.demands:
		if d.kind == Demand.PRESS and d.target == a and not d.satisfied:
			return true
	return false
