extends SceneTree

# Standing verification. Not a test framework — no fixtures, no mocks, no
# runner, no GUT, no GdUnit. One file that loads the real game scene, pumps the
# real Zoogs by hand, and says PASS or FAIL out loud.
#
# It exists because "it runs without errors" has been demonstrated to mean
# nothing here: a silent null guard shipped a dead day/night cycle through two
# commits, and nothing complained. Everything below this rung is gated on it.
#
# RUN IT WITH TWO COMMANDS, ALWAYS:
#
#   Godot_v4.4-stable_mono_win64_console.exe --headless --path . --editor --quit
#   Godot_v4.4-stable_mono_win64_console.exe --headless --path . --script game/probe.gd
#
# `--script` does NOT build the global class cache. Without the import pass in
# front of it, `class_name Person` fails to resolve and the probe dies for a
# reason that has nothing to do with the code you changed. (Measured.)
#
# Three more engine behaviours this file is shaped around, all measured against
# the 4.4 binary, none of them worth rediscovering:
#
#   PROCESS_MODE_DISABLED, never set_process(false). set_process(false) called
#   from _initialize() is silently discarded and the node ticks anyway — so a
#   probe that disables a person and then pumps him by hand gets a
#   DOUBLE-TICKED person, adenosine advancing at twice the pumped rate. That
#   presents as a tuning problem rather than a harness problem, which is how it
#   costs a day. Setting process_mode leaks zero frames, works from
#   _initialize, and inherits down to Brain, Stats and Readout for free.
#
#   _initialize() runs before anything is in the tree. Setup belongs there;
#   every assertion waits for the first _process frame, by which time _ready
#   has run and @onready vars exist.
#
#   With everything disabled, Clock._process never runs and nothing moves time.
#   The harness advances the Clock itself, in the same loop that pumps people
#   and in the same unit, so the two cannot drift apart.


const GAME_SCENE_PATH := "res://game/game.tscn"
const PERSON_SCENE_PATH := "res://game/person.tscn"

# Where the .tscn scan starts. The whole project, not just the scene under the
# probe — the node_paths trap is textual, so this catches it in files nothing
# here ever loads.
const PROJECT_ROOT_DIR := "res://"

# One tick of simulated time, in WORLD HOURS. Everything below Clock is
# denominated in hours, which is what makes this file readable: 0.01 hours is
# 36 world seconds, 2400 ticks is a day, and no assertion anywhere needs to
# know what `day_length_seconds` is set to. Drag that slider all you like; this
# file cannot notice.
#
# Chosen to sit near a real frame at the shipped 60-second day (1/60 real
# second is 0.0067 hours), so the probe pumps him the way the game does rather
# than in coarse jumps that round the cycle somewhere it never actually lands.
const TICK_HOURS := 0.01
const HOURS_IN_A_DAY := 24.0

# Two days, not one, for the per-tick assertions. The cycle is anchored to the
# sun now: he turns in around 22:00 and is up around 06:00, so a probe that
# starts at midnight with an empty tank and stops at hour 24 catches him going
# to bed and quits before he gets up. Nothing was wrong with the assertion; the
# window was cut to a free-running cycle that no longer exists.
const PUMPED_HOURS := 48.0

# Long enough for a disturbed sleeper to be pulled back onto the town's hours —
# measured at about three days — with room to see him hold there afterwards.
const ANCHOR_DAYS := 6


# Every claim the probe made, in the order it first made them, and the first
# failing detail for each. Only the FIRST failure per claim is kept: a per-tick
# assertion that goes wrong goes wrong two thousand times, and a wall of
# identical lines buries the other three assertions — which is exactly how a
# suite stops being read and then gets deleted.
var _claims: Array[String] = []
var _first_failure := {}
var _checks := 0

var _game: Node
var _person: Person
var _clock: Clock
var _population: Population

# Kept only so the report can say what the cycle actually did. Nothing asserts
# against these directly — they are here so a human reading a PASS can still
# see whether the schedule moved.
var _fell_asleep_at_hour := -1.0
var _woke_at_hour := -1.0

# The settled schedule, once the sun has finished pulling him onto it. Reported,
# never asserted against — an assertion naming an hour would be an assertion
# about the tuning board.
var _kept_bedtime := -1.0
var _kept_night := -1.0
var _kept_strong_morning := -1.0


func _initialize() -> void:
	_game = _add_a_disabled_game_scene()


# One instance of the real game scene, disabled and in the tree. Used more than
# once: a check that needs a person at a known starting state gets his own
# world rather than picking through whatever the last check left behind, which
# is what keeps the checks in this file independent of each other's order.
#
# process_mode is set BEFORE add_child so not one frame ticks itself — see the
# header. Never set_process(false).
func _add_a_disabled_game_scene() -> Node:
	var scene: PackedScene = load(GAME_SCENE_PATH) as PackedScene
	if scene == null:
		push_error("probe: could not load %s" % GAME_SCENE_PATH)
		return null
	var instanced := scene.instantiate()
	instanced.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(instanced)
	return instanced


# Everything happens in the first frame and then the probe leaves. By now the
# scene is in the tree and _ready has run everywhere, which is the whole reason
# this isn't in _initialize.
func _process(_delta: float) -> bool:
	if not _is_scene_ready_to_pump():
		_report()
		quit(1)
		return true
	_pump_the_opening_days()
	_check_everyone_is_ticked_once_per_call()
	_check_the_town_survives_losing_somebody()
	_check_a_man_carries_his_place()
	_check_who_is_where_is_asked_not_remembered()
	_check_travel_cost_is_read_and_never_bars()
	_check_the_cycle_is_anchored_to_the_sun()
	_check_two_farmers_one_plot()
	_check_a_claim_survives_a_day_boundary()
	_check_an_unworked_claim_lapses_at_the_boundary()
	_check_a_plot_cannot_be_claimed_from_the_wrong_place()
	_check_freeing_the_holder_frees_the_plot_within_two_ticks()
	_check_no_stations_and_every_station_taken_are_different_counters()
	_check_a_man_walks_the_gap_shut()
	_check_a_plot_is_invisible_from_afar_until_he_arrives()
	_check_he_does_not_bid_for_a_plot_he_can_see_is_taken()
	_check_the_nearer_station_wins_and_moving_a_place_changes_it()
	_check_working_a_plot_yields_grain()
	_check_a_walking_man_produces_nothing()
	_check_taking_more_than_he_has_moves_nothing()
	_check_handing_over_conserves_and_is_all_or_nothing()
	_check_only_creation_and_destruction_move_a_world_total()
	_check_every_scene_is_wired()
	_report()
	quit(0 if _first_failure.is_empty() else 1)
	return true


# Nothing below this can say anything true if the scene didn't come up, and
# most of it would crash trying. Checked separately and bailed on, rather than
# folded into the assertions, so "the probe is broken" never reads as "the
# game is broken".
func _is_scene_ready_to_pump() -> bool:
	if _game == null:
		push_error("probe: the game scene never instantiated")
		return false
	_person = _game.get_node_or_null("Population/Zoogs") as Person
	_clock = _game.get_node_or_null("Clock") as Clock
	_population = _game.get_node_or_null("Population") as Population
	if _person == null:
		push_error("probe: no Person called \"Zoogs\" under Population")
		return false
	if _clock == null:
		push_error("probe: no Clock under the game scene")
		return false
	if _population == null:
		push_error("probe: no Population under the game scene")
		return false
	return true


# --- The pumped day -------------------------------------------------------------

# The opening stretch, one tick at a time, with assertions 1, 2 and 3 riding
# along. They share a loop because they are three questions about the same
# ticks, and pumping him three times would be three different runs.
func _pump_the_opening_days() -> void:
	var ceiling: float = _person.brain.adenosine_ceiling
	var tick_count := int(round(PUMPED_HOURS / TICK_HOURS))
	var has_slept := false
	var has_woken_again := false

	for tick in tick_count:
		var hour := tick * TICK_HOURS

		# ASSERTION 3, first half — snapshot every gate BEFORE the tick.
		#
		# The obvious version of this assertion asks the gate again after the
		# tick, and it is wrong: gates are asked against what he WAS doing.
		# Wake's gate is `not is_awake()`, and the moment Wake becomes the
		# current action he reads as awake — so re-asking afterwards reports
		# the gate shut on the one action legitimately chosen, every single
		# time he gets up. Gates are pure reads, so asking them immediately
		# before think_and_act gives exactly what choose() is about to see.
		var gate_answers := {}
		for action in _person.brain.get_known_actions():
			gate_answers[action.name] = action.is_available_to(_person)

		var tired_before: float = _person.stats.get_stat(&"adenosine")

		_clock.advance(TICK_HOURS)
		# Driven through Population rather than by poking the Person, so these
		# three assertions cover the real call site the game uses. Reaching
		# past the driver would leave the one thing rung 1 added untested by
		# the three checks most likely to notice it misbehaving.
		_population.think_for_everyone(TICK_HOURS)

		var tired_after: float = _person.stats.get_stat(&"adenosine")
		var is_awake_now: bool = _person.brain.is_awake()

		# ASSERTION 3, second half.
		var chosen: Action = _person.brain.current_action
		if chosen != null:
			var was_gate_open: bool = gate_answers.get(chosen.name, false)
			_require(was_gate_open,
				"3 — no action is ever chosen while its own gate says no",
				"chose \"%s\" at hour %.2f while its gate said no" % [chosen.name, hour])

		# ASSERTION 2 — the body only ever moves the way what he's doing says.
		#
		# Loose comparison first, because _update_body clamps into
		# [0, ceiling] and a clamped value is allowed to stand still. Then the
		# strict one, guarded by the clamp that would flatten it — pinned at
		# the ceiling he cannot rise, and empty he cannot fall, and neither is
		# a bug. Everywhere in between, standing still IS a bug: it means a
		# rate reached zero or the drift stopped being applied.
		if is_awake_now:
			_require(tired_after >= tired_before,
				"2 — adenosine rises while awake and falls while asleep",
				"awake at hour %.2f and adenosine fell, %.4f → %.4f" % [hour, tired_before, tired_after])
			if tired_before < ceiling:
				_require(tired_after > tired_before,
					"2 — adenosine rises while awake and falls while asleep",
					"awake at hour %.2f below the ceiling and adenosine did not rise, %.4f → %.4f" % [hour, tired_before, tired_after])
		else:
			_require(tired_after <= tired_before,
				"2 — adenosine rises while awake and falls while asleep",
				"asleep at hour %.2f and adenosine rose, %.4f → %.4f" % [hour, tired_before, tired_after])
			if tired_before > 0.0:
				_require(tired_after < tired_before,
					"2 — adenosine rises while awake and falls while asleep",
					"asleep at hour %.2f above empty and adenosine did not fall, %.4f → %.4f" % [hour, tired_before, tired_after])

		# ASSERTION 1's raw material. He starts awake, so waking only counts
		# once he has been under — otherwise the first tick satisfies it.
		if not is_awake_now and not has_slept:
			has_slept = true
			_fell_asleep_at_hour = hour
		elif is_awake_now and has_slept and not has_woken_again:
			has_woken_again = true
			_woke_at_hour = hour

	# ASSERTION 1. Stated in simulated hours and nowhere near a real second, so
	# dragging day_length_seconds on the tuning board cannot turn it red.
	_require(has_slept,
		"1 — he sleeps at least once and wakes at least once",
		"never slept in %.0f simulated hours — adenosine reached %.2f against StayUp's pull" % [
			PUMPED_HOURS, _person.stats.get_stat(&"adenosine")])
	_require(has_woken_again,
		"1 — he sleeps at least once and wakes at least once",
		"slept at hour %.2f and was still under at hour %.0f" % [_fell_asleep_at_hour, PUMPED_HOURS])


