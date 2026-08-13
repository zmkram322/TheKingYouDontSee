class_name Workstation
extends Node3D

# One spot that one person works at a time. A plot in the grain fields today; a
# millstone, an anvil and — the case the expiry rule below was actually shaped
# for — a bed, later. Who has his hands on it is a fact about the STATION, not a
# plan stored on a person, which is why the two fields below don't break "store
# nothing you can work out again": no amount of looking at the world would tell
# you who claimed the millstone.
#
# A claim is a DAY-LONG TENANCY, not a per-tick lease. Two fields, and the
# second is what makes a claim expire without anything ever sweeping: a claim
# stamped yesterday simply isn't a claim today. Expiry is LAZY — one comparison,
# run at read time when somebody happens to ask — so a station nobody asks about
# can sit stamped with last week's claim forever at zero cost. Nothing sweeps,
# nothing maintains this, and UPKEEP never touches it. (A sweep was the original
# plan and was ruled out: it is incompatible with the frame-stagger rung 1
# exists to enable — a man thinking every 4th frame would fail to renew on 3 of
# them and be evicted from a plot he is standing on.)
#
# What keeps a claim alive is USE: the working step calls claim() on every tick
# it advances. He is present and it is already his, so the call succeeds and
# re-stamps today — a day boundary passes under a man mid-work and nothing
# expires. Only claims nobody is standing on go stale.
#
# There is deliberately NO release(). Under renew-on-use, abandoning a plot IS
# simply not renewing it — walk away and the claim lapses at the next day
# boundary on its own. A release() today would be a call site with no caller;
# what would earn it is an Action that scores giving a station up EARLY, so
# that somebody else can have it before tonight. Nothing scores that yet.
#
# Note what is_permitted_to() is not: nothing reads owned_by yet (below). This
# plot is common land — the king's, which is the same answer as nobody's — and
# a reader arrives at rung 6b when there is finally an Obligation to consult it.

# What kind of work is done here. Town.find_workstations matches on this, so it
# is what makes a plot answer "field work" and a millstone, one day, not.
@export var work_name := &"field work"

# Who has this spot, and which day he took it. -1 means never claimed, which no
# clock.day() ever returns.
var claimed_by: Person = null
var claimed_on_day := -1

# Who OWNS this spot, may be null. Unowned land is the king's, which is the
# same answer as nobody's — same reading as claimed_by == null above, just at
# a longer timescale: claimed_by is who has it today, owned_by is whose it is
# at all.
#
# NOT NAMED `owner` — Node already declares a built-in `owner` property (the
# scene owner a node belongs to for saving purposes), and redeclaring it is a
# GDScript compile error. `owned_by` was chosen to match `claimed_by` above it.
# The plan's documents call this field `owner`; it is `owned_by` here for
# exactly that reason.
#
# NO READER AT ALL THIS RUNG. Nothing in game/ asks this question yet — 6b's
# is_permitted_to() is its first reader, and until that lands this field is
# authored and inert.
@export var owned_by: Person = null

# Work done here that has not yet come to anything — a furrow part turned, in
# units of whatever this station makes. The step adds a tick's worth every tick
# it advances and takes whole units OUT the moment they complete, so this only
# ever holds the remainder: a number in [0, 1).
#
# WHY THERE IS A STORED NUMBER HERE AT ALL, since the substrate refuses stored
# progress everywhere else. A count is a whole thing (see inventory.gd) and a
# tick is a hundredth of an hour, so a plot yielding one grain an hour makes
# 0.01 of a grain per tick. That fraction has to survive to the next tick or a
# man works all day and produces nothing — truncated to a whole number, every
# tick of work rounds to zero, forever. It is genuinely not derivable from a
# snapshot: no amount of looking at the world tells you how far into this
# grain he is, which is the same test claimed_by already passes.
#
# AND WHY IT IS ON THE STATION RATHER THAN ON THE MAN. Decision 6 settles the
# category: work in progress is a fact about the world object, never about a
# person. Put it on the man and interrupting stops being free — he would carry
# a half-turned furrow across town to the next plot, and the step would be
# holding exactly the progress ActionStep exists to refuse. Here, walking away
# leaves the part-done work lying in the furrow where anyone can have it, which
# is both the better fiction and what rung 9a's half-ground sack already needs.
var output_part_made := 0.0


