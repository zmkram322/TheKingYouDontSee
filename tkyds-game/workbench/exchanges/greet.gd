extends "res://workbench/exchanges/exchange_action.gd"

# The first exchange, and now the ONLY WAY INTO ONE. Deliberately the smallest
# thing that can exist: it names a target, it draws on the arc, it opens the
# conversation, and it changes nothing about what either man wants.
#
# IT REQUIRES NOTHING OF THE MAN, WHICH IS WHY IT IS THE WAY IN. Give and ask
# author `needs_to_have_met`; a greeting authors nothing, so it is the only thing
# over a stranger's head — not because this file checks for one, but because
# everything else asks for a record that only a greeting can leave.
#
# No utility score is overridden, so it inherits Action's default of 0.0 — and
# that is correct rather than lazy. A player's verb is never scored: PlayerBrain
# hands back whatever a hand chose and get_highest_scoring is never called for
# him at all. A score here would be a number nobody reads.
#
# No settle() either, so it inherits the base — which lands whatever the two
# PackedScene slots hold, and greet.tscn authors neither. A GREETING THAT LEAVES
# NOTHING BEHIND IS THE HONEST DEFAULT until Gate 2 cuts standing; the point of
# the seam is that the day a greeting DOES move standing, greet.tscn gains a
# scene in a slot and this file still says nothing.


# Nobody greets in his sleep. The one thing on this gate is about the GREETER,
# and it is asked through the shared engine exactly like every other action's.
func is_available_to(person: Person) -> bool:
	return person.brain.is_awake()


# And nobody greets a sleeping man — he would not see it. This is the target
# half, the half Decision 35 says nothing in game/ is allowed to ask, asked here
# on purpose.
#
# THE BASE HALF IS RE-ASKED THROUGH is_regarded_enough RATHER THAN DROPPED.
# Overriding is_available_toward replaces the base entirely, so an override that
# forgot this line would silently ignore whatever regard the action authored.
# Greeting requires none, so today it changes nothing — which is exactly when a
# missing call is easiest to leave out and hardest to notice.
func is_available_toward(person: Person, target: Person) -> bool:
	return is_regarded_enough(person, target) and target.brain.is_awake()
