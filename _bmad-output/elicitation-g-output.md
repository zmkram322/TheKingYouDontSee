---
name: Elicitation G Output — The Perception → Decision → Action Loop
status: COMPLETE — Round 1 spawned + adjudicated; design directives synthesized 2026-05-11
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

**STATUS — PRE-ROUND-1 SURFACING COMPLETE 2026-05-09. ROUND 1 PROMPTS READY TO DRAFT.**

The pre-Round-1 author-intent step expanded substantially across two sessions (2026-05-06, then 2026-05-09). What started as "your gut on Q1 (NPC intent representation) and Q3 (player command surface)" became a deep architectural surfacing that locks much of G's foundational shape *before agents are spawned at all*. Two structural reframings happened mid-session 2026-05-06, plus a third in the 2026-05-09 resume:

1. **GDD re-read.** Author asked the orchestrator to re-read the GDD before continuing. Result: GDD already substantially answers Q1's "reactive vs. goals vs. hybrid" (it's hybrid, with a tier split) and Q3's "player as Actor vs. command bus vs. commissioner-only" (Player-as-Actor with visible-then-invisible influence arc). Both are GDD-locked, not open for elicitation.

2. **Author surfaced the Factorio-recursive composition principle as load-bearing,** which expanded the elicitation beyond the original 7 system + 5 experience questions in §3.7. The new threads: outcome-only directive propagation, Goal Resource substrate with multiple outcome shapes, two-layer recursive engineering (selection/propagation + decomposition), recipes as the design unit at each tier, decider with pluggable scoring.

3. **2026-05-09 resume — author reframed the elicitation shape itself.** Rather than continuing to surface single decisions one at a time (leaf shape, then outcome shapes, then propagation, then satisfaction-check), author called for a halt: the remaining questions are integrated calls that need agents holding code + the full conceptual stack at once, not orchestrator-extracted one at a time. Round 1 was reframed from per-question Socratic alternative-surfacing into an **integrated architecture task** — agents study current code + locked context (L1–L10), propose the integrated weight-bearing system + vocabulary, trace top-down AND bottom-up, audit legibility, conclude refactor-vs-rebuild. Locks L9 (conceptual stack) + L10 (scope + carve-outs) added; §1.3 reframed accordingly.

4. **2026-05-11 synthesis.** Round 1 spawned in parallel (Cloud + Indie + Mary), each returning an integrated architecture proposal + refactor-vs-rebuild verdict. Verdict spread: Cloud (B) full delete; Indie (B) rebuild with generous keeper-list; Mary (A) modify. Author adjudicated all seven divergence axes (D1–D7) on a single round; no Round 2 needed. Adjudications captured in §4; synthesized design directives in §6.

Round 1 papers saved as separate files (see §2).

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

### 1.2.5 Locks added 2026-05-09 (resume session)

