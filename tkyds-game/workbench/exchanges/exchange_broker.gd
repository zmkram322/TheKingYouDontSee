extends Node

# WHO IS TALKING TO WHOM, AND WHAT COMES OF IT. One node, one place, everything
# installs here.
#
# Modelled directly on Population, which earns its keep for the same reason —
# it is a CALL SITE. population.gd, verbatim: "everything later installs here
# and nowhere else... The engine must never have called a Brain directly,
# because every one of those would then be a change to every Person instead."
# Whatever an exchange grows into — a rung ladder, a refusal, a camera framing
# a two-shot, an NPC lord dispatching a steward — installs in this file rather
# than in the arc, the brain, or the person.
#
# LIVE EXCHANGES ARE ITS CHILDREN, and that is the whole store. Nothing keeps a
# parallel list, so nothing can disagree with the tree. "Is this man held?" is
# answered by walking them, which is a handful of nodes and will stay that way:
# an exchange is two people talking, not a subscription.

const Exchange := preload("res://workbench/exchanges/exchange.gd")

# HOW FAR APART TWO PEOPLE CAN BE AND STILL BE TALKING, in metres.
#
# THIS IS WHAT ENDS A CONVERSATION, and it is the second place this workbench
# knowingly breaks Decision 35's "no gate reads where a man is standing" (the
# first is exchange_action.is_available_toward). The break is the same one and
# it is taken for the same reason: an exchange is a fact about two people being
# together, and there is no other honest reading of when one is over.
#
# DERIVED, NOT TIMED, which is the part that matters. No countdown, no "when
# does this expire" field, nothing to remember to clear: the conversation stands
# while they stand together and is over the moment they do not, re-asked from
# the world every time anybody wants to know. That keeps a lapsed exchange from
# being able to hold somebody for ever through a missed release — the failure
# W3 built the derived hold to rule out — even if every other mechanism forgets.
#
# SIZED WIDER THAN LookingAt.within_reach, WHICH IS HYSTERESIS AND NOT SLOP.
# It is the same shape exchange_brain.gd already uses for enters_within (3.0) /
# leaves_beyond (4.5), and the first cut of this number had it backwards.
#
# Tighter than the addressing reach opens a DEAD ZONE: standing between the two
# numbers, the arc offers you a verb, you press it, the conversation opens and
# the very next question anybody asks sweeps it away as lapsed. Nothing errors,
# nothing prints, the key just does not work — and it does not work only at
# certain distances, which is the worst kind of bug to be handed.
#
# Wider, the two numbers cannot disagree in that direction: anything you were
# close enough to ADDRESS you are close enough to KEEP TALKING TO, and ending a
# conversation takes a deliberate walk away rather than a shuffle.
@export var stands_within := 10.0

# REAL SECONDS SINCE THIS BROKER STARTED RUNNING. The exact shape of
# Clock.hours_elapsed — one monotonic number, the only stored fact here, and the
# thing every exchange stamps itself against — but on the frame clock, because an
# exchange's visible length is presentation and does not belong to the sun.
#
# THE ONE PLACE A REAL DELTA IS READ IN THIS FOLDER, which is the same discipline
# Clock keeps on the other side: converted once, in one file, and never
# interpreted again below it. Public so it can be driven by hand in a check
# rather than by waiting.
#
# It advances only while this node processes, so an exchange does not run on
# while the game is paused — which is right, and is why this is not
# Time.get_ticks_msec().
var seconds_running := 0.0


# FACING AND ENDING, once a frame. Presentation phase deliberately: turning two
# bodies toward each other is what they LOOK like, and _process is where clip
# choice already lives. The ending is read off ELAPSED SECONDS rather than off a
# frame count, so a slow machine and a fast one show the same length of wave.
func _process(delta: float) -> void:
	seconds_running += delta
	for child in get_children():
		var exchange := child as Exchange
		if exchange == null:
			continue
		if has_lapsed(exchange):
			end(exchange)
			continue
		exchange.face_each_other()
		_answer_when_due(exchange)


# THE REPLY LANDS ON ELAPSED REAL TIME, not on a frame count, so it falls at the
# same moment in the exchange whatever the frame rate and whatever the day length.
# Idempotent: begin_answering makes the reply
# once and returns null every time after, so this can be asked every frame.
func _answer_when_due(exchange: Exchange) -> void:
	if exchange.answering != null or exchange.performing == null:
		return
	if not exchange.is_answer_due(seconds_running):
		return
	var scene: Variant = exchange.performing.get(&"answered_with")
	if not (scene is PackedScene):
		return
	var reply := exchange.begin_answering(scene)
	if reply != null:
		_start_performing(exchange.recipient, reply)


# --- STARTING AND SETTLING ----------------------------------------------------

