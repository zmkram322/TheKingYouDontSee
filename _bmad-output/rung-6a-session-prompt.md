# Rung 6a — session prompt

Copy everything below the line into a fresh session. Written 2026-08-11, the day
rung 5 closed.

**This rung is NOT routed to Fable** (Fable is for 6b, 6d, 7 and 8). So this
prompt spells the corrected shapes out rather than saying *"re-derive this"*.
**Nothing below is optional detail.**

**Unlike the rung 4 and rung 5 prompts, this one does NOT arrive with its design
calls already made.** Four are open, and one of them changes what the rung *is*.
They are the first section below, with the shapes and the costs, and they are to
be settled **with the author, at the top of the session, before a line is
written.** Do not settle them by implementation drift — that is the exact failure
the decisions file exists to prevent.

---

Build **rung 6a** of the proving-scene ladder. One rung, then stop at the gate.

## THE OPEN CALLS — SETTLE THESE FIRST

### ⚠ CALL 1 — does 6a ship `social` and the tavern? THIS ONE CHANGES THE RUNG

**There is an error in a settled decision, and it has to be resolved before the
rung has a defined scope.** Decision 3 puts **hunger AND social** in 6a, and says
in as many words:

> *"hunger and social both rising in UPKEEP and both bidding against adenosine,
> and you watch which wins."*

and its Moment is *"three drives on one graph and you watch which wins."*

**`Socialise` is rung 6d.** At 6a there is no action anywhere that reads
`social`, so it cannot bid and it cannot win. It would be a line that climbs
forever and touches nothing, for three gates. **The same applies to the tavern**,
which 6a's file list includes and which nothing visits until 6d — `Eat` is
explicitly from the man's *own* inventory, and `Drink` is rung 7.

Three ways out, and the author picks:

| | Shape | Cost |
|---|---|---|
| **Defer both to 6d** | 6a lands **hunger only** — the stat, its upkeep line, and `Eat` that consumes it. One drive, one consumer, one gate: the same clean shape rung 5 had. 6d then lands `social` + `Socialise` + the tavern together. | Amends Decision 3, which is marked *do not reopen* — so it needs a **new numbered decision with a banner on 3**, never an edit (append-only, the author's explicit call 2026-08-11). |
| **Ship both as written** | Decision 3 stands untouched. Social's curve is visible on the instrument for three gates before anything reads it, which is arguably how you tune its rate. | A stat nothing reads and a place nobody goes are both *substrate before need* by the project's own rule, and the Moment's "three drives compete" is false — you would watch two drives and a spectator line. |
| **Social, no tavern** | The stat is one line in `_update_body` and plots for free; a `Place` is a scene node that changes the town's geography and every travel-cost query in it. | Still a stat with no reader; the Moment still overstates what can be watched. |

**`Workstation.owner` ships at 6a regardless** and is not part of this call. It is
one exported field, it may be null, and **6b genuinely needs it** — a single null
field is not the same weight as a whole stat or a whole place.

### ⚠ CALL 2 — does eating take world time, or is it one tick?

**The fraction problem from rung 5 comes back, from the consumption side, and it
has no furrow to live in this time.** A count is a whole number and a tick is
0.01 world hours. So "eat one loaf per hour" is 0.01 of a loaf per tick, `take`
takes an `int`, and truncated it is zero forever — the identical failure that
made rung 5 put the remainder on the workstation. **Consumption out of a man's
own pocket has no world object to hang a remainder on**, and putting one on the
person is the stored progress the substrate refuses.

| | Shape | Cost |
|---|---|---|
| **One tick, one loaf** *(the cheap answer)* | `Eat.is_available_to` = hungry **and** has bread. The step does `take(&"bread", 1)` and drops hunger by an authored amount, in a single tick. No fraction anywhere, no remainder to store. Decision 6 already accepted exactly this for trade: *"One-tick resolution is accepted for now."* It also makes `Eat` a natural **spike** — the tick he eats, hunger collapses and `Eat` leaves the ballot — which is what Call 3 below needs. | A meal is instantaneous, which is not what a meal looks like. Nothing yet needs it to look like anything. |
| **A meal takes world time** | Decision 18: *the sim owns duration.* Hunger falls per world hour while `Eat` is the current action, so a meal is a legible stretch of the day and is outbiddable the whole way through — a fire breaks out mid-meal and he drops the loaf. | **The loaf has to be taken at a moment**, and "the start of the meal" is remembered state, which is the thing an ActionStep may not hold. Answering that is real design work and it is not what this rung is about. |

**Recommended: one tick, one loaf.** Take the time-based meal when something
actually needs to watch a man eat — probably alongside the wind-down step
Decision 18 describes, which is not ported.

### ⚠ CALL 3 — is `Eat` allowed to move bedtime?

**This is a consequence, not a preference, and it is the one most likely to eat a
day.** Bedtime is not authored anywhere. It is **wherever rising adenosine
crosses the highest WAKING bid.** Rung 6a adds a new waking bid.

`work_the_field.gd`'s header already documents this exact hazard, and rung 3's
numbers were chosen to dodge it:

> *"Flat and high enough to beat StayUp at noon (87+), work would still be
> winning at 22:00, where StayUp has fallen to 50 — and bedtime is wherever
> rising adenosine crosses the top waking bid, so the farmers' turning-in hour
> would quietly move."*

**`Eat` inherits that, whole.** If `Eat` can score above ~50 in the evening,
bedtime moves — and **claims 10, 11 and 12 go red presenting as "the sleep cycle
broke."** If `Eat` is a spike that collapses the moment he is fed, bedtime is
untouched.

The author's call is whether the regression baseline is **protected** (Eat must
never be the top waking bid at bedtime) or whether a genuinely starving man is
**allowed** to push his own bedtime later. The second is better fiction and it
means the baseline in this document changes deliberately, with the new numbers
recorded — which is legitimate, but it must be a decision and not a surprise.

