class_name WholesaleMarket
extends Market

@export var good_id: StringName = &"grain"

func _ready() -> void:
	WindowBus.wholesale_market_closed.connect(clear)
	print("[Wire] WholesaleMarket.clear ← WindowBus.wholesale_market_closed")

func compute_clearing_price() -> float:
	# v0: single producer. Phase 3+ multi-producer needs aggregation strategy.
	var producers: Array = supply_pool.keys()
	if producers.is_empty():
		return 0.0
	var supplier := get_node(producers[0]) as Actor
	var production := supplier.find_interest(ProductionInterest) as ProductionInterest
	if production == null:
		return 0.0
	return production.weekly_cost_basis * (1.0 + production.compute_supplier_delta())

func clear() -> void:
	var total_supply: int = 0
	for actor_path in supply_pool.keys():
		total_supply += int(supply_pool[actor_path])
	var total_demand: int = 0
	for actor_path in demand_pool.keys():
		total_demand += int(demand_pool[actor_path])

	if total_supply == 0 or total_demand == 0:
		print("[CLEAR]    WholesaleMarket.clear() — nothing to clear (supply=%d, demand=%d)" % [total_supply, total_demand])
		demand_pool.clear()
		return

	var price: float = compute_clearing_price()
	print("[CLEAR]    WholesaleMarket.clear() — supply=%d, demand=%d, price=%.2f" % [total_supply, total_demand, price])

	# Proportional allocations per demander (capped by demand and by coin budget)
	var allocations: Dictionary = {}
	for demander_path in demand_pool.keys():
		var my_demand: int = int(demand_pool[demander_path])
		var raw: int = int(floor(float(my_demand) * float(total_supply) / float(total_demand)))
		var capped_by_demand: int = min(raw, my_demand)
		var demander := get_node(demander_path) as Actor
		var coin_cap: int = int(floor(float(demander.accounts.coin) / max(price, 0.001)))
		allocations[demander_path] = min(capped_by_demand, coin_cap)

	# Transfer grain + coin
	for demander_path in allocations.keys():
		var qty: int = allocations[demander_path]
		if qty == 0:
			continue
		var demander := get_node(demander_path) as Actor
		var total_paid: int = int(round(float(qty) * price))
		demander.accounts.inventory[good_id] = demander.accounts.inventory.get(good_id, 0) + qty
		demander.accounts.coin -= total_paid

		# Distribute payment to suppliers proportionally to their share of total_supply
		for supplier_path in supply_pool.keys():
			var supplier_share: float = float(supply_pool[supplier_path]) / float(total_supply)
			var supplier_qty: int = int(round(float(qty) * supplier_share))
			var supplier_payment: int = int(round(float(supplier_qty) * price))
			var supplier := get_node(supplier_path) as Actor
			supplier.accounts.coin += supplier_payment
			supplier.accounts.inventory[good_id] = supplier.accounts.inventory.get(good_id, 0) - supplier_qty
			# Track this supply pool entry shrinkage so leftover stays accurate
			supply_pool[supplier_path] = int(supply_pool[supplier_path]) - supplier_qty
			print("    %s sold %d %s to %s for %d coin" % [supplier.actor_id, supplier_qty, good_id, demander.actor_id, supplier_payment])

		# Section 2 amendment: write per-unit acquisition cost back to merchant
		var merchant_interest := demander.find_interest(MercantileInterest) as MercantileInterest
		if merchant_interest != null:
			merchant_interest.wholesale_cost_per_unit = price

	# Leftover supply (from floor-rounding) stays in pool; clear demand
	var leftover: int = 0
	for actor_path in supply_pool.keys():
		leftover += int(supply_pool[actor_path])
	if leftover > 0:
		print("[CLEAR]    %d %s remained in supply pool (floor-rounding)" % [leftover, good_id])
	# Strip out zero-balance suppliers so the dict stays tidy
	for actor_path in supply_pool.keys():
		if int(supply_pool[actor_path]) <= 0:
			supply_pool.erase(actor_path)
	demand_pool.clear()
