class_name Merchant
extends Actor

@export var mercantile_interest: MercantileInterest

func _wire_signals() -> void:
	super._wire_signals()
	WindowBus.merchant_restock.connect(weekly_restock)
	print("[Wire] %s.weekly_restock ← WindowBus.merchant_restock" % actor_id)
	WindowBus.wholesale_market_closed.connect(ship_to_retail)
	print("[Wire] %s.ship_to_retail ← WindowBus.wholesale_market_closed" % actor_id)

func weekly_restock() -> void:
	if mercantile_interest != null:
		mercantile_interest.place_buy_order_at_wholesale(self)

func ship_to_retail() -> void:
	if mercantile_interest != null:
		mercantile_interest.send_inventory_to_retail(self)
