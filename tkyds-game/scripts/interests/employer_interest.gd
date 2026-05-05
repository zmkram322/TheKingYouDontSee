class_name EmployerInterest
extends Interest

@export var desired_workers: int = 2

func connect_to_bus() -> void:
	pass    # LaborMarket pulls open positions on open_market.

func disconnect_from_bus() -> void:
	pass
	# Phase 3+ cleanup clause:
	# if there is a still-ACTIVE contract for an employer, mark it BREACHED here.

# What work happens here is sourced from the plot's WorkPattern, the same
# lookup path WorkingInterest uses. v0 assumes one ProductionInterest /
# one plot per employer; when an employer owns multiple plots the contract
# will need to specify which one.
func resolve_work_pattern() -> WorkPattern:
	if owner == null:
		return null
	var prod := owner.find_interest(ProductionInterest) as ProductionInterest
	if prod == null or prod.plot == null:
		return null
	return prod.plot.work_pattern

func filled_positions() -> int:
	return employees().size()

# Population seam (Section 5.2): "the workers at this employer" is enumerable
# from day one. v0 doesn't aggregate over them, but the cross-actor population
# query primitive (v0.5+) builds on this enumerator.
func employees() -> Array[Actor]:
	var out: Array[Actor] = []
	if owner == null or owner.accounts == null:
		return out
	for c in owner.accounts.contracts:
		if c is LaborContract and c.status == Contract.Status.ACTIVE and c.employer == owner.get_path():
			var w := owner.get_node_or_null(c.worker) as Actor
			if w != null:
				out.append(w)
	return out

func open_positions() -> int:
	return max(0, desired_workers - filled_positions())

# Called by WindowOrchestrator at week's wage settlement step. Walks the
# employer's outstanding Payable accounts and creates+closes a
# WagePaymentActivity per worker.
func settle_outstanding_wages() -> void:
	if owner == null or owner.accounts == null:
		return
	var outstanding: Array = owner.accounts.outstanding_payables()
	if outstanding.is_empty():
		print("    %s.EmployerInterest.settle_outstanding_wages() — nothing to settle" % owner.actor_id)
		return
	print("    %s.EmployerInterest.settle_outstanding_wages() — settling %d payable(s)" %
		[owner.actor_id, outstanding.size()])
	for entry in outstanding:
		var counterparty: StringName = entry["counterparty"]
		var amount: float = entry["amount"]
		var worker := _find_worker_by_id(counterparty)
		if worker == null:
			push_error("EmployerInterest: cannot resolve worker %s for payment" % counterparty)
			continue
		var pay_act := WagePaymentActivity.new()
		pay_act.employer = owner
		pay_act.worker = worker
		pay_act.amount = amount
		pay_act.participants = [owner.get_path(), worker.get_path()]
		pay_act.begin(SimClock.current_day)
		pay_act.close(SimClock.current_day)
		owner.accounts.activities.append(pay_act)

func _find_worker_by_id(actor_id: StringName) -> Actor:
	for c in owner.accounts.contracts:
		if c is LaborContract and c.employer == owner.get_path():
			var w := owner.get_node_or_null(c.worker) as Actor
			if w != null and w.actor_id == actor_id:
				return w
	return null
