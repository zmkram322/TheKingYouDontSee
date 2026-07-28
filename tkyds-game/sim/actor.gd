class_name Actor
extends RefCounted

# A person in the world. Just data + a bit of display state.
# Role is assigned on demand — everyone can start idle and get pulled into
# whatever role the cascade needs (merchant, producer, ...).
# All stat data (hunger, food, coin, willingness, role, ...) lives in
# Simulation's StatStore — this is just identity + structural/display state.

const ROLE_IDLE := &"idle"
const ROLE_CONSUMER := &"consumer"
const ROLE_MERCHANT := &"merchant"
const ROLE_PRODUCER := &"producer"
const ROLE_FARM_WORKER := &"farm_worker"
const ROLE_KEEPER := &"keeper"   # runs a public house; receives what drinkers spend there

var id: int = 0  # assigned by StatStore.register

var person_name: String
var workers: Array[Actor] = []   # farm workers a producer has hired (needed to produce)

# Short human-readable line describing what this person is doing right now.
var state_text: String = "idle"


func _init(name: String) -> void:
	person_name = name
