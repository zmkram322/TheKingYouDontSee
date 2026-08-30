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
# The body moves as of rung 4, and NOT by move_and_slide — GoToStep integrates
# global_position by hand. Measured: called from _process, move_and_slide
# multiplies by the PHYSICS delta and produces non-uniform steps, and under
# PROCESS_MODE_DISABLED it moves zero in silence, which would make every
# movement claim in the probe unwritable. It stays a CharacterBody3D anyway:
# the type costs nothing and collision may want it later.

@export var person_name := "Someone"

# Enough to tell people apart at a glance once there's more than one. Applied
# over the rig's meshes in _ready rather than authored into a material asset,
# so every instance can differ without needing a material file apiece.
@export var tint := Color(0.78, 0.74, 0.68)

# What his body does when nothing else is driving it. A clip name rather than a
# verb: the animation he is PLAYING is not the action he is DOING, and nothing
# here maps one to the other. Exported so a person who should idle differently
# is authored, not coded.
@export var resting_clip := &"idle"

# What his body does when it is covering ground, and how much of his own travel
# speed counts as covering it. Both are clip names and a fraction, never verbs:
# nothing here asks WHY he is walking, and a fraction rather than a number of
# units means the threshold still means the same thing for a strong man who
# covers more ground in an hour, or for whatever a horse turns him into later.
@export var walking_clip := &"walk"
@export var walking_above := 0.1

# And what he does when he is covering ground FASTER THAN HE WALKS. Same
# shape and same units as the pair above, and deliberately a fraction GREATER
# THAN ONE: `_speed / get_travel_speed()` is "what fraction of his own full
# stride is he covering", so 1.0 is a man walking at his own pace and anything
# past it is a man being made to hurry.
#
# NOTHING IN THE GAME CAN EXCEED 1.0 BY ITSELF, which is why this slot sat
# empty until now: GoToStep moves everybody at exactly get_travel_speed().
# A summons is the first thing that pushes a man past his own walk (see
# come_along.gd), and the moment something could, his legs had nothing to
# show for it — he glided at a sprint wearing a walk cycle.
@export var running_clip := &"run"
@export var running_above := 1.8

# Where he IS — a discrete fact he carries, not a distance to anything. Authored
# per instance at birth, and after that ONE thing writes it. Null is a real
# state and means "on the way".
#
# WHICH one thing depends on what moves him, and that is the whole of Decision
# 17. For everybody whose movement follows from a DECISION, it is GoToStep:
# cleared to null on the first tick of a journey, written again on arrival. For
# a body somebody STEERS, nobody chose "go to the Inn" — a stick was pushed —
# so the writer is an input-driven one instead: PlayerBrain settles this field
# from where his body actually stands, on a two-radius band, as the last thing
# in his tick. Both are still exactly one writer per man, and both hand back the
# same discrete crisp answer, which is the point: get_current_place() is what
# every gate and every query in the game reads, and NOTHING downstream can tell
# a steered body's answer from a decided one.
#
# What must never happen is TWO writers on one man. That is why the band settles
# after the step rather than before it — a chosen verb whose step walks him
# (WorkStep) writes this field too, and the band speaking last is what keeps the
# count at one.
#
# (The probe writes it by hand too, and that is legal — it is authoring a
# situation rather than moving a man. The one-writer rule is about the game.)
#
# Note for whoever wires this in a .tscn by hand: it needs
# `node_paths=PackedStringArray("current_place")` on that instance's own header
# line, or the loader assigns the raw NodePath to a typed field and you get null
# — which here reads as a man standing on a road that doesn't exist.
@export var current_place: Place

# How fast he covers ground, in units per WORLD HOUR — like every rate in
# game/, and emphatically not per second. It is his, not the walk's, for the
# same reason strength is his: a fast walker should be fast at everything he
# ever walks to, not only at the actions somebody remembered to edit.
#
# CALIBRATED FROM THE FICTION, NOT FROM A REALISTIC PACE, and nobody should
# "correct" it. The visible town is a diorama: a person capsule is 1.7 units
# tall and the Inn stands 19.24 units from the fields, so if units were metres
# that crossing would be a fourteen-second stroll and every journey in this game
# would be free. The author's ruling is that a decent-sized town is a five to
# fifteen minute walk to the fields, so this is set to make the shipped crossing
# take about ten world minutes. The geometry still means exactly what it meant —
# double the distance and you double the trip.
@export var walk_speed := 115.0

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