**L9 — The conceptual stack.**
The architecture must implement this articulated stack (author's exact framing on resume):

- **Initiative** (GDD term) is the top-level unit. **Concrete target outcome is mandatory** — vague initiatives are not allowed. ("directives or 'initiatives' are highest level and they can't be vague — we have to have a clear path to actions.")
- **Recipe** is the evaluation structure. The decider walks recipes against the decision-maker's utilities to pick. ("we can use recipes as a structure to then walk through how to evaluate whether that is the optimal action or aligns with the utilities of the decision maker.")
- **Decider depth scales with actor tier.** High lords do real thinking — many recipes evaluated, multi-axis scoring, archetype weights. Lower-tier actors collapse to weighted-random choice within a small option tree. ("the higher the level of the lord the more 'thinking' they do before making decisions. then we can boil it down to more random choices that are in the tree of options.")
- **Target outcome → behavior is mechanically linked.** The outcome IS the load-bearing thing; behavior is what falls out of running the recipe the decider picks. ("initiatives should ultimately have concrete target outcomes and those target outcomes should be able to drive the behaviors that result.")
- **We need both** the weight-bearing system (data shapes, code paths) AND the vocabulary (names/types that make the architecture readable as a design, not just compilable). ("we need to land on both the architectural weight bearing system AND the vocabulary.")
- **Legibility is the test.** At every tier the actor must have queryable information to make the evaluation. Recipe needs info the actor can't see → architecture is broken there. ("legibility will be the test of whether the actors have the information needed to produce the right evaluations.")
- **Trace runs both ways.** Top-down (initiative → recipe → sub-recipe → leaf action) AND bottom-up (atomic verb → composes into → recipe → directive). Rules must hold along both traces. ("whether we explore from top down or bottom up, we should trace both and make sure they follow the rules we need to set.")

**L10 — Scope and carve-outs for Round 1 evaluation.**
Round 1 agents evaluate the **actor behavior surface** — not the whole prototype, not just Interest+Activity in isolation.

- **In scope:** Interest + Activity + how those connect outward to Books (writes), Markets (offer-queueing), and Contract creation sites. `Account.gd` / `accounts.gd` as a struct stays in scope (it holds Activity list + contracts); their internals do not.
- **Carve-out — Contracts are husk + relational-visibility byproduct.** A Contract is a persistent record of a labor-market clearing, with a side benefit of "who works for whom" visibility. **Contracts are NOT a force-carrier for behavior.** Author's words: *"the labor contracts were just a husk to resolve labor markets and potentially lead to visibility on who's working for who."* Agents must propose a different mechanism for directive propagation lord→steward.
- **Carve-out — Books / Accounts are legibility substrate, not architectural locus.** Their internals are the foundation of first-class economic queries. Architectural unease does NOT live there. Agents may push on how Activities WRITE to Books, but not on `Book` / `FinancialBook` / `SkillsBook` / `VitalsBook` internals. Author's words: *"accounts i think are a big part of the underlying data that'll be queried through first class legibility concepts — since at its core, there's economics in the game."*
- **Out of scope:** Markets internals (clearing strategies, offer/request types). Bus signals beyond `work_window_opened/closed`.

### 1.3 Pre-Round-1 surfacing — closed (2026-05-09)

The 2026-05-06 session paused on the **leaf-of-decomposition question** (anchored on a sub-goal *"buy 20 grain"*; three options surfaced — leaves-as-Activity, leaves-as-Task-union, leaves-as-method-calls).

On 2026-05-09 resume the orchestrator presented the three options for an a/b/c lock. **Author rejected the framing** — pulling on the leaf question revealed deeper unease about the current Interest/Activity scaffolding, and a single-vote on leaf shape would solve nothing. The architecture has to be evaluated as a whole: *"let's not make them choose between a,b,c — let's have them think about (after studying the right artifacts and current godot scripts) whether starting fresh — there's ways we could handle all the design concerns or whether we're close and just need some modifications to the current approach."*

**Decision:** the leaf question is folded into the Round 1 agent task as one input, not a pre-Round-1 vote. Other previously-candidate pre-Round-1 questions also fold in:
- Goal **outcome shapes** (account-target / predicate / target-state / relational-state) inside `Goal` Resource.
- Goal **propagation mechanics** in code (since Contracts are NOT the force-carrier per L10 — agents must propose what is).
- Goal **satisfaction check** (polling, event-driven, decider re-runs).

Round 1 will be drafted as an **integrated architecture task** — not per-question Socratic alternative-surfacing. The surface has been mapped; agents propose direct.

---

## 2. Agent Responses (Round 1, verbatim)

Round 1 papers were saved as separate files (verbatim, full text):

- 🏛️ **Cloud Dragonborn** → `_bmad-output/elicitation-g-round-1-cloud.md` — verdict **(B) clean-sheet rebuild**. Deletes the entire Interest family. Key contribution: standing-recipe pattern (`recipe.repeating: bool`) named as load-bearing.
- 🎮 **Indie** → `_bmad-output/elicitation-g-round-1-indie.md` — verdict **(B) rebuild with generous keeper-list**. Decision-side gutted; Interests survive renamed as `*Role` market-registration manifests. Vocabulary-first lens.
- 📊 **Mary** → `_bmad-output/elicitation-g-round-1-mary.md` — verdict **(A) modifications**. Interests reframe to atomic-verb library + bus binding. Key contribution: `DirectiveAssignmentActivity` + `DirectiveOutcomeActivity` writing to `Directive_Outcomes:{counterparty}` accounts — earns "steward track record" for free + seeds reputation substrate.

---

## 4. Author Adjudications

Seven divergences (D1–D7) surfaced across the three Round 1 papers. Author adjudicated all on a single round; no Round 2 needed.

### D1 — Verdict: rebuild vs. modify

**Author's call:** *"re-purposing accomplishes the same end as deleting outright.. we'll get to where we want to be either way."*

**Lock:** decision logic gutted from Interest classes; methods + bus subscriptions stay as atomic-verb library. Rename to `*Role` is a phase-directive call, not locked here. Functionally Indie's (B-with-keepers) path, operationally indistinguishable from Mary's (A) reframe — Cloud's full delete declined.

**Orchestrator forward note:** Cloud's deeper concern (Interest classes don't name load-bearing distinctions; re-purposing risks carrying old assumptions forward, e.g., `GrainInterest.outstanding_demand` staying as a field rather than moving to Books) is captured as the *discipline rule* in directive G9: Interest/Role classes carry only bus subscriptions + atomic-verb methods; any field shaped like "what the actor is currently trying to do" moves to Goal state or to Books.

