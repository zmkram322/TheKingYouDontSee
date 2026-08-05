class_name WorldTune
extends RefCounted

# --- Tunable constants for the world ----------------------------------------
# THE one constants block for world content, mirroring sandbox_tuning.gd's
# role for the sandbox: every invented number a world leaf, curve, or clock
# uses lives here, named, so the whole world can be tuned in one sitting.
# Do not scatter literals.
#
# --- The shared scoring scale ---
# Every candidate — a need, an errand, a lord's order — lands on one number
# line and the highest bid wins, so the units have to mean something. The
# unit is: ONE POINT OF SCORE = ONE POINT OF UNMET PRIMARY NEED. A stat like
# hunger IS its own score ("get some food" bids exactly the hunger value),
# so a need at its ceiling bids NEED_FULL, and an author pricing an
# obligation answers "how desperate a need should this outbid?" in those
# same points — an order worth 90 outbids any single bodily need, an order
# worth 30 loses to real hunger, and that is the whole conversion.
#
# The one scale that does NOT fit: spatial appeal. The existing inn-choosing
# curve bids (SPATIAL_REACH - distance) in raw pixels, peaking at 400 —
# nearly seven fully-desperate needs. It survives today only because it
# lives inside a nested Choice, ranking inn against inn where the inflated
# units cancel out. The moment a curve on that scale sits beside a need at
# the top level, pixels outbid starvation. Both ceilings are named here so
# the collision is visible in one screenful; the day-curve work that first
# consumes this block is expected to bring spatial appeal onto the need
# scale rather than the other way around.

# --- The clock ---
const DAY_LENGTH_SECONDS := 120.0    # one day of world time; time_of_day() is the fraction of this

# --- The need scale (top-level scoring, brain suites' hunger runs 0..60) ---
const NEED_FULL := 60.0              # what a need at its ceiling bids; the yardstick obligations are priced against

# --- The spatial scale (nested inn-choice curve: SPATIAL_REACH - distance, pixels) ---
const SPATIAL_REACH := 400.0         # where nearness appeal runs out; standing on the spot bids the full 400

# --- Eating ---
const EAT_RATE := 40.0               # hunger cleared per second at table; a full belly from NEED_FULL takes 1.5s

# --- The day curves ---
# Two facts the clock hands out about the shape of a day, read through
# world.curve(). Both are weight, never permission — a curve at zero must
# never be the reason nothing is choosable, only the reason something else
# wins the score. Priced against NEED_FULL like everything else on this
# scale, so a full-strength curve can sit next to a need honestly instead of
# quietly outbidding or losing to it by accident.
#
# WORK_CURVE_PEAK sits at half of NEED_FULL: at high noon, the pull to work
# is worth as much as a need that's half gone — real enough to send a
# comfortable character to the field, but a genuinely hungry one still wins,
# because 30 loses to any hunger reading above 30. SOCIAL_CURVE_PEAK sits a
# little lower, at 0.4 of NEED_FULL: the inn's call at dusk is real, but a
# character who is actually starving should still eat before she socialises.
# Both are hand-tuned anchors for two named shapes, not a general
# curve-authoring system — the day only has two of these today.
const WORK_CURVE_PEAK := 30.0        # NEED_FULL * 0.5 — work's strongest pull, at midday
const SOCIAL_CURVE_PEAK := 24.0      # NEED_FULL * 0.4 — the inn's strongest pull, at dusk

# The anchors that shape urge_to_work: silent before dawn, climbing through
# the morning, held flat through the working day, winding down across the
# afternoon, silent again by evening. All four are fractions of the day,
# same units as time_of_day().
const WORK_RISES_FROM := 0.20        # dawn — the pull starts climbing off the floor
const WORK_FULL_BY := 0.35           # mid-morning — full strength from here through the plateau
const WORK_FADES_FROM := 0.60        # early afternoon — the plateau ends, the wind-down begins
const WORK_SILENT_BY := 0.80         # evening — back to nothing

