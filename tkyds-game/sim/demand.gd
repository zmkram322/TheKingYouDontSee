class_name Demand
extends RefCounted

# The one repeated primitive. A demand hits a resolver each tick; the resolver
# either satisfies it or emits the child demand it needs and waits on that child.
# When the child is satisfied, this demand resumes. That's the whole engine.

# Kinds of demand
const FOOD := &"food"        # a hungry consumer wants to eat
const ROLE := &"role"        # a missing role needs a body assigned to it
const BUY_GOOD := &"buy"     # a merchant wants to restock from a producer

var id: int
var kind: StringName
var requester: Actor            # who needs this filled
var provider: Actor = null      # who got assigned to fill it (once known)
var role_wanted: StringName     # only for ROLE demands
var phase: StringName           # where we are in this demand's little state machine
var child: Demand = null        # the sub-demand we're currently waiting on
var satisfied: bool = false


func _init(new_id: int, new_kind: StringName, who: Actor) -> void:
	id = new_id
	kind = new_kind
	requester = who


# A compact label for the queue panel, e.g. "#4 food (Bram) — request_good".
func label() -> String:
	var who := requester.person_name if requester else "?"
	var extra := ""
	if kind == ROLE:
		extra = " " + String(role_wanted)
	return "#%d %s%s (%s) — %s" % [id, String(kind), extra, who, String(phase)]
