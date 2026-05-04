class_name MercantileInterest
extends Interest

var wholesale_market: WholesaleMarket
var retail_market: RetailMarket
@export var good_id: StringName = &"grain"
@export var target_inventory: int = 60
@export var max_wholesale_price: float = 2.0
@export var delta_retail: float = 0.1
@export var min_retail_margin: float = 0.0

# Cost basis carried forward from the most recent wholesale buy. Used by
# RetailPurchaseActivity to recognize COGS on retail sales. v0 single-batch:
# this is the unit cost paid for the current week's inventory.
var wholesale_cost_per_unit: float = 1.0

func connect_to_bus() -> void:
	pass    # Markets pull-on-open via respond_to_demand_call.

func disconnect_from_bus() -> void:
	pass

# Wholesale demand call. Restock-deficit drives the demand quantity; the
# merchant walks away if the offered cost basis exceeds max_wholesale_price.
func respond_to_wholesale_demand_call(_market: WholesaleMarket, _tick: int) -> DemandRequest:
	var on_hand: float = owner.accounts.inventory_of(good_id)
	var deficit: float = max(0.0, float(target_inventory) - on_hand)
	print("    %s.MercantileInterest.respond_to_wholesale_demand_call — on_hand=%.1f, target=%d, deficit=%.1f" %
		[owner.actor_id, on_hand, target_inventory, deficit])
	return DemandRequest.make(owner.get_path(), deficit, max_wholesale_price)

# Retail supply call: merchant offers all on-hand inventory at retail clearing.
func respond_to_retail_supply_call(_market: RetailMarket, _tick: int) -> SupplyOffer:
	var qty: float = owner.accounts.inventory_of(good_id)
	# unit-cost basis = wholesale_cost_per_unit (carried forward from recent buy).
	return SupplyOffer.make(owner.get_path(), qty, wholesale_cost_per_unit)

func compute_retail_price(p_star: float) -> float:
	var clamped_delta: float = max(0.0, delta_retail)
	var unclamped: float = p_star * (1.0 + clamped_delta)
	var floor_price: float = wholesale_cost_per_unit * (1.0 + min_retail_margin)
	return max(floor_price, unclamped)
