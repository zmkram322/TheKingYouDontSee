class_name PlayerBrain
extends Brain

# The one body a hand steers instead of a score. Everything shared about
# deciding — the gate half, the body upkeep, the three-phase order — lives in
# Brain and runs here unchanged through super(); this file holds only the two
# things that differ about somebody being steered: WHICH action wins, and
# WHERE he is, both driven by input instead of by is_awake, a stat or a step.
#
# No `if person == player` anywhere, here or in Brain — the fork is which
# Brain script sits under him, decided once in the scene, not a branch a
# shared file takes for one particular body. Gate 1 forks the picking half
# only; the gating half is the one every author's is_available_to still
# governs, for him exactly as it does for anyone else.


# --- Which verb wins -------------------------------------------------------

# The verb a hand picked, or null if it picked nothing. Written by
# choose_verb, read by pick_from_the_ballot below — nothing else touches it.
var _chosen: Action


# Overrides Brain's score-driven default. The open list is still the shared
# gate half's — nothing here reopens or re-filters it — this only answers
# "which one wins" differently: not the highest score, whatever a hand chose.
#
# A CHOSEN VERB WHOSE GATE SHUTS UNDER HIM IS DROPPED, NOT HELD. If _chosen
# isn't in open_actions this pass, it silently falls out of his hand — he does
# not keep doing it once the world stops allowing it, and he does not resume
# it on his own the moment the world reopens it. Holding it across the gap
# would be exactly the remembered plan the rest of this substrate refuses to
# keep: nothing here is suspended and restored, everything is re-asked every
# tick, and a bid the world just refused is a bid that has to be made again,
# not a standing order. The verb-list UI reads get_chosen_verb() and shows
# nothing selected — the honest picture, since nothing is.
#
# The is_instance_valid guard is CLAUDE.md's standing rule for a stored node
# reference: queue_free() (forget(), an obligation lapsing and freeing what
# depended on it, anything) does not null your copy of the pointer, so a
# freed action would otherwise read as chosen forever and error the moment
# anything touched it.
func pick_from_the_ballot(open_actions: Array[Action]) -> Action:
	if not is_instance_valid(_chosen):
		_chosen = null
	if _chosen != null and not open_actions.has(_chosen):
		_chosen = null
	return _chosen


# A hand's bid. Decision 33: a command is a bid, not an override — this only
# ever hands a candidate to pick_from_the_ballot above, which still has to
# find it on the open list next think_and_act before it does anything.
# Choosing a gated-shut action is legal; it just loses on the next pass, same
# as it would for any other brain.
func choose_verb(action: Action) -> void:
	_chosen = action


# Choosing nothing is itself a choice — "stand there" — not an absence the
# rest of the code has to special-case. current_action already reads null
# correctly (see Brain.pick_from_the_ballot's comment).
func stop_doing_anything() -> void:
	_chosen = null


func get_chosen_verb() -> Action:
	return _chosen


# --- Where he is -------------------------------------------------------

# Decision 17's band, in world units. Enter on crossing the inner one, leave
# only on crossing the outer — see _settle_where_he_stands below for why a
# single radius was rejected. Left open by that decision and exported so it
# lands on the tuning board and gets picked by watching a man walk the edge
# of the Inn, not derived from anything.
@export var enters_within := 3.0
@export var leaves_beyond := 4.5

# What the last frame's input pointed at. Sampled every frame in _process,
# consumed once a world hour's worth at a time in think_and_act — see the
# split below for why those have to be two different rates.
var _pointed := Vector3.ZERO


func _ready() -> void:
	super()
	if leaves_beyond < enters_within:
		push_warning("a PlayerBrain's leaving band (%.2f) is inside its entering band (%.2f) — his place will flicker on every boundary" % [leaves_beyond, enters_within])


# Input is SAMPLED per frame here, and INTEGRATED per world hour below. The
# split matters: this just records which way the stick points, and records
# it as often as a frame renders so the game feels responsive. Nothing about
# HOW FAR he moves is decided in this function — that's below, and it's
# decided in hours.
func _process(_delta: float) -> void:
	var steer := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_pointed = Vector3(steer.x, 0.0, steer.y)


# For whatever one day points him without a stick under a thumb — a cutscene,
# an on-screen joystick, a script driving the probe. Same field _process
# writes, so both routes end up integrated by the exact same code below.
func point_toward(direction: Vector3) -> void:
	_pointed = direction


