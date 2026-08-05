class_name Dawdle
extends Step

# The dull default every resident of the village can always fall back to —
# sweeping, dozing, chatting, sleeping, fleeing. Never satisfied and never
# impossible on its own; only losing a decision ever ends it, which is the
# whole of what "she never waits, she sweeps" means in practice. Promoted
# from emit_smoke.gd's own fixture-local Filler into real content now that
# more than one village needs the same shape — named differently on purpose,
# since emit_smoke.gd's inner class Filler is a fixture that stays exactly
# as it is (see brain_choice_smoke.gd's own note on why a global class_name
# can't quietly share a name already claimed by an inner class).
#
# Carries a verb because, unlike the fixture it was promoted from, this one
# has to answer to a 3D skin: sweeping and chatting and dozing all read as
# &"idling" by default, but sleeping and fleeing are named outright, since
# both are in the fixed vocabulary a skin switches animation on.

var _label: String
var _verb: StringName


func _init(new_label: String, new_verb: StringName = &"idling") -> void:
	_label = new_label
	_verb = new_verb


func is_satisfied(_who) -> bool:
	return false


func advance(_who, _delta: float) -> bool:
	return false


func describe(_who) -> String:
	return _label


func verb(_who) -> StringName:
	return _verb
