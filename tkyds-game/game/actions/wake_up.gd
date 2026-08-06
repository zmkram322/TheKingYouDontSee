class_name WakeUp
extends ActionStep

# Getting up. Does nothing, because winning IS waking up — the brain reads
# whether he's awake off what he's doing, and this isn't sleeping, so choosing
# it is the whole of it.
#
# Done immediately, so it never holds him for more than the tick he chose it.
# The next tick he's awake, Wake's own gate says no, and StayUp takes over.


func is_done(_person: Person) -> bool:
	return true


func advance(_person: Person, _delta: float) -> bool:
	return true


func describe(_person: Person) -> String:
	return "getting up"
