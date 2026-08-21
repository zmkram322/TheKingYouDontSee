# The Boss Scene — build plan

*Written 2026-08-19. **This supersedes `proving-scene-build-plan.md` as the
forward ladder.** That document is not retired: rungs 0–6 shipped, every seam it
installed survives untouched, and its rungs 7–9 are re-seated at the back of
this ladder rather than deleted. Read it for why the substrate is shaped the way
it is. Read this for what gets built next.*

---

## What changed

The seat. Not the town, not the substrate, not one line of `game/`.

The old ladder watched a farmer decide to work a field. This one puts you in the
town and lets you **tell him to** — and lets him say no.

The author's framing, verbatim:

> *"The thing that's fun is being the boss. When you're the boss you tell people
> what to do. And if they don't work for you, they don't have to listen."*

That second sentence is the whole design. A command that always lands is a
button. A command that can be refused is a relationship you had to build, and
the building is the game.

## Why this is cheap

Three things were already true before the reframe, and none of them were built
for it.

**1. The command object exists.** `Obligation` is stored intent hung under a
person — *"Zoogs owes the grain fields twelve grain a day."* It is authored by
hand in `game.tscn` today. **The player installing one at runtime is the
identical operation performed by a different hand.**

**2. The weight seam was cut and named for this.** `obligation.gd`, verbatim:

> *"When channels exist to set this dynamically — **a lord's writ**, a guild
> rate, a season's bargain — the BODY of the function below changes and no
> caller anywhere moves."*

**3. Refusal is already the mechanism.** `WorkForHire` scores 73 + daylight and
competes on one ballot against sleep, hunger and loneliness. A command is not an
override; **it is a bid.** Tell an exhausted man to work and he goes to bed, and
the decision graph already draws you exactly why. Nobody has to build refusal.
Somebody has to author the bid.

## The two realisations this plan rests on

### The verb menu is the ballot, drawn instead of scored

`DecisionEngine` keeps its two halves strictly apart, and says why:

> *"Two halves kept strictly apart: `get_available` never scores,
> `get_highest_scoring` never gates."*

That split was justified as debuggability. It is also, unmodified, **the
player's contextual verb list.** `get_available(player, known_actions)` returns
what this body may do right now — Give when someone is in reach, Work when he is
standing at a plot, Beckon when a man is in sight. The player build is: run the
first half, draw it, and let input pick where `get_highest_scoring` would have.

**Consequence, and it is binding: no menu code names a verb.** A verb appears
because an `Action`'s own `is_available_to` said yes about the player's body.
Authoring a new player verb is dropping an Action scene under the player's
Brain — the same sentence as teaching an NPC something, because it is the same
operation.

### Refusal speaks, and the excuse comes from what beat you

> *"When you ask the person that's too tired they can say they are too tired."*
> — the author, 2026-08-19

When your command loses the ballot, the man says so — and **the line is authored
on the drive that beat it, never on the command.** Sleep says *"I'm dead on my
feet."* Eat says *"Let me eat first."* Socialise says *"I'm for the tavern."*

One exported string per Action, read off the winner. Which means:

- Every refusal is automatically truthful — it names the thing that actually
  outbid you, because that is where the string lives.
- A new drive arrives with its own excuse and every command ever written
  inherits it, the same way every action inherits a new line of upkeep.
- **The utility model becomes diegetic.** The graph turns into a sentence, which
  is the PRD's no-floating-bars pillar arriving for free rather than as an art
  budget.

A refusal with no reason is a rejection. A refusal with a reason is an
instruction: feed him, let him sleep, come back at dawn. **The excuse is what
converts a no into the next move**, and that is the difference between a wall
and a game.

---

## What each gate carries

Unchanged from the old plan, and non-negotiable.

| | |
|---|---|
| **Seam** | the one narrow waist this gate exists to install |
| **Files** | what gets created or touched |
| **Probe** | the assertion that pins it, added to the standing harness |
| **Moment** | what you should be able to sit and *watch* when it works |

**The Probe + Moment pair is the review gate**, and the Moment half is the one
that has been quietly dropping out. Rung 5's moment was never watched. Rung 6
shipped four gates and produced a headless six-day pump instead of a chair —
and the thing that got through was a man **pacing a field for six days while a
counter reported nineteen hours of work.** Ten seconds of watching catches that.
Three days of numbers did not.

