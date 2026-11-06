local weapons = {
 -- Spread is in degrees and fire intervals are in seconds.
 -- Body damage is per trigger pull, before spread, headshots and distance falloff.
 -- Precision/heavy weapons trade cadence and capacity for higher damage; standard automatics stay at 5.
 {name="Vanguard Rifle", short="Rifle", model="rifle", magazine=25, shotInterval=.105, reloadTime=1.35, automatic=true, range=450, bodyDamage=5, headMultiplier=1.6, hip=1.3, ads=.36, zoom=.80, recoil=.14, pitchKick=1.08, shotSound="rbxassetid://72591590550768", soundPitch=1},
 {name="Scout Pistol", short="Scout", model="pistol", magazine=12, shotInterval=.24, reloadTime=1.05, automatic=false, range=250, bodyDamage=5, headMultiplier=1.6, hip=1.45, ads=.48, zoom=.88, recoil=.19, pitchKick=1.35, shotSound="rbxassetid://98975838871911", soundPitch=1.12},
 {name="Longshot Carbine", short="Carbine", model="rifle", magazine=15, shotInterval=.19, reloadTime=1.45, automatic=false, range=550, bodyDamage=14, headMultiplier=1.6, hip=1.1, ads=.23, zoom=.74, recoil=.20, pitchKick=1.55, shotSound="rbxassetid://72591590550768", soundPitch=.83},
 {name="Viper Pistol", short="Viper", model="pistol", magazine=16, shotInterval=.15, reloadTime=.9, automatic=false, range=180, bodyDamage=5, headMultiplier=1.6, hip=1.65, ads=.58, zoom=.9, recoil=.12, pitchKick=1.00, shotSound="rbxassetid://98975838871911", soundPitch=1.3},
 {name="Rush SMG", short="SMG", model="rifle", magazine=30, shotInterval=.075, reloadTime=1.25, automatic=true, range=220, bodyDamage=5, headMultiplier=1.6, hip=2, ads=.68, zoom=.88, recoil=.09, pitchKick=.65, shotSound="rbxassetid://72591590550768", soundPitch=1.42},
 {name="Breach Shotgun", short="Shotgun", model="rifle", magazine=5, shotInterval=.66, reloadTime=1.8, automatic=false, range=115, bodyDamage=40, headMultiplier=1.45, hip=5.7, ads=3.7, zoom=.85, recoil=.28, pitchKick=3.0, pellets=8, shotSound="rbxassetid://71816202649396", soundPitch=1},
 {name="Horizon Sniper", short="Sniper", model="rifle", magazine=4, shotInterval=1.0, reloadTime=1.9, automatic=false, range=650, bodyDamage=35, headMultiplier=2, hip=4.2, ads=.065, zoom=.48, recoil=.34, pitchKick=3.25, shotSound="rbxassetid://9118173988", soundPitch=1.1},
 {name="Arc Launcher", short="Launcher", model="pistol", magazine=1, shotInterval=.92, reloadTime=1.85, automatic=false, range=100, bodyDamage=40, directDamage=60, headMultiplier=1, hip=1.3, ads=.6, zoom=.9, recoil=.29, pitchKick=2.65, blastRadius=13, shotSound="rbxasset://sounds/impact_explosion_03.mp3", soundPitch=2.4},
 {name="Spectre SMG",short="Spectre",family="smg",magazine=24,shotInterval=0.085,reloadTime=1.12,automatic=true,range=240,bodyDamage=5,headMultiplier=1.6,hip=1.6,ads=0.5,zoom=0.86,recoil=0.1,pitchKick=0.72,shotSound="rbxassetid://72591590550768",soundPitch=1.3},
 {name="Talon Rifle",short="Talon",family="rifle",magazine=30,shotInterval=0.13,reloadTime=1.55,automatic=true,range=460,bodyDamage=7,headMultiplier=1.6,hip=1.5,ads=0.38,zoom=0.78,recoil=0.17,pitchKick=1.3,shotSound="rbxassetid://72591590550768",soundPitch=0.88},
 {name="Anchor LMG",short="Anchor",family="lmg",magazine=60,shotInterval=0.12,reloadTime=2.8,automatic=true,range=400,bodyDamage=6,headMultiplier=1.6,hip=2.7,ads=0.85,zoom=0.82,recoil=0.18,pitchKick=1.25,shotSound="rbxassetid://72591590550768",soundPitch=0.78},
 {name="Needle PDW",short="Needle",family="smg",magazine=36,shotInterval=0.06,reloadTime=1.6,automatic=true,range=165,bodyDamage=5,headMultiplier=1.6,hip=2.4,ads=0.82,zoom=0.9,recoil=0.07,pitchKick=0.5,shotSound="rbxassetid://72591590550768",soundPitch=1.55},
 {name="Hammer Shotgun",short="Hammer",family="shotgun",magazine=2,shotInterval=0.85,reloadTime=1.4,automatic=false,range=95,bodyDamage=65,headMultiplier=1.25,hip=6,ads=4.5,zoom=0.86,recoil=0.36,pitchKick=3.7,shotSound="rbxassetid://71816202649396",soundPitch=0.78,pellets=9},
 {name="Vector DMR",short="Vector",family="marksman",magazine=12,shotInterval=0.3,reloadTime=1.5,automatic=false,range=600,bodyDamage=22,headMultiplier=1.6,hip=1.6,ads=0.15,zoom=0.68,recoil=0.22,pitchKick=1.9,shotSound="rbxassetid://72591590550768",soundPitch=0.72},
 {name="Sentinel Sniper",short="Sentinel",family="sniper",magazine=6,shotInterval=0.68,reloadTime=2.2,automatic=false,range=600,bodyDamage=30,headMultiplier=2,hip=4.5,ads=0.09,zoom=0.55,recoil=0.26,pitchKick=2.7,shotSound="rbxassetid://72591590550768",soundPitch=0.86},
 {name="Warden Revolver",short="Warden",family="revolver",magazine=6,shotInterval=0.42,reloadTime=1.7,automatic=false,range=320,bodyDamage=28,headMultiplier=1.6,hip=1.5,ads=0.3,zoom=0.82,recoil=0.26,pitchKick=2.2,shotSound="rbxassetid://98975838871911",soundPitch=0.8},
 {name="Ember Auto Pistol",short="Ember",family="pistol",magazine=20,shotInterval=0.095,reloadTime=1.2,automatic=true,range=150,bodyDamage=5,headMultiplier=1.6,hip=2.5,ads=0.95,zoom=0.91,recoil=0.09,pitchKick=0.65,shotSound="rbxassetid://98975838871911",soundPitch=1.45},
 {name="Kestrel Heavy Pistol",short="Kestrel",family="pistol",magazine=8,shotInterval=0.34,reloadTime=1.25,automatic=false,range=330,bodyDamage=20,headMultiplier=1.6,hip=1.6,ads=0.35,zoom=0.84,recoil=0.24,pitchKick=1.8,shotSound="rbxassetid://98975838871911",soundPitch=0.88},
 {name="Nova Launcher",short="Nova",family="launcher",magazine=2,shotInterval=1.1,reloadTime=2.5,automatic=false,range=160,bodyDamage=40, directDamage=60,headMultiplier=1,hip=2,ads=0.85,zoom=0.86,recoil=0.38,pitchKick=3.2,shotSound="rbxasset://sounds/impact_explosion_03.mp3",soundPitch=1.8,blastRadius=15},
 {name="Drift Auto Shotgun",short="Drift",family="shotgun",magazine=8,shotInterval=0.38,reloadTime=2.2,automatic=true,range=90,bodyDamage=25,headMultiplier=1.3,hip=6.8,ads=4.5,zoom=0.9,recoil=0.21,pitchKick=2.1,shotSound="rbxassetid://71816202649396",soundPitch=1.2,pellets=7},
 {name="Fists",short="Fists",family="melee",magazine=1,shotInterval=.45,reloadTime=1,automatic=false,range=7,bodyDamage=20,headMultiplier=1,hip=0,ads=0,zoom=1,recoil=.15,pitchKick=0,shotSound="rbxasset://sounds/action_jump.mp3",soundPitch=1.5,melee=true},
 {name="Chainsaw",short="Chainsaw",family="melee",magazine=1,shotInterval=.16,reloadTime=1,automatic=true,range=8,bodyDamage=8,headMultiplier=1,hip=0,ads=0,zoom=1,recoil=.06,pitchKick=0,shotSound="rbxasset://sounds/action_footsteps_plastic.mp3",soundPitch=.7,melee=true},
 {name="Grenade",short="Grenade",family="utility",magazine=1,shotInterval=1,reloadTime=8,automatic=false,range=100,bodyDamage=40,headMultiplier=1,hip=0,ads=0,zoom=1,recoil=.15,pitchKick=0,shotSound="rbxasset://sounds/action_jump.mp3",soundPitch=1,grenade=true,blastRadius=13},

}

