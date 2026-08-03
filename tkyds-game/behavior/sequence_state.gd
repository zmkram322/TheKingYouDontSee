class_name SequenceState
extends State

# The one composite in the hierarchy: runs its children in order, and is
# finished once the last one is. A child can itself be a SequenceState —
# nesting is free, no extra code — so this is the single mechanism for
# "do this, then this" at any depth, replacing what used to be a flat
# Goal.plan array on one side and a hand-rolled phase match-statement on the
# other for exactly the same job.

var children: Array[State] = []
var _index := 0


func begin() -> void:
	_index = 0
	if not children.is_empty():
		children[0].begin()


# Chains through as many already-finished children as exist in one frame
# (a zero-duration WalkTo that's already at its target, say) instead of
# wasting a frame per instant transition — each freshly-begun child still
# gets its own advance() call this same frame, same as a single-step Goal
# always did.
func advance(delta: float) -> void:
	while _index < children.size():
		var current := children[_index]
		current.advance(delta)
		if not current.finished:
			return
		_index += 1
		if _index < children.size():
			children[_index].begin()
	finished = true


func describe() -> String:
	if _index < children.size():
		return children[_index].describe()
	return ""


func describe_all() -> Array[String]:
	var parts: Array[String] = []
	for i in range(_index, children.size()):
		parts.append_array(children[i].describe_all())
	return parts
