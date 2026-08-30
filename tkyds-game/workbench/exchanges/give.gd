extends "res://workbench/exchanges/exchange_action.gd"

# Handing something over. The first exchange whose result is a change to the
# WORLD rather than to a repertoire, and W4 is why it is the first of the two:
# of the three kinds envisioned — information, goods/services, pleasantries —
# only goods/services lands on machinery that already exists.
#
# IT DOES NOT OVERRIDE THE RUNG. give.tscn authors `needs_to_have_met`, so this
# is not on a stranger's head — you greet him first, and the greeting is what
# put the record there. Nothing in this file says so, which is the point of the
# field. It was authored `offered = "only once talking"` first and that stopped
# working the day a greeting became a thing that ENDS: give flashed for four
# seconds and vanished. Gating on the RELATIONSHIP survives walking away, works
# NPC-to-NPC, and makes the greeting matter rather than be a doorway.
#
# THE TRANSFER IS IN settle(), NOT IN THE STEP, and that split is the whole
# shape of an exchange. The step is what the GIVER'S BODY looks like — one clip,
# played because a hand chose a verb — and it is presentation. Handing goods
# over is what the exchange RESULTED IN, it happens once, and it happens at the
# broker's door with the conversation standing around it. Putting it in the step
# would run it every tick he wore the clip, which is a man emptying his pockets
# for as long as he holds a wave.

# WHAT MOVES. An item name and a count, authored — not a verb, and not a
# playstyle: a StringName that matches Inventory's own keys, the same kind of
# authored datum as the clip name on an ActionStep. Naming the GOODS is allowed;
# naming the VERB is not.
@export var gives_item := &"bread"
@export var gives_count := 1


# The giver's half, and it belongs HERE rather than in is_available_toward:
# "have I got one to give" is a question about him, not about the man in front
# of him. Keeping the two apart is what stops the arc disappearing for a reason
# you would have to read the wrong file to understand.
#
# has_at_least rather than a count comparison, because get_count is Inventory's
# wall and the question already has a name on the other side of it.
func is_available_to(person: Person) -> bool:
	if not person.brain.is_awake():
		return false
	return person.get_inventory().has_at_least(gives_item, gives_count)


# THE ONE TRANSFER PATH, and nothing here is allowed to be a second one.
# CLAUDE.md: add creates, take destroys, hand_over moves — a world total may
# change only where add or take is called, which is what makes a conservation
# check mean anything. hand_over is take-then-add: both halves or neither.
#
# super() LAST, DELIBERATELY. The base lands whatever scenes the two slots hold,
# and an outcome that wants to read what he is now carrying — an errand to go
# use the thing he was just handed — must find the goods already there. The
# other order would hand a man an errand about a loaf he does not have yet.
func settle(initiator: Person, recipient: Person) -> void:
	var moved := initiator.get_inventory().hand_over(
		gives_item, gives_count, recipient.get_inventory())
	if not moved:
		# The gate said yes and the transfer said no, which means the world
		# changed between the two. Said out loud rather than swallowed: a silent
		# null guard is how a dead day/night cycle shipped through two commits.
		push_warning("%s could not hand %d %s to %s" % [
			initiator.person_name, gives_count, gives_item, recipient.person_name])
		return
	super(initiator, recipient)
