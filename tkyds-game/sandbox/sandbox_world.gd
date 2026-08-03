class_name SandboxWorld
extends RefCounted

# The behavior sandbox's engine, fully headless — the scene is a skin over
# it, same split as Simulation/main.gd. advance(delta) is the only mover:
# it drifts needs, lets each villager's Orchestrator pick and run whatever
# it's doing. Nothing here names a specific behavior; the four example
# actions live only in sandbox/sandbox_catalog.gd.

var stats: StatStore
var villagers: Array[Villager] = []
var options: Array[ActionOption] = []
var places := {}          # StringName -> Vector2
var log_lines: Array[String] = []
var time := 0.0            # seconds of sandbox time elapsed

# Fired the instant two villagers cross GREET_PROXIMITY_RADIUS (edge-triggered
# — see _scan_proximity), not polled. A real push notification, not Area2D:
# position lives outside StatStore on purpose (see behavior/action_option.gd's
# comment and sandbox/walk_to.gd), so this is SandboxWorld's own plain-data
# distance check emitting the "change-notification signal" the PRD reserves
# for exactly this class of problem — without requiring a live physics tick,
# which would break running this whole world under --headless --script with
# no scene at all (see tests/sandbox_smoke.gd).
signal proximity_detected(v: Villager)


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
	stats.set_actor_default(Stat.FEAR, 0.0)
	stats.set_actor_default(Stat.NEARBY, false)
	stats.set_actor_default(Stat.GREET_COOLDOWN, 0.0)
	stats.define_derived(Stat.VIGOR, _derive_vigor)
	stats.define_derived(Stat.THREATENED, _derive_threatened)

	if not proximity_detected.is_connected(_on_proximity_detected):
		proximity_detected.connect(_on_proximity_detected)

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

	log_line("Sandbox seeded: %d villagers, %d places, %d actions in the catalog." % [villagers.size(), places.size(), options.size()])


func _spawn(person_name: String, position: Vector2) -> Villager:
	var a := Actor.new(person_name)
	stats.register(a)
	var v := Villager.new(a, position)
	v.orchestrator = Orchestrator.new(a, stats, options, Callable(self, "build_goal"), Callable(self, "log_line"))
	villagers.append(v)
	return v


func _derive_vigor(store: StatStore, a: Actor, _b: Actor) -> float:
	var energy: float = store.get_primary(a, Stat.ENERGY)
	var hunger: float = store.get_primary(a, Stat.HUNGER)
	return clampf((energy - 0.5 * hunger) / SandboxTune.ENERGY_MAX, 0.0, 1.0)


# Pure math off the one primary — no stored history. The reshape (X < 1)
# makes this read stay above THREAT_THRESHOLD longer than raw FEAR would as
# it decays, which is what gives "takes a while to calm down" without a
# second threshold or a hand-written primary.
func _derive_threatened(store: StatStore, a: Actor, _b: Actor) -> bool:
	var fear: float = store.get_primary(a, Stat.FEAR)
	var lingering: float = SandboxTune.FEAR_MAX * pow(fear / SandboxTune.FEAR_MAX, SandboxTune.FEAR_LINGER_EXPONENT)
	return lingering >= SandboxTune.THREAT_THRESHOLD


# --- The step -----------------------------------------------------------

func advance(delta: float) -> void:
	time += delta

	# Ambient drift, through the store, so derived caches (VIGOR, THREATENED)
	# invalidate honestly rather than going stale under a doing actor's feet.
	for v in villagers:
		var hunger: float = stats.get_primary(v.actor, Stat.HUNGER)
		stats.write_primary(v.actor, Stat.HUNGER, minf(SandboxTune.HUNGER_MAX, hunger + SandboxTune.HUNGER_PER_SECOND * delta))
		var energy: float = stats.get_primary(v.actor, Stat.ENERGY)
		stats.write_primary(v.actor, Stat.ENERGY, maxf(0.0, energy - SandboxTune.ENERGY_DRIFT_PER_SECOND * delta))

		# Cheap watcher, not a poll of the brain: reading a cached derived
		# bool before/after one primary write is nowhere near the cost of a
		# full rescore. The expensive part (reconsider -> choose(), scoring
		# the whole catalog) only runs on the rare tick where THREATENED
		# actually flips.
		var was_threatened: bool = stats.get_derived(v.actor, Stat.THREATENED)
		var fear: float = stats.get_primary(v.actor, Stat.FEAR)
		stats.write_primary(v.actor, Stat.FEAR, maxf(0.0, fear - SandboxTune.FEAR_DECAY_PER_SECOND * delta))
		_sync_threat(v, was_threatened)

		var cooldown: float = stats.get_primary(v.actor, Stat.GREET_COOLDOWN)
		if cooldown > 0.0:
			stats.write_primary(v.actor, Stat.GREET_COOLDOWN, maxf(0.0, cooldown - delta))

	_scan_proximity()

	for v in villagers:
		v.orchestrator.tick(delta)


