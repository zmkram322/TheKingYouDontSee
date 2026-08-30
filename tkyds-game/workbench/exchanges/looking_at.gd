extends Node

# Who the player is looking at. One question, asked once a frame, answered for
# anybody who wants it — the arc reads it, and whatever comes after the arc
# reads the same answer rather than working it out a second way.
#
# GATE, THEN RANK — the substrate's own shape, pointed at targets instead of
# verbs. DecisionEngine keeps two halves strictly apart ("get_available never
# scores, get_highest_scoring never gates") and the same split is what makes
# this forgiving with one man in front of you and precise with six:
#
#   GATE   a generous cone and a reach. Cheap, and it never changes.
#   RANK   nearest to the centre of view wins, distance breaking near-ties.
#
# THAT IS WHY THERE IS NO CROWD-SIZE TERM. Tightening a threshold as people
# arrive would need a curve authored against a head count and retuned every
# time the scene changed. Ranking gives the same felt behaviour for free: alone,
# a man wins from anywhere inside the cone because nobody is beating him; in a
# crowd, only the one you are actually pointing at wins.
#
# ASKED IN _process, WHICH IS THE RIGHT PHASE. Physics has already moved
# everybody by the time this runs, and the camera's angle was set at event time
# before that, so this reads a settled world rather than a half-stepped one.

# The eye. Not the player's body — where he is LOOKING is a fact about the
# camera, and taking it from the body would make the arc appear behind him
# whenever he turned the view without turning his feet.
@export var eye: Camera3D

# Whose view it is, so he cannot be his own target.
@export var looker: Person

# Everybody who could be looked at. Read through Population rather than a
# group or a scan, for the same reason Population drives thinking: one place
# that knows who is alive.
@export var crowd: Population

# The GATE. Generous on purpose — see the header. Half-angle, in degrees.
@export var within_degrees := 35.0

# How far a man can be and still be addressable, in metres.
@export var within_reach := 12.0

# How much being far away costs, in degrees of apparent angle per metre. Small:
# it is here to break a near-tie between two men at the same angle, never to
# override which one you are actually pointing at.
@export var distance_costs := 0.6

# Where a man's head is, so the cone is aimed at faces rather than at ankles.
@export var head_height := 1.6

var _eye: Camera3D
var _looker: Person
var _crowd: Population
var _looked_at: Person


func _ready() -> void:
	_eye = eye
	_looker = looker
	_crowd = crowd
	if _eye == null:
		push_warning("LookingAt has no Camera3D — nobody will ever be looked at")
	if _looker == null:
		push_warning("LookingAt has no looker — he will be able to address himself")
	if _crowd == null:
		push_warning("LookingAt has no Population — there is nobody to look at")


func _process(_delta: float) -> void:
	_looked_at = _find_who_is_looked_at()


# Null is a real answer and means "nobody" — the arc draws nothing, which is
# the honest picture rather than a stale target left up from last frame.
func get_looked_at() -> Person:
	if not is_instance_valid(_looked_at):
		_looked_at = null
	return _looked_at


func _find_who_is_looked_at() -> Person:
	if _eye == null or _crowd == null:
		return null
	var from := _eye.global_position
	var facing := -_eye.global_transform.basis.z
	var best: Person = null
	var best_cost := INF
	for person in _crowd.get_people():
		if person == _looker or not is_instance_valid(person):
			continue
		var toward := person.global_position + Vector3.UP * head_height - from
		var reach := toward.length()
		if reach > within_reach or reach <= 0.0:
			continue
		var off_centre := rad_to_deg(facing.angle_to(toward))
		if off_centre > within_degrees:
			continue
		var cost := off_centre + reach * distance_costs
		if cost < best_cost:
			best_cost = cost
			best = person
	return best