# --- Assertion 5: exactly one tick each, per call --------------------------------

# The hazard this catches is specific and was measured: if Person._process is
# still calling think_and_act, or if a node the harness meant to disable is
# ticking anyway, the man advances TWICE per pumped tick. Nothing errors.
# Adenosine simply climbs at double the rate and it reads as a tuning problem,
# which is how it costs a day to find.
#
# Asserted on an observable — how far he actually moved — rather than on a
# counter the probe installs. A counter would need a fixture and would only
# ever prove the fixture was called.
#
# On a FRESH world, so the numbers are exact: adenosine starts at 0, he is
# awake, nothing is clamped, and one hour must move him by exactly one hour's
# worth of accumulation. The claim is per think_for_everyone CALL, not per
# frame — there are no frames in a pumped harness.
func _check_everyone_is_ticked_once_per_call() -> void:
	var claim := "5 — Population moves each person exactly once per call"
	var world := _add_a_disabled_game_scene()
	var person := world.get_node_or_null("Population/Zoogs") as Person
	var population := world.get_node_or_null("Population") as Population
	if person == null or population == null:
		_require(false, claim, "a second game scene came up without a Population and a Zoogs in it")
		return

	var tired_before: float = person.stats.get_stat(&"adenosine")
	population.think_for_everyone(1.0)
	var moved: float = person.stats.get_stat(&"adenosine") - tired_before
	var expected: float = person.brain.get_adenosine_accumulation()

	var ticks_worth := moved / expected if expected != 0.0 else 0.0
	_require(absf(moved - expected) < 0.001, claim,
		"one hour moved adenosine by %.4f where one tick's worth is %.4f — that is %.2f ticks, so something besides Population is moving him" % [
			moved, expected, ticks_worth])

	world.queue_free()


# --- Assertion 6: losing somebody mid-run ----------------------------------------

# Standing check #1, made mechanical: delete a person mid-run and the town must
# return a verdict rather than a stack trace.
#
# Two hazards, both real. A freed node does NOT null your reference —
# `== null` stays false and the next property read errors — which is why the
# loop asks is_instance_valid rather than trusting the list. And get_children()
# hands back a SNAPSHOT, so somebody freed part-way through a tick is still in
# the list being walked.
#
# Also checks the loop tolerates a child that isn't a Person at all. Somebody
# will drop a marker or a spawn point under Population eventually, and a driver
# that crashes on it is a trap laid for a future rung.
func _check_the_town_survives_losing_somebody() -> void:
	var claim := "6 — losing a person mid-run leaves the rest of the town ticking"
	var world := _add_a_disabled_game_scene()
	var population := world.get_node_or_null("Population") as Population
	var survivor := world.get_node_or_null("Population/Zoogs") as Person
	if population == null or survivor == null:
		_require(false, claim, "a second game scene came up without a Population and a Zoogs in it")
		return

	var person_scene: PackedScene = load(PERSON_SCENE_PATH) as PackedScene
	if person_scene == null:
		_require(false, claim, "could not load %s" % PERSON_SCENE_PATH)
		return
	var doomed := person_scene.instantiate() as Person
	doomed.name = "Doomed"
	doomed.person_name = "Doomed"
	population.add_child(doomed)
	# Not a Person. The loop must walk straight past it.
	#
	# Moved to the FRONT deliberately. A loop that doesn't skip it calls
	# think_and_act on a plain Node, which aborts think_for_everyone where it
	# stands — so with the marker last, everybody has already ticked and this
	# check passes while broken. First, the abort happens before Zoogs moves at
	# all, and the survivor's numbers below go wrong. Order is the only thing
	# making this assertion able to fail.
	var bystander := Node.new()
	bystander.name = "SomeMarker"
	population.add_child(bystander)
	population.move_child(bystander, 0)

	population.think_for_everyone(1.0)
	# 3 = the two authored farmers plus Doomed. This number reads the authored
	# population, so adding a person to game.tscn moves it — rung 3 took it from
	# 2 to 3 when Hobb was authored in.
	_require(population.get_people().size() == 3, claim,
		"expected 3 people under Population and found %d — the marker node was counted as one" % [
			population.get_people().size()])

	# Freed outright rather than queue_free()d: queued deletion doesn't land
	# until the end of the frame, so within one pumped tick the node is still
	# perfectly valid and the guard this is here to exercise never runs.
	doomed.free()

	var tired_before: float = survivor.stats.get_stat(&"adenosine")
	population.think_for_everyone(1.0)
	var moved: float = survivor.stats.get_stat(&"adenosine") - tired_before
	var expected: float = survivor.brain.get_adenosine_accumulation()

	_require(absf(moved - expected) < 0.001, claim,
		"after a death the survivor moved %.4f where one tick's worth is %.4f" % [moved, expected])
	_require(population.get_people().size() == 2, claim,
		"expected 2 people left and found %d" % population.get_people().size())

	world.queue_free()


# --- Assertion 7: a man carries his place ----------------------------------------

# Place is a discrete fact he holds, not a result derived from where he is
# standing. The last assertion in here is the important one: it is the mechanical
# guard against the proximity model that was reverted on 2026-08-08 coming back
# in through a side door. If standing somewhere starts changing where a man IS,
# gates begin flickering at a radius edge and nothing in the design can smooth it.
func _check_a_man_carries_his_place() -> void:
	var claim := "7 — a man's place is a fact he carries, never a proximity result"
	var world := _add_a_disabled_game_scene()
	var population := world.get_node_or_null("Population") as Population
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var inn := world.get_node_or_null("Town/Inn") as Place
	if population == null or zoogs == null or fields == null or inn == null:
		_require(false, claim, "the scene came up without a Population, a Zoogs, and a Town holding Fields and Inn")
		return

	# Authored in game.tscn — and this doubles as the one check that would catch
	# `current_place` losing its node_paths header, because a node reference the
	# loader refused to resolve arrives here as exactly this null.
	#
	# THE INN AS OF RUNG 4, and deliberately: both farmers were re-authored there
	# so that the walk to work is something the shipped scene does on its own
	# rather than something you stage by dragging a capsule. This expectation
	# reads the authored population, so it moves whenever that does — it moved at
	# rung 3 too, for Hobb.
	_require(zoogs.get_current_place() == inn, claim,
		"Zoogs is authored at the Inn and reports %s" % _describe_place(zoogs.get_current_place()))

	var newcomer := _add_a_person(population, "Newcomer")
	if newcomer == null:
		_require(false, claim, "could not instance %s" % PERSON_SCENE_PATH)
		return

	_require(newcomer.get_current_place() == null, claim,
		"a man nobody has placed reports %s — something is defaulting it" % _describe_place(newcomer.get_current_place()))

	newcomer.current_place = fields
	_require(newcomer.get_current_place() == fields, claim,
		"put at the fields and reports %s" % _describe_place(newcomer.get_current_place()))
	newcomer.current_place = inn
	_require(newcomer.get_current_place() == inn, claim,
		"moved to the Inn and reports %s" % _describe_place(newcomer.get_current_place()))

	# Standing somewhere is not being there. His BODY goes to the fields and he
	# is still at the Inn, because nothing derives place from a transform.
	newcomer.global_position = fields.global_position
	_require(newcomer.get_current_place() == inn, claim,
		"standing him on the fields changed his place to %s — place is being derived from distance again" % [
			_describe_place(newcomer.get_current_place())])

	world.queue_free()


# --- Assertion 8: who is where ---------------------------------------------------

# find_people_at is a QUERY — it loops the people and asks each one. So the plan's
# original assertion here ("the index and the fact never disagree") is vacuous:
# there is one copy of the fact and one copy cannot contradict itself. That
# assertion is banked in town.gd against the day an index exists to disagree.
#
# These have teeth instead: the exact set, a man who moves without anything being
# invalidated by hand, and a man who dies.
func _check_who_is_where_is_asked_not_remembered() -> void:
	var claim := "8 — find_people_at returns exactly who is there, and nobody else"
	var world := _add_a_disabled_game_scene()
	var town := world.get_node_or_null("Town") as Town
	var population := world.get_node_or_null("Population") as Population
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var hobb := world.get_node_or_null("Population/Hobb") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var inn := world.get_node_or_null("Town/Inn") as Place
	if town == null or population == null or zoogs == null or hobb == null or fields == null or inn == null:
		_require(false, claim, "the scene came up without a Town, a Population, a Zoogs, a Hobb, Fields and an Inn")
		return

	var mara := _add_a_person(population, "Mara")
	var bram := _add_a_person(population, "Bram")
	var wisp := _add_a_person(population, "Wisp")
	if mara == null or bram == null or wisp == null:
		_require(false, claim, "could not instance %s" % PERSON_SCENE_PATH)
		return
	mara.current_place = fields
	bram.current_place = inn
	# Wisp is at no place at all — on the road, as far as anyone can tell.

	# The expected sets read the AUTHORED population, so they move whenever the
	# authored placement does. Hobb joined the Fields at rung 3; at rung 4 BOTH
	# farmers were re-authored to the Inn, so the fields hold nobody but the
	# spare the probe puts there.
	_require_exactly(town.find_people_at(fields), [mara], claim, "at the fields")
	_require_exactly(town.find_people_at(inn), [zoogs, hobb, bram], claim, "at the Inn")

	# Nothing is invalidated, nothing is notified, nothing is re-posted. The next
	# call simply asks again, which is the whole argument for a query.
	mara.current_place = inn
	_require_exactly(town.find_people_at(fields), [], claim, "at the fields once Mara left")
	_require_exactly(town.find_people_at(inn), [zoogs, hobb, bram, mara], claim, "at the Inn once Mara arrived")

	# STRUCTURALLY SATISFIED TODAY — say so rather than let it read as covered.
	# find_people_at asks the living, and free() takes Bram out of the child list
	# at once, so there is no path by which he could come back. Measured:
	# deleting the is_instance_valid guard in town.gd leaves this green. It grows
	# teeth the day find_people_at holds a list, which is the same day the banked
	# index-disagreement assertion does — both are waiting on the same change.
	#
	# free() rather than queue_free() regardless: queued deletion doesn't land
	# until the end of the frame, so within one pumped tick he would still be a
	# perfectly valid child and this would be testing nothing at all.
	bram.free()
	_require_exactly(town.find_people_at(inn), [zoogs, hobb, mara], claim, "at the Inn once Bram died")

	# Nobody is at nowhere. If this ever returns Wisp, then every man walking a
	# road counts as standing with every other man walking a road, and rung 7
	# trades between two people half a town apart.
	_require_exactly(town.find_people_at(null), [], claim, "at nowhere")

	world.queue_free()


