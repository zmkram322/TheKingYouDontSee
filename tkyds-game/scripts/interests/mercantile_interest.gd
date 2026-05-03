class_name MercantileInterest
extends Interest

var wholesale_market: WholesaleMarket
var retail_market: RetailMarket
@export var good_id: StringName = &"grain"
@export var target_inventory: int = 60
@export var max_wholesale_price: float = 2.0
@export var delta_retail: float = 0.1
@export var min_retail_margin: float = 0.0
var wholesale_cost_per_unit: float = 0.0

func connect_to_bus() -> void:
	WindowBus.merchant_restock.connect(place_buy_order_at_wholesale)
	WindowBus.wholesale_market_closed.connect(send_inventory_to_retail)

func disconnect_from_bus() -> void:
	WindowBus.merchant_restock.disconnect(place_buy_order_at_wholesale)
	WindowBus.wholesale_market_closed.disconnect(send_inventory_to_retail)

func place_buy_order_at_wholesale() -> void:
	var on_hand: int = owner.accounts.inventory.get(good_id, 0)
	var deficit: int = max(0, target_inventory - on_hand)
	print("    %s.MercantileInterest.place_buy_order_at_wholesale() — on_hand=%d, target=%d, deficit=%d" %
		[owner.actor_id, on_hand, target_inventory, deficit])
	if deficit == 0 or wholesale_market == null:
		return
	var ask: float = wholesale_market.compute_clearing_price()
	if ask > max_wholesale_price:
		print("    %s walks away — wholesale ask %.2f exceeds ceiling %.2f" % [owner.actor_id, ask, max_wholesale_price])
		return
	wholesale_market.queue_demand(owner, deficit)

func send_inventory_to_retail() -> void:
	var qty: int = owner.accounts.inventory.get(good_id, 0)
	print("    %s.MercantileInterest.send_inventory_to_retail() — supplying %d %s to RetailMarket" %
		[owner.actor_id, qty, good_id])
	if retail_market != null and qty > 0:
		retail_market.queue_supply(owner, qty)

func compute_retail_price(p_star: float) -> float:
	var clamped_delta: float = max(0.0, delta_retail)
	var unclamped: float = p_star * (1.0 + clamped_delta)
	var floor_price: float = wholesale_cost_per_unit * (1.0 + min_retail_margin)
	return max(floor_price, unclamped)
