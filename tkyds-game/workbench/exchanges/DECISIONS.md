# Exchanges — workbench decisions

**Started 2026-08-21.** This is a **scratch decisions file for an experiment**,
deliberately NOT `_bmad-output/proving-scene-decisions.md`. Nothing in here is
authoritative over anything in `game/`, and nothing in here should be cited as
settled. It exists so that when the experiment ends we can walk this list and
decide, one by one, what gets promoted into the real decisions file, what gets
rewritten, and what gets deleted with the folder.

Numbered **W1, W2…** on purpose, so a workbench call can never be mistaken for
a project Decision (which are numbered 1–39 and counting).

> **Read this first if you are wondering why the code breaks the rules.**
> Several things here contradict `CLAUDE.md` and the boss ladder outright. The
> contradictions are intentional, they are argued below, and they are confined
> to `workbench/exchanges/`.

---

## W1 — Exchanges do NOT ride the live utility ballot

**The rule this overrides**, from `boss-scene-build-plan.md`, stated there as
the design's central bet:

> *"A command is not an override; **it is a bid.** Tell an exhausted man to work
> and he goes to bed, and the decision graph already draws you exactly why.
> **Nobody has to build refusal.** Somebody has to author the bid."*

**The call (author, 2026-08-21): exchanges are scored independently of the
ballot.** Verbatim reasoning:

> *"there's already really thin margins on utilities winning out and we want the
> boss interactions to have a certain amount of certainty… i know this creates
> parallels but it's going to be needed for fun gameplay."*

Two options were offered and both refused for the same reason: holding the NPC
only *after* he accepts (so the ask is a live bid), and scoring him once while
frozen. Both leave acceptance at the mercy of margins that are already thin.

**What this costs, recorded now so it is not discovered later.** The plan's
elegance was that a refusal names the drive that beat you *because that is where
the string lives* — Sleep says "I'm dead on my feet," Eat says "let me eat
first" — so **a new drive arrives with its own excuse and every command ever
written inherits it for free.** Independent scoring gives that up: refusal
reasons now get authored somewhere specific, once, and every future drive has to
be *remembered* rather than inherited. That is a real maintenance tax and it is
the price of certainty.

**Left open, and it is the important one:** if "whatever outbid you" is no
longer what refuses, *what does?* Standing, mood, fear, a prior grievance, an
existing obligation — unanswered. See W2.

## W2 — Acceptance always succeeds, for now

The channel is built with the answer hardcoded to yes. **The "no" path is not
written**, deliberately, rather than written against a guess about W1's open
question.

**Watch for this going stale.** A branch that never runs is a branch nobody has
checked, and the longer the yes-path is the only path, the more the eventual no
will find the shape of the code wrong. This is the first thing to revisit.

## W3 — An exchange is brokered, not owned by either participant

**Rejected: hanging the exchange off the player.** The author's reason kills it
cleanly:

> *"i intend for exchanges to be possible between NPCs, especially driving the
> interaction of the lord based hierarchy — essentially becoming the way we
> inject goals / obligations / errands onto people."*

There is no player in most of those. So an exchange has an **initiator and a
recipient, both plain `Person`, neither special** — the same discipline that
makes `player.tscn` an inherited scene nothing downstream can distinguish from
an NPC.

**Shape: a broker node, on the model of `Population`.** `population.gd` earns
its existence by being a CALL SITE — *"everything later installs here and
nowhere else… The engine must never have called a Brain directly."* The broker
is the same shape for a different question: **who is talking to whom.**

**And it buys back a rule we had broken.** The first cut stored a `_held` array
on the Population — suspended state, the one thing this substrate refuses to
keep anywhere. Under a broker, **"held" stops being stored and becomes
derived**: a man is held *if and only if* he is in a live exchange. That is back
inside "store nothing you can work out again," and it means an exchange ending
cannot leave somebody frozen for ever through a missed release.

## W4 — The first exchange is goods/services, not pleasantries

Three types are envisioned: **information**, **goods/services** (work my field,
trade goods), and **pleasantries/threats**. The author's first instinct was
pleasantries.

**Switched to goods/services**, because the three produce different *shapes* of
result — information → something known; goods/services → an obligation or
errand; pleasantries → standing — and only goods/services lands on machinery
that already exists. Starting with pleasantries would mean the first thing built
does not exercise the result seam at all, and standing does not exist yet (it is
Gate 2 of the ladder).

**Not a judgement on pleasantries.** The author's correction stands and is
recorded: *"pleasantries help reinforce social bonds / reputation — don't sleep
on that."* Correct — reputation is the spine, not a garnish.

## W5 — The exchange result is an `Obligation`, and it moves `weight`

`obligation.gd` was already built for this and says so on the function in
question:

> *"When channels exist to set this dynamically — **a lord's writ**, a guild
> rate, a season's bargain — the BODY of the function below changes and no
> caller anywhere moves."*

So an exchange result is an `Obligation` installed at runtime by a different
hand. "Elevated value in the utility scoring" means **raising `weight`**, never
adding a bonus term beside the score: Decisions 19–27 are firm that every want
is a gap and that lenses touch weight and rate. A bolted-on additive score is
precisely what they exist to prevent, and it would be a second, quieter
override than W1 rather than the same one.

## W6 — The interrupt installs by overriding `Population.think_for_everyone`

> **SUPERSEDED IN PART BY W8 (2026-08-28), and left standing rather than
> rewritten.** Two sentences below are now false. **`game/` IS edited** — W8 made
> `Brain.run_upkeep` public and added `Person.run_upkeep`, because the fix could
> not be made from this folder without reaching through a private door. And the
> measurement "held he stays at 5.00" was real but was **proof of a bug**: it
> meant time stopped for a man in a conversation. He now accrues while held, at
> the same rate as a free man. Everything else here — the inherited seam, the
> serial loop, the derived hold — stands untouched.

