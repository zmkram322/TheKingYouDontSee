# Decisions — Critique of `tkyds-game/brain/`

**Ruled** 2026-08-03, branch `poc-v2`. Closes Part 1 of `brain-critique-and-world-session-plan.md`.
Room: Winston (architect), Cloud Dragonborn (game architect), Samus Shepard (game designer), John (PM), each run as an independent subagent against the code, the plan, and the PRD.

---

## First: what was struck, and why

A large share of the room's findings were the same finding — **nothing calls `decide_action()`**, so an actor never re-decides mid-action, survival never actually outbids mid-walk, and idle actors rescan forever.

**That is not a defect. It is the world layer, deliberately unbuilt.** The substrate was built first, on purpose: how one actor decides, and how actions chain. The things that would poke a reconsider — hunger draining, market hours opening and closing, daylight, a fright, a passer-by — are Part 2's job. `decide_action()` is public and cheap; the hook exists and is waiting for callers.

Struck on that basis:

- "No reconsider trigger exists" (raised by three of four voices).
- "`active_action` is stored progress." Once events poke reconsider, it is the last answer held until the next question — not a memory that prevents re-asking.
- "The top level is deaf during a 3-second walk."
- "Every idle actor runs a full scan at 60Hz."
- "FR7's survival-outbids is undelivered."

Also struck: **findings about how the smoke tests wire the brain, as distinct from the design.** Where a test exposed a genuine design defect it is kept below and re-stated as a design defect. Where it only showed a test doing something odd, it is gone.

---

## Verdicts — the seed items

| Item | Verdict | Ruling |
|---|---|---|
| **A** — protected set has no representation | **BRAIN + PRD CHANGE** | FR86's "cannot be excluded" is structural language and gets a structural guarantee: an explicit `protected` marker on the action, **not** the old "no gate means universal". Forgetting to write a gate must never promote an action into the protected set. FR86 also gains the category-not-instance scoping. |
| **B** — does the generator prune behaviour or cost? | **BRAIN CHANGE** | Narrowing *instances* is legitimate and stays. The defect is that an empty generator reports **satisfied**. See design defect 1. No PRD change — A's category scoping already legalises the narrowing. |
| **C** — obligations compete rather than bias | **PRD CHANGE, by addition** | The brain is right. Competing is the *stricter* guarantee than biasing: a large enough bias is indistinguishable from a script, whereas a peer candidate can always be outbid (FR13, which already said "competes" and "outbid"). The PRD was short a word, not wrong. |
| **Goal naming** (deferred twice) | **SETTLED** | Two concepts, one word. **Goal** = standing intent, installed from outside, no completion condition, tilts many actions. **Obligation** = one dischargeable job that competes as its own candidate. The PRD keeps "goal" and gains "obligation" as a defined term. A goal may emit obligations. `brain/` renames nothing — its comments already say obligation. |
| **D** — is the queue an FR84 violation? | **PRD CHANGE** | It is legitimate storage. The test is **regenerability, not persistence**: hunger regenerates from a stat, so storing "still hungry" would be a second memory of intent; "a lord told you to plough" regenerates from nothing, so refusing to store it is amnesia. The PRD currently reads as prohibiting the queue and must say otherwise. |
| **E** — nested decisions vs "one shared pass" | **NO CHANGE to the rule; FR1 wording clarified** | Unanimous across all four voices: FR1 means one *mechanism*, not one *evaluation*. `Choice` calls the same `choose_action` over a narrower set. Flattening would put fifty inns in the top-level candidate list — precisely the cost FR85 exists to prevent. FR1's wording is ambiguous and gets tightened. |
| **F** — where do channels gate anything? | **PRD CHANGE; deferral upheld** | Genuine gap, correctly out of scope. Decided, so the deferral is deliberate: **the channel sets the weight the obligation carries into the scoring pass — never permission to assign.** A gate on assignment means the refusal never happens, and the refusal is the interesting part (FR31). The seam already exists: `Action.score` takes the subject and today ignores it. |
| **G** — cheaper shots | **PARTLY BRAIN CHANGE** | Kept: winner asked three times per tick (defect 3), the reference cycle (defect 4). Struck as world layer: the busy loop. Deferred: tuning-constants block (already in Part 2 scope), stat accessor, typed subject. |

---

## Status — all six landed 2026-08-03

Code done, all nine suites green (`brain_smoke`, `brain_steps_smoke`, `brain_choice_smoke`, `sandbox_smoke`, `board_smoke`, `placement_smoke`, `settlement_smoke`, `terrain_smoke`, `town_smoke`). The three brain suites now run **leak-free** — defect 4 removed the cycle. The PRD edit list below has **not** been applied yet.

Two things found while building that weren't in the plan:

