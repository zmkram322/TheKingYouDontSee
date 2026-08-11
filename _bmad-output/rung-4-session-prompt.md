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
2. **`_bmad-output/proving-scene-decisions.md`** — **Decision 14 above all**
   (travel cost subtracts and is denominated in hours; it **amends Decision 7**
   and settles the arithmetic this rung stands on), then **7** (the
   identity-check / travel-cost split, and *outbid, never barred*, both of which
   still stand), then **10** (arrival is the overshoot clamp, departure writes
   null, and the `find_people_at(null)` rule that depends on it), then **4**
   (`move_and_slide` cannot be pumped), then **13** (what rung 3 settled and what
   the author saw), then **12** (how two people differ — this rung gives
   `strength` its predicted second job). **This file wins where it and the plan
   disagree, and Decision 14 wins over Decision 7 where those two disagree.**
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

**The visual town is a diorama and must not be "corrected" to human scale.** A
person capsule is 1.7 units tall, so if units were metres the Inn-to-Fields
crossing would be a fourteen-second stroll and every journey in the game would
be free. **The author's ruling: a decent-sized town is a five to fifteen minute
walk to the fields.** Travel speed is calibrated from that fiction — at a
ten-minute crossing, `walk_speed ≈ 115 units per world hour`. The geometry still
means exactly what it meant: double the distance and you double the trip.

## THE JOB

Four things.

1. **`game/actions/go_to_step.gd`** — `GoToStep`, an `ActionStep` that owns
   movement and **both edges of `current_place`**.
2. **`game/person.gd`** — `@export var walk_speed`, the new
   `get_travel_speed()` seam, and `get_travel_cost_to()` **changed to return
   hours**. There is **no** `distance_that_halves_appeal` — Decision 14 cut it.
3. **`WorkStep` learns to walk** — not at the plot's place, walk toward it; at
   it, claim and work. One `advance()`, re-derived from where he is standing,
   holding no route and no progress. `WorkTheField` gains a `patience` export
   and subtracts `patience × hours_to_reach` from its score.
