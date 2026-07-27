# Social & Political Layer — Design Session Decisions (2026-07-24)

*Party-mode pressure-test of the "The King You Don't See — Design Summary" (the
emergent-NPC-simulation + leverage-politics rethink). Table: Samus Shepard (game
designer), Cloud Dragonborn (game architect), Sally (UX), Indie (solo dev).
Every entry below is a **decision Zach made in-session** or an **open tension**,
not a suggestion. This feeds the next PRD.*

*Grounding note: the demand-resolver economy (hunger → food → labor → money) is
already shipped headless across slices 1 → 3b on `poc-v2`. This session is about
the layer that sits ON TOP of that — social influence, leverage, and the
diegetic reading game. See `poc-v2-system-spirit.md` for the economy substrate.*

---

## 0. The one-line game

You begin as an actor the world acts upon, and end as one who acts upon the world
**through others**, **without being seen**. First you earn coin to fill your
belly and make good decisions; then you build influence — through **loyalty** or
through **coercion/fear** — until you can make a dent in the world. The core
"combat" is **leverage**: moving a person who moves a person, your hand undetected.

Build discipline (unchanged from prior memory): smallest playable thing first,
seams day one, ship simplest impl, graduate later. Brick by brick — but **each
brick must be shaped like the cathedral.**

---

## 1. Core verb — LEVERAGE (⚠️ SUPERSEDED — re-litigated 2026-07-24)

> **RE-LITIGATION RECORD (2026-07-24, PRD vision party session).** This section
> originally read *"Leverage is the core combat. Reveal is secondary."* That claim
> was **explicitly overturned** later the same day. Zach's correction: *"It's not
> that leverage is the core combat, per se — the player can definitely act
> directly. As they accumulate power/influence, gates open to new actions,
> strategies, individuals to direct."* The corrected position:
>
> - **Leverage is NOT the core combat.** It is **one path** — the covert /
>   through-others form of power. **Direct/overt action (commanding, coercing) is
>   first-class, equal to it.**
> - The true spine is **illegible authorship** (the world can't read your reach /
>   method, whether your hand is hidden OR your sword is drawn), climbing the
>   **arc-vector** from unable-to-perceive-the-unseen-hand → becoming it.
> - Power = *how many people fall under the shadow of your decisions.*
> - The bullets below remain valid **scoped to the leverage/covert path** — they
>   describe how that ONE path works, not the whole game.
>
> Authoritative current framing lives in `design-positioning-and-comparables.md`
> (§2 illegible-authorship spine) and `design-multipath-routes-framework.md`
> (leverage as one of several distinct routes), and in the path-agnostic PRD
> Executive Summary + Success Criteria (`planning-artifacts/prd.md`).

*The leverage/covert path (valid, scoped):*

- The atom is **"I act on A, and A visibly acts on B, and my name is on nothing
  the world can see."**
