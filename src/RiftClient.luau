local Ballistics=require(game.ReplicatedStorage:WaitForChild("RiftBallistics"))
local GunFX=require(game.ReplicatedStorage:WaitForChild("RiftGunFX"))
local P=game.Players.LocalPlayer
local R=game.ReplicatedStorage:WaitForChild("RiftAction")
local U=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local T=game:GetService("TweenService")
local D=game:GetService("Debris")
local audio=game:GetService("SoundService")
local assets=game:GetService("ContentProvider")
local weapons=require(game.ReplicatedStorage:WaitForChild("RiftWeapons"))
local UI=require(game.ReplicatedStorage:WaitForChild("RiftUI"))
local C=UI.C
local Audio=require(game.ReplicatedStorage:WaitForChild("RiftAudio"))
local soundGroup=Audio.Effects
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health,false)
local gui=Instance.new("ScreenGui"); gui.Name="RiftHUD"; gui.ResetOnSpawn=false; gui.ScreenInsets=Enum.ScreenInsets.None; gui.IgnoreGuiInset=true; gui.Parent=P:WaitForChild("PlayerGui")
local function label(size,pos,anchor,caption,fontSize)
 local l=Instance.new("TextLabel"); l.Size=size; l.Position=pos; l.AnchorPoint=anchor
 l.BackgroundColor3=C.panel; l.BackgroundTransparency=.08; UI.corner(l,8)
 l.TextColor3=C.text; l.Font=Enum.Font.Gotham; l.TextSize=UI.typeSize(fontSize)
 l.Text=caption; l.Parent=gui; return l
end
local function bar(w,h,x,y)
 local f=Instance.new("Frame"); f.BorderSizePixel=0; f.Size=UDim2.fromOffset(w,h); f.Position=UDim2.new(.5,x,.5,y); f.AnchorPoint=Vector2.new(.5,.5); f.BackgroundColor3=C.text; f.Parent=gui; return f
end
local cross={bar(2,7,0,-8),bar(2,7,0,8),bar(7,2,-8,0),bar(7,2,8,0)}
for _,f in cross do local s=Instance.new("UIScale"); s.Parent=f end
local footer=Instance.new("Frame")
footer.Name="CombatFooter"
footer.Size=UDim2.fromOffset(780,138)
footer.AnchorPoint=Vector2.new(.5,1)
footer.Position=UDim2.new(.5,0,1,-22)
footer.BackgroundTransparency=1
footer.Parent=gui
local footerScale=Instance.new("UIScale")
footerScale.Parent=footer

local function footerLabel(name,caption,x,y,w,h,fontSize,parent)
 local item=label(UDim2.fromOffset(w,h),UDim2.fromOffset(x,y),Vector2.zero,caption,fontSize)
 item.Name=name
 item.Parent=parent or footer
 return item
end

local function rounded(item,pixels) UI.corner(item,8) end

local healthTrack=footerLabel("HealthTrack","",0,41,190,31,15)
healthTrack.BackgroundTransparency=0
healthTrack.BackgroundColor3=C.panel
healthTrack.BorderSizePixel=0
rounded(healthTrack,6)
local healthOutline=Instance.new("UIStroke")
healthOutline.Color=C.text
healthOutline.Thickness=1; healthOutline.Transparency=.85
healthOutline.Parent=healthTrack
local healthFill=Instance.new("Frame")
healthFill.Name="HealthFill"
healthFill.Size=UDim2.fromScale(1,1)
healthFill.BackgroundColor3=C.success
healthFill.BorderSizePixel=0
healthFill.BackgroundTransparency=.72
healthFill.Parent=healthTrack
rounded(healthFill,6)
local health=footerLabel("HealthValue","100/100 HP",0,0,190,31,17,healthTrack)
health.BackgroundTransparency=1
health.TextColor3=C.text
health.TextStrokeColor3=C.background
health.TextStrokeTransparency=1
health.ZIndex=2
local staminaTrack=footerLabel("StaminaTrack","",0,79,190,10,12)
staminaTrack.BackgroundColor3=C.panel
rounded(staminaTrack,5)
local staminaFill=Instance.new("Frame")
staminaFill.Name="StaminaFill"
staminaFill.Size=UDim2.fromScale(1,1)
staminaFill.BackgroundColor3=C.text
staminaFill.BorderSizePixel=0
staminaFill.Parent=staminaTrack
rounded(staminaFill,5)
local staminaText=footerLabel("StaminaValue","Sprint · Dash",0,19,190,18,11)
staminaText.BackgroundTransparency=1
staminaText.TextColor3=C.text
staminaText.TextStrokeColor3=C.background
staminaText.TextStrokeTransparency=1
local ammo=footerLabel("Ammo","",574,2,206,37,20)
rounded(ammo,7)
local weaponSlots={}
local switchSlot=function() end
for slot=1,#weapons.Slots do
 local chip=UI.button(footer,tostring(slot),574+((slot-1)%2)*104,44+math.floor((slot-1)/2)*48,102,44,function() switchSlot(slot) end)
 chip.Name="Weapon"..slot; chip.TextSize=13; weaponSlots[slot]=chip
