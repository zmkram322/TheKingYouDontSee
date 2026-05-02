class_name Worker
extends Actor

@export var work_state: SimEnums.WorkState = SimEnums.WorkState.IDLE
@export var active_contract: LaborContract
@export var working_interest: WorkingInterest

func _wire_signals() -> void:
	super._wire_signals()
	WindowBus.labor_market_opened.connect(seek_work)
	print("[Wire] %s.seek_work ← WindowBus.labor_market_opened" % actor_id)
	WindowBus.work_window_opened.connect(begin_working)
	print("[Wire] %s.begin_working ← WindowBus.work_window_opened" % actor_id)
	WindowBus.work_window_closed.connect(deliver_grain_and_bill)
	print("[Wire] %s.deliver_grain_and_bill ← WindowBus.work_window_closed" % actor_id)

func seek_work() -> void:
	if working_interest != null:
		working_interest.look_for_work(self)

func begin_working() -> void:
	if active_contract != null:
		work_state = SimEnums.WorkState.WORKING
		print("    %s.work_state → WORKING" % actor_id)

func deliver_grain_and_bill() -> void:
	if working_interest != null:
		working_interest.hand_grain_to_owner_and_bill(self)
	if active_contract != null:
		work_state = SimEnums.WorkState.EMPLOYED_NOT_WORKING
		print("    %s.work_state → EMPLOYED_NOT_WORKING" % actor_id)

func tick_each_slot(slot: int) -> void:
	super.tick_each_slot(slot)
	if working_interest != null:
		working_interest.do_one_work_slot(self)
