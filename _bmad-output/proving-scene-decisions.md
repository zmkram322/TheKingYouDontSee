# Proving Scene — Decisions

Companion to `proving-scene-build-plan.md`. This file records what was settled,
why, and what it changes — so a revision pass (or a delegate who wasn't in the
room) can apply it without re-deriving it.

**The plan HAS now been revised against every section here** (2026-08-09 for the
first nine, 2026-08-11 for the rest). Each section's *"Plan edits this implies"*
table says whether it was applied. **Where two sections disagree, the HIGHEST
NUMBER WINS** — 15 over 14 over 7 — and superseded sections carry a warning
banner at the top rather than being rewritten, per the append-only rule below.

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

**APPLIED 2026-08-09.** Verified row by row against the build plan on 2026-08-11; every row landed.

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

**APPLIED 2026-08-09.** Verified row by row against the build plan on 2026-08-11; every row landed.

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

> **⚠ AMENDED BY DECISION 25 (2026-08-12) — READ 25 FIRST.** The cut into 6a–6d
> stands and is not reopened. **What 25 changes is 6a's contents:** this section
> puts `social` AND the tavern in 6a, and its Moment says *"three drives on one
> graph and you watch which wins."* Nothing reads `social` until 6d, so it can
> neither bid nor win, and nobody enters the tavern until 6d either. **6a lands
> hunger only.** Everything else here — the seven-debut argument, the 6b/6c/6d
> split, beer moving to rung 7, a man eating his own bread at 6a — is unchanged
> and still governs.

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

**APPLIED 2026-08-09.** Verified row by row against the build plan on 2026-08-11; every row landed.

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

**The behaviour-preserving conversion factor is `day_length_seconds / 24`** —
`60 / 24 = 2.5` at the shipped default. Multiply every per-second rate by it:

| Today | Becomes |
|---|---|
| `base_adenosine_per_second = 1.0` | `base_adenosine_per_hour = 2.5` |
| `base_adenosine_cleared_per_second = 2.5` | `base_adenosine_cleared_per_hour = 6.25` |

That reproduces the shipped cycle exactly — 45 real seconds up (18 world hours,
turning in around 18:00) and 14 asleep (5.6 hours). **Getting this factor wrong
is the one way this change breaks a working system, and it presents as "he never
sleeps" or "he naps constantly" rather than as a units error.**

Every rate in the game becomes per-hour:

```gdscript
@export var base_adenosine_per_hour := 2.5     # reaches ~45 after ~18 hours awake
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

**APPLIED 2026-08-09.** Verified row by row against the build plan on 2026-08-11; every row landed.

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

> **⚠ AMENDED TWICE ON 2026-08-10 — BY DECISION 14, AND THEN BY DECISION 15.
> Read 15 first, then 14, then this.** What still stands: the identity-check /
> travel-cost split this decision exists to settle, *outbid never barred*, and
> the cut of rung 3's radius bound and hard cap. **What does NOT stand is the
> arithmetic**: the multiplier (`1.0` at his feet, falling off, never reaching
> zero), the `distance_that_halves_appeal` knob on `Person`, and *"a man walks
> further for a bed than for a beer"* as a travel-cost expression. 14 cut the
> multiplier and the knob; 15 then confined travel cost to ordering an action's
> own candidates, so there is no cross-action distance term left for per-action
> sensitivity to live in. **Nothing in `game/` has ever contained a
> `distance_that_halves_appeal`** — rung 4 shipped without one on 2026-08-11.

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

### ~~The falloff curve, and the personality it gives you free~~ — CUT, see Decisions 14 and 15

> **Everything in this subsection was overturned and none of it was built.** It
> is kept because Decision 14 argues against it in detail and that argument is
> worth reading. **The principle survives; only the arithmetic died** — a far
> option is still *outbid, never barred*, but that is now guaranteed
> structurally (travel cost never enters a cross-action score at all) rather
> than by a curve that never reaches zero.

Travel cost becomes a score multiplier through one curve: **1.0 at his feet,
falling off, never reaching zero** — so a far option is *outbid, never barred*.
That is what keeps the plan's "he loses, and losing is the content" true.

The knob lives on **`Person`**, not on the town:

> **⚠ CUT — DO NOT BUILD THIS. Decision 14 dropped this export outright** (travel
> speed already does the "how far will he walk" job it was invented for), and
> Decision 15 then removed the cross-action term it would have fed. Measured at
> exactly the `12.0` below, work from the Inn scores **39.6 against StayUp's
> 87.3 — the man never goes to work at any hour of any day.** Rung 4 shipped
> 2026-08-11 with no such export and the score untouched. The snippet is kept
> only so the reasoning above it stays readable.

```gdscript
@export var distance_that_halves_appeal := 12.0    # CUT — never built
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
- **Rung 4** — ~~the falloff curve and the `distance_that_halves_appeal`
  export.~~ **CUT by Decisions 14 and 15.** What rung 4 actually got, and
  shipped: `walk_speed`, `get_travel_speed()`, `get_travel_cost_to()`
  denominated in hours, and freeness made locally knowable. The prediction that
  rung 4 would be "the first collision that can actually break the curve" was
  right — the collision was worked out on paper in advance and broke it before
  a line was written.
  Deferring it to 6d (as one reviewer proposed) would ship two rungs that
  quietly need it.

### Plan edits this implies

**APPLIED 2026-08-11** (most rows had already landed 2026-08-09; the rest were carried across on 2026-08-11 after a row-by-row audit found them missing). Rows that are deliberately NOT carried across, because a later decision overturned them, are struck through or banner-marked in place.

| Section | Change |
|---|---|
| Rung 2 | Add `Person.get_travel_cost_to(place)`. State the identity-check / travel-cost split explicitly so it is not re-fused. |
| Rung 3 | **Delete** "Radius bound and the hard cap (~3) live in here." `find_workstations` returns every matching station, **sorted by travel cost**, stably, with node path as tiebreak. |
| Rung 4 | ~~Add the falloff curve and `distance_that_halves_appeal` on `Person`.~~ **SUPERSEDED — see Decisions 14 and 15.** Of the probes named here, "a nearer station outscores an identical farther one" survives as a **candidate-ordering** assertion, "moving a place changes which wins" survives unchanged, and "a far one still scores above zero" is **retired** (no cross-action term is left for it to be barred by). |
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

**APPLIED 2026-08-09.** Verified row by row against the build plan on 2026-08-11; every row landed.

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

**APPLIED 2026-08-09.** Verified row by row against the build plan on 2026-08-11; every row landed.

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

---

## Decision 10 — How a Person reaches the world

**Settled 2026-08-09 while building rung 2, and shipped in `9722033`.** Not a
roundtable question — three calls the plan left open or got wrong, made at the
keyboard and recorded so rungs 3, 4, 6d and 7 don't re-make them.

### The Person pulls its Town. It is not handed down.

**The plan says** *"`Population._ready` injects `town` into each Person. Person
`_ready` warns if `town` is still null."* **Those two sentences cannot both
hold.** Godot readies **children before parents**, so every Person checks his
pocket before `Population._ready` has run — the warning would fire on every
person of every correctly wired scene, and a warning that always fires trains
you to ignore the channel that exists to catch the dead-day/night-cycle bug.

```gdscript
# person.gd — _ready
var population := get_parent() as Population
if population == null:
    push_warning("%s has no Population above him — he will never think" % person_name)
else:
    town = population.town          # the one line
if town == null:
    push_warning("%s has no Town — he can never be asked who else is here" % person_name)
```

This satisfies everything the injection instruction was protecting — **one wire
in the whole scene** (`Population.town`), zero per-person `NodePath`s, thirteen
people at rung 9 still one wire — and it mirrors how `Brain` finds its `Person`,
which is what the plan's own sentence pointed at.

**It is also strictly better for two later rungs**, which is why it should not be
flipped back: a man added to a *running* world is wired in his own `_ready`, with
nothing watching for new arrivals. That is what the probe's four spare people
exercise, and it is precisely what standing check #2 (*add a fourteenth
villager*) needs at 9d. Push would need a `child_entered_tree` hook to match.

**Generalised:** anything a Person needs a single shared reference to — the
world, a calendar, a market — hangs off `Population` and is pulled in
`Person._ready`. Never one `@export` per person.

### `find_people_at` is a query, and here is the contract that lets it graduate

Built as a loop over `population.get_people()`. **Cost measured against the
ladder, not in the abstract:** one pointer comparison per person per call, so
169 per tick at the thirteen-person town this arc ends at — lost in the noise of
the utility scoring those same thirteen already do. It stops being free
somewhere in the low hundreds of people, which is an order of magnitude past the
end of this plan.

**The graduation is already legal, and exactly one thing would foreclose it:**

> A **public occupancy list on `Place` that callers read directly** makes the
> list the interface — every caller then depends on it existing and being
> maintained at every write site, and it can never be swapped out. So: **nobody
> reads occupancy except through `Town.find_people_at()`.** Kept behind that
> function, an index is an optimisation rather than an architecture, and the body
> can change on a Tuesday with no call site moving. Same wall as
> `get_stat`/`set_stat`.

**And the plan's assertion 2 is banked, not discarded.** *"`find_people_at` and
`get_current_place` never disagree"* is vacuous today — one copy of the fact
cannot contradict itself — and it is the **exact** test for the day an index
lands: keep the loop as the slow oracle, run both, assert they match. The note
lives on the function in `town.gd`.

### `find_people_at(null)` returns nobody, deliberately

Nowhere holds no one. This is a real answer rather than a swallowed error, and
it is load-bearing from rung 4 onward: a man walking between places has
`current_place == null` for the length of the road. Without this guard every man
on a road would be found *together* at nowhere — and rung 7's `Trade`, whose
candidates are `find_people_at(person.get_current_place())`, would let two people
exchange goods while half a town apart. **A man on the road is unreachable, and
that is the feature.**

### Travel cost, as built

- **Straight-line 3D `distance_to` off `global_position`.** Height counts. If a
  rung ever stands a workstation on raised ground, that is included.
- **`get_travel_cost_to(null)` pushes an error and returns `INF`.** Nowhere is
  the *most* expensive answer, never the cheapest: `0.0` would read as "at his
  feet" and make a nonexistent place the most attractive destination in town — a
  bug that would present as strange wandering rather than as a null.
- **The readout prices every place in the town**, enumerated from
  `Town.get_places()`, rather than naming one in `person.gd`. Same reason the
  stats are listed rather than named: adding a place makes it appear over every
  head with no edit. At rung 9d that is seven lines over each head, and trimming
  it is that rung's problem.

### What rung 4 inherits, and one thing it does *not* have to undo

Arrival should be **"this tick's step would take me there or past it"**, snapping
`global_position` onto the place exactly and writing `current_place` once — not a
"within N metres" radius. There is then no threshold constant to tune, and he
lands on the spot at any tick rate, which removes the framerate-dependent
arrival that helped get the proximity model reverted. Departure writes
`current_place = null`.

**The "starts nowhere" warning in `Person._ready` does not need removing when
that lands.** It fires at birth only, and nobody is born on the road.

### Probe

Three claims added — 7 (a man carries his place), 8 (the exact set), 9 (cost
falls, rises, and never comes back `INF`). **All six deliberate breaks were seen
to exit 1**: place defaulting to the first place in town, place derived from
proximity, `find_people_at` losing its filter, the null-place guard removed,
cost stopping reading the transforms, and a far place returning `INF`.

**Claim 7's last assertion is the mechanical guard against the reverted physics
model** — move a man's *body* onto the fields and he must still report the Inn.

**One finding, measured:** the freed-person half of claim 8 **cannot fail
today.** Deleting the `is_instance_valid` guard from `find_people_at` leaves the
probe green, because `free()` removes a node from `get_children()` at once. The
guard is kept and both comments say it is unreachable. It gains teeth on the same
change that un-banks assertion 2. **That is the third assertion in this plan to
turn out vacuous when actually checked — keep checking.**

### Plan edits this implies

**APPLIED 2026-08-11** (most rows had already landed 2026-08-09; the rest were carried across on 2026-08-11 after a row-by-row audit found them missing). Rows that are deliberately NOT carried across, because a later decision overturned them, are struck through or banner-marked in place.

