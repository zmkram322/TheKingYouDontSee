# The King You Don't See — working notes

Godot **4.7.2-stable-mono** project in `tkyds-game/`. Solo dev. Built atom by atom: smallest
playable thing first, layer on top of it, resist building substrate before
something needs it.

## Where things live

| Folder | What |
|---|---|
| `game/` | **The build.** Substrate: `person`, `stats`, `brain`, `action`, `action_step`, `decision_engine`, `clock`, `daylight`, `population`, `place`, `town`, `workstation`, `inventory`. `person` also owns the body layer — the rig, and the one function per person per frame that decides which clip it plays. Plus `player_brain` — the ONE fork in the whole substrate: a `Brain` whose winner comes from a hand instead of from a score, and whose `current_place` is written by input instead of by a step. `player.tscn` is an inherited scene, not a class; nothing downstream can tell his answers from an NPC's. |
| `game/actions/` | The action library. One scene per action, instanced under a person's Brain. |
| `game/ui/` | Watching and tuning. `stat_graph` plots a person's stats over time; `tuning_board` puts a slider on every exported number of whatever nodes you point it at; `verb_list` draws the player's open ballot and reports what he clicked. All three are their own scenes, all three need a `CanvasLayer` parent in a 3D scene, and all three discover what to show by reflection so none needs a line per stat, per knob or **per verb** — `verb_list` naming a verb is a failed build, on the same footing as code naming a playstyle. |
| `assets/` | Art. `quaternius/` is 3D, `tiny_town`/`tiny_dungeon` are 2D. `mixamo/` is the people: `y_bot.tscn` (the rig every person wears, carrying its own 180° turn because Mixamo faces +Z and Godot forward is -Z) plus `y_bot_animations.res`. Its four `.gd` files are **editor tooling, not game code** — `mixamo_import.gd` is the one place four Mixamo import traps are answered, `report_clips.gd` measures per-clip root drift and total yaw, `build_character.gd` rebuilds the rig and names any `.fbx` whose `.import` has drifted off the script, `clip_viewer.gd` eyeballs one clip. |
| `_bmad-output/planning-artifacts/prd.md` | The requirements contract. FR numbers are stable identifiers. |
| **The four "why" docs** | **What the game is FOR.** The plans say what to build; these say why any of it is worth building, and they are the thing to re-read when the work starts feeling like bookkeeping. `design-positioning-and-comparables.md` — the spine (*illegible authorship*: the gap between what the world attributes to you and what you authored), power defined as *how many people fall under the shadow of your decisions*, and what CK3/Dishonored/Mordor each prove or warn about. `design-multipath-routes-framework.md` — paths are distinct by **what breaks and who fights you**, never by what you watch; **no code may name a playstyle**. `poc-v2-system-spirit.md` — the ten tenets, incl. **no hard-fail states** and *legibility is a design constraint, not a nicety*. `design-session-2026-07-24-social-political-layer.md` — greeting rungs, LOOK held separate from GREET, and *you are a perfect reader of a deliberately foggy world.* |
| `_bmad-output/boss-scene-build-plan.md` | **THE FORWARD LADDER — start here.** Eleven gates, cut from the player's seat: you walk the town, greet, beckon, give, and tell people what to do, **and they can refuse.** Read before adding to `game/`. |
| `_bmad-output/proving-scene-build-plan.md` | **The record of the shipped substrate**, not the forward plan (superseded 2026-08-19, Decision 33). Rungs 0–6 shipped and every seam in them stands; read it for *why* `game/` is shaped the way it is. Its rungs 7–9 are re-seated as the boss ladder's Gate 10+. |
| `_bmad-output/proving-scene-decisions.md` | **The authority. Read with whichever plan you are building from.** **Thirty-nine** questions settled, each with the reasoning, indexed at the top of the file. Wins where it and a plan disagree, and the **highest number wins** within it. Three of them look like violations of the rules below until you read why they aren't. **19–27 settle how wanting works at all** — every want is a gap, `want = weight × gap^bite`, gates ask the world and never how much he wants it, failure marks the candidate. **28: Socialise's candidates are venues (`Place.is_gathering_place`), not crowds.** **33 (2026-08-19) re-seats the whole ladder in the player's seat** — a command is a *bid*, not an override; the player's verb menu is `get_available()` drawn instead of scored; and no code may name a verb. **35 (2026-08-20) is the one that will surprise you: since 30 made freeness public, NOT ONE gate in the game reads where a man is standing, so no verb can be revealed by arriving anywhere** — a ballot turns on what he carries and what the town has done. Read 19–27, 33 and 35 before writing any new Action. **36–38 (2026-08-28) are the first sections that rule on code which does NOT exist**, settled ahead of it because everything layers on top: **36** — a `Condition` is the one shape a modifier takes; intensity is a stat and the condition is the translation, so conditions attach by composition and are inert at zero; **a factor of 0 is a gate and is forbidden**, and no condition may read another. **37** — pressure is APPLIED, never transmitted: a lord's gap drives his own ballot, so an unmet need sets *how often he shows up*, not a number on anybody else. **38** — a quota breaks the man who does the work and is safe on the man who directs it. **39 (2026-08-29) is the opposite kind of section — the code already does it, and what is settled is that an optimisation is OFF THE TABLE: there are NO coarse ticks.** A distant region runs unbounded by the frame rate, never at bigger `hours`; `probe.gd` is already that execution model, and spreading people across frames is out entirely because it breaks the serial loop. |
| `_bmad-output/*-findings-*.md` | **What each session FOUND, as opposed to what it was told to build.** One per landed piece of work, and the place a builder's discoveries go so they are not left in a git commit message. `gate-0-` and `gate-1-findings-2026-08-20.md` — the two boss-ladder gates so far; Gate 1's carries **the watch list, and the standing note that its Moment has NOT been watched.** `body-and-animation-findings-2026-08-21.md` — the Mixamo body layer: the two-layer rule, the index-0 swap that guards Hobb's dawn race, and **four Mixamo import traps including a reimport that is a silent no-op.** `rimworld-comparison-findings-2026-08-28.md` — the study that produced Decisions 36–38: where RimWorld's extensibility actually comes from (few primitives, many instances; **no modifier reads another**), the two corrections it forced to claims already on record, and **a new species of vacuous assertion — a seam check that passed for a week while asserting the opposite of what the design wanted.** Breaking the code would have made it fail correctly, so the standing discipline could never have caught it. |

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

