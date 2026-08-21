# Gate 1 — what putting a body in the town found

**Written 2026-08-20**, the day Gate 1 of the boss ladder landed. Opus
orchestrated; Sonnet agents built the fork, the verb list and the probe claims
against re-derived delta sheets; every claim was re-verified and independently
break-tested before anything was committed.

**This file is for a conversation, not for a builder.** Read Part 0 first — it is
the reason this gate's Moment is not the Moment the plan wrote.

> ### ⚠ THE MOMENT HAS NOT BEEN WATCHED
>
> This gate was built in a headless background session. **Nobody has seen it
> run.** Decision 33's process rule — *a gate is not closed until a paragraph of
> what you SAW is written above the probe output* — is therefore **NOT
> satisfied**, and no paragraph is offered in its place. Part 5 is the watch
> list. Until that is done, treat this gate as built and verified but not closed.

---

## Part 0 — Gate 1's Moment could not be built, and the reason outlives Gate 1

The plan and the session prompt both cut the same beat:

> *"You walk toward the fields on your own legs and **the list changes under
> you** — Work appears when you are standing at the plot."*

**Neither half was true of the shipped code**, and both were true when written.

**The player could not work anything.** The only `field work` station in the
world was Marle's. `Workstation.is_permitted_to` opens owned land to the owner
and to whoever carries an obligation naming that place; the player is neither, so
`WorkTheField` read false for him **everywhere in town, at every hour.**

**And no gate in the game reads where a man is standing.** This is the part that
matters beyond this gate. Decision 30 moved freeness onto a public register —
*"the register says whether it is worth going; his feet decide whether he gets
it"* — and in doing so took the **last positional term out of the last gate in
the project.** Enumerated:

| Action | What its gate asks | Positional? |
|---|---|---|
| `StayUp` | is he awake | no |
| `Sleep` | is any bed free anywhere | no |
| `Wake` | is he asleep | no |
| `Eat` | awake, and has he a loaf | no |
| `MakeBread` | awake, and has he the grain | no |
| `Socialise` | awake, and does a venue exist at all | no |
| `WorkTheField` | awake, and is a permitted station free | no |

**So a ballot cannot change under anybody's feet — player or NPC.** Nothing is
wrong: Decision 30 argued the change and the dither it killed was measured. But a
Moment written around walking into a verb described a game that had stopped
existing eight commits earlier, and nobody noticed because until now nobody had
feet.

Settled as **Decision 35** before a line was written. The town gained an
unclaimed field so the player can act on the world at all, and the Moment was
**re-cut rather than rescued**: the list changes because of what he **carries**.
Work to three grain and MakeBread appears on his own ballot; bake, and Eat
appears. That is the loop closing in a person's hands instead of in a probe, and
it is a better beat than the authored one.

**Position did not become irrelevant — it moved phases.** It orders candidates in
SCORE (which plot), and in DO it is nearly everything: no yield until you stand
at the plot, no claim without presence, no company until you reach the venue, not
asleep until you are in the bed.

---

## Part 1 — What landed

**One seam, as specified: where a Person's decision comes from.**

`DecisionEngine.open_the_ballot()` clears the score readout and gates, in that
order, so the clear still happens in exactly one place. `Brain` grew one virtual —
`pick_from_the_ballot(open_actions)` — whose default body is what `choose()` used
to do inline. `PlayerBrain extends Brain` overrides it to return whatever a hand
picked. **The gating half is untouched and shared**, which was the whole point:
the player is subject to every gate any author ever wrote.

**`DecisionEngine.choose()` was deleted.** Not in the plan, and it is an
improvement rather than a liberty: once `Brain` stopped calling it, it had no
caller anywhere — and worse, a future `Brain` subclass that called it would get
the score-driven winner **with the fork silently skipped.** Same reasoning as
`Inventory` having exactly one transfer path: a second way to do the whole thing
is a second place for the wrong half to happen.