# A station stands AT a place — its parent, structurally — and everything about
# it hangs on that: presence is checked against the place, and Town finds
# stations by walking its places' children. One authored anywhere else is
# invisible and unclaimable, which without this warning would read as "nobody
# wants to work" rather than as a mis-parented node.
func _ready() -> void:
	if get_place() == null:
		push_warning("Workstation \"%s\" is not the child of a Place — nobody will ever find or work it" % name)


# The place this station stands at — its parent, the same "structurally where it
# belongs" pattern Brain uses to find its Person. No wire to mis-type.
func get_place() -> Place:
	return get_parent() as Place


# What is sitting ON this station — the sack on the millstone, and one day the
# half-ground flour beside it. Found as a child, asked in the same words as a
# person's and a place's, and null where nothing is ever set down. Nothing in
# the game puts anything here yet: rung 9a is what needs it, when inputs move
# onto a station as work starts so that a man who wanders off mid-grind leaves
# the grain on the stone instead of carrying it away.
func get_inventory() -> Inventory:
	return get_node_or_null("Inventory") as Inventory


# Free, or already his. The plain truth about this station, and it NEVER asks
# about presence — not because distance is irrelevant, but because whose
# question that is, is settled elsewhere.
#
# THE COMMENT THAT USED TO BE HERE ARGUED THE OPPOSITE AND WAS WRONG. It said
# a man across town must be able to see a free plot from there or he could never
# score walking to it. He must not: a plot he can see the state of from his bed
# is omniscience, and it stops him ever setting off, because the moment somebody
# else takes it work leaves his ballot while he is still at the Inn. The code was
# always right and only the reasoning was backwards, which is why this is a
# comment fix and not a change. (Decision 15.)
#
# The knowledge rule lives in WorkTheField._is_a_candidate_for, where it belongs:
# a station reports what is true OF ITSELF, and what a man knows of that truth is
# the asking action's business. The world is not obliged to lie on his behalf.
# Standing here is still claim()'s question alone.
func is_free_for(person: Person) -> bool:
	# A holder who has been freed is not a holder.
	#
	# UNREACHABLE TODAY — measured 2026-08-10 by deleting it: the probe stayed
	# green with zero errors, because a TRULY freed reference already compares
	# `== null` as true in this engine. (The trap CLAUDE.md documents is the
	# queue_free() case, where the node survives to end-of-frame and `== null`
	# stays false — but a claim is only ever read on a later tick, by which
	# time the deletion has landed either way.) Third guard in the codebase
	# standing unreachable for this same engine reason; kept like the others,
	# because freed-compares-null is an undocumented quirk where
	# is_instance_valid is the documented contract, and one line is cheap
	# insurance against the quirk moving under a future engine.
	if not is_instance_valid(claimed_by):
		claimed_by = null
	if claimed_by == null:
		return true
	# Yesterday's claim, expired where it lies. The day is read off the asking
	# person's clock — everyone shares the one Clock, pulled off Population at
	# birth — so not one station carries a wire of its own.
	if claimed_on_day < person.clock.day():
		return true
	return claimed_by == person


# Take it, or re-stamp it if it is already his. Written in DO, and only by a
# man standing here — you cannot reserve a plot from your bed. For the man
# already holding it this is the renewal: the working step calls it every tick
# it advances, and that re-stamp is the whole mechanism that keeps a worked
# claim alive across a day boundary.
func claim(person: Person) -> bool:
	if person.get_current_place() != get_place():
		return false
	if not is_free_for(person):
		return false
	claimed_by = person
	claimed_on_day = person.clock.day()
	return true
