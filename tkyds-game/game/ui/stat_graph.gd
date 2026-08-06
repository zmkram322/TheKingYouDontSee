class_name StatGraph
extends Control

# A person's stats over time — the thing you actually watch to tell whether a
# number is behaving. Its own scene so it can be dropped into any scene and
# pointed at anybody; nothing about it is tied to the village or to Zoogs.
#
# It is not a debug tool. Reading a number move and knowing WHY is the whole
# design medium here, so this is meant to be as legible as the world is.
#
# Dropping it in: the root is a Control, so in a 3D scene it needs a
# CanvasLayer parent (see game.tscn). Then set `person` in the inspector and
# that's the whole of the wiring — it discovers what to plot by asking Stats
# what stats exist, so a stat added tomorrow shows up here on its own with
# nothing changed in this file.
#
# Read-only, always. It asks through get_stat like everything else and never
# writes anything back.

const MARGIN_LEFT := 40.0
const MARGIN_RIGHT := 10.0
const MARGIN_TOP := 20.0
const MARGIN_BOTTOM := 22.0

# Enough distinct hues to tell a handful of lines apart at a glance. More stats
# than this and they start repeating, which is the moment to think about
# grouping rather than about a longer list.
const TRACK_COLORS: Array[Color] = [
	Color(0.98, 0.62, 0.25),   # amber
	Color(0.40, 0.78, 0.95),   # sky
	Color(0.55, 0.85, 0.45),   # green
	Color(0.92, 0.45, 0.60),   # rose
	Color(0.72, 0.60, 0.95),   # violet
	Color(0.95, 0.88, 0.40),   # straw
]

const BACKGROUND := Color(0.09, 0.10, 0.13, 0.88)
const GRID := Color(1.0, 1.0, 1.0, 0.09)
const AXIS_TEXT := Color(0.72, 0.75, 0.80)
const ASLEEP_BAND := Color(0.35, 0.42, 0.70, 0.22)

@export var person: Person

# How much history is on screen at once. The graph fills up over this many
# seconds and then scrolls.
@export_range(5.0, 600.0, 1.0, "or_greater") var window_seconds := 60.0

# How often a reading is taken. Higher is smoother and costs more memory;
# what's stored is window_seconds × this, per stat.
@export_range(1.0, 60.0, 1.0) var samples_per_second := 10.0

# Shade the background while he's asleep. Being awake isn't a stat he carries
# (it's worked out from what he's doing — see Brain.is_awake), so it can't be
# drawn as a line off the stat list like everything else. A band behind the
# lines is the better read anyway: you want to see what the numbers did DURING
# the night, not a second line bouncing between two values.
@export var show_asleep_band := true

var _tracks := {}                # StringName -> Array[float], oldest first
var _asleep: Array[bool] = []
var _seconds_owed := 0.0


# Same reasoning as Daylight's: an unwired graph draws an empty panel forever
# and says nothing, which reads as "the numbers aren't moving" rather than "you
# didn't point me at anybody".
#
# Wiring `person` in a hand-written .tscn needs
# `node_paths=PackedStringArray("person")` on the node's header line — without
# it the loader hands the typed field a raw NodePath and it lands as null.
func _ready() -> void:
	if person == null:
		push_warning("StatGraph has nobody to watch — set `person`")


func _process(delta: float) -> void:
	if person == null:
		return
	var interval := 1.0 / samples_per_second
	_seconds_owed += delta
	# Capped so a long stall (a breakpoint, a slow frame) can't spend the next
	# frame taking ten thousand identical readings.
	var allowed := int(samples_per_second)
	while _seconds_owed >= interval and allowed > 0:
		_seconds_owed -= interval
		allowed -= 1
		_take_sample()
	queue_redraw()


func _take_sample() -> void:
	var capacity := int(window_seconds * samples_per_second)
	for stat_name in person.stats.get_stat_names():
		var value: Variant = person.stats.get_stat(stat_name)
		# Yes/no stats have no place on a line. They'd read as a square wave
		# between 0 and 1 and squash every real number against the axis.
		if not (value is float or value is int):
			continue
		if not _tracks.has(stat_name):
			_tracks[stat_name] = [] as Array[float]
		var samples: Array = _tracks[stat_name]
		samples.append(float(value))
		while samples.size() > capacity:
			samples.pop_front()

	_asleep.append(not person.brain.is_awake())
	while _asleep.size() > capacity:
		_asleep.pop_front()


