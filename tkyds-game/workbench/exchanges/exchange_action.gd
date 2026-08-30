extends Action

# An Action aimed at somebody. The base Action answers "may he do this?"; this
# adds "may he do this TO THAT MAN?", and carries what the arc needs to draw
# itself.
#
# THIS IS THE RULE EXCHANGES BREAKS, AND IT IS BROKEN IN ONE NAMED PLACE.
# Decision 35: since freeness became a public register, NOT ONE gate in the
# game reads where a man is standing, so no verb can be revealed by arriving
# anywhere — a ballot turns on what he CARRIES and what the town has DONE. An
# arc over somebody's head is the opposite claim: this verb exists because that
# man is in front of you. The break is deliberate and it is confined to
# is_available_toward below, which nothing in game/ calls and nothing in game/
# knows about.
#
# WHY THE TARGET IS AN ARGUMENT AND NOT A STORED FIELD. Handing the target in
# means no exchange action ever holds a stale pointer to somebody who walked
# off or was freed, and it keeps ActionStep's "hold no progress" rule intact:
# ask again every frame, from whoever is being looked at right now.

# What the arc draws. All three are AUTHORED ON THE ACTION, never looked up
# from a table keyed by name — the same reason the clip name lives on the
# ActionStep instead of in a dictionary in game/. A UI that decides which
# picture means "greet" is code naming a verb, which is a failed build on the
# same footing as verb_list naming one. This file names nothing; it holds a
# slot and whoever authors an action fills it.
@export var icon: Texture2D

# Stands in for the icon until there is art, and doubles as the colour coding.
@export var swatch := Color(0.85, 0.85, 0.85)

# The key that fires it. A single character, authored here, so the arc can show
# a shortcut without owning a keymap or knowing what the verb is called.
@export var shortcut := ""


# May he do this to THIS man? Default yes — an exchange that cannot be refused
# on the target's account says so itself.
#
# The person doing it is already gated by is_available_to, which is asked
# normally and is NOT replaced here: both have to say yes. That split is
# deliberate — "am I able to greet at all" and "is he a man I can greet" are
# different questions and blur into an unreadable single gate if merged.
func is_available_toward(_person: Person, _target: Person) -> bool:
	return true
