class_name Activity
extends RefCounted

# The state machinery, kept to its smallest honest shape: an actor is always
# doing exactly one Activity; when it reports finished, whoever owns the
# actor decides what happens next. Subclasses override the three methods
# below; nothing in this file knows about walking, performing, or the
# sandbox — that knowledge lives entirely in the subclasses that need it.

var finished := false


func begin() -> void:
	pass


func advance(_delta: float) -> void:
	pass


func describe() -> String:
	return ""   # the label the skin prints over the actor's head