# --- Assertion 9: travel cost ----------------------------------------------------

# Cost is read off the transforms every time it is asked, which is what makes
# standing check #3 mechanical — drag a place and this moves. And it never bars:
# there is no distance at which a place stops being an option, only one at which
# it is outbid.
func _check_travel_cost_is_read_and_never_bars() -> void:
	var claim := "9 — travel cost is read off the transforms and never bars a place"
	var world := _add_a_disabled_game_scene()
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var inn := world.get_node_or_null("Town/Inn") as Place
	if zoogs == null or fields == null or inn == null:
		_require(false, claim, "the scene came up without a Zoogs, Fields and an Inn")
		return

	zoogs.global_position = inn.global_position
	_require(is_zero_approx(zoogs.get_travel_cost_to(inn)), claim,
		"standing on the Inn cost him %.4f to reach" % zoogs.get_travel_cost_to(inn))

	var away := inn.global_position + Vector3(30.0, 0.0, 30.0)
	zoogs.global_position = away
	var cost_from_there: float = zoogs.get_travel_cost_to(inn)

	zoogs.global_position = away.lerp(inn.global_position, 0.5)
	var cost_from_halfway: float = zoogs.get_travel_cost_to(inn)
	_require(cost_from_halfway < cost_from_there, claim,
		"walked half way to the Inn and the cost did not fall, %.2f → %.2f" % [cost_from_there, cost_from_halfway])

	zoogs.global_position = away + Vector3(20.0, 0.0, 20.0)
	var cost_from_further: float = zoogs.get_travel_cost_to(inn)
	_require(cost_from_further > cost_from_there, claim,
		"walked away from the Inn and the cost did not rise, %.2f → %.2f" % [cost_from_there, cost_from_further])

	# Absurdly far, and still a price rather than a refusal. INF or NAN here
	# would poison the candidate ordering in Town.find_workstations — every
	# comparison against NAN is false, so a sort over one would land wherever the
	# algorithm happened to leave it, and a station in the next county could come
	# back as the nearest. "Outbid, never barred" is the one thing travel cost is
	# not allowed to stop being.
	#
	# (This comment used to say "rung 4's falloff curve". There is no falloff
	# curve: Decision 14 cut it and the multiplier with it, and Decision 15 then
	# confined travel cost to ordering an action's own candidates. Nothing in
	# game/ has ever had a `distance_that_halves_appeal`.)
	zoogs.global_position = Vector3(100000.0, 0.0, 100000.0)
	var absurd: float = zoogs.get_travel_cost_to(fields)
	_require(is_finite(absurd) and absurd > 0.0, claim,
		"a place 140km away priced at %f — a far place must be expensive, never unreachable" % absurd)

	world.queue_free()


# --- Assertions 10 and 11: the sun holds the cycle in place ----------------------

# Adenosine alone gives a cycle whose length is whatever the two rates happen to
# add up to. Measured before this landed: 19.6 hours, so bedtime slid 4.4 hours
# earlier every day and by day two he was asleep at nine in the morning. Tuning
# the rates to sum to 24 would fix the PERIOD and not the PHASE — nothing would
# pull him back, so one disturbed night would move him permanently.
#
# Both claims below are about the RESTORING FORCE and neither mentions a tuned
# number. "Bedtime is around 22:00" would be an assertion about the tuning board
# and would go red the first time anybody dragged a slider, which is the
# flakiness rung 0 spent its time removing. So: he goes to bed in the DARK
# (semantic, survives any retune), his hours STOP MOVING (structural), and two
# men who start from different histories end up keeping the SAME hours
# (structural, and the thing the anchor is actually for). The measured schedule
# is printed in the report instead, where a human can see it change.
func _check_the_cycle_is_anchored_to_the_sun() -> void:
	var anchored := "10 — the cycle holds its hour instead of drifting round the clock"
	var together := "11 — two people who start from different histories keep the same hours"
	var world := _add_a_disabled_game_scene()
	var population := world.get_node_or_null("Population") as Population
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	if population == null or clock == null or zoogs == null:
		_require(false, anchored, "the scene came up without a Population, a Clock and a Zoogs")
		return

	# A second man with a very different history — most of a day's tiredness
	# already on him at midnight, so his first night lands in the afternoon. If
	# the sun is doing anything, it drags him onto the same hours as Zoogs.
	var stranger := _add_a_person(population, "Stranger")
	# And a strong one. Same scene, same sun, same formula — a bigger body, so
	# he clears the same debt in fewer hours and is up before the others.
	var ox := _add_a_person(population, "Ox")
	if stranger == null or ox == null:
		_require(false, anchored, "could not instance %s" % PERSON_SCENE_PATH)
		return
	stranger.stats.set_stat(&"adenosine", 44.0)
	ox.stats.set_stat(&"strength", 1.15)

	var watched: Array[Person] = [zoogs, stranger, ox]
	var diary := {}
	for person in watched:
		diary[person] = {
			"awake": person.brain.is_awake(),
			"asleep_since": 0.0,
			"bedtimes": [],     # hour of day he turned in, one per night
			"mornings": [],     # hour of day he got up
			"nights": [],       # how long each night lasted, in hours
		}

	for tick in int(round(ANCHOR_DAYS * HOURS_IN_A_DAY / TICK_HOURS)):
		clock.advance(TICK_HOURS)
		population.think_for_everyone(TICK_HOURS)
		for person in watched:
			var entry: Dictionary = diary[person]
			var awake_now: bool = person.brain.is_awake()
			if awake_now == entry["awake"]:
				continue
			if awake_now:
				entry["nights"].append(clock.hours_elapsed - float(entry["asleep_since"]))
				entry["mornings"].append(clock.time_of_day() * HOURS_IN_A_DAY)
			else:
				entry["bedtimes"].append(clock.time_of_day() * HOURS_IN_A_DAY)
				entry["asleep_since"] = clock.hours_elapsed
			entry["awake"] = awake_now

	var his_bedtimes: Array = diary[zoogs]["bedtimes"]
	var his_nights: Array = diary[zoogs]["nights"]
	_require(his_bedtimes.size() >= 4, anchored,
		"only %d nights in %d simulated days — he is barely sleeping" % [
			his_bedtimes.size(), ANCHOR_DAYS])
	if his_bedtimes.size() < 4:
		world.queue_free()
		return

	# He goes to bed in the dark. Stated as sun height rather than as an hour, so
	# it survives every retune and still means what it says.
	for bedtime: float in his_bedtimes.slice(1):
		_require(_get_sun_height_at(bedtime) < 0.0, anchored,
			"turned in at %s, with the sun still up" % _as_clock_text(bedtime))

	# And stops moving. A free-running cycle slips hours per day; an anchored one
	# lands on the same minute.
	var last: float = his_bedtimes[his_bedtimes.size() - 1]
	var before_last: float = his_bedtimes[his_bedtimes.size() - 2]
	_require(absf(last - before_last) < 0.25, anchored,
		"bedtime moved from %s to %s between the last two nights — it is still drifting" % [
			_as_clock_text(before_last), _as_clock_text(last)])
	_kept_bedtime = last
	if not his_nights.is_empty():
		_kept_night = his_nights[his_nights.size() - 1]

	# ASSERTION 11. Two histories, one town, one set of hours.
	var stranger_bedtimes: Array = diary[stranger]["bedtimes"]
	_require(not stranger_bedtimes.is_empty(), together,
		"the stranger never slept at all in %d simulated days" % ANCHOR_DAYS)
	if not stranger_bedtimes.is_empty():
		var his: float = stranger_bedtimes[stranger_bedtimes.size() - 1]
		_require(absf(his - last) < 0.5, together,
			"after %d days Zoogs turns in at %s and the stranger at %s — the sun is not pulling them together" % [
				ANCHOR_DAYS, _as_clock_text(last), _as_clock_text(his)])

	# ASSERTION 12. The one difference the sun does NOT flatten — and the reason
	# two farmers racing for one plot is a contest rather than a coin flip
	# decided by scene order.
	#
	# Stated as "earlier than the ordinary man", never as an hour: it is about
	# the SIGN of what strength does, which is the thing that would go wrong. Put
	# strength on how fast he tires instead and this fails, because a man who
	# tires slowly goes to bed later and gets up later — measured, and the whole
	# reason it hangs on recovery.
	var strongest := "12 — a stronger body clears the night faster, so he is up first"
	var his_mornings: Array = diary[zoogs]["mornings"]
	var ox_mornings: Array = diary[ox]["mornings"]
	var ox_bedtimes: Array = diary[ox]["bedtimes"]
	_require(not his_mornings.is_empty() and not ox_mornings.is_empty(), strongest,
		"one of them never got up at all in %d simulated days" % ANCHOR_DAYS)
	if not his_mornings.is_empty() and not ox_mornings.is_empty():
		var ordinary: float = his_mornings[his_mornings.size() - 1]
		var strong: float = ox_mornings[ox_mornings.size() - 1]
		_require(strong < ordinary, strongest,
			"the strong man rose at %s and the ordinary one at %s — strength is not buying him the morning" % [
				_as_clock_text(strong), _as_clock_text(ordinary)])
		_kept_strong_morning = strong
	# And he is still anchored. A trait that bought an early start by unhooking
	# him from the sun would be a drift dressed as a difference.
	if ox_bedtimes.size() >= 2:
		_require(absf(float(ox_bedtimes[ox_bedtimes.size() - 1])
				- float(ox_bedtimes[ox_bedtimes.size() - 2])) < 0.25, strongest,
			"the strong man's bedtime is still moving — strength unhooked him from the sun")

	world.queue_free()


