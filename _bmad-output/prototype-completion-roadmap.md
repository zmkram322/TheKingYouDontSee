---
name: Prototype Completion Roadmap
status: master plan (drives all elicitation + phase planning sessions)
date: 2026-05-04
supersedes:
  - (re-buckets entries currently in _bmad-output/phase-3-backlog.md across phases — see §6)
relates_to:
  - _bmad-output/phase-2.5-books-activity-architecture-directive.md (architecture foundation — preserved)
  - _bmad-output/phase-2-math-directive.md (formulas — preserved)
  - memory/project_thekingdontSee.md (resume point)
authors:
  - Author adjudication (Zach)
  - Roundtable input (Cloud Dragonborn, Samus Shepard, Mary, Indie)
---

# Prototype Completion Roadmap

## 0. Preamble — What This Is and How To Use It

This document is the master plan that bridges Phase 2.5 (just shipped) to "prototype-complete + architecture diagram finalized." It is **the single input to every subsequent planning and elicitation session**. Each elicitation is structured so it can be run in a clean Claude Code conversation by reading this doc + the named pre-read files.

**Where we are (2026-05-04):**
- Phase 2.5 coding-pass shipped. Books + Activity + Force Carriers primitives in place. All 5 Phase 2 ACs reproduce on the 14-day headless trace.
- WorkPattern resource on LandPlot lets multi-good production land as sibling-class additions with no orchestration changes.
- Aptitudes (`aptitude_profile.gd`) exist as a Resource but no Actor uses one. Skills/XP wired but BASE_XP=0. Hunger/fatigue wired in VitalsBook but BASE_CALORIES/FATIGUE=0. These are intentional placeholders awaiting the design pass.

**The plan in one breath:** do a small cleanup pass, run six elicitation sessions to surface design intent for systems not yet fleshed out, write the actual phase plan from those answers, then build through phases until the prototype demonstrates economy + legibility, then finalize the architecture diagram and begin the first observation UI.

**How to use this document in a fresh session:**
1. Open this file (`_bmad-output/prototype-completion-roadmap.md`).
2. Identify which session you're running (cleanup pass, elicitation A–F, or phase plan write-up).
3. Load the named pre-read files (§3.x or §2 lists them).
4. Spawn agents per the recommended pattern (§8 has the operating procedure).
5. Capture the session output to the named output artifact.

---

## 1. The Plan at a Glance

| Stage | Name | Type | Output | Prerequisite |
|---|---|---|---|---|
| **0** | Cleanup pass (Phase 2.6) | Coding | Updated code + lean backlog | None — start now |
| **1A** | Elicitation: Aptitudes + XP + Skills | Party-mode session | `elicitation-a-output.md` | Stage 0 |
| **1B** | Elicitation: Hunger + Consumption + Vitals | Party-mode session | `elicitation-b-output.md` | Stage 0 |
| **1C** | Elicitation: Multi-Good Economy + Multi-Plot Employers | Party-mode session | `elicitation-c-output.md` | Stage 0 |
| **1D** | Elicitation: Lord Economy + Taxation | Party-mode session | `elicitation-d-output.md` | Stage 0 |
| **1E** | Elicitation: Macro-Legibility Primitives | Party-mode session | `elicitation-e-output.md` | Stage 0 |
| **1F** | Elicitation: Social + Morale + Reputation | Party-mode session | `elicitation-f-output.md` | Stage 0 |
| **2** | Prototype Phase Plan write-up | Synthesis session | `prototype-phase-plan.md` | Stages 1A–1F |
| **3** | Phase 3 implementation (likely Aptitudes+XP) | Coding directive + pass | `phase-3-directive.md` + code | Stage 2 |
| **4–7+** | Subsequent phases per phase plan | Coding directive + pass | per phase | prior phase |
| **N** | Architecture diagram + seam map | Synthesis + diagram | `architecture-diagram.{md,png}` + seam map | Sufficient phase coverage |
| **N+1** | First observation UI / debug HUD pass | Coding | UI scene | Diagram |

**Provisional phase ordering** (subject to revision after elicitations):

| Phase | Working name | Anchored elicitation |
|---|---|---|
| 3 | Aptitudes + XP + skill-driven productivity | A |
| 4 | Hunger + consumption + vitals readback | B |
| 5 | Multi-good economy + multi-plot employers | C |
| 6 | Lord economy + taxation | D |
| 7 | Macro-legibility primitives | E |
| 8 | Architecture diagram + first observation UI | (synthesis) |
| 9+ | Social + morale + reputation, then vertical slice | F |

Hunger placement (4 vs. 5) is the one explicit ordering question this plan defers to the elicitation phase. Group consensus from elicitation outputs decides.

---

## 2. Stage 0 — Cleanup Pass (Phase 2.6)

**Goal:** Land the unanimous-add backlog items, fix the one correctness landmine that's already in the code, kill the dead class, document the implicit decisions. Done before any elicitation so we're not eliciting against shifting code.

**Pre-read for the session running this pass:**
- `_bmad-output/phase-2.5-books-activity-architecture-directive.md` (architecture context)
- `_bmad-output/phase-3-backlog.md` (current backlog)
- `tkyds-game/scripts/activities/wholesale_sale_activity.gd` (the unit-cost landmine)
- `tkyds-game/scripts/activities/labor_contract_activity.gd` (wage-rate timing seam)
- `tkyds-game/scripts/interests/employer_interest.gd` and `tkyds-game/scripts/economy/work_pattern.gd` (job_category drift)

**Scope:**

1. **Fix #11 — unit-cost = 1.00 assumption in `WholesaleSaleActivity`**
   - Today: asserts `qty == total_revenue` and crashes on price ≠ 1.
   - Replace with: merchant Tx becomes 3-leg if `price ≠ unit_cost_basis`. Add `Cost_of_Inventory` adjustment account OR carry the price gap through a paired entry. Pattern matches `RetailPurchaseActivity`'s 3-leg buyer Tx.
   - Verify all 5 ACs still reproduce.

2. **Fix #13 — `EmployerInterest.job_category` ↔ `WorkPattern.job_category` drift**
   - Today: both fields set independently in bootstrap.
   - Resolve by: removing `job_category` from `EmployerInterest`; deriving it via `EmployerInterest._resolve_work_pattern().job_category` (same lookup path WorkingInterest already uses through ProductionInterest).
   - Verify post-clear LaborContract gets the correct job_id.

