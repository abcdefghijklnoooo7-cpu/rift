# RIFT: Art Bible and Level Design Brief (competitive-first)

This is a read-only design pass. Nothing in Studio was changed. It is written for the environment and level-design agents who will rebuild the maps in place.

---

## 0. Ground truth: read this before any layout

### 0.1 Team-to-spawn mapping
The task brief places Blue at z = −105.3. The code does the opposite.

- `RiftDuel:180` reads `winner==1 and "Blue wins the round"`, so Blue is team 1.
- `RiftDuel:231` builds `spawns={SpawnA,SpawnB}`.
- `RiftContainment:10` sends `RiftTeam==2` to SpawnB and every other team to SpawnA.

So **Blue = Team 1 = SpawnA = +Z side**, and **Orange = Team 2 = SpawnB = −Z side**.

Do not swap the attribute values. Containment, travel, explore spawn (Spawn = SpawnA) and practice-target placement all assume the current values.

Every layout in this document is written as **A-side (+Z, Blue)** and **B-side (−Z, Orange)**. If the team assignment ever changes, only the colour labels and spawn dressing change; the geometry stays.

### 0.2 Spawn depths
All 7 maps are duel arenas, because RiftDuel collects every map that has SpawnA and SpawnB. They spawn at two different depths:

- **RiftMaps** (Pine Ridge, Red Mesa, Metro District, Dockyard): SpawnA/B at local z = ±105.3. These four are also explore maps, with Spawn = SpawnA and Aim = (cx, 14, 0).
- **RiftDuels** (Switchyard, Canyon Crossing, Old Town): SpawnA/B at local z = ±112. They have no Spawn or Aim attribute.

Every spawn room is designed around |z| 100–118 so the same room template fits both depths. At each spawn point:

- There must be a clear strip at local x −6, 0 and +6. The **clear rectangle is x −9..+9 by |z| ±4 around the spawn point**.
- The floor top must be at Y 10, with open sky or a ceiling no lower than Y 22.
- Players are anchored for 2.5 s facing the enemy spawn. That forward view must be blocked within 30 studs by spawn-room architecture: a baffle wall or front parapet.

### 0.3 Footprint and containment
- Grid is local x −142..142 and z −142..142. The **playable area is ±139**.
- The band from 139 to 142 is the perimeter wall: solid, CanQuery true, inner face at or inside 139, at least 3 studs thick, top at Y 60 or higher.
- Anything beyond 142 is background scenery only.
- RiftContainment checks the HumanoidRootPart in world space: |X − cx| ≤ 139, Z within ±139, Y between 5 and 155.
- **Floor tops: lowest Y 2** (HRP 6). **No reachable surface above Y 48.** That is a design cap; the hard limit is about 152.
- All walkable floors must be descendants of the map Model with CanQuery = true. The last-safe ray is 8 studs long.

### 0.4 Practice-target pads (Pine Ridge, Red Mesa, Metro District, Dockyard)
The bots live in `workspace.RiftArena.Targets` at world positions with pivot Y 12.65, so their feet are at Y 10.

- They stay visible and stop bullets during duels on these maps.
- **Treat them as deliberate cover in the lane plans.** Each pad needs:
  - floor at Y 10
  - a clear 5×5 patch
  - nothing hittable inside the bot volume
  - a ceiling at Y 21 or higher (Red Mesa Target 2 currently has a ceiling at exactly Y 21)
- The pads are not mirror-symmetric across z = 0. That is accepted. Moving them is a separate task, because it means editing the Targets folder, which every map agent must leave untouched.
- The per-map local coordinates are listed in each map section, as local x = world X − cx.

### 0.5 Lighting is global
There is one `game.Lighting`, and all 9 areas share it. The per-map mood values below are **preset data for a future client-side preset switcher**, for example in RiftAmbience, keyed on the player's current map. Building that switcher is script work outside this task. **No per-map value takes effect until it exists.** Until then, use the Global Baseline in section 1.5.

### 0.6 Runtime-only names: never author these
- `RoundEffects` children
- `RiftInUse` attributes
- ProximityPrompts or BillboardGuis on Drill consoles
- Drill attributes
- `ActiveTarget` highlights

Keep each map's Audio folder with its "Music" and "Ambience" Sounds. Do not rename any map.

### 0.7 Neighbour spacing
Maps are 700 studs apart on X. Keep background scenery within local |x| ≤ 300 and |z| ≤ 420. Every background part must be:

- CanCollide = false
- CanQuery = false
- CanTouch = false
- CastShadow = false, except a few hero silhouettes, which may keep CastShadow but still have CanQuery = false

---

## 1. Rift visual identity

### 1.1 World premise (lore hook)
A decade ago, "Rift events" tore thin seams in reality across ordinary places: forest outposts, desert mines, a city rail hub, a harbour, a power yard, a gorge dam and a hill town.

The **Rift Authority** stabilised each seam with modular **anchor hardware**, then turned the cordoned zones into sanctioned combat proving grounds. Every map is therefore a real, lived-in place that was abandoned mid-use, plus a layer of clean, engineered Authority equipment:

- teal-cored stabiliser pylons
- cable trays
- containment fencing
- numbered zone signage
- a dormant or active seam at the map's heart

**Storytelling formula for every map:**
1. **Place:** the original civilian identity, which supplies 70% of the visual mass.
2. **Event:** the moment the rift hit. Frozen evidence such as a derailed car, a stopped clock or a spilled ore cart.
3. **Authority:** the overlay of stabiliser tech, barricades and markings that made the place into an arena.

The three layers must stay visually separable. Place uses natural or weathered materials, Event uses scorched or displaced elements, and Authority uses clean graphite with teal.

### 1.2 Shape language
- **Primary forms** are strong, simple masses, chunky enough to read at 80 studs.
  - Floor-to-floor height is 8 studs: floors at Y 10, 18, 26 and 34.
  - Wall thickness is 1–2 studs, parapets 3.5 studs high, doorways 6 wide by 8 tall, windows at 2-stud increments.
  - Rule of three: every building has a base (plinth or rusticated band 0–2 studs), a body, and a crown (cornice, roof or parapet).
- **Rift and Authority shapes** are angular, faceted and chamfered: 45° bevels and hexagonal or octagonal pylons. They are the only "sharp" vocabulary, and they contrast with each theme's native forms (organic pine, eroded mesa, orthogonal city, and so on).
- **Silhouette rhythm:** every skyline has one dominant vertical (the hero landmark), two secondary verticals, and a low continuous horizon band. No skyline is a flat line of equal-height boxes.
- **No plain rectangles.** Every building gets at least one of: setback, overhang, recessed entry, balcony, stair volume, roof form, or arcade.
- **Grid alignment:** snap primary geometry to a 1-stud grid and detail to 0.25. Rotations are 0/90/180/270, plus 45° only for Rift elements and deliberate street angles. No random rotation of structural pieces.

### 1.3 Material language
**Detail layers**
- **Primary (gameplay mass):** one dominant material per surface type per map. Use Roblox materials with low-frequency colour:
  - Concrete, Slate, Brick, WoodPlanks, Sandstone, Limestone, Basalt, Asphalt, Pavement, CorrodedMetal, DiamondPlate, Metal, Cobblestone
- **Secondary (articulation):** trims, frames, columns, stairs, railings. Use a contrasting material at a value step of 15–25%.
- **Tertiary (storytelling and micro):** decals, cables, vents, signage, debris vignettes. All CanCollide false and CanQuery false unless they are cover.

**Material families**

| Family | Materials | Use |
|---|---|---|
| Place | Wood, WoodPlanks, Brick, Cobblestone, Sandstone, Limestone, Slate, Grass, LeafyGrass, Ground, Rock, Basalt, CrackedLava (Red Mesa only, as dark ochre crust), Fabric, CorrodedMetal | the original civilian identity |
| Authority | SmoothPlastic or Metal in graphite (46,50,58), cool white panels (214,220,226), DiamondPlate floors, Glass (CanQuery false) for observation | stabiliser equipment and markings |
| Rift energy | Neon teal (0,224,204), used **only** on the rift seam, stabiliser cores and objective wayfinding | rift energy |

- Teal Neon surfaces must be at most 0.5 studs thick and narrow strips. **No more than 1.5% of visible surface area** in any frame.
- **Forbidden:** ForceField material in play spaces, large Neon surfaces, Glass that blocks bullets unintentionally, and pure black (value below 12%) or pure white (above 92%) large surfaces.