No file in `game/` is edited. The seam is inherited, which is what
`population.gd`'s own header nominates it for. The serial loop is preserved —
skipping a man is safe; an `await`, a thread or a `call_deferred` here would
break the no-locking contention guarantee that loop is built on.

**Proven, not assumed** (`_seam_check.gd`, 2026-08-21): unheld he accrues
adenosine 0.00 → 5.00; held he stays at 5.00; the player beside him keeps
accruing; released he resumes 5.00 → 10.00. So it is an interrupt on one man,
not a pause on the world.

## W7 — The steered body moved onto the physics tick

From the earlier half of this workbench. `PlayerBrain` integrates position by
hand in WORLD HOURS and Decision 4 forbids `move_and_slide`; that trade
guarantees dragging `day_length_seconds` cannot change the player's speed
relative to NPCs. `exchange_brain.gd` takes the other side — real delta,
gravity, sprint, jump — and `person_with_exchange.gd` picks clips off physics
`velocity` rather than `_speed`, which is measured in `Person.think_and_act` and
is `0.0` whenever nothing ticks him.

**Before either moves back into `game/`,** answer what happens to **probe claim
66**, which pins player movement by driving real frame deltas through
`Clock.get_hours_elapsed` at two different day lengths. It measures exactly the
thing `_physics_process` stops doing.

## W8 — Upkeep was never part of the hold, and the seam check said otherwise

**Settled and FIXED 2026-08-28.** The only entry in this file that records a bug
rather than a call.

**What was wrong.** `exchange_population.gd` skipped a held man with a bare
`continue`. Upkeep is the tail of `Brain.think_and_act` and the movement
measurement is the tail of `Person.think_and_act`, so skipping the man skipped
both:

1. **Time stopped for him.** No hunger, no adenosine, no loneliness, for as long
   as the conversation lasted. A long enough exchange was a free night's rest
   nobody authored, and standing still listening was cheaper than sleeping.
2. **His clip froze.** `_speed` is only ever written by `_measure_how_he_moved`,
   so a man held mid-stride stood perfectly still playing a walk cycle.

W6 called this proven — *"held he stays at 5.00"* — and it was proven. It was the
wrong thing to prove.

**Why it is a bug and not the interrupt.** `Brain`'s own header says upkeep is
what happens to him **whether he decides it or not**, and `CLAUDE.md` is explicit
that putting upkeep anywhere else gives you *"a farmhand who works forever and
never sleeps."* The interrupt this workbench exists to test is on his
**deciding**. His body was never supposed to be in it.

**The fix, and it crosses this folder's own boundary deliberately.** The README
says nothing in `game/` is edited by anything here. This edits `game/`, because
the alternative was reaching through a private door from the workbench:

- `Brain._update_body` became **`Brain.run_upkeep`**, public. Same body, same
  call order, renamed because making it public is a real change in meaning — it
  is now the one door time comes through, for anybody held out of the loop for
  any reason.
- **`Person.run_upkeep(hours)`** is new: the body runs, the ballot never opens,
  and `_measure_how_he_moved` is handed a real `Vector3.ZERO` so he genuinely
  stops walking. It deliberately does NOT clear `current_action` — he is
  interrupted, not reset.
- `exchange_population.gd` calls it in the `is_held` branch.

**Evidence, both directions.** The probe is unmoved: **64 claims, 14898 checks,
cold start 21:14 / 05:52, settled 22:10 / 8.00 h / 06:10, strong man 04:47.** The
seam check now reads `HELD, his body still runs: 5.00 -> 10.00` and `at the same
rate: 5.00 free vs 5.00 held`. Reverting the one line turns exactly those two
claims red and nothing else. Watched, restored, green.

**The seam check had to be rewritten, and that is the lesson.** Adenosine can no
longer witness the hold, because it now rises in both states — that is the entire
point of the fix. The hold is witnessed by `current_action` surviving a tick
instead. **The first draft of that used `get_known_actions()[0]` as the sentinel
and failed**, correctly: an action he can legitimately CHOOSE makes "it still
holds the sentinel" ambiguous between *the ballot never ran* and *the ballot ran
and picked that one*. The sentinel is now an orphan `Action.new()`, in nobody's
repertoire, so surviving a tick means one thing only.

**Left open: what a held man LOOKS like.** He wears the clip of whatever he was
doing, so a man stopped on his way to bed looks like he is sleeping on his feet.
That belongs to whatever holds him — an exchange should say what he looks like —
not to the hold.

## W9 — Where an errand lands, and why the obvious answer is closed

**Argued 2026-08-28. NOT settled, and nothing is built.** It records the shape of
the problem so the next session does not rediscover it.

**The question the author asked:** an exchange succeeds — he agrees — but the
resulting errand is not the top bid. What remembers that he agreed, and how does
the errand ever get done?

**The memory is real and it already exists.** `obligation.gd` names itself
**STORED INTENT (FR101)**: *"no amount of looking at the world tells you who this
man agreed to work for, so it has to be remembered somewhere, and it is
remembered here."* An agreed-but-not-yet-acted errand is an `Obligation` node
under him, and `Person.get_obligations()` already walks for them. **This is the
one place the "store nothing you can work out again" rule has a standing
carve-out, and it was written for exactly this case.**

**WHAT IS CLOSED, AND IT CLOSES THE OBVIOUS ANSWER.** `WorkForHire` scores
`obligation.get_weight_at_scoring_time() + daylight_pull * sun` against a
**binary** gap — employed today or not (Decision 31, deliberately, because a gap
work closes continuously would fight itself all day).

**So work's want is flat all day and never gets quieter.** In an ordinary gap
system an errand wins by patience: work satisfies itself, its want falls, the
errand's does not, and the errand takes over on the merits. That road does not
exist here. An errand must beat `73 + daylight` **outright and permanently**, or
it never fires at all — which means hand-tuning every errand against work's
number for ever, and re-tuning all of them whenever a drive is added. **That is
the same thin-margins problem W1 already refused once, waiting at the result
instead of at the ask.**

