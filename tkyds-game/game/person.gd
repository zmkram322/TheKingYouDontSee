class_name Person
extends CharacterBody3D

# One person in the world. A scene of its own (person.tscn) rather than nodes
# built inline in game.tscn, so that everyone who ever lives here is the same
# thing instanced again — Zoogs is not a special class, he is this scene with
# a name typed into it.
#
# What makes an instance somebody in particular is the exports below and the
# starting values on their Stats node, both overridable per instance straight
# from the inspector. When someone eventually needs a node nobody else has,
# that's what Godot's inherited scenes are for; nothing here has to change to
# allow it.
#
# The body itself doesn't move yet — no walking, nowhere to walk. It's a
# CharacterBody3D now rather than a Node3D so that when movement arrives it
# lands on the node already carrying `velocity` and `move_and_slide`, instead
# of a scene-wide retype.

@export var person_name := "Someone"

# Enough to tell people apart at a glance once there's more than one. Applied
# to the capsule in _ready rather than authored into person.tscn's material,
# so every instance can differ without needing a material file apiece.
@export var tint := Color(0.78, 0.74, 0.68)

# Where he IS — a discrete fact he carries, not a distance to anything. Authored
# per instance today; rung 4's walking step writes it on arrival and clears it
# for the length of the road. Null is a real state and means "on the way".
#
# Note for whoever wires this in a .tscn by hand: it needs
# `node_paths=PackedStringArray("current_place")` on that instance's own header
# line, or the loader assigns the raw NodePath to a typed field and you get null
# — which here reads as a man standing on a road that doesn't exist.
@export var current_place: Place

# The world he can ask questions about. Not exported and not a wire: pulled off
# his Population in _ready, the same way Brain finds its Person by asking its
# parent. One wire in the whole scene feeds everybody, so thirteen people at
# rung 9 is still one NodePath rather than thirteen chances at the trap that
# already shipped a dead day/night cycle here.
#
# It is pulled rather than handed down because Godot readies children BEFORE
# parents: a Population handing this out in its own _ready would arrive after
# every person had already checked his pocket and found it empty, so the warning
# below would fire on every person of every correct scene. Pulling also means a
# man born mid-run — the probe's spares, and standing check #2's fourteenth
# villager — is wired the instant he enters the tree, with nothing watching for
# new arrivals.
var town: Town

# The time of day, for anything that cares what hour it is. Pulled off
# Population in the same breath as the town, for the same reasons.
#
# It is NOT here to interpret a real-time delta — that stays the one line in
# Clock, and nothing below Population ever sees a real second. It is here
# because an Action scoring itself has the person and nothing else, and some of
# them need to know whether the sun is up. Rung 3 wants it too: a workstation's
# tenancy is stamped with `clock.day()`, and reading that off the person means
# not one station needs a wire of its own.
var clock: Clock

@onready var stats: Stats = $Stats
@onready var brain: Brain = $Brain
@onready var readout: Label3D = $Readout

@onready var _shape: MeshInstance3D = $Shape


func _ready() -> void:
	_apply_tint()
	# Says so out loud rather than standing there quietly not living. Nothing
	# here drives itself any more — a person dropped into a scene without a
	# Population above him never thinks, never tires and never sleeps, and
	# without this that is indistinguishable from a man who is merely well
	# rested. It is the same silence that shipped a dead day/night cycle.
	var population := get_parent() as Population
	if population == null:
		push_warning("%s has no Population above him — he will never think" % person_name)
	else:
		town = population.town
		clock = population.clock
	if town == null:
		push_warning("%s has no Town — he can never be asked who else is here" % person_name)
	if clock == null:
		push_warning("%s has no Clock — for him the sun never rises" % person_name)
	# Nobody is born on the road. Null is a legitimate state for a man WALKING
	# once rung 4 exists, but at birth it means his place was never authored —
	# and a man standing nowhere is invisible to every place query in the game,
	# which reads as a town that ignores him rather than as a missing wire.
	if current_place == null:
		push_warning("%s starts nowhere — no place query will ever find him" % person_name)


# One slice of living, in world HOURS. Not called from here: Population walks
# its people and hands each of them the same slice, having read the Clock once
# for all of them. That is the seam — everything later about WHO thinks and
# HOW OFTEN installs up there, at one call site, rather than in every body.
#
# It takes hours, not a real delta, because everything below Clock does. Kept
# as its own method rather than folded into the caller so that a harness
# pumping a day in a fraction of a second advances him by exactly the path the
# game uses, rather than by a second route that can quietly diverge from it.
func think_and_act(hours: float) -> void:
	brain.think_and_act(hours)


