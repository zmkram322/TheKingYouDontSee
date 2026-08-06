class_name StatGraph
extends Control

# The numbers driving one person, over time — the thing you actually watch to
# tell whether something is behaving. Two kinds of line:
#
#   Stats      — what's true about him. Adenosine, later hunger.
#   Utilities  — what each action was worth in the last pass, which is the
#                decision itself rather than its outcome.
#
# They belong on one chart, not two, because they're on the same scale on
# purpose: Sleep's utility IS his adenosine, and a pull is priced against the
# same points. So "he fell asleep" stops being a state change you infer and
# becomes a crossing you watch — adenosine rising through StayUp's flat 45, and
# later falling through Wake's flat 10. Splitting them across two panels would
# mean eyeballing between charts to see the one thing worth seeing.
#
# It is not a debug tool. Reading a number move and knowing why is the whole
# design medium here.
#
# Dropping it in: the root is a Control, so in a 3D scene it needs a
# CanvasLayer parent, and the node's own header line in the .tscn needs
# `node_paths=PackedStringArray("person")` or `person` silently loads as null.
# Then set `person` and that's the whole of the wiring — it discovers what to
# plot by asking, so a stat or an action added tomorrow appears on its own.
#
# Read-only, always. It never writes anything back.

const MARGIN_LEFT := 40.0
const MARGIN_RIGHT := 10.0
const MARGIN_TOP := 20.0
const MARGIN_BOTTOM := 34.0

# Enough distinct hues to tell a handful of lines apart. Stats and utilities
# draw from one list so no two lines anywhere share a colour.
const TRACK_COLORS: Array[Color] = [
	Color(0.98, 0.62, 0.25),   # amber
	Color(0.40, 0.78, 0.95),   # sky
	Color(0.55, 0.85, 0.45),   # green
	Color(0.92, 0.45, 0.60),   # rose
	Color(0.72, 0.60, 0.95),   # violet
	Color(0.95, 0.88, 0.40),   # straw
	Color(0.45, 0.90, 0.80),   # teal
	Color(0.90, 0.55, 0.35),   # clay
]

const STAT_WIDTH := 2.0
const UTILITY_WIDTH := 1.0

const BACKGROUND := Color(0.09, 0.10, 0.13, 0.88)
const GRID := Color(1.0, 1.0, 1.0, 0.09)
const AXIS_TEXT := Color(0.72, 0.75, 0.80)
const ASLEEP_BAND := Color(0.35, 0.42, 0.70, 0.22)

@export var person: Person

# What's shown. Both on by default, so one panel gives you the crossings — the
# adenosine line rising through StayUp's flat 45 is the decision itself.
#
# Turning one off is how you get two panels instead: instance this twice, one
# with utilities off and one with stats off. Worth doing once there are enough
# lines that they crowd each other, since the two answer different questions —
# stats are what's true about him, utilities are what he's weighing.
@export var show_stats := true
@export var show_utilities := true

# What the panel calls itself. Blank means his name, which is right when
# there's one panel and ambiguous the moment there are two.
@export var title := ""

# How much history is on screen at once. Fills up over this many seconds, then
# scrolls.
@export_range(5.0, 600.0, 1.0, "or_greater") var window_seconds := 60.0

# How often a reading is taken. Higher is smoother and costs more memory;
# what's stored is window_seconds × this, per line.
@export_range(1.0, 60.0, 1.0) var samples_per_second := 10.0

# Shade the background while he's asleep. Being awake isn't a stat he carries
# (it's worked out from what he's doing), so it can't be drawn as a line off
# the stat list. A band behind everything is the better read anyway: you want
# to see what the numbers did DURING the night.
@export var show_asleep_band := true

var _stats := {}                 # StringName -> Array[float], oldest first
var _utilities := {}             # StringName -> Array[float], NAN = wasn't on the ballot
var _asleep: Array[bool] = []
var _seconds_owed := 0.0


func _ready() -> void:
	if person == null:
		push_warning("StatGraph has nobody to watch — set `person`")


func _process(delta: float) -> void:
	if person == null:
		return
	var interval := 1.0 / samples_per_second
	_seconds_owed += delta
	# Capped so a long stall can't spend the next frame taking ten thousand
	# identical readings.
	var allowed := int(samples_per_second)
	while _seconds_owed >= interval and allowed > 0:
		_seconds_owed -= interval
		allowed -= 1
		_take_sample()
	queue_redraw()


func _take_sample() -> void:
	var capacity := int(window_seconds * samples_per_second)

	if show_stats:
		for stat_name in person.stats.get_stat_names():
			var value: Variant = person.stats.get_stat(stat_name)
			# Yes/no stats have no place on a line — they'd read as a square
			# wave between 0 and 1 and squash every real number against the
			# axis.
			if not (value is float or value is int):
				continue
			_push(_stats, stat_name, float(value), capacity)

	if show_utilities:
		var scores := person.brain.get_last_scores()
		for action_name in scores:
			_push(_utilities, action_name, scores[action_name], capacity)

	_asleep.append(not person.brain.is_awake())
	while _asleep.size() > capacity:
		_asleep.pop_front()


