# Session Plan — Build a World

**Written** 2026-08-03, branch `poc-v2`, at the close of the session that critiqued `tkyds-game/brain/` and applied the resulting fixes.
**This is Part 2.** Part 1 is closed — its rulings are in `_bmad-output/brain-critique-decisions.md` and are not up for re-litigation. Start here, cold.

---

## How to use this document

**You are orchestrating, not implementing.** Read this whole file and the PRD, decide the split, brief delegates, and verify what comes back. Resist doing the build yourself — the value here is in the split and the verification, and a delegate that returns something subtly wrong is only caught by someone holding the whole picture.

**Two audiences, and they need different things.**

- **You** read this file end to end, plus `_bmad-output/planning-artifacts/prd.md` (771 lines) and `_bmad-output/brain-critique-decisions.md`.
- **Delegates do not read the PRD.** It is too long to hand out, and a delegate spending its context reconstructing the design will have less left for the work. **Paste the relevant FR text into the brief** instead. If a delegate needs an FR you did not include, that is your gap to fix, not theirs to go hunting.

**Every brief must carry the invariants block below, verbatim.** Almost every rule in it says *don't do the obvious thing*, so a model that hasn't been told will violate it while doing exactly what was asked. Told "build a world object," an unbriefed delegate will add a `finished` flag, reach into `stats` directly, extend `Node`, and split it into three classes — all reasonable, all wrong here.

**A delegate that thinks it must break an invariant stops and reports.** It does not work around it. That report is a finding and comes to you.

### The invariants block — copy this into every delegate brief

> **Non-negotiable constraints for this codebase. If your task seems to require breaking one, stop and report it rather than working around it.**
>
> 1. **Nothing stores progress.** No `finished` flags, no child indices, no timers. Every tick re-asks the world. If you are tempted to remember where something got to, the world should already say.
> 2. **Steps are shared by every character at once.** A Step must store nothing about who is doing it. Per-character state goes on the `Character`.
> 3. **All character state goes through `who.stat(&"x")` / `who.set_stat(&"x", v)`.** Never `who.stats.x`. The Dictionary behind the accessor is an implementation detail.
> 4. **Everything runs under `--headless --script`.** Extend `RefCounted`. Never `Node`, physics, `Area2D`, or anything requiring a scene tree. (The 3D scene skin is the single exception, and it only reads.)
> 5. **`DecisionBrain` never reads a field off its subject.** It hands the subject to an action's own gate and curve, nothing more. Actions may know what a subject is; `brain/` may not.
> 6. **No class per noun.** Three related jobs are usually three *methods*, not three classes. `Scorer`/`Ranker`/`Scored` were built and deleted the same hour.
> 7. **Impossible is not the same as done.** `is_possible` false means abandon without discharging. Collapsing it into `is_satisfied` lets a debt nobody can serve quietly pay itself off.
> 8. **Obligations compete as ordinary candidates.** They never bias, bypass, or pre-empt scoring. Exhaustion is allowed to outbid a lord's order, and the order stays owed.
> 9. **Every new piece gets its own miniature headless proof scene** before it joins anything larger, following `tests/brain_*_smoke.gd` — including the `EXPECTED_CHECKS` guard that catches a suite crashing while still printing OK.
> 10. **All nine existing suites must stay green.** Do not opportunistically refactor `brain/`; it is a settled substrate.
> 11. **Before blaming a reimport, check for a duplicate `class_name`.** Godot never reports this — one silently wins, and which one depends on scan order.
>
> Run: `Z:/Godot/Godot_v4.4-stable_mono_win64/Godot_v4.4-stable_mono_win64_console.exe --headless --path tkyds-game --script res://tests/<name>.gd`
> New `class_name` scripts need a reimport first: `--headless --path tkyds-game --editor --quit` — run it twice, the first pass prints parse errors while the class cache rebuilds.

---

## Where things stand

`tkyds-game/brain/` is a decision substrate for **one actor acting alone**. It decides what to do and chains actions together. It has no world, no clock, and no way for work to cross between people. That is what this session builds.

