# Rift map gameplay contracts (read-only audit, 2026-11-06)

Sources read in full: ServerScriptService.RiftTravel, RiftContainment, RiftDuel, RiftCombat, RiftMovement;
ReplicatedStorage.RiftTraining, RiftEnvironment, RiftMapDetails, RiftItems; StarterPlayerScripts.RiftAmbience,
RiftSettings, RiftLobbyClient; ServerScriptService.RiftLobbyDisplays. Relevant lines grepped in RiftClient, RiftDuelUI,
RiftMotion, RiftArsenal, RiftAudio, RiftPurchasePrompt. ServerStorage.RiftBackup_* excluded.
Live instance state was inspected with execute_luau in Edit mode.

## 0. Things that do not exist (nothing to preserve)
- `RiftEnvironment.Build()` and `RiftMapDetails.Build()` are empty stubs. RiftTraining calls `RiftEnvironment.Build()` on require, so the module and the function must stay.
- No script reads `GapClosureWalls`. It is only a geometry convention: solid walls that close the open edges.
- No minimap. No kill-plane parts. No named boundary parts are read. No Lighting swap per map. Only `workspace.FallenPartsDestroyHeight = -500` and the RiftContainment Y check (below) apply.
- `RiftMovement.addFeatures` (trampolines, hazards, flank steps, and the "Red Mesa" pad special case) is dead code that nothing calls. Maps do not need parts named Trampoline or Live hazard.
- No script uses a map's Pivot or GetBoundingBox. GetBoundingBox only appears in weapon viewport UIs. The only Pivot read on a map container is `workspace.RiftLobby:GetPivot()`.

## 1. Global / container contracts
| Contract | Where enforced | Rule |
|---|---|---|
| `workspace.RiftMaps` (Folder) | RiftTravel, RiftDuel, RiftContainment, RiftCombat, RiftMovement, RiftAmbience | Explore maps. They also act as duel arenas when they have SpawnA and SpawnB. |
| `workspace.RiftDuels` (Folder) | RiftDuel, RiftContainment, RiftCombat, RiftMovement, RiftAmbience | Duel-only arenas. |
| `workspace.RiftArena` (**Folder**, not Model) | RiftTravel, RiftContainment, RiftCombat, RiftTraining, RiftItems, RiftAmbience | Training Arena. Never call GetPivot on it. |
| `workspace.RiftLobby` (**Model**) | RiftDuel (`lobby:GetPivot()`), RiftTravel, RiftLobbyClient, RiftLobbyDisplays | Must stay a PVInstance. Its pivot is the queue-zone origin. |
| Map name = child name | everywhere | Names are keys: player attr `RiftMap`, `RiftDuelArena`, vote ballot text, target name prefixes, the RiftSettings explore buttons. **Never rename a map.** |
| Built-at-startup lists | RiftDuel `arenas` (line 10-16), RiftMovement `features` (line 19-20) | These scan the RiftMaps and RiftDuels children **once at server start**. A map must exist with that exact name, under that folder, when the server boots. If a map is missing at boot, sprint/dash/slide stop working on it (`features[name]` is nil) and it is never offered as an arena. Swap maps by editing contents in place, not by reparenting at runtime. |
| Vote UI capacity | RiftDuelUI line 87 (`for i=1,7`) | There are only 7 ballot buttons. Today there are exactly 7 arenas (4 RiftMaps + 3 RiftDuels). **Adding an 8th SpawnA/SpawnB map makes it un-votable** unless the UI changes. |
| Runtime-only names | RiftDuel / RiftCombat | `RoundEffects` (a Folder created inside the arena each round) and the attribute `RiftInUse` are set at runtime. **Do not author either one on a map.** An authored RiftInUse=true blocks RiftTravel. An authored RoundEffects child would be picked up by `FindFirstChild` and keep effects alive. |
| `workspace.SpawnLocation` | none | Disabled, neutral, at (0,0.5,0). Harmless. Leave it. |

## 2. Containment (RiftContainment), the footprint limits
Every 0.2 s, per living player, the player's region is chosen:
- **Duel** (`RiftDuelId` and `RiftDuelArena` set): map = RiftDuels[name] or RiftMaps[name]. `spawn = SpawnA` (team 1) or `SpawnB` (team 2). Center X `cx = spawn.X`.
- **Explore** (`RiftMap` = a RiftMaps child): `spawn = Spawn`, `cx = Spawn.X`.
- **Training** (`RiftMap == "Training Arena"`): map = RiftArena, spawn = RiftArena.Spawn (fallback (0,14,110)), `cx = 0`.
- Lobby: no containment.