func get_pointed_direction() -> Vector3:
	return _pointed


# The same three-phase order Brain.think_and_act argues for at length,
# wrapped around it rather than reordered: movement happens before super's
# decide-do-update so a step chosen THIS tick already sees where he walked
# TO this tick, and current_place is settled after super so the band — not
# GoToStep, not a step's own arrival write — has the last word on where he
# ends up standing. See _settle_where_he_stands below for why that ordering
# is load-bearing rather than incidental.
func think_and_act(hours: float) -> void:
	if person == null:
		return
	_walk_where_he_is_pointed(hours)
	super.think_and_act(hours)
	_settle_where_he_stands()


# WORLD HOURS, NEVER A REAL DELTA — the same rule every rate in game/ answers
# to. person.get_travel_speed() is units per world hour, so hours is the only
# unit this can multiply by. Input may be SAMPLED per frame (see _process
# above); it may not be INTEGRATED per frame, because think_and_act only
# runs on Population's slice of world time, not on every frame the engine
# draws. Multiply by a real delta instead and dragging day_length_seconds
# would change how fast the player walks relative to every NPC around him —
# the exact shape of bug rung 0 was spent removing, just reintroduced one
# body at a time.
func _walk_where_he_is_pointed(hours: float) -> void:
	if _pointed.length_squared() <= 0.0:
		return
	person.global_position += _pointed.normalized() * person.get_travel_speed() * hours


# global_position IS INTEGRATED BY HAND HERE, DELIBERATELY NOT
# move_and_slide. Measured, per person.gd's own header: called from
# _process, move_and_slide multiplies by the PHYSICS delta and gives
# non-uniform steps, and under PROCESS_MODE_DISABLED it moves ZERO in
# silence — which would make every movement claim about the player
# unwritable for exactly the same reason it would for an NPC.
#
# A BAND, NOT A LINE, AND NOT A NEW MECHANISM. Enter on crossing the INNER
# boundary; leave only on crossing the OUTER one. This is the sleep cycle's
# own two-threshold shape — "starts winning high, stops winning low" — read
# onto space instead of onto adenosine. A single radius is a line a man can
# stand on and jitter across, and Decision 17 is explicit about the cost of
# that here specifically: a flickering player flickers in and out of EVERY
# NPC's candidate list, and it reads as "the AI is flaky" rather than as
# what it is. Do NOT reach for Area3D for this — that is the proximity model
# retired 2026-08-08, and probe claim 7 exists to keep it retired.
#
# THIS IS THE LAST WORD ON THE PLAYER'S PLACE, and that's why it runs after
# super. person.gd's own comment says GoToStep is the only thing in the game
# that writes current_place — for the player that stops being true, and
# Decision 17 is the ruling that makes it stop on purpose: his place gets
# exactly one writer too, just an input-driven one instead of a
# decision-driven one. If a chosen verb's step also writes current_place
# (WorkStep walking him onto a plot, say), settling here afterward means the
# band always speaks last — so there remains exactly ONE rule deciding where
# ANY given person is standing, discrete, crisp, and nothing downstream can
# tell a player's answer from an NPC's.
func _settle_where_he_stands() -> void:
	if person.town == null:
		return
	var here := person.get_current_place()
	if here != null and is_instance_valid(here) \
			and person.global_position.distance_to(here.global_position) <= leaves_beyond:
		return
	person.current_place = _find_the_place_he_has_entered()


# The inner boundary's other half: which place, if any, he has stepped
# inside of. Ties are impossible in practice (two places sharing a footprint
# is an authoring error, not a case worth writing for) but nearest wins if
# it ever happens, same tie-shape as everywhere else in game/ that sorts by
# cost.
func _find_the_place_he_has_entered() -> Place:
	var nearest: Place = null
	var nearest_gap := INF
	for place in person.town.get_places():
		var gap := person.global_position.distance_to(place.global_position)
		if gap <= enters_within and gap < nearest_gap:
			nearest_gap = gap
			nearest = place
	return nearest

# WATCH, DON'T FIX: he can be steered while asleep. Nothing here gates
# _walk_where_he_is_pointed on is_awake, and it shouldn't grow one on a
# guess — Decision 33 leaves open whether the player's own drives ever
# constrain him at all, and answering that here, quietly, in a movement
# function, would settle a question the design has deliberately not settled.
# If it ever needs an answer it gets one on purpose, as its own decision.