end
local keys={Q="smoke",E="flash",F="recon"}
local slots={}
for i,key in {"Q","E","F"} do
 slots[keys[key]]=footerLabel("Ability"..key,"",202+(i-1)*120,50,112,39,13)
 rounded(slots[keys[key]],7)
end
local overlay=Instance.new("Frame"); overlay.Size=UDim2.fromScale(1,1); overlay.BackgroundColor3=C.panel; overlay.BackgroundTransparency=1; overlay.ZIndex=10; overlay.Parent=gui
local fog=overlay:Clone(); fog.BackgroundColor3=C.background; fog.ZIndex=9; fog.Parent=gui
local damageArrow=label(UDim2.fromOffset(40,38),UDim2.fromScale(.5,.5),Vector2.new(.5,.5),"▲",29)
damageArrow.Name="DamageDirection"
damageArrow.BackgroundTransparency=1
damageArrow.TextColor3=C.danger
damageArrow.TextStrokeTransparency=.25
damageArrow.Visible=false
damageArrow.ZIndex=8
local damageVignette=Instance.new("Frame")
damageVignette.Name="DamageFlash"
damageVignette.Size=UDim2.new(1,-12,1,-12)
damageVignette.Position=UDim2.fromOffset(6,6)
damageVignette.BackgroundTransparency=1
damageVignette.Parent=gui
local damageBorder=Instance.new("UIStroke")
damageBorder.Thickness=6
damageBorder.Color=C.danger
damageBorder.Transparency=1
damageBorder.Parent=damageVignette
local damageAt=0
local damagePosition
local clouds={}
local modelFactory=require(game.ReplicatedStorage:WaitForChild("RiftWeaponModels"))
local views={}
local viewIds={}
local function updateView(slot,id)
 if viewIds[slot]~=id then
  if views[slot] then views[slot]:Destroy() end
  views[slot]=modelFactory.create(weapons[id])
  viewIds[slot]=id
 end
 return views[slot]
end

local function sound(name,id,volume,speed)
 local template=Instance.new("Sound")
 template.Name=name
 template.SoundGroup=soundGroup
 template.SoundId=id
 template.Volume=volume
 template.PlaybackSpeed=speed
 template.RollOffMaxDistance=150
 template.Parent=audio
 task.spawn(function() pcall(function() assets:PreloadAsync({template}) end) end)
 return template
end
local shots={}
for id=1,#weapons do
 shots[id]=sound("RiftWeaponFire"..id,weapons[id].shotSound,.27,weapons[id].soundPitch)
