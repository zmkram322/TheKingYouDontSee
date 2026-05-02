class_name LaborMarket
extends Market

func _ready() -> void:
	WindowBus.labor_market_closed.connect(clear)
	print("[Wire] LaborMarket.clear ← WindowBus.labor_market_closed")

func clear() -> void:
	var available_workers: Array[Worker] = []
	for path in supply_pool:
		var node := get_node_or_null(path)
		if node is Worker:
			var w: Worker = node
			if w.active_contract == null:
				available_workers.append(w)
	var open_positions: Array[LandOwner] = []
	for path in demand_pool:
		var node := get_node_or_null(path)
		if node is LandOwner:
			var qty: int = int(demand_pool[path])
			for i in range(qty):
				open_positions.append(node)

	var matched: int = min(available_workers.size(), open_positions.size())
	print("    LaborMarket.clear() — available_workers=%d open_positions=%d → match %d; write LaborContract(s)" % [available_workers.size(), open_positions.size(), matched])
	for i in range(matched):
		var worker: Worker = available_workers[i]
		var employer: LandOwner = open_positions[i]
		var contract := LaborContract.new()
		contract.employer = employer.get_path()
		contract.worker = worker.get_path()
		contract.wage_per_work_unit = WageCalculator.calculate_wage(employer, worker)
		contract.agreed_at_week = (SimClock.current_day - 1) / 7 + 1
		contract.status = Contract.Status.ACTIVE
		worker.active_contract = contract
		worker.accounts.contracts.append(contract)
		employer.accounts.contracts.append(contract)
		print("      contract: %s ↔ %s @ wage=%d/slot, week=%d" % [worker.actor_id, employer.actor_id, contract.wage_per_work_unit, contract.agreed_at_week])
	reset_pools()