### ⚠ CALL 4 — the curves, which is what this rung is actually for

The plan calls 6a *"the rung where the curves actually get tuned."* Two numbers
and they are the author's, at the keyboard, on the tuning board:

- **`base_hunger_per_hour`** — how fast he gets hungry.
- **What a loaf is worth** — how much hunger one drops.

**Do not guess these in code and move on.** The scale they have to land on is in
*THE UTILITY SCALE* below, measured, so nobody re-derives it. What the two
numbers decide is **how many times a day he eats and whether a meal ever
interrupts work** — which is the entire visible content of this rung.

---

## ORIENT

Godot 4.4 project in `Z:\TheKingYouDontSee\tkyds-game`. Solo dev. The build is
`game/` — a substrate running **two farmers contending for one plot** on a
sun-anchored sleep cycle, with places, travel cost in hours, walking, workstation
day-tenancy, **inventories and a grain yield**, live stat/utility graphs for both
men, a tuning board, an on-screen clock, and a standing probe of **thirty
claims** that gates every rung.

**Rung 6a is where the body stops being one-dimensional.** Every rung so far has
had exactly one drive: tiredness rises, the sun says when, and everything else is
a flat pull competing against it. A man has never once had to choose between two
things his *body* wanted. Rung 6a gives him a second appetite and something to
answer it with, and the day stops being "work until you sleep."

## READ FIRST, IN THIS ORDER

1. **`CLAUDE.md`** (repo root) — naming rules, design rules, Godot traps. Governs.
   Note the goods rule added at rung 5: **`add` creates, `take` destroys,
   `hand_over` moves**, and `Eat` is the first consumer in the game.
