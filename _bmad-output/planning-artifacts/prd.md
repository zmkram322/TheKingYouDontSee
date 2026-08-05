---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-02b-vision', 'step-02c-executive-summary', 'step-03-success', 'step-04-journeys', 'step-05-domain', 'step-06-innovation', 'step-07-project-type', 'step-08-scoping', 'step-09-functional', 'step-10-nonfunctional', 'step-11-polish', 'step-12-complete', 'step-e-01-discovery', 'step-e-02-review', 'step-e-03-edit']
workflowType: 'prd'
workflow: 'edit'
releaseMode: 'phased'
lastEdited: '2026-08-02'
draftNote: 'Steps 4-12 were drafted by the PM facilitator in a single pass on 2026-07-24. The 2026-07-25 edit session revised the load-bearing sections against a direct author elicitation: added the Core Mechanical Model (new), rewrote Product Scope around the proving scene, rebuilt the Functional Requirements contract, and added Explicit Non-Goals. The 2026-07-27 edit session rewrote FR1 and the decision-model portions of the Core Mechanical Model against fable-spike findings and a party-mode roundtable (see Open Questions → "Resolved in the 2026-07-27 party-mode roundtable"). The 2026-08-02 edit session added the hex-board/influence-layer as a spatial interface to reach and cascade, validated via a four-agent party-mode roundtable against `hex-board-influence-layer-seed.md` (see Open Questions → "Resolved in the 2026-08-02 party-mode roundtable"). Sections still carrying unreviewed 2026-07-24 draft content are marked inline. See "Open Questions" at the end.'
classification:
  projectType: 'single-player-pc-game (emergent-simulation systemic RPG, Godot 4, PC/Steam)'
  domain: 'systems-driven simulation game (social/political immersive-sim adjacent)'
  complexity: 'high (design-risk-dominated, not infra-dominated)'
  projectContext: 'greenfield-design-layer on brownfield-substrate (demand-resolver economy shipped)'
inputDocuments:
  - path: '_bmad-output/design-session-2026-07-24-social-political-layer.md'
    role: 'primary'
    binding: true
    note: 'Section 1 was re-litigated 2026-07-24 and is marked SUPERSEDED in-source; sections 0, 10 and Next Steps still carry the superseded framing and are pending a source cleanup pass.'
  - path: '_bmad-output/design-positioning-and-comparables.md'
    role: 'authoritative-framing (why/pitch)'
    binding: true
  - path: '_bmad-output/design-multipath-routes-framework.md'
    role: 'authoritative-framing (how/routes)'
    binding: true
  - path: '_bmad-output/poc-v2-system-spirit.md'
    role: 'substrate-tenets'
    binding: true
  - path: '_bmad-output/pub-slice-leverage-seed.md'
    role: 'tabled-seed'
    binding: false
    note: 'Tabled 2026-07-25 pending prioritization. Superseded as a first slice by the proving scene in Product Scope, which adds a fail state the seed lacked. Parked, not retired.'
  - path: '_bmad-output/poc-v2-refactor-plan.md'
    role: 'reference'
    binding: false
  - path: '_bmad-output/fable-spike-decisions.md'
    role: 'validation-evidence'
    binding: true
    note: 'Spike build against the proving scene; §9 findings drove the 2026-07-27 FR1 rewrite and the eligibility/candidate-pool FRs (FR84-87).'
  - path: '_bmad-output/hex-board-influence-layer-seed.md'
    role: 'validated-seed'
    binding: true
    note: 'Captured 2026-08-02 as a non-binding seed; pressure-tested the same day by a four-agent party-mode roundtable (Cloud Dragonborn, Samus Shepard, Mary, Indie) per hex-board-prd-edit-session-plan.md and re-roled binding on incorporation. Drove the new Core Mechanical Model subsection "The Board," FR88-FR99, and the Growth/Vision phasing of the board in Product Scope.'
documentCounts:
  gdd: 0
  brief: 0
  research: 0
  brainstorming: 0
  projectDocs: 5
editHistory:
  - date: '2026-07-25'
    changes: 'Added Core Mechanical Model and Explicit Non-Goals sections. Rewrote Product Scope around the proving scene. Rebuilt and renumbered Functional Requirements (FR1-FR76; prior FR1-FR45 superseded) against the mechanical model. Phased Success Criteria. Made NFRs measurable. Updated frontmatter traceability: added two authoritative-framing design docs, re-roled the tabled pub-slice seed.'
  - date: '2026-07-27'
    changes: 'Rewrote Journey 1 against the proving scene, with FR-level traceability; added the Corwin/Bram comparative read and the fail branch. Marked Journey 1 and the MVP scene as placeholders: the FR structure binds, the fiction does not, and concrete details are expected to be tuned once the systems are playable. Added trust and promotion to the Core Mechanical Model and as FR77-FR83. Trust is the Player estimate that an actor delivers, inferred from observed goal outcomes and distinct from a held channel; promotion grants an authority channel as an edge operation (explicit positions deferred until roles matter). Added both to Growth, dependency-ordered after installed goals. Established append-only FR numbering policy so identifiers stay stable.'
  - date: '2026-07-27 (session 2)'
    changes: 'Rewrote FR1 and the Core Mechanical Model decision-model sections against fable-spike-decisions.md findings and a two-round party-mode roundtable. Demands are now specified as re-derived reads over persistent stats, not persistent memory objects. Survival arbitration confirmed as weighting, never a checked-first gate, with hysteresis as the data-driven fix for flicker. Added a new Eligibility subsection to the Core Mechanical Model and FR84-FR87 to bound per-actor scoring cost by eligibility rather than by goals, protecting a universal core action set from identity-based pruning. Added a matching Performance NFR line and two architecture notes (eligibility as a data seam now, full tagging deferred). Added fable-spike-decisions.md as a binding input document. Logged resolution in Open Questions.'
  - date: '2026-08-02'
    changes: 'Added the hex-board/influence-layer as a spatial interface to reach and cascade, validated via a four-agent party-mode roundtable (Cloud Dragonborn/architecture, Samus Shepard/design, Mary/positioning, Indie/solo-dev scope) against hex-board-influence-layer-seed.md; no spike was needed. Added Core Mechanical Model subsection "The Board — spatial interface to reach and cascade." Added FR88-FR99: goal-install-at-hex (reusing FR11/FR12/FR45), placement ranked by loyalty/trust, stick-until-resolved goals with a single-depth "seize control" interrupt, occupied capacity as a Player-side bookkeeping index (not a scan), the instant/permanent split, two ownership layers reusing existing storage patterns, resource-block reuse, a social overlay on the same board (not a second board), the territorial-legibility rollup, and terrain generation as a new one-way instantiation step distinct from the existing actor promote/collapse seam (FR73). Added a Performance NFR note for the added slow-tick rollup. Split the board across Growth (core verb, dependency-ordered after installed goals/trust/promotion/cascade) and Vision (terrain generation, template library, territorial legibility, scattered asset layer) in Product Scope. Added Civ 6/Catan to Market Context with an explicit not-menu-driven contrast; left Detected Innovation Areas and the Executive Summary unchanged. Added a light-touch board reference to Journey 4 without a full rewrite. Logged resolution and migrated remaining open seed-doc threads into Open Questions.'
  - date: '2026-08-03'
    changes: 'Reconciled the contract with the rebuilt decision substrate in tkyds-game/brain/, following a four-voice party-mode critique (Winston/architecture, Cloud Dragonborn/engine, Samus Shepard/legibility, John/contract) recorded in brain-critique-decisions.md. Named the missing concept: an **obligation** is a discrete dischargeable piece of assigned work that competes as a peer candidate, distinct from a **goal** (standing intent that biases many weights and never completes) — settling a naming collision deferred three times, and resolving the FR9-vs-FR13 contradiction that predated the rebuild in FR13''s favour. Added FR100-FR103: the obligation itself, the regenerability-not-persistence storage test, channel-as-weight computed at scoring time with an authored constant standing in until channels exist, and obligation expiry. Amended FR1 (one shared *mechanism*, not one evaluation — nested decisions run the same mechanism over a narrower set), FR9 (goal defined, may emit obligations), FR12 (channel sets weight, never permission to install, which would make refusal invisible), FR84 (externally-originated intent is the sole storage exception), FR86 (protected set is by *category* not instance, explicitly marked rather than inferred from a missing predicate), and FR87 (candidate pool = eligible capabilities + outstanding obligations). Matching Core Mechanical Model prose edits to The atom, Behaviour, Eligibility, and Influence. FR7''s tuning-table amendment is deliberately deferred until the tuning block lands. No FR renumbered; FR100 was the next free number (FR88-FR99 are the board group).'
---

# Product Requirements Document - TheKingYouDontSee

**Author:** Zach
**Date:** 2026-07-24

## Executive Summary

**The King You Don't See** is a single-player emergent-simulation RPG (Godot 4, PC/Steam) set in a living medieval kingdom where *nothing is scripted, everything is scored* — every actor, from peasant to lord to the player, runs one shared utility-AI loop over the same primary and derived stats. Behavior variety comes from data (stats, curves, goals), not per-actor code.

**The logline:** *A living kingdom is steered by an unseen power you begin too small to even see — climb through war, commerce, crime, secrets, public service, and more until you are that power.*

**The core fantasy is vertical illegible authorship.** At the start, there is a "king you don't see" — an actor so far above you that you cannot even perceive, let alone reach, the hand that shapes how the kingdom behaves and how decisions cascade culturally downward. The game is the climb: you accumulate the ability first to *perceive* that hidden web of influence, then to *reach* through it, until you become the actor whose decisions propagate across the world — a will the kingdom moves to but cannot fully read. That inversion — from an actor the world acts upon to one who acts upon the world through others — is the title made mechanical.

**Crucially, "the king you don't see" names illegibility of *reach and method*, not physical invisibility.** The hidden manipulator and the overt, soldier-commanding warlord are *both* unseen in the sense that matters: the world never fully reads the apparatus of power behind them. **Direct action is a first-class path, not a lesser one** — you climb by whatever means you build, from earned loyalty to open coercion to command of armies. "Unseen" is the purest expression of the spine (the manipulator end of the spectrum), never its definition.

**Power is defined precisely: power is a measure of how many people fall under the shadow of your decisions.** Not wealth, not territory — causal reach over the choices of others. You begin by earning coin to fill your belly and making good decisions in a world that runs without you; you end by steering a kingdom that can never fully read the hand behind its fate — whether that hand is hidden or openly commanding.

**Target player:** systems-literate players drawn to emergent social/political simulation and immersive-sim-style expression — the CK3, Dishonored, and Disco Elysium audience who want to outsmart a living world rather than out-execute it. The game has no combat execution; the skill is *reading people and orchestrating consequence.*

**The problem it solves:** most "living world" games are aquariums — rich to watch, but the player's actions don't legibly ripple through them. TKYDS makes the simulation *actionable and legible*: you read the board, pull a lever, watch it ripple through real actors, and re-read — with the entire relationship state written diegetically on NPC bodies rather than in floating bars.

### What Makes This Special