The player is "inside" when all of these hold. **The check uses world coordinates, not the map's pivot:**
| Region | X | Z (absolute world) | Y (HumanoidRootPart) |
|---|---|---|---|
| Explore and duel maps | `abs(X - cx) <= 139` | `-139 <= Z <= 139` | `5 <= Y <= 155` |
| Training Arena | `abs(X) <= 147` | `-257 <= Z <= 151` | `5 <= Y <= 155` |

Outside that box, the player is pivoted to the last safe CFrame. If there is none, they go to `CFrame.lookAt(spawn, (cx, spawn.Y, 0))`.
Last-safe CFrame is recorded only when the player is on the ground and a downward ray of 8 studs, **filtered to Include {map}**, hits a part.

What a map author must do:
1. Every map must stay centered on world Z = 0, with SpawnA.X == SpawnB.X == Spawn.X == the map's center X. If SpawnA.X differs from SpawnB.X, the two teams get different containment boxes.
2. Every playable space must lie inside X ∈ [cx-139, cx+139] and Z ∈ [-139, 139]. Root Y must stay between 5 and 155, so floors must sit at Y ≥ about 2 (the root is about 3 above the floor), and no reachable surface may be above Y ≈ 152.
3. The perimeter must physically block players before ±139, or they get teleported. Current closure walls sit at Z = ±140/141 and X = cx ± 140. Walls should be solid and CanCollide, inner face at ≤ 139. Background scenery may extend beyond the box (current bboxes reach Z ±148, X ±162) if it is not reachable.
4. All walkable floors must be **descendants of the map instance and CanQuery = true**, or the last-safe position is never stored. Current audit: 0 parts with CanCollide=true and CanQuery=false in any map. Keep it that way. Decor may be CanQuery=false only when it is not walkable.
5. For other map grids, keep the 700-stud X spacing (centers: Training 0, Pine Ridge 700, Red Mesa 1400, Metro District 2100, Dockyard 2800, Switchyard 3700, Canyon Crossing 4400, Old Town 5100, Lobby -700). Scenery from one map must not enter another map's ±139 box or its sightlines.

## 3. Explore-mode travel (RiftTravel)
- Remote `RiftTravel(name)`: valid names are the RiftMaps children, `"Training Arena"`, and `"Lobby"`. A RiftDuels map **cannot** be explored. Travel is blocked if the map has `RiftInUse`, or if the player is queued or in a duel.
- Arrival and every respawn while `RiftMap` is set: `character:PivotTo(CFrame.lookAt(map.Spawn, map.Aim))`. The fallback is RiftArena.Spawn/Aim, then (0,14,82)/(0,14,0).
- Lobby: `workspace.RiftLobby.LobbySpawn.CFrame + (0,3,0)`. RiftTravel resolves LobbySpawn **at script start**, so it must exist at boot.
- UI: RiftSettings hard-codes explore buttons for **Pine Ridge, Red Mesa, Metro District, Dockyard**, and "Enter training" → `"Training Arena"`.
- When a RiftMaps map is picked as a duel arena, explorers on it are sent to the lobby (RiftDuel line 322-326).

## 4. Duel arena contract (RiftDuel)
- A map is an arena when **both `SpawnA` and `SpawnB` Vector3 attributes exist** at server start (in RiftDuels or RiftMaps).
- Round start: for each player, `pos = Spawn{A|B} + ((index - (size-1)*0.5) * 6, 0, 0)`. In 3v3 the offsets are X = -6, 0, +6. The player is pivoted to `CFrame.lookAt(pos, otherTeamSpawn)` and **Anchored for 2.5 s**. Rules that follow:
  - The spawn Y is the HumanoidRootPart position. The floor must be about 3-4 studs below it (all current spawns have Y=14, floor Y=10.0). A 13-stud-wide strip (X ±6.5) at each spawn must be clear of collidable geometry from the floor up to at least floor+6, with no step, edge, or hole.
  - The line from one spawn to the other only sets facing. It need not be clear. Spawn rooms should not see each other (competitive readability).
