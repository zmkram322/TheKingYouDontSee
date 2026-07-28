extends SceneTree

# The proving scene, headless, all three branches:
#   invest_tam    — the right investment: Tam's channel pays out; Kestrel backs off
#   invest_corwin — the wrong investment: money in a hole; Aldric yields
#   no_invest     — no investment: nobody moves; Aldric yields
# Usage: godot --headless --path . --script res://tests/headless_scene.gd -- <branch>

const TICKS := 24

func _initialize() -> void:
	var branch := "invest_tam"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		branch = args[0]

	var sim := Simulation.new()
	sim.reset()
	var tam := _find(sim, "Tam")
	var corwin := _find(sim, "Corwin")
	var kestrel := _find(sim, "Kestrel")
	var invest_target: Actor = null
	match branch:
		"invest_tam":
			invest_target = tam
		"invest_corwin":
			invest_target = corwin

	for t in range(1, TICKS + 1):
		if t == 6:
			sim.queue_intent(&"go_to", &"pub")
		if t == 8 and invest_target != null:
			sim.queue_intent(&"share_drink", invest_target)
		sim.advance_one_tick()
		if t == 7:
			# The reading beat: LOOK is free observation, GREET reads the rung.
			sim.look(tam)
			sim.look(corwin)
			sim.look(kestrel)
			sim.greet(tam)
			sim.greet(corwin)
		if t == 9 and invest_target != null:
			sim.greet(invest_target)   # the delta: a rung earned, previous rung kept

	for line in sim.log_lines:
		print(line)

	var log_text := "\n".join(sim.log_lines)
	var failures: Array[String] = []
	match branch:
		"invest_tam":
			_expect(failures, log_text.contains("puts himself between"), "Tam should visibly intervene")
			_expect(failures, log_text.contains("backs off"), "Kestrel should re-read the room and back off")
			_expect(failures, not log_text.contains("Aldric yields"), "Aldric should NOT yield")
			_expect(failures, log_text.contains("watching, not yet moved"), "Tam's hesitation should be visible before he moves")
		"invest_corwin", "no_invest":
			_expect(failures, log_text.contains("Aldric yields"), "Aldric should yield — the fail branch must actually fail")
			_expect(failures, not log_text.contains("puts himself between"), "nobody should intervene")
		_:
			failures.append("unknown branch '%s'" % branch)

	print("")
	if failures.is_empty():
		print("=== SCENE PASS (%s) ===" % branch)
		quit(0)
	else:
		for f in failures:
			print("FAIL: %s" % f)
		print("=== SCENE FAIL (%s) ===" % branch)
		quit(1)


func _expect(failures: Array[String], ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)


func _find(sim: Simulation, name: String) -> Actor:
	for a in sim.actors:
		if a.person_name == name:
			return a
	return null
