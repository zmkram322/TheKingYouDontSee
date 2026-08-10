# Rung 3 — session prompt

Copy everything below the line into a fresh session. Written 2026-08-10, after
rung 2 and the sun anchor shipped.

---

Fable, you orchestrate and delegate to simpler models where applicable — but
remember the guidance on code development semantics below. Build **rung 3** of
the proving-scene ladder. One rung, then stop at the gate.

## ORIENT

Godot 4.4 project in `Z:\TheKingYouDontSee\tkyds-game`. Solo dev. The build is
`game/` — a substrate running one person (Zoogs) through a **sun-anchored** sleep
cycle, with places and travel cost, a live stat/utility graph, a tuning board, an
on-screen clock, and a standing probe harness of **eleven claims** that gates
every rung.

**Rung 3 is the rung the whole plan is built around.** Everything the roundtable
settled about contention is unverified theory until `claim` returns `false` once.

## READ FIRST, IN THIS ORDER

1. **`CLAUDE.md`** (repo root) — naming rules, design rules, Godot traps. Governs.
2. **`_bmad-output/proving-scene-decisions.md`** — **Decision 2 above all**
   (day-long tenancy), then **10 and 11** (what rungs 2 and the sun anchor
   settled and what rung 3 inherits), then **1** (`find_candidates` and the
   idleness counters as accumulators) and **7** (the radius bound and hard cap
   are CUT; candidates sort by travel cost). **This file wins where it and the
   plan disagree.**
3. **`_bmad-output/proving-scene-build-plan.md`** — the "Rung 3" section only.
4. **`game/town.gd`, `game/person.gd`, `game/population.gd`, `game/probe.gd`** —
   read them before writing anything. Rung 3 extends all four.

Do not read the later rungs. They are not this session's work.

## WHERE THE BUILD IS

Committed on `poc-v2`:

```
956fb3e  rung 0  world time in hours + the probe
01f0272  rung 1  Population owns who thinks
a4c38fd          the .tscn wiring scan lifted into scene_wiring.gd
9722033  rung 2  Place, Town, current_place, travel cost
77dc7a9          places carry their own mesh so dragging one drags the place
d10afa6          PersonReadout + an on-screen clock; camera pulled back
cd5fc7c          the sleep cycle hung on the sun
fab7c1b          Decision 11 recorded
```

```
game/      person, stats, brain, action, action_step, decision_engine, clock,
           daylight, population, place, town  |  probe.gd, scene_wiring.gd
actions/   StayUp+BeUp, Sleep+Rest, Wake+WakeUp
ui/        stat_graph, tuning_board, person_readout

game.tscn: Game
├─ Clock, Sky, Daylight, Ground
├─ Town ─ Fields, Inn                    (Place; MeshInstance3D carrying a pad)
├─ Population ─ Zoogs                    (authored at the Fields)
├─ Camera
└─ Screen ─ StatGraph, UtilityGraph, PersonReadout, TuningBoard
```

**REGRESSION BASELINE — the old 18.01 / 23.62 pair is dead.**

```
cold start   turns in hour 21.11 (21:07), up at 29.67 (05:40)
settled      turns in 22:01, sleeps 8.00 h, up 06:01   <- day 3 onward, to the minute
```

The probe pumps **48 hours**, not 24. Eleven claims. Exits non-zero on any
failure.

**`Workstation`, `WorkTheField`, `WorkStep` and `Linger` are all free as
`class_name`s. Verified 2026-08-10.**

## THE JOB

Two seams, one action, and two counters.

```
Workstation.claim(person) -> bool                 taken in DO, by a man standing here
Workstation.is_free_for(person) -> bool           asked in GATE, every tick, by everybody
Town.find_workstations(person, work_name)         sorted by travel cost, stably
Town.note_no_candidates_existed()                 "there was no field"
Town.note_every_candidate_was_taken()             "every field was taken"
```

- **`game/workstation.gd`** — `claimed_by` + `claimed_on_day`. A **day-long
  tenancy**, not a per-tick lease. A claim stamped yesterday simply isn't a claim
  today, so **expiry is lazy** — one comparison at read time. **Nothing sweeps.
  UPKEEP never touches this.** `is_instance_valid(claimed_by)` first, always.
- **`game/actions/work_the_field.{gd,tscn}` + `work_step.gd`** — the Action gates
  on "are there candidates", scores on "how good is the best one", and the step
  claims and works.
