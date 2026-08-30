extends "res://workbench/exchanges/exchange_action.gd"

# The first exchange. Deliberately the smallest one that can exist: it names a
# target, it draws on the arc, and it interrupts him. It changes nothing about
# what either man wants.
#
# No utility score is overridden, so it inherits Action's default of 0.0 — and
# that is correct rather than lazy. A player's verb is never scored: PlayerBrain
# hands back whatever a hand chose and get_highest_scoring is never called for
# him at all. A score here would be a number nobody reads.


# Nobody greets in his sleep. The one thing on this gate is about the GREETER,
# and it is asked through the shared engine exactly like every other action's.
func is_available_to(person: Person) -> bool:
	return person.brain.is_awake()


# And nobody greets a sleeping man — he would not see it. This is the target
# half, the half Decision 35 says nothing in game/ is allowed to ask, asked
# here on purpose.
func is_available_toward(_person: Person, target: Person) -> bool:
	return target.brain.is_awake()
