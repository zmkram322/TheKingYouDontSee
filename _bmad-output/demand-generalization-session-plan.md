# Demand Generalization — Session Plan

*Prep + work order for a fresh session, not the session itself. Written 2026-08-02, same day as the sandbox work it follows up on. Companion to the sandbox landing doc (link below) and structurally modeled on `fable-refactor-brief.md` / `hex-board-prd-edit-session-plan.md` — same idea: vet what's unverified, then build the smallest proof, then report what didn't hold.*

---

## Why this exists

Two features shipped this session in `tkyds-game/sandbox/`: a per-villager goal queue (front-insert for self-directed interrupts, back-insert for externally-assigned obligations) and a signal-driven proximity greeting. Working through the second one surfaced a third, bigger idea that did **not** get built: generalize `sim/demand.gd` — already proven for food — into the uniform way *every* need decomposes, including movement itself as a phase, instead of a Goal-builder special case.

That idea is well-motivated (it's literally what `Demand`'s own header comment claims: *"that's the whole engine"*) but it hasn't been pressure-tested the way anything else that's reached the PRD here has been — FR1 only got rewritten after a spike forced it concrete; the hex board's occupied-capacity claim got a party-mode architecture pass before it touched the PRD. This idea has the same shape: an assertion ("this reuses existing X") plus two named, unsolved technical blockers. It deserves the same bar before more gets built on top of it.

**This session is sandbox-layer engineering, not a PRD-writing pass.** Nothing here should touch `prd.md` directly — if the proof succeeds and the shape holds, *that's* the trigger for a future PRD-edit session, not this one.

---

## 0. Read first

- **The landing doc — full detail on what shipped and where this idea landed:** https://claude.ai/code/artifact/72b3ab95-3a8a-40e1-9ca7-fd6ff199c37f (§3 "Everything as a demand" is the relevant section; fetch it, don't re-derive it from scratch)
- `tkyds-game/sim/demand.gd`, `tkyds-game/sim/simulation.gd` — the existing phase-machine this generalizes (`_step_food` is the richest example, and the direct analog for the proof below)
- `tkyds-game/behavior/goal.gd`, `tkyds-game/sandbox/sandbox_world.gd` — the goal queue this session built; `_build_goal`'s `already_there`/`WalkTo` handling is exactly what this pass is trying to eliminate
- `tkyds-game/sandbox/README.md` — the headless-testability discipline (no scene, no physics, `--headless --script` must keep working) that already shaped one rejection this session (Area2D for proximity) and is binding here too

---

## Step 0 — Scope call (solo, fast, before vetting)

Confirm out loud: **this pass proves the shape on food alone.** Sleep, safety, and social contact do not get demand-ified this session regardless of how well the proof goes — that's explicitly out of scope (§ below). Say it before Step 1 so vetting doesn't quietly expand into "let's also figure out how rest becomes a demand."

---

## Step 1 — Vet the two real blockers

Lighter than the hex-board four-agent roundtable — this is a scoped technical question, not a kingdom-scale design call, so a solo pass (you, or a single architect-agent pass if you want a second read) is probably the right weight. Use the full party only if the tick-model question turns out to be genuinely contested, not by default.

**a) Tick-model reconciliation.** `Simulation.advance_one_tick()` steps every open demand exactly one hop per discrete tick — no phase has ever taken real time. `SandboxWorld.advance(delta)` is continuous, and a `WalkTo` phase needs to take actual seconds. Candidate shapes worth weighing, not a prescribed answer:
   - A phase can itself *be* an `Activity` (or wrap one) — `Demand.phase` transitions to `"walking_to_inn"`, and the demand doesn't advance past it until an attached `WalkTo`'s `finished` flips, the same way `Goal.plan` already sequences local steps.
   - Or: `Demand` stays instant-per-phase as today, and movement stays a *separate* pre-step the `Goal` layer inserts before attaching to the demand (this partially gives up the "movement is just a phase, no Goal-builder special case" win — say so plainly if this is where it lands).
   - Or something else — this is the actual open question, not a leading one.

**b) `Demand`/`Simulation` decoupling.** `Demand`'s fields exist independent of `Simulation`, but the `_step_X` resolvers and demand-list bookkeeping (`_new_demand`, `_step_all_demands_one_hop`, `_has_open_food_demand`, etc.) are methods on `Simulation`, written against its own actor list and its own `StatStore` instance — not shared with `SandboxWorld`'s. Find the smallest real move: does a demand-stepping capability get extracted into something both engines can own an instance of, or does `SandboxWorld` end up holding a `Simulation`-shaped sub-object for just this purpose? Don't drag the whole 800-line `Simulation` class along for one resolver.

