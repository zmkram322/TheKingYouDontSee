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

# AND EVERYTHING ELSE WORTH LOOKING AT. A basket, a barrel, a cart — anything
# with a body in the world that a verb might be aimed at.
#
# Array[NodePath] AND NOT Array[Node3D], and that is not a style choice:
# CLAUDE.md records that `@export var x: Array[Node]` does not resolve its paths
# at all, even with node_paths, and loads as a list of nulls in silence. The
# documented answer is NodePath plus get_node_or_null, which is what _ready does.
#
# LISTED RATHER THAN SCANNED. A group or a "find everything with an inventory"
# sweep would make what is addressable depend on what happens to exist, which is
# how a scene grows a target nobody meant to add. This is a workbench; naming the
# three things in it is honest and takes a line each.
@export var things: Array[NodePath] = []

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
var _things: Array[Node3D] = []
var _looked_at: Node3D


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
	for path in things:
		var thing := get_node_or_null(path) as Node3D
		if thing == null:
			push_warning("LookingAt was given a path to nothing: %s" % path)
			continue
		_things.append(thing)


func _process(_delta: float) -> void:
	_looked_at = _find_who_is_looked_at()


# Null is a real answer and means "nobody" — the arc draws nothing, which is
# the honest picture rather than a stale target left up from last frame.
func get_looked_at() -> Node3D:
	if not is_instance_valid(_looked_at):
		_looked_at = null
	return _looked_at


# PEOPLE AND THINGS RANKED TOGETHER, ON ONE COST. A basket standing in front of a
# man wins the arc, and stepping past it hands the arc back to him — which is the
# behaviour you would want and the behaviour you get for free, because both go
# through the same comparison. Two separate searches with a tie-break between
# them would need a rule about which kind wins, and there is no honest one.
func _find_who_is_looked_at() -> Node3D:
	if _eye == null:
		return null
	var from := _eye.global_position
	var facing := -_eye.global_transform.basis.z
	var best: Node3D = null
	var best_cost := INF

	var candidates: Array[Node3D] = []
	if _crowd != null:
		for person in _crowd.get_people():
			candidates.append(person)
	candidates.append_array(_things)

	for thing in candidates:
		if thing == _looker or not is_instance_valid(thing):
			continue
		# Aimed at faces for a man, and at the middle of the thing for a basket —
		# which is what head_height already is, applied to a thing that is not as
		# tall. Close enough for a workbench, and the alternative is a per-target
		# height nobody would tune.
		var lift := head_height if thing is Person else 0.0
		var toward := thing.global_position + Vector3.UP * lift - from
		var reach := toward.length()
		if reach > within_reach or reach <= 0.0:
			continue
		var off_centre := rad_to_deg(facing.angle_to(toward))
		if off_centre > within_degrees:
			continue
		var cost := off_centre + reach * distance_costs
		if cost < best_cost:
			best_cost = cost
			best = thing
	return best