3. **Decide #15 — wage-rate locked-at-contract vs. recomputed-at-settlement**
   - Adopt: locked-at-contract (current behavior) for prototype.
   - Add a `wage_policy` seam: `LaborContractActivity` reads a (currently-default) lock-at-contract policy; phase 3+ "recomputed" becomes a sibling strategy.
   - Document the choice and its rationale in `labor_contract_activity.gd`.

4. **Address #14 — `WeeklyBurstActivity` unused as tree root**
   - Decision: **delete**. The orchestrator drives sequencing; the burst class doesn't earn its line. Remove `weekly_burst_activity.gd` and the ineffectual create-and-close in `window_orchestrator.gd`.
   - If a week-level audit anchor is wanted later, it'll be re-introduced with a real consumer.

5. **Document #19 — Activity ownership convention**
   - Add a comment block to `tkyds-game/scripts/activities/activity.gd` documenting the v0 rule: *"The actor whose Interest creates the activity owns the canonical instance in `accounts.activities`. Other participants find it via the activity tree from a known root. Concrete v0 ownership: WorkDayActivity → worker; WagePaymentActivity → employer; WholesaleSaleActivity → producer; RetailPurchaseActivity → merchant; LaborContractActivity → employer."*
   - This is the documentation seam; phase 3+ may evolve when multi-participant queries become first-class.

6. **Update `phase-3-backlog.md`** per §6 of this doc (rebucket entries).

7. **Create `_bmad-output/design-parking-lot.md`** for items rejected from backlog but worth capturing (per §6).

8. **Create `_bmad-output/placeholders.md`** per §7 of this doc (the placeholder ledger).

**Acceptance criteria:**
- All 5 Phase 2 ACs still reproduce on the 14-day headless trace.
- `WholesaleSaleActivity` no longer hard-asserts price = 1; can carry a non-unit price test through the Tx.
- `EmployerInterest.job_category` field removed; lookups go through plot.work_pattern.
- `WeeklyBurstActivity` and its orchestrator hooks deleted.
- `phase-3-backlog.md`, `design-parking-lot.md`, `placeholders.md` exist with §6 / §7 contents.

**Estimated size:** ~1 hour of code + tests + doc updates.

---

## 3. Stage 1 — Elicitation Series

### 3.0 Shared elicitation protocol

**Format:** `/bmad-party-mode` session. Spawn the named owner agents in parallel. Present each agent's response in full. After all four respond, the user (Zach) answers the questions interactively or schedules another round to go deeper on specific questions.

**Output:** Each elicitation produces an output artifact (e.g. `_bmad-output/elicitation-a-output.md`) that captures:
- Each agent's framing of the system
- Zach's answers to the questions (synthesized or verbatim)
- The set of design directives the elicitation produces
- Open questions deferred to a later elicitation or phase

**Operating notes:**
- Each elicitation is **independent**. Run them in any order; ordering for *implementation* (which phase first) gets settled in Stage 2 (Phase Plan write-up) after all six are answered.
- Each elicitation has its own pre-read list. Loading those is the first action of the session.
- If an elicitation surfaces a question better answered by another elicitation, defer cleanly — note it in the output artifact and let the next session catch it.

**Recommended agent owners** (cited in each section below). All are spawned via `general-purpose` subagent_type with persona injection in the prompt — see §8 for the spawn template.

---

### 3.1 Elicitation A — Aptitudes + XP + Skills

**Working title:** *"What does it mean to be skilled in this world?"*

**Owner agents:** Samus Shepard (game designer, player-feel) + Cloud Dragonborn (architect, force-carrier compliance) + Mary (analyst, "is the math load-bearing")

**Pre-read:**
- This document (§3.1)
- `_bmad-output/phase-2.5-books-activity-architecture-directive.md` §2.3 (SkillsBook), §3.4 (work activity hierarchy + aptitude weights)
- `_bmad-output/phase-2-math-directive.md` §1 (wage formula uses skill_factor)
- `tkyds-game/scripts/resources/aptitude_profile.gd` (the unused class)
- `tkyds-game/scripts/activities/farming_slot_activity.gd` (BASE_XP=0, aptitude_factor=0)
- `tkyds-game/scripts/activities/farming_day_activity.gd` (skill_id=&"farming")
- `tkyds-game/scripts/sim/wage_calculator.gd` (reads SkillsBook for skill_factor)
- `tkyds-game/scripts/economy/jobs/farming.tres` (calibration: x_0=100, a=1.0, base_skill=2.0)
- `memory/project_thekingdontSee.md` "PROTOTYPE ARCHITECTURE — LOCKED" section (three-tier actor model)

**Project context capsule:**

The world has a three-tier actor model: aptitudes (ATH/CHA/INT, fixed traits) → skills/XP (per-skill accumulation, weighted by aptitude) → behavior/economy. Phase 2.5 wired SkillsBook and the WageCalculator to read XP, but no XP accrues today (BASE_XP=0) and no actor has an aptitude profile. The wage formula `max(minimum_wage, skill_value × scarcity)` collapses to minimum_wage in v0 because xp=0. This elicitation surfaces the design intent so Phase 3 can flesh out the productivity layer.

**Current placeholders (file:line):**
- `farming_slot_activity.gd:12` — `BASE_XP := 0.0` ("aptitudes not yet integrated")
- `farming_slot_activity.gd:46-48` — `_aptitude_factor()` returns 0.0
- `farming_slot_activity.gd:51-54` — `_variance(_factor)` returns 0.0 (deterministic; no roll)
- No Actor has an `aptitude_profile` field; the Resource exists but is unused.
- `wage_calculator.gd` reads SkillsBook for xp; works, but always returns 0 → minimum_wage floor.
- LaborContract.wage_per_slot is locked-at-contract (per Stage 0 cleanup decision).

