# Session Plan — Critique the Brain, then Build a World

**Written** 2026-08-03, branch `poc-v2`, at the close of the session that built `tkyds-game/brain/`.
**Two parts, run in order.** Part 1 is a party-mode critique that must finish before Part 2 is planned in detail, because Part 1 can change what Part 2 builds.

---

## Inputs

| What | Where |
|---|---|
| System summary + diagrams | https://claude.ai/code/artifact/bd07c874-f6ab-4d0a-a178-90426b33a8f8 |
| The code under critique | `tkyds-game/brain/` — 7 files, ~330 lines |
| Proof suites (all green) | `tkyds-game/tests/brain_smoke.gd`, `brain_steps_smoke.gd`, `brain_choice_smoke.gd` |
| The contract | `_bmad-output/planning-artifacts/prd.md` — §Core Mechanical Model (L203–303), §FR (L500–545) |
| Prior art, untouched | `tkyds-game/behavior/`, `tkyds-game/sandbox/` — the implementation `brain/` was rebuilt away from |
| Session history + rejected designs | memory: `project_brain_rebuild.md`, `project_behavior_sandbox.md` |

**Read the artifact first.** It states the five invariants and, more usefully for critique, the list of machinery that re-derivation *deleted*. Most of the risk in this design is concentrated in whether those deletions were sound.

---

# Part 1 — Party-mode critique

## Purpose

Three outcomes, in priority order:

1. **Find what's wrong with it.** Adversarial, specific, and grounded in the code — not a design appreciation.
2. **Confront it against the PRD**, FR by FR, on the list below.
3. **Rule on each conflict**: does the PRD change to match where the brain landed, or does the brain change to honour the PRD? Every item gets an explicit verdict. "Both are fine" is not a verdict.

## Suggested room

Four voices, matching the roster shape that worked for the board roundtable (see `project_hex_board_build` memory):

- **Winston** (`bmad-agent-architect`) — structural soundness, coupling, the deletions.
- **Cloud Dragonborn** (`gds-agent-game-architect`) — engine reality: allocation churn, tick cost, headless testability.
- **Samus Shepard** (`gds-agent-game-designer`) — does this produce *legible* behaviour, the PRD's product-defining quality attribute.
- **John** (`bmad-agent-pm`) — owns the FR contract; must be the one who signs off on any PRD change.

## Seed critiques — do not let the room skip these

These were identified while building and are known-unresolved. They are the floor, not the ceiling.

### A. The protected set has no representation — a small regression, not an architectural one

FR86 requires *"a protected set of survival and direct interpersonal actions eligible to every actor regardless of role, faction, possession, or position, [which] cannot be excluded by an eligibility predicate."*

The prior implementation honoured this structurally: `ActionOption.eligible` left unset **meant** universally eligible (`behavior/action_option.gd`, `can_attempt`). The rebuild dropped it — `Action._init` requires an `eligible` Callable and `DecisionBrain.is_available` always calls it, so nothing prevents an author gating `flee` out of existence.

**The scoping that makes this cheap:** FR86 protects a *category* ("eat", "flee"), never an *instance* ("eat at the Green Dragon"). That set is small and fixed — perhaps ten actions — so keeping it permanently in every candidate list costs nothing, and is fully compatible with FR85 pruning everything else hard. FR85 and FR86 are not in tension; the PRD's own §Eligibility rationale (*"a peasant's decision loop would score 'seize the throne' every tick alongside 'eat bread'"*) argues **for** predicates on exactly the performance grounds the author has raised.

**Question for the room:** is the protected set a structural guarantee (unfakeable in code — e.g. unset `eligible` means universal, or an explicit `protected` marker) or an authoring convention (a lint or a test)? The PRD's wording says structural, and it is a roughly one-line change either way.

### B. Does the `Choice` generator prune behaviour, or only cost?

The Arbitration rule is *"weighting, never a checked-first gate."* A generator returning six of fifty inns has removed forty-four options that can never be outbid at any level of need.

**Counter-argument, per A:** narrowing *instances* is legitimate, because the protected thing is the category. A starving man must always be able to attempt `eat`; he is not entitled to have all fifty inns scored. So a spatial narrowing is a genuine cost optimisation, not a behaviour rule — **provided the category itself survives**.