# The same shape the Clock uses, worked out for an arbitrary hour of day so a
# bedtime that already happened can be asked about after the fact.
func _get_sun_height_at(hour_of_day: float) -> float:
	return sin((hour_of_day / HOURS_IN_A_DAY - 0.25) * TAU)


# --- Assertions 13-18: two farmers, one plot -------------------------------------

# Rung 3's whole point, made mechanical: one Workstation, two men who both know
# WorkTheField, and a schedule that is supposed to be the thing that decides
# between them rather than which node happens to sit first under Population.

# Both farmers are put to bed together — adenosine above StayUp's 50 sends both
# to Sleep on the very next tick, from the same hour, same place, same debt.
# From there only strength differs: Hobb clears 58 at 5.75/hour and wakes first;
# Zoogs clears it at 5.0/hour and is still under when Hobb reaches the plot. If
# strength were inert here, both would wake the same tick and the winner would
# be decided by scene order, which is exactly the failure this claim exists to
# catch — recording WHO claimed day 2's plot first and WHETHER Zoogs was still
# asleep when it happened, not just who holds it at the end.
func _check_two_farmers_one_plot() -> void:
	var claim := "13 — two farmers, one plot: the early riser claims it and the loser is never scored"
	var world := _add_a_disabled_game_scene()
	var population := world.get_node_or_null("Population") as Population
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var hobb := world.get_node_or_null("Population/Hobb") as Person
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var fields := world.get_node_or_null("Town/Fields") as Place
	var work_action := world.get_node_or_null("Population/Zoogs/Brain/WorkTheField") as WorkTheField
	if population == null or clock == null or zoogs == null or hobb == null or plot == null or fields == null or work_action == null:
		_require(false, claim, "the scene came up without a Population, a Clock, a Zoogs, a Hobb, the Plot, the Fields and Zoogs' WorkTheField")
		return

	# BOTH MEN PINNED ON THE FIELDS, and this is the whole point of the pin. This
	# claim is about a SLEEP-ORDER race — Hobb clears the same debt faster, so he
	# is up first and takes the plot while Zoogs is still under. Left to the
	# authored scene at rung 4 both men start at the Inn, so Hobb would wake,
	# WALK, and claim some eight world minutes later — still comfortably inside
	# the pump window, so this claim would go on passing while quietly having
	# become a claim about travel time fitting in a ten-hour pump. It did exactly
	# that when rung 4 first ran, which is how the pin got written. Standing them
	# both in the furrow puts the race back to the one thing it is about.
	_stand_at(zoogs, fields)
	_stand_at(hobb, fields)

	clock.advance(46.0)
	zoogs.stats.set_stat(&"adenosine", 58.0)
	hobb.stats.set_stat(&"adenosine", 58.0)

	var first_claimant_of_day_2: Person = null
	var zoogs_was_asleep_when_claimed := false
	var tick_count := int(round(10.0 / TICK_HOURS))
	for tick in tick_count:
		clock.advance(TICK_HOURS)
		population.think_for_everyone(TICK_HOURS)
		# Only the FIRST such tick matters — everything after it is the same fact
		# restated, and recording it more than once would just be racing the loop
		# against itself.
		if first_claimant_of_day_2 == null and plot.claimed_on_day == 2:
			first_claimant_of_day_2 = plot.claimed_by
			zoogs_was_asleep_when_claimed = not zoogs.brain.is_awake()

	_require(first_claimant_of_day_2 == hobb, claim,
		"the first man holding day 2's plot was %s, not Hobb — strength did not decide the race" % [
			(first_claimant_of_day_2.person_name if first_claimant_of_day_2 != null else "nobody")])
	_require(zoogs_was_asleep_when_claimed, claim,
		"Hobb claimed day 2's plot while Zoogs was already up — either they woke together and scene order decided it, or Zoogs got there first")
	_require(plot.claimed_by == hobb, claim,
		"at the end of the pump the plot reads held by %s, not Hobb" % [
			(plot.claimed_by.person_name if plot.claimed_by != null else "nobody")])
	_require(not plot.claim(zoogs), claim,
		"Zoogs was able to claim a plot Hobb already holds")
	_require(plot.claimed_by == hobb, claim,
		"after Zoogs' failed claim the plot reads held by %s" % [
			(plot.claimed_by.person_name if plot.claimed_by != null else "nobody")])
	_require(zoogs.brain.is_awake(), claim,
		"Zoogs is still asleep at the end of a ten-hour pump that started at 22:00")

	# is_nan, not a low score: the loser was never on the ballot at all, and the
	# graph draws that as a hole rather than a losing line. A plain low number
	# here would mean he was OUTscored, which is a different (and false) claim.
	var score: Variant = zoogs.brain.get_last_scores().get(work_action.name)
	var zoogs_score_is_off_the_ballot := false
	if score is float:
		var score_value: float = score
		zoogs_score_is_off_the_ballot = is_nan(score_value)
	_require(zoogs_score_is_off_the_ballot, claim,
		"Zoogs' last WorkTheField score reads %s — the loser must be OFF the ballot (NAN), not merely outscored" % str(score))

	var hobb_action: Action = hobb.brain.current_action
	_require(hobb_action != null and String(hobb_action.name) == String(work_action.name), claim,
		"Hobb's current action reads \"%s\", not WorkTheField" % [
			String(hobb_action.name) if hobb_action != null else "nothing"])

	world.queue_free()


# The renew mechanism, isolated from the decision layer. At 23:30 the decision
# layer would already be sending him to bed, so this drives the STEP directly —
# claim() on every tick it advances — to prove the day boundary itself is
# survived by a man being worked, independent of whether he'd choose to be
# there.
func _check_a_claim_survives_a_day_boundary() -> void:
	var claim := "14 — a claim survives a day boundary while being worked"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var hobb := world.get_node_or_null("Population/Hobb") as Person
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var fields := world.get_node_or_null("Town/Fields") as Place
	var hobb_work := world.get_node_or_null("Population/Hobb/Brain/WorkTheField") as WorkTheField
	if clock == null or zoogs == null or hobb == null or plot == null or fields == null or hobb_work == null:
		_require(false, claim, "the scene came up without a Clock, a Zoogs, a Hobb, the Plot, the Fields and Hobb's WorkTheField")
		return

	# Pinned rather than taken on trust from the scene — see _stand_at. This
	# claim is about the day boundary, and it should not be able to go red
	# because somebody moved where a farmer is authored. Hobb has to be IN the
	# furrow for the step below to renew instead of setting off for it.
	_stand_at(hobb, fields)

	clock.advance(23.5)
	_require(plot.claim(hobb), claim, "Hobb, standing at the fields, could not claim the plot at 23:30")
	_require(plot.claimed_on_day == 0, claim,
		"claimed at 23:30 on day 0 and stamped day %d instead" % plot.claimed_on_day)
	_require(not plot.is_free_for(zoogs), claim,
		"the plot read free for Zoogs the moment Hobb held it")

	for tick in 100:
		clock.advance(TICK_HOURS)
		hobb_work.step.advance(hobb, TICK_HOURS)

	_require(clock.day() == 1, claim,
		"100 ticks of %.2f hours from 23:30 should cross midnight and landed on day %d instead" % [TICK_HOURS, clock.day()])
	_require(plot.claimed_by == hobb, claim,
		"after crossing midnight under a working man the plot reads held by %s, not Hobb" % [
			(plot.claimed_by.person_name if plot.claimed_by != null else "nobody")])
	# The re-stamp is the whole mechanism: dawn passed under him and nothing
	# expired because claim() ran again on every tick the step advanced.
	_require(plot.claimed_on_day == 1, claim,
		"the step advanced across the boundary and the stamp still reads day %d — renew-on-use did not fire" % plot.claimed_on_day)
	_require(not plot.is_free_for(zoogs), claim,
		"a plot being worked through the boundary read free for somebody else")

	world.queue_free()


# The mirror of claim 14: a claim NOBODY renews. Lazy expiry means the day
# boundary itself does the work — nothing sweeps, and no tick is pumped between
# the claim and the read below, which is the entire point being proven.
func _check_an_unworked_claim_lapses_at_the_boundary() -> void:
	var claim := "15 — a claim nobody is working lapses at the day boundary"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var hobb := world.get_node_or_null("Population/Hobb") as Person
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var fields := world.get_node_or_null("Town/Fields") as Place
	if clock == null or zoogs == null or hobb == null or plot == null or fields == null:
		_require(false, claim, "the scene came up without a Clock, a Zoogs, a Hobb, the Plot and the Fields")
		return

	# Both pinned in the furrow — see _stand_at. This claim is about lazy expiry
	# at the day boundary; where the two of them are authored has nothing to do
	# with it, and both have to be present because both take a turn claiming.
	_stand_at(zoogs, fields)
	_stand_at(hobb, fields)

	clock.advance(10.0)
	_require(plot.claim(hobb), claim, "Hobb, standing at the fields, could not claim the plot at 10:00")
	_require(not plot.is_free_for(zoogs), claim, "the plot read free for Zoogs while Hobb held it, same day")

	# No think_for_everyone here, and none needed — the claim expires where it
	# lies the moment somebody asks, with nothing having touched the plot at all.
	clock.advance(15.0)
	_require(plot.is_free_for(zoogs), claim,
		"yesterday's claim still reads held on day %d, though nothing has touched the plot since" % clock.day())
	_require(plot.claim(zoogs), claim, "Zoogs could not claim a plot that lapsed under nobody")
	_require(plot.claimed_by == zoogs, claim,
		"after Zoogs' claim the plot reads held by %s, not Zoogs" % [
			(plot.claimed_by.person_name if plot.claimed_by != null else "nobody")])
	_require(plot.claimed_on_day == 1, claim,
		"Zoogs claimed on day %d and the stamp reads day %d" % [clock.day(), plot.claimed_on_day])

	world.queue_free()


