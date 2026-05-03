extends Node

const _GRAIN := preload("res://scripts/economy/goods/grain.tres")

var _by_id: Dictionary = {}

func _ready() -> void:
	_register(_GRAIN)
	print("[Goods] ready — %d good(s) registered" % _by_id.size())

func _register(cfg: GoodConfig) -> void:
	_by_id[cfg.good_id] = cfg
	print("[Wire] Goods registered: %s (e_g=%.2f, A=%.1f, λ=%.2f)" %
		[cfg.good_id, cfg.elasticity, cfg.a_per_actor_daily, cfg.decay_lambda])

func config_for(good_id: StringName) -> GoodConfig:
	var cfg: GoodConfig = _by_id.get(good_id, null)
	if cfg == null:
		push_error("Goods.config_for(): unknown good %s" % good_id)
	return cfg
