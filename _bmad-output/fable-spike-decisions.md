# Fable Spike — Decisions Document

*Companion to `fable-spike-brief.md`. Written 2026-07-27, on branch `fable-spike` (worktree off `poc-v2`). The proving scene runs headless in all three branches (`tests/headless_scene.gd`: invest-in-Tam → visible intervention → aggressor backs off; invest-in-Corwin and no-invest → the player yields). This document records every place the code forced the model concrete, and where the PRD is wrong or silent.*

**The scene, as the sim actually played it:**

```
Tick 6   Aldric heads to the pub.            Kestrel's eyes keep finding Aldric.
Tick 7   You watch. Tam: keeps to the edge of the group, glancing in; ...
         You watch. Corwin: (no social tell — wants for nothing you can see)
         Tam answers your greeting: cold     Corwin answers your greeting: cold
Tick 8   Aldric buys Tam a round. It lands — Tam needed the company.
         Kestrel pushes back his chair and squares up to Aldric.
         Kestrel presses Aldric — poise down to 41.
Tick 9   Aldric is buckling — the need for someone to step in hangs in the air.
         Kestrel presses Aldric — poise down to 32.
         Tam shifts in his seat — watching, not yet moved.
         Tam answers your greeting: neutral  (was cold)
Tick 10  Kestrel presses Aldric — poise down to 23.
         Tam stands and puts himself between Kestrel and Aldric —
         spending his own standing to do it. ✓ answered
Tick 11  Kestrel reads the room again — this is no longer a lone stranger —
         and backs off. ✓ over
```

No goal exists anywhere in that log. Kestrel escalates because his standing drive is unmet, his regard for the stranger is negative, and the stranger reads as the cheapest body in the room. Tam's hesitation is the same evaluation run twice with different inputs: the first pass genuinely fails.

---

## 1. The architecture question — resolver vs. utility loop

**Verdict: both survive, with distinct jobs. The resolver was not in the way; the *unscored matching inside it* was. FR1 as written describes neither the shipped code nor what I built, and should be rewritten.**

- **A demand is the right representation of unmet need.** It carries identity, lifecycle, and composition (child demands). A pure utility loop has no object that *waits*, and the waiting is where self-assembly comes from: an unsatisfiable demand persists and keeps pulling until the world grows the capacity to satisfy it. A utility score is an instantaneous ranking; it forgets. **The demand queue is the sim's memory of what is still wrong.** That is why the economy bootstraps from all-idle and why a naive utility loop would not have given it for free.
- **Utility scoring is the right mechanism at exactly two points:**
  1. **Emission / sustain** — whether an actor's state starts or continues a pursuit. Kestrel's press is a scored choice re-evaluated every tick; the same evaluation that starts the confrontation ends it when a backer changes the sums. Nothing was authored to make him aggressive and nothing was authored to make him stop.
  2. **Pick-up** — who resolves a demand. The shipped `_find_actor_with_role` (first body with the role) becomes, for the aid demand, a scored and *refusable* candidate evaluation. "Delegation is provider-matching where the provider chose you" holds up in code exactly as the PRD hoped: the aid demand is ordinary provider-matching where every candidate runs a genuine evaluation whose honest output can be "no."
- **The phase machines stay.** Once a demand is being resolved, hand-written phase steps are honest sequencing, not scripting. Re-scoring mid-resolution every tick would add nothing and cost legibility.

**Recomposition: demands = persistent memory of unmet need · phases = sequencing of resolution · utility = the two decision points (emit, pick up).** The economy resolvers still use unscored matching (first-merchant-wins) — fine at depth 1; the seam to upgrade them is the same pick-up point the aid demand already uses.

Confidence: high on the division of jobs (the scene exercises all three parts); untested past depth 1 and past ~12 actors.

## 2. Tick and time model

Discrete, manually-stepped ticks retained; one hop per tick. **The scene's dramatic beats fall out of tick granularity** — sizing-up (3 ticks), drawdown (1 rung of poise per tick), hesitation (an evaluation that fails, then passes) — with zero animation or timer code. Real-time is a presentation deferral: an auto-step timer over the same sim, later. Nothing in the sim knows wall-clock time.

The design notes flagged tick-vs-scene-time as "load-bearing for feel" — verdict from the build: at debug-skin fidelity the stepped tick *is* the feel, and it is good. The real question (deferred honestly) is what happens when a 3D body has to fill a tick.

## 3. The action set

Minimum set the scene forced (all generic; the player-specific part is only the input seam):

