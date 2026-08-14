# Proving Scene — Build Plan

**Status:** written 2026-08-08. **Revised 2026-08-09** against nine settled
decisions, and again **2026-08-11** against all fifteen — see
`proving-scene-decisions.md`. **Rungs 0-4 are SHIPPED** on `poc-v2` (rung 4,
walking, on 2026-08-11 as `35f717f`); rung 5 is next and nothing below it is
built.
**Target:** the east-side town, built rung by rung, ending on a merchant with a
stack of unsold scythes.
**Orchestrated by:** Fable, one rung at a time.  **Fable plans then delegate to cheaper models.**

> **Read `proving-scene-decisions.md` first.** It is the companion to this file
> and it wins where the two disagree — and where two decisions disagree with each
> other, **the HIGHEST NUMBER WINS** (15 over 14 over 7). Nine questions were
> settled on 2026-08-09, and six more since
> after this plan was vetted; each one records what was proposed, what was
> settled, and *why*, so the reasoning survives without being re-derived. This
> file carries the outcomes. That file carries the arguments — and the arguments
> are what stop a delegate from "fixing" a deliberate decision back into the
> obvious one.


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
actually proves it. If either fails, we read code. **Fifteen review points across
the whole arc instead of a hundred** — it was nine until rungs 6 and 9 were each
found to be carrying four rungs of cargo behind one gate (Decisions 3 and 8). A
gate is only worth having if a failure at it has **one** suspect.

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
- **Then read `proving-scene-decisions.md`.** Where it and this file disagree,
  it wins. Nine decisions from the 2026-08-09 vetting pass are folded into the
  rungs below, but the *reasoning* for each lives only in that file. A delegate
  who reads only the rung will re-make a decision that was already made — three
  of the nine look like violations of `CLAUDE.md` until you read why they
  aren't.

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
| `Workstation` | `ActionStep` | something a step works at; the step still holds no progress — the **station** holds it |
| `Inventory` | `Person`, `Place`, `Workstation` | a sibling Node to `Stats`, same accessor discipline. On the station so a half-ground sack exists somewhere. |
| travel cost | `Person` | a second question a person can be asked, and the only one that reads geometry |
| `Obligation` | `Brain`'s candidate pull | reaches the ballot through an ordinary Action |
| the whole town | `person.tscn` | thirteen instances of the scene that already exists |

**A new profession is never a new class.** `Person` already says it: *"Zoogs is
not a special class, he is this scene with a name typed into it."* A miller is
`person.tscn` with a `Miller`-ish set of Action scenes under his Brain and his
own starting stats. There is no `Miller` type, and rungs 9b–9d add eight people
in five trades without adding a single class — which is exactly what those two
no-code gates exist to prove.

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
| A step that **chooses for** another person | Two brains, one puppeteer. **Amended 2026-08-09 (Decision 6)** — as originally worded ("reaches past its own person to move somebody else") this forbade the only implementable trade, since one line of code has to move goods both directions. The rule is: **you may exchange with a man who *could* have chosen this; never with one who couldn't.** So the receiver's own `Trade` must be available to him right now — awake, present, not otherwise gated. Not that he chose it. That he could have. |
| An `if` standing in for a decision | The rung-8 hauling fallback is the canonical case: two competing Actions, never one action that checks and branches. |

**The one thing that is not scripting:** authored constants. Tuning numbers,
recipe contents, quota sizes, and starting inventories are *data*, and data is
surface #2 and #3 doing their job. The line is simple — **a number is
authoring; a branch on who you are is a script.**

### Two rules that keep the surfaces honest

**Want is never a fourth surface.** (Decision 1.) What a man wants is
`target − stock`, computed in GATE and stored nowhere. The target is a quota,
and quotas are authored numbers — surface #2 and #3. Flip the sign and you get
the other half free: `stock − target` is his surplus, which is what he will put
on the table. **Nobody authors a wants-list or a for-sale list**, and a merchant
with fifty sacks stops bidding for the fifty-first without a rule saying so.

**Handoffs are synchronous between strangers.** (Decision 6.) Goods move two
ways, and which one you pick is a design decision about how much the town is
forced to meet:

- **Async** — dropping goods at a place you are permitted to use. One body, no
  simultaneity. **Only inside a relationship that already exists**, e.g. an
  employee discharging into his employer's storage.
- **Sync** — exchanging with a person. Two bodies, one place, both present, both
  currently able to trade.

An economy routed through warehouses is efficient and lonely — nobody waits for
anybody and nobody is ever in the square at the wrong moment. This plan says the
square is where people incidentally see each other and that **seeing each other
is the substrate the whole game is built on.** Async handoffs quietly delete
that, so they are permitted only where a relationship already justifies them.

### The utility scale

> **⚠ PLACEHOLDER — the author to write this in his own words.**
>
> Everything is currently priced against adenosine on a 0–100 scale, and
> `Sleep`'s utility *is* the adenosine, deliberately, so the number you watch is
> the number deciding. That legibility is a virtue and should not be normalised
> away.
>
> But by rung 9 there will be nine action families authored across fifteen
> sessions bidding on one unnormalised scale. Without a written contract they
> will drift, and you will get a blacksmith who never eats with no way to tell
> whether the bug is in `Eat` or in `Forge`. **Cost of writing it now: one
> paragraph. Cost of discovering it at rung 9: retuning thirteen people blind.**
>
> It needs to say what a number *means* — e.g. what score corresponds to "he'd do
> this instead of turning in at the usual hour", and what corresponds to "instead
> of sleeping at all" — and that damping terms (nearness, stock levels) are
> multiplicative and bounded to [0,1] so they never move the anchor.

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
| `_bmad-output/proving-scene-decisions.md` | **The nine decisions settled 2026-08-09**, each with the reasoning behind it. Companion to this file and wins where they disagree. Read it before any rung. |

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
  **Amended 2026-08-09 (Decision 7):** that ruling settled the **identity
  check** — *am I at the tavern?* — and only that. **Travel cost** — *what does
  getting there cost me?* — is a separate, permitted, continuous quantity that
  **never gates anything.** *(Amended again 2026-08-10, Decisions 14 and 15:
  this bullet used to end "only ever multiplies a score", and that arithmetic is
  dead. 14 replaced the multiplier with a subtraction in HOURS; 15 then confined
  travel cost to ordering **one action's own candidates** — this plot or that
  one — so it never enters the comparison between two different actions at all.
  **Pull decides WHAT you do; travel cost decides WHERE you go to do it.** That
  is what makes muting a commute structurally impossible rather than a tuning
  invariant. Relevant to 6d and 9a, neither built.)* The two were fused
  into one word and had to be pulled apart: the plan's own standing check #3
  ("move a place in the editor, does behaviour change?") is unsatisfiable unless
  something reads a transform.
- **Early bird catches the worm is intentional** (decided 2026-08-09, Decision
  2). Claims are day-long and claiming requires presence, so who works a plot is
  decided by who is standing in the field at dawn. **That loop is a feature.**
  It is not to be damped with a fairness rule, a rotation, or a priority scheme.
  If it ever needs softening, that is a curve to tune, never a rule to add.

  **Corrected 2026-08-10 (Decisions 11 and 12) — the mechanism named here was
  wrong.** This bullet used to say the dawn winner "traces back through adenosine
  to when he went to sleep, and compounds." Decision 11 **deleted** that: the
  cycle is now anchored to the sun, so it does NOT compound — every man is pulled
  back onto the same hours within about three days, and two men from the same
  scene would otherwise wake on the same tick forever, handing the plot to
  whoever happens to sit first under `Population`.

  **What actually decides it is `strength`** — a stat on the body, 1.0 for an
  ordinary man, read inside `Brain.get_adenosine_recovery()`. A stronger man
  clears the same sleep debt in fewer hours, so he is up first, every day, for a
  reason you can point at. Measured: 1.15 rises at **04:41** against **06:01**.
  It hangs on RECOVERY and deliberately never on how fast a man tires — that
  direction inverts the answer (a slow-tirer goes to bed later AND gets up
  later) and runs at a cliff. Keep strength in roughly **0.9–1.6**.

  **This is the plan's only written basis for making two people different**, so
  it matters well past rung 3: rung 4 feeds `strength` into `get_travel_speed()`
  (a stronger body walks faster, which is what settles an arrival race), and
  **rung 9d's thirteen people are thirteen bodies with different stats and no
  new code.** Build 9d with identical farmers and you get a coin flip decided by
  scene order, which is the exact failure Decision 12 exists to prevent.

---

## The seam ledger

What this arc installs, and what it deliberately refuses.

### Installed

| Seam | Shape | Rung |
|---|---|---|
| World time | `Clock.get_hours_elapsed(real_delta) -> float` — the sole real→world converter | 0 |
| Decision dispatch | `Population.think_for_everyone(delta)` | 1 |
| Named place | `Person.get_current_place() -> Place` | 2 |
| Travel cost | `Person.get_travel_cost_to(place) -> float` — **returns HOURS** (Decision 14); straight-line ÷ speed today, roads/rivers/a world of towns later. Orders an action's own candidates and never enters a cross-action score (Decision 15) | 2 |
| Means of travel | `Person.get_travel_speed() -> float` — takes no destination; a horse, a cart, a bad leg install here | 4 |
| Who is where | `Town.find_people_at(place) -> Array[Person]` — the reverse index of the named place | 2 |
| Labour clearing | `Workstation.claim(person) -> bool` — a **day-long tenancy**, renewed by use | 3 |
| Candidate pull | `Town.find_workstations(person, work_name) -> Array[Workstation]`, **sorted by travel cost** | 3 |
| Idleness diagnosis | two counters on `Town` | 3 |
| Carried goods | `Inventory.get_count(item_name) -> int` — mounted under Person, Place AND Workstation; `get_inventory()` is the accessor on all three | 5 |
| Goods movement | `Inventory.hand_over(item_name, count, to_inventory) -> bool` — the one waist all goods pass through; take-then-add, both halves or neither | 5 |
| Yield | `WorkStep.get_yield_per_hour(person) -> float` — a tool, a richer plot, a wound install here. Empty today, and **strength is deliberately not in it** | 5 |
| Who benefits | `Workstation.owner` / `Place.owner` — may be nobody, may be somebody with no body | 6a |
| Assigned intent | `Obligation` node under a Person | 6b |
| Permission | `Workstation.is_permitted_to(person) -> bool` — **employment grants access to land** | 6b |
| Want | `target − stock`, computed in GATE, stored nowhere | 7 |
| Exchange | `Trade` action + `can_afford(person, price) -> bool` | 7 |
| Capability from an object | `is_available_to` reading `Inventory` | 8 |
| Work that takes time | `Workstation.progress` + the station's own `Inventory`, world state. **The field landed early as `Workstation.output_part_made` at rung 5** — a count is whole and a tick is a hundredth of an hour, so the fraction had to live somewhere. 9a widens it; it must not add a second one | 5 / 9a |

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
| Demand recording / quota revision | Refused for this arc, **seams named and left empty** (Decision 1). Quotas are authored numbers and act as a floor. `reconsider_quota_levels()` exists, is uncalled, and hangs off `owner` — because a quota level is where authority touches the economy. Prices, haggling, clearing and the order book above stay refused outright. |
| A notice board of who wants what | Deferred to its own rung *after* `Trade` works face to face — a seam earns itself by a collision you witnessed (Decision 1). When built it is a **query**, never a posted list: posting needs sweeping, and sweeping is incompatible with stagger for the same reason it was cut from rung 1 (Decision 2). |
| Multi-party market clearing | Trade is **bilateral** — two people, one place, one tick. N-party matching is the labour-clearing algorithm already deferred twice, arriving through a third door (Decision 6). |