end
local shotFallback=sound("RiftFallbackFire","rbxasset://sounds/impact_explosion_03.mp3",.19,2.3)
local reloadSound=sound("RiftReload",weapons.ReloadSound,.33,1)
local reloadFallback=sound("RiftFallbackReload","rbxasset://sounds/action_get_up.mp3",.28,1.5)
local hitSound=sound("RiftHit","rbxasset://sounds/volume_slider.ogg",.2,1.4)
local emptySound=sound("RiftEmpty","rbxasset://sounds/volume_slider.ogg",.17,.72)
local abilitySound=sound("RiftAbilityCue","rbxasset://sounds/volume_slider.ogg",.19,1.65)
local bounceSound=sound("RiftBounce","rbxasset://sounds/action_jump.mp3",.27,1.25)
local eliminationSound=sound("RiftElimination","rbxasset://sounds/volume_slider.ogg",.31,1.96)
local explosionSound=sound("RiftExplosion","rbxasset://sounds/impact_explosion_03.mp3",.41,1.1)
local function playShot(slot,source)
 local template=shots[slot]
 local shot=(template.IsLoaded and template or shotFallback):Clone()
 if not template.IsLoaded and slot==2 then shot.PlaybackSpeed=3 end
 if not source then
  local cam=workspace.CurrentCamera
  local roof=cam and workspace:Raycast(cam.CFrame.Position,Vector3.new(0,30,0))
  if roof then local echo=Instance.new("EchoSoundEffect");echo.Delay=.08;echo.Feedback=.12;echo.WetLevel=-15;echo.Parent=shot end
 end
 shot.Parent=source or audio
 shot:Play()
 D:AddItem(shot,shot.TimeLength>0 and shot.TimeLength/shot.PlaybackSpeed+.1 or 3)
end
local function stopReloadSound()
 reloadSound:Stop()
 reloadFallback:Stop()
end

local sprayIndex=0
local lastFire=0
local recoilYaw=0
local cameraRecoil=Vector2.zero
local inspectUntil=0
local strikeAt=0
local ready={}
local equipped=1
local held=false
local nextShot=0
local kick=0
local function weaponId(slot)
 return weapons.GetId(P,slot)
end
local rounds=weapons[weaponId(1)].magazine
local reloading=false
local hitAt=0
local hitAmount=label(UDim2.fromOffset(108,28),UDim2.new(.5,0,.5,-38),Vector2.new(.5,.5),"",17)
hitAmount.BackgroundTransparency=1
hitAmount.TextStrokeTransparency=.3
hitAmount.Visible=false
local feedbackUntil=0
local aiming=false
local aimBlend=0
local equipBlend=0
local reloadBlend=0
local reloadStarted=0
local emptyReload=false
local flashTween
local function canFight()
 if P:GetAttribute("RiftDuelId") then
  return P:GetAttribute("RiftDuelPhase")=="Fight" and P:GetAttribute("RiftRoundAlive")==true
 end
 local map=P:GetAttribute("RiftMap")
 return map~=nil and map~="Lobby"
end
switchSlot=function(slot)
 if P:GetAttribute("RiftMenuOpen") or not canFight() then return end
 held=false; R:FireServer("equip",slot)
end
local function kitAllows(action)
 return not P:GetAttribute("RiftDuelId") or weapons.Kits[P:GetAttribute("RiftKit") or 1].omitted~=action
end
local function resetLoadout()
 table.clear(ready)
 equipped=1
 rounds=weapons[weaponId(1)].magazine
 held=false
 reloading=false
 nextShot=0
 kick=0
 aiming=false
 equipBlend=1
 stopReloadSound()
end
local function request(action)
 local cam=workspace.CurrentCamera
 if cam then R:FireServer(action,cam.CFrame.LookVector,equipped,aiming and not P:GetAttribute("RiftSprinting"),cam.CFrame.Position) end
end
local function fire(now)
 if now<nextShot or rounds<=0 or reloading then return end
 local id=weaponId(equipped)
 local weapon=weapons[id]
 nextShot=now+weapon.shotInterval
 sprayIndex=now-lastFire>.28 and 1 or sprayIndex+1;lastFire=now
 if not weapon.melee then rounds=math.max(0,rounds-1) end
 request("fire")
 strikeAt=now
 playShot(id)
 kick=weapon.recoil
 local cam=workspace.CurrentCamera
 if cam then
  local pitch,yaw=Ballistics.Pattern(weapon,sprayIndex)
  if not weapon.item then
   local delta=Vector2.new(pitch*(aiming and .65 or 1),yaw);cameraRecoil+=delta
   cam.CFrame*=CFrame.Angles(math.rad(delta.X),math.rad(delta.Y),0)
  end
  recoilYaw=yaw*.015
  local view=views[equipped];local muzzle=view and view:GetAttribute("WorldMuzzle") or (cam.CFrame*CFrame.new(.5,-.3,-2)).Position
  GunFX.Muzzle(muzzle,weapon,cam.CFrame.LookVector)
 end
