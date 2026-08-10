# Proving Scene — Build Plan

**Status:** written 2026-08-08, not started.
**Target:** the east-side town, built rung by rung, ending on a merchant with a
stack of unsold scythes.
**Orchestrated by:** Fable, one rung at a time.  **Fable plans then delegate to cheaper models.**


---

## What this is

A ladder. Each rung is a small, shippable change to `tkyds-game/game/` that
forces **one seam** into existence by putting a real collision in front of it,
rather than laying pipe against a guess.

Every rung carries four things, and a rung isn't done until it has all four:

| | |
|---|---|
| **Seam** | the one narrow waist this rung exists to install |
| **Files** | what gets created or touched |
| **Probe** | the assertion that pins it, added to the standing harness |
| **Moment** | what you should be able to sit and *watch* when it works |

The **Probe + Moment pair is the review gate.** Green probe and a moment that
reads right means the seams were correct — that's the only evidence that
actually proves it. If either fails, we read code. Roughly nine review points
across the whole arc instead of a hundred.

From rung 3 onward the gate has a third element: **the standing check** (see
*Don't script the simulation*). A rung can pass its probe and produce its moment
and still be wrong, if it got there by scripting.

### How Fable should run this

- **One rung per session.** Do not run ahead. A rung that lands two seams has
  destroyed the evidence that either was needed.
- **The probe is written in the same session as the code**, not after.
- **Stop at the gate.** Report the probe output and describe the moment. Do not
  begin the next rung.
- **"What NOT to build" is binding.** Each rung names the tempting adjacent
  system. Building it is the failure mode this plan exists to prevent.
- **When delegating, pass the whole rung plus *Don't script the simulation* and
  *This extends `game/`*.** A delegate who only receives the rung will produce a
  working town that is a script with thirteen entries — the shorter diff is
  always the scripted one, and it always looks like it works.
- Read `CLAUDE.md` first. Its naming rules and design rules govern; where this
  document and `CLAUDE.md` disagree, `CLAUDE.md` wins and this file is wrong.

---

## This extends `game/`. It does not sit beside it.

Every rung **adds to the substrate already in `tkyds-game/game/`** — the same
`Person`, `Stats`, `Brain`, `Action`, `ActionStep`, `DecisionEngine`, `Clock`
and `Daylight` that already run a Zoog through a sleep cycle. Nothing here is a
new engine, a parallel actor model, or a second way to make a decision.

Concretely, what each rung hangs off:

| Rung adds | Hangs off | How |
|---|---|---|
| `Population` | `Person._process` | takes over a call that already exists (`person.gd:38-42` anticipates it in a comment) |
| `Place`, `Town` | `Person` | a new question a person can be asked |
| `WorkTheField`, `Trade`, `HireHauler`, … | `Action` / `ActionStep` | new action scenes in `game/actions/`, learned the same way `Sleep` is |
| `Workstation` | `ActionStep` | something a step works at; the step still holds no progress |
| `Inventory` | `Person`, `Place` | a sibling Node to `Stats`, same accessor discipline |
| `Obligation` | `Brain`'s candidate pull | reaches the ballot through an ordinary Action |
| the whole town | `person.tscn` | thirteen instances of the scene that already exists |

**A new profession is never a new class.** `Person` already says it: *"Zoogs is
not a special class, he is this scene with a name typed into it."* A miller is
`person.tscn` with a `Miller`-ish set of Action scenes under his Brain and his
own starting stats. There is no `Miller` type, and rung 9 adds five professions
without adding five classes.

**`tkyds-game/` is now `game/` and `assets/` and nothing else.** The earlier
studies — `board/`, `town/`, `sandbox/`, `sim/`, `behavior/`, `tests/` and the
old `main.tscn` — were **deleted 2026-08-08** rather than left to rot, because
`class_name` is project-global and they were squatting on 23 good names. They
are in git history; port an idea by hand if you want one, never wire to it.
`project.godot`'s main scene now points at `res://game/game.tscn`.

**`class_name` audit, re-run after the deletion — everything this plan needs is
free:** `Town`, `Place`, `Population`, `Inventory`, `Recipe`, `Workstation`,
`Obligation`, and also `Linger` if a floor action is ever wanted. Freed by the
same deletion and now available for later rungs: **`Goal`** and **`Demand`**
(both words the PRD uses constantly and both previously unavailable), plus
`Actor`, `State`, `Wait`, `Simulation`, `Villager`, `TownMap`, `Hex`, `HexMap`,
`Orchestrator`, `UtilityBrain`, `Stat`, `Tune`.

Godot's registry was rebuilt and verified: the only registered classes are the
fifteen in `game/`.

---

## Don't script the simulation

**The systems interact through the seams. Nothing orchestrates them.**

This is the rule most likely to be broken by an implementer who wasn't in the
design conversations, because the scripted version is always the shorter diff
and always looks like it works. It is written here to be enforceable without
that context.

### The three authoring surfaces

A human writes intent in exactly three places. There is no fourth.

1. **What a person knows** — which Action scenes sit under his Brain.
2. **Who he is** — his starting stats and the exported tuning numbers on his
   actions and steps.
3. **What the world contains** — places, workstations, items, and the
   obligations somebody issued.

Everything else *falls out of scoring.* If a behaviour you want cannot be
produced by moving something in those three surfaces, that is the finding —
report it, don't reach for a fourth surface. It usually means a utility curve is
wrong or an action is missing, and both of those are one-line fixes that leave
the simulation intact.

### Banned shapes

| Don't | Because |
|---|---|
| A class, file, function, or branch **named for a profession** | Directly extends prd.md:468 — *"No class, function, branch, or file may name a playstyle"* — same rule, same reason. Role is composition. |
| `if person.person_name == "…"` — any branch on identity | The twelfth farmer must behave like the first without being mentioned anywhere. |
| A manager that walks people and tells them what to do | `Population` dispatches *thinking*. It never decides. The moment it decides, the Brain is decoration. |
| A timetable — "at 08:00 the farmers go to the field" | The day's shape comes from adenosine, daylight scaling work utility, and the quota's weight running out. Dusk is a *consequence*, not a trigger. |
| Hardcoded trade partners | The farm owner sells to the miller because `find_candidates()` found him standing in the square, not because a line says he does. |
| A workstation that advances itself | Nothing in the town produces anything unless a person chose to work it. Production is an effect of a decision, never an ambient world tick. |
| A step that reaches past its own person to move somebody else | Two brains, one puppeteer. |
| An `if` standing in for a decision | The rung-8 hauling fallback is the canonical case: two competing Actions, never one action that checks and branches. |

**The one thing that is not scripting:** authored constants. Tuning numbers,
recipe contents, quota sizes, and starting inventories are *data*, and data is
surface #2 and #3 doing their job. The line is simple — **a number is
authoring; a branch on who you are is a script.**

### The standing check — run at every gate

Three questions, at every rung from 3 onward. They take a minute and they are
falsifiable, which the doctrine above is not.

1. **Delete a person mid-run.** Does the town carry on? Nothing may hold a hard
   reference to a named individual.
2. **Add a fourteenth.** Does he participate immediately — scene, actions,
   stats, no new code? If he needs a line written for him, the town is a script
   with thirteen entries.
3. **Move a place in the editor.** Does behaviour change without an edit?
   Geography must be *read*, never assumed.

Any "no" means something got scripted. Find it before the next rung, because
each rung builds on the one below and a scripted seam holds no water.

---

## Source documents

| Document | What it governs |
|---|---|
| `CLAUDE.md` (repo root) | Naming, the load-bearing design rules, Godot traps, how to verify. Authoritative. |
| `_bmad-output/planning-artifacts/prd.md` | The requirements contract. FR numbers are stable identifiers, append-only. |
| `_bmad-output/roundtable-brief-2026-08-08.html` | The seven-round design settlement this plan implements. Also live at `https://claude.ai/code/artifact/09ba7127-337b-4ca8-8346-fb675d403ea1` |

---

## The proving scene

### Places

| Place | Where | Workstations |
|---|---|---|
| **Lord's Inn** | east | 20 beds, individually claimed. Free to sleep. |
| **Market Square** | centre, west of the Inn | 5 merchant stalls. The only place trade happens. |
| **Grain fields** | west | 4 plots, one worker per plot |
| **Mill** | south of the square | 1 millstone |
| **Townswood** | east of the square, south of the Inn | trees |
| **Smithy** | south-west of the square | 1 anvil, 1 forge |
| **Tavern** | north of the Inn, east of the fields | 1 oven, 1 bar, storage |

Geography is load-bearing, not decoration: the square sits between the fields
and everything else, so most of the town crosses it twice a day. That is where
people incidentally see each other, and seeing each other is the substrate the
whole game is eventually built on. Preserve the relative layout.

### People (13)

Tavern owner · baker · brewer · wood chopper · 2 merchants · farm owner ·
4 farmers · blacksmith · miller

### The chains

```
grain fields ──> farmer ──quota──> farm owner ──sells──> miller ──> flour
                                              └──sells──> merchant
mill (flour) ─────sells──> tavern owner ──> baker  ──> bread ──> tavern storage
grain ────────────sells──> tavern owner ──> brewer ──> beer  ──> tavern storage
tavern owner serves bread + beer to whoever comes in

townswood ──> wood chopper ──> logs ──> sticks ──sells──> merchant ─┐
(off-map) ──> merchant ──imports──> iron ore ──sells──> blacksmith │
                                    blacksmith ──> iron plates ────┤
                                                                   ▼
                                             merchant ──> SCYTHES ──> unsold
```

### The day shape

A farmer works his plot until his **quota** is met, at which point the utility
of working collapses. He wants company, so he walks to the tavern, buys beer
(replenishing a social stat) and bread if he's hungry, then walks to the Inn and
sleeps on a bed. The miller and the smith run the same shape against their own
production targets, and both pass through the market square to trade.

### Where the arc ends

The merchant assembles scythes from sticks and iron plates and they **sit in his
inventory, unsold.** This is not an unfinished economy — it is the hook. Nothing
stops a farmer from buying one except that *"buy a scythe" is not a verb any
farmer knows.* Money is plentiful; ignorance is the constraint. That leaves the
town's most valuable object sitting in the square beside a man with an unmet
driver, which is the exact shape FR38 and FR32 want a player to walk into.

**Do not fix it. Ship it as the ending.**

---

## Author's decisions already made — do not reopen

- **Iron ore is imported** by a merchant and sold on to the blacksmith. The
  merchant is the town's only channel to the outside world.  don't write an import system, when we instantiate the ore merchant just start him with a lot of ore in his inventory to sell.
- **Money exists and everyone is flush.** Affordability is deliberately not a
  constraint yet. Ship `can_afford()` returning true so the call site exists.
- **Scythes are made and left unsold.** Whether the player buys one and gifts it
  to a farmer is a later decision, deliberately deferred.
- **Wagons are given to whoever needs to haul.** Hauling contractors and
  logistics come later; for now a man who finds no hauler available hauls it
  himself.
- **`Population` ships as a fifteen-line loop over one list.** The narrow waist,
  not the scheduler.
- **The version stamp on `set_stat` is cut** from this arc. Nothing derives,
  nothing caches, nothing sleeps on a stat change. Revisit when something does.
- **A man with nothing to do goes where the people are** (decided 2026-08-08) —
  in practice the market square or the tavern. He does not stand in an empty
  field. **Build the cause, never the observation:** there is no `Idle` action
  naming two places. There is `Socialise`, scored off the `social` stat, whose
  candidates are places that currently have people in them. The square and the
  tavern win because that is where people are. Name them in the action and the
  town stops working the day you add an eighth place.
- **Location is a discrete fact, not a distance check** (decided 2026-08-08,
  reverting the earlier physics override). A person *has* a place; walking sets
  it on arrival. This restores prd.md:470 and FR85, and it buys a free, exact
  **arrival event** with no threshold at the edge of a circle and no flicker.
  Rungs 3 and 7 both ask "same place?" every tick and both want a crisp answer.

---

## The seam ledger

What this arc installs, and what it deliberately refuses.

### Installed

| Seam | Shape | Rung |
|---|---|---|
| Decision dispatch | `Population.think_for_everyone(delta)` | 1 |
| Named place | `Person.get_current_place() -> Place` | 2 |
| Labour clearing | `Workstation.claim(person) -> bool` | 3 |
| Candidate pull | `Town.find_workstations(person, work_name) -> Array[Workstation]` | 3 |
| Idleness diagnosis | two counters on `Town` | 3 |
| Carried goods | `Inventory.get_count(item_name) -> int` | 5 |
| Assigned intent | `Obligation` node under a Person | 6 |
| Who benefits | `Workstation.owner` / `Place.owner` — may be nobody, may be somebody with no body | 6 |
| Exchange | `Trade` action + `can_afford(person, price) -> bool` | 7 |
| Capability from an object | `is_available_to` reading `Inventory` | 8 |
| Work that takes time | `Workstation.progress`, world state | 9 |

### Refused, with reason

| Not building | Why |
|---|---|
| Version stamp on `set_stat` | A cache for a cache that doesn't exist. Cut unanimously. Adding it later touches one file. |
| Stagger / budget / LOD / replay | Four solutions to a fifty-person problem. The `Population` loop is the seam; the scheduler is water. FR73 installs here later without a call-site change. |
| A hauling profession | The point of rung 8 is that hiring finds *zero* candidates. |
| Prices, wages, affordability | FR60 says output is leverage, never wealth. Money is plumbing here, not a system. |
| Spoilage | Turns storage into a decision. Real, but not needed to reach scythes. |
| Item-modifies-a-rate | The scythe's productivity effect waits for a buyer. Rung 8 builds only *item gates an action*. |
| A decision log | O(actors × elapsed time) — the only unbounded complexity class in the design. Reputation is one number written at discharge. |

---

## Two doctrine calls Fable must not re-make

These both look like violations of `CLAUDE.md`'s "store nothing you can work out
again." They are not, and the distinction is the same one in both cases.

**1. `Workstation` stores who holds it.** The rule forbids storing a *person's
progress or plan*. It does not forbid world state. Who is standing at the
millstone is not regenerable from anybody's stats — it is a fact about the
millstone. FR101 is the exact test: *regenerability, not persistence.*

The claim is a **per-tick lease**, not a booking. Each tick the working step
calls `claim(person)` again; `Population` releases every station nobody renewed
at the end of the tick. So it re-derives every frame like everything else, and
one-secures-it comes for free: the holder renews before a rival can take it,
so there is no flicker and no split-yield.

**2. `Workstation` stores production progress.** Grinding a sack of grain takes
time. That time lives on **the millstone, not the miller** — which is the
roundtable's rule that a completion condition belongs to the job, not to a flag
on anybody. Two consequences fall out for free and both are correct: interrupting
a miller costs nothing, and a second miller who takes over the stone continues
from where the first one left it.

If a rung ever wants to put either of these on a `Person`, that's the violation.
On the world object, it's the design.

---

## Interpretation note: how FR100 obligations reach the ballot

FR100 says an obligation "enters that actor's candidate set as a peer action."
FR101 permits storing it, because no stat regenerates it. The roundtable
separately ruled that obligations must **not** go through `Brain.learn()` /
`forget()` — capability is a property of the person, an obligation is intent
between two parties, and collapsing them makes `forget()` mean both "he lost the
skill" and "he walked off the job."

So the shape is:

- An **`Obligation`** is a Node under the Person. Stored intent (FR101).
- A standing **`WorkForHire`** Action sits in the farmer's repertoire like any
  other. Its `find_candidates()` returns his workable obligations; zero
  candidates means `is_available_to` returns false. That reuses the rung-3
  candidate-pull seam rather than inventing a parallel path.
- Its utility comes through **one function** supplying FR102's weight. Today it
  returns an authored constant. When channels exist, that function's body
  changes and no call site moves — which is what FR102 asks for by name.
- **Quitting is an Action he scores**, never a bookkeeping call. Otherwise
  walking off a job is invisible and cannot be outbid, which is the single most
  dramatic worker beat in the town.

---

## How the town assembles

The rungs are deliberately narrow — rung 3 is *two farmers and one plot*, not
the fields — because a seam proves itself against the smallest collision that
can break it. The full town arrives at rung 9, and by then it should cost
almost nothing, because every mechanism it needs already exists.

| Rung | Places in the scene | People | What's new |
|---|---|---|---|
| 0 | — | Zoogs | harness only, no game change |
| 1 | — | Zoogs | dispatch moves to `Population` |
| 2 | grain fields, Lord's Inn | Zoogs | a person has a place |
| 3 | fields with **1 plot** | 2 farmers | contention |
| 4 | same | 2 farmers | walking, arriving |
| 5 | same | 2 farmers | grain in hand |
| 6 | + tavern (bar, storage), Inn's **20 beds** | + farm owner | the whole day |
| 7 | + market square, mill | + miller, 1 merchant | trade, serving |
| 8 | same | same | wagons, hiring nobody |
| 9 | + townswood, smithy, tavern oven, **4 plots**, 5 stalls | + tavern owner, baker, brewer, wood chopper, blacksmith, 2nd merchant, 2 more farmers = **13** | the chain |

## Coverage map

Every element of the authored scene, and where it lands. If something you said
isn't in this table, it isn't in the plan — that's the point of the table.

| From the spec | Rung |
|---|---|
| Lord's Inn, free to sleep | 2 |
| 20 **individual** beds, one sleeper each | 6 — beds are `Workstation`s using rung 3's `claim()` |
| Grain fields, one worker per plot | 3 (one plot) → 9 (four) |
| Market square is the only place trade happens | 7 |
| 5 merchant stalls | 9 |
| Mill, millstone | 7 (place) → 9 (grain → flour) |
| Townswood, trees | 9 |
| Smithy, anvil + forge | 9 |
| Tavern: bar + storage | 6 |
| Tavern: oven | 9 |
| Farmer's quota, set by the farm owner as part of his contract | 6 |
| Quota met → work utility drops precipitously | 6 |
| Urge to socialise → walks to the tavern → beer | 6 |
| Beer replenishes a social stat | 6 |
| **Eats bread if hungry** | 6 (hunger stat + `Eat`, bread authored into storage) → 9 (baker actually bakes it) |
| Then tired enough → Lord's Inn → sleeps on a bed | 6 |
| Farmer hands his quota to the farm owner | 6 (discharge) |
| Farm owner sells to the miller **or** a merchant willing to buy | 7 |
| Miller grinds bought grain into flour | 9 |
| Tavern owner buys both grain and flour | 9 |
| Baker and brewer are **in his employ** | 9 (an obligation, reusing rung 6 — not a new relationship type) |
| Baker → bread → storage; brewer → beer → storage | 9 |
| **Tavern owner acts as the server** when people request beer and bread | 7 — this is `Trade`, not a service system. See the rung. |
| Wood chopper: trees → logs → sticks → sells to a merchant | 9 |
| Blacksmith: iron ore → iron plates at the anvil → sells to the same merchant | 9 |
| Merchant: sticks + plates → **scythes** → tries to sell at market | 9 (they don't sell — that's the ending) |
| Merchant imports iron ore and sells it on to the blacksmith | 9 |
| Miller and smith drink at night against their own production targets | 9 |
| "If you've got something to trade you have to go there" | 7 (presence is the gate) |
| Money, everybody flush, no affordability | 7 |
| **People with nothing to do hang in the square or chill at the tavern** | 6 — an *outcome* of `Socialise`, never an authored destination |
| Wagons given to whoever hauls | 8 |
| No hauler available → he hauls it himself | 8 |

**Deferred past this arc, on purpose:** transporters and logistics suppliers;
the player; buying and gifting a scythe; affordability and prices; the scythe's
actual productivity effect; spoilage; wages.

---

## The rungs

### Rung 0 — Standing verification

**Nothing new in the game. This gates everything below it.**

There are currently no tests for `game/`, and verification is throwaway scripts
that get deleted. A silent null guard already shipped a dead day/night cycle
through two commits, so "it runs without errors" has been demonstrated to mean
nothing here. Build the pipes only once something checks they hold water.

- **Files:** `game/probe.gd` (a `SceneTree`), `game/probes/` for per-rung checks.
- **Shape:** instance a scene, pump `person.think_and_act(fixed_delta)` N ticks,
  assert, print `PASS` / `FAIL`, exit non-zero on failure. Ten lines, not a
  framework.
- **Run:** `Godot_v4.4-stable_mono_win64_console.exe --headless --path . --script game/probe.gd`

**First assertions, against the Zoog that already exists:**

1. Over 24 simulated hours he sleeps at least once and wakes at least once.
2. Adenosine rises monotonically while awake and falls while asleep.
3. When `Sleep.is_available_to` is false, `Sleep` is never the chosen action.
4. **Every required `@export` node reference is non-null after `_ready`** — the
   `node_paths` trap, caught mechanically, forever.

**Moment:** none. This is the only rung without one, which is why it's rung 0
rather than rung 1.

**Do not build:** a test framework, fixtures, mocks, or a runner. One file.

---

### Rung 1 — `Population` owns who thinks

**Seam:** `Population.think_for_everyone(delta)`

Today `Person._process` calls `brain.think_and_act(delta)` directly — and
`person.gd:38-42` already carries a comment anticipating exactly this change.
The engine must **never** have called a Brain directly, because everything later
(stagger, frame budget, FR73 promote/collapse, FR71 deterministic replay)
installs at that one call site. It is the only seam in this plan that gets more
expensive to defer, which is what earns it rung 1 with one person on screen.

- **Files:** `game/population.gd` + node in `game/game.tscn`; edit `game/person.gd`.
- **Change:** rename the body of `Person._process` to `Person.think_and_act(delta)`
  (matching `Brain.think_and_act`), call `set_process(false)`, and have
  `Population` walk its `Person` children calling it.
- **Also:** `Population` ends each tick by releasing unrenewed workstation
  claims (rung 3 fills this in; leave the call site empty for now).

**Probe:** three dummy persons under a `Population` are each ticked exactly once
per frame, and a `Person` removed mid-run stops being ticked.

**Moment:** Zoogs behaves *identically*. A pure refactor whose success condition
is that nothing changed — verify against rung 0's assertions still passing.

**Do not build:** stagger, jitter, a frame budget, LOD, priority tiers, or a
tick-rate export. A `for` loop. That is the whole rung.

---

### Rung 2 — Places, and where a man is standing

**Seam:** `Person.get_current_place() -> Place`

- **Files:** `game/place.gd` (`Node3D`, `@export var place_name`), a
  `game/town.gd` registry node, `game/person.gd`.
- **Scene:** two places only — the grain fields and the Lord's Inn.

**A person *has* a place** — a discrete fact, per prd.md:470 and FR85. Walking
sets it on arrival (rung 4); until then it's authored per instance. Not a
distance check: the crisp answer is what rungs 3 and 7 are built on, and the
arrival it gives you is exact and free.

Keep it behind `get_current_place()` anyway. One function is what lets the
answer graduate later — to an in-transit value, to a tag lookup — without a
call site moving.

**Probe:** a person placed at the fields reports the fields; moved to the Inn,
reports the Inn; standing between them reports either exactly one place or
`null`, never both.

**Moment:** the readout over Zoogs' head gains a line naming where he is, and it
changes when you drag him in the editor.

**Do not build:** tags, a `location → tags` lookup table, zone refcounting, or
change-notification signals. prd.md:469 is explicit that eligibility is a data
seam and the tag-resolution system waits for a second action that needs it.

---

### Rung 3 — Two farmers, one plot ★

**Seams:** `Workstation.claim(person) -> bool` · `Town.find_workstations(...)` ·
the two idleness counters

**The rung the whole plan is built around.** Everything the roundtable settled
about contention is unverified theory until `claim` returns `false` once.

- **Files:** `game/workstation.gd`, `game/actions/work_the_field.{gd,tscn}`,
  `game/actions/work_step.gd`; edit `game/town.gd`, `game/population.gd`.
- **Scene:** the grain fields with **one plot**, and **two farmers**. Deliberately
  short by one — with four plots and four farmers, as originally sketched, the
  contention design cannot occur.

```gdscript
# Workstation — one person works here at a time.
func claim(person: Person) -> bool          # first-decider-wins; renews per tick
func release(person: Person) -> void
func is_free_for(person: Person) -> bool    # free, or already his

# Town — the one function that finds candidates.
# Radius bound and the hard cap (~3) live in here. Distance is a SCORE term
# for the caller, never a gate in here.
func find_workstations(person: Person, work_name: StringName) -> Array[Workstation]
func note_no_candidates_existed() -> void
func note_every_candidate_was_taken() -> void
```

Two counters, not one. *"There was no field"* and *"every field was taken"* are
different worlds and the fix for each is opposite. Collapsed into one number,
the day the town silently runs out of work looks exactly like the day it runs
out of workers.

**Probe:**
1. Two persons, one station: one `claim` returns `true`, the other `false`.
2. The holder still holds it after 100 ticks — no alternation, no split.
3. The holder stops working; within one tick the station is free.
4. With zero stations in range, `WorkTheField.is_available_to` is false and the
   *no candidates existed* counter incremented — not the *all taken* one.

**Moment:** two capsules. Both wake, both score "work the field" high. One
claims it and his utility curve settles. **The other's scores visibly scramble
on the graph you already built** — work collapses, something else climbs, and he
picks a different life in real time. That is the loser with a body, live, in
about eight seconds, with no art and no movement.

**The loser must always have something on the ballot.** Today `StayUp` is the
floor by composition and that is sufficient — do not add an `Idle` action here.
From rung 6 `Socialise` takes over the job properly. (If a floor action ever is
needed, note `Wait` and `State` are already taken as `class_name`s by the
retired studies; `Linger` is free.)

**Do not build:** queueing, waiting, reservation, priority between the two
farmers, or a fairness rule. He loses, and losing is the content.

---

### Rung 4 — Walking, and arriving

**Seam:** movement, and work gated on presence

- **Files:** `game/actions/go_to_step.gd`, `game/person.gd` (`@export var walk_speed`).
- `Person` is already a `CharacterBody3D` carrying `velocity` and
  `move_and_slide` precisely so this rung doesn't retype the scene.
- `WorkTheField`'s step becomes: not at the plot → walk toward it; at the plot →
  work. One step asking where he's standing, holding no progress and no route.

**Probe:** a person distant from the fields closes the distance every tick and
eventually reports `get_current_place()` as the fields; a person whose target is
claimed by someone else turns around within one tick.

**Moment:** one farmer walks west and starts working. The other sets off, gets
outbid en route, and **turns around mid-field** — the first time an interruption
costs nothing is the first time you can see that it costs nothing.

**Do not build:** pathfinding, navmesh, obstacle avoidance, or animation. Move
toward a point.

---

### Rung 5 — Things you carry

**Seam:** `Inventory.get_count(item_name) -> int`

Mirrors the `get_stat` / `set_stat` wall exactly, and for the same reason: named
access is what lets storage graduate later without rewriting call sites.

- **Files:** `game/inventory.gd` (`Node`), added under `Person` and under `Place`
  (the tavern's storage is the same node).

```gdscript
func get_count(item_name: StringName) -> int
func add(item_name: StringName, count: int) -> void
func take(item_name: StringName, count: int) -> bool   # false if he hasn't got it
func has_at_least(item_name: StringName, count: int) -> bool
func get_item_names() -> Array[StringName]             # for the readout, by reflection
```

Working a plot now yields grain into the farmer's inventory.

**Probe:** work N ticks, assert grain increases; `take` more than he has returns
false and changes nothing.

**Moment:** the readout over the farmer's head gains `grain 3`, and you watch it
climb while the loser's stays at zero. The difference between the two men
becomes a number on their heads rather than an inference from a graph.

**Do not build:** weight, stack limits, item quality, an item database, or a
`Resource` per item kind. A name and a count.

---

### Rung 6 — The quota, and the shape of a day

**Seam:** `Obligation` as stored intent, reaching the ballot as a peer action

- **Files:** `game/obligation.gd`, `game/actions/work_for_hire.{gd,tscn}`;
  the farm owner as a `Person` who issues them.
- Per FR100/FR101/FR102/FR103 and the interpretation note above.

```gdscript
# Obligation — a Node under the Person who owes it.
@export var owed_item := &"grain"
@export var owed_count := 0
@export var place_name := &""       # where it can be discharged — FR100 target
@export var expires_on_day := -1    # FR103: nothing accumulates without bound

func is_discharged() -> bool
func get_weight_at_scoring_time() -> float   # FR102 seam. Authored constant today.
```

When the quota is met the obligation stops contributing weight, work's utility
collapses, and something else wins. The evening needs somewhere to go, so this
rung also lands the rest of the day shape:

- **Two new stats, `social` and `hunger`**, both rising in `Brain._update_body`
  beside adenosine — upkeep, never inside an action. Grep `game/actions/` for
  either afterwards; it must return nothing.
- **`Drink` and `Eat` actions**, in *every* person scene by composition — FR86
  is explicit that the protected categories are present by construction and can
  only be outbid, never pruned. Bread and beer are authored into the tavern's
  starting storage for now (authoring surface #3); rung 9 makes the baker and
  brewer actually produce them.
- **Beds are `Workstation`s.** Twenty of them at the Inn, claimed one per
  sleeper through the *same* `claim()` from rung 3 — which is the cheapest
  possible proof that the labour-clearing seam wasn't secretly about labour.
  `Sleep` gains a place requirement; a man with no bed free is a man with a
  problem, and that problem is content later.
- **Ownership — `Workstation.owner`.** Three rungs need it and it costs one
  exported field: the farm owner sets quotas for plots *he owns*, the tavern
  owner employs a baker at *his* oven (rung 9), a merchant works *his* stall
  (rung 9). It may be null — unowned land belongs to the king, which is the
  same answer as nobody until it isn't.
  **The Lord owns the Inn's twenty beds and has no body** (decided 2026-08-08).
  He is the first off-screen actor in the game, and thirteen people sleeping on
  his charity every night is the largest unexamined lever in the town. Nothing
  reads it yet, and that is correct — see the note below.
- **`Socialise`** — scored off `social`, candidates are places that currently
  hold other people. This is what a man with nothing to do does, and it must
  name no place: the tavern wins in the evening because that is where everyone
  is, and the square wins at midday for the same reason. **Watch for a herd.**
  People-attract-people is positive feedback, and the whole town converging on
  one room is the same stable equilibrium that got split-yield rejected. The
  damper is already specified — distance is a score term (rung 3), so a far
  crowd loses to a near one. If it herds anyway, that is a curve to tune, never
  a rule to add.

**Probe:** a farmer with an unmet quota chooses work over rest at equal
tiredness; the same farmer at quota does not; an expired obligation leaves the
candidate set (FR103) rather than remaining owed; hunger and social rise for a
person doing nothing at all, and neither one is written to from any file under
`game/actions/`; twenty-one sleepers at a twenty-bed Inn leaves exactly one
man standing.

**Moment:** **the first full day.** A farmer works, hits quota mid-afternoon,
walks east across the square to the tavern, drinks, gets tired, walks to the
Inn, sleeps. You can watch one man's whole day without touching anything, and
every transition in it is a decision that was outbid rather than a script.

**Note — the favour the Lord is doing, and why it isn't built yet.** Ownership
is the seam; *detecting a favour* is not. There is no player, no channel system
and nobody who can perceive a benefaction, so a favour written to a social
graph would be a write with no reader — the same shape as the `set_stat`
version stamp, and producing exactly as much watchable difference. Meanwhile
ownership already makes the **present** fact free: who is sleeping in whose bed
is answerable any tick from world state, with nothing stored.

When it does earn its place, two things are already decided:

- **The hook is one point** — the moment `claim()` succeeds on a workstation
  with an owner. One line, no call site moves. That is the whole reason
  `owner` goes in now rather than later.
- **It must be an accumulator, never a history.** FR29 economic dependence is
  *a number on a relationship*, the same shape the roundtable settled for
  reputation (one number written at discharge). "How many nights has he slept
  in my bed" kept as a list of nights is a decision log — O(actors × elapsed
  time), the one unbounded complexity class this design refuses.

**Do not build:** wages, contracts as a type, renegotiation, a quitting action
(rung 9's option), reputation, or a social graph. One obligation, one number,
one expiry.

---

### Rung 7 — Trade needs two bodies in one place

**Seam:** `Trade` action + `can_afford(person, price) -> bool`

- **Files:** `game/actions/trade.{gd,tscn}`; `coin` added to `game/stats.gd`
  (so it plots on the existing graph for free).
- **Scene:** the market square, the farm owner, one merchant, the miller.
- `Trade.find_candidates()` returns people **at my place** who want what I have.
  Not a global lookup — that is the one thing that would break it, because it
  makes failure impossible and deletes the reason the square exists.
- `can_afford` returns `true` unconditionally, today. The call site is the point.

**The tavern owner serving beer is this same action, and that is not a
coincidence — it's the unification worth checking the rung against.** A thirsty
farmer at the bar wants beer; the owner is standing there with beer; the trade
happens because both bodies are in one room. No `Serve` action, no service
system, no counter. Which means the owner cannot serve while he is at the
market square buying flour — and *that* is Samus's drunk-mill-owner beat
arriving on its own, out of a seam built for something else. If serving needs
its own mechanism, rung 7 got the candidate query wrong.

**Probe:** two people in the same place with matching wants exchange goods and
coin, conserving both totals; the same two people in *different* places do not,
and `Trade.is_available_to` is false.

**Moment:** the farm owner walks to the square with grain, the miller walks to
the square, and the sacks change hands **because they are standing in the same
place at the same time.** Move one of them and it doesn't happen. That is
presence as a gate, which is the whole thesis of the game arriving in a rung
that cost almost nothing.

**Do not build:** prices that vary, haggling, supply and demand, a market
clearing price, or an order book. Everyone is flush and the price is authored.

---

### Rung 8 — The wagon, and hiring nobody

**Seam:** an object granting a capability — `is_available_to` reading `Inventory`

Goods now have to reach the square. Two Actions, **never one action with an
`if`:**

| Action | Gate | Score |
|---|---|---|
| `HireHauler` | `find_candidates()` — people who haul. **Returns zero today.** | higher |
| `HaulGoodsYourself` | has a wagon, has goods to move | lower — it costs his afternoon |

Written as a branch inside one step, the fallback is invisible and the engine
never sees a decision. Written as two competing actions, the fallback *emerges*
— and the day a hauling profession exists, the farm owner starts hiring **with
no code change**, because hiring simply outscores pushing your own cart. That is
the seam paying rent, and it's the difference between infrastructure and
ceremony.

- **Files:** `game/actions/hire_hauler.{gd,tscn}`, `game/actions/haul_goods_yourself.{gd,tscn}`.
- Wagons are handed out to whoever needs one. No wagon economy.

**Probe:** with no haulers in the world, `HireHauler.is_available_to` is false
and `HaulGoodsYourself` wins; **inject one dummy hauler and hiring wins instead,
with no other change** — this is the assertion that proves the seam rather than
the feature.

**Moment:** a man pushing his own wagon across the square. It reads as ordinary
until you know that the game asked whether anyone would do it for him and the
answer was nobody — which is what a missing labour market actually looks like
from the inside.

**Do not build:** a hauler profession, wagon capacity, routes, or logistics.
The zero is the content.

---

### Rung 9 — The chain, and the scythes nobody buys

**Seam:** `Recipe` (shared authored data) + `Workstation.progress` (world state)

Mostly repetition, and that is the point: if the seams are right, five
professions are five data rows and no new systems. If any of them needs a new
mechanism, a seam below was wrong, and this is where you find out cheaply.

- **Files:** `game/recipe.gd` (`Resource` — same for everyone, so a Resource per
  `CLAUDE.md`'s Node-vs-shared-file rule), one `.tres` per conversion; edit
  `game/workstation.gd`.
- **Scene:** the town completes — townswood, smithy, the tavern's oven, the
  fields back up to four plots, five stalls in the square — and the roster
  reaches thirteen with the tavern owner, baker, brewer, wood chopper,
  blacksmith, a second merchant and two more farmers. **Eight people and four
  places, and no new classes.** Each one is `person.tscn` with a different set
  of Action scenes under his Brain and different starting stats. If any of them
  needs a script, a seam below was wrong.
- Baker and brewer are in the tavern owner's employ, which is an `Obligation`
  from rung 6 with a different place target — not a second kind of contract.

```gdscript
# Recipe — what a workstation turns into what, and how long it takes.
@export var inputs: Dictionary       # {&"grain": 1}
@export var output_name: StringName
@export var output_count := 1
@export var seconds_of_work := 1.0
```

| Workstation | Recipe |
|---|---|
| millstone | grain → flour |
| oven | flour → bread |
| bar | grain → beer |
| chopping block | log → sticks |
| anvil | iron ore → iron plate |
| merchant stall | sticks + iron plate → **scythe** |

The merchant gains a `TravelForStock` action: he leaves town, returns with iron
ore, and sells it to the blacksmith. Cheap, and it gives the town its first
offscreen event — the smithy can now go idle for reasons nobody in town
controls.

**Farmers are not taught `BuyScythe`.** Not gated shut — simply not in their
repertoire. That is `learn()` doing real work.

**Probe:** grain in at the mill yields flour out conserving totals; a miller
interrupted mid-grind and replaced by a second miller **resumes from the same
progress**, proving progress lives on the stone; after N simulated days the
merchant's scythe count is greater than zero and every farmer's is zero.

**Moment:** the town runs. Thirteen people, seven places, and a full chain from a
field in the west to a finished scythe in the square — and the scythes just
**pile up on the merchant's stall**, because the men who need them have no idea
what they're for. That is the last frame of this arc and the first frame of the
next one.

**Do not build:** the player. A buyer. A gift. A productivity effect. Stop here.

---

## Open calls for the author

**~~1. Is the godswood name deliberate?~~ Resolved 2026-08-08 — renamed
`townswood`.** The original note, kept because the reasoning may be worth
reviving elsewhere: chopping trees in a sacred grove is a
transgression in the tradition that word comes from. If intentional, your wood
chopper commits a small impiety every morning and that is a free social lever
for later. If it's just a nice name, no action.

**~~2. Who pays for the Inn's twenty free beds?~~ Resolved 2026-08-08 — the
Lord does**, as `owner` on the beds, with no body in the scene. Favour
detection deliberately not built; see the note in rung 6. Original framing: There is a Lord in your town who
isn't in the roster. Probably deliberate given the title — flagging it so it
stays deliberate.

---

## What this arc deliberately does not answer

Carried forward from the roundtable brief, still open, and **not** to be
resolved by implementation drift:

- Whether the **farmer** or the **farm owner** buys the first scythe. Same
  object, same productivity number, opposite meaning: one buys a man his
  evening back, the other raises the quota and buys extraction. The second is
  the first genuinely political act in the town.
- The unit of presence at high influence.
- Whether the player experiences the day boundary (FR70).
- Whether the utility graph is ever a player-facing instrument.
- The 300-actor performance probe (`perf_probe.tscn`), against the PRD's
  ≥60fps-at-150 NFR.
