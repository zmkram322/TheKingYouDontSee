# Rung 6a — session prompt

Copy everything below the line into a fresh session.

**Written 2026-08-11, the day rung 5 closed. REWRITTEN 2026-08-12 against
Decisions 19–27.** The first version carried **four open calls** to be settled
with the author at the top of the session. **All four are now settled and written
into `proving-scene-decisions.md`.** Nothing below is a question any more; where
this document and an older one disagree, the decisions file wins and the highest
decision number wins within it.

**This rung is NOT routed to Fable** (Fable is for 6b, 6d, 7 and 8). So this
prompt spells the corrected shapes out rather than saying *"re-derive this"*.
**Nothing below is optional detail.**

---

Build **rung 6a** of the proving-scene ladder. One rung, then stop at the gate.

## WHAT WAS SETTLED, SO YOU DO NOT RE-DERIVE IT

Read `_bmad-output/proving-scene-decisions.md` **19 through 27** before anything
else. They were worked out from first principles rather than reverse-engineered
from scenes, and they are the reason this rung is smaller than it used to be.

**The five that change what you type:**

- **19 — every want is a gap** (should-be minus is). Hunger and Decision 1's
  `target − stock` are one rule. It also names what `WorkTheField.pull = 73` and
  `StayUp.pull = 67.3` really are: **placeholders for gaps not yet built.**
- **20 — `want = weight × gap ^ bite`.** It reproduces all four shipped actions
  exactly, so it is a way of reading them, not a rewrite. **`Eat` is the first
  want in the game with both parts live.**
- **22 — gates ask the world, never how much he wants it.** This corrects the
  first version of this prompt, which specified `Eat.is_available_to` as *hungry
  AND has bread*. **The hunger half is wrong and must not be written.**
- **23 — one tick, one loaf**, and why: failure marks the candidate, success
  marks the world, and an action that changes nothing in the world twitches.
- **25, 26, 27 — what this rung actually contains.** 25 takes `social` and the
  tavern out. 26 settles where bread comes from. 27 settles the numbers and rules
  out a lens on work.

**And two that will save you an argument with yourself:**

- **21 — the baseline is a personality.** `StayUp` becomes `Leisure` at a later
  rung. **Not here.** Tune hunger against the shipped `StayUp` and know the
  baseline is going to change shape afterwards.
- **24 — unmet need is recorded where it failed.** Nothing this rung.

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
things his *body* wanted.

## READ FIRST, IN THIS ORDER

1. **`CLAUDE.md`** (repo root) — naming rules, design rules, Godot traps.
   Governs. Note the goods rule added at rung 5: **`add` creates, `take`
   destroys, `hand_over` moves**, and `Eat` is the first consumer in the game.
2. **`_bmad-output/proving-scene-decisions.md`** — there are **TWENTY-SEVEN**
   decisions. **19–27 in full** (above). Then **1** (where want comes from),
   **11** (the sleep cycle hangs on the sun), **5** (every rate is per world
   hour), and **3** — which now carries a banner pointing at 25. **Where two
   decisions disagree the HIGHEST NUMBER WINS.**
3. **`_bmad-output/proving-scene-build-plan.md`** — the "Rung 6a" section, which
   was revised 2026-08-12 and carries the settled version, plus the rung 5
   section above it. Glance at **6a2** immediately after, which is the next gate
   and is NOT yours.
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
20541fc           the first version of this prompt, and the index trap disproved
842c6cf           decisions 19-24 — the utility model
4226503           decisions 25-27 — what this rung actually lands
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

**REGRESSION BASELINE — all of this must still be true when you are done:**

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

Read in Decision 20's terms, every one of those is `weight × gap^bite` with one
part switched off: `StayUp` and `WorkTheField` have `gap = 1`, `Sleep` is
`weight 100 × (adenosine/100) ^ 1`.

**The three crossings that produce the shipped day:**

- **~20:45** — work falls under `StayUp` and hands the evening back.
- **22:01** — adenosine (~50) crosses `StayUp` (**50.0 at 22:00**) and he turns
  in. **This is bedtime.**
- **04:41 / 06:01** — adenosine falls under `Wake`'s flat 10 and he gets up;
  work is worth 62.8 there against `StayUp`'s 60.5, so he goes straight to the
  field.

