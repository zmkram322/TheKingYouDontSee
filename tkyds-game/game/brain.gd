class_name Brain
extends Node

# What one person knows how to do, which of it wins right now, and the body
# bookkeeping that happens to him whether he decides it or not.
#
# His repertoire is this node's children — every Action under here is something
# he knows. That's the whole of teaching him something: drop the action scene
# in. It is NOT how you gate what he can do this second; that's each action's
# own is_available_to, asked every tick. Nodes move when someone learns or
# forgets, never when someone falls asleep.
#
# The picking itself lives in DecisionEngine, which holds nothing about anybody
# and could be swapped without touching this file.

var person: Person
var decision_engine := DecisionEngine.new()

# What he's doing right now. Kept ONLY so you can see it over his head and so
# is_awake can read it — never fed back into the ranking. Every tick re-picks
# from scratch over current facts, so this is a readout, not a memory.
var current_action: Action

# What was open to him on the last pass — every action that cleared its gate,
# in the order DecisionEngine handed them back, before any of them was scored.
#
# A readout, same shape and same justification as _last_scores below it:
# nothing reads it back into a decision, it is worked out fresh every
# think_and_act rather than kept across one, and deleting it changes no
# decision he ever makes. It exists so anything watching him — a verb menu
# under a player's hand, a panel drawing what he DIDN'T pick — can ask what
# was on the table without re-deriving it.
var _open_actions: Array[Action] = []

var _known_actions: Array[Action] = []


func _ready() -> void:
	person = get_parent() as Person
	if person == null:
		push_warning("a Brain's parent must be a Person — it has nobody to think for")
	reload_known_actions()


# --- What he knows ---------------------------------------------------------------

# Learning and forgetting are first-class, not housekeeping. Growing reach
# unlocking new actions is the shape of progression, and what someone can do at
# all is most of what makes them a different person from the man beside them.
# It just doesn't happen every tick — which is why the list is cached here and
# re-read on the rare occasion it changes, rather than rebuilt sixty times a
# second.
#
# What this is NOT is how you gate what he can do right now. That's each
# action's own is_available_to, asked every tick. Nodes move when he learns or
# forgets, never when he falls asleep.

# Teach him something. Takes the action's scene from the library, so he gets his
# own copy and tuning one man's sleep doesn't change everybody's.
func learn(action_scene: PackedScene) -> Action:
	var action := action_scene.instantiate() as Action
	if action == null:
		push_warning("that scene isn't an Action — nothing learned")
		return null
	add_child(action)
	reload_known_actions()
	return action


# Take something away — a trade lost, a limb lost, a rank stripped. If it's what
# he's doing right now, he stops doing it; next tick he picks again from
# whatever's left.
func forget(action: Action) -> void:
	if action == null or action.get_parent() != self:
		return
	if current_action == action:
		current_action = null
	remove_child(action)
	action.queue_free()
	reload_known_actions()


# Re-read his repertoire off the children. Once at startup, and again whenever
# he learns or forgets.
func reload_known_actions() -> void:
	_known_actions.clear()
	for child in get_children():
		if child is Action:
			_known_actions.append(child)
	# forget() queue_frees the action it removes. Left standing, this list
	# would hand a freed node to whatever is drawing it — the same
	# is_instance_valid trap CLAUDE.md warns about, avoided here by simply not
	# keeping the stale entry around. It is rebuilt honestly on the very next
	# think_and_act; this only closes the gap between "he forgot it" and
	# "he next thinks".
	_open_actions.clear()


# His whole repertoire — everything he knows how to do, gated or not. Read-only
# to everyone outside: the way the list changes is learn() and forget(), never
# by somebody appending to it.
#
# It exists so anything watching him can ask what was on the table rather than
# only what won. The probe's standing check — "no action is ever chosen while
# its own gate says no" — needs exactly this, and so will any panel that wants
# to draw the actions he DIDN'T pick.
func get_known_actions() -> Array[Action]:
	return _known_actions


# What was open to him on the last pass — see _open_actions above.
func get_open_actions() -> Array[Action]:
	return _open_actions


