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

## Index

*Added 2026-08-19, extended 2026-08-20. Thirty-five sections is past the point where "highest number
wins" can be applied by reading the file. **Scan up from the bottom** — a later
ruling narrows an earlier one more often than it contradicts it.*

| # | Settles | Narrowed by |
|---|---|---|
| 1 | Where "want" comes from — `find_candidates()`, never a named partner | 19, 20 |
| 2 | How a workstation claim expires — day-long tenancy, read lazily | 30 |
| 3 | How rung 6 gets cut — five gates, not one | 25, 26 |
| 4 | `move_and_slide` is not used; `GoToStep` integrates position by hand | |
| 5 | World time is denominated in **hours**, everywhere below `Clock` | |
| 6 | What a handoff is — sync, async, and the shape of a trade | 29 |
| 7 | Identity check vs travel cost — which question a gate may ask | 15 |
| 8 | Rung 9 splits into 9a–9d | |
| 9 | Rung 0's harness, corrected against the engine | |
| 10 | How a Person reaches the world — pulled off `Population`, never wired | |
| 11 | The sleep cycle is anchored to the sun | |
| 12 | How two people differ — authored stats, not classes | |
| 13 | The rung-3 Moment reads at a **shortened** day | |
| 14 | Travel cost is subtracted, and denominated in hours | 15 |
| 15 | What distance may decide, and what a man can know from afar | 30 |
| 16 | What physics is for | |
| 17 | **How an embodied player gets a place** — load-bearing for the boss ladder | 33 |
| 18 | The sim owns duration; the animation illustrates it | |
| 19 | **Every want is a gap** | 20–27 |
| 20 | **The want formula** — `want = weight × gap^bite`; the sun lands on weight | 31 |
| 21 | The baseline is a personality, not a floor | |
| 22 | What may touch a want, and where — gates ask the world, never how much he wants it | |
| 23 | Failure marks the candidate; success marks the world | 32 |
| 24 | Unmet need is recorded where it failed | 32 |
| 25 | Rung 6a lands hunger only | |
| 26 | Where bread comes from, and the rung that closes the loop | |
| 27 | Hunger is two gaps, and only the slow one is a lens | |
| 28 | **Socialise's candidates are venues, not crowds** | 32 |
| 29 | The crop belongs to the land. A worker is **paid**, not indebted. | 31, 33, 38 |
| 30 | **A claim is public.** Freeness is read from the register, not the doorstep. | |
| 31 | A gap drives the verb that closes it in one go | |
| 32 | The empty-venue trickle is a placeholder, not a mistake | |
| 33 | **The player is the boss, and the ladder is re-cut from his seat.** A command is a *bid*. The verb menu is `get_available()` drawn. No code names a verb. | |
| 34 | **A gap is measured in what can actually change hands.** `is_discharged()` is derived, never stamped. | |
| 35 | **What makes a verb come and go, once freeness is public.** No gate reads where a man stands any more, so the player's ballot turns on what he CARRIES. The town gains an unclaimed field so he can act on the world at all. | |
| 36 | **A `Condition` is the one shape a modifier takes.** Intensity is a stat; the condition is the translation. Zero is a gate and is forbidden. No condition reads another. | |
| 37 | **Pressure is applied, never transmitted.** A lord's gap drives HIS ballot, not the steward's number. It sets how often he shows up. | |
| 38 | **A quota is safe one layer above the labour.** Decision 29's trap reaches the man who DOES the work, never the man who DIRECTS it — so the quota it deleted comes back one layer up, WITHOUT the debt semantics. | |
| 39 | **The simulation is always full-resolution — there are no coarse ticks.** A distant region runs unbounded by the frame rate, never at bigger `hours`. `probe.gd` is already that execution model. Retires a constraint 37–38's conversation had argued from the opposite premise. | |

**36–39 are rulings about what to build, not records of what was built.** Every
other section in this file describes shipped code. 36–38 describe code that does not exist, settled ahead of it
because the cost of getting them wrong is paid by everything layered on top;
nothing in them has been measured. **39 is the opposite case** — the code already
behaves that way, and what is settled is that an optimisation which would change
it is off the table.

**If you read only four: 19–27** (how wanting works — before writing any
Action), **30** (how freeness is known — before writing any gate that asks where
a man is standing), **33** (whose seat the game is played from), and **35**
(what 30 quietly did to every ballot in the game).

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

> **⚠ ALSO REFRAMED BY DECISION 29 (2026-08-15).** This section's 6b row, and
> its plan-edit row, say *"discharge into the owning Place's inventory"* — and a
> builder reading that today would build the thing 29 deletes. **The routing
> survives: the crop still lands in the barn.** What does not survive is the
> framing around it — the farmer is not discharging a debt, because the crop
> was never his. He is paid a share of what he raises on his employer's land.
> `WorkForHireStep` and its per-tick capped handover are deleted, not amended.

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

> ⚠️ **NARROWED BY DECISION 30 (2026-08-17). Read that one; the mechanism below
> is retired, the purpose is not.** This ruling shipped and produced the
> **boundary dither**: departure writes `current_place = null`, so one tick of
> walking away from a held plot put work back on the ballot at full strength, and
> a man pinned himself one step from a plot he could never have — 1145 action
> changes in a day. `sleep.gd` hand-copied the check and the dither with it.
>
> **A claim is now a public record**, readable from anywhere in town. What this
> ruling was defending survives by other means: the bootstrap lockout it feared
> cannot form because **claims expire at the day boundary**, so every station
> reads free to everybody at dawn; and the race survives because **`claim()`
> still requires presence.** What it refused was a *perceptual* fact (is a man
> standing in that furrow); a tenancy is a *legal* one.
>
> **Ruling 2 below is untouched** and remains in full force.

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

---

## Decision 29 — The crop belongs to the land. A worker is paid, not indebted.

**Settled 2026-08-15. Author's call**, made reading the six-day findings from
rung 6. Changes the **contents** of rung 6b's `Obligation`, not its shape.

> **Number note.** The rung-6 findings file proposes a standing-want pricing
> rule and suggests it "should probably be Decision 29". That rule is **still
> unruled** and will take a later number when it is settled. This section took
> 29 because it was decided first.

### The question

Rung 6b ships work as an obligation to **deliver grain**: a man owes twelve a
day, and `WorkForHireStep` hands over `min(carrying, still owed today)` on
every tick it works. Six days of the shipped scene, measured:

```
                Zoogs    Hobb     Marle
worked           19.0 h   63.7 h    0.0 h
ends: grain          0        0        0
bakes                0        0        0
barn                63 grain over six days   (24/day owed between two men)
```

**No man ever holds a grain**, so `MakeBread`'s three-grain gate never opens,
so the loop rung 6a2 exists to close — work → grain → bread → eat → work —
cannot fire in the shipped scene at all. At two meals a day the fourteen
authored loaves run out around day seven and the town starves with nothing to
do about it.

### Why this cannot be fixed by tuning, which is what made it a design question

The findings file diagnoses it as *"the quota is never met, so the delivery cap
never closes"* — which implies lowering `owed_count` would restore the surplus.
**It would not**, and this is worth recording because it is the obvious fix and
it is dead:

- grain comes off the plot **one whole unit at a time** (`work_step.gd`), and
  the delivery leg runs in the **same tick**, so `min(carrying, remaining)` is
  always `min(1, ≥1)` and takes all of it;
- the tick the twelfth grain is delivered, `is_discharged()` flips and
  `WorkForHire.get_utility_score` returns **0.0** on the very next DECIDE.

**Meeting the quota and stopping work are the same event.** There is no window
on either side of it in which a man accumulates anything. At `owed_count = 3`
Hobb finishes at 09:00 holding exactly zero. `work_for_hire_step.gd`'s own
comment — *"the surplus a man holds past quota is rung 7's trade stock"* —
describes a state the code cannot reach at any tuning.

### The deeper thing underneath it

Chasing the surplus turned up the actual error: **the grain was never the
worker's to owe.** Hobb works Marle's land under Marle's employment. The crop
is Marle's from the moment it leaves the ground. Modelling it as a debt Hobb
discharges gives the farmhand ownership he never had, and then has to invent a
mechanism to take it back off him one grain at a time.

### What was settled

> **The crop belongs to whoever owns the land. A worker is paid, not indebted.**
>
> An `Obligation` stops being a want and becomes a **capability**: it grants
> access to the land and sets what he is paid. **The wanting moves onto the
> man's own larder** — he works because his own stores are short, which is a
> gap with a real source that shrinks as he works.

That last clause is the point. Work's score today is
`73 + 30 × sun` — the same hand-placed constant it has been since rung 4, with
a binary switch bolted on, which Decision 19 already called out as *a
placeholder standing in for a gap that has not been built.* Under a wage the
placeholder finally dissolves into the thing it was standing in for.

### The three code consequences

**1. Where the yield lands, by ownership.** One branch in `WorkStep`:

```gdscript
# Unowned land is the king's, i.e. nobody's, and a man keeps what he raises on
# it — which is what keeps plain WorkTheField meaningful instead of dead
# library code. Owned land's crop is the owner's from the moment it leaves the
# ground: he is not handed it later, it was never the worker's.
#
# add(), not hand_over(). The work CREATES the grain, so the world total rises
# here exactly as it does today and the conservation probe keeps its meaning —
# this is not a transfer and must not be written as one.
#
# is_instance_valid FIRST: owned_by is a stored Person reference, and a freed
# owner would otherwise error on the next property read.
```

**2. `game/actions/work_for_hire_step.gd` deletes entirely.** The whole file
exists to do the capped per-tick handover, and under this there is nothing to
hand over. **Three things proposed while working this out cancel themselves**
along with it — a `Deliver` action, the sack-versus-pile question, and any
repair to the `min(carrying, owed)` arithmetic. That is the sign the reframe is
right rather than merely different.

**3. `Obligation` changes contents, not shape.** Same node, same parent, same
expiry, same permission role. `owed_item` / `owed_count` become a wage.

### The payment seam — a gap, not a strategy object

Share-of-crop and a collected payday differ in **when** payment settles, not in
how much, and that means **different call sites** — a share is settled from
`WorkStep` as grain comes off; a payday is settled from an action with a walk
in it. A pluggable strategy object would paper over exactly that difference and
the mismatch would surface the day payday needed the walk.

So the seam is the one question both shapes agree on, and it is the shape
everything else in this project already is:

```gdscript
# obligation.gd
#
# What today's labour has earned him, and what he has actually had. The
# difference is a GAP like any other, and it is what both payment shapes agree
# on — they differ only in WHEN it is settled.
#
# Share of crop settles continuously, so the gap sits at ~0 and nothing ever
# bids to collect. A daily wage, a piece rate, or a payday he must walk to and
# ask for all leave it open, and then the gap drives an action.
func get_earned_today() -> float
var received_today := 0
```

**It goes on `Obligation` because that is the object that varies.** Marle
sharecrops while a Lord's estate pays a wage, in the same town, at the same
time — so a bare function on `WorkStep` could only serve both by branching on
who the employer is, and *a number is authoring; a branch on who you are is a
script.* Travel speed sits on `Person` for the identical reason.

