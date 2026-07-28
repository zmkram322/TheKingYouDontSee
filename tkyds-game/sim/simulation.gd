class_name Simulation
extends RefCounted

# The world engine. One good (food), driven entirely by hunger.
# advance_one_tick() moves the whole dependency graph forward exactly ONE hop,
# so a full cascade (hungry -> need merchant -> need producer -> produce -> sell
# -> sell -> eat) visibly crawls down and the satisfaction visibly crawls back up
# over several ticks. Nothing here knows about market windows or world triggers.

# Tunables live in sim/tuning.gd (the one constants block).

var tick: int = 0
var actors: Array[Actor] = []
var demands: Array[Demand] = []   # open (unsatisfied) demands only
var log_lines: Array[String] = []
var stats := StatStore.new()

# The player is an ordinary Actor running the same loop; the only thing that
# makes them the player is the input seam (queue_intent / look / greet).
var player: Actor = null

var _next_demand_id: int = 1
var _pending_intents: Array[Dictionary] = []
var _favor_pairs: Array = []   # [holder, toward] pairs with favor written, so upkeep can decay them


func reset() -> void:
	tick = 0
	actors.clear()
	demands.clear()
	log_lines.clear()
	_next_demand_id = 1

	player = null
	_pending_intents.clear()
	_favor_pairs.clear()

	stats = StatStore.new()
	stats.set_actor_default(Stat.HUNGER, 0.0)
	stats.set_actor_default(Stat.FOOD, 0)
	stats.set_actor_default(Stat.COIN, 0)
	stats.set_actor_default(Stat.WILLINGNESS, Tune.WILLINGNESS_MAX)
	stats.set_actor_default(Stat.ROLE, Actor.ROLE_IDLE)
	stats.set_actor_default(Stat.PRODUCING_TICKS_LEFT, 0)
	stats.set_actor_default(Stat.STALLED, false)
	stats.set_actor_default(Stat.PLACE, &"town")
	stats.set_actor_default(Stat.POISE, Tune.POISE_DEFAULT)
	stats.set_actor_default(Stat.STANDING, Tune.STANDING_DEFAULT)
	stats.set_actor_default(Stat.BELONGING, 60.0)
	stats.set_actor_default(Stat.PRESS_COOLDOWN, 0)
	stats.set_edge_default(Stat.FAVOR, 0.0)
	stats.set_edge_default(Stat.REGARD, 0.0)
	stats.set_edge_default(Stat.SIZING_TICKS, 0)
	stats.set_edge_default(Stat.SEEN_RUNG, &"")
	stats.define_derived(Stat.GREETING_RUNG, _derive_greeting_rung)

	# Two consumers, staggered so they don't all get hungry on the same tick.
	# They hold the starting money supply (spent on food, topped up by a stipend).
	var bram := _spawn("Bram", Actor.ROLE_CONSUMER)
	stats.write_primary(bram, Stat.HUNGER, 42.0)
	stats.write_primary(bram, Stat.COIN, 40)
	var cora := _spawn("Cora", Actor.ROLE_CONSUMER)
	stats.write_primary(cora, Stat.HUNGER, 18.0)
	stats.write_primary(cora, Stat.COIN, 40)

	# A pool of idle people. The cascade pulls them into roles as it needs them:
	# merchant + producer + at least one farm worker all get drawn from here.
	# A little starting coin lets a fresh merchant/producer bootstrap trade.
	for i in range(4):
		var idle := _spawn("Idle-%d" % (i + 1))
		stats.write_primary(idle, Stat.COIN, 10)

	# --- The pub, and the people in it ---------------------------------------
	# Rigged first case (a deliberate, guaranteed-legible contrast): two men in
	# the same room who differ only in STATE. Tam wants company he isn't getting;
	# Corwin wants for nothing. A round bought for one is an investment, for the
	# other a hole. Kestrel is low on standing and nursing a dislike — pressure
	# looking for a weak target. Nobody here has a goal.
	var keeper := _spawn("Osric", Actor.ROLE_KEEPER)
	stats.write_primary(keeper, Stat.PLACE, &"pub")
	stats.write_primary(keeper, Stat.STANDING, 25.0)

	var tam := _spawn("Tam", Actor.ROLE_CONSUMER)
	stats.write_primary(tam, Stat.PLACE, &"pub")
	stats.write_primary(tam, Stat.COIN, 60)
	stats.write_primary(tam, Stat.HUNGER, 20.0)
	stats.write_primary(tam, Stat.STANDING, 22.0)    # met — so his ONE tell is the belonging
	stats.write_primary(tam, Stat.BELONGING, 25.0)   # unmet — the tell shows, relief accrues

	var corwin := _spawn("Corwin", Actor.ROLE_CONSUMER)
	stats.write_primary(corwin, Stat.PLACE, &"pub")
	stats.write_primary(corwin, Stat.COIN, 60)
	stats.write_primary(corwin, Stat.HUNGER, 10.0)
	stats.write_primary(corwin, Stat.STANDING, 30.0)
	stats.write_primary(corwin, Stat.BELONGING, 90.0)  # met — a drink here buys nothing

	var kestrel := _spawn("Kestrel", Actor.ROLE_CONSUMER)
	stats.write_primary(kestrel, Stat.PLACE, &"pub")
	stats.write_primary(kestrel, Stat.COIN, 60)
	stats.write_primary(kestrel, Stat.HUNGER, 15.0)
	stats.write_primary(kestrel, Stat.STANDING, 8.0)   # unmet standing — pressure
	stats.write_primary(kestrel, Stat.POISE, 70.0)

	# The player: a newcomer subject to the same needs as anyone. Broke enough
	# to be pulled into the labour loop by the shipped resolvers, unknown enough
	# to read as the weakest thing in the room.
	player = _spawn("Aldric", Actor.ROLE_CONSUMER)
	stats.write_primary(player, Stat.COIN, 15)
	stats.write_primary(player, Stat.HUNGER, 30.0)
	stats.write_primary(player, Stat.STANDING, 5.0)
	stats.write_primary(kestrel, Stat.REGARD, -25.0, player)  # offence taken over nothing

	_log("World seeded: 2 consumers, 4 idle. No merchant, producer, or workers yet.")
	_log("The pub: Osric keeps it. Tam, Corwin and Kestrel drink there. Aldric arrives in town, unknown.")
	_refresh_all_state_text()


