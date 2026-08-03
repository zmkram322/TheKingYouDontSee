class_name SandboxTune
extends RefCounted

# --- Tunable feel constants for the behavior sandbox ------------------------
# THE one constants block for the sandbox. Every invented number the sandbox
# uses lives here, named, so the loop can be tuned by hand in one sitting.
# Mirrors sim/tuning.gd's role for the core sim — do not scatter literals.

# --- Drift (ambient, independent of what anyone is doing) ---
const HUNGER_PER_SECOND := 2.0
const ENERGY_DRIFT_PER_SECOND := 0.5    # ambient tiredness, even idling

# --- Movement ---
const WALK_SPEED := 90.0                # pixels/second

# --- Eating at the inn ---
const MEAL_PRICE := 5
const MEAL_RELIEVES_HUNGER := 55.0

# --- Working the field ---
const WAGE := 8
const WORK_DRAINS_ENERGY := 30.0

# --- Resting at home ---
const REST_RESTORES_ENERGY := 65.0

# --- Stat ceilings ---
const ENERGY_MAX := 100.0
const HUNGER_MAX := 100.0

# --- Appeal weights/shapes — author-editable curve constants ---
const W_EAT := 100.0
const W_WORK := 60.0
const W_REST := 80.0
const IDLE_APPEAL := 6.0        # the floor: what "nothing presses" scores
const COIN_COMFORT := 20.0      # coin level above which working stops appealing

# --- Fear / safety interrupt ---
const FEAR_MAX := 100.0
const FEAR_DECAY_PER_SECOND := 8.0    # ambient calm-down, same shape as hunger/energy drift
const SCARE_AMOUNT := 80.0            # what the "Scare" button adds, clamped to FEAR_MAX
const THREAT_THRESHOLD := 55.0        # the lingering read (below) must clear this to count as threatened
const FEAR_LINGER_EXPONENT := 0.5     # < 1: FEAR_MAX * (fear/FEAR_MAX)^X reads higher than raw fear
                                       # as fear decays, so the threat reading lingers after a scare
                                       # without needing a second threshold or any stored history
const W_SHELTER := 120.0              # above every other option's ceiling, so it wins outright once threatened
const SHELTER_DURATION := 4.0         # short cycle so a cleared threat is noticed at the next seam

# --- Passerby greeting ---
# Smaller than the ~36px gap between Berta's and Fen's starting spots, so the
# smoke test's first-choice assertions can't be disturbed by a false trigger
# at t=0 — verified by running the smoke test, not just by this comment.
const GREET_PROXIMITY_RADIUS := 24.0
const GREET_COOLDOWN_SECONDS := 20.0  # how long before the same actor will greet again
const GREET_DURATION := 1.0           # brief — a nod in passing, not a conversation
const W_GREET := 12.0                 # modest: beats idling, never competes with a real need
