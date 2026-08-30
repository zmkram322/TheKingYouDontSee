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

const Acquaintance := preload("res://workbench/exchanges/acquaintance.gd")

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

	# THE SCENE ITSELF, ASKED BEFORE THIS FILE TOUCHES ANYTHING. Give is gated on
	# the giver having something to give, so a player authored with an empty sack
	# means the verb never appears — and it appears nowhere, says nothing, and
	# looks exactly like a broken gate.
	#
	# IT HAS HAPPENED FIVE TIMES. exchanges.tscn authors him six loaves, and an
	# open Godot editor re-saves the scene from its own stale copy and drops the
	# block every time (see the engineering traps at the end of DECISIONS.md).
	# Every other claim in this file stocks what it measures, so not one of them
	# could see it. This one deliberately does not.
	var starts_with := 0
	for item_name in player.get_inventory().get_item_names():
		starts_with += player.get_inventory().get_count(item_name)
	_held("the scene authors the player something to give (%d items) — if this is red, the editor ate it again"
		% starts_with, starts_with > 0)

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

	# --- and now the path the RUNNING GAME actually uses -----------------------
	#
	# EVERYTHING ABOVE CALLS think_for_everyone BY HAND, which is not how this
	# scene runs when you press play. Since 2026-08-30 Population owns an
	# accumulator: _process banks real seconds and step_real_time spends them on
	# whole ticks, advancing the Clock and thinking for everybody once each.
	# exchange_population.gd overrides think_for_everyone and inherits all of
	# that — so the question nobody had asked is whether the interrupt still
	# installs when the BASE class is the one doing the calling.
	#
	# It should: GDScript dispatches virtually, so the base calling
	# think_for_everyone reaches the override. "Should" is not evidence.
	var clock: Clock = _scene.get_node(^"Clock") as Clock
	_held("the scene has a Clock for the accumulator to drive", clock != null)
	if clock != null:
		var sun_before: float = clock.hours_elapsed
		var real_seconds := 10.0 / 60.0 # ten frames' worth at 60fps
		crowd.step_real_time(real_seconds)
		_held("Population drives the Clock now that Clock has no _process of its own: %.4f -> %.4f h"
			% [sun_before, clock.hours_elapsed], clock.hours_elapsed > sun_before)

		var guard := Action.new()
		npc.brain.current_action = guard
		var stood := npc.global_position
		var body_before: float = npc.stats.get_stat("adenosine")
		var talking: Node = broker.begin(player, npc)
		crowd.step_real_time(real_seconds)
		_held("through the accumulator too, a held man still does not decide",
			npc.brain.current_action == guard)
		_held("and still does not move", npc.global_position.is_equal_approx(stood))
		_held("and his body still runs: adenosine %.2f -> %.2f"
			% [body_before, npc.stats.get_stat("adenosine")],
			npc.stats.get_stat("adenosine") > body_before)
		broker.end(talking)

		npc.brain.current_action = guard
		crowd.step_real_time(real_seconds)
		_held("RELEASED, the accumulator decides for him again (the guard is real)",
			npc.brain.current_action != guard)
		npc.brain.current_action = null
		guard.free()

	# --- THE GREETING ITSELF: it turns them, it shows on both, it ends ----------
	#
	# Everything above proves the HOLD. None of it proves the exchange is a thing
	# you can watch. These four are the wave.

	var greet: Action = null
	var give: Action = null
	for action in player.brain.get_known_actions():
		if action.scene_file_path == "res://workbench/exchanges/greet.tscn":
			greet = action
		if action.scene_file_path == "res://workbench/exchanges/give.tscn":
			give = action
	_held("the player carries a greeting", greet != null)
	_held("and something to give", give != null)

	# THE GATE, SHUT — asserted BEFORE anybody greets anybody, which is the only
	# point in this file where these two are still strangers. Everything above
	# opened exchanges through broker.begin, which does not settle, so no regard
	# has ever been recorded.
	if give != null:
		_held("they have not met", not Acquaintance.have_met(player, npc))
		_held("so give is shut on a stranger, even standing right in front of him",
			not give.is_available_toward(player, npc))

		# AND GREETING HONOURS THE SAME GATE, asserted in a state that does not
		# otherwise exist. greet.gd OVERRIDES is_available_toward, which replaces
		# the base entirely, so its call to is_regarded_enough is the one line
		# standing between "a greeting requires nothing" and "a greeting ignores
		# whatever it was authored to require". Greeting authors no requirement,
		# so nothing in normal play could ever witness that line — CLAIM ABOUT A
		# RULE WITH NO BRANCH, ASSERTED IN THE STATE THE MISSING BRANCH WOULD HAVE
		# CHANGED. The requirement is put on and taken straight back off.
		var greeting: Object = greet
		greeting.set(&"needs_to_have_met", true)
		_held("greeting re-asks the base gate rather than replacing it",
			not greet.is_available_toward(player, npc))
		greeting.set(&"needs_to_have_met", false)
		_held("and is open again once the requirement is lifted",
			greet.is_available_toward(player, npc))

	if greet != null and clock != null:
		# Stood apart and pointed anywhere, so "they face each other" cannot pass
		# by having started that way. Both are turned to a third direction first.
		npc.global_position = player.global_position + Vector3(3.0, 0.0, 0.0)
		var npc_body: Node3D = npc.get_node(^"Body")
		var player_body: Node3D = player.get_node(^"Body")
		npc_body.rotation.y = 0.0
		player_body.rotation.y = 0.0

		# DRIVEN IN REAL SECONDS, by hand. broker.seconds_running is the frame
		# clock's twin of Clock.hours_elapsed and is public for exactly this: an
		# exchange's length is presentation, so waiting for it would mean actually
		# waiting. The sun is deliberately NOT advanced anywhere below — that is
		# the claim, that a wave does not care what the day length is.
		var opened_at: float = broker.seconds_running
		var wave: Node = broker.offer(player, npc, greet)
		_held("the greeting opened an exchange", wave != null)
		_held("it took its length from the action: %.2f s" % wave.runs_for_seconds,
			is_equal_approx(wave.runs_for_seconds, greet.takes_seconds))

		# TWO SIDES, AND THE SECOND ONE HAS NOT ARRIVED YET. The greeter waves; the
		# greeted man STANDS. Asserted as "cleared" rather than "not the greeting",
		# because the failure this replaced was him wearing the clip he was
		# stopped in, which is also not the greeting.
		_held("the greeter waves and the greeted man stands and listens",
			player.brain.current_action == greet and npc.brain.current_action == null)
		_held("nobody has answered on the opening frame", wave.answering == null)

		# THE REVEAL IS NOT INTERACTIVE — W10's one hard line. Give's own gate is
		# open by now (settle ran at the ask, so they have met), and it must STILL
		# not be on the arc, because he is mid-wave. Asserted against the ARC
		# rather than against the gate for exactly that reason: the gate says yes
		# and the right answer is still nothing.
		_held("mid-wave the gate itself is open", give.is_available_toward(player, npc))
		_held("but the arc offers nothing at all while the wave is playing",
			arc._get_open_exchanges(npc).is_empty())

		# THE ACTOR'S OWN HALF, which the line above cannot witness — the man he
		# is waving at is busy either way, so a check that asked only about the
		# TARGET would pass it. Pointed at a third man who is standing idle, the
		# arc must still draw nothing, because the GREETER is the one mid-wave.
		_held("nor over a bystander, because the greeter himself is mid-wave",
			arc._get_open_exchanges(bystander).is_empty())

		# AND THE DOOR ITSELF REFUSES, not merely the drawing of it. An arc that
		# declined to draw a row while offer() would still have honoured it is two
		# answers to one question, and the day something other than this arc calls
		# the broker — an NPC lord dispatching a steward — it would get the other
		# one.
		_held("and the broker refuses a second action inside a standing exchange",
			broker.offer(player, npc, give) == null)

		# He is to the player's +X, so the player turns toward +X (atan2(1,0) =
		# +PI/2) and he turns back toward -X. Asserted as real angles rather than
		# "it changed", because both started at 0.0 and either one drifting would
		# otherwise read as success.
		wave.face_each_other()
		_held("they turn to face each other: greeter %.2f rad, greeted %.2f rad"
			% [player_body.rotation.y, npc_body.rotation.y],
			is_equal_approx(player_body.rotation.y, PI * 0.5)
			and is_equal_approx(npc_body.rotation.y, -PI * 0.5))

		# THE BEAT. Not yet at half of answers_after, and landed by the time the
		# exchange is half over — both directions, because a reply that had simply
		# always been there would pass the second on its own.
		broker._process(greet.answers_after_seconds * 0.5)
		_held("before the beat, still no answer", wave.answering == null)

		broker._process(greet.answers_after_seconds)
		# HE IS DOING IT, not merely that a reply node was made. The first cut
		# asserted only `answering != null`, which begin_answering sets whether or
		# not anybody was ever handed it — so cutting the man out of his own reply
		# left this green. Vacuous in the usual way: no state in which it could
		# have gone the other way.
		_held("after the beat he answers",
			wave.answering != null and npc.brain.current_action == wave.answering)
		_held("and he answers in his own gesture, not the one he was greeted with",
			wave.answering != null and npc.brain.current_action == wave.answering
			and wave.answering.step.get_clip_for(npc) != greet.step.get_clip_for(player))
		_held("half way through, they are still at it", crowd.is_held(npc))

		# AND THE SUN IS IRRELEVANT TO ALL OF IT. A whole world day passes here and
		# the wave neither ends nor hurries — which is the entire point of moving
		# these two numbers off world hours. Put them back on hours and this is the
		# line that goes red.
		var sun_before: float = clock.hours_elapsed
		clock.advance(24.0)
		_held("a whole day of world time passes and the wave is unmoved: %.0f h -> %.0f h"
			% [sun_before, clock.hours_elapsed], crowd.is_held(npc))

		broker._process(greet.takes_seconds)
		_held("the wave runs its course and the exchange ends itself after %.2f s"
			% (broker.seconds_running - opened_at), not crowd.is_held(npc))
		_held("and both are handed back what they were doing, which is nothing",
			player.brain.current_action == null and npc.brain.current_action == null)

	# --- WHAT THE GREETING LEFT BEHIND, AND WHAT IT UNLOCKS --------------------
	#
	# The first relational number in the codebase. Asserted on BOTH SIDES
	# separately, because one node per side is the whole design — two people do
	# not have to agree about each other, and a shared edge would make that
	# impossible by construction rather than merely untrue today.

	if greet != null and give != null:
		_held("the greeting left a record on the greeter: %.1f"
			% Acquaintance.get_warmth(player, npc),
			is_equal_approx(Acquaintance.get_warmth(player, npc), greet.initiator_regard_change))
		_held("and its own record on the greeted man: %.1f"
			% Acquaintance.get_warmth(npc, player),
			is_equal_approx(Acquaintance.get_warmth(npc, player), greet.recipient_regard_change))
		_held("a bystander is a stranger to both of them still",
			not Acquaintance.have_met(player, bystander)
			and not Acquaintance.have_met(npc, bystander))

		# THE TARGET'S OWN HALF, and the only state in this file that can witness
		# it: the player FREE and the man he is looking at busy with somebody
		# else. Every other check has both of them in the same exchange, where the
		# actor half alone would pass it — so without these two lines, half of
		# _both_are_free_to_talk is unasserted.
		#
		# IT IS ALSO THE FIRST NPC-TO-NPC EXCHANGE IN THE WORKBENCH. No player
		# anywhere in it, which W3 says is most of what exchanges are for.
		var elsewhere: Node = broker.begin(npc, bystander)
		_held("two NPCs hold a conversation with no player in it", elsewhere != null)
		_held("and you cannot cut into it — nothing is offered over a man already talking",
			arc._get_open_exchanges(npc).is_empty())
		broker.end(elsewhere)

		# THE GATE, OPEN. Same call, same two men, same standing — the ONLY thing
		# that changed is that they have now met.
		_held("having met, give is on the table", give.is_available_toward(player, npc))

		# --- AND THE GOODS ACTUALLY MOVE ---------------------------------------
		#
		# CONSERVATION, not just "he got one". add creates and take destroys; only
		# hand_over moves, and the whole reason that is the one transfer path is
		# so a check like this means something. A world total that changed here
		# would mean a second door had been cut.
		# STOCKED HERE RATHER THAN READ OFF THE SCENE, and that is not laziness.
		# exchanges.tscn authors the player six loaves, and an open Godot editor
		# has silently eaten that block out of the file once already (see the
		# engineering traps at the end of DECISIONS.md). A transfer check that
		# quietly measures 0 -> 0 and calls conservation satisfied is worse than
		# no check, so the quantity under test is put there by the test.
		var loaf: StringName = give.gives_item
		player.get_inventory().add(loaf, 3)
		var giver_before: int = player.get_inventory().get_count(loaf)
		var taker_before: int = npc.get_inventory().get_count(loaf)
		var handed: Node = broker.offer(player, npc, give)
		_held("the gift opened an exchange", handed != null)

		var giver_after: int = player.get_inventory().get_count(loaf)
		var taker_after: int = npc.get_inventory().get_count(loaf)
		_held("the loaf changed hands: giver %d -> %d, taker %d -> %d"
			% [giver_before, giver_after, taker_before, taker_after],
			giver_after == giver_before - give.gives_count
			and taker_after == taker_before + give.gives_count)
		_held("and the world is neither richer nor poorer for it: %d -> %d"
			% [giver_before + taker_before, giver_after + taker_after],
			giver_after + taker_after == giver_before + taker_before)

		# THE GIFT IS NOT SYMMETRIC, which is why there are two numbers and not
		# one. Being handed bread moves the receiver a great deal more than it
		# moves the giver.
		_held("it moved them by different amounts: giver %.1f, receiver %.1f"
			% [Acquaintance.get_warmth(player, npc), Acquaintance.get_warmth(npc, player)],
			not is_equal_approx(Acquaintance.get_warmth(player, npc),
				Acquaintance.get_warmth(npc, player)))

		broker.end(handed)

		# AND A MAN WITH AN EMPTY SACK CANNOT GIVE. The giver's own half of the
		# gate, which is is_available_to and not the regard half — asserted by
		# emptying him rather than by reading the code, because the two gates fail
		# for different reasons and only one of them is about the other man.
		player.get_inventory().take(loaf, player.get_inventory().get_count(loaf))
		_held("emptied out, he has nothing to give though he still knows the man",
			not give.is_available_to(player) and Acquaintance.have_met(player, npc))

		# --- ASK, ALL THE WAY THROUGH TO HIM DOING IT --------------------------
		#
		# The whole path in one go, because the pieces passing separately is what
		# let "he never actually works the ground" hide: the verb appears, the
		# errand lands, AND he is seen doing it are three different claims and
		# only the third is what anybody watching cares about.
		var ask: Action = null
		for action in player.brain.get_known_actions():
			if action.scene_file_path == "res://workbench/exchanges/ask.tscn":
				ask = action
		_held("the player carries an ask", ask != null)

		if ask != null:
			var errand_scene: PackedScene = ask.lands_on_recipient
			_held("having met, ask is drawn on the arc",
				arc._get_open_exchanges(npc).has(ask))
			_held("and he does not already know the errand",
				ask.find_landed(errand_scene, npc) == null)

			var asked: Node = broker.offer(player, npc, ask)
			_held("the ask opened an exchange", asked != null)
			var errand: Action = ask.find_landed(errand_scene, npc)
			_held("the errand landed in his repertoire", errand != null)

			# ASKED TWICE, LANDED ONCE. An Action holds no per-instance progress,
			# so a second copy is indistinguishable from the first and does
			# nothing but lengthen the ballot.
			broker.end(asked)
			broker.offer(player, npc, ask)
			var copies := 0
			for action in npc.brain.get_known_actions():
				if action.scene_file_path == errand_scene.resource_path:
					copies += 1
			_held("asked twice, it landed once (found %d)" % copies, copies == 1)
			broker.end_for(npc)

			# AND NOW THE ONE THAT MATTERS. Released, does he actually do it?
			#
			# THE SUN IS SET DELIBERATELY, and that is not the check cheating — it
			# is the check being honest about W9. work_the_ground scores a FLAT 75
			# with no gap (W9's Option A, the trap), against StayUp's
			# 67.3 + 20 x sun. So he works at night and stands about at noon, and
			# which one you saw depends on what time it was when you pressed R.
			# Both are asserted, because the failure mode nobody would notice is the
			# errand never winning at all.
			clock.hours_elapsed = 0.0
			npc.stats.set_stat(&"adenosine", 0.0)
			npc.stats.set_stat(&"hunger", 0.0)
			npc.stats.set_stat(&"social", 0.0)
			crowd.think_for_everyone(0.01)
			_held("released at midnight he sets to work: he is %s"
				% npc.brain.describe_current_action(),
				npc.brain.current_action == errand)

			clock.hours_elapsed = 12.0
			crowd.think_for_everyone(0.01)
			_held("and at noon being up outbids it — outbid, never barred: he is %s"
				% npc.brain.describe_current_action(),
				npc.brain.current_action != errand
				and npc.brain.get_open_actions().has(errand))

	print("")
	print("seam check: all held." if _bad == 0 else "seam check: %d FAILED." % _bad)
	quit(1 if _bad > 0 else 0)
	return true
