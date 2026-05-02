---
name: Prototype v0 Build Spec
status: Locked, ready to build
date: 2026-05-01
supersedes_for_prototype_scope:
  - "_bmad-output/supplement-prototype-gaps.md"
  - "_bmad-output/planning-artifacts/godot-rewrite-plan.md"
target_codebase: "tkyds-game/scripts/"
engine: "Godot 4.x, GDScript"
---

# The King You Don't See — Prototype v0 Build Spec

## Purpose

Build the smallest economic loop that exercises every signal-and-clearing path the planned simulation will need. No survival, no needs, no aptitudes, no skills, no morale, no hierarchy AI. Five Actors, one good, four windows, three markets, two simulated weeks. If this loop runs cleanly and the success criteria are observable, the architecture is sound and we can hang real economic logic on it without rebuilding the spine.

This is a clean break from the previous prototype design (`supplement-prototype-gaps.md` and `planning-artifacts/godot-rewrite-plan.md`). Aptitude/skill/morale/lord-AI work is deferred until the loop architecture is proven.

## Architectural invariants this prototype proves

1. **Tick → window → market separation works.** Time advances independent of windows. Windows open and close as named events on a bus. Markets only clear when their window closes.
2. **Bus decoupling holds.** Anyone can fire a window signal — the orchestrator initially, debug tools later, scenario scripts eventually. Subscribers don't know who fired.
3. **Synchronous emit gives "all reported" for free.** When the orchestrator opens a window, every connected handler runs before the call returns. Closing the window after that emits against fully-populated pools. No barrier counters needed.
4. **Interests as first-class drivers.** Behavior is not "the actor decides what to do at this tick" — it's "the actor's interests subscribe to the signals they care about, and the actor is the sum of its interests."
5. **Actors don't know their region.** Interests hold direct refs to the markets they emit to, set at bootstrap. The Region is a structural container, not a back-reference.
6. **Region scope from day one** even with N=1. All markets are owned by a Region. No global market singletons.

---

## Bootstrap inventory

| | Count | Notes |
|---|---|---|
| Region | 1 | Owns all markets and all actors |
| LandOwner | 1 | Owns the LandPlot in their accounts |
| LandPlot | 1 | A `ProductionResource` in LandOwner's accounts |
| Worker | 2 | Begin unemployed |
| Merchant | 1 | Begins with starting coin, no inventory |

### Initial conditions

| | Value |
|---|---|
| `LandPlot.size` | 1.0 |
| `LandPlot.base_output_per_work_unit` | 1.0 grain per slot worked |
| `LandPlot.producible_goods` | `["grain"]` |
| `ProductionInterest.desired_workers` | 2 |
| Flat wage (placeholder calculator) | 1 coin per slot worked |
| Flat wholesale price (placeholder clearing) | 1 coin per grain |
| Flat retail price (placeholder clearing) | 1 coin per grain |
| `GrainInterest` flat demand | 2 grain per Actor per day |
| LandOwner starting coin | 200 |
| Worker starting coin | 0 |
| Merchant starting coin | 100 |
| Merchant `target_inventory` | 60 grain |

Numbers are chosen so the loop is self-consistent on day one: production = consumption (56 grain/week), wage bill (56 coin/week) << LandOwner runway, merchant has buying power. We can knock things out of balance later to *test* clearing logic; for v0 we want the loop to just run.

---

## Time architecture

### Tick cadences (`SimClock` autoload)

```
signal daily_tick(slot: TimeSlot)   # fires 8x per simulated day, in slot order
signal weekly_tick()                # fires once per simulated week
```

`weekly_tick()` fires *during* `EARLY_MORNING` of day 7, immediately after the `daily_tick(EARLY_MORNING)` for that day resolves. (Reserved for later: monthly_tick, yearly_tick.)

### TimeSlot enum

