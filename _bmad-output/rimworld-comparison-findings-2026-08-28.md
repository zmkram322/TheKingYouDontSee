# RimWorld comparison — findings, 2026-08-28

*What this session FOUND, as against what it was told to look for. The ask was
"compare TKYDS to RimWorld." What came out of it was three project Decisions
(36–38), two workbench entries (W8–W9), one shipped bug fix, and two corrections
to claims already on record in this repo.*

**Read `proving-scene-decisions.md` 36–38 for the rulings.** This file is the
reasoning that produced them, plus everything that did not become a ruling.

---

## The headline, stated so it cannot be softened

**TKYDS's differentiation from RimWorld exists today only in the architecture,
not in anything a player can touch.** As of Gate 1 the player can only command
himself, nobody has ever refused him anything, and exactly **one** stat
distinguishes any two people in shipped code — `strength`, multiplying
`Brain.get_adenosine_recovery()`, which is the entire mechanical content of Hobb
waking at 04:47 and Zoogs at 05:52.

Play it today and, hands-on, it reads like an undrafted RimWorld colonist
wandering a very small base with a nicer camera and no priority tab.

**It becomes a played fact the day someone beckons a tired man across the square,
hears him say he is dead on his feet, and feels that as a relationship rather
than a bug. That is Gate 3, and it has not been built.**

---

## Two corrections to claims already on record

### 1. "Refusal there is a static capability flag" is not right, and the truth is sharper

`roundtable-brief-2026-08-08.html` (line ~669) calls RimWorld "the sharpest
contrast — refusal there is a static capability flag; here it is a contested
score that can be outbid."

**RimWorld does not have one refusal mechanism. It has two control regimes.**
Undrafted, a colonist runs a **lexicographic priority queue** — you rank work
types 1–4, and he exhausts every priority-1 job before touching priority-2, with
needs interrupting at thresholds rather than competing continuously. Drafted, he
executes the player's literal click with **zero** negotiation. A mental break is
a discrete state transition layered on top of whichever regime is running, not a
bid.

So the accurate claim is bigger than the one on record:

> **RimWorld has no unified concept of "a command" at all.** An autonomy mode and
> a puppet mode, switched by a hotkey. Refusal exists only as a categorical
> override on top of one of them — never as a magnitude comparison between what
> you were told and what you already wanted.

Decision 33's real insight is that these should never have been two modes.

### 2. "This build already has the RimWorld half" is overstated

Same brief, line ~471: the number lives in the colonist, so the same offer yields
different answers, and that difference is characterisation.

Directionally right, and **not yet true as a measurement.** One axis
(`strength`) against RimWorld's dozen skills with passion multipliers, dozen-plus
traits, two stacked backstories restricting whole work categories, and a live
injury/capacity ledger. Correct as an architectural bet (Decision 12); not
correct as a description of what is built.

---

## What genuinely converges, and where it stops

**A real, shipped, defensible difference nobody would notice:** `DecisionEngine`
is a **continuous cardinal auction with no priority tiers and no stored
commitment**, recomputed from scratch every tick. RimWorld is a priority ladder
with threshold interrupts. In RimWorld a severely-gapped low-tier want *cannot*
interrupt a running priority-1 job; here, any want can win any tick if its number
is big enough. That is a genuine divergence — and you would need two decision
graphs side by side to see it.

**The reservation comparison is the better one.** RimWorld's Reservation Manager
and `Workstation.claimed_by` do the same job, but RimWorld releases explicitly
(job completes, is cancelled, colonist is drafted away) while
`Workstation` has **no `release()` at all, by design** — a day-long tenancy that
lapses unread if nobody re-stamps it. That is "store nothing you can work out
again" actually paying rent: interrupting a farmer costs nothing because there
was never a commitment object to clean up.

---

## The finding that became Decision 36 — where the extensibility actually comes from

RimWorld's extensibility is **not** the modding API. It is that the game has
roughly six generic primitives — Hediff, Thought, StatPart, Def, Comp, Incident —
and essentially all content, four DLCs included, is an **instance** of one rather
than a new mechanism. Ideology did not add a religion system; precepts are data
that emit an existing modifier and gate an existing job.

And the one rule that keeps it from collapsing: **no modifier ever reads another
modifier.** Each independently offsets a base. That is what makes stacking O(n)
instead of O(n-squared), and why you can pile twelve hediffs and forty thoughts
on a pawn that nobody ever thought about together.

**Scored against that, TKYDS wins twice and loses once.**