2. **`_bmad-output/proving-scene-decisions.md`** — there are **EIGHTEEN**
   decisions. For this rung: **3** (how rung 6 got cut, and the source of Call 1
   — read the *"the correction: at rung 6, a man eats his own bread"* section
   twice), then **1** (where want comes from — 6b's quota subtracts against
   stock, and hunger is the *deficit against a body* that Decision 1 explicitly
   left open as possibly-the-same-rule), then **11** (the sleep cycle hangs on
   the sun — this is what Call 3 is about), then **5** (every rate is per world
   hour). **Where two decisions disagree the HIGHEST NUMBER WINS.**
3. **`_bmad-output/proving-scene-build-plan.md`** — the "Rung 6a" section only,
   plus the rung 5 section immediately above it, which now carries what rung 5
   settled by building it.
4. **`game/brain.gd`** (`_update_body` and the two rate seams), **`game/stats.gd`**,
   **`game/inventory.gd`**, **`game/actions/stay_up.gd`**, **`game/actions/sleep.gd`**,
   **`game/actions/wake.gd`**, **`game/actions/work_the_field.gd`**,
   **`game/person.tscn`**, **`game/probe.gd`** — read them before writing anything.

Do not read the later rungs. They are not this session's work.

## WHERE THE BUILD IS

Committed on `poc-v2`:

```
956fb3e  rung 0   world time in hours + the probe
01f0272  rung 1   Population owns who thinks
9722033  rung 2   Place, Town, current_place, travel cost
605b4b6  rung 3   Workstation, WorkTheField, find_workstations, the counters
35f717f  rung 4   GoToStep, walk_speed, get_travel_speed, the knowledge rule
07a147c  rung 5   Inventory's three doors, the yield seam, the fraction in the furrow
23bdb38           claim 26's tick-produces-something check accepts either half
98e9d90           the unbuilt rungs warned about what rung 5 moved
```

```
game/      person, stats, brain, action, action_step, decision_engine, clock,
           daylight, population, place, town, workstation, inventory
           |  probe.gd, scene_wiring.gd
actions/   StayUp+BeUp, Sleep+Rest, Wake+WakeUp, WorkTheField+Work+GoTo
ui/        stat_graph, tuning_board, person_readout

game.tscn: Game
├─ Clock, Sky, Daylight, Ground
├─ Town ─ Fields ─ Plot (Workstation) ─ Inventory
│       │        └─ Inventory
│       └─ Inn ─ Inventory
├─ Population ─ Zoogs, Hobb      (both authored AT THE INN)
├─ Camera
└─ Screen ─ StatGraph, UtilityGraph, HobbStatGraph, HobbUtilityGraph,
            PersonReadout, TuningBoard

person.tscn children, in order: Shape, Collision, Brain, Stats, Readout, Inventory
Brain's children:               StayUp, Sleep, Wake   (+ WorkTheField, added per
                                instance by game.tscn at index="3")
```

**REGRESSION BASELINE — all of this must still be true when you are done, unless
Call 3 deliberately changes it:**

```
cold start   turns in hour 21.11 (21:07), up at 29.67 (05:40)
settled      turns in 22:01, sleeps 8.00 h, up 06:01     <- Zoogs, day 3 onward
             a strong man (strength 1.15) is up at 04:41 <- Hobb
```

Contention, measured over six days: **Hobb takes the plot on every day 0-5 and
Zoogs never does.** Day 0 both set off from the Inn at 03:41 and Hobb claims at
03:50. From day 1 both sleep where they stopped, so there is no commute after day
0 and Hobb claims within one tick of waking. **And, as of rung 5: Hobb ends day 5
holding 94 grain and Zoogs 0**, Hobb gaining ~16 a day across a 04:41→21:24
working day.

The probe pumps **48 hours**. **Thirty claims.** Exits non-zero on any failure.

**`Eat` and `EatStep` are free as `class_name`s. Verified 2026-08-11** by listing
every `class_name` in the project (26 of them).

## THE UTILITY SCALE — MEASURED, DO NOT RE-DERIVE