---

## Three doctrine calls Fable must not re-make

These all look like violations of `CLAUDE.md`'s "store nothing you can work out
again." They are not, and the distinction is the same one in every case.

**1. `Workstation` stores who holds it.** The rule forbids storing a *person's
progress or plan*. It does not forbid world state. Who is standing at the
millstone is not regenerable from anybody's stats — it is a fact about the
millstone. FR101 is the exact test: *regenerability, not persistence.*

**The claim is a day-long tenancy** (Decision 2, revised 2026-08-09 — it was a
per-tick lease, and that was wrong). Two fields: `claimed_by` and
`claimed_on_day`. A claim stamped yesterday simply isn't a claim today, so
**expiry is lazy** — one comparison at read time, nothing sweeps, nothing
decays, UPKEEP never touches it.

**Renewed by use, not by a timer.** The running step calls `claim()` on every
tick it advances; he is present, it is already his, so it re-stamps today.
*Anything you are actively doing holds itself; only claims nobody is standing
on go stale.* That is also what stops a sleeper losing his bed when dawn breaks
mid-sleep.

**Claiming requires presence** — you cannot reserve a plot from your bed. Which
means the dawn reshuffle is decided by who is standing in the field, not by
scene order.

*Why not a per-tick lease: it required `Population` to sweep every station at
end of tick, and the moment anyone thinks less often than every frame — which is
the entire point of rung 1 — the sweep evicts a man from a plot he is standing
on and working. You would install rung 1's seam and guarantee it could never be
used.*

**2. `Workstation` stores production progress.** Grinding a sack of grain takes
time. That time lives on **the millstone, not the miller** — which is the
roundtable's rule that a completion condition belongs to the job, not to a flag
on anybody. Two consequences fall out for free and both are correct: interrupting
a miller costs nothing, and a second miller who takes over the stone continues
from where the first one left it.

**The inputs live on the station too**, not in the worker's pockets. When work
starts, the grain moves onto the millstone's own `Inventory`. Otherwise a miller
who walks off mid-grind takes his grain with him and leaves progress behind,
which is a conservation leak wearing a feature's clothes — and a half-ground
sack that exists nowhere cannot be watched, counted, or probed. On the stone, it
is a sack on a stone, which is content.

**And nothing cleans it up.** A half-ground sack nobody returns to *sits there*.
A decay timer or a reset-on-abandon would be an ambient world tick — a banned
shape. The correct answer is "nobody eats."

If a rung ever wants to put either of these on a `Person`, that's the violation.
On the world object, it's the design.

**3. "Interrupting costs nothing" applies to the person, not the world.**
(Decision 2.) A man stores nothing, re-decides every tick, and can walk away
from anything for free — that half is unchanged and load-bearing. But a day-long
tenancy means he holds a plot nobody else can use while he sits in the tavern.
That is a **tenancy, not a lease**, and it is a deliberate commitment.

Do not "fix" it back into a fast lease on the grounds that it violates
*interrupting costs nothing*. It doesn't. The principle was always about what a
person carries between ticks, and he still carries nothing.

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
  dramatic worker beat in the town. *(Same shape as giving up a workstation
  claim early — Decision 2. Releasing a tenancy is a decision, not housekeeping.)*

**Added 2026-08-09 (Decision 1) — the obligation's count is what a want is
measured against.** `owed_count` stays a plain authored `@export`, and it is the
**target** in `want = target − stock`. So the same obligation that makes a man
work is what makes him shop, and there is no second authoring surface for
desire.

Two seams are named here and left **empty and uncalled**, so the day demand
drives production nothing has to move:

```gdscript
# The one place a quota level is ever revised. Today: nothing — quotas are
# authored and stay where you typed them, acting as a floor. When unmet demand
# and excess supply are recorded, and when somebody holds the authority to act
# on them, this is where that lands.
func reconsider_quota_levels() -> void
```

**It hangs off `owner`, and that is the point.** Revision comes from the king,
the Lord, or a player with influence — never from the worker and never from the
town. **A quota level is where authority touches the economy**, and setting one
is a complete political act needing no body, no presence and no dialogue. Rung
6c's note about the Lord's beds is describing that lever without naming it.

---

## How the town assembles

The rungs are deliberately narrow — rung 3 is *two farmers and one plot*, not
the fields — because a seam proves itself against the smallest collision that
can break it. The full town arrives at rung 9d, and by then it should cost
**nothing at all** — every mechanism it needs already exists, which is why 9d's
gate is that no code was written.

**Sixteen gates, not nine** — rung 6 splits into 6a–6d (Decision 3), rung 9 into
9a–9d (Decision 8), and **6a2 was inserted between 6a and 6b on 2026-08-12**
(Decision 26). Both splits were carrying several rungs of cargo behind one review
point, which on a project with no test suite means a failure has seven suspects
and nothing to bisect with.

**6a2 is named out of sequence deliberately.** The decisions file is append-only
and names `6b`, `6c` and `6d` in a dozen places; renumbering them would make
settled text silently wrong with no sanctioned way to correct it.

| Rung | Places in the scene | People | What's new |
|---|---|---|---|
| 0 | — | Zoogs | harness only + world time in hours; no behaviour change |
| 1 | — | Zoogs | dispatch moves to `Population` |
| 2 | grain fields, Lord's Inn | Zoogs | a person has a place, and knows what getting somewhere costs |
| 3 | fields with **1 plot** | 2 farmers | contention |
| 4 | same | 2 farmers | walking, arriving, and near beating far |
| 5 | same | 2 farmers | grain in hand |
| **6a** | same | 2 farmers | the body wants more than sleep |
| **6a2** | same | 2 farmers | **the world learns to feed itself** |
| **6b** | same | + farm owner | the quota |
| **6c** | + Inn's **20 beds** | same | a bed of your own |
| **6d** | **+ tavern** | same | **the first full day** |
| 7 | + market square, mill | + 1 merchant | trade, serving |
| 8 | same | same | wagons, hiring nobody |
| **9a** | + mill's millstone | + miller | work that takes time |
| **9b** | + tavern oven, smithy, townswood, chopping block | + baker, brewer, blacksmith, wood chopper | four conversions, **no new code** |
| **9c** | + 5 stalls | + 2nd merchant | the two-input recipe → scythes |
| **9d** | **4 plots** | + 2 more farmers = **13** | thirteen people, **no new code** |

## Coverage map

Every element of the authored scene, and where it lands. If something you said
isn't in this table, it isn't in the plan — that's the point of the table.

| From the spec | Rung |
|---|---|
| Lord's Inn, free to sleep | 2 |
| 20 **individual** beds, one sleeper each | **6c** — beds are `Workstation`s using rung 3's `claim()`. The only rung that exercises a claim **across** a day boundary, which is the case renew-on-use was repaired for. |
| Grain fields, one worker per plot | 3 (one plot) → **9d** (four) |
| Market square is the only place trade happens | 7 |
| 5 merchant stalls | **9c** |
| Mill, millstone | 7 (place, empty) → **9a** (grain → flour, and the miller arrives with it) |
| Townswood, trees | **9b** |
| Smithy, anvil + forge | **9b** |
| Tavern: bar + storage | **6d** — moved from 6a by Decision 25; nothing enters it before `Socialise` |
| Tavern: oven | **9b** |
| Farmer's quota, set by the farm owner as part of his contract | **6b** |
| Quota met → work utility drops precipitously | **6b** |
| Urge to socialise → walks to the tavern | **6d** — the walk and the urge |
| …→ beer | **7** — beer is a purchase, so it waits for `Trade` |
| Beer replenishes a social stat | **7** |
| **Eats bread if hungry** | **6a** — from his **own** inventory, **fourteen loaves authored per farmer in `game.tscn`** (Decision 26). → **6a2** (he bakes his own from grain, 3:1) → **7** (bought from the tavern) → **9b** (the baker actually bakes it, 1:1) |
| Then tired enough → Lord's Inn → sleeps on a bed | **6c** |
| Farmer hands his quota to the farm owner | **6b** — discharged into the **Place** his obligation names (the barn), which `owner` makes the farm owner's. No person-to-person transfer at rung 6. |
| Farm owner sells to a merchant willing to buy | **7** |
| Miller grinds bought grain into flour | **9a** |
| Tavern owner buys both grain and flour | **9b** |
| Baker and brewer are **in his employ** | **9b** (an obligation, reusing 6b — not a new relationship type) |
| Baker → bread → storage; brewer → beer → storage | **9b** |
| **Tavern owner acts as the server** when people request beer and bread | **7** — this is `Trade`, not a service system. See the rung. |
| Wood chopper: trees → logs → sticks → sells to a merchant | **9b** |
| Blacksmith: iron ore → iron plates at the anvil → sells to the same merchant | **9b** |
| Merchant: sticks + plates → **scythes** → tries to sell at market | **9c** (they don't sell — that's the ending) |
| Merchant imports iron ore and sells it on to the blacksmith | **9c** |
| Miller and smith drink at night against their own production targets | **9d** |
| "If you've got something to trade you have to go there" | 7 (presence is the gate) |
| Money, everybody flush, no affordability | 7 |
| **People with nothing to do hang in the square or chill at the tavern** | **6d** — an *outcome* of `Socialise`, never an authored destination |
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

**This rung also lands world time.** See *Time* below — it is a prerequisite for
the assertions, not a cleanup.

- **Files:** `game/probe.gd` (a `SceneTree`). One file until it hurts — call it
  ~300 lines. Edits: `clock.gd`, `person.gd`, `brain.gd`, `action_step.gd` and
  the existing steps, for the hours change.
- **Shape:** instance a scene, pump it, assert, print `PASS` / `FAIL`, exit
  non-zero on failure. **Realistically 120–150 lines**, not ten — said plainly
  so nobody under time pressure cuts the `.tscn` scan, which is the
  highest-value assertion in the file.
