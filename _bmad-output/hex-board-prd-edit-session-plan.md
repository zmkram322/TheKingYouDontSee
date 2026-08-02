# Hex Board / Influence Layer — PRD Edit Pass Session Plan

*Prep runbook for a future session, not the session itself. Written 2026-08-02, same day as the brainstorm it prepares. Companion to `hex-board-influence-layer-seed.md` (the raw material this session validates and, if it survives, feeds into a `bmad-edit-prd`/`gds-edit-prd` pass on `prd.md`).*

**Why this exists:** everything in the seed doc is a one-on-one brainstorm (Zach, Claude, Samus-in-character), not yet pressure-tested the way anything else that's made it into the locked PRD has been — the social/political layer went through a full party-mode roundtable before its first PRD draft, and FR1 was rewritten only after a code spike proved the original wrong. The seed doc deserves the same bar before it touches `prd.md`, not because the ideas are shaky, but because that's the process that's caught real problems every other time it's been run here.

## Step 0 — Scope call (solo, fast, do this before spawning anyone)

Confirm: **the hex board is Growth/Vision-tier, not MVP.** The MVP proving scene (pub, three actors, no board) doesn't touch it. This should hold on inspection, but say it out loud and commit to it before the party convenes — it sets how much rigor the rest of this session actually needs, and keeps the roundtable from accidentally re-litigating MVP scope. If this call turns out *not* to hold (something in the seed doc turns out to be load-bearing for the MVP after all), stop and re-scope before continuing.

## Step 1 — Party-mode roundtable

**Party:** Cloud Dragonborn (architect), Samus Shepard (designer), Mary (analyst), Indie (solo-dev scope). Same four who ran the FR1 roundtable and the multi-path-routes work — reuse the working group, not a new one.

**Orchestration rules (non-negotiable, carried over from the axis-identity session precedent):**
1. Agents surface options and risks; they do not unilaterally decide. A soft recommendation is fine as a one-line tail, not the whole answer.
2. No agent proceeds past their assigned questions without an author check-in. Halt after each agent's pass, present findings, wait for Zach.
3. Orchestrator (whoever runs the session) frames each pass, spawns in parallel where questions don't depend on each other, presents responses verbatim, halts, confirms, moves on.

**Cloud Dragonborn — architecture pressure-test (highest priority; several seed-doc claims are "this reuses existing X" asserted, not verified):**
- Does hex-of-hexes LOD (micro-hex cluster → strategic-hex aggregate) actually compose with the existing sparse+inheritance social graph and stat-store accessor, or does spatial aggregation need its own data shape?
- Can promote/collapse (FR73) genuinely extend from actors to terrain/geometry the way the seed doc claims (cheap global macro layer, on-demand micro layer), or does on-demand terrain generation need a separate mechanism after all?
- **Highest-risk claim in the doc:** is "occupied capacity" (reach tied up while a goal is active, released on resolution) implementable as a derived-stat read, or does it require real mutable per-actor state — a list of active commitments — that risks becoming exactly the kind of "demand with memory" the PRD's atom explicitly rejected for the economy layer? This one may be worth a spike (see Step 2).
- Storage cost of two ownership layers (contiguous jurisdiction vs. scattered assets) — does contiguous territory need a different shape than the existing sparse edge-based graph?
- Does the territorial-legibility slow-tick rollup fit inside the existing performance NFR (150 actors, no frame >33ms on a slow tick) once it's stacked on top of the reach/power rollups already running there?

**Samus Shepard — design cross-check (lighter touch; most of this already got a 1:1 pass this session, this is a second set of eyes, not a re-derivation):**
- Does the single goal-install verb hold up as genuinely *fun* across a full Growth-phase arc, or does the deferred "contest a rival" thread need to arrive sooner than "arbitration handles it for free" suggests?
- Check the MTG instant/permanent framing against route parity (FR61) — does the board give every route (war/commerce/crime/secrets/public-service) equally interesting things to do, or does it quietly favor territorial/production routes over covert ones?

**Mary — positioning/comparables:**
- Civ 6 and Catan now enter the comparables set alongside CK3/Dishonored/Nemesis/Disco Elysium. Does that strengthen the "not a menu-driven scheme" positioning, or dilute it? Does it belong in Innovation & Novel Patterns as a fifth area, or fold into an existing one?
- Does the board shift how the game reads genre-wise in a way that changes the target-player framing in the Executive Summary?

**Indie — solo-dev scope reality:**
- Full scope as captured (terrain gen, template library, territorial legibility, two ownership layers, goal-install economy) — buildable inside Growth/Vision timelines for a solo dev, or does it need its own phased sub-scope, narrower than everything currently in the seed doc?
- What's the smallest slice worth prototyping first — a "board proving scene," mirroring the discipline that already produced the ground-level MVP?

## Step 2 — Decide spike-or-not

FR1 only got rewritten correctly after `fable-spike-decisions.md` forced the model concrete in code. Several seed-doc claims are the same shape of assertion ("this reuses X, no new engine needed") and haven't been forced yet. After Step 1, decide whether either of these earns a small headless spike before FR language gets written:
- **Occupied capacity as a derived read** (flagged above under Cloud's pass) — the single riskiest claim in the doc.
- **Hex-of-hexes on-demand generation** — whether the cheap-macro/expensive-micro-on-demand split actually holds up once code has to move between the two LODs, not just in description.

If a spike is warranted, scope it the same way the fable spike was: smallest scene that forces the real question, decisions document written from what the code actually did, not from the plan.

## Step 3 — Run the PRD edit

Once Steps 1–2 land (or explicitly get deferred with reasons, same as any other open question), run `bmad-edit-prd` (or `gds-edit-prd`) against `prd.md`. Expected touch points, based on what the seed doc claims and what already exists:
- **Product Scope / Growth & Vision** — a new subsection for the board layer, phased in wherever Step 0/1 land it.
- **A new FR group** — the goal-install-at-location verb, the occupied-capacity model, the instant/permanent split, territorial legibility as a rollup. Append-only numbering per the PRD's existing policy; don't renumber anything.
- **Journey 4 (Becoming the King You Don't See)** — currently gestures at kingdom-scale play with no concrete mechanism; check whether it should be rewritten around the board the way Journey 1 was rewritten around the proving scene.
- **Open Questions** — migrate the seed doc's "Landed here" list into the PRD's own Open Questions section (tagged `[author]`/`[party]` per existing convention) so parked threads are tracked in one authoritative place instead of living only in the seed doc.
- **Frontmatter** — new `editHistory` entry, `inputDocuments` entry for the seed doc (and the spike decisions doc, if Step 2 produces one) with correct `role`/`binding` status, consistent with how `fable-spike-decisions.md` was added.

## Pre-read for the fresh session

- `_bmad-output/hex-board-influence-layer-seed.md` — the raw material, full doc.
- `_bmad-output/planning-artifacts/prd.md` — the locked target, especially Core Mechanical Model, Product Scope, and the existing Open Questions section.
- `_bmad-output/fable-spike-decisions.md` — format/rigor reference for Step 2 if a spike gets scoped.
- `_bmad-output/design-multipath-routes-framework.md` — route-parity reference for Samus's and Mary's questions in Step 1.

## Resume command

> "Hey Samus — let's run the hex-board PRD-edit prep session. Start with Step 0 (confirm Growth/Vision scope), then Step 1: party = Cloud + Samus + Mary + Indie, pressure-testing `hex-board-influence-layer-seed.md` against the locked PRD, per the questions in `hex-board-prd-edit-session-plan.md`. Halt between agents for my check-in."
