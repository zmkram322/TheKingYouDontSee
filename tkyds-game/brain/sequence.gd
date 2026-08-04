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


# Only the child actually being worked on can make the sequence impossible.
# A later child having nothing to offer yet says nothing — by the time the
# work reaches it, the world will have moved.
func is_possible(who) -> bool:
	for child in children:
		if not child.is_satisfied(who):
			return child.is_possible(who)
	return true


# Give the time to the first child that isn't done. If that finishes it, the
# rest still have to be checked before the sequence as a whole can claim to be
# satisfied — but only the ones after it, since everything before was already
# done on the way in.
func advance(who, delta: float) -> bool:
	for i in children.size():
		var child := children[i]
		if child.is_satisfied(who):
			continue
		if not child.advance(who, delta):
			return false
		for j in range(i + 1, children.size()):
			if not children[j].is_satisfied(who):
				return false
		return true
	return true


func describe(who) -> String:
	for child in children:
		if not child.is_satisfied(who):
			return child.describe(who)
	return ""
