class_name Village
extends RefCounted

# The authored village this session proves out: five residents around one
# small demand chain, wired up once here so that the headless proof
# (tests/village_smoke.gd) and the eventual 3D scene are looking at the
# exact same VillageWorld — a scene is a skin over this, never a second
# simulation of its own. build() is the only entry point; every place and
# every resident a skin might need to find is named as a constant below
# rather than buried in the wiring, and find() is how a skin asks for one
# by name instead of holding onto a reference of its own.
#
# The cast, and why each of them earns a place in this proof:
#
#   - Tam, Ivo, and Cade work the field. Three farmhands, not one, because
#     the same field pulls triple duty: it's what urge_to_work acts on,
#     working it is what makes them hungry, and three of them drifting to
#     the inn together at dusk is what makes urge_to_be_social visible as a
#     crowd, not a single data point.
#
#   - Osric mills. Grinding is the duration-based work case: grinding_progress
#     lives as a fact on the MILL, never on him and never on the Step doing
#     the grinding, so a fright mid-batch loses nothing when he resumes.
#
#   - Maren keeps the inn. Baking is gated on having flour and nothing
#     else — no Wait step anywhere in her — she sweeps or naps until flour
#     turns up, and then baking simply starts winning on its own the moment
#     it's eligible.
#
# The chain, three deep on purpose: farmhands eat bread -> the inn's bread
# stock falls -> Maren's flour need emits an errand to Osric -> carrying it
# out empties his flour_ground, which drops his own grain low enough to emit
# an errand to whichever farmhand the field says can serve it -> that
# farmhand hauls grain, Osric grinds and delivers, Maren bakes, and bread
# comes back. Nobody at any link is told what to do next; every step of it
# is a plain need or a plain errand winning an ordinary scoring pass, guarded
# by anyone_owes_about the same way emit_smoke.gd's two-actor version proved
# it could be.

const FIELD := &"field"
const MILL := &"mill"
const INN := &"inn"
const HOME := &"home"

const FIELD_AT := Vector2(-300, 0)
const MILL_AT := Vector2(0, 0)
const INN_AT := Vector2(400, 0)
const HOME_AT := Vector2(200, 220)

const FARMHAND_NAMES := ["Tam", "Ivo", "Cade"]
const MILLER_NAME := "Osric"
const INNKEEPER_NAME := "Maren"


static func build() -> VillageWorld:
	var world := VillageWorld.new()
	world.add_place(FIELD, FIELD_AT)
	world.add_place(MILL, MILL_AT)
	world.add_place(INN, INN_AT)
	world.add_place(HOME, HOME_AT)

	var farmhands: Array[Character] = []
	for farmhand_name in FARMHAND_NAMES:
		farmhands.append(_build_farmhand(world, farmhand_name))
	var miller := _build_miller(world)
	var innkeeper := _build_innkeeper(world)

	for farmhand in farmhands:
		world.add_character(farmhand)
	world.add_character(miller)
	world.add_character(innkeeper)

	_wire_hunger_drift(world, farmhands)
	_wire_flour_emission(world, miller)
	_wire_grain_emission(world, farmhands)

	return world


# A skin asks for a resident by name each time it wants to draw one, the
# same way it asks world.where() for a place instead of keeping a Vector2 of
# its own — nothing outside the world is meant to hold a Character between
# frames.
static func find(world: VillageWorld, character_name: String) -> Character:
	for who in world.characters:
		if who.character_name == character_name:
			return who
	return null


# --- The cast -----------------------------------------------------------------

# Tam, Ivo, or Cade: works the field, eats when hungry, drifts to the inn
# to socialise, sleeps at home — four actions, and the day curves plus
# hunger plus the clock are the only things that ever move one from any of
# them to another.
static func _build_farmhand(world: VillageWorld, farmhand_name: String) -> Character:
	var work_action := Action.new("work the field",
		func(_w: Character) -> bool: return true,
		func(_w: Character) -> float: return world.curve(&"work"),
		Sequence.new([
			WalkTo.new(FIELD_AT),
			WorkField.new(world, FIELD, &"grain", WorldTune.FIELD_YIELD_RATE, WorldTune.FIELD_GRAIN_CAP),
		] as Array[Step]))

	var eat_action := Action.new("eat at the inn",
		func(_w: Character) -> bool: return world.place_stat(INN, &"bread") > 0.0,
		func(w: Character) -> float: return w.stat(&"hunger"),
		Sequence.new([
			WalkTo.new(INN_AT),
			EatBread.new(world, INN, &"bread", WorldTune.EAT_RATE),
		] as Array[Step])
	).hard_to_interrupt(WorldTune.MEAL_INTERRUPT_THRESHOLD)

	var social_action := Action.new("idle at the inn",
		func(_w: Character) -> bool: return true,
		func(_w: Character) -> float: return world.curve(&"social"),
		Sequence.new([
			WalkTo.new(INN_AT),
			Dawdle.new("chatting at the inn"),
		] as Array[Step]))

	var knows: Array[Action] = [work_action, eat_action, social_action, _sleep_action(world)]
	return Character.new(farmhand_name, {"position": HOME_AT, "hunger": 0.0}, knows)


