# Gate 0 — what landing the rung-6 repair found

**Written 2026-08-20**, the day Gate 0 of the boss ladder landed (`07a1400`,
`ef04050`, `e756795`, `1575b3a`, `d11fe8c` on `poc-v2`). Opus orchestrated;
Sonnet agents built each gate against re-derived delta sheets; every gate was
verified independently before it was committed.

**This file is for a conversation, not for a builder.** It is the things a green
probe does not say. Every number in it is measured — from a twelve-day pump of
the shipped scene, run and deleted — and where it is a projection it says so.

Read Part 1 first. Part 0 is an error to know about before you trust anything.

---

## Part 0 — One thing was built that the plan said to defer

`boss-scene-build-plan.md`, Gate 0, carries a banner:

> **HOLD THE SHARE-SIZING HALF.** Decisions 29/31 size how much grain a worker
> keeps. Under this ladder that quantity is a **wage**, and Gate 8 authors it
> properly. Landing the dither fix (Decision 30, a pure deletion) is required;
> authoring share numbers that Gate 8 deletes is not. Build the deletion, defer
> the arithmetic.

**The arithmetic was authored anyway.** The session worked from
`rung-6-repair-session-prompt.md` (2026-08-18), whose Step 0 makes the sizing a
required author call, and never opened the newer `boss-scene-build-plan.md`
(2026-08-19) that amends it — the file CLAUDE.md names as the forward ladder to
start from. That is the error, recorded rather than smoothed over.

| | |
|---|---|
| The wage **mechanism** | **Keep.** Decision 29 mandates it independently — the ownership branch, `add` not `hand_over`, deleting `work_for_hire_step.gd`. Without it nobody ever holds a grain and the loop cannot close at any tuning. |
| `share_of_crop = 0.35`, `base_grain_per_hour = 2.5`, `larder_target = 6` | **Gate 8's to re-author.** Treat as measured placeholders, not settled numbers. |
| The twelve-day measurement | **Keep — it is the payoff.** It could not have been taken without the numbers, and it is the first honest measurement this project has had. |

**The judgement for next session:** revert the three numbers to something inert
until Gate 8, or leave them standing so the ladder is watched in a town where the
loop closes. Recommendation: **leave them** — a town that starves on day 9 is a
worse instrument than one that feeds one man — but that is not this file's call.

---

## Part 1 — The loop closes. That is the headline.

**work → grain → bread → eat had never fired in this project. It fires now.**

**Hobb bakes his first loaf on day 7 at 16:20**, one minute after his last one
runs out. It is a settled cycle, not a single event: two loaves a day, every day,
through day 11. His furrow hours do not dent — 10.19 h/day before and after,
because `MakeBreadStep` costs grain, not time.

Twelve days of the shipped scene, measured by counting **ticks that reached the
yield line**, never ticks whose action was *named* work:

| | Zoogs | Hobb | Marle |
|---|---|---|---|
| furrow hours | **0.00 h** | 128.96 h | **0.00 h** |
| grain produced | **0** | **322** | **0** |
| loaves baked | 0 | **10** | 0 |
| ends holding | 0 grain, 0 bread | 82 grain, 2 bread | 0 grain, 0 bread |

Barn: **210 grain.** Conservation exact: 322 = 82 + 210 + 30 baked away. The wage
lands at **0.348** against an authored 0.350 across 322 grain — the fractional
carry converges correctly.

**Hobb's grain is a genuine surplus with nowhere to go.** He gains ~25/day and
spends 6, accumulating ~19/day, because nothing in the game gives grain a second
purpose. That is the pressure Gate 8 exists to relieve, now a measured quantity
rather than an argument.

---

## Part 2 — Three findings that want a decision

### 1. The larder target governs nothing. `bite` was tuned for the wrong kind of gap.

**Hobb's bread parks at 2 and never approaches `larder_target = 6`.**

`MakeBread` scores `115 × gap^3`, where `gap = (6 − stock)/6`:

| bread in pack | 6 | 4 | 2 | 1 | 0 |
|---|---|---|---|---|---|
| MakeBread scores | 0.00 | 4.26 | 34.07 | 66.55 | 115.00 |

against `StayUp` at 50–67 and work up to 103. **Baking is inert until the pack is
empty**, then spikes. The equilibrium sits just above zero, and the authored
target of 6 only scales a curve that is flat everywhere it matters.

**The cause is a mismatch, not a tuning error.** `bite = 3` was authored when
`MakeBread` scored on **hunger** — a gap that reliably saturates, so cubing it is
right and gives the late decisive spike `Eat` wants. **Decision 31 moved it onto a
STOCK gap**, which is a gap you want *maintained* rather than *saturated*, and
cubing a maintenance gap guarantees it is never maintained.

**Neither Decision 29 nor 31 rules on this.** Nothing was changed. Named so it is
decided rather than discovered:

> **What curve is right for a gap you want held at a level, as against a gap that
> climbs to its ceiling on its own?**

Do not answer by retuning 3 to 1.5 — that is the banned shape, a number standing
in for a mechanism. The real question is whether a stock gap wants a different
curve *form*, or a target meaning "bake toward this" rather than "bake when below
this."

### 2. Two of three men starve permanently — watched now, not predicted

Zoogs and Marle hit zero bread at **day 7, 16:29** and pin at the hunger ceiling
**24.00 hours a day from day 9 onward**, for the rest of the window:

| day | 5 | 6–7 | 8 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|
| hours pinned (both) | 1.17 | 0 | 14.86 | **24.00** | **24.00** | **23.99** |

