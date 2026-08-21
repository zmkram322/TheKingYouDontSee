# Gate 1 — A body you steer, and a verb list that changes under your feet

> ## ✅ GATE 1 LANDED 2026-08-20 — this file is spent
>
> Built and verified. **Two things in this file were wrong when it was written
> and are recorded rather than smoothed over**, both settled as **Decision 35**
> before any code was cut:
>
> 1. **"Work appears when you are standing at the plot" cannot happen.** Decision
>    30 made freeness a public register, and in doing so took the last positional
>    term out of the last gate in the project. **No gate anywhere reads where a
>    man is standing.** A ballot cannot change under anybody's feet.
> 2. **The player could not work at all.** The only `field work` station is
>    Marle's, and the player carries neither ownership nor an obligation — so
>    `WorkTheField` read false for him everywhere, at every hour.
>
> Step 1 (the band), Step 2 (hours, not frames) and Step 0 (the fork) were all
> correct and all landed as written. See `gate-1-findings-2026-08-20.md`.


**Written 2026-08-19, for a fresh session.** First gate of the boss ladder
(`boss-scene-build-plan.md`).

> ## ✅ GATE 0 LANDED 2026-08-20 — build this one
>
> The town has stopped dithering. `07a1400`, `ef04050`, `e756795`, `1575b3a`,
> `d11fe8c` on `poc-v2`; probe **55/55 green, 14823 checks**. Read
> **`gate-0-findings-2026-08-20.md`** before starting — Part 0 first, it records
> an instruction this repo gave and the last session missed.
>
> **The anchor to measure against.** Not the numbers in any older file; they are
> superseded and must not be re-quoted.
>
> ```
> cold start: turned in 21:14, up 05:52
> settled:    turns in 22:10, sleeps 8.00 h, up 06:10
> strong man (1.15): up 04:47
> ```
>
> **Four things about the town you will be standing in**, so none of them reads
> as a bug you introduced:
>
> 1. **The loop closes.** Hobb bakes from day 7 and holds a two-loaf cycle. He
>    ends twelve days on 82 grain and gaining — a surplus with nowhere to go.
> 2. **Zoogs does nothing, all day, every day.** He loses every dawn race and
>    has no second plot. Decision 30 made rung 5's inequality visible instead of
>    disguising it as pacing. **This is correct. Do not give him an errand.**
> 3. **Zoogs and Marle starve from day 9**, pinned at the hunger ceiling around
>    the clock. Decisions 29 and 30 both say outright they do not fix this.
>    **Do not give either man an action.** It will not affect a 48-hour probe.
> 4. **A residual dither remains, ~356 changes/day, and it is NOT the fields** —
>    Marle mirrors it exactly with no obligation at all. It is the
>    `Socialise`/`StayUp` oscillation awaiting failure-marks-the-candidate
>    (Decisions 23/24). **Out of scope. Do not chase it.**
>
> **Three carried-forward calls that are the author's, not a builder's.** Raise
> them, do not decide them:
>
> - Whether Gate 0's three authored numbers (`share_of_crop 0.35`,
>   `base_grain_per_hour 2.5`, `larder_target 6`) **stand or revert** — the
>   ladder reserves them for Gate 8 and they were authored early by mistake.
> - **`bite` on a stock gap** (Decision 34's closing section). `larder_target`
>   currently governs nothing.
> - **`physics/common/physics_interpolation`** is off, so `workbench/`'s camera
>   jitter fix is not live. It is GLOBAL, and this town's people are moved by
>   direct position writes every `_process` tick — `Population` and `Town` want
>   opting out before it goes near `game.tscn`. **Relevant to this gate**, which
>   is the first to put a steered body in that scene.
>
> **Engine is now Godot 4.7.2-stable-mono** — verified behaviour-identical to
> 4.4. Run lines are in `CLAUDE.md`; `probe.gd`'s own header still prints the old
> 4.4 ones and has not been corrected.

## What this gate installs

**One seam: where a Person's decision comes from.**

Every body runs `Brain.think_and_act(hours)` → `DecisionEngine.choose()` →
`get_available()` then `get_highest_scoring()`. This gate forks **the second half
only, for one body**. The gating half stays shared and untouched, which is the
entire point: **the player is subject to every gate any author ever wrote,
exactly like everyone else.**

**What this seam is NOT:** a menu system, an input manager, a UI framework, a
camera system, or a `Player` class. It is a fork in one function plus a list
drawn on screen.

## Read before writing anything

| | |
|---|---|
| `CLAUDE.md` (repo root) | Conventions. Non-negotiable. Note the naming rules and the node-vs-shared-file rule. |
| `boss-scene-build-plan.md` | The ladder, and Gate 1 cut in full at the bottom. |
| `proving-scene-decisions.md` — **17** | **How an embodied player gets a place.** Already settled, and it is this gate's hardest problem. Settled 2026-08-11 with the note *"relevant the moment one exists"* — this is that moment. |
| `proving-scene-decisions.md` — **33** | The reframe. The two binding sub-rulings (verb menu = `get_available()` drawn; no code names a verb). |
| `proving-scene-decisions.md` — **5, 12, 16, 18** | Hours-denomination, how two people differ, what physics is for, sim-owns-duration. |
| `proving-scene-build-plan.md` — *Don't script the simulation* | Still binding on every gate of the new ladder. |
| `game/brain.gd`, `game/decision_engine.gd`, `game/person.gd`, `game/population.gd` | The four files this gate touches or reads. Read them, do not trust this document's summary of them. |

## Five hard rules

1. **Re-derive every snippet; paste none.** Code quoted in plans and decisions is
   illustrative and has drifted from `game/` more than once. Open the real file.
2. **Every probe claim must be watched failing.** Break the code deliberately,
   see it go red, put it back. **Eight vacuous assertions have been caught this
   way.**
3. **No `if person == player` anywhere in `game/`.** The fork is polymorphic or
   it is wrong — same footing as the rule that no code names a playstyle.
4. **No menu code names a verb.** A verb appears because an `Action`'s own
   `is_available_to` said yes about the player's body. `if verb == "work"` is a
   failed build.
5. **No new substrate.** No input-remapping layer, no action-bar framework, no
   camera rig, no scheduler. If something seems to need one, it is out of scope —
   say so and stop.

---

## Step 0 — The decision fork. Design this before writing anything else.

`DecisionEngine.choose()` currently does three things in one call: clears
`_last_scores`, gates, then scores. **The clear must keep happening exactly once
per pass**, or the readout the graph draws stops being trustworthy — and it is
written by *both* halves, which is why it cannot simply be moved into one of
them.

**The shape to aim for**, to be re-derived against the real file:

- `DecisionEngine` grows **one** method that starts a pass and returns the open
  list — the clear plus `get_available`, in that order.
- `choose()` is refactored to call that method and then `get_highest_scoring`,
  so there remains **exactly one place** the clear happens.
- `Brain` grows **one** virtual — *how this brain picks a winner from the open
  list* — whose default body is what it does today.
- `PlayerBrain extends Brain` overrides that one method and nothing else.

Name the new method by the house rules (verbs or questions; plain English over CS
vocabulary). Do not name it `dispatch`, `resolve`, or `tick`.

**`null` is a real answer and means "standing there."** A player who has chosen
nothing does nothing — and still tires, still hungers, still grows lonely,
because `_update_body` runs regardless. That has been true since rung 0 and must
stay true.

**Do NOT duplicate upkeep into `PlayerBrain`.** Grep `game/actions/` for
`adenosine` — it must stay empty, and the same reasoning bans a second copy of
`_update_body`.

## Step 1 — The player's place, per Decision 17

This is the part most likely to be got wrong, and it is already ruled.

> **The player's place must be exactly as crisp as an NPC's**, because nothing
> downstream can distinguish them. Same field, same accessor, same discrete
> answer, no flicker. **What differs is only the WRITER.**

- NPCs: `GoToStep` writes `current_place`, driven by a decision.
- The player: an **input-driven writer**, driven by input.

**The mechanism is a band, not a line: enter on crossing an INNER boundary, leave
only on crossing an OUTER one.** This is the same two-threshold pattern the sleep
cycle already uses — sleep starts winning high and stops winning low — applied to
space instead of to adenosine. **It is not a new mechanism, and it must not be
built as one.**

Do not reach for `Area3D` proximity. That is the model retired 2026-08-08, and
**probe claim 7 exists specifically to stop it coming back.** A player whose
place flickers on a boundary flickers in and out of every NPC's candidate list,
and it reads as *"the AI is flaky."*

**The band width is a tuning number and Decision 17 left it open.** Export it,
put it on the tuning board, and pick a value by watching — do not derive one.

## Step 2 — Movement is denominated in WORLD HOURS. This is a trap.

`Person.walk_speed` is units per **world hour**, and `get_travel_speed()` is the
one accessor for how fast a body moves. If the player is moved from `_process`
by a real-frame delta, then **dragging `day_length_seconds` changes how fast the
player walks relative to every NPC** — and that failure presents as a tuning
problem, which is exactly the shape of the bug rung 0 was spent removing.

> **The player's movement happens inside the hours-denominated tick**, using
> `get_travel_speed() * hours`, like everything else below `Clock`. Input may be
> *sampled* per frame; it may not be *integrated* per frame.

Integrate `global_position` by hand. **Do not use `move_and_slide`** — Decision 4
and `person.gd`'s own header: called from `_process` it multiplies by the
*physics* delta and produces non-uniform steps, and under `PROCESS_MODE_DISABLED`
it moves zero in silence, which would make every movement claim in the probe
unwritable.

## Step 3 — The player scene

**An inherited scene from `person.tscn`, not a new class and not a hand-built
node tree.** He keeps Stats, Inventory, Readout, `current_place`, travel cost,
and every drive, because he *is* a Person — Decision 12's whole point is that
people differ by authored values, not by type.

> **⚠ `person.tscn`'s node order is load-bearing and an inherited scene must not
> reorder it.** `game.tscn` overrides Hobb's Stats **by index**
> (`[node name="Stats" ... index="3"]`). A node inserted above Stats renumbers
> it, the override lands on the wrong node or is dropped, both farmers wake at
> the same moment, and the dawn race turns back into a coin flip. **That failure
> presents as "the sleep cycle broke," never as "a node moved."**

He goes **under `Population`**, like everybody. That is what ticks him, and it is
what gives him upkeep for free.

## Step 4 — What putting him under Population does to the rest of the town

Two consequences. **Both are correct. Neither is to be patched at this gate.**

**1. `probe.gd` asserts there are exactly four people.** Line ~380:
`population.get_people().size() == 4`, with a sibling claim expecting 3 after a
removal. **Adding the player breaks both.** Update them deliberately — and read
the claim's own comment first, because it exists to catch a *marker node being
counted as a person*, which is a real hazard this gate walks straight into.

**2. `Town.find_people_at()` will return the player**, because it reads
`population.get_people()` and cannot tell him from an NPC — which Decision 17
says is the point. So a player standing in the tavern **is company**, and soothes
a lonely NPC's `social` gap.

That is not a bug. It is the first time the town reacts to your presence at all,
it arrives two gates before you can address anybody, and **it should be watched
rather than suppressed.** If it turns out to feel wrong, that is a finding for
Gate 2, not a fix for Gate 1.

## Step 5 — The verb list

A new scene under `game/ui/`, alongside `stat_graph` and `tuning_board`, and
built the same way they were: **it discovers what to show by reflection**, so it
needs no line per verb. Like both of them it wants a `CanvasLayer` parent.

It draws whatever the open-list method returned this tick and reports which entry
was chosen. Label text comes from `Action.label`, which already exists for
exactly this — *"what this reads as when you're watching him."*

**It contains no verb name. Not one.**

---

## Probe claims

Written in the same session as the code, added to the standing harness, and
**each one watched failing** before it counts.

1. **A player body with no verb chosen still tires** — `adenosine` rises across a
   pumped hour with `current_action` null. *(Break-test: stub the upkeep call.)*
2. **The verb list is exactly the open list** — assert against the engine's own
   output, never against an expected set of names, so adding an Action to the
   player's Brain cannot make this claim stale.
3. **A verb whose gate says no never appears.** **Break-test by authoring a gate
   that returns false**, not by finding one that happens to be shut — the standing
   trap is that *a claim about a rule with no branch must be asserted in the state
   the missing branch would have changed.*
4. **Choosing a verb runs that Action's step** — grain in the player's own
   inventory climbs after choosing Work at a plot, and does **not** climb when he
   is standing in the road.
5. **An NPC on the same tick still picks by score** — the fork changed one body,
   not the engine.
6. **The player's place never flickers.** Walk him across a boundary and back;
   `get_current_place()` changes at most once per crossing. This is Decision 17's
   claim and the reason the band exists.
7. **The player moves the same distance per world hour at any day length.** Pump
   an hour at two different `day_length_seconds` values and compare. This is the
   Step 2 trap, pinned.
8. **The existing population-count claims still mean what they meant** — updated
   for the new body, not deleted.

## The Moment

**Watch at a LONG day — 300–600 seconds.** This is a slow walk and a changing
list, not a once-a-day beat. Rung 4 is the precedent: at 60 s the crossing that
matters here is over in under a second, and *"I did not see it happen"* reads as
a broken seam.

You spawn in the town square. The verb list is empty or nearly so. You walk
toward the fields on your own legs and **the list changes under you** — Work
appears when you are standing at the plot. You choose it. The number in your own
sack climbs, on the same readout that has floated over Zoogs' head since rung 5.

Meanwhile Zoogs and Hobb run their day around you and **nothing about it
acknowledges that you are there** — except, if you stand in the tavern, that
somebody is a little less lonely. That indifference is the correct result and it
is the baseline every later gate is measured against: **Gate 3 is the first time
the town does something because you told it to.**

> **This gate is not closed until a paragraph of what you SAW is written above
> the probe output.** Not instead of it — above it. Rung 5's Moment was never
> watched, and rung 6 shipped a man pacing a field for six days behind a green
> probe and a counter that reported nineteen hours of work.

## What NOT to build

Each of these is a later gate, or no gate at all.

- **Any command.** No greet, no beckon, no give, no follow. The player acts on
  the **world** at this gate, never on a **person**. Commands start at Gate 3.
- **Standing, or any social value between two people.** Gate 2.
- **The excuse strings** (*"I'm dead on my feet"*). They belong to the gate where
  a refusal first happens — Gate 3 — and authoring them here means authoring them
  against a guess.
- **Removing the authored obligations from `game.tscn`.** The town stays employed
  until Gate 6. Zoogs and Hobb working around you is precisely what makes the
  indifference baseline legible.
- **A follow-camera, mouse-look, or any camera system.** Whatever gets a body
  walking around and visible is enough. A camera is not a seam.
- **Hotkeys, input remapping, or an action bar.** A list you can click is the
  whole requirement.
- **Animation.** Decision 18: the sim owns duration, the animation illustrates
  it. There is no animation budget on this ladder yet.

## Verifying

No test suite. Two commands, always, and in this order — `--script` does not
build the global class cache, so without the import pass in front of it
`class_name Person` fails to resolve and the probe dies for a reason that has
nothing to do with what you changed:

```
Godot_v4.4-stable_mono_win64_console.exe --headless --path . --editor --quit
Godot_v4.4-stable_mono_win64_console.exe --headless --path . --script game/probe.gd
```

Then open the scene and **watch the Moment at a long day.**

## Stop at the gate

Report the probe output, write what you saw, and **do not begin Gate 2.** A
session that lands two seams has destroyed the evidence that either was needed.
