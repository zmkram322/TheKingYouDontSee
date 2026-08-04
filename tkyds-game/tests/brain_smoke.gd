extends SceneTree

# Headless proof scene for brain/action.gd + brain/obligation.gd +
# brain/decision_brain.gd + brain/character.gd, with no dependency on sim/ —
# these characters carry plain Dictionary stats, not a StatStore.
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
#   7)   The peasant again, this time actually working: the order is carried
#        out to the end and leaves the queue by being done. Taking work on and
#        putting it down are separate proofs, and this is the second one.
#   8)   A protected action cannot be gated away, however hard its own gate
#        tries.
#   9)   Work already owed is recognised as owed, so nobody hands it over
#        twice.
#
# Usage: godot --headless --path tkyds-game --script res://tests/brain_smoke.gd

const SLICE := 0.05
const EXPECTED_CHECKS := 32   # a crash that skips assertions must not read as a pass

var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	_scoring_and_availability()
	_the_innkeeper()
	_the_peasant()
	_the_peasant_finishes()
	_protected_cannot_be_gated_away()
	_work_already_owed_is_recognised()

	if _checks < EXPECTED_CHECKS:
		_failures.append("only %d of %d checks ran — something bailed out early" % [_checks, EXPECTED_CHECKS])

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
			func(who: Character) -> float: return who.stats.hunger,
			Busy.new("eating")),
		Action.new("rest",
			func(_who: Character) -> bool: return true,
			func(who: Character) -> float: return 100.0 - who.stats.energy,
			Busy.new("resting")),
		Action.new("idle",
			func(_who: Character) -> bool: return true,
			func(_who: Character) -> float: return 5.0,
			Busy.new("idling")),
	]
	var eat: Action = actions[0]

	print("--- Berta: can afford to eat, hungriest ---")
	var berta := Character.new("Berta", {"hunger": 70.0, "energy": 40.0, "coin": 10}, actions)
	var berta_choice := berta.decide_action()
	_print_why(berta, berta_choice)
	_expect(berta_choice != null and berta_choice.label == "eat", "Berta should choose eat (got %s)" % _label_of(berta_choice))
	_expect(berta.active_action == berta_choice, "deciding should leave the winner as Berta's active action")

	print("")
	print("--- Cole: can't afford to eat despite the higher score ---")
	var cole := Character.new("Cole", {"hunger": 70.0, "energy": 40.0, "coin": 0}, actions)
	var cole_choice := cole.decide_action()
	_print_why(cole, cole_choice)
	_expect(cole_choice != null and cole_choice.label == "rest", "Cole should choose rest (got %s)" % _label_of(cole_choice))
	_expect(not cole.brain.is_available(cole, eat), "Cole should show eat as unavailable")

	print("")
	print("--- the two halves stay separate ---")
	# Ranking the unfiltered list still picks eat: highest_scoring ranks
	# whatever it's handed and never gates. Availability is a separate step.
	var ungated := cole.brain.highest_scoring(cole, cole.actions)
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
		func(_who: Character) -> float: return 90.0,
		Busy.new("praying"))
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
		func(who: Character) -> float: return 100.0 - who.stats.energy,
		Busy.new("dozing"))
	var flee := Action.new("flee out the back",
		func(_who: Character) -> bool: return true,
		func(who: Character) -> float: return 3.0 * who.stats.fear,
		Busy.new("running"))
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
	hal.assign_action(stew)
	hal.assign_action(pie)
	hal.assign_action(ale)
	var hal_busy := hal.decide_action()
	_print_why(hal, hal_busy)
	_expect(hal.assigned_count() == 3, "Hal should owe three orders")
	_expect(hal_busy == stew, "the most urgent order should win outright (got %s)" % _label_of(hal_busy))
	_expect(hal.queue.has(stew), "working on the stew must not take it out of the queue — owed and being-worked-on are separate facts")

	print("")
	print("--- someone kicks the door in ---")
	# Nothing grants fear special status. It simply outscores a full house.
	hal.stats.fear = 40.0
	var hal_scared := hal.decide_action()
	_print_why(hal, hal_scared)
	_expect(hal_scared == flee, "fear should outbid every waiting order (got %s)" % _label_of(hal_scared))
	_expect(hal.assigned_count() == 3, "all three orders should survive the interruption")

	print("")
	print("--- it passes; he picks the stew back up and finishes it ---")
	hal.stats.fear = 0.0
	_expect(hal.decide_action() == stew, "Hal should resume the stew with nothing re-queued and nothing restored")
	hal.clear_assigned_action(stew)
	var hal_after := hal.decide_action()
	_print_why(hal, hal_after)
	_expect(hal.assigned_count() == 2, "discharging the stew should leave two orders")
	_expect(hal_after == pie, "the next most urgent order should take over (got %s)" % _label_of(hal_after))


