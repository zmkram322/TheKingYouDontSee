extends SceneTree

# Headless proof scene for the two day curves added to world/world.gd and
# world/world_tune.gd: urge_to_work and urge_to_be_social, read through
# world.curve().
#
# The village built here has no needs and no obligations at all — nobody is
# hungry, nobody is owed anything. The only two things anyone knows how to do
# are "work the field" (scores world.curve(&"work")) and "idle at the inn"
# (scores world.curve(&"social")), each with a body that never finishes and
# never becomes impossible. That is deliberate: with nothing else able to
# change anyone's mind, the ONLY thing that can ever move a villager from one
# to the other is the clock moving and the sweep noticing — which is exactly
# what this file sets out to prove, and why nothing here ever calls
# character.act() or character.decide_action() by hand.
#
#   1) Across a full day, work and social genuinely cross — there is a moment
#      where social outscores work while work is still above zero, not just
#      two curves taking turns being silent.
#   2) Both curves stay inside the ceilings named in WorldTune, at every
#      sampled moment of the day.
#   3) A whole village with no needs still visibly drifts from working to
#      idling as the clock runs, driven by world.advance() and the sweep
#      alone — no hand-poked decisions anywhere in this test.
#   4) Asking the lookup for a curve that was never named warns and answers
#      0.0, same as world.where() does for a place nobody added.
#
# Usage: godot --headless --path tkyds-game --script res://tests/curve_smoke.gd

const SLICE := 0.05
const EXPECTED_CHECKS := 5

var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	_curves_cross_during_the_day()
	_curve_values_stay_on_the_tuning_scale()
	_a_needless_village_still_drifts_from_work_to_social()
	_unknown_curve_name_warns_and_returns_zero()

	if _checks < EXPECTED_CHECKS:
		_failures.append("only %d of %d checks ran — something bailed out early" % [_checks, EXPECTED_CHECKS])

	print("")
	if _failures.is_empty():
		print("=== curve smoke: OK ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== CURVE SMOKE FAIL ===")
		quit(1)


# --- 1. A real crossing, not merely alternating silence ----------------------

func _curves_cross_during_the_day() -> void:
	print("--- work and social genuinely cross somewhere in the day ---")
	var world := VillageWorld.new()

	var crossed := false
	var samples := 480
	for i in samples:
		var t := float(i) / samples
		var work := world.curve(&"work", t)
		var social := world.curve(&"social", t)
		if social > work and work > 0.0:
			crossed = true
			print("  at t=%.3f  work=%.1f  social=%.1f — social overtakes work while work is still nonzero" % [t, work, social])
			break

	_expect(crossed, "somewhere in the afternoon social should overtake work while work is still above zero")


# --- 2. Bounded by the named ceilings, everywhere -----------------------------

func _curve_values_stay_on_the_tuning_scale() -> void:
	print("")
	print("--- both curves stay within their named ceilings all day ---")
	var world := VillageWorld.new()

	var in_range := true
	var samples := 480
	for i in samples:
		var t := float(i) / samples
		var work := world.curve(&"work", t)
		var social := world.curve(&"social", t)
		if work < 0.0 or work > WorldTune.WORK_CURVE_PEAK + 0.01:
			in_range = false
		if social < 0.0 or social > WorldTune.SOCIAL_CURVE_PEAK + 0.01:
			in_range = false

	_expect(in_range, "work should stay within [0, WORK_CURVE_PEAK] and social within [0, SOCIAL_CURVE_PEAK] all day")


# --- 3. A needless village, moved only by the clock and the sweep ------------

func _a_needless_village_still_drifts_from_work_to_social() -> void:
	print("")
	print("--- a village with no needs at all still shifts from work to idling, purely from the clock ---")
	var world := _seeded_curve_village(6)

	_run_world_to(world, 0.45)   # deep in the working day's plateau
	var working := _count_doing(world, "work the field")
	print("  at t=%.2f: %d of %d are working" % [world.time_of_day(), working, world.characters.size()])
	_expect(working == world.characters.size(), "deep in the working day, everyone should be working — nothing else could have moved them but the sweep")

	_run_world_to(world, 0.90)  # well past the crossing, into the evening spike
	var idling := _count_doing(world, "idle at the inn")
	print("  at t=%.2f: %d of %d are idling" % [world.time_of_day(), idling, world.characters.size()])
	_expect(idling == world.characters.size(), "well into the evening, everyone should have drifted to idling — again, only the sweep could have moved them")

	# The two actions above close over `world` by design — that's what lets
	# world-content read a curve at all — which makes World -> Character ->
	# Action -> (closure holding world) a genuine reference cycle, and
	# RefCounted cycles never free themselves. Emptying the residency list
	# breaks the cycle from this end before `world` goes out of scope, the
	# same way DecisionBrain's own history warns a Character<->Brain cycle
	# would have leaked every headless run.
	world.characters.clear()


# --- 4. The lookup stays closed -----------------------------------------------

func _unknown_curve_name_warns_and_returns_zero() -> void:
	print("")
	print("--- asking for a curve that doesn't exist warns and answers 0.0 ---")
	var world := VillageWorld.new()
	var value := world.curve(&"weather")
	_expect(is_equal_approx(value, 0.0), "an unknown curve name should read as 0.0, not crash or guess (expect a push_warning above)")


# --- A village with no needs, no obligations, just the clock -----------------

# Bodies that never finish and never become impossible: with nothing to make
# them stop or fail, the only remaining way active_action ever changes is a
# reconsideration finding a new winner. That is precisely the seam this file
# means to exercise on its own, with nothing else muddying the result.
class NeverFinishes:
	extends Step

	func is_satisfied(_who) -> bool:
		return false

	func advance(_who, _delta: float) -> bool:
		return false


func _seeded_curve_village(count: int) -> VillageWorld:
	var world := VillageWorld.new()

	var work_action := Action.new("work the field",
		func(_who: Character) -> bool: return true,
		func(_who: Character) -> float: return world.curve(&"work"),
		NeverFinishes.new())
	var idle_action := Action.new("idle at the inn",
		func(_who: Character) -> bool: return true,
		func(_who: Character) -> float: return world.curve(&"social"),
		NeverFinishes.new())
	var knows: Array[Action] = [work_action, idle_action]

	for i in count:
		world.add_character(Character.new("villager %d" % i, {}, knows))
	return world


func _run_world_to(world: VillageWorld, target_fraction: float) -> void:
	var target_seconds := target_fraction * WorldTune.DAY_LENGTH_SECONDS
	while world.seconds < target_seconds:
		world.advance(SLICE)


func _count_doing(world: VillageWorld, label: String) -> int:
	var n := 0
	for who in world.characters:
		if who.active_action != null and who.active_action.label == label:
			n += 1
	return n


func _expect(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)