1. **One interface, many genuinely-distinct paths to power.** The player commands through a single interface, but pursues power along composable value-chains — war (iron, lumber, smiths feeding a war machine), commerce (real estate, vice, wholesale-and-resell through hired merchants), crime, secrets-brokering, public service, and more as systems layer in. Paths are **data, not code** (no system may name a playstyle); they are differentiated by their *primary constraint* and the fact that borrowed tools from other routes are available but taxed at a premium — so specialization pays and "do everything" loses on efficiency, not by prohibition. Each route must clear a three-part distinctness bar: distinct people-and-stats to operate it, every interaction terminating in a person's genuine decision that can go against you, and a characteristic way the route breaks (buildable from shared primitives).

2. **The interface is the world — diegetic legibility.** No floating bars. A character's body, greeting, and worn allegiance *are* the readout. You read whether a merchant's greeting is a rung colder than yesterday and infer someone got to him. Player skill is social perception, not timing. The relationship graph isn't a screen you check — it's something you witness as you move through the world.

3. **Traceable emergent consequence.** Because power is causal reach and the world runs unscripted, accumulated decisions — hidden *or* overt — produce large outcomes, such as a war or famine you predicted and profit from, that rival actors visibly tried and failed to foresee. The payoff is *authorship you can trace*: the private thrill of causing an outcome whose true reach and method the world can never fully read back to you, whether or not it saw your hand move.

4. **The unifying design principle:** the game brings things into focus; it never takes your notes away. It rewards attention and denies certainty, but never confiscates what the player earned by looking.

**Key Risks (named up front, because they are design-defining):**

- **The tycoon trap.** Because paths are economic value-chains, the game risks reading as a supply-chain management sim. Guardrail: *the game scores political reach, not wealth. Any actor — including the player — may pursue wealth for its own sake (many NPCs will, which is what makes the world believable), but wealth only advances the player's arc when converted into sway over people's decisions. Every economic verb terminates in a person.*
- **Path parity.** Multi-path promises collapse when one path is secretly "the real game." Each route must reach a top-tier outcome the others structurally cannot, and must be able to compete *across* routes (a merchant prince must be able to out-maneuver a warlord).
- **Design risk over technical risk.** As a solo Godot game there is no scale/compliance concern; the load-bearing unknowns are whether the core loop is *fun and legible*. Two requirements remain explicitly unvalidated: early reads must be comparative (never pure noise), and hidden actors must genuinely act and leave a coherent trail off-screen (never a fog toggle over a static graph).

## Project Classification