**New rule for this ladder: a gate is not closed until a paragraph of what you
SAW is written above the probe output.** Not instead of it. Above it.

---

## The ladder

Ordering principle throughout: **watch a thing fail before building the thing
that fixes it**, so nothing is built against a guess.

### Gate 0 — Stop the pacing

> **✅ LANDED 2026-08-20.** `07a1400`, `ef04050`, `e756795`, `1575b3a`, `d11fe8c`
> on `poc-v2`. Probe 50/50 → **55/55**, 14823 checks. Findings:
> **`gate-0-findings-2026-08-20.md`**. The Moment was watched: the loser of the
> dawn race now reads the register and never sets off.
>
> **The hold below was not honoured, and it should have been.** The session
> worked from `rung-6-repair-session-prompt.md`, whose Step 0 makes the sizing a
> required author call, and did not open this file. So `share_of_crop = 0.35`,
> `base_grain_per_hour = 2.5` and `larder_target = 6` are authored and shipped.
> **Gate 8 still owns those numbers** — treat them as measured placeholders. The
> wage MECHANISM was required either way (Decision 29), and the arithmetic bought
> the twelve-day measurement that proved the loop closes, so nothing is wasted;
> but whether the three numbers stand or revert is an open call, recorded in the
> findings file, Part 0.

**Seam:** none new. A deletion.

Already written and settled — build `rung-6-repair-session-prompt.md` against
Decisions 29–32. Do it first regardless of frame: the instrument is currently
lying, and no gate below can be judged through it.

**Moment:** a man who loses the dawn race walks away and *stays* away.

> **HOLD THE SHARE-SIZING HALF.** Decisions 29/31 size how much grain a worker
> keeps. Under this ladder that quantity is a **wage**, and Gate 8 authors it
> properly. Landing the dither fix (Decision 30, a pure deletion) is required;
> authoring share numbers that Gate 8 deletes is not. Build the deletion, defer
> the arithmetic.

### Gate 1 — A body you steer, and a verb list that changes under your feet

> **⚠ THE MOMENT BELOW IS SUPERSEDED BY DECISION 35 (2026-08-20).** "Work when
> you reach the plot" describes a game that stopped existing at Decision 30:
> freeness became a public register, and with it **the last positional term went
> out of the last gate in the project.** No verb anywhere can be revealed by
> arriving somewhere. The seam, the files and every probe claim but one are
> unaffected; only this paragraph and claim 4's "at a plot" were wrong. Read
> Decision 35 for the re-cut Moment — the list changes because of what you
> CARRY, and it is a better beat.

**Seam:** where a Person's decision comes from — input picking off
`get_available()`, instead of `get_highest_scoring()` picking for him.

**Moment:** ~~you walk from the town square to the fields on your own legs, and
the verb list changes as you go — empty in the road, Work when you reach the
plot.~~ You walk from the town square to the unclaimed common field on your own
legs and choose Work. Grain climbs in *your* sack — and at three grain **a verb
you have never seen appears on your list**, because you can now bake. Nobody in
town cares that you exist.

Cut in full below, and **handed off in `gate-1-session-prompt.md`** — build from
that file, not from this summary.

### Gate 2 — Greet, across a square

**Seam:** a person notices you at range and responds visibly, by stance and
facing, according to what he already thinks of you. **The first social edge** —
authored per instance, moved by nothing yet.

**Moment:** you greet two men from across the square. One turns toward you. One
looks away and carries on. Nothing differs about them except an authored number.

Standing is authored before anything moves it, exactly the way Hobb's strength
was authored at rung 3 before a single system modified it.

### Gate 3 — Beckon

**Seam:** a command whose target is **you** — and travel to a target that moves.

**Moment:** you beckon across the square. One man stops what he is doing and
crosses to you. The other glances up, **says "I'm dead on my feet,"** and goes
back to it.

This is the bet. The smallest possible command, the most legible possible
compliance, and the refusal speaks. If this does not feel like anything, nothing
below saves it — and you know inside three gates.

### Gate 4 — Give

**Seam:** a player→person transfer that moves standing. `Inventory.hand_over`
already exists and is already the one transfer path in the game.

**Moment:** the man who refused your beckon takes your bread. The next time you
beckon, he crosses the square.

### Gate 5 — Follow

**Seam:** a **standing** command rather than a one-shot — it persists until
revoked, and it is re-bid every tick against everything he wants.

