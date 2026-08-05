class_name Rest
extends Step

# Lie there and let the day drain off. The sleeping half of adenosine: while
# he's out, the built-up waste gets swept back into energy and the meter falls.
#
# Setting `awake` here rather than in Sleep's own code is deliberate — being
# asleep is a consequence of *doing* the sleeping, not of having decided to.
# If something outbids him mid-nap he stops being asleep by simply not doing
# this any more, and nothing has to be told to undo it.

# Roughly 2.5× the rate BeUp puts it on, so a night is a good deal shorter
# than a day. Adjustable per person straight on his own copy of the node.
@export var cleared_per_second := 2.5


func is_done(who: Person) -> bool:
	var tired: float = who.stats.value_of(&"adenosine")
	return tired <= 0.0


func work_on(who: Person, delta: float) -> bool:
	who.stats.set_value(&"awake", false)
	var tired: float = who.stats.value_of(&"adenosine")
	who.stats.set_value(&"adenosine", maxf(0.0, tired - cleared_per_second * delta))
	return is_done(who)


func describe(_who: Person) -> String:
	return "out cold"
