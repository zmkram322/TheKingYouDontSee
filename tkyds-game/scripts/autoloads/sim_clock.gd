extends Node

signal daily_tick(slot: int)
signal weekly_tick

@export var seconds_per_slot: float = 0.1
@export var max_days: int = 14
@export var auto_quit: bool = true

var current_day: int = 1
var current_slot: int = 0
var elapsed: float = 0.0
var stopped: bool = false

func _ready() -> void:
	print("[SimClock] ready — seconds_per_slot=%.3f max_days=%d" % [seconds_per_slot, max_days])

func _process(delta: float) -> void:
	if stopped:
		return
	elapsed += delta
	while elapsed >= seconds_per_slot and not stopped:
		elapsed -= seconds_per_slot
		_advance_one_slot()

func _advance_one_slot() -> void:
	var slot := current_slot
	var day := current_day
	print("\n[Day %d %s]" % [day, SimEnums.slot_name(slot)])
	daily_tick.emit(slot)
	if slot == SimEnums.TimeSlot.EARLY_MORNING and day % 7 == 0:
		print("[SimClock] weekly_tick (day %d)" % day)
		weekly_tick.emit()
	current_slot += 1
	if current_slot >= 8:
		current_slot = 0
		current_day += 1
	if current_day > max_days:
		stopped = true
		print("\n[SimClock] reached max_days=%d, stopping" % max_days)
		if auto_quit:
			get_tree().quit()
