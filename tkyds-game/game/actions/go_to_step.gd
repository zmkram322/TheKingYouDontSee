class_name GoToStep
extends ActionStep

# Getting there. The only thing in the game that moves a body, and the only
# thing that writes where a man IS.
#
# It holds no route, no destination, no progress and no "how far along am I" —
# like every step here, it re-derives everything from the world each tick. That
# is what makes being interrupted free: nothing was suspended, so nothing has to
# be put back, and a man outbid halfway across town simply does something else
# from where he now stands.
#
# WHY IT TAKES ITS DESTINATION AS AN ARGUMENT rather than overriding advance().
# Where a man is going is dynamic — WHICH plot, chosen fresh every tick by the
# action above — so it cannot come from an @export, and advance(person, hours)
# has no room to be told. So the verb is walk_toward(), and whoever hosts this
# step passes the place it re-derived. A destination stored on this node would
# be exactly the remembered plan the rest of the design refuses to keep.
#
# WHERE IT LIVES: nested UNDER the step that uses it, never beside it.
# Action._ready takes the FIRST ActionStep child it finds, so two ActionSteps
# under one Action would silently pick one and ignore the other. Nesting is also
# what lets any later action reuse walking — one more of these under its own
# step, and no walking code moves.
#
# TWO THINGS IT DELIBERATELY DOES NOT DO:
#
#   move_and_slide(). Measured (Decision 4): called from _process it multiplies
#   by the PHYSICS delta and produces non-uniform displacement, and under
#   PROCESS_MODE_DISABLED it moves ZERO in silence — which would make every
#   movement claim in the probe unwritable. global_position is integrated by
#   hand instead, which moves exactly the same amount at any tick rate.
#
#   Steering, acceleration, pathfinding, obstacle avoidance. He moves toward a
#   point at a constant speed. Two capsules converging on one plot will stand
#   inside each other, and that is a cosmetic fact about a diorama rather than a
#   thing to build a navmesh for.
#
# ONE INHERITED KNOB THAT DOES NOTHING HERE, so nobody spends an afternoon on
# it: `exertion` is read by Brain.get_exertion() off the CURRENT ACTION'S step,
# which is the step this one is nested under — never off this node. Walking
# therefore tires a man exactly as much as whatever he is walking in service of,
# and setting a number here would change nothing. The day walking should cost
# more than standing, the honest fix is Brain asking the innermost step what it
# is doing, not a second number quietly ignored.


# Walk him one tick's worth toward a place, and say whether he is now there.
#
# ARRIVAL IS AN OVERSHOOT CLAMP AND NEVER A RADIUS. The question asked is "would
# this tick's step take me there or past it?" — and if it would, he is put ON
# the spot exactly and his place is written once. There is no "within N metres"
# constant, so there is nothing to tune and nothing that lands differently at a
# different tick rate. A radius would flicker at its own edge, would overlap
# ambiguously where two places sit close together, and would make arrival depend
# on the frame rate — that model was tried here and reverted on 2026-08-08, and
# a "close enough" check of any kind is how it comes back in through a side
# door. (Decision 10.)
#
# DEPARTURE WRITES NULL, and it is not bookkeeping. The first tick of a journey
# clears his place, so a man on the road is at no place at all — which is the
# truth, and which is what stops Town.find_people_at from standing him with
# everybody else who is also on a road. Without the clear he keeps the fields
# all the way to the Inn, and rung 7's "same place?" gate then says two men half
# a town apart are trading.
func walk_toward(person: Person, place: Place, hours: float) -> bool:
	if place == null:
		# Nowhere is not a destination. Said out loud rather than returned as a
		# quiet "not there yet", because a man walking toward null would stand
		# still forever and read as a broken decision rather than a missing
		# place.
		push_warning("%s was told to walk to nowhere" % person.person_name)
		return false

	if not walk_toward_point(person, place.global_position, hours):
		return false
	person.current_place = place
	return true


# The movement on its own, with no opinion about WHY he is going there. Split out
# of walk_toward above so that walking toward something that is not a Place — a
# man, a cart, a spot in a field — does not need a second copy of the one piece
# of code that moves a body. walk_toward is this plus the place bookkeeping, and
# behaves exactly as it did before the split.
#
# ARRIVAL IS AN OVERSHOOT CLAMP AND NEVER A RADIUS. The question asked is "would
# this tick's step take me there or past it?" — and if it would, he is put ON the
# point exactly. There is no "within N metres" constant here, so there is nothing
# to tune and nothing that lands differently at a different tick rate. A radius
# would flicker at its own edge and would make arrival depend on the frame rate;
# that model was tried and reverted on 2026-08-08 (Decision 10). A caller that
# wants to stop SHORT of something asks for a point that is short of it, which
# keeps the clamp doing the work and introduces no threshold.
#
# DEPARTURE WRITES NULL, and it is not bookkeeping — see walk_toward's header.
# It belongs here rather than up there because it is true of any journey: the
# moment he is on the road he is at no place, whether or not he is headed for one.
# `pace` is a MULTIPLE OF HIS OWN WALK, and it defaults to 1.0 so every caller
# that has one speed keeps it and reads exactly as it did. It exists because a
# man can be made to hurry — a summons is the first thing that does it — and the
# alternative was a second integrator somewhere else, which would have made this
# file's own claim to be "the only thing in the game that moves a body" false.
# A multiple rather than a speed so it stays dimensionless: a strong man hurries
# from his own faster walk, and Person._show_the_body reads the same fraction to
# decide whether his legs are walking or running.
func walk_toward_point(person: Person, point: Vector3, hours: float, pace := 1.0) -> bool:
	var to_there := point - person.global_position
	var gap := to_there.length()
	var step := person.get_travel_speed() * pace * hours

	# There, or would be past it by the end of this tick. Snapped onto the spot
	# rather than left a hair short, so "am I at the fields" is answered by a
	# field he carries and never by how close he happens to be standing. Also
	# the zero-gap case: a man already on the spot arrives without dividing by
	# nothing.
	if step >= gap:
		person.global_position = point
		return true

	# Still on the road, and therefore at no place.
	person.current_place = null
	person.global_position += to_there / gap * step
	return false


# Nothing more specific is knowable from here — this node does not remember
# where he was sent, so it cannot name the destination. Whoever hosts it
# re-derives that anyway and can say it better.
func describe(_person: Person) -> String:
	return "on the way"
