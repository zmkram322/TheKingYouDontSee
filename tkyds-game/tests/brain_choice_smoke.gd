extends SceneTree

# Headless proof scene for brain/choice.gd — a decision nested inside a plan.
#
# Berta knows one thing: "get some food". Where that food comes from isn't
# written into the plan at all; a Choice asks the world at the moment she needs
# it. Three inns, and the nearest one is deliberately the one she can't afford:
#
#     Golden Swan    60 away, costs 10   <- nearest, and out of reach
#     Green Dragon  120 away, costs 3
#     Boar's Head   300 away, costs 2
#
#   1) She walks past the Swan she can't afford to the Dragon she can, then
#      eats until she isn't hungry — a Choice picking, a Sequence carrying it
#      out, and the whole nested tree settling.
#   2) The generator hands back the same Action objects each pass, so what
#      she's pursuing doesn't churn identity underneath her.
#   3) The Dragon closes while she's walking to it. Nothing is torn down and
#      nothing restarts: the next tick simply re-ranks, the Boar's Head wins,
#      and she turns for it from exactly where she's standing.
#   4) Every inn closes while she is under orders to fetch supper. Being unable
#      to get on with work is not the same as having done it: the errand stays
#      owed, she stays hungry, and when a door opens again she finishes it.
#
# Usage: godot --headless --path tkyds-game --script res://tests/brain_choice_smoke.gd

const SLICE := 0.05
const EXPECTED_CHECKS := 17

var _failures: Array[String] = []
var _checks := 0

# The world. Plain data — the generator queries it, nothing else knows it.
var _inns := []
var _built: Dictionary = {}   # inn name -> Action, so identity stays stable


func _initialize() -> void:
	_walks_past_what_she_cannot_afford()
	_generator_keeps_identity_stable()
	_reroutes_when_the_inn_closes()
	_thwarted_is_not_finished()

	if _checks < EXPECTED_CHECKS:
		_failures.append("only %d of %d checks ran — something bailed out early" % [_checks, EXPECTED_CHECKS])

	print("")
	if _failures.is_empty():
		print("=== brain choice smoke: OK ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== BRAIN CHOICE SMOKE FAIL ===")
		quit(1)


# --- 1. Nearest isn't a rule, it's a score -----------------------------------

func _walks_past_what_she_cannot_afford() -> void:
	print("--- Berta is hungry, and three inns are open ---")
	_reset_world()
	var berta := _hungry_someone(Vector2.ZERO, 5)

	print("  starts at %s, doing: %s" % [_at(berta), berta.doing_label()])
	var fed := _act_until(berta, func() -> bool: return berta.stats.hunger <= 0.0, 30.0)
	print("  ends at %s, hunger %.0f" % [_at(berta), berta.stats.hunger])

	_expect(fed, "Berta should end up fed")
	_expect(berta.stats.position.distance_to(_where("Green Dragon")) <= 4.0, "she should have eaten at the Green Dragon — nearest of the ones she can afford")
	_expect(berta.stats.position.distance_to(_where("Golden Swan")) > 4.0, "she should not have gone to the Golden Swan she can't afford, despite it being closest")
	# Fed, so "get some food" is off her menu and she pursues nothing.
	_expect(berta.brain.active_action == null, "once fed she should be pursuing nothing")


# --- 2. Generated options must not churn identity ----------------------------

func _generator_keeps_identity_stable() -> void:
	print("")
	print("--- asking the world twice gives the same options back ---")
	_reset_world()
	var berta := _hungry_someone(Vector2.ZERO, 5)

	var first: Array[Action] = _food_options(berta)
	var second: Array[Action] = _food_options(berta)

	_expect(first.size() == 3, "all three inns should be offered before gating (got %d)" % first.size())
	_expect(first[0] == second[0] and first[1] == second[1], "the same inn should yield the same Action object each pass")
	# Gating happens after generation — the Swan is offered, then ruled out.
	var open_to_her := berta.brain.determine_available_actions(first)
	_expect(open_to_her.size() == 2, "only two of the three should be open to her (got %d)" % open_to_her.size())


# --- 3. Re-deriving a nested decision ----------------------------------------

func _reroutes_when_the_inn_closes() -> void:
	print("")
	print("--- the Green Dragon closes while she's on her way ---")
	_reset_world()
	var berta := _hungry_someone(Vector2.ZERO, 5)

	_act_until(berta, func() -> bool: return berta.stats.position.x >= 60.0, 10.0)
	var when_it_closed: Vector2 = berta.stats.position
	print("  on her way: %s, doing: %s" % [_at(berta), berta.doing_label()])
	_expect(berta.doing_label().contains("Green Dragon"), "she should be heading for the Dragon before it closes")

	_close("Green Dragon")
	berta.act(SLICE)
	print("  it closes — now doing: %s" % berta.doing_label())
	_expect(berta.doing_label().contains("Boar's Head"), "the next tick should re-rank to the Boar's Head")

	var fed := _act_until(berta, func() -> bool: return berta.stats.hunger <= 0.0, 30.0)
	print("  ends at %s, hunger %.0f" % [_at(berta), berta.stats.hunger])
	_expect(fed, "she should still end up fed")
	_expect(berta.stats.position.distance_to(_where("Boar's Head")) <= 4.0, "she should have eaten at the Boar's Head")
	_expect(when_it_closed.x > 0.0, "she should genuinely have been partway to the Dragon when it closed")
	_expect(berta.brain.active_action != null or berta.stats.hunger <= 0.0, "she should never have been left stuck with nothing to pursue")


