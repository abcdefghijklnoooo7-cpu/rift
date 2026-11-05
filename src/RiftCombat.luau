local Training=require(game.ReplicatedStorage.RiftTraining)
local Ballistics=require(game.ReplicatedStorage.RiftBallistics)
local P=game:GetService("Players")
local R=game.ReplicatedStorage.RiftAction
local D=game:GetService("Debris")
local weapons=require(game.ReplicatedStorage.RiftWeapons)
local Items=require(game.ReplicatedStorage.RiftItems)
local eliminated=script.Parent.RiftElimination
local rng=Random.new()
local S={}
local function reset(p)
 local loadout,ammo={},{}
 for slot,definition in ipairs(weapons.Slots) do
  local id=weapons.GetId(p,slot); loadout[slot]=id; ammo[slot]=weapons[id].magazine
  if p:GetAttribute(definition.attribute)==nil then p:SetAttribute(definition.attribute,id) end
 end
 S[p]={
  equipped=1,
  loadout=loadout,
  ammo=ammo,
  nextShot=0,
  ready={},
  reload=nil,
 }
 R:FireClient(p,"combatReset")
end
script.Parent.RiftResetCombat.Event:Connect(reset)
local function setup(p)
 p.CameraMode=Enum.CameraMode.LockFirstPerson
 local function onCharacter(character)
  reset(p)
  p:SetAttribute("RiftGuardUntil",0); p:SetAttribute("RiftEmpoweredUntil",0)
  local humanoid=character:WaitForChild("Humanoid",5)
  if humanoid then
   humanoid.MaxHealth=100
   humanoid.Health=100
   humanoid.StateChanged:Connect(function(_,state) if state==Enum.HumanoidStateType.Landed and S[p] then S[p].airJumpUsed=false end end)
  end
 end
 p.CharacterAdded:Connect(onCharacter)
 if p.Character then task.spawn(onCharacter,p.Character) end
end

local function sameCombatSpace(a,b)
 local duel=a:GetAttribute("RiftDuelId")
 if duel then
  return b:GetAttribute("RiftDuelId")==duel and b:GetAttribute("RiftDuelPhase")=="Fight" and b:GetAttribute("RiftRoundAlive")==true
 end
 local map=a:GetAttribute("RiftMap")
 return map and map~="Lobby" and not b:GetAttribute("RiftDuelId") and b:GetAttribute("RiftMap")==map
end
P.PlayerAdded:Connect(setup)
P.PlayerRemoving:Connect(function(p) S[p]=nil end)
for _,p in P:GetPlayers() do setup(p) end
local function effect(parent,pos,size,color,alpha,life,ball)
 local part=Instance.new("Part")
 part.Name="AbilityEffect"; part.Anchored=true; part.CanCollide=false; part.CanTouch=false; part.CanQuery=false
 part.Shape=ball and Enum.PartType.Ball or Enum.PartType.Block
 part.Size=size; part.Position=pos; part.Color=color; part.Transparency=alpha; part.Material=Enum.Material.Neon
 part.Parent=parent; D:AddItem(part,life); return part
end
local function enemy(attacker,opponent)
 if not sameCombatSpace(attacker,opponent) then return false end
 return not attacker:GetAttribute("RiftDuelId") or attacker:GetAttribute("RiftTeam")~=opponent:GetAttribute("RiftTeam")
end

