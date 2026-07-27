# Multi-Path Routes — Distinctness Framework

*Reference doc distilled from the 2026-07-24 PRD-vision party session (Samus + Cloud, with Zach). Answers one question: **how do multiple routes to power stay genuinely distinct on ONE shared simulation substrate, without becoming a reskinned spreadsheet or three separate games?** This is the "how" behind the PRD's multi-path claims. See also `design-positioning-and-comparables.md` (the "why/pitch") and `design-session-2026-07-24-social-political-layer.md` (the underlying architecture).*

---

## 0. The frame

The player commands through **one interface**. Routes to power are **composable economic/social value-chains** — war, commerce, crime, secrets, public service, and more as systems layer in. The danger of "many playstyles" is that they differ in fiction but feel identical in the hand. This doc is the discipline that prevents that.

Core fantasy is **path-agnostic**: the spine is *illegible authorship* (the world can't read your reach/method), reachable whether your hand is hidden or your sword is drawn. **Direct/overt play is first-class, not a lesser path.** (Full fantasy framing in the positioning doc.)

---

## 1. The distinctness principle (the load-bearing idea)

> **Paths are made distinct by WHAT BREAKS and WHO FIGHTS YOU — not by what you watch.**

Different *metrics on a dashboard* is a reskinned spreadsheet. Watching different numbers is not different *play*. A cockpit with different gauges is still the same seat doing the same thing.

A path feels genuinely different in the hand when its value-chain imposes a **different dominant constraint** and therefore a **different characteristic failure mode** — one that requires a different skill to prevent and a different action to recover from.

### The failure-mode table

| Route | Dominant constraint | Characteristic failure | You watch for the… | Recovery |
|---|---|---|---|---|
| **War** | supply continuity | **rupture** (a starving smith halts iron→arms) | *snap* | re-secure the link, feed the smith |
| **Commerce** | margin / spread | **compression** (competitors undercut; willingness-to-pay shifts) | *squeeze* | re-open a spread (not add a resource) |
| **Crime** | concealment / heat | **exposure** (law + informants close in) | *leak* | suppress, relocate, eliminate the witness |
| **Secrets** | timing | **staleness & double-cross** (a secret decays; the held party works to defuse it) | *clock + counterparty* | spend it before it rots |

If all routes fail the same way ("a number drops → inject resource → it recovers"), it's a reskin. If they fail by rupture / squeeze / leak / decay, they are genuinely different games in the hand — because the counterplay is **a different verb underneath the same command gesture.**

---

## 2. The route-specific antagonist (the sim's unfair advantage)

Because this is an NPC sim, the world pushes back with a **different antagonist per route**:

- **War** → rival warlords + your own hungry workers
- **Commerce** → undercutting competitors + guild resistance
- **Crime** → informants, the law, betrayal from inside
- **Secrets** → *the very people whose secrets you hold, acting to protect themselves*

Same verb (direct an actor); completely different thing fighting you. **The opposition is the distinctness engine — not the dashboard.** Route-specific opposition means route-specific interesting decisions, which means route-specific *feel*, for free from the sim.

---

## 3. Routes bleed — "primary constraint + borrowed tools at a premium"

Routes are **not** siloed. A merchant prince hires goons to protect trade routes and greases bandit lords to keep the peace; war is not only met with war. The identity lives one level up:

> **Your route is the constraint you perpetually defend and the goal you optimize toward. Everyone else's tools are available to you — but they are your CHEAP verb only on your own route, and an EXPENSIVE borrowed verb everywhere else.**

The merchant's hired goons are worse and pricier than a warlord's soldiers (he lacks the martial standing/loyalty that makes men die cheap); the warlord pays retail for iron (he never built the commercial relationships). **Everybody borrows tools; nobody borrows goals, and nobody borrows the other route's efficiency.**

This is the **anti-collapse mechanism**: "do everything" loses not because it is forbidden but because it is *inefficient at everything* (pure Sid-Meier opportunity cost). Bleed is a feature; siloing was never the claim.

**Cross-interference:** routes feed and starve each other (war needs commerce's iron; a crime route can choke a war route's supply). That intersection turns each session into a live "which enterprise is right for *this* board *right now*" decision instead of parallel solitaire games.

---

## 4. Distinct MOMENT vs. distinct SESSION (the honest split)

Zach's framing — *distinctness lives in who you interact with, how, and which stats you need; the backend is invisible middleware* — was tested and **partially** holds. The precise split:

- **Different people / mechanism / stats = distinct MOMENT.** The surface of the moment differs. This **fully dissolves the "backend is a spreadsheet" fear** — because every economic verb terminates in a *person's decision*, and a person deliberates, resists, runs their own utility, and can say no (a spreadsheet cell always complies). Bribing a bandit lord (coin + intimidation + reputation) genuinely feels different from conscripting a smith (authority + provisioning + loyalty). **Shippable now; genuinely not a spreadsheet.**
- **Different characteristic failure = distinct SESSION.** What happens across the session when it goes wrong. Four different-feeling *conversations* can still resolve to the same consequence structure ("did the number move, y/n") — a warmer spreadsheet, a themed minigame, not a different game. This is the **teeth**.

You need both. Distinct moment gives *texture*; distinct failure gives *stakes*.

---

## 5. The 3-part minimum bar (what a route must clear to count as a "path")

1. **Distinct people + social mechanism + stats to operate it.** (The floor. Non-negotiable, shippable now — makes the moment real.)
2. **Every interaction terminates in a person's genuine decision that can go against you.** (Why the spreadsheet backend doesn't matter.)
3. **A characteristic way the route breaks, inflicted by its own people, recoverable by a route-appropriate action.** (The teeth — makes it a distinct *game*, not just a distinct *conversation*.)