# The anchors that shape urge_to_be_social: silent through the working day,
# climbing as work falls off, held flat for the evening, fading back to
# nothing overnight. Deliberately overlapping WORK_FADES_FROM/WORK_SILENT_BY
# rather than picking up where work leaves off — the overlap is what makes
# the two curves cross instead of merely taking turns.
const SOCIAL_RISES_FROM := 0.55      # work is visibly winding down; the evening pull starts climbing
const SOCIAL_FULL_BY := 0.75         # dusk — full strength, while work is still fading through it
const SOCIAL_FADES_FROM := 0.80      # evening plateau ends
const SOCIAL_SILENT_BY := 0.98       # deep night — back to nothing

# --- Reconsidering ---
# How often the world pokes a settled character to ask whether the world has
# moved out from under their decision — see VillageWorld.reconsider(). Chosen
# only after Action.interrupt_threshold existed to defend an incumbent: without
# resistance, a short window here is exactly the failure this pairing exists to
# avoid — a fast, unresisted poke turns a score that dips mid-pursuit into
# constant swapping, not responsiveness. With resistance in place, a short
# window stops being dangerous and becomes pure responsiveness — a fright is
# felt within half a second, not held hostage to a coarse cadence picked to be
# safe on its own.
const RECONSIDER_SWEEP_SECONDS := 0.5

# --- Obligations ---
# FR102's authored-constant seam: the weight an obligation carries into a
# scoring pass is supplied here as a flat number until channels exist to
# compute it from who's asking and how urgently — replacing this constant
# with that computation is the whole migration, and no call site changes
# when it happens.
#
# FLOUR_ERRAND_WORTH sits at two-thirds of NEED_FULL: comfortably above a
# flat filler (a doze, a sweep) and above either day curve at full strength
# (WORK_CURVE_PEAK and SOCIAL_CURVE_PEAK both sit lower), so the errand is a
# real pull, not something an idle moment beats by accident. But a
# character whose own need has already climbed past 40 — two-thirds of the
# way to its own ceiling — still finishes tending to themselves first. An
# order priced at 90 would outbid any need outright; this one competes
# honestly instead of commanding.
const FLOUR_ERRAND_WORTH := 40.0

# GRAIN_ERRAND_WORTH is priced identically to FLOUR_ERRAND_WORTH and for the
# same reason: both are "someone genuinely needs a real thing carried," not
# a superior's order, and neither deserves to outrank the other just because
# one sits one link further from the visible need (bread) than the other.
# A farmhand mid-haul still finishes eating first once his own hunger climbs
# past 40 — the identical defence FLOUR_ERRAND_WORTH's own comment makes for
# the miller.
const GRAIN_ERRAND_WORTH := 40.0

# --- The village content built in world/village.gd --------------------------
# Everything below prices the real five-person village against the same
# scale as everything above. The two chores that convert stock at a place
# over time (grinding, baking) and the two that carry stock between places
# (flour delivery, grain hauling) are one leaf apiece — see
# world/convert_stock.gd and world/carry_stock.gd — tuned per use through
# these constants rather than through separate classes.

# Grinding: one full batch (GRIND_BATCH grain -> GRIND_BATCH flour_ground)
# takes GRIND_SECONDS of continuous work. Numbers proven in emit_smoke.gd's
# fixture and promoted here unchanged — a batch a second is fast enough that
# a morning's hauled grain doesn't sit waiting behind a slow mill, yet slow
# enough that the mill's own grinding_progress fact is genuinely worth
# keeping on the place rather than resolving in a single tick.
const GRIND_SECONDS := 1.0
const GRIND_BATCH := 10.0

# Baking: half the batch size of grinding, same cadence — a modest flour
# delivery already lets several loaves finish before the inn runs dry again,
# so bread keeps pace with three hungry farmhands without flour piling up
# unused at the inn.
const BAKE_SECONDS := 1.0
const BAKE_BATCH := 5.0

# Carrying: flour from the mill to the inn, grain from the field to the
# mill. Both move at the same pace — carrying is carrying, and there is no
# authored reason grain should travel faster or slower than flour — so one
# rate serves both call sites.
const CARRY_RATE := 10.0

# Working the field: one farmhand alone fills a full grind batch
# (GRIND_BATCH) in ten seconds of steady work — fast enough that a single
# morning's labour keeps the mill fed, slow enough that the field is a real
# bottleneck rather than a formality. FIELD_GRAIN_CAP is a backstop, not a
# tuned value: a pile only reached after three straight minutes of nobody
# ever hauling, well past anything this village's chain is meant to let
# happen.
const FIELD_YIELD_RATE := 1.0
const FIELD_GRAIN_CAP := 200.0

