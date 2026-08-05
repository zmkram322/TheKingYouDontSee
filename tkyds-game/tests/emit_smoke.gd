extends SceneTree

# Headless proof scene for the cross-actor demand seam added to
# world/world.gd (place facts, offers/who_can_serve, chores, close_down)
# and brain/obligation.gd (still_wanted / is_still_wanted).
#
# The cast is the innkeeper/miller chain. The inn needs flour; nobody tells
# the miller to grind it — he grinds because that's what's eligible and
# scores best, and the world hands him the errand to carry it over only once
# something is actually ready to carry. Nothing here is a Wait: whenever the
# interesting thing isn't eligible, something duller wins instead, and the
# interesting thing starts winning again the moment the world changes under
# it — never because anyone remembered to check back.
#
# What's being proven, in order:
#
#   1) With no flour anywhere and nothing to grind, the innkeeper sweeps.
#      No Wait step, nothing frozen — "bake bread" simply isn't eligible yet.
#   2) The inn's flour need emits exactly ONE obligation onto the miller —
#      the anyone_owes_about guard holds under repeated ticks.
#   3) The miller grinds — progress accumulating on the MILL, not on him or
#      his Step — then, once there's something to carry, delivers it. The
#      obligation discharges through the ordinary finish path — proven, not
#      assumed: emission and still-wanted read from opposite ends of a
#      hysteresis band (EMIT_WHEN_FLOUR_BELOW / WANTED_UNTIL_FLOUR) so a
#      partial delivery can never read as "no longer needed" and get swept
#      mid-carry, and the mill's flour_ground reading empty at the moment
#      the errand stops being owed is what tells discharge from expiry.
#   4) The moment flour lands at the inn, "bake bread" starts winning on its
#      own — the innkeeper bakes, bread appears — with nobody having told
#      her to.
#   5) A fright mid-delivery: the miller flees, the flour obligation stays
#      owed the whole time, and when the fright passes he picks the chain
#      back up from wherever he's standing and it still completes.
#   6) Expiry: the inn's flour is restocked by hand before the miller
#      delivers. The world's own sweep clears the obligation — it stops
#      being owed without ever being discharged as done work — and the
#      miller, with nothing left to grind either, goes back to dozing.
#   7) A provider whose ready test fails (no grain, nothing ground yet)
#      never appears in the snapshot; the emission rule tries and finds
#      nobody to hand the work to, and simply leaves it for a tick when the
#      world has changed — no error, no stuck state.
#
# Usage: godot --headless --path tkyds-game --script res://tests/emit_smoke.gd

const SLICE := 0.05
const EXPECTED_CHECKS := 25

const INN_AT := Vector2(400, 0)
const MILL_AT := Vector2(0, 0)

const SWEEP_SCORE := 5.0     # the innkeeper's dull filler — flat, always open to her
const BAKE_SCORE := 20.0     # baking, once flour makes it eligible — beats sweeping outright
const DOZE_SCORE := 5.0      # the miller's dull filler — flat, always open to him
const GRIND_SCORE := 20.0    # grinding, while there's grain — beats dozing outright

const GRIND_SECONDS := 1.0   # continuous work to turn one batch of grain into flour_ground
const GRIND_BATCH := 10.0    # grain consumed / flour_ground produced per completed batch
const DELIVER_RATE := 10.0   # flour_ground carried into the inn's stock, per second
const BAKE_RATE := 5.0       # flour turned into bread, per second

# The hysteresis band that keeps the flour errand justified through partial
# delivery. A single threshold shared by "should I emit" and "am I still
# wanted" is a bug: the moment the first speck of a delivery lands, the inn
# reads as no-longer-short, the errand's own justification evaporates before
# the errand is done, and the sweep clears it mid-carry — stranding whatever
# was left at the mill, only for the emission rule to notice the inn is
# short again a moment later and hand out a brand new errand. Two named
# thresholds instead of one: emit while the inn is genuinely running low,
# stay justified until it's genuinely restocked. The gap between them is
# exactly the room a delivery needs to be carried out in one uninterrupted
# debt, the same authored-band shape the design calls for rather than a
# special case bolted onto the sweep.
const EMIT_WHEN_FLOUR_BELOW := 1.0   # the inn calls for flour once its stock drops below this
const WANTED_UNTIL_FLOUR := 10.0     # the errand stays justified until the inn reaches this — a full batch's worth