- **Run — two commands, always:**
  ```
  Godot_v4.4-stable_mono_win64_console.exe --headless --path . --editor --quit
  Godot_v4.4-stable_mono_win64_console.exe --headless --path . --script game/probe.gd
  ```
  `--script` does **not** build the global class cache. Without the import pass
  first, `class_name Person` fails to resolve and the probe dies for a reason
  that has nothing to do with the code. *(Measured — Decision 9.)*

**Four engine behaviours the harness must respect** *(all measured against the
4.4 binary above — Decision 9):*

1. **`process_mode = Node.PROCESS_MODE_DISABLED`, never `set_process(false)`.**
   `set_process(false)` called from `_initialize()` is **silently discarded** —
   the node ticks anyway. A probe that disables a Person and then pumps him by
   hand gets a **double-ticked person**, adenosine advancing at twice the pumped
   rate, presenting as a tuning bug. `PROCESS_MODE_DISABLED` leaks zero frames,
   works from `_initialize`, and inherits to Brain/Stats/Readout for free.
2. **`_initialize()` runs before anything is in the tree** — `_ready` has not
   run, `@onready` vars are null, `get_global_transform()` errors. Setup there;
   assertions from the first `_process` frame.
3. **The harness advances `Clock` itself.** With everything disabled,
   `Clock._process` never runs and nothing moves time.
4. `move_and_slide()` cannot be pumped — see rung 4.

**Time — the prerequisite** *(Decision 5)*

Today drift is per **real** second (`base_adenosine_per_second * delta`) while
`Clock` divides by `day_length_seconds`. They are two unconnected clocks, and
`day_length_seconds` is a slider on the tuning board. Drag it to 10s and the
farmer stays awake for four and a half days; drag it to 600s and he naps around
the clock. The slider does not do what its own comment says.

> **Real time enters the simulation at exactly one line and is never seen
> again.** `Clock.get_hours_elapsed(real_delta)` is the sole converter.
> Everything downstream takes **hours** — including the argument name, per
> `CLAUDE.md` rule 3. Every rate becomes per-hour
> (`base_adenosine_per_hour := 2.5` reaches ~45 after ~18 hours awake, which is
> a sentence you can reason about).

**To preserve today's behaviour, multiply every per-second rate by
`day_length_seconds / 24`** — which is `60 / 24 = 2.5` at the shipped default.
So `base_adenosine_per_second = 1.0` becomes `base_adenosine_per_hour = 2.5`,
and `base_adenosine_cleared_per_second = 2.5` becomes
`base_adenosine_cleared_per_hour = 6.25`. That reproduces the current cycle
exactly: 45 real seconds up (18 world hours, sleeping around 18:00) and 14
asleep (5.6 hours). **Getting this factor wrong is the one way this change
breaks a working system**, and it will present as "he never sleeps" or "he naps
constantly" rather than as a units error.

Until `Population` exists the conversion sits in `Person.think_and_act`; rung 1
moves it up. This is what makes assertion 1 writable: `think_and_act(1.0)` **is**
one hour, twenty-four calls **is** a day, and no assertion ever mentions
`day_length_seconds`.

**First assertions, against the Zoog that already exists:**

1. Over 24 simulated hours he sleeps at least once and wakes at least once.
   *Stated in hours; never references the day-length slider.*
2. Adenosine rises while awake and falls while asleep. Use `>=`, and assert
   **strict** increase only below `adenosine_ceiling` — `clampf` flattens it at
   the top, so strict monotonicity is false there.
3. **No action is ever chosen while its own gate says no** — every pumped tick,
   for every action anybody ever learns:
   ```gdscript
   for action in person.brain.get_known_actions():
       if person.brain.current_action == action:
           assert_true(action.is_available_to(person),
               "chose \"%s\" while gated shut" % action.name)
   ```
   *(Replaces "when `Sleep.is_available_to` is false, `Sleep` is never chosen" —
   `sleep.gd` overrides no `is_available_to`, so that assertion was vacuous and
   could never fail. Needs `Brain.get_known_actions()`; `_known_actions` is
   private today.)*
4. **The `node_paths` trap, caught by scanning `.tscn` text** — not by runtime
   reflection, which cannot tell a broken wire from a legitimately empty
   optional, and would false-positive forever on rung 6a's deliberately-null
   `Workstation.owner`. The rule: *a property assigned a bare `NodePath("…")`
   must be named in its own node's `node_paths`; one assigned
   `Array[NodePath]([…])` must not.* Verified against `game.tscn` — four bare
   assignments, all declared; `TuningBoard.watching` correctly excluded; zero
   false positives. It also catches the bug in scenes that aren't in the probe.
   **Plus a runtime half** for `CLAUDE.md`'s second trap, which text cannot see:
   every path inside an `Array[NodePath]` export must actually resolve.

**Moment:** none. This is the only rung without one, which is why it's rung 0
rather than rung 1.

**Do not build:** a test framework, fixtures, mocks, or a runner. No GUT, no
GdUnit. Injected actors are always real `person.tscn` instances with different
Action children — never mocks — which is this plan's own thesis about
composition and doubles as standing check #2.

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
- **Change:** rung 0 already extracted `Person.think_and_act(hours)` out of
  `_process`. Rung 1 removes the call from `_process` and has `Population` walk
  its `Person` children instead. **The readout stays on `_process`** — it is
  presentation, it should run every frame regardless, and dragging a `Label3D`
  write into a method named `think_and_act` hides half of what that method does.
- **Also:** the real→world time conversion moves up here. `Population` calls
  `clock.get_hours_elapsed(delta)` once and passes hours to everyone, so
  **nothing below `Population` ever sees a real second.**
- **Warn on a missing driver.** `Person._ready` should complain if it has no
  `Population` above it — otherwise a person dropped into a scene silently
  stands there forever and it reads as a balance problem. (`CLAUDE.md`: never
  guard a missing wire with a silent return.)
- **Write down why the loop is serial.** `Population` walking its people one at
  a time in order is what makes rung 3's first-decider-wins correct **without
  any locking** — gate and claim are atomic per person because nothing runs
  between them. Put that in the file's comment: the day somebody adds
  `call_deferred` or a thread, it breaks silently.

**Deleted from this rung (Decision 2):** the plan previously had `Population`
end each tick releasing unrenewed workstation claims. **Do not write that call
site at all.** Claims are day-long tenancies that expire lazily on read; nothing
sweeps. A sweep would also be incompatible with the very stagger this rung
exists to enable — a man who thinks every fourth frame would be evicted from a
plot he is standing on and working.

**Probe:** assert on an **observable**, not on instrumentation — it needs no
fixture and catches the exact hazard rung 0 measured:

```gdscript
var before: float = person.stats.get_stat(&"adenosine")
population.think_for_everyone(1.0)
assert_near(person.stats.get_stat(&"adenosine") - before,
    person.brain.get_adenosine_accumulation(), 0.001,
    "ticked twice — engine _process is still live on this Person")
```

Plus: a `Person` removed *during* the loop is not ticked after removal and does
not error. (`get_children()` returns a snapshot, so a person removed mid-loop
still gets one tick with `is_inside_tree() == false` — survivable for
`think_and_act`, not for anything touching `global_position`.)

*Note "once per `think_for_everyone` call", not "once per frame" — there are no
frames in a pumped harness.*

**Moment:** Zoogs behaves *identically*. A pure refactor whose success condition
is that nothing changed — verify against rung 0's assertions still passing.

**Do not build:** stagger, jitter, a frame budget, LOD, priority tiers, or a
tick-rate export. A `for` loop. That is the whole rung.

---

### Rung 2 — Places, and where a man is standing

**Seams:** `Person.get_current_place() -> Place` · `Person.get_travel_cost_to(place) -> float` ·
`Town.find_people_at(place) -> Array[Person]`

- **Files:** `game/place.gd` (`Node3D`, `@export var place_name`), a
  `game/town.gd` registry node, `game/person.gd` (the accessor, the travel cost,
  **and a line in the readout naming where he is**).
- **Scene:** two places only — the grain fields and the Lord's Inn.

**Two questions, permanently separate** (Decision 7). Fusing them is what caused
the physics override that had to be reverted:

| | Question | Asked in | Shape |
|---|---|---|---|
| **Identity check** | *am I at the tavern?* | **GATE** | discrete. One answer or `null`. |
| **Travel cost** | *what does getting there cost me?* | **SCORE** | continuous. **Never gates anything.** |

**A person *has* a place** — a discrete fact, per prd.md:470 and FR85. Walking
sets it on arrival (rung 4); until then it's authored per instance. Not a
distance check: a radius flickers at its own edge, overlaps ambiguously when two
places are near each other, and makes arrival framerate-dependent. Rungs 3 and 7
both ask "same place?" every tick and both need a crisp answer.

**Travel cost is the other half, and the plan already requires it.** Standing
check #3 — *move a place in the editor, does behaviour change?* — is
unsatisfiable unless something reads a transform. It lives on `Person` rather
than `Place` or `Town`, because every caller is an Action scoring itself and an
Action always has the person — and because there will be more than one town, so
a `Town`-scoped answer breaks. Straight-line off the transforms today; roads, a
river crossing, a gate shut at night and eventually a world spanning towns all
install in that one function body with no call site moving.

**`Town.find_people_at()` is the reverse index** of the named place. Both 6d's
`Socialise` ("candidates are places that currently hold people") and rung 7's
`Trade` ("people at my place") need it, and it is four lines. It goes in here,
where the index and the fact can first disagree.

**Each Person PULLS `town` off `Population` in his own `_ready`** — one wire in
the whole scene feeds everybody, instead of thirteen hand-wired `NodePath`s and
thirteen chances at the trap that already shipped a dead day/night cycle here.
Mirrors how `Brain` finds its `Person`. `Person._ready` warns if `town` is null.

> **Corrected 2026-08-10 (Decision 10). This paragraph used to say
> "`Population._ready` INJECTS `town` into each Person", and that cannot work** —
> Godot readies **children before parents**, so a Population handing the town
> down in its own `_ready` arrives *after* every person has already looked and
> found nothing, and the missing-town warning would fire on every person of every
> correctly-wired scene. Pull also wires a man born mid-run, with nothing
> watching for new arrivals, which is what standing check #2 needs at 9d.
> **Generalises: anything a Person needs one shared reference to hangs off
> `Population` and is PULLED, never pushed** — so a market, a calendar or a
> weather system installs the same way and not by copying the rejected shape.

**Probe:**
1. A person placed at the fields reports the fields; moved to the Inn, reports
   the Inn; reports `null` before anything has set it, and warns.
2. ~~**`find_people_at(place)` and `get_current_place()` never disagree** — this
   is the one with teeth.~~ **VACUOUS — do not write this (Decision 10).**
   `find_people_at` is a *query*: it loops the people and asks each one where he
   is, so there is exactly ONE copy of the fact and one copy cannot contradict
   itself. It is **banked** in `town.gd` against the day that function becomes an
   index and a second copy exists to disagree. What replaced it, and has teeth:
   the exact set at a place; a man who moves with nothing invalidated by hand; a
   man who dies; and nobody at `null`.
