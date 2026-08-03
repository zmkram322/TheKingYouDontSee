extends SceneTree

# Headless proof scene for brain/action.gd + brain/decision_brain.gd +
# brain/character.gd, with no dependency on sim/ — these characters carry
# plain Dictionary stats, not a StatStore. One starting catalog, two
# characters seeded from it:
#   A) Berta can afford to eat and is hungriest -> eat wins on score.
#   B) Cole can't afford it -> eat isn't available, and rest (the best of what
#      is available) wins instead.
#   C) The two halves stay separate: ranking Cole's FULL list still picks eat,
#      proving highest_scoring never gates on its own.
#   D) Cole gets paid -> eat becomes available with nothing rebuilt, proving
#      availability is worked out fresh rather than fixed at birth.
#   E) Dropping and adding actions changes only the character it was done to —
#      characters are seeded from the same list but never share one array.
# The "why" table printed below is built here, by the caller, out of the same
# is_available/score methods — the brain carries no audit trail of its own.
# Usage: godot --headless --path tkyds-game --script res://tests/brain_smoke.gd

var _failures: Array[String] = []


func _initialize() -> void:
	# The starting catalog characters are seeded from. Actions are allowed to
	# know what a subject is — that's world-specific content — which is why
	# they can read subject.stats directly while the brain never does.
	var actions: Array[Action] = [
		Action.new("eat",
			func(who: Character) -> bool: return who.stats.coin >= 5,
			func(who: Character) -> float: return who.stats.hunger),
		Action.new("rest",
			func(_who: Character) -> bool: return true,
			func(who: Character) -> float: return 100.0 - who.stats.energy),
		Action.new("idle",
			func(_who: Character) -> bool: return true,
			func(_who: Character) -> float: return 5.0),
	]
	var eat: Action = actions[0]

	print("--- Berta: can afford to eat, hungriest ---")
	var berta := Character.new("Berta", {"hunger": 70.0, "energy": 40.0, "coin": 10}, actions)
	var berta_choice := berta.decide_action()
	_print_why(berta, berta_choice)
	_expect(berta_choice != null and berta_choice.label == "eat", "Berta should choose eat (got %s)" % _label_of(berta_choice))

	print("")
	print("--- Cole: can't afford to eat despite the higher score ---")
	var cole := Character.new("Cole", {"hunger": 70.0, "energy": 40.0, "coin": 0}, actions)
	var cole_choice := cole.decide_action()
	_print_why(cole, cole_choice)
	_expect(cole_choice != null and cole_choice.label == "rest", "Cole should choose rest (got %s)" % _label_of(cole_choice))
	_expect(not cole.brain.is_available(eat), "Cole should show eat as unavailable")
	_expect(not cole.brain.determine_available_actions(cole.actions).has(eat), "Cole's available actions should exclude eat")

	print("")
	print("--- the two halves stay separate ---")
	# Ranking the unfiltered list still picks eat: highest_scoring ranks
	# whatever it's handed and never gates. Availability is a separate step.
	var ungated := cole.brain.highest_scoring(cole.actions)
	_expect(ungated != null and ungated.label == "eat", "highest_scoring over the full list should still pick eat, gating nothing (got %s)" % _label_of(ungated))

	print("")
	print("--- Cole gets paid; nothing rebuilt ---")
	cole.stats.coin = 10
	var cole_paid := cole.decide_action()
	_print_why(cole, cole_paid)
	_expect(cole.brain.is_available(eat), "eat should become available once Cole has coin")
	_expect(cole_paid != null and cole_paid.label == "eat", "Cole should now choose eat (got %s)" % _label_of(cole_paid))

	print("")
	print("--- Cole forgets how to eat; Berta is untouched ---")
	cole.drop_action(eat)
	var cole_dropped := cole.decide_action()
	_print_why(cole, cole_dropped)
	_expect(not cole.has_action(eat), "Cole should no longer know eat")
	_expect(cole_dropped != null and cole_dropped.label == "rest", "Cole should fall back to rest (got %s)" % _label_of(cole_dropped))
	_expect(berta.has_action(eat), "Berta should still know eat after Cole dropped it")
	_expect(berta.decide_action().label == "eat", "Berta's choice should be unaffected by Cole's drop")

	print("")
	print("--- Cole learns something new; Berta still doesn't know it ---")
	var pray := Action.new("pray",
		func(_who: Character) -> bool: return true,
		func(_who: Character) -> float: return 90.0)
	cole.add_action(pray)
	cole.add_action(pray)   # adding twice must not stack a second copy
	var cole_learned := cole.decide_action()
	_print_why(cole, cole_learned)
	_expect(cole.actions.count(pray) == 1, "adding pray twice should leave exactly one copy")
	_expect(cole_learned != null and cole_learned.label == "pray", "Cole should choose pray, his new best (got %s)" % _label_of(cole_learned))
	_expect(not berta.has_action(pray), "Berta should not have gained pray from Cole")

	print("")
	if _failures.is_empty():
		print("=== brain smoke: OK ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== BRAIN SMOKE FAIL ===")
		quit(1)


func _print_why(who: Character, winner: Action) -> void:
	for action in who.actions:
		var marker := "->" if action == winner else "  "
		if who.brain.is_available(action):
			print("%s %6.1f  %s" % [marker, who.brain.score(action), action.label])
		else:
			print("%s    -   %s  (not available)" % [marker, action.label])


func _label_of(action: Action) -> String:
	return action.label if action != null else "(none)"


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)