### 1.4 Colour philosophy
- Every map owns one **temperature identity** and a desaturated base palette (HSV saturation ≤ 0.40 for large surfaces). It has exactly **one accent family** in addition to the reserved colours.
- **Reserved colours.** Do not use these hues for environment mass anywhere:

  | Role | RGB | Rule |
  |---|---|---|
  | Blue team, world | (52,112,200), dark trim (30,64,120) | spawn-side only |
  | Orange team, world | (222,122,50), dark trim (130,64,24) | spawn-side only |
  | Rift teal | (0,224,204), glow core (120,255,236) | rift and objectives only |
  | Danger red | (230,60,70) | out-of-bounds and hazard edges only |

- Practical consequences:
  - No saturated blue or orange containers, shutters, awnings or vehicles.
  - Substitute sage (110,132,104), maroon (120,52,50), mustard (186,150,70), cream (220,208,180) or slate-blue-grey (96,108,122). Slate-blue-grey is allowed because its saturation is below 0.25.
- **Value structure:** floors are mid-dark (value 30–50%). Walls in the silhouette band are mid (45–65%). Roofs and skyline are lighter, or darker with atmosphere. The background must be at least 15% lower in contrast than the play space.

### 1.5 Lighting philosophy and Global Baseline

**Philosophy**
- Bright and readable first, mood second.
- The sun is the key light, and practicals are accents.
- Shadows exist to describe form, never to hide players. No interior zone may have an ambient-lit luminance below the readability floor: a character at 60 studs must be distinguishable.
- Indoors, use SurfaceLights or PointLights at 0.6–1.2 brightness with shadows off.

**Global Baseline**
Apply this as soon as possible to `game.Lighting`. It is independent of the switcher.

| Setting | Value |
|---|---|
| Technology | Future (keep) |
| ClockTime | 16.3 |
| Brightness | 2.6 |
| Ambient | (118,118,126) |
| OutdoorAmbient | (140,138,136), near-neutral |
| EnvironmentDiffuseScale / EnvironmentSpecularScale | 0.5 / 0.6 |
| ExposureCompensation | 0.1 |
| GlobalShadows | on |
| ShadowSoftness | 0.25 |
| ColorShift_Top | (255,214,178) |
| ColorShift_Bottom | (0,0,0) |
| Atmosphere | Density 0.22, Offset 0.15, Color (206,214,224), Decay (146,150,170), Glare 0.3, Haze 0.8 |
| Bloom (keep ONE, delete "RiftBloom" or the default) | Intensity 0.15, Size 20, Threshold 1.3 |
| ColorCorrection (keep ONE) | Brightness 0.02, Contrast 0.10, Saturation 0.0, Tint (255,250,244) |
| SunRays | Intensity 0.04, Spread 0.2 |
| Sky | keep RiftSunsetSky for now; per-map skies are switcher-driven |

**Budgets**
- At most 40 lights per map. At most 4 may have Shadows = true, and only on hero landmarks.
- Prefer Neon practicals that are not lights. A lamp head made of SmoothPlastic with emissive-looking light colour plus one non-shadow PointLight per 2–3 lamps is enough.

### 1.6 Signage and graphics language
**Typography**
- Font: GothamBold / GothamBlack for Authority signage, with condensed uppercase, tracking +.
- Civilian signs use the theme's own font: Antique for Old Town, Arcade-free Highway for Metro, and so on.

**Authority zone code system.** Every callout location gets a plate reading `[MAP-CODE] / [ZONE] / [NUMBER]`. Plates are graphite with white text and a teal 0.2-stud underline. Map codes:

| Code | Map |
|---|---|
| PR | Pine Ridge |
| RM | Red Mesa |
| MD | Metro District |
| DY | Dockyard |
| SW | Switchyard |
| CC | Canyon Crossing |
| OT | Old Town |

For example, `MD / A-HALL / 02`.

**Team-side signage**
- A-side and B-side spawns each get a large painted spawn mural: a chevron plus the letter "A" or "B" in the team colour on a graphite field. Floor chevrons point out of each spawn exit.
- Team colour appears only within about 35 studs of the team's own spawn (|z| > 70), always at saturation reduced as specified in 1.4. **Mid is team-neutral.**

**Hazard and edge language**
- Danger red with graphite 45° stripes on non-walkable edges such as quay drops, trench lips and track pits.
- Yellow (210,180,60) step-edge strips on stairs only.

**Wayfinding.** Teal floor arrows are allowed only on the path toward mid (the objective).

**Decals.** Low count, purposeful: graffiti tags of the "seam" glyph, stencils, posters. Each wall face has at most 2 decals.

### 1.7 Readability rules
1. **Silhouette band, Y 11–17** (character body at floor Y 10). Surfaces directly behind common combat positions in this band must be low-frequency and mid-value. No busy patterns, mullion grids, Neon, high-contrast stripes or foliage clusters.
2. **Player contrast.** Characters are blocky, multi-coloured avatars, so keep the environment desaturated:
   - No large surfaces in fully saturated primaries.
   - No glare sources in the eye line of a main sightline. Neon is never placed where a player would be framed by it.
3. **Cover grammar.** One height reads one function:

   | Height | Function |
   |---|---|
   | 3.5 studs | crouch / half cover |
   | 7 studs | full cover |
   | 10 studs or more | sightline blocker |

   Cover pieces use the map's secondary material plus a 0.2-stud lighter cap edge, so they read as cover.
4. **Hittable vs decorative.** Anything that looks solid must stop bullets (CanQuery = true). Anything that does not stop bullets must look non-solid: chain-link, glass, foliage, cloth, cables. Set chain-link and glass to CanQuery = false, and make their transparency at least 0.4 so they are visually see-through.
5. **No ambiguous foliage.** Bushes in the play space are either solid planters with the foliage on top above Y 13.5, or non-colliding tufts below Y 11.5. Never person-height clumps.
6. **Clutter cap.** Within the playable footprint, at most 1 prop vignette per 400 sq studs. Props are composed into vignettes of 3–7 pieces with a story, never loose singles.
7. **Callouts.** Every one of about 10–14 named callouts per map has a unique silhouette or colour cue and an Authority plate.

### 1.8 Performance rules
- Target 4,000–9,000 BaseParts per map: play space about 2,500–4,500, background about 1,500–4,000.
- Build modular kits: a window bay, a door bay, stairs of 8-stud rise, a railing segment, a pylon and a crate kit. Clone kit Models rather than hand-placing parts.
- Background parts must be large and few, with the flags in 0.6.
- Particles: at most 6 emitters per map, Rate ≤ 10, lightweight.
- Organise each map into sub-folders:

  ```
  Map/Gameplay/{Floors, Walls, Cover, Stairs, Perimeter}
  Map/Architecture/{District name}
  Map/Detail
  Map/Story
  Map/Lights
  Map/Background
  Map/Audio   (existing)
  ```

  Walkable floors stay under the map Model, at any depth.

---

## 2. Shared competitive template

All seven duel maps use this skeleton. Each map section gives only its deltas from it.

### 2.1 Symmetry and frame
- Use **mirror symmetry across the plane z = 0** for all gameplay geometry. Every gameplay piece at (x, z) has a twin at (x, −z).
  - Each lane is therefore one themed district shared by both teams, with equal travel distance and equal cover on each half.
  - Lane themes differ: West is "Long" and East is "Short".
  - Handedness differs only slightly: West is on A's left (facing −Z, RightVector = +X) and on B's right. Make the key peek corners symmetric about the lane centreline so neither team gets a better wide-swing side.
- Do **not** use 180° rotational symmetry. It would force the west and east lanes to be hybrids of each other and destroy the per-lane district identity.
- Thematic dressing (Place and Event layers) may be asymmetric if it does not change cover or sightlines. A-side dressing leans "Place-pristine" and B-side leans "Event-damaged", which adds variety at no gameplay cost.
- Axes: A-side is +Z (Blue) and B-side is −Z (Orange). "West" is −x and "East" is +x.
- "Twin" throughout this document means the mirrored counterpart at (x, −z).

### 2.2 Bands (local)

