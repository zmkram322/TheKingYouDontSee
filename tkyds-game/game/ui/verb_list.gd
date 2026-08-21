class_name VerbList
extends PanelContainer

# The player's ballot, drawn instead of scored (Decision 33, sub-ruling A). A
# button per action his own PlayerBrain reports open, no more and no fewer —
# whatever cleared is_available_to this tick, in the order the gate half
# handed it back. Nothing here decides which of them is worth doing; that's
# still the score every other brain uses, just not asked of this one.
#
# IT CONTAINS NO VERB NAME. A row exists because an Action's own gate said
# yes about this body, and its text is Action.label — "what this reads as
# when you're watching him", already written for exactly this. Learn a new
# Action onto the player's Brain and it appears here with this file
# unchanged; that's the whole test of whether this file still obeys its own
# rule.
#
# Its own scene, like the graph and the board, so it can be dropped anywhere.
# In a 3D scene it needs a CanvasLayer parent. The node's own header line in
# whatever .tscn drops it in needs `node_paths=PackedStringArray("person")`
# or `person` silently loads as null — this scene's own .tscn doesn't assign
# it, game.tscn does.

@export var person: Person
@export var title := "what you could do"

var _column: VBoxContainer
var _heading: Label

# What's on screen right now, kept ONLY so the next frame can ask "did
# anything actually change" before touching a single node. See _same_ballot
# below for why that question has to be answered before rebuilding.
var _shown_actions: Array[Action] = []
var _rows: Array[Dictionary] = []   # {action: Action, button: Button}


func _ready() -> void:
	# Warn rather than return. A quiet return here would make "nobody wired
	# me up" look exactly like "his ballot is empty right now" — the same
	# silent-null trap that once shipped a dead day/night cycle through two
	# commits. The panel still builds itself either way, and sits there
	# empty and legible about why.
	if person == null:
		push_warning("VerbList has nobody's ballot to draw — its person export is unwired")
	elif not (person.brain is PlayerBrain):
		push_warning("VerbList's person is not steered by a PlayerBrain — no verb will ever appear on it")
	_build_shell()


# Presentation rides the frame the eye sees, same reasoning as
# PersonReadout._process and TuningBoard._process: this is not simulated
# time, and folding it into think_and_act would rebuild — or at least
# re-read — a menu nobody looked at for every tick a harness pumps.
func _process(_delta: float) -> void:
	# Read through is_instance_valid, always: queue_free() does not null a
	# stored reference, so `== null` would stay false and the next property
	# read would error.
	if person == null or not is_instance_valid(person):
		return
	var brain := person.brain as PlayerBrain
	if brain == null:
		return
	var open := brain.get_open_actions()
	if not _same_ballot(open):
		_rebuild_rows(open)
	_refresh_highlight(brain.get_chosen_verb())


# What is actually on screen right now, in the order it is drawn. Read-only,
# and it exists for the same reason Brain.get_known_actions() does: a panel
# that cannot be asked what it is showing can only be checked by a human
# looking at it, and "the list on screen is exactly the open ballot" is the
# one claim this file exists to keep true. Asserting it against the engine's
# own output — rather than against a list of expected names — is what stops
# the claim going stale the day somebody teaches the player something new.
func get_drawn_actions() -> Array[Action]:
	return _shown_actions


# --- Building ---------------------------------------------------------------------

func _build_shell() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	margin.add_child(outer)

	_heading = Label.new()
	_heading.text = title
	outer.add_child(_heading)

	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 2)
	outer.add_child(_column)


# Rebuilds the buttons from scratch — the ONLY place this file destroys a
# node. Called exactly when _same_ballot says the open list actually
# differs from what's on screen, and not one frame more often than that:
# rebuilding every frame would destroy the very Button the mouse is
# halfway through pressing, and the click would never land.
func _rebuild_rows(open: Array[Action]) -> void:
	for child in _column.get_children():
		child.queue_free()
	_rows.clear()

	for action in open:
		var text: String = action.label if not action.label.is_empty() else String(action.name)
		var button := Button.new()
		button.text = text
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_toggle_verb.bind(action))
		_column.add_child(button)
		_rows.append({"action": action, "button": button})

	_shown_actions = open.duplicate()


# A click on an already-chosen row un-chooses it; a click on any other row
# chooses it. Deliberately a toggle rather than a second button reading
# "stop" — a button with a word on it would be this file spelling a verb of
# its own, which is the one thing it may not do. Standing still already has
# a real, nameless way to say it: choose nothing.
func _toggle_verb(action: Action) -> void:
	var brain := person.brain as PlayerBrain
	if brain == null:
		return
	if brain.get_chosen_verb() == action:
		brain.stop_doing_anything()
	else:
		brain.choose_verb(action)


# Which row reads as chosen. Read fresh from the brain every frame rather
# than from whatever was last clicked, because the brain drops a chosen verb
# on its own the moment its gate shuts under him — a highlight that
# remembered the click instead would keep glowing on a verb he is no longer
# doing.
func _refresh_highlight(chosen: Action) -> void:
	for row in _rows:
		if not is_instance_valid(row.action):
			continue
		row.button.button_pressed = row.action == chosen


# Whether the open list handed back this frame is the same list already on
# screen — by IDENTITY and ORDER, not merely by contents. An action's own
# is_instance_valid is checked first rather than trusted to compare safely:
# forget() frees a node without nulling anyone's copy of the pointer, and a
# stale entry here has to read as "this changed, rebuild" rather than risk
# touching a freed Action at all.
func _same_ballot(open: Array[Action]) -> bool:
	if open.size() != _shown_actions.size():
		return false
	for i in open.size():
		var previous: Action = _shown_actions[i]
		if not is_instance_valid(previous) or previous != open[i]:
			return false
	return true
