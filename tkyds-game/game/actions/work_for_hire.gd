class_name WorkForHire
extends WorkTheField

# Working because you are EMPLOYED to. The same working WorkTheField already
# does — same candidates, same knowledge rule, same telemetry, same step
# machinery underneath — with one thing changed: the want finally comes from
# a real gap instead of the hand-placed 73 (Decision 19 named `pull` as
# exactly that placeholder, and this is the rung that cashes it in).
#
# THE INHERITED `pull` EXPORT IS SUPERSEDED HERE AND DOES NOTHING TO THIS
# SUBCLASS'S SCORE. Said out loud rather than left to be discovered: the flat
# 73 dissolved into Obligation.weight, and get_utility_score below never
# reads `pull` at all. It is still declared, inherited, and visible on the
# node — a stray reader who finds it unused should find this paragraph next,
# not a mystery.
#
# WHY THE GATE READS EXPIRY AND THE SCORE READS DISCHARGE, and this is the
# whole shape of the rung:
#
#   EXPIRY takes the candidate OUT OF THE WORLD. get_standing_obligation
#   below skips an expired obligation entirely, so an expired man has nothing
#   to work FOR — is_available_to returns false, and the graph draws a hole,
#   the same "off the ballot" shape a lost dawn race draws (FR103, "leaves
#   the candidate set").
#
#   DISCHARGE never removes anything. A man who met today's quota is still
#   employed, still permitted on the land, still ON the ballot — he is just
#   scored 0.0, outbid rather than barred (Decision 22). The distinction
#   matters mechanically: an obligation discharged at 14:00 can still start
#   mattering again the moment the day turns over, and nothing has to notice
#   that happening because nothing ever took him off the ballot to begin
#   with.
#
# A BINARY GAP, AND THAT IS A SETTLED CALL, NOT AN OVERSIGHT. Decision 20's
# want = weight × gap^bite reads this as a gap of exactly 1 (unmet) or 0
# (met) rather than a proportional gap like hunger's. A promise is kept or it
# is not; scoring it proportionally would make a man slack off as he nears
# his target, which is backwards — the twelfth grain matters exactly as much
# as the first, because missing either one is the same broken promise. The
# sun still lands on the WEIGHT (Decision 20's other half), so while the
# quota stands unmet this is arithmetically identical to the work curve this
# project has shipped since rung 4 — the schedule does not move.


# The first UNEXPIRED obligation among his, discharged or not. The gate asks
# CANDIDACY — is there an agreement to work under at all — and candidacy does
# not care whether today's want has already been answered; that is the
# score's question, not this one.
func get_standing_obligation(person: Person) -> Obligation:
	for obligation in person.get_obligations():
		if not obligation.is_expired():
			return obligation
	return null


# No standing obligation, no ballot entry at all — an unemployed man cannot
# work a plot he has no claim on, and this is checked before anything
# WorkTheField would ask, so an unemployed man never even reaches the
# station-hunting logic below.
func is_available_to(person: Person) -> bool:
	if get_standing_obligation(person) == null:
		return false
	return super.is_available_to(person)


# A station whose place is not the obligation's named place is not this
# action's candidate AT ALL — checked BEFORE the knowledge rule below, and
# that ordering is the point: a man knows his own employment from ANYWHERE,
# because it is knowledge about the AGREEMENT, not about occupancy. He does
# not need to be standing at a plot to know it is not the one he is employed
# to work; he needs to be standing at it only to know whether it is FREE,
# which is exactly what the inherited knowledge rule (super, below) still
# gates.
#
# With one plot in the world this changes nothing about which station wins —
# there is only one to scope to. It starts mattering the moment there is more
# than one, and 9b's baker reuses this same override rather than growing a
# second copy of the idea.
func _is_a_candidate_for(station: Workstation, person: Person) -> bool:
	var obligation := get_standing_obligation(person)
	if obligation == null:
		return false
	var place := station.get_place()
	if place == null or place.place_name != obligation.place_name:
		return false
	return super._is_a_candidate_for(station, person)


# want = weight × gap^bite with a BINARY gap (see the header): obligation
# null or already discharged scores 0.0 — on the ballot, outbid, never
# barred. Otherwise it is the obligation's own weight (Decision 19's
# dissolved 73) plus the identical daylight term WorkTheField has always
# carried (Decision 20: the sun lands on weight, not on the gap).
func get_utility_score(person: Person) -> float:
	var obligation := get_standing_obligation(person)
	if obligation == null or obligation.is_discharged():
		return 0.0
	return obligation.get_weight_at_scoring_time() + daylight_pull * person.get_sun_height()
