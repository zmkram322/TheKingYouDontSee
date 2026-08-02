class_name VillagerBody
extends Node2D

# The skin of one villager: a filled circle, their name above it, and the
# doing-label under it. That doing-label IS the print-shell for "what am I
# doing" — it just prints villager.doing_label() straight through
# ("→ inn", "working the field", "choosing…").

const RADIUS := 10.0

var villager: Villager
var color := Color.WHITE

var selected := false:
	set(value):
		if selected == value:
			return
		selected = value
		queue_redraw()

var _name_label: Label
var _doing_label: Label
var _last_doing_text := ""


func setup(new_villager: Villager, new_color: Color) -> void:
	villager = new_villager
	color = new_color
	position = villager.position

	_name_label = Label.new()
	_name_label.text = villager.actor.person_name
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.custom_minimum_size = Vector2(120, 0)
	_name_label.position = Vector2(-60, -30)
	add_child(_name_label)

	_doing_label = Label.new()
	_doing_label.add_theme_font_size_override("font_size", 11)
	_doing_label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
	_doing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_doing_label.custom_minimum_size = Vector2(160, 0)
	_doing_label.position = Vector2(-80, 14)
	add_child(_doing_label)

	_last_doing_text = villager.doing_label()
	_doing_label.text = _last_doing_text


# Cheap per-frame sync: position always, the label text only when it changed
# so we're not re-shaping a Label's glyph buffer every tick for nothing.
func refresh() -> void:
	position = villager.position
	var text := villager.doing_label()
	if text != _last_doing_text:
		_last_doing_text = text
		_doing_label.text = text


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, color)
	if selected:
		draw_arc(Vector2.ZERO, RADIUS + 4.0, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.85), 2.0)
