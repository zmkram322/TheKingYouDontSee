class_name WakeUp
extends Step

# Getting up. One tick's worth — flip awake and it's done.
#
# It doesn't have to tell anyone it finished. Next tick `awake` is true, so
# Wake's own can_do says no, and it simply isn't on the ballot any more. That's
# the whole shape of this substrate: things stop because they stop winning, not
# because something reported success.


func is_done(who: Person) -> bool:
	return who.stats.value_of(&"awake")


func work_on(who: Person, _delta: float) -> bool:
	who.stats.set_value(&"awake", true)
	return true


func describe(_who: Person) -> String:
	return "getting up"