| Band | Range | Contents |
|---|---|---|
| Spawn room A | x −34..34, z 96..136 | Spawn strip at z 105.3 or 112 |
| Spawn room B | mirror at z −136..−96 | |
| Spawn front baffle | z 92..96 (A), x −14..14, height ≥ 12 (Y 22) | Blocks the forward view while players are anchored. Exits are at x ±20..±30 (6 studs wide) plus two side exits at x ±34. |
| Staging plaza | z 70..92 (A) | Team-coloured floor graphics; routes split here |
| Lane W | x −125..−65 | |
| Lane Mid | x −28..28 | |
| Lane E | x 65..125 | |
| Connectors | x −65..−28 and 28..65 | Connectors between lanes at z ≈ ±45 ("A-link" / "B-link"), plus one central cross at z −10..10 through or around the mid landmark |
| Mid landmark footprint | x −16..16, z −16..16 | Solid core, at least 14 studs tall (top at Y 24 or higher), visually the map's hero or attached to it |

### 2.3 Elevation tiers (floor tops)

| Tier | Floor Y | Use |
|---|---|---|
| Sunken | 4–6 | trenches, docks, track pits, culverts (HRP 8–10 ≥ 5 OK) |
| Base | 10 | |
| Raised | 14 | plinths, platforms; 4 rise by stairs or ramp |
| Upper | 18 | balconies, walkways, 2nd floors |
| High | 26 | rooftops, catwalks; at most 2 per side and must be contestable |
| Landmark crown | 34–42 | non-walkable, or walkable only if enclosed by parapets with no spawn view |

- Stairs: 1-stud risers by 1.6-stud treads, 6 studs wide minimum. Ramps: ≤ 30°, 6 studs wide minimum.
- Every upper tier needs **two access routes**: one exposed, one protected.

### 2.4 Lane archetypes per map (default pattern)
- **Long:** an open, longer-range lane with one elevated vantage per side at Y 18. It bends once with an S-bend so there is no straight run of more than 90 studs.
- **Mid:** the contest space around the landmark. It has an underpass or interior route at base level and a heaven/bridge at Y 18 whose ends are protected from spawn view.
- **Short:** a close-quarters route through interiors, alleys or tunnels, with doors and corners every 20–30 studs. It is partially roofed (ceilings at Y ≥ 18 or Y ≥ 22 over target pads).

### 2.5 Sightline rules
1. **No spawn-to-spawn line**, from any spawn-side vantage (the highest A-side walkable point within |z| > 70, at eye height plus 1.7) to any point in the opposite spawn rectangle.
   - The mid landmark must be taller than the highest spawn-side vantage plus 4. Default vantage is Y 18 + 5.5 = 23.5, so the landmark top is at Y ≥ 28.
   - Lanes each carry a named baffle at |z| 55–70 (the S-bend).
2. **Longest uninterrupted sightline** in any lane: 110 studs. Mid crosses: at most 80 studs.
3. **Spawn exits** are not visible from any point on the other team's half (sign of z opposite) beyond 40 studs.
4. **Elevated vantages** each have at least one blind approach (stairs inside a volume or a back ladder) and at least one counter-angle.
5. **Verify** with edit-mode raycasts. Grid of 1 ray per 6 studs on spawn strip and vantage points.

### 2.6 Background ring (shared spec)
Each map has three bands beyond the perimeter:

| Band | Distance | Contents | Part budget |
|---|---|---|---|
| Near | 142–175 | facades and terrain that "continue" the place, rising above the perimeter wall so the wall is hidden | 600–1,500 |
| Mid | 175–260 | silhouettes, larger masses | 400–1,000 |
| Far | 260–420 on Z (and up to 300 on X) | horizon masses (cliffs, skyline, sea plane, ridges) | 100–300 big parts |

The perimeter wall is dressed on its inner face as believable architecture (backs of buildings, rock walls, quay fences backed by solid walls) and is never a flat grey tray.

---

## 3. Maps

Local coordinates are used throughout: local x = world X − cx, and local z = world Z. "Twin" means the mirrored counterpart (x, −z), which must be built identically for gameplay.

---

### 3.1 PINE RIDGE: "Ridge Station Seven" (cx 700, RiftMaps, spawns ±105.3)

**Theme.** An alpine forestry and seismic research outpost on a pine-covered ridge in late-morning sun. Cool, fresh, green-grey.

**Story**
- *Place:* timber lodge dorms, a sawmill shed, a log yard and a fire-lookout tower.
- *Event:* the seam opened under the sawmill, splitting the log yard along a teal fissure. Logs are frozen mid-roll and a felled pine lies across the creek.
- *Authority:* the lookout tower was refitted as an anchor mast with a dish. Stabiliser pylons are staked along the fissure.

**Districts**
- A-side "Lodge Terrace" (+z)
- B-side "Ranger Yard" (−z)
- West "Creek Cut"
- Mid "Sawmill & Fissure"
- East "Log Deck"

**Practice-target pads**
- (38,−50), (0,−50), (62,−50), (−38,30), (38,30), (0,30)
- Two rows of 3. Dress them as the "Ranger qualification range": flat timber pads, each flanked by low log barriers 3.5 tall placed 4 studs to the side.
- The z −50 row sits in the B-side approach to mid and Short-E. The z +30 row sits in the A-side mid approach.
- Keep the floor at Y 10 and a ceiling at Y 22 or higher at all six.

**Layout (deltas from template)**
- **Spawn A "Lodge Terrace"**
  - Timber lodge porch: x −34..34, z 98..134, ceiling open over the strip.
  - Baffle: a stone chimney mass at z 92..96 (x −8..8, top Y 26).
- **Spawn B "Ranger Yard"**
  - A covered vehicle bay of the same footprint, with an open roof slot over the strip.
  - Baffle: a stacked-log wall, top Y 22.
- **Mid "Sawmill"**
  - The sawmill building's core is the landmark footprint.
  - Mid-route options:
    - An interior saw floor at Y 10 (x −14..14, z −10..10). Its N and S doors are both at x +8, with a solid saw-bench baffle (x 2..14, z −2..2, 7 tall) between them, so there is no straight line through.
    - An upper conveyor gantry at Y 18 running east to west (x −40..40, z −2..2, 4 wide) with 3.5-stud railings. CanQuery is true on the rail posts only.
  - The fissure: a sunken trench at Y 5, 6 wide, along z −3..3. It runs from x −44 to −14 and from x 14 to 44, with the sawmill splitting it, beneath the gantry. Teal Neon crack strips (0.3 wide) line its floor. Exit ramps are at both ends of each half.
- **Long West "Creek Cut"**
  - A creek-bed lane at Y 6 (x −110..−80, z −60..60), banked with Rock steps rising to Y 10.
  - The felled pine trunk (radius 2.5, Wood) is solid cover across the creek at z 0.
  - Elevated vantage: the timber footbridge at Y 18 (x −110..−80, z 40..46). Its twin is at z −46..−40, on the same lane.
  - Bend: a boulder cluster at z ±62.
- **Short East "Log Deck"**
  - A covered log-sorting shed. Interiors run x 70..125, z −70..70 with low ceilings at Y 18.
  - Stacked log bays act as doors.
  - Upper lofts at Y 18 at z 30..50 and its twin at z −50..−30, each with a ladder stair.
- **Connectors**
  - A-link at z 45: a pine-needle path between a lodge outbuilding (x −60..−30) and a woodpile.
  - B-link: the twin at z −45.
- **High ground.** The lookout tower base (outside mid, at (0,0) above the sawmill roof) has a walkable crown platform at Y 26, enclosed by a parapet at Y 30. Landmark mass must reach Y ≥ 30 so the parapet blocks the spawn line.

**Hero landmark: "Lookout Seven"**
- A timber-truss fire tower rising from the sawmill roof to Y 64.
- A cab at Y 52–60 with an Authority anchor dish (octagonal, 12 diameter, graphite plus teal core ring).
- Visible from both spawns as an orientation anchor.
- The walkable part ends at Y 26–30; everything above is CanQuery false except the solid core column.

**Callouts**
- Lodge, Chimney, Porch, Creek, Pine Log, Footbridge, Sawmill, Gantry, Fissure, Log Deck, Loft, Woodpile, Range, Tower

**Palette**

| Role | RGB |
|---|---|
| Pine bark / wood primary | (104,78,58) |
| Weathered plank | (150,128,104) |
| Stone base | (118,120,118) |
| Moss / grass | (92,118,74) |
| Pine foliage | (52,82,60) |
| Slate roof | (70,78,86) |
| Snowcap trim (rooftops only) | (226,230,232) |
| Accent: forest-service mustard | (186,150,70), signage and trims only |
| Rift teal | in the fissure only |

**Materials**
- WoodPlanks, Wood, Cobblestone (bases), Slate (roofs), Rock (creek), Grass/LeafyGrass, CorrodedMetal (saw machinery)