3. Travel cost falls as he moves toward a place and rises as he moves away.

*(The plan previously asserted "standing between them reports either exactly one
place or `null`, never both." That is vacuous — a single field cannot report
both. It was testing a distance-model failure in a model that isn't
distance-based.)*

**Moment:** the readout over Zoogs' head gains a line naming where he is, and a
second line for what the fields cost him to reach. **Drag the *fields* in the
editor and the second line moves** — geography being read, live. *(Dragging
**Zoogs** does not change his place, and must not: place is a discrete fact he
carries, not a proximity result. That was the earlier Moment and it described
the model that got reverted.)*

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
# A DAY-LONG TENANCY, not a per-tick lease (Decision 2). Two fields; a claim
# stamped yesterday simply isn't a claim today, so expiry is lazy — one
# comparison at read time. Nothing sweeps. UPKEEP never touches this.
var claimed_by: Person = null
var claimed_on_day := -1

func is_free_for(person: Person) -> bool:
	# A holder who has been freed is not a holder. KEPT, BUT UNREACHABLE —
	# measured 2026-08-10 by deleting it: a TRULY freed reference already
	# compares `== null` as true in this engine, so the branch below produces
	# the right answer without it. (CLAUDE.md's queue_free() trap is the
	# end-of-frame case, and a claim is only ever read on a later tick.) Kept
	# because is_instance_valid is the documented contract and one line is cheap
	# — but do NOT write a probe claim believing this guard has teeth. It does
	# not, and that was found the expensive way.
	if not is_instance_valid(claimed_by):
		claimed_by = null
	if claimed_by == null:
		return true
	# person.clock, NOT a `clock` field on the station. Every Person already
	# carries the one Clock (pulled off Population at birth, Decision 11), so
	# NOT ONE STATION NEEDS A WIRE OF ITS OWN — which matters most at 6c, where
	# twenty beds are twenty more chances at the hand-wired-NodePath trap that
	# already shipped a dead day/night cycle in this project.
	if claimed_on_day < person.clock.day():
		return true
	return claimed_by == person

func claim(person: Person) -> bool     # only from here — no reserving from your bed

# NO release(), AND THAT IS DELIBERATE — do not add one here or at 6c. Under
# renew-on-use, abandoning a plot IS simply not renewing it: walk away and the
# claim lapses at the next day boundary on its own. A release() today would be a
# call site with no caller, and a second way to give something up. What would
# earn it is an Action that SCORES giving a station up early, so somebody else
# can have it before tonight — nothing scores that yet. (Rung 3 shipped without
# it; rung 4 re-confirmed it.)

# Town — the one function that finds candidates.
# NO radius bound and NO hard cap (Decision 7 — both cut). A radius bound is a
# gate, which contradicts the next line, and neither is testable with one plot.
# Returns EVERY matching station, STABLY SORTED BY TRAVEL COST, node path as
# tiebreak. Never Dictionary hash order.
func find_workstations(person: Person, work_name: StringName) -> Array[Workstation]
func note_no_candidates_existed() -> void
func note_every_candidate_was_taken() -> void
```

**Ask once, not three times.** `is_available_to` needs *"are there candidates"*,
`get_utility_score` needs *"how good is the best one"*, and the step needs
*"which one am I claiming"*. If those three re-derivations disagree, **the
utility that won is not the utility he gets** — a bug that reads as "the AI is
flaky" and costs a day to find. One `get_best_candidate(person)`, and the sort
is what makes the three agree.

**Renewed by use.** The working step calls `claim()` every tick it advances; he
is present, it is already his, so it re-stamps today. Nothing else keeps a claim
alive and nothing needs to.

Two counters, not one. *"There was no field"* and *"every field was taken"* are
different worlds and the fix for each is opposite. Collapsed into one number,
the day the town silently runs out of work looks exactly like the day it runs
out of workers.

**Probe:**
1. Two persons, one station: one `claim` returns `true`, the other `false`, and
   `WorkTheField` is off the loser's ballot entirely — he is never scored, not
   outscored.
2. **A claim survives a day boundary while being worked** (renew-on-use).
3. **A claim does not survive a day boundary while abandoned.**
4. **A claim attempted from the wrong place fails** — presence is required.
5. **`queue_free()` the holder, pump two ticks, and the loser can now claim it.**
   Standing check #1, made mechanical.
6. With zero stations existing, `WorkTheField.is_available_to` is false and the
   *no candidates existed* counter incremented — not the *all taken* one.

*(The plan previously asserted "the holder still holds it after 100 ticks — no
alternation, no split." That is now trivially true; it only ever guarded against
sweep-order flicker, and there is no sweep. Dropped.)*

**Moment:** two capsules. Both wake, both score "work the field" high. One
claims it and his utility curve settles. **The other's scores visibly scramble
on the graph you already built** — `WorkTheField` drops to a gap (gated actions
record `NAN` and the graph already draws that as a hole, not a zero), something
else climbs, and he picks a different life.

**Shorten the day to watch it repeat.** With a day-long tenancy the scramble
happens at dawn and then goes flat, so run at an 8–12 second day and you get the
beat every few seconds: dawn, both bid, one loses, his curves re-scramble.
*(This only works because of Decision 5 — before world time was denominated in
hours, dragging that slider left the farmer awake for four days.)*

And the day-long version is the better frame: **the loser now loses for a whole
day and you watch him live a different one**, instead of snatching the plot the
moment the winner blinks.

**Two more graph instances.** `game.tscn` currently wires `StatGraph.person` to
Zoogs by `NodePath`. Two farmers means two more panels — a scene edit worth
noting because you will be at four panels on one screen.

**The loser must always have something on the ballot.** Today `StayUp` is the
floor by composition and that is sufficient — do not add an `Idle` action here.
From rung 6d `Socialise` takes over the job properly. (If a floor action ever is
needed, note `Wait` and `State` are already taken as `class_name`s by the
retired studies; `Linger` is free.)

**Do not build:** queueing, waiting, reservation, priority between the two
farmers, or a fairness rule. He loses, and losing is the content.

---

### Rung 4 — Walking, and arriving

**Seam:** movement, and work gated on presence

> **SHIPPED 2026-08-11 as `35f717f` on `poc-v2`.** This section was corrected
> against Decisions 14 and 15 on the same day — as originally written it
> specified a falloff curve and a `distance_that_halves_appeal` knob that both
> decisions **cut**, and a Moment (outbid *en route*, turning around mid-field)
> that Decision 15's knowledge rule makes impossible. Neither was ever built.

- **Files:** `game/actions/go_to_step.gd`, `game/person.gd` (`@export var walk_speed`,
  `get_travel_speed()`, and `get_travel_cost_to()` changed to return **hours**),
  `game/actions/work_step.gd`, `game/actions/work_the_field.gd` (the knowledge
  rule below); `game/game.tscn` (both farmers re-authored at the Inn, camera).
- **Do NOT call `move_and_slide()`** (Decision 4, measured). Called from
  `_process` it multiplies by the *physics* delta and produces non-uniform
  displacement; under `PROCESS_MODE_DISABLED` it moves **zero, silently**, so
  every movement probe from here on would be unwritable. **Integrate
  `global_position` directly.** Keep `CharacterBody3D` as the type — it costs
  nothing and collision may want it later.
- `WorkTheField`'s step becomes: not at the plot → walk toward it; at the plot →
  work. One step asking where he's standing, holding no progress and no route.

**`GoToStep` owns both edges of `current_place`.** The first tick of movement
**clears it to `null`** (in transit); arrival writes it. Nothing else ever
writes it. Without the clear, a man keeps the fields until he reaches the
tavern — and rung 7's *"same place?"* gate then says two men a hundred metres
apart are trading, which makes every trade probe meaningless. prd.md already
specifies the in-transit value; the plan had omitted it.

**NOTHING ABOUT SCORING CHANGES AT THIS RUNG** (Decisions 14 and 15, which
between them replaced what this paragraph used to say). `WorkTheField` keeps
`pull + daylight_pull * sun`, **`73 / 30` untouched**. There is no falloff
curve, no multiplier, no `distance_that_halves_appeal`, no travel-cost
coefficient and no `patience` weight — the last of those was invented by two
drafts of the rung-4 prompt purely to stage this rung's Moment, and was deleted.

> **Pull decides WHAT you do. Travel cost decides WHERE you go to do it.**

Travel cost only ever competes an action's own **candidates** — this plot or
that one. It never enters the comparison between one action and another, which
is what makes muting a commute *structurally impossible* rather than a tuning
invariant somebody has to remember to check. `Town.find_workstations` already
sorts by it (rung 3), so travel cost is already doing its whole job.
`get_travel_cost_to` changes to return **hours** — no observable behaviour at
this rung, since hours and distance sort identically for one man; it earns
itself at 9a, where candidates first differ in quality.

**Two seams, kept apart** (Decision 14): `Person.get_travel_speed()` is the
MEANS — walking today, a horse or a cart or a bad leg later — and takes no
destination. `get_travel_cost_to()` is the JOURNEY, where roads and rivers
install. **A horse changes the first, a road changes the second.** `walk_speed`
is calibrated from the FICTION (a five-to-fifteen-minute walk to the fields),
never from a realistic metres-per-second, or every journey in the game is free.

**FREENESS IS KNOWABLE ONLY WHERE YOU ARE STANDING** (Decision 15) — one
condition on `WorkTheField`'s candidate query, and the thing that lets a man set
off at all. Away from a plot he knows it EXISTS, not whether it is taken, so it
stays a candidate and he walks; standing at it he can see, and work leaves his
ballot **on arrival**. Rung 3's remote freeness was omniscience the moment two
men stood apart: a man at the Inn would know the job was gone and would never
leave. `Workstation.is_free_for` does **not** change — the station reports the
plain truth, and what a man knows of it is the Action's business. **The wasted
journey is the point**; it is the collision that later earns the notice board.

**Probe:**
1. A person distant from the fields closes the distance by exactly
   `walk_speed × hours` each tick, and eventually reports `get_current_place()`
   as the fields.
2. **In transit, `get_current_place()` is `null`** — not his origin, not his
   destination.
3. A man walks toward a plot he cannot see the state of, and **work leaves his
   ballot ON ARRIVAL.** Two exact assertions: while away from the fields with
   the plot held by somebody else, `is_available_to` is **true** and his
   distance is decreasing; on the tick he arrives it is **false** and
   `get_last_scores()` records `NAN`. *(This replaced "outbid en route, distance
   stops decreasing" — under Decision 15 he cannot see the plot until he reaches
   it, so he is never outbid mid-stride.)*
4. **A man does not walk to a plot he is standing next to and can see is
   taken** — the same rule from the other side, so the gate is not simply always
   true when away.
5. **A nearer station is chosen over an identical farther one.** A
   **candidate-ordering** assertion, not a score assertion. Build the second
   station in a probe-constructed world; do not add one to `game.tscn`, or rung
   3's contention disappears. *("The farther one still scores above zero" is
   retired: travel cost never enters a cross-action score, so there is no number
   left for it to be barred by. The property is now structural.)*
6. **Move a place and which station wins changes.** Standing check #3, made
   mechanical.

**Moment — accepted as it unfolds, not staged.** Day 0: both farmers wake at the
Inn, work overtakes `StayUp` around 03:45, and both set off. **The faster man
arrives first and claims it; the other arrives to find the job already gone and
re-decides standing in the furrow.** Day 1 onward is the short version — nothing
pulls anybody home at night (beds are 6c), so both wake at or near the fields,
Hobb claims at 04:41 and Zoogs wakes at 06:01 to find it taken where he stands.

**Nobody is outbid mid-stride, and that is correct.** The loser cannot see the
plot until he arrives, so he walks the whole way and the drop happens on
arrival. **The commute is mostly a day-0 event**, and that is honest — do not
"fix" either here.

**Pull the camera back here.** From 6d onward the Moment is a man crossing from
the fields to the tavern to the Inn, and a Moment you cannot see is not a gate.

**Watch it at a LONG day — 300–600 seconds — which INVERTS rung 3's
instrument.** Decision 13 established the shortened day for watching a
once-a-day crossing repeat; at the shipped 60-second day a ten-minute commute
takes 0.4 real seconds and you will not see anybody walk anywhere.

**Do not build:** pathfinding, navmesh, obstacle avoidance, animation, steering
or acceleration. Move toward a point at a constant speed. No radius-based
arrival check of any kind. No second authored workstation in `game.tscn`.

---

### Rung 5 — Things you carry

**SHIPPED 2026-08-11 (`07a147c`), through its gate.** All thirty claims green,
the schedule unmoved (Zoogs 22:01 / 8.00 h / 06:01, Hobb up 04:41), and Hobb
takes the plot on every day 0-5 while Zoogs never does — now with grain on it:
Hobb ends day 5 holding 94, Zoogs holding 0. Three things below were settled by
building them and are recorded in place: the fraction lives on the station, the
scale guard shipped as a pin, and `get_inventory()` is the accessor on all
three mounts.

**Seam:** `Inventory.get_count(item_name) -> int`

Mirrors the `get_stat` / `set_stat` wall exactly, and for the same reason: named
access is what lets storage graduate later without rewriting call sites.

- **Files:** `game/inventory.gd` (`Node`), added under `Person`, under `Place`
  (the tavern's storage is the same node) **and under `Workstation`** (rung 9a
  needs the millstone to hold the sack it is grinding). Edit `game/person.gd`
  (readout) and `game/ui/stat_graph.gd` (see below) — both omitted from the
  original Files list and both are what make this rung's Moment visible at all.

```gdscript
func get_count(item_name: StringName) -> int
func add(item_name: StringName, count: int) -> void    # CREATION — production only
func take(item_name: StringName, count: int) -> bool   # DESTRUCTION — consumption only
func has_at_least(item_name: StringName, count: int) -> bool
func get_item_names() -> Array[StringName]             # for the readout, by reflection