**System questions (mechanical):**
1. **Distribution.** How are aptitudes (ATH/CHA/INT) generated for an actor? Random uniform? Archetype-biased? Inherited (parent → child in long-running sims)?
2. **Mutability.** Are aptitudes fixed at creation, or do they drift (slowly, with use)? Is "trained body" different from "raw athletic potential"?
3. **XP curve shape.** The current formula `skill_factor = (1 - exp(-xp/x_0))^a` saturates. Is saturation right, or do we want skill ceilings that need separate breakthroughs (apprentice → journeyman → master)?
4. **Per-skill granularity.** Today only `&"farming"` exists. What's the right list of skills for the prototype? (`farming`, `bartering`, `market_perception`, `charisma`, `smithing`?) Are skills discovered through use, or always present at zero?
5. **Aptitude → skill mapping.** Per the directive, aptitude weights live as class-level constants on each work-activity class. For farming: W_ATH=0.7, W_CHA=0.0, W_INT=0.3. Confirm? What about the day-aggregated XP — does it use the same weights, or does the day-level cluster reward something different (consistency, completion)?
6. **Wage update cadence.** Locked-at-contract means rate doesn't change as worker skills grow. When does a worker's growing skill reach their wage? Renegotiation at contract end? New contract? Per-period bonus?
7. **Failure modes.** Can a worker have *negative* skill (e.g., injury, sickness, age)? Or does floor at 0?
8. **Wage formula extensions.** The formula has `minimum_wage`, `skill_value`, `scarcity`. Should it also factor employer's wealth, the worker's reputation, or a separate "ask"?
9. **Variance.** Should slot-level production have deterministic output (current placeholder) or stochastic variance (the `_variance()` hook)? If stochastic, what's the band, and what gameplay does variance enable?

**Experience questions (player-feel):**
1. **The "best farmer in the village" reading.** When the player is told "Bob is the most skilled farmer here," what makes that legible in the world? A statistic on a sheet? Behavioral cue (he works faster, finishes first)? Social cue (others defer to him)?
2. **The long arc.** A worker who farms for 5 years — what should that LOOK like? Should the player notice "Bob has clearly been farming a long time" without being told?
3. **Information asymmetry.** Should actors KNOW their own skills? Should they know each other's? Is there a fog-of-war on stats?
4. **Skill diff felt.** When a 50-XP farmer and a 200-XP farmer work the same plot, what's the player-felt difference? Output volume? Output quality? Resilience under stress?
5. **The ceiling/breakthrough question.** Is there a moment of "I leveled up" — explicit milestone — or pure curve?
6. **Ambient vs. directed growth.** Is XP something that just happens through work, or do players direct training (apprenticeships, schools)?

**Output artifact:** `_bmad-output/elicitation-a-output.md` — answered questions, design directives, Phase 3 spec inputs.

---

### 3.2 Elicitation B — Hunger + Consumption + Vitals

**Working title:** *"What does hunger feel like in this world?"*

**Owner agents:** Samus Shepard (player-feel + gameplay loop) + Cloud Dragonborn (force-carrier — every state mutation through an activity) + Indie (YAGNI on scope)

**Pre-read:**
- This document (§3.2)
- `_bmad-output/phase-2.5-books-activity-architecture-directive.md` §2.3 (VitalsBook), §4.1 (force carrier table — EatGrainActivity DEFERRED), §10 (deferred items list)
- `tkyds-game/scripts/books/vitals_book.gd`
- `tkyds-game/scripts/activities/farming_day_activity.gd` (writes hunger/fatigue at 0)
- `tkyds-game/scripts/interests/grain_interest.gd` (outstanding_demand exists, unused for hunger)
- `memory/project_thekingdontSee.md` "Needs & Actor Model" + "Economic Model" sections (subsistence floor, hunger-strike trigger, minimum-viable-emergence threshold)

**Project context capsule:**

The Phase 2.5 directive deferred `EatGrainActivity` and the consumption system entirely (R2.4). VitalsBook exists with `hunger` and `fatigue` accounts; FarmingDayActivity writes to them with BASE_CALORIES=BASE_FATIGUE=0. No actor consumes their own grain. The famine cascade is the minimum-viable-emergence demonstration target from the project's earliest design notes — when hunger lands, it must connect productivity (hungry workers produce less), demand (hungry actors buy more), and morale (hunger + low morale → strike). The directive flagged hunger as a phase-of-its-own.

**Current placeholders (file:line):**
- `farming_slot_activity.gd:14-15` — `BASE_CALORIES := 0.0`, `BASE_FATIGUE := 0.0` ("hunger system deferred (R2.4)")
- `farming_day_activity.gd:64-68` — VitalsBook writes are conditional on amount > 0; today nothing is written.
- No `EatGrainActivity` class exists.
- `GrainInterest.outstanding_demand` accumulates and decays, but nothing reads it as hunger pressure.
- VitalsBook has no `morale` writes.

**System questions (mechanical):**
1. **Hunger metric.** Is hunger a single VitalsBook account that depletes daily and replenishes when eating? Or a balance (calories in - calories out)?
2. **Cadence.** Daily-tick depletion (one entry per day per actor)? Event-driven (on work activity, on day-close)? Different for different actors?
3. **EatGrainActivity shape.** Is it persistent (audit value: "Bob ate at sundown")? Transient inside a daily routine? Or is eating a *non-activity* daily-close hook that just writes a VitalsBook entry?
4. **Consumption source.** Eat from own inventory only, or can actors buy-and-immediately-consume at retail in one event? Does inventory have a "household consumption" pre-allocation (private subtraction — finally landing here)?
5. **Productivity feedback.** When hunger crosses thresholds, does production drop? Linear? Stepwise (HUNGRY = 0.7×, STARVING = 0.3×, DYING = 0×)?
6. **Demand feedback.** Hungry actors with outstanding_demand — does their want curve shift up (higher A in the isoelastic formula)? Lower elasticity (more desperate, more inelastic)?
7. **Failure modes.** Hunger strike (no work). Departure (leave the region). Death (full removal from the actor list). Illness (intermediate state)?
8. **Food choice.** Today only grain. When bread/meat exist, are they substitutes (same hunger restoration) or differentiated (better food = better morale, satiety duration, social status)?
9. **Aggregation.** "Workers at this mill are usually well fed" — is that a `Population.balance_avg("hunger", week)` query? (Foreshadow Elicitation E.)

