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
	_check_a_held_plot_reads_taken_from_anywhere_in_town()
	_check_the_dither_is_gone_across_arrival_departure_and_after()
	_check_the_day_boundary_reopens_a_held_plot_from_the_same_spot()
	_check_the_dawn_race_survives_the_register()
	_check_the_bedless_man_does_not_pace_the_doorway()
	_check_the_nearer_station_wins_and_moving_a_place_changes_it()
	_check_working_a_plot_yields_grain()
	_check_a_walking_man_produces_nothing()
	_check_taking_more_than_he_has_moves_nothing()
	_check_handing_over_conserves_and_is_all_or_nothing()
	_check_only_creation_and_destruction_move_a_world_total()
	_check_every_scene_is_wired()
	_check_hunger_rises_for_an_idle_man()
	_check_eating_drops_hunger_and_a_loaf()
	_check_no_bread_means_off_the_ballot()
	_check_hunger_never_goes_negative()
	_check_adenosine_is_written_only_in_brain()
	_check_eat_is_on_every_person_by_composition()
	_check_baking_turns_grain_into_bread()
	_check_bread_wins_over_baking_and_grain_alone_bakes()
	_check_neither_grain_nor_bread_means_neither_and_hunger_still_rises()
	_check_expired_obligation_leaves_the_candidate_set()
	_check_owned_plot_refuses_the_unemployed_and_counts_it()
	_check_work_score_is_unchanged_by_his_sack()
	_check_short_larder_bakes_full_larder_does_not()
	_check_crop_splits_between_owner_and_worker_and_conserves()
	_check_unowned_land_worker_keeps_all_of_it()
	_check_a_man_holds_three_grain_and_bakes()
	_check_twenty_one_sleepers_leave_one_standing()
	_check_a_sleeper_holds_his_bed_across_midnight()
	_check_an_abandoned_bed_lapses_at_the_boundary()
	_check_a_lonely_man_goes_where_company_is_to_be_found()
	_check_social_rises_for_an_idle_man()
	_check_the_day_keeps_its_shape()
	_check_a_steered_body_with_no_verb_chosen_still_tires_hungers_and_grows_lonely()
	_check_the_verb_list_on_screen_is_exactly_the_open_ballot()
	_check_a_gate_that_says_no_never_reaches_the_players_ballot()
	_check_choosing_a_verb_runs_its_step_and_choosing_nothing_runs_nothing()
	_check_a_verb_dropped_from_under_him_is_dropped_not_held()
	_check_the_fork_changed_one_body_not_the_engine()
	_check_the_players_place_is_a_band_and_does_not_flicker_on_a_boundary()
	_check_the_player_covers_the_same_ground_per_world_hour_at_any_day_length()
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
	# 5 = the four authored people (Zoogs, Hobb, Marle, the Player) plus
	# Doomed. This number reads the authored population, so adding a person
	# to game.tscn moves it — rung 3 took it from 2 to 3 when Hobb was
	# authored in, rung 6b took it from 3 to 4 when Marle, the farm owner,
	# was, and Gate 1 took it from 4 to 5 when the Player was.
	_require(population.get_people().size() == 5, claim,
		"expected 5 people under Population and found %d — the marker node was counted as one" % [
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
	_require(population.get_people().size() == 4, claim,
		"expected 4 people left and found %d" % population.get_people().size())

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
	var marle := world.get_node_or_null("Population/Marle") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var inn := world.get_node_or_null("Town/Inn") as Place
	if town == null or population == null or zoogs == null or hobb == null or marle == null or fields == null or inn == null:
		_require(false, claim, "the scene came up without a Town, a Population, a Zoogs, a Hobb, a Marle, Fields and an Inn")
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
	# spare the probe puts there. Marle, the farm owner, joined the Inn at
	# rung 6b.
	_require_exactly(town.find_people_at(fields), [mara], claim, "at the fields")
	_require_exactly(town.find_people_at(inn), [zoogs, hobb, marle, bram], claim, "at the Inn")

	# Nothing is invalidated, nothing is notified, nothing is re-posted. The next
	# call simply asks again, which is the whole argument for a query.
	mara.current_place = inn
	_require_exactly(town.find_people_at(fields), [], claim, "at the fields once Mara left")
	_require_exactly(town.find_people_at(inn), [zoogs, hobb, marle, bram, mara], claim, "at the Inn once Mara arrived")

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
	_require_exactly(town.find_people_at(inn), [zoogs, hobb, marle, mara], claim, "at the Inn once Bram died")

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

# Rung 3's whole point, made mechanical: one Workstation, two men who both
# know WorkForHire (as of rung 6b — see below), and a schedule that is
# supposed to be the thing that decides between them rather than which node
# happens to sit first under Population.

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
	var work_action := world.get_node_or_null("Population/Zoogs/Brain/WorkForHire") as WorkForHire
	if population == null or clock == null or zoogs == null or hobb == null or plot == null or fields == null or work_action == null:
		_require(false, claim, "the scene came up without a Population, a Clock, a Zoogs, a Hobb, the Plot, the Fields and Zoogs' WorkForHire")
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
	# ELEVEN hours, not ten, as of rung 6c — and the extra hour is the commute,
	# twice. Both men now walk to the Inn to sleep (arriving ~22:08) instead of
	# dropping where they stand, and Zoogs — recovery 5.0/hour against the 58
	# authored above — does not surface until ~07:56, then has to walk BACK to
	# the fields before he can SEE the plot is taken and fall off the ballot.
	# A ten-hour pump ended at 08:00, while he was still on the road, and the
	# NAN assertion below read a man who had not yet arrived rather than a
	# broken knowledge rule.
	var tick_count := int(round(11.0 / TICK_HOURS))
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
		"Zoogs is still asleep at the end of an eleven-hour pump that started at 22:00")

	# is_nan, not a low score: the loser was never on the ballot at all, and the
	# graph draws that as a hole rather than a losing line. A plain low number
	# here would mean he was OUTscored, which is a different (and false) claim.
	var score: Variant = zoogs.brain.get_last_scores().get(work_action.name)
	var zoogs_score_is_off_the_ballot := false
	if score is float:
		var score_value: float = score
		zoogs_score_is_off_the_ballot = is_nan(score_value)
	_require(zoogs_score_is_off_the_ballot, claim,
		"Zoogs' last WorkForHire score reads %s — the loser must be OFF the ballot (NAN), not merely outscored" % str(score))

	var hobb_action: Action = hobb.brain.current_action
	_require(hobb_action != null and String(hobb_action.name) == String(work_action.name), claim,
		"Hobb's current action reads \"%s\", not WorkForHire" % [
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
	var hobb_work := world.get_node_or_null("Population/Hobb/Brain/WorkForHire") as WorkForHire
	if clock == null or zoogs == null or hobb == null or plot == null or fields == null or hobb_work == null:
		_require(false, claim, "the scene came up without a Clock, a Zoogs, a Hobb, the Plot, the Fields and Hobb's WorkForHire")
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
	var work := world.get_node_or_null("Population/Zoogs/Brain/WorkForHire") as WorkForHire
	if town == null or zoogs == null or plot == null or fields == null or work == null:
		_require(false, claim, "the scene came up without a Town, a Zoogs, the Plot, the Fields and Zoogs' WorkForHire")
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

	# Zero stations now — "there was no field", not "every field was
	# taken". Gate 1 authored a second `field work` station (the unowned
	# CommonPlot at Town/CommonField), so freeing only Town/Fields/Plot no
	# longer empties the town — this frees every station the town currently
	# reports for this work, which keeps the claim's meaning exactly and
	# survives the next plot somebody authors.
	for station in town.find_workstations(zoogs, work.work_name):
		station.free()

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
	var walk := world.get_node_or_null("Population/Zoogs/Brain/WorkForHire/Work/GoTo") as GoToStep
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


# --- Assertion 21: a claim is public, read the same from anywhere in town ---------

# THIS IS THE CLAIM THAT GOES RED IF ANYBODY RESTORES THE POSITIONAL GATE.
# Decision 30 retired the rule that freeness was knowable only where you stand
# (Decision 15's Ruling 1, which this narrows) — a held plot is now off a
# man's ballot from the Inn exactly as it is from the furrow, because
# claimed_by is a public record, not a perceptual one. Restore the old
# position check and Zoogs would set off from the Inn anyway — this claim's
# very first gate read would flip true, and the "gap does not shrink" reads
# below would start failing the moment he actually started walking.
func _check_a_held_plot_reads_taken_from_anywhere_in_town() -> void:
	var claim := "21 — a man anywhere in town reads a held plot as taken and never sets off toward it"
	var world := _add_a_disabled_game_scene()
	var population := world.get_node_or_null("Population") as Population
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var hobb := world.get_node_or_null("Population/Hobb") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var inn := world.get_node_or_null("Town/Inn") as Place
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var work_action := world.get_node_or_null("Population/Zoogs/Brain/WorkForHire") as WorkForHire
	if population == null or clock == null or zoogs == null or hobb == null or fields == null or inn == null or plot == null or work_action == null:
		_require(false, claim, "the scene came up without a Population, a Clock, a Zoogs, a Hobb, Fields, an Inn, the Plot and Zoogs' WorkForHire")
		return

	# Midday — where work scores 103 and beats StayUp's 87.3, so a man who
	# COULD set off would have every reason to. See work_the_field.gd's header
	# for why that margin is there at all.
	clock.advance(12.0)
	_stand_at(hobb, fields)
	_stand_at(zoogs, inn)
	_require(plot.claim(hobb), claim, "Hobb, standing at the fields at midday, could not claim the plot")

	var starting_gap: float = zoogs.global_position.distance_to(fields.global_position)
	for tick in 30:
		_require(not work_action.is_available_to(zoogs), claim,
			"from the Inn, with Hobb holding the only plot, work still read available to Zoogs — the register must be readable from anywhere in town")
		_require(zoogs.get_current_place() == inn, claim,
			"Zoogs' current_place reads %s, not the Inn — he must never even START a journey toward a plot the register already says is Hobb's" % _describe_place(zoogs.get_current_place()))

		var gap_before: float = zoogs.global_position.distance_to(fields.global_position)
		clock.advance(TICK_HOURS)
		population.think_for_everyone(TICK_HOURS)
		var gap_after: float = zoogs.global_position.distance_to(fields.global_position)

		_require(gap_after >= gap_before - 0.0001, claim,
			"his gap to the Fields shrank, %.4f → %.4f, on a tick where work was never a candidate — he must never set off toward a plot he cannot have" % [gap_before, gap_after])

	_require(is_equal_approx(zoogs.global_position.distance_to(fields.global_position), starting_gap), claim,
		"after 30 ticks his distance to the Fields moved from %.4f to %.4f — he should not have taken a single step toward a plot the register already says is Hobb's" % [
			starting_gap, zoogs.global_position.distance_to(fields.global_position)])

	world.queue_free()


# --- Assertion 22: the dither, asserted directly -----------------------------------

# CLAIM 22 MUST BREAK RED AGAINST THE PRE-DECISION-30 CODE, and the specific
# tick it must break on is named below. Claim 21 shows the general case — a
# man far from the plot never sets off at all. This claim reproduces the exact
# geometry Decision 30 was written to fix: a man ONE TICK'S WALK from a held
# plot, driven through the arrival, the departure, and the tick after, with
# GoToStep called directly (the same technique claims 19/20 use) so the
# position on each tick is exact rather than incidental.
#
# The old bug lived entirely in the DEPARTURE tick: go_to_step.gd's first tick
# of any journey writes current_place = null, and the retired position check
# read "not at the plot's place" as "still a candidate" — full strength,
# regardless of is_free_for. That is the read this claim pins down.
func _check_the_dither_is_gone_across_arrival_departure_and_after() -> void:
	var claim := "22 — the dither, asserted directly: gate stays false on the arrival tick, the departure tick, and the tick after"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var hobb := world.get_node_or_null("Population/Hobb") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var inn := world.get_node_or_null("Town/Inn") as Place
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var work_action := world.get_node_or_null("Population/Zoogs/Brain/WorkForHire") as WorkForHire
	var walk := world.get_node_or_null("Population/Zoogs/Brain/WorkForHire/Work/GoTo") as GoToStep
	if clock == null or zoogs == null or hobb == null or fields == null or inn == null or plot == null or work_action == null or walk == null:
		_require(false, claim, "the scene came up without a Clock, a Zoogs, a Hobb, Fields, an Inn, the Plot, Zoogs' WorkForHire and its GoToStep")
		return

	clock.advance(12.0)
	_stand_at(hobb, fields)
	_require(plot.claim(hobb), claim, "Hobb, standing at the fields at midday, could not claim the plot")

	# THE ARRIVAL TICK. Zoogs stands exactly where GoToStep would have left
	# him, and this half was never broken — the old code got the arrival tick
	# right, which is exactly why the bug hid inside the tick after it.
	_stand_at(zoogs, fields)
	_require(not work_action.is_available_to(zoogs), claim,
		"on the arrival tick, standing where Hobb holds the plot, work still read available to Zoogs")

	# THE DEPARTURE TICK. One tick's walk toward the Inn — the step that used
	# to write current_place = null and, with it, erase everything the arrival
	# tick had just proven. Driven directly rather than through the decision
	# layer so the distance is exactly one tick, never a tick-and-a-bit that
	# would let the old bug hide behind rounding.
	var departed := walk.walk_toward(zoogs, inn, TICK_HOURS)
	_require(not departed, claim,
		"one tick's walk toward the Inn was enough to arrive there outright — the Inn and Fields need to be more than one tick apart for this claim to mean anything")
	_require(zoogs.get_current_place() == null, claim,
		"one tick after leaving the Fields, current_place reads %s, not nowhere — this claim needs the departure tick it is named for" % _describe_place(zoogs.get_current_place()))
	_require(not work_action.is_available_to(zoogs), claim,
		"on the departure tick — current_place nowhere, one tick's walk from the plot — work read available to Zoogs; this is the exact tick the pre-Decision-30 bug resurrected it at full strength")

	# THE TICK AFTER. Nothing about his position changes again; only world time
	# does. The register does not need him to move to keep telling the same
	# truth, unlike the doorstep check it replaced.
	clock.advance(TICK_HOURS)
	_require(not work_action.is_available_to(zoogs), claim,
		"the tick after departure, still one tick's walk from the plot and having moved nowhere further, work read available to Zoogs")

	world.queue_free()


# --- Assertion 51: the day boundary re-opens the race, not a footstep -------------

# The mirror of claim 15 (is_free_for lapses at the boundary) one layer up,
# through the Action's own gate, and from a spot the man never leaves. If this
# claim went red it would mean the gate disagrees with the station it asks —
# a bug in _is_a_candidate_for or its caller, never in Workstation.is_free_for,
# which claim 15 already covers directly.
func _check_the_day_boundary_reopens_a_held_plot_from_the_same_spot() -> void:
	var claim := "51 — at the day boundary the same plot reads free from the same spot, nobody having moved"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var hobb := world.get_node_or_null("Population/Hobb") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var inn := world.get_node_or_null("Town/Inn") as Place
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var work_action := world.get_node_or_null("Population/Zoogs/Brain/WorkForHire") as WorkForHire
	if clock == null or zoogs == null or hobb == null or fields == null or inn == null or plot == null or work_action == null:
		_require(false, claim, "the scene came up without a Clock, a Zoogs, a Hobb, Fields, an Inn, the Plot and Zoogs' WorkForHire")
		return

	# Zoogs stands at the Inn for the whole claim and never takes a step — the
	# ONLY thing that changes between the two reads below is the calendar.
	_stand_at(zoogs, inn)
	_stand_at(hobb, fields)
	clock.advance(10.0)
	_require(plot.claim(hobb), claim, "Hobb, standing at the fields, could not claim the plot at hour 10")
	_require(not work_action.is_available_to(zoogs), claim,
		"from the Inn, on the day Hobb holds the plot, work read available to Zoogs")

	# Cross midnight. Nobody renews — Hobb never advances a work step in this
	# claim — so lazy expiry is the only thing that can flip this, the same
	# mechanism claim 15 proves directly against is_free_for.
	clock.advance(15.0)
	_require(clock.day() == 1, claim,
		"advancing from hour 10 by 15 hours should cross midnight and landed on day %d instead" % clock.day())
	_require(zoogs.get_current_place() == inn, claim,
		"Zoogs' current_place reads %s, not the Inn — this claim requires him to have not moved at all" % _describe_place(zoogs.get_current_place()))
	_require(work_action.is_available_to(zoogs), claim,
		"the day turned over and yesterday's claim should have lapsed, but work still reads unavailable to Zoogs standing exactly where he was")
	_require(plot.is_free_for(zoogs), claim,
		"is_free_for agrees the plot lapsed — the Action's gate disagreeing with it would be a bug in the gate, not the station")

	world.queue_free()


# --- Assertion 52: the dawn race survives the register -----------------------------

# Reading the register must never turn into a reservation. Two men who both
# read a free plot at dawn both have to set off, and the plot must still go to
# whoever gets there first — claim() requiring presence is what this claim
# leans on, same as claim 16. What makes this claim more than a restatement of
# claim 13 (the sleep-order race) is the second half: the LOSER, still mid
# journey when the winner's claim lands, must stop closing the gap immediately
# rather than walking all the way in to find out — which is exactly the read
# the old position check could not give him until he physically arrived.
func _check_the_dawn_race_survives_the_register() -> void:
	var claim := "52 — two men who both read a plot free at dawn both set off, and whoever arrives first holds it"
	var world := _add_a_disabled_game_scene()
	var population := world.get_node_or_null("Population") as Population
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var hobb := world.get_node_or_null("Population/Hobb") as Person
	var inn := world.get_node_or_null("Town/Inn") as Place
	var fields := world.get_node_or_null("Town/Fields") as Place
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var zoogs_work := world.get_node_or_null("Population/Zoogs/Brain/WorkForHire") as WorkForHire
	var hobb_work := world.get_node_or_null("Population/Hobb/Brain/WorkForHire") as WorkForHire
	if population == null or clock == null or zoogs == null or hobb == null or inn == null or fields == null or plot == null or zoogs_work == null or hobb_work == null:
		_require(false, claim, "the scene came up without a Population, a Clock, a Zoogs, a Hobb, an Inn, Fields, the Plot and both men's WorkForHire")
		return

	# Both stood at the Inn, both wide awake, both reading the SAME unclaimed
	# plot from the SAME distance — this is what every dawn looks like under
	# Decision 30, and the only thing that should decide the winner is who
	# gets there first, never who happened to read the register earlier.
	_stand_at(zoogs, inn)
	_stand_at(hobb, inn)
	clock.advance(6.0)
	zoogs.stats.set_stat(&"adenosine", 0.0)
	hobb.stats.set_stat(&"adenosine", 0.0)

	_require(zoogs_work.is_available_to(zoogs), claim,
		"at dawn, with nobody holding the plot yet, work read unavailable to Zoogs from the Inn")
	_require(hobb_work.is_available_to(hobb), claim,
		"at dawn, with nobody holding the plot yet, work read unavailable to Hobb from the Inn")

	var zoogs_start_gap: float = zoogs.global_position.distance_to(fields.global_position)
	var hobb_start_gap: float = hobb.global_position.distance_to(fields.global_position)
	var zoogs_set_off := false
	var hobb_set_off := false
	var winner: Person = null

	for tick in 400:
		clock.advance(TICK_HOURS)
		population.think_for_everyone(TICK_HOURS)
		if not zoogs_set_off and zoogs.global_position.distance_to(fields.global_position) < zoogs_start_gap - 0.0001:
			zoogs_set_off = true
		if not hobb_set_off and hobb.global_position.distance_to(fields.global_position) < hobb_start_gap - 0.0001:
			hobb_set_off = true
		if winner == null and plot.claimed_by != null:
			winner = plot.claimed_by
			break

	_require(zoogs_set_off, claim,
		"Zoogs never took a single step toward the Fields — reading a free plot's register at dawn must not stop a man from setting off for it")
	_require(hobb_set_off, claim,
		"Hobb never took a single step toward the Fields — reading a free plot's register at dawn must not stop a man from setting off for it")
	_require(winner != null, claim,
		"400 ticks passed from dawn and nobody ever claimed the plot — the race never resolved")
	if winner == null:
		world.queue_free()
		return

	var loser: Person = hobb if winner == zoogs else zoogs
	_require(not plot.claim(loser), claim,
		"%s could still claim() the plot after %s already held it — the race must have exactly one winner" % [loser.person_name, winner.person_name])
	_require(plot.claimed_by == winner, claim,
		"after the loser's failed claim attempt the plot reads held by %s, not %s" % [
			(plot.claimed_by.person_name if plot.claimed_by != null else "nobody"), winner.person_name])

	# THE LOSER'S JOURNEY IS WASTED NOW, AND HE SHOULD KNOW IT IMMEDIATELY. The
	# register is public the instant the winner's claim lands — the loser does
	# not have to arrive to find out, unlike the doorstep rule this replaced.
	var loser_gap: float = loser.global_position.distance_to(fields.global_position)
	for tick in 5:
		clock.advance(TICK_HOURS)
		population.think_for_everyone(TICK_HOURS)
		var loser_gap_now: float = loser.global_position.distance_to(fields.global_position)
		_require(loser_gap_now >= loser_gap - 0.0001, claim,
			"the loser's gap to the Fields shrank from %.4f to %.4f after the winner already held the plot — he must stop closing on a plot the register already says is taken" % [
				loser_gap, loser_gap_now])
		loser_gap = loser_gap_now

	world.queue_free()


# --- Assertion 53: the bedless man does not pace the doorway -----------------------

# Reuses claim 45's own setup (twenty-one sleepers, twenty beds, night, forced
# adenosine) rather than inventing a second one — see that claim's header for
# why each of those choices is there. What this claim adds is the exact
# geometry claim 22 adds for a plot: the standing man driven, by hand, one
# tick's walk from the Inn, so the departure tick — the tick the old
# hand-copied check went blind on — is pinned down rather than incidental.
func _check_the_bedless_man_does_not_pace_the_doorway() -> void:
	var claim := "53 — twenty-one sleepers at a twenty-bed Inn: the man with no bed does not pace the doorway"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var population := world.get_node_or_null("Population") as Population
	var inn := world.get_node_or_null("Town/Inn") as Place
	var fields := world.get_node_or_null("Town/Fields") as Place
	if clock == null or population == null or inn == null or fields == null:
		_require(false, claim, "the scene came up without a Clock, a Population, an Inn and Fields")
		return

	clock.advance(1.0)

	var spares: Array[Person] = []
	for i in 21:
		var spare := _add_a_person(population, "Sleeper%d" % i)
		if spare == null:
			_require(false, claim, "could not instance %s" % PERSON_SCENE_PATH)
			return
		_stand_at(spare, inn)
		spare.stats.set_stat(&"adenosine", 90.0)
		spares.append(spare)

	for tick in 5:
		clock.advance(TICK_HOURS)
		population.think_for_everyone(TICK_HOURS)

	var awake_spare: Person = null
	for spare in spares:
		if spare.brain.is_awake():
			awake_spare = spare
	_require(awake_spare != null, claim,
		"twenty beds and twenty-one sleepers should leave exactly one man standing and none is — see claim 45")
	if awake_spare == null:
		world.queue_free()
		return

	var sleep_action := awake_spare.get_node_or_null("Brain/Sleep") as Sleep
	var walk := awake_spare.get_node_or_null("Brain/Sleep/Rest/GoTo") as GoToStep
	if sleep_action == null or walk == null:
		_require(false, claim, "the standing man has no Sleep action, or its Rest has no GoToStep")
		world.queue_free()
		return

	_require(not sleep_action.is_available_to(awake_spare), claim,
		"standing at the Inn with every bed already visibly taken, Sleep still read available to the standing man")

	# ONE TICK'S WALK FROM THE DOOR — the exact distance the pre-Decision-30
	# hand-copied check pulled him back and forth across all night. Driven
	# directly, the same technique claim 22 uses for the plot case.
	walk.walk_toward(awake_spare, fields, TICK_HOURS)
	_require(awake_spare.get_current_place() == null, claim,
		"one tick after stepping away from the Inn, current_place reads %s, not nowhere — this claim needs him mid-step" % _describe_place(awake_spare.get_current_place()))
	_require(not sleep_action.is_available_to(awake_spare), claim,
		"one tick's walk from the doorway, with current_place now nowhere, Sleep read available again — this is exactly the position the old hand-copied check went blind at")

	# THE TICK AFTER. Nothing further has to happen for the register to keep
	# telling the same truth.
	clock.advance(TICK_HOURS)
	_require(not sleep_action.is_available_to(awake_spare), claim,
		"the tick after stepping away, still one tick's walk from the Inn, Sleep read available to the standing man")

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
	var common_plot := world.get_node_or_null("Town/CommonField/CommonPlot") as Workstation
	if town == null or zoogs == null or fields == null or inn == null or plot == null or common_plot == null:
		_require(false, near_claim, "the scene came up without a Town, a Zoogs, Fields, an Inn, the Plot and the CommonPlot")
		return

	# THIS CLAIM IS ABOUT TWO STATIONS, so the world has to hold exactly the
	# two it is comparing. Gate 1 authored a third `field work` station (the
	# unowned CommonPlot at Town/CommonField) — narrowing it away here is
	# deliberate, not an assumption that the town happens to hold only one
	# plot beside the hand-built NearPlot below; a later rung authoring a
	# fourth would need the same treatment, not a rewrite of this claim.
	common_plot.free()

	# A BARE WorkTheField, built by hand rather than pulled off Zoogs' Brain —
	# as of rung 6b both farmers know WorkForHire, not WorkTheField, and
	# WorkForHire scopes its candidates to the place its OBLIGATION names
	# (see work_for_hire.gd's _is_a_candidate_for). This claim is about pure
	# geography — the ordering find_workstations hands back — and routing it
	# through WorkForHire would make it a claim about employment scoping
	# instead, for a reason that has nothing to do with what it is testing.
	# get_best_candidate and _find_first_candidate need no tree membership and
	# no step, so an unparented instance is enough — the same
	# instantiate-and-use-directly pattern Place.new() and Workstation.new()
	# already use two lines below.
	var work_action := WorkTheField.new()

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

	# work_action was never parented anywhere — a deliberately unparented
	# instance, per its own comment above — so it is the one thing in this
	# claim world.queue_free() below cannot reach. Freed by hand rather than
	# left to leak.
	work_action.free()
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
# RE-ANCHORED AT RUNG 6B, THEN AGAIN AT ITS REPAIR (Decision 29). The claim's
# point — pay at exactly the seam's rate, every hundredth accounted for — is
# unchanged; WHERE the pay lands has moved twice now. First to the barn
# alone (a grain debt, since retired), and now to a SPLIT: the fields' Plot
# is owned land (Marle), so Zoogs' authored 0.35 share
# (Obligation.share_of_crop) lands in his own sack as it is earned and the
# rest lands in the barn — see work_step.gd's _pay_out. THE EXACT SPLIT
# BELOW IS HAND-TRACED, not merely computed, against
# Obligation.share_part_owed's own carry-the-remainder arithmetic: 6 whole
# grain complete in this run (see expected_whole below), and running 0.35 of
# each successive completion through the carry by hand — 0.35, 0.70, 1.05
# (pays 1st), 0.40, 0.75, 1.10 (pays 2nd) — lands the worker exactly 2 of the
# 6 and the owner the other 4. A different tick pattern would not
# necessarily reproduce these exact two numbers (see claim 56, which uses a
# round total precisely so its split is traceable without walking the carry
# by hand); this claim's own point is the RATE, and the split is asserted
# here only far enough to prove it went somewhere real rather than vanishing.
func _check_working_a_plot_yields_grain() -> void:
	var claim := "25 — working a plot yields grain at exactly the rate the seam reports"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var fields := world.get_node_or_null("Town/Fields") as Place
	var work := world.get_node_or_null("Population/Zoogs/Brain/WorkForHire") as WorkForHire
	if clock == null or zoogs == null or plot == null or fields == null or work == null:
		_require(false, claim, "the scene came up without a Clock, a Zoogs, the Plot, the Fields and Zoogs' WorkForHire")
		return
	var step := work.step as WorkStep
	var inventory := zoogs.get_inventory()
	var barn := fields.get_inventory()
	if step == null or inventory == null or barn == null:
		_require(false, claim, "WorkForHire has no WorkStep under it, Zoogs has no Inventory under him, or the Fields has none")
		return

	# Standing him in the furrow is required, and it is this rung's second trap:
	# both farmers are authored at the Inn, so "work N ticks and assert grain"
	# quietly becomes "walk N ticks and assert nothing". See _stand_at.
	_stand_at(zoogs, fields)
	_require(inventory.get_count(&"grain") == 0, claim,
		"Zoogs starts the day holding %d grain — nothing has authored him any" % inventory.get_count(&"grain"))
	_require(barn.get_count(&"grain") == 0, claim,
		"the Fields' barn starts the day holding %d grain — nothing has authored it any" % barn.get_count(&"grain"))
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
	_require(inventory.get_count(&"grain") == 2, claim,
		"%.2f hours of employed work on owned land, split 0.35/0.65, should leave his own sack holding 2 (hand-traced above) and he is holding %d" % [
			hours_worked, inventory.get_count(&"grain")])
	_require(barn.get_count(&"grain") == expected_whole - 2, claim,
		"%.2f hours at %.2f grain an hour makes %d whole grain, of which the owner's part should be %d and the barn holds %d" % [
			hours_worked, rate, expected_whole, expected_whole - 2, barn.get_count(&"grain")])
	# Sack plus barn plus furrow accounts for every hundredth. This is the half
	# that makes the claim exact rather than approximate: a rate applied per
	# tick instead of per hour, or a fraction dropped on the floor each tick,
	# both land here — now with a third container in the sum, not a new sum.
	# Splitting whole grain between two containers does not change this total
	# by one hundredth: the split only decides which of sack or barn a whole
	# grain lands in, never whether it exists.
	var accounted := float(inventory.get_count(&"grain")) + float(barn.get_count(&"grain")) + plot.output_part_made
	_require(absf(accounted - owed) < 0.0001, claim,
		"%.2f hours at %.2f an hour owes %.4f grain, and sack (%d) plus barn (%d) plus furrow (%.4f) accounts for %.4f" % [
			hours_worked, rate, owed, inventory.get_count(&"grain"), barn.get_count(&"grain"), plot.output_part_made, accounted])

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
	var work := world.get_node_or_null("Population/Zoogs/Brain/WorkForHire") as WorkForHire
	if clock == null or zoogs == null or plot == null or fields == null or inn == null or work == null:
		_require(false, claim, "the scene came up without a Clock, a Zoogs, the Plot, the Fields, an Inn and Zoogs' WorkForHire")
		return
	var step := work.step as WorkStep
	var inventory := zoogs.get_inventory()
	var barn := fields.get_inventory()
	if step == null or inventory == null or barn == null:
		_require(false, claim, "WorkForHire has no WorkStep under it, Zoogs has no Inventory under him, or the Fields has none")
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
		# THE BARN — a third place a walking man's pay must not appear, new at
		# rung 6b: the delivery leg gives grain a second home besides his own
		# sack, and this check would be silently incomplete watching only the
		# one place WorkStep alone ever wrote to.
		_require(barn.get_count(&"grain") == 0, claim,
			"%.4f units short of the Fields and the barn already holds %d grain — delivery is happening from the road" % [
				zoogs.global_position.distance_to(fields.global_position), barn.get_count(&"grain")])
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
	_require(barn.get_count(&"grain") == 0, claim,
		"the walk from the Inn to the Fields delivered %d grain to the barn" % barn.get_count(&"grain"))
	_require(is_zero_approx(plot.output_part_made), claim,
		"the walk from the Inn to the Fields banked %.4f of a grain on the plot" % plot.output_part_made)

	# And now that he IS there, one tick of the same step must pay somewhere.
	# Without this the claim above could be satisfied by a step that never
	# produces anything at all, anywhere — which is the vacuous form of it.
	#
	# THREE PLACES COUNT, not two, as of rung 6b — a tick's work lands in the
	# furrow while it is a fraction, in his sack once it is whole, OR straight
	# in the barn if the delivery leg moves it on the very tick it completes.
	# Naming only the furrow would go red for a rate of one grain per tick —
	# a real defect, but it is claim 25's to catch, and a claim that fails for
	# somebody else's reason is a claim you stop believing.
	clock.advance(TICK_HOURS)
	step.advance(zoogs, TICK_HOURS)
	_require(inventory.get_count(&"grain") > 0 or barn.get_count(&"grain") > 0 or plot.output_part_made > 0.0, claim,
		"standing in the furrow with the plot claimed, one worked tick left him holding %d grain, the barn holding %d, and the plot holding %.4f — the step produces nothing ANYWHERE, so the walking half of this claim proves nothing" % [
			inventory.get_count(&"grain"), barn.get_count(&"grain"), plot.output_part_made])

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


# --- Assertions 31-34: hunger, the second drive ------------------------------------

# The mirror of claim 5, for the new drive. On a FRESH world, one hour must
# move hunger by exactly its own accumulation rate — AMOUNT, not direction, for
# the same reason claim 5 reads that way: a rate applied per tick instead of
# per world hour still moves the number in the right direction, just by the
# wrong amount, and only an exact check catches that. Doing nothing at all
# means whatever StayUp he starts on; upkeep must move him regardless of what
# he chose, which is the whole point of it living in Brain rather than in an
# action.
#
# AND IT MUST RISE WHILE HE IS ASLEEP TOO — the second half below, added
# 2026-08-14, and it was added because the FIRST half could not fail on the
# thing it was supposed to guard. `_update_body`'s hunger line is deliberately
# unbranched, and that no-branch is load-bearing: it is the whole reason a man
# wakes up hungry. Break-testing rung 6d's identical social line by wrapping it
# in `if is_awake()` reddened NOTHING, because an awake man's reading is the
# same either way. A claim that cannot fail on its own subject is decoration —
# so the sleeping half is where this claim actually earns its place.
func _check_hunger_rises_for_an_idle_man() -> void:
	var claim := "31 — hunger rises for a man doing nothing at all, awake OR asleep, by exactly one hour's worth in one hour"
	var world := _add_a_disabled_game_scene()
	var person := world.get_node_or_null("Population/Zoogs") as Person
	var population := world.get_node_or_null("Population") as Population
	var inn := world.get_node_or_null("Town/Inn") as Place
	if person == null or population == null or inn == null:
		_require(false, claim, "a second game scene came up without a Population, a Zoogs and an Inn")
		return

	var hungry_before: float = person.stats.get_stat(&"hunger")
	population.think_for_everyone(1.0)
	var moved: float = person.stats.get_stat(&"hunger") - hungry_before
	var expected: float = person.brain.get_hunger_accumulation()

	_require(absf(moved - expected) < 0.001, claim,
		"awake, one hour moved hunger by %.4f where one hour's worth is %.4f" % [moved, expected])

	_require_the_stat_rises_while_he_sleeps(&"hunger", claim, world, population, inn)

	world.queue_free()


# The sleeping half of claims 31 and 49, shared because it is the same question
# asked of two stats and writing it twice is two chances to ask it differently.
#
# A spare is put down at the Inn with a night's worth of tiredness on him, so
# the decision layer itself chooses Sleep and Rest claims a bed — never poked
# into a fake sleeping state, because what is under test is the body's upkeep
# under a REAL sleeping man. The stat is seeded low so an hour cannot reach the
# ceiling and clamp, which would flatten the reading into a false pass.
func _require_the_stat_rises_while_he_sleeps(
	stat_name: StringName, claim: String, world: Node, population: Population, inn: Place
) -> void:
	var sleeper := _add_a_person(population, "Sleeper")
	if sleeper == null:
		_require(false, claim, "could not instance %s" % PERSON_SCENE_PATH)
		return
	_stand_at(sleeper, inn)
	sleeper.stats.set_stat(&"adenosine", 90.0)
	sleeper.stats.set_stat(stat_name, 10.0)

	# Long enough for the decision layer to pick Sleep and for Rest to claim a
	# bed he is already standing beside.
	for tick in 5:
		population.think_for_everyone(TICK_HOURS)
	_require(not sleeper.brain.is_awake(), claim,
		"a man put down at the Inn with adenosine 90 did not fall asleep, so the sleeping half of this claim tested nothing")
	if sleeper.brain.is_awake():
		return

	var before: float = sleeper.stats.get_stat(stat_name)
	for tick in 100:
		population.think_for_everyone(TICK_HOURS)
	var moved: float = sleeper.stats.get_stat(stat_name) - before
	var expected: float = 0.0
	if stat_name == &"hunger":
		expected = sleeper.brain.get_hunger_accumulation()
	else:
		expected = sleeper.brain.get_social_accumulation()

	_require(not sleeper.brain.is_awake(), claim,
		"the sleeper woke up inside the measured hour, so the reading covers a man who was not asleep throughout")
	_require(absf(moved - expected) < 0.001, claim,
		"ASLEEP, one hour moved %s by %.4f where one hour's worth is %.4f — upkeep must not branch on being awake, and that no-branch is why he wakes hungry and lonely" % [
			stat_name, moved, expected])


# Both halves of "he ate": the stat fell AND the count went down by one, so a
# step that changed hunger for free could not satisfy this. Driven through the
# STEP directly, the same way claims 14 and 25 do — this is about what eating
# DOES, not about whether the decision layer would choose it at this hour.
# The drop is read off the step's own export rather than hardcoded, so a
# retune on the board cannot make this claim lie about what it's checking.
func _check_eating_drops_hunger_and_a_loaf() -> void:
	var claim := "32 — eating drops hunger and consumes exactly one loaf, both halves"
	var world := _add_a_disabled_game_scene()
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var eat := world.get_node_or_null("Population/Zoogs/Brain/Eat") as Eat
	if zoogs == null or eat == null:
		_require(false, claim, "the scene came up without a Zoogs or Zoogs' Eat action")
		return
	var step := eat.step as EatStep
	var inventory := zoogs.get_inventory()
	if step == null or inventory == null:
		_require(false, claim, "Eat has no EatStep under it, or Zoogs has no Inventory under him")
		return

	zoogs.stats.set_stat(&"hunger", 90.0)
	var bread_before := inventory.get_count(&"bread")
	_require(bread_before >= 1, claim,
		"Zoogs is authored with %d bread — expected at least one loaf to eat" % bread_before)

	step.advance(zoogs, TICK_HOURS)

	var expected_drop: float = step.hunger_a_loaf_fixes
	_require(inventory.get_count(&"bread") == bread_before - 1, claim,
		"one advance() should consume exactly one loaf — he holds %d where he started with %d" % [
			inventory.get_count(&"bread"), bread_before])
	_require(absf(zoogs.stats.get_stat(&"hunger") - (90.0 - expected_drop)) < 0.001, claim,
		"hunger should have fallen by exactly %.2f (the step's own hunger_a_loaf_fixes) and reads %.2f instead of %.2f" % [
			expected_drop, zoogs.stats.get_stat(&"hunger"), 90.0 - expected_drop])

	world.queue_free()


# EMPTIES THE BAG EXPLICITLY, per the rung's own warning: a spare starting
# empty is not the same claim as a man who WAS fed and then ran out, and a
# check states the world it wants rather than inheriting one. NAN, not merely
# a low score — the same off-the-ballot shape claims 13 and 21 already use,
# because a plain low number would mean he was OUTscored, which is a
# different and false claim. And having nothing to eat must not stop the
# upkeep line running — hunger is a fact about his body, not about his
# larder.
func _check_no_bread_means_off_the_ballot() -> void:
	var claim := "33 — a man with no bread cannot eat: Eat is off his ballot entirely, and hunger keeps rising regardless"
	var world := _add_a_disabled_game_scene()
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var population := world.get_node_or_null("Population") as Population
	var eat := world.get_node_or_null("Population/Zoogs/Brain/Eat") as Eat
	if zoogs == null or population == null or eat == null:
		_require(false, claim, "the scene came up without a Zoogs, a Population and Zoogs' Eat action")
		return
	var inventory := zoogs.get_inventory()
	if inventory == null:
		_require(false, claim, "Zoogs has no Inventory under him")
		return

	var starting_bread := inventory.get_count(&"bread")
	if starting_bread > 0:
		inventory.take(&"bread", starting_bread)
	_require(inventory.get_count(&"bread") == 0, claim,
		"could not empty Zoogs' bread before the check — he still holds %d" % inventory.get_count(&"bread"))

	zoogs.stats.set_stat(&"hunger", 90.0)
	var hungry_before: float = zoogs.stats.get_stat(&"hunger")

	population.think_for_everyone(TICK_HOURS)

	var score: Variant = zoogs.brain.get_last_scores().get(eat.name)
	var off_the_ballot := false
	if score is float:
		var score_value: float = score
		off_the_ballot = is_nan(score_value)
	_require(off_the_ballot, claim,
		"with no bread, Zoogs' Eat score reads %s — an empty sack must take Eat off the ballot entirely (NAN), not merely outscore it" % str(score))
	_require(zoogs.stats.get_stat(&"hunger") > hungry_before, claim,
		"having no bread stopped hunger rising over one tick — it went from %.4f to %.4f" % [
			hungry_before, zoogs.stats.get_stat(&"hunger")])

	world.queue_free()


# Set well below what a loaf fixes, so a step that didn't clamp would drive
# the stat negative and this would catch it on the first meal, not the fifth.
func _check_hunger_never_goes_negative() -> void:
	var claim := "34 — hunger never goes negative, however much he eats"
	var world := _add_a_disabled_game_scene()
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var eat := world.get_node_or_null("Population/Zoogs/Brain/Eat") as Eat
	if zoogs == null or eat == null:
		_require(false, claim, "the scene came up without a Zoogs or Zoogs' Eat action")
		return
	var step := eat.step as EatStep
	var inventory := zoogs.get_inventory()
	if step == null or inventory == null:
		_require(false, claim, "Eat has no EatStep under it, or Zoogs has no Inventory under him")
		return

	zoogs.stats.set_stat(&"hunger", 3.0)
	var bread_before := inventory.get_count(&"bread")
	_require(bread_before >= 1, claim,
		"Zoogs is authored with %d bread — expected at least one loaf to eat" % bread_before)

	step.advance(zoogs, TICK_HOURS)

	_require(is_zero_approx(zoogs.stats.get_stat(&"hunger")), claim,
		"hunger starting at 3.0, well below what a loaf fixes, reads %.4f after one meal instead of clamping at 0.0" % [
			zoogs.stats.get_stat(&"hunger")])
	_require(inventory.get_count(&"bread") == bread_before - 1, claim,
		"a meal that clamped at the floor should still have consumed one loaf — he holds %d where he started with %d" % [
			inventory.get_count(&"bread"), bread_before])

	world.queue_free()


# --- Assertion 35: adenosine is written from nowhere outside brain.gd --------------

# THE MECHANICAL FORM of the upkeep-vs-effects rule. A TEXT SCAN, in the shape
# SceneWiring already establishes for .tscn files: at runtime "was this ever
# written outside brain.gd" isn't something a pumped run can catch by itself —
# you'd have to already know where to look before you could watch for it, and
# a scan over the source text doesn't need to.
#
# Exactly three exemptions, each for a different reason: brain.gd is the one
# legitimate write site (upkeep); stats.gd carries the declaration itself,
# which is not a write in the sense this claim means; probe.gd is the harness
# authoring situations by hand, the same exemption _stand_at already takes for
# current_place.
#
# DELIBERATELY NOT EXTENDED TO HUNGER. Eat MUST write hunger — that's an
# effect the design permits, not upkeep sneaking in through a side door — so a
# parallel scan over "hunger" would be asserting the opposite of what this
# rung built.
#
# THE POSITIVE CONTROL matters as much as the scan: a scan finding nothing
# could just as easily be reading the wrong pattern or the wrong folder, and a
# claim that can only ever pass proves nothing. So this also asserts brain.gd
# DOES contain a write — if that pattern ever stops matching brain.gd's own
# upkeep line, this claim fails for that reason rather than going on passing
# vacuously forever.
const _ADENOSINE_SCAN_EXEMPT_FILES: Array[String] = [
	"res://game/brain.gd",       # the one legitimate write site — upkeep
	"res://game/stats.gd",       # the declaration, not a write
	"res://game/probe.gd",       # the harness authoring situations by hand
]

func _check_adenosine_is_written_only_in_brain() -> void:
	var claim := "35 — adenosine is written from nowhere outside brain.gd"
	var script_paths := _find_gd_files("res://game")
	_require(not script_paths.is_empty(), claim,
		"found no .gd files at all under res://game — the scan read nothing")

	# Direct assignment, GDScript's typed-declaration colon included, so both
	# `adenosine = x` and `adenosine := x` are caught alongside `+=` and
	# friends. The word boundary is what keeps this from tripping over
	# `adenosine_ceiling` or `base_adenosine_per_hour` — both have a
	# non-boundary character sitting where this pattern needs a break.
	var assignment_regex := RegEx.create_from_string("\\badenosine\\b\\s*:?[-+*/]?=(?!=)")

	var offenders: Array[String] = []
	var brain_has_a_write := false
	for script_path: String in script_paths:
		var file_text := FileAccess.get_file_as_string(script_path)
		if FileAccess.get_open_error() != OK:
			continue
		var writes := file_text.contains("set_stat(&\"adenosine\"") \
			or assignment_regex.search(file_text) != null
		if script_path == "res://game/brain.gd":
			brain_has_a_write = writes
			continue
		if _ADENOSINE_SCAN_EXEMPT_FILES.has(script_path):
			continue
		if writes:
			offenders.append(script_path)

	_require(offenders.is_empty(), claim,
		"adenosine is written outside brain.gd in: %s" % ", ".join(offenders))
	_require(brain_has_a_write, claim,
		"brain.gd itself reads as having no write to adenosine — the scan's pattern is not matching its own upkeep line, so a scan that finds nothing proves nothing")


# The same DirAccess walk SceneWiring.find_scene_files uses, rewritten here for
# .gd rather than .tscn. Kept in probe.gd rather than folded into SceneWiring,
# which is about .tscn wiring specifically and isn't the right home for a
# write-site scan over source text.
func _find_gd_files(root_dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	_gather_gd_files(root_dir, found)
	return found


func _gather_gd_files(dir_path: String, found: PackedStringArray) -> void:
	var directory := DirAccess.open(dir_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while entry_name != "":
		if entry_name != "." and entry_name != "..":
			var entry_path := dir_path.path_join(entry_name)
			if directory.current_is_dir():
				if entry_name != ".godot" and entry_name != ".import" and entry_name != "addons":
					_gather_gd_files(entry_path, found)
			elif entry_name.ends_with(".gd"):
				found.append(entry_path)
		entry_name = directory.get_next()
	directory.list_dir_end()


# --- Assertion 36: Eat is on every person by composition ---------------------------

# FR86's guarantee made mechanical, the same way claim 7 makes composition
# mechanical for a man's place. A fresh person.tscn, nothing authored beyond
# what the scene itself ships with — no bread, no hunger set by hand — and Eat
# still has to be in his repertoire, because it's in every person scene rather
# than something learned.
func _check_eat_is_on_every_person_by_composition() -> void:
	var claim := "36 — Eat is on every person by composition"
	var world := _add_a_disabled_game_scene()
	var population := world.get_node_or_null("Population") as Population
	if population == null:
		_require(false, claim, "a second game scene came up without a Population in it")
		return

	var newcomer := _add_a_person(population, "Newcomer")
	if newcomer == null:
		_require(false, claim, "could not instance %s" % PERSON_SCENE_PATH)
		return

	var knows_eat := false
	for action in newcomer.brain.get_known_actions():
		if action is Eat:
			knows_eat = true
			break
	_require(knows_eat, claim,
		"a freshly instanced person, nothing else authored, does not know Eat — it must be present by composition, not learned")

	world.queue_free()


# --- Assertion 37: baking, driven through the step ----------------------------

# Driven through the STEP directly, the same pattern claims 14, 25 and 32 use
# — this is about what baking DOES, not about whether the decision layer
# would choose it at this hour. Both doors are asserted, not just one: a step
# that consumed grain without producing bread, or produced bread for free,
# would each satisfy only half of "he baked". And the refusal half — too
# little grain for even one loaf — has to move NEITHER count, the same
# all-or-nothing rule Inventory.take() already guarantees generally.
func _check_baking_turns_grain_into_bread() -> void:
	var claim := "37 — baking turns three grain into one loaf, and the world's totals move at both doors"
	var world := _add_a_disabled_game_scene()
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var make_bread := world.get_node_or_null("Population/Zoogs/Brain/MakeBread") as MakeBread
	if zoogs == null or make_bread == null:
		_require(false, claim, "the scene came up without a Zoogs or Zoogs' MakeBread action")
		return
	var step := make_bread.step as MakeBreadStep
	var inventory := zoogs.get_inventory()
	if step == null or inventory == null:
		_require(false, claim, "MakeBread has no MakeBreadStep under it, or Zoogs has no Inventory under him")
		return

	var loaf_cost := step.grain_per_loaf
	inventory.add(&"grain", 7)
	var grain_before := inventory.get_count(&"grain")
	var bread_before := inventory.get_count(&"bread")

	step.advance(zoogs, TICK_HOURS)

	_require(inventory.get_count(&"grain") == grain_before - loaf_cost, claim,
		"one advance() should consume exactly %d grain (the step's own grain_per_loaf) — he holds %d where he started with %d" % [
			loaf_cost, inventory.get_count(&"grain"), grain_before])
	_require(inventory.get_count(&"bread") == bread_before + 1, claim,
		"one advance() should add exactly one loaf — he holds %d bread where he started with %d" % [
			inventory.get_count(&"bread"), bread_before])

	# STARVE THE STEP. Bring him below one loaf's worth of grain and advance
	# again: the partial-take refusal must do its job here exactly as it does
	# in Inventory.take() generally.
	var grain_left := inventory.get_count(&"grain")
	if grain_left >= loaf_cost:
		inventory.take(&"grain", grain_left - loaf_cost + 1)
	_require(inventory.get_count(&"grain") < loaf_cost, claim,
		"could not bring Zoogs below one loaf's worth of grain to test the refusal — he holds %d against a cost of %d" % [
			inventory.get_count(&"grain"), loaf_cost])

	var grain_before_refusal := inventory.get_count(&"grain")
	var bread_before_refusal := inventory.get_count(&"bread")
	step.advance(zoogs, TICK_HOURS)
	_require(inventory.get_count(&"grain") == grain_before_refusal, claim,
		"with fewer than %d grain, an advance() still took some — he holds %d where he started with %d" % [
			loaf_cost, inventory.get_count(&"grain"), grain_before_refusal])
	_require(inventory.get_count(&"bread") == bread_before_refusal, claim,
		"with too little grain to bake, a loaf still appeared — bread reads %d where it started at %d" % [
			inventory.get_count(&"bread"), bread_before_refusal])

	world.queue_free()


# --- Assertion 38: bread wins over baking, and grain alone bakes ---------------

# THROUGH THE DECISION LAYER, at hour 0 — midnight, a fresh world, he starts
# awake with StayUp (47.3) and WorkForHire (~43 at midnight, off his own
# authored obligation) the only other competition. At the shipped numbers a
# hunger of 90 scores Eat around 94.8 and MakeBread around 83.8 — both clear
# StayUp and WorkForHire — but NEITHER number is asserted here. What's
# asserted is which ACTION won, so a retune on
# the board can never make this claim lie about what it's checking: the
# ordering between Eat and MakeBread is the two weights doing their one job.
func _check_bread_wins_over_baking_and_grain_alone_bakes() -> void:
	var claim := "38 — with bread in the bag he eats; with none but grain he bakes"

	var world_a := _add_a_disabled_game_scene()
	var zoogs_a := world_a.get_node_or_null("Population/Zoogs") as Person
	var population_a := world_a.get_node_or_null("Population") as Population
	if zoogs_a == null or population_a == null:
		_require(false, claim, "the first world came up without a Zoogs and a Population")
		return
	var inventory_a := zoogs_a.get_inventory()
	if inventory_a == null:
		_require(false, claim, "Zoogs has no Inventory under him")
		return
	# Bread AND grain both present — he already holds authored bread (rung
	# 6a's fourteen loaves), and grain is added through the door for good
	# measure so this half is a genuine contest, not a default from MakeBread
	# being gated off.
	inventory_a.add(&"grain", 10)
	zoogs_a.stats.set_stat(&"hunger", 90.0)
	population_a.think_for_everyone(TICK_HOURS)
	var action_a: Action = zoogs_a.brain.current_action
	_require(action_a != null and action_a is Eat, claim,
		"with bread AND grain both in the bag, hunger 90 chose \"%s\", not Eat" % [
			String(action_a.name) if action_a != null else "nothing"])
	world_a.queue_free()

	var world_b := _add_a_disabled_game_scene()
	var zoogs_b := world_b.get_node_or_null("Population/Zoogs") as Person
	var population_b := world_b.get_node_or_null("Population") as Population
	if zoogs_b == null or population_b == null:
		_require(false, claim, "the second world came up without a Zoogs and a Population")
		return
	var inventory_b := zoogs_b.get_inventory()
	if inventory_b == null:
		_require(false, claim, "Zoogs has no Inventory under him")
		return
	# EMPTY THE BREAD BAG EXPLICITLY — state the world this half wants rather
	# than leaning on a spare starting empty, the same lesson claim 33 paid
	# for. Grain only, so baking is the one candidate left that can serve
	# hunger at all.
	var starting_bread := inventory_b.get_count(&"bread")
	if starting_bread > 0:
		inventory_b.take(&"bread", starting_bread)
	_require(inventory_b.get_count(&"bread") == 0, claim,
		"could not empty Zoogs' bread before the second half of this check — he still holds %d" % inventory_b.get_count(&"bread"))
	inventory_b.add(&"grain", 10)
	zoogs_b.stats.set_stat(&"hunger", 90.0)
	population_b.think_for_everyone(TICK_HOURS)
	var action_b: Action = zoogs_b.brain.current_action
	_require(action_b != null and action_b is MakeBread, claim,
		"with grain and no bread, hunger 90 chose \"%s\", not MakeBread" % [
			String(action_b.name) if action_b != null else "nothing"])
	world_b.queue_free()


# --- Assertion 39: the desert case ----------------------------------------------

# BOTH emptied explicitly — the lesson claim 33 already paid for, applied
# twice over. NAN for both, the same off-the-ballot shape claims 13, 21 and 33
# already use: a plain low score would mean OUTscored, which is a different
# and false claim when the truth is he holds nothing that could ever serve
# either want. And hunger keeps climbing regardless — the want doesn't pause
# because nobody can answer it, it just keeps growing in silence, which is
# the whole reason this rung is the one where losing the dawn race finally
# has a stake.
func _check_neither_grain_nor_bread_means_neither_and_hunger_still_rises() -> void:
	var claim := "39 — a man with neither grain nor bread does neither, and goes on getting hungrier"
	var world := _add_a_disabled_game_scene()
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var population := world.get_node_or_null("Population") as Population
	var eat := world.get_node_or_null("Population/Zoogs/Brain/Eat") as Eat
	var make_bread := world.get_node_or_null("Population/Zoogs/Brain/MakeBread") as MakeBread
	if zoogs == null or population == null or eat == null or make_bread == null:
		_require(false, claim, "the scene came up without a Zoogs, a Population, Zoogs' Eat action and Zoogs' MakeBread action")
		return
	var inventory := zoogs.get_inventory()
	if inventory == null:
		_require(false, claim, "Zoogs has no Inventory under him")
		return

	var starting_bread := inventory.get_count(&"bread")
	if starting_bread > 0:
		inventory.take(&"bread", starting_bread)
	var starting_grain := inventory.get_count(&"grain")
	if starting_grain > 0:
		inventory.take(&"grain", starting_grain)
	_require(inventory.get_count(&"bread") == 0 and inventory.get_count(&"grain") == 0, claim,
		"could not empty Zoogs' bread and grain before the check — he holds %d bread and %d grain" % [
			inventory.get_count(&"bread"), inventory.get_count(&"grain")])

	zoogs.stats.set_stat(&"hunger", 90.0)
	var hungry_before: float = zoogs.stats.get_stat(&"hunger")

	for tick in 5:
		population.think_for_everyone(TICK_HOURS)

	var eat_score: Variant = zoogs.brain.get_last_scores().get(eat.name)
	var eat_off_the_ballot := false
	if eat_score is float:
		var eat_score_value: float = eat_score
		eat_off_the_ballot = is_nan(eat_score_value)
	_require(eat_off_the_ballot, claim,
		"with neither bread nor grain, Zoogs' Eat score reads %s — it must be off the ballot (NAN)" % str(eat_score))

	var bake_score: Variant = zoogs.brain.get_last_scores().get(make_bread.name)
	var bake_off_the_ballot := false
	if bake_score is float:
		var bake_score_value: float = bake_score
		bake_off_the_ballot = is_nan(bake_score_value)
	_require(bake_off_the_ballot, claim,
		"with neither bread nor grain, Zoogs' MakeBread score reads %s — it must be off the ballot (NAN)" % str(bake_score))

	_require(zoogs.stats.get_stat(&"hunger") > hungry_before, claim,
		"having nothing to eat or bake stopped hunger rising over 5 ticks — it went from %.4f to %.4f" % [
			hungry_before, zoogs.stats.get_stat(&"hunger")])

	world.queue_free()


# --- Assertion 41: expiry, the mirror of discharge --------------------------------

# The other half of the gate/score split in work_for_hire.gd's header: EXPIRY
# takes the candidate out of the world entirely, unlike discharge (claim 40),
# which only empties the want. Same off-the-ballot shape claims 13, 21 and 33
# already use for a different reason (a lost race, a plot he can see is
# taken, an empty larder) — this is a fourth cause producing the identical
# effect, which is the point: NAN always means "never asked", regardless of
# why.
func _check_expired_obligation_leaves_the_candidate_set() -> void:
	var claim := "41 — an expired obligation leaves the candidate set"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var population := world.get_node_or_null("Population") as Population
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var work_action := world.get_node_or_null("Population/Zoogs/Brain/WorkForHire") as WorkForHire
	if clock == null or population == null or zoogs == null or fields == null or plot == null or work_action == null:
		_require(false, claim, "the scene came up without a Clock, a Population, a Zoogs, the Fields, the Plot and Zoogs' WorkForHire")
		return
	var obligation := work_action.get_standing_obligation(zoogs)
	if obligation == null:
		_require(false, claim, "Zoogs has no standing obligation to expire")
		return

	obligation.expires_on_day = 0
	_stand_at(zoogs, fields)
	clock.advance(30.0) # day 1, mid-morning — well past expires_on_day
	_require(obligation.is_expired(), claim,
		"expires_on_day = 0 on day %d should read expired and does not" % clock.day())

	population.think_for_everyone(TICK_HOURS)
	_require(not work_action.is_available_to(zoogs), claim,
		"an expired obligation still left WorkForHire available to Zoogs")

	var score: Variant = zoogs.brain.get_last_scores().get(work_action.name)
	var score_is_off_the_ballot := false
	if score is float:
		var score_value: float = score
		score_is_off_the_ballot = is_nan(score_value)
	_require(score_is_off_the_ballot, claim,
		"an expired obligation's WorkForHire score reads %s — expiry must take the candidate OFF the ballot (NAN), the same shape claims 13, 21 and 33 already use" % str(score))

	_require(not plot.is_permitted_to(zoogs), claim,
		"the plot still reads permitted for Zoogs after his only obligation naming it expired")

	world.queue_free()


# --- Assertion 43: owned land refuses the unemployed, and it is its own counter ---

# THE LIBRARY ACTION, not WorkForHire. work_the_field.tscn stays in the
# library after this rung with nothing authored using it any more — both
# farmers were switched to WorkForHire in game.tscn — and this is what
# exercises it: a plain WorkTheField still has to gate correctly on OWNED
# land, with no employment logic of its own standing between it and the
# station. Permission lives on Workstation, not on the Action, so any Action
# that walks up to owned land has to respect it identically.
func _check_owned_plot_refuses_the_unemployed_and_counts_it() -> void:
	var claim := "43 — an owned plot is not a candidate for a man with no obligation, and the refusal is its own counter"
	var world := _add_a_disabled_game_scene()
	var town := world.get_node_or_null("Town") as Town
	var population := world.get_node_or_null("Population") as Population
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var marle := world.get_node_or_null("Population/Marle") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	var common_plot := world.get_node_or_null("Town/CommonField/CommonPlot") as Workstation
	if town == null or population == null or zoogs == null or marle == null or fields == null or plot == null or common_plot == null:
		_require(false, claim, "the scene came up without a Town, a Population, a Zoogs, a Marle, the Fields, the Plot and the CommonPlot")
		return

	# THIS CLAIM IS ABOUT THE OWNED PLOT REFUSING AN UNEMPLOYED MAN. Gate 1
	# authored a second, UNOWNED `field work` station (CommonPlot at
	# Town/CommonField) — freeing it here is deliberate, the same narrowing
	# claims 23/24 now use, so a spare who has no claim on the owned plot
	# does not go on to find a legitimate one on common land instead, for a
	# reason that has nothing to do with what this claim is about.
	common_plot.free()

	var spare := _add_a_person(population, "Spare")
	if spare == null:
		_require(false, claim, "could not instance %s" % PERSON_SCENE_PATH)
		return
	var work_scene: PackedScene = load("res://game/actions/work_the_field.tscn") as PackedScene
	if work_scene == null:
		_require(false, claim, "could not load res://game/actions/work_the_field.tscn")
		return
	var spare_work := spare.brain.learn(work_scene) as WorkTheField
	if spare_work == null:
		_require(false, claim, "Brain.learn() did not hand back a WorkTheField")
		return

	_stand_at(spare, fields)
	_stand_at(zoogs, fields)

	_require(not plot.is_permitted_to(spare), claim,
		"an owned plot read permitted for a man with no claim on it at all")
	_require(plot.is_permitted_to(marle), claim,
		"the plot's own owner read not permitted on his own land")
	_require(plot.is_permitted_to(zoogs), claim,
		"Zoogs, whose obligation names the grain fields, read not permitted on it")

	var no_candidates_before: float = town.no_candidates_existed_pressure
	var every_taken_before: float = town.every_candidate_was_taken_pressure
	var not_permitted_before: float = town.was_not_permitted_pressure

	_require(not spare_work.is_available_to(spare), claim,
		"a plain WorkTheField still read available to a man with no obligation and no ownership on land that is owned")

	_require(absf(town.was_not_permitted_pressure - not_permitted_before - 1.0) < 0.0001, claim,
		"a not-permitted refusal should move was_not_permitted_pressure by exactly 1.0, moved it by %.1f" % [
			town.was_not_permitted_pressure - not_permitted_before])
	_require(town.no_candidates_existed_pressure == no_candidates_before, claim,
		"a not-permitted refusal moved no_candidates_existed_pressure — that counter is for a town with no field at all")
	_require(town.every_candidate_was_taken_pressure == every_taken_before, claim,
		"a not-permitted refusal moved every_candidate_was_taken_pressure — that counter is for a permitted man finding no room")

	world.queue_free()


# --- Assertion 54: the wage never bids on the larder ------------------------------

# DECISION 31, MADE MECHANICAL. THIS IS A CLAIM ABOUT AN ABSENT BRANCH, and an
# absent branch proves nothing unless asserted in the one state where the
# MISSING branch would have changed the answer — an empty sack scores
# identically to a full one whether or not anything reads the larder, so the
# claim has to compare the two states directly rather than just reading one.
# Break-tested by temporarily multiplying the score by the same
# weight × gap^bite MakeBread now uses: it goes red exactly here, at the full
# larder, because that is the only state where reading the gap would move the
# number.
func _check_work_score_is_unchanged_by_his_sack() -> void:
	var claim := "54 — a farmer's work score is unchanged by what is in his sack"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var work_action := world.get_node_or_null("Population/Zoogs/Brain/WorkForHire") as WorkForHire
	if clock == null or zoogs == null or work_action == null:
		_require(false, claim, "the scene came up without a Clock, a Zoogs and Zoogs' WorkForHire")
		return
	var inventory := zoogs.get_inventory()
	if inventory == null:
		_require(false, claim, "Zoogs has no Inventory")
		return

	# A fixed hour so the daylight term is identical on both reads — this
	# claim is about the SACK, not the sun.
	clock.advance(8.0)

	inventory.take(&"bread", inventory.get_count(&"bread"))
	inventory.take(&"grain", inventory.get_count(&"grain"))
	var score_empty := work_action.get_utility_score(zoogs)

	# THE STATE A LARDER-SHAPED SCORE WOULD DIFFER IN — bread past MakeBread's
	# own larder_target, grain in hand too, the exact opposite of the state
	# above.
	inventory.add(&"bread", 20)
	inventory.add(&"grain", 20)
	var score_full := work_action.get_utility_score(zoogs)

	_require(absf(score_empty - score_full) < 0.0001, claim,
		"WorkForHire's score reads %.4f with an empty sack and %.4f with bread and grain both stocked deep — Decision 31 requires these to be identical" % [
			score_empty, score_full])

	world.queue_free()


# --- Assertion 55: the larder gap drives baking, not hunger -----------------------

# THE OTHER HALF OF DECISION 31: the gap that used to drive MakeBread
# (hunger) no longer does, and the gap that now does (the larder) has to
# actually win and lose against a real competitor at the SAME hour, the same
# adenosine, the same everything else — StayUp, the one action always open
# to an awake man with nothing more pressing. Break-tested by reverting
# MakeBread's score to hunger: with hunger held low here on purpose (so this
# claim is not accidentally passing for hunger's reasons), that break makes
# the SHORT-larder half go red — hunger near zero scores far below StayUp's
# ~87 regardless of how empty the larder is.
func _check_short_larder_bakes_full_larder_does_not() -> void:
	var claim := "55 — a short larder chooses MakeBread over StayUp, and a full larder does not"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var population := world.get_node_or_null("Population") as Population
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var make_bread := world.get_node_or_null("Population/Zoogs/Brain/MakeBread") as MakeBread
	if clock == null or population == null or zoogs == null or make_bread == null:
		_require(false, claim, "the scene came up without a Clock, a Population, a Zoogs and Zoogs' MakeBread")
		return
	var step := make_bread.step as MakeBreadStep
	var inventory := zoogs.get_inventory()
	if step == null or inventory == null:
		_require(false, claim, "MakeBread has no MakeBreadStep under it, or Zoogs has no Inventory")
		return

	clock.advance(13.0) # early afternoon — StayUp sits near its own daylight peak
	zoogs.stats.set_stat(&"adenosine", 30.0) # nowhere near Sleep's pull
	zoogs.stats.set_stat(&"hunger", 0.0) # held low so this is never accidentally Eat's or hunger's win

	# SHORT LARDER: no bread at all, grain in hand.
	inventory.take(&"bread", inventory.get_count(&"bread"))
	inventory.take(&"grain", inventory.get_count(&"grain"))
	inventory.add(&"grain", step.grain_per_loaf)

	population.think_for_everyone(TICK_HOURS)
	var chosen_short: Action = zoogs.brain.current_action
	_require(chosen_short != null and chosen_short is MakeBread, claim,
		"with an empty larder and grain in hand, Zoogs chose \"%s\", not MakeBread" % [
			String(chosen_short.name) if chosen_short != null else "nothing"])

	# FULL LARDER: bread restocked to the target, still holding grain.
	inventory.add(&"bread", make_bread.larder_target)
	inventory.add(&"grain", step.grain_per_loaf)

	population.think_for_everyone(TICK_HOURS)
	var chosen_full: Action = zoogs.brain.current_action
	_require(not (chosen_full != null and chosen_full is MakeBread), claim,
		"with a full larder and grain still in hand, Zoogs is still choosing \"%s\"" % [
			String(chosen_full.name) if chosen_full != null else "nothing"])

	world.queue_free()


# --- Assertion 56: the split lands whole, both halves, and conserves ------------

# DECISION 29's SPLIT, PROVEN AT REAL TICK GRANULARITY — driven through the
# step directly (the claims 14/25 pattern), TICK_HOURS at a time, the exact
# loop shape Population._process itself uses, because that granularity is
# the whole reason Obligation.share_part_owed exists at all (see its own
# comment): a single tick almost never completes more than one grain, and a
# naive floor(made × share) would pay the worker nothing, ever. 4.0 hours at
# 2.5/hour makes exactly 10 whole grain with nothing left in the furrow —
# chosen to be a clean total specifically so the split is checkable by hand
# rather than merely trusted: 10 completions each add 0.35 to the running
# remainder, and walking that by hand (0.35, 0.70, 1.05 pays 1, 0.40, 0.75,
# 1.10 pays 1, 0.45, 0.80, 1.15 pays 1, 0.50) lands the worker exactly 3 and
# the owner exactly 7.
func _check_crop_splits_between_owner_and_worker_and_conserves() -> void:
	var claim := "56 — the crop lands in the owner's store and the worker keeps his share, both halves and the total"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var work_action := world.get_node_or_null("Population/Zoogs/Brain/WorkForHire") as WorkForHire
	if clock == null or zoogs == null or fields == null or work_action == null:
		_require(false, claim, "the scene came up without a Clock, a Zoogs, the Fields and Zoogs' WorkForHire")
		return
	var step := work_action.step as WorkStep
	var obligation := work_action.get_standing_obligation(zoogs)
	var inventory := zoogs.get_inventory()
	var barn := fields.get_inventory()
	if step == null or obligation == null or inventory == null or barn == null:
		_require(false, claim, "WorkForHire has no WorkStep under it, has no standing obligation, or an Inventory is missing somewhere")
		return

	inventory.take(&"grain", inventory.get_count(&"grain"))
	barn.take(&"grain", barn.get_count(&"grain"))

	_stand_at(zoogs, fields)
	var worked_ticks := 400 # 4.0 hours at 2.5 grain/hour = exactly 10 whole grain
	for tick in worked_ticks:
		clock.advance(TICK_HOURS)
		step.advance(zoogs, TICK_HOURS)

	_require(inventory.get_count(&"grain") == 3, claim,
		"a 0.35 share of 10 grain, paid out one completed grain at a time (hand-traced above), should leave Zoogs holding 3 and he holds %d" % inventory.get_count(&"grain"))
	_require(barn.get_count(&"grain") == 7, claim,
		"the owner's part of the same 10 grain should leave the barn holding 7 and it holds %d" % barn.get_count(&"grain"))
	var total := inventory.get_count(&"grain") + barn.get_count(&"grain")
	_require(total == 10, claim,
		"sack (%d) plus barn (%d) should conserve the full 10 grain made between them and instead totals %d" % [
			inventory.get_count(&"grain"), barn.get_count(&"grain"), total])

	world.queue_free()


# --- Assertion 57: unowned land pays the worker whole ------------------------------

# THE OTHER SIDE OF THE BRANCH IN _pay_out. The Fields' one authored Plot is
# owned (Marle), so an unowned station has to be manufactured for this check
# — done by clearing owned_by on THIS check's own private scene copy only
# (_add_a_disabled_game_scene gives every check its own instance), never on
# the source .tscn, so nothing else in the probe or the shipped game ever
# sees an unowned Plot. WorkTheField, not WorkForHire, because an unowned
# station has no obligation to speak of — the plain library action Decision
# 29's header names as what keeps meaningful once WorkForHire exists.
func _check_unowned_land_worker_keeps_all_of_it() -> void:
	var claim := "57 — a man working unowned land keeps all of it"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var fields := world.get_node_or_null("Town/Fields") as Place
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	if clock == null or zoogs == null or fields == null or plot == null:
		_require(false, claim, "the scene came up without a Clock, a Zoogs, the Fields and the Plot")
		return

	plot.owned_by = null

	var work_scene: PackedScene = load("res://game/actions/work_the_field.tscn") as PackedScene
	if work_scene == null:
		_require(false, claim, "could not load res://game/actions/work_the_field.tscn")
		return
	var work_action := zoogs.brain.learn(work_scene) as WorkTheField
	if work_action == null:
		_require(false, claim, "Brain.learn() did not hand back a WorkTheField")
		return
	var step := work_action.step as WorkStep
	var inventory := zoogs.get_inventory()
	var barn := fields.get_inventory()
	if step == null or inventory == null or barn == null:
		_require(false, claim, "WorkTheField has no WorkStep under it, Zoogs has no Inventory, or the Fields has none")
		return

	inventory.take(&"grain", inventory.get_count(&"grain"))
	barn.take(&"grain", barn.get_count(&"grain"))

	_stand_at(zoogs, fields)
	var worked_ticks := 40 # 0.4 hours at 2.5 grain/hour = exactly 1 whole grain
	for tick in worked_ticks:
		clock.advance(TICK_HOURS)
		step.advance(zoogs, TICK_HOURS)

	_require(inventory.get_count(&"grain") == 1, claim,
		"on unowned land Zoogs should keep the whole grain he raised and he holds %d" % inventory.get_count(&"grain"))
	_require(barn.get_count(&"grain") == 0, claim,
		"on unowned land nothing should land in the fields' barn and it holds %d" % barn.get_count(&"grain"))

	world.queue_free()


# --- Assertion 58: the loop closes -------------------------------------------------

# THE HEADLINE CLAIM OF THIS REPAIR. Work → grain → bread → eat has never
# fired once in this project (Decision 29's own six-day measurement: every
# man ended every day holding zero grain, so MakeBread's gate never opened).
# Holding exactly grain_per_loaf — no margin — is deliberate: it is the
# smallest amount that could ever trigger a bake, so if the sizing in this
# rung's header is wrong in the stingy direction, THIS is where it is found.
func _check_a_man_holds_three_grain_and_bakes() -> void:
	var claim := "58 — a man holds three grain and bakes"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var population := world.get_node_or_null("Population") as Population
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var make_bread := world.get_node_or_null("Population/Zoogs/Brain/MakeBread") as MakeBread
	if clock == null or population == null or zoogs == null or make_bread == null:
		_require(false, claim, "the scene came up without a Clock, a Population, a Zoogs and Zoogs' MakeBread")
		return
	var step := make_bread.step as MakeBreadStep
	var inventory := zoogs.get_inventory()
	if step == null or inventory == null:
		_require(false, claim, "MakeBread has no MakeBreadStep under it, or Zoogs has no Inventory")
		return

	clock.advance(13.0)
	zoogs.stats.set_stat(&"adenosine", 30.0)
	zoogs.stats.set_stat(&"hunger", 0.0)
	inventory.take(&"bread", inventory.get_count(&"bread"))
	inventory.take(&"grain", inventory.get_count(&"grain"))
	inventory.add(&"grain", step.grain_per_loaf) # THE MINIMUM — exactly enough for one loaf

	population.think_for_everyone(TICK_HOURS)

	_require(inventory.get_count(&"grain") == 0, claim,
		"holding exactly grain_per_loaf grain with an empty larder, Zoogs should have baked it away and he holds %d" % inventory.get_count(&"grain"))
	_require(inventory.get_count(&"bread") == 1, claim,
		"a completed bake should leave exactly one loaf in Zoogs' sack and he holds %d" % inventory.get_count(&"bread"))

	world.queue_free()


# --- Assertion 45: twenty beds, twenty-one sleepers -------------------------------

# The rung's whole point, made mechanical: a bed to fail to find did not
# exist before this rung, and now it does. NIGHT, so nobody's daylight term
# is fighting sleep — and the authored trio (Zoogs, Hobb, Marle) start with
# adenosine ~0 and stay well under Sleep's pull for the whole short pump
# below, which is what keeps them out of the race and leaves this claim
# entirely about the 21 spares.
func _check_twenty_one_sleepers_leave_one_standing() -> void:
	var claim := "45 — twenty-one sleepers at a twenty-bed Inn leave exactly one man standing"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var population := world.get_node_or_null("Population") as Population
	var inn := world.get_node_or_null("Town/Inn") as Place
	if clock == null or population == null or inn == null:
		_require(false, claim, "the scene came up without a Clock, a Population and an Inn")
		return

	clock.advance(1.0)

	var spares: Array[Person] = []
	for i in 21:
		var spare := _add_a_person(population, "Sleeper%d" % i)
		if spare == null:
			_require(false, claim, "could not instance %s" % PERSON_SCENE_PATH)
			return
		_stand_at(spare, inn)
		spare.stats.set_stat(&"adenosine", 90.0)
		spares.append(spare)

	for tick in 5:
		clock.advance(TICK_HOURS)
		population.think_for_everyone(TICK_HOURS)

	var asleep_count := 0
	var awake_spare: Person = null
	for spare in spares:
		if spare.brain.is_awake():
			awake_spare = spare
		else:
			asleep_count += 1
	_require(asleep_count == 20, claim,
		"twenty beds and twenty-one sleepers should leave exactly 20 asleep and %d are" % asleep_count)
	_require(awake_spare != null, claim,
		"twenty beds and twenty-one sleepers should leave exactly one man standing and none is")

	# TWENTY DISTINCT BEDS, not twenty claims piled on the same one. Walked
	# off the Inn's own children rather than assumed — a check states the
	# world it wants, the same discipline claim 33 paid for.
	var beds: Array[Workstation] = []
	for child in inn.get_children():
		var station := child as Workstation
		if station != null and station.work_name == &"sleeping":
			beds.append(station)
	_require(beds.size() == 20, claim,
		"expected 20 beds under the Inn and found %d — the scene is not what this claim thinks it is" % beds.size())

	var holders := {}
	for bed in beds:
		if bed.claimed_by != null:
			holders[bed.claimed_by] = true
	_require(holders.size() == 20, claim,
		"20 sleepers should hold 20 DISTINCT beds and only %d distinct holders were found — somebody is sharing" % holders.size())

	if awake_spare != null:
		var sleep_action := awake_spare.get_node_or_null("Brain/Sleep") as Sleep
		var score: Variant = null
		if sleep_action != null:
			score = awake_spare.brain.get_last_scores().get(sleep_action.name)
		var off_the_ballot := false
		if score is float:
			var score_value: float = score
			off_the_ballot = is_nan(score_value)
		_require(sleep_action != null and off_the_ballot, claim,
			"the standing man's Sleep score reads %s — every bed visibly taken must take Sleep OFF the ballot (NAN), not merely outscore it" % str(score))

	world.queue_free()


# --- Assertion 46: renew-on-use across a sleeping man's midnight ------------------

# THE REAL PATH — through Population, never the step driven by hand — because
# this claim exists to prove the renewal comes from Rest's OWN claim-per-tick,
# not from anything the harness is doing for it. This is the first claim in
# the whole probe to carry a claim() across a day boundary where the claimant
# is ASLEEP and could not have chosen to renew it — every earlier claim()
# caller works inside a waking man's day. See rest.gd's header.
func _check_a_sleeper_holds_his_bed_across_midnight() -> void:
	var claim := "46 — a sleeper holds his bed across a day boundary passing mid-sleep"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var population := world.get_node_or_null("Population") as Population
	var inn := world.get_node_or_null("Town/Inn") as Place
	if clock == null or population == null or inn == null:
		_require(false, claim, "the scene came up without a Clock, a Population and an Inn")
		return

	var spare := _add_a_person(population, "Sleeper")
	if spare == null:
		_require(false, claim, "could not instance %s" % PERSON_SCENE_PATH)
		return
	_stand_at(spare, inn)
	clock.advance(23.5)
	spare.stats.set_stat(&"adenosine", 90.0)

	for tick in 100:
		clock.advance(TICK_HOURS)
		population.think_for_everyone(TICK_HOURS)

	_require(clock.day() == 1, claim,
		"100 ticks of %.2f hours from 23:30 should cross midnight and landed on day %d instead" % [TICK_HOURS, clock.day()])
	_require(not spare.brain.is_awake(), claim,
		"a man put down at 23:30 with adenosine 90 should still be asleep an hour later")

	var bed: Workstation = null
	for child in inn.get_children():
		var station := child as Workstation
		if station != null and station.claimed_by == spare:
			bed = station
			break
	_require(bed != null, claim,
		"no bed under the Inn reads claimed by the sleeping spare at all")
	if bed != null:
		# THE RE-STAMP IS THE WHOLE MECHANISM: dawn passed under him and
		# nothing expired because claim() ran again on every tick Rest
		# advanced — the identical proof claim 14 already gave WorkStep.
		_require(bed.claimed_on_day == 1, claim,
			"the bed was claimed across midnight and its stamp reads day %d, not day 1 — renew-on-use did not fire" % bed.claimed_on_day)
		var stranger := _add_a_person(population, "Stranger")
		_require(stranger != null and not bed.is_free_for(stranger), claim,
			"a bed held by a sleeping man read free for somebody else")

	world.queue_free()


# --- Assertion 47: an abandoned bed lapses, the same rule on a new station type ---

# Claim 15's rule, on the station type it was actually shaped for: nobody
# renews, so nothing keeps a bed claim alive past the day it was made on. No
# think_for_everyone here, and none needed — the claim expires where it lies
# the moment somebody asks, exactly as claim 15 already proved for a plot.
func _check_an_abandoned_bed_lapses_at_the_boundary() -> void:
	var claim := "47 — an abandoned bed lapses at the day boundary"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var population := world.get_node_or_null("Population") as Population
	var inn := world.get_node_or_null("Town/Inn") as Place
	if clock == null or population == null or inn == null:
		_require(false, claim, "the scene came up without a Clock, a Population and an Inn")
		return

	var sleeper := _add_a_person(population, "Sleeper")
	var another := _add_a_person(population, "Another")
	if sleeper == null or another == null:
		_require(false, claim, "could not instance %s" % PERSON_SCENE_PATH)
		return
	_stand_at(sleeper, inn)
	_stand_at(another, inn)

	var bed: Workstation = null
	for child in inn.get_children():
		var station := child as Workstation
		if station != null and station.work_name == &"sleeping":
			bed = station
			break
	if bed == null:
		_require(false, claim, "no bed at all under the Inn")
		return

	clock.advance(10.0)
	_require(bed.claim(sleeper), claim, "Sleeper, standing at the Inn, could not claim a bed at 10:00")
	_require(not bed.is_free_for(another), claim, "the bed read free for Another the moment Sleeper held it")

	clock.advance(15.0)
	_require(bed.is_free_for(another), claim,
		"an abandoned bed still reads held on day %d, though nothing has touched it since it was claimed" % clock.day())

	world.queue_free()


# --- Assertion 48: the bootstrap — a lonely man goes where company belongs -------

# THE CLAIM THAT PROVES THE BOOTSTRAP HOLE IS ACTUALLY CLOSED, AND THAT THE
# EMPTY VENUE ACTUALLY RESOLVES. An earlier draft of Socialise made "a place
# currently holding somebody else" the candidate, and that model can never
# put a first man anywhere: an empty venue is never a candidate, so nobody
# ever sets off toward it, so it never holds anybody, forever. This claim
# exercises exactly the case that shape could not survive — the Tavern starts
# EMPTY, nobody pinned there — and checks all three things the fix has to
# deliver: the venue draws him before anyone is in it, being there ALONE
# still moves the gap (at the thinner change_of_scene_per_hour, not zero —
# zero is the earlier bug this rung measured and stopped on), and once
# there's actual company the gap closes FASTEST, at company_per_hour.
#
# Made mechanical the same way claim 21 already made "walk toward what you
# want" mechanical for a plot: gap strictly shrinking while in transit,
# arrival within a generous budget. Then TWO further phases rather than one —
# alone at the venue, and then with Marle brought in — each asserting the
# exact per-tick AMOUNT, never merely a direction, the same discipline claim
# 5 already established for adenosine.
func _check_a_lonely_man_goes_where_company_is_to_be_found() -> void:
	var claim := "48 — a lonely man goes where company is to be found, and company feeds the gap fastest"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var population := world.get_node_or_null("Population") as Population
	var marle := world.get_node_or_null("Population/Marle") as Person
	var tavern := world.get_node_or_null("Town/Tavern") as Place
	var fields := world.get_node_or_null("Town/Fields") as Place
	if clock == null or population == null or marle == null or tavern == null or fields == null:
		_require(false, claim, "the scene came up without a Clock, a Population, a Marle, the Tavern and Fields")
		return
	_require(tavern.is_gathering_place, claim,
		"the Tavern does not read as a gathering place — nothing in the header's bootstrap fix applies to it")

	# Daytime, so StayUp's daylight term is somewhere near its peak (up to
	# 87.3) rather than out of the way — company_worth dropped to 90 at this
	# rung specifically so Socialise could no longer outrun Sleep, and that
	# same drop means a middling gap is no longer enough to beat StayUp at
	# noon either. Social is set to the CEILING (100) rather than merely
	# "very lonely", so this claim tests the walk itself rather than
	# accidentally also testing what hour it is: 90 × 1.0² = 90, clear of
	# StayUp's 87.3 peak at any time of day.
	clock.advance(8.0)
	# Marle stays wherever game.tscn authors him (the Inn) for this first
	# half — the Tavern must draw a lonely man toward it with NOBODY there
	# at all, or the bootstrap hole is still open.

	var spare := _add_a_person(population, "Lonesome")
	if spare == null:
		_require(false, claim, "could not instance %s" % PERSON_SCENE_PATH)
		return
	_stand_at(spare, fields)
	spare.stats.set_stat(&"social", 100.0)

	var arrived := false
	# Fields to the Tavern is about 9 world-minutes at speed 115 — a generous
	# budget past that.
	for tick in 100:
		if spare.get_current_place() == tavern:
			arrived = true
			break

		var gap_before: float = spare.global_position.distance_to(tavern.global_position)
		clock.advance(TICK_HOURS)
		population.think_for_everyone(TICK_HOURS)
		var gap_after: float = spare.global_position.distance_to(tavern.global_position)

		_require(spare.stats.get_stat(&"social") >= 0.0, claim,
			"social read below zero mid-transit: %.4f" % spare.stats.get_stat(&"social"))

		if spare.get_current_place() != tavern:
			_require(gap_after < gap_before, claim,
				"walking toward the empty tavern and the gap to it did not shrink, %.4f → %.4f" % [gap_before, gap_after])

	_require(arrived, claim,
		"Lonesome never reached the empty Tavern inside 100 ticks — an empty gathering place must still draw him")
	if not arrived:
		world.queue_free()
		return

	var mingle := spare.get_node_or_null("Brain/Socialise/Mingle") as SocialiseStep
	_require(mingle != null, claim, "Lonesome has no SocialiseStep at Brain/Socialise/Mingle")
	if mingle == null:
		world.queue_free()
		return

	# HALF ONE: ALONE AT THE VENUE. The thinner change_of_scene_per_hour rate,
	# never company_per_hour and never zero — zero is the earlier bug this
	# rung measured and stopped on: a wait that pays nothing down is a
	# standing bid that never resolves. The amount is asserted exactly, the
	# change-of-scene rate minus the upkeep still running underneath it.
	var social_before_waiting: float = spare.stats.get_stat(&"social")
	clock.advance(TICK_HOURS)
	population.think_for_everyone(TICK_HOURS)
	var social_after_waiting: float = spare.stats.get_stat(&"social")
	var expected_alone: float = -(mingle.change_of_scene_per_hour - spare.brain.get_social_accumulation()) * TICK_HOURS
	_require(absf((social_after_waiting - social_before_waiting) - expected_alone) < 0.001, claim,
		"one tick alone at the tavern should move social by exactly %.5f (the change-of-scene rate minus the upkeep still running) and moved it by %.5f instead" % [
			expected_alone, social_after_waiting - social_before_waiting])

	# HALF TWO: MARLE ARRIVES. Now the FAST rate applies — company_per_hour,
	# not the thinner one above. Company pulls social down, upkeep is still
	# pulling it up on the very same tick, so the net move is the two rates
	# against each other.
	_stand_at(marle, tavern)
	var social_before: float = spare.stats.get_stat(&"social")
	clock.advance(TICK_HOURS)
	population.think_for_everyone(TICK_HOURS)
	var social_after: float = spare.stats.get_stat(&"social")

	var expected_move: float = -(mingle.company_per_hour - spare.brain.get_social_accumulation()) * TICK_HOURS
	_require(absf((social_after - social_before) - expected_move) < 0.001, claim,
		"one tick with Marle now present should move social by exactly %.5f (company minus the upkeep still running) and moved it by %.5f instead" % [
			expected_move, social_after - social_before])

	_require(social_after >= 0.0, claim,
		"social read below zero once company arrived: %.4f" % social_after)

	world.queue_free()


# --- Assertion 49: social is a want like the other two -----------------------------

# The mirror of claim 31 (hunger) and, before it, claim 5 (adenosine) — same
# shape, same discipline: on a FRESH world, one hour must move social by
# exactly its own accumulation rate. AMOUNT, not direction, because a rate
# applied per tick instead of per world hour still moves the number the right
# way, just by the wrong amount, and only an exact check catches that.
#
# THE SLEEPING HALF IS WHERE THIS CLAIM HAS TEETH, and it is here because the
# waking half was break-tested and caught nothing: wrapping the upkeep line in
# `if is_awake()` left every claim in the probe green. Nothing about sleeping
# answers loneliness — only company does — so the line is deliberately
# unbranched, and this is the only assertion in the file that can tell.
func _check_social_rises_for_an_idle_man() -> void:
	var claim := "49 — social rises for a man doing nothing at all, awake OR asleep, by exactly one hour's worth in one hour"
	var world := _add_a_disabled_game_scene()
	var person := world.get_node_or_null("Population/Zoogs") as Person
	var population := world.get_node_or_null("Population") as Population
	var inn := world.get_node_or_null("Town/Inn") as Place
	if person == null or population == null or inn == null:
		_require(false, claim, "a second game scene came up without a Population, a Zoogs and an Inn")
		return

	var lonely_before: float = person.stats.get_stat(&"social")
	population.think_for_everyone(1.0)
	var moved: float = person.stats.get_stat(&"social") - lonely_before
	var expected: float = person.brain.get_social_accumulation()

	_require(absf(moved - expected) < 0.001, claim,
		"awake, one hour moved social by %.4f where one hour's worth is %.4f" % [moved, expected])

	_require_the_stat_rises_while_he_sleeps(&"social", claim, world, population, inn)

	world.queue_free()


# --- Assertion 50: the day keeps its shape ------------------------------------------

# THE FALSIFIABLE ANTI-HERD CLAIM. Adding a want that can pull a man across
# town to a crowd is exactly the kind of change that could quietly swallow the
# day it was added to — a town absorbed into one endless conversation stops
# claiming the plot, and that failure would not announce itself; the day's
# other business would simply stop happening while every graph still looked
# busy. This asks the only two questions that would catch it: did the plot
# still get claimed, and did anybody still socialise.
#
# DAY 0 IS EXCLUDED ON PURPOSE. Everybody starts the run at the same cold
# midnight with adenosine and social both near zero, so day 0 is a shared
# transient rather than the settled town — the same reasoning claim 45 already
# gives for standing its farmers well clear of a fair fight. Days 1 and 2 are
# where the claim actually has teeth.
#
# ONLY THE TAVERN IS A GATHERING PLACE (game.tscn marks nothing else), so any
# Socialise observed here is, mechanically, a visit to it — chosen the same
# way every other action is, never scripted to happen. If three pumped days
# never send anybody there, that is a real finding about the ballot, not a
# harness bug, and it gets reported rather than tuned away here.
func _check_the_day_keeps_its_shape() -> void:
	var claim := "50 — the day keeps its shape: work happens and company happens, every day"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var population := world.get_node_or_null("Population") as Population
	var plot := world.get_node_or_null("Town/Fields/Plot") as Workstation
	if clock == null or population == null or plot == null:
		_require(false, claim, "the scene came up without a Clock, a Population and the Plot")
		return

	var people := population.get_people()
	var plot_claimed_on_day := {}
	var socialising_on_day := {}

	var tick_count := int(round(3.0 * HOURS_IN_A_DAY / TICK_HOURS))
	for tick in tick_count:
		clock.advance(TICK_HOURS)
		population.think_for_everyone(TICK_HOURS)
		var today := clock.day()

		if plot.claimed_on_day == today:
			plot_claimed_on_day[today] = true

		for person in people:
			if not person.brain.is_awake():
				continue
			if person.brain.current_action is Socialise:
				socialising_on_day[today] = true

	for day_index in [1, 2]:
		_require(plot_claimed_on_day.get(day_index, false), claim,
			"the Plot was never observed claimed on day %d — a town absorbed into one endless conversation stops claiming the plot" % day_index)
		_require(socialising_on_day.get(day_index, false), claim,
			"nobody was observed socialising while awake on day %d — a dead social stat never socialises at all" % day_index)

	world.queue_free()


# --- Assertions 59-66: Gate 1 — a steered body in the town ------------------------

# 59 — NULL IS A REAL ANSWER, and stands for "standing there". A steered body
# with nothing chosen still pays the same upkeep every other body pays —
# Brain._update_body never asks who is steering, only what happened this
# tick — so one hour of choosing nothing has to move all three drives by
# exactly one hour's worth, the same AMOUNT-not-direction discipline claims 5,
# 31 and 49 already use for the same reason: a rate applied per tick instead
# of per world hour still moves the number the right way, just by the wrong
# amount.
func _check_a_steered_body_with_no_verb_chosen_still_tires_hungers_and_grows_lonely() -> void:
	var claim := "59 — a steered body with no verb chosen still tires, hungers and grows lonely"
	var world := _add_a_disabled_game_scene()
	var player := world.get_node_or_null("Population/Player") as Person
	var population := world.get_node_or_null("Population") as Population
	if player == null or population == null:
		_require(false, claim, "the scene came up without a Population and a Player under it")
		return

	var tired_before: float = player.stats.get_stat(&"adenosine")
	var hungry_before: float = player.stats.get_stat(&"hunger")
	var lonely_before: float = player.stats.get_stat(&"social")

	population.think_for_everyone(1.0)

	_require(player.brain.current_action == null, claim,
		"a player brain with nothing chosen picked \"%s\" on its own" % [
			String(player.brain.current_action.name) if player.brain.current_action != null else "nothing"])

	var moved_adenosine: float = player.stats.get_stat(&"adenosine") - tired_before
	var expected_adenosine: float = player.brain.get_adenosine_accumulation()
	_require(absf(moved_adenosine - expected_adenosine) < 0.001, claim,
		"standing there for one hour moved adenosine by %.4f where one hour's worth is %.4f" % [
			moved_adenosine, expected_adenosine])

	var moved_hunger: float = player.stats.get_stat(&"hunger") - hungry_before
	var expected_hunger: float = player.brain.get_hunger_accumulation()
	_require(absf(moved_hunger - expected_hunger) < 0.001, claim,
		"standing there for one hour moved hunger by %.4f where one hour's worth is %.4f" % [
			moved_hunger, expected_hunger])

	var moved_social: float = player.stats.get_stat(&"social") - lonely_before
	var expected_social: float = player.brain.get_social_accumulation()
	_require(absf(moved_social - expected_social) < 0.001, claim,
		"standing there for one hour moved social by %.4f where one hour's worth is %.4f" % [
			moved_social, expected_social])

	world.queue_free()


# 60 — Assert against the engine's OWN OUTPUT, never against an expected set
# of names, so teaching the player a new Action cannot make this claim stale.
# The identity-and-order comparison is VerbList's own claim about itself (see
# get_drawn_actions' header); this is what proves it, driven from outside.
func _check_the_verb_list_on_screen_is_exactly_the_open_ballot() -> void:
	var claim := "60 — the verb list on screen is exactly the open ballot, and never a list of names"
	var world := _add_a_disabled_game_scene()
	var player := world.get_node_or_null("Population/Player") as Person
	var population := world.get_node_or_null("Population") as Population
	var verb_list := world.get_node_or_null("Screen/VerbList") as VerbList
	if player == null or population == null or verb_list == null:
		_require(false, claim, "the scene came up without a Population, a Player and Screen/VerbList")
		return
	var brain := player.brain as PlayerBrain
	if brain == null:
		_require(false, claim, "the Player's Brain is not a PlayerBrain — player.tscn's script override did not take")
		return

	population.think_for_everyone(TICK_HOURS)
	verb_list._process(0.0)
	_require(_same_action_list(verb_list.get_drawn_actions(), brain.get_open_actions()), claim,
		"the drawn list disagrees with the open ballot, by identity or by order, before anything about the ballot changed")
	_require_one_button_per_drawn_action(verb_list, claim)

	var size_before := verb_list.get_drawn_actions().size()

	# Change the world so the ballot itself changes — a loaf makes Eat a
	# candidate where it was not one before. If this file only ever asserted
	# equality against a ballot that never moves, a list that never rebuilds
	# would pass it for free; the size comparison below is what rules that out.
	player.get_inventory().add(&"bread", 1)
	population.think_for_everyone(TICK_HOURS)
	verb_list._process(0.0)
	_require(_same_action_list(verb_list.get_drawn_actions(), brain.get_open_actions()), claim,
		"the drawn list disagrees with the open ballot after the ballot changed")
	_require(verb_list.get_drawn_actions().size() != size_before, claim,
		"giving the player a loaf did not change the size of his drawn ballot (%d before, %d after) — this claim cannot tell a list that redraws from one that never does" % [
			size_before, verb_list.get_drawn_actions().size()])

	world.queue_free()


# get_drawn_actions() is VerbList's own bookkeeping copy of the list it was
# HANDED, not a read of what it actually BUILT — so a loop in _rebuild_rows
# that silently drops a row would leave get_drawn_actions() none the wiser.
# This is the check with teeth for exactly that: it counts the real Button
# nodes in the tree, through Godot's own public Node API, never VerbList's
# private column. A count that disagrees means the panel promised something
# it did not put on screen.
#
# CALLED ONLY ONCE, ON THE FIRST BUILD. A second rebuild in the same
# hand-pumped tick would call queue_free() on the old buttons, and queued
# deletion does not land until end of frame — this harness never yields one
# — so a later count would double up stale rows with fresh ones and read
# wrong for a reason that has nothing to do with the row-building loop under
# test. The specified break drops a row on EVERY rebuild, including the very
# first, so checking only the first is not a narrower claim.
func _require_one_button_per_drawn_action(verb_list: VerbList, claim: String) -> void:
	var buttons := verb_list.find_children("*", "Button", true, false)
	_require(buttons.size() == verb_list.get_drawn_actions().size(), claim,
		"get_drawn_actions() reports %d actions but the panel actually holds %d Button nodes — the drawn list must match what was actually built, not merely what it was handed" % [
			verb_list.get_drawn_actions().size(), buttons.size()])


# Identity AND order, the same two-part comparison VerbList._same_ballot uses
# on itself — this file is checking that promise from outside, so it has to
# ask the same question of it.
func _same_action_list(left: Array[Action], right: Array[Action]) -> bool:
	if left.size() != right.size():
		return false
	for i in left.size():
		if left[i] != right[i]:
			return false
	return true


# 61 — asserted in BOTH states of a gate that genuinely branches: shut without
# bread, open with it. A claim asserted only in the shut state proves nothing
# about the gate being asked at all — an always-closed gate and a genuinely
# asked one look identical from that side alone.
func _check_a_gate_that_says_no_never_reaches_the_players_ballot() -> void:
	var claim := "61 — an action whose own gate says no never reaches the player's ballot"
	var world := _add_a_disabled_game_scene()
	var player := world.get_node_or_null("Population/Player") as Person
	var population := world.get_node_or_null("Population") as Population
	if player == null or population == null:
		_require(false, claim, "the scene came up without a Population and a Player under it")
		return

	var eat: Eat = null
	for action in player.brain.get_known_actions():
		if action is Eat:
			eat = action
			break
	if eat == null:
		_require(false, claim, "the Player has no Eat action among what he knows — Eat must be on every person by composition")
		return

	# THE SHUT STATE — the Player is authored with no bread at all.
	population.think_for_everyone(TICK_HOURS)
	_require(not player.brain.get_open_actions().has(eat), claim,
		"with no bread, Eat is still on the player's open ballot")
	_require(not eat.is_available_to(player), claim,
		"with no bread, Eat's own gate reads available")

	# THE OPEN STATE — the same man, the same Action node, now holding a loaf.
	player.get_inventory().add(&"bread", 1)
	population.think_for_everyone(TICK_HOURS)
	_require(player.brain.get_open_actions().has(eat), claim,
		"with a loaf in hand, Eat is still off the player's open ballot")
	_require(eat.is_available_to(player), claim,
		"with a loaf in hand, Eat's own gate still reads unavailable")

	world.queue_free()


# 62 — THREE HALVES, because "choosing a verb runs that action's step, and
# choosing nothing runs nothing" is really three separate claims about the
# same fork: work performed where he stands, none performed while walking
# there, and none performed while standing on a withdrawn bid.
func _check_choosing_a_verb_runs_its_step_and_choosing_nothing_runs_nothing() -> void:
	var claim := "62 — choosing a verb runs that action's step, and choosing nothing runs nothing"

	# AT THE PLOT. 40 ticks of 0.01 hours at 2.5 grain/hour is exactly 1
	# whole grain, and CommonPlot is unowned so he keeps all of it — see
	# work_step.gd's _pay_out. Started at hour 0, where StayUp (47.3) still
	# beats WorkForHire (43) for both Zoogs and Hobb, so neither of them sets
	# off toward the grain fields' OWNED plot during this window — which is
	# what makes "the fields' barn is untouched" a claim about THIS work and
	# not theirs.
	var world_a := _add_a_disabled_game_scene()
	var player_a := world_a.get_node_or_null("Population/Player") as Person
	var clock_a := world_a.get_node_or_null("Clock") as Clock
	var population_a := world_a.get_node_or_null("Population") as Population
	var common_field_a := world_a.get_node_or_null("Town/CommonField") as Place
	var fields_a := world_a.get_node_or_null("Town/Fields") as Place
	if player_a == null or clock_a == null or population_a == null or common_field_a == null or fields_a == null:
		_require(false, claim, "the first world came up without a Player, a Clock, a Population, the CommonField and the Fields")
		return
	var brain_a := player_a.brain as PlayerBrain
	if brain_a == null:
		_require(false, claim, "the Player's Brain is not a PlayerBrain")
		return
	var work_a: WorkTheField = null
	for action in player_a.brain.get_known_actions():
		if action is WorkTheField:
			work_a = action
			break
	if work_a == null:
		_require(false, claim, "the Player has no WorkTheField among what he knows")
		return

	_stand_at(player_a, common_field_a)
	player_a.get_inventory().take(&"grain", player_a.get_inventory().get_count(&"grain"))
	brain_a.choose_verb(work_a)

	for tick in 40:
		clock_a.advance(TICK_HOURS)
		population_a.think_for_everyone(TICK_HOURS)

	_require(player_a.get_inventory().get_count(&"grain") == 1, claim,
		"40 ticks worked at the common field with Work chosen should leave the Player holding 1 grain and he holds %d" % player_a.get_inventory().get_count(&"grain"))
	_require(fields_a.get_inventory().get_count(&"grain") == 0, claim,
		"working the unowned common field should never touch the grain fields' barn, and it holds %d" % fields_a.get_inventory().get_count(&"grain"))
	world_a.queue_free()

	# ON THE ROAD. Mirrors claim 26's shape and its point exactly — a walking
	# man produces nothing — for a hand-driven body instead of a scored one.
	# The Fields' plot is owned by Marle and the Player has no obligation
	# there, so it is never his candidate at all; the common field's unowned
	# plot is the only station a bare WorkTheField will ever walk him toward.
	var world_b := _add_a_disabled_game_scene()
	var player_b := world_b.get_node_or_null("Population/Player") as Person
	var population_b := world_b.get_node_or_null("Population") as Population
	var inn_b := world_b.get_node_or_null("Town/Inn") as Place
	var common_field_b := world_b.get_node_or_null("Town/CommonField") as Place
	if player_b == null or population_b == null or inn_b == null or common_field_b == null:
		_require(false, claim, "the second world came up without a Player, a Population, an Inn and the CommonField")
		return
	var brain_b := player_b.brain as PlayerBrain
	if brain_b == null:
		_require(false, claim, "the Player's Brain is not a PlayerBrain")
		return
	var work_b: WorkTheField = null
	for action in player_b.brain.get_known_actions():
		if action is WorkTheField:
			work_b = action
			break
	if work_b == null:
		_require(false, claim, "the Player has no WorkTheField among what he knows")
		return

	_stand_at(player_b, inn_b)
	player_b.get_inventory().take(&"grain", player_b.get_inventory().get_count(&"grain"))
	brain_b.choose_verb(work_b)

	var arrived := false
	for tick in 200:
		if player_b.get_current_place() == common_field_b:
			arrived = true
			break
		_require(player_b.get_inventory().get_count(&"grain") == 0, claim,
			"still on the road to the common field and already carrying %d grain — the yield is being paid for walking" % player_b.get_inventory().get_count(&"grain"))
		population_b.think_for_everyone(TICK_HOURS)
	_require(arrived, claim,
		"the Player never reached the common field in 200 ticks — the walk half of this claim proved nothing")
	world_b.queue_free()

	# CHOOSING NOTHING. Standing on the plot itself, with the bid withdrawn —
	# grain must not move on its own.
	var world_c := _add_a_disabled_game_scene()
	var player_c := world_c.get_node_or_null("Population/Player") as Person
	var population_c := world_c.get_node_or_null("Population") as Population
	var common_field_c := world_c.get_node_or_null("Town/CommonField") as Place
	if player_c == null or population_c == null or common_field_c == null:
		_require(false, claim, "the third world came up without a Player, a Population and the CommonField")
		return
	var brain_c := player_c.brain as PlayerBrain
	if brain_c == null:
		_require(false, claim, "the Player's Brain is not a PlayerBrain")
		return

	_stand_at(player_c, common_field_c)
	player_c.get_inventory().take(&"grain", player_c.get_inventory().get_count(&"grain"))
	brain_c.stop_doing_anything()

	for tick in 10:
		population_c.think_for_everyone(TICK_HOURS)
		_require(player_c.brain.current_action == null, claim,
			"choosing nothing still ran an action — current_action reads \"%s\"" % [
				String(player_c.brain.current_action.name) if player_c.brain.current_action != null else "nothing"])
		_require(player_c.get_inventory().get_count(&"grain") == 0, claim,
			"choosing nothing still produced %d grain" % player_c.get_inventory().get_count(&"grain"))

	world_c.queue_free()


# 63 — THE CLAIM WHOSE WHOLE POINT IS A BRANCH, so it has to be asserted in
# the state where holding and dropping give different answers: dropped, then
# the world reopens what it shut, and a held verb would resume on its own if
# anything here remembered the plan instead of re-asking every tick.
func _check_a_verb_dropped_from_under_him_is_dropped_not_held() -> void:
	var claim := "63 — a verb dropped from under him is dropped, not held"
	var world := _add_a_disabled_game_scene()
	var player := world.get_node_or_null("Population/Player") as Person
	var population := world.get_node_or_null("Population") as Population
	var clock := world.get_node_or_null("Clock") as Clock
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	var common_field := world.get_node_or_null("Town/CommonField") as Place
	var common_plot := world.get_node_or_null("Town/CommonField/CommonPlot") as Workstation
	if player == null or population == null or clock == null or zoogs == null or common_field == null or common_plot == null:
		_require(false, claim, "the scene came up without a Player, a Population, a Clock, a Zoogs, the CommonField and the CommonPlot")
		return
	var brain := player.brain as PlayerBrain
	if brain == null:
		_require(false, claim, "the Player's Brain is not a PlayerBrain")
		return
	var work: WorkTheField = null
	for action in player.brain.get_known_actions():
		if action is WorkTheField:
			work = action
			break
	if work == null:
		_require(false, claim, "the Player has no WorkTheField among what he knows")
		return

	_stand_at(player, common_field)
	brain.choose_verb(work)
	population.think_for_everyone(TICK_HOURS)
	_require(brain.get_chosen_verb() == work, claim,
		"choosing Work and pumping a tick left get_chosen_verb() reading something else")
	_require(player.brain.current_action == work, claim,
		"choosing Work and pumping a tick left current_action reading something else")

	# SHUT FROM THE WORLD, NOT FROM HIM. The grain fields' own plot is owned
	# by Marle and the Player carries no obligation, so it was never his
	# candidate; claiming the common field's plot away leaves him with no
	# candidate at all — a gate shutting under him, not a choice he made.
	common_plot.claimed_by = zoogs
	common_plot.claimed_on_day = clock.day()
	population.think_for_everyone(TICK_HOURS)
	_require(brain.get_chosen_verb() == null, claim,
		"the common plot was claimed out from under him and get_chosen_verb() still reads Work")
	_require(player.brain.current_action == null, claim,
		"the common plot was claimed out from under him and current_action still reads Work")

	# REOPENED — AND THIS IS THE CLAIM. A held verb would resume here on its
	# own; nothing does, because nothing here was ever suspended and restored.
	common_plot.claimed_by = null
	population.think_for_everyone(TICK_HOURS)
	_require(brain.get_chosen_verb() == null, claim,
		"the plot reopened and get_chosen_verb() reads Work again on its own — a dropped verb must not resume itself")
	_require(player.brain.current_action == null, claim,
		"the plot reopened and current_action reads Work again on its own — a dropped verb must not resume itself")

	# NOT PERMANENT DAMAGE — chosen again, it runs.
	brain.choose_verb(work)
	population.think_for_everyone(TICK_HOURS)
	_require(brain.get_chosen_verb() == work, claim,
		"choosing Work again after the drop did not stick")
	_require(player.brain.current_action == work, claim,
		"choosing Work again after the drop did not make it his current action")

	world.queue_free()


# 64 — BOTH HALVES MATTER, and the second is the one with teeth: the fork
# Gate 1 added lives entirely in PlayerBrain.pick_from_the_ballot, and nothing
# about DecisionEngine or Brain.think_and_act changed to make room for it — so
# an ordinary body on the exact same tick, thought by the exact same
# Population loop, still picks by score.
func _check_the_fork_changed_one_body_not_the_engine() -> void:
	var claim := "64 — the fork changed one body, not the engine: an NPC on the same tick still picks by score"
	var world := _add_a_disabled_game_scene()
	var clock := world.get_node_or_null("Clock") as Clock
	var population := world.get_node_or_null("Population") as Population
	var player := world.get_node_or_null("Population/Player") as Person
	var zoogs := world.get_node_or_null("Population/Zoogs") as Person
	if clock == null or population == null or player == null or zoogs == null:
		_require(false, claim, "the scene came up without a Clock, a Population, a Player and a Zoogs")
		return
	var brain := player.brain as PlayerBrain
	if brain == null:
		_require(false, claim, "the Player's Brain is not a PlayerBrain")
		return
	var work: WorkTheField = null
	for action in player.brain.get_known_actions():
		if action is WorkTheField:
			work = action
			break
	if work == null:
		_require(false, claim, "the Player has no WorkTheField among what he knows")
		return

	clock.advance(2.0) # the small hours — StayUp (49.98) outscores work (47.02) for the Player here
	brain.choose_verb(work)
	population.think_for_everyone(TICK_HOURS)

	# HALF ONE. Read the SCORES RECORDED, never re-asked — re-gating would
	# move Town's pressure counters and make this check write to the world it
	# is measuring.
	var zoogs_scores := zoogs.brain.get_last_scores()
	var zoogs_best := _highest_scoring_open_action(zoogs.brain.get_open_actions(), zoogs_scores)
	_require(zoogs_best != null and zoogs.brain.current_action == zoogs_best, claim,
		"Zoogs' current_action reads \"%s\", not the highest recorded scorer \"%s\"" % [
			String(zoogs.brain.current_action.name) if zoogs.brain.current_action != null else "nothing",
			String(zoogs_best.name) if zoogs_best != null else "nothing"])

	# HALF TWO — the state in which "picks by score" and "picks by hand" give
	# different answers, and without it this claim would pass for free.
	_require(player.brain.current_action == work, claim,
		"the Player chose Work and current_action reads \"%s\" instead" % [
			String(player.brain.current_action.name) if player.brain.current_action != null else "nothing"])
	# THE PLAYER'S OWN BALLOT IS NEVER SCORED AT ALL — Decision 33's "the
	# player's verb menu is get_available() drawn instead of scored" made
	# mechanical: PlayerBrain.pick_from_the_ballot never calls
	# DecisionEngine.get_highest_scoring, so his _last_scores holds nothing
	# but NAN for the actions his own gates shut. There is no recorded number
	# to read here the way half one just did for Zoogs, so this half asks
	# each of his open actions directly — get_utility_score is a pure read
	# with no telemetry side effect, unlike a gate, so asking it fresh here
	# is not the thing claim 64's header warns against.
	var player_best := _highest_scoring_action_by_score(player.brain.get_open_actions(), player)
	_require(player_best != null and player_best != work, claim,
		"at night Work is still the highest scorer on the Player's own ballot — this claim needs a state where the hand-picked verb and the top score disagree")

	world.queue_free()


# The highest-scoring entry among an open ballot, read off a recorded scores
# dictionary rather than re-asked — see claim 64's own header for why
# re-asking would write to the world it is trying to measure. Ties go to
# whichever came first, the same rule DecisionEngine.get_highest_scoring uses.
func _highest_scoring_open_action(open_actions: Array[Action], scores: Dictionary) -> Action:
	var best: Action = null
	var best_score := -INF
	for action in open_actions:
		var score: Variant = scores.get(action.name)
		if not (score is float):
			continue
		var score_value: float = score
		if not is_finite(score_value):
			continue
		if best == null or score_value > best_score:
			best_score = score_value
			best = action
	return best


# The mirror of the helper above for a ballot nobody ever scored — the
# PLAYER's. Same tie rule as DecisionEngine.get_highest_scoring: strict
# greater-than, so the first action encountered keeps the win on a tie.
# get_utility_score is a pure read on every Action in this game (the sum a
# gate is never allowed to be), so asking it directly here writes nothing to
# the world it is describing.
func _highest_scoring_action_by_score(open_actions: Array[Action], person: Person) -> Action:
	var best: Action = null
	var best_score := -INF
	for action in open_actions:
		var score: float = action.get_utility_score(person)
		if not is_finite(score):
			continue
		if best == null or score > best_score:
			best_score = score
			best = action
	return best


# 65 — DECISION 17'S CLAIM, AND THE REASON THE BAND EXISTS. Read
# enters_within/leaves_beyond off the node rather than hard-coding 3.0 and
# 4.5, so retuning them on the tuning board cannot turn this red.
#
# Positions are set BY HAND and pumped through player.think_and_act(0.0)
# directly rather than through Population — this claim is entirely about
# _settle_where_he_stands, and driving one person directly is the same
# isolation technique claims 14, 22 and 46 already use to keep a claim about
# one mechanism from being muddied by everybody else in the world.
func _check_the_players_place_is_a_band_and_does_not_flicker_on_a_boundary() -> void:
	var claim := "65 — the player's place is a band, and it does not flicker on a boundary"
	var world := _add_a_disabled_game_scene()
	var player := world.get_node_or_null("Population/Player") as Person
	var square := world.get_node_or_null("Town/Square") as Place
	if player == null or square == null:
		_require(false, claim, "the scene came up without a Player and Town/Square")
		return
	var brain := player.brain as PlayerBrain
	if brain == null:
		_require(false, claim, "the Player's Brain is not a PlayerBrain")
		return
	# A DIRECTION CLEAR OF EVERY OTHER AUTHORED PLACE ALONG THE WHOLE
	# TRAVERSE, hand-picked against game.tscn's own layout — Fields, Inn,
	# Tavern and CommonField all stay well clear of this line between t=-7
	# and t=+7 of the Square — so a crossing counted here is a crossing of
	# the Square's own band and nothing else's.
	var direction := Vector3(1.0, 0.0, -1.0).normalized()

	# HALF ONE — ONE CHANGE PER CROSSING. Start well outside every place,
	# walk a straight line through the Square's centre and out the far side.
	var start_t := -7.0
	var end_t := 7.0
	var steps := 280
	player.global_position = square.global_position + direction * start_t
	player.think_and_act(0.0)
	var previous_place := player.get_current_place()
	var changes: Array[Place] = []
	for i in range(1, steps + 1):
		var t: float = start_t + (end_t - start_t) * float(i) / float(steps)
		player.global_position = square.global_position + direction * t
		player.think_and_act(0.0)
		var now_place := player.get_current_place()
		if now_place != previous_place:
			changes.append(now_place)
			previous_place = now_place
	_require(changes.size() == 2, claim,
		"walking a straight line through the Square and out the far side changed current_place %d times, not 2" % changes.size())
	if changes.size() == 2:
		_require(changes[0] == square, claim,
			"the first change on the traverse reads %s, not the Square" % _describe_place(changes[0]))
		_require(changes[1] == null, claim,
			"the second change on the traverse reads %s, not nowhere" % _describe_place(changes[1]))

	# HALF TWO — THE HYSTERESIS, AND THIS IS THE HALF WITH TEETH. A single-
	# radius model answers the in-between distance differently depending on
	# which way it is crossed; a band does not.
	var midpoint: float = (brain.enters_within + brain.leaves_beyond) / 2.0
	player.global_position = square.global_position + direction * midpoint
	player.think_and_act(0.0)
	_require(player.get_current_place() == null, claim,
		"approaching from outside, parked at the midpoint between the two radii (%.2f), he reads %s — he has not entered yet" % [
			midpoint, _describe_place(player.get_current_place())])

	player.global_position = square.global_position + direction * (brain.enters_within * 0.5)
	player.think_and_act(0.0)
	_require(player.get_current_place() == square, claim,
		"moved inside enters_within (%.2f), he reads %s, not the Square" % [
			brain.enters_within, _describe_place(player.get_current_place())])

	player.global_position = square.global_position + direction * midpoint
	player.think_and_act(0.0)
	_require(player.get_current_place() == square, claim,
		"moved back out to the same midpoint distance (%.2f) he entered from, he now reads %s — a single-radius model would have dropped him here; the band must not" % [
			midpoint, _describe_place(player.get_current_place())])

	# HALF THREE — NO FLICKER. From inside, cross the INNER radius only, back
	# and forth, ten times. Holding the Square means only the OUTER radius can
	# evict him, so oscillating across the inner one alone must never move
	# current_place at all.
	var held_place := player.get_current_place()
	for i in 10:
		var factor: float = 0.8 if i % 2 == 0 else 1.2
		var distance: float = brain.enters_within * factor
		player.global_position = square.global_position + direction * distance
		player.think_and_act(0.0)
		_require(player.get_current_place() == held_place, claim,
			"crossing the inner radius alone (to %.2f, %.2fx enters_within) changed current_place to %s" % [
				distance, factor, _describe_place(player.get_current_place())])

	world.queue_free()


# 66 — THE STEP 2 TRAP, PINNED. Simply calling think_for_everyone(1.0) twice
# would be VACUOUS here: that call site takes hours by construction and never
# sees a real second, so it could never catch a real-frame constant leaking
# into the player's own walk. This drives him through the REAL conversion —
# clock.get_hours_elapsed(real_delta) — the only place the bug could live.
func _check_the_player_covers_the_same_ground_per_world_hour_at_any_day_length() -> void:
	var claim := "66 — the player covers the same ground per world hour at any day length"

	var distance_60 := _walk_one_world_hour_at(60.0, claim)
	var distance_600 := _walk_one_world_hour_at(600.0, claim)
	if distance_60 < 0.0 or distance_600 < 0.0:
		return

	_require(absf(distance_60 - distance_600) < 0.001, claim,
		"one world hour moved him %.5f units at a 60-second day (2.5 real seconds) and %.5f units at a 600-second day (25 real seconds) — real-frame integration is leaking through, not world hours" % [
			distance_60, distance_600])

	# A body that moved consistently but by the WRONG amount would still pass
	# the comparison above, so this checks the amount itself against the one
	# number it is supposed to equal — a third fresh world, so the expected
	# figure is read off the same seam the body's own walk uses, never
	# smuggled in from a run already under test.
	var speed_world := _add_a_disabled_game_scene()
	var speed_player := speed_world.get_node_or_null("Population/Player") as Person
	if speed_player == null:
		_require(false, claim, "a third world came up without a Player")
		return
	var expected_distance: float = speed_player.get_travel_speed() * 1.0
	speed_world.queue_free()

	_require(absf(distance_60 - expected_distance) < 0.001, claim,
		"one world hour should move him exactly get_travel_speed() times 1.0 = %.5f units, and it moved him %.5f" % [
			expected_distance, distance_60])


# One world hour of walking, driven through the REAL clock conversion — one
# simulated frame at a time — so the only path that could leak a real-second
# constant through to the player's own walk is the one being exercised.
# Returns -1.0 (and records a failure against `claim`) if the world did not
# come up right.
func _walk_one_world_hour_at(day_length_seconds: float, claim: String) -> float:
	var world := _add_a_disabled_game_scene()
	var player := world.get_node_or_null("Population/Player") as Person
	var population := world.get_node_or_null("Population") as Population
	var clock := world.get_node_or_null("Clock") as Clock
	if player == null or population == null or clock == null:
		_require(false, claim, "a world came up without a Player, a Population and a Clock")
		return -1.0
	var brain := player.brain as PlayerBrain
	if brain == null:
		_require(false, claim, "the Player's Brain is not a PlayerBrain")
		return -1.0

	clock.day_length_seconds = day_length_seconds
	brain.point_toward(Vector3.RIGHT)
	var start_position := player.global_position

	var real_frame := 1.0 / 60.0 # a single frame at 60fps, in REAL seconds
	var hours_accumulated := 0.0
	while hours_accumulated < 1.0:
		var hours_this_frame: float = clock.get_hours_elapsed(real_frame)
		# CLAMP THE FINAL STEP so both runs total exactly one world hour to
		# the float — a day length's ragged last frame must not add a
		# different fraction of an hour to one run than to the other.
		if hours_accumulated + hours_this_frame > 1.0:
			hours_this_frame = 1.0 - hours_accumulated
		population.think_for_everyone(hours_this_frame)
		hours_accumulated += hours_this_frame

	var distance: float = player.global_position.distance_to(start_position)
	world.queue_free()
	return distance


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