# --- Exhaustion outbidding a lord --------------------------------------------

func _the_peasant() -> void:
	var tam := _tam()
	var plough: Obligation = tam.queue[0]

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
	_expect(tam_spent != null and tam_spent.label == "sleep", "exhaustion should outbid the lord's order (got %s)" % _label_of(tam_spent))
	_expect(tam.queue.has(plough), "the field is still owed while he sleeps")

	print("")
	print("--- rested, and it's still owed ---")
	tam.stats.energy = 100.0
	var tam_rested := tam.decide_action()
	_print_why(tam, tam_rested)
	_expect(tam_rested == plough, "he should go back to the field on waking (got %s)" % _label_of(tam_rested))


# --- Putting the work down again ---------------------------------------------

# The scene above proves an obligation can be taken on and outbid. It does not
# prove it can ever be finished, which is the harder half: an obligation that
# can be owed and never discharged grows the queue without bound. So here Tam
# actually ploughs, and the debt goes away by being paid rather than by being
# called off.
func _the_peasant_finishes() -> void:
	print("")
	print("--- Tam works the field to the end ---")
	var tam := _tam()
	var plough: Obligation = tam.queue[0]

	tam.act(SLICE)
	_expect(tam.active_action == plough, "he should be at the field (got %s)" % _label_of(tam.active_action))
	print("  doing: %s" % tam.doing_label())

	var worked := 0.0
	while worked < 20.0 and tam.assigned_count() > 0:
		tam.act(SLICE)
		worked += SLICE

	print("  after %.1fs the field is %.0f%% ploughed" % [worked, tam.stats.ploughed])
	_expect(tam.stats.ploughed >= 100.0, "the field should actually get ploughed (got %.0f)" % tam.stats.ploughed)
	_expect(tam.assigned_count() == 0, "finishing the work should settle the debt")
	_expect(tam.active_action != plough, "he should not still be pursuing a discharged order")


# --- The protected set --------------------------------------------------------

# FR86: a handful of survival and direct interpersonal actions are open to
# everyone, always. The guarantee has to be structural — a convention loses to
# whoever writes the one gate that seems reasonable at the time.
func _protected_cannot_be_gated_away() -> void:
	print("")
	print("--- a guard who has been authored unable to run ---")
	var hold := Action.new("hold the post",
		func(_who: Character) -> bool: return true,
		func(_who: Character) -> float: return 10.0,
		Busy.new("holding the post"))
	# The gate says never, in as many words. Being protected outranks it.
	var flee := Action.new("flee",
		func(_who: Character) -> bool: return false,
		func(who: Character) -> float: return 3.0 * who.stats.fear,
		Busy.new("running")).always_available()
	var known: Array[Action] = [hold, flee]
	var guard := Character.new("Guard", {"fear": 0.0}, known)

	var calm := guard.decide_action()
	_print_why(guard, calm)
	_expect(guard.brain.is_available(guard, flee), "a protected action must stay available however its gate is written")
	_expect(calm == hold, "with nothing to fear he should hold the post (got %s)" % _label_of(calm))

	print("")
	print("--- and then something worth running from ---")
	guard.stats.fear = 40.0
	var scared := guard.decide_action()
	_print_why(guard, scared)
	# Protected buys a place in the pass, not a win. It still has to outbid.
	_expect(scared == flee, "fear should be able to outbid the post (got %s)" % _label_of(scared))
	_expect(not hold.protected and flee.protected, "only the marked action should be protected")