# Is he awake? Read off what he's doing rather than kept as a stat, so the two
# can never disagree — there is no flag to forget to clear.
#
# Doing nothing counts as awake. On the very first tick he hasn't decided
# anything yet, and "hasn't decided" must not read as "unconscious".
# What each action was worth in the last pass, by name — NAN for anything that
# wasn't on the ballot. For watching a decision get made rather than inferring
# it from the outcome. Nothing reads this back.
func get_last_scores() -> Dictionary:
	return decision_engine.get_last_scores()


# Reads counts_as_asleep_for rather than the bare flag, because as of rung
# 6c "is he asleep" can depend on WHERE he is, not only on WHAT he chose:
# Sleep only counts as asleep once he is standing at a claimed bed, not
# while he is still walking to one. See action.gd's header for the split.
func is_awake() -> bool:
	return current_action == null or not current_action.counts_as_asleep_for(person)


# One slice of thinking and doing, measured in world HOURS — never real
# seconds. The conversion happened once, above, in Clock.get_hours_elapsed;
# down here `hours` is the only unit there is. The argument is named for what
# it holds rather than for where it came from, because an argument called
# `delta` carrying hours is precisely the trap that costs a day.
#
# Three things, in this order, and the order matters:
#
#   1. Decide. Gates read what he WAS doing — that's what lets Wake be on the
#      ballot only while he's already asleep, which is half the reason the sleep
#      cycle doesn't twitch.
#   2. Do the work. The world changes here — including where he is standing.
#   3. Update the body, using what he ACTUALLY DID this tick.
#
# THE BODY UPDATE MOVED BELOW THE WORK AT RUNG 6c, and the old order was not
# wrong until then. It used to say "the tick he decides to turn in is the tick
# adenosine starts falling" — true while lying down happened wherever he stood,
# because deciding and doing were the same instant. Once Sleep's step gained a
# walk, "is he asleep" became a fact the DO step writes (arriving, claiming a
# bed), so an update run before the work reads the tick's beginning while every
# check after the tick reads its end — and the transition tick pays the wrong
# rate. Updating last means the body pays for what the tick actually contained:
# a man who spent it walking to bed tires for the walk, and the tick he lies
# down is the tick adenosine starts falling.
#
# Deliberately re-decides every tick instead of committing. With nothing
# stored, an interruption costs nothing — the next tick picks again from
# wherever he now is. It doesn't flicker because of the two thresholds on the
# actions themselves (see game/actions/): sleep starts winning high and stops
# winning low, so there's a wide gap between "start" and "stop" rather than one
# line to sit on and jitter across.
func think_and_act(hours: float) -> void:
	if person == null:
		return
	_open_actions = decision_engine.open_the_ballot(person, _known_actions)
	current_action = pick_from_the_ballot(_open_actions)
	if current_action != null and current_action.step != null \
			and current_action.step.is_doable(person):
		current_action.step.advance(person, hours)
	run_upkeep(hours)


# How THIS brain picks a winner from the open list. The gate half above is
# shared and never overridden — everybody's ballot is opened the same way,
# by the same DecisionEngine, subject to the same gates. This is the seam
# Gate 1 forks: the default body picks by score, exactly as choose() always
# did; PlayerBrain overrides it to hand back whatever a hand chose instead.
#
# Null is a REAL ANSWER, not a missing one — it means "standing there", and
# think_and_act already treats a null current_action correctly (it simply
# does no step this tick, then still runs the body). An empty ballot scores
# to null the same way; a player who hasn't chosen anything is the same
# case wearing a different reason.
func pick_from_the_ballot(open_actions: Array[Action]) -> Action:
	return decision_engine.get_highest_scoring(person, open_actions)


# --- The body ------------------------------------------------------------------