func _spawn(name: String, starting_role: StringName = Actor.ROLE_IDLE) -> Actor:
	var a := Actor.new(name)
	stats.register(a)
	if starting_role != Actor.ROLE_IDLE:
		stats.write_primary(a, Stat.ROLE, starting_role)
	actors.append(a)
	return a


# --- The tick ---------------------------------------------------------------

func advance_one_tick() -> void:
	tick += 1
	_log("──────── Tick %d ────────" % tick)

	_apply_player_intents()
	_accumulate_hunger_and_emit()
	_seek_employment()
	_drain_willingness()
	_advance_production()   # completing a batch pays wages, which restores willingness
	_social_upkeep()        # favor decays, poise recovers, cooldowns tick down
	_consider_pressing()    # pressure looking for a target — a scored choice, not a goal
	_emit_aid_calls()       # a buckling actor's need for help enters the queue by itself
	_step_all_demands_one_hop()
	_refresh_all_state_text()


func _seek_employment() -> void:
	# A consumer who's running low on coin goes looking for work — the person
	# side of a two-sided match (they want a wage; a producer wants hands).
	for a in actors:
		var role: StringName = stats.get_primary(a, Stat.ROLE)
		var coin: int = stats.get_primary(a, Stat.COIN)
		if role == Actor.ROLE_CONSUMER and coin < Tune.EMPLOYMENT_COIN_THRESHOLD and not _has_open_employment_demand(a):
			var d := _new_demand(Demand.EMPLOYMENT, a)
			d.phase = &"find_employer"
			_log("%s is low on coin (%dc) → looks for work (demand #%d)" % [a.person_name, coin, d.id])


func _has_open_employment_demand(a: Actor) -> bool:
	for d in demands:
		if d.kind == Demand.EMPLOYMENT and d.requester == a and not d.satisfied:
			return true
	return false


func _drain_willingness() -> void:
	# The hungrier a worker is, the faster their will to keep working erodes.
	for a in actors:
		var role: StringName = stats.get_primary(a, Stat.ROLE)
		if role == Actor.ROLE_FARM_WORKER:
			var willingness: float = stats.get_primary(a, Stat.WILLINGNESS)
			var hunger: float = stats.get_primary(a, Stat.HUNGER)
			stats.write_primary(a, Stat.WILLINGNESS, maxf(0.0, willingness - hunger * Tune.WILLINGNESS_HUNGER_DRAIN))


func _accumulate_hunger_and_emit() -> void:
	# Everyone who eats gets hungry — including the farm workers we hire. That's
	# the feedback loop: every worker added to grow food is another mouth to feed.
	for a in actors:
		if not _is_eater(a):
			continue
		var hunger: float = minf(Tune.HUNGER_MAX, stats.get_primary(a, Stat.HUNGER) + Tune.HUNGER_PER_TICK)
		stats.write_primary(a, Stat.HUNGER, hunger)
		if hunger >= Tune.HUNGER_NEED_THRESHOLD and not _has_open_food_demand(a):
			var d := _new_demand(Demand.FOOD, a)
			d.phase = &"check_pantry"
			_log("%s is hungry (%d) → emits demand #%d for food" % [a.person_name, int(hunger), d.id])


