PROPOSAL ONLY — nothing applied, awaiting owner approval.

# Rift Stage 8: gunplay audit and final rework proposal

- This document was produced by a read-only audit of the live Studio session (studio 93e180b3…, Edit DataModel). No script or instance was edited, no playtest was started, and nothing was saved or published.
- It starts from Proposal 0, the highest-scoring proposal (judge average 6.8). It adds the phased rollout and minimal call-site approach from Proposal 2, and the readable band/archetype ideas from Proposal 1. It also fixes every judge-flagged problem, plus one bug the judges missed: under P0's heat model, automatics never built heat (see 3.3).
- TTK was recomputed for this document by `/private/tmp/claude-501/-Users-jeffr-Documents-Rift-Animations/95ac1ee0-bbef-4655-aba5-871cd0444a02/scratchpad/final2.py`. That script uses Luau `math.round` (that is, `floor(x+.5)`) once per trigger pull. The heat model was simulated in `/private/tmp/claude-501/-Users-jeffr-Documents-Rift-Animations/95ac1ee0-bbef-4655-aba5-871cd0444a02/scratchpad/heat.py`.
- TTK conventions:
  - Time runs from the first shot to the killing shot, with every shot landing and the target at 100 HP.
  - "+R" means the kill needs a reload, and the reload time is included.
  - Shotgun rows assume every pellet hits the same zone.

---

## 1. Summary

- **Damage.** Today's 5-damage automatics need 20 body or 13 head shots, and Scout and Viper cannot finish a body-shot kill without reloading.
  - After the change, every gun kills in 1–6 body shots at 10 studs.
  - Rifles, marksman rifles, snipers, Kestrel and Warden one-tap to the head in their effective band. SMGs and pistols two-tap the head up close.
  - Body TTK for automatics drops from 1140–2040 ms to 225–420 ms.
- **Accuracy.** Accuracy becomes Valorant-like:
  - A first shot is exact only when the player is grounded, has been on the ground for at least 0.3 s, is moving under 2.5 studs/s, and is cooled down. This applies to ADS as well, so the walk-speed loophole from `speed<18` is closed.
  - Walking with a rifle adds about 4.5°, whether hip or ADS. Air penalties are per weapon (2.5–14°) and include a landing tail.
  - Crouching gives ×0.75 spread. Shotguns are no longer immune to movement.
- **Spray.** Spray gets learnable, server-authoritative recoil:
  - A per-weapon deterministic pattern (climb, then sway) is applied by the server to the bullet direction.
  - "Heat" with a per-weapon `recover` value replaces the 0.28 s reset cliff.
  - The client punches the camera visually, strips that punch from the look vector it sends, and does not auto-recover while firing.
- **Sidegrades.** Damage bands replace falloff that currently never triggers. Each pair now wins somewhere: Vanguard/Talon/Longshot, Vector/Sentinel/Longshot, Warden/Kestrel/Scout, and SMGs versus rifles.
- **Rollout.** Ship in two phases to limit risk, because other agents are editing the same scripts:
  - Phase 1: stats, bands and the new `Error` constants on the existing call site.
  - Phase 2: heat, server pattern, client camera, pellet layouts and crosshair.

---

## 2. How accuracy works today, and the gaps

### 2.1 Today (exact, from the code)

- **Server spread** is computed by `RiftBallistics.Error(w, moving, airborne, ads, index)` and returns the cone half-angle in degrees.
  - It returns 0 when `index==1`, the player is grounded, and either ADS is on or the player is hipfiring with `moving<.08` on a weapon that is not sniper or marksman.
  - Otherwise it returns `base*(.18+min(i/14,.7)) + moving*(ADS .25 | precision 1.25 | other .65) + (air and 2)`.
  - `moving = speed/20`.
  - The call site is `RiftCombat` L313, where `ads = aiming==true and speed<18`. Walk speed is 17, so walking counts as aiming still.
- **Cone sampling** is `sqrt(rand)*tan(deg)` (L168), which spreads hits uniformly over the disk.
- **Spray index:** `s.spray` resets to 1 after a gap of more than 0.28 s (L300). The client copies this on its own clock.
- **Recoil is client-only.**
  - `Ballistics.Pattern` gives `pitch = pitchKick*(.42+.38*min(i/7,1))` (×0.65 when ADS) and `yaw = sin(i*.72+finish)*min(i/10,1)*.32*pitchKick`.
  - The yaw is not scaled when ADS.
  - The camera rotates for real and auto-recovers with `exp(-dt*5)` even while firing, so the climb levels off at about 1.2°.
  - The server only sees where the camera points.
