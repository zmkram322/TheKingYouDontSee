class_name Tune
extends RefCounted

# --- Tunable feel constants -------------------------------------------------
# THE one constants block. Every invented number in the sim lives here, named,
# so it can be tuned by hand in one sitting. Do not scatter literals.

# --- Hunger & food ---
const HUNGER_PER_TICK := 6.0
const HUNGER_NEED_THRESHOLD := 50.0
const HUNGER_MAX := 100.0
const EAT_REDUCES_HUNGER := 70.0  # a meal actually fills you up (drops below threshold)
const PRODUCE_TICKS := 2          # ticks a producer spends on a batch
const FOOD_PER_PRODUCTION := 2    # batch size — leaves buffer stock so one producer feeds several

# --- Money & willingness ---
const FOOD_RETAIL_PRICE := 3      # what an eater pays the merchant for 1 food
const FOOD_WHOLESALE_PRICE := 2   # what the merchant pays the producer for 1 food
const WAGE_PER_BATCH := 3         # what a producer pays each worker when a batch lands
const EMPLOYMENT_COIN_THRESHOLD := 20   # a consumer this broke goes looking for a job
const PRODUCER_STARTING_EQUITY := 250   # a producer's capital — must outlast its payroll
const WILLINGNESS_MAX := 100.0
const QUIT_THRESHOLD := 20.0            # below this, a worker refuses to work
const WILLINGNESS_HUNGER_DRAIN := 0.03  # per tick × current hunger — hunger erodes willingness
const WAGE_WILLINGNESS_BOOST := 25.0    # a paycheck restores willingness — "everyone has a price"

# --- Drinks & belonging (the investment act) ---
const DRINK_PRICE := 3                   # paid to the keeper — coin is conserved, never spawned
const BELONGING_FROM_ROUND := 40.0
const BELONGING_MAX := 100.0
const BELONGING_NEED_THRESHOLD := 50.0   # below this the driver is unmet: the tell shows, and relief accrues favor
const REGARD_COURTESY_BUMP := 5.0        # any gift is at least polite
const FAVOR_PER_RELIEVED_NEED := 18.0    # the channel: one relieved need ≈ one greeting rung
const FAVOR_DECAY_PER_TICK := 0.1
const FAVOR_SPENT_WHEN_ACTED := 10.0     # obligation partially discharged by acting on it
const GRATITUDE_FAVOR := 15.0            # what the rescued now owe their rescuer

# --- Greeting rungs (discrete bands over favor + regard; derived, never stored) ---
const RUNG_HOSTILE_BELOW := -25.0
const RUNG_COLD_BELOW := 5.0             # strangers (0) read cold
const RUNG_NEUTRAL_BELOW := 25.0
const RUNG_WARM_BELOW := 55.0            # at or above reads devoted

# --- Standing & poise ---
const STANDING_DEFAULT := 10.0
const STANDING_NEED_THRESHOLD := 20.0    # below this, the standing drive is unmet
const POISE_DEFAULT := 50.0
const POISE_MAX := 100.0
const POISE_REGEN_PER_TICK := 4.0        # recovery when not pressed — no unrecoverable state

# --- Pressing (a confrontation chosen from state, not a goal) ---
const PRESS_DWELL_TICKS := 3             # ticks spent sizing a target up before moving
const PRESS_START_THRESHOLD := 12.0
const PRESS_SUSTAIN_THRESHOLD := 10.0    # re-scored every tick; below this the aggressor backs down
const PRESS_COOLDOWN_TICKS := 12
const W_STANDING_HUNGER := 1.5           # pull of an unmet standing drive
const W_GRUDGE := 0.5                    # pull of negative regard toward the target
const W_THREAT := 1.0                    # push of the target's VISIBLE threat (latent channels never enter)
const W_BACKER := 2.0                    # a committed defender reads heavier than bystander standing
const THREAT_POISE_WEIGHT := 0.2
const DRAWDOWN_PER_TICK := 9.0
const YIELD_THRESHOLD := 10.0            # poise floor: yield, lose standing, recover after
const YIELD_STANDING_LOSS := 3.0
const PRESS_STANDING_GAIN := 6.0

# --- Aid (emitted by the sim for any pressed actor; picked up by a scored, refusable evaluation) ---
const AID_CALL_THRESHOLD := 45.0         # poise below this emits the aid demand — early enough that a would-be backer visibly deliberates before peril pushes them over
const INTERVENE_THRESHOLD := 10.0
const INTERVENE_BASE_RELUCTANCE := 10.0  # stepping into someone else's fight costs something by default
const INTERVENE_STANDING_SPEND := 4.0
const W_AID_FAVOR := 1.0                 # the held channel — dominant term by design
const W_AID_PERIL := 0.6                 # urgency grows as drawdown deepens; this is the hesitation beat
const W_AID_DANGER := 0.5                # the aggressor's visible threat argues against stepping in
const PERIL_POISE_BASELINE := 50.0
