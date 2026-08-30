extends "res://workbench/exchanges/exchange_action.gd"

# CALLING SOMEBODY OVER. Beckon and follow are both this file — they differ only
# in which scene they land, and those two differ only in one flag. "Come here"
# and "stay with me" are the same behaviour with different stopping conditions,
# so they are one action authored twice rather than two actions kept in step.
#
# THE ONLY THING THIS ADDS to the base result seam is WHO CALLED. land_on already
# puts the action in his repertoire; without this the man would carry a summons
# with nobody summoning him, which come_along.gd reads — correctly — as nobody
# calling, and he would stand there. That is the whole of the script.
#
# WHY THE NAME IS SET HERE AND NOT AUTHORED: a PackedScene is shared, and the
# summoner is the one part of a summons that cannot be known until the moment it
# happens. It is the same split as everywhere else in this folder — the KIND of
# thing is authored, the WHO is passed in.


func settle(initiator: Person, recipient: Person) -> void:
	super(initiator, recipient)
	# Found rather than remembered from land_on's return, so that a summons he
	# was ALREADY carrying is re-pointed at whoever just called instead of a
	# second one being landed. Being beckoned by somebody new while walking to
	# somebody else means you turn around, not that you owe two men your company.
	var summons := find_landed(lands_on_recipient, recipient)
	if summons == null:
		push_warning("\"%s\" landed nothing to be summoned by" % name)
		return
	summons.set(&"summoner", initiator)
