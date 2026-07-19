class_name Actor
extends RefCounted

# A person in the world. Just data + a bit of display state.
# Role is assigned on demand — everyone can start idle and get pulled into
# whatever role the cascade needs (merchant, producer, ...).

const ROLE_IDLE := &"idle"
const ROLE_CONSUMER := &"consumer"
const ROLE_MERCHANT := &"merchant"
const ROLE_PRODUCER := &"producer"
const ROLE_FARM_WORKER := &"farm_worker"

var person_name: String
var role: StringName = ROLE_IDLE

# Consumer stuff
var hunger: float = 0.0          # 0 = full, 100 = starving

# Anyone can hold food (consumer eats it, merchant resells it, producer makes it)
var food: int = 0

# Producer stuff
var producing_ticks_left: int = 0
var workers: Array[Actor] = []   # farm workers a producer has hired (needed to produce)

# Short human-readable line describing what this person is doing right now.
var state_text: String = "idle"


func _init(name: String, starting_role: StringName = ROLE_IDLE) -> void:
	person_name = name
	role = starting_role
	state_text = String(starting_role)