**Experience questions (player-feel):**
1. **The famine cascade.** Imagine a region where the harvest fails. What does the player SEE in the trace, and later in the UI? Is it "everyone's hunger meter goes down" or "actors do different things — leave, riot, beg, hoard"?
2. **First encounter.** When does the player first encounter hunger as a force? In-tutorial (forced)? Emergent (notice it themselves)? Direct (their own actor gets hungry)?
3. **Reading hunger.** Should hunger be visible as a number, a state name (HUNGRY), or pure behavior (Bob is slumping, Bob hasn't shown up to work)?
4. **Wealth differentiation.** Should rich actors visibly eat differently from poor actors? Is "what you eat" a status signal?
5. **Pressure dial.** Is the goal of hunger to ALWAYS create scarcity pressure (everyone is one bad week from trouble), or to USUALLY be in the background and occasionally bite (most actors are fed; a marginalized few starve)?
6. **Gameplay leverage.** What can the player DO about hunger? Buy and distribute food? Manipulate prices? Hire workers from a hungry village? Influence a lord to release stores?

**Output artifact:** `_bmad-output/elicitation-b-output.md`.

---

### 3.3 Elicitation C — Multi-Good Economy + Multi-Plot Employers

**Working title:** *"What's the second good, and what does it teach us?"*

**Owner agents:** Mary (economic rigor) + Cloud Dragonborn (architecture stress test) + Samus Shepard (player-felt diversity)

**Pre-read:**
- This document (§3.3)
- `_bmad-output/phase-2-math-directive.md` §2 (isoelastic demand, equilibrium, GoodConfig pattern)
- `_bmad-output/phase-3-backlog.md` "Multi-good economy + cross-price elasticity" entry
- `tkyds-game/scripts/economy/work_pattern.gd` (the abstraction the second good will exercise)
- `tkyds-game/scripts/economy/goods/grain.tres` (template for new GoodConfig)
- `tkyds-game/scripts/activities/wholesale_sale_activity.gd` (post-cleanup; should handle non-unit price after Stage 0)
- `tkyds-game/scripts/markets/retail_market.gd` (single-good clear; multi-good needs per-good clearing)
- `tkyds-game/scripts/resources/labor_contract.gd` (no `production_resource` field yet)

**Project context capsule:**

v0 has one good (grain) and one plot. The Phase 2.5 rebuild added `WorkPattern` on `LandPlot` so adding a second good means: new GoodConfig `.tres`, new WorkPattern `.tres`, new pair of Activity subclasses (e.g. `BakingSlotActivity` / `BakingDayActivity`), new actors who produce/consume. The architecture is ready; the design isn't. This elicitation chooses the second good and resolves the questions a second good forces (multi-plot employers, cross-price elasticity, intermediate products).

**Current placeholders (file:line):**
- Only one `GoodConfig` exists (`grain.tres`).
- Only one `WorkPattern` exists (`grain_farming.tres`).
- `LaborContract` has no `production_resource: NodePath` — single-plot-per-employer assumed.
- `MercantileInterest.wholesale_cost_per_unit` is single-batch (overwritten each wholesale buy; no weighted-avg across multi-supplier purchases).
- `RetailMarket` clears one `good_id` at a time; multi-good means N independent retail clearings (or one clearing with per-good sub-pools).
- `Population.balance_avg` and friends don't exist (needed when "average wheat consumption per worker" type queries land).

**System questions (mechanical):**
1. **Choice of second good.** Bread (intermediate, needs grain input)? Cloth (parallel, independent supply chain)? Ale (intermediate, time-consuming)? Tools (durable, infrequent purchase)? Each teaches a different architectural lesson — which lesson do we want to take next?
2. **Intermediate vs. parallel.** If bread: there's a Baker actor who buys grain wholesale, transforms it, and sells bread at retail. That introduces a transformation activity (`BakeBreadActivity`?) and a multi-stage supply chain. If cloth: parallel to grain, simpler. Which?
3. **Cross-price elasticity.** Today demand uses `Q_d = A × P^(-e_g)` per good independently. With two goods, do we model substitution (cheap bread → less grain bought)? Complementarity (bread needs ale)? Or keep independent for prototype?
4. **Multi-plot employer.** Lord Harwick owns a wheat field and a cloth-spinning workshop. Same `EmployerInterest`, different `ProductionInterest` per plot? Or two `EmployerInterest`s, one per plot?
5. **Contract→plot binding.** `LaborContract.production_resource: NodePath` — necessary if a worker contracts for "the wheat field, not the workshop." When does this land?
6. **Worker mobility across plots.** Does a single worker work multiple plots in a day, or are workers plot-bound? Implication for the WorkDay tree.
7. **Job category drift fix re-tested.** After Stage 0, EmployerInterest.job_category is gone. The plot's WorkPattern.job_category drives contract creation. Does this hold under multi-plot?
8. **Cost basis with non-unit prices.** The Stage 0 cleanup makes `WholesaleSaleActivity` price-flexible. With cloth at price 1.5 and grain at price 1.0, the merchant carries inventory at different per-unit costs. Cost basis at retail clearing — weighted average across all goods on hand? Per-good?
9. **Independent vs. combined market clearing.** Do all retail goods clear at the same week burst (independent per good)? Same merchant clears N goods, each with its own equilibrium price?

**Experience questions (player-feel):**
1. **Diversity meaning.** Does the player perceive grain-vs-bread as economically meaningful, or just decorative variety? What's the gameplay leverage point?
2. **Specialization.** "This region grows grain, that region bakes bread" — is regional differentiation a stated goal, or an emergent observation?
3. **The first non-grain transaction.** When does the player notice the second good differs? Price diverging? Different actors producing? Different demand patterns?
4. **Player as merchant.** When the player becomes a merchant (per the GDD progression — first land purchase → first market stall → first enterprise), do they trade in multiple goods, or specialize? Does specialization feel like a choice?
5. **Scarcity asymmetry.** Should one good be reliably available and another reliably scarce, OR should both fluctuate together?

**Output artifact:** `_bmad-output/elicitation-c-output.md`.

---

### 3.4 Elicitation D — Lord Economy + Taxation

**Working title:** *"Is the lord an actor or a force?"*

**Owner agents:** Samus Shepard (lord archetypes + player relationship) + Mary (taxation flow + economic role) + Cloud Dragonborn (architecture: lord-as-actor implications)

**Pre-read:**
- This document (§3.4)
- `_bmad-output/phase-2.5-books-activity-architecture-directive.md` §4.1 (TaxPaymentActivity in force-carrier table — deferred)
- `_bmad-output/phase-3-backlog.md` "Labor strategies wired to lord archetypes" entry
- `memory/project_thekingdontSee.md` "Economic Model" → Lord tax bullet, "Influence & Progression" section, "Regions" section (lord behavioral archetypes), "Locked Decisions" → No lord AI in prototype
- `memory/project_labor_strategy.md` (per-region matcher strategy hook, threads economy↔influence)

**Project context capsule:**

The world model has lords in five archetypes (extractive, mercantile, military, corrupt, absent) intersecting with regional resource profiles to create regional character. Locked decision: no lord AI in the prototype — only a tax rate as a float (coin sink). But the prototype is now closer to "complete" than expected, and the directive named TaxPaymentActivity as a real force-carrier candidate. This elicitation decides whether the lord lands in the prototype as a first-class actor or stays a force-only abstraction.

**Current placeholders (file:line):**
- No Lord actor type. No `LordInterest`. No `LordEconomicArchetype` enum.
- `Accounts.A_LORD_TAX_EXPENSE` named in the chart of accounts but never written.
- No `TaxPaymentActivity`.
- `LaborMarket.ClearingStrategy.CHARISMA_PICK` and `PRODUCTIVITY_RANK` are enum stubs without bodies — these were earmarked for lord archetypes.

**System questions (mechanical):**
1. **Actor or force.** Does the lord exist as an Actor with their own books, interests, and behavior loop? Or as a regional system (a tax rate, a strategy enum, no agency)?
2. **Tax base.** What gets taxed? Transactions (sales tax)? Income (worker wages)? Land/property (annual)? Inventory (windfall)? All?
3. **Tax cadence.** Per transaction (immediate)? Weekly burst step? Monthly? Harvest-time (seasonal)?
4. **Lord's books.** If lord-as-actor: does the lord have a FinancialBook with tax revenue accruing as `Sales_Revenue` or a new `Taxes_Revenue` account?
5. **Revenue deployment.** Where does tax money go? Buys things (luxuries, services)? Pays soldiers (PayRetinueActivity)? Inert pile?
6. **Archetype differentiation.** Are extractive/mercantile/military/corrupt/absent the same actor type with different parameters (rate, strategy, deployment), or different actor subclasses with different behavior?
7. **Loops to other systems.** Lord's labor strategy (CHARISMA_PICK vs. PRODUCTIVITY_RANK) — does this thread directly to lord archetype config?
8. **Multiple lords.** One per region? Hierarchical (regional lord under a king)? At what scope does the prototype demonstrate this?
9. **Player as lord-payer first.** The player starts as an outsider/debtor. They pay taxes before they ever become a lord. What's the player-side TaxPaymentActivity look like?

**Experience questions (player-feel):**
1. **Lord's presence.** "Lord X is harsh; Lord Y is fair" — what makes that legible? Visible tax stamp on transactions? Witnessed events (a tax collector visits)? Pure behavioral observation (everyone in region X is poor)?
2. **The reading moment.** "This lord has been operating at a loss for two months — someone has been loaning him money" — when the player notices this, what tools do they have to USE the information?
3. **Lord as obstacle vs. lever.** Early game: is the lord an obstacle (taxes hurt)? Late game: is the lord a lever (player influences lord decisions)?
4. **Corruption surface.** Is bribery / tax evasion a player-relevant mechanic at prototype scope?
5. **Visibility scope.** Does the player see other actors' tax payments, or only their own? (Foreshadows the book-access gates of Elicitation E.)
6. **Prototype demo target.** What's the demo moment that proves "lords matter" in the prototype? (Reference point: the famine cascade demonstrates "economy matters" — what's the equivalent for "lordship matters"?)

