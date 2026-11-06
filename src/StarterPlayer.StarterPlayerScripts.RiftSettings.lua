local player=game.Players.LocalPlayer
local input=game:GetService("UserInputService")
local run=game:GetService("RunService")
local storage=game.ReplicatedStorage
local travel=storage:WaitForChild("RiftTravel")
local action=storage:WaitForChild("RiftAction")
local queue=storage:WaitForChild("RiftQueue")
local weapons=require(storage:WaitForChild("RiftWeapons"))
local Models=require(storage:WaitForChild("RiftWeaponModels"))
local UI=require(storage:WaitForChild("RiftUI"))
local Controller=require(storage:WaitForChild("RiftUIController"))
local C=UI.C
local Audio=require(storage:WaitForChild("RiftAudio"))
local gui=Instance.new("ScreenGui"); gui.Name="RiftSettings"; gui.ResetOnSpawn=false; gui.DisplayOrder=30; gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets; gui.Parent=player:WaitForChild("PlayerGui")
local shade=Instance.new("CanvasGroup"); shade.Name="MenuScreen"; shade.Size=UDim2.fromScale(1,1); shade.BackgroundColor3=C.background; shade.BackgroundTransparency=.3; shade.Parent=gui
local panel=UI.frame(shade,"Menu",0,0,0,0); panel.Size=UDim2.fromScale(.92,.9); panel.Position=UDim2.fromScale(.5,.5); panel.AnchorPoint=Vector2.new(.5,.5); UI.surface(panel)
local bounds=Instance.new("UISizeConstraint"); bounds.MaxSize=Vector2.new(880,720); bounds.Parent=panel
local title=UI.text(panel,"Rift",16,12,200,40,32,C.text,true)
local close=UI.button(panel,"Close",0,12,80,44,function() Controller:Set("Menu",false) end)
close.Position=UDim2.new(1,-96,0,12); close.Modal=true
local tabs=UI.frame(panel,"Navigation",16,64,0,48); tabs.Size=UDim2.new(1,-32,0,48); tabs.BackgroundTransparency=1
local tabLayout=Instance.new("UIListLayout"); tabLayout.FillDirection=Enum.FillDirection.Horizontal; tabLayout.SortOrder=Enum.SortOrder.LayoutOrder; tabLayout.Padding=UDim.new(0,8); tabLayout.Parent=tabs
local pages,nav={},{}
local opened=false
local homeOpen=true
local pageName="Play"
local mode=player:GetAttribute("RiftSelectedMode") or 1
local selected=player:GetAttribute("RiftPrimary") or 1
local practiceVisited=false
local loadoutEdited=false
local refresh=function() end
local home
Controller:Register("Menu",shade,20,function(visible)
 opened=visible
 player:SetAttribute("RiftMenuOpen",visible or (homeOpen and Controller.active==nil))
end)
local function editable()
 return player:GetAttribute("RiftMap")=="Lobby" and not player:GetAttribute("RiftQueued") and not player:GetAttribute("RiftDuelId")
end
local function openArsenal()
 -- The full-screen Arsenal (StarterPlayerScripts.RiftArsenal) replaces the old in-menu page when it is loaded.
 if Controller.screens.Arsenal then Controller:Set("Menu",false); if Controller.screens.Shop then Controller:Set("Shop",false) end; Controller:Set("Arsenal",true); return true end
end
-- Shop (StarterPlayerScripts.RiftShopUI): opens once the profile has loaded; offline/readonly open view-only (RiftShopUI shows a banner).
local function shopLoading() local st=player:GetAttribute("RiftProfileState"); return st==nil or st=="loading" or not Controller.screens.Shop end
local function openShop()
 if shopLoading() then return end
 Controller:Set("Menu",false)
 for _,name in {"Arsenal","Loadout"} do if Controller.screens[name] then Controller:Set(name,false) end end
 Controller:Set("Shop",true)
end
local function showPage(name)
 if name=="Arsenal" and openArsenal() then return end
 pageName=name
 for key,page in pages do page.Visible=key==name; UI.select(nav[key],key==name) end
