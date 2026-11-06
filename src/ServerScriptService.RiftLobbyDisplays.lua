-- Lobby weapon display stands: "Equip" prompt puts that weapon in its loadout slot (same rules as the Arsenal).
local RiftData=require(script.Parent.RiftData) -- installs weapons.OwnershipProvider
local weapons=require(game.ReplicatedStorage.RiftWeapons)
local sync=game.ReplicatedStorage:WaitForChild("RiftShopSync")
local displays=workspace.RiftLobby:WaitForChild("WeaponDisplays")
for _,stand in displays:GetChildren() do
 local id=stand:GetAttribute("WeaponId")
 local prompt=stand:FindFirstChild("Equip",true)
 if not id or not prompt then continue end
 prompt.Triggered:Connect(function(player)
  if player:GetAttribute("RiftMap")~="Lobby" or player:GetAttribute("RiftQueued") or player:GetAttribute("RiftDuelId") then return end
  if not weapons.IsUnlocked(player,id) then sync:FireClient(player,"offer","w:"..id); return end
  local slot=weapons.SlotOf(id)
  local definition=slot and weapons.Slots[slot]
  if not definition then return end
  player:SetAttribute(definition.attribute,id)
  player:SetAttribute("RiftPending"..slot,nil)
  local st=RiftData.State(player)
  local profile=(st=="ready" or st=="nosave") and RiftData.Get(player)
  if profile and profile.equipped and profile.equipped.loadout then profile.equipped.loadout[slot]=id; RiftData.SaveSoon(player) end
 end)
end