**The player's place, per Decision 17**, is written by a two-radius band — enter
on the inner, leave only on the outer — settled as the **last** thing in his tick.
That ordering is load-bearing: a chosen verb whose step walks him (`WorkStep`)
writes `current_place` too, and the band speaking last is what keeps the writer
count at one. `person.gd` and `place.gd` both carried comments asserting the old
absolute; both were corrected rather than left to rot.

**Movement is integrated in world hours**, sampled per frame. Probe claim 66 pins
it by driving real frame deltas through `Clock.get_hours_elapsed` at two different
day lengths.

**The verb list names no verb.** Rows come from `Action.label`; the file contains
no verb string and no branch on one.

---

## Part 2 — The town gained two places, and cost the NPCs nothing

`Town/Square` (where you spawn; non-gathering, so `Socialise` cannot see it) and
`Town/CommonField` holding one **unowned** plot.

**At its own Place, deliberately.** An unowned plot at the grain fields would
match Zoogs' obligation `place_name`, and **Zoogs would get an errand** — which
Gate 1 forbids outright, because his idleness is Decision 30's finding made
visible. At its own place no NPC can see it: both farmers scope to the grain
fields, Marle has no work action.

**Measured, not argued.** The anchor is byte-identical either side of the whole
gate:

```
cold start: turned in 21:14, up 05:52
settled:    turns in 22:10, sleeps 8.00 h, up 06:10
strong man (1.15): up 04:47
```

---

## Part 3 — Two probe claims were vacuous on the first attempt

Both were caught by break-testing, which is the entire argument for the practice.

**1. "The verb list is exactly the open ballot" could not fail.** The obvious
claim compares `get_drawn_actions()` against the engine's output. But
`_shown_actions` is assigned from the list the panel was **handed**, not from what
it **built** — so a rebuild that silently dropped a row would leave the two
agreeing perfectly. Fixed by counting actual `Button` nodes. Red line, once the
rebuild was made to drop its last row:

```
get_drawn_actions() reports 4 actions but the panel actually holds 3 Button nodes
```

**2. "An NPC still picks by score" could not fail either**, for a reason that is a
genuine consequence of the fork nobody had stated: **the player's ballot is never
scored at all.** `get_highest_scoring` is never called for him, so `_last_scores`
holds nothing but NANs for the player forever. A claim reading his recorded scores
would have been reading an empty room. Rewritten to score his open actions
directly, and asserted at **night**, where a hand and a score genuinely disagree.

**That NAN readout is a live consequence, not a bug**, and it is worth knowing:
the player's utility graph will draw nothing. He is not scored because nothing
scores him.

---

## Part 4 — The four author calls

| Call | Ruling |
|---|---|
| Gate 0's three numbers (`share_of_crop` 0.35, `base_grain_per_hour` 2.5, `larder_target` 6) | **Stand.** Still Gate 8's to re-author; Gate 1 changed none of them. |
| `bite` on a stock gap | **Still unruled**, and now with a *second* wrong answer named. See below. |
| `physics/common/physics_interpolation` | **Left off.** The question does not come due: Decision 4 forbids `move_and_slide`, so the steered body is moved by the same direct position writes every NPC uses. No physics-driven transform entered `game.tscn`. Revisit when something actually moves on the physics tick. |
| The Moment | **Author a square and an unclaimed field.** Decision 35. |

**On `bite`:** the mechanism-shaped proposal was to make the ACT close the gap —
`MakeBreadStep` bakes up to the target in one go, so `bite` stays 3 and the target
starts governing. **The author refused it, and the refusal is sharper than the
proposal:** *"closing gaps in one go sounds dangerous — one act may reduce the gap
below the action threshold."* An act sized to close the whole gap overshoots the
state in which the want was **legible** — plainly-short to plainly-stocked inside
one tick, with no middle for anything to read. A want that is only ever fully open
or fully shut is a switch, and a switch somebody flips is the shape Decision 34
opens by diagnosing. Recorded in Decision 34 alongside the first wrong answer
(retuning the exponent).