**And W5 is only half a want.** W5 says the errand raises `weight`. But
`want = weight x gap^bite`, and an errand has no gap. Every gap in the game today
is physiological (hunger, adenosine, social) or stock (the larder). **None is
relational — none exists because somebody asked.**

**Four candidate landings, ranked.**

- **A — author the errand louder than work.** What W5 implies today. Fragile,
  degrades with every drive added. This is the trap, not the answer.
- **B — a tier above the score** (RimWorld's ThinkTree, where a player-forced job
  sits in a node above the work node and never has to out-score anything).
  Guaranteed landing, zero tuning. **Costs the single number line** — and with it
  the property that a refusal can name whatever beat you, since a tiered loss is
  not a score comparison and has no loser to point at.
- **C — the errand suppresses the other drives, through a `Condition`.**
  Decision 22 licenses the shape and Decision 36 now specifies it. Work stays on
  the ballot ("outbid, never barred"), the errand wins on the merits, and
  `stat_graph` shows work's line dip the moment the errand lands. Composes: two
  errands, two conditions. Degrades honestly — a man carrying five errands has
  everything else suppressed, which reads as *overloaded*, which is a real state.
- **D — the errand's gap grows toward a deadline.** `Obligation.expires_on_day`
  already exists as a field; today it is binary (expired or not). Turning
  days-remaining into a rising gap is new arithmetic in one existing function.
  An errand ignorable on Monday is undeniable by Friday.

**Recommended: C + D**, C as the mechanism and D as the pacing. **Costed
honestly: D is nearly free; C is a real build, because `Condition` does not
exist** — `lens` appears zero times in the codebase, and Decision 22 has never
been code. An earlier draft of this section claimed both were primitives already
in hand. That was wrong; it was one for two.

**Ordering: you need memory, you probably want order, you do not need a queue.**
Completion is derivable, the way `is_discharged()` is derived rather than
stamped. Order is worth having — *"I promised the miller before I promised the
baker"* is characterisation, not bookkeeping — but it wants **one field, when he
agreed**, with the order SORTED from it, exactly as `claimed_on_day` and
`received_on_day` already answer their questions at read time. RimWorld's
JobQueue stores position because it has no number to sort by at that layer. This
substrate does.

**And `Sequence` is not a port, it is an `ActionStep`.** The author's correction,
confirmed against git (`40c53e1`): the retired `Sequence` was
`class_name Sequence extends Step`, holding child steps and delegating to the
first unsatisfied one — and `Step`'s interface maps one-to-one onto today's
`ActionStep` (`is_satisfied` -> `is_done`). So "take this to the miller" (walk
there, hand over) is one subclass of about twenty-five lines. **The only
genuinely new content is that the old `Step` had no `clip` and no `exertion`: a
`Sequence` must forward both to whichever child is live, or a man plays one
animation through a walk AND a hand-over.**

## W10 — An exchange takes world hours, and one number owns both the hold and the animation

**Argued 2026-08-29. NOT built.** Read with **project Decision 39**, which
settles that the simulation never runs at coarse ticks — half of what is below
was worked out against the opposite assumption and is recorded as retired rather
than deleted.

### The question

Exchanges want **real timings for legibility** — you should see two people talk,
and see one of them think before answering. But an NPC's decision happens in a
single tick. So what is the two seconds of visible deliberation?

### It is a REVEAL, not a deliberation, and that is allowed

The answer exists before it is shown. Decision 18 already licenses this — *the
sim owns duration, the animation illustrates it* — and it is exactly how RimWorld
handles social interaction: an `InteractionWorker` resolves instantly, applies
its thoughts and opinion changes, and everything visible (the two colonists
standing together, the speech motes, the social log line) is presentation layered
on top. **Nobody is ever mid-conversation in RimWorld's simulation.**

**Do NOT copy the other half of RimWorld's model.** Its *work* has genuine
duration with stored progress — `JobDriver` holding `ticksLeftThisToil`, work-left
counters, a job queue. That is the thing this substrate refuses, and it is why
RimWorld's interruptions are expensive and this one's are free. Duration here is
expressed as **a world fact that changes** — position for a walk, accumulated
grain for work — never as a counter.

**THE ONE LINE A REVEAL MAY NOT CROSS: it must not be interactive.** The moment
the player can do something during the animation that changes the outcome, the
answer was not decided at the ask, and the exchange is no longer a single
resolvable event.

### `await` belongs to the animation, never to the decision

`population.gd` is emphatic: *"Put a `call_deferred` in here, or a thread, or an
`await`, and that stops being true — silently, and only under contention, which
is the hardest kind of bug this project could have."*

So the split is the one that already exists: **presentation may await, the tick
may not.** Clip choice already runs in `_process` rather than `think_and_act` for
this reason.

**And no awaiting `ActionStep` is needed** — the hold already IS the wait. A man
mid-reveal is a held man: skipped in the loop, ballot never opened, body still
running (W8). The broker owns the waiting. An awaiting step would put that same
wait back inside the tick loop, which is the one place it cannot go.

### The shape: duration in world hours, start as a STAMP

```gdscript
@export var takes_hours := 0.2   # authored, shared
var began_at_hour := 0.0         # Clock.hours_elapsed at begin()
```

**`began_at_hour` is a stamp, not a timer** — the identical pattern
`Workstation.claimed_on_day` and `Obligation.received_on_day` already use.
"Is it over?" is one comparison against `Clock.hours_elapsed` at read time.
Nothing counts down, nothing sweeps, and there is no progress to restore, so
`Exchange`'s standing claim that it *"holds no progress"* survives intact.

`Clock.hours_elapsed` is public and monotonic — *"World hours since this world
started running. The only stored fact here."*

