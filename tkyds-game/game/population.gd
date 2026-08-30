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


# --- The step loop ---------------------------------------------------------------

# HOW BIG ONE TICK IS, in real seconds, before the day-length slider is applied.
# 1/60th, so a normal frame at 60fps is exactly one tick and the common case
# does no extra work at all.
#
# It is REAL SECONDS rather than world hours on purpose. day_length_seconds is
# the author's statement of how much world time a real second buys, and at the
# 1-second floor he is deliberately asking for enormous jumps so a whole day can
# be watched in a blink. A quantum denominated in hours would fight that — it
# would keep throwing away the very time the slider was dragged to produce. In
# real seconds the slider goes on meaning exactly what it says, and the quantum
# only ever bounds how much simulation happens between two decisions.
const TICK_SECONDS := 1.0 / 60.0

# The ceiling on how many ticks one frame may buy. Past this, real time is
# DROPPED rather than simulated.
#
# It is what stops the spiral: a five-second stall at 60 ticks a second is 300
# ticks, and if running them takes longer than the frame they were owed to, the
# next frame owes even more and the game never catches up again. Better to lose
# a moment of world honestly than to freeze.
#
# 8 is two frames' worth at 30fps and is a guess. It wants measuring against a
# real stall rather than defending in the abstract.
const MAX_TICKS_PER_FRAME := 8

# Real seconds owed but not yet worth a whole tick, carried to the next frame.
#
# THE ONE PIECE OF STORED PROGRESS IN THIS FILE, and it earns it: without a
# carry, every frame would round its leftover down to nothing and the world
# would run measurably slow — a 1/90th-second frame against a 1/60th tick would
# buy zero ticks, for ever. It is bounded below one tick by construction.
var _seconds_owed := 0.0


func _process(delta: float) -> void:
	step_real_time(delta)


# Turn real seconds into whole ticks, and run them.
#
# A SEPARATE FUNCTION FROM _process SO IT CAN BE MEASURED. The probe runs
# everything PROCESS_MODE_DISABLED and pumps think_for_everyone by hand, so
# nothing it does would ever reach a _process body — and an accumulator nobody
# can hand a five-second stall to is an accumulator nobody has checked. This is
# the door a claim knocks on.
#
# WHY A FIXED QUANTUM AT ALL, restated because it is the whole point: the ballot
# opens ONCE per tick. Hand a man two hours in one step and he gets one decision
# to cover them — he does not wake, eat and walk to the field, he skips through
# all three. The arithmetic would survive it (every rate here is per hour, so
# one big step and many small ones integrate the same), but the DECIDING does
# not. So a slow frame buys MORE ticks, never a bigger one — which is what
# Decision 39 says, said in code rather than in prose.
func step_real_time(real_seconds: float) -> void:
	if clock == null:
		return
	# Negative or non-finite deltas are not a thing Godot should hand us, and a
	# NaN here would poison hours_elapsed permanently — one stored fact, no way
	# back. Cheaper to refuse it than to find it three days later.
	if not is_finite(real_seconds) or real_seconds <= 0.0:
		return
	_seconds_owed += real_seconds
	var ticks := 0
	while _seconds_owed >= TICK_SECONDS and ticks < MAX_TICKS_PER_FRAME:
		_seconds_owed -= TICK_SECONDS
		var hours := clock.get_hours_elapsed(TICK_SECONDS)
		# THE CLOCK MOVES FIRST, then the people, and both by the SAME number.
		# Advancing it anywhere else is how the sun and the body drifted apart
		# once already; advancing it by a different number would be the same bug
		# wearing a fixed step.
		clock.advance(hours)
		think_for_everyone(hours)
		ticks += 1
	# Past the ceiling, the debt is forgiven rather than carried. Carried, a
	# machine that cannot keep up accrues an ever-growing backlog it will never
	# work off, and the game falls further behind every frame until it stops
	# responding. Dropped, it simply runs slow while the stall lasts and is
	# correct again the moment it ends.
	if _seconds_owed >= TICK_SECONDS:
		_seconds_owed = 0.0


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