# --- Recognising work that is already owed ------------------------------------

# An Action is a label and two anonymous callables, so the only way to find one
# again is to have kept hold of it. An Obligation says what it's about, which
# is what lets whoever hands work over ask whether it is already owed instead
# of remembering that they asked.
func _work_already_owed_is_recognised() -> void:
	print("")
	print("--- the same errand, asked for twice ---")
	var tam := _tam()

	_expect(tam.owes_anything_about(&"plough the north field"), "the field should read as owed")
	_expect(not tam.owes_anything_about(&"mend the fence"), "work nobody asked for should not read as owed")

	var found := tam.find_obligation_about(&"plough the north field")
	_expect(found != null and found.asked_by == "the lord", "the obligation should still know who asked (got %s)" % (found.asked_by if found != null else "nothing"))
	_expect(found == tam.queue[0], "matching on what it's about should find the very obligation that was handed over")


# --- Helpers -----------------------------------------------------------------

# Work handed over from outside. It's an ordinary Action in every way that
# matters — it just lives in the queue instead of in what the character knows,
# and is therefore remembered when it loses rather than regenerated by scoring
# like a need would be.
func _order(label: String, worth: float) -> Obligation:
	return Obligation.new(label,
		func(_who: Character) -> bool: return true,
		func(_who: Character) -> float: return worth,
		Busy.new(label),
		StringName(label), "the lord")


func _tam() -> Character:
	var sleep := Action.new("sleep",
		func(_who: Character) -> bool: return true,
		func(who: Character) -> float: return 100.0 - who.stats.energy,
		Busy.new("sleeping"))
	var known: Array[Action] = [sleep]
	var tam := Character.new("Tam", {"energy": 100.0, "ploughed": 0.0}, known)

	# The lord's claim is expressed as a high score, not as a position in a
	# list. That's exactly what lets a real need beat it without deleting it.
	var plough := Obligation.new("plough the north field",
		func(_who: Character) -> bool: return true,
		func(_who: Character) -> float: return 80.0,
		Ploughing.new(),
		&"plough the north field", "the lord")
	tam.assign_action(plough)
	return tam


func _print_why(who: Character, winner: Action) -> void:
	for action in who.candidate_actions():
		var marker := "->" if action == winner else "  "
		var owed := "   (owed)" if who.queue.has(action) else ""
		if who.brain.is_available(who, action):
			print("%s %6.1f  %s%s" % [marker, who.brain.score(who, action), action.label, owed])
		else:
			print("%s    -   %s  (not available)%s" % [marker, action.label, owed])


func _label_of(action: Action) -> String:
	return action.label if action != null else "(none)"


func _expect(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)


# --- Leaves used by this scene ------------------------------------------------

# Work that takes time and changes nothing the world can see. Stands in for the
# body of an action this scene only ever scores — it is never satisfied, so a
# character who picks it simply keeps at it.
class Busy:
	extends Step

	var what: String

	func _init(new_what: String = "busy") -> void:
		what = new_what

	func is_satisfied(_who) -> bool:
		return false

	func advance(_who, _delta: float) -> bool:
		return false

	func describe(_who) -> String:
		return what


# Real work, with its progress kept where progress belongs: on the field, not
# in the Step. Satisfaction is re-derived from that — hand this Step to a
# second peasant and it reads their field, not this one's.
class Ploughing:
	extends Step

	const RATE := 25.0   # percent of the field turned per second

	func is_satisfied(who) -> bool:
		return who.stats.ploughed >= 100.0

	func advance(who, delta: float) -> bool:
		who.stats.ploughed = minf(100.0, who.stats.ploughed + RATE * delta)
		return is_satisfied(who)

	func describe(who) -> String:
		return "ploughing the north field (%.0f%%)" % who.stats.ploughed
