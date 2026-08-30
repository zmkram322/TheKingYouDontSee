extends CanvasLayer

# The arc of things you can do to the man you are looking at.
#
# IT NAMES NO VERB, and that is the constraint it is built around rather than a
# side effect. Every row's colour, letter and picture come off the Action
# itself — the same rule that keeps the clip name on the ActionStep instead of
# in a dictionary in game/. Grep this file for "greet" and you will not find
# it; author a second exchange, drop it under the player's Brain, and it turns
# up here with its own colour and its own key.
#
# WHY A CanvasLayer AND NOT A Sprite3D over his head: a projected overlay stays
# crisp and the same size at any range, which is what "legible" asked for. The
# cost is one gotcha, handled below — unproject_position returns a MIRRORED
# point for anything behind the camera, so an unguarded overlay flips to the
# wrong side of the screen the moment you turn away. is_position_behind is the
# guard, and without it this reads as a haunted UI rather than as a bug.
#
# ONE FRAME, ONE PHASE. Population ticks brains in _process, and so does this.
# Where this node sits in the tree relative to Population decides whether a
# hold lands this frame or next; it is placed ABOVE Population in
# exchanges.tscn so the interrupt is same-frame and deterministic.

# Typed against the script rather than against Action, so swatch/icon/shortcut
# resolve at parse time. Casting each candidate through it is also what
# separates an exchange from an ordinary verb — a plain Action casts to null
# and falls out, with nothing asking what any of them are called.
const ExchangeAction := preload("res://workbench/exchanges/exchange_action.gd")

@export var watching: Node              # the LookingAt node
@export var eye: Camera3D               # the camera that does the projecting
@export var actor: Person               # whose verbs these are — the player
@export var broker: Node                # who is talking to whom

# The arc itself, in screen pixels and degrees. Authored rather than derived,
# because the only way numbers like these get picked is by looking at them.
@export var radius := 86.0
@export var spread_degrees := 78.0
@export var lifts_above_head := 1.75

# How long the greeter holds his gesture before dropping back to idle. Seconds,
# REAL ones — this is presentation, and presentation runs on the frame clock.
@export var gesture_seconds := 1.6

var _eye: Camera3D
var _actor: Person
var _watching: Node
var _rows: Array[Control] = []
var _shown: Array = []
var _gesture_left := 0.0


func _ready() -> void:
	_watching = watching
	_eye = eye
	_actor = actor
	if _watching == null:
		push_warning("the exchange arc has nothing watching for it — it will never appear")
	if _eye == null:
		push_warning("the exchange arc has no camera — it cannot place itself on screen")
	if _actor == null:
		push_warning("the exchange arc has no actor — there are no verbs to draw")


func _process(delta: float) -> void:
	_run_down_the_gesture(delta)
	var target := _get_target()
	if target == null or _eye == null or _actor == null:
		_clear()
		return
	var head := target.global_position + Vector3.UP * lifts_above_head
	# THE GUARD — see the header. Behind the camera, unproject mirrors.
	if _eye.is_position_behind(head):
		_clear()
		return
	var open := _get_open_exchanges(target)
	if open != _shown:
		_rebuild(open)
	_lay_out_on_an_arc(_eye.unproject_position(head))


# What he may do to that man: BOTH gates, asked separately, both required.
# is_available_to is the shared one every author in the game already writes;
# is_available_toward is the target half exchanges adds. Neither is skipped and
# neither is folded into the other.
func _get_open_exchanges(target: Person) -> Array:
	var open: Array = []
	if _actor.brain == null:
		return open
	for action in _actor.brain.get_known_actions():
		var exchange := action as ExchangeAction
		if exchange == null:
			continue
		if not exchange.is_available_to(_actor):
			continue
		if not exchange.is_available_toward(_actor, target):
			continue
		open.append(exchange)
	return open


# Null is a real answer and means "nobody" — the arc draws nothing, which is
# the honest picture rather than a stale target left up from last frame.
func _get_target() -> Person:
	if _watching == null or not _watching.has_method(&"get_looked_at"):
		return null
	var found: Variant = _watching.call(&"get_looked_at")
	return found as Person


func _rebuild(open: Array) -> void:
	_clear()
	_shown = open
	for exchange in open:
		_rows.append(_draw_one(exchange))


