class_name GrainInterest
extends Interest

var retail_market: RetailMarket
var outstanding_demand: float = 0.0

func connect_to_bus() -> void:
	WindowBus.retail_market_opened.connect(register_for_retail_clearing)

func disconnect_from_bus() -> void:
	WindowBus.retail_market_opened.disconnect(register_for_retail_clearing)

func register_for_retail_clearing() -> void:
	if retail_market == null:
		return
	retail_market.queue_demand(owner, 0)
	print("    %s.GrainInterest.register_for_retail_clearing() — registered as grain demander" % owner.actor_id)

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
