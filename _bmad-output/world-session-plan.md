# Session Plan — Build a World

**Written** 2026-08-03, branch `poc-v2`, at the close of the session that critiqued `tkyds-game/brain/` and applied the resulting fixes.
**This is Part 2.** Part 1 is closed — its rulings are in `_bmad-output/brain-critique-decisions.md` and are not up for re-litigation. Start here, cold.

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

## What to build, in order

Brick by brick, each with its own miniature proof scene before it joins anything larger.

1. **A world object.** Owns places, a clock, and the list of characters. Characters do not know about it; generators and leaf Steps close over it. `sandbox/sandbox_world.gd` is prior art for the headless-engine/scene-skin shape — reuse the shape, not the code.
2. **A home for world content.** `Eat` currently exists only as an inner class inside `brain_choice_smoke.gd`. World-specific leaves and actions want a folder that is not `brain/`.
3. **A tuning-constants block.** Needs and obligations already score on one scale, and nothing says what a lord's order is worth in units of tiredness. Two scoring domains already coexist in the test suites (`hunger`, 0–60, against `400 - distance`, in pixels) and will meet the moment an obligation sits beside a spatial action. Do this *before* authoring a second domain — retrofitting a numeric scale across authored content is the expensive kind of change.
4. **The reconsider poke.** The world advances characters and pokes `decide_action()` when something happens — a stat crossing, a fright, someone arriving. This is the missing world layer, not a defect in the brain, but the interruption proof cannot be written until it exists. Stagger/jitter it rather than re-deciding every actor every frame.
5. **The provider index**, derived once per tick.
6. **Emit.** One character's unmet need becomes another's obligation, guarded by `owes_anything_about`.
7. **Expiry** (FR103). The world sweeps obligations on its own clock. This is also what stops an actor re-picking and re-abandoning an obligation nobody can serve.
8. **A scene skin** over the headless world.

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

Channels, trust, promotion, the board, the player. This session earns the substrate; the influence layer sits on top of it later.

## Open, and worth settling while building

- **Who owns the identity of generated Actions?** `brain_choice_smoke.gd` memoises an Action per inn inside the test file so identity stays stable. Obligations solved this for assigned work via `about`; ordinary generated options still rely on test-side discipline. The world should own it.
- **Two questions if goals get built** (not this session): is a goal a *lump* — an Action whose body never finishes, which works with today's types for free but makes all its sub-actions lose together — or a true *tilt*? And does it emit onto its owner (decomposition) or onto subordinates (delegation)? The latter is a third cascade path §Cascade doesn't currently describe, since it says intent propagates by changing the state people react to.

---

## Verification — not negotiable

- Every new piece gets a **miniature headless proof scene** before it joins anything larger. `tests/brain_*_smoke.gd` are the pattern, including the `EXPECTED_CHECKS` guard that catches a suite crashing while still printing OK.
- All nine existing suites stay green: `brain_smoke`, `brain_steps_smoke`, `brain_choice_smoke`, `sandbox_smoke`, `board_smoke`, `placement_smoke`, `settlement_smoke`, `terrain_smoke`, `town_smoke`. `sandbox_smoke` breaking means something leaked across the wall from the old implementation.
- Run: `Z:/Godot/Godot_v4.4-stable_mono_win64/Godot_v4.4-stable_mono_win64_console.exe --headless --path tkyds-game --script res://tests/<name>.gd`
- New `class_name` scripts need a reimport before they resolve: `--headless --path tkyds-game --editor --quit`. Expect the first pass to print parse errors while the class cache rebuilds; run it twice.
- **Everything must run under `--headless --script`.** This constraint is why the Beehave addon was rejected. `brain/` currently has zero engine coupling — every class extends `RefCounted`, nothing touches `Node`, physics, or `Area2D`. Do not lose that.
- **Check for a duplicate `class_name` before blaming a reimport.** `sandbox/walk_to.gd` and `brain/walk_to.gd` both declared `class_name WalkTo`. Godot never reports this — one silently wins, and which one depends on scan order. A reimport flipped it and two suites failed with a constructor from the wrong class. The sandbox one is now `SandboxWalkTo`.

## Working agreements that produced this code

- **Interview before implementation**, one focused question at a time, sign-off before code.
- **No class per noun.** `Scorer`/`Ranker`/`Scored` were built and deleted the same hour; three jobs were meant to be three *methods*. `DecisionBrain` had the opposite problem — one class doing two jobs — and was split. Watch for both.
- **Build the seam, ship the simplest thing behind it.** `stat()`/`set_stat()` over a plain Dictionary is the live example.
- **When a need seems to require branching or waiting, check first whether it's really a multi-step sequence** before reaching for cross-actor machinery.
