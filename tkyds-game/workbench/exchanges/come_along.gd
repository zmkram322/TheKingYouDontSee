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

# HOW HARD HE HURRIES, as a multiple of his own walk. He does not have one
# speed and a decision about when to use it: his pace comes off HOW FAR BEHIND
# HE IS, ramping from a standstill at `closes_to` to this cap once he has fallen
# `catches_up_over` metres further back than that.
#
# THAT IS WHY NOTHING HERE SAYS "IF THE MAN RUNS, RUN." A leader who breaks into
# a run opens the gap, the gap sets the pace, the pace pushes him past his own
# walk, and Person._show_the_body — reading nothing but how much ground he
# covered — puts him in a run clip. Walk away and the same loop settles him back
# into a walk. One number, no state, and no file asking what anybody is doing.
#
# 2.6 IS CHOSEN AGAINST THE PLAYER'S SPRINT, not picked for feel: exchange_brain
# runs him at 5.5 m/s against a walk of 2.2, so a follower capped below 2.5x
# could never close on a sprinting man and would trail further and further back
# for ever. Above it, he settles at a fixed distance and holds it.
@export var hurries_up_to := 2.6

# Over how many metres past `closes_to` he goes from a standstill to that cap.
# Short on purpose. A long ramp is a man creeping the last stretch at a pace too
# slow to read as walking — gliding, which is what this whole pair replaced.
@export var catches_up_over := 0.8

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


# How fast he should be moving, given how far back he is — see `hurries_up_to`.
# A pure function of the gap, asked fresh every tick, remembering nothing: this
# is the whole of "he keeps up", and it is why he neither stutters at the edge
# of a threshold nor needs to be told what the man in front of him is doing.
func get_pace(gap: float) -> float:
	if catches_up_over <= 0.0:
		return hurries_up_to
	return clampf((gap - closes_to) / catches_up_over, 0.0, hurries_up_to)


# Is he out of position on THIS man's account — following him, and not yet back
# at his shoulder? Asked by the arc, which draws nothing over a man who is
# hurrying to catch you up: an overlay bobbing along behind your own back is
# clutter, and there is nothing you could usefully press at him mid-stride
# anyway. Stand still, he settles beside you, and his verbs come back.
#
# BOTH HALVES MATTER. A man hurrying to somebody ELSE is still somebody you can
# address, so this asks who called him and not merely whether he is moving.
func is_catching_up_to(person: Person, leader: Person) -> bool:
	if not is_instance_valid(summoner) or summoner != leader:
		return false
	var toward := summoner.global_position - person.global_position
	toward.y = 0.0
	return toward.length() > closes_to


# CALLED OFF. Forgetting who called him is exactly what being finished means —
# the gate above is "is somebody calling me" — so this is the same one line the
# arrival already uses, given a name and a second caller. Nothing else has to
# change and there is still no "done" flag to keep in step with anything.
func discharge() -> void:
	summoner = null