# What he is carrying. A Node under him rather than a field on him, and rather
# than anything shared: what one man has in his pockets is the most per-person
# fact in the game, and CLAUDE.md's rule sends different-for-everybody to a Node
# every time.
#
# AUTHORED LAST IN person.tscn, AFTER Readout, AND IT MUST STAY THERE.
# game.tscn overrides Hobb's Stats BY INDEX — `[node name="Stats" ... index="3"]`
# carrying his strength of 1.15 — so a node inserted anywhere above Stats
# renumbers it, the override lands on the wrong node or is dropped, both farmers
# wake at the same moment, and the dawn race turns back into a coin flip decided
# by scene order. That failure presents as "the sleep cycle broke", never as "a
# node moved", which is why it is written down here rather than left to be
# rediscovered.
@onready var inventory: Inventory = $Inventory

# His body, and the one thing that plays it. Body is an instance of y_bot.tscn,
# which carries its own 180-degree turn — Mixamo rigs face +Z and Godot forward
# is -Z — so nothing in game/ has to know that.
#
# IT SITS AT INDEX 0, WHERE THE CAPSULE SAT, AND IT MUST STAY THERE. The rig
# REPLACED that node rather than being added beside it, which is what kept
# Stats at 3 and Inventory at 5 — see the Inventory comment above for what
# renumbering them costs.
@onready var _body: Node3D = $Body
@onready var _animation: AnimationPlayer = $Body/AnimationPlayer

# How fast he was moving over his last slice of world time, in units per world
# HOUR, and which way he was pointed doing it. A MEASUREMENT taken where
# movement happens and read where the eye is — not a memory of a decision, and
# not progress through anything that would have to be restored.
#
# It survives between ticks on purpose. A man Population thinks for every
# fourth frame is still walking on the three frames nobody asked him anything,
# and his legs should not stutter to prove it.
var _speed := 0.0
var _heading := 0.0

# The one-shot he has already performed. A gesture — a wave, a bow, a loaf held
# out — is authored LOOP_NONE and means to happen ONCE; play() on a clip that
# has run out starts it again, so a three-second give sawed the same throw over
# and over for as long as the step declared it.
#
# WRITTEN BY THE SIGNAL, NOT BY A TIMER. AnimationPlayer already knows when a
# clip has ended and says so, and it clears current_animation when it does — so
# there is nothing to compare against afterwards and no second clock to keep in
# step with the first. It is cleared the moment anything else is asked for,
# which is what lets him wave again next time somebody is worth waving at.
var _gesture_spent: StringName = &""


func _ready() -> void:
	_apply_tint()
	# WIRED HERE AND NOT IN _start_the_body, WHICH IS OVERRIDDEN. It was in there
	# first and person_with_exchange.gd replaces that whole function, so the one
	# body in the game that gives things away was the one body whose gestures
	# still sawed. A subclass that wants to check different clips must not be
	# able to lose the thing that makes a clip happen once — so the wiring sits
	# beside the call rather than inside it.
	if _animation != null:
		_animation.animation_finished.connect(_remember_it_is_spent)
	_start_the_body()
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
	# Every person carries one, by composition — the same guarantee that keeps
	# eat and flee on everybody's ballot. Said out loud because a man without one
	# works a full day and produces nothing, and an empty readout looks exactly
	# like a man who has not got round to working yet.
	if inventory == null:
		push_warning("%s has no Inventory under him — he can carry nothing, and a day's work will vanish" % person_name)


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
	var was_at := global_position
	brain.think_and_act(hours)
	_measure_how_he_moved(global_position - was_at, hours)


# One slice of LIVING for a man who is not thinking — the body keeps running,
# the ballot never opens, and he does not move.
#
# THE HALF OF think_and_act THAT NOBODY IS ALLOWED TO SKIP. Anything that holds
# a man out of Population's loop — a conversation, a coarsely-stepped distant
# village, whatever a later mechanism wants — calls this instead of simply
# passing him over. Passing him over stops time for him: he stops hungering,
# stops tiring and stops getting lonely while the man beside him does all
# three, so a long enough hold is a free rest nobody authored.
#
# THE ZERO DISPLACEMENT IS NOT A FORMALITY. _speed is what decides whether the
# travel layer wins over his declared clip, and it is only ever written here.
# Skip this and it keeps the last value it had — so a man held mid-stride
# stands perfectly still playing a walk cycle until he is released. Handing it
# a real zero is what makes him stop.
#
# WHAT IT DELIBERATELY DOES NOT DO is clear current_action. He is interrupted,
# not reset, and the thing he was doing is still what he means to be doing when
# the hold ends — this substrate re-decides from scratch on the next real tick
# anyway. The visible cost is that he wears the clip of whatever he was at, so
# a man stopped on his way to bed looks like he is sleeping on his feet.
# Whatever holds him is the thing that should say what he looks like instead.
func run_upkeep(hours: float) -> void:
	brain.run_upkeep(hours)
	_measure_how_he_moved(Vector3.ZERO, hours)


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


