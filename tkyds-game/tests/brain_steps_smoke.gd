extends SceneTree

# Headless proof scene for brick one of the runner: brain/step.gd,
# brain/sequence.gd, brain/walk_to.gd, and Character.act().
#
#   1) Berta walks home and stops pursuing it once she's there.
#   2) Two characters share the SAME Action and Step objects and still make
#      independent progress — the proof that a Step stores nothing about who
#      is doing it.
#   3) Berta is frightened halfway home, bolts for the woods, and when it
#      passes she carries on from where she's standing. Nothing was suspended
#      and nothing restored: the walk simply re-asks "am I home yet?" and the
#      answer is still no.
#
# Usage: godot --headless --path tkyds-game --script res://tests/brain_steps_smoke.gd

const SLICE := 0.05          # seconds per act() call
const HOME := Vector2(300, 0)
const WOODS := Vector2(0, -220)
const ARRIVED := 4.0         # matches WalkTo.ARRIVE_EPSILON

const EXPECTED_CHECKS := 12   # a crash that skips assertions must not read as a pass

var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	_walks_home()
	_steps_are_shareable()
	_frightened_then_carries_on()

	if _checks < EXPECTED_CHECKS:
		_failures.append("only %d of %d checks ran — something bailed out early" % [_checks, EXPECTED_CHECKS])

	print("")
	if _failures.is_empty():
		print("=== brain steps smoke: OK ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== BRAIN STEPS SMOKE FAIL ===")
		quit(1)


# --- 1. Getting there --------------------------------------------------------

func _walks_home() -> void:
	print("--- Berta walks home ---")
	var go_home := _go_home()
	var berta := _someone("Berta", Vector2.ZERO, [go_home])

	print("  starts at %s, doing: %s" % [_at(berta), berta.doing_label()])
	var arrived := _act_until(berta, func() -> bool: return go_home.body.is_satisfied(berta), 20.0)
	print("  ends at %s" % _at(berta))

	_expect(arrived, "Berta should reach home")
	_expect(berta.stats.position.distance_to(HOME) <= ARRIVED, "she should be standing at home")
	# Her gate is "not already home", so once she is, there's nothing open to
	# her at all and she stops pursuing anything.
	_expect(berta.active_action == null, "having arrived, she should no longer be pursuing going home")


# --- 2. One Step, many characters --------------------------------------------

func _steps_are_shareable() -> void:
	print("")
	print("--- two characters, the very same Action and Step objects ---")
	# Built once. If a Step held progress, these two would corrupt each other.
	var go_home := _go_home()
	var far := _someone("Far", Vector2.ZERO, [go_home])
	var near := _someone("Near", Vector2(150, 0), [go_home])

	var near_arrived_at := -1.0
	var far_arrived_at := -1.0
	var elapsed := 0.0
	while elapsed < 20.0 and (near_arrived_at < 0.0 or far_arrived_at < 0.0):
		far.act(SLICE)
		near.act(SLICE)
		elapsed += SLICE
		if near_arrived_at < 0.0 and near.stats.position.distance_to(HOME) <= ARRIVED:
			near_arrived_at = elapsed
		if far_arrived_at < 0.0 and far.stats.position.distance_to(HOME) <= ARRIVED:
			far_arrived_at = elapsed

	print("  Near started 150 away, arrived at t=%.2fs" % near_arrived_at)
	print("  Far  started 300 away, arrived at t=%.2fs" % far_arrived_at)

	_expect(far.actions[0] == near.actions[0], "both should be holding the identical Action object")
	_expect(near_arrived_at > 0.0 and far_arrived_at > 0.0, "both should arrive")
	_expect(near_arrived_at < far_arrived_at, "the nearer one should arrive first — shared Steps must not pool progress")


# --- 3. Interrupted, and carrying on -----------------------------------------

func _frightened_then_carries_on() -> void:
	print("")
	print("--- Berta is frightened halfway home ---")
	var go_home := _go_home()
	var flee := Action.new("flee to the woods",
		func(_who: Character) -> bool: return true,
		func(who: Character) -> float: return 3.0 * who.stats.fear,
		Sequence.new([WalkTo.new(WOODS)] as Array[Step]))
	var berta := _someone("Berta", Vector2.ZERO, [go_home, flee])

	var started_from: Vector2 = berta.stats.position
	_act_until(berta, func() -> bool: return berta.stats.position.x >= 120.0, 10.0)
	var when_frightened: Vector2 = berta.stats.position
	print("  got as far as %s, doing: %s" % [_at(berta), berta.doing_label()])
	_expect(berta.active_action == go_home, "she should be heading home before the fright")

	berta.stats.fear = 40.0
	berta.decide_action()
	print("  something moves in the hedge — now doing: %s" % berta.doing_label())
	_expect(berta.active_action == flee, "fear should outbid going home")

	_act_until(berta, func() -> bool: return berta.stats.position.y <= -60.0, 5.0)
	print("  bolted to %s" % _at(berta))
	# Nothing had to be told the walk was unfinished. It re-derives that from
	# where she is standing, and would say the same if she'd been carried here.
	_expect(not go_home.body.is_satisfied(berta), "the walk home should still read as unfinished, purely from where she is")

	berta.stats.fear = 0.0
	berta.decide_action()
	var resumed_from: Vector2 = berta.stats.position
	print("  it passes — resuming from %s, doing: %s" % [_at(berta), berta.doing_label()])
	_expect(berta.active_action == go_home, "she should go back to heading home")
	_expect(resumed_from.distance_to(started_from) > 100.0, "she should carry on from where she stands, not restart from where she set off")
	_expect(when_frightened.x > 0.0, "the fright should genuinely have caught her partway")

	var arrived := _act_until(berta, func() -> bool: return go_home.body.is_satisfied(berta), 20.0)
	print("  ends at %s" % _at(berta))
	_expect(arrived, "she should still get home after the detour")


# --- Helpers -----------------------------------------------------------------

# Going home is only worth choosing while she isn't there — an action whose
# work is already done shouldn't be on the menu. Expressed as its own gate
# rather than built into the brain, same as every other bit of judgment.
func _go_home() -> Action:
	return Action.new("go home",
		func(who: Character) -> bool: return who.stats.position.distance_to(HOME) > ARRIVED,
		func(_who: Character) -> float: return 50.0,
		Sequence.new([WalkTo.new(HOME)] as Array[Step]))


func _someone(who_name: String, where: Vector2, knows: Array[Action]) -> Character:
	return Character.new(who_name, {"position": where, "fear": 0.0}, knows)


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