# claim()'s presence check, isolated from is_free_for's deliberate lack of one.
# Seeing a free plot from across town must stay legal — it is what lets a man
# decide whether there is work for him before he has walked there, and rung 4's
# walk-there-and-work could never even score without it. Taking it is a
# different question, and only claim() asks it.
func _check_a_plot_cannot_be_claimed_from_the_wrong_place() -> void:
	var claim := "16 — a plot cannot be claimed from the wrong place"
	var world := _add_a_disabled_game_scene()
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var fields := world.get_node_or_null("Town/Fields") as Place
	var inn := world.get_node_or_null("Town/Inn") as Place
	if zoogs == null or plot == null or fields == null or inn == null:
		_require(false, claim, "the scene came up without a Zoogs, the Plot, Fields and an Inn")
		return

	zoogs.current_place = inn
	_require(plot.is_free_for(zoogs), claim,
		"the plot read taken for a man standing at the Inn who has never touched it — freeness must not require presence")
	_require(not plot.claim(zoogs), claim,
		"Zoogs claimed a plot in the fields while standing at the Inn — you cannot reserve a plot from your bed")
	_require(plot.claimed_by == null, claim,
		"a claim attempted from the wrong place still landed — claimed_by reads %s" % [
			(plot.claimed_by.person_name if plot.claimed_by != null else "nobody")])

	zoogs.current_place = fields
	_require(plot.claim(zoogs), claim,
		"the same man, same plot, now standing at the fields, still could not claim it")

	world.queue_free()


# Standing check #1 (the probe's own name for it), made to run against
# Workstation specifically: delete the holder mid-run and the town must return
# a verdict — the plot frees — rather than a stack trace. free() rather than
# queue_free(): queued deletion doesn't land until end of frame, so inside a
# pumped tick the node would still be perfectly valid and nothing stale would
# exist to survive. See claim 8.
#
# WHAT THIS DOES NOT PROVE — measured 2026-08-10, the same day it was written.
# It was expected to be the first claim to exercise is_free_for's
# is_instance_valid guard, rung 3 being the first rung where one person holds a
# reference to another across ticks. It cannot: a TRULY freed reference already
# compares `== null` as true in this engine (unlike a queue_free()d one inside
# its final frame, which is the case CLAUDE.md warns about), so is_free_for's
# own null branch produces the passing answer with the guard deleted — the
# break was tried, and the probe stayed green with zero errors. That makes
# THREE is_instance_valid guards standing unreachable in this codebase for the
# same engine reason, all kept: `== null` catching freed objects is an
# undocumented quirk, is_instance_valid is the documented contract, and the
# guard is one line. The claim keeps its behavioural teeth (13a, 15, 16 and 18
# all went red on cue in the same session); it just doesn't have THESE teeth.
func _check_freeing_the_holder_frees_the_plot_within_two_ticks() -> void:
	var claim := "17 — free the holder and the plot frees within two ticks"
	var world := _add_a_disabled_game_scene()
	var population := world.get_node_or_null("Population") as Population
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var hobb := world.get_node_or_null("Population/Hobb") as Person
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var fields := world.get_node_or_null("Town/Fields") as Place
	if population == null or clock == null or zoogs == null or hobb == null or plot == null or fields == null:
		_require(false, claim, "the scene came up without a Population, a Clock, a Zoogs, a Hobb, the Plot and the Fields")
		return

	# Both pinned in the furrow — see _stand_at. What is under test is a holder
	# being deleted, so both men need to be standing where they can claim, and
	# neither should be walking anywhere during the two ticks below.
	_stand_at(zoogs, fields)
	_stand_at(hobb, fields)

	_require(plot.claim(hobb), claim, "Hobb could not claim the plot at hour 0")
	_require(not plot.claim(zoogs), claim, "Zoogs claimed a plot Hobb already held")

	hobb.free()

	# Zoogs' own gate walks is_free_for over the now-freed claimed_by on each of
	# these ticks. Not, it turns out, to exercise the is_instance_valid guard —
	# see the header — but the walk itself still matters: a crash anywhere in
	# gate, score or step while a freed man is on the books would surface here.
	for tick in 2:
		clock.advance(TICK_HOURS)
		population.think_for_everyone(TICK_HOURS)

	_require(plot.claim(zoogs), claim,
		"two ticks after Hobb was freed, Zoogs still could not claim the plot")
	_require(plot.claimed_by == zoogs, claim,
		"after Zoogs' claim the plot reads held by %s, not Zoogs" % [
			(plot.claimed_by.person_name if plot.claimed_by != null else "nobody")])

	world.queue_free()


# The two counters town.gd keeps are two different worlds — no work versus no
# room — and this is the claim that they cannot bleed into each other. A gate
# check that succeeds must move neither; a town with zero stations moves only
# the first.
func _check_no_stations_and_every_station_taken_are_different_counters() -> void:
	var claim := "18 — no stations and every-station-taken are different counters"
	var world := _add_a_disabled_game_scene()
	var town := world.get_node_or_null("Town") as Town
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var fields := world.get_node_or_null("Town/Fields") as Place
	var work := world.get_node_or_null("Population/Zoogs/Brain/WorkTheField") as WorkTheField
	if town == null or zoogs == null or plot == null or fields == null or work == null:
		_require(false, claim, "the scene came up without a Town, a Zoogs, the Plot, the Fields and Zoogs' WorkTheField")
		return

	# Pinned in the furrow — see _stand_at. Standing him ON the plot's place is
	# what makes the first check below say what it claims to say: away from it he
	# would read available because he cannot SEE the plot, which is a true fact
	# about knowledge and not the fact this claim is about.
	_stand_at(zoogs, fields)

	var no_candidates_before: float = town.no_candidates_existed_pressure
	var every_taken_before: float = town.every_candidate_was_taken_pressure
	_require(work.is_available_to(zoogs), claim,
		"a free plot at hour 0, with Zoogs awake and standing at the fields, did not read available")
	_require(town.no_candidates_existed_pressure == no_candidates_before
			and town.every_candidate_was_taken_pressure == every_taken_before, claim,
		"a plain successful gate check moved a pressure counter — no candidates %.1f to %.1f, every taken %.1f to %.1f" % [
			no_candidates_before, town.no_candidates_existed_pressure,
			every_taken_before, town.every_candidate_was_taken_pressure])

	# Zero stations now — "there was no field", not "every field was taken".
	plot.free()

	var no_candidates_before_empty: float = town.no_candidates_existed_pressure
	var every_taken_before_empty: float = town.every_candidate_was_taken_pressure
	_require(not work.is_available_to(zoogs), claim,
		"with zero stations in town, work still read available")
	_require(town.no_candidates_existed_pressure == no_candidates_before_empty + 1.0, claim,
		"a town with no stations at all should move no_candidates_existed_pressure by exactly 1.0, moved by %.1f instead" % [
			town.no_candidates_existed_pressure - no_candidates_before_empty])
	_require(town.every_candidate_was_taken_pressure == every_taken_before_empty, claim,
		"a town with no stations at all moved every_candidate_was_taken_pressure — that counter is for a full town, not an empty one")

	world.queue_free()


# --- Assertions 19 and 20: the walk itself ----------------------------------------

# Rung 4's step, isolated from the decision layer entirely — walk_toward is
# called directly, tick by tick, rather than through think_for_everyone. This
# claim is about the STEP, not about whether anybody chooses to walk.
#
# THE POINT OF CLAIM 19 is the PER-TICK displacement, not merely that he
# eventually arrives. A step that dawdled for 199 ticks and teleported on the
# 200th would still get there in the end — arrival alone can't catch that.
# Asserting (gap_before - gap_after) against his travel speed on every tick
# before arrival is what would fail if the overshoot clamp only fired on the
# last tick instead of closing the gap uniformly the whole way (Decision 10).
#
# CLAIM 20 is the departure half of the same rule, checked on the same ticks:
# the first step of a journey writes current_place = null, and it stays null
# until the tick he arrives. Neither his origin (the Inn) nor his destination
# (the Fields) is a correct answer while he's between them — see
# go_to_step.gd's header on why that's what stops find_people_at from standing
# a man on the road together with everybody else who's also on a road.
func _check_a_man_walks_the_gap_shut() -> void:
	var step_claim := "19 — a walking man closes the gap by exactly his travel speed each tick, and arrives"
	var transit_claim := "20 — a man in transit is at no place at all"
	var world := _add_a_disabled_game_scene()
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var inn := world.get_node_or_null("Town/Inn") as Place
	var walk := world.get_node_or_null("Population/Zoogs/Brain/WorkTheField/Work/GoTo") as GoToStep
	if zoogs == null or fields == null or inn == null or walk == null:
		_require(false, step_claim, "the scene came up without a Zoogs, Fields, an Inn and Zoogs' GoToStep")
		return

	_stand_at(zoogs, inn)
	var expected_step := zoogs.get_travel_speed() * TICK_HOURS

	var arrived := false
	for tick in 200:
		var gap_before: float = zoogs.global_position.distance_to(fields.global_position)
		var arrived_this_tick: bool = walk.walk_toward(zoogs, fields, TICK_HOURS)
		var gap_after: float = zoogs.global_position.distance_to(fields.global_position)

		if arrived_this_tick:
			arrived = true
			break

		_require(absf((gap_before - gap_after) - expected_step) < 0.001, step_claim,
			"one tick closed the gap by %.5f where his travel speed is worth %.5f a tick, gap %.4f → %.4f" % [
				gap_before - gap_after, expected_step, gap_before, gap_after])
		_require(zoogs.get_current_place() == null, transit_claim,
			"mid-journey, %.4f units short of the Fields, current_place reads %s — that is neither his origin (the Inn) nor his destination (the Fields)" % [
				gap_after, _describe_place(zoogs.get_current_place())])

	_require(arrived, step_claim,
		"200 ticks of %.4f hours each did not close the %.4f-unit gap between the Inn and the Fields at %.2f units/hour" % [
			TICK_HOURS, inn.global_position.distance_to(fields.global_position), zoogs.get_travel_speed()])
	_require(zoogs.get_current_place() == fields, step_claim,
		"walk_toward returned true and current_place reads %s, not the Fields" % _describe_place(zoogs.get_current_place()))
	_require(zoogs.global_position.distance_to(fields.global_position) < 0.0001, step_claim,
		"walk_toward returned true and he is still %.6f units from the Fields — arrived must mean ON the spot, not near it" % [
			zoogs.global_position.distance_to(fields.global_position)])

	world.queue_free()


# --- Assertion 21: freeness is invisible from afar --------------------------------

