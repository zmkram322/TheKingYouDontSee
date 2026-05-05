---
name: GDD ↔ Build Alignment Review
status: complete (pre-Stage-1 reality check)
date: 2026-05-04
session_type: party-mode
session_inputs:
  - _bmad-output/gdd.md
  - _bmad-output/prototype-completion-roadmap.md
  - _bmad-output/prototype-completion-companion.md (§1 code map)
  - _bmad-output/placeholders.md
  - memory/project_thekingdontSee.md
authors:
  - Cloud Dragonborn (Game Architect)
  - Samus Shepard (Game Designer)
  - Mary (Business Analyst)
  - Indie (Game Solo Dev)
  - Author adjudication (Zach)
purpose: |
  Pre-elicitation reality check. The GDD was written largely before Phase
  2.5/2.6 landed; some of what's been built since is GDD-canon-eligible,
  some of what the GDD says is stale. Framing: neither doc is authoritative
  — both are evidence; recommend changes to whichever needs them; vet
  whether the build is on the right trajectory.
---

# GDD ↔ Build Alignment Review

## 1. Agent Responses

### 🏛️ Cloud Dragonborn — Game Architect

*The morning light finds the foundations laid, and I have walked them with a critical eye. Sit a moment — the load-bearing walls deserve proper consideration before the next stones are stacked.*

**1. GDD edits**

- **GDD §Sim Architecture names *Worker / LandOwner / Merchant* as Actor subclasses; build flattened to a single `Actor` carrying Interests.** Recommend **GDD adopts B**. The flattened Actor + composable Interests is a deeper, more defensible foundation than role-as-class — every later system (lords, builders, soldiers) gets the same load-bearing surface.
- **GDD §Sim Architecture declares *"Sim state lives in plain GDScript Resource objects... No `get_node()` in the sim layer."* Build now uses Autoloads which are nodes.** Recommend **GDD adopts B, with a clarification clause**. The discipline that matters is *value-typed sim state*, not *no nodes anywhere*. Coordination autoloads earned their keep.
- **GDD §Economic Loop describes a push-based daily supply emit + cached cost basis; build now does pull-on-open with FinancialBook queries.** Recommend **GDD adopts B**. Pull-on-open structurally eliminates a whole bug class.
- **GDD §Sim Architecture lists `Payable` Resource and `weekly_costs`/`weekly_outputs`; build deleted both, replaced by Books + Activities.** Recommend **GDD adopts B** and adds a §Books/Activities subsection — the persistent-vs-transient activity rule is the most reusable architectural primitive we have, and it's not in the bible at all.
- **GDD §Tutorial promises *Structured Observer Entry built last*; roadmap lands a Phase 8 *first observation UI* well before Epic 7.** Recommend **adopt C**: distinguish *developer-facing observation HUD* (early, debug-grade) from *player-facing Structured Observer Entry* (truly last). The GDD conflates them.
- **GDD has no §Macro-Legibility section; project memory locks it as the central architectural lens.** Recommend **GDD adopts B** and promotes macro-legibility to a first-class §Sim Architecture subsection.
- **GDD §Economic Loop says *"Lord: Flat tax rate, no lord AI in prototype."* Roadmap Elicitation D openly questions whether lord lands as actor.** Recommend **defer the GDD edit until D resolves**.
- **GDD §Epic 1 hard-codes 5 actors, flat 1 coin per slot, flat clearing. Build is past this — Phase 2 math (isoelastic demand, scarcity-driven wages) is shipped.** Recommend **GDD adopts B**: rewrite Epic 1 acceptance to match the five Phase 2 ACs that actually reproduce on the trace.
- **GDD §Combat describes melee + injury-as-cost as the next archetype.** Recommend **build pivots toward A — eventually**. But not yet. Combat is downstream of legibility for *this* game's perception fantasy.
- **GDD §Aptitudes is implicit only; the three-tier aptitude/skill/behavior model lives only in project memory.** Recommend **GDD adopts B**: codify the three-tier model in §Sim Architecture.

**2. Verdict — GREEN, leaning cautious-green.** Foundations are sound. Books/Activities/Force-Carrier triad is the right primitive set. Pull-on-open eliminates the cost-basis bug class structurally. Six-elicitation cut is the right granularity. What keeps me from full green: macro-legibility is named as a *lens* but not yet exercised. Until Elicitation E lands the population-API + inference-layer seams, we're accumulating architectural debt against the game's actual identity. If E ships strong directives and Phase 7 lands the seams, my verdict goes full green.

**3. Flags**

