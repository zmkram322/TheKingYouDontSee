# The King You Don't See — Development Epics

## Epic Overview

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

---

## Recommended Sequence

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

## Epic 1: Sim Proof

### Goal
Prove emergence exists at minimum fidelity before a single line of player-facing code is written.

### Scope

**Includes:**
- SimClock with `week_tick` and `day_tick` signals
- Burn-in pass (headless, regional fidelity)
- Economic circular flow (grain → market → coin → wages → food → productivity → grain)
- Needs hierarchy (Tier 1 only — food)
- Worker model (wages, productivity, hunger strike trigger)
- Market clearing (weekly cadence, binary search price clearing)
- Lord tax (flat rate, coin sink)
- Simulation telemetry / metrics layer (burn-in monitoring, mid-run observability)

**Excludes:**
- Player character, rendered world, art, audio, UI, player input
- Second resource type
- Full three-tier fidelity (stub only)
- Regional or distant fidelity (stub only)
- Influence system, ownership system

### Dependencies
None. Ground zero.

### Deliverable
Load the game, walk away five minutes, come back, and the world has moved. All five emergence behaviors observable in unsupervised simulation run. Developer can read sim telemetry logs and trace a famine cascade end-to-end.

### Emergence Validation Targets
1. **Famine cascade** — bad harvest → price rise → hunger debuff → productivity loss → smaller next harvest → spiral
2. **Labor drain** — wage differential causes worker migration, collapsing supply at origin farms
3. **Merchant margin capture** — merchant protecting margin converts supply shortage into price spike independent of production collapse
4. **Hunger strike contagion** — one farm's strike raises prices at neighboring farms, triggering further strikes
5. **Black market emergence** — when official prices exceed affordable thresholds, shadow transactions emerge

### Stories
- As a developer, I can run a simulation with 3 actors and 1 resource for 5 minutes and observe emergent price movement I didn't hardcode
- As a developer, I can observe a famine cascade traceable end-to-end in simulation logs
- As a developer, I can run 10+ world seeds and confirm 90%+ reach stable burn-in equilibrium
- As a developer, I can observe all 5 emergence behaviors occurring without developer-triggered input
- As a developer, I can observe the circular flow completing 4+ weekly cycles without intervention

---

## Epic 2: The Living World

### Goal
A full-fidelity simulation the developer can observe, stress-test, and diagnose — the complete engine before any player touches it.

### Scope

**Includes:**
- Full SimClock (all signal types: `week_tick`, `day_tick`, `event_interrupt`)
- Three-tier fidelity system (Near / Regional / Distant, including fidelity tier manager)
- Hierarchy-driven model (lord weekly decisions → lower lord daily execution → event interrupts propagate up)
- `SimEvent` queue with configurable drain cap
- Burn-in with full observability (metrics layer active during burn-in, not just final snapshot)
- Fidelity transition policy (Near ↔ Regional, within 5s load budget)
- Multi-market dynamics (at least 2 markets, consumer travel decision)
- ReadoutMapper initial version (data pipeline only — sim state → VisualStateDescriptor, no visual output yet)
- Save/serialize architecture foundation (not player-facing yet)

**Excludes:**
- Player character, rendered world, art, audio, player-facing UI
- Influence system, ownership system

### Dependencies
Epic 1 — emergence must be proven before the full engine is built on top of it.

### Deliverable
Developer can view real-time telemetry during burn-in, confirm lord hierarchy making decisions at correct cadences, observe actors transitioning between fidelity tiers without state loss, and query the ReadoutMapper for any actor's current state descriptor. 90%+ of seeds produce stable burn-in across both markets.

### Stories
- As a developer, I can view sim telemetry during burn-in so instability is diagnosable before player arrival
- As a developer, I can trigger a world seed and observe lord decisions firing at weekly cadence in logs
- As a developer, I can observe actors transitioning between fidelity tiers without state corruption
- As a developer, I can observe regional aggregate floats updating correctly from actor-level sim state
- As a developer, I can query the ReadoutMapper for any actor's VisualStateDescriptor and verify it reflects sim state
- As a developer, I can observe multi-market arbitrage occurring when price differential exceeds travel cost

---

## Epic 3: Eyes Open

### Goal
Give the player the LISTEN verb in complete form — the world is watchable and readable before any action is taken.

### Scope

**Includes:**
- Player character (movement, third-person navigation)
- Greet + Question social verbs (proximity-triggered, returns real sim-state information)
- Information log (queryable record of what the player has learned, when, from whom)
- ReadoutMapper connected to visual output (character visual system minimum viable — silhouette reads role, color temperature reads needs tier)
- Zone aggregate lighting (minimum viable — warm/cool environmental shift)
- Procedural template kit (one region minimum — town square, market stalls, roads, residences)
- Bulletin boards / town criers (confirm what active traversal surfaces)

