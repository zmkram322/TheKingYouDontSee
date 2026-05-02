---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
inputDocuments:
  - "_bmad-output/game-brief.md"
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 0
  projectDocs: 0
workflowType: 'gdd'
lastStep: 9
project_name: 'TheKingYouDontSee'
user_name: 'Zach'
date: '2026-04-26'
game_type: 'simulation'
game_name: 'The King You Don''t See'
---

# The King You Don't See - Game Design Document

**Author:** Zach
**Game Type:** Simulation (Hybrid: RPG · Sandbox)
**Target Platform(s):** {{platforms}}

---

## Executive Summary

### Game Name

The King You Don't See

### Core Concept

A medieval fantasy society simulation where every actor — from hungry farmer to scheming lord to desperate king — runs on the same needs-based decision system, producing emergent political, economic, and social behavior that unfolds whether the player is watching or not. The world is not a stage waiting for a protagonist. It is a living system in motion before the player arrives and indifferent to whether they ever act at all. A player who never leaves the starting village would still witness famines cascade from bad harvests, merchant cartels form around scarcity, lords lose legitimacy when they can no longer deliver safety, and power vacuums fill themselves through the logic of collective need. The simulation has its own story. The player is simply the most interesting thing that can happen to it.

The same simulation that runs without the player can also run over them. The world's indifference cuts both ways — famine, political realignment, or a lord who decides the player has become a liability are as real as any opportunity. The floor is as genuine as the ceiling.

When the player does engage, they rise from hungry nobody to invisible kingmaker not by grinding a fixed power curve, but by reading what the world needs and positioning themselves to supply it. Combat is a viable path — but only where the simulation has made room for it: a destabilized region, a power vacuum, a population desperate for protection over politics. The world opens the door; the player decides whether to walk through it. As influence grows — measured through activity-driven stats that expand the player's organizational span of control — so does their capacity to shape the world: seeding events, redirecting power, engineering crises or stability at regional scale. Even so, the simulation always remains larger than any one actor. A king governs within the same system that governed them as a peasant — just from the highest seat in it. The highest expression of play is causing everything while appearing to do nothing: the invisible hand that is not passive, but selective.

### Game Type

**Primary Type:** Simulation
**Hybrid DNA:** RPG (embodied character subject to the same needs hierarchy as every other actor) · Sandbox (open-ended, player-directed goals, no authored main arc)

**Classification Rationale:** The simulation is the content, not the container. A pure RPG requires the player to be the engine of the narrative. A pure sandbox requires the player to impose meaning on an empty space. This game requires neither — the world generates its own narrative, its own urgency, and its own consequences. The player is one actor among many, governed by the same rules, with the unique ability to read the system and act on what they understand. RPG embodiment is the lens. Sandbox agency is the mode. Simulation is the foundation everything else rests on.

**GDD Framework:** Uses the Simulation template with type-specific sections for core simulation systems, economic and resource loops, and emergent behavior design — extended with RPG-specific sections for character embodiment, influence progression, and needs-hierarchy mechanics.

**Flagged for later steps:**
- Influence system: activity-driven stat growth → organizational span of control (pull-based directive model, relationship affinity mechanics with high-influence peers)
- Initiative system: how player-set goals propagate through autonomous actors
- Economy modeling: markets, resource flows, supply chains, wartime vs. peacetime dynamics
- World configuration: number of kingdoms (default 2; single-kingdom mode removes external war dynamic — accessibility dial for newer players)

### Target Audience

Ages 18–35, concentration in 22–34. Systems readers. Long-form PC sessions. The player who loses and immediately wants to trace the causal chain backward — not to undo the loss, but to find the moment they should have known.

### Unique Selling Points (USPs)

See full USP section below.

---

## Unique Selling Points

### 1. The Simulation Is the Content, Not the Container

Most games use simulation as backdrop for authored content. Here, simulation *is* the content. The famine that emerges from your grain manipulation three sessions ago IS the story. Architectural, not cosmetic — cannot be patched into an existing game. Players feel this as: "the world feels alive" and "things I did last week still matter."

### 2. Influence Changes What Kind of Actor You Are

Most RPGs make you stronger. This makes you categorically different. Low influence means direct verbs only. High influence means directing others, setting traps, causing outcomes while appearing to do nothing. The progression is a fundamental change in your relationship to the world — felt through threshold experiences at each categorical transition, not just stat increases.

### 3. Needs Hierarchy Governs Everyone Equally

Every actor from farmer to king runs the same needs-based decision system — including the player. Consequence feels fair rather than arbitrary because the world isn't punishing you; it's applying the same rules to everyone. This is what makes the "I should have seen that coming" failure response possible: the system is honest.

### 4. The Surface Earns Patience for the Depth

Expressive, readable combat gives players a kinetic reason to stay in the world long enough to discover what the simulation is doing underneath. Neither layer is decoration. Combat isn't a break from the real game — it's a different register of the same game.

### Competitive Positioning

| Game | Simulation | Surface | Embodiment |
|---|---|---|---|
| Kenshi / Dwarf Fortress | ✓ | ✗ | Partial |
| Skyrim / KCD | ✗ | ✓ | ✓ |
| CK3 | ✓ | Partial | ✗ |
| RimWorld | ✓ | ✗ | ✗ |
| Mount & Blade: Bannerlord | Partial | Partial | ✓ |
| **The King You Don't See** | **✓** | **✓** | **✓** |

**One sentence:** This is the only game where the thing you're proud of is what you understood — not what you survived.

---

## Target Platform(s)

### Primary Platform

**PC (Steam)** — launch target. Natural home for the target audience; keyboard and mouse give full access to simulation depth without interface compromise.

### Platform Considerations

- **Performance:** 60fps non-negotiable on the active layer (combat, movement). Simulation tick rate runs independently — heartbeat-driven at regional fidelity, statistical at distant fidelity. The hot path cannot dip below 60 regardless of simulation complexity.
- **Engine:** Godot 3D
- **Console:** Post-launch only. Controller-first design requires interface rethinking for the simulation layer — making dense systemic information readable without keyboard/mouse precision. Revisit after PC release validates the core loop.

### Control Scheme

Keyboard and mouse primary. Controller support deferred to post-launch.

---

## Target Audience

### Primary Demographic

Ages 18–35, concentration in 22–34. North America and Western Europe — Western Europe (Germany, France, UK, Nordics) likely represents the densest per-capita concentration of this archetype; the CK3 and Morrowind playerbase skews heavily European.

**Content:** Family-appropriate by intent (no excessive violence, sexual content, or profanity) but designed for adult cognitive engagement.

### Player Identity: Systems Readers

Players who derive satisfaction from legibility — from understanding *why* the world does what it does, not just what it does. The reward is the inference: the signal caught before it mattered, the causal chain traced backward from the consequence. Success feels earned through insight. Failure feels educational.

### Player Profile

The player who bounced off Kenshi's inaccessibility, found RimWorld too abstract, loved Morrowind's openness but wanted systemic depth, and plays CK3 wishing they could embody a character. Comfortable with indirect systems and self-directed goals. Prefers long sessions driven by genuine engagement over obligation.

### The Emotional Job

**"Hire me to feel like the only one who saw it coming."**

The player is not hired to feel powerful — they are hired to feel *perceptive*. The perception fantasy says: give me information other actors don't have and let me exploit the gap. Every system must have a legible theory the player can discover and then act on.

### Failure Response Type: "I Should Have Seen That Coming"

This game's player is not the CK3 player who celebrates disaster from emotional distance. Not the RimWorld player who screenshots a colony's death as communal story. Not the Morrowind player who reframes loss as an exploration redirect.

The player is the one who loses and immediately wants to rewind — not to undo the loss, but to find the moment they should have known.

| Failure Type | Response | Character |
|---|---|---|
| CK3 | "Great story, what's next" | Detachment, narrative distance |
| RimWorld | "Look what happened to us" | Communal loss, screenshot moment |
| Morrowind | "I'll try a different direction" | Exploration reframe, low stakes |
| **This game** | **"I should have seen that coming"** | **Retrospective inference — personal, motivated, educational** |

**Design implication:** Every failure state must have had traceable precursor signals. Failures without precursors produce frustration, not retrospective inference.

**Failure legibility test:** After any significant loss, can the player trace at least three signals they could have caught before it landed? If yes → correct failure type (player feels smart even losing, motivated to retry). If no → design failure (player feels cheated, churn risk high).

**Difficulty tuning target:** Signal-to-noise ratio, not consequence severity. A new player misses most signals and experiences failures as surprising. An experienced player catches most signals and experiences failures as earned. The correct difficulty curve for this failure type is not getting easier over time — it is getting *more legible* over time.

### Session Length

Long-form PC sessions (1+ hours). The 11pm boot-up because something is unresolved — a play that hasn't landed, a signal not yet traced. The game pulls players back because they're still thinking about it.

### Continuous Agency Commitment

Players are never blocked from attempting to act. The world always has something going on — town squares host foreigners with news from other regions, markets shift, NPC agendas surface. A player without the stats for high-influence relationships won't succeed there, but the simulation always provides legible events to read and act on. Failure-by-waiting is a design failure, not a player failure.

### Discovery Pathway

This audience discovers through video — YouTube deep-dives, streamer playthroughs, word-of-mouth. The emergent story pull is also what makes the game streamable: the moment a player reads the market and watches a lord fall is a story that tells itself on camera. Information legibility is a discovery mechanism as much as a design one.

### Player Motivations (as felt experiences)

- *"I see what's about to happen before anyone else does."* — the perception reward
- *"I caused this — three sessions ago, and I just watched it land."* — the consequence reward
- *"The world did something I didn't expect, and now I need to figure out why."* — the legibility pull

### Secondary Audiences

- **Lateral-thinking agency players** (Thief, Prey, Disco Elysium) — read environments and act on what they find; comfortable with systems that reward attention over reflexes
- **Emergent sandbox narrative players** (Dwarf Fortress, RimWorld, Caves of Qud) — fluent in simulation-as-story design, hungry for an accessible surface and embodied perspective

---

## Goals and Context

### Project Goals

1. **The Ceiling-Stare Moment** *(Player Impact)* — A blind playtester puts the game down mid-session and is still thinking about it. They describe their experience using inference language ("I figured out that...") not action language ("I killed X" or "I completed Y"). The three designed peaks occur naturally without guidance: the inference peak, the consequence peak, and the ceiling-stare.

2. **Prove the Loop** *(Technical)* — Demonstrate that the planned simulation architecture supports a complete economic loop end-to-end before any layered systems (needs, aptitudes, hierarchy AI) go on top of it. Five actors, one good, four windows, three markets, two simulated weeks. Workers find employment via market clearing, produce goods, get paid, owners distribute supply to merchants who distribute to consumers — all driven by tick-and-window signal flow. This is the first real milestone; emergence is what we layer on top once the loop runs cleanly. See `prototype-build-spec.md` for the locked architecture.

3. **Ship the Vertical Slice** *(Craft)* — One region, the LISTEN → INFER → COMPOSE → DISRUPT loop playable end-to-end, no production art or audio. At least one influence tier transition felt by the player. At least one consequence that lands from an action taken earlier in the same session.

4. **Build the Evangelical Audience** *(Business — secondary)* — Wishlists and community are meaningful signals after the vertical slice is shareable, not before. The target is the specific, vocal segment that has been waiting for a game that treats consequence as a system — when the systems deliver, they become the marketers.

### Background and Rationale

Most games that promise freedom deliver a corridor with wider walls. Most games that promise consequences deliver a cutscene.

The market currently offers two unsatisfying options: authored-consequence games (wide freedom, ultimately cosmetic outcomes) or pure simulation games (real consequence, inaccessible surface). Nobody has successfully bridged accessible kinetic surface experience with genuinely real consequence simulation in a medieval fantasy setting. That is the gap. The King You Don't See is the bridge.

Three forces make now the right moment: AI tooling for dynamic systems and asset generation is maturing rapidly; studios prioritizing player-driven narratives are capturing measurably higher engagement; and player frustration with corridor-with-wider-walls design is loud, growing, and actively looking for something that delivers.

The pet project structure is a creative advantage — no publisher constraints on the vision, no runway pressure forcing premature scope decisions. The correct build order (simulation prototype → vertical slice → production) can be honored without compromise.

---

## Core Gameplay

### Game Pillars