# The hysteresis bands that keep each errand justified through partial
# delivery — see emit_smoke.gd's own note on why a single shared threshold
# would let the first delivered speck expire the errand mid-carry. Flour's
# band is proven in emit_smoke.gd and promoted unchanged. Grain's band is
# three grind batches wide (GRAIN_STOCKED_AT - GRAIN_LOW_AT = 25, well over
# GRIND_BATCH's 10) so a single haul is never caught reading as "no longer
# needed" partway to the mill.
const FLOUR_LOW_AT := 1.0
const FLOUR_STOCKED_AT := 10.0
const GRAIN_LOW_AT := 5.0
const GRAIN_STOCKED_AT := 30.0

# Flat scores for the village's fillers. Dull and always open, same tier as
# emit_smoke's proven fixture numbers, promoted here unchanged now that
# they're pricing real content rather than a fixture.
const SWEEP_SCORE := 5.0
const DOZE_SCORE := 5.0

# Grinding and baking, by contrast, are priced well above SLEEP_SCORE (22)
# rather than at emit_smoke's original fixture value of 20 — Osric and Maren
# don't run on a day curve the way the farmhands do, so once SLEEP_SCORE was
# raised to win its own race against a farmhand's dawn hunger (see that
# constant's comment), a miller or innkeeper with real work in front of them
# would otherwise have found bed a flat, unconditional improvement over the
# job at any hour, day or night. Priced at WORK_CURVE_PEAK instead: real
# work, not idle filler, worth exactly as much as tending the field is to a
# farmhand, and comfortably clear of both SLEEP_SCORE and the two dull
# fillers.
const GRIND_SCORE := WORK_CURVE_PEAK
const BAKE_SCORE := WORK_CURVE_PEAK

# Sleep: a flat score with no gate, the same shape the design calls for —
# no tiredness stat, no third curve. The threshold sits at 22, chosen to
# win the RACE against hunger at dawn without ever contesting the day
# curves once they're actually up: WORK_CURVE_PEAK's own rise (a smoothstep
# from WORK_RISES_FROM to WORK_FULL_BY) crosses 22 a few seconds before
# HUNGER_DRIFT_RATE's steady climb from a fresh day's hunger=0 does, so work
# always wakes the village before an early snack ever could — a SLEEP_SCORE
# much below this lets hunger win that race and drags everyone up for
# breakfast before dawn's own pull gets a say, which was observed and isn't
# the story this village is meant to tell. Priced under SOCIAL_CURVE_PEAK
# (24) so the inn's own dusk plateau still outbids bed cleanly — sleep must
# survive WORK's plateau, but never needs to survive SOCIAL's. Comfortably
# above both fillers (5), so bed still wins the instant both curves have
# genuinely gone quiet at night.
const SLEEP_SCORE := 22.0

# How fast an idle farmhand's hunger drifts upward — the content chore in
# village.gd applies this against real elapsed seconds, the same rate
# EAT_RATE already clears it at in reverse. Over a full DAY_LENGTH_SECONDS
# with no meal at all, hunger comfortably reaches NEED_FULL well before the
# day is out: a farmhand who skips eating entirely is genuinely starving,
# not merely peckish, and the day arc's midday crossing has room to happen
# inside the work plateau rather than right at its edge.
const HUNGER_DRIFT_RATE := 0.6

# The meal's defence against the exact livelock reconsider_smoke.gd
# demonstrates: hunger is the score eating is chosen for, and it falls as
# the meal is pursued, so an unguarded meal loses to whatever else is
# scoring once hunger dips below it. Defended at WORK_CURVE_PEAK — the
# higher of the two day curves — so that for as long as any real hunger
# remains (hunger > 0), the incumbent meal's effective score
# (hunger + MEAL_INTERRUPT_THRESHOLD) always clears the strongest curve
# either one could ever present, and a meal once begun always finishes
# rather than being bumped by the clock moving underneath it. An urgent
# errand (GRAIN/FLOUR_ERRAND_WORTH, both above this) can still interrupt a
# nearly-finished meal — obligations are meant to compete honestly, not be
# structurally barred by a defence meant for the day curves.
const MEAL_INTERRUPT_THRESHOLD := WORK_CURVE_PEAK
