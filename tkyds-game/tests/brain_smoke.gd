extends SceneTree

# Headless proof scene for brain/action.gd + brain/decision_brain.gd +
# brain/character.gd, with no dependency on sim/ — these characters carry
# plain Dictionary stats, not a StatStore.
#
#   1-3) Berta & Cole: scoring, the availability gate pruning a would-be
#        winner, the two halves staying separate, and availability being
#        re-derived rather than fixed at birth.
#   4)   Per-character lists: dropping and learning affects only who it was
#        done to, though both were seeded from one catalog.
#   5)   Hal the innkeeper: obligations compete directly against needs, an
#        emergency outbids a full house without the orders being lost, and a
#        queued action stays owed while it's being worked on.
#   6)   The peasant: exhaustion outbids a lord's order, and the order is
#        still owed when he wakes.
#
# Usage: godot --headless --path tkyds-game --script res://tests/brain_smoke.gd

var _failures: Array[String] = []


func _initialize() -> void:
	_scoring_and_availability()
	_the_innkeeper()
	_the_peasant()

	print("")
	if _failures.is_empty():
		print("=== brain smoke: OK ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== BRAIN SMOKE FAIL ===")
		quit(1)


# --- Scoring, availability, and per-character lists --------------------------

func _scoring_and_availability() -> void:
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
	_expect(berta.brain.active_action == berta_choice, "deciding should leave the winner as Berta's active action")

	print("")
	print("--- Cole: can't afford to eat despite the higher score ---")
	var cole := Character.new("Cole", {"hunger": 70.0, "energy": 40.0, "coin": 0}, actions)
	var cole_choice := cole.decide_action()
	_print_why(cole, cole_choice)
	_expect(cole_choice != null and cole_choice.label == "rest", "Cole should choose rest (got %s)" % _label_of(cole_choice))
	_expect(not cole.brain.is_available(eat), "Cole should show eat as unavailable")

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
	_expect(cole_paid != null and cole_paid.label == "eat", "Cole should now choose eat (got %s)" % _label_of(cole_paid))

	print("")
	print("--- Cole forgets how to eat, and learns to pray; Berta is untouched ---")
	var pray := Action.new("pray",
		func(_who: Character) -> bool: return true,
		func(_who: Character) -> float: return 90.0)
	cole.drop_action(eat)
	cole.add_action(pray)
	cole.add_action(pray)   # adding twice must not stack a second copy
	var cole_learned := cole.decide_action()
	_print_why(cole, cole_learned)
	_expect(cole.actions.count(pray) == 1, "adding pray twice should leave exactly one copy")
	_expect(cole_learned != null and cole_learned.label == "pray", "Cole should choose pray, his new best (got %s)" % _label_of(cole_learned))
	_expect(berta.has_action(eat) and not berta.has_action(pray), "Berta should still know eat and never have gained pray")
	_expect(berta.decide_action().label == "eat", "Berta's choice should be unaffected by Cole's changes")


# --- Obligations competing directly ------------------------------------------

