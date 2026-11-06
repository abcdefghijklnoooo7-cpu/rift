# Training Arena (workspace.RiftArena) - Functional Preservation Inventory

Read-only audit, 2026-11-06, Edit DataModel. Nothing was modified.
Sources read in full: ReplicatedStorage.RiftTraining (244 lines), ReplicatedStorage.RiftEnvironment, ServerScriptService.RiftTravel, ServerScriptService.RiftContainment, StarterPlayerScripts.RiftAmbience. Also read in full: ServerScriptService.RiftCombat (432 lines). Read in part: ServerScriptService.RiftMovement (lines 1-110) and RiftBallistics (TraceRange).
Backup restore source (verified, read-only): `ServerStorage.RiftBackup_2026-11-06_preStage7.Workspace_RiftArena`. It contains `Targets` with all 30 models and the `Spawn` attribute.

Server shot rules (RiftCombat:296-371): shots are cast from the shooter's Head with `RaycastParams` Exclude = {own character} only. No transparency, material or name pass-through exists, so **any CanQuery=true part blocks bullets**, including glass, railings and thin trims. Trace range is at least 1,200 studs for hitscan weapons. The camera-to-head segment is also validated (`cameraSegmentClear`), so solid geometry right at the firing position can reject shots. Decorative geometry in sight lines must be CanQuery=false. Grepped all scripts for `RiftArena`, `Training Arena`, `Training Target`, `GapClosure`.

## 0. Current contents
- `workspace.RiftArena` is a **Folder** with 1,530 direct children: 1,740 Parts, 30 Models, 30 Humanoids, 10 SurfaceGuis/TextLabels, 2 Sounds, 3 Folders. It has 0 Lights, 0 ProximityPrompts, 0 ClickDetectors, 0 Scripts and 0 ParticleEmitters at edit time.
- Of the 1,740 parts, 210 are target bots (30 x 7). The other 1,530 are loose, flat-parented environment parts. All of them are in CollisionGroup Default, and 821 have CanCollide/CanQuery on.
- Folder attributes: `Spawn = (0, 14, 110.7)`, `Aim = (0, 14, 0)`.

## 1. Hard dependencies (renaming or moving these breaks code)

| What | Exact requirement | Used by |
|---|---|---|
| `workspace.RiftArena` | Must exist with this exact name. Index-style access, so a missing folder errors at server start. A Folder is fine. | RiftTraining:7,194; RiftCombat:94,204,408,423; RiftTravel:11-12,33-34; RiftContainment:13,25; RiftItems:16; RiftAmbience:16 |
| `RiftArena` attribute `Spawn` (Vector3) | Training teleport destination and out-of-bounds fallback. Fallbacks if missing: `(0,14,82)` in RiftTravel, `(0,14,110)` in RiftContainment. **Keep it set.** If the spawn moves, update the value. | RiftTravel, RiftContainment |
| `RiftArena` attribute `Aim` (Vector3) | The spawn faces it via `CFrame.lookAt(Spawn, Aim)`. Currently `(0,14,0)`, which looks down-range (-Z). | RiftTravel |
| `RiftArena.Targets` (Folder) | Must be a **direct child**. All damageable NPCs must be **direct children** of it, because RiftCombat:94 rejects damage when `model.Parent ~= workspace.RiftArena.Targets`. Blast/recon/RiftItems also iterate it. RiftTraining parents runtime drill models into it. | RiftCombat, RiftTraining, RiftItems |
| `Targets["Training Target 1"]` | Must exist **when RiftTraining is required**: `assert(... 'Training Target 1 is required as the training mannequin template')`. It is cloned as the template for every drill target. If it is missing, the module errors and training breaks, along with RiftCombat (which requires Training). | RiftTraining:8-10 |
| `Targets["Training Target 1".."6"]` | Lane N's default mannequin is looked up by name `'Training Target '..lane` and hidden while a drill runs in that lane. Name format: exactly `Training Target <1-6>`. Index N must match lane N (see lane X table below). | RiftTraining:127 |
| Name substring `Training Target` | Damage rule for players on the Training Arena: `model.Name:find("Training Target")`. Any static bot without this substring (and without `TrainingOwner`) is invulnerable on this map. | RiftCombat:100 |
| Name substring `<MapName> Target` | Players on map X can only damage bots named `X Target ...`. That is why the other maps' bots also live in RiftArena.Targets (section 4). | RiftCombat:101 |
| `Drill console` x5 | Must be **direct children** of RiftArena (`RiftArena:GetChildren()` with `Name=='Drill console'`), must be **BaseParts** (`.Position` is read), and **exactly 5** are needed. Sorted by X ascending, they map to actions 1-5. The server checks the player is within **15 studs of `console.Position`**. The prompt is 12 studs. | RiftTraining:193-213 |
| `RiftArena.Audio` with `Ambience` and `Music` Sounds | Each Sound has a `Note` attribute. The SoundIds are empty now. RiftAmbience clones any Sound child with a non-empty SoundId. Keep the folder name `Audio`. | RiftAmbience |
| Walkable floors inside RiftArena | RiftContainment records "last safe" positions only when an 8-stud downward ray hits a **descendant of RiftArena**. Every walkable surface must be inside the RiftArena folder (any depth). | RiftContainment:31-32 |