- **Run E before D.** D's question *"is the lord an actor or a force?"* is partially answered by E's *"who can read whose books, at what precision?"* — if lord-as-actor lands without book-access gating, you'll either rebuild or leak omniscience.
- **Promote a quiet Stage 1.5 between elicitations and phase plan.** The disposal-side cost-basis landmine is structurally latent at v0 calibration. Resolve the convention *before* Phase 5 starts coding, not during.
- **The architecture diagram should be Stage 2.5 — drawn once after elicitations, redrawn after Phase 5.** Two passes, not one.

*The walls hold. Build on.*

---

### 🎲 Samus Shepard — Game Designer

OHHH yeah, this is the good stuff. I've been sitting with both docs and I gotta tell you — the build is talking back to the GDD now, and it's saying smart things. Let's GOOOO.

**1. GDD edits**

- **GDD §"Epic 1: Sim Proof" — actor list says "1 LandOwner, 2 Workers, 1 Merchant"; build has flat `Actor` + Interests, no subclasses.** *GDD adopts B.* Subclass language fights your own pillar.
- **GDD §Sim Architecture lists `Payable` Resource and `Accounts` with coin/inventory/payables fields; build deleted all of those for `books: Dictionary` + Books primitive.** *GDD adopts B.* The Books primitive IS the macro-legibility instrument.
- **GDD §Excludes-from-Epic-1 says "no skills, no XP" and §Mid-Layer puts needs/aptitudes in Epic 2; build already wired SkillsBook + aptitude_profile + WageCalculator skill_factor.** *Build pivots to A* on intent, but the wiring stays as seams. Re-anchor the GDD's epic boundaries.
- **GDD §Economic Loops shows daily wholesale supply emission + weekly clear; build is pull-on-open with Activity primitive.** *GDD adopts B.*
- **GDD §Lord — "no lord AI in prototype, rate float only"; roadmap D opens lord-as-actor.** *Adopt C.* Don't lock either way before D runs.
- **GDD §"Famine cascade as Epic 2 emergence target"; project memory has it as the minimum-viable-emergence demonstration target since day one.** *GDD adopts memory's framing.* Make it Epic 1.5/Phase 4's exit criterion explicitly.
- **GDD §"5 actors, 1 good, 4 windows"; build runs 4 actors, 1 good, 3 markets and reproduces all 5 ACs.** *GDD adopts B.* The 5th actor was vestigial.
- **GDD §Tutorial — "Authored grammar anchor"; build has zero player-facing strings, `Activity.display_name` is a stub.** *Adopt C — defer the GDD's tutorial language until Elicitation E lands.*
- **GDD §Macro-legibility doesn't exist as a named section.** *GDD adopts memory.* This is the most consequential edit on the list. Add the section.
- **GDD §Influence "two-axis (direct coin + indirect stat)"; build has nothing toward this and reputation is parking-lot.** *Defer.* Soften GDD to "two-axis design intent; mechanics deferred to Elicitation F."

**2. Verdict — GREEN, leaning bright green.** Books, Activities, Force Carriers, Interests, WorkPattern — these are the right primitives for a society sim where macro-legibility is the player-facing lens. Books especially: time-aggregated AND population-aggregated queries fall out of the data shape. Pull-on-open killing the cost-basis bug class is the kind of architectural trade that pays compounding interest. Six elicitations is the right granularity. The macro-legibility orientation lock is the move that turns a sim into a *game* — without it you'd be building Dwarf Fortress with extra steps.

**3. Flags**

- **Run E (macro-legibility) BEFORE D (lord) and ideally before C (multi-good).**
- **B (hunger) and C (multi-good) feed each other so hard they should run as a pair.** Hunger pressure IS demand-side input for multi-good economy.
- **The famine cascade demo deserves to be a named Stage 2 milestone, not an emergent target.**

Let's GOOOO ship it.

---

### 📊 Mary — Business Analyst

I read both documents. The GDD is a tall, confident ridge; the build is a working dig site at its base. Let me lay out what I found.

**1. GDD edits (the consequential ones)**

