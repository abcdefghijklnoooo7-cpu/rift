# Rift overhaul checkpoint (2026-11-05)

Studio place: "rift" (placeId 123656256423285). Studio edits are live in the open place but are only kept once the place is saved or published.

## Done (compiled, not playtested)
- **Stage 1:** movement easing (RiftMovement + StarterPlayerScripts.RiftMotion), third-person lobby / first-person matches, cursor lock.
- **Stage 2:** custom Animate controller plus 63 custom animations, uploaded with their IDs in ReplicatedStorage.RiftAnimations. Crouch on Ctrl.
- **Stage 3:** theme (RiftTheme/RiftUI), custom health and stamina bars, bottom nav bar with badges.
- **Stage 4:** all 7 maps on the vote, team spawns, in-use maps greyed out. Dockyard walls moved out of the training range.
- **Stage 5:** full-screen Arsenal (RiftArsenal) and the M loadout picker. Picks made in a match apply at next respawn. UI restyled after the reference screenshots.
- **Lobby:**
  - Queue pads (1v1/2v2/3v3) and Scythe/Vanguard Rifle display stands.
  - Queue terminal range bug fixed.
  - Baseplate removed and a sunset sky added (old sky, lighting and baseplate are in ServerStorage.RiftBackup_2026-11-05_preSunset).
  - Per-map Audio slots (RiftAmbience).
  - Red damage vignette, plus round-end banner and stingers.
- **Weapons tab:** the Arsenal 3D stage now uses the lobby-style display stand.

## Stage 6 (shop): in progress
Spec: `shop_design_spec.md` (merged by a 4-agent design workflow).

Built so far:
- Backup: ServerStorage.RiftBackup_2026-11-05_preStage6 (27 scripts).
- ReplicatedStorage.RiftEconomyConfig (all economy numbers).
- ReplicatedStorage.RiftSkins (9 styles).
- ReplicatedStorage.RiftShopCatalog (starters, weapon prices, bundles, daily rotation, Resolve). Checked: 12 starters, 28 locked weapons (32,750 Shards for all), offers resolve correctly.
- RiftWeaponModels.create(w, skin) accepts skin colours and material.