Nine headless suites are green. The three brain suites run leak-free.

### What's in `brain/` — 8 files, ~500 lines

| File | What it is |
|---|---|
| `action.gd` | `Action` — choosable. `label`, `eligible` (gate), `score` (curve), `body` (**required**), `protected` + `.always_available()`. |
| `obligation.gd` | `Obligation extends Action` — work handed in from outside. Adds `about` (a key to match on), `asked_by`, `taken_on`. |
| `step.gd` | `Step` — doable. Answers **three** questions: `is_satisfied(who)`, `is_possible(who)`, `advance(who, delta) -> bool` (returns whether it's now satisfied). |
| `sequence.gd` | Children in order. No index, no bookkeeping — re-asks which child is next every tick. |
| `choice.gd` | A Step that generates Actions, ranks them, gives the winner the time. Decisions nest at any depth. |
| `walk_to.gd` | The one leaf. Reads/writes `position` through the stat accessor. |
| `decision_brain.gd` | **Stateless.** `is_available(who, action)`, `determine_available_actions(who, from)`, `score(who, action)`, `highest_scoring(who, from)`, `choose_action(who, from)`. Holds nothing, shareable like a Step. |
| `character.gd` | Everything that's a fact about a person: `stats` + `stat()`/`set_stat()` accessor, `actions`, `queue`, `active_action`, `candidate_actions()`, `decide_action()`, `assign_action()`, `owes_anything_about()`, `find_obligation_about()`, `finish_active_action()`, `abandon_active_action()`, `act(delta)`, `doing_label()`. |

### The five things that hold it up

1. **Nothing stores progress.** Every tick re-asks the world. No `finished` flags, no child indices, no timers. So interrupting costs nothing — nothing was suspended, so nothing needs restoring.
2. **Steps are shareable.** A Step stores nothing about who is doing it, so one object serves every character at once.
3. **Obligations compete, they don't override.** An assigned obligation is a candidate in the same pass as every ordinary need. Exhaustion can outbid a lord's order, and the order stays owed.
4. **Everything goes through `stat()`/`set_stat()`.** The Dictionary behind them is an implementation detail. Do not reach past the accessor — that seam is why a derived-stat store can be swapped in later as a one-file change.
5. **Impossible ≠ done.** A Step that can't be got on with says so, and the caller abandons without discharging.

---

## The question that unlocks this session

**Where do demands get emitted and awaited?**

The PRD's atom: *a demand hits a resolver each tick; the resolver either satisfies it or emits the child demand it requires and waits on it.* The brain has no emit and no wait. Part 1 settled most of the shape:

| PRD concept | How it's expressed |
|---|---|
| An actor's own unmet demand | Already there — an Action whose `score` reads the unmet stat. Nothing to build. |
| Emitting a child demand | `assign_action` an `Obligation` on **another** character. The one path by which work crosses actors. |
| Not emitting it twice | `owes_anything_about(key)` — ask whether it's already owed. Reading what someone owes is reading the world, not remembering that you asked. This is why `Obligation.about` exists. |
| Finding who to emit to | A world-owned index of who currently reads as able to serve. **Derive it once per world tick and serve that snapshot** — deriving per read is O(actors) inside a generator inside a scoring pass, and does not survive contact with a real actor count. Fresh as of T is exactly what FR4 asks for and no more. |
| Waiting on it | **Nothing.** See below. |
| Provider chose you | The provider's own scoring pass over their queue. They may simply not do it. |

### There is no `Wait` step, and that is the strongest form of the idea

Waiting is not a state an actor is in. It is what it looks like from outside when the interesting action is ineligible and something duller keeps winning.

The innkeeper does not wait for flour. She sweeps, she dozes, she serves who's there — and `bake bread` is gated on having flour. When the flour arrives, baking starts winning. Nothing was blocked, nothing was resumed, and no leaf had to exist.

**Build it this way first.** If something genuinely cannot be expressed like this, that is a real finding and worth stopping on — but reach for it last, not first.

### Duration is world-side

Re-derivation handles *state-based* work perfectly — walk until you're there, eat until you're fed. It does not handle *duration-based* work at all: mill the grain for an hour, stand the watch.

Express duration as a progress stat on the thing being worked (`grinding_progress` on the mill), not a timer on a Step. Be honest that this is **more** state, not less — it just lives somewhere shared, where an interruption can't destroy it. `Ploughing` in `brain_smoke.gd` is the pattern, and it's deliberately per-character; a mill would hold its own.

---

## Step 0 — read the PRD before deciding anything

Before any delegation decision, read `_bmad-output/planning-artifacts/prd.md`. The FR numbers cited throughout this plan (FR1, FR4, FR9/FR12/FR13, FR86, FR100–FR103) are load-bearing and this plan only paraphrases them. Whoever splits this session into delegated work decides that split **after** reading the PRD, not from this file alone.

Read at minimum: the demand/resolver atom, §Cascade, and FR100–FR103. If the PRD and this plan disagree, that is a finding — stop and raise it rather than picking one.

**The numbers in the build order are an ordering, not a work breakdown.** They say what must exist before what. They say nothing about how much work each one is, and the sizes are wildly uneven — item 3 is a constants file, item 9 is asset sourcing plus a scene plus an FSM. Do not hand out one numbered item per delegate and assume the load is balanced. Group and split on actual weight, respecting the order.

**One constraint on the split, decided in advance: items 4 and 5 go to a single delegate as one chunk.** The curve proof scene needs a day to pass in order to show anything, and the thing that advances the day is the staggered sweep in item 5. Split them and the curve delegate has to hand-step a clock that the next delegate then replaces. Everything else in the build order is yours to divide.

## What to build, in order

Brick by brick, each with its own miniature proof scene before it joins anything larger.

1. **A world object.** Owns places, a clock, and the list of characters. Characters do not know about it; generators and leaf Steps close over it. `sandbox/sandbox_world.gd` is prior art for the headless-engine/scene-skin shape — reuse the shape, not the code.
2. **A home for world content.** `Eat` currently exists only as an inner class inside `brain_choice_smoke.gd`. World-specific leaves and actions want a folder that is not `brain/`.
3. **A tuning-constants block.** Needs and obligations already score on one scale, and nothing says what a lord's order is worth in units of tiredness. Two scoring domains already coexist in the test suites (`hunger`, 0–60, against `400 - distance`, in pixels) and will meet the moment an obligation sits beside a spatial action. Do this *before* authoring a second domain — retrofitting a numeric scale across authored content is the expensive kind of change. **The world curves below are this block's first real consumer** — build the block against them, not speculatively.
4. **Two world curves on the clock: `urge_to_work` and `urge_to_be_social`.** See below.
5. **The reconsider poke**, plus `Action.interrupt_threshold`. See below.
6. **The provider index**, derived once per tick.
7. **Emit.** One character's unmet need becomes another's obligation, guarded by `owes_anything_about`.
8. **Expiry** (FR103). The world sweeps obligations on its own clock. This is also what stops an actor re-picking and re-abandoning an obligation nobody can serve.
9. **A scene skin** over the headless world, in simple 3D. See below.

### Reconsidering — what pokes a decision, and what resists one

`act(delta)` already re-decides in three situations, and between them they cover everything *self*-caused: nothing active, the body reported finished, or the body reported impossible (which nulls the action, so the next tick decides). What is missing is re-deciding while the work is still going and still perfectly possible, because **the world** changed — a fright, a passer-by, the flour arriving.

**Build a staggered sweep, and one seam.** Each character carries a phase offset; the world re-decides a slice of the population per tick, everyone within N seconds. Bounded, predictable, and it cannot leave anyone frozen.

The seam is a single method — `world.reconsider(who)` — and it is the **only** place `decide_action()` is ever poked from. The sweep calls it. When event-driven reconsidering is earned later (a stat crossing, an arrival, an obligation landing), those events call the same method and nothing else changes. Do **not** build a dirty flag yet: the flag is the part carrying a design commitment, and the sweep works without one.

Do not pick the cadence first. Settle the resistance rule below, then set the cadence to suit it — without resistance, a faster poke makes behaviour worse rather than more responsive.

#### `Action.interrupt_threshold`

**The action declares how hard it is to interrupt.** A float on `Action`, defaulting to `0.0`. While an action is the incumbent, its score is raised by its threshold for that decision, so a challenger has to clear the threshold to take the job.

- `flee` leaves it at zero and is dropped the instant anything outscores it. Fleeing must never be sticky.
- `mill the grain` sets it high and rides out a passing distraction.
- The number reads as *how hard is this to interrupt*, which is what an author is actually thinking when setting it. Denominated in the tuning block's units like everything else.

**The incumbent is passed in as a parameter — never read off the subject.**

```gdscript
func choose_action(who, from: Array[Action], incumbent: Action = null) -> Action:
	return highest_scoring(who, determine_available_actions(who, from), incumbent)

func highest_scoring(who, from: Array[Action], incumbent: Action = null) -> Action:
	...
	var value := score(who, action)
	if action == incumbent:
		value += action.interrupt_threshold
```

Four things this gets right, and each one rules out an alternative that looks simpler:

- **Judgment stays in `DecisionBrain`.** Putting the comparison in `Character.decide_action()` would put scoring policy in the facts class — against the split the refactor established, where what someone knows, owes and pursues are facts on the character, and which one wins is judgment in the brain. `Character` supplies `active_action`, a fact it owns, and holds no rule.
- **Opacity survives.** `DecisionBrain` still never reads a field off its subject (`decision_brain.gd:19`).
- **Nesting is correct by construction.** Had `choose_action` reached for `who.active_action` itself, every nested `Choice` would judge its inner options against the *top-level* pursuit — picking which inn would be scored against "go eat." Each level passing its own incumbent makes that impossible. `Choice` passes nothing today, which is right, and when Choice-level commitment is earned it passes its remembered pick through the same parameter — no new machinery.
- **"Still available to defend" is free.** `determine_available_actions` runs first, so an action gated shut is not in the list to receive the bonus. It cannot hold on because it was winning a moment ago.

No new class, one optional parameter, one line of arithmetic.

Why this matters beyond twitchiness: the oscillation that actually bites is a score that **falls as you pursue it** — eating drives hunger down, so mid-meal `eat` weakens, something else takes the lead, and the character stalls at the satisfaction threshold. That is a livelock, not a cosmetic wobble.

**Proof scene:** two actions whose scores cross mid-pursuit. With `interrupt_threshold` at zero, show the character stalling — the failure has to be *visible* first, or the constant is unfalsifiable. Then raise it and show the meal finishing. A second case with `flee` at zero proves the escape hatch still opens instantly.

**Not fixed by this: the same shape one level down.** `choice.gd:77` re-picks from scratch on every call, at every depth. Static terms are safe (preference, an inn someone would rather avoid), and distance is self-*reinforcing* — walking toward an inn raises that inn's score. The unsafe term is one that falls as *others* pursue it, i.e. how crowded somewhere is, which `urge_to_be_social` makes worth scoring. Making a `Choice` sticky means remembering which option it picked, and a `Choice` is shared by every character so it cannot hold that itself — the memory would have to be a fact on the character written through `set_stat`, keyed by stable Action identity. That is the open question already listed below. **Watch for it; do not pre-build it.**

### World curves — the day shapes behaviour without commanding it

The world clock exposes two curves over time of day. They are **world facts**, read by scoring functions, and they push everyone at once without telling anyone what to do.

- **`urge_to_work`** — rises with the sun, amplified while it's up, winding down through the late afternoon.
- **`urge_to_be_social`** — low through the working day, spiking toward evening as work falls off. The two should cross, not merely alternate.

This is the same idea as re-derivation applied to the day: nobody is scheduled, nobody holds a timetable. A farmer heads out at dawn because `work the field` starts outscoring everything, and drifts to the inn at dusk because it stops. Interruption stays free.

Constraints:

- **Curves live on the world, and `brain/` must not learn about them.** World-content actions in the folder from item 2 close over the world and read the curve; `Character` gains no world reference. `Action.score` already takes the subject and ignores it — that seam is what makes this a value change, not a call-site change.
- **A curve multiplies, it never gates.** It is weight, not permission — the same rule as channels (FR12/FR102). A curve at zero must never be the reason nothing is choosable.
- **Curve output shares the tuning block's scale.** Whatever `urge_to_work` returns has to sit next to `hunger` and `400 - distance` honestly. This is precisely the collision item 3 exists to prevent.
- **Ship the seam, then two authored curves.** A small named lookup — `world.curve("work")` — with two hand-tuned shapes behind it. Not a curve-authoring system.
- **Proof scene:** run a day with no needs and no obligations at all, and show the population's chosen actions shifting from work to social purely because the clock moved.

### The verb seam — how decisions reach animation without touching the brain

`behavior/orchestrator.gd`, `state.gd` and `sequence_state.gd` already exist from the sandbox HSM work. **Do not fuse that with `brain/`.** They are two machines doing different jobs: the decision layer is re-derived, holds nothing, runs headless, and answers *why*; an animation layer is inherently stateful — continuity, transitions, blend times — and answers *what does the body look like right now*. Re-derivation is deliberately wrong for the second: a blend that is halfway through cannot be re-derived. Merging them drags engine state into `brain/` and costs the headless constraint.

The bridge is one field: **every leaf Step declares a verb.** `WalkTo` reads `&"walking"`, an eat leaf `&"eating"`, milling `&"working"`. The skin polls the active leaf's verb and runs its own FSM off it. The brain never learns an animation exists, and the skin-reads-never-writes rule holds. This generalises what `doing_label()` already does — why-plus-what for a human reader; the verb is the same readout for a machine.

**Land the seam this session, keep the FSM dumb.** The field costs nothing now, but retrofitting a verb onto every authored leaf later is the same expensive shape as retrofitting the numeric scale, which is why item 3 exists. The FSM itself stays "verb → play clip," no blending — all the placeholder assets deserve. If the seam turns out to be wrong it is one field to delete.

### Scene skin — stylized 3D, real enough to read

Surface layer only. Its whole job is that **waking up from a bed and walking to the farm reads as a thing that happened**, not two log lines.

**On the look — this is a hard requirement, not a preference.** Stylized low-poly with flat or gradient shading, in the Synty/Quaternius idiom. **Not voxel. Not Minecraft. No cube heads, no blocky proportions.** "Placeholder" here means *unfinished*, not *ugly* — the whole reason this scene exists is to find out whether a morning reads as a morning, and blocky programmer-art answers that question wrong in both directions: it makes good behaviour look broken, and it makes you stop trusting your own eyes on the thing you are actually testing.

- **The constraint that decides quality is coherence, not polygon count.** One pack by one author reads as intentional; six best-of-breed models from six authors read as garbage no matter how good each one is. Pick a single source for the buildings and props, and match the character to it. Reject an asset that is *better* but doesn't match.
- **Sources, in order of preference:**
  - **Quaternius** — CC0, stylized low-poly, and crucially has **animated rigged characters** as well as modular medieval buildings. Start here; it is the best free match for the target look.
  - **Poly Pizza** — aggregator, filter to CC0. Good for one-off props (a bed, a millstone) once the pack is chosen.
  - **Kenney** — CC0 and reliable, but the medieval sets skew chunky/toy. Fine for a ground plane or terrain blockout, weak for characters. Do not let it set the art direction.
  - **Mixamo** — free rigged animations if Quaternius's built-ins are too thin for the verb list. **Adobe licence, not CC0** — record that distinction accurately in `CREDITS.md` rather than lumping it in.
  - **Synty POLYGON** — paid, and the actual reference for this look. Not to be bought by a delegate; flag it to the author as the escape hatch if the free options can't carry the scene.
- Prefer `.glb`. Record source, author, and licence for **each** asset in a `CREDITS.md` beside them, **at the time of download** — reconstructing provenance later is miserable and usually fails.
- Minimum set to make the two proofs watchable: a bed, a small building, a field, a mill, a ground plane, and a character that is **rigged and can face a direction** — the character is the hard requirement, since a static capsule makes the verb seam untestable.
- **This is its own scene, and it does not touch the hex board.** The board stays data-first with its 2D skin; nothing about this skin is a step toward replacing it.
- **The skin reads the world and never writes to it.** If a proof passes headless but fails in the scene, or vice versa, the coupling leaked — that is a bug in the skin, not the world.
- Everything in items 1–8 must still run under `--headless --script` with the skin absent entirely.

### The scene — what actually happens in it

The scene and the headless proofs run **the same world object**. The 3D is a skin over it, never a second simulation. If the scene needs its own sim, the coupling leaked.

#### The cast — five, and each earns its place

- **Three farmhands.** They work the field, get hungry, and drift to the inn at dusk. Deliberately doing triple duty: they are the labour `urge_to_work` acts on, the hunger that starts the demand chain, and the crowd that makes `urge_to_be_social` visible. One actor type covering three jobs is why the cast stays small enough to debug.
- **A miller.** Grinds grain into flour, and carries the duration-based work case — `grinding_progress` on the mill, per the rule that duration lives on the thing being worked, not on a Step.
- **An innkeeper.** Bakes bread and serves it. `bake bread` is gated on having flour, which is the no-`Wait`-step proof standing on its own feet: she sweeps, dozes and serves, and baking simply starts winning when flour arrives.

#### The chain, three deep on purpose

Hungry farmhands eat bread → the inn's bread stock falls → the innkeeper needs flour → **emits to the miller** → the miller's grain runs low → **emits to the farmhands**. Consumption at one end drives work at the other, and no one scripts anyone.

**Three deep is the point.** A two-actor chain is a plausible special case; a chain that passes through a third link with no new machinery is what proves it is a mechanism. Every emit is guarded by `owes_anything_about`.

#### The day arc

Dawn — `urge_to_work` rises, beds empty, people head for the field. Morning — the field's progress stat climbs. Midday — hunger crosses on the farmhands and they eat, which is what quietly pulls flour demand down the chain. Dusk — `urge_to_work` falls as `urge_to_be_social` spikes, and the same people converge on the inn; **that convergence is the curve proof, visible with no need or obligation involved.** Night — sleep wins.

The interruption proof rides on top: a fright while the miller is mid-delivery. He flees (protected, `interrupt_threshold` 0), the flour is **still owed**, and when the fear drains he resumes from wherever he is standing. Nothing unwinds.

#### Cut from the scene, and not arbitrarily

- **Wages and money — out, author's call.** Neither proof needs them: the chain is proven by flour moving, not coin. Paying for things drags in a whole exchange subsystem (who holds coin, does being broke gate eating, what happens when the inn won't serve). This session earns the substrate.
- **The farm manager — out, and this is the subtler one.** A manager telling a farmhand to plough is *already free*; it is the same `assign_action` emit as everything else. What is not free is that a manager is a **goal-emitting superior**, and "does a goal emit onto its owner or onto subordinates" is an open question below, deferred because delegation is a third cascade path §Cascade does not currently describe. The manager is not cut for being hard. It is cut for being the deferred thing wearing an innocent costume.

