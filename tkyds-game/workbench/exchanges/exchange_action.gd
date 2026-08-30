extends Action

const Acquaintance := preload("res://workbench/exchanges/acquaintance.gd")

# An Action aimed at somebody. The base Action answers "may he do this?"; this
# adds "may he do this TO THAT MAN, GIVEN WHETHER THEY ARE ALREADY TALKING?",
# carries what the arc needs to draw itself, and owns THE ONE DOOR AN EXCHANGE'S
# RESULT COMES THROUGH.
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
# ask again every frame, from whoever is being looked at right now. The live
# exchange is handed in for exactly the same reason, and it is asked of the
# broker afresh every frame rather than remembered here.

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
#
# W, A, S and D are SPENT — they are the movement keys, and Shift, Space and
# Escape are spent too (see the README's controls table). An exchange authored
# onto one of those fires while you are walking, which reads as the game
# talking to people by itself.
@export var shortcut := ""

# HOW LONG IT RUNS, IN REAL SECONDS — and the unit is the whole point.
#
# W10 authored this in WORLD HOURS, on the rule that every rate in game/ is per
# world hour and real time is converted once, up in Clock, and never seen again.
# THAT RULE IS RIGHT AND THIS IS NOT ONE OF ITS CASES. A world hour is a fact
# about the simulation, and day_length_seconds is a tuning slider: at the shipped
# 60 s/day one hour is 2.5 real seconds, and at a real play speed of 600 s/day it
# is twenty-five. So an exchange authored in hours is a two-second wave while you
# are debugging and a twenty-second wave when you are playing, off ONE number
# nobody edited.
#
# A GESTURE'S LENGTH IS A FACT ABOUT THE GESTURE. A greeting takes about as long
# as it takes to raise a hand, and that does not get longer because the sun is
# moving slower. This is the same side of the line clip choice is already on:
# presentation runs on the frame clock (person.gd chooses a clip in _process, not
# in think_and_act) because it answers to how often it is LOOKED AT.
#
# WHAT IS GIVEN UP, SAID OUT LOUD. W10 wanted the cost denominated in world hours
# so that a conversation costs the same slice of a man's life whether anybody is
# watching. Under real seconds it does not: the world hours a greeting eats now
# vary with day_length_seconds. That is accepted here because a greeting COSTS
# NOTHING yet — no outcome, no stat, nothing left behind. The day an exchange
# has a real price, the price is its own number in world hours and this one stays
# what it is: how long you watch it.
@export var takes_seconds := 4.0

# --- THE ANSWER ---------------------------------------------------------------
#
# AN EXCHANGE HAS TWO SIDES AND THEY ARE NOT THE SAME SIDE. The first cut handed
# both men the same Action, so they played the same clip on the same frame and
# read as two strangers waving in unison rather than as a greeting and a reply.
#
# The answer is its own Action with its own step, AUTHORED, so the clip comes off
# a step exactly like every other clip in the game and no file maps a verb to an
# animation. It is instanced under the Exchange, not learned into anybody's
# repertoire — nobody CHOOSES to answer, and an answer on the ballot would be a
# verb a man could pick out of nowhere.
#
# THIS IS ALSO WHERE REFUSAL WILL LIVE. W1 and W2 leave "what does a no look
# like" open, and the honest answer is that it looks like a different reply: a
# shake_head where a nod would have gone. Nothing structural is missing for it —
# when the broker learns to decide the answer instead of always playing the
# authored one, this slot becomes two and the rest of the file does not move.
@export var answered_with: PackedScene

# THE BEAT, in REAL SECONDS after the exchange opens — same argument as
# takes_seconds above. Nobody answers before he has been spoken to; that pause is
# most of what makes the pair read as one event rather than two coincidences, and
# how long a man takes to notice you and raise his own hand is not a thing the
# day length has an opinion about.
#
# UNTIL IT LANDS THE ANSWERER STANDS. Not "keeps doing what he was doing" — a man
# stopped on his way to bed would look like he was sleeping on his feet (W8's
# open item), and a man listening is a man who has stopped.
#
# Must be shorter than takes_seconds or the answer never plays; the broker says
# so out loud rather than leaving you to wonder why nobody replied.
@export var answers_after_seconds := 1.2

