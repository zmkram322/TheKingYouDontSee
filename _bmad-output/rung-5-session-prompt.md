# Rung 5 — session prompt

> **⚠ SPENT — EXECUTED 2026-08-11 (`07a147c`). Kept as a record, and it holds up
> except on two points, both worth knowing before this file is used as a model:**
>
> **1. ITS LOUDEST SECTION IS WRONG. The index trap does not exist.** *"⚠ THE
> TRAP THIS RUNG WILL FALL INTO — MEASURED, NOT PREDICTED"* was predicted, not
> measured, and it was tested directly on 2026-08-11 and disproved in both of its
> forms: a node inserted **before `Stats`** leaves Hobb reading 1.15 (a property
> override resolves by NAME, not by index), and a node added to **`Brain`** where
> `WorkTheField` is inserted at `index="3"` leaves all 30 claims green. It cost
> two rungs of authoring freedom for nothing. See the rung 6a prompt.
>
> **2. It asserted something arithmetically impossible and did not notice** —
> claim 1 asks for *"exactly `get_yield_per_hour(person) × hours` per tick"* into
> an integer count, but a tick is 0.01 hours, so every tick truncates to zero and
> a man farms all day for nothing. That was caught mid-build and settled by the
> author: the fraction lives in the furrow (`Workstation.output_part_made`). **A
> prompt this specific can still hand the session an impossible instruction; the
> lesson is that "nothing below is optional detail" is not the same as "nothing
> below is wrong."**

Copy everything below the line into a fresh session. Written 2026-08-11, the day
rung 4 closed.

**This rung is NOT routed to Fable** (Fable is for 6b, 6d, 7 and 8). So this
prompt spells the corrected shapes out rather than saying *"re-derive this"*.
**Nothing below is optional detail.**

Two design calls were made by the author while this prompt was being written and
are already baked in: **the yield seam** and **all three mount points**. They are
marked where they land. Do not re-open either.

---

Build **rung 5** of the proving-scene ladder. One rung, then stop at the gate.

## ORIENT

Godot 4.4 project in `Z:\TheKingYouDontSee\tkyds-game`. Solo dev. The build is
`game/` — a substrate running **two farmers contending for one plot** on a
sun-anchored sleep cycle, with places, travel cost in hours, **walking**,
workstation day-tenancy, live stat/utility graphs for both men, a tuning board,
an on-screen clock, and a standing probe of **twenty-four claims** that gates
every rung.

**Rung 5 is where work finally produces something.** Rung 3 proved a man can win
a plot; rung 4 proved he will cross a town to reach it and that losing sends him
somewhere. Both of those are still only *positions and claims* — nothing in the
world has yet been made, moved, or held. Rung 5 gives the day an output, and it
gives the two men a difference you can read off their heads instead of inferring
from a graph.

## READ FIRST, IN THIS ORDER

1. **`CLAUDE.md`** (repo root) — naming rules, design rules, Godot traps. Governs.
2. **`_bmad-output/proving-scene-decisions.md`** — there are now **EIGHTEEN**
   decisions, not fifteen. For this rung: **1** (where "want" comes from — rung
   5 builds the thing rung 7's `target − stock` will subtract against, so the
   shape matters), then **2** (a claim is a day-long tenancy, renewed by use —
   the yield hangs off the same `claim()` that renews), then **12** (how two
   people differ, and the prediction that `strength` will one day mean
   work-per-hour and carry capacity — **read the warning about that below**),
   then **5** (world time is hours; every rate you author here is per world
   hour). **Where two decisions disagree the HIGHEST NUMBER WINS.**
3. **`_bmad-output/proving-scene-build-plan.md`** — the "Rung 5" section only.
   **It carries a ⚠ box about `WorkStep` that is the single most important
   thing in it.** Read that box twice.
4. **`game/actions/work_step.gd`, `game/actions/work_the_field.gd`,
   `game/person.gd`, `game/stats.gd`, `game/place.gd`, `game/workstation.gd`,
   `game/ui/stat_graph.gd`, `game/probe.gd`** — read them before writing
   anything.

Do not read the later rungs. They are not this session's work.

## WHERE THE BUILD IS

Committed on `poc-v2`:

```
956fb3e  rung 0  world time in hours + the probe
01f0272  rung 1  Population owns who thinks
9722033  rung 2  Place, Town, current_place, travel cost
605b4b6  rung 3  Workstation, WorkTheField, find_workstations, the counters
35f717f  rung 4  GoToStep, walk_speed, get_travel_speed, the knowledge rule
a7e55da          claim 9's comment corrected — there is no falloff curve
4a79577          the plan reconciled with Decisions 7, 14, 15
9d99ba3          the plan reconciled with all fifteen decisions
3a0cc63          the unbuilt rungs warned about the seam rung 4 moved
d16148b          Decisions 16, 17, 18 — what physics is for
98105d5          the editor's normalisation of game.tscn
```

