extends Person

# A Person whose body reads its own physics instead of the world clock.
#
# extends, NOT A COPY, and the reason is measurable rather than stylistic:
# `Person` is a declared type in 83 places across 27 files — Action.
# is_available_to, ActionStep.advance, DecisionEngine, Town.find_people_at,
# Workstation, and every action in the library. A body that is not a Person
# cannot enter any of it. A forked copy of person.gd would have been a dead
# end wearing the shape of a head start. Subclassing keeps the whole substrate
# underneath and makes the eventual port back into game/ a diff against one
# named function instead of a merge between two files that have drifted apart
# for a month.
#
# WHAT DIVERGES, AND WHY IT HAS TO. person.gd answers "is he moving" from
# _speed, which is displacement measured across the brain's tick in world
# hours — and that measurement happens inside Person.think_and_act, which only
# Population ever calls. This scene has no Population, so _speed is 0.0
# forever and the inherited _show_the_body would play `idle` at a dead sprint.
# This one reads the physics velocity exchange_brain.gd actually set.
#
# THE OPEN QUESTION THAT POSES is the interesting half, and it is for the
# author, not for this file: whether game/ should measure the same way.
# Displacement-over-hours is what lets sleep.tscn say `sleep` unconditionally
# and still show a man walking to his bed, and velocity would do that too —
# IF anything in game/ set velocity. Nothing does; Decision 4 is why.

# The four locomotion clips person.gd has no slot for. `resting_clip` and
# `walking_clip` are inherited and still mean exactly what they meant. All six
# are clip names and none is a verb — nothing here asks WHY he is moving, the
# same rule that keeps a dictionary from action to animation out of game/.
@export var running_clip := &"run"
@export var rising_clip := &"jump"
@export var falling_clip := &"jump_down"
@export var running_jump_clip := &"run_jump"

# METRES PER SECOND, unlike the inherited `walking_above`, which is a FRACTION
# of a person's own travel speed in units per world hour. Two different
# quantities that are deliberately not reconciled here — reconciling them is
# part of what porting this back has to answer, and doing it early would hide
# the question.
@export var walks_above := 0.15
@export var runs_above := 3.2


# Every clip checked once, loudly, at birth. The inherited version knows about
# two of the six. A missing clip is a wiring fault that should be said once and
# clearly, not sixty times a second into a log nobody can read — which is why
# _play below stays silent about it.
func _start_the_body() -> void:
	if _animation == null:
		push_warning("%s has no AnimationPlayer under his Body — he will stand in his bind pose" % person_name)
		return
	for clip_name in [resting_clip, walking_clip, running_clip,
			rising_clip, falling_clip, running_jump_clip]:
		if not _animation.has_animation(clip_name):
			push_warning("%s has no \"%s\" clip — his body cannot show it" % [person_name, clip_name])
	_play(resting_clip)


# person.gd's two layers become three, and the new one goes on TOP rather than
# beside: airborne beats travel, travel beats whatever the step declared.
# A man falling is not doing anything else, whatever he had chosen — the same
# argument person.gd makes for travel beating the declared clip, one storey up.
func _show_the_body() -> void:
	if _animation == null or _body == null:
		return
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var speed := flat.length()

	# Turn the BODY, never the man — person.gd's rule, kept for its own reason
	# (global_position is what every gate and every distance reads, and his own
	# rotation means nothing at all) and now for a second one: the camera rig
	# hangs off the man, so rotating him would drag the view around by his
	# shoulders every time he changed direction.
	if speed > walks_above:
		_body.rotation.y = atan2(flat.x, flat.z)

	if not is_on_floor():
		if speed >= runs_above:
			_play(running_jump_clip)
		elif velocity.y > 0.0:
			_play(rising_clip)
		else:
			_play(falling_clip)
		return

	if speed >= runs_above:
		_play(running_clip)
		return
	if speed >= walks_above:
		_play(walking_clip)
		return

	# Grounded and still: whatever his step says he is doing, decided exactly
	# as person.gd decides it and reached through the same accessor — so a step
	# that declares a clip still shows it here, and this override costs the
	# substrate underneath nothing.
	var doing: StringName = brain.get_clip() if brain != null else &""
	_play(resting_clip if doing.is_empty() else doing)

# KNOWN, AND NOT WORTH A BLEND TREE YET: `jump`, `jump_down` and `run_jump`
# import as LOOP_NONE (see assets/mixamo/mixamo_import.gd), so a long fall
# plays its clip once and then holds the last pose. Note it when watching; do
# not build a state machine to fix it until a fall is long enough to look wrong.
