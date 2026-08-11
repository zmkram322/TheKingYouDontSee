# Rung 4 — session prompt

Copy everything below the line into a fresh session. Written 2026-08-10, the
day rung 3 closed.

**This rung is NOT routed to Fable** (see the model-routing note: Fable is for
3, 6b, 6d, 7 and 8). So this prompt is deliberately more explicit than rung 3's
was: where that one could say *"re-derive this, don't paste it"* and trust it to
land, this one spells the corrected shape out. **Nothing below is optional
detail.**

**Two earlier drafts of this prompt were wrong in the same way** and the record
of that is Decision 15: they invented a tuning knob whose only job was to make
this rung's Moment look the way the build plan describes it. If you find
yourself reaching for a number to make a Moment happen, **stop and ask the
author whether what actually happens is sufficient.** A Moment is a prediction
about what the causes will produce, not a specification to satisfy.

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
2. **`_bmad-output/proving-scene-decisions.md`** — **Decision 15 above all**
   (what distance is allowed to decide, and what a man can know from afar; it
   **amends 14, which amends 7**, and it settles what this rung stands on),
   then **14** (the multiply-vs-subtract rule, hours, and the two travel seams —
   noting its `patience` weight is the part 15 overturned), then **7** (the
   identity-check / travel-cost split, and *outbid, never barred*, both of which
   still stand), then **10** (arrival is the overshoot clamp, departure writes
   null, and the `find_people_at(null)` rule that depends on it), then **4**
   (`move_and_slide` cannot be pumped), then **13** (what rung 3 settled and what
   the author saw), then **12** (how two people differ — this rung gives
   `strength` its predicted second job). **This file wins where it and the plan
   disagree, and where these decisions disagree with each other the HIGHEST
   number wins: 15 over 14 over 7.**
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
de8502a          Decision 14 — travel cost subtracts, in hours
b51a8fb          Decision 15 — what distance may decide, and what is known afar
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
   holding no route and no progress. **`WorkTheField`'s SCORE does not change**
   — see Decision 15 below. Its candidate query gains one condition: a station
   he is not standing at is a candidate regardless of who holds it.
