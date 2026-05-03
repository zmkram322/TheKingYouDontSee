class_name EmployerInterest
extends Interest

var labor_market: LaborMarket
@export var desired_workers: int = 2

func connect_to_bus() -> void:
	WindowBus.labor_market_opened.connect(post_open_jobs)
	WindowBus.wages_due.connect(pay_outstanding_wages)

func disconnect_from_bus() -> void:
	WindowBus.labor_market_opened.disconnect(post_open_jobs)
	WindowBus.wages_due.disconnect(pay_outstanding_wages)
	# Phase 3+ cleanup clause (documented now, not implemented at v0):
	# if there is a still-ACTIVE contract for an employer, mark it BREACHED here.

func post_open_jobs() -> void:
	var open := desired_workers - filled_positions()
	print("    %s.EmployerInterest.post_open_jobs() — desired=%d filled=%d open=%d" % [owner.actor_id, desired_workers, filled_positions(), open])
	if open <= 0 or labor_market == null:
		return
	labor_market.queue_demand(owner, open)

func pay_outstanding_wages() -> void:
	var n := owner.accounts.payables.size() if owner.accounts != null else 0
	if n == 0:
		print("    %s.EmployerInterest.pay_outstanding_wages() — nothing to settle" % owner.actor_id)
		return
	print("    %s.EmployerInterest.pay_outstanding_wages() — settling %d payable(s)" % [owner.actor_id, n])
	var supply := labor_market.supply_for_scarcity() if labor_market != null else 0
	var total_paid: int = 0
	for payable in owner.accounts.payables:
		var worker := owner.get_node(payable.worker) as Actor
		var rate := WageCalculator.calculate_wage_per_slot(owner, worker, supply)
		var coin_owed := int(round(payable.slots_worked * rate))
		owner.accounts.coin -= coin_owed
		worker.accounts.coin += coin_owed
		total_paid += coin_owed
		print("      paid %s: %d slots × %.2f rate = %d coin" % [worker.actor_id, payable.slots_worked, rate, coin_owed])
	owner.accounts.payables.clear()
	owner.accounts.weekly_costs[&"wages"] = owner.accounts.weekly_costs.get(&"wages", 0) + total_paid

func filled_positions() -> int:
	if owner == null or owner.accounts == null:
		return 0
	var count := 0
	for c in owner.accounts.contracts:
		if c is LaborContract and c.status == Contract.Status.ACTIVE and c.employer == owner.get_path():
			count += 1
	return count