# What he is carrying. A method rather than a bare field read, so that a person,
# a place and a workstation are all asked the same question in the same words —
# `something.get_inventory()` — and a transfer between any two of them reads
# identically. Rung 6b hands a farmer's quota into a barn and rung 7 hands grain
# to a merchant; neither wants to know which kind of thing it is holding.
#
# It is also the wall where "his pockets" could later become "his pockets, plus
# the cart he is pulling" without a caller moving.
func get_inventory() -> Inventory:
	return inventory


# Everything he owes, by walking his children — the same shape
# Brain.reload_known_actions uses for what he knows. An obligation is
# authored the same way: a Node under him rather than an entry in a list kept
# somewhere else, so a man's agreements are visible in exactly the tree you'd
# already look in to see what he can do.
func get_obligations() -> Array[Obligation]:
	var found: Array[Obligation] = []
	for child in get_children():
		if child is Obligation:
			found.append(child)
	return found


# Does an UNEXPIRED obligation of his name this place. DISCHARGED STILL
# COUNTS — a man who met today's quota is not evicted from the land he is
# employed on, he is merely done wanting for today. Permission and want are
# two different questions: this answers the first (can he set foot here at
# all), WorkForHire.get_utility_score answers the second (does he still want
# to).
func has_obligation_at(place: Place) -> bool:
	if place == null:
		return false
	for obligation in get_obligations():
		if obligation.is_expired():
			continue
		if obligation.place_name == place.place_name:
			return true
	return false


# How fast he travels right now, whatever he is travelling by. THE MEANS.
#
# Its own call site rather than a read of walk_speed, because walking is only
# one way to travel: a horse, a cart, a boat, a bad leg or a heavy sack all
# install in this one body and not one caller changes. Same shape as
# Brain.get_adenosine_recovery(), and it has the same single modifier behind it
# today — strength, doing the second job it was always predicted to do. A
# bigger body carries itself faster, so two men who set off together do not
# arrive together, and a race for one plot is settled by the men rather than by
# the order they happen to sit in the scene tree.
#
# It deliberately takes NO destination. The means of travel is a fact about the
# traveller; anything route-shaped belongs in get_travel_cost_to below. A road
# changes that one, a horse changes this one, and neither has to know about the
# other — which is the whole reason there are two.
func get_travel_speed() -> float:
	if stats == null:
		return walk_speed
	var strength: float = stats.get_stat(&"strength")
	return walk_speed * strength


# What getting there costs him, IN HOURS. THE JOURNEY. Asked in SCORE, and it
# NEVER gates: a far place is outbid, never barred, which is what keeps "he
# loses, and losing is the content" true, and why nothing here compares against
# a threshold.
#
# Straight-line ÷ his speed today, which is what makes standing check #3 pass —
# drag a place in the editor and this number moves while the game runs. Roads, a
# river crossing, a gate shut at night, and one day a world spanning several
# towns all install in THIS FUNCTION BODY and no call site changes. It lives on
# Person rather than on Place or Town because every caller is an Action scoring
# itself and an Action always has the person — and because there will be more
# than one town, so a Town-scoped answer breaks.
#
# HOURS RATHER THAN RAW DISTANCE, and be honest about what that buys at this
# rung: nothing you can see. Sorting by hours and sorting by distance are the
# same ordering for one man, because his speed is positive. It is the honest
# unit, it is the last un-denominated quantity in game/, and it is what a road
# or a horse actually changes — a road does not shorten the distance, it
# shortens the trip. It earns itself at rung 9a, where candidates first differ
# in quality and cost has to be traded against yield. (Decision 14.)
#
# WHAT IT IS NOT ALLOWED TO DO, and this is structural rather than a tuning
# invariant somebody has to remember: this number only ever competes the SAME
# alternative at different locations — this plot against that one. It never
# enters the comparison between one action and another, so no weight on it can
# mute a commute, because the comparison that could mute one never happens.
# Pull decides WHAT you do; this decides WHERE you go to do it. (Decision 15.)
func get_travel_cost_to(place: Place) -> float:
	# A place that isn't there costs everything. Nowhere is deliberately the
	# most expensive answer rather than the cheapest: returning 0.0 would read
	# as "at his feet" and make a nonexistent place the most attractive
	# destination in town, which is a bug that would present as strange
	# wandering rather than as a null.
	if place == null:
		push_error("%s was asked what it costs to reach nowhere" % person_name)
		return INF
	# A man who cannot move cannot get there, and INF is the truthful price of
	# that rather than the division quietly handing back one. Nothing sets a
	# speed of zero today; this is here so that the day something does — a
	# broken leg, a sack too heavy — it reads as "he is not going" instead of as
	# a number nobody can explain.
	var speed := get_travel_speed()
	if speed <= 0.0:
		push_error("%s cannot travel at all — his speed is %f" % [person_name, speed])
		return INF
	return global_position.distance_to(place.global_position) / speed


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
	_show_the_body()


