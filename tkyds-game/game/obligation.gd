class_name Obligation
extends Node

# A promise, not a fact about the world. An agreement that the man who carries
# this works FOR somewhere and is PAID BY it, kept as a Node under him because
# it is STORED INTENT (FR101) — "Zoogs works the grain fields for a third of
# what he raises" is not a fact you could work out again by looking at where
# he is standing or what he is carrying. It is the same test Workstation.claimed_by
# already has to pass: no amount of looking at the world tells you who this
# man agreed to work for, so it has to be remembered somewhere, and it is
# remembered here.
#
# AUTHORED PER INSTANCE IN game.tscn, NOT IN person.tscn. A body is not a
# life: person.tscn is the template of what every man carries by
# construction (a Brain, an Inventory, a hunger stat), and not every man is
# employed. The day this town holds somebody idle, he is a person with no
# Obligation under him at all, and that has to be possible.
#
# DECISION 29 — THE CROP BELONGS TO THE LAND, A WORKER IS PAID, NOT INDEBTED.
# This file used to model employment as a grain DEBT: owed_item/owed_count
# authored a daily quota, and delivered_count/delivered_on_day/note_delivery()
# tracked it being paid down. Measured over six days, that shape meant meeting
# the quota and stopping work were the SAME EVENT — grain came off the plot
# one whole unit at a time and the delivery leg ran in the same tick, so no
# man ever held a grain, MakeBread's gate never opened, and the loop
# work -> grain -> bread -> eat could not fire at any tuning. The deeper
# error underneath: the grain was never the worker's to OWE. Hobb works
# Marle's land under Marle's employment; the crop is Marle's from the moment
# it leaves the ground. This file now grants a CAPABILITY (access to the
# land) and sets a WAGE (a share of what comes off it) — see share_of_crop
# below — and the wanting moves onto the man's own larder instead of onto a
# debt (see make_bread.gd, eat.gd).

# The FR102 wage. What fraction of the crop is his the moment it comes off
# the plot — see work_step.gd's ownership branch, which pays it straight
# into his own sack the instant it is made, never as a lump sum later.
#
# 0.35 is the author's sizing against the six-day measurement: hunger rises
# ~96/day unbranched, one loaf fixes 50 of it (~1.92 loaves/day), and
# MakeBreadStep's 3-grain-per-loaf puts that at ~5.76 grain/man/day. At the
# authored yield (WorkStep.base_grain_per_hour, 2.5) a man working a full
# day (~10.6h) makes ~26.5 grain, so a 0.35 share keeps ~9.3 of it — a real
# surplus over the ~5.76 he needs. (Break-even at the OLD 1.0 yield would
# have needed a 0.54 share — over half the owner's own crop — which is why
# the yield moved rather than the share.)
@export var share_of_crop := 0.35

# The FR100 discharge target — WHERE this is owed, i.e. which Place's
# inventory receives the OWNER's part of the crop. A String, matching
# Place.place_name's own type, DELIBERATELY rather than a StringName (an
# earlier draft of this rung's spec called for one — a snippet, not code,
# per the standing hazard). Compared against place_name every tick in
# WorkForHire's candidate check, and matching the type on the other end of
# that comparison is cheaper than asking every future reader to remember
# that a String and a StringName holding the same text are still worth
# checking against each other correctly. The cheapest wall is the one
# nobody has to remember.
@export var place_name := ""

# FR103: employment ENDS. -1 means never, which no clock.day() ever returns
# as a real day. Expiry and discharge are two different facts, kept apart on
# purpose — UNCHANGED BY DECISION 29, only what "discharge" MEANS changed:
#
#   EXPIRY terminates the agreement — the candidate LEAVES the world
#   (FR103's own words: "leaves the candidate set"). is_expired() below.
#
#   DISCHARGE just means today's wage is settled — the candidate STAYS,
#   never barred by it (Decision 22's "outbid, never barred", though as of
#   Decision 31 nothing scores on this any more either; see
#   work_for_hire.gd). Being paid up has never taken, and still does not
#   take, a man off the ballot the way expiry does.
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


func _ready() -> void:
	if get_parent() as Person == null:
		push_warning("an Obligation's parent must be a Person — nobody owes it")


