# Rift game design ideas

This document collects the game-development ideas discussed for Rift. It is a design reference, not a claim that every idea is finished or balanced.

## Vision

A competitive Roblox first-person shooter combining the fast gunplay, movement, pacing and colourful presentation of RIVALS with tactical abilities inspired by Valorant. Aiming, reactions and movement should decide fights. Abilities add tactical choices and complement guns.

## Combat and weapons

- Responsive first-person camera, aiming and satisfying shooting.
- Primary and secondary loadouts with direct weapon selection and a weapon catalogue or shop interface.
- Assault rifles, SMGs, shotguns, sniper rifles, pistols and explosives, each with a distinct role, handling, rate of fire, recoil, spread, damage, magazine and reload time.
- Aim down sights, switching weapons, headshot multipliers, hit markers and clear damage feedback. Damage and hit detection must be validated by the server.
- Latest balance direction: approximately 20 body shots to eliminate a 100 HP opponent. Headshots reward accuracy, and a shotgun blast's pellets share its damage.
- Distinctive, improved weapon models and smooth firing, reload and equip animations.

## Movement and abilities

- Fast sprinting, jumping, strafing, air movement, sliding and momentum-based repositioning with a readable stamina bar.
- Offensive, defensive, information and mobility abilities with cooldowns or limited charges. Encourage varied strategies and team compositions while keeping weapon combat central.
- Trampolines and clearly readable map hazards support movement and positioning.

## Matches

- Separate compact arenas for 1v1, 2v2 and 3v3 team matches.
- Elimination rounds, short round timers, respawns between rounds and first team to five round wins.
- Map voting before matches, a scoreboard with kills, deaths and wins, and clear victory and defeat screens.
- A larger lobby with matchmaking and a larger training zone for targets, weapons and movement practice.

## Maps and presentation

- Improve map quality with distinct landscape and urban locations.
- Give both teams balanced layouts, multiple routes, flanks, clear sightlines, useful cover, verticality, and a mix of close- and long-range engagements.
- Keep geometry clean, textures simple and readable, lighting bright, characters recognisably blocky, and clutter low.
- Use original artwork and layouts while taking inspiration from RIVALS.

## Interface and usability

The latest direction replaces the earlier restrained Claude-inspired interface concept with an energetic, RIVALS-inspired arcade FPS style.

- Keep the game world visible behind independent, dark translucent panels. Use compact bold typography, outlines or shadows for readability, and purposeful green, yellow, purple, blue and red accents.
- Position game mode selection near the top centre, progression and tasks on the left, leaderboard and statistics on the upper right, navigation along the bottom, and notifications and player information around the edges.
- Provide main menu, settings, matchmaking, loadout, weapon shop or catalogue, abilities, scoreboard, pause menu and combat HUD.
- The HUD should show a RIVALS-inspired numbered health bar out of 100, stamina, ammo, abilities, hit confirmation and damage direction.
- Include mouse sensitivity, field of view, crosshair and audio settings. Keep controls quick to navigate, spacing consistent and visual effects restrained.
- Avoid generic dashboard layouts, excessive outlined cards and unnecessary decoration.

## Sound

Use clear, satisfying firing sounds, reloads, footsteps, hit confirmation, elimination cues, ability activation, explosions and UI interaction sounds. Audio should help players understand combat.

## Development priorities

1. FPS camera and aiming.
2. Weapon and shooting framework.
3. Server-authoritative hit detection and damage.
4. Movement.
5. Teams and rounds.
6. Ability framework.
7. UI and HUD.
8. Maps and environments.
9. Animation and sound.
10. Progression, cosmetics and ranked matchmaking.

## Performance and testing constraints

- Keep instance counts and memory use low, reuse shared components and avoid unnecessary complexity.
- Preserve existing functionality and inspect related systems before changing them. Make targeted edits, review them, and commit each coherent change.
- Use the GitHub repository as the source of truth. Consult current official Roblox and Luau documentation through Context7 when needed.
- Avoid further 2v2 and 3v3 multi-client testing on this machine because of RAM limits. The user plans to test those modes with friends.

## Current snapshot

The project has a larger lobby and training range, 20 available weapons, a RIVALS-inspired lobby UI, loadout and ability selection, and team-mode systems. A solo Studio check verified the Vanguard Rifle's 20-body-hit result against a 100 HP target. The new balance, all weapons, multiplayer modes and the full overhaul still need broader playtesting and tuning. Progression, cosmetics and ranked matchmaking remain future ideas rather than completed features. The most recent overhaul was committed to the repository but was not published live at the time of that work.
