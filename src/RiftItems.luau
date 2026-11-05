local Items={}
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
function Items.Use(x,alt)
 local w,p,s=x.weapon,x.player,x.state
 local root=x.character:FindFirstChild("HumanoidRootPart")
 if not root then return end
 local function targets(position,radius,callback)
  local seen={}
  for _,part in workspace:GetPartBoundsInRadius(position,radius) do
   local model=part:FindFirstAncestorOfClass("Model")
   if model and not seen[model] and model~=x.character then
    seen[model]=true
    local hum=model:FindFirstChildOfClass("Humanoid"); local r=model:FindFirstChild("HumanoidRootPart")
    local other=Players:GetPlayerFromCharacter(model)
    if hum and r and hum.Health>0 and ((other and x.enemy(p,other)) or (not p:GetAttribute("RiftDuelId") and model.Parent==workspace.RiftArena.Targets)) then
     local delta=r.Position-position; local hit=workspace:Raycast(position,delta,x.params)
     if not hit or hit.Instance:IsDescendantOf(model) then callback(model,hum,r,other) end
    end
   end
  end
 end
 local function boost(direction,power)
  root.AssemblyLinearVelocity=direction*power+Vector3.new(0,28,0)
 end
 local function block(position,size,color,life)
  local part=x.effect(x.parent,position,size,color,0,life,false); part.Name=w.name; return part
 end
 local function area(position,amount,radius)
  x.blast(p,x.parent,position,{bodyDamage=amount,blastRadius=radius})
 end
 local function impact(position)
  if not x.valid() then return end
  if w.name=="Smoke Grenade" then
   local cloud=x.effect(x.parent,position,Vector3.one*22,Color3.fromRGB(75,83,91),.15,9,true)
   x.remote:FireAllClients("smoke",cloud)
  elseif w.name=="Flashbang" then
   x.effect(x.parent,position,Vector3.one*4,Color3.new(1,1,1),.15,.3,true)
   for _,other in Players:GetPlayers() do
    local head=other.Character and other.Character:FindFirstChild("Head")
    if head and x.enemy(p,other) and (head.Position-position).Magnitude<55 then
     local ray=workspace:Raycast(position,head.Position-position,x.params)
     if not ray or ray.Instance:IsDescendantOf(other.Character) then x.remote:FireClient(other,"flash",position) end
    end
   end
  elseif w.name=="Molotov" then
   local fire=block(position,Vector3.new(16,.3,16),Color3.fromRGB(235,115,42),6)
   task.spawn(function() for _=1,12 do if not x.valid() or not fire.Parent then break end; targets(position,9,function(model) x.damage(p,model,8,false,position) end); task.wait(.5) end end)
  else area(position,w.bodyDamage,w.blastRadius or 13) end
 end
 local hit=workspace:Raycast(x.origin,x.aim*(w.range or 60),x.params)
 local point=hit and hit.Position+hit.Normal*.8 or x.origin+x.aim*(w.range or 60)
 if alt then
  if w.name=="Fists" then
   if x.humanoid.FloorMaterial==Enum.Material.Air and not s.airJumpUsed then s.airJumpUsed=true; root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X,48,root.AssemblyLinearVelocity.Z) end
  elseif w.name=="Katana" or w.name=="Riot Shield" then p:SetAttribute("RiftGuardUntil",os.clock()+1.2); p:SetAttribute("RiftGuardReflect",w.name=="Katana")
  elseif w.name=="Trowel" then local wall=block(root.Position+root.CFrame.LookVector*6,Vector3.new(9,7,1),Color3.fromRGB(125,113,94),8); wall.CanCollide=true; wall.CanQuery=true
  elseif w.name=="Spear" then local thrown=workspace:Raycast(x.origin,x.aim*90,x.params); if thrown then x.damage(p,thrown.Instance:FindFirstAncestorOfClass("Model"),45,false,x.origin) end
  elseif w.name=="Maul" then x.effect(x.parent,root.Position,Vector3.new(20,.3,20),Color3.fromRGB(145,128,100),.5,.3,false); targets(root.Position,12,function(model) x.damage(p,model,35,false,root.Position) end)
  elseif w.name=="Satchel" then if s.satchel and s.satchel.Parent then local pos=s.satchel.Position; s.satchel:Destroy(); s.satchel=nil; area(pos,55,14) end
  elseif w.name=="Warper" then
   if s.portal and s.portal.Parent then
    local first=s.portal; s.portal=nil
    local second=block(point,Vector3.new(5,.3,5),Color3.fromRGB(90,160,170),12)
    local last={}
    for _,pair in {{first,second},{second,first}} do pair[1].CanTouch=true; pair[1].Touched:Connect(function(part)
     local character=part:FindFirstAncestorOfClass("Model"); local other=character and Players:GetPlayerFromCharacter(character)
     if x.valid() and other and x.ally(p,other) and pair[2].Parent and os.clock()-(last[other] or 0)>1 then last[other]=os.clock(); character:PivotTo(CFrame.new(pair[2].Position+Vector3.new(0,4,0))) end
    end) end
   end
  else boost(x.aim,w.name=="Chainsaw" and 58 or 44) end
  return
 end
 if w.melee then
  targets(x.origin,w.range,function(model,hum,r)
   local delta=r.Position-x.origin
   if delta.Magnitude<.01 or x.aim:Dot(delta.Unit)>.35 then
    local amount=w.bodyDamage
    if w.name=="Knife" and r.CFrame.LookVector:Dot((root.Position-r.Position).Unit)<-.5 then amount*=2 end
    x.damage(p,model,amount,false,x.origin)
    if w.name=="Maul" or w.name=="Battle Axe" or w.name=="Riot Shield" then r.AssemblyLinearVelocity+=x.aim*35+Vector3.new(0,12,0) end
   end
  end)
 elseif w.name=="Medkit" or w.name=="Elixir" then
  x.humanoid.Health=math.min(x.humanoid.MaxHealth,x.humanoid.Health+(w.name=="Medkit" and 70 or 35))
  if w.name=="Elixir" then boost(x.aim,35) end
 elseif w.name=="Warpstone" then
  if hit then
   local destination=point+Vector3.new(0,3,0)
   local clear=OverlapParams.new(); clear.FilterType=Enum.RaycastFilterType.Exclude; clear.FilterDescendantsInstances={x.character}
   local safe=true; for _,part in workspace:GetPartBoundsInBox(CFrame.new(destination),Vector3.new(3,5,3),clear) do if part.CanCollide then safe=false; break end end
   if safe then x.character:PivotTo(CFrame.lookAt(destination,destination+x.aim)) end
  end
 elseif w.name=="Grappler" then if hit then boost((point-root.Position).Unit,65) end
 elseif w.name=="War Horn" then
  for _,other in Players:GetPlayers() do
   local r=other.Character and other.Character:FindFirstChild("HumanoidRootPart")
   if r and x.ally(p,other) and (r.Position-root.Position).Magnitude<30 then other:SetAttribute("RiftEmpoweredUntil",os.clock()+6) end
  end
 elseif w.name=="Freeze Ray" then
  local length=(point-x.origin).Magnitude; if length>.1 then local beam=block((point+x.origin)*.5,Vector3.new(.12,.12,length),Color3.fromRGB(120,210,230),.15);beam.CFrame=CFrame.lookAt((point+x.origin)*.5,point) end
  if hit then
   local model=hit.Instance:FindFirstAncestorOfClass("Model"); x.damage(p,model,5,false,x.origin)
   targets(point,2,function(_,hum,r) r.AssemblyLinearVelocity*=.25; hum:SetAttribute("RiftFrozenUntil",os.clock()+1.5) end)
  end
 elseif w.name=="Jump Pad" then
  local pad=block(root.Position+root.CFrame.LookVector*5-Vector3.new(0,2.5,0),Vector3.new(6,.4,6),Color3.fromRGB(73,151,159),15)
  pad.CanCollide=true; pad.CanTouch=true; local last={}
  pad.Touched:Connect(function(part) local model=part:FindFirstAncestorOfClass("Model"); local other=model and Players:GetPlayerFromCharacter(model); local r=model and model:FindFirstChild("HumanoidRootPart")
   if x.valid() and other and r and x.ally(p,other) and os.clock()-(last[other] or 0)>.8 then last[other]=os.clock(); r.AssemblyLinearVelocity=Vector3.new(r.AssemblyLinearVelocity.X,75,r.AssemblyLinearVelocity.Z) end
  end)
 elseif w.name=="Satchel" or w.name=="Subspace Tripmine" or w.name=="Warper" then
  local device=block(point,Vector3.new(2,.4,2),Color3.fromRGB(120,146,136),20)
  if w.name=="Satchel" then s.satchel=device
  elseif w.name=="Warper" then s.portal=device
  else task.spawn(function() task.wait(.8); while device.Parent and x.valid() do local found=false; targets(device.Position,7,function() found=true end); if found then local pos=device.Position; device:Destroy(); area(pos,50,13); break end; task.wait(.2) end end) end
 elseif w.name=="RNG Dice" then
  local roll=math.random(1,3); if roll==1 then x.humanoid.Health=math.min(100,x.humanoid.Health+25) elseif roll==2 then boost(x.aim,45) else impact(point) end
 else
  local ball=block(x.origin+x.aim*2,Vector3.one*.6,Color3.fromRGB(86,116,82),4); ball.Shape=Enum.PartType.Ball; ball.Anchored=false; ball.CanCollide=true; ball.CanQuery=false; ball:SetNetworkOwner(nil); ball.AssemblyLinearVelocity=x.aim*60+Vector3.new(0,20,0)
  task.delay(w.name=="Molotov" and 1 or 2.5,function() if ball.Parent then local pos=ball.Position; ball:Destroy(); impact(pos) end end)
 end
end
return Items