# THE ONE DOOR. Somebody does something to somebody else: the conversation opens
# if one is not already standing, and the action settles. Both halves here, in
# the call site, rather than split between the arc and the action — a UI that
# could settle an exchange directly would be a second way for the world to
# change on an exchange's behalf, and a second way is a second place for a
# half-completed result to hide.
#
# Returns the exchange they are now in, or null if it could not happen at all.
func offer(initiator: Person, recipient: Person, action: Node) -> Node:
	if action == null or not action.has_method(&"settle"):
		push_warning("an exchange was offered without an action that can settle — nothing happened")
		return null
	# ALWAYS A NEW ONE. This used to reuse a conversation already standing between
	# these two, so that a second verb could be played inside it — which was the
	# `offered = "only once talking"` ladder, and it is gone (see
	# exchange_action.gd). One exchange is one action, opened and run to its end,
	# and begin() refuses outright if either man is already mid-anything. That is
	# the same answer the arc draws, from the same function, so a row it offers can
	# never be one that pressing would silently decline.
	var exchange := begin(initiator, recipient)
	if exchange == null:
		return null
	# HOW LONG IT RUNS COMES FROM THE ACTION, because that is where a wave and a
	# haggle differ. One number, read twice — the hold ends by it and the gesture
	# is fitted to it — rather than two kept equal (W10).
	var takes: Variant = action.get(&"takes_seconds")
	if takes is float:
		exchange.runs_for_seconds = takes
	exchange.began_at_second = seconds_running

	# SETTLED WHILE THE CONVERSATION STANDS, never after ending it. A result may
	# want to read who is talking to whom — a refusal will, when W1's open
	# question is answered — and an exchange torn down first would answer that
	# question with silence.
	action.call(&"settle", initiator, recipient)

	# BOTH OF THEM PERFORM IT, WRITTEN HERE FOR BOTH — and the first cut got this
	# wrong in a way the seam check caught. It set only the recipient, on the
	# reasoning that the initiator had already chosen the verb himself through
	# PlayerBrain.choose_verb. He had, and it did nothing: choose_verb records a
	# BID (Decision 33), and a bid only becomes current_action when the ballot
	# next runs — which for a man the broker has just held is never. So the
	# greeter did not wave either.
	#
	# Underneath that was the real fault: two doors for one fact. The greeter's
	# performance came from the arc and the greeted man's from here, so an
	# exchange between two NPCs — which has no arc anywhere near it — would have
	# had an initiator who stood still. W3 is explicit that neither participant is
	# special, and this is what that costs if you let it slide.
	# THE OFFER IS THE INITIATOR'S ALONE. Handing it to both was the first cut and
	# it read wrong on screen: two men waving in unison on the same frame, which
	# is not a greeting, it is a coincidence. The recipient gets his own reply a
	# beat later (see _answer_when_due), and until then he STANDS — cleared, not
	# left wearing whatever clip he was stopped in, because a man listening is a
	# man who has stopped.
	exchange.performing = action as Action
	exchange.answers_after_seconds = 0.0
	var beat: Variant = action.get(&"answers_after_seconds")
	if beat is float:
		exchange.answers_after_seconds = beat
	if exchange.answers_after_seconds >= exchange.runs_for_seconds:
		push_warning("\"%s\" answers after %.2f s but only runs %.2f s — nobody will reply"
			% [action.name, exchange.answers_after_seconds, exchange.runs_for_seconds])
	if exchange.performing != null:
		_start_performing(initiator, exchange.performing)
	_stand_and_listen(recipient)
	return exchange


# Stop him doing whatever he was doing, without giving him anything else. Null
# current_action reads as "" through Brain.get_clip, which Person turns into the
# resting clip — so he is a man standing there, which is the honest picture of
# somebody being spoken to.
func _stand_and_listen(person: Person) -> void:
	if not is_instance_valid(person) or person.brain == null:
		return
	person.brain.current_action = null
	if person.brain.has_method(&"stop_doing_anything"):
		person.brain.call(&"stop_doing_anything")


func _start_performing(person: Person, action: Action) -> void:
	if not is_instance_valid(person) or person.brain == null:
		return
	person.brain.current_action = action
	# The player's own bid as well, so that when the exchange hands him back,
	# stop_doing_anything has something to clear and he is not left holding a
	# choice the ballot would re-apply the moment he is free.
	if person.brain.has_method(&"choose_verb"):
		person.brain.call(&"choose_verb", action)


# Start one. Returns the Exchange so a caller can hold on to it, but nothing is
# obliged to — the broker is the owner and the tree is the record.
#
# ACCEPTANCE IS NOT ASKED HERE, and W2 in DECISIONS.md is why: the answer is
# hardcoded yes until we know what a refusal is actually driven by. When that
# lands it lands in THIS function, which is the whole point of the node.
func begin(initiator: Person, recipient: Person) -> Node:
	if initiator == null or recipient == null or initiator == recipient:
		push_warning("an exchange needs two different people — none was started")
		return null
	# BOTH SIDES ARE CHECKED, not just the man being addressed. An earlier cut
	# asked only about the recipient, which let one man hold conversations with
	# two people at once: greet somebody, turn to face a third, and the ladder
	# offers a greeting again because no exchange stands between THOSE two.
	# Neither is an error. He is mid-conversation and the second asker simply
	# does not get him — which is a refusal of a kind, and the first honest one
	# in the system.
	if get_exchange_for(recipient) != null:
		return null
	if get_exchange_for(initiator) != null:
		return null
	var exchange := Exchange.new()
	exchange.name = "%s_and_%s" % [initiator.person_name, recipient.person_name]
	exchange.initiator = initiator
	exchange.recipient = recipient
	exchange.began_at_second = seconds_running
	add_child(exchange)
	return exchange