# Compares THREATENED from before/after a FEAR write and reconsiders only on
# an actual flip — the pre-emption trigger. This is bookkeeping about when to
# ask the brain again, not a second copy of the threat logic itself; that
# logic lives entirely in _derive_threatened.
func _sync_threat(v: Villager, was_threatened: bool) -> void:
	var now_threatened: bool = stats.get_derived(v.actor, Stat.THREATENED)
	if now_threatened == was_threatened:
		return
	if now_threatened:
		log_line("%s is startled and bolts for safety!" % v.actor.person_name)
	v.reconsider()


# O(n^2) over the live villager list — trivial at sandbox scale (5 actors)
# and still cheap at the NFR's 150-actor ceiling, since it's nothing but
# distance math. Deliberately doesn't identify WHO is nearby: NEARBY is a
# plain per-actor bool, because nothing downstream (appeal/eligibility) can
# resolve an Actor reference back from the store anyway — see
# greet_passerby's comment in sandbox_catalog.gd. Edge-triggered exactly like
# _sync_threat: emits only on a false->true flip, so two villagers lingering
# close together don't refire every tick (the cooldown handles re-approach
# after separating).
func _scan_proximity() -> void:
	for i in villagers.size():
		var a: Villager = villagers[i]
		var was_nearby: bool = stats.get_primary(a.actor, Stat.NEARBY)
		var now_nearby := false
		for j in villagers.size():
			if i == j:
				continue
			if a.position.distance_to(villagers[j].position) <= SandboxTune.GREET_PROXIMITY_RADIUS:
				now_nearby = true
				break
		if now_nearby != was_nearby:
			stats.write_primary(a.actor, Stat.NEARBY, now_nearby)
			if now_nearby:
				proximity_detected.emit(a)


func _on_proximity_detected(v: Villager) -> void:
	v.reconsider()


# The scare button's handler. Writes FEAR directly, same as any other stat
# write, then runs the same before/after check the ambient loop uses — so a
# scare takes effect immediately (mid-Activity, not on the next frame's
# drift pass) without a second, parallel notion of "just got scared."
func scare(v: Villager, amount: float = SandboxTune.SCARE_AMOUNT) -> void:
	var was_threatened: bool = stats.get_derived(v.actor, Stat.THREATENED)
	var fear: float = stats.get_primary(v.actor, Stat.FEAR)
	stats.write_primary(v.actor, Stat.FEAR, minf(SandboxTune.FEAR_MAX, fear + amount))
	_sync_threat(v, was_threatened)


func _villager_for(a: Actor) -> Villager:
	for v in villagers:
		if v.actor == a:
			return v
	return null


# Turns a chosen ActionOption into its execution State — the one place
# sandbox-specific construction knowledge (places, WalkTo) lives. Called by
# any Orchestrator as a plain Callable (bound in _spawn); Orchestrator never
# sees these types itself, which is what keeps it generic. option.place ==
# &"" is the "wherever I already am" sentinel — used by options with no
# destination of their own (e.g. greeting whoever's nearby) — so no WalkTo
# is ever built for it.
func build_goal(actor: Actor, option: ActionOption) -> Goal:
	var v := _villager_for(actor)
	var goal := Goal.new(option)
	var steps: Array[State] = []
	if option.place != &"":
		var here: StringName = stats.get_primary(actor, Stat.PLACE)
		var already_there: bool = here == option.place and v.position == places[option.place]
		if not already_there:
			steps.append(WalkTo.new(v, self, option.place))
	steps.append(Perform.new(v, self, option))
	var sequence := SequenceState.new()
	sequence.children = steps
	goal.root = sequence
	return goal


func log_line(line: String) -> void:
	log_lines.append(line)
