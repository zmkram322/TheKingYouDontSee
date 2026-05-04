---
name: Phase 2.5 — Books, Activity, & Force Carriers Session Brief
status: brief (pre-session — not yet directive)
date: 2026-05-03
inputs:
  - _bmad-output/phase-2-architecture-directive.md
  - _bmad-output/phase-2-math-directive.md (both sections)
  - C:/Users/zachm/.claude/plans/drifting-dazzling-flask.md (Phase 2 implementation as shipped)
  - tkyds-game/scripts/ (Phase 2 code as it stands at session start)
  - This conversation's cost-basis ordering exchange (Cloud's recommendation paper)
  - Author's Phase 2.5 reframing (this conversation, post-cost-basis-paper)
purpose: |
  Capture the seed of a foundational rebuild that consolidates three missing primitives
  the Phase 2 implementation surfaced: (1) no first-class concept of activity in the
  simulation, (2) no proper per-actor books — the current Accounts shape is an ad-hoc
  bag of fields, (3) no force carrier for XP (or for any other non-financial effect).
  These three are facets of one architectural gap. This brief is a session prep doc —
  not yet a directive — so a future fresh session can pick up cold and produce real
  decisions, not just analysis.
participants_planned:
  - Cloud Dragonborn (Game Architect) — required
  - Samus Shepard (Game Designer) — required, for player-legibility framing
attendees_deliberately_excluded:
  - Mary (single-pass economic vetting) — invite only if the books model materially
    shifts pricing/clearing semantics beyond what Phase 2 math established
  - Indie (v0 pragmatism) — invite if Cloud+Samus's design exceeds what the prototype
    can absorb in one coding pass
acknowledged_tradeoff:
  Per-actor books mean every actor carries a journal of every entry ever made against
  any of their accounts. Save files grow with population × playtime. Author has
  considered this and accepts it: there is no clean alternative that preserves
  queryability and integrity. Pruning policy (rolling window? per-period checkpoint?
  archive to disk?) is a phase-3+ concern, not a session blocker.
---

# The Diagnosis (Why a Phase 2.5 Exists at All)

The Phase 2 math implementation works — all five acceptance criteria pass on the 14-day headless trace. But shipping it surfaced three architectural gaps that all manifest as the same kind of brittleness:

1. **No first-class activity.** Behaviors are methods on Interests wired to bus signals. Correctness depends on humans remembering signal-emit order. The cost-basis bug exposed this — a user-driven orchestrator reorder produced `wholesale_price=0.00` (free grain) silently. No error, no assertion, just wrong numbers in a passing-looking trace.

2. **No proper books.** `Accounts` is `{coin: int, inventory: Dict, contracts: Array, payables: Array, receivables: Array, weekly_costs: Dict, weekly_outputs: Dict, skills: Dict}` — an ad-hoc bag of fields that grew as needs arose. Every new effect category becomes another field. Every read becomes a custom query. Cost basis lives as a derived field on ProductionInterest because there's no general way to ask "what costs accrued this period." Inventory deltas can't be audited because they're direct mutations, not entries.

3. **No force carrier for XP.** `accounts.skills` exists as an empty dict. No code writes to it. The directive flagged "phase 3+ XP-emit code populates" as a placeholder. There is no architectural answer to *how* XP gets generated when work happens — and the same gap exists for hunger, morale, reputation, every non-financial effect. They have no source.

These three are facets of one missing primitive. The Phase 2 implementation runs because we wired around them. The cost-basis bug, the empty skills dict, and the messy Accounts shape are the same problem at three angles.

---

# The Three Pillars (What This Session Designs)

## Pillar 1 — Per-actor books (parallel ledgers per category)

**Author's framing (verbatim seed):**
> "Use debits and credits like a financial accounting system to record the books appropriately. If everyone has their own books, it makes it easy to create actions off of those books or valuations off of them."

**Author's scope decision:** parallel ledgers per category, not one unified ledger. Each ledger follows ledger semantics (chart of accounts, journal of entries, query interface) but is its own structure on the actor.

**v0 books (proposed for the session to validate):**

