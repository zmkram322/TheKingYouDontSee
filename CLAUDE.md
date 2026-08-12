# The King You Don't See — working notes

Godot 4.4 project in `tkyds-game/`. Solo dev. Built atom by atom: smallest
playable thing first, layer on top of it, resist building substrate before
something needs it.

## Where things live

| Folder | What |
|---|---|
| `game/` | **The build.** Substrate: `person`, `stats`, `brain`, `action`, `action_step`, `decision_engine`, `clock`, `daylight`, `population`, `place`, `town`, `workstation`, `inventory`. |
| `game/actions/` | The action library. One scene per action, instanced under a person's Brain. |
| `game/ui/` | Watching and tuning. `stat_graph` plots a person's stats over time; `tuning_board` puts a slider on every exported number of whatever nodes you point it at. Both are their own scenes, both need a `CanvasLayer` parent in a 3D scene, both discover what to show by reflection so neither needs a line per stat or per knob. |
| `assets/` | Art. `quaternius/` is 3D, `tiny_town`/`tiny_dungeon` are 2D. |
| `_bmad-output/planning-artifacts/prd.md` | The requirements contract. FR numbers are stable identifiers. |
| `_bmad-output/proving-scene-build-plan.md` | The current build ladder — **fifteen gates** from one Zoog to a thirteen-person town. Read before adding to `game/`. |
| `_bmad-output/proving-scene-decisions.md` | **Read with the plan.** Nine questions settled 2026-08-09, each with the reasoning. Wins where it and the plan disagree. Three of them look like violations of the rules below until you read why they aren't. |

`tkyds-game/` is now **`game/` and `assets/` and nothing else.** `brain/`,
`world/` and `skin/` were retired 2026-08-05; `board/`, `town/`, `sandbox/`,
`sim/`, `behavior/`, `tests/` and the old `main.tscn` followed on **2026-08-08**,
deleted outright to free their `class_name`s — see below. All of it is in git
history if you need to read how something worked; port ideas by hand, never
wire to them.

**`class_name` is project-global, and 23 good names were being squatted on.**
Freed by that deletion, and now available: `Goal`, `Demand`, `Actor`, `State`,
`Wait`, `Simulation`, `Villager`, `TownMap`, `Hex`, `HexMap`, `Orchestrator`,
`UtilityBrain`, `ActionOption`, `SequenceState`, `Perform`, `Stat`, `StatStore`,
`Tune`, `TerrainGenerator`, `Settlement*`, `Sandbox*`. `Goal` and `Demand`
especially — both are words the PRD uses constantly and both were unavailable.

## Naming

Four rules, non-negotiable — a rename pass was already spent getting here.

1. **Methods are verbs or questions.** Never bare nouns. `get_text()`, not `reading()`.
2. **Booleans read as questions.** `is_`, `can_`, `has_`.
3. **Arguments are named for what they ARE, not the role they play.** `person`, not `who`. `stat_name`, not `what`. Never `from`, `it`, `obj`.
4. **If a name hides what the thing does, rename it.** `wants()` hiding a utility score was the case that triggered this list.

Plain English over CS vocabulary. `describe_current_action()`, not `dispatch()`
or `transition_to()`. When a domain term is genuinely the clearest word
(`utility score`), use it and explain it in a comment.

## Design rules that are load-bearing

Each of these is cheap to follow now and expensive to retrofit.

**Store nothing you can work out again.** No `finished` flags, no elapsed
timers, no "which child am I on". "Am I at the inn?" is answered by where he's
standing. This is why interrupting costs nothing — nothing was suspended, so
nothing needs restoring. The brain re-decides every single tick.

**All stat access goes through `get_stat` / `set_stat`.** Never touch the
`@export` field from outside `stats.gd`. That accessor is the one wall that
lets storage graduate (Dictionary → packed array → native) without rewriting
call sites. The PRD names it the load-bearing architectural wall.

**Goods go through `Inventory`'s three doors, and they mean different things.**
`get_count` is the same wall as `get_stat`, for the same reason — nothing
outside `inventory.gd` touches `items`. Above that: **`add` creates, `take`
destroys, `hand_over` moves.** A world total may change only where `add` or
`take` is called, which is what makes a conservation check mean anything, and
`hand_over` is the ONE transfer path — a second one is a second place for a
half-completed transfer to hide. `hand_over` is take-then-add: both halves or
neither.