end
local function open(name) showPage(name); Controller:Set("Menu",true); refresh() end
local function leaveFor(destination)
 if player:GetAttribute("RiftDuelId") or player:GetAttribute("RiftQueued") then return end
 homeOpen=false; travel:FireServer(destination); Controller:Set("Menu",false)
end
for i,name in {"Play","Arsenal","Abilities","Settings"} do
 local b=UI.button(tabs,name,0,0,80,44,function() showPage(name) end)
 b.Size=UDim2.new(.25,-6,0,44); b.TextSize=13; b.LayoutOrder=i; nav[name]=b
 local page=Instance.new("ScrollingFrame"); page.Name=name; page.Position=UDim2.fromOffset(16,128); page.Size=UDim2.new(1,-32,1,-144)
 page.ClipsDescendants=true; page.BackgroundTransparency=1; page.BorderSizePixel=0; page.ScrollBarThickness=3; page.ScrollBarImageColor3=C.text
 page.AutomaticCanvasSize=Enum.AutomaticSize.Y; page.CanvasSize=UDim2.new(); page.Visible=false; page.Parent=panel
 local pad=UI.padding(page,8)
 local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,16); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=page
 pages[name]=page
end
local order=0
local function row(parent,height)
 order+=1
 local r=UI.frame(parent,"Row",0,0,0,height); r.Size=UDim2.new(1,-8,0,height); r.BackgroundTransparency=1; r.LayoutOrder=order; return r
end
local function text(parent,caption,size,bold,height)
 local r=row(parent,height or (size==32 and 44 or 24))
 if size==32 then r:SetAttribute("CompactHidden",true); parent:SetAttribute("IntroPending",true) end
 local t=UI.text(r,caption,0,0,0,height or 24,size,C.text,bold); t.Size=UDim2.fromScale(1,1); t.TextWrapped=true; return t
end
local function button(parent,caption,callback,primary)
 local r=row(parent,48)
 local b=UI.button(r,caption,0,0,0,48,callback,primary); b.Size=UDim2.fromScale(1,1); return b
end
local function hint(parent,caption) local t=text(parent,caption,13,false,40); t.TextTransparency=.22; if parent:GetAttribute("IntroPending") then t.Parent:SetAttribute("CompactHidden",true); parent:SetAttribute("IntroPending",false) end; return t end
local function modeRow(parent)
 local r=row(parent,48); local buttons={}
 for size=1,3 do
  local b=UI.button(r,size.."v"..size,0,0,44,48,function()
   if editable() then mode=size; player:SetAttribute("RiftSelectedMode",size); queue:FireServer("mode",size); refresh() end
  end)
  b.Position=UDim2.new((size-1)/3,0,0,0); b.Size=UDim2.new(1/3,-8,1,0); buttons[size]=b
 end
 return buttons
end
local play=pages.Play
text(play,"Find your next match",32,true,44)
hint(play,"First to five wins. Short rounds. Every weapon is available.")
local modeButtons=modeRow(play)
local queueStatus=text(play,"",16)
local join=button(play,"Find match",function()
 if player:GetAttribute("RiftMap")=="Lobby" and not player:GetAttribute("RiftDuelId") then queue:FireServer("queue",mode) end
end,true)
button(play,"Explore lobby",function()
 if player:GetAttribute("RiftMap")=="Lobby" then homeOpen=false; Controller:Set("Menu",false)
 else leaveFor("Lobby") end
end)
text(play,"Practice",20,true)
button(play,"Enter training",function() leaveFor("Training Arena") end)
local loadout=hint(play,"")
button(play,"Change loadout",function() showPage("Arsenal") end)
for _,destination in {"Pine Ridge","Red Mesa","Metro District","Dockyard"} do
 button(play,"Explore "..destination,function() leaveFor(destination) end)