- **`FinancialBook`** — strict double-entry. Every transaction is balanced (sum of debits = sum of credits). Chart of accounts: Cash, Inventory[good_id], Receivable[counterparty], Payable[counterparty], Wages_Expense, Wages_Income, Cost_of_Goods_Sold, Production_Output_Value, Lord_Tax_Expense, etc. Replaces `coin`, `inventory`, `payables`, `receivables`, `weekly_costs`, `weekly_outputs` from current `Accounts`.

- **`SkillsBook`** — entries credit XP to a skill account when work activities close. Account = skill name (`farming`, `bartering`, `market_perception`). Entry = `(activity_ref, +N XP)`. Replaces `accounts.skills` dict. Force carrier for XP.

- **`VitalsBook`** — entries debit/credit hunger, morale, fatigue. Activities (eating, working, sleeping) write to this. Force carrier for hunger.

- **`ReputationBook`** — phase 3+, but the slot exists.

**The win:** every state mutation becomes a journal entry. Cost basis becomes `book.balance(Cost_of_Goods_Sold, period)` — a query, not a derived field that needs cache + reset + signal-ordering. Inventory delta becomes auditable. Save/load becomes "serialize the books." Adding a new cost category becomes "add an account to the chart" — no other code changes.

**The cost:** save files grow with population × playtime × entries-per-period. Author has accepted this. Pruning is phase 3+.

## Pillar 2 — Activity as first-class primitive

**Author's framing (verbatim seed):**
> "A fundamental architectural principle around activity in the game. Activity as it closes writes to the necessary systems, demand, supply, etc. Market opening events are calls for supply (so a pull model) whereas calls for demand and recognition of activity is a push model."

**Author's scope decision:** fine-grained — any discrete unit of behavior at any scale, including instantaneous ones. Hierarchical. Activities can contain sub-activities.

**Activity as the bridge between the simulation and the books:** when an activity closes, it writes journal entries to participating books. No more "Interest method directly mutates ledger field." Mutations only happen via activity-close → journal entry.

**Push/pull asymmetry the author committed to:**
- Activity recognition pushes (actor → world): activity-close emits notice + writes book entries.
- Demand pushes (actor → market): consumer says "I want X" when the want arises.
- Market open *pulls* supply: market asks producers "what do you have for me?" Suppliers respond based on activity completion state — "yes, my weekly production activity has closed, here's my offer" or "not ready yet."

**The win:** activities own knowing what to write to which books. No coordinator needed. The cost-basis bug class disappears because cost basis is a query over the financial book, not a value computed at a specific signal moment.

## Pillar 3 — Force carriers (the source of every effect)

Every effect category in the game needs an architectural answer to "where does this come from?" Currently:

| Effect | Current source | Status |
|---|---|---|
| Coin | Direct mutation in market clear methods | Works, untraceable |
| Inventory | Direct mutation in market clear methods | Works, untraceable |
| XP | Nothing | **No source** |
| Hunger | Nothing | **No source** (no system yet) |
| Morale | Nothing | **No source** (no system yet) |
| Cost basis | Computed at weekly_books_close | Brittle (the bug) |
| Reputation | Nothing | **No source** |

**The unified answer:** force carriers for every effect are activities. Each activity declares which books it writes to and what entries it produces. XP comes from work-slot activities closing. Hunger comes from time-without-eating activities (or eating-activity absence). Morale comes from social/economic outcome activities. Cost basis emerges as a financial-book query — no separate force needed.

This is the third pillar because without it, "activity" is just a refactor of method calls. With it, activity becomes the *only* way state changes — which is what makes the books trustworthy as the system of record.

---

# How the Three Pillars Connect

```
ACTIVITY                 BOOKS                    EFFECTS
(when, what, who)   →   (record of what          (queryable state:
                         changed, balanced)        coin, XP, hunger, ...)
                              ↑
                              │
                         Force carriers:
                         activity-close writes entries
```

A worker working a slot:
- ActivityType: `WorkSlotActivity`
- Participants: worker, employer, plot
- Effect on close: `worker.SkillsBook.credit(farming, +1 XP)`; produced grain accrues toward the day's `WorkDayActivity` parent