`Brain` for reference: `base_adenosine_per_hour = 2.5` awake,
`base_adenosine_cleared_per_hour = 5.0` asleep (× `strength`), ceiling 100.

## THE JOB

Four things, and nothing else.

### 1. `hunger` in `game/stats.gd`

A stat like `adenosine`, with the same kind of comment explaining what it means
and why the number is what it is. **0–100, where 100 means "as hungry as a person
gets", NOT "dead"** — exactly as 100 adenosine is not death by sleep deprivation.
Say that in the comment, because reading a felt gap as a lethal one is the
mistake Decision 27 was written to stop. **Starving is a second, slower gap and
is NOT built here.**

### 2. `Brain._update_body` gains one line

Hunger rises per world hour. **UPKEEP, never inside an action**, per `CLAUDE.md`'s
load-bearing rule: put it in `Eat` and the next action you write silently doesn't
have it. Grep `game/actions/` for `adenosine`; it should return nothing, and the
same should become true of hunger everywhere except `Eat` itself.

Give it the same **`get_…()` seam treatment** the two adenosine rates have
(`get_adenosine_accumulation` / `get_adenosine_recovery`), because illness, cold,
a hard day's work and a growing boy all land there later — and because a rate you
can plot is a rate you can tune.

> **`base_hunger_per_hour = 4.0`, awake and asleep alike. One line, no branch.**

The lack of a branch is deliberate and it is why he wakes up hungry.

### 3. `game/actions/eat.{gd,tscn}`

`Eat` (Action) + its step. **In `person.tscn`, so every person has it by
composition** — FR86's protected categories are present by construction and can
only be outbid, never pruned. **It takes bread from his OWN inventory**
(`person.get_inventory()`). No transfer, no place, no owner, no trade.

**The gate — and read this twice, because the first version of this prompt got
it wrong:**

> **Gate on being AWAKE and HAVING BREAD. Never on hunger.**

*"Not hungry enough"* is want, not possibility, and putting it in a gate is
barring in a new coat — the same mistake `stay_up.gd`'s header already warns
about in its own case. A man at hunger 5 loses to `StayUp`'s 47.3 without any
help. Leaving it out also means `Eat`'s line is drawn **rising and losing all
day** rather than as a gap, which is better instrumentation for a rung whose
Moment is a graph.

**The `is_awake` half is required.** `StayUp` and `WorkTheField` both gate on
`person.brain.is_awake()` and both document why. A man whose hunger crosses at
03:00 will get up and eat in the dark if you forget, and it will present as a
broken sleep cycle. Note that `Sleep` itself does **not** gate on being awake,
deliberately; `Wake` gates on being asleep. Read all four before writing the
fifth.

**The step:**

> **One tick, one loaf.** `take(&"bread", 1)`, and hunger drops by an authored
> amount, in a single tick.

No fraction anywhere, no remainder to store. A timed meal would need somewhere to
hold the meal-in-progress, and that is the identical missing thing as the
fractional loaf's home — one absence, two symptoms (Decision 23). It also makes
`Eat` a natural **spike**, which is what keeps bedtime still.

**The score — non-linear, and this is not optional:**

> `weight × (hunger / 100) ^ bite`

Two authored numbers, both plain English:

- **what starving is worth** — the `weight`. This is the one that decides whether
  a meal can ever interrupt work. **It must clear 103 if it ever should.**
- **how sharply it bites** — the exponent. This is what makes *a bit hungry* mean
  *keep working*.

**A straight line gives exactly the wrong day and it is arithmetic, not
opinion:** a 100-ceiling stat scored linearly can never reach work's 103, so a
meal could never interrupt work at any hunger — while half-empty at 22:00 scores
50 and beats `StayUp`'s 50.0, so he would nibble every evening and never eat by
day.

**A loaf fixes 50.** With `base_hunger_per_hour = 4.0` that is **two meals a
day**, and that cadence is forced by conservation — `meals/day = 24 × rate ÷
loaf` — so **`bite` does not change how often he eats.** It changes *when*, and
therefore what he is willing to interrupt. A higher `bite` makes him more stoic,
not more prompt.

**Two things hunger may NOT do** (Decision 27):