end
text(play,"Your session",20,true)
local session=hint(play,"")
local objectives=hint(play,"")
local leaders=hint(play,"")
local arsenal=pages.Arsenal
text(arsenal,"Your loadout",32,true,44)
hint(arsenal,"Choose a weapon, then equip it. Changes are available in the lobby.")
local activeCategory=1
local categoryButtons={}
local updateFilter=function() end
local categoryRow=row(arsenal,48)
for category,definition in ipairs(weapons.Slots) do
 local b=UI.button(categoryRow,definition.label,0,0,44,48,function() activeCategory=category; updateFilter() end)
 b.Position=UDim2.new((category-1)/4,0,0,0);b.Size=UDim2.new(.25,-6,1,0);b.TextSize=13;categoryButtons[category]=b
end
local searchRow=row(arsenal,48)
local search=Instance.new("TextBox"); search.Name="WeaponSearch"; search.Size=UDim2.fromScale(1,1); search.BackgroundColor3=C.panel; search.TextColor3=C.text; search.PlaceholderColor3=C.text
search.PlaceholderText="Search weapons"; search.Text=""; search.ClearTextOnFocus=false; search.Font=UI.Font.regular; search.TextSize=16; search.Parent=searchRow; UI.surface(search); UI.padding(search,12)
local list=row(arsenal,184); list.Name="WeaponList"
local scroll=Instance.new("ScrollingFrame"); scroll.ClipsDescendants=true; scroll.Size=UDim2.fromScale(1,1); scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollBarThickness=3; scroll.ScrollBarImageColor3=C.text; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.CanvasSize=UDim2.new(); scroll.Parent=list
local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,8); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=scroll
local weaponName=text(arsenal,"",20,true)
local classLabel=text(arsenal,"",13)
local previewRow=row(arsenal,144)
local preview=Instance.new("ViewportFrame"); preview.Name="WeaponPreview"; preview.Size=UDim2.fromScale(1,1); preview.BackgroundTransparency=1; preview.Ambient=Color3.fromRGB(190,196,210); preview.LightColor=Color3.new(1,1,1); preview.LightDirection=Vector3.new(-1,-1,-1); preview.Parent=previewRow
local aspect=Instance.new("UIAspectRatioConstraint"); aspect.AspectRatio=3; aspect.DominantAxis=Enum.DominantAxis.Width; aspect.Parent=preview
local camera=Instance.new("Camera"); camera.FieldOfView=29; camera.Parent=preview; preview.CurrentCamera=camera
local description=hint(arsenal,"")
local stats=hint(arsenal,"")
local previewId,previewModel
local weaponRows={}
local equipButtons={}
local function refreshWeapon()
 local w=weapons[selected]
 if previewId~=selected then
  if previewModel then previewModel:Destroy() end
  previewModel=Models.create(w); previewModel.Parent=preview; previewId=selected
  local centre,size=previewModel:GetBoundingBox()
  camera.CFrame=CFrame.lookAt(centre.Position+Vector3.new(2.7,.5,-.9)*math.max(size.Z/3,.55),centre.Position)
 end
 Models.recolorFists(previewModel,player)
 local slot=1 for category,ids in ipairs(weapons.Loadouts) do if table.find(ids,selected) then slot=category; break end end
 local category=slot
 weaponName.Text=w.name
 classLabel.Text=weapons.Slots[slot].label.." · "..(w.class or w.short)
 description.Text=w.description or "Aim carefully and use cover between shots."
 stats.Text=w.directDamage and string.format("%d direct · %d splash · %d rounds · %.1fs reload",w.directDamage,w.bodyDamage,w.magazine,w.reloadTime) or string.format("%s damage · %d rounds · %.1fs reload",tostring(w.bodyDamage),w.magazine,w.reloadTime)
 for destination,b in equipButtons do
  local definition=weapons.Slots[destination]
  local equipped=weapons.GetId(player,destination)==selected
  b.Parent.Visible=definition.category==category
  b.Text=equipped and ("Slot "..destination.." · Equipped") or (editable() and ("Equip to slot "..destination.." · "..definition.label) or "Return to lobby to equip")
  b.Active=editable() and not equipped; b.TextTransparency=b.Active and 0 or .35
 end
 for id,b in weaponRows do UI.select(b,id==selected) end
end
for slot,definition in ipairs(weapons.Slots) do
 equipButtons[slot]=button(arsenal,"Equip to slot "..slot,function() if editable() then action:FireServer("loadout",selected,slot); Audio.Play("equip") end end,true)