local function damage(attacker,model,amount,headshot,origin)
 if not model then return end
 local opponent=P:GetPlayerFromCharacter(model)
 if opponent then
  if opponent==attacker or not enemy(attacker,opponent) then return end
 elseif attacker:GetAttribute("RiftDuelId") or model.Parent~=workspace.RiftArena.Targets or not Training.CanDamage(attacker,model) then
  return
 end
 if not opponent then
  local map=attacker:GetAttribute("RiftMap")
  if model:GetAttribute("TrainingOwner") then if map~="Training Arena" then return end
  elseif map=="Training Arena" then if not model.Name:find("Training Target",1,true) then return end
  elseif not map or not model.Name:find(map.." Target",1,true) then return end
 end
 local target=model:FindFirstChildOfClass("Humanoid")
 if not target or target.Health<=0 then return end
 if attacker:GetAttribute("RiftEmpoweredUntil") and attacker:GetAttribute("RiftEmpoweredUntil")>os.clock() then amount*=1.2 end
 if opponent and origin then
  local root=model:FindFirstChild("HumanoidRootPart")
  local direction=root and origin-root.Position
  local facing=direction and direction.Magnitude>.01 and root.CFrame.LookVector:Dot(direction.Unit) or 0
  if (opponent:GetAttribute("RiftGuardUntil") or 0)>os.clock() and facing>.2 then
   if opponent:GetAttribute("RiftGuardReflect") then local h=attacker.Character and attacker.Character:FindFirstChildOfClass("Humanoid"); if h then h:TakeDamage(math.min(amount,35)) end end
   return
  end
  local state=S[opponent]
  if state and state.equipped~=3 and weapons[state.loadout[3]].name=="Riot Shield" and facing<-.2 then amount*=.5 end
 end
 local before=target.Health
 target:TakeDamage(math.round(amount))
 local dealt=math.round(before-target.Health)
 if dealt<=0 then return end
 Training.Hit(attacker,model,headshot,dealt)
 local killed=target.Health<=0
 R:FireClient(attacker,"hit",headshot,dealt,killed)
 if opponent then
  R:FireClient(opponent,"damageFrom",origin)
  if killed then eliminated:Fire(attacker,opponent) end
 end
end

-- Resolve the character above nested equipment models as well as direct body parts.
local function hitCharacter(instance)
 local current=instance
 while current and current~=workspace do
  if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then return current end
  current=current.Parent
 end
end
local function isHeadHit(part,character)
 if part.Name=="Head" then return true end
 local accessory=part:FindFirstAncestorOfClass("Accessory")
 if accessory and accessory:IsDescendantOf(character) then
  local weld=part:FindFirstChild("AccessoryWeld")
  return weld and weld.Part1 and weld.Part1.Name=="Head" or false
 end
 return false
end
local function finiteVector(v)
 return typeof(v)=="Vector3" and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<1e7 and math.abs(v.Y)<1e7 and math.abs(v.Z)<1e7
end
local function cameraSegmentClear(origin,offset,character)
 if offset.Magnitude<.001 then return true end
 local exclusions={character}
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
 -- Characters can overlap a first-person camera. They must not hide a wall
 -- farther along the validation segment; recast after each skipped character.
 for _=1,8 do
  params.FilterDescendantsInstances=exclusions
  local hit=workspace:Raycast(origin,offset,params)
  if not hit then return true end
  local model=hitCharacter(hit.Instance)
  if not model then return false end
  table.insert(exclusions,model)
 end
 return false
end
local function shotRay(origin,direction,distance,params,character)
 -- Raycast ignores a part that already contains the ray origin. Detect only
 -- forward-facing, direct humanoid body parts in this tiny initial overlap.
 local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Exclude
 overlap.FilterDescendantsInstances={character};overlap.MaxParts=32
 for _,part in workspace:GetPartBoundsInRadius(origin,.025,overlap) do
  local model=hitCharacter(part)
  if not model or part.Parent~=model or not part.CanQuery then continue end
  local delta=part.Position-origin
  if delta:Dot(direction)<0 then continue end
  local localOrigin=part.CFrame:PointToObjectSpace(origin)
  local half=part.Size*.5
  if math.abs(localOrigin.X)<=half.X and math.abs(localOrigin.Y)<=half.Y and math.abs(localOrigin.Z)<=half.Z then
   return {Instance=part,Position=origin,Normal=-direction,Material=part.Material,Distance=0}
  end
 end
 return workspace:Raycast(origin,direction*distance,params)
end

local function aimWithSpread(aim,degrees)
 local cone=math.tan(math.rad(degrees))
 local angle=rng:NextNumber(0,math.pi*2)
 local radius=math.sqrt(rng:NextNumber())*cone
 local basis=CFrame.lookAt(Vector3.zero,aim)
 return (aim+basis.RightVector*(math.cos(angle)*radius)+basis.UpVector*(math.sin(angle)*radius)).Unit
end

