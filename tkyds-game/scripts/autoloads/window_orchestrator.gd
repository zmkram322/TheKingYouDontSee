extends Node

# Activity-initiator. The weekly burst is a structural sequence of direct
# market and interest calls — coordination ordering is enforced by call
# order, not by signal-emit order (per Phase 2.5 directive Section 7.2).

var _region: Region = null

func _ready() -> void:
	SimClock.daily_tick.connect(handle_daily_slot)
	SimClock.weekly_tick.connect(fire_weekly_burst)
	print("[WindowOrchestrator] ready — listening to SimClock.daily_tick and SimClock.weekly_tick")

func bind_region(region: Region) -> void:
	_region = region

func handle_daily_slot(slot: int) -> void:
	match slot:
		SimEnums.TimeSlot.MID_MORNING:
			WindowBus.open_work_window()
		SimEnums.TimeSlot.EARLY_EVENING:
			WindowBus.close_work_window()
		_:
			pass

func fire_weekly_burst() -> void:
	if _region == null:
		push_error("WindowOrchestrator.fire_weekly_burst: no region bound")
		return
	print("  [Orchestrator] weekly burst begins")
	var tick: int = SimClock.current_day

	# Step 1 — wage settlement: each employer pays outstanding payables.
	for actor in _region.actors:
		var ei := actor.find_interest(EmployerInterest) as EmployerInterest
		if ei != null:
			ei.settle_outstanding_wages()

	# Step 2 — wholesale market: pull supply (cost basis = books query) +
	# pull demand (merchant restock); clear creates WholesaleSaleActivity per match.
	var wholesale := _region.wholesale_markets.get(&"grain", null) as WholesaleMarket
	if wholesale != null:
		wholesale.open_market(tick)
		wholesale.clear_market(tick)

	# Step 3 — retail market: pull supply, compute P_m, pull demand at P_m, clear.
	var retail := _region.retail_markets.get(&"grain", null) as RetailMarket
	if retail != null:
		retail.open_market(tick)
		retail.clear_market(tick)

	# Step 4 — labor market: pull seekers and hirers, clear into LaborContractActivity per match.
	if _region.labor_market != null:
		_region.labor_market.open_market(tick)
		_region.labor_market.clear_market(tick)

	print("  [Orchestrator] weekly burst ends")