end
for id,w in ipairs(weapons) do
 local b=UI.button(scroll,w.name,0,0,0,48,function() selected=id; refreshWeapon() end)
 b.Size=UDim2.new(1,-8,0,48); b.LayoutOrder=id; weaponRows[id]=b
end
local empty=UI.text(scroll,"No weapons found. Try another name.",0,0,0,48,13); empty.Size=UDim2.new(1,-8,0,48); empty.Visible=false
updateFilter=function()
 local count=0
 local first
 for id,b in weaponRows do
  local w=weapons[id]
  b.Visible=table.find(weapons.Loadouts[activeCategory],id)~=nil and (w.name.." "..(w.class or w.short)):lower():find(search.Text:lower(),1,true)~=nil
  if b.Visible then count+=1; first=first or id end
 end
 for category,b in categoryButtons do UI.select(b,category==activeCategory) end
 empty.Visible=count==0; scroll.CanvasPosition=Vector2.zero
 if first and not weaponRows[selected].Visible then selected=first; refreshWeapon() end
end
search:GetPropertyChangedSignal("Text"):Connect(updateFilter)
updateFilter()

local abilities=pages.Abilities
text(abilities,"Choose your tools",32,true,44)
hint(abilities,"Pick a kit in the lobby. Movement is available with every kit.")
local kits={}
for id,kit in ipairs(weapons.Kits) do
 kits[id]=button(abilities,kit.name.." · "..({"Smoke + Flash","Smoke + Recon","Flash + Recon"})[id],function() if editable() then action:FireServer("kit",id) end end)
end
for _,info in {{"Smoke","Block a sightline for 9 seconds."},{"Flash","Look away to counter an incoming flash."},{"Recon","Reveal nearby enemies with three pulses."},{"Movement","Sprint, slide and dash. Keep some stamina ready."}} do
 text(abilities,info[1],20,true); hint(abilities,info[2])
end
local settings=pages.Settings
text(settings,"Make it feel right",32,true,44)
hint(settings,"Changes apply now and last for this session.")
local function setting(label,attribute,default,min,max,step,format)
 if player:GetAttribute(attribute)==nil then player:SetAttribute(attribute,default) end
 text(settings,label,16,true)
 local r=row(settings,48)
 local value=UI.text(r,"",56,0,0,48,20,C.text,true); value.Size=UDim2.new(1,-112,1,0); value.TextXAlignment=Enum.TextXAlignment.Center
 local function update(delta)
  local n=math.clamp(math.round(((player:GetAttribute(attribute) or default)+delta)/step)*step,min,max)
  player:SetAttribute(attribute,n); value.Text=string.format(format,n)
 end
 UI.button(r,"−",0,0,48,48,function() update(-step) end)
 local plus=UI.button(r,"+",0,0,48,48,function() update(step) end); plus.Position=UDim2.new(1,-48,0,0)
 update(0)