- Team colours in the UI: team 1 = "Blue"/"Team A" at SpawnA (+Z side). Team 2 = "Orange"/"Team B" at SpawnB (-Z side).
- `RoundEffects` Folder is parented to the arena during Fight. Abilities, grenades, and items are parented there.
- Ballot order = arenas sorted by Name.

## 5. Combat / targets (RiftCombat, RiftItems, RiftTraining)
- **Explore-map practice targets do not live in the maps.** They are Models in `workspace.RiftArena.Targets`, named `"<Map Name> Target <n>"` and placed at that map's world coordinates. A non-player model takes damage only if `model.Parent == workspace.RiftArena.Targets` and its name contains `RiftMap .. " Target"`. On death, each target is re-cloned at its original position (template captured at server start).
- Current target positions (pivot Y 12.65, floor must be at Y 10.0 with no overhead clutter and no blocking parts):
  - Pine Ridge: (738,-50) (700,-50) (762,-50) (662,30) (738,30) (700,30)
  - Red Mesa: (1400,-50) (1338,-50) (1362,30) (1438,30) (1462,30) (1382,30). Target 2 has a ceiling at Y 21.
  - Metro District: (2138,-50) (2162,-50) (2118,-50) (2062,30) (2100,30) (2038,30)
  - Dockyard: (2762,-50) (2838,-50) (2800,-50) (2762,30) (2838,30) (2800,30)
  - RiftDuels maps have no targets.
  A map rebuild must keep a floor at Y = 10 under each (X, Z) pair above, or move the target models in RiftArena.Targets to match. The legs bottom is at about Y 10. Targets are visible and block shots during duels on RiftMaps maps but take no duel damage.
- Training Arena (RiftTraining):
  - `RiftArena.Targets["Training Target 1"]` must exist (assert). It is the drill mannequin template, with children Head, Torso, Arm×2, Leg×2, HumanoidRootPart, and Humanoid. Training Target 1..6 sit at lanes X = -110, -66, -22, 22, 66, 110 (Z -85). Training Target N is hidden during a session on lane N.
  - Lane firing positions: player pivoted to `(laneX, 14, -5)` looking at -Z. Drill targets spawn at Z -45 (default), -85 (Spray), -225 (Precision), pivot Y 12.65.
  - Five direct children of RiftArena named exactly `"Drill console"` (BaseParts; sorted by X → actions 1..5). Current positions are X -105, -55, 0, 55, 105 at (Y 12, Z 104).
  - Training Arena's z-range for containment is -257..151, and |X| ≤ 147. Current side closures are at X ±146.
  - Existing minor issue: collidable parts overlap the lane teleport box (Firing station top at Z -9, steel columns at X ±112 near lanes ±110). This is not blocking, but keep a clear 4×5×4 volume at each `(laneX, 14, -5)`.
- Raycast-based mechanics read map geometry generically. Shots, flash line of sight, explosion line of sight, Warpstone (destination box 3×5×3 checks CanCollide parts), and the RiftClient "roof echo" (any CanQuery part within 30 studs above the camera adds reverb) all behave this way. Glass, fences, and decor that should not stop bullets must be CanQuery=false. Anything collidable and queryable is hard cover.

## 6. Audio (RiftAmbience)
- Each map (RiftMaps, RiftDuels children, RiftArena, RiftLobby) has an optional child Folder `Audio`. Every `Sound` child with a non-empty SoundId is cloned, looped, and crossfaded in. A Sound named `"Music"` goes to SoundService.RiftMusic. Any other name goes to RiftEffects.
- Current state: every map has `Audio/Music` (vol 0.2) and `Audio/Ambience` (vol 0.35), all with empty SoundId (silent). RiftLobby has only Ambience. Keep the Folder and both Sound names.

## 7. Per-map attribute and children spec (current live values)
Attributes are all Vector3. Y is the HumanoidRootPart height, and the floor under every spawn is Y 10.0.

