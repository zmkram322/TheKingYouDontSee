class_name Wake
extends Action

# Get up. Only open to him while he's asleep, which is what makes it Sleep's
# opponent for exactly the stretch that matters and nobody's the rest of the
# time.
#
# `pull` is the bottom of the band — he keeps sleeping while adenosine is above
# it, and gets up once it falls below. Read it as "how rested he has to be
# before he'll get out of bed". Together with StayUp's `pull` it's the whole
# cycle in two numbers: turns in at 45, gets up at 10.
#
# The distance between those two is what stops him twitching. If they were the
# same number, the tick that drops him below it would put him straight back
# above it, forever. Sleeping most of the way down before getting up is both
# how bodies work and, for free, the thing that makes the cycle stable.

# He gets up once adenosine falls below this.
@export var pull := 10.0


func can_do(who: Person) -> bool:
	return not who.stats.value_of(&"awake")


func wants(_who: Person) -> float:
	return pull
