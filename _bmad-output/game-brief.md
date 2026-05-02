---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments: []
documentCounts:
  brainstorming: 0
  research: 0
  notes: 0
workflowType: 'game-brief'
lastStep: 0
project_name: 'TheKingYouDontSee'
user_name: 'Zach'
date: '2026-04-26'
game_name: 'The King You Don''t See'
---

# Game Brief: The King You Don't See

**Date:** 2026-04-26
**Author:** Zach
**Status:** Draft for GDD Development

---

## Executive Summary

The King You Don't See is a medieval fantasy society simulation RPG where every actor from peasant to king pursues layered needs through indirect systems, and the player is the most interesting variable in it.

**Target Audience:** Players who want to participate and act in a living world — not be guided through it. Ages 14+, accessible by default with depth unlockable for those who want it. The Kenshi player who wanted an accessible surface. The RimWorld player who wanted to be embodied in the world. The CK3 player who wanted to actually be the character.

**Core Pillars:** The World Doesn't Wait · Consequence Is Structural, Not Scripted · Power Is Earned Through Understanding · Surface and Depth Are Both Real

**Key Differentiators:** The simulation is the content, not the container. Influence changes what kind of actor you are — not just how strong. Needs hierarchy governs everyone equally. The surface layer earns patience for the depth layer.

**Platform:** PC (Steam) · Engine: Godot 3D · Solo developer, pet project

**Success Vision:** A playtester puts the game down mid-session, stares at the ceiling, and thinks about what they're going to do next. They tell their friend: *"I figured out what was actually happening."* That's the game working.

**One sentence:** This is the only game where the thing you're proud of is what you understood — not what you survived.

---

## Game Vision

### Core Concept

A medieval fantasy society simulation where every actor from peasant to king pursues layered needs through indirect systems, and the player is the most interesting variable in it.

### Elevator Pitch

Everyone needs something — farmers need grain, lords need gold, kings need legitimacy — and in this medieval fantasy RPG you rise from hungry nobody to invisible kingmaker by understanding what people need before they do, controlling the markets that supply it, building power and influence, and being dangerous enough to protect it or to watch the world burn and collapse under your careful orchestration.

### Vision Statement

Most games that promise freedom deliver a corridor with wider walls. Most games that promise consequences deliver a cutscene.

The King You Don't See is built on a different contract.

The world runs whether you're watching or not. Farmers hunger, markets shift, lords scheme, and power vacuums fill themselves — driven by needs, greed, fear, and ambition that exist independently of the player. You don't trigger this world. You enter it mid-motion and start making ripples.

The feeling we're designing toward is the moment a player realizes something they did three hours ago just caused a famine — and they're not sure if they should fix it or exploit it. That tension between agency and consequence, between power and responsibility, is where the game lives.

There is no set path because path implies destination. The player who becomes a shadow merchant controlling grain supplies, the player who builds a warrior legend and attracts a retinue, the player who quietly becomes the most dangerous information broker in three kingdoms — they're all playing the same game, reading the same systems, and arriving somewhere entirely their own.

What makes this matter is that the player's intelligence is respected completely. The world doesn't explain itself. It rewards observation, patience, and genuine understanding of how human needs drive human behavior. When you figure something out — when you see the signal before anyone else does — it feels real because the system is real.

The goal is for someone to put down the controller mid-crisis, stare at the ceiling, and think about what they're going to do next.

That's the game. That's the feeling. That's why it's worth building.

---

## Target Market

### Primary Audience

Players who want to participate and act in a living world — not be guided through it. They seek emergent consequences over authored stories, genuine agency to experiment and plan, and the satisfaction of feeling their own cleverness rewarded by systems that actually respond. They engage with games as intelligent actors, not as audiences.

**Demographics:**
Ages 14+, accessible by default with depth unlockable for those who want it (Factorio model). Concentration in 18–35 adults, particularly in North America and Western Europe. Not hardcore in the traditional sense — not grinding-tolerant — but willing to invest time when that time is spent orchestrating, not waiting.

**Gaming Preferences:**
New to the genre but not to thoughtful play. Comfortable with indirect systems and self-directed goals. Prefer long sessions driven by genuine engagement ("I want to see what happens next") over sessions driven by obligation ("I need to complete this quest").

**Motivations:**
The living world pull — wanting to be an actor in a system that runs without them, with real stakes and real ripple effects. The emergent story pull — wanting to watch a narrative take shape from their decisions and feel awe at what the systems created. The cleverness pull — the reward of seeing a signal before anyone else does and acting on it.