func _is_eater(a: Actor) -> bool:
	var role: StringName = stats.get_primary(a, Stat.ROLE)
	return role == Actor.ROLE_CONSUMER or role == Actor.ROLE_FARM_WORKER


func _advance_production() -> void:
	for a in actors:
		var role: StringName = stats.get_primary(a, Stat.ROLE)
		var producing_ticks_left: int = stats.get_primary(a, Stat.PRODUCING_TICKS_LEFT)
		if role != Actor.ROLE_PRODUCER or producing_ticks_left <= 0:
			continue
		# Teeth: a batch only makes progress while a worker is still willing.
		# Willingness is held up by pay, so a well-paid worker labours on despite hunger.
		if not _producer_can_work(a):
			if not stats.get_primary(a, Stat.STALLED):
				stats.write_primary(a, Stat.STALLED, true)
				_log("%s STALLS — its workers refuse to work (demoralised)" % a.person_name)
			continue
		if stats.get_primary(a, Stat.STALLED):
			stats.write_primary(a, Stat.STALLED, false)
			_log("%s's workers are willing again → production resumes" % a.person_name)
		producing_ticks_left -= 1
		stats.write_primary(a, Stat.PRODUCING_TICKS_LEFT, producing_ticks_left)
		if producing_ticks_left == 0:
			var food: int = stats.get_primary(a, Stat.FOOD) + Tune.FOOD_PER_PRODUCTION
			stats.write_primary(a, Stat.FOOD, food)
			_log("%s finished a batch (+%d) → now holds %d food" % [a.person_name, Tune.FOOD_PER_PRODUCTION, food])
			_pay_wages(a)


func _producer_can_work(p: Actor) -> bool:
	for w in p.workers:
		var willingness: float = stats.get_primary(w, Stat.WILLINGNESS)
		if willingness > Tune.QUIT_THRESHOLD:
			return true
	return false


func _pay_wages(producer: Actor) -> void:
	for w in producer.workers:
		var producer_coin: int = stats.get_primary(producer, Stat.COIN)
		if producer_coin >= Tune.WAGE_PER_BATCH:
			stats.write_primary(producer, Stat.COIN, producer_coin - Tune.WAGE_PER_BATCH)
			var worker_coin: int = stats.get_primary(w, Stat.COIN)
			stats.write_primary(w, Stat.COIN, worker_coin + Tune.WAGE_PER_BATCH)
			var willingness: float = stats.get_primary(w, Stat.WILLINGNESS)
			var new_willingness: float = minf(Tune.WILLINGNESS_MAX, willingness + Tune.WAGE_WILLINGNESS_BOOST)
			stats.write_primary(w, Stat.WILLINGNESS, new_willingness)
			_log("  %s pays %s %dc in wages → willingness up to %d" % [producer.person_name, w.person_name, Tune.WAGE_PER_BATCH, int(new_willingness)])
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
			Demand.PRESS:
				_step_press(d)
			Demand.AID:
				_step_aid(d)
	# Drop everything that got satisfied this tick.
	demands = demands.filter(func(d: Demand) -> bool: return not d.satisfied)


# --- The three resolvers ----------------------------------------------------

