# Rung 6 — what shipping it found

**Written 2026-08-14, the day 6a through 6d landed** (`aedd5a7`, `d6376e3`,
`2bedc87`, `15a74c7`, `8bb96a4`, plus `6269254`, `141ed58`, `a7161c3`). Fable
orchestrated, Sonnet built against re-derived delta sheets, Fable verified and
committed each gate.

**This file is for a conversation, not for a builder.** It is the things a
green probe does not say. Every claim in it is measured — the numbers come from
a six-day pump of the shipped scene, run and deleted — and where I am guessing I
say so. Nothing here has been acted on; three of the items are calls that are
yours to make.

Read Part 1 first. The rest is context for it.

---

## Part 1 — Three findings that want a decision

### 1. Nobody can ever bake, and the town starves around day eight

**This is the big one, and the probe cannot see it** — it pumps 48 hours, and
the longest measurement anyone has run is six days. The failure lands on day
seven or eight.

Measured over six days of the shipped scene:

| | Zoogs | Hobb | Marle |
|---|---|---|---|
| worked | 19.0 h | 63.7 h | 0 h |
| **grain held at the end** | **0** | **0** | **0** |
| bread held (from 14) | 4 | 4 | 4 |
| **times anyone baked** | **0** | **0** | **0** |
| barn | \- | \- | 63 grain |

**No man ever holds a grain**, and that is structural rather than incidental.
`WorkForHireStep` delivers `min(carrying, what is still owed today)` on every
tick it works, and the quota is never met (63 grain into the barn over six days
against 24 a day owed between two men), so *what is still owed* never reaches
zero, so every grain he makes leaves his hands the same tick it arrives.

`MakeBread` gates on holding three grain. Nobody ever holds one. **So the loop
rung 6a2 exists to close — work → grain → bread → eat → work — cannot fire in
the shipped scene, at all, ever.** At roughly two meals a day the fourteen
authored loaves run out around day seven, and then all three men climb to the
top of the hunger scale and stay there, with nothing to do about it.

My commit message for 6b says *"the surplus a man holds past quota is rung 7's
trade stock."* **That was wrong when I wrote it. There is no surplus, by
construction.**

**Why this is interesting rather than merely broken.** The mechanism is: *the
lord's quota takes everything a man makes, and the men starve.* For this game
that is not a bug, it is the title. But it arrived by accident, and Decision
26's stake was a different one — *the man who loses the dawn race starves*,
where losing is the cause. What actually happens is that **everyone starves
equally, and the cause is the agreement rather than the contention.**

The call is yours, and I think it is genuinely open:

