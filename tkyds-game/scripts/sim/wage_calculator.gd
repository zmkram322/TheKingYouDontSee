class_name WageCalculator
extends RefCounted

static func calculate_wage_per_slot(_employer: Actor, worker: Actor, job: JobCategory, supply: int) -> float:
	var sb: SkillsBook = worker.accounts.skills() if worker != null else null
	var xp: float = sb.balance(job.skill_key) if sb != null else 0.0
	var skill_factor: float = pow(1.0 - exp(-xp / job.x_0), job.a)
	var skill_value: float = job.base_skill * skill_factor
	var scarcity: float = 2.0 / (1.0 + exp(job.k * (float(supply) - job.s_0)))
	return max(job.minimum_wage, skill_value * scarcity)
