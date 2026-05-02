class_name Market
extends Node

var region: Region

var supply_pool: Dictionary = {}
var demand_pool: Dictionary = {}

func take_supply(actor: Actor, qty: int) -> void:
	supply_pool[actor.get_path()] = supply_pool.get(actor.get_path(), 0) + qty
	print("    %s.take_supply(%s, %d)" % [name, actor.actor_id, qty])

func take_demand(actor: Actor, qty: int) -> void:
	demand_pool[actor.get_path()] = demand_pool.get(actor.get_path(), 0) + qty
	print("    %s.take_demand(%s, %d)" % [name, actor.actor_id, qty])

func clear() -> void:
	print("    %s.clear() — base no-op" % name)

func reset_pools() -> void:
	supply_pool.clear()
	demand_pool.clear()
	print("    %s.reset_pools()" % name)