4. **Scene** — **both farmers are re-authored to start at the Inn** (the
   author's call, 2026-08-10). Today nobody in the shipped scene ever travels,
   so the Moment could only be staged by dragging a capsule. Starting them at
   the Inn makes the Moment native: at first light both set off, one arrives and
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

### The two seams — the MEANS and the JOURNEY, kept apart

**The author's call: travel speed gets its own call site, because walking is
only one way to travel.**

```gdscript
# person.gd — the MEANS. On foot today; a horse, a cart, a boat, a bad leg or a
# heavy sack all install in this one body and no caller changes.
func get_travel_speed() -> float:
    return walk_speed

# person.gd — the JOURNEY, and it now returns HOURS. Straight-line ÷ speed
# today; roads, a river crossing and a gate shut at night install here.
func get_travel_cost_to(place: Place) -> float
```

**A horse changes the first. A road changes the second.** Neither has to know
about the other, and that is the whole reason there are two.

`get_travel_speed()` deliberately takes **no destination** — the means of travel
is a fact about the traveller. Anything route-shaped belongs in
`get_travel_cost_to`.

### Travel cost SUBTRACTS, denominated in hours — Decision 14

**Decision 7's multiplier is cut, and so is `distance_that_halves_appeal`.**
Read Decision 14 for why; the short version is that this utility scale has no
meaningful zero, so multiplying taxes a man's entire reason to be awake rather
than taxing his journey, and at the shipped geometry it muted the commute
outright.

```gdscript
# work_the_field.gd
@export var patience := 36.0    # what an hour of walking costs this errand

func get_utility_score(person: Person) -> float:
    var station := get_best_candidate(person)
    var hours_away := person.get_travel_cost_to(station.get_place())
    return pull + daylight_pull * person.get_sun_height() - patience * hours_away
```

`patience` lives on the **action**, because it is a fact about the errand — a
man walks further for a bed than for a beer.

**`pull` and `daylight_pull` do NOT move.** Keep `73 / 30`. A man standing on
the plot pays nothing, so his 22:00 score is still 47.0 against `StayUp`'s 50.0
and **bedtime is untouched.** That is the point of subtraction: it costs nothing
when you are already there.

**The invariant, which is now a probe claim rather than a hope:** no place may
be made unreachable by its own travel cost. Mechanically — *work at its best
hour, from the farthest place in town, still beats `StayUp`*. At a ten-minute
crossing that holds for any `patience` below about 94, so there is enormous
headroom; muting is now hard to do by accident where multiplying made it the
default.

## THE ONE THING THIS SESSION MUST TUNE — the interruption is an inequality

**The arithmetic is already settled (Decision 14) — do not re-derive it and do
not tune by trial and error.** What is NOT settled is the one relationship that
decides whether this rung's Moment exists at all, and it is a trap you will
otherwise walk into after everything else is green.

Rung 4's Moment is a man **outbid while still walking**. That is the rung's
whole proof that interrupting costs nothing — nothing was suspended, so he
simply stops. It happens only if the loser has already set off when the winner
claims:

> **waking gap < commute time**

**The shipped numbers fail this, badly.** The waking gap is **80 minutes**
(Hobb 04:41, Zoogs 06:01) and the commute is **ten**. So whoever wakes first
claims the plot over an hour before the other man opens his eyes, the loser's
gate is already shut when he wakes, he never sets off, and **nobody is ever
interrupted.** Everything would still be green and the rung would have proved
nothing.

**Take the first of these three, and record which you took:**

1. **Set `patience` so work does not pay before sunrise** — then both men are
   awake before either sets off, and the race is decided on **arrival**. At
   `patience ≈ 36` the crossing lands about **06:07**, just after Zoogs wakes.
   Hobb is up at 04:41 and waits for first light, which is good fiction rather
   than a fudge: you do not cross town in the dark for work.
   **This needs a speed difference to decide the race**, or two men leaving the
   same place at the same moment arrive on the same tick and it is settled by
   `Population` child order — the exact hazard Decision 12 exists to prevent.
   So: **`strength` feeds `get_travel_speed()`**, which is the second job
   Decision 12 predicted for it (*"rung 3's work step wants a rate of work per
   hour and rung 5 wants carry capacity — both are the same capacity"*). The
   difference stays on the body and never on the action.
2. Shrink the waking gap to under ten minutes (`strength ≈ 1.02`) — but that
   throws away Decision 12's deliberately visible 04:41 and weakens claim 12.
3. Lengthen the commute past 80 minutes — contradicts the town scale the author
   ruled, and makes every journey tedious.

**Expect the interruption to be BRIEF.** A 15% speed advantage over a ten-minute
walk is about **1.3 minutes** of world time. It is real, the probe can assert it
exactly, and it is *hard to see* — which is why the Moment section below tells
you to slow the day down rather than speed it up. If you want it more visible,
widen it by starting the two men at different offsets near the Inn (their
`global_position`s already differ today) rather than by inflating `strength`.

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
   `get_travel_speed() × hours` each tick**, and eventually reports
   `get_current_place()` as the fields. Assert the per-tick displacement
   exactly, not just that he got there — a step that teleports on the last tick
   would otherwise pass.
2. **In transit, `get_current_place()` is `null`** — not his origin, not his
   destination.
3. **A man whose target is claimed en route** stops: his chosen action is no
   longer `WorkTheField`, **and** his distance to the fields stops decreasing.
   *(Two exact assertions. "Turns around within one tick" is not a predicate, and
   he does not walk home — there is nothing to walk home to until 6c.)* **This is
   the claim the inequality above exists to protect** — if the tuning is wrong
   the loser never sets off, and this claim quietly becomes unconstructible
   rather than red. Build it so it FAILS in that case.
4. **A nearer station outscores an identical farther one.** Build the second
   station in a **probe-constructed world** (instance a `Place` and a
   `Workstation` at runtime, as the probe already instances people); do not add
   one to `game.tscn`, or rung 3's contention disappears and claim 13 dies with
   it.
5. **No place is unreachable by its own travel cost** — work at its best hour,
   from the farthest place in town, still beats `StayUp`. This is Decision 14's
   invariant made mechanical, and it replaces the plan's *"the farther one still
   scores above zero"*, which subtraction makes meaningless.
6. **Move a place and which station wins changes** — standing check #3, made
   mechanical.

**Moment:** both farmers wake at the Inn. At first light both set off for the
one plot. **The faster man arrives first and claims it; the other is outbid
while still walking and stops mid-field.** The first time an interruption costs
nothing is the first time you can *see* that it costs nothing — nothing was
suspended, so there is nothing to put back, and he simply stops where he stands.

**Pull the camera back.** It currently frames the fields; the Moment is now a
walk across the whole town. A Moment you cannot see is not a gate.

**Run at a LONG day — 300–600 seconds — and this inverts rung 3's instrument.**
Decision 13 established the shortened day for watching a once-a-day crossing
repeat, and rung 4 wants the opposite: at the shipped 60-second day a ten-minute
commute takes 0.4 real seconds and the interruption is invisible. At 600
seconds the walk takes about six real seconds and the interruption about one.
Watch it slow first, then speed the day up to see the beat repeat.

**The commute is mostly a day-0 event, and that is honest.** Nothing pulls
anybody home at night — beds arrive at 6c — so both men sleep where they
stopped and wake at or near the fields from day 2 onward. Expect the long walk
once, not every dawn, and do not "fix" it here.

## DO NOT BUILD

A falloff curve or `distance_that_halves_appeal` — **Decision 14 cut both**, and
a session that "restores" them from the plan or from Decision 7 has undone this
rung's central call. Pathfinding. A navmesh. Obstacle avoidance. Animation.
Steering or acceleration
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
  including `walk_speed`, which is **units per world hour**, not per second. And
  `get_travel_cost_to` now returns **hours**, so anything holding its result is
  named for that (`hours_away`, never `distance` or `cost`).
- Plain English over CS vocabulary. Comments explain WHY and match the existing
  density in `game/` — that density is the house style, not clutter.

## DELEGATION

Delegate a chunk that is self-contained, mechanically specifiable, and has
ground truth to check itself against.

**Good candidates:** the five new probe claims, handed over **after** the API and
the tuning numbers are frozen, with an exact expected-results table. And the
measurement run that re-derives the schedule after retuning — hand over an
expected table and have it report HOLDS/DEVIATES per line.

**Do NOT delegate:** the inequality above, `GoToStep` itself (arrival-as-clamp
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
- **Claim 9 already asserts travel cost** — that it falls, rises, and never
  comes back `INF`. Changing the unit from distance to hours keeps every one of
  those true, since hours are distance ÷ a positive speed. If claim 9 goes red,
  you have changed more than the unit.
- **The working tree on `poc-v2` is clean.** Anything uncommitted you find is
  yours.
