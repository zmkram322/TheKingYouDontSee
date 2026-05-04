class_name LaborContractActivity
extends Activity

# Persistent (long-running). Records the moment a contract was struck. No
# financial entries on creation; downstream WorkDayActivity / WagePaymentActivity
# write the actual flow. The contract Resource is appended to both parties'
# `accounts.contracts` at on_close; wage_per_slot is locked at that moment
# using current scarcity.

var employer: Actor
var worker: Actor
@export var job_id: StringName = &"farming"
@export var current_supply: int = 0     # labor scarcity at contract time

# Created at on_close — the canonical contract reference.
var contract: LaborContract

func _init() -> void:
	activity_type = &"LaborContractActivity"

func on_close() -> bool:
	if employer == null or worker == null:
		return false

	var job := Jobs.config_for(job_id)
	var rate: float = WageCalculator.calculate_wage_per_slot(employer, worker, job, current_supply)

	contract = LaborContract.new()
	contract.employer = employer.get_path()
	contract.worker = worker.get_path()
	contract.wage_per_slot = rate
	contract.agreed_at_week = (closed_tick - 1) / 7 + 1
	contract.status = Contract.Status.ACTIVE

	worker.accounts.contracts.append(contract)
	employer.accounts.contracts.append(contract)
	print("[CLEAR]      contract: %s ↔ %s, week=%d, wage_per_slot=%.2f" %
		[worker.actor_id, employer.actor_id, contract.agreed_at_week, rate])
	return true