#### Build it brick by brick too

Five actors, a three-deep chain and a full day arc is too much to debug as one drop. Innkeeper and miller alone first, then the farmhands, then the day.

### Two things to prove, and they are the whole point

1. **A demand chain completes across two characters** without either scripting the other — the innkeeper's need for flour becomes the miller's obligation, and the innkeeper never waits on a callback, only on a world fact.
2. **The chain survives interruption at every level.** Scare the miller mid-delivery. Nothing should need unwinding.

If the second one requires new machinery, re-derivation didn't hold — and it is far better to discover that on a two-actor scene than a fifty-actor one.

---

## Decided already — do not re-open

- **Obligations compete as peer candidates**, they don't bias. FR9/FR13's contradiction was resolved in FR13's favour; FR100 now defines the obligation.
- **Goal vs obligation.** A *goal* is standing intent that tilts many actions and never completes. An *obligation* is one dischargeable job. A goal may emit obligations, and that emit is the same operation as the cross-actor emit above — so goals add no new machine when they arrive.
- **The queue is legitimate storage.** The test is regenerability, not persistence (FR101).
- **Nesting is fine.** FR1 means one *mechanism*, not one evaluation.
- **Channels set weight, never permission** (FR12, FR102). Out of scope this session; when they come, `Action.score` already takes the subject and today ignores it — the seam exists, so implementing channels replaces a value, never a call site.
- **The protected set is by category, never instance** (FR86). A generator narrowing fifty inns to six is a legitimate cost optimisation; leaving the category with no instance at all is not.

