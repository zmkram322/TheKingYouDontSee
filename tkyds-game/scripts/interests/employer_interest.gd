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
	print("    %s.EmployerInterest.pay_outstanding_wages() — walk %d payable(s); decrement coin; pay each worker; clear payables" % [owner.actor_id, n])
	# Math lands in the next session. Print-only for now.

func filled_positions() -> int:
	if owner == null or owner.accounts == null:
		return 0
	var count := 0
	for c in owner.accounts.contracts:
		if c is LaborContract and c.status == Contract.Status.ACTIVE and c.employer == owner.get_path():
			count += 1
	return count