func end(exchange: Node) -> void:
	if exchange == null or not is_instance_valid(exchange):
		return
	# TAKEN OUT OF THE TREE IMMEDIATELY, not merely queued. queue_free() does
	# not land until the end of the frame, and "held" is DERIVED from this node
	# being a child of the broker — so a queued-only exchange goes on answering
	# is_in_an_exchange as true, and the man stays frozen for the rest of the
	# frame after he was released. Freeing stays deferred, which is correct;
	# the ANSWER must not be.
	# HANDED BACK WHAT THEY WERE DOING — which is nothing. Cleared only where it
	# still IS the exchange's own action, so a man who has since been given
	# something else to do is left alone. Next tick he decides for himself again.
	var talking := exchange as Exchange
	if talking != null:
		_stop_performing(talking.initiator, talking)
		_stop_performing(talking.recipient, talking)

	if exchange.get_parent() == self:
		remove_child(exchange)
	exchange.queue_free()


# Hand a man back what he was doing, which is nothing. THE EXCHANGE IS PASSED IN,
# NOT LOOKED UP, and that is not tidiness: end() is called from inside
# get_exchange_for's sweep, so asking for it again here would re-enter the sweep,
# find the same lapsed exchange, and call end() on it forever. The first cut did
# exactly that.
#
# Asked of the exchange rather than against one remembered action, so it covers
# the offer AND the reply — and still leaves alone anybody who has since been
# given something else to do.
func _stop_performing(person: Person, talking: Exchange) -> void:
	if not is_instance_valid(person) or person.brain == null or talking == null:
		return
	if not talking.is_performing(person.brain.current_action):
		return
	# BOTH, AND NOT ONE OR THE OTHER. current_action is what he is DOING and
	# _chosen is what he BID; PlayerBrain.stop_doing_anything clears only the
	# second. An earlier cut called it instead of clearing current_action and
	# left the player waving for ever — and the claim that should have caught it
	# had been passing all along, because until the broker started performing for
	# both men there was never anything in current_action to fail to clear. Same
	# species as the seam check that asserted a held man's adenosine stood still.
	person.brain.current_action = null
	if person.brain.has_method(&"stop_doing_anything"):
		person.brain.call(&"stop_doing_anything")


func end_for(person: Person) -> void:
	end(get_exchange_for(person))


# --- WHO IS TALKING TO WHOM ---------------------------------------------------

# THE QUERY THE POPULATION ASKS. Held is DERIVED, never stored — see W3. A man
# is held if and only if a live exchange node names him.
func is_in_an_exchange(person: Person) -> bool:
	return get_exchange_for(person) != null


func get_exchange_for(person: Person) -> Node:
	if person == null:
		return null
	for child in get_children():
		var exchange := child as Exchange
		if exchange == null:
			continue
		# SWEPT ON THE WAY PAST rather than in a tidy-up pass, so nothing has to
		# remember to run one — and that is now doing more work than it looks
		# like. Population asks is_held for every person every tick, and every
		# one of those asks arrives here, so a conversation whose parties have
		# walked apart is ended by the very next question anybody asks about
		# either of them. There is no sweep to schedule and no phase to get
		# wrong, which is the whole argument for deriving the hold rather than
		# storing it.
		if has_lapsed(exchange):
			end(exchange)
			continue
		if exchange.involves(person):
			return exchange
	return null


# The conversation between these two specifically, or null. Different from
# get_exchange_for, and the difference is what the greeting ladder turns on: a
# man talking to somebody ELSE has an exchange, but not one with you, so a
# greeting is still the only thing you may offer him — and begin() will refuse
# it, which is the honest answer rather than a second conversation.
func get_exchange_between(one: Person, another: Person) -> Node:
	var exchange := get_exchange_for(one)
	if exchange == null:
		return null
	if not exchange.involves(another):
		return null
	return exchange


# Is this conversation over? Two ways, and both are read off the world rather
# than off anything stored: one of them is gone, or they are no longer together.
func has_lapsed(exchange: Node) -> bool:
	var talking := exchange as Exchange
	if talking == null:
		return true
	if not talking.is_still_standing():
		return true
	if talking.get_distance_apart() > stands_within:
		return true
	# RUN ITS COURSE. The wave is over, so the exchange is over — and for now
	# that is the whole of a greeting: nothing is left behind, and nothing else
	# is on the table between these two until deeper actions are written.
	if talking.is_over(seconds_running):
		return true
	return false


func get_live_exchanges() -> Array:
	var standing: Array = []
	for child in get_children():
		var exchange := child as Exchange
		if exchange != null and not has_lapsed(exchange):
			standing.append(exchange)
	return standing
