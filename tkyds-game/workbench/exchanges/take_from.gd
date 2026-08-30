extends "res://workbench/exchanges/aimed_action.gd"

# TAKING SOMETHING OUT OF A CONTAINER. The first aimed action whose target is not
# a person, and the reason aimed_action.gd was split out of exchange_action.gd at
# all: you look at a basket the same way you look at a man, but you do not have a
# conversation with it, and it must never reach the broker.
#
# WHY THIS EXISTS RATHER THAN AUTHORING BREAD INTO THE PLAYER'S INVENTORY.
# exchanges.tscn authored him six loaves and an open editor overwrote that block
# FIVE times from its own stale copy, so give was gated shut and appeared nowhere
# with no error. The basket is not a workaround for that — it is the honest
# version of the same thing. **Goods should come from somewhere.** A player who
# starts holding bread because a scene file says so cannot answer "where did it
# come from", and the moment anything else wants to hand out goods — a barn, a
# market stall, a body — it would need its own answer. This one is reusable, and
# it survives the editor because the loaves live in the BASKET'S own scene file.
#
# THE TRANSFER IS THE ONE TRANSFER PATH. Inventory.hand_over, take-then-add,
# both halves or neither. `add` creates and `take` destroys, and neither is
# called here — so a world total cannot move because somebody helped himself.

# What comes out, and how much per press. An item name and a count, authored —
# naming the GOODS is data, the same as a clip name on an ActionStep. Naming the
# VERB would not be.
@export var takes_item := &"bread"
@export var takes_count := 1


# The taker's half: is he in a state to take anything at all. Kept apart from the
# target half below for the usual reason — "can I pick things up" and "is that a
# thing with bread in it" fail for different reasons and blur into an unreadable
# single gate if merged.
func is_available_to(person: Person) -> bool:
	return person.brain.is_awake()


# And the target half: is that thing a container with what I want in it.
#
# ASKED OF THE THING, NOT OF A LIST OF THINGS. Anything that answers
# get_inventory() can be taken from — a basket today, a barrel or a cart or a
# dead man later — with no file naming which. That is the same duck-typed reach
# Person, Place and Workstation already share by all answering get_inventory().
#
# THE REACH BAND IS RE-ASKED rather than replaced: an override takes the base out
# entirely, and a take you could do from across the field would be a verb that
# reaches through walls.
func is_available_toward(person: Person, target: Node3D) -> bool:
	if not is_in_reach(person, target):
		return false
	var held := _get_inventory(target)
	if held == null:
		return false
	return held.has_at_least(takes_item, takes_count)


func perform(person: Person, target: Node3D) -> bool:
	if not is_available_toward(person, target):
		return false
	var held := _get_inventory(target)
	if held == null:
		return false
	var moved := held.hand_over(takes_item, takes_count, person.get_inventory())
	if not moved:
		# The gate said yes and the transfer said no, so the world changed between
		# the two. Said out loud rather than swallowed — a silent null guard is how
		# a dead day/night cycle shipped through two commits here.
		push_warning("%s could not take %d %s" % [person.person_name, takes_count, takes_item])
		return false
	print("TOOK — %s took %d %s from %s" % [
		person.person_name, takes_count, takes_item, target.name])
	return true


func _get_inventory(target: Node3D) -> Inventory:
	if not is_instance_valid(target) or not target.has_method(&"get_inventory"):
		return null
	return target.call(&"get_inventory") as Inventory