| If you want | Then |
|---|---|
| the quota to be survivable | a man keeps a share, or the quota is a floor on delivery rather than a ceiling on work, or the farm owner feeds his men (rung 7's trade) |
| the quota to be a threat | leave it, build starving (Decision 27), and this becomes the ladder's first real stake — a town that works itself to death for a barn it never eats from |
| the loop to be watchable at all | one of the above, or 6a2 stays a mechanism nobody has ever seen run |

Decision 26 already left *make-or-buy as a stock target* open and pointed it at
6b's quota machinery. This is that question arriving with teeth.

---

### 2. The dither — one absence, two symptoms

**Zoogs changed action 1145 times on day two. Hobb changed 224.** The loop:

1. He walks to the fields, because a plot's freeness is unknowable from afar
   and work stays on his ballot — Decision 15, and the wasted journey is
   deliberately the point.
2. He arrives, sees Hobb has the plot, and work leaves his ballot on that tick.
3. `Socialise` is now his top bid, so he takes one step toward the tavern.
4. One step away from the fields he can no longer see the plot, so work returns
   at full strength and beats socialising, and he turns round.
5. Back to 2.

**Every rule in that loop is individually correct.** Before 6d there was simply
nothing else on his ballot, so he stood still where he lost — which is exactly
what probe claim 22 asserts, and it still passes. Give a man one competing want
that moves him and the boundary becomes a limit cycle.

It is the same hole as the empty tavern, seen from the other side. He tried the
plot and could not have it; he tried the tavern and found it empty. **Neither
failure is recorded anywhere, so both wants come back at full strength on the
very next tick.** Decision 23 (failure marks the candidate) and Decision 24
(recorded at the place it failed, decaying) are **one mechanism with two
symptoms already waiting for it.**

I refused to paper over it — Decision 23 rejects the commitment bonus and the
cooldown by name, and both would have hidden this. The `change_of_scene`
trickle in item 4 below is the cheap stand-in I did ship, and I am not proud of
it.

**My recommendation, for what it is worth: build the mechanism as its own gate
before rung 7.** Rung 7 adds a refused trade partner, which is a third symptom
of the same absence, and Decision 23 already says so in advance.

---

### 3. Rung 6d cost Hobb the ninety minutes that met his quota

At 6b, measured: Hobb hit quota at **16:41** and the barn gained **exactly 12 a
day**. That was 6b's Moment — *work's utility falls off the graph*, which the
build plan calls probably the single best gate in the ladder.

At 6d, measured: Hobb works **10.6 hours a day** and the barn gains **10.5**.
He spends **1.4 hours a day at the tavern**. The arithmetic closes exactly: the
tavern took the margin, and he now finishes every day just short.

**So 6b's Moment no longer happens in the shipped scene.** Work never
discharges, so it never collapses, so there is nothing to watch. Nothing is
broken — this is two correct rungs interacting — but the gate you would most
want to show someone is currently unreachable without dropping the quota below
about ten, or raising the yield.

This is also *why* finding 1 bites: an unmet quota is what keeps the delivery
cap open and strips every grain.

---

## Part 2 — Things I changed that deserve your review

**The tick order is now decide → do → update** (6c, `brain.gd`). It was
decide → update → do since rung 0. Once `Sleep` grew a walk, *is he asleep*
became a fact the do phase writes, so a body updated first pays the transition
tick at the wrong rate — probe claim 2 caught it in both directions. The body
now pays for what the tick actually contained. **Every future step that writes
state the body reads depends on this order**, so it is worth knowing it moved.

**`Workstation.owner` is `owned_by` in code.** `owner` is a built-in `Node`
property and redeclaring it is a compile error. Every plan and decision snippet
saying `owner` means `owned_by`. Not a design change, but permanent, and it
will read as a discrepancy forever.

**The `change_of_scene_per_hour = 18` trickle is the one thing I would like
vetoed.** Sitting alone in the tavern soothes loneliness at 18/hour against
real company's 30. It exists because an empty-venue visit changes nothing in
the world, so without it the bid stands forever and the sleep anchor breaks —
measured: cold start slid to 05:27. It bends *company is the payoff, not the
option*, which was the whole point of your venue call. **It should shrink
toward zero the day failure-marks-the-candidate lands.**

**Two numbers are now load-bearing for a reason worth generalising.**
`company_worth` is 90 and `base_social_per_hour` is 2.5. The rule I extracted,
which is in Decision 28's prose but is not a numbered decision:

> **A want that can stand unresolved for hours must price below the ceilings of
> what it competes with. A want that resolves in one tick may price above
> them.**

`Eat` gets to sit at 130 — above work's 103 peak — only because a meal wins for
exactly one tick and then vanishes. `Socialise` at 110 was permanent capture: a
saturated man could never be outbid by sleep again, because sleep's own score
is capped at 100 and cannot climb to catch him. **If that reads right to you it
should probably be Decision 29**, because every future want will need it.

---

## Part 3 — What fifty green claims still do not prove

**Claims 31 and 49 could not fail on the thing they existed to guard**, and I
only found it by break-testing. Both pumped an *awake* man for an hour; the
no-branch rule in `_update_body` — the reason a man wakes hungry and wakes
lonely — was never tested on either stat, and hunger's line had been unguarded
since 6a. Both now have a sleeping half and both break red on cue (`6269254`).
**That is the eighth vacuous assertion this ladder has found this way.**

The generalisable lesson: **a claim about a rule with no branch has to be
asserted in the state the missing branch would have changed.** Worth an audit
pass over the other 48 at some point; I did not do one.

Still not proven by anything in the probe:

- **Any horizon longer than six days.** Finding 1 lives at day seven.
- **That the authored numbers produce a sustainable town** — every claim is
  about a mechanism, and no claim reads a balance.
- **That the day is watchable.** All fifty claims pass in a scene nobody has
  looked at.

---

## Part 4 — Five unwatched Moments

Nothing on the ladder is blocked by this, but the gates were designed to be
seen and none of these have been:

| Rung | The Moment | Instrument |
|---|---|---|
| 5 | two men's grain diverging over their heads | short day |
| 6a | two drives on one graph, and which wins | short day |
| 6b | work's utility falling off the graph at quota | **currently unreachable — see finding 3** |
| 6c | one man left standing while twenty sleep | short day |
| 6d | the first full day, end to end | short day |

The 6d one I can vouch for from the log: all three men converge on the tavern
between roughly 20:30 and 22:05 and then go to bed, every night. That part
works, and it is the first time the town has done anything together.

---

## Part 5 — What I would put on the agenda

In this order, and the first two are the ones I actually care about:

1. **Decide finding 1** — quota survivable, or quota as threat plus starving.
   It changes what rung 7 is for.
2. **Decide finding 2** — build failure-marks-the-candidate as its own gate
   before rung 7, or ship the dither as texture.
3. **Promote or reject the standing-want-pricing rule** as Decision 29.
4. **Watch something.** 6d's first full day is the cheapest and the most
   rewarding; 6b's needs finding 3 resolved first.
5. Then rung 7, which is the trade seam and wants findings 1 and 2 settled to
   be worth building.

---

## Appendix — the measured six days

Shipped scene, `day_length_seconds` irrelevant (pumped in world hours), three
people, one plot, twenty beds, one tavern.

```
cold start   turns in 21:17, up 05:55
settled      turns in 22:10, sleeps 7.99 h, up 06:09
strong man   up 04:47

                Zoogs    Hobb     Marle
worked           19.0 h   63.7 h    0.0 h
tavern            7.3 h    8.3 h   12.7 h
meals               10       10       10
bakes                0        0        0
ends: grain          0        0        0
ends: bread          4        4        4   (from 14)
day-2 action changes  1145      224        —

barn                63 grain over six days   (24/day owed between two men)
plot                last claimed by Hobb, day 5
```

Two notes on reading that table. **Zoogs is no longer shut out** — he works 19
hours because Hobb stops for the tavern and the plot frees, which is 6b and 6d
together fixing rung 5's inequality that nobody designed. And **Marle works
zero hours and spends the most time in the tavern**, which is correct: he owns
the plot, owes nothing, and has nothing else to do. The farm owner drinking
while his men work is fiction the sim produced on its own.
