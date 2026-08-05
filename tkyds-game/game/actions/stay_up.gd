class_name StayUp
extends Action

# Be up and about. Nothing in particular — this is the placeholder every other
# waking action will eventually outbid, and for now it's the only thing
# competing with sleep while he's awake.
#
# It is also, quietly, half of the sleep cycle. `pull` is a flat number, so
# Sleep (which wants exactly as much as his adenosine) beats it the moment
# adenosine climbs past it. That makes `pull` literally "how tired he gets
# before he turns in", readable as a number rather than buried in a curve.
#
# The other half is in wake.gd, and the gap between the two is the point: he
# falls asleep at 45 but doesn't get up until 10, so there's a wide band
# between "start sleeping" and "stop sleeping" instead of one line to sit on
# and jitter across. That gap is why the brain can re-decide every single tick
# without flickering, and it's the biology doing the work — you don't wake the
# instant you're a shade less tired than when you dropped off.

# Sleep wins once adenosine climbs past this.
@export var pull := 45.0


func can_do(who: Person) -> bool:
	return who.stats.value_of(&"awake")


func wants(_who: Person) -> float:
	return pull
