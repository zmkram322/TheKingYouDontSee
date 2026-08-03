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
		var goal := v.current_goal()
		if goal == null:
			choose(v)
			goal = v.current_goal()
		elif goal.is_complete():
			# This goal is fully done — drop it. Whatever's queued behind it
			# (a paused self-goal or a waiting assigned one) just resumes
			# untouched; nothing gets re-scored just because it reached the
			# front. Only an empty queue asks the brain for something new.
			v.goal_queue.pop_front()
			goal = v.current_goal()
			if goal == null:
				choose(v)
				goal = v.current_goal()
			elif not goal.started:
				goal.begin()
		elif goal.doing.finished:
			goal.advance_step()
		goal.doing.advance(delta)


# Compares THREATENED from before/after a FEAR write and reconsiders only on
# an actual flip — the pre-emption trigger. This is bookkeeping about when to
# ask the brain again, not a second copy of the threat logic itself; that
# logic lives entirely in _derive_threatened.
func _sync_threat(v: Villager, was_threatened: bool) -> void:
	var now_threatened: bool = stats.get_derived(v.actor, Stat.THREATENED)
	if now_threatened == was_threatened:
		return
	if now_threatened:
		_log("%s is startled and bolts for safety!" % v.actor.person_name)
	v.reconsider(self)


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
	v.reconsider(self)


# The scare button's handler. Writes FEAR directly, same as any other stat
# write, then runs the same before/after check the ambient loop uses — so a
# scare takes effect immediately (mid-Activity, not on the next frame's
# drift pass) without a second, parallel notion of "just got scared."
func scare(v: Villager, amount: float = SandboxTune.SCARE_AMOUNT) -> void:
	var was_threatened: bool = stats.get_derived(v.actor, Stat.THREATENED)
	var fear: float = stats.get_primary(v.actor, Stat.FEAR)
	stats.write_primary(v.actor, Stat.FEAR, minf(SandboxTune.FEAR_MAX, fear + amount))
	_sync_threat(v, was_threatened)


# Builds a goal's local execution plan. option.place == &"" is the "wherever
# I already am" sentinel — used by options with no destination of their own
# (e.g. greeting whoever's nearby) — so no WalkTo is ever queued for it.
func _build_goal(v: Villager, option: ActionOption) -> Goal:
	var goal := Goal.new(option)
	var steps: Array[Activity] = []
	if option.place != &"":
		var here: StringName = stats.get_primary(v.actor, Stat.PLACE)
		var already_there: bool = here == option.place and v.position == places[option.place]
		if not already_there:
			steps.append(WalkTo.new(v, self, option.place))
	steps.append(Perform.new(v, self, option))
	goal.doing = steps.pop_front()
	goal.plan = steps
	return goal


# The self-directed decision point: score everything, and if the winner is
# already what's running, leave it alone (this is what makes resuming a
# paused goal safe to route back through choose() — it comes back out a
# no-op unless something genuinely outscored it). Otherwise the winner takes
# the front and whatever was there — if anything — waits its turn instead of
# being discarded. This one rule covers both "queue was empty, fill it" and
# "something just interrupted" without needing to tell them apart.
func choose(v: Villager) -> void:
	v.last_decision = UtilityBrain.decide(stats, v.actor, options)
	var option: ActionOption = v.last_decision.chosen
	assert(option != null, "no eligible option for %s — pass_time_well has no gate and should always qualify" % v.actor.person_name)

	var current := v.current_goal()
	if current != null and current.option == option:
		return

	# The winner might already be sitting paused further back in the queue
	# (an earlier interrupt shelved it) rather than genuinely new — promote
	# that same Goal instead of building a duplicate, or a goal that was
	# mid-walk would silently restart from scratch every time it's re-picked.
	for i in range(1, v.goal_queue.size()):
		if v.goal_queue[i].option == option:
			var existing: Goal = v.goal_queue[i]
			v.goal_queue.remove_at(i)
			v.goal_queue.push_front(existing)
			_log("%s returns to: %s" % [v.actor.person_name, option.label])
			return

	var goal := _build_goal(v, option)
	goal.begin()
	v.goal_queue.push_front(goal)

	var score := 0.0
	for entry in v.last_decision.considered:
		if entry.option == option:
			score = entry.score
			break
	var verb := "decides" if current == null else "interrupts itself"
	_log("%s %s: %s (score %.1f; best of %d)" % [v.actor.person_name, verb, option.label, score, v.last_decision.considered.size()])


# The externally-assigned counterpart to choose(): not a competition this
# actor's own scoring runs, but an obligation handed to them (e.g. a provider
# asked to serve someone else's demand). Queues behind whatever they're
# already doing rather than preempting it — the PRD's sense of "goal,"
# distinct from choose()'s self-directed picks.
func assign_goal(v: Villager, option: ActionOption) -> void:
	var goal := _build_goal(v, option)
	var was_empty := v.goal_queue.is_empty()
	v.goal_queue.push_back(goal)
	if was_empty:
		goal.begin()
	_log("%s is asked to: %s (%s)" % [v.actor.person_name, option.label, "starting now" if was_empty else "queued behind current work"])


func _log(line: String) -> void:
	log_lines.append(line)
