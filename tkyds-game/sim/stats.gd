class_name Stat
extends RefCounted

# Canonical stat names. Every get_primary / write_primary / get_derived call
# names its stat from here, so the whole vocabulary is greppable in one place.

# --- Actor primaries: the needs substrate -----------------------------------
const HUNGER := &"hunger"                          # 0 = full, 100 = starving
const FOOD := &"food"                              # units held
const COIN := &"coin"                              # money held
const WILLINGNESS := &"willingness"                # will to keep working
const ROLE := &"role"                              # current economic role
const PRODUCING_TICKS_LEFT := &"producing_ticks_left"
const STALLED := &"stalled"                        # producer whose workers refuse

# --- Actor primaries: the social substrate ----------------------------------
const PLACE := &"place"        # where this actor is; proximity = same place
const POISE := &"poise"        # composure under pressure; drains in a confrontation, yields when low
const STANDING := &"standing"  # public social weight; spent when you put yourself forward
const BELONGING := &"belonging"  # feeling of being included; a shared drink relieves it

# --- Actor primaries: sim bookkeeping ---------------------------------------
const PRESS_COOLDOWN := &"press_cooldown"  # ticks before this actor can start another press

# --- Edge primaries (a → b relationship, stored sparsely) -------------------
const FAVOR := &"favor"    # accrued obligation a holds toward b; the durable channel
const REGARD := &"regard"  # how a feels about b right now; negative = dislike
const SIZING_TICKS := &"sizing_ticks"  # how long a has been sizing b up
const SEEN_RUNG := &"seen_rung"        # the rung the OBSERVER last saw b show them (the prosthesis)

# --- Derived (computed on read, never stored) -------------------------------
const GREETING_RUNG := &"greeting_rung"  # discrete rung a shows toward b
# (Threat and backing are evaluations, not stats: they read live confrontation
# state — who has committed as a backer — which lives on demands, not in the
# store. They are computed in Simulation. See the decisions doc.)

# --- Sandbox examples (behavior sandbox; see sandbox/) ----------------------
const ENERGY := &"energy"   # 0 = spent, 100 = fresh; work drains it, rest restores it
const VIGOR := &"vigor"     # derived: how much doing an actor has in them right now