var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	_no_flour_the_innkeeper_sweeps()
	_exactly_one_obligation_is_emitted()
	_the_chain_grinds_delivers_and_baking_begins()
	_fear_interrupts_mid_delivery_and_the_chain_still_completes()
	_restocking_by_hand_expires_the_obligation_unfinished()
	_a_provider_not_ready_is_absent_and_nothing_breaks()

	if _checks < EXPECTED_CHECKS:
		_failures.append("only %d of %d checks ran — something bailed out early" % [_checks, EXPECTED_CHECKS])

	print("")
	if _failures.is_empty():
		print("=== emit smoke: OK ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== EMIT SMOKE FAIL ===")
		quit(1)


# --- 1. No Wait: she sweeps while there's nothing to bake ---------------------

func _no_flour_the_innkeeper_sweeps() -> void:
	print("--- with no flour anywhere, the innkeeper sweeps rather than wait ---")
	var made := _seeded_world(0.0)
	var world: VillageWorld = made.world
	var innkeeper: Character = made.innkeeper

	var ever_baked := false
	for i in 40:
		world.advance(SLICE)
		if innkeeper.active_action != null and innkeeper.active_action.label == "bake bread":
			ever_baked = true

	print("  doing: %s" % innkeeper.doing_label())
	_expect(not ever_baked, "with no flour ever appearing, bake bread should never once have been eligible to win")
	_expect(innkeeper.active_action != null and innkeeper.active_action.label == "sweep the floor",
		"she should settle on sweeping the floor — no Wait step, nothing frozen, just the duller thing winning")

	world.close_down()


# --- 2. The emission guard holds under repeated ticks --------------------------

func _exactly_one_obligation_is_emitted() -> void:
	print("")
	print("--- the inn's need emits exactly one obligation, never a second helping ---")
	var made := _seeded_world(20.0)
	var world: VillageWorld = made.world
	var innkeeper: Character = made.innkeeper
	var miller: Character = made.miller

	# Long enough for the emission chore to run many times over, short enough
	# that the single obligation it hands out hasn't yet been carried out.
	for i in 30:
		world.advance(SLICE)

	var about_flour := 0
	for who in [innkeeper, miller]:
		for action in who.queue:
			if action is Obligation and action.about == &"flour":
				about_flour += 1

	print("  %.1fs of ticks under one open need: %d obligation(s) about flour outstanding" % [30 * SLICE, about_flour])
	_expect(about_flour == 1, "anyone_owes_about should have stopped every tick after the first from emitting a second (saw %d)" % about_flour)

	world.close_down()


# --- 3 & 4. Grinding, delivering, and baking starting on its own --------------

func _the_chain_grinds_delivers_and_baking_begins() -> void:
	print("")
	print("--- the miller grinds, delivers, and then the innkeeper bakes — nobody scripted any of it ---")
	var made := _seeded_world(20.0)
	var world: VillageWorld = made.world
	var innkeeper: Character = made.innkeeper
	var miller: Character = made.miller

	# Run until the obligation has genuinely been owed and then discharged —
	# not merely until the first speck of flour lands, which happens while
	# delivery is still under way and would catch this mid-errand.
	# Baking can genuinely start winning for the innkeeper before the miller's
	# own errand has fully discharged — she only needs the first delivered
	# flour to cross her gate, not the whole load — so this flag is tracked
	# across both loops below, not just the second one, or a fast innkeeper
	# could start and finish baking within the window this loop is watching
	# and leave nothing left for the second loop to observe.
	var saw_progress := false
	var saw_grinding_label := false
	var saw_baking := false
	var was_ever_owed := false
	var elapsed := 0.0
	var limit := 60.0
	while elapsed < limit:
		world.advance(SLICE)
		elapsed += SLICE
		if world.place_stat(&"mill", &"grinding_progress") > 0.0:
			saw_progress = true
		if miller.active_action != null and miller.active_action.label == "grind grain":
			saw_grinding_label = true
		if innkeeper.active_action != null and innkeeper.active_action.label == "bake bread":
			saw_baking = true
		if miller.owes_anything_about(&"flour"):
			was_ever_owed = true
		elif was_ever_owed:
			break

	print("  after %.2fs: mill grain=%.1f flour_ground=%.1f, inn flour=%.1f" % [
		elapsed, world.place_stat(&"mill", &"grain"), world.place_stat(&"mill", &"flour_ground"), world.place_stat(&"inn", &"flour")])
	_expect(saw_grinding_label, "the miller should genuinely have ground before delivering")
	_expect(saw_progress, "grinding_progress on the MILL should have climbed — duration lives on the place, not on him")
	_expect(world.place_stat(&"inn", &"flour") > 0.0, "delivery should eventually land flour at the inn")
	_expect(not miller.owes_anything_about(&"flour"), "carrying the errand out should discharge it, the same finish path as any other obligation")
	# The discriminator that tells discharge from expiry, the same fact test
	# 6 reads in reverse: discharge means DeliverFlour ran out of load to
	# carry, so nothing is left stranded at the mill. A sweep clearing the
	# errand early would have left flour_ground sitting there untouched.
	_expect(world.place_stat(&"mill", &"flour_ground") <= 0.0,
		"discharge means he emptied his load — a sweep would have left flour stranded at the mill instead")

	var baked_more := 0.0
	while elapsed < limit and world.place_stat(&"inn", &"bread") <= 0.0:
		world.advance(SLICE)
		elapsed += SLICE
		if innkeeper.active_action != null and innkeeper.active_action.label == "bake bread":
			saw_baking = true

	baked_more = world.place_stat(&"inn", &"bread")
	print("  after %.2fs total: innkeeper doing %s, inn bread=%.1f" % [elapsed, innkeeper.doing_label(), baked_more])
	_expect(saw_baking, "once flour arrived, bake bread should have started winning on its own")
	_expect(baked_more > 0.0, "and actually produced bread")

	world.close_down()


