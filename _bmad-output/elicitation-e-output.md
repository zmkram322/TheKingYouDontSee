---
name: Elicitation E Output — Macro-Legibility Primitives
status: complete
date: 2026-05-06
elicitation_ref: prototype-completion-roadmap.md §3.5
session_inputs:
  - _bmad-output/phase-2.5-books-activity-architecture-directive.md §1.1, §5.2, §5.3, §6
  - _bmad-output/gdd-build-alignment-review.md
  - _bmad-output/design-parking-lot.md (war + export/import compatibility)
  - _bmad-output/placeholders.md
  - tkyds-game/scripts/books/book.gd
  - tkyds-game/scripts/interests/employer_interest.gd
  - tkyds-game/scripts/activities/activity.gd
  - tkyds-game/scripts/resources/accounts.gd
session_conduct: legacy (papers-with-directives). Future elicitations adopt Socratic alternative-surfacing conduct — see roadmap §8.2.
authors:
  - Author adjudication (Zach)
  - Cloud Dragonborn (Game Architect)
  - Samus Shepard (Game Designer)
  - Mary (Business Analyst)
---

# Elicitation E Output — Macro-Legibility Primitives

## 0. Session Frame

**Question:** *"How does the player learn what's true without the game telling them?"*

**Owner agents (per Stage 0.5 narrowing):** Cloud Dragonborn + Samus Shepard + Mary. Sally + Paige split into 1E.1 UI-pass follow-up (deferred — likely re-folded into Phase 8 first-observation-UI work, or absorbed into the new G elicitation if its command-surface piece earns it).

**Compatibility check (mandatory):** verify population API + inference layer + knowledge graph don't preclude future sibling systems on the design-parking-lot — War, Export/Import, Reputation. All three agents addressed. All three pass under the locked adjudications.

**Headline outcome:** four architectural decisions locked for v0; gossip-mechanics + NPC perception→decision coupling surfaced as a foundational gap that reshapes the next elicitation. New elicitation **G — The Perception → Decision → Action Loop** inserted into the roadmap as the next session, and the elicitation conduct for G onwards switches from agent-papers-with-directives to author-driven Socratic alternative-surfacing.

---

## 1. Agent Responses (verbatim)

### 🏛️ Cloud Dragonborn — Game Architect

*A pause. The cartographer unrolls a map weighted at four corners with smooth river stones. The ink at the edges is faded — those territories are not yet walked.*

Hear me, fellow architects. Before we set the next stones, let us study the shape of the land.

What we are designing today is not a feature. It is a **lens** — the shape through which every later subsystem will be observed by the player and queried by the code. War will look through this lens. Export will look through this lens. Reputation will look through this lens. If the lens is ground crooked, every system downstream inherits the distortion. So we must be exact, and we must be patient with our seams.

I will work in three movements: the population shape, the inference shape, the knowledge shape. Then directives.

#### Movement One: The Shape of a Population

The first decision is the load-bearing one, and it is structural, not cosmetic. **A Population is not a query — it is a Resource.**

Mary will say (rightly, in the small) that a method on `EmployerInterest` called `balance_avg(account)` would ship faster. I respect the instinct. But consider what we lose: every time we want a different *cohort* — "the workers at this mill," "the lords of this region," "the regions exporting grain" — we must invent a new method, on a new owner, with a new lifetime. The query operations splinter across the codebase. There is no single seat where someone asking "how do I aggregate over a group?" can find the answer.

A `Population` Resource gives us one seat. Its job is small and severe: hold a list of `Actor` references (or, in the export-import future, a list of `Region` references) and expose aggregation operations against their books. The Resource is the *cohort identity*. The methods are the *aggregation verbs*.

Subtypes are how we keep this honest:
- `MillWorkers` — backed by `EmployerInterest.employees()` (the seam that already exists)
- `RegionalActors` — all actors with an `Interest` rooted in a region
- `LordsDomain` — the lord's full household (his actors, his lands' actors)
- and tomorrow: `RegionsExportingGood`, `RaisedRetinue`, `CasualtiesOfSiege`

The subtype declares *who is in the cohort*. The base class declares *what we can ask of any cohort*. This is the named seam war and export will inherit, and it is why the seam must exist now even if v0 only instantiates `MillWorkers`.

This is exactly the disagreement Indie and Mary will raise — "you're building scaffolding for systems that may never come." My answer is that a `Population` base class is fifteen lines of code. The architectural payoff is enormous: the day we introduce war's `RaisedRetinue`, no one will need to rediscover what aggregation looks like. They will subclass and ship.

**Aggregation Verbs**

For prototype scope, I commit to a small but generative set:
- `balance_avg(account, period_start, period_end)` — the workhorse
- `balance_sum(account, period_start, period_end)` — for "how much grain did this region produce"
- `balance_distribution(account, period_start, period_end) -> Array[float]` — returns the raw per-actor values, sorted; histograms and quantiles compose from this
- `count_where(account, period_start, period_end, predicate: Callable) -> int` — for "how many workers ran a deficit this week"

`min` and `max` are degenerate cases of `distribution`. I would not ship them as separate methods until something demands the convenience.

What I will *not* ship: per-Population caches, dirty-flag invalidation, materialized rollups. The journal walk is O(n) over a tiny trace. The prototype dies at perhaps ten thousand entries. Caches at this scale are premature complexity that introduces a class of cache-coherence bugs we just spent Phase 2.5 eliminating in cost-basis. **The trigger for caching is a profile that shows population queries in the hot path of the simulation tick.** Until that profile exists, we walk the journal.

#### Movement Two: The Shape of Inference

This is where Samus and I will agree on the destination but I will press for sharper plumbing.

The directive's §6.2 four-tier precision frame is sound. Behavioral (cheap) → mood/posture (moderate) → financial (expensive). But "tier" alone is not a return shape. We must answer: when the code calls `book.balance_with_precision(observer, account, period, tier)`, what data type comes back?

I propose **a tagged union**, not a single shared shape:

```
class Reading:
    var kind: ReadingKind  # PRECISE | RANGE | NOISY | ENUM | UNKNOWN
    var precise_value: float  # if PRECISE
    var range_low: float; var range_high: float  # if RANGE
    var noisy_value: float; var noise_stddev: float  # if NOISY
    var enum_value: int  # if ENUM (POOR/MIDDLING/PROSPEROUS/...)
```

Why a union and not a single noisy float? Because "appears prosperous" and "approximately 50 grain ± 10" and "I cannot tell" are *different epistemic states*, not points on a number line. The UI will render them differently. A nascent investigation system will branch on them differently. Collapsing them to "noisy float, sometimes very noisy" loses the categorical distinction that makes the experience legible.

This is also where I gently push back on Mary, who I expect will argue we should "just return floats and let the UI fuzz the display." That works for one tier. The moment a second observer-investment level wants a *qualitatively* different reading, the float-only approach forces UI code to reverse-engineer the inference rules. The kind tag belongs in the data, not in the renderer.

**How the Tier Is Chosen**

The observer does not ask for a tier. **The observer is the tier.** The signature is:

```
book.balance(observer: Actor, account: StringName, period_start, period_end) -> Reading
```

Or, when the player is the observer:

```
book.balance(player_knowledge: PlayerKnowledge, account, period_start, period_end) -> Reading
```

The book inspects the relationship between the observer and the book's owner — investment level, witnessed events, whether they are the same actor — and chooses the tier itself. Code that calls into books **does not select precision**. This is critical, because otherwise every caller becomes a place where a bug can leak full precision to an observer who shouldn't have it. One choke point. One auditable function.

