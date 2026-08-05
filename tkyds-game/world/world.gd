class_name VillageWorld
extends RefCounted

# The world: where places are, what time it is, and who lives here. Fully
# headless — a scene, if one ever exists, is a skin that reads this and
# draws; it never gets to push anything back in.
#
# advance(delta) is the only mover, same shape as the old sandbox engine:
# the clock takes its share, then every character gets the same slice to get
# on with whatever they're pursuing. Nothing else in the codebase moves time.
#
# The dependency points one way on purpose. The world knows its characters;
# a Character never holds a world reference. Anything world-shaped a
# character needs — where the inn is, whether it's open — reaches them
# through an action's gate, curve, or generator closing over this object.
# That keeps brain/ ignorant of worlds the same way it's ignorant of
# subjects, and means a character can be lifted into a test with no world
# at all, which is exactly what the brain suites already do.

var places := {}                       # StringName -> Vector2, plain data
var characters: Array[Character] = []

# The one clock fact. Everything else — which day it is, how far through the
# day we are — is derived from this on read, in the same spirit as a Step
# re-deriving satisfaction: a stored day counter could only ever agree with
# this number or be a bug.
var seconds := 0.0


# The world's own housekeeping runs from the moment it exists: no actor
# should ever be able to accumulate an obligation without bound (FR103), so
# the sweep that prevents it is built in rather than something content has
# to remember to wire up.
func _init() -> void:
	add_chore(_sweep_expired_obligations)


# --- Time -------------------------------------------------------------------

# One slice of the world living: the clock moves, this tick's provider
# snapshot is re-derived, the world's own chores get first look — sweeping
# what's no longer wanted, handing out what's newly needed — then everyone
# due a reconsider gets one, then everyone gets the same slice to get on
# with whatever they're pursuing. Characters are visited in residence order
# every tick; nobody is scheduled, skipped, or remembered between slices.
func advance(delta: float) -> void:
	seconds += delta
	_derive_who_can_serve()
	_run_chores()
	for who in characters:
		if _due_to_reconsider(who, delta):
			reconsider(who)
	for who in characters:
		who.act(delta)


# --- Reconsidering ------------------------------------------------------------

# The seam every poke to a settled mind goes through from outside the
# character itself. Character re-decides on its own when there's nothing
# active, when the body finishes, or when the body turns out impossible — all
# reasons found by looking at the work. This is the other reason a mind might
# change: the WORLD moved while the work was still perfectly possible and
# still under way — a fright, a bell ringing, the clock crossing into
# evening. Nothing about how the poke was earned lives here; by the time this
# is called, something has already decided a reconsideration is due, whether
# that's the sweep below or, one day, an event firing directly.
#
# Deliberately just decide_action(). Re-deciding is always safe on its own —
# see Character's own docs — and it's Action.interrupt_threshold, not this
# method, that keeps a reconsideration from being mistaken for permission to
# drop whatever's already under way.
func reconsider(who: Character) -> void:
	who.decide_action()


# Is this character due for a reconsider this slice? Purely a question about
# facts already on hand — the world's clock and the character's own phase —
# never a countdown kept anywhere. The timeline is cut into windows
# RECONSIDER_SWEEP_SECONDS wide, offset by the character's phase; crossing
# from one window into the next during this slice is what "due" means. That
# makes every character due exactly once per window, on their own schedule,
# with nothing stored beyond the one phase number — the same re-derivation
# discipline as everywhere else, just applied to "was it recently checked"
# instead of "is it done".
func _due_to_reconsider(who: Character, delta: float) -> bool:
	var window := WorldTune.RECONSIDER_SWEEP_SECONDS
	var phase: float = who.stat(&"reconsider_phase", 0.0)
	var window_before: float = floor((seconds - delta + phase) / window)
	var window_now: float = floor((seconds + phase) / window)
	return window_now != window_before


# How far through the current day, in [0, 1). This is the hook later day
# curves hang off — "the field pays at 0.3, the inn calls at 0.8" — and
# deliberately nothing more than a fraction: no dawn/dusk names, no phases,
# until something real needs them.
func time_of_day() -> float:
	return fmod(seconds, WorldTune.DAY_LENGTH_SECONDS) / WorldTune.DAY_LENGTH_SECONDS


# Which day it is, counting from day 0. FR70's readable boundary: state
# changes are meant to be read as day-over-day deltas, and this is the number
# they're read against.
func day() -> int:
	return int(seconds / WorldTune.DAY_LENGTH_SECONDS)