end
U.InputBegan:Connect(function(input,processed)
 if processed or P:GetAttribute("RiftMenuOpen") or not canFight() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton2 then
  if weapons[weaponId(equipped)].item then request("itemAlt") else aiming=true end
 end
 if input.KeyCode==Enum.KeyCode.Space and equipped==3 and weapons[weaponId(3)].name=="Fists" then request("itemAlt") end
 if input.UserInputType==Enum.UserInputType.MouseButton1 then
  held=weapons[weaponId(equipped)].automatic
  if rounds==0 and not reloading then emptySound:Play() else fire(os.clock()) end
 end
 local numberSlots={[Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,[Enum.KeyCode.Three]=3,[Enum.KeyCode.Four]=4}
 local slot=numberSlots[input.KeyCode]; if slot then switchSlot(slot) end
 if input.KeyCode==Enum.KeyCode.R then request("reload") end
 if input.KeyCode==Enum.KeyCode.V and not reloading then inspectUntil=os.clock()+1.8 end
 if input.KeyCode==Enum.KeyCode.LeftShift then R:FireServer("sprint",true) end
 if input.KeyCode==Enum.KeyCode.C then R:FireServer("dash") end
 if input.KeyCode==Enum.KeyCode.LeftControl then R:FireServer("slide") end
 local action=keys[input.KeyCode.Name]
 if action and kitAllows(action) and (ready[action] or 0)<=os.clock() then request(action) end
end)
U.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 then held=false end
 if input.UserInputType==Enum.UserInputType.MouseButton2 then aiming=false end
 if input.KeyCode==Enum.KeyCode.LeftShift then R:FireServer("sprint",false) end
end)
U.WindowFocusReleased:Connect(function()
 held=false
 aiming=false
 R:FireServer("sprint",false)
end)
P:GetAttributeChangedSignal("RiftMenuOpen"):Connect(function()
 if P:GetAttribute("RiftMenuOpen") then R:FireServer("sprint",false) end
end)
local revealed={}
P.CharacterAdded:Connect(resetLoadout)
local function landing(character)
 local hum=character:WaitForChild("Humanoid",5)
 if hum then hum.StateChanged:Connect(function(old,new)
  if old==Enum.HumanoidStateType.Freefall and new==Enum.HumanoidStateType.Landed then Audio.Play("land") end
 end) end