| Section | Change |
|---|---|
| Rung 2 | Replace *"`Population._ready` injects `town`"* with the pull, and state the child-before-parent reason so it isn't flipped back. |
| Rung 2 (probes) | Assertion 2 is **vacuous as written** and is replaced by the exact-set / moves / freed trio. Note where it is banked. |
| Rung 3 | `find_workstations` sorting by travel cost (per Decision 7) now has its metric — `person.get_travel_cost_to(station_place)`. |
| Rung 4 | Arrival is the overshoot clamp, not a radius. Departure writes null. The `_ready` warning stays. |
| Rung 7 | `Trade`'s candidate query inherits "a man on the road is unreachable" for free. |

---

## Decision 11 — The sleep cycle is anchored to the sun

**Settled 2026-08-10, at the author's direction, between rungs 2 and 3. Shipped
in `cd5fc7c`.** Not a rung — a tuning fix taken before rung 3, on the author's
reasoning that a drifting cycle makes every rung above it harder to verify.

### The bug, measured

Driven by adenosine alone, the cycle's length is whatever the two rates happen
to sum to. Measured at **19.6 hours** — 14 awake plus 5.6 asleep. A day is 24,
so **bedtime slid 4.4 hours earlier every day** and lapped the clock every five
and a half days:

```
day 0  18:01 → 23:37      day 2  09:17 → 14:53
day 1  13:39 → 19:15      day 3  04:55 → 10:31
```

The shipped baseline of *"turns in at 18.01, up at 23.62"* was therefore never a
schedule. It was **day 0 of a free run**, and day 0 was the odd one out: he
starts on an empty tank, which is fuller than any night ever leaves him.

### Why tuning the rates is not the fix

Making the rates sum to 24 fixes the **period** and not the **phase**. There is
no restoring force, so any disturbance moves him permanently and he keeps the
new hours forever. Rung 6's obligations are full of disturbances.

### What was settled

> **Being up is worth more while the sun is up.**

`StayUp.get_utility_score` stops being flat:

```gdscript
@export var pull := 67.3           # what being up is worth at dawn and dusk
@export var daylight_pull := 20.0  # added at midday, taken off at midnight
return pull + daylight_pull * person.get_sun_height()
```

Recovery drops `6.25 → 5.0`, so sixteen hours awake at 2.5 builds a swing of 40
and eight hours asleep clears it. **The rates set the shape of the cycle;
`daylight_pull` sets its phase.**

Measured convergence from a cold start — and the convergence is the point:

```
day 0  turns in 21:07        day 2  21:59 → 05:59
day 1  21:53 → 05:55         day 3+ 22:00 → 06:00, to the minute
```

### It is a score term and never a gate

*"Can't sleep during the day"* would bar an exhausted man from sleeping — the
same barring mistake as a radius around a tavern, in different clothes, and
forbidden by the same rule as travel cost. **The daylight peak (87.3) sits below
the adenosine ceiling (100) deliberately**, so a man kept up long enough WILL
drop at noon. The probe's second man demonstrates it without being asked to:
started with most of a day's tiredness on him, he goes to bed at **14:59** on
day 0, and is on the town's hours by day 3.

### One definition of the sun

`Clock.get_sun_height()` — −1 at midnight, 0 at dawn and dusk, +1 at midday.
`Daylight` now asks for it instead of writing its own sine; two would agree today
and part company the first time either changed.

Actions reach it through **`Person.get_sun_height()`**, because an Action scoring
itself has the person and nothing else — and it is the honest place for it to
graduate, since a man in a cellar sees no sun at noon.

### `Person.clock`, and what rung 3 gets from it

`Person` now pulls a `Clock` off `Population` beside its `Town`, by the same
mechanism (Decision 10). **This changes rung 3's workstation snippet.** Decision
2 shows `Workstation.claim()` reading a `clock` of its own, and flags the
hand-wired reference as the `node_paths` trap waiting to happen. It no longer
needs one: `claim(person)` can read `person.clock.day()`, so **not one station
carries a wire.** Re-derive the snippet accordingly.

### Wake has no daylight term — measured, not overlooked

The symmetrical version was written and then deleted:

> StayUp anchors bedtime to the evening. Eight hours of clearing puts the waking
> crossing at **dawn** — and dawn is exactly where the sun sits level with the
> horizon, so the term is multiplied by **zero** at the only moment the score is
> ever read. Tried at 6 and again at 30: the settled schedule did not move by one
> minute either time, and no claim in the probe could tell.

The anchor is one term in one action. If bedtime is ever retuned far enough that
waking lands well away from dawn, this becomes live again — **that** is what to
look for before adding it back, rather than adding it because it reads as
symmetrical.

### Probe

**The pumped window goes 24h → 48h.** An eight-hour night starting at 22:00 no
longer fits inside one midnight-to-midnight window, so the old one caught him
going to bed and quit before he got up. Not a fix to the assertion — the window
was cut to a free-running cycle that no longer exists.

Two claims added, **neither of which names an hour**, because an assertion about
a tuned number is an assertion about the tuning board and goes red the first time
somebody drags a slider:

- **10 — the cycle holds its hour.** He turns in with the sun below the horizon
  (stated as sun height, so it survives any retune), and the last two bedtimes
  differ by under fifteen minutes.
- **11 — two people who start from different histories keep the same hours.** The
  restoring force, asserted directly, and a preview of the town.

Broken on purpose, both red: strip the sun out of `StayUp` (10 and 11 both fail),
and invert it (he turns in at 09:56 in broad daylight, 10 fails).

**The measured schedule is printed, not asserted** — the same treatment
18.01/23.62 always had.

### New regression baseline — supersedes 18.01 / 23.62 everywhere

```
cold start   turns in hour 21.11 (21:07), up at 29.67 (05:40)
settled      turns in 22:01, sleeps 8.00 h, up 06:01
```

### Plan edits this implies

**APPLIED 2026-08-11** (most rows had already landed 2026-08-09; the rest were carried across on 2026-08-11 after a row-by-row audit found them missing). Rows that are deliberately NOT carried across, because a later decision overturned them, are struck through or banner-marked in place.

| Section | Change |
|---|---|
| Rung 0 / everywhere | The regression fingerprint is no longer 18.01 / 23.62. Use the pair above. |
| Rung 3 (`Workstation`) | Drop the per-station `clock` reference from Decision 2's snippet — read `person.clock.day()` instead. No station carries a wire. |
| Rung 6a | The "expect assertion 1 to go red when hunger and social join the ballot" note still stands, but the window is now 48 h and the cycle is anchored, so there is more headroom than the old 0.38 h. |

---

## Decision 12 — How two people differ

**Settled 2026-08-10, at the author's direction. Shipped in `57b1594`.** Falls
out of Decision 11 and has to be settled before rung 3, because rung 3's whole
Moment depends on it.

### The problem Decision 11 created

Decision 2 rules *early bird catches the worm* a **feature**: waking order
decides who farms, and waking order comes out of adenosine. **Decision 11
removed that mechanism.** The sun anchors everybody to the same hour — the
probe's own claim 11 asserts it — so two farmers instanced from one scene wake
**on the same tick, forever**, and the one plot goes to whoever sits higher in
`Population`'s child order. That is *"scene order silently deciding every
contest"*, the hazard Decision 2 was relieved to have narrowed. It would pass its
probe, and the Moment would be a coin flip landing the same way every morning.

### What was rejected

**Giving one farmer a different `StayUp.pull`.** It works, and it puts the
difference in the wrong place: the *action* would differ by who you are, which is
a branch on identity wearing a number's clothes, and the plan's own doctrine says
*a number is authoring; a branch on who you are is a script.* An action's utility
should be formulaic and identical for everybody.

### What was settled

> **The difference lives on the body, not on the action.** A `strength` stat,
> 1.0 for an ordinary man, read inside `Brain.get_adenosine_recovery()`.

Same formula for everyone; a different body running it. A stronger man clears the
same debt in fewer hours and is up first. **Measured: strength 1.15 rises at
04:41 against 06:01** — eighty minutes of daylight in which to reach the plot.

`get_adenosine_recovery()` was already the documented seam for *"a bed versus a
ditch, sleeping ill, sleeping cold."* Sleeping in a strong body is simply the
first modifier to arrive there. **No call site moved.**

### It hangs on RECOVERY and never on how fast he tires — measured

The natural reading is *strong man exerts himself less, tires more slowly, needs
less sleep, wakes earlier.* **The middle steps are right and the conclusion is
backwards**, because it quietly assumes a fixed bedtime — and bedtime has not
been fixed since Decision 11. Bedtime is where rising tiredness crosses the sun's
line, so a man who tires slowly reaches it LATER:

```
  up/hr  down/hr   turns in   gets up   night
   2.50    5.00     22:01      06:01    8.00 h    ordinary
   2.25    5.00     23:57      07:21    7.40 h    "strong" — up 80 min LATER
   2.75    5.00     21:11      05:41    8.51 h    tires fast — up EARLIEST
   2.50    6.00     21:14      04:18    7.06 h    recovers fast — what we want
```

### And that direction runs at a cliff

```
  2.50  22:01 locked    2.20  drifting
  2.40  22:29 locked    2.15  drifting
  2.30  23:11 locked    2.10  COLLAPSED — 39 hours awake at a stretch
  2.25  00:01 slipping  2.00  COLLAPSED
```

The sun's line bottoms out at 47.3 around midnight and its **slope there is
zero**, so a bedtime pushed toward midnight is weakly anchored, and one pushed
past it is never caught at all — he waits for the following evening. **A trait on
tiring walks straight at that edge.**

Recovery has no such trap in the useful direction:

```
  4.00  00:05 / 09:25  DRIFTING     6.00  21:15 / 04:19  locked
  4.50  22:40 / 07:14  locked       7.00  20:45 / 03:04  locked
  5.00  22:01 / 06:01  locked       8.00  20:22 / 02:05  locked
```

Only the *poor sleeper* below ~4.0 unhooks. **The wanted direction runs away from
the cliff.** Keep `strength` in roughly **0.9 – 1.6**.

Recovery also has the better *shape*: 5.0 → 5.5 moves bedtime 26 minutes but
waking 56. It reads as *"how much sleep does he need"*, which is the everyday
intuition, where tiring reads as *"when does he crash"* and drags waking behind
it in the wrong direction.

### Why one stat and not two

`strength` will mean more without a second stat: **rung 3's work step wants a rate
of work done per hour, and rung 5 wants how much a man can carry.** Both are the
same capacity. A strong body that both works more and shrugs off a day is honest
fiction, so the name hides nothing.

It is a **stat** rather than an authored number on `Brain` because it will have to
*change* during a run — a wound, age, a winter — and because it then shows up on
the graph and over his head with no extra code.

### Probe

**Claim 12, in two halves, because one is not enough.** The strong man rises
before the ordinary one, **and** he is still anchored.

Both were broken on purpose:

- Make `strength` inert → the **first** half catches it (both rise at 06:01).
- Move `strength` onto tiring instead → **the first half still passes** (he does
  rise earlier, at 05:25) and the **second** half catches him drifting.

A single-sign assertion would have shipped the exact mistake this decision
exists to prevent.

### Plan edits this implies

**APPLIED 2026-08-11** (most rows had already landed 2026-08-09; the rest were carried across on 2026-08-11 after a row-by-row audit found them missing). Rows that are deliberately NOT carried across, because a later decision overturned them, are struck through or banner-marked in place.

| Section | Change |
|---|---|
| Rung 3 | The two farmers differ by `strength`, authored per instance. Nothing else about them differs — same actions, same numbers on those actions. |
| Rung 3 (Moment) | The loser loses because the winner *got there first*, and got there first because he needed less sleep. That is the causal chain to watch, and it is visible on the readout. |
| Rung 9d | Thirteen people can be thirteen different bodies with one stat each, and no new code. Standing check #2 gets cheaper. |

---

## Decision 13 — The rung-3 Moment reads

**Closed 2026-08-10 by the author, at the keyboard, by watching it.** Not a
disagreement — this is the one question Decision 2 deliberately left open, and
it could only ever be settled by looking.

### The question, as Decision 2 left it

> *"Whether the rung-3 Moment still reads. Day-long claims mean the loser's
> utility scrambles once at dawn and then goes flat, where the plan promises a
> live scramble watchable in eight seconds… Unresolved until it can actually be
> watched."*

