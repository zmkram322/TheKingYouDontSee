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
# Note what is also not here: an `owner`, and is_permitted_to(). This plot is
# common land — the king's, which is the same answer as nobody's — and both
# arrive at rung 6 when there is finally an Obligation for them to read.

# What kind of work is done here. Town.find_workstations matches on this, so it
# is what makes a plot answer "field work" and a millstone, one day, not.
@export var work_name := &"field work"

# Who has this spot, and which day he took it. -1 means never claimed, which no
# clock.day() ever returns.
var claimed_by: Person = null
var claimed_on_day := -1


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


# Free, or already his. Asked in GATE, every tick, by everybody — and it NEVER
# asks about presence: a man deciding from across town whether there is work for
# him must be able to see a free plot from there, or rung 4's "walk there and
# work" could never score. Standing here is claim()'s question alone.
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
