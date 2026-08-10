# Proving Scene — Decisions

Companion to `proving-scene-build-plan.md`. **The plan is not yet revised.** This
file records what was settled, why, and what it changes — so a revision pass (or
a delegate who wasn't in the room) can apply it without re-deriving it.

One section per settled question. Append, never rewrite.

**Source:** roundtable 2026-08-09 — Cloud Dragonborn (game architect) and Link
Freeman (game developer) reviewed the plan against `CLAUDE.md` and the live
substrate in `tkyds-game/game/`. Four disagreements came out of it. This file
tracks their resolution.

---

## The frame everything below is expressed in

The tick has three phases, and the whole design is easier to reason about when
stated in them:

```
DECIDE
  GATE   Action.is_available_to(person)      →  can I, at all?
  SCORE  Action.get_utility_score(person)    →  how much do I want it?
UPKEEP   Brain._update_body(delta)           →  what happens regardless
DO       current_action.step.advance(...)    →  make it so
```

**Gate and score are reads. DO is the only write.** Everything the ladder adds
is either a new thing to read during DECIDE, or a new thing to write during DO.
The loop itself never changes shape — rung 1 inserts `Population` above it and
that is the only structural change in the whole arc.

An **Action is a family, not a single choice.** `WorkTheField` means "work
*which* plot"; `Trade` means "trade *with whom*". So each action has a
`find_candidates()`, and the phases consume its answer differently:

- **GATE** — came back empty? Off the ballot entirely.
- **SCORE** — how good is the best candidate? That's what the action is worth.
- **DO** — act on that best candidate.

This is why "hardcoded trade partners" is a banned shape: the farm owner sells
to the miller because `find_candidates()` returned him, not because anything
names him.

---

## Decision 1 — Where "want" comes from

**Settled 2026-08-09. Author's call. Do not reopen.**

### The question

Rung 7's `Trade.find_candidates()` returns "people at my place who want what I
have." Nothing in rungs 1–6 gives a person a representable want. `Demand` is
listed as a freed `class_name` that no rung uses. **What does a person actually
look at to answer "does he want this?"**

### What was proposed, and rejected

| Proposal | Shape | Why not |
|---|---|---|
| A `Demand` class | stored wants | **Rejected by both reviewers independently.** A stored want is a second copy of a truth you can recompute, and it goes stale. `prd.md` already forbids it: *"Demands have no bespoke persistence layer."* `Demand` stays an unused `class_name`. |
| Cloud: `Action.get_appetite_for(person, item_name) -> float`, polled across the repertoire | want derived from capability | Answers *"would you take grain?"* — no quantity. Every action must learn to answer about every item. Costliest per tick. |
| Link: `@export var buys: Array[StringName]` on `Trade` | want as authored data | Binary. Can gate a trade but can't score one. A farmer could be given `buys = [&"scythe"]` by accident and would buy a thing he has no use for. |

### What was settled

> **Want = target − stock.**
>
> The target is a **quota**. Quotas are **plain authored numbers** for now.

One rule, one arithmetic, computed fresh in GATE every tick. Nothing stored.

It produces a **quantity**, not a yes/no — which is what neither reviewer's
proposal gave. The miller's shortfall *is* how much he wants to buy, and it's
also what makes him grind. Want and work come from one cause; there is no second
authoring surface.

Both reviewers abandoned their own proposals for this one.

### Consequences

- `Trade.find_candidates()` finally has a defined predicate. It ships **with**
  `Trade` — it is not an addition to that rung, it is the thing that rung was
  missing.
- **The merchant fits** — his trading stock level is his target, self-set. Cloud
  had flagged the merchant as an open gap; the stock-target framing closes it.
- **Deficit must be recomputed after every exchange inside the same tick.** Sell
  a man three sacks and his want is now smaller. Nothing may cache it between
  the ask and the transfer. (Link)
- **The scythes are unaffected, and now have a better reason.** Nobody's target
  contains a scythe, because a scythe isn't consumed or converted by anything —
  it's a tool that changes a rate. `find_who_wants(&"scythe")` is empty for a
  stateable reason rather than by assertion. The ending survives intact, and the
  category it needs (durable goods) is already deferred by the plan.

### The two seams — named, empty, uncalled

The author's concern: if every quota is an authored constant, the chain only
**pushes**. Nobody produces *because* someone wants a thing, so the town is
thirteen treadmills running at typed-in speeds. That is real, and it is
deliberately **not solved in this arc**. It is made cheap to solve later:

**Seam 1 — record.** Something accumulates **unmet demand** and **excess
supply**. Not built, no reader, nothing calls it.

**Seam 2 — revise.** Something reads that accumulation and moves a quota
*level*:

```gdscript
# The one place a quota level is ever revised. Today: nothing — quotas are
# authored and stay where you typed them. When unmet demand and excess supply
# are recorded, and when somebody holds the authority to act on them, this is
# where that lands. Nobody calls it yet, and that is correct.
func reconsider_quota_levels() -> void
```

The quota's value stays authored and acts as a **floor** — never produce less
than this. The seam is only about what could later raise or lower it.

### Why stale aggregate demand is acceptable, when a stale want is not

This distinction is load-bearing and will be re-litigated by anyone who reads
"store nothing you can work out again" without it:

| | Derivable from a snapshot? | Storing it is |
|---|---|---|
| *"The miller wants 7 grain right now"* | **yes** — quota minus stock | a **cache**. Rots the instant he buys. Forbidden. |
| *"This region drank 400 beers last month"* | **no** — no snapshot contains it | a **measurement**. Its age is a property, not a defect. |

And the slowness is the mechanism, not a compromise. A brewery responding to
last month's sales overshoots, gluts, and runs dry — which is the drama. One
responding instantly to who is thirsty right now is a treadmill with extra
steps. **The lag is the point.**

Precedent already in the plan: rung 3's two idleness counters (*"there was no
field"* / *"every field was taken"*) are the same class of fact, kept for the
same reason — a failure that already happened cannot be reconstructed from world
state. Any demand record must be an **accumulator, never a history** — one
decaying number, not a list of nights. A list is the decision log the plan names
as its only unbounded complexity class.

### Where the revise seam hangs — and why it matters more than it looks

Quota revision comes from **the king, the Lord, or the player once they have
influence**. So it belongs on neither the worker nor the town. It belongs on
**`Workstation.owner` / `Place.owner`** — already entering at rung 6, currently
justified only as "the farm owner sets quotas for plots he owns."

`owner` now earns its place twice, and the second reason is the larger one:

> **A quota level is where authority touches the economy.** Setting one is the
> most consequential act an owner has, and it needs no body, no presence, and no
> dialogue. An off-map Lord raising a quota is a complete political act
> expressed entirely in mechanism that already exists.

For a game called *The King You Don't See*, that is load-bearing. Rung 6's
existing note — *"The Lord owns the Inn's twenty beds and has no body… the
largest unexamined lever in the town"* — is describing this lever without
naming it.

### Deliberately left open

- **Where demand originates, if not from authored targets.** The pull-chain
  question is real and is explicitly deferred, not answered. Seams 1 and 2 exist
  so that answering it later moves no call site.
- **Whether hunger and thirst are the same rule.** "Deficit against a target,
  one from a quota, one from a body" reads identically and both reviewers noted
  it. **Not decided.** Collapsing the body into the quota system would make
  needs and economics share a mechanism and lose the ability to tune them
  separately.
- **The notice board** — a `Town.find_who_wants(item_name)` that answers *who to
  go ask* (identity only, never quantity, recomputed on demand). Judged a real
  upgrade — it moves discovery from DO ("he wandered into the square and
  happened to find a seller") up into GATE ("he knows before he leaves, so the
  walk has a cause"). **Deferred to its own rung after `Trade` works
  face-to-face**, on the plan's own logic: a seam earns itself by a collision
  you witnessed. Ship the loop, not an index; the index is the graduation.

### Plan edits this implies

Not yet applied.

| Section | Change |
|---|---|
| Rung 7 (`Trade`) | `find_candidates()` gets its predicate: candidates are people at my place whose `target − stock` for what I hold is greater than zero. |
| Rung 6 (`Obligation`) | `owed_count` stays a plain authored `@export`. Add `reconsider_quota_levels()` as a named, empty, uncalled seam. |
| Rung 6 (`Workstation.owner`) | Add the second justification — owner is where quota revision will hang, i.e. where authority touches the economy. |
| Seam ledger → *Installed* | Add: **Want** — `target − stock`, rung 7, shipped with `Trade`. |
| Seam ledger → *Refused* | Add: **demand recording / quota revision** — refused for this arc, seams named and empty. Distinguish from the already-refused prices, haggling, clearing, order book, which stay refused. |
| *Don't script the simulation* | The three authoring surfaces are unchanged. Quota numbers are surface #2/#3 doing their job — a number is authoring; a branch on who you are is a script. |
| Interpretation note (FR100) | Extend: an obligation reaches the ballot as before; what's new is that its *count* is the quantity a want is measured against. |

---

## Decision 2 — How a workstation claim expires

**Settled 2026-08-09. Author's call. Do not reopen.**

### The question

A `Workstation` is a spot one person uses at a time — a field plot, a
millstone, an anvil, a bed. When somebody takes it, the station records who has
it. The plan already ruled that legitimate world state (see its *"Two doctrine
calls Fable must not re-make"*): who has their hands on the millstone is a fact
about the millstone, not a plan stored on a person, so it doesn't break *"store
nothing you can work out again."*

**But a record that never expires is a booking**, and a booking is stored
intent. So the plan made it a **per-tick lease**: the working step re-calls
`claim(person)` every tick, and `Population` releases every station nobody
renewed at the end of the tick.

**The question is how that record expires.**

### What was proposed, and rejected

| Proposal | Why not |
|---|---|
| **Plan as written** — `Population` sweeps every workstation at end of tick, releasing anyone who didn't renew | Couples the thinking dispatcher to world maintenance, and needs a second registry of every station. Decisively: **it is incompatible with the frame-stagger rung 1 exists to enable.** If a person thinks every 4th frame, he fails to renew on 3 of them and the sweep evicts him from a plot he is standing on and actively working. You would install rung 1's seam and simultaneously guarantee it can never be used. (Cloud) |
| **Timestamp lease** — the station stores when it was last touched; the claim lapses after `lease_seconds` of real time | Immune to stagger, but needs every station to reach the `Clock` (a hand-wired reference, i.e. the `node_paths` trap that already shipped a dead day/night cycle in this project once), and `lease_seconds` becomes a number secretly coupled to a scheduling policy that doesn't exist yet. (Cloud) |
| **Sweep, but on `Town` instead of `Population`** — keeps the sweep, moves the ownership | Fixes the coupling, does not fix the stagger incompatibility, which went unanswered. (Link) |

Both of the above answer *"how does a one-tick lease expire?"* — and the
settled answer removes the one-tick lease, so neither is needed.

### What was settled

> **A claim is a day-long tenancy, not a per-tick lease.**

```gdscript
# workstation.gd

# Who has this spot, and which day he took it. Two fields — and the second is
# what makes a claim expire without anything ever sweeping: a claim stamped
# yesterday simply isn't a claim today.
var claimed_by: Person = null
var claimed_on_day := -1


# Free, or already his. Asked in GATE, every tick, by everybody.
func is_free_for(person: Person) -> bool:
	# A holder who has been freed is not a holder. queue_free() does not null
	# your reference — `claimed_by == null` stays false and the next property
	# read errors. Without this the town reserves a plot for a dead man and the
	# plan's own standing check ("delete a person mid-run") crashes instead of
	# returning a verdict.
	if not is_instance_valid(claimed_by):
		claimed_by = null
	if claimed_by == null:
		return true
	if claimed_on_day < clock.day():
		return true                      # yesterday's claim, expired where it lies
	return claimed_by == person


# Take it. Written in DO, and only by a man standing here — you cannot reserve
# a plot from your bed.
func claim(person: Person) -> bool:
	if not is_free_for(person):
		return false
	claimed_by = person
	claimed_on_day = clock.day()
	return true
```

### Why this dissolves the argument

**"Grip" — the fast, per-tick sense of *hands on it right now* — is no longer a
stored thing.** It is:

> `claimed_by == me` **and** `person.get_current_place()` is this station's place

Both halves already exist; presence arrives with `Place` at rung 2. So there is
no fast lease left, nothing needs expiring quickly, and timestamp-vs-sweep is
moot.

### Phase by phase

- **GATE** — *reads.* `WorkTheField.is_available_to()` → `find_candidates()` →
  `Town.find_workstations()` filtered by `is_free_for(me)`. An empty list means
  work never reaches scoring — he isn't outbid, he is never asked.
- **SCORE** — *reads.* Of the plots he could have, the best one sets what
  working is worth.
- **UPKEEP** — **touches it never.** Nothing maintains a claim, nothing sweeps,
  nothing decays. Expiry is **lazy**: one comparison, evaluated when somebody
  happens to ask. A station nobody asks about can sit stamped with last week's
  claim forever at zero cost.
- **DO** — *writes.* The step asks *am I standing here?* No → walk. Yes →
  `claim(me)`, then work.

### Renew on use — and the bed bug it fixes

**The bug:** beds are `Workstation`s (rung 6 reuses `claim()` for them, as the
cheapest possible proof that the labour-clearing seam wasn't secretly about
labour). A bed is the one station used *across* a day boundary. A man claims a
bed at 21:00 on day 3; dawn breaks on day 4 while he is still asleep;
`claimed_on_day (3) < today (4)` so the bed reads as free — **and somebody else
can claim the bed he is lying in.** The presence check doesn't stop it, because
the newcomer is also standing there.

**The fix, which both reviewers reached independently:** the running step calls
`claim()` on every tick it advances, not once at the start. He is present, it is
already his, so it succeeds and re-stamps `claimed_on_day = today`. Dawn passes
under him and nothing expires.

> **Anything you are actively doing holds itself. Only claims nobody is
> standing on go stale.**

No new concept, no extra condition, and it generalises to every station.

**Backstop, for when frame-stagger lands:** a rival could still slip into the
gap between dawn and the claimant's next think. Guard by having `is_free_for()`
return false while the claimant is standing here — presence beats the calendar,
which is the same rule that already governs claiming. Not needed until stagger
exists; note it so it isn't rediscovered.

### Who dispatches work: nobody

Three separate things, and none is an assignment:

| Who | Decides | Mechanism |
|---|---|---|
| **The owner** | *that there is work, and how much* | issues an `Obligation` naming a **place** — the plan's existing `place_name` field |
| **The worker** | *which station, and when* | `find_candidates()` → picks the best free one |
| **The station** | *who has it* | `claimed_by` — records, never chooses |

The owner names a **place**, never a specific station. The dispatch is
deliberately coarse: it is a job, not a work order.

**Why the owner must not pick the station:** doing so requires an allocation
procedure — round-robin, nearest, best worker, first to ask. That is the
labour-market clearing strategy already deferred elsewhere in this project
(RANDOM / FIFO / CHARISMA_PICK / PRODUCTIVITY_RANK, deferred 2026-05-16 until
combat earns it). It would arrive here through a side door. It also puts a
decision in the wrong body — the plan's banned shape *"a manager that walks
people and tells them what to do"* is exactly that, wearing a hat.

### `is_permitted_to()` — employment grants access to land

Without this, `owner` is a label used only for quota-setting, and **any farmer
can walk onto anyone's land, claim a plot and keep the grain.**

```gdscript
# workstation.gd — can he work here at all? Three ways in.
func is_permitted_to(person: Person) -> bool:
	if owner == null:    return true    # common land — the king's, i.e. nobody's
	if owner == person:  return true    # his own mill, his own forge
	return person.has_obligation_at(get_place())   # somebody hired him onto it
```

`is_free_for()` asks this too. So: no obligation → the owner's plots are not
candidates → work is not on your ballot.

**It must be asked in GATE every tick.** It is the first capability in the game
that can vanish *mid-work* — an obligation expiring at noon revokes land access
while the man is standing in the furrow. A step that assumes permission persists
will keep working land he may no longer touch. (Cloud)

**Ladder placement:** rung 3 leaves `owner` null on the test plot — common land,
both farmers can claim it, contention works exactly as the plan describes, no
permission check needed. The check lands at **rung 6**, when `owner` and
`Obligation` both arrive and there is finally something for it to read.

### Early bird catches the worm is intentional

Because claiming requires presence, the dawn reshuffle is decided by **who is
standing in the field at dawn**, not by who happens to be first in
`Population`'s iteration order. That narrows a real hazard (scene order silently
deciding every contest) but does not remove the underlying loop:

> waking order decides who farms → waking order comes from adenosine →
> adenosine comes from when he went to sleep → the early riser gets a plot,
> works, tires, sleeps early, rises early, gets a plot again.

Positive feedback, one iteration per day, no damper. **The author has ruled this
a feature, not a starvation bug.** It is not to be damped with a fairness rule,
a rotation, or a priority scheme. If it ever needs softening, that is a curve to
tune — never a rule to add — which is the same answer the plan already gives for
the `Socialise` herd.

### The doctrine change, committed deliberately

The plan states that interrupting costs nothing, because nothing was suspended.
Under a day-long tenancy that is **still true for the person** — he stores
nothing, re-decides every tick, and can walk away for free — and **no longer
true for the world.** He holds a plot nobody else can use while he sits in the
tavern.

> **This is a tenancy, not a lease.** It is a defensible commitment and it is
> made on purpose. Do not let a later reader "fix" it back into a fast lease on
> the grounds that it violates *interrupting costs nothing*; that principle now
> applies to the person, not to the world.

### Probe changes

**Drop** the plan's rung-3 assertion *"the holder still holds it after 100 ticks
— no alternation, no split."* It is now trivially true, and it only ever
guarded against sweep-order flicker that no longer exists.

**Replace with three, all exact, none dependent on tick ordering:**

1. A claim **survives a day boundary while being worked** (renew-on-use).
2. A claim **does not survive a day boundary while abandoned.**
3. A claim attempted **from the wrong place fails.**

**Keep** the freed-holder assertion — `queue_free()` the claimant, pump two
ticks, assert the loser can now claim it. That is the plan's standing check #1
made mechanical.

Link's assessment: the new model has fewer ordering assumptions to assert
against, so it is easier to probe than the per-tick lease was.

### Consequence for the notice board (see Decision 1)

Decision 1 deferred a "who wants what" notice board to a later rung. One
candidate implementation was *post each tick, and clear anyone who didn't
re-post* — the identical sweep mechanism ruled out here, and it inherits the
identical stagger bug: a staggered miller drops off the board on the frames he
doesn't think, and a farm owner reading it sees no buyers for no reason.

**Ruling out the sweep here rules it out there.** If the board is ever built, it
is a query (loop the people and ask), not a posted list.

### Deliberately left open

- **Whether the rung-3 Moment still reads.** Day-long claims mean the loser's
  utility scrambles once at dawn and then goes flat, where the plan promises a
  live scramble watchable in eight seconds. Link's answer is to shorten the day
  on the tuning board so the dawn beat repeats every few seconds — **which is
  blocked by Decision 5 below and cannot be done until that is fixed.** He also
  argues the new Moment is *stronger*: a man who lost the field at dawn and
  spent the day drinking beats a man twitching at a threshold. Unresolved until
  it can actually be watched.

### Plan edits this implies

Not yet applied.

| Section | Change |
|---|---|
| Rung 1 | **Delete** the instruction to end each tick releasing unrenewed claims. Do not write that call site at all. `Population` stays a loop and never touches the world. |
| Rung 3 (`Workstation`) | Replace the per-tick lease with `claimed_by` + `claimed_on_day`. Add `is_instance_valid` inside `is_free_for`. Add: claiming requires presence. Keep `owner` null on the rung-3 plot. |
| Rung 3 (probes) | Drop "holds after 100 ticks"; add the three replacements above plus the freed-holder assertion. |
| Rung 3 (text) | Amend "The claim is a per-tick lease, not a booking" — it is now a day-long tenancy. |
| *Two doctrine calls Fable must not re-make* | Add a third: a claim is world state with a slow expiry, and *interrupting costs nothing* now applies to the person, not the world. |
| Rung 6 (`Workstation.owner`) | Add `is_permitted_to()`. Employment grants access to land. Asked in GATE every tick because it can vanish mid-work. |
| Rung 6 (beds) | Note renew-on-use explicitly — it is what stops a sleeper losing his bed at dawn. |
| Seam ledger → *Installed* | Amend "Labour clearing — `Workstation.claim(person) -> bool`" to note day-long tenancy. Add `is_permitted_to` at rung 6. |
| Coverage map | No change — "one worker per plot" is still satisfied. |

## Decision 3 — How rung 6 gets cut

**Settled 2026-08-09. Author's call. Do not reopen.**

### The question

Rung 6 as written in the build plan lands **seven independent debuts behind one
review gate**:

```
Obligation + WorkForHire      stored intent reaching the ballot
hunger + social               two new stats in UPKEEP
Eat + Drink                   in every person scene, by composition
beds as Workstations          twenty of them; Sleep gains a place requirement
Workstation.owner             a new field with three future readers
Socialise                     a new action with a new candidate query
                              + a new person (farm owner), + a new place (tavern)
```

Its Moment is *"the first full day."*

The plan's own method is **one seam per rung, so a failure has one suspect**, and
the Probe + Moment pair is the only review gate. There is no test suite for
`game/`, so debugging is by bisection. Seven debuts behind one gate means a
first-full-day that reads wrong has seven suspects and nothing to bisect with.
Both reviewers flagged this independently as the worst gate in the document.

### What was proposed

**Cloud — reorder rungs 6 and 7 by dependency.** His diagnosis: rung 6 moves
goods three times before the goods-moving seam exists — the farmer hands his
quota to the farm owner, buys beer from the tavern owner, and eats bread out of
the tavern's storage. Rung 7's own text insists serving beer *is* `Trade`. So
rung 6 ships a transfer path **rung 7's first act is to delete**, and deleting a
shipped path is the exact failure the plan exists to prevent. His fix: pull
`Trade` down into 6 (a hungry farmer beside a tavern owner with bread — no
obligation, no recipe needed), and push obligations, discharge, `owner`, beds and
`Socialise` up into 7. Reasoning: the true dependency order is *inventory → an
action that consumes an item → a want → trade → an obligation that creates a
second kind of want*, and hunger is the cheapest want in the game while
obligations are the most expensive.

**Link — split rung 6 into four, leave `Trade` at 7.** And solve Cloud's
duplicate-transfer problem differently and more cheaply: **discharge into a
Place, not a person.** `Obligation` already carries `place_name`; rung 5 already
puts `Inventory` under `Place`. The farmer drops the sacks in the barn, and
`owner` is what makes the barn the farm owner's. No person-to-person transfer at
rung 6 at all.

### What was settled

**Link's split, with one correction, and the ladder does not reorder.**

The author's ruling: *more rungs is better than fewer; the guidance to isolate is
good.*

| Rung | Lands | Moment |
|---|---|---|
| **6a** | `hunger` + `social` rising in `Brain._update_body`; `Eat` in every person scene by composition; the tavern as a `Place`; `Workstation.owner` (one field, needed by 6b's barn) | three drives on one graph and you watch which wins — the first time the sleep cycle has a competitor that isn't a flat number |
| **6b** | `Obligation`, `WorkForHire`, expiry, discharge into the owning Place's inventory, the farm owner as a body | work's utility **falls off the graph** at quota and something else takes over — one legible crossing on the instrument that already exists |
| **6c** | twenty beds as `Workstation`s; `Sleep` gains a place requirement | twenty-one sleepers, twenty beds, one man left standing |
| **6d** | `Socialise`, `Town.find_people_at`, the distance damper | **the first full day** — now a *composition* moment rather than a debut moment, which is what a capstone should be |

**Why Cloud's reorder was not taken:** his diagnosis is correct, but Link's
Place-discharge fixes it without moving anything. Reordering touches every rung
below; routing discharge to a barn touches one line and is better fiction.

### The correction: at rung 6, a man eats his own bread

Link's Place-discharge handles the quota. It does **not** handle the farmer
buying beer from the tavern owner, which is person-to-person and sits in 6a. So
6a as Link drafted it still ships a transfer path that rung 7 replaces.

One authoring change closes it:

> **`Eat` takes bread from his own inventory.** No transfer, no place, no owner,
> no trade. Bread is authored into the farmer's starting inventory instead of the
> tavern's storage — a one-line change to authoring surface #3, which the plan
> already permits.

And **beer slides to rung 7 with `Trade`**, where it becomes rung 7's second
assertion: the tavern owner serving beer is the same action as the farm owner
selling grain. That is the unification rung 7 exists to test, and it now gets
tested in the rung that invents the mechanism rather than one rung early.

What 6a loses: one of three competing needs. What it keeps: hunger and social
both rising in UPKEEP and both bidding against adenosine, and you watch which
wins. That is still the Moment — three drives on one graph where yesterday there
was one.

The farmer still walks to the tavern at 6d, for `Socialise` — because that is
where the people are, which was always the real reason.

### 6c (beds) is kept, not cut

Link judged 6c cuttable — nothing downstream depends on beds. **Decision 2
changed that.** A claim is now a day-long tenancy with renew-on-use, and the bug
that forced renew-on-use *was the bed*: the day boundary falls mid-sleep, so a
sleeper's claim expires underneath him and someone else can claim the bed he is
lying in.

So 6c is no longer just a cheap proof that `claim()` was never really about
labour. **It is the only rung that exercises a claim across a day boundary**,
which is the single case the mechanism was repaired for. Its probe should assert
the sleeper still holds his bed at dawn.

### Effect on the ladder

Nine gates become twelve. No rung is reordered; rung 6 becomes 6a–6d and one
item (beer) moves from 6 to 7.

### Plan edits this implies

Not yet applied.

| Section | Change |
|---|---|
| Rung 6 | Split into 6a / 6b / 6c / 6d as tabled above, each with its own Probe + Moment gate. |
| Rung 6a | `Eat` reads the person's **own** inventory. Bread is authored into the farmer's starting inventory, not the tavern's storage. |
| Rung 6b | Discharge goes to the **Place** named by the obligation, into that Place's `Inventory`. No person-to-person transfer at rung 6. |
| Rung 6c | Probe asserts a sleeper holds his bed **across** a day boundary (renew-on-use, per Decision 2). |
| Rung 7 | Gains `Drink` and beer. Rung 7 now carries two assertions: trade between strangers at the square, and the tavern owner serving beer through the same action. |
| Coverage map | *"Urge to socialise → walks to the tavern → beer"* splits: the walk and the urge are 6d, the beer is 7. *"Eats bread if hungry"* is 6a from his own inventory, and only becomes tavern-sourced once `Trade` exists. |
| *How the town assembles* table | Rows for 6 and 7 re-tabled against the new gates. |

## Decision 4 — `move_and_slide`

*Not a disagreement — settled by measurement. Link ran Godot 4.4 and found
`move_and_slide()` cannot be pumped from a headless harness (non-uniform
displacement at process rate; silently zero under `PROCESS_MODE_DISABLED`).
Rung 4 must integrate `global_position` directly. Keep `CharacterBody3D` as the
type. Recorded here so it isn't rediscovered.*

---

## Decision 5 — World time is denominated in hours

**Settled 2026-08-09. Author's call. Do not reopen.**

Not one of the four review disagreements. It surfaced as a live bug in shipped
code while settling Decision 2, and it blocks rung 3.

### The bug, verified against the code

Two clocks run in this project and nothing connects them.

**`tkyds-game/game/clock.gd:23`** — `day_length_seconds` is an
`@export_range` slider, and its own comment says:

> *"day_length_seconds is the slider: how long a day FEELS. Changing it mid-run
> is safe and does what you'd expect."*

`time_of_day()` and `day()` both divide by it, so the **calendar** is measured
in world days.

**`tkyds-game/game/brain.gd:141`** — `base_adenosine_per_second := 1.0`,
applied in `_update_body` as `rate * delta`. The **body** is measured in real
seconds.

Change the day length and the body does not move with it. With the shipped
defaults (60s day, 1.0 adenosine/sec, `Sleep`'s utility being adenosine
directly, outbid by `StayUp`'s pull):

| `day_length_seconds` | What actually happens |
|---|---|
| **60** (default) | tired enough to sleep ~45 real seconds in — roughly one sleep cycle per day. Works, which is why nobody has noticed. |
| **10** | adenosine still needs ~45 real seconds → **he stays awake for about four and a half days** |
| **600** | he is exhausted 4% into the day → naps around the clock |

The slider does not do what its comment says, the failure looks like a tuning
problem rather than a units problem, and nobody would suspect the slider.

### Why it blocks rung 3

Decision 2 left one thing open: whether rung 3's Moment still reads, given that
a day-long tenancy means the loser's utility scrambles once at dawn and then
goes flat. The proposed answer is to **shorten the day on the tuning board** so
the dawn contest repeats every few seconds and you get the plan's promised
eight-second beat over and over.

That answer is correct and it currently produces a farmer who never sleeps. So
this is a prerequisite, not a cleanup.

### The fix

> **Real time enters the simulation at exactly one line and is never seen
> again. Everything below that line is denominated in world hours.**

```gdscript
# clock.gd — the one converter in the project.
func get_hours_elapsed(real_delta: float) -> float:
	return real_delta / day_length_seconds * 24.0
```

```gdscript
# population.gd — real seconds stop here.
func think_for_everyone(delta: float) -> void:
	var hours := clock.get_hours_elapsed(delta)
	for person in _people:
		person.think_and_act(hours)
```

Everything downstream takes **hours**, including the argument name — per
`CLAUDE.md` naming rule 3, arguments are named for what they ARE, and an
argument called `delta` that holds hours is exactly the trap that rule exists to
prevent. So: `Person.think_and_act(hours)`, `Brain.think_and_act(hours)`,
`ActionStep.advance(person, hours)`.

Every rate in the game becomes per-hour:

```gdscript
@export var base_adenosine_per_hour := 4.0     # reaches ~45 after ~11 hours awake
```

### Three things this buys

1. **`day_length_seconds` becomes a pure game-speed control.** Drag it and the
   whole world scales together — which is what its comment already claims it
   does, and what a tuning-board slider should do.
2. **Rates become readable.** *"4 per hour, sleeps around 45, so he is up about
   eleven hours"* is a sentence you can reason about and tune against. *"1.0 per
   real second"* is not, and it silently means something different at every day
   length.
3. **Probes stop depending on the tuning board.** With hours,
   `think_and_act(1.0)` **is** one hour and twenty-four calls **is** a day. A
   probe asserting "he sleeps at least once in 24 hours" never mentions
   `day_length_seconds` and cannot be turned red by someone dragging a slider.
   This kills that flakiness at the root rather than working around it by
   pinning tuning values in every probe.

### Ladder placement

- **Rung 0** — change the units, and put the conversion inside
  `Person.think_and_act`, which rung 0 extracts anyway. This is a fix to shipped
  code, not a new rung, and rung 0's probes need it to be writable.
- **Rung 1** — the conversion moves up into `Population`, where it belongs, when
  `Population` arrives.

Cost is a rename across `person.gd`, `brain.gd`, `action_step.gd` and the
handful of existing action steps. It is cheap now and gets more expensive with
every action added.

### Plan edits this implies

Not yet applied.

| Section | Change |
|---|---|
| Rung 0 | Add: denominate all drift rates in hours; `Clock.get_hours_elapsed()` is the sole real→world converter; conversion sits in `Person.think_and_act` until `Population` exists. |
| Rung 0 (probes) | Assertions are stated in simulated hours and never reference `day_length_seconds`. |
| Rung 1 | The conversion moves into `Population.think_for_everyone`. Nothing below it ever sees real seconds. |
| Rung 9 (`Recipe`) | `seconds_of_work` becomes `hours_of_work`, and so avoids inheriting this confusion. |
| `CLAUDE.md` | Add to the design rules: nothing outside `Clock` interprets a real-time delta. Every rate in `game/` is per world hour. |

---

## Decision 6 — What a handoff is: sync, async, and the shape of a trade

**Settled 2026-08-09. Author's call. The *rule* is settled; the *mechanics*
are deliberately deferred to their own session — see the end of this section.**

Not one of the four review disagreements. It surfaced underneath Decision 3:
the two reviewers were proposing opposite cuts to rung 6 because they held
opposite unstated assumptions about what moving goods between people *is*.

### The split that was hiding under Decision 3

**Cloud treats person-to-person as the primitive.** `Inventory.hand_over()` is
the one waist all goods movement passes through; `Trade` is two calls of it,
discharge is one. Everything else is expressed in its terms.

**Link treats person-to-person as the special case to be avoided.** His
discharge routes through a `Place` — the farmer drops sacks in the barn, the
owner collects them later, nobody has to meet. He reached for that partly
because he correctly spotted that the plan's banned-shapes table (*"a step that
reaches past its own person to move somebody else"*) forbids the only
implementable two-party write.

Those are not two ways to write one function. They are two different towns.

### Why it matters more than it looks

Routing goods through places makes the handoff **asynchronous**. You still have
to *be* at the barn to drop a sack — presence still gates — but two people never
have to be there *at the same time*.

Set against what the plan says about its own geography:

> *"The square sits between the fields and everything else, so most of the town
> crosses it twice a day. That is where people incidentally see each other, and
> **seeing each other is the substrate the whole game is eventually built on.**"*

and rung 7's Moment:

> *"the sacks change hands **because they are standing in the same place at the
> same time.** Move one of them and it doesn't happen."*

**Asynchronous handoffs quietly delete that.** An economy that runs through
warehouses is efficient and lonely — nobody waits for anybody, nobody is ever in
the square at the wrong moment. The arc's ending (a merchant and a farmer
standing beside each other with a misunderstanding between them) needs the town
to *force* co-presence, and warehouses are precisely the technology for not
having to.

### The settled rule

> **`hand_over` is one mechanism with two fictions.**
>
> **Async** — dropping goods at a place you are permitted to use. One body, no
> simultaneity. **Permitted only inside a relationship that already exists** —
> an employee discharging to his employer's storage.
>
> **Sync** — exchanging with a person. Two bodies, one place, both present, and
> both currently *able* to trade.
>
> **Everything between strangers is synchronous, on purpose**, because
> co-presence is the substrate the game is built on and an efficient supply
> chain would delete it.

Which handoffs are async is therefore **a design lever about how much the town
is forced to meet**, not a technical convenience. Make everything async and you
get a clean supply chain with no story in it.

### The gate neither reviewer specified

Under Decision 1, want is `target − stock` — so the initiating party answers
*"does he want this?"* by **reading the other man's state**, never by consulting
his decision. The receiving party's brain does not run.

As specified, that means **a merchant could trade with a sleeping man**: read his
deficit, hand over goods, take his coin, while the farmer is unconscious at the
Inn. Cloud's defence of the two-party write was *"both parties scored the same
exchange, so it is consented rather than imposed"* — Decision 1 made that
literally untrue, because nobody scored anything on the receiving side.

**The fix is a gate on the receiver, not a decision:**

> The receiver's own `Trade` action must be **available to him right now** —
> awake, present, not otherwise gated. Not that he chose it. That he *could*
> have.

One condition, and it restores the meaning of the banned shape: *you may
exchange with a man who could have chosen this, never with one who couldn't.*

### The shape of a trade

**One generic `Trade` Action. The work lives in its ActionStep.** No `Serve`, no
per-profession variants — consistent with the plan's rule that a profession is
never a class.

The step, in one tick:

1. **Put your surplus on the table.**
2. **Declare your deficits.**
3. **Match, and move the goods.**

**What "everything on the table" means comes free from Decision 1.** Flip the
sign on the want rule and you get the other half:

```
deficit  =  target − stock      →  what I will buy
surplus  =  stock − target      →  what I will put on the table
```

Same equation, both directions. So a merchant lays out his surplus grain and
keeps his dinner; a farmer with a quota to fill is not selling the grain he owes.
**Nobody authors a for-sale list and nobody accidentally sells their own food.**
A design that needs no new rule to answer its first hard question is usually not
fighting the substrate.

The match is a loop, not a market:

```
for each item I have a surplus of:
    if he has a deficit of it:
        move min(surplus, deficit)
```

### What this does to the arc's ending

Under the plan as written the scythes go unsold because *"buy a scythe is not a
verb any farmer knows"* — an assertion in a document.

Under this shape: every day the merchant walks to the square and lays scythes on
the table; every farmer lays out his surplus and his wants; **no farmer's deficit
ever contains a scythe**, because no target of his does. So the scythes go back
in the cart, every day, in front of you.

**You are not told the ending. You watch a man fail to sell something,
repeatedly.** Same loop, no match, no extra code.

### Three things pinned so this does not drift

1. **Bilateral, never N-party.** Two people, one place, one tick. The moment it
   becomes "collect everyone's offers and find the global optimum," it is the
   market-clearing algorithm already deferred twice — the labour strategy
   (deferred 2026-05-16) and the order book (in the plan's Refused ledger). Same
   system, third door. *"The market clears"* is a phrase that invites an order
   book; it means the loop above and nothing more.
2. **One step, not a sequence.** The plan notes `Sequence` and `Choice` are not
   ported from git history. This does not need them — same pattern as rung 4:
   *not at the square → walk toward it; at the square → lay out and match.* One
   `advance()`, re-derived from where he is standing. Laying out and matching
   happen inside a single tick, so they are function calls, not phases.
3. **Price stays out.** Everyone is flush, `can_afford()` returns true, the call
   site exists and nothing reads it. "Put it on the table" invites price
   thinking, and FR60 makes output the leverage, never wealth.

### It satisfies rung 7's actual test

Rung 7's stated check is that the tavern owner serving beer must be **the same
action** as the farm owner selling grain — *"if serving needs its own mechanism,
rung 7 got the candidate query wrong."*

Thirsty farmer has a beer deficit; owner has a beer surplus; both at the tavern
→ match → exchange. Same loop, no `Serve`, no service system. It passes.

### An emergent property worth watching for (author's observation)

The utility of trading keeps a man **standing in the square** while he has
surplus to move — and while he stands there, others arrive. The square becomes a
gathering point *because of trade utility*, with nobody authored to go there.
That then feeds `Socialise`, whose candidates are places that currently hold
people.

**Watch for a herd.** This is the same positive-feedback shape the plan already
warns about for `Socialise` (*"people-attract-people… the whole town converging
on one room is the same stable equilibrium that got split-yield rejected"*), now
with a second driver pushing the same way. The specified damper is the same:
distance is a score term, so a far crowd loses to a near one. **If it herds
anyway, that is a curve to tune, never a rule to add.**

### Deferred to its own session

The rule above is enough to build rung 7 against. These are not, and should not
be resolved by implementation drift:

- **What "the table" is** — whether an offer is a real object in the world, and
  what it looks like.
- **Whether a third party can see an offer that isn't for them.** This is where
  Decision 1's deferred notice board returns.
- **Exchange that takes time.** The author's note: an exchange should visually
  take time, with balances moving only on completion, not during. **One-tick
  resolution is accepted for now.** When it is built, note that a
  part-completed exchange is work-in-progress state, which puts it in the same
  category as `Workstation.progress` — and Decision 2's rule says such state
  lives on the world object, never on a person. Where a half-done trade lives is
  an open question that session must answer.
- **Prices**, and what happens the day money stops being free.
- **Multi-party clearing**, if it ever earns its way in.

---

## Decision 7 — Identity check vs travel cost

**Settled 2026-08-09. Author's call. Do not reopen.**

This was hole 1 of the four found in the original pre-read of the build plan,
and the last of them to be settled.

### The confusion, and where it came from

On **2026-08-08** the author ruled that *location is a discrete fact, not a
distance check* — a person **has** a place, and walking sets it on arrival. That
reverted an earlier physics-based override and restored `prd.md:470` / FR85.

The build plan then goes on to say, in rung 3, *"Distance is a SCORE term for
the caller, never a gate in here"*, and in rung 6 that the anti-herd damper on
`Socialise` works because *"a far crowd loses to a near one."* Decision 6 above
leans on that same damper again for the trade-herd risk.

**But no place-to-place metric exists anywhere in the ladder.** Two dampers are
specified as already-solved and their input was never built.

The root cause: **two different questions were fused into one word.** The
2026-08-08 ruling only ever settled the first one.

### The two questions, permanently separate

| | Question | Asked in | Must be |
|---|---|---|---|
| **Identity check** | *Am I at the tavern?* | **GATE** — can I drink here? | crisp; exactly one answer |
| **Travel cost** | *What does getting there cost me?* | **SCORE** — how appealing is going? | a number; never crisp |

These are the author's terms and they are preferred over "location vs distance".
**"Travel cost" is deliberately not called distance**, because it does not
promise straight-line: roads, a river crossing, a gate shut at night are all
travel cost changing and none of them are distance.

### Why the identity check had to be strict

The rejected model was *"he is at the tavern if he is within 5 metres of it."*
Three failures, and the first is decisive:

1. **Flicker.** Walking past at 5.01m, 4.99m, 5.01m flips the answer every tick.
   `Drink` appears on his ballot, vanishes, appears. He starts drinking, stops,
   starts. Because the brain re-decides every tick with nothing stored, there is
   nothing to smooth it — the twitch is the design working correctly on a bad
   input.
2. **Overlap.** Two places near each other and he is inside both radii. Is he at
   both? Neither? There is no correct answer, and every gate reading it gets a
   different one depending on which radius happens to be larger.
3. **Fuzzy arrival.** "Has he arrived?" becomes "did he cross a threshold this
   frame," which is framerate- and speed-dependent. Rungs 3 and 7 both ask
   *"same place?"* every tick and both need a clean yes.

So: a person **has** a place. One field, one answer, arrival exact and free
because the walking step writes it. That ruling stands and is not reopened.

### Why none of that applies to travel cost

Travel cost **never decides anything.** It multiplies a score. A far tavern does
not become un-enterable — it becomes less appealing than a near one, and if
nothing nearer exists, he walks.

Nothing flickers, because nothing is compared to a threshold. Nothing overlaps,
because it is not answering "which place am I in." It answers "what does this
cost me."

**And the plan already requires it.** Standing check #3 reads:

> *"Move a place in the editor. Does behaviour change without an edit? Geography
> must be **read**, never assumed."*

That check is **unsatisfiable unless something reads a transform.** Travel cost
is therefore not a concession to the reverted ruling — it is the only way to
pass a test the plan already set. Both reviewers reached this independently.

Consistent with the author's earlier ruling on situational action gating
(2026-07-30): geometry is for effects and costs — a fear radius — never for
identity.

### The seam, and why it is on `Person`

The author raised the decisive objection against the two obvious owners:
**there will be multiple towns.** A person in town A scoring a place in town B
has no obvious `Town` to ask, so a `Town`-scoped method breaks. But inventing a
`World` node today to hold one function is substrate before need.

Resolved by putting the seam **where the caller already stands**:

```gdscript
# person.gd
# What getting there costs him. Straight-line off the transforms today.
# Roads, rivers, a gate shut at night, and one day a world spanning several
# towns — all of them install in this one function body and no caller changes.
func get_travel_cost_to(place: Place) -> float
```

Every caller is an Action scoring itself, and **an Action always has the
person.** So the call site is `person.get_travel_cost_to(place)` permanently.
Today the body is one line of arithmetic against `global_position`. The day a
world routing service exists, the body becomes a one-line delegate to it and
nothing else in the project moves.

Rejected: `Place.get_distance_from(person)` (the endpoint is not the natural
owner of what lies between two points) and `Town.get_travel_distance(...)`
(breaks across towns).

### Travel cost never gates — cut the radius and the cap

The build plan's rung 3 says *"Radius bound and the hard cap (~3) live in
here"* and then, two lines later, *"Distance is a SCORE term for the caller,
never a gate in here."* **Those contradict.** A radius bound is a gate. Both
reviewers flagged it independently.

**Cut both.** It is also premature: at rung 3 there are two farmers and one
plot, so a radius that never excludes anything is untested code and a
"nearest 3" cap is meaningless without a metric.

### Staying local without a locality rule

The author's concern — with multiple towns you cannot consider every place in
the world — is real, and the answer is not a cap:

> **`find_candidates()` returns its results sorted by travel cost.**

Then "nearest three" is `[0..3]` at whatever call site ever wants it, and
**locality is emergent rather than authored**: places in the next town sit at
the bottom of the list because they are expensive, not because a rule says
"only your own town." That is the plan's own doctrine — build the cause, never
the observation.

Nothing truncates yet. Sorting is the whole change.

*(Sorting also closes a separate hazard Cloud raised: `is_available_to`,
`get_utility_score` and the step each need the candidate list, and if they
disagree the utility that won is not the utility he gets. A stable sort — by
travel cost, then node path as tiebreak, never Dictionary hash order — makes the
three agree. Never iterate a Dictionary for candidates.)*

### The falloff curve, and the personality it gives you free

Travel cost becomes a score multiplier through one curve: **1.0 at his feet,
falling off, never reaching zero** — so a far option is *outbid, never barred*.
That is what keeps the plan's "he loses, and losing is the content" true.

The knob lives on **`Person`**, not on the town:

```gdscript
@export var distance_that_halves_appeal := 12.0
```

Defaulted on `person.tscn` so everyone is identical until you decide otherwise,
and overridden per instance when you want somebody specific — the pattern
`person.gd` already documents: *"what makes an instance somebody in particular
is the exports below."*

**So "how far will he walk" becomes a character trait at zero cost.** A homebody
who will not cross town for a beer and a wanderer who will are the same scene
with one number changed.

Per-action sensitivity, when it is wanted, is that action's own weight on the
multiply — a man walks further for a bed than for a beer.

### Rung placement

- **Rung 2** — `Person.get_travel_cost_to(place)`. One line; both nodes already
  carry positions. Lands with `Place` itself.
- **Rung 4** — the falloff curve and the `distance_that_halves_appeal` export.
  Rung 4 is the first rung where a man chooses between two places at different
  costs, so it is the first collision that can actually break the curve.
  Deferring it to 6d (as one reviewer proposed) would ship two rungs that
  quietly need it.

### Plan edits this implies

Not yet applied.

| Section | Change |
|---|---|
| Rung 2 | Add `Person.get_travel_cost_to(place)`. State the identity-check / travel-cost split explicitly so it is not re-fused. |
| Rung 3 | **Delete** "Radius bound and the hard cap (~3) live in here." `find_workstations` returns every matching station, **sorted by travel cost**, stably, with node path as tiebreak. |
| Rung 4 | Add the falloff curve and `distance_that_halves_appeal` on `Person`. Probe: a nearer station outscores an identical farther one; a far one still scores above zero (outbid, never barred); moving a place in the editor changes which wins — standing check #3, made mechanical. |
| Rung 6d | `Socialise`'s anti-herd damper now has its input. No change to the text beyond correcting the rung it cites. |
| *Author's decisions already made* | Amend the 2026-08-08 location entry to say it settled the **identity check** only, and that travel cost is a separate, permitted, score-only quantity. |
| Seam ledger → *Installed* | Add: **Travel cost** — `Person.get_travel_cost_to(place)`, rung 2. |

---

## Decision 8 — Rung 9 splits into 9a–9d

**Settled 2026-08-09. Author's call — the same ruling as Decision 3 (*more rungs
is better than fewer; the guidance to isolate is good*).**

### The question

The build plan's rung 9 lands the whole town at once: `Recipe`,
`Workstation.progress`, five conversions, `TravelForStock`, eight new people,
four new places, and the arc's ending. Its own text says this is where you learn
whether the seams held:

> *"Mostly repetition, and that is the point: if the seams are right, five
> professions are five data rows and no new systems. If any of them needs a new
> mechanism, a seam below was wrong, and this is where you find out cheaply."*

**As one rung, you find out about all five at once and cannot tell which seam
was wrong.** On a project with no test suite, where debugging is by bisection,
that is the same seven-suspect problem Decision 3 fixed at rung 6.

### The split

| Rung | Lands | The gate passes when |
|---|---|---|
| **9a** | `Recipe` (`Resource`), `Workstation.progress`, inputs held on the station from the moment work starts — **the millstone alone** | a miller interrupted mid-grind and replaced by a second miller **resumes from the same progress**, and world totals are conserved across the abandonment |
| **9b** | the other four conversions — oven, bar, chopping block, anvil — **as `.tres` rows** | **no new code was written.** If any of them needs code, a seam below 9a was wrong |
| **9c** | the merchant's stall: the first **two-input** recipe (sticks + iron plate → scythe), plus `TravelForStock` | a scythe comes out; the smithy can now go idle for reasons nobody in town controls |
| **9d** | thirteen people, seven places — tavern owner, baker, brewer, wood chopper, blacksmith, second merchant, two more farmers | **no new code was written.** Standing check #2 (*add a fourteenth, does he participate immediately?*) is the entire content |

### Why this is not merely "more gates"

**9b and 9d are negative gates — they pass by requiring nothing.** That is a
different kind of gate from every other rung in the ladder, and it is the only
way the plan's central claim is actually *tested* rather than asserted.

The diagnostic value is the point: **9b failing means the `Recipe` seam is
wrong. 9d failing means something got scripted.** Those are two different
problems with two different fixes, and one combined rung cannot tell them apart.

### Effect on the ladder

Combined with Decision 3 (rung 6 → 6a–6d), the ladder goes from **9 gates to
15**.

### Plan edits this implies

Not yet applied.

| Section | Change |
|---|---|
| Rung 9 | Split into 9a / 9b / 9c / 9d as tabled above, each with its own Probe + Moment. |
| Rung 9a | Inputs move onto the `Workstation`'s own `Inventory` when work begins, so a half-ground sack exists somewhere in the world rather than leaking. Probe asserts conservation across an abandonment, not just across a completion. |
| Rung 9b | **Explicitly a no-code rung.** State that writing any GDScript here is a finding about 9a, not a task. |
| Rung 9d | **Explicitly a no-code rung.** This is standing check #2 as a gate. |
| Rung 9 probes | Split the plan's *"after N simulated days the merchant's scythe count > 0 and every farmer's is zero"* — it is an integration assertion over ~40 tuning inputs and will go red for tuning reasons. Keep (a) the stall given sticks and plates produces a scythe — deterministic, 9c; and (b) no farmer ever knows `BuyScythe` — a repertoire assertion, exact, and it *is* the thesis. Demote the N-days convergence to a Moment. |
| *How the town assembles* table | Re-table rows for 6 and 9 against the new gates. |

---

## Decision 9 — Rung 0's harness, corrected against the engine

**Settled 2026-08-09.** Not a design disagreement. Everything here is either a
behaviour measured against the Godot 4.4.stable.mono binary named in `CLAUDE.md`,
or a claim checked directly against this repo. Recorded so it is not
rediscovered.

### Why rung 0 exists at all

There is no test suite for `game/`. Verification today is throwaway scripts that
get deleted. A silent null guard already shipped a dead day/night cycle through
two commits in this project, so *"it runs without errors"* has been demonstrated
to mean nothing here. Rung 0 gates everything below it.

### What the build plan specifies, and what is wrong with it

The plan calls for one file, `game/probe.gd`, a `SceneTree` that instances a
scene, pumps `person.think_and_act(fixed_delta)` for N ticks, asserts, prints
`PASS`/`FAIL` and exits non-zero. *"Ten lines, not a framework."* Four
assertions. Run with
`Godot_v4.4-stable_mono_win64_console.exe --headless --path . --script game/probe.gd`.

Four things in that do not work.

### Engine behaviour 1 — `set_process(false)` is silently discarded from `_initialize()`

Measured frame counts, three approaches:

```
                       set_process(false)   same call on    process_mode =
                       in _initialize       frame 1         PROCESS_MODE_DISABLED
  frame 1              ticks=0              ticks=0         ticks=0
  frame 2              ticks=1   <--        ticks=0         ticks=0
  frame 5              ticks=4   <--        ticks=0         ticks=0
```

A probe that adds a `Person`, calls `set_process(false)`, and then pumps
`think_and_act` by hand gets a **double-ticked person** — adenosine advancing at
twice the pumped rate. **That presents as a tuning problem, not a harness
problem**, which is how it costs a day.

> **Use `process_mode = Node.PROCESS_MODE_DISABLED`.** It is the only recipe
> with zero leaked frames, it works from `_initialize`, and it inherits to
> `Brain` / `Stats` / `Readout` for free.

### Engine behaviour 2 — `_initialize()` runs before anything is in the tree

`_ready` has not run, `@onready` vars are null, and `get_global_transform()`
spams `Condition "!is_inside_tree()" is true`.

> **Setup in `_initialize`; assertions from the first `_process` frame onward.**

### Engine behaviour 3 — `--script` does not build the global class cache

On a project that has not been imported, `class_name Person` fails to resolve:
`Parse Error: Identifier "Person" not declared in the current scope`. The cache
appears only after an editor import pass.

> **The run line always needs `--editor --quit` in front of it**, or the probe
> fails for a reason that has nothing to do with the code:
>
> ```
> Godot_..._console.exe --headless --path . --editor --quit
> Godot_..._console.exe --headless --path . --script game/probe.gd
> ```

### Engine behaviour 4 — `move_and_slide()` cannot be pumped

Recorded separately as Decision 4. Rung 4 integrates `global_position` directly
and keeps the `CharacterBody3D` type.

### Assertion 3 as written is vacuous — verified

The plan's third assertion is *"when `Sleep.is_available_to` is false, `Sleep` is
never the chosen action."*

**Checked against `tkyds-game/game/actions/sleep.gd`: it overrides no
`is_available_to`**, so it inherits `Action`'s default `return true`. The
condition can never be false and the assertion can never fail.

Replace with the general form, which covers every action anybody writes for the
remaining fifteen rungs and is the highest-value single assertion in the file:

```gdscript
# No action is ever chosen while its own gate says no. Checked every pumped
# tick, for every action anybody ever learns.
for action in person.brain.get_known_actions():
	if person.brain.current_action == action:
		assert_true(action.is_available_to(person),
			"chose \"%s\" while gated shut" % action.name)
```

*(This needs `Brain.get_known_actions()` — `_known_actions` is private today.
One accessor.)*

### Assertion 4 cannot be written at runtime — do it statically over the `.tscn` text

The plan's fourth assertion is *"every required `@export` node reference is
non-null after `_ready`"* — the `node_paths` trap, caught mechanically.

**It is not writable by runtime reflection.** A broken wire and a legitimately
empty optional are indistinguishable at runtime, and Decision 2 introduces a
**deliberately null** `Workstation.owner` (unowned land belongs to the king,
which is the same answer as nobody) that would false-positive forever.

The trap is textual, so catch it textually:

> A property assigned a bare `NodePath("…")` **must** be named in its own node's
> `node_paths=PackedStringArray(...)` header. A property assigned
> `Array[NodePath]([…])` **must not** — per `CLAUDE.md`, `Array[Node]` does not
> resolve at all and `Array[NodePath]` is resolved by hand with
> `get_node_or_null()`.

**Verified by hand against `tkyds-game/game/game.tscn`** — five `NodePath(`
sites, zero false positives:

| Node | Assignment | Declared? |
|---|---|---|
| `Daylight` | `clock`, `environment` — bare | ✓ `node_paths=PackedStringArray("clock","environment")` |
| `StatGraph` | `person` — bare | ✓ `node_paths=PackedStringArray("person")` |
| `UtilityGraph` | `person` — bare | ✓ `node_paths=PackedStringArray("person")` |
| `TuningBoard` | `watching = Array[NodePath]([…])` | correctly **not** declared |

This also catches the bug in `.tscn` files that are not even in the probe's
scene, which runtime reflection cannot.

**Add a runtime half** for `CLAUDE.md`'s *second* trap, which the text scan
cannot see: every path inside an `Array[NodePath]` export must actually resolve.

### Assertion 1 is already fixed by Decision 5

*"Over 24 simulated hours he sleeps at least once and wakes at least once"* was
flaky as written — it depends on `day_length_seconds`, both adenosine rates and
`StayUp`'s pull, and **`Clock` is on the tuning board** (confirmed: it is the
first entry in `TuningBoard.watching` in `game.tscn`). Dragging one slider turned
the suite red with nothing broken, and a suite you distrust gets deleted — which
is the exact failure rung 0 exists to prevent.

**Decision 5 kills it at the root.** With world time denominated in hours,
`think_and_act(1.0)` **is** one hour and twenty-four calls **is** a day. The
assertion never mentions `day_length_seconds` and cannot be turned red by the
tuning board. This is why Decision 5 is a rung-0 prerequisite and not a cleanup.

### Assertion 2 needs one small fix

*"Adenosine rises monotonically while awake and falls while asleep."* Use `>=`,
and only assert **strict** increase below `adenosine_ceiling` — `_update_body`
applies `clampf(tired, 0.0, adenosine_ceiling)`, so strict monotonicity is false
once he is pinned at the top.

### The harness must drive the clock

With everything set to `PROCESS_MODE_DISABLED`, `Clock._process` never runs and
nothing advances time. **The probe advances `Clock` itself**, in the same loop
that pumps people. Under Decision 5 this is straightforward: the pump is
denominated in hours and the clock moves with it.

### Honest scope

- **"Ten lines" is wrong** — realistically 120–150 once the `.tscn` scan is in.
  **Say so in the plan**, or an implementer under time pressure cuts the scan,
  which is the highest-value assertion in the file.
- **"One file" and "`game/probes/` for per-rung checks" contradict each other.**
  One file until it hurts — call it ~300 lines.
- Still **not** a framework. No fixtures, no mocks, no runner, no GUT, no
  GdUnit. Injected actors are real `person.tscn` instances with different Action
  children, never mocks — which is the plan's own thesis about composition, and
  doubles as standing check #2.

### Plan edits this implies

Not yet applied.

| Section | Change |
|---|---|
| Rung 0 — run line | Two commands: `--editor --quit` import pass first, then `--script game/probe.gd`. Never the second alone. |
| Rung 0 — shape | Setup in `_initialize`, assertions from the first `_process` frame. `process_mode = PROCESS_MODE_DISABLED`, **never** `set_process(false)`. The harness advances `Clock` itself. |
| Rung 0 — assertion 1 | Stated in simulated hours; never references `day_length_seconds`. Depends on Decision 5. |
| Rung 0 — assertion 2 | `>=`; assert strict increase only below `adenosine_ceiling`. |
| Rung 0 — assertion 3 | Replace the vacuous `Sleep` check with the general "no action is chosen while its own gate says no" loop. Add `Brain.get_known_actions()`. |
| Rung 0 — assertion 4 | Static scan over `.tscn` text for the bare-`NodePath`-without-`node_paths` rule, plus a runtime check that every `Array[NodePath]` entry resolves. |
| Rung 0 — scope | Say 120–150 lines. Resolve "one file" vs `game/probes/` — one file until ~300 lines. |
| Rung 0 — prerequisites | Note that Decision 5 (world time in hours) lands **in** rung 0, before the assertions are written. |