func _step_food(d: Demand) -> void:
	var consumer := d.requester
	match d.phase:
		&"check_pantry":
			var food: int = stats.get_primary(consumer, Stat.FOOD)
			if food > 0:
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
			var merchant_food: int = stats.get_primary(merchant, Stat.FOOD)
			var consumer_coin: int = stats.get_primary(consumer, Stat.COIN)
			if merchant_food <= 0:
				d.child = _need_restock(merchant, d)
				d.phase = &"await_good"
				_log("  #%d: %s is out of stock → emits demand #%d to restock" % [d.id, merchant.person_name, d.child.id])
			elif consumer_coin >= Tune.FOOD_RETAIL_PRICE:
				stats.write_primary(merchant, Stat.FOOD, merchant_food - 1)
				var consumer_food: int = stats.get_primary(consumer, Stat.FOOD)
				stats.write_primary(consumer, Stat.FOOD, consumer_food + 1)
				stats.write_primary(consumer, Stat.COIN, consumer_coin - Tune.FOOD_RETAIL_PRICE)
				var merchant_coin: int = stats.get_primary(merchant, Stat.COIN)
				stats.write_primary(merchant, Stat.COIN, merchant_coin + Tune.FOOD_RETAIL_PRICE)
				d.phase = &"eat"
				_log("  #%d: %s buys food from %s for %dc" % [d.id, consumer.person_name, merchant.person_name, Tune.FOOD_RETAIL_PRICE])
			else:
				# Broke and hungry — for now they go without; a later slice turns
				# this into a demand for employment.
				_log("  #%d: %s can't afford food (%dc < %dc) — goes without" % [d.id, consumer.person_name, consumer_coin, Tune.FOOD_RETAIL_PRICE])

		&"await_good":
			if d.child != null and d.child.satisfied:
				d.phase = &"request_good"
				_log("  #%d: %s restocked → resuming" % [d.id, d.provider.person_name])

		&"eat":
			var consumer_food: int = stats.get_primary(consumer, Stat.FOOD)
			stats.write_primary(consumer, Stat.FOOD, consumer_food - 1)
			var hunger: float = stats.get_primary(consumer, Stat.HUNGER)
			var new_hunger: float = maxf(0.0, hunger - Tune.EAT_REDUCES_HUNGER)
			stats.write_primary(consumer, Stat.HUNGER, new_hunger)
			d.satisfied = true
			_log("  #%d: %s eats. Hunger now %d. ✓ satisfied" % [d.id, consumer.person_name, int(new_hunger)])


func _step_role(d: Demand) -> void:
	# "A missing role is just another demand." Auto-assign an idle body if one
	# is free; otherwise keep waiting (the demand stays tracked in the queue).
	var idle := _find_actor_with_role(Actor.ROLE_IDLE)
	if idle != null:
		stats.write_primary(idle, Stat.ROLE, d.role_wanted)
		if d.role_wanted == Actor.ROLE_PRODUCER:
			stats.write_primary(idle, Stat.COIN, Tune.PRODUCER_STARTING_EQUITY)
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
			var producer_food: int = stats.get_primary(producer, Stat.FOOD)
			var merchant_coin: int = stats.get_primary(merchant, Stat.COIN)
			if producer_food > 0 and merchant_coin >= Tune.FOOD_WHOLESALE_PRICE:
				stats.write_primary(producer, Stat.FOOD, producer_food - 1)
				var merchant_food: int = stats.get_primary(merchant, Stat.FOOD)
				stats.write_primary(merchant, Stat.FOOD, merchant_food + 1)
				stats.write_primary(merchant, Stat.COIN, merchant_coin - Tune.FOOD_WHOLESALE_PRICE)
				var producer_coin: int = stats.get_primary(producer, Stat.COIN)
				stats.write_primary(producer, Stat.COIN, producer_coin + Tune.FOOD_WHOLESALE_PRICE)
				d.satisfied = true
				_log("  #%d: %s buys food from %s for %dc. ✓ satisfied" % [d.id, merchant.person_name, producer.person_name, Tune.FOOD_WHOLESALE_PRICE])
			elif producer.workers.is_empty():
				# Can't grow food without hands — a missing worker is just another demand.
				d.child = _need_role(Actor.ROLE_FARM_WORKER, producer)
				d.phase = &"await_worker"
				_log("  #%d: %s has no farm workers → emits demand #%d to hire one" % [d.id, producer.person_name, d.child.id])
			else:
				var producing_ticks_left: int = stats.get_primary(producer, Stat.PRODUCING_TICKS_LEFT)
				if producing_ticks_left == 0:
					stats.write_primary(producer, Stat.PRODUCING_TICKS_LEFT, Tune.PRODUCE_TICKS)
					_log("  #%d: %s puts its worker to producing (%d ticks)" % [d.id, producer.person_name, Tune.PRODUCE_TICKS])
				d.phase = &"await_produce"

		&"await_worker":
			if d.child != null and d.child.satisfied:
				d.phase = &"request_produce"
				_log("  #%d: %s now has a worker → resuming" % [d.id, d.provider.person_name])

		&"await_produce":
			var producer := d.provider
			var producer_food: int = stats.get_primary(producer, Stat.FOOD)
			var merchant_coin: int = stats.get_primary(merchant, Stat.COIN)
			if producer_food > 0 and merchant_coin >= Tune.FOOD_WHOLESALE_PRICE:
				stats.write_primary(producer, Stat.FOOD, producer_food - 1)
				var merchant_food: int = stats.get_primary(merchant, Stat.FOOD)
				stats.write_primary(merchant, Stat.FOOD, merchant_food + 1)
				stats.write_primary(merchant, Stat.COIN, merchant_coin - Tune.FOOD_WHOLESALE_PRICE)
				var producer_coin: int = stats.get_primary(producer, Stat.COIN)
				stats.write_primary(producer, Stat.COIN, producer_coin + Tune.FOOD_WHOLESALE_PRICE)
				d.satisfied = true
				_log("  #%d: %s buys freshly-made food from %s for %dc. ✓ satisfied" % [d.id, merchant.person_name, producer.person_name, Tune.FOOD_WHOLESALE_PRICE])