- **`sandbox/walk_to.gd` and `brain/walk_to.gd` both declared `class_name WalkTo`.** Godot does not report this; one silently wins, and which one depends on the order the project was scanned in. A reimport flipped it, and both step suites failed with a constructor from the wrong class. Renamed the sandbox one to `SandboxWalkTo` (two lines) so `brain/` keeps the plain name. **This was a live landmine, not something the changes introduced** — it would have fired on any future reimport.
- **`Character.act` now re-decides nothing when the work is impossible.** It abandons and returns, so the next tick re-asks. That means an actor with an impossible obligation re-picks it each tick and abandons it again — no work done, same cost as any idle actor, and it stops entirely once the world changes. The real fix is expiry (FR103, Part 2). Commented at the call site so it reads as a decision.

New proofs added: an obligation carried through to completion and discharged (`brain_smoke` §7 — the flagship scene was previously only ever *scored*, never run); a protected action surviving a gate that says `return false` (§8); work already owed being recognised (§9); and an errand staying owed when every inn shuts (`brain_choice_smoke` §4 — the failure that would have eaten Part 2).

---

## The six design defects to fix

Real regardless of what world gets wired up.

### 1. A Step can say "done" or "not yet." It cannot say "I can't."

The source of four symptoms the room reported as unrelated bugs. `Choice.is_satisfied` returns **true** when nothing can be picked (`choice.gd:37-41`), which `Character.act` reads as completion and turns into `finish_active_action()` (`character.gd:79-80`), which erases the item from the queue (`decision_brain.gd:151`).

So: a starving character with every inn closed reads as having finished eating. An obligation nobody can serve **discharges its own debt**. And the character finishes-and-re-decides every tick while it happens.

Two answers cannot carry three states.

**Change:** add a third question — `is_possible(who)`, defaulting true on `Step`. `Choice` returns false when nothing can be picked; `Sequence` returns false when its frontier child is impossible. `Character.act` treats impossible as *abandon and re-decide, do not discharge*. Make an impossible `Choice` describe itself rather than returning an empty string.
**Files:** `step.gd`, `choice.gd`, `sequence.gd`, `character.gd`. ~15 lines.

### 2. The design has rooms with no exit.

`character.gd:73-74` — an Action whose `body` is null is pursued forever: `act()` returns every tick, the action is never finished, and nothing re-decides. `body` is optional in the type but the loop cannot handle it.

**Change:** make `body` required in `Action._init`. An action that cannot be carried out should not be choosable. This will break the smoke suites, which build orders with no body — that is the point: prove one obligation completing end to end.
**Files:** `action.gd`, `character.gd`, all three test suites. Small, plus test work.

*Related and deferred:* an obligation the actor is ineligible for is skipped every tick and stays owed forever. That is expiry, already in Part 2 scope.

### 3. The winner is asked three times a tick and can change between asks.

`Character.act` calls `is_satisfied`, then `advance` — which moves the character, which changes the scores — then `is_satisfied` again. Today this is safe only because the one authored curve happens to rise as you approach the target. Nothing enforces that.

**Change:** `advance` returns whether it is now satisfied; `act()` asks once and uses the answer. Two traversals instead of three, and the "is it done" answer can no longer come from a different option than the one that did the work.
**Files:** `step.gd`, `sequence.gd`, `choice.gd`, `walk_to.gd`, `character.gd`. ~10 lines.

### 4. `DecisionBrain` is two things wearing one name.

The ranking half (`is_available`, `determine_available_actions`, `score`, `highest_scoring`, `choose_action`) needs no subject — only to be handed one. The other half is this character's queue and current action. Welding them is what creates the `Character → brain → subject → Character` loop that never frees, and it is why the file's own claim ("usable by any subject at all") is not true.

**Change:** ranking methods take `who` as a parameter; `queue` and `active_action` move onto `Character`. The loop cannot form, and the ranker becomes shareable the way Steps already are.
**Files:** `decision_brain.gd`, `character.gd`, `choice.gd`. Largest of the six — sequence it after 1–3 if time is short; nothing else depends on it.

### 5. FR86's protected set has nowhere to live.

`Action._init` requires an `eligible` Callable and `is_available` always calls it, so `flee` can be gated out of existence. An absent option is the least readable thing in the game: a losing bid is a row with a number, an option that was never offered has no row at all. Gate `flee` off a guard and every point of fear the player spends on him silently returns nothing.

**Change:** `Action.protected: bool`. `is_available` returns true for a protected action without calling `eligible`. The protected categories (eat, flee, confront, beg, steal, hold ground) live in one named list as data, so the guarantee is testable.
**Files:** `action.gd`, `decision_brain.gd`, one new small data file. ~10 lines.

### 6. Obligations are matched by object identity.

`queue.erase(action)` and `active_action == action` compare object references. Fine while you hold the reference. It breaks the moment work is *generated* to hand to another character — you cannot cancel, find, or avoid duplicating an obligation you never kept a pointer to. `brain_choice_smoke.gd` already hand-rolls a memo dictionary to keep identity stable, inside a test, because the type does not support it.

