-- Client audio: independent effects/music buses and action-driven cues.
local Audio={}
local service=game:GetService("SoundService")
local player=game.Players.LocalPlayer
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
Audio.Effects=service:FindFirstChild("RiftEffects") or Instance.new("SoundGroup")
Audio.Effects.Name="RiftEffects"; Audio.Effects.Parent=service
local musicBus=Instance.new("SoundGroup"); musicBus.Name="RiftMusic"; musicBus.Parent=service
local function volume()
 Audio.Effects.Volume=player:GetAttribute("RiftVolume") or 1
 musicBus.Volume=player:GetAttribute("RiftMusicVolume") or .5
end
player:GetAttributeChangedSignal("RiftVolume"):Connect(volume)
player:GetAttributeChangedSignal("RiftMusicVolume"):Connect(volume); volume()
local sources={
 equip={"rbxassetid://9120409666",.18,1.6},
 reloadEnd={"rbxassetid://9120409666",.12,1.9},
 dash={"rbxasset://sounds/action_jump.mp3",.2,1.5},
 slide={"rbxasset://sounds/action_footsteps_plastic.mp3",.15,.85},
 land={"rbxasset://sounds/action_footsteps_plastic.mp3",.13,.7},
 hurt={"rbxasset://sounds/impact_water.mp3",.1,1.8},
 round={"rbxasset://sounds/volume_slider.ogg",.16,1.7},
 queue={"rbxasset://sounds/volume_slider.ogg",.1,1.3},
}
local templates={}
for name,data in sources do
 local s=Instance.new("Sound"); s.Name="RiftCue_"..name; s.SoundId=data[1]; s.Volume=data[2]; s.PlaybackSpeed=data[3]; s.SoundGroup=Audio.Effects; s.Parent=service; templates[name]=s
end
function Audio.Play(name)
 local template=templates[name]; if not template then return end
 local s=template:Clone(); s.Parent=service; s:Play(); Debris:AddItem(s,4)
end
local music=Instance.new("Sound"); music.Name="RiftLobbyMusic"; music.SoundId="rbxassetid://9042295159"; music.Looped=true; music.Volume=0; music.SoundGroup=musicBus; music.Parent=service
local fade,generation
local function lobbyMusic()
 generation=(generation or 0)+1; local current=generation
 local lobby=player:GetAttribute("RiftMap")=="Lobby" and not player:GetAttribute("RiftDuelPhase")
 if fade then fade:Cancel() end
 if lobby and not music.IsPlaying then music:Play() end
 fade=Tween:Create(music,TweenInfo.new(.7,Enum.EasingStyle.Quad),{Volume=lobby and .22 or 0}); fade:Play()
 if not lobby then task.delay(.7,function() if generation==current then music:Pause() end end) end
end
player:GetAttributeChangedSignal("RiftMap"):Connect(lobbyMusic)
player:GetAttributeChangedSignal("RiftDuelPhase"):Connect(function()
 local phase=player:GetAttribute("RiftDuelPhase")
 if phase=="Countdown" or phase=="Fight" then Audio.Play("round") end
 lobbyMusic()
end)
player:GetAttributeChangedSignal("RiftQueued"):Connect(function() Audio.Play("queue") end)
lobbyMusic()
task.spawn(function()
 local preload={music}; for _,s in templates do table.insert(preload,s) end
 pcall(function() game:GetService("ContentProvider"):PreloadAsync(preload) end)
end)
return Audio
