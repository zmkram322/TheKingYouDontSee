class_name BeUp
extends Step

# Being awake, and paying for it. The waking half of adenosine: the brain
# spends energy all day and this is the waste piling up behind it.
#
# Never done — there is no end to being up. It stops because something outbids
# it, which here means adenosine climbing past StayUp's pull and Sleep winning.
# That's the day ending because he got tired, not because a timer said so.

@export var per_second := 1.0

# A backstop, not a tuned number. Nothing should ever sit here — if it does,
# something is stopping him sleeping and you want the graph to flatline
# visibly rather than the number running away.
@export var ceiling := 100.0


func is_done(_who: Person) -> bool:
	return false


func work_on(who: Person, delta: float) -> bool:
	var tired: float = who.stats.value_of(&"adenosine")
	who.stats.set_value(&"adenosine", minf(ceiling, tired + per_second * delta))
	return false


func describe(_who: Person) -> String:
	return "up and about"
