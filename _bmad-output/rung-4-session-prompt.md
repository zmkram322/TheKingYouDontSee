# Rung 4 — session prompt

Copy everything below the line into a fresh session. Written 2026-08-10, the
day rung 3 closed.

**This rung is NOT routed to Fable** (see the model-routing note: Fable is for
3, 6b, 6d, 7 and 8). So this prompt is deliberately more explicit than rung 3's
was: where that one could say *"re-derive this, don't paste it"* and trust it to
land, this one spells the corrected shape out. **Nothing below is optional
detail.** The arithmetic in "THE CALL THIS SESSION MUST MAKE" in particular was
worked out in advance precisely so a session does not discover it by flailing.

---

Build **rung 4** of the proving-scene ladder. One rung, then stop at the gate.

## ORIENT

Godot 4.4 project in `Z:\TheKingYouDontSee\tkyds-game`. Solo dev. The build is
`game/` — a substrate running **two farmers contending for one plot** on a
sun-anchored sleep cycle, with places, travel cost, workstation tenancy, live
stat/utility graphs for both men, a tuning board, an on-screen clock, and a
standing probe of **eighteen claims** that gates every rung.

**Rung 4 is where losing goes somewhere.** Rung 3 proved a man can lose the
plot; the author watched it and reported that the loser *"didn't wander off, he
just stayed put at the fields"* — correct behaviour and an honest limit,
because there is no walking and nowhere to go. Recorded as part of Decision 13.
Rung 4 is the rung that fixes it.

## READ FIRST, IN THIS ORDER

1. **`CLAUDE.md`** (repo root) — naming rules, design rules, Godot traps. Governs.
2. **`_bmad-output/proving-scene-decisions.md`** — **Decision 7 above all** (the
   identity-check / travel-cost split, the falloff curve, and why the radius
   bound was cut), then **10** (arrival is the overshoot clamp, departure writes
   null, and the `find_people_at(null)` rule that depends on it), then **4**
   (`move_and_slide` cannot be pumped), then **13** (what rung 3 settled and what
   the author saw), then **12** (how two people differ — this rung may give
   `strength` its second job). **This file wins where it and the plan disagree.**
3. **`_bmad-output/proving-scene-build-plan.md`** — the "Rung 4" section only.
4. **`game/person.gd`, `game/actions/work_step.gd`, `game/actions/work_the_field.gd`,
   `game/workstation.gd`, `game/probe.gd`** — read them before writing anything.

Do not read the later rungs. They are not this session's work.

## WHERE THE BUILD IS

Committed on `poc-v2`:

```
956fb3e  rung 0  world time in hours + the probe
01f0272  rung 1  Population owns who thinks
a4c38fd          the .tscn wiring scan lifted into scene_wiring.gd
9722033  rung 2  Place, Town, current_place, travel cost
d10afa6          PersonReadout + an on-screen clock
cd5fc7c          the sleep cycle hung on the sun
57b1594          a strength stat, so two farmers do not wake at once
605b4b6  rung 3  Workstation, WorkTheField, find_workstations, the counters
4a3c13a          probe claims 13-18; claims 6 and 8 moved for the second farmer
69b41da          claim 17's vacuity finding recorded at both sites
93ebc8f          Decision 13 — the Moment reads
f69aa32          the editor's normalisation of game.tscn
14a434e          Decision 13 — the loser stands in the field
```