- **GDD Epic 1 names Actor subclasses + Payable/weekly_costs/weekly_outputs as locked v0; build is flat Actor + Interests + Books.** Recommend **GDD adopts the build's flat-actor-plus-Interests model**.
- **GDD Epic 1 §Includes lists `Payable` Resource and placeholder `WageCalculator` returning flat 1 coin/slot; build is journal entries in FinancialBook + real `max(minimum_wage, skill_value × scarcity)` formula.** **GDD adopts the build.** Phase 2 math shipped.
- **GDD §Economic Loops pseudocode shows flat 1 coin/grain clearing, no demand function; build is isoelastic + equilibrium clearing + decay carry-forward.** **GDD adopts the build.** The pseudocode is now historical fiction.
- **GDD §Worker model claims "morale modifier, hunger strike at low hunger + low morale"; build has morale account reserved/unwritten, hunger zeroed, no SocializeActivity.** Recommend **GDD pivots to "morale and hunger are deferred to post-spine phases B+F"** with a forward-pointer to placeholders.
- **GDD specifies EatGrainActivity implicitly; directive deferred it.** **GDD adopts: consumption is a Phase 4 system with EatGrainActivity as anchor activity.**
- **GDD §Window-and-Bus says subscribers don't know who fires windows + WeeklyBurstActivity is part of the model; build deleted both.** **GDD adopts: orchestrator-direct sequencing with WindowBus reduced to work signals.**
- **GDD has no §Macro-Legibility Orientation; memory locks it as the central architectural lens.** **GDD adopts a new short section** under Game Pillars or Difficulty Curve. *This is the one consequential ADD.*
- **GDD §"Acceptance criteria (v0)" #3 — flat 4 coin/worker/day, 56 total at week 7; build matches numerically but doesn't credit the WageCalculator + scarcity machinery.** **GDD adopts a note** that v0 numbers reproduce under the real formula at calibration.
- **GDD §Economic Model says "Merchant: own coin tracking, basic needs"; build has no needs yet, but structural promise holds.** **Build pivots to add self-consumption private subtraction** — diegetic weirdness in trace.
- **GDD §Aptitudes-adjacent material — both stay**, correctly a placeholder. Flag in GDD as "Phase 3 system per Elicitation A."

