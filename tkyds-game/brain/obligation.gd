class_name Obligation
extends Action

# A discrete piece of work handed to a subject from outside — an order taken,
# an errand given. It is an ordinary Action in every way that matters: it goes
# into the same candidate set, is gated by the same predicate, ranked by the
# same curve, and can lose to an ordinary need without anything granting it or
# the need special status.
#
# What it adds is a way to be recognised. An Action is a label and two
# anonymous callables, so the only way to find one again is to have kept hold
# of it. That works while the same code both creates the work and hands it
# over, and breaks the moment work is generated for someone else: you cannot
# cancel, expire, or avoid duplicating an obligation you never kept a pointer
# to.
#
# `about` is what makes it recognisable — a key naming the work rather than the
# instance of it. Two obligations about the same thing are the same obligation
# asked twice. That is what lets whoever emits work ask "is this already owed?"
# by looking at the world, instead of remembering that they asked — which would
# be exactly the stored intention everything else here avoids.

var asked_by                # who wanted it; opaque, and may be nobody
var about: StringName       # what the work is, for matching — not the label
var taken_on: float         # when it was taken on, by whatever clock the world keeps

# The condition that justified taking this on, re-checked against the world
# each time it's asked — not remembered, asked. An obligation is not owed
# forever just because nobody got around to cancelling it: FR103 requires
# that it lapse on its own once the thing it was for stops being true, the
# same way a need lapses once the stat behind it is satisfied. Closes over
# whatever world-fact it depends on; this file stays as ignorant of what
# that fact IS as it already is of what the work itself is. Left unset, an
# obligation is assumed always wanted — most are justified by nothing more
# than having been asked, and an order never lapses on its own just because
# time passed.
var still_wanted: Callable  # () -> bool


func _init(new_label: String, new_eligible: Callable, new_score: Callable, new_body: Step,
		new_about: StringName = &"", new_asked_by = null, new_taken_on: float = 0.0,
		new_still_wanted: Callable = Callable()) -> void:
	super(new_label, new_eligible, new_score, new_body)
	about = new_about if new_about != &"" else StringName(new_label)
	asked_by = new_asked_by
	taken_on = new_taken_on
	still_wanted = new_still_wanted


# Is the condition that justified this still true? The world's own sweep
# asks this of every outstanding obligation each tick, never the obligation
# itself — nothing here decides when it's checked, only what the answer is.
func is_still_wanted() -> bool:
	if not still_wanted.is_valid():
		return true
	return still_wanted.call()