# --- WHEN IT IS ON THE TABLE --------------------------------------------------
#
# THERE WAS AN `offered` ENUM HERE — "either" / "only to open" / "only once
# talking" — AND IT IS GONE. It was the first attempt at the greeting ladder and
# it died twice, both times for reasons worth keeping:
#
#   1. It gated on a LIVE CONVERSATION, which stopped meaning anything the day a
#      greeting became a thing that ENDS (W11). Give and ask flashed for four
#      seconds and vanished. `needs_to_have_met` below replaces it, and gating on
#      the RELATIONSHIP is better in every direction: it survives walking away and
#      coming back, and it works NPC-to-NPC where no conversation is ever standing
#      for a player to act inside.
#
#   2. Its remaining case became unreachable. Nothing is offered at all while an
#      exchange stands (see exchange_arc._get_open_exchanges), because W10 draws
#      one hard line under the reveal — *"it must not be interactive. The moment
#      the player can do something during the animation that changes the outcome,
#      the answer was not decided at the ask."* An arc full of pressable verbs
#      mid-wave is exactly that. With nothing offerable during an exchange, "only
#      to open" and "either" say the same thing.
#
# WHEN A CONVERSATION CAN PERSIST rather than always running its course, the
# distinction that matters will be between *mid-reveal* (nothing offered) and
# *standing, awaiting your move* (verbs offered) — which is not what this enum
# said, so it is deleted rather than kept warm for a case it does not fit.

# WHAT HE MUST ALREADY THINK OF THE MAN, for this to be on the table at all.
#
# THE REAL GREETING LADDER, and it is what replaced `offered` — see above. It
# makes the greeting MATTER rather than be a doorway: the record it leaves is the
# thing everything after it turns on.
#
# -1 IS "NO REQUIREMENT" AND 0 IS "WE HAVE MET". A stranger has no Acquaintance
# node at all and reads 0.0 warmth, which is why the test below is strictly
# greater-than AND is paired with have_met: 0 must not mean both "never spoken"
# and "spoken, thinks nothing much of me". Authoring 0.0 here means "greet me
# first"; authoring 25.0 would mean "we would have to be friends".
@export var needs_regard_above := -1.0

# Whether having MET is required at all, separate from how warm it must be. Kept
# apart for the reason above: they are two different facts and one number cannot
# carry both.
@export var needs_to_have_met := false


# May he do this to THIS man? Default: whatever he already thinks of him, and
# nothing else. An exchange that cannot be refused on the target's own account
# says so by not overriding this.
#
# NO LONGER TAKES THE LIVE EXCHANGE. It did, so that `offered` could read it, and
# once nothing is offerable during an exchange at all the argument was null on
# every single call — a parameter that can only ever hold one value, which the
# next reader would have to prove to themselves is dead. When a persisting
# conversation needs it back, it comes back then.
#
# The person doing it is already gated by is_available_to, which is asked
# normally and is NOT replaced here: both have to say yes. That split is
# deliberate — "am I able to greet at all" and "is he a man I can greet" are
# different questions and blur into an unreadable single gate if merged.
func is_available_toward(person: Person, target: Person) -> bool:
	return is_regarded_enough(person, target)


# Does he think enough of that man for this to be offerable? Both halves, asked
# separately and both required — same discipline as is_available_to /
# is_available_toward one level up.
func is_regarded_enough(person: Person, target: Person) -> bool:
	if needs_to_have_met and not Acquaintance.have_met(person, target):
		return false
	return Acquaintance.get_warmth(person, target) > needs_regard_above