Where it becomes a real violation is a generator that returns **nothing**, silently converting "eat" into an unavailable action for someone who is starving. `brain/choice.gd` documents the hazard; nothing prevents it.

**Question:** what enforces the line? Candidates: a generator that widens its search under need (`who.search_radius()` is already a method, not a constant, for this reason); a fallback option so the category is never empty; or making an empty generated set an authoring error rather than silent satisfaction. Also worth settling: `Choice.is_satisfied` currently returns **true** when nothing can be picked, so an empty generator reads as *"this work is done"* rather than *"this work is impossible"* — those should probably not be the same outcome.

### C. Obligations compete as Actions — this may contradict FR9

FR9: *"A goal biases the utility of a hand-authored action set; goals never script actions."*

The brain does something materially different. An assigned obligation **is an Action** that enters the candidate set and competes directly (`DecisionBrain.candidate_actions` = capabilities ∪ queue). It does not bias anything; it wins or loses on its own score.

This works well and is proven (Tam sleeping through the lord's order, in the artifact). But it is not what FR9 describes. Note also that a wrapper design closer to FR9's "biasing" shape *was* built earlier in the session and discarded for being unable to express per-item urgency.

**Question:** amend FR9 to describe competing obligations, or reshape the queue to bias rather than compete? Also settle the long-deferred **`Goal` naming collision** here (queue-item sense vs FR9/FR10's externally-installed sense) — it has been punted twice.

### D. Is the queue legitimate storage, or a second memory of intent?

The PRD is emphatic (§The atom): *"A demand is not a persistent object with its own memory... What other actors discover and pick up is a live index of which actors currently read as having an open demand, not a queue of remembered intentions."* FR84 says the same.

`DecisionBrain.queue` is literally a stored queue of remembered intentions. The defence: it holds only **externally assigned** work, which scoring genuinely cannot regenerate — which is FR10's sparse-stored-goal shape, not FR84's derived-demand shape.

**Question:** confirm the queue is FR10 storage and not an FR84 violation — and if confirmed, the PRD should say so explicitly, because the current text reads as prohibiting it.

### E. Nested decisions vs "one shared pass"

FR1: *"one shared weighted-utility pass."* A `Choice` inside a `Sequence` inside an Action's body runs a *second* scoring pass at depth, on a different candidate set. Same mechanism, but not one pass.

**Question:** is FR1 about a single mechanism (satisfied) or a single evaluation per decision (violated)? Does nesting damage the "why did they do that" legibility FR1 exists to protect — a player now has to understand two levels to understand one choice?

### F. Where do channels gate anything?

FR12 requires an installed goal's ability to clear the actor's threshold to be **gated by the channel the Player holds**. Nothing in `brain/` has any notion of a channel; `assign_action` lets anyone queue anything on anyone.

**Question:** is channel-gating a property of the assignment path (who may call `assign_action`), of the obligation's own `score`, or of a gate we haven't built? This is a genuine gap, not a conflict.

### G. Cheaper shots worth taking

- **Double evaluation:** `Choice.is_satisfied` and `Choice.advance` each call `_pick`, so the generator runs twice per tick per Choice, and the ranking twice.
- **Reference cycle:** `Character → brain → subject → Character` never frees; every headless run prints `ObjectDB instances leaked at exit`.
- **The busy-loop edge:** an Action whose gate is still true but whose body is instantly satisfied will finish-and-re-decide every single tick. Nothing detects it.
- **Shared scale:** needs and obligations now score on one axis with no tuning-constants block (the old `SandboxTune`'s role). What is a lord's order worth in units of tiredness?
- **Untyped `subject`:** buys the decoupling, costs all type safety at the seam — `who.stats.hungr` fails at runtime, never at parse time.

## Required output of Part 1

A short decisions document, in the shape the board roundtable produced:

- One line per item above: **PRD changes** / **brain changes** / **no change, and here's why the apparent conflict isn't one**.
- Any new flaws the room found, with the same verdict format.
- A concrete edit list for `prd.md` if it changes — FR numbers and replacement text, honouring the PRD's **append-only numbering** policy (new requirements take the next free number; existing FR numbers are stable identifiers).
- A concrete change list for `brain/` if it changes, sized so Part 2 isn't blocked on it.

---

# Part 2 — Build a world

**Do not plan this in detail until Part 1 has ruled.** What follows is scope and the one question that has to be answered first.

## The question that unlocks it: where do demands get emitted and awaited?

This is the real test of the architecture, and the thing `brain/` conspicuously does not yet do. The PRD's atom is:

> A demand hits a resolver each tick. The resolver either satisfies the demand or **emits the child demand it requires and waits on it**.

The brain has no emit and no wait. Everything so far is one character acting alone. A first-pass mapping to test — the room should attack it, not adopt it:

| PRD concept | Candidate expression in `brain/` |
|---|---|
| An actor's own unmet demand | Already implicit — an Action whose `score` reads the unmet stat. Nothing to build. |
| Emitting a child demand | `assign_action` on **another** character's brain — the one existing path by which work crosses actors. |
| Finding who to emit to | A world-owned **live index** of characters who currently read as able to serve — the PRD's "live index", not a stored subscription list. |
| Waiting on it | A new leaf Step whose `is_satisfied` reads a world fact ("do I have the stew?"). Waiting must be **re-derived like everything else** — never a stored "I am blocked" flag. |
| Provider chose you | The provider's own scoring pass over their queue. They may simply not do it. |

Two things to prove, and they are the whole point:

1. **A demand chain completes across two characters** without either one scripting the other — the innkeeper's need for flour becomes the miller's obligation, and the innkeeper waits on a world fact rather than a callback.
2. **The chain survives interruption at every level.** Scare the miller mid-delivery. Nothing should need unwinding.

If the second one requires new machinery, re-derivation didn't hold, and that is worth discovering on a two-actor scene rather than a fifty-actor one.

## Scope for the world

Deliberately larger than a proof scene, deliberately smaller than the old sandbox.

- **A world object** that owns places, the provider index, and the clock. Characters do not know about it; generators and leaf Steps close over it. (`sandbox/sandbox_world.gd` is prior art for the headless-engine/scene-skin split — reuse the shape, not the code.)
- **World-specific leaves**, currently homeless: `Eat` exists only as an inner class inside `brain_choice_smoke.gd`. These want a folder that is not `brain/`.
- **A blackboard**, only if the demand chain actually needs it — `Character.stats` is already one. Do not build ahead of a real need; the "brick by brick" instruction stands.
- **A scene skin** over a headless world, so the whole thing still runs under `--headless --script`. This constraint is why Beehave was rejected; do not lose it.
- **Obligation expiry**, tabled during the build: the world sweeps dead obligations on its own clock. A gate alone leaves them queued forever and the queue grows unbounded.
- **A tuning-constants block** for the shared need/obligation score scale.

## Explicitly not in scope

Channels, trust, promotion, the board, the player. This session earns the substrate; the influence layer sits on top of it later.

---

## Verification

Same discipline as the build session, and it is not negotiable:

- Every new piece gets a **miniature headless proof scene** before it joins anything larger — `tests/brain_*_smoke.gd` are the pattern, including the check-count guard that catches a suite crashing while still printing `OK`.
- `brain_smoke`, `brain_steps_smoke`, `brain_choice_smoke` stay green throughout.
- `sandbox_smoke.gd` also stays green — the old implementation is untouched, and any breakage means something leaked across the wall.
- Run: `Z:/Godot/Godot_v4.4-stable_mono_win64/Godot_v4.4-stable_mono_win64_console.exe --headless --path tkyds-game --script res://tests/<name>.gd`
- New `class_name` scripts need a reimport (`--headless --path tkyds-game --editor --quit`) before they resolve as global classes.

## Working agreements that produced this code

Worth carrying forward — they are why the rebuild is smaller than what it replaces:

- **Interview before implementation**, one focused question at a time, sign-off before code.
- **No class per noun.** `Scorer`/`Ranker`/`Scored` were built and deleted the same hour; three jobs were meant to be three *methods*. Second occurrence in two days (see the reverted demand-generalization detour).
- **Build the seam, ship the simplest thing behind it.**
- **When a need seems to require branching or waiting, check first whether it's really a multi-step sequence** before reaching for cross-actor machinery.