# THE WAGE'S OWN FRACTIONAL REMAINDER — the exact pattern
# Workstation.output_part_made already uses, applied to his SHARE rather
# than to the plot's total yield, and needed for an arithmetic reason worth
# spelling out: WorkStep runs at real FRAME granularity (Population._process,
# ~60 calls a real second at the shipped day length), so any single
# advance() call almost never completes more than ONE whole grain — and
# floor(1 × 0.35) is ZERO, EVERY TIME. Splitting a single indivisible grain
# by a fraction has nothing to floor toward the worker without somewhere to
# carry the leftover 0.35 forward to add to the NEXT grain's 0.35 — without
# this field, share_of_crop would silently degrade to "the owner takes
# everything, always," which is not a rounding nicety, it is a broken wage.
#
# CARRIED HERE, ON THE OBLIGATION, AND NOT ON THE STATION — deliberately
# unlike output_part_made. This fraction is the WORKER's own accrued credit,
# not a fact about the furrow: a different man taking the same plot the next
# day must not inherit, or lose, whatever fraction of a grain his
# predecessor had not yet rounded into a whole one. It belongs to the
# relationship, which is exactly what an Obligation already is.
var share_part_owed := 0.0


# THE ONE DOOR THE WAGE IS PAID THROUGH. Hand it the whole grain that just
# came off the plot; it hands back however much of that is HIS, and settles
# its own books on the way. WorkStep gives the rest to the landowner.
#
# IT EXISTS SO THAT NOTHING OUTSIDE THIS FILE TOUCHES share_part_owed OR
# received_today. That is the same wall Stats.get_stat and Inventory.get_count
# already are, for the same reason: the wage is the thing most likely to be
# revisited in this whole rung — a payday, a piece rate, a guild minimum, a
# lord taking a cut off the top, a different rounding policy — and every one
# of those is a change to THIS FUNCTION BODY with no caller anywhere moving.
# An earlier draft had WorkStep do the arithmetic itself, reaching in and
# mutating two of this node's fields from outside; that version worked and
# was still wrong, because it spread the wage across two files and made
# swapping it a two-file edit forever after.
#
# WHY IT ROUNDS THROUGH A CARRY AND NOT OFF `made` ALONE. Grain comes off the
# furrow one WHOLE unit at a time and advance() runs every frame, so `made`
# is 0 or 1 on essentially every call that gets here. floor(1 x 0.35) is
# ZERO — so the naive split pays a worker nothing at all, forever, at any
# share strictly between 0 and 1, and does it quietly. The carry is what
# makes a fractional share mean anything.
#
# CONSERVES, BY CONSTRUCTION. share_part_owed is always in [0, 1) on entry,
# so floor(share_part_owed + made x share) <= made whenever share <= 1 — the
# worker's cut can never exceed what was raised, and WorkStep's owner_share
# = made - worker_share is therefore never negative. Whole grain in, whole
# grain out, nothing created and nothing destroyed.
func take_worker_share(made: int) -> int:
	if made <= 0:
		return 0
	share_part_owed += float(made) * share_of_crop
	var worker_share := int(floorf(share_part_owed))
	share_part_owed -= float(worker_share)
	if worker_share > 0:
		_record_payment(worker_share)
	return worker_share


# Record a whole grain landing in his sack as HIS wage — called from
# WorkStep's ownership branch the instant it pays him, never from anywhere
# that only decides or scores. LAZILY DAY-STAMPED, the exact pattern
# Workstation.claimed_on_day already uses: a payment stamped yesterday
# simply is not today's payment, and nothing sweeps or resets this on a
# timer — the comparison inside is_discharged() does the whole job at read
# time. NOT DERIVABLE FROM THE BARN, for the same reason the old
# delivered_count never was — more than one man can be paid out of the same
# land's takings, so the barn's total says nothing about which part of it
# was THIS man's.
func _record_payment(count: int) -> void:
	var person := get_parent() as Person
	var today := received_on_day
	if person != null and person.clock != null:
		today = person.clock.day()
	if received_on_day != today:
		received_today = 0
		received_on_day = today
	received_today += count


var received_today := 0
var received_on_day := -1


