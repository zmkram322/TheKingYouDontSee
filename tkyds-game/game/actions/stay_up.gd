class_name StayUp
extends Action

# Be up and about. Nothing in particular — this is the placeholder every other
# waking action will eventually outbid, and for now it's the only thing
# competing with sleep while he's awake.
#
# It is also, quietly, half of the sleep cycle. Sleep wants exactly as much as
# his adenosine, so it beats this the moment adenosine climbs past whatever this
# is worth right now — which makes the number below literally "how tired he gets
# before he turns in", readable rather than buried in a curve.
#
# The other half is in wake.gd, and the gap between the two is the point: he
# falls asleep high and doesn't get up until low, so there's a wide band between
# "start sleeping" and "stop sleeping" instead of one line to sit on and jitter
# across. That gap is why the brain can re-decide every single tick without
# flickering, and it's the biology doing the work — you don't wake the instant
# you're a shade less tired than when you dropped off.
#
# THE SUN IS THE OTHER INPUT, and it is what stops the cycle wandering. Without
# it the body runs on adenosine alone, the round trip comes to whatever the two
# rates happen to add up to, and if that isn't exactly 24 hours the whole
# schedule walks around the clock — measured at 19.6 hours, so bedtime slid 4.4
# hours earlier every day and he was asleep at nine in the morning by day two.
# Tuning the rates to sum to 24 would fix the PERIOD and not the PHASE: there
# would be no force pulling him back, so one late night would move him
# permanently. Being up is simply worth more while the sun is up, so the same
# tiredness that puts him to bed at ten at night doesn't quite manage it at ten
# in the morning, and a disturbed night corrects itself over the following days.
# That is what a circadian rhythm actually is — a bias, not a timetable.
#
# IT IS A SCORE TERM AND NEVER A GATE. "Can't sleep during the day" would bar an
# exhausted man from sleeping, which is the same barring mistake as a radius
# around a tavern wearing different clothes. Keep the daylight peak below the
# adenosine ceiling and a man kept up for thirty hours WILL drop at noon — he is
# outbid, never barred.

# Sleep wins once adenosine climbs past what being up is worth. This is that
# worth at dawn and dusk, when the sun is level with the horizon.
@export var pull := 67.3

# Added to it at midday and taken off it at midnight, following the sun. This is
# the whole anchor: the bigger it is, the more firmly bedtime holds its hour and
# the harder it is to sleep through the afternoon.
@export var daylight_pull := 20.0


func is_available_to(person: Person) -> bool:
	return person.brain.is_awake()


func get_utility_score(person: Person) -> float:
	return pull + daylight_pull * person.get_sun_height()
