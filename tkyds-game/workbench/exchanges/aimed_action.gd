extends Action

# AN ACTION AIMED AT WHATEVER YOU ARE LOOKING AT. The base Action answers "may he
# do this?"; this adds "may he do it TO THAT THING", carries what the arc needs
# to draw itself, and owns the one door doing it comes through.
#
# WHY THIS EXISTS SEPARATELY FROM exchange_action.gd. An exchange is between two
# PEOPLE — W3 is emphatic that both parties are a plain Person and neither is
# special, and the broker holds and runs upkeep for both. A bread basket is not a
# person and you do not have a conversation with it. But you DO look at it, and
# the arc's whole job is "what can I do to the thing I am looking at", so the
# basket belongs on the arc and not in the broker.
#
# So: this is the aimed half, exchange_action.gd is the between-two-people half,
# and the arc knows only about this one. Adding a verb aimed at a thing —
# a door, a cart, a barrel — is now a scene, not a change to the arc.
#
# THIS IS THE RULE THE WORKBENCH BREAKS, AND IT IS BROKEN IN ONE NAMED PLACE.
# Decision 35: since freeness became a public register, NOT ONE gate in the game
# reads where a man is standing, so no verb can be revealed by arriving anywhere.
# An arc over something is the opposite claim: this verb exists because that
# thing is in front of you. Deliberate, and confined to is_available_toward and
# the reach band below.
#
# WHY THE TARGET IS AN ARGUMENT AND NOT A STORED FIELD. Handing it in means no
# action ever holds a stale pointer to something that moved or was freed, and it
# keeps ActionStep's "hold no progress" rule intact: ask again every frame, about
# whatever is being looked at right now.

# What the arc draws. AUTHORED ON THE ACTION, never looked up from a table keyed
# by name — the same reason the clip name lives on the ActionStep instead of in a
# dictionary in game/. A UI that decides which picture means "greet" is code
# naming a verb, a failed build on the same footing as verb_list naming one. This
# file names nothing; it holds slots and whoever authors an action fills them.
@export var icon: Texture2D

# Stands in for the icon until there is art, and doubles as the colour coding.
@export var swatch := Color(0.85, 0.85, 0.85)

# The key that fires it. A single character, authored here, so the arc can show a
# shortcut without owning a keymap or knowing what the verb is called.
#
# W, A, S and D are SPENT — they are the movement keys, and Shift, Space and
# Escape are spent too (see the README's controls table). A verb authored onto
# one of those fires while you are walking, which reads as the game acting by
# itself.
@export var shortcut := ""

# --- HOW FAR IT REACHES -------------------------------------------------------
#
# A BAND, NOT A LIMIT, AND THE BAND IS WHAT MAKES THE VERBS FEEL DIFFERENT. You
# hail a man you can see from across a field; you hand him bread standing next to
# him; and you BECKON precisely because he is too far away to talk to. Beckoning
# somebody standing beside you is nonsense, so beckon authors a MINIMUM as well
# as a maximum and simply is not offered up close.
#
# WHY IT IS PER ACTION AND NOT ONE NUMBER ON THE ARC. One number can only say how
# far you can address somebody at all; it cannot say that this verb belongs near
# and that one belongs far. LookingAt keeps the outer limit of what you can even
# point at; these two decide which of your verbs survive at that range.
#
# Metres, flat — the vertical is dropped, because a man on a step is not further
# away in any sense that matters to whether you can hail him.
@export var reaches_within := 8.0

# Below this, the verb is NOT offered. 0.0 means "no minimum", which is what
# nearly everything wants.
@export var reaches_beyond := 0.0


func is_in_reach(person: Person, target: Node3D) -> bool:
	if person == null or not is_instance_valid(target):
		return false
	var apart := Vector3(
		target.global_position.x - person.global_position.x, 0.0,
		target.global_position.z - person.global_position.z).length()
	return apart <= reaches_within and apart >= reaches_beyond


# May he do this to THIS thing? Default: whatever the reach band says. Anything
# with its own opinion overrides and RE-ASKS THIS — an override replaces the base
# entirely, so a subclass that forgets the call silently ignores its own authored
# reach.
func is_available_toward(person: Person, target: Node3D) -> bool:
	return is_in_reach(person, target)


# DOING IT. The one door, called by the arc on a keypress and by nothing else.
#
# The arc knows only this method, which is what lets a verb aimed at a basket and
# a verb aimed at a man sit on the same arc without the arc learning the
# difference: an exchange's perform opens a conversation through the broker, a
# take's perform moves goods, and neither is a branch in the UI.
#
# Returns whether it actually happened, so the arc can say so rather than
# reporting a keypress it does not know the outcome of.
func perform(_person: Person, _target: Node3D) -> bool:
	push_warning("\"%s\" is on the arc but does nothing when pressed" % name)
	return false
