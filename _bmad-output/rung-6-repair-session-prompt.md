# Rung 6 repair — build the four settled decisions

**Written 2026-08-18, for a fresh session.** Everything here is already decided.
**This session designs nothing.** If you find yourself making a design call,
stop and ask — with one named exception, the share sizing in Step 0, which is
flagged as an author call on purpose.

## Why this exists

Rung 6 shipped and was measured. Two findings are settled as decisions, and two
more rulings came out of the discussion that followed. **The build is small —
roughly one file deleted, one branch added, four lines removed, two numbers
authored — but nothing else on the ladder can be judged until it lands, because
the instrument is currently lying.**

## Read before writing anything

| | |
|---|---|
| `CLAUDE.md` (repo root) | Conventions. Non-negotiable. |
| `proving-scene-build-plan.md` — Rungs 4, 6b, 6c, 6d | The gates being repaired. Read the ⚠ banners; several sections carry superseded text kept deliberately beneath a correction. |
| `proving-scene-decisions.md` — **29, 30, 31, 32** | The four rulings. **Highest number wins**, and 31 narrows 29. |
| `proving-scene-decisions.md` — 15, 23, 28 | The rulings these four narrow or lean on. |
| `rung-6-findings-2026-08-14.md` | **Read its correction banner first.** Two statements in it are false and it says which. |

## Four hard rules

1. **Re-derive every snippet; paste none of them.** Code in the plan and the
   decisions files is illustrative and has drifted from `game/` more than once.
   Open the real file.
2. **Every probe claim must be watched failing.** Break the code deliberately,
   see it go red, put it back. **Eight vacuous assertions have been caught this
   way**, and the most recent pair were found only by break-testing. The
   specific trap: *a claim about a rule with no branch must be asserted in the
   state the missing branch would have changed.*
3. **No new substrate.** No knowledge store, no strategy object, no scheduler,
   no failure-marking mechanism. If something seems to need one, it is out of
   scope — say so and stop.
4. **Nothing in `game/actions/` touches upkeep.** Grep for `adenosine` there; it
   must stay empty.

---

## Step 0 — The sizing check. Do this FIRST, before any code.

**This build fails exactly like the last one if the share is authored wrong**,
and the arithmetic is knowable in advance. Work it out and put it in front of
the author.

Known: `MakeBread` costs **3 grain → 1 bread**; the measured six days show
**~1.7 meals a day**; Hobb worked **~10.6 h/day** at **1 grain/hour**.

```
grain needed per man per day   ≈ 1.7 meals × 3 grain  ≈ 5.1
grain a working man produces   ≈ 10.6 h × 1 grain/h   ≈ 10.6
share needed just to break even ≈ 5.1 / 10.6          ≈ 0.48
```

**So `share_of_crop = 0.25`, the figure used illustratively in Decision 29,
starves both farmers — slower than the quota did, but it starves them.**

Present the sizing and the levers — the share, the bread ratio, the yield per
hour, the meal rate — and **get a call before building. Do not pick one
quietly.** Note for that conversation: a share above ~0.5 means the farm owner
keeps less than half his own crop, which is a fiction question as much as a
number.

**Also unauthored: the larder target** (Decision 31 left it open). It decides
how empty a man's sack must get before baking outbids idling. Size it against
the same table; a few days of bread is the obvious start.

---

## Gate 1 — The public claim register (Decision 30)

**Do this first.** Smallest change, and it is what makes every later measurement
trustworthy.

**What changes:** delete the positional short-circuit from `_is_a_candidate_for`
in **both** `work_the_field.gd` and `sleep.gd`. The check becomes the station's
own answer, asked from wherever the man happens to be standing.

**By hand, in both files.** The duplication is deliberate — `sleep.gd`'s header
says 9b's baker queuing for a millstone is the third consumer that earns pulling
the shape into a common home. **This is not that occasion.**

**Replace the comment block above `_is_a_candidate_for` in `work_the_field.gd`;
do not trim it.** It argues the deleted rule at length. This would be the second
time in this project's history that a comment outlived the code it justified,
and the first one cost a day.

**Untouched:** `Workstation.is_free_for`, `claim()` requiring presence, the
absence of `release()`, travel cost, the telemetry-from-gate exemption.

**Probe — claim 2 must break red against the pre-30 code:**

1. A man **anywhere in town** reads a plot held by somebody else: gate false, and
   his distance to the fields does **not** decrease. He never sets off.
2. **The dither, asserted directly.** A man one tick's walk from a held plot:
   gate false on the arrival tick, the departure tick, **and the tick after**.
3. **At the day boundary the same plot reads free from the same spot**, nobody
   having moved. Expiry is what re-opens the race.
