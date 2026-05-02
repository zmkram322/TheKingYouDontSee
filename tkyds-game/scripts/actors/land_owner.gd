class_name LandOwner
extends Actor

@export var production_interest: ProductionInterest

func _wire_signals() -> void:
	super._wire_signals()
	WindowBus.labor_market_opened.connect(post_open_jobs)
	print("[Wire] %s.post_open_jobs ← WindowBus.labor_market_opened" % actor_id)
	WindowBus.work_window_closed.connect(send_supply_to_wholesale)
	print("[Wire] %s.send_supply_to_wholesale ← WindowBus.work_window_closed" % actor_id)
	WindowBus.wages_due.connect(pay_outstanding_wages)
	print("[Wire] %s.pay_outstanding_wages ← WindowBus.wages_due" % actor_id)

func post_open_jobs() -> void:
	if production_interest != null:
		production_interest.post_jobs(self)

func send_supply_to_wholesale() -> void:
	if production_interest != null:
		production_interest.send_grain_to_wholesale(self)

func pay_outstanding_wages() -> void:
	var n := accounts.payables.size() if accounts != null else 0
	print("    %s.pay_outstanding_wages() — walk %d payable(s); decrement coin; pay each worker; clear payables" % [actor_id, n])