```
game/      person, stats, brain, action, action_step, decision_engine, clock,
           daylight, population, place, town, workstation
           |  probe.gd, scene_wiring.gd
actions/   StayUp+BeUp, Sleep+Rest, Wake+WakeUp, WorkTheField+Work+GoTo
ui/        stat_graph, tuning_board, person_readout

game.tscn: Game
├─ Clock, Sky, Daylight, Ground
├─ Town ─ Fields ─ Plot          (Workstation, work_name &"field work")
│       └─ Inn
├─ Population ─ Zoogs, Hobb      (both authored AT THE INN since rung 4)
├─ Camera
└─ Screen ─ StatGraph, UtilityGraph, HobbStatGraph, HobbUtilityGraph,
            PersonReadout, TuningBoard
```

**REGRESSION BASELINE — all of this must still be true when you are done:**

```
cold start   turns in hour 21.11 (21:07), up at 29.67 (05:40)
settled      turns in 22:01, sleeps 8.00 h, up 06:01     <- Zoogs, day 3 onward
             a strong man (strength 1.15) is up at 04:41 <- Hobb
```

Contention, measured over six days: **Hobb takes the plot on every day 0-5 and
Zoogs never gets it.** Day 0 both set off from the Inn at 03:41; Hobb walks 17.68
units at 132.25 u/h and claims at **03:50**; Zoogs walks 20.59 at 115.00 and
arrives at 03:52 to find it gone. From day 1 both sleep where they stopped, so
there is **no commute after day 0** and Hobb claims within one tick of waking,
every day.

The probe pumps **48 hours**. **Twenty-four claims.** Exits non-zero on any
failure.

**`Inventory` is free as a `class_name`. Verified 2026-08-11** by listing every
`class_name` in the project.

## THE JOB

Four things.

1. **`game/inventory.gd`** — `Inventory`, a `Node`, with the API below. Mounted
   under **`Person`, `Place` AND `Workstation`** — all three, this rung.
2. **`WorkStep` yields grain** into the working man's inventory, at a base rate
   **behind a seam**, per world hour.
3. **`game/person.gd`** — the readout gains his items, by reflection, the same
   way it already lists stats.
4. **`game/ui/stat_graph.gd`** — learns to plot item counts, **and gains the
   scale guard first.**

### The `Inventory` API — three call sites, one implementation

```gdscript
func get_count(item_name: StringName) -> int
func add(item_name: StringName, count: int) -> void    # CREATION — production only
func take(item_name: StringName, count: int) -> bool   # DESTRUCTION — consumption only
func has_at_least(item_name: StringName, count: int) -> bool
func get_item_names() -> Array[StringName]             # for the readout, by reflection

# MOVEMENT — the one waist all goods pass through, in both directions.
func hand_over(item_name: StringName, count: int, to_inventory: Inventory) -> bool
```

**`get_count` mirrors the `get_stat`/`set_stat` wall exactly**, and for the same
reason: named access is what lets storage graduate later without rewriting call
sites. `CLAUDE.md` names that wall as load-bearing. Nothing outside `inventory.gd`
touches the backing store.

**`add`/`take` create and destroy. `hand_over` moves.** Keeping them apart is what
makes a conservation claim mean anything — **world totals may change ONLY where
`add` or `take` is called** — and it is what stops rungs 6b, 7 and 9a each
growing their own transfer path.

**`hand_over` is both halves or neither.** A transfer that half-happened surfaces
three rungs later as an item count that drifts, and you will not find it by
reading. Take from one, add to the other, and if the take fails, nothing moves.

### The yield, and THE AUTHOR'S CALL ON ITS SHAPE

**Author's call, 2026-08-11:** *"grain per hour has a base but leave a seam for
calculating modifiers (like the use of tools) later."*

So: **an authored base number, and a getter that is the only thing anybody
calls.** Same shape as `Brain.get_adenosine_recovery()` and
`Person.get_travel_speed()` — a seam with **nothing** behind it today.

```gdscript
# work_step.gd
@export var base_grain_per_hour := 1.0      # PER WORLD HOUR, like every rate here

# The seam. A tool, a better plot, a wound, a sack already full — all install in
# THIS FUNCTION BODY and no caller changes. It takes the person because a tool is
# a fact about the MAN, exactly as get_travel_speed's modifier is.
func get_yield_per_hour(person: Person) -> float:
    return base_grain_per_hour
```

**Nothing multiplies it yet, and `strength` in particular does NOT.** `stats.gd`
predicts that strength will one day mean work-per-hour — **that is a prediction,
not a specification, and this rung does not cash it.** Feeding strength in here
would hand Hobb a fourth advantage (he already wakes first, walks faster, and
wins the plot), and nothing has asked for that. The seam is where it goes on the
day something does.