end
setting("Mouse sensitivity","RiftSensitivity",1,.1,3,.1,"%.1fx")
setting("Field of view","RiftFOV",80,60,110,5,"%.0f°")
setting("Crosshair size","RiftCrosshair",1,.5,2,.25,"%.2fx")
setting("Effects volume","RiftVolume",1,0,1,.1,"%.1fx")
setting("Music volume","RiftMusicVolume",.5,0,1,.1,"%.1fx")
text(settings,"Controls",20,true)
hint(settings,"Aim / item ability: right mouse · Fists double jump: Space · Reload: R · Switch: 1 / 2 / 3 / 4 · Scoreboard: Tab · Menu: M")
hint(settings,"A live match keeps running while this menu is open.")
-- The lobby shows navigation; matchmaking lives in the Play page.
home=UI.frame(gui,"LobbyInterface",0,0,0,0); home.Size=UDim2.fromScale(1,1); home.BackgroundTransparency=1
-- Bottom nav bar: large icon buttons with labels and red notification badges.
-- Any client script can set a badge with player:SetAttribute("RiftBadge<Name>",count), e.g. RiftBadgeShop.
local NAV={
 {"⚔️","Play",function() open("Play") end},
 {"🎯","Arsenal",function() if not openArsenal() then open("Arsenal") end end},
 {"⚡","Abilities",function() open("Abilities") end},
 {"🏋️","Training",function() leaveFor("Training Arena") end},
 {"🛒","Shop",openShop},
 {"⚙️","Settings",function() open("Settings") end},
}
-- Full-width strip that fades up from the bottom of the screen; icons sit on it and overlap its top edge.
local strip=UI.frame(home,"NavFade",0,0,0,0,C.background); strip.AnchorPoint=Vector2.new(0,1); strip.Position=UDim2.fromScale(0,1); strip.Size=UDim2.new(1,0,0,120)
local fade=Instance.new("UIGradient"); fade.Rotation=90; fade.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.45,.45),NumberSequenceKeypoint.new(1,.2)}); fade.Parent=strip
local dock=UI.frame(home,"Navigation",0,0,0,0); dock.AnchorPoint=Vector2.new(.5,1); dock.Position=UDim2.new(.5,0,1,-6); dock.BackgroundTransparency=1
local dockList=Instance.new("UIListLayout"); dockList.FillDirection=Enum.FillDirection.Horizontal; dockList.Padding=UDim.new(0,18); dockList.HorizontalAlignment=Enum.HorizontalAlignment.Center; dockList.VerticalAlignment=Enum.VerticalAlignment.Bottom; dockList.SortOrder=Enum.SortOrder.LayoutOrder; dockList.Parent=dock
local navBadges={}
for i,item in NAV do
 local b=UI.button(dock,item[2],0,0,140,120,function() if item[3] then item[3]() end end)
 b.Name=item[2]; b.LayoutOrder=i; b.Text=""; b.Size=UDim2.fromOffset(140,120); b.ClipsDescendants=false; b.BackgroundTransparency=1
 for _,decor in {b:FindFirstChildOfClass("UIStroke"),b:FindFirstChild("RiftShade")} do decor:Destroy() end
 -- Big icon on a soft dark disc, label underneath with a thick outline (no boxed card).
 local disc=UI.frame(b,"Disc",0,0,84,84,C.background); disc.AnchorPoint=Vector2.new(.5,0); disc.Position=UDim2.new(.5,0,0,0); disc.BackgroundTransparency=.55; UI.corner(disc,42)
 local icon=UI.text(b,item[1],0,0,0,0,32); icon.Name="Icon"; icon.AnchorPoint=Vector2.new(.5,.5); icon.Position=UDim2.new(.5,0,0,40); icon.Size=UDim2.fromOffset(100,90); icon.TextXAlignment=Enum.TextXAlignment.Center; icon.TextSize=62; icon.ZIndex=2
 local pop=Instance.new("UIScale"); pop.Parent=icon
 local caption=UI.text(b,item[2],0,0,0,30,28,C.text,true); caption.Name="Caption"; caption.Size=UDim2.new(1,20,0,30); caption.Position=UDim2.new(0,-10,1,-32); caption.TextXAlignment=Enum.TextXAlignment.Center; caption.TextSize=26; caption.ZIndex=3
 local badgeHolder=UI.frame(b,"BadgeAnchor",0,0,84,84); badgeHolder.AnchorPoint=Vector2.new(.5,0); badgeHolder.Position=UDim2.new(.5,0,0,0); badgeHolder.BackgroundTransparency=1; badgeHolder.ZIndex=4
 navBadges[item[2]]=UI.badge(badgeHolder)
 b.MouseEnter:Connect(function() if b.Active then pop.Scale=1.12 end end)
 b.MouseLeave:Connect(function() pop.Scale=1 end)
 if not item[3] then
  b.Active=false; icon.TextTransparency=.45; caption.TextTransparency=.45; disc.BackgroundTransparency=.75
  local soon=UI.text(b,"SOON",0,0,52,20,13,C.background,true); soon.Name="Soon"; soon.AnchorPoint=Vector2.new(.5,.5); soon.Position=UDim2.new(.5,0,0,4); soon.TextXAlignment=Enum.TextXAlignment.Center; soon.TextSize=13; soon.BackgroundColor3=C.accent; soon.BackgroundTransparency=0; UI.corner(soon,10); soon.ZIndex=6
 end
