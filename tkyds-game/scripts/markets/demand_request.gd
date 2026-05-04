class_name DemandRequest
extends Resource

# Returned by demanders from respond_to_demand_call(). For wholesale this is
# the merchant's restock target; for retail it's a per-actor quantity-want at
# the offered price, computed via isoelastic demand.

@export var demander: NodePath
@export var quantity: float = 0.0
@export var max_price: float = -1.0      # -1 = no ceiling

static func make(demander_: NodePath, quantity_: float, max_price_: float = -1.0) -> DemandRequest:
	var d := DemandRequest.new()
	d.demander = demander_
	d.quantity = quantity_
	d.max_price = max_price_
	return d