- **`game/town.gd`** — `find_workstations`, the two counters.
- **Scene:** the grain fields with **one plot** and **two farmers**. Deliberately
  short by one; with four plots and four farmers the contention design cannot
  occur. Both farmers must be **standing at the Fields** — there is no walking
  until rung 4.

**Ask once, not three times.** `is_available_to` needs *"are there candidates"*,
`get_utility_score` needs *"how good is the best one"*, the step needs *"which one
am I claiming"*. If those three re-derivations disagree, **the utility that won is
not the utility he gets** — which reads as "the AI is flaky" and costs a day.
One `get_best_candidate(person)`, and the stable sort is what makes the three
agree. **Never iterate a Dictionary for candidates.**

**Renewed by use.** The working step calls `claim()` on **every tick it
advances**, not once at the start. He is present, it is already his, so it
re-stamps today and dawn passes under him. Nothing else keeps a claim alive.

**Two counters, not one.** *"There was no field"* and *"every field was taken"*
are different worlds and the fixes are opposite. Collapsed into one number, the
day the town runs out of work looks exactly like the day it runs out of workers.
They are **decaying accumulators, never histories** — one number, not a list of
nights.

## FOUR CALLS THE SESSION MUST MAKE — do not let these be decided by drift

### 1. The dawn tie. THE SUN ANCHOR BROKE "EARLY BIRD CATCHES THE WORM."

Decision 2 rules the positive-feedback loop a **feature**, not a starvation bug:

> waking order decides who farms → waking order comes from adenosine →
> adenosine comes from when he went to sleep → the early riser gets a plot,
> works, tires, sleeps early, rises early, gets a plot again.

**That mechanism no longer exists.** Since 2026-08-10 the cycle is anchored to
the sun, and the probe's own claim 11 asserts that *two people who start from
different histories keep the same hours*. Two farmers from the same scene with
the same numbers now wake **on the same tick, at 06:00, forever.** There is no
early bird.

So the contest is decided by **`Population`'s child order** — which Decision 2
explicitly names as the hazard it was glad to have narrowed: *"scene order
silently deciding every contest."* It will work, the probe will pass, and the
Moment will be a coin flip that lands the same way every morning.

Two ways out:

- **(a) Differentiate the two farmers.** One authored number on one instance —
  a slightly lower `StayUp.pull`, or a slightly higher `base_adenosine_per_hour`
  — and he wakes minutes earlier, every day, for a reason you can point at.
  Restores the early-bird loop *inside* the anchored rhythm, and it is exactly
  what `person.gd` already documents: *"what makes an instance somebody in
  particular is the exports."*
- **(b) Accept scene order at rung 3** and let rung 4 fix it, when the two stand
  in different places and arrival order decides.

**Recommendation: (a).** It is one number, it makes the Moment watchable, and
(b) is what happens by default if nobody chooses — which is the drift this
section exists to prevent. **Whichever is chosen, say so in the scene and in the
commit**, because a later reader will otherwise "fix" the asymmetry.

### 2. The idleness counters are a WRITE, and GATE is supposed to be a read.

The frame is explicit: **gate and score are reads, DO is the only write.** But
*"there was no field"* is only knowable in `is_available_to`, which is where the
plan puts it.

Recommendation: **write them from the gate, and say in a comment that telemetry
is not world state** — nothing reads them back into a decision, so they cannot
change what anybody does. Same exemption `DecisionEngine._last_scores` already
takes and documents. **Make the exception explicit** so it does not silently
license writes in gates generally.

### 3. `release()` — do not build it.

The plan lists `release(person)` and calls it *"an Action he SCORES."* **Nothing
scores it at rung 3**, and under renew-on-use, abandoning a plot IS simply not
renewing it — the claim lapses at the next day boundary on its own. Building it
would be a call site with no caller.

Recommendation: **leave it out**, and note in `workstation.gd` that it is
deliberately absent and what would earn it.

### 4. A Workstation is a child of a Place.

Decision 2's `is_permitted_to` already references `Workstation.get_place()`, and
`place.gd` already says rung 3 stands workstations at a place. So:

- The plot is a child of the `Fields` `Place` node.
- `get_place()` returns `get_parent() as Place` — the same "structurally its
  parent" pattern `Brain` and `ActionStep` already use.