```
EARLY_MORNING, MID_MORNING, LATE_MORNING,
EARLY_AFTERNOON, LATE_AFTERNOON,
EARLY_EVENING, LATE_EVENING,
MIDDLE_OF_NIGHT
```

### Windows (`WindowBus` autoload)

A window is a pair of signals on the bus. Anything can open or close it; subscribers don't know or care who.

| Window | Opens on | Closes on | Cadence |
|---|---|---|---|
| Labor Market (LMW) | `LATE_EVENING` | explicit close after open returns | Daily |
| Work (WW) | `MID_MORNING` | `EARLY_EVENING` | Daily |
| Wholesale Market (WMW) | weekly tick (during `EARLY_MORNING` day 7) | explicit close after clearing | Weekly |
| Retail Market (RMW) | immediately after WMW closes (same tick) | explicit close after clearing | Weekly |

Plus two non-window bus signals:

| Signal | Fires on | Triggers |
|---|---|---|
| `merchant_restock` | weekly tick, before WMW opens | `MercantileInterest.place_buy_order_at_wholesale()` |
| `wages_due` | weekly tick, after RMW closes | `LandOwner.pay_outstanding_wages()` |

`WindowOrchestrator` (autoload) is the only thing that listens to `SimClock` and decides which bus signals to fire when. Replacing or extending it is how we'd add new triggers later (debug tools, scenario scripts).

### Daily flow (regular day, no weekly tick)

```
EARLY_MORNING       (no windows fire)
MID_MORNING         WindowBus.open_work_window()
                      Worker.WorkingInterest sets work_state = WORKING (if has active_contract)
                      WindowBus.close_work_window() is NOT called yet
LATE_MORNING        Worker.WorkingInterest.do_one_work_slot() — accrue 1 grain to worker inventory
EARLY_AFTERNOON     same
LATE_AFTERNOON      same
EARLY_EVENING       WindowBus.close_work_window()
                      Worker.WorkingInterest.hand_grain_to_owner_and_bill()
                        - transfer all grain from worker.inventory to LandOwner.inventory
                        - emit payable to LandOwner.payables (wages owed)
                        - work_state = EMPLOYED_NOT_WORKING
                      LandOwner.ProductionInterest.send_grain_to_wholesale()
                        - emit supply (whatever just landed in inventory) to WholesaleMarket
                        (Wholesale supply pool accumulates daily; only clears weekly.)
LATE_EVENING        WindowBus.open_labor_market()
                      LandOwner.ProductionInterest.post_jobs() — open positions = desired_workers - filled
                      Worker.WorkingInterest.look_for_work() — only if work_state == IDLE
                    WindowBus.close_labor_market()
                      LaborMarket.clear() — match available workers to open positions; write LaborContracts
                    Each Actor.GrainInterest.place_grain_order()
                      - increment own outstanding_demand for grain by flat constant
                      - emit demand to RetailMarket
                      (Retail demand pool accumulates daily; only clears weekly.)
MIDDLE_OF_NIGHT     (no windows fire)
```

Worker's MID_MORNING also calls `do_one_work_slot()` for that slot — work happens *during* the slot WW opens on, not just subsequent slots. So 4 slots of work per day (MID_MORNING through LATE_AFTERNOON), 4 grain per worker per day.

### Weekly flow (day 7 — adds steps to `EARLY_MORNING`)

