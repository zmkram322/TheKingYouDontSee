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
	_pump_one_day()
	_check_everyone_is_ticked_once_per_call()
	_check_the_town_survives_losing_somebody()
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

# One simulated day, one tick at a time, with assertions 1, 2 and 3 riding
# along. They share a loop because they are three questions about the same
# 2400 ticks, and pumping him three times would be three different days.
func _pump_one_day() -> void:
	var ceiling: float = _person.brain.adenosine_ceiling
	var tick_count := int(round(HOURS_IN_A_DAY / TICK_HOURS))
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
		"1 — over 24 simulated hours he sleeps at least once and wakes at least once",
		"never slept in %.0f simulated hours — adenosine reached %.2f against StayUp's pull" % [
			HOURS_IN_A_DAY, _person.stats.get_stat(&"adenosine")])
	_require(has_woken_again,
		"1 — over 24 simulated hours he sleeps at least once and wakes at least once",
		"slept at hour %.2f and was still under at hour %.0f" % [_fell_asleep_at_hour, HOURS_IN_A_DAY])


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
	_require(population.get_people().size() == 2, claim,
		"expected 2 people under Population and found %d — the marker node was counted as one" % [
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
	_require(population.get_people().size() == 1, claim,
		"expected 1 person left and found %d" % population.get_people().size())

	world.queue_free()


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


# --- Saying so ------------------------------------------------------------------

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
		_checks, HOURS_IN_A_DAY, TICK_HOURS])
	if _fell_asleep_at_hour >= 0.0:
		print("        turned in at hour %.2f, up again at hour %.2f" % [
			_fell_asleep_at_hour, _woke_at_hour])
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

