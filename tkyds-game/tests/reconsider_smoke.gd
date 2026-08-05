extends SceneTree

# Headless proof scene for the reconsider seam and Action.interrupt_threshold,
# added to world/world.gd and brain/action.gd, brain/decision_brain.gd,
# brain/character.gd.
#
# What's being proven, in order:
#
#   1) Without resistance, a score that falls as it's pursued genuinely
#      livelocks: eating drains the hunger it's scored on, so mid-meal it
#      weakens, gossip (a flat score) overtakes it, and — because gossiping
#      lets hunger drift back up — eating overtakes gossip again a moment
#      later. Under the sweep alone this produces real, repeated swapping and
#      a character who never once reaches satisfied. This is demonstrated,
#      not asserted from authority: the test tracks the actual swap count and
#      the actual minimum hunger reached.
#   2) The same two actions, with the meal's interrupt_threshold raised above
#      gossip's score. Now, once the meal is incumbent, gossip can never clear
#      the bar — and the meal finishes.
#   3) A flee-shaped protected action, threshold 0, exercised through
#      world.reconsider() directly — playing the part of the "event-driven
#      poke" the brief for this seam describes. It seizes control the instant
#      fear spikes, and is dropped the instant fear passes and work outscores
#      it again — because with threshold 0 it is exactly as easy to unseat as
#      any ordinary action; being protected only guarantees it's on the ballot.
#   4) The sweep's coverage: several characters, several actions each that
#      never finish and never become impossible, so nothing but the sweep
#      could ever change anyone's mind. A stat is changed behind their back —
#      no action, no event, no hand-poked decide_action() — and within one
#      reconsider window everyone has independently noticed and switched.
#
# Usage: godot --headless --path tkyds-game --script res://tests/reconsider_smoke.gd

const SLICE := 0.05
const EXPECTED_CHECKS := 8

const GOSSIP_SCORE := 30.0     # flat — gossip's appeal doesn't depend on anything
const EAT_RATE := 40.0         # hunger cleared per second while eating, same feel as EatMeal
const GOSSIP_DRIFT := 8.0      # hunger regained per second while distracted gossiping

var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	_livelock_without_resistance_stalls_and_thrashes()
	_raising_the_threshold_lets_the_meal_finish()
	_flee_seizes_and_releases_control_through_the_seam()
	_the_sweep_reaches_everyone_within_the_window()

	if _checks < EXPECTED_CHECKS:
		_failures.append("only %d of %d checks ran — something bailed out early" % [_checks, EXPECTED_CHECKS])

	print("")
	if _failures.is_empty():
		print("=== reconsider smoke: OK ===")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		print("=== RECONSIDER SMOKE FAIL ===")
		quit(1)


# --- 1. No resistance: the livelock, demonstrated -----------------------------

func _livelock_without_resistance_stalls_and_thrashes() -> void:
	print("--- with interrupt_threshold at 0, a score that falls as it's pursued stalls and thrashes ---")
	var world := VillageWorld.new()
	var who := _seeded_hunger_and_gossip(0.0)
	world.add_character(who)

	var min_hunger: float = who.stat(&"hunger")
	var swaps := 0
	var last_label := ""
	var elapsed := 0.0
	var duration := 14.0
	while elapsed < duration:
		world.advance(SLICE)
		elapsed += SLICE
		min_hunger = minf(min_hunger, who.stat(&"hunger"))
		var label: String = who.active_action.label if who.active_action != null else ""
		if last_label != "" and label != last_label:
			swaps += 1
		last_label = label

	print("  after %.0fs: hunger=%.1f (lowest seen %.1f), %d swaps between eating and gossiping, doing: %s" % [duration, who.stat(&"hunger"), min_hunger, swaps, who.doing_label()])
	_expect(who.stat(&"hunger") > 0.0, "without resistance she should never actually reach satisfied — the meal keeps losing the job before it can finish")
	_expect(swaps >= 3, "the two actions should visibly swap back and forth under the sweep rather than settle on one (saw %d)" % swaps)