---

## Part 5 — The watch list, in the order to look at them

**Set `day_length_seconds` to 300–600 on the tuning board first.** At 60 the whole
town is crossed in a fraction of a second.

1. **The Moment.** Spawn at the square with an empty sack. Walk to the common
   field on WASD. Choose Work. Watch the grain climb on your own head — and watch
   **MakeBread appear on the list at three grain.**
2. **The band.** Walk slowly across the edge of the square and back. Your place
   should change once each way, and not twitch. `enters_within` and
   `leaves_beyond` are on the tuning board; they were picked at 3.0 and 4.5
   without watching, which Decision 17 says is the wrong way round.
3. **The auto-walk, and this is the one most likely to feel wrong.** Choose Work
   from the square without walking there. `WorkStep` will walk your body for you —
   the player picks a verb and loses his legs. It is consistent (it is what a
   commanded NPC will do from Gate 3) and it may still read badly. **Related: WASD
   still works while it walks you**, because input integrates before the step each
   tick, so you can drag against your own errand.
4. **Standing in the tavern makes you company.** `Town.find_people_at` cannot tell
   you from an NPC, which Decision 17 says is the point. The first time the town
   reacts to you at all, two gates before you can address anybody. Watch it; do
   not suppress it.
5. **You can steer while asleep.** Nothing gates movement on `is_awake`, because
   Decision 33 leaves open whether the player's drives ever constrain him, and a
   movement function is the wrong place to answer that quietly.
6. **You will starve.** The player is authored with no bread. That is the point —
   bake your way out — but it is not a bug report.

---

## Part 6 — Still open, in the order they will bite

1. **Travel as a chooseable activity.** The author's proposal: utility should find
   the activity that maximises the probability of the desired action — *going* to
   the field is what you pick when you want to work, and working is what you pick
   once you are there. **This would make the verb list positional again for
   free**, with no gate reading the world from afar: "am I standing at a workable
   plot" reads only your own body. It also dissolves the auto-walk problem in
   Part 5.3. **One wrong answer already eliminated: not probability.** A travel
   action should inherit, undiscounted, the want it serves — which needs no new
   quantity. **Comes due at Gate 3**, where beckon is a travel-only command and a
   travel intent gets built regardless.
2. **Decision 15's ban on travel cost in the want sum** is a *scale* ruling
   wearing a principle's clothes. The author: *"travel time should be a very small
   cost, and if it is too big for them to walk to work, we haven't calibrated the
   distances and travel times and the cost to travel properly."* Correct — and the
   number in question **has never been authored**, because the ban stopped anyone
   picking one. Measured at today's map: the longest journey is ~19 units, about a
   sixth of a world hour, against wants on a 67–130 scale. Under ~10 want-points
   per world hour the worst commute costs 1.7 points and can only break ties.
   **Around ~34 it starts muting work at dawn** (work beats idling by only 5.7 at
   sun-level). So the safe window is real but not self-evident. The shape that
   gives both: **a probe claim that the worst in-town commute costs less than the
   narrowest gap between the top two wants** — a tripwire instead of a ban, which
   goes red by itself the day the world stops being one town.
3. **`bite` on a stock gap.** Part 4. Blocks nothing.
4. **Failure-marks-the-candidate** (Decisions 23/24), unchanged from Gate 0.
5. **`project.godot` still declares `config/features=("4.4", ...)`**, and
   `probe.gd`'s header still prints the 4.4 run lines. Author's call.
6. **A Godot 4.4 editor was open on this project throughout the session** (started
   15:12, before any of this work). It holds a pre-Gate-1 `game.tscn` in memory;
   saving from it would silently wipe the Square, the Common Field, the Player and
   the VerbList. Verified intact at commit time. **Close it without saving.**
