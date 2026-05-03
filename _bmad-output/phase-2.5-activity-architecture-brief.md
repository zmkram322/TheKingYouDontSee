---
name: Phase 2.5 — Activity Architecture Session Brief
status: brief (pre-session — not yet directive)
date: 2026-05-03
inputs:
  - _bmad-output/phase-2-architecture-directive.md
  - _bmad-output/phase-2-math-directive.md (both sections)
  - C:/Users/zachm/.claude/plans/drifting-dazzling-flask.md (Phase 2 implementation as shipped)
  - tkyds-game/scripts/ (Phase 2 code as it stands at session start)
  - This conversation's cost-basis ordering exchange (Cloud's recommendation paper)
purpose: |
  Capture the seed of a proposed architectural rebuild around a first-class concept
  of "activity" in the simulation. The Phase 2 math implementation surfaced a
  brittleness pattern (cost-basis cracks under orchestrator reordering) that points
  to a deeper missing primitive. This brief is a session prep doc — not yet
  a directive — to ensure a future fresh session can pick up cold and produce real
  architectural decisions, not just analysis.
participants_planned:
  - Cloud Dragonborn (Game Architect) — required
  - Samus Shepard (Game Designer) — required, for player-legibility framing
attendees_deliberately_excluded:
  - Mary (single-pass economic vetting) — invite only if activity model materially shifts the economic clearing logic
  - Indie (v0 pragmatism) — invite only if Cloud+Samus's design exceeds prototype scope
---

# The Seed

The Phase 2 math implementation works. All five acceptance criteria pass on the 14-day headless trace. But the implementation rests on a foundation that the author identified as untenable for scale, and that diagnosis is correct.

The current model: behaviors are wired to bus signals, the orchestrator emits signals in a sequence, and correctness depends on humans remembering which signals must precede which others. The cost-basis bug surfaced when a signal reorder silently produced wholesale_price = 0.00 (free grain) — no error, no assertion, just wrong numbers in a passing-looking trace. Cloud's response paper proposed a phase-grouped burst + rollover pattern as the immediate fix. The author's deeper read: **the real missing primitive is "activity."**

## The author's framing (verbatim seed)

> "I think it's about a fundamental architectural principle around **activity** in the game. That activity as it closes writes to the necessary systems, demand, supply, etc. Market opening events are calls for supply (so a pull model) whereas calls for demand and recognition of activity is a push model."

Three claims to evaluate:

1. **Activity is a first-class primitive.** Not a bus signal, not an Interest method — a named, lifecycled thing in the simulation. Every meaningful state transition in the game is an activity (fine-grained, per the author's scope decision).
2. **Activities push their effects on close.** When a work-day activity closes, it writes its outputs (grain produced, slots worked) to the appropriate ledgers/markets. When a wage-payment activity closes, it writes its effects (coin transfer, cost ledger entry). The activity OWNS knowing what to write. No external coordinator is responsible for "did this fire yet."
3. **Markets are pull-on-open for supply, push-on-arrival for demand.** Asymmetric:
   - When a market opens (or "wakes up to clear"), it actively pulls supply — asks producers "what do you have for me?"
   - Demand is declared by actors as it arises (push) — actor wants something, says so.
   - Activity recognition flows the same way as demand (push): when an activity completes, the world finds out via push, not by some scheduler polling.

## Why this matters more than fixing the cost-basis bug

The phase-grouped burst (Cloud's prior recommendation) is a real fix at the *current* abstraction level. It encodes the existing implicit ordering as explicit phases. That's correct — but it's a patch on a model that doesn't have the right primitives.

If activity is the right primitive, then:

- The orchestrator stops being a sequence of signal emits. It becomes a lifecycle coordinator for activities.
- The Interests stop being "code that listens to signals and mutates ledgers." They become activity declarers / activity participants.
- Cost basis stops being "computed at a specific signal" or even "snapshot at a specific phase." It becomes "the natural read over completed-activity outputs and costs, queryable by anyone whenever the activity has closed."
- The brittleness goes away because the activity itself owns its effects, not a coordinating signal.

This is foundational. Doing it after Phase 3 lands more economy work means refactoring more code. Doing it now (as Phase 2.5) means a clean reset on the timing model before adding aptitudes, hunger, and more goods.

---

# Open Design Questions

The session must answer most of these. They're the real work, not just framing.

## Q1 — What IS an activity, structurally?

Author committed to fine-grained scope: "any discrete unit of behavior at any scale, including instantaneous ones. Could include 'place an order', 'pay a wage', 'gain 1 grain.' Lots of activities, hierarchical."

Candidate definition to test:
> An activity is a named, lifecycled unit of behavior that has (a) a beginning, (b) an end, (c) effects that materialize on end, and (d) participants. Activities can contain sub-activities.

Open:
- Is "gain 1 grain" really an activity, or is that just a side-effect of the "do one work slot" activity?
- Is the weekly burst itself an activity, or an orchestrator concern?
- Does "instantaneous activity" make sense, or is duration mandatory?
- How do hierarchical activities propagate effects — does parent close trigger child close? Or vice versa?

## Q2 — Activity as code: class? Resource? Just a pattern?

Three implementation shapes to consider:

(a) **Activity as a base class** like Interest. `class_name Activity extends RefCounted` (or Resource), with virtual `begin()`, `end()`, `effects: Array[Effect]`. Each kind of activity (WorkSlotActivity, WagePaymentActivity, OrderPlacementActivity) is a subclass. Activities are owned by Interests or by the simulation directly.

(b) **Activity as a Resource holding state**, with the BEHAVIOR living elsewhere (in the Interest that initiates it). Activity is a record of "this happened" rather than a runtime object.

(c) **Activity as a discipline, not a class**. Document the pattern in code comments and naming conventions; don't add new types. Each Interest method that mutates ledgers wraps its work in a "begin/effects/end" structure but there's no shared base.

Cloud's instinct: probably (a), because it gives us a place to hang shared lifecycle code (like the rollover question, audit trace, save/load alignment, etc.) and because hierarchical composition needs structural support. But this is exactly the kind of "do we add a new primitive" call that needs Samus's player-facing read too — does activity-as-class help or hurt the legibility surface?

## Q3 — How do markets pull supply on open?

Today: producers push supply into supply_pool when they feel like it (in Phase 2 math, on weekly_books_close). Market clears whatever's there.

Author's proposed model: market open = pull. Market actively asks each registered supplier "what do you have for me?"

This needs:
- A registry of "who could supply what" per market. (Today this is implicit — anyone with a `wholesale_market` reference and the will to push.)
- A `supplier.respond_to_market_open(market) -> SupplyOffer` interface.
- Decision: does the market call each supplier in order, or does each supplier register a pull-handler at startup?

Cloud's question for the session: is the pull model *better* than the push model, or does it just move the brittleness? If a market polls supplier X before supplier X has finished its weekly production activity, the pull returns nothing. Solving "did the activity close yet" via pull instead of push doesn't obviously help — unless activities have explicit "is this activity complete for the period" state that suppliers can reflect.

Likely answer: pull-on-open works *if* activities have queryable lifecycle state. Supplier responds to pull with "yes, weekly production activity closed, here's what I'm offering." If the production activity isn't closed yet, the response is "not ready" — and the market knows to either wait or proceed without that supplier.

## Q4 — Demand & activity recognition as push

Author's model: demand and activity recognition flow as push (actor → world). Demand-push is already the pattern (GrainInterest pushes retail demand). Activity recognition push is new — when an activity completes, the actor declares it.

Candidate mechanism: an `ActivityCompleted` event/signal carrying `(actor, activity, effects)`. Anyone interested subscribes (markets for supply/demand updates; ledger-writers for cost/output recording; aptitude system for XP gain; observability for trace logging).

Open:
- Is this a global bus or per-region or per-actor?
- Does the activity itself emit, or does the actor on its behalf?
- Effects bundle: structured (typed Effect resources) or loose (Dictionary of changes)?

## Q5 — What about activities that span time (not just instantaneous)?

A work-day activity opens at MID_MORNING and closes at EARLY_EVENING. During its lifetime, it accrues grain. On close, the accrued grain becomes the activity's effect.

Today this is modeled as: WorkingInterest has `slots_worked_today` field, increments on each `do_one_work_slot` call, resets in `deliver_grain_and_bill`. There's no "activity" object — the state is on the Interest.

In the activity model, would this become an explicit `WorkDayActivity` resource that lives for the duration of the work day, accumulates effects internally, and writes them out on close? Or stays on the Interest with `slots_worked_today` representing the in-flight activity state?

This question matters because it determines whether activities are first-class objects or whether they're just a discipline applied to Interest methods.

## Q6 — How does this interact with the rollover / phase pattern?

Cloud's prior recommendation (rollover buckets + three-phase burst) was the right fix at the current abstraction. If we move to activity-centric, does the rollover go away? Or does it stay as the *implementation* of "activities completed in last period vs. activities currently in flight"?

Likely: activities subsume the rollover. `last_completed_period_outputs` becomes "outputs of activities that closed in the last period." Same data, different mental model. The rollover step becomes "activity period boundary" and the buckets become "in-flight activities" vs. "completed-this-period activities."

## Q7 — Player legibility (Samus's domain)

If activity becomes a first-class concept, it's also a player-facing one. The player can SEE actors doing activities (work, shop, hire, trade). The player's observation primitive (LISTEN → INFER → COMPOSE → DISRUPT) might become "observe activities."

Open:
- Do activities have observable properties (visibility, duration, participants)?
- Does activity recognition push include "which observers can see this"?
- Does this give us the substrate for the tail-events system the GDD wants (escalation thresholds = high-volatility activity types)?
- Does it give us a clean shape for the journal / first-touch contextual layer?

Samus's input is required here. Cloud's bias is "activities are infrastructure"; Samus's bias is "activities are the player's epistemology." Both are true and the design has to honor both.

## Q8 — Out of scope for this session (explicit)

Not in scope; surface but defer:

- **Re-implementing markets** under the new model. Session produces a directive; coding pass comes after.
- **Changing the bus signal API or removing WindowBus**. The activity model may make some signals vestigial, but the session's job is the architecture, not the cleanup.
- **Save/load implications**. Note them; don't design them in this session.
- **Multi-region / multi-actor activity coordination**. v0 has 4 actors in 1 region; that's the design surface. Phase 3+ scaling stays in backlog.
- **Aptitude / hunger / XP integration**. They consume activity effects (XP from completed work activity, hunger from time without eating activity). Note the integration points; design them in their own sessions.

---

# What "Done" Looks Like for the Session

The session has succeeded when the author has, in writing:

1. **A definition of `Activity`** (concrete enough that a coding agent can implement it).
2. **A decision on Q2** (class? Resource? discipline?).
3. **The lifecycle contract** — what `begin`, `end`, and `effects` mean precisely.
4. **The push/pull asymmetry resolved** — concrete answer to Q3 (market pull-on-open) and Q4 (demand & activity push).
5. **A migration mapping** — how each current Phase 2 Interest method becomes an activity declaration. Specifically:
   - `do_one_work_slot` → ?
   - `deliver_grain_and_bill` → ?
   - `pay_outstanding_wages` → ?
   - `place_buy_order_at_wholesale` → ?
   - `register_for_retail_clearing` → ?
   - `settle_weekly_production` (the dead method) → ?
   - Each market's `clear()` → ?
6. **A confirmation that the cost-basis bug class is structurally eliminated** under the new model. Not just "this specific bug fixed" — the pattern that produced it.
7. **A list of follow-on directives needed** before a coding pass begins (e.g., a fresh architecture directive, possibly a fresh math directive if the activity model changes pricing semantics).

The session does NOT need to produce code. It produces a directive (or two), the same way the Phase 2 architecture directive produced a refactor plan that informed the math directive that informed the implementation.

---

# Recommended Pre-Reads (in order)

For the future session's orchestrator (Claude or otherwise) to load before launching Cloud + Samus:

1. **This brief.** Sets the seed.
2. **`_bmad-output/phase-2-architecture-directive.md`** — the persistence-vs-transience principle that the activity model must respect or replace.
3. **`_bmad-output/phase-2-math-directive.md` (Sections 1+2)** — the math the activity model must still produce correctly.
4. **`C:/Users/zachm/.claude/plans/drifting-dazzling-flask.md`** — the Phase 2 implementation plan, including the 9 architectural decisions (A1–A9). Some of those decisions (especially A2 ledger pattern and A4 settle_weekly_production) get reconsidered.
5. **The cost-basis ordering exchange** in this conversation, including Cloud's recommendation paper. The phase-grouped burst + rollover proposal is the *fallback* — what we'd ship if the activity rebuild is too ambitious for this session. Hold it as a known-good safety net.
6. **GDD's LISTEN → INFER → COMPOSE → DISRUPT framing** (project memory, "Core Concept" section). Samus will pull this in for player-facing work.

---

# Session Format Suggestion

Two rounds, mirroring the Phase 2 math session:

**Round 1 — independent papers.**
- Cloud writes "Activity as a primitive — architecture proposal" (~1500 words). Concrete shapes.
- Samus writes "Activity as the player's verb — game-feel proposal" (~1000 words). What it means for the player to see actors doing activities.
- Neither sees the other's paper first.

**Round 2 — adjudication round.**
- Author reads both. Identifies real disagreements.
- Cloud and Samus get one revision each, responding to each other.
- Author adjudicates anything still unresolved.

**Output: a single Phase 2.5 Activity Architecture Directive** that supersedes the relevant pieces of the Phase 2 architecture directive and the Phase 2 math implementation plan. The directive informs a coding pass that REPLACES the current Phase 2 implementation, not extends it.

---

# How This Session Should Be Triggered

The author should explicitly invoke this brief at session start with something like:

> "Let's run the Phase 2.5 activity architecture session per the brief at `_bmad-output/phase-2.5-activity-architecture-brief.md`. Spin up Cloud and Samus in parallel for round 1."

This brief is the entry point. Loading it gives the new session everything it needs to begin without re-deriving the seed.

---

# Why This Brief Exists Instead of Just Doing It Now

Three reasons, captured for the next session:

1. **Context discipline.** The current conversation has a working Phase 2 trace, a successful coding pass, and a freshly-written Plan file. Doing a deep architectural rebuild in this same session risks mixing the "we just shipped working code" energy with the "we're about to invalidate that code" energy. Cleaner with a fresh session.

2. **The author's pattern.** Three times in this conversation, the author has surfaced a deeper architectural concern after the immediate question was resolved. The pattern is: implement, see how it feels, identify what's brittle, design the next layer. That pattern works — but only if the design rounds are their own contained sessions, not afterthoughts to coding rounds.

3. **Cloud's read.** This isn't a quick-fix question. The activity model touches every Interest, every market, the orchestrator, the bus, and probably the Accounts shape. A rushed session produces a bad directive. A focused session produces a foundation worth pouring concrete on.

— Cloud
