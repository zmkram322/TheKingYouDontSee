---
name: Elicitation G Output — The Perception → Decision → Action Loop
status: IN PROGRESS — pre-Round-1 surfacing paused; resume in fresh session
date: 2026-05-06
elicitation_ref: prototype-completion-roadmap.md §3.7
session_inputs:
  - _bmad-output/prototype-completion-roadmap.md §3.7 (G's full framing) + §8.2 (Socratic conduct template)
  - _bmad-output/prototype-completion-companion.md §1 (code map), §2 (personas), §4.1 (elicitation checklist)
  - _bmad-output/elicitation-e-output.md (just-shipped read-side context)
  - _bmad-output/gdd.md (re-read mid-session — anchors Q1/Q3 in already-locked GDD intent)
  - memory/MEMORY.md, project_thekingdontSee.md, feedback_* memories
session_conduct: Socratic alternative-surfacing (G is first session under new conduct; one question at a time after author's mid-session feedback)
authors:
  - Author adjudication (Zach) — pre-Round-1 surfacing only; Round 1 not yet spawned
---

# Elicitation G Output — The Perception → Decision → Action Loop

## 0. Session Frame

**STATUS — IN PROGRESS, PAUSED AFTER EXTENDED PRE-ROUND-1 SURFACING.**

The pre-Round-1 author-intent step expanded substantially. What started as "your gut on Q1 (NPC intent representation) and Q3 (player command surface)" became a deep architectural surfacing that locks much of G's foundational shape *before agents are spawned at all*. Two structural reframings happened mid-session:

1. **GDD re-read.** Author asked the orchestrator to re-read the GDD before continuing. Result: GDD already substantially answers Q1's "reactive vs. goals vs. hybrid" (it's hybrid, with a tier split) and Q3's "player as Actor vs. command bus vs. commissioner-only" (Player-as-Actor with visible-then-invisible influence arc). Both are GDD-locked, not open for elicitation.

2. **Author surfaced the Factorio-recursive composition principle as load-bearing,** which expanded the elicitation beyond the original 7 system + 5 experience questions in §3.7. The new threads: outcome-only directive propagation, Goal Resource substrate with multiple outcome shapes, two-layer recursive engineering (selection/propagation + decomposition), recipes as the design unit at each tier, decider with pluggable scoring.

Round 1 spawn prompts have not yet been drafted. Round 1 will pick up in a fresh session with everything below pre-loaded into the agent prompts as "Author's pre-Round-1 intent."

---

## 1. Author Intent (pre-Round-1) — Locks Surfaced

### 1.1 Q1 / Q3 reframed against the GDD

The orchestrator re-read the GDD mid-session (per author request). The GDD already locks:

**Q1 — NPC intent shape: hybrid is locked.**
- USP #3: every actor (player included) runs the same needs-based decision system. Tier-1 needs (food/sleep/safety) drive REACTIVE behavior — depletion, threshold-triggered reactions (e.g., hunger strike).
- Pillar 1 + Hierarchy-Driven Decision Layer (Epic 2+): "lords scheme." Lords pursue strategic goals and propagate them via stewards on weekly/daily cadences. Workers' tier-1 stays mostly reactive; tier-2/3 (wealth, power) is goal-shaped.
- Initiative system (GDD line 53, "flagged for later steps"): the player-facing version of the same goal-propagation machinery. *"How player-set goals propagate through autonomous actors."*
- Threshold listeners: NPCs have probability-weighted decision pools, not fixed reactive scripts.

**Q3 — Player command surface: Player-as-Actor + visible-then-invisible arc is locked.**
- USP #2: *"rise from hungry nobody to invisible kingmaker… Low influence means direct verbs only. High influence means directing others."* Invisible kingmaker is LATE-GAME, not a starting frame.
- USP #3 + Pillar 2: player is a 5th `Actor` with books, needs, body — identical machinery to NPCs. Direct actions land as Activities on the player's books.
- Influence milestones: first wage contract = PLAYER AS WORKER (employed by an NPC, earning coin from own labor). Income-source table: "Player: Any of the above depending on current influence tier."
- DISRUPT verb: *"physical presence is never neutral."* Player has body in Near zone; direct observation is a real perception channel.
- Mechanic 4 (Position/Plan): direct verbs and commissioning **coexist**; commissioning grows in weight as influence rises but never replaces direct action ("the king still eats").

### 1.2 Architectural locks accumulated through one-question-at-a-time exchange

**L1 — Outcome-only directives.**
When a higher-tier actor directs a lower-tier actor (lord → steward), the directive carries **outcome only**, not means. The receiver consults their own action vocabulary and picks methods themselves. Each tier carries its own action vocabulary; goals propagate as outcome-states; subordinates fill in the means. Maximally Factorio-clean recursion — *nothing about HOW leaks across tiers.*

*Open riffs (NOT locked, captured for future exploration):*
- Outcome-landing as a "training feedback" signal back up to the directing actor — could tune the steward's behavior over time.
- Influence-tier scaling = more outcomes specifiable + weighted desirability of outcomes — NOT finer specification of means. At higher influence the player can declare more outcomes (or weight them); the means stay opaque.

**L2 — Recursive composition is the architectural shape.**
Action + influence hierarchy is recursive. **Same primitives at every tier; depth comes from composition.** The "quietly disrupt their routes, then sell them protection, get caught by the rumor mill if sloppy" pattern is the emblematic example — two atomic verbs (disrupt + commission-protection) composed under a strategic goal, with rumor-leak as a feedback channel that punishes sloppy execution. Each influence tier opens new composition possibilities, not new verbs. **Programmatic cleanness of the primitives is non-negotiable** — if they don't compose cleanly, the architecture rots under technical debt.

Implications:
- Action vocabulary stays small and atomic.
- Rumor leakage is a first-class feedback channel gating disruption (not a separate "rumor system" — emerges from book-leak / perception primitives, per E's design seed).

**L3 — Goal Resource is the substrate.**
Ship `Goal` Resource from day one. **Multiple outcome shapes inside the Resource** — account-balance targets are one shape; predicates, target-state declarations, relational-state targets are others. The earlier-considered alternative *"directives live as account-target values"* is **a special case INSIDE Goal Resource**, not an alternative to it. We don't choose between "Goal Resource vs. account targets" — we ship Goal Resource and account targets are one of its outcome shapes.

**L4 — Two engineering layers, recursively self-similar.**
1. *Goal/directive selection + outcome-only propagation.* At each tier, an actor decides which goals to pursue (from its own needs, archetype, received directives) and propagates outcome-only directives to subordinates.
2. *Subordinates picking from received goals.* Same shape one tier down. Decompose received goals into sub-goals; propagate further.

Recursion terminates at a **task layer** at the leaf. (Leaf shape still open — see §1.3 below.)

**L5 — Recipes are the design unit at each tier.**
A *recipe* = a known-balanced composition of primitives that achieves a class of outcomes. Same primitives at every tier; what differs is the **recipe set available to an actor**, which accumulates as influence climbs.

- **Recipes ship as static `.tres` data (option a from the surfacing).** Designer-authored. Each recipe contains a list of sub-goal templates with sequencing/dependency notes. When an actor adopts a recipe, the templates instantiate as concrete Goals on its goal list.
- **Player-authored recipes via UI are a future feature at high-influence tiers.** Low-tier player selects pre-authored recipes from a menu. High-tier player composes their own from primitives. The Factorio analogy gets literal: low-tier = run canned recipes; high-tier = wire your own assembly from raw verbs.
- **The same decider evaluates default recipes AND player-authored recipes.** No special code path for player content.

**L6 — Multiple recipes per outcome class is a content discipline, not an architectural feature.**
The architecture allows it (recipes are a list; decider iterates). What we *author* is multiple recipes per outcome class with costs/payoffs that compete meaningfully across actor archetypes. This is a design-balance project, not an engineering one. Architecture stays clean.

**L7 — Decider iterates recipes; scoring is pluggable.**
The decider scores recipes against the current goal/context. **Scoring is a pluggable method on the actor (or a Resource carried by the actor) — call site is the same regardless of implementation.**

- v0 ships a **single-axis cost scorer** (one numeric cost per recipe; cheapest wins).
- Post-prototype graduation: **multi-axis scoring with archetype weights** (each recipe declares cost/benefit on multiple axes — coin, time, reputation_risk, archetype_alignment, success_probability; each actor carries weights that modulate the axes). Corrupt lord weights `reputation_risk` near zero; mercantile lord weights `archetype_alignment` high. Same recipe library, different actors evaluate it differently.
- **No call sites change between v0 and graduated impl.** Player-authored recipes inherit whatever axis vocabulary is current at the time.
- **Archetype/personality slots into the decider as scoring inputs**, NOT as separate code paths. This is how lord archetypes from the GDD become mechanical — scoring parameters applied to a shared library, not a behavior tree per archetype.

**L8 — "Build seam now, ship simple impl, graduate without rewrite" is a recurring project-level discipline.**
Mary's pattern from E (`observer: Actor = null` parameter slot ships now; per-account precision adapters land at first Phase-6+ consumer) is the same shape as G's pluggable decider scorer (single-axis ships now; multi-axis lands when archetype variation earns it). Saved as project memory `project_seam_then_ship_simple.md` per author suggestion.

### 1.3 Open question when session paused

The pre-Round-1 surfacing paused on the **leaf-of-decomposition question:**

> *When sub-goals decompose recursively, eventually the recursion bottoms out and an actor actually DOES something atomic. What shape does that "atomic thing" take?*
>
> Three options surfaced (anchored on a sub-goal *"buy 20 grain"*):
> - **(a) Leaves are Activity instances.** Existing primitives (`RetailPurchaseActivity`, etc.) ARE the leaves. *Cost:* not every action is a state-mutation (signing contracts, queueing offers, moving, perception queries) — would have to bloat the Activity hierarchy with `SignContractActivity`, `QueueOfferActivity`, `TravelActivity`, etc.
> - **(b) Leaves are a small "Task" union** of ~5 leaf shapes (Activity-creation, contract-signing, market-queuing, movement, perception-query). *Cost:* new Task class hierarchy; slight indirection. *Benefit:* Activity hierarchy stays clean; leaves connect to whichever primitive fits each action class.
> - **(c) Leaves are method calls on the actor.** Methods, not data. *Cost:* recipes lose discoverable identity since half their content (the method body) is invisible to recipe readers.

**Author paused before answering.** Resume here in fresh session.

---

## 2. Agent Responses (Round 1, verbatim)

*Not yet spawned. Round 1 will run after the leaf question is locked and any remaining pre-Round-1 questions are resolved.*

## 3–8. (Not yet reached.)

---

## 9. Notes for Next Sessions

### Resume protocol for fresh session

A fresh session picking up Elicitation G should:

1. **Read this file** — §1 is the pre-Round-1 author intent that any agent prompt MUST be pre-loaded with as "Author's pre-Round-1 intent."
2. Read `_bmad-output/prototype-completion-roadmap.md` §3.7 (G's framing) + §8.2 (Socratic conduct template).
3. Read `_bmad-output/prototype-completion-companion.md` §2 (agent personas) + §4.1 (elicitation checklist).
4. Read `memory/project_thekingdontSee.md` resume point + `memory/MEMORY.md` for feedback memories.
5. **Resume with the leaf question** (§1.3 above). One question at a time. Author has explicitly requested this cadence — saved to memory `feedback_one_question_at_a_time.md`.
6. After the leaf question is locked, expect 1–3 more pre-Round-1 questions before Round 1 spawns. Candidates (orchestrator should pick the most upstream first; do not dump them all at once):
   - **Outcome shapes within Goal Resource** — what concrete shapes does a Goal's outcome take (account-target, predicate, target-state, relational-state)? Does the prototype ship all of them or just account-target?
   - **Goal propagation mechanics in code** — when a lord assigns a directive to a steward, what's the code shape? Reference, copy, contract-binding? How does the assignment relate to existing `Contract` machinery?
   - **Goal satisfaction check** — how does a goal know it's been achieved (or abandoned)? Polling? Event-driven? Decider re-runs each tick and notices when score saturates?
   - **Task / Activity bridge** (depending on leaf answer): if (b) Task union, exactly which leaf shapes go in v0?
7. **Once pre-Round-1 surfacing is fully locked, draft three Round 1 spawn prompts (Cloud + Indie + Mary)** per the §8.2 Socratic template. Pre-load all §1 locks as "Author's pre-Round-1 intent." **Show prompts to author before launching** — explicitly required by §4.1 step 7.
8. Spawn Round 1 in parallel: single message, three `Agent` tool calls, `subagent_type: "general-purpose"` with persona injection.

### Conduct discipline (do not violate in fresh session)

- **One question at a time.** Author explicitly asked. Six-branched-sub-question batches were too much; he skipped questions, which means they were noise. Saved to memory.
- **Explain jargon inline.** Author asked for plain-language reframing of project/CS terms when surfacing alternatives. Each option needs concrete shape + cost + tradeoff named, not just labels. Saved to memory.
- **Recipes / decider / leaf were NOT in §3.7's original brief.** They emerged in pre-Round-1 surfacing. Round 1 agents need them as **locked context**, not as new questions to re-litigate.
- **Many original §3.7 sub-questions are now superseded** (Q1's sub-questions about reactive-vs-goals, Q3's sub-questions about Actor-vs-bus). Round 1 prompts should focus on what's still genuinely open after §1's locks.

### Memory state at session pause

New memories saved during this session:
- `feedback_communication_clarity.md` — explain jargon, show concrete cost of each alternative.
- `feedback_one_question_at_a_time.md` — single focused question per message in elicitation.
- `project_seam_then_ship_simple.md` — recurring project-level architectural discipline.

Updated:
- `MEMORY.md` index — three new pointers.
- `project_thekingdontSee.md` — resume point updated to G-in-progress.

### What's still open after §1 (the substantive elicitation work)

Round 1 (Cloud + Indie + Mary) and possibly Round 2 (Samus reactive) still need to address — once pre-Round-1 finishes:

- **Original §3.7 system questions still genuinely open:**
  - Q2 (perception → decision coupling: pull / push / read-with-precision).
  - Q5 (disruption surface — at perception / at action / at relationship; or all three).
  - Q6 (NPC use of imperfect info — precise reads + behavior-as-noise vs. perception scopes).
  - Q7 (action vocabulary extensibility recipe — likely partially answered by L5 + leaf decision).
- **Original §3.7 experience questions** — the player-feel concerns that Samus owns (held back from Round 1 deliberately; reactive Round 2 only).
- **Compatibility check (mandatory for G's directives):** verify the perception-decision-action architecture doesn't preclude War, Export/Import, Reputation.
- **Placeholders affected:** at least three E-resolved entries gated on G — gossip substrate, NPC knowledge representation, possibly the Activity.display_name resolution.

— Author adjudication (Zach), partial; Cloud / Indie / Mary not yet spawned.