- **Project Type:** Single-player PC game — emergent-simulation / systemic RPG (Godot 4, PC/Steam), utility-AI actors over a shared stat substrate.
- **Domain:** Systems-driven simulation game; social/political immersive-sim adjacent (reference class: Crusader Kings III, Dishonored, Disco Elysium, Shadow of Mordor's Nemesis system).
- **Complexity:** High — design-risk-dominated, not infrastructure-dominated. Novel, deeply interdependent systems (emergent NPC sim, promote/collapse LOD, diegetic legibility); the risk is proving fun/legibility, not scale.
- **Project Context:** Greenfield design layer on a brownfield substrate. A demand-resolver economy (hunger→food→labor→money) is already shipped in Godot; this PRD specifies the social/leverage/power layer built on top of it.

## Success Criteria

*This is a solo, design-risk-dominated project. Success is defined as **proving the core design is fun and legible** — not commercial performance. Commercial criteria (wishlists, reviews, revenue) are explicitly deferred until the design proves out and are out of scope for this PRD. Success criteria are **path-agnostic**: direct/overt play (commanding, coercing) is a first-class route, equal to covert manipulation.*

### User Success

The player succeeds when:

- **The authorship moment fires — by any means.** After exerting power over the world, the player can say: *"I caused this. My decisions propagated through people and reshaped what happened."* This holds whether they **acted directly** (commanded, coerced, forced) or **indirectly** (maneuvered someone into it). The thrill is **authorship of consequence**; the *illegibility* is that the world can't fully read the reach and method behind it — **not** that the player was hidden.
- **The world feels alive and responsive to their actions** — early and throughout. A direct action lands and the world visibly reacts; an exercise of influence (through **loyalty** or through **coercion/fear**) visibly moves an actor or outcome.
- **Reads become a learnable skill** — the player learns to read diegetic state (greeting rungs, allegiance, tells) and correctly infers change, taught via rigged first cases and information actors that teach a *verb, not a fact*.
- **The climb feels earned** — the player moves along the arc from powerless to power that propagates, and *feels* their growing reach as new actions, more **individuals to direct**, goals to set, and strategies to command unlock.
- **They come back voluntarily** — the "one more move" pull.

### Project Success (design-proof milestones)

*Commercial metrics deferred. "Winning" = the design holds up under playtest:*

- **The core power-over-people loop is proven fun** — the player exerts influence over an actor (directly, or through loyalty/coercion/fear) and it **propagates and is legible**. This is proven first for **direct** influence (the alive/responsive world) before indirect leverage is layered on.
- **The multi-path promise is proven real, not narrated** — at least two divergent routes feel distinct *in the hand*, and the set spans the range from **overt/confrontational** (e.g. war — commanding soldiers, feeding the war machine) to **covert** (e.g. crime or secrets). The overt path must feel like TKYDS, not a bolted-on RTS.
- **The off-screen-truth requirement is validated** — hidden actors demonstrably act and leave a coherent trail while unseen, proven in the smallest form before any reveal/progression UI is built on it.

### Technical Success

- **Playstyle = data, not code.** Divergent routes are expressed as data bundles (derived-stat lever + curve set + gated rows) over one universal action set; no code names a playstyle. A new route is authored as data, not a subsystem.
- **The shared substrate holds** — the narrow stat-store accessor, lazy-with-version derived stats, and sparse+inheritance social graph keep the sim performant at the target actor count for a slice (dozens of live individuals, masses as faction-level aggregates) without stutter.
- **One promote/collapse seam** serves both spatial and social level-of-detail; the "traitor" (covert individual) can be born from aggregate on demand.

### Measurable Outcomes (playtest-testable)

*Phased to match Product Scope — the MVP is measured only against MVP bars. Sample size for a solo project: **n ≥ 8** first-time playtesters per phase gate, recorded sessions, no coaching.*

**MVP gate — the proving scene:**
- ≥ **6 of 8** playtesters, unprompted, attribute the outcome to **their own earlier investment** ("A helped me because I bought him that drink"), not to luck or to a meter.
- ≥ **6 of 8** playtesters who *skip* the investment and reach the yield state correctly identify what they should have done differently, **with no text tutorial**.
- A playtester correctly reads a manufactured relationship *delta* (a greeting cooled one rung) **within the first rigged encounter**, with no text tutorial.
- A playtester correctly infers **which driver** a given actor's channel runs on, from tells alone, within one session.

**Growth gate — multiplicity and cascade:**
- The same playtester, playing two routes — **one overt, one covert** — makes demonstrably different moment-to-moment decisions (different people, different characteristic failure), confirmable from a session recording with fiction stripped.
- A playtester can **trace a multi-step outcome back to their own initiating action** when asked "why did this happen?"
- A playtester **predicts a cascade before it resolves** and the prediction is recorded and later confirmed or refuted.

**All phases:**
- ≥ **70%** describe outcomes as *them causing it by directing, pressuring, or commanding people* — regardless of overt or covert play (not "I raised his friendship meter").
- Voluntary continuation past a natural stopping point.

## Product Scope

### Sequencing Rationale (why direct action comes first)

Direct action ships before acting-through-others for a **structural** reason, not a pedagogical one: **acting through another actor is provider-matching over an action that must already exist.** There is nothing to delegate until there is something to do. This is a dependency, not a difficulty ramp, and it does not rank the two.

This supersedes any reading of `design-session §1` ("leverage is the core combat") as a *sequencing* claim. That section was re-litigated in-source on 2026-07-24: leverage is **one path** — the covert/through-others form — and direct/overt action is **first-class and equal**. The spine is illegible authorship, not concealment.

### MVP — the proving scene

The MVP is a **single scene** that exercises the whole mechanical spine at depth 1, in the honest-but-ugly skin (portraits + posture/standing icon + one line of event text):

1. The player, living in the **shipped needs substrate** (hunger→food→labor→money), earns coin and makes a small **direct investment** in actor A — buying a drink — which raises a channel A holds toward the player.
2. Later in the same scene, actor B escalates against the player. The player is **outmatched**; drawdown begins.
3. The player's own demand for aid is emitted by the sim. **A, in proximity and now held, resolves it** — visibly and attributably acting.
4. B's evaluation changes; the aggression subsides.
5. **If the player did not invest, no one resolves the demand and the player yields.**

**What it proves:** needs-and-utility producing organised behaviour with *no goals present anywhere*; a held channel changing **who matches a demand**; direct investment paying out **through another person**; and a genuine **fail state**.

**The fiction is not the requirement.** A pub, a drink, and three actors are an exemplar chosen because it exercises every rule at minimum cost. What binds is the **structure**: a direct investment that raises a held channel; a later demand the player emits rather than commands; a held actor resolving it; and a failure branch when the investment was absent or misdirected. Any setting preserving that structure is an acceptable substitute, and the concrete details are expected to be tuned once the systems can be played.

**Why this scene and not a direct-influence demo.** The earlier draft MVP (influence an actor, watch the world respond) carries no consequence for declining to act — the exact flaw that sank the original pub slice, which three of four voices attacked for proving *a relationship meter, not the fantasy*. The tabled `pub-slice-leverage-seed.md` fixed the through-others half but kept a win condition that was purely a legibility test. This scene adds the missing half — something at risk — using only shipped primitives.

**Non-negotiable MVP content:** the influenced actor **genuinely deliberates and can refuse**, and the world **visibly reacts**. These are the two properties whose absence makes any version of this scene read as a meter with extra steps.

**Note on goals:** no goal exists anywhere in this scene — not for the player, A, or B. B escalates from *state* (disposition toward the player, opportunity against a weak target), not from an authored goal. The scene validates the substrate before the goal system exists.

**Also required in MVP:** the minimal reading loop — discrete greeting rungs, **LOOK held separate from GREET**, and a log storing the *previous* rung so the delta is visible.

### Growth Features (Post-MVP)

Ordered by dependency:

- **Directed dispatch** — the player explicitly sends a held actor at a target, rather than relying on latent payout.
- **Installed goals at depth 1** — the player installs a goal in a held actor, who resolves it themselves.
- **Trust** — observing whether assigned goals were executed, accumulating an inferred estimate of who delivers. Depends on installed goals existing to observe.
- **Promotion** — granting a trusted actor an authority channel over others (edge operation), enlarging the subtree a single installed goal reaches. NPCs promote too, so hierarchies form and become readable.
- **Layered goals and cascade** — goals installed at higher points in a hierarchy, propagating downward **by changing state**, not by copying goals.
- **A second and third distinct route** meeting the 3-part distinctness bar, spanning overt↔covert, with routes that **bleed** (borrowed tools at a premium). Prototype the **most divergent pair side-by-side early** (war/rupture vs. crime/exposure) — this attacks the path-parity risk while it is still cheap to fix.
- **Promote/collapse LOD** (individual ↔ faction) enabling the covert traitor and scaling the cast.
- **Information agents** (unreliable secondhand eyes); **visibility-as-progression** (fog over the social graph lifts as reach grows).
- **Diegetic legibility depth** — richer tells, sigils, context-of-observation.
- **Hex board — proving scene.** *Depends on installed goals, trust, promotion, and cascade* — board placement is rank-ordered by loyalty/trust (needs trust to exist) and the jurisdictional ownership layer is authority/promotion made geometric (needs promotion to exist). A handful of hand-placed hexes, no procedural generation, reusing actors already live from the ground-level slice. Proves: zoom continuity (same coordinate space as the walked world), the install/placement/occupied-capacity loop, a visibly legible "seize control" interrupt, and consequences landing at ground level rather than in the capacity math. Core verb only (FR88-FR96); see FR97-FR99 and Vision below for territorial legibility and terrain generation.

### Vision (Future)

- The full **become-the-unseen-power** arc at kingdom scale, reachable by *any* path — overt or covert: rival kingmakers generating live counter-goals; the **traceable emergent epic moment** (a war/famine you predicted and profited from that rivals failed to foresee).
- **Far-region simulation** via night-ticked headlines/newspapers as the sole cross-tier channel.
- The full spread of value-chain paths (war, commerce, crime, secrets, public service, and more) with **parity** — each reaching a top-tier outcome the others can't.
- Multiple **win conditions** spanning the overt-to-covert spectrum (the Puppeteer at one end; commanding, visible dominance at the other), sustained over time.
- **Hex board — generative richness.** The full terrain-generation pipeline (elevation → hydrology → biome, FR99), the settlement template library, the two-speed territorial-legibility rollup (FR98), and the scattered asset-ownership layer (FR95) — kingdom-scale content and presentation depth built on the Growth-tier board core.

## Core Mechanical Model

*How the systems interlock. This is the mechanical spine the Functional Requirements express — every FR traces to a rule stated here. Derived from the shipped demand-resolver substrate (`poc-v2-system-spirit.md`) plus the 2026-07-25 author elicitation.*

### The atom (shipped)

A demand hits a resolver each tick. The resolver either satisfies the demand or emits the child demand it requires and waits on it. Actors generate demands from needs; demands find providers. No world-state triggers. This is **shipped and proven** for a material economy that bootstraps its entire supply chain from an all-idle start with **zero authored goals**.

**A demand is not a persistent object with its own memory.** It is a derived read: whenever a need's underlying stat crosses its threshold, the Simulation reports an open demand from that stat, recomputed at each check exactly like any other lazy-with-version derived value. The stat is the only thing that persists — hunger keeps decaying whether or not anything is currently addressing it. What other actors discover and pick up is a live index of which actors currently read as having an open demand, not a queue of remembered intentions.

**The exception is intent that came from outside the actor.** A goal installed in someone, or an obligation handed to them, is stored — because nothing in their own stats will regenerate it. The discriminating test is regenerability, not persistence (FR101): if the next scoring pass would rediscover it, storing it is a second memory of intent; if it would not, refusing to store it is amnesia.

The social/political layer adds **no second engine**. It adds drivers (safety, standing, belonging), derived stats over the social graph, and a filter on **who gets matched to a demand**.

### Behaviour — needs by default, goals and obligations by exception

- **Needs plus utility is the default.** An actor scores available actions against current state and acts. This requires no authoring and produces organised collective behaviour on its own.
- **A goal biases the utility of a hand-authored action set.** Goals never script actions. They exist to carry what utility structurally cannot: persistent intent, action against immediate utility, and **intent that originated outside the actor**. A goal shifts many weights at once and carries no completion condition.
- **An obligation is a single piece of assigned work, and it competes rather than biases.** It enters the actor's candidate set as a peer action carrying its own weight, so an ordinary need can outbid it (FR13) and it is still owed afterwards. The two shapes do different jobs and neither replaces the other: a goal makes a *class* of actions attractive across time, an obligation is *one thing* that must get done — and a goal may emit obligations. Per-item urgency ("the stew before the ale") is expressible only in the obligation shape; an aim reshaping a dozen weights at once is expressible only in the goal shape.
- **Goals are sparse.** Actors inherit faction-level defaults; only *deviating* individuals store an explicit goal — the same sparse-plus-inheritance pattern as the social graph.
- **Consequence:** because goals are rare, installing one in someone is a visible act of authorship. Goal scarcity is what makes goal-setting a power fantasy rather than noise.

### Eligibility — what an actor can even attempt

- Before anything is scored, the Simulation filters which actions an actor is even eligible to attempt. Eligibility is a cheap precondition check (role, faction, possession, position) evaluated against actor state — not a scoring judgement, not a memory, and not gated by goals.
- **A protected universal set is eligible to every actor, always.** Survival responses and direct interpersonal actions (eat, flee, confront, beg, steal, hold ground) are **explicitly marked protected** and compete in every actor's scoring pass regardless of role; their eligibility is never evaluated. The marking is explicit and never a missing predicate — an author who forgets to gate an action has written a bug, not promoted it into this set. **Protection is by category, never by instance:** a starving man must always be able to attempt `eat`; he is not entitled to have every inn in the region scored. This is the same guarantee that lets a sufficiently-held actor hold his post while starving: nothing may be pruned from this set by identity, only by weight.
- **Specialised actions declare their own eligibility as data** — a throne claim requires holding a claim; a guild vote requires guild membership; a smuggling run requires contraband in hand. A new action ships with its own precondition; no actor-side code changes.
- **Goals never determine eligibility.** Goals are sparse (most actors carry none) and only bias weight within whatever pool eligibility already produced — gating the pool by goal would leave the goal-less majority with no pool at all. This sharpens FR9: the "hand-authored action set" a goal biases is that actor's eligible capabilities plus their outstanding obligations (FR87, FR100), never the full action registry.
- **Why this exists:** without it, per-actor scoring cost grows with the size of the entire action library, not with what that actor could plausibly do — and a peasant's decision loop would score "seize the throne" every tick alongside "eat bread." Eligibility keeps both the frame budget and the fiction honest, using the same mechanism for both.

### Arbitration — everything outbids, nothing overrides

- Motivation is a **composite scalar** fed by competing drives. No categorical overrides, no hard-fail states.
- **Survival outbids.** Hunger and exhaustion are weighted steeply enough to dominate in the common case: an actor whose survival drive is unmet abandons an installed goal and resumes it when the drive normalises. This happens **by outbidding, not by rule**.
- **Why not a rule:** a hard survival override was built and deadlocked the sim (the build that hard-failed on hunger never recovered). It also creates actors who cannot be moved, contradicting the premise that everyone has a price.
- **Weighting, never a checked-first gate.** All competing drives — survival included — score in the same pass; nothing is evaluated only after another drive has already been ruled out. If flicker appears at a threshold boundary, the fix is a two-threshold hysteresis band on that stat (enter at one value, don't clear until a higher one), authored as data — never a special-cased priority check.
- **Consequence:** a sufficiently-held actor holds his post while starving. That scene is emergent, not authored.

### Influence — one slot, filled by the channel you hold

Whether an installed goal clears an actor's action-decision threshold is gated by **the channel the player holds over that actor** — loyalty, fear, economic dependence, authority, or informational exposure. One slot, one mechanism; the stat filling it differs per route. A patron's world is scored through loyalty, a coercer's through fear. This is why routes need no separate influence systems.

The channel sets the *weight* an installed goal carries into the actor's ordinary scoring pass; it is never permission to install. Anyone may attempt; the deliberation — and the refusal — happen in the same pass as everything else (FR31).

### Drivers — different people want different things

- Each actor's channels are fed by a **per-actor driver set with per-actor weights**: one man's loyalty runs on wealth above a threshold, another's on standing with the player, another's on safety.
- **This is the content of the reading skill.** The core competency is not "read the number" but *work out what this person actually needs*. Non-verbal tells gain meaning: a tell signals an unmet driver, and the driver set determines which lever applies.
- **Route distinctness partly follows for free:** a wealth-driven actor is the commercial route's natural client, a safety-driven actor the martial route's.

### Persistence — rented or owned

Each driver carries a persistence model.

- **Transactional** — evaluated against the actor's *current* state. Held only while the player is relieving a currently-unmet driver. Computed, not stored (a derived stat).
- **Accrual** — favours accumulate on the social-graph edge and decay slowly. Survives lean periods. Stored as a primary on a deviating edge.
- **Consequences:** transactional holds are cheap to acquire, cheap to lose, and must be continuously fed; accrual holds are slow, expensive, and durable. An enterprise financed on transactional holds ruptures **all at once** when its driver supply fails. And transactional leverage runs on an *unmet* need — enriching the people you hold by wealth loosens your grip on them.
- **Fear is a third shape:** it decays fast without renewal and **inverts into resentment**, paying out as betrayal. This is the coercive route's characteristic failure. It must be **recoverable by a route-appropriate action** (renew credible threat, remove the resentful, convert the hold to another channel) — never a one-way penalty for playing cruel, which would rebuild the parity failure the comparables warn against.

### Reach — acting through others

- **Delegation is provider-matching where the provider chose you.** When a demand is emitted, who picks it up is filtered by the channels held toward the emitter. Acting through others is not a separate subsystem — it is the shipped provider-match with a social filter.
- **Direct action is the player resolving their own demand.** First-class, not a lesser mode: you show up when the outcome warrants spending your presence.
- **Delegation costs intent fidelity, not quality.** A more competent delegate produces a *better* outcome than the player would. What is lost is control — the intent passes through actors who deliberate, decompose it by their own lights, and carry their own drives and agendas.
- **Presence is scarce in breadth.** There are more decisions than one actor can personally attend to. This is what forces intent downward, and it is the reason delegation exists.

### Trust and promotion — choosing whom to act through

- **Trust is the Player's estimate that an actor will deliver**, accumulated by observing the outcomes of goals that actor was given. It is different in kind from a held channel: a channel is *why an actor complies* and points from them to the Player; **trust is a belief and points from the Player to them**.
- The two are independent, and the **combination** is the decision. An actor the Player holds but does not trust is kept close and not elevated. An actor the Player trusts but holds no channel over is competent and unleashed — dangerous to promote before a channel exists.
- **Trust must be inferred, never counted.** The Player observes the *outcome* of an assignment, not its *cause*: a failure may be incompetence, the actor's own drives outbidding the goal, or third-party interference, and these are not distinguishable from the outcome alone. A visible success counter would rebuild exactly the competence bar the diegetic-legibility pillar exists to avoid.
- **Promotion grants an actor an authority channel over a set of other actors.** Implemented as an **edge operation** on the social graph — a large, visible edge write — not as an explicit position or org-chart slot. *Roles as contestable positions (vacancy, succession, inheritance) are deferred until roles matter; the edge operation is the seam.*
- **Promotion is the lever on power.** Because power is the size of the subtree whose behaviour changed under an installed goal, elevating a trusted actor enlarges the subtree a single installed goal reaches. This is kingmaking in mechanical form: the Player does not take the position, they place someone in it.
- **Promotion manufactures a rival.** Authority is itself a channel, so a promoted actor accumulates their own reach, holds others, and can install goals of their own — including goals contrary to the Player's. It compounds with fear-inversion: an actor held by fear and then promoted carries resentment proportional to the authority granted.
- **NPC actors promote too**, elevating those they trust. Organisational hierarchies therefore form without authoring, and the Player can **read an organisation by observing who rises** — inferring who trusts whom from the shape of the hierarchy.

### Cascade — intent at the top, needs below

- A goal installed high in a hierarchy propagates **by changing the state everyone below reacts to**, not by copying goals downward. A lord given an aim cuts wages, locks a granary, or calls a muster; the people beneath him respond through their own needs.
- **Power becomes computable.** "How many people fall under the shadow of your decisions" is the size of the subtree whose behaviour changed under an installed goal — a measurement, not a metaphor.
- **Progression is a ladder of leverage over state, not of rank.** A goal installed in a prestigious actor who controls nothing changes nothing. Reach must be measured as access to actors who can move state.

### The Board — spatial interface to reach and cascade

*Added 2026-08-02, validated by a four-agent party-mode roundtable against `hex-board-influence-layer-seed.md`. The board is an interface onto mechanisms already specified above (reach, cascade, promotion, persistence); it adds one new persistence shape (occupied capacity) and one new generation mechanism (terrain), and reuses everything else.*

- **The board is a zoom level of the same world, not a second interface.** A hex resolves through the existing `location → tags` lookup; the player walks the ground and zooms out to the same coordinate space, never switching to a disconnected screen.
- **The board's only verb is targeting.** Installing a goal at a hex installs it in whoever holds that location — the same goal-install mechanism (FR11, FR12, FR45), aimed at a place instead of named directly. No second goal-installation system exists.
- **No new currency.** Board actions spend the same per-channel reach (FR46) as any other exercise of influence.
- **Placement priority is rank-ordered by loyalty and trust** (FR27, FR77-FR78) when more than one actor could install on the same hex.
- **A placed goal sticks and resolves on its own clock**, matching the stack-not-pause cadence already used elsewhere — it is not continuously re-arbitrated against a rival's competing install. This governs the board/placement layer only; ground-level arbitration (an actor's own drives outbidding a goal, per Arbitration above) is unchanged.
- **Contesting a standing goal is a discrete played action ("seize control"), not passive re-arbitration.** It can target only a standing goal (a permanent, below), never a one-shot goal that has already resolved. It is single-depth by design — it cannot itself be countered — a deliberate scope limit, not a structural ceiling.
- **A board goal is either an instant or a permanent.** Instants resolve once and release their occupied capacity. Permanents stand until revoked, interrupted, or otherwise resolved, occupying capacity the whole time. Both cost reach to install.
- **Capacity is occupied, not drained, not a refilling gauge** — a third persistence shape alongside transactional and accrual (Persistence, above). Installing a goal ties up a portion of the Player's current reach for as long as it is active; capacity returns in full when the goal resolves, by any means (success, failure, or interruption) — reach itself is never damaged, and never a flat per-cycle refill. This is tracked as a small stored index of the Player's own currently-active installed goals and their cost, not a scan of the world's goal state — the goal itself is already legitimate stored state (FR10); the index is bookkeeping over goals that already exist, not a second memory of intent (contrast FR84).
- **Outcome consequences land at ground level, never in the capacity math.** Whether a goal succeeds or fails, its capacity returns the same way; consequences are felt through the existing relationship/channel machinery (FR35).
- **Two ownership layers, reusing existing storage shapes.** Territorial/jurisdictional control (authority and promotion, FR81-FR83, made geometric) is contiguous and hierarchical, using the same sparse+inheritance pattern as the social graph. Asset/enterprise ownership (FR55, made geometric) is scattered and crosses jurisdiction freely, using the same sparse-edge pattern as accrual channels. Both render as toggle-able overlays on one board.
- **A hex's resource stat is not a new data structure.** It is whichever primary the shipped economy already tracks at that location (production, worker count, wage) — one source of truth between the board and the walked world.
- **Social/influence state is a toggle-able overlay on the same board**, not a second board — every actor already resolves to a hex through jurisdiction or enterprise, so social state paints onto ground that already exists.
- **Territorial legibility extends diegetic presentation (FR67-FR69) from body scale to territory scale.** A rollup, the same shape as the existing reach rollup, aggregates the tell/driver state of actors within a domain's footprint, computed at two speeds: a frequent "mood" and a long-window, smoothed "character." The claimed identity an actor broadcasts (FR22) sits alongside this honest aggregate, not in place of it — the gap between the two is the read.
- **Terrain generation is a separate, one-way mechanism, not a second use of the actor promote/collapse seam.** A cheap macro layer (elevation, hydrology, biome) generates once, globally, up front. Settlement-level detail generates once per region, on first attention, from a small authored template library with parametric (not structural) variation — a step with no inverse. Once generated, the actors populating that settlement promote and collapse through the existing, unchanged seam (FR73).

### Conflict — resolution without execution

- Contested conflict resolves as a contest of **state**, not player execution. An actor can be outmatched, take drawdown, and reach a yield state. No timing or aiming skill; no permadeath.
- **The counterplay to physical conflict is social.** You do not out-fight; you out-invested. A third party holding a channel toward the player can intervene, changing the aggressor's evaluation.

## Explicit Non-Goals

*Decided against, not merely unscheduled. Listed so downstream work does not rebuild them.*

- **Counterfactual pivot-marking.** The sim does not mark "the node where your influence was decisive." Authorship is delivered by **predict-then-watch** — the player causes a pivotal decision and predicts the cascade, then sees it land. The visible chain plus the player's own prediction *is* the authorship; the percentage that tipped a decision is out of scope.
- **Hard-fail / permadeath states.** The world stays recoverable. See "Arbitration" above.
- **Categorical survival override.** Built once, deadlocked the sim, replaced by outbidding.
- **Passive social-proof as leverage.** "You look protected because you're in with A" is rejected. A proxy must **visibly and attributably act**.
- **Denial of recall.** The game never confiscates observations the player earned by looking. Certainty is denied; recorded notes are not.
- **Sub-threshold gradients in relationship readout.** Greeting rungs are discrete and never subdivided; intensity lives in the sigil/colour channel.
- **Combat execution.** No timing, aiming, or reflex skill. Conflict resolves from state.
- **Commercial success metrics.** Deferred until the design proves out; out of scope for this PRD.

---

> ⚠️ **MIXED REVIEW STATE BELOW.** **Journey 1**, the **Functional Requirements**, and the **Non-Functional Requirements** are current — rebuilt in the 2026-07-25/27 author elicitation and traced to the Core Mechanical Model. **Journeys 2–4**, **Domain-Specific Requirements**, **Innovation & Novel Patterns**, **Game-Specific Requirements**, and **Project Scoping** still carry 2026-07-24 single-pass draft content and are **pending review**. See **"Open Questions"** at the end.

## User Journeys

*Single-player game: the sole user is the player. Journeys map the arc's phases and the divergent paths (kept path-agnostic — one overt, one covert), and each reveals required capabilities.*

*Journeys 2 and 3 are **alternative runs**, not one playthrough. They use distinct names (Aldric, Varo) to make that explicit. Phase tags map each journey to Product Scope.*

### Journey 1 — The Newcomer (early game: the proving scene) · **[MVP]**

> **Placeholder, deliberately.** This journey exists to exercise the systems end-to-end — it is not authored content and carries no narrative commitment. **The FR references at the end are binding; the fiction is not.** Names, the pub, the drink, the specific tells, and the shape of the provocation are all expected to change once the systems are in hand and can be tuned against. Read it as a test harness with a story wrapped around it.

**Opening.** Aldric arrives with an empty purse and a growling stomach, in a town that was already living before he got there — bakers working, guards patrolling, a merchant haggling over a price nobody asked him about. He takes work, earns a few coins, eats. Nobody greets him warmly: cold nods, and hands that stay in pockets. He is an actor the world acts upon.

**Rising action — learning to look.** An old steward at the next table teaches him a way of seeing rather than a fact: *"Everyone in this room wants something they haven't got."* He tips his cup toward the loud man at the centre table. *"Not him. He's full. Buying that one a drink is money in a hole."* Then nothing more — he never says who *is* worth it.

So Aldric starts to **LOOK** before he greets. Two men. **Corwin** holds the centre of a table, laughing, three drinks already in front of him. **Bram** stands a half-step outside that same table, facing it — in it and not in it. Same room, same posture at a glance. One wants nothing Aldric can give; the other wants something a copper can buy.

Aldric buys Bram a round. It costs most of what he earned, and it reads as courtesy, not strategy. Bram's greeting warms a rung — and the log keeps the old one, so Aldric can see the arrow.

**Climax — the round comes back.** Later a drunk named **Kestrel** takes offence over nothing and escalates. Aldric is outmatched. He takes drawdown, and there is no button that fixes it.

Bram hesitates — visibly, long enough that it reads as a decision and not a trigger — then steps in and puts a hand on Kestrel's chest, spending his own standing to do it. Kestrel reads the room again: this is no longer a lone stranger, and the sums have changed. The aggression subsides.

Aldric never asked. He had no goal set for Bram, and Bram had none set for him.

**The other branch.** Had Aldric kept his coin — or spent it on Corwin, who needed nothing — nobody would have moved, and he would have yielded on the floor of a pub in a town that does not know his name.

**Resolution.** The lesson is not *I made a friend*. It is that **the room was a board the whole time.** People carry needs; needs are legible if you look; relieving one buys something that returns later in a shape you did not specify and could not have commanded. Aldric could not see the web an hour ago. He has seen one thread of it now — and behind that, an unsettling question: how many threads are there, and who is already pulling them?

*Reveals requirements:* FR1–FR5 (living substrate, player as low-status actor); FR8 (organised behaviour with no goals present anywhere); FR15–FR18 (LOOK vs GREET, discrete rungs, prior-rung delta); FR19–FR21 (tells indicating an unmet driver; per-actor drivers); FR23 (comparative read — Corwin against Bram); FR24–FR25 (information actor teaching a verb; rigged contrast); FR27, FR33 (held channel via a social driver, accrual persistence); FR31 (genuine deliberation that can refuse); FR39–FR40 (held actor resolving the player's emitted demand, attributed to the proxy); FR52–FR54 (conflict without execution, yield state, third-party intervention).

### Journey 2 — The Warlord (mid game: an overt / direct path) · **[Growth]**

**Opening.** Aldric has chosen force. He wants a province to answer to him — openly.

**Rising action.** He builds a value-chain: secure iron, employ smiths, keep them fed and producing, arm men whose **loyalty** he has cultivated so they charge cheap. He directs individuals — captains, quartermasters — sets goals, watches the metrics that matter to this route (supply continuity, men's willingness).

**Climax.** A rival warlord moves against him — and a smith, unpaid and starving, halts production at the worst moment (the route's characteristic failure: **rupture**). Aldric must recover with a route-appropriate action: re-secure the link, feed the smith, or lean on a merchant (a **borrowed tool at a premium** — he lacks the commercial standing, so he pays retail).

**Resolution.** The province answers to him — visibly. He is a *seen* power, yet the full apparatus behind his command (whom he broke, what leverage he spent) the world never fully reads.

*Reveals requirements:* value-chain enterprises (production, employment, provisioning) on the economy substrate; directing multiple individuals; per-route metrics/goals; the characteristic-failure model (rupture) from shared primitives; route-specific antagonists (rival warlords, hungry workers); cross-route borrowed tools with a premium cost.

### Journey 3 — The Unseen Hand (mid game: a covert / indirect path) · **[Growth]**

**Opening.** A different run, a different player-character. Varo wants the same province — but his name on nothing.

**Rising action.** He works through others: cultivates a proxy, spends standing so the proxy **visibly acts** against a target Varo never touches. He recruits an **information agent** — an unreliable secondhand eye — to read a room he cannot enter (*"Varic wouldn't meet my eye when the Queen came up"*), and must weigh both the target and the reporter's bias.

**Climax.** A rival begins to suspect a hidden hand (the route's characteristic failure: **exposure**). Varo must suppress the leak through his proxies without surfacing himself. A wrong probe costs him standing, not a reload.

**Resolution.** The province shifts and the world credits its own actors. Varo holds the private ledger of causation — authorship the world cannot read back to him.

*Reveals requirements:* proxy-acts-on-your-behalf (leverage); information agents as unreliable eyes; exposure/concealment pressure; anti-save-scum (wrong reads cost relationship, persistently); the traceable causal chain surfaced to the player.

### Journey 4 — Becoming the King You Don't See (late game: the payoff) · **[Vision]**

**Opening.** The player-character now has real reach — across channels, across the map. (Shown here as Aldric; the arc is path-agnostic and reachable from either run above.)

**Rising action.** His accumulated decisions ripple: he predicts that a locked granary will break a region, and positions for it — whether by commanding the lord (overt) or maneuvering him (covert) — now concretely the board's goal-install-at-hex, ranked by trust and contestable by a rival's "seize control" (see Core Mechanical Model → The Board). Far regions report back as **headlines**. Rival kingmakers generate live counter-goals against a hand they cannot locate.

**Climax.** Famine → strike → mob → revolt breaks exactly as he foresaw, and he profits — while rivals visibly tried and failed to see it coming. He can **trace the chain** back to his own move.

**Resolution.** The kingdom moves to a will it cannot fully read — his. He has become the king you don't see, by whatever path he built.

*Reveals requirements:* per-channel reach/power (slow-tick PageRank); rival actors with live counter-goals; the traceable emergent cascade + attribution surfaced diegetically; far-region headlines as cross-tier channel; win-condition evaluation across the overt↔covert spectrum; FR88-FR99 (the board as the concrete mechanism for kingdom-scale positioning).

### Journey Requirements Summary

- **Survival & economy substrate** (shipped): needs, coin, labor as felt pressure driving actors.
- **Reading system:** discrete greeting rungs; LOOK vs GREET; observation log with prior-state deltas; diegetic tells/sigils; information/tutorial actors (teach a verb).
- **Influence & action:** direct influence via loyalty and via coercion/fear; leverage (proxy visibly acts); one universal action set with gated unlocks.
- **Value-chain / route system:** composable enterprises; per-route primary constraint, characteristic failure, and route-specific antagonist; cross-route borrowed tools at a premium.
- **Directing actors & goals:** direct multiple individuals; set goals that bias hand-authored action sets; per-route metrics.
- **Reach & progression:** per-channel reach vector; gate-evaluator unlocking actions/actors/strategies as reach grows; visibility-as-progression (fog lifts).
- **Emergence & payoff:** rival counter-goals; traceable cascade + attribution; far-region headlines; overt↔covert win conditions.
- **Simulation scaling:** promote/collapse LOD (individual ↔ faction); off-screen coherence.

## Domain-Specific Requirements

*The classification domain complexity is "high," but this is a **single-player PC game**, not a regulated-industry product. There are **no compliance/regulatory domain requirements** (no HIPAA/PCI/GDPR-class obligations beyond ordinary Steam-platform data handling; no payments in-game; no PII processing beyond platform standards). The meaningful "domain" here is the **emergent-simulation game-design domain**, whose known patterns and anti-patterns are treated as first-class constraints below.*

### Design-Domain Patterns to Honor

- **Utility-AI over data, not code** — behavior variety comes from stats/curves/goals; every actor runs one loop. (Reference: Dave Mark, *Behavioral Mathematics for Game AI*; The Sims object-advertised utility.)
- **One-substrate, verb-gated multi-path** — distinct playstyles come from which verbs a stat-profile unlocks against a shared world-state (reference: Crusader Kings III).
- **Emergence made legible via world-reaction** — paths and consequences must reflect back to the player through the world's visible reaction (reference: Dishonored Chaos read diegetically).

### Design-Domain Anti-Patterns to Avoid

- **The aquarium** — a rich simulation with no legible, actionable loop is not a game.
- **The tycoon trap** — value-chain paths that read as supply-chain optimization; economy must be the *means*, people the *point*.
- **Emergence without path-multiplicity** — a rich generator with one dominant verb (reference: Shadow of Mordor Nemesis) produces great stories about the *same* playstyle.
- **The cardboard reveal** — visibility-as-progression over a graph that is secretly static; hidden actors must genuinely act off-screen.

### Domain Risk Mitigations

- Enforce the tycoon guardrail (every economic verb terminates in a person; the game scores political reach, not wealth).
- Enforce path parity (each route reaches a top-tier outcome the others cannot).
- Prove off-screen coherence in the smallest form before building reveal/progression UI on it.

## Innovation & Novel Patterns

### Detected Innovation Areas

1. **Political propagation power gated behind player-composed value-chains.** The novel core: distinct routes to power are *economic/social engines the player assembles* (war, commerce, crime, secrets, public service), and what they buy is **causal reach over people's decisions** — not wealth or territory. This is CK3-style verb-gating expressed as composable value-chains rather than fixed skill trees. No shipped game clearly occupies this exact intersection.
2. **Diegetic legibility as the entire interface.** No floating bars; the character's body, greeting, and worn allegiance *are* the readout, and reading them is the core skill. The relationship graph is witnessed in the world, not checked on a screen.
3. **Illegible authorship as the core fantasy.** Power whose reach and method the world can never fully read — expressible along a full spectrum from hidden manipulation to overt command — with a traceable emergent payoff the player can claim.
4. **Unified promote/collapse LOD** where spatial distance and social salience are the *same* aggregate↔individual mechanism, so the covert individual (the traitor) is *born* from faction aggregate exactly when attention falls on them.

### Market Context & Competitive Landscape

- **Crusader Kings III** — closest comparable for one-substrate/verb-gated distinct paths; TKYDS differs by expressing paths as composed value-chains and by embodied, diegetic legibility rather than menu-driven schemes.
- **Dishonored** — one-substrate multi-path with world-reaction selling the fork; TKYDS extends the reaction channel to greeting/body-language and adds economic engines.
- **Shadow of Mordor (Nemesis)** — north star for traceable emergent rivalry; TKYDS aims to add the path-multiplicity Nemesis lacks.
- **Disco Elysium** — reference for embodied, continuous, socially-legible world without combat execution.
- **Civ 6 / Catan** — source of the hex board's resource-and-adjacency and strategic-zoom instincts, not its interface model: the board is a zoom level of the same embodied, diegetically-legible world (see Core Mechanical Model → The Board), not a disconnected menu-driven screen — the distinction that keeps the CK3 comparable's "not menu-driven" claim intact.

### Validation Approach

Innovation is validated by the design-proof playtests in Success Criteria — specifically: the traceable-authorship moment landing unprompted; two divergent routes (one overt, one covert) feeling distinct in the hand; and reads being learnable without a text tutorial. Ugly-but-honest prototype skin (portraits/icons/text) validates the loop before art spend.

### Risk Mitigation

- **If the multi-path promise fails to feel distinct:** fall back to fewer, more strongly-differentiated routes with hand-authored characteristic failures before expanding.
- **If diegetic-only legibility proves unreadable:** the reading system is a presentation seam; icons-as-training-wheels are a legitimate fallback that protect the vision without abandoning it.
- **If off-screen coherence proves too costly:** narrow the live off-screen cast (fewer promoted actors) rather than faking the reveal.

## Game-Specific Requirements (Project-Type Deep Dive)

### Project-Type Overview

Single-player, systemic simulation RPG built in **Godot 4** (GDScript authoring; C#/GDExtension reserved for a hot numeric loop only if actor counts demand it later), targeting PC/Steam. No multiplayer, no live-service, no backend. The technical heart is a shared utility-AI simulation the entire game reads and writes.

### Technical Architecture Considerations

- **Narrow stat-store accessor from line one** (`get_primary`, `get_derived`, `write_primary`) — the single boundary that lets storage graduate (Dictionary → `PackedFloat32Array` SoA → native loop) without rewriting call sites. *This is the load-bearing architectural wall.*
- **Derived stats: lazy-with-version**, recomputed per-(actor,target) on read against a primaries dirty-stamp — not recomputed-every-tick, not stale.
- **Social graph: sparse + inheritance** — store only *deviating* per-target relationships as explicit edges; all other pairs inherit a faction-level default. Player may be a high-degree hub (O(N)); dense mesh (O(N²)) is prevented.
- **Playstyle = data bundle**, never code: `{ primary_derived_lever, curve_set, unlocked_action_ids }` over one universal action set. **No class, function, branch, or file may name a playstyle.** Goals bias a *hand-authored* set of action tags.
- **Eligibility as a data seam, not a system yet.** Every action definition carries an optional eligibility predicate (role/faction/possession/position tags), defaulting to universally-eligible. Ship the field now; defer the full tag-resolution/pool-caching system until a second action's fiction actually requires gating — the current action set needs none of it yet.
- **Position resolves through a location fact, not physics, by default.** An actor's `location` (a discrete state, including an in-transit/no-location value that resolves to an empty tag set) maps through a static `location → tags` lookup consulted by the eligibility predicate above — no Area2D, no collision layer, no signal bus. Real spatial geometry (a moving/overlapping zone, refcounted tag state, a change-notification signal) is reserved for the rare case where distance itself is the fiction — e.g. a feared actor's proximity radius — not the default mechanism for named-place gating (a tavern, an office, a bathroom). Promote to a full zone/registry framework only when hand-authoring gates across many places stops scaling, not ahead of it.
- **Demands have no bespoke persistence layer.** "Still wanting X" is a re-derived read of a persistent stat, not a stored record — consistent with the lazy-with-version derived-stat rule above; the existing demand-tracking data structures are the internal implementation of that read, not a parallel authority.
- **Progression = per-channel reach vector** `{coercive, economic, authority, loyalty, informational}`, each a slow-tick rollup over the social graph; a single gate-evaluator filters a requirement-tagged unlock table (new unlock = new data row).
- **Power = eigenvector centrality (PageRank-style)** over the leverage graph, computed on the slow tick with a damping factor — never in the hot loop.
- **Two-tier world: events are the sole cross-tier channel** — the far world is night-ticked and emits idempotent, authoritative headlines; no continuous floats leak across the seam. Shared totals (coin, food) are conserved across the instantiate/collapse boundary, not made pixel-identical.
- **One promote/collapse seam** serves both spatial LOD and social-salience LOD; a faction-aggregated actor is promoted to a full individual node when attention (player, threshold, recruitment) falls on it.

### Implementation Considerations

- **Prototype rendering in the honest-but-ugly skin** (2D portraits + posture/standing icon + one line of event text). The diegetic 3D presentation (greeting ladder, tells, sigils) is a downstream presentation seam; the sim emits semantic signals regardless of skin.
- **Build order:** prove the alive/responsive world + direct influence first; add indirect leverage; then a second/third route (prototype the most divergent pair — e.g. war/rupture vs crime/exposure — side by side early); defer scaling, far-tier, nested goals, and 3D tell rendering.
- **Existing substrate:** the shipped demand-resolver economy (hunger→food→labor→money) is the foundation; the social/leverage/power layer is built on it, behind the stat-store accessor.

## Project Scoping & Phased Development

*Release mode: **phased** (MVP → Growth → Vision), consistent with the Product Scope defined in Success Criteria. Nothing the author specified has been de-scoped; phasing follows the author's explicit brick-by-brick sequencing.*

### MVP Strategy & Philosophy

**MVP approach:** *validated-learning / experience MVP* — the smallest build that answers "does the world feel alive and genuinely responsive to the player's exercise of power over people?" **Resource requirements:** solo developer; Godot; no art/audio spend (portrait+icon+text skin).

### MVP Feature Set (Phase 1)

**Core journeys supported:** Journey 1 (The Newcomer) — *pending rewrite to match the proving scene.*

**Must-have capabilities:** as specified in **Product Scope → MVP — the proving scene**, which is authoritative. In summary: the shipped needs/economy substrate as felt pressure; a direct investment raising a held channel; a demand the player emits being resolved by a held actor; conflict resolution with a yield state; the minimal reading loop (discrete greeting rungs, LOOK separate from GREET, log storing the prior rung); a rigged first case plus at least one information actor; the honest-but-ugly skin.

### Post-MVP Features

**Phase 2 (Growth):** as specified in **Product Scope → Growth Features**, dependency-ordered: directed dispatch; installed goals at depth 1; layered goals and cascade; a second and third **distinct route** spanning overt↔covert (prototype the most divergent pair — war/rupture vs. crime/exposure — side by side early); **promote/collapse LOD**; **information agents**; **visibility-as-progression**; richer diegetic legibility; the **hex board proving scene** (goal-install-at-hex, occupied capacity, instant/permanent + interrupt), dependency-ordered after installed goals, trust, promotion, and cascade.

**Phase 3 (Vision):** kingdom-scale become-the-unseen-power arc; rival kingmakers with live counter-goals; the traceable emergent epic moment; far-region headlines; full value-chain spread with parity; multiple win conditions across the overt↔covert spectrum; graduated presentation (3D greeting ladder, tells, sigils, context-of-observation); **hex board generative richness** (terrain generation, settlement templates, territorial legibility, scattered asset layer).

### Risk Mitigation Strategy

- **Technical risk (biggest):** the stat-store accessor + data-not-code discipline are the cheap insurance against a substrate rewrite; validate performance only at real actor counts, not speculatively.
- **Design risk (dominant):** prove fun/legibility in the ugly skin before art; prototype the most divergent route pair early to prove the multi-path bet.
- **Resource risk (solo):** every deferred system ships as a stub with a seam; presentation is faked until the loop earns the art budget.

## Functional Requirements

*The capability contract. Path-agnostic — direct and through-others are equal. Every FR traces to a rule in the Core Mechanical Model. Actors: **Player**, **NPC actor**, **Simulation**, **Author** (the designer authoring content as data).*

*Numbering policy: **FR numbers are stable identifiers.** The contract was rebuilt and renumbered once on 2026-07-25 (prior FR1–FR45 superseded); from that point numbering is **append-only** — a new requirement takes the next free number regardless of which group it is placed in, so downstream references never break. Group headers are organisational, not sequential.*

### Simulation Substrate & World Life

- FR1: The Simulation scores every actor decision — pursuing an unmet need, answering another actor's unmet need, or taking an immediate contested action — through **one shared weighted-utility mechanism** over that actor's current primary and derived stats; no decision is scripted per actor. A decision nested inside an action's execution — which provider, which target, which place — runs that same mechanism over a narrower candidate set, and is not a second kind of decision.
- FR2: NPC actors pursue needs and act autonomously whether or not the Player is present.
- FR3: The Simulation resolves an economy (food, labour, coin) from actor demands without world-state triggers.
- FR4: The Simulation never serves a stale derived stat — a derived value read at time T reflects the primaries as of T.
- FR5: The Player enters the world as a low-status actor subject to the same needs as any NPC.
- FR6: An actor's motivation is a composite of competing drives; no drive categorically overrides another, and no state is unrecoverable (no hard-fail, no permadeath).
- FR7: Survival drives are weighted to dominate in the common case — an actor with an unmet survival drive abandons lower-priority pursuits and resumes them when the drive normalises — achieved by weighting, not by an override rule. The weights sit in one shared tuning table, so "dominates" is a checkable relation between named constants rather than a property smeared across individual action definitions.

### Behaviour, Goals & Arbitration

- FR8: NPC actors produce organised collective behaviour from needs and utility alone, with no goal assigned.
- FR9: A **goal** — standing intent, installed from outside, persisting until revoked and carrying no completion condition of its own — biases the utility of a hand-authored action set already in the actor's eligible pool, and may emit obligations (FR100). Goals never script actions.
- FR10: Goals are sparse — actors inherit a faction-level default and only *deviating* individuals carry an explicit goal.
- FR11: The Player can install a goal in an actor over whom they hold a channel.
- FR12: Whether an installed goal clears an actor's action-decision threshold is gated by the channel the Player holds over that actor (any of loyalty, fear, economic dependence, authority, informational exposure). The channel sets the **weight** the goal carries into the actor's ordinary scoring pass; it is never permission to install, which would make the refusal invisible and contradict FR31.
- FR13: An installed goal competes with the actor's own drives and can be outbid by them.
- FR14: Rival actors generate and pursue their own persistent goals, including counter-goals against a hand they cannot fully locate.
- FR84: An actor's unmet need is derived from that actor's current primary and derived stats at each decision point; the Simulation does not store a separate persistent record of "still pursuing" beyond the underlying stat. Intent that originated **outside** the actor — a goal (FR10) or an obligation (FR100) — is the sole permitted exception, governed by FR101.
- FR85: Before scoring, the Simulation filters an actor's candidate actions to those the actor is eligible for, based on role, faction, possession, or position; ineligible actions are never scored.
- FR86: A protected set of survival and direct interpersonal action **categories** (eat, flee, confront, beg, steal, hold ground) is enumerated as data and eligible to every actor regardless of role, faction, possession, or position; a protected action's eligibility predicate is never evaluated. Membership is declared explicitly and is never inferred from a missing predicate — an omitted gate is an authoring error, not a promotion into this set. Protection covers the **category**, never a particular instance of it: narrowing which providers an actor considers is legitimate, leaving the category with no instance at all is not.
- FR87: An actor's candidate pool is their eligible capabilities plus their outstanding obligations (FR100). Goals bias the weight of actions already in that pool; goals never add or remove eligibility, and an obligation entering the pool is never exempt from the eligibility filter (FR85).
- FR100: An **obligation** — a discrete, dischargeable piece of work assigned to an actor from outside — enters that actor's candidate set as a peer action carrying its own weight, competing directly against the actor's own needs rather than modifying their scores. It is eligibility-filtered like any other action (FR85), remains owed while it is being worked on, and leaves the actor only when discharged, revoked, or expired. Competing rather than biasing is the stricter guarantee: a sufficiently large bias is indistinguishable from a script, whereas a peer candidate can always be outbid (FR13).
- FR101: The test for what an actor may store is **regenerability, not persistence**: anything the next scoring pass would rediscover from the actor's own stats is never stored (FR84); intent that no stat regenerates — a goal, an obligation — is stored on the actor, because deleting it deletes it for good. An actor never stores its own self-directed choice.
- FR102: The weight an assigned goal or obligation carries into an actor's scoring pass is computed from the assigner's held channel over that actor **at the moment of scoring**, not fixed at the moment of assignment. Until channels exist, that weight is supplied as an authored constant through the same seam, so implementing channels replaces a value and never a call site.
- FR103: An outstanding obligation expires when the condition that justified it no longer holds, and an obligation the actor is permanently ineligible for is discharged rather than remaining owed; no actor accumulates obligations without bound.

### Reading & Legibility

- FR15: The Player can **LOOK** at an actor to read current diegetic state without initiating an interaction or altering the relationship.
- FR16: The Player can **GREET** an actor, which both reads relationship state and opens available actions.
- FR17: An NPC actor's disposition toward the Player is expressed as one of a small set of **discrete greeting rungs**, never a continuous gradient.
- FR18: The Simulation records observed state per actor and surfaces the **previous** rung so the Player can perceive a delta.
- FR19: NPC actors express distinguishable non-verbal tells (fear, distraction, dislike, concealment) via orthogonal channels.
- FR20: A tell indicates an **unmet driver**, enabling the Player to infer which lever applies to that actor.
- FR21: Each actor's channel drivers differ; the Player must infer which need a given actor's channel runs on rather than reading a universal value.
- FR22: NPC actors display allegiance (sigil/colour) at variable intensity and may conceal it.
- FR23: Every read the Player can make is **comparative** — directional against another read or a prior observation — and never unanchored, including before the explicit ladder is unlocked.
- FR24: Information/tutorial actors teach the Player a reading *verb or category to watch for*, without naming the answer.
- FR25: The Simulation can stage rigged first-encounter cases that guarantee a legible contrast.
- FR26: The Player can adjust denial-of-certainty as a difficulty setting, without altering what the prosthesis records.

### Influence, Channels & Persistence

- FR27: The Player can build a held channel over an actor through cultivated **loyalty**.
- FR28: The Player can build a held channel over an actor through **coercion/fear**.
- FR29: The Player can build a held channel over an actor through **economic dependence**.
- FR30: The Player can build a held channel over an actor through **authority**.
- FR31: An actor's response to influence is a genuine deliberation that can go against the Player.
- FR32: **Transactional** channels are held only while the Player relieves a currently-unmet driver, and lapse when that driver is satisfied by any source or the provision stops.
- FR33: **Accrual** channels accumulate on the social graph from past acts and decay slowly, persisting through periods without provision.
- FR34: **Fear** decays rapidly without renewal and inverts into resentment, producing betrayal.
- FR35: Every characteristic failure — including fear-inversion — is recoverable by a route-appropriate action; no failure mode is a one-way penalty for a legitimate playstyle.
- FR36: A wrong read, probe, or acted-upon bad tip imposes a persistent relationship cost, not a reloadable failure.
- FR37: All influence draws from **one universal action set**; playstyle differences arise from dispatch mode, channel lever, curve set, and gated unlocks — never from separate action sets.

### Reach, Delegation & Cascade

- FR38: The Player can resolve their own demand directly by being present.
- FR39: An actor holding a channel toward the Player may resolve a demand the Player emits — acting-through-others is provider-matching filtered by held channels, not a separate subsystem.
- FR40: A proxy's action is discrete, logged, and attributed **to the proxy** in the world's view, never to the Player.
- FR41: The Player can explicitly dispatch a held actor against a target.
- FR42: Delegated execution's quality is a function of the delegate's competence and may exceed what the Player would achieve directly.
- FR43: Delegated intent loses fidelity — it is decomposed and interpreted by actors carrying their own drives and goals.
- FR44: The Player cannot personally attend to every decision available to them; breadth of attention is finite and is the constraint that forces intent downward.
- FR45: A goal installed high in a hierarchy propagates downward **by changing the state subordinate actors react to**, not by copying goals.
- FR46: The Player accumulates **per-channel reach** (coercive, economic, authority, loyalty, informational) derived from held channels across the social graph.
- FR47: Reach is measured as access to actors who can **move world state**, not as rank or prestige.
- FR48: Growing reach unlocks new actions, more actors to direct, and new strategies.
- FR49: The Player's growth increases **breadth of attention** rather than confiscating recorded observations.
- FR50: The Player has a diegetic memory prosthesis that faithfully records what they chose to notice; certainty may be denied, recall never.
- FR51: The Player can employ **information agents** returning partial, biased, secondhand reads at a cost, with the possibility of being wrong.

### Trust, Promotion & Organisation

- FR77: The Player accumulates a **trust** estimate of an actor from the observed outcomes of goals that actor was given.
- FR78: Trust is distinct from a held channel — the Player may trust an actor over whom they hold no channel, and hold an actor they do not trust.
- FR79: The **outcome** of an assigned goal is observable to the Player; its **cause** is not necessarily distinguishable between actor incompetence, the actor's competing drives, and third-party interference.
- FR80: Trust is surfaced as an inference over a logged assignment-and-outcome history, never as a certainty or a bare success count.
- FR81: The Player can **promote** an actor by granting them an authority channel over a set of other actors.
- FR82: A promoted actor accumulates their own reach, may hold others, and may install goals of their own — including goals contrary to the Player's.
- FR83: NPC actors promote actors they trust, forming organisational hierarchies without authored content, which the Player can read by observing who rises.

### Board — Spatial Interface to Reach and Cascade

- FR88: The Player can install a goal targeted at a hex; the Simulation installs it in whichever actor holds that location, using the same goal-install mechanism as FR11.
- FR89: When more than one actor could install a goal on the same hex, placement priority is ranked by the Player's loyalty and trust standing with the location's holder.
- FR90: An installed board goal resolves on its own clock without continuous re-arbitration against a rival's competing install; ground-level utility arbitration (FR6, FR7, FR13) is unaffected by this rule.
- FR91: The Player can contest a standing board goal through a discrete "seize control" action, targetable only against a standing goal, never against a one-shot goal that has already resolved.
- FR92: A board goal is either an instant, which resolves once and releases its occupied capacity, or a permanent, which stands and occupies capacity until resolved, revoked, or interrupted; both cost reach to install.
- FR93: Installing a board goal occupies a portion of the Player's current reach for the goal's duration; capacity returns in full when the goal resolves by any means, tracked as a stored record of the Player's own currently-active installed goals rather than a scan of all actors' goals.
- FR94: A board goal's success or failure does not alter occupied capacity; its consequences are expressed through the existing relationship/channel machinery (FR35).
- FR95: The Player can view and act on two independent ownership layers over the board — territorial/jurisdictional control (contiguous, hierarchical, one holder per region) and asset/enterprise ownership (scattered, crosses jurisdiction freely) — each rendered as a toggle-able overlay.
- FR96: A hex's actionable resource state is the same primary the shipped economy already tracks at that location; the board and the walked world read one number.
- FR97: Social/influence state renders as a toggle-able overlay on the same board as the ownership layers, keyed to actors already positioned via jurisdiction or enterprise, not as a separate board or coordinate space.
- FR98: The Simulation computes a territorial-legibility rollup — the aggregated tell/driver state of actors within a domain's footprint — at two speeds: a frequent current-mood read and a smoothed long-window regional-character read.
- FR99: The Simulation generates terrain in two layers: a cheap macro layer (elevation, hydrology, biome) for the whole kingdom up front, and settlement-level detail generated once per region, on first attention, from an authored template library with parametric variation.

### Conflict Resolution

- FR52: Contested conflict between actors resolves from actor state, with no player execution skill (no timing, aiming, or reflex input).
- FR53: An outmatched actor takes drawdown and can reach a **yield** state; conflict never produces an unrecoverable state.
- FR54: A third party holding a channel toward a participant can **intervene**, altering an aggressor's evaluation and de-escalating the conflict.

### Value-Chain Routes

- FR55: The Player can build composable economic/social **enterprises** (production chains, real estate/vice, illicit operations, information brokering) on the shared economy substrate.
- FR56: Each route exposes a **primary constraint** and a **characteristic failure mode** inflicted by the route's own actors and recoverable by a route-appropriate action.
- FR57: The Simulation opposes each route with a **route-specific antagonist behaviour**.
- FR58: The Player can use **another route's tools** at a premium cost — routes bleed; "do everything" is inefficient, not forbidden.
- FR59: Routes **interfere** — one route's activity can feed or starve another's.
- FR60: Every route's ultimate output is **leverage over a person's decision**, never wealth for its own sake. Wealth without power is a valid world-state but does not advance the Player's arc.
- FR61: Each route reaches at least one **top-tier outcome the other routes structurally cannot**, and any route can compete directly against any other.

### Emergence, Attribution & Payoff

- FR62: The Simulation produces large emergent outcomes (famine, strike, revolt, war) from accumulated actor decisions without a scripted event system.
- FR63: The Player can **record a prediction** about a cascade before it resolves and compare it against the outcome.
- FR64: The Player can **trace a multi-step outcome back** to their own initiating action; the causal chain is inspectable.
- FR65: Visibility of the social/leverage graph **expands as reach grows**, over a graph whose hidden actors were genuinely acting all along.
- FR66: The Simulation evaluates **named win conditions** spanning the overt↔covert spectrum, with at least one reachable per route.

### Presentation & Feedback

- FR67: The Simulation emits **semantic presentation signals** (tell state, greeting rung, allegiance, event) independent of the rendering skin, so presentation can graduate from portraits/icons/text to 3D without changing the sim.
- FR68: The Player receives **transient reaction feedback** — a tight vocabulary of confirm signals — when an action lands.
- FR69: The Player receives **persistent state feedback** (posture/sigil/greeting) that is partial and inferred, readable before acting.

### Time, Session & Persistence

- FR70: The Simulation advances time in discrete days with a night boundary, so state changes are readable as day-over-day deltas.
- FR71: The Player can save and restore full simulation state, including per-target deviations, accrued channels, installed goals, and promoted individuals.

### Cross-Tier & Scaling

- FR72: The Simulation represents distant regions as aggregate state, night-ticked, communicating with the local world **only through discrete headline events**.
- FR73: The Simulation can **promote** a faction-aggregated actor into a full individual when attention falls on it, and **collapse** it back, conserving shared totals across the boundary.

### Authoring (Data-Driven Content)

- FR74: The Author can define a new playstyle/route entirely as **data** (channel lever, curve set, gated unlock rows) with no new code that names the route.
- FR75: The Author can add a new unlock (action, directable actor, strategy) by adding a **requirement-tagged data row**, without touching gate-evaluation code.
- FR76: The Author can introduce new fluid magnitude modifiers (item, world-state, blessing) into the effect-magnitude stack as content, without changing action definitions.

## Non-Functional Requirements

*Only categories that matter for a solo, single-player, offline PC game are included. Security, multi-tenancy, and compliance NFRs are intentionally omitted as not applicable.*

### Performance

- The per-tick simulation hot path must sustain **≥60fps (frame time ≤16.6ms)** at **150 fully-simulated individuals** — the MVP slice targets 12 — with masses as faction aggregates, using staggered/jittered decision ticks rather than all-actors-per-frame.
- Derived-stat evaluation must be lazy and bounded to what is actually read per tick; per-tick derived-stat computations must scale linearly with reads, never as O(actors²).
- Slow-tick computations (per-channel reach rollup, power centrality, far-region night-tick) must be amortised off the hot path such that **no single frame exceeds 33ms (one dropped frame)** during a slow tick.
- Per-actor scoring cost must scale with that actor's **eligible** action count, not the total size of the action registry — verified by benchmarking scoring-pass duration as the registry grows while an actor's eligible-pool size is held constant.
- The territorial-legibility rollup adds a **third slow-tick computation** alongside the reach rollup and power centrality against the same 150-actor/33ms budget; its frequent-tick "mood" read runs more often than the existing slow-tick rollups and must be benchmarked empirically once implemented, not assumed to fit within existing headroom.

### Legibility (product-defining quality attribute)

- Relationship and disposition state must be readable **diegetically** (body/greeting/sigil) without floating numeric bars.
- State changes the game intends the Player to notice must be expressed as **discrete, categorical** shifts (rung changes), not sub-threshold gradients.
- A first-time Player must correctly read a manufactured one-rung delta **within the first rigged encounter**, taught only by in-world means (rigged cases + information actors), with no non-diegetic tutorial.

### Reliability & Simulation Integrity

- Off-screen/aggregated actors must act coherently: when visibility is later granted, **every revealed action must be reconstructable from a logged decision** with its inputs, so the history withstands scrutiny (no cardboard reveal).
- Cross-tier shared totals (coin, food) must be conserved **exactly** across promote/collapse and instantiate/collapse boundaries — measured as zero net change in global totals across a promote-collapse cycle.
- Save/load must restore full simulation state such that a saved-then-reloaded world produces **identical subsequent tick output** to an uninterrupted run, including per-target deviations, accrued channels, installed goals, and promoted individuals.

### Authoring & Modifiability

- Adding content (routes, actions, unlocks, modifiers, curves) must be possible as **data** without engine code changes and without naming a playstyle in code.
- Tuning levers (curves, thresholds, feel constants) must remain author-editable (GDScript/data) even if a hot numeric loop is later moved to a faster language.

### Scalability (of the fiction, not of users)

- The world must scale in *apparent* population via the two-tier model (drawn masses on faction-level dynamics; individuals promoted on demand), targeting a believable kingdom without fully simulating every body.

## Open Questions

*Updated 2026-07-25 after the author elicitation session. Reviewers: **[author]** = Zach's call; **[party]** = worth a roundtable (Samus/Cloud/Mary/Indie).*

### Resolved in the 2026-07-25 session

- **Leverage vs. direct action.** Leverage is one path, not the destination; direct action is first-class and equal. Direct ships first as a **dependency** (delegation is provider-matching over an action that must exist), not as a difficulty ramp. Recorded in Product Scope → Sequencing Rationale.
- **MVP identity.** The proving scene replaces the earlier direct-influence demo; it adds the fail state the tabled pub-slice seed lacked.
- **Pub-slice seed.** Tabled, re-roled `binding: false`. Parked, not retired.
- **Arbitration.** Survival outbids, never overrides — closes `poc-v2-system-spirit` §7 open tension #9 (multi-driver arbitration), previously flagged as "the single largest unknown."
- **Goal model.** Needs-and-utility is the default; goals are a sparse overlay carrying externally-originated intent; cascade propagates via state change, not goal copying.
- **Influence gate.** Channel-agnostic (loyalty / fear / economic / authority / informational), not loyalty-specific — preserves route parity.
- **Persistence.** Transactional vs. accrual, determined per-driver; fear is a third shape (fast decay, inverts to resentment).
- **Conflict model.** Resolution without execution; social counterplay. Closes the previously-missing conflict FR gap.
- **Early reads must be comparative** — now binding as FR23.
- **Trust and promotion.** Trust is the Player's estimate that an actor delivers (points Player → actor), distinct from a held channel (points actor → Player). Promotion is the lever on power, implemented as an **edge operation** granting an authority channel. Explicit positions/roles are **deferred until roles matter**; the edge operation is the seam.

### Resolved in the 2026-07-27 party-mode roundtable (post-fable-spike)

- **FR1 was wrong, but not for the reason first proposed.** The fable-spike (`fable-spike-decisions.md`) found FR1's "one shared utility-AI loop" didn't describe the shipped code and proposed splitting demands and utility scoring into two named surfaces. A four-agent roundtable (Cloud Dragonborn, Amelia, Samus Shepard, Indie), pressure-tested against the author's own counter-model, converged on a tighter fix: FR1 now names one weighted-scoring pass across three decision points (pursue, answer, act), and **demands are re-derived reads over persistent stats, not persistent memory objects** — resolving the "does a demand need memory" question without inventing a new mechanism. See Core Mechanical Model → "The atom (shipped)."
- **Survival arbitration confirmed as weighting, never a checked-first gate.** The author's simplified "check survival first, else continue" model was flagged as structurally identical to the hard-override that already deadlocked the sim once, and would foreclose the desired "holds his post while starving" scene. Resolved: survival stays a heavy weight in the same scoring pass; flicker at a threshold gets fixed with two-threshold hysteresis (data), not a priority gate.
- **Action-set scaling addressed via eligibility, not goals.** A second roundtable converged on gating the per-tick candidate pool by eligibility (role/faction/possession/position — cheap, structural, data-authored) rather than by goals, because goals are sparse (FR10) and a goal-gated pool would leave the goal-less majority with no pool. A protected universal core (survival + direct interpersonal actions) is never prunable by eligibility, preserving the "everything outbids, nothing overrides" guarantee. New: FR84–FR87, a Performance NFR line, and an architecture note (ship the eligibility-predicate field now, defer the full tagging system until a second action needs it).

### Resolved in the 2026-08-02 party-mode roundtable (hex board)

- **The hex board is Growth/Vision-tier, not MVP** — confirmed against the proving scene's scope before the roundtable convened.
- **Architecture (Cloud Dragonborn).** The board composes with existing patterns more than it needed new ones: hex cells reuse the `location → tags` lookup; the territorial-legibility rollup reuses the reach-rollup shape; the two ownership layers reuse the social graph's inheritance pattern and the accrual channels' sparse-edge pattern respectively. One genuine gap closed: terrain generation is a new one-way instantiation step, not a second use of the actor promote/collapse seam (FR73) as the seed doc first proposed — the two mechanisms share a philosophy, not code.
- **Occupied capacity (the session's highest-risk claim) resolved without a spike.** It is a derived read over the Player's own currently-active installed goals, tracked via a small stored bookkeeping index (built on install, torn down on resolution) rather than a scan of all actors' goals. This is not a "demand with memory" in the sense FR84 rejects — the goals themselves are already legitimate stored state (FR10); the index is an aggregate over them, structurally akin to the sparse-edge indices already used elsewhere.
- **Contesting a rival (Samus Shepard).** FR13 as written only covered a goal competing against its holder's own drives, not against a second installer's competing goal — the seed doc's "no bespoke verb needed" claim wasn't actually specified. Resolved: placement is rank-ordered by loyalty/trust; a placed goal sticks and resolves on its own clock; contesting a standing goal requires a discrete, visible "seize control" interrupt (single-depth for now, deliberately not built to preclude a future stack). This also resolves the seed doc's parked "standing-goal visibility" concern for the contest case specifically — an interrupt is inherently a played, visible action, not silent erosion. The overlay's own visual grammar for ambient (non-contest) visibility remains open (below).
- **Route parity (Samus Shepard).** The board's "resource block = shipped economy primary" framing is inherently production-shaped, risking favoring territorial/production routes unless covert routes get an equally native fit. Resolved: one board, not two, and no new per-route vocabulary — every actor already resolves to a hex via jurisdiction or enterprise, so social/influence state (the covert routes' natural content) renders as a toggle-able overlay on the same grid rather than needing its own resource vocabulary.
- **Positioning (Mary).** Civ 6 and Catan added to Market Context as comparables with an explicit contrast (the board is a zoom level of the embodied world, not a menu-driven screen) — not a fifth Detected Innovation Area; the board is existing claims #2 (diegetic legibility) and #4 (unified promote/collapse LOD) proven at a new scale. Executive Summary target-player framing holds unchanged, conditional on the tycoon guardrail continuing to apply to every board action.
- **Scope reality (Indie).** The seed doc's full scope split: goal-install-at-hex, occupied capacity, instant/permanent + interrupt, and the jurisdictional ownership layer are Growth-tier and load-bearing; the full terrain-generation pipeline, template library, two-speed territorial-legibility rollup, and scattered asset layer are Vision-tier generative richness, not core-loop-proving. The board's Growth entry point is a hand-authored "board proving scene" (no procedural generation), dependency-ordered after installed goals, trust, promotion, and cascade — the board's own placement-ranking and jurisdictional-ownership rules reach back into all four.
- **No spike needed (Step 2 verdict).** Occupied capacity was resolved by design decision rather than remaining ambiguous, and will be exercised for real by the proving scene itself. Terrain generation's on-demand split is deferred to Vision and isn't being built yet — spike it, if ever, when it's actually next up.

### Still open

**Source-document hygiene · [author]**
- `design-session` §0, §10, and Next Steps still carry the framing superseded by its own §1 re-litigation record (§0 still reads *"the core 'combat' is leverage"* and *"without being seen"*). A cleanup pass on that file is outstanding; the PRD does not depend on it.
- `design-session` §9 defers *"nested goals w/ automatic effect-signature linking."* Re-scope: defer the **automatic linking**, keep the **nesting** — nesting is the endgame cascade.

**Prior art · [author]**
- Health-triangle combat work (crystallised 2026-05-18) has **not** been checked against the conflict-resolution model in FR52–54. Confirm whether it applies, supersedes, or is retired.

**Architecture · [party — Cloud]**
- Confirm the architecture list is complete and correctly prioritised (stat-store accessor as the one load-bearing wall). Any missing seam? Confirm the C#/GDExtension deferral threshold. *Sharpened by the new model: the transactional/accrual split maps onto the derived/primary boundary, and delegation reuses provider-matching — confirm both hold under load.*
- Confirm the **150-actor** performance bound now written into NFRs is the right number to design against.

**Innovation claim · [party — Mary]**
- Is "political propagation power gated behind player-composed value-chains" still the strongest single innovation claim, now that the Core Mechanical Model exists? The candidate replacement is **"delegation as provider-matching where the provider chose you"** — one substrate serving needs-economy, influence, and cascade.

**Journeys · [party — Samus]**
- Journey 1 was rewritten 2026-07-27 against the proving scene. Journeys 2–4 remain 2026-07-24 draft — do their *climaxes* each land the intended feeling, or are any still "meter with extra steps"?
- **[author]** Whether commerce/secrets/public-service deserve their own journeys — currently only war and crime are exemplified, despite commerce being named in the logline.

**Yield-state tuning · [author, slice-level]**
- Journey 1's fail branch requires the Player to actually lose. If yielding is toothless the scene has no stakes; if it is punishing on a first encounter it reads as a gotcha. This is the beat most likely to decide whether the MVP works, and it is a tuning question for the slice rather than a requirements question.

**Trust granularity · [author]**
- Is trust **one scalar** per actor, or **per action-tag / domain**? A man reliable with violence may be useless at negotiation. Per-domain is richer and matches the existing action-tag structure; one scalar is cheaper but risks reading as a generic "good employee" rating. Not blocking — the FRs hold either way.

**Win conditions · [author]**
- FR66 requires *named* win conditions with at least one reachable per route. None are named yet. This is the remaining gap in the parity claim (FR61). Promotion sharpens one candidate: *sustained control of a figurehead you placed* is now mechanically expressible.

**Cross-cutting · [author]**
- **Off-screen coherence** remains asserted and unproven; must be validated in the smallest form before any reveal/progression UI is built on it.
- Logline, definition of power, and the illegible-authorship spine — confirm they still hold now that power is computable as cascade-subtree size.

**Hex board — carried from the seed doc, not resolved this session**
- **Zoom-transition feel · [author]** — what moving between the board and the ground level is actually like, mechanically and experientially. Not discussed this session; Cloud's pass confirmed the two share one coordinate space, but not what the transition itself feels like to play.
- **Micro-hex-per-strategic-hex scale · [author]** — order-of-magnitude question, how many micro-hexes typically compose one strategic-zoom cell. Not pinned down.
- **Presence-scarcity at high influence · [author]** — does travel to specific places remain necessary once influence is high, or does the requirement change shape? Not addressed this session.
- **Differential pricing for standing vs. one-shot goals · [author, tuning]** — the likely single lever against a lategame "autopilot" trap; explicitly deferred to a calibration pass.
- **Overlay visual grammar · [party — Samus]** — which tells map to which visual signal on the social/territorial overlay is undesigned, deliberately deferred until goal-install/interrupt is playable. The *contest* case is now visible by construction (seize control is a played action); ambient/non-contest visibility is still open.
- **Dormant-but-occupied capacity · [author]** — if a held actor's own drives are currently outbidding a standing board goal, does the goal's capacity stay locked the whole time it's not being honored?
- **Revocation cost · [author]** — whether pulling a standing board goal off someone costs something, symmetric with installing one.
- **Exact stack timing/duration mechanics · [author, tuning]** — deferred to tuning.
- **Asset-in-foreign-jurisdiction mechanism · [author]** — currently flavor-only (no mechanical exposure); parked as the likely eventual home for FR58/FR59 texture if it ever earns a mechanism.
- **Person-to-person influence with no spatial anchor · [author]** — every actor discussed so far resolves to a hex via jurisdiction or enterprise; whether a genuinely non-spatial influence action ever arises, and how it would render on a hex-built board, is unflagged until it happens.

### Deferred: Polish (Step 11)
- Full document polish (dedup, flow, terminology, header hygiene) is still deferred and now has concrete targets: the **tycoon guardrail** is stated four times and **path parity** four times; **Product Scope** and **Project Scoping & Phased Development** both define MVP/Growth/Vision and should be merged. Run polish after the remaining open questions land.
