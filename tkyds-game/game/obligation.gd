class_name Obligation
extends Node

# A promise, not a fact about the world. An agreement that the man who carries
# this owes something to somewhere, kept as a Node under him because it is
# STORED INTENT (FR101) — "Zoogs owes the grain fields twelve grain a day" is
# not a fact you could work out again by looking at where he is standing or
# what he is carrying. It is the same test Workstation.claimed_by already has
# to pass: no amount of looking at the world tells you who this man agreed to
# work for, so it has to be remembered somewhere, and it is remembered here.
#
# AUTHORED PER INSTANCE IN game.tscn, NOT IN person.tscn. A body is not a
# life: person.tscn is the template of what every man carries by
# construction (a Brain, an Inventory, a hunger stat), and not every man is
# employed. The day this town holds somebody idle, he is a person with no
# Obligation under him at all, and that has to be possible.

@export var owed_item := &"grain"

# PER DAY. The quota renews rather than being met once and forgotten. The
# Moment this rung watches for — a man hits quota mid-afternoon and work
# collapses — is documented as a once-a-day repeating beat, and a quota that
# didn't renew would only ever produce that beat on day one, then leave a
# man sitting idle with nothing left to want for the rest of the run.
@export var owed_count := 12

# The FR100 discharge target — WHERE this is owed. A String, matching
# Place.place_name's own type, DELIBERATELY rather than a StringName (an
# earlier draft of this rung's spec called for one — a snippet, not code,
# per the standing hazard). This value is compared against place_name every
# tick in WorkForHireStep's delivery leg, and matching the type on the other
# end of that comparison is cheaper than asking every future reader to
# remember that a String and a StringName holding the same text are still
# worth checking against each other correctly. The cheapest wall is the one
# nobody has to remember.
@export var place_name := ""

# FR103: employment ENDS. -1 means never, which no clock.day() ever returns
# as a real day. Expiry and discharge are two different facts, kept apart on
# purpose:
#
#   EXPIRY terminates the agreement — the candidate LEAVES the world
#   (FR103's own words: "leaves the candidate set"). is_expired() below.
#
#   DISCHARGE just means today's want has been answered — the candidate
#   STAYS, scored at zero, outbid rather than barred (Decision 22). Meeting
#   quota does not fire a man; missing a day does not either, until this
#   field says a day it does. is_discharged() below.
#
# See work_for_hire.gd's header for why the gate reads one of these and the
# score reads the other.
@export var expires_on_day := -1

# The FR102 seam. An authored constant today — this number IS what
# WorkTheField used to call `pull` before this rung dissolved it into the
# gap it was always standing in for (Decision 19: the flat 73 was always a
# placeholder for an unmet obligation, not an opinion about work). When
# channels exist to set this dynamically — a lord's writ, a guild rate, a
# season's bargain — the BODY of the function below changes and no caller
# anywhere moves, the same seam shape as Brain.get_adenosine_recovery() and
# WorkStep.get_yield_per_hour().
@export var weight := 73.0

func get_weight_at_scoring_time() -> float:
	return weight


# The agreement's memory — what has actually been handed over. LAZILY
# day-scoped exactly like Workstation.claimed_on_day: a delivery stamped
# yesterday simply is not today's delivery, and nothing sweeps or resets
# this on a timer — the comparison below does the whole job at read time.
#
# NOT DERIVABLE FROM THE BARN, which is why storing it here does not break
# "store nothing you can work out again". More than one man can fill the
# same barn, so the barn's total says nothing about which part of it was
# THIS man's delivery today — this is the one thing here that genuinely
# cannot be recomputed from a snapshot of the world.
var delivered_count := 0
var delivered_on_day := -1


func _ready() -> void:
	if get_parent() as Person == null:
		push_warning("an Obligation's parent must be a Person — nobody owes it")


# Has today's quota been met. The day is read off the person's own clock —
# everyone shares the one Clock, pulled off Population at birth — so not one
# Obligation needs a wire of its own, the same pattern
# Workstation.is_free_for already uses for claimed_on_day.
func is_discharged() -> bool:
	var person := get_parent() as Person
	if person == null or person.clock == null:
		return false
	if delivered_on_day != person.clock.day():
		return false
	return delivered_count >= owed_count


# Has the employment itself ended, per FR103. -1 is "never"; otherwise ONE
# comparison against the day, run at read time, is what lets this be true
# the instant a day crosses without anything sweeping to make it so.
func is_expired() -> bool:
	if expires_on_day < 0:
		return false
	var person := get_parent() as Person
	if person == null or person.clock == null:
		return false
	return person.clock.day() > expires_on_day


# What is still owed today. owed_count itself if nothing has been delivered
# today yet (the stamp is stale or absent), otherwise the gap that is left.
func get_remaining_today() -> int:
	var person := get_parent() as Person
	if person == null or person.clock == null:
		return owed_count
	if delivered_on_day != person.clock.day():
		return owed_count
	return maxi(owed_count - delivered_count, 0)


# Record a delivery. Resets FIRST if the stamp is stale — the same lazy
# pattern a day-long tenancy uses, so nothing anywhere has to notice
# midnight passing and zero this out on a timer of its own.
func note_delivery(count: int) -> void:
	var person := get_parent() as Person
	var today := delivered_on_day
	if person != null and person.clock != null:
		today = person.clock.day()
	if delivered_on_day != today:
		delivered_count = 0
		delivered_on_day = today
	delivered_count += count