# --- 2. Resistance: the same shape, but the meal finishes ---------------------

func _raising_the_threshold_lets_the_meal_finish() -> void:
	print("")
	print("--- raising the meal's interrupt_threshold above gossip's score lets it finish ---")
	var world := VillageWorld.new()
	var threshold := GOSSIP_SCORE + 5.0
	var who := _seeded_hunger_and_gossip(threshold)
	world.add_character(who)

	var elapsed := 0.0
	var limit := 5.0
	while elapsed < limit and who.stat(&"hunger") > 0.0:
		world.advance(SLICE)
		elapsed += SLICE

	print("  after %.2fs: hunger=%.1f, doing: %s (interrupt_threshold=%.0f)" % [elapsed, who.stat(&"hunger"), who.doing_label(), threshold])
	_expect(who.stat(&"hunger") <= 0.0, "with the meal defended above gossip's flat score, once incumbent it can never be dislodged, and should finish")


# A shared shape for both of the above: hunger starts well above gossip's
# flat appeal, so eating wins the very first decision on its own merits —
# interrupt_threshold never enters into a first pick, only a defence.
func _seeded_hunger_and_gossip(eat_threshold: float) -> Character:
	var eat_action := Action.new("have a bite",
		func(_w: Character) -> bool: return true,
		func(w: Character) -> float: return w.stat(&"hunger"),
		DrainsHunger.new(EAT_RATE)).hard_to_interrupt(eat_threshold)
	var gossip_action := Action.new("swap gossip",
		func(_w: Character) -> bool: return true,
		func(_w: Character) -> float: return GOSSIP_SCORE,
		DriftsHunger.new(GOSSIP_DRIFT))
	var knows: Array[Action] = [eat_action, gossip_action]
	return Character.new("Mara", {"hunger": 60.0}, knows)


# Drains hunger while eating — the score it's pursued for falls as it's
# pursued, which is the whole shape of the failure this file exists to prove.
class DrainsHunger:
	extends Step

	var rate: float

	func _init(new_rate: float) -> void:
		rate = new_rate

	func is_satisfied(who) -> bool:
		return who.stat(&"hunger") <= 0.0

	func advance(who, delta: float) -> bool:
		who.set_stat(&"hunger", maxf(0.0, who.stat(&"hunger") - rate * delta))
		return is_satisfied(who)

	func describe(_who) -> String:
		return "eating"


# Never satisfied and never impossible on its own — gossip doesn't end itself,
# only losing a decision ends it. While it's under way hunger creeps back up,
# which is what eventually makes eating worth returning to.
class DriftsHunger:
	extends Step

	var rate: float

	func _init(new_rate: float) -> void:
		rate = new_rate

	func is_satisfied(_who) -> bool:
		return false

	func advance(who, delta: float) -> bool:
		who.set_stat(&"hunger", who.stat(&"hunger") + rate * delta)
		return false

	func describe(_who) -> String:
		return "gossiping"


# --- 3. Flee: seized instantly, dropped instantly, through the seam alone ----

func _flee_seizes_and_releases_control_through_the_seam() -> void:
	print("")
	print("--- a fright pokes world.reconsider() directly, the way a future event would ---")
	var world := VillageWorld.new()
	var who := _seeded_worker_who_might_flee()
	world.add_character(who)

	world.reconsider(who)
	print("  fear=0: doing %s" % who.doing_label())
	_expect(who.active_action.label == "tend the field", "with no fear at all, work should win on the very first decision")

	who.set_stat(&"fear", 100.0)
	world.reconsider(who)
	print("  fear spikes to 100 — %s" % who.doing_label())
	_expect(who.active_action.label == "flee", "the instant fear outscores work, flee should seize control — no threshold defends work against it")

	who.set_stat(&"fear", 0.0)
	world.reconsider(who)
	print("  fear passes — %s" % who.doing_label())
	_expect(who.active_action.label == "tend the field", "the instant fear passes, flee's own threshold of 0 means it defends nothing, and work should win it right back")