Ship #1 + #2 → a defensible, honestly-distinct MVP with distinct *texture*. Add #3 → distinct *games*.

**Design red line:** *any route that is purely a goal-weight over shared primitives, with no bespoke pressure of its own, will feel identical in the hand and must not ship as a "path."*

**Important nuance — teeth ≠ exclusive primitives.** The characteristic failure can be **assembled from shared primitives**: war's rupture runs on the **already-shipped hunger primitive** (a starving smith halts production). So you can *defer* exclusive/bespoke mechanics (the parity-safe call) and *still* get failure-mode teeth cheaply, today, from the common substrate. Do NOT conflate "needs a characteristic failure" (required, cheap) with "needs an exclusive mechanic" (deferrable). Don't defer #3 to zero — a lightweight characteristic failure is the price of the multi-path promise being *true* rather than *narrated*.

---

## 6. Playstyle = DATA, not code (Cloud's architecture)

The whole multi-path bet only survives for a solo dev if a playstyle lives in **data**, not code. Otherwise "multiple paths" = multiple codebases wearing one name.

- **A playstyle is a data bundle**, ranked by how much it leans on each mechanism:
  - **(foundation) the derived stat it leans on** — a coercer's world is scored through `fear(→me)`; a patron's through `loyalty(→me)`; a spymaster's through `informational_exposure(→me)`. These already exist; every NPC already runs its loop over them. *Zero new code.*
  - **(framing) the curve set** — different curves reweight the *same* actions (same `pressure_target`; coercer reads a steep `fear` curve, patron weights `loyalty` gains). Pure data.
  - **(trim, last & sparingly) gated new actions** — genuinely new verbs a route unlocks (`make_example_of`, `grant_sinecure`). If you reach for new actions to express a playstyle, that's the smell of bespoke code.
  - Model: `{ primary_derived_lever, curve_set, unlocked_action_ids }` over **one universal action set**. Not three action sets — one set, three lenses. Lever + curves do ~80%; gated actions the last ~20%.
- **Progression = a per-channel REACH vector**, not one scalar (a single meter collapses the divergence): `{coercive, economic, authority, loyalty, informational}` — each a **slow-tick rollup** over the existing social graph (sibling to the PageRank power tick), *derived from the substrate, not bolted beside it.* Hybrid gates (`coercive AND authority`) yield "vicious-but-savvy" emergently.
- **Gates are data, evaluated by ONE mechanism.** Every gated action/actor/strategy carries a `requires:` expression against the reach vector; a single gate-evaluator filters the master unlock table. New unlock = new data row, no code.
- **The one inviolable discipline (enforceable in review):** **NO new code may name a playstyle.** If a class/function/branch/file has `coercer`/`patron`/`spymaster` in its identifier or conditionals, reject on sight. Path-specific needs are converted into *generic* substrate primitives (that ≥2 hypothetical paths could use) or they don't ship. It's a grep and a habit — the one thing keeping three data configs from becoming three codebases.
- **Honest trade-off:** this front-loads cost into authoring the primitives well (reach-rollup, curve library, requirement-evaluator, gate reader). Hardcoding path one is an afternoon; but then paths two and three have no door to walk through. *Build the door once; the paths are then just keys, and keys are cheap to cut.*

Note the rhyme with goal→action linking: goals bias a **hand-authored** set of action tags (the effect-signature graph is a *suggestion tool*, not an oracle) — "inherited biases up, hand-placed overrides down," same shape as the relationship graph.

---

## 7. Parity (the make-or-break)

Multi-path promises collapse when one path is secretly "the real game" (see the positioning doc's Dishonored "penalty box" warning). Commit to a testable **parity claim**:

> Each route must reach a **top-tier outcome the others structurally cannot**, and must be able to **compete across** routes — a merchant prince must be able to out-maneuver a warlord.

If you cannot name a distinct win-condition for the vicious-commander that the puppeteer can't reach, the multi-path positioning is mush no sentence can save. (Bespoke/exclusive primitives, when eventually added, must NOT wall routes off from cross-route competition — Zach's explicit caveat.)

---

## 8. Build-order recommendation

**Prototype two routes with genuinely different failure modes side-by-side EARLY — war (rupture) and crime (exposure) are the most divergent pair.** If those two feel different in an hour of playtest, the compositional bet is proven and you can fan out to commerce and secrets with confidence. If they feel the same, you learn it now — cheap — before the architecture hardens around a false promise.

---

## 9. One-page checklist (for authoring any new route)

- [ ] Distinct **dominant constraint** (the perpetually scarce/at-risk thing)?
- [ ] Distinct **characteristic failure** (breaks differently; recovery is a different action)?
- [ ] **Route-specific antagonist** behavior from the sim?
- [ ] **Cross-interference** with at least one other route (feeds/starves)?
- [ ] Distinct **people + mechanism + stats** to operate (the moment)?
- [ ] Every verb **terminates in a person's decision** that can refuse?
- [ ] A **top-tier win the other routes can't reach** (parity)?
- [ ] Expressed as a **data bundle**, with **no code naming the route**?
- [ ] If it borrows another route's tools, are they **taxed at a premium**?
- [ ] If purely a goal-weight with **no bespoke pressure** → it is NOT a path. Reject.
