class_name WorkForHire
extends WorkTheField

# Working because you are EMPLOYED to. The same working WorkTheField already
# does — same candidates, same knowledge rule, same telemetry, same step
# machinery underneath — with one thing changed: the want comes from a real
# gap instead of the hand-placed 73 (Decision 19 named `pull` as exactly that
# placeholder), gated on holding a LIVE obligation rather than open to anyone
# who wanders up to a plot.
#
# THE INHERITED `pull` EXPORT IS SUPERSEDED HERE AND DOES NOTHING TO THIS
# SUBCLASS'S SCORE. Said out loud rather than left to be discovered: the flat
# 73 dissolved into Obligation.weight, and get_utility_score below never
# reads `pull` at all. It is still declared, inherited, and visible on the
# node — a stray reader who finds it unused should find this paragraph next,
# not a mystery.
#
# DECISION 31 — THE SCORE IS FLAT, AND THE LARDER GAP NEVER DRIVES WORK. An
# earlier shape here (retired by this rung's repair) scored a BINARY QUOTA
# gap — unmet vs. met, outbid to exactly 0.0 the tick a man's delivery
# discharged a daily grain debt. Decision 29 deleted that debt entirely: the
# crop belongs to whoever owns the land, a worker is PAID a share rather than
# owing one, and is_discharged() on Obligation is now a derived question
# about a wage ledger, not a switch anybody flips (see obligation.gd).
# Reading it here to zero the score would make the identical mistake in a new
# coat: under share-of-crop the ledger settles CONTINUOUSLY as WorkStep pays
# him — add(), one grain at a time, the instant it is made — so a score gated
# on that gap would fight itself all day, closing the very thing that is
# supposed to keep driving it. That is exactly the trap Decision 31 names: "a
# gap drives the action that closes it in ONE act; an action whose output
# closes its own driver slowly and continuously must not be scored on that
# gap." So work scores on the DAY'S LABOUR instead, which IS binary — he is
# employed and there is a day of it to do — the same flat shape
# `pull + daylight_pull * sun` this action has carried since rung 4, now
# reading Obligation.weight where `pull` used to sit. THE LARDER GAP DRIVES
# EATING AND BAKING (eat.gd, make_bread.gd), NEVER WORK.
#
# WHY THE GATE STILL READS EXPIRY, AND ONLY EXPIRY, NOW:
#
#   EXPIRY takes the candidate OUT OF THE WORLD. get_standing_obligation
#   below skips an expired obligation entirely, so an expired man has nothing
#   to work FOR — is_available_to returns false, and the graph draws a hole,
#   the same "off the ballot" shape a lost dawn race draws (FR103, "leaves
#   the candidate set").
#
#   DISCHARGE no longer has anything for the gate OR the score to ask. A paid
#   man is still employed, still permitted on the land, still on the ballot,
#   still scored the identical flat number he was scored before this rung —
#   there is no event left called "meeting the quota" for either of them to
#   notice, because there is no longer a quota to meet.


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


# want = weight × gap^bite with a BINARY gap, per Decision 31: employed today
# or not, nothing in between, and no read of is_discharged() anywhere in this
# function — a wage settled continuously has nothing left to bid a man off
# work with. No obligation scores 0.0 (should be unreachable behind
# is_available_to's own gate, kept defensive rather than assumed). Otherwise
# it is the obligation's own weight (Decision 19's dissolved 73) plus the
# identical daylight term WorkTheField has always carried (Decision 20: the
# sun lands on weight, not on the gap).
func get_utility_score(person: Person) -> float:
	var obligation := get_standing_obligation(person)
	if obligation == null:
		return 0.0
	return obligation.get_weight_at_scoring_time() + daylight_pull * person.get_sun_height()
