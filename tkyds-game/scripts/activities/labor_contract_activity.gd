class_name LaborContractActivity
extends Activity

# Persistent (long-running). Records the moment a contract was struck. No
# financial entries on creation; downstream WorkDayActivity / WagePaymentActivity
# write the actual flow. The contract Resource is appended to both parties'
# `accounts.contracts` at on_close.
#
# Wage policy seam: v0 locks wage_per_slot at contract creation using the
# scarcity-and-skill snapshot at that moment. A worker whose skills grow
# during a multi-week contract is paid at the strike-time rate, which makes
# the contract a real tradable object and surfaces labor arbitrage as a
# deliberate dynamic. Phase 3+ may add RECOMPUTED_AT_SETTLEMENT as a sibling
# policy where the rate is recomputed at each WagePaymentActivity.

enum WagePolicy { LOCKED_AT_CONTRACT }

var employer: Actor
var worker: Actor
@export var job_id: StringName = &"farming"
@export var current_supply: int = 0     # labor scarcity at contract time
@export var wage_policy: WagePolicy = WagePolicy.LOCKED_AT_CONTRACT

# Created at on_close — the canonical contract reference.
var contract: LaborContract

func _init() -> void:
	activity_type = &"LaborContractActivity"

func on_close() -> bool:
	if employer == null or worker == null:
		return false

	var job := Jobs.config_for(job_id)
	var rate: float
	match wage_policy:
		WagePolicy.LOCKED_AT_CONTRACT:
			rate = WageCalculator.calculate_wage_per_slot(employer, worker, job, current_supply)
		_:
			push_error("LaborContractActivity: wage_policy %d not implemented" % wage_policy)
			return false

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
