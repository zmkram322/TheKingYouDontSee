---
name: Phase 2.5 Round 2 — Cloud D1 Revision (Slot-Level Aggregation)
status: round-2 revision
date: 2026-05-03
author: Cloud Dragonborn (Game Architect)
session: phase-2.5-books-activity-forces
round: 2 (D1-only revision after reading Samus's Round 1)
model: haiku
position: Option C (Hybrid)
---

# Round 2 Revision: D1 — Slot-Level Effect Aggregation

**I choose Option C — Hybrid approach.**

**Statement:** Per-slot SkillsBook, VitalsBook, and activity-tree data fields are written per-slot at slot close. FinancialBook stays aggregated at day level. The activity tree becomes the canonical per-slot record with explicit guarantees about retention and queryability. This preserves Samus's player-legible moments while keeping FinancialBook auditable and clean.

**Reasoning:**

Samus's position lands harder than I anticipated when writing Round 1. Her concern is not pedantic — it's about whether the player can answer "what happened in slot 2 of yesterday's WorkDay?" with diegetic richness or only with a day-level aggregate. My Round 1 defense ("the activity tree is queryable") is architecturally sound but operationally incomplete. The activity tree is durable, yes. But if a slot's XP, fatigue, and grain effects are written only to the parent's aggregated FinancialBook entry, the UI layer has to reconstruct slot-level effects post-hoc from totals and counts — a lossy operation. Samus is right to reject this for player-legibility.

The hybrid approach inverts the cost structure: **write immediately to books that matter for moment-by-moment legibility; aggregate only the books that are purely financial.**

**What goes where:**

- **SkillsBook entries:** Per-slot writes at `WorkSlotActivity.on_close()`. Each slot writes `credit farming +XP_gained` where XP is computed from `base_xp * aptitude_factor` (using the aptitude weights now living on the activity type, per R2.1). The worker's SkillsBook is the source of truth for "which slot earned how much XP?"; the entries are atomic and timestamped by slot close tick.

- **VitalsBook entries:** Per-slot writes. Fatigue, morale, hunger deltas are written per-slot at slot close. A worker's VitalsBook shows the fatigue ramp across four slots; the UI can display "Fatigue accumulation: +2 per slot, now at 6/10."

- **Activity-tree fields:** Each `WorkSlotActivity` carries `grain_produced: float` and `fatigue_incurred: float` as fields. These are not journal entries; they are durable data on the activity object. After the day closes, `actor.completed_activities[yesterday].child_activities[2].grain_produced` is queryable directly.

- **FinancialBook (aggregated):** `WorkDayActivity.on_close()` reads the summed `grain_produced` across all four slot activities and commits one FinancialBook transaction: `debit Inventory:grain +28, credit Production_Output_Value +28`. Similarly, wage accrual is one transaction per day: `debit Wages_Expense +4, credit Payable:{worker} +4`. The books remain clean; auditors see day-level events.

**The query path for "show me what happened in slot 2 of yesterday's WorkDay":**

```
yesterday_day = actor.completed_activities[yesterday_id]
slot_2 = yesterday_day.child_activities[2]

// Activity data directly queryable:
grain_from_slot_2 = slot_2.grain_produced  // 7 grain
xp_from_slot_2 = actor.books["skills"].entries("farming", slot_2.started_tick, slot_2.closed_tick)  // [JournalEntry(farming, +12)]
fatigue_from_slot_2 = actor.books["vitals"].entries("fatigue", slot_2.started_tick, slot_2.closed_tick)  // [JournalEntry(fatigue, +2)]

// Display: "Slot 2 of yesterday: 7 grain produced, 12 farming XP gained, fatigue +2"
```

The day-level FinancialBook entry is separate and higher-level: "Day closed: 28 grain produced, wages accrued 4." A financial auditor never needs to see the slot-level transaction; the player's activity history does.

**Why this is architecturally sound:**

The axiom I held in Round 1 was correct — **books should only record outcomes that matter at their resolution level**. I now see that "resolution level" is not universal; it is book-type-specific. SkillsBook and VitalsBook are observational books; they capture moment-by-moment behavioral data and are best written at the moment of causation (slot close). FinancialBook is a settlement book; its natural resolution is the work-day event. This is not inconsistency — it is honoring the semantic weight of each book.

The activity tree carries the detailed record; the books carry the aggregated summaries at the right level. Save/load works identically: `WorkSlotActivity` is a Resource and persists with its `grain_produced` field. FinancialBook entries are Resources in the journal. Both survive load.

**What Samus wins here:**

Slot-level moments remain legible indefinitely. A player can inspect yesterday's work and see "slot 2 was fatigue-heavy, grain-light, high XP"; the activity tree guarantees this without FinancialBook reconstruction logic. The WagePaymentActivity record is per-participant in the SkillsBook and VitalsBook if relevant, and as a day-level FinancialBook entry if audit is the goal. The "between slots" moment is observable as a null activity or rest activity if we choose to model it, and the player can ask "what was my fatigue at slot 2 close?" without ambiguity.

**Cost:**

SkillsBook and VitalsBook grow by 4× (4 slot entries per day instead of 1 aggregate). This is acceptable; these books are smaller than FinancialBook and v0 will not hit pruning concerns. The query interface remains unified: `book.entries(account, tick_start, tick_end)` returns the atomic writes regardless of which book or aggregation level.

**R2.1 synergy:**

Since aptitude weights now live on `WorkSlotActivity` (the activity type carries the weights), each slot writes its own aptitude-adjusted XP. There is no ambiguity about which weights applied to which slot — the formula is on the activity that closes. This actually strengthens the per-slot write case: if weights differ by activity type or context, per-slot writes are the only honest record.

This is the architecture that gives both legibility and correctness.