4. **The race survives:** two men who both read a plot free at dawn both set
   off, and whoever arrives first holds it.
5. **Beds:** twenty-one sleepers, twenty beds — the man with no bed **does not
   pace the doorway.** Assert the gate stays false across three consecutive
   ticks while he is near the Inn.

**Retire** rung 4's *"work leaves his ballot ON ARRIVAL"* claim. It asserts the
rule being deleted.

---

## Gate 2 — The wage (Decisions 29 + 31)

**In dependency order:**

1. **`Obligation`** — `owed_item` / `owed_count` become a wage. It grants a
   capability (access to the land) and sets the pay. Add `share_of_crop` and the
   earned-minus-received gap (`get_earned_today()`, `received_today`). **A gap,
   not a strategy object** — share-of-crop settles continuously so the gap stays
   ~0; a payday would leave it open and drive an action. **Do not build payday.**
2. **`WorkStep`** — one branch on ownership. Unowned land → the whole yield to
   the worker's sack. Owned land → to the owning Place's inventory, **via `add`,
   not `hand_over`**, because work CREATES grain; the worker's share likewise via
   `add`. **`is_instance_valid` on the owner first.**
3. **`work_for_hire_step.gd` — DELETE the file.** Not amend. Its per-tick
   delivery leg is what made every grain leave a man's hands the tick it arrived.
4. **`WorkForHire.get_utility_score` keeps its FLAT shape** — `pull +
   daylight_pull * sun`, gated on holding a live obligation. **Decision 31: work
   does NOT score on the larder gap.** It closes that gap one grain an hour and
   would fight itself all day.
5. **The larder gap drives `Eat` and `MakeBread`**, and nothing else yet.

**Probe:**

1. A farmer's work score is **unchanged by what is in his sack.**
2. A farmer whose larder is short chooses `MakeBread` over `StayUp`; with a full
   larder he does not.
3. The crop lands in the **owner's** store and the worker keeps **his share** —
   assert both halves and the total.
4. A man working **unowned** land keeps all of it.
5. A man with no obligation finds the owned plot is **not a candidate.**
6. An expired obligation leaves the candidate set (FR103).
7. **A man holds three grain and bakes.** This has never once happened in this
   project. If it does not fire, Step 0's sizing was wrong.

---

## Gate 3 — The trickle (Decision 32)

`SocialiseStep.change_of_scene_per_hour`: **18 → 6.0.** Update its comment to
say it is a placeholder with a named deletion date — it goes to zero the day
failure-marks-the-candidate lands, and **not before**, because at zero a man
stands in an empty tavern most of the night.

*(That file's stale `base_social_per_hour (4.0)` citation was already corrected
to 2.5 on 2026-08-18.)*

---

## Gate 4 — Measure honestly. This is the point of the session.

**The existing numbers are worthless and must not be re-quoted.** The six-day
pump counted the *name* of a man's current action, and half of every dither
cycle is genuinely named work — which is how nineteen hours of pacing got
reported as labour.

Count **ticks that reached the yield line**, never ticks whose action was named
work. Then run six days and report:

- furrow hours per man, and grain produced per man
- grain in each man's sack, grain in the barn, and **bread baked** (expected
  above zero for the first time)
- whether anybody's hunger pins at the ceiling, and on which day
- action changes per man per day — **expected to collapse for the dawn-race
  loser**, from ~1145 toward Hobb's ~224
- bedtimes, cold-start and settled, against the pre-build anchor

---

## Expected outcomes, including two that look like bugs and are not

- **The loop closes for the first time.** work → grain → bread → eat has never
  fired in this project. That is the headline.
- **Zoogs stops pacing and has an empty day.** He reads the register at dawn,
  sees Hobb has the plot, and does very little. **This is correct and it is the
  point** — rung 5's inequality was never fixed, only camouflaged, and this is
  what makes it visible. **Do not give him a second plot or an errand.**
- **Marle still starves on a full barn.** He owns the land, the crop lands at
  the fields' Place, and he has no work action and no hauling action, so he
  cannot reach it. Decision 29 says explicitly that it does not fix this;
  selling from the barn is rung 7's. **Do not give him an action.**

## Out of scope — name it and stop

Failure-marks-the-candidate; payday as an event; coin, prices, affordability; a
hauling action for Marle; a second plot; trade; a knowledge store; merging the
two candidate checks; the standing-want pricing rule (still unruled).

## Model routing

Fable orchestrates and verifies each gate; Sonnet builds against re-derived
delta sheets. The `.tscn` authoring and the Step 0 sizing conversation stay with
Fable.