**Output artifact:** `_bmad-output/elicitation-d-output.md`.

---

### 3.5 Elicitation E — Macro-Legibility Primitives

**Working title:** *"How does the player learn what's true without the game telling them?"*

**Owner agents:** Samus Shepard (macro-legibility lens — the orientation she co-locked) + Sally (UX, reading-in-context) + Paige (information design — accessibility + visual precision) + Cloud Dragonborn (architecture seam authority)

**Pre-read:**
- This document (§3.5)
- `_bmad-output/phase-2.5-books-activity-architecture-directive.md` §1.1 (macro-legibility orientation), §5.2 (population queries v0.5), §5.3 (counterparty mystery seam), §6 (player-legibility framework — book access, vocabulary, gates)
- `tkyds-game/scripts/books/book.gd` (period query primitives — `balance(account, start, end)`, `entries(...)`)
- `tkyds-game/scripts/interests/employer_interest.gd` (`employees()` enumerable seam already present)
- `tkyds-game/scripts/activities/activity.gd` (`display_name` field — exists, no consumer)
- `tkyds-game/scripts/resources/accounts.gd` (universal chart of accounts — counterparty StringNames)
- `memory/project_thekingdontSee.md` "Macro-Legibility Orientation", "Tail Events & Observability", "Tutorial & Onboarding" sections

**Project context capsule:**

The macro-legibility orientation locked during Phase 2.5 D1 adjudication is the foundation: player-facing target is *"the workers at this mill are usually well fed"*, *"this lord has been operating at a loss for two months"* — time-aggregated AND population-aggregated patterns, not per-moment detail. The Books primitive ships time-period queries on per-actor scale today. The cross-actor population API is deferred (v0.5). The inference layer (precision-graded reads) is named in the directive but unimplemented. This is the elicitation Cloud and Samus called load-bearing for the architecture diagram itself; Mary and Indie called premature. Resolving that disagreement is part of this session's work.

