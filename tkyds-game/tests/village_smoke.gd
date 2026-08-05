extends SceneTree

# Headless proof scene for the full village authored in world/village.gd —
# the assembled whole that world_smoke.gd, curve_smoke.gd, reconsider_smoke.gd,
# and emit_smoke.gd each proved a piece of in isolation. Village.build() is
# the same builder a later 3D scene calls; nothing here is a second
# simulation, only a headless way of watching this one run.
#
# What's being proven, in order:
#
#   1) The day arc. A full day, sampled at dawn/morning/midday/dusk/night:
#      farmhands at the field in the morning with the field's own grain
#      pile climbing, at least one of them crossing into hunger and eating
#      around midday, a majority converging on the inn at dusk — the
#      work/social crossing made visible with real needs layered on top,
#      not the needless village curve_smoke.gd ran — and a majority asleep
#      at home once night falls. Printed as a readable timeline.
#   2) The chain, three deep. Starting from nothing (empty field, empty
#      mill, empty inn), run until eating has genuinely pulled flour demand
#      onto Osric and grain demand onto a farmhand, both errands actually
#      carried out, and bread comes back — nobody having scripted the
#      sequence. Checked continuously, not just at the end: at no tick does
#      more than one outstanding obligation share an `about` key.
#   3) Interruption mid-chain. A fright hits Osric while he's mid-delivery:
#      he flees, the flour errand stays owed the whole time he's running,
#      and the instant fear passes he resumes from wherever he's standing
#      and finishes it — nothing unwound, the same proof emit_smoke.gd
#      already ran, now against the real village.
#
# Usage: godot --headless --path tkyds-game --script res://tests/village_smoke.gd

const SLICE := 0.05
const EXPECTED_CHECKS := 19

var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	_the_day_arc_unfolds()
	_the_chain_runs_three_deep()
	_fear_interrupts_mid_chain_and_resumes()

	if _checks < EXPECTED_CHECKS:
		_failures.append("only %d of %d checks ran — something bailed out early" % [_checks, EXPECTED_CHECKS])

	print("")
	if _failures.is_empty():
		print("=== village smoke: OK ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== VILLAGE SMOKE FAIL ===")
		quit(1)


# --- 1. The day arc -------------------------------------------------------------

func _the_day_arc_unfolds() -> void:
	print("--- a full day: field in the morning, hunger crossing at midday, the inn at dusk, sleep at night ---")
	var world := Village.build()
	var farmhands := _farmhands(world)

	# Bread on the shelf from the start, generous enough that no farmhand's
	# hunger is ever left unsatisfiable by a slow-moving background chain —
	# this proof is about the day's rhythm, not about the chain, which gets
	# its own proof below starting from nothing.
	world.set_place_stat(Village.INN, &"bread", 200.0)

	var field_grain_at_dawn: float = world.place_stat(Village.FIELD, &"grain")
	_print_timeline(world, farmhands, "dawn")
	# At dawn hunger, work, and social all read zero, so sleep's flat score
	# is the only nonzero candidate and everyone is still abed — which is
	# exactly dawn's own story: nothing has pulled anyone out of bed yet.

	# Absolute times-of-day rather than windows-from-here, one per named
	# moment, all against the same anchors WorldTune's own curve comments
	# name (WORK_FULL_BY, WORK_FADES_FROM/SOCIAL_FULL_BY, SOCIAL_SILENT_BY):
	# comfortably inside the working plateau, well into the evening pull,
	# and deep enough into the night that both curves have genuinely gone
	# quiet, not merely dipped.
	var morning_by := 46.0
	var midday_by := 66.0
	var dusk_by := 95.0
	var night_by := 118.0

	var working := _run_until(world, farmhands, morning_by,
		func(w: Character) -> bool: return w.active_action != null and w.active_action.label == "work the field",
		_majority(farmhands))
	_print_timeline(world, farmhands, "morning")
	_expect(working, "a majority of farmhands should be working the field once the morning pull is up")
	_expect(world.place_stat(Village.FIELD, &"grain") > field_grain_at_dawn,
		"the field's own grain pile should have climbed while they worked it")

	var ate := _run_until(world, farmhands, midday_by,
		func(w: Character) -> bool: return w.active_action != null and w.active_action.label == "eat at the inn",
		1)
	_print_timeline(world, farmhands, "midday")
	_expect(ate, "at least one farmhand's hunger should have crossed into eating by midday")

	var at_inn := _run_until(world, farmhands, dusk_by,
		func(w: Character) -> bool: return w.active_action != null and w.active_action.label in ["idle at the inn", "eat at the inn"],
		_majority(farmhands))
	_print_timeline(world, farmhands, "dusk")
	_expect(at_inn, "a majority should have converged on the inn as social overtakes work at dusk")

	var asleep := _run_until(world, farmhands, night_by,
		func(w: Character) -> bool: return w.active_action != null and w.active_action.label == "sleep",
		_majority(farmhands))
	_print_timeline(world, farmhands, "night")
	_expect(asleep, "a majority should be asleep at home once both curves have gone quiet")

	world.close_down()


