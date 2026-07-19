class_name Simulation
extends RefCounted

# The world engine. One good (food), driven entirely by hunger.
# advance_one_tick() moves the whole dependency graph forward exactly ONE hop,
# so a full cascade (hungry -> need merchant -> need producer -> produce -> sell
# -> sell -> eat) visibly crawls down and the satisfaction visibly crawls back up
# over several ticks. Nothing here knows about market windows or world triggers.

# --- Tunable feel constants -------------------------------------------------
const HUNGER_PER_TICK := 6.0
const HUNGER_NEED_THRESHOLD := 50.0
const HUNGER_MAX := 100.0
const EAT_REDUCES_HUNGER := 70.0  # a meal actually fills you up (drops below threshold)
const PRODUCE_TICKS := 2          # ticks a producer spends on a batch
const FOOD_PER_PRODUCTION := 2    # batch size — leaves buffer stock so one producer feeds several
# ----------------------------------------------------------------------------

var tick: int = 0
var actors: Array[Actor] = []
var demands: Array[Demand] = []   # open (unsatisfied) demands only
var log_lines: Array[String] = []

var _next_demand_id: int = 1


func reset() -> void:
	tick = 0
	actors.clear()
	demands.clear()
	log_lines.clear()
	_next_demand_id = 1

	# Two consumers, staggered so they don't all get hungry on the same tick.
	var bram := Actor.new("Bram", Actor.ROLE_CONSUMER)
	bram.hunger = 42.0
	var cora := Actor.new("Cora", Actor.ROLE_CONSUMER)
	cora.hunger = 18.0
	actors.append(bram)
	actors.append(cora)

	# A pool of idle people. The cascade pulls them into roles as it needs them.
	for i in range(3):
		actors.append(Actor.new("Idle-%d" % (i + 1)))

	_log("World seeded: 2 consumers, 3 idle. Nobody is a merchant or producer yet.")
	_refresh_all_state_text()


# --- The tick ---------------------------------------------------------------

func advance_one_tick() -> void:
	tick += 1
	_log("──────── Tick %d ────────" % tick)

	_accumulate_hunger_and_emit()
	_advance_production()
	_step_all_demands_one_hop()
	_refresh_all_state_text()


func _accumulate_hunger_and_emit() -> void:
	for a in actors:
		if a.role != Actor.ROLE_CONSUMER:
			continue
		a.hunger = min(HUNGER_MAX, a.hunger + HUNGER_PER_TICK)
		if a.hunger >= HUNGER_NEED_THRESHOLD and not _has_open_food_demand(a):
			var d := _new_demand(Demand.FOOD, a)
			d.phase = &"check_pantry"
			_log("%s is hungry (%d) → emits demand #%d for food" % [a.person_name, int(a.hunger), d.id])


func _advance_production() -> void:
	for a in actors:
		if a.role == Actor.ROLE_PRODUCER and a.producing_ticks_left > 0:
			a.producing_ticks_left -= 1
			if a.producing_ticks_left == 0:
				a.food += FOOD_PER_PRODUCTION
				_log("%s finished a batch (+%d) → now holds %d food" % [a.person_name, FOOD_PER_PRODUCTION, a.food])


func _step_all_demands_one_hop() -> void:
	# Snapshot: demands spawned during this loop wait until next tick, which is
	# exactly what makes the wave travel one layer per tick.
	var snapshot := demands.duplicate()
	for d in snapshot:
		if d.satisfied:
			continue
		match d.kind:
			Demand.FOOD:
				_step_food(d)
			Demand.ROLE:
				_step_role(d)
			Demand.BUY_GOOD:
				_step_buy(d)
	# Drop everything that got satisfied this tick.
	demands = demands.filter(func(d: Demand) -> bool: return not d.satisfied)


# --- The three resolvers ----------------------------------------------------

func _step_food(d: Demand) -> void:
	var consumer := d.requester
	match d.phase:
		&"check_pantry":
			if consumer.food > 0:
				d.phase = &"eat"
			else:
				d.phase = &"find_merchant"
				_step_food(d)   # no reason to burn a tick just re-labelling

		&"find_merchant":
			var merchant := _find_actor_with_role(Actor.ROLE_MERCHANT)
			if merchant != null:
				d.provider = merchant
				d.phase = &"request_good"
				_log("  #%d: found merchant %s → asks for food" % [d.id, merchant.person_name])
			else:
				d.child = _need_role(Actor.ROLE_MERCHANT, d)
				d.phase = &"await_merchant"
				_log("  #%d: no merchant exists → emits demand #%d for a merchant" % [d.id, d.child.id])

		&"await_merchant":
			if d.child != null and d.child.satisfied:
				d.phase = &"find_merchant"
				_log("  #%d: a merchant now exists → resuming" % d.id)

		&"request_good":
			var merchant := d.provider
			if merchant.food > 0:
				merchant.food -= 1
				consumer.food += 1
				d.phase = &"eat"
				_log("  #%d: %s buys food from %s" % [d.id, consumer.person_name, merchant.person_name])
			else:
				d.child = _need_restock(merchant, d)
				d.phase = &"await_good"
				_log("  #%d: %s is out of stock → emits demand #%d to restock" % [d.id, merchant.person_name, d.child.id])

		&"await_good":
			if d.child != null and d.child.satisfied:
				d.phase = &"request_good"
				_log("  #%d: %s restocked → resuming" % [d.id, d.provider.person_name])

		&"eat":
			consumer.food -= 1
			consumer.hunger = max(0.0, consumer.hunger - EAT_REDUCES_HUNGER)
			d.satisfied = true
			_log("  #%d: %s eats. Hunger now %d. ✓ satisfied" % [d.id, consumer.person_name, int(consumer.hunger)])