- **It may not touch another action's weight.** A damper on work was proposed and
  rejected: hunger drives some men to work harder, so the direction is not
  universal, which makes it personality rather than a lens.
- **It may not enter `WorkStep.get_yield_per_hour()`.** That seam **stays
  empty**. *Starving* will land there when it exists; hunger does not.

### 4. `Workstation.owner`

One `@export var owner: Person`, may be null, **with no reader at all this
rung.** Unowned land is the king's, which is the same answer as nobody's. 6b adds
`is_permitted_to()` that reads it; do not write that here.

### And the bread

> **Fourteen loaves each, authored on Zoogs and Hobb in `game.tscn`. NOT on
> `person.tscn`.**

`person.tscn` is the template of a **body**, not of a life: stats belong there,
possessions do not, and a newly created person owning nothing is the honest
default. It also matches how rung 5 authored the Fields', the Inn's and the
Plot's inventories. Fourteen is about a week at the cadence above, which is what
makes the cold start easy.

**Consequence you must handle:** the probe's spare people start with empty bags.
The *"a man with no bread cannot eat"* claim must still **empty a bag
explicitly** rather than lean on that. Rung 4 paid for this lesson twice — a
check states the world it wants instead of inheriting one, which is what
`_stand_at` exists for.

## ⚠ THE TRAPS

**THE INDEX TRAP IS DEAD. MEASURED 2026-08-11 — DO NOT TIPTOE AROUND IT.** Both
of its forms were tested directly and both are false:

- A node inserted **before `Stats`** (making Stats index 4) — **Hobb still reads
  1.15.** A property override on an existing child resolves by **name**; the
  index is a positioning hint.
- **A node added to `person.tscn`'s Brain**, which is the case this rung hits —
  Brain came out `StayUp, Sleep, Wake, WorkTheField, Eat` and **all 30 claims
  stayed green.**

**Author `Eat` wherever it reads best.** The one real consequence of ordering:
`DecisionEngine.get_highest_scoring` breaks **exact ties** by *"whichever came
first"*, so Brain child order decides only between two actions scoring
**identically**.

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

## THE GATE

**Probe, then Moment. All thirty existing claims stay green. New claims start
at 31.**

1. **Hunger rises for a man doing nothing at all** — it is upkeep, so it must
   move for somebody whose current action is `StayUp`, and it must move by
   exactly one hour's worth in one hour. **Assert the amount, not the direction.**
2. **Eating drops hunger, and consumes exactly one loaf.** Both halves: the stat
   fell *and* the count went down by one, so "he ate" cannot be satisfied by a
   step that changes hunger for free.
3. **A man with no bread cannot eat** — `Eat` is off his ballot entirely (NAN in
   `get_last_scores`, the same off-the-ballot shape claims 13 and 21 already
   use), not merely outscored. And having no bread must not stop hunger rising.
   **Empty the bag explicitly; do not rely on a spare starting empty.**
4. **Hunger never goes negative**, however much he eats.
5. **`adenosine` is written from nowhere outside `brain.gd`** — a **text scan**,
   in the shape `SceneWiring` already establishes, over every `.gd` in `game/`.
   This is the mechanical form of the upkeep-vs-effects rule and it is the claim
   that stops the farmhand-who-never-tires bug from ever being written.
   **Deliberately NOT extended to hunger:** `Eat` **must** write hunger, that is
   an effect, and the design permits it.
6. **`Eat` is on every person by composition** — instance `person.tscn` fresh,
   with nothing authored, and assert the newcomer knows it. That is FR86's
   guarantee made mechanical.

**Moment — accepted as it unfolds, not staged.** **TWO** drives on one graph and
you watch which wins: the first time the sleep cycle has a competitor that is not
a flat number. **Watch it at a SHORTENED day** — this is a once-a-day beat
repeating, so Decision 13's instrument applies (rung 4's long day is the opposite
case and does not apply here).

**What the numbers are predicted to produce**, so the Moment is a prediction to
check and never a target to engineer:

- **Two meals a day**, one in the late morning that genuinely interrupts work,
  one in the evening gap after work falls and before sleep wins.
- Meals land in the **valleys of the waking ladder**, because that is the
  cheapest hour on it. Supper is emergent, not authored.
- **Bedtime does not move.** `Eat` can hold the top waking bid for exactly the
  one tick it takes to eat, so 22:01 shifts by at most 0.01 world hours.