- **Shotguns** skip `Error` and use a flat `ads`/`hip` cone with random pellets.
- **Crouch** (`RiftCrouching`) is never read by combat code.
- **Crosshair:**
  - It is four bars with a fixed ±8 px gap, and only their `UIScale` changes.
  - It uses 0.25 s and /20 where the server uses 0.28 s and /14.
  - It ignores walking, air, crouch and the weapon's base spread.
- **Damage:** per-pull `math.round(sum of pellets*head*falloff)`.
  - Hitscan falloff is 1 up to `range` (150–650), so it never triggers at real distances.
  - Shotguns use `clamp(1.2-d/range,.15,1)`.
  - Launchers: the struck target takes `directDamage` only, splash deals `bodyDamage`, and splash has no falloff and no headshots.
- **Arsenal UI** (L157/177/180) shows shotguns as `bodyDamage × pellets`, but the server deals `bodyDamage/pellets` per pellet.

### 2.2 Gaps against the Valorant-feel goal

1. **ADS while moving is accurate.** The first shot is free at walk speed, and the ADS movement term is only about 0.21°.
2. **The movement penalty is tiny.** It is at most +0.65° hip, and there is no curve on speed.
3. **Air** is a flat +2° for every gun, with no landing recovery. `FloorMaterial` flickers on stairs.
4. **Crouch** has no accuracy effect.
5. **Spray is a random cone.** The camera pattern self-recovers, so there is nothing to learn, and recoil can be skipped by an exploit that does not rotate the camera.
6. **The 0.28 s reset is a hard cliff.** Whether a semi-auto blooms depends on whether its interval happens to be above or below 0.28 s: Scout and Viper bloom, Warden and Kestrel do not.
7. **The crosshair does not show real spread.**
8. **Shotguns ignore movement, air and spray.** Pellets are random, not a fixed layout.
9. **TTK is not headshot-centric.** 1.6× multipliers on 5-damage guns give no one-tap tier, and there are near-miss breakpoints (Kestrel 32×3=96, Carbine 22×4=88, Talon 11×9=99).
10. **Falloff is dead for hitscan weapons**, so the pairs below are tiers rather than sidegrades.
11. **The server trusts the `aiming` flag**, including during reload, with no scope-in time.
12. **Small issues:**
    - Arsenal shows the wrong shotgun damage.
    - A `RiftWeapons` comment says "standard automatics stay at 5".
    - Longshot is family `marksman`, so it loses the hip first-shot exemption.

---

## 3. Global accuracy changes (RiftBallistics, RiftCombat, RiftClient)

### 3.1 New `B.Error`

Changes from Proposal 0:
- Crouch applies whenever the player is grounded, not only when standing still.
- The shotgun branch no longer stacks base on top of growth and has a cap.
- The first-shot test uses `heat <= 0`.

```lua
-- speed: horizontal root speed (studs/s); heat: see 3.3; crouched: RiftCrouching attribute
-- sinceLand: seconds since FloorMaterial stopped being Air (also debounces stair flicker)
-- adsReady: aiming and not reloading and aim held >= w.adsTime (see 3.5)
function B.Error(w, speed, airborne, adsReady, heat, crouched, sinceLand)
 if w.item then return 0 end
 local base  = adsReady and w.ads or w.hip
 local still = speed < 2.5
 local m     = math.clamp((speed - 2.5) / 14.5, 0, 1.3)      -- 0 still, ~.45 crouch-walk(9), 1 walk(17), 1.3 sprint/slide
 local move  = w.run * m^1.4 * (adsReady and .85 or 1)        -- ADS barely helps on the move
 local air   = airborne and w.air
            or (sinceLand < .3 and w.air * .5 * (1 - sinceLand/.3) or 0)
 local crouch = (crouched and not airborne) and (w.crouchMult or .75) or 1
 if w.pellets then                                            -- shotguns: flat cone + movement/air, optional capped growth
   local grow = base * math.min(heat * (w.grow or 0), w.growMax or 0)
   return (base + grow + move) * crouch + air
 end
 local first = heat <= 0 and still and not airborne and sinceLand >= .3
               and (adsReady or w.hipFirst ~= false)
 local spray = first and 0 or base * math.min(.3 + heat * w.grow, w.sprayMax)
 return (spray + move) * crouch + air
end
```

