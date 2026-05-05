---
name: Design Parking Lot
status: passive — captured but not actively tracked
date_started: 2026-05-04
relates_to:
  - _bmad-output/prototype-completion-roadmap.md §6 (move-in source)
  - _bmad-output/phase-3-backlog.md (sibling — items WITH a v0 seam)
purpose: |
  Items rejected from the active backlog because they lack a load-bearing
  v0 seam, but worth capturing so we don't lose the thought. These are
  candidates for the elicitations to either scope concretely (then they
  graduate to a phase plan or to the backlog), or formally drop.

  The bar for entry: it's a real design idea worth remembering, but
  there's no current code seam that earns its keep, and no phase has
  scheduled it. If a phase plan picks one up, MOVE the entry into that
  phase's directive and delete it from here.
---

# Design Parking Lot

---

## ReputationBook

**What:** A fourth Book type for the actor's `accounts.books` dictionary, alongside Financial / Skills / Vitals. Captures what the actor knows about other actors — trust, esteem, witnessed events, gossip-acquired reputation.

**Why parked:** No v0 consumer. Phase 2.5 directive named the slot (`books["reputation"]` — Phase 3+ may add) but didn't define accounts, accumulation rules, locality (per-pair vs. per-actor), or decay.

**Pickup candidate:** Elicitation F (Social + Morale + Reputation) — may produce a concrete shape, at which point this graduates to Phase 9 (or wherever the Phase Plan lands social).

---

## Player-knowledge graph

**What:** A persistent record of which counterparty IDs the player has resolved to display names, which actors they've encountered, which witnessed events they've accumulated. The infrastructure that backs the *"why is Lord Harwick paying rival_lord_castellan?"* mystery — and the path from `&"rival_lord_castellan"` to *"Lord Eddard of Westhold"*.

**Why parked:** Design pillar from project memory ("Counterparty mystery" section of macro-legibility orientation) but no v0 seam. The Activity / Books primitives carry counterparty StringNames already; the resolution layer is what's missing, and it touches knowledge as a first-class concept.

**Pickup candidate:** Elicitation E (Macro-Legibility Primitives) is the place where this gets scoped — autoload service vs. per-actor field vs. per-Region store; how it interacts with the precision tiers. May graduate to Phase 7 or be split across phases.

---

## Diegetic vocabulary surfacing

**What:** `Activity.display_name: StringName` exists as a reserved field, currently never set, never read. The intent: a UI surface that translates `WorkDayActivity → "Bob worked a full day at the field"`, `RetailPurchaseActivity → "Bob bought four sheaves of grain"` — moving from the engineering vocabulary to the diegetic one.

**Why parked:** UI-layer concern. v0 has no UI, so display strings are pure overhead. The seam exists (the field) but the consumers don't.

**Pickup candidate:** Elicitation E may scope tone calibration and where strings get set (per-class `_init`, per-locale registry, etc.). Picked up when the first observation UI lands (Phase 8 in the provisional ordering).

---

## War (military system)

**What:** A future system covering raised retinues, soldier wages, casualties, supply chains, sieges, raids. Touches every existing primitive: actors with `MilitaryInterest`, `RetinueContract` (cousin to LaborContract), `MarchActivity` / `BattleActivity` (persistent activities with transient slot-equivalents), book entries for casualties + readiness + supply, regional risk modulating travel/trade.

**Why parked:** No v0 consumer; nowhere near prototype scope. But the architecture must remain compatible — the persistent-vs-transient activity rule, force-carrier book writes, and population API are general by design and should accommodate war as a sibling system without re-architecting.

**Pickup candidate:** Far downstream — likely post-Phase-5 vertical-slice work or beyond. Recognized here to keep the foundation compatibility-checked. Elicitation E explicitly verifies its population API + inference layer don't preclude this.

---

## Export / Import (cross-region trade)

**What:** Multi-region trade: caravans moving goods between markets at different prices, regional supply gluts feeding regional scarcity, traders earning on the spread. Touches: regional `LaborMarket` / `WholesaleMarket` / `RetailMarket` instancing (already partially scoped in `phase-3-backlog.md`), travel as activity primitive, region-pair book entries for cross-region transfers.

**Why parked:** v0 has one region. Multi-region is on the architecture roadmap (regional `LaborMarket` is a backlog item) but cross-region trade as a player-meaningful system is beyond prototype scope.

**Pickup candidate:** Likely after Phase 5 (multi-good economy) and after Phase 7+ (some legibility infrastructure). Recognized here so Elicitation C (multi-good) and E (legibility) verify their decisions don't preclude cross-region trade as a future sibling. The population API in particular should generalize from "actors at this employer" → "regions exporting this good."

---

## Book-access gates by precision level

**What:** When one actor reads another's books (or any aggregated population query), the precision returned should depend on the observer's investment / source / relationship. Player's own books = precise. A rumored claim from a tavern overhear = noisy float or coarse enum bucket. A bribed steward = mid-precision.

**Why parked:** Real architectural concept, but every implementation choice (enum tiers? noisy float? range pair? per-account-type?) is open. v0 ships precise reads everywhere because there is no observer model yet.

**Pickup candidate:** Elicitation E will define the precision-tier shape and where it lives (a `book.balance_with_precision(observer, account, period)` API, a wrapper layer, or a per-book gate). Picked up when player UI starts demanding non-precise reads.

---

## How to use this file

When an elicitation or phase plan picks up an item, **move** the entry into that phase's directive (or the phase plan) and delete it here. The parking lot is a holding area, not a permanent store.

If a parked item becomes load-bearing for an architectural seam, promote it to `phase-3-backlog.md` instead — that's where items WITH seams live.