`ReplicatedStorage.RiftEnvironment.Build()` is an empty stub (comment only). It builds nothing and needs no named parts.
`RiftMovement.addFeatures` has `"Training Arena"` pad/hazard offsets, but **it is never called** (dead code). No trampolines or hazards are spawned into the arena.
`GapClosureWalls` is not referenced by any script (grep shows 0 hits). It is purely geometric.

## 2. Containment volume (RiftContainment, hard-coded, not geometry)
A player on the Training Arena is snapped back to their last safe CFrame (or to Spawn) when any of these is true:
- `|X - 0| > 147`
- `Z < -257` or `Z > 151`
- `Y < 5` or `Y > 155`

All playable space must stay inside **X ±147, Z -257..151, Y 5..155**. The spawn must sit inside it. Geometry outside it is fine as unreachable backdrop, but players must not be able to reach it. If the rebuild needs a different footprint, update RiftContainment line 13/25, which belongs to another agent's script area, so coordinate first.

The existing invisible blockers (Transparency 1, CanCollide true) match this volume:
- `Map containment North`: (0, 80, -260), size 300x180x2
- `Map containment South`: (0, 80, 154), size 300x180x2
- `Map containment East`: (149, 80, -53), size 2x180x416
- `Map containment West`: (-149, 80, -53), size 2x180x416

Re-create equivalents. The names are not referenced by code.

## 3. Training range functional layout (RiftTraining hard-codes these coordinates)

### 3.1 Lanes
`lanes = {-110, -66, -22, 22, 66, 110}`. Lane N center X = lanes[N], with 44-stud spacing. Six lanes, one player each ("All six training lanes are in use").

| Lane | X | Default bot | Station number (SurfaceGui) |
|---|---|---|---|
| 1 | -110 | Training Target 1 | 01 |
| 2 | -66 | Training Target 2 | 02 |
| 3 | -22 | Training Target 3 | 03 |
| 4 | 22 | Training Target 4 | 04 |
| 5 | 66 | Training Target 5 | 05 |
| 6 | 110 | Training Target 6 | 06 |

### 3.2 Firing position (code teleports the player here on drill start)
`CFrame.lookAt((laneX, 14, -5), (laneX, 14, -90))`. The root is at Y 14, so the **floor top must be about Y 10** at the firing line (the current ground top is Y 10). The player looks toward -Z. There must be a clear, walkable floor at (laneX, 10, -5) with nothing solid at head height.

### 3.3 Target spawn depths (runtime drill targets: pivot Y = 12.65, feet on Y 10)
| Mode | Z | Distance from firing point (z=-5) | X placement |
|---|---|---|---|
| Stationary, Moving, Flick, Reaction, Switching, Timed | -45 | 40 studs | Moving: laneX + sin(t)*10 (±10). Flick/Reaction: laneX + random(-10,10). Switching/Timed: 3 bots at laneX-8, laneX, laneX+8 with Z = -50, -45, -50 (`z-(i%2)*5`) |
| Spray | -85 | 80 studs | laneX |
| Precision | **-225** | **220 studs** | laneX, scale 0.62 |

