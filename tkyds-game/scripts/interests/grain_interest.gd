class_name GrainInterest
extends Interest

var retail_market: RetailMarket
@export var daily_demand: int = 2

var outstanding_demand: int = 0

func place_grain_order(actor: Actor) -> void:
	outstanding_demand += daily_demand
	print("    %s.GrainInterest.place_grain_order() — +%d grain demand (outstanding=%d)" % [actor.actor_id, daily_demand, outstanding_demand])
	if retail_market != null:
		retail_market.take_demand(actor, daily_demand)

func record_receipt(qty: int) -> void:
	outstanding_demand = max(0, outstanding_demand - qty)
	print("    GrainInterest.record_receipt(%d) — outstanding_demand now %d" % [qty, outstanding_demand])
