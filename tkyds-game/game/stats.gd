class_name Stats
extends Node

# Everything true about one person that anything else is allowed to read.
# Lives as its own Node under them, so you can select Zoogs in the running
# scene and watch his numbers move in the inspector without printing anything.
#
# A plain Node rather than a Resource on purpose: this is per-person state that
# changes every frame and means nothing outside this run. Resources earn their
# keep for authored data you want to save, preset, and swap. Runtime state and
# authored constants don't share a box.
#
# Two ways in:
#
#   The @export below is the one you look at and drag. Named, typed, visible,
#   and editable live while the game runs.
#
#   get_stat / set_stat are the one everything else uses. They take a stat's
#   NAME rather than touching the field, which is what lets a graph panel plot
#   "adenosine" without being written to know what adenosine is, and what lets
#   a stat later become a worked-out reading — "how tired does he LOOK to
#   someone watching" — by changing those two methods and nothing else. That
#   only stays true while everything goes through them, so nothing outside this
#   file should reach for the field directly.


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


# Note what is NOT here: whether he's awake. That's not a fact he carries, it's
# a fact about what he's currently doing, so it's read off the brain
# (Brain.is_awake) rather than stored. A stored copy could disagree with what
# he's actually doing; a worked-out one can't.


# What a stat currently reads, in whatever type it was declared as: a number
# comes back a number, a yes/no comes back a yes/no. An unknown name comes back
# as `fallback` rather than erroring, so only what differs from nothing has to
# be set.
#
# Callers should say what they expect — `var tired: float = stats.get_stat(...)`
# — which both documents the stat and catches the day someone changes its type
# underneath them.
func get_stat(stat_name: StringName, fallback = 0.0) -> Variant:
	if stat_name in self:
		return get(stat_name)
	return fallback


# Setting a stat nobody declared is a typo, not a new stat — the fields here
# are the whole list, so inventing one silently would give you a value that
# never shows up in the inspector and never gets plotted.
func set_stat(stat_name: StringName, value) -> void:
	if not (stat_name in self):
		push_warning("no stat called \"%s\" — a stat name is misspelled or was never added" % stat_name)
		return
	set(stat_name, value)


# Every stat there is, by name. This is what a graph panel asks so it can offer
# you something to plot without anyone having to list them twice.
# Exported only — a stat is something declared for the world to see, so an
# internal working variable added here later shouldn't quietly become one and
# turn up on the graph. (PROPERTY_USAGE_SCRIPT_VARIABLE on its own catches
# both; PROPERTY_USAGE_EDITOR is what tells an @export from a plain var.)
func get_stat_names() -> Array[StringName]:
	var found: Array[StringName] = []
	for property in get_script().get_script_property_list():
		if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if not (property.usage & PROPERTY_USAGE_EDITOR):
			continue
		found.append(property.name)
	return found
