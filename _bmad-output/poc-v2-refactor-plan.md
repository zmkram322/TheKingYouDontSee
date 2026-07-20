# Runbook: Pressure-test → Extract the Demand-Resolver Node (two fresh sessions)

## Context

Across POC v2 slices 1 → 3b (`poc-v2` branch) we proved one recursive primitive —
*a demand hits a resolver that either satisfies it or emits the child demand it
needs and waits* — can bootstrap and sustain a whole economy (food → labour →
money) from hunger alone, with zero world-triggers. Four concrete resolvers now
exist (`_step_food`, `_step_role`, `_step_buy`, `_step_employment` in
`tkyds-game/sim/simulation.gd`), the last of which (employment) is the first
*two-sided* shape.

The loop is proven, so a generalized node is finally **earned**. But the archived
build died from abstracting *before* the loop was proven, so we move carefully:
**(1)** pressure-test the model's spirit with a party before touching code, then
**(2)** extract behaviour-preservingly, from the concrete cases only. The spirit
is captured in `_bmad-output/poc-v2-system-spirit.md` (tenets T1–T10 + §7 open
tensions). Crucially, food is only the *test load*: the real target is a general
needs-and-wants engine hosting physical/social/emotional drivers, each
bootstrapping its own economy — so the node must generalize past "an economy that
eats."

This runbook is executed across **two fresh sessions** (clean context each).
Pre-read for BOTH: `_bmad-output/poc-v2-system-spirit.md`, the project-state
memory, and `tkyds-game/sim/*.gd`.

---

## SESSION 1 — Party-mode elicitation (pressure-test the spirit)

**Goal:** attack the spirit doc's tenets; emerge with each tenet marked
**survived / broken / refined** and a set of **locked design decisions** that
constrain the refactor. Divergent session — surface options, do not converge to
code.

**Party (locked):** Cloud (architect — does the node generalize? scale?),
Samus (designer — are the seams real playable moments?), Indie (solo dev — is this
shippable / over-scoped?). Run via `bmad-party-mode`.