# DECISION 29's PAYMENT SEAM — a GAP, not a strategy object, and the reason
# it is a gap rather than a switch is the whole point of this rung. A share
# of a crop and a collected payday differ only in WHEN payment settles, not
# in how much, and both agree on this one question: what has he EARNED
# today, against what he has actually RECEIVED (record_payment above). A
# share settles the gap from WorkStep, continuously, as grain comes off the
# plot; a payday (not built) would leave the gap open all day and give an
# action with a walk in it something to close — gate: am I owed anything;
# score: this gap; step: not at him, walk, at him, be paid. No existing file
# would need to change to add it.
#
# EARNED IS RECEIVED PLUS THE FRACTION HE CANNOT YET BE HANDED. An earlier
# draft returned received_today straight back, which made the gap below read
# `x >= x` — a question that cannot be answered no. That is a vacuous
# assertion wearing a function's clothes, and it is the same failure this
# rung spent its whole budget hunting out of the probe: a check with no state
# in which it could ever have gone the other way proves nothing, and the next
# person to read it is entitled to believe it did.
#
# There IS a real gap here, and it is share_part_owed. A man is paid in whole
# grain because you cannot hand somebody four tenths of a grain, so between
# one whole grain and the next he is carrying credit the world genuinely owes
# him and genuinely has not given him. Counting it is what makes the sum
# below a measurement rather than a tautology.
#
# THE ONE IMPURITY, NAMED RATHER THAN HIDDEN: received_today is day-stamped
# and share_part_owed is not, because a rounding residue is not "today's"
# anything — it is the same unpaid fraction it was before midnight, and
# zeroing it at the boundary would quietly rob him of it every single night.
# So this sum can carry up to one grain of yesterday. It is bounded by one
# grain, it is deliberate, and a payday that ever needs the two scopes to
# agree should day-stamp the carry HERE rather than teaching its callers to
# subtract it.
#
# The day a real payday lands, THIS function is where its own formula goes
# (hours worked today × the wage, say), and the gap simply gets larger and
# stays open longer. No caller moves.
func get_earned_today() -> float:
	return float(received_today) + share_part_owed


# Is today's wage settled — a DERIVED question about the gap above, not a
# stamped event. THE OLD VERSION HERE READ BACK A MARK note_delivery() had
# FLIPPED — a switch somebody threw, which is exactly what made "meeting the
# quota" and "stopping work" the same event (Decision 29's finding): there
# was no window on either side of that flip in which a man had ever held a
# grain. Derived from the gap, there is nothing to stamp and nothing to
# reset at midnight — get_earned_today() and received_today already carry
# whatever day-scoping they need.
#
# IT ASKS WHETHER ANYTHING WHOLE IS OWED, NOT WHETHER THE GAP IS EXACTLY
# ZERO, and the difference between those two is the difference between a
# working seam and a trap. Two wrong versions were written before this one
# and both are worth knowing about:
#
#   `received >= received` — a tautology. It cannot answer no. A question
#   with one possible answer proves nothing, and every future probe claim
#   about it would pass for free.
#
#   `received >= received + carry` — false whenever ANY fraction is
#   outstanding. It reads honest and it is a trap: a fraction of a grain
#   CANNOT BE PAID. Nobody hands a man 0.35 of a grain, so a payday action
#   gated on this would bid, win, change nothing, and bid again forever —
#   the standing bid that never resolves, which Decision 32 already had to
#   shrink a number to work around once.
#
# So the gap is measured in what can actually change hands. Below one whole
# grain there is nothing anybody COULD give him, and his account is as square
# as arithmetic allows; at one or more, something is genuinely collectable
# and an action has something to do about it.
#
# UNDER SHARE-OF-CROP THIS IS TRUE, and — the point — it is true for a
# REASON rather than by construction: take_worker_share pays out every whole
# grain the moment it accrues, so the carry it leaves behind is always in
# [0, 1). Break that invariant and this reads false, which is what makes it
# an assertion worth writing. A payday, which lets the gap run all day, would
# read false for most of that day, and that is the seam doing its job.
#
# Nothing reads it yet — see Decision 31 for why WorkForHire's score stopped.
func is_discharged() -> bool:
	return get_earned_today() - float(received_today) < 1.0


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