A worker delivering at end of day:
- ActivityType: `WorkDayActivity` (close)
- Participants: worker, employer
- Effect on close:
  - `employer.FinancialBook.entry({debit: Inventory[grain] +N, credit: Production_Output_Value +N})`
  - `employer.FinancialBook.entry({debit: Wages_Expense +slots, credit: Payable[worker] +slots})`
  - (Or: defer the wage entry to the wage-payment activity. Design call.)

A wage-payment activity (in burst):
- ActivityType: `WagePaymentActivity`
- Participants: employer, worker
- Effect on close:
  - `employer.FinancialBook.entry({debit: Payable[worker] -coin, credit: Cash -coin})`
  - `worker.FinancialBook.entry({debit: Cash +coin, credit: Wages_Income +coin})`
  - Both entries balance. Both books stay consistent.

Cost basis for the period:
- `employer.FinancialBook.query(account: Wages_Expense, period: last_completed)` → 56
- `employer.FinancialBook.query(account: Production_Output_Value, period: last_completed)` → 56
- `cost_basis = wages / output = 1.0`
- No cache, no signal, no order. The query is the truth.

The cost-basis bug **cannot exist** in this model. There's no "did the snapshot fire yet" because there's no snapshot — the entries are timestamped on write, and the query filters by period. Reorder anything in the burst and the books still reconcile.

---

# Open Design Questions

Each pillar generates real questions. The session must produce concrete answers (or explicit "deferred to phase 3+" decisions).

## P1 — Books

**P1.Q1 — Strict double-entry, or journal-style with looser balancing?**

Strict: every transaction is two balanced entries (debits = credits). Forces clean account design. Catches errors (unbalanced entries fail loudly). Standard accounting.

Journal-style: entries are "this account changed by N." Looser. Easier to write entries that don't have a natural counterparty (e.g., production output — what's the credit side?).

Author's stated preference: strict ("actually use debits and credits like a financial accounting system"). But strict needs a clear chart of accounts and conventions for tricky cases (production, decay, spoilage, gifts). Session should validate or relax.

**P1.Q2 — What's the chart of accounts for v0 FinancialBook?**

Concrete proposal to validate:
- Asset accounts: `Cash`, `Inventory[grain]`, `Receivable[counterparty]`
- Liability accounts: `Payable[counterparty]`
- Equity accounts: `Owner_Equity` (initial coin)
- Revenue accounts: `Wages_Income`, `Sales_Revenue`
- Expense accounts: `Wages_Expense`, `Cost_of_Goods_Sold`, `Lord_Tax_Expense`

Worker's chart is leaner than landowner's. Merchant has its own. Should each actor type have a default chart, or do all actors share a universal chart and just don't use accounts they have no entries for?

**P1.Q3 — How does query work?**

`book.balance(account, as_of_date) -> int` — walking the journal, summing debits-credits up to the date.
`book.balance(account, period_start, period_end) -> int` — period activity in an account.
`book.entries(account, period) -> Array[JournalEntry]` — raw entries for the period.

Performance: walking the full journal on every query is O(n) per query. For v0 (14 days, ~hundreds of entries) it's nothing. For phase 3+ (multi-year sims) need indexing. Note as deferred.

**P1.Q4 — How are SkillsBook and VitalsBook different from FinancialBook?**

Skills doesn't have natural double-entry semantics (XP is created from nothing — no counterparty). Vitals could be modeled as "Hunger account, debited by eating activities, credited by hunger-tick activities."

Three options:
- (a) All books inherit a base `Book` class with the same entry/query interface; only FinancialBook enforces balanced-debit-credit. Skills and Vitals use the same machinery without the balance constraint.
- (b) Skills and Vitals are simpler structures (running totals + entry log) that don't pretend to be ledgers.
- (c) Skills and Vitals follow ledger discipline by adding a "void" account that absorbs unbalanced entries (XP credited; Void debited).

Cloud's instinct: (a) — shared base, FinancialBook adds balance enforcement on top. Most consistent. Session validates.

## P2 — Activity

**P2.Q1 — Activity as a class? Resource? Pattern?**

(a) `class_name Activity extends RefCounted` with virtual `begin()`, `end()`, `effects()`, `participants`. Subclassed per activity type.

(b) `class_name Activity extends Resource` — same shape but persistable for save/load.

(c) Discipline only — code organization convention, no shared base.

