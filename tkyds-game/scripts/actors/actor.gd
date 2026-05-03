class_name Actor
extends Node

@export var actor_id: StringName = &""
@export var accounts: Accounts
@export var interests: Array[Interest] = []

func _ready() -> void:
	for interest in interests:
		interest.owner = self
		interest.connect_to_bus()
		print("[Wire] %s attached %s" % [actor_id, interest.get_script().get_global_name()])

func _exit_tree() -> void:
	for interest in interests:
		interest.disconnect_from_bus()
		interest.owner = null

func add_interest(interest: Interest) -> void:
	interests.append(interest)
	interest.owner = self
	interest.connect_to_bus()

func remove_interest(interest: Interest) -> void:
	interest.disconnect_from_bus()
	interest.owner = null
	interests.erase(interest)

func find_interest(type: Variant) -> Interest:
	for i in interests:
		if is_instance_of(i, type):
			return i
	return null
