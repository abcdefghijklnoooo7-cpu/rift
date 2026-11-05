# Rift interface and world direction

The interface uses pale stone panels, slate text and muted teal primary actions against the existing blue lobby. `ReplicatedStorage.RiftTheme` defines exactly six color tokens: background, panel, text, accent, success and danger. All runtime UI uses these tokens; world and weapon materials remain independent.

- Panels have 12px corners and subtle 1px strokes. Buttons have 8px corners and at least 44px targets. Spacing uses 8/16px increments, with 16px panel margins.
- Gotham and GothamBold use a 32 / 20 / 16 / 13 type scale. Copy uses sentence case and direct verbs.
- Matchmaking is the lobby's focal element. Four navigation controls sit on the left; session objectives, wins and leaders are available in Play instead of competing around the scene. Training and the existing practice destinations remain accessible there.
- Each page has one teal primary action. Selection uses slate rather than another accent. Health, wins and damage use semantic success/danger colors.
- Scale-based menu bounds and scrolling pages adapt without shrinking touch targets. Compact landscape headers keep the match action visible on phones. The weapon preview has an aspect constraint. The HUD uses a UIScale and a narrower touch layout above the native movement controls.
- RiftUIController arbitrates map voting, the menu and the scoreboard. Map voting has highest priority; the menu takes priority over the scoreboard. Fading-out screens stop accepting interaction immediately. Modal open/close fades use 0.2s Quad easing. Buttons scale to 0.95 on press. There is no idle animation.
- Shared quiet click audio respects the effects volume. Winning a completed match plays a short UI reward cue. There is no currency, reward-claim or rare-drop system yet; this styling does not invent one.
- All 20 weapons, loadout selection, kits, settings, matchmaking, map voting, training and scoreboard remain connected to the existing game systems. Map voting and scoreboard viewing also have visible touch controls.

## Verification

A single Studio client was used. Desktop, iPhone 17 Pro landscape and portrait, and iPad Pro M5 landscape layouts were inspected. The theme token count, modal priority, search empty state, all 20 weapon rows, and 44px menu button dimensions passed runtime checks. The training HUD was inspected on the tablet simulator. Studio was returned to its default viewport afterwards. Existing weapon sound asset warnings remain; no new UI runtime error was observed during these checks. Multiplayer matches and full touch combat were not tested.

`Rift.rbxlx` is the editable place and source of truth. This update is saved to GitHub and applied to the open Studio edit session; it is not a Roblox live publication.