Cloud's instinct: (b) Resource. Persistable activities mean in-flight activities survive save/load. Hierarchical structure works as a tree of Resources. The cost is a small one (~50 lines of base class).

**P2.Q2 — Activity lifecycle hooks**

What does `begin()` do? `end()`? When does an activity write its book entries — only in `end()`, or progressively during its lifetime?

Proposal to validate: activities accumulate effects in-flight (in fields on the activity object), and write all entries to all participating books in a single atomic `end()` call. If `end()` fails (e.g., insufficient funds), the activity rolls back — no entries written.

This gives transactional semantics. Cost: more complexity in `end()`. Win: the books always reconcile.

**P2.Q3 — Hierarchical activities**

A `WorkDayActivity` contains 4 `WorkSlotActivity` instances. Does the day-activity's `end()` cascade to close any open slots? Do slot effects propagate to the day before writing to books, or are they written independently?

This is where the design has to commit. Cloud and Samus may disagree — Cloud will lean toward hierarchical effect aggregation (cleaner audit), Samus will lean toward independent writes (each slot is a player-observable moment).

**P2.Q4 — Pull-on-open for market supply**

When `wholesale_market_opened` fires, market polls registered suppliers. Each supplier responds based on their production activity state:
- If the supplier's `WeeklyProductionActivity` has closed: respond with the offer.
- If still open: respond with "not ready" (or auto-close it now if appropriate).

This requires:
- Supplier registry per market (who could supply what).
- A supplier-side `respond_to_supply_call(market) -> SupplyOffer` method.
- Decision: does failure-to-respond block clearing, or does the market proceed with whoever responded?

## P3 — Force carriers

**P3.Q1 — Mapping: which activities produce which book entries?**

Concrete map for v0 (the session validates / corrects):

| Activity | On close, writes to: |
|---|---|
| `WorkSlotActivity` | Worker SkillsBook: +1 XP farming. Worker VitalsBook: +1 fatigue (future). |
| `WorkDayActivity` | Employer FinancialBook: Inventory[grain] += slots, Production_Output_Value += slots. |
| `WagePaymentActivity` | Employer + Worker FinancialBook entries (wages: expense → cash → income). |
| `WholesaleSaleActivity` | Producer + Merchant FinancialBook entries (grain inventory ↔ cash, COGS ↔ Sales_Revenue). |
| `RetailPurchaseActivity` | Merchant + Buyer FinancialBook entries. |
| `LaborContractActivity` | Both parties' financial books? (Probably no entries — just contract record.) |
| `EatGrainActivity` | Buyer FinancialBook: Inventory[grain] -= 1. Buyer VitalsBook: Hunger -= N. |

**P3.Q2 — Force carriers for non-activity-driven effects**

Some effects don't have an obvious activity. Examples:
- Lord tax — does it come from a `TaxCollectionActivity` initiated by the lord, or is it a side-effect of every WholesaleSaleActivity?
- Inventory spoilage (phase 3+) — is there a `SpoilageActivity` that fires on a timer?
- Hunger increase (the natural drift) — does every time-tick produce a `HungerTickActivity`, or does VitalsBook just decay continuously?

Some of these are clearly best as activities. Others might be properly modeled as continuous functions over time. The session should commit to a rule of thumb.

## P4 — Migration & integration

**P4.Q1 — Mapping current Phase 2 code to the new model**

Each current Interest method becomes (or initiates) an activity, and each ledger mutation becomes a book entry. The session produces this mapping concretely:

- `WorkingInterest.do_one_work_slot` → initiates `WorkSlotActivity`
- `WorkingInterest.deliver_grain_and_bill` → closes the day's `WorkDayActivity`
- `EmployerInterest.pay_outstanding_wages` → initiates+closes `WagePaymentActivity` per payable
- `MercantileInterest.place_buy_order_at_wholesale` → declares demand (push to market)
- `MercantileInterest.send_inventory_to_retail` → declares supply (push to market)
- `WholesaleMarket.clear` → for each match, initiates+closes `WholesaleSaleActivity`
- `RetailMarket.clear` → for each match, initiates+closes `RetailPurchaseActivity`
- `LaborMarket.clear` → for each match, initiates `LaborContractActivity` (and stores it as a long-running activity)
- `ProductionInterest.settle_weekly_production` → **deleted entirely** — its job is replaced by activity-effects writing to FinancialBook + queries replacing cost-basis cache