The concern was real: a day-long tenancy trades a twitchy contest for one
decisive beat per day, and a beat you have to wait a full day for is not a
Moment. Link's proposed answer — shorten the day on the tuning board so the
dawn beat repeats every few seconds — was **blocked by Decision 5** at the time
it was proposed, because before world time was denominated in hours, dragging
that slider left the farmer awake for four days.

### What settled it

Decision 5 shipped at rung 0 and unblocked the slider. Rung 3 shipped the
contention. **The author ran it and confirms the Moment lands.**

So the chain closes: hours made the day shortenable, a shortened day made the
dawn beat repeat, and the repeating beat is what makes one decisive contest per
day watchable as a rhythm rather than as an event you wait for.

### What it also showed: the loser has nowhere to go

Observed by the author in the same sitting. **The loser does not wander off —
he stands in the field.** His `WorkTheField` drops off the ballot exactly as
designed, `StayUp` catches him as the floor, and then he is a man standing
still in a furrow he is not allowed to work.

**That is correct behaviour and an honest limit, not a defect.** Nothing else
is built yet: there are no beds, no tavern, no walking, so `StayUp` is not
merely the floor of his ballot, it is the whole of it. The plan's promise —
*"he picks a different life"* — is currently satisfied in the ledger (his
utility curves genuinely re-scramble and a different action wins) but not yet
in the fiction, because the different life has nowhere to happen.

**This is the strongest possible argument for rung 4's Moment**, and it should
be read as the setup for it rather than as a complaint about rung 3. Rung 4's
Moment is *"the other sets off, gets outbid en route, and turns around
mid-field"* — the loser doing something visible with his loss. Rung 3 proved he
loses; rung 4 is where losing goes somewhere. 6a and 6d then give the somewhere
a reason (hunger, company) rather than only a destination.

### What this licenses for the rungs above

**Shortening the day is now a proven instrument, not just a tuning
convenience.** Any rung whose Moment is a once-a-day crossing can be watched
the same way — 6a's three drives competing, 6b's work falling off the graph at
quota, 6d's first full day. That is worth knowing before those rungs are built,
because each of them was written expecting to be watched at normal speed.

It also means the day-long tenancy needs no softening. If the beat ever wants
adjusting, it is the day length or a curve — **never a fairness rule, a
rotation, or a priority scheme**, all of which Decision 2 already refused and
none of which the Moment turned out to need.

### Plan edits this implies

**APPLIED 2026-08-11** (most rows had already landed 2026-08-09; the rest were carried across on 2026-08-11 after a row-by-row audit found them missing). Rows that are deliberately NOT carried across, because a later decision overturned them, are struck through or banner-marked in place.

| Section | Change |
|---|---|
| Rung 3 (Moment) | Mark the open question closed: the day-long Moment reads, watched at a shortened day. |
| Decision 2 → *Deliberately left open* | The single item there is closed by this section. |
| Rungs 6a / 6b / 6d | Note that their Moments are once-a-day crossings and are meant to be watched at a shortened day, the same instrument rung 3 proved. |

---

## Decision 14 — Travel cost is subtracted, and denominated in hours

**Settled 2026-08-10. Author's call. Amends Decision 7, which specified a
multiplier.** Found while writing rung 4's session prompt, before any of rung 4
was built — the arithmetic was worked out in advance rather than discovered by
tuning, which is why this is a decision and not a bug report.

> **⚠ AMENDED THE SAME DAY BY DECISION 15 — read that first.** The
> multiply-vs-subtract rule, the hours denomination and the two seams below all
> stand. **What does not stand is subtracting travel cost from an action's score
> against OTHER actions, and the `patience` weight that did it.** Travel cost
> only ever competes the same alternative at different locations. If you read
> this section alone you will build a mechanism the author overturned.

### The question

Decision 7 settled that travel cost **scores and never gates** — a far place is
*outbid, never barred* — and specified the mechanism: a multiplier, `1.0` at his
feet, falling off, never reaching zero, with the knob
`distance_that_halves_appeal` on `Person`.

**Worked against the shipped town, that mechanism mutes the commute entirely.**

### What is wrong with multiplying, and it is not "the numbers are small"

Utility here is an **absolute, band-limited scale with no meaningful zero.**
`StayUp` runs 47.3 → 87.3 across the day and is the neutral baseline of being
awake with nothing pressing; `Sleep` is adenosine, 0 → 100; `WorkTheField` runs
43 → 103. What decides anything is not a score but the **margin** between two of
them — work beats idling by 2.3 at 04:41 and by 15.7 at midday.

A multiplier scales the whole number, and the whole number is mostly baseline.
So a 10% travel penalty removes about 7 points and wipes out a 2.3-point margin
several times over. **It does not tax the journey, it taxes the man's entire
reason for being awake.**

Measured, at Decision 7's own suggested `distance_that_halves_appeal = 12` and
the shipped 19.24 units between the Inn and the Fields:

```
falloff ×0.384      work from the Inn at midday = 39.6      StayUp = 87.3
```

**A man at the Inn would never go to work at any hour of any day**, and it would
present as a broken walking system rather than as a curve. Holding work's peak
under the adenosine ceiling *and* getting him to set off turned out to be
mutually exclusive; satisfying both forces the halving distance past 130 units,
seven times the width of the town — a falloff curve that does not curve.

> **Muting a commute is barring it, wearing different clothes.** The author's
> ruling: *"it should never outright mute a commute to work, that's nonsense."*
> That is Decision 7's own *outbid, never barred* principle, applied to the
> mechanism Decision 7 chose.

### The rule: which costs multiply and which subtract

Both shapes are legitimate and they describe different things.

| | Shape | Because | Examples |
|---|---|---|---|
| **How good is this instance** | **multiply** | it genuinely scales the reward | a rich plot against a poor one; a bed against a ditch; a half-yield field |
| **What you spend to get it** | **subtract** | you pay it identically whatever the reward turns out to be | hours walking, effort, a toll, a fee |

**Travel is unambiguously the second.** You spend the same two hours whether the
plot is rich or poor, so the cost cannot be a function of the prize.

So: `score = pull + daylight_pull * sun − patience * hours_to_reach`, where
`patience` is **the action's own weight** — which is how *"a man walks further
for a bed than for a beer"* is finally expressed, and it lives on the action
because it is a fact about the errand, not about the man.

### Denominated in HOURS, and this is the load-bearing half

`get_travel_cost_to` returned raw distance — `19.24` — a number with no meaning
attached, so **any** weight on it is arbitrary and every retune is guesswork.
Denominated in hours it becomes a real quantity: *this trip costs me ten
minutes.* Four things follow, and the first is the reason:

1. **The weight gets an honest unit** — "what an hour of walking is worth in
   appeal" — so it can be reasoned about rather than fiddled.
2. **It is the last un-denominated quantity in `game/`.** `CLAUDE.md` already
   rules that every rate is per world hour; distance was the one holdout.
3. **It is what roads and rivers actually change.** A road does not shorten the
   distance, it shortens the *trip*. Decision 7 already named this function body
   as where they install.
4. **It makes the falloff knob unnecessary.** A faster traveller already finds
   everywhere cheaper, so travel speed does the *"how far will he walk"* job
   that `distance_that_halves_appeal` was invented for. **That export is
   dropped** — one knob, not two doing the same work.

### Two seams, and the division of labour between them

**The author's call: travel speed is its own call site, because walking is only
one way to travel.**

```gdscript
# person.gd — the MEANS. On foot today; a horse, a cart, a boat, a bad leg,
# or a sack of grain on his back all install in this one body.
func get_travel_speed() -> float:
    return walk_speed

# person.gd — the JOURNEY. Straight-line today; roads, a river crossing, a gate
# shut at night, and one day a world spanning several towns install here.
func get_travel_cost_to(place: Place) -> float      # now returns HOURS
```

Keeping them apart is the point: **a horse changes the first, a road changes the
second**, and neither one has to know about the other. Same shape as
`Brain.get_adenosine_recovery()` — a seam with one modifier behind it today.

### Scale: the visual town is a diorama, and travel speed is what maps it

**Author's ruling: a decent-sized town is a five to fifteen minute walk to the
fields.** The Inn and the Fields sit 19.24 units apart, and a person capsule is
1.7 units tall — so if units were metres, that crossing is a fourteen-second
stroll and every journey in the game is instant.

> **Travel speed is therefore calibrated from the FICTION, not from a realistic
> metres-per-second.** Set it so crossing this town takes the five to fifteen
> minutes the fiction claims, and do not let anybody "correct" it to human
> walking pace — that would make every journey free and delete the cost this
> whole decision is about.

At a ten-minute crossing, `walk_speed ≈ 115 units per world hour`. The geometry
still matters exactly as before: double the distance and you double the time,
which is what keeps standing check #3 mechanical.

### The invariant, and its mechanical form

> **No place in the town may be made unreachable by its own travel cost.**

Checkable, and it should be a probe claim rather than a hope: *work at its best
hour, from the farthest place in town, still beats `StayUp`.* At a ten-minute
crossing that holds for any `patience` below about 94, which is enormous
headroom — the point being that hours-denominated subtraction makes muting hard
to do by accident, where multiplication made it the default.

### What this costs, and what it buys back

**Retired from Decision 7:** the multiplier, the *"never reaching zero"*
property, `distance_that_halves_appeal`, and the probe assertion that a far
station *"still scores above zero"* — under subtraction a distant option goes
negative. **The principle is untouched**: it is still on the ballot, still
scored, still merely outbid. Only the arithmetic changed.

**Bought back, and this was the surprise:** because a man standing on the plot
pays nothing, **`WorkTheField`'s tuned `73 / 30` does not move at all** and
bedtime is untouched. The whole conflict dissolves rather than being tuned
around.

### ~~The consequence rung 4 must tune for — the interruption is an inequality~~

> **⚠ THIS ENTIRE SECTION WAS OVERTURNED BY DECISION 15 — kept only as the
> record of a mistake, and it is the mistake this project most wants to catch.**
> The `patience` weight all three "ways out" below hang on does not exist and
> never did. Its only real job was to delay the farmers' departure so the loser
> would be outbid *en route* and the Moment would match the build plan's
> wording — **building the observation instead of the cause.** Decision 15:
> *"There is no tuning problem, no inequality, and no retune."* Rung 4 shipped
> 2026-08-11 with the score untouched and nobody outbid mid-stride, and that is
> the correct behaviour. **Read nothing below as an instruction.**

Rung 4's Moment is a man *outbid while still walking* — that is the rung's proof
that interrupting costs nothing. It only happens if the loser has set off before
the winner claims:

> **waking gap < commute time**

The shipped numbers give a waking gap of **80 minutes** (Hobb 04:41, Zoogs
06:01) against a **ten-minute** commute, so whoever wakes first always wins and
**nobody is ever interrupted.** Three ways out, and rung 4 must pick one
deliberately rather than tune into it:

1. **Set `patience` high enough that work does not pay before sunrise**, so both
   men are awake before either sets off and the race is decided on arrival. Good
   fiction — you do not cross town in the dark for work — and it needs a speed
   difference to decide, which is where `strength` feeding `get_travel_speed()`
   earns itself as Decision 12's predicted second job.
2. Shrink the waking gap (`strength` ≈ 1.02), which weakens Decision 12's
   deliberately visible 04:41.
3. Lengthen the commute past 80 minutes, which contradicts the town scale ruled
   above.

**Recommended: 1.** At `patience ≈ 36` both set off around 06:07.

**And the interruption is brief by construction** — a 15% speed advantage over a
ten-minute walk is about 1.3 minutes. **Rung 4's Moment therefore wants the day
SLOWED DOWN, not sped up**, which inverts Decision 13's instrument: rung 3
needed a short day to see the beat repeat, rung 4 needs a long one to see the
walk happen at all.

### Plan edits this implies

**APPLIED 2026-08-11**, together with Decision 15's table below — with the rows
that Decision 15 overturned dropped rather than applied. See that table.