# --- 2. The chain, three deep ----------------------------------------------------

func _the_chain_runs_three_deep() -> void:
	print("")
	print("--- the chain runs three deep from nothing: eating pulls flour, flour pulls grain, and bread comes back ---")
	var world := Village.build()
	var farmhands := _farmhands(world)
	var miller := Village.find(world, Village.MILLER_NAME)
	var innkeeper := Village.find(world, Village.INNKEEPER_NAME)

	# Start inside the working day so the field doesn't sit idle through a
	# pre-dawn silence before the chain has any reason to move at all.
	world.seconds = WorldTune.DAY_LENGTH_SECONDS * 0.22

	var saw_working := false
	var saw_grain_errand := false
	var saw_hauling := false
	var saw_grinding := false
	var saw_flour_errand := false
	var saw_delivering := false
	var saw_baking := false
	var duplicate_about_seen := false

	var elapsed := 0.0
	var limit := 400.0
	while elapsed < limit and world.place_stat(Village.INN, &"bread") <= 0.0:
		world.advance(SLICE)
		elapsed += SLICE

		if _anyone_doing(farmhands, "work the field"):
			saw_working = true
		if _anyone_doing(farmhands, "haul grain to the mill"):
			saw_hauling = true
		if world.anyone_owes_about(&"grain"):
			saw_grain_errand = true
		if miller.active_action != null and miller.active_action.label == "grind grain":
			saw_grinding = true
		if miller.owes_anything_about(&"flour"):
			saw_flour_errand = true
		if miller.active_action != null and miller.active_action.label == "deliver flour to the inn":
			saw_delivering = true
		if innkeeper.active_action != null and innkeeper.active_action.label == "bake bread":
			saw_baking = true

		# The guard: at no tick may two outstanding obligations share an
		# `about` key. anyone_owes_about is a yes/no question, so this walks
		# every queue directly rather than calling it, the same shape its
		# own docstring describes as the alternative to remembering.
		var about_counts := {}
		for who in world.characters:
			for action in who.queue:
				if action is Obligation:
					about_counts[action.about] = about_counts.get(action.about, 0) + 1
		for about in about_counts:
			if about_counts[about] > 1:
				duplicate_about_seen = true

	print("  after %.1fs: field grain=%.1f, mill grain=%.1f flour_ground=%.1f, inn flour=%.1f bread=%.1f" % [
		elapsed,
		world.place_stat(Village.FIELD, &"grain"),
		world.place_stat(Village.MILL, &"grain"),
		world.place_stat(Village.MILL, &"flour_ground"),
		world.place_stat(Village.INN, &"flour"),
		world.place_stat(Village.INN, &"bread")])
	_expect(saw_working, "a farmhand should genuinely have worked the field to start the chain")
	_expect(saw_grain_errand, "the mill running low on grain should have emitted an errand to a farmhand")
	_expect(saw_hauling, "a farmhand should genuinely have hauled grain to the mill")
	_expect(saw_grinding, "Osric should genuinely have ground the grain that arrived")
	_expect(saw_flour_errand, "the inn running low on flour should have emitted an errand to Osric")
	_expect(saw_delivering, "Osric should genuinely have delivered the flour he ground")
	_expect(saw_baking, "Maren should genuinely have baked once flour arrived")
	_expect(world.place_stat(Village.INN, &"bread") > 0.0, "and bread should have come back at the end of it, nobody having scripted the sequence")
	_expect(elapsed < limit, "the whole chain should have completed well inside the time limit")
	_expect(not duplicate_about_seen, "at no tick should two outstanding obligations have shared an about key — anyone_owes_about should have guarded every emission")

	world.close_down()


# --- 3. Interruption mid-chain: nothing unwinds -----------------------------------

