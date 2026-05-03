class_name LaborMarket
extends Market

enum ClearingStrategy { RANDOM, FIFO }

@export var clearing_strategy: ClearingStrategy = ClearingStrategy.RANDOM

func _ready() -> void:
	WindowBus.labor_market_closed.connect(clear)
	print("[Wire] LaborMarket.clear ← WindowBus.labor_market_closed")

func supply_for_scarcity() -> int:
	# v0: hardcoded global headcount; phase 3+ uses regional registry.
	return 2

func clear() -> void:
	var employers: Array = demand_pool.keys()
	var workers: Array = supply_pool.keys()
	var supply: int = workers.size()

	if employers.is_empty() or workers.is_empty():
		print("[CLEAR]    LaborMarket.clear() — nothing to match (employers=%d, workers=%d)" % [employers.size(), workers.size()])
		supply_pool.clear()
		demand_pool.clear()
		return

	# Step 1: each employer ranks candidates by expected_productivity / asked_wage
	var rankings: Dictionary = {}
	for employer_path in employers:
		var employer := get_node(employer_path) as Actor
		var ranked: Array = []
		for worker_path in workers:
			var worker := get_node(worker_path) as Actor
			var asked_wage: float = WageCalculator.calculate_wage_per_slot(employer, worker, supply)
			var expected_productivity: float = 1.0
			var ratio: float = expected_productivity / max(asked_wage, 0.01)
			ranked.append({"worker": worker_path, "ratio": ratio})
		ranked.sort_custom(func(a, b): return a["ratio"] > b["ratio"])
		ranked.shuffle()
		rankings[employer_path] = ranked

	# Step 2: pick order via clearing_strategy
	var pick_order: Array = employers.duplicate()
	match clearing_strategy:
		ClearingStrategy.RANDOM:
			pick_order.shuffle()
		ClearingStrategy.FIFO:
			pass
		# phase 3+: CHARISMA_PICK reads each employer's charisma; PRODUCTIVITY_RANK reads worker skills

	# Step 3: draft loop
	var unmatched: Array = workers.duplicate()
	var positions_remaining: Dictionary = {}
	for employer_path in employers:
		positions_remaining[employer_path] = int(demand_pool[employer_path])

	while true:
		var any_picked: bool = false
		for employer_path in pick_order:
			if positions_remaining[employer_path] <= 0:
				continue
			for entry in rankings[employer_path]:
				var worker_path = entry["worker"]
				if not (worker_path in unmatched):
					continue
				_write_contract(employer_path, worker_path)
				unmatched.erase(worker_path)
				positions_remaining[employer_path] -= 1
				any_picked = true
				break
		if not any_picked:
			break

	for employer_path in employers:
		if positions_remaining[employer_path] > 0:
			var employer := get_node(employer_path) as Actor
			print("[CLEAR]    %s left with %d open positions" % [employer.actor_id, positions_remaining[employer_path]])
	for worker_path in unmatched:
		var worker := get_node(worker_path) as Actor
		print("[CLEAR]    %s left without contract" % worker.actor_id)

	supply_pool.clear()
	demand_pool.clear()

func _write_contract(employer_path: NodePath, worker_path: NodePath) -> void:
	var employer := get_node(employer_path) as Actor
	var worker := get_node(worker_path) as Actor
	var contract := LaborContract.new()
	contract.employer = employer_path
	contract.worker = worker_path
	contract.wage_per_work_unit = 0   # legacy field; rate is recomputed at settlement
	contract.agreed_at_week = (SimClock.current_day - 1) / 7 + 1
	contract.status = Contract.Status.ACTIVE
	worker.accounts.contracts.append(contract)
	employer.accounts.contracts.append(contract)
	print("[CLEAR]      contract: %s ↔ %s, week=%d" % [worker.actor_id, employer.actor_id, contract.agreed_at_week])