# --- 5. Interruption mid-chain: nothing unwinds --------------------------------

func _fear_interrupts_mid_delivery_and_the_chain_still_completes() -> void:
	print("")
	print("--- a fright mid-delivery: he flees, the errand stays owed, and the chain still finishes ---")
	var made := _seeded_world(10.0)   # one batch's worth — grinds fast, gets to delivering quickly
	var world: VillageWorld = made.world
	var miller: Character = made.miller

	var elapsed := 0.0
	var limit := 40.0
	while elapsed < limit and not (miller.active_action != null and miller.active_action.label == "deliver flour to the inn"):
		world.advance(SLICE)
		elapsed += SLICE
	print("  %.2fs in, mid-chain: %s" % [elapsed, miller.doing_label()])
	_expect(miller.active_action != null and miller.active_action.label == "deliver flour to the inn",
		"he should genuinely be underway delivering before the fright hits")

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
	print("  after %.2fs: inn flour=%.1f, owes flour: %s" % [elapsed, world.place_stat(&"inn", &"flour"), miller.owes_anything_about(&"flour")])
	_expect(world.place_stat(&"inn", &"flour") > 0.0, "he should have resumed from wherever he stood and finished the delivery — nothing unwound")
	_expect(not miller.owes_anything_about(&"flour"), "and the errand should be discharged, same as if nothing had interrupted it")
	_expect(world.place_stat(&"mill", &"flour_ground") <= 0.0,
		"discharge, not expiry — he actually emptied his load after resuming, the same discriminator as the chain proof above")

	world.close_down()


# --- 6. Expiry: the world sweeps it away unfinished ----------------------------

func _restocking_by_hand_expires_the_obligation_unfinished() -> void:
	print("")
	print("--- the inn is restocked by hand before delivery — the sweep clears the errand unfinished ---")
	var made := _seeded_world(10.0)   # one batch: grain runs out right as flour_ground appears
	var world: VillageWorld = made.world
	var miller: Character = made.miller

	var elapsed := 0.0
	var limit := 40.0
	while elapsed < limit and not (miller.active_action != null and miller.active_action.label == "deliver flour to the inn"):
		world.advance(SLICE)
		elapsed += SLICE
	_expect(miller.active_action != null and miller.active_action.label == "deliver flour to the inn",
		"he should be underway delivering before the inn is restocked by hand")

	var flour_ground_before: float = world.place_stat(&"mill", &"flour_ground")
	world.set_place_stat(&"inn", &"flour", 15.0)   # restocked by hand — nothing to do with the miller
	world.advance(SLICE)   # one tick is enough for the built-in sweep to notice

	print("  restocked by hand — owes flour: %s, mill flour_ground unchanged: %s, doing: %s" % [
		miller.owes_anything_about(&"flour"),
		is_equal_approx(world.place_stat(&"mill", &"flour_ground"), flour_ground_before),
		miller.doing_label()])
	_expect(not miller.owes_anything_about(&"flour"), "the sweep should have cleared the errand the moment it stopped being wanted")
	_expect(is_equal_approx(world.place_stat(&"mill", &"flour_ground"), flour_ground_before),
		"nothing should have been carried — this was cleared, not completed")

	for i in 20:
		world.advance(SLICE)
	print("  settling — doing: %s" % miller.doing_label())
	_expect(miller.active_action != null and miller.active_action.label == "doze",
		"with grain spent and the errand gone, dozing is all that's left open to him")

	world.close_down()


# --- 7. An unready provider is invisible, and nothing breaks -------------------

