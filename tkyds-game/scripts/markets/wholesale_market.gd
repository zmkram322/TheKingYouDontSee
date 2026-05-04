class_name WholesaleMarket
extends Market

@export var good_id: StringName = &"grain"

var _supply_offers: Array[SupplyOffer] = []
var _demand_requests: Array[DemandRequest] = []

func _ready() -> void:
	print("[Wire] WholesaleMarket ready (pull-on-open; period_length=%d)" % period_length)

func open_market(tick: int) -> void:
	_supply_offers.clear()
	_demand_requests.clear()
	# Pull supply
	for supplier in registered_suppliers:
		var production := supplier.find_interest(ProductionInterest) as ProductionInterest
		if production == null:
			continue
		var offer := production.respond_to_supply_call(self, tick)
		if offer != null and offer.quantity > 0.0:
			_supply_offers.append(offer)
	# Pull demand
	for demander in registered_demanders:
		var mercantile := demander.find_interest(MercantileInterest) as MercantileInterest
		if mercantile == null:
			continue
		var req := mercantile.respond_to_wholesale_demand_call(self, tick)
		if req != null and req.quantity > 0.0:
			_demand_requests.append(req)

func clear_market(tick: int) -> void:
	var event := MarketClearingEvent.new()
	event.tick = tick
	event.market_name = StringName(name)
	event.good_id = good_id

	var total_supply: float = 0.0
	var weighted_cost_basis_sum: float = 0.0
	for offer in _supply_offers:
		total_supply += offer.quantity
		weighted_cost_basis_sum += offer.cost_basis * offer.quantity
		event.responding_suppliers.append(offer.supplier)
	for supplier in registered_suppliers:
		var path := supplier.get_path()
		var found := false
		for offer in _supply_offers:
			if offer.supplier == path:
				found = true
				break
		if not found:
			event.non_responding_suppliers.append(path)

	var total_demand: float = 0.0
	for req in _demand_requests:
		total_demand += req.quantity
		event.responding_demanders.append(req.demander)

	event.total_supply = total_supply
	event.total_demand = total_demand

	if total_supply <= 0.0 or total_demand <= 0.0:
		event.clearing_price = 0.0
		last_clearing_event = event
		print("[CLEAR]    WholesaleMarket — nothing to clear (supply=%.1f, demand=%.1f)" % [total_supply, total_demand])
		return

	# Weighted-avg cost basis × (1 + delta) — for v0 single supplier this
	# collapses to that supplier's cost_basis.
	var cost_basis: float = weighted_cost_basis_sum / total_supply
	# Use first supplier's delta (v0 single-supplier); phase 3+ aggregates.
	var delta: float = 0.0
	if not registered_suppliers.is_empty():
		var p := registered_suppliers[0].find_interest(ProductionInterest) as ProductionInterest
		if p != null:
			delta = p.compute_supplier_delta()
	var price: float = cost_basis * (1.0 + delta)
	event.clearing_price = price
	print("[CLEAR]    WholesaleMarket — supply=%.0f, demand=%.0f, price=%.2f" % [total_supply, total_demand, price])

	# Demand-side ceiling check: drop any demand with max_price < price.
	var effective_demand: Array[DemandRequest] = []
	var effective_total_demand: float = 0.0
	for req in _demand_requests:
		if req.max_price >= 0.0 and price > req.max_price:
			print("    %s walks away — wholesale ask %.2f exceeds ceiling %.2f" %
				[String(req.demander), price, req.max_price])
			continue
		effective_demand.append(req)
		effective_total_demand += req.quantity

	if effective_total_demand <= 0.0:
		last_clearing_event = event
		return

	# Per-demander allocation: proportional, capped by demand and by demander's
	# coin budget. Then create+close one WholesaleSaleActivity per
	# (supplier, demander) pair.
	for req in effective_demand:
		var demander := get_node_or_null(req.demander) as Actor
		if demander == null:
			continue
		var raw_share: float = floor(req.quantity * total_supply / effective_total_demand)
		var capped_by_demand: float = min(raw_share, req.quantity)
		var coin_cap: float = floor(demander.accounts.cash() / max(price, 0.001))
		var allocated: float = min(capped_by_demand, coin_cap)
		if allocated <= 0.0:
			continue

		# Distribute allocation across suppliers proportional to each supplier's share.
		for offer in _supply_offers:
			var supplier_share: float = offer.quantity / total_supply
			var supplier_qty: float = floor(allocated * supplier_share)
			if supplier_qty <= 0.0:
				continue
			var supplier := get_node_or_null(offer.supplier) as Actor
			if supplier == null:
				continue
			var sale := WholesaleSaleActivity.new()
			sale.producer = supplier
			sale.merchant = demander
			sale.good_id = good_id
			sale.quantity = supplier_qty
			sale.price = price
			sale.participants = [supplier.get_path(), demander.get_path()]
			sale.begin(tick)
			if sale.close(tick):
				supplier.accounts.activities.append(sale)
				# Update merchant's cost basis carrier — used by RetailPurchaseActivity.
				var mi := demander.find_interest(MercantileInterest) as MercantileInterest
				if mi != null:
					mi.wholesale_cost_per_unit = price

	last_clearing_event = event
