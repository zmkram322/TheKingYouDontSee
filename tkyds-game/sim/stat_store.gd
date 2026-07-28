class_name StatStore
extends RefCounted

# The single wall between simulation logic and stat storage.
# Every read or write of an actor stat or relationship stat goes through
# get_primary / write_primary / get_derived — nothing else touches storage.
# Backing is a humble Dictionary today; call sites never learn if that changes.
#
# Two scopes share the same three methods:
#   actor stat         get_primary(a, stat)
#   relationship stat  get_primary(a, stat, b)   — the a→b edge
#
# Storage is sparse: an unset stat falls back to a per-stat default, so only
# deviations allocate. (Faction-level defaults would slot in at the fallback
# point when factions exist; today the default is global.)
#
# Derived stats are recomputed on read and cached against the version stamps
# of every primary they touched — captured automatically while the derivation
# runs — so they are never stale and never recomputed when nothing they read
# has changed.

var _actor_stats := {}     # actor id -> {stat: value}
var _edge_stats := {}      # Vector2i(from id, to id) -> {stat: value}
var _versions := {}        # storage key -> write count
var _actor_defaults := {}  # stat -> value when unset
var _edge_defaults := {}   # stat -> value when unset
var _derivations := {}     # stat -> Callable(store, a, b) -> value
var _derived_cache := {}   # stat -> {Vector2i(a id, b id or 0): {value, deps}}
var _capture_stack: Array[Dictionary] = []
var _next_id := 1


func register(a: Actor) -> void:
	a.id = _next_id
	_next_id += 1


func set_actor_default(stat: StringName, value: Variant) -> void:
	_actor_defaults[stat] = value


func set_edge_default(stat: StringName, value: Variant) -> void:
	_edge_defaults[stat] = value


# fn is Callable(store: StatStore, a: Actor, b: Actor) -> Variant.
func define_derived(stat: StringName, fn: Callable) -> void:
	_derivations[stat] = fn


func get_primary(a: Actor, stat: StringName, b: Actor = null) -> Variant:
	var key: Variant = _key(a, b)
	if not _capture_stack.is_empty():
		_capture_stack[-1][key] = _versions.get(key, 0)
	var table: Dictionary = _edge_stats if b != null else _actor_stats
	var bucket: Dictionary = table.get(key, {})
	if bucket.has(stat):
		return bucket[stat]
	var defaults: Dictionary = _edge_defaults if b != null else _actor_defaults
	assert(defaults.has(stat), "No default registered for stat '%s'" % stat)
	return defaults.get(stat)


func write_primary(a: Actor, stat: StringName, value: Variant, b: Actor = null) -> void:
	var key: Variant = _key(a, b)
	var table: Dictionary = _edge_stats if b != null else _actor_stats
	var bucket: Dictionary = table.get(key, {})
	var defaults: Dictionary = _edge_defaults if b != null else _actor_defaults
	var current: Variant = bucket[stat] if bucket.has(stat) else defaults.get(stat)
	if current == value:
		return
	if not table.has(key):
		table[key] = bucket
	bucket[stat] = value
	_versions[key] = _versions.get(key, 0) + 1


func get_derived(a: Actor, stat: StringName, b: Actor = null) -> Variant:
	assert(_derivations.has(stat), "No derivation registered for stat '%s'" % stat)
	var ckey := Vector2i(a.id, b.id if b != null else 0)
	var cache: Dictionary = _derived_cache.get(stat, {})
	if cache.has(ckey):
		var entry: Dictionary = cache[ckey]
		if _deps_fresh(entry.deps):
			if not _capture_stack.is_empty():
				_capture_stack[-1].merge(entry.deps, true)
			return entry.value
	_capture_stack.append({})
	var fn: Callable = _derivations[stat]
	var value: Variant = fn.call(self, a, b)
	var deps: Dictionary = _capture_stack.pop_back()
	if not _derived_cache.has(stat):
		_derived_cache[stat] = {}
	_derived_cache[stat][ckey] = {"value": value, "deps": deps}
	if not _capture_stack.is_empty():
		_capture_stack[-1].merge(deps, true)
	return value


func _deps_fresh(deps: Dictionary) -> bool:
	for key: Variant in deps:
		if _versions.get(key, 0) != deps[key]:
			return false
	return true


func _key(a: Actor, b: Actor) -> Variant:
	return a.id if b == null else Vector2i(a.id, b.id)