**Background**
- Near: pine-forest wall using a cone-tree kit (3 sizes, 3–6 parts each), with stepped Rock ridges rising to Y 40 behind the perimeter.
- Mid: a second ridge with sparser trees and power-line towers.
- Far: snow-capped mountain wedges (Rock and Snow, 6–10 huge WedgeParts) at z ±400 and a valley lake plane to the east. The perimeter wall is dressed as a stone retaining wall with timber fencing.

**Lights (about 16)**
- Lodge porch lanterns (6), sawmill interior SurfaceLights (4), fissure glow PointLights (teal, brightness 0.6, range 10; 4), tower cab (2; 1 with shadows)

**Lighting preset**

| Setting | Value |
|---|---|
| ClockTime | 11.2 |
| Brightness | 2.8 |
| Ambient | (120,128,132) |
| OutdoorAmbient | (136,148,150) |
| ExposureCompensation | 0.05 |
| ColorCorrection | Tint (246,252,255), Saturation 0.0, Contrast 0.08 |
| Atmosphere | Density 0.24, Color (200,216,224), Decay (120,140,150), Haze 0.9, Glare 0.15 |
| Bloom | 0.12 |

---

### 3.2 RED MESA: "Seam Quarry" (cx 1400, RiftMaps, spawns ±105.3)

**Theme.** A desert open-pit mine cut into red mesa rock under hot early-afternoon sun. Warm, bright and dusty, with hard shadows.

**Story**
- *Place:* a terraced quarry, an ore conveyor, a headframe mine shaft and adobe miners' cantina buildings.
- *Event:* drilling breached the seam. The central pit glows teal, ore carts hang off derailed tracks, and a dragline bucket lies abandoned.
- *Authority:* containment fencing around the pit, a stabiliser ring at the pit rim, and survey stakes.

**Districts**
- A "Cantina Row"
- B "Truck Depot"
- West "Upper Benches"
- Mid "The Pit"
- East "Conveyor Gallery"

**Practice-target pads**
- (0,−50), (−62,−50), (−38,30), (38,30), (62,30), (−18,30)
- Dress them as survey-target stands on graded dirt pads.
- (−62,−50) previously had a Y 21 ceiling. **Rebuild with no ceiling below Y 24** there.

**Layout**
- **Spawns.** A: an adobe cantina courtyard with pergola beams at Y 24 (open between beams) and a baffle of an adobe water tower base, top Y 24. B: a truck-depot canopy (roof at Y 24 with a skylight gap over the strip), with its baffle a parked ore truck (solid, top Y 22).
- **Mid "The Pit"**
  - A stepped sunken bowl, x −30..30, z −24..24. Floor at Y 4 at centre, with terraces at Y 6 and 8 and ramps at the 4 diagonals.
  - The landmark core is the headframe base: x −8..8 at the pit centre. It is a solid concrete collar and shaft housing up to Y 30.
  - Contesting mid means fighting down into or across the rim.
- **Long West "Upper Benches"**
  - Quarry terraces along the west edge, x −125..−70: Y 10 to Y 14 to Y 18 benches, stepping toward the perimeter.
  - Long-range duels along z. The bend is a rock spur at z ±60, a 12-tall Sandstone mass.
- **Short East "Conveyor Gallery"**
  - A corrugated-steel conveyor gallery: a tunnel at Y 10, x 75..95, z −80..80, roof at Y 18, broken into 3 segments by machinery rooms.
  - The conveyor itself runs on top at Y 18–20 as a walkable catwalk, reached from crusher-house stairs at z ±70.
- **Connectors**
  - Ore-track cuttings at z ±45: rails at Y 8 sunk 2 into the ground, with ore carts as half cover.
- **Elevation and spawn safety.** The headframe catwalk ring at Y 26 is walkable, accessed by a single internal stair. Parapets at Y 30 hide the spawns.

**Hero landmark: "Headframe No. 3"**
- A steel A-frame headframe with twin sheave wheels at Y 70, over the pit.
- A teal-lit seam column rises out of the shaft. It is CanQuery false and a narrow Neon core with a Glass sleeve.

**Callouts**
- Cantina, Water Tower, Depot, Truck, Pit, Rim, Collar, Benches, Spur, Gallery, Crusher, Catwalk, Cart, Survey

**Palette**

| Role | RGB |
|---|---|
| Mesa red rock | (168,86,58) |
| Pale sandstone | (206,164,120) |
| Dust ground | (196,150,110) |
| Adobe | (214,176,140) |
| Weathered steel | (110,104,100) |
| Rust | (128,70,46) |
| Sky-faded turquoise doors | (92,140,136), low saturation; the only cool note, not teal-bright |
| Accent: mine-safety yellow | (210,180,60) |
| Rift teal | shaft column and pit rim |

**Materials**
- Sandstone, Rock, Ground, Concrete (collar), CorrodedMetal, DiamondPlate, WoodPlanks (pergola), Plaster (adobe), CrackedLava (sparingly, as oxidised crust in pit walls, saturation-checked)

**Background**
- Near: quarry walls rising in terraced red cliffs to Y 50 around the footprint.
- Mid: freestanding mesas and buttes (stacked Wedge and Block clusters), a power line, and a haul road with a parked dump truck.
- Far: flat-topped mesa silhouettes at z ±400 and a heat-faded horizon plane.

**Lights (about 12)**
- Cantina string lights (4), gallery interior (5), shaft glow (2), headframe beacon (1, red, small)

**Lighting preset**

| Setting | Value |
|---|---|
| ClockTime | 13.8 |
| Brightness | 3.1 |
| Ambient | (128,112,104) |
| OutdoorAmbient | (156,138,124) |
| ExposureCompensation | −0.1 |
| ColorCorrection | Tint (255,246,236), Saturation 0.02, Contrast 0.12 |
| Atmosphere | Density 0.2, Color (230,196,166), Decay (170,120,96), Haze 1.1, Glare 0.35 |
| Bloom | 0.14 |

---

### 3.3 METRO DISTRICT: "Kestrel Junction" (cx 2100, RiftMaps, spawns ±105.3)

**Theme.** A dense mid-rise city interchange at blue-hour dusk. Cool navy sky against warm amber windows and shop practicals.

**Story**
- *Place:* an elevated metro line crossing a plaza, a station concourse, brick townhouses, a corner diner and a parking deck.
- *Event:* the seam stopped a train mid-bridge. The last carriage is twisted and hanging, newspapers are frozen mid-air (non-colliding), and streetlights flicker.
- *Authority:* barricaded intersections, a mobile command van and an anchor pylon on the station roof.

**Districts**
- A "Diner Corner"
- B "Parking Deck"
- West "Townhouse Alley"
- Mid "Junction Plaza & Viaduct"
- East "Station Concourse"

**Practice-target pads**
- (38,−50), (62,−50), (18,−50), (−38,30), (0,30), (−62,30)
- Dress them as police training cut-outs on a cordoned plaza strip.
- The z −50 row is in the east concourse forecourt. The z +30 row is in the plaza and alley mouth.

**Layout**
- **Spawns.** A: a diner forecourt under a neon-free awning (awning at Y 22, open slot over the strip). Its baffle is a newsstand plus bus shelter mass (top Y 22). B: parking-deck ground level with a roof opening (skylight void) over the strip. Its baffle is a ticket booth plus stair core.
- **Mid**
  - The **viaduct** runs east-west across mid at Y 26–30. It is a deck with arches, piers at x ±16, ±48 and ±80, at z −6..6.
  - A walkable track deck at Y 26 sits only between x −40..40, enclosed by the stalled train cars. The cars are solid 7-tall cover with side doors.
  - The plaza beneath at Y 10 has a sunken fountain basin at Y 7 (16×16).
  - The landmark core is the central pier cluster plus the train above, totalling Y 10–36.
- **Long West "Townhouse Alley"**
  - A narrow cobbled alley, x −100..−80, between townhouse rows.
  - Townhouse interiors at Y 10 and 18 with exterior iron stairs. Balconies at Y 18 face the alley.
  - The bend is a dog-leg at z ±60 through a covered passage (archway, 8 tall).
- **Short East "Station Concourse"**
  - Interior ticket hall, x 70..125, z −60..60, with mezzanine at Y 18. Turnstile banks are 3.5-tall half cover.
  - Platform stairs at z ±30 inside the concourse lead up to the viaduct deck at Y 26. This is the protected route to heaven; the exposed route is an external fire stair on a west-alley townhouse at z ±30.
