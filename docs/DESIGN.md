# Rift interface and world direction

The combat screen prioritises targets, health, ammunition, and cooldowns. The menu uses a quiet editorial layout inspired by the restraint of Claude's interface, with original FPS navigation and no decorative dashboard cards.

## Shared interface rules

- Charcoal background #171819; elevated surface #202123; fine border #38393B.
- Warm white #EEECE7 for primary text; grey #A9AAA6 for supporting text.
- Muted copper #C79B7A marks selection and primary actions. Red is reserved for damage; team colours appear only where team identity matters.
- An 8-pixel spacing rhythm, 24-pixel page margins, 6-pixel corners, 1-pixel borders.
- Gotham typography: regular body 14–16, medium labels 12–14, semibold page titles 24. No all-bold paragraphs.
- Buttons, labels, surfaces, and dividers come from one shared RiftUI module. Hover transitions take 0.12 seconds.
- One menu owns Play, Arsenal, Abilities, and Settings. The same menu acts as the pause overlay during a match; the match continues live.
- Arsenal is also the weapon catalogue/shop surface: all weapons are available, with no invented currency or purchases. Selection is explicit and acknowledged by the server.
- HUD: numbered 100 HP, slim stamina, readable ammo and cooldowns; compact match status, aligned scoreboard columns.
- Interactive screens respect Roblox safe insets and scale to fit. Long weapon lists scroll.

## World rules

Enlarge the lobby and training footprint without multiplying decorative objects. Use architectural proportions, broad material changes, coherent signage, and clear circulation. Keep competitive maps and existing match rules intact. Training provides open sightlines, distance lanes, movement space, and existing respawning targets.

## Scope and verification

Preserve existing combat validation, travel, match queues, abilities, and settings attributes. Use only a solo runtime for UI/combat checks; 2v2 and 3v3 testing belongs to the user and their friends. Commit each coherent change. Prefer native materials, shared weapon geometry, and no downloaded texture packs to control memory.