Requirements: each lane must have **clear line of sight** from (laneX±0..10, ~15.5, -5) to every spawn point above. The floor must be continuous at Y 10 from Z -5 to Z -230 over laneX ±12. No CanQuery geometry may sit in that corridor below about Y 20. Drill bots are anchored and CanCollide false, so floor collision only matters visually. Dividers between lanes are fine if they stay outside laneX ±12 (lanes are 44 apart, so dividers go at X = ±0, ±44, ±88, plus outer walls).

### 3.4 Default (always-present) mannequins
`Training Target 1-6`: pivot `(laneX, 12.65, -85)`, yaw 0, Model with no PrimaryPart. They respawn 3 s after death via RiftCombat:423-432 (it clones every child of Targets at server start, then on `Humanoid.Died` destroys the model and parents a fresh clone after `task.delay(3)`). They must be visible and damageable from the firing line and the spawn area.

### 3.5 Drill consoles (ProximityPrompts and BillboardGuis are created at runtime, not authored)
Currently each is a Part `Drill console`, 8x4x4, Metal, CanCollide true, Y center 12 (top Y 14), Z 104:

| Sort order (by X) | X | Action text |
|---|---|---|
| 1 | -105 | Start / next drill |
| 2 | -55 | Difficulty |
| 3 | 0 | Reset 60 second challenge |
| 4 | 55 | Test next primary |
| 5 | 105 | Return to stationary |

The runtime prompt has `ObjectText='RIFT training'`, HoldDuration 0.15, MaxActivationDistance 12. The BillboardGui is 240x50 at StudsOffset (0,4,0), MaxDistance 70. These consoles can move anywhere reachable, but they must keep distinct X values in the same left-to-right order, stay direct children of RiftArena, stay BaseParts, number exactly 5, and keep the root within 15 studs of the part center. Do **not** author your own ProximityPrompt or BillboardGui on them, or they will duplicate. Decorative neighbors (`Console display` Neon 6x2 screens at Z 101.8, `Console tactile control` x15 at Z 103) are cosmetic and can be renamed.

### 3.6 Spawn / lobby entry
Spawn `(0, 14, 110.7)` faces `(0,14,0)`. It sits 6.7 studs behind the center console, between the console row (Z 104) and the equipment lockers (Z 130.3), under the entrance header ("RIFT / TACTICAL DEVELOPMENT CAMPUS" at (0,29,143)). After a rebuild, keep the spawn on a Y-10 floor, inside containment, unobstructed for a 2x5 character, and with a clear view toward the range.

## 4. Other maps' bots inside RiftArena.Targets (the "stray parts near x~2800")
The parts near X 2800 are **Dockyard Target 1-6**, and they are **still required**. Dockyard, Metro District, Pine Ridge and Red Mesa have **no Targets folder of their own**. Their practice bots live in `RiftArena.Targets` because RiftCombat only damages bots that are direct children of that folder and named `<RiftMap> Target ...`. Leave all 24 in place (same names, same positions, still children of RiftArena.Targets) when RiftArena is rebuilt. Moving them would break bot practice on the other four maps. Each map's center X: Pine Ridge 700, Red Mesa 1400, Metro District 2100, Dockyard 2800 (Spawn Z +105.3, Aim Z 0).

Pivot positions (Y 12.65 for all) and yaw:

