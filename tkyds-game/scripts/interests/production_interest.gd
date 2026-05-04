class_name ProductionInterest
extends Interest

@export var plot: LandPlot
@export var good_id: StringName = &"grain"
@export var current_delta: float = 0.0
var wholesale_market: WholesaleMarket

func connect_to_bus() -> void:
	pass    # No coordination signals needed — markets pull-on-open.

func disconnect_from_bus() -> void:
	pass

# Called by WholesaleMarket.open_market(tick). Cost basis is computed as a
# FinancialBook period query — never cached. The cost-basis bug is structurally
# eliminated: the books are always current, and order-of-call within the burst
# does not affect the answer.
func respond_to_supply_call(market: WholesaleMarket, tick: int) -> SupplyOffer:
	var fb: FinancialBook = owner.accounts.financial()
	if fb == null:
		return SupplyOffer.make(owner.get_path(), 0.0, 0.0)
	var period_start: int = max(0, tick - market.period_length)
	# Production_Output_Value is credit-natural — balance reads as the natural
	# positive total output value over the window.
	var output: float = fb.balance(Accounts.A_PRODUCTION_OUTPUT_VALUE, period_start, tick)
	# Wages_Expense is debit-natural — balance reads negative cumulative; negate.
	var wages: float = -fb.balance(Accounts.A_WAGES_EXPENSE, period_start, tick)
	var cost_basis: float = (wages / output) if output > 0.0 else 0.0
	# Quantity offered = inventory of good_id available right now (running balance).
	var quantity: float = owner.accounts.inventory_of(good_id)
	print("    %s.ProductionInterest.respond_to_supply_call — output=%.0f, wages=%.0f, cost_basis=%.2f, qty_offered=%.0f" %
		[owner.actor_id, output, wages, cost_basis, quantity])
	return SupplyOffer.make(owner.get_path(), quantity, cost_basis)

func compute_supplier_delta() -> float:
	return current_delta
