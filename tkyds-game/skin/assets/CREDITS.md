# Asset Credits — Village Scene Skin

Assets sourced 2026-08-04/05 for a Godot 4.4 stylized low-poly village scene
(Synty/Quaternius idiom). Single source (Quaternius) used throughout for
stylistic coherence. Trimmed 2026-08-04 to exactly what the scene ships — see
git history for the fuller staged set this was trimmed down from.

| Asset | Source | Author | Licence | Local path |
|---|---|---|---|---|
| Worker_Male (rigged, animated character — Tam, Ivo, Cade, Osric) | quaternius.com "Ultimate Animated Character" pack, via the pack's public Google Drive folder linked from https://quaternius.com/packs/ultimatedanimatedcharacter.html | Quaternius | CC0 1.0 Universal | `quaternius-ultimate-animated-character/glTF/Worker_Male.gltf` |
| Worker_Female (rigged, animated character — Maren) | same pack/folder as above | Quaternius | CC0 1.0 Universal | `quaternius-ultimate-animated-character/glTF/Worker_Female.gltf` |
| Inn (building, at INN_AT) | quaternius.com "Medieval Village Pack" (Dec 2020), via public Google Drive folder linked from https://quaternius.com/packs/medievalvillage.html | Quaternius | CC0 1.0 Universal | `quaternius-medieval-village/Buildings/Inn.fbx` |
| Mill (building, at MILL_AT) | same pack/folder | Quaternius | CC0 1.0 Universal | `quaternius-medieval-village/Buildings/Mill.fbx` |
| House_1 (building, at HOME_AT) | same pack/folder | Quaternius | CC0 1.0 Universal | `quaternius-medieval-village/Buildings/House_1.fbx` |
| Barrel, Fence, Well (village dressing props) | same pack/folder, `Props/` subfolder | Quaternius | CC0 1.0 Universal | `quaternius-medieval-village/Props/Barrel.fbx`, `Fence.fbx`, `Well.fbx` |
| BedDouble (bed, at HOME_AT) | quaternius.com "Ultimate Furniture" pack, via public Google Drive folder linked from https://quaternius.com/packs/ultimatefurniture.html | Quaternius | CC0 1.0 Universal (per pack page; see note below on this one pack's missing local `License.txt`) | `quaternius-ultimate-furniture/BedDouble.fbx` |
| Wheat_1 (crop prop, at FIELD_AT) | quaternius.com "Ultimate Crops" pack, via public Google Drive folder linked from https://quaternius.com/packs/ultimatecrops.html | Quaternius | CC0 1.0 Universal | `quaternius-ultimate-crops/Wheat_1.fbx` |

## Notes on provenance / mechanics

- All assets are Quaternius packs, sourced from quaternius.com pack pages, each of
  which links to a Google Drive folder as the actual download host. Files were
  pulled directly from the public Drive folders, not through poly.pizza mirrors,
  so filenames/paths match the original pack structure.
- Kept **glTF** for the two characters (self-contained, embedded binary + flat-color
  materials, no external texture files) and **FBX** for everything else (buildings,
  props, furniture, the crop) — no glTF option was offered for those packs; FBX is
  the explicitly-approved fallback and Godot 4.4 imports it natively via ufbx.
- Each pack's own `License.txt` (verbatim CC0 1.0 grant text from Quaternius) is
  kept alongside the assets in its folder as a durable license record, EXCEPT the
  Ultimate Furniture pack: its staged download did not include a `License.txt` of
  its own. Its CC0 licensing is asserted the same way the original staging pass
  recorded it — from the pack's own quaternius.com page — but there is no local
  license file to point to for BedDouble specifically. Flagged here rather than
  silently assumed.

## What didn't ship (trimmed from the original staged set)

Pulled into `asset_staging/` for consideration during world-building but not used
by this scene, so deleted rather than carried into the project unused: House_2/3/4,
Blacksmith, Stable, Bell_Tower (unused buildings — one house and the two named
workplaces were enough for five residents); Bench_1, Cart, Crate, Door_Straight,
Hay, MarketStand_1, Path_Straight, Rock_1, Window_1 (unused props — Barrel/Fence/
Well were kept as the "sparingly" dressing the brief asked for); Wheat_Crop.fbx
(the second crop variant — Wheat_1 alone fills the field).

## Gaps against the "minimum set" brief (carried over, still true)

- **Ground plane texture/tile**: not sourced (see original staging investigation
  — asset hosts gated behind client-side JS / account flows weren't scriptable
  from here). Shipped as a flat-color `StandardMaterial3D` on the ground plane
  instead — consistent with the flat-shaded look used throughout this set.
- **Trees / bushes**: not sourced; not needed — the field, mill, inn, and one
  house are the whole village this scene draws.
- **Mixamo / Synty POLYGON**: not needed — the free CC0 Quaternius set covered
  everything this scene uses, clip set included.