| Section | Change |
|---|---|
| Rung 2 / `get_travel_cost_to` | Returns **hours**, not distance units. Add `Person.get_travel_speed()` beside it and state the means/journey split. |
| Rung 4 | Travel cost **subtracts**; the falloff curve and `distance_that_halves_appeal` are **cut**. Add `walk_speed`, calibrated from the fiction. |
| Rung 4 (probes) | Replace *"the farther one still scores above zero"* with the invariant: the farthest place in town is still reachable at the best hour. Keep *nearer outscores farther*. |
| Rung 4 (Moment) | State the `waking gap < commute` inequality, and that this Moment wants a **long** day where rung 3's wanted a short one. |
| Decision 7 | Amended, not overturned — the split it settled (identity check vs travel cost) and *outbid, never barred* both stand; only the arithmetic and the knob change. |
| Decision 12 | `strength` feeding `get_travel_speed()` is its predicted second job, and is what decides an arrival race. |
| Rungs 6d / 7 | The anti-herd damper still has its input; it is now a subtraction in hours. |

---

## Decision 15 — What distance is allowed to decide, and what a man can know from afar

**Settled 2026-08-10. Author's call. Amends Decision 14 (the same day) and, with
it, Decision 7.** Two rulings from one exchange. They interlock, and both say the
same thing from different ends: **geography may not pre-empt a want.**

### How this came up, because the failure is instructive

Rung 4's prompt had been written with a `patience` knob whose only real job was
to delay the farmers' departure until both were walking at once, so that the
loser would be outbid *en route* and the Moment would look the way the build
plan describes it.

**That is building the observation instead of the cause** — this project's own
banned shape — and it had already been written into a session prompt as *"the
one thing this session must tune,"* which would have propagated it into the
build. The author caught it:

> *"ur trying to fit in a system to fit that specific moment rather than asking
> me if the moments as they'll unfold is sufficient."*

**The lesson is more general than the knob.** A Moment in the build plan is a
prediction about what the causes will produce, not a specification to be
satisfied. When the natural behaviour and the written Moment disagree, the
question to ask the author is *"is what actually happens sufficient?"* — never
*"what can I add to make the written one occur?"* A rung that tunes its way to a
predicted tableau has proved nothing about its seams.

### Ruling 1 — Freeness is knowable only where you are standing

Rung 3 built `WorkTheField`'s gate to ask whether a plot is **free** from
anywhere in the world. With everybody standing in the same field that was
invisible; the moment distance exists it is **omniscience**, and it is what
forced the knob: a man at the Inn knew the plot was taken, so work never reached
his ballot, so he never set off, so nothing could ever interrupt him.

> **What he knows about a station depends on whether he is standing at its
> place.** Not there → he knows it EXISTS, not whether it is taken; it stays a
> candidate and the urge to work stands. There → he can see it; taken by
> somebody else, it drops out and work leaves his ballot **at the moment he
> arrives.**

One condition on the candidate query, no new knob, and it mirrors a rule the
codebase already has — **presence is required to claim, and now presence is
required to know.**

**`Workstation.is_free_for` does not change.** The station goes on reporting the
plain truth about itself; what a man KNOWS of that truth becomes the Action's
business. That is the right seam: the world is not obliged to lie, and knowledge
is not a property of a plot. *(The comment on that function, written earlier the
same day, argues the opposite case and must be corrected — its code is fine.)*

**This is the standing default restored, not a new idea.** Decision 1 already
described the notice board as moving discovery *"from DO — he wandered into the
square and happened to find a seller — up into GATE, he knows before he leaves,
so the walk has a cause,"* and **deferred it.** Rung 3 quietly shipped that index
for work before the town had earned it.

**The wasted journey is the point.** A man who walks to the field and finds the
job gone is the collision that later *earns* the notice board, which is this
project's whole method for deciding when a seam has paid for itself. Pre-solving
it with omniscience would delete the evidence.

It also makes rung 3's second counter truer: *"every candidate was taken"* starts
counting **men who turned up and found no room**, rather than men who
theoretically could not have worked.

### Ruling 2 — Travel cost competes the same alternative at different locations, and nothing else

Decision 14 had travel cost subtracted from an action's score, where it competed
against *other actions* — work-at-a-distance against standing-here. **That is
what let it mute a commute**, and no weight is small enough to make it right in
principle.

> **Pull decides WHAT you do. Travel cost decides WHERE you go to do it.**
>
> Travel cost belongs to choosing among an action's **candidates** — this plot
> or that one, this tavern or that one. It never enters the comparison between
> one action and another.

**Muting a commute stops being a tuning invariant to check and becomes
structurally impossible**, because the comparison that could mute it never
happens. A want can no longer be vetoed by geography.

**And `patience` was the wrong name for the wrong thing.** It implied a
psychological trait — tolerance for walking — when the quantity is only ever a
conversion from hours into appeal. The author's phrasing: *"it's not patience per
se, which sounds like a different mechanism; it's more just a utility multiple on
travelling."*

**Every use of travel cost anywhere in the plan already fits this narrower
rule**, which is the strongest evidence it is the right one:

| Where | The comparison | Same alternative? |
|---|---|---|
| Rung 4's probe — *a nearer station outscores an identical farther one* | plot vs plot | ✓ |
| 6d's anti-herd damper — *a far crowd loses to a near one* | `Socialise` candidate vs candidate | ✓ |
| Decision 6's trade herd, damped the same way | `Trade` candidate vs candidate | ✓ |
| **Rung 4's `patience`, as written** | **work-there vs stay-here** | **✗ — the only offender, and it was mine** |

### What this leaves the coefficient doing, and why it is not built yet

If candidates are identical apart from where they stand, ordering by
`appeal − k × hours` is just ordering by hours, **at any positive `k`.** The
coefficient only decides anything when candidates differ in **quality** — a rich
plot far away against a poor one nearby.

**Nothing has quality until rung 9a** brings `Recipe` and yields. So the
coefficient is currently **unobservable**, and exporting a number nothing can
read is substrate before need. **Do not add it.** Note the seam where it will go
and let 9a earn it.

### What rung 4 therefore has to change: nothing about scoring

This is the useful consequence, and it is worth stating plainly because two
prompt drafts said otherwise:

- **`WorkTheField.get_utility_score` keeps `pull + daylight_pull * sun`.** No
  subtraction, no coefficient. **`73 / 30` stands untouched.**
- **`Town.find_workstations` already sorts by travel cost**, stably, node path as
  tiebreak — shipped at rung 3. Travel cost is already doing its only job.
- **There is no tuning problem, no inequality, and no retune.** The entire
  difficulty of the last two drafts was manufactured by putting travel cost in
  the wrong comparison.

### Honest note on the hours denomination

Sorting by hours and sorting by distance are the **same ordering** for one
person, since travel speed is positive — so at rung 4 the unit change from
Decision 14 buys **no observable behaviour**. It is kept anyway, cheaply, because
it is the honest unit, because `get_travel_speed()` is genuinely needed the
moment anybody walks, and because hours are what a road or a horse actually
changes. **It earns itself at 9a** (quality against distance) and the first time
two people travel by different means. Recorded so nobody looks for an effect at
rung 4 and concludes the change did not work.

### Casualty, recorded so it is not re-derived

*"A man walks further for a bed than for a beer"* — Decision 7's per-action
distance sensitivity — **retires as a travel-cost expression.** Under this
ruling, wanting the bed more simply means the bed's pull is higher. There is no
cross-action distance term left for it to live in, and it does not need one.

### Plan edits this implies

**APPLIED 2026-08-11**, when rung 4 shipped. Every row below is now reflected in
`proving-scene-build-plan.md` and in the amendment headers on Decisions 7 and 14.

| Section | Change |
|---|---|
| Decision 14 | Amended: keep multiply-vs-subtract, hours, the two seams, scale-from-fiction, and the cut of `distance_that_halves_appeal`. **Drop** the subtraction from cross-action scores and the `patience` weight. |
| Rung 3 (`workstation.gd`) | The comment on `is_free_for` justifying remote freeness is **backwards** — correct it. The code stands. |
| Rung 4 | No scoring change. Freeness becomes locally knowable in `WorkTheField`'s candidate query. `walk_speed` + `get_travel_speed()` remain. |
| Rung 4 (probes) | *"Nearer station outscores an identical farther one"* is now a **candidate-ordering** assertion, not a score assertion. Add: a man walks to a plot he cannot yet see the state of, and work leaves his ballot **on arrival**. |
| Rung 6d / 7 | Dampers unaffected — both were always candidate-vs-candidate. |
| Rung 9a | The travel-cost coefficient earns itself here, when candidates first differ in quality. |
| *Method* | Add the general lesson: a Moment is a prediction about causes, not a specification. Ask the author whether what actually happens is sufficient. |

---

## Decision 16 — What physics is for

**Settled 2026-08-11. Author's call.** Forward-looking: **nothing on the current
ladder is gated on this.** It is recorded because a cold session looking at a
`CharacterBody3D` with a `CollisionShape3D` on it will reasonably assume
`move_and_slide()` was an oversight, and because the combat ruling it rests on
lives in a GDD from May that nobody reading `game/` would think to open.

> **Collision is for the eye and for the route. It never decides an outcome.**

### Three consumers, and not one of them is a resolver

| Consumer | What it is | Touches the sim? |
|---|---|---|
| **Animation** | presentation | no |
| **Walls** | what the navmesh bakes from | no |
| **Pathfinding** | what makes travel cost honest | **yes** — via `get_travel_cost_to` |

### Combat resolves on the card stack, never on a collision

This upholds the identity cut recorded in the 2026-05-18 crystallisation:
**"no action combat, no twitch stealth — failure must be cognitive, not
mechanical."** Collision answers *"can I reach him, is he cornered, is there a
table between us"*. The stack answers *"what happens."* A hit is always the
effect of a card that was played, never something the engine emitted.

**The argument that settles it, and it was not previously written down
anywhere.** A stack resolver is arithmetic, so it produces the same answer
whether you are standing there or a hundred miles away. A physics resolver
cannot run at all without frames — so two guards brawling in a village you are
skipping past would need a SECOND resolver, and the same fight would come out
differently depending on whether anybody was looking.

> **In a game about consequences accumulating while you are elsewhere, an
> unwatched event must resolve exactly as a watched one does.**

That single property rules out physics-resolved combat on its own, independently
of the identity cut, and it is the reason to keep the ruling even if the card
mechanics change shape later.

### What a `body_entered` signal would have cost

Worth stating so nobody reaches for it as a shortcut. Damage written from a
collision signal is a write from **no decision**, arriving outside the tick
order, in a design where DO is the only writer and every effect follows from
something a person chose. You would also lose attribution — *"why did that
happen to me"* stops having an answer — which is the opposite of a game whose
failures are meant to be legible.

### The consequence nobody expected: fast-forward SURVIVES walls

Walls sound like `move_and_slide()` and collision response, and they are not.
**If pathfinding routes AROUND a wall, the walker never hits one** — so nothing
ever has to be physically stopped.

- Walking stays exactly what rung 4 shipped: integrating `global_position`
  toward a point at constant speed. `move_and_slide()` never arrives.
- The only change is that the point is the **next waypoint** rather than the
  destination, and **the overshoot clamp works unchanged, per waypoint.**
- Headless pumping, the probe's movement claims, and a week simulated in seconds
  all keep working. (Decision 4 is why this matters: `move_and_slide()` moves
  **zero, silently** under `PROCESS_MODE_DISABLED`.)

**Collision shapes exist to bake the navmesh and to make animation land right —
not to stop anybody walking.**

### Travel cost under pathfinding

`get_travel_cost_to` becomes **path length ÷ speed**. That installs in that one
function body and no call site changes, which is exactly what its own comment
already promises about roads and river crossings.

**Keep `GoToStep` stateless.** The obvious implementation stores the path, which
is the remembered plan the whole design refuses to keep. Ask the navmesh *"which
way from here?"* each tick — a query, re-derived, nothing held. It costs more per
tick and buys back free interruption.

### The movement strategy, IF physics movement is ever genuinely needed

Not now. Written down so the surface stays small when somebody reaches for it.

```gdscript
# The ONLY thing that differs: how a requested displacement lands on the body.
# Returns what the body ACTUALLY moved, which may be less than was asked.
func apply_movement(person: Person, movement: Vector3) -> Vector3
```

Hung off **`Person.get_mover()`**, mirroring `get_travel_speed()` — the body
decides, and no caller learns there was a choice.