Everything is scored on one scale and the highest bid wins. `sun` is
`person.get_sun_height()`: −1 at midnight, 0 at dawn and dusk, +1 at midday.

| Action | Score | midnight | dawn/dusk | midday |
|---|---|---|---|---|
| `StayUp` | `67.3 + 20 × sun` | 47.3 | 67.3 | 87.3 |
| `WorkTheField` | `73 + 30 × sun` | 43.0 | 73.0 | 103.0 |
| `Sleep` | `adenosine` (0–100 ceiling) | — | — | — |
| `Wake` | flat `10.0` (gated to a sleeping man) | 10 | 10 | 10 |

**The three crossings that produce the shipped day, and what `Eat` has to live
between:**

- **~20:45** — work falls under `StayUp` and hands the evening back.
- **22:01** — adenosine (~50) crosses `StayUp` (**50.0 at 22:00**) and he turns
  in. **This is bedtime, and it is the number Call 3 is about.**
- **04:41 / 06:01** — adenosine falls under `Wake`'s flat 10 and he gets up;
  work is worth 62.8 there against `StayUp`'s 60.5, so he goes straight to the
  field.

So an `Eat` that must **interrupt work at noon** has to clear **103**, and an
`Eat` that must **not disturb bedtime** has to sit under **50** in the evening.
The gap between those two is the whole tuning problem of Call 4.

`Brain` for reference: `base_adenosine_per_hour = 2.5` awake,
`base_adenosine_cleared_per_hour = 5.0` asleep (× `strength`), ceiling 100.

## THE JOB

Three things, or four depending on Call 1.

1. **`hunger` in `game/stats.gd`** — a stat like `adenosine`, with the same kind
   of comment explaining what it means and why the number is what it is.
2. **`Brain._update_body` gains a line** — hunger rises per world hour.
   **UPKEEP, never inside an action**, per `CLAUDE.md`'s load-bearing rule: put
   it in `Eat` and the next action you write silently doesn't have it. Give it
   the same **`get_…()` seam treatment** the two adenosine rates have
   (`get_adenosine_accumulation` / `get_adenosine_recovery`), because illness,
   cold, a hard day's work and a growing boy all land there later — and because
   a rate you can plot is a rate you can tune.
3. **`game/actions/eat.{gd,tscn}`** — `Eat` (Action) + its step. **In
   `person.tscn`, so every person has it by composition** — FR86's protected
   categories are present by construction and can only be outbid, never pruned.
   **It takes bread from his OWN inventory** (`person.get_inventory()`), authored
   into his starting stock on `person.tscn` or per instance in `game.tscn`. No
   transfer, no place, no owner, no trade — that is what keeps this rung clean of
   rung 7's seam.
4. **`Workstation.owner`** — one `@export var owner: Person`, may be null,
   **with no reader at all this rung.** Unowned land is the king's, which is the
   same answer as nobody's. 6b adds `is_permitted_to()` that reads it; do not
   write that here.

*(Plus `social` and/or the tavern, if Call 1 says so.)*

**Authoring the bread is a real decision, not a detail.** Bread on `person.tscn`
means every person ever instanced starts fed — including the probe's spares and
every villager at 9d. Bread in `game.tscn` per farmer means the probe's spares
start with none, and a man with no bread cannot eat. Both are defensible; pick
one on purpose and say which in the commit.

## ⚠ THE TRAPS

**THE INDEX TRAP IS DEAD. MEASURED 2026-08-11 — DO NOT TIPTOE AROUND IT.** The
rung 4 and rung 5 prompts both carried a loud warning that `game.tscn` overrides
nodes BY INDEX, so inserting a node into `person.tscn` would drop Hobb's
`strength = 1.15` and turn the dawn race back into a coin flip. **It was tested
directly and it is false, in both of its forms:**

- A node inserted **before `Stats`** (making Stats index 4) — **Hobb still reads
  1.15.** A property override on an existing child resolves by **name**; the
  index is a positioning hint.