# --- 4. Being unable to is not the same as being done -------------------------

# The sharpest version of the failure, because a debt is involved. Berta has
# been told to fetch supper; then every inn in the region shuts. A Choice with
# nothing to pick used to report itself satisfied, which read as the errand
# being finished — so the order was struck off having never been carried out,
# and nothing anywhere said so.
func _thwarted_is_not_finished() -> void:
	print("")
	print("--- Berta is sent for supper, and then every door shuts ---")
	_reset_world()
	var berta := _hungry_someone(Vector2.ZERO, 5)
	var errand := Obligation.new("fetch supper",
		func(_who: Character) -> bool: return true,
		func(_who: Character) -> float: return 90.0,
		Choice.new(_food_options),
		&"supper", "the innkeeper")
	berta.brain.assign_action(errand)

	berta.act(SLICE)
	_expect(berta.brain.active_action == errand, "she should set about the errand first, it outscores her own hunger")

	for inn in _inns:
		inn.open = false
	var hunger_when_shut: float = berta.stats.hunger
	var moved_to: Vector2 = berta.stats.position

	for i in 20:
		berta.act(SLICE)

	print("  every inn shut — owes %d, hunger %.0f, doing: %s" % [berta.brain.assigned_count(), berta.stats.hunger, berta.doing_label()])
	_expect(berta.brain.assigned_count() == 1, "the errand must still be owed — she never carried it out")
	_expect(berta.stats.hunger >= hunger_when_shut, "she should not have been fed by an inn that is shut")
	_expect(berta.stats.position.distance_to(moved_to) < 1.0, "with nowhere to go she should not be walking anywhere")

	print("")
	print("--- the Boar's Head opens up again ---")
	for inn in _inns:
		if inn.name == "Boar's Head":
			inn.open = true
	var fed := _act_until(berta, func() -> bool: return berta.stats.hunger <= 0.0, 30.0)
	print("  ends at %s, hunger %.0f, owes %d" % [_at(berta), berta.stats.hunger, berta.brain.assigned_count()])
	_expect(fed, "she should get her supper once somewhere will serve her")
	_expect(berta.brain.assigned_count() == 0, "carrying the errand out should settle it")
	_expect(berta.stats.position.distance_to(_where("Boar's Head")) <= 4.0, "she should have gone to the one inn that reopened")


# --- The world ----------------------------------------------------------------

func _reset_world() -> void:
	_built.clear()
	_inns = [
		{"name": "Golden Swan", "at": Vector2(60, 0), "price": 10, "open": true},
		{"name": "Green Dragon", "at": Vector2(120, 0), "price": 3, "open": true},
		{"name": "Boar's Head", "at": Vector2(0, 300), "price": 2, "open": true},
	]


func _where(inn_name: String) -> Vector2:
	for inn in _inns:
		if inn.name == inn_name:
			return inn.at
	return Vector2.ZERO


func _close(inn_name: String) -> void:
	for inn in _inns:
		if inn.name == inn_name:
			inn.open = false


# The generator: a world query and nothing more. It offers every inn — being
# shut or unaffordable is a gate, not a reason to withhold the option, so a
# desperate enough character could still be authored to consider them.
func _food_options(_who: Character) -> Array[Action]:
	var offered: Array[Action] = []
	for inn in _inns:
		offered.append(_eat_at(inn))
	return offered


# Memoised per inn: the same inn always yields the same Action object, so
# active_action doesn't change identity underneath the character every tick.
func _eat_at(inn: Dictionary) -> Action:
	if _built.has(inn.name):
		return _built[inn.name]
	var action := Action.new("eat at the %s" % inn.name,
		func(who: Character) -> bool: return inn.open and who.stats.coin >= inn.price,
		func(who: Character) -> float: return 400.0 - who.stats.position.distance_to(inn.at),
		Sequence.new([WalkTo.new(inn.at), Eat.new()] as Array[Step]))
	_built[inn.name] = action
	return action


# --- A leaf that eats ---------------------------------------------------------

# World-specific content, so it lives here rather than in brain/. Satisfaction
# is a plain fact about the character — no timer, nothing stored.
class Eat:
	extends Step

	const RATE := 40.0   # hunger cleared per second

	func is_satisfied(who) -> bool:
		return who.stats.hunger <= 0.0

	func advance(who, delta: float) -> bool:
		who.stats.hunger = maxf(0.0, who.stats.hunger - RATE * delta)
		return is_satisfied(who)

	func describe(_who) -> String:
		return "eating"


# --- Helpers -----------------------------------------------------------------

func _hungry_someone(where: Vector2, coin: int) -> Character:
	var get_food := Action.new("get some food",
		func(who: Character) -> bool: return who.stats.hunger > 0.0,
		func(who: Character) -> float: return who.stats.hunger,
		Choice.new(_food_options))
	var knows: Array[Action] = [get_food]
	return Character.new("Berta", {"position": where, "hunger": 60.0, "coin": coin}, knows)


func _act_until(who: Character, done: Callable, limit: float) -> bool:
	var elapsed := 0.0
	while elapsed < limit:
		who.act(SLICE)
		elapsed += SLICE
		if done.call():
			return true
	return false


func _at(who: Character) -> String:
	return "(%.0f, %.0f)" % [who.stats.position.x, who.stats.position.y]


func _expect(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)
