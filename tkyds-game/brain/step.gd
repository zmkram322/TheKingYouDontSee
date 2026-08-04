class_name Step
extends RefCounted

# Something that can be done. A Step answers three questions and holds no
# progress of its own: whether it's already satisfied, whether it could be
# satisfied at all, and how to make a bit more headway toward that.
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


# Could this be done at all right now? Distinct from being satisfied, and the
# distinction is load-bearing: without it "there is nowhere to eat" and "I have
# finished eating" are the same answer, and a character reads as having eaten
# when in fact she cannot. Most Steps are always possible — walking somewhere
# is possible even from far away — so the default is true and only a Step that
# can genuinely run out of options says otherwise.
func is_possible(_who) -> bool:
	return true


# Make progress toward being satisfied, and answer whether it now is. Returning
# the answer is what lets a caller ask once per tick: the alternative — advance,
# then ask again — re-runs the whole tree over world state the advance just
# changed, and can be answered by a different option than the one that did the
# work. Already-satisfied is not an error here; it simply does nothing and
# returns true.
func advance(_who, _delta: float) -> bool:
	return true


# What the character would be seen doing right now — takes the subject because
# a composite can only say which part it's on by re-deriving it, same as
# everything else here.
func describe(_who) -> String:
	return ""
