# The King You Don't See — POC v2

A deliberate restart. The previous build grew into a full economy simulation
(markets, books, activities, interests, ~60 scripts) plus a large planning
trove. This branch throws that out and rebuilds from the smallest playable
loop, re-derived from the **health-triangle seed** (reciprocal combat across
physical / social / emotional axes).

## Where the old work went (nothing was deleted)

The complete pre-restart state is archived and 100% recoverable:

| Ref | Type | Points at |
| --- | --- | --- |
| `archive/economy-sim-v1` | tag | full economy-sim + bar_fight prototype + all planning docs |
| `archive/economy-sim` | branch | same snapshot (easy to check out) |
| `prototype-phase-2.5/feature` | branch | original working branch, unchanged |

Recover anything with e.g. `git checkout archive/economy-sim -- <path>`.

## What's here now

- `tkyds-game/` — a bare Godot 4.4 project: one empty `main.tscn`, no
  autoloads, no economy. The starting point, not the destination.
- `_bmad/` — BMad agent framework (kept, so the game-dev agents still work).

Everything else starts fresh.