**What must NEVER move into the strategy:** arrival semantics, either edge of
`current_place`, travel cost, or the decision. Put arrival in there and you get
two arrival rules, and the radius model returns through the physics one.

**Do not build it.** One implementation behind an interface is ceremony, and the
seam that matters — `GoToStep` is the single place anything moves — already
exists. When physics genuinely arrives, `GoToStep` grows a branch; extract this
only if that branch turns ugly.

### Left open, deliberately

- **Straight-line for DECIDING vs. real path for WALKING.** `find_workstations`
  calls `get_travel_cost_to` per station, per sort, per tick, per person; a
  `distance_to` is free and a navmesh query is not. Deciding by straight line
  means a man sets off for the near field and finds the bridge out — arguably
  good content, but it must be **chosen, not discovered.**
- **Whether `NavigationServer3D` and `PhysicsDirectSpaceState3D` queries return
  anything useful inside the probe's disabled scene**, where the nav map may
  never sync and the physics server may never step. **Unmeasured.** Short
  experiment, and it belongs BEFORE walls arrive, not during.

### Plan edits this implies

None yet — nothing on the ladder builds this. When walls land,
`get_travel_cost_to` gains path length and `GoToStep` steers by waypoint; both
were already named as the places those install.

---

## Decision 17 — How an embodied player gets a place

**Settled 2026-08-11. Author's call.** Extends the 2026-08-08 location ruling,
which settled `current_place` for **decision-driven movers** — everyone who
existed at the time. The player is a category that ruling never covered.

### The hole

`GoToStep` owning both edges of `current_place` is only true while **every move
follows from a decision.** The player is the first mover that does not: nobody
chose *"go to the Inn"*, somebody pushed a stick. He arrives long before
knockback or any other physical shove does.

### Why the obvious fix is the one already reverted — and worse here

Walk into an `Area3D`, write `current_place`. That is the proximity model retired
on 2026-08-08, and probe claim 7 exists to stop it returning.

**For the player it is a SIM problem, not a UI one.** `Town.find_people_at()`
cannot tell a player from an NPC. Stand on a boundary and your place flickers
Inn → null → Inn, and you flicker in and out of **every NPC's candidate list** —
rung 7's trade gate matches you, then does not, then does. It would read as
*"the AI is flaky"*, which is the exact failure `work_the_field.gd`'s header
warns costs a day to trace.

### The contract, and where the wall already is

> **The player's place must be exactly as crisp as an NPC's**, because nothing
> downstream can distinguish them.

Same field, same accessor, same discrete answer, no flicker. **What differs is
only the WRITER:**

| | Writer | Driven by |
|---|---|---|
| NPC | `GoToStep` | a decision |
| player | an input-driven writer | input |

`get_current_place()` is already the accessor everything reads, so nothing else
in the game moves. `find_people_at`, the trade gate and every `is_available_to`
keep working, because all of them only ever read.

### The mechanism: a band, not a line

> **Enter on crossing an INNER boundary. Leave only on crossing an OUTER one.**

The reverted model used **one** radius, and one line is a thing you can stand on
and jitter across. The sleep cycle already solved this with **two** — *"sleep
starts winning high and stops winning low, so there is a wide gap rather than one
line to sit on."* This is that same house pattern applied to space instead of to
adenosine. It is not a new mechanism.

**Interiors get it free.** A door is naturally discrete — you are in the Inn or
you are not. The band is only needed for open ground: the fields, the square.

### Left open

The band width. It is a tuning number and nothing can read it yet.

### Plan edits this implies

None yet — there is no player character on this ladder. Relevant the moment one
exists, and to rung 7's *"same place?"* gate, which is what would go wrong first.

---

## Decision 18 — The sim owns duration; the animation illustrates it

**Settled 2026-08-11. Author's call.**

> **The animation does not decide how long it takes. It is told.**

### The inversion this exists to prevent

*"The leaving animation has to resolve before the step moves on"* is the natural
way to think about it, and it is backwards. Gating a step on an animation
**commits** the decision for that animation's duration — which stores progress
(*"I am 0.3 s into leaving"*) and breaks the rule the whole substrate is built
on:

> *"An ActionStep holds NO progress… Interrupting costs nothing. Nothing was
> suspended, so nothing has to be put back."*

### What to do instead, when a transition should be legible

**Put the time in the WORLD, not in the renderer.** If straightening up and
shouldering a tool should take ninety world seconds, that is ninety world seconds
of a **step**, and the animation fills the window it is given.

Legibility then belongs to the simulation, which means it survives being
fast-forwarded past, written to a log, and happening where nobody is watching.
Animation-owned duration gives you none of those — the same property Decision 16
turns on.

**And the wind-down stays outbiddable.** It is just another thing on the ballot:
fire breaks out mid-put-down, `Flee` outscores it, he drops the tool where he
stands, and nothing needed unwinding. **That is the legible beat AND free
interruption, which the blocking version cannot have both of.**

### The visual half is already seamed

`person.tscn` carries `Shape` as a **child** `MeshInstance3D`, separate from the
body — so the authoritative transform can move per the sim while the mesh blends
and lags a few frames behind it. Presentation being slightly late is invisible;
presentation being **authoritative** is what bites. Same precedent as the
`Readout`, which deliberately rides `_process` rather than `think_and_act`.

### Animation thrash is already prevented, and rate is not the lever

The real risk in re-deciding every tick is **oscillation** — walk/work/walk
across three ticks, and a blend tree convulses. The actions already prevent it,
with the same hysteresis band Decisions 17 and 11 both lean on.

> **Do NOT throttle the decision rate down to animation speed.** Decision
> *stability* is the property that matters, not decision *rate*, and throttling
> couples the simulation to the renderer — the same mistake as letting an
> animation gate a step, wearing a different hat.

### What this asks for that does not exist yet

A vocabulary for **transitions that take world time**: a short wind-down step,
outbiddable, holding no progress. That is the shape `Sequence` was for, and it is
sitting unported in git history — port it by hand when something needs it, never
wire to it.

### Plan edits this implies

None yet — no rung on this ladder animates anything. Relevant the first time a
Moment is meant to be *read* rather than measured off a graph.

---

## Decision 19 — Every want is a gap

**Settled 2026-08-12. Author's call.** Closes the question Decision 1 explicitly
left open. Does not overturn it — Decision 1's `target − stock` is this rule,
stated for one case.

### The question

Decision 1 settled where want comes from **for trade**, and said the body's
appetites might be the same rule without settling it. Rung 6a brings `hunger`,
the first appetite, and the ladder has no account of what wanting *is*. Every
`get_utility_score` in `game/` is a hand-written formula answerable to nothing
but itself, and the count of them is about to grow.

### What was settled

> **A want is a gap between how things are and how they should be.**

One sentence, and it covers everything on the ladder:

| The want | The should-be | The is | Where the gap lives |
|---|---|---|---|
| tired | rested | `adenosine` | the body |
| hungry | fed | `hunger` | the body |
| lonely (6d) | company wanted | company had | the body |
| a miller's quota (7) | `target` | `stock` | a barn |
| an obligation (6b) | owed | delivered | the agreement |

Decision 1's `target − stock` is the barn row. Nothing about it changes; it stops
being a rule about trade and becomes one case of a rule about wanting.

### What this immediately exposes

**`WorkTheField`'s `pull = 73` is not a design choice. It is a placeholder
standing in for a gap that has not been built yet.** Work has no should-be behind
it at 6a — the 73 is a hand-placed constant doing the job a quota will do at 6b,
and the same is true of `StayUp`'s 67.3 (see Decision 21).

This is worth stating because it changes how those numbers should be read when
they cause trouble. A flat pull that has to be re-tuned every time a new action
lands is not a tuning problem; it is a **missing gap**, and the fix is to build
the gap rather than to re-place the constant. Expect most of the 73 to dissolve
at 6b.

### The test that keeps it honest

> **If he did this constantly, would he stop wanting it?**

Yes → it is a gap. Eat constantly and you stop wanting food. No → it is something
else, and Decisions 21 and 22 are where the something-elses live.

This test is the guard against the model becoming vacuous. Any behaviour can be
dressed as a gap by inventing a hollow for it ("a whittling deficit"), and once
that is allowed the rule has stopped saying anything. Apply the test before
adding a stat.

### Where a gap comes from — the seam this names

A gap has a **source**, and the source is a thing in the world. The body for
appetites, a barn for a farmer's quota, an agreement for an obligation, and — see
Decision 24 — a town's ledger for a lord's work.

**A role is which ledger your work reads.** Same person, same formula, same
temperament; only the source of the gap differs. That is what makes promotion
mechanically real later, and it is why this is one seam and not a family of
special cases.

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| Rung 6a | `hunger` is the first gap with a body behind it. Its stat comment should say *what it is the gap to* (fed), not merely what it counts. | not yet |
| Rung 6b | Work's quota is not a new mechanism — it is `WorkTheField` finally getting the gap its 73 stands in for. Expect the flat pull to shrink when it lands. | not yet |
| Decision 1 | Unchanged and uncontradicted. A forward-pointer banner on it is the author's call; none was added, since append-only means an edit needs a reason stronger than tidiness. | n/a |

---

## Decision 20 — The want formula

**Settled 2026-08-12. Author's call.** Rests on Decision 19.

### The question

Given that a want is a gap, how does a gap become a number on the ballot? And
can one formula serve every action, so that a new behaviour slots in and competes
intuitively without re-placing every existing constant?

### What was settled

> ```
> want = weight × gap ^ bite
> ```
>
> - **`gap`** — 0 to 1. How far from how it should be.
> - **`bite`** — how sharply it amplifies. The author's word for this is
>   **urgency**: a buildup that can no longer be ignored, where the *type* of
>   urgency sets how fast the amplification comes on.
> - **`weight`** — what it is worth when the gap is total. May be a function of
>   the world. This is where the sun lands, and where lenses land (Decision 22).
>
> A want with no gap yet is `gap = 1`, and the formula collapses to
> `want = weight`.

### Why this one: it reproduces every shipped number exactly

This is the argument that carried it. It is not a rewrite — it is a way of
**reading** the four numbers already measured and living in `game/actions/`:

| Shipped | weight | gap | bite | comes out as |
|---|---|---|---|---|
| `StayUp` | `67.3 + 20 × sun` | 1 | — | `67.3 + 20 × sun` ✓ |
| `WorkTheField` | `73 + 30 × sun` | 1 | — | `73 + 30 × sun` ✓ |
| `Sleep` | `100` | `adenosine / 100` | 1 | `adenosine` ✓ |
| `Wake` | `10` | 1 | — | `10` ✓ |

Every action in the game today is this formula with one of the two interesting
parts switched off. `Sleep` is the only one with a real gap, and its `bite` is 1,
which is exactly why it is a straight line and why the graph reads so cleanly.

**Rung 6a's `Eat` is the first want in the game with both parts live.** Nothing
needs retuning to adopt this; adopting it tells you which knob each existing
action is missing.

### The sun modifies weight, not gap and not bite

"Work is worth more while the sun is up" is the world changing what a thing is
worth. On `gap` it would be nonsense — the sun does not make you less hungry —
and on `bite` it would be a claim about temperament changing hourly.

### Why `bite` above 1 is not optional at 6a

A straight-line `Eat` is arithmetically incapable of the thing rung 6a exists to
let you tune, and the failure is in both directions:

- Work at midday is **103**, and a stat with a 100 ceiling scored linearly can
  never reach it. A meal could never interrupt work, at any hunger, ever.
- `StayUp` at 22:00 is **50.0**, so a linearly-scored man half-empty in the
  evening scores 50 and eats. Then eats again. And again.

Straight line gives exactly the wrong day: never at noon, constantly at night.
`bite` is what makes "a bit hungry" mean *keep working*.

### Worked examples — ILLUSTRATIVE ONLY, DO NOT PASTE

The standing hazard applies with full force: **these are a worked check that the
shape behaves, not the settled numbers.** Call 4 of the rung 6a prompt is the
author's, at the keyboard, on the tuning board. Taking `Eat` at weight 130 and
bite 3 against the measured scale:

| When | The ballot | Outcome |
|---|---|---|
| midday, hunger 60 | Eat `28`, Work `103` | keeps working, does not think about it |
| midday, hunger 90 | Eat `95`, Work `103` | pushes through the last of the job — the knife edge |
| midday, hunger 97 | Eat `119`, Work `103` | stops. Only when nearly empty |
| 22:00, hunger 75, adenosine 50 | Eat `55`, Leisure `50`, Sleep `50`, Work `47` | eats his supper |

The last row is worth reading twice. Meals land in the **valleys of the waking
ladder** — the evening gap after work falls and before sleep wins — because that
is the cheapest hour on it. Supper is emergent, not authored.

### This answers rung 6a's Call 3 by arithmetic rather than by policy

Call 3 asks whether `Eat` is permitted to move bedtime, and frames it as the
author choosing between a protected baseline and better fiction. Under an
impulse meal (Call 2, and see Decision 23) it is neither — it is a measurement:

**`Eat` can hold the top waking bid for exactly one tick**, because the tick it
wins is the tick hunger collapses. One tick is 0.01 world hours. Bedtime moves by
at most 36 world-seconds, and only on a night hunger happens to cross within one
tick of 22:01.

The regression baseline is protected **structurally**, not by a tuning invariant
somebody has to re-check at every future rung — the same class of guarantee
`work_the_field.gd` argues for when it keeps travel cost out of the sum.

### What is deliberately NOT in the formula

Two candidate terms were designed and rejected during the same session. Both are
recorded because both are the obvious thing to reach for again:

| Rejected | What it was for | Why not |
|---|---|---|
| **`haste`** — a factor rising as a window closes | one-time events: a merchant in town today only, an invitation for tonight | The pressure does not need to be felt, because **the gap keeps growing across the misses.** Skip three market days and the cloth gap is three times bigger, and it outbids work on its own. Nobody sprints to market because it is nearly dusk; they go because their boots have been failing for a month. `haste` was a number standing in for a gap that was already doing the work. |
| **a lookahead term** — "will this still be available later?" | the same | It would be the first time anything in this world reasons about the future, and that door does not close again. Re-deciding every tick from current facts is what makes interruption free. Not worth trading for a case the growing gap already covers. |

**What stays unhandled, on purpose:** a true one-shot — a ship that sails once
and never returns. The gap stays open forever and nothing discharges it. That is
a story, not a bug, and the remedy belongs in the world being fair rather than in
the brain being clever. Same for a breached invitation: the obligation gap simply
stays open, and the consequence is social.

### Left open

- Whether `bite` is a property of the gap **type** (all hunger bites the same) or
  of the **person** (a stoic and a whiner differ). Both are one exported number;
  the fork is where it is authored. Nothing needs it settled until two people are
  meant to differ in temperament rather than in strength.
- Whether **how good the best available candidate is** may feed back into how
  much the action is wanted at all — "he stays up late for a good book but not to
  stare at a wall", "he has a drink because he is already at the inn". Decision 15
  bans cost from the sum, and its argument is about cost *suppressing* a want;
  both of these are cost *creating* one. **Retired for now** — the author's
  ruling is that this is quantity-demanded-scales-with-price, which is a market
  mechanism and there are no prices. Revisit when there are.

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| Rung 6a | `Eat`'s score must be non-linear in hunger. Two authored numbers, both plain English: *what starving is worth* (the one that decides whether a meal can ever interrupt work — must exceed 103 if it ever should) and *how sharply it bites*. | not yet |
| Rung 6a, Call 3 | Answered above. Not an author preference — a consequence of the impulse meal. Baseline holds to within one tick. | not yet |
| Build plan, rungs 6b+ | New actions are expressed as `weight × gap^bite`, not as a fresh constant placed by hand against every existing one. | not yet |

---

## Decision 21 — The baseline is a personality, not a floor

**Settled 2026-08-12. Author's call.** The author's word — *baseline*, not floor
— is load-bearing and is the reason the decision came out this way.

### The question

`StayUp` is documented as *"the placeholder every other waking action will
eventually outbid"*. Under Decision 19 it has no gap, so what is it a placeholder
**for**? And its `pull = 67.3` is doing two unrelated jobs at once:

- **the bar every action in the game must clear** — anything scoring below it
  never happens, all day
- **the bedtime threshold** — bedtime is where adenosine crosses the top waking
  bid, and in the evening that is `StayUp`

Want him to turn in later? Raise it — and you have silently made him pickier
about everything else he might have done all day. That coupling is the mechanism
behind rung 6a's Call 3 and it will recur at 6b, 6d and 7.

### Why "floor" was the wrong word

A **floor** is a minimum everything must clear, which is a ranking, and a ranking
authored by hand is the hierarchy this whole model exists to avoid. A
**baseline** is what is normally happening until something pulls you off it — and
a baseline can obviously differ from man to man, where a floor sounds universal.

### What was settled

> **`StayUp` is not a placeholder for a missing gap. It is a placeholder for a
> person.**
>
> What a man does when nothing is pressing is the most characterful thing about
> him. That becomes **one action — `Leisure`** — with whittling, drinking,
> praying and the rest as its **candidates**, chosen by his tendencies.

**One action, not several.** The author's call, and it is the correction that
makes this work: a bag of small tastes each bidding on the main ladder would put
personality in among the appetites and distort everything. `Leisure` is scored
once, and *which* leisure is a candidate question — the same two-stage shape
`WorkTheField` already uses for plots, and the same place travel cost and
candidate quality already live.

### What this fixes, and why the coupling stops being a bug

Bedtime is still where the tiredness gap crosses the top waking want, and in the
evening that is still the baseline. The coupling does not go away. **What changes
is that the number acquires a meaning.**

| | To move bedtime you change… | Which means |
|---|---|---|
| today | "what idling is worth" | nothing, and it silently re-tunes his whole day |
| with `Leisure` | "how much Zoogs likes whittling" | something, and bedtime follows for a reason you can point at on screen |

A man with a rich evening stays up. A man with nothing turns in early. Two men
with identical bodies visibly differ all evening from nothing but their
tendencies. That is fiction the current 67.3 cannot express at any value.

### Tendencies live in candidates, and only there

A tendency is *which*, not *whether* — "beer over wine" is not how much he wants
a drink. Candidate ranking is where it belongs, alongside travel cost and quality,
and it must not leak back into the action's score (Decision 15, and Decision 20's
Left Open).

### NOT this rung

`Leisure` is not rung 6a's work and must not be built there. 6a's job is `hunger`
and `Eat` against the shipped `StayUp`. This decision exists so that the hunger
curve is tuned by someone who knows the baseline is about to change shape.

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| Build plan | `StayUp` is scheduled to become `Leisure` at whichever rung first gives a man something to do with an evening. It is not scheduled for deletion. | not yet |
| Rung 6a | No code change. A note that 67.3 is currently doing two jobs, so hunger numbers tuned against it may want revisiting when the baseline gains tendencies. | not yet |

---

## Decision 22 — What may touch a want, and where

**Settled 2026-08-12. Author's call.** Two mechanisms that both look like they
modify wanting, and only one of them may.

### Part one — the gate is where the world answers back

`stay_up.gd` already carries the rule for its own case: *"IT IS A SCORE TERM AND
NEVER A GATE."* Generalised:

> **A gate asks about the world. It never asks how much he wants it.**

Every gate in `game/` is one of exactly two things, and both are facts:

| Kind | Asks | Examples |
|---|---|---|
| **candidate** | *do I know of anything that could serve this want?* | `WorkTheField` (find stations, find one free), `Eat` (have I bread), `Drink` (do I know of water) |
| **posture** | *is my body in a state where this is even a question?* | `Wake` needs him asleep; `StayUp` and `WorkTheField` need him awake |

Neither ever reads the size of the gap. **"Not hungry enough" is want, not
possibility**, and putting it in a gate is barring in a new coat.

### What the gate buys, which is the whole desert case

Because the gap grows whether or not anything can answer it, **a want with no
outlet is invisible on the ballot and not remotely idle.** It keeps building.

A man crossing a desert who knows of no water has `Drink` off the ballot for two
days while the gap goes to maximum in silence. He tops a dune, sees green, and
the gate opens on a want that has been screaming into nothing. He drinks
greedily. Nothing rose quickly — **something enormous simply became sayable.**

That is suffering modelled for free, and it is why no `haste` term was needed
(Decision 20).

The two branches are worth stating separately, because they are the two halves of
what a gate does:

- **He knows of an oasis, three days off** → `Drink` is *on* the ballot and
  winning hugely, and its step is a walk. He crosses the desert **because he is
  thirsty**, the want never dips, and on arrival the step stops walking and
  starts drinking. This is `WorkTheField` + `GoToStep` exactly.
- **He knows of no water at all** → no candidate, off the ballot, silent.

**Searching is a shared step**, in the `GoToStep` mould — one step several actions
borrow when a want's candidate is unknown, rather than each action growing its
own. Not built; named here so it is not reinvented per action.

### Part two — a lens changes weight or rate. Never gap, never the gate.

A **lens** is a state of a person that changes how everything else is weighed
rather than proposing anything itself: fear, drink, illness, grief. It is not a
competitor on the ballot.

> **A lens may multiply `weight`, or change a rate. It may never touch `gap`, and
> it may never gate.**

**Never `gap`,** because the gap is the truth about a body and the world, and
nothing is allowed to lie about it. Drink does not make a man less hungry; it
makes him care less. Same principle as `Workstation.is_free_for` reporting the
plain truth while the *action* handles what a man knows of it.

**Never the gate,** because gating is barring. "Distress disables work and
leisure" must be *distress crushes their weight* instead — the man does not
whittle because whittling is worth 3 while everything urgent is worth 100, not
because whittling was removed. The case that decides it is the panicking man
standing next to the rope that would save him: crush the weight and something
urgent enough still cuts through; close the gate and he cannot take it. **Outbid,
never barred** — the rule `CLAUDE.md` keeps by composition and refuses to give
back with a flag.

Where each lens lands is a one-sentence test a person would recognise:

| Lens | Lands on | Effect |
|---|---|---|
| fever | rate | tiredness builds faster |
| drink | weight | every gap is still there; he cares less about all of them |
| fear | weight | one want enormous, baseline crushed — a terrified man does not whittle |
| grief | weight | appetites untouched; he simply stops doing what he liked |

**The rate half already exists.** `Brain.get_adenosine_accumulation()` and
`get_adenosine_recovery()` are documented as *"the seam every future modifier
lands in — illness, age, cold, a stimulant, a wound."* That seam was built at
rung 0 without being named; this names it.

**And `brain.gd`'s warning stands unchanged:** name the places a lens can land,
because names are free; do **not** build a registry of modifiers with priorities
and stacking rules. There is one modifier in the whole game today (`strength`)
and it is a bare multiply. *"Systems built before they're needed get thrown
away."*

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| **Rung 6a — correction to the session prompt** | Call 2's table specifies `Eat.is_available_to` = *hungry AND has bread*. **The hunger half must be dropped.** Gate on bread and being awake only; hunger belongs entirely in the score. A man at hunger 5 already loses to the baseline's 47.3 floor without help, and dropping it also means `Eat`'s line is drawn rising and losing all day instead of as a gap — better instrumentation for a rung whose Moment is a graph. Probe claim 3 tests the bread half and is unaffected. | **not yet — read before writing `eat.gd`** |
| Rung 6a | The `is_awake` gate on `Eat` stands, and is a posture gate. Without it a man whose hunger crosses at 03:00 gets up and eats in the dark, presenting as a broken sleep cycle. | not yet |

---

## Decision 23 — Failure marks the candidate; success marks the world

**Settled 2026-08-12. Author's call.**

### The question

Two problems that turn out to be one. **Twitching:** an action whose score
collapses by only a tick's worth when taken will win, lose, win, lose across
consecutive ticks. **Spamming:** a man tries a locked door, nothing changes, so
next tick he tries the locked door. Both are the cost of re-deciding every tick
with nothing stored, and both invite the same wrong fix — a damping number or a
cooldown timer.

### What was settled

> **Every action leaves a mark. Success marks the world; failure marks the
> candidate — never the want.**

Succeeds: the loaf is gone, the plot is claimed, he is somewhere else. Fails: the
well is dry, the man refused, the door is locked — and that lands on **that well,
that man, that door**, which sinks to the bottom of the candidate list.

He does not stop wanting water. That would be barring. He picks the next-best
candidate; if there is none the gate closes and the want goes silent and keeps
growing (Decision 22).