- **A node added to `person.tscn`'s Brain**, which is the case this rung hits
  because `WorkTheField` is *inserted* at `index="3"` — Brain came out
  `StayUp, Sleep, Wake, WorkTheField, Eat` and **all 30 claims stayed green.**
  An added node takes position 3; a new base-scene sibling sorts after it.

**Author `Eat` wherever it reads best.** The one real consequence of ordering is
much narrower and worth knowing: `DecisionEngine.get_highest_scoring` breaks
**exact ties** by *"whichever came first"*, so Brain child order decides only
between two actions scoring **identically**.

**THE TRAP THAT IS REAL — a new competing action can break claims that assert
what a man is DOING.** Three existing claims name an action or a ballot:

- **Claim 13** asserts `Hobb's current action reads WorkTheField` at the end of a
  ten-hour pump. If hunger spikes inside that window and Hobb stops to eat, this
  goes red — and it will read as *"the contention broke"* when it means *"he had
  lunch."*
- **Claims 21 and 22** assert work is on / off Zoogs' ballot, and 22 asserts he
  **does not move** over 20 idle ticks having lost the plot. Eating does not move
  him, so 22's position check is safe — but do not assume, check.

**If one of these goes red, decide which of two things it is** before touching
it: the tuning is wrong (a man should not be eating at that hour), or the claim
was quietly about something narrower than it said. Rung 4 hit exactly this and
the answer was to **pin the world the claim wants** (`_stand_at`) rather than
weaken the assertion. There is no `_feed` helper yet; if claim 13 needs one, that
is the shape.

**The other real trap: `Eat` must not be able to fire while he is asleep.**
`StayUp` and `WorkTheField` both gate on `person.brain.is_awake()` and both
document why. A man whose hunger crosses the threshold at 03:00 will get up and
eat in the dark if you forget — and it will present as a broken sleep cycle. Note
that `Sleep` itself does **not** gate on being awake, deliberately; `Wake` gates
on being asleep. Read all four before writing the fifth.

## THE GATE

**Probe, then Moment. All thirty existing claims stay green** (or move
deliberately, per Call 3, with the new baseline recorded). **New claims start at
31.**

1. **Hunger rises for a man doing nothing at all** — it is upkeep, so it must
   move for somebody whose current action is `StayUp`, and it must move by
   exactly one hour's worth in one hour. Assert the amount, not the direction.
2. **Eating drops hunger, and consumes exactly one loaf.** Both halves: the stat
   fell *and* the count went down by one, so "he ate" cannot be satisfied by a
   step that changes hunger for free.
3. **A man with no bread cannot eat** — `Eat` is off his ballot entirely (NAN in
   `get_last_scores`, the same off-the-ballot shape claims 13 and 21 already
   use), not merely outscored. And having no bread must not stop hunger rising.
4. **Hunger never goes negative**, however much he eats.
5. **`adenosine` is written from nowhere outside `brain.gd`** — a **text scan**,
   in the shape `SceneWiring` already establishes, over every `.gd` in `game/`.
   This is the mechanical form of the upkeep-vs-effects rule and it is the claim
   that stops the farmhand-who-never-tires bug from ever being written.
   **Deliberately NOT extended to hunger:** `Eat` **must** write hunger, that is
   an effect, and the design permits it. *(The build plan's original wording said
   neither stat may be written from `game/actions/`. That is wrong and would fail
   on correct code — it is already corrected in the plan, do not restore it.)*
6. **`Eat` is on every person by composition** — instance `person.tscn` fresh,
   with nothing authored, and assert the newcomer knows it. That is FR86's
   guarantee made mechanical, and it is what a later rung would break by moving
   `Eat` into `game.tscn` per person.

