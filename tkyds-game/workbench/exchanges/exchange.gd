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


func describe() -> String:
	if not is_still_standing():
		return "a lapsed exchange"
	return "%s ⇄ %s" % [initiator.person_name, recipient.person_name]