| Model | X | Z | Yaw |
|---|---|---|---|
| Pine Ridge Target 1 | 738 | -50 | 166.2 |
| Pine Ridge Target 2 | 700 | -50 | 180 |
| Pine Ridge Target 3 | 762 | -50 | 158.2 |
| Pine Ridge Target 4 | 662 | 30 | -153.1 |
| Pine Ridge Target 5 | 738 | 30 | 153.1 |
| Pine Ridge Target 6 | 700 | 30 | 180 |
| Red Mesa Target 1 | 1400 | -50 | 180 |
| Red Mesa Target 2 | 1338 | -50 | -158.2 |
| Red Mesa Target 3 | 1362 | 30 | -153.1 |
| Red Mesa Target 4 | 1438 | 30 | 153.1 |
| Red Mesa Target 5 | 1462 | 30 | 140.4 |
| Red Mesa Target 6 | 1382 | 30 | -166.5 |
| Metro District Target 1 | 2138 | -50 | 166.2 |
| Metro District Target 2 | 2162 | -50 | 158.2 |
| Metro District Target 3 | 2118 | -50 | 173.4 |
| Metro District Target 4 | 2062 | 30 | -153.1 |
| Metro District Target 5 | 2100 | 30 | 180 |
| Metro District Target 6 | 2038 | 30 | -140.4 |
| Dockyard Target 1 | 2762 | -50 | -166.2 |
| Dockyard Target 2 | 2838 | -50 | 166.2 |
| Dockyard Target 3 | 2800 | -50 | 180 |
| Dockyard Target 4 | 2762 | 30 | -153.1 |
| Dockyard Target 5 | 2838 | 30 | 153.1 |
| Dockyard Target 6 | 2800 | 30 | 180 |

Safest rebuild method: **do not delete or recreate the `Targets` folder or anything in it.** Rebuild the environment around it, and only delete or replace the loose environment parts and the `GapClosureWalls` folder. If the other map rebuilds move a map's floor height or bot lanes, these pivots must be re-checked by those agents. That decision belongs to them, not to the arena rebuild.

## 5. Target bot model spec (all 30 identical rigs)
Model children: `Humanoid` + 7 Parts, **all Anchored, with no joints/Motor6Ds**:
- `HumanoidRootPart` 2x2x1, Transparency 1, CanCollide false, CanQuery false (RiftCombat finds the bot through it; RiftTraining keeps it non-query)
- `Head` 1.3x1.25x1.25, SmoothPlastic, Teal (55,227,186). It is named `Head` for headshot detection (`isHeadHit`: `part.Name=="Head"`).
- `Torso` 2.15x2x1.15, Metal, (234,112,86)
- `Arm` x2 0.62x1.9x0.8 and `Leg` x2 0.8x2x0.85, Metal, (26,36,49)
- Humanoid: R6, Health/MaxHealth 100, HipHeight 0, BreakJointsOnDeath false, DisplayDistanceType Viewer
- No attributes on the static bots, and no PrimaryPart.

Runtime-only attributes and children (created by RiftTraining on cloned drill models, never authored): `TrainingOwner` (UserId), `TrainingSession`, `DrillIndex`, `DrillBase`, `DrillActive`, `ActivatedAt`, `Retiring`, plus a `Highlight` named `ActiveTarget`. Drill models are named `Drill <UserId> <index>` and parented to RiftArena.Targets. `Training Target 1` must keep its current structure, because ScaleTo/PivotTo and per-part Transparency/CanQuery toggles assume plain anchored parts.

## 6. Authored SurfaceGuis (cosmetic; re-create in the new style)
- `Firing station enamel number` x6, (laneX, 11.4, -7.4), front TextLabels "01".."06"
- `Observation monitor` x3, "RIFT / RANGE CONTROL" (control booth)
- `Training entrance header` (0,29,143) 73x4x3, "RIFT / TACTICAL DEVELOPMENT CAMPUS"

No script reads these.

## 7. GapClosureWalls: replace them and fix a live bug
Three solid, opaque Concrete Parts (CanCollide, CanQuery, CastShadow all on), not referenced by any script:
- `Range side closure` (-146, 25, -50), 4x32x300
- `Range side closure` (146, 25, -50), 4x32x300
- `Range rear closure` (0, 25, -200), 292x32x4 (spans Z -202..-198, Y 9..41)

**Bug found:** the rear closure sits **in front of the Precision drill spawn (Z -225)** and the recoil backboards (Z -243). Raycasts from every lane's firing point (laneX, 15.5, -5) to (laneX, 13, -225) hit `GapClosureWalls.Range rear closure` at Z -198. Raycasts to Z -45 and Z -85 are clear. Right now **Precision mode cannot be completed** because its targets sit behind a wall. The rebuild must not have any solid, CanQuery geometry crossing the lane corridors between Z -5 and Z -230. Put the rear range wall behind Z -235 (the current `Precision terminal wall` is at Z -254, 290x25x4, and the containment north is at Z -260).

