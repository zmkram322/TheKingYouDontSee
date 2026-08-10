class_name Town
extends Node3D

# The places, and the one question about them that isn't about a single place:
# who is standing where.
#
# A Node3D rather than a plain Node so the places sit under it in a real
# transform hierarchy — you can drag the whole town and every travel cost in it
# moves together, which is the same live read standing check #3 is about.
#
# WHY IT REACHES THE PEOPLE THROUGH Population RATHER THAN WALKING THE TREE:
# Population is already the one node that knows who is alive; it grew
# get_people() at rung 1 for exactly this. Searching the scene for anything
# shaped like a Person would mean this file quietly deciding what counts as
# inhabiting the world, and it would find the probe's spare worlds too.

# Where the people are. Dragged in from the inspector rather than found by path,
# so moving either node doesn't silently break the link.
#
# Note for whoever wires this in a .tscn by hand: it needs
# `node_paths=PackedStringArray("population")` on the node's own header line, or
# the loader assigns the raw NodePath to a typed field and you get null.
@export var population: Population


# Says so out loud rather than answering every question with an empty list. A
# Town with no Population reports that nobody is anywhere, which is exactly what
# an empty town looks like — and that is the silence that shipped a dead
# day/night cycle here.
func _ready() -> void:
	if population == null:
		push_warning("Town has no Population — every place will report itself empty")


# Every place in this town, in scene order. Asked for fresh rather than cached
# because places are authored, few, and a cached list is one more thing to be
# wrong the day somebody adds one at runtime.
func get_places() -> Array[Place]:
	var found: Array[Place] = []
	for child in get_children():
		var place := child as Place
		if place != null:
			found.append(place)
	return found


# Who is standing at this place, right now.
#
# THIS IS A QUERY, NOT AN INDEX, AND THAT IS THE POINT. Nobody posts their
# arrival and nothing is maintained: it loops the people and asks each one where
# he is. So there is exactly ONE copy of "where Zoogs is" — the field he
# carries — and one copy cannot contradict another copy. A list held on the
# Place would be a second copy, and every write that updated one and not the
# other would produce a trade with a man who is not in the room, with both
# records looking correct in isolation.
#
# The cost is one pointer comparison per person per call: 169 of them per tick
# for the thirteen-person town this ladder ends at, which is lost in the noise
# of the utility scoring those same thirteen are already doing. It stops being
# free somewhere in the low hundreds of people.
#
# WHEN THAT DAY COMES, this function body becomes an index lookup and NOT ONE
# CALLER MOVES — same trick as get_stat/set_stat, the accessor is the wall. The
# one thing that would foreclose it is a public occupancy list on Place that
# callers read directly, because then the list is the interface. So: nobody
# reads occupancy except through here. And the test for that day is already
# written — keep this loop as the slow oracle, run both, assert they agree. The
# build plan's "find_people_at and get_current_place never disagree" assertion
# is vacuous today because there is only one copy; it is banked for exactly then.
# The two flavours of idleness, and they are TWO on purpose: "there was no
# field" and "every field was taken" are different worlds with opposite fixes —
# collapsed into one number, the day the town runs out of work looks exactly
# like the day it runs out of workers. Each is one accumulating float and never
# a history: a list of nights would be the decision log the plan names as its
# only unbounded complexity class. These are the class of fact that CANNOT be
# recomputed from world state — a failure that already happened leaves no trace
# in a snapshot — which is why storing them doesn't break "store nothing you
# can work out again".
#
# PLAIN accumulators for now, deliberately: decay arrives with the first reader
# (a Lord noticing his town stands idle), because a half-life is a tuning knob
# and a knob nothing reads is substrate before need. Nothing reads these yet,
# and that is correct. They are telemetry written from a gate — the documented
# exception lives at the write site in work_the_field.gd.
var no_candidates_existed_pressure := 0.0
var every_candidate_was_taken_pressure := 0.0


# Every station in this town where that kind of work is done, STABLY SORTED by
# what the journey costs the asking person, node path as tiebreak — never
# Dictionary hash order. The sort is the agreement mechanism: gate, score and
# step each re-derive "the best plot" fresh, and a stable order is what makes
# three derivations land on the same one.
#
# No radius bound and no nearest-N cap, deliberately: a far plot is outbid,
# never barred, and locality is emergent — a station in the next town would sit
# at the bottom of this list because it is expensive, not because a rule says
# "only your own town". Nothing truncates; a caller that ever wants the nearest
# three takes the front of the list.
#
# Freeness is NOT filtered here — that is the asking action's business, and a
# taken plot is still a fact about the town (it is what makes "every field was
# taken" answerable at all).
func find_workstations(person: Person, work_name: StringName) -> Array[Workstation]:
	var found: Array[Workstation] = []
	for place in get_places():
		for child in place.get_children():
			var station := child as Workstation
			if station != null and station.work_name == work_name:
				found.append(station)
	found.sort_custom(func(left: Workstation, right: Workstation) -> bool:
		var left_cost: float = person.get_travel_cost_to(left.get_place())
		var right_cost: float = person.get_travel_cost_to(right.get_place())
		if left_cost != right_cost:
			return left_cost < right_cost
		return String(left.get_path()) < String(right.get_path()))
	return found


# "There was no field." The town has run out of WORK — the fix is more
# stations, and it is nothing like the fix for the counter below.
func note_no_candidates_existed() -> void:
	no_candidates_existed_pressure += 1.0


# "Every field was taken." The town has run out of ROOM — it has more willing
# hands than places to put them.
func note_every_candidate_was_taken() -> void:
	every_candidate_was_taken_pressure += 1.0


func find_people_at(place: Place) -> Array[Person]:
	var found: Array[Person] = []
	# Nobody is at nowhere — and this is a real answer, not a swallowed error. A
	# man walking between places is at no place, and rung 4 will write null into
	# him for the length of the road. Without this, every such man would be
	# found "together" at nowhere, and rung 7 would let two people trade while
	# they are half a town apart.
	if place == null:
		return found
	if population == null:
		return found
	for person in population.get_people():
		# UNREACHABLE TODAY, AND KEPT ON PURPOSE — measured, not assumed: pull
		# this guard out and the probe still passes, because free() removes a
		# node from get_children() at once, so a snapshot taken here can't
		# contain a dead man. It stops being unreachable the moment anything in
		# this file holds a list between calls, which is exactly the index this
		# function is written to be able to graduate into — and a freed node
		# does not null the references to it, so `== null` stays false and the
		# next property read errors. Cheaper to leave standing than to
		# rediscover.
		if not is_instance_valid(person):
			continue
		if person.get_current_place() == place:
			found.append(person)
	return found