| Situation (Vanguard: hip 1.1, ADS .30, run 4.5, air 7) | Today | Proposed |
|---|---|---|
| Standing first shot, hip or ADS | 0° | 0° |
| Walking first shot, hip | 0.88° | ≈4.8° |
| Walking first shot, ADS | 0° | ≈3.9° |
| Crouch-walking (speed 9), hip | ≈0.6° | ≈1.3° |
| Airborne | +2° | +7°, with a 0.3 s landing tail |
| ADS spray, standing, shot 6 | ≈0.3° random | ≤0.27° random cone, plus the pattern (2.1° up) |

**Cone sampling:** switch to `r = rand*tan(deg)` so hits cluster toward the centre. This is Phase 2, so the effect of the new numbers can be tested on its own first.

### 3.2 Call site, `RiftCombat` L313

**Phase 1 (minimal):**
```lua
spread = Ballistics.Error(weapon, speed, h.FloorMaterial == Enum.Material.Air,
  aiming == true and not s.reloading,         -- drops the speed<18 rule
  s.spray - 1,                                 -- heat stand-in until Phase 2
  char:GetAttribute("RiftCrouching") == true,
  s.sinceLand or 1)
```
- Shotguns now also go through `Error`, so the `weapon.pellets and (...)` branch is removed.
- Phase 1 keeps the 0.28 s reset, so `heat = spray-1` reproduces today's index behaviour.

**Phase 2:**
- Track `s.landedAt`: update it on the Heartbeat transition from Air to ground, debounced 0.1 s.
- Track `s.heat` (3.3).
- Track `s.aimStart` (3.5).

### 3.3 Heat replaces the 0.28 s cliff (Phase 2; server and client use the same code)

```lua
local grace = w.auto and w.interval * 1.15 or 0      -- autos: no decay while the trigger is held
heat = math.max(0, heat - math.max(0, gap - grace) / w.recover)
-- Error uses this heat; pattern index = math.floor(heat) + 1; then:
heat = math.min(heat + 1, w.heatMax or 20)
```

**Fix to Proposal 0.** P0 used `heat -= gap/recover` with `recover ≈ interval` on automatics. Under held fire that decayed about 1 heat per shot:
- Spectre, Needle and Ember stayed at heat 0.
- Vanguard rose only 0.045 per shot.

The result was a laser for the whole magazine with no pattern climb. The grace term makes held fire climb exactly 1 per shot. Simulated:
- Vanguard, 10 shots held: heat 0, 1, …, 9.
- Release for 0.5 s: heat 3.7. Release for 0.75 s: heat 0.
- Three-round bursts every 0.35 s: each burst starts at heat 0.

**Semi-autos** (`auto` false) decay over the full gap, so `recover` is the tap cadence that keeps every shot exact. Firing at max rate builds bloom (simulated over 5 shots):

| Weapon | Fire interval | `recover` (exact cadence) | Heat at shot 5 when spammed |
|---|---|---|---|
| Scout | .24 | .30 | .8 |
| Viper | .15 | .22 | 1.27 |
| Longshot | .24 | .32 | 1.0 |
| Vector | .42 | .50 | .64 |
| Kestrel | .34 | .38 | .42 |
| Warden | .42 | .45 | .27 |
| Sentinel | .68 | .75 | .37 |
| Horizon | 1.25 | 1.25 | always 0 |

`w.auto` means whatever field RiftClient already uses for hold-to-fire. If no such field exists, add `auto=true` to ids 1, 5, 9, 10, 11, 12, 17 and 20.

### 3.4 Movement, air and crouch fields (per weapon, see section 4)

- **`run`:** degrees added at walk speed (17).
  - Crouch-walk adds about 0.33×.
  - Sprint and slide add about 1.44×.
