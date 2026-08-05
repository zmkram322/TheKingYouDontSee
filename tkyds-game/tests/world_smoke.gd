extends SceneTree

# Headless proof scene for world/world.gd, world/world_tune.gd,
# world/eat_meal.gd, and the verb seam added to brain/step.gd (Sequence,
# Choice, WalkTo).
#
# Everything brain/ proved works for one actor deciding in isolation. This is
# the first time any of it runs inside an actual world: a clock that moves on
# its own, a map with a named place on it, and a resident who is fed by
# nothing but world.advance() — no direct character.act() calls anywhere in
# this file, because that is the whole point of building a world around the
# brain rather than driving characters by hand.
#
#   1) The clock accumulates seconds and reads back as a day-fraction that
#      wraps at the day boundary, with the day counter climbing — nothing
#      stored beyond the one seconds total (FR70's readable day-over-day
#      boundary, built on a number that can only ever agree with itself).
#   2) A place put on the map resolves to where it was put.
#   3) A hungry resident, seeded into the world and left alone, walks to the
#      hearth and eats — driven end to end by world.advance() alone.
#   4) The verb seam reports &"walking" while she's on her way and &"eating"
#      once she's at table, re-derived through the Sequence exactly the way
#      describe() already is — nothing about which leg she's on is stored
#      anywhere.
#
# Usage: godot --headless --path tkyds-game --script res://tests/world_smoke.gd

const SLICE := 0.05
const EXPECTED_CHECKS := 14

var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	_clock_accumulates_and_wraps()
	_places_resolve()
	_a_resident_walks_and_eats_under_advance_alone()
	_verb_seam_reports_through_a_sequence()

	if _checks < EXPECTED_CHECKS:
		_failures.append("only %d of %d checks ran — something bailed out early" % [_checks, EXPECTED_CHECKS])

	print("")
	if _failures.is_empty():
		print("=== world smoke: OK ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== WORLD SMOKE FAIL ===")
		quit(1)


# --- 1. The clock -------------------------------------------------------------

func _clock_accumulates_and_wraps() -> void:
	print("--- the clock accumulates and wraps at the day boundary ---")
	var world := VillageWorld.new()
	_expect(world.day() == 0, "a fresh world starts on day 0")
	_expect(is_equal_approx(world.time_of_day(), 0.0), "a fresh world starts at the top of the day")

	world.advance(WorldTune.DAY_LENGTH_SECONDS * 0.5)
	_expect(world.day() == 0, "still day 0 halfway through")
	_expect(is_equal_approx(world.time_of_day(), 0.5), "halfway through the day reads as 0.5 (%.3f)" % world.time_of_day())

	world.advance(WorldTune.DAY_LENGTH_SECONDS * 0.75)
	_expect(world.day() == 1, "day rolls over once total seconds pass one day length")
	_expect(is_equal_approx(world.time_of_day(), 0.25), "time_of_day wraps rather than keeps climbing (%.3f)" % world.time_of_day())


# --- 2. Places ------------------------------------------------------------------

func _places_resolve() -> void:
	print("")
	print("--- a place resolves to where it was put ---")
	var world := VillageWorld.new()
	world.add_place(&"hearth", Vector2(200, 0))
	_expect(world.where(&"hearth") == Vector2(200, 0), "the hearth resolves to the position it was added with")


# --- 3. A resident, fed by world.advance() alone --------------------------------

func _a_resident_walks_and_eats_under_advance_alone() -> void:
	print("")
	print("--- a hungry resident walks to the hearth and eats, driven only by world.advance() ---")
	var world := _seeded_world()
	var who: Character = world.characters[0]

	_expect(who.stat(&"hunger") > 0.0, "she starts hungry")
	_expect(who.stat(&"position") != world.where(&"hearth"), "she starts away from the hearth")

	var elapsed := 0.0
	var limit := 30.0
	while elapsed < limit and who.stat(&"hunger") > 0.0:
		world.advance(SLICE)
		elapsed += SLICE

	_expect(who.stat(&"hunger") <= 0.0, "world.advance() alone should have fed her")
	_expect(who.stat(&"position").distance_to(world.where(&"hearth")) <= 4.0, "and left her standing at the hearth")
	_expect(elapsed < limit, "she should have finished well inside the time limit")


# --- 4. The verb seam, re-derived through a Sequence -----------------------------

func _verb_seam_reports_through_a_sequence() -> void:
	print("")
	print("--- the verb seam reports walking, then eating, re-derived from the Sequence ---")
	var world := _seeded_world()
	var who: Character = world.characters[0]

	var saw_walking := false
	for i in 200:
		world.advance(SLICE)
		if who.active_action != null and who.active_action.body.verb(who) == &"walking":
			saw_walking = true
			break
	_expect(saw_walking, "mid-walk the Sequence should report the WalkTo leaf's verb")

	var saw_eating := false
	for i in 200:
		if who.stat(&"hunger") <= 0.0:
			break
		world.advance(SLICE)
		if who.active_action != null and who.active_action.body.verb(who) == &"eating":
			saw_eating = true
			break
	_expect(saw_eating, "mid-meal the Sequence should report the Eat leaf's verb")


# --- The world used by 3) and 4) -------------------------------------------------

# One place, one resident, one action: walk to the hearth and eat there.
# Fresh each call so the two tests that use it don't share a clock.
func _seeded_world() -> VillageWorld:
	var world := VillageWorld.new()
	world.add_place(&"hearth", Vector2(200, 0))

	var have_a_meal := Action.new("have a meal",
		func(w: Character) -> bool: return w.stat(&"hunger") > 0.0,
		func(w: Character) -> float: return w.stat(&"hunger"),
		Sequence.new([WalkTo.new(world.where(&"hearth")), EatMeal.new()] as Array[Step]))
	var knows: Array[Action] = [have_a_meal]

	var who := Character.new("Wren", {"position": Vector2.ZERO, "hunger": 40.0}, knows)
	world.add_character(who)
	return world


func _expect(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)
