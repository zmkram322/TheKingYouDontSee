class_name Step
extends RefCounted

# Something that can be done. A Step answers two questions and holds no
# progress of its own: whether it's already satisfied, and how to make a bit
# more headway toward that.
#
# There is deliberately no `finished` flag, no current-child index, and no
# elapsed timer anywhere in a Step. Satisfaction is re-derived from the world
# every time it's asked — "am I at the inn?" is answered by looking at where
# the character is standing, not by remembering that a walk was started. Two
# consequences follow, and both are the point:
#
#   Interrupting costs nothing. Nothing was suspended, so nothing has to be
#   restored; the next tick simply re-asks and carries on from wherever the
#   character now is.
#
#   Steps are shareable. Because a Step stores nothing about who is doing it,
#   one Step object can be used by every character in the world at once — it's
#   a description of work, not an attempt at it.
#
# `who` is the subject, and stays opaque here the same way it does in
# DecisionBrain: a Step only ever hands it to a leaf that knows what to read.


# Is this already done, as far as the world is concerned?
func is_satisfied(_who) -> bool:
	return true


# Make progress toward being satisfied. Called only when it isn't.
func advance(_who, _delta: float) -> void:
	pass


# What the character would be seen doing right now — takes the subject because
# a composite can only say which part it's on by re-deriving it, same as
# everything else here.
func describe(_who) -> String:
	return ""