**c) Scope-of-uniformity check.** Does *every* need become a `Demand`, even trivial single-phase ones (`rest_home`'s entire future shape might just be one phase — go home, rest, done) — accepting the object overhead for consistency — or does the eligibility precedent apply here too (ship the capability, only actually reach for it where a need demonstrably grows branches or a cross-actor hop)? This session's proof only needs food either way, but the answer shapes whether `shelter_home`/`greet_passerby` are expected to convert later or stay plain `Activity`-backed indefinitely.

Write down what you land on for (a) and (b) before touching code — this is the same discipline as the refactor brief: decide the model, then build against it, don't improvise the architecture mid-implementation.

---

## Step 2 — Decide spike-or-not

If (a) turns out genuinely contested (more than one shape looks defensible and it's not obvious which), scope a small throwaway spike the way `fable-spike-brief.md` did: smallest scene that forces the real question — probably just Berta, hunger, and one demand cycle, headless, no UI. If one shape is clearly right once you've thought it through, skip the spike and build straight.

---

## Step 3 — Build the food proof

**Goal:** `eat_at_inn` becomes demand-backed end to end, including the walk, without breaking anything already shipped.

a) **Resolve the tick-model mismatch** per whatever Step 1(a) landed on.

b) **Port or share the minimum of `Demand`/`_step_food`** needed for `SandboxWorld` to open, step, and read demands — per Step 1(b)'s answer. Don't touch `Simulation`'s own behavior in the process; it has its own tests/usage and isn't part of this proof.

c) **Fold movement into the phase chain.** Replace `_build_goal`'s mechanical `already_there`/`WalkTo` handling for `eat_at_inn` specifically with a phase (`DecideWhereToEat()` or similar) that decides the destination and triggers the walk itself — the same way `find_merchant` already decides *which* merchant. This is the concrete thing that proves the idea's core claim; if it turns out movement can't cleanly live inside a phase, that's a finding worth reporting exactly like a failed hypothesis anywhere else in this project's history, not a thing to force.

d) **A demand-aware `Activity`.** Something whose `finished` polls `Demand.satisfied` instead of counting a duration — the piece originally sketched two sessions ago (`AwaitDemand` or similar naming).

e) **Verify.**
   - `tests/sandbox_smoke.gd` stays green — same first-choice assertions, unchanged.
   - A new ad hoc script (same pattern as this session's `verify_queue.gd`/`verify_greet2.gd`) proving: choosing `eat_at_inn` produces a real `Demand`, the demand actually steps through its phases (including the walk), and hunger only drops when the demand resolves — not when a fixed `Perform` duration elapses.

---

## Constraints (carried over, non-negotiable)

- **Headless testability stays intact.** If this work requires `SandboxWorld` to depend on a scene, a physics tick, or anything `tests/sandbox_smoke.gd` can't exercise under `--headless --script`, that's a regression, not a tradeoff to accept quietly.
- **No new engine.** This is a generalization of `Demand`, not a second decomposition system running alongside it.
- **Ship the seam, defer the system** — same discipline as eligibility. Build what food needs. Don't build a generic "any need can become a demand" framework speculatively in the same pass unless Step 1(c) explicitly calls for it.
- Every invented constant goes in `sandbox_tuning.gd`, same as everything else this codebase has shipped.

---

## Out of scope this pass

- Sleep, safety, or social-contact demand-ification (shelter_home, greet_passerby stay exactly as they are).
- The "Goal" naming collision (queue-item vs. PRD's FR9/FR10 sense) — real, not blocking, pick up separately if there's time.
- Provider-side scoring (the innkeeper choosing to serve via their own `UtilityBrain` pass, rather than resolving procedurally) — named as a real follow-on in the landing doc, not required for this proof to succeed.
- Any `prd.md` edits.

---

## What to decide and report

1. Did movement actually fold cleanly into a phase, or did it need to stay a separate pre-step? Either answer is valid — report which and why.
2. What the tick-model reconciliation actually cost — how much of `Simulation`/`Demand` needed touching versus how much was additive.
3. Whether the food proof changes your read on Step 1(c) — now that one need is actually demand-backed end to end, does "everything becomes a demand" still look right, or does it look like overkill for the simple cases?
4. Anything about `Demand`'s current shape that turned out to be `Simulation`-specific in ways that weren't obvious until you tried to share it.

---

## Resume command

> "Let's pick up the demand-generalization work. Read `_bmad-output/demand-generalization-session-plan.md` in full, fetch the landing doc it links (§3 especially), then start at Step 0."