**2. Verdict — GREEN-with-asterisk.** Books, Activity, Interest, WorkPattern, force-carrier discipline, pull-on-open markets, opaque counterparty StringNames — right primitives for the macro-legibility architecture the GDD describes (even where the GDD doesn't yet name macro-legibility as the lens). Pattern-class additions in WorkPattern make multi-good a sibling change. Cost-basis bug class structurally eliminated. Roadmap's six-elicitation cut hits every load-bearing system. **The asterisk:** the inventory units/dollars conflation in disposal Tx (placeholders.md) is structurally latent — detonates the moment Elicitation C lands a non-unit good. Needs to be on Phase 5's critical path, not "trigger to revisit." Fix that and I'm fully green.

**3. Flags**

- **Re-order: run Elicitation E first or in the first wave.** It's the lens for everything else.
- **Resolve the projected-seams-on-diagram disagreement BEFORE E, not during.** Author adjudication needed.
- **Add a pre-Elicitation-C task: spike the disposal-side Cost_of_Inventory pattern.** A 30-minute POC de-risks Phase 5.
- **The GDD's Epic 1 acceptance language is now stale enough to mislead future sessions.** Schedule a GDD reconciliation pass after Stage 2 (phase plan synthesis) — surgical, not a rewrite.

The dig is good. The trajectory is sound.

---

### 🎮 Indie — Game Solo Dev

Alright, I read the GDD, the roadmap, the companion, the placeholders, the locked-decisions memo. Here's my honest read.

**1. GDD edits — the consequential ones**

- **GDD §Architectural Prerequisites + Epic 1 list the OLD class catalog (Worker/LandOwner/Merchant subclasses, Payable, weekly_costs/weekly_outputs).** Recommend **GDD adopts B.** The refactor is locked memory; the GDD is just stale.
- **GDD §Sim Architecture Constraints — Window-and-Bus describes the deleted coordination spine.** **GDD adopts B.** Pull-on-open is a load-bearing fix that killed a whole bug class.
- **GDD §Economic and Resource Loops still spells out Phase-1 daily/weekly pseudocode with old signal names.** **GDD adopts B**, in summary form. Link the directive instead of pasting drift-prone pseudocode.
- **GDD §Sim Data as Pure Value Types says "Lords are data containers, separate `SimProcessor` reads them."** Build says actors carry Interests that drive their own behavior. **GDD adopts B.** Interest pattern beats god-processor.
- **GDD §Mid layer / Upper layer lists hunger/morale/aptitudes as "Epic 2+".** Roadmap re-buckets these as Phases 3–9 with elicitation gates. **GDD adopts roadmap's phasing.**
- **GDD §Locked Decisions / Lord tax = float, no lord AI in prototype.** Roadmap D is debating lord-as-actor. **Leave both alive until D resolves.**
- **GDD §Aesthetic Goals / ReadoutMapper presumes a render pipeline.** Build has no UI. **GDD pivots to "ReadoutMapper is a Phase 8+ seam, not present-tense architecture."**
- **GDD §Failure legibility test — ≥3 traceable signals — is a great frame.** Macro-legibility orientation IS this, sharper. **GDD adopts macro-legibility framing as a primary design lens.**
- **GDD §Acceptance criteria (v0) describes the 5 ACs in old-vocabulary terms (LandOwner inventory, payables list).** **GDD adopts B's vocabulary** — keeps AC stable but updates the readout.
- **GDD §Worker productivity formula: "confirm min() not max()" still flagged as Open Question.** **Kill the open question entirely** — let A or C resolve it.

**2. Verdict — GREEN, leaning bright green.** Build's direction points where the GDD wants to go, and in several places the build is *ahead* of the GDD in structural maturity. Books/Activities/Force-Carriers are exactly the substrate macro-legibility needs. Pull-on-open killing the cost-basis bug class is the kind of structural fix you only get from a real coding pass. Six-elicitation gate before Phase 3 is correct discipline. Placeholders ledger is the right tool. **What flips me to yellow:** if Elicitation E resolves toward heavyweight inference-layer infrastructure before any consumer exists. *Build a HUD before a knowledge graph.*

**3. Flags**

- **Run B before C.** Hunger pressure IS demand-side input that C wants to test against.
- **Elicitation E will sprawl. Cap agent count or split it.** Run with Cloud + Samus first, then a separate UI-pass with Sally + Paige once seams are named.
- **D's "lord-as-actor vs. force" threads into B and F.** Don't lock D before B and F have at least produced first responses.
- **GDD §10 (Art & Audio) is fine to leave alone.**

Ship the elicitations. The bones are good.

---

## 2. Orchestrator Note

**Strong consensus:**
- Verdict: **GREEN** from all four. Right objects and systems.
- GDD's old class catalog (Worker/LandOwner/Merchant subclasses, `Payable`, `weekly_costs`/`weekly_outputs`, push-based Bus) is stale — GDD adopts the build's flat `Actor` + Interests + Books/Activities + pull-on-open.
- **Macro-legibility must become a named section in the GDD.** All four flag this as the most consequential single ADD.
- Lord-as-actor vs. force (D) stays open until elicitation resolves.

**Real disagreements:**

1. **Elicitation ordering.** Mary, Cloud, Samus want E first as the lens for the others. Indie wants B before C and warns E will sprawl.
2. **Disposal-side Cost_of_Inventory.** Mary: 30-min POC spike before Elicitation C. Cloud: "Stage 1.5" between elicitations and phase plan.
3. **Architecture diagram timing.** Cloud: two passes (after elicitations + post-Phase-5). Roadmap currently has single Stage N.
4. **Famine cascade as named milestone.** Samus: Stage 2 milestone, not emergent.

---

## 3. Author Adjudications (Zach)

1. **Elicitation order:** **E first** (consensus 3-vs-1; trust the team). **B before C** (Indie's argument carried). Remaining ordering (A, D, F) flexible — to be locked in Stage 2 phase plan synthesis.
2. **Foundation concern raised:** social/reputation, war, export/import are likely future systems. Concrete pour goes deep on legibility/multi-goods only — feels weird without the full footprint. **Resolution:** add war + export/import to `design-parking-lot.md` so they're visible. Add a single check item to E's pre-read: *"verify the population API + inference layer don't preclude war / cross-region trade as future sibling systems."* The architecture stays compatible by construction; we don't need to map the full house before pouring foundations.
3. **Disposal-side Cost_of_Inventory:** **adopt Mary's spike framing.** 30-min POC before Elicitation C runs, as a pre-C task in the roadmap.
4. **Architecture diagram passes:** **two passes adopted.** Pass 1 = draft (after elicitations), Pass 2 = final (after Phase 5 stress-tests abstractions).
5. **Famine cascade:** named Stage 2 milestone (per Samus). To be lifted into the phase plan synthesis explicitly.
6. **GDD reconciliation:** scheduled after Stage 2 (phase plan synthesis). Surgical, not rewrite. Macro-legibility section ADD may earn an early carve-out.
7. **Indie's E split:** adopted. E runs with Cloud + Samus + Mary first; Sally + Paige pulled into a follow-up UI-pass once the seams are named.

---

## 4. Roadmap Changes Applied

- §1 table: elicitation order locked (E first, B before C); Stage 1.5 added (disposal-side POC); diagram split into Pass 1 (draft) + Pass 2 (final).
- §3.5 (Elicitation E): pre-read updated with war/cross-region check item; agent owners narrowed to Cloud + Samus + Mary; UI-pass with Sally + Paige split off as follow-up.
- §6 (decision rules): GDD reconciliation scheduled post-Stage-2.

## 5. Followups Scheduled

- War + Export/Import entries added to `_bmad-output/design-parking-lot.md`.
- Project memory resume point updated with new elicitation order.
- GDD reconciliation pass: post-Stage-2, surgical. Macro-legibility section ADD may carve out earlier if the architecture diagram needs it.

— Author adjudication (Zach), with Cloud Dragonborn, Samus Shepard, Mary, and Indie in the room.
