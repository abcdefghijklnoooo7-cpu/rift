require(game.ReplicatedStorage.RiftEnvironment).Build()
-- Drills receive only accepted server shots and actual damage from RiftCombat.
local Training={}
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Remote=game.ReplicatedStorage.RiftAction
local folder=workspace.RiftArena.Targets
local source=folder:FindFirstChild('Training Target 1')
assert(source,'Training Target 1 is required as the training mannequin template')
local template=source:Clone()
local modes={'Stationary','Moving','Flick','Reaction','Precision','Spray','Switching','Timed'}
local lanes={-110,-66,-22,22,66,110}
local sessions={}
local rng=Random.new()
local function report(p,s)
 if p.Parent~=Players then return end
 local caption=s.mode
 if s.done then caption..=' · complete'
 elseif s.mode=='Reaction' then caption..=s.phase=='Waiting' and ' · wait for target' or ' · shoot now'
 elseif s.mode=='Switching' then caption..=' · shoot the illuminated target' end
 Remote:FireClient(p,'training',caption,s.shots,s.hits,s.heads,s.damage,math.max(0,math.ceil(s.finish-os.clock())),s.reactions>0 and math.floor(s.reactionTotal/s.reactions) or 0,s.difficulty)
end
local function clear(s)
 for _,m in s.targets do m:Destroy() end
 table.clear(s.targets)
end
local function restoreLane(s)
 for part,state in s.laneParts or {} do
  if part.Parent then part.Transparency=state[1];part.CanCollide=state[3];part.CanQuery=state[2] end
 end
 s.laneParts=nil
end
local function stop(p)
 local s=sessions[p]
 if s then clear(s);restoreLane(s);sessions[p]=nil end
end
local function valid(p,s)
 return sessions[p]==s and not s.done and p.Parent==Players and p:GetAttribute('RiftMap')=='Training Arena' and not p:GetAttribute('RiftDuelId') and os.clock()<s.finish
end
local function setActive(m,on)
 m:SetAttribute('DrillActive',on)
 for _,part in m:GetDescendants() do
  if part:IsA('BasePart') then
   if part.Name~='HumanoidRootPart' then
    part.Transparency=on and 0 or .9
   end
   part.CanQuery=on and part.Name~='HumanoidRootPart'
  end
 end
 local h=m:FindFirstChild('ActiveTarget')
 if h then h.Enabled=on end
 if on then m:SetAttribute('ActivatedAt',os.clock()) end
end
local function removeTarget(s,m)
 local index=table.find(s.targets,m)
 if index then table.remove(s.targets,index) end
 m:Destroy()
end
local populate
local function makeTarget(p,s,index,x,z)
 local m=template:Clone()
 m.Name='Drill '..p.UserId..' '..index
 m:SetAttribute('TrainingOwner',p.UserId)
 m:SetAttribute('TrainingSession',s.token)
 m:SetAttribute('DrillIndex',index)
 local scale=s.mode=='Precision' and .62 or (1-(s.difficulty-1)*.12)
 if scale~=1 then m:ScaleTo(scale) end
 local base=Vector3.new(x,12.65,z)
 m:PivotTo(CFrame.new(base));m:SetAttribute('DrillBase',base)
 for _,part in m:GetDescendants() do
  if part:IsA('BasePart') then part.Anchored=true;part.CanCollide=false;part.CanTouch=false end
 end
 local h=m:FindFirstChildOfClass('Humanoid')
 h.BreakJointsOnDeath=false
 local oneHitDrill=s.mode=='Flick' or s.mode=='Reaction' or s.mode=='Switching' or s.mode=='Timed'
 h.MaxHealth=(s.mode=='Spray' or oneHitDrill) and 100000 or 100;h.Health=h.MaxHealth
 local glow=Instance.new('Highlight');glow.Name='ActiveTarget';glow.FillColor=Color3.fromRGB(90,203,190);glow.FillTransparency=.78;glow.OutlineColor=Color3.fromRGB(163,237,218);glow.DepthMode=Enum.HighlightDepthMode.Occluded;glow.Parent=m
 m.Parent=folder;table.insert(s.targets,m)
 setActive(m,true)
 h.Died:Connect(function()
  if not valid(p,s) or m:GetAttribute('Retiring') then return end
  m:SetAttribute('Retiring',true)
  task.delay(.25,function()
   if not valid(p,s) then return end
   removeTarget(s,m)
   if #s.targets==0 then populate(p,s) end
  end)
 end)
 return m
end
local function reactionWait(p,s)
 s.phase='Waiting';s.nextActivation=os.clock()+rng:NextNumber(.65,2.3);s.expireTarget=nil
 for _,m in s.targets do setActive(m,false) end
 report(p,s)