# THIS IS THE CLAIM THAT GOES RED IF ANYBODY RESTORES THE OMNISCIENT GATE.
# Rung 3 let a plot's freeness be asked from anywhere in the world; rung 4
# restricted that to wherever a man is actually standing (Decision 15). Away
# from the plot he knows it EXISTS and nothing more, so it stays a candidate
# and the urge to work sends him walking; the instant he arrives he can see it,
# and if it's already somebody else's it drops off his ballot on that exact
# tick. Restore the old rule — let is_available_to see the plot's true state
# from the Inn — and Zoogs never sets off at all, because he'd already know the
# job was gone: this check's very first loop iteration would never run long
# enough to walk him anywhere, and the mid-journey gate assertion below would
# fail the moment the plot changed hands out of his sight.
func _check_a_plot_is_invisible_from_afar_until_he_arrives() -> void:
	var claim := "21 — a plot's freeness is invisible from afar, and work leaves his ballot on arrival"
	var world := _add_a_disabled_game_scene()
	var population := world.get_node_or_null("Population") as Population
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var hobb := world.get_node_or_null("Population/Hobb") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var inn := world.get_node_or_null("Town/Inn") as Place
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var work_action := world.get_node_or_null("Population/Zoogs/Brain/WorkTheField") as WorkTheField
	if population == null or clock == null or zoogs == null or hobb == null or fields == null or inn == null or plot == null or work_action == null:
		_require(false, claim, "the scene came up without a Population, a Clock, a Zoogs, a Hobb, Fields, an Inn, the Plot and Zoogs' WorkTheField")
		return

	# Midday — where work scores 103 and beats StayUp's 87.3, so a man actually
	# sets off rather than sitting at the Inn idling. See work_the_field.gd's
	# header for why that margin is there at all.
	clock.advance(12.0)
	_stand_at(hobb, fields)
	_stand_at(zoogs, inn)
	_require(plot.claim(hobb), claim, "Hobb, standing at the fields at midday, could not claim the plot")

	var arrived := false
	for tick in 60:
		if zoogs.get_current_place() == fields:
			arrived = true
			break

		# Gates are asked BEFORE the tick that moves him — same reason assertion
		# 3 reads gate_answers before think_for_everyone: the gate answers for
		# what he is about to do, not for what the tick just changed him into.
		_require(work_action.is_available_to(zoogs), claim,
			"away from the fields (%s) and unable to see the plot is taken, work still read unavailable to Zoogs" % _describe_place(zoogs.get_current_place()))

		var gap_before: float = zoogs.global_position.distance_to(fields.global_position)
		clock.advance(TICK_HOURS)
		population.think_for_everyone(TICK_HOURS)
		var gap_after: float = zoogs.global_position.distance_to(fields.global_position)

		if zoogs.get_current_place() != fields:
			_require(gap_after < gap_before, claim,
				"walking toward the fields and the gap to them did not shrink, %.4f → %.4f" % [gap_before, gap_after])

	_require(arrived, claim,
		"Zoogs never reached the Fields inside 60 ticks — the walk-then-work path never completed")
	if not arrived:
		world.queue_free()
		return

	# THE MOMENT OF ARRIVAL. He can now see what he couldn't from the Inn.
	_require(not work_action.is_available_to(zoogs), claim,
		"the instant Zoogs stands at the Fields where Hobb already holds the plot, work still read available")

	# One more decision pass so the ballot actually gets rebuilt with him
	# standing there, and the loser's score is read the same way claim 13 reads
	# it — NAN, meaning off the ballot, not merely outscored.
	clock.advance(TICK_HOURS)
	population.think_for_everyone(TICK_HOURS)
	var score: Variant = zoogs.brain.get_last_scores().get(work_action.name)
	var zoogs_score_is_off_the_ballot := false
	if score is float:
		var score_value: float = score
		zoogs_score_is_off_the_ballot = is_nan(score_value)
	_require(zoogs_score_is_off_the_ballot, claim,
		"Zoogs' WorkTheField score, standing at the Fields with the plot already Hobb's, reads %s — the loser must be OFF the ballot (NAN), not merely outscored" % str(score))

	_require(plot.claimed_by == hobb, claim,
		"after the race the plot reads held by %s, not Hobb — arriving and losing must not let the loser take it off him" % [
			(plot.claimed_by.person_name if plot.claimed_by != null else "nobody")])

	world.queue_free()


# --- Assertion 22: the same rule, seen from the other side ------------------------

# Claim 21 shows a man away from a taken plot still bidding for it. This is the
# mirror: a man standing right where he can see it's taken must NOT bid — so
# the gate isn't simply "always true unless you're at the exact station",
# it's specifically "true away from it, false once you can see for yourself".
# And having lost, he has nowhere better to be — nothing on his ballot moves
# him, so he stands exactly where he lost.
func _check_he_does_not_bid_for_a_plot_he_can_see_is_taken() -> void:
	var claim := "22 — a man standing at a plot he can see is taken does not bid for it"
	var world := _add_a_disabled_game_scene()
	var population := world.get_node_or_null("Population") as Population
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var hobb := world.get_node_or_null("Population/Hobb") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var work_action := world.get_node_or_null("Population/Zoogs/Brain/WorkTheField") as WorkTheField
	if population == null or clock == null or zoogs == null or hobb == null or fields == null or plot == null or work_action == null:
		_require(false, claim, "the scene came up without a Population, a Clock, a Zoogs, a Hobb, the Fields, the Plot and Zoogs' WorkTheField")
		return

	clock.advance(12.0)
	_stand_at(hobb, fields)
	_stand_at(zoogs, fields)
	_require(plot.claim(hobb), claim, "Hobb, standing at the fields at midday, could not claim the plot")

	_require(not work_action.is_available_to(zoogs), claim,
		"Zoogs, standing right at the Fields where the plot is visibly Hobb's, still read work as available — the same rule from the other side")

	var starting_position := zoogs.global_position
	for tick in 20:
		clock.advance(TICK_HOURS)
		population.think_for_everyone(TICK_HOURS)

	_require(zoogs.global_position.distance_to(starting_position) < 0.0001, claim,
		"with no work on his ballot, Zoogs moved %.4f units over 20 idle ticks — he should have nowhere better to go" % [
			zoogs.global_position.distance_to(starting_position)])
	_require(zoogs.get_current_place() == fields, claim,
		"after 20 idle ticks Zoogs reads at %s, not the Fields where he lost the race" % _describe_place(zoogs.get_current_place()))

	world.queue_free()


# --- Assertions 23 and 24: the nearer station, and geography that moves -----------

# Two identical stations, both discoverable from where he stands (rung 4's
# knowledge rule doesn't apply here — he's at neither one's place), so nothing
# but travel cost is left to order them. Town/Fields is authored FIRST under
# Town, so a get_best_candidate that quietly picks scene order instead of
# reading find_workstations' cost-sorted list would return the Plot here and
# claim 23 would fail — that's what gives the claim teeth. Claim 24 then drags
# the near station away in code, which is standing check #3 aimed at
# WorkTheField specifically: cost is read live, never cached, so moving a place
# changes which candidate wins without touching a single call site.
func _check_the_nearer_station_wins_and_moving_a_place_changes_it() -> void:
	var near_claim := "23 — the nearer of two identical stations is the candidate"
	var moved_claim := "24 — move a place and which station wins changes"
	var world := _add_a_disabled_game_scene()
	var town := world.get_node_or_null("Town") as Town
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var inn := world.get_node_or_null("Town/Inn") as Place
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var work_action := world.get_node_or_null("Population/Zoogs/Brain/WorkTheField") as WorkTheField
	if town == null or zoogs == null or fields == null or inn == null or plot == null or work_action == null:
		_require(false, near_claim, "the scene came up without a Town, a Zoogs, Fields, an Inn, the Plot and Zoogs' WorkTheField")
		return

	# A second, hand-built station — never authored into game.tscn for this.
	# Parented to its place BEFORE the place enters the tree, so
	# Workstation._ready sees a Place above it the moment it's ready, same as
	# any station built by the loader.
	var near_place := Place.new()
	near_place.name = "NearField"
	near_place.place_name = "the near field"
	var near_station := Workstation.new()
	near_station.name = "NearPlot"
	near_station.work_name = work_action.work_name
	near_place.add_child(near_station)
	town.add_child(near_place)
	near_place.global_position = Vector3(10.0, 0.0, 10.0)

	# He stands on the near field's spot but BELONGS to the Inn — at neither
	# station's place, so both are candidates on knowledge grounds alone and
	# only cost is left to separate them.
	zoogs.current_place = inn
	zoogs.global_position = Vector3(10.0, 0.0, 10.0)

	var near_first: Workstation = work_action.get_best_candidate(zoogs)
	var near_first_name := "nothing"
	if near_first != null:
		near_first_name = String(near_first.name)
	_require(near_first == near_station, near_claim,
		"standing on the near field, the best candidate reads \"%s\", not NearPlot — Town/Fields sits first in scene order, so scene order is deciding instead of distance" % near_first_name)

	# Geography is READ, never assumed: drag the near place far away and the
	# winner has to flip to the far one, with nothing else changed.
	near_place.global_position = Vector3(300.0, 0.0, 300.0)
	var far_first: Workstation = work_action.get_best_candidate(zoogs)
	var far_first_name := "nothing"
	if far_first != null:
		far_first_name = String(far_first.name)
	_require(far_first == plot, moved_claim,
		"after moving the near field out to (300, 0, 300), the best candidate still reads \"%s\", not the Plot — the ordering did not re-read the new geometry" % far_first_name)

	world.queue_free()


# --- Assertions 25 and 26: work makes something, and only work does -------------