func _step_employment(d: Demand) -> void:
	# A broke consumer joins a producer's workforce and starts earning wages.
	var seeker := d.requester
	var seeker_role: StringName = stats.get_primary(seeker, Stat.ROLE)
	if seeker_role != Actor.ROLE_CONSUMER:
		d.satisfied = true
		return
	var producer := _find_actor_with_role(Actor.ROLE_PRODUCER)
	if producer == null:
		_log("  #%d: %s wants work but there's no employer yet — waiting" % [d.id, seeker.person_name])
		return
	stats.write_primary(seeker, Stat.ROLE, Actor.ROLE_FARM_WORKER)
	stats.write_primary(seeker, Stat.WILLINGNESS, Tune.WILLINGNESS_MAX)
	producer.workers.append(seeker)
	d.satisfied = true
	_log("  #%d: %s is hired by %s → now a farm worker earning wages. ✓ satisfied" % [d.id, seeker.person_name, producer.person_name])


# --- The player seam ---------------------------------------------------------
# The player acts by queueing intents; the sim applies them at the top of the
# next tick, so player acts and NPC decisions flow through the same clock.
# look() and greet() are reads — instant, no tick, no world change beyond the
# player's own record of what they saw.

func queue_intent(verb: StringName, subject: Variant = null) -> void:
	_pending_intents.append({"verb": verb, "subject": subject})


func _apply_player_intents() -> void:
	var pending := _pending_intents
	_pending_intents = []
	for intent in pending:
		match intent.verb:
			&"go_to":
				stats.write_primary(player, Stat.PLACE, intent.subject)
				_log("%s heads to the %s." % [player.person_name, intent.subject])
			&"share_drink":
				_share_drink(intent.subject)


func _share_drink(target: Actor) -> void:
	var here: StringName = stats.get_primary(player, Stat.PLACE)
	if stats.get_primary(target, Stat.PLACE) != here:
		_log("%s looks for %s to stand them a drink, but they aren't here." % [player.person_name, target.person_name])
		return
	var keeper := _keeper_at(here)
	if keeper == null:
		_log("No one here sells drinks.")
		return
	var coin: int = stats.get_primary(player, Stat.COIN)
	if coin < Tune.DRINK_PRICE:
		_log("%s can't cover a round (%dc < %dc)." % [player.person_name, coin, Tune.DRINK_PRICE])
		return
	# Priced transfer: coin moves player → keeper. Conserved, never spawned.
	stats.write_primary(player, Stat.COIN, coin - Tune.DRINK_PRICE)
	stats.write_primary(keeper, Stat.COIN, int(stats.get_primary(keeper, Stat.COIN)) + Tune.DRINK_PRICE)
	# Relieve-need: the drink touches the target's belonging. Whether it BUYS
	# anything depends entirely on whether that need was unmet — this one rule
	# is the whole difference between the right and the wrong investment.
	var belonging: float = stats.get_primary(target, Stat.BELONGING)
	var was_unmet := belonging < Tune.BELONGING_NEED_THRESHOLD
	stats.write_primary(target, Stat.BELONGING, minf(Tune.BELONGING_MAX, belonging + Tune.BELONGING_FROM_ROUND))
	stats.write_primary(target, Stat.REGARD, float(stats.get_primary(target, Stat.REGARD, player)) + Tune.REGARD_COURTESY_BUMP, player)
	if was_unmet:
		_accrue_favor(target, player, Tune.FAVOR_PER_RELIEVED_NEED)
		_log("%s buys %s a round. It lands — %s needed the company." % [player.person_name, target.person_name, target.person_name])
	else:
		_log("%s buys %s a round. %s toasts politely. Money in a hole." % [player.person_name, target.person_name, target.person_name])


func look(target: Actor) -> String:
	# Observe-mode: read the tells without spending a greeting. A tell is the
	# expression of an UNMET driver; a met driver shows nothing at all.
	var tells: Array[String] = []
	if float(stats.get_primary(target, Stat.BELONGING)) < Tune.BELONGING_NEED_THRESHOLD:
		tells.append("keeps to the edge of the group, glancing in")
	if float(stats.get_primary(target, Stat.STANDING)) < Tune.STANDING_NEED_THRESHOLD:
		tells.append("talks a little too loud, watching who's watching")
	if float(stats.get_primary(target, Stat.HUNGER)) >= Tune.HUNGER_NEED_THRESHOLD:
		tells.append("eyes other people's plates")
	var line: String
	if tells.is_empty():
		line = "%s looks settled — wants for nothing you can see." % target.person_name
	else:
		line = "%s: %s." % [target.person_name, "; ".join(tells)]
	_log("You watch. %s" % line)
	return line