4. **Scene** — **both farmers are re-authored to start at the Inn** (the
   author's call, 2026-08-10). Today nobody in the shipped scene ever travels,
   so the Moment could only be staged by dragging a capsule. Starting them at
   the Inn makes the Moment native: at first light both set off, one arrives and
   claims, and the other arrives to find the job gone.

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

### Why the unit is hours, when it changes nothing you can see at this rung

Decision 7's multiplier is cut, and so is `distance_that_halves_appeal` — read
Decision 14 for why, and Decision 15 for what replaced the subtraction it
proposed.

**Be honest with yourself about what the unit buys here: nothing observable.**
Sorting by hours and sorting by distance are the SAME ordering for one person,
because travel speed is positive. It is kept because it is the honest unit,
because `get_travel_speed()` is needed the moment anybody walks at all, and
because hours are what a road or a horse actually change. **It earns itself at
rung 9a**, when candidates first differ in quality and cost has to be traded
against yield. Do not go looking for a behaviour change at rung 4 and conclude
the change did not work.

## THE CALL ALREADY MADE FOR YOU — knowledge is local, and travel cost only orders candidates

**Decision 15. Do not re-open either half, and do not add a knob to either.**

An earlier draft of this prompt had a `patience` weight whose only real job was
to delay the farmers' departure so the loser would be outbid *en route* and the
Moment would look the way the build plan describes. That is **building the
observation instead of the cause**, the author caught it, and it is deleted. If
you find yourself reaching for a number to make a Moment happen, you are making
the same mistake — stop and ask.

### Freeness is knowable only where you are standing

Rung 3 lets `WorkTheField`'s gate ask whether a plot is **free** from anywhere in
the world. With both farmers standing in the same field that was invisible; the
moment they are apart it is **omniscience**, and it kills this rung: a man at the
Inn would know the plot was taken, so work would never reach his ballot, so he
would never set off, and nothing could ever interrupt him.

> **Not at the plot's place** → he knows it EXISTS, not whether it is taken. It
> stays a candidate, the urge to work stands, and he walks.
> **At the plot's place** → he can see it. Taken by somebody else → it drops out,
> and work leaves his ballot **at the moment he arrives.**

One condition on the candidate query. **No new knob**, and it mirrors a rule the
codebase already has: presence is required to *claim*, and now presence is
required to *know*.

**`Workstation.is_free_for` does not change** — the station keeps reporting the
plain truth about itself, and what a man KNOWS of that truth is the Action's
business. **The comment on that function argues the opposite and is wrong; fix
the comment, not the code.**

This restores the standing default rather than inventing one: Decision 1 already
deferred the notice board, describing exactly this move — discovery in DO, not
in GATE. **The wasted journey is the point**, because it is the collision that
later earns the notice board.

### Travel cost competes the same alternative at different locations, and nothing else

> **Pull decides WHAT you do. Travel cost decides WHERE you go to do it.**

Travel cost belongs to choosing among an action's **candidates** — this plot or
that one. **It never enters the comparison between one action and another.** That
is what makes muting a commute structurally impossible rather than a tuning
invariant somebody has to remember to check.

**So rung 4 changes NOTHING about scoring:**

- `WorkTheField.get_utility_score` keeps `pull + daylight_pull * sun`. **`73 / 30`
  stands untouched.** No subtraction. No coefficient. No `patience`.
- `Town.find_workstations` **already sorts by travel cost** — shipped at rung 3.
  Travel cost is already doing its only job.
- **There is no tuning problem and no retune.** Bedtime cannot move, because
  nothing about the score moved.

**Do not add a travel-cost coefficient.** Ordering identical candidates by
`appeal − k × hours` is just ordering by hours at any positive `k`, so the
coefficient decides nothing until candidates differ in **quality** — which is
rung 9a's `Recipe`. A number nothing can read is substrate before need.

### What the Moments actually are — accepted as they unfold

Not staged, not tuned for. This is what the causes produce:

- **Day 0** — both wake at the Inn. Work overtakes `StayUp` around **03:45**
  (`73 + 30·sun > 67.3 + 20·sun` at `sun > −0.57`). Both set off. **The faster
  man arrives first and claims; the other arrives to find the job gone and
  re-decides standing in the furrow.**
- **Day 1 onward** — nothing pulls anybody home at night (beds are 6c), so both
  wake at or near the fields. Hobb claims at 04:41; Zoogs wakes at 06:01, sees it
  taken, and re-decides on the spot. The short version of the same beat.

Two men leaving the same place at the same moment would otherwise arrive on the
same tick and the plot would go by `Population` child order — the exact hazard
Decision 12 exists to prevent. **So `strength` feeds `get_travel_speed()`**,
which is the second job Decision 12 predicted for it (*"both are the same
capacity"*), and the difference stays on the body rather than on the action.

## THE PROBE WILL BREAK, AND THIS IS WHERE

Re-authoring the farmers to the Inn breaks claims that read the authored
population. **These are not regressions.** Fix them deliberately and say why in
the commit, the way rung 3 did with claims 6 and 8.

- **Claim 7** asserts `zoogs.get_current_place() == fields` because he is
  authored there. He now starts at the Inn — update the expectation.
- **Claim 8** builds exact sets: `find_people_at(fields)` currently expects
  `[Zoogs, Hobb, Mara]` and `find_people_at(inn)` expects `[Bram]`. **Both move.**
- **Claim 13** is the rung-3 centrepiece, and it may well still pass — which is
  the danger. It pumps ten hours from a shared bedtime and asserts that Hobb
  first held day 2's plot *and that Zoogs was still asleep when it happened*.
  With both men starting at the Inn, Hobb now wakes, **walks**, and claims some
  ten minutes later — still comfortably before Zoogs wakes — so the assertion
  survives **by accident**, on the walk happening to fit inside the pump window.

  **Do not leave it resting on that. Pin its world.** The probe already sets
  `current_place` by hand in claims 7, 8 and 16; claim 13 should do the same —
  stand both farmers **on the Fields** explicitly at the top of the check, so
  the pure sleep-order race it was written to prove is preserved exactly and no
  longer depends on travel time at all. Then write the walk from the Inn as a
  **new claim**, where it belongs. This is the second rung running where
  authored placement moved under a claim; pinning is the durable fix.

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
3. **A man walks toward a plot he cannot see the state of, and work leaves his
   ballot ON ARRIVAL.** Two exact assertions: while he is away from the Fields
   and the plot is held by somebody else, `WorkTheField.is_available_to` is
   **true** and his distance is decreasing; on the tick he arrives it is
   **false** and `get_last_scores()` records `NAN` for it. This is Decision 15's
   knowledge rule made mechanical, and it is the claim that would go red if
   anybody restores the omniscient gate.
4. **A man does not walk to a plot he is standing next to and can see is
   taken** — the same rule from the other side, so the gate is not simply always
   true when away.
5. **A nearer station is chosen over an identical farther one.** A
   **candidate-ordering** assertion, not a score assertion — assert
   `get_best_candidate` returns the near one, not that any score is bigger.
   Build the second station in a **probe-constructed world** (instance a `Place`
   and a `Workstation` at runtime, as the probe already instances people); do
   not add one to `game.tscn`, or rung 3's contention disappears and claim 13
   dies with it.
6. **Move a place and which station wins changes** — standing check #3, made
   mechanical.

*(The plan's "the farther one still scores above zero — outbid, never barred" is
**retired**. Under Decision 15 travel cost never enters a cross-action score at
all, so there is no number for it to be barred by; the property it was
protecting is now structural.)*

**Moment — accepted as it unfolds, not staged.** Day 0: both farmers wake at the
Inn, work overtakes `StayUp` around 03:45, both set off. **The faster man
arrives first and claims it; the other arrives to find the job already gone and
re-decides standing in the furrow.** Day 1 onward is the short version — Hobb
claims at 04:41, Zoogs wakes at 06:01 and finds it taken where he stands.

**Pull the camera back.** It currently frames the fields; the Moment is now a
walk across the whole town. A Moment you cannot see is not a gate.

**Run at a LONG day — 300–600 seconds — and this inverts rung 3's instrument.**
Decision 13 established the shortened day for watching a once-a-day crossing
repeat; rung 4 wants the opposite, because at the shipped 60-second day a
ten-minute commute takes **0.4 real seconds** and you will not see anybody walk
anywhere. At 600 seconds the walk takes about six real seconds, which is long
enough to watch two men cross the town and one of them stop dead on arrival.
Watch it slow first, then speed the day up to see the beat repeat.

**Note nobody is outbid mid-stride.** Under the knowledge rule the loser cannot
see the plot until he reaches it, so he walks the whole way and the drop happens
**on arrival** — he does not turn around in the middle of the field. That is the
build plan's Moment amended by Decision 15, and it is the correct behaviour, not
a bug to tune out.

**The commute is mostly a day-0 event, and that is honest.** Nothing pulls
anybody home at night — beds arrive at 6c — so both men sleep where they
stopped and wake at or near the fields from day 2 onward. Expect the long walk
once, not every dawn, and do not "fix" it here.

## DO NOT BUILD

A falloff curve or `distance_that_halves_appeal` — **Decision 14 cut both**, and
a session that "restores" them from the plan or from Decision 7 has undone this
rung's central call. **A travel-cost term in any action's utility score, under
any name** — Decision 15 confines travel cost to candidate ordering, and
`patience` in particular was deleted for being a knob that existed to stage a
Moment. **A travel-cost coefficient**, which decides nothing until candidates
differ in quality at 9a. Pathfinding. A navmesh. Obstacle avoidance. Animation.
Steering or acceleration — move toward a point at a constant speed. A "go home"
or `Linger` action — the loser stopping is sufficient, and `StayUp` is the floor
by composition. Beds or
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
  named for that (`hours_away`, never `distance`).
- Plain English over CS vocabulary. Comments explain WHY and match the existing
  density in `game/` — that density is the house style, not clutter.

## DELEGATION

Delegate a chunk that is self-contained, mechanically specifiable, and has
ground truth to check itself against.

**Good candidates:** the six new probe claims, handed over **after** `GoToStep`'s
API is frozen, with an exact expected-results table. And a measurement run that
pumps six days and reports the schedule plus who claimed the plot when — hand
over an expected table and have it report HOLDS/DEVIATES per line. **Nothing is
being retuned this rung**, so that run is a regression check rather than a
search: if any line deviates, something unintended moved.

**Do NOT delegate:** the knowledge rule above, `GoToStep` itself (arrival-as-clamp
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
  is up 06:01; Hobb still rises 04:41. **Nothing this rung touches the score, so
  there is no legitimate reason for either man's hours to move** — if they do,
  you have changed something you did not mean to, most likely by giving the
  walking step an `exertion` other than 1.0 and quietly altering how fast he
  tires.
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
