# Hex Board — Influence Layer Seed

*Captured 2026-08-02. A piece-by-piece brainstorm between Zach, Claude, and Samus Shepard (`gds-agent-game-designer` persona), read against the locked `prd.md`. This document is a candidate input for a future PRD edit pass — same class as `pub-slice-leverage-seed.md` and `fable-spike-decisions.md` before it: **`binding: false`, not yet validated by a build or a party-mode roundtable.** Nothing here modifies the PRD. Where a decision references an FR, that FR already exists and is being reused, not proposed.*

## The core idea

Zach works bottom-up then switches to top-down: resources fundamentally drive the underlying economy, and a procedurally generated hex grid gives that economy a substrate. The pitch: the player runs around the land at ground level (the existing walked world, town/economy sim), and can zoom out to a hexagonal strategic board to drive the high-influence tiers of play — goal-setting from the top, which the existing Core Mechanical Model already specifies mechanically (cascade, FR45) but has no interface for yet.

Light inspiration, explicitly separated:
- **Civ 6** — the board as the UI for decisions too abstract to walk up to and LOOK at.
- **Catan** — resources and adjacency driving the economy (the bottom-up half of Zach's instinct).

This gives the two-tier world architecture note (far tier talks to local tier only through headline events, FR72) and the reach/power-as-eigenvector-centrality machinery (FR46-48) a **place to put your hand** — currently both are pure background math with no interface.

## What's settled this session

- **One hex grid, one coordinate space.** The board you zoom out to and the ground you walk on are the same grid, LOD'd — not two disconnected representations. Zooming in reveals the actual actors, mines, trade goods, tavern; zooming out shows the strategic abstraction. This is what keeps diegetic legibility (FR17, no floating bars) intact at every zoom level: bodies only ever render at the zoom level where bodies exist, so the board only needs to be legible as terrain/resource abstraction, a much lower bar than "legible as people."
  - **Production note:** a hex cell is already shaped like the architecture's existing `location → tags` lookup (see PRD "Position resolves through a location fact, not physics, by default"). If world-gen produces hex chunks as the base unit, that's one generator serving both LODs — not two authoring pipelines (hand-build a town, separately hand-build a strategic map).
  - **Parked:** does presence-scarcity (FR44) ever get *waived* by growing influence, or only ever *delegated*? Zach flagged that even at high influence you may still need to travel to specific places to drive certain plays — not resolved.

- **No new currency.** Board actions spend **reach** — the per-channel vector the PRD already defines (FR46: coercive/economic/authority/loyalty/informational) — not an invented action-point pool. This keeps the Core Mechanical Model's "no second engine" rule intact and enforces the Executive Summary's guardrail (power is causal reach, not wealth) automatically: a wallet with no reach still can't move the board.

- **One verb to start: install a goal, targeted at a hex.** Reuses FR11/FR12/FR45 exactly — install a goal in whoever holds that location; what they actually do about it (hire workers, squeeze existing labor, neglect something else) isn't authored, it falls out of their own drives, same as any other installed goal. Other verbs (directly contesting a rival) are deferred, not designed away — see below, they may not need a bespoke verb at all.

- **Cadence: stack, not pause.** Committing a board action resolves on its own clock while the world keeps running — matching the MTG-stack precedent already crystallized for Health Triangle combat, not a Civ-style synchronous turn that freezes the ground level. Exact timing/duration is tuning, deferred.

- **Capacity model: occupied, not drained, not a refilling gauge.** This is a third model, distinct from both persistence types already in the PRD (transactional/accrual decay on a channel):
  - Installing a goal **ties up** a portion of current reach for as long as the goal is active.
  - The capacity **returns when the goal resolves** — regardless of success or failure.
  - Reach itself is never damaged by installing a goal (rejected: "drawdown" model, where a board action would directly cool a specific NPC's disposition). Reach is also not a flat per-cycle refill abstracted away from the graph (rejected as its own thing, on its own: "gauge" model).
  - Rationale: avoids double-jeopardy (paying via both damaged capacity *and* a soured relationship for one play), which would push toward risk-aversion and work against the "one more move" pull named in Success Criteria.

- **Outcome consequences land at ground level, not in the points economy.** Success/failure of a goal doesn't change capacity math — capacity returns either way. Consequences are felt through the existing relationship/channel machinery (a cooled greeting rung, a resentful captain), consistent with FR35 ("recoverable by a route-appropriate action, never a one-way penalty"). This cleanly separates two questions the systems already answer separately: "how much can I attempt right now" (capacity) vs. "did people like what I did" (relationship state).

- **MTG instant/permanent framing, and a mix of both is intended:**
  - **Instants = one-shot goals.** Resolve once, release their occupied capacity.
  - **Permanents = standing goals.** Installed and left running indefinitely, occupying capacity until revoked.
  - Both cost reach to install/cast.
  - **Permanents give the deferred "contest a rival's enterprise" idea a natural home, likely without a new verb.** A standing goal is something a rival's competing goal can outbid via the arbitration math that already exists (FR13: an installed goal competes with the actor's own drives and can be outbid). A permanent doesn't get "destroyed" by a bespoke removal action — it gets *outplayed*, visibly, as the held actor's compliance slips. Theorized, not proven.

## Parked / explicitly deferred

These are flagged so they aren't lost, not because they're unimportant — several are close to load-bearing for how the board actually plays:

1. **Presence-scarcity at high influence** — does travel to specific places remain necessary once influence is high, or does that requirement change shape? (See "one hex grid" above.)
2. **Differential pricing for standing vs. one-shot goals** — raised as the likely single lever against a lategame "autopilot" trap (the Civ-governors problem: cheap standing orders accumulate until the board stops being a series of decisions). Explicitly deferred to a calibration/tuning pass — "we'll certainly be scaling actions as we calibrate to fun gameplay."
3. **Standing-goal visibility.** A permanent that never resurfaces at ground level risks becoming an invisible number going up — the tycoon trap and the floating-bar anti-pattern at once. Working instinct (not yet mechanized): a standing goal should periodically re-surface diegetically (a steward reports back, a felt event), the way fear needs renewal to not decay — not free, visible upkeep.
4. **Dormant-but-occupied capacity.** If a held actor's own drives are currently outbidding a standing goal (FR13), does the goal's capacity stay locked the whole time it's not being honored? Not resolved.
5. **Revocation cost.** Is pulling a standing order off someone free, or does it cost something the way installing one does — symmetry argument raised, not settled.
6. **Exact stack timing/duration mechanics** — deferred to tuning, per the "cadence" decision above.

## Where this sits against the existing PRD

FR46-48 (per-channel reach, access to state-moving actors, growing reach unlocking new actions/actors/strategies) and the "Two-tier world" architecture note already describe most of what this board is *for*. Worth checking in the next PRD edit pass whether the hex board is simply the missing interface for the existing far-tier/reach concept — in which case it sharpens existing FRs rather than adding new ones — or whether it earns its own FR group. Not decided here.

## Grid geometry & resource blocks

*Continued in the same 2026-08-02 session, same status (non-binding seed).*

- **Micro-hex composition.** The hex the player sees at the strategic zoom is itself composed of smaller micro-hexes, sized to the functional footprint of what occupies them — a merchant stall might be one micro-hex, a town square or a tavern six. Not a fixed size; a footprint per feature. The strategic-zoom hex is a LOD aggregation over a cluster of these.

- **Two ownership layers, not one — this resolves a real complexity, not just papers over it:**
  - **Territorial/jurisdictional control** — the jarl's domain. Contiguous, hierarchical, legible at a glance (one clear owner per region, like Civ's borders). This is the **authority channel and promotion** (FR81-83) made geometric: whose goals cascade over this ground.
  - **Asset/enterprise ownership** — a route actor's holdings (e.g., a commerce actor's stalls). Scattered, tied to the owning actor's reach in their route, can cross jurisdiction boundaries freely. This is the **value-chain enterprise system** (FR55) made geometric: what you operate, wherever it sits.
  - An asset sitting inside someone else's jurisdiction is a natural, concrete instance of FR58 (borrowed tools at a premium) / FR59 (routes interfere) — **flavor only for now, no mechanism attached.** Parked as the likely eventual home if/when exposure (taxation, seizure, protection) earns its way in.
  - UI concern resolved by precedent, not new design: standard toggle-able overlay (territory borders as one layer, actor holdings as pins on top) — the genre already solves this (Civ shows national borders and trade routes/improvements as separate layers on one map).