- **Connectors**
  - Street crossings at z ±45 with abandoned cars (full cover) and a barricade chicane.
- **Rooftops**
  - One rooftop route per side at Y 26 over the townhouses (x −125..−95, z 20..70; twin at x −125..−95, z −70..−20). Parapets 3.5. The approach is through the interior stairwell.

**Hero landmark: "The Stalled Line"**
- The arched viaduct with a 3-car train, the last car twisted 20° down toward the plaza.
- A teal seam threads between its wheels. CanQuery is false on the seam; the car bodies are solid.

**Callouts**
- Diner, Shelter, Deck, Booth, Plaza, Fountain, Viaduct, Train, Alley, Passage, Balcony, Concourse, Turnstiles, Mezz, Roofs

**Palette**

| Role | RGB |
|---|---|
| Brick | (132,72,58) |
| Sandstone trim | (196,176,146) |
| Concrete | (142,144,146) |
| Asphalt | (62,64,68) |
| Paving | (120,118,114) |
| Iron | (58,62,66) |
| Window glow | (255,206,140), SmoothPlastic, not Neon |
| Accent: transit green | (70,140,104), metro signage and line livery |
| Rift teal | seam only |

Team blue would clash with any blue city signage, so the transit accent is green.

**Materials**
- Brick, Concrete, Asphalt, Pavement, Cobblestone, Metal, Glass (CanQuery false), Granite (station)

**Background**
- Near: continuous 4–8-storey facade walls (facade kit: window bays, cornices) rising to Y 70 behind the perimeter. They have lit windows (randomised 20% warm) built as SmoothPlastic colour, with no lights.
- Mid: high-rise silhouettes up to Y 180, and the viaduct continuing off-map in both directions.
- Far: a skyline of block towers at z ±380 with a few red aircraft beacons as tiny Neon parts. Replace the existing flat grey boundary wall.

**Lights (about 30, the largest budget)**
- Streetlamps (10, no shadows), diner and shop interiors (8), concourse (6), train interior (3), viaduct uplights (3, one with shadows)

**Lighting preset**

| Setting | Value |
|---|---|
| ClockTime | 18.6 |
| Brightness | 1.9 |
| Ambient | (100,106,126) |
| OutdoorAmbient | (118,124,146) |
| ExposureCompensation | 0.3 |
| ColorCorrection | Tint (240,244,255), Saturation 0.0, Contrast 0.12 |
| Atmosphere | Density 0.26, Color (150,160,190), Decay (90,80,120), Haze 0.9, Glare 0.2 |
| Bloom | 0.18, Threshold 1.2 (practicals glow) |

Readability guard: the minimum ambient must keep street-level characters readable.

---

### 3.4 DOCKYARD: "Pier 9 Terminal" (cx 2800, RiftMaps, spawns ±105.3)

**Theme.** A working container harbour on an overcast, sea-misted morning. Cool grey-green and steel, with weathered multi-colour containers in muted tones.

**Story**
- *Place:* a container stack yard, warehouse sheds, a quay edge with bollards and a crane rail, and a customs office.
- *Event:* the seam erupted between container rows. Containers are flung and stacked at odd angles (gameplay-aligned) and one container is split open, leaking teal light. A freighter is moored offshore.
- *Authority:* an inspection checkpoint, scanner arches and floodlight masts.

**Districts**
- A "Customs Office"
- B "Warehouse 9"
- West "Quay Edge"
- Mid "Stack Yard"
- East "Shed Row"

**Practice-target pads**
- (−38,−50), (38,−50), (0,−50), (−38,30), (38,30), (0,30)
- Dress them as customs inspection lanes: painted bays with low steel barriers.
- The pad rows (z −50 and z +30) break mirror symmetry. Compensate with container half-cover pieces at the missing mirror positions (z +50 and z −30, x −38/0/38), placed 6 studs off the pads so the bot volumes stay clear.

**Layout**
- **Spawns.** A: the customs office forecourt with a canopy (open slot over the strip). Its baffle is a scanner arch housing, solid, top Y 22. B: the Warehouse 9 loading dock with a roll-up door bank. The floor is the dock apron at Y 10, and its baffle is a stacked container pair.
- **Mid "Stack Yard"**
  - Containers are 8 wide, 8 tall and 20 long, aligned in a grid. No random angles in gameplay space; a tilted container may appear only as background.
  - The landmark core is a 3-high stack (Y 10–34) at the centre with the split container at its base.
  - Mid route options:
    - A container corridor at ground level (2 openings)
    - A walkway of planks over containers at Y 18 (contestable heaven, x −24..24 at z ±12)
- **Long West "Quay Edge"**
  - The quay apron at Y 10, x −125..−95, with the quay drop at x −125 into a dock basin at Y 2 (sunken tier). The basin is a walkable mudflat or ladder platform, with ladders back up. The drop edge is marked danger red.
  - Water is non-colliding and visual at Y 3, over a solid floor at Y 2, so players never fall below containment.
  - Bollards are half cover. The crane rail is flush.
  - The bend: a moored barge hull (solid, top Y 16) at z ±60.
- **Short East "Shed Row"**
  - Corrugated warehouse sheds, x 70..125, with interiors at Y 10, mezzanine offices at Y 18 and roofs at Y 26 (skylights, CanQuery false Glass, roof walkable with parapets).
  - Forklift and pallet-rack vignettes inside.
- **Connectors**
  - Straddle-carrier lanes at z ±45. A straddle carrier vehicle frame is solid at its legs only.
- **High ground.** The crane portal legs at x ±60 offer walkable machinery platforms at Y 26, reached by enclosed ladder stairs.

**Hero landmark: "Gantry 9"**
- A ship-to-shore gantry crane straddling the quay (west). Legs are at local x −130 and −110 (the leg outside the perimeter is background), with the boom at Y 90 extending out over the sea.
- An Authority anchor pod hangs from the trolley, with a teal core.
- The playable mid has the stack-yard core. The gantry is the long-range orientation landmark.

**Callouts**
- Customs, Scanner, Dock 9, Stacks, Split, Planks, Quay, Bollards, Barge, Basin/Drydock, Sheds, Office, Racks, Carrier, Gantry

**Palette**

| Role | RGB |
|---|---|
| Concrete apron | (128,130,128) |
| Asphalt | (70,72,74) |
| Steel | (98,104,110) |
| Corrugated cladding | (150,152,148) |
| Containers | maroon (120,52,50), sage (110,132,104), cream (220,208,180), mustard (186,150,70), graphite (60,64,70) |
| Harbour water | (54,78,84) |
| Rust | (128,74,52) |
| Hazard danger red | (230,60,70) on edges |
| Accent: mustard | crane and safety yellow |
| Rift teal | split container only |

**No blue or orange containers.**

**Materials**
- Concrete, Asphalt, CorrodedMetal (containers), DiamondPlate, Metal, WoodPlanks (pier planks), Water-look SmoothPlastic with Transparency 0.15 (no Terrain water inside the playable area; use Terrain water only in background if desired)

**Background**
- Near: an open sea plane west and east beyond the quay (non-colliding Part at Y 3, extending to |x| 300), and further stack yards rising to Y 50 north and south.
- Mid: a moored freighter at local x −220, about 160 long, hull rising to Y 45, with a superstructure.
- Far: a breakwater with a lighthouse, distant cranes, and a headland silhouette.

**Lights (about 18)**
- Floodlight masts (4, one with shadows), shed interiors (8), customs (3), the split container glow (2), the lighthouse (1)

**Lighting preset**

| Setting | Value |
|---|---|
| ClockTime | 9.4 |
| Brightness | 2.3 |
| Ambient | (122,126,130) |
| OutdoorAmbient | (140,148,152) |
| ExposureCompensation | 0.15 |
| ColorCorrection | Tint (244,250,252), Saturation −0.04, Contrast 0.10 |
| Atmosphere | Density 0.27, Color (196,206,210), Decay (130,140,150), Haze 1.2, Glare 0.1 |
| Bloom | 0.1 |

---

### 3.5 SWITCHYARD: "Substation Delta" (cx 3700, RiftDuels, spawns ±112)

**Theme.** A rail switchyard fused with a high-voltage substation, under storm light in the late afternoon. Dark steel, ballast grey, wet concrete, and the strongest teal presence: arcing insulators.

**Story**
- *Place:* rail sidings, a signal box, a roundhouse turntable, transformer banks and a control house.
- *Event:* the seam formed between transformer banks. Lightning-like teal arcs (Beams, not lights) jump between insulators. A switching locomotive is frozen on the turntable.
- *Authority:* the yard was rewired as a "grounding grid". Grounding cages and warning beacons.

