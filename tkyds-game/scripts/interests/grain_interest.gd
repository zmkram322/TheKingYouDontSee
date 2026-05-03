class_name GrainInterest
extends Interest

var retail_market: RetailMarket
@export var daily_demand: int = 2
var outstanding_demand: int = 0

func connect_to_bus() -> void:
	SimClock.daily_tick.connect(_consider_placing_order)

func disconnect_from_bus() -> void:
	SimClock.daily_tick.disconnect(_consider_placing_order)

func _consider_placing_order(slot: int) -> void:
	if slot != SimEnums.TimeSlot.LATE_EVENING: return
	place_grain_order()

func place_grain_order() -> void:
	outstanding_demand += daily_demand
	print("    %s.GrainInterest.place_grain_order() — +%d grain demand (outstanding=%d)" % [owner.actor_id, daily_demand, outstanding_demand])
	if retail_market != null:
		retail_market.queue_demand(owner, daily_demand)

func record_receipt(qty: int) -> void:
	outstanding_demand = max(0, outstanding_demand - qty)
	print("    GrainInterest.record_receipt(%d) — outstanding_demand now %d" % [qty, outstanding_demand])
