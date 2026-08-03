class_name State
extends RefCounted

# The one execution primitive, kept to its smallest honest shape: an actor
# is always running exactly one State; when it reports finished, whoever
# owns it decides what happens next. A State is either a leaf (WalkTo,
# Perform, Wait — nothing here knows about walking or performing, that
# knowledge lives entirely in the subclasses that need it) or a composite
# that sequences other States (see SequenceState) — same base, same
# contract, so composites nest for free.

var finished := false


func begin() -> void:
	pass


func advance(_delta: float) -> void:
	pass


func describe() -> String:
	return ""   # the label the skin prints over the actor's head


# The full remaining step list, flattened — a leaf is just itself; a
# composite recurses into whichever children haven't run yet. Lets an
# inspector show the whole plan without knowing whether it's looking at one
# step or a nested sequence.
func describe_all() -> Array[String]:
	return [describe()]