*Ahead — the decision layer.* RimWorld needs a ThinkTree AND work priorities AND
need thresholds AND mental states because it has no common currency.
`want = weight x gap^bite` means a new drive is a new gap: no tree node, no
tier, no threshold. **Strictly more extensible than RimWorld**, and the reason
not to graft their hierarchy onto it.

*Ahead — the tree is the store.* Known actions, obligations, live exchanges, all
discovered by walking children. No registries, nothing to keep in sync. RimWorld
has manager singletons and cache invalidation precisely because its store is not
its structure.

*Behind, and it is the whole hole —* **there is no "condition attached to a
person" primitive.** Stats are numbers he has; obligations are relationships he
is in; actions are things he can do. Nothing says *this man currently has a thing
that modifies him.* `lens` appears **zero times** in the codebase; Decision 22
has never been code.

**Five consumers are queued behind that one missing primitive** — fear/drink/
grief (Decision 22), a lord's writ/guild rate/season (`obligation.gd`), hierarchy
pressure (Decision 37), standing (Gate 2), and precepts. Five systems each about
to be written separately. That is Decision 36.

**And the Def system is the one thing NOT to copy.** It is why RimWorld cannot be
understood by reading it — behaviour lives in XML across hundreds of files and
"why did this happen" often needs a debugger or a wiki. They traded
comprehensibility for moddability. This project has bet the opposite way, and its
equivalent is already better for its own purposes: scenes with exported numbers,
`tuning_board` reflecting a slider onto every one of them, and a person's whole
configuration visible in the tree you would already be looking at.

---

## The bug this session found and fixed

Not what the session was for, and the most concrete thing in it. Full account in
`workbench/exchanges/DECISIONS.md`, **W8**.

`exchange_population.gd` skipped a held man with a bare `continue`. Upkeep is the
tail of `Brain.think_and_act`, so **time stopped for anybody in a conversation** —
no hunger, no adenosine, no loneliness. A long enough exchange was a free rest.
And `_speed` kept its last value, so a man held mid-stride stood still playing a
walk cycle.

Fixed by making `Brain.run_upkeep` public (it was `_update_body`) and adding
`Person.run_upkeep`, which runs the body, opens no ballot, and hands the movement
measure a real zero. **The probe is unmoved: 64 claims, 14898 checks, 21:14 /
05:52, 22:10 / 8.00 h / 06:10, strong man 04:47.**

**THE PART WORTH REMEMBERING:** the workbench's own seam check had asserted
`HELD, he does not: adenosine stayed at 5.00` — **and it passed, the whole time.**
It was green because it was written to describe what the code did rather than
what the design wanted. That is a new entry in this project's catalogue of
vacuous-assertion failures, and a different species from the eight already
caught: not a claim that could not fail, but a claim that was **aimed at the
wrong outcome**. The existing discipline (break it, watch it go red) would never
have caught this one, because breaking the code would have made it fail
correctly.

---

## What RimWorld warns about

**Psychological depth and political reach are orthogonal axes, and RimWorld
maximises the first while having none of the second.** A colonist can have a
spouse, a rival, a decade of memory, and **none of it ever routes a decision
through a third party on the player's behalf.** Relationships terminate in a mood
modifier or a compatibility check; faction goodwill is a single scalar gating
raid frequency and trade access — a resource meter, not a web of who owes whom.

TKYDS's thesis — *power is a measure of how many people fall under the shadow of
your decisions* — requires a **propagation primitive** that RimWorld never needed
and never built. **Depth of simulation is not evidence of reach.** You can ship a
beloved, deep sim for a decade without ever closing that gap.

**Second warning: RimWorld's drama runs substantially on lethal stakes.** Raids,
bleeding out, freezing, organ harvesting. Decision 27 and tenet T5 cut all of it
off deliberately. That is a good, argued choice — but it means TKYDS cannot
borrow RimWorld's proof that "the simulation generates drama" and assume it holds
without mortality. All the tension has to come from the command/refusal economy,
which is the thing still unbuilt past Gate 1. **It is not a warning to add death.
It is a warning that the substitute needs to be proven to carry weight on its
own, because there is no fallback if it does not.**

---

## The live risk this surfaced, which is not a RimWorld question at all

**Gate ordering.** Beckon (Gate 3) is where refusal first exists. Give (Gate 4)
and the wage (Gate 8) are the tools that convert a refusal into future
compliance — and they arrive **after** it. Between those gates the player has
been taught that people say no and handed nothing to do about it.

