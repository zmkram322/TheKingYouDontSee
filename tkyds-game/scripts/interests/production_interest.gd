class_name ProductionInterest
extends Interest

@export var plot: LandPlot
@export var good_id: StringName = &"grain"
@export var current_delta: float = 0.0
var wholesale_market: WholesaleMarket
var weekly_cost_basis: float = 0.0

func connect_to_bus() -> void:
	WindowBus.weekly_books_close.connect(settle_weekly_production)

func disconnect_from_bus() -> void:
	WindowBus.weekly_books_close.disconnect(settle_weekly_production)

func settle_weekly_production() -> void:
	var costs: int = 0
	for v in owner.accounts.weekly_costs.values():
		costs += int(v)
	var output: int = owner.accounts.weekly_outputs.get(good_id, 0)
	if output > 0:
		weekly_cost_basis = float(costs) / float(output)
	else:
		weekly_cost_basis = 0.0
	print("    %s.ProductionInterest.settle_weekly_production() — costs=%d, output=%d %s, cost_basis=%.2f" %
		[owner.actor_id, costs, output, good_id, weekly_cost_basis])
	if output > 0 and wholesale_market != null:
		wholesale_market.queue_supply(owner, output)
	owner.accounts.weekly_costs.clear()
	owner.accounts.weekly_outputs.clear()

func compute_supplier_delta() -> float:
	return current_delta