Still to build (in this order; see the spec's buildOrder):
1. ServerScriptService.RiftData: DataStore profiles, session lock, saves, MockStore in Studio, ownership provider on RiftWeapons.IsUnlocked.
2. RiftCombat: fix the reset() pending bypass, throttle and persist the loadout. Locked lobby display stands send an "offer" event.
3. Earning: RiftMatchResult/RiftDamage events, RiftDuel patches, ServerScriptService.RiftEconomy payouts and daily rules.
4. ServerScriptService.RiftShopServer plus ReplicatedStorage.RiftShop (RemoteFunction) and RiftShopSync (RemoteEvent).
5. trimMaterial in RiftWeaponModels, and skins passed at every Models.create call site.
6. RiftPurchasePrompt plus the RiftShopUI LocalScript (currency bar, tabs Home/Bundles/Skins/Daily/Keys, cards, featured panel, payout panel).
7. Arsenal integration: price pills, UNLOCK button, skin strip, locked weapons in the picker, Shop nav button enabled.
8. Review and compile check.

## Open decisions for the owner
- APPROVED by owner: the 12 starter weapons (Vanguard Rifle, Rush SMG, Breach Shotgun, Horizon Sniper, Scout Pistol, Viper Pistol, Fists, Knife, Katana, Grenade, Smoke Grenade, Medkit). The other 28 become locked.
- Rename "Subspace Tripmine", "Warper" and "Warpstone": these names match classic Roblox gear. They are kept out of promos until renamed.
- Stage 7 (restyle) covers EVERY map. Stage 8 (gunplay audit) comes after.

## 2026-11-06 run (user asleep, ultracode)
- Studio restarted; new studio_id 93e180b3-e8b7-485f-8750-16ec115feb40. Work intact.
- Created ReplicatedStorage.RiftShop (RemoteFunction), RiftShopSync (RemoteEvent), ServerScriptService.RiftMatchResult + RiftDamage (BindableEvents).
- Workflow wf_f15aa452-b81 building Stage 6 steps 1-8 (build -> review -> verify -> fix). Sources mirrored to ./src/.
- Workflow wf_26478d59-b37: Stage 8 audit, read-only, writes ./stage8_gun_audit.md (not applied).
- Stage 8 DONE (proposal only): ./stage8_gun_audit.md. Nothing applied; needs owner approval.
- Stage 7: backup ServerStorage.RiftBackup_2026-11-06_preStage7 (all 7 maps, Training Arena, Lobby, Lighting).
- Owner sent AAA visual overhaul goals: maps + training range are fully REPLACED (not restyled). The paint-only restyle (wf_77180c2a-d93) was stopped before it changed anything.
- Git checkpoint: local clone ./rift-repo, tag checkpoint/pre-visual-overhaul-2026-11-06 (NOT pushed). The repo's Rift.rbxlx predates this overhaul's Studio work.
- Workflow wf_5b75ad1f-b29: contracts -> art bible (./visual_overhaul/art_bible.md) -> ServerStorage.RiftKit -> rebuild 8 environments in 2 waves -> detail -> review -> fix; plus LocalScript RiftMapMood.
- Codex is building FBX weapons, rails, pipes, signs + texture maps (concrete, steel, plaster, tile, stone, floor) into ./visual_overhaul/assets/. Wire them in when they land. Codex Stage 8 feedback appended to stage8_gun_audit.md; guns stay proposal-only.
- Next after Stage 6 finishes: weapon visual polish (muzzle flash, tracers, impacts, shells, sway, recoil), since it touches RiftClient/RiftGunFX.

## Status at wrap-up (2026-11-06, 5-hour limit near)
- Stage 6 workflow wf_f15aa452-b81: ALL BUILD steps done (RiftData, combat fixes, earning, shop server, skins, PurchasePrompt, ShopUI, Arsenal). 5 reviewers done. Was in VERIFY -> FIX -> FINAL when paused. Sources mirrored in ./src/.
- Environment rebuild wf_5b75ad1f-b29: Understand + art direction done (docs in ./visual_overhaul/: map_gameplay_contracts.md, training_arena_preservation_inventory.md, art_bible*.md). Was building ServerStorage.RiftKit; maps NOT yet replaced (some may be mid-build: check each map in Studio before resuming; backups in ServerStorage.RiftBackup_2026-11-06_preStage7).
- Stage 8: proposal only + Codex feedback (4 open points) in stage8_gun_audit.md.
- Codex: assets incoming to ./visual_overhaul/assets/. Save-system review cancelled.
- Not done: weapon visual polish; Stage 6 verify/fix/final; map rebuilds; wiring Codex assets.
- OWNER TODO in Studio: File > Save (or publish) NOW so tonight's work is kept; later set Lighting.Technology = Future.

## Resume (workflows replay finished agents from cache)
1. Workflow({scriptPath: "~/.claude/projects/-Users-jeffr-Documents-Rift-Animations/95ac1ee0-bbef-4655-aba5-871cd0444a02/workflows/scripts/rift-stage6-shop-wf_f15aa452-b81.js", resumeFromRunId: "wf_f15aa452-b81"})
2. Workflow({scriptPath: "~/.claude/projects/-Users-jeffr-Documents-Rift-Animations/95ac1ee0-bbef-4655-aba5-871cd0444a02/workflows/scripts/rift-environment-rebuild-wf_5b75ad1f-b29.js", resumeFromRunId: "wf_5b75ad1f-b29"})
3. After Stage 6: weapon visual polish workflow (RiftClient/RiftGunFX), then wire Codex assets.

## Resume prompt
"Resume Rift from CHECKPOINT.md: resume both workflows, then weapon visuals."
