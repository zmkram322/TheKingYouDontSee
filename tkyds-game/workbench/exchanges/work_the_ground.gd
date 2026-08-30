extends Action

# AN ERRAND SOMEBODY WAS ASKED TO RUN. This is what an exchange leaves behind:
# not a flag, not an entry in a list somewhere, but a node in his Brain that was
# not there this morning. He can be seen doing it, he can be outbid off it, and
# nothing about him needed to know that exchanges exist for it to arrive.
#
# STORED INTENT, AND THE NODE IS THE STORE — the FR101 carve-out obligation.gd
# already names. No amount of looking at the world tells you that this man
# agreed to work the ground; it has to be remembered, and it is remembered in
# exactly the tree you would already read to see what he can do.
#
# IT COSTS HIM SOMETHING REAL, which is the part that stops this being a
# decoration. The step's `exertion` is 1.6, so an asked man tires faster than an
# idle one and goes to bed earlier — a measurable consequence of a conversation,
# through machinery that existed before exchanges did and needed no wire.
#
# ------------------------------------------------------------------------------
# THIS SCORE IS W9's OPTION A, AND OPTION A IS THE TRAP. READ BEFORE COPYING IT.
#
# W9 in DECISIONS.md rules on where an errand lands and how it ever gets done,
# and it closes the obvious answer: WorkForHire scores an obligation's weight
# against a BINARY gap (employed today or not, Decision 31), so work's want is
# FLAT ALL DAY AND NEVER GETS QUIETER. An errand cannot win by patience the way
# a gap-driven want does — it has to out-score work outright and permanently, or
# never fire at all. W9's recommendation is C + D: a Condition that suppresses
# the other drives, paced by a gap that grows toward a deadline. NEITHER IS
# BUILT — Condition does not exist anywhere in the codebase (Decision 36
# specifies it; nothing implements it).
#
# So this errand is authored the fragile way ON PURPOSE, and the workbench is
# where that is cheap. The three people in exchanges.tscn carry no Obligation
# and no WorkForHire, so a flat 75 genuinely wins their idle hours and you can
# WATCH the outcome land from across the field. Put this same number in a town
# where men are employed and it is a hand-tuned fight against 73 + daylight that
# has to be re-fought every time a drive is added. That is the failure W9
# describes, and this file is where you will be standing when you meet it.
# ------------------------------------------------------------------------------

# What it is worth to him to do as he was asked. FLAT — no gap, no bite, and
# that absence is the whole of the paragraph above. W5 says an exchange result
# moves `weight`; W9 records the other half nobody has answered, which is that
# `want = weight x gap^bite` and AN ERRAND HAS NO GAP. Every gap in the game
# today is physiological (hunger, adenosine, social) or stock (the larder); none
# is relational, none exists because somebody asked.
#
# 75.0 sits deliberately between the numbers already authored: above StayUp's
# 67.3 + 20 x sun at low sun, below Socialise's 90 at real loneliness and well
# below Eat's 130 at real hunger. So an asked man works his idle hours and still
# eats, still sleeps, still seeks company — outbid, never barred.
@export var pull := 75.0


func get_utility_score(_person: Person) -> float:
	return pull
