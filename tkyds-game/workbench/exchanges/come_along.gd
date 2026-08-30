extends Action

# BEING SOMEWHERE BECAUSE SOMEBODY CALLED YOU. The thing a beckon leaves behind,
# and the thing a follow leaves behind — the SAME action, differing by one
# authored flag, because "come here" and "stay with me" are the same behaviour
# with different stopping conditions.
#
# It is landed on a man by an exchange (see summon.gd), never learned by anyone
# at birth: nobody is born already following somebody.
#
# THE SUMMONER IS THE STORED INTENT, AND IT IS ALSO THE DISCHARGE. `summoner`
# holds who called him, because no amount of looking at the world tells you that
# — the FR101 carve-out again. And when a beckon is answered, THE FIELD IS
# CLEARED rather than a separate "done" flag being set: the gate below is
# "is somebody calling me", so forgetting who called is exactly what being
# finished means. One field, doing one job, with nothing to keep in step.
#
# A FOLLOW NEVER CLEARS IT, which is the whole of the difference.

# Does he stay with the man, or just go to him once? The one authored
# difference between a beckon and a follow.
@export var stays_with_him := false

# How close he gets before he stops, in metres. He walks to a point THIS FAR
# SHORT of the man rather than onto him — see come_along_step.gd, where the
# overshoot clamp lands him exactly on that point, so this is a stopping
# DISTANCE and never an arrival radius. Decision 10 forbids the second; this is
# not it.
@export var closes_to := 1.8

# What answering is worth to him. FLAT, and W9's Option A again — see
# work_the_ground.gd for the full argument about why that is a trap rather than
# a design.
#
# 100 IS CHOSEN AGAINST TWO SPECIFIC NUMBERS AND IS A DESIGN STATEMENT, NOT A
# FUDGE. StayUp peaks at 67.3 + 20 = 87.3 at noon, so a summons outranks going
# about your day at any hour — being called is not a thing you get round to.
# Eat reaches 130 at real hunger and Sleep climbs past this on real exhaustion,
# so a starving or spent man still refuses you, and refuses you by being outbid
# rather than by being barred. That is the shape the whole design wants: he
# comes when you call unless he genuinely cannot.
@export var pull := 100.0

# Who called. Set by the exchange that landed this, read through
# is_instance_valid everywhere — a summoner who was freed must end the summons,
# not error the next thing that reads him.
var summoner: Person


# Is anybody still calling him? Null means nobody — either it was never set, or
# a beckon was answered and cleared it. Both are the same fact and read the same.
func is_available_to(person: Person) -> bool:
	if not is_instance_valid(summoner):
		return false
	return person.brain.is_awake()


func get_utility_score(_person: Person) -> float:
	return pull
