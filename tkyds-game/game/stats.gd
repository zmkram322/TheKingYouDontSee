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


# --- Strength -----------------------------------------------------------------
# How much body he has. A multiplier around 1.0, where 1.0 is an ordinary man.
#
# Today it does one thing: he clears adenosine faster while asleep, so a strong
# man needs less sleep and is up before everyone else. That is the whole of the
# difference between two farmers racing for one plot at dawn — not a different
# opinion about being awake, which would be the action differing by who you are,
# but a different body running the same formula everybody else runs.
#
# It goes on RECOVERY and deliberately not on how fast he tires, and that is a
# measurement rather than a preference. Bedtime is where rising tiredness
# crosses the sun's line, so a man who tires slowly reaches it LATER and gets up
# later — 2.25/hr put him to bed at 23:57 and out of it at 07:21, an hour and a
# half after everybody else. Worse, it runs at a cliff: below about 2.15/hr the
# sun's line never catches him at all and he stays awake for thirty-nine hours
# at a stretch. Recovery has no such trap in this direction. Measured
# 2026-08-10; see Decision 11.
#
# THE SAFE BAND, also measured: recovery holds its hour down to about 4.5/hr and
# starts drifting at 4.0 — so strength below roughly 0.9 unhooks him from the
# sun. Upward there is room to spare; 8.0/hr (strength 1.6) still locks, and
# puts him up at 02:05.
#
# It will mean more than this. Rung 3's work step wants a rate of work done per
# hour and rung 5 wants how much a man can carry; both are the same capacity and
# neither needs a second stat. And when strength has to CHANGE during a run — a
# wound, age, a winter — it already does, because it is a stat rather than a
# number typed into a scene.
@export var strength := 1.0


# --- Hunger -------------------------------------------------------------------
# The gap between what he's eaten and being fed. It rises the whole time he is
# alive — awake or asleep, working or idle, per Brain._update_body's one
# unbranched line — because a body burns fuel regardless of what its owner is
# up to. It falls only when he eats (see actions/eat_step.gd), which is the
# one effect this stat is allowed to have written into it from outside upkeep.
#
# 0–100, where 0 is a man who just ate and 100 means "as hungry as a person
# gets" — NOT "dead". Read that the same way adenosine's ceiling above already
# asks you to: a hundred adenosine is a man desperate to sleep, not a man
# killed by sleep deprivation, and a hundred hunger is the same shape of claim
# about food. Treating a felt gap as a lethal one is exactly the mistake
# Decision 27 was written to head off.
#
# Starving — how long a want this large has gone unanswered — is a second,
# slower gap layered on top of this one, and it is NOT built here. This stat
# only ever says how hungry he feels right now, never how long he's been that
# way.
@export var hunger := 0.0


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
