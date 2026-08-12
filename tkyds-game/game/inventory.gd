class_name Inventory
extends Node

# What something holds. A man's pockets, a barn's floor, the sack sitting on a
# millstone — ONE node, mounted under Person, Place AND Workstation alike,
# because "what is here" is the same question wherever it is asked, and a second
# implementation of it is a second place for goods to leak out of.
#
# A NAME AND A COUNT, AND NOTHING ELSE. No weight, no stack limit, no quality,
# no database of what an item IS, no Resource per kind of thing. An item is a
# StringName and a whole number. Every one of those omissions is something
# nothing has yet bumped against, and a limit nothing bumps against is substrate
# built before need.
#
# get_count mirrors the get_stat / set_stat wall exactly, and for the reason
# CLAUDE.md names that wall load-bearing: named access is what lets the store
# graduate — Dictionary today, a packed array or something native later —
# without one call site moving. Nothing outside this file touches `items`.
#
# THREE DOORS, AND KEEPING THEM APART IS THE WHOLE POINT:
#
#   add        CREATION      production only. A world total goes UP here.
#   take       DESTRUCTION   consumption only. A world total goes DOWN here.
#   hand_over  MOVEMENT      the one waist all goods pass through, both ways,
#                            and it changes no total at all.
#
# So "did the town's grain change, and why?" has exactly two suspects. That is
# what makes a conservation check mean anything rather than being a sum that
# always agrees with itself, and it is what stops rungs 6b, 7 and 9a each
# growing a transfer path of their own — three paths being three places for a
# half-completed transfer to hide.

# Everything held here, by name: StringName -> int. Kept as an @export for the
# reason Stats keeps its numbers that way — you can select the barn in a running
# scene and read what is in it, and a starting stock (rung 6a authors bread onto
# a farmer) is then a value typed into the inspector rather than a line of code.
#
# Exported and still walled: read it through get_count, write it through the
# three doors above. A wall is only a wall while everything goes through it.
@export var items := {}


# How many of a thing is here. Nothing it has never held reads zero rather than
# erroring — an inventory is not a list of declarations the way Stats is, so a
# name nobody has stocked yet is a legitimate question with an obvious answer.
#
# INT, NEVER FLOAT, and callers should keep it that way. A count is a count;
# the day half a grain can exist, "how much is in the barn" stops having a
# straight answer and every comparison in the game grows an epsilon. Work that
# arrives in fractions is banked as fractions where the work happens
# (Workstation.output_part_made) and only ever lands here whole.
func get_count(item_name: StringName) -> int:
	return int(items.get(item_name, 0))


# CREATION. Something was made, or it is being authored into the world at the
# start of a run. Nothing else may call this — a transfer that reaches for add
# on one side is how a world total quietly grows, and the growth shows up three
# rungs later as an economy that inflates for no reason anybody can name.
func add(item_name: StringName, count: int) -> void:
	# A negative add is a take wearing a disguise, and it would slip destruction
	# through the creation door — the one thing the split above exists to stop.
	# Said out loud rather than quietly flipped, because the caller believes it
	# is producing something.
	if count < 0:
		push_warning("tried to add %d %s — a negative add is a take, and it has its own door" % [count, item_name])
		return
	if count == 0:
		return
	items[item_name] = get_count(item_name) + count


# DESTRUCTION. Something was eaten, burned, or consumed by work. Answers whether
# it happened, and the answer is the whole contract: a take that cannot be
# satisfied moves NOTHING. No partial take, and never a negative count — a
# count below zero is a debt, and a debt is a promise, which is a system nobody
# has asked for.
func take(item_name: StringName, count: int) -> bool:
	if count < 0:
		push_warning("tried to take %d %s — a negative take is an add, and it has its own door" % [count, item_name])
		return false
	if not has_at_least(item_name, count):
		return false
	# The key is left in place at zero rather than erased. An item he has spent
	# down to nothing is still a thing he deals in, and a line that VANISHES off
	# the graph reads as broken instrumentation where a line sitting on the axis
	# reads as the truth: he is out.
	items[item_name] = get_count(item_name) - count
	return true


# Enough for what somebody is about to do. Its own method rather than a
# comparison at each call site, because "can he afford it" is asked in GATE by
# things that must not change anything, and a gate reaching into `items` would
# be a write waiting to happen.
func has_at_least(item_name: StringName, count: int) -> bool:
	return get_count(item_name) >= count


# MOVEMENT — the one waist. Goods leave one inventory and arrive in another, and
# no world total changes: this is deliberately not add plus take, it is take
# plus add, in that order, so the only way to move something is to have had it.
#
# BOTH HALVES OR NEITHER. The take is attempted first and the add only runs if
# it succeeded, so a transfer that cannot complete moves nothing at all. Written
# this way rather than checked-then-done because a check followed by two writes
# is two chances to be interrupted between them, and a transfer that
# half-happened surfaces three rungs later as an item count that drifts — which
# you will not find by reading, because every individual line of it looks right.
func hand_over(item_name: StringName, count: int, to_inventory: Inventory) -> bool:
	# Nowhere is not a destination. Handing goods to null would destroy them
	# silently through the movement door, which is exactly the leak the three-way
	# split exists to make impossible.
	if to_inventory == null:
		push_warning("tried to hand over %d %s to nothing at all" % [count, item_name])
		return false
	if not take(item_name, count):
		return false
	to_inventory.add(item_name, count)
	return true


# Everything held here, by name — the reflection the readout and the graph run
# on, so an item that turns up in the world for the first time appears over his
# head and on the instrument without a line being written for it. Nothing in
# game/ names one particular item.
#
# Sorted, and not for tidiness: the graph hands out a colour per series in the
# order this returns, so an unsorted list would give the same item a different
# colour on each panel and re-shuffle everybody's readout the moment somebody
# produced something new.
func get_item_names() -> Array[StringName]:
	var found: Array[StringName] = []
	for key: Variant in items:
		found.append(StringName(key))
	found.sort()
	return found