func _push(into: Dictionary, key: StringName, value: float, capacity: int) -> void:
	if not into.has(key):
		into[key] = [] as Array[float]
	var samples: Array = into[key]
	samples.append(value)
	while samples.size() > capacity:
		samples.pop_front()


# Clear the history and start again — for when you've changed a number and want
# to see the new shape without the old one still on screen.
func reset() -> void:
	_stats.clear()
	_utilities.clear()
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

	var color_index := 0
	for stat_name in _stats:
		_draw_track(plot, _stats[stat_name], top, _color_at(color_index), STAT_WIDTH)
		color_index += 1
	for action_name in _utilities:
		_draw_track(plot, _utilities[action_name], top, _color_at(color_index), UTILITY_WIDTH)
		color_index += 1

	_draw_labels()


func _color_at(index: int) -> Color:
	return TRACK_COLORS[index % TRACK_COLORS.size()]


# The top of the y axis, rounded up to something round so the gridlines land on
# readable numbers. Never zero, or an empty graph divides by nothing. NANs are
# skipped — an action off the ballot has no value to scale against.
func _get_top_of_scale() -> float:
	var highest := 1.0
	for samples in _stats.values():
		for value in samples:
			highest = maxf(highest, value)
	for samples in _utilities.values():
		for value in samples:
			if not is_nan(value):
				highest = maxf(highest, value)
	var step: float = pow(10.0, floorf(log(highest) / log(10.0)))
	return ceilf(highest / step) * step


func _draw_grid(plot: Rect2, top: float) -> void:
	var font := ThemeDB.fallback_font
	for i in 5:
		var fraction := i / 4.0
		var y := plot.position.y + plot.size.y * fraction
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), GRID, 1.0)
		draw_string(font, Vector2(4.0, y + 4.0), "%.0f" % (top * (1.0 - fraction)),
			HORIZONTAL_ALIGNMENT_LEFT, MARGIN_LEFT - 8.0, 10, AXIS_TEXT)


# Shaded stretches behind everything else, one per unbroken run of sleep. Drawn
# from the same sample history as the lines, so the shading and the numbers can
# never disagree about when he was out.
func _draw_asleep_band(plot: Rect2) -> void:
	if _asleep.size() < 2:
		return
	var step := plot.size.x / float(int(window_seconds * samples_per_second) - 1)
	var run_start := -1
	for i in _asleep.size():
		if _asleep[i] and run_start < 0:
			run_start = i
		elif not _asleep[i] and run_start >= 0:
			_draw_band(plot, run_start, i, step)
			run_start = -1
	if run_start >= 0:
		_draw_band(plot, run_start, _asleep.size(), step)


func _draw_band(plot: Rect2, from_index: int, to_index: int, step: float) -> void:
	var left := plot.position.x + from_index * step
	var width := maxf((to_index - from_index) * step, 1.0)
	draw_rect(Rect2(Vector2(left, plot.position.y), Vector2(width, plot.size.y)), ASLEEP_BAND)


# Drawn in unbroken runs rather than as one line, so a NAN — an action that
# wasn't on the ballot — leaves a real gap instead of a stroke down to zero. A
# gap is the honest picture: Wake isn't worth nothing while he's up, it isn't
# being considered at all.
func _draw_track(plot: Rect2, samples: Array, top: float, color: Color, width: float) -> void:
	var step := plot.size.x / float(int(window_seconds * samples_per_second) - 1)
	var run := PackedVector2Array()
	for i in samples.size():
		var value: float = samples[i]
		if is_nan(value):
			if run.size() >= 2:
				draw_polyline(run, color, width, true)
			run = PackedVector2Array()
			continue
		run.append(Vector2(
			plot.position.x + i * step,
			plot.end.y - (value / top) * plot.size.y))
	if run.size() >= 2:
		draw_polyline(run, color, width, true)


# The person's name, then a swatch and current reading per line. Readings come
# from the last sample rather than being asked for fresh, so the number under
# the legend is the same number the end of the line is showing. Wraps onto a
# second row rather than running off the edge.
func _draw_labels() -> void:
	var font := ThemeDB.fallback_font
	var heading := title
	if heading.is_empty():
		heading = person.person_name if person != null else "(nobody)"
	draw_string(font, Vector2(MARGIN_LEFT, 14.0), heading,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, AXIS_TEXT)

	var x := MARGIN_LEFT
	var y := size.y - 18.0
	var color_index := 0
	for entry in [_stats, _utilities]:
		for key in entry:
			var samples: Array = entry[key]
			var latest: float = samples[-1] if not samples.is_empty() else NAN
			var text := "%s —" % key if is_nan(latest) else "%s %.1f" % [key, latest]
			var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			if x + text_width + 14.0 > size.x - MARGIN_RIGHT:
				x = MARGIN_LEFT
				y += 13.0
			var color := _color_at(color_index)
			draw_rect(Rect2(Vector2(x, y - 7.0), Vector2(7.0, 7.0)), color)
			draw_string(font, Vector2(x + 10.0, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
			x += 10.0 + text_width + 12.0
			color_index += 1
