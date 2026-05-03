class_name RetailMarket
extends Market

@export var good_id: StringName = &"grain"

enum ClearingStrategy {
	PROPORTIONAL,
	FIFO,
	SUPPLY_LADDER,
	MARKET_PERCEPTION,
	CHARISMA_FAVOR,
	BARTERING,
}

@export var clearing_strategy: ClearingStrategy = ClearingStrategy.PROPORTIONAL

func _ready() -> void:
	WindowBus.retail_market_closed.connect(clear)
	print("[Wire] RetailMarket.clear ← WindowBus.retail_market_closed")

func compute_equilibrium_price(_good_id: StringName) -> float:
	var total_supply: float = 0.0
	for actor_path in supply_pool.keys():
		total_supply += float(supply_pool[actor_path])
	if total_supply <= 0.0:
		return 0.0

	var cfg := Goods.config_for(_good_id)
	var a_total: float = 0.0
	for actor_path in demand_pool.keys():
		a_total += cfg.a_per_actor_daily * 7.0    # weekly aggregation; days=7 in v0
	return pow(a_total / total_supply, 1.0 / cfg.elasticity)

func clear() -> void:
	match clearing_strategy:
		ClearingStrategy.PROPORTIONAL:
			_clear_proportional()
		ClearingStrategy.FIFO:
			_clear_fifo()
		_:
			push_error("RetailMarket: unimplemented clearing strategy %d" % clearing_strategy)

func _clear_proportional() -> void:
	var total_supply: float = 0.0
	for actor_path in supply_pool.keys():
		total_supply += float(supply_pool[actor_path])

	if total_supply <= 0.0 or demand_pool.is_empty():
		print("[CLEAR]    RetailMarket.clear() — nothing to clear (supply=%.1f, demanders=%d)" % [total_supply, demand_pool.size()])
		supply_pool.clear()
		demand_pool.clear()
		return

	# Single-merchant v0: one supplier
	var merchant_path: NodePath = supply_pool.keys()[0]
	var merchant := get_node(merchant_path) as Actor
	var merchant_interest := merchant.find_interest(MercantileInterest) as MercantileInterest

	var p_star: float = compute_equilibrium_price(good_id)
	var p_m: float = merchant_interest.compute_retail_price(p_star)
	print("[CLEAR]    RetailMarket.clear() — supply=%.1f, P*=%.2f, P_m=%.2f" % [total_supply, p_star, p_m])

	# Per-actor demand resolution
	var actor_wants: Dictionary = {}
	var total_want: float = 0.0
	for actor_path in demand_pool.keys():
		var actor := get_node(actor_path) as Actor
		var gi := actor.find_interest(GrainInterest) as GrainInterest
		if gi == null:
			continue
		gi.decay_carried_demand()
		var this_week: float = gi.compute_demand_at_price(p_m, 7)
		var want: float = this_week + gi.outstanding_demand
		actor_wants[actor_path] = want
		total_want += want

	if total_want <= 0.0:
		print("[CLEAR]    RetailMarket.clear() — no demand expressed")
		supply_pool.clear()
		demand_pool.clear()
		return

	# Allocate proportionally, cap by affordability per actor
	for actor_path in actor_wants.keys():
		var actor := get_node(actor_path) as Actor
		var gi := actor.find_interest(GrainInterest) as GrainInterest
		var want: float = actor_wants[actor_path]
		var supply_share: float = total_supply * (want / total_want)
		var affordable: float = float(actor.accounts.coin) / max(p_m, 0.001)
		var received: float = min(want, min(supply_share, affordable))
		var coin_paid: int = int(round(received * p_m))
		var grain_received: int = int(round(received))

		actor.accounts.inventory[good_id] = actor.accounts.inventory.get(good_id, 0) + grain_received
		actor.accounts.coin -= coin_paid
		merchant.accounts.inventory[good_id] = merchant.accounts.inventory.get(good_id, 0) - grain_received
		merchant.accounts.coin += coin_paid

		if affordable < want:
			print("    %s: wanted %.1f, could afford %.1f, received %.1f. %.1f outstanding." %
				[actor.actor_id, want, affordable, received, max(0.0, want - received)])
		else:
			print("    %s: wanted %.1f, received %.1f. %.1f outstanding." %
				[actor.actor_id, want, received, max(0.0, want - received)])

		gi.record_clearing(want, received)

	# Leftover stays with merchant inventory (carried across weeks)
	var allocated: float = 0.0
	for actor_path in actor_wants.keys():
		allocated += min(actor_wants[actor_path], total_supply * (actor_wants[actor_path] / total_want))
	var leftover: float = total_supply - allocated
	if leftover > 0.5:
		print("[CLEAR]    leftover with merchant: %.1f %s" % [leftover, good_id])

	supply_pool.clear()
	demand_pool.clear()

func _clear_fifo() -> void:
	push_error("RetailMarket: FIFO strategy not implemented in v0")