The existing `Book.balance(account, period_start, period_end)` becomes either deprecated or renamed `Book.raw_balance(...)` — internal, used by the precision-resolving layer and by tests, never by gameplay code. This is a structural fix in the spirit of pull-on-open killing cost-basis: we eliminate the *bug class* of accidental precision leak by making it impossible to express in the type signature.

**Player's Own Books**

Yes — confirmed, free and precise. The player's `PlayerKnowledge` resolves their own actor's books to `Reading.PRECISE` unconditionally. This is non-negotiable. If a player cannot trust their own ledger, the entire economic surface becomes unreadable.

#### Movement Three: The Shape of Knowledge

The counterparty resolution problem is the most subtle of the three, because the wrong shape here will *feel right* and only reveal its wrongness three phases later.

The temptation is to put `knows_about: Dictionary` on every `Actor`. Resist it. NPCs do not need a knowledge graph; they have full information about each other within whatever scope their AI requires, mediated by the same `Reading` precision layer above. **The knowledge graph is a player-only structure.**

Therefore: a `PlayerKnowledge` Resource, owned by the player's session/save, exposed via either an autoload (`PlayerKnowledge.current`) or — my preference — passed explicitly into the precision-aware book API as the observer. Explicit beats ambient. Autoloads are global mutable state in disguise; we have done well to avoid them in Phase 2 and should continue.

`PlayerKnowledge` holds:
- `resolved_counterparties: Dictionary[StringName, DisplayName]` — `&"rival_lord_castellan"` → "Lord Harwick of Eastfield"
- `witnessed_events: Array[WitnessRecord]` — the substrate for "I have seen Bob work this field three times"
- `relationships: Dictionary[ActorRef, RelationshipState]` — investment level, last interaction, accumulated trust

**When Does Resolution Happen?**

This is a design question, but architecturally the seam must support all of these:
1. **Direct meeting** — you encounter the actor in a scene; their counterparty ID resolves.
2. **Tavern hearsay** — you hear the name; resolution happens but possibly with a `RelationshipState.heard_of_only` flag that gates further precision.
3. **Purchased intelligence** — a tip costs coin or favor; resolution happens with quality dependent on the source.
4. **Inference** — repeated observation of `&"rival_lord_castellan"` in your books accumulates *something*; perhaps a "frequent counterparty" flag that opens a "ask around about them" action.

The seam is: `PlayerKnowledge.resolve(counterparty_id) -> DisplayName | null`. The *triggers* for resolution are gameplay events that call `PlayerKnowledge.learn(counterparty_id, display_name, source: LearnSource)`. We ship the seam in v0.5; we ship a single trigger (direct meeting) in v1; the others arrive when their gameplay arrives.

**Diegetic Vocabulary — `Activity.display_name`**

This is the simplest of the four placeholders and I will resolve it cleanly: **`Activity.display_name` is set in the subclass `_init` or as a `const` class member.** Not a registry. Not a localization system yet. The string `"worked a full day in the field"` lives on `WorkActivity`. The string `"hauled grain to market"` lives on `MarketHaulActivity`.

When Phase 7 (or Phase 8) builds the observation UI, it pulls `activity.display_name` and templates around it. Localization is a Phase 12+ concern and the field will move to a translation key without breaking callers — `tr(activity.display_name)` is a one-line change.

#### The Architecture Diagram Question

Indie and Mary will say: do not draw what you have not built. I hold my prior position, and Movement One has hardened it.

**Draw the seams. Mark them v0.5 stubs.**

The architecture diagram is not a snapshot of the build — it is a depiction of the system's *identity*. A diagram that omits `Population` because it is a fifteen-line stub, but includes `FinancialBook` because it is fully implemented, lies about the shape of the project. Worse, it invites the next contributor to add population queries in the wrong place because the right place isn't on the map.

The compromise I will offer Mary: stubs are drawn in *outline*, implemented seams in *fill*. The diagram tells the truth about both what exists and what is committed-to. This is how every honest engineering org draws their systems: solid lines for shipped, dashed for planned, and you can see the silhouette of the cathedral before the last buttress is poured.

#### Compatibility Check — War / Export / Reputation

**War.** `Population` generalizes cleanly. `RaisedRetinue extends Population` with cohort = "actors currently mustered to this lord." `balance_sum(SupplyAccount, ...)` answers "how much grain does the army carry." Casualties become a `Population` whose membership shrinks. **No conflict.**

**Export/Import.** This is the test the population API must pass. Today's `Population` holds `Actor` references. Cross-region export wants `Region` references. I commit to: `Population` is generic over its element type — `Population[Actor]`, `Population[Region]`. Aggregation methods take a closure that extracts the book from the element. This is fifteen more lines and avoids a future fork. **No conflict if generic from day one — flag if we hardcode `Array[Actor]`.**

**Reputation.** Reputation is a *network-flavored book read with decay* — the directive's words. The `Reading` tagged union handles decay naturally as `NOISY` with growing stddev over time-since-witnessed. Gossip-acquired reputation enters via `PlayerKnowledge.witnessed_events` with a source tag. **No conflict.** The only thing I would add: when reputation ships, it will want a `Reading` kind I have not specified — perhaps `WEIGHTED` for "this is what the network believes, weighted by trust." We accept that as a future addition to the union.

#### The Four E-Gated Placeholders — Resolutions

1. **`Activity.display_name`** — Resolved. Set in subclass `_init` or as `const`. No registry yet. Phase 7/8 consumes it.
2. **Player-knowledge graph** — Resolved as `PlayerKnowledge` Resource. Seam shipped v0.5 with `resolve()` and `learn()`. One trigger (direct meeting) in v1; others on demand.
3. **Diegetic vocabulary surfacing** — Resolved via #1. Display strings live on Activity subclasses; UI templates around them.
4. **Book-access gates by precision** — Resolved as `Book.balance(observer, account, period) -> Reading` with tagged-union return. `raw_balance` becomes the internal-only escape hatch. Choke point eliminates precision-leak bug class.

#### On Experience Questions

I will be brief here — Samus owns this surface. My only architectural input:

The first noticing moment must come through the *same* `Reading` API the rest of the game uses. Do not build a special "tutorial reading" path. The `ENUM` tier ("appears prosperous") is the natural shape for first noticings — coarse, evocative, mysterious. The investigation arc is the player walking up the precision ladder one rung at a time, each rung gated by an action that costs something. Information has cost; that cost is investment, not coin alone.

The tavern is one source among many. Architecturally it is a `LearnSource` enum value feeding `PlayerKnowledge.learn()`. Rate-limiting lives in the tavern scene, not in the knowledge graph. Keep the graph dumb; let the gameplay surfaces decide what they pay for.

#### Cloud's Design Directives

