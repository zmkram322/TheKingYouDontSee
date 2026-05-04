class_name SupplyOffer
extends Resource

# Returned by suppliers from respond_to_supply_call(). Cost basis lets the
# market compute clearing price as a query, not a cached field.

@export var supplier: NodePath
@export var quantity: float = 0.0
@export var cost_basis: float = 0.0      # price-per-unit floor (e.g., wages/output for production)

static func make(supplier_: NodePath, quantity_: float, cost_basis_: float) -> SupplyOffer:
	var s := SupplyOffer.new()
	s.supplier = supplier_
	s.quantity = quantity_
	s.cost_basis = cost_basis_
	return s