**Districts**
- A "Control House"
- B "Signal Box"
- West "Sidings"
- Mid "Turntable"
- East "Transformer Bank"

**Layout (spawns at ±112)**
- **Spawns.** A: the control house ground floor, with a strip under a light-well roof opening x −10..10, z 100..124. Its baffle is a battery-room block, top Y 24. B: the signal-box yard, with its baffle being the signal box base (brick, top Y 24).
- **Mid "Turntable"**
  - A circular turntable pit, diameter 40, centred (0,0). The pit floor is at Y 6, and the turntable bridge deck is at Y 10, spanning north-south.
  - The landmark core is the locomotive on the deck, solid and 10 tall. Its cab is enclosed and has a walkable cab roof at Y 20, reached from the pit side only.
  - The roundhouse arc to the west (stalls as cover pockets) mirrors the east-side engine shed.
- **Long West "Sidings"**
  - Parallel tracks, x −120..−70, rails sunk at Y 9. Stationary freight wagons in rows (solid, 8 tall) create two sub-lanes.
  - A footbridge over the sidings at Y 22 at z ±50 is the elevated vantage.
  - The bend is a coal hopper at z ±62.
- **Short East "Transformer Bank"**
  - A fenced compound, x 70..125. Transformers are solid 9-tall blocks with radiator fins as detail.
  - The chain-link fence is CanQuery false (transparency 0.5).
  - A cable trench at Y 4 is a sunken route under the compound, with 2 grates up.
- **Connectors**
  - Level crossings at z ±45 with barrier arms, and a relay cabinet row as half cover.
- **Elevation.** Signal gantries are walkable catwalks at Y 22, spanning the sidings, with ladders in enclosed cages. Parapets block the spawn line.

**Hero landmark: "The Arc Tower"**
- A lattice transmission tower at the mid-east (local (30,0)) base rising to Y 110, with teal arcs between insulators: Beam effects, CanQuery false, no PointLights except 2.
- It is visible from everywhere.

**Callouts**
- Control, Battery, Signal Box, Sidings, Wagons, Footbridge, Hopper, Turntable, Loco, Cab, Roundhouse, Shed, Bank, Trench, Crossing, Gantry

**Palette**

| Role | RGB |
|---|---|
| Ballast | (104,102,98) |
| Sleepers | (84,70,58) |
| Steel | (82,88,94) |
| Wet concrete | (118,122,124) |
| Brick | (118,66,54) |
| Insulator porcelain | (206,200,190) |
| Wagon livery | oxide red (124,58,48), graphite |
| Accent: warning yellow-black | (210,180,60) |
| Rift teal | arcs and cores, the strongest of any map but still ≤ 2% area |

**Materials**
- Slate (ballast), Wood, CorrodedMetal, Metal, Concrete, Brick, DiamondPlate

**Background**
- Near: more transformer bays and a perimeter of pylons with drooping cable lines (thin parts) and floodlit fence.
- Mid: a power-plant cooling tower (cylinder, Y 160) to the north and an approaching rail line on an embankment.
- Far: a storm-cloud wall. Use a dark sky, plus low hills.

**Lights (about 16)**
- Yard floodlights (4, one shadows), control house (4), signal lamps (4 small), arc glow (2), trench (2)

**Lighting preset**

| Setting | Value |
|---|---|
| ClockTime | 17.0, storm overcast |
| Brightness | 2.0 |
| Ambient | (112,118,128) |
| OutdoorAmbient | (124,132,142) |
| ExposureCompensation | 0.25 |
| ColorCorrection | Tint (236,244,250), Saturation −0.06, Contrast 0.14 |
| Atmosphere | Density 0.28, Color (150,162,172), Decay (92,100,116), Haze 1.0, Glare 0.05 |
| Bloom | 0.16 |
| Sky | an overcast grey skybox, if available |

---

### 3.6 CANYON CROSSING: "Greywater Gorge" (cx 4400, RiftDuels, spawns ±112)

**Theme.** A lush basalt river gorge with a hydro dam and steel bridges in clear late-afternoon light. Green and grey with white water, in deliberate contrast to Red Mesa's arid reds.

**Story**
- *Place:* a gravity dam spillway, a pump house, a rope-and-steel suspension bridge and a riverside gauging station.
- *Event:* the seam cracked the dam face. Water flows uphill in a teal-lit sheet (non-colliding Neon and Glass), and boulders hang suspended above the river.
- *Authority:* anchor bolts drilled into the gorge walls with cable stays holding the cracked dam.

**Districts**
- A "Pump House"
- B "Gauging Station"
- West "Cliff Path"
- Mid "Gorge Bridge"
- East "Spillway Galleries"

**Layout**
- **The river** is a sunken channel crossing the full map width at mid: z −14..14, floor at Y 3, gravel bars at Y 5, with a non-colliding water surface at Y 4.5. Containment is fine because HRP sits at 7.
- **Spawns.** A: the pump house terrace with an open-roof light well. Its baffle is a turbine housing, top Y 24. B: the gauging station deck, with its baffle being an instrument hut plus a rock outcrop.
- **Mid "Gorge Bridge"**
  - A steel truss bridge spans the river at Y 18, x −10..10, z −24..24. The deck is 8 wide with 3.5 parapets of solid steel plate on the lower half and an open truss above (CanQuery false members above Y 21.5 except the main chords).
  - Below, stepping-stone fords at Y 5 at x ±40 provide the low route.
  - The landmark core is the bridge's twin central pylons, which are solid stone piers 12×6 at z ±16..±22, rising to Y 40. **The piers block the spawn line along the bridge axis**; verify from both bridge ends.
- **Long West "Cliff Path"**
  - A basalt cliff ledge path, x −125..−90, climbing from Y 10 (at the spawns) to Y 18 near mid. The west gorge wall is the perimeter.
  - It crosses the river via a narrow rope bridge at Y 18 (x −115..−105). Rope is visual; the plank deck is solid and the side ropes are CanQuery false.
  - The bend: a rock buttress at z ±62.
- **Short East "Spillway Galleries"**
  - Concrete dam inspection galleries (tunnels) at Y 10, x 80..125. They cross under the river through a culvert at Y 4, with stairs down and up.
  - Interior rooms are valve chambers.
  - Upper exit at the spillway crest at Y 26 (the high vantage per side), reachable by internal stairs.
- **Connectors**
  - Boulder-field paths at z ±45 with mossy boulder cover (solid Rock blocks at 4–8 tall).
- **Foliage** follows rule 1.7.5: ferns are non-colliding below Y 11.5. Trees are solid trunks only, with canopies above Y 20 (CanQuery false).

**Hero landmark: "The Cracked Dam"**
- A curved concrete dam wall beyond the east perimeter, local x 150..240, rising to Y 110.
- A diagonal teal crack, with a reversed waterfall (non-colliding) climbing it and cable stays anchored on the gorge walls.
- The in-play bridge piers echo its concrete and bolt style.

**Callouts**
- Pump, Turbine, Gauge, Hut, Bridge, Piers, Ford, River, Cliff, Rope, Buttress, Gallery, Culvert, Valve, Crest, Boulders

**Palette**

| Role | RGB |
|---|---|
| Basalt | (78,82,84) |
| Wet basalt | (60,64,66) |
| Moss | (88,118,72) |
| Fern | (70,108,66) |
| Dam concrete | (168,166,158) |
| River | (70,104,104) |
| White water | (214,226,226) |
| Weathered steel | (104,96,90) |
| Accent: lichen chartreuse | (168,176,90), sparingly on rocks |
| Rift teal | dam crack and floating boulders |

**Materials**
- Basalt, Rock, Slate, Concrete, Grass, LeafyGrass, Mud, Metal, WoodPlanks

**Background**
- Near: gorge walls rising to Y 90 on the west and east perimeters (stacked Basalt column parts: a kit of hexagonal columns, which is efficient), with hanging vines as thin non-colliding parts.
- Mid: the dam (east) and a downstream waterfall gorge (west), with trees on the rim.
- Far: forested ridges and a mountain behind the dam.

**Lights (about 14)**
- Gallery tunnels (6), pump house (3), bridge lamps (3), crack glow (2, one shadows)

**Lighting preset**

