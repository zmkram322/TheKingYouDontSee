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

# --- Money & willingness (slice 3) ---
const FOOD_RETAIL_PRICE := 3      # what an eater pays the merchant for 1 food
const FOOD_WHOLESALE_PRICE := 2   # what the merchant pays the producer for 1 food
const WAGE_PER_BATCH := 3         # what a producer pays each worker when a batch lands
const EMPLOYMENT_COIN_THRESHOLD := 20   # a consumer this broke goes looking for a job
const PRODUCER_STARTING_EQUITY := 250   # a producer's capital — must outlast its payroll
const WILLINGNESS_MAX := 100.0
const QUIT_THRESHOLD := 20.0            # below this, a worker refuses to work
const WILLINGNESS_HUNGER_DRAIN := 0.03  # per tick × current hunger — hunger erodes willingness
const WAGE_WILLINGNESS_BOOST := 25.0    # a paycheck restores willingness — "everyone has a price"
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
	# They hold the starting money supply (spent on food, topped up by a stipend).
	var bram := Actor.new("Bram", Actor.ROLE_CONSUMER)
	bram.hunger = 42.0
	bram.coin = 40
	var cora := Actor.new("Cora", Actor.ROLE_CONSUMER)
	cora.hunger = 18.0
	cora.coin = 40
	actors.append(bram)
	actors.append(cora)

	# A pool of idle people. The cascade pulls them into roles as it needs them:
	# merchant + producer + at least one farm worker all get drawn from here.
	# A little starting coin lets a fresh merchant/producer bootstrap trade.
	for i in range(4):
		var idle := Actor.new("Idle-%d" % (i + 1))
		idle.coin = 10
		actors.append(idle)

	_log("World seeded: 2 consumers, 4 idle. No merchant, producer, or workers yet.")
	_refresh_all_state_text()


# --- The tick ---------------------------------------------------------------

func advance_one_tick() -> void:
	tick += 1
	_log("──────── Tick %d ────────" % tick)

	_accumulate_hunger_and_emit()
	_seek_employment()
	_drain_willingness()
	_advance_production()   # completing a batch pays wages, which restores willingness
	_step_all_demands_one_hop()
	_refresh_all_state_text()


func _seek_employment() -> void:
	# A consumer who's running low on coin goes looking for work — the person
	# side of a two-sided match (they want a wage; a producer wants hands).
	for a in actors:
		if a.role == Actor.ROLE_CONSUMER and a.coin < EMPLOYMENT_COIN_THRESHOLD and not _has_open_employment_demand(a):
			var d := _new_demand(Demand.EMPLOYMENT, a)
			d.phase = &"find_employer"
			_log("%s is low on coin (%dc) → looks for work (demand #%d)" % [a.person_name, a.coin, d.id])


func _has_open_employment_demand(a: Actor) -> bool:
	for d in demands:
		if d.kind == Demand.EMPLOYMENT and d.requester == a and not d.satisfied:
			return true
	return false


func _drain_willingness() -> void:
	# The hungrier a worker is, the faster their will to keep working erodes.
	for a in actors:
		if a.role == Actor.ROLE_FARM_WORKER:
			a.willingness = max(0.0, a.willingness - a.hunger * WILLINGNESS_HUNGER_DRAIN)


func _accumulate_hunger_and_emit() -> void:
	# Everyone who eats gets hungry — including the farm workers we hire. That's
	# the feedback loop: every worker added to grow food is another mouth to feed.
	for a in actors:
		if not _is_eater(a):
			continue
		a.hunger = min(HUNGER_MAX, a.hunger + HUNGER_PER_TICK)
		if a.hunger >= HUNGER_NEED_THRESHOLD and not _has_open_food_demand(a):
			var d := _new_demand(Demand.FOOD, a)
			d.phase = &"check_pantry"
			_log("%s is hungry (%d) → emits demand #%d for food" % [a.person_name, int(a.hunger), d.id])


func _is_eater(a: Actor) -> bool:
	return a.role == Actor.ROLE_CONSUMER or a.role == Actor.ROLE_FARM_WORKER


