class_name LaborContract
extends Contract

@export var employer: NodePath
@export var worker: NodePath
@export var wage_per_slot: float = 0.0     # locked at LaborContractActivity.on_close()
@export var agreed_at_week: int = 0