# Clear the history and start again — for when you've changed a number and want
# to see the new shape without the old one still on screen.
func reset() -> void:
	_tracks.clear()
	_asleep.clear()
	_seconds_owed = 0.0
	queue_redraw()


# --- Drawing --------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	var plot := Rect2(
		Vector2(MARGIN_LEFT, MARGIN_TOP),
		Vector2(size.x - MARGIN_LEFT - MARGIN_RIGHT, size.y - MARGIN_TOP - MARGIN_BOTTOM))
	if plot.size.x <= 0.0 or plot.size.y <= 0.0:
		return

	var top := _get_top_of_scale()
	if show_asleep_band:
		_draw_asleep_band(plot)
	_draw_grid(plot, top)

	var index := 0
	for stat_name in _tracks:
		_draw_track(plot, _tracks[stat_name], top, TRACK_COLORS[index % TRACK_COLORS.size()])
		index += 1

	_draw_labels(plot)


# The top of the y axis, rounded up to something round so the gridlines land on
# readable numbers. Never zero, or an empty graph divides by nothing.
func _get_top_of_scale() -> float:
	var highest := 1.0
	for samples in _tracks.values():
		for value in samples:
			highest = maxf(highest, value)
	var step: float = pow(10.0, floorf(log(highest) / log(10.0)))
	return ceilf(highest / step) * step


func _draw_grid(plot: Rect2, top: float) -> void:
	var font := ThemeDB.fallback_font
	for i in 5:
		var fraction := i / 4.0
		var y := plot.position.y + plot.size.y * fraction
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), GRID, 1.0)
		var value := top * (1.0 - fraction)
		draw_string(font, Vector2(4.0, y + 4.0), "%.0f" % value,
			HORIZONTAL_ALIGNMENT_LEFT, MARGIN_LEFT - 8.0, 10, AXIS_TEXT)


# Shaded stretches behind everything else, one per unbroken run of sleep. Drawn
# from the same sample history as the lines, so the shading and the numbers can
# never disagree about when he was out.
func _draw_asleep_band(plot: Rect2) -> void:
	var capacity := int(window_seconds * samples_per_second)
	if _asleep.size() < 2:
		return
	var step := plot.size.x / float(capacity - 1)
	var run_start := -1
	for i in _asleep.size():
		if _asleep[i] and run_start < 0:
			run_start = i
		elif not _asleep[i] and run_start >= 0:
			_draw_band_from(plot, run_start, i, step)
			run_start = -1
	if run_start >= 0:
		_draw_band_from(plot, run_start, _asleep.size(), step)


func _draw_band_from(plot: Rect2, from_index: int, to_index: int, step: float) -> void:
	var left := plot.position.x + from_index * step
	var width := maxf((to_index - from_index) * step, 1.0)
	draw_rect(Rect2(Vector2(left, plot.position.y), Vector2(width, plot.size.y)), ASLEEP_BAND)


func _draw_track(plot: Rect2, samples: Array, top: float, color: Color) -> void:
	if samples.size() < 2:
		return
	var capacity := int(window_seconds * samples_per_second)
	var step := plot.size.x / float(capacity - 1)
	var points := PackedVector2Array()
	for i in samples.size():
		var value: float = samples[i]
		points.append(Vector2(
			plot.position.x + i * step,
			plot.end.y - (value / top) * plot.size.y))
	draw_polyline(points, color, 1.5, true)


# The title, and a swatch and current reading per stat. The reading is taken
# from the last sample rather than asked for fresh, so the number under the
# legend is the same number the end of the line is showing.
func _draw_labels(plot: Rect2) -> void:
	var font := ThemeDB.fallback_font
	var title := person.person_name if person != null else "(nobody)"
	draw_string(font, Vector2(MARGIN_LEFT, 14.0), title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, AXIS_TEXT)

	var x := MARGIN_LEFT
	var y := size.y - 7.0
	var index := 0
	for stat_name in _tracks:
		var color := TRACK_COLORS[index % TRACK_COLORS.size()]
		var samples: Array = _tracks[stat_name]
		var latest: float = samples[-1] if not samples.is_empty() else 0.0
		draw_rect(Rect2(Vector2(x, y - 8.0), Vector2(8.0, 8.0)), color)
		var text := "%s %.1f" % [stat_name, latest]
		draw_string(font, Vector2(x + 12.0, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
		x += 12.0 + font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 14.0
		index += 1

	if show_asleep_band and person != null and not person.brain.is_awake():
		draw_string(font, Vector2(x, y), "asleep", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, AXIS_TEXT)