func _advance_production() -> void:
	for a in actors:
		if a.role != Actor.ROLE_PRODUCER or a.producing_ticks_left <= 0:
			continue
		# Teeth: a batch only makes progress while a worker is still willing.
		# Willingness is held up by pay, so a well-paid worker labours on despite hunger.
		if not _producer_can_work(a):
			if not a.stalled:
				a.stalled = true
				_log("%s STALLS — its workers refuse to work (demoralised)" % a.person_name)
			continue
		if a.stalled:
			a.stalled = false
			_log("%s's workers are willing again → production resumes" % a.person_name)
		a.producing_ticks_left -= 1
		if a.producing_ticks_left == 0:
			a.food += FOOD_PER_PRODUCTION
			_log("%s finished a batch (+%d) → now holds %d food" % [a.person_name, FOOD_PER_PRODUCTION, a.food])
			_pay_wages(a)


func _producer_can_work(p: Actor) -> bool:
	for w in p.workers:
		if w.willingness > QUIT_THRESHOLD:
			return true
	return false


func _pay_wages(producer: Actor) -> void:
	for w in producer.workers:
		if producer.coin >= WAGE_PER_BATCH:
			producer.coin -= WAGE_PER_BATCH
			w.coin += WAGE_PER_BATCH
			w.willingness = min(WILLINGNESS_MAX, w.willingness + WAGE_WILLINGNESS_BOOST)
			_log("  %s pays %s %dc in wages → willingness up to %d" % [producer.person_name, w.person_name, WAGE_PER_BATCH, int(w.willingness)])
		else:
			_log("  %s can't make payroll for %s (no coin)" % [producer.person_name, w.person_name])


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
			Demand.EMPLOYMENT:
				_step_employment(d)
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
				d.child = _need_role(Actor.ROLE_MERCHANT, d.requester)
				d.phase = &"await_merchant"
				_log("  #%d: no merchant exists → emits demand #%d for a merchant" % [d.id, d.child.id])

		&"await_merchant":
			if d.child != null and d.child.satisfied:
				d.phase = &"find_merchant"
				_log("  #%d: a merchant now exists → resuming" % d.id)

		&"request_good":
			var merchant := d.provider
			if merchant.food <= 0:
				d.child = _need_restock(merchant, d)
				d.phase = &"await_good"
				_log("  #%d: %s is out of stock → emits demand #%d to restock" % [d.id, merchant.person_name, d.child.id])
			elif consumer.coin >= FOOD_RETAIL_PRICE:
				merchant.food -= 1
				consumer.food += 1
				consumer.coin -= FOOD_RETAIL_PRICE
				merchant.coin += FOOD_RETAIL_PRICE
				d.phase = &"eat"
				_log("  #%d: %s buys food from %s for %dc" % [d.id, consumer.person_name, merchant.person_name, FOOD_RETAIL_PRICE])
			else:
				# Broke and hungry — for now they go without; a later slice turns
				# this into a demand for employment.
				_log("  #%d: %s can't afford food (%dc < %dc) — goes without" % [d.id, consumer.person_name, consumer.coin, FOOD_RETAIL_PRICE])

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
		if d.role_wanted == Actor.ROLE_PRODUCER:
			idle.coin = PRODUCER_STARTING_EQUITY
		d.provider = idle
		d.satisfied = true
		if d.role_wanted == Actor.ROLE_FARM_WORKER and d.requester != null:
			d.requester.workers.append(idle)
			_log("  #%d: hired %s as a farm worker for %s. ✓ satisfied" % [d.id, idle.person_name, d.requester.person_name])
		else:
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
				d.child = _need_role(Actor.ROLE_PRODUCER, d.requester)
				d.phase = &"await_producer"
				_log("  #%d: no producer exists → emits demand #%d for a producer" % [d.id, d.child.id])

		&"await_producer":
			if d.child != null and d.child.satisfied:
				d.phase = &"find_producer"
				_log("  #%d: a producer now exists → resuming" % d.id)

		&"request_produce":
			var producer := d.provider
			if producer.food > 0 and merchant.coin >= FOOD_WHOLESALE_PRICE:
				producer.food -= 1
				merchant.food += 1
				merchant.coin -= FOOD_WHOLESALE_PRICE
				producer.coin += FOOD_WHOLESALE_PRICE
				d.satisfied = true
				_log("  #%d: %s buys food from %s for %dc. ✓ satisfied" % [d.id, merchant.person_name, producer.person_name, FOOD_WHOLESALE_PRICE])
			elif producer.workers.is_empty():
				# Can't grow food without hands — a missing worker is just another demand.
				d.child = _need_role(Actor.ROLE_FARM_WORKER, producer)
				d.phase = &"await_worker"
				_log("  #%d: %s has no farm workers → emits demand #%d to hire one" % [d.id, producer.person_name, d.child.id])
			else:
				if producer.producing_ticks_left == 0:
					producer.producing_ticks_left = PRODUCE_TICKS
					_log("  #%d: %s puts its worker to producing (%d ticks)" % [d.id, producer.person_name, PRODUCE_TICKS])
				d.phase = &"await_produce"

		&"await_worker":
			if d.child != null and d.child.satisfied:
				d.phase = &"request_produce"
				_log("  #%d: %s now has a worker → resuming" % [d.id, d.provider.person_name])

		&"await_produce":
			var producer := d.provider
			if producer.food > 0 and merchant.coin >= FOOD_WHOLESALE_PRICE:
				producer.food -= 1
				merchant.food += 1
				merchant.coin -= FOOD_WHOLESALE_PRICE
				producer.coin += FOOD_WHOLESALE_PRICE
				d.satisfied = true
				_log("  #%d: %s buys freshly-made food from %s for %dc. ✓ satisfied" % [d.id, merchant.person_name, producer.person_name, FOOD_WHOLESALE_PRICE])


