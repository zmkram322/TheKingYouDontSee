extends Node

# ONE LIVE CONVERSATION. Two people, neither of them special.
#
# There is no "player" here and there must never be one. Exchanges are how
# goals, obligations and errands get injected into people at all — a lord
# leaning on a steward is the same object as you leaning on a farmhand — so a
# field named `player` would make the whole hierarchy unreachable by the very
# mechanism built for it.
#
# IT HOLDS NO PROGRESS, in the ActionStep tradition: no stage counter, no
# elapsed timer, no "whose turn". What it holds is WHO, and everything else is
# re-asked. The one thing it is allowed to be is ALIVE — its existence, as a
# child of the broker, is the entire fact that these two are talking. That is
# why nothing stores a "held" flag anywhere: held is derived from this node
# existing, so an exchange that ends cannot leave somebody frozen for ever.

var initiator: Person
var recipient: Person

# WHEN IT STARTED AND HOW LONG IT RUNS, in REAL SECONDS off the broker's own
# monotonic count. A STAMP, NOT A TIMER — the pattern Workstation.claimed_on_day
# and Obligation.received_on_day already use, just against a different clock.
# Nothing counts down and nothing sweeps; "is it over?" is one comparison at read
# time, so this still holds no progress.
var began_at_second := 0.0
var runs_for_seconds := 4.0

# WHAT BOTH OF THEM ARE SHOWN DOING. A held man is out of the ballot, so nothing
# would otherwise overwrite the clip he was wearing when he was stopped — W8's
# open item, which is exactly what ruins the feel of a greeting: you wave and he
# stands there asleep on his feet. Kept here rather than pushed onto either man
# because it is the same fact for both, and it is cleared from both when this
# node dies. It is WHO/WHAT, like initiator and recipient — not progress.
var performing: Action

# THE REPLY, AND IT IS THE EXCHANGE'S OWN CHILD. Instanced here rather than
# learned into the answerer's Brain, because nobody CHOOSES to answer — it is not
# a verb he could pick, and putting it on his ballot would let him do it to
# somebody who never spoke to him. Freed with this node, so an exchange that ends
# takes its whole performance with it.
var answering: Action
var answers_after_seconds := 1.2


func is_answer_due(now_in_seconds: float) -> bool:
	return now_in_seconds - began_at_second >= answers_after_seconds


# Made once. Returns null if there is nothing authored to answer with, which is a
# real answer — an exchange whose reply is silence.
func begin_answering(answer_scene: PackedScene) -> Action:
	if answering != null or answer_scene == null:
		return null
	var made := answer_scene.instantiate() as Action
	if made == null:
		push_warning("an exchange was authored an answer that is not an Action")
		return null
	add_child(made)
	answering = made
	return made


# Is this what either of them is doing on this exchange's account? Asked so that
# tearing down clears only what this node put there and leaves alone anything a
# man has since been given.
func is_performing(action: Action) -> bool:
	if action == null:
		return false
	return action == performing or action == answering


func is_over(now_in_seconds: float) -> bool:
	return now_in_seconds - began_at_second >= runs_for_seconds


# Both halves through is_instance_valid, per CLAUDE.md's standing rule: a man
# who was freed does NOT null your reference, so `== null` stays false and the
# next property read errors. An exchange with a dead participant is over.
func is_still_standing() -> bool:
	return is_instance_valid(initiator) and is_instance_valid(recipient)


func involves(person: Person) -> bool:
	if person == null:
		return false
	return person == initiator or person == recipient


# Who the other one is, from either side. Written as a question rather than
# left to callers so that nothing outside this file has to know which of the
# two fields it is holding.
func get_other_party(person: Person) -> Person:
	if person == initiator:
		return recipient
	if person == recipient:
		return initiator
	return null


# TURN THEM TOWARD EACH OTHER. The body, never the man — person.gd's rule, and
# for its own reason: global_position is what every gate and distance reads, and
# his own rotation means nothing at all.
#
# IT LOSES TO WALKING FOR FREE, which is why this can be written every frame
# without arbitrating anything. Heading is only ever written by _show_the_body
# inside its moving branch, so a man walking away overwrites this the same frame
# and a man standing still keeps it. "Moving wins" already decided this.
func face_each_other() -> void:
	if not is_still_standing():
		return
	_turn(initiator, recipient.global_position)
	_turn(recipient, initiator.global_position)


func _turn(person: Person, toward: Vector3) -> void:
	var body := person.get_node_or_null(^"Body") as Node3D
	if body == null:
		return
	var flat := Vector3(toward.x - person.global_position.x, 0.0,
		toward.z - person.global_position.z)
	if flat.length() < 0.01:
		return
	body.rotation.y = atan2(flat.x, flat.z)


# How far apart the two of them are, in metres. A fact about the world, asked
# fresh, never remembered — the broker compares it against its own reach to
# decide whether this conversation is still happening at all.
#
# INF WHEN THERE IS NOBODY TO MEASURE, which is deliberately the answer that
# ENDS the exchange rather than the one that preserves it. A lapsed participant
# must never read as "still close enough": that is the direction in which a bug
# holds somebody for ever, and the other direction merely ends a conversation
# early.
func get_distance_apart() -> float:
	if not is_still_standing():
		return INF
	return initiator.global_position.distance_to(recipient.global_position)


func describe() -> String:
	if not is_still_standing():
		return "a lapsed exchange"
	return "%s ⇄ %s" % [initiator.person_name, recipient.person_name]