**P4.Q2 — Does this require dropping Phase 2's working code?**

Likely yes. The activity model touches Interest method shapes, market clear logic, Accounts shape, and the orchestrator. Migrating in place is more work than rebuilding. Session should commit: directive triggers a coding pass that **replaces** Phase 2 implementation, not extends it.

What's preserved across the rebuild:
- Phase 2 math directive (the formulas, calibration, market clearing logic) — still authoritative.
- Phase 2 architecture directive (Interest as transient behavior, Accounts as persistent ledger) — partially. The "Accounts as persistent ledger" principle is preserved, but the *shape* of Accounts becomes books.
- The 5 acceptance criteria — still hold; the rebuild must reproduce the trace numbers.

**P4.Q3 — How do activities interact with the burst orchestrator?**

The burst doesn't go away — there are still events the simulation needs to schedule (wages settlement, market clearings). But the burst becomes an activity-initiator rather than a signal-emitter. `WindowOrchestrator.fire_weekly_burst()` initiates a `WeeklyBurstActivity` which contains sub-activities (wage payments, market clearings, etc.). Each sub-activity opens, runs, and closes — order within the burst becomes the burst's own concern, no longer the world's.

## P5 — Save/load implications

**P5.Q1 — What's serialized?**

- All books (financial + skills + vitals) per actor.
- All in-flight activities (Resource serialization).
- Reference graph (NodePath references to actors persist).

**P5.Q2 — Save file growth**

Author has accepted the tradeoff. Note for phase 3+:
- Pruning policy options: roll up old entries into period summaries; archive entries older than N weeks to disk; keep only the last K periods in memory.
- Defer until first scaling pain.

## P6 — Player legibility (Samus's domain)

**P6.Q1 — Do players see activities?**

If activity is a first-class concept, the player's observation system can report on activities directly. "What is this NPC doing?" becomes "what activity are they currently in?" — a clean read.

**P6.Q2 — Do players see books?**

The book's audit trail is a powerful debugging tool. Should it be a player-facing feature too? "Why is this merchant rich?" → look at their FinancialBook entries. "Why did this worker leave?" → look at their VitalsBook morale entries.

This connects to the GDD's "post-hoc legibility" principle — tail events only land if the player can reconstruct the causal chain. Books *are* the causal chain.

Samus owns this thread. The architecture must not preclude player access to the books, even if v0 doesn't expose them.

---

# What "Done" Looks Like for the Session

The session has succeeded when the author has, in writing, the following decisions and artifacts:

1. **Concrete `Book` base class** — fields, methods, query interface, balance-enforcement decision (P1.Q1).
2. **Concrete `FinancialBook` chart of accounts for v0** (P1.Q2).
3. **Skills/Vitals book shape decision** (P1.Q4).
4. **Concrete `Activity` base class** — fields, lifecycle hooks, hierarchical semantics (P2.Q1, P2.Q2, P2.Q3).
5. **Pull-on-open mechanism** for market supply (P2.Q4).
6. **Activity-to-book-entry mapping for v0** (P3.Q1).
7. **Treatment of non-activity effects** — taxes, spoilage, hunger drift (P3.Q2).
8. **Migration mapping**: current Phase 2 code → new structure (P4.Q1).
9. **Confirmation that the rebuild replaces, not extends, Phase 2 code** (P4.Q2).
10. **Burst orchestrator's new role** under the activity model (P4.Q3).
11. **Save/load notes** captured for phase 3+ (P5.Q1, P5.Q2).
12. **Player-legibility framing** — what's preserved as a player-facing capability vs. internal-only (P6.Q1, P6.Q2).
13. **The Phase 2 acceptance criteria pass** under the new design (numerically equivalent — verified at coding-pass time, but design must commit to reproducing them).

The session does NOT produce code. It produces a **Phase 2.5 Books-Activity-Forces Architecture Directive** that supersedes the relevant pieces of the Phase 2 architecture directive and triggers a coding-pass that replaces Phase 2 implementation.

---

# Recommended Pre-Reads (in order)

For the future session's orchestrator (Claude or otherwise) to load before launching Cloud + Samus:

1. **This brief.** Sets the seed and the three pillars.
2. **`_bmad-output/phase-2-architecture-directive.md`** — the persistence-vs-transience principle. Books *are* persistence — the principle survives but the implementation changes shape.
3. **`_bmad-output/phase-2-math-directive.md` (Sections 1+2)** — the math the rebuild must still produce correctly.
4. **`C:/Users/zachm/.claude/plans/drifting-dazzling-flask.md`** — the Phase 2 implementation plan, including its 9 architectural decisions (A1–A9). Most get reconsidered. The cost-basis pattern (A2 ledger, A3 weekly_books_close signal, A4 settle_weekly_production) is the thing that books-activity-forces replaces.
5. **The cost-basis ordering exchange** in this conversation, including Cloud's recommendation paper (phase-grouped burst + rollover). The phase-grouped-burst pattern is held as a **fallback** — what we'd ship if the books-activity rebuild is too ambitious. Don't lose it.
6. **Project memory `project_thekingdontSee.md`** — locked design decisions, especially three-tier needs hierarchy, dual-clock architecture, and the LISTEN→INFER→COMPOSE→DISRUPT loop. Books and activities have to support these.
7. **`_bmad-output/supplement-prototype-gaps.md`** (per project memory note) — the original aptitude/skill design before Phase 2. The XP force carrier conversation pulls from this.

---

# Session Format Suggestion

Two rounds, mirroring the Phase 2 math session — but expanded scope means longer rounds.

**Round 1 — independent papers (parallel, blind to each other).**

- **Cloud writes the architecture paper** (~2500 words). Three sections, one per pillar:
  - The Books primitive: base class, chart of accounts, query interface, double-entry semantics, save/load shape.
  - The Activity primitive: base class, lifecycle, hierarchical composition, pull-on-open mechanism for supply.
  - The Force Carriers map: which activities produce which entries; treatment of non-activity-driven effects.
  Plus a closing migration section: how Phase 2's code becomes the new structure.

- **Samus writes the player-facing paper** (~1500 words). One section per question:
  - What does the player observe when they see an actor doing an activity?
  - What does it cost the player to read another actor's books? (Skill check? Reputation gate? Always-visible?)
  - How do activities and books support tail-event escalation surfaces from the GDD?
  - What player-facing language does the books/activity vocabulary translate into?

- Neither sees the other's paper first.

**Round 2 — adjudication round.**

- Author reads both. Identifies disagreements (Cloud will lean infrastructural; Samus will lean experiential).
- Cloud and Samus get one revision each, responding to the other.
- Author adjudicates anything still unresolved.
- Author sets v0 calibration: which of the optional pieces ship in the rebuild, which slot for phase 3+.

**Output: a single `phase-2.5-books-activity-architecture-directive.md`** that supersedes the relevant pieces of Phase 2 architecture and authorizes the coding-pass rebuild.

---

# How This Session Should Be Triggered

The author should explicitly invoke this brief at session start with something like:

> "Let's run the Phase 2.5 books-activity-forces session per the brief at `_bmad-output/phase-2.5-activity-architecture-brief.md`. Spin up Cloud and Samus in parallel for round 1. Use haiku for the closing rounds per BMad workflow memory."

This brief is the entry point. Loading it gives the new session everything it needs without re-deriving the seed.

---

# Why This Brief Exists Instead of Doing It Now

Three reasons, captured for the next session:

1. **Context discipline.** The current conversation has working Phase 2 code, a successful coding pass, and a freshly-written Plan file. Doing a foundational rebuild in this same session risks mixing "we just shipped" energy with "we're about to invalidate that" energy. Cleaner with a fresh session.

2. **The author's pattern.** Three times in this conversation, the author surfaced a deeper architectural concern after the immediate question was resolved. The pattern is: implement → see how it feels → identify what's brittle → design the next layer. That pattern works — but only if the design rounds are their own contained sessions, not afterthoughts to coding rounds.

3. **The scope tripled.** The original v1 of this brief was just the activity primitive. The author's reframing added the books primitive and the force-carrier map. Together they're a foundation rebuild, not an architectural tweak. Three pillars need air, not a corner of an existing session.

— Cloud
