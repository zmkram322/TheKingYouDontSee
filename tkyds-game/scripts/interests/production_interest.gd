class_name ProductionInterest
extends Interest

@export var plot: LandPlot
var labor_market: LaborMarket
var wholesale_market: WholesaleMarket
@export var desired_workers: int = 2

func post_jobs(land_owner: LandOwner) -> void:
	var open_positions := desired_workers
	print("    %s.ProductionInterest.post_jobs() — open_positions=%d" % [land_owner.actor_id, open_positions])
	if labor_market != null:
		labor_market.take_demand(land_owner, open_positions)

func send_grain_to_wholesale(land_owner: LandOwner) -> void:
	print("    %s.ProductionInterest.send_grain_to_wholesale() — emit grain supply" % land_owner.actor_id)
	if wholesale_market != null:
		wholesale_market.take_supply(land_owner, 0)
