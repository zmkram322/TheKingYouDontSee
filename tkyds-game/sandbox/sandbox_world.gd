class_name SandboxWorld
extends RefCounted

# The behavior sandbox's engine, fully headless — the scene is a skin over
# it, same split as Simulation/main.gd. advance(delta) is the only mover:
# it drifts needs, lets the utility brain pick when an actor's plan runs dry,
# and steps whatever Activity is currently running. Nothing here names a
# specific behavior; the four example actions live only in
# sandbox/sandbox_catalog.gd.

var stats: StatStore
var villagers: Array[Villager] = []
var options: Array[ActionOption] = []
var places := {}          # StringName -> Vector2
var log_lines: Array[String] = []
var time := 0.0            # seconds of sandbox time elapsed


func reset() -> void:
	time = 0.0
	log_lines.clear()
	villagers.clear()

	places = {
		&"home": Vector2(120, 420),
		&"field": Vector2(620, 140),
		&"inn": Vector2(620, 420),
		&"well": Vector2(370, 280),
	}

	stats = StatStore.new()
	stats.set_actor_default(Stat.HUNGER, 0.0)
	stats.set_actor_default(Stat.ENERGY, SandboxTune.ENERGY_MAX)
	stats.set_actor_default(Stat.COIN, 0)
	stats.set_actor_default(Stat.PLACE, &"well")
	stats.define_derived(Stat.VIGOR, _derive_vigor)

	options = SandboxCatalog.build()

	# Five staggered starting states so the loop visibly demonstrates five
	# different first choices at once. Each comment says which need wins, and
	# why — including the one gated by eligibility rather than the score.

	var berta := _spawn("Berta", places[&"well"])
	stats.write_primary(berta.actor, Stat.HUNGER, 70.0)
	stats.write_primary(berta.actor, Stat.COIN, 12)
	# Hungriest body in the yard, and can afford a meal → beelines the inn.

	var cole := _spawn("Cole", places[&"home"])
	stats.write_primary(cole.actor, Stat.HUNGER, 45.0)
	stats.write_primary(cole.actor, Stat.COIN, 0)
	# Wants to eat but can't afford it: eat_at_inn's possession gate prunes
	# it before scoring even runs, so work is what's left standing. The gate
	# made visible.

	var dara := _spawn("Dara", places[&"field"])
	stats.write_primary(dara.actor, Stat.ENERGY, 12.0)
	stats.write_primary(dara.actor, Stat.COIN, 8)
	# Nearly spent → drags himself home to rest.

	var edmun := _spawn("Edmun", places[&"inn"])
	stats.write_primary(edmun.actor, Stat.COIN, 30)
	stats.write_primary(edmun.actor, Stat.HUNGER, 10.0)
	# Nothing presses yet: the well, until hunger grows enough to outbid it.

	var fen := _spawn("Fen", Vector2(400, 300))
	stats.write_primary(fen.actor, Stat.HUNGER, 30.0)
	stats.write_primary(fen.actor, Stat.COIN, 6)
	stats.write_primary(fen.actor, Stat.ENERGY, 60.0)
	# Mid-everything — the first to flip between needs as the others settle.

	_log("Sandbox seeded: %d villagers, %d places, %d actions in the catalog." % [villagers.size(), places.size(), options.size()])


func _spawn(person_name: String, position: Vector2) -> Villager:
	var a := Actor.new(person_name)
	stats.register(a)
	var v := Villager.new(a, position)
	villagers.append(v)
	return v


func _derive_vigor(store: StatStore, a: Actor, _b: Actor) -> float:
	var energy: float = store.get_primary(a, Stat.ENERGY)
	var hunger: float = store.get_primary(a, Stat.HUNGER)
	return clampf((energy - 0.5 * hunger) / SandboxTune.ENERGY_MAX, 0.0, 1.0)


# --- The step -----------------------------------------------------------

func advance(delta: float) -> void:
	time += delta

	# Ambient drift, through the store, so derived caches (VIGOR) invalidate
	# honestly rather than going stale under a doing actor's feet.
	for v in villagers:
		var hunger: float = stats.get_primary(v.actor, Stat.HUNGER)
		stats.write_primary(v.actor, Stat.HUNGER, minf(SandboxTune.HUNGER_MAX, hunger + SandboxTune.HUNGER_PER_SECOND * delta))
		var energy: float = stats.get_primary(v.actor, Stat.ENERGY)
		stats.write_primary(v.actor, Stat.ENERGY, maxf(0.0, energy - SandboxTune.ENERGY_DRIFT_PER_SECOND * delta))

	for v in villagers:
		# Commitment rule: a decision sticks until its activities finish —
		# rescoring happens only at the seam between plans. Flicker, when it
		# shows up, gets hysteresis as data (an appeal-curve tweak in
		# sandbox_tuning.gd), never a priority gate bolted onto the brain.
		if v.doing == null or v.doing.finished:
			if not v.plan.is_empty():
				v.doing = v.plan.pop_front()
				v.doing.begin()
			else:
				choose(v)
		v.doing.advance(delta)


func choose(v: Villager) -> void:
	v.last_decision = UtilityBrain.decide(stats, v.actor, options)
	var option: ActionOption = v.last_decision.chosen
	assert(option != null, "no eligible option for %s — pass_time_well has no gate and should always qualify" % v.actor.person_name)

	var here: StringName = stats.get_primary(v.actor, Stat.PLACE)
	var already_there: bool = here == option.place and v.position == places[option.place]
	var steps: Array[Activity] = []
	if not already_there:
		steps.append(WalkTo.new(v, self, option.place))
	steps.append(Perform.new(v, self, option))

	v.doing = steps.pop_front()
	v.plan = steps
	v.doing.begin()

	var score := 0.0
	for entry in v.last_decision.considered:
		if entry.option == option:
			score = entry.score
			break
	_log("%s decides: %s (score %.1f; best of %d)" % [v.actor.person_name, option.label, score, v.last_decision.considered.size()])


func _log(line: String) -> void:
	log_lines.append(line)