- **`air`:** degrees added while airborne. Half of it is added at the moment of landing, fading to 0 over 0.3 s. The landing tail also debounces stair and ledge flicker.
- **`crouchMult`:** ×0.75 by default and ×0.6 on Anchor. It applies whenever the player is grounded and crouched.
- **Pattern scaling:** crouching also scales the pattern by ×0.85 (×0.7 on Anchor).

### 3.5 ADS validation (Phase 2)

- The client sends `aiming` from its stricter `ads` local, which excludes reloading and sliding.
- The server records `s.aimStart` when `aiming` turns true, and sets `adsReady = aiming and not s.reloading and now - s.aimStart >= w.adsTime`.
  - `adsTime`: .15 s for rifles, SMGs and pistols; .22 s for marksman rifles; .30 s for snipers.
  - This is a new signal: the server currently only gets `aiming` per shot. Either send an `aim` toggle remote, or send `aimHeld` seconds and clamp it on the server.

### 3.6 Damage falloff uses distance bands

- **New field:** `bands = {{maxDist, mult}, …}`. `B.Falloff` returns the multiplier of the first band with `d <= maxDist`.
  - Weapons without bands return 1.
  - Pellet weapons use bands instead of `clamp(1.2-d/range)`.
  - Blast weapons still return 1.
- **`range` is not touched,** because `TraceRange` uses it for trace length.
- **Breakpoint margin:** every one-tap is at least 101, and no value lands on a .5 rounding edge.

### 3.7 Crosshair (Phase 2)

- The gap is `8px + tan(B.Error(...))*focal`, computed with client speed, `FloorMaterial`, crouch, adsReady and client heat.
- This removes the hard-coded 0.25 s and /20 constants.
- Optional setting: a static Valorant-style crosshair with a movement-error flash.

### 3.8 Other fixes (Phase 1)

- **Arsenal:** show pellet weapons as "`bodyDamage` total (`bodyDamage/pellets` × `pellets`)".
- Delete the "standard automatics stay at 5" comment in `RiftWeapons`.
- **Longshot:** set `hipFirst=true`. Family stays `marksman` for display only.
- **Launchers:** keep no headshots and no blast falloff. They go through the non-pellet branch with `grow=0` and `sprayMax=.3`.

### Phase split

| Phase 1 (low risk, one call-site line plus data) | Phase 2 (feel overhaul) |
|---|---|
| All section-4 damage, interval and mag numbers; `bands` | Heat and `recover` (3.3) |
| `B.Error` with `run`/`air`/`crouchMult`/`hipFirst`, `heat = spray-1` | Server-authoritative pattern, client punch and strip (section 5) |
| Closing the ADS-walk and ADS-reload holes; shotguns through `Error` | `adsTime` scope-in, `sinceLand` tracking |
| Arsenal fix, comment removal, Longshot `hipFirst` | `rand` cone sampling, fixed pellet layouts, dynamic crosshair |

---

## 4. Per-weapon changes

Notation: `current -> proposed`. Fields not listed are unchanged.

### 4.1 Damage, fire rate and bands