- **Resource blocks are not a new data structure.** A micro-hex's "stat" (the thing a goal-install action changes) is literally whichever primary the shipped economy already tracks at that location — production output, worker count, wage. One source of truth between the board and the walked world: looking at the actual farmer shows the same number the board showed. Same discipline as "reach, not a new currency" — reuse a real number, don't invent a parallel one.

## Territorial legibility (regional tells)

- Extends the existing diegetic-presentation pillar (FR67-69: semantic signals independent of skin, partial/inferred state readable before acting) from **body scale to territory scale.** A region's ambience — music, color saturation, whatever the presentation layer wants to key off — can be a tell, same pillar, bigger canvas. Not a new system.

- **Mechanism: a rollup, same shape as the existing reach rollup** (architecture note: "a slow-tick rollup over the social graph"). Aggregate the driver/tell state of the actors living inside a domain's footprint.

- **Two speeds, not two mechanisms, produce both a "mood" and a "character":**
  - **Fast/current mood** — a frequent-tick aggregate (today's read: a recent crackdown, a festival).
  - **Slow/regional character** — the identical rollup computed over a long window, smoothed enough that only a *sustained* pattern of rule shows through. This is what supplies the "static" quality Zach wanted, without a separate broadcast mechanism — it's the honest aggregate, just slower.

- **The direct/authored broadcast layer Zach also wanted already exists: FR22** (allegiance sigil/colour, variable intensity, concealable). A lord's banner/heraldry is a *claimed identity* — an authored choice, not a derived read — sitting alongside, not replacing, the honest population aggregate.

- **The generative payoff:** when the claimed identity (banner) and the slow honest aggregate (regional character) diverge — a lord flying proud colors over a population whose long-run state reads exhausted and afraid. The player infers this gap; the world never states it as a label. Consistent with the illegible-authorship spine and FR23 (every read is comparative).

- **Settled:** mostly honest aggregate, with the "broadcast" feel achieved by layering tick-speed (fast mood / slow character) under the existing FR22 sigil system — not a new mechanism.

## Terrain generation & settlement templates

- **Landscape is the world seed — generated once, up front, for the whole kingdom.** Standard layered pipeline: elevation/heightmap first, then hydrology (rivers/lakes derived by flow simulation off elevation), then biome classification (elevation + water proximity, possibly temperature/latitude). This is cheap, global, geometry-and-classification only — no actor content.
- **This resolves the earlier up-front-vs-on-demand question by layer, not by an either/or.** The macro terrain layer (elevation, hydrology, biome) is cheap enough to generate globally up front — it's exactly the "aggregate state" FR72 already wants for a distant, unvisited region. The expensive layer — actual micro-hex detail, specific actors and buildings — stays deferred to the promote/collapse seam (FR73), generated only when attention arrives. Same split already used for actor LOD, extended one layer down to geometry.
- **Biome gates what a hex can produce** (mountains → ore/stone, plains/river-adjacency → grain, forest → lumber), feeding directly into the "resource block = shipped economy primary" rule above.
- **Economic-playability as a hyperparameter, not a binary choice.** Rather than picking between purely naturalistic generation (settlements adapt to whatever geography rolls; can produce a genuinely hard kingdom with no good farmland near a river) and constrained generation (always guarantees a coherent resource mix within reach), expose the degree of constraint as a tunable dial. Ship a sane default now; the dial itself is a free replayability/difficulty lever later — same generator, harder or gentler starts.
- **Settlement micro-hex layout: template library, not freeform generation.** A small authored library of footprint templates (town square, tavern, stall, church, etc.) gets arranged by a placement algorithm per settlement — cheap, finite, reusable, and gives direct authorial control over each footprint's content (a tavern template can guarantee the cast a scene like Journey 1 needs actually exists there, every time).
- **Templates carry parametric variation, not structural variation.** A template defines a fixed shape and cast (a tavern has a bar, tables, room for N patrons); a few parameters vary each instance — capacity, footprint size, which of a small pool of interchangeable arrangements gets picked. A wealthier domain's tavern seats more and occupies more micro-hexes than a hamlet's, using the same authored template. Line held: parametric (numbers vary within a fixed shape) yes, structural (the algorithm invents a genuinely novel layout from scratch) no.

## Landed here — open threads for future structured sessions

Everything below is named so it isn't lost, not because any of it is next by default:

- **Zoom-transition feel** — what it's actually like to move between the strategic view and the walked ground level (mechanically and experientially). Not discussed yet at all.
- **How many micro-hexes typically compose one strategic-zoom cell** — order-of-magnitude scale question, not pinned down.
- **Presence-scarcity at high influence** — does travel to specific places remain necessary once influence is high, or does that requirement change shape?
- **Differential pricing for standing vs. one-shot goals** — the likely lever against a lategame "autopilot" trap; deferred to a calibration/tuning pass.
- **Standing-goal visibility** — how a permanent goal periodically resurfaces at ground level so it never goes invisible; instinct only, not mechanized.
- **Dormant-but-occupied capacity** — whether a standing goal's capacity stays locked while the held actor's own drives are currently outbidding it.
- **Revocation cost** — whether pulling a standing order off someone costs something, symmetric with installing one.
- **Exact stack timing/duration mechanics** — deferred to tuning.
- **Asset-in-foreign-jurisdiction mechanism** — currently flavor-only (no mechanical exposure); parked as the likely eventual home for FR58/FR59 texture if it ever earns a mechanism.