```
EARLY_MORNING       SimClock.daily_tick(EARLY_MORNING) fires (no windows on this slot)
                    SimClock.weekly_tick() fires
                      WindowOrchestrator handles weekly_tick:
                        WindowBus.merchant_restock
                          Merchant.MercantileInterest.place_buy_order_at_wholesale()
                            - emit demand to WholesaleMarket (target_inventory - current holdings)
                        WindowBus.open_wholesale_market()
                          (supply already in pool from past week of WW-close emissions)
                        WindowBus.close_wholesale_market()
                          WholesaleMarket.clear() — match supply to demand at flat price
                        Merchant.MercantileInterest.send_inventory_to_retail()
                          - emit supply (just-bought grain) to RetailMarket
                        WindowBus.open_retail_market()
                          (demand already in pool from past week of GrainInterest emissions)
                        WindowBus.close_retail_market()
                          RetailMarket.clear() — match supply to demand at flat price
                            - on each transfer, decrement consumer's GrainInterest.outstanding_demand
                        WindowBus.wages_due
                          LandOwner.pay_outstanding_wages()
                            - walk payables, decrement own coin, increment each worker's coin, clear payable
MID_MORNING         WW open (continues as a normal day from here)
...
```

So day 7 is "normal day plus a weekly burst on the EARLY_MORNING tick." The weekly burst fires entirely synchronously inside the `weekly_tick()` handler.

---

## Class catalog

### Resources (pure data — no behavior, no node dependencies)

```gdscript
# accounts.gd
class_name Accounts extends Resource
@export var coin: int = 0
@export var inventory: Dictionary = {}              # good_id (StringName) -> int qty
@export var owned_resources: Array[ProductionResource] = []
@export var contracts: Array[Contract] = []
@export var payables: Array[Payable] = []           # who I owe and why
@export var receivables: Array[Receivable] = []     # who owes me

# payable.gd
class_name Payable extends Resource
@export var owed_to: NodePath                       # actor reference
@export var amount: int
@export var reason: StringName                      # "wages", future: "rent", etc.

# receivable.gd  -- mirror of Payable, for completeness; may not need until later

# production_resource.gd
class_name ProductionResource extends Resource
@export var resource_id: StringName

# land_plot.gd
class_name LandPlot extends ProductionResource
@export var size: float = 1.0
@export var producible_goods: Array[StringName] = ["grain"]
@export var base_output_per_work_unit: float = 1.0

# contract.gd
class_name Contract extends Resource
@export var status: ContractStatus                  # ACTIVE, EXPIRED, BREACHED
enum ContractStatus { ACTIVE, EXPIRED, BREACHED }

# labor_contract.gd
class_name LaborContract extends Contract
@export var employer: NodePath
@export var worker: NodePath
@export var wage_per_work_unit: int                 # set by WageCalculator placeholder
@export var agreed_at_week: int
```

`Good` is just a `StringName` id in v0 (`"grain"`). Promote to a Resource when goods grow attributes.

### Interests (Resource attached to Actor)