**Upkeep goes in `Brain.run_upkeep`. Effects go in the action.** Two
different things:

- *Happens to you regardless of what you chose* — adenosine rising, hunger
  rising, a wound bleeding, fear fading. One place: `run_upkeep`.
  **It is PUBLIC, and anything that holds a man out of `Population`'s loop must
  call `Person.run_upkeep` rather than passing him over** — skipping him skips
  the tail of `think_and_act`, which stops his hunger, his tiredness and his
  loneliness while the man beside him gets all three. A conversation was once a
  free night's rest for exactly this reason.
- *Happens because of what you chose* — eating drops hunger, walking moves you,
  grinding makes flour. That's the action's whole job; it belongs there.

Only the first is the rule. Put upkeep inside an action and the next action you
write silently doesn't have it — you get a farmhand who works forever and never
sleeps, which reads as a balance problem and takes an hour to trace. Grep
`game/actions/` for `adenosine`; it should return nothing.

**Every question a decision asks goes through one named accessor over the single
copy of the truth.** Never a maintained index, never an Action reaching past the
accessor into the tree. `Town.find_people_at` loops the people and asks each one
where he is, rather than Places keeping occupancy lists — so there is exactly one
copy of "where Zoogs is" and one copy cannot contradict another. Same wall as
`get_stat` and `get_count`, and for the same reason: **the day it needs to be an
index, that function body changes and no caller moves.** It is roughly one
pointer comparison per person per call and stops being free somewhere in the low
hundreds of people, which is two orders of magnitude away. Do not pre-build the
index; do not let a second copy exist.