| id | Name | Field changes |
|---|---|---|
| 1 | Vanguard Rifle | bodyDamage 5→29; headMultiplier 1.6→3.55; bands {25:1, else .84}; hip 1.3→1.1; ads .36→.30 |
| 2 | Scout Pistol | bodyDamage 5→34; headMultiplier 1.6→3.0; bands {20:1, 40:.88, else .8}; hip 1.45→1.2; ads .48→.40 |
| 3 | Longshot Carbine | bodyDamage 14→38; headMultiplier 1.6→2.7; interval .19→.24; hip 1.1→1.4; ads .23→.20; hipFirst true |
| 4 | Viper Pistol | bodyDamage 5→25; headMultiplier 1.6→3.0; bands {20:1, else .85}; hip 1.65→1.5; ads .58→.50 |
| 5 | Rush SMG | bodyDamage 5→26; headMultiplier 1.6→2.7; bands {15:1, 35:.85, else .7}; hip 2.0→1.6; ads .68→.60 |
| 6 | Breach Shotgun | bodyDamage 40→104 (13/pellet × 8); headMultiplier 1.45→1.5; bands {12:1, 25:.8, 40:.55, else .3}; hip 5.7→5.2; ads 3.7→3.2 |
| 7 | Horizon Sniper | bodyDamage 35→105; interval 1.0→1.25; reload 1.9→2.1; hip 4.2→5.0; ads .065→.05; hipFirst false |
| 8 | Arc Launcher | directDamage 60→75; bodyDamage (splash) 40→45; reload 1.85→1.6 |
| 9 | Spectre SMG | bodyDamage 5→25; headMultiplier 1.6→2.6; bands {20:1, 40:.88, else .75}; hip 1.6→1.4; ads .50→.45 |
| 10 | Talon Rifle | bodyDamage 7→30; headMultiplier 1.6→3.4; bands {50:1, else .9}; hip 1.5→1.2; ads .38→.30 |
| 11 | Anchor LMG | bodyDamage 6→25; headMultiplier 1.6→3.0; bands {40:1, else .88}; hip 2.7→2.2; ads .85→.60; crouchMult .6 |
| 12 | Needle PDW | bodyDamage 5→20; headMultiplier 1.6→2.8; bands {12:1, 30:.8, else .6}; hip 2.4→2.0; ads .82→.75 |
| 13 | Hammer Shotgun | bodyDamage 65→117 (13/pellet × 9); headMultiplier 1.25→1.3; bands {10:1, 20:.7, 35:.45, else .2}; hip 6→5.8; ads 4.5→4.2 |
| 14 | Vector DMR | bodyDamage 22→55; headMultiplier 1.6→2.0; interval .30→.42; mag 12→10; reload 1.5→1.6; bands {50:1, else .88}; hip 1.6→3.0; ads .15→.12; hipFirst false |
| 15 | Sentinel Sniper | bodyDamage 30→75; ads .09→.07; hipFirst false |
| 16 | Warden Revolver | bodyDamage 28→52; headMultiplier 1.6→2.0; bands {25:1, 45:.85, else .7}; hip 1.5→1.3; ads .30→.25 |
| 17 | Ember Auto Pistol | bodyDamage 5→20; headMultiplier 1.6→2.8; bands {15:1, 30:.85, else .7}; hip 2.5→2.2; ads .95→.85 |
| 18 | Kestrel Heavy Pistol | bodyDamage 20→34; headMultiplier 1.6→3.0; no bands; hip 1.6→1.3; ads .35→.28 |
| 19 | Nova Launcher | directDamage 60→70; bodyDamage (splash) 40→45; reload 2.5→2.3 |
| 20 | Drift Auto Shotgun | bodyDamage 25→63 (9/pellet × 7); headMultiplier 1.3→1.4; bands {10:1, 20:.75, 35:.52, else .3}; hip 6.8→6.0; ads 4.5→4.0 |

### 4.2 New accuracy fields

All values are in degrees except `recover` and `adsTime` (seconds). `pattern = {climb, n, sway}`, as defined in section 5.

| id | run | air | grow | sprayMax | recover | adsTime | pattern | auto |
|---|---|---|---|---|---|---|---|---|
| 1 Vanguard | 4.5 | 7 | .14 | .9 | .06 | .15 | {.42, 7, 1.1} | yes |
| 2 Scout | 2.6 | 5 | .30 | 1.0 | .30 | .15 | {.55, 3, .4} | |
| 3 Longshot | 4.0 | 7 | .35 | 1.0 | .32 | .22 | {.8, 3, .3} | |
| 4 Viper | 2.2 | 4.5 | .25 | 1.1 | .22 | .15 | {.45, 4, .5} | |
| 5 Rush | 1.4 | 3.5 | .10 | 1.0 | .05 | .15 | {.25, 6, .9} | yes |
| 6 Breach | 1.5 | 3 | 0 | – | .66 | .15 | fixed pellet layout | |
| 7 Horizon | 9 | 14 | 1.0 | 1.0 | 1.25 | .30 | {2.0, 1, 0} | |
| 8 Arc | 1.5 | 3 | 0 | .3 | – | .15 | none | |
| 9 Spectre | 1.2 | 3.5 | .09 | .85 | .05 | .15 | {.22, 6, .7} | yes |
| 10 Talon | 5.0 | 8 | .16 | .95 | .07 | .15 | {.5, 6, 1.4} | yes |
| 11 Anchor | 5.5 | 8 | .08 | 1.0 | .08 | .15 | {.35, 10, 1.8} | yes |
| 12 Needle | 1.0 | 3 | .08 | 1.0 | .045 | .15 | {.18, 8, 1.0} | yes |
| 13 Hammer | 1.5 | 3 | 0 | – | .85 | .15 | fixed pellet layout | |
| 14 Vector | 6 | 10 | .5 | 1.0 | .50 | .22 | {1.1, 2, .2} | |
| 15 Sentinel | 8 | 12 | 1.0 | 1.0 | .75 | .30 | {1.6, 1, 0} | |
| 16 Warden | 3.0 | 5 | .40 | 1.2 | .45 | .15 | {.9, 2, .3} | |
| 17 Ember | 1.6 | 3.5 | .10 | 1.1 | .05 | .15 | {.2, 6, 1.0} | yes |
| 18 Kestrel | 3.0 | 5 | .40 | 1.1 | .38 | .15 | {.8, 2, .3} | |
| 19 Nova | 2.0 | 4 | 0 | .3 | – | .15 | none | |
| 20 Drift | 1.0 | 2.5 | .05 (growMax .3) | – | .45 | .15 | fixed pellet layout | yes |

