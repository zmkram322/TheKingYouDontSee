extends Node

const _FARMING := preload("res://scripts/economy/jobs/farming.tres")

var _by_id: Dictionary = {}

func _ready() -> void:
	_register(_FARMING)
	print("[Jobs] ready — %d job(s) registered" % _by_id.size())

func _register(cfg: JobCategory) -> void:
	_by_id[cfg.job_id] = cfg
	print("[Wire] Jobs registered: %s (skill_key=%s, min_wage=%.2f, base_skill=%.1f)" %
		[cfg.job_id, cfg.skill_key, cfg.minimum_wage, cfg.base_skill])

func config_for(job_id: StringName) -> JobCategory:
	var cfg: JobCategory = _by_id.get(job_id, null)
	if cfg == null:
		push_error("Jobs.config_for(): unknown job %s" % job_id)
	return cfg
