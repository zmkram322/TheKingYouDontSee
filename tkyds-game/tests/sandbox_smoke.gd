extends SceneTree

# Headless smoke test for the behavior sandbox: boot SandboxWorld, run it for
# 90 simulated seconds in 0.1s steps, and check the five staggered villagers
# each make their expected first choice, that eating and working both
# actually occur, and that nobody ends up stuck doing nothing.
# Usage: godot --headless --path tkyds-game --script res://tests/sandbox_smoke.gd

const STEP := 0.1
const DURATION := 90.0

var _failures: Array[String] = []


func _initialize() -> void:
	var world := SandboxWorld.new()
	world.reset()

	var seed_coin := {}       # villager name -> coin at spawn, to check someone got paid
	var first_choice := {}    # villager name -> id of the FIRST option they ever chose
	for v in world.villagers:
		seed_coin[v.actor.person_name] = int(world.stats.get_primary(v.actor, Stat.COIN))
		first_choice[v.actor.person_name] = &""

	var elapsed := 0.0
	while elapsed < DURATION:
		world.advance(STEP)
		elapsed += STEP
		for v in world.villagers:
			if first_choice[v.actor.person_name] == &"" and v.orchestrator.last_decision != null and v.orchestrator.last_decision.chosen != null:
				first_choice[v.actor.person_name] = v.orchestrator.last_decision.chosen.id

	# 1. Everyone has weighed in at least once.
	for v in world.villagers:
		_expect(v.orchestrator.last_decision != null, "%s should hold a non-null last_decision" % v.actor.person_name)

	# 2. The four staggered starting states each produce the expected first
	# choice — including Cole, whose eat_at_inn is pruned by the possession
	# gate rather than by score.
	_expect(first_choice.get("Berta") == &"eat_at_inn", "Berta's first choice should be eat_at_inn (got %s)" % String(first_choice.get("Berta")))
	_expect(first_choice.get("Cole") == &"work_field", "Cole's first choice should be work_field (got %s)" % String(first_choice.get("Cole")))
	_expect(first_choice.get("Dara") == &"rest_home", "Dara's first choice should be rest_home (got %s)" % String(first_choice.get("Dara")))
	_expect(first_choice.get("Edmun") == &"pass_time_well", "Edmun's first choice should be pass_time_well (got %s)" % String(first_choice.get("Edmun")))

	# 3. The loop actually completes doings, not just chooses them.
	var ate := false
	var worked := false
	for line in world.log_lines:
		if line.contains("finishes eating"):
			ate = true
		if line.contains("finishes working"):
			worked = true
	_expect(ate, "at least one villager should finish eating")
	_expect(worked, "at least one villager should finish working")

	var earned := false
	for v in world.villagers:
		var coin: int = world.stats.get_primary(v.actor, Stat.COIN)
		if coin > int(seed_coin[v.actor.person_name]):
			earned = true
			break
	_expect(earned, "at least one villager's coin should have grown above its seed (someone got paid)")

	# 4. Nobody is left with no Activity to run.
	for v in world.villagers:
		var goal := v.current_goal()
		_expect(goal != null and goal.root != null, "%s should not be stuck with no current goal" % v.actor.person_name)

	print("")
	print("--- last log lines ---")
	var start := maxi(0, world.log_lines.size() - 20)
	for i in range(start, world.log_lines.size()):
		print(world.log_lines[i])

	print("")
	if _failures.is_empty():
		print("=== sandbox smoke: OK ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== SANDBOX SMOKE FAIL ===")
		quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)
