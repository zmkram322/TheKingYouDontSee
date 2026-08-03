# Behavior Sandbox — what it is

`behavior/` is generic decision-making machinery (a utility brain that scores
options and picks the best eligible one, an Orchestrator that owns each
actor's pause/resume stack, plus the State machinery that runs whatever gets
chosen — an actor is always running exactly one State, which may itself be a
SequenceState composed of smaller steps). `sandbox/` is one example world
built on top of it — four actions, four places, five villagers. The scene here
(`sandbox.tscn` + `sandbox.gd`) is just a skin over a headless `SandboxWorld`;
it draws places and bodies and reads `world.stats` /
`v.orchestrator.last_decision` back out, it never invents behavior of its
own.

## Run it

```
Z:/Godot/Godot_v4.4-stable_mono_win64/Godot_v4.4-stable_mono_win64_console.exe --path tkyds-game res://sandbox/sandbox.tscn
```

Headless smoke test (no scene, just the world logic):

```
Z:/Godot/Godot_v4.4-stable_mono_win64/Godot_v4.4-stable_mono_win64_console.exe --headless --path tkyds-game --script res://tests/sandbox_smoke.gd
```

## Add an action

Copy a stanza out of `sandbox/sandbox_catalog.gd` — every option is built
this way, so it reads as one paragraph: what it is, where it happens, what
makes it appealing, what gates it, what it does when it finishes.

```gdscript
options.append(
	ActionOption.make(&"rest_home", "resting at home", &"home", 2.5)
		.scored_by(func(store: StatStore, actor: Actor) -> float:
			var energy: float = store.get_primary(actor, Stat.ENERGY)
			return SandboxTune.W_REST * pow(1.0 - energy / SandboxTune.ENERGY_MAX, 2.0))
		.then(func(store: StatStore, actor: Actor) -> void:
			var energy: float = store.get_primary(actor, Stat.ENERGY)
			store.write_primary(actor, Stat.ENERGY, minf(SandboxTune.ENERGY_MAX, energy + SandboxTune.REST_RESTORES_ENERGY)))
)
```

`scored_by` (appeal) is the whole personality — that curve is the only place
"how much do I want this" lives. `only_if` (eligibility) is a data gate, not
a special case in the brain: unset means universally eligible, and only an
explicit gate rules an actor out. No other file needs to change.

## Add a stat

Name it in `sim/stats.gd` (that file is the whole vocabulary — keep it
greppable). Give it a default in `SandboxWorld.reset()` via
`stats.set_actor_default(...)`. Read it from any appeal or effect with
`store.get_primary(actor, Stat.YOUR_STAT)`. For a derived stat (computed from
other stats, like VIGOR), call `stats.define_derived(Stat.YOUR_STAT, fn)`
once in `reset()` and read it with `get_derived`; the cache invalidates
itself off whatever primaries the derivation actually touched, so you never
have to think about staleness.

## Add a new kind of state

Subclass `State` (see `sandbox/walk_to.gd` or `sandbox/perform.gd` for the
shape): override `begin()`, `advance(delta)`, `finished`, and `describe()`
(the label the skin prints over the actor's head). Add it to the `steps`
array `SandboxWorld.build_goal()` builds, alongside `WalkTo`/`Perform`. If an
option ever needs more than a couple of steps, or a step that itself needs
to sequence sub-steps, nest a `SequenceState` inside another — that's the one
composite in the hierarchy and it costs nothing to nest.

## Where the seams are

- Rescoring only happens between goals — a decision sticks until its root
  State finishes. If flicker ever shows up, the fix is hysteresis added
  as data (an appeal-curve tweak in `sandbox_tuning.gd`), never a priority
  gate bolted onto the brain.
- Walking writes the `PLACE` stat on arrival, so position stays a fact any
  appeal or gate can read — the body's motion through space is pure skin,
  not the thing eligibility checks against.
- The brain records every option it considered, eligible or not, with its
  score — that's why the inspector can show "why" for any decision instead
  of just the outcome.
