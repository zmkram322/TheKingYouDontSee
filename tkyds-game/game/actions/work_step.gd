class_name WorkStep
extends ActionStep

# The working itself, and — as of rung 4 — getting there first. As of rung 5 it
# is also the first thing in this game that MAKES something: grain, per world
# hour. As of rung 6b's repair (Decision 29) where that grain LANDS branches
# on who owns the plot — the worker's whole inventory on unowned land, a
# split between the owning Place's barn and the worker's own SHARE on owned
# land — see _pay_out below.
#
# Like every step it holds no progress — nothing on this node, and nothing on
# the man. Which plot he is working is re-derived every tick from the same
# get_best_candidate the gate and score used, who holds the plot lives on the
# plot, how far along the road he is, is where he is standing, and how far into
# the current grain he is lives in the FURROW (Workstation.output_part_made),
# which is why walking away from a part-turned plot costs him nothing and leaves
# the part-turned work for whoever comes next.
#
# ONE advance(), TWO behaviours, chosen by looking rather than by remembering:
# not at the plot's place → walk toward it; at it → claim it and work. There is
# no "I am currently walking" state to get stuck in, which is why a man whose
# plot is taken from under him mid-journey costs nothing to interrupt — the next
# tick simply asks again from wherever his feet now are.
#
# The walking is a GoToStep NESTED UNDER THIS ONE, never a sibling: Action._ready
# takes the first ActionStep child it finds, so two steps under one Action would
# silently pick one and ignore the other. Nesting is also what lets later
# actions reuse walking by hanging one of these under their own step.

# The legs. Found from the children rather than dragged in, because a step's own
# machinery is structurally its child — the same way an Action finds its step
# and a Brain finds its Person. Said out loud when it is missing: without it a
# farmer standing at the Inn would silently never set off, which reads as a
# broken decision rather than as a missing node.
var walk: GoToStep

# What a plot yields. A constant rather than a knob: an export for it would be a
# second authoring surface for what a station makes, and the day a station makes
# something other than grain that comes from a Recipe (rung 9a), which owns the
# output and the time it takes together. One item, named in one place.
const YIELD_NAME := &"grain"

# What a man brings in from a plot in one world HOUR — like every rate in game/,
# and emphatically not per tick. An authored 2.5 means two and a half grain an
# hour — the yield Decision 29's sizing needed to make a wage viable at all:
# at the old 1.0/hour, share_of_crop (Obligation, 0.35) would have needed to
# rise past 0.5 just to break even against measured hunger, which hands the
# owner less than half his own crop and is a fiction question as much as a
# tuning one, so the yield moved instead. At the hundredth-of-an-hour tick the
# game runs he makes a hundredth of that a tick and the plot holds the
# remainder until it comes to something. See Workstation.output_part_made for
# why the fraction lives there and not here.
@export var base_grain_per_hour := 2.5


func _ready() -> void:
	for child in get_children():
		if child is GoToStep:
			walk = child
			return
	push_warning("a WorkStep has no GoToStep under it — he can only work a plot he is already standing on")


func advance(person: Person, hours: float) -> bool:
	var work := get_parent() as WorkTheField
	if work == null:
		push_warning("a WorkStep's parent must be a WorkTheField — it has no idea what to work")
		return true
	var station := work.get_best_candidate(person)
	if station == null:
		# Gone between deciding and doing. The serial loop means nothing runs
		# in between today, so this cannot happen yet — kept as a quiet no-op
		# rather than an assumption the day the loop stops being serial.
		return true
	# Not there yet. Note what he does NOT know while he is on the road: whether
	# the plot is still free. Freeness is only visible where you are standing
	# (Decision 15), so he walks the whole way and finds out on arrival — the
	# wasted journey is the point, because it is the collision that later earns
	# a notice board.
	var place := station.get_place()
	if person.get_current_place() != place:
		if walk == null:
			return true
		walk.walk_toward(person, place, hours)
		return false
	# RENEWED BY USE — claim() on EVERY tick this advances, not once at the
	# start. He is present and it is already his, so the call re-stamps today
	# and dawn passes under him; nothing else keeps a claim alive. claim() is
	# also the presence check: a man not standing at the plot's place gets
	# false, and the branch above is what makes that false mean "walk there".
	if not station.claim(person):
		return false
	# THE WORK ITSELF. Everything above this line is about getting to it.
	#
	# IT SITS BELOW THE CLAIM, and that placement is the whole of this rung's
	# trap. advance() grew a second branch at rung 4, so a yield written at the
	# top of this function pays a man for WALKING ACROSS TOWN — which reads as a
	# balance problem, not as a misplaced line, and costs an hour to trace. Down
	# here it is paid for exactly what renew-on-use is paid for: standing on the
	# plot with his hands on it.
	var inventory := person.get_inventory()
	if inventory == null:
		# He has already said so in his own _ready. Banking work he could never
		# collect would leave the plot holding a part-made number that grows
		# without bound, so the work simply does not happen.
		return false
	station.output_part_made += get_yield_per_hour(person) * hours
	# Whole grain comes off the plot; the fraction stays in the furrow for
	# whoever works it next. Floor-and-subtract rather than a loop, so one
	# enormous tick pays out in a single step instead of spinning through it a
	# grain at a time.
	var made := int(floorf(station.output_part_made))
	if made > 0:
		station.output_part_made -= float(made)
		_pay_out(person, inventory, station, made)
	return false


