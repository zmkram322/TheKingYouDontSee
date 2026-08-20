class_name Sleep
extends Action

# Go to sleep — WHERE, though, is the question rung 6c adds. Wanted exactly as
# much as he's tired — the pull IS the adenosine, no curve on top, so the
# number you watch on the graph is the same number driving the decision. That
# part is unchanged from before this rung.
#
# THE GATE CHANGED SHAPE, AND IT USED TO SAY THE OPPOSITE OF THIS. It read
# "nothing gates this: sleep is always open to him" — true when a bed was a
# fiction nobody had to find. As of rung 6c a bed is a Workstation exactly
# like a plot, so the gate is now a CANDIDATE question, the same shape
# WorkTheField's already is: is there anywhere he could lie down AT ALL. It is
# STILL never a WANT question — "is he tired enough to bother" has no
# business in a gate, the same argument eat.gd and work_for_hire.gd both
# already make in their own words. A man who finds every bed taken is not
# barred from wanting sleep; Sleep simply has no candidate to offer him, which
# is a different (and true) fact about the world rather than about him.
#
# WHAT THIS ACTUALLY BUYS: A MAN WHO CANNOT FIND A BED. Twenty beds and a
# twenty-first sleeper leaves exactly one man standing all night — his
# adenosine climbs and pins at the ceiling, and nothing in this project could
# ever have shown that before this rung, because a bed to fail to find did not
# exist yet. That man is this rung's content.
#
# THE CANDIDATE MACHINERY BELOW IS THE SAME SHAPE work_the_field.gd CARRIES —
# gate asks "are there candidates", score asks "how much do I want it", step
# asks "which one am I claiming", and all three agree because all three call
# get_best_candidate. As of Decision 30 the knowledge rule is the same too, in
# spirit and in code: a bed's claim is a PUBLIC RECORD, readable from wherever
# he happens to be standing — see work_the_field.gd's copy of
# _is_a_candidate_for for the full argument. Beds add a wrinkle plots don't:
# bed claims all expire at DUSK rather than dawn, so every sleeper sets off for
# the Inn at once and the claims land WHILE men are converging, not before
# anybody has taken a step. Reading the register still saves nothing the plot
# case saves — there is no quiet night spent knowing better — but it is what
# stops the twenty-first sleeper from pacing the doorway once he learns, on
# the road or at the door, that every bed is somebody else's.
#
# DUPLICATED RATHER THAN SHARED, ON PURPOSE. Two consumers of one shape is
# tolerable; the THIRD — 9b's baker, queuing for a millstone the same way —
# is the one that will actually earn pulling this into a common home.
# Extracting it for two readers now would be guessing at a shape neither has
# finished proving out.
#
# NO TELEMETRY WRITES HERE, UNLIKE WorkTheField's GATE. An Inn with no free
# bed is real pressure on the town — exactly the "every candidate was taken"
# shape — but nothing reads a sleep-specific counter yet, and the
# telemetry-from-gate exemption belongs to work_the_field.gd, which documents
# it there. Widening it here just because the shape matches is how an
# exception quietly stops meaning anything; a counter earns itself the day
# something reads it back, the same rule Town's existing two already obeyed.
#
# WHY A BED DOES NOT COUNT AS ASLEEP UNTIL HE IS LYING IN IT: see
# counts_as_asleep_for below, and action.gd's header for the split it rests
# on.

# What kind of station this claims. Matched against Workstation.work_name by
# Town.find_workstations, same pattern as WorkTheField.work_name.
@export var work_name := &"sleeping"


func is_available_to(person: Person) -> bool:
	if person.town == null:
		return false
	var stations := person.town.find_workstations(person, work_name)
	if stations.is_empty():
		return false
	return _find_first_candidate(stations, person) != null


func get_utility_score(person: Person) -> float:
	var tired: float = person.stats.get_stat(&"adenosine")
	return tired


# Only actually asleep once he is LYING DOWN — standing at the place of a bed
# he formally holds. The walk there happens while this still reads false,
# which is exactly the point: he shows up as awake for the whole commute (see
# action.gd's header), and his adenosine keeps rising on the road the way a
# real commute should cost him.
#
# THE FORMAL CLAIM IS REQUIRED, and it is safe to require only because the
# body update runs AFTER the work as of this rung (see Brain.think_and_act).
# An earlier draft read mere presence-at-the-place instead, because under the
# old decide→update→do order the claim was written a phase too late and a
# man's first tick in bed upkept as awake while reporting asleep — claim 2
# caught it both ways. With the update last, Rest claims the bed in the same
# tick it arrives and the body reads the finished truth: the claim IS the
# fact of lying there, and presence alone would let two men standing by one
# free bed both read as sleeping in it.
func counts_as_asleep_for(person: Person) -> bool:
	var bed := get_best_candidate(person)
	if bed == null:
		return false
	if bed.claimed_by != person:
		return false
	return person.get_current_place() == bed.get_place()


# The bed he would take. PREFERS A BED HE ALREADY HOLDS, checked before the
# generic search — and this is not a place-preference beyond the candidate
# machinery, it is the candidate machinery working correctly for the case
# work_the_field.gd never had to face: twenty stations sharing ONE place.
# Town.find_workstations sorts by travel cost to a station's PLACE, and every
# bed here shares the Inn, so once more than one is free the tiebreak is bare
# node-path order — which has nothing to do with which bed a man is actually
# lying in. Without asking this first, an already-asleep man's "best
# candidate" can silently drift to a different, still-unclaimed bed the
# moment one happens to sort ahead of his own, and the bed he is physically
# in reads as abandoned while he is still on it — counts_as_asleep_for would
# read false for a man lying perfectly still. Gate, score, step and
# counts_as_asleep_for all call this fresh, so all four still agree on which
# bed; they now also agree that "the one I'm already in" outranks any empty
# one.
func get_best_candidate(person: Person) -> Workstation:
	if person.town == null:
		return null
	var stations := person.town.find_workstations(person, work_name)
	for station in stations:
		if station.claimed_by == person:
			return station
	return _find_first_candidate(stations, person)


# See work_the_field.gd's own copy of this pair for the full argument —
# duplicated here rather than pulled into a shared base, per this file's
# header.
func _find_first_candidate(stations: Array[Workstation], person: Person) -> Workstation:
	for station in stations:
		if _is_a_candidate_for(station, person):
			return station
	return null


func _is_a_candidate_for(station: Workstation, person: Person) -> bool:
	return station.is_free_for(person)