If what actually happens differs, **that is information, not a failure** — ask
the author whether what happens is sufficient before tuning toward the
prediction. Rung 4 paid for that lesson: a Moment is a prediction about what the
causes produce, not a spec to satisfy.

**Two instrument notes, both learned at rung 5:**

- `stat_graph` has **`top_of_scale`** (0.0 = fit to the data). Grain already
  passes adenosine's 47 inside a working day and reaches 94 by day 5, so the stat
  panels are **already crowded before hunger arrives**. Pinning the two stat
  panels is one number in the inspector and is probably the first thing you do
  when you sit down to watch this.
- Items and stats both list by reflection, so `hunger` appears on both readouts
  and both graphs, and bread appears over every head, **with no line written for
  either.** If it does not appear, something is wrong with the stat's export
  usage flags, not with the panel.

## DO NOT BUILD

**`MakeBread` — that is 6a2, the very next gate**, and this rung's bread is
authored and will not run out inside a probe run. **`social`, `Socialise`, the
tavern, `Town.find_people_at` being consumed, the distance damper — 6d**
(Decision 25 moved them there; Decision 3 carries a banner saying so).
**`Leisure`, or renaming `StayUp` — a later rung** (Decision 21). **Starving, and
anything that reads it** (Decision 27). `Drink`, beer, or buying anything —
**rung 7**. `Obligation`, `WorkForHire`, quotas, discharge, `is_permitted_to()` —
**6b** (`owner` ships as a field with no reader; that is the whole of it). Beds,
and `Sleep` gaining a place requirement — **6c**. A hunger *quota* or any attempt
to unify hunger with Decision 1's `target − stock` — Decision 19 says they are
the same rule, but closing that is not this rung's job. Cooking, recipes, food
that spoils, an item database, weight, carry capacity. `release()` on
`Workstation` — still no caller, still deliberately absent.

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
  way `probe.gd` does.
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

**Good candidates:** the `adenosine`-is-only-written-in-`brain.gd` text scan (a
pure function over file text with an exact expected answer, and it mirrors
`scene_wiring.gd` closely enough to hand over with the existing file as the
model). And a six-day measurement run reporting the schedule, who claimed the
plot when, each man's grain at each dusk **and how many times each man ate** —
hand over the regression table above and have it report HOLDS/DEVIATES per line.

**Do NOT delegate:** the curve tuning, or the decision about whether a red claim
13 is a tuning problem or a claim problem.

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
- **The sleep cycle has not moved** — Zoogs 22:01 / 8.00 h / 06:01, Hobb 04:41.
  "It moved and I am not sure why" is a failed gate.
- **Hobb still takes the plot every day and Zoogs still never does.**
- **A man eats.** Say how often, at what hours, and whether a meal ever
  interrupted work — that is the rung's actual content and a green probe does not
  show it.
- Report the probe output, then **STOP**. Do not begin 6a2.

## STANDING HAZARDS

- **Treat every code snippet in `proving-scene-decisions.md` AND in the build plan
  as intent to be re-derived, not code to paste.** Five have been wrong so far and
  only the probe caught them. **Decision 25 is the case where a settled
  decision's PROSE was wrong rather than its code** — the same scepticism applies
  to reasoning, not only to snippets.
- **The worked numbers in Decision 20 (weight 130, bite 3) are ILLUSTRATIVE.**
  They are a check that the shape behaves. The tuning is the author's, at the
  keyboard, on the board.
- **Watch for assertions that cannot fail.** This is the ladder's most reliable
  source of wasted work.
- **When this rung ships, grep the UNBUILT rungs for what it changed.** Rung 4
  moved a seam under 5, 6a, 6d and 7; rung 5 landed 9a's `Workstation.progress`
  four rungs early as `output_part_made`. That is now part of the ritual, and 6a
  introduces `hunger`, which 6a2, 6b, 6d, 7 and 9b all sit downstream of — and
  `Workstation.owner`, whose first reader is 6b.
- **The working tree on `poc-v2` is clean** except for a `[display]` block in
  `project.godot` (window maximized, so the UI stops dominating a 2K screen),
  which was left uncommitted for the author to try. Anything else uncommitted you
  find is yours.
