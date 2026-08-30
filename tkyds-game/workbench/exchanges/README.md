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

## The eight warnings on startup are correct

`person.gd` says so out loud when a body has no world around it, and this scene
deliberately gives it none — the NPC is a mannequin, so there is no `Clock`, no
`Town`, no `Population` and no `Place`. Expect four per body, twice:

```
X has no Population above him — he will never think
X has no Town — he can never be asked who else is here
X has no Clock — for him the sun never rises
X starts nowhere — no place query will ever find him
```

Do not silence them. CLAUDE.md is explicit that a silent null guard is how a
dead day/night cycle shipped through two commits, and "it runs without errors"
stopped counting as evidence here because of it.

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