```
game/      person, stats, brain, action, action_step, decision_engine, clock,
           daylight, population, place, town, workstation
           |  probe.gd, scene_wiring.gd
actions/   StayUp+BeUp, Sleep+Rest, Wake+WakeUp, WorkTheField+Work
ui/        stat_graph, tuning_board, person_readout

game.tscn: Game
├─ Clock, Sky, Daylight, Ground
├─ Town ─ Fields ─ Plot          (Workstation, work_name &"field work")
│       └─ Inn
├─ Population ─ Zoogs, Hobb      (both authored AT the Fields today)
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

Contention, measured over six days: **day 0's plot goes to Zoogs at 03:41**
(cold start, both awake from midnight, decided by child order — harmless and
gone by day 1); **day 1 onward it goes to Hobb**, on the tick he wakes.

The probe pumps **48 hours**. **Eighteen claims.** Exits non-zero on any failure.

**`GoToStep`, `Linger`, `Walk` and `Travel` are all free as `class_name`s.
Verified 2026-08-10** by grepping every `class_name` in the project.

## THE GEOMETRY YOU ARE WORKING IN — measured, use these numbers

```
Fields  origin (-9, 0.02, -5)
Inn     origin ( 8, 0.02,  4)
Fields <-> Inn  =  19.24 units      <- the whole town is 19 units wide
Zoogs   authored at (-8, 0, -4)     standing on the Fields
Hobb    authored at (-10.5, 0, -5.5)
```

Travel cost is straight-line 3D `distance_to` off `global_position`, measured to
the **Place**, not to the station.

## THE JOB

Four things.

1. **`game/actions/go_to_step.gd`** — `GoToStep`, an `ActionStep` that owns
   movement and **both edges of `current_place`**.
2. **`game/person.gd`** — `@export var walk_speed` and
   `@export var distance_that_halves_appeal`, both defaulted on `person.tscn`.
3. **`WorkStep` learns to walk** — not at the plot's place, walk toward it; at
   it, claim and work. One `advance()`, re-derived from where he is standing,
   holding no route and no progress.
4. **Scene** — **both farmers are re-authored to start at the Inn** (the
   author's call, 2026-08-10). Today nobody in the shipped scene ever travels,
   so the Moment could only be staged by dragging a capsule. Starting them at
   the Inn makes the Moment native: at dawn both set off, one arrives and
   claims, the other is outbid en route and stops.

### `GoToStep` — the shape, spelled out

**Do NOT call `move_and_slide()`.** Decision 4, measured: called from `_process`
it multiplies by the *physics* delta and produces non-uniform displacement, and
under `PROCESS_MODE_DISABLED` it moves **zero, silently** — which would make
every movement claim in the probe unwritable. **Integrate `global_position`
directly.** Keep `CharacterBody3D` as the type.

**Arrival is the overshoot clamp, never a radius** (Decision 10). *"Would this
tick's step take me there or past it?"* → snap `global_position` onto the place
exactly and write `current_place` once. There is then no threshold constant to
tune and he lands on the spot at any tick rate — which is what removes the
framerate-dependent arrival that got the proximity model reverted in the first
place. **A "within N metres" arrival check is forbidden.**

**Departure writes null.** The first tick of movement clears `current_place` to
`null`. Nothing else in the project ever writes that field. Without the clear, a
man keeps the Fields all the way to the Inn, and rung 7's *"same place?"* gate
then says two men a hundred metres apart are trading.

`GoToStep` needs a destination, which is dynamic (which plot), so it cannot come
from an `@export`. Give it a verb that takes one — e.g.
`walk_toward(person, place, hours) -> bool` returning whether he has arrived —
rather than overriding `advance(person, hours)`, which has no room for it.

**Where it lives:** as a **child of `WorkStep`**, not a sibling. `Action._ready`
takes the *first* `ActionStep` child it finds, so two `ActionStep`s under one
Action would silently pick one and ignore the other. Nesting also matches what
`action.gd` already documents — a step may hold further machinery — and it is
what lets 6a and 6d reuse walking by nesting the same node under their steps.

**`walk_speed` goes on `Person`, not on the step.** How fast a man walks is a
fact about the man, exactly as `strength` is (Decision 12: *the difference lives
on the body, not on the action*). Put it on the step and every action would need
its own copy, and a fast walker would be fast only at the things you remembered
to edit.

### The falloff curve

Travel cost becomes a score multiplier: **1.0 at his feet, falling off, never
reaching zero**, so a far option is *outbid, never barred*. The natural shape,
and the one the knob's name describes:

```gdscript
# 1.0 at his feet; 0.5 at distance_that_halves_appeal; never 0.
return 1.0 / (1.0 + cost / distance_that_halves_appeal)
```

`WorkTheField.get_utility_score` multiplies its score by this, measured to the
best candidate's place. **Read the next section before choosing any numbers.**

## THE CALL THIS SESSION MUST MAKE — the falloff is over-constrained, and here is the arithmetic

The plan promises rung 4 is *"the first collision that can actually break the
curve."* **It is, and it does.** This was worked out in advance so the session
does not lose a day to it. Do not skip it and do not tune by trial and error.

Every score in this game sits in a narrow band. The adenosine ceiling is 100,
`StayUp` runs 47.3 → 87.3 across the day, and `WorkTheField` currently runs
43 → 103. **`StayUp` is not multiplied by anything** — it is the "stay where you
are" action — so a multiplier below 1.0 on work is a large, one-sided penalty.

The three constraints, with the sun heights that matter:

```
sun height   22:00 = -0.866      04:41 = -0.338      midday = +1.0
StayUp       22:00 = 50.0        04:41 = 60.5        midday = 87.3
```

1. **Bedtime must hold.** A man standing on the plot must score work BELOW
   `StayUp`'s 50.0 at 22:00, or the top waking bid moves and Zoogs stops turning
   in at 22:01. Today: `73 - 25.98 = 47.0`. ✓
2. **Sleep must never be barred** (Decision 11's principle, applied to work):
   work's midday peak should sit below the adenosine ceiling of 100, or a man on
   the plot can never be outbid by exhaustion.
3. **A man at the Inn must actually set off.** Work multiplied by the falloff
   has to beat `StayUp` at some hour, from 19.24 units away.

**Constraint 3 is the one that bites, and the arithmetic is brutal:**

```
falloff at 19.24 units:   d = 12  -> ×0.384      (12.0 is the value Decision 7 suggests)
                          d = 60  -> ×0.757
                          d = 130 -> ×0.871