| Map | Folder | Class | Required attributes (exact) | Required children | Containment X range | Z range | Parts / lights now |
|---|---|---|---|---|---|---|---|
| Pine Ridge | RiftMaps | Model | Spawn=(700,14,105.3) Aim=(700,14,0) SpawnA=(700,14,105.3) SpawnB=(700,14,-105.3) | Audio{Music,Ambience}; GapClosureWalls (convention) | 561..839 | -139..139 | 1617 / 0 |
| Red Mesa | RiftMaps | Model | Spawn=(1400,14,105.3) Aim=(1400,14,0) SpawnA=(1400,14,105.3) SpawnB=(1400,14,-105.3) | same | 1261..1539 | -139..139 | 1736 / 0 |
| Metro District | RiftMaps | Model | Spawn=(2100,14,105.3) Aim=(2100,14,0) SpawnA=(2100,14,105.3) SpawnB=(2100,14,-105.3) | same | 1961..2239 | -139..139 | 1744 / 0 |
| Dockyard | RiftMaps | Model | Spawn=(2800,14,105.3) Aim=(2800,14,0) SpawnA=(2800,14,105.3) SpawnB=(2800,14,-105.3) | same | 2661..2939 | -139..139 | 1789 / 0 |
| Switchyard | RiftDuels | Model | SpawnA=(3700,14,112) SpawnB=(3700,14,-112) (no Spawn/Aim) | Audio{Music,Ambience} | 3561..3839 | -139..139 | 1814 / 0 |
| Canyon Crossing | RiftDuels | Model | SpawnA=(4400,14,112) SpawnB=(4400,14,-112) | Audio{Music,Ambience} | 4261..4539 | -139..139 | 1873 / 0 |
| Old Town | RiftDuels | Model | SpawnA=(5100,14,112) SpawnB=(5100,14,-112) | Audio{Music,Ambience}, (Perimeter masonry folder) | 4961..5239 | -139..139 | 2415 / 0 |
| Training Arena | workspace.RiftArena | **Folder** | Spawn=(0,14,110.7) Aim=(0,14,0) | Targets (Folder, incl. Training Target 1..6 and all `<Map> Target n`), 5× "Drill console" Part direct children, Audio, GapClosureWalls | -147..147 | -257..151 | 1740 (incl. 168 target parts) / 0 |
| Lobby | workspace.RiftLobby | **Model** (pivot (-700,22,0)) | none on the model | LobbySpawn (SpawnLocation, enabled, (-700,10.31,64.8)); QueuePads/{1v1,2v2,3v3} Models with attrs QueueSize (1/2/3) and Center (Vector3; -716/-700/-684, 10.6, -60), each with Plate (has a Beam), Ring (Part), Base, BeamTop/Sign (BillboardGui)/Count (TextLabel); WeaponDisplays/<stand> Model with attr WeaponId, child Model "Display" with attr SpinCenter, and a ProximityPrompt "Equip" somewhere under the stand; QueueTerminal (Part) with ProximityPrompt "JoinDuel"; Audio{Ambience} | Queue allowed only within lobby-pivot object space abs(X) ≤ 130, abs(Z) ≤ 100. Pad trigger is a radius of 6 around Center, dY in (-1, 8). | n/a | 292 / 7 |

Spawn safety, audited now: all spawn points and ±6 offsets have floor Y 10.0. Exception: Pine Ridge SpawnB-6 lands on "Raceway stone coping" at 11.0, which is fine. No blocking parts, and all are open to the sky.

## 8. Checklist for any rebuild
1. Keep the instance itself, its name, its parent folder, its class, and its attributes exactly. Rebuild **contents only**.
2. Keep the SpawnA/SpawnB/Spawn/Aim values, or update them consistently: same X as the map center, Z mirrored about 0. Floor at spawnY-4. 13×6 clear strip.
3. Keep all walkable geometry inside the ±139 box, with root Y between 5 and 155. Solid perimeter walls at ≤ 139. Walkable parts CanQuery=true and under the map instance.
4. Keep floor Y 10 and clear volumes at the `<Map> Target n` positions, or move those models in RiftArena.Targets to match.
5. Keep the `Audio` folder with `Music` and `Ambience` Sounds.
6. Do not author `RoundEffects` or `RiftInUse`. Do not add a new arena without enlarging the 7-slot vote UI.
7. Training: keep Training Target 1..6, the 5 Drill consoles (direct children, BaseParts), the lane teleport volumes at (laneX,14,-5), and the drill target zones at Z -45/-85/-225 along the lane Xs.
8. Lobby: keep LobbySpawn, QueuePads (attrs and child names), WeaponDisplays (WeaponId, Display.SpinCenter, Equip), and QueueTerminal.JoinDuel. Keep queue pads within ±130 X / ±100 Z of the lobby pivot.