1. **`Population` is a Resource, generic over element type** (`Population[Actor]`, `Population[Region]`). Subtypes (`MillWorkers`, `RegionalActors`, `LordsDomain`) declare cohort membership; the base class declares aggregation verbs. Ship the base class and one subtype (`MillWorkers`) in v0.5.
2. **Aggregation verbs at prototype scope: `balance_avg`, `balance_sum`, `balance_distribution`, `count_where`.** No `min`/`max`/`median` until a caller demands them. No caches until profiling shows population queries in the simulation hot path.
3. **`Book.balance(observer, account, period_start, period_end) -> Reading`** replaces direct precision access for gameplay code. The book selects the precision tier from the observer's relationship — callers do not request tiers. Eliminates the precision-leak bug class structurally.
4. **`Reading` is a tagged union** with kinds `PRECISE | RANGE | NOISY | ENUM | UNKNOWN`. The kind tag travels with the data; UI and inference branches consume it. No collapse to a single noisy float.
5. **`Book.raw_balance(...)`** — the renamed precise-access method, internal-only, used by the precision-resolution layer and tests. Gameplay code does not call it.
6. **`PlayerKnowledge` is a Resource passed explicitly as the observer** to precision-aware book reads. Not an autoload. Holds resolved counterparties, witnessed events, relationships. NPCs do not have a knowledge graph in v1.
7. **Counterparty resolution seam: `PlayerKnowledge.resolve(counterparty_id) -> DisplayName | null` and `PlayerKnowledge.learn(counterparty_id, display_name, source: LearnSource)`.** Ship the seam in v0.5; ship one trigger (direct meeting) in v1; defer tavern/purchase/inference triggers to their gameplay phases.
8. **`Activity.display_name`** is set as a subclass `const` or in `_init` — no registry, no localization indirection in v0.5. Localization migrates to `tr()` wrapping in Phase 12+ without breaking callers.
9. **The player's own books always return `Reading.PRECISE`.** Non-negotiable, encoded in the precision-resolution layer as the first guard clause.
10. **The Pass 1 architecture diagram depicts seams as well as implementations.** Implemented seams in fill, v0.5 stubs in outline. `Population`, `PlayerKnowledge`, and the `Reading`-returning `Book.balance` all appear on the diagram. The diagram tells the truth about both shipped code and committed-to architecture.

*The cartographer rolls the map back, ties it with twine, sets it on the rack with the others.* The land is mapped. Let us set the next stone.

---

### 🎲 Samus Shepard — Game Designer

#### The Lens — Elicitation E Paper
##### What Kind of Game This Is At The Perception Layer

Okay. **OKAY.** Let's GOOOO. Cloud, Mary, Indie, Author — we have been circling this question for two phases and it's finally on the table. So let me start by saying the loud thing: this is the elicitation where the game becomes itself or stays a sandbox. Three of us said E was the lens for everything else and I want to honor that by *leading with the player-felt arc*, not the seams. The seams come second. The seams are *because*.

#### Section 1 — What Are We Even Designing For? (The Arc Before The Seams)

The UVP is "the only game where the thing you're proud of is what you understood." So the central question isn't "what API do we ship" — it's: **what does understanding *feel like* in this game, beat by beat?**

Here's the arc I want every player to walk:

1. **Confusion.** Numbers, names, transactions you don't have the schema for. *"Why is Lord Harwick paying 500 to someone called rival_lord_castellan?"* You feel like you walked into the middle of a play in Act 3.
2. **Pattern.** You start noticing the same names recurring. The same shapes — "every harvest week, this lord's payables spike." Pattern is the first dopamine hit.
3. **Hypothesis.** You start *guessing*. "I bet Harwick is in debt to Castellan." This is the moment the player starts treating the world as a thing they can model.
4. **Investment.** You spend a resource — coin, time, a relationship — to *test* the hypothesis. Send a steward. Buy a drink at the right tavern. Marry the right cousin.
5. **Confirmation or Surprise.** You were right (mastery!) or you were wrong in an interesting way (the world is bigger than you thought!).
6. **Leverage.** Now you *do something* with the knowledge. You undercut Harwick's grain. You offer Castellan better terms. You blackmail. The understanding *becomes* power.

That's the loop. Six beats. Confusion → Pattern → Hypothesis → Investment → Confirmation/Surprise → Leverage. **Every architectural decision Cloud names today must serve at least one of those beats or it's not earning its place in this game.**

I want to call out beat 5 — *Surprise*. This is where Dwarf Fortress wins and where most economy games lose. The game has to be *capable of being wrong about itself in interesting ways from the player's POV*. That means inference is **lossy on purpose**. If the player's read of "Harwick is in debt" can never be wrong because the inference layer is just `book.balance() with a UI filter`, we've built a spreadsheet with mood lighting.

#### Section 2 — The First Noticing Moment (Concrete Vignette)

Author asked. Here it is. This is what I want the first ten minutes of the prototype-with-perception-layer to feel like.

> Week 3. You're a minor lord at a market day in your own holding. The retail market is on screen — you can see grain trading, prices fluctuating day by day. You're looking at your own books because you're trying to figure out if you can afford a better mason. They're precise. Boring. Yours.
>
> Then the tavern feed surfaces a line. Not a popup — just a quiet line in a scrolling diegetic log: *"A hauler at the Mill of Greenfield said the workers there have been complaining about thin pottage. Three weeks running."*
>
> You didn't ask for this. You weren't watching the Mill of Greenfield. You don't even know who owns it yet — your knowledge graph has it as `Mill_03` or maybe just "a mill west of here." But the line lodges. *Thin pottage. Three weeks.* Something tickles.
>
> Two days later you're checking grain prices and you notice — wait, Greenfield's wholesale grain price has been ticking up. You can see *that*, because wholesale is public. Hmm. Workers underfed. Grain expensive. Someone's squeezing somewhere.
>
> You spend 5 coin to buy a round at the Greenfield tavern via your factor. The next day, a new line surfaces: *"The miller at Greenfield has been late with wages. Workers are looking elsewhere."*
>
> *Now* the player leans forward. Because that's three pieces of evidence — underfed, expensive grain, late wages — and they're starting to *cohere into a story*. The miller's in trouble. There's an opportunity here.

That's the arc. Notice what I did NOT do in that vignette:
- I did NOT show the player a number.
- I did NOT show the player the Mill's actual books.
- I did NOT name the miller until information was paid for.
- The signal arrived **time-aggregated** ("three weeks running") and **population-aggregated** ("the workers" not "Bob specifically").

That is the macro-legibility orientation in action and it's what I locked in D1. I am MORE confident in it now, not less.

#### Section 3 — Experience Questions (My Domain)

**E1 — The First Noticing Moment.** Vignette above. The principle: **the first noticing moment must be unsolicited.** The world surfaces a pattern *to* the player without the player having clicked anything. This is critical because it tells the player "the simulation is alive whether you're watching or not" — pillar one. If the first noticing only happens when they open a menu, we've trained them that the world is a database. Bad.

**E2 — Information As Resource.** **YES. Information is a resource.** Hard yes from me. It must be acquired, it has cost (coin, time, relationship-capital, sometimes reputation-risk), and it **decays** — knowledge about a lord's finances from 8 weeks ago is *less precise* than knowledge from 2 weeks ago. Decay is what forces re-investment, which is what creates the *second* and *third* investigation arc, not just the first.

This is also where I disagree with anyone who wants information to be free-after-observed. Free-after-observed is what makes 4X games degenerate into spreadsheet optimization. Information as a *renewable but expiring* resource is what keeps the player active in the social fabric of the world.

**E3 — Precision Granularity.** Three tiers minimum at prototype. I want the inference layer to deliberately *blur*:

- **Precise** — exact numbers. Reserved for: your own books; an account on someone you have a steward inside; a transaction you witnessed.
- **Bracketed** — "approximately 40-60 grain" or "between 2 and 4 weeks of wages owed." Reserved for: hearsay from a trusted source; recent observation; a relationship-mediated read.
- **Qualitative** — "appears prosperous", "the workers seem well-fed", "operating at a loss for some time." Reserved for: ambient gossip; first-time encounter; decayed knowledge.

These are not separate APIs — they're **the same query returning different fidelity based on the observer's standing.** Cloud, this is your problem to shape, but the *experiential requirement* is: **the same question asked by two different player-characters should return different-shaped answers.** That's the seam.

**E4 — The Investigation Arc (Lord Harwick).** Player wonders why Harwick is operating at a loss. The gameplay surfaces I want available at prototype:

