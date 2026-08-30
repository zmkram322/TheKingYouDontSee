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
const AimedAction := preload("res://workbench/exchanges/aimed_action.gd")
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

# NO GESTURE TIMER LIVES HERE ANY MORE. There used to be a gesture_seconds in
# REAL seconds that dropped the greeter back to idle, and it was a second number
# racing the exchange's own length — at 60 s/day the 1.6 s timer beat a 1 world
# hour exchange by nearly a second, so the wave died while both men were still
# held. The exchange owns how long it runs and hands both of them back when it
# ends (see exchange_broker.end). One number, read twice.

var _eye: Camera3D
var _actor: Person
var _watching: Node
var _rows: Array[Control] = []
var _shown: Array = []


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


func _process(_delta: float) -> void:
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
#
# AN EXCHANGE ALREADY UNDER WAY OFFERS NOTHING, AND THAT IS W10's ONE HARD LINE.
# The reveal — the wave, the beat, the reply — is presentation over an answer that
# was decided at the ask, and W10 is explicit about what may not happen during it:
# *"it must not be interactive. The moment the player can do something during the
# animation that changes the outcome, the answer was not decided at the ask."* An
# arc full of pressable verbs over a man mid-wave is exactly that, and it is what
# it looked like: greet him and his other verbs appeared before he had finished
# waving back.
#
# ASKED OF THE BROKER, NOT WORKED OUT HERE. "Is he free to be spoken to" is the
# same question begin() already refuses on, so there is one answer in one place
# and the arc cannot offer a row that pressing would silently decline.
func _get_open_exchanges(target: Node3D) -> Array:
	var open: Array = []
	if _actor.brain == null:
		return open
	if not _both_are_free_to_talk(target):
		return open
	for action in _actor.brain.get_known_actions():
		# AimedAction, NOT ExchangeAction, and that one word is the whole
		# generalisation: the arc draws what can be aimed at whatever you are
		# looking at, and an exchange is one KIND of that. A verb aimed at a
		# basket and a verb aimed at a man now sit on the same arc with no branch
		# anywhere in this file — and each one carries its own reach band, which
		# is what lets hailing reach across a field while handing bread over does
		# not.
		var aimed := action as AimedAction
		if aimed == null:
			continue
		if not aimed.is_available_to(_actor):
			continue
		if not aimed.is_available_toward(_actor, target):
			continue
		# The one wire an exchange cannot get for itself: an Action instanced
		# under a Brain has no path to a scene-level node. Set here, every frame,
		# rather than in _ready — the arc is the only thing that knows both.
		var exchange := aimed as ExchangeAction
		if exchange != null:
			exchange.broker = broker
		open.append(aimed)
	return open


# Neither of them mid-anything. BOTH, not just the target: a man already talking
# to somebody else cannot start a second conversation either, and drawing him an
# arc while he is halfway through his own wave is the same lie pointed the other
# way.
func _both_are_free_to_talk(target: Node3D) -> bool:
	if broker == null:
		return false
	if broker.call(&"is_in_an_exchange", _actor):
		return false
	# Only a PERSON can be mid-conversation. A basket is never busy, and asking
	# the broker about one would be asking a question with no meaning rather than
	# one with a false answer.
	var man := target as Person
	if man == null:
		return true
	return not broker.call(&"is_in_an_exchange", man)


# Null is a real answer and means "nobody" — the arc draws nothing, which is
# the honest picture rather than a stale target left up from last frame.
func _get_target() -> Node3D:
	if _watching == null or not _watching.has_method(&"get_looked_at"):
		return null
	var found: Variant = _watching.call(&"get_looked_at")
	return found as Node3D


func _rebuild(open: Array) -> void:
	_clear()
	_shown = open
	for exchange in open:
		_rows.append(_draw_one(exchange))


# One row, built entirely out of what the Action carries. The icon is used if
# somebody authored one, and a coloured disc stands in until somebody does —
# neither branch asks what the verb is.
func _draw_one(exchange: AimedAction) -> Control:
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


# PRESSING ONE. The arc reaches the verb only through perform() — it does not
# know what an exchange is, what a basket is, or which of the two it just fired.
# That is the payoff of the AimedAction split: adding a verb aimed at a door, a
# cart or a barrel is a scene, not a change to this file.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var target := _get_target()
	if target == null:
		return
	for row in _shown:
		var aimed := row as AimedAction
		if aimed == null or aimed.shortcut.is_empty():
			continue
		if key.keycode != OS.find_keycode_from_string(aimed.shortcut):
			continue
		_fire(aimed, target)
		get_viewport().set_input_as_handled()
		return


func _fire(aimed: AimedAction, target: Node3D) -> void:
	# The bid first. Decision 33: a command is a bid, never an override —
	# choose_verb hands a candidate to the ballot and nothing more. When an
	# exchange opens, the broker overwrites current_action for both men a moment
	# later (_start_performing); for a take there is no exchange and the bid is all
	# there is, which is exactly what makes him reach out for the loaf.
	var brain: Node = _actor.brain
	if brain != null and brain.has_method(&"choose_verb"):
		brain.call(&"choose_verb", aimed)

	# WHAT THIS FILE STILL DOES NOT DO: it does not hold anybody, it does not know
	# that being in an exchange stops a man thinking, and it does not move a single
	# loaf. A UI that could freeze a brain directly would be a second way to
	# suspend somebody, and a second way is a second place for a man to get stuck.
	if not aimed.perform(_actor, target):
		# Refused, and legitimately — one of them is already talking, or the basket
		# emptied between the frame that drew the row and the key going down.
		print("REFUSED — %s could not %s toward %s" % [
			_actor.person_name, aimed.label, target.name])
		if brain != null and brain.has_method(&"stop_doing_anything"):
			brain.call(&"stop_doing_anything")
		return
	print("DID — %s: %s toward %s" % [_actor.person_name, aimed.label, target.name])
