class_name WorkStep
extends ActionStep

# The working itself, and — as of rung 4 — getting there first. Like every step
# it holds no progress: no furrow counter, no elapsed anything, and no route.
# Which plot he is working is re-derived every tick from the same
# get_best_candidate the gate and score used, who holds the plot lives on the
# plot, and how far along the road he is, is where he is standing.
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
	# The work has nothing to move yet — grain arrives with inventory at rung 5
	# and work-that-takes-time at 9a. Holding the plot IS this rung's work.
	return false


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