func _a_provider_not_ready_is_absent_and_nothing_breaks() -> void:
	print("")
	print("--- a provider whose ready test fails never appears, and emission simply tries again later ---")
	var made := _seeded_world(0.0)   # no grain, nothing ground — the miller can't serve yet
	var world: VillageWorld = made.world
	var miller: Character = made.miller

	world.advance(SLICE)
	print("  who_can_serve(flour): %d, anyone owed: %s" % [world.who_can_serve(&"flour").size(), world.anyone_owes_about(&"flour")])
	_expect(world.who_can_serve(&"flour").is_empty(), "with nothing to grind and nothing ground, the miller shouldn't be in the snapshot at all")
	_expect(not world.anyone_owes_about(&"flour"), "with no provider to hand it to, emission should simply not emit — no error, no stuck state")

	# The world changes — grain arrives — and the very next tick the same
	# rule finds a provider on its own, with nothing re-authored.
	world.set_place_stat(&"mill", &"grain", 20.0)
	world.advance(SLICE)
	print("  grain arrives — who_can_serve(flour): %d, %s now owes flour: %s" % [
		world.who_can_serve(&"flour").size(), miller.character_name, miller.owes_anything_about(&"flour")])
	_expect(not world.who_can_serve(&"flour").is_empty(), "the moment the world changes, the same declared offer should read as ready")
	_expect(miller.owes_anything_about(&"flour"), "and the very next tick's emission chore should hand the errand out, with nothing re-authored")

	world.close_down()


# --- The village: one inn, one mill, an innkeeper, a miller --------------------

# Fresh every call so no test shares a clock or a place fact with another.
# `grain_stock` is the only knob tests turn — everything else about the
# village is fixed.
func _seeded_world(grain_stock: float) -> Dictionary:
	var world := VillageWorld.new()
	world.add_place(&"inn", INN_AT)
	world.add_place(&"mill", MILL_AT)
	world.set_place_stat(&"mill", &"grain", grain_stock)

	var sweep_action := Action.new("sweep the floor",
		func(_w: Character) -> bool: return true,
		func(_w: Character) -> float: return SWEEP_SCORE,
		Filler.new("sweeping"))
	var bake_action := Action.new("bake bread",
		func(_w: Character) -> bool: return world.place_stat(&"inn", &"flour") > 0.0,
		func(_w: Character) -> float: return BAKE_SCORE,
		BakeBread.new(world))
	var innkeeper := Character.new("the innkeeper", {"position": INN_AT}, [sweep_action, bake_action] as Array[Action])
	world.add_character(innkeeper)

	var doze_action := Action.new("doze",
		func(_w: Character) -> bool: return true,
		func(_w: Character) -> float: return DOZE_SCORE,
		Filler.new("dozing"))
	var grind_action := Action.new("grind grain",
		func(_w: Character) -> bool: return world.place_stat(&"mill", &"grain") > 0.0,
		func(_w: Character) -> float: return GRIND_SCORE,
		GrindGrain.new(world))
	# Same shape as reconsider_smoke's flee: protected so it's always on the
	# ballot, threshold 0 so it defends nothing and is exactly as easy to
	# unseat as any ordinary action the instant fear passes.
	var flee_action := Action.new("flee",
		func(_w: Character) -> bool: return true,
		func(w: Character) -> float: return w.stat(&"fear"),
		Filler.new("fleeing")).always_available()
	var miller := Character.new("the miller", {"position": MILL_AT, "fear": 0.0}, [doze_action, grind_action, flee_action] as Array[Action])
	world.add_character(miller)

	# The miller can serve `flour` whenever there's something to work with —
	# grain still to grind, or flour_ground already sitting there waiting for
	# a trip to the inn.
	world.offers(&"flour", miller, func(_w: Character) -> bool:
		return world.place_stat(&"mill", &"grain") > 0.0 or world.place_stat(&"mill", &"flour_ground") > 0.0)

	# The one emission rule in this village: is the inn genuinely running low
	# on flour, and is nobody already owed about it? Then hand it to whoever
	# the snapshot says can serve it. First/nearest is fine today —
	# channel-weighted ranking (FR102) replaces this pick later; that's a
	# change to which provider gets chosen, never to this call site.
	#
	# The errand's still_wanted uses the OTHER end of the hysteresis band —
	# it stays justified until the inn is genuinely restocked, not merely
	# until the first speck arrives, so a delivery in progress can never be
	# read as "no longer needed" partway through carrying it.
	world.add_chore(func() -> void:
		if world.place_stat(&"inn", &"flour") >= EMIT_WHEN_FLOUR_BELOW:
			return
		if world.anyone_owes_about(&"flour"):
			return
		var providers := world.who_can_serve(&"flour")
		if providers.is_empty():
			return
		var provider: Character = providers[0]
		var errand := Obligation.new("deliver flour to the inn",
			func(_c: Character) -> bool: return world.place_stat(&"mill", &"flour_ground") > 0.0,
			func(_c: Character) -> float: return WorldTune.FLOUR_ERRAND_WORTH,
			Sequence.new([WalkTo.new(world.where(&"inn")), DeliverFlour.new(world)] as Array[Step]),
			&"flour", "the inn", world.seconds,
			func() -> bool: return world.place_stat(&"inn", &"flour") < WANTED_UNTIL_FLOUR)
		provider.assign_action(errand)
	)

	return {"world": world, "innkeeper": innkeeper, "miller": miller}


