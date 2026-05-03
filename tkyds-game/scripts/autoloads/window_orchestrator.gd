extends Node

func _ready() -> void:
	SimClock.daily_tick.connect(handle_daily_slot)
	SimClock.weekly_tick.connect(fire_weekly_burst)
	print("[WindowOrchestrator] ready — listening to SimClock.daily_tick and SimClock.weekly_tick")

func handle_daily_slot(slot: int) -> void:
	match slot:
		SimEnums.TimeSlot.MID_MORNING:
			WindowBus.open_work_window()
		SimEnums.TimeSlot.EARLY_EVENING:
			WindowBus.close_work_window()
		_:
			pass

func fire_weekly_burst() -> void:
	print("  [Orchestrator] weekly burst begins")
	WindowBus.fire_wages_due()
	WindowBus.fire_weekly_books_close()
	WindowBus.fire_merchant_restock()
	WindowBus.open_wholesale_market()
	WindowBus.close_wholesale_market()
	WindowBus.open_retail_market()
	WindowBus.close_retail_market()
	WindowBus.open_labor_market()
	WindowBus.close_labor_market()
	print("  [Orchestrator] weekly burst ends")
