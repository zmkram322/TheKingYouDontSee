# The body layer — what putting a real rig on every person found

**Written 2026-08-21**, covering commits `87eb3bf` (the raw Mixamo assets) and
`662044b` (the seam). Verified independently after the fact: parse pass clean,
**probe 64 claims / 14898 checks, all green**, anchor unmoved.

**This file exists because that work landed with its findings in a git commit
message and nowhere else** — which is the one place this project does not look.
Nothing here is new work; it is the commit message's substance re-stated where a
builder will actually find it, plus what independent verification added.

---

## Part 0 — What the seam is, in one line

**What a person's body is doing, and where that answer comes from.** One seam,
as this project builds them: the capsule became a rig, and exactly one new
question got a home.

---

## Part 1 — Two layers, and moving wins

A person's clip comes from exactly two places, and the precedence between them
is the whole design:

| Layer | Source | Unit |
|---|---|---|
| **Travel** | *measured displacement* across the brain's tick, against his own `get_travel_speed()` | world hours |
| **Everything else** | a clip name authored on the `ActionStep`, beside `exertion` | — |

**Travel wins.** That is what lets `sleep.tscn` declare `sleep` unconditionally
and still show a man *walking to his bed* — the measurement overrides the
declaration until he has arrived, so nothing in `sleep.tscn` says one word about
walking. Sleep needing no line about locomotion is the test that this layering
is right rather than merely convenient.

**Displacement, never velocity — and this is not a preference.** Nothing in the
game *sets* velocity. `PlayerBrain` and `GoToStep` both integrate
`global_position` by hand, because Decision 4 forbids `move_and_slide` (measured:
non-uniform under `_process`, and silently zero under `PROCESS_MODE_DISABLED`).
Reading `velocity` would have read zero forever, on every body, and looked like
an animation bug.

**The clip sits on the step, not the action, for exactly `exertion`'s reason:**
in walk-there-then-dig, only the step knows which half is happening.

**Where this layer would lie:** a body moved for a reason that is not walking — a
cart, a carried man, an author teleporting someone. It would show walking legs.
Nothing does that yet; when something does, this is the paragraph to re-read.

---

## Part 2 — The rule this seam was the first real test of

**No file in `game/` maps an action to an animation.** A dictionary from action
to clip is code naming verbs, forbidden on the same footing as `verb_list`
naming one (Decision 33). Every clip is authored in the action's own `.tscn`:

```
eat.tscn            clip = &"drink"
make_bread.tscn     clip = &"work_field"
sleep.tscn          clip = &"sleep"
socialise.tscn      clip = &"greet"
wake.tscn           clip = &"stand_up"
work_for_hire.tscn  clip = &"work_field"
work_the_field.tscn clip = &"work_field"
```

Presentation was the obvious place for that rule to break — it is where you most
want a lookup table — and it held. Empty means "nothing to say" and he rests,
which is the honest default: an action nobody has drawn yet should look like a
man standing there, not like a man doing something else.

**Choosing the clip runs in `_process`, not `think_and_act`.** Presentation
redraws as often as it is looked at, not as often as the world is stepped. Fold
it into the tick and the day `Population` thinks for a man every fourth frame,
his legs stutter between thoughts. That one function per person per frame is
also **the seam where a visibility test installs** when three people become
thirty — `_animation.active = false` and every clip behind it goes quiet.
Deliberately not built: culling three people is substrate before anything needs
it.

---

## Part 3 — The swap that could have cost the town its dawn race

**The rig REPLACED the capsule at index 0 rather than being added beside it.**
That is what kept `Stats` at 3 and `Inventory` at 5.

`game.tscn` overrides both **by index**. A node inserted above `Stats` would have
silently dropped Hobb's 1.15 strength — and the dawn race between two farmers for
one plot, which claims 12 and 13 both turn on, would have become a coin flip.
Not an error; a *quiet* re-tuning of the town.

**The probe caught this by not moving:**

```
cold start: turned in 21:14, up 05:52
settled:    turns in 22:10, sleeps 8.00 h, up 06:10
strong man (1.15): up 04:47
```

`04:47` now guards **node order** as well as strength. If it ever moves, look at
`person.tscn`'s node order before you look at the arithmetic. This is recorded in
`CLAUDE.md`'s Verifying section.

`tint` also stopped naming one mesh and now finds every `MeshInstance3D` the rig
wears — Y Bot wears two, a later rig will wear some other number, and none of
them are spelled out.

---

## Part 4 — Four Mixamo traps, answered in one place

`assets/mixamo/mixamo_import.gd` is an `EditorScenePostImport` running on every
reimport. Mixamo hands over four problems and this is the only place they are
answered:

