class_name Population
extends Node

# Who thinks, and when. Everyone alive in this world is a child of this node,
# and this is the one place their thinking is driven from.
#
# It is a `for` loop. That is the whole of it, deliberately — no stagger, no
# jitter, no frame budget, no priority tiers, no tick-rate export. What earns
# the node at one person on screen is not what it does today but the fact that
# it is a CALL SITE: everything later installs here and nowhere else. A budget,
# promoting a distant village to full simulation and collapsing it again,
# replaying a run tick-for-tick — all of it is a change to this loop. The engine
# must never have called a Brain directly, because every one of those would then
# be a change to every Person instead.
#
# TWO OF THOSE LATERS HAVE SINCE BEEN RULED OUT, and this is where somebody
# would come looking for permission to build them:
#
#   COLLAPSING A DISTANT VILLAGE MEANS UNBOUNDED BY THE FRAME RATE. It does NOT
#   mean bigger `hours`. Decision 39: a region far from the player runs the same
#   size ticks as everybody else, just as fast as it can with nothing drawn —
#   which is exactly what probe.gd already does. Hand one region four hours
#   where another gets a hundredth and it behaves differently: a man loses no
#   decisions to a conversation that would cost him twenty, a dawn race becomes
#   whoever this loop reaches first, and any threshold crossed and re-crossed
#   inside the tick never happened. Watched-versus-unwatched divergence is the
#   one bug class where looking at it changes it. A region too expensive to keep
#   current may run FEWER ticks per frame and fall behind; it may not run bigger
#   ones.
#
#   SPREADING PEOPLE ACROSS FRAMES IS OUT ENTIRELY — it was listed here as a
#   later and it is not one. Half the town this frame and half the next breaks
#   the serial guarantee below, which is the whole reason contention needs no
#   locking. Splitting BETWEEN ticks is safe. Splitting WITHIN one is not.
#
# It is also where real time stops. Population reads the Clock once per tick and
# hands the same `hours` to everybody, so nothing below this node ever sees a
# real second and nobody can convert twice. One clock read for the whole town
# rather than one per body, which is the smaller reason and still a good one.
#
# WHY THE LOOP IS SERIAL, and why that matters more than it looks:
#
#   People are walked one at a time, in order, and each one finishes thinking
#   and acting before the next one starts. That is what makes contention
#   correct with no locking anywhere — when two farmers want the same plot, the
#   first one asked gates, scores and claims it with nothing running in
#   between, so the second one simply finds it taken. There is no window for
#   them both to see it free.
#
#   Put a `call_deferred` in here, or a thread, or an `await`, and that stops
#   being true — silently, and only under contention, which is the hardest kind
#   of bug this project could have. If this loop ever needs to not be serial,
#   the claiming has to be rewritten first.

# Where real time becomes world time. Dragged in from the inspector rather than
# found by path, so moving either node doesn't silently break the link.
#
# Note for whoever wires this in a .tscn by hand: it needs
# `node_paths=PackedStringArray("clock")` on the node's own header line, or the
# loader assigns the raw NodePath to a typed field and you get null.
@export var clock: Clock

# The world the people live in. Population never reads this itself — it is here
# so that ONE wire in the scene feeds every person underneath, instead of one
# per person. Thirteen hand-typed NodePaths at rung 9 is thirteen chances at the
# trap that already shipped a dead day/night cycle here.
#
# Each Person picks it up off this field in his own _ready, the same way Brain
# finds its Person by asking its parent. Handing it down from here instead would
# arrive too late to be checked: Godot readies children before parents, so every
# person would have already looked and found nothing.
#
# No warning here on purpose — the person who wants it warns by name, which
# tells you WHO is standing there unable to ask questions about the world.
@export var town: Town


# Says so out loud rather than standing there quietly doing nothing. A
# Population with no Clock never advances anybody, and without this that is
# indistinguishable from a town that simply isn't tired yet.
func _ready() -> void:
	if clock == null:
		push_warning("Population has no Clock — nobody will ever think")


func _process(delta: float) -> void:
	if clock != null:
		think_for_everyone(clock.get_hours_elapsed(delta))


# One slice of living for everybody, in world HOURS — the same slice for each
# of them, read from the Clock once above.
#
# It takes hours rather than a real delta so that a harness can pump a day in a
# fraction of a second and mean it: `think_for_everyone(1.0)` IS one hour, and
# twenty-four calls IS a day, at any day length. Do the conversion in here
# instead and a probe has to pass `day_length_seconds / 24` to get an hour,
# which puts a tuning slider back inside every assertion — the exact flakiness
# rung 0 spent its time removing.
#
# Children are asked for fresh each call rather than cached, because who is
# alive changes and nothing here is expensive. get_children() hands back a
# snapshot, so somebody freed part-way through the loop is still in the list we
# are walking — hence is_instance_valid, which is the difference between a
# verdict and a stack trace. queue_free() does not null your reference.
func think_for_everyone(hours: float) -> void:
	for child in get_children():
		if not is_instance_valid(child):
			continue
		var person := child as Person
		if person == null:
			continue
		person.think_and_act(hours)


# Everyone alive here. Nothing in game/ needs this yet — Town's queries arrive
# at rung 2 and answer different questions — but a driver that can't be asked
# who it drives is a driver you have to reach around, and reaching around this
# node is precisely what it exists to prevent.
func get_people() -> Array[Person]:
	var found: Array[Person] = []
	for child in get_children():
		var person := child as Person
		if person != null:
			found.append(person)
	return found
