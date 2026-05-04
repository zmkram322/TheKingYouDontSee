---
name: Phase 2.5 Round 1 — Samus Shepard Player-Facing Paper
status: round-1 paper (pre-revision)
date: 2026-05-03
author: Samus Shepard (Game Designer)
session: phase-2.5-books-activity-forces
round: 1 (independent, blind to Cloud)
inputs:
  - _bmad-output/phase-2.5-activity-architecture-brief.md
  - _bmad-output/phase-2-architecture-directive.md
  - memory/project_thekingdontSee.md (locked design decisions)
---

# Player-Facing Paper — Phase 2.5 Books-Activity-Forces
**Samus Shepard, Game Designer | Round 1 | 2026-05-03**

---

**My thesis on player-legibility for this rebuild is this:** activities and books are only as valuable as the player's ability to read them under pressure — ideally under the pressure of trying to understand why something went wrong. The architecture session will be tempted to treat the books model as an audit infrastructure problem and the activity model as a signal-ordering problem. Both framings are correct but insufficient. The books are not just a correct record; they are the player's retrospective lens. Activities are not just a clean mutation pathway; they are the player's real-time window into what the world is doing. If we get the plumbing right and lose the observation layer, we will have built a beautiful filing cabinet in a room with no lights. The test is always: can the player who just watched a lord fall sit down, trace the cause, and feel the satisfaction of understanding? That sequence — LISTEN to the fall, INFER from the books, COMPOSE a response, DISRUPT the next lord — only works if the books are legible and the activities were observable in the first place.

---

## Section 1 — What the Player Observes When They See an Actor Doing an Activity

Activity becoming first-class is a gift to the LISTEN phase. Right now, "what is this NPC doing?" is answered by inference: you see an actor at a work site and you assume. With a first-class activity primitive, the answer becomes a direct read. "What is this NPC doing?" is a query that returns an activity with a name, a duration, and participants. That is the correct foundation for the observation system, and I want to make sure the architecture preserves it as a player-facing query path, not just an internal state variable.

**What the player sees when observing a worker mid WorkSlotActivity.**

The worker is at the field. The player hovers or selects. The UI surfaces something like: *"Working: morning slot (2 of 4 today)."* This is diegetically motivated — you can see a person at work, count the hours. The information is: activity name (in human terms, not class name — more on this in Section 4), progress within the day's arc, and location. Not coin. Not skill values. Those are behind a gate.

The key design question is: what is always visible vs. what requires investment? My position is that the activity itself — the fact of work, its type, its rough progress — is always visible to any observer who is physically present. You can see a man harvesting. The diegetic lock is on the *books*, not on the activity in progress. Activity visibility is proximity-gated (are you there?) and attention-gated (did you look?). Book access is relationship-gated and skill-gated. These are different gates, and conflating them would be an error.

**Observing the gap between slots.**

This is the moment I care most about. A worker finishes a slot and enters a between-slot state. Maybe they rest. Maybe they eat. Maybe they walk to speak with someone. In the current implementation, this gap is invisible — it's just "no signal fired." With first-class activities, the gap is itself an activity (or a deliberate null state). The player who is watching carefully should be able to see: *"Resting between shifts."* This is the simulation's breathing. It is also where hunger, morale, and fatigue should be legible in behavior — a worker who is hungry rests differently than one who is not.

**Watching a WagePaymentActivity resolve.**

This is a burst event, which means it happens fast and the player may not catch it in real time. The observation design must account for this. My position: WagePaymentActivity should leave a visible record on the activity history for each participant — something the player can inspect post-hoc within a short window. "Yesterday: received wages (28 coin)." This is the activity-to-book link made visible at the player layer. The payment happened; the books recorded it; the activity history surfaces it. The player who arrives after the burst and asks "did the wages settle?" gets an answer.

**Where I anticipate disagreement with Cloud.** Cloud will want hierarchical effect aggregation — the WorkDayActivity closes and its effects roll up from the four WorkSlotActivity instances. Clean for auditing. Potentially wrong for the player, because the slot-level moments (each slot is an observable quantum of work) become invisible if they're collapsed into the day's totals. I want the player to be able to see the grain quantity per slot, the fatigue per slot, the XP per slot. That means slot-level activities must remain queryable even after the day-level activity closes — not collapsed away. I will stake this in the closing positions.

---

## Section 2 — What It Costs the Player to Read Another Actor's Books

The books are not a free UI element. They are a player-facing investment mechanic — a capability you build toward across the run, with different costs for different books. This is where the GDD's "Power Is Earned Through Understanding" pillar is most operationally expressed.

**The four books, four gates.**

**FinancialBook** is the most private and legally charged. Reading another actor's financial ledger should require either: a diegetic intermediary (a steward who reports to you, a tax-roll you've bribed access to, a ledger you've physically obtained), or a high `market_perception` skill that lets you infer coin flows from observed behavior. At low perception you see: *"This merchant appears prosperous."* At moderate perception: *"This merchant's margins are thinning — they've bought high twice this week."* At high perception: direct ledger read. The diegetic framing matters because it makes the financial book feel like private information rather than a UI panel.