- **Presence** is `person.get_current_place() == station.get_place()`. Not a
  distance. Never a radius.
- `Town.find_workstations` walks its places' children.

## WHAT CHANGED UNDER THE PLAN — RE-DERIVE, DO NOT PASTE

**The plan's rung 3 snippet shows `clock.day()` on the Workstation.** Decision 2
flagged that a per-station `Clock` reference is the `node_paths` trap waiting to
happen. **It is no longer needed.** Since `cd5fc7c`, `Person` carries a `Clock`,
pulled off `Population` in its own `_ready` beside its `Town`. So:

```gdscript
# in claim(person) / is_free_for(person)
person.clock.day()      # not a clock of the station's own
```

**Not one workstation carries a wire.** This is the single most important
correction to the plan's snippet.

**Decision 7 already CUT** rung 3's radius bound and its hard cap of ~3. Do not
reintroduce either. `find_workstations` returns **every** matching station,
stably sorted by travel cost, node path as tiebreak. The metric exists:
`person.get_travel_cost_to(place)`.

## THE PROBE WILL BREAK, AND THIS IS WHERE

Adding a second farmer to `game.tscn` breaks **existing** claims. These are not
regressions; the probe reads the authored population. Fix them deliberately and
say why in the commit.

- **Claim 6** asserts `population.get_people().size() == 2` after adding
  "Doomed", then `== 1` after freeing him. With two farmers authored, those
  become **3 and 2**.
- **Claim 8** builds exact sets against the authored population —
  `find_people_at(fields)` currently expects `[Zoogs, Mara]`. **Any farmer
  authored at the Fields joins that set.**
- **Claim 7** asserts Zoogs is authored at the Fields. Leave him there or update it.
- `StatGraph`, `UtilityGraph` and `PersonReadout` are all wired to
  `Population/Zoogs` by `NodePath`. The plan wants **two more graph instances**
  for the farmers — you will be at five panels on one screen; lay them out
  deliberately.

## THE GATE

**Probe, then Moment. All eleven existing claims stay green.** New claims start
at 12.

1. **Two persons, one station: one `claim` returns `true`, the other `false`** —
   and `WorkTheField` is **off the loser's ballot entirely.** He is never scored,
   not outscored. (Check `get_last_scores()` records `NAN` for him, which is what
   the graph draws as a hole.)
2. **A claim survives a day boundary while being worked** — renew-on-use.
3. **A claim does NOT survive a day boundary while abandoned.**
4. **A claim attempted from the wrong place fails.** Presence is required; you
   cannot reserve a plot from your bed.
5. **`free()` the holder, pump two ticks, and the loser can now claim it.**
   Standing check #1 made mechanical. **Use `free()`, not `queue_free()`** —
   queued deletion does not land until the end of the frame, so inside one pumped
   tick the node is still perfectly valid and the guard is never exercised. (The
   probe already documents this at claim 8.)
6. **With zero stations existing**, `WorkTheField.is_available_to` is false and
   the *no candidates existed* counter incremented — **not** the *all taken* one.

**Moment:** two capsules. Both wake, both score "work the field" high. One claims
it and his utility curve settles. **The other's scores visibly scramble on the
graph you already built** — `WorkTheField` drops to a gap, something else climbs,
and he picks a different life. **The loser loses for a whole day and you watch
him live a different one.**

**Shorten the day to watch it repeat.** Run at an 8–12 second day on the tuning
board and the beat comes every few seconds: dawn, both bid, one loses, his curves
re-scramble. This only works because world time is denominated in hours — and now
also because the cycle is sun-anchored, so shortening the day scales the whole
world together instead of unhooking the body from the sun.

## DO NOT BUILD

Queueing. Waiting. Reservation. Priority between the two farmers. A fairness rule
or a rotation. **A sweep of any kind** — Decision 2 ruled it out and it is
incompatible with the frame-stagger rung 1 exists to enable. A radius bound or a
nearest-N cap (Decision 7 cut both). `Workstation.owner` or `is_permitted_to`
(rung 6). An `Idle` or `Linger` floor action — **`StayUp` is the floor by
composition and that is sufficient.** Walking or arrival (rung 4) — both farmers
start standing at the Fields. The falloff curve or
`distance_that_halves_appeal` (rung 4). Inventory, grain or anything carried
(rung 5). `Recipe` or `Workstation.progress` (9a). A `Clock` reference on the
Workstation.