| Action | Who | Mechanically |
|---|---|---|
| `go_to(place)` | player (seam) | place write |
| `share_drink(target)` | player (seam) | priced transfer (coin → keeper, conserved) + relieve-need (belonging) |
| `look(target)` | player (seam) | read tells; no world write |
| `greet(target)` | player (seam) | read rung; log previous rung (the delta) |
| `press(target)` | any actor (scored) | contest of state; drains poise; standing to the winner |
| `intervene` | any actor (scored) | commit standing behind a pressed party; changes the aggressor's evaluation |

Player verbs bypass the demand queue (intents applied at tick start). A fuller build should route them as demands with the policy dial at `player` — the T4 shape — but the seam cost nothing now and the cheap version proves the loop.

## 4. Conflict resolution

Contest of state, no execution. Poise drains at a flat rate under press; yield at a floor transfers standing and leaves resentment (regard) on the edge; poise regenerates when unpressed — **no unrecoverable state, no categorical override anywhere** (survival never had to be special-cased; at depth 1 nothing competed hard enough to need weighting — see §9.7).

**Load-bearing finding — visible vs. latent social state.** The aggressor's sustain evaluation may read only *visible* state: standing, poise, and **committed backers**. Held channels (favor) are **latent** — invisible until spent. This is not a nicety; if evaluation could read latent favor, no one would ever attack an invested player, and the held actor would never get to visibly act — the proving scene becomes structurally impossible. **Illegible authorship is a constraint on which stats may enter whose evaluations**, not a presentation choice. The PRD nowhere says this.

A committed backer is weighted heavier than bystander standing (`W_BACKER`) — a declared cost reads bigger than latent weight, which is exactly "the sums have changed."

## 5. Demand emission for aid

Emitted by the sim when any pressed actor's poise crosses a calling threshold — generic, not player-special. Candidates: co-located bystanders (participants and committed backers excluded). Each scores: **favor toward the pressed party** (dominant by design) **+ peril** (grows as drawdown deepens) **− aggressor's visible threat − base reluctance**, against a threshold. The hesitation beat is *the same evaluation failing before it passes* — peril accumulates until the channel-holder crosses; a stranger never does, at any peril in this tuning. Refusal is the evaluation's honest output, not a branch.

The calling threshold had to be tuned (40 → 45) so at least one tick of visible not-yet-moved exists between emission and commitment. That one number is the difference between "a decision" and "a trigger" — exactly the kind of feel constant the one-block rule exists for.

## 6. Channel maths

- **The one rule that carries the reading game:** the investment act relieves a target stat; **favor accrues only if that stat was below its need threshold at the time.** Relieving a met need is money in a hole. The entire wrong-target branch is this single rule — no Corwin-specific code exists.
- Favor is an **accrual** edge primary: +18 per relieved need (≈ one greeting rung), decays slowly (0.1/tick), and is **partially spent by acting on it** (−10 on intervention). Gratitude accrues back on the reverse edge (+15) — the rescued now owe the rescuer.
- Regard (like/dislike) is a separate edge primary; both feed the rung.
- **Greeting rungs: five discrete bands over favor+regard, derived on read, never stored.** The observation log stores the previously *seen* rung per (observer, target) — the delta ("neutral — was cold") is the prosthesis's job, and the sim never holds a rung as state that could go stale.

**Observed emergent consequence worth keeping:** because intervention spends favor and standing, protection is *consumable*. In the success branch, Kestrel's cooldown lapses at tick 23 and he begins sizing Aldric up again — and Tam, favor partly spent, would **not** cross the threshold a second time. One drink buys one rescue. That is the transactional/accrual texture the PRD describes (FR32–33), arrived at from the maths rather than authored — and it is also a tuning warning: the MVP scene must end before the second press, or teach it deliberately.

## 7. Driver inference surface

LOOK returns tells; a tell is the expression of an **unmet driver**; a met driver shows *nothing* — Corwin's absence-of-tell is the read. Tam and Corwin answer the same GREET rung (cold) on first contact; only LOOK distinguishes them. That is the reading game at minimum size: **rungs tell you where you stand; tells tell you what they need; the skill is the second one.**