func greet(target: Actor) -> String:
	# Read the rung the target shows you, and keep the PREVIOUS one — the delta
	# is the gameplay, and it's the thing humans forget.
	var rung: StringName = stats.get_derived(target, Stat.GREETING_RUNG, player)
	var prev: StringName = stats.get_primary(player, Stat.SEEN_RUNG, target)
	stats.write_primary(player, Stat.SEEN_RUNG, rung, target)
	var line := "%s answers your greeting: %s" % [target.person_name, rung]
	if prev != &"" and prev != rung:
		line += "  (was %s)" % prev
	_log(line)
	return line


# --- Social upkeep -----------------------------------------------------------

func _social_upkeep() -> void:
	for pair in _favor_pairs:
		var favor: float = stats.get_primary(pair[0], Stat.FAVOR, pair[1])
		if favor > 0.0:
			stats.write_primary(pair[0], Stat.FAVOR, maxf(0.0, favor - Tune.FAVOR_DECAY_PER_TICK), pair[1])
	for a in actors:
		var cooldown: int = stats.get_primary(a, Stat.PRESS_COOLDOWN)
		if cooldown > 0:
			stats.write_primary(a, Stat.PRESS_COOLDOWN, cooldown - 1)
		if _open_press_on(a) == null:
			var poise: float = stats.get_primary(a, Stat.POISE)
			if poise < Tune.POISE_DEFAULT:
				stats.write_primary(a, Stat.POISE, minf(Tune.POISE_DEFAULT, poise + Tune.POISE_REGEN_PER_TICK))


func _accrue_favor(holder: Actor, toward: Actor, amount: float) -> void:
	var favor: float = stats.get_primary(holder, Stat.FAVOR, toward)
	stats.write_primary(holder, Stat.FAVOR, favor + amount, toward)
	for pair in _favor_pairs:
		if pair[0] == holder and pair[1] == toward:
			return
	_favor_pairs.append([holder, toward])


# --- Pressing: a confrontation chosen from state ------------------------------
# Nobody is assigned aggression. An actor whose standing drive is unmet scores
# the move against every visible body in the room; the score has to clear a
# threshold, and it is re-scored every tick — the same evaluation that starts
# a confrontation ends it when the sums change.

func _consider_pressing() -> void:
	for a in actors:
		if a == player:
			continue   # the player-seam: their aggression is a verb, never a policy
		if int(stats.get_primary(a, Stat.PRESS_COOLDOWN)) > 0 or _open_press_by(a) != null:
			continue
		var unmet := maxf(0.0, Tune.STANDING_NEED_THRESHOLD - float(stats.get_primary(a, Stat.STANDING)))
		if unmet <= 0.0:
			continue
		var here: StringName = stats.get_primary(a, Stat.PLACE)
		var best: Actor = null
		var best_score := -INF
		for t in actors:
			if t == a or stats.get_primary(t, Stat.PLACE) != here or _open_press_on(t) != null:
				continue
			var score := _press_score(a, t)
			if score > best_score:
				best_score = score
				best = t
		if best == null or best_score < Tune.PRESS_START_THRESHOLD:
			continue
		var sizing: int = stats.get_primary(a, Stat.SIZING_TICKS, best) + 1
		stats.write_primary(a, Stat.SIZING_TICKS, sizing, best)
		if sizing == 1:
			_log("%s's eyes keep finding %s." % [a.person_name, best.person_name])
		if sizing >= Tune.PRESS_DWELL_TICKS:
			stats.write_primary(a, Stat.SIZING_TICKS, 0, best)
			var d := _new_demand(Demand.PRESS, a)
			d.target = best
			d.phase = &"pressing"
			_log("%s pushes back his chair and squares up to %s. (demand #%d)" % [a.person_name, best.person_name, d.id])