| Setting | Value |
|---|---|
| ClockTime | 15.6 |
| Brightness | 2.7 |
| Ambient | (114,124,120) |
| OutdoorAmbient | (134,146,140) |
| ExposureCompensation | 0.05 |
| ColorCorrection | Tint (248,255,250), Saturation 0.04, Contrast 0.1 |
| Atmosphere | Density 0.25, Color (196,214,206), Decay (110,130,130), Haze 1.0, Glare 0.2 |
| Bloom | 0.12 |

---

### 3.7 OLD TOWN: "San Corvo" (cx 5100, RiftDuels, spawns ±112)

**Theme.** A Mediterranean hill town in golden-hour light: whitewash, terracotta, warm stone and sage shutters. It is the signature warm map and the closest to the current RiftSunsetSky mood.

**Story**
- *Place:* a piazza with a fountain, a clock tower, arcaded market streets, stair-alleys, an aqueduct and a chapel.
- *Event:* the clock hands stopped at the moment of the rift. The fountain water hangs in a teal arc and laundry lines are frozen mid-flutter.
- *Authority:* sandbagged arcades, anchor pylons disguised in the bell loft, and cordon tape in the alleys.

**Districts**
- A "Upper Gate"
- B "Harbour Steps"
- West "Aqueduct Walk"
- Mid "Piazza del Orologio"
- East "Market Arcades"

**Fixes to the current map**
- It has isolated houses in an open courtyard and over-long sightlines. Replace them with continuous town blocks that form alleys.
- Remove stray arches and stone blocks.

**Layout**
- **Spawns.** A: the town-gate courtyard inside the walls, with an arch gate behind and its baffle a well-house (top Y 24). B: the harbour-steps landing, with its baffle a chapel apse (top Y 26).
- **Mid "Piazza"**
  - A compact piazza, x −26..26, z −26..26, ringed by 2–3-storey buildings with arcades.
  - The clock tower is the landmark core at (0,0): an 12×12 base, solid, rising to Y 74.
  - The fountain is not in mid, so the tower blocks the spawn axis. The fountain sits in a side court at (−40,0), twin (40,0), as a low basin (half cover).
  - Upper loggias at Y 18 overlook the piazza from the east corners, x 18..26, at z 18..26 and its twin at z −26..−18.
- **Long West "Aqueduct Walk"**
  - The aqueduct runs north-south at x −100..−92 with its walkable channel top at Y 26 (the high lane), with parapets.
  - Beneath, an arched street at Y 10 with arches every 12 studs gives a long but broken sightline.
  - Access is by stair towers at z ±70 and a mid-point ladder stair at z 0.
  - The bend: a chapel buttress at z ±60.
- **Short East "Market Arcades"**
  - Vaulted market streets, x 70..125, with stall blocks as cover, an upper gallery at Y 18 and stair-alleys climbing toward the spawn sides.
- **Connectors**
  - Stair-alleys at z ±45 that rise Y 10 → 14 → 10 over a hump bridge across a dry canal (Y 6), with laundry lines (CanQuery false).
- **Rooftops**
  - Terracotta roof walks at Y 26 over two blocks per side, reachable by an internal stair. Roof slopes are not walkable: they are steep wedge parts, so players walk only on parapeted flat terraces.

**Hero landmark: "Torre dell'Orologio"**
- A stone clock tower with a bell loft (Y 56–66) and a teal-glow clock face stopped at 4:17. The hands are graphite and the face has a teal ring.
- An Authority anchor sits visible inside the bell loft.

**Callouts**
- Gate, Well, Steps, Chapel, Piazza, Tower, Loggia, Fountain, Aqueduct, Arches, Buttress, Market, Gallery, Canal, Hump, Roofs

**Palette**

| Role | RGB |
|---|---|
| Whitewash | (226,218,200) |
| Warm limestone | (198,174,136) |
| Terracotta | (176,94,64), roof tiles only; desaturated relative to team orange |
| Sage shutters | (110,132,104) |
| Ochre plaster | (196,156,96) |
| Cobble | (130,120,108) |
| Dark wood | (86,64,48) |
| Accent: bougainvillea magenta | (168,64,110), a few planter blooms above Y 14 |
| Rift teal | clock face and frozen fountain arc |

Terracotta sits close to team orange. Keep it on roofs above Y 22 and away from the B-spawn area. Use whitewash and sage at B-side street level so team orange remains unique.

**Materials**
- Plaster (whitewash), Limestone, Cobblestone, Brick (arches), Wood, Slate (roof tiles via colour, or clay-roof material if available)

**Background**
- Near: a hill town that cascades down and away: stepped house rows (a kit of 3 house shells) climbing to the north (A side, uphill to Y 70) and falling toward the harbour south.
- Mid: a sea bay with fishing boats to the south and olive-terrace hills.
- Far: a coastal headland and distant islands, with the sunset sky retained.

**Lights (about 20)**
- Wall lanterns (10), arcade (4), loggia (2), clock face (2, one shadows), chapel (2)

**Lighting preset**

| Setting | Value |
|---|---|
| ClockTime | 17.4 |
| Brightness | 2.5 |
| Ambient | (124,112,108) |
| OutdoorAmbient | (150,132,120) |
| ExposureCompensation | 0.1 |
| ColorCorrection | Tint (255,244,232), Saturation 0.02, Contrast 0.1 |
| Atmosphere | Density 0.22, Color (236,200,170), Decay (150,110,120), Haze 0.9, Glare 0.4 |
| Bloom | 0.14 |
| Sky | RiftSunsetSky |

---

## 4. TRAINING ARENA: "Rift Authority Proving Campus, Range One"

Located at `workspace.RiftArena` (a Folder, cx 0).

### 4.1 Hard constraints (from the preservation inventory)
- **Own grid:** X ±147, Z −257..151, Y 5..155.
- Invisible containment blockers recreate the current four: N at z −260, S at z 154, E and W at x ±149, each 180 tall. Do not author code-referenced names.
- **Spawn and Aim:** `Spawn` (0,14,110.7) with floor Y 10; `Aim` (0,14,0). Keep both, and do not move the spawn unless the attribute is updated.
- **`Targets` folder:** untouched. That includes Training Targets 1–6 at (laneX, 12.65, −85) and the 24 explore-map bots at X 662–2838 that live in this folder.
- **Lanes:** laneX = −110, −66, −22, 22, 66, 110. The firing point is (laneX, 14, −5) with floor at Y 10.
  - **Keep each lane clear of anything with CanQuery = true over laneX ±12, Z −5..−230, below Y 20.**
  - Drill targets stand at Z −45/−50, −85 and −225.
- **Lane dividers and structures** go only at X 0, ±44 and ±88, at most 18 wide (|x − divider| ≤ 9).
- **Fix the Precision blocker:** delete `GapClosureWalls.Range rear closure` (z −200), or move it behind z −235. The side closures at x ±146 can stay or be replaced by the new perimeter.
- **Drill console:** exactly 5 BaseParts as direct children of RiftArena, at Z 104. Keep X at −105, −55, 0, 55 and 105, ordered left to right. Size 8×4×4, top Y 14.
  - The player must be able to stand within 15 studs. No authored prompts or Guis.
  - Restyle is allowed as long as the part stays a single BasePart with the same name.
- **Audio:** keep `Audio` with "Ambience" and "Music".
- **Overhead target-carrier rails** at Y 28 are CanQuery false.
- **Check** that the "Firing station top" parts and the columns at x ±112 no longer overlap the lane start points.

### 4.2 Theme and story
This is the Rift Authority's flagship operator academy: a premium near-future tactical training campus where recruits certify before deployment to seam zones.

- The language is clean, engineered architecture: cool white composite panels, graphite steel, brushed metal, glass observation galleries and precise teal light lines.
- It is the most "Authority" space in the game and the purest expression of the brand, but it stays bright and neutral for aim training.
- *Storytelling:* a contained micro-seam is displayed in a stabiliser vitrine at the campus atrium, used to "calibrate" recruits. Certification boards list fictional operator callsigns. Weapon racks are labelled by class.

### 4.3 Zones (world = local, cx 0)

