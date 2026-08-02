class_name ActionOption
extends RefCounted

# One thing the world offers an actor to do, defined entirely as data. The
# design rule: playstyle is data, not code — eligibility, appeal, and effect
# are all Callables supplied by a catalog (see sandbox/sandbox_catalog.gd),
# never behavior baked into this class. This file only carries the shape.

var id: StringName
var label: String          # shown while doing it, e.g. "working the field"
var place: StringName      # where it happens; the actor walks there first
var duration: float        # seconds of doing, once arrived

var appeal: Callable       # (store: StatStore, actor: Actor) -> float — the utility score
var eligible: Callable     # (store, actor) -> bool; unset = universally eligible
var effect: Callable       # (store, actor) -> void — applied once, when the doing finishes


static func make(id: StringName, label: String, place: StringName, duration: float) -> ActionOption:
	var option := ActionOption.new()
	option.id = id
	option.label = label
	option.place = place
	option.duration = duration
	return option


func scored_by(fn: Callable) -> ActionOption:
	appeal = fn
	return self


func only_if(fn: Callable) -> ActionOption:
	eligible = fn
	return self


func then(fn: Callable) -> ActionOption:
	effect = fn
	return self


# Left unset, eligible means universally eligible — the protected set: identity
# may never prune it. Only an explicit gate (only_if) can rule an actor out.
func can_attempt(store: StatStore, actor: Actor) -> bool:
	if not eligible.is_valid():
		return true
	return eligible.call(store, actor)


func score(store: StatStore, actor: Actor) -> float:
	assert(appeal.is_valid(), "ActionOption '%s' has no appeal set — scored_by() was never called" % id)
	return appeal.call(store, actor)


func finish(store: StatStore, actor: Actor) -> void:
	if effect.is_valid():
		effect.call(store, actor)