func _step_press(d: Demand) -> void:
	var aggressor := d.requester
	var target := d.target
	# Re-score every tick against VISIBLE state. Latent channels never enter;
	# only a backer who has committed changes the sums.
	var score := _press_score(aggressor, target)
	if score < Tune.PRESS_SUSTAIN_THRESHOLD:
		d.satisfied = true
		stats.write_primary(aggressor, Stat.PRESS_COOLDOWN, Tune.PRESS_COOLDOWN_TICKS)
		if d.backers.is_empty():
			_log("  #%d: %s loses interest and turns back to his drink." % [d.id, aggressor.person_name])
		else:
			_log("  #%d: %s reads the room again — this is no longer a lone stranger — and backs off. ✓ over" % [d.id, aggressor.person_name])
		return
	var poise := maxf(0.0, float(stats.get_primary(target, Stat.POISE)) - Tune.DRAWDOWN_PER_TICK)
	stats.write_primary(target, Stat.POISE, poise)
	_log("  #%d: %s presses %s — poise down to %d." % [d.id, aggressor.person_name, target.person_name, int(poise)])
	if poise <= Tune.YIELD_THRESHOLD:
		d.satisfied = true
		stats.write_primary(aggressor, Stat.PRESS_COOLDOWN, Tune.PRESS_COOLDOWN_TICKS)
		var lost := minf(Tune.YIELD_STANDING_LOSS, float(stats.get_primary(target, Stat.STANDING)))
		stats.write_primary(target, Stat.STANDING, float(stats.get_primary(target, Stat.STANDING)) - lost)
		stats.write_primary(aggressor, Stat.STANDING, float(stats.get_primary(aggressor, Stat.STANDING)) + Tune.PRESS_STANDING_GAIN)
		stats.write_primary(target, Stat.REGARD, float(stats.get_primary(target, Stat.REGARD, aggressor)) - 15.0, aggressor)
		_log("  #%d: %s yields. %s takes the room's regard. ✓ over" % [d.id, target.person_name, aggressor.person_name])


func _press_score(a: Actor, t: Actor) -> float:
	var unmet := maxf(0.0, Tune.STANDING_NEED_THRESHOLD - float(stats.get_primary(a, Stat.STANDING)))
	var grudge := maxf(0.0, -float(stats.get_primary(a, Stat.REGARD, t)))
	return Tune.W_STANDING_HUNGER * unmet + Tune.W_GRUDGE * grudge - Tune.W_THREAT * _threat(t)


# How costly someone looks to move against — VISIBLE state only. Held channels
# are latent: they enter this number only once a backer has visibly committed.
func _threat(t: Actor) -> float:
	var value := float(stats.get_primary(t, Stat.STANDING)) + Tune.THREAT_POISE_WEIGHT * float(stats.get_primary(t, Stat.POISE))
	var press := _open_press_on(t)
	if press != null:
		for backer in press.backers:
			value += Tune.W_BACKER * float(stats.get_primary(backer, Stat.STANDING))
	return value


# --- Aid: the demand nobody commands ------------------------------------------

func _emit_aid_calls() -> void:
	for d: Demand in demands.duplicate():
		if d.kind != Demand.PRESS or d.satisfied:
			continue
		if not d.backers.is_empty():
			continue   # help already stood up; the call is answered
		var victim: Actor = d.target
		if float(stats.get_primary(victim, Stat.POISE)) < Tune.AID_CALL_THRESHOLD and not _has_open_aid(victim):
			var ad := _new_demand(Demand.AID, victim)
			ad.regarding = d
			ad.phase = &"calling"
			_log("%s is buckling — the need for someone to step in hangs in the air. (demand #%d)" % [victim.person_name, ad.id])


func _step_aid(d: Demand) -> void:
	var victim := d.requester
	if d.regarding == null or d.regarding.satisfied:
		d.satisfied = true
		_log("  #%d: the moment passes — no one stepped in. ✗ unanswered" % d.id)
		return
	var aggressor: Actor = d.regarding.requester
	var here: StringName = stats.get_primary(victim, Stat.PLACE)
	# Provider-matching, but scored and refusable: every bystander runs the same
	# genuine evaluation, and "no" is a real outcome of it — not a branch.
	var best: Actor = null
	var best_score := -INF
	for c in actors:
		if c == victim or c == aggressor or c == player or c in d.regarding.backers:
			continue
		if stats.get_primary(c, Stat.PLACE) != here:
			continue
		var score := _aid_score(c, victim, aggressor)
		if score > best_score:
			best_score = score
			best = c
	if best == null:
		return
	if best_score >= Tune.INTERVENE_THRESHOLD:
		_intervene(best, d)
	elif best_score > 0.0:
		_log("  #%d: %s shifts in his seat — watching, not yet moved." % [d.id, best.person_name])


func _aid_score(c: Actor, victim: Actor, aggressor: Actor) -> float:
	var favor: float = stats.get_primary(c, Stat.FAVOR, victim)
	var peril := maxf(0.0, Tune.PERIL_POISE_BASELINE - float(stats.get_primary(victim, Stat.POISE)))
	return Tune.W_AID_FAVOR * favor + Tune.W_AID_PERIL * peril \
		- Tune.W_AID_DANGER * _threat(aggressor) - Tune.INTERVENE_BASE_RELUCTANCE


