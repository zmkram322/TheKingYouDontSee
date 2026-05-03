class_name Market
extends Node

var region: Region

var supply_pool: Dictionary = {}
var demand_pool: Dictionary = {}

func queue_supply(actor: Actor, qty: int) -> void:
	supply_pool[actor.get_path()] = supply_pool.get(actor.get_path(), 0) + qty
	print("[QUEUE]    %s.queue_supply(%s, %d)" % [name, actor.actor_id, qty])

func queue_demand(actor: Actor, qty: int) -> void:
	demand_pool[actor.get_path()] = demand_pool.get(actor.get_path(), 0) + qty
	print("[QUEUE]    %s.queue_demand(%s, %d)" % [name, actor.actor_id, qty])

func clear() -> void:
	print("[CLEAR]    %s.clear() — base no-op" % name)

func reset_pools() -> void:
	supply_pool.clear()
	demand_pool.clear()
	print("    %s.reset_pools()" % name)
