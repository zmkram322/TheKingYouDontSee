class_name Sequence
extends Step

# Do these, in order. Satisfied once every child is.
#
# Note what isn't here: no index, no "current child", no bookkeeping at all.
# Every tick it re-asks which child isn't done yet and gives that one the time.
# A child that becomes satisfied by some other means — the character was
# already home, or someone carried them there — is simply skipped next tick
# without anything having to notice or be told.

var children: Array[Step] = []


func _init(new_children: Array[Step] = []) -> void:
	children = new_children


func is_satisfied(who) -> bool:
	for child in children:
		if not child.is_satisfied(who):
			return false
	return true


func advance(who, delta: float) -> void:
	for child in children:
		if not child.is_satisfied(who):
			child.advance(who, delta)
			return


func describe(who) -> String:
	for child in children:
		if not child.is_satisfied(who):
			return child.describe(who)
	return ""