**Moment:** a man follows you across town. Then he peels off to the tavern,
because he got hungry enough that your standing order lost the ballot. **He was
never obeying; he was choosing, every tick, and now he chose differently.**

### Gate 6 — The writ

**Seam:** an `Obligation` naming a place and a job, installed at runtime.

**Moment:** you tell a man to work the unclaimed field, and he goes and does the
thing you did yourself at Gate 1. A tired man says he is tired and goes to bed.

**This is where the authored obligations come OUT of `game.tscn`.** The town
starts unemployed, the field starts unclaimed, and nothing in it works unless
you say so.

### Gate 7 — Bring it to me

**Seam:** an obligation discharged to a **person** rather than a place
(`Obligation.place_name` grows a sibling).

**Moment:** he works your field, walks to wherever you are standing, and your
sack fills with grain he grew.

### Gate 8 — Coin, and a day's wage

**Seam:** money as a conserved flow (T6 — coin circulates, never trickles).
Paying **maintains** standing where a gift **raised** it.

**Moment:** a man works your field all day, you pay him at dusk, and he walks to
the tavern and spends it. The author's sentence, closed.

### Gate 9 — What it costs to be a bad boss

**Seam:** revocation and neglect have a price on standing.

**Moment:** yank a man off the field three times, or leave him working hungry and
unpaid, and he refuses you outright — and now you have to win him back.

Last of the core, because every way of being a good boss must exist before
failing to do them can mean anything.

### Gate 10+ — The chain

The old rungs 7–9 re-seated: a second trade, the miller, the smith, the wagon,
the market square.

**And the old ending inverts.** The merchant assembles scythes and they sit
unsold because no farmer knows the verb *"buy a scythe."* **You know it.** The
dead end becomes a player move — and it lands directly on the question the old
plan explicitly refused to answer:

> *Whether the **farmer** or the **farm owner** buys the first scythe. Same
> object, same productivity number, opposite meaning: one buys a man his evening
> back, the other raises the quota and buys extraction. The second is the first
> genuinely political act in the town.*

Under this ladder that is your call to make, with your coin, and it is the last
gate on it.

---

## Two consequences to decide on rather than discover

**The unemployed town gets hungry.** After Gate 6 nobody works unless you say
so, the fourteen authored loaves run out, and everyone climbs toward pinned
hunger. That is not the day-eight bug — it is **pressure, and it is the reason
to be the boss.** Starving proper is not built (Decision 27), so it cannot kill
anyone. Watch it deliberately; do not patch it.

**The player has a body, so the player has drives.** He tires, he hungers, he
gets lonely, because he is a `Person` and upkeep runs in `Brain._update_body`
for everybody. Nothing forces you to answer any of it yet. Whether the player's
own hunger ever becomes a constraint is left open here.

---

## What this ladder deliberately does not answer

- Whether standing is one number or several (the PRD's reach vector:
  `{coercive, economic, authority, loyalty, informational}`). **One number until
  a gate cannot be built without a second.**
- Whether a command can be refused *silently* — a man who lies about why.
  Deception is a later system; like/dislike plus candor is enough interior state
  for this whole ladder.
- Whether the player is seen by the town as an actor with standing of his own,
  or only as a source of commands.
- Anything about a second town, the hex board, or reach beyond walking distance.
- The 300-actor performance probe, still owed against the ≥60fps-at-150 NFR.

---

## The discipline, unchanged

- **One gate per session.** A gate that lands two seams has destroyed the
  evidence that either was needed.
- **The probe is written in the same session as the code.**
- **Every probe claim must be watched failing.** Break it deliberately, see it go
  red, put it back. Eight vacuous assertions have been caught this way.
- **Re-derive every snippet; paste none.** Code in this file and in the decisions
  file is illustrative and has drifted from `game/` more than once.
- **No new substrate.** If something seems to need a scheduler, a knowledge
  store, or a menu framework, it is out of scope — say so and stop.
- **No code names a playstyle**, and now also: **no code names a verb.** A menu
  that has `if verb == "beckon"` in it has already failed.

---

# Gate 1, cut in full

*Gate 0 is `rung-6-repair-session-prompt.md`, already written. This is the first
gate of the new ladder.*

## Seam

**Where a Person's decision comes from.**

