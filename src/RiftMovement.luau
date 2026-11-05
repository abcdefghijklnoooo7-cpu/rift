-- Environments contain authored detail; obsolete procedural decoration removed.
local players=game:GetService("Players")
local run=game:GetService("RunService")
local remote=game.ReplicatedStorage.RiftAction
local reset=script.Parent.RiftResetCombat
local states={}
local features={["Training Arena"]={boosts={},hazards={}}}
for _,folder in {workspace.RiftMaps,workspace.RiftDuels} do for _,map in folder:GetChildren() do features[map.Name]={boosts={},hazards={}} end end
local motionTokens={}

local function launch(root,impulse)
 if not root:CanSetNetworkOwnership() then return end
 local token={}
 motionTokens[root]=token
 root:SetNetworkOwner(nil)
 root:ApplyImpulse(impulse*root.AssemblyMass)
 task.delay(.24,function()
  if motionTokens[root]~=token then return end
  motionTokens[root]=nil
  if root.Parent and root:CanSetNetworkOwnership() then root:SetNetworkOwnershipAuto() end
 end)
end

local function makePart(parent,name,size,position,color,material)
 local part=Instance.new("Part")
 part.Name=name
 part.Anchored=true
 part.Size=size
 part.Position=position
 part.Color=color
 part.Material=material
 part.Parent=parent
 return part
end

local function addFeatures(map,mapName,center,duel)
 local folder=Instance.new("Folder")
 folder.Name="ArenaFeatures"
 folder.Parent=map
 local function place(name,size,position,color,material)
  local offset=position-center
  return makePart(folder,name,Vector3.new(size.X*1.35,size.Y,size.Z*1.35),center+Vector3.new(offset.X*1.35,offset.Y,offset.Z*1.35),color,material)
 end
 local boosts={}
 local hazards={}
 features[mapName]={boosts=boosts,hazards=hazards}
 for _,side in {-1,1} do
  local padPosition=center+Vector3.new(side*31,.28,side*32)
  if mapName=="Training Arena" then padPosition=center+(side==1 and Vector3.new(74,.28,-7) or Vector3.new(86,.28,-77)) end
  if mapName=="Red Mesa" and side==-1 then padPosition=center+Vector3.new(-38,.28,-52) end
  local trampoline=place("Trampoline",Vector3.new(9,.55,9),padPosition,Color3.fromRGB(42,186,237),Enum.Material.Neon)
  table.insert(boosts,trampoline)
  local hazard=place("Live hazard",Vector3.new(9,.16,10),center+Vector3.new(mapName=="Training Arena" and -84 or side*(duel and 13 or 9),.13,side*20),Color3.fromRGB(247,89,33),Enum.Material.Neon)
  table.insert(hazards,hazard)
  if duel then
   local deckColor=side==1 and Color3.fromRGB(82,132,173) or Color3.fromRGB(173,111,79)
   place("Flank step",Vector3.new(5,2,6),center+Vector3.new(side*34,1,0),deckColor,Enum.Material.Concrete)
   place("Flank platform",Vector3.new(7,4,6),center+Vector3.new(side*40,2,0),deckColor,Enum.Material.Concrete)
  end
 end
end

local function resetPlayer(player)
 states[player]={stamina=100,sprint=false,exhausted=false,dashUntil=0,boostUntil=0,hazardUntil=0,recoverAt=0,slideUntil=0,slideReady=0}
 player:SetAttribute("RiftStamina",100)
 player:SetAttribute("RiftSprinting",false)
 player:SetAttribute("RiftSliding",false)
end

local function bind(player)
 resetPlayer(player)
 player.CharacterAdded:Connect(function() resetPlayer(player) end)
end
players.PlayerAdded:Connect(bind)
players.PlayerRemoving:Connect(function(player) states[player]=nil end)
for _,player in players:GetPlayers() do bind(player) end
reset.Event:Connect(resetPlayer)

local function activeMap(player)
 if player:GetAttribute("RiftDuelId") then
  if player:GetAttribute("RiftDuelPhase")=="Fight" and player:GetAttribute("RiftRoundAlive") then return player:GetAttribute("RiftDuelArena") end
  return nil
 end
 return player:GetAttribute("RiftMap")
