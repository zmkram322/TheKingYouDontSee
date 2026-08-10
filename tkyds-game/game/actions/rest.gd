class_name Rest
extends ActionStep

# Lying there. Does nothing at all, and that's the point.
#
# The adenosine clearing that used to live here now happens in the brain's own
# drift, driven by whether he's asleep — because being asleep is what clears
# it, not this particular step. Anything else that ever puts him under (a
# faint, a knock on the head) gets the same recovery without copying a line.
#
# So all this is now is the name of what you'd see. Never done, because sleep
# doesn't end by finishing — it ends by Wake outbidding it.


func is_done(_person: Person) -> bool:
	return false


func advance(_person: Person, _hours: float) -> bool:
	return false


func describe(_person: Person) -> String:
	return "out cold"
