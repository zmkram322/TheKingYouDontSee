class_name WorkingInterest
extends Interest

@export var work_state: SimEnums.WorkState = SimEnums.WorkState.IDLE
var current_day_activity: Activity = null    # FarmingDayActivity or sibling

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

func _resolve_work_pattern(employer: Actor) -> WorkPattern:
	# The plot is the source of truth for what work happens. v0 assumes one
	# ProductionInterest per employer (one plot); when an employer owns
	# multiple plots, the contract will need to specify which one.
	var prod := employer.find_interest(ProductionInterest) as ProductionInterest
	if prod == null or prod.plot == null:
		return null
	return prod.plot.work_pattern

func begin_working() -> void:
	var contract := current_contract()
	if contract == null:
		return
	var employer := owner.get_node(contract.employer) as Actor
	var pattern := _resolve_work_pattern(employer)
	if pattern == null:
		push_error("%s: no work_pattern on employer's plot" % owner.actor_id)
		return

	work_state = SimEnums.WorkState.WORKING
	var day := pattern.create_day_activity() as FarmingDayActivity
	if day == null:
		push_error("%s: pattern[%s] did not yield a FarmingDayActivity-compatible class" %
			[owner.actor_id, pattern.pattern_id])
		work_state = SimEnums.WorkState.EMPLOYED_NOT_WORKING
		return
	day.worker = owner
	day.employer = employer
	day.contract = contract
	day.good_id = pattern.good_id
	day.skill_id = pattern.skill_id
	day.participants = [owner.get_path(), employer.get_path()]
	day.begin(SimClock.current_day)
	current_day_activity = day
	print("    %s.work_state → WORKING (pattern=%s, good=%s)" %
		[owner.actor_id, pattern.pattern_id, pattern.good_id])

func do_one_work_slot(slot: int) -> void:
	if work_state != SimEnums.WorkState.WORKING:
		return
	if slot < SimEnums.TimeSlot.MID_MORNING or slot > SimEnums.TimeSlot.LATE_AFTERNOON:
		return
	if current_day_activity == null:
		return
	var contract := current_contract()
	if contract == null:
		return
	var employer := owner.get_node(contract.employer) as Actor
	var pattern := _resolve_work_pattern(employer)
	if pattern == null:
		return
	var slot_act := pattern.create_slot_activity() as FarmingSlotActivity
	if slot_act == null:
		return
	slot_act.worker = owner
	slot_act.contract = contract
	slot_act.parent_activity_ref = current_day_activity
	slot_act.participants = [owner.get_path()]
	current_day_activity.child_activities.append(slot_act)
	slot_act.begin(SimClock.current_day)
	slot_act.close(SimClock.current_day)
	var slots: int = (current_day_activity as FarmingDayActivity).slots_worked
	print("    %s.WorkingInterest — slot %d worked (today %d)" % [owner.actor_id, slot, slots])

func close_workday() -> void:
	if current_day_activity == null:
		return
	current_day_activity.close(SimClock.current_day)
	owner.accounts.activities.append(current_day_activity)
	current_day_activity = null
	work_state = SimEnums.WorkState.EMPLOYED_NOT_WORKING
	print("    %s.work_state → EMPLOYED_NOT_WORKING" % owner.actor_id)