# --- Content leaves: converting place facts over time --------------------------

# Grinds whatever grain the mill has into flour_ground. Duration lives here
# as a fact on the MILL, not a timer on this Step and not a stat on whoever
# is doing the grinding — an interruption loses nothing, because nothing was
# ever stored anywhere but the place itself.
class GrindGrain:
	extends Step

	var world: VillageWorld

	func _init(new_world: VillageWorld) -> void:
		world = new_world

	func is_satisfied(_who) -> bool:
		return world.place_stat(&"mill", &"grain") <= 0.0

	func advance(_who, delta: float) -> bool:
		var grain: float = world.place_stat(&"mill", &"grain")
		if grain <= 0.0:
			return true
		var progress: float = world.place_stat(&"mill", &"grinding_progress") + delta
		while progress >= GRIND_SECONDS and world.place_stat(&"mill", &"grain") > 0.0:
			progress -= GRIND_SECONDS
			var take: float = minf(GRIND_BATCH, world.place_stat(&"mill", &"grain"))
			world.set_place_stat(&"mill", &"grain", world.place_stat(&"mill", &"grain") - take)
			world.set_place_stat(&"mill", &"flour_ground", world.place_stat(&"mill", &"flour_ground") + take)
		world.set_place_stat(&"mill", &"grinding_progress", progress)
		return is_satisfied(_who)

	func describe(_who) -> String:
		return "grinding grain"

	func verb(_who) -> StringName:
		return &"grinding"


# Carries flour_ground from the mill to the inn's own stock, drained and
# filled the same way EatMeal drains hunger — a plain rate against a place
# fact, nothing stored beyond the facts themselves.
class DeliverFlour:
	extends Step

	var world: VillageWorld

	func _init(new_world: VillageWorld) -> void:
		world = new_world

	func is_satisfied(_who) -> bool:
		return world.place_stat(&"mill", &"flour_ground") <= 0.0

	func advance(_who, delta: float) -> bool:
		var have: float = world.place_stat(&"mill", &"flour_ground")
		var take: float = minf(have, DELIVER_RATE * delta)
		world.set_place_stat(&"mill", &"flour_ground", have - take)
		world.set_place_stat(&"inn", &"flour", world.place_stat(&"inn", &"flour") + take)
		return is_satisfied(_who)

	func describe(_who) -> String:
		return "carrying flour"

	func verb(_who) -> StringName:
		return &"carrying"


# Turns the inn's flour into bread, the same drain-a-place-fact shape again.
class BakeBread:
	extends Step

	var world: VillageWorld

	func _init(new_world: VillageWorld) -> void:
		world = new_world

	func is_satisfied(_who) -> bool:
		return world.place_stat(&"inn", &"flour") <= 0.0

	func advance(_who, delta: float) -> bool:
		var flour: float = world.place_stat(&"inn", &"flour")
		var take: float = minf(flour, BAKE_RATE * delta)
		world.set_place_stat(&"inn", &"flour", flour - take)
		world.set_place_stat(&"inn", &"bread", world.place_stat(&"inn", &"bread") + take)
		return is_satisfied(_who)

	func describe(_who) -> String:
		return "baking bread"

	func verb(_who) -> StringName:
		return &"baking"


# The dull default every character in this village can always fall back to.
# Never satisfied and never impossible on its own — same shape as
# reconsider_smoke's NeverFinishes — only losing a decision ends it, which
# is exactly what "she never waits, she sweeps" means in practice.
class Filler:
	extends Step

	var _label: String

	func _init(new_label: String) -> void:
		_label = new_label

	func is_satisfied(_who) -> bool:
		return false

	func advance(_who, _delta: float) -> bool:
		return false

	func describe(_who) -> String:
		return _label


func _expect(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)