### Secondary Audience

**Immersive sim fans** (Morrowind, Kenshi, Dwarf Fortress adventurer mode) — already fluent in "world runs without you, figure it out" design, but hungry for a more accessible surface experience that doesn't require them to fight the interface to find the depth.

**Sandbox survival players** — comfortable with indirect loops and self-directed goals, drawn to the medieval fantasy setting and the promise of consequence that actually lands.

Both secondary audiences share the primary's frustration with authored consequence and are actively looking for something that respects their intelligence at the systems level.

### Market Context

The RPG market sits at $23B (2024), projected to reach $316B by 2032 at 16.2% CAGR. The King You Don't See doesn't need a mainstream slice — it needs the specific, vocal, evangelical segment that has been waiting for a game that treats consequence as a system rather than a script.

**Similar Successful Games:**
- **RimWorld** — proves massive audience for emergent-consequence, player-generated story design
- **Crusader Kings 3** — proves political simulation with needs-driven NPC behavior resonates commercially at scale
- **Kenshi / Dwarf Fortress / Morrowind** — prove the immersive sim lineage; demonstrate loyalty depth but also surface accessibility as an unsolved problem
- **Baldur's Gate 3** — proves player-intelligence-respecting design (systems you can genuinely break creatively) produces cultural moments, not just sales
- The through-line: players who find these games become evangelical. Smaller audience than mainstream RPGs, but dramatically more loyal and vocal.

**Market Opportunity:**
The market currently offers two unsatisfying options: authored-consequence games (wide freedom, ultimately cosmetic outcomes) or pure simulation games (real consequence, inaccessible surface). Nobody has successfully bridged accessible, kinetic surface experience with genuinely real consequence simulation in a medieval fantasy setting. That is the gap. The King You Don't See is the bridge.

Three convergent forces make now the right moment: AI tooling for dynamic systems and asset generation is maturing rapidly; studios prioritizing player-driven narratives are capturing measurably higher engagement; and culturally, player frustration with corridor-with-wider-walls design is loud, growing, and actively looking for something that delivers.

**Real Competition:**
Not Elden Ring or The Witcher. The target player bounced off Kenshi's inaccessibility, found RimWorld too abstract, loved Morrowind's openness but wanted more systemic depth, and plays Crusader Kings 3 wishing they could embody a character. That player is actively looking for this game. The real competition is their time — and their skepticism, earned by being promised real consequence before.

---

## Game Fundamentals

### Core Gameplay Pillars

**1. The World Doesn't Wait**
The simulation runs independently of the player. Markets shift, lords scheme, farmers hunger, power vacuums fill. Every system — combat, influence, economy, needs — exists as part of a living world that was in motion before the player arrived and continues without them. *If a feature requires the player's presence to function, it doesn't belong.*

**2. Consequence Is Structural, Not Scripted**
Every action writes to the simulation. Killing a delivery agent cascades into famine. Cornering a market destabilizes a region. There are no authored consequence cutscenes — only systems responding to disturbance. *If a consequence has to be written by hand, the system isn't deep enough yet.*

**3. Power Is Earned Through Understanding**
The player gets stronger by reading the world more accurately — not by grinding levels. Influence, information, and timing beat raw force. The game respects player intelligence completely and rewards observation over button mashing. *If a feature can be brute-forced without understanding, it undermines this pillar.*

**4. Surface and Depth Are Both Real**
Kinetic, expressive combat and movement give players a joyful surface to inhabit while the simulation runs underneath. Neither layer is decoration. Combat isn't a break from the real game — it's a different register of the same game. *If a feature serves only one layer without connecting to the other, reconsider it.*

**Pillar Priority:** When pillars conflict, prioritize:
1. Consequence Is Structural (the contract the entire vision rests on — break this and everything collapses)
2. Power Is Earned Through Understanding (understanding beats reflex when they conflict)
3. Pillars 1 and 2 are the same idea at different scales and should never conflict

---

### The Two-Layer Design Framework

The game operates on two layers that are the same system at different timescales — not parallel systems that coexist.

| | Simulation Layer | Active Layer |
|---|---|---|
| **Speed** | Slow, systemic | Fast, kinetic |
| **Directness** | Indirect, persistent | Direct, immediate |
| **Presence** | World runs without you | Requires your presence |
| **Consequence** | Compounds over time | Instant |
| **Verbs** | Indirect (influence, withhold) | Direct (strike, arrive) |
| **Satisfaction** | Delayed | Immediate |
| **Domain** | Markets, needs, information | Combat, movement, disruption |