end
populate=function(p,s)
 if not valid(p,s) then return end
 clear(s)
 local z=s.mode=='Precision' and -225 or (s.mode=='Spray' and -85 or -45)
 if s.mode=='Switching' or s.mode=='Timed' then
  for i=1,3 do makeTarget(p,s,i,lanes[s.lane]+(i-2)*8,z-(i%2)*5) end
  if s.mode=='Switching' then
   s.activeIndex=rng:NextInteger(1,3)
   for _,m in s.targets do setActive(m,m:GetAttribute('DrillIndex')==s.activeIndex) end
  end
 else
  local offset=(s.mode=='Flick' or s.mode=='Reaction') and rng:NextNumber(-10,10) or 0
  makeTarget(p,s,1,lanes[s.lane]+offset,z)
  if s.mode=='Reaction' then reactionWait(p,s) end
 end
end
local function start(p,mode,difficulty)
 if p.Parent~=Players or p:GetAttribute('RiftMap')~='Training Arena' or p:GetAttribute('RiftDuelId') then return false,'Enter the training range first' end
 if not table.find(modes,mode) then mode='Stationary' end
 difficulty=math.clamp(math.floor(tonumber(difficulty) or 1),1,3)
 local used={}
 for other,s in sessions do if other~=p and not s.done then used[s.lane]=true end end
 local lane
 for i=1,#lanes do if not used[i] then lane=i;break end end
 if not lane then return false,'All six training lanes are in use' end
 stop(p)
 local now=os.clock()
 local s={mode=mode,difficulty=difficulty,lane=lane,token=tostring(now)..':'..p.UserId,shots=0,hits=0,heads=0,damage=0,kills=0,targets={},finish=now+60,lastHitShot=-1,reactions=0,reactionTotal=0,phase='Active'}
 sessions[p]=s
 -- The default mannequin must not block a precision or reactive target farther down the lane.
 s.laneParts={}
 local defaultTarget=folder:FindFirstChild('Training Target '..lane)
 if defaultTarget then
  for _,part in defaultTarget:GetDescendants() do
   if part:IsA('BasePart') then
    s.laneParts[part]={part.Transparency,part.CanQuery,part.CanCollide}
    part.Transparency=1;part.CanCollide=false;part.CanQuery=false
   end
  end
 end
 -- Each player is positioned at their own assigned firing lane.
 local c=p.Character
 if c and c:FindFirstChild('HumanoidRootPart') then
  c:PivotTo(CFrame.lookAt(Vector3.new(lanes[lane],14,-5),Vector3.new(lanes[lane],14,-90)))
  c.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
 end
 populate(p,s);report(p,s)
 return true,lane
end
function Training.Shot(p)
 local s=sessions[p]
 if not s or not valid(p,s) then return end
 s.shots+=1
 -- Rate-limited reporting: sustained automatic fire does not send an extra HUD remote per shot.
 s.dirty=true
end
function Training.CanDamage(p,m)
 local owner=m:GetAttribute('TrainingOwner')
 if not owner then return true end
 local s=sessions[p]
 return owner==p.UserId and s~=nil and valid(p,s) and m:GetAttribute('TrainingSession')==s.token and m:GetAttribute('DrillActive')==true and not m:GetAttribute('Retiring')
end
function Training.Hit(p,m,head,damage)
 local s=sessions[p]
 if not s or not valid(p,s) or m:GetAttribute('TrainingOwner')~=p.UserId or m:GetAttribute('TrainingSession')~=s.token then return end
 if s.lastHitShot~=s.shots then s.hits+=1;s.lastHitShot=s.shots end
 if head then s.heads+=1 end
 s.damage+=damage
 local reaction=math.max(0,(os.clock()-(m:GetAttribute('ActivatedAt') or os.clock()))*1000)
 if s.mode=='Reaction' then s.reactions+=1;s.reactionTotal+=reaction end
 s.dirty=true
 if s.mode=='Flick' or s.mode=='Reaction' or s.mode=='Switching' or s.mode=='Timed' then
  m:SetAttribute('Retiring',true);setActive(m,false);s.kills+=1
  if s.mode=='Switching' then
   local old=s.activeIndex
   s.activeIndex=old%3+1
   for _,other in s.targets do
    local h=other:FindFirstChildOfClass('Humanoid');if h then h.Health=h.MaxHealth end
    other:SetAttribute('Retiring',nil)
    setActive(other,other:GetAttribute('DrillIndex')==s.activeIndex)
   end
  elseif s.mode=='Timed' then
   task.delay(.3/s.difficulty,function()
    if not valid(p,s) or not m.Parent then return end
    local h=m:FindFirstChildOfClass('Humanoid');if h then h.Health=h.MaxHealth end
    m:SetAttribute('Retiring',nil);setActive(m,true)
   end)
  else
   task.delay(s.mode=='Flick' and .12 or .25,function()if valid(p,s) then populate(p,s) end end)
  end
 end