1. **Tavern listening** (cheap, qualitative, slow). Buy rounds, hear gossip.
2. **Hire a factor/steward to observe a specific actor or holding** (medium cost, bracketed precision, takes weeks).
3. **Personal relationship investment** — visit, marry into, ally with (expensive, slow, but unlocks precise on a narrow slice).
4. **Direct observation** if you happen to be present at a transaction (free, precise, but rare).

At prototype scope I'd ship 1 and 2. 3 and 4 can be Phase 5+.

**E5 — Tavern Talk.** Rate-limited. Always. Each tavern visit yields N gossip events drawn from a weighted pool of (a) recent transactions involving locals, (b) population-aggregated patterns at nearby holdings, (c) decayed memories of older events. **Workers and haulers and laborers gossip about *what they observed in their own books and Activities*.** Their VitalsBook said thin pottage. Their FinancialBook said late wages. Those become gossip lines.

This is gorgeous because it makes the *existing* book infrastructure the gossip generator. We don't need a new "rumor" system — gossip is just *other actors' book reads, leaking through social channels, with decay and noise*. **Books are the truth substrate; gossip is lossy book-leaks.**

**E6 — Counterparty As Mystery.** **The not-knowing is THE point.** When the player sees `Payable:rival_lord_castellan +500`, that opaque StringName *is the mystery hook*. Resolving it should cost something. The player-knowledge graph maps `rival_lord_castellan` → display name "Lord Aldric of the Castellan March" only after the player has *met him, heard his name in a context that links it to his title, or paid for the link*.

This is why Cloud's §5.3 directive about preserving opaque StringNames is load-bearing. Don't pre-resolve. The opacity is the gameplay.

**E7 — Diegetic Vocabulary Cap.** "Bob's WorkDay closed: 4 grain produced" is failure. "Bob worked a full day at the field. The harvest brought four sheaves home" is the floor, not the ceiling. The ceiling is: *"At Greenfield, the harvest came in light this week — four sheaves, where five were hoped for."* Population-aggregated. Time-aggregated. **Even diegetic line generation should respect the macro-legibility orientation.**

`Activity.display_name` gets set in the Activity's `_init` from a per-Activity-class default. NOT a global registry — that's a Phase 7 problem when localization shows up. For prototype, each Activity subclass sets its own `display_name` and a `closing_narration_template(book_delta)` method. That's enough.

**E8 — Architecture Diagram Question.** **My position holds: YES, the population aggregation API and inference layer go on the diagram as named seams even though v0 only stubs them.**

Reasoning sharpened by writing this paper: the diagram depicts the *identity* of the system. If a future contributor (or future-us) reads the diagram in 6 months and sees only what's built, they will design *against* a shape that doesn't include perception. We've already seen what happens when a system grows a perception layer as an afterthought — it becomes a UI hack on top of raw data, and the macro-legibility property is lost. Indie and Mary's concern (don't lie about what's built) is fair, but the answer is **diagram convention**, not omission. Mark stubbed seams with a dashed border or a `[v0.5]` tag. Show them. Their absence on the diagram is a worse lie than their stubbed presence.

I am open to being wrong if Indie has a concrete failure mode where a stubbed-on-diagram seam led to a worse decision. But absent that, ship them dashed.

#### Section 4 — System Questions (Quick Takes, Deferring To Cloud On Shape)