end

remote.OnServerEvent:Connect(function(player,action,arg)
 if action~="sprint" and action~="dash" and action~="slide" then return end
 local state=states[player]
 if not state then return end
 if action=="sprint" and arg==false then state.sprint=false; return end
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not features[activeMap(player) or ""] or not root or root.Anchored or not humanoid or humanoid.Health<=0 then return end
 if action=="sprint" and arg==true then
  state.sprint=true
 elseif action=="dash" and state.stamina>=30 and os.clock()>=state.dashUntil then
  state.stamina-=30
  state.dashUntil=os.clock()+1.2
  state.recoverAt=os.clock()+.7
  local heading=root.CFrame.LookVector
  local flat=Vector3.new(heading.X,0,heading.Z)
  if flat.Magnitude>.01 then launch(root,flat.Unit*46) end
  player:SetAttribute("RiftStamina",math.floor(state.stamina))
  remote:FireClient(player,"abilityCast","dash")
 elseif action=="slide" then
  local now=os.clock()
  local velocity=root.AssemblyLinearVelocity
  local horizontal=Vector3.new(velocity.X,0,velocity.Z)
  if not state.sprint or state.stamina<16 or now<state.slideReady or horizontal.Magnitude<14 or humanoid.FloorMaterial==Enum.Material.Air then return end
  state.stamina-=16
  state.slideUntil=now+.48
  state.slideReady=now+1.2
  state.recoverAt=now+.65
  launch(root,horizontal.Unit*math.max(0,37-horizontal.Magnitude))
  player:SetAttribute("RiftSliding",true)
  remote:FireClient(player,"abilityCast","slide")
 end
end)

local function onPlate(root,plate,maxHeight)
 local offset=root.Position-plate.Position
 return math.abs(offset.X)<plate.Size.X*.5 and math.abs(offset.Z)<plate.Size.Z*.5 and offset.Y>=0 and offset.Y<maxHeight
end

local elapsed=0
run.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<.1 then return end
 local step=math.min(elapsed,.25)
 elapsed=0
 local now=os.clock()
 for player,state in states do
  local character=player.Character
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  local root=character and character:FindFirstChild("HumanoidRootPart")
  if not humanoid or humanoid.Health<=0 or not root then continue end
  local region=features[activeMap(player) or ""]
  if state.stamina<=0 then state.exhausted=true end
  if state.exhausted and state.stamina>=30 then state.exhausted=false end
  local sliding=region~=nil and now<state.slideUntil and not root.Anchored
  local sprint=region~=nil and state.sprint and not sliding and not state.exhausted and not root.Anchored
  local velocity=root.AssemblyLinearVelocity
  local moving=Vector3.new(velocity.X,0,velocity.Z).Magnitude>2
  if sprint and moving then
   state.stamina=math.max(0,state.stamina-step*24)
   state.recoverAt=now+.45
  elseif not sprint and now>=state.recoverAt then
   state.stamina=math.min(100,state.stamina+step*18)
  end
  local speed=sliding and 28 or (sprint and 25 or 17)
  if (humanoid:GetAttribute("RiftFrozenUntil") or 0)>os.clock() then speed=math.min(speed,6) end
  if humanoid.WalkSpeed~=speed then humanoid.WalkSpeed=speed end
  player:SetAttribute("RiftStamina",math.floor(state.stamina))
  player:SetAttribute("RiftSprinting",sprint and moving)
  player:SetAttribute("RiftSliding",sliding)
  if not region or root.Anchored then continue end
  if now>=state.boostUntil and velocity.Y<10 then
   for _,pad in region.boosts do
    if onPlate(root,pad,4.8) then
     state.boostUntil=now+1.1
     launch(root,Vector3.new(0,66-velocity.Y,0))
     remote:FireClient(player,"abilityCast","bounce")
     break
    end
   end
  end
  if now>=state.hazardUntil then
   for _,plate in region.hazards do
    if onPlate(root,plate,4.2) then
     state.hazardUntil=now+.75
     humanoid:TakeDamage(14)
     remote:FireClient(player,"damageFrom")
     break
    end
   end
  end
 end
end)