local function blast(attacker,parent,position,weapon,directTarget)
 effect(parent,position,Vector3.one*weapon.blastRadius*2,Color3.fromRGB(255,159,68),.55,.18,true)
 local targets={}
 for _,player in P:GetPlayers() do
  if player.Character and sameCombatSpace(attacker,player) then
   R:FireClient(player,"explosion",position)
   if player~=attacker then table.insert(targets,player.Character) end
  end
 end
 if not attacker:GetAttribute("RiftDuelId") then
  for _,bot in workspace.RiftArena.Targets:GetChildren() do table.insert(targets,bot) end
 end
 local sight=RaycastParams.new()
 sight.FilterType=Enum.RaycastFilterType.Exclude
 sight.FilterDescendantsInstances={attacker.Character}
 for _,target in targets do
  local root=target:FindFirstChild("HumanoidRootPart")
  if not root then continue end
  local offset=root.Position-position
  if target~=directTarget and offset.Magnitude>weapon.blastRadius then continue end
  local hit=workspace:Raycast(position,offset,sight)
  if target==directTarget or not hit or hit.Instance:IsDescendantOf(target) then
   local amount=target==directTarget and (weapon.directDamage or weapon.bodyDamage) or weapon.bodyDamage
   damage(attacker,target,amount,false,position)
  end
 end
end

