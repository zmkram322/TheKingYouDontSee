class_name MercantileInterest
extends Interest

var wholesale_market: WholesaleMarket
var retail_market: RetailMarket
@export var good_id: StringName = &"grain"
@export var target_inventory: int = 60

func connect_to_bus() -> void:
	WindowBus.merchant_restock.connect(place_buy_order_at_wholesale)
	WindowBus.wholesale_market_closed.connect(send_inventory_to_retail)

func disconnect_from_bus() -> void:
	WindowBus.merchant_restock.disconnect(place_buy_order_at_wholesale)
	WindowBus.wholesale_market_closed.disconnect(send_inventory_to_retail)

func place_buy_order_at_wholesale() -> void:
	var deficit := target_inventory
	print("    %s.MercantileInterest.place_buy_order_at_wholesale() — emit demand for %d %s" % [owner.actor_id, deficit, good_id])
	if wholesale_market != null:
		wholesale_market.queue_demand(owner, deficit)

func send_inventory_to_retail() -> void:
	print("    %s.MercantileInterest.send_inventory_to_retail() — emit %s supply to RetailMarket" % [owner.actor_id, good_id])
	if retail_market != null:
		retail_market.queue_supply(owner, 0)