Every body in this game runs `Brain.think_and_act(hours)`, which calls
`DecisionEngine.choose()`, which runs `get_available()` and then
`get_highest_scoring()`. This gate installs a second answer to the second half
only: **for one body, the pick comes from input.** The gating half is untouched
and shared, which is the entire point — the player is subject to every gate an
author ever wrote, exactly like everyone else.

**What this seam is NOT.** It is not a menu system, not an input manager, not a
UI framework, and not a player class. It is a fork in one function, plus a list
drawn on screen.

## Files

- `game/person.tscn` / a new `game/player.tscn` — **an inherited scene**, not a
  new class. Godot's inherited scenes exist for exactly this: the player is a
  Person with one node swapped. He keeps Stats, Inventory, Readout, place,
  travel cost, and every drive.
- `game/brain.gd` — the fork. One virtual, one override, no branch on identity.
- `game/player_brain.gd` (new) — extends Brain; overrides *how the winner is
  chosen*, nothing else. Upkeep still runs in `Brain._update_body` and is not
  duplicated here.
- `game/ui/verb_list.{gd,tscn}` (new) — draws `get_available()` and reports which
  one was clicked. Discovers its contents by reflection, like `stat_graph` and
  `tuning_board` before it. **It must not contain a verb name.**
- `game/game.tscn` — the player instanced into the town square.
- `game/probe.gd` — the claims below.

## The shape of the fork

`Brain.think_and_act` currently does three things in a fixed order, and the
order is load-bearing (decide → do → update body, per its own header). **The
order does not change.** Only the middle of step one does.

Suggested shape, to be re-derived against the real file:

- `Brain` grows one virtual — *how this brain picks a winner from the open
  list*. Default body is what it does today: hand the list to
  `get_highest_scoring`.
- `PlayerBrain` overrides that one method to return whatever the verb list last
  reported, or null.
- **`get_available` is called identically for both**, from the shared parent.

**Null is a real answer and means "standing there."** The player who has chosen
nothing does nothing, tires, and hungers — because `_update_body` runs
regardless, which is the rule that has been true since rung 0.

**What must NOT happen:** `if person == player` anywhere in `game/`. The fork is
polymorphic or it is wrong. Same rule as "no code names a playstyle."

## Probe claims

Written in the same session, and **each one watched failing** before it counts.

1. A player body with no verb chosen still tires — `adenosine` rises across a
   pumped hour with `current_action` null.
2. The verb list is exactly `get_available()` — assert against the engine's own
   output, not against an expected set of names, so adding an action to the
   player's Brain cannot make this claim stale.
3. A verb whose gate says no never appears in the list. **Break-test this by
   authoring a gate that returns false**, not by finding one that happens to.
4. Choosing a verb runs that Action's step — grain in the player's inventory
   climbs after choosing Work at a plot, and does not climb when he is standing
   in the road.
5. An NPC in the same scene, on the same tick, still picks by score — the fork
   changed one body and not the engine.

## Moment

**Watch at a LONG day — 300–600 seconds.** This gate is a slow walk and a
changing list, not a once-a-day beat; rung 4 is the precedent, and at 60 s the
crossing that matters here takes under a second.

You spawn in the town square. The verb list is empty or nearly so. You walk
toward the fields on your own legs — and **the list changes under you.** Work
appears when you are standing at the plot. You choose it. The number in your own
sack climbs, on the same readout that has floated over Zoogs' head since rung 5.

Meanwhile Zoogs and Hobb run their day around you and **nothing about it
acknowledges that you are there.** That indifference is the correct result and
is the baseline every later gate is measured against: Gate 3 is the first time
the town does something because of you.

**Write down what you saw before you paste the probe output.**

## What NOT to build

The tempting adjacent systems, each of which is a later gate or no gate at all:

- **Any command.** No beckon, no greet, no give. The player acts on the world at
  this gate, never on a person. Commands start at Gate 3.
- **Standing, or any social value.** Gate 2.
- **A camera system.** Whatever gets you a body walking around is enough. A
  follow-cam is not a seam.
- **An input remapping layer, an action-bar framework, or hotkeys.** A list you
  can click is the whole requirement.
- **The excuse strings.** They belong to the gate where a refusal first happens
  (Gate 3), and authoring them here means authoring them against a guess.
- **Removing the authored obligations.** The town stays employed until Gate 6.
  Zoogs and Hobb working around you is what makes your indifference-baseline
  legible.