end
function Training.Snapshot(p)
 local s=sessions[p]
 if not s then return nil end
 return {mode=s.mode,lane=s.lane,difficulty=s.difficulty,shots=s.shots,hits=s.hits,headHits=s.heads,damage=s.damage,targets=#s.targets,kills=s.kills,done=s.done==true,phase=s.phase}
end
local consoles={}
for _,p in workspace.RiftArena:GetChildren() do if p.Name=='Drill console' then table.insert(consoles,p) end end
table.sort(consoles,function(a,b)return a.Position.X<b.Position.X end)
local actions={'Start / next drill','Difficulty','Reset 60 second challenge','Test next primary','Return to stationary'}
for i,console in consoles do
 local prompt=Instance.new('ProximityPrompt');prompt.ActionText=actions[i];prompt.ObjectText='RIFT training';prompt.HoldDuration=.15;prompt.MaxActivationDistance=12;prompt.Parent=console
 local surf=Instance.new('BillboardGui');surf.Size=UDim2.fromOffset(240,50);surf.StudsOffset=Vector3.new(0,4,0);surf.MaxDistance=70;surf.Parent=console
 local l=Instance.new('TextLabel');l.Size=UDim2.fromScale(1,1);l.BackgroundColor3=Color3.fromRGB(30,48,58);l.TextColor3=Color3.fromRGB(212,234,235);l.Text=actions[i];l.TextScaled=true;l.Font=Enum.Font.Gotham;l.Parent=surf
 prompt.Triggered:Connect(function(p)
  if p:GetAttribute('RiftMap')~='Training Arena' or p:GetAttribute('RiftDuelId') then return end
  local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
  if not root or (root.Position-console.Position).Magnitude>15 then return end
  local s=sessions[p]
  if i==1 then start(p,modes[((s and table.find(modes,s.mode) or 0)%#modes)+1],s and s.difficulty)
  elseif i==2 then start(p,s and s.mode,(s and s.difficulty or 1)%3+1)
  elseif i==3 then start(p,s and s.mode,s and s.difficulty)
  elseif i==4 then
   local w=require(game.ReplicatedStorage.RiftWeapons);local ids=w.Loadouts[1];local id=p:GetAttribute(w.Slots[1].attribute);p:SetAttribute(w.Slots[1].attribute,ids[(table.find(ids,id) or 0)%#ids+1]);game.ServerScriptService.RiftResetCombat:Fire(p)
  else start(p,'Stationary',1) end
 end)
end
Training.Start=start
local tickAt=0
Run.Heartbeat:Connect(function()
 local now=os.clock();if now<tickAt then return end;tickAt=now+.05
 for p,s in sessions do
  if p:GetAttribute('RiftMap')~='Training Arena' or p:GetAttribute('RiftDuelId') then stop(p)
  elseif now>s.finish then
   if not s.done then s.done=true;clear(s);restoreLane(s);report(p,s) end
  elseif not s.done then
   if s.mode=='Moving' then
    for _,m in s.targets do if m.Parent then local b=m:GetAttribute('DrillBase');m:PivotTo(CFrame.new(b+Vector3.new(math.sin(now*(.6+s.difficulty*.55))*10,0,0))) end end
   elseif s.mode=='Reaction' then
    if s.phase=='Waiting' and now>=s.nextActivation then
     s.phase='Active';s.expireTarget=now+(2.2-s.difficulty*.4)
     for _,m in s.targets do m:SetAttribute('Retiring',nil);setActive(m,true) end
     report(p,s)
    elseif s.phase=='Active' and s.expireTarget and now>s.expireTarget then reactionWait(p,s) end
   end
   if now>(s.nextReport or 0) then s.nextReport=now+.2;report(p,s);s.dirty=false end
  end
 end
end)
local function bind(p)
 p.CharacterAdded:Connect(function()stop(p) end)
 p:GetAttributeChangedSignal('RiftMap'):Connect(function()if p:GetAttribute('RiftMap')~='Training Arena' then stop(p) end end)
end
Players.PlayerAdded:Connect(bind)
for _,p in Players:GetPlayers() do bind(p) end
Players.PlayerRemoving:Connect(stop)
return Training
