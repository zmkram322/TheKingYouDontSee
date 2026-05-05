class_name LaborMarket
extends Market

# Pull-on-open. Workers register as suppliers, employers as demanders. On
# open, each is polled for a per-tick offer. Clearing creates one
# LaborContractActivity per match; the activity's on_close locks the wage
# rate (via WageCalculator) and writes the contract to both parties'
# `accounts.contracts`.

enum ClearingStrategy { RANDOM, FIFO }

@export var clearing_strategy: ClearingStrategy = ClearingStrategy.RANDOM

# Built fresh each open_market call.
var _seeking_workers: Array[Actor] = []
var _hiring_employers: Array[Actor] = []
var _positions_open: Dictionary = {}     # employer NodePath → int

func _ready() -> void:
	print("[Wire] LaborMarket ready (pull-on-open)")

func supply_for_scarcity() -> int:
	# v0: hardcoded global headcount; phase 3+ reads regional registry.
	return 2

func open_market(_tick: int) -> void:
	_seeking_workers.clear()
	_hiring_employers.clear()
	_positions_open.clear()
	for worker in registered_suppliers:
		var wi := worker.find_interest(WorkingInterest) as WorkingInterest
		if wi == null:
			continue
		if wi.is_seeking_work():
			_seeking_workers.append(worker)
			print("    %s offers self to LaborMarket" % worker.actor_id)
	for employer in registered_demanders:
		var ei := employer.find_interest(EmployerInterest) as EmployerInterest
		if ei == null:
			continue
		var open := ei.open_positions()
		if open > 0:
			_hiring_employers.append(employer)
			_positions_open[employer.get_path()] = open
			print("    %s.EmployerInterest — desired=%d filled=%d open=%d" %
				[employer.actor_id, ei.desired_workers, ei.filled_positions(), open])

func clear_market(tick: int) -> void:
	if _hiring_employers.is_empty() or _seeking_workers.is_empty():
		print("[CLEAR]    LaborMarket — nothing to match (employers=%d, workers=%d)" %
			[_hiring_employers.size(), _seeking_workers.size()])
		return

	var supply: int = _seeking_workers.size()

	# Step 1: each employer ranks candidates by expected_productivity / asked_wage.
	var rankings: Dictionary = {}
	for employer in _hiring_employers:
		var ei := employer.find_interest(EmployerInterest) as EmployerInterest
		var pattern := ei.resolve_work_pattern() if ei != null else null
		var job: JobCategory = Jobs.config_for(pattern.job_category) if pattern != null else null
		var ranked: Array = []
		for worker in _seeking_workers:
			var asked_wage: float = WageCalculator.calculate_wage_per_slot(employer, worker, job, supply)
			var expected_productivity: float = 1.0
			ranked.append({"worker": worker, "ratio": expected_productivity / max(asked_wage, 0.01)})
		ranked.sort_custom(func(a, b): return a["ratio"] > b["ratio"])
		ranked.shuffle()
		rankings[employer] = ranked

	# Step 2: pick order via clearing_strategy.
	var pick_order: Array[Actor] = _hiring_employers.duplicate()
	match clearing_strategy:
		ClearingStrategy.RANDOM:
			pick_order.shuffle()
		ClearingStrategy.FIFO:
			pass

	# Step 3: draft loop.
	var unmatched: Array[Actor] = _seeking_workers.duplicate()
	while true:
		var any_picked: bool = false
		for employer in pick_order:
			if int(_positions_open[employer.get_path()]) <= 0:
				continue
			for entry in rankings[employer]:
				var worker: Actor = entry["worker"]
				if not unmatched.has(worker):
					continue
				_strike_contract(employer, worker, supply, tick)
				unmatched.erase(worker)
				_positions_open[employer.get_path()] = int(_positions_open[employer.get_path()]) - 1
				any_picked = true
				break
		if not any_picked:
			break

	for employer in _hiring_employers:
		var remaining: int = int(_positions_open[employer.get_path()])
		if remaining > 0:
			print("[CLEAR]    %s left with %d open positions" % [employer.actor_id, remaining])
	for worker in unmatched:
		print("[CLEAR]    %s left without contract" % worker.actor_id)

func _strike_contract(employer: Actor, worker: Actor, supply: int, tick: int) -> void:
	var ei := employer.find_interest(EmployerInterest) as EmployerInterest
	var pattern := ei.resolve_work_pattern() if ei != null else null
	var act := LaborContractActivity.new()
	act.employer = employer
	act.worker = worker
	act.job_id = pattern.job_category if pattern != null else &"farming"
	act.current_supply = supply
	act.participants = [employer.get_path(), worker.get_path()]
	act.begin(tick)
	if act.close(tick):
		employer.accounts.activities.append(act)
