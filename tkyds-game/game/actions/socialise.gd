class_name Socialise
extends Action

# Go find some company. The third want with a real weight AND a real bite
# (Eat's shape — want = weight × gap^bite), and the first whose candidates
# are a PROPERTY OF A PLACE rather than a kind of station: a candidate here
# is anywhere Place.is_gathering_place says company is to be found, whether
# or not anybody happens to be standing there right now.
#
# THE FAMILY SHAPE IS work_the_field.gd's AND sleep.gd's, ONE MORE TIME. Gate
# asks "are there candidates", score asks "how much do I want it", step asks
# "which one am I heading for" — and all three agree because all three run
# through get_best_candidate below, over a list sorted the identical way
# Town.find_workstations already sorts its own: by what the journey costs
# HIM, tie broken by more company already there, then place path for a
# result that never depends on Dictionary order.
#
# CANDIDATES ARE VENUES, NOT CROWDS — AND THAT DISTINCTION IS THE WHOLE
# POINT. An earlier draft made "a place currently holding somebody else" the
# candidate, and it has a bootstrap hole nothing in it can ever climb out of:
# an empty venue is never a candidate, so the FIRST man never sets off toward
# it, so it never holds anybody, so it is never a candidate — forever. A
# lonely man goes where company is TO BE FOUND, not where a headcount already
# happens to be positive; the second man then finds the first one there. See
# place.gd's is_gathering_place for the flag that carries this.
#
# TRAVEL COST ORDERS THE CANDIDATES AND NEVER ENTERS THE SCORE — Decision 15,
# the same rule work_the_field.gd's header spells out at length. That ordering
# IS the herd damper: a venue across town loses to one next door, so nothing
# ever needs to notice a crowd exists and cap it. Put cost in the score
# instead and a far tavern would simply stop being wanted, which is barring
# wearing different clothes.
#
# OCCUPIED NON-VENUES ARE STILL NOT CANDIDATES. Two farmers standing together
# in the furrows are not a candidate for a third man's Socialise — company
# happens where company belongs, the same way work happens where work
# belongs. Only Place.is_gathering_place makes a place eligible at all;
# whether anyone is actually there only breaks ties among eligible places and
# decides, in the step, whether the visit pays off yet.
#
# NO KNOWLEDGE RULE, AND THAT'S DELIBERATE — UNLIKE A PLOT'S FREENESS. Which
# places ARE gathering places, and who's currently at one, are both read from
# anywhere in town, with no "only once you've arrived" restriction the way
# WorkTheField and Sleep both impose on whether a STATION is free. The
# settled design treats both as the town's shared knowledge: everybody knows
# the tavern is a tavern, and roughly who's in it, even from across town.
# Revisit this if that omniscience ever actually shows.

# What desperate loneliness is worth — the weight in weight × gap^bite. Set
# BELOW work's 103 peak AND below the adenosine ceiling of 100 — the opposite
# of Eat's placement, and deliberately so. Eat is a one-tick spike: even a
# weight that could dominate everything only wins the single tick it takes to
# eat, then vanishes. Socialise can stand on the ballot for HOURS with
# nothing changing the world at all — an empty venue, the failure case
# socialise_step.gd's header explains — and a standing bid above what Sleep
# can EVER reach is not a strong preference, it is permanent capture: a man
# who reaches the ceiling while nobody's at the venue can never be outbid by
# sleep again, because sleep's own score is capped at 100 and cannot climb
# any higher to catch up. Measured on this rung at 110: cold start slid from
# 21:17 to 05:27 and stayed broken. 90 keeps Socialise a real, sometimes
# dominant want — it can still win over StayUp and even briefly over work —
# without ever being able to outrun the one want that has to be able to
# reclaim him no matter how lonely he's been left.
@export var company_worth := 90.0

# How sharply it bites — the exponent. GENTLER than Eat's 3.0 on purpose:
# company is sought before the gap turns desperate, where food is stoically
# postponed until it is. A lower bite lets a middling gap already score
# something real, rather than staying flat until loneliness is nearly total.
@export var bite := 2.0


# Awake, and somewhere in town is a gathering place at all. NEVER the size of
# the gap — "not lonely enough to bother" is want, not possibility, the same
# argument eat.gd's header already makes for hunger and sleep.gd's for
# tiredness. NEVER whether anybody is currently there either — that would
# make the gate itself the bootstrap hole the header above describes.
func is_available_to(person: Person) -> bool:
	if not person.brain.is_awake():
		return false
	return _find_candidates(person).size() > 0


# The gap and nothing else — no travel cost, no crowd size, no place quality.
# See the header: cost orders WHICH place, never whether he wants company at
# all.
func get_utility_score(person: Person) -> float:
	var lonely: float = person.stats.get_stat(&"social")
	return company_worth * pow(lonely / 100.0, bite)


# The place he would head for: the nearest gathering place, ties broken by
# more company already there, then by place path so the order can never
# depend on Dictionary hashing. Gate, score and step all call this fresh, so
# all three always agree on which place is meant.
func get_best_candidate(person: Person) -> Place:
	var candidates := _find_candidates(person)
	if candidates.is_empty():
		return null
	return candidates[0]


# Every gathering place in town, stably sorted the way Town.find_workstations
# sorts its own list: cheapest journey first, more company already there as
# the tiebreak, place path as the last resort. Occupancy never decides
# WHETHER a place is a candidate — only Place.is_gathering_place does that.
func _find_candidates(person: Person) -> Array[Place]:
	var found: Array[Place] = []
	if person.town == null:
		return found
	for place in person.town.get_places():
		if place.is_gathering_place:
			found.append(place)
	found.sort_custom(func(left: Place, right: Place) -> bool:
		var left_cost: float = person.get_travel_cost_to(left)
		var right_cost: float = person.get_travel_cost_to(right)
		if left_cost != right_cost:
			return left_cost < right_cost
		var left_count := _company_count_at(left, person)
		var right_count := _company_count_at(right, person)
		if left_count != right_count:
			return left_count > right_count
		return String(left.get_path()) < String(right.get_path()))
	return found


# How many people besides the one asking are standing at this place, right
# now — the town's shared gossip, per the header above. Only ever a tiebreak
# among eligible venues, never what makes a place eligible.
func _company_count_at(place: Place, person: Person) -> int:
	var count := 0
	for other in person.town.find_people_at(place):
		if other != person:
			count += 1
	return count