# Rung 5's whole point: a day finally has an output. Driven through the STEP
# directly rather than through think_for_everyone, for the same reason claim 14
# does it — this is about what working PAYS, not about whether the decision layer
# would choose to work at this hour, and at midnight it would not.
#
# THE AMOUNT IS ASSERTED, NOT MERELY THE DIRECTION. "Grain went up" would pass
# with the rate read off the wrong unit — per tick instead of per world hour is a
# hundredfold error and it still goes up. So this reads the seam itself, works a
# known number of hours, and asserts both halves of what that must produce: the
# whole grain in his sack, and the fraction still lying in the furrow. Together
# they have to account for every last hundredth of rate × hours, which is what
# makes it impossible to satisfy by producing roughly the right amount.
#
# 2.5 hours DELIBERATELY, never a whole number of them. On an exact boundary the
# expected answer sits one float rounding away from paying out a grain that has
# not quite finished, and the claim would flicker for a reason that has nothing
# to do with the code under it.
func _check_working_a_plot_yields_grain() -> void:
	var claim := "25 — working a plot yields grain at exactly the rate the seam reports"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var fields := world.get_node_or_null("Town/Fields") as Place
	var work := world.get_node_or_null("Population/Zoogs/Brain/WorkTheField") as WorkTheField
	if clock == null or zoogs == null or plot == null or fields == null or work == null:
		_require(false, claim, "the scene came up without a Clock, a Zoogs, the Plot, the Fields and Zoogs' WorkTheField")
		return
	var step := work.step as WorkStep
	var inventory := zoogs.get_inventory()
	if step == null or inventory == null:
		_require(false, claim, "WorkTheField has no WorkStep under it, or Zoogs has no Inventory under him")
		return

	# Standing him in the furrow is required, and it is this rung's second trap:
	# both farmers are authored at the Inn, so "work N ticks and assert grain"
	# quietly becomes "walk N ticks and assert nothing". See _stand_at.
	_stand_at(zoogs, fields)
	_require(inventory.get_count(&"grain") == 0, claim,
		"Zoogs starts the day holding %d grain — nothing has authored him any" % inventory.get_count(&"grain"))
	_require(is_zero_approx(plot.output_part_made), claim,
		"the plot starts with %.4f of a grain already part-made" % plot.output_part_made)

	var rate := step.get_yield_per_hour(zoogs)
	var worked_ticks := 250
	for tick in worked_ticks:
		clock.advance(TICK_HOURS)
		step.advance(zoogs, TICK_HOURS)

	var hours_worked := worked_ticks * TICK_HOURS
	var owed := rate * hours_worked
	var expected_whole := int(floorf(owed))
	_require(inventory.get_count(&"grain") == expected_whole, claim,
		"%.2f hours at %.2f grain an hour should put %d whole grain in his sack and he is holding %d" % [
			hours_worked, rate, expected_whole, inventory.get_count(&"grain")])
	# Sack plus furrow accounts for every hundredth. This is the half that makes
	# the claim exact rather than approximate: a rate applied per tick instead of
	# per hour, or a fraction dropped on the floor each tick, both land here.
	var accounted := float(inventory.get_count(&"grain")) + plot.output_part_made
	_require(absf(accounted - owed) < 0.0001, claim,
		"%.2f hours at %.2f an hour owes %.4f grain, and sack (%d) plus furrow (%.4f) accounts for %.4f" % [
			hours_worked, rate, owed, inventory.get_count(&"grain"), plot.output_part_made, accounted])

	world.queue_free()


# THE CLAIM MOST LIKELY TO CATCH A REAL MISTAKE, and it exists because
# WorkStep.advance() grew a second branch at rung 4. It no longer only works: it
# asks where the man is standing, and if he is not at the plot's place it walks
# him there and returns. Put the yield at the TOP of advance() — the obvious
# place, and where anybody reading only rung 3's version of the file would put
# it — and a man produces grain the whole way across town. That reads as a
# balance problem, not as a misplaced line.
#
# Both halves are checked on every tick of the road, because a yield paid to the
# walker could land in either: in his sack, or as part-made work on a plot he has
# not reached yet.
func _check_a_walking_man_produces_nothing() -> void:
	var claim := "26 — a man walking to a plot produces nothing until he gets there"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var fields := world.get_node_or_null("Town/Fields") as Place
	var inn := world.get_node_or_null("Town/Inn") as Place
	var work := world.get_node_or_null("Population/Zoogs/Brain/WorkTheField") as WorkTheField
	if clock == null or zoogs == null or plot == null or fields == null or inn == null or work == null:
		_require(false, claim, "the scene came up without a Clock, a Zoogs, the Plot, the Fields, an Inn and Zoogs' WorkTheField")
		return
	var step := work.step as WorkStep
	var inventory := zoogs.get_inventory()
	if step == null or inventory == null:
		_require(false, claim, "WorkTheField has no WorkStep under it, or Zoogs has no Inventory under him")
		return

	_stand_at(zoogs, inn)

	var arrived := false
	for tick in 200:
		if zoogs.get_current_place() == fields:
			arrived = true
			break
		# Asserted BEFORE the tick, while he is provably still on the road —
		# checking afterwards would be asking about a tick that may have landed
		# him, and an arriving tick is allowed to work.
		_require(inventory.get_count(&"grain") == 0, claim,
			"%.4f units short of the Fields and already carrying %d grain — the yield is being paid for walking" % [
				zoogs.global_position.distance_to(fields.global_position), inventory.get_count(&"grain")])
		_require(is_zero_approx(plot.output_part_made), claim,
			"%.4f units short of the Fields and the plot already reads %.4f of a grain part-made — work is being banked from the road" % [
				zoogs.global_position.distance_to(fields.global_position), plot.output_part_made])
		clock.advance(TICK_HOURS)
		step.advance(zoogs, TICK_HOURS)

	_require(arrived, claim,
		"Zoogs never reached the Fields in 200 ticks — the walk half of the step never completed, so this claim proved nothing")

	# The tick he ARRIVES walks him and returns; it does not also work. So the
	# whole journey, arrival included, has to have paid exactly nothing.
	_require(inventory.get_count(&"grain") == 0, claim,
		"the walk from the Inn to the Fields paid him %d grain" % inventory.get_count(&"grain"))
	_require(is_zero_approx(plot.output_part_made), claim,
		"the walk from the Inn to the Fields banked %.4f of a grain on the plot" % plot.output_part_made)

	# And now that he IS there, one tick of the same step must pay. Without this
	# the claim above could be satisfied by a step that never produces anything
	# at all, anywhere — which is the vacuous form of it.
	#
	# EITHER HALF COUNTS, and that is not laziness. A tick's work lands in the
	# furrow while it is a fraction and in his sack once it is whole, so which of
	# the two moves depends entirely on the authored rate. Naming only the furrow
	# would make this go red for a rate of one grain per tick — which is a real
	# defect, but it is claim 25's to catch, and a claim that fails for somebody
	# else's reason is a claim you stop believing.
	clock.advance(TICK_HOURS)
	step.advance(zoogs, TICK_HOURS)
	_require(inventory.get_count(&"grain") > 0 or plot.output_part_made > 0.0, claim,
		"standing in the furrow with the plot claimed, one worked tick left him holding %d grain and the plot holding %.4f — the step produces nothing ANYWHERE, so the walking half of this claim proves nothing" % [
			inventory.get_count(&"grain"), plot.output_part_made])

	world.queue_free()


# --- Assertions 27 to 30: the three doors ----------------------------------------

# DESTRUCTION refused. A take that cannot be satisfied must move NOTHING: no
# partial take, and no count driven below zero. A negative count would be a debt,
# and every sum in the game would silently start including one.
func _check_taking_more_than_he_has_moves_nothing() -> void:
	var claim := "27 — taking more than he has returns false and changes nothing"
	var world := _add_a_disabled_game_scene()
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	if zoogs == null:
		_require(false, claim, "the scene came up without a Zoogs")
		return
	var inventory := zoogs.get_inventory()
	if inventory == null:
		_require(false, claim, "Zoogs has no Inventory under him")
		return

	inventory.add(&"grain", 3)
	_require(inventory.get_count(&"grain") == 3, claim,
		"added 3 grain to an empty sack and it reads %d" % inventory.get_count(&"grain"))

	_require(not inventory.take(&"grain", 5), claim,
		"taking 5 grain from a sack holding 3 came back true")
	_require(inventory.get_count(&"grain") == 3, claim,
		"a refused take left him holding %d grain instead of the 3 he started with — it moved part of it" % [
			inventory.get_count(&"grain")])

	# The boundary in both directions: exactly what he has must go, and one more
	# than nothing must not.
	_require(inventory.take(&"grain", 3), claim,
		"taking exactly the 3 grain he holds came back false")
	_require(inventory.get_count(&"grain") == 0, claim,
		"after taking all of it he reads %d grain" % inventory.get_count(&"grain"))
	_require(not inventory.take(&"grain", 1), claim,
		"taking 1 grain from an empty sack came back true")
	_require(inventory.get_count(&"grain") == 0, claim,
		"taking from an empty sack drove the count to %d — a count may never go negative" % [
			inventory.get_count(&"grain")])
	# A thing he has never held is not a thing he can lose.
	_require(not inventory.take(&"scythe", 1), claim,
		"taking a scythe he has never owned came back true")

	world.queue_free()


# MOVEMENT, from both ends. Claim 28 is that the waist conserves — sum before
# equals sum after — and claim 29 is that a transfer which cannot complete moves
# NEITHER half, asserted on both inventories rather than on the return value,
# because a half-completed transfer also returns false.
#
# Run across all three mounts on purpose: man to place to station. If any one of
# them came up without an Inventory this is where it says so, and a transfer
# between a person and a barn is exactly what rung 6b's discharge will be.
func _check_handing_over_conserves_and_is_all_or_nothing() -> void:
	var conserves := "28 — handing goods over conserves the total across both inventories"
	var atomic := "29 — a transfer that cannot complete moves neither half"
	var world := _add_a_disabled_game_scene()
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var inn := world.get_node_or_null("Town/Inn") as Place
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	if zoogs == null or inn == null or plot == null:
		_require(false, conserves, "the scene came up without a Zoogs, an Inn and the Plot")
		return
	var pockets := zoogs.get_inventory()
	var barn := inn.get_inventory()
	var stone := plot.get_inventory()
	if pockets == null or barn == null or stone == null:
		_require(false, conserves, "rung 5 mounts an Inventory under Person, Place AND Workstation — one of the three has none")
		return

	pockets.add(&"grain", 10)
	var before := _sum_grain([pockets, barn, stone])

	_require(pockets.hand_over(&"grain", 4, barn), conserves,
		"handing 4 of his 10 grain to the Inn came back false")
	_require(pockets.get_count(&"grain") == 6 and barn.get_count(&"grain") == 4, conserves,
		"after handing 4 over, he holds %d and the Inn holds %d" % [
			pockets.get_count(&"grain"), barn.get_count(&"grain")])
	_require(_sum_grain([pockets, barn, stone]) == before, conserves,
		"a transfer changed the town's grain from %d to %d — movement must change no total" % [
			before, _sum_grain([pockets, barn, stone])])

	# Place to station, so the third mount is exercised as a source and not only
	# as a bystander.
	_require(barn.hand_over(&"grain", 4, stone), conserves,
		"handing the Inn's 4 grain onto the plot came back false")
	_require(barn.get_count(&"grain") == 0 and stone.get_count(&"grain") == 4, conserves,
		"after the second transfer the Inn holds %d and the plot holds %d" % [
			barn.get_count(&"grain"), stone.get_count(&"grain")])
	_require(_sum_grain([pockets, barn, stone]) == before, conserves,
		"two transfers changed the town's grain from %d to %d" % [
			before, _sum_grain([pockets, barn, stone])])

	# ATOMICITY. He holds 6; ask for 9.
	var his_before := pockets.get_count(&"grain")
	var barns_before := barn.get_count(&"grain")
	_require(not pockets.hand_over(&"grain", 9, barn), atomic,
		"handing over 9 grain out of the 6 he holds came back true")
	_require(pockets.get_count(&"grain") == his_before, atomic,
		"a refused transfer left the giver holding %d where he held %d — the take half happened" % [
			pockets.get_count(&"grain"), his_before])
	_require(barn.get_count(&"grain") == barns_before, atomic,
		"a refused transfer left the receiver holding %d where it held %d — the add half happened" % [
			barn.get_count(&"grain"), barns_before])
	_require(_sum_grain([pockets, barn, stone]) == before, atomic,
		"a refused transfer changed the town's grain from %d to %d" % [
			before, _sum_grain([pockets, barn, stone])])

	# Nowhere is not a destination. Goods handed to null must not simply vanish
	# through the movement door, which is the leak the three-way split exists to
	# make impossible.
	_require(not pockets.hand_over(&"grain", 1, null), atomic,
		"handing a grain to nothing at all came back true")
	_require(pockets.get_count(&"grain") == his_before, atomic,
		"handing a grain to nothing left him holding %d where he held %d — it was destroyed in transit" % [
			pockets.get_count(&"grain"), his_before])

	world.queue_free()