### 4.3 TTK before → after

Each cell is `damage × shots = TTK ms`.
- Hitscan "before" values are the same at every range, because falloff never triggers today.

| id | Weapon | Body 10 | Body 30 | Body 60 | Head 10 | Head 30 | Head 60 |
|---|---|---|---|---|---|---|---|
| 1 | Vanguard | 5×20=1995 → 29×4=315 | 1995 → 24×5=420 | 1995 → 24×5=420 | 8×13=1260 → 103×1=0 | 1260 → 86×2=105 | 1260 → 86×2=105 |
| 2 | Scout | 5×20=+R 5370 → 34×3=480 | +R 5370 → 30×4=720 | +R 5370 → 27×4=720 | 8×13=+R 3690 → 102×1=0 | +R 3690 → 90×2=240 | +R 3690 → 82×2=240 |
| 3 | Longshot | 14×8=1330 → 38×3=480 | 1330 → 38×3=480 | 1330 → 38×3=480 | 22×5=760 → 103×1=0 | 760 → 103×1=0 | 760 → 103×1=0 |
| 4 | Viper | 5×20=+R 3600 → 25×4=450 | +R 3600 → 21×5=600 | +R 3600 → 21×5=600 | 8×13=1800 → 75×2=150 | 1800 → 64×2=150 | 1800 → 64×2=150 |
| 5 | Rush | 5×20=1425 → 26×4=225 | 1425 → 22×5=300 | 1425 → 18×6=375 | 8×13=900 → 70×2=75 | 900 → 60×2=75 | 900 → 49×3=150 |
| 6 | Breach | 40×3=1320 → 104×1=0 | 38×3=1320 → 57×2=660 | 27×4=1980 → 31×4=1980 | 58×2=660 → 156×1=0 | 54×2=660 → 86×2=660 | 39×3=1320 → 47×3=1320 |
| 7 | Horizon | 35×3=2000 → 105×1=0 | 2000 → 105×1=0 | 2000 → 105×1=0 | 70×2=1000 → 210×1=0 | 1000 → 0 | 1000 → 0 |
| 9 | Spectre | 5×20=1615 → 25×4=255 | 1615 → 22×5=340 | 1615 → 19×6=425 | 8×13=1020 → 65×2=85 | 1020 → 57×2=85 | 1020 → 49×3=170 |
| 10 | Talon | 7×15=1820 → 30×4=390 | 1820 → 30×4=390 | 1820 → 27×4=390 | 11×10=1170 → 102×1=0 | 1170 → 102×1=0 | 1170 → 92×2=130 |
| 11 | Anchor | 6×17=1920 → 25×4=360 | 1920 → 25×4=360 | 1920 → 22×5=480 | 10×10=1080 → 75×2=120 | 1080 → 75×2=120 | 1080 → 66×2=120 |
| 12 | Needle | 5×20=1140 → 20×5=240 | 1140 → 16×7=360 | 1140 → 12×9=480 | 8×13=720 → 56×2=60 | 720 → 45×3=120 | 720 → 34×3=120 |
| 13 | Hammer | 65×2=850 → 117×1=0 | 57×2=850 → 53×2=850 | 37×3=+R 2250 → 23×5=+R 4500 | 81×2=850 → 152×1=0 | 72×2=850 → 68×2=850 | 46×3=+R 2250 → 30×4=+R 3100 |
| 14 | Vector | 22×5=1200 → 55×2=420 | 1200 → 55×2=420 | 1200 → 48×3=840 | 35×3=600 → 110×1=0 | 600 → 110×1=0 | 600 → 97×2=420 |
| 15 | Sentinel | 30×4=2040 → 75×2=680 | 2040 → 75×2=680 | 2040 → 75×2=680 | 60×2=680 → 150×1=0 | 680 → 0 | 680 → 0 |
| 16 | Warden | 28×4=1260 → 52×2=420 | 1260 → 44×3=840 | 1260 → 36×3=840 | 45×3=840 → 104×1=0 | 840 → 88×2=420 | 840 → 73×2=420 |
| 17 | Ember | 5×20=1805 → 20×5=380 | 1805 → 17×6=475 | 1805 → 14×8=665 | 8×13=1140 → 56×2=95 | 1140 → 48×3=190 | 1140 → 39×3=190 |
| 18 | Kestrel | 20×5=1360 → 34×3=680 | 1360 → 34×3=680 | 1360 → 34×3=680 | 32×4=1020 → 102×1=0 | 1020 → 102×1=0 | 1020 → 102×1=0 |
| 20 | Drift | 25×4=1140 → 63×2=380 | 22×5=1520 → 33×4=1140 | 13×8=2660 → 19×6=1900 | 33×4=1140 → 88×2=380 | 28×4=1140 → 46×3=760 | 17×6=1900 → 26×4=1140 |