**This is the only one of the six that specifically blocks Part 2.**

**Change:** the queue item gains a record — *who asked*, *what for* (a key you can match on), *when*. Then "have I already asked?" is a lookup rather than a stored flag, which is what keeps emission re-derivable.
**Files:** new `obligation.gd`, `decision_brain.gd`. Small, and it discharges three separate needs at once: emit-without-duplicating, channel weighting later, and expiry.

### Noted, not ruled

Small and real; take them if they're in the way, skip them otherwise. `Character.doing_label()` throws away the action's own label and returns only the leaf's description, so a flee renders as `"walking to (0, -220)"` — six characters of fix. `highest_scoring` seeds at `-INF` and compares with `>`, so an action scoring exactly `-INF` never wins even unopposed, and a `NaN` produces a motionless actor with no error. `brain_smoke.gd` has 24 checks and no `EXPECTED_CHECKS` guard, unlike the two newer suites.

Deliberately deferred, all defensible, none blocking: restoring a stat accessor seam over the raw `stats` dictionary (FR4 has no substrate today), capturing the score table so the game can answer "what did it beat", making an actor's queue readable, and the shared tuning-constants block (already in Part 2 scope).

---

## PRD edit list

**Numbering: next free is FR100.** FR88–FR99 are the Board group at L588–599 — the session plan's "next free after FR87" was wrong. Existing FR numbers are stable identifiers.

### Amendments in place

**FR1** (L508) — replace:
> - FR1: The Simulation scores every actor decision — pursuing an unmet need, answering another actor's unmet need, or taking an immediate contested action — through **one shared weighted-utility mechanism** over that actor's current primary and derived stats; no decision is scripted per actor. A decision nested inside an action's execution — which provider, which target, which place — runs that same mechanism over a narrower candidate set, and is not a second kind of decision.

**FR9** (L519) — replace:
> - FR9: A **goal** — standing intent, installed from outside, persisting until revoked and carrying no completion condition of its own — biases the utility of a hand-authored action set already in the actor's eligible pool, and may emit obligations (FR100). Goals never script actions.

**FR12** (L522) — replace:
> - FR12: Whether an installed goal clears an actor's action-decision threshold is gated by the channel the Player holds over that actor (any of loyalty, fear, economic dependence, authority, informational exposure). The channel sets the **weight** the goal carries into the actor's ordinary scoring pass; it is never permission to install, which would make the refusal invisible and contradict FR31.

**FR84** (L525) — replace:
> - FR84: An actor's unmet need is derived from that actor's current primary and derived stats at each decision point; the Simulation does not store a separate persistent record of "still pursuing" beyond the underlying stat. Intent that originated **outside** the actor — a goal (FR10) or an obligation (FR100) — is the sole permitted exception, governed by FR101.

**FR86** (L527) — replace:
> - FR86: A protected set of survival and direct interpersonal action **categories** (eat, flee, confront, beg, steal, hold ground) is enumerated as data and eligible to every actor regardless of role, faction, possession, or position; a protected action's eligibility predicate is never evaluated. Membership is declared explicitly and is never inferred from a missing predicate — an omitted gate is an authoring error, not a promotion into this set. Protection covers the **category**, never a particular instance of it: narrowing which providers an actor considers is legitimate, leaving the category with no instance at all is not.

**FR87** (L528) — replace:
> - FR87: An actor's candidate pool is their eligible capabilities plus their outstanding obligations (FR100). Goals bias the weight of actions already in that pool; goals never add or remove eligibility, and an obligation entering the pool is never exempt from the eligibility filter (FR85).

**FR7** (L514) — amend when the tuning block lands in Part 2, not before. Append:
> The weights sit in one shared tuning table, so "dominates" is a checkable relation between named constants rather than a property smeared across individual action definitions.

### New requirements — append after FR87 (L528)

> - FR100: An **obligation** — a discrete, dischargeable piece of work assigned to an actor from outside — enters that actor's candidate set as a peer action carrying its own weight, competing directly against the actor's own needs rather than modifying their scores. It is eligibility-filtered like any other action (FR85), remains owed while it is being worked on, and leaves the actor only when discharged, revoked, or expired. Competing rather than biasing is the stricter guarantee: a sufficiently large bias is indistinguishable from a script, whereas a peer candidate can always be outbid (FR13).
> - FR101: The test for what an actor may store is **regenerability, not persistence**: anything the next scoring pass would rediscover from the actor's own stats is never stored (FR84); intent that no stat regenerates — a goal, an obligation — is stored on the actor, because deleting it deletes it for good. An actor never stores its own self-directed choice.
> - FR102: The weight an assigned goal or obligation carries into an actor's scoring pass is computed from the assigner's held channel over that actor **at the moment of scoring**, not fixed at the moment of assignment. Until channels exist, that weight is supplied as an authored constant through the same seam, so implementing channels replaces a value and never a call site.
> - FR103: An outstanding obligation expires when the condition that justified it no longer holds, and an obligation the actor is permanently ineligible for is discharged rather than remaining owed; no actor accumulates obligations without bound.