weapons.Loadouts = {{1,3,5,6,7,9,10,11,12,13,14,15,19,20},{2,4,8,16,17,18},{21,22},{23}}
weapons.Slots = {
 {attribute="RiftPrimary",category=1,default=1,label="Primary"},
 {attribute="RiftSecondary",category=2,default=2,label="Secondary"},
 {attribute="RiftMelee",category=3,default=21,label="Melee"},
 {attribute="RiftUtility",category=4,default=23,label="Utility"},
}
function weapons.GetId(player,slot)
 local definition=weapons.Slots[slot]
 if not definition then return 1 end
 local id=player:GetAttribute(definition.attribute)
 return typeof(id)=="number" and table.find(weapons.Loadouts[definition.category],id) and id or definition.default
end
weapons.Kits = {
 {name="Vanguard", omitted="recon"},
 {name="Sentinel", omitted="flash"},
 {name="Scout", omitted="smoke"},
}

local families={"rifle","pistol","marksman","pistol","smg","shotgun","sniper","launcher"}
local classes={rifle="Assault rifle",pistol="Pistol",marksman="Marksman",smg="SMG",shotgun="Shotgun",sniper="Sniper",launcher="Explosive",lmg="LMG",revolver="Revolver"}
local descriptions={
 "A balanced assault rifle. Controlled bursts reward accurate mid-range tracking.",
 "A reliable sidearm. Quick reloads and accurate single shots rescue a dry primary.",
 "A light precision carbine. Pace your shots for consistent mid-range damage.",
 "A fast-trigger sidearm with a generous magazine. Strong close-range follow-up.",
 "A mobile close-range automatic. Track targets and close the distance.",
 "A pump shotgun with a tight aimed pattern. Commit to close-range engagements.",
 "A heavy bolt-action profile. Use the scope for reliable headshots across long sightlines.",
 "A single-shot explosive sidearm. Splash checks nearby cover; walls block the blast.",
 "A controlled SMG for short bursts. Trades peak fire rate for precision and handling.",
 "A hard-hitting automatic rifle. Slower cadence and heavier kick reward recoil control.",
 "A sustained-fire support weapon. Large magazine, long reload, and wider spread.",
 "A rapid-fire personal defence weapon. Excellent tracking up close; weak at distance.",
 "A two-shell breacher. Very high close-range damage with little room for mistakes.",
 "A semi-automatic precision rifle. Steady aim rewards headshots at long range.",
 "A lighter sniper with faster follow-up shots. Lower body damage demands precision.",
 "A six-shot revolver. High-impact rounds and a deliberate trigger rhythm.",
 "An automatic backup pistol. Emergency firepower with short reach and strong spread.",
 "A heavy precision pistol. Eight rounds and a steady aim for long-range follow-up.",
 "A two-shot launcher. Wider splash and a slow reload; cover still protects opponents.",
 "A close-range automatic shotgun. Sustained pressure with less damage per shell.",
}
for id,weapon in ipairs(weapons) do
 weapon.family=weapon.family or families[id]
 weapon.class=classes[weapon.family] or weapon.family
 weapon.description=descriptions[id] or (weapon.melee and "Close-range attacks. Melee attacks use no ammunition." or "Throw a grenade. Detonates after 2.5 seconds; cover blocks the blast.")
 weapon.model=(weapon.family=="pistol" or weapon.family=="revolver") and "pistol" or "rifle"
 weapon.finish=id%3
 if weapon.family=="rifle" or weapon.family=="marksman" or weapon.family=="lmg" then weapon.shotSound="rbxassetid://9114727430"
 elseif weapon.family=="smg" then weapon.shotSound="rbxassetid://9114729252"
 elseif weapon.family=="sniper" then weapon.shotSound="rbxassetid://9114727561"; weapon.soundPitch=.68 end