func _intervene(backer: Actor, aid: Demand) -> void:
	var victim := aid.requester
	var aggressor: Actor = aid.regarding.requester
	# The act is visible, attributable, and it costs the backer something real.
	stats.write_primary(backer, Stat.STANDING, maxf(0.0, float(stats.get_primary(backer, Stat.STANDING)) - Tune.INTERVENE_STANDING_SPEND))
	aid.regarding.backers.append(backer)
	stats.write_primary(backer, Stat.FAVOR, maxf(0.0, float(stats.get_primary(backer, Stat.FAVOR, victim)) - Tune.FAVOR_SPENT_WHEN_ACTED), victim)
	_accrue_favor(victim, backer, Tune.GRATITUDE_FAVOR)
	stats.write_primary(aggressor, Stat.REGARD, float(stats.get_primary(aggressor, Stat.REGARD, backer)) - 10.0, backer)
	aid.satisfied = true
	_log("  #%d: %s stands and puts himself between %s and %s — spending his own standing to do it. ✓ answered" % [aid.id, backer.person_name, aggressor.person_name, victim.person_name])


# --- Social lookups -----------------------------------------------------------

func _derive_greeting_rung(store: StatStore, a: Actor, b: Actor) -> StringName:
	# Discrete bands over favor + regard. Derived on read, never stored —
	# and never subdivided: the rung IS the readout.
	var warmth := float(store.get_primary(a, Stat.FAVOR, b)) + float(store.get_primary(a, Stat.REGARD, b))
	if warmth < Tune.RUNG_HOSTILE_BELOW:
		return &"hostile"
	if warmth < Tune.RUNG_COLD_BELOW:
		return &"cold"
	if warmth < Tune.RUNG_NEUTRAL_BELOW:
		return &"neutral"
	if warmth < Tune.RUNG_WARM_BELOW:
		return &"warm"
	return &"devoted"


func _keeper_at(place: StringName) -> Actor:
	for a in actors:
		if stats.get_primary(a, Stat.ROLE) == Actor.ROLE_KEEPER and stats.get_primary(a, Stat.PLACE) == place:
			return a
	return null


func _open_press_by(a: Actor) -> Demand:
	for d in demands:
		if d.kind == Demand.PRESS and d.requester == a and not d.satisfied:
			return d
	return null


func _open_press_on(t: Actor) -> Demand:
	for d in demands:
		if d.kind == Demand.PRESS and d.target == t and not d.satisfied:
			return d
	return null


func _has_open_aid(victim: Actor) -> bool:
	for d in demands:
		if d.kind == Demand.AID and d.requester == victim and not d.satisfied:
			return true
	return false


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
		if stats.get_primary(a, Stat.ROLE) == role:
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
	var role: StringName = stats.get_primary(a, Stat.ROLE)
	var coin: int = stats.get_primary(a, Stat.COIN)
	match role:
		Actor.ROLE_CONSUMER:
			var tag := "seeking work" if _has_open_employment_demand(a) else _hunger_word(a)
			return "%s · %dc" % [tag, coin]
		Actor.ROLE_FARM_WORKER:
			var willingness: float = stats.get_primary(a, Stat.WILLINGNESS)
			if willingness <= Tune.QUIT_THRESHOLD:
				return "farm worker · QUIT (demoralised) · %dc" % coin
			return "farm worker · %s · will %d · %dc" % [_hunger_word(a), int(willingness), coin]
		Actor.ROLE_MERCHANT:
			var food: int = stats.get_primary(a, Stat.FOOD)
			return "merchant · %d food · %dc" % [food, coin]
		Actor.ROLE_PRODUCER:
			var food: int = stats.get_primary(a, Stat.FOOD)
			var producing_ticks_left: int = stats.get_primary(a, Stat.PRODUCING_TICKS_LEFT)
			var hands := "%d worker(s)" % a.workers.size()
			if producing_ticks_left > 0 and not _producer_can_work(a):
				return "STALLED — workers quit · %d food · %dc · %s" % [food, coin, hands]
			if producing_ticks_left > 0:
				return "producing (%d left) · %d food · %dc · %s" % [producing_ticks_left, food, coin, hands]
			return "producer · %d food · %dc · %s" % [food, coin, hands]
		_:
			return "idle"


func _hunger_word(a: Actor) -> String:
	var hunger: float = stats.get_primary(a, Stat.HUNGER)
	if hunger >= Tune.HUNGER_MAX:
		return "STARVING"
	if _has_open_food_demand(a):
		return "seeking food"
	return "fed" if hunger < Tune.HUNGER_NEED_THRESHOLD else "hungry"