**Current placeholders (file:line):**
- `book.gd` ships `balance(account, period_start, period_end)` and `entries(...)` — single-actor primitives.
- `employer_interest.gd:filled_positions()` and `employees()` — population enumeration seam ("the workers at this employer").
- No `Population` resource type, no `population.balance_avg(...)` method.
- `activity.gd` has `display_name: StringName = &""` field — never set or consumed.
- No book-access gating (anyone reading any actor's books gets precise floats).
- No knowledge graph for counterparty mystery — `Payable:rival_lord_castellan` resolves to no display name.

**System questions (mechanical):**
1. **Population API location.** Is it a `Population` Resource (typed: `MillWorkers`, `RegionalActors`, `LordsDomain`) with its own `balance_avg`, or methods bolted onto `Region` / `EmployerInterest`?
2. **Aggregation operations.** What aggregation operations matter at prototype scope? `avg`, `sum`, `min`, `max`, `distribution`, `count_above_threshold`?
3. **Inference layer shape.** Is precision returned as: an enum (UNKNOWN/POOR/MIDDLING/PROSPEROUS)? A noisy float (true_value × (1 + noise))? A range pair (low, high)? Different for different account types?
4. **Precision tiers (§6.2).** Cheap (behavioral observation), moderate (mood/posture), expensive (financial). How does code request a particular tier? `book.balance_with_precision(observer, account, period)` — observer's investment determines precision returned.
5. **Knowledge graph location.** Per-actor field (`actor.knows_about: Dictionary`)? An autoload service (`KnowledgeGraph.resolve(observer, counterparty_id) -> display_name | null`)? Per-Region?
6. **Counterparty resolution gating.** When does an opaque `&"rival_lord_castellan"` resolve to "Lord Harwick of Eastfield"? Player meets him? Player hears his name in a tavern? Player buys a tip?
7. **Diegetic vocabulary.** Where does `Activity.display_name` get set? In the Activity's `_init`? In a separate registry? Per-locale?
8. **Player's own books.** Always free + precise to read. Confirmed?
9. **Time horizon.** Multi-period queries today require explicit `period_start, period_end`. Should there be helper conventions (`weeks_ago(8)`, `current_week`)? In the Book class or in a SimClock helper?
10. **Performance posture.** Today journal walks are O(n). When does that bite? Prototype trace is small; what's the trigger to introduce per-account running-balance caches?

**Experience questions (player-feel):**
1. **The first noticing moment.** First human beat where the player catches the simulation doing something they can use. What does that look like? Tavern overhear? A tax-payable line you weren't supposed to see? A pattern in prices over weeks?
2. **Information as resource.** Is information itself a resource (must be acquired, has cost, decays)? Or always free once observed? The §6.2 precision tiers say "cost varies by source" — what does cost look like in-game (time, coin, relationship)?
3. **Precision granularity.** Player-character's own books = precise. Everyone else = abstracted. How abstracted? "Approximately 50 grain" vs "many grain" vs "appears prosperous" — when does each level appear?
4. **The investigation arc.** Player wonders why Lord Harwick is operating at a loss. What's the gameplay surface for digging in? Tavern talk → bribed steward → witnessed transaction?
5. **Tavern talk specifically.** What are the mechanics? Other actors observe (their books update); they share what they observed (gossip flows); player listens. Is it a free flow or rate-limited?
6. **Counterparty as mystery.** When the player sees `Payable: rival_lord_castellan +500` — what's their tool to find out who that is? Is the *not-knowing* the point?
7. **Diegetic vocabulary cap.** A line of UI says "Bob's WorkDay closed: 4 grain produced." Bad. What's the diegetic equivalent? "Bob worked a full day at the field. The harvest brought four sheaves home." Tone calibration matters.
8. **Architecture diagram question.** Should the population aggregation API and the inference layer be on the architecture diagram as named seams (even if v0 stubs) or only when actually built? (Cloud/Samus say YES, Indie/Mary say NO. Resolve here.)

**Output artifact:** `_bmad-output/elicitation-e-output.md`.

---

### 3.6 Elicitation F — Social + Morale + Reputation

**Working title:** *"What is reputation, and who gets to know yours?"*

**Owner agents:** Samus Shepard (social loop + relationships) + Sally (UX of social interaction) + Cloud Dragonborn (book/activity architecture for ReputationBook)

**Pre-read:**
- This document (§3.6)
- `_bmad-output/phase-2.5-books-activity-architecture-directive.md` §4.1 (SocializeActivity in force-carrier table — partner books symmetrically), §6.2 (ReputationBook in book-access table — phase 3+, "network access cost, gossip-flavored, decays with source contact"), §10 (deferred items)
- `tkyds-game/scripts/books/vitals_book.gd` (morale account named, never written)
- `memory/project_thekingdontSee.md` "Worker model" → morale modifier + hunger-strike trigger, "Influence & Progression" → two-axis influence model

**Project context capsule:**

Social, morale, and reputation are the third VitalsBook category (alongside hunger, fatigue) and a candidate fourth Book entirely. Phase 2.5 named ReputationBook as a `null` placeholder slot in the actor's `books` dictionary. The directive's SocializeActivity row writes morale ↑, fatigue ↓ on initiator; charisma XP; partner books symmetrically. Project memory has the locked decisions: hunger-strike triggers at low hunger + low morale; two-axis influence model (direct via coin, indirect via stats — passive draw and threat surface). This elicitation surfaces what reputation IS and how it accumulates.

**Current placeholders (file:line):**
- `accounts.gd` `books["reputation"]` slot is documented as "Phase 3+ may add" — no `ReputationBook` class exists.
- `vitals_book.gd` has no morale entries written.
- No `SocializeActivity`.
- `aptitude_profile.gd` has CHA but no work pattern uses CHA weight today.

**System questions (mechanical):**
1. **Reputation locality.** Per-actor scalar (everyone agrees Bob is liked)? Per-pair (what A thinks of B, possibly different from what C thinks of B)? Per-group (Bob's reputation among lords vs. among workers)?
2. **ReputationBook accounts.** If it's a Book — what are the accounts? `Trust:bob`, `Esteem:bob`? Or one entry per gossip-event-witnessed?
3. **Accumulation mechanism.** Discrete events (SocializeActivity, observed transactions, witnessed events)? Or aggregated from primary observations (every time you see Bob be honest, +trust)?
4. **Decay.** Does reputation decay without contact? At what rate? Does decay differ by initial weight (one big betrayal = persistent; small transgressions fade)?
5. **Morale source loop.** Morale up from successful socializing, eating well, getting paid? Down from hunger, fatigue, betrayal? What's the integration point with VitalsBook?
6. **SocializeActivity shape.** Is it persistent or transient? Pair of actors (initiator + partner, books written symmetrically)? Or one-actor-broadcasts (gossip in a tavern)? What's the daily cadence?
7. **Failure modes.** Hunger strike as established (low hunger + low morale). Other morale-driven behaviors — refusal to work, sabotage, departure, revolt?
8. **Influence integration.** Per the locked two-axis influence model: direct (coin) + indirect (stats). Does reputation feed into indirect influence? How does threshold-listener architecture (project memory) read it?
9. **Player's reputation.** Does the player have a reputation that precedes them? Does it differ by region/group? Is it visible to the player?
10. **Reputation as gate.** Can a sufficiently-low reputation actor be refused trade? Refused work? Driven from town?

**Experience questions (player-feel):**
1. **Tavern scene.** What are the mechanics — interaction, observation, listening? What does the player DO in a tavern? Approach an actor and ask? Sit and overhear? Buy a round and unlock conversation?
2. **First non-economic interaction.** When does the player first experience an actor relationship that isn't a trade? Tutorial-forced? Emergent?
3. **The criminal arc.** Is it ever a goal to maintain a low reputation (shadow path from the GDD)? What's the gameplay loop there?
4. **Reputation reading.** "Bob is well-liked" — how is that legible? Behavior of others around him (deference)? UI affordance? Direct readout?
5. **Player reputation visibility.** Can the player see their own reputation? Or only infer from behavior?
6. **Reputation surprise.** Should there be moments where the player learns their reputation in someone's eyes is different from what they thought? (Tied to Elicitation E — counterparty mystery applied to social.)
7. **Pacing.** When does the social/reputation loop become MEANINGFUL in the prototype? Phase 7? Phase 9? Vertical slice?
8. **Scope guard.** Indie's voice: most social-system designs blow up. What's the smallest possible reputation system that demonstrates the principle without becoming a black hole?

**Output artifact:** `_bmad-output/elicitation-f-output.md`.

---

## 4. Stage 2 — Prototype Phase Plan Write-Up

After all six elicitations are complete, run a synthesis session.

**Pre-read:** All six `elicitation-{a,b,c,d,e,f}-output.md` files + this document + `phase-3-backlog.md`.

**Owner agents:** Cloud Dragonborn + Samus Shepard + Mary (the trio who triaged this round). Optional: Indie for YAGNI sanity.

**Output artifact:** `_bmad-output/prototype-phase-plan.md`. Contains:
- Final phase ordering (3 → N) with dependencies and rationale
- Per-phase: scope, ACs, exit criteria, light defaults for things still unfleshed
- Architecture diagram dependencies (which phase outputs unblock the diagram)
- Updates to `placeholders.md` as placeholders are scheduled for resolution

This is where the hunger-placement question (phase 4 vs. 5) gets locked.

---

## 5. Stage N — Architecture Diagram + Seam Map

After enough phases land that the architecture is "stable enough to draw," write the seam map first, then the diagram.

**Seam map** (`_bmad-output/architecture-diagram-seams.md`): enumeration of every architectural seam — present and projected. Resolves the Cloud/Samus vs. Indie/Mary disagreement by structure: present seams are documented because they exist; projected seams are documented because they're load-bearing for the architecture's IDENTITY (macro-legibility), even if not built. Each seam: name, code location (or "stub"), responsibility, downstream consumers.

**Diagram** (`_bmad-output/architecture-diagram.{md,png,svg}`): visual reference. Boxes are actors, books, activities, markets, autoloads. Arrows are reads, writes, signals, calls. Dashed boxes are projected seams from the seam map.

**Owner:** Paige (information design) + Cloud Dragonborn (architecture truth) + Samus Shepard (does it tell the macro-legibility story).

---

## 6. Lean `phase-3-backlog.md` Update (Stage 0)

Updates committed during the cleanup pass. Result: `phase-3-backlog.md` becomes a strict "deferred-with-seam" doc. Items not meeting that bar move out.

**ADD as new entries:**
- **#11** v0 unit-cost = 1.00 assumption *(addressed in Stage 0 cleanup; remove from backlog once fix lands)*
- **#13** EmployerInterest.job_category ↔ WorkPattern.job_category drift *(addressed in Stage 0; remove once fix lands)*
- **#15** Wage-rate-locked-at-contract vs. recomputed-at-settlement *(decision committed in Stage 0; entry stays as a `wage_policy` extension hook)*

**MOVE (out of backlog into the phase plan or parking lot):**
- #1 EatGrainActivity → scope of Phase 4 (Elicitation B)
- #7 Population aggregation API → scope of Phase 7 (Elicitation E)
- #16 TaxPaymentActivity → scope of Phase 6 (Elicitation D)
- #17 SocializeActivity / morale → scope of Phase 9 (Elicitation F)
- #12 Multi-plot employer → scope of Phase 5 (Elicitation C)

**MOVE to `_bmad-output/design-parking-lot.md`** (per Mary's recommendation — captured but not actively tracked):
- #2 ReputationBook (no seam yet; Elicitation F may produce one)
- #8 Player-knowledge graph (design pillar; Elicitation E may scope it)
- #9 Diegetic vocabulary surfacing (UI-layer; Elicitation E may scope)
- #10 Book-access gates by precision level (Elicitation E will define)

**KEEP IMPLICIT (no entry needed):**
- #3 Trend-shape query helpers — YAGNI; build at second consumer
- #4 Journal indexing — premature; profile first
- #5 Pruning policy — defer until pain
- #6 Save/load at scale — defer until shape is stable
- #18 Recurring persistent-vs-transient pattern instances — rule is locked, instances are feature work
- #20 Self-consumption read — folds into existing "private subtraction" backlog item

**KEEP DELETED (Stage 0 cleanup actually deletes the code):**
- #14 WeeklyBurstActivity unused as tree root → deleted in Stage 0

---

## 7. Placeholders Ledger (Stage 0)

Single index of every stubbed value/behavior in current code. Lives at `_bmad-output/placeholders.md`. Maintained as code evolves.

**Format per entry:**
```
### [Name]
- **File:line:** `relative/path.gd:LINE`
- **Current value/behavior:** ...
- **Real version gated on:** [phase / elicitation / event]
- **Trigger to revisit:** [condition]
```

**Initial entries** (committed during Stage 0):

- **`FarmingSlotActivity.BASE_XP`** — current 0.0, real value gated on Elicitation A + Phase 3, trigger = aptitudes integrated
- **`FarmingSlotActivity._aptitude_factor()`** — returns 0.0, gated on Elicitation A + Phase 3
- **`FarmingSlotActivity.BASE_CALORIES`** / **`BASE_FATIGUE`** — both 0.0, gated on Elicitation B + Phase 4
- **`FarmingSlotActivity._variance()`** — returns 0.0 (deterministic), gated on Elicitation A (variance design)
- **No actor has `aptitude_profile`** — gated on Phase 3; bootstrap will assign at actor creation
- **`LaborContract.wage_per_slot` locked-at-creation** — current behavior, decision documented in Stage 0; gated on `wage_policy` extension if "recomputed" variant is wanted
- **`LaborMarket.supply_for_scarcity()` returns hardcoded 2** — gated on Phase 5 (multi-region) or earlier if regional registry lands
- **`MercantileInterest.wholesale_cost_per_unit` single-batch** — overwritten each wholesale buy; gated on Phase 5 (multi-good with non-unit prices)
- **`Activity.display_name` field never set** — gated on Elicitation E + Phase 7
- **`accounts.books[&"reputation"]` not seeded** — gated on Elicitation F + Phase 9
- **`VitalsBook.morale` never written** — gated on Elicitation F + Phase 9
- **`GrainInterest.outstanding_demand` exists but no consumer reads it as hunger pressure** — gated on Phase 4

---

## 8. Operating Procedure for Elicitation Sessions

A clean session running an elicitation should follow this protocol.

### 8.1 Session opening

```
1. Read this file (`_bmad-output/prototype-completion-roadmap.md`).
2. Identify the elicitation by letter (A–F).
3. Read the section's pre-read files.
4. Confirm with the user which elicitation is running and check for any local context shifts.
```

### 8.2 Spawning agents

Agents are NOT real BMAD subagent_types in this Claude Code build — they are spawned via `general-purpose` subagent_type with persona injection. Use this spawn pattern:

```
Agent({
  subagent_type: "general-purpose",
  description: "<Agent name> on <topic>",
  prompt: `
You are roleplaying as <Agent name>, the <Title>. You will respond ONLY in <Agent name>'s voice — do NOT break character. Do not use any tools.

## Your Persona
<icon> **<Agent name> — <Title>**
<full description from agent manifest>

## Discussion Context
<150–250 word capsule from the elicitation section's "Project context capsule">

## The User's Message
<the elicitation's questions, both system and experience halves, with the placeholders section appended>

## Guidelines
- Respond authentically as <Agent name>. Embody the persona fully.
- Start your response with: <icon> **<Agent name>:**
- Speak in English.
- Scale your response to the substance.
- Disagree with other agents when your perspective tells you to.
- Do NOT use tools. Just respond with your perspective in plain text.
- Stay in character throughout.
`
})
```

Spawn all agents named in the elicitation's "Owner agents" line **in parallel** (single message, multiple Agent tool calls). Agent identity references:

| Agent | Title | Icon | Description source |
|---|---|---|---|
| Cloud Dragonborn | Game Architect | 🏛️ | gds-agent-game-architect |
| Samus Shepard | Game Designer | 🎲 | gds-agent-game-designer |
| Indie | Game Solo Dev | 🎮 | gds-agent-game-solo-dev |
| Link Freeman | Game Developer | 🕹️ | gds-agent-game-dev |
| Paige (gds) | Technical Writer | 📚 | gds-agent-tech-writer |
| Mary | Business Analyst | 📊 | bmad-agent-analyst |
| John | Product Manager | 📋 | bmad-agent-pm |
| Sally | UX Designer | 🎨 | bmad-agent-ux-designer |
| Winston | System Architect | 🏗️ | bmad-agent-architect |
| Amelia | Senior Software Engineer | 💻 | bmad-agent-dev |

To get an agent's full description, run:
```
PYTHONIOENCODING=utf-8 .venv/Scripts/python _bmad/scripts/resolve_config.py --project-root . --key agents
```

### 8.3 Presenting responses

Each agent's response gets its own unabridged section in the chat output. Never blend, paraphrase, or condense. After all responses are presented, optionally add a brief **Orchestrator Note** flagging disagreements worth exploring next.

### 8.4 Capturing the output

The session output goes into `_bmad-output/elicitation-<letter>-output.md`. The output file should contain:
- Each agent's full response (verbatim)
- Zach's answers (interactive — possibly multi-round)
- A **Design directives** section: load-bearing decisions reached, explicitly numbered
- An **Open questions** section: anything unresolved, with which elicitation/phase will pick it up
- A **Placeholders affected** section: which entries in `placeholders.md` this elicitation resolves or rewrites

### 8.5 Ending the session

When the user signals the elicitation is done, write the output artifact and update:
- `placeholders.md` if any placeholders are now scheduled for resolution
- `phase-3-backlog.md` if any items move
- This document's §1 table (mark the elicitation as complete)

---

## 9. Decision Rules / Open Questions

These are the cross-cutting questions left explicitly open by this plan. They get resolved during the relevant elicitations or in Stage 2 (phase plan write-up).

1. **Hunger placement (Phase 4 vs. 5).** Resolved by Elicitation B + cross-reference with C (does multi-good economy benefit from hunger-pressure as a demand-side input, or is hunger cleaner standalone?).
2. **Lord-as-actor vs. lord-as-force.** Resolved by Elicitation D. Has implications for whether lord behavior is part of the prototype or pure parameter tuning.
3. **Population API on diagram or only in code.** Resolved by Elicitation E. Cloud/Samus position: yes, name on diagram even if stub. Indie/Mary position: no, until consumer exists. Author adjudicates after Elicitation E.
4. **Counterparty mystery scope.** Resolved by Elicitation E. Decision: full knowledge graph, partial graph (bound to display-name resolution only), or pure architectural seam with no implementation in prototype.
5. **Reputation Book or Reputation Account.** Resolved by Elicitation F. Decision: separate `ReputationBook` per directive §10, or just morale-extended on `VitalsBook`.
6. **Diagram trigger condition.** When is the architecture stable enough to draw? Tentative: after Phase 5 (multi-good has stress-tested the abstractions). Confirm in Stage 2.

---

## 10. What This Plan Is Not

- **Not a directive.** Directives are committed architectural decisions (like phase-2.5-books-activity-architecture-directive.md). This plan SHAPES future directives but doesn't replace them.
- **Not a specification.** Phase-level specs come out of Stage 2 after elicitations.
- **Not a wish list.** Items rejected from backlog go to `design-parking-lot.md`, not here.
- **Not finalized scope.** Phases 8+ are deliberately fuzzy. The first 3-4 phases need clarity; the last 3 need direction.

---

## 11. Author Adjudication Locks

Things this plan locks without further debate (until evidence emerges to revise):

1. **Cleanup pass runs first.** No elicitation begins before Stage 0 lands. Clean code → clean conversation.
2. **Six elicitations is the right granularity.** Not five (would conflate). Not ten (would fragment).
3. **Macro-legibility is a LENS, not a feature.** Every coding pass is checked against "does this make the population/time-aggregated story more readable or less?" — Samus's call from this round.
4. **Backlog hygiene > backlog completeness.** Per Indie + Mary. A backlog with 30 items Zach trusts beats one with 50 he skims.
5. **The architecture diagram is projected, not retrospective.** Per Cloud + Samus. It depicts the architecture's identity (current + projected seams), not just current code state. The seam map is its source of truth.

---

— Author adjudication (Zach), with Cloud Dragonborn, Samus Shepard, Mary, and Indie in the room.