1. **Every clip is named `mixamo_com`** (Godot sanitises Mixamo's "mixamo.com").
2. **Every file carries a second, motionless clip, `Take 001`.**
3. **Loop mode always imports as `none`**, so an idle hitches once per cycle.
4. **Nobody ticked "In Place."** Walking dragged the Hips **1.77 m per cycle**,
   straight off the `CharacterBody3D` the brain is steering. `holds_position`
   strips horizontal Hips travel and stands in for the checkbox.

> ### ⚠ The trap that will waste an afternoon
>
> **Godot tracks `import_script/path` but NOT the script's *contents*.** Editing
> the clip table does not invalidate the import cache, so a reimport is a
> **silent no-op** — the files look reimported and nothing changed. The forcing
> command is recorded in the file:
>
> ```
> sed -i '/^uid=/d; /^path=/d; /^dest_files=/d; /^importer_version=/d' assets/mixamo/*.fbx.import
> ```
>
> then the editor import pass, then `build_character.gd`.

A companion trap, also handled: **deleting a `.fbx.import` makes Godot regenerate
it with defaults** — plain scene, no import script — so the clip silently keeps
its raw `mixamo_com` name and the merged library quietly grows a stranger.
`build_character.gd` names any `.fbx` whose `.import` has drifted off the script,
rather than letting it pass.

**Every `.fbx` arrived With Skin**, so each carries a redundant copy of the mesh.
They import as Animation Libraries, which discards it. The cost is repo weight
only — but it is ~60 MB of it.

**`y_bot.tscn` is written as text, not packed.** `PackedScene.pack()` on an
instantiated rig serialises the whole mesh inline: a ten-megabyte scene that
churns in git on every rebuild. An inherited scene referencing the `.fbx` is a
few hundred bytes and stays correct when the import is redone.

The rig carries **its own 180° turn** — Mixamo faces +Z, Godot forward is -Z — so
nothing in `game/` has to know that, and `look_at()` works downstream.

---

## Part 5 — The measurement that caught a mislabelled download

`report_clips.gd` measures per-clip root drift **and total yaw**. That second
column is the one that earned its keep:

- **`Running.fbx` was a 195-degree turn, not a run.** Caught by yaw, not by eye.
  Re-downloaded — the file changed size in `662044b`, which is the fix landing.
- **`Sitting Drinking` is still wrong by the same measure** — 15.2 s and 167
  degrees, a compound clip. **It wants re-downloading, not fixing here.** It is
  wired as `sit_drink` and nothing plays it yet, so it costs nothing today.

**The lesson generalises past Mixamo:** an asset that imports cleanly can still
be the wrong asset, and the cheap way to find out is to measure something about
it that a name cannot fake.

---

## Part 6 — Probe: 63 → 64 claims, 14894 → 14898 checks

**Claim 67** — *a man's body shows the work his step declares, and walking legs
whenever he covers ground.*

Two things about how it is written are worth copying:

1. **It asks the repertoire for whatever action declares a clip, rather than
   naming one.** So it cannot start testing a verb somebody deleted — the same
   discipline `verb_list` follows, applied to a test.
2. **It asserts the work clip DIFFERS from the resting clip.** Without that
   second half it would have passed for a body that ignored every step and
   idled through the entire day — the exact vacuous shape `CLAUDE.md` warns
   about: *a claim about a rule with no branch must be asserted in the state the
   missing branch would have changed.*

---

## Part 7 — Still open

1. **The Gate 1 Moment is STILL not watched.** Unchanged and now more urgent:
   this work makes the watch *worth more*, it does not substitute for it. The
   watch list is Part 5 of `gate-1-findings-2026-08-20.md`.
2. **`Sitting Drinking` wants re-downloading** (Part 5).
3. **The clip vocabulary is deliberately ahead of the action vocabulary.**
   Twenty-two clips are imported; seven are played. `beckon`, `hand_over`,
   `greet_warm`, `sit`, `sit_drink` are staged for gates that do not exist yet —
   which is fine for *art*, and would not be fine for code. Worth stating
   because it looks like dead weight and isn't.
4. **`run`, `stand_up` and the three jump clips are wired and nothing triggers
   them.** No locomotion state above walking exists.
5. **NPCs start awake at midnight and so stand idle at the town's first
   instant.** That is the body telling the truth, not a bug. Starting them
   asleep is an authoring change to `game.tscn` that **would move the cold-start
   anchor** — so it is the author's call, not a builder's.
6. **`build_character.gd`'s header says "21 per-file libraries"; the table holds
   22.** Stale by one, harmless, noted so the next reader doesn't go hunting for
   a missing clip.
7. **The animation work was done in a Godot 4.4 editor** while the probe verifies
   under 4.7.2. Consistent with `project.godot` still declaring
   `config/features=("4.4", ...)` — which remains the author's call to bump, now
   with import data riding on it.
