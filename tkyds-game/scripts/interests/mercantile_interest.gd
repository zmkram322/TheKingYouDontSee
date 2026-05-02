class_name MercantileInterest
extends Interest

var wholesale_market: WholesaleMarket
var retail_market: RetailMarket
@export var good_id: StringName = &"grain"
@export var target_inventory: int = 60

func place_buy_order_at_wholesale(merchant: Merchant) -> void:
	var deficit := target_inventory
	print("    %s.MercantileInterest.place_buy_order_at_wholesale() — emit demand for %d %s" % [merchant.actor_id, deficit, good_id])
	if wholesale_market != null:
		wholesale_market.take_demand(merchant, deficit)

func send_inventory_to_retail(merchant: Merchant) -> void:
	print("    %s.MercantileInterest.send_inventory_to_retail() — emit %s supply to RetailMarket" % [merchant.actor_id, good_id])
	if retail_market != null:
		retail_market.take_supply(merchant, 0)