work from the Inn at midday, at today's 73/30:   103 × 0.384 = 39.6   vs StayUp 87.3
```

**At the shipped numbers a man at the Inn never goes to work at any hour of any
day.** He stands at the Inn forever and the rung is dead on arrival. Worse, it
would *look* like a walking bug.

For work-from-the-Inn to beat `StayUp` at midday you need
`(pull + daylight_pull) × falloff > 87.3`. Hold constraint 2 (`pull +
daylight_pull ≤ 100`) and that forces `falloff > 0.873`, i.e.
**`distance_that_halves_appeal` ≥ ~130 — nearly seven times the width of the
town, which is a falloff curve that does not curve.** Let the falloff genuinely
bite (say `d = 60`, ×0.757) and work's peak has to climb to roughly 125, which
breaks constraint 2.

**Constraints 2 and 3 cannot both hold at this scale. Choose deliberately:**

- **Option A — let the falloff bite, and let work's peak exceed 100.**
  Roughly `pull = 80`, `daylight_pull = 45`, `distance_that_halves_appeal = 60`.
  Check: on the plot at 22:00 → `80 - 39.0 = 41.0 < 50` ✓ bedtime holds. From
  the Inn, work crosses `StayUp` around **07:54**. Cost: a man standing on the
  plot at midday can never be outbid by sleep. He still goes to bed, because
  work collapses in the evening — so the violation is theoretical here, but it
  IS a violation of Decision 11's *outbid, never barred* discipline and must be
  written down as one.
- **Option B — hold the peak under 100 and make the falloff nearly flat**
  (`d ≥ 130`, ~`70/30`). Every claim stays honest and the curve is testable
  (nearer still beats farther), but it barely bites at this town's scale, so
  "outbid by distance" is arithmetic rather than fiction.
- **Option C — make travel cost SUBTRACTIVE** rather than multiplicative
  (`pull + daylight_pull * sun − weight * cost`), which fits a band-limited
  scale naturally and dissolves the whole conflict. **This amends Decision 7,
  which explicitly specifies a multiplier. It is the author's call and NOT this
  session's — stop and ask if you want it.**

**Recommended: Option A**, and record the constraint-2 consequence in
`work_the_field.gd` beside the numbers. It keeps Decision 7 intact, makes the
curve mean something, and it hands `strength` its second job — see below.

**All numbers above must be RE-MEASURED against the running sim, not trusted.
They are a starting point and a proof that the shape works, nothing more.**

### What Option A does to the dawn race — know this before you build it

Under today's numbers Hobb claims the plot **on the tick he wakes, at 04:41**,
while Zoogs is still asleep. That is Decision 12's causal chain: *needed less
sleep → up first → got there first.*

**Move both men to the Inn and that chain changes.** Work does not beat `StayUp`
from the Inn until mid-morning — around 07:54 under Option A — by which time
**both men are awake** (Zoogs is up at 06:01). They set off together, and the
plot is then won by whoever *arrives* first, not by whoever *woke* first.

So the race needs a body difference that survives the walk. **`strength` should
feed `walk_speed`**, the way it already feeds `Brain.get_adenosine_recovery()`.
Decision 12 explicitly anticipated this: *"`strength` will mean more without a
second stat — rung 3's work step wants a rate of work done per hour, and rung 5
wants how much a man can carry. Both are the same capacity."* Walking speed is
that same capacity, and it keeps the difference **on the body and never on the
action**, which is the whole of Decision 12.

The chain becomes *stronger body → walks faster → arrives first → claims it*,
and the loser is outbid **while still walking**, which is exactly the Moment the
plan asks for. Note this as an amendment to Decision 12 when you record the
rung.

## THE PROBE WILL BREAK, AND THIS IS WHERE

Re-authoring the farmers to the Inn breaks claims that read the authored
population. **These are not regressions.** Fix them deliberately and say why in
the commit, the way rung 3 did with claims 6 and 8.

- **Claim 7** asserts `zoogs.get_current_place() == fields` because he is
  authored there. He now starts at the Inn — update the expectation.
- **Claim 8** builds exact sets: `find_people_at(fields)` currently expects
  `[Zoogs, Hobb, Mara]` and `find_people_at(inn)` expects `[Bram]`. **Both move.**
- **Claim 13** is the rung-3 centrepiece and its second assertion —
  *"Hobb claimed it while Zoogs was still asleep"* — **goes false under Option
  A**, because both men are awake by the time anyone sets off.

  **Do not weaken claim 13. Pin its world instead.** The probe already sets
  `current_place` by hand in claims 7, 8 and 16; claim 13 should do the same —
  stand both farmers **on the Fields** explicitly at the top of the check, and
  the pure sleep-order race it was written to prove is preserved exactly. Then
  write the walk-from-the-Inn race as a **new claim**. A claim that pins its own
  setup instead of leaning on authoring is more robust anyway, and this is the
  second rung in a row where authored placement moved underneath one.

- **The probe writing `current_place` by hand is LEGAL and must stay.** `GoToStep`
  owning both edges of that field is a rule about the **game**, not about the
  harness: the probe is authoring a situation, not moving a man. Do not "fix"
  claims 7, 8 or 16 to route through the walking step — you would break three
  green claims to satisfy a rule that does not apply to them.

## THE GATE

**Probe, then Moment. All eighteen existing claims stay green** (with 7, 8 and
13 updated deliberately as above). **New claims start at 19.**

1. **A person distant from the fields closes the gap by exactly
   `walk_speed × hours` each tick**, and eventually reports
   `get_current_place()` as the fields. Assert the per-tick displacement
   exactly, not just that he got there — a step that teleports on the last tick
   would otherwise pass.
2. **In transit, `get_current_place()` is `null`** — not his origin, not his
   destination.
3. **A man whose target is claimed en route** stops: his chosen action is no
   longer `WorkTheField`, **and** his distance to the fields stops decreasing.
   *(Two exact assertions. "Turns around within one tick" is not a predicate, and
   he does not walk home — there is nothing to walk home to until 6c.)*
4. **A nearer station outscores an identical farther one**, and the farther one
   still scores **above zero** — outbid, never barred. Build the second station
   in a **probe-constructed world** (instance a `Place` and a `Workstation` at
   runtime, as the probe already instances people); do not add one to
   `game.tscn`, or rung 3's contention disappears and claim 13 dies with it.
5. **Move a place and which station wins changes** — standing check #3, made
   mechanical.

**Moment:** both farmers wake at the Inn. Mid-morning both set off for the one
plot. **The stronger man arrives first and claims it; the other is outbid
while still walking and stops mid-field.** The first time an interruption costs
nothing is the first time you can *see* that it costs nothing — nothing was
suspended, so there is nothing to put back, and he simply stops.

**Pull the camera back.** It currently frames the fields; the Moment is now a
walk across the whole town. A Moment you cannot see is not a gate.

Run at an 8–12 second day to watch the beat repeat — **Decision 13 established
that shortening the day is a proven instrument for exactly this**, and it works
only because world time is denominated in hours.

## DO NOT BUILD

Pathfinding. A navmesh. Obstacle avoidance. Animation. Steering or acceleration
— move toward a point at a constant speed. A "go home" or `Linger` action — the
loser stopping is sufficient, and `StayUp` is the floor by composition. Beds or
sleeping anywhere in particular (6c). Hunger, the tavern, or `Socialise` (6a,
6d). Inventory (5). A radius-based arrival check of any kind. A second
authored workstation in `game.tscn`. `Workstation.owner` or `is_permitted_to`
(6). `release()` on Workstation — still no caller, still deliberately absent.

## ENGINE FACTS — MEASURED. DO NOT REDISCOVER.

- **`move_and_slide()` cannot be pumped headlessly.** Integrate
  `global_position`. (Decision 4.)
- `process_mode = Node.PROCESS_MODE_DISABLED`, **never** `set_process(false)` —
  the latter is silently discarded from `_initialize()` and you get a
  double-ticked person that reads as a tuning bug.
- `_initialize()` runs before anything is in the tree. `root.add_child()` there
  does **not** run `_ready`. Setup in `_initialize`; assertions from the first
  `_process` frame.
- The harness advances `Clock` itself. Nothing else will.
- **The run line is TWO commands.** `--script` does not build the class cache:
  ```
  "/z/Godot/Godot_v4.4-stable_mono_win64/Godot_v4.4-stable_mono_win64_console.exe" --headless --path . --editor --quit
  "/z/Godot/Godot_v4.4-stable_mono_win64/Godot_v4.4-stable_mono_win64_console.exe" --headless --path . --script game/probe.gd
  ```
- A node reference in a hand-written `.tscn` needs `node_paths` on that node's
  own header or it loads as null. `@export var x: Array[Node]` does not resolve
  at all — use `Array[NodePath]` + `get_node_or_null()`. Claim 4 catches both.
- **An `@export` default in a `.gd` does nothing if the `.tscn` already stores a
  value** — and the reverse: the editor DROPS a stored value that equals the
  script default. The Plot's `work_name` line was removed that way on 2026-08-10,
  so `Workstation.work_name` and `WorkTheField.work_name` now agree by their
  defaults alone. Change one and the farmers silently find no work; the probe
  catches it (claims 13–17 all go red), but know why.
- **A freed reference compares `== null` as TRUE** in this engine — measured
  2026-08-10. The `queue_free()` trap in `CLAUDE.md` is specifically about the
  end-of-frame window. Three `is_instance_valid` guards in the codebase are
  unreachable for this reason and are documented as such; do not "clean them up".
- `class_name` is project-global. Check before naming.

## SYNTAX — the build runs warnings-as-errors

- Ternaries infer `Variant` when the branches differ in type. Annotate.
- `var x = something_returning_Variant` fails the same way. Write
  `var x: Variant = …` or the concrete type.
- Typed arrays throughout: `var found: Array[Workstation] = []`.
- Methods are verbs or questions, never bare nouns. Booleans read as questions
  (`is_`, `can_`, `has_`). Arguments are named for what they ARE, not the role
  they play — `person`, `place`, `station`; never `from`, `it`, `obj`, `who`.
- **`hours`, never `delta`,** below `Population`. Every rate is per world hour —
  including `walk_speed`, which is **units per world hour**, not per second.
- Plain English over CS vocabulary. Comments explain WHY and match the existing
  density in `game/` — that density is the house style, not clutter.

## DELEGATION

Delegate a chunk that is self-contained, mechanically specifiable, and has
ground truth to check itself against.

**Good candidates:** the five new probe claims, handed over **after** the API and
the tuning numbers are frozen, with an exact expected-results table. And the
measurement run that re-derives the schedule after retuning — hand over an
expected table and have it report HOLDS/DEVIATES per line.

**Do NOT delegate:** the falloff call above, `GoToStep` itself (arrival-as-clamp
and the null-on-departure edge are exactly what a cold agent gets wrong), or the
surgical edits to claims 7, 8 and 13.

## BEFORE YOU CLAIM DONE

- Both commands run; **all claims print PASS**; probe exits 0.
- **Every new claim has been seen to FAIL.** Break the thing it guards, confirm
  exit 1, restore. A claim never observed failing is decoration — **five
  assertions in this ladder have already turned out vacuous when checked this
  way**, the most recent on 2026-08-10. Commit the rung FIRST so that per-file
  `git restore` is safe during the break pass; never `git restore .`.
- **The sleep cycle has not moved.** Zoogs still turns in 22:01, sleeps 8.00 h,
  is up 06:01; Hobb still rises 04:41. Retuning `WorkTheField` must not shift
  either man — this is the single most likely casualty of this rung.
- The claims that had to change are updated **deliberately**, with the reason in
  the commit — not quietly renumbered.
- Report the probe output, then **STOP**. Do not begin rung 5.

## STANDING HAZARDS

- **Treat every code snippet in `proving-scene-decisions.md` AND in the build
  plan as intent to be re-derived, not code to paste.** Five have been wrong so
  far and only the probe caught them.
- **Watch for assertions that cannot fail.** This is the ladder's most reliable
  source of wasted work.
- **The working tree on `poc-v2` is clean as of `14a434e`.** Anything
  uncommitted you find is yours.
