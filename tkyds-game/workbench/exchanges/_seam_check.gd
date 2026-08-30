extends SceneTree

# Throwaway. Proves the interrupt lands on his DECIDING and on nothing else.
#
# THIS FILE USED TO CLAIM THE OPPOSITE, AND THE CLAIM PASSED. It asserted that
# a held man's adenosine stayed put — which was true, and was a bug: skipping
# him in the loop skipped the tail of think_and_act, where upkeep lives. Time
# stopped for him. The check was green the whole way through, because it was
# written to describe what the code did rather than what the design wanted.
#
# So adenosine can no longer witness the hold — it now rises whether or not a
# man is held, which is the entire point. It witnesses the BODY instead, and
# `current_action` witnesses the hold: the ballot never opens, so nothing
# overwrites what he was last doing. Both directions are asserted, because a
# sentinel nothing could ever have cleared proves nothing.
#
# TWO THINGS COPIED FROM probe.gd, BOTH THE HARD WAY (this file got each one
# wrong first):
#
#   1. Assertions wait for the first _process frame. At _initialize time the
#      scene is in the tree but _ready has NOT run, so every @onready var —
#      stats, brain, inventory — is still null and reads as "Nonexistent
#      function in base Nil".
#
#   2. process_mode is set to DISABLED *before* add_child, so the scene never
#      ticks itself. Otherwise Population._process advances everybody behind
#      the measurement and the numbers below mean nothing.

var _bad := 0
var _done := false
var _scene: Node


func _initialize() -> void:
	var packed: PackedScene = load("res://workbench/exchanges/exchanges.tscn")
	_scene = packed.instantiate()
	_scene.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(_scene)


func _held(claim: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + claim)
	if not ok:
		_bad += 1


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true

	var crowd: Node = _scene.get_node(^"Population")
	var broker: Node = _scene.get_node(^"ExchangeBroker")
	var npc: Person = _scene.get_node(^"Population/Somebody") as Person
	var player: Person = _scene.get_node(^"Population/Player") as Person
	var bystander: Person = _scene.get_node(^"Population/Another") as Person

	_held("the scene stands up with both bodies under a Population",
		npc != null and player != null and npc.stats != null)

	var watcher: Node = _scene.get_node(^"LookingAt")
	var arc: Node = _scene.get_node(^"ExchangeArc")
	_held("the targeting node resolved its three wires",
		watcher.eye != null and watcher.looker != null and watcher.crowd != null)
	_held("the arc resolved its three wires",
		arc.watching != null and arc.eye != null and arc.actor != null)

	# The player must actually know an exchange, or the arc has nothing to draw
	# and pressing the key would do nothing for a reason unrelated to the seam.
	var exchanges := 0
	for action in player.brain.get_known_actions():
		if action.has_method(&"is_available_toward"):
			exchanges += 1
	_held("the player knows at least one exchange (found %d)" % exchanges, exchanges > 0)

	var before: float = npc.stats.get_stat("adenosine")
	crowd.think_for_everyone(2.0)
	var ticking: float = npc.stats.get_stat("adenosine")
	_held("unheld, he accrues: adenosine %.2f -> %.2f" % [before, ticking], ticking > before)

	# Through the broker now: nothing holds a man directly, and being held is
	# derived from a live exchange existing rather than stored on anybody.
	var conversation: Node = broker.begin(player, npc)
	_held("the broker opened an exchange", conversation != null)
	# BOTH parties are held. involves() answers for either side, so opening a
	# conversation stops both men deciding — which is what two people talking
	# to each other should mean, and matters most for the NPC-to-NPC case where
	# neither of them is the player.
	_held("the recipient is held", crowd.is_held(npc))
	_held("the initiator is held too — an exchange takes both", crowd.is_held(player))
	_held("a bystander is NOT held", not crowd.is_held(bystander))

	var outsiders: float = bystander.stats.get_stat("adenosine")
	var accrued_free := ticking - before

	# THE BODY KEEPS RUNNING, AT THE SAME RATE. Not merely "it went up" — the
	# same two hours must buy the same adenosine held as free, or the hold is a
	# discount on being alive rather than an interrupt on deciding.
	crowd.think_for_everyone(2.0)
	var held_at: float = npc.stats.get_stat("adenosine")
	var accrued_held := held_at - ticking
	_held("HELD, his body still runs: adenosine %.2f -> %.2f" % [ticking, held_at],
		held_at > ticking)
	_held("and at the same rate: %.2f free vs %.2f held over the same 2h"
		% [accrued_free, accrued_held], is_equal_approx(accrued_free, accrued_held))

	# The conversation, not the world. Kept from the version that measured a
	# freeze, because it is still the claim that separates an interrupt from a
	# pause button — it just witnesses that a bystander is UNAFFECTED now,
	# rather than that he alone survived.
	_held("the hold took the conversation only: a bystander kept accruing",
		bystander.stats.get_stat("adenosine") > outsiders)

	broker.end(conversation)
	# queue_free lands at end of frame; the broker sweeps lapsed exchanges on
	# the way past, so ask it once to prove the sweep rather than the timer.
	crowd.think_for_everyone(2.0)
	var resumed: float = npc.stats.get_stat("adenosine")
	_held("released, his body is still running: adenosine %.2f -> %.2f"
		% [held_at, resumed], resumed > held_at)

	# --- and now the half that IS supposed to stop -----------------------------
	#
	# WHAT ACTUALLY WITNESSES THE HOLD, now that the body cannot. current_action
	# is rewritten from the ballot on every think_and_act, so a value that
	# survives a tick is proof the ballot never opened.
	#
	# ASSERTED IN BOTH DIRECTIONS ON PURPOSE. A sentinel that nothing could have
	# cleared would pass held, pass unheld, and prove nothing — the vacuous
	# claim this project keeps catching. So it is cleared once for real first.
	#
	# THE SENTINEL IS AN ACTION HE DOES NOT KNOW, and the first draft got this
	# wrong in a way worth keeping written down: it used get_known_actions()[0],
	# which is an action he can legitimately CHOOSE — so "it still holds the
	# sentinel" was ambiguous between "the ballot never ran" and "the ballot ran
	# and picked that one." It failed unheld for exactly that reason. An orphan
	# Action is in nobody's repertoire, so the ballot can never return it, and
	# surviving a tick means only one thing.
	var sentinel := Action.new()

	npc.brain.current_action = sentinel
	crowd.think_for_everyone(2.0)
	_held("UNHELD, deciding overwrites what he was doing (the sentinel is real)",
		npc.brain.current_action != sentinel)

	npc.brain.current_action = sentinel
	var stood_at := npc.global_position
	var conversation_again: Node = broker.begin(player, npc)
	crowd.think_for_everyone(2.0)
	_held("the broker opened a second exchange", conversation_again != null)
	_held("HELD, his deciding stops: the ballot never overwrote current_action",
		npc.brain.current_action == sentinel)
	_held("and he does not move while held", npc.global_position.is_equal_approx(stood_at))
	broker.end(conversation_again)
	# Never entered the tree, so nothing will collect it — and current_action
	# must not be left pointing at a freed node either.
	npc.brain.current_action = null
	sentinel.free()

	print("")
	print("seam check: all held." if _bad == 0 else "seam check: %d FAILED." % _bad)
	quit(1 if _bad > 0 else 0)
	return true
