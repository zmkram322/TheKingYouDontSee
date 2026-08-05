class_name Sleep
extends Action

# Go to sleep. Wanted exactly as much as he's tired — the pull IS the
# adenosine, no curve on top, so the number you watch on the graph is the same
# number driving the decision.
#
# Nothing gates this: sleep is always open to him. What decides whether he
# actually sleeps is what he's being outbid by. Awake, that's StayUp; asleep,
# it's Wake. Two different opponents at two different heights is the whole of
# the sleep/wake cycle — see stay_up.gd for how the gap between them works.


func wants(who: Person) -> float:
	var tired: float = who.stats.value_of(&"adenosine")
	return tired
