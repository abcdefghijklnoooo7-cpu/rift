local remote=game.ReplicatedStorage.RiftTravel
local last={}
local resetCombat=script.Parent.RiftResetCombat
local lobbySpawn=workspace.RiftLobby.LobbySpawn
local function spawn(player,character)
 local map=workspace.RiftMaps:FindFirstChild(player:GetAttribute("RiftMap") or "")
 local name=player:GetAttribute("RiftMap")
 if map or name=="Training Arena" then
  local root=character:WaitForChild("HumanoidRootPart",8)
  if not root or player.Character~=character or player:GetAttribute("RiftMap")~=name then return end
  local pos=map and map:GetAttribute("Spawn") or workspace.RiftArena:GetAttribute("Spawn") or Vector3.new(0,14,82)
  local aim=map and map:GetAttribute("Aim") or workspace.RiftArena:GetAttribute("Aim") or Vector3.new(0,14,0)
  character:PivotTo(CFrame.lookAt(pos,aim))
 end
end
local function bind(player)
 player.CharacterAdded:Connect(function(character) spawn(player,character) end)
end
game.Players.PlayerAdded:Connect(bind)
for _,player in game.Players:GetPlayers() do bind(player) end
game.Players.PlayerRemoving:Connect(function(player) last[player]=nil end)
remote.OnServerEvent:Connect(function(player,name)
 if typeof(name)~="string" or os.clock()-(last[player] or -10)<2 then return end
 local map=workspace.RiftMaps:FindFirstChild(name)
 if player:GetAttribute("RiftDuelId") or player:GetAttribute("RiftQueued") then return end
 if not map and name~="Training Arena" and name~="Lobby" then return end
 local character=player.Character
 local hum=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not root or not hum or hum.Health<=0 then return end
 last[player]=os.clock(); player:SetAttribute("RiftMap",name)
 local pos=map and map:GetAttribute("Spawn") or workspace.RiftArena:GetAttribute("Spawn") or Vector3.new(0,14,82)
 local aim=map and map:GetAttribute("Aim") or workspace.RiftArena:GetAttribute("Aim") or Vector3.new(0,14,0)
 local destination=CFrame.lookAt(pos,aim)
 if name=="Lobby" then destination=lobbySpawn.CFrame+Vector3.new(0,3,0) end
 character:PivotTo(destination)
 root.AssemblyLinearVelocity=Vector3.zero
 resetCombat:Fire(player)
end)