# Flee is protected — always on the ballot regardless of its gate — and its
# interrupt_threshold is left at the default 0.0 on purpose: a protected
# action is guaranteed a fair hearing, never a free pass once something else
# outscores it.
func _seeded_worker_who_might_flee() -> Character:
	var work_action := Action.new("tend the field",
		func(_w: Character) -> bool: return true,
		func(_w: Character) -> float: return 20.0,
		NeverFinishes.new())
	var flee_action := Action.new("flee",
		func(_w: Character) -> bool: return true,
		func(w: Character) -> float: return w.stat(&"fear"),
		NeverFinishes.new()).always_available()
	var knows: Array[Action] = [work_action, flee_action]
	return Character.new("Osric", {"fear": 0.0}, knows)


# --- 4. The sweep reaches everyone, unprompted --------------------------------

func _the_sweep_reaches_everyone_within_the_window() -> void:
	print("")
	print("--- every character in a several-person village re-decides within the sweep window, unprompted ---")
	var world := VillageWorld.new()
	var villagers: Array[Character] = []
	for i in 5:
		var who := _seeded_watcher()
		villagers.append(who)
		world.add_character(who)

	# One slice is enough for everyone's first decision — active_action starts
	# null, and Character.act() decides for itself the moment it's asked to do
	# anything at all, sweep or no sweep.
	world.advance(SLICE)
	var steady_at_start := 0
	for who in villagers:
		if who.active_action != null and who.active_action.label == "keep watch":
			steady_at_start += 1
	print("  before the alarm: %d of %d are keeping watch" % [steady_at_start, villagers.size()])
	_expect(steady_at_start == villagers.size(), "with no alarm raised, everyone should start out keeping watch")

	# The alarm stat is changed directly — no action touched it, no event
	# fired, nobody's decide_action() was called by hand. If anyone notices,
	# it can only be the sweep.
	for who in villagers:
		who.set_stat(&"alarm", 100.0)

	var elapsed := 0.0
	var window := WorldTune.RECONSIDER_SWEEP_SECONDS
	var limit := window + SLICE * 4.0   # comfortably past one full window for every phase
	while elapsed < limit:
		world.advance(SLICE)
		elapsed += SLICE

	var raised := 0
	for who in villagers:
		if who.active_action != null and who.active_action.label == "raise the alarm":
			raised += 1
	print("  %.2fs after the alarm, unprompted: %d of %d have switched — window is %.1fs" % [elapsed, raised, villagers.size(), window])
	_expect(raised == villagers.size(), "within one reconsider window, every villager should have noticed the alarm on the sweep alone")


# Never-finishing, always-possible bodies with no side effects at all, so
# nothing but a reconsideration can ever change which of the two wins.
func _seeded_watcher() -> Character:
	var steady_action := Action.new("keep watch",
		func(_w: Character) -> bool: return true,
		func(_w: Character) -> float: return 10.0,
		NeverFinishes.new())
	var urgent_action := Action.new("raise the alarm",
		func(_w: Character) -> bool: return true,
		func(w: Character) -> float: return w.stat(&"alarm"),
		NeverFinishes.new())
	var knows: Array[Action] = [steady_action, urgent_action]
	return Character.new("watcher", {"alarm": 0.0}, knows)


# A body that never finishes and never becomes impossible — the shared shape
# every fixture action in this file uses that doesn't need a side effect of
# its own. See curve_smoke.gd for the same idea under the same reasoning.
class NeverFinishes:
	extends Step

	func is_satisfied(_who) -> bool:
		return false

	func advance(_who, _delta: float) -> bool:
		return false


func _expect(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(what)
	print(("PASS  " if ok else "FAIL  ") + what)
