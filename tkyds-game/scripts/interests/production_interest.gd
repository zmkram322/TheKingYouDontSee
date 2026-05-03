class_name ProductionInterest
extends Interest

@export var plot: LandPlot
var wholesale_market: WholesaleMarket

func connect_to_bus() -> void:
	WindowBus.work_window_closed.connect(send_grain_to_wholesale)

func disconnect_from_bus() -> void:
	WindowBus.work_window_closed.disconnect(send_grain_to_wholesale)

func send_grain_to_wholesale() -> void:
	print("    %s.ProductionInterest.send_grain_to_wholesale() — emit grain supply" % owner.actor_id)
	if wholesale_market != null:
		wholesale_market.queue_supply(owner, 0)