| Zone | Range | Description |
|---|---|---|
| Entrance Atrium / Spawn Hall (indoor) | x −60..60, z 80..150 | Double-height hall, ceiling Y 34 with a skylight band, glass facade facing the range. Spawn at (0, 10, 110.7) in a clear 20×12 zone. The five Drill consoles stand in a line at z 104 as illuminated "command pedestals" with a graphite body, white top, teal edge line and a SurfaceGui-free look. The atrium centrepiece is the **Calibration Vitrine** at (0, 10, 135): a glass cylinder (CanQuery false) with a teal seam core, behind the spawn so it does not obstruct the console line. Entrance header sign "RIFT AUTHORITY / RANGE ONE" at (0, 29, 143). |
| Weapon Test Bay (indoor, east wing) | x 70..140, z 70..140 | Weapon racks per class (display only), the "Test next primary" console 4 at x 55 sits at its threshold, test benches, and a short 25-stud calibration lane against a steel backstop at x 135 running east-west (not in the main lanes). |
| CQB Reaction House (indoor, west wing) | x −140..−70, z 60..140 | A two-storey kill-house shell (Y 10 and Y 18) with modular rooms, doorways 6×8, a catwalk observation rail above (Y 26). Walkable and explorable; future drills could use it. No runtime dependency. Pop-up target silhouettes are decorative plywood shapes (CanQuery true, so players can shoot them as free-fire). |
| Lockers and Ready Room | along z 120..140, x ±75..95 | Lockers stay in this area. |
| Firing Hall (indoor/outdoor threshold) | x −140..140, z −20..40 | A long canopy roof at Y 30 over the firing line, supported only on divider lines (x 0, ±44, ±88) and the outer walls. Six firing booths at z −9..−3: desks with lane numbers "01"–"06" enamel plates at (laneX, 11.4, −7.4). Desks must not sit on (laneX, −5); place them as side counters at laneX ±7. Lane-number lightboxes hang above each booth at Y 24 (CanQuery false). |
| Observation Deck | Y 24.5 mezzanine over z 30..70, full width | Glass front (CanQuery false), reached by stairs at x ±128 (rebuild the existing stair at x 128 plus a twin at −128). Control booth "Range Control" at (0, 24.5, 50) with consoles and monitor walls (illuminated SurfaceGui-free screens: Neon-free SmoothPlastic emissive colours plus 2 SurfaceLights). |
| Outdoor Grounds, Lanes (open air) | z −20..−245 | Floor Y 10, lane surface DiamondPlate-texture concrete with painted lane edges at laneX ±12 (decals or flush 0.05 parts). Distance markers at z −45, −85, −145 and −225: flush floor stripes plus divider-mounted signs "40", "80", "140", "220". |
| Spray-Control Wall | on the dividers at z −80..−95 | Pattern boards showing recoil-pattern dot graphics, 16 wide, CanQuery false, mounted on divider pylons, readable from each adjacent lane. |
| Moving-target infrastructure | overhead Y 28 | Carrier rails spanning each lane between dividers (CanQuery false), with trolley housings parked at the dividers. Floor tracks are flush (Y 10.05, CanQuery false or flush). |
| Long-range Precision zone | z −205..−245 | Raised berm terraces beyond z −235 as backstop scenery. A "Precision" gantry sign over the dividers at Y 30 (CanQuery false). Recoil backboards behind Z −235 only (current ones at −243 are OK). Back wall "Precision terminal wall" at z −254 stays, or is rebuilt at z −250..−256. |
| Lane dividers | x 0, ±44, ±88, z −20..−240 | Low graphite blast walls, 1.5 wide, 4 tall (top Y 14), with teal 0.2 top-edge light lines. Tall divider pylons, 4×4, rising to Y 26, every 40 studs, carry signage and the spray boards. Everything within |x − divider| ≤ 9. |
| Outer grounds (outside lanes) | x ±123..147 | Grass verges, perimeter security fence (solid concrete base to Y 14, mesh above CanQuery false), sensor masts, flag poles with the Authority emblem. |

### 4.4 Sightlines and readability
- Every lane must keep a pure, uncluttered sightline. The background behind targets at z −45, −85 and −225 must be mid-value and plain:
  - Z −45 and −85 have the far berm or backboards behind them.
  - Graphite backboard panels (60,64,70) behind the Precision zone give the teal-headed targets maximum contrast.
- Bots have teal heads (the head colour is part of the target rig). **No teal anything behind a target zone in the silhouette band**, so no teal lines on the backboards.

### 4.5 Palette

| Role | RGB |
|---|---|
| Composite white | (214,220,226) |
| Light grey panel | (176,182,190) |
| Graphite | (46,50,58) |
| Steel | (120,126,134) |
| Lane concrete | (138,140,142) |
| Turf verge | (96,124,82) |
| Rift teal | (0,224,204) in narrow lines |
| Wayfinding white | (240,240,236) |
| Lane-number amber | (232,190,90), the only warm accent |

### 4.6 Materials
- SmoothPlastic, Metal, DiamondPlate, Concrete, Glass (CanQuery false), Grass, Fabric (ready room)

### 4.7 Background
- Beyond the X ±147 limit, the background needs a different limit. Neighbours are at X −700 (Lobby) and +700 (Pine Ridge), so stay within |x| ≤ 320, z −420..320.
- North beyond the range: a stepped earth berm and a forest edge rising to Y 50, plus campus outbuildings (hangar shells and a comms tower to Y 120).
- South behind the atrium: a campus quad and further academy buildings.
- East and west: a sports-field-like outdoor obstacle course (visual only) and a heliport pad with a parked tiltrotor silhouette.

### 4.8 Lights (≤ 30)
- Atrium (6, one shadows)
- Console pedestals: no lights, emissive look only
- Firing hall canopy SurfaceLights (6)
- Observation deck (4)
- CQB house (6)
- Test bay (4)
- Vitrine (1)
- Range floods (3, no shadows)

### 4.9 Lighting preset (switcher)

| Setting | Value |
|---|---|
| ClockTime | 14.5 |
| Brightness | 2.8 |
| Ambient | (132,134,140) |
| OutdoorAmbient | (148,150,154) |
| ExposureCompensation | 0.05 |
| ColorCorrection | Tint (250,252,255), Saturation 0.0, Contrast 0.08 |
| Atmosphere | Density 0.18, Color (210,220,228), Decay (150,160,175), Haze 0.5, Glare 0.15 |
| Bloom | 0.1 |

This is the clearest, least hazy preset, for aim training.

---

## 5. Cross-map variety matrix

| Map | Time | Temperature | Base hues | Accent | Mid landmark | Low route | High route |
|---|---|---|---|---|---|---|---|
| Pine Ridge | 11.2 | cool-fresh | timber, moss, slate | mustard | Sawmill + Lookout tower | creek, fissure trench | gantry, footbridge |
| Red Mesa | 13.8 | hot | red rock, sand, adobe | safety yellow | Pit + headframe | pit bowl | benches, conveyor |
| Metro District | 18.6 | dusk, cool + warm | brick, concrete, amber | transit green | Viaduct + train | fountain basin | track deck, rooftops |
| Dockyard | 9.4 | grey-cool | steel, concrete, muted containers | mustard | Stack + split container | dock basin | container planks, crane decks |
| Switchyard | 17.0 storm | dark-cool | ballast, steel, oxide | warning yellow | Turntable + loco | cable trench | signal gantries |
| Canyon Crossing | 15.6 | green-fresh | basalt, moss, white water | lichen | Truss bridge + piers | river ford, culvert | bridge, spillway crest |
| Old Town | 17.4 | golden | whitewash, limestone, terracotta | magenta bloom | Clock tower piazza | dry canal | aqueduct, roof terraces |
| Training | 14.5 | neutral-bright | white composite, graphite | lane amber | Calibration vitrine | — | observation deck |

## 6. Build order and verification checklist (per map)
1. Back up the map: already done in `RiftBackup_2026-11-06_preStage7`.
2. Rebuild **in place**: keep the map Model's name, attributes and Audio folder. Clear the old contents in chunks.
3. Gameplay blockout: Gameplay folder only. Run these raycast checks:
   - spawn strips clear, with Y 10 floors at x −6/0/+6
   - no spawn-to-spawn sightline, from every spawn-side vantage
   - 8-stud down-ray hits a map part on every walkable surface
   - perimeter inner face ≤ 139
   - no reachable surface > Y 48
   - practice-target pads clear (RiftMaps only)
4. Architecture and primary forms, then secondary, then tertiary/story. Chunk ≤ 400 instances per parent operation.
5. Background ring, with all four collision/query/touch/shadow flags false.
6. Lights within budget. Record the lighting preset values in the map's attributes? **No.** Avoid new attributes on map Models. Keep presets in this document, or in a future ModuleScript owned by the switcher.
7. Final counts: BaseParts 4,000–9,000, lights ≤ 40 (shadows ≤ 4), particles ≤ 6. Screen captures from both spawns, mid and an overview.
