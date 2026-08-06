class_name BeUp
extends ActionStep

# Being up, and nothing more specific than that. The placeholder every real
# waking action will eventually outbid.
#
# It does no work — the tiredness that used to be added here now happens in the
# brain's drift, because getting tired is a consequence of being awake, not of
# this particular way of being awake. That's what stops "work the field" from
# needing to remember it too.
#
# Never done. There's no end to being up; it stops because something outbids
# it, which for now means adenosine climbing past StayUp's pull.


func is_done(_person: Person) -> bool:
	return false


func advance(_person: Person, _delta: float) -> bool:
	return false


func describe(_person: Person) -> String:
	return "up and about"
