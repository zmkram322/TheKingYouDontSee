---
title: 'Exchanges workbench scene — a steered body that runs and jumps'
type: 'feature'
created: '2026-08-21'
status: 'in-progress'
baseline_commit: '662044b'
context:
  - '{project-root}/CLAUDE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The boss ladder's next gates are social (greet, beckon, give), and there is nowhere to judge how any of that *feels*. `game/`'s player can only walk: `PlayerBrain` integrates `global_position` by hand in world hours, so there is no velocity and no gravity, and Decision 4 forbids `move_and_slide`. Nothing in the project has a follow camera — `game.tscn`'s `Camera3D` is static.

**Approach:** A parallel scene in `workbench/exchanges/`, isolated from `game/`, built on a body that **extends** `Person` rather than copying it. Movement moves down into `_physics_process` so gravity, sprint and jump exist, and a mouse-look follow camera rides the body. Because the clone is a subclass, integrating anything back into `game/` later reads as a short diff against a named override instead of a merge between two drifted files.

## Boundaries & Constraints

**Always:**
- Everything new lives under `tkyds-game/workbench/exchanges/`.
- The clone is `extends Person` / `extends PlayerBrain`. **Never copy `person.gd`'s body** — `Person` is a declared type in 83 places across 27 files, and a non-`Person` body cannot enter the substrate at all.
- Workbench scripts carry **no `class_name`** — referenced by path from the `.tscn`, so no project-global name is burned.
- Every place the clone diverges from `game/` behaviour gets a comment saying so, in place. That comment is the integration-back note.
- Tunable numbers are `@export`, authored not derived, so they land on a tuning board and get picked by watching.

**Ask First:**
- Any edit to `project.godot` other than adding the `sprint` input action — **specifically `physics/common/physics_interpolation`**, which is project-wide and would reach the proving scene.
- Any change to any file under `game/`.

**Never:**
- Do not edit, refactor or "tidy" anything in `game/`.
- No `Clock`, `Town`, `Population`, `Place` or `Obligation` wiring this pass. The NPC is a mannequin.
- No exchange/greet/give verb yet — the controller is the whole subject.
- Do not suppress `person.gd`'s startup warnings. Eight are expected (four per body) and they are correct.
- No input-remapping layer, no state-machine framework, no animation-tree substrate.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Idle | No input, grounded | `idle` clip, body does not drift | N/A |
| Walk | WASD held, grounded | Moves camera-relative at `walk_speed`, `walk` clip, body faces travel | N/A |
| Run | WASD + sprint held, grounded | Moves at `run_speed`, `run` clip | N/A |
| Jump | `ui_jump` pressed while grounded | One upward impulse, `jump` clip | Held key must NOT add thrust |
| Falling | Airborne, descending | `jump_down` clip, gravity applied | N/A |
| Running jump | Airborne, horizontal speed ≥ run threshold | `run_jump` clip | N/A |
| Mouse look | Mouse moved, cursor captured | Yaw free, pitch clamped | Pivot must not spin when mouse stops |
| Release cursor | `ui_cancel` | Cursor visible; click recaptures | N/A |
| Missing clip | Clip absent from library | Warn once at `_ready`, never per-frame | Silent in the per-frame path |

</frozen-after-approval>

## Code Map

- `game/person.gd` — base class. `_show_the_body()` (two clips off `_speed`) and `_process()` are what the clone overrides. **Read only.**
- `game/player_brain.gd` — base for the steered fork. `_process` samples input into `_pointed`; `_walk_where_he_is_pointed(hours)` integrates it. **Read only.**
- `game/person.tscn` — `Person` root + `Body` (`y_bot.tscn`), `Collision`, `Brain` + 6 actions, `Stats`, `Readout`, `Inventory`. Base for the inherited scene.
- `assets/mixamo/mixamo_import.gd` — the clip-name table. Locomotion names available: `idle`, `walk`, `run`, `jump`, `jump_down`, `run_jump`.
- `workbench/tutorial_character.gd` — reference only, and **buggy**: double jump-thrust, compounding `velocity = twist_pivot.basis * velocity`, per-tick `move_toward`, per-tick `print`. Re-derive, do not copy.
- `project.godot` — `[input]` has `move_left/right/up/down` and `ui_jump`. No sprint.

