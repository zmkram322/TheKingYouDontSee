class_name WorkingInterest
extends Interest

@export var work_state: SimEnums.WorkState = SimEnums.WorkState.IDLE
var labor_market: LaborMarket

func connect_to_bus() -> void:
	WindowBus.labor_market_opened.connect(look_for_work)
	WindowBus.work_window_opened.connect(begin_working)
	WindowBus.work_window_closed.connect(deliver_grain_and_bill)
	SimClock.daily_tick.connect(do_one_work_slot)

func disconnect_from_bus() -> void:
	WindowBus.labor_market_opened.disconnect(look_for_work)
	WindowBus.work_window_opened.disconnect(begin_working)
	WindowBus.work_window_closed.disconnect(deliver_grain_and_bill)
	SimClock.daily_tick.disconnect(do_one_work_slot)
	# Phase 3+ cleanup clause (documented now, not implemented at v0):
	# if there is a still-ACTIVE contract for this worker, mark it BREACHED here.

func current_contract() -> LaborContract:
	if owner == null or owner.accounts == null:
		return null
	for c in owner.accounts.contracts:
		if c is LaborContract and c.worker == owner.get_path() and c.status == Contract.Status.ACTIVE:
			return c
	return null

func look_for_work() -> void:
	if work_state != SimEnums.WorkState.IDLE: return
	print("    %s.WorkingInterest.look_for_work() — offering self to LaborMarket" % owner.actor_id)
	if labor_market != null:
		labor_market.queue_supply(owner, 1)

func begin_working() -> void:
	if current_contract() != null:
		work_state = SimEnums.WorkState.WORKING
		print("    %s.work_state → WORKING" % owner.actor_id)

func do_one_work_slot(slot: int) -> void:
	# Filter internally — only do work during a work-window slot AND when WORKING.
	if work_state != SimEnums.WorkState.WORKING: return
	if slot < SimEnums.TimeSlot.MID_MORNING or slot > SimEnums.TimeSlot.LATE_AFTERNOON: return
	print("    %s.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory" % owner.actor_id)

func deliver_grain_and_bill() -> void:
	if current_contract() == null: return
	print("    %s.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)" % owner.actor_id)
	work_state = SimEnums.WorkState.EMPLOYED_NOT_WORKING
	print("    %s.work_state → EMPLOYED_NOT_WORKING" % owner.actor_id)
