class_name Step
extends Node

# Something that can be done — the WHAT under an Action's WHY. "Walking to the
# inn." "Lying there clearing adenosine."
#
# A Step holds NO progress. No finished flag, no elapsed timer, no
# which-child-am-I-on. Every question is answered by looking at the world
# again: "am I at the inn?" is answered by where he's standing, never by
# remembering that a walk was started.
#
# That's not tidiness, it buys two specific things:
#
#   Interrupting costs nothing. Nothing was suspended, so nothing has to be
#   put back. The next tick re-asks and carries on from wherever he now is.
#
#   The numbers on this node mean the same thing for everybody. Because it
#   stores nothing about who's doing it, editing the file changes what the
#   work IS, not what anyone's mid-way through.

# Is this already done, as far as the world is concerned? Default true, so a
# Step that does nothing doesn't hold anyone up.
func is_done(_who: Person) -> bool:
	return true


# Could this be done at all right now? Different from being done, and the
# difference matters: without it, "there is nowhere to eat" and "I have
# finished eating" are the same answer, and he reads as having eaten when in
# fact he couldn't. Most Steps are always possible — walking somewhere is
# possible even from far away — so only one that can genuinely run out of
# options says otherwise.
func is_possible(_who: Person) -> bool:
	return true


# Do a slice of it, and say whether it's now done. Answering here is what lets
# a caller ask once per tick — advancing and then asking separately re-runs
# everything over a world the advance just changed.
func work_on(_who: Person, _delta: float) -> bool:
	return true


# What he'd be seen doing. Takes the person because anything holding other
# Steps can only say which part it's on by looking, same as everything else
# here.
func describe(_who: Person) -> String:
	return ""