### ONE NUMBER READ TWICE, NOT TWO NUMBERS KEPT EQUAL

The hold reads `takes_hours` to know when to end. **The animation is FIT to it** —
stretched or compressed to fill the budget — rather than carrying a duration of
its own that somebody keeps matched.

Two numbers is a desync waiting to happen: a clip is whatever length Mixamo
exported, so an animation-driven exchange varies in length by which clip plays,
and two separate fields eventually get edited one at a time. The failure reads as
a man held after he has visibly stopped talking, which presents as a physics bug
and traces back to presentation an hour later.

### What this buys

- **Deliberation stretches with `day_length_seconds`.** At 60 s/day, 0.2 world
  hours is half a real second; at 600 s/day it is five. So dragging the tuning
  slider to watch something makes the deliberation watchable too — the same
  reason Decision 13 reads the rung-3 Moment at a shortened day.
- **The cost is denominated in the one unit that survives everything.** 0.2 hours
  of a man's life, whether it is stepped while somebody watches or while nobody
  does.

### RETIRED — an hours-subtraction that solved a problem that does not exist

An earlier cut of this section required that a coarse-ticked region subtract
exchange hours from the tick (`think_and_act(hours - hours_spent_talking)`),
because a 0.2-hour conversation inside a 4-hour tick costs its participants **no
decisions at all** — they only got one ballot for the whole tick anyway. So
talking would be free wherever nobody was watching.

**Decision 39 removes the premise: there are no coarse ticks.** The hold spans
the same number of ticks everywhere, so the asymmetry never arises and the
subtraction is unnecessary. Recorded because the reasoning is correct *if the
tick size ever varies*, and this is the file that would be read before making it.

### Also retired: "resolvable in one call"

Same premise, same withdrawal — see Decision 39's own section on it. **A greeting
rung ladder where each exchange warms a man up is permitted**, as is any
multi-stage negotiation, and W1's eventual refusal model is not constrained by
it.

### The accumulator made this design better, 2026-08-30

Decision 39 landed a fixed-tick accumulator after this section was written, and
it improves the shape above rather than disturbing it: **an exchange of
`takes_hours` now spans the same number of ticks on every machine.** Before, a
0.2-hour conversation was thirty ticks at 60fps and twelve at 144, so the number
of decisions a held man lost to talking depended on his frame rate. Now it does
not, and "one number owns both the hold and the animation" is frame-rate
independent as well as fidelity independent.

One consequence worth knowing: `began_at_hour` is compared against a
`Clock.hours_elapsed` that now advances in whole quanta, so an exchange ends on a
tick boundary and may overrun `takes_hours` by up to one tick. That is
deterministic and identical everywhere, which is better than the alternative.

### What is still open

- **What `takes_hours` should be**, and whether it is one number for all
  exchanges or authored per kind. 0.2 is a placeholder chosen to make the maths
  in this section concrete.
- **Whether the hold should begin at the ask or at arrival.** Today `begin()`
  does both at once because the player is already standing there.
- **What a held man LOOKS like** — W8's open item. He currently wears the clip of
  whatever he was doing, so a man stopped on his way to bed looks asleep on his
  feet. A reveal with a real duration makes this more visible, not less.

## W11 — A greeting is a whole exchange: face, wave, end, nothing left behind

**Built 2026-08-30.** The first exchange you can actually WATCH. Deliberately
stops where it stops: two men turn to each other, both play the wave, the
exchange ends itself, and **no outcome is left on either of them.** Give and ask
exist and are authored "only once talking", so during the wave they are the only
other things on the table — and after it, nothing is. That is the point rather
than a gap: deeper actions past the greeting get written next, against a
greeting whose FEEL is already right.

**Facing is a third body layer, and it was not there.** `_body.rotation.y` is
written in exactly one place in each of `person.gd` and `person_with_exchange.gd`
— **inside the moving branch.** Heading has only ever been a consequence of
displacement, so nothing in this game could face anything while standing still.
`Exchange.face_each_other()` is the third writer, and it needs no arbitration:
"moving wins" already decides it, because a man who walks away has his own
`_show_the_body` overwrite this the same frame.