end

-- Rift interpretations of the RIVALS wiki catalogue; balance values are Rift-specific.
local additions={
 {"Knife",3,"Backstab from behind for extra damage.",35,.55,7},
 {"Katana",3,"Slash enemies; alternate use briefly deflects frontal damage.",30,.6,8},
 {"Scythe",3,"Wide close-range swing; alternate use lunges forward.",32,.7,10},
 {"Battle Axe",3,"Heavy swing with knockback; alternate use leaps forward.",45,.95,9},
 {"Riot Shield",3,"Shove nearby enemies; alternate use blocks frontal attacks.",15,.7,7},
 {"Trowel",3,"Strike enemies; alternate use builds temporary cover.",25,.6,7},
 {"Spear",3,"Long reach; alternate use throws a piercing spear.",30,.65,12},
 {"Maul",3,"Heavy knockback; alternate use performs a ground slam.",50,1.1,8},
 {"Glass Shard",3,"A fast close-range blade inspired by the special-mode item.",25,.35,6},
 {"Flashbang",4,"Throw a delayed flash that affects enemies with line of sight.",0,1,60},
 {"Smoke Grenade",4,"Throw smoke to obscure a route.",0,1,60},
 {"Molotov",4,"Throw a bottle that creates a damaging fire zone.",8,1,60},
 {"Medkit",4,"Restore health, capped at your maximum.",0,1,1},
 {"Satchel",4,"Place an explosive, then activate it with alternate use.",55,1,45},
 {"Subspace Tripmine",4,"Place a trap that detonates when an enemy approaches.",50,1,45},
 {"Freeze Ray",4,"Slow an enemy with a short freezing beam.",5,.25,65},
 {"Jump Pad",4,"Deploy a temporary launch pad.",0,1,10},
 {"War Horn",4,"Temporarily empower nearby teammates.",0,1,25},
 {"Warpstone",4,"Teleport toward an aimed safe surface.",0,1,55},
 {"Grappler",4,"Pull yourself toward a visible anchor point.",0,1,80},
 {"Warper",4,"Place a paired set of portals using alternate use.",0,1,60},
 {"Elixir",4,"Restore health and grant a short movement boost.",0,1,1},
 {"RNG Dice",4,"Roll a random healing, movement or explosive effect.",25,1,45},
}
local removed={ ["Glass Shard"]=true,["RNG Dice"]=true,["War Horn"]=true,["Grappler"]=true,["Jump Pad"]=true,["Freeze Ray"]=true }
for _,entry in additions do
 if removed[entry[1]] then continue end
 local id=#weapons+1; local melee=entry[2]==3
 weapons[id]={name=entry[1],short=entry[1],family=melee and "melee" or "utility",class=melee and "Melee" or "Utility",description=entry[3],magazine=melee and 1 or (entry[1]=="Freeze Ray" and 20 or 1),shotInterval=entry[5],reloadTime=melee and 1 or 12,automatic=entry[1]=="Freeze Ray",range=entry[6],bodyDamage=entry[4],headMultiplier=1,hip=0,ads=0,zoom=1,recoil=.12,pitchKick=0,shotSound="rbxasset://sounds/action_jump.mp3",soundPitch=1.1,melee=melee,finish=id%3,blastRadius=13,item=true}
 table.insert(weapons.Loadouts[entry[2]],id)
end
for _,id in {21,22,23} do weapons[id].item=true end

weapons.ReloadSound = "rbxassetid://117963160131194"
-- Lock state shared by server validation, the Arsenal screen and the loadout picker.
-- Everything is unlocked until the shop stage sets player attribute RiftLocked<id>=true.
function weapons.IsUnlocked(player,id)
 if weapons.OwnershipProvider then return weapons.OwnershipProvider(player,id) end
 return player:GetAttribute("RiftLocked"..tostring(id))~=true
end
-- Which loadout slot a weapon belongs to.
function weapons.SlotOf(id)
 for slot,definition in ipairs(weapons.Slots) do
  if table.find(weapons.Loadouts[definition.category],id) then return slot end
 end
end
return weapons