# Where he is standing, or null if he is between places. Asked in GATE, where
# the answer has to be crisp: "am I at the tavern?" gets exactly one answer, and
# a gate reading it can never flicker because nothing here is compared against a
# threshold. Rungs 3 and 7 both ask it every tick.
#
# An accessor over a public field looks redundant and isn't: it is the wall that
# lets where-he-is graduate — carried on a vehicle, inside a building inside a
# place — without a single caller moving. Same reason stats go through get_stat.
func get_current_place() -> Place:
	return current_place


# What getting there costs him. Asked in SCORE, and it NEVER gates: a far place
# is outbid, never barred, so the cost only ever multiplies an appeal. That is
# what keeps "he loses, and losing is the content" true, and it is why nothing
# here compares against a threshold.
#
# Straight-line off the transforms today, which is what makes standing check #3
# pass — drag a place in the editor and this number moves while the game runs.
# Roads, a river crossing, a gate shut at night, and one day a world spanning
# several towns all install in THIS FUNCTION BODY and no call site changes. It
# lives on Person rather than on Place or Town because every caller is an Action
# scoring itself and an Action always has the person — and because there will be
# more than one town, so a Town-scoped answer breaks.
#
# The falloff curve that turns this into a multiplier lands at rung 4, which is
# the first rung where a man chooses between two places at different costs and
# so the first collision that can actually break the curve.
func get_travel_cost_to(place: Place) -> float:
	# A place that isn't there costs everything. Nowhere is deliberately the
	# most expensive answer rather than the cheapest: returning 0.0 would read
	# as "at his feet" and make a nonexistent place the most attractive
	# destination in town, which is a bug that would present as strange
	# wandering rather than as a null.
	if place == null:
		push_error("%s was asked what it costs to reach nowhere" % person_name)
		return INF
	return global_position.distance_to(place.global_position)


# How high the sun is FOR HIM: -1 at midnight, 0 at dawn and dusk, +1 at midday.
#
# Asked of the person rather than of the Clock directly, because every caller is
# an Action scoring itself and an Action has the person and nothing else. It is
# also the honest place for it to graduate: a man in a cellar, down a mine or
# inside at rung 6 sees no sun at noon, and that is a fact about where HE is.
# The day that matters, it changes in this body and no caller moves.
#
# Flat nothing with no clock. He has already said so in _ready, and a person who
# cannot tell the time should be neither more nor less inclined to be up.
func get_sun_height() -> float:
	if clock == null:
		return 0.0
	return clock.get_sun_height()


# What's over his head, and nothing else. The readout deliberately does NOT
# ride think_and_act: it is presentation, so it should redraw once per frame
# the eye sees, not once per slice of simulated time. Fold it in and a harness
# pumping a thousand ticks would rebuild a label a thousand times for nobody —
# and the day Population starts thinking for him every fourth frame, the text
# above his head would freeze between thoughts.
func _process(_delta: float) -> void:
	readout.text = get_name_plate_text()


func _apply_tint() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 1.0
	_shape.material_override = material


# What floats over his head — who he is and what he is doing, and deliberately
# nothing else. It travels with him, so it shrinks with distance and turns
# side-on, and thirteen stat lists floating over a town is soup. Everything you
# need to tell one man from another at a glance, and not one line more.
#
# The detail lives in PersonReadout, which sits still in a corner and shows one
# man closely. That split is why this is short.
func get_name_plate_text() -> String:
	return "\n".join([person_name, brain.describe_current_action()])


# Everything about him, for something that has the room to show it. The stats
# are listed rather than named one by one so that adding one to Stats makes it
# show up here without this file changing.
func get_readout_text() -> String:
	var lines := [person_name, brain.describe_current_action()]
	# Asked for by name rather than picked up off the stat list, because being
	# awake isn't a stat he carries — see Brain.is_awake.
	lines.append("awake %s" % ["yes" if brain.is_awake() else "no"])
	for stat_name in stats.get_stat_names():
		var value: Variant = stats.get_stat(stat_name)
		lines.append("%s %s" % [stat_name, _as_text(value)])
	lines.append("at %s" % _describe_current_place())
	# Every place in the town gets priced, rather than one named in here. Same
	# reason the stats above are listed instead of named one by one: adding a
	# place to the scene makes it show up over every head without this file
	# changing, and no string in game/ ends up naming one particular instance.
	if town != null:
		for place in town.get_places():
			lines.append("to %s %.1f" % [place.place_name, get_travel_cost_to(place)])
	return "\n".join(lines)


# Nowhere is a real answer — a man between places is at no place — so it gets a
# word rather than being left blank and read as a broken wire.
func _describe_current_place() -> String:
	if current_place == null:
		return "nowhere"
	return current_place.place_name


# Numbers get a decimal place; yes/no stats read as words. Anything else falls
# back to however it prints itself.
func _as_text(value: Variant) -> String:
	if value is float or value is int:
		return "%.1f" % value
	if value is bool:
		return "yes" if value else "no"
	return str(value)