# Over every mesh the rig has, found rather than named. Y Bot wears two
# (a surface and its joints) and a rig swapped in later will wear some other
# number; none of them get spelled out here.
func _apply_tint() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 1.0
	if _body == null:
		return
	for node in _body.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_override = material


# Something has to be playing or he stands in his bind pose, arms out, which
# reads as a broken import rather than as a man doing nothing. Both clips are
# checked HERE, once, rather than on every tick that plays one — a missing clip
# is a wiring fault that should be said once and loudly, not a thousand times a
# second into a log nobody can read.
func _start_the_body() -> void:
	if _animation == null:
		push_warning("%s has no AnimationPlayer under his Body — he will stand in his bind pose" % person_name)
		return
	for clip_name in [resting_clip, walking_clip, running_clip]:
		if not _animation.has_animation(clip_name):
			push_warning("%s has no \"%s\" clip — his body cannot show it" % [person_name, clip_name])
	_play(resting_clip)


# A clip that ran all the way to its end has been performed. Only a LOOP_NONE
# clip ever gets here — a looping one never finishes — so nothing has to ask
# which kind it was.
func _remember_it_is_spent(clip_name: StringName) -> void:
	_gesture_spent = clip_name


# Is that gesture still to be MADE — a thing that happens once, on this body,
# that he has not got through yet? The two halves are both load-bearing: a
# looping clip is never pending because it has no end to reach, and a clip he
# has already performed is not pending either.
#
# Asked by whatever wants to wait for him. It is deliberately a question about
# the BODY and not about the verb: nothing here knows why he is doing it, and a
# caller that wanted to know that would be asking the brain instead.
func is_gesture_pending(clip_name: StringName) -> bool:
	if _animation == null or clip_name.is_empty() or clip_name == _gesture_spent:
		return false
	var clip := _animation.get_animation(clip_name)
	return clip != null and clip.loop_mode == Animation.LOOP_NONE


# He is about to make a gesture AGAIN. A one-shot is spent the moment it runs
# out and only starting something else clears the mark, so a man who reaches
# into the same basket twice without moving in between would reach exactly once.
# This is the one door for saying "again", and the only thing that should ever
# knock on it is a fresh press.
func start_gesture_again() -> void:
	_gesture_spent = &""


# Taken across the brain's tick, because that is where global_position moves —
# by hand in both PlayerBrain and GoToStep, never by move_and_slide, so there
# is no velocity to read. IN WORLD HOURS like every rate in game/, so what his
# legs do cannot change when day_length_seconds is dragged.
#
# Nothing is decided here. This only measures; _show_the_body below is what
# does something about it.
func _measure_how_he_moved(displacement: Vector3, hours: float) -> void:
	if hours <= 0.0:
		return
	var travelled := Vector3(displacement.x, 0.0, displacement.z)
	_speed = travelled.length() / hours
	if _speed > 0.0:
		_heading = atan2(travelled.x, travelled.z)