# MOVEMENT — the one waist all goods pass through, in both directions.
# Both halves or neither: a transfer that half-happened surfaces three rungs
# later as an item count that drifts, and you will not find it by reading.
func hand_over(item_name: StringName, count: int, to_inventory: Inventory) -> bool
```

**Three call sites, one implementation.** `add`/`take` create and destroy;
`hand_over` moves. Keeping them apart is what makes a conservation probe mean
something — world totals may change **only** where `add`/`take` are called. And
it is what stops rungs 6b, 7 and 9a each growing their own transfer path.

> **THE API ABOVE SHIPPED EXACTLY AS WRITTEN, AND IS NOW FROZEN — 6a, 6b, 7, 9a
> and 9c all consume it.** Three things it also grew that are not in the block
> above, and that a later rung will otherwise reinvent:
>
> - **`get_inventory()` is the accessor, on Person, Place AND Workstation** —
>   the same words asked of all three, so `hand_over` between a farmer and a
>   barn (6b) or a farmer and a merchant (7) never has to know which kind of
>   thing is on either end. **Null is a legitimate answer** for a Place or a
>   Workstation: a road is somewhere a man can be and nowhere goods are kept.
>   Only `Person` warns when it has none, by composition.
> - **`hand_over` is take-then-add, in that order**, so the only way to move a
>   thing is to have had it, and it refuses a null destination out loud rather
>   than dropping the goods through the movement door.
> - **A count spent to zero keeps its key**, so an item stays on his readout and
>   on the graph at zero rather than vanishing — a line that disappears reads as
>   broken instrumentation where a line on the axis reads as *he is out*.

Working a plot now yields grain into the farmer's inventory.

> **⚠ `WorkStep` GREW A SECOND BRANCH AT RUNG 4 — put the grain in the right
> one.** `advance()` no longer only works: it asks where he is standing, and if
> he is **not** at the plot's place it walks him there and returns. Add the yield
> at the top of `advance()` and **a man produces grain while walking across
> town**, which reads as a balance problem and is not one. It belongs after the
> `station.claim(person)` succeeds — the same place, and for the same reason,
> that renew-on-use lives.
>
> **The probe for this rung inherits the trap.** *"Work N ticks, assert grain
> increases"* silently becomes *"walk N ticks, assert nothing"* if the farmer
> starts anywhere but the fields — and **both farmers are now authored at the
> Inn.** Stand him on the plot's place first (`probe.gd` has `_stand_at()` for
> exactly this), or pump long enough to cover a ten-world-minute commute. Rung 4
> had to pin four existing claims for this reason; do not rediscover it.

**Coin lives here, not in `Stats`.** The plan previously put it in `stats.gd`
"so it plots on the existing graph for free" — that is presentation choosing
storage, and it splits possession across two systems permanently, so every trade
probe would have to check both. Instead: coin is `Inventory.get_count(&"coin")`,
and **`stat_graph` learns to plot item counts** — about six lines mirroring the
loop already there, using the `get_item_names()` reflection this rung already
specifies. Not a nicety: the last frame of this arc is scythes piling up on a
merchant's stall, and **inventory-on-the-graph is the instrument that ending is
measured with.**

**`stat_graph` needs a per-series ignore or scale guard before coin lands.**
`_get_top_of_scale()` scales to the global maximum, so coin at 500 squashes
adenosine at 45 flat against the axis and the primary instrument goes unreadable
exactly when the town gets interesting.

> **SHIPPED as a pin, not an ignore:** `@export var top_of_scale` — 0.0 fits the
> axis to the data as before, and any other number holds it there. A line above
> the pin **rides the top edge** rather than being drawn across the rest of the
> interface. A pin beats an ignore because an ignored series is invisible, and
> the merchant's coin is a thing you want to WATCH; what you do not want is it
> taking the sleep cycle off the screen with it.
>
> **The shipped panels are left on 0.0 deliberately**, because at rung 5 grain
> and adenosine share a range and the thing worth watching is both at once. It
> stops being true fast — Hobb passes adenosine's 47 before the end of his first
> working day and ends day 5 at 94 — so **pinning the two stat panels around 60
> is the first tuning move**, and it is one number in the inspector, not a code
> change.
>
> One thing that is not obvious until an item appears mid-run: a series born
> after the graph started is **back-filled with NANs** so it lines up in time.
> Without that it is drawn from the left edge as though it had always existed,
> and a man's first grain reads as having happened an hour ago.

> **⚠ A COUNT IS WHOLE AND A TICK IS A HUNDREDTH OF AN HOUR — so the yield
> needed somewhere to keep the fraction, and this was the one thing the rung
> could not be built without deciding.** One grain an hour is 0.01 of a grain
> per tick; truncated to a count, every tick of work rounds to zero and a man
> farms all day for nothing.
>
> **Settled by the author 2026-08-11: the fraction lives in the furrow** —
> `Workstation.output_part_made`, a float in [0, 1). The step adds a tick's
> worth and takes whole grain OUT the moment it completes. Rejected: paying on
> the hour off the clock (nothing stored, but it pays by wall time rather than
> by work done, so two minutes either side of the hour collects a full grain),
> and a carry on the man's own step (which is stored progress on a PERSON, the
> one thing the substrate refuses — he would carry a half-turned furrow across
> town). See the ⚠ box on **rung 9a**, whose `Workstation.progress` this is.

**Probe:** work N ticks, assert grain increases; `take` more than he has returns
false and changes nothing; **`hand_over` conserves the total across two
inventories, and fails atomically** — a transfer that cannot complete moves
neither half.

> **SHIPPED AS SIX CLAIMS, 25 TO 30**, all of them watched failing. Two are
> stronger than the line above and worth knowing about before you write a
> seventh: **claim 25 asserts the AMOUNT, not the direction** — sack plus furrow
> must account for every hundredth of rate × hours, which is what a per-tick
> instead of per-hour rate fails — and **claim 26 stands a man at the Inn and
> asserts he produces nothing on the road**, which is the ⚠ box above made
> mechanical. 26 caught the misplaced yield on the first try when it was
> deliberately moved above the walk branch.

**Moment:** the readout over the farmer's head gains `grain 3`, and you watch it
climb while the loser's stays at zero. The difference between the two men
becomes a number on their heads rather than an inference from a graph.

**Do not build:** weight, stack limits, item quality, an item database, or a
`Resource` per item kind. A name and a count.

---

### Rung 6 — The shape of a day, in five gates

**Split 2026-08-09 (Decision 3).** As drafted this rung landed seven independent
debuts behind one review point — obligations, two stats, `Eat`, `Drink`, beds,
`owner`, `Socialise`, plus a new person and a new place — with *"the first full
day"* as its single Moment. On a project with no test suite, a first-full-day
that reads wrong then has seven suspects and nothing to bisect with. Four gates
instead.

**Two amendments since, both 2026-08-12:**

- **Decision 25 moved `social` and the tavern OUT of 6a and into 6d**, where the
  first thing that reads them arrives. 6a lands hunger only. Decision 3 carries a
  banner pointing at 25.
- **Decision 26 inserted 6a2 between 6a and 6b** — `MakeBread`, because nothing
  in the world makes bread until 9b and food would otherwise be a fiction for the
  whole ladder. So this rung is five gates, and the total is sixteen.

**One item left this rung entirely:** beer. Buying a drink is person-to-person,
which is rung 7's seam, so shipping it here would ship a transfer path rung 7
deletes. `Drink` and beer are now rung 7.

---

#### Rung 6a — The body wants more than sleep

> **⚠ REVISED 2026-08-12 against Decisions 19–27. All four of this rung's open
> calls are now settled and the text below is the settled version.** `social` and
> the tavern are **gone from this rung** (Decision 25) and bread is authored
> differently than the old text said (Decision 26). If you are reading
> `_bmad-output/rung-6a-session-prompt.md`, note that it predates all of this.

**Seam:** a second drive competing with adenosine

- **Files:** `game/brain.gd` (one more line of upkeep), `game/actions/eat.{gd,tscn}`,
  `game/stats.gd` (`hunger`), `game/workstation.gd` (`owner`), and bread authored
  onto the two farmers in `game.tscn`.
- **ONE new stat, `hunger`**, rising in `Brain._update_body` beside adenosine —
  upkeep, never inside an action. Per world hour, like everything else
  (Decision 5). Give it the same **`get_…()` seam treatment** the two adenosine
  rates have, because illness, cold and a hard day's work all land there later.
  - **`base_hunger_per_hour = 4.0`**, awake and asleep alike — **one line, no
    branch**, and it is why he wakes up hungry (Decision 27).
  - **`hunger` runs 0–100 where 100 means "as hungry as a person gets", NOT
    "dead"** — exactly as 100 adenosine is not death by sleep deprivation.
    Starving is a **second, slower gap** that only begins once hunger is pinned,
    and it is **not built here** (Decision 27).
- **`Eat`, in *every* person scene by composition** — FR86 is explicit that the
  protected categories are present by construction and can only be outbid, never
  pruned. **It takes bread from his own inventory.** No transfer, no place, no
  owner, no trade — which is what keeps this rung clean of rung 7's seam.
  - **Gate: awake, and has bread. NEVER hunger** (Decision 22). *"Not hungry
    enough"* is want, not possibility, and putting it in a gate is barring in a
    new coat — the same mistake `stay_up.gd` already warns against. A man at
    hunger 5 loses to the waking baseline's 47.3 without any help, and leaving it
    out means `Eat`'s line is drawn rising and losing all day rather than as a
    gap, which is better instrumentation for a rung whose Moment is a graph.
  - **The `is_awake` gate is required.** Without it a man whose hunger crosses at
    03:00 gets up and eats in the dark, and it presents as a broken sleep cycle.
  - **One tick, one loaf** (Decision 23). `take(&"bread", 1)` and hunger drops by
    an authored amount, in a single tick. A timed meal needs somewhere to hold
    the meal-in-progress, which is the identical missing thing as the fractional
    loaf's home — one absence, two symptoms.
  - **A loaf fixes 50.** With the rate above that is **two meals a day**, and
    that cadence is forced by conservation, not by the curve (Decision 27).
  - **The score must be NON-LINEAR in hunger** (Decision 20). Two authored
    numbers, both plain English: **what starving is worth** — the one that
    decides whether a meal can ever interrupt work, and it must clear **103** if
    it ever should — and **how sharply it bites**. A straight line gives exactly
    the wrong day: it can never reach work's 103 from a 100 ceiling, while
    half-empty at 22:00 scores 50 and beats the baseline's 50.0, so he would
    nibble every evening and never eat by day.
  - **Nothing hunger does may touch another action's weight** (Decision 27). A
    damper on work was proposed and rejected — hunger drives some men to work
    harder, so the direction is not universal, which makes it personality rather
    than a lens.
  - **`WorkStep.get_yield_per_hour()` STAYS EMPTY.** Hunger does not modify
    production; *starving* will, when it exists. Rung 5 built that seam
    deliberately empty and it survives this rung intact.
- **Bread — fourteen loaves, authored on Zoogs and Hobb in `game.tscn`, NOT on
  `person.tscn`** (Decision 26). That scene is the template of a **body**, not of
  a life: stats belong there, possessions do not, and a newly created person
  owning nothing is the honest default. It also matches how rung 5 authored the
  Fields', the Inn's and the Plot's inventories. Fourteen is about a week at the
  cadence above.
  - **Consequence for the probe:** its spare people start with empty bags, and
    the *"a man with no bread cannot eat"* claim must still **empty a bag
    explicitly** rather than lean on that. Rung 4 paid for this twice — a check
    states the world it wants instead of inheriting one.
- **Ownership — `Workstation.owner`.** One exported field, needed by 6b's barn
  and by 9b/9c, **with no reader at all this rung.** The farm owner sets quotas
  for plots *he owns*, the tavern owner employs a baker at *his* oven, a merchant
  works *his* stall. It may be null — unowned land belongs to the king, which is
  the same answer as nobody until it isn't. **The Lord owns the Inn's twenty beds
  and has no body** (decided 2026-08-08); see the note under 6c.

**Probe:** hunger rises for a person doing nothing at all, **by exactly one
hour's worth in one hour** — assert the amount, not the direction. Eating drops
hunger **and consumes exactly one loaf**, both halves, so "he ate" cannot be
satisfied by a step that changes a stat for free. A man with no bread has `Eat`
**off his ballot entirely** (NAN in `get_last_scores`), not merely outscored —
and having no bread must not stop hunger rising. Hunger never goes negative.
`Eat` is on a freshly instanced `person.tscn` with nothing authored. And
**`adenosine` is never written from any file outside `brain.gd`** — statically
checkable, zero false positives.

*(The original probe said neither hunger nor social may be written from
`game/actions/`. That is wrong and would fail on correct code: `Eat` **must**
write hunger or eating does nothing. That is an effect, which the design
explicitly permits. Only adenosine is pure upkeep.)*

**Moment:** **two** drives on one graph and you watch which wins. The first time
the sleep cycle has a competitor that isn't a flat number — and the rung where
the curves actually get tuned.

**What the numbers above are predicted to produce**, so the Moment is a
prediction to check rather than a target to engineer: **two meals a day**, one in
the late morning that genuinely interrupts work, one in the evening gap after
work falls and before sleep wins. Meals land in the **valleys of the waking
ladder** because that is the cheapest hour on it — supper is emergent, not
authored. **Bedtime does not move**: `Eat` can hold the top waking bid for
exactly the one tick it takes to eat, so 22:01 shifts by at most 0.01 world hours
(Decision 20).

**Watch this at a SHORTENED day (Decision 13.)** This Moment happens ONCE A DAY, and rung 3 proved the shortened day is the instrument for exactly that shape — drag `day_length_seconds` down and the beat repeats often enough to see it hold. At the shipped 60 s a once-a-day crossing is over before you have focused on it, and "I did not see it happen" reads as a broken seam. *(Rung 4 is the one rung that wants the OPPOSITE — a LONG day — because a ten-minute commute at 60 s takes 0.4 real seconds. Match the instrument to whether you are watching one slow event or a repeating beat.)*

**Do not build:** `Drink`, beer, buying anything, or the tavern's storage being
anybody else's — that is rung 7. **`social`, `Socialise` and the tavern itself —
that is 6d** (Decision 25). **`MakeBread` — that is 6a2, the very next gate**;
this rung's bread is authored and does not run out inside a probe run.
`Obligation`, quotas, `is_permitted_to()` — 6b (`owner` ships as a field with no
reader, and that is the whole of it). Beds — 6c. **A hunger quota, or any attempt
to unify hunger with Decision 1's `target − stock`** — Decision 19 says they are
the same rule but closing that is not this rung's job. **Starving**, and anything
that reads it — Decision 27. Cooking, recipes, food that spoils, an item
database, weight, carry capacity.

---

#### Rung 6a2 — The world learns to feed itself

**Added 2026-08-12 (Decision 26). Runs BETWEEN 6a and 6b.** Named out of sequence
on purpose: the decisions file is append-only and references `6b`, `6c` and `6d`
by name in a dozen places, so renumbering them would make settled text silently
wrong with no sanctioned way to fix it. Its subject is 6a's — 6a makes a man
hungry, 6a2 makes the world able to feed him.

**Seam:** the first closed loop in the project

**The hole it fills.** The ladder routes bread as *6a authored → 7 bought from
the tavern → 9b the baker actually bakes it* — and at 7 the tavern's bread is
**also authored.** So nothing in the world MAKES bread until 9b, the
second-to-last gate, and food is a fiction for the entire ladder. The real chain
is grain → miller → flour → tavern owner → baker → bread, five links, none of
which exists yet.

- **Files:** `game/actions/make_bread.{gd,tscn}`, in `person.tscn` beside `Eat`.
- **Anyone with grain can bake.** Crude and dear next to a baker's oven, which is
  exactly what makes a baker worth employing at 9b rather than a formality.

| | |
|---|---|
| **Gate** | awake, and has grain. |
| **Score** | the **same hunger gap `Eat` uses, at a lower weight** — with bread in the bag he eats; with none he bakes. |
| **Step** | **one tick: take 3 grain, add 1 loaf.** |

- **NOT a workstation, and that is a constraint rather than a preference.**
  `WorkStep.YIELD_NAME` is a `const`, and rung 5 refused to export it on the
  stated grounds that a station making something other than grain *"comes from a
  Recipe (rung 9a), which owns the output and the time it takes together."* A
  hearth lands 9a's Recipe five gates early against a recorded refusal.
- **Which is why it cannot cost world time yet.** Duration needs somewhere to
  bank the fraction; that is a station; that is the Recipe. **The cost is paid in
  grain, not hours** — three to one against a baker's one to one — and that
  ratio *is* the make-or-buy weight, needing no extra mechanism.

**Probe:** grain in, bread out, at three to one, conserving nothing — this is
`add` and `take`, a creation and a destruction, and the world total legitimately
moves at both. A man with grain and no bread bakes; a man with bread eats rather
than bakes; a man with neither does neither and goes on getting hungrier.

**Moment:** **work → grain → bread → eat → work.** The first complete loop the
project has, with no authored fiction anywhere in it.

**And the measured reason this gate is early rather than late.** Rung 5
established that Hobb takes the plot every day and gains ~16 grain, and **Zoogs
never takes it and gains zero.** So Zoogs eats his fourteen loaves and then has
nothing, no grain, and no way to get any. **The man who loses the dawn race
starves** — the first time contention has a stake instead of a bigger number over
somebody's head. Nothing punishes him for it yet (starving is Decision 27 and is
not built), and that is fine: the point is that the sim now *says* it.

**Left open — make-or-buy, properly.** Scoring `MakeBread` off the hunger gap
makes him hand-to-mouth: he only gets bread once he is already hungry. The better
form gives bread a **stock target**, so making and later buying both score off
`target − stock` (Decision 1) and he restocks on a quiet afternoon. That wants
6b's quota machinery and is a natural thing to fold in there.

**Do not build:** a hearth, a recipe, an oven, cooking times, flour as a separate
item, bread quality, or buying anything.

---

#### Rung 6b — The quota

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
collapses, and something else wins.

**Discharge goes to a Place, not to a person** (Decision 3). The obligation
already names a `place_name` as its FR100 target, and rung 5 already put an
`Inventory` under `Place`. **The farmer drops the sacks in the barn**, and
`owner` from 6a is what makes the barn the farm owner's. That is better fiction
*and* it means this rung ships no person-to-person transfer for rung 7 to
duplicate. The farm owner later sells *from the barn*.

**`Workstation.is_permitted_to(person)` lands here**, now that there is
something for it to read:

```gdscript
# Can he work here at all? Three ways in — and employment is one of them.
func is_permitted_to(person: Person) -> bool:
	if owner == null:    return true    # common land — the king's, i.e. nobody's
	if owner == person:  return true    # his own mill, his own forge
	return person.has_obligation_at(get_place())