### D2 — Goal Resource shape: typed subclasses vs. enum discriminator

**Author's call:** *"i'm not sure i see the benefit of a sub-class.. should be easier to expand types of goals later than having to sub-class each time."*

**Lock:** single `Goal` Resource with `outcome_kind` enum discriminator. Cloud's typed-subclass approach declined. Adding a new outcome shape later = new enum value + new `match` arm, not a new class.

### D3 — Plan as separate Resource vs. collapsed into Goal

**Author's call (question form):** *"the goal will need to orchestrate the decider, as long as the 'plan' can be revised through a decider, then i don't think we need to have a separate carve-out of plans, but maybe there's something i'm missing?"*

**Orchestrator answer:** nothing missed. Collapsing works cleanly — `Goal` carries `picked_recipe` + `step_index` + `child_goals` directly. Plan revision = decider re-runs and overwrites `picked_recipe`. History of plans-tried is a journal concern if it ever earns its keep.

**Lock:** no separate `Plan` Resource. Vocabulary stays at four (Initiative / Goal / Recipe / Decider). Indie's Plan concept declined. Cloud + Mary's "recipe state lives on Goal" prevails.

### D4 — Directive feedback channel (Mary's contribution)

**Author's call:** *"seems fine, benefits legibility perhaps?"*

**Lock:** `DirectiveAssignmentActivity` + `DirectiveOutcomeActivity` adopted (see G7). Directives are journaled like any other activity. Earns "steward track record" via existing `book.balance(account, period)` API. Seeds reputation substrate.

### D5 — Standing recipes (Cloud's contribution)

**Author's call:** *"it probably should hold true that every behavior should be pursuant towards a goal (or defiance thereof) or else the world won't make sense, feel tractable. so keep cloud's contribution."*

**Lock:** standing-recipe pattern adopted as first-class. `recipe.repeating: bool` flag on Recipe (see G4). NOT a separate Resource type. Author's framing — "every behavior pursuant to a goal (or defiance thereof)" — becomes a v0 design discipline: every actor's bus-driven activity must trace to a Goal it is serving (including reactive Goals like `sustain_household`).

### D6 — Outcome shapes shipped in v0

**Author's call:** *"predicates make sense — it's how cleverly we can evaluate sub-goals that are smart enough to re-direct properly when the predicates aren't met."*

**Lock:** v0 ships `ACCOUNT_TARGET` + `PREDICATE`. `RELATIONAL_STATE` and other shapes are type slots in the enum from day one; no code paths branch on them yet (L8 discipline).

**Forward note (author's second clause):** predicate failure → smart re-direction of sub-goals is a graduation concern. v0 marks goals `&"failed"` and propagates failure up; smart retry (decider re-runs with the failed recipe excluded) is a one-line addition when the first trace failure surfaces. Captured in §7.

### D7 — Goal propagation: copy vs. reference

**Author's call:** *"ok"* (assenting to Mary's recommendation).

