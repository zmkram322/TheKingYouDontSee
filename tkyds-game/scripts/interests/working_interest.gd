class_name WorkingInterest
extends Interest

@export var work_state: SimEnums.WorkState = SimEnums.WorkState.IDLE
var current_day_activity: WorkDayActivity = null

func connect_to_bus() -> void:
	WindowBus.work_window_opened.connect(begin_working)
	WindowBus.work_window_closed.connect(close_workday)
	SimClock.daily_tick.connect(do_one_work_slot)

func disconnect_from_bus() -> void:
	WindowBus.work_window_opened.disconnect(begin_working)
	WindowBus.work_window_closed.disconnect(close_workday)
	SimClock.daily_tick.disconnect(do_one_work_slot)
	# Phase 3+ cleanup clause:
	# if there is a still-ACTIVE contract for this worker, mark it BREACHED here.

func current_contract() -> LaborContract:
	if owner == null or owner.accounts == null:
		return null
	for c in owner.accounts.contracts:
		if c is LaborContract and c.worker == owner.get_path() and c.status == Contract.Status.ACTIVE:
			return c
	return null

# LaborMarket pulls this on open_market. v0: a worker offers themselves if
# they are IDLE (no active contract).
func is_seeking_work() -> bool:
	return work_state == SimEnums.WorkState.IDLE and current_contract() == null

func begin_working() -> void:
	var contract := current_contract()
	if contract == null:
		return
	work_state = SimEnums.WorkState.WORKING
	var employer := owner.get_node(contract.employer) as Actor
	current_day_activity = WorkDayActivity.new()
	current_day_activity.worker = owner
	current_day_activity.employer = employer
	current_day_activity.contract = contract
	current_day_activity.participants = [owner.get_path(), employer.get_path()]
	current_day_activity.begin(SimClock.current_day)
	print("    %s.work_state → WORKING" % owner.actor_id)

func do_one_work_slot(slot: int) -> void:
	if work_state != SimEnums.WorkState.WORKING:
		return
	if slot < SimEnums.TimeSlot.MID_MORNING or slot > SimEnums.TimeSlot.LATE_AFTERNOON:
		return
	if current_day_activity == null:
		return
	var slot_act := WorkSlotActivity.new()
	slot_act.worker = owner
	slot_act.contract = current_day_activity.contract
	slot_act.parent_activity_ref = current_day_activity
	slot_act.participants = [owner.get_path()]
	current_day_activity.child_activities.append(slot_act)
	slot_act.begin(SimClock.current_day)
	slot_act.close(SimClock.current_day)
	print("    %s.WorkingInterest — slot %d worked (today %d)" %
		[owner.actor_id, slot, current_day_activity.slots_worked])

func close_workday() -> void:
	if current_day_activity == null:
		return
	current_day_activity.close(SimClock.current_day)
	owner.accounts.activities.append(current_day_activity)
	current_day_activity = null
	work_state = SimEnums.WorkState.EMPLOYED_NOT_WORKING
	print("    %s.work_state → EMPLOYED_NOT_WORKING" % owner.actor_id)
