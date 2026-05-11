---
name: Placeholders Ledger
status: live (updated as phases land)
date_started: 2026-05-04
relates_to:
  - _bmad-output/prototype-completion-roadmap.md §7 (format authority)
  - _bmad-output/prototype-completion-companion.md §1 (current code state)
purpose: |
  Single index of every stubbed value or placeholder behavior in current
  code. Each entry names where the placeholder lives, what it currently
  does, what's gating the real version, and what trigger surfaces it for
  resolution. Maintained as code evolves — when an entry resolves, strike
  it (don't delete the line) so the resolution history stays visible until
  the surrounding phase directive lands.
---

# Placeholders Ledger

## Format

```
### [Name]
- **File:line:** `relative/path.gd:LINE`
- **Current value/behavior:** ...
- **Real version gated on:** [phase / elicitation / event]
- **Trigger to revisit:** [condition]
```

---

## Aptitudes / Skills / XP

### `FarmingSlotActivity.BASE_XP`
- **File:line:** `tkyds-game/scripts/activities/farming_slot_activity.gd:13`
- **Current value/behavior:** `0.0` — no XP accrues on slot close.
- **Real version gated on:** Elicitation A + Phase 3.
- **Trigger to revisit:** Aptitudes integrated into actor model; XP curve confirmed.

### `FarmingSlotActivity._aptitude_factor()`
- **File:line:** `tkyds-game/scripts/activities/farming_slot_activity.gd:49-52`
- **Current value/behavior:** Returns `0.0`. Slot output and XP collapse to BASE_OUTPUT / BASE_XP.
- **Real version gated on:** Elicitation A — distribution + mapping decisions.
- **Trigger to revisit:** Aptitudes integrated; W_ATH/W_CHA/W_INT weights become live.

### `FarmingSlotActivity._variance()`
- **File:line:** `tkyds-game/scripts/activities/farming_slot_activity.gd:54-57`
- **Current value/behavior:** Returns `0.0` — fully deterministic slot output.
- **Real version gated on:** Elicitation A — variance design (deterministic vs. stochastic; band; gameplay role).
- **Trigger to revisit:** Variance design locked.

### Actor `aptitude_profile` field
- **File:line:** `tkyds-game/scripts/actors/actor.gd` (no field exists), `tkyds-game/scripts/resources/aptitude_profile.gd` (Resource class exists, unused)
- **Current value/behavior:** No Actor instance has an `aptitude_profile`. The Resource class is defined but never instantiated.
- **Real version gated on:** Phase 3.
- **Trigger to revisit:** Bootstrap will assign at actor creation; aptitudes feed slot output and wage skill_factor.

---

## Hunger / Vitals

### `FarmingSlotActivity.BASE_CALORIES`
- **File:line:** `tkyds-game/scripts/activities/farming_slot_activity.gd:14`
- **Current value/behavior:** `0.0` — no calorie burn on slot.
- **Real version gated on:** Elicitation B + Phase 4.
- **Trigger to revisit:** Hunger system designed.

### `FarmingSlotActivity.BASE_FATIGUE`
- **File:line:** `tkyds-game/scripts/activities/farming_slot_activity.gd:15`
- **Current value/behavior:** `0.0` — no fatigue accrual on slot.
- **Real version gated on:** Elicitation B + Phase 4.
- **Trigger to revisit:** Fatigue mechanics designed (tied to hunger or separate?).

### `VitalsBook.morale` never written
- **File:line:** `tkyds-game/scripts/books/vitals_book.gd:4` (account name reserved in header comment)
- **Current value/behavior:** No activity writes to a `morale` account. No consumer reads it.
- **Real version gated on:** Elicitation F + Phase 9.
- **Trigger to revisit:** SocializeActivity lands (writes morale ↑); hunger-strike trigger lands (reads morale + hunger).

### `GrainInterest.outstanding_demand` not read as hunger pressure
- **File:line:** `tkyds-game/scripts/interests/grain_interest.gd:5`
- **Current value/behavior:** Field accumulates and decays correctly. `record_clearing()` keeps it current. Trace prints it. No code reads it as hunger pressure (no productivity modulation, no wants-curve shift).
- **Real version gated on:** Phase 3.5 (G9 — field moves OFF the Interest, accumulates as journal entries on a `Demand_Carry:grain` Book account) + Phase 4 (read as hunger pressure).
- **Trigger to revisit:** Phase 3.5 directive author pass relocates the state to Books per G9 discipline; Phase 4 wires hunger-feedback.

---

## Wage / Labor

### `LaborContract.wage_per_slot` locked at contract creation
- **File:line:** `tkyds-game/scripts/activities/labor_contract_activity.gd` (`WagePolicy.LOCKED_AT_CONTRACT` is the only enum value).
- **Current value/behavior:** Computed via `WageCalculator` at `LaborContractActivity.on_close`, never recomputed for the contract's life. Decision documented in the activity's header comment.
- **Real version gated on:** N/A — locked-at-contract is the v0 design choice; not a placeholder. Listed here so the seam is visible.
- **Trigger to revisit:** When a non-locked policy is wanted (apprenticeship rate-step, seasonal renegotiation). Backlog entry: "Wage-policy: recomputed-at-settlement."

### `LaborMarket.supply_for_scarcity()` returns hardcoded 2
- **File:line:** `tkyds-game/scripts/markets/labor_market.gd:22-24`
- **Current value/behavior:** Returns `2` (the v0 worker count). Used in scarcity computation.
- **Real version gated on:** Multi-region landed (Phase 5+) OR earlier if regional registry lands.
- **Trigger to revisit:** When second region exists in the world.

---

## Inventory / Cost basis

### `MercantileInterest.wholesale_cost_per_unit` single-batch
- **File:line:** `tkyds-game/scripts/interests/mercantile_interest.gd:15`
- **Current value/behavior:** Overwritten each wholesale buy with the latest clearing price. No weighted average across batches; no per-supplier breakdown.
- **Real version gated on:** Phase 5 (multi-good or multi-supplier with non-unit prices).
- **Trigger to revisit:** Second supplier or second good lands and weighted-avg cost basis becomes load-bearing.

### Inventory units/dollars conflation in COGS disposal Tx
- **File:line:** `tkyds-game/scripts/activities/wholesale_sale_activity.gd:38-39` (producer Tx 1); `tkyds-game/scripts/activities/retail_purchase_activity.gd:38-41` (merchant disposal Tx 1)
- **Current value/behavior:** Both disposal Txs ship inventory out of `Inventory:grain` while conflating units and dollars. The producer's Tx 1 disposes `quantity` units at $1/unit (assumes producer cost basis = 1.0). The merchant's retail Tx 1 disposes `total_cogs = quantity × unit_cost_basis` "units" out of `Inventory:grain` — but `Inventory:grain` is held in unit count, so when `unit_cost_basis ≠ 1.0` the wrong number of units leaves the ledger. At v0 calibration ($1/unit everywhere) both reconcile; the conflation is structurally latent, not surfaced.
- **Real version gated on:** Elicitation C — choice of inventory-tracking convention (units-tracked + `Cost_of_Inventory` contra-account on disposal, OR dollar-tracked inventory). Stage 0 cleanup landed the acquisition-side `Cost_of_Inventory` for the merchant; the disposal side is the matching half.
- **Trigger to revisit:** First non-unit producer cost basis OR first non-unit merchant unit_cost_basis. Likely surfaces as soon as a second good lands at a different price tier than grain, or when wages/output diverges from 1:1.

---

## UI / Diegetic vocabulary

### `Activity.display_name` field never set
- **File:line:** `tkyds-game/scripts/activities/activity.gd:25`
- **Current value/behavior:** Field declared as `&""`. No concrete activity sets it; no consumer reads it.
- **Real version gated on:** First UI consumer (Phase 7 or Phase 8 first-observation-UI). Per Elicitation E adjudication: stay as no-op overhead; do not set, do not delete, do not surface.
- **Trigger to revisit:** First UI surface that needs to render a player-facing line for an Activity.
- **History:** 2026-05-06 — Elicitation E hardened the gate. Mary's deferred-with-reasoning posture won; Cloud's "set in subclass `_init` now" was rejected because v0 has no UI consumer. Cost of leaving the field is near-zero; cost of removing then re-adding is real.

### Diegetic vocabulary surfacing (tone, templating, per-Activity narration)
- **File:line:** Not present in code; design seed only.
- **Current value/behavior:** Headless trace prints engineering vocabulary (`Bob's WorkDay closed: 4 grain produced`). No diegetic surface.
- **Real version gated on:** First UI consumer (Phase 7/8). Ties to `Activity.display_name` and a `closing_narration_template(book_delta)` method or equivalent.
- **Trigger to revisit:** First UI surface that needs to render player-facing lines.
- **Anticipated shape at consumer time:** Per-Activity-class `const`/`_init`-set strings (Cloud's resolution); registry deferred to Phase 12+ localization. **Or** per-Activity templates that read `book_delta` and produce time/population-aggregated lines (Samus's "Greenfield came in light this week — four sheaves where five were hoped for"). G's intent architecture may shift this if NPC-visible-intent becomes a UI surface.

---

## Inference / Precision / Observer-gated reads

### `Book.balance(...)` and `Book.entries(...)` — `observer: Actor = null` parameter slot
- **File:line:** `tkyds-game/scripts/books/book.gd:32, 44, 59` — to be added in next code pass after E lock (Phase 3 or earlier).
- **Current value/behavior:** Methods take `(account, period_start, period_end)` only. No observer parameter.
- **Real version gated on:** Not gated — adopted by Elicitation E directive 4. Parameter slot lands now; default behavior unchanged (`observer == null` = god-mode precise read, today's only mode).
- **Trigger to revisit:** Phase 6+ first observer-gated reader. At that point, a precision-resolution wrapper layer materializes the observer into actual precision degradation.

### Per-account precision shapes
- **File:line:** Not present; design seed only.
- **Current value/behavior:** All book reads return `float`. No per-account-type precision differentiation.
- **Real version gated on:** Phase 6+ first observer-gated read consumer. Per Elicitation E directive 5: per-account-type adapter chosen at consumer site, NOT a global `Reading` union.
- **Trigger to revisit:** First observer-gated reader — likely a UI surface that must show "appears prosperous" or "approximately 50 grain" for a non-self actor.
- **Anticipated shape at consumer time (per-account, plural):**
  - Vitals (food_satiation, fatigue) → small enum bucket (UNDERFED / FED / WELL_FED) or range pair
  - Financial (cash, payable, revenue) → noisy magnitude (true_value × (1 ± noise)) or range pair
  - Reputation (when it lands) → decayed scalar with confidence
  - Skills/XP → coarse skill-level enum (NOVICE / JOURNEYMAN / MASTER) for outsiders; precise for steward-level access
  Each consumer designs its own shape; no central type forces uniformity.

---

## Knowledge / Counterparty resolution

### NPC knowledge representation
- **File:line:** Not present; design seed only.
- **Current value/behavior:** Counterparty IDs are opaque `StringName`s in book entries (`Payable:rival_lord_castellan`). No resolution layer. NPCs operate with full info on each other when their Interest loops fire.
- **Real version gated on:** Elicitation G (perception → decision → action loop). G's intent architecture choice determines whether NPCs need a knowledge representation at all. Three candidate shapes (preserved as alternatives, not commitments):
  - **(per-actor)** Every actor has `accounts.books[&"knowledge"]`. Substrate for "gossip = lossy book-leaks" (Samus).
  - **(player-only)** A `PlayerKnowledge` Resource; NPCs use full-info gated by precision tier when they read others' books (Cloud).
  - **(none in v0)** Counterparty IDs stay opaque; no resolution layer until first UI consumer (Mary).
- **Trigger to revisit:** Elicitation G's adjudication of NPC intent representation + perception-decision coupling.

### Gossip substrate (book-leak mechanics)
- **File:line:** Not present; design seed only.
- **Current value/behavior:** No gossip system. No way for an actor's book entry to propagate, with decay/noise, to another actor.
- **Real version gated on:** Elicitation G + the phase that lands social/tavern mechanics (likely post-G, possibly Phase 9 social per Elicitation F). Author's D3 critique: programmatic path required, not just aesthetic — "how does imperfect information motivate actual NPC decisions?"
- **Trigger to revisit:** G ships the perception-decision-action loop architecture; gossip becomes implementable as a propagation mechanism over book reads, with a clear path from "book entry" → "perceived event" → "decision input" → "observable behavior."
- **Anticipated shape (preserved as design seed only — not commitment):** "Books are truth substrate; gossip is lossy book-leaks via tavern/social events with decay and noise" (Samus). Requires per-actor knowledge representation OR a propagation system that doesn't need actor-local memory.

---

## Cohort / Population caching

### Godot-groups-as-cohort-cache
- **File:line:** Not present; forward note only.
- **Current value/behavior:** Cohort membership derives from truth substrate (`EmployerInterest.employees()` walks `accounts.contracts`). No cache layer. O(n) per aggregation.
- **Real version gated on:** Either (a) cross-cutting cohort lands that doesn't derive from a single Interest (e.g., "hungry workers across all employers in this region" — needs a query that spans employers AND filters by VitalsBook state), OR (b) profiling shows population queries in the simulation hot path (>5% of frame time, or single-tick exceeds 33ms).
- **Trigger to revisit:** Either trigger above. At that point, Godot's `Node.add_to_group("cohort_name")` becomes the natural index — engine-tracked, O(1) add/remove. Membership sync happens via the Activity that creates/destroys cohort participation (e.g., `LaborContractActivity` adds worker to employer's group on close; contract end removes). Force-carrier discipline keeps it from diverging from truth.
- **Anticipated shape at consumer time:** `add_to_group(cohort_string)` / `remove_from_group(cohort_string)` calls inside relevant Activity `on_close` / `on_abort` hooks. Aggregator helpers (e.g., `PopulationOps.aggregate(cohort_string, account, op, period)`) walk the group instead of the contracts. Truth substrate (contracts) remains canonical; group is index/cache.

---

## Reputation

### `accounts.books[&"reputation"]` not seeded
- **File:line:** `tkyds-game/scripts/resources/accounts.gd:5` (header comment names the slot)
- **Current value/behavior:** No `ReputationBook` class exists. Bootstrap doesn't seed the slot. No actor has reputation entries.
- **Real version gated on:** Elicitation F + Phase 9.
- **Trigger to revisit:** Reputation locality and accumulation design locked.

---

## How to use this file

When an entry resolves:
1. Strike the entry (don't delete the line) so the resolution history stays visible.
2. Add a `**Resolved:** <YYYY-MM-DD> by <directive ref>` line under the entry.
3. When the surrounding phase directive lands, the resolved entries can be archived to the directive's "placeholders cleared" section and removed here.

When a new placeholder is introduced (e.g., a Phase 3 directive adds a stub), add an entry here at land-time so the ledger stays the single source of truth.