### Why this removes cooldowns entirely

**"Try again later" costs nothing and is never written**, because the brain
re-decides every tick anyway. The well refills, it stops being a bad candidate,
he goes back. Retry is free.

The test for any cooldown anyone proposes:

> **What is recovering during it?**

Name it and build *that*; the cooldown disappears:

| The cooldown | What is actually recovering | Where it belongs |
|---|---|---|
| "he can't swing again yet" | stamina | a gap on the body — and a strong man recovers faster for free |
| "the well is dry for an hour" | the well's water | world state, not a rule about people |
| "only at matins" | nothing — it is a schedule | the clock, read by the gate |
| "don't ask him again straight away" | nothing — he is simply a worse candidate now | candidate ranking, where quality already lives |

**If you cannot name what is recovering, the cooldown is hiding a design hole and
should be refused.** Same shape as `haste` in Decision 20: a number standing in
for something that should have been changing on its own.

### The hysteresis rule this generalises

Rung 5 put the fraction in the furrow; `wake.gd` gets its band from a posture
change; `Eat` gets its band from the loaf leaving the bag. All three are the same
thing:

> **You do not twitch when the world actually changed.**

Which gives the check for any new action: *what in the world is different after I
do this once?* If the honest answer is "nothing", that action will twitch, and
the fix is the action — never a damping number, never a commitment bonus on
`current_action`.

**A commitment bonus is specifically refused.** `brain.gd` says `current_action`
is *"kept ONLY so you can see it… never fed back into the ranking"*, and it
already feeds `is_awake()`. That is the line: **current state may change what is
possible; it may never change what is wanted.** A stored preference for what you
were already doing makes "why did he keep doing that" unanswerable from anything
on screen.

### This settles rung 6a's Call 2

Call 2 argues one-tick-one-loaf from integer truncation — a count is a whole
number, 0.01 of a loaf per tick truncates to zero forever, and consumption from a
man's own pocket has no world object to hang a remainder on.

The hysteresis lens reaches the same answer independently and more strongly: **a
time-based meal needs a home for the meal-in-progress, and that is the identical
missing thing as the home for the fractional loaf.** One absence, two symptoms.
An impulse meal gets its band from the loaf leaving the bag and needs neither.

> **Rung 6a ships `Eat` as one tick, one loaf.** Consistent with Decision 6's
> *"one-tick resolution is accepted for now"*.

**The honest cost, which the Call 2 table understates:** a meal is a one-tick
label flicker. The hunger line shows it; the man does not. 6a's Moment is a graph
Moment, so it survives — but if a *visible* lunch break is ever wanted, the shape
is an episode with a home in the world (walk to the inn, eat, walk back, with
`GoToStep` doing the duration and his position holding all the state), and that
is 6d/7 territory, not 6a's.

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| Rung 6a, Call 2 | Settled: one tick, one loaf. | not yet |
| Build plan, all rungs | No cooldown fields, anywhere. A proposed cooldown is a prompt to name the depleted thing. | not yet |
| Rung 7+ | A refused trade partner is a *worse candidate*, not a blocked action. The want is untouched. | not yet |

---

## Decision 24 — Unmet need is recorded where it failed

**Settled 2026-08-12. Author's call.** Gives Decision 1's Seam 1 a shape, and
promotes two existing counters from telemetry to signal.

### The question

Decision 1 named two seams and left both empty: **record** (something accumulates
unmet demand and excess supply) and **revise** (something reads it and moves a
quota). Decision 23 leaves a residue — failure marks the candidate, but a failure
nobody aggregates teaches the world nothing. Both want the same object.

### The seed already in the code

`Town.note_no_candidates_existed()` and `Town.note_every_candidate_was_taken()`,
called from `WorkTheField.is_available_to`, are already a record of unmet want,
written at the moment of failure, held by the town. **They already found the
distinction that matters:** *"there was nothing"* and *"there was something and it
was not for me"* are different failures with different remedies.

**This crosses a line those counters explicitly draw.** `work_the_field.gd` calls
them *"TELEMETRY, NOT WORLD STATE"*, and the whole justification for writing them
from a gate is that *"nothing ever reads these counters back into a decision, so
they cannot change what anybody does."* Promoting them ends that exemption. It is
recorded here as a deliberate crossing rather than allowed to happen by drift —
and the gate-writes-telemetry exemption does **not** widen: a gate may note that
it failed, and nothing more.

### What was settled

> **When a want fails, the place it failed at records that it did. The record is
> a gap like any other, and it decays.**

The failure kinds are a small closed list, and each points at a different remedy
— which is exactly why they are recorded apart rather than as one counter:

| Why it failed | He does | What it says |
|---|---|---|
| nothing exists | searches, or goes silent | make one exist |
| all taken | tries elsewhere, or later | not enough of them |
| too far | walks — not a failure at all | build one closer |
| refused | asks someone else | a person problem |
| not permitted | — | a rights problem |

The first two exist. The rest arrive with their rungs — **"not permitted" is
rung 6b's `is_permitted_to()`**, so the ledger and the permission check land
together.

**The record decays**, at a rate, like every other gap (Decision 19). A well dug
last year stops showing thirst on its own. Without decay it is a log file and it
grows forever.

### Seam 2, and the thing worth holding on to

> **A lord does not need his own decision system. His *work* reads a bigger
> ledger.**

The author's refinement, and it is the correct one: a lord is still a person. He
gets hungry, he sleeps, his appetites are gaps on his body like anyone's. **What
differs is the source of the gap behind his work** — a farmer's is his barn, a
miller's is the queue at his mill, a bailiff's is one district, a lord's is the
town. Same formula, same `bite`, different ledger. That is Decision 19's source
seam, and it is what makes promotion mechanically real: hand a man a bigger
ledger and he becomes a bigger man, with no new decision machinery anywhere.

His **candidates** are remedies — dig a well, clear a field, appoint a bailiff,
send a merchant — and the failure kinds above are what tell them apart.

That is Decision 1's Seam 2 with a shape. Still nothing calls it, and that is
still correct.

### The property worth protecting: pressure, not petitions

Nobody asks. Nobody files anything. Men simply fail to get what they wanted, and
**the failing is the message.** The lord reads a heat map of frustration and acts
on it late, partially, or not at all, and the men never know a decision was made
about them.

This falls out of the mechanism rather than being written on top of it, and it
means the lord can be **wrong** — he can read pressure at the north field and dig
in the wrong place, with nothing to correct him but more pressure. A request queue
would have none of that.

### Left open — and it is a one-way door

**Does the ledger record who, or only how many?**

| | Buys | Costs |
|---|---|---|
| **anonymous** | the lord genuinely cannot see individuals — he knows the north field is thirsty, not that Hobb is. Fits the title exactly. Keeps the ledger tiny. | no favour, no grievance, no bailiff who knows whose plot is failing |
| **attributed** | favour, grievance, taxation, singling a man out. Much richer. | the king becomes someone you might be seen by |

Attribution is easy to add later and very hard to remove once anything depends on
it. **Not called.**

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| Decision 1, Seam 1 | Has a shape: recorded at the place of failure, by kind, decaying. Still uncalled. | not yet |
| Decision 1, Seam 2 | Has a shape: a role's work reads a ledger. Still uncalled. | not yet |
| Rung 6b | `is_permitted_to()` should record a *not permitted* failure when it refuses. Cheapest moment to add the third kind. | not yet |
| `work_the_field.gd` | Its telemetry comment will need amending the first time anything reads those counters back. Not yet — nothing does. | not yet |

---

## Decision 25 — Rung 6a lands hunger only

**Settled 2026-08-12. Author's call.** **Amends Decision 3, which carries a
banner pointing here.** The 6a–6d cut is not reopened; only 6a's contents change.

### The error

Decision 3 puts **hunger AND social** in 6a and says in as many words:

> *"hunger and social both rising in UPKEEP and both bidding against adenosine,
> and you watch which wins."*

Its Moment is *"three drives on one graph and you watch which wins."*

**`Socialise` is rung 6d.** At 6a there is no action anywhere that reads
`social`, so it cannot bid and it cannot win — it would be a line climbing
forever and touching nothing, for three gates. **The same applies to the
tavern**, which nothing visits until 6d: `Eat` is explicitly from the man's own
inventory, and `Drink` is rung 7.

This is the first case in the file where a settled decision's **prose** is wrong
rather than its code, and it is recorded as a caution: the standing scepticism
about pasted snippets applies to reasoning too.

### What was settled

> **Rung 6a lands hunger only** — the stat, its upkeep line, and `Eat` that
> consumes it. One drive, one consumer, one gate: the same clean shape rung 5
> had.
>
> **6d lands `social` + `Socialise` + the tavern together**, where the first
> thing that reads the stat arrives with it.

Two reasons, and the second is the one that decided it:

- A stat nothing reads and a place nobody enters are both **substrate before
  need** by the project's own rule.
- **The Moment would be false advertising.** "Three drives compete" would in fact
  be two drives competing and a spectator line rising in the corner.

### What is NOT part of this

**`Workstation.owner` ships at 6a regardless.** One exported field, may be null,
**no reader at all this rung** — 6b's `is_permitted_to()` is its first. Unowned
land is the king's, which is the same answer as nobody's. A single null field is
not the same weight as a whole stat or a whole place.

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| Build plan, Rung 6a | Remove `social` and the tavern from the file list, the job list and the Moment. The Moment becomes **two** drives on one graph. | not yet |
| Build plan, Rung 6d | Gains `social`, its upkeep line and the tavern, alongside `Socialise`. | not yet |
| Rung 6a session prompt | Its Call 1 is answered. | not yet |

---

## Decision 26 — Where bread comes from, and the rung that closes the loop

**Settled 2026-08-12. Author's call.**

### The hole the author found

The build plan routes bread as:

> **Eats bread if hungry** — **6a** authored into his starting stock → **7**
> bought from the tavern → **9b** the baker actually bakes it

At 7 the tavern's bread is **also authored**. So **nothing in the world makes
bread until 9b**, the second-to-last rung, and food is a fiction for the entire
ladder. The real chain — grain → miller → flour → tavern owner → baker → bread —
is five links long and none of it exists at 6a.

### Part one — the starting stock

> **Bread is authored per farmer in `game.tscn`, not on `person.tscn`.**
> **Fourteen loaves each**, which is about a week at the shipped cadence.

`person.tscn` is the template of a **body**, not of a life. Stats belong there —
every body has adenosine, hunger, strength. Possessions do not, and a newly
created person owning nothing is the honest default. It also matches how rung 5
authored the Fields', the Inn's and the Plot's inventories: in `game.tscn`.

`inventory.gd`'s own comment predicts this — *"a starting stock (rung 6a authors
bread onto a farmer)"* — though that is a prediction rather than a spec, the same
status as `stats.gd` predicting strength would feed the yield, which rung 5
deliberately declined to cash.

**Consequence for the probe:** its spare people start with empty bags, and the
*"a man with no bread cannot eat"* claim must still **empty a bag explicitly**
rather than lean on that. Rung 4 paid for this lesson twice — a check states the
world it wants instead of inheriting one, which is what `_stand_at` exists for.

### Part two — `MakeBread`, and where it goes

> **Anyone with grain can make bread.** Costlier and cruder than a baker's, and
> it is what lets the world stand up before a society exists to feed it.

The shape, deliberately minimal:

| | |
|---|---|
| **Gate** | awake, and has grain |
| **Score** | the same hunger gap `Eat` uses, at a **lower weight** — with bread in the bag he eats; with none he bakes |
| **Step** | one tick: take 3 grain, add 1 loaf |

That closes the metabolism for the first time in the project: **work → grain →
bread → eat → work**, with no authored fiction anywhere in the loop.

**Three grain a loaf is the make-or-buy gap.** A baker's oven gets one for one,
so buying is plainly better and employing a baker at 9b is worth doing rather
than a formality. The efficiency difference *is* the choice, and it needs no
extra mechanism.

**NOT a workstation, and this is a constraint not a preference.**
`WorkStep.YIELD_NAME` is a `const`, and rung 5 refused to export it on the stated
grounds that a station making something other than grain *"comes from a Recipe
(rung 9a), which owns the output and the time it takes together."* A hearth
workstation lands 9a's Recipe five rungs early against a recorded refusal. A
standalone one-tick action does not touch it.