**1. The World Doesn't Wait**
The simulation runs independently of the player. Markets shift, lords scheme, farmers hunger, power vacuums fill. Every system exists as part of a living world that was in motion before the player arrived and continues without them. *If a feature requires the player's presence to function, it doesn't belong.*

**2. Consequence Is Structural, Not Scripted**
Every action writes to the simulation. Killing a delivery agent cascades into famine. Cornering a market destabilizes a region. There are no authored consequence cutscenes — only systems responding to disturbance. *If a consequence has to be written by hand, the system isn't deep enough yet.*

**3. Power Is Earned Through Understanding**
The player gets stronger by reading the world more accurately — not by grinding levels. Influence, information, and timing beat raw force. *If a feature can be brute-forced without understanding, it undermines this pillar.*

**4. Surface and Depth Are Both Real**
Kinetic, expressive combat and movement give players a joyful surface to inhabit while the simulation runs underneath. Neither layer is decoration. *If a feature serves only one layer without connecting to the other, reconsider it.*

**Pillar Priority:** When pillars conflict, prioritize:
1. Consequence Is Structural (the contract the entire vision rests on — break this and everything collapses)
2. Power Is Earned Through Understanding
3. Pillars 1 and 2 are the same idea at different scales and should never conflict

---

### Core Gameplay Loop

**LISTEN → INFER → COMPOSE → DISRUPT**

The same four verbs at every scale. A fight, a market play, a long political trap — same loop, different timescale. The loop never changes; what changes is the surface area it operates on.

```
LISTEN      Observe world state — market prices, NPC behavior, rumors,
            environmental signals, the things that are wrong before
            anyone says they are

INFER       Reconstruct causality — what does this signal mean, who
            benefits, what's about to happen, where is the gap

COMPOSE     Position and plan — set conditions, cultivate relationships,
            time interventions, direct subordinates, arrange so another
            actor's own logic walks them into your position

DISRUPT     Act — transact, strike, arrive, expose, withhold. Physical
            presence is never neutral. The player's body is a variable
            the simulation reads.
```

**Loop Timescales:**
- Seconds: a fight, a conversation, a single transaction
- Minutes: reading a market situation, executing a disruption play
- Sessions: composing a multi-actor scheme, building a relationship, watching a consequence land

**The Factorio Principle — Compounding Complexity, Not Changing Games:**
The loop never changes. What changes is the logistical surface area it operates on. At low influence, LISTEN means watching one market stall. At high influence, LISTEN means reading signals across three regions simultaneously — and knowing you can't watch all of them. Each tier stacks on the previous rather than replacing it:

- Tier 1: Wealth acquisition loops (trade, labor, basic transactions)
- Tier 2: Enterprise ownership (purchasing or growing operations, supply chain exposure)
- Tier 3: Safety and risk management (protecting assets, managing instability costs)
- Tier 4: Relationship management (cultivating high-influence peers, coalition politics)
- Tier 5: Directed influence (setting initiatives, directing actors, causing outcomes at regional scale while managing the attention cost of your own reach)

Each tier adds logistical complexity without removing the previous tier's demands. A king still needs to eat.

**The Attention Constraint:**
The player cannot be everywhere at once. This is the real upper bound on power — not a stat cap, but a presence limit that the simulation imposes naturally. Conflict and disruption create costs that attract attention from other influential NPCs. Acting in one place means not acting in another. At high influence, things are simultaneously outside your control and caused by your actions. The coalition forming against you exists because you were too successful. The famine in the eastern region exists because you were focused west. This is not a failure of the system — it is the system working correctly.

**Three Satisfaction Peaks:**
- *Flow peak* — combat clicking into a chain (immediate)
- *Inference peak* — the world suddenly becoming legible (medium-term)
- *Consequence peak* — watching something composed three sessions ago land (rare, delayed, the one players describe to their friends)

---

### Stakes and Consequence

*(This game has no traditional win/loss screen. Success and failure are states within the simulation, not endpoints.)*

**No Permadeath — Persistent Consequences:**
The player does not die. Fights end in injury — wounds that heal over time and impose real costs while they do. This gives fight-or-flight genuine mechanical weight: choosing to fight means accepting a recovery window during which the simulation continues without you at full capacity. Recognizing an unwinnable fight and escaping cleanly is using the system correctly.

Combat outcomes write to NPC state as well. Defeated actors carry depressed stats — less likely to re-engage — or leave the area entirely. Victory over an actor is a simulation event with downstream consequences, not a reset.

**Setback States (Not Loss States):**
There are no hard loss states. The simulation always leaves a door open. However, significant failures can result in being marked or branded — reputation consequences that reshape how the world responds to the player. A branded player isn't playing a worse game; they're playing a different game in the same world. New paths open as others close. The simulation reconfigures around who you've become.

**Success States:**
Player-defined. The simulation validates player goals through emergent outcomes rather than authored rewards. Success feels like: watching a consequence land exactly as composed, seeing the world respond to your understanding of it, reaching a new influence tier and feeling the categorical shift in what you can cause.

**Endgame — Sandbox All the Way Up:**
Becoming king is a milestone, not an endpoint. Even at the highest influence tier, the sandbox continues — with king-level problems. Power can be lost. Legitimacy erodes. The simulation that put you on the throne is the same simulation that will generate the conditions to remove you from it if you stop reading it. The specific mechanics of king-level play will be explored after core systems are established.

**The Compounding Failure Mode:**
At high influence, the failure mode is the accumulation of costs from acting everywhere simultaneously. You cannot be everywhere at once. The things you set in motion and then couldn't watch are the source of the most meaningful late-game failures.

**Failure Recovery:**
Re-enter the simulation. Trace the chain. The information channels — gossip, NPC dialogue, environmental tells — are breadcrumb trails for what went wrong. An experienced player reads the failure and immediately begins composing the next move.

---

## Game Mechanics

### Primary Mechanics

**1. Observe / Read** *(most repeated action — LISTEN phase)*
Information surfaces as you move through the world. Approaching a group presents context-driven interaction options; initial implementation: Greet · Question. Additional social verbs (Talk Shop · Talk Shit · Interrogate · Special Greeting / intel exchange) added after playtesting validates which gaps players actually hit. Bulletin boards and town criers confirm what active traversal has already surfaced — they do not replace it. The player who walks the world knows more than the player who reads the board.

The system tracks what the player has learned, when, and from whom (a queryable log — queries designed before schema). *Model first, UI second: the observation interface is shaped by what information is actually tracked.*

**Open design question:** What is the minimum viable signal that tells a player their inference was correct — structurally, through world response, not through dialogue confirmation? The gap between inference and world validation is where the perception fantasy lives or dies.

Serves: Power Is Earned Through Understanding

**2. Transact / Control** *(the influence layer — COMPOSE phase)*
Trade, broker, manipulate, spend influence, withhold, expose. **Withhold is a first-class mechanic** — letting a crisis deepen on purpose is a power move, not an absence of action. At low influence: direct peer-to-peer transactions. At high influence: menu-driven evaluation of world/region state, directing resources through initiatives and direct actions.

Dialogue trees are too slow. The specific UI will be determined by what the simulation actually tracks — skill checks, action types, initiative structures. *Model first, UI second.*

Serves: Consequence Is Structural, Not Scripted

**3. Act Directly** *(the active layer — DISRUPT phase)*
Move, strike, arrive, disrupt, chain. **"Arrive" is the most consequential verb** — physical presence is never neutral, and the player's body is a variable the simulation reads.

*Combat — three postures within one fight-or-flight core:*

All three share: adrenaline spikes, movement behaviors unlock (speed, gap-closing, escape options), injury-as-cost (wounds heal over time, impose real costs during recovery, and write to social simulation state — a visibly injured player has fewer dialogue options and registers differently to NPCs). Clean escape reads as clearly as a clean win. Defeated NPCs carry depressed stats or leave the area.

- **Melee** *(Close the gap)*: Direct engagement. Expressive chains, high risk/reward. Priority archetype for prototype — highest feel complexity, must land before others are built.
- **Ranged / Charisma archetype** *(Manage the gap)*: Distance management and positioning. Combat as threat neutralization from safety. Suits actors who project force without direct confrontation. Second archetype after melee is validated.
- **Elemental / Magic** *(Reshape terrain around the gap)*: High power, high cost, high commitment. Spells produce **outcome states** — destroyed, incapacitated, disrupted, revealed — that the simulation already knows how to process. The surface shows fire, ice, lightning; the simulation reads the outcome and responds through existing systems. No physics-based propagation required. Deferred until simulation state architecture is established.

Serves: Surface and Depth Are Both Real, Consequence Is Structural

**4. Position / Plan** *(the delegation layer — COMPOSE at scale)*
Compose, time, cultivate, assign downward, negotiate laterally, position upward. As influence grows, players stop doing and start directing — reach multiplies beyond physical presence. Mechanically mirrors Transact / Control at higher tiers: menu-driven world/region state evaluation, initiative-setting, resource direction. *Model first: the interaction model will be designed once the simulation model — actions, initiatives, state — is established.*

Serves: All four pillars

---

### Mechanic Interactions

- Observe informs Compose: information gathered feeds directly into planning
- Act Directly generates new observation targets: presence changes world state and surfaces new signals
- Injury writes to social simulation: combat costs are legible to NPCs, not just to the health bar
- Withhold (Transact) is a Compose move executed through inaction: absence of your resource is as readable as its presence
- Combat outcome writes to NPC state: defeating an actor changes who they are in the influence network
- Elemental outcomes write to simulation state via outcome mapping: spells produce states (destroyed, disrupted) the simulation already processes

### Mechanic Progression

*The Factorio principle:* The same verbs at every scale, dramatically expanding logistical surface area. Low influence: one-to-one. High influence: layered, delegated, attention-constrained.

Archetypes are not selected — they emerge from how the player spends time. The player needs to *feel* themselves becoming something (NPCs comment differently, new options appear) before they see it in stats. Emergence is discovery, not drift.

---

