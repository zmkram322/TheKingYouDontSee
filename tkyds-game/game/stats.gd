class_name Stats
extends Node

# Everything true about one character that anything else is allowed to read.
# Lives as its own Node under them, so you can select Zoogs in the running
# scene and watch his numbers move in the inspector without printing anything.
#
# A plain Node rather than a Resource on purpose: this is per-Zoogs runtime
# state that changes every frame and means nothing outside this run. Resources
# earn their keep for authored data you want to save, preset, and swap — which
# is what the tuning block will be, and why it will be a different object from
# this one. Runtime state and authored constants don't share a box.
#
# Two ways in:
#
#   The @export below is the one you look at and drag. Named, typed, visible,
#   and editable live while the game runs.
#
#   value_of() / set_value() are the one everything else uses. They take a
#   stat's NAME rather than touching the field, which is what lets a graph
#   panel plot "adenosine" without being written to know what adenosine is,
#   and what lets a stat later become a derived reading — "how tired does he
#   LOOK to someone watching" — by changing these two methods and nothing
#   else. That only stays true while everything goes through them, so nothing
#   outside this file should reach for the field directly.


# --- Adenosine ----------------------------------------------------------------
# The sleep-pressure stat, and the only one for now.
#
# The brain spends ATP to stay awake and adenosine is what's left over, so it
# accumulates for as long as he's up — the longer awake, the more of it. Past
# a point it damps the wakefulness centres and he reads as drowsy. Sleep is
# what clears it: the built-up adenosine gets swept back into energy, and he
# wakes with the meter near empty.
#
# So it is not a need that gets met and then stops. It's a tide that rises all
# day and only goes out when he sleeps, which is what makes it the right first
# stat — it gives the day/night cycle something to actually push on.
@export var adenosine := 0.0


# --- Awake --------------------------------------------------------------------
# Yes or no. There is no half — if grogginess ever matters it gets its own
# stat, derived off adenosine; being awake stays a plain fact.
#
# Nobody sets this from outside. It's set by the *doing* — Rest holds it false
# while he's actually sleeping, WakeUp puts it back — so being asleep is a
# consequence of sleeping rather than a flag someone has to remember to clear.
@export var awake := true


# What a stat currently reads, in whatever type it was declared as: a number
# comes back a number, a yes/no comes back a yes/no. An unknown name comes back
# as `fallback` rather than erroring, so only what differs from nothing has to
# be set.
#
# Callers should say what they expect — `var tired: float = stats.value_of(...)`
# — which both documents the stat and catches the day someone changes its type
# underneath them.
func value_of(what: StringName, fallback = 0.0) -> Variant:
	if what in self:
		return get(what)
	return fallback


# Setting a stat nobody declared is a typo, not a new stat — the fields here
# are the whole list, so inventing one silently would give you a value that
# never shows up in the inspector and never gets plotted.
func set_value(what: StringName, value) -> void:
	if not (what in self):
		push_warning("no stat called \"%s\" — a stat name is misspelled or was never added" % what)
		return
	set(what, value)


# Every stat there is, by name. This is what a graph panel asks so it can offer
# you something to plot without anyone having to list them twice.
func names() -> Array[StringName]:
	var found: Array[StringName] = []
	for property in get_script().get_script_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			found.append(property.name)
	return found