**The relationship:** Active Layer = the HOW. Simulation Layer = the SO WHAT. Combat is how you create a power vacuum. The simulation is what fills it. Trading is how you move resources. The simulation is what that does to regional stability over time. Physical presence is how you generate information. The simulation is what that information reveals about underlying world state.

**The Feature Test** *(design axiom — every mechanic goes through this)*:
- Does it feel good in the moment? → Active layer valid
- Does it matter tomorrow? → Simulation layer valid
- If only one answer is yes → incomplete feature

**The ideal session:** Ends with the player putting down the controller mid-crisis — still in the active layer emotionally — but staring at the ceiling planning their next simulation move. That's both layers holding simultaneously.

---

### Primary Mechanics

**Observe / Read** — Listen, watch, infer, investigate. The most repeated action is noticing something is wrong before anyone else does.

**Transact / Control** — Trade, broker, manipulate, spend influence, withhold, expose. Withhold is a first-class mechanic — letting a crisis deepen on purpose is a power move, not an absence of action.

**Act Directly** — Move, strike, chain, disrupt, arrive. Physical presence is never neutral — the player's body is a variable the simulation reads. *Arrive* is the most consequential verb in the game.

**Position / Plan** — Compose, time, cultivate, assign downward, negotiate laterally, position upward. As influence grows, players stop doing and start directing — reach multiplies beyond physical presence. The logical trap lives here: arranging conditions so another actor's own utility curve walks them into your position without a fight.

**Direct Action as Influence Tool** — Combat and physical disruption are not separate from the influence layer. They accelerate world state, force reveals, create vacuums, and demonstrate capability as lateral signal to peers.

**Core Loop:** LISTEN → INFER → COMPOSE → DISRUPT
The same four verbs at every scale. A fight, a market play, a long political trap — same loop, different timescale.

**The High Influence Fantasy:** Causing everything while appearing to do nothing. Like any good leader, direct involvement is reserved for where the risk is highest — arriving precisely when needed, doing the one critical thing, then disappearing. The invisible hand is not passive. It is selective.

**Three Satisfaction Peaks:**
- *Flow peak* — combat clicking into a chain (immediate)
- *Inference peak* — the world suddenly becoming legible (medium-term)
- *Consequence peak* — watching something composed three hours ago land (rare, delayed, the one players describe to their friends)

---

### Simulation Architecture

The simulation runs at three fidelity tiers scaled by player proximity and influence class:

| Tier | Scope | Fidelity |
|---|---|---|
| **Near Player** | Local zone | Full actor simulation, every tick |
| **Regional** | Surrounding regions | Aggregate floats only, heartbeat-driven |
| **Distant** | Far territories | Statistical drift, no individual actors — outcomes reconstructed on player arrival |

**Minimum viable emergence threshold:** Three actors, three resources, one scarcity driver, five rules. The simulation prototype must demonstrate genuine emergence at this configuration before any additional systems are built on top of it. A spreadsheet that breathes before it becomes a game.

**Three programming modes:**
1. Raw simulation (world state running without rendering)
2. NPC situations that play out and record outcomes (regional resolution)
3. Individual interaction and resultant outcome (active layer, fully rendered)

*Open specification needed:* The reconstruction contract when transitioning from REGIONAL to NEAR — whether aggregate state resolves deterministically or probabilistically has architectural implications for save states and player-exploitable boundary conditions.

---

### Violence Ceiling

Violence is not blocked — it is taxed by the simulation.

Direct action writes to world state immediately and visibly. Visibility raises detection risk, destabilizes regional trust floats, and accelerates instability cascades. A player who solves everything through violence accumulates instability faster than any single actor can absorb — eventually producing the power vacuums and coalition responses that make their position untenable.

| Approach | Instability Rate | Outcome |
|---|---|---|
| Low violence (surgical, targeted) | Slow accumulation | Sustainable high-influence position |
| High violence (fast, visible) | Fast accumulation | Simulation-generated adversaries; position becomes unsustainable |

Violence works. It just works expensively. A player who fights their way to kingmaker arrives there with a destabilized region, exhausted resources, and a simulation-generated coalition of threatened actors. They won the battle and inherited the consequences. Understanding remains strictly superior because it produces outcomes without the instability tax — and that asymmetry is systemic, not aspirational.

*Instability accumulation must be legible through diegetic channels before coalition response arrives — or the ceiling reads as unfair even when mechanically correct.*

---

### Diegetic Legibility Architecture

The causal arrow is never given to the player — it is reconstructable by an attentive player through triangulation across channels. The inferential leap is the reward, not the information itself.