- **S1 (Population API location):** Lean `Population` as a Resource type, instantiated per scope (Region, Employer, etc.). But Cloud owns this.
- **S2 (Aggregation ops):** `avg`, `count`, `distribution` at prototype. `min/max/sum` later if needed. Distribution is the secret weapon — "wage distribution at the mill" tells stories that averages don't.
- **S3 (Inference shape):** **Per-account-type.** A wealth read returns a different-shaped enum than a vitals read. Don't force one shape.
- **S4 (Precision tier API):** `book.balance(observer, account, period)` — observer is the precision input, no separate `_with_precision` method. The observer *is* the precision filter.
- **S5 (Knowledge graph location):** Per-actor field. Each actor has their own knowledge — the player-character is just one actor. This is also how NPC-vs-NPC gossip works in the same substrate.
- **S6 (Counterparty resolution):** Resolution events fire when (a) actor meets actor, (b) gossip mentions a name in a resolving context, (c) explicit payment for info.
- **S7 (Diegetic vocab):** Activity `_init`. Templates per Activity subclass.
- **S8 (Player's own books):** Confirmed. Always free, always precise.
- **S9 (Time horizon helpers):** SimClock. Books shouldn't know about weeks.
- **S10 (Performance):** O(n) journal walks are fine until they aren't. Cache trigger: when a single tick exceeds 33ms or population queries become >5% of frame time. Not before.

#### Section 5 — Compatibility Check

- **War.** Population API generalizes from "actors at this employer" to "soldiers in this retinue." Casualties are book entries against a `Readiness` or `Strength` account. Sieges are population-aggregated VitalsBook reads on the besieged settlement. **Compatible.**
- **Export/Import.** Population API generalizes from "actors at scope X" to "regions exporting good Y." Same query shape, different scope object. **Compatible** — and this is exactly why Population should be a flexible Resource not methods on Region.
- **Reputation.** Reputation is a network-flavored book with decay, read via the same observer-mediated precision API as everything else. Gossip-acquired = the same gossip pipeline that surfaces the Greenfield miller's troubles. **Compatible.**

#### Section 6 — E-Gated Placeholders Resolution

1. **`Activity.display_name`** — Resolve in this directive. Set in Activity subclass `_init`. Plus add `closing_narration_template()` method on Activity. Phase 7 still owns localization.
2. **Player-knowledge graph** — Build seam at v0.5: per-actor `KnowledgeGraph` Resource with `resolve(opaque_id) → display_name | null` and `record_encounter(...)`. Stubbed but on diagram.
3. **Diegetic vocabulary surfacing** — Resolved by directive 1 + the gossip-as-book-leak architecture in directive 5 below.
4. **Book-access gates by precision** — Resolved by `book.balance(observer, ...)` shape. Observer is the gate.

#### Section 7 — Samus's Design Directives

1. **The player-felt arc is six beats: Confusion → Pattern → Hypothesis → Investment → Confirmation/Surprise → Leverage.** Every architectural seam points back to one of these or it doesn't ship.
2. **Information is a resource with cost AND decay.** No free-after-observed. Decay is what creates the second and third investigation arc.
3. **Three precision tiers — Precise, Bracketed, Qualitative — selected by observer standing, not by API choice.** Same query, different fidelity. `book.balance(observer, account, period)`.
4. **Counterparty StringNames stay opaque until paid for.** The not-knowing is the gameplay. Per-actor `KnowledgeGraph` Resource is the resolution layer; stubbed at v0.5, named on the diagram.
5. **Gossip = lossy book-leaks.** Other actors' VitalsBook and FinancialBook reads, decayed and channeled through tavern/social events, become diegetic lines. No separate rumor system.
6. **Activity.display_name set in subclass `_init`. Add `closing_narration_template(book_delta)` method.** Diegetic vocabulary lives with the activity, not in a global registry. Localization is Phase 7.
7. **Population is a Resource type instantiated per scope** (Region, Employer, Retinue, ExportingRegions). Generalizes to war, trade, reputation. Cloud owns the precise shape.
8. **Inference output shape is per-account-type.** Wealth, vitals, readiness, reputation — each has its own enum/range/distribution shape. Don't force uniformity.
9. **First-noticing moments must be unsolicited.** The world surfaces patterns to the player without clicks. The simulation announces itself. Pillar one made playable.
10. **Population API + inference layer + knowledge graph appear on the architecture diagram as dashed/`[v0.5]`-tagged seams.** Identity over current code. If Indie surfaces a concrete failure mode in adjudication, I'll revisit — but absent that, ship them visible.

Let's GOOOO. This is the lens. Build the seams behind it and the rest of the game writes itself.

---

### 📊 Mary — Business Analyst

#### Elicitation E — Macro-Legibility Primitives: A Triage Paper

##### Top Line (Pyramid Principle)

**Of the five surfaces this elicitation puts on the table, exactly two earn v0 architecture seams: (1) a population enumeration aggregator built as thin methods on `EmployerInterest` and `Region` — not a `Population` Resource — and (2) an `observer` parameter on `Book.balance(...)` reserved as a no-op for now, with precision tiers deferred behind it.** The other three — full inference layer, player-knowledge graph, diegetic vocabulary surfacing — go to the placeholders ledger as named-but-unbuilt entries with explicit consumer triggers. None graduate to the architecture diagram yet, because none have v0 or near-term consumers that exercise them, and three of the four bind to a UI we haven't started.

I am hardening, not softening, my prior position with Indie: **the diagram depicts what is built and what is structurally projected by a near-term consumer**, not what is aesthetically aspirational. But I am moving on the population API specifically — the macro-legibility orientation locked in D1 makes that aggregator a near-term consumer, not a speculative one. So: one seam earned, four seams deferred with reasoning.

The treasure here is the line itself. Let me show you where I drew it and why.

#### Section 1: The Triage Frame

The question this elicitation asks is not "what is the right shape for macro-legibility?" — Cloud and Samus will give you ten thoughtful versions of that. The question is: **which shapes are load-bearing for the architecture's identity right now, and which are design ideation that wants to become architecture before earning it?**

A seam earns v0 architecture when one of three things is true:
1. **A v0 consumer reads it** (today's headless trace, today's matcher, today's books).
2. **A Phase 3-5 consumer is named in the roadmap and would have to wait or be retrofitted if the seam is absent.**
3. **The seam's *absence* would force a different shape on something we're already building** — i.e., it constrains v0 even unbuilt.

Anything else is design parking lot. Not wrong — just not architecture-yet.

I'll walk each of E's five surfaces against this test.

#### Section 2: Surface-by-Surface Triage

##### 2.1 Population Aggregation API — EARNS A SEAM

**Consumer:** D1's locked macro-legibility orientation. "The workers at this mill are usually well fed" is a population query: enumerate `EmployerInterest.employees()` → for each, read `VitalsBook.balance(food_satiation, period)` → aggregate. That sentence has no implementation today. The headless trace's next assertion target — Phase 3's "well-being patterns are visible across a population" — needs it.

**Shape — methods, not a Resource:**

Cloud will likely propose a `Population` Resource. I disagree on evidence:
- A Resource implies state. Population at prototype scope is not state — it is a *query result* over flat `Actor`s indexed by interest membership.
- We already have the enumeration seam: `EmployerInterest.employees()`. The aggregator is a thin layer above it.
- A Resource locks identity; methods compose.
- Export/Import compatibility: when "regions exporting this good" becomes a query, it generalizes as `Region.actors_with_interest(ProducerInterest)` → aggregate. A `Population` Resource would have to be re-modeled for the cross-region case. Methods don't.

**Concrete v0 shape:**

```
EmployerInterest.aggregate(book_account: StringName, op: AggregateOp, period) -> float
Region.aggregate_over(interest_filter, book_account, op, period) -> float
```

Where `AggregateOp` is an enum: `AVG`, `SUM`, `MIN`, `MAX`, `COUNT`. **Not `distribution`. Not `count_above_threshold`.** Distribution is a UI-shape concern — it serializes a histogram, which a headless trace cannot consume. Threshold-counting is `COUNT` + a predicate, which we don't need until a consumer asks.

**v0 stub vs. real:** Real. The implementation is fifteen lines. Stubbing it is more work than writing it.

##### 2.2 Precision Tiers / Book-Access Gating — EARNS A RESERVED PARAMETER, NOT A FRAMEWORK

**Consumer:** None today. v0 has no observer. The player has no books-of-others to read.

**But:** the §6 four-tier framework's *absence* would constrain the `Book.balance(...)` signature we're already shipping. If we ship `balance(account, period_start, period_end)` and later need `balance(observer, account, period_start, period_end, precision)`, every call site changes.

**This is the third test passing.** The seam constrains v0 even unbuilt.

**Concrete v0 shape:**

```
Book.balance(account, period_start, period_end, observer: Actor = null) -> float
```

Where `observer == null` means "god-mode read" (today's only mode). The precision tier *machinery* — noisy floats, range pairs, enum buckets — does not ship. The *parameter slot* does. When Phase 6 or Phase 7 introduces observer-gated reads, every existing call site keeps working; new call sites pass an observer; the precision logic lives behind one chokepoint.

This is the cheapest possible seam. It is one parameter with a default. I commit to it.

**War compatibility:** military readiness reads (`MilitaryBook.balance(retinue_strength, ...)`) inherit the observer slot for free. No retrofit.
**Reputation compatibility:** reputation-as-book-read with decay reads through the same chokepoint. No retrofit.
**Export/Import compatibility:** cross-region book reads inherit it.

All three pass. This is the load-bearing identity seam Cloud and Samus are pointing at — but the *framework* isn't. The *parameter* is. That's the precision I'm asking us to hold.

##### 2.3 Inference Layer Shape — DEFERRED, REGISTERED IN PLACEHOLDERS LEDGER

**Consumer:** None until precision tiers actually do something. That is post-Phase-6 at earliest.

**Why I deferred and won't move:** Cloud will reasonably argue that picking the shape now — enum vs. noisy float vs. range pair — prevents thrash later. I disagree on evidence: we don't yet know whether *any single shape* serves all account types. Vitals (food_satiation) reads as a range or bucket; financials (cash) read as a noisy magnitude; reputation reads as a decayed scalar. The question "what is the inference shape?" is probably miscast — it's plural.

**Premature commitment to a single shape would lock identity around an aesthetic guess.** That is the exact thing the diagram-or-not disagreement is about.

**Placeholder ledger entry:**
> *Inference layer shape* — gated on first observer-gated read (Phase 6+). Resolution: per-account-type adapter, chosen at consumer site. Do not pre-commit to a global shape.

##### 2.4 Player-Knowledge Graph — DEFERRED, REGISTERED

**Consumer:** None. Currently three things would consume it: counterparty ID resolution, diegetic vocabulary surfacing, observer-gated precision lookup. **All three are UI-layer or post-UI.** v0 has no UI. The trace prints `Payable:rival_lord_castellan` — that is the correct level of detail for a headless trace.

**Cloud/Samus's argument** will be that the knowledge graph appears on the diagram as a named seam because it is identity. **My counter:** "identity" without a consumer is decoration. Counterparty IDs being opaque `StringName`s today is *fine*. They will become opaque-with-display-name when a UI consumer arrives, and the resolution layer will appear *with* its consumer.

**Placeholder ledger entry:**
> *Player-knowledge graph* — gated on first UI surface (Phase 8 first-observation-UI is the natural earliest). Resolution: autoload service `KnowledgeGraph` with per-actor `(counterparty_id → known_display_name, certainty)` map. Do not build seam without a consumer.

##### 2.5 Diegetic Vocabulary Surfacing — DEFERRED, REGISTERED

**Consumer:** None. `Activity.display_name` exists as overhead at `activities/activity.gd:25`, never set, never read. It is a Stage-0-cleanup-pass-shaped sin: a field added in anticipation of a consumer that never arrived.

**The honest move** is to acknowledge it as overhead and either (a) delete it pending a UI consumer or (b) leave it as a no-op marker. I lean (b) — its presence costs almost nothing, and deleting then re-adding is its own kind of churn. But it does not graduate to architecture.

**Placeholder ledger entry:**
> *Activity.display_name* — overhead today; gated on Phase 7 or Phase 8 UI. Resolution at point of consumer: set in activity factory or via per-activity-type constants.

#### Section 3: The Diagram-or-Not Disagreement — Where I Land

**My prior position with Indie:** seams appear on the diagram only when built.

**Where E moves me:** slightly, on one item. The population aggregator earns a diagram entry because D1 has named the consumer (macro-legibility traces) and the aggregator will be implemented in Phase 3. That is no longer speculation; that is the next phase.

**Where I hold firm:** the inference layer, knowledge graph, and diegetic vocabulary do **not** appear on the diagram. They appear in the **placeholders ledger** with consumer triggers. The placeholders ledger is the right artifact for "named, scheduled, not yet built." The diagram is the wrong one — diagrams that show unbuilt boxes train the team to read the diagram as a wishlist instead of a contract.

**Cloud's strongest argument** is that the diagram depicts identity, and identity exists before consumers do. I take the point and reject the conclusion: identity that has no consumer cannot be tested or falsified, and an architecture diagram should be falsifiable. The placeholders ledger is the falsifiable home for projected identity. *That's* where these belong.

**Net:** one seam moves from "no" to "yes" (population aggregator). Three stay in placeholders. The precision-tier *parameter slot* is a third category — it appears on the diagram as part of the `Book.balance` signature, but the framework behind it does not. That precision is the contribution I want this paper to make.

#### Section 4: War / Export-Import / Reputation Compatibility Check

**War.** The population aggregator generalizes: `Region.aggregate_over(MilitaryInterest, retinue_strength, AVG, period)` reads "average retinue strength across this region's lords this month." The `observer` parameter on `Book.balance` lets enemies read your military book at degraded precision. Books for casualties / supply / readiness slot in as new account types on existing or new books — the architecture does not care. **Compatible. No directive precludes war.**

**Export/Import.** Cross-region trade is "regions exporting this good" — `Region.actors_with_interest(ProducerInterest, good=grain)` → aggregate. The methods-not-Resource decision in 2.1 specifically protects this. A `Population` Resource would have forced a re-modeling. **Compatible, and the directive in 2.1 actively defends compatibility.**

**Reputation.** Reputation-as-book-read-with-decay reads through `Book.balance(account, period, observer)` with a decay applied at the precision tier. This is the most natural fit of the three — the observer parameter was practically designed for it. **Compatible.**

All three pass. No directive in this paper precludes any of them.

#### Section 5: The Four E-Gated Placeholders, Resolved

1. **`Activity.display_name` never set** — registered in placeholders ledger. Gate: Phase 7 or Phase 8 UI consumer. Do not delete; do not surface. Stays as no-op marker. *(See Directive 6.)*
2. **Player-knowledge graph** — registered. Gate: Phase 8 first-observation-UI. Shape at consumer time: autoload service. *(See Directive 7.)*
3. **Diegetic vocabulary surfacing** — registered. Gate: same as #1. *(See Directive 6.)*
4. **Book-access gates by precision level** — *parameter slot* graduates to v0 architecture (`observer` on `Book.balance`). *Framework* registered with gate: Phase 6+ observer-gated read consumer. *(See Directives 3 and 8.)*

#### Section 6: On the Experience Questions — Defer to Samus

Samus will write the player-feel paper. I will not duplicate that work. My one note from the analyst seat: **"information as resource with cost/decay"** is a mechanic that can ride on top of the precision-tier parameter without architectural change. That is the right test of whether the parameter slot is correctly shaped — if it can carry that mechanic without a retrofit, the seam is doing its job. I believe it can. Samus should challenge that.

#### Section 7: Mary's Design Directives

1. **Add a population aggregator as methods, not a Resource.** Ship `EmployerInterest.aggregate(account, op, period)` and `Region.aggregate_over(interest_filter, account, op, period)` in Phase 3. Operations: `AVG, SUM, MIN, MAX, COUNT`. **Consumer:** D1's locked macro-legibility traces. **Earns its seam.**
2. **Do not build a `Population` Resource.** Methods compose; the Resource locks identity and breaks export/import generalization. **Consumer-defending decision** for Phase 5+ cross-region work.
3. **Add `observer: Actor = null` parameter to `Book.balance(...)` and `Book.entries(...)` now.** No precision logic behind it yet. Pure call-site futureproofing. **Consumer:** Phase 6+ observer-gated reads. **Earns its seam by constraining v0 signatures.**
4. **Defer the inference layer shape.** Register in placeholders ledger with gate "first observer-gated read consumer." Resolution shape: per-account-type adapter chosen at consumer site, not a global enum/float/range commitment. **Consumer:** none yet.
5. **Defer the player-knowledge graph.** Register in placeholders ledger with gate "first UI surface (Phase 8)." Anticipated shape: autoload service with per-actor counterparty maps. **Consumer:** none yet.
6. **Leave `Activity.display_name` as no-op overhead.** Do not set it; do not delete it; do not surface it. Register with gate "first UI surface." **Consumer:** none yet. Cost of leaving it: near-zero. Cost of deleting and re-adding: real.
7. **Counterparty IDs remain opaque `StringName`s in v0.** No resolution layer. Headless traces print `Payable:rival_lord_castellan` correctly. Resolution layer arrives with its UI consumer. **Consumer:** none yet.
8. **The architecture diagram entries E adds: ONE.** `EmployerInterest.aggregate` / `Region.aggregate_over`. The `observer` parameter is documented in `Book.balance`'s signature, not as a separate diagram box. The other three surfaces appear in the placeholders ledger, not the diagram. **This is my hardened position with Indie, against Cloud/Samus.**
9. **The placeholders ledger gets four new entries from this elicitation.** Each entry includes: name, consumer-trigger, anticipated-shape-at-consumer-time. This is the falsifiable artifact for projected identity — not the diagram.
10. **Performance posture: O(n) walks are fine through Phase 5.** Aggregator caches are a Phase 6+ decision triggered by trace timing, not architecture. **Consumer:** none yet — premature optimization is its own gold-plating.

The line is drawn. One seam earned, one parameter slot earned, three surfaces registered as placeholders with consumer triggers, zero surfaces speculatively diagrammed. The treasure was knowing which clue was load-bearing and which was decoration that wanted to become structure. We found it.

---

## 2. Mid-Round Author Drive — The Action-Side Gap

After Round 1, the orchestrator surfaced the live disagreements (population shape, inference shape, knowledge graph location, diagram convention). Before adjudicating, the author flagged a foundational gap none of the three papers addressed:

> *"How we build on the complexity of the actions one can actually take, what that universe looks like, or architecturally how we build the framework to extend in any direction — because reading the world reads like a diorama or a book you can't interact with if we don't connect how one (either player or actor) actually changes / interacts with the world they are a part of."*

**Diagnosis.** All three papers built read-side architecture (Books, Population aggregators, Reading precision, KnowledgeGraph, gossip-as-book-leaks) with no traceable code path for the write side. Specifically:

- **Player action surface** — v0 has no player; no command surface; no "buy a round at the tavern" / "send a factor" / "offer a contract" architecture.
- **NPC intent representation** — Interests fire on bus signals (reactions); there is no goal/plan structure that can be set, observed, or interfered with. The GDD's DISRUPT verb has nothing to disrupt.
- **Compositional action** — the GDD's COMPOSE verb has no architectural surface.
- **Indirect action** — paying NPC X to do Y; the "invisible kingmaker" UVP has no representation today.
- **Action vocabulary extensibility** — adding a new action means inventing a new Interest or Activity each time; no recipe.

**Resolution.** Insert a **new elicitation G** into the roadmap before B. Working title: **"The Perception → Decision → Action Loop: how actors (player and NPC) sense, decide, and intervene; how the architecture extends to anything we add later."** The three are not separable — perception without action coupling is decorative; action without decision is empty inputs; decision without perception is unreadable behavior. They form one architectural concern.

E may be re-scoped post-G as "Read-Side Primitives" in the roadmap §1 table.

### Mid-round D1 expansion — Godot groups

The author also surfaced a third pattern for D1 (population shape) that the agents missed: **Godot's built-in groups system** (`Node.add_to_group`, `get_tree().get_nodes_in_group`).

**Orchestrator evaluation:**

- ✅ Works for Actor cohorts (Actors are Nodes). Engine-tracked O(1) add/remove. Idiomatic Godot.
- ❌ Doesn't extend to non-Node aggregations — `Region` isn't a Node; export/import wants `Region` aggregation; groups don't generalize there.
- ⚠️ Requires syncing with the truth substrate (active LaborContracts). Manageable under the activity-as-force-carrier discipline (one chokepoint), but a denormalization that re-introduces a cache-coherence bug class.
- ✅ Cheap if adopted as a *cache/index* rather than primary cohort store.

**Verdict for v0:** overkill in one direction (stringly-typed cohort identity for ONE cohort), underkill in the other (no Region story). Truth-substrate aggregator (Mary's shape) wins for v0. Groups become the candidate caching pattern when (a) a cross-cutting cohort lands not derivable from a single Interest (e.g., "hungry workers across all employers in this region") OR (b) profiling shows population queries in the simulation hot path.

Forward note added to placeholders.md.

---

## 3. Author Adjudications

### D1 — Population shape: Mary's methods over derived membership

**Locked.** Population aggregation lands as thin methods on existing types — `EmployerInterest.aggregate(account, op, period)` and `Region.aggregate_over(interest_filter, account, op, period)`. Cohort membership derives from the truth substrate (e.g., active `LaborContract`s for mill workers); no separate `Population` Resource. No `Population` subtypes. Reify only when a 2nd cohort lands and earns the abstraction.

**Author rationale:** v0 has one cohort (workers per employer). The macro-legibility consumer is named, but Cloud's identity-pays-back argument is unearned today. Methods compose; Resource locks identity prematurely.

**Aggregation operations (v0):** `AVG, SUM, MIN, MAX, COUNT`. No `distribution` (UI-shape, headless trace can't consume). No `count_above_threshold` (compose with `COUNT` + predicate when a caller asks).

**Forward note:** Godot groups become the candidate caching/index pattern when (a) cross-cutting cohort lands or (b) profiling shows population queries in the hot path. Documented in placeholders.md.

### D2 — Inference shape: Samus middle (parameter slot now, per-account precision later, no global Reading union)

**Locked.** Add `observer: Actor = null` parameter slot to `Book.balance(...)` and `Book.entries(...)` now. Default behavior unchanged (god-mode read). No `Reading` tagged union. Per-account precision shapes are forward-committed to per-consumer adapters when observer-gated reads land (Phase 6+).

**Author rationale:** "Develop it as we first start to experience it." The right precision-leak chokepoint is one observer-aware wrapper per consumer site, not one global type for the whole game. Cloud's structural-prevention argument is correct in principle but locks return shape on a guess.

**Confirmed:** player's own books always return precise. Encoded as the first guard clause when precision logic eventually lands.

### D3 — Knowledge graph location: defer entirely; handed to G

**Locked.** Counterparty IDs remain opaque `StringName`s in v0. No resolution layer. No `PlayerKnowledge` Resource. No per-actor knowledge book. Gossip-as-book-leaks captured as a design seed only — not an architectural commitment. G is the natural session to resolve this.

**Author rationale (methodological):**

> *"It's unclear to me how imperfect information will end up motivating actual NPC decisions since the gossip is inherently text in nature — seems like decision systems have to be built in such a way as to allow for perception that then impacts decision making to actually be intuitive, robust, and then ultimately visible. This is primarily why I wanted to drive elicitation through me rather than through the party first and then have them react — I think they are bringing some interesting ideas without a clear path to how programmatically we'd pull it off."*

This critique reshaped G's scope: G must address the full **perception → decision → action loop** as one architectural concern, not three. NPC perception is decorative unless it changes a decision somewhere observable. The agent-spawn conduct also shifts (see §7) — Socratic alternative-surfacing replaces papers-with-directives.

### D4 — Diagram convention: Mary's shape (current code + signature changes; placeholders ledger holds the rest)

**Locked, conditional on D1–D3.** Pass 1 of the architecture diagram (Stage 2.5) depicts current code post-Phase-3 — population aggregator methods on existing classes, `observer` parameter on `Book.balance`. Placeholders ledger holds the committed-but-unbuilt items (per-account precision shapes, knowledge graph, diegetic vocabulary, gossip substrate, NPC perception coupling).

**Author rationale:** Diagrams are the author's memory aid for "how the hell things work" — a current-state artifact, not a wishlist. Will be revisited as systems mature.

If D1 or D2 had landed Cloud's way, D4 would have tipped to filled-vs-outlined seams. The downstream-from-D1-D3 character of D4 is intentional.

---

## 4. Synthesized Design Directives

These flow from the author adjudications above. They are the architectural commitments E adds to the v0 codebase. Each directive cites its anchor adjudication.

### Population aggregation (D1)

1. **Population aggregation lands as methods on existing types**, not a `Population` Resource. Ship in Phase 3 (or wherever the macro-legibility traces first need them):
   ```
   EmployerInterest.aggregate(book_account: StringName, op: AggregateOp, period_start: int = -1, period_end: int = -1) -> float
   Region.aggregate_over(interest_filter: GDScriptType, book_account: StringName, op: AggregateOp, period_start: int = -1, period_end: int = -1) -> float
   ```
   `AggregateOp` is an enum: `AVG | SUM | MIN | MAX | COUNT`. No `distribution`. No `count_above_threshold`.

2. **Cohort membership derives from the truth substrate.** For workers-at-employer, that substrate is `accounts.contracts` filtered by `Contract.Status.ACTIVE` and `LaborContract.employer == owner.get_path()` — already exposed via `EmployerInterest.employees()`. No separate cohort store. No denormalization in v0.

3. **`Population` Resource is reified later, not now.** Trigger: a 2nd cohort that the methods-pattern doesn't accommodate cleanly (e.g., `RaisedRetinue`, `RegionalActors`, `RegionsExportingGood`). At that point, a refactor lifts the methods into a `Population` base class with subtypes. v0 ships methods.

### Book access & precision (D2)

4. **`Book.balance(...)` and `Book.entries(...)` gain an `observer: Actor = null` parameter slot now.** Default behavior unchanged — `observer == null` means god-mode precise read (today's only mode). All current call sites continue to compile and run. The parameter slot futureproofs call-site signatures for Phase 6+ observer-gated reads.

   ```gdscript
   func balance(account: StringName, period_start: int = -1, period_end: int = -1, observer: Actor = null) -> float
   ```

5. **Return type stays `float` in v0.** No `Reading` tagged union. No global precision shape. Per-account precision shapes are forward-committed to per-consumer adapters at the consumer site, when the first observer-gated reader lands (Phase 6+).

6. **Player's own books always return precise** when the player exists as an actor. Encoded as the first guard clause in the precision-resolution wrapper when that wrapper lands.

### Counterparty mystery & knowledge (D3)

7. **Counterparty IDs remain opaque `StringName`s in v0.** No display-name resolution. No `PlayerKnowledge` Resource. No per-actor knowledge book. Confirms the Phase 2.5 directive §5.3 commitment.

8. **NPC perception → decision coupling is G's load-bearing question.** v0 makes no architectural commitment. Gossip-as-book-leaks is captured as a design seed for G to evaluate against the perception-decision-action loop architecture G produces.

### Diagram convention (D4)

9. **Pass 1 architecture diagram (Stage 2.5) depicts current code post-Phase-3 + signature changes.** Population aggregator methods appear as new arrows on existing boxes (`EmployerInterest`, `Region`). The `observer` parameter appears in `Book.balance`'s signature documentation, not as a separate box. Placeholders ledger holds the committed-but-unbuilt items.

### Cross-cutting

10. **Time-period query helpers (`weeks_ago(N)`, `current_week`, etc.) live on `SimClock`, not on `Book`.** Books work in raw ticks; the SimClock helper translates calendar concepts to tick boundaries. Keeps Book agnostic to calendar semantics.

11. **Performance posture: O(n) journal walks remain the v0 implementation through Phase 5.** No per-account caches, no materialized rollups, no dirty-flag invalidation. Trigger to revisit: profiling shows population queries in the hot path of the simulation tick.

12. **`Activity.display_name` stays as no-op overhead.** Do not set it. Do not delete it. Do not surface it. Gate hardened to "first UI consumer (Phase 7/8)." Cost of leaving it: near-zero. Cost of removing then re-adding: real churn.

---

## 5. Open Questions (handed forward)

### Handed to Elicitation G — The Perception → Decision → Action Loop

- **NPC intent representation.** Goal Resource overlay vs. reactive-Interest-only vs. hybrid. Drives whether NPC knowledge needs a home.
- **NPC use of imperfect information.** If NPCs read with precision and decisions branch on noisy reads — what's the decision system's shape, and is the noise observable to the player as behavior? (The author's D3 critique cuts here directly.)
- **Gossip-as-book-leaks shape.** Samus's "books are truth, gossip is lossy book-leak" idea is preserved as a design seed. Programmatic path: who reads whose books with what precision, who shares it, with what decay, on what cadence. Untouched by E's directives; G must address.
- **Player command surface.** Player as Actor with `PlayerInterest` vs. command-bus issuer vs. commissioner-only ("invisible kingmaker"). Drives whether the player has books, contracts, etc.
- **Indirect action / commission shape.** New `CommissionContract` type vs. goal-injection vs. generalized `LaborContract`.
- **Disruption surface.** At perception (poison info), at action (abort/sabotage Activities), at relationship (break contract / reputation hit), or all three.
- **Action vocabulary extensibility recipe.** Subclass-and-ship (current pattern) vs. Activity factory + data-driven vocabulary vs. goal-language + Activity selection.

### Handed to Phase 6+ (when first observer-gated read consumer arrives)

- **Per-account precision shapes.** Vitals likely wants range/bucket; financial likely wants noisy magnitude; reputation likely wants decayed scalar. Designed at consumer site, not centrally.
- **The precision-resolution wrapper.** Where `observer` materializes into actual precision degradation. Likely a per-consumer wrapper layer, not a global API.

### Handed to Phase 7/8 (first UI consumer)

- **`Activity.display_name` resolution.** Per-Activity-class `const`/`_init`-set string vs. registry vs. localization-keyed. Lands at UI consumer time.
- **Diegetic vocabulary tone calibration.** "Bob worked a full day at the field; the harvest brought four sheaves home" tone vs. population-aggregated form. Untouched by E.

### Handed to design-parking-lot.md (no current pickup)

- **Knowledge graph for the player.** Cloud's `PlayerKnowledge` shape captured as a design seed; pickup at first UI consumer (likely Phase 8) IF G's intent architecture pushes toward player-side resolution. If G pushes toward per-actor knowledge (Samus's instinct), the parking-lot entry will need rewriting.

---

## 6. Placeholders Affected

See `_bmad-output/placeholders.md` for the full ledger. E's session updates:

- **`Activity.display_name`** — gate hardened to "first UI consumer (Phase 7/8)." Stays as no-op overhead; not built in v0. Resolution: Mary's deferred-with-reasoning posture.
- **NEW: Per-account precision shapes** — gated on first observer-gated read consumer (Phase 6+).
- **NEW: Gossip substrate (book-leak mechanics)** — gated on G's perception-decision-action loop architecture; the programmatic-path-not-just-aesthetic question.
- **NEW: NPC knowledge representation** — gated on G's intent architecture choice. May surface as per-actor knowledge book, or as nothing if NPCs operate on full-info gated by precision.
- **NEW: Godot-groups-as-cohort-cache** — gated on (a) cross-cutting cohort that doesn't derive from a single Interest, OR (b) profiling shows population queries in the hot path.
- **NEW: `Book.balance` signature change** (not strictly a placeholder, but a forward note) — `observer: Actor = null` parameter added; default behavior unchanged; per-consumer precision wrappers will land at Phase 6+.

---

## 7. Notes for Next Sessions

### G inserts as next session, not B

The roadmap §1 table updates: Stage **1G — The Perception → Decision → Action Loop** inserts after 1E.1 and before 1B. Stage 1B (Hunger) is now blocked on G, not just on E. Reasoning: hunger affects NPC decisions; without G's intent architecture, B has no anchor for "hungry workers behave differently."

### New elicitation conduct adopted (G onwards)

E ran under the legacy "papers with directives" conduct. The author's mid-session feedback locked a new Socratic conduct for all elicitations from G onwards:

- Round 1 agents surface alternatives, not finished designs.
- For each question: sharper reframing, what-to-ask-author-first (multi-question, not single-broad), tradeoff space, 2–3 alternatives with code touch-points, soft recommendation.
- Code-path grounding required for every alternative — name the class/file/method or flag that no current touch-point exists.
- "Design Directives" sections are written by orchestrator after author adjudication, not by each agent.
- Round 2 reactive (optional): agents respond to author locks with refinements, pushback, or downstream implications.
- Author-driven intent: author optionally pre-seeds Round 1 with their gut on load-bearing axes (G's intent representation + command surface) so agents react to author intent rather than producing clean-slate design space.
- Conversational cadence: many small specific questions, never one open-ended "so, what verbs?" type ask.

The agent-spawn template in companion §2 / roadmap §8.2 is updated accordingly.

### G's owner agents

Round 1: Cloud + Indie + Mary. Samus held back from Round 1 (aesthetic-led design without code paths is the failure mode this conduct shift targets); Round 2 reactive only. Sally + Link Freeman held for 1G.1 follow-up if command-surface UX or Godot-implementation guidance becomes the gating question.

### E may be re-scoped post-G

Once G ships, E may be retitled in roadmap §1 from "Macro-Legibility Primitives" to "Read-Side Primitives" — to make the perception/action symmetry explicit. Author option, not a commitment.

### Compatibility check — confirmed

War, Export/Import, and Reputation are all compatible with the locked adjudications. No directive in this paper precludes any of the three. The methods-not-Resource decision in D1 specifically defends export/import generalization. The `observer` parameter in D2 generalizes naturally to military and reputation reads.

---

— Author adjudication (Zach), with Cloud Dragonborn, Samus Shepard, and Mary in the room.
