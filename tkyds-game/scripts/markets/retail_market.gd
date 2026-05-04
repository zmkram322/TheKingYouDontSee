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

var _supply_offers: Array[SupplyOffer] = []
var _demand_requests: Array[DemandRequest] = []
var _p_star: float = 0.0
var _p_m: float = 0.0

func _ready() -> void:
	print("[Wire] RetailMarket ready (pull-on-open; period_length=%d)" % period_length)

func open_market(tick: int) -> void:
	_supply_offers.clear()
	_demand_requests.clear()
	# Pull supply (merchants)
	for supplier in registered_suppliers:
		var mercantile := supplier.find_interest(MercantileInterest) as MercantileInterest
		if mercantile == null:
			continue
		var offer := mercantile.respond_to_retail_supply_call(self, tick)
		if offer != null and offer.quantity > 0.0:
			_supply_offers.append(offer)

	# Compute equilibrium price from total supply and per-actor demand at P*=1.
	# We need a price to ask demanders. Phase 2 math: P* = (A_total / Q_s)^(1/e_g)
	# where A_total sums isoelastic A across registered demanders.
	var total_supply: float = 0.0
	for offer in _supply_offers:
		total_supply += offer.quantity
	_p_star = _compute_equilibrium_price(total_supply, registered_demanders.size())
	# Merchant markup → final P_m offered to demanders.
	var merchant_interest: MercantileInterest = null
	if not registered_suppliers.is_empty():
		merchant_interest = registered_suppliers[0].find_interest(MercantileInterest) as MercantileInterest
	_p_m = merchant_interest.compute_retail_price(_p_star) if merchant_interest != null else _p_star

	# Pull demand at P_m
	for demander in registered_demanders:
		var grain := demander.find_interest(GrainInterest) as GrainInterest
		if grain == null:
			continue
		var req := grain.respond_to_retail_demand_call(self, _p_m, period_length)
		if req != null and req.quantity > 0.0:
			_demand_requests.append(req)

func clear_market(tick: int) -> void:
	match clearing_strategy:
		ClearingStrategy.PROPORTIONAL:
			_clear_proportional(tick)
		ClearingStrategy.FIFO:
			push_error("RetailMarket: FIFO strategy not implemented in v0")
		_:
			push_error("RetailMarket: unimplemented clearing strategy %d" % clearing_strategy)

func _compute_equilibrium_price(total_supply: float, num_demanders: int) -> float:
	if total_supply <= 0.0 or num_demanders <= 0:
		return 0.0
	var cfg := Goods.config_for(good_id)
	var a_total: float = cfg.a_per_actor_daily * float(period_length) * float(num_demanders)
	return pow(a_total / total_supply, 1.0 / cfg.elasticity)

func _clear_proportional(tick: int) -> void:
	var event := MarketClearingEvent.new()
	event.tick = tick
	event.market_name = StringName(name)
	event.good_id = good_id

	var total_supply: float = 0.0
	for offer in _supply_offers:
		total_supply += offer.quantity
		event.responding_suppliers.append(offer.supplier)
	var total_want: float = 0.0
	for req in _demand_requests:
		total_want += req.quantity
		event.responding_demanders.append(req.demander)

	event.total_supply = total_supply
	event.total_demand = total_want
	event.clearing_price = _p_m

	if total_supply <= 0.0 or total_want <= 0.0:
		last_clearing_event = event
		print("[CLEAR]    RetailMarket — nothing to clear (supply=%.1f, demanders=%d)" %
			[total_supply, _demand_requests.size()])
		return

	# Single-merchant v0 — supply-side bookkeeping points to one merchant.
	var merchant: Actor = registered_suppliers[0] if not registered_suppliers.is_empty() else null
	var merchant_interest := merchant.find_interest(MercantileInterest) as MercantileInterest
	var unit_cost: float = merchant_interest.wholesale_cost_per_unit if merchant_interest != null else 1.0

	print("[CLEAR]    RetailMarket — supply=%.1f, P*=%.2f, P_m=%.2f" % [total_supply, _p_star, _p_m])

	# Per-buyer allocation: proportional, then capped by affordability (coin/P_m).
	for req in _demand_requests:
		var buyer := get_node_or_null(req.demander) as Actor
		if buyer == null:
			continue
		var supply_share: float = total_supply * (req.quantity / total_want)
		var affordable: float = buyer.accounts.cash() / max(_p_m, 0.001)
		var received: float = min(req.quantity, min(supply_share, affordable))
		if received <= 0.0:
			_record_buyer_clearing(buyer, req.quantity, 0.0)
			continue

		var sale := RetailPurchaseActivity.new()
		sale.merchant = merchant
		sale.buyer = buyer
		sale.good_id = good_id
		sale.quantity = received
		sale.unit_price = _p_m
		sale.unit_cost_basis = unit_cost
		sale.participants = [merchant.get_path(), buyer.get_path()]
		sale.begin(tick)
		if sale.close(tick):
			merchant.accounts.activities.append(sale)
		_record_buyer_clearing(buyer, req.quantity, received)
		if affordable < req.quantity:
			print("    %s: wanted %.1f, could afford %.1f, received %.1f" %
				[buyer.actor_id, req.quantity, affordable, received])

	last_clearing_event = event

func _record_buyer_clearing(buyer: Actor, wanted: float, received: float) -> void:
	var grain := buyer.find_interest(GrainInterest) as GrainInterest
	if grain != null:
		grain.record_clearing(wanted, received)
