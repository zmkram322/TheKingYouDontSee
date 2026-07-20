# The Demand-Resolver — System Spirit & Foundations (POC v2)

*Status: living manifesto. Written to be **pressure-tested**, not admired. Every
tenet below is a falsifiable claim; the open tensions at the end are where we
expect it to strain. This is the "why/what." The generalized-node refactor is
the "how" — planned separately.*

*Grounding: this is not armchair design. Every claim here was observed in a
working headless sim across slices 1 → 3b (see `poc-v2` commit history). Where a
claim is only a belief, it's marked as such.*

---

## 1. What this is

A world where **behaviour is not scripted — it resolves.** Actors have needs and
wants; those become demands; demands find whatever satisfies them, or spawn the
sub-demands they require and wait. Economies assemble themselves, sustain
themselves, and can collapse, out of nothing but pressure and one repeated rule.
No world-state triggers, no market windows, no orchestration. The kingdom is a
dependency graph resolving under pressure.

**Food is the proof, not the point.** What we've built so far runs on a single
driver — hunger — because you validate a machine on the simplest load first. But
hunger is *one physical driver*. The real system is a **needs-and-wants resolution
engine** meant to host many drivers at once — **physical, social, emotional (the
health-triangle axes)** — each generating its own demands and **bootstrapping its
own economy**:

- **physical** → hunger spawns a *food* economy; fear of harm spawns a *safety*
  economy (guards, walls, protection rackets).
- **social** → the want for standing spawns a *status* economy (patronage,
  favours, reputation).
- **emotional** → **loneliness spawns a *companionship* economy** — the ache for
  company drives demand for friends, a tavern's warmth, courtship, belonging; and
  someone, somewhere, provisions it.

Same atom, same primitives, many economies. Anyone reading this as "an economy
that wants to eat" has the scope wrong — eating is the *first instance* of a
general pattern.

With many drivers comes a question the food-only POC never had to face: when an
actor is hungry *and* unsafe *and* lonely at once, **what does it choose to
pursue?** That arbitration — likely a policy-driven **behavioural state machine** —
is core to the real system, not an add-on (see T9 and §7).

The goal of the refactor this doc feeds is to **extract the one rule into a
general node** that can carry all of this — without over-abstracting (see §6, the
scar).

---

## 2. The Atom

> **A demand hits a resolver each tick. The resolver either satisfies the demand,
> or emits the child demand it needs and waits on that child. When the child is
> satisfied, the parent resumes.**

That is the entire engine. Depth comes from *composition* of this one move, not
from adding systems. If a new behaviour can't be expressed as demands resolving,
it doesn't belong in this model.

---

## 3. The Primitives

Every resolver we've written is secretly built from the same small vocabulary.
These are the moves the generalized node must support — and, we believe, *only*
these:

| Primitive | Meaning | Seen in |
|---|---|---|
| **Match a provider** | find/assign the actor who can satisfy this (merchant, producer, idle body, willing employer) | all four demand kinds |
| **Emit child & wait** | spawn the sub-demand I depend on; resume when it's satisfied | food→restock→produce |
| **Priced transfer** | move a good one way and coin the other | retail, wholesale |
| **Transform** | convert inputs into an output over time (produce a batch) | production |
| **Two-sided match** | a demand meets a *counter*-demand and both are satisfied (person wants wage ↔ producer wants hands) | employment |

If a primitive isn't used by one of the four proven demand kinds, we don't build
it. Generality is earned by example, never anticipated.

---

## 4. The Tenets (falsifiable — attack these)

**T1 — A missing role is just another demand.** No merchant, no producer, no
worker? That's a demand for one, tracked in the same queue as a demand for food.
This symmetry is the source of emergence. *Evidence: the sim bootstraps its
entire supply chain from an all-idle start.*

**T2 — Emergence comes from composition, not special-case systems.** We refuse
world-state triggers and market windows. Pressure enters through needs; structure
falls out of demands resolving. *Evidence: a sustaining food/labour/money economy
with zero trigger code.*

**T3 — One hop per tick. Causality must be visible.** Demands crawl down one
layer per tick and satisfaction crawls back up. Legibility is a design
constraint, not a nicety: if you can't read *why* something happened on screen,
it isn't done.

**T4 — Every resolution step carries a policy: `auto` or `player-seam`.** *(North
star; belief, not yet built.)* Each point where the sim decides — assign a role,
feed the hungriest, pay a wage, hire a hand — is a point the *player* could decide
instead. This single property is meant to deliver extensibility, composition, and
the invisible-kingmaker fantasy at once. "Feed a worker" and "donate money" are
not features; they're steps with the policy dial flipped to `player`.

**T5 — Everyone has a price. Motivation is a composite scalar, and there are no
hard fails.** A worker's will to labour is one value fed by competing drives
(today: hunger down, pay up). Enough pay keeps them working at any hunger. We
reject hard-fail states because a dead-locked world is un-recoverable and
un-fun. *Evidence: a paid worker labours through 100/100 starvation; the economy
that hard-failed on hunger (slice 2b) never recovered.*