# What happens to him whether he decides it or not.
#
# This lives here rather than inside the actions on purpose. Adenosine is the
# waste left over from the brain spending energy — it piles up for as long as
# he's up, no matter WHAT he's up doing. Put it inside "stay up" and the day
# you add "work the field" you get a farmhand who never gets tired, and you
# find out three atoms later. Nothing an action does should be required for
# this to be true.
#
# Every drift that arrives later — hunger, fear fading, a wound — is one more
# line here, and every action ever written inherits all of them for free.
@export_group("Body")
# `base_` because these are inputs to a sum, not the answer. What actually gets
# applied comes out of the two getters below.
#
# PER WORLD HOUR, like every rate in game/ — not per real second. That matters
# twice over. It makes the numbers sentences you can reason about ("2.5 an
# hour, turns in around 50, so he is up about sixteen hours") where "1.0 per
# real second" silently meant something different at every day length. And it is
# what ties the body to the sun: drag day_length_seconds and both move
# together, which is what that slider always claimed to do.
#
# These two set the SHAPE of the cycle and StayUp's daylight term sets its
# PHASE. Sixteen hours awake at 2.5 is a swing of 40, and clearing that 40 at
# 5.0 is the eight hours asleep — so their ratio is the ratio of the day, and
# changing one without the other changes how much of the day he spends in bed.
# Where in the day that bed sits is not decided here; see stay_up.gd.
#
# A wrong value here presents as "he never sleeps" or "he naps constantly"
# rather than as a units error, so if the cycle ever looks off, suspect these
# before the actions.
@export var base_adenosine_per_hour := 2.5              # while awake
@export var base_adenosine_cleared_per_hour := 5.0      # while asleep
@export var adenosine_ceiling := 100.0

# Unlike the pair above, hunger gets no awake/asleep split at all — see the
# unbranched line in run_upkeep below for why.
@export var base_hunger_per_hour := 4.0
@export var hunger_ceiling := 100.0

# Same reasoning as hunger's, in the same words: no awake/asleep branch,
# because nothing about SLEEPING answers what company he's had — only company
# does. A man alone in a locked room gets no lonelier for staying up, and no
# less lonely for turning in.
#
# 2.5, NOT hunger's 4.0, and the difference is a measurement, not a mood.
# Hunger's rate is DERIVED — two meals a day is forced by conservation
# against what a loaf fixes. Loneliness has no loaf: the only drain is time
# actually spent in company, and the town can supply roughly an evening of
# it. At 4.0 a man accrued 96 a day, woke SATURATED every morning (sleep
# adds a third of the scale with nothing draining it), and a standing
# saturated bid captured whole days — measured: one 33-hour waking stretch
# and a 16-hour sleep to pay for it. At 2.5 the daily accrual closes on one
# tavern evening, mornings start where work outbids company, and loneliness
# saturates only after a full day and a half of genuine isolation — a
# SLOWER gap than hunger, which is what it always was in the fiction.
@export var base_social_per_hour := 2.5
@export var social_ceiling := 100.0


# PUBLIC, AND THAT IS THE POINT — this is the one door time comes through.
#
# It used to be `_update_body`, private, reachable only by finishing a whole
# think_and_act. That made "he is not deciding" and "nothing happens to him"
# the same event, which is wrong in exactly one direction and the direction
# matters: a man held out of the loop for any reason stopped getting hungry,
# stopped getting tired, and stopped getting lonely for as long as he was
# held. Time stood still for him and ran for everybody else.
#
# The header above says upkeep is what happens to him WHETHER HE DECIDES IT
# OR NOT. Private, that read as "whatever he decides"; public, it also covers
# "whether or not he was allowed to decide at all" — a man mid-conversation,
# a distant village stepped coarsely, anybody a later mechanism holds out of
# the ballot. Every one of those still lives. Nothing may skip a person
# without calling this, and Person.run_upkeep is the shape to call.
func run_upkeep(hours: float) -> void:
	var tired: float = person.stats.get_stat(&"adenosine")
	if is_awake():
		tired += get_adenosine_accumulation() * hours
	else:
		tired -= get_adenosine_recovery() * hours
	person.stats.set_stat(&"adenosine", clampf(tired, 0.0, adenosine_ceiling))

	# ONE LINE, NO BRANCH — and the missing branch is deliberate. Adenosine
	# above reads differently awake versus asleep because sleep is the thing
	# that clears it; nothing clears hunger by sleeping, only eating does (see
	# eat_step.gd), so upkeep has exactly one behaviour for this stat, all day
	# and all night alike. That is exactly why he wakes up hungry: the eight
	# hours he spent asleep were eight more hours of this line running.
	var hungry: float = person.stats.get_stat(&"hunger")
	hungry += get_hunger_accumulation() * hours
	person.stats.set_stat(&"hunger", clampf(hungry, 0.0, hunger_ceiling))

	# ONE LINE, NO BRANCH, SAME REASONING AS HUNGER'S ABOVE. Sleep clears
	# adenosine because sleep is the thing that answers tiredness; nothing
	# about sleeping answers loneliness, only company does (see
	# actions/socialise_step.gd), so this runs identically whether he's awake
	# or out cold.
	var lonely: float = person.stats.get_stat(&"social")
	lonely += get_social_accumulation() * hours
	person.stats.set_stat(&"social", clampf(lonely, 0.0, social_ceiling))


