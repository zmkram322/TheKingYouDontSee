class_name WorkingInterest
extends Interest

@export var work_state: SimEnums.WorkState = SimEnums.WorkState.IDLE
var labor_market: LaborMarket
var slots_worked_today: int = 0

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
	if work_state != SimEnums.WorkState.WORKING: return
	if slot < SimEnums.TimeSlot.MID_MORNING or slot > SimEnums.TimeSlot.LATE_AFTERNOON: return
	slots_worked_today += 1
	print("    %s.WorkingInterest.do_one_work_slot() — slot %d worked (today %d)" %
		[owner.actor_id, slot, slots_worked_today])

func deliver_grain_and_bill() -> void:
	var contract := current_contract()
	if contract == null: return
	var employer := owner.get_node(contract.employer) as Actor
	# Produced grain = slots worked today × 1 grain/slot. Goes straight to employer.
	# Worker's personal inventory (retail purchases, etc.) stays untouched.
	var grain_produced: int = slots_worked_today
	employer.accounts.inventory[&"grain"] = employer.accounts.inventory.get(&"grain", 0) + grain_produced
	employer.accounts.weekly_outputs[&"grain"] = employer.accounts.weekly_outputs.get(&"grain", 0) + grain_produced
	# Accumulate Payable
	var payable := find_or_create_payable_for(employer, contract, owner)
	payable.slots_worked += slots_worked_today
	print("    %s.WorkingInterest.deliver_grain_and_bill() — %d grain → %s; +%d slots on payable (now %d)" %
		[owner.actor_id, grain_produced, employer.actor_id, slots_worked_today, payable.slots_worked])
	slots_worked_today = 0
	work_state = SimEnums.WorkState.EMPLOYED_NOT_WORKING
	print("    %s.work_state → EMPLOYED_NOT_WORKING" % owner.actor_id)

func find_or_create_payable_for(employer: Actor, _contract: LaborContract, worker: Actor) -> Payable:
	# Contract is a Resource, not a Node — payable.contract stays empty NodePath at v0.
	# v0 settlement reads rate fresh via WageCalculator, so contract reference isn't needed yet.
	var worker_path := worker.get_path()
	for p in employer.accounts.payables:
		if p is Payable and p.worker == worker_path:
			return p
	var fresh := Payable.new()
	fresh.worker = worker_path
	fresh.slots_worked = 0
	employer.accounts.payables.append(fresh)
	return fresh