**Moment — accepted as it unfolds, not staged.** Two drives on one graph and you
watch which wins: the first time the sleep cycle has a competitor that is not a
flat number. **Watch it at a SHORTENED day** — this is a once-a-day beat
repeating, so Decision 13's instrument applies (rung 4's long day is the
opposite case and does not apply here).

**Two instrument notes, both learned at rung 5:**

- `stat_graph` now has **`top_of_scale`** (0.0 = fit to the data). Grain already
  passes adenosine's 47 inside a working day and reaches 94 by day 5, so the
  stat panels are **already crowded before hunger arrives**. Pinning the two
  stat panels is one number in the inspector and is probably the first thing you
  do when you sit down to watch this.
- Items and stats both list by reflection, so `hunger` appears on both readouts
  and both graphs, and bread appears over every head, **with no line written for
  either.** If it does not appear, something is wrong with the stat's export
  usage flags, not with the panel.

## DO NOT BUILD

`Drink`, beer, the tavern's storage being anybody else's, or buying anything —
that is **rung 7**, and shipping a transfer path here is exactly what Decision 3
split this rung to avoid. `Obligation`, `WorkForHire`, quotas, discharge,
`is_permitted_to()` — **6b** (`owner` ships as a field with no reader; that is
the whole of it). Beds, and `Sleep` gaining a place requirement — **6c**.
`Socialise`, `Town.find_people_at` being consumed, the distance damper — **6d**.
A hunger *quota* or any attempt to unify hunger with Decision 1's `target −
stock` — **Decision 1 explicitly left that open and it is not this rung's to
close.** Cooking, recipes, food that spoils, an item database, weight, carry
capacity. `release()` on `Workstation` — still no caller, still deliberately
absent.

## ENGINE FACTS — MEASURED. DO NOT REDISCOVER.

- **A `.tscn` override by index does NOT break when child order changes** — see
  THE TRAPS. Both halves tested 2026-08-11.
- `process_mode = Node.PROCESS_MODE_DISABLED`, **never** `set_process(false)` —
  the latter is silently discarded from `_initialize()` and you get a
  double-ticked person that reads as a tuning bug.
- `_initialize()` runs before anything is in the tree, so `_ready` has not run and
  `@onready` vars **do not exist yet**. Setup in `_initialize`; assertions from
  the first `_process` frame. **And `quit()` called from `_initialize()` does not
  take — the process hangs.** Do the work in `_process` and return `true`, the
  way `probe.gd` does. (Cost five minutes on 2026-08-11.)
- The harness advances `Clock` itself. Nothing else will.
- **The run line is TWO commands.** `--script` does not build the class cache:
  ```
  "/z/Godot/Godot_v4.4-stable_mono_win64/Godot_v4.4-stable_mono_win64_console.exe" --headless --path . --editor --quit
  "/z/Godot/Godot_v4.4-stable_mono_win64/Godot_v4.4-stable_mono_win64_console.exe" --headless --path . --script game/probe.gd
  ```
  The first prints harmless `progress_dialog.cpp` errors. Ignore them.
- A node reference in a hand-written `.tscn` needs `node_paths` on that node's
  own header or it loads as null. `@export var x: Array[Node]` does not resolve
  at all — use `Array[NodePath]` + `get_node_or_null()`. Claim 4 catches both.
- **An `@export` default in a `.gd` does nothing if the `.tscn` already stores a
  value** — and the reverse: the editor DROPS a stored value equal to the script
  default.
- **A freed reference compares `== null` as TRUE** in this engine. Three
  `is_instance_valid` guards stand unreachable for this reason and are documented
  as such; do not "clean them up".
- `Stats.get_stat_names()` reflects over exported script properties and requires
  **both** `PROPERTY_USAGE_SCRIPT_VARIABLE` and `PROPERTY_USAGE_EDITOR` — that is
  what makes an `@export` show up and an internal var not.
- `class_name` is project-global. `Eat` and `EatStep` are free; check before
  naming anything else.

## SYNTAX — the build runs warnings-as-errors

- Ternaries infer `Variant` when the branches differ in type. Annotate.
- `var x = something_returning_Variant` fails the same way. Write
  `var x: Variant = …` or the concrete type.
- Typed arrays throughout: `var found: Array[StringName] = []`.
- **`Inventory.get_count` returns `int`, `Stats.get_stat` returns `Variant`** —
  read a stat into a declared `float`, the way every existing caller does.
- An unused-but-declared parameter is underscored (`_person`) — the house marker
  for a seam standing empty, as `Action.is_available_to` and
  `WorkStep.get_yield_per_hour` both do.
- Methods are verbs or questions, never bare nouns. Booleans read as questions
  (`is_`, `can_`, `has_`). Arguments are named for what they ARE.
- **`hours`, never `delta`,** below `Population`. Every rate is per world hour,
  including the hunger rate.
- Plain English over CS vocabulary. Comments explain WHY and match the existing
  density in `game/` — that density is the house style, not clutter.

## DELEGATION

Delegate a chunk that is self-contained, mechanically specifiable, and has ground
truth to check itself against.

**Good candidates:** the `adenosine`-is-only-written-in-`brain.gd` text scan (it
is a pure function over file text with an exact expected answer, and it mirrors
`scene_wiring.gd` closely enough to hand over with the existing file as the
model). And a six-day measurement run reporting the schedule, who claimed the
plot when, each man's grain at each dusk **and how many times each man ate** —
hand over the regression table above and have it report HOLDS/DEVIATES per line.

**Do NOT delegate:** the four open calls, the curve tuning, or the decision about
whether a red claim 13 is a tuning problem or a claim problem.

## BEFORE YOU CLAIM DONE

- Both commands run; **all claims print PASS**; probe exits 0.
- **Every new claim has been seen to FAIL.** Break the thing it guards, confirm
  exit 1, restore. A claim never observed failing is decoration — **seven
  assertions in this ladder have already turned out vacuous or fragile when
  checked this way**, the most recent at rung 5, where a claim went red for a
  *different* claim's reason and had to be rewritten. Commit the rung FIRST so
  per-file `git restore` is safe during the break pass; **never `git restore .`**.
  **Watch which claims each break turns red** — a break that reddens a claim you
  were not aiming at is telling you the two overlap.
- **The sleep cycle has not moved** — Zoogs 22:01 / 8.00 h / 06:01, Hobb 04:41 —
  **or it has moved exactly as Call 3 decided, and the new numbers are written
  into the build plan and this baseline.** "It moved and I am not sure why" is a
  failed gate.
- **Hobb still takes the plot every day and Zoogs still never does.**
- **A man eats.** Say how often, at what hours, and whether a meal ever
  interrupted work — that is the rung's actual content and a green probe does not
  show it.
- Report the probe output, then **STOP**. Do not begin rung 6b.

## STANDING HAZARDS

- **Treat every code snippet in `proving-scene-decisions.md` AND in the build plan
  as intent to be re-derived, not code to paste.** Five have been wrong so far and
  only the probe caught them. **Call 1 above is the first case where a settled
  decision's PROSE is wrong rather than its code** — the same scepticism applies
  to it.
- **Watch for assertions that cannot fail.** This is the ladder's most reliable
  source of wasted work.
- **When this rung ships, grep the UNBUILT rungs for what it changed.** Rung 4
  moved a seam under 5, 6a, 6d and 7; rung 5 landed 9a's `Workstation.progress`
  four rungs early as `output_part_made`. That is now part of the ritual, and 6a
  introduces `hunger`, which 6b, 6d, 7 and 9b all sit downstream of — and
  `Workstation.owner`, whose first reader is 6b.
- **The working tree on `poc-v2` is clean** except for a `[display]` block in
  `project.godot` (window maximized, so the UI stops dominating a 2K screen),
  which was left uncommitted for the author to try. Anything else uncommitted you
  find is yours.
