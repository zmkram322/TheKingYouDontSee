class_name Daylight
extends DirectionalLight3D

# The sun, and the whole of "can I see that it's night?". Reads the Clock and
# nothing else; never writes to it. One full arc per day, driven straight off
# time_of_day() so there is no second schedule that can drift out of step with
# the first.
#
# Three things move together, because only one of them alone actually reads as
# night. The sun's ANGLE gives the long shadows and the direction light comes
# from. Its ENERGY AND COLOUR give the warm low sun at dawn and dusk and the
# flat white overhead at midday. And the environment's AMBIENT AND SKY are the
# ones that genuinely make it dark — without dimming those, a scene at
# midnight still sits in full flat daylight with the sun merely pointing the
# wrong way.
#
# Every number below is an export rather than a constant, so all of it is
# reachable from the tuning board later without this file changing.

# Dragged in from the inspector rather than found by path, so moving either
# node doesn't silently break the link — Godot repoints the reference for you.
@export var clock: Clock
@export var environment: WorldEnvironment

@export_group("Sun")
# How bright the sun gets at its highest, and what's left of it at midnight.
# The floor is not zero on purpose: a pitch-black scene is unreadable rather
# than atmospheric, and moonlight is the honest excuse.
@export var noon_energy := 1.15
@export var midnight_energy := 0.10
# The colour it warms toward when it's low in the sky. Full white overhead.
@export var horizon_tint := Color(1.0, 0.72, 0.45)
# A little yaw so light doesn't come dead-on down an axis, which flattens
# everything it lands on.
@export_range(-180.0, 180.0, 1.0) var sun_heading_degrees := -35.0

@export_group("Sky and ambient")
@export var day_sky := Color(0.55, 0.68, 0.78)
@export var night_sky := Color(0.04, 0.05, 0.10)
@export var day_ambient := 0.60
@export var night_ambient := 0.08


# Says so out loud if it was never wired up. Without this the sun simply never
# moves and nothing anywhere complains — which is exactly what happened, and it
# survived two atoms and a commit before anyone noticed. A guard that turns a
# broken link into silence is worse than no guard.
#
# Note for whoever wires this in a .tscn by hand: a node reference needs
# `node_paths=PackedStringArray("clock", "environment")` on the node's own
# header line, or the loader assigns the raw NodePath to a typed field and you
# get null. The editor writes that for you; hand-written scenes don't.
func _ready() -> void:
	if clock == null:
		push_warning("Daylight has no Clock — the sun will not move")
	if environment == null:
		push_warning("Daylight has no WorldEnvironment — the sky and ambient will not change")


func _process(_delta: float) -> void:
	if clock == null:
		return
	# -1 at midnight, 0 at dawn and dusk, +1 at midday. Everything below is a
	# function of this one number, which is why the sky, the sun and the
	# ambient can never disagree about what time it is.
	#
	# Asked of the Clock rather than worked out here, because the BODY reads it
	# too now — being up is worth more while the sun is up. Two sines would
	# agree today and part company the first time one of them changed.
	var height := clock.get_sun_height()
	_aim_sun(height)
	_light_the_sky(height)


# The sun sweeps a full circle each day: level with the horizon at dawn,
# straight down at midday, level again at dusk, and under the world at night.
func _aim_sun(height: float) -> void:
	rotation.x = -(clock.time_of_day() - 0.25) * TAU
	rotation.y = deg_to_rad(sun_heading_degrees)

	# Above the horizon only. Below it the sun is off, and what light there is
	# comes from the ambient floor instead.
	var above := maxf(height, 0.0)
	light_energy = lerpf(midnight_energy, noon_energy, above)
	# Warmest when the sun is lowest, so dawn and dusk get their colour and
	# midday stays white. Only applied while it's up; the tint of a sun nobody
	# can see is wasted.
	light_color = Color.WHITE.lerp(horizon_tint, 1.0 - above)


# What actually sells the darkness. `height` is remapped from -1..+1 into
# 0..1 so the sky and ambient keep fading through the night rather than
# bottoming out the moment the sun sets.
func _light_the_sky(height: float) -> void:
	if environment == null or environment.environment == null:
		return
	var brightness := (height + 1.0) * 0.5
	var settings := environment.environment
	settings.background_color = night_sky.lerp(day_sky, brightness)
	settings.ambient_light_color = settings.background_color
	settings.ambient_light_energy = lerpf(night_ambient, day_ambient, brightness)