func _step_employment(d: Demand) -> void:
	# A broke consumer joins a producer's workforce and starts earning wages.
	var seeker := d.requester
	if seeker.role != Actor.ROLE_CONSUMER:
		d.satisfied = true
		return
	var producer := _find_actor_with_role(Actor.ROLE_PRODUCER)
	if producer == null:
		_log("  #%d: %s wants work but there's no employer yet — waiting" % [d.id, seeker.person_name])
		return
	seeker.role = Actor.ROLE_FARM_WORKER
	seeker.willingness = WILLINGNESS_MAX
	producer.workers.append(seeker)
	d.satisfied = true
	_log("  #%d: %s is hired by %s → now a farm worker earning wages. ✓ satisfied" % [d.id, seeker.person_name, producer.person_name])


# --- Small helpers ----------------------------------------------------------

func _new_demand(kind: StringName, who: Actor) -> Demand:
	var d := Demand.new(_next_demand_id, kind, who)
	_next_demand_id += 1
	demands.append(d)
	return d


# Reuse an already-open role demand if one exists, so we never assign two
# merchants when one will do. Missing-role demands are shared.
func _need_role(role: StringName, requester: Actor) -> Demand:
	for d in demands:
		if d.kind == Demand.ROLE and d.role_wanted == role and not d.satisfied:
			return d
	var nd := _new_demand(Demand.ROLE, requester)
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
			var tag := "seeking work" if _has_open_employment_demand(a) else _hunger_word(a)
			return "%s · %dc" % [tag, a.coin]
		Actor.ROLE_FARM_WORKER:
			if a.willingness <= QUIT_THRESHOLD:
				return "farm worker · QUIT (demoralised) · %dc" % a.coin
			return "farm worker · %s · will %d · %dc" % [_hunger_word(a), int(a.willingness), a.coin]
		Actor.ROLE_MERCHANT:
			return "merchant · %d food · %dc" % [a.food, a.coin]
		Actor.ROLE_PRODUCER:
			var hands := "%d worker(s)" % a.workers.size()
			if a.producing_ticks_left > 0 and not _producer_can_work(a):
				return "STALLED — workers quit · %d food · %dc · %s" % [a.food, a.coin, hands]
			if a.producing_ticks_left > 0:
				return "producing (%d left) · %d food · %dc · %s" % [a.producing_ticks_left, a.food, a.coin, hands]
			return "producer · %d food · %dc · %s" % [a.food, a.coin, hands]
		_:
			return "idle"


func _hunger_word(a: Actor) -> String:
	if a.hunger >= HUNGER_MAX:
		return "STARVING"
	if _has_open_food_demand(a):
		return "seeking food"
	return "fed" if a.hunger < HUNGER_NEED_THRESHOLD else "hungry"
