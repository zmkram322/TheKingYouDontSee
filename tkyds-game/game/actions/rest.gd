class_name Rest
extends ActionStep

# Getting to bed, and lying there once he has one. Before rung 6c a bed was a
# fiction and this step did nothing but name what you'd see; as of 6c a bed
# is a Workstation exactly like a plot, so getting into one is walk-then-
# claim, the identical shape work_step.gd already carries.
#
# ONE advance(), TWO behaviours, chosen by looking rather than remembering:
# not at the bed's place → walk toward it; at it → claim it, EVERY tick,
# renewed by use. There is no "I am currently walking to bed" flag to get
# stuck in — the next tick simply asks again from wherever he now stands.
#
# RENEW-ON-USE IS THE WHOLE POINT OF THIS RUNG. Every earlier claim() caller
# — WorkStep, shared by both WorkTheField and WorkForHire — works entirely
# inside one man's WAKING day, so none of them has ever actually carried a
# claim across a day boundary while
# the claimant is ASLEEP and cannot act on anything else. A man works past
# midnight because he is choosing to, and could stop; a sleeper cannot
# "choose" to renew a claim, so the renewal has to arrive as a SIDE EFFECT of
# this step simply continuing to run him every tick — exactly the case
# claim() on a day-long tenancy was repaired for. Claim a bed at 22:00, dawn
# breaks mid-sleep, and without claim() firing on every tick the bed reads
# free the instant the day turns and somebody else takes the bed a sleeping
# man is lying in. See probe claim 46.
#
# LYING ITSELF DOES NOTHING FURTHER. The body's own recovery is Brain's job
# (Brain.run_upkeep, driven by is_awake() / counts_as_asleep_for, never by
# anything in this file) — the same split this file's very first version
# already explained, just now sitting behind one more layer of "am I actually
# there".

# The legs. Found from the children rather than dragged in, the same pattern
# WorkStep uses for its own GoToStep — a step's own machinery is structurally
# its child.
var walk: GoToStep


func _ready() -> void:
	for child in get_children():
		if child is GoToStep:
			walk = child
			return
	push_warning("a Rest has no GoToStep under it — he can only sleep in a bed he is already standing at")


func advance(person: Person, hours: float) -> bool:
	var sleep := get_parent() as Sleep
	if sleep == null:
		push_warning("a Rest's parent must be a Sleep — it has no idea which bed to hold")
		return true
	var bed := sleep.get_best_candidate(person)
	if bed == null:
		# No bed anywhere — nothing to walk to and nothing to hold. The gate
		# closes on the very next tick; this tick simply does nothing, the
		# same quiet no-op WorkStep uses for the equivalent "gone between
		# deciding and doing" case.
		return true
	var place := bed.get_place()
	if person.get_current_place() != place:
		if walk == null:
			return true
		if not walk.walk_toward(person, place, hours):
			return false
		# Arrived THIS tick — fall through and take the bed now, so the tick
		# that stands him at the Inn is the tick he lies down. A tick spent
		# standing beside an unclaimed bed would be a tick where "is he
		# asleep" has no honest answer, and claim 2 reads the answer on every
		# tick there is.
	# RENEWED BY USE, on EVERY tick this advances — the mechanism claim 46
	# exists to prove. A failed claim means the bed was taken between ticks;
	# either way the next gate ask picks up from wherever the world now
	# stands, the same as a failed claim anywhere else in the game.
	if not bed.claim(person):
		return false
	return false


# Never done, because sleep doesn't end by finishing — it ends by Wake
# outbidding it.
func is_done(_person: Person) -> bool:
	return false


# Re-derived, like everything else here — the destination is named from
# whichever bed this tick's get_best_candidate chose, never from anything
# the walk remembered.
func describe(person: Person) -> String:
	var sleep := get_parent() as Sleep
	if sleep != null:
		var bed := sleep.get_best_candidate(person)
		if bed != null:
			var place := bed.get_place()
			if place != null and person.get_current_place() != place:
				return "walking to %s" % place.place_name
	return "out cold"