## Tasks & Acceptance

**Execution:**
- [ ] `project.godot` — add a `sprint` input action bound to Shift — nothing else in this file changes.
- [ ] `workbench/exchanges/follow_camera.tscn` + `.gd` — `TwistPivot/PitchPivot/Camera3D`, mouse-look with clamped pitch, capture/release/recapture. Its own scene so the person scene stays camera-free and the NPC instances it unchanged. Fix all four tutorial bugs.
- [ ] `workbench/exchanges/exchange_brain.gd` — `extends PlayerBrain`. Adds `_physics_process`: gravity, camera-relative direction, walk/sprint speed, one-shot jump, `move_and_slide`. Overrides `_walk_where_he_is_pointed()` to a documented no-op so movement keeps exactly one writer if a `Population` is ever wired above it.
- [ ] `workbench/exchanges/person_with_exchange.gd` — `extends Person`. Overrides `_show_the_body()` to pick from six locomotion clips off real `velocity` and `is_on_floor()`. Exported speed thresholds.
- [ ] `workbench/exchanges/person_with_exchange.tscn` — inherits `game/person.tscn`, swaps root script; `Brain` keeps `player_brain`'s slot but takes `exchange_brain.gd`.
- [ ] `workbench/exchanges/exchanges.tscn` — ground **with a StaticBody3D collider** (`game.tscn`'s ground has none; `move_and_slide` needs a floor), light, sky, player instance + `follow_camera` under it, one mannequin NPC. Header comment explaining the eight expected warnings.

**Acceptance Criteria:**
- Given `game/` is untouched, when the probe runs, then it reports the standing **63 claims / 14894 checks, all green**.
- Given the scene runs, when the editor import pass runs, then it parses with no errors and only the eight expected `push_warning`s.
- Given the player is airborne, when `ui_jump` is held down, then he does not gain further height.
- Given the player runs a full circle, when the camera is rotated, then movement stays camera-relative and the body faces its direction of travel.
- Given no `Population` exists above either body, when the scene runs, then both still render, animate and (for the player) move.

## Design Notes

**Two divergences from `game/`, and both are the point.**

1. **Clips come off physics `velocity`, not measured displacement.** `game/` measures `_speed` as displacement over world hours inside `Person.think_and_act` — which `Population` drives. With no `Population` here, `_speed` is permanently `0.0` and the inherited `_show_the_body()` would idle at a dead sprint. The override reads `velocity` instead. Integration-back question this poses: whether `game/` should measure the same way.

2. **Movement is in `_physics_process(delta)`, not `think_and_act(hours)`.** This is the experiment's actual subject. It buys gravity, airborne state and jump; it costs the guarantee that dragging `day_length_seconds` cannot change how fast the player walks relative to NPCs. `game/` deliberately made the other trade (Decision 4). Do not "fix" this back — watch it.

`jump`, `jump_down` and `run_jump` import as `LOOP_NONE`, so a long fall plays its clip once and holds the last pose. Acceptable for a first watch; note it, do not build a blend tree for it.

## Verification

**Commands:**
```
GODOT="/z/Godot/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe"
"$GODOT" --headless --path tkyds-game --editor --quit
"$GODOT" --headless --path tkyds-game --script game/probe.gd
```
- Import pass — expected: parses clean; no error on any new file.
- Probe — expected: **63 claims, 14894 checks, all green.** `game/` is untouched, so any movement here is a regression this spec caused.

**Manual checks:**
- Run `workbench/exchanges/exchanges.tscn` directly (do **not** change `run/main_scene`). Walk, sprint, jump, spin the camera, run off nothing. The Moment is: it feels like a body worth standing next to somebody with.
