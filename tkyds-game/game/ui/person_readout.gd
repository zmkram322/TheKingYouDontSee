class_name PersonReadout
extends PanelContainer

# One man, read closely, in a corner that doesn't move.
#
# The Label3D over a person's head is the right place for WHO HE IS — you need
# that at a glance, for everybody, while they walk around. It is the wrong place
# for detail: it shrinks with distance, turns side-on, hides behind things, and
# at thirteen people a stat list over every head is soup. So the two split. The
# name plate follows him; this stays still and says everything.
#
# It also carries the CLOCK, which nothing on screen showed until now. Every
# number in this project is denominated in world hours, and until this panel
# existed the only way to find out what hour it actually was in a running game
# was to pump the simulation in a script and print it. A day and a time, in the
# corner, is most of what makes the rest of the readout mean anything — "asleep"
# says very little; "asleep, and it is 09:17" says the schedule has drifted.
#
# Dropping it in: the root is a Control, so in a 3D scene it needs a CanvasLayer
# parent, and the node's own header line in the .tscn needs
# `node_paths=PackedStringArray("person", "clock")` or both silently load as
# null. Same trap as StatGraph, same fix.
#
# Read-only, always. It never writes anything back.

const TEXT_COLOR := Color(0.88, 0.90, 0.94)
const CLOCK_COLOR := Color(0.98, 0.82, 0.45)
const PADDING := 12

@export var person: Person
@export var clock: Clock

# Big enough to read from across the room while you drag something with the
# other hand, which is the actual use.
@export var font_size := 16

var _clock_line: Label
var _detail: Label


func _ready() -> void:
	# Says so out loud rather than sitting there empty. A panel with nobody to
	# watch looks exactly like a panel watching a man who is doing nothing.
	if person == null:
		push_warning("PersonReadout has nobody to watch")
	if clock == null:
		push_warning("PersonReadout has no Clock — it will not say what time it is")
	_build()


# Built here rather than authored in the .tscn so the scene stays one node and
# the layout can't drift out of step with what the text expects.
func _build() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, PADDING)
	add_child(margin)

	var rows := VBoxContainer.new()
	margin.add_child(rows)

	_clock_line = Label.new()
	_clock_line.add_theme_font_size_override("font_size", font_size + 2)
	_clock_line.add_theme_color_override("font_color", CLOCK_COLOR)
	rows.add_child(_clock_line)

	_detail = Label.new()
	_detail.add_theme_font_size_override("font_size", font_size)
	_detail.add_theme_color_override("font_color", TEXT_COLOR)
	rows.add_child(_detail)


# Redrawn every frame the eye sees, deliberately — NOT once per simulated tick.
# Presentation follows the frame rate, not the clock: fold this into anything a
# harness pumps and a thousand pumped ticks would rebuild a label a thousand
# times for nobody, and the day Population thinks for him every fourth frame the
# text here would freeze between thoughts.
func _process(_delta: float) -> void:
	if clock != null:
		_clock_line.text = clock.get_text()
	# Read through is_instance_valid, always: queue_free() does not null your
	# reference, so `== null` stays false and the next property read errors. A
	# panel is exactly the kind of thing left pointing at somebody who died.
	if person == null or not is_instance_valid(person):
		return
	_detail.text = person.get_readout_text()