**Excludes:**
- Combat, ownership mechanics, influence system
- Full art / audio, second region
- Full character visual system, blend shapes

### Dependencies
Epic 2 — the sim must be running and healthy; you're observing real state, not a placeholder.

### Deliverable
A player can walk through a village, read NPC needs tier visually before speaking, ask questions that return information reflecting actual sim state, and begin building a mental model of the economy. A stressed worker looks different from a prosperous merchant at a glance.

### Stories
- As a player, I can walk up to an NPC and greet them to establish social contact
- As a player, I can question an NPC and receive information that reflects actual sim state
- As a player, I can visually distinguish a hungry farmer from a prosperous merchant at a glance without opening a menu
- As a player, I can build an information log of what I've learned and where I learned it
- As a player, I can read a village's economic health from the lighting and crowd color temperature before speaking to anyone
- As a developer, I can confirm the information log reflects genuine sim state, not scripted dialogue

---

## Epic 4: Hit Something

### Goal
Validate the active layer — prove physical agency in the simulation and that DISRUPT writes to world state.

### Scope

**Includes:**
- Melee combat (full system: expressive chains, dodge, block/parry, clean escape)
- Fight-or-flight adrenaline system (vignette, movement behavior unlocks, injury-as-cost)
- Injury persistence (wounds heal over time, write to social sim state — NPCs react to visibly injured player)
- NPC state write-back (defeated actors carry depressed stats or leave area)
- Fidelity transition system (Near zone inflation on player approach)
- Information-driven inter-region navigation (follow a price differential, a rumor, a consequence)

**Excludes:**
- Ranged / charisma archetype, magic / elemental
- Ownership mechanics, influence system

### Dependencies
Epic 3 — need a populated, readable world to fight in and the information system to navigate between regions.

### Deliverable
Player can navigate a region, engage in melee, sustain an injury with real costs, execute a clean escape from an unwinnable fight, and move to a second region by following information. Developer can observe sim logs showing the world reacting to the combat disruption.

### Stories
- As a player, I can engage in melee combat and experience responsive, expressive chains that feel satisfying
- As a player, I can sustain an injury that persists and reduces my capability so consequences are real
- As a player, I can recognize an unwinnable fight and execute a clean escape that feels as satisfying as winning
- As a player, I can observe NPCs treating me differently when I'm visibly injured
- As a player, I can navigate between regions by following a specific name, price, or complaint — not a waypoint
- As a developer, I can observe sim logs confirming a player-combat event wrote to NPC and regional simulation state

---

## Epic 5: Own Something

### Goal
Give the player economic stakes — something to lose, something to protect, something that makes the simulation personal.

### Scope

**Includes:**
- Transact/Control mechanics (trade, broker, withhold as first-class mechanic)
- Wage contract system (player can be employed, can employ others)
- Land purchase (player becomes landowner — directs labor, collects revenue, has something to lose)
- First market stall (player controls distribution, influences local price)
- First enterprise milestone (simulation treats player as an organization)
- Save/serialize (player-facing — must save before ownership means anything)
- Management UI (minimal — mirror ownership state: what I own, what it earns, what it costs)

**Excludes:**
- Influence system, full world generation, full management UI, ranged/charisma

### Dependencies
Epics 1–3 (sim + observation — ownership is meaningless without a readable world to own things in). Epic 4 useful but not strictly required.

### Deliverable
Player can sign a wage contract, accumulate coin, purchase land, open a market stall, and observe the simulation treating them as a landowner with different interaction classes available. Player can withhold supply and observe downstream price effects. Player can save and return to a world that has continued without them.

**Vertical slice milestone:** This is the first build a blind playtester sees. The LISTEN → INFER → COMPOSE → DISRUPT loop is playable end-to-end. No production art, no adaptive audio, no onboarding.

### Stories
- As a player, I can sign a wage contract and begin participating in the economic circular flow
- As a player, I can accumulate coin and purchase land so I become a landowner with something to lose
- As a player, I can open a market stall and observe how controlling distribution affects local prices
- As a player, I can withhold a resource from market and observe the downstream simulation effect
- As a player, I can save my game and return to a world that has moved without me
- As a developer, I can confirm each ownership milestone changes which NPC interaction classes are available to the player

---

## Epic 6: Pull the Strings

### Goal
The world responds to who the player is becoming — soft power works, and it is meaningfully different from economic power.

### Scope

**Includes:**
- Two-axis influence model (direct: coin-based contracts/employees; indirect: stats/exp-based reputation and capability)
- Threshold listener layer (designer-authored response curves — not pure emergence; thresholds observable in sim telemetry)
- Legitimate vs shadow path fork (same sim systems, different strategic and reputational texture)
- Influence reconciliation at period boundaries (two axes read from each other, reconcile at tick boundaries — not live-linked)
- Multi-market dynamics tied to influence reach (influence has geographic texture)