**T6 — Money is a conserved flow, not a spawned resource.** Coin circulates
(consumer → merchant → producer → worker → …). New money enters only through
*deliberate* injection (a producer's starting equity), never as a silent per-tick
trickle. Leaks and pools are findings, not to be papered over. *Evidence:
removing the stipend placeholder ended coin inflation.*

**T7 — Behaviour is driven by needs *and wants*, not scripts — and drivers are
plural and pluggable.** Hunger is only the first, and only a *physical* one.
Social and emotional drivers (safety, status, belonging, ...) generate demands
the same way and bootstrap their own economies through the same node. The engine
is driver-agnostic; a driver is *content*, not a special case. *(Belief — only
hunger is built so far.)*

**T8 — Standing needs re-fire.** Hunger returns; demands are not one-and-done.
The model must treat recurring demand as first-class, not a special case.

**T9 — When drives compete, the choice is a policy.** An actor with several live
needs must decide which demand to pursue *now*; that arbitration is a first-class,
policy-driven decision — probably a behavioural state machine — not a buried
if-ladder. It's `auto` today and a player-seam tomorrow, exactly like T4. *(Belief
— untested; the POC has one need, so nothing competes yet.)*

**T10 — The system is legible at the aggregate, and change is *attributable*.**
Factorio's real pleasure isn't the belt — it's watching a number move and knowing
*why*. You should be able to read the world at the pattern scale (food throughput,
who's usually fed, which enterprise is bleeding) **and trace a shift to its
cause**: "grain output up 15% because a lord cut wages," or "…because *you* fed
his workers." Observability is the design medium and the player-facing payoff, not
a debug afterthought. *(Extends T3 from per-tick causality to aggregate-flow
attribution. Belief — not built.)*

---

## 5. What we deliberately reject

- **World-state triggers & market windows** — the machinery of the archived
  build. Replaced by needs + resolution.
- **Hard-fail / permadeath states** — see T5. The world stays recoverable.
- **Per-moment micro-legibility** — we read the world at the *pattern* scale
  (who's usually fed, which enterprise is bleeding), not every atomic transfer.
- **Premature abstraction** — see §6.

---

## 6. The North Star & the Scar

**North star:** the invisible kingmaker. The player rarely acts directly; they
act at **seams** — the auto-decisions they choose to reach into. A system where
every resolution step is policy-tagged is a system *made of* latent player
moments. The architecture and the fantasy are the same shape.

**The scar (read before generalizing):** the previous build died because its
`Goal / Recipe / Decider` abstraction machinery was built *before* the loop was
proven — it became substrate that slept, then got thrown out. The loop is proven
now, so extraction is finally earned. But the discipline stands: **extract from
the four concrete working resolvers; never design the abstraction in the
abstract.** If we can't point at the working code a primitive generalizes, we
don't add it.

---

## 7. Open tensions — where to push (this is the pressure-test agenda)

These are the honest weak points. Cloud and the party should attack here.

1. **Does "a recipe of steps, each policy-tagged" actually generalize —** or will
   some demand shapes resist it? The two-sided match already stretched the
   one-sided mould once; what's the *next* shape that breaks it (auctions?
   many-to-many? conditional/branching recipes)?
2. **Is allocation-under-scarcity a first-class concern the node must model, or a
   policy on top?** Creation-order serving already causes a fairness skew (one
   mouth eats least). When food/labour is scarce, *who* gets it is the whole
   game. Where does that decision live?
3. **How do player-seams interleave with an auto-running tick** without stalling
   the world? Does the sim pause for player input (turn-like) or keep flowing
   (real-time with deferred choices)? This is load-bearing for feel.
4. **Does one-hop-per-tick survive scale?** It's beautiful at 6 actors. At 600,
   does legibility demand aggregation (near / regional / distant fidelity), and
   does that break the single-node model?
5. **Where does space & travel time live?** As extra phases in a demand's recipe,
   or as a separate spatial concern the node consumes? On-screen visibility of
   "walking to market" is wanted eventually.
6. **Standing vs. one-shot demands** (T8): how are recurring/renewing demands
   modelled without the queue thrashing or duplicating?
7. **Conservation vs. injection** (T6): what's the principled rule for when new
   money/goods may enter the system, so the economy neither starves of liquidity
   nor inflates?
8. **Overstaffing / right-sizing:** the producer currently hires everyone who
   asks and bleeds equity. The "production-manager policy" is hand-waved — is it
   just another policy-tagged step, or does it need its own structure?
9. **Multi-driver arbitration (the big one):** when an actor has competing live
   needs — hungry *and* unsafe *and* lonely — how is "what do I pursue now?"
   decided? Does it need a dedicated behavioural state machine (T9), or does it
   fall out of demands competing for the actor's attention and resources? This is
   the single largest unknown the moment we go past one driver.
10. **Do non-material economies fit the same node?** Hunger→food is a *material*
    economy (goods and coin that physically move). A social or emotional economy
    (status, favours, trust, companionship) may have no good to transfer. Does the
    priced-transfer / transform vocabulary still hold, or do social/emotional
    drivers need primitives of their own — and if so, is the atom still one atom?
11. **Causal attribution in an emergent web (T10):** "food output +15% because of
    decision X" is easy to *say* and hard to *compute* — in a mesh of resolving
    demands, how do we honestly trace an aggregate shift to a single decision
    (a lord's or the player's) without lying about correlation? It's both a UI
    promise and a genuine systems problem.

---

*If a tenet survives Cloud, it becomes a constraint on the refactor. If it
breaks, better to learn it here than in the code.*