### Core Mechanical Model prose

**L211**, §The atom — append:
> **The exception is intent that came from outside the actor.** A goal installed in someone, or an obligation handed to them, is stored — because nothing in their own stats will regenerate it. The discriminating test is regenerability, not persistence (FR101): if the next scoring pass would rediscover it, storing it is a second memory of intent; if it would not, refusing to store it is amnesia.

**L215** — replace the header:
> ### Behaviour — needs by default, goals and obligations by exception

**L218** — append to the goal bullet: *A goal shifts many weights at once and carries no completion condition.* Then insert a new bullet after it:
> - **An obligation is a single piece of assigned work, and it competes rather than biases.** It enters the actor's candidate set as a peer action carrying its own weight, so an ordinary need can outbid it (FR13) and it is still owed afterwards. The two shapes do different jobs and neither replaces the other: a goal makes a *class* of actions attractive across time, an obligation is *one thing* that must get done — and a goal may emit obligations. Per-item urgency ("the stew before the ale") is expressible only in the obligation shape; an aim reshaping a dozen weights at once is expressible only in the goal shape.

**L225**, §Eligibility — replace the protected-set bullet:
> - **A protected universal set is eligible to every actor, always.** Survival responses and direct interpersonal actions (eat, flee, confront, beg, steal, hold ground) are **explicitly marked protected** and compete in every actor's scoring pass regardless of role; their eligibility is never evaluated. The marking is explicit and never a missing predicate — an author who forgets to gate an action has written a bug, not promoted it into this set. **Protection is by category, never by instance:** a starving man must always be able to attempt `eat`; he is not entitled to have every inn in the region scored. This is the same guarantee that lets a sufficiently-held actor hold his post while starving: nothing may be pruned from this set by identity, only by weight.

**L227**, §Eligibility — append to the final sentence:
> …and the pool a goal biases is that actor's eligible capabilities plus their outstanding obligations (FR87, FR100), never the full action registry.

**L240**, §Influence — append:
> The channel sets the *weight* an installed goal carries into the actor's ordinary scoring pass; it is never permission to install. Anyone may attempt; the deliberation — and the refusal — happen in the same pass as everything else (FR31).

**L291**, §The Board — no text change. Its parenthetical now inherits from FR101; if a future edit touches the line, replace `(contrast FR84)` with `(FR101)`.

---

## Goals emitting obligations — what it changes

Nothing to build this session. Recorded so it isn't rediscovered.

**The mechanism already has an owner.** A goal that adds an obligation each tick floods the queue, so emission must be able to ask *"did I already ask for this?"* — which needs matchable obligations, which is design defect 6. That is the same operation as Part 2's cross-actor emit: put a piece of work somewhere without duplicating it if it's already there. One mechanism, two customers. Goals do not add a machine.

**Two questions it opens, to rule on when goals get built:**

- *Lump or tilt?* A goal expressed as an Action whose body never finishes works with today's types for free — it competes, it can be outbid, it never discharges. But it competes as one lump: if "prepare for siege" loses to hunger, hoarding and drilling and wall-repair all lose together. True biasing would let a badly-needed wall repair beat hunger while hoarding doesn't. Different behaviour; the lump is far cheaper.
- *Which direction does it emit?* Onto its own owner is decomposition; onto subordinates is delegation — same call, different target. But §Cascade says intent propagates downward by **changing the state people react to**, not by handing work down. Emitting obligations onto subordinates is a third path the PRD doesn't describe. Settle it there before it becomes drift.

---

## Part 2 is unblocked

Defect 6 (matchable obligations) is the only item Part 2 waits on; it is small and it is the same object Part 2 needs for emit-and-wait. Defects 1–3 and 5 are cheap and should land first because Part 2 will exercise all of them. Defect 4 can follow.

Two carry-overs from the room worth holding onto while building the world:

- **There may be no `Wait` step at all.** Waiting is not a state an actor is in — it's what it looks like from outside when the interesting action is ineligible and something duller keeps winning. The innkeeper doesn't wait for flour; she sweeps, and `bake bread` gates on having flour.
- **Duration is world-side, not Step-side.** Re-derivation handles *state-based* work (walk until there, eat until fed) cleanly and *duration-based* work (mill for an hour, stand the watch) not at all. Express duration as a progress stat on the thing being worked, not a timer on a shared Step. Be honest that this is more state, not less — it is still the right trade, because world-side progress survives interruption and a timer on a shared Step cannot.
