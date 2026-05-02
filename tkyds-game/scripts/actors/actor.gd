class_name Actor
extends Node

@export var actor_id: StringName = &""
@export var accounts: Accounts
@export var interests: Array[Interest] = []
@export var grain_interest: GrainInterest

func _ready() -> void:
	_wire_signals()

func _wire_signals() -> void:
	SimClock.daily_tick.connect(tick_each_slot)
	print("[Wire] %s.tick_each_slot ← SimClock.daily_tick" % actor_id)

func tick_each_slot(slot: int) -> void:
	if grain_interest != null and slot == SimEnums.TimeSlot.LATE_EVENING:
		grain_interest.place_grain_order(self)