# How fast he's tiring right now, per world hour, after everything that affects it.
#
# This is a seam, and worth having one even though there's a single modifier
# behind it today. Everything that will ever change how fast someone tires —
# illness, age, cold, a stimulant, a wound — goes in here as one more factor,
# and no caller anywhere changes. It also means the rate is a number you can
# plot, so "why is he tiring so fast today" is something you look at rather
# than reason about.
#
# It is a function doing arithmetic, deliberately, and should stay one. If it
# ever grows a list of registered modifiers with priorities and stacking rules,
# that's a system, and systems built before they're needed get thrown away.
#
# Modifiers multiply rather than add: they compose in any order and can't drive
# the rate negative. Watch the stacking though — three 2× modifiers is 8×, not
# 6×. At four factors, revisit; not before.
func get_adenosine_accumulation() -> float:
	return base_adenosine_per_hour * get_exertion()


# How fast he's hungering right now, per world hour. The same seam shape as
# the accumulation above it — everything that will ever change how fast
# someone hungers (illness, cold, a hard day's work, a growing boy) lands in
# here as one more factor, and no caller anywhere has to change to get it. A
# function doing arithmetic today; a rate you can plot rather than reason
# about, same as its neighbour.
func get_hunger_accumulation() -> float:
	return base_hunger_per_hour


# How fast he's growing lonelier right now, per world hour. The same seam
# shape as its two neighbours above — everything that will ever change how
# fast someone misses company (a temperament, a grief, a crowd he can't
# stand) lands in here as one more factor, and no caller anywhere has to
# change to get it.
func get_social_accumulation() -> float:
	return base_social_per_hour


# How fast he's recovering, per world hour. The mirror of the above, and the
# seam every future modifier lands in — sleeping in a bed versus a ditch,
# sleeping ill, sleeping cold. Sleeping in a strong body is the first of them.
#
# STRENGTH IS WHY TWO FARMERS DON'T WAKE AT THE SAME MOMENT. The sun anchors
# everybody's cycle to the same hour, so two men from the same scene wake on the
# same tick forever — and then who gets the one plot is decided by the order
# they happen to sit in the scene tree, which is nobody's design. A stronger man
# clears the same debt in fewer hours, so he is up first, every day, for a
# reason you can point at. The formula is the same for both of them; only the
# body differs. See stats.gd for why this hangs on recovery and not on how fast
# he tires — that direction inverts the answer and runs at a cliff.
func get_adenosine_recovery() -> float:
	if person == null:
		return base_adenosine_cleared_per_hour
	var strength: float = person.stats.get_stat(&"strength")
	return base_adenosine_cleared_per_hour * strength


# How strenuous what he's doing right now is. 1.0 when he isn't doing anything
# in particular, which is also the default on every step — so an unconsidered
# action costs a normal amount rather than nothing.
# What his body should look like, or empty if whatever he is doing has nothing
# to say about it. The same five lines as get_exertion below and deliberately
# so: both ask the STEP, because both are facts about the work being done
# rather than about the reason for doing it.
func get_clip() -> StringName:
	if current_action == null or current_action.step == null:
		return &""
	return current_action.step.get_clip_for(person)


func get_exertion() -> float:
	if current_action == null or current_action.step == null:
		return 1.0
	return current_action.step.exertion


# What he'd be seen doing, both halves. The Action says why — "sleep" — and the
# step says what — "out cold". Reporting only one of them throws away the half
# a reader actually needs.
func describe_current_action() -> String:
	if current_action == null:
		return "…"
	var why: String = current_action.label if not current_action.label.is_empty() else String(current_action.name)
	var what: String = current_action.step.describe(person) if current_action.step != null else ""
	return why if what.is_empty() else "%s — %s" % [why, what]