# --- WHAT COMES OF IT ---------------------------------------------------------
#
# THE RESULT SEAM. One function, called once, by the broker, when an exchange
# resolves — never by the arc, never by a step, never by a brain. Nothing else
# in this folder may change the world on an exchange's behalf, for the same
# reason Inventory.hand_over is the ONE transfer path: a second door is a second
# place for a half-completed result to hide.
#
# THE DEFAULT IS NOT "NOTHING". Most results are the same shape — somebody comes
# away from this able to do something he could not do before — so that shape is
# the base behaviour and an author fills in two slots rather than writing a
# function. give.gd overrides this for goods and calls super(); ask.tscn does not
# override it at all and HAS NO SCRIPT OF ITS OWN, which is the whole test of
# whether this seam is generic: A NEW EXCHANGE SHOULD BE A .tscn, NOT A .gd.
#
# BOTH PARTIES, DELIBERATELY. An exchange is not a thing one man does to
# another — a bargain leaves each side holding something — and W3 is emphatic
# that neither participant is special. A result that could only land on the
# recipient would quietly make the initiator the privileged one, which is the
# same mistake as a field named `player`.
@export var lands_on_initiator: PackedScene
@export var lands_on_recipient: PackedScene

# WHAT IT DOES TO WHAT THEY THINK OF EACH OTHER. Two numbers, NOT one, and named
# for WHOSE BOOK the change is written in — `initiator_regard_change` moves the
# initiator's regard for the recipient.
#
# TWO BECAUSE AN EXCHANGE IS NOT SYMMETRIC. A greeting is (both men now know each
# other, equally), but a gift is emphatically not: being handed bread should move
# the receiver a great deal more than it moves the giver. One shared number would
# make every exchange in the game reciprocal by construction and delete the
# possibility of a man who is liked by somebody he cannot stand.
#
# ZERO IS A REAL VALUE AND STILL RECORDS THE MEETING — see Acquaintance.change.
@export var initiator_regard_change := 0.0
@export var recipient_regard_change := 0.0


func settle(initiator: Person, recipient: Person) -> void:
	# REGARD FIRST, so an outcome that wants to read it — a reply chosen by how
	# warmly he is thought of — finds this exchange already counted.
	Acquaintance.change(initiator, recipient, initiator_regard_change)
	Acquaintance.change(recipient, initiator, recipient_regard_change)
	land_on(lands_on_initiator, initiator)
	land_on(lands_on_recipient, recipient)


# Put an action in a man's repertoire because somebody asked him to. Public so
# an overriding settle() can land something conditionally without reimplementing
# the once-only rule below.
#
# STORED INTENT, AND THE NODE IS THE STORE. "Store nothing you can work out
# again" has a standing carve-out for exactly this — obligation.gd names itself
# FR101 stored intent: no amount of looking at the world tells you that this man
# AGREED to a thing, so it has to be remembered, and it is remembered as a node
# under his Brain, which is the same tree you would already read to see what he
# can do.
#
# LANDED ONCE PER KIND, NOT STACKED, and the reason is structural rather than
# tidiness: an Action holds NO per-instance progress, so a second identical node
# is indistinguishable from the first in every way that matters and does nothing
# but lengthen the ballot. Asking a man twice to fetch grain means MORE GRAIN,
# and that quantity is a fact about the world — his sack — not about how many
# copies of an intention he is carrying.
#
# IDENTITY IS THE SCENE, NOT THE SCRIPT: two errands authored as different .tscn
# files off the same base script are different errands, and that is precisely
# what a seam whose new verbs are scenes has to be able to tell apart.
func land_on(what: PackedScene, person: Person) -> Action:
	if what == null or person == null or person.brain == null:
		return null
	var already := find_landed(what, person)
	if already != null:
		return already
	return person.brain.learn(what)


# Is this already in his repertoire? Asked by walking what he knows rather than
# kept as a set somewhere, so it cannot disagree with the tree — the same shape
# as Person.get_obligations and Brain.reload_known_actions.
func find_landed(what: PackedScene, person: Person) -> Action:
	if what == null or person == null or person.brain == null:
		return null
	for action in person.brain.get_known_actions():
		if action.scene_file_path == what.resource_path:
			return action
	return null
