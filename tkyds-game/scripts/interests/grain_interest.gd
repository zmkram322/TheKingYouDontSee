class_name GrainInterest
extends Interest

var retail_market: RetailMarket
var outstanding_demand: float = 0.0

func connect_to_bus() -> void:
	pass    # RetailMarket pulls demand on open.

func disconnect_from_bus() -> void:
	pass

# Retail demand call: returns this actor's grain demand at the offered price.
# The market typically calls this with its computed P_m. Outstanding (carry-forward)
# demand is added; decay applied on the carry portion.
func respond_to_retail_demand_call(_market: RetailMarket, price: float, days: int) -> DemandRequest:
	decay_carried_demand()
	var this_period: float = compute_demand_at_price(price, days)
	var want: float = this_period + outstanding_demand
	return DemandRequest.make(owner.get_path(), want)

func compute_demand_at_price(price: float, days: int) -> float:
	var cfg := Goods.config_for(&"grain")
	return cfg.a_per_actor_daily * pow(price, -cfg.elasticity) * float(days)

func decay_carried_demand() -> float:
	var cfg := Goods.config_for(&"grain")
	outstanding_demand *= (1.0 - cfg.decay_lambda)
	return outstanding_demand

func record_clearing(wanted: float, received: float) -> void:
	outstanding_demand = max(0.0, wanted - received)
	print("    %s.GrainInterest.record_clearing() — wanted %.1f, received %.1f, %.1f outstanding" %
		[owner.actor_id, wanted, received, outstanding_demand])
