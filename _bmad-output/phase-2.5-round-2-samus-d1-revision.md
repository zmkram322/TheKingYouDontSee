---
name: Phase 2.5 Round 2 — Samus D1 Revision (Slot-Level Aggregation)
status: round-2 revision
date: 2026-05-03
author: Samus Shepard (Game Designer)
session: phase-2.5-books-activity-forces
round: 2 (D1-only revision after reading Cloud's Round 1)
model: haiku
position: Option A (Accept with conditions)
---

# Round 2 Revision — D1: Slot-Level Effect Aggregation

**Samus Shepard, Game Designer | Round 2 | 2026-05-03**

**My engagement:** Cloud's Section 2.3 reframes the question in a way I did not fully anticipate. He is not arguing for "collapse slot detail," but for "separate the observation layer from the FinancialBook layer." The activity tree is the audit trail; books are the financial summary. This is cleaner than I predicted. I'm moving to **Option A — Accept, with conditions.**

---

**Why I'm accepting Cloud's framing.**

Cloud's proposal is: `WorkSlotActivity` remains observable (the player sees it exist, track its progress, query its participants). Its per-slot effects (grain produced, XP earned, fatigue accumulated) live on the activity object as fields (`grain_produced`, for example). Those fields are queryable even after the parent `WorkDayActivity` closes. The *FinancialBook* gets the aggregated day-level grain transaction (debit Inventory +28, credit Production_Output), not four separate grain entries. Per-slot XP gets written directly to the SkillsBook per-slot (each slot closes with its own XP credit), which is already what we want — a queryable history.

This is an asymmetry I can live with:
- **SkillsBook writes per-slot.** Each `WorkSlotActivity.on_close()` credits farming_xp. The SkillsBook becomes the per-slot XP audit trail. Perfect.
- **FinancialBook aggregates at the day.** One grain transaction per day, not four. Cleaner, and the per-slot data lives on the activity.
- **Activity tree is the slot-level record.** `actor.active_activities` (or however we surface this) includes the closed slot activities. Query them for `grain_produced`, `fatigue_delta`, `hunger_delta` — all there.

The design elegance here is that activities aren't just lifecycle wrappers; they're **Resources that carry slot-level state**. Activity-as-Resource makes sense under R2.1 too: activity types now hold aptitude-weight parameters (w_ATH, w_CHA, w_INT for farming), so activities are already becoming richer, more authoritative objects. Having them also carry the per-slot outcome fields is a natural extension.

---

**The conditions I require.**

This design works for me if and only if these guarantees hold:

1. **`WorkSlotActivity` fields are first-class queryable, not collapsed after parent closes.** The slot object must remain accessible on the activity tree with its `grain_produced`, `fatigue_cost`, `hunger_cost`, `xp_earned` fields intact. A player UI asking "what happened in slot 2 of yesterday's work?" must be able to read the activity object's fields, not reconstruct them. This is a data-structure guarantee: closed `WorkSlotActivity` instances stay on the parent `WorkDayActivity.child_activities` array, never pruned or collapsed until they're explicitly removed by the activity-retention policy.

2. **Activity tree retention mirrors or exceeds SkillsBook retention.** By D2 adjudication, SkillsBook entries prune last. Activity trees must have the same or longer horizon. This is non-negotiable: if we're replacing per-slot FinancialBook entries with "read the activity tree," the activity tree must be as durable as the SkillsBook. No situation where a player can see "You earned 3 farming XP on day 5" but cannot see the slot activity that produced it.

3. **The player-facing query path is clean and explicit.** The player (or the UI) must have a documented, straightforward way to ask "show me slot-level detail for day N." Concretely: something like `workday_activity.child_activities.filter(...).grain_produced` works, but the path must be in the documentation and accessible without crawling the activity tree by hand. This might mean a helper method on `WorkDayActivity`: `get_slot_grain_breakdown() -> Array[float]` that returns per-slot grain for all children. Without this, we've hidden the data on the activity objects but not made the access path obvious to the player-UI layer.

---

**What breaks if we don't get these guarantees.**

Without condition 1: Closed slot activities become opaque nodes in the tree. The player UI can see "slot 2 exists" but not "what did slot 2 produce?" The activity tree becomes a shape without substance — good for structural audit, useless for player understanding.

Without condition 2: Activity retention policies diverge from book retention. We end up pruning activities faster than the SkillsBook entries they generated, which means the causal link breaks. "I earned 3 XP but the slot activity is gone" is worse than the status quo because it breaks the audit trail at both ends.

Without condition 3: Per-slot detail is technically available but not discoverable. The player UI team asks "how do I show slot-by-slot grain?" and the only answer is "crawl the tree by hand." This invites bugs and makes the UI layer fragile.

---

**Why this moves the needle on player-legibility.**

Cloud's framing gets the player-observation goal right. The player watching a worker in progress sees the slot activities spawn and progress. The player retrospectively asking "why did the lord fall?" can trace grain output to specific work days and (with the tree accessible) to specific slots within those days. The SkillsBook becomes the fine-grained XP audit trail, which is Clean™. The activity tree becomes the slot-level context provider.

The only gap I had in my Round 1 was assuming we'd need per-slot FinancialBook entries. Cloud's insight — "the activity tree is your audit trail at the slot level, books are your financial summary" — is right. I was conflating observability with "must be in a book." Activities solve for observability.

---

**R2.1 Synergy (aptitude weights on activity types).**

This condition-set actually aligns well with the aptitude-weight decision. If `WorkSlotActivity` carries both the aptitude weights (from its type definition) AND the per-slot outcome fields (grain, fatigue, hunger, xp), then activity objects are the complete record of "what kind of work was this, how was it weighted, and what happened." The activity becomes a richer, more authoritative object. This is consistent with Cloud's direction.

---

**My position stated plainly.**

I accept Cloud's architecture for D1 with the three conditions above. The activity tree as the slot-level audit trail, SkillsBook as the per-slot XP summary, and FinancialBook as the day-level financial record is a clean separation of concerns. The player-legibility requirement is met if we commit to (1) durable per-slot activity fields, (2) activity retention parity with SkillsBook, and (3) a documented, accessible query path from day-activity to slot-grain breakdown.

This is good architecture and I'm not fighting it.