## Explicitly not in scope

Channels, trust, promotion, the board, the player. **Money, wages and any exchange mechanic** — decided 2026-08-04; the demand chain is proven by flour moving, not coin. **Goals and any superior-emits-to-subordinate delegation**, which is why the scene has no farm manager. This session earns the substrate; the influence layer sits on top of it later.

## Open, and worth settling while building

- **Who owns the identity of generated Actions?** `brain_choice_smoke.gd` memoises an Action per inn inside the test file so identity stays stable. Obligations solved this for assigned work via `about`; ordinary generated options still rely on test-side discipline. The world should own it. **This is now the blocker on Choice-level commitment** — see the `interrupt_threshold` section. It stays open, but it has stopped being cosmetic.
- **Two questions if goals get built** (not this session): is a goal a *lump* — an Action whose body never finishes, which works with today's types for free but makes all its sub-actions lose together — or a true *tilt*? And does it emit onto its owner (decomposition) or onto subordinates (delegation)? The latter is a third cascade path §Cascade doesn't currently describe, since it says intent propagates by changing the state people react to.

---

## Verification — not negotiable

- Every new piece gets a **miniature headless proof scene** before it joins anything larger. `tests/brain_*_smoke.gd` are the pattern, including the `EXPECTED_CHECKS` guard that catches a suite crashing while still printing OK.
- All nine existing suites stay green: `brain_smoke`, `brain_steps_smoke`, `brain_choice_smoke`, `sandbox_smoke`, `board_smoke`, `placement_smoke`, `settlement_smoke`, `terrain_smoke`, `town_smoke`. `sandbox_smoke` breaking means something leaked across the wall from the old implementation.
- Run: `Z:/Godot/Godot_v4.4-stable_mono_win64/Godot_v4.4-stable_mono_win64_console.exe --headless --path tkyds-game --script res://tests/<name>.gd`
- New `class_name` scripts need a reimport before they resolve: `--headless --path tkyds-game --editor --quit`. Expect the first pass to print parse errors while the class cache rebuilds; run it twice.
- **Everything must run under `--headless --script`.** This constraint is why the Beehave addon was rejected. `brain/` currently has zero engine coupling — every class extends `RefCounted`, nothing touches `Node`, physics, or `Area2D`. Do not lose that. The 3D scene skin is the **only** exception, and it is one-directional: it reads the world, the world does not know it exists. Delete the skin and every suite still passes.
- **Check for a duplicate `class_name` before blaming a reimport.** `sandbox/walk_to.gd` and `brain/walk_to.gd` both declared `class_name WalkTo`. Godot never reports this — one silently wins, and which one depends on scan order. A reimport flipped it and two suites failed with a constructor from the wrong class. The sandbox one is now `SandboxWalkTo`.

## Working agreements that produced this code

- **Interview before implementation**, one focused question at a time, sign-off before code.
- **No class per noun.** `Scorer`/`Ranker`/`Scored` were built and deleted the same hour; three jobs were meant to be three *methods*. `DecisionBrain` had the opposite problem — one class doing two jobs — and was split. Watch for both.
- **Build the seam, ship the simplest thing behind it.** `stat()`/`set_stat()` over a plain Dictionary is the live example.
- **When a need seems to require branching or waiting, check first whether it's really a multi-step sequence** before reaching for cross-actor machinery.