**SkillsBook** is the most observable book. You can watch someone work and infer their skill level. The observation system should surface skill reads from behavioral outputs: a worker who rarely fumbles, works faster than their peers, gets less fatigued. This is the book the player should be able to read with the least investment — proximity, patience, and maybe a small market_perception check for precision.

**VitalsBook** is behavioral. Hunger reads from posture and movement (slow, distracted). Morale reads from social behavior (avoidance, argument, absenteeism). The player who pays attention to behavior gets the VitalsBook for free, diegetically. The player who wants precise numbers — "this worker is at 34% hunger" — needs medical knowledge or a trusted relationship with the actor (they tell you they're struggling).

**ReputationBook** is gossip. You read it by spending time in taverns, cultivating information sources, commissioning observation of a target. It's the social book and should have the most interesting information-decay mechanics — reputation entries are current as of the last time your source had contact.

**Reading as a player verb you invest in.**

The key design position here is that book-reading is not a passive unlock but an active verb with cost. You choose to spend time and resources building access to particular actors' books. A player who has a steward on their payroll gets regular financial book summaries for the steward's domain. A player who has cultivated a friendship with a lord's grain merchant gets informal VitalsBook and SkillsBook reads. A player who has invested heavily in market_perception gets FinancialBook inference for anyone they trade with.

This means book access is part of the player's build — it is an influence investment in the LISTEN phase that pays off during COMPOSE. The player who hasn't invested can still observe activities in progress but cannot reconstruct the full causal chain because they can't read the books deeply enough.

**The cost asymmetry matters.** A player should be able to read their own books for free, always. Reading the player-character's own FinancialBook should feel like reviewing your own accounts — immediate, complete, no gate. This creates a natural reference point: you know exactly why you're in the position you're in, and the work is understanding why everyone else is in theirs.

---

## Section 3 — How Activities and Books Support Tail-Event Escalation

The GDD's post-hoc legibility requirement is not decoration. It is the design contract for tail events. A lord falling is not a dramatic moment if the player cannot retrospectively understand why. The books and activity histories are the substrate that makes that reconstruction possible.

**Concrete scenario: a lord falls.**

Walk the player through it. The lord — Lord Harwick — has had his grain supply cut. His workers are hungry. His coin is drained. He has missed two tax collections. A rival lord calls in a favor and Harwick is ousted. The player hears about this and starts the reconstruction.

Layer 1 (free, always visible): Activity history — Harwick's production activity has been closing understrength for three weeks. The player can see this from observation records, no book access required. The worker count was visibly low. This is diegetically available — you saw the half-empty fields.

Layer 2 (SkillsBook and VitalsBook — moderate access): Worker skill levels dropped (or never rose). Worker hunger entries show persistent deficit. These books confirm what the behavioral signals suggested. If the player has market_perception investment or a source close to Harwick's workers, they can read these.

Layer 3 (FinancialBook — high gate): Harwick's coin position — the Wages_Expense vs. Cash account drain. The player who has a steward in Harwick's domain, or who has been tracking tax-roll records, can see that Harwick was paying wages out of reserve coin while output revenue was falling. The gap between production cost basis and actual revenue is the exact causal chain. The FinancialBook makes this legible as a query: what did his cost basis look like over the last four weeks?

Layer 4 (ReputationBook — social): The political pressure from the rival lord. This is gossip-layer information — who was pressuring Harwick, what the rival's motive was, which of Harwick's allies had already been flipped. This connects to COMPOSE: can the player reconstruct what a counter-offer would have been worth?

**The payoff for COMPOSE and DISRUPT.** A player who has invested in book access across all four layers now knows: the exact production gap, the coin drain timeline, the worker morale trajectory, and the political context. They can now ask: if I had provided Harwick grain credit at week three, would it have changed the outcome? They can model this. And they can apply this model to the next vulnerable lord — COMPOSE a position that gives them leverage, then DISRUPT at the moment of maximum effect.

**The critical architecture constraint.** The activity histories must persist long enough for this reconstruction to be possible. A tail event that resolves in week six must be reconstructable from activity records dating back to week two or three. The architectural decision on book pruning (noted as phase 3+ in the brief) has player-legibility implications that must not be treated as purely infrastructural. My position: activity histories for observable NPCs should persist at minimum for the current "arc" — however that gets defined — and ideally for the full run. If save-file growth forces pruning, prune financial entries first (compress to period summaries), prune activity histories last.

---

## Section 4 — Player-Facing Language

The vocabulary question is a design decision, not just a naming question. The words the game teaches players to use determine how they think about the simulation. If we use the wrong words at the surface, we train players to think about the wrong things.

**Words that stay hidden behind diegetic terms:**

- "Activity" → never surfaces as the word "activity." It becomes: *work, deal, payment, errand, contract, delivery.* The player does not need to know that the game calls these Activity objects. They need to know that things happen, have duration, and have participants.
- "Book" / "ledger" → never surfaces as "FinancialBook" or "SkillsBook." These become: *accounts, records, rumor, reputation, condition.* "Have you checked his accounts?" is a natural NPC utterance. "Have you read his FinancialBook?" is not.
- "Force carrier" → entirely internal. No player-visible equivalent needed.
- "Journal entry" → "record," "entry," "line in the accounts." Or nothing — the player interacts with the *result* of entries (the balance, the history) not the entries themselves.

**Words that can be player-visible with care:**

- "Slot" — potentially useful if framed as temporal language. But "morning slot" or "afternoon shift" is better than "slot 2 of 4." The player should think in time-of-day, not in index numbers.
- "Skill" — entirely player-safe. "Your farming skill," "his bartering skill" — these are natural vocabulary.
- "Cost basis" — this is the one I'm watching. The player probably doesn't need to see the term "cost basis" ever. What they need to see is "how much it cost him to produce this grain, and what he sold it for." The gap between those two numbers is the story. The term is internal.

**Sample NPC utterances:**

- "I worked four slots today" → *"Had a full day in the fields — morning through late afternoon."* The system uses slots; the world uses time of day.
- "His FinancialBook shows a deficit" → *"Word is Harwick's accounts are in trouble."* Source-attributed, gossip-flavored.
- "WagePaymentActivity completed" → *"The steward came round with wages this morning."* Event surfaced as social fact.
- "VitalsBook.hunger = 0.65" → *"He looked hungry — slow, not talking much."* Behavioral read, no numbers.

**The tradeoff, stated plainly.**

Technical clarity helps players infer system rules. Immersion keeps the world from feeling like a spreadsheet. The correct balance for this game is: surface effects in diegetic language, surface system logic in first-touch tutorial asides (fires once, never again — per the GDD), and surface precise numbers only when the player has built the skill or relationship that earns that precision. The number "28 coin in wages" should feel like information the player worked to obtain — not a free tooltip.

A player who has invested nothing in book access should walk away from the lord's fall thinking: *"I noticed the fields were thin, but I didn't know how bad it was."* A player who built a steward network should think: *"I could see it coming in the accounts three weeks out."* That gap — between the observer who watched and the one who understood — is the game.

---

## Staked Positions and Anticipated Disagreements

**Positions staked:**

1. Activity visibility is proximity-and-attention gated, NOT skill-gated. The fact of work is observable. The books are skill/relationship-gated. These are different locks and must not be collapsed.

2. Slot-level activities must remain queryable after the parent day-level activity closes. Hierarchical aggregation that collapses slot details erases player-legible moments. Oppose any architecture that makes per-slot XP, per-slot grain, or per-slot fatigue irrecoverable after close.

3. Activity histories persist last in any pruning policy. Financial entries can be compressed to period summaries; activity histories are the causal chain substrate.

4. Book access is a player verb with differential cost by book type: SkillsBook (behavioral/cheap), VitalsBook (behavioral/moderate), ReputationBook (social/network), FinancialBook (legal/expensive). Architecture must not expose all books at a flat access cost.

5. No player-visible class names. "FinancialBook," "WorkSlotActivity," "WagePaymentActivity" — none of these surface in the UI. Diegetic equivalents required before v0 ships.

6. The player-character's own books are always free to read, completely. No gate. This is the reference point.

7. WagePaymentActivity and similar burst events must leave a post-hoc readable record for a minimum window. Real-time visibility is not the only access path.

**Anticipated disagreements with Cloud's architecture paper:**

1. Hierarchical effect aggregation. Cloud will design WorkDayActivity to close with aggregate effects from the slot-level children. I will push back if slot-level detail is lost after aggregation. Resolution needed: slot entries must remain queryable independently of whether the parent day-activity has closed.

2. Strict double-entry for all books. I support strict double-entry for FinancialBook. For VitalsBook and SkillsBook, the "void account" solution (option c in the brief) feels like an accounting convention smuggled into gameplay that will confuse the observation model. I prefer the shared base class with relaxed balance constraint (option a) because it keeps the query interface consistent without requiring the player-facing system to maintain a fiction that XP has a counterparty.

3. Activity-as-Resource vs. activity-as-RefCounted. Cloud will lean Resource for save/load. I have no objection on principle, but I want explicit confirmation that in-flight activity observability (the player inspecting an activity that hasn't closed yet) is first-class, not an afterthought to the save/load motivation.

4. Pull-on-open for market supply. No legibility objection — this is clean. But the failure mode (supplier not ready, market proceeds with partial supply) needs a player-visible signal. "Some suppliers hadn't delivered yet" should be a readable state, not a silent partial fill.