Each Interest holds direct refs to the markets it emits to, set at bootstrap. Interests do NOT subscribe to bus signals themselves — the Actor brokers signals to its interests. (Resources can't be in the scene tree and connecting their callables to autoload signals is awkward.)

```gdscript
# interest.gd
class_name Interest extends Resource
# Base. Subclasses define their own methods; Actor decides which to call when.

# production_interest.gd
class_name ProductionInterest extends Interest
@export var plot: LandPlot
@export var labor_market: LaborMarket               # set at bootstrap
@export var wholesale_market: WholesaleMarket       # set at bootstrap
@export var desired_workers: int = 2
func post_jobs(land_owner: LandOwner) -> void
func send_grain_to_wholesale(land_owner: LandOwner) -> void

# working_interest.gd
class_name WorkingInterest extends Interest
@export var labor_market: LaborMarket
func look_for_work(worker: Worker) -> void
func do_one_work_slot(worker: Worker) -> void       # only acts if worker.work_state == WORKING
func hand_grain_to_owner_and_bill(worker: Worker) -> void

# mercantile_interest.gd
class_name MercantileInterest extends Interest
@export var wholesale_market: WholesaleMarket
@export var retail_market: RetailMarket
@export var good_id: StringName = "grain"
@export var target_inventory: int = 60
func place_buy_order_at_wholesale(merchant: Merchant) -> void
func send_inventory_to_retail(merchant: Merchant) -> void

# grain_interest.gd
class_name GrainInterest extends Interest
@export var retail_market: RetailMarket
@export var daily_demand: int = 2
var outstanding_demand: int = 0                     # incremented on order, decremented on receipt
func place_grain_order(actor: Actor) -> void
func record_receipt(qty: int) -> void               # called by RetailMarket.clear()
```

### Actors (Node)

```gdscript
# actor.gd
class_name Actor extends Node
@export var actor_id: StringName
@export var accounts: Accounts
@export var interests: Array[Interest] = []         # ordered, mixed types

# Connects relevant interests' methods to bus signals at _ready().
# Subclasses override _wire_signals() to declare which signals call which interest methods.
func _ready() -> void: _wire_signals()
func _wire_signals() -> void: pass

# land_owner.gd
class_name LandOwner extends Actor
func _wire_signals() -> void:
  # ProductionInterest.post_jobs on labor_market_opened
  # ProductionInterest.send_grain_to_wholesale on work_window_closed (after workers transfer)
  ...
func pay_outstanding_wages() -> void                # walk payables; decrement coin; pay workers

# worker.gd
class_name Worker extends Actor
@export var work_state: WorkState = WorkState.IDLE
@export var active_contract: LaborContract = null
enum WorkState { IDLE, EMPLOYED_NOT_WORKING, WORKING }
func _wire_signals() -> void:
  # WorkingInterest.look_for_work on labor_market_opened
  # set work_state = WORKING on work_window_opened (if has active_contract)
  # WorkingInterest.do_one_work_slot on daily_tick (interest internally checks work_state)
  # WorkingInterest.hand_grain_to_owner_and_bill on work_window_closed
  # then set work_state = EMPLOYED_NOT_WORKING
  ...

# merchant.gd
class_name Merchant extends Actor
func _wire_signals() -> void:
  # MercantileInterest.place_buy_order_at_wholesale on merchant_restock
  # MercantileInterest.send_inventory_to_retail on wholesale_market_closed (after clearing)
  ...
```

Note on signal order at `work_window_closed`: workers' `hand_grain_to_owner_and_bill` must run *before* LandOwner's `send_grain_to_wholesale`. Easiest enforcement is `_ready()` connection order across actors at bootstrap — connect workers first. If we hit ordering bugs we'll add an explicit two-phase close (`work_window_closing` then `work_window_closed`).

### Markets (Node, owned by Region)

```gdscript
# market.gd
class_name Market extends Node
@export var region: Region
var supply_pool: Dictionary = {}                    # actor (NodePath) -> qty offered
var demand_pool: Dictionary = {}                    # actor (NodePath) -> qty wanted
func take_supply(actor: Actor, qty: int) -> void
func take_demand(actor: Actor, qty: int) -> void
func clear() -> void: pass                          # subclass-specific
func reset_pools() -> void                          # called after clearing

# labor_market.gd
class_name LaborMarket extends Market
# pools hold int qty of "available worker slots" / "open job slots"
# clear() pairs workers to jobs, builds LaborContracts, writes them to both parties' accounts

# wholesale_market.gd
class_name WholesaleMarket extends Market
@export var good_id: StringName = "grain"
# clear() at flat price; transfers grain from owner inventory to merchant inventory; coin reverse

# retail_market.gd
class_name RetailMarket extends Market
@export var good_id: StringName = "grain"
# clear() at flat price; transfers grain from merchant to consumers; coin reverse
# on each transfer, calls consumer.grain_interest.record_receipt(qty)
```

### Region (Node)

```gdscript
# region.gd
class_name Region extends Node
@export var region_id: StringName
@export var actors: Array[Actor] = []
@export var labor_market: LaborMarket
@export var wholesale_markets: Dictionary = {}      # good_id -> WholesaleMarket
@export var retail_markets: Dictionary = {}         # good_id -> RetailMarket
```

### Autoloads

```
SimClock              — drives daily_tick(slot) and weekly_tick(); the only thing
                        that touches simulated time
WindowBus             — open_*/close_* methods plus signals; pure pub/sub
WindowOrchestrator    — listens to SimClock; decides when to call WindowBus methods
                        + the merchant_restock and wages_due burst on weekly_tick
```

No `WorldRegistry` autoload in v0 — Region is a node in the scene tree, actors are children of Region, interests hold direct market refs.

---

## Signal contracts

### `SimClock` (autoload)

```gdscript
signal daily_tick(slot: TimeSlot)
signal weekly_tick()

func _process(delta: float) -> void
  # advances simulated time on a configurable scaling
  # emits daily_tick(slot) at slot boundaries
  # emits weekly_tick() during the EARLY_MORNING tick of day 7
```

For v0 the clock can advance at any rate — fast for testing, slow for observation. Make this configurable from the start.

### `WindowBus` (autoload)

```gdscript
signal labor_market_opened
signal labor_market_closed
signal work_window_opened
signal work_window_closed
signal wholesale_market_opened
signal wholesale_market_closed
signal retail_market_opened
signal retail_market_closed
signal merchant_restock
signal wages_due

func open_labor_market()  -> void: labor_market_opened.emit()
func close_labor_market() -> void: labor_market_closed.emit()
# ... mirror for the other three windows
func fire_merchant_restock() -> void: merchant_restock.emit()
func fire_wages_due() -> void: wages_due.emit()
```

The bus is intentionally dumb — it does not enforce ordering, doesn't track state, doesn't know who's listening. State and order live in `WindowOrchestrator`.

### `WindowOrchestrator` (autoload)

Listens to `SimClock`. On daily and weekly ticks, calls `WindowBus` methods in the right order:

```gdscript
func _ready():
  SimClock.daily_tick.connect(_on_daily_tick)
  SimClock.weekly_tick.connect(_on_weekly_tick)

func _on_daily_tick(slot: TimeSlot):
  match slot:
    TimeSlot.MID_MORNING:    WindowBus.open_work_window()
    TimeSlot.EARLY_EVENING:  WindowBus.close_work_window()
    TimeSlot.LATE_EVENING:
      WindowBus.open_labor_market()
      WindowBus.close_labor_market()

func _on_weekly_tick():
  WindowBus.fire_merchant_restock()
  WindowBus.open_wholesale_market()
  WindowBus.close_wholesale_market()
  WindowBus.open_retail_market()
  WindowBus.close_retail_market()
  WindowBus.fire_wages_due()
```

Replacing or supplementing this orchestrator is how scenario tools or debug commands fire windows manually later. The bus and the subscribers don't need to change.

---

## Build phases

### Phase 1 — Signal flow (deliverable: print-traced two-week run)

- All classes declared with fields and method signatures
- Method bodies are `print()` statements describing what *would* happen
- Bootstrap script: spawn 1 Region with 1 LaborMarket + 1 WholesaleMarket + 1 RetailMarket (grain), spawn 1 LandOwner + 2 Workers + 1 Merchant, attach interests with market refs, connect signals
- Run `SimClock` for 14 simulated days
- **Acceptance:** console output shows the daily and weekly flows in correct order, with the right Actors firing the right Interest methods at the right windows. No math required.

### Phase 2 — Stub math (deliverable: success criteria pass)

- Replace prints with the simplest math that makes the loop self-consistent:
  - LaborMarket.clear() actually creates `LaborContract` instances and writes them to both parties' accounts; matches workers to positions FIFO; placeholder `WageCalculator.calculate_wage()` returns flat 1
  - Worker `do_one_work_slot()` actually adds 1 grain to inventory
  - WW close actually transfers grain to LandOwner and creates `Payable`
  - WholesaleMarket.clear() actually moves grain and coin at flat price
  - RetailMarket.clear() actually moves grain and coin at flat price; updates `outstanding_demand`
  - LandOwner.pay_outstanding_wages() actually walks payables and pays
- Add minimal logging: every coin/grain movement writes a one-line ledger entry
- **Acceptance:** all five success criteria observable in a 14-day run, all account balances reconcile (no coin or grain leaks)

### Phase 3 — Out of scope for v0

- Real clearing math (price elasticity, supply/demand response curves)
- Multiple goods, multiple regions, multiple plots
- Aptitudes, skills, XP
- Needs hierarchy, hunger, morale, condition flags
- Worker incapacity, deficit accumulation, cascade dynamics
- Lord AI, LordLedger, LordPolicyEngine, LordDirective, routine swapping
- Merchant pricing model with target margin
- Multi-market arbitrage, consumer travel decisions
- Burn-in equilibrium, three-tier fidelity, ReadoutMapper
- Save/load, world generation, player character

These are the next-prototype concerns. They will be added to a foundation that runs cleanly under v0. If v0 doesn't run cleanly, fix v0 before adding any of them.

---

## Acceptance criteria — v0 ships when all five are true

1. **Workers gain employment.** After day 1 LMW closes, both workers have an active `LaborContract`; LandOwner's accounts list both contracts.
2. **Work contracts in place.** Contract amounts and references are consistent on both sides (worker.active_contract == land_owner.accounts.contracts[i] for some i).
3. **Workers work, produce resources, emit payables, get paid.** By end of day 1, LandOwner inventory holds 8 grain and `payables` lists 4 coin owed to each worker. By end of day 7's `wages_due`, LandOwner coin decremented by 56, both Workers coin incremented by 28 each.
4. **Owners sell supply in the wholesale market.** After day 7's WMW clears, LandOwner inventory grain transferred to Merchant inventory at flat price; coin moved in reverse.
5. **Workers buy supply in the retail market.** After day 7's RMW clears, Workers (and other consumers) have grain in their inventory; Merchant has coin; consumers' `outstanding_demand` decremented appropriately.

All five must be observable via console / log output without manual debugger inspection.

---

## File layout in `tkyds-game/scripts/`

```
scripts/
  autoloads/
    sim_clock.gd
    window_bus.gd
    window_orchestrator.gd
  resources/
    accounts.gd
    payable.gd
    production_resource.gd
    land_plot.gd
    contract.gd
    labor_contract.gd
  interests/
    interest.gd
    production_interest.gd
    working_interest.gd
    mercantile_interest.gd
    grain_interest.gd
  actors/
    actor.gd
    land_owner.gd
    worker.gd
    merchant.gd
  markets/
    market.gd
    labor_market.gd
    wholesale_market.gd
    retail_market.gd
  region/
    region.gd
  sim/
    enums.gd                       # TimeSlot, WorkState, ContractStatus
    wage_calculator.gd             # placeholder, returns flat 1
  bootstrap/
    prototype_bootstrap.gd         # spawns the world; entry point for the scene
```

Existing code in `tkyds-game/scripts/` from the prior architecture should be archived (move to `scripts/_archived/`) rather than mixed with the new build. Don't delete — old code is reference material when we layer aptitudes/needs back on later.

---

## Open questions deliberately deferred

- **WindowOrchestrator structure when windows multiply.** Today it's a single match statement. When we have 20 windows, this becomes a config table. Not a v0 problem.
- **Quorum-style window close** ("close once N expected reporters have spoken"). Synchronous emit gives this for free in v0; revisit when async work lands.
- **Multiple regions and per-region orchestrators.** Architecture scopes markets to Region; orchestrator is currently global. Will need region-scoped orchestrators when N > 1.
- **Save/load.** Resources serialize cleanly; Nodes don't. Not a v0 concern.
- **Whether Merchant's own `GrainInterest` is appropriate (merchant buying retail from themselves).** Edge case ignored for v0; demand is small enough not to matter.