func _fear_interrupts_mid_chain_and_resumes() -> void:
	print("")
	print("--- a fright hits Osric mid-delivery: he flees, the errand stays owed, and the chain still finishes ---")
	var world := Village.build()
	var miller := Village.find(world, Village.MILLER_NAME)

	# Flour already ground, so the errand is emitted and he's delivering
	# within a tick or two — the same shortcut emit_smoke.gd's own fear
	# proof takes, since what's under proof here is the interruption, not
	# grinding a second time.
	world.set_place_stat(Village.MILL, &"flour_ground", 15.0)

	var elapsed := 0.0
	var limit := 20.0
	while elapsed < limit and not (miller.active_action != null and miller.active_action.label == "deliver flour to the inn"):
		world.advance(SLICE)
		elapsed += SLICE
	print("  %.2fs in, mid-chain: %s" % [elapsed, miller.doing_label()])
	_expect(miller.active_action != null and miller.active_action.label == "deliver flour to the inn",
		"Osric should genuinely be underway delivering before the fright hits")

	miller.set_stat(&"fear", 100.0)
	world.reconsider(miller)
	print("  fear spikes — %s" % miller.doing_label())
	_expect(miller.active_action != null and miller.active_action.label == "flee", "fear outscoring everything should seize control instantly")
	_expect(miller.owes_anything_about(&"flour"), "fleeing must not touch what's owed — the errand is still his the whole time he's running")

	miller.set_stat(&"fear", 0.0)
	world.reconsider(miller)
	print("  fear passes — %s" % miller.doing_label())
	_expect(miller.active_action != null and miller.active_action.label != "flee", "the instant fear passes, flee defends nothing and the chain resumes")

	while elapsed < limit and miller.owes_anything_about(&"flour"):
		world.advance(SLICE)
		elapsed += SLICE
	print("  after %.2fs: inn flour=%.1f, owes flour: %s" % [elapsed, world.place_stat(Village.INN, &"flour"), miller.owes_anything_about(&"flour")])
	_expect(world.place_stat(Village.INN, &"flour") > 0.0, "he should have resumed from wherever he stood and finished the delivery — nothing unwound")
	_expect(not miller.owes_anything_about(&"flour"), "and the errand should be discharged, same as if nothing had interrupted it")

	world.close_down()


# --- Helpers -----------------------------------------------------------------

func _farmhands(world: VillageWorld) -> Array[Character]:
	var found: Array[Character] = []
	for farmhand_name in Village.FARMHAND_NAMES:
		found.append(Village.find(world, farmhand_name))
	return found


func _anyone_doing(who_list: Array[Character], label: String) -> bool:
	for who in who_list:
		if who.active_action != null and who.active_action.label == label:
			return true
	return false


func _majority(farmhands: Array[Character]) -> int:
	return (farmhands.size() / 2) + 1


# Runs the world from wherever its clock already stands up to `until_seconds`
# of world.seconds, watching at every tick for at least `count_needed` of
# `farmhands` to satisfy `matches` at the SAME instant, and returns true the
# moment that happens (the run still continues to `until_seconds` regardless,
# so the timeline printed right after reflects the state at the named
# moment, not the instant the pattern first held). A single-instant sample
# would be fragile here on purpose: hunger, once it crosses a flat score
# like sleep's, resolves in well under a second (EAT_RATE against a
# generous larder), so the village's true rhythm is a majority holding a
# pattern for most of a stretch, not necessarily at one exact tick a test
# happens to land on. Scanning the whole stretch up to the named moment is
# what a human watching the timeline would actually see; sampling one
# instant is not.
func _run_until(world: VillageWorld, farmhands: Array[Character], until_seconds: float,
		matches: Callable, count_needed: int) -> bool:
	var seen := false
	while world.seconds < until_seconds:
		world.advance(SLICE)
		var n := 0
		for farmhand in farmhands:
			if matches.call(farmhand):
				n += 1
		if n >= count_needed:
			seen = true
	return seen


func _print_timeline(world: VillageWorld, farmhands: Array[Character], label: String) -> void:
	var who_lines := []
	for farmhand in farmhands:
		who_lines.append("%s(h=%.1f): %s" % [farmhand.character_name, farmhand.stat(&"hunger"), farmhand.doing_label()])
	print("  [%s] t=%.2f — %s" % [label, world.time_of_day(), ", ".join(who_lines)])
	print("    field grain=%.1f  mill grain=%.1f flour_ground=%.1f  inn flour=%.1f bread=%.1f" % [
		world.place_stat(Village.FIELD, &"grain"),
		world.place_stat(Village.MILL, &"grain"),
		world.place_stat(Village.MILL, &"flour_ground"),
		world.place_stat(Village.INN, &"flour"),
		world.place_stat(Village.INN, &"bread")])


func _expect(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)