# One row, built entirely out of what the Action carries. The icon is used if
# somebody authored one, and a coloured disc stands in until somebody does —
# neither branch asks what the verb is.
func _draw_one(exchange: ExchangeAction) -> Control:
	var disc := Panel.new()
	disc.custom_minimum_size = Vector2(46, 46)
	disc.size = Vector2(46, 46)

	var skin := StyleBoxFlat.new()
	skin.bg_color = exchange.swatch
	skin.corner_radius_top_left = 23
	skin.corner_radius_top_right = 23
	skin.corner_radius_bottom_left = 23
	skin.corner_radius_bottom_right = 23
	skin.border_width_left = 2
	skin.border_width_top = 2
	skin.border_width_right = 2
	skin.border_width_bottom = 2
	skin.border_color = Color(0.0, 0.0, 0.0, 0.55)
	disc.add_theme_stylebox_override(&"panel", skin)
	add_child(disc)

	if exchange.icon != null:
		var art := TextureRect.new()
		art.texture = exchange.icon
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		disc.add_child(art)
	else:
		var key := Label.new()
		key.text = exchange.shortcut
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		key.add_theme_color_override(&"font_color", Color(0.06, 0.06, 0.06))
		key.set_anchors_preset(Control.PRESET_FULL_RECT)
		disc.add_child(key)

	var caption := Label.new()
	caption.text = "%s  [%s]" % [exchange.label, exchange.shortcut]
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	caption.add_theme_constant_override(&"outline_size", 5)
	caption.position = Vector2(-40.0, 48.0)
	caption.size = Vector2(126.0, 20.0)
	disc.add_child(caption)
	return disc


# Spread evenly across the arc, centred over his head. A lone row sits dead
# centre rather than off to one side, which is what makes a single verb read as
# "him" instead of as "something over there".
func _lay_out_on_an_arc(at: Vector2) -> void:
	var count := _rows.size()
	if count == 0:
		return
	var step := 0.0
	if count > 1:
		step = deg_to_rad(spread_degrees) / float(count - 1)
	var first := -step * float(count - 1) * 0.5
	for index in count:
		var angle := first + step * float(index)
		var row := _rows[index]
		row.position = at + Vector2(sin(angle), -cos(angle)) * radius - row.size * 0.5


func _clear() -> void:
	for row in _rows:
		if is_instance_valid(row):
			row.queue_free()
	_rows.clear()
	_shown = []


# THE INTERRUPT IS FIRED HERE. Two things happen and they are deliberately
# separate: the greeter is handed a verb through PlayerBrain's ordinary
# choose_verb — a BID, exactly as Decision 33 says, never an override — and the
# man being addressed is held. Nothing else in the game knows an exchange began.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var target := _get_target()
	if target == null:
		return
	for exchange in _shown:
		var typed := exchange as ExchangeAction
		if typed == null or typed.shortcut.is_empty():
			continue
		if key.keycode != OS.find_keycode_from_string(typed.shortcut):
			continue
		_begin(typed, target)
		get_viewport().set_input_as_handled()
		return


func _begin(exchange: ExchangeAction, target: Person) -> void:
	# Called rather than invoked directly: choose_verb lives on PlayerBrain and
	# _actor.brain is typed Brain, so a static call would not resolve. call()
	# keeps this file honest that it is talking to a fork.
	var brain: Node = _actor.brain
	if brain != null and brain.has_method(&"choose_verb"):
		brain.call(&"choose_verb", exchange)
		_gesture_left = gesture_seconds

	# THE INTERRUPT. Note what this file does NOT do: it does not hold anybody,
	# and it does not know that being in an exchange stops a man thinking. It
	# asks the broker to start a conversation; the pause is a CONSEQUENCE of
	# that conversation existing, decided in exchange_population.gd. A UI that
	# could freeze a brain directly would be a second way to suspend somebody,
	# and a second way is a second place for a man to get stuck.
	if broker == null:
		push_warning("the exchange arc has no broker — nothing can be started")
		return
	var started: Variant = broker.call(&"begin", _actor, target)
	if started == null:
		# Refused, and legitimately: he is already talking to somebody.
		print("EXCHANGE — %s is already engaged" % target.person_name)
		return
	print("EXCHANGE — %s opened %s with %s" % [
		_actor.person_name, exchange.label, target.person_name])


# Drops the gesture so he returns to idle rather than holding the last pose of
# a LOOP_NONE clip for ever. The verb is a bid that expires, not a state.
func _run_down_the_gesture(delta: float) -> void:
	if _gesture_left <= 0.0:
		return
	_gesture_left -= delta
	if _gesture_left > 0.0:
		return
	var brain: Node = null
	if _actor != null:
		brain = _actor.brain
	if brain != null and brain.has_method(&"stop_doing_anything"):
		brain.call(&"stop_doing_anything")