Launchers have no headshots, and their damage is the same at every range.

| id | Weapon | Direct hit | Splash |
|---|---|---|---|
| 8 | Arc | 60×2, reload forced = 1850 → 75×2 = 1600 | 40×3 = 3700 → 45×3 = 3200 |
| 19 | Nova | 60×2 = 1100 → 70×2 = 1100 | 40×3, +R = 3600 → 45×3, +R = 3400 |

### 4.4 Sidegrade check (resolves the judges' dominance pairs)

- **Vanguard vs Talon vs Longshot.** Each one wins a different distance band.
  - Inside 25 studs, Vanguard is the fastest rifle: 315 ms body and a one-tap. It drops to 5 body shots and a two-tap headshot past 25 studs.
  - From 25 to 50 studs, Talon is best: 390 ms body and a one-tap.
  - Past 50 studs, Longshot is the only non-sniper that still one-taps the head. Talon needs 2 headshots there (130 ms), though its 390 ms body kill is faster than Longshot's 480 ms. Longshot also has the tightest ADS cone (.20).
- **Vector vs Sentinel vs Longshot.**
  - Inside 50 studs, Vector is best: 2 body shots in 420 ms and a one-tap. Past 50 it needs 3 body shots (840 ms) and 2 headshots.
  - Sentinel needs 2 body shots (680 ms) and one-taps the head at any range.
  - Longshot needs 3 body shots (480 ms) and one-taps at any range. It fires faster, but needs one more hit than Sentinel.
  - This replaces P0's "Vector strictly better than Sentinel" problem. One pair is still open (see section 6).
- **SMGs vs rifles up close.** Rush (225 ms), Spectre (255 ms) and Needle (240 ms) all beat Vanguard (315 ms) on body TTK at 10 studs, and have 3–5× better `run` values. Rifles answer with one-taps. Past about 35 studs the SMGs fall behind.
- **Pistols.**
  - Scout: 480 ms at close range with a one-tap inside 20 studs.
  - Viper: 450 ms body, 2 headshots everywhere.
  - Ember: auto pistol with a 380 ms body kill.
  - Warden: 420 ms body and a one-tap, but only inside 25 studs.
  - Kestrel: 680 ms body and a one-tap at every range, so it owns long range.
  - Scout beats Warden at 30 studs.
- **Anchor LMG.** It beats Vanguard at 30 studs (360 ms vs 420 ms) and has 60 rounds with a 2-headshot kill at every range. Its costs are the worst `run` value and a 2.8 s reload.
- **Shotguns.**
  - Breach and Hammer one-shot only inside 10–12 studs.
  - At 30 studs they take 2 shots (660 / 850 ms). At 60 studs they are bad, which is intended.
  - Drift takes 2 shells (380 ms) with no reach.
  - The judges' complaint that P2's shotguns one-shot at 30–60 studs does not apply here.