# --- The day curves -----------------------------------------------------------

# A named lookup, not a Dictionary of Callables — the day has exactly two
# curves today, and a closed lookup says so out loud: an unknown name is a
# typo or a curve nobody wrote yet, and both deserve a warning, not a silent
# 0.0 that reads as "the world has no opinion right now" when the truth is
# "you asked for something that doesn't exist". A curve reading 0.0 through
# this lookup, by contrast, is a real answer — the middle of the night truly
# has no pull to work or to socialise — which is exactly why the two failure
# modes have to be told apart at all.
#
# `at_time` defaults to a sentinel below any real time-of-day so the usual
# call reads the world's own clock; passing an explicit fraction is only for
# proving the shape of a curve without having to run the clock there.
func curve(name: StringName, at_time: float = -1.0) -> float:
	var t := time_of_day() if at_time < 0.0 else at_time
	match name:
		&"work":
			return _urge_to_work(t)
		&"social":
			return _urge_to_be_social(t)
		_:
			push_warning("no curve called \"%s\" — a curve name is misspelled or never added" % name)
			return 0.0


# Rises with the sun, amplified while it's up, winding down through the late
# afternoon. Built from two ramps rather than one hump: `rising` climbs from
# 0 to 1 through the morning and then stays at 1 forever after, `falling`
# stays at 1 until the afternoon and then drops to 0 — so their minimum is a
# plateau with a smooth ramp on either side, at full strength for exactly the
# stretch of the day named WORK_FULL_BY..WORK_FADES_FROM and nothing outside
# WORK_RISES_FROM..WORK_SILENT_BY.
func _urge_to_work(t: float) -> float:
	var rising := smoothstep(WorldTune.WORK_RISES_FROM, WorldTune.WORK_FULL_BY, t)
	var falling := 1.0 - smoothstep(WorldTune.WORK_FADES_FROM, WorldTune.WORK_SILENT_BY, t)
	return WorldTune.WORK_CURVE_PEAK * minf(rising, falling)


# Low through the working day, spiking toward evening as work falls off. Same
# two-ramp shape as urge_to_work, anchored later in the day and deliberately
# overlapping work's wind-down (SOCIAL_RISES_FROM sits inside
# WORK_FADES_FROM..WORK_SILENT_BY) — that overlap is what lets the two curves
# genuinely cross partway through the afternoon instead of one going quiet
# exactly where the other wakes up.
func _urge_to_be_social(t: float) -> float:
	var rising := smoothstep(WorldTune.SOCIAL_RISES_FROM, WorldTune.SOCIAL_FULL_BY, t)
	var falling := 1.0 - smoothstep(WorldTune.SOCIAL_FADES_FROM, WorldTune.SOCIAL_SILENT_BY, t)
	return WorldTune.SOCIAL_CURVE_PEAK * minf(rising, falling)


# --- Places -----------------------------------------------------------------

# Where a named place stands. Asking for a place nobody put on the map is a
# bug worth being loud about — a silent Vector2.ZERO would send characters
# quietly walking to the origin and nothing anywhere would say why.
func where(place_name: StringName) -> Vector2:
	if not places.has(place_name):
		push_warning("nowhere called \"%s\" — a place name is misspelled or never added" % place_name)
		return Vector2.ZERO
	return places[place_name]


func add_place(place_name: StringName, at: Vector2) -> void:
	places[place_name] = at


# --- Place facts --------------------------------------------------------------

# The facts about things standing in the world — the mill's grinding
# progress, the inn's flour stock — shared by everyone and surviving any
# interruption, the same reason a character's own stats live behind
# `Character.stat`/`set_stat` rather than being stored on whatever Step
# happens to be touching them. Every read and write of a place fact goes
# through these two, and the Dictionary behind them is an implementation
# detail nobody outside should reach past them to touch.
#
# `fallback` is the seam's other half: an unset fact reads as its default
# rather than as an error, so only what actually differs from "nothing here
# yet" has to be stored — a mill nobody has ground anything at yet simply
# reads as having no flour, not as a bug.
var place_stats := {}                  # StringName -> (StringName -> Variant)

func place_stat(place: StringName, what: StringName, fallback = 0.0) -> Variant:
	if not place_stats.has(place):
		return fallback
	return place_stats[place].get(what, fallback)


func set_place_stat(place: StringName, what: StringName, value) -> void:
	if not place_stats.has(place):
		place_stats[place] = {}
	place_stats[place][what] = value