**Upkeep goes in `Brain._update_body`. Effects go in the action.** Two
different things:

- *Happens to you regardless of what you chose* — adenosine rising, hunger
  rising, a wound bleeding, fear fading. One place: `_update_body`.
- *Happens because of what you chose* — eating drops hunger, walking moves you,
  grinding makes flour. That's the action's whole job; it belongs there.

Only the first is the rule. Put upkeep inside an action and the next action you
write silently doesn't have it — you get a farmhand who works forever and never
sleeps, which reads as a balance problem and takes an hour to trace. Grep
`game/actions/` for `adenosine`; it should return nothing.

**Node vs shared file:** different for every person → **Node** (stats, brain,
what he's doing). Same for everyone → **shared scene/resource** (what "sleep"
means). Never store one person's progress on a shared action.

**Nothing outside `Clock` interprets a real-time delta.** `Clock` owns the one
conversion from real seconds to world time; **every rate in `game/` is per world
hour**, and every argument carrying one is named `hours`, not `delta`. Two
clocks running in different units is a live bug this project already has:
`base_adenosine_per_second` is per real second while `Clock` divides by
`day_length_seconds`, which is a slider — so dragging it desynchronises the body
from the sun and the failure looks like a tuning problem. Rung 0 fixes it.

**A stored `Person` reference is read through `is_instance_valid()`, always.**
`queue_free()` does not null your reference — `== null` stays false and the next
property read errors. Anything holding a person (a workstation's claimant, an
obligation's issuer, a trade candidate) must check, or "delete somebody mid-run"
produces a stack trace instead of a verdict.

**Gate with `is_available_to`, never by adding or removing nodes.** Three
different questions, three mechanisms:
- what exists in the game → the `game/actions/` library
- what this person knows → the Action nodes under his Brain, via `Brain.learn()` / `Brain.forget()`
- what he can do *right now* → `is_available_to`, asked every tick

**Learning and forgetting are first-class**, not housekeeping. Growing reach
unlocking new actions is the shape of progression, and what someone can do at
all is most of what makes them a different person. It's just not a per-tick
operation, which is why the known list is cached.

**Every gate is asked. There is no override.** The rule that nobody can be made
unable to eat or run away is kept by **composition** — those actions are in
every person scene — not by a flag that discards a gate an author wrote. A flag
like that means someone writes a gate and it silently does nothing, which is a
worse trap than the one it guards. (This intentionally departs from the PRD's
FR86, which specifies an explicit protected mark.)

**Action = why, ActionStep = what.** An Action is choosable (gated, scored). Its
ActionStep does the work. Keeping them apart is what lets a decision nest
inside an action ("go eat" → "…at which inn?"). `Sequence` and `Choice` are not
ported yet; port them from git history when something needs them.

## Godot gotchas already hit here

- **A node reference in a hand-written `.tscn` needs `node_paths` on the node header**, or it silently loads as `null`:
  ```
  [node name="Daylight" type="DirectionalLight3D" parent="." node_paths=PackedStringArray("clock", "environment")]
  clock = NodePath("../Clock")
  ```
  The editor writes that for you; writing the file by hand does not. This shipped a day/night cycle that never ran for two atoms. **Corollary: never guard a missing wire with a silent `return`.** Warn in `_ready` if a required reference is null — otherwise a broken link is indistinguishable from "nothing is happening yet", and "it runs without errors" stops meaning anything.
- **`@export var x: Array[Node]` does not resolve its paths at all**, even with `node_paths`. Use `Array[NodePath]` and `get_node_or_null()`.
- **`class_name` is project-global.** A name used anywhere in the project is taken everywhere. Check before naming.
- **Ternaries infer `Variant`** when the branches are different types — `String` and `StringName` will fail the build under warnings-as-errors. Annotate the variable.
- **`var x = something_returning_Variant`** fails the same way. Write `var x: Variant = ...` or the concrete type.
- Resources are shared by reference. That's a footgun for per-person state and exactly what you want for shared definitions.

## Verifying

There is no test suite for `game/` — headless suites were retired along with
the folders they covered. To check something works, pump it directly:

```bash
"/z/Godot/Godot_v4.4-stable_mono_win64/Godot_v4.4-stable_mono_win64_console.exe" \
  --headless --path . --editor --quit          # parse + import check
```

Then a throwaway `SceneTree` script calling `person._process(fixed_delta)` in a
loop, printing what you care about. Delete it after.