# Osric: dozes by default, grinds whenever the mill has grain, flees if
# something frightens him, sleeps at home once there's truly nothing left to
# grind. Delivering flour is never one of his known actions — it only ever
# reaches him as the obligation _wire_flour_emission hands out, the same way
# emit_smoke.gd's miller never knew "deliver flour" as a standing skill.
static func _build_miller(world: VillageWorld) -> Character:
	var doze_action := Action.new("doze",
		func(_w: Character) -> bool: return true,
		func(_w: Character) -> float: return WorldTune.DOZE_SCORE,
		Dawdle.new("dozing"))

	var grind_action := Action.new("grind grain",
		func(_w: Character) -> bool: return world.place_stat(MILL, &"grain") > 0.0,
		func(_w: Character) -> float: return WorldTune.GRIND_SCORE,
		ConvertStock.new(world, MILL, &"grain", &"flour_ground", &"grinding_progress",
			WorldTune.GRIND_SECONDS, WorldTune.GRIND_BATCH, "grinding grain", &"grinding"))

	# Protected and left at the default interrupt_threshold of 0 — same
	# shape as emit_smoke.gd's own flee and reconsider_smoke.gd's: always on
	# the ballot, and exactly as easy to unseat as any ordinary action the
	# instant fear passes, so it seizes control instantly but defends
	# nothing of its own.
	var flee_action := Action.new("flee",
		func(_w: Character) -> bool: return true,
		func(w: Character) -> float: return w.stat(&"fear"),
		Dawdle.new("fleeing", &"fleeing")
	).always_available()

	var knows: Array[Action] = [doze_action, grind_action, flee_action, _sleep_action(world)]
	return Character.new(MILLER_NAME, {"position": MILL_AT, "fear": 0.0}, knows)


# Maren: sweeps by default, bakes whenever the inn has flour, sleeps at
# home. "Deliver flour to the inn" is Osric's obligation, not something she
# does — her half of the chain is entirely: bake when there's flour, and
# don't when there isn't.
static func _build_innkeeper(world: VillageWorld) -> Character:
	var sweep_action := Action.new("sweep the floor",
		func(_w: Character) -> bool: return true,
		func(_w: Character) -> float: return WorldTune.SWEEP_SCORE,
		Dawdle.new("sweeping"))

	var bake_action := Action.new("bake bread",
		func(_w: Character) -> bool: return world.place_stat(INN, &"flour") > 0.0,
		func(_w: Character) -> float: return WorldTune.BAKE_SCORE,
		ConvertStock.new(world, INN, &"flour", &"bread", &"baking_progress",
			WorldTune.BAKE_SECONDS, WorldTune.BAKE_BATCH, "baking bread", &"baking"))

	var knows: Array[Action] = [sweep_action, bake_action, _sleep_action(world)]
	return Character.new(INNKEEPER_NAME, {"position": INN_AT}, knows)


# Shared by all five: walk home and rest. A flat, gateless score, priced in
# WorldTune against the two day curves — see SLEEP_SCORE's own comment for
# why it wins only once work and social have both gone quiet, exactly the
# behaviour the day arc calls for without a tiredness stat or a third curve.
static func _sleep_action(world: VillageWorld) -> Action:
	return Action.new("sleep",
		func(_w: Character) -> bool: return true,
		func(_w: Character) -> float: return WorldTune.SLEEP_SCORE,
		Sequence.new([
			WalkTo.new(HOME_AT),
			Dawdle.new("asleep", &"sleeping"),
		] as Array[Step]))


# --- The chain, three deep -----------------------------------------------------