## ENGINE FACTS — MEASURED. DO NOT REDISCOVER.

- `process_mode = Node.PROCESS_MODE_DISABLED`, **never** `set_process(false)` —
  the latter is silently discarded from `_initialize()` and you get a
  double-ticked person that reads as a tuning bug.
- `_initialize()` runs before anything is in the tree. `root.add_child()` there
  does **not** run `_ready`. Setup in `_initialize`; assertions from the first
  `_process` frame.
- The harness advances `Clock` itself. Nothing else will.
- `move_and_slide()` cannot be pumped headlessly. Not needed this rung.
- **The run line is TWO commands.** `--script` does not build the class cache:
  ```
  "/z/Godot/Godot_v4.4-stable_mono_win64/Godot_v4.4-stable_mono_win64_console.exe" --headless --path . --editor --quit
  "/z/Godot/Godot_v4.4-stable_mono_win64/Godot_v4.4-stable_mono_win64_console.exe" --headless --path . --script game/probe.gd
  ```
- A node reference in a hand-written `.tscn` needs `node_paths` on that node's
  own header or it loads as null. `@export var x: Array[Node]` does not resolve
  at all — use `Array[NodePath]` + `get_node_or_null()`. Claim 4 catches both.
- **An `@export` default in a `.gd` does nothing if the `.tscn` already stores a
  value.** This cost time during the sun-anchor tuning: `stay_up.tscn` held
  `pull = 45.0` and silently won over the script. The scene is the authoring
  surface — put the number there, and keep the script default matching it.
- `class_name` is project-global. Check before naming.

## SYNTAX — the build runs warnings-as-errors

- Ternaries infer `Variant` when the branches differ in type. Annotate.
- `var x = something_returning_Variant` fails the same way. Write
  `var x: Variant = …` or the concrete type.
- Typed arrays throughout: `var found: Array[Workstation] = []`.
- Methods are verbs or questions, never bare nouns. Booleans read as questions
  (`is_`, `can_`, `has_`). Arguments are named for what they ARE, not the role
  they play — `person`, `place`, `station`; never `from`, `it`, `obj`, `who`.
- Plain English over CS vocabulary. Comments explain WHY and match the existing
  density in `game/` — that density is the house style, not clutter.

## DELEGATION

Delegate a chunk that is self-contained, mechanically specifiable, and has
ground truth to check itself against.

**Good candidate:** the six new probe claims, handed over **after** the API is
frozen, with an exact expected-results table. That is a bigger and cleaner
delegation than rung 2 had.

**Do NOT delegate:** `workstation.gd` itself (Decision 2's snippet has to be
re-derived, and the `person.clock.day()` correction is exactly what a cold agent
would miss), the four design calls above, or the surgical edits to the existing
probe claims.

## BEFORE YOU CLAIM DONE

- Both commands run; **all seventeen claims print PASS**; probe exits 0.
- **Every new claim has been seen to FAIL.** Break the thing it guards, confirm
  exit 1, restore. A claim never observed failing is decoration — **four
  assertions in this plan have already turned out vacuous when checked this
  way**, three of them found by doing exactly this.
- The pre-existing claims that had to change for the second farmer are updated
  **deliberately**, with the reason in the commit — not quietly renumbered.
- **The sleep cycle has not moved.** Settled schedule still turns in 22:01,
  sleeps 8.00 h, up 06:01. Adding a farmer must not shift Zoogs.
- Report the probe output, then **STOP**. Do not begin rung 4.

## STANDING HAZARDS

- **Treat every code snippet in `proving-scene-decisions.md` AND in the build
  plan as intent to be re-derived, not code to paste.** Four have been wrong so
  far — three in the decisions doc, one in the plan — and only the probe caught
  them. Decision 2's `workstation.gd` is the biggest snippet still unimplemented
  and it is this rung's.
- **Watch for assertions that cannot fail.** Two `is_instance_valid` guards in
  the codebase are currently unreachable and documented as such. Rung 3 is the
  first rung where one person's action can affect another, so it may be the rung
  that finally gives them teeth — check, don't assume.
- The working tree on `poc-v2` is clean as of `fab7c1b`. Anything uncommitted you
  find is yours.

Await the author's guidance before writing code.