end
local opener=UI.button(gui,"Menu",16,16,88,48,function() open("Settings") end)
local notice=UI.text(home,"M to explore the lobby",0,0,0,24,13,C.text,true); notice.Size=UDim2.new(1,-32,0,24); notice.Position=UDim2.new(.5,0,1,-124); notice.AnchorPoint=Vector2.new(.5,1); notice.TextXAlignment=Enum.TextXAlignment.Center; notice.TextStrokeColor3=C.background; notice.TextStrokeTransparency=.4
refresh=function()
 local queued=player:GetAttribute("RiftQueued")==true
 local phase=player:GetAttribute("RiftDuelPhase")
 local size=queued and (player:GetAttribute("RiftQueueSize") or mode) or mode
 local count=workspace:GetAttribute("RiftQueueCount"..size) or 0
 local caption=queued and "Leave queue" or (phase and "Match in progress" or "Find match")
 join.Text=caption
 join.Active=player:GetAttribute("RiftMap")=="Lobby" and not phase
 queueStatus.Text=string.format("%d of %d players ready",count,size*2)
 player:SetAttribute("RiftBadgePlay",(workspace:GetAttribute("RiftQueueCount"..mode) or 0)) -- players waiting in your mode's queue
 for i,b in modeButtons do UI.select(b,i==size); b.Active=editable() end
 for i,b in kits do UI.select(b,i==(player:GetAttribute("RiftKit") or 1)); b.Active=editable() end
 local names={} for slot in ipairs(weapons.Slots) do table.insert(names,slot..": "..weapons[weapons.GetId(player,slot)].short) end; loadout.Text=table.concat(names," · ")
 session.Text=string.format("%d match wins this session",player:GetAttribute("RiftMatchWins") or 0)
 objectives.Text=(practiceVisited and "✓" or "○").." Train  ·  "..(loadoutEdited and "✓" or "○").." Change loadout  ·  "..((player:GetAttribute("RiftMatchWins") or 0)>0 and "✓" or "○").." Win a match"
 local all=game.Players:GetPlayers()
 table.sort(all,function(a,b) return (a:GetAttribute("RiftMatchWins") or 0)>(b:GetAttribute("RiftMatchWins") or 0) end)
 local names={}
 for i=1,math.min(3,#all) do table.insert(names,all[i].DisplayName.." ("..(all[i]:GetAttribute("RiftMatchWins") or 0)..")") end
 leaders.Text="Session leaders: "..table.concat(names,", ")
 refreshWeapon()
end
for _,attribute in {"RiftPrimary","RiftSecondary","RiftMelee","RiftUtility","RiftKit","RiftQueued","RiftQueueSize","RiftDuelPhase","RiftSelectedMode","RiftMatchWins"} do
 player:GetAttributeChangedSignal(attribute):Connect(function() if attribute=="RiftPrimary" or attribute=="RiftSecondary" or attribute=="RiftMelee" or attribute=="RiftUtility" then loadoutEdited=true end; mode=player:GetAttribute("RiftSelectedMode") or mode; refresh() end)
end
for size=1,3 do workspace:GetAttributeChangedSignal("RiftQueueCount"..size):Connect(refresh) end
player:GetAttributeChangedSignal("RiftMap"):Connect(function()
 if player:GetAttribute("RiftMap")=="Training Arena" then practiceVisited=true end
 homeOpen=player:GetAttribute("RiftMap")=="Lobby" and not player:GetAttribute("RiftDuelPhase")
 Controller:Set("Menu",false); refresh()
end)
player:GetAttributeChangedSignal("RiftDuelPhase"):Connect(function()
 if player:GetAttribute("RiftDuelPhase")=="Voting" then homeOpen=false; Controller:Set("Menu",false) end
end)
input.InputBegan:Connect(function(key,processed)
 if not processed and key.KeyCode==Enum.KeyCode.M then
  if opened then Controller:Set("Menu",false)
  elseif player:GetAttribute("RiftMap")=="Lobby" and not player:GetAttribute("RiftDuelPhase") then homeOpen=not homeOpen
  elseif Controller.screens.Loadout and Controller.active~="Vote" then Controller:Set("Loadout",Controller.active~="Loadout") -- in-game loadout picker
  else open("Settings") end
 end
end)
local lastMenuActive
local nextRefresh=0
run:BindToRenderStep("RiftSettings",Enum.RenderPriority.Camera.Value+2,function()
 if os.clock()>nextRefresh and (opened or home.Visible) then nextRefresh=os.clock()+1; refresh() end
 local cam=workspace.CurrentCamera
 if cam then
  cam.FieldOfView=(player:GetAttribute("RiftFOV") or 80)*(player:GetAttribute("RiftZoom") or 1)
  local viewport=cam.ViewportSize
  local phone=input.TouchEnabled or viewport.X<700
  local compact=viewport.Y<500 and viewport.X>600
  title.Text=compact and pageName or "Rift"
  title.TextSize=compact and 20 or 32
  tabs.Position=UDim2.fromOffset(compact and 144 or 16,compact and 12 or 64)
  tabs.Size=UDim2.new(1,compact and -256 or -32,0,48)
  for _,page in pages do
   page.Position=UDim2.fromOffset(16,compact and 72 or 128)
   page.Size=UDim2.new(1,-32,1,compact and -88 or -144)
   page.UIListLayout.Padding=UDim.new(0,compact and 8 or 16)
   for _,r in page:GetChildren() do if r:IsA("Frame") and r:GetAttribute("CompactHidden") then r.Visible=not compact end end
  end
  local responsive=panel:FindFirstChildOfClass("UIScale")
  if not responsive then responsive=Instance.new("UIScale"); responsive.Parent=panel end
  responsive.Scale=1
  local navW,navH,gap=phone and 58 or 140,phone and 66 or 120,phone and 4 or 18
  for _,b in dock:GetChildren() do
   if b:IsA("TextButton") then
    b.Size=UDim2.fromOffset(navW,navH); b.Caption.Visible=not phone; b.Icon.TextSize=phone and 34 or 62
    b.Disc.Size=UDim2.fromOffset(phone and 54 or 84,phone and 54 or 84); b.BadgeAnchor.Size=b.Disc.Size; b.Icon.Position=UDim2.new(.5,0,0,phone and 27 or 40)
    navBadges[b.Name](player:GetAttribute("RiftBadge"..b.Name) or 0)
    if b.Name=="Shop" then local loading=shopLoading(); b.Active=not loading; b.Caption.Text=loading and "Loading..." or "Shop"; b.Icon.TextTransparency=loading and .45 or 0; b.Caption.TextTransparency=loading and .45 or 0 end
   end
  end
  strip.Size=UDim2.new(1,0,0,phone and 80 or 130)
  dockList.Padding=UDim.new(0,gap)
  dock.Size=UDim2.fromOffset(#NAV*navW+(#NAV-1)*gap,navH)
  notice.Visible=not phone
 end
 home.Visible=homeOpen and Controller.active==nil
 opener.Visible=not opened and not home.Visible and Controller.active~="Vote"
 local menuActive=opened or home.Visible or Controller.active=="Arsenal" or Controller.active=="Loadout" or Controller.active=="Shop" or Controller.active=="ShopConfirm"
 if lastMenuActive~=menuActive then lastMenuActive=menuActive; player:SetAttribute("RiftMenuOpen",menuActive) end
 local voting=Controller.active=="Vote"
 input.MouseDeltaSensitivity=menuActive and 0 or (player:GetAttribute("RiftSensitivity") or 1)
 if menuActive or voting then input.MouseBehavior=Enum.MouseBehavior.Default; input.MouseIconEnabled=true
 elseif player:GetAttribute("RiftThirdPerson") then input.MouseBehavior=Enum.MouseBehavior.Default; input.MouseIconEnabled=true
 else input.MouseBehavior=Enum.MouseBehavior.LockCenter; input.MouseIconEnabled=false end
end)
homeOpen=player:GetAttribute("RiftMap")=="Lobby" or player:GetAttribute("RiftMap")==nil
showPage("Play"); refresh()