**Node vs shared file:** different for every person → **Node** (stats, brain,
what he's doing). Same for everyone → **shared scene/resource** (what "sleep"
means). Never store one person's progress on a shared action.

**The body is two layers, and moving wins.** What a person looks like comes from
exactly two places: **travel**, answered by *measured displacement* over the
brain's tick in world hours against his own travel speed; and **everything
else**, a clip name authored on the `ActionStep` beside `exertion`, for the same
reason `exertion` lives there — in walk-there-then-dig only the step knows which
half is happening. Travel wins over the declared clip, which is what lets
`sleep.tscn` say `sleep` unconditionally and still show a man walking to his bed
without one word about walking in it. **No file in `game/` maps an action to an
animation** — a dictionary from action to clip is code naming verbs, forbidden
on the same footing as `verb_list` naming one. Displacement rather than velocity
because *nothing sets velocity*: `PlayerBrain` and `GoToStep` both integrate
`global_position` by hand (Decision 4 forbids `move_and_slide`). The one thing
this would lie about is a body moved for a reason that is not walking — a cart,
a carried man, an author teleporting someone. Nothing does that yet.

**Choosing a clip runs in `_process`, not `think_and_act`.** Presentation
redraws as often as it is *looked at*, not as often as the world is stepped —
the same split the readout answers to. Fold it back into the tick and the day
`Population` thinks for a man every fourth frame, his legs stutter between
thoughts. That function is also the seam where a visibility test installs when
three people become thirty; deliberately not built.

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

**The engine moved to 4.7.2 on 2026-08-20.** Verified that day against the
then-current probe: identical numbers under 4.4 and 4.7.2 — same 14747 checks,
same bedtimes to the minute. The bump changed no behaviour. Two things are still
stale and are the author's call to bump rather than a builder's: `project.godot`
still declares `config/features=PackedStringArray("4.4", ...)`, and
`game/probe.gd`'s own header still prints the 4.4 run lines.

**The standing count, after the accumulator: 65 claims, 14906 checks, all green.**
The anchor every measurement is taken against, unmoved by Gate 0, by Gate 1, or
by putting a real rig on every person:

```
cold start: turned in 21:14, up 05:52
settled:    turns in 22:10, sleeps 8.00 h, up 06:10
strong man (1.15): up 04:47
```

**That last line now guards node ORDER as well as strength.** `game.tscn`
overrides Stats and Inventory *by index*, so anything inserted above them in
`person.tscn` silently drops Hobb's 1.15 and turns the dawn race back into a
coin flip. The rig REPLACED the capsule at index 0 rather than being added
beside it, for exactly this reason. If `04:47` ever moves, look at the node
order before you look at the arithmetic.

**Do not run the probe from the repo root.** `--path .` outside `tkyds-game/`
finds no project, does nothing, and exits 0 — a silent false green that looks
exactly like a clean pass. Pass the project path explicitly.

There is no test suite for `game/`, and there is no framework — no GUT, no
GdUnit, no fixtures, no runner. What there is instead is **`game/probe.gd`, a
standing `SceneTree` that loads the real `game.tscn`, pumps the real people by
hand, and says PASS or FAIL out loud.** It is the thing to add to, and it is
why "it runs without errors" is not accepted here as evidence — a silent null
guard once shipped a dead day/night cycle through two commits and nothing
complained.

**Run it with TWO commands, always, in this order.** `--script` does not build
the global class cache, so without the import pass in front of it `class_name
Person` fails to resolve and the probe dies for a reason that has nothing to do
with whatever you changed:

```bash
GODOT="/z/Godot/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe"
"$GODOT" --headless --path . --editor --quit          # parse + import check
"$GODOT" --headless --path . --script game/probe.gd   # the claims
```

`ObjectDB instances were leaked at exit` and `resources still in use at exit`
are normal editor-quit noise; ignore both.

**A new claim is not finished until you have watched it fail.** Break the code
deliberately, see it go red, put it back. Eight vacuous assertions have been
caught here that way. The trap that keeps recurring: *a claim about a rule with
no branch must be asserted in the state the missing branch would have changed.*