**Excludes:**
- Full world generation, final art/audio, onboarding

### Dependencies
Epic 5. Influence needs ownership to exist — there must be something concrete for influence to operate on and something the player cares about losing before soft power has stakes.

**Design note:** Ownership is the accounting layer (balance sheet, ROI). Influence is the emotional layer — harder to tune, requires agent behavioral variety to feel meaningful. Built after ownership is stable so influence has a real floor to stand on.

### Deliverable
Player can cross an influence threshold without a notification and observe changed NPC behavior. A corrupt official approaches them unprompted. A merchant offers unsolicited information. The world treats them as someone. Player can pursue either the legitimate or shadow path and observe the simulation generating appropriate allies and adversaries for whoever they're becoming.

### Stories
- As a player, I can cross an influence threshold without a notification and discover the change by observing NPC behavior
- As a player, I can build legitimate influence through investment and observe the simulation generating allies appropriate to that path
- As a player, I can build shadow influence through infamy and observe a different but equally real consequence set
- As a player, I can feel my indirect influence growing through how NPCs treat me, before I see it in any stat screen
- As a developer, I can observe influence threshold crossings in sim telemetry so the response curve is tunable
- As a developer, I can confirm the two influence axes reconcile at period boundaries without mid-tick feedback loops

---

## Epic 7: A World to Play In

### Goal
A full world that can be generated, played across multiple regions, and experienced with complete visual and audio simulation readout.

### Scope

**Includes:**
- Full procedural template assembly (all region types)
- Region generation (resource profile × lord behavioral archetype producing emergent regional character)
- Multi-region navigation (full information-driven system)
- Full management UI (mirror all sim state the player has ownership stake in)
- Ranged/charisma archetype (second combat posture — manage the gap, project force without direct confrontation)
- Full character visual system (all three signal layers + blend shapes)
- Zone aggregate lighting (full regional health readout)
- Stems-based adaptive audio (full horizontal re-sequencing system, all state variables wired)
- Vocal fragment sets per archetype (tonal only — no linguistic content)

**Excludes:**
- Magic / elemental (deferred)
- Onboarding

### Dependencies
Epics 1–6. Production epic — art, audio, and full world commissioned after the core loop is proven worth investing in.

### Deliverable
Player can generate a new world seed, play across multiple regions with distinct economic and political characters, use charisma as an alternative to melee, and experience the simulation readout through art and audio before opening any UI. Developer can confirm all five emergence behaviors remain observable with full production systems integrated.

### Stories
- As a player, I can generate a new world and experience regions with meaningfully distinct economic and political characters
- As a player, I can hear the score shift before I understand what's about to happen so audio is a simulation instrument
- As a player, I can read a crowd's collective economic health from zone lighting without inspecting individual NPCs
- As a player, I can use a charisma-based approach as an alternative to melee when social leverage matters more than force
- As a player, I can read a character's needs tier and role at a glance through visual design alone, without UI
- As a developer, I can confirm all five emergence behaviors remain observable after full world and art systems are integrated

---

## Epic 8: The Door Opens *(built last)*

### Goal
Make the first five minutes feel inevitable for a stranger — without a tutorial popup.

### Scope

**Includes:**
- Contextual First-Touch Layer (every system surface has a first-touch moment — fires once, never again; NPC line or journal entry that surfaces system logic; full system audit required before ship)
- Structured Observer Entry (outsider start with plausible reason to be there: debt, letter, newcomer; one NPC, one task, one system — 5–10 min contained sequence, then released into full sim)
- Authored grammar anchor (one guaranteed early interaction: one lord, one visible want, visibly getting it or not — establishes the game's grammar before emergence takes over)
- Observer Entry is skippable from second playthrough

**Excludes:**
- Magic / elemental (deferred indefinitely)

### Dependencies
Everything. Built after all systems are stable — you cannot design onboarding until you know what the game actually is.

### Deliverable
A blind playtester can start the game and reach functional footing within ten minutes without a tutorial popup or external explanation. They encounter one lord wanting something visibly before emergence takes over. On second playthrough, experienced players skip directly to the full simulation.

### Stories
- As a new player, I can start as an outsider with a reason to be there and reach functional footing within 10 minutes
- As a new player, I can encounter one authored interaction with a lord that shows me what lords want before emergence takes over
- As a returning player, I can skip the Observer Entry on second playthrough and start directly in the simulation
- As a player, I can encounter a first-touch moment for each system surface exactly once — it explains the system and never fires again
- As a developer, I can confirm every system has been audited for a first-touch moment before ship

---

## Deferred

**Magic / Elemental** — Outcome-state model (destroyed, incapacitated, disrupted, revealed). High expressive surface cost, low architectural cost *if* the sim is built correctly from day one. Deferred until Epic 7 is complete and the simulation state architecture is confirmed ready to accept outcome writes. Not planned at GDD stage.