# WHERE THE YIELD LANDS, BY OWNERSHIP (Decision 29). Unowned land is the
# king's, i.e. nobody's, and a man keeps the whole of what he raises on it —
# which is what keeps plain WorkTheField meaningful instead of dead library
# code now that WorkForHire exists. Owned land's crop is the owner's from the
# moment it leaves the ground: the worker is not handed it later, it was
# never his in full — he keeps only his authored SHARE
# (Obligation.share_of_crop), paid the instant it is made.
#
# BOTH SIDES LAND VIA add(), NEVER hand_over(). The work CREATES the grain —
# there is no "before" inventory to take it from — so the world total rises
# here exactly as it does today and the conservation probe keeps its meaning.
# Writing this as a transfer would be wrong on both counts: hand_over would
# make a creation look like a move, and there is nothing to take() from.
#
# IS_INSTANCE_VALID FIRST: owned_by is a stored Person reference (see
# workstation.gd), and a freed owner would otherwise error on the very next
# property read — the same one-liner Workstation.is_permitted_to already
# uses, matched here rather than re-derived differently.
func _pay_out(person: Person, inventory: Inventory, station: Workstation, made: int) -> void:
	if not is_instance_valid(station.owned_by):
		station.owned_by = null
	if station.owned_by == null:
		inventory.add(YIELD_NAME, made)
		return
	var employer := get_parent() as WorkForHire
	var obligation := employer.get_standing_obligation(person) if employer != null else null
	if obligation == null:
		# Owned land worked with no obligation to pay against — unreachable
		# in the shipped game (Workstation.is_permitted_to already refused
		# station.claim() to anyone here who is neither the owner nor an
		# obligation-holder, so DO never reaches this line for them), but the
		# owner himself COULD one day work his own land through the plain
		# library action rather than WorkForHire, and that man has no
		# obligation to read a share off. Kept as a quiet fallback to the
		# owner's own store, consistent with "owned land's crop is the
		# owner's" even when the owner is the one holding the hoe, rather
		# than an assumption the game would rather crash on.
		var place_fallback := station.get_place()
		var barn_fallback := place_fallback.get_inventory() if place_fallback != null else null
		if barn_fallback != null:
			barn_fallback.add(YIELD_NAME, made)
		return
	# THE SPLIT. Asked, never worked out here: how much of this is his is the
	# AGREEMENT's question, so it is answered behind Obligation's one door and
	# this file does not know — and must not learn — that a share is a
	# fraction, that fractions need carrying, or that anything gets rounded at
	# all. Swap share-of-crop for a payday, a piece rate or a lord's cut off
	# the top and every line below goes on working unread.
	#
	# WHAT THIS FILE DOES STILL GUARANTEE is the conservation, because that is
	# a fact about the FURROW rather than about the wage: whole grain came off
	# the plot, and whole grain is placed. owner_share is whatever the door
	# did not hand back, so the two always sum to exactly `made` however the
	# wage is later rewritten. That is the property the probe's total leans
	# on, and it survives any change made on the other side of the door.
	var worker_share := obligation.take_worker_share(made)
	var owner_share := made - worker_share
	if owner_share > 0:
		var place := station.get_place()
		var barn := place.get_inventory() if place != null else null
		if barn == null:
			# No barn to receive the owner's part — said out loud rather than
			# silently dropping grain, the same corollary CLAUDE.md names for a
			# missing node_paths wire: a broken link must not be indistinguishable
			# from nothing happening yet.
			push_warning("Workstation \"%s\" is owned but its place has no Inventory to receive the crop" % station.name)
		else:
			barn.add(YIELD_NAME, owner_share)
	if worker_share > 0:
		# add(), not hand_over(): the work CREATED this grain, so the world
		# total rises here exactly as it does on unowned land. Writing the
		# wage as a transfer would make the conservation claim lie.
		inventory.add(YIELD_NAME, worker_share)


# What he brings in per hour, right now. THE SEAM, and it stands empty on
# purpose.
#
# Its own call site rather than a read of base_grain_per_hour, because a scythe
# in his hands, a richer plot, a wound, or a sack already full all install in
# THIS FUNCTION BODY and not one caller changes. Same shape as
# Brain.get_adenosine_recovery() and Person.get_travel_speed(), which is what
# this project reaches for whenever a number is going to grow modifiers.
#
# It takes the person because the first modifier anybody will want is a fact
# about the MAN — the tool he is holding — exactly as get_travel_speed's one
# modifier is. Underscored only because nothing reads him yet, the same marker
# Action.is_available_to uses for a seam standing empty; drop the underscore the
# day something does.
#
# STRENGTH IS DELIBERATELY NOT IN HERE, though stats.gd predicts it will one day
# mean work done per hour. That is a prediction, not a specification, and this
# rung does not cash it: Hobb already needs less sleep, rises first, walks
# faster and takes the plot, and nothing has asked for a fourth advantage. This
# is where it goes on the day something does.
func get_yield_per_hour(_person: Person) -> float:
	return base_grain_per_hour


# Which half of the job he is seen doing. Re-derived, like everything else here
# — the destination is named from the station this tick chose, never from
# anything the walk remembered.
func describe(person: Person) -> String:
	var work := get_parent() as WorkTheField
	if work != null:
		var station := work.get_best_candidate(person)
		if station != null:
			# A mis-parented station has no place at all. Workstation._ready
			# already says so; here it must simply not be dereferenced.
			var place := station.get_place()
			if place != null and person.get_current_place() != place:
				return "walking to %s" % place.place_name
	return "in the furrows"
