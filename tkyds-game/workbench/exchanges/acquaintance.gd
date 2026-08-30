extends Node

# WHAT ONE MAN THINKS OF ANOTHER. A node under the person doing the thinking,
# naming the person thought about — the same shape `Obligation` already is, for
# the same reason and under the same carve-out.
#
# STORED INTENT, AND THERE IS NO ALTERNATIVE. "Store nothing you can work out
# again" is the standing rule, and obligation.gd names the exception it is
# written for (FR101): *"no amount of looking at the world tells you who this man
# agreed to work for, so it has to be remembered somewhere."* Regard is exactly
# that and more so — nothing about where a man stands, what he carries, or what
# the town has done says whether he has met you.
#
# THIS IS THE FIRST RELATIONAL NUMBER IN THE CODEBASE, and W9 is the record of
# why that matters: every gap in the game today is physiological (hunger,
# adenosine, social) or stock (the larder), and *"none is relational — none
# exists because somebody asked."* W9 names that absence as the thing blocking an
# errand from ever winning a ballot on its merits. It does not solve that here —
# nothing scores on warmth yet — but the number an eventual gap would be measured
# against now exists.
#
# ONE NODE PER SIDE, NOT ONE PER PAIR, AND THAT IS THE WHOLE DESIGN. Two people
# do not have to agree about each other. A lord may think well of a steward who
# despises him, and the steward's face will not say so — which is
# *illegible authorship* and *a perfect reader of a deliberately foggy world*
# pointed at one other person. A shared edge would make regard symmetric by
# construction and quietly delete that.
#
# NOT A CENTRAL GRAPH, for the reason `Town.find_people_at` loops people rather
# than Places keeping occupancy lists: one copy of the truth cannot contradict
# another. The graph is DERIVED by walking people, and there is nothing to keep
# in step.

# Who this is about. Read through is_instance_valid everywhere, per CLAUDE.md's
# standing rule — a freed man does not null your reference, and a dead
# acquaintance must not error the next thing that reads it.
var about: Person

# How warmly he is regarded, on one scale. 0 is "we have met and that is all",
# which is what a first greeting leaves behind — NOT "stranger". A stranger has
# no node at all, and that difference is the whole of what give and ask gate on.
#
# Negative is allowed and means what it sounds like. Nothing produces it yet.
var warmth := 0.0


# The duck-typed marker every lookup below matches on. No script under
# workbench/ takes a class_name (project-global, not worth burning on an
# experiment), so this is how a child is recognised as one of these.
func is_regard_for(person: Person) -> bool:
	return is_instance_valid(about) and about == person


# --- Finding it -------------------------------------------------------------
#
# Static, because these are questions about a person that no instance owns. They
# walk his children rather than consulting an index, exactly as
# Person.get_obligations and Brain.reload_known_actions do — one copy of the
# truth, in the tree you would already look in.

static func find(person: Person, about_person: Person) -> Node:
	if not is_instance_valid(person) or not is_instance_valid(about_person):
		return null
	for child in person.get_children():
		if child.has_method(&"is_regard_for") and child.call(&"is_regard_for", about_person):
			return child
	return null


# HAVE THEY MET AT ALL? The question with no number in it, kept separate from
# warmth on purpose: "we have never spoken" and "we have spoken and he thinks
# nothing much of me" are different facts, and folding them into a single number
# makes 0 mean both. Give and ask ask this one.
static func have_met(person: Person, about_person: Person) -> bool:
	return find(person, about_person) != null


static func get_warmth(person: Person, about_person: Person) -> float:
	var regard := find(person, about_person)
	if regard == null:
		return 0.0
	return regard.warmth


# Move it, making the record if this is the first time. THE ONE DOOR warmth
# changes through — same wall as Stats.get_stat and Inventory.get_count, and for
# the same reason: warmth is the most likely thing in this folder to be revisited
# (a decay, a ceiling, a cap on how fast it can move, a lens that scales it), and
# every one of those is a change to THIS function body with no caller moving.
#
# A CHANGE OF ZERO STILL MAKES THE RECORD, and that is deliberate rather than
# sloppy: meeting somebody is a fact even when it leaves you cold. An exchange
# that authored no warmth would otherwise leave two men who have demonstrably
# spoken still reading as strangers to every gate that asks.
static func change(person: Person, about_person: Person, by: float) -> Node:
	if not is_instance_valid(person) or not is_instance_valid(about_person):
		return null
	if person == about_person:
		push_warning("a man cannot be his own acquaintance — nothing recorded")
		return null
	var regard := find(person, about_person)
	if regard == null:
		regard = (load("res://workbench/exchanges/acquaintance.gd") as GDScript).new()
		regard.about = about_person
		regard.name = "Regard for %s" % about_person.person_name
		person.add_child(regard)
	regard.warmth += by
	return regard