**Three things this buys:** shipping share-of-crop today installs payday's
ledger for free (it is simply always zero); payday later is a **new Action**
(gate: am I owed anything — score: the gap — step: not at him, walk; at him, be
paid) and **no existing file changes**; and it arrives with the failure mode
worth having — Marle cannot be found, or will not pay, and the gap just stays
open.

**`received_today` is stored state and survives the same defence already
accepted for `delivered_count`:** more than one man can be paid out of the same
barn, so the barn's total says nothing about which part was *this* man's pay.
It genuinely cannot be recomputed from a snapshot. Same lazy day-stamp as the
tenancy, so nothing sweeps it at midnight.

**A `PaymentStrategy` resource with a registry is refused** — not wrong in
principle, but it would be a pattern with exactly one implementation, and
`brain.gd` already states the rule: *systems built before they're needed get
thrown away.* The day a second employer needs a different **shape** rather than
different numbers, the function above is already at the right seam to grow into
one.

### What this does NOT change — most of the prior thinking stands

Recorded explicitly, because the session that produced this decision initially
over-read it as a course correction and it is not one:

| Still stands | Note |
|---|---|
| **Discharge into a Place** (Decision 3) | The grain still lands in the barn. Only the *reason* changes — not "he pays down a debt" but "the crop belongs to the landowner." The routing was right. |
| **`Obligation` as stored intent, a Node under the Person** | Untouched. Employment cannot be worked out by looking at the world. |
| **Expiry vs discharge as two facts** | Untouched, both still needed. |
| **`is_permitted_to` — employment grants access to land** | Untouched, and *better* under a wage: you work his field because he hired you, and the crop is his. |
| **Bilateral exchange, two present bodies** (Decision 6) | Untouched, and it is what payday uses when it arrives. |
| **Want = target − stock** (Decision 1) | Untouched, and it gets its first real use as the worker's own larder target. |
| **The 6a–6d cut, the tenancy, the knowledge rule, exertion** | Untouched. |

### What was deliberately NOT taken, and why

The session that produced this ranged much wider. Recorded so it is not
re-litigated from scratch, and not acted on:

| Considered | Verdict |
|---|---|
| **Coin, worth-per-item, a profit motive** | **Not now.** Wages in grain need no coin, no prices and no exchange, so the *"prices, wages, affordability"* entry in the Refused ledger **stays refused** and the ladder ordering does not move. Noted for the record: that ledger entry justifies itself with FR60, which on reading is about the **player's win conditions** (wealth without power does not advance the arc) and says nothing about coin existing inside the sim. If coin is ever wanted, that re-reading is the door, not a reversal. |
| **Pulling `Trade` forward ahead of obligations** | **Not taken** — see the next section, which is the reason it deserves a real hearing next time rather than a reflex. |
| **Everyone holds a coin target, making coin universally accepted** | Named as the elegant answer to the double-coincidence-of-wants **if** coin ever lands. Not built. |
| **Pricing exchange in utility ("utils")** | **Refused.** A utility score is a *private ranking device*; using it as a price makes utility interpersonally comparable, puts a private number into the world as a public quantity, gives a different rate for every pair and every tick, and fleeces the desperate man by construction. A one-way door. Authored worth per item is the cheaper answer if worth is ever needed. |
| **Scoring an action for every gap it closes** | **Right idea, not yet.** No action in the shipped game closes two gaps — eating is hunger, socialising is loneliness, work is a binary promise. The first genuinely multi-purpose act (eating *at the tavern*, working *in company*) does not exist. **Three traps named for when it lands:** positive terms only, never a negative term for a gap the action *opens* (that is cost re-entering the cross-action sum, banned by Decision 15); ceilings **stack**, so the sum needs its own ceiling rule; and a mediocre multi-gap action will otherwise dominate a good single-gap one. |
| **Scoring an action for gaps it closes *later*** ("work scores for hunger because work becomes bread") | **Refused** — that is the lookahead Decision 20 closed. A **standing target is that chain already compiled**: he does not reason forward, he feels short *now*. |
| **A brain that decides how long to work** | **Refused as stated** — a decided duration is a plan on the person, breaks free interruption, makes *why is he doing that* unanswerable from the screen, and is Decision 23's refused commitment bonus with a clock in it. **The line: the job may know how long it takes; the man may not decide how long he will do it.** Work-in-progress living on a station (`output_part_made` today, the Recipe at 9a) is the legal form. |
| **Exertion feeding hunger** | **Not a decision — a two-line omission.** `exertion` is already built on `ActionStep` and already multiplies `get_adenosine_accumulation()`; `get_hunger_accumulation()` does **not** read it, and **nothing in the project ever sets `exertion` above its 1.0 default.** So working and drinking currently cost the body exactly the same. Fix whenever wanted: a number on `WorkStep`, and a multiply in the hunger accumulator. |

### The prediction that was already on the record

Worth writing down, because it changes how the next reorder proposal should be
weighed. **Cloud Dragonborn called this on 2026-08-09**, in the roundtable that
produced Decision 3:

> rung 6 moves goods three times before the goods-moving seam exists… So rung 6
> ships a transfer path **rung 7's first act is to delete**, and deleting a
> shipped path is the exact failure the plan exists to prevent.

His proposed order was *inventory → an action that consumes an item → a want →
**trade** → an obligation that creates a second kind of want*, on the grounds
that **obligations are the most expensive want in the game**. He was overruled
on the reasoning that Place-discharge fixed it without moving anything.

**The mitigation solved the stated symptom and missed the actual problem.**
Routing discharge to a Place did successfully avoid shipping a person-to-person
transfer. But the path that has to come out is not person-to-person — it is the
per-tick delivery leg, and it exists because there was no ownership-and-payment
model to hang employment on. The barn was never the hard part; having nothing
to pay a man with was.

This decision fixes it **without** reordering, because a share of a crop is not
a price. But if a third occasion arises where a rung has to invent a fake
economy because the real one is two gates away, the reorder should be granted
rather than mitigated again.

### Left open

- **Payday as an event.** The richer shape, and the one that forces
  co-presence. Wants its own gate; the ledger above is what it will read.
- **Whether the work gap stays binary.** **CLOSED BY DECISION 31 (2026-08-18):
  binary for the day's labour, proportional for the larder — because work closes
  the larder one grain an hour and would otherwise fight itself all day.**
  Original text follows. Decision 22's *a promise is kept or it
  is not* was reasoned about a grain debt. Under a wage the binary thing is
  arguably the day's labour, and the proportional thing is the larder. **Not
  settled** — decide it when the larder target is authored.
- **A pile in the field.** Yield landing on the *plot's* own inventory rather
  than the place's would give Marle a collect-and-haul day and put visible,
  stealable grain in the world. Deferred: it needs Marle to have a hauling
  action, and the minimum does not.
- **What Marle does all day.** He still has no work action and no path to a
  grain of his own, so he starves on top of a full barn around day seven like
  everybody else. This decision does not fix that; selling from the barn is
  rung 7's.

### Plan edits this implies

**APPLIED 2026-08-15**, every row, same day it was settled.

| Where | Edit | Applied |
|---|---|---|
| Build plan, Rung 6b | Retitled *The wage*. Work is a wage relationship, not a grain debt; `Obligation` grants a capability and carries `share_of_crop`, not `owed_item`/`owed_count`. Revision banner added. | **applied** |
| Build plan, Rung 6b | The yield lands by ownership — unowned land to the worker's sack, owned land to the owning Place's inventory, via `add` not `hand_over`, `is_instance_valid` first. `WorkForHireStep` is deleted, not amended. | **applied** |
| Build plan, Rung 6b | The earned-vs-received seam on `Obligation`, with share-of-crop as the shipped body and the reason it is not a strategy object. | **applied** |
| Build plan, Rung 6b probe | *"discharge moves grain into the barn and conserves the total"* retired; replaced by *the crop lands in the owner's store and the worker keeps his share*, plus a new claim that a man on **unowned** land keeps all of it. | **applied** |
| Build plan, Rung 6b Moment | Restated against the larder gap, and marked as a **prediction to check** rather than a target — it was unreachable as shipped (the tavern took the margin that met the quota). | **applied** |
| Build plan, Rung 6b *Do not build* | *"wages"* struck through, with the share-is-not-a-price note and payday deferred to its own gate. | **applied** |
| Build plan, rung-6 warning block | The *"surplus past quota stays his — rung 7's tradable stock"* claim marked **false and unreachable at any tuning**, with the two-line mechanism. | **applied** |
| Decision 3 | Banner: its 6b discharge row is reframed — routing survives, the debt framing does not. | **applied** |
| Seam ledger → *Installed* | **Payment** added; *Assigned intent* amended to say `Obligation` is a capability, not a want. | **applied** |
| Seam ledger → *Refused* | *"Prices, wages, affordability"* stays, amended: a share of a crop is not a price; the FR60 re-reading and the coin-target-on-everyone form recorded as the door if coin is ever wanted; **utils-as-price refused outright.** | **applied** |
| Rung 6a2 (`MakeBread`) | Unblocked — a worker who keeps his share can finally hold three grain. No text change needed. | n/a |

---

## Decision 30 — A claim is public. Freeness is read from the register, not from the doorstep.

**Settled 2026-08-17. Author's call, and the mechanism is the author's proposal.
Narrows Decision 15's Ruling 1** — which stands in its reasoning and in its
purpose, and is wrong about one thing it did not know at the time.

### How this came up

Rung 6 shipped and was measured over six days. **Zoogs changed what he was doing
1145 times on day two. Hobb changed 224.** The loop, traced against the code
rather than inferred:

1. He walks to the fields. A plot's freeness is unknowable from afar
   (Decision 15), so work stays on his ballot and the journey has a cause.
2. He arrives. Hobb has the plot. Work leaves his ballot on that tick — not
   outbid, **gated out**, which is the hole in the graph rung 4 was built to
   draw.
3. `Socialise` is now his top bid, so he takes one step toward the tavern.
4. **The first tick of any journey writes his place to null** (`go_to_step.gd`,
   *departure writes null*, and it is correct — a man on the road is at no
   place, which is what stops the town standing him with everyone else who is
   also walking). "No place" is not "the plot's place", so the freeness check
   never runs, and **work returns at full strength.** It buries `Socialise` and
   he turns round.
5. Arrival is an overshoot clamp, not a radius, so one tick's walk from the
   field means he is back on it next tick. Go to 2.

**It is not a wobble. It is a two-tick cycle that pins him within one tick's
walk of a plot he cannot have.** He does not drift toward the tavern and get
pulled back — he never gets a second step. It breaks only at dusk, when work's
daylight term falls far enough that loneliness can win from the road.

**Every rule in that loop is individually correct, and each one would be
re-derived if deleted.** There is no bad decision in it to reverse. That is what
makes it worth a decision rather than a fix.

### Two things the findings file got wrong, corrected here

