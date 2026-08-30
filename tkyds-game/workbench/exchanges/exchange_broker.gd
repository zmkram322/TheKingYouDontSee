extends Node

# WHO IS TALKING TO WHOM. One node, one place, everything installs here.
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
	var already := get_exchange_for(recipient)
	if already != null:
		# Not an error. He is mid-conversation and the second asker simply does
		# not get him — which is a refusal of a kind, and the first honest one
		# in the system.
		return null
	var exchange := Exchange.new()
	exchange.name = "%s_and_%s" % [initiator.person_name, recipient.person_name]
	exchange.initiator = initiator
	exchange.recipient = recipient
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
	if exchange.get_parent() == self:
		remove_child(exchange)
	exchange.queue_free()


func end_for(person: Person) -> void:
	end(get_exchange_for(person))


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
		# Swept on the way past rather than in a tidy-up pass, so nothing has to
		# remember to run one. A conversation whose other party was freed is
		# over, and leaving it standing would hold the survivor for ever.
		if not exchange.is_still_standing():
			exchange.queue_free()
			continue
		if exchange.involves(person):
			return exchange
	return null


func get_live_exchanges() -> Array:
	var standing: Array = []
	for child in get_children():
		var exchange := child as Exchange
		if exchange != null and exchange.is_still_standing():
			standing.append(exchange)
	return standing
