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
- **Real version gated on:** Phase 4.
- **Trigger to revisit:** EatGrainActivity lands; hunger-feedback design locks.

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
- **File:line:** `tkyds-game/scripts/activities/activity.gd:15`
- **Current value/behavior:** Field declared as `&""`. No concrete activity sets it; no consumer reads it.
- **Real version gated on:** Elicitation E + Phase 7 (or first observation UI pass — Phase 8).
- **Trigger to revisit:** When player-facing strings are needed.

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
