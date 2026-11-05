# Rift interface and world direction

The interface uses pale stone panels, slate text and muted teal primary actions against the existing blue lobby. `ReplicatedStorage.RiftTheme` defines exactly six color tokens: background, panel, text, accent, success and danger. All runtime UI uses these tokens; world and weapon materials remain independent.

- Panels have 12px corners and subtle 1px strokes. Buttons have 8px corners and at least 44px targets. Spacing uses 8/16px increments, with 16px panel margins.
- Gotham and GothamBold use a 32 / 20 / 16 / 13 type scale. Copy uses sentence case and direct verbs.
- The lobby keeps the world visible with four navigation controls on the left. Matchmaking appears only in the Play menu; session objectives, wins and leaders are available in Play instead of competing around the scene. Training and the existing practice destinations remain accessible there.
- Each page has one teal primary action. Selection uses slate rather than another accent. Health, wins and damage use semantic success/danger colors.
- Scale-based menu bounds and scrolling pages adapt without shrinking touch targets. Compact landscape headers keep the match action visible on phones. The weapon preview has an aspect constraint. The HUD uses a UIScale and a narrower touch layout above the native movement controls.
- RiftUIController arbitrates map voting, the menu and the scoreboard. Map voting has highest priority; the menu takes priority over the scoreboard. Fading-out screens stop accepting interaction immediately. Modal open/close fades use 0.2s Quad easing. Buttons scale to 0.95 on press. There is no idle animation.
- Shared quiet click audio respects the effects volume. Winning a completed match plays a short UI reward cue. There is no currency, reward-claim or rare-drop system yet; this styling does not invent one.
- All 20 weapons, loadout selection, kits, settings, matchmaking, map voting, training and scoreboard remain connected to the existing game systems. Map voting and scoreboard viewing also have visible touch controls.

## Verification

A single Studio client was used. Desktop, iPhone 17 Pro landscape and portrait, and iPad Pro M5 landscape layouts were inspected. The theme token count, modal priority, search empty state, all 20 weapon rows, and 44px menu button dimensions passed runtime checks. The training HUD was inspected on the tablet simulator. Studio was returned to its default viewport afterwards. Existing weapon sound asset warnings remain; no new UI runtime error was observed during these checks. Multiplayer matches and full touch combat were not tested.

`Rift.rbxlx` is the editable place and source of truth. The expanded maps, weapon balance, four-slot loadout and audio update were published to Roblox as version 28 on 5 November 2026.

## Larger maps and weapon balance

All nine map areas (lobby, training, four practice maps and three duel arenas) are 35% wider and longer, giving approximately 82% more horizontal area. Floor heights, structure heights and training target sizes are preserved. Spawns, map aim points, cover, boundaries and runtime movement features move with their maps. Shared practice targets remain aligned with their named map. The lobby queue distance allowance grows with the lobby. Round duration remains 40 seconds.

The duplicate “Ready to play?” lobby card is removed. Matchmaking and mode selection live in the Play menu.

| Weapon | Body / splash | Head / direct |
| --- | ---: | ---: |
| Horizon Sniper | 35 | 70 head |
| Sentinel Sniper | 30 | 60 head |
| Arc Launcher | 40 splash | 60 direct |
| Nova Launcher | 40 splash | 60 direct |
| Breach Shotgun | 40 per full shell | Existing head multiplier |
| Hammer Shotgun | 65 per full shell | Existing head multiplier |
| Drift Auto Shotgun | 25 per full shell | Existing head multiplier |
| Longshot Carbine | 14 | Existing head multiplier |
| Vector DMR | 22 | Existing head multiplier |
| Warden Revolver | 28 | Existing head multiplier |
| Kestrel Heavy Pistol | 20 | Existing head multiplier |
| Talon Rifle | 7 | Existing head multiplier |
| Anchor LMG | 6 | Existing head multiplier |

The Vanguard Rifle remains at 5 body damage. Shotgun spread and distance falloff still apply, and shell damage is shared among pellets. Launchers apply exactly 60 to the directly struck target, or 40 to an indirectly hit target within the blast radius and with line of sight. Direct and splash damage do not stack, and walls still block indirect blasts. The Arsenal shows both launcher outcomes.

Verification: all 1,100 saved map parts matched the Studio edit scene within 0.003 studs. Floor-support checks passed at the lobby, training and four practice spawns, and both team spawns in every duel arena. Six real client fire requests passed server-side checks: Horizon body 35 and head 70, Nova direct 60 and indirect 40, Arc direct 60 and indirect 40. The lobby was visually checked without the removed card. These checks used one Studio client; multiplayer balancing remains for playtesting.

## Four weapon slots and audio

Players carry two primaries and two secondaries. Slots 1/2 retain the existing rifle/pistol defaults; slots 3/4 default to Horizon Sniper and Arc Launcher. The Arsenal offers the appropriate destination slots for each selected weapon. Keys 1–4 and clickable/touchable HUD controls switch weapons. The server validates slot/category membership and maintains independent ammo and reload state for every slot. Switching keeps the existing fire-cadence restriction, so a slow weapon cannot bypass its cooldown through a quick swap.

`RiftAudio` owns the effects/music buses and extra equip, reload-completion, dash, slide, landing, damage, queue and round cues. Gun shots for rifles, SMGs and snipers use Pro Sound Effects Creator Store audio (9114727430, 9114729252 and 9114727561). The equip/reload mechanism cue uses Pro Sound Effects' Vice Grips 35 (9120409666). Other weapons retain their existing working shot assets. Shot tails now finish naturally rather than being cut at 0.65 seconds.

The lobby loops APM Music's **Spirit Warmth** (9042295159), a quiet instrumental ambient/electronic track from the Roblox Creator Store. It fades in/out over 0.7 seconds, pauses outside the lobby and during matches, and resumes on return. Settings has an independent music-volume slider, including mute; effects volume remains separate. These catalogue assets are referenced by ID, not redistributed as audio files.

Studio verification confirmed all 20 gun templates, eight extra cue templates, and the 132-second music track loaded. Four real fire requests consumed ammo independently in slots 1–4. Switching preserved ammo, reloads restored slots 1 and 4, invalid slot/category loadout requests were rejected, and music mute/fade/resume left effects volume unchanged. The four-slot HUD was visually inspected on desktop. Multiplayer audio mixing and full mobile combat still need player testing.
