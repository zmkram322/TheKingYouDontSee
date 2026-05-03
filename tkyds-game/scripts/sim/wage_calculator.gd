class_name WageCalculator
extends RefCounted

const MINIMUM_WAGE: float = 1.0
const BASE_SKILL: float = 2.0
const X_0: float = 100.0
const A: float = 1.0
const K: float = 1.0
const S_0: float = 2.0

static func calculate_wage_per_slot(_employer: Actor, worker: Actor, supply: int) -> float:
	var xp: float = worker.accounts.skills.get(&"farming", 0.0)
	var skill_factor: float = pow(1.0 - exp(-xp / X_0), A)
	var skill_value: float = BASE_SKILL * skill_factor
	var scarcity: float = 2.0 / (1.0 + exp(K * (float(supply) - S_0)))
	return max(MINIMUM_WAGE, skill_value * scarcity)