end
P.CharacterAdded:Connect(landing)
if P.Character then task.spawn(landing,P.Character) end
local trainingText=label(UDim2.fromOffset(660,60),UDim2.new(.5,0,0,56),Vector2.new(.5,0),"",13)
trainingText.Visible=false
R.OnClientEvent:Connect(function(event,a,b,c,d,e,f,g,h,i)
 if event=="training" then
  trainingText.Visible=P:GetAttribute("RiftMap")=="Training Arena"
  trainingText.Text=string.format("%s · Level %d · %ds\n%d shots · %.0f%% accuracy · %d head hits · %d damage · %dms",a,h or 1,f or 0,b or 0,(b or 0)>0 and (c or 0)/b*100 or 0,d or 0,e or 0,g or 0)
 elseif event=="impact" then GunFX.Impact(a,b,c,d,e)
 elseif event=="combatReset" then
  resetLoadout()
 elseif event=="weaponState" then
  if equipped~=a then
   Audio.Play("equip")
   nextShot=os.clock()+.2
   held=false
   kick=0
   equipBlend=1
  end
  if c and not reloading then
   reloadStarted=os.clock();emptyReload=rounds==0
   local reload=reloadSound.IsLoaded and reloadSound or reloadFallback
   reload:Play()
  elseif not c and reloading then
   if b>rounds then Audio.Play("reloadEnd") end
   stopReloadSound()
  end
  equipped=a
  rounds=b
  reloading=c
 elseif event=="shot" then
  playShot(a,b)
 elseif event=="hit" then
  hitAt=os.clock()+(a and .21 or .13)
  hitSound.PlaybackSpeed=a and 1.7 or 1.4
  if c then eliminationSound:Play() else hitSound:Play() end
  hitAmount.Text=c and "Eliminated" or tostring(b or "")
  hitAmount.TextColor3=a and C.success or C.panel
  feedbackUntil=os.clock()+.65
 elseif event=="explosion" then
  local cam=workspace.CurrentCamera
  if cam then
   explosionSound.Volume=.42*math.clamp(1-(cam.CFrame.Position-a).Magnitude/110,0,1)
   explosionSound:Play()
  end
 elseif event=="damageFrom" then
  Audio.Play("hurt")
  damageAt=os.clock()+.65
  damagePosition=a
 elseif event=="abilityCast" then
  if a=="dash" or a=="slide" then Audio.Play(a)
  else local cue=a=="bounce" and bounceSound or abilitySound; cue:Play() end
 elseif event=="cooldown" then ready[a]=os.clock()+b
 elseif event=="smoke" and a then table.insert(clouds,a)
 elseif event=="flash" then
  local cam=workspace.CurrentCamera
  local delta=a-cam.CFrame.Position
  if delta.Magnitude<.1 or cam.CFrame.LookVector:Dot(delta.Unit)>.35 then
   if flashTween then flashTween:Cancel() end
   overlay.BackgroundTransparency=.02
   flashTween=T:Create(overlay,TweenInfo.new(1.7,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1}); flashTween:Play()
  end
 elseif event=="reveal" and a then
  if revealed[a] then revealed[a]:Destroy() end
  local h=Instance.new("Highlight")
  h.Adornee=a
  h.FillColor=C.danger
  h.OutlineColor=C.panel
  h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
  h.Parent=a
  revealed[a]=h
  task.delay(1.25,function()
   if revealed[a]==h then revealed[a]=nil end
   h:Destroy()
  end)
 end
end)
Run:BindToRenderStep("RiftHUD",Enum.RenderPriority.Camera.Value+1,function(dt)
 local now=os.clock()
 local cam=workspace.CurrentCamera
 if cam then local recovery=cameraRecoil*(1-math.exp(-dt*5));cameraRecoil-=recovery;cam.CFrame*=CFrame.Angles(-math.rad(recovery.X),-math.rad(recovery.Y),0) end
 local hum=P.Character and P.Character:FindFirstChildOfClass("Humanoid")
 trainingText.Visible=trainingText.Text~="" and P:GetAttribute("RiftMap")=="Training Arena"
 local inLobby=P:GetAttribute("RiftMap")=="Lobby"
 gui.Enabled=not inLobby and P:GetAttribute("RiftDuelPhase")~="Voting" and not P:GetAttribute("RiftMenuOpen")
 local fighting=canFight()
 local eliminated=P:GetAttribute("RiftDuelPhase")=="Fight" and not P:GetAttribute("RiftRoundAlive")
 local alive=hum and hum.Health>0 and not inLobby and not eliminated
 local menuOpen=P:GetAttribute("RiftMenuOpen")
 if menuOpen or not fighting then held=false; aiming=false end
 local weapon=weapons[weaponId(equipped)]
 local sliding=P:GetAttribute("RiftSliding")==true
 local sprinting=P:GetAttribute("RiftSprinting")==true
 local ads=aiming and alive and not reloading and not sprinting and not sliding
 local smooth=1-math.exp(-dt*15)
 aimBlend+=( (ads and 1 or 0)-aimBlend)*smooth
 reloadBlend+=((reloading and 1 or 0)-reloadBlend)*smooth
 equipBlend=math.max(0,equipBlend-dt*4.8)
 local zoom=1-(1-weapon.zoom)*aimBlend
 if P:GetAttribute("RiftZoom")~=zoom then P:SetAttribute("RiftZoom",zoom) end
 if hum then hum.CameraOffset=hum.CameraOffset:Lerp(sliding and Vector3.new(0,-.85,0) or Vector3.zero,smooth) end
 hitAmount.Visible=now<feedbackUntil
 if cam then
  local phone=U.TouchEnabled or cam.ViewportSize.X<700
  footerScale.Scale=math.min(1,(cam.ViewportSize.X-32)/(phone and 320 or 780))
  footer.Position=UDim2.new(.5,0,1, U.TouchEnabled and -148 or -22)
  if phone then
   footer.Size=UDim2.fromOffset(320,152)
   healthTrack.Size=UDim2.fromOffset(130,31); health.Size=UDim2.fromOffset(130,31); staminaTrack.Size=UDim2.fromOffset(130,10); staminaText.Size=UDim2.fromOffset(148,24)
   ammo.Size=UDim2.fromOffset(150,37)
   healthTrack.Position=UDim2.fromOffset(0,4); staminaTrack.Position=UDim2.fromOffset(0,44)
   staminaText.Position=UDim2.fromOffset(0,58)
   ammo.Position=UDim2.fromOffset(170,0)
   for i,chip in weaponSlots do chip.Position=UDim2.fromOffset((i-1)*80,72); chip.Size=UDim2.fromOffset(76,44); chip.TextTruncate=Enum.TextTruncate.AtEnd; chip.TextSize=13 end
   for i,key in {"Q","E","F"} do slots[keys[key]].Position=UDim2.fromOffset((i-1)*108,124); slots[keys[key]].Size=UDim2.fromOffset(104,24) end
  else
   footer.Size=UDim2.fromOffset(780,138)
   healthTrack.Size=UDim2.fromOffset(190,31); health.Size=UDim2.fromOffset(190,31); staminaTrack.Size=UDim2.fromOffset(190,10); staminaText.Size=UDim2.fromOffset(190,18)
   ammo.Size=UDim2.fromOffset(206,37)
   healthTrack.Position=UDim2.fromOffset(0,41); staminaTrack.Position=UDim2.fromOffset(0,79); staminaText.Position=UDim2.fromOffset(0,19)
   ammo.Position=UDim2.fromOffset(574,2)
   for i,chip in weaponSlots do chip.Position=UDim2.fromOffset(574+((i-1)%2)*104,44+math.floor((i-1)/2)*48); chip.Size=UDim2.fromOffset(102,44); chip.TextSize=13 end
   for i,key in {"Q","E","F"} do slots[keys[key]].Position=UDim2.fromOffset(202+(i-1)*120,50); slots[keys[key]].Size=UDim2.fromOffset(112,39) end
  end
 end
 local hp=alive and math.clamp(hum.Health,0,100) or 0
 health.Text=string.format("%d/100 HP",math.ceil(hp))
 healthFill.Size=UDim2.fromScale(hp/100,1)
 healthFill.Visible=hp>0
 healthFill.BackgroundColor3=hp<=25 and C.danger or C.success
 local stamina=P:GetAttribute("RiftStamina") or 100
 staminaFill.Size=UDim2.fromScale(stamina/100,1)
 staminaFill.Visible=stamina>0
 staminaText.Text=string.format("Stamina %d · C dash",stamina)
 local damageAlpha=math.clamp((damageAt-now)/.65,0,1)
 damageBorder.Transparency=1-damageAlpha*.78
 damageArrow.Visible=damageAlpha>0 and damagePosition~=nil and cam~=nil
 if damageArrow.Visible then
  local localSource=cam.CFrame:PointToObjectSpace(damagePosition)
  local angle=math.atan2(localSource.X,-localSource.Z)
  damageArrow.Rotation=math.deg(angle)
  damageArrow.Position=UDim2.new(.5,math.sin(angle)*82,.5,-math.cos(angle)*82)
  damageArrow.TextTransparency=1-damageAlpha
 end
 ammo.Text=weapon.melee and "Melee" or (reloading and "Reloading" or string.format("%02d / %02d",rounds,weapons[weaponId(equipped)].magazine))
 for slot,chip in weaponSlots do
  local name=weapons[weaponId(slot)].short
  chip.Text=slot.."  "..name
  chip.BackgroundColor3=C.panel
  chip.TextColor3=slot==equipped and C.text or C.text
  chip.BackgroundTransparency=slot==equipped and .06 or .23
 end
 for key,action in keys do
  local seconds=math.ceil((ready[action] or 0)-now)
  local allowed=kitAllows(action)
  slots[action].Text=key.."  "..action:sub(1,1):upper()..action:sub(2)..(seconds>0 and ("  "..seconds.."s") or "")
  slots[action].TextColor3=allowed and C.text or C.text
  slots[action].TextTransparency=allowed and 0 or .64
  slots[action].BackgroundTransparency=allowed and .23 or .62
 end
 for _,f in cross do
  f.Visible=alive
  f.UIScale.Scale=(P:GetAttribute("RiftCrosshair") or 1)*(1+math.min(sprayIndex/20,.5)*(now-lastFire<.25 and 1 or 0)+(sprinting and .4 or 0)-.42*aimBlend)
  f.BackgroundColor3=now<hitAt and C.danger or C.panel
 end
 if not cam then return end
 local inside=false
 for i=#clouds,1,-1 do
  local cloud=clouds[i]
  if not cloud.Parent then table.remove(clouds,i)
  elseif (cloud.Position-cam.CFrame.Position).Magnitude<11 then inside=true end
 end
 fog.BackgroundTransparency=inside and .04 or 1
 local view=updateView(equipped,weaponId(equipped))
 if weapon.name=="Fists" then modelFactory.recolorFists(view,P) end
 local showWeapon=alive and not menuOpen and P:GetAttribute("RiftDuelPhase")~="Voting"
 for _,model in pairs(views) do
  local parent=showWeapon and model==view and cam or nil
  if model.Parent~=parent then model.Parent=parent end
 end
 if not showWeapon then return end
 if held and fighting then fire(now) end
 kick=math.max(0,kick-dt*1.8)
 local root=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
 local velocity=root and root.AssemblyLinearVelocity or Vector3.zero
 local planar=Vector3.new(velocity.X,0,velocity.Z)
 local horizontal=planar.Magnitude
 if fighting and root and hum.FloorMaterial==Enum.Material.Air and not sliding and horizontal<26 then
  local input=hum.MoveDirection
  if input.Magnitude>.1 then
   local steered=planar:Lerp(input*math.max(horizontal,17),math.min(dt*2.1,.12))
   root.AssemblyLinearVelocity=Vector3.new(steered.X,velocity.Y,steered.Z)
  end
 end
 local stride=math.min(horizontal/24,1)*(1-aimBlend)
 local bobX=math.sin(now*(sprinting and 15 or 10))*.035*stride*(1-aimBlend)
 local bobY=math.cos(now*(sprinting and 30 or 20))*.032*stride*(1-aimBlend)
 local distance=weapons.Slots[equipped].category==1 and -1.45 or -1.15
 local x=.52*(1-aimBlend)+bobX
 local sight=view:GetAttribute("SightHeight") or .43
 local y=-.52*(1-aimBlend)-sight*aimBlend-.49*reloadBlend-.55*equipBlend*(1-aimBlend)+bobY
 local swing=weapon.melee and math.sin(math.clamp((now-strikeAt)/weapon.shotInterval,0,1)*math.pi) or 0
 local inspect=now<inspectUntil and math.sin(math.clamp((inspectUntil-now)/1.8,0,1)*math.pi) or 0
 local base=cam.CFrame*CFrame.new(x-swing*.35,y+swing*.12,distance+kick+.1*aimBlend-swing*.4)*CFrame.Angles(0,swing*.45,-swing*.6)
  *CFrame.Angles(-.35*reloadBlend-.26*equipBlend*(1-aimBlend),inspect*.5+recoilYaw,.22*reloadBlend-.12*equipBlend*(1-aimBlend)+inspect*.45)
 view:SetAttribute("WorldMuzzle",(base*CFrame.new(view:GetAttribute("MuzzleLocal") or Vector3.new(0,.08,-.95))).Position)
 recoilYaw*=math.exp(-dt*18)
 for _,p in view:GetChildren() do
  local localCF=p:GetAttribute("LocalCFrame") or CFrame.new(p:GetAttribute("Offset"))
  local progress=math.clamp((now-reloadStarted)/weapon.reloadTime,0,1)
  local magazine=(p.Name:find("Magazine",1,true) or p.Name:find("Belt box",1,true)) and not p.Name:find("Magazine shoe",1,true)
  if reloading and magazine then localCF*=CFrame.new(0,-math.sin(progress*math.pi)*(emptyReload and .75 or .5),.12*math.sin(progress*math.pi)) end
  if p.Name:find("Slide",1,true) then localCF*=CFrame.new(0,0,math.max(0,1-(now-strikeAt)/.09)*.08) end
  p.CFrame=base*localCF
 end
end)