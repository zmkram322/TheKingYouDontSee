class_name WorkTheField
extends Action

# Work a plot in the fields. The first action whose availability depends on
# somebody ELSE — a plot another man holds, AND CAN SEE IS HELD, is off his
# ballot entirely, so the loser of a dawn race is never scored, not outscored,
# and the graph draws his work as a hole rather than a losing line. That "and
# can see" is rung 4's, and it is what lets a man set off at all: see
# _is_a_candidate_for at the bottom.
#
# An Action is a family, not a single choice: "work the field" means "work
# WHICH plot". So the gate asks "are there candidates", the score asks "how
# good is the best one", and the step asks "which one am I claiming" — and all
# three MUST agree, or the utility that won is not the utility he gets, which
# reads as "the AI is flaky" and costs a day to trace. They agree because all
# three run through get_best_candidate below, over Town's stably sorted list.
#
# THE SCORE CARRIES ITS OWN DAYLIGHT TERM, AND THE GATE ASKS is_awake. Both
# are load-bearing, worked out against the settled cycle before this landed:
#
#   Flat and high enough to beat StayUp at noon (87+), work would still be
#   winning at 22:00, where StayUp has fallen to 50 — and bedtime is wherever
#   rising adenosine crosses the top waking bid, so the farmers' turning-in
#   hour would quietly move. With its own, steeper daylight term, work wins the
#   day and loses the evening (crosses under StayUp near 20:45 at the shipped
#   numbers), and StayUp remains the line bedtime is measured against. The
#   numbers below also keep work above StayUp at 04:41, where a strong man
#   rises — win the plot at dawn, hand the evening back to StayUp.
#
#   And without the is_awake gate, work sits on a SLEEPING man's ballot. His
#   claim lapsed at midnight where he isn't standing on it, the plot reads
#   free all night, and the first moment work's nighttime score beats his
#   falling adenosine, he gets up to farm in the dark. Same gate StayUp
#   already uses, for the same reason: a sleeping man's only way back to the
#   waking ballot is Wake.

# What kind of station this works. Matched against Workstation.work_name by
# Town.find_workstations.
@export var work_name := &"field work"

# What working is worth at dawn and dusk, when the sun is level with the
# horizon. Sits above StayUp's 67.3 so that a man who is up while the sun is
# anywhere near the sky works rather than idles.
@export var pull := 73.0

# Added at midday, taken off at midnight, following the sun — same shape as
# StayUp's anchor and deliberately STEEPER (30 against 20), which is what hands
# the evening back to StayUp before bedtime. See the header.
@export var daylight_pull := 30.0


func is_available_to(person: Person) -> bool:
	# A sleeping man doesn't bid for plots — see the header.
	if not person.brain.is_awake():
		return false
	if person.town == null:
		return false
	var stations := person.town.find_workstations(person, work_name)
	if stations.is_empty():
		# TELEMETRY, NOT WORLD STATE — a deliberate, documented exception to
		# "gate and score are reads, DO is the only write". "There was no
		# field" is only knowable here, and nothing ever reads these counters
		# back into a decision, so they cannot change what anybody does — the
		# same exemption DecisionEngine._last_scores takes and documents. It
		# does NOT license writes in gates generally.
		person.town.note_no_candidates_existed()
		return false
	if _find_first_candidate(stations, person) == null:
		# The other idleness, and a different world — the town has work and no
		# room, not no work. See town.gd for why these are two counters.
		#
		# Under the knowledge rule below this counter got TRUER: it now counts
		# men who turned up and found no room, rather than men who theoretically
		# could not have worked from wherever they happened to be standing.
		person.town.note_every_candidate_was_taken()
		return false
	return true


# How much he wants to work: the sun's arc, worth more than idling all day.
#
# TRAVEL COST IS NOT IN THIS SUM, AND MAY NEVER BE — under any name, at any
# weight. It belongs to picking between an action's candidates, this plot or
# that one, and never to the comparison between one action and another: pull
# decides WHAT you do, travel cost decides WHERE you go to do it. Subtract a
# commute here and geography starts vetoing a want — a man at the Inn would
# simply stop wanting to work — which is barring wearing different clothes, and
# no weight is small enough to make it right in principle. Keeping it out is
# what makes muting a commute structurally impossible instead of a tuning
# invariant somebody has to remember to check. (Decision 15; an earlier draft of
# rung 4 had a `patience` weight here and it was deleted.)
#
# Travel cost is already doing its whole job one layer down, in the ordering
# Town.find_workstations hands back. The best candidate's QUALITY is still not
# in the sum either — with one kind of plot on common land every candidate is
# equally good, and a coefficient trading quality against hours decides nothing
# until rung 9a gives plots yields to differ by.
func get_utility_score(person: Person) -> float:
	return pull + daylight_pull * person.get_sun_height()


# The one plot he would work: the first station he'd take in Town's list, which
# is stably sorted by what the journey costs HIM — so gate, score and step, each
# calling this fresh, land on the same station every time. Never iterates a
# Dictionary; order is the whole contract.
func get_best_candidate(person: Person) -> Workstation:
	if person.town == null:
		return null
	return _find_first_candidate(person.town.find_workstations(person, work_name), person)


# FREENESS IS KNOWABLE ONLY WHERE YOU ARE STANDING. Presence was already
# required to CLAIM a plot; as of rung 4 it is required to KNOW about one.
#
#   Not at the plot's place → he knows the plot EXISTS, not whether it is taken.
#   It stays a candidate, the urge to work stands, and he walks.
#   At the plot's place    → he can see it. Taken by somebody else and it drops
#   out, so work leaves his ballot at the moment he ARRIVES.
#
# Rung 3 let this gate ask whether a plot was free from anywhere in the world.
# With both farmers standing in the same field that was invisible; the moment
# they are apart it is omniscience, and it kills walking outright — a man at the
# Inn would know the plot was taken, so work would never reach his ballot, so he
# would never set off, and nothing could ever interrupt him.
#
# The wasted journey is the POINT. A man who crosses the town and finds the job
# gone is the collision that later earns a notice board; pre-solving it with
# omniscience would delete the evidence that the board is worth building.
# (Decision 15, restoring the default Decision 1 had already described.)
#
# Note where this rule does NOT live: Workstation.is_free_for goes on reporting
# the plain truth about itself. The world is not obliged to lie, and what a man
# KNOWS of the truth is this action's business, not the plot's.
func _find_first_candidate(stations: Array[Workstation], person: Person) -> Workstation:
	for station in stations:
		if _is_a_candidate_for(station, person):
			return station
	return null


func _is_a_candidate_for(station: Workstation, person: Person) -> bool:
	if person.get_current_place() != station.get_place():
		return true
	return station.is_free_for(person)