## 8. Current visual layout (reference only; all replaceable)
- Ground: `Structural ground` (0, 9, -65), 294x2x390 (top Y 10, Z -260..130). `Range entrance apron` (0, 9, 141), 294x2x25.
- Firing line: `Firing rubber mat` at (laneX, 10, 0), 29x0.1x10. `Firing station desk` at (laneX, 11.2, -9), 31x2.5x3. Desk top Y 12.45 is below the eye line, and the player stands at Z -5, in front of the desk on the range side.
- Distance stripes: `Range distance stripe` at Z -35, -85, -145, -225 (30/80/140/220 studs from the firing point), 33 wide per lane.
- Overhead: `Target carrier extrusion` per lane at Y 28, Z -239..-17, plus 24 carrier motors/yokes. `Firing gallery roof panel` x3 at Y 35, Z 4/22/40, tilted -10 deg. `Suspended linear light` x11 (Neon) at Y 33, Z 17.
- Back of range: `Recoil calibration backboard` (laneX, 17, -243), 13x12x0.8. `Backstop angled panel`/upper ventilation at Z about -251. `Precision terminal wall` at Z -254. The side walls are `Range perimeter pier`/coping/infill at X ±145.
- Second level: `Observation mezzanine` (0, 24, 60), 286x1x16 (top Y 24.5, Z 52..68). A stair at X 128 (`Dressed stone stair tread` x29, Z 96 to 65) leads to a `Stair top landing` (128, 24.2, 62.5), with `Inclined handrail`s at X 122.9/133.1. The `Control booth` floor is at (0, 24.5, 78) 70x21, the roof at Y 36, with 3 `Observation operator desk`s and panoramic glazing.
- Spawn plaza: 5 drill consoles at Z 104. `Raised planter`s at (±53, 11, 78). `Equipment locker` x6 at X ±75/85/95, Z 130.3 under `Equipment bay canopy` (±85, 22.3, 126). `Training entrance pier`s at (±36, 20.5, 143).
- Lighting: there are 0 Light objects, so all illumination comes from global Lighting plus Neon parts.

## 9. Adjacent observation (not in scope, report only)
`workspace.SpawnLocation` (0, 0.5, 0) lies inside the arena footprint, about 9 studs **below** the arena floor (top Y 10). RiftTravel only repositions characters whose RiftMap is set. Any character spawning before RiftMap is assigned would appear under the range floor. Do not bury it deeper or rely on it. Flag it to the owner of spawn/lobby flow.

## 10. Checklist for the rebuild agent
1. Keep `workspace.RiftArena` (Folder) and its attributes `Spawn`/`Aim`. Update them if the spawn moves (it must stay inside X±147, Z-257..151, on a Y-10 floor).
2. Do not touch `RiftArena.Targets` or any of its 30 models. If they get damaged, restore them from `ServerStorage.RiftBackup_2026-11-06_preStage7.Workspace_RiftArena.Targets` by cloning, never by moving them out of the backup. Keep `Training Target 1-6` at (laneX, 12.65, -85).
3. Keep `RiftArena.Audio` with `Ambience` and `Music`.
4. Provide exactly 5 BasePart `Drill console`s as direct children of RiftArena. They must be reachable from the floor, and their left-to-right X order maps to the action order above. Do not author prompts on them.
5. Keep the 6 lane corridors (X = -110, -66, -22, 22, 66, 110, ±12) clear of CanQuery geometry from Z -5 to Z -230, below about Y 20. Keep the floor at Y 10 there and the firing point (laneX, 14, -5) standable.
6. Delete `GapClosureWalls`, or move the rear piece behind Z -235. It currently blocks Precision.
7. Every walkable surface must be inside RiftArena. Use invisible containment walls at X ±149, Z -260/+154, height up to Y 170.
8. Lane numbers 01-06 should stay visually tied to lanes 1-6. Facing down-range (-Z), +X is on the player's right, so lane 1 (X -110) is the far-left lane and lane 6 (X 110) is the far-right. The drill consoles also read left to right: Start (X -105) through Return (X 105).