**The rate is per world hour and multiplied by `hours`**, like every rate below
`Clock`. An authored 1.0 means one grain per world hour, not per tick.

### ⚠ WHERE THE YIELD GOES — `WorkStep` GREW A SECOND BRANCH AT RUNG 4

`WorkStep.advance()` no longer only works. It asks where the man is standing, and
**if he is not at the plot's place it walks him there and returns.**

> **Put the yield after `station.claim(person)` succeeds** — the same place, and
> for the same reason, that renew-on-use lives. Put it at the top of `advance()`
> and **a man produces grain while walking across town**, which reads as a
> balance problem and takes an hour to trace.

There is a probe claim below whose whole job is to catch exactly this.

### The readout and the graph

**`Person.get_readout_text()`** already lists stats by reflection so that adding
a stat makes it appear without this file changing. Do the same for items, using
`get_item_names()`. No string in `game/` names one particular item.

**`stat_graph` needs the scale guard BEFORE it plots items.**
`_get_top_of_scale()` (stat_graph.gd:187) scales to the **global maximum across
every series**, so coin at 500 squashes adenosine at 45 flat against the axis and
**the primary instrument goes unreadable exactly when the town gets
interesting.** Guard it first, then add the item loop — about six lines mirroring
the `show_stats` loop already at stat_graph.gd:115.

This is not a nicety. The last frame of this whole arc is scythes piling up on a
merchant's stall, and **inventory-on-the-graph is the instrument that ending is
measured with.**

## ⚠ THE TRAP THIS RUNG WILL FALL INTO — MEASURED, NOT PREDICTED

**`game.tscn` overrides three nodes BY INDEX, and one of them is `Stats`.**

```
game.tscn:102   [node name="Stats" parent="Population/Hobb" index="3"]
                strength = 1.15
```

`person.tscn`'s children are, in order: `Shape` 0, `Collision` 1, `Brain` 2,
**`Stats` 3**, `Readout` 4.

> **Add `Inventory` to `person.tscn` ANYWHERE BEFORE `Stats` and `Stats` becomes
> index 4.** Hobb's `strength = 1.15` override then lands on the wrong node or is
> dropped, both farmers wake at the same moment, the dawn race is decided by
> `Population` child order, and **claims 12 and 13 go red** — presenting as *"the
> sleep cycle broke"* rather than as *"a node moved."*

**Add it at the END of `person.tscn`'s children**, after `Readout`. Then indices
0-4 are untouched and nothing shifts. The same applies to `Brain`'s children —
`WorkTheField` is overridden at `index="3"` for both farmers.

If you would rather not depend on this at all, the durable fix is to re-author
those three overrides by name rather than index — but that is a separate change,
and if you make it, make it in its own commit and say so.

## THE GATE

**Probe, then Moment. All twenty-four existing claims stay green.** Unlike rung
4, **this rung is additive and should break nothing** — an `Inventory` node is
invisible to every existing query (`get_places()` casts to `Place`,
`find_workstations` casts to `Workstation`, `find_people_at` asks people). **So if
an existing claim goes red, you have changed something you did not mean to** —
almost certainly the index trap above. **New claims start at 25.**

1. **Working a plot puts grain in the working man's inventory, at exactly
   `get_yield_per_hour(person) × hours` per tick.** Assert the amount, not merely
   that it went up.
2. **A man WALKING to a plot produces nothing.** Stand him at the Inn, pump until
   he arrives, and assert his grain is still zero on the tick before arrival.
   This is the ⚠ box above, made mechanical, and it is the claim most likely to
   catch a real mistake.
3. **`take` more than he has returns `false` and changes nothing** — no partial
   take, and no negative count.
4. **`hand_over` conserves the total across two inventories.** Sum before equals
   sum after.
5. **`hand_over` fails atomically** — a transfer that cannot complete moves
   **neither** half. Assert both sides are untouched, not just the return value.
6. **Only `add` and `take` change a world total.** Pump a `hand_over` and assert
   the two-inventory sum is unmoved; call `add` and assert it moved. This is the
   claim that keeps the three call sites honest and is what rungs 6b, 7 and 9a
   will lean on.

**Standing the farmer on the plot is required for claim 1**, and this is the
second trap: *"work N ticks, assert grain increases"* silently becomes *"walk N
ticks, assert nothing"* now that both farmers are authored at the Inn.
**`probe.gd` already has `_stand_at(person, place)` for exactly this** — added at
rung 4, and writing `current_place` by hand in the probe is legal and deliberate.