Caveat found in the build: with everyone hungry mid-scene, the hunger tell appears on all three and adds noise; Tam's standing also had to be seeded *met* so his belonging tell stands alone. **Tell hygiene — how many simultaneous tells a body can carry before reads blur — is a real design surface the PRD doesn't touch** (FR19's "orthogonal channels" covers rendering distinctness, not simultaneity).

Per-actor driver *weights* (FR21's fuller claim) were **not needed** at depth 1 — per-actor *state* differences (met vs unmet) were enough to make the wrong target wrong. Weights stay unbuilt and unproven.

## 8. Where the player sits

The player is an `Actor` in the same array, running the same loop — he gets hungry, goes broke, is hired, earns wages, and buys food **through the shipped resolvers with zero new code** (the scene log shows Idle-2 paying Aldric wages mid-confrontation). Cost of "same loop" so far: nil. Two asymmetries only: the input seam (intents applied at tick start), and two `skip if player` guards — auto-aggression and auto-intervention are policies the player owns. Those two guards are the T4 policy dial in embryonic form.

## 9. Where the PRD is wrong, incoherent, or silent

1. **FR1 is wrong as written.** "One shared utility-AI loop over primary and derived stats" describes neither the shipped substrate nor a desirable target. Rewrite to the composition in §1: demands as persistent unmet need; utility at emission and pick-up; phases for sequencing.
2. **Silent on visible vs. latent social state** (§4). Without the split the MVP scene is structurally impossible. Should be a requirement with FR-level force: *an actor's evaluations may read only state that is visible to that actor; held channels are invisible until spent.* This is also the mechanical root of illegible authorship, currently asserted only as fantasy.
3. **FR4 solves the cheap half of derived-stat correctness.** Staleness is easy (the store's version stamps did it in ~30 lines). The load-bearing rule is *whose evaluations may read which stats* — a visibility model, which no FR covers.
4. **Demands need an expiry/abandon path — the model is silent.** An aid demand whose confrontation ends must die without being "satisfied." The spike hand-closed it. T8's "standing needs re-fire" implies open-ended demand lifetimes; nothing specifies un-becoming.
5. **Silent on upkeep over sparse edges.** Favor decays per tick, which requires *enumerating* favor edges — but the sparse store is built for point reads. The spike keeps a side registry of touched pairs; the real store needs edge enumeration as first-class API. This is an architecture-document item, found only because decay met sparseness in code.
6. **The proximity rule is a stub and the PRD knows nothing about space.** "Same place" worked for one room. Meanwhile the player was farm-working in a field *while standing in the pub* — labour is place-blind. Harmless at depth 1, incoherent at depth 2. (Confirms system-spirit open tension #5; the PRD dropped it.)
7. **Multi-driver arbitration (T9, "the single largest unknown") never got forced — and the reason is a finding.** Kestrel queued for food *while* pressing Aldric; demands don't compete because **no action economy exists** — actors have no scarce attention to allocate. Arbitration becomes real only when actions become exclusive. The PRD's "composite motivation / survival outbids" (FR6–7) is accordingly **still unexercised**: nothing yet competes. Honest status: designed, not proven.
8. **FR23 ("every read is comparative") is not what the build produced.** First GREETs return an absolute rung ("cold") — anchored by the *other* readable body in the room, not by a prior observation. The comparative texture came from staging (two contrasting men), not from the read mechanism. Either FR23 relaxes to "every read is anchorable," or reads need to change shape.
9. **Journey 1's "spending his own standing" survived contact** — intervention costs are what make refusal genuine and protection consumable (§6). But the journey's implication that the round buys *durable* safety does not: see the second-press dynamic. The yield-tuning open question in the PRD ("if yielding is toothless…") is real and now measurable: yield costs 3 standing of 5 and ~10 ticks of poise — currently closer to "toothless" than "gotcha," deliberately, until the scene is played by hand.

## 10. Constraint compliance

- **Accessor:** every stat read/write in sim and UI goes through `get_primary/get_derived/write_primary` (retrofit verified byte-identical over 60 ticks before the social layer landed). Storage: sparse Dictionaries + per-stat defaults; derived cache with auto-captured dependency versions.
- **No hard-fails:** yield recovers; no override rules anywhere.
- **No playstyle names:** grep-clean; press/intervene/favor/standing are path-agnostic primitives (a coercive path and a patronage path would both use all four).
- **One constants block:** `sim/tuning.gd`, 40-odd named values, every invented number in it.
- **Discrete rungs:** five bands, derived, never subdivided; deltas via the seen-rung prosthesis.

## 11. What I would do next (not done, deliberately)

- Play the scene by hand in the debug UI and tune yield teeth + second-press timing.
- Route player verbs through the demand queue with a `policy` tag — the smallest honest T4.
- Give the economy resolvers the scored pick-up (one candidate loop, same shape as aid) and watch whether allocation-under-scarcity (spirit tension #2) starts answering itself.
- A second driver pair (safety?) to force arbitration for real — that's the point where FR6–7 stop being beliefs.