# What his body is doing, asked once per frame the eye sees — the same split
# the readout answers to, and for the same reason: presentation should redraw
# as often as it is LOOKED AT, not as often as the world is stepped. Fold this
# back into think_and_act and the day Population thinks for him every fourth
# frame, his legs stutter between thoughts.
#
# THIS FUNCTION IS THE SEAM for not animating a body nobody is looking at. It
# is the one place, once per person per frame, where the question gets asked,
# so a visibility test installs HERE — `_animation.active = false` and every
# clip in the game goes quiet behind it. Deliberately NOT built: there are
# three people in this town, and culling three people is substrate before
# anything needs it.
#
# TWO LAYERS, AND MOVING WINS. Travel is answered by measured displacement, so
# no step has to describe its own walk — which is what lets Sleep play a walk
# on the way to the bed and a sleep once he is in it, with nothing in
# sleep.tscn saying either word. Everything else is whatever his step declares,
# and a step that declares nothing leaves him resting.
func _show_the_body() -> void:
	if _animation == null or _body == null:
		return
	# What fraction of his own full stride he is covering. Dimensionless on
	# purpose — both halves are units per world hour — so a strong man who covers
	# more ground in an hour still starts walking and starts running at the same
	# point in his own gait, and dragging day_length_seconds cannot change either.
	var stride := _speed / maxf(get_travel_speed(), 0.0001)
	if stride >= walking_above:
		# Turn the BODY, never the man. global_position is what every gate and
		# every distance in this game reads; his own rotation means nothing at
		# all, and it should keep meaning nothing.
		_body.rotation.y = _heading
		_play(running_clip if stride >= running_above else walking_clip)
		return
	var doing: StringName = brain.get_clip() if brain != null else &""
	_play(resting_clip if doing.is_empty() else doing)


# play() on a clip already playing is a no-op, so asking every tick costs
# nothing and nothing has to remember what his body was doing. The guard is
# for a clip that does not exist — already warned about in _start_the_body,
# and silent here so one wiring fault is not also a flood.
#
# THE ONE THING IT DOES REMEMBER is a gesture that has already run its course:
# asked for that same clip again he RESTS instead, so a one-shot happens once
# and he stands there for the rest of a step that goes on declaring it. Asked
# for anything else at all, the memory is dropped in the same breath as the new
# clip starts — there is no state to clear and nobody to clear it.
func _play(clip_name: StringName) -> void:
	if _animation == null:
		return
	if clip_name == _gesture_spent:
		if _animation.has_animation(resting_clip):
			_animation.play(resting_clip)
		return
	if not _animation.has_animation(clip_name):
		return
	_gesture_spent = &""
	_animation.play(clip_name)


# What floats over his head — who he is, what he is doing, and what he is
# carrying. It travels with him, so it shrinks with distance and turns side-on,
# and thirteen stat lists floating over a town is soup. Everything you need to
# tell one man from another at a glance, and not one line more.
#
# The detail lives in PersonReadout, which sits still in a corner and shows one
# man closely. That split is why this is short.
#
# WHY WHAT HE CARRIES MADE THE CUT, when no stat has. The test for this label is
# "what tells one man from another at a glance", and from rung 5 that is exactly
# what his sacks do: two farmers race for one plot, one of them works it, and the
# winner's grain climbs while the loser's sits at zero. Read off two heads at
# once, that is the whole rung. A corner panel cannot show it — it watches one
# man — and a graph makes you infer it. THE DAY THIS GOES SOUPY, and it will
# around thirteen people with five kinds of goods, this loop is the first thing
# to cut back; it is listed by reflection, so cutting it is deleting three lines
# rather than unpicking a list of item names.
func get_name_plate_text() -> String:
	var lines := [person_name, brain.describe_current_action()]
	if inventory != null:
		for item_name in inventory.get_item_names():
			lines.append("%s %d" % [item_name, inventory.get_count(item_name)])
	return "\n".join(lines)


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
	# And what he is carrying, listed the same way and for the same reason: an
	# item that turns up in this world for the first time shows up here without
	# this file changing, and no string in game/ ends up naming one particular
	# kind of goods.
	if inventory != null:
		for item_name in inventory.get_item_names():
			lines.append("%s %d" % [item_name, inventory.get_count(item_name)])
	lines.append("at %s" % _describe_current_place())
	# Every place in the town gets priced, rather than one named in here. Same
	# reason the stats above are listed instead of named one by one: adding a
	# place to the scene makes it show up over every head without this file
	# changing, and no string in game/ ends up naming one particular instance.
	if town != null:
		for place in town.get_places():
			lines.append("to %s %.2f h" % [place.place_name, get_travel_cost_to(place)])
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
