class_name SocialiseStep
extends ActionStep

# Getting to a gathering place, and mingling once he's there IF there's
# anybody to mingle with. The same walk-then-something shape rest.gd already
# carries, except what waits at the far end can be empty — the whole reason
# Socialise's candidates are VENUES rather than crowds (see socialise.gd's
# header): the first man to ever visit a tavern finds nobody in it, and this
# step is what has to be honest about that rather than pretending an empty
# room is company.
#
# THREE BEHAVIOURS NOW, CHOSEN BY LOOKING, NEVER BY REMEMBERING: not at the
# chosen place → walk toward it; at it with nobody else there → the venue
# ITSELF still helps, at the thinner rate below; at it WITH somebody else
# there → real company, at the faster rate. There is no "I am currently
# walking over" flag and no "I've been waiting since" timer — the next tick
# simply asks Socialise.get_best_candidate and Town.find_people_at again from
# wherever he now stands.
#
# WHY BEING ALONE AT THE VENUE ISN'T NOTHING, WHEN AN EARLIER DRAFT OF THIS
# FILE SAID IT WAS. That draft wrote zero here, and it measurably broke the
# whole day: a man who reaches an empty tavern with nobody in it sits on a
# STANDING BID that changes nothing in the world for as long as the venue
# stays empty (Decision 23's "every win changes the world" has no purchase on
# a win that doesn't), so social keeps climbing toward its ceiling with no
# way back down, and past a point Socialise's score can outrun even Sleep's —
# see socialise.gd's header on company_worth for the number this actually
# broke at. change_of_scene_per_hour is the cheap fix: getting OUT is itself
# worth something, thinner than real company but enough to resolve the wait
# rather than let it stand forever. It is a stand-in for the real fix — a man
# who finds a venue empty ought to eventually give up on THAT venue and try
# elsewhere or something else entirely (Decision 23's failure-marks-the-
# candidate, unbuilt substrate, flagged for the author) — not a claim that
# sitting in an empty room is nearly as good as being with somebody.
#
# THE OSCILLATION AT THE MARGIN IS EXPECTED, NOT A BUG TO CHASE, once he does
# have company. Once social has fallen far enough that Socialise's score dips
# under whatever else is on the ballot, he leaves; upkeep then puts the gap
# right back on the way up, and a few ticks later Socialise outscores that
# neighbour again and pulls him back. The result, watched on a graph, is a
# slow relaxation oscillation — chat a tick, wander off, chat again — a man
# drifting in and out of conversation. Decision 23 permits exactly this: a
# win that DOES change the world is allowed to change what wins next. The two
# rates below are the knobs that stretch or compress each kind of period;
# nothing here should be read as broken and "fixed" by smoothing it.

# The legs. Found from the children rather than dragged in, same as Rest's own
# copy — a step's own machinery is structurally its child.
var walk: GoToStep

# How fast the gap closes while he's actually IN company, per world hour.
# Set well above upkeep's base_social_per_hour (2.5) so company visibly wins
# ground against the tide, rather than merely slowing it.
@export var company_per_hour := 30.0

# How fast the gap closes while he's AT the venue but ALONE — thinner than
# real company, on purpose: being out, hearing the hearth, sitting in the
# room, is worth something even with nobody to talk to, but it is not the
# same as company and should never be tuned to feel like it. See the header
# above for why this exists at all: without it, an empty venue is a
# standing bid that never resolves.
#
# A PLACEHOLDER WITH A NAMED DELETION DATE, NOT A TUNED NUMBER (Decision 32).
# It was 18.0, which is 56% of real company's 30 net of the 2.5 tide — far
# too close to the thing it is only supposed to hint at. 6.0 is small enough
# that company is plainly the payoff and the venue is plainly only the
# option, and still large enough to resolve the standing bid.
#
# IT GOES TO ZERO THE DAY FAILURE-MARKS-THE-CANDIDATE LANDS (Decisions 23 and
# 24), AND NOT ONE DAY BEFORE. At zero, with no way to give up on a venue, a
# man who finds the tavern empty stands in it most of the night — that is
# measured, not predicted. Marking is what lets him drop THAT venue and go to
# bed, and only then is there nothing left for this number to do.
@export var change_of_scene_per_hour := 6.0


func _ready() -> void:
	for child in get_children():
		if child is GoToStep:
			walk = child
			return
	push_warning("a SocialiseStep has no GoToStep under it — he can only join company he is already standing beside")


func advance(person: Person, hours: float) -> bool:
	var socialise := get_parent() as Socialise
	if socialise == null:
		push_warning("a SocialiseStep's parent must be a Socialise — it has no idea where to look for company")
		return true
	var place := socialise.get_best_candidate(person)
	if place == null:
		# No gathering place anywhere at all — nothing to walk to. The gate
		# closes on the very next tick; this tick simply does nothing, the
		# same quiet no-op WorkStep and Rest use for "gone between deciding
		# and doing".
		return true
	if person.get_current_place() != place:
		if walk == null:
			return true
		if not walk.walk_toward(person, place, hours):
			return false
		# Arrived THIS tick — fall through and ask straight away whether
		# anybody's here, so the tick that stands him at the venue is the
		# tick company (or the wait) starts counting.

	# TWO RATES, NEVER BOTH: real company when somebody else is actually
	# there, the thinner change-of-scene rate when he's alone at the venue.
	# Upkeep keeps running underneath either way (Brain._update_body), so
	# both numbers are competing against the same rising tide, not against
	# zero.
	var lonely: float = person.stats.get_stat(&"social")
	var rate := company_per_hour
	if not person.town.find_people_at(place).any(func(other: Person) -> bool: return other != person):
		rate = change_of_scene_per_hour
	person.stats.set_stat(&"social", maxf(lonely - rate * hours, 0.0))
	return false


# Never done, the same as Rest — he doesn't stop by finishing, only by
# something else outbidding him.
func is_done(_person: Person) -> bool:
	return false


# Re-derived, like everything else here — the destination and the verdict on
# who's there are whichever this tick's own questions answer, never anything
# the walk or the last mingle remembered.
func describe(person: Person) -> String:
	var socialise := get_parent() as Socialise
	if socialise == null:
		return "in company"
	var place := socialise.get_best_candidate(person)
	if place == null:
		return "in company"
	if person.get_current_place() != place:
		return "walking to %s" % place.place_name
	if person.town.find_people_at(place).any(func(other: Person) -> bool: return other != person):
		return "in company"
	return "waiting for company"