**There is no `release()`, deliberately, and a claim is a day-long tenancy.**
Walk away from a plot and it stays yours until the next day boundary
(`workstation.gd`: *"abandoning a plot IS simply not renewing it — walk away and
the claim lapses at the next day boundary on its own"*).

So the appendix's *"Zoogs works 19 hours because Hobb stops for the tavern and
the plot frees"* **is false. The plot does not free when Hobb goes drinking.**
He holds it to midnight, and Zoogs standing in that field at 20:30 is still
refused.

Which forces the second correction. Hobb is stronger, sleeps less, rises at
04:47 and walks faster, so **he wins every dawn race**, so on every measured day
Zoogs could not touch that plot at any hour. **Zoogs produced zero grain over six
days.** His nineteen "worked" hours are the pump counting the *name* of his
current action, and half of every dither cycle is genuinely named work — it is
the work step, walking him to the plot. The action was real; the labour was not.

The arithmetic agrees independently: Hobb's 63.7 hours against 63 grain in the
barn is one-for-one with the remainder left in the furrow, and leaves nothing
for anyone else to have produced.

**So rung 5's inequality was never fixed. It was reformatted from a man standing
still into a man pacing**, and the instrument reported the pacing as work. Any
future counter must measure furrow time, not action name.

### Why it cannot be fixed by tuning, and what was refused

A penalty on work means work still bids and merely bids lower — and now there is
a **margin** to tune: large enough that `Socialise` wins at the fence, small
enough that work still wins everywhere else. That number would be retuned
forever, and it is the banned shape (building the observation instead of the
cause).

| Considered | Verdict |
|---|---|
| **A commitment bonus** — a bump for continuing what he chose last tick | **Refused, already, by name** (Decision 23). It is a stored decision, and it is what free interruption is currently paying for. |
| **A cooldown** — a timer barring re-choice | **Refused, already, by name** (Decision 23). Same objection, with a clock in it. |
| **A soft radius** — knowledge fading with distance rather than at the doorstep | **Refused.** A radius model was built and reverted 2026-08-08; `go_to_step.gd` names it and explains that it flickers at its own edge, overlaps where places sit close, and makes arrival frame-rate dependent. This is the obvious first idea and it is a dead end. |
| **Marking the candidate** — the man stores what he saw, decaying (Decisions 23 + 24) | **Not needed here, and not spent here.** It would work, but it invents a per-person knowledge store with a decay rate to tune and a write-in-the-decide-phase problem to resolve — to hold a fact **the world already holds publicly.** Left intact for the failures that have no public record: an empty tavern, and rung 7's refused trade partner. |

### The ruling

> **A claim is a public record. `claimed_by` and `claimed_on_day` are readable
> from anywhere in town, and a station held by somebody else is not a candidate
> no matter where the asking man is standing.**
>
> **The register says whether it is worth going. His feet decide whether he gets
> it.**

`Workstation.is_free_for` still does not change — it has always reported the
plain truth about itself, and that was always right.

### Why this is not the omniscience Decision 15 refused

Three reasons, and the first is the load-bearing one.

**1. Claims expire at dawn, so nobody is ever locked out at the start.**
Decision 15's objection — *"a plot he can see the state of from his bed stops
him ever setting off"* — assumes a state that is always visible and can be
permanently bad. It is not. `is_free_for` says a claim stamped before today is
not a claim, so **at dawn every plot in the world reads free to everybody.** The
bootstrap hole cannot form. The daily expiry, shipped for an unrelated reason,
is what makes the register safe to read.

**2. `claim()` still requires presence, so this creates no reservation.** Two men
both read *unclaimed* at dawn, both set off, and the faster one takes it on
arrival. **The race is preserved by construction.** You still cannot reserve a
plot from your bed.

**3. Decision 15 refused a perceptual fact; this is a legal one.** *Is a man
physically standing in that furrow right now* is something you would have to see.
*Whose field is it today* is a tenancy — village knowledge, the same kind
`socialise.gd` already grants for who is in the tavern, whose header says
*"everybody knows the tavern is a tavern, and roughly who's in it, even from
across town"* and explicitly invites this revisit.

**And the door is already ajar.** `Sleep.get_best_candidate` reads
`station.claimed_by == person` directly, from anywhere in town, with no
positional check — added to fix a real bug where a sleeping man's best candidate
drifted to a different bed and the one he was lying in read as abandoned. **A man
already reads his own claim from across town.** This makes an existing
inconsistency consistent rather than opening something new.

### What it costs, honestly

**The wasted journey shrinks to the race.** Decision 15 protected it as *"the
collision that later earns a notice board"* — evidence that a discovery index is
worth building. **Reading the register IS that notice board**, and it costs
nothing, because the field already exists and already expires correctly. The
design pressure is **spent, not lost**. Recorded plainly so nobody later reads
this as the evidence having been discarded.

What survives is the race itself, which is where the collision was always
interesting: at dawn for plots, at dusk for beds.

**It exposes rung 5's inequality nakedly, and that is the point.** Today Zoogs
paces the fence and the counter calls it work. Afterwards he reads the register
at dawn, sees Hobb has it, and spends the whole day visibly with nothing to do.
That is not a new problem — it is the existing problem with the camouflage taken
off. **The strongest argument for this ruling is that it makes the ladder's real
unsolved problem legible instead of disguised as productivity.**

### Beds, checked rather than assumed

The same positional short-circuit is hand-copied into `sleep.gd`, and it carries
the same dither — **in the exact scenario rung 6c was built to show.** The
twenty-first sleeper walks to the Inn, finds every bed taken, sleep leaves his
ballot; one step away the beds read free again, and his adenosine is pinned at
the ceiling so sleep buries everything, and he turns round. The file says *"that
man is this rung's content"*, and what he actually does is pace the doorway all
night.

**So this fixes the dither in both places it exists, not one.**

The contention survives there too, and for a different reason than plots: bed
claims are all expired by dusk, so everyone sets off for the Inn at once and the
claims land **while men are converging.** The twenty-first learns on the road or
at the door, exactly as he does today. Plot claims resolve at dawn and hold all
day, which is why reading them from afar saves a whole pointless day of walking;
bed claims resolve live, so reading them from afar changes almost nothing.

### What changes in the code

Delete the positional short-circuit from the candidate check — **in both copies,
by hand.** `sleep.gd`'s header says the duplication is deliberate and that 9b's
baker queuing for a millstone is the third consumer that earns pulling the shape
into a common home; that judgement is unchanged, and this is not the occasion.

```gdscript
# work_the_field.gd and sleep.gd, both:
func _is_a_candidate_for(station: Workstation, person: Person) -> bool:
	return station.is_free_for(person)
```

The comment block above `_is_a_candidate_for` in `work_the_field.gd` argues the
deleted rule at length and must be **replaced**, not trimmed — it is the second
comment in this file's history to argue a superseded position after the code
moved under it, and the first one cost a day.

### What does NOT change

| | |
|---|---|
| `Workstation.is_free_for` | Untouched. It always reported the plain truth; only who may ask has changed. |
| `claim()` requiring presence | Untouched, and it is what keeps the race real. |
| No `release()` | Untouched. What would earn one is an action that scores giving a station up early; nothing scores that yet. |
| Travel cost | Untouched. Still orders candidates, still never enters a cross-action score (Decision 15's Ruling 2, which this does not touch at all). |
| Decision 23 / 24 (failure marks the candidate) | **Still wanted, still unbuilt.** Two symptoms remain with no public record to read — the empty tavern, and rung 7's refused trade partner. This ruling removes the one symptom that had a register and closes nothing else. |
| The telemetry-from-gate exemption | Untouched, and notably **not widened** — nothing here is written from a gate. |

### Left open

- **What Zoogs does with an empty day.** This ruling gives him back the hours the
  dither was eating and does not say what fills them. Under Decision 29 he has a
  larder to want for and no way to fill it, so the honest answer is probably
  *nothing yet*, and that is the pressure that earns rung 7.
- **Whether the loser should ever get the plot.** With a day-long tenancy and no
  release, losing the dawn race costs the whole day. That may be correct and
  brutal, or it may want a second plot; it is a scene-authoring question, not a
  substrate one.
- **A furrow-hours counter.** Any measurement of work from here must count ticks
  that reached the yield, not ticks whose action was named work. The existing
  numbers cannot be trusted and should not be re-quoted.
- **Whether `Socialise` should read venue occupancy the same way.** It already
  does, for company as a tiebreak. Nothing to change; noted so the asymmetry is
  not mistaken for an oversight later.

### Plan edits this implies

**APPLIED 2026-08-17**, every row, same day it was settled.

| Where | Edit | Applied |
|---|---|---|
| Decision 15, Ruling 1 | Banner: narrowed by this decision. Its purpose (no bootstrap lockout, the wasted journey has a cause) is preserved by dawn expiry + presence-to-claim; its *mechanism* (positional knowledge) is retired. | **applied** |
| Build plan, Rung 4 | The freeness-is-local block carries a supersession banner — what shipped, the two-tick mechanism that made it dither, why the register is safe where this said it was not, and that the wasted journey is spent rather than lost. Original text kept beneath it. | **applied** |
| Build plan, Rung 4 probe | Claim 3 (*work leaves his ballot on arrival*) struck; replaced by *he reads a held plot from anywhere and never sets off* + *the day boundary re-opens it with nothing having moved*. Claim 4 replaced by the dither asserted directly across the arrival, departure and following ticks — it must break red against the pre-30 code. | **applied** |
| Build plan, Rung 4 Moment | Amended: the loser IS now dropped mid-stride, learns on the road and turns aside. Day-1-onward unchanged. | **applied** |
| Build plan, Rung 6c | Banner: the twenty-first sleeper paced the doorway all night on the hand-copied check; the register is what makes this rung's Moment watchable. Plus why the bed race survives for a different reason than the plot race. | **applied** |
| Build plan, rung-6 warning block | *"Zoogs is no longer shut out"* marked **false**, with the no-`release()` mechanism and the rule that work must be measured in ticks that reached the yield. | **applied** |
| Findings file (`rung-6-findings-2026-08-14.md`) | Correction banner at the top: both false appendix statements, and where findings 1 and 2 were settled. | **applied** |
| Seam ledger → *Installed* | **Public claim register** added; *Labour clearing* amended to say `claim()` requires presence. | **applied** |
| Seam ledger → *Refused* | *Notice board* row amended: half of it landed here for free and needs no sweeping; what stays deferred is discovery of **people and goods**, which has no register — and that is where the collisions still are. | **applied** |

---

## Decision 31 — A gap drives the verb that closes it in one go

**Settled 2026-08-18. Author's call. Closes the item Decision 29 left open**
(*"whether the work gap stays binary"*).

### The problem this heads off

Decision 29 moved the wanting onto a man's own larder. Read literally, that makes
`WorkForHire`'s score **the larder gap** — and then every grain he earns lowers
his desire to earn the next one. Work is the first action in the game whose own
output slowly closes the gap that drives it.

Worked at a plausible authoring — larder target 20, weight 73, bite 2:

| Grain in sack | Work at noon | Loses to a lonely man's `Socialise` (max 90)? |
|---|---|---|
| 0 | 103 | no |
| 5 | 71 | only when nearly saturated |
| 10 | **48** | **yes, from 73% lonely** |

He walks to the tavern, company drains the loneliness, work wins again, he walks
back. **Travel cost is barred from cross-action scores (Decision 15), so nothing
damps the commute** — and the world genuinely changes on every flip, so the
"did the world change?" test blesses it. The afternoon is spent walking.

### The ruling

> **A gap drives the action that closes it in ONE act. An action whose output
> closes its own driver slowly and continuously must not be scored on that gap.**

`Eat` closes hunger in a tick. `MakeBread` closes it in one act. **Work closes
the larder one grain an hour across a whole day, so it fights itself the entire
time.** That is a mismatch between the want and the verb, not a tuning problem,
and no coefficient fixes it.

**So work scores on the day's labour, which is binary** — he is employed and
there is a day's work — keeping the flat shape `pull + daylight_pull * sun` that
already tunes correctly against `StayUp` and bedtime. **The larder gap drives
eating, baking, and (rung 7) buying.** Decision 29's substance survives: the
wanting still lives on his own larder, one step removed from the shovel.

### What was rejected

| | Why not |
|---|---|
| **Tune around it** — a bigger target or a lower bite so work never falls far enough to lose | Fragile by construction: it must be re-tuned every time a new want lands, and it is the banned shape (a number standing in for a mechanism). |
| **A switching cost on `current_action`** | `interrupt_threshold`, refused by Decision 23 and again here. |
| **`output_part_made` as the band** | **It is not a switching cost at all.** The part-turned furrow stays in the plot for whoever comes next, so walking away costs a solo worker **nothing**. Recorded because it was proposed in session and is wrong. |

### Left open

- **What the larder target is.** Unauthored. It decides how hungry a man has to
  get before baking beats drinking, and nothing else now.
- **Whether a paid man ever stops working early.** Under a binary day's labour he
  does not. If that reads wrong, the honest lever is the daylight term, not the
  gap.

### Plan edits this implies

**APPLIED 2026-08-18.**

| Where | Edit | Applied |
|---|---|---|
| Decision 29, *Left open* | Banner: *"whether the work gap stays binary"* is closed by Decision 31 — binary for labour, proportional for the larder. | **applied** |
| Build plan, Rung 6b | Record that `WorkForHire.get_utility_score` keeps its flat shape; the larder gap drives `Eat`/`MakeBread`/`Trade`, never work. | **applied** |

---

## Decision 32 — The empty-venue trickle is a placeholder, not a mistake

**Settled 2026-08-18. Author's call. Answers the one item rung 6's findings
asked to have vetoed.**

### The question

`SocialiseStep.change_of_scene_per_hour = 18` — sitting alone at a gathering
place soothes loneliness, against real company's 30. Loneliness rises at 2.5, so
**net of upkeep, being alone is 56% as good as being with somebody**, which bends
*company is the payoff, the venue is only the option*. The file's own comment
calls it *"thinner than real company"*; 56% is not thin.

It exists because an empty-venue visit **changes nothing in the world**, so the
bid never resolves — measured with it at zero, a man stood in an empty tavern
outbidding both `StayUp` and sleep, and the cold-start bedtime slid to 05:27.

### The ruling

> **Not vetoed. Shrunk now, deleted with the mechanism.**
>
> `change_of_scene_per_hour` drops to **6.0**, and it is **deleted outright** the
> day failure-marks-the-candidate lands (Decisions 23 + 24) — at which point a
> man who finds a venue empty drops *that venue* for a while and goes to bed,
> with nothing claiming that sitting alone helped.

**A bare veto was refused**: it restores a measured failure. `company_worth = 90`
bounds that failure (sleep's ceiling of 100 can always eventually reclaim him)
but does not prevent it — at 2.5 adenosine per hour he needs most of a day and a
half to climb past 90, so he would stand in the empty room most of the night.
**The 90 bounds the damage; the trickle is what resolves it.**

### Why the register trick does not transfer

Decision 30 solved the plot dither by making a hidden fact public. **The tavern's
occupancy is already public** — `find_people_at` reads from anywhere and
`Socialise` already uses it as a tiebreak. It is **deliberately not gated on**,
because an empty venue must stay a candidate or the first man never sets off
(Decision 28's bootstrap hole).

> **The plot problem was information withheld. The tavern problem is information
> the design refuses to act on, for a good reason.**

Marking preserves the bootstrap where gating cannot: the mark only forms **after**
a visit, so the first visit always happens.

### The design question inside the real fix, named and left open

**What counts as failure here.** The plot *refused* him — a gate said no. The
tavern *accepted* him and did not pay. Decisions 23 and 24 were reasoned about
refusal; this is a rule about **outcome**. It needs saying out loud before it is
built, because it will apply to a great many things later.

### Also done

`socialise_step.gd`'s comment justified `company_per_hour` against
*"`base_social_per_hour` (4.0)"* — the real value is **2.5**; 4.0 is *hunger's*
rate, copied from the neighbouring line. **Corrected in code 2026-08-18** (the
only code change made this session). Harmless to behaviour, but the whole job of
that comment is to justify one number against another.

### Plan edits this implies

**APPLIED 2026-08-18.**

| Where | Edit | Applied |
|---|---|---|
| Build plan, Rung 6d | `change_of_scene_per_hour` is **6.0**, marked a placeholder with a named deletion date (when failure-marks-the-candidate lands), and the bootstrap reason the register cannot fix it. | **applied** |

---

## Decision 33 — The player is the boss, and the ladder is re-cut from his seat

**Settled 2026-08-19. Author's call. This is the largest re-framing since the
rebuild began, and it changes NO shipped code.**

### The question

Rungs 0–6 built a town that runs without anybody in it. The ladder's remaining
rungs (7–9) continued that: trade, a wagon, a chain of trades, and an ending
where a scythe sits unsold because *"buy a scythe" is not a verb any farmer
knows.*

The author, returning to first principles after six days of substrate work:

> *"The thing that's fun is being the boss. When you're the boss you tell people
> what to do. **And if they don't work for you, they don't have to listen.**"*
>
> *"So it simply starts with walking around looking, greeting people, give them a
> gift, ask them to follow you. But there'd be an unclaimed field, then you can
> tell them to work the field, then you can tell them to bring you the grain,
> stop working, give them coin, enjoy themselves at the tavern. That's the way to
> do the proving scene we've been working on."*

The question this settles: **does the proving scene keep watching an autonomous
farmer, or does it put the player in the town and let him command?**

### The ruling

> **The player is a body in the town, and every remaining gate is cut from his
> seat.** `boss-scene-build-plan.md` is the forward ladder;
> `proving-scene-build-plan.md` is retained as the record of the shipped
> substrate and as the source of the re-seated economy rungs.
>
> **No shipped code is invalidated.** The reframe changes the seat, not the
> substrate.

**The second sentence of the author's framing is the load-bearing one.** A
command that always lands is a button. A command that can be refused is a
relationship that had to be built, and the building is the game.

### Why this costs almost nothing to install

Three things were already true, and none were built for this.

1. **`Obligation` is already the command object.** Stored intent, hung as a Node
   under a person, authored by hand in `game.tscn`. **The player installing one
   at runtime is the identical operation performed by a different hand.**

2. **The weight seam was cut and named for this**, in `obligation.gd`'s own
   words: *"When channels exist to set this dynamically — **a lord's writ**, a
   guild rate, a season's bargain — the BODY of the function below changes and no
   caller anywhere moves."*

3. **Refusal is already the mechanism.** `WorkForHire` scores 73 + daylight and
   competes against sleep, hunger and loneliness on one ballot. **A command is
   not an override; it is a bid.** Nobody has to build refusal. Somebody has to
   author the bid.

### Two sub-rulings, both binding

**A. The player's verb menu is `get_available()` drawn instead of scored.**

`DecisionEngine` already keeps its halves apart — *"`get_available` never scores,
`get_highest_scoring` never gates"* — justified at the time as debuggability. It
is also, unmodified, the contextual verb list. The player build is: run the first
half, draw it, let input pick where the second half would have.

> **No menu code names a verb.** A verb appears because an `Action`'s own
> `is_available_to` said yes about the player's body. Authoring a player verb is
> dropping an Action scene under his Brain — the same sentence as teaching an
> NPC something, because it is the same operation. `if verb == "beckon"`
> anywhere in `game/` is a failed build, on the same footing as code naming a
> playstyle.

**B. A refusal speaks, and the excuse is authored on the drive that WON — never
on the command.**

> *"When you ask the person that's too tired they can say they are too tired."*

One exported string per Action, read off the winning candidate. Sleep carries
*"I'm dead on my feet"*; Eat carries *"let me eat first"*; Socialise carries
*"I'm for the tavern."*

Three consequences, and the third is why this is a ruling rather than a nicety:

- **Refusals cannot lie.** The line names whatever actually outbid you, because
  that is the only place it is stored.
- **A new drive arrives with its own excuse**, and every command ever written
  inherits it — the same inheritance `_update_body` already gives upkeep.
- **The utility model becomes diegetic.** The decision graph turns into a
  sentence, which is the PRD's no-floating-bars pillar arriving as a string
  rather than as an animation budget.

**The cost, stated plainly: a bespoke refusal for one specific order is now
impossible.** That is accepted. A refusal with no reason is a rejection; a
refusal with a reason is an instruction — feed him, let him sleep, come back at
dawn — and **the excuse is what converts a no into the next move.**

### What was rejected

**Reading and greeting deferred until standing has stakes.** The first draft of
this ladder put greeting at gate 5, reasoning that a greeting which buys nothing
is the *"meter with extra steps"* the pub slice was written to guard against.
**Overturned by the author**: greeting *at a distance* is a body turning toward
you across a square. Its satisfaction is motion, not a number, so it does not
need stakes to earn its place early. Greeting is gate 2, and beckon — not the
writ — is the first command.

**"Work the field" as the first command.** Displaced by **beckon**, which is
smaller (one obligation: be where I am) and whose compliance is more legible (a
man crossing a square to you, versus a man walking off to a plot).

### Left open

- **Whether standing is one number or several.** The PRD's reach vector is
  `{coercive, economic, authority, loyalty, informational}`. Ruled: **one number
  until a gate cannot be built without a second.**
- **Whether a man can refuse silently, or lie about why.** Deception stays a
  later system; like/dislike plus candor is enough interior state for this whole
  ladder.
- **Whether the player's own drives ever constrain him.** He has them by
  construction — he is a `Person` and `_update_body` runs for everybody. Nothing
  forces him to answer any of it yet.
- **Whether the player carries standing of his own** in the town's eyes, or is
  only a source of commands.

### A consequence to watch rather than patch

**After the writ lands, the unemployed town gets hungry.** Nobody works unless
the player says so, the fourteen authored loaves run out, and everyone climbs
toward pinned hunger. **This is pressure, and it is the reason to be the boss.**
It is not the day-eight bug from rung 6's findings. Starving proper is not built
(Decision 27), so it cannot kill anybody. Watch it deliberately.

### One process rule, added because rung 6 paid for it

**A gate is not closed until a paragraph of what you SAW is written above the
probe output.** Not instead of it — above it.

Rung 5's Moment was never watched. Rung 6 shipped four gates and produced a
headless six-day pump instead of a chair, and what got through was **a man pacing
a field for six days while a counter reported nineteen hours of work.** Ten
seconds of watching catches that; three days of numbers did not.

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| `boss-scene-build-plan.md` | Created. Eleven gates, Gate 1 cut in full. | **applied** |
| `CLAUDE.md` | Pointer table names the boss plan as the forward ladder; decision count corrected. | **applied** |
| `proving-scene-build-plan.md` | Header banner pointing forward; rungs 7–9 marked re-seated, not deleted. | **applied** |
| `proving-scene-decisions.md` | Index added at the top — 33 decisions is past the point where "highest number wins" can be applied by reading. | **applied** |
| Gate 0 = `rung-6-repair-session-prompt.md` | Unchanged and still first. **Hold its share-sizing half** — that quantity is a wage, and the boss ladder's Gate 8 authors it. Land Decision 30's deletion; defer Decisions 29/31's arithmetic. | **applied** |
| Spent rung prompts (3, 4, 5, 6a) | **Deleted 2026-08-19** — those rungs shipped and their reasoning lives in the code and in this ledger. `rung-6a-session-prompt.md` was additionally *wrong*: it predated Decisions 25–27 and described a rung that shipped differently. In git history if ever wanted. | **applied** |
| `gate-1-session-prompt.md` | Created. The first gate handed off for a build session, incl. Decision 17 as its hardest problem and the `probe.gd` population-count hazard. | **applied** |

---

## Decision 34 — A gap is measured in what can actually change hands

**Settled 2026-08-20. Author's call**, made while building Gate 0. **Closes the
question Decisions 29 and 31 left between them** — whether `is_discharged()`
survives a wage at all — and rules on a shape that will recur everywhere.

### The question

Decision 29 says, in its "what does NOT change" table: *"Expiry vs discharge as
two facts — untouched, both still needed."* Decision 31 then makes
`WorkForHire.get_utility_score` flat, which **deleted `is_discharged()`'s only
reader** — the branch that forced the score to 0.0 at quota. Highest number wins,
but 31 never argues the concept away; it only removes what read it. So this was a
genuine gap rather than a contradiction precedence could settle.

Underneath it sat a better question. The quota version read:

```gdscript
if delivered_on_day != person.clock.day():
	return false
return delivered_count >= owed_count
```

**That is a switch somebody flipped.** `note_delivery()` wrote the marks;
`is_discharged()` read them back. And that shape is precisely what produced
Decision 29's finding — *"meeting the quota and stopping work are the same
event"* — with no window on either side in which a man ever held a grain.

### What was settled

> **Discharge survives, and it is DERIVED from the gap rather than stamped by an
> event. And the gap is measured in WHAT CAN ACTUALLY CHANGE HANDS — not in
> exact equality, and not in fractions nobody could ever hand over.**

```gdscript
func get_earned_today() -> float:
	return float(received_today) + share_part_owed

func is_discharged() -> bool:
	return get_earned_today() - float(received_today) < 1.0
```

Nothing stamps, nothing sweeps at midnight, and the answer is worked out fresh at
read time — the same rule as *"am I at the inn?"* is answered by where he is
standing.

### Three versions were written. The two rejected ones are the point.

**1. `received >= received` — a tautology.** It cannot answer no. **A vacuous
assertion wearing a function's clothes**, and it is exactly the failure this
project has spent eight caught probe claims learning to hunt: *a check with no
state in which it could have gone the other way proves nothing, and the next
reader is entitled to believe it did.* It would have made every future claim
about discharge pass for free.

**2. `received >= received + carry` — honest-looking, and a trap.** It reads
false whenever any fraction is outstanding. **But a fraction of a grain cannot be
paid.** Nobody hands a man 0.35 of a grain, so a payday action gated on this
would bid, win, change nothing, and bid again — forever. **That is the standing
bid that never resolves**, the same failure Decision 32 had to shrink
`change_of_scene_per_hour` to work around, arriving by a completely different
road.

**3. Measured in whole grain — a seam.** Below one whole unit there is nothing
anybody *could* give him and his account is as square as arithmetic allows; at
one or more, something is genuinely collectable and an action has something to
do about it.

### Why version 3 is not merely version 1 with extra steps

Because it is true **for a reason**, and the reason is checkable.
`take_worker_share()` pays out every whole grain the instant it accrues, so the
carry it leaves behind is always in `[0, 1)`. Under share-of-crop the function
therefore reads true — but break that invariant and it reads false, which is what
makes it worth asserting. **Verified by breaking it**, not by reasoning about it.

**The general rule, which is the part worth keeping:**

> **A gap that cannot be closed by any act is not a gap, it is a leak.** Before
> writing one, ask what act closes it and in what units that act moves. If the
> answer is "nothing can move less than one of these", the gap is measured in
> whole ones.

### The wage goes through one door

Settled in the same conversation, on the author's instruction that these
mechanics stay loosely coupled and easy to revisit.

`Obligation.take_worker_share(made) -> int` is the only way the wage is paid.
**Nothing outside `obligation.gd` touches `share_part_owed` or `received_today`.**
`WorkStep` hands over the whole grain that came off the plot and gets back
whatever is the worker's; it does not know that a share is a fraction, that
fractions need carrying, or that anything is rounded at all.

Same wall as `Stats.get_stat` and `Inventory.get_count`, for the same reason: **a
payday, a piece rate, a guild minimum or a lord's cut off the top is a change to
that one function body with no caller anywhere moving.** An earlier draft had
`WorkStep` do the arithmetic itself, reaching in and mutating two of the
`Obligation`'s fields from outside. It worked, and it was still wrong — it spread
the wage across two files and made swapping it a two-file edit forever after.

**What deliberately stayed on the `WorkStep` side: the conservation.**
`owner_share = made − worker_share` is a fact about the *furrow*, not about the
wage — whole grain came off the plot, whole grain is placed — so it holds however
the wage is later rewritten. That is the property the probe's total leans on.

### What this does not settle

- **Payday as an event.** Still deferred, still its own gate. This is the ledger
  it will read, and it is now a ledger that can actually open.
- **Whether `share_part_owed` should be day-stamped.** It is not, deliberately: a
  rounding residue is not "today's" anything, and zeroing it at the boundary
  would quietly rob him of it every night. The cost, named in the code rather
  than hidden: `get_earned_today()` can carry up to one grain of yesterday. It is
  bounded by one grain. A payday needing the two scopes to agree should stamp the
  carry there, not teach its callers to subtract it.
- **The three numbers Gate 0 authored** (`share_of_crop`, `base_grain_per_hour`,
  `larder_target`). See `gate-0-findings-2026-08-20.md` Part 0 — the boss ladder
  reserves those for Gate 8 and they were authored early by mistake.

### The open question this measurement raised, recorded so it gets a number

**`bite` was tuned for a saturating gap and Decision 31 moved it onto a stock
gap.** `MakeBread` scores `weight × gap^3` where the gap is now *bread short of a
larder target* — and cubing a gap you want **maintained** guarantees it is never
maintained. Measured over twelve days: Hobb's bread parks at **2** and never
approaches the authored target of **6**, because baking is inert until his pack is
empty and then spikes. The target scales a curve that is flat everywhere it
matters.

> **Unruled: what curve is right for a gap you want held at a level, as against a
> gap that climbs to its ceiling on its own?**

**Do not answer it by retuning 3 to 1.5.** That is a number standing in for a
mechanism — the shape this ledger has refused three times. It will take a number
of its own when it is settled.

**RAISED AND RE-REFUSED 2026-08-20, DURING GATE 1.** The obvious mechanism-shaped
answer was put to the author: since Decision 31 says *a gap may only drive a verb
that closes it in ONE act*, and `MakeBreadStep` bakes exactly one loaf, make the
act bake up to the target and the target starts governing with the curve
untouched. **The author refused it, and the refusal is sharper than the
proposal:**

> *"Closing gaps in one go sounds dangerous — one act may reduce the gap below
> the action threshold."*

That is the failure the proposal walks into and it is worth stating in full.
An act sized to close the whole gap does not merely satisfy the want, it
**overshoots the state in which the want was legible**: the man goes from
plainly-short to plainly-stocked inside one tick, so every observer — the graph,
the readout, a later gate reading the same stock — never sees the middle. A want
that is only ever fully open or fully shut is a switch, and Decision 34's own
opening argument is that a switch somebody flips is what produced the failure it
was written to fix. **One-act closure is a legitimate shape for a gap that
genuinely IS binary (a day's labour, employed or not) and a trap for one measured
on a continuum.**

So the question stands, now with a second wrong answer named beside the first:

- **Not** retuning the exponent — a number standing in for a mechanism.
- **Not** closing the gap in one act — a continuum quantised into a switch.

**Still unruled. It blocks nothing** and Gate 1 changed no number touching it.
Gate 1 does hand it a better instrument than the twelve-day pump did: the player
bakes with his own hands, parks at two loaves against an authored target of six,
and the inertness is watched rather than read off a table.

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| Decision 29, *Left open* | *"Payday as an event"* row: the ledger it will read now exists and can open. Discharge survives, re-bodied. | **applied** |
| Decision 31 | Untouched. Work's score is still flat and still does not read the larder. | n/a |
| `gate-1-session-prompt.md` | Banner: Gate 0 landed; the anchor numbers it should be watched against; the three carried-forward open items. | **applied** |
| Seam ledger → *Installed* | **Payment** amended: paid through one door, `Obligation.take_worker_share()`. | **applied** |

---

## Decision 35 — What makes a verb come and go, once freeness is public

**Settled 2026-08-20. Author's call**, made before a line of Gate 1 was written,
on a hole found while reading rather than while building.

### The question

`gate-1-session-prompt.md` and `boss-scene-build-plan.md` both cut the same
Moment:

> *"You walk toward the fields on your own legs and **the list changes under
> you** — Work appears when you are standing at the plot."*

**Neither half of that sentence was true of the shipped code**, and both were
true when the sentence was written. Two separate things had moved underneath it.

**One: the player cannot work anything.** The only `field work` station in the
world is `Town/Fields/Plot`, owned by Marle. `Workstation.is_permitted_to` says
an owner's land is open to the owner and to whoever carries an obligation naming
that place — the player is neither — so `WorkTheField.is_available_to` reads
false for him **everywhere in town, at every hour**. The verb could not appear at
the plot because it could not appear at all.

**Two, and this is the one that generalises: no gate in the game reads where a
man is standing any more.** Decision 30 moved freeness onto a public register —
*"the register says whether it is worth going; his feet decide whether he gets
it"* — and in doing so deleted the last positional term out of a gate.
Enumerated, at the day this was settled:

| Action | What its gate asks | Positional? |
|---|---|---|
| `StayUp` | is he awake | no |
| `Sleep` | is any bed free anywhere | no |
| `Wake` | is he asleep | no |
| `Eat` | awake, and has he a loaf | no |
| `MakeBread` | awake, and has he the grain | no |
| `Socialise` | awake, and does a venue exist at all | no |
| `WorkTheField` | awake, and is a permitted station free | no |

**So a ballot cannot change under anybody's feet, player or NPC.** That is not a
regression and nothing about it is wrong — Decision 30 argued the change at
length and the dither it killed was real. It simply means a Moment written
around walking into a verb was describing a game that had stopped existing
eight commits earlier, and nobody noticed because until Gate 1 nobody had feet.

### The ruling

> **The player's ballot turns on what he CARRIES and what the town has DONE, not
> on where he stands. And the town gains an unclaimed field, so that he can act
> on the world at all.**

Three parts, each with a consequence.

**A. The Moment is re-cut, not rescued.** It now reads:

> You spawn in the town square with an empty sack. Work is on your list because
> there is unclaimed land in this town. You walk to it on your own legs, choose
> Work, and the number in your own sack climbs. **At three grain, a verb you have
> never seen appears on your list** — you can bake. Bake, and a fourth appears:
> you can eat.

That is a better beat than the authored one and it is not a consolation prize.
The authored version had the world reveal a verb because you moved; this one has
**your own labour reveal it**, which is the loop closing in your hands rather
than a trigger firing. It is also the first thing in this project that shows
work → grain → bread → eat to a person instead of to a probe.

**B. `Town/CommonField` — one unowned `field work` station at a Place of its
own.** Unowned land is the king's, which is the same answer as nobody's, so
permission is wide open on it and the player can simply work it. **It is at its
own Place deliberately, and that is load-bearing**: put an unowned plot at the
grain fields instead and Zoogs' `WorkForHire` scopes candidates by his
obligation's `place_name`, matches it, and **Zoogs gets an errand** — which
Gate 1 forbids in as many words, because his idleness is Decision 30's finding
made visible. At its own Place, no NPC in the town can see it: both farmers are
scoped to the grain fields and Marle has no work action at all. **Measured, not
argued: the probe's anchor numbers are byte-identical either side of this
change** — cold start 21:14/05:52, settled 22:10/8.00 h/06:10, strong man 04:47.

It is also the field Decision 33 quotes the author asking for — *"but there'd be
an unclaimed field, then you can tell them to work the field"* — arriving five
gates before Gate 6's writ needs somewhere to point.

**C. `Town/Square`, and it earns its place for one reason only.** Nothing gates
on it and no NPC reacts to it. It exists so that Decision 17's band has open
ground to be watched on: a door is naturally discrete, and the band was only ever
needed for the fields and the square. Non-gathering, so `Socialise` cannot see
it and the town's evenings do not move.

### What was rejected

**Employing the player at the grain fields.** An `Obligation` plus `WorkForHire`
would have let him work the existing plot with no new content, and it would have
given the truest possible version of *the list changes under you*: Work drops off
his ballot the moment Hobb claims the plot at dawn and returns at the day
boundary. Refused on two counts. The boss on Marle's payroll is the wrong
fiction for a ladder whose first sentence is *the player is the boss*. And it
puts a third contender in the dawn race, which moves the one measurement this
project has — the anchor — for a Moment, which is the worst possible reason.

**Building nothing and dropping probe claim 4.** The gate would then prove the
fork and nothing about the fork being *worth* anything. A verb list you cannot
act on is a menu, and the whole point of drawing `get_available()` is that the
things on it are real.

### What this does NOT settle

- **Whether a gate should ever read position again.** Decision 30's argument
  stands untouched and this does not reopen it. What is now known is the *cost*
  of that argument, which was never stated: no verb anywhere can be revealed by
  arriving. If a later gate wants one — a verb that exists only at a threshing
  floor, a door only openable from inside — that is a new question and it must
  answer Decision 30 on its own terms, not lean on this.
- **Whether the player should be able to steer while asleep.** He can, today.
  Nothing gates his movement on `is_awake`, because Decision 33 leaves open
  whether his own drives ever constrain him and a movement function is the wrong
  place to answer it quietly. **Watch it; do not patch it.**
- **What a second unclaimed field would do.** One is authored. The moment there
  are two, `Town.find_workstations`' ordering starts deciding which the player
  walks to, and that is a fine answer — it is just an unmeasured one.

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| `gate-1-session-prompt.md` | Its Moment and its probe claim 4 both assume Work is revealed by arriving. Superseded by this decision; the file is spent either way. | **applied** (recorded here) |
| `boss-scene-build-plan.md`, Gate 1 | Same sentence, same supersession. Gates 2–11 are unaffected — none of them turns on a positional gate. | **applied** (recorded here) |
| `game.tscn` | `Town/Square`, `Town/CommonField` + `CommonPlot`, `Population/Player`. | **applied** |
| `probe.gd` | Claims 18, 24 and 43 each narrowed to the stations they are actually about, rather than depending on the town holding exactly one plot. Claim 6's population count moved 4 → 5. | **applied** |

---

## Decision 36 — A condition is the one shape a modifier takes

**Settled 2026-08-28**, out of a study of RimWorld's extensibility (see
`rimworld-comparison-findings-2026-08-28.md`). **Nothing here is built.** This
settles the shape before five separate things get written as five separate
mechanisms.

### The problem this exists to stop

Five things are queued behind a primitive that does not exist:

- **fear, drink, grief** — named in Decision 22, never built
- **a lord's writ, a guild rate, a season's bargain** — named on
  `Obligation.get_weight_at_scoring_time()`, never built
- **hierarchy pressure** — Decision 37, below
- **standing** — Gate 2 of the boss ladder
- **precepts** — a value system that makes the same act read differently to
  different people; the one steal worth taking from RimWorld

`lens` appears **zero times** in the codebase. Decision 22 is a ruling about how
modifiers must behave and has never been code. So each of those five is
currently on course to be written as its own mechanism, which is the shape that
makes a substrate expensive: n systems, n-squared interactions.

**What RimWorld actually proves is not its modding API.** It is that a game can
carry four DLCs without a maintenance collapse by having very few mechanisms and
enormous numbers of *instances* of them. Ideology did not add a religion system;
precepts are data that emit an existing modifier and gate an existing job. The
lesson is primitive-count, and it transfers. The Def system does **not** transfer
— it is why RimWorld cannot be understood by reading it, which is a direct trade
against this project's first tenet.

### The seams it installs into — six, not four

| Seam | Body today |
|---|---|
| `Brain.get_adenosine_accumulation()` | `base_adenosine_per_hour * get_exertion()` |
| `Brain.get_adenosine_recovery()` | `base_adenosine_cleared_per_hour * strength` |
| `Brain.get_hunger_accumulation()` | `base_hunger_per_hour` |
| `Brain.get_social_accumulation()` | `base_social_per_hour` |
| `WorkStep.get_yield_per_hour(person)` | `base_grain_per_hour` |
| `Obligation.get_weight_at_scoring_time()` | `weight` |

**Two of them already multiply by a factor**, so this generalises a pattern
proven twice rather than inventing one. Every one of those getters already
carries a comment saying that everything which will ever change it lands there
with no caller moving. This is that landing.

**THE TRAP IN THAT TABLE: `WorkStep` IS A SHARED SCENE.** Same resource for
everybody, per the node-vs-shared-file rule — so it can never hold a condition
and must never store one. It already takes `person` as an argument, and that is
the door: it asks the man. The four `Brain` getters reach him the same way;
`Obligation` reaches him with `get_parent()`.

### Where it lives

**A Node under the Person**, found by walking children — the identical shape
`get_obligations()` and `reload_known_actions()` already use. The tree is the
store. Nothing keeps a parallel list, so nothing can disagree with it, and a
condition exists exactly as long as its node does.

```gdscript
func get_conditions() -> Array[Condition]:
```

### Named `Condition`, not `Lens`

Decision 22's word is *lens*, and it would normally be honoured. It is dropped
under naming rule 4 — *if a name hides what the thing does, rename it.* A lens is
about **seeing**; this changes how fast a man tires. `Condition` is plain
English, covers drunk / frightened / grieving / bound-by-a-writ, and is not CS
vocabulary. Checked and free, as are `Lens`, `Modifier`, `Influence`, `Sway` and
`Pressure`.

### THE RULING THAT MAKES IT CHEAP — intensity is a stat, the condition is the translation

Decision 22 names fear, drink and grief as lenses. `CLAUDE.md` names *"fear
fading"* as upkeep — that is, a stat. **Both are right, once split:**

> **A stat is a magnitude that changes over time. A condition is the translation
> from that magnitude into an effect on a rate or a weight.**

`fear` is a number that rises when something frightens him and decays in
`run_upkeep`, one more line beside hunger. `Frightened` is a Condition whose
factor is computed from that number.

**The payoff is that conditions attach by composition and never move.** Every
person carries the same set, permanently — exactly as eat and flee are on
everybody's ballot by composition rather than by a flag — and each returns `1.0`
while its driving stat is zero. Nothing installs, nothing removes, nothing can
be forgotten.

The alternative — install a condition when he is frightened, remove it when he
calms — is **a flag somebody has to remember to clear**, which is the shape this
substrate has already rejected twice: once when `_held` moved off a stored array
onto a derived question (W3), and once when `is_discharged()` stopped reading a
mark somebody flipped (Decision 34).

**Two flavours, one class.** A *driven* condition computes its factor from a stat
(fear, drink, grief). An *installed* condition carries an authored factor and is
attached when something happens (a precept, a season). They differ only in
whether the factor is computed or declared, and only the second ever needs an
expiry — which is the proven lazy day-stamp, read at read time, swept by nobody.

### The two rules that keep it from becoming a system

**1. A condition may never read another condition.** It may read the person's
stats and the world; it may not read its siblings. This is the whole of what
makes twelve of them composable without anyone having considered that
combination, and it is precisely what RimWorld gets right — no hediff ever
references another hediff, which is why stacking is O(n) and not O(n-squared).

They still interact *through the world* — a condition slowing recovery leaves
more adenosine, which another condition reads. That is unavoidable and fine. The
ban is on direct reads.

**2. ZERO IS A GATE, AND IS THEREFORE FORBIDDEN.** `want = weight x gap^bite`. A
factor of `0.0` sets a want to zero, which is *outbid by everything, for ever* —
barred in all but name. Decision 22 says a lens may never gate, and Decision 22's
own **"outbid, never barred"** is broken by a single zero.

**This is enforcement, not documentation.** Factors are clamped strictly above
zero at the door, with a warning, and are never trusted to the author. A silent
zero presents as *"this action mysteriously never fires"*, which is the worst
diagnosis available in this codebase and the exact family as the silent null
guard that shipped a dead day/night cycle.

### What it may not touch, restated from Decision 22

**It may multiply a `weight`, or change a rate. It may never touch a `gap`, and
it may never gate.** A gap is a fact about the world — how empty the larder is,
how far past dawn he slept. A condition is how loudly he feels about it. Letting
one write a gap makes the world's own bookkeeping a matter of opinion.

### The stacking problem arrives immediately, and the answer is drawing it

`brain.gd` already warns: *"three 2x modifiers is 8x, not 6x. At four factors,
revisit; not before."* A general primitive makes four factors trivial — five
grievances at 1.5x is 7.6x.

**Multiply anyway, and make the product drawable.** The answer to runaway
stacking, in a project whose stated constraint is legibility, is seeing it rather
than preventing it. Bounding the product hides the compounding and leaves a
tuning mystery.

**WHICH LANDS ON A REAL GAP IN THE TOOLING.** `stat_graph` samples through
`person.stats.get_stat_names()` — it can plot **stats and nothing else**. Every
number a condition touches is a rate or a weight, none of which is a stat. So
today the effects of a condition are visible (his hunger climbs, the line bends)
and its cause is invisible. **The one number that explains his behaviour is the
one number the graph structurally cannot draw.**

The fix is not to make `weight` a stat — it is not his, it belongs to a
relationship, and `Stats` is the wrong owner. It is for `stat_graph` to discover
numbers the way `tuning_board` already does: by reflecting over exported numbers
on the nodes it is pointed at. That keeps the property `CLAUDE.md` names for all
three UI tools — **no line per stat, per knob or per verb.** A graph with
`weight` hardcoded into it is the same failure as `verb_list` naming a verb.

### What this does NOT settle

- **The clamp floor.** "Strictly above zero" is the rule; whether that is
  `0.01`, an epsilon, or a warn-and-substitute is unmeasured and should be
  chosen against a real condition rather than in advance.
- **Whether the six getters walk the children on every call.** They run every
  tick for every person. Walking a handful of nodes is almost certainly free at
  three people and is certainly not free at three hundred; the cache seam is
  `reload_known_actions`'s shape if it is ever wanted. **Do not pre-build it.**
- **Whether a condition may modify a getter belonging to someone else.** Nothing
  here permits it and nothing here argues it. Assume no until a case is made.
- **Expiry granularity.** `Obligation` and `Workstation` both day-stamp. Drink
  and fear are hour-scale. If installed conditions ever need hours, that is a new
  question about what `Clock` exposes, not a rewrite of this.
- **Whether `exertion` and `strength` should become conditions.** They are the
  two factors that already exist and they work. Folding them in is tidying, and
  tidying that moves Hobb's `04:47` is not tidying.

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| — | Nothing is built. This section is the specification, and the first thing that needs a modifier is the thing that should build it. | **not applied** |
| `stat_graph.gd` | Must discover by reflection over the tree rather than through `get_stat_names()`, or a condition's cause is undrawable. Blocks nothing until the first condition exists. | **not applied** |

---

## Decision 37 — Pressure is applied, never transmitted

**Settled 2026-08-28.** **Nothing here is built.** It settles the mechanism by
which a decision at the top of a hierarchy reaches the bottom, which the boss
ladder needs before Gate 6's writ and which W3 in the workbench file already
names as the point of NPC-to-NPC exchanges.

### The question, asked plainly

A lord wants grain. As his need goes unmet, does that raise the `weight` on his
steward's obligation — so that the steward feels more pressure and leans harder
on his workers?

**No.** The lord's gap drives **the lord's own ballot** and touches nothing else.

### The mechanism

1. The lord wants grain. `wanted - in_barn` is a gap **on his own node**.
2. That gap scores **his** actions, `want = weight x gap^bite`, the same as
   everybody's. With an empty barn, *lean on the steward* outbids whatever else
   his day held.
3. Leaning is **an exchange**. It costs him hours, it holds both parties out of
   the ballot, and it can be refused.
4. If it lands, it **writes a number** — sets a weight, a quota, a deadline on
   the steward's obligation. A discrete act, at a moment, by a named man.
5. That number **persists**. It does not decay and it does not track the lord's
   mood. It sits there until somebody comes and changes it.
6. The steward now holds a heavier obligation and a gap of his own, and the same
   thing happens one layer down.

**Pressure is applied, not transmitted. Every hop is somebody choosing to spend
time on it.**

### THE REFRAME — his gap sets how often he shows up, not how big the number is

An unmet need does not raise anyone else's number. It raises **his own
likelihood of acting.** A lord badly behind on grain has *lean on the steward*
winning his ballot repeatedly, so he keeps turning up. A lord who is fine has it
losing to everything, so he is never seen.

**The pressure a steward feels is a lord who keeps appearing.** That is better
fiction than a multiplier, it is free from the substrate as it already stands,
and — the point — it is *watchable* rather than readable off a number.

### Why the continuous version is wrong, on four counts

- **It is a second, quieter override.** W5 already warns about exactly this
  shape. A live coupling bends a man without anyone acting, at no cost, from any
  distance. It deletes the action economy whole.
- **It breaks the carried/read line** (below). A lord's appetite is not a world
  fact. If a steward's weight tracks it live, the steward is reading his lord's
  mind — with no delivery, and no point at which anyone could refuse.
- **It is illegible.** `issued_by` (Decision 38) works because a weight was
  *set*, by someone, at a moment. A weight that drifts has no author, so the
  cascade stops being traceable — and this project has already ruled that
  *legibility is a design constraint, not a nicety.*
- **It kills the middle man.** A steward who transmits pressure automatically is
  not choosing to lean on anybody. He is a belt. The whole reason a hierarchy is
  interesting is that your instrument is a person with his own ballot.

### The line this rests on — what is read, and what must be carried

> **Facts about the world are read. Facts about a relationship are carried.**

The price of grain, the season, the law, whether it is daylight — nobody
delivers the weather, and an obligation may read them freely. **What one man
specifically owes another must be carried to him by an exchange**, at cost, and
may be refused.

That is not arbitrary; it is the line this codebase already draws. Decision 30
made freeness public. Decision 35 confirmed no gate reads where a man is
standing. `obligation.gd` says stored intent exists *precisely* because "no
amount of looking at the world tells you who this man agreed to work for."

**And it hands over the overt/covert spectrum as an economic fact rather than a
theme:** a lord who changes *the world* reaches everybody at once, cheaply and
visibly. A man who changes *individuals* pays one expensive exchange each, and
nobody can read the pattern. Same substrate, opposite economics.

### The one thing that varies without a new visit

A term set at the last exchange may itself be time-varying. *"Two hundred grain
**by winter**"* gets louder as winter comes, with nobody visiting.

That is legal, and the distinction is exact: **it is not the lord's live
appetite leaking, it is a term of the deal, ticking** — authored at a moment,
delivered by an exchange, and thereafter the steward's own to feel. Carried
once, then read for ever.

### The boundary between the two primitives

Settled here because it decides where `issued_by` has to exist:

> **An `Obligation` is a deal with a named counterparty. A `Condition` is a
> modifier with nobody on the other end.**

A writ setting a wage or a quota is an obligation field — it has an issuer, it is
traceable, it was carried, and somebody could have refused it. A precept, a
season, drink, fear and grief are conditions — no counterparty, nothing to
trace, nobody to refuse. **So `issued_by` lives on `Obligation` only**, and
`Condition` never needs it.

### What falls out for free

- **Attention is rationed by his own gaps.** A lord with finite hours and three
  things behind goes to whichever is worst. A steward who performs is left alone;
  one who does not gets a lord in his face. Emergent management, nobody wrote it.
- **Satisfaction does not propagate.** The lord's gap closes and he stops coming
  — but the weight he set is still on the steward, because it persists. The
  steward grinds on at the elevated number until told otherwise.
- **Silence is ambiguous, honestly.** A steward who has not seen his lord in a
  month cannot tell whether he is doing well or has been forgotten.

### What this does NOT settle

- **Whether an obligation decays.** The author's call, stated 2026-08-28 and
  deliberately not argued here: *"my gut says persist but still interruptable,
  overridable by a higher power."* Recorded as an inclination, not a ruling.
  Persisting means reach accumulates for free and a twentieth farmer costs what
  the first did; decaying makes holding power an upkeep in exchanges. Unmeasured
  either way.
- **What a refusal is actually driven by.** W1's open question is untouched.
  Decision 38 offers a candidate, and it is a candidate only.
- **Fan-out.** Everything here is one-to-one. Whether a lord may address a crowd
  — O(1) delivery to n people, presumably at worse compliance per head — is a
  real and attractive question and is not asked here.
- **Whether a message degrades per hop.** If it can, hierarchy depth *is* the
  illegibility the title is about, and the farmer blames the steward standing in
  front of him. Named because it is the most on-thesis thing in this area; not
  settled.
- **Attribution.** Nobody in this town believes anything about anybody, so
  nothing can yet be *mis*attributed. That is the primitive the spine actually
  needs and it is worthless before there is a hierarchy deep enough to
  misattribute through. Not settled, deliberately late.

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| `boss-scene-build-plan.md`, Gate 6 | The writ is the first delivery. It sets a number on somebody else's obligation; it does not couple two people's needs. | **not applied** |
| `workbench/exchanges/DECISIONS.md`, W5 | Consistent, and now narrower: an exchange result raising `weight` is the ONLY channel from one man's need to another man's number. | **not applied** |

---

## Decision 38 — A quota is safe one layer above the labour

**Settled 2026-08-28.** **Nothing here is built.** It resolves an apparent
contradiction between the author's instinct that hierarchies push quotas
downward and Decision 29's finding that quotas break the loop.

### The contradiction

Decision 29 deleted the quota model outright. Measured over six days, a daily
grain debt on the worker meant **meeting the quota and stopping work were the
same event** — grain came off the plot one unit at a time and the delivery leg
ran in the same tick, so no man ever *held* a grain, `MakeBread`'s gate never
opened, and the loop work -> grain -> bread -> eat could not fire at any tuning.

Decision 31 generalised it: *"a gap drives the action that closes it in ONE act;
an action whose output closes its own driver slowly and continuously must not be
scored on that gap."*

So "the lord raises the quota" looks forbidden.

### The ruling

**Neither finding reaches the man who DIRECTS the work.**

A steward's gap is not closed continuously by his own step. He does not work the
field — he leans on farmers, and his gap closes in **discrete jumps, when other
people's deliveries arrive.** He cannot grind it down himself, so there is no
tick on which "meeting it" and "stopping" could be the same event.

The trap that killed quotas at the labour layer is **structurally absent** one
layer up. A quota on a director is safe for a reason, not by luck.

### IT IS THE SAME WORD FOR THE SAME FIELD — THIS IS A RESTORATION, NOT A NEW DESIGN

Said plainly, because reading 29 and 38 together should not look like 38
reversing 29. **It does not reverse it. It narrows where it applies.**

A quota is exactly what `Obligation` used to carry and what Decision 29 removed
— `owed_item` / `owed_count`, tracked down by `delivered_count` /
`delivered_on_day` / `note_delivery()`. **The field shape is in git and the
arithmetic largely still applies.** What changed is not the mechanism, it is
**who holds one**:

| | The farmer | The steward |
|---|---|---|
| Holds a quota | **no** — Decision 29 | **yes** — this section |
| What drives him | `weight`, flat all day (Decision 31) | the quota |
| Who closes it | his own step, continuously | other people, in discrete jumps |

**AND THE SECOND HALF OF DECISION 29 MUST NOT COME BACK WITH IT.** That section
found two things, and only the first is narrowed here. The second stands
untouched: the old quota modelled employment as a **grain DEBT**, as though the
crop were the worker's to owe. *"The grain was never the worker's to OWE. Hobb
works Marle's land under Marle's employment; the crop is Marle's from the moment
it leaves the ground."*

So a steward's quota is **an outcome he is accountable for, never goods he
personally owes.** Restore the field and the debt semantics come back with it
unless somebody is watching for exactly this — which would quietly undo Decision
29's real finding while appearing to honour it.

**Vocabulary, fixed here:** this file says **quota** for the thing an obligation
carries and **gap** for what it is measured as. A quota IS a gap — a live
measurement of what is owed against what has arrived, feeding `weight x gap^bite`
like every other want since Decision 19. Two words, one object, and they are not
interchangeable: *every* want has a gap, and only a director's obligation has a
quota.

### What that makes the whole stack

> **Every layer holds its own gap. Only weight propagates downward.**

- The **lord** wants grain. That gap drives him to lean on the steward
  (Decision 37).
- The **steward** wants his quota. That gap drives him to lean on farmers.
- The **farmer** has no quota at all. He has a heavier `weight`.

### AND THAT ANSWERS WHAT PRESSURE ACTUALLY DOES AT THE BOTTOM

**The working layer is already saturated.** A farmer works every daylight hour —
`WorkForHire` scores flat all day by Decision 31, so it never gets quieter and
there are no unworked hours left to buy. Weight from above therefore **cannot
make him work more.** What it does is make work outbid the other things on his
ballot.

**So pressure converts a man's needs into labour.** A lord leaning on a steward
leaning on a farmer produces, at the bottom, a man who skips supper and stays in
the field past dark. He does not die — there are no hard-fail states — he simply
accumulates hunger, loneliness and adenosine that nothing is paying off.

That is a complete loop, and every part of it is already built except the leaning.

### A candidate answer to W1, offered as a candidate

W1 gave up the property that a refusal names whatever outbid you, and left the
important question open: *if that is no longer what refuses, what does?*

**Accumulated unmet need is a candidate.** The man who refuses is the man whose
stats have been ground down by a season of being leaned on. Not a new stat and
not a mood system — the three gaps already running in `run_upkeep`, read at the
moment of the ask.

Its attraction is that the excuse then names something **true, and caused by the
player** — which is the property W1 was most worried about giving up. It just
names *the cumulative cost of your own commands* rather than *whatever outbid you
this tick*.

**It is not settled.** It has not been measured, W2's no-path is still unwritten,
and the ordering hazard below is real.

### What this does NOT settle

- **Whether accumulated unmet need is what refuses.** Candidate only. See above.
- **THE GATE ORDERING HAZARD, which is the live risk in this area.** Beckon
  (Gate 3) is where refusal first exists. Give (Gate 4) and the wage (Gate 8) are
  the tools that convert a refusal into future compliance, and they arrive
  *after* it. Between those gates a player has been taught that people say no and
  handed nothing to do about it. RimWorld never has this problem because drafting
  is always available as an escape hatch; this design has deliberately refused
  that hatch, which means **the refusal rate is a tuning surface with no safety
  valve.** The cheapest fix is ordering, not mechanism. Named here, not solved.
- **What "lean on somebody" is, as an Action.** It is an exchange with a result
  that writes a number. Its gate, its score and its step are unwritten.
- **What the lord's grain gap is measured against.** `wanted - in_barn` is the
  obvious shape and is not the only one.

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| `boss-scene-build-plan.md`, Gates 3-8 | The ordering hazard above is a real risk to the ladder as sequenced and should be answered before Gate 3 ships. | **not applied** |
| `obligation.gd` | Gains back a **quota** — the field Decision 29 removed, returning at a different layer and WITHOUT the debt semantics — alongside the weight and the wage it already carries. Directors only. | **not applied** |

---

## Decision 39 — The simulation is always full-resolution. There are no coarse ticks.

**Settled 2026-08-29** (author's call, correcting a design conversation that had
assumed the opposite). This one is unusual in that **the code already does it** —
what is settled is that it stays that way, and that a whole family of
optimisations is off the table.

### The question

`population.gd` names the scenario in its own header: *"promoting a distant
village to full simulation and collapsing it again."* So: when a region is far
from the player, or nobody is watching it, does it step at a **bigger `hours` per
tick** — four hours at a time instead of a hundredth?

**No. A tick is never deliberately enlarged — not for distance, not for
population, not for whether anyone is looking.**

**Stated precisely, because "the tick size never changes" would be false.** In
the live game the tick is the frame delta converted — `Population._process` hands
`Clock.get_hours_elapsed(delta)` down, so at 60 fps and a 60-second day a tick is
about 0.0067 hours, and it jitters with the frame rate. The probe passes a fixed
0.01. **Neither is a fidelity choice; both are small.** What this section forbids
is the deliberate enlargement — handing a distant region four hours where a near
one gets a hundredth, so that its people think once where the others think six
hundred times.

What changes when nobody is watching is **wall-clock speed and whether
presentation runs** — never the resolution of the simulation. The author's
words: *"we'll always step the ticks, they'll just be unbounded by not having to
draw on the screen, and it takes how long it takes but definitely sped up.
otherwise you get all sorts of problems."*

### Why — the failure mode is what decides it

A coarse-ticked region **behaves differently from a fine-ticked one**, and the
difference is not a rounding error. Three examples out of the design
conversation that produced this section:

- A held man loses twenty ballots to a 0.2-hour conversation at 0.01-hour ticks,
  and **zero** at four-hour ticks — he only got one decision for the whole tick
  anyway. So the cost of talking to somebody depends on whether anyone is
  watching.
- Contention resolves differently. Two farmers racing for a plot at fine
  resolution is a real race; at four hours a tick it is whoever the loop reaches
  first, with the whole morning collapsed into one comparison.
- Any threshold crossed and re-crossed inside one coarse tick simply never
  happened.

**Watched-versus-unwatched divergence is the least debuggable class of bug this
project could adopt**, because the act of looking at it changes it. A hitch —
the player waiting while a region catches up — is survivable, visible, and
profileable. In a game with no hard-fail states and no reflex demands, that trade
is not close.

**This is the Dwarf Fortress trade, taken deliberately.** It is why that game is
deep and why it stutters.

### It already works, and it is already measured

**`probe.gd` IS the collapsed-region execution model.** It loads the real
`game.tscn`, pumps `think_for_everyone(0.01)` by hand, and runs 48 simulated
hours with nothing drawn — real scene, real people, same tick size, unbounded by
frame rate. **14898 checks a run.** There is no second code path to write and no
approximation to reconcile, because the thing a distant region would do is the
thing the probe has been doing since rung 0.

The architecture that permits it is already load-bearing and already documented:
**presentation redraws as often as it is LOOKED AT, not as often as the world is
stepped.** `Person._show_the_body()` runs in `_process`; `think_and_act` runs
from `Population`. That split was written for frame-rate independence and turns
out to be the LOD architecture.

### What it costs, stated plainly

**A region's cost does not shrink with distance.** Five hundred people across a
kingdom simulating a week is five hundred x 168 hours x 100 ticks an hour of
person-ticks whether anybody is watching or not. This decision buys correctness
with compute and nothing else.

### The mitigation that preserves everything — run BEHIND, never COARSER

A region that is too expensive to keep current may run **fewer ticks per frame**
and fall behind, catching up over time. That is a **queue depth, not a fidelity
change**: every tick it eventually runs is the same size as every other tick in
the game.

**SPLIT BETWEEN TICKS, NEVER WITHIN ONE.** `population.gd` is emphatic that
people are walked one at a time with nothing running in between, because that is
what makes contention correct with no locking anywhere. Running half a town's
people this frame and half the next **breaks that**, silently and only under
contention. Running the whole town fewer times does not.

### The consequence, and the thing that pays for it

Regions running behind means **regions sit at different world-times** — the
lagging one at hour 100 while the player's is at 103. That is fine until
something spans them.

**And travel time is the catch-up budget.** You can only exchange with somebody
you are standing next to, so a cross-region conversation requires walking there —
and the region being walked toward has the entire journey to catch up. *The thing
that makes reconciliation necessary is the same thing that pays for it.* Nothing
needs building for this; it falls out of the fact that talking requires
proximity.

### WHAT THIS RETIRES — a constraint argued from the rejected premise

The design conversation that led here had proposed, as a hard requirement, that
**an exchange must be resolvable in one call with no accumulated conversational
state** — because a coarse-ticked region could not reproduce a conversation that
developed over many fine ticks.

**That justification is gone with the premise, and is withdrawn rather than
re-argued.** What remains is weaker and is a preference, not a rule: single-call
resolution is marginally kinder to tick-for-tick replay (which `population.gd`
names as a thing its call site enables) and makes fast-forward cheaper. Neither
is a requirement.

**So a greeting-rung ladder in which each exchange warms a man up is back on the
table**, as is any multi-stage negotiation. Whatever eventually answers W1 is not
constrained by this.

### What this does NOT settle

- **Whether a distant region is ever UNLOADED.** This section is about tick
  *size*, not about whether bodies exist. Despawning a region's people is a
  different question with different consequences — every stored `Person`
  reference in an exchange or an obligation would need `is_instance_valid` to do
  real work, and an exchange whose party was unloaded would end **silently**,
  which `CLAUDE.md`'s standing rule against silent guards would not accept.
  Unasked here.
- **What the hitch budget is.** "It takes how long it takes" is the ruling; how
  long is too long before a region must be allowed to fall behind is unmeasured,
  and should be measured rather than guessed.
- **Whether a tick should be BOUNDED, and at what.** Nothing clamps
  `get_hours_elapsed` today, so a frame hitch or a debugger pause hands the whole
  town one enormous tick — which is precisely the coarse step this section
  forbids, arriving by accident rather than by design. A `maxf` in `Clock` is the
  obvious guard and is deliberately not specified here; it wants measuring.
- **What tick size is RIGHT.** 0.01 is what the probe measures at and ~0.0067 is
  what 60 fps produces. Nothing here argues either is correct — only that no
  region gets a deliberately larger one than another.

### Plan edits this implies

| Where | Edit | Applied |
|---|---|---|
| — | Nothing to build. The code already behaves this way; this section forbids the optimisation that would change it. | **not applied** |
| `population.gd` header | Its "collapsing it again" line reads as though coarse stepping were the intent. It is the one place a future builder would look for permission to do it, and should say instead that collapsing means *unbounded by the frame rate*, never *bigger hours*. | **not applied** |
