class_name WorkingInterest
extends Interest

var labor_market: LaborMarket

func look_for_work(worker: Worker) -> void:
	if worker.work_state != SimEnums.WorkState.IDLE:
		return
	print("    %s.WorkingInterest.look_for_work() — offering self to LaborMarket" % worker.actor_id)
	if labor_market != null:
		labor_market.take_supply(worker, 1)

func do_one_work_slot(worker: Worker) -> void:
	if worker.work_state != SimEnums.WorkState.WORKING:
		return
	print("    %s.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory" % worker.actor_id)

func hand_grain_to_owner_and_bill(worker: Worker) -> void:
	if worker.active_contract == null:
		return
	print("    %s.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)" % worker.actor_id)
