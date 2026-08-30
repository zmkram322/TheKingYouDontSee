extends Node3D

# A BASKET WITH BREAD IN IT. The simplest possible thing in the world that is not
# a person and is worth looking at.
#
# IT ANSWERS get_inventory() AND THAT IS ITS WHOLE INTERFACE. Person, Place and
# Workstation all answer the same question in the same words, which is what lets
# take_from.gd be written about "a thing with an inventory" rather than about a
# basket — author a barrel, a cart, a market stall, and the same verb works on it
# with no file naming which.
#
# THE LOAVES ARE AUTHORED IN THIS SCENE, NOT IN exchanges.tscn, AND THAT IS
# DELIBERATE. Six loaves authored onto the player in exchanges.tscn were
# overwritten out of the file five times by an open editor re-saving from its own
# stale copy; give was gated shut and appeared nowhere, with no error anywhere.
# Contents that live in the container's own scene are not in the file the editor
# is holding open. That is a happy side effect rather than the reason, though —
# the reason is that goods should come from somewhere.
#
# NO SCRIPT ON THE INVENTORY, NO SCRIPT DOING THE HANDING. This file holds no
# logic at all beyond the accessor: taking is take_from.gd's job, and the
# transfer is Inventory.hand_over, the one transfer path.

@onready var inventory: Inventory = $Inventory


func _ready() -> void:
	if inventory == null:
		push_warning("a basket with no Inventory holds nothing — nobody can take from it")


# The same wall Person.get_inventory is, in the same words. Nothing outside
# inventory.gd touches `items`.
func get_inventory() -> Inventory:
	return inventory