**Which is also why it cannot cost world time yet.** Duration needs somewhere to
bank the fraction, and that is a station, and that is the Recipe. The cost is
paid in **grain**, not hours, until the Recipe exists.

### Where it lands: its own gate, immediately after 6a

Not inside 6a — that rung is hunger versus work and adding a producer blurs it.
Not deferred to 9b — that is four gates of authored food.

**The reason to do it early is measured, not aesthetic.** Rung 5 established that
Hobb takes the plot every day and gains ~16 grain, and **Zoogs never takes it and
gains zero.** With `MakeBread`, Zoogs eats his fourteen loaves and then has
nothing, no grain, and no way to get any. **The man who loses the dawn race
starves.** That is the first time contention has a stake instead of a bigger
number on somebody's head.

### Left open

**Make-or-buy as a choice within getting fed.** The author's framing, and it is
right. Two forms:

| Form | Shape | Cost |
|---|---|---|
| **cheap** (this rung) | `Eat`, `MakeBread` and later `BuyBread` all score off the same hunger gap at different weights, so a seller being present makes buying win on its own | he is hand-to-mouth: he only gets bread once he is already hungry |
| **better** (wants 6b) | bread gets a **stock target**, so `MakeBread` and `BuyBread` score off `target − stock` (Decision 1) and he restocks on a quiet afternoon | needs the quota machinery 6b builds |

Not called. The cheap form is what ships with the rung; the better one is a
natural thing to fold in when 6b gives quotas a home.

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| Build plan, Rung 6a | Bread authored in `game.tscn`, fourteen loaves, per farmer. | not yet |
| Build plan | **A new gate between 6a and 6b** for `MakeBread`. Numbering and name are the author's — inserting a gate moves the "fifteen gates" count quoted in the plan and in `CLAUDE.md`. | **not yet — needs the author's call on numbering** |
| Build plan, line 585 | The bread row becomes: 6a authored → **new gate** made from grain → 7 bought → 9b baked properly. | not yet |
| Rung 9b | Unthreatened. The baker is still worth employing because his oven is three times as efficient. | n/a |

---

## Decision 27 — Hunger is two gaps, and only the slow one is a lens

**Settled 2026-08-12. Author's call.** Corrects a proposal made in the same
session and rejected by the author; the rejection is the decision.

### Part one — the cadence is forced, and `bite` does not set it

Over a day, what goes in equals what built up:

```
meals per day  =  24 × hunger per hour  ÷  what a loaf fixes
```

**`bite` does not appear.** Whatever the curve looks like, he must put back what
he burned. `bite` decides **when** each meal happens and therefore **what he is
willing to interrupt** — a higher `bite` makes him more stoic, not more prompt.

This matters because three natural wishes are mutually inconsistent:

| Wish | Forces |
|---|---|
| a week to reach the top of the scale | rate ≈ 0.6/hour |
| a loaf fixes 50 | one loaf covers three and a half days |
| eats twice a day | a loaf must fix ~7, not 50 |

At rate 0.6 with a 7-point loaf he lives his whole life between hunger 7 and 14 —
the bottom seventh of the scale, where the curve never engages and nothing ever
competes with anything.

**Shipped: rate 4 per world hour, a loaf fixes 50, two meals a day.** `bite` is
the author's on the tuning board.

### Part two — hunger and starving are different gaps

> **Hunger** is the gap between fed and not. It **saturates in a day**, and 100
> means *"as hungry as a person gets"*, never *"dead"*.
>
> **Starving** is the gap between healthy and wasting. It only begins accruing
> once hunger has been **pinned at the top**, and that is the one that takes a
> week.

Exactly the adenosine parallel: 100 adenosine is not death by sleep deprivation.
Reading a felt gap as a lethal one is what forced the inconsistency above.

**Starving is not built.** Nothing at 6a has a consequence for it. The week lives
in fourteen authored loaves (Decision 26) until there is something for the second
gap to do.

### Part three — the drive to work stays whole

A damper was proposed and **rejected**: hunger multiplying down the weight of
work and leisure, so that `Eat` wins earlier without `Eat`'s own score moving.

The author's rejection, and it is the right one:

> **Hunger drives some men to work harder.** The direction is not universal, and
> a lens is a claim about everyone. Something that points opposite ways for
> different people is not a lens — it is **personality**, and personality's home
> is Decision 21's tendencies and per-person weights.

Two things follow:

- **Nothing hunger does touches another want's weight.** The competition between
  `Eat` and work is decided by the two curves alone, which is what keeps the
  tuning legible.
- **When "hunger makes him work harder" does arrive, it is temperament and never
  reasoning.** He cannot want to work *because* work eventually becomes bread —
  that is two steps of foresight, and Decision 20 refused lookahead on purpose.

### Part four — starving cuts production, and that is legibility

> **Starving is a lens on the RATE, not on wanting.** It lands in
> `WorkStep.get_yield_per_hour(person)` — the seam rung 5 built and deliberately
> left empty.

Hunger does **not** land there. So **`get_yield_per_hour` stays empty at 6a**,
and rung 5's intent survives another rung intact. Its first occupant is
starvation, whenever that lands — a better first occupant than `strength` would
have been, because it is a **state** rather than an identity: the same man
produces differently on different days.

**The author's framing is the point: this is a reportable event.** Two different
signals reach a lord from one starving man, and neither is a petition
(Decision 24):

| | The signal |
|---|---|
| **direct** | he wanted food and did not get it — recorded where it failed |
| **indirect** | the grain stopped coming off that plot |

Nobody reported anything. The lord notices a field producing less, and can act on
it, or not, and be wrong about why.

### The hazard this creates, named before it is built

**Starving cuts production, and production is what feeds you. That is a positive
feedback loop with no floor** — a man who slips far enough cannot climb back.

That is a **feature**: a spiral is legible in a way a flat penalty is not, and it
is precisely what earns a lord's intervention. But it needs either a floor on how
far output may fall, or an outside rescue (charity, a neighbour, the lord), and
**that must be chosen on purpose rather than discovered when the town dies.**

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| Rung 6a | `hunger` rises at **4 per world hour**, awake and asleep alike — one line, no branch, and it is why he wakes hungry. A loaf fixes **50**. | not yet |
| Rung 6a | **`get_yield_per_hour` stays empty.** Hunger does not modify production; starving will. | not yet |
| Rung 6a | Nothing hunger does may touch another action's weight. | not yet |
| Build plan | `starvation` as a second, slower gap is named as a future need with two jobs — a production lens and a ledger signal. Not scheduled. | not yet |

---

## Decision 28 — Socialise's candidates are venues, not crowds

**Settled 2026-08-14. Author's call, made watching rung 6d land.** Corrects the
candidate model in rung 6d's own text; recorded by the session and standing for
the author's review.

### The question

What are `Socialise`'s candidates? The build plan said *"places that currently
hold other people, via `Town.find_people_at()`"* — you go where people already
are.

### The hole the author found

**An empty place is never a candidate, so the first person never arrives.** The
occupied-places model can only redistribute company that already exists; it
cannot convene any. A tavern nobody has entered stays empty forever, the
"tavern wins in the evening" Moment never fires, and the only way to make it
fire is to author somebody standing in it — a hack that was in fact briefly
built.

### What was settled

> **A place is a Socialise candidate if company can be found there** —
> `Place.is_gathering_place`, an authored fact about the place: the tavern
> today, the market square at rung 7. **The venue is a candidate even when
> empty**, because a lonely man goes where company is TO BE FOUND, and the
> first man must be able to arrive so the second can find him. **Company —
> another person actually present — is what feeds the gap once he is there**;
> alone at the bar he waits, and his social does not fall.

Ordering is unchanged: travel cost first (the herd damper — a far crowd loses
to a near one, Decision 15), crowd size as tiebreak.

### What this keeps, and what it corrects

Kept from Decision 22: the gate stays a **candidate** question about the world
— *does a venue exist* — and never reads the size of the gap. Corrected in the
6d text: candidates-are-people becomes candidates-are-venues. **People are the
payoff, not the option.**

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| Rung 6d | Candidates are gathering places; company gates the DROP, not the candidacy. `Place.is_gathering_place` authored true on the tavern. | applied 2026-08-14, with the rung |
| Rung 7 | The market square ships `is_gathering_place = true` — "people with nothing to do hang in the square" is now literally this mechanism. | not yet |
| Build plan, rung-6 warning block | The Marle-at-the-tavern bootstrap note replaced with this decision. | applied 2026-08-14 |

### What shipping it found, same day — two constraints the venue model forces

Measured, not argued: the first build shipped `company_worth = 110` and the
cold start slid to 05:27 — a fully lonely man was CAPTURED. An empty-venue
visit changes nothing in the world, so the bid stands forever (Decision 23's
twitch test, at commute scale), and 110 sits above everything else's reachable
ceiling — Sleep tops out at the adenosine ceiling of 100 — so once saturated,
nothing could ever outbid Socialise again.

Two constraints follow, and both shipped:

1. **A want that can stand unresolved for hours must price under the ceilings
   of what it competes with.** `company_worth = 90`: under work's 103 peak
   (the working day survives total isolation) and under the adenosine ceiling
   (sleep always, eventually, wins). Eat gets to price at 130 only because a
   meal resolves in one tick.
2. **The empty-venue wait must RESOLVE.** Shipped as a thin-company trickle —
   being out is weak company (`change_of_scene_per_hour = 18` against real
   company's 30) — so a man who waits alone is slowly soothed and released.
   **This is the cheap stand-in for the honest mechanism, which is
   Decision 23's failure-marks-the-candidate**: a man should be able to give
   up on a tavern he found empty, and that mark (per candidate, decaying,
   Decision 24's shape) is unbuilt substrate. When it lands, the trickle can
   shrink toward zero and the author should revisit both numbers. Flagged as
   the author's to accept or replace.

And a third constraint, found the same evening: **the accrual rate must close
against the town's actual supply of company.** At hunger's 4.0/hour a man
accrued 96 a day and woke saturated every morning — sleep adds a third of the
scale with nothing draining it — so the standing 90-bid recurred daily.
Shipped at **2.5/hour**: one tavern evening closes the day's accrual, mornings
start where work outbids company, and loneliness saturates only after a day
and a half of genuine isolation — a slower gap than hunger, as the fiction
always had it. Hunger's rate is derived from conservation against the loaf;
social has no loaf, so its rate is derived from the company the town can
supply.

### The second symptom of the same absence, measured 2026-08-14

Six days of the shipped town turned up a dither that is worth recording
because it is the SAME missing mechanism from the other side. **Zoogs — the
man who loses the dawn race — flipped action 1145 times on day 2, against
Hobb's 224.** The loop:

1. He walks to the fields, because from afar a plot's freeness is unknowable
   and work stays on his ballot (Decision 15, and the wasted journey is
   deliberately the point).
2. He arrives, sees Hobb has it, and work leaves his ballot **on that tick**.
3. Socialise is now the top bid, so he takes one step toward the tavern.
4. One step away from the fields he can no longer see the plot — so work is
   back on his ballot at 73+, beating Socialise, and he turns round.
5. Go to 2.

**Nothing is wrong with any single rule here.** The knowledge rule is right,
the gate is right, re-deciding every tick is right. Before rung 6d there was
simply nothing else on his ballot, so he stood still where he lost — which is
exactly what probe claim 22 asserts and still passes. Give him ONE competing
want that moves him and the boundary becomes a limit cycle.

**It is the same hole as the empty tavern: a failure that marks nothing.** He
tried the plot and could not have it; he tried the tavern and found it empty.
Neither failure is recorded anywhere, so both wants come back at full strength
on the very next tick. **Decision 23's failure-marks-the-candidate and
Decision 24's record-at-the-place-of-failure are one mechanism with two
symptoms already waiting for it**, and that is a strong argument for building
it sooner than "whenever it comes up". Refused here, on purpose: it is
substrate, it belongs to its own gate, and the rung shipped without it rather
than growing a commitment bonus or a cooldown — both of which Decision 23
refuses by name.

Not a defect to hide: on screen it reads as a man hovering at the edge of the
field, and it resolves on its own as the sun lifts work clear. The author's
call is whether it ships as a texture or earns the mechanism now.