# Hunger drifts upward for every farmhand, all the time, regardless of what
# they're doing — the content chore that starts the whole demand chain,
# kept ignorant to world.gd itself the same way every other chore in this
# file is. Chores are called with no arguments (see VillageWorld._run_chores),
# so real elapsed time is recovered the same way world.seconds recovers
# time_of_day: one stored fact, re-derived against, never a countdown. The
# fact stored here — when hunger drift was last accounted for — is bookkeeping
# for the chore itself, not progress on anyone's need, the same category as
# Character's own reconsider_phase; it's kept as a place fact under a
# nominal "village" key since it isn't about any one place.
static func _wire_hunger_drift(world: VillageWorld, farmhands: Array[Character]) -> void:
	world.add_chore(func() -> void:
		var last: float = world.place_stat(&"village", &"hunger_marked_at", world.seconds)
		var elapsed: float = world.seconds - last
		if elapsed > 0.0:
			for farmhand in farmhands:
				var hunger: float = farmhand.stat(&"hunger") + WorldTune.HUNGER_DRIFT_RATE * elapsed
				farmhand.set_stat(&"hunger", minf(WorldTune.NEED_FULL, hunger))
		world.set_place_stat(&"village", &"hunger_marked_at", world.seconds)
	)


# Maren's need, emitted onto Osric — the first link, proven two-actor in
# emit_smoke.gd and reproduced here against the real village and real
# WorldTune constants rather than fixture-local ones. Osric can serve
# `flour` whenever the mill holds something to work with, grain still to
# grind or flour_ground already sitting there waiting for a trip to the inn.
static func _wire_flour_emission(world: VillageWorld, miller: Character) -> void:
	world.offers(&"flour", miller, func(_w: Character) -> bool:
		return world.place_stat(MILL, &"grain") > 0.0 or world.place_stat(MILL, &"flour_ground") > 0.0)

	world.add_chore(func() -> void:
		if world.place_stat(INN, &"flour") >= WorldTune.FLOUR_LOW_AT:
			return
		if world.anyone_owes_about(&"flour"):
			return
		var providers := world.who_can_serve(&"flour")
		if providers.is_empty():
			return
		var provider: Character = providers[0]
		var errand := Obligation.new("deliver flour to the inn",
			func(_c: Character) -> bool: return world.place_stat(MILL, &"flour_ground") > 0.0,
			func(_c: Character) -> float: return WorldTune.FLOUR_ERRAND_WORTH,
			Sequence.new([
				WalkTo.new(INN_AT),
				CarryStock.new(world, MILL, &"flour_ground", INN, &"flour", WorldTune.CARRY_RATE, "carrying flour"),
			] as Array[Step]),
			&"flour", INNKEEPER_NAME, world.seconds,
			func() -> bool: return world.place_stat(INN, &"flour") < WorldTune.FLOUR_STOCKED_AT)
		provider.assign_action(errand)
	)


# Osric's own need, emitted onto whichever farmhand the field says can
# serve it — the second link, and the one that makes this three deep rather
# than two: carrying his flour out is what runs his grain low enough to ask
# for more. All three farmhands declare the same offer, since being able to
# haul grain is a fact about the field's own stock, not about any one of
# them; the first one the snapshot lists gets the errand, the same
# first/nearest simplification emit_smoke.gd already names and defers.
static func _wire_grain_emission(world: VillageWorld, farmhands: Array[Character]) -> void:
	for farmhand in farmhands:
		world.offers(&"grain", farmhand, func(_w: Character) -> bool:
			return world.place_stat(FIELD, &"grain") > 0.0)

	world.add_chore(func() -> void:
		if world.place_stat(MILL, &"grain") >= WorldTune.GRAIN_LOW_AT:
			return
		if world.anyone_owes_about(&"grain"):
			return
		var providers := world.who_can_serve(&"grain")
		if providers.is_empty():
			return
		var provider: Character = providers[0]
		var errand := Obligation.new("haul grain to the mill",
			func(_c: Character) -> bool: return world.place_stat(FIELD, &"grain") > 0.0,
			func(_c: Character) -> float: return WorldTune.GRAIN_ERRAND_WORTH,
			Sequence.new([
				WalkTo.new(FIELD_AT),
				CarryStock.new(world, FIELD, &"grain", MILL, &"grain", WorldTune.CARRY_RATE, "carrying grain"),
			] as Array[Step]),
			&"grain", MILLER_NAME, world.seconds,
			func() -> bool: return world.place_stat(MILL, &"grain") < WorldTune.GRAIN_STOCKED_AT)
		provider.assign_action(errand)
	)