**Four legibility channels:**
- **Audio** — tension, heartbeat, ambient shift
- **NPC Dialogue** — merchants complain, guards cite reasons, lords blame correctly or incorrectly
- **Behavior** — caravans stop running, stalls close early, routines disrupted
- **Visible State** — market prices shift, NPC patterns change

**Ship criterion:** Every simulation system must expose its own causality through at least two diegetic channels before it ships. Channels must be epistemically independent — removing either one should leave the inference still possible but harder, not impossible. Two channels that point at the same thing the same way do not satisfy the spirit of this constraint.

**NPC content pipeline:** Build economic loops and hierarchy-of-needs systems first. High-influence actors read simulation metadata and drive macro decisions for regions. NPC observations are procedurally generated from simulation state — not hand-authored at scale. Tight data structures feeding decision-making engines in motion.

---

### Player Experience Goals

**Early game — the cog:** Players feel like part of a much larger machine. Low-level jobs, survival needs, combat scaled to individual stakes. Taking orders, meeting basic needs, belonging to a broader organization. The world teaches itself through natural progression — harvest crop, buy grain, join a caravan — achievements that are tutorials in disguise.

**Mid game — the question:** As influence grows, players must decide how to direct it. Exploration through low-stakes experimentation: challenge a merchant, go rogue, try a bandit camp (if too poor, the bandits won't even bother attacking — the simulation reads you accurately). Each rung of the influence ladder expands the scale of action and consequence. Mistakes cascade. Other agents get involved. Take advantage.

**Late game — the weight:** High influence carries real responsibility. Missteps don't just hurt the player — they hurt the world. Heavy weighs the crown must be seen and felt. The game mirrors the real-world truth that power at scale means living with the consequences of your decisions at scale.

**Teaching delegation:** Designed so players arrive at it naturally — offhand comments from high-influence NPCs, achievements that require delegation, explicit visible rewards for stepping back. The game does not force it. Success teaches it. A player who discovers they can delegate and it works — that's the moment.

**Emotional Journey:** Curiosity and survival → experimentation and confidence → strategic depth and consequence → the weight of having shaped something larger than yourself.

**What makes it meaningful:** Players leave having genuinely practiced reading systems, anticipating consequences, and understanding how human needs drive behavior. The ceiling-stare moment — putting down the controller mid-crisis to think — is the signature emotional experience.

---

### Open Design Questions

*Carried forward for resolution in GDD phase:*

1. **The noticing moment** — What is the specific first human beat where a player catches the simulation doing something they can use? Not a mechanic — the actual moment. Design backward from this once identified.
2. **Transition seam specification** — Exact reconstruction contract when moving from REGIONAL to NEAR fidelity tier.
3. **Channel independence test** — Formal validation that paired diegetic channels are epistemically independent, not redundant.

---

## Scope and Constraints

### Target Platforms

**Primary:** PC (Steam)
Natural home for the target audience — the RimWorld, Kenshi, CK3, Morrowind players who will find and evangelize this game live on PC. Keyboard and mouse give full access to the simulation depth without interface compromise.

**Secondary:** Console (post-launch consideration)
Not a launch target. Controller-first design would require interface rethinking for the simulation layer. Revisit after PC release validates the core loop.

### Development Timeline

Pet project cadence — no fixed ship date. Milestone-driven rather than calendar-driven. The simulation prototype (spreadsheet that breathes) is the first real milestone; everything else is downstream of proving emergence at minimum fidelity.

### Budget Considerations

Self-funded pet project. No external funding, no runway pressure — which is a creative advantage (no publisher constraints on the vision) and a pacing reality (development moves at personal bandwidth).

**In-house:** Core simulation systems, game logic, Godot implementation, design, systems architecture.

**Outsource when ready:** Combat feel and polish, art assets (characters, environments, UI), audio and music. These are production-phase costs — not blockers for the prototype and simulation-first build phases.

**Budget discipline:** Scope must be achievable solo through prototype and vertical slice. Outsource costs are deferred until the core loop is proven and worth investing in.

### Team Resources

**Solo developer** with intermediate game dev experience (Godot, general development). Full design, systems, and implementation ownership.

**Skill Gaps:**
- Combat feel and animation polish (outsource)
- Art production at scale (outsource)
- Audio design and music composition (outsource)
- Procedural content pipeline engineering (steep learning curve — high priority internal skill to develop)

**Outsourcing strategy:** Keep outsourced work modular and late-stage. The simulation and systems architecture must be stable before committing art and audio spend. Combat polish is a production milestone, not a prototype requirement.

### Technical Constraints

**Engine:** Godot 3D

**Performance target:** 60fps is non-negotiable on the active layer (combat, movement). Simulation tick rate is independent — heartbeat-driven at regional level, statistical at distant level. The hot path cannot dip below 60 regardless of simulation complexity.

**Simulation performance:** The proximity-tiered architecture (near/regional/distant fidelity) is the core performance strategy. Full actor simulation only in the player's local zone. This must be proven in the prototype phase before any content is built on top of it.

### Scope Realities

This is an ambitious solo project. The simulation architecture designed — three fidelity tiers, diegetic legibility across four channels, procedural NPC content pipeline, influence hierarchy — is genuinely complex. The correct build order protects against over-scoping:

1. **Simulation prototype first** — three actors, three resources, one scarcity driver, five rules. Prove emergence before building anything else.
2. **Vertical slice second** — one region, the LISTEN → INFER → COMPOSE → DISRUPT loop playable end-to-end, no art.
3. **Production later** — art, audio, combat polish commissioned once the core loop is proven worth investing in.

---

## Reference Framework

### Inspiration Games

**Skyrim**
- Taking: Behavioral skill progression, the nobody-who-rises arc, the feeling that every path is visible from day one, a diegetic world that reacts to your presence
- Not Taking: Static world simulation, markets that don't move, politics that don't shift, consequence that resets. The world waiting for you is exactly what we're replacing.

**RimWorld**
- Taking: Emergent story from interconnected systems, player-generated meaning, the simulation producing narrative nobody authored, systems depth as the primary content
- Not Taking: Abstract overhead view, colony management framing, emotional distance from individual actors. We want embodiment — you're in the world, not above it.

**Crusader Kings 3**
- Taking: Influence accumulation as core progression, factional relationships with real stakes, competence and honesty as meaningful actor dimensions, the nobody-to-dynasty arc, lateral relationship management between peers
- Not Taking: The disembodied map-clicking interface, purely political abstraction, no physical presence in the world. CK3 is the simulation layer without the active layer. We're building both.

**Kingdom Come: Deliverance**
- Taking: Behavioral XP, NPC daily routines, layered reputation by demographic, condition-based social interactions requiring multiple ingredients, the weight of starting at the bottom of every hierarchy simultaneously
- Not Taking: Authored main storyline that constrains everything, static macro world state, decorative economy that doesn't respond to player behavior at scale, punishing opaque combat. KCD proves the feel works. We're building the living macro layer it was missing.

**Combat Reference: Fight-or-Flight System** *(philosophy, not power fantasy)*
- Taking: Snappy, expressive, readable combat. An adrenaline-driven fight-or-flight bridge between the active and simulation layers. The emotional contract: winnable fights flow, unwinnable fights are immediately legible — adrenaline spikes, movement behaviors unlock (speed, jump height, gap-closing), and a clean escape feels as satisfying as a clean win. The player who reads a situation, recognizes they're outmatched, and executes a clean escape used the system correctly.
- Not Taking: Power fantasy. Artificial equalizing. Batman-in-a-crowd domination. Combat as primary progression.

| Encounter Type | Feel |
|---|---|
| Winnable | Snappy, fun, expressive — combat as reward |
| Unwinnable | Immediate powerlessness, adrenaline, fight-or-flight unlocks, escape is the correct move and feels like one |

**Identity Consequence Reference: Fable's Philosophy, Not Fable's Execution**
- Taking: Who you've become changes how the simulation runs around you — not just how it looks. Three layers working simultaneously: (1) Aesthetic — how the world looks different (clothing, body language, NPC expressions — present but not the point); (2) Behavioral — how NPCs make decisions differently (prices, information access, compliance thresholds, trust levels); (3) Political — how other influencers respond (threatened actors form coalitions, aligned actors offer resources, the simulation generates allies and enemies from your pattern, not from a script).
- Not Taking: Aesthetic-only identity reflection. Reputation as a single numerical axis. NPC memory so shallow that consequences don't propagate through the world.

*The test: can a player describe not just how the world looks different, but how it runs differently because of who they are. If they can't — we built Fable.*

---

### Competitive Analysis

**The four failure modes to stay alert to:**

*"Oh it's just another Kenshi"* — simulation without surface joy. Inaccessible entry, opaque systems, no kinetic release valve. Every system must have a diegetic feedback channel or it becomes this.

*"Oh it's just another Skyrim with spreadsheets"* — beautiful surface, hollow simulation. Markets that don't actually move. Consequences that reset. NPCs that are schedules wearing faces.

*"Oh it's just another management game"* — abstraction creeping upward until physical presence stops mattering. CK3 is brilliant and guilty of this.

*"Oh it's just another sandbox with nothing to do"* — freedom without generative pressure. The simulation must generate its own urgency or players drift and disengage.

**Competitor map:**

| Game | Simulation | Surface | Embodiment | Notes |
|---|---|---|---|---|
| Kenshi / Dwarf Fortress | ✓ | ✗ | Partial | Deep sim, hostile entry |
| Skyrim / KCD | ✗ | ✓ | ✓ | Surface feel, decorative sim |
| CK3 | ✓ | Partial | ✗ | Sim + politics, no physical presence |
| RimWorld | ✓ | ✗ | ✗ | Emergent systems, overhead abstraction |
| Outward | ✗ | ✓ | ✓ | Embodiment + surface, thin simulation |
| Mount & Blade: Bannerlord | Partial | Partial | ✓ | Closest to the white space; weaknesses: rough surface, thin NPC depth, no player-NPC equality |
| BG3 | ✗ | ✓ | ✓ | Not a competitor — market validation. Proved demand for immersive, consequential, embodied play at scale. |
| **The King You Don't See** | ✓ | ✓ | ✓ | All three, unified |

**Embodiment defined:** The player experiences consequences through a body subject to the same physical and social needs hierarchy as every other actor in the simulation. CK3 cannot claim this. Skyrim cannot claim this.

**Strategic vulnerability:** The honest risk is Paradox Interactive moving laterally — CK3 with a physical layer would fill the space with a AAA budget. The moat is not being first. It's building a community and design language so distinctive that the AAA version feels like a pale imitation. That's the Minecraft defense.

---

### Key Differentiators

**1. The simulation is the content, not the container.**
Most games use simulation as backdrop for authored content. Here, simulation is the content itself. The famine that emerges from your grain manipulation three sessions ago IS the story. Architectural, not cosmetic — cannot be patched into an existing game. Players feel this as: "the world feels alive" and "things I did last week still matter."

**2. Influence changes what kind of actor you are.**
Most RPGs make you stronger. This makes you categorically different. Low influence means direct verbs only. High influence means directing others, setting traps, causing outcomes while appearing to do nothing. The progression is a fundamental change in your relationship to the world — and that shift must be felt, not just simulated. Threshold experiences (a scene, a conversation, a door that opens differently) mark each categorical transition.

**3. Needs hierarchy governs everyone equally.**
Every actor from farmer to king runs the same needs-based decision system. The player is subject to the same logic as every NPC. Consequence feels fair rather than arbitrary — the world isn't punishing you, it's applying the same rules to everyone.

**4. The surface layer earns patience for the depth layer.**
Expressive, readable combat gives players a kinetic reason to stay in the world long enough to discover what the simulation is doing underneath. The bar: combat must never become friction — readable, responsive, satisfying at its own register.

**Real UVP — what the player tells their friend:**

*"I figured out what was actually happening."*

Not "I won a fight." Not "I completed a quest." The brag is an inference. The stories sound like:
- *"I didn't even have to touch him. I just made sure the right people found out."*
- *"I caused a famine. Not on purpose. Well — kind of on purpose by the end."*
- *"I showed up to that region and everything just... changed. Because they knew I was there."*
- *"I've been setting this up for three sessions and it's about to land."*

**One sentence:** This is the only game where the thing you're proud of is what you understood — not what you survived.

**The 11pm decision:** The player boots it up again because something is unresolved in the simulation. Not a quest marker — a situation. A play they set up that hasn't landed yet. A signal they noticed that they haven't traced to its source. The game doesn't pull them back with a notification. It pulls them back because they're still thinking about it.

---

## Content Framework

### World and Setting

Medieval fantasy — flavor sits between KCD's grit and playful stylization. Grounded enough that hunger and corruption feel real, expressive enough that the world invites experimentation rather than dread. Not grimdark. Not whimsical. The tone is **precarious normalcy** — a world that works until it doesn't, where systems are fragile and everyone knows it.

Three atmospheric layers running simultaneously:

| Layer | Description |
|---|---|
| **Economic Precarity** | Nobody is comfortable. Everyone is one bad harvest from a worse tier. |
| **Political Tension** | Authority is real but fragile. Legitimacy is always being negotiated, never assumed. |
| **Social Mistrust** | Information is unreliable. Loyalty is conditional. Everyone is reading everyone else. |

**Lore philosophy:** Systems-first, thin scaffolding only. The world doesn't need a creation myth — it needs a believable reason why grain is expensive, why the roads aren't safe, and why the lord and the merchant guild don't trust each other. Lore exists to make simulation conditions feel motivated, not to be read. The tension is systemic, not historical.

### Narrative Approach

No authored main arc. No chosen one framing. The minimal starting frame is purely situational — you arrive somewhere, you have nothing, the world is mid-motion. Why you're there is deliberately thin. The simulation will generate your actual story within the first hour.

World context is delivered through three channels exclusively:

**Environmental** — Architecture tells economic history. Abandoned buildings signal past crises. Granary size signals lord priorities. Road condition signals security investment.

**NPC Dialogue** — Gossip as world state readout. Merchants complain about prices. Guards cite reasons for tension. Farmers reference things that happened before you arrived.

**Readable Artifacts** — Notices, ledgers, correspondence that a literate player can find and interpret for system insight.

The player who pays attention reconstructs the world's recent history from signals. The player who doesn't still plays fine — they read the world more slowly. No content is gated behind lore comprehension.

The narrative the game is proudest of is the one the player generates and tells their friend at 11pm. Everything authored exists to make that story possible — not to compete with it.

### Content Volume

Simulation-first content model: systems and rules are the primary content, not authored scenes or quests. Content volume scales with simulation depth, not with writing throughput. A region with three factions, four resource types, and one scarcity driver contains more effective player content than a hundred hand-crafted quest lines.

---

## Art and Audio Direction

### Visual Style

Stylized low-poly with expressive proportions — closer to painterly illustration than photorealism. Characters read as archetypes at a glance. Visual design carries simulation information: NPC appearance shifts with their needs tier. A hungry farmer looks hungry. A corrupt lord who's been skimming looks comfortable in a way that's slightly off.

**Color palette as simulation readout** — regional temperature doubles as political temperature:

| World State | Palette |
|---|---|
| High stability | Warm, golden, saturated — life at normal speed |
| Low stability | Cooler, grayer, slightly too quiet or too loud |
| Player adrenaline | Vignette, saturation spike, world narrows and sharpens |
| Sleep deprived | Desaturated edges, softened contrast, slightly slow |

The art layer does simulation communication work before the UI layer does. Players read world state through color before they read it through numbers.

### Audio Style

**Diegetic first, score second.** The world sounds before it scores.

Market ambient audio reflects economic activity — busy markets sound busy, failing ones sound sparse and wrong. NPC conversation volume and tone reflects regional tension without words being distinguishable. The score responds to **world state**, not player action — music doesn't swell because you entered combat, it shifts because regional instability crossed a threshold.

Sound design does the heaviest legibility work:
- Adrenaline has a heartbeat
- Sleep deprivation has subtle audio degradation
- Market crashes have a sound before they have a UI indicator
- The player hears the simulation before they see it

**Voice acting scope:** Grunts, tones, and fragments — no full VO. NPCs vocalize emotionally but not linguistically. A suspicious merchant sounds suspicious. A frightened farmer sounds frightened. The player's brain fills in the words from context. Full VO would make the world feel authored. Tonal vocals make it feel inhabited.

### Production Approach

Art and audio are outsourced in production phase, deferred until simulation and core loop are proven. Style direction established early (for outsourcing briefs), execution late. Asset store and AI generation tools acceptable for prototype and vertical slice phases.

---

## Risk Assessment

### Key Risks (Priority Order)

**1. Causal Legibility** *(High impact, High difficulty)*
Players must feel the consequence chain without it being scripted. If the player can't draw the causal arrow from their action to the outcome, the core fantasy fails.

**2. Simulation Fidelity vs. Performance** *(High impact, High difficulty)*
A simulation too detailed runs at 12fps. A simulation too abstracted feels like a spreadsheet wearing a coat. Both are fatal.

**3. Inference Scaffolding** *(High impact, High difficulty)*
The game must make the world teach itself without hand-holding. The aha moment outsourced is the core fantasy lost.

**4. Combat Scope** *(Medium impact, High likelihood of scope creep)*
Combat doubles the "feel" workload. Easy to deprioritize until too late, easy to over-reference and chase an unbuildable bar.

**5. NPC Content Pipeline** *(High impact, Medium difficulty)*
Diegetic feedback requires NPCs to respond contextually to simulation state at scale. Hand-authoring this doesn't survive simulation complexity.

**6. Solo Bandwidth** *(Medium impact, Persistent)*
Pet project pace against an ambitious design. The risk is drifting into the wrong build order and spending months on the wrong layer.

### Technical Challenges

- Proximity-tier simulation architecture (near/regional/distant) must be proven before any content layer is built on top
- Fight-or-flight adrenaline system bridging active and simulation layers
- Procedural NPC content pipeline generating contextually responsive observations from simulation state
- Regional-to-local reconstruction contract (deterministic vs. probabilistic — implications for save states)

### Market Risks

- Player skepticism ("we've heard this promise before") — mitigated by early vertical slice footage showing actual emergent consequence
- AAA lateral entry (Paradox moving toward embodiment with a studio budget) — mitigated by community-first development and shipping before the window closes
- Steam discoverability — mitigated by the evangelical audience dynamic; this game's players become its marketers when the systems deliver

### Mitigation Strategies

1. **Causal legibility:** Every system exposes causality through at least two epistemically independent diegetic channels before it ships. Structural requirement, not a feature.
2. **Simulation performance:** Proximity-tier architecture with proven minimum emergence threshold (3 actors, 3 resources, 1 scarcity driver, 5 rules) before building anything on top.
3. **Inference scaffolding:** LISTEN → INFER loop prototyped in isolation first. 20-minute vertical slice, one village, one hidden problem, ten blind testers. If inference doesn't feel rewarding here, nothing else matters yet.
4. **Combat scope:** Built last. Outsource polish. Bar is testable: readable, responsive, never friction. Fight-or-flight as the architectural anchor.
5. **NPC pipeline:** Econ → metadata → decision engines → procedural observations. Build the data structures first; generate from state, not from scripts.
6. **Solo bandwidth:** Milestone-driven, not calendar-driven. Build order strictly enforced: simulation prototype → vertical slice → production. No art or audio spend until core loop proven.

---

## Success Criteria

### MVP Definition

One region. The LISTEN → INFER → COMPOSE → DISRUPT loop playable end-to-end. At least one influence tier transition felt by the player. At least one consequence that lands from an action taken earlier in the same session. No production art, no audio, no polish — just the simulation running and the loop working.

The MVP is not a vertical slice for a publisher. It's the first build where a blind playtester puts it down mid-session and is still thinking about it.

### Success Metrics

**Primary:** Playtest satisfaction — specifically, the presence of the designed emotional peaks occurring naturally without guidance:
- The inference peak: a playtester reconstructs a world state they weren't told about
- The consequence peak: a playtester connects an outcome to something they did earlier and reacts visibly
- The ceiling-stare: a playtester stops mid-session to think about their next move

**Secondary signals:** Playtesters describe their experience using inference language ("I figured out that...") rather than action language ("I killed X" or "I completed Y"). Playtesters ask to keep playing after the session ends.

Commercial metrics are secondary for a pet project. Wishlists and community are meaningful if and when a vertical slice is shareable — not a success criterion for prototype phase.

### Launch Goals

Ship a vertical slice that demonstrates the core loop to a small audience of target players (the Kenshi/RimWorld/CK3 crowd). Their reaction to the systems — not the art, not the production value — is the real launch signal.

---

## Next Steps

### Immediate Actions

1. **Build the simulation prototype** — 3 actors, 3 resources, 1 scarcity driver, 5 rules. Prove emergence before writing a line of game code. A spreadsheet that breathes.
2. **Validate the LISTEN → INFER loop in isolation** — one village, one hidden problem, ten blind testers. No quest markers, no prompts. Does inference feel rewarding? If yes, proceed. If no, fix this before everything else.
3. **Architect the proximity tiers** — near/regional/distant fidelity model established in Godot 3D before any content is built on top of it.
4. **Draft the GDD** — transform this brief into system specifications and design documents that can drive development decisions.

### Research Needs

- Godot 3D performance characteristics for agent-based simulation at regional scale
- Procedural dialogue generation approaches for simulation-state-responsive NPC speech
- Regional-to-local reconstruction contract (deterministic vs. probabilistic resolution)

### Open Questions

1. **The noticing moment** — what is the specific first human beat where a player catches the simulation doing something they can use? Design backward from this once identified.
2. **Influence tier thresholds** — what are the exact categorical transition points, and what does each feel like in the body of play?
3. **Transition seam specification** — exact reconstruction contract when moving from REGIONAL to NEAR fidelity.

---

## Appendices

### A. Research Summary

{{research_summary}}

### B. Stakeholder Input

{{stakeholder_input}}

### C. References

{{references}}

---

_This Game Brief serves as the foundational input for Game Design Document (GDD) creation._

_Next Steps: Use the `workflow gdd` command to create detailed game design documentation._