This is the day-7/8 collapse the rung-6 findings file predicted, one day later
because the higher yield left Hobb marginally more efficient than that estimate
assumed. **It is correct per Decisions 29 and 30** — Zoogs loses every dawn race
and has no second plot; Marle owns the land, the crop lands at the fields' Place,
and he has no work action and no hauling action. Both decisions say outright they
do not fix this. **Neither man was given an action.**

**Two different causes converge on one symptom**, and separating them matters:

- **Day 5's 1.17-hour pin was SLEEP-gated.** Bread was in the pack the whole
  time. `Eat.is_available_to` requires `is_awake()`, so hunger crossed 100
  overnight and sat clamped until morning. **A man starves in his sleep with food
  in his bag**, and nothing is wrong with the code. Nobody has asked whether that
  is wanted.
- **Day 9's pin is AVAILABILITY-gated.** `Eat`'s gate fails on
  `has_at_least(bread, 1)` regardless of waking. Being awake stops helping.

### 3. The dither halved. The half that remains is not the field.

Zoogs' action changes on day 2: **1145 before, 357 after** — a 69% cut, and
Decision 30's register is what did it. But it did **not** collapse to Hobb's ~249,
as the repair prompt anticipated.

**The diagnosis is clean, and it is the sharpest thing the measurement produced:
Marle sits at 356–358/day with no work obligation at all, never once approaching
the plot.** He mirrors Zoogs almost exactly. So the residual has nothing to do
with plots or the register — it is the `Socialise`/`StayUp` oscillation named in
Decisions 23/24, which is what **failure-marks-the-candidate** is for, and was
explicitly out of scope.

It is also indifferent to starvation: Zoogs holds 355–356/day right through the
famine, because `Eat` drops off his ballot entirely rather than dithering around a
failed attempt.

**This is the second symptom with no public register to read.** The first is the
empty tavern, whose trickle (Decision 32) now carries a named deletion date
pointing at the same unbuilt mechanism. **Two symptoms, one cause, both now
measured.** That is what earns the build.

---

## Part 3 — Two bugs that would have shipped green

**1. The wage paid nothing, at any share.** Grain comes off the furrow one whole
unit at a time and `advance()` runs every frame, so `made` is 0 or 1 on
essentially every call reaching the split. `floor(1 × 0.35) = 0` — **the worker
is paid zero, forever, at any share strictly between 0 and 1**, silently, with a
green probe throughout. Fixed with a fractional carry on the `Obligation`, not on
the station: a different man taking the same plot tomorrow must neither inherit
nor lose it.

**2. `is_discharged()` was a tautology.** It read `received >= received` — a
question that cannot answer no. **A vacuous assertion wearing a function's
clothes**, and every future probe claim about it would have passed for free. See
Decision 34.

**A third version was written and rejected in between, and it is the instructive
one.** `received >= received + carry` reads honest and is a trap: a fraction of a
grain **cannot be paid**, so a payday action gated on it would bid, win, change
nothing, and bid again forever — the standing bid that never resolves, which
Decision 32 already had to shrink a number to work around. **Measuring the gap in
what can actually change hands is what makes it a seam instead of a trap.**

---

## Part 4 — What else moved

**The engine went to Godot 4.7.2-stable-mono.** Verified rather than assumed: the
project parses clean and the probe returns **identical numbers under 4.4 and
4.7.2** — same 14747 checks, same bedtimes to the minute. The bump changed no
behaviour and rewrote no scene. `CLAUDE.md` now points at 4.7.2 and describes the
standing probe instead of a throwaway pump script.

**The probe went 50 → 55 claims, 14747 → 14823 checks.** Five retired for
asserting rules that no longer exist (21, 22, 40, 42, 44), claim 25 re-derived
against the split, twelve added. **Every new claim was watched failing against
deliberately broken code before being kept.**

**The anchor of record**, for every measurement after this one:

```
cold start: turned in 21:14, up 05:52
settled:    turns in 22:10, sleeps 8.00 h, up 06:10
strong man (1.15): up 04:47
```

Unchanged by any of the four gates — which is the evidence they left the sleep
cycle alone.

**A camera rig for the embodied player** landed in `workbench/`: four real defects
fixed — runaway rotation, force applied off the physics tick, yaw about a tilted
axis rolling the horizon, and physics-body jitter. Not playtested; it cannot be,
headlessly, and everything unverifiable is marked as such in the file.

---

## Part 5 — Still open, in the order they will bite

1. **`bite` on a stock gap** (Part 2.1). Unruled. Blocks nothing; distorts
   `MakeBread` now and every future maintenance-shaped want later.
2. **Failure-marks-the-candidate** (Decisions 23/24). Two measured symptoms point
   at it. Also the named deletion date for `change_of_scene_per_hour`.
3. **Whether Gate 0's three authored numbers stand or revert** (Part 0).
4. **`physics/common/physics_interpolation` is not enabled**, so the camera jitter
   fix is not live. **It is global**, and the town's people are moved by direct
   position writes every `_process` tick — interpolation would be reconstructing
   transforms that are already authoritative. `Population` and `Town` want opting
   out before it goes near the game scene.
5. **`project.godot` still declares `config/features=("4.4", ...)`**, and
   `probe.gd`'s header still prints the 4.4 run lines.
6. **CLAUDE.md's `adenosine` rule** says the grep "should return nothing"; it
   returns 15 — 14 comments, and one legitimate *read* in `sleep.gd` scoring
   tiredness. The real invariant is claim 35: adenosine is *written* nowhere
   outside `brain.gd`.