RimWorld never has this problem because **drafting is always available as an
escape hatch**: annoyed by a refusal, you take the wheel. This design has
deliberately refused that hatch, which is right for the thesis and means **the
refusal rate is a tuning surface with no safety valve.** That is the Majesty
failure mode with better subtitles — heroes who would not take your bounty and no
way to make them want to.

**Cheapest fix is ordering, not mechanism.** Recorded in Decision 38's "does not
settle" list; unsolved.

---

## Things established here that did not become rulings

- **The action economy is why hierarchy exists.** An exchange holds both parties,
  so a lord who wants twenty farmers to change pays twenty exchanges out of a day
  the same length as theirs. He physically cannot reach them all. Nobody designed
  that; it falls out of the hold. And it makes the thesis countable — reach is
  people-affected over exchanges-spent.
- **The interrupt is asymmetric.** An exchange is a *chosen action* for the
  initiator and *taken time* for the recipient. `_seam_check` correctly says both
  are held, but the costs differ — which is what caps a steward's delivery route
  at however many stops his own hunger allows, with nobody authoring a limit.
- **Attribution is the primitive the spine actually needs, and it is deliberately
  late.** Nobody in this town believes anything about anybody, so nothing can be
  *mis*attributed — and *the gap between what the world attributes to you and
  what you authored* is the whole spine. It is worthless before there is a
  hierarchy deep enough to misattribute through, and it is legible only because
  the true chain (`issued_by`) and what each man believes would both be drawable.
- **`Sequence` is an `ActionStep`, not a port.** Author's correction, confirmed
  against `40c53e1`. See W9.
- **The `MakeBread` curve problem is a RimWorld lesson in disguise.**
  `115 x gap^3` parks bread at 2 loaves against a target of 6 — a cubic bite
  tuned for a *saturating* gap (hunger) applied to a *maintenance* gap (a larder
  held topped up). RimWorld uses three separately-engineered mechanisms for mood,
  needs and work priority because one formula strains differently against
  different need-shapes. **That is evidence, not merely a different taste.** The
  unification is worth defending, but `bite` may need to be per-gap-*type* rather
  than a universal constant before a fifth or sixth need lands. Decision 34's open
  question, unresolved.

---

## Recommended addition to `design-positioning-and-comparables.md`

The comparables playbook (section 5) currently teaches about **paths** — CK3,
Dishonored, Mordor, Disco Elysium. Nothing in it teaches about **the player's
relationship to the agent being led**, which is arguably the more central axis
for this project. Drafted below in that document's house style, to sit after
Dishonored. **Not applied.**

### RimWorld — the deepest simulation, the shallowest politics (the mirror)

Colonists carry a dozen skills with passion multipliers, a dozen-plus traits, two
stacked backstories restricting whole work categories, and a running mood ledger
of named modifiers — the most individuated agents in this list, bar none.
Undrafted, they run an autonomous work-priority queue that need-thresholds can
interrupt; drafted, they execute the player's click with no negotiation at all,
mental breaks being the only override either mode has. Refusal is never a
magnitude comparison against a command — it is a rare categorical status effect
layered on top of one of two separate control regimes, never a bid entering a
shared ballot.

**Transferable lesson:** RimWorld proves that psychological depth and political
reach are *orthogonal axes*. A colonist can have a spouse, a rival, a decade of
memory, and it never once routes a decision through a third party on the player's
behalf — relationships terminate in a mood number or a compatibility flag, and
faction goodwill is a single scalar, not a legible web of who owes whom. TKYDS's
thesis (power = *how many people fall under the shadow of your decisions*)
requires a propagation primitive RimWorld never needed to build. Depth of
simulation is not evidence of reach; don't mistake shipping the first for having
proven the second.

**The warning (load-bearing):** *Command as bid, not override* (Decision 33) is
the correct answer to indirect control's oldest failure — Majesty's heroes
refused bounties for reasons the player could never see, and TKYDS's refusal is
guaranteed truthful because the excuse is read straight off whatever actually won
the ballot. But legibility solves the *why* of a no, not the *how often*.
RimWorld sidesteps this entirely by giving the player an escape hatch (drafting)
that overrides refusal outright the moment it becomes tedious. TKYDS has
deliberately refused that hatch — the right call for the thesis — but it means the
refusal *rate* is a tuning surface with no safety valve, and it has not yet been
authored, measured, or even built past the point where a player commands himself.
**If beckon (gate 3) ships before the standing-raising tools (Give, gate 4; wage,
gate 8) that let a player convert a refusal into future compliance, the game will
teach "commanding people doesn't work" before it teaches "commanding people is a
relationship you build" — the exact lesson Majesty's players learned, with better
subtitles.**
