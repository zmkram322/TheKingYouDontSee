extends Population

# Population, minus whoever is mid-conversation.
#
# THE SEAM IS INHERITED, NOT CUT. population.gd's own header says the reason
# this node exists is that it is a CALL SITE — "everything later installs here
# and nowhere else... The engine must never have called a Brain directly,
# because every one of those would then be a change to every Person instead."
# An interrupt is precisely one of those laters. It installs by overriding one
# function, and not one line of game/ moves.
#
# WHAT THIS BREAKS, SAID OUT LOUD (see W1 in DECISIONS.md). The substrate rests
# on re-deciding every tick: "interrupting costs nothing because nothing was
# suspended, so nothing needs restoring." A man who is not thinking is
# suspended, which this design has refused everywhere else.
#
# BUT IT KEEPS THE OTHER HALF OF THAT RULE. Nothing here STORES who is held.
# An earlier cut kept a _held array on this node and that was the wrong shape:
# a flag somebody has to remember to clear is a man frozen for ever the first
# time somebody forgets. Held is DERIVED — he is held if and only if the broker
# has a live exchange naming him. There is one fact, in one place, and it is
# the existence of a node.
#
# THE SERIAL LOOP IS PRESERVED. population.gd is emphatic that people are
# walked one at a time with nothing running in between, because that is what
# makes contention correct with no locking anywhere. Skipping a man does not
# break that. An await, a thread or a call_deferred here would.

# Who is talking to whom. Typed as Node rather than against the broker script:
# a node-reference export needs a registered class to survive a hand-written
# .tscn, and no script under workbench/ takes a class_name. Asked through call()
# below, which is honest about the fact that this is a dynamic edge.
@export var broker: Node


func _ready() -> void:
	super()
	if broker == null:
		push_warning("this Population has no exchange broker — nobody will ever be interrupted")


# Everything Population does, minus the people in an exchange.
func think_for_everyone(hours: float) -> void:
	for child in get_children():
		if not is_instance_valid(child):
			continue
		var person := child as Person
		if person == null:
			continue
		if is_held(person):
			# HELD OUT OF THE BALLOT, NOT OUT OF TIME. The first cut of this
			# `continue` skipped the man entirely, and that was a bug rather
			# than the interrupt it looked like: upkeep is the tail of
			# think_and_act, so a man in a conversation stopped hungering,
			# stopped tiring and stopped getting lonely for as long as he was
			# talking. Long enough exchange and standing still listening was a
			# free night's rest. It also froze the clip he was wearing — see
			# Person.run_upkeep for that half.
			#
			# The interrupt this scene is actually testing is on his DECIDING,
			# and only that. His body was never supposed to be in it.
			person.run_upkeep(hours)
			continue
		person.think_and_act(hours)


# Derived, never stored. The one question this node asks the broker.
func is_held(person: Person) -> bool:
	if broker == null or person == null:
		return false
	var answer: Variant = broker.call(&"is_in_an_exchange", person)
	return answer == true