**One number owns the wave.** `ExchangeAction.takes_hours` (W10's shape),
stamped onto the Exchange as `began_at_hour` at `begin()`, asked at read time by
`has_lapsed`. **The arc's `gesture_seconds` was deleted, not kept in step** — a
real-seconds timer of 1.6 racing a world-hours exchange, which at 60 s/day beat
it by nearly a second, so the wave died while both men were still held.

**TWO BUGS THE SEAM CHECK CAUGHT, and both were invisible from the outside.**

1. **Neither man waved.** The greeter got his verb through
   `PlayerBrain.choose_verb`, which records a **bid** (Decision 33) — and a bid
   only becomes `current_action` when the ballot next runs, which for a man the
   broker has just held is never. Underneath it, the real fault was **two doors
   for one fact**: the greeter's performance came from the arc, the greeted
   man's from the broker. An exchange between two NPCs has no arc anywhere near
   it, so its initiator would have stood still. Both are now written in
   `offer()`, for both men, which is what W3 meant by neither participant being
   special.

2. **`stop_doing_anything` does not clear `current_action`.** It clears
   `_chosen`. Tearing down with it alone left the player waving for ever.

**AND THE CLAIM THAT SHOULD HAVE CAUGHT THE SECOND ONE HAD BEEN PASSING.** Until
the broker started performing for both men there was never anything in
`current_action` to fail to clear, so "both are handed back what they were doing"
was green while asserting nothing — the same species as this file's own W8, and
as the seam check that spent a week asserting a held man's adenosine stood still.
It only bit once the code around it got closer to right, which is the argument
for writing the claim before you believe it.

**Also vacuous until fixed:** "it took its length from the action" compared
`runs_for_hours` (default 1.0) against `takes_hours` (default 1.0) and could not
fail. `greet.tscn` now authors 0.8 so the comparison means something.

**Left open, on purpose.**
- **No outcome.** Nothing is written to either man. The next thing to build is
  what a greeting LEAVES — and the author's own instinct is the right one: a
  regard between two people, which would be the FIRST RELATIONAL NUMBER in the
  codebase (W9 records that every gap today is physiological or stock, and that
  the absence of a relational one is what blocks errands from ever winning).
- **The wave has one flavour.** Neutral only. `greet_warm` is imported and
  unused; picking between them off a regard stat is Decision 36's exact shape —
  intensity is a stat, the clip is the translation — and must be AUTHORED rungs,
  never a dictionary in code from a number to a clip name.
- **The staging axis may be wrong.** `offered` gates give and ask on a live
  conversation. If a greeting instead raises regard, they should gate on
  "have we greeted" — a fact about the relationship, which survives walking
  away, works NPC-to-NPC, and makes the greeting matter rather than be a
  doorway. Not decided.
- **WATCHED 2026-08-30, and it found something the claims could not.** Both men
  waved on the same frame — green everywhere, wrong on screen. See W11a. This is
  the standing argument for the Moment being a separate gate from the probe.


## W11a — An exchange has two sides, and they differ in what AND when

**Built 2026-08-30, straight off watching W11 run.** Both men waved on the same
frame with the same clip, which does not read as a greeting — it reads as two
strangers doing the same thing at the same time by coincidence.

**The fix is a slot, not a stagger,** and the reason to spend a slot on it is
that **THIS IS WHERE REFUSAL LIVES.** W1 and W2 leave "what does a no look like"
unanswered, and the honest answer is that it looks like a different reply — a
`shake_head` where a `greet_warm` would have gone. Staggering the same clip
would have to be rebuilt the day refusal lands; a slot does not. It is also what
`mixamo_import.gd` imported seven clips for in the first place: *"the vocabulary
of an ASK and an ANSWER — assent, refusal, and the gestures that point one
person at another."*

- `ExchangeAction.answered_with` — a PackedScene, an Action with its own step, so
  the reply's clip comes off a step like every other clip in the game and no file
  maps a verb to an animation. `greet_answer.tscn` needs **no script of its own**
  (`game/action.gd` + `game/action_step.gd`), which is the same genericity test
  `ask.tscn` passes.
- `ExchangeAction.answers_after` — the beat, in world hours. The broker warns
  if it is not shorter than `takes_hours`, because otherwise nobody ever replies
  and there is nothing to see that says why.
- **Instanced under the Exchange, never learned.** Nobody CHOOSES to answer. An
  answer on a man's ballot is a verb he could aim at somebody who never spoke to
  him.

**It closes W8's open item as a side effect.** Until the beat the answerer is
CLEARED, not left wearing the clip he was stopped in — so a man stopped on his
way to bed stands and listens instead of sleeping on his feet. A man listening
is a man who has stopped.

**A recursion this nearly shipped.** `end()` is called from inside
`get_exchange_for`'s sweep, so a teardown that looked the exchange up again
re-entered the sweep, found the same lapsed exchange, and called `end()` for
ever. The exchange is passed in.

**And a second vacuous claim, caught the same way as W11's.** "after the beat he
answers" first asserted only that a reply node existed — which `begin_answering`
creates whether or not anybody is handed it — so cutting the man out of his own
reply left it green. It now asserts he is DOING it. Five of the six new claims
went red on a deliberate break the first time; this one did not, and that is the
only reason it was found.

**Standing count: 35 claims, all green.**

**Still open:** one flavour each way (`greet_warm` is the only reply authored, and
nothing yet CHOOSES between replies — that choosing is refusal), and the greeter
holds his last pose for the rest of the exchange because the clip is `LOOP_NONE`.


## W11b — A gesture's length is REAL SECONDS, and W10's unit is retired

**Author's call, 2026-08-30, straight off watching W11a.** The beat was too
short, and chasing why found the real fault underneath it.

**W10 authored an exchange's length in WORLD HOURS**, on the standing rule that
every rate in `game/` is per world hour and real time is converted once, up in
`Clock`, and never seen again below it. **That rule is right and this was never
one of its cases.** `day_length_seconds` is a TUNING SLIDER: at the shipped
60 s/day one world hour is 2.5 real seconds; at a plausible play speed of
600 s/day it is twenty-five. So a greeting authored at 0.8 hours is a two-second
wave while you are debugging and a twenty-second wave when you are playing —
**off one number nobody edited.** W10 listed that stretching as a BENEFIT
("dragging the tuning slider to watch something makes the deliberation watchable
too"). It is a benefit for a *deliberation whose cost is a slice of a life*. It
is a bug for *a hand going up*.

**The distinction, which W10 collapsed into one number:**

| | unit | why |
|---|---|---|
| how long you WATCH it | real seconds | a fact about the gesture. A greeting takes as long as it takes to raise a hand, and that does not change because the sun sped up. |
| what it COSTS him | world hours | a fact about the simulation. Same slice of a life whether anybody is watching. |

**Today an exchange has only the first, because a greeting COSTS NOTHING** — no
outcome, no stat, nothing left behind. The day an exchange has a real price, the
price is **its own number in world hours** and `takes_seconds` stays what it is.
W10's "one number owns both the hold and the animation" survives intact; only
its UNIT is retired.

**This is not a violation of "nothing outside Clock interprets a real delta" —
it is the other half of a split the project already makes.** Clip choice already
runs in `_process` rather than `think_and_act`, because presentation answers to
how often it is LOOKED AT. An exchange's visible length is on that side of the
line. `ExchangeBroker.seconds_running` is the frame clock's twin of
`Clock.hours_elapsed`: one monotonic number, converted once in one file, never
interpreted again below it — and it advances only while the node processes, so a
paused game does not run a wave on without you (which is why it is not
`Time.get_ticks_msec()`).

**What moved.** `takes_hours` -> `takes_seconds` (4.5), `answers_after` ->
`answers_after_seconds` (1.6, the longer beat the author asked for). The broker
no longer holds a `Clock` at all and the wire is gone from `exchanges.tscn`.

**Standing count: 36 claims, all green,** and the one that pins this decision is
new: *a whole day of world time passes and the wave is unmoved (0 h -> 24 h).*
**The first break written for it was vacuous** — it stopped the exchange expiring
at all, which passes for the wrong reason. The break that means something puts
the length back on the sun (`is_over(clock.hours_elapsed)`), and that one goes
red. Worth knowing: for a claim of the form *X does not depend on Y*, the only
honest break is **making it depend on Y**, never disabling X.


## W12 — Regard: the first relational number, and what gates a gift

**Built 2026-08-30.** Give works. What made it possible is not give.

**The blocker.** Give and ask were authored `offered = "only once talking"`, which
was fine while an exchange stood open indefinitely and stopped working the moment
W11 made a greeting a thing that ENDS: they flashed for four and a half seconds
and vanished. **The gate had to move off "is a conversation live right now" and
onto "have we met."**

**And that is the greeting's missing outcome**, so the two problems answer each
other. A greeting now leaves a record, and the record is what a gift needs.

**`acquaintance.gd` — a node under the person doing the thinking, naming the
person thought about.** Exactly `Obligation`'s shape, under exactly its carve-out
(FR101 stored intent): nothing about where a man stands, what he carries, or what
the town has done says whether he has met you.

- **ONE NODE PER SIDE, NOT ONE PER PAIR, and that is the whole design.** Two
  people do not have to agree about each other. A shared edge would make regard
  symmetric by construction and quietly delete *illegible authorship* pointed at
  one other person.
- **Not a central graph**, for the reason `Town.find_people_at` loops people
  rather than Places keeping occupancy lists: one copy of the truth cannot
  contradict another. The graph is DERIVED by walking people.
- **`have_met` is held apart from `warmth`.** A stranger has no node and reads
  0.0; a man who has been greeted and thinks nothing much of you also reads 0.0.
  Those are different facts and one number cannot carry both, so there are two
  gates (`needs_to_have_met`, `needs_regard_above`) and 0 never means both.
- **A change of ZERO still makes the record.** Meeting somebody is a fact even
  when it leaves you cold.

**THIS IS THE FIRST RELATIONAL NUMBER IN THE CODEBASE.** W9 names the absence as
the thing blocking an errand from ever winning a ballot on its merits — *"every
gap today is physiological or stock; none is relational, none exists because
somebody asked."* **It does not solve W9 and nothing scores on warmth yet.** What
changed is that the number an eventual relational gap would be measured against
now exists.

**Two regard numbers per exchange, not one**, named for whose book the change is
written in. **An exchange is not symmetric:** a greeting is (both men now know
each other, +8/+8), a gift emphatically is not (+2 to the giver, +15 to the
receiver). One shared number would make every exchange in the game reciprocal by
construction.

**Give itself is small, because the substrate was already there.** The transfer is
`Inventory.hand_over` — the ONE transfer path — called from `settle()`, never from
the step: the step is what the giver's body looks like, and a transfer in a step
runs every tick he wears the clip, which is a man emptying his pockets for as long
as he holds a wave. A failed transfer returns before `super()`, so **no bread means
no gratitude either**.

**Standing count: 48 claims, all green.** Seven new ones, each watched go red, and
two of them are worth keeping for how cleanly they separate:

- transfer that MOVES NOTHING -> only "the loaf changed hands" fails (9 -> 9)
- transfer that CREATES instead of moving -> only conservation fails (9 -> 10)

That is the whole argument for `add` creates / `take` destroys / `hand_over` moves
being three doors instead of one, restated as a measurement.

**AND THE OPEN EDITOR ATE A SCENE BLOCK AGAIN.** The player's six loaves,
hand-written into `exchanges.tscn`, were silently gone — the trap already recorded
at the end of this file, second occurrence this session. The check now **stocks the
inventory it is about to measure** rather than reading it off the scene, because a
conservation claim that quietly measures 0 -> 0 and calls itself satisfied is worse
than no claim.

**Still open:** ask is authored and gated the same way but its outcome
(`work_the_ground`) runs straight into W9 — a flat score with no gap, which is
W9's Option A, the trap. And nothing yet reads `warmth` for anything: the obvious
first reader is the greeting's own reply, picking `greet_warm` over `greet` above
some threshold, which is Decision 36's shape exactly (intensity is a stat, the
clip is the translation).

## W12a — A reveal offers nothing, and `offered` is deleted

**Author's observation, 2026-08-30, from watching it:** *"ask is already shown as
an option while the greeting is still taking place and not after?"*

Half of that was a stale build — ask was still authored `offered = "only once
talking"`, which W12 had just replaced. But the other half is real and survives
the fix: **verbs were on the arc while the wave was still playing.**

**W10 draws one hard line under the reveal** and this crosses it:

> *"THE ONE LINE A REVEAL MAY NOT CROSS: it must not be interactive. The moment
> the player can do something during the animation that changes the outcome, the
> answer was not decided at the ask."*

`settle()` runs at the ask, so regard lands the instant you press E — by design,
and W10's whole reveal argument depends on it. What must not follow is an arc
full of pressable rows over a man mid-wave.

**So nothing is offered at all while an exchange stands**, asked of the broker
rather than worked out in the UI, so `offer()` and the arc give one answer to one
question. **`offer()` no longer reuses a standing exchange either** — one exchange
is one action, opened and run to its end.

**AND THAT DELETES `offered`.** Its three cases collapse: with nothing offerable
during an exchange, "only to open" and "either" say the same thing, and "only once
talking" is unreachable. It died twice — first when W11 made a greeting a thing
that ENDS, then this. `is_available_toward` lost its `exchange` argument with it,
which had become a parameter that could only ever be null.

**When a conversation can PERSIST** rather than always running its course, the
distinction that matters will be *mid-reveal* (nothing offered) versus *standing,
awaiting your move* (verbs offered). That is not what the enum said, so it is
deleted rather than kept warm for a case it does not fit.

**Standing count: 56 claims, all green.** Four rounds of breaking were needed to
get there, and three of the failures are the interesting part:

- **`greet.gd`'s call to the base gate was unassertable.** It overrides
  `is_available_toward`, which replaces the base entirely — so that one line is
  all that stands between "a greeting requires nothing" and "a greeting ignores
  whatever it is authored to require". Greeting authors no requirement, so nothing
  in normal play could witness it. This is CLAUDE.md's standing trap verbatim: *a
  claim about a rule with no branch must be asserted in the state the missing
  branch would have changed.* The check now puts the requirement on, asserts the
  refusal, and takes it straight back off.
- **Half of `_both_are_free_to_talk` was unassertable too**, for a different
  reason: every existing state had BOTH men in the same exchange, where the
  actor's half alone passes it. Witnessing the target's half needed a state the
  workbench had never produced — the player free and the man he is looking at busy
  with somebody else. **Which made it the first NPC-to-NPC exchange in this
  folder**, and W3 says that is most of what exchanges are for.
- **The broker's refusal needed its own claim.** An arc that declines to draw a
  row while `offer()` would still have honoured it is two answers to one question,
  and the day something other than the arc calls the broker it gets the other one.

**Third time the open editor ate the player's six loaves out of
`exchanges.tscn`.** See the traps below. It is now a standing cost of leaving the
4.4 editor open on this project while hand-editing scenes.

## W13 — Beckon and follow, and the other book

**Built 2026-08-30.** The first outcome you can watch from across a field: you
call a man and he walks over.

**ONE ACTION, AUTHORED TWICE.** `come_along.gd` is what both verbs land, and the
only difference is `stays_with_him` — "come here" and "stay with me" are the same
behaviour with different stopping conditions, so they are one file authored twice
rather than two files kept in step.

**THE SUMMONER IS BOTH THE STORED INTENT AND THE DISCHARGE.** `summoner` holds
who called (the FR101 carve-out again — nothing in the world tells you). When a
beckon is answered, **the field is CLEARED rather than a separate `done` flag
being set**: the gate is "is somebody calling me", so forgetting who called is
exactly what finished means. One field, one job, nothing to keep in step. A
follow never clears it, and that is the whole of the difference.

**A `game/` EDIT, AND IT IS THE SECOND ONE THIS WORKBENCH HAS MADE** (W8 was the
first). `GoToStep.walk_toward` takes a `Place`, snaps onto it, and writes
`current_place` — none of which is right for walking to a man. Rather than copy
the hand integration (that file calls itself *"the only thing in the game that
moves a body"*, and a second copy makes that false), **`walk_toward_point` was
split out**: the movement with no opinion about why, with the place bookkeeping
left in the caller that has a place. `walk_toward` is now that plus two lines and
behaves identically.

**HE STOPS BESIDE THE MAN, AND THAT IS NOT A RADIUS.** The target is a point
`closes_to` short of the summoner, and the inherited overshoot clamp lands him
exactly on it. Decision 10 forbids arrival BY THRESHOLD — which flickers at its
own edge and lands differently at different tick rates — and asking for a point
that is short of something keeps the clamp doing the work instead. Measured: he
stops at **1.80 m**, every time.

**`pull = 100` IS A DESIGN STATEMENT, NOT A FUDGE**, and it is chosen against two
specific numbers. StayUp peaks at 87.3 at noon, so **a summons outranks going
about your day at any hour** — being called is not a thing you get round to. Eat
reaches 130 at real hunger and Sleep climbs past this on real exhaustion, so a
starving or spent man still refuses, and refuses **by being outbid rather than by
being barred**. Asserted at noon, StayUp at its loudest, and he still comes.

### `needs_their_regard_above` — the first gate that reads the other book

W12 built one Acquaintance node per SIDE and argued it on principle. **Follow is
where that pays.** "Will he follow me around" does not turn on what I think of
him at all — it turns on what HE thinks of ME, and a single shared number could
not tell those apart.

The claim is built so it cannot pass by luck: at that point he regards the player
at **23** (greeted 8, given 15) and the player regards him at **10**, against
follow's threshold of 20. **Reading the wrong book would shut the gate**, so
passing means it read the right one.

**Standing count: 73 claims, all green.**

**Also landed: the trap now reports itself.** The player's six loaves have been
overwritten out of `exchanges.tscn` by the open editor FIVE times, and give
silently never appeared — every other claim in the file stocks what it measures,
so none of them could see it. There is now one claim that deliberately does not:
*"the scene authors the player something to give (N items) — if this is red, the
editor ate it again."* It caught it on the first run at 0 items.

## W14 — The arc aims at THINGS too, and goods come from somewhere

**Built 2026-08-30**, from the author's call: *"you will have to create a bread
basket… because inserting directly into his inventory to start the scene isn't
working at all.. so let's solve it the right way."*

**THE WORKAROUND AND THE RIGHT ANSWER TURNED OUT TO BE THE SAME THING.** Six
loaves authored onto the player in `exchanges.tscn` were overwritten out of the
file **five times** by an open editor re-saving from its own stale copy; give was
gated shut, drew nothing, and said nothing. But a player who starts holding bread
because a scene file says so **cannot answer where it came from**, and the moment
anything else wants to hand out goods — a barn, a stall, a body — it needs its
own answer. A basket is that answer, it is reusable, and its loaves live in its
OWN scene file, which is not the one the editor is holding open.

### `aimed_action.gd` — the split the basket forced

The arc only drew over `Person`, because every verb was an `ExchangeAction` and
an exchange is between two people (W3: both parties plain, neither special, the
broker holds and runs upkeep for both). **You do not have a conversation with a
basket.** But you do look at one, and the arc's job is *"what can I do to the
thing I am looking at"*.

So the aimed half is now its own base — what the arc draws, how far it reaches,
and `perform()`, the one door pressing it comes through. `ExchangeAction` is that
plus the between-two-people half. **The arc reaches a verb only through
`perform()`** and does not know which kind it just fired: an exchange's perform
opens a conversation at the broker, a take's moves goods, and neither is a branch
in the UI. Adding a verb aimed at a door, a cart or a barrel is now a scene.

**`take_from.gd` asks the THING, not a list of things.** Anything answering
`get_inventory()` can be taken from — the same duck-typed reach `Person`, `Place`
and `Workstation` already share by all answering it. No file names a basket.

### Reach bands — the author's second call

> *"for beckon and greet to feel right, the distance can and should be longer to
> greet and then beckon is only for longer distances"*

`reaches_within` / `reaches_beyond`, **per action**, because one number on the arc
can only say how far you can address somebody at all — it cannot say that this
verb belongs near and that one belongs far. `LookingAt.within_reach` went to 30 m
and now only decides what you can point at; the verbs decide what survives at
that range:

| | band |
|---|---|
| take a loaf | ≤ 2.6 m |
| give | ≤ 2.8 m |
| ask | ≤ 4.0 m |
| greet, follow | ≤ 14 m |
| **beckon** | **6 m – 30 m** |

**Beckon authors a MINIMUM**, which is the whole point of it: beckoning a man
standing beside you is nonsense, so it simply is not offered up close.

### `offered` is gone for good

W12a killed its last case. The reach band and `needs_to_have_met` between them do
everything it was reaching for, and they do it as two numbers rather than an enum.

**Standing count: 92 claims, all green.**

**Three break-pass findings worth keeping:**

- **A claim that asked the arc directly could not see LookingAt at all.** "Taking
  is on the arc" passed `basket` straight in, so removing things from the search
  entirely left it green. The eye is now aimed at the basket and the real search
  is run, which catches it.
- **"You do not greet a basket" was DOUBLE-GUARDED and unbreakable.** `greet.gd`
  overrides `is_available_toward` and casts for itself, and the base casts too —
  so no single break could show it, and breaking both errored rather than failing.
  The claim was moved onto **give**, which does not override, so the base's guard
  is the only thing standing there and breaking it turns the claim red on its own.
  *Defence in depth makes a claim harder to write, not easier.*
- The two transfer breaks separate as cleanly as W12's: moving nothing fails only
  "into his hands" (24 → 24), creating instead of moving fails only conservation
  (24 → 25).

---

## Two engineering traps found the hard way

Neither is a design call; both cost real time today and both will recur.

**A headless `--editor --quit` re-saves open scenes and silently drops any
property whose stored value no longer matches its export type.** Changing an
export from `NodePath` to `Camera3D`, then running the import pass, **deleted
six wires out of `exchanges.tscn` with no error of any kind.** It presents
exactly as "the `node_paths` mechanism doesn't work," which sent two debugging
passes in the wrong direction. Same mechanism as the warning already in the
Gate 1 findings about an editor being open on the project.

**Probe claim 4 has a blind spot.** It catches a bare `NodePath` assignment
*missing* from `node_paths` — the documented gotcha — but not the inverse, a
`NodePath`-typed property that *is* listed in `node_paths`. Same silent null,
same broken wire, and claim 4 stayed green throughout. Worth closing in the real
probe whether or not any of this workbench survives.

**AND IT HAS A FALSE POSITIVE, WHICH IS WORSE — 2026-08-30.** Claim 4 is RED
today, on `person_with_exchange.tscn`'s `steered_by_camera`, reporting *"is a
bare NodePath but is not in node_paths — it loads as null"*. **It does not load
as null.** Measured decisively: the .tscn was given
`NodePath("../DecisiveTestValue")` — deliberately different from the script's
default, so a dropped value could not hide behind it — and the instantiated Brain
read it back intact and non-empty.

`node_paths` exists for properties typed as a NODE, where the loader must turn a
path into an object. A property typed `NodePath` stores a NodePath and is
resolved by the script at runtime (`get_node_or_null`), which is the whole point
of that type. **Claim 4 flags any `NodePath(...)` assignment missing from
`node_paths`, and that is only a bug for the Node-typed case.**

**THE EXPENSIVE PART IS WHAT THE FALSE POSITIVE TAUGHT THE CODEBASE.** On
2026-08-21 somebody saw claim 4 go red, believed it, and wrote the conclusion
into `exchange_brain.gd` as a fact — *"a BARE NodePath export needs node_paths on
the .tscn node header too"* — explicitly overruling an earlier correct note. So a
wrong claim did not merely fail; **it propagated into a source comment as
documented knowledge, where the next person would have believed it too.** This
project has a standing discipline for claims that pass while asserting nothing.
This is the other species: a claim that FAILS for the wrong reason, and is
believed. The comment is corrected; **claim 4 itself is left for the author,
because it is the project's standing green and not a workbench call.**

**It is also PRE-EXISTING, not a workbench regression** — the offending line is
committed at HEAD, so the probe's recorded "65 claims, all green" and this red
cannot both be current.

---

## When we fold this back

Walk W1–W14 in order and rule on each. **W8 is already fixed and needs no ruling** — it was a bug, the fix is in `game/`, and the probe is unmoved at 64 claims / 14898 checks. W1 is the only one that genuinely
contradicts a stated design bet, so it is the one that has to be argued rather
than merged — and if it survives, the boss plan's "nobody has to build refusal"
paragraph needs rewriting, not just supplementing.