**Orchestration rules (Zach's non-negotiables — from project memory):**
1. Agents **surface options, do not opinionate** — 2–3 alternatives per facet,
   each with concrete shape + cost + tradeoff; a one-line soft rec is OK as a tail.
2. **Halt after every facet** for Zach's ruling. No agent ventures past a facet
   without the author's check-in.
3. Facilitator sequence per facet: frame → spawn party in parallel → present
   responses verbatim → halt → confirm the ruling → next facet.
4. **Show the spawn prompts to Zach before launching** each facet.

**Structure: tensions-first, tenet-anchored.** Each facet takes an open tension
from §7, has the party show how the load-bearing tenet(s) hold or break against
it, and surfaces alternatives. Proposed facet order (highest-leverage first;
Zach re-orders at kickoff):

1. **Does the node generalize?** (§7 #1; anchors T4 + the §3 "only five
   primitives" claim). Is "a recipe of ordered steps, each tagged `auto` /
   `player-seam`" the right shape — or what breaks it? This is the make-or-break
   facet for the whole refactor.
2. **Non-material economies** (§7 #10; anchors T7, "is the atom still one atom?").
   Do social/emotional drivers (status, trust, **loneliness→companionship**) fit
   the same primitives when there's no good to transfer?
3. **Multi-driver arbitration** (§7 #9; anchors T9). When drives compete, is the
   choice an emergent property of competing demands, or a dedicated behavioural
   state machine? *(The single biggest unknown past one driver.)*
4. **Player-seams vs. the tick** (§7 #3; anchors T4). Does the sim pause for
   player input (turn-like) or keep flowing (deferred choices)? Load-bearing for
   feel.
5. **Scale + aggregate legibility & attribution** (§7 #4 + #11; anchors T3, T10).
   Does one-hop-per-tick survive hundreds of actors, and how do we honestly
   compute "output +15% because of decision X"?
6. **Allocation under scarcity** (§7 #2). Is who-gets-the-scarce-thing a
   first-class node concern or a policy?
7. **Cleanups** (§7 #6/#7/#8; anchors T6/T8): standing/recurring demands,
   conservation-vs-injection, right-sizing labour (the production-manager policy).

**Output (the handoff):** write `_bmad-output/poc-v2-elicitation-outcome.md` —
per-tenet verdict (survived / broken / refined, with the reasoning) + the locked
decisions (node shape, primitive set, arbitration approach, seam/tick model,
scale posture). This doc is Session 2's brief.

---

## SESSION 2 — The extraction refactor (behaviour-preserving)

**Goal:** collapse the four bespoke resolvers into one generalized, policy-aware
node, per the Session-1 decisions — **without changing observable behaviour** and
**without building any new driver/economy** (those come later, on the new base).

**Guardrails:**
- **Golden-run regression is step 0.** The sim is deterministic (no RNG — no
  `Math.random`/`randi` in the engine; staggered fixed hunger seeds; fixed actor
  order), so a headless run is byte-reproducible. Capture a baseline BEFORE
  refactoring and require the refactored engine to reproduce it exactly.
- **Extract from the four concrete resolvers only.** If a primitive isn't used by
  food/role/buy/employment, it isn't built (§6 scar discipline).
- **One resolver at a time**, re-verifying golden after each.

**Steps:**
1. **Capture golden baseline.** Add a throwaway `SceneTree` harness (like the
   `test_sim.gd` pattern used this build) that runs `Simulation.new()` for a fixed
   tick count and dumps the full `log_lines` + final actor state. Save output as
   the regression fixture. Godot binary:
   `Z:\Godot\Godot_v4.4-stable_mono_win64\Godot_v4.4-stable_mono_win64_console.exe`
   (refresh class cache with `--headless --editor --quit` after adding
   `class_name` files; run with `--headless --script res://<harness>.gd`).
2. **Name the primitives** as reusable building blocks pulled from the four
   resolvers: *match-a-provider*, *emit-child-and-wait*, *priced-transfer*,
   *transform*, *two-sided-match* (final set per Session 1).
3. **Introduce the generalized node** (shape per Session 1 decision): a `Demand`
   carries an ordered **recipe** of steps; each step has a kind (one of the
   primitives) and a **policy** (`auto` | `player-seam`). The engine gains one
   generic step-walker that replaces the four `match d.kind` state machines.
   Likely files: `sim/demand.gd` (recipe/step/policy structures), a new
   `sim/steps.gd` (the primitive implementations), `sim/simulation.gd` (generic
   walker replacing `_step_food/_role/_buy/_employment`).
4. **Re-express each demand kind as a recipe** over the primitives — food, then
   role, then buy, then employment — verifying golden after each one. Keep
   `advance_one_tick`'s ordering (hunger → employment-seek → willingness-drain →
   production → one-hop step) intact.
5. **Wire the policy tag as the seam hook**: `auto` resolves as today; add a stub
   path for `player-seam` (no player UI yet — just the seam existing and
   defaulting to auto) so the extensibility the north star needs is real.
6. **Confirm & play.** Golden regression matches tick-for-tick for all four kinds;
   boot the UI (`--path ... --quit-after 5` clean, then a real run) and play a few
   cycles to confirm it still behaves.

**Explicitly out of scope for Session 2:** new drivers (social/emotional),
arbitration/behavioural state machine, non-material economies, attribution/
dashboards, player-seam UI. Session 2 only *builds the foundation* that hosts
them.

**Verification:** golden headless run reproduces the pre-refactor baseline
exactly for all four demand kinds; UI boots clean and plays; no dangling refs.

---

## Session mechanics — how the "fresh sessions" hand off across `/clear`

A fresh session starts **cold**: it auto-loads `MEMORY.md` but NOT this
conversation. So every handoff artifact must be **committed to disk before the
`/clear`** — anything only in context is lost at the clear. The `/clear`s are
what keep each session's context clean (elicitation divergence never leaks into
the refactor); the committed docs are the memory that survives them.

**Housekeeping — THIS session, immediately after this plan is approved (before any
`/clear`):**
- Save this runbook to `_bmad-output/poc-v2-refactor-plan.md` and commit on
  `poc-v2`.
- Add a one-line pointer in project memory (`MEMORY.md` + project-state file) that
  says: "Next = Session 1 elicitation; start from `poc-v2-refactor-plan.md`."
- Only after this is committed is the first `/clear` safe.

**Then the flow:**
1. `/clear` → **Session 1.** Cold load: spirit doc + this runbook + `sim/*.gd`.
   Run party mode. Before ending, commit `_bmad-output/poc-v2-elicitation-outcome.md`.
2. `/clear` → **Session 2.** Cold load: spirit doc + runbook + **elicitation
   outcome** + code. Do the refactor against the golden baseline. Commit.

(The kickoff for each fresh session can just be: "read the memory pointer / the
refactor plan and begin the next session.")
