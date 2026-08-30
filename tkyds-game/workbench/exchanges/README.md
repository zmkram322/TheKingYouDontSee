# exchanges — a workbench scene

**Nothing in `game/` is edited by anything in this folder.** Every script here
`extends` a class from `game/`; none replaces one, and none carries a
`class_name` (those are project-global, and there is no reason to burn one on
an experiment). The only file outside this folder that this work touched is
`project.godot`, which gained a single `sprint` action bound to Shift.

Run `exchanges.tscn` directly from the editor. **Do not change
`run/main_scene`** — that still points at `game/game.tscn`, which is what the
probe loads.

## Controls

| | |
|---|---|
| WASD / arrows | move, relative to where the camera is looking |
| Shift | run |
| Space | jump — one shove on the press; holding it does nothing |
| Mouse | look; pitch clamped to −60°..30° |
| Escape | release the cursor. Click anywhere to take it back |
| **T** | **take a loaf** — look at the bread basket and stand next to it |
| **E** | **greet** — up to 14 m. The way in: everything else needs the record it leaves |
| **G** | **give** a loaf — up to 2.8 m, and only to somebody you have greeted |
| **R** | **ask** him to work the ground — up to 4 m |
| **B** | **beckon** — 6 m to 30 m. NOT offered up close; it is for calling across a field |
| **F** | **come with me** — up to 14 m, and only if HE thinks well of YOU (over 20) |

**The ladder, in the order you will meet it:** take a loaf from the basket, walk
up to a man and greet him (+8 each way), give him the loaf (+15 to him, +2 to
you) — and now that he regards you at 23, **follow appears**, which it could not
before. Beckon needs only that you have met, and needs you to be standing back.

## The three warnings on startup are correct

> **This section said EIGHT until 2026-08-30 and was wrong.** It described a
> scene that had no `Clock`, no `Town` and no `Population`; the scene grew all
> three while this file was not updated. Left visible rather than quietly
> rewritten, because a README that tells you to expect warnings you do not get
> is worse than no README — it trains you to ignore the count.

`person.gd` says so out loud when a body has no world around it. This scene now
has a `Clock`, a `Town` and a `Population`, all wired, so the only thing missing
is a `Place`. **Expect exactly one warning per body, three bodies:**

```
You starts nowhere — no place query will ever find him
Somebody starts nowhere — no place query will ever find him
Another starts nowhere — no place query will ever find him
```

Do not silence them. CLAUDE.md is explicit that a silent null guard is how a
dead day/night cycle shipped through two commits, and "it runs without errors"
stopped counting as evidence here because of it.

## The clock is driven from above now

Since 2026-08-30 (project Decision 39) `Clock` has no `_process` and does not
advance itself. **`Population` owns the step loop** — it banks real seconds and
spends them on whole fixed ticks, advancing the Clock and thinking for everybody
once per tick.

`exchange_population.gd` overrides only `think_for_everyone`, so it inherits the
accumulator whole and the interrupt still installs: the base class doing the
calling still reaches the override. **Measured, not assumed** — `_seam_check.gd`
drives `step_real_time` directly and asserts a held man neither decides nor moves
while his body goes on running.

**What it means for this scene:** nothing to change, and one thing to know — a
single `step_real_time` call is capped at `Population.MAX_TICKS_PER_FRAME`, so
handing it ten frames' worth of seconds buys eight ticks, not ten. That is the
stall ceiling doing its job, not a bug in here.

## What this scene is actually testing

`game/`'s player moves by hand-integrated position in **world hours**
(`PlayerBrain._walk_where_he_is_pointed`), with no velocity and no gravity —
Decision 4 forbids `move_and_slide` outright. That buys a real guarantee:
dragging `day_length_seconds` cannot change how fast the player moves relative
to the NPCs beside him. It costs everything needing a physics body — falling,
airborne state, jumping.

This scene takes the other side of that trade, where taking it wrong is free.
Two divergences, both deliberate, both commented where they happen:

1. **`exchange_brain.gd` moves the body in `_physics_process` against a real
   delta.** `PlayerBrain`'s hour-based walk is overridden to a no-op so that
   wiring a `Population` above this scene later cannot move the body twice.
2. **`person_with_exchange.gd` picks clips off physics `velocity`, not
   `_speed`.** `_speed` is measured inside `Person.think_and_act`, which only
   `Population` calls — with no Population it is `0.0` forever, and the
   inherited `_show_the_body()` would play `idle` at a dead sprint.

## If any of this earns its way back into `game/`

The two functions above are the diff, and the question to answer *before*
either one moves is what happens to **probe claim 66**, which pins player
movement by driving real frame deltas through `Clock.get_hours_elapsed` at two
different day lengths. It measures precisely the thing `_physics_process`
stops doing.

## Known, and not worth fixing yet

`jump`, `jump_down` and `run_jump` import as `LOOP_NONE` (see
`assets/mixamo/mixamo_import.gd`), so a long fall plays its clip once and holds
the last pose. Note it while watching; do not build a blend tree until a fall
is long enough for it to look wrong.
