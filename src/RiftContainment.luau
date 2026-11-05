-- Server safeguard for dash, teleport utilities, physics pushes and out-of-bounds falls.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local lastSafe={}
local elapsed=0
local function region(player)
 local duel=player:GetAttribute('RiftDuelArena')
 if player:GetAttribute('RiftDuelId') and duel then
  local map=workspace.RiftDuels:FindFirstChild(duel)
  if map then local spawn=map:GetAttribute(player:GetAttribute('RiftTeam')==2 and 'SpawnB' or 'SpawnA');return map,spawn,spawn.X,-139,139 end
 end
 local name=player:GetAttribute('RiftMap')
 if name=='Training Arena' then return workspace.RiftArena,workspace.RiftArena:GetAttribute('Spawn') or Vector3.new(0,14,110),0,-257,151 end
 local map=name and (workspace.RiftMaps:FindFirstChild(name) or workspace.RiftDuels:FindFirstChild(name))
 if map then local spawn=map:GetAttribute('Spawn') or map:GetAttribute('SpawnA');if spawn then return map,spawn,spawn.X,-139,139 end end
end
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.2 then return end;elapsed=0
 for _,p in Players:GetPlayers() do
  local c=p.Character;local root=c and c:FindFirstChild('HumanoidRootPart');local hum=c and c:FindFirstChildOfClass('Humanoid')
  if not root or not hum or hum.Health<=0 then continue end
  local map,spawn,cx,zmin,zmax=region(p)
  if not map then lastSafe[p]=nil;continue end
  local x=root.Position.X-cx;local z=root.Position.Z
  local limit=map==workspace.RiftArena and 147 or 139
  local inside=math.abs(x)<=limit and z>=zmin and z<=zmax and root.Position.Y>=5 and root.Position.Y<=155
  if not inside then
   local record=lastSafe[p];local destination=record and record.map==map and record.character==c and record.cf or CFrame.lookAt(spawn,Vector3.new(cx,spawn.Y,0))
   c:PivotTo(destination);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
  elseif hum.FloorMaterial~=Enum.Material.Air then
   local q=RaycastParams.new();q.FilterType=Enum.RaycastFilterType.Include;q.FilterDescendantsInstances={map}
   if workspace:Raycast(root.Position,Vector3.new(0,-8,0),q) then lastSafe[p]={map=map,character=c,cf=c:GetPivot()} end
  end
 end
end)
Players.PlayerRemoving:Connect(function(p)lastSafe[p]=nil end)
