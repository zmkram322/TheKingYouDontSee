class_name Place
extends Node3D

# Somewhere a man can be. A name and a position, and deliberately nothing else.
#
# TWO QUESTIONS GET ASKED ABOUT A PLACE, and keeping them apart is the whole
# reason this node is as thin as it is:
#
#   "am I at the Inn?"              asked in GATE.  Discrete — one answer or null.
#   "what does the Inn cost me?"    asked in SCORE. Continuous — never gates.
#
# The first is answered by Person.get_current_place(), which reads a field the
# man carries. It is NOT answered by asking whether he is standing near this
# node. A radius flickers at its own edge — 5.01m, 4.99m, 5.01m and Drink
# appears on his ballot, vanishes, appears — and the brain re-decides every tick
# with nothing stored, so there is nothing anywhere to smooth it: the twitch
# would be the design working correctly on a bad answer. It also overlaps
# ambiguously when two places sit close together, and it makes arrival depend on
# the frame rate. That model was tried and reverted on 2026-08-08.
#
# The second IS geometry, read live off this node's transform by
# Person.get_travel_cost_to(). Drag this node in the editor and what it costs
# changes while the game is running — which is standing check #3, geography must
# be READ and never assumed, and that check is unsatisfiable unless something
# reads a transform. So the reverted ruling did not banish geometry; it moved it
# to the half where it cannot flicker, because a cost is never compared against
# a threshold. A far Inn is outbid, never barred.
#
# WHAT THIS NODE DOES NOT HOLD: a list of who is currently here. That would be
# one fact — where Zoogs is — written down twice, and two copies drift. A man
# freed mid-run lingers in the list (queue_free() does not null your reference,
# so `== null` stays false and the next property read errors), and any write
# that updates one copy and not the other hands rung 7 a trade with somebody who
# is not in the room. Ask Town.find_people_at() instead: it loops the people and
# asks each one, so there is only ever one copy to be wrong. See town.gd for
# what has to stay true for that to graduate into an index later.
#
# It will grow, and the dividing line is worth stating now: a place stores what
# is true OF THE PLACE. Rung 3 stands Workstations here — who has his hands on
# the millstone is a fact about the millstone. Rung 5 gives it an Inventory —
# the sacks in the barn are a fact about the barn and nowhere else. Where a man
# is, is true of the man.

# A NOTE ON THE NODE TYPE, so nobody "corrects" it back. This script extends
# Node3D, which is all a place needs — but in game.tscn the place nodes are
# MeshInstance3D, carrying their own ground pad instead of parenting a marker
# child. Godot accepts a Node3D script on any Node3D descendant, and it is worth
# doing: with a child marker, clicking the pad in the viewport selects the
# MARKER, so you drag the decoration while the place stays where it was and the
# travel cost never moves. Standing check #3 then looks broken when it isn't.
# Mesh on the place itself means clicking it selects the place. The transform's
# scale is the pad's size and does not touch its origin, so the position stays
# exactly where a man would stand.

@export var place_name := "Somewhere"