---

## 5. Spray pattern recommendation: deterministic, per weapon, server-authoritative (Phase 2)

- **Pattern.** For index `i = floor(heat)+1`:
  - Vertical: `V(i) = climb*min(i-1, n) + 0.15*climb*max(0, i-1-n)`. This climbs for n shots, then creeps.
  - Horizontal: `H(i) = sway*sin((i-1-n)*0.9 + finish*2.1)*clamp((i-1-n)/3, 0, 1)`. Sideways sway starts only after the climb.
  - ADS scales both axes ×0.8. This fixes today's bug where only pitch is scaled.
  - Crouch scales by ×0.85 (×0.7 on Anchor).
- **Server.** RiftCombat rotates the bullet direction by (V up, H right) from the look vector the client sends, and then adds the random `Error` cone. A client that skips the kick gains nothing.
- **Client.**
  - Stop rotating the real camera.
  - Render a visual punch of 0.35×V as a camera offset, and strip that punch from the look vector before sending. The punch must be stripped because the server adds the pattern itself (Proposal 1 would have double-counted it).
  - Do not auto-recover while firing. After release, the punch returns over `recover × heat`.
  - The player controls spray by pulling down against V/H, as in Valorant.
- **Data cleanup.**
  - `B.Pattern` becomes the table-driven function above, reading `pattern` and `finish`.
  - `pitchKick` and `recoil` become viewmodel and punch feel only (`vmKick`).
- **Shotguns.** Use a fixed pellet layout: 1 centre pellet, a ring at 0.55× the cone and an outer ring at 1.0×. The layout is rotated randomly by ±15° per shell.
- **Why per weapon** rather than one shared shape as in P1: Valorant-style mastery comes from learning each gun's spray. Each pattern is only three numbers, so it is still cheap to tune.
- **Interim (Phase 1 only).** Keep the current camera `Pattern`, but stop the `exp(-dt*5)` recovery while the trigger is held. This makes today's climb something the player actually has to pull down against.

---

## 6. Open questions for the owner

1. **Horizon one-shots to the body at every range** (105 damage), balanced only by its 1.25 s interval, 4-round mag, hip 5.0 with no free first shot, and `air` 14. Is that acceptable, or should Horizon drop to 95 so a body kill needs a second hit?
2. **Longshot vs Sentinel at range.** On paper Longshot (480 ms, one-tap) beats Sentinel (680 ms). Sentinel's advantages are needing 2 hits instead of 3, an ADS cone of .07 vs .20, and scope zoom. Is that enough, or should Sentinel's interval go to .55 (550 ms)?
3. **Arc keeps its 1-round mag,** so every follow-up waits on the reload (now 1.6 s). Do you want that as a deliberate burst-then-swap secondary, or should the mag go to 2?
4. **Crosshair:** dynamic spread gap (default), or a static Valorant-style crosshair with movement-error feedback as the default?
5. **Phasing:** ship Phase 1 alone first and playtest, or ship both phases together?
6. **Launcher splash:** keep splash at full damage across the blast radius, or let it fall to 50% at the edge (P1's idea)?
7. **Feel shock:** ADS-walking goes from 0° to about 3.9°, and air goes from +2° to up to +14°. Do you want a softer first pass, for example `run`×0.7?

---
## External second opinion (Codex, 2026-11-06) — still PROPOSAL ONLY
Second opinion not finished yet. Open points to resolve before any change:
1. Rifle falloff too short: Vanguard loses the head one-tap past 25 studs while Kestrel keeps it at every range. Rebalance the falloff bands.
2. SMG claim contradicts the table: Rush still out-TTKs Vanguard/Talon on body shots at 60 studs. Steepen SMG falloff or fix the claim.
3. Breach 104 total needs all 8 pellets for a body one-shot. Measure real pellet coverage (spread x distance) before calling it a reliable close kill.
4. Recoil display at 35% of server recoil may put bullets above the visible aim point. Needs an aim-alignment check (crosshair vs server ray) before adoption.