# THE CLAIM THAT KEEPS THE THREE DOORS HONEST, and the one rungs 6b, 7 and 9a
# will lean on: a world total may move where add or take is called, and NOWHERE
# ELSE. Stated as a positive as well as a negative — a conservation check that
# only ever asserts "the number did not move" is satisfied by a system in which
# nothing works at all.
func _check_only_creation_and_destruction_move_a_world_total() -> void:
	var claim := "30 — only add and take move a world total; hand_over never does"
	var world := _add_a_disabled_game_scene()
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var inn := world.get_node_or_null("Town/Inn") as Place
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	if zoogs == null or inn == null or plot == null:
		_require(false, claim, "the scene came up without a Zoogs, an Inn and the Plot")
		return
	var pockets := zoogs.get_inventory()
	var barn := inn.get_inventory()
	var stone := plot.get_inventory()
	if pockets == null or barn == null or stone == null:
		_require(false, claim, "one of Person, Place and Workstation came up without an Inventory")
		return
	var everywhere: Array[Inventory] = [pockets, barn, stone]

	pockets.add(&"grain", 7)
	var settled := _sum_grain(everywhere)
	_require(settled == 7, claim,
		"7 grain were created and the town holds %d" % settled)

	pockets.hand_over(&"grain", 3, barn)
	barn.hand_over(&"grain", 2, stone)
	stone.hand_over(&"grain", 1, pockets)
	_require(_sum_grain(everywhere) == settled, claim,
		"three transfers moved the town's grain from %d to %d — MOVEMENT changed a total" % [
			settled, _sum_grain(everywhere)])

	pockets.add(&"grain", 4)
	_require(_sum_grain(everywhere) == settled + 4, claim,
		"creating 4 grain moved the town's total from %d to %d — CREATION did not change it by 4" % [
			settled, _sum_grain(everywhere)])

	_require(barn.take(&"grain", 1), claim, "taking 1 grain from the Inn's store came back false")
	_require(_sum_grain(everywhere) == settled + 3, claim,
		"destroying 1 grain left the town holding %d where %d was expected" % [
			_sum_grain(everywhere), settled + 3])

	world.queue_free()


# Every grain in a set of inventories. Its own function because the interesting
# assertions above are all about a number that must or must not move, and a sum
# written out four times is four chances to sum a different set.
func _sum_grain(inventories: Array[Inventory]) -> int:
	var total := 0
	for inventory in inventories:
		total += inventory.get_count(&"grain")
	return total


# --- Assertion 4: the node_paths trap -------------------------------------------

# Two halves, because the trap has two halves and only one of them is visible
# at runtime. The text half lives in SceneWiring — it is about .tscn files in
# general rather than about any one rung, and every rung from here adds scenes
# for it to read.
func _check_every_scene_is_wired() -> void:
	var claim := "4 — every node reference in a .tscn is wired the way the loader needs"

	var scene_paths := SceneWiring.find_scene_files(PROJECT_ROOT_DIR)
	_require(not scene_paths.is_empty(), claim,
		"found no .tscn files at all under %s — the scan read nothing" % PROJECT_ROOT_DIR)

	var violations := SceneWiring.find_node_path_violations(scene_paths)
	_require(violations.is_empty(), claim, "\n        ".join(violations))

	var unresolved := _find_unresolved_node_path_arrays()
	_require(unresolved.is_empty(), claim, "\n        ".join(unresolved))


# The runtime half. Text cannot see this one: an Array[NodePath] export is
# resolved by hand with get_node_or_null(), so its paths are only ever checked
# by whoever wrote the loop — and a path that points nowhere comes back null
# and usually gets skipped in silence.
#
# Deliberately NOT attempted for bare NodePath exports. Those load as objects,
# so a broken wire and a legitimately empty optional are the same `null` at
# runtime and always will be — which is why that half is a text scan, and why
# Workstation.owner being null on purpose (unowned land is the king's, which is
# the same answer as nobody's) will never false-positive here.
func _find_unresolved_node_path_arrays() -> Array[String]:
	var unresolved: Array[String] = []
	var every_node: Array[Node] = [_game]
	every_node.append_array(_game.find_children("*", "", true, false))
	for node in every_node:
		var script: Variant = node.get_script()
		if script == null:
			continue
		for property in script.get_script_property_list():
			if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
				continue
			if not (property.usage & PROPERTY_USAGE_EDITOR):
				continue
			var value: Variant = node.get(property.name)
			if not (value is Array):
				continue
			for entry: Variant in value:
				if not (entry is NodePath):
					continue
				var path: NodePath = entry
				if node.get_node_or_null(path) == null:
					unresolved.append("%s.%s points at \"%s\", which resolves to nothing" % [
						node.name, property.name, path])
	return unresolved


# --- Building a cast ------------------------------------------------------------

# Stand a man on a place outright — the fact he carries AND the body carrying
# it — so a check that is about something else does not quietly depend on where
# he happened to be authored.
#
# WRITING current_place BY HAND IS LEGAL HERE, and it must stay that way.
# GoToStep owning both edges of that field is a rule about the GAME: it is what
# stops a second walking path appearing. This file is authoring a situation, not
# moving a man, and routing these through the walking step would mean every
# claim below had to wait out a commute before it could assert anything.
#
# It exists because authored placement has now moved under a claim on TWO
# successive rungs — rung 3 moved claims 6 and 8 by authoring Hobb in, rung 4
# moved 7, 8, 13, 14, 15 and 17 by sending both farmers to the Inn. Pinning is
# the durable fix: a check that says what world it wants cannot be broken by a
# later rung rearranging the scene, and the checks that SHOULD track the authored
# population (7 and 8) are then the only ones that do.
func _stand_at(person: Person, place: Place) -> void:
	person.current_place = place
	person.global_position = place.global_position


# One more real person under a real Population — person.tscn instanced, never a
# mock. He picks his Town up off his parent in his own _ready, which is also the
# only proof this file has that a man born mid-run is wired at all.
func _add_a_person(population: Population, person_name: String) -> Person:
	var person_scene: PackedScene = load(PERSON_SCENE_PATH) as PackedScene
	if person_scene == null:
		return null
	var person := person_scene.instantiate() as Person
	if person == null:
		return null
	person.name = person_name
	person.person_name = person_name
	population.add_child(person)
	return person


# --- Saying so ------------------------------------------------------------------

# Compares two casts as SETS, by name, so the assertion says nothing about the
# order people come back in. Order is Population's child order today and there is
# no reason for any caller to depend on it — an assertion that quietly did would
# go red the day somebody reorders the scene tree, for no defect.
func _require_exactly(found: Array[Person], expected: Array[Person], claim: String, where: String) -> void:
	var found_names := _list_names(found)
	var expected_names := _list_names(expected)
	found_names.sort()
	expected_names.sort()
	_require(found_names == expected_names, claim,
		"%s — expected [%s] and found [%s]" % [where, ", ".join(expected_names), ", ".join(found_names)])


func _list_names(people: Array[Person]) -> PackedStringArray:
	var names := PackedStringArray()
	for person in people:
		names.append(person.person_name)
	return names


# An hour as a human reads it. Hours elapsed and hours of the day both land
# here; anything past the first day wraps, which is what you want either way.
func _as_clock_text(hour: float) -> String:
	var minutes := int(round(fmod(hour, HOURS_IN_A_DAY) * 60.0))
	return "%02d:%02d" % [minutes / 60, minutes % 60]


# Nowhere is a real answer, so it reads as a word rather than as "<null>".
func _describe_place(place: Place) -> String:
	if place == null:
		return "nowhere"
	return place.place_name


# Records one claim's outcome. Claims are keyed by their headline text, so the
# same headline asserted two thousand times reports once — see _claims.
func _require(is_true: bool, claim: String, detail: String) -> void:
	_checks += 1
	if not _claims.has(claim):
		_claims.append(claim)
	if is_true or _first_failure.has(claim):
		return
	_first_failure[claim] = detail


func _report() -> void:
	print("")
	print("probe — %d checks over %.0f simulated hours at %.2f-hour ticks" % [
		_checks, PUMPED_HOURS, TICK_HOURS])
	if _fell_asleep_at_hour >= 0.0:
		print("        from a cold start: turned in at hour %.2f (%s), up at %.2f (%s)" % [
			_fell_asleep_at_hour, _as_clock_text(_fell_asleep_at_hour),
			_woke_at_hour, _as_clock_text(_woke_at_hour)])
	if _kept_bedtime >= 0.0:
		print("        once settled:      turns in %s, sleeps %.2f h, up %s" % [
			_as_clock_text(_kept_bedtime), _kept_night,
			_as_clock_text(_kept_bedtime + _kept_night)])
	if _kept_strong_morning >= 0.0:
		print("        a strong man (1.15) is up at %s instead" % _as_clock_text(_kept_strong_morning))
	print("")
	for claim in _claims:
		if _first_failure.has(claim):
			var detail: String = _first_failure[claim]
			print("FAIL    %s" % claim)
			print("        %s" % detail)
		else:
			print("PASS    %s" % claim)
	print("")
	if _first_failure.is_empty():
		print("all %d claims held." % _claims.size())
	else:
		print("%d of %d claims failed." % [_first_failure.size(), _claims.size()])
	print("")