### Development Build Order
*(The simulation eats you if you don't respect the order)*

**The simulation is the foundation. Everything else is downstream of it.**

If NPCs don't run convincingly without the player, the entire UVP collapses before a single player touches it. Do not build combat, UI, or observation systems on top of a simulation that hasn't proven it can breathe on its own. The milestone is: load the game, walk away for five minutes, come back, and the world has moved. When that works — proceed.

**1. Simulation core — the loop before the layers**
Tick architecture, window architecture, market clearing, account-and-contract bookkeeping. This is not a feature — it is the ground the game stands on. Nothing else is built until the prototype loop runs cleanly: 5 actors, 1 good, 4 windows, 3 markets, both simulated weeks pass with workers employed, producing, paid, and consuming. See `prototype-build-spec.md` for the v0 acceptance criteria. Needs hierarchy, aptitudes, hierarchy AI, and emergent cascade behaviors layer on top once the loop is proven.

**2. Observation layer**
Two social verbs (Greet + Question) on top of a working simulation. Validate which gaps players actually hit before expanding. Bulletin boards and town criers are cheap to implement and high-value for teaching world-reading — do these early. Add additional social verbs only after playtesting shows where players are reaching for something that isn't there.

**3. One combat archetype — melee only**
Melee is the hardest to get right. If it's wrong, everything built on top of it is wrong. Expressive chains, injury persistence, NPC state write-back — end-to-end, fully validated. Do not start ranged or magic until melee is solid.

**4. Management UI**
A mirror of simulation state. Cannot be meaningful until the simulation is rich enough to manage. Build it fourth, not second.

**5. Ranged / charisma archetype**
Added once melee is proven. The fight-or-flight core already handles it — this is posture expression, not a new system.

**6. Magic / elemental (outcome-state model)**
Deferred until the simulation state architecture is established and designed to accept outcome writes. Magic is: expressive surface effect + outcome state (destroyed, incapacitated, disrupted) that existing simulation systems already process. The architecture cost is low *if* the sim is built right. It becomes a retrofit nightmare if it isn't.

**The rule:** If you hit month eighteen and you're still on step two — that's information, not failure. Cut scope. What you have at that point is probably a political sim with light RPG elements, and that is still a game worth shipping. Ship something. Iterate.

---

### Architectural Prerequisites

**Prototype scope (Epic 1) requires only:**
- Tick + window calendar (`SimClock` + `WindowBus` signal contracts) — see `prototype-build-spec.md`
- Class catalog: Actor, Interest, Market, Region, ProductionResource, Accounts, Contract
- Bootstrap configuration (5 actors, 1 region, 1 plot, initial coin/inventory)
- Window orchestration: which bus signals fire on which ticks (the `WindowOrchestrator` autoload)

Everything below is forward-looking and arrives in later epics, not Epic 1:

- NPC state schema for needs hierarchy and aptitudes (post-prototype)
- Simulation event vocabulary for cascade and tail-event triggers (Epic 2+)
- Fidelity tier rules — when NPCs drop to low-fidelity simulation and what that means (Epic 2+)
- Outcome state taxonomy — what states spells and combat can produce (Epic 4+)
- Knowledge tracking schema — log design: queries first, schema follows (Epic 3+)
- Influence/control state model — what "high influence" means in data (Epic 6+)

---

## Controls and Input

### Control Scheme — PC (Keyboard + Mouse)

| Action Category | Input Approach |
|---|---|
| Movement | WASD + mouse look (standard 3D) |
| Context interaction | E / proximity-triggered option surfaces |
| Combat — melee | Mouse buttons, dodge on Shift, block/parry on right mouse |
| Combat — ranged/magic | Hotbar / quickslot for equipped ranged or spell |
| Observation options | Context menu surfaces on approach |
| Management UI | Tab or dedicated key — opens world/region state view |
| Initiative/delegation | Menu-driven within management UI |

*Full key rebinding. Common actions on easy-to-reach inputs.*

### Input Feel

- **Active layer:** Responsive, snappy, no input lag. 60fps non-negotiable.
- **Simulation layer:** Deliberate, menu-driven, pause-optional. Never rushed.
- **Observation/context:** Frictionless — information surfaces as you move, no dedicated mode required.

### Accessibility Controls

Full key rebinding. UI scaling for management views. Colorblind-safe simulation state indicators. Additional options specified as UI/UX matures.

---

## Simulation Specific Design

### Core Simulation Systems

The simulation is built in layers. The bottom layer — the prototype scope — is the **economic loop spine**: ticks drive windows, windows drive markets, markets clear and write to actor accounts. The mid and upper layers (needs, aptitudes, hierarchy AI, emergent cascades) are built on top once the spine is proven.

**Prototype layer — the spine (Epic 1):**

The spine has four moving parts:

1. **`SimClock`** — drives `daily_tick(slot)` (8 slots per simulated day) and `weekly_tick()` (fires during `EARLY_MORNING` of day 7). The only thing that touches simulated time.
2. **`WindowBus`** — pub/sub for named windows: Labor Market, Work, Wholesale Market, Retail Market. Each window has open and close signals. Anyone can fire either; subscribers don't know who fired. Synchronous emission means "all subscribers reported" comes for free between open and close.
3. **Markets** — region-scoped (`LaborMarket`, `WholesaleMarket`, `RetailMarket`). Hold supply and demand pools that accumulate between clearings. Clear when their window closes.
4. **Actors** (`LandOwner`, `Worker`, `Merchant`) carrying **Interests** (`ProductionInterest`, `WorkingInterest`, `MercantileInterest`, `GrainInterest`). Interests subscribe to bus signals and drive economic behavior. The Actor is the sum of its interests.

This is the architecture the v0 prototype validates. See `prototype-build-spec.md` for the locked class catalog, signal contracts, and acceptance criteria.

**Mid layer — needs and behavior (Epic 2+, post-prototype):**

Three-tier needs hierarchy applied to all actor types — farmer to lord — running on the spine above:

| Tier | Need | Expression varies by actor |
|---|---|---|
| 1 | Basic needs — food, sleep, safety | Farmer needs grain; lord's "safety" is legitimacy |
| 2 | Wealth accumulation — coin, property, assets | Pursued once Tier 1 is satisfied |
| 3 | Power and influence — control, authority, access | Lord: legitimacy. Merchant: market monopoly. Bandit leader: territorial control |

Tier 1 deprivation produces stat debuffs, behavioral cascades, and crisis events (hunger strike, desertion). Tier 2 and 3 shape actor decision-making once survival is stable.

**Upper layer — emergence targets (Epic 2+, after needs land):**

Once the spine is running and needs are layered on, the simulation must demonstrate these behaviors *without authored content*:

1. **Famine cascade** — bad harvest → supply drop → price rise → workers priced out → hunger debuff → productivity loss → smaller next harvest → spiral
2. **Labor drain** — wage differential causes worker contract migration, collapsing supply at origin farms
3. **Merchant margin capture** — merchant protecting profit margin during scarcity converts supply shortage into artificial price spike independent of actual production collapse
4. **Hunger strike contagion** — one farm's strike reduces regional supply, raising prices at neighboring farms and triggering further strikes
5. **Black market emergence** — when official market prices exceed affordable thresholds, shadow transactions emerge through the night cycle

These are *not* prototype acceptance criteria — they are the behavioral targets for the epic that follows the prototype. Trying to prove them on a spine that doesn't run cleanly is the failure mode the prototype exists to prevent.

**System interconnections:**

Supply → market → coin → wages → consumption → needs satisfaction → productivity → supply. Every system is downstream of the spine and feeds back into it through markets.

**Dual-clock architecture** *(design feature requiring explicit architectural resolution before prototyping):*

- **Active game time** — compressed real-time clock with day/night cycle. Players experience the world at this speed.
- **Simulation time** — runs dramatically faster for hidden NPC decision-making. A full in-game week of economic simulation resolves between player actions.
- **Day/night cycle is mechanically significant** — black markets, dark connections (bandit commissioning, shadow alliances), and covert high-influence actions occur at night. Actors operating across both cycles accumulate rest deficits with real productivity trade-offs.
- **Open specification** — how the two clocks remain coherent and what the player experiences vs. what the simulation resolves requires explicit definition before implementation.

**Prototype acceptance — the loop runs (precedes everything else):**

Five actors (1 LandOwner, 2 Workers, 1 Merchant, 1 Region as container), one good (grain), one exchange medium (coin), four windows (LMW, WW, WMW, RMW), three markets. After two simulated weeks: workers gain employment, work contracts in place, workers produce and get paid, owners sell to merchants in wholesale, workers buy from merchants in retail. All five criteria observable in console / log output. This is the v0 acceptance gate — see `prototype-build-spec.md`.

The "world moves while you watch it" milestone is at Epic 2 (full sim with needs and hierarchy AI), not Epic 1.

---

### Management Mechanics

Not present in the prototype. At low influence tiers, the player acts directly as one actor among many. Management emerges at higher influence tiers through the initiative and delegation system — when span of control expands, the player sets goals that propagate through autonomous actors rather than acting directly.

*Cross-reference: Influence tier progression is detailed in the Progression and Balance section.*

**Automation vs. manual control:**
The simulation always runs autonomously — actors execute their own decision functions without player direction. "Manual control" means direct action (DISRUPT phase). The tension between direct action and delegated action is the core mechanical expression of influence tier progression.

---

### Ownership and Acquisition

*This game does not feature traditional building or construction placement mechanics. Structures exist as simulation entities with ownership state. The relevant mechanic is acquisition — how structures change hands — not construction.*

**Builders as a working class:**

Builders are a labor category governed by the same worker model as farmers — assigned via wage contract, accumulate skill experience, require food and sleep, subject to morale and productivity modifiers. They are assigned to construction and maintenance projects commissioned by landowners or lords. A lord who stops paying builders lets infrastructure decay. A merchant who commissions a new market stall generates a construction contract that employs builders and produces a new owned simulation entity.

**Ownership as influence milestones:**

The economic spine of influence tier progression runs through ownership. These are not quest markers — they are states the simulation reaches when the player has accumulated sufficient coin and social standing to transact at that level.

| Milestone | What changes |
|---|---|
| First wage contract | Market participant — can transact |
| First land purchase | Landowner — directs labor, collects revenue, has something to lose |
| First market stall | Supply controller — influences local price by controlling distribution |
| First enterprise | Multi-asset operator — the simulation treats the player as an organization, not an individual |

**Ownership mechanics:**

- Land and structures carry a market value influenced by regional productivity, crime score, and demand
- Transfer requires: sufficient coin + seller willingness (relationship/reputation factor) + lord's legal sanction within their domain
- Contested ownership (seizure, inheritance, political transfer) is resolved through the influence system, not the market

---

### Economic and Resource Loops

**Prototype model — the spine (v0):**

The prototype runs a single good (grain) through a tick-driven, window-mediated, market-cleared loop. No needs, no scarcity, no margin behavior, no travel decisions — just the bookkeeping spine that the rest of the economy will eventually run on. Acceptance is "the loop runs cleanly," not "emergent dynamics appear." See `prototype-build-spec.md` for the locked architecture, class catalog, and signal contracts.

```
DAILY (8 slots)
  MID_MORNING       Work Window opens
                      Workers with active contracts → WORKING
  MID..LATE_AFTERNOON Workers accrue grain to own inventory each slot
  EARLY_EVENING     Work Window closes
                      Workers transfer grain to LandOwner inventory
                      Workers emit Payable to LandOwner.payables (wages owed)
                      LandOwner's ProductionInterest emits supply to WholesaleMarket
                      (supply pool accumulates daily; clears weekly)
  LATE_EVENING      Labor Market Window opens, then closes
                      ProductionInterest posts open positions
                      Unemployed Workers post availability
                      LaborMarket clears → LaborContracts written
                    Each Actor's GrainInterest emits demand to RetailMarket
                      (demand pool accumulates daily; clears weekly)

WEEKLY (during EARLY_MORNING of day 7)
  merchant_restock signal
    Merchant emits demand to WholesaleMarket
  Wholesale Market Window opens, then closes
    WholesaleMarket clears at flat price → grain to Merchant, coin to LandOwner
  Merchant emits supply to RetailMarket
  Retail Market Window opens, then closes
    RetailMarket clears at flat price → grain to consumers, coin to Merchant
    Each transfer decrements consumer's outstanding_demand
  wages_due signal
    LandOwner walks payables, decrements own coin, increments worker coin
```

**What the spine deliberately doesn't do (yet):**

- No production formula beyond `slots_worked × base_output_per_work_unit`. The full `Output = A · g(t) · ∏(p(s))` formula and worker-cap saturation arrive when production becomes the bottleneck under needs pressure.
- No demand function beyond a flat constant. The `Q_demanded = min(preferred_quantity, budget / price)` form, subsistence floors, and budget-tier prioritization arrive with the needs hierarchy.
- No merchant pricing logic. Flat clear at 1 coin per grain. Merchant target-margin behavior, supply withholding, and the price-spike mechanism arrive after needs.
- No multi-market arbitrage. Single region, single market per type. Travel-cost arbitrage and consumer stratification arrive when N regions > 1.
- No lord tax, no wage curve, no scarcity modifier. All wages flat per slot. Lord tax as coin sink and skill/scarcity wage modulation arrive in the wage-pricing pass.

**Forward-looking economic structure (post-prototype):**

Once the spine is proven, the layered economic model the simulation will reach for:

```
PRODUCTION (post-prototype)
  Output = A · g(t) · ∏(p(s))
  A       = land area
  g(t)    = base resource generating function (time-dependent)
  ∏(p(s)) = product of all productivity factors
  p(w)    = min(Σ p_i(workers), 1)   [capped — overstaffing adds nothing]

DEMAND (post-prototype, when needs land)
  Q_demanded = min(preferred_quantity, budget / price)
  Subsistence floor: Q < minimum → need deficit accumulates
  Budget priority: Tier 1 needs get first claim on available coin

MERCHANT (post-prototype, when margin behavior lands)
  Buy if (expected_sale - farm_gate - lord_tax) >= target_margin
  Sell at price clearing against aggregate demand
  Supply unwilling to buy at unprofitable prices doesn't reach the market

MULTI-MARKET (post-prototype, when N regions > 1)
  Consumer travel: (price_local - price_nonlocal) * quantity_needed > travel_cost
  Travel cost = time + road_risk(crime) + coin
  Subsistence actors trapped local; arbitrage stratifies naturally
```

**Income sources by actor type (target, post-prototype):**

| Actor | Income mechanism |
|---|---|
| Worker | Wage from land contract |
| Landowner | Harvest revenue minus wage costs |
| Merchant | Margin between purchase and sale price, minus lord's tax |
| Lord | Flat tax rate on all domain transactions (coin sink) |
| Player | Any of the above depending on current influence tier |

**Key structural tension to validate (post-prototype):**

The lord's tax is a coin drain on every transaction. Above a threshold rate, workers can't afford food after tax is embedded in prices, merchants exit or compress margins, and supply chains thin. The lord collects more per transaction but from fewer transactions — self-defeating. This dynamic should emerge from the model, not be authored.

---

### Progression and Unlocks

*The full influence tier system is specified in the Progression and Balance section. This section covers the economic unlock spine beneath it.*

Progression is categorical, not numerical. Each ownership milestone changes what kind of actor the player is — not just how capable.

**Difficulty scaling:** Adjusted through signal-to-noise ratio, not stat curves. The world produces more signals than any player can track. Experienced players learn which signals matter. The world does not get easier; the player becomes more legible to it.

**Endgame:** No authored endgame. Becoming king is a milestone within an ongoing sandbox. King-level problems — legitimacy management at scale, coalition suppression, regional stability — are the same simulation running at maximum complexity.

**Research/tech tree:** Not applicable. Progression is through simulation engagement and ownership acquisition, not research gates.

---

### Sandbox vs. Scenario

**Primary mode: pure sandbox.** No authored main arc, no win condition. Player-defined goals within a world that generates its own urgency. The simulation produces pressure — famine, destabilization, power vacuums — without authorship.

**World generation:** Procedurally generated maps, kingdoms, regions, actors, and hierarchies. The world is configured by world state variables at generation time.

**Starting configuration:** Default two-kingdom mode (external war dynamic active). Single-kingdom mode removes external war pressure — an accessibility dial for players learning the economic and influence layers before kingdom-level destabilization is introduced.

**Modes:** Deferred for full specification. Challenge starts and custom world states are planned as particular configurations of the world state variable system. Slider UI for tuning starting conditions is a future feature, not a prototype requirement.

---

## Progression and Balance

### Player Progression

**Two-axis influence model — no artificial tier gates:**

Influence in The King You Don't See is not a level or a label. It is a state the simulation continuously reads. Two axes drive it:

**Direct influence (coin-based):** The count of actors contracted to or employed by the player — workers, henchmen, partners, retainers. Direct influence expands operational footprint. It is purchased with coin and constrained by the same market dynamics every other actor faces: wages must be paid, contracts honored, supply chains maintained.

**Indirect influence (stats/exp-based):** Whether actors will support the player's initiatives without explicit contract — through reputation, demonstrated capability, and social standing. Indirect influence works in both directions: high indirect influence draws passive cooperation and unsolicited opportunity; it also makes the player a viable target. High-influence NPCs assess the player's indirect influence when deciding whether to cooperate, compete, or preempt.

*Architectural note (dual-clock coherence):* Indirect influence is updated on compressed-time ticks; direct influence is updated on active-time events. They read from each other but do not write to each other mid-tick — reconciled at period boundaries like two columns in a ledger. This prevents feedback loops during simulation steps.

**No unlock screens. Threshold listeners, not gates:**

As both axes grow, the simulation naturally exposes new interactions, new adversaries, and new opportunities. The player experiences tier transition through how the world behaves around them — NPCs address them differently, new options surface in conversations, the simulation generates different coalition pressures.

*Design note:* The simulation does not rely on pure emergence to surface new interaction classes. A threshold detection layer watches the influence axes cross soft thresholds and weights the probability of new interaction classes entering the NPC decision pool. The player never sees a gate — but the designer has authored the shape of the response curve. Not a door that locks: a slope that steepens. Validate in playtesting: can a player articulate what changed after the fact? If not, the response curve needs strengthening.

**World response scales continuously:**

Threshold moments must be designed to be noticed even when unannounced. The corrupt magistrate approaching the player for the first time — instead of the player always chasing — is the gate. The simulation's response to growing influence must change player experience continuously, not only at dramatic late-game events. If indirect influence rises but nothing behaves differently, players will read it as "nothing to do."

**The two-path fork:**

The same influence systems support two distinct trajectories:

| Path | Mechanics | Texture |
|---|---|---|
| Legitimate | Investment, land purchase, merchant relationships, market expansion | Reputation as currency; adversaries are competitors and political rivals |
| Shadow | Infamy, corrupt patrolmen, tip networks, henchmen recruitment, protection | Reputation as liability; adversaries include law, former allies, rival criminal networks |

The fork is not mechanical — it is strategic and reputational. Both paths run on the same underlying simulation. The world reads the pattern of your actions and generates appropriate allies and adversaries for whoever you're becoming.

---

### Difficulty Curve

**Not a stat curve — a legibility arc.**

The world produces more signals than any player can track at any stage of the game. Difficulty is calibrated by signal-to-noise ratio, not by enemy hit points. The world does not get easier as the player progresses — it becomes more legible to them.

**Early game — the world before you can read it:**

The player arrives mid-motion. The designed introduction to world complexity is the tavern on the first night: NPCs broadcasting live world state through conversation — *"life's good here," "another day without pay and I'll strike," "good money to clear those bandits off the eastern road."* These are not tutorials. They are signals. A player who recognizes them as signals acts immediately. A player who treats them as atmosphere learns more slowly. Neither is wrong; the world rewards the attentive without punishing the patient.

The profit/risk engines are legible from the first session. The better a player reads them — market day timing, merchant margin logic, the relationship between wages and productivity — the better they perform. Understanding beats grinding.

*Design note — noise design is load-bearing:* Signal-to-noise difficulty requires deliberate noise. Gossip that sounds relevant but isn't. NPCs with confident but wrong reads on world state. Deliberate misinformation and irrelevance woven into the environment. Without designed distractors, "reading signals" is not genuinely difficult — it is merely slow. Early-game information density must read as *the world is alive and chaotic*, not *the game is missing content*. This is as much a presentation problem as a design problem.

**Mid game — reading wider:**

The player is learning other markets, talking to workers in neighboring towns, mapping merchant networks, identifying where to invest or where to disrupt. The simulation expands the legibility problem: more world to read, more signal sources, more actors with agendas. The mid-game arc is the player discovering that the same skills that worked in one market work everywhere — and that the world has already started generating responses to who they're becoming.

**Late game — the weight of scale:**

High-influence failure is structurally different from low-influence failure.

| Scale | Failure feels like |
|---|---|
| Low influence | Personal setback — less coin, broken contract, lost fight |
| High influence | Structural event — dissolved partnership, betrayal, correlated portfolio collapse, regional destabilization |

**The game is about moments. Tail events as designed peak — with sequencing discipline:**

The designed emotional ceiling of late-game play is the tail event — something not authored, not planned, that the simulation produces because the player played long enough for the probability space to deliver it. Cascading systemic failure. A consequence landing from a decision three sessions ago. A betrayal from someone trusted with too much.

*Design note — tail events are escalation thresholds, not a separate system:* Do not build a dedicated "dramatic event" system. Design for simulation states that, once crossed, unlock high-volatility actor behavior — the cascade emerges from the simulation doing what it already does, just hotter. Same emotional payoff, less to build, failures are debuggable.

*Design note — build order for tail events:* The logging substrate comes first — every significant simulation decision writes a lightweight record. Not for tail events yet; for understanding the simulation's own distribution of outcomes. When the normal distribution is legible to the developer, the tail event layer follows: a probability tracker reading from the log, threshold watchers, and a curated set of authored event templates instantiated when probability conditions are met. Estimated scope once the log substrate exists: two to three weeks focused work. It must come after the simulation is legible to the developer, not before.

*Design note — post-hoc legibility is the test:* Tail events land as the game's signature moment only if the player can reconstruct the causal chain after the fact. "I didn't have to touch him — I just made sure the right people found out." If the cascade feels random even when it isn't, the emotional response is frustration, not awe. Design for the reconstruction, not just the event. The diegetic legibility architecture (four independent channels: audio, NPC dialogue, behavior, visible state) is the mechanism that makes reconstruction possible.

---

### Economy and Resources

The simulation economics defined in the Simulation Specific Design section — grain and coin circular flow, merchant as simulated actor, multi-market dynamics, lord's tax as coin sink — represents the **prototype foundation only.**

**Build philosophy:** Prove emergence at minimum fidelity first. Then build economic systems one loop at a time, tested carefully before the next layer is added. The full economic system will not be envisioned in advance. Future elicitation sessions will expand the economy incrementally as each layer is validated by prototype testing.

*Economy expansion is explicitly deferred to post-prototype elicitation.*

---

## Level Design Framework

### Structure Type

**Open world, procedurally generated, simulation-driven.**

The King You Don't See has no levels, stages, or authored content sequences. The playable space is a continuous world of interconnected regions, each generated at world-seed time and populated with actors running the same simulation from the moment of creation. The world is not a content delivery system — it is a state machine the player enters mid-motion.

**Burn-in equilibrium:**
Before the player arrives, the simulation runs a time-period burn-in phase. Economies establish supply/demand baselines, lords consolidate or contest territory, labor markets reach initial equilibrium, and social hierarchies form from the starting actor pool. The player enters a world that has been running — with existing tensions, existing power structures, and existing instabilities baked in by the simulation's own logic.

*Architectural design notes (burn-in):*
- The dual-clock system must be a first-class architectural citizen from day one. Burn-in is a headless simulation pass decoupled from rendering — if both clocks share a tick, burn-in cannot run at accelerated rate without breaking the active layer.
- Burn-in runs at **regional fidelity** (aggregate floats), not full actor fidelity. Full fidelity simulation has nothing to anchor to without a player in the near zone. Near-zone actor simulation begins at local instantiation — when the player enters a region and specific actors are generated whose aggregate properties are consistent with the regional state. Local instantiation is a first-class system requiring explicit design, not a byproduct of load.
- Two failure modes to design against: *runaway accumulation* (a lord archetype too efficient at extracting a resource drains it to monopoly before player arrival — needs a stability threshold check) and *oscillation without damping* (supply and demand chasing each other without converging — regional price floats need damping coefficients and moving averages, not spot-price reactive logic; the economy needs memory).
- Burn-in monitoring is required: simulation state must be observable *during* burn-in, not only at the final snapshot. A stable final state and a wildly oscillating state that happened to land somewhere reasonable are indistinguishable without mid-run observability.

**World seeds and infinite playability:**
Each world seed produces a unique configuration of natural resource distributions and lord behavioral archetypes. These ingredients combine to generate emergent regional character. No two seeds produce the same political economy. The design goal is that the core mechanics generate something genuinely new in every playthrough, indefinitely.

---

### Regional Structure

**Regions as the primary spatial unit:**
A region is the simulation's unit of geographic and political coherence — a bounded area with its own supply/demand dynamics, lord authority, crime baseline, NPC population, and fidelity tier behavior. Regions are not authored environments; they are simulation configurations that produce distinct felt experiences from their generated starting conditions.

**Regional differentiation emerges from two generative dimensions:**

| Dimension | Examples |
|---|---|
| Natural resource profile | Grain-rich agricultural land; mineral deposits; trade route access; coastal fishing; contested frontier with no dominant resource |
| Lord behavioral archetype | Extractive (high tax, low legitimacy investment); mercantile (trade-friendly, market access priority); military (high garrison, low crime, high stability); corrupt (shadow economy patron, selective enforcement); absent (legitimacy vacuum, power contest in progress) |

The intersection produces emergent regional character — economic profile, dominant power dynamics, crime conditions, NPC behavioral mix — without hand-authored content.

**If specific simulation situations need to exist:** Manufacture them by tuning the engine conditions that produce them, not by authoring content directly. The simulation is the content pipeline.

*Design note — tune-to-a-target discipline:* "Tune conditions" only works with a concrete felt target written down first. "Players should feel grain scarcity before they've spoken to a single merchant" is a tunable spec. "Players should feel scarcity" is not. Write the felt experience before touching parameters.

---

### World Navigation and Region Discovery

**Movement is information-driven, not waypoint-driven.**

Players move between regions by following information: tavern talk with specific names and prices that seem wrong, merchant networks carrying price differentials from their routes, consequence-following (actions create downstream effects in other regions), and opportunity pull at higher influence tiers.

*Design note — information quality is the load-bearing work:* The design investment belongs in the quality of signals, not the structure of the system. A signal must be specific — a name, a price that seems off, a concrete complaint — not ambient texture. Generic chatter reads as missing content. Specific world-state readouts are the mechanic.

*Design note — noise design is required:* Without deliberate distractors, reading signals isn't genuinely difficult — it's just slow. The information environment needs gossip that sounds relevant but isn't, NPCs with confident but wrong reads on world state, and red herrings that cost the player something before being identified. Noise is not the absence of signal design — it is signal design.

---

### Tutorial Integration

**The Structured Observer Entry + Contextual First-Touch Layer**

Two mechanisms working in parallel, neither interrupting the simulation.

**The Structured Observer Entry** *(thin, diegetic, built last):*
Player begins as an outsider with a plausible reason to be in the starting region — a debt to work off, a letter to deliver, a newcomer seeking their first contract. One NPC gives them a first task that pulls them naturally through one core system (find work, get paid, buy food — the circular flow in miniature). After a short contained sequence (5–10 minutes), the player is released into the full simulation with functional footing.

*Authored grammar anchor:* One guaranteed early interaction establishes the simulation's grammar before emergence takes over — one lord, visibly wanting one thing, visibly getting it or not. Players cannot infer "I outwitted a lord" if they've never seen what a lord wants. One authored sentence makes the procedural paragraphs readable.

Design constraints: skippable from second playthrough; built after simulation is stable; functions as a design forcing function — authoring this entry requires articulating the starting world state, which becomes a test harness for whether the simulation produces legible starting conditions.

**The Contextual First-Touch Layer** *(always active, never intrusive):*
Every simulation system surface has a first-touch moment. Brief aside, fires once, never again. Embedded in world texture — an NPC line that surfaces the logic of a system, a journal entry that collects what the player has discovered. Every system must be audited for its first-touch moment before ship.

**Long-term target:** As the simulation matures and playtesting reveals what players consistently misread, the Structured Observer Entry shrinks and the First-Touch Layer expands toward ambient world legibility.

---

### World Design Principles

**Emergent, not authored.**

- *Every region has felt scarcity.* Generation must be tuned so no region feels abundant in everything.
- *Every scarcity is reachable through play.* The generation space must cover it without requiring a specific seed.
- *Write the felt target before tuning.* The engine is the level designer — but the designer must specify what experience is missing in concrete, testable terms before touching parameters.
- *The grammar comes first.* One authored anchor per new system class; everything else can be emergent.

---

## Art and Audio Direction

### Art Style

Stylized 3D with strong silhouette discipline and shader-first state communication. Not photorealistic, not hard-edge low-poly — enough mesh resolution for blend-shape-driven needs-state expression and wear-state deformation, constrained to keep crowd-scale performance healthy (target: 2–5k vertices per character archetype). The closest reference for scope and approach is *Wartales* — purposeful, readable, stylized without chasing surface realism.

The tone anchor: **performance of normalcy, not normalcy itself.** Characters should feel slightly too composed — like everyone is performing their role rather than living it. The simulation readout lives in the cracks: when the wear parameter starts showing, when posture starts to slump, when the color temperature of a market crowd begins to cool. That crack is the emotional payload.

#### Character Design — Three Signal Layers

Characters communicate simulation state through three independent, legible channels that stack without conflict:

| Layer | Signal | Reads at | Mechanism |
|---|---|---|---|
| Silhouette | Role archetype | 20m+ | Exaggerated proportions baked into base mesh. Farmer: wide, low, labor posture. Merchant: asymmetric, mid-weight, active hands. Lord: tall, vertical, posture that costs calories. Guard: angular, structured. Immutable — never varies. |
| Color temperature | Needs tier | 10m | Shader-driven `needs_health` float (0.0–1.0) fed from the ReadoutMapper. Stable (1.0): warm earth tones, saturated, coherent. Strained (0.5): cooled hue, slightly desaturated, texture reads as worn. Failing (0.0): ash-gray shift, visual entropy, postural collapse. |
| Accent color | Faction | 10m | Fixed hue on a specific costume location (collar, hem, or belt) — never bleeds into other channels. 5–6 faction colors, legend-key stable across the world. |

Blend shapes (8–12 targets per rig) — slumped posture, hollow cheeks, tensed jaw, dropped shoulders — are driven alongside the shader by the ReadoutMapper, adding a third physical channel at close and mid range. One base model per archetype. Clean UVs. Needs-state handled entirely in engine — no asset variants.

#### Visual References

- **The Favourite** (2018 film) — costume and spatial positioning broadcast power tier without dialogue. Primary character design reference for how social status is worn, not stated.
- **Hades** — silhouette discipline; every archetype readable across faction and role at any scale.
- **Disco Elysium** — color theory for "precarious normalcy": slightly off-saturated, slightly wrong, but not ugly. A world that looks like it used to be beautiful and is having a bad decade.
- **Frostpunk** — environmental palette as world state readout; population condition bleeds into the environment before any UI confirms it.
- **Darkest Dungeon 2** — art budget invested in state-readability, not surface realism. Every visual element communicates character condition.

#### Color Palette

Muted base with vibrant accents — the muted base establishes "normal," the accents carry legibility and faction identity. The palette is a simulation readout operating in parallel with character design:

| World State | Environment Palette | Character Palette |
|---|---|---|
| High stability | Warm, golden, soft saturation | Warm earth tones, coherent colors |
| Low stability | Cooler, grayer, ambient quiet | Color temperature cooled, desaturated edges |
| Player adrenaline | Vignette, saturation spike, world narrows | — |
| Sleep deprived | Desaturated edges, softened contrast | — |

Zone-level aggregate lighting carries regional health — a prosperous district is lit warmly, a failing one cooler and grayer — so players read the crowd's collective state from the *world*, not from squinting at individual NPCs.

#### Camera and Perspective

Third-person, slightly tilted toward an isometric lean when the player surveys a space — camera functions as a *simulation instrument*, not just a character follower. Close follow for active combat and traversal; elevated survey angle available for town squares and market reads. Camera system must be finalized before art brief is delivered to outsource artists, as play-distance pixel height determines the detail level worth commissioning.

### Audio and Music

Diegetic first, score second. The world sounds before it scores. Every audio decision serves the simulation readout.

The score responds to **world state trend** — the rate of change in regional stability, not the current absolute value and not player action. If three districts are slowly destabilizing over ten minutes, the score builds unease for eight of those minutes — before the riot, before the UI indicator, before the player has named what they're feeling. The score tracks the *slope*, not the *value*. Music sometimes runs ahead of what the camera has shown, whispering what the simulation already knows.

Market ambient audio reflects economic activity — busy markets sound busy, failing ones sound sparse and wrong. NPC conversation volume and tone reflect regional tension without words being distinguishable. The player *hears* the simulation before they see it.

#### Music Style

Orchestral with ambient and folk-textural layers — sparse, atmospheric, low melodic saturation. Stems delivered by composer, not linear tracks. Horizontal re-sequencing via FMOD or Godot's AudioStreamPlayer with crossfade logic. Composer must be briefed on interactive audio from the first conversation.

**References:** *FTL* (audio responds to world danger state, not player action) · *Into the Breach* (score confirms player's read of state — tagged to visible world changes) · *Hellblade: Senua's Sacrifice* (audio as cognitive system reading internal state)

#### Sound Design

Adrenaline has a heartbeat. Sleep deprivation has subtle audio degradation. Market crashes have a sound before they have a UI indicator. Environmental audio carries simulation state before the visual layer does at the macro level. Sound design is legibility infrastructure, not atmosphere.

#### Voice / Dialogue

Tonal vocals only — grunts, emotional fragments, no full VO. NPCs vocalize emotionally but not linguistically. Full VO would make the world feel authored; tonal vocals make it feel inhabited. NPC vocal register shifts with needs tier: thriving NPCs have warmer, rounder vocal textures; stressed NPCs are drier and more clipped.

**Reference:** *Hollow Knight* — no words, full emotional content. Every vocal fragment is a simulation data point, not an aesthetic flourish.

### Aesthetic Goals

The art and audio layers are the simulation's sensory cortex. Players should not need the UI to feel the world. By the time the UI confirms what they suspected, they should already know.

| Pillar | Art / Audio expression |
|---|---|
| The World Doesn't Wait | Zone lighting and ambient audio change without player action. The score shifts before the player acts. The market sounds different before the UI shows it. |
| Consequence Is Structural | Character wear state degrades visibly over time — needs-tier entropy shows on the body before any dialogue triggers. Crowd palette shifts confirm what the player inferred. |
| Power Is Earned Through Understanding | Visual and audio systems reward observation. Players who look at the crowd read world state. Players who listen hear what the simulation is about to do. |
| Surface and Depth Are Both Real | Combat adrenaline (vignette, heartbeat, saturation spike) is immediate and kinetic. Simulation state reads (palette, posture, ambient tone) are slow and cumulative. Both layers speak simultaneously. |

### Production Notes

- **Vertex budget ceiling before outsourcing.** Background crowd NPCs use simplified meshes with shader-only signaling; foreground NPCs carry full blend-shape and shader readout. LOD tier is a ReadoutMapper output, not a renderer decision.
- **Lock one foundational artist for first 3–4 archetypes.** Derive the style guide from their output, not a mood board. Style guide is a production asset as critical as the GDD.
- **Brief with reference images, not the phrase "stylized 3D."** The spectrum is too wide for an open brief.
- **Shader-driven wear state only — no asset variants.** One base model per archetype, clean UVs; needs-state driven from engine.
- **Composer must deliver stems, not tracks.** Confirm interactive audio experience before hiring.

---

## Technical Specifications

### Performance Requirements

The active layer (combat, movement, world traversal) runs at a locked 60fps — non-negotiable regardless of simulation complexity. The simulation layer is architecturally independent of the render loop and operates on cadenced event resolution, not per-frame processing.

#### Frame Rate Target

60fps minimum on the active layer. The simulation layer has no frame rate target — it runs on a discrete event schedule (weekly lord decisions, daily execution ticks, queued event resolution). These two rates are deliberately decoupled and must remain so from the first line of sim code.

#### Resolution Support

1080p minimum, 1440p as the primary design target. 4K is deferred — resolution scaling is a post-launch concern once the core game is validated. No design decisions should be blocked on 4K support.

#### Load Times

No hard targets, but a design discipline: **seconds, not minutes.**

| Context | Target |
|---|---|
| New area / region transition | Under 5 seconds |
| Burn-in simulation pass (pre-player) | No hard ceiling — design for observability and tuning, not a black box |
| Scene load after burn-in | Standard Godot scene load, optimized as needed |

Burn-in is a headless simulation pass at regional fidelity before the player enters the world. Its duration scales with world complexity and seed. The metrics layer (simulation telemetry) must be active during burn-in so duration and stability are measurable and tunable.

---

### Simulation Architecture Constraints

These are technical requirements derived from the simulation design. They are load-bearing.

#### Window-and-Bus Simulation Model (prototype foundation)

The simulation is **not** hundreds of autonomous NPCs running individual AI every frame. It is a **tick-driven, window-mediated, market-cleared model:**

- **`SimClock`** advances simulated time and fires `daily_tick(slot)` (8 slots/day) and `weekly_tick()` (during `EARLY_MORNING` of day 7)
- **`WindowBus`** carries `opened` / `closed` signals for named windows (Labor Market, Work, Wholesale Market, Retail Market). Anyone can fire either; subscribers don't know who fired.
- **`WindowOrchestrator`** listens to `SimClock` and decides which bus signals to fire on which ticks. It is the only thing that knows the calendar — replacing or supplementing it is how scenario tools and debug commands fire windows manually later.
- **Markets** (region-scoped) accumulate supply and demand pools between clearings; clear when their window closes; write account changes synchronously.
- **Actors** carry **Interests** that subscribe to bus signals and drive economic behavior. The Actor is the sum of its interests.

The world's economic behavior emerges from interests responding to window signals and markets clearing — not from individual NPC behavior trees. The simulation is **accounting and scheduling**, not AI.

#### Hierarchy-Driven Decision Layer (post-prototype, Epic 2+)

Once the spine runs cleanly, hierarchical decision propagation layers on top:

- **Lords** evaluate and issue strategic decisions on the **weekly cadence**
- **Lower lords / stewards** execute those directives on the **daily cadence**
- **Random events** interrupt at lower levels and propagate back up via an event queue
- The player injects `SimEvent` objects into the same queue as all other events, resolved at tick boundaries

This layer is *not* in Epic 1. Epic 1 proves the loop runs without it.

#### Rendering Contract

Only a **handful of NPCs are drawn** at any time. The broader economy runs entirely in the invisible sim layer.

| Tier | What renders |
|---|---|
| Near (player zone) | Full actor sim — a small set of specific NPCs whose aggregate state matches the regional sim |
| Regional | Aggregate floats only — grain supply, coin flow, stability index. No individual actors drawn. |
| Distant | Statistical drift. No individual actors. |

Player-initiated disruptions (combat, market interference, a deal struck in person) inject into the sim event queue with a player-source tag. The sim resolves them identically to NPC-initiated events.

#### SimClock Architecture

No `_process()` in the simulation layer. Zero. All sim logic is **cadence-driven** via a dedicated `SimClock` autoload that fires typed signals:

- `daily_tick(slot: TimeSlot)` — fires 8 times per simulated day in slot order: `EARLY_MORNING`, `MID_MORNING`, `LATE_MORNING`, `EARLY_AFTERNOON`, `LATE_AFTERNOON`, `EARLY_EVENING`, `LATE_EVENING`, `MIDDLE_OF_NIGHT`
- `weekly_tick()` — fires once per simulated week during `EARLY_MORNING` of day 7, immediately after that slot's `daily_tick` resolves
- *(reserved)* `monthly_tick`, `yearly_tick` — for later
- *(post-prototype)* `event_interrupt` — random events, player actions, cascade triggers; not in Epic 1

Sim actors and interests subscribe to the signals they need (directly to `SimClock`, or indirectly through `WindowBus`). Nothing runs unless a tick fires. Off-screen events resolve at fixed window boundaries — not continuously. This makes the simulation effectively **turn-based inside a real-time shell**, which eliminates threading complexity and keeps behavior deterministic and debuggable.

**Tick rate:** Configurable from day one — fast for testing (collapse a sim week into seconds), slow for observation. The exact rate is not load-bearing against any architectural decision.

#### Sim Data as Pure Value Types

Sim state lives in plain GDScript `Resource` objects or dictionaries — not node trees. No `get_node()` in the sim layer. No scene tree dependencies. The sim layer takes data in and returns data out through a clean interface.

Lords are data containers. A separate `SimProcessor` reads them and writes decisions back. Memory stays flat, iteration stays predictable, serialization stays trivial. This is the discipline that makes GDScript viable for this simulation.

#### State-Render Bridge (ReadoutMapper)

```
SimulationState → ReadoutMapper → VisualStateDescriptor → RenderParameters
SimulationState → WorldStateAggregator → MoodVector → AudioMixerParameters
ZoneState      → ZoneStateAggregator  → EnvironmentLightingParameters
```

The ReadoutMapper is the only bridge between simulation truth and visual/audio presentation. It polls simulation state each frame — does not wait for push events. The sim layer does not know about shaders or audio. The render/audio layer does not know about needs tiers or grain supply. The ReadoutMapper is the only place these concerns meet.

#### Fidelity Transition Policy

Near ↔ Regional transitions must not spike the active-layer frame time. Actor hydration at Near-zone entry must complete within the area load time budget (under 5 seconds). Actors generated at Near-zone entry must be consistent with the Regional aggregate for that zone — deterministic for a given world seed + regional state. Re-entering an area produces coherent actors, not random re-rolls.

#### Save / Serialize Architecture

Sim state must serialize cleanly and reload deterministically. Because the sim layer is pure value types, serialization to a structured format requires no custom logic. Config schema and save format must be versioned together — a config change that breaks old saves is a data integrity failure. This needs an architectural slot before content scope expands.

---

### Platform-Specific Details

#### PC (Steam) — Primary Launch Target

**Minimum specification (mid-tier 2023 hardware):**

| Component | Minimum |
|---|---|
| GPU | NVIDIA RTX 3060 / AMD RX 6600 or equivalent |
| CPU | Intel Core i5-12400 / AMD Ryzen 5 5600 or equivalent |
| RAM | 16GB (floor, not comfort zone) |
| Storage | SSD recommended |
| OS | Windows 10/11 64-bit |

**Performance note:** CPU is the likely bottleneck to profile against, not GPU. Profile CPU load under full regional-tier sim load as the primary performance test target.

**Steam integration:** Basic at launch. In-game achievement system designed first — achievement events are instrumentation points in the simulation layer from day one, not retrofits. Steam Achievements are a port-out of that internal event system. No Steam Workshop at launch.

**Mod support:** Not a launch requirement. The config-driven, data-first sim architecture puts mod support closer than a hardcoded game would. Maintain config discipline with this possibility in mind. Revisit after the core game is proven.

**Console:** Post-launch only. Not a constraint on current development.

---

### Asset Requirements

#### Character Archetypes

Dozens of archetypes at full scope, all config-driven. Behavioral config is the primary design asset — visual archetypes are instances of it. Round 1 targets a handful of core archetypes (farmer/worker, merchant, lord, guard, player character). Additional archetypes added incrementally as gameplay validates the need.

**Archetype contract — one must fully satisfy all criteria before the next begins:**
- Config file with behavioral parameters
- Readable behavior loop in the sim layer (wakes, works, eats, sleeps, strikes)
- Visual expression in Near tier (base mesh, shader-driven needs-state, blend shapes)
- Graceful degradation to Regional aggregate (becomes a sim float, not a rendered object)

One base mesh per archetype. Clean UVs. Needs-state driven in-engine via `needs_health` shader float and blend shapes. No per-state asset variants.

#### Environment Assets

**Procedural templates** — authored modular kit assembled procedurally. Not fully procedural PCG, not hand-placed unique levels.

**Round 1 scope:** Handcrafted scenes built with the modular kit. Build the kit first, hand-place one or two areas using it, extract the assembly logic in round 2 when the kit's requirements are understood. Realistic round 1 kit:

- 4–6 tileable ground / road modules
- 3–4 building facade variations per major type (tavern, market stall, residence, granary)
- 2–3 landmark anchors (well, notice board, gate)
- One assembly script producing a legible village layout from a config seed

**Template metadata schema:** Each module carries typed simulation metadata — capacity, ownership state, condition, navmesh tags, economy node tags, social space definitions — in a structured resource type, not freeform node names. Schema defined before the assembler is built. Merge/override rules for metadata (when modules combine) specified before the first assembly pass.

**Navmesh:** Per-module bake, stitched at assembly time. Dynamic full-scene rebaking is too slow. Module boundaries designed to support nav-tile stitching.

#### Audio Assets

Stems-based horizontal re-sequencing — not linear tracks. The **state variables that drive the mixer** are defined before stems are commissioned:

| State Variable | Description |
|---|---|
| `regional_stability_slope` | Rate of change in stability — the score tracks slope, not absolute value |
| `time_of_day` | Day / dusk / night |
| `location_type` | Market, road, lord's hall, wilderness |
| `player_adrenaline` | Combat proximity / threat state |
| `sleep_deprivation` | Player needs-tier state affecting audio degradation |

Composer delivers stems keyed to these variables. Must be briefed on interactive / horizontal re-sequencing before engagement — a linear-scoring composer will fight this system.

SFX scope: market ambient layers (activity-level responsive), environmental state transition cues, combat feedback, UI, vocal fragment sets per archetype (tonal only — no linguistic content).

#### External Assets

Asset store and AI generation tools acceptable for prototype and vertical slice. Production art commissioned from outsource artists after simulation loop is validated. No licensed audio or art planned.

---

### Technical Constraints

- **No `_process()` in the simulation layer.** All sim logic is cadence-driven via `SimClock` signals. Per-frame polling in the sim layer is a design failure.
- **Sim layer is pure GDScript, pure value types.** No node dependencies, no `get_node()`. Sim state serializable to a structured format without custom logic. If a specific function becomes a *measured* bottleneck, that function earns a C# conversion — decided at the chokepoint, not in advance.
- **Simulation/render decoupling is a hard requirement.** The ReadoutMapper is the only bridge. No direct coupling between sim state and shader uniforms or audio parameters.
- **60fps hot path is a veto.** Any system that cannot maintain 60fps on the active layer at minimum spec is descoped or deferred. This is a veto, not a guideline.
- **Config and save format versioned together.** A config schema change that breaks existing saves is a data integrity failure.
- **Godot 4.x, GDScript primary.** All technical decisions made in the context of Godot's rendering pipeline, GDScript, scene system, and C# interop capability.

---

## Development Epics

### Epic Structure

| # | Epic | Goal | Key Contents | Deps |
|---|---|---|---|---|
| 1 | Sim Proof | Prove emergence at minimum fidelity | SimClock skeleton, burn-in, economic circular flow, needs hierarchy, worker model, market clearing | None |
| 2 | The Living World | Full simulation engine the developer can observe and diagnose | Full SimClock, three-tier fidelity, hierarchy model, burn-in observability, multi-market, ReadoutMapper data pipeline | 1 |
| 3 | Eyes Open | Player can LISTEN — the world is watchable and readable | Player character, Greet + Question, information log, ReadoutMapper visual output, minimal character visual system, one procedural region | 2 |
| 4 | Hit Something | Validate the active layer — physical agency in the simulation | Melee combat, fight-or-flight, injury persistence, NPC state write-back, fidelity transition, inter-region navigation | 3 |
| 5 | Own Something | Give the player economic stakes — something to lose | Transact/Control, wage contract, land, market stall, enterprise milestone, save/serialize, minimal management UI | 1–3 |
| 6 | Pull the Strings | The world responds to who the player is becoming | Two-axis influence model, threshold listeners, legitimate vs shadow fork, influence reconciliation | 5 |
| 7 | A World to Play In | A full world that can be generated, played, and returned to | Full world gen, all region types, full management UI, ranged/charisma, full character visual system, adaptive audio | 1–6 |
| 8 | The Door Opens | Make the first five minutes feel inevitable for a stranger | First-Touch Layer, Structured Observer Entry, authored grammar anchor | All |

### Recommended Sequence

```
Epic 1 (Sim Proof)
    ↓
Epic 2 (The Living World)
    ↓
Epic 3 (Eyes Open)
    ↓
Epic 4 (Hit Something) ←── can run parallel with Epic 5 after Epic 3
Epic 5 (Own Something) ←── can run parallel with Epic 4 after Epic 3
    ↓ (both complete)
Epic 6 (Pull the Strings)
    ↓
Epic 7 (A World to Play In)
    ↓
Epic 8 (The Door Opens)
```

**Sequencing rationale:**
- Epics 1–2 are pure developer validation — no player-facing content until emergence is proven
- Epic 3 is the first player-facing milestone; everything before it is infrastructure
- Epics 4 and 5 are independent after Epic 3 — combat and ownership don't depend on each other
- Epic 5 (ownership) precedes Epic 6 (influence) because ownership is the accounting layer that gives influence something concrete to operate on; influence is the emotional layer that casts consequences onto ownership — the harder design problem, built on stable ground
- Epic 7 is production: art, audio, full world — commissioned after the core loop is proven worth investing in
- Epic 8 is always last — you cannot design onboarding until you know what the game actually is

**Vertical slice target:** End of Epic 5. One region. The LISTEN → INFER → COMPOSE → DISRUPT loop playable end-to-end. Player can own a market stall, observe the simulation responding to their ownership, and trace a consequence from an action taken earlier in the same session. No production art, no adaptive audio, no onboarding — just the simulation running and the loop working. This is the first build a blind playtester sees.

**Magic / Elemental:** Deferred indefinitely. Goes in after Epic 7 if scope and architecture allow. Not planned at GDD stage.

---

### Epic 1: Sim Proof — the Loop

**Goal:** Prove the planned simulation architecture supports a complete economic loop end-to-end before any layered systems (needs, aptitudes, hierarchy AI, emergence dynamics) go on top of it. This is the foundation; emergence comes in Epic 2.

**Reference:** `prototype-build-spec.md` is the locked architecture and class catalog for this epic. The build spec is canonical for what gets built; this section describes scope and acceptance.

**Includes:**
- `SimClock` autoload with `daily_tick(slot)` and `weekly_tick()` signals
- `WindowBus` autoload with open/close signals for Labor Market, Work, Wholesale Market, Retail Market windows, plus `merchant_restock` and `wages_due` signals
- `WindowOrchestrator` autoload mapping ticks to bus signals
- Region (single, structural)
- Actors: 1 LandOwner, 2 Workers, 1 Merchant
- Interests: ProductionInterest, WorkingInterest, MercantileInterest, GrainInterest
- Resources: Accounts, Payable, ProductionResource, LandPlot, Contract, LaborContract
- Markets: LaborMarket, WholesaleMarket (grain), RetailMarket (grain)
- Placeholder `WageCalculator` returning flat 1 coin per slot worked
- Phase 1 (signal-flow with print statements) → Phase 2 (stub math, success criteria pass)

**Excludes:**
- Player character, rendered world, art, audio, UI, player input
- Needs hierarchy, hunger, morale, condition flags
- Aptitudes, skills, XP, skill effects
- Lord AI, LordLedger, LordPolicyEngine, routine swapping
- Merchant pricing model with target margin; multi-market arbitrage
- Real clearing math (price elasticity, supply/demand response curves)
- Multiple goods, multiple regions, multiple plots
- Burn-in equilibrium, three-tier fidelity, ReadoutMapper
- Save/load, world generation
- Influence system, ownership-as-progression, combat

**Dependencies:** None. Ground zero.

**Deliverable:** Two simulated weeks run end-to-end with the five acceptance criteria below observable in console / log output without manual debugger inspection. All account balances reconcile (no coin or grain leaks).

**Acceptance criteria (v0):**
1. **Workers gain employment.** After day 1 LMW closes, both workers have an active `LaborContract`; LandOwner accounts list both contracts.
2. **Work contracts in place.** Contract amounts and references are consistent on both sides.
3. **Workers work, produce resources, emit payables, get paid.** By end of day 1, LandOwner inventory holds 8 grain and `payables` lists 4 coin owed each worker. By end of day 7's `wages_due`, LandOwner coin decremented by 56, both Workers coin incremented by 28.
4. **Owners sell supply in the wholesale market.** After day 7's WMW clears, LandOwner inventory grain transferred to Merchant inventory at flat price; coin moved in reverse.
5. **Workers buy supply in the retail market.** After day 7's RMW clears, consumers have grain in inventory; Merchant has coin; consumers' `outstanding_demand` decremented appropriately.

**Stories (sketch — to be expanded against the build spec):**
- Stub all Resource subclasses (data-only, no behavior)
- Stub all Interest subclasses with named methods
- Stub all Actor subclasses with `_wire_signals()` connecting interests to bus
- Stub all Market subclasses with `take_supply` / `take_demand` / `clear` / `reset_pools`
- Stub Region
- Implement `SimClock`, `WindowBus`, `WindowOrchestrator` autoloads
- Bootstrap script wires the world and starts the clock
- Phase 1: console output shows correct signal order across two simulated weeks
- Phase 2: replace prints with stub math; all five acceptance criteria pass

**Emergence (deferred to Epic 2 — *not* an Epic 1 acceptance gate):**

Famine cascade, labor drain, merchant margin capture, hunger strike contagion, and black market emergence are the targets *for the layer that follows the prototype*. They require needs, scarcity, margin behavior, and multi-actor pressure that v0 deliberately excludes. Trying to prove them on a spine that doesn't run cleanly is the failure mode the prototype exists to prevent.

---

### Epic 2: The Living World

**Goal:** A full-fidelity simulation the developer can observe, stress-test, and diagnose — the complete engine before any player touches it.

**Includes:** Full SimClock (all signal types) · Three-tier fidelity system (Near / Regional / Distant, including fidelity tier manager) · Hierarchy-driven model (lord weekly decisions → lower lord daily execution → event interrupts propagate up) · `SimEvent` queue with configurable drain cap · Burn-in with full observability (metrics layer active during burn-in, not just final snapshot) · Fidelity transition policy (Near ↔ Regional, within 5s load budget) · Multi-market dynamics (at least 2 markets, consumer travel decision) · ReadoutMapper initial version (data pipeline only — sim state → VisualStateDescriptor, no visual output yet) · Save/serialize architecture foundation

**Excludes:** Player character, rendered world, art, audio, player-facing UI · Influence system, ownership system

**Dependencies:** Epic 1 — emergence must be proven before the full engine is built on top of it.

**Deliverable:** Developer can view real-time telemetry during burn-in, confirm lord hierarchy making decisions at correct cadences, observe actors transitioning between fidelity tiers without state loss, and query the ReadoutMapper for any actor's current state descriptor. 90%+ of seeds produce stable burn-in across both markets.

---

### Epic 3: Eyes Open

**Goal:** Give the player the LISTEN verb in complete form — the world is watchable and readable before any action is taken.

**Includes:** Player character (movement, third-person navigation) · Greet + Question social verbs (proximity-triggered, returns real sim-state information) · Information log (queryable record of what the player has learned, when, from whom) · ReadoutMapper connected to visual output (character visual system minimum viable) · Zone aggregate lighting (minimum viable — warm/cool environmental shift) · Procedural template kit (one region minimum) · Bulletin boards / town criers

**Excludes:** Combat, ownership mechanics, influence system · Full art / audio, second region · Full character visual system, blend shapes

**Dependencies:** Epic 2 — the sim must be running and healthy; you're observing real state, not a placeholder.

**Deliverable:** A player can walk through a village, read NPC needs tier visually before speaking, ask questions that return information reflecting actual sim state, and begin building a mental model of the economy.

---

### Epic 4: Hit Something

**Goal:** Validate the active layer — prove physical agency in the simulation and that DISRUPT writes to world state.

**Includes:** Melee combat (expressive chains, dodge, block/parry, clean escape) · Fight-or-flight adrenaline system (vignette, movement behavior unlocks, injury-as-cost) · Injury persistence (wounds heal over time, write to social sim state) · NPC state write-back (defeated actors carry depressed stats or leave area) · Fidelity transition system (Near zone inflation on player approach) · Information-driven inter-region navigation

**Excludes:** Ranged / charisma archetype, magic / elemental · Ownership mechanics, influence system

**Dependencies:** Epic 3 — need a populated, readable world to fight in and the information system to navigate between regions.

**Deliverable:** Player can navigate a region, engage in melee, sustain an injury with real costs, execute a clean escape from an unwinnable fight, and move to a second region by following information. Developer can observe sim logs showing the world reacting to the combat disruption.

---

### Epic 5: Own Something

**Goal:** Give the player economic stakes — something to lose, something to protect, something that makes the simulation personal.

**Includes:** Transact/Control mechanics (trade, broker, withhold as first-class mechanic) · Wage contract system (player can be employed, can employ others) · Land purchase (player becomes landowner — directs labor, collects revenue, has something to lose) · First market stall (player controls distribution, influences local price) · First enterprise milestone (simulation treats player as an organization) · Save/serialize (player-facing) · Management UI (minimal)

**Excludes:** Influence system, full world generation, full management UI, ranged/charisma

**Dependencies:** Epics 1–3 (sim + observation — ownership is meaningless without a readable world to own things in). Epic 4 useful but not strictly required.

**Deliverable:** Player can sign a wage contract, accumulate coin, purchase land, open a market stall, and observe the simulation treating them as a landowner. Player can withhold supply and observe downstream price effects. Player can save and return to a world that has continued without them.

**Vertical slice milestone:** This is the first build a blind playtester sees. The LISTEN → INFER → COMPOSE → DISRUPT loop is playable end-to-end.

---

### Epic 6: Pull the Strings

**Goal:** The world responds to who the player is becoming — soft power works, and it is meaningfully different from economic power.

**Includes:** Two-axis influence model (direct: coin-based contracts/employees; indirect: stats/exp-based reputation and capability) · Threshold listener layer (designer-authored response curves — thresholds observable in sim telemetry) · Legitimate vs shadow path fork (same sim systems, different strategic and reputational texture) · Influence reconciliation at period boundaries · Multi-market dynamics tied to influence reach

**Excludes:** Full world generation, final art/audio, onboarding

**Dependencies:** Epic 5. Influence needs ownership to exist — there must be something concrete for influence to operate on and something the player cares about losing before soft power has stakes.

**Design note:** Ownership is the accounting layer (balance sheet, ROI). Influence is the emotional layer — harder to tune, requires agent behavioral variety to feel meaningful. Built after ownership is stable so influence has a real floor to stand on.

**Deliverable:** Player can cross an influence threshold without a notification and observe changed NPC behavior. Player can pursue either the legitimate or shadow path and observe the simulation generating appropriate allies and adversaries for whoever they're becoming.

---

### Epic 7: A World to Play In

**Goal:** A full world that can be generated, played across multiple regions, and experienced with complete visual and audio simulation readout.

**Includes:** Full procedural template assembly (all region types) · Region generation (resource profile × lord behavioral archetype producing emergent regional character) · Multi-region navigation (full information-driven system) · Full management UI · Ranged/charisma archetype · Full character visual system (all three signal layers + blend shapes) · Zone aggregate lighting (full regional health readout) · Stems-based adaptive audio (full horizontal re-sequencing, all state variables wired) · Vocal fragment sets per archetype

**Excludes:** Magic / elemental (deferred) · Onboarding

**Dependencies:** Epics 1–6. Production epic — art, audio, and full world commissioned after the core loop is proven worth investing in.

**Deliverable:** Player can generate a new world seed, play across multiple regions with distinct economic and political characters, use charisma as an alternative to melee, and experience the simulation readout through art and audio before opening any UI.

---

### Epic 8: The Door Opens *(built last)*

**Goal:** Make the first five minutes feel inevitable for a stranger — without a tutorial popup.

**Includes:** Contextual First-Touch Layer (every system surface has a first-touch moment — fires once, never again) · Structured Observer Entry (outsider start with plausible reason to be there; one NPC, one task, one system — 5–10 min contained sequence, then released into full sim) · Authored grammar anchor (one guaranteed early interaction: one lord, one visible want, visibly getting it or not) · Observer Entry is skippable from second playthrough

**Dependencies:** Everything. Built after all systems are stable — you cannot design onboarding until you know what the game actually is.

**Deliverable:** A blind playtester can start the game and reach functional footing within ten minutes without a tutorial popup or external explanation.

---

## Success Metrics

### Metric Design Principle

Session length is not a success metric in isolation — long sessions can mean compelling or confused. Cross-reference every engagement metric with *voluntary return rate*. The signal is whether players come back, not how long they stayed.

---

### Technical Metrics

#### Simulation Health Gates (Binary — must pass before any playtesting begins)

These are not metrics to track over time. They are preconditions. If the sim isn't healthy, playtest data is noise.

**Epic 1 (prototype) gates** — see `prototype-build-spec.md`:

| Gate | Target | Notes |
|---|---|---|
| Loop runs two simulated weeks | Yes, all five v0 acceptance criteria pass | No manual debugger inspection required |
| Account reconciliation | No coin or grain leaks across the run | Sum of coin/grain conserved at every clearing |
| Signal ordering | Daily and weekly flows fire in canonical order | Verified via console / log trace |

**Epic 2+ gates** (after needs, scarcity, and emergence layer in):

| Gate | Target | Notes |
|---|---|---|
| All 5 emergence behaviors observable | Yes, in unsupervised 10-cycle run | Observed by someone who wasn't told what to look for |
| Famine cascade traceable | Yes, end-to-end in sim logs | Developer must be able to follow the chain |
| Burn-in equilibrium rate | 90%+ of seeds | Non-degenerate, non-monopoly, non-oscillating |
| Circular flow completion | 4+ weekly cycles without intervention | No developer input required |
| Multi-market arbitrage | At least 1 event per 10-cycle run | Demonstrates multi-market dynamics working |

#### Performance Gates (Binary — active layer hard floor)

| Gate | Target | Notes |
|---|---|---|
| Active layer frame rate | 60fps locked at min spec | Non-negotiable veto; any feature that breaks this is descoped |
| Sim tick time | Monitored weekly during dev | Creeping upward = performance debt accumulating |
| Save/load round-trip time | Under 3 seconds | Longer feels broken to a player |
| Save/load sim determinism | Functionally identical state on reload | Verified via deterministic seed replay, not visual inspection |
| Crash rate | Under 1/hr during playtesting | Above this: fix before next session |

**Note on save/load determinism:** If save/load introduces sim drift, players who take breaks return to a world that has silently diverged, losing trust in their own inference chains. This is a design-level failure hiding inside a technical bug.

#### Development Tracking (Weekly, Simple Spreadsheet)

| Metric | Signal |
|---|---|
| Sim tick time (ms) | Creeping up = performance debt accumulating |
| Crash rate per hour of VS play | Above 1/hr = fix before next session |
| Systems touched per session | If players only use 2 of 6 systems, 4 are invisible |
| Playtester "lost/confused" moments | Timestamp + quote; no interpretation at collection time |

---

### Gameplay Metrics

#### Vertical Slice Playtester Gates (End of Epic 5)

**Observable during session (no surveys required):**

| Signal | Target | What failure looks like |
|---|---|---|
| First unprompted pause — player stops moving and watches the sim | Before minute 15 | Never happens = world not generating legible signals |
| Time-to-meaningful-choice | Under 8 minutes | Over 8 min = onboarding is costing wishlists |
| "Wait, what just happened" moment — player catches an unplanned consequence | At least once per session | Never = consequence loops invisible |
| Inference attempt rate — player explains something to themselves before checking UI | 3+ instances per session | Zero = world not generating legible questions |
| Voluntary COMPOSE engagement — non-combat composition used without prompt | Yes, at least once | No = loop isn't intrinsically motivating |
| Session end behavior | Player asks "can I do one more thing?" | Immediate "okay cool" = no investment |
| Session map — where did they stop? | Reached DISRUPT phase | Never reaching DISRUPT = everything after COMPOSE is untested |

**Instrumented metrics (logged):**

| Metric | Target | Notes |
|---|---|---|
| Inference attempt rate | >70% of sessions include voluntary compose-layer open | Below = LISTEN layer not surfacing enough signal |
| First meaningful disruption timing | 15–30 minute median | Under 10 min = telegraphing too hard; over 45 min = opaque |
| Sim-touch rate per session | 4–6 distinct sim writes per session (median) | Below 3 = player skimming the surface |
| Playtester second-session rate | 60%+ of blind playtesters return | Below = hook isn't holding |

#### Vertical Slice Exit Interview (10 minutes, post-session)

These are not satisfaction questions. They are perception-fantasy diagnostics.

**"Describe what kind of person your character was in this game."**
*Role answer ("a merchant," "someone who manipulated the guilds") = winning. Mechanic answer ("someone who clicked on stalls") = redesign the onboarding.*

**"At any point, did you feel like you understood something about the world that you hadn't been told? If yes, describe the moment."**
Target: 4 out of 5 first playtesters can describe a specific inference moment unprompted. This is the single most important qualitative gate at the vertical slice milestone.

**"Was there a moment where something you did earlier had an unexpected effect? What was it?"**
Target: 3 out of 5 playtesters report a causal surprise they can articulate backward.

**"What did the other characters want?"**
Right answer = any specific answer. Wrong answer = "I don't know" or "they just reacted to me." If NPCs feel like props, the World Doesn't Wait pillar has failed.

**"What would you do differently if you played again?"**
Specific answer = failure felt like their insight gap, not game opacity. "I don't know, level up faster?" = they're treating it as a numbers game.

**"Did anything happen that surprised you but felt fair?"**
Fair surprise is the exact emotional fingerprint of good simulation design. Unfair surprise = frustration. Pure prediction = satisfaction but no peak. Fair surprise = consequence peak.

**"Did you feel like you figured things out, or did things just kind of work out?"**
*Smarter = perception fantasy landing. Luckier = outcomes the player can't connect to their actions.*
**Target: at least 3 out of 5 blind playtesters say "smarter." If fewer: pause, diagnose, fix before Epic 6.**

#### Failure Signals — Hard Stops (Redesign, Not Polish)

1. **Player never looks away from their own status.** Every glance is "how am I doing" not "what is the world doing." Core fantasy inverted — onboarding and framing failure, runs deep.
2. **Player asks "what should I do next?" more than twice.** World isn't generating its own legible pull. Not a UI fix — a world-state-generation problem.
3. **Combat feels like the "real game."** "I wish there was more combat" = the surface layer has become the gravity well. Depth problem.
4. **Can't name a faction's disposition without checking UI.** World is speaking in data, not behavior. Spreadsheet game with a medieval skin.

**The honest stop-building trigger:** If after two rounds of playtesting the LISTEN → INFER loop isn't producing "wait, so if I do *this*, then *that* happens?" moments naturally — without explanation — you don't have a game yet. You have a simulation. Stop adding features and fix the feedback loop that makes the system readable.

---

### Qualitative Success Criteria

#### Vertical Slice

- Blind playtesters describe their character using a *role*, not a mechanic
- Playtesters volunteer causal explanations ("I think the lord cut supply because...") without prompting
- Failure response in debrief is "I should have seen that coming" not "that was unfair"
- Playtesters build their own mental model of sim behavior and can articulate it

#### Launch

- Steam reviews surface the phrases: "I should have seen that coming," "I traced it back," "I understood the world" — the design-intent signal buried in natural language
- Negative review dominant complaint is "too complex" or "too slow" (expected audience mismatch) — *not* "nothing I do matters" (sim responsiveness failure, requires a design patch; these look similar from outside but require completely different responses)
- At least one content creator (5K–30K followers) plays live and gets *curiosity-lost* in the systems — not confused-lost. That single stream tells you more about market fit than any spreadsheet.

---

### Launch Success Targets

*(Reference targets only — revisit after Epic 7 is validated. Too early to optimize for these.)*

| Metric | Target | Notes |
|---|---|---|
| Wishlists at launch | 8,000–15,000 | Below 5,000 = long-tail grind, not spike |
| Launch week units | 1,500–3,000 | At ~$17 avg: $17K–$35K after Steam cut — runway + validation |
| Launch week reviews | 50+, 70%+ positive | Below 70% positive = algorithm buries you |
| Day 7 retention | >40% | Niche sim audience; 40% D7 is strong and realistic |
| 60-day retention (past 2 hours) | >30% of buyers | Below 20% = core loop not holding past session one |
| Player-causation rate in major sim events | 40–60% | Below 30% = world runs without player; above 80% = player is the world's engine. Both violate a pillar. |
| Unprompted backward tracing | >35% of major negative events trigger trace attempt | Proxy for "I should have seen that coming" response in action |

---

## Out of Scope

### Explicitly Out of Scope for v1.0

| Category | Item | Notes |
|---|---|---|
| **Features** | Multiplayer / co-op | Single-player only |
| **Features** | Leaderboards | Not applicable to sandbox sim |
| **Features** | Mod support | Config-discipline maintained to make this easier later; not a launch requirement |
| **Features** | Steam Workshop | Post-launch |
| **Features** | Level editor | Not applicable — procedural world |
| **Features** | Controller support | Keyboard + mouse primary; post-launch revisit |
| **Platform** | Console ports (all) | Post-launch only — controller-first interface requires full rethink |
| **Platform** | 4K resolution | Resolution scaling post-launch; 1440p is design target |
| **Platform** | VR | Not planned |
| **Content** | Magic / Elemental system | Deferred indefinitely — goes in after Epic 7 if sim architecture confirms readiness |
| **Content** | Ranged / charisma archetype | Epic 7 — after melee is fully validated |
| **Content** | Full character visual system (blend shapes, all signal layers) | Epic 7 |
| **Content** | Full procedural world generation (all region types) | Epic 7 |
| **Content** | Stems-based adaptive audio (full system) | Epic 7 |
| **Content** | Structured Observer Entry / onboarding | Epic 8 — built last |
| **Economy** | Non-food resources (tools, wood, luxury goods) | Post-prototype |
| **Economy** | Full Tier 2/3 demand curves | Post-prototype |
| **Economy** | Wartime vs. peacetime economic dynamics | Post-prototype |
| **Economy** | Trade route infrastructure | Post-prototype |
| **Economy** | Currency inflation mechanics | Post-prototype |
| **Economy** | Full lord AI (budget-pressure responses) | Post-prototype |
| **Audio** | Full voice acting / linguistic VO | Tonal fragments only — no linguistic content |
| **Localization** | Non-English languages | English only at launch |

### Deferred to Post-Launch

- Console ports and controller-first UI redesign
- Mod support and Steam Workshop
- Magic / Elemental system (requires confirmed sim architecture readiness)
- 4K resolution support
- Additional language localization

---

## Assumptions and Dependencies

### Key Assumptions

| Assumption | Risk if Wrong |
|---|---|
| **Solo dev capacity** — timeline is defined by one person's throughput; no team sprint to absorb scope creep | Scope must be cut ruthlessly if milestones slip; no parallel tracks available |
| **GDScript sufficient for simulation layer** — C# only if a specific function becomes a *measured* bottleneck | If sim performance degrades beyond GDScript's ceiling, a partial C# rewrite mid-project is expensive but scoped |
| **Godot 4.x remains stable** — building on Godot LTS; engine regressions are a known risk with any engine | Pin Godot version at project start; upgrade only on a branch with full regression test |
| **Emergence is provable at minimum fidelity** — the entire build order rests on Epic 1 delivering provable emergence; if it doesn't, the design is wrong at the foundation | Epic 1 is the first hard gate; failure here triggers redesign before any further investment |
| **Hierarchy-driven sim is sufficient** — the top-down authority model (lords weekly, stewards daily) produces the desired emergence without individual NPC intelligence | Validated at Epic 1; if emergence requires per-NPC autonomy, architecture changes significantly |
| **Vertical slice validates the core loop** — the Epic 5 build will confirm the LISTEN → INFER → COMPOSE → DISRUPT loop is worth full production investment | If playtesters don't produce "smarter" responses, stop and redesign before Epic 6 |

### External Dependencies

| Dependency | Timing | Risk |
|---|---|---|
| **Outsource artists** (character archetypes, environment kit) | Production phase — after Epic 5 vertical slice validates the loop | Availability and style coherence; lock foundational artist first and derive style guide from their output |
| **Composer** (stems-based adaptive audio) | Epic 7 | Must be briefed on horizontal re-sequencing before engagement; a linear-scoring composer will fight the system |
| **Asset store / AI generation tools** | Prototype through vertical slice | Acceptable for non-production phases; replaced by commissioned art in Epic 7 |
| **Steam platform** | Launch | Standard Steamworks integration; achievement events instrumented from Epic 1 onward |
| **FMOD or Godot AudioStreamPlayer** | Epic 7 | Audio middleware decision before stems are commissioned |

### Risk Factors

1. **Art style coherence without a full-time art director.** Stylized 3D requires a consistent visual language across all archetypes. Mitigation: lock one foundational artist for first 3–4 archetypes; derive the style guide from their output before commissioning additional artists.
2. **Sim complexity outpacing GDScript performance.** The hierarchy-driven model mitigates this significantly, but deep-simulation scenarios may reveal bottlenecks. Mitigation: weekly sim tick time tracking; C# conversion at measured chokepoints only.
3. **Burn-in stability across seeds.** 90%+ stability target is demanding. Two failure modes to guard against: runaway accumulation (one actor monopolizes a resource) and oscillation without damping. Mitigation: stability threshold checks and moving-average price memory built into burn-in from day one.
4. **Signal legibility gap.** The core fantasy requires the world to be readable through behavior, not UI. If players consistently need UI to understand world state, the sim's behavioral expression is insufficient. Mitigation: every playtester session has a "describe a faction's disposition without checking UI" diagnostic.

---

## Document Information

**Document:** The King You Don't See — Game Design Document
**Version:** 1.1
**Created:** 2026-04-26
**Author:** Zach
**Status:** Complete

### Change Log

| Version | Date | Changes |
|---|---|---|
| 1.0 | 2026-04-27 | Initial GDD complete — all 14 steps |
| 1.1 | 2026-05-01 | Prototype overhaul: retargeted Epic 1 from emergence proof to "prove the loop" via tick + window + market spine. Added forward references to `prototype-build-spec.md`. Surgical edits to: Goal 2 (Project Goals), Development Build Order step 1, Architectural Prerequisites, Core Simulation Systems, Economic and Resource Loops, Window-and-Bus Simulation Model (replacing Hierarchy-Driven for prototype scope), SimClock signal names, Epic 1, Simulation Health Gates. Pillars, USPs, target audience, art/audio direction, and downstream epics unchanged. `supplement-prototype-gaps.md` and `planning-artifacts/godot-rewrite-plan.md` marked superseded for prototype scope (preserved as historical/future-state reference). |
