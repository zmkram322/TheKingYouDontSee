class_name ActionStep
extends Node

# The part of an Action that actually does something. "Walking to the inn."
# "Lying there." Named for what it is — a step belonging to an action — so the
# relationship reads off the type instead of having to be looked up.
#
# An ActionStep holds NO progress. No finished flag, no elapsed timer, no
# which-child-am-I-on. Every question is answered by looking at the world
# again: "am I at the inn?" is answered by where he's standing, never by
# remembering that a walk was started.
#
# That's not tidiness, it buys two specific things:
#
#   Interrupting costs nothing. Nothing was suspended, so nothing has to be put
#   back. The next tick re-asks and carries on from wherever he now is.
#
#   The numbers on this node mean the same thing for everybody. Because it
#   stores nothing about who's doing it, editing the file changes what the work
#   IS, not what anyone's mid-way through.


# How hard this is on the body. A multiplier the brain feeds into its own
# tiredness sum — it never touches a stat itself, it just declares how
# strenuous the work is and lets the brain decide what that costs.
#
# It sits on the step rather than the action because that's where the truth is:
# in a walk-there-then-dig sequence, walking and digging are not equally hard,
# and only the step knows which one is happening.
#
# **Default 1.0, never 0.0.** An action nobody thought about should tire you a
# normal amount. If the default were zero, forgetting to set this would quietly
# make the work free, which is the failure you'd never go looking for.
@export var exertion := 1.0


# Is this already done, as far as the world is concerned? Default true, so a
# step that does nothing doesn't hold anyone up.
func is_done(_person: Person) -> bool:
	return true


# Could this be got on with at all right now? Different from being done, and
# the difference matters: without it, "there is nowhere to eat" and "I have
# finished eating" are the same answer, and he reads as having eaten when in
# fact he couldn't. Most steps are always doable — walking somewhere is doable
# even from far away — so only one that can genuinely run out of options says
# otherwise.
func is_doable(_person: Person) -> bool:
	return true


# The only method in the whole system that changes anything. Everything else
# asks questions; this does the work — one tick's worth of it, scaled by how
# much WORLD TIME passed, so he works at the same speed on any machine and at
# any day length.
#
# `hours` is world hours, never real seconds — real time was converted once, up
# in Clock, and is never seen again below it. Every rate a step multiplies by
# this must therefore be authored per world hour too. Naming the argument for
# what it holds rather than calling it `delta` is the whole guard: the two
# units read identically at the shipped 60-second day and diverge everywhere
# else, so a mislabelled one is invisible until somebody drags the slider.
#
# Returns whether it's now done. Answering here is what lets a caller ask once
# per tick: advancing and then asking separately re-runs everything over a
# world the advance just changed. Nothing reads that answer yet — it's for
# Sequence, which isn't ported.
func advance(_person: Person, _hours: float) -> bool:
	return true


# What he'd be seen doing. Takes the person because anything holding other
# steps can only say which part it's on by looking, same as everything else
# here.
func describe(_person: Person) -> String:
	return ""