func _the_innkeeper() -> void:
	# Hal knows only how to doze and how to run. Orders are not a capability he
	# has — they're work handed to him, and they compete on their own merits.
	var doze := Action.new("doze by the fire",
		func(_who: Character) -> bool: return true,
		func(who: Character) -> float: return 100.0 - who.stats.energy)
	var flee := Action.new("flee out the back",
		func(_who: Character) -> bool: return true,
		func(who: Character) -> float: return 3.0 * who.stats.fear)
	var known: Array[Action] = [doze, flee]
	var hal := Character.new("Hal", {"energy": 90.0, "fear": 0.0}, known)

	print("")
	print("--- Hal the innkeeper: nothing owed yet ---")
	var hal_idle := hal.decide_action()
	_print_why(hal, hal_idle)
	_expect(hal_idle != null and hal_idle.label == "doze by the fire", "with nothing owed Hal should doze (got %s)" % _label_of(hal_idle))

	print("")
	print("--- three orders come in, each worth its own urgency ---")
	var stew := _order("stew for table four", 25.0)
	var pie := _order("pie for the traveller", 22.0)
	var ale := _order("ale for the corner", 20.0)
	hal.brain.assign_action(stew)
	hal.brain.assign_action(pie)
	hal.brain.assign_action(ale)
	var hal_busy := hal.decide_action()
	_print_why(hal, hal_busy)
	_expect(hal.brain.assigned_count() == 3, "Hal should owe three orders")
	_expect(hal_busy == stew, "the most urgent order should win outright (got %s)" % _label_of(hal_busy))
	_expect(hal.brain.queue.has(stew), "working on the stew must not take it out of the queue — owed and being-worked-on are separate facts")

	print("")
	print("--- someone kicks the door in ---")
	# Nothing grants fear special status. It simply outscores a full house.
	hal.stats.fear = 40.0
	var hal_scared := hal.decide_action()
	_print_why(hal, hal_scared)
	_expect(hal_scared == flee, "fear should outbid every waiting order (got %s)" % _label_of(hal_scared))
	_expect(hal.brain.assigned_count() == 3, "all three orders should survive the interruption")

	print("")
	print("--- it passes; he picks the stew back up and finishes it ---")
	hal.stats.fear = 0.0
	_expect(hal.decide_action() == stew, "Hal should resume the stew with nothing re-queued and nothing restored")
	hal.brain.clear_assigned_action(stew)
	var hal_after := hal.decide_action()
	_print_why(hal, hal_after)
	_expect(hal.brain.assigned_count() == 2, "discharging the stew should leave two orders")
	_expect(hal_after == pie, "the next most urgent order should take over (got %s)" % _label_of(hal_after))


# --- Exhaustion outbidding a lord --------------------------------------------

func _the_peasant() -> void:
	var sleep := Action.new("sleep",
		func(_who: Character) -> bool: return true,
		func(who: Character) -> float: return 100.0 - who.stats.energy)
	var known: Array[Action] = [sleep]
	var tam := Character.new("Tam", {"energy": 60.0}, known)

	# The lord's claim is expressed as a high score, not as a position in a
	# list. That's exactly what lets a real need beat it without deleting it.
	var plough := _order("plough the north field", 80.0)
	tam.brain.assign_action(plough)

	print("")
	print("--- Tam has a lord's order and energy to spare ---")
	var tam_working := tam.decide_action()
	_print_why(tam, tam_working)
	_expect(tam_working == plough, "a rested Tam should work the field (got %s)" % _label_of(tam_working))

	print("")
	print("--- worked to the bone ---")
	tam.stats.energy = 5.0
	var tam_spent := tam.decide_action()
	_print_why(tam, tam_spent)
	_expect(tam_spent == sleep, "exhaustion should outbid the lord's order (got %s)" % _label_of(tam_spent))
	_expect(tam.brain.queue.has(plough), "the field is still owed while he sleeps")

	print("")
	print("--- rested, and it's still owed ---")
	tam.stats.energy = 100.0
	var tam_rested := tam.decide_action()
	_print_why(tam, tam_rested)
	_expect(tam_rested == plough, "he should go back to the field on waking (got %s)" % _label_of(tam_rested))


# --- Helpers -----------------------------------------------------------------

# Work handed over from outside. It's an ordinary Action — it just lives in the
# queue instead of in what the character knows, and is therefore remembered
# when it loses rather than regenerated by scoring like a need would be.
func _order(label: String, worth: float) -> Action:
	return Action.new(label,
		func(_who: Character) -> bool: return true,
		func(_who: Character) -> float: return worth)


func _print_why(who: Character, winner: Action) -> void:
	for action in who.brain.candidate_actions(who.actions):
		var marker := "->" if action == winner else "  "
		var owed := "   (owed)" if who.brain.queue.has(action) else ""
		if who.brain.is_available(action):
			print("%s %6.1f  %s%s" % [marker, who.brain.score(action), action.label, owed])
		else:
			print("%s    -   %s  (not available)%s" % [marker, action.label, owed])


func _label_of(action: Action) -> String:
	return action.label if action != null else "(none)"


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)