local cooldown={smoke=16,flash=12,recon=18}
R.OnServerEvent:Connect(function(p,action,aim,expectedSlot,aiming,cameraOrigin)
 local s=S[p]; local c=p.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 local head=c and c:FindFirstChild("Head")
 if not s or not h or h.Health<=0 or not head then return end
 if action=="loadout" or action=="kit" then
  if p:GetAttribute("RiftMap")~="Lobby" or p:GetAttribute("RiftQueued") or p:GetAttribute("RiftDuelId") then return end
  if action=="kit" then
   if aim==1 or aim==2 or aim==3 then p:SetAttribute("RiftKit",aim) end
  else
   local slot=expectedSlot
   if slot==nil then slot=table.find(weapons.Loadouts[1],aim) and 1 or 2 end
   if typeof(slot)~="number" or slot%1~=0 then return end
   local definition=weapons.Slots[slot]
   if definition and typeof(aim)=="number" and table.find(weapons.Loadouts[definition.category],aim) then p:SetAttribute(definition.attribute,aim) end
  end
  return
 end
 local duel=p:GetAttribute("RiftDuelId")
 local effectParent=workspace
 if duel then
  if p:GetAttribute("RiftDuelPhase")~="Fight" or not p:GetAttribute("RiftRoundAlive") then return end
  local arena=workspace.RiftDuels:FindFirstChild(p:GetAttribute("RiftDuelArena") or "")
  effectParent=arena and arena:FindFirstChild("RoundEffects")
  if not effectParent then return end
 elseif not p:GetAttribute("RiftMap") or p:GetAttribute("RiftMap")=="Lobby" then
  return
 end
 local now=os.clock()
 if action=="equip" then
  if typeof(aim)~="number" or aim%1~=0 or not weapons.Slots[aim] or aim==s.equipped then return end
  s.reload=nil
  s.equipped=aim
  s.nextShot=math.max(s.nextShot,now+.2)
  R:FireClient(p,"weaponState",aim,s.ammo[aim],false)
  return
 end
 local slot=s.equipped
 local weaponId=s.loadout[slot]
 local weapon=weapons[weaponId]
 if action=="reload" then
  if weapon.melee then return end
  if (expectedSlot and expectedSlot~=slot) or s.reload or s.ammo[slot]==weapon.magazine then return end
  local reload={}
  s.reload=reload
  R:FireClient(p,"weaponState",slot,s.ammo[slot],true)
  task.delay(weapon.reloadTime,function()
   if S[p]~=s or s.reload~=reload then return end
   s.ammo[slot]=weapon.magazine
   s.reload=nil
   R:FireClient(p,"weaponState",slot,s.ammo[slot],false)
  end)
  return
 end
 if typeof(action)~="string" or (action~="fire" and action~="itemAlt" and not cooldown[action]) then return end
 if duel and action==weapons.Kits[p:GetAttribute("RiftKit") or 1].omitted then return end
 if not finiteVector(aim) or not (aim.Magnitude>.99 and aim.Magnitude<1.01) then return end
 local origin=head.Position
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={c}
 local function useItem(alt)
  Items.Use({weapon=weapon,player=p,state=s,character=c,humanoid=h,origin=origin,aim=aim,params=params,parent=effectParent,remote=R,damage=damage,blast=blast,effect=effect,enemy=enemy,ally=function(a,b) return sameCombatSpace(a,b) and (not a:GetAttribute("RiftDuelId") or a:GetAttribute("RiftTeam")==b:GetAttribute("RiftTeam")) end,valid=function() return p.Parent==P and S[p]==s and h.Health>0 and effectParent.Parent~=nil and (not duel or (p:GetAttribute("RiftDuelPhase")=="Fight" and p:GetAttribute("RiftRoundAlive"))) end},alt)
 end
 if action=="itemAlt" then
  if not weapon.item or (expectedSlot and expectedSlot~=slot) or now<(s.itemAltReady or 0) then return end
  if not weapon.melee and weapon.name~="Satchel" and weapon.name~="Warper" then return end
  if weapon.name=="Fists" and h.FloorMaterial~=Enum.Material.Air then return end
  s.itemAltReady=now+3; useItem(true); return
 end
 if action=="fire" then
  if (expectedSlot and expectedSlot~=slot) or s.reload or s.ammo[slot]<=0 or now+.008<s.nextShot then return end
  local traceRange=Ballistics.TraceRange(weapon)
  local root=c:FindFirstChild("HumanoidRootPart")
  local speed=root and Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude or 0
  -- Account for a small amount of character replication travel while bounding
  -- camera displacement and checking every solid obstruction along that segment.
  if not weapon.item and cameraOrigin~=nil then
   local allowance=math.clamp(2+speed*.1,2,6)
   if not finiteVector(cameraOrigin) or (cameraOrigin-origin).Magnitude>allowance then return end
   local cameraOffset=cameraOrigin-origin
   if not cameraSegmentClear(origin,cameraOffset,c) then return end
   local cameraHit=shotRay(cameraOrigin,aim,traceRange,params,c)
   local target=cameraHit and cameraHit.Position or cameraOrigin+aim*traceRange
   local delta=target-origin
   if delta.Magnitude>.01 then aim=delta.Unit end
  end
  s.spray=now-(s.lastShot or 0)>.28 and 1 or (s.spray or 0)+1;s.lastShot=now
  s.nextShot=math.max(now,s.nextShot)+weapon.shotInterval
  Training.Shot(p)
  if not weapon.melee then s.ammo[slot]-=1 end
  R:FireClient(p,"weaponState",slot,s.ammo[slot],false)
  for _,other in P:GetPlayers() do
   if other~=p and sameCombatSpace(p,other) then
    local otherHead=other.Character and other.Character:FindFirstChild("Head")
    if otherHead and (otherHead.Position-origin).Magnitude<150 then
     R:FireClient(other,"shot",weaponId,head)
    end
   end
  end
  local spread=weapon.pellets and (aiming==true and weapon.ads or weapon.hip) or Ballistics.Error(weapon,math.clamp(speed/20,0,1),h.FloorMaterial==Enum.Material.Air,aiming==true and speed<18,s.spray)
  if weapon.item then useItem(false); return end
  if weapon.grenade then
   local ball=Instance.new("Part"); ball.Name="RiftGrenade"; ball.Shape=Enum.PartType.Ball; ball.Size=Vector3.one*.65; ball.Color=Color3.fromRGB(65,90,62); ball.CFrame=CFrame.new(origin+aim*2); ball.CanCollide=true; ball.Parent=effectParent
   ball:SetNetworkOwner(nil); ball.AssemblyLinearVelocity=aim*65+Vector3.new(0,20,0); D:AddItem(ball,3)
   task.delay(2.5,function() if ball.Parent then local position=ball.Position; ball:Destroy(); if p.Parent and S[p]==s then blast(p,effectParent,position,weapon) end end end)
   return
  end
  local hits={}
  local pellets=weapon.pellets or 1
  local pelletDamage=weapon.bodyDamage/pellets
  for pellet=1,pellets do
   local direction=aimWithSpread(aim,spread)
   local hit=shotRay(origin,direction,traceRange,params,c)
   local dest=hit and hit.Position or origin+direction*traceRange
   if pellet==1 then
    for _,viewer in P:GetPlayers() do if viewer==p or sameCombatSpace(p,viewer) then R:FireClient(viewer,"impact",origin,dest,hit and hit.Normal or -aim,hit and hit.Material or Enum.Material.Air,hit and hitCharacter(hit.Instance)~=nil) end end
   end
   if weapon.blastRadius then
    local directTarget=hit and hitCharacter(hit.Instance)
    blast(p,effectParent,hit and dest+hit.Normal*.15 or dest,weapon,directTarget)
   elseif hit then
    local model=hitCharacter(hit.Instance)
    if model then
     local headshot=isHeadHit(hit.Instance,model)
     local info=hits[model] or {amount=0,headshot=false}
     local falloff=Ballistics.Falloff(weapon,hit.Distance)
     info.amount+=pelletDamage*(headshot and weapon.headMultiplier or 1)*falloff
     info.headshot=info.headshot or headshot
     hits[model]=info
    end
   end
  end
  for model,info in hits do damage(p,model,info.amount,info.headshot,origin) end
  return
 end
 if now<(s.ready[action] or 0) then return end
 s.ready[action]=now+cooldown[action]
 R:FireClient(p,"cooldown",action,cooldown[action])
 R:FireClient(p,"abilityCast",action)
 local hit=workspace:Raycast(origin,aim*65,params)
 local pos=hit and (hit.Position+hit.Normal*1.6) or origin+aim*65
 if action=="smoke" then
  local cloud=effect(effectParent,pos,Vector3.one*22,Color3.fromRGB(61,45,91),0,9,true)
  cloud.Material=Enum.Material.SmoothPlastic
  R:FireAllClients("smoke",cloud)
 elseif action=="flash" then
  effect(effectParent,pos,Vector3.one*2,Color3.new(1,1,.85),0,.55,true)
  task.delay(.55,function()
   if S[p]~=s or (duel and not effectParent.Parent) then return end
   effect(effectParent,pos,Vector3.one*8,Color3.new(1,1,.9),.18,.18,true)
   for _,other in P:GetPlayers() do
    local target=other.Character and other.Character:FindFirstChild("Head")
    if target and sameCombatSpace(p,other) then
     local delta=pos-target.Position
     local sight=RaycastParams.new(); sight.FilterType=Enum.RaycastFilterType.Exclude; sight.FilterDescendantsInstances={other.Character}
     if delta.Magnitude<65 and not workspace:Raycast(target.Position,delta,sight) then R:FireClient(other,"flash",pos) end
    end
   end
  end)
 else
  local pulse=effect(effectParent,pos,Vector3.one*2,Color3.fromRGB(38,240,212),.55,.65,true)
  game:GetService("TweenService"):Create(pulse,TweenInfo.new(.6),{Size=Vector3.one*80,Transparency=1}):Play()
  local function scan()
   if S[p]~=s or (duel and not effectParent.Parent) then return end
   local targets={}
   for _,other in P:GetPlayers() do
    if other~=p and other.Character and enemy(p,other) then table.insert(targets,other.Character) end
   end
   if not duel then
    for _,bot in workspace.RiftArena.Targets:GetChildren() do table.insert(targets,bot) end
   end
   for _,model in targets do
    local root=model:FindFirstChild("HumanoidRootPart")
    local hum=model:FindFirstChildOfClass("Humanoid")
    if root and hum and hum.Health>0 and (root.Position-pos).Magnitude<=40 then
     R:FireClient(p,"reveal",model)
    end
   end
  end
  scan()
  task.delay(1,scan)
  task.delay(2,scan)
 end
end)
local folder=workspace.RiftArena.Targets
for _,bot in folder:GetChildren() do
 local template=bot:Clone()
 local function bind(model)
  model.Humanoid.Died:Connect(function()
   task.delay(3,function() model:Destroy(); local replacement=template:Clone(); replacement.Parent=folder; bind(replacement) end)
  end)
 end
 bind(bot)
end