```

`is_free_for()` asks this too. So no obligation → the owner's plots are not
candidates → work is not on your ballot. **Employment grants access to land** —
without it, any farmer could walk onto anyone's land and keep the grain.

**It must be asked in GATE every tick.** It is the first capability in the game
that can vanish *mid-work*: an obligation expiring at noon revokes land access
while the man is standing in the furrow, and a step that assumes permission
persists will keep working land he may no longer touch.

**Nobody dispatches the work.** The owner issues an obligation naming a
**place**; the worker picks the **station**; the station merely records who has
it. The owner never picks a plot — doing so needs an allocation procedure, which
is the labour-clearing strategy already deferred (RANDOM / FIFO / CHARISMA_PICK /
PRODUCTIVITY_RANK, deferred 2026-05-16), arriving through a side door. It would
also be *"a manager that walks people and tells them what to do"* wearing a hat.

**Probe:** a farmer with an unmet quota chooses work over rest at equal
tiredness; the same farmer at quota does not; an expired obligation leaves the
candidate set (FR103) rather than remaining owed; discharge moves grain into the
barn's inventory and conserves the total; a farmer with no obligation finds the
owned plot is not a candidate.

**Moment:** **work's utility falls off the graph.** He hits quota mid-afternoon
and the `WorkForHire` curve collapses while something else climbs to take it —
one legible crossing on the instrument you already built. This is probably the
single best gate in the plan, and it was previously buried under six other
debuts.

**Watch this at a SHORTENED day (Decision 13.)** This Moment happens ONCE A DAY, and rung 3 proved the shortened day is the instrument for exactly that shape — drag `day_length_seconds` down and the beat repeats often enough to see it hold. At the shipped 60 s a once-a-day crossing is over before you have focused on it, and "I did not see it happen" reads as a broken seam. *(Rung 4 is the one rung that wants the OPPOSITE — a LONG day — because a ten-minute commute at 60 s takes 0.4 real seconds. Match the instrument to whether you are watching one slow event or a repeating beat.)*

**Do not build:** wages, contracts as a type, renegotiation, a quitting action,
reputation, or a social graph. One obligation, one number, one expiry.

---

#### Rung 6c — A bed of your own

**Seam:** `claim()` proving it was never really about labour

- **Beds are `Workstation`s.** Twenty of them at the Inn, claimed one per
  sleeper through the *same* `claim()` from rung 3 — the cheapest possible proof
  that the labour-clearing seam wasn't secretly about labour. `Sleep` gains a
  place requirement; a man with no bed free is a man with a problem, and that
  problem is content later.
- **This is the only rung that exercises a claim across a day boundary**, which
  is the exact case renew-on-use was repaired for (Decision 2): a man claims a
  bed at 21:00 on day 3, dawn breaks on day 4 while he is still asleep, and
  without renew-on-use his claim expires underneath him and somebody else takes
  the bed he is lying in.

**Probe:** twenty-one sleepers at a twenty-bed Inn leaves exactly one man
standing; **a sleeper still holds his bed after a day boundary passes
mid-sleep**; an abandoned bed does not survive one.

**Moment:** one man left standing in the doorway while twenty sleep.

---

#### Rung 6d — Socialise, and the first full day

**Seam:** candidates that are *people*, not stations

- **`social`, its upkeep line, AND the tavern land HERE, not at 6a**
  (Decision 25, which amends Decision 3 and put a banner on it). They were
  scheduled for 6a alongside hunger, but nothing reads `social` and nobody enters
  the tavern until this gate — a stat that cannot bid and a building nobody
  visits are both substrate before need, and 6a's promised *"three drives
  compete"* Moment would have been two drives and a spectator line. **They arrive
  with the first thing that reads them, which is `Socialise` below.** The stat is
  one line in `Brain._update_body`, per world hour like every other rate, and
  under Decision 19 it is the gap between the company he wants and the company he
  has had.
- **`Socialise`** — scored off `social`, candidates are places that currently
  hold other people, via `Town.find_people_at()` from rung 2. This is what a man
  with nothing to do does, and it must name no place: the tavern wins in the
  evening because that is where everyone is, and the square wins at midday for
  the same reason. **Watch for a herd.** People-attract-people is positive
  feedback, and the whole town converging on one room is the same stable
  equilibrium that got split-yield rejected. The damper is already specified —
  `Socialise`'s candidates are ordered by travel cost, so a far crowd loses to a
  near one. **Note the mechanism carefully: travel cost orders one action's
  CANDIDATES and never enters `Socialise`'s own score** (Decision 15). This line
  used to read "travel cost is a score term (rung 4)", which would put a commute
  into the comparison between socialising and everything else and let geography
  veto a want. If it herds anyway, that is a curve to tune, never a rule to add.

**Probe:** a man with nothing else on his ballot walks to the place holding the
most people, cost-weighted; **after N simulated days no single place ever held
more than X of Y people** — the falsifiable version of "watch for a herd".

**Moment:** **the first full day.** A farmer works, hits quota mid-afternoon,
walks east across the square to the tavern, gets tired, walks to the Inn,
sleeps. You can watch one man's whole day without touching anything, and every
transition in it is a decision that was outbid rather than a script.

This is now a **composition** moment rather than a debut moment — everything in
it already shipped and was gated separately, which is what a capstone should be.
*(The camera was pulled back at rung 4 precisely so this is watchable.)*

**Watch this at a SHORTENED day (Decision 13.)** This Moment happens ONCE A DAY, and rung 3 proved the shortened day is the instrument for exactly that shape — drag `day_length_seconds` down and the beat repeats often enough to see it hold. At the shipped 60 s a once-a-day crossing is over before you have focused on it, and "I did not see it happen" reads as a broken seam. *(Rung 4 is the one rung that wants the OPPOSITE — a LONG day — because a ten-minute commute at 60 s takes 0.4 real seconds. Match the instrument to whether you are watching one slow event or a repeating beat.)*

---

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

*(This note belongs to 6c — the Lord's beds — but applies to every owned thing
in the town. `owner` itself lands at 6a because 6b's barn needs it.)*

---

> **⚠ WHAT RUNG 6 AS BUILT MOVED UNDER EVERYTHING BELOW (2026-08-14, rungs
> 6a–6d shipped).** Read before building any later rung; each of these makes
> some text below stale where it disagrees.
>
> - **`Workstation.owner` is `owned_by` in code.** `owner` is a built-in
>   property on Godot's `Node` and redeclaring it is a compile error. Every
>   snippet below saying `owner` means `owned_by`; `Place` has no owner field
>   at all yet.
> - **The tick order is decide → DO → update as of 6c**, because "is he
>   asleep" became a fact the do phase writes (arriving at a bed, claiming
>   it). The body pays for what the tick actually contained. Anything below
>   reasoning about "update then do" is stale; see `brain.gd`'s header.
> - **The settled schedule moved at 6c by exactly the commute**: turning in
>   now happens at bed-arrival in the Inn, so the settled day reads **22:19 /
>   8.00 h / up 06:19** (cold start 21:17 / 05:55) against the old 22:01 /
>   06:01. Probe claim 13 pumps eleven hours for the same reason. Numbers
>   below quoting the old schedule describe the pre-6c world.
> - **The quota is DAILY.** `Obligation` lazily resets its delivered count at
>   the day boundary (`delivered_on_day`, the same pattern as the tenancy
>   stamp), so the quota beat repeats every day with nothing sweeping.
>   Expiry is employment ending and closes the GATE (off the ballot, FR103);
>   discharge only zeroes the SCORE (outbid, never barred — Decision 22).
>   9b's baker and brewer obligations inherit all of this.
> - **`WorkForHire` extends `WorkTheField` and replaced it on the authored
>   farmers.** The library still has `WorkTheField` for common land; nothing
>   authored uses it. `WorkForHire` scopes its candidates to the obligation's
>   named place, and its step delivers each whole grain into the place's
>   inventory capped at what is still owed today — **the surplus a man holds
>   past quota stays his, and that is rung 7's tradable stock.**
> - **Marle, the farm owner, exists (6b) and is authored AT THE TAVERN
>   (6d).** An empty place is never a Socialise candidate, so the tavern
>   needed an occupant to ever be visited — the owner idling there is the
>   bootstrap. Rung 7's "farm owner walks to the square" starts from the
>   tavern.
> - **`Sleep` is candidate-gated on beds** (twenty Workstations under the
>   Inn, `work_name` "sleeping", unowned — the Lord has no body), and
>   `Action` grew `counts_as_asleep_for(person)`: the flag says what KIND of
>   action, the method says whether doing it right now means he is out. A
>   nap, a faint or a knockout that depends on circumstance overrides the
>   method, not the flag.
> - **`Town` has a third pressure counter**, `was_not_permitted_pressure`,
>   written when permission (not room, not existence) refused a candidate —
>   Decision 24's rights-problem kind, landed with `is_permitted_to`.

### Rung 7 — Trade needs two bodies in one place

**Seams:** want (`target − stock`) · `Trade` action · `can_afford(person, price) -> bool`

- **Files:** `game/actions/trade.{gd,tscn}`, `game/actions/drink.{gd,tscn}`.
  **`coin` is an `Inventory` item, not a stat** (Decision 6 / rung 5) — putting
  it in `stats.gd` would split possession across two systems permanently and
  make every conservation probe check both.
- **Scene:** the market square, the mill (as a place), the farm owner, one
  merchant. **Beer and `Drink` arrive here**, moved down from rung 6 — buying a
  drink is person-to-person, so it belongs in the rung that invents the
  mechanism.
- `can_afford` returns `true` unconditionally, today. The call site is the point.

**⚠ Cast note.** The plan originally put the *miller* in this rung. Under
Decision 1 a want is `target − stock`, and the miller's grain target comes from
his flour quota — which needs `Grind`, which is **rung 9a**. So at rung 7 the
miller has no representable want and cannot be traded with. **The merchant can**
— his trading stock level is his own target. Rung 7's trade is therefore
**farm owner → merchant**, and the miller arrives with the millstone at 9a.
*Flagged rather than assumed: if you want the miller here, he needs a stock
target authored on him, which is legal (surface #2) but is a decision.*

**Want, and its mirror** (Decision 1 / Decision 6). One rule, both directions:

```
deficit = target − stock     →  what I will buy
surplus = stock − target     →  what I will put on the table
```

So **"everything on the table" is everything above your target** — a merchant
lays out his surplus grain and keeps his dinner; a farmer with a quota to fill
is not selling the grain he owes. Nobody authors a for-sale list and nobody
accidentally sells their own food.

**One generic `Trade` Action; the work is in its ActionStep.** No `Serve`, no
per-profession variants. In one tick: *put your surplus on the table, declare
your deficits, match, move the goods.* The match is a **loop, not a market**:

```
for each item I have a surplus of:
    if he has a deficit of it:
        move min(surplus, deficit)