**Moment — accepted as it unfolds, not staged.** The readout over the farmer's
head gains `grain 3`, and you watch it climb **while the loser's stays at zero.**
The difference between the two men stops being an inference from a graph and
becomes a number on their heads. Watch it at a **shortened day** — this is a
once-a-day beat repeating, so Decision 13's instrument applies, not rung 4's long
day.

## DO NOT BUILD

Weight. Stack limits. **Carry capacity** — `stats.gd` predicts strength will mean
"how much a man can carry", and the plan's own *do not build* list forbids it;
**the prediction is not a spec, and a limit nothing bumps against is substrate
before need.** Item quality. An item database. A `Resource` per item kind. A
name and a count, and nothing else. **Strength feeding the yield** (see above).
Coin being *produced* by anything — coin is `get_count(&"coin")` and nothing
mints it until trade at rung 7; this rung only makes it *plottable*. Eating,
hunger, `Drink`, the tavern (6a, 6d). Obligations, quotas, `owner`,
`is_permitted_to` (6). Beds (6c). `release()` on `Workstation` — still no caller,
still deliberately absent. Any second transfer path that is not `hand_over`.

## ENGINE FACTS — MEASURED. DO NOT REDISCOVER.

- **A `.tscn` node override by INDEX breaks when child order changes.** See the ⚠
  section above. This is the one that will bite.
- `process_mode = Node.PROCESS_MODE_DISABLED`, **never** `set_process(false)` —
  the latter is silently discarded from `_initialize()` and you get a
  double-ticked person that reads as a tuning bug.
- `_initialize()` runs before anything is in the tree, so `_ready` has not run and
  `@onready` vars **do not exist yet**. Setup in `_initialize`; assertions from
  the first `_process` frame. (This cost a throwaway script on 2026-08-11.)
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
- `class_name` is project-global. `Inventory` is free; check before naming
  anything else.

## SYNTAX — the build runs warnings-as-errors

- Ternaries infer `Variant` when the branches differ in type. Annotate.
- `var x = something_returning_Variant` fails the same way. Write
  `var x: Variant = …` or the concrete type.
- Typed arrays throughout: `var found: Array[StringName] = []`.
- **`get_count` returns `int`, not `float`.** A count is a count. Mixing them is
  how a half-grain appears three rungs later.
- Methods are verbs or questions, never bare nouns. Booleans read as questions
  (`is_`, `can_`, `has_`). Arguments are named for what they ARE —
  `item_name`, `count`, `person`, `to_inventory`; never `from`, `it`, `obj`.
- **`hours`, never `delta`,** below `Population`. Every rate is per world hour,
  including `base_grain_per_hour`.
- Plain English over CS vocabulary. Comments explain WHY and match the existing
  density in `game/` — that density is the house style, not clutter.

## DELEGATION

Delegate a chunk that is self-contained, mechanically specifiable, and has ground
truth to check itself against.

**Good candidates:** the six new probe claims, handed over **after** `Inventory`'s
API is frozen, with an exact expected-results table. And a six-day measurement
run reporting the schedule, who claimed the plot when, and each man's grain at
each dusk — hand over the regression table above and have it report
HOLDS/DEVIATES per line.

**Do NOT delegate:** the `.tscn` edits (the index trap is exactly what a cold
agent gets wrong), the `hand_over` atomicity, or the decision about where the
yield goes inside `advance()`.

## BEFORE YOU CLAIM DONE

- Both commands run; **all claims print PASS**; probe exits 0.
- **Every new claim has been seen to FAIL.** Break the thing it guards, confirm
  exit 1, restore. A claim never observed failing is decoration — **six
  assertions in this ladder have already turned out vacuous when checked this
  way.** Commit the rung FIRST so per-file `git restore` is safe during the break
  pass; **never `git restore .`**.
- **The sleep cycle has not moved.** Zoogs still turns in 22:01, sleeps 8.00 h, is
  up 06:01; Hobb still rises 04:41. **Nothing this rung touches the score or the
  body, so there is no legitimate reason for either man's hours to move** — if
  they do, suspect the index trap first.
- **Hobb still takes the plot every day and Zoogs still never does.**
- Report the probe output, then **STOP**. Do not begin rung 6.

## STANDING HAZARDS

- **Treat every code snippet in `proving-scene-decisions.md` AND in the build plan
  as intent to be re-derived, not code to paste.** Five have been wrong so far and
  only the probe caught them.
- **Watch for assertions that cannot fail.** This is the ladder's most reliable
  source of wasted work.
- **When this rung ships, grep the UNBUILT rungs for what it changed.** Rung 4
  moved a seam under rungs 5, 6a, 6d and 7 and only a manual read caught it; that
  is now part of the ritual, and rung 5 introduces `Inventory`, which 6a, 6b, 7,
  9a and 9c all consume.
- **The working tree on `poc-v2` is clean.** Anything uncommitted you find is
  yours.
