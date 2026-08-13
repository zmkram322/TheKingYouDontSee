class_name WorkForHireStep
extends WorkStep

# Working because you are employed to — the same working WorkStep already
# does (walking, claiming, the furrow, the yield seam), PLUS one more leg:
# handing over what is owed, on the spot, as it comes off the plot.
#
# advance() calls super.advance() FIRST, unconditionally, and only then
# attempts delivery. This file ADDS a leg; it does not rewrite the one
# WorkStep already has, which is what keeps claims 25 and 26 — about the
# WORKING half — true here without a single line of them changing meaning.


func advance(person: Person, hours: float) -> bool:
	var done := super.advance(person, hours)
	_attempt_delivery(person)
	return done


# hand_over is the ONE transfer path Inventory has (its three doors), and it
# CONSERVES — nothing this leg does can move a world total, only WHERE it
# lands, which is what the probe leans on to prove delivery isn't quietly
# creating or destroying grain.
#
# THE CAP IS DELIBERATE. He delivers what he owes TODAY and the surplus stays
# his — that surplus is rung 7's trade stock, not something this rung reaches
# for. Capping at get_remaining_today() rather than handing over everything he
# is carrying is what makes "a quota" mean anything at all; without the cap
# this would be a tax, not a target.
#
# delivered_count is the agreement's "is" side against owed_count's "should
# be" — Decision 19's target-minus-stock shape, the same one hunger reads on
# a different stat.
func _attempt_delivery(person: Person) -> void:
	var work := get_parent() as WorkForHire
	if work == null:
		return
	var obligation := work.get_standing_obligation(person)
	if obligation == null or obligation.is_discharged():
		return
	# Delivery, like the work itself, only happens where it is owed — a man
	# is not handing grain into a barn he cannot see, and this is the same
	# "compare by name" shape Obligation.place_name is typed for, no Town
	# query needed.
	var place := person.get_current_place()
	if place == null or place.place_name != obligation.place_name:
		return
	var barn := place.get_inventory()
	if barn == null:
		return
	var inventory := person.get_inventory()
	if inventory == null:
		return
	var carrying := inventory.get_count(obligation.owed_item)
	var moving := mini(carrying, obligation.get_remaining_today())
	if moving <= 0:
		return
	if inventory.hand_over(obligation.owed_item, moving, barn):
		obligation.note_delivery(moving)