- **Proxy must VISIBLY ACT.** Rejected: *passive social-proof* ("you look
  protected because you're in with A, and the world recalculates around you").
  Required: *active dispatch* ("A stands up / vouches / leans on B **because of
  what you did for A**"). The difference is "I look safe" vs. "I have a weapon I
  didn't know I was holding." Only the second is the fantasy.
- Cheap-skin rule: "A acts" is a **game-logic event** (a discrete, logged,
  attributed action A takes), NOT a bespoke animation. The expensive part is
  making the **causal chain readable**, not rendering it.

## 2. Attribution & the epic moment (decided)

- The late-game payoff is a traceable cascade: e.g. *famine → lord keeps grain
  stores locked → workers strike → mob → revolt.* Symmetry required: for every
  lucky cascade there are unlucky ones. The chain must be **legible after the
  fact** (you can connect the events).
- **DECISION — counterfactual marking is NOT required.** Samus argued the sim
  should mark "the pivot node where your influence was decisive" (60/40 → locked
  *because of you*). Zach's call: *doesn't matter what percentage led to the
  decision.* The visible cascade + the player's own confirmation is the right
  experience.
- **Authorship is relocated, not dropped.** It comes from **predict-then-watch**:
  one day the player has the power to *decide* the pivotal action — directly, or
  by getting an agent to convince the decider — and can **accurately predict the
  impact** before it unfolds. Calling the shot and then watching it land IS the
  authorship. (This is arguably stronger than a sim-drawn fingerprint: the player
  earns the credit by causing the decision, not by being shown a receipt.)

## 3. Legibility — the reading game (decided)

- **Discrete, gated greeting rungs — forever.** e.g. offer-no-hand → stiff
  handshake → formal greeting → warm handshake → hug. Each rung has a
  diegetically distinct signature. **Never subdivide** into "warm-ish" — that
  reintroduces the unreadable volume knob. We are NOT chasing subtle
  half-second-stiffer reads; that's too hard to get right and too hard to read.
- **Greeting still does three jobs** (state-readout + action + feedback-loop
  closing). Kept — it's good design economy.
- **New verb: LOOK, held separate from GREET.** Observe-mode. You can read an
  actor (do they look away? do they approach?) *without spending a greeting* and
  without altering the relationship. This resolves the "I can't just watch"
  contradiction and later powers "get someone alone" (alone, they don't
  re-compose to a public face).
- **The log stores the PREVIOUS rung, not just current.** The current rung is on
  the NPC's body; the *delta* ("cold — was warm") is the gameplay and it's the
  thing humans forget. Log entries must show the arrow.
- Degree/intensity, when it eventually matters, goes in the **sigil/color
  channel** (casual cap vs. full kit), never by adding greeting rungs.
- Deception/lying is a **later system.** For a long while, **like/dislike +
  candor** is enough interior state to read off of. Find **orthogonal tell
  vectors** so states don't blur (Sally's cut: gaze-target = fear; self-fidget =
  distracted-by-need; facing+distance = dislike; *interrupted/withheld gesture* =
  hiding-something — the last is a broken animation, legible even in silhouette).

## 4. Onboarding — teach the verb, not the fact (decided)

- **Tutorial / "information characters"** placed through the world teach the
  player how to play. Design test for each: **after they speak, does the player
  still have to do the perceiving?** If the line ends in a *name* ("Varic serves
  the Queen"), you wrote a quest marker. If it ends in a *category to watch for*
  ("watch the ones who won't give you their hands"), you wrote a teacher.
- Best form: the tutorial actor **demonstrates the tell himself, once**, so the
  lesson and the example are the same beat.
- **Rigged first cases.** Certain moments are scripted with rigged stats
  (guaranteed contrast — same NPC warm, then visibly changed) so the player
  learns "watch the delta" from a delta they cannot miss. These teed-up moments
  make the *rest* of the game feel fluid and alive by contrast.
- Front-load tutorial actors; one in hour twenty is an admission that hour twenty
  still isn't legible.

## 5. Memory & growth — sell REACH, never confiscate recall (decided)

- **The prosthesis (diegetic memory) always faithfully records what the player
  chose to notice.** Reward attention; never erase it. "Buy a better memory
  because yours is broken" is a band-aid / inventory chore and is rejected.
- **Growth is bought as breadth of ATTENTION / REACH**, not recall fidelity: how
  many actors you can keep tabs on, whether you can log someone glimpsed across a
  room, whether agents' reports file themselves. The power fantasy is *"I can
  watch more of the board now."*
- This resolves the reader-vs-half-blind fork cleanly: **you are a *perfect*
  reader of a *deliberately foggy* world.** Keep **denial of certainty** (you saw
  the tell, you're not sure what it means — that's the game). Drop **denial of
  recall** (the game confiscating your notes — that's a tax).
- Denial-of-certainty can additionally be dialed as a **difficulty mode.**

## 6. Information agents — unreliable eyes that extend reach (decided)

- Delegating perception to trusted NPCs is *literally the through-others fantasy
  pointed at perception itself.* Kept — becomes a mid/late-game weight-bearer so
  the player isn't doing every read personally. Checking the flow of information
  into your circle should be fun.
- **An agent is another pair of unreliable eyes, not an oracle.** Reports carry
  the same texture as a firsthand read — partial, angled, and *colored by the
  agent's own bias* ("Varic wouldn't meet my eye when the Queen came up," not
  "Confirmed: Varic serves the Queen"). This makes the player do **two reads**:
  the target through the report, and the reporter's trustworthiness. Core skill
  recurses instead of being retired.
- Guardrails: **agents cost and can be wrong, and their wrongness costs YOU** (a
  bad tip acted on burns your standing — same anti-save-scum rule as a wrong
  read). **Agents extend reach** (read a room you're not in) — they must never
  read the person in front of you better than you can.
- Anti-save-scum principle (general): a wrong read/probe/tip lands persistently
  on the *relationship*, not on a reload. If the only cost of being wrong is
  loading a save, the subtlest systems degrade into brute-force lockpicking.

## 7. Architecture — foundations (decided)

- **Stat store behind a narrow accessor from line one.** `get_primary`,
  `get_derived`, `write_primary` — nothing else touches storage, ever. Backing is
  a humble Dictionary today; SoA `PackedFloat32Array` later; C#/GDExtension for
  the per-tick loop someday. Call sites never learn the difference. *This is the
  one wall that, if wrong, forces the month-long rewrite.*
- **Derived stats: lazy-with-version, not never-cache.** Recompute on read, per
  (actor,target), only when a consideration touches them; rebuild only when the
  primaries' dirty-stamp changed. Gets the "no stale data" guarantee without the
  O(actors²) per-tick blowup.
- **Social graph = sparse + inheritance.** Store only *deviating* relationships as
  explicit edges; everyone else is felt via a **faction-level default** ("I feel
  toward this stranger what my faction feels toward his"). ~95% of pairs never
  allocate a float. The player is allowed to be a high-degree hub (that's O(N));
  the disaster is a dense mesh (O(N²)), which this prevents.
- **Goals bias the utility of a HAND-AUTHORED set of actions.** Confirmed:
  effect-signatures are authored by hand — more design control, and cheaper than
  computing gradients through nonlinear derived stats. Honest naming: we traded
  *automatic* goal→action matching for *authored* goal→action biasing. The
  effect-signature graph is a **suggestion tool** (proposes tags for a human to
  accept), not an oracle. Direction: inherited biases UP, hand-placed overrides
  DOWN — same shape as the relationship graph. Build basics, then see if the
  blocks hold.
- **Two-tier seam: events are the SOLE cross-tier channel.** No leaking
  continuous floats (prices, stock) alongside the headlines — two channels of
  cross-tier truth fight and drag you back into reconciling floats. The far world
  is night-ticked and emits **headlines/newspapers** ("bandits burned the north
  granary," "Lord Aldric fell") that come back to local. Events must be
  idempotent + authoritative. Bonus: the seam becomes *diegetic* — news lag and
  unreliable reports read as intrigue, not as a bug. (Jensen's inequality means
  aggregate floats can *never* exactly match micro-decisions; stop chasing
  "nothing jumps," promise "nothing leaks" — conserve shared totals across
  instantiate/collapse.)
- **ONE promote/collapse seam for BOTH spatial and social LOD.** Spatial ("am I
  near you") and social salience ("do you matter to the story") are the *same
  mechanism*: live as a cheap faction-averaged float until something promotes you
  — the player notices you, grievance crosses a threshold, a faction recruits you
  — then you're born as a full individual node with your own edges. Build it once;
  two separate LOD systems will drift out of sync the first time the player walks
  into a far region to confront a traitor who only exists in one of them.
- **Power = PageRank over the leverage graph, on the SLOW tick only.** Eigenvector
  centrality via power iteration is milliseconds on dozens of nodes — but it's a
  *slow-moving structural truth*, amortized on the settlement tick, read cheaply
  between refreshes. Add a damping factor (transitive leverage = cycles).

## 8. Off-screen truth — the load-bearing requirement (decided)

- **The masses are still DRAWN** (you see fields worked, alley shadows, bandit
  camps prepping a raid, soldiers readying a siege). Drawn ≠ individually
  simulated. They just **don't carry individual social floats driving
  decisions** — they run on faction-level dynamics. The promote system decides
  who graduates to individual dynamics.
- **The traitor problem:** a faction stat is an *average*; a traitor is the
  *outlier the average erases*. A purely faction-level social model structurally
  *cannot represent* the one covert creature who is the whole point of the title.
  The promote/collapse seam is the answer: **the traitor is born the moment the
  sim or the player makes him individual.**
- **The sim must be truthful off-screen** (flagged by both Indie and Cloud, same
  requirement from two directions). Hidden/aggregated kingmakers must *genuinely
  act and leave a coherent trail* while unseen, so that when the player finally
  gains the visibility to "see," the conspiracy holds up to scrutiny. Do NOT ship
  "visibility" as a fog toggle over a graph that's secretly static — that's a
  cardboard reveal. Prove hidden-actors-act-coherently in the smallest form
  *before* building any progression UI on top of it. (This is a later-session
  concern, flagged now so nobody specs a beautiful reveal over a sim that can't
  back it up.)
- **Visibility-as-progression** ("you can't see the kingmakers → you start to see
  → you pull the strings") is endorsed as possibly the best-feeling mechanic, and
  cheap — it's an information-reveal gate over a graph the sim runs the same the
  whole time. The cost is entirely in requirement #3 above (off-screen coherence).

---

## 9. Deferred — hard cut from near-term scope

Kept in the vision, cut from the next build. Ship stubs / hand-set values;
graduate when the blocks below them are proven.

- **PageRank power graph** — stub returning a hand-set number until there's a
  graph worth ranking.
- **Two-tier scaling** (local sim + far aggregate) — no seam visible at one-room
  scale; biggest time-sink for zero prototype value right now.
- **Nested 2–3-level goals w/ automatic effect-signature linking** — slice-1
  goals are flat and hand-authored.
- **Context-of-observation** (greeting changes by who's watching) — one of the
  coolest ideas; note loud for the animation-budget version, one-line rule at
  most in the icon prototype.
- **3D body-language tell rendering** — defer the *rendering*, keep the
  *semantics*. Sim knows the tell + rung; screen shows an icon/portrait/text in
  the prototype skin. The "diegetic, no bars" purity is a *shipped-game* goal, not
  a *prototype* constraint — faking it with portraits + icons *protects* the
  vision by getting you to the loop before the animation mountain.

---

## 10. Open tensions carried forward (not yet resolved)

- **The "A visibly acts" attribution chain** must be readable in the prototype
  skin — round → Bram → Cato → *my name nowhere.* Whether that reads is exactly
  what the pub-slice session must answer.
- **Earliest reads can't be pure noise.** Even before the explicit ladder is
  unlocked, reads must be *directional/comparative* ("warmer or colder than the
  last guy," a single-scene contrast) — ambiguous is fine, unanchored is death.
- **Off-screen coherence** (§8) is asserted as a requirement but unproven; needs
  its own smallest-form validation before any reveal/progression UI.
- **Legibility unlocks with influence** (the explicit ladder is *earned*) is a
  lovely progression idea but needs a guardrail so hour-one isn't unreadable.

---

## Next steps

1. **Dedicated pub-slice session** — build from `pub-slice-leverage-seed.md`
   (smallest leverage loop, ugly-honest skin). The single question it answers:
   *does moving Cato through Bram's arm feel like unseen leverage, or a meter
   with extra steps?*
2. **PRD** — this document is the raw material. Convert §1–§8 decisions into
   requirements; §9 into explicit out-of-scope; §10 into risks.