# --- Who can serve what -------------------------------------------------------

# Content declares, once, that a character can serve a kind of work whenever
# some world-fact test passes — the miller can serve `flour` whenever the
# mill has grain or something already ground. That declaration is a standing
# fact about the world's residents, not something re-evaluated on every
# read: who_can_serve() answers from a snapshot, re-derived exactly once per
# advance() before anyone acts and served untouched for the rest of the
# tick, "fresh as of T" rather than paying for a world query on every
# candidate a scoring pass happens to glance at (FR4).
var _offers: Array[Dictionary] = []            # declared {about, who, ready} triples
var _who_can_serve: Dictionary = {}            # StringName -> Array[Character], this tick's snapshot


func offers(about: StringName, who: Character, ready: Callable) -> void:
	_offers.append({"about": about, "who": who, "ready": ready})


# Who currently reads as able to serve this kind of work — read from the
# snapshot, never re-derived here.
func who_can_serve(about: StringName) -> Array[Character]:
	return _who_can_serve.get(about, [] as Array[Character])


func _derive_who_can_serve() -> void:
	_who_can_serve.clear()
	for offer in _offers:
		if not offer.ready.call(offer.who):
			continue
		var about: StringName = offer.about
		if not _who_can_serve.has(about):
			_who_can_serve[about] = [] as Array[Character]
		_who_can_serve[about].append(offer.who)


# Does anybody already owe about this? Reading what people currently owe is
# reading the world, not remembering having asked — see Obligation's own
# docs on why `about` exists at all. This is the guard whoever emits work
# checks before handing out a second helping of the same errand.
func anyone_owes_about(about: StringName) -> bool:
	for who in characters:
		if who.owes_anything_about(about):
			return true
	return false


# --- Chores --------------------------------------------------------------------

# The world's own jobs, run once per advance() before anyone acts: sweeping
# obligations nobody wants any more, watching a stock level and handing out
# an errand when it runs low. World.gd stays content-ignorant on purpose —
# it runs whatever chores it's given and never learns what flour is; that
# knowledge lives entirely in the closures content adds here.
var _chores: Array[Callable] = []


func add_chore(chore: Callable) -> void:
	_chores.append(chore)


func _run_chores() -> void:
	for chore in _chores:
		chore.call()


# An outstanding obligation whose still_wanted now reads false is cleared
# the same way a lord withdrawing an order would clear it: it stops being
# owed without ever having been discharged as done work. This is also what
# stops an actor endlessly re-picking and re-abandoning an obligation
# nobody can serve any more — the same debt would otherwise sit in the
# queue forever, losing every scoring pass without ever going away.
func _sweep_expired_obligations() -> void:
	for who in characters:
		for action in who.queue.duplicate():
			if action is Obligation and not action.is_still_wanted():
				who.clear_assigned_action(action)


# --- Teardown ------------------------------------------------------------------

# Content closures over the world are held by the characters the world
# itself holds — an obligation's eligible and score, an offer's ready test,
# a chore's own body, all close over this object to read it. That's a
# reference cycle, and GDScript's RefCounted never collects cycles on its
# own; found the hard way in the sandbox's demand-generalisation detour.
# close_down() is the deliberate break: drop every character, every
# declared offer, every chore, and nothing here is left pointing back in.
# Call it whenever a world is being discarded — every test that builds one
# calls it when it's done.
func close_down() -> void:
	characters.clear()
	_offers.clear()
	_who_can_serve.clear()
	_chores.clear()


# --- Who lives here ---------------------------------------------------------

# Moving in twice is a no-op rather than a second residency — a duplicated
# resident would get two slices per tick and live at double speed.
#
# Also where a resident gets their reconsider phase — harness bookkeeping for
# the sweep, not progress on anything, so it's a stat like any other rather
# than a new field on Character. Spread across the window with the golden
# ratio's conjugate rather than evenly divided by headcount, so the spread
# stays good however many residents there end up being and never collapses
# them all onto the same tick the way a naive index-mod-N can for a small
# window and a large village.
const _PHASE_STAGGER := 0.6180339887498949

func add_character(who: Character) -> void:
	if not characters.has(who):
		var window := WorldTune.RECONSIDER_SWEEP_SECONDS
		who.set_stat(&"reconsider_phase", fmod(characters.size() * _PHASE_STAGGER * window, window))
		characters.append(who)