func _step_role(d: Demand) -> void:
	# "A missing role is just another demand." Auto-assign an idle body if one
	# is free; otherwise keep waiting (the demand stays tracked in the queue).
	var idle := _find_actor_with_role(Actor.ROLE_IDLE)
	if idle != null:
		idle.role = d.role_wanted
		d.provider = idle
		d.satisfied = true
		_log("  #%d: assigned %s as %s. ✓ satisfied" % [d.id, idle.person_name, String(d.role_wanted)])
	else:
		_log("  #%d: no idle person free to become %s — waiting" % [d.id, String(d.role_wanted)])


func _step_buy(d: Demand) -> void:
	var merchant := d.requester
	match d.phase:
		&"find_producer":
			var producer := _find_actor_with_role(Actor.ROLE_PRODUCER)
			if producer != null:
				d.provider = producer
				d.phase = &"request_produce"
				_log("  #%d: found producer %s → asks for food" % [d.id, producer.person_name])
			else:
				d.child = _need_role(Actor.ROLE_PRODUCER, d)
				d.phase = &"await_producer"
				_log("  #%d: no producer exists → emits demand #%d for a producer" % [d.id, d.child.id])

		&"await_producer":
			if d.child != null and d.child.satisfied:
				d.phase = &"find_producer"
				_log("  #%d: a producer now exists → resuming" % d.id)

		&"request_produce":
			var producer := d.provider
			if producer.food > 0:
				producer.food -= 1
				merchant.food += 1
				d.satisfied = true
				_log("  #%d: %s buys food from %s. ✓ satisfied" % [d.id, merchant.person_name, producer.person_name])
			else:
				if producer.producing_ticks_left == 0:
					producer.producing_ticks_left = PRODUCE_TICKS
					_log("  #%d: %s has no stock → starts producing (%d ticks)" % [d.id, producer.person_name, PRODUCE_TICKS])
				d.phase = &"await_produce"

		&"await_produce":
			var producer := d.provider
			if producer.food > 0:
				producer.food -= 1
				merchant.food += 1
				d.satisfied = true
				_log("  #%d: %s buys freshly-made food from %s. ✓ satisfied" % [d.id, merchant.person_name, producer.person_name])


# --- Small helpers ----------------------------------------------------------

func _new_demand(kind: StringName, who: Actor) -> Demand:
	var d := Demand.new(_next_demand_id, kind, who)
	_next_demand_id += 1
	demands.append(d)
	return d


# Reuse an already-open role demand if one exists, so we never assign two
# merchants when one will do. Missing-role demands are shared.
func _need_role(role: StringName, parent: Demand) -> Demand:
	for d in demands:
		if d.kind == Demand.ROLE and d.role_wanted == role and not d.satisfied:
			return d
	var nd := _new_demand(Demand.ROLE, parent.requester)
	nd.role_wanted = role
	nd.phase = &"find_idle"
	return nd


# Reuse an open restock demand for the same merchant.
func _need_restock(merchant: Actor, _parent: Demand) -> Demand:
	for d in demands:
		if d.kind == Demand.BUY_GOOD and d.requester == merchant and not d.satisfied:
			return d
	var nd := _new_demand(Demand.BUY_GOOD, merchant)
	nd.phase = &"find_producer"
	return nd


func _find_actor_with_role(role: StringName) -> Actor:
	for a in actors:
		if a.role == role:
			return a
	return null


func _has_open_food_demand(consumer: Actor) -> bool:
	for d in demands:
		if d.kind == Demand.FOOD and d.requester == consumer and not d.satisfied:
			return true
	return false


func _log(line: String) -> void:
	log_lines.append(line)


func _refresh_all_state_text() -> void:
	for a in actors:
		a.state_text = _describe(a)


func _describe(a: Actor) -> String:
	match a.role:
		Actor.ROLE_CONSUMER:
			if a.hunger >= HUNGER_MAX:
				return "STARVING"
			if _has_open_food_demand(a):
				return "seeking food"
			return "fed" if a.hunger < HUNGER_NEED_THRESHOLD else "hungry"
		Actor.ROLE_MERCHANT:
			return "merchant · %d food" % a.food
		Actor.ROLE_PRODUCER:
			if a.producing_ticks_left > 0:
				return "producing (%d left) · %d food" % [a.producing_ticks_left, a.food]
			return "producer · %d food" % a.food
		_:
			return "idle"