**Lock:** reference semantics. Goals propagate as Godot Resource shared instances; both directing actor and assignee see status changes through the same Resource. Revisit only if save/load forces copy semantics.

---

## 6. Synthesized Design Directives

These directives are the architectural locks for Elicitation G. They feed the Phase 3.5 directive (G's foundations) and downstream phases (perception-decision-action integration).

### G1 — Goal Resource as the substrate

- `Goal` Resource at `scripts/goals/goal.gd`. Single Resource type with enum-discriminated outcome shape. No subclass hierarchy for outcome kinds — adding a new outcome shape = new enum value + new `match` arm, not a new class.
- v0 ships two outcome kinds: `ACCOUNT_TARGET` (compares `book.balance(account, period_start, period_end)` against threshold + comparator) and `PREDICATE` (named `Callable` returning bool).
- `RELATIONAL_STATE` and other shapes exist as enum slots from day one; no code path branches on them until the first instance demands it.
- Goal carries its own runtime plan state directly: `picked_recipe: Recipe`, `step_index: int`, `child_goals: Array[Goal]`, `status: StringName` (`&"open" | &"satisfied" | &"abandoned" | &"failed"`). No separate `Plan` Resource (D3).

### G2 — Initiative is a top-level Goal (vocabulary, not class)

- An Initiative is a Goal with no `parent_goal`, a non-null outcome, and a non-null `deadline_tick`. The mandatory-concrete-outcome rule (L9) is enforced by a validator at construction — no path to creating an Initiative with a vague outcome.
- "Initiative" maps to a constructional discipline (root + concrete + deadline), not a separate class. Recursion (L2) stays clean — same `Goal` type at every tier.

### G3 — Recipe Resource as static `.tres` data (L5)

- `Recipe` Resource at `scripts/recipes/recipe.gd`. Designer-authored. Fields: `steps: Array[RecipeStep]`, `produces_outcome_kind: Goal.OutcomeKind`, `produces_account: StringName` (for matchable lookup on `ACCOUNT_TARGET` recipes), `single_axis_cost: float`, `repeating: bool` (see G4), `requires: Array[StringName]` (named pre-conditions).
- `RecipeStep` is a small union: `SubGoalStep` (instantiates a child Goal — recursion vehicle) or `ActionStep` (invokes a named verb on the actor — leaf). Implemented as two Resource subclasses for `.tres` editor support.
- Recipes live at `scripts/recipes/library/*.tres`. New recipe = new file. No code change required. (L6 content discipline.)

### G4 — Standing recipes (`repeating: bool`)

- A recipe whose lone step re-fires while the parent goal stays open is first-class. Modeled via `recipe.repeating: bool`. NOT a separate Resource type.
- Common in v0: `recipe_honor_active_contract`, `recipe_pay_outstanding_payables_weekly`, `recipe_keep_inventory_above_target`, etc.
- Author's design discipline (locked alongside the directive): *every behavior must be pursuant to a Goal (or defiance thereof).* No actor activity exists in v0 that doesn't trace to a Goal it is serving.
- Semantics: when `repeating == true`, the step runner re-fires the lone step on each `ready_when` match while the parent goal's outcome hasn't been hit. When the outcome hits, the goal closes and the standing recipe stops scheduling.

### G5 — Decider with pluggable scorer (L7+L8)

- `Decider` Resource at `scripts/decider/decider.gd`. One method: `pick_recipe_for(actor: Actor, goal: Goal) -> Recipe`. Iterates `actor.recipe_library.recipes_for(goal)`, filters by pre-conditions, scores via pluggable `RecipeScorer`, returns best.
- `RecipeScorer` abstract at `scripts/decider/recipe_scorer.gd`. v0 impl: `SingleAxisCostScorer` (returns `recipe.single_axis_cost`).
- Graduation: `MultiAxisArchetypeScorer` carrying `axis_weights: Dictionary` Resource. **No call site changes between v0 and graduated impl.** L8 discipline.
- Decider depth scales with actor tier via *which scorer Resource is attached*, not via different code paths. Worker actors may carry a `WeightedRandomScorer` (small bias roll over candidates); lord actors carry the cost scorer (v0) or the multi-axis scorer (graduated). Lord-tier "thinks more" = more recipes in the library + a richer scorer Resource.

### G6 — Directive propagation via direct goal-write (NOT Contract; L10)

- New field on `Accounts`: `directives_received: Array[Goal]`.
- New method on `Actor`: `direct_subordinate(subordinate: Actor, goal: Goal)`. Sets `goal.assigned_by = self.get_path()`, `goal.assigned_to = subordinate.get_path()`, appends to `subordinate.accounts.directives_received`, writes a `DirectiveAssignmentActivity` to the directing actor's books (see G7).
- Goals propagate as **reference** (Godot Resource shared instance), not copy (D7). Both directing actor and assignee see status changes through the same Resource.
- Contracts (`Contract`, `LaborContract`) explicitly do NOT carry directives. They remain husk + relational-visibility byproducts of market clearings (L10).

### G7 — Directive lifecycle journaling (legibility through Books)

- Two new persistent Activity classes:
  - **`DirectiveAssignmentActivity`** — writes on directive creation. Records at `Directive_Assignments:{subordinate_id}` on the directing actor's books. Substrate for "how many directives has this lord issued in this period" macro-legibility.
  - **`DirectiveOutcomeActivity`** — writes on status flip to `satisfied | abandoned | failed`. Posts to BOTH actors' books at `Directive_Outcomes:{counterparty_id}`. Sign convention: credit = satisfied; debit = abandoned/failed.
- Earns the "steward track record" query via existing `book.balance(Directive_Outcomes:{steward}, period)` — no new query API needed.
- Seeds the substrate for future Reputation phase — gossip-sourced entries write to the same per-counterparty namespace.

### G8 — Decider call site on Actor

- New method on `Actor`: `advance_goals(tick: int)`. Called per-actor by the orchestrator on the appropriate cadence (daily for low-tier; possibly weekly for lord-tier post-tier-split).
- `advance_goals` walks the union of (a) `accounts.directives_received` with `status == &"open"` and (b) self-originated open goals (from needs, archetype aspirations). For each:
  1. Check `goal.is_satisfied(self)` → close if true; emit `DirectiveOutcomeActivity`.
  2. Check past-deadline → mark `&"abandoned"`; emit `DirectiveOutcomeActivity`.
  3. If `picked_recipe == null`, run `decider.pick_recipe_for(self, goal)`.
  4. Run one step of the picked recipe — advance `step_index`; spawn child Goal for `SubGoalStep`; invoke verb method for `ActionStep`.
- Orchestrator hook: `WindowOrchestrator` adds a daily-tick call to `actor.advance_goals(tick)` for every actor, before existing slot/market work.

### G9 — Interest classes re-purposed (decision logic gutted)

- All five existing Interest classes (`WorkingInterest`, `EmployerInterest`, `ProductionInterest`, `MercantileInterest`, `GrainInterest`) survive as containers for:
  - Bus subscriptions (continue to listen on `work_window_opened/closed`, `daily_tick`, etc.).
  - Atomic-verb methods (`begin_working`, `do_one_work_slot`, `close_workday`, `settle_outstanding_wages`, `respond_to_supply_call`, `respond_to_wholesale_demand_call`, etc.).
- All decision logic moves OUT of Interest classes:
  - Hardcoded thresholds (`@export var desired_workers: int = 2`, `target_inventory: int = 60`, `max_wholesale_price`) become *parameters that recipes set* via the recipe's leaf `ActionStep` payload.
  - `GrainInterest.outstanding_demand: float` — Cloud's call applies here: this is actor state, not behavior. v0 placement: accumulates as journal entries on a `Demand_Carry:grain` account. Books carry the state; macro-legibility substrate handles it natively.
- **Discipline rule (locked here, applies to all five Interests):** Interest/Role classes carry only bus subscriptions + atomic-verb methods. Any field shaped like "what the actor is currently trying to do" moves to a Goal (`picked_recipe`, `step_index`) or to Books (accumulating state via journal entries). This is what makes D1's re-purpose-vs-delete equivalence hold.
- Rename of Interest → `Role` is a phase-directive decision, not locked here.

### G10 — Leaf shape: ActionStep invokes a named verb on the actor

- Leaves of decomposition are NOT Activity instances. NOT a Task class hierarchy. They are `ActionStep` Resources with `action_id: StringName` + `payload: Dictionary` that the step runner dispatches via `actor.do_action(action_id, payload)` (or equivalent thin shim that routes to the relevant Interest method).
- **Dependency direction: ActionStep → verb method (on Interest or Actor) → Activity → Book write.** Activities never know about Goals or Recipes.
- v0 verb set is concrete and small (~6 verbs to support the existing trace): `work_a_day`, `pay_outstanding_wage`, `queue_wholesale_buy`, `queue_wholesale_sell`, `strike_labor_offer`, `command_subordinate`. Each verb has an Activity (or market-registration effect) behind it. **Discipline rule:** no verb without a force-carrier.

### G11 — Satisfaction check is polling (not event-driven)

- `Goal.is_satisfied(actor)` is called on every `advance_goals` tick for every open goal. For `ACCOUNT_TARGET` goals: one `book.balance(...)` read. For `PREDICATE` goals: one `Callable` invocation.
- No `goal_completed` event-firing layer in v0. With ~4 actors × ~5-10 open goals × one balance read per tick, this is well under any performance budget.
- Graduation to event-driven (if ever required) is purely additive and does not change call sites (L8).

### G12 — Predicate registry

- New autoload at `scripts/predicates/predicate_registry.gd`: a Dictionary `StringName → Callable`. Predicates internally use the same `book.balance(...)` queries as `ACCOUNT_TARGET` goals.
- Earns its keep as the escape hatch for outcomes that don't naturally express as account-targets: `is_employed(self)`, `has_active_contract_with(employer)`, `owns_plot(X)`, `wholesale_market_open`, etc.

### G13 — Goal copy-vs-reference (D7)

- Goals propagate as **reference** (Godot Resource shared instance). Both parties see status changes through the same Resource.
- Save/load durability: Resource serialization handles this natively in Godot. Revisit only if a save/load case forces copy semantics.

### G14 — Compatibility with War / Export-Import / Reputation

Verified across all three Round 1 papers and confirmed by adjudication:

- **War.** PREDICATE outcomes (`rival_lord_neutralized`, `region_X_controlled_by_self`) + recipes propagating sub-goals to marshal/captain/seneschal via `directives_received`. Casualties → new Activity classes writing to a future MilitaryBook. No new architectural layer.
- **Export/Import.** Cross-region recipe leaves invoke `region.market.queue_*` on the destination region. Same Goal/Recipe/Decider stack. New activity class (`JourneyActivity`) is templated in the Phase 2.5 directive's persistent/transient table.
- **Reputation.** `Directive_Outcomes:{counterparty}` substrate (G7) is the seed. Future `ReputationBook` (Book subclass) extends with gossip-sourced entries; queries are the same `book.balance(account, period)`.

The compatibility doesn't come from claims of generality — it comes from every new system reading/writing through Book, propagating through `directives_received`, and deciding through `decider.pick_recipe_for`. Three primitives; same shape every time.

---

## 7. Open Questions (handed forward)

### Handed to Phase 3.5 directive (G's foundations coding pass)

- **Rename `*Interest` → `*Role`?** D1's re-purpose-vs-delete equivalence works under either naming. Phase directive picks.
- **Standing-recipe `ready_when` semantics.** What field on `ActionStep`/`RecipeStep` declares "fire on which bus signal / tick event"? Candidate: `ready_when: StringName` enum (`work_window_opened`, `daily_tick`, `weekly_burst`, etc.).
- **Recipe expression evaluator.** Indie's `min_balance_expr: StringName = "parent.min_balance * 0.6"` proposal — v0 could ship Callables on `GoalTemplate` instead (simpler), and graduate to string expressions when player-authored recipes need editor-editable expressions. Phase directive's call.
- **`v0` recipe library content.** What 4–6 starter recipes drive the existing 14-day trace? Author + Phase directive author together.

### Handed to Phase 4+ (downstream phases)

- **Goal failure → smart re-direction.** v0 marks goal `&"failed"` and propagates up. Smart retry (decider re-runs with the failed recipe excluded from candidates) lands when first trace failure surfaces. (Author's D6 second clause.)
- **Multi-axis archetype scorer.** Graduation of `RecipeScorer` from `SingleAxisCostScorer` to `MultiAxisArchetypeScorer` lands when archetype variation across actors earns its keep.
- **Tier-specific verb sets.** v0 has one `do_action` on `Actor`. Tier-specific actor classes (`LordActor`, `StewardActor`) come when the population diversifies. Same dispatch shape, different verb sets.
- **Outcome → upstream training feedback.** L1 open riff — outcomes landing as feedback that tunes a directing actor's future scorer. No v0 implementation; data path exists (`Goal.directed_by_path` / `assigned_by`); tuning logic ships with archetype-modulated scoring.
- **Initiative deadline as a vivid simulation event.** v0 marks `&"abandoned"` past-deadline. Dramatic UI moment ("the lord's stockpile attempt failed at the eleventh hour") is a UI concern.
- **Player-authored recipes via UI.** High-influence feature. `Recipe.new()` → save as `.tres` path is open from day one; UI is the deliverable.

### Handed to elicitation F or design-parking-lot

- **Contract lifecycle journaling.** Mary's macro-legibility audit gap: contract `BREACHED` events don't write journal entries today. Adding a `ContractLifecycleActivity` (or `WorkingInterest.disconnect_from_bus` writing the entry) makes "high turnover at this farm" queryable. Small fix, but its placement (Phase 3.5? Phase 6?) is open. Likely Phase 3.5 since it's load-bearing for D4's directive-outcome legibility pattern.
- **Reputation Phase trigger.** When does `ReputationBook` ship as a Book subclass? Currently scheduled for Phase 9 (Elicitation F). The `Directive_Outcomes:{counterparty}` substrate (G7) lands in Phase 3.5, well before.

---

## 8. Placeholders Affected

### E-resolved entries gated on G (status updates)

- **Gossip substrate** — G7's `Directive_Outcomes:{counterparty}` accounts + future gossip-sourced entries (post-Reputation) is the seed. *Status: substrate landing Phase 3.5; gossip entries gated on Elicitation F + Phase 9.*
- **NPC knowledge representation** — Resolved via the `observer: Actor = null` slot from E (perception primitive) + the predicate registry (G12). Observers read books with precision; predicates query books. *Status: foundation landing Phase 3.5.*
- **`Activity.display_name` field never set** — Touched by Goal.description / Recipe.description in G1/G3 (vocabulary surface). Activity.display_name remains gated on Elicitation E + Phase 7 (UI pass).

### New placeholders surfaced by G

- **`RecipeScorer = SingleAxisCostScorer`** — v0 only scores on `recipe.single_axis_cost`. Real version: `MultiAxisArchetypeScorer` with `axis_weights` per actor archetype. *Gated on:* archetype variation earning its keep (likely Phase 7+).
- **Recipe pre-condition expressions** — v0 uses named `StringName` keys in `recipe.requires` referencing the predicate registry. *Gated on:* player-authored recipe UI (high-influence feature, far phase).
- **`GoalTemplate` value expressions** — v0 uses Callables on `GoalTemplate` (e.g., `(parent_goal) -> parent_goal.target_amount * 0.6`). String-expression evaluator (Indie's `min_balance_expr`) deferred. *Gated on:* player-authored recipe UI.
- **Goal failure → recipe re-pick** — v0 marks goal `&"failed"`. Smart retry (decider re-runs with failed recipe excluded) deferred. *Trigger to revisit:* first trace failure observed in dev.
- **Standing-recipe `ready_when` enum membership** — v0 carries the event names matching `WindowBus` + `SimClock` signals. *Gated on:* new bus signals landing.
- **Outcome shapes `RELATIONAL_STATE`, `POSSESSION_OF` (Mary's naming) / `PopulationOutcome`** — type slots ship v0; first concrete instances gated on Reputation (F) + future systems.

---

## 9. Notes for Next Sessions

### Session closed 2026-05-11

Elicitation G is complete. G1–G14 directives (§6) feed the Phase 3.5 directive (G's foundations coding pass). All other gated elicitations (B / A / D / F / C per roadmap) are now unblocked — but the prototype-completion sequence keeps Phase 3.5 next (substrate before consumer).

**Immediate next session candidate:** Phase 3.5 directive author pass. Pre-read: this file's §6 (G1–G14) + companion §1 + Phase 2.5 directive §3 (Activity primitive). Output: `_bmad-output/phase-3.5-perception-decision-action-directive.md` per companion §6.3 template.

**Vocabulary lock (typed a thousand times — author's gut check applies):** `Goal`, `Recipe`, `Decider`, `RecipeScorer`, `RecipeStep` (with `SubGoalStep` / `ActionStep` variants), `Initiative` (vocabulary alias for top-level Goal — no separate class), `advance_goals(tick)`, `pick_recipe_for(goal)`, `score_recipe(actor, goal, recipe)`, `is_satisfied(actor)`, `direct_subordinate(subordinate, goal)`, `do_action(action_id, payload)`, `directives_received: Array[Goal]`. Phase 3.5 directive must hold this vocabulary or surface a rename early.

**Disciplines locked alongside directives:**
- *Every behavior must be pursuant to a Goal (or defiance thereof)* — author's D5 framing; Phase 3.5 must hold this.
- *Interest/Role classes carry only bus subscriptions + atomic-verb methods* — Cloud's D1 deeper concern, made discipline rule in G9.
- *No verb without a force-carrier* — G10. New action_id only lands when its Activity (or market-registration effect) lands with it.
- *Same call site across v0 and graduated impl* — L8 applies to RecipeScorer (G5), satisfaction check (G11), and any future seam landing.

---

### Resume protocol — UPDATED 2026-05-09 (pre-Round-1 closed) — historical, superseded

Pre-Round-1 surfacing is complete. Round 1 is next.

1. **Read this file** — §1 (L1–L10 + §1.3 reframing) is locked context to inject into agent prompts as "Author's pre-Round-1 intent" / "Locked context (do not re-litigate)."
2. Read `_bmad-output/prototype-completion-companion.md` §1 (current code map) + §2 (agent personas inline).
3. Read `_bmad-output/prototype-completion-roadmap.md` §3.7 (G's framing) for the original system+experience question set (much is now superseded — see §1.3 of this file). §8.2 conduct template is partially superseded for G's Round 1 (see §9 below).
4. Draft three Round 1 spawn prompts (Cloud + Indie + Mary) as **integrated architecture tasks**, not per-question Socratic surfacing. Each agent gets:
   - Persona injection (companion §2)
   - Locked context (L1–L10 + scope/carve-outs from §1.2 + §1.2.5)
   - Pre-read list (current `tkyds-game/scripts/` — Activities, Interests, Accounts struct, Markets interface, Contract creation sites — plus locked artifacts)
   - Agent-specific lens (Cloud = weight-bearing system + types; Indie = rebuild-vs-refactor pragmatism + vocabulary feel; Mary = legibility audit + cross-actor information flow)
   - Output spec (one integrated paper to `_bmad-output/elicitation-g-round-1-<agent>.md` with verdict on refactor-vs-rebuild)
5. **Show the prompts to author before launching** — required per §4.1 step 7 + author preference.
6. Spawn Round 1 in parallel: single message, three `Agent` tool calls, `subagent_type: "general-purpose"` with persona injection.

### Conduct change — §8.2 Socratic template superseded for G's Round 1

§8.2's per-question alternative-surfacing template fits when the surface is unmapped. G's surface is now mapped (L1–L10). The Round 1 task is integrated architecture proposal + verdict. Each agent writes one paper, not a per-question response. Conduct disciplines that DO carry forward:
- Code-path grounding required for every architectural claim (no aesthetic visions without traceable touch-points)
- Honest verdict — agent classifies their proposal as "modifications to current scaffolding" or "clean-sheet rebuild" without softening
- Surface disagreement with other agents as tradeoffs, not edicts
- Plain-English vocabulary (no CS-textbook jargon — see `feedback_naming.md`)

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