```

**Bilateral — two people, one place, one tick.** The moment it becomes "collect
everyone's offers and find the global optimum," it is the market-clearing
algorithm already deferred twice, arriving through a third door.

**One step, not a sequence.** Same pattern as rung 4: *not at the square → walk
toward it; at the square → lay out and match.* `Sequence` and `Choice` are not
ported from git history and this does not need them.

> **REUSE THE WALKING, DO NOT REWRITE IT.** Rung 4 shipped `GoToStep`
> (`game/actions/go_to_step.gd`) with a `walk_toward(person, place, hours)` verb,
> and reuse is the whole reason it takes its destination as an argument instead
> of an `@export`. **Nest one under this rung's step, as a CHILD, never a
> sibling** — `Action._ready` takes the *first* `ActionStep` child it finds, so
> two steps under one Action silently pick one and ignore the other. The same
> applies to **6a** (walk to the tavern) and **6d** (walk to the crowd). A second
> movement implementation is also a second place `current_place` gets written,
> and `GoToStep` owning both edges of that field is what keeps *"same place?"*
> honest for the trade gate below.

**`Trade.find_candidates()` returns people at my place with a deficit I can
fill.** Not a global lookup — that is the one thing that would break it, because
it makes failure impossible and deletes the reason the square exists.

**And the receiver must be *able* to trade** (Decision 6). Want is read off the
other man's state, not off his decision — his brain never runs. Without a gate
on his side, **a merchant could trade with a sleeping man.** So his own `Trade`
must be available to him right now: awake, present, not otherwise gated. Not
that he chose it. That he *could* have. *(This is the amended banned shape — you
may exchange with a man who could have chosen this, never with one who
couldn't.)*

**The tavern owner serving beer is this same action, and that is not a
coincidence — it's the unification worth checking the rung against.** A thirsty
farmer at the bar has a beer deficit; the owner is standing there with a beer
surplus; the trade happens because both bodies are in one room. No `Serve`
action, no service system, no counter. Which means the owner cannot serve while
he is at the market square buying flour — and *that* is Samus's drunk-mill-owner
beat arriving on its own, out of a seam built for something else. If serving
needs its own mechanism, rung 7 got the candidate query wrong.

**Probe:**
1. Two people in the same place, one with surplus grain and one with a grain
   deficit, exchange goods and coin — **conserving both totals**.
2. The same two people in *different* places do not, and `Trade.is_available_to`
   is false.
3. **A sleeping man is not a trade candidate**, even with a matching deficit.
4. A man whose deficit is 3 does not receive 10 — the match moves
   `min(surplus, deficit)`.
5. Two people who each want to trade with the other exchange **exactly once per
   tick**, and totals are conserved. *(Self-correcting because nothing is
   stored: after the first `hand_over` the deficit recomputes to zero. Worth
   pinning so nobody later "fixes" it with a per-tick trade flag, which would be
   stored progress.)*

**Moment:** the farm owner walks to the square with grain, the merchant walks to
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
and `HaulGoodsYourself` wins; **inject one hauler and hiring wins instead,
with no other change** — this is the assertion that proves the seam rather than
the feature.

*The injected hauler is a real `person.tscn` with one extra Action node under his
Brain — **never a mock.** Rung 0 bans fixtures, and composition is this plan's
own thesis. It doubles as standing check #2: a fourteenth person who participates
immediately with no code written for him.*

**Moment:** a man pushing his own wagon across the square. It reads as ordinary
until you know that the game asked whether anyone would do it for him and the
answer was nobody — which is what a missing labour market actually looks like
from the inside.

**Do not build:** a hauler profession, wagon capacity, routes, or logistics.
The zero is the content.

---

### Rung 9 — The chain, and the scythes nobody buys, in four gates

**Split 2026-08-09 (Decision 8).** Mostly repetition, and that is the point: if
the seams are right, five professions are five data rows and no new systems. But
**as one rung you find out about all five at once and cannot tell which seam was
wrong.** Split, 9b failing means the `Recipe` seam is wrong and 9d failing means
something got scripted — two different diagnoses.

**Two of these four are negative gates: they pass by requiring no code.** That is
a different kind of gate from every other rung, and it is the only way this
plan's central claim gets *tested* rather than asserted.

---

#### Rung 9a — Work that takes time

**Seam:** `Recipe` (shared authored data) + `Workstation.progress` (world state)

> **⚠ THAT WORLD-STATE FIELD ALREADY EXISTS. RUNG 5 SHIPPED IT** as
> `Workstation.output_part_made`, and this rung must **subsume it, never sit
> beside it.** Two accumulators on one station is two answers to "how far along
> is this", and the one the step reads will not be the one the probe sums.
>
> Why it landed four rungs early: a count is a whole number and a tick is a
> hundredth of an hour, so a plot yielding one grain an hour makes 0.01 of a
> grain per tick. Truncated, every tick of work rounds to zero and a man farms
> all day for nothing. Rung 5 needed the fraction to survive a tick, and
> Decision 6 already says where work-in-progress lives — on the world object,
> never on the person.
>
> **What to check when you widen it.** It is denominated in **units of the
> output**, not in hours of work, so a `Recipe` carrying `hours_of_work` is a
> change of unit as well as a change of owner — decide which the field holds and
> say so at the declaration. Nothing resets or sweeps it, deliberately, which is
> already the behaviour this rung's own probe asks for: *"a miller interrupted
> mid-grind and replaced by a second miller resumes from the same progress."*
> Rung 5 gets that free — walk off a part-turned furrow and the fraction stays
> in it for whoever claims the plot next.

- **Files:** `game/recipe.gd` (`Resource` — same for everyone, so a Resource per
  `CLAUDE.md`'s Node-vs-shared-file rule), one `.tres`; edit
  `game/workstation.gd`.
- **Scene:** the mill's millstone, and the miller arrives as a body.

```gdscript
# Recipe — what a workstation turns into what, and how long it takes.
@export var inputs: Dictionary       # {&"grain": 1}
@export var output_name: StringName
@export var output_count := 1
@export var hours_of_work := 1.0     # HOURS, per Decision 5 — never real seconds
```

**Inputs move onto the station when work starts**, into the `Workstation`'s own
`Inventory` (mounted at rung 5). Otherwise a miller who walks off mid-grind takes
his grain with him and leaves progress behind — a conservation leak, and a
half-ground sack that exists nowhere cannot be watched, counted or probed. On the
stone it is a sack on a stone, which is content. **Nothing cleans it up**; a
decay timer would be an ambient world tick, which is a banned shape.

**Probe:** grain in yields flour out, conserving totals; **a miller interrupted
mid-grind and replaced by a second miller resumes from the same progress**;
**sum every inventory in the world — people, places, stations — before and after
an abandonment, and the total is unchanged.**

**Moment:** a man walks away from a half-ground sack, and it is still sitting on
the stone when somebody else picks it up.

---

#### Rung 9b — Four more conversions, and no new code

**Seam:** none. **That is the gate.**

- **Scene:** the tavern's oven, the smithy, the townswood and its chopping block;
  the baker, brewer, blacksmith and wood chopper arrive.
- Baker and brewer are in the tavern owner's employ, which is an `Obligation`
  from **6b** with a different place target — not a second kind of contract.

| Workstation | Recipe |
|---|---|
| oven | flour → bread |
| bar | grain → beer |
| chopping block | log → sticks |
| anvil | iron ore → iron plate |

**This rung is four `.tres` files and four `person.tscn` instances.** Writing any
GDScript here is **a finding about 9a, not a task** — it means the `Recipe` seam
was wrong, and you can only learn that if 9a shipped separately.

**Probe:** each recipe converts its inputs to its output conserving totals; **the
diff for this rung contains no new `.gd` file.**

**Moment:** bread and beer appear in the tavern's storage because two men worked,
and the tavern owner starts buying flour because his stock target says so.

---

#### Rung 9c — The stall, and the scythes

**Seam:** the first **two-input** recipe

- **Scene:** five stalls in the square; the second merchant arrives.

| Workstation | Recipe |
|---|---|
| merchant stall | sticks + iron plate → **scythe** |

The merchant gains a `TravelForStock` action: he leaves town, returns with iron
ore, and sells it to the blacksmith. Cheap, and it gives the town its first
offscreen event — the smithy can now go idle for reasons nobody in town
controls.

**Farmers are not taught `BuyScythe`.** Not gated shut — simply not in their
repertoire. That is `learn()` doing real work. **And under Decision 1 it is now
observable rather than asserted:** the merchant lays scythes on the table, every
farmer lays out his surplus and his deficits, and **no farmer's deficit ever
contains a scythe** — because a scythe is not consumed or converted by anything,
so no target of his contains one. Same loop, no match.

**Probe:** the stall, given sticks and plates, produces a scythe — deterministic;
**no farmer ever knows `BuyScythe`** — a repertoire assertion, exact, and it *is*
the thesis.

*(The plan previously asserted "after N simulated days the merchant's scythe
count is greater than zero and every farmer's is zero." That is an integration
assertion over ~40 tuning inputs and will go red for tuning reasons constantly. A
slow whole-economy assertion is the flaky test that erodes trust in the other
twenty. **Demoted to a Moment**, where it belongs.)*

**Moment:** scythes accumulate on the stall. Watch the count climb on the graph —
which is why coin and items live in `Inventory` and why `stat_graph` learned to
plot them at rung 5.

---

#### Rung 9d — Thirteen people, and no new code

**Seam:** none. **That is the gate**, and it is standing check #2 as a rung.

- **Scene:** the fields go back up to four plots; two more farmers arrive; the
  roster reaches **thirteen**. Miller and smith drink at night against their own
  production targets.
- **No new classes, no new code.** Each person is `person.tscn` with a different
  set of Action scenes under his Brain and different starting stats. **If any of
  them needs a script, a seam below was wrong** — and now you know which rung to
  look at.

**Probe:** **the diff for this rung contains no new `.gd` file**; delete a person
mid-run and the town carries on; add a fourteenth and he participates
immediately.

**Readouts don't scale to thirteen.** Thirteen billboarded `Label3D`s each
printing name, action, awake and five stats is unreadable at town distance, and
`stat_graph` watches one person. Cheapest fix with no new files: set
`Label3D.visibility_range_end` on `person.tscn` so readouts appear only up close,
and fly the camera.

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
detection deliberately not built; see the note under rung 6c. Original framing: There is a Lord in your town who
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
