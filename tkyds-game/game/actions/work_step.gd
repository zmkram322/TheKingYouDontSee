class_name WorkStep
extends ActionStep

# The working itself, and — as of rung 4 — getting there first. As of rung 5 it
# is also the first thing in this game that MAKES something: grain, per world
# hour, into the working man's own inventory.
#
# Like every step it holds no progress — nothing on this node, and nothing on
# the man. Which plot he is working is re-derived every tick from the same
# get_best_candidate the gate and score used, who holds the plot lives on the
# plot, how far along the road he is, is where he is standing, and how far into
# the current grain he is lives in the FURROW (Workstation.output_part_made),
# which is why walking away from a part-turned plot costs him nothing and leaves
# the part-turned work for whoever comes next.
#
# ONE advance(), TWO behaviours, chosen by looking rather than by remembering:
# not at the plot's place → walk toward it; at it → claim it and work. There is
# no "I am currently walking" state to get stuck in, which is why a man whose
# plot is taken from under him mid-journey costs nothing to interrupt — the next
# tick simply asks again from wherever his feet now are.
#
# The walking is a GoToStep NESTED UNDER THIS ONE, never a sibling: Action._ready
# takes the first ActionStep child it finds, so two steps under one Action would
# silently pick one and ignore the other. Nesting is also what lets later
# actions reuse walking by hanging one of these under their own step.

# The legs. Found from the children rather than dragged in, because a step's own
# machinery is structurally its child — the same way an Action finds its step
# and a Brain finds its Person. Said out loud when it is missing: without it a
# farmer standing at the Inn would silently never set off, which reads as a
# broken decision rather than as a missing node.
var walk: GoToStep

# What a plot yields. A constant rather than a knob: an export for it would be a
# second authoring surface for what a station makes, and the day a station makes
# something other than grain that comes from a Recipe (rung 9a), which owns the
# output and the time it takes together. One item, named in one place.
const YIELD_NAME := &"grain"

# What a man brings in from a plot in one world HOUR — like every rate in game/,
# and emphatically not per tick. An authored 1.0 means one grain an hour, so at
# the hundredth-of-an-hour tick the game runs he makes a hundredth of a grain a
# tick and the plot holds the remainder until it comes to something. See
# Workstation.output_part_made for why the fraction lives there and not here.
@export var base_grain_per_hour := 1.0


func _ready() -> void:
	for child in get_children():
		if child is GoToStep:
			walk = child
			return
	push_warning("a WorkStep has no GoToStep under it — he can only work a plot he is already standing on")


func advance(person: Person, hours: float) -> bool:
	var work := get_parent() as WorkTheField
	if work == null:
		push_warning("a WorkStep's parent must be a WorkTheField — it has no idea what to work")
		return true
	var station := work.get_best_candidate(person)
	if station == null:
		# Gone between deciding and doing. The serial loop means nothing runs
		# in between today, so this cannot happen yet — kept as a quiet no-op
		# rather than an assumption the day the loop stops being serial.
		return true
	# Not there yet. Note what he does NOT know while he is on the road: whether
	# the plot is still free. Freeness is only visible where you are standing
	# (Decision 15), so he walks the whole way and finds out on arrival — the
	# wasted journey is the point, because it is the collision that later earns
	# a notice board.
	var place := station.get_place()
	if person.get_current_place() != place:
		if walk == null:
			return true
		walk.walk_toward(person, place, hours)
		return false
	# RENEWED BY USE — claim() on EVERY tick this advances, not once at the
	# start. He is present and it is already his, so the call re-stamps today
	# and dawn passes under him; nothing else keeps a claim alive. claim() is
	# also the presence check: a man not standing at the plot's place gets
	# false, and the branch above is what makes that false mean "walk there".
	if not station.claim(person):
		return false
	# THE WORK ITSELF. Everything above this line is about getting to it.
	#
	# IT SITS BELOW THE CLAIM, and that placement is the whole of this rung's
	# trap. advance() grew a second branch at rung 4, so a yield written at the
	# top of this function pays a man for WALKING ACROSS TOWN — which reads as a
	# balance problem, not as a misplaced line, and costs an hour to trace. Down
	# here it is paid for exactly what renew-on-use is paid for: standing on the
	# plot with his hands on it.
	var inventory := person.get_inventory()
	if inventory == null:
		# He has already said so in his own _ready. Banking work he could never
		# collect would leave the plot holding a part-made number that grows
		# without bound, so the work simply does not happen.
		return false
	station.output_part_made += get_yield_per_hour(person) * hours
	# Whole grain comes off the plot and goes in his sack; the fraction stays in
	# the furrow for whoever works it next. Floor-and-subtract rather than a
	# loop, so one enormous tick pays out in a single step instead of spinning
	# through it a grain at a time.
	var made := int(floorf(station.output_part_made))
	if made > 0:
		station.output_part_made -= float(made)
		inventory.add(YIELD_NAME, made)
	return false


# What he brings in per hour, right now. THE SEAM, and it stands empty on
# purpose.
#
# Its own call site rather than a read of base_grain_per_hour, because a scythe
# in his hands, a richer plot, a wound, or a sack already full all install in
# THIS FUNCTION BODY and not one caller changes. Same shape as
# Brain.get_adenosine_recovery() and Person.get_travel_speed(), which is what
# this project reaches for whenever a number is going to grow modifiers.
#
# It takes the person because the first modifier anybody will want is a fact
# about the MAN — the tool he is holding — exactly as get_travel_speed's one
# modifier is. Underscored only because nothing reads him yet, the same marker
# Action.is_available_to uses for a seam standing empty; drop the underscore the
# day something does.
#
# STRENGTH IS DELIBERATELY NOT IN HERE, though stats.gd predicts it will one day
# mean work done per hour. That is a prediction, not a specification, and this
# rung does not cash it: Hobb already needs less sleep, rises first, walks
# faster and takes the plot, and nothing has asked for a fourth advantage. This
# is where it goes on the day something does.
func get_yield_per_hour(_person: Person) -> float:
	return base_grain_per_hour


# Which half of the job he is seen doing. Re-derived, like everything else here
# — the destination is named from the station this tick chose, never from
# anything the walk remembered.
func describe(person: Person) -> String:
	var work := get_parent() as WorkTheField
	if work != null:
		var station := work.get_best_candidate(person)
		if station != null:
			# A mis-parented station has no place at all. Workstation._ready
			# already says so; here it must simply not be dereferenced.
			var place := station.get_place()
			if place != null and person.get_current_place() != place:
				return "walking to %s" % place.place_name
	return "in the furrows"
