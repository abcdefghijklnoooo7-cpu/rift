-- Lobby Arsenal screen and in-game loadout picker (M), laid out after the reference screenshots with Rift's own content.
-- Equipping uses the existing RiftAction "loadout" remote. Outside the lobby the server queues the change for the next respawn.
local player=game.Players.LocalPlayer
local input=game:GetService("UserInputService")
local run=game:GetService("RunService")
local storage=game.ReplicatedStorage
local action=storage:WaitForChild("RiftAction")
local weapons=require(storage:WaitForChild("RiftWeapons"))
local Models=require(storage:WaitForChild("RiftWeaponModels"))
local UI=require(storage:WaitForChild("RiftUI"))
local Controller=require(storage:WaitForChild("RiftUIController"))
local Audio=require(storage:WaitForChild("RiftAudio"))
local Cat=require(storage:WaitForChild("RiftShopCatalog"))
local Prompt=require(storage:WaitForChild("RiftPurchasePrompt")) -- also arms the ShopConfirm view and "offer" events
local C=UI.C
local GOLD=Color3.fromRGB(255,196,64)
local EYE=Color3.fromRGB(20,150,255) -- bright action blue for "view" buttons, as in the reference

local gui=Instance.new("ScreenGui"); gui.Name="RiftArsenal"; gui.ResetOnSpawn=false; gui.DisplayOrder=32; gui.IgnoreGuiInset=true; gui.Parent=player:WaitForChild("PlayerGui")

local function inLobby() return player:GetAttribute("RiftMap")=="Lobby" and not player:GetAttribute("RiftQueued") and not player:GetAttribute("RiftDuelId") end
local function roleLine(id)
 local w=weapons[id]; local slot=weapons.SlotOf(id) or 1
 return (w.class or w.short).." · "..weapons.Slots[slot].label
end
local function equip(id)
 local slot=weapons.SlotOf(id)
 if not slot or not weapons.IsUnlocked(player,id) then return end
 action:FireServer("loadout",id,slot); Audio.Play("equip")
end
local function pill(parent,text,color,textColor)
 local p=Instance.new("TextLabel"); p.Name="Pill"; p.Text=text; p.Font=UI.Font.display; p.TextSize=13; p.TextColor3=textColor or C.background
 p.BackgroundColor3=color or C.accent; p.AutomaticSize=Enum.AutomaticSize.X; p.Size=UDim2.fromOffset(0,22); p.ZIndex=6; p.Parent=parent; UI.corner(p,11)
 local pad=Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,9); pad.PaddingRight=UDim.new(0,9); pad.Parent=p
 return p
end
local function card(parent,name,order)
 local f=UI.frame(parent,name,0,0,0,0,C.background); f.BackgroundTransparency=.22; f.Size=UDim2.new(1,0,0,0); f.AutomaticSize=Enum.AutomaticSize.Y; f.LayoutOrder=order or 0
 UI.corner(f,14); UI.padding(f,12)
 local s=Instance.new("UIStroke"); s.Color=C.text; s.Transparency=.9; s.Thickness=1.5; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=f
 return f
end
local function viewport(parent)
 local v=Instance.new("ViewportFrame"); v.BackgroundTransparency=1; v.Ambient=Color3.fromRGB(175,182,200); v.LightColor=Color3.new(1,1,1); v.LightDirection=Vector3.new(-1,-1.4,-.8); v.Parent=parent
 local cam=Instance.new("Camera"); cam.FieldOfView=30; cam.Parent=v; v.CurrentCamera=cam
 return v,cam
end
local function aimAt(cam,model,yaw,pitch,zoom)
 local cf,size=model:GetBoundingBox()
 local dist=math.max(size.Magnitude,1.2)*(zoom or 1.55)
 cam.CFrame=CFrame.new(cf.Position)*CFrame.Angles(0,yaw,0)*CFrame.Angles(pitch,0,0)*CFrame.new(0,0,dist)
end
-- The local player's equipped skin for a weapon (RiftSkins JSON attribute); nil for Fists or none.
local Skins=require(storage:WaitForChild("RiftSkins"))
local function equippedStyle(id)
 if id==21 or not Skins.Allowed(id) then return nil end
 local ok,t=pcall(function() return game:GetService("HttpService"):JSONDecode(player:GetAttribute("RiftSkins") or "{}") end)
 local style=ok and type(t)=="table" and t[tostring(id)]
 return Skins.Get(style) and style or nil
end
-- style: nil = equipped, false = Default, else a style id (stage previews).
local function skinFor(id,style)
 if style==nil then style=equippedStyle(id) end
 return style and id~=21 and Skins.Model(style) or nil
end
-- Shop pricing, display only (the server re-resolves every offer).
local function balance(cur)
 local a=tonumber(player:GetAttribute(cur=="cores" and "RiftCores" or "RiftShards")); if a then return a end
 local snap=Prompt.Snapshot and Prompt.Snapshot()
 return snap and tonumber(snap[cur=="cores" and "cores" or "shards"]) or 0
end
local function money(cur,n) return Prompt.Glyph(cur).." "..Prompt.Format(n) end
local function pct(d) return "-"..math.floor(d*100+.5).."%" end
local dailyDay,dailyCache
local function dailyOffers()
 local day=Cat.Today(math.floor(workspace:GetServerTimeNow()))
 if day~=dailyDay then dailyDay,dailyCache=day,Cat.Daily(day) end
 return dailyCache
end
-- Cheapest live offer for a weapon (style nil) or a weapon skin: offerId, price, cur, discount|nil.
local function offerFor(id,style)
 local oid,price,cur=style and ("s:"..id..":"..style) or ("w:"..id),nil,"shards"
 if style then price,cur=Cat.SkinPrice(style) else price=Cat.WeaponPrice(id) end
 if not price then return nil end
 local discount
 for _,d in dailyOffers() do
  local match=d.weapon==id and (style and d.kind=="skin" and d.style==style or not style and d.kind=="weapon")
  if match and d.cur==cur and d.price<price and (not Prompt.Resolve or Prompt.Resolve(d.id)~=nil) then oid,price,discount=d.id,d.price,d.discount end
 end
 return oid,price,cur,discount
end
local function ownsSkin(id,style)
 local snap=Prompt.Snapshot and Prompt.Snapshot()
 return snap~=nil and type(snap.ownedSkins)=="table" and snap.ownedSkins[Skins.Key(id,style)]==true
end
local function icon3D(parent,id,yaw,zoom)
 local v,cam=viewport(parent)
 local m=Models.create(weapons[id],skinFor(id)); m.Parent=v; Models.recolorFists(m,player)
 aimAt(cam,m,yaw or math.rad(-62),-.18,zoom or 1.2)
 return v
end
-- Round icon button with a label underneath (bottom action row).
local function roundButton(parent,glyph,label,color,callback,order)
 local holder=UI.frame(parent,label,0,0,92,96); holder.BackgroundTransparency=1; holder.LayoutOrder=order
 local b=Instance.new("TextButton"); b.Name="Circle"; b.Text=glyph; b.Font=UI.Font.display; b.TextSize=34; b.TextColor3=C.text; b.AutoButtonColor=false
 b.AnchorPoint=Vector2.new(.5,0); b.Position=UDim2.new(.5,0,0,0); b.Size=UDim2.fromOffset(66,66); b.BackgroundColor3=color or C.panel; b.Parent=holder; UI.corner(b,33)
 local s=Instance.new("UIStroke"); s.Color=C.text; s.Transparency=.8; s.Thickness=2; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=b
 local t=UI.text(holder,label,0,68,0,26,20,C.text,true); t.Size=UDim2.new(1,0,0,26); t.TextXAlignment=Enum.TextXAlignment.Center; t.TextSize=20
 b.Activated:Connect(function() if b.Active and callback then callback() end end)
 return holder,b,t
end

------------------------------------------------------------------ Arsenal: 3D display scene fills the screen
local screen=Instance.new("CanvasGroup"); screen.Name="ArsenalScreen"; screen.Size=UDim2.fromScale(1,1); screen.BackgroundColor3=C.panel; screen.Parent=gui
local sky=Instance.new("UIGradient"); sky.Rotation=90; sky.Color=ColorSequence.new(Color3.fromRGB(46,60,96),C.background); sky.Parent=screen
local stageView,stageCam=viewport(screen); stageView.Name="Stage"; stageView.Size=UDim2.fromScale(1,1)
local function prop(size,cf,color,shape)
 local p=Instance.new("Part"); p.Anchored=true; p.Size=size; p.CFrame=cf; p.Color=color; p.Material=Enum.Material.SmoothPlastic; if shape then p.Shape=shape end; p.Parent=stageView; return p
end
prop(Vector3.new(60,1,40),CFrame.new(0,-2.6,-6),Color3.fromRGB(34,44,72))
prop(Vector3.new(60,30,1),CFrame.new(0,8,-14),Color3.fromRGB(28,37,61))
-- Display stand matching the lobby's weapon displays: metal plinth, teal ring, dark top, floating weapon.
local up=CFrame.Angles(0,0,math.rad(90))
prop(Vector3.new(2.4,9,9),CFrame.new(0,-2.9,0)*up,Color3.fromRGB(85,105,128),Enum.PartType.Cylinder).Material=Enum.Material.Metal
prop(Vector3.new(.3,9.4,9.4),CFrame.new(0,-1.6,0)*up,C.accent,Enum.PartType.Cylinder).Material=Enum.Material.Neon
prop(Vector3.new(.4,8,8),CFrame.new(0,-1.5,0)*up,Color3.fromRGB(18,26,40),Enum.PartType.Cylinder)
prop(Vector3.new(.05,12,12),CFrame.new(0,-2.08,0)*up,C.accent,Enum.PartType.Cylinder).Transparency=.82 -- soft floor glow
prop(Vector3.new(6,4,4),CFrame.new(-9,-0.1,-7)*CFrame.Angles(0,.3,0),Color3.fromRGB(64,78,118))
prop(Vector3.new(4,6,4),CFrame.new(9.5,0.9,-8)*CFrame.Angles(0,-.2,0),Color3.fromRGB(58,72,110))

local title=UI.text(screen,"ARSENAL",0,14,0,40,32,C.text,true); title.AnchorPoint=Vector2.new(.5,0); title.Position=UDim2.new(.5,0,0,14); title.Size=UDim2.fromOffset(400,40); title.TextXAlignment=Enum.TextXAlignment.Center
local subtitle=UI.text(screen,"",0,54,0,20,13,C.text); subtitle.AnchorPoint=Vector2.new(.5,0); subtitle.Position=UDim2.new(.5,0,0,54); subtitle.Size=UDim2.fromOffset(600,20); subtitle.TextXAlignment=Enum.TextXAlignment.Center; subtitle.TextTransparency=.25
-- Currency bar (top-right): Shards and Cores; tap for how to earn.
local wallet=UI.frame(screen,"Wallet",0,0,0,36); wallet.AnchorPoint=Vector2.new(1,0); wallet.Position=UDim2.new(1,-18,0,16); wallet.Size=UDim2.fromOffset(0,36); wallet.AutomaticSize=Enum.AutomaticSize.X; wallet.BackgroundTransparency=1
local walletLayout=Instance.new("UIListLayout"); walletLayout.FillDirection=Enum.FillDirection.Horizontal; walletLayout.Padding=UDim.new(0,8); walletLayout.SortOrder=Enum.SortOrder.LayoutOrder; walletLayout.Parent=wallet
local walletPills={}
for i,cur in {"shards","cores"} do
 local b=Instance.new("TextButton"); b.Name=cur; b.AutoButtonColor=false; b.Font=UI.Font.display; b.TextSize=18; b.TextColor3=Prompt.Color(cur); b.BackgroundColor3=C.background; b.BackgroundTransparency=.2
 b.AutomaticSize=Enum.AutomaticSize.X; b.Size=UDim2.fromOffset(0,36); b.LayoutOrder=i; b.Parent=wallet; UI.corner(b,18)
 local pad=Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,14); pad.PaddingRight=UDim.new(0,14); pad.Parent=b
 local s=Instance.new("UIStroke"); s.Color=Prompt.Color(cur); s.Thickness=2; s.Transparency=.35; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=b
 b.Activated:Connect(function() if Prompt.HowToEarn then Prompt.HowToEarn() end end)
 walletPills[cur]=b
end
local function refreshWallet() for cur,b in walletPills do b.Text=money(cur,balance(cur)) end end
local previewPill=pill(screen,"PREVIEW",GOLD); previewPill.AnchorPoint=Vector2.new(.5,0); previewPill.Position=UDim2.new(.5,0,0,82); previewPill.Visible=false

-- Left sidebar: fades into the scene, weapon icon + name rows.
local sidebar=UI.frame(screen,"Sidebar",0,0,0,0,C.background); sidebar.Size=UDim2.new(0,330,1,0)
local sideFade=Instance.new("UIGradient"); sideFade.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.08),NumberSequenceKeypoint.new(.75,.25),NumberSequenceKeypoint.new(1,1)}); sideFade.Parent=sidebar
local catTitle=UI.text(sidebar,"",20,16,0,40,32,C.text,true); catTitle.Size=UDim2.new(1,-40,0,40)
local catRow=UI.frame(sidebar,"Categories",20,62,280,34); catRow.BackgroundTransparency=1
local listFrame=Instance.new("ScrollingFrame"); listFrame.Name="WeaponList"; listFrame.Position=UDim2.fromOffset(0,108); listFrame.Size=UDim2.new(1,-20,1,-120); listFrame.BackgroundTransparency=1; listFrame.BorderSizePixel=0
listFrame.ScrollBarThickness=4; listFrame.ScrollBarImageColor3=C.text; listFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y; listFrame.CanvasSize=UDim2.new(); listFrame.Parent=sidebar
local listLayout=Instance.new("UIListLayout"); listLayout.Padding=UDim.new(0,2); listLayout.SortOrder=Enum.SortOrder.LayoutOrder; listLayout.Parent=listFrame

-- Right: stacked cards in the bottom-right corner.
local stack=UI.frame(screen,"InfoStack",0,0,0,0); stack.AnchorPoint=Vector2.new(1,1); stack.Position=UDim2.new(1,-18,1,-18); stack.Size=UDim2.fromOffset(340,0); stack.AutomaticSize=Enum.AutomaticSize.Y; stack.BackgroundTransparency=1
local stackLayout=Instance.new("UIListLayout"); stackLayout.Padding=UDim.new(0,8); stackLayout.SortOrder=Enum.SortOrder.LayoutOrder; stackLayout.VerticalAlignment=Enum.VerticalAlignment.Bottom; stackLayout.Parent=stack
local infoCard=card(stack,"Info",1)
local infoList=Instance.new("UIListLayout"); infoList.Padding=UDim.new(0,2); infoList.SortOrder=Enum.SortOrder.LayoutOrder; infoList.Parent=infoCard
local nameLabel=UI.text(infoCard,"",0,0,0,34,28,C.text,true); nameLabel.Size=UDim2.new(1,0,0,34); nameLabel.LayoutOrder=1; nameLabel.TextScaled=true
local nameLimit=Instance.new("UITextSizeConstraint"); nameLimit.MaxTextSize=28; nameLimit.Parent=nameLabel
local role=UI.text(infoCard,"",0,0,0,18,13,C.text); role.Size=UDim2.new(1,0,0,18); role.LayoutOrder=2; role.TextTransparency=.15
local description=UI.text(infoCard,"",0,0,0,0,13,C.text); description.Size=UDim2.new(1,0,0,0); description.AutomaticSize=Enum.AutomaticSize.Y; description.TextWrapped=true; description.LayoutOrder=3; description.TextTransparency=.25
local equipCard=card(stack,"Equip",2)
local statusLine=UI.text(equipCard,"",0,0,0,20,16,C.text,true); statusLine.Size=UDim2.new(1,0,0,20)
local equipButton=UI.button(equipCard,"Equip",0,26,0,48,function() end,true); equipButton.Size=UDim2.new(1,0,0,48); equipButton.TextSize=20
local equipHint=UI.text(equipCard,"Win duels to earn Shards",0,74,0,0,13,C.text); equipHint.Size=UDim2.new(1,0,0,0); equipHint.TextTransparency=.3; equipHint.TextXAlignment=Enum.TextXAlignment.Center; equipHint.Visible=false
local rowsCard=card(stack,"Actions",3)
local rowsList=Instance.new("UIListLayout"); rowsList.Padding=UDim.new(0,8); rowsList.SortOrder=Enum.SortOrder.LayoutOrder; rowsList.Parent=rowsCard
local detail=card(screen,"Detail",0); detail.AutomaticSize=Enum.AutomaticSize.None; detail.AnchorPoint=Vector2.new(1,1); detail.Position=UDim2.new(1,-370,1,-18); detail.Size=UDim2.fromOffset(330,0); detail.AutomaticSize=Enum.AutomaticSize.Y; detail.Visible=false
local detailList=Instance.new("UIListLayout"); detailList.Padding=UDim.new(0,10); detailList.SortOrder=Enum.SortOrder.LayoutOrder; detailList.Parent=detail
local detailTitle=UI.text(detail,"",0,0,0,28,20,C.text,true); detailTitle.Size=UDim2.new(1,0,0,28); detailTitle.LayoutOrder=0
local detailBody=UI.text(detail,"",0,0,0,0,13,C.text); detailBody.Size=UDim2.new(1,0,0,0); detailBody.AutomaticSize=Enum.AutomaticSize.Y; detailBody.TextWrapped=true; detailBody.LayoutOrder=1; detailBody.TextYAlignment=Enum.TextYAlignment.Top
local detailMode
local statRows={}
local function statRow(name,order)
 local r=UI.frame(detail,name,0,0,0,38); r.Size=UDim2.new(1,0,0,38); r.BackgroundTransparency=1; r.LayoutOrder=10+order
 local label=UI.text(r,name,0,0,0,18,16,C.text,true); label.Size=UDim2.new(.6,0,0,18)
 local value=UI.text(r,"",0,0,0,18,16,C.text,true); value.AnchorPoint=Vector2.new(1,0); value.Position=UDim2.fromScale(1,0); value.Size=UDim2.new(.4,0,0,18); value.TextXAlignment=Enum.TextXAlignment.Right
 local track=UI.frame(r,"Track",0,24,0,10,C.panel); track.Size=UDim2.new(1,0,0,10); UI.corner(track,5)
 local fill=UI.frame(track,"Fill",0,0,0,10,EYE); fill.Size=UDim2.fromScale(.5,1); UI.corner(fill,5); UI.shade(fill,.25)
 statRows[name]={value=value,fill=fill,row=r}
end
for i,name in {"Damage","Fire rate","Range","Magazine","Reload","Headshot"} do statRow(name,i) end
local function actionRow(glyph,title,sub,order,onView)
 local r=UI.frame(rowsCard,title,0,0,0,46); r.Size=UDim2.new(1,0,0,46); r.BackgroundTransparency=1; r.LayoutOrder=order
 local g=UI.text(r,glyph,0,0,40,46,20); g.TextSize=26; g.TextXAlignment=Enum.TextXAlignment.Center
 local t=UI.text(r,title,46,2,0,24,20,C.text,true); t.Size=UDim2.new(1,-130,0,24)
 local s=UI.text(r,sub,46,26,0,16,13,C.text); s.Size=UDim2.new(1,-130,0,16); s.TextTransparency=.3; s.TextSize=12
 local eye=Instance.new("TextButton"); eye.Name="View"; eye.AnchorPoint=Vector2.new(1,.5); eye.Position=UDim2.new(1,0,.5,0); eye.Size=UDim2.fromOffset(74,42); eye.AutoButtonColor=false
 eye.BackgroundColor3=EYE; eye.Text=onView and "👁" or "SOON"; eye.Font=UI.Font.display; eye.TextSize=onView and 24 or 14; eye.TextColor3=C.text; eye.Parent=r; UI.corner(eye,10); UI.shade(eye,.22)
 local es=Instance.new("UIStroke"); es.Color=C.text; es.Thickness=2; es.Transparency=.55; es.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; es.Parent=eye
 if not onView then eye.Active=false; eye.BackgroundTransparency=.5; t.TextTransparency=.4 end
 eye.Activated:Connect(function() if onView then onView() end end)
 return r
end

-- Bottom action row: Leave + cosmetic slots (placeholders until the shop stage).
local actions=UI.frame(screen,"Actions",0,0,0,108,C.background); actions.AnchorPoint=Vector2.new(.5,1); actions.Position=UDim2.new(.5,0,1,-10); actions.Size=UDim2.fromOffset(5*92+40,108); actions.BackgroundTransparency=.35; UI.corner(actions,18)
local actionsLayout=Instance.new("UIListLayout"); actionsLayout.FillDirection=Enum.FillDirection.Horizontal; actionsLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; actionsLayout.VerticalAlignment=Enum.VerticalAlignment.Center; actionsLayout.SortOrder=Enum.SortOrder.LayoutOrder; actionsLayout.Parent=actions
roundButton(actions,"✖","Leave",C.danger,function() Controller:Set("Arsenal",false) end,0)
local skinButton,toggleStrip,setPreview
for i,item in {{"🎨","Skin"},{"🌀","Wrap"},{"🧿","Charm"},{"💥","Finisher"}} do
 local holder,b,t=roundButton(actions,item[1],item[2],C.panel,i==1 and function() if toggleStrip then toggleStrip() end end or nil,i)
 if i==1 then skinButton={button=b,label=t}
 else
  b.Active=false; b.TextTransparency=.45; b.BackgroundTransparency=.3; t.TextTransparency=.35
  local soon=pill(holder,"SOON"); soon.AnchorPoint=Vector2.new(.5,.5); soon.Position=UDim2.new(.5,22,0,4)
 end
end

local activeCategory,selected=1,weapons.GetId(player,1)
local rows,categoryButtons,rowIcons={},{},{}
local model,modelKey,modelOffset
local yaw,pitch,dragging,lastDrag=math.rad(-35),0,false,0
local preview,stripOpen,busy=nil,false,false -- preview: style id or false (Default); nil = show the equipped style
local arsenalWanted=false
local refreshInfo

-- Skin strip above the action row: Default + every style for the selected weapon. Clicks preview on the stage.
local strip=UI.frame(screen,"SkinStrip",0,0,0,0,C.background); strip.AnchorPoint=Vector2.new(.5,1); strip.Position=UDim2.new(.5,0,1,-126); strip.Size=UDim2.new(1,-730,0,150); strip.BackgroundTransparency=.3; strip.Visible=false; UI.corner(strip,16)
local stripMax=Instance.new("UISizeConstraint"); stripMax.MinSize=Vector2.new(320,150); stripMax.MaxSize=Vector2.new(760,150); stripMax.Parent=strip
local stripList=Instance.new("ScrollingFrame"); stripList.Name="Styles"; stripList.Position=UDim2.fromOffset(10,8); stripList.Size=UDim2.new(1,-162,1,-12); stripList.BackgroundTransparency=1; stripList.BorderSizePixel=0
stripList.ScrollingDirection=Enum.ScrollingDirection.X; stripList.ScrollBarThickness=4; stripList.ScrollBarImageColor3=C.text; stripList.AutomaticCanvasSize=Enum.AutomaticSize.X; stripList.CanvasSize=UDim2.new(); stripList.Parent=strip
local stripLayout=Instance.new("UIListLayout"); stripLayout.FillDirection=Enum.FillDirection.Horizontal; stripLayout.Padding=UDim.new(0,8); stripLayout.SortOrder=Enum.SortOrder.LayoutOrder; stripLayout.Parent=stripList
local stripButton=UI.button(strip,"EQUIP",0,0,0,0,function() end,true); stripButton.AnchorPoint=Vector2.new(1,.5); stripButton.Position=UDim2.new(1,-10,.5,0); stripButton.Size=UDim2.fromOffset(136,56); stripButton.TextSize=16; stripButton.TextWrapped=true
local stripCells={}
local styleOrder={false}
for _,s in Skins.LIST do table.insert(styleOrder,s.id) end
for i,style in styleOrder do
 local s=style and Skins.Get(style)
 local b=Instance.new("TextButton"); b.Name=style or "Default"; b.Text=""; b.AutoButtonColor=false; b.LayoutOrder=i; b.Size=UDim2.fromOffset(92,128); b.BackgroundColor3=C.panel; b.Parent=stripList; UI.corner(b,12)
 local stroke=Instance.new("UIStroke"); stroke.Color=C.text; stroke.Thickness=1.5; stroke.Transparency=.8; stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; stroke.Parent=b
 local sw=UI.frame(b,"Swatch",10,8,72,44,s and s.paint or Color3.fromRGB(85,105,128)); UI.corner(sw,8)
 local band=UI.frame(sw,"Trim",0,28,72,16,s and s.trim or Color3.fromRGB(40,46,58)); UI.corner(band,8)
 local n=UI.text(b,s and s.name or "Default",0,56,0,20,14,C.text,true); n.Size=UDim2.new(1,0,0,20); n.TextXAlignment=Enum.TextXAlignment.Center; n.TextSize=14
 local tier=s and Skins.TIERS[s.tier]
 local t=UI.text(b,s and s.tier or "Factory",0,75,0,14,11,tier and tier.color or C.text); t.Size=UDim2.new(1,0,0,14); t.TextXAlignment=Enum.TextXAlignment.Center; t.TextSize=11
 local badge=pill(b,""); badge.AnchorPoint=Vector2.new(.5,1); badge.Position=UDim2.new(.5,0,1,-6); badge.TextSize=11; badge.Size=UDim2.fromOffset(0,20)
 b.Activated:Connect(function() if setPreview then setPreview(style) end; Audio.Play("equip") end)
 table.insert(stripCells,{style=style,stroke=stroke,badge=badge})
end
local function refreshStrip()
 local allowed=Skins.Allowed(selected)
 if skinButton then
  skinButton.button.Active=allowed; skinButton.button.TextTransparency=allowed and 0 or .45; skinButton.button.BackgroundTransparency=allowed and 0 or .3; skinButton.label.TextTransparency=allowed and 0 or .35
 end
 if not allowed then stripOpen=false; preview=nil end -- Fists: no skins
 strip.Visible=stripOpen
 if not stripOpen then return end
 local eq=equippedStyle(selected) or false
 local view=preview; if view==nil then view=eq end
 for _,cell in stripCells do
  local style=cell.style
  local current=style==view
  cell.stroke.Color=current and C.accent or C.text; cell.stroke.Thickness=current and 3 or 1.5; cell.stroke.Transparency=current and 0 or .8
  local b=cell.badge
  if style==eq then b.Text="EQUIPPED"; b.BackgroundColor3=C.accent; b.TextColor3=C.background
  elseif style==false or ownsSkin(selected,style) then b.Text="OWNED"; b.BackgroundColor3=C.panel; b.TextColor3=C.text
  else
   local _o,price,cur,discount=offerFor(selected,style)
   local can=price~=nil and balance(cur)>=price
   b.Text=price and money(cur,price)..(discount and " "..pct(discount) or "") or "N/A"
   b.BackgroundColor3=can and Prompt.Color(cur) or C.danger; b.TextColor3=can and C.background or C.text
  end
 end
 local active,text=false,"EQUIPPED"
 if busy then text="..."
 elseif view==eq then text=view==false and "DEFAULT" or "EQUIPPED"
 elseif view==false or ownsSkin(selected,view) then text,active="EQUIP",true
 else
  local _o,price,cur=offerFor(selected,view)
  local need=price and price-balance(cur) or 0
  if not price then text="UNAVAILABLE" elseif need>0 then text="NEED "..Prompt.Format(need).." MORE" else text,active="BUY  "..money(cur,price),true end
 end
 stripButton.Text=text; stripButton.Active=active; stripButton.BackgroundTransparency=active and 0 or .45
end

local maxStat={damage=1,rpm=1,range=1,magazine=1,head=1}
for _,w in ipairs(weapons) do
 if not w.item then
  maxStat.damage=math.max(maxStat.damage,(w.directDamage or w.bodyDamage or 0)*(w.pellets or 1))
  maxStat.rpm=math.max(maxStat.rpm,60/math.max(w.shotInterval or 1,.01))
  maxStat.range=math.max(maxStat.range,w.range or 0)
  maxStat.magazine=math.max(maxStat.magazine,w.magazine or 0)
  maxStat.head=math.max(maxStat.head,w.headMultiplier or 1)
 end
end
local function setStat(name,shown,fraction,text)
 local s=statRows[name]; s.row.Visible=shown
 if shown then s.value.Text=text; s.fill.Size=UDim2.fromScale(math.clamp(fraction,.03,1),1) end
end
local function refreshDetail()
 detail.Visible=detailMode~=nil
 if not detailMode then return end
 local w=weapons[selected]
 local stats=detailMode=="Statistics"
 detailTitle.Text=stats and "Statistics" or "Overview"
 for _,s in statRows do s.row.Visible=false end
 if stats then
  detailBody.Text="Measured per shot. Bars compare against every weapon in Rift."
  local damage=(w.directDamage or w.bodyDamage or 0)*(w.pellets or 1)
  local gun=not w.item
  local rpm=60/math.max(w.shotInterval or 1,.01)
  setStat("Damage",damage>0,damage/maxStat.damage,(w.pellets and w.pellets>1) and string.format("%d × %d",w.bodyDamage,w.pellets) or tostring(math.floor(damage+.5)))
  setStat("Fire rate",gun,rpm/maxStat.rpm,string.format("%d RPM",rpm))
  setStat("Range",(w.range or 0)>0,(w.range or 0)/maxStat.range,string.format("%d studs",w.range or 0))
  setStat("Magazine",gun,(w.magazine or 0)/maxStat.magazine,tostring(w.magazine or 0))
  setStat("Reload",gun,1-math.clamp(((w.reloadTime or 0)-.8)/3.2,0,.97),string.format("%.1fs",w.reloadTime or 0))
  setStat("Headshot",gun,(w.headMultiplier or 1)/maxStat.head,string.format("×%.2f",w.headMultiplier or 1))
 else
  local slot=weapons.SlotOf(selected) or 1
  detailBody.Text=(w.description or "").."\n\nSlot "..slot.." · "..weapons.Slots[slot].label..(w.automatic and "\nFull-auto" or "")..(w.melee and "\nMelee" or "")
 end
end
local function toggleDetail(mode)
 detailMode=detailMode~=mode and mode or nil
 if detailMode and stripOpen then stripOpen=false; preview=nil; refreshInfo() else refreshDetail() end -- detail card and skin strip share space
end
actionRow("📜","Contracts","Earn rewards",1,nil)
actionRow("✨","Overview","About this weapon",2,function() toggleDetail("Overview") end)
actionRow("📊","Statistics","Damage, fire rate, range",3,function() toggleDetail("Statistics") end)

local function rowIcon(id)
 if rowIcons[id] then return end
 local v=icon3D(rows[id].button,id,math.rad(-60),1.1); v.Position=UDim2.fromOffset(10,3); v.Size=UDim2.fromOffset(86,48); v.ZIndex=2
 rowIcons[id]=v
end
local function refreshRows()
 local count=0
 for id,row in rows do
  local slot=weapons.SlotOf(id)
  local visible=slot==activeCategory
  row.button.Visible=visible
  if visible then rowIcon(id) end
  local isSelected=id==selected
  local equipped=slot and weapons.GetId(player,slot)==id
  local pending=slot and player:GetAttribute("RiftPending"..slot)==id
  local locked=not weapons.IsUnlocked(player,id)
  row.bar.Visible=isSelected
  row.button.BackgroundTransparency=isSelected and .55 or 1
  row.name.TextColor3=isSelected and C.accent or C.text
  row.name.TextTransparency=locked and .45 or 0
  row.tag.Visible=equipped or pending or locked
  local discount
  if locked then -- price pill: accent if affordable, danger if not
   local _o,price,cur,d=offerFor(id); discount=d
   local can=price~=nil and balance(cur)>=price
   row.tag.Text=price and money(cur,price) or "🔒"
   row.tag.BackgroundColor3=can and C.accent or C.danger; row.tag.TextColor3=can and C.background or C.text
  else
   row.tag.Text=pending and "NEXT" or "✓"; row.tag.BackgroundColor3=C.accent; row.tag.TextColor3=C.background
  end
  row.ribbon.Visible=discount~=nil; if discount then row.ribbon.Text=pct(discount) end
 end
 for i,b in categoryButtons do UI.select(b,i==activeCategory) end
 catTitle.Text=weapons.Slots[activeCategory].label
end
function refreshInfo()
 local w=weapons[selected]; if not w then return end
 local slot=weapons.SlotOf(selected) or 1
 nameLabel.Text=w.name
 role.Text="• "..roleLine(selected)
 description.Text="• "..(w.description or "")
 local equippedId=weapons.GetId(player,slot)
 local pendingId=player:GetAttribute("RiftPending"..slot)
 local locked=not weapons.IsUnlocked(player,selected)
 local _o,price,cur
 if locked then _o,price,cur=offerFor(selected) end
 local need=price and price-balance(cur) or 0
 statusLine.Text=locked and (price and "🔒 Locked - "..Prompt.Format(price)..(cur=="cores" and " Cores" or " Shards") or "🔒 Locked — unlock in the Shop") or (pendingId==selected and "Equips when you next respawn" or (equippedId==selected and "✓ Equipped in "..weapons.Slots[slot].label or ("In slot now: "..weapons[equippedId].name)))
 if locked and price and need>0 then equipButton.Text="NEED "..Prompt.Format(need).." MORE"; equipButton.Active=false
 elseif locked and price then equipButton.Text="UNLOCK - "..Prompt.Format(price); equipButton.Active=true
 elseif locked then equipButton.Text="LOCKED"; equipButton.Active=false
 elseif equippedId==selected and not pendingId then equipButton.Text="EQUIPPED"; equipButton.Active=false
 elseif pendingId==selected then equipButton.Text="NEXT RESPAWN"; equipButton.Active=false
 else equipButton.Text=inLobby() and "EQUIP" or "EQUIP NEXT RESPAWN"; equipButton.Active=true end
 equipButton.BackgroundTransparency=equipButton.Active and 0 or .45
 local hint=locked and price~=nil and need>0
 equipHint.Visible=hint; equipHint.Size=UDim2.new(1,0,0,hint and 18 or 0); equipHint.Position=UDim2.fromOffset(0,hint and 80 or 74)
 subtitle.Text=inLobby() and "Pick a weapon · drag it to rotate" or "In a match: changes apply when you next respawn"
 local style=preview; if style==nil then style=equippedStyle(selected) or false end
 local key=selected..":"..tostring(style)
 if modelKey~=key then
  if model then model:Destroy() end
  model=Models.create(w,skinFor(selected,style)); Models.recolorFists(model,player); modelKey=key
  local cf,size=model:GetBoundingBox()
  modelOffset=cf:Inverse()*model:GetPivot()
  local scale=math.clamp(4.2/math.max(size.X,size.Y,size.Z,.5),.6,3)
  if model.ScaleTo then model:ScaleTo(scale); cf,size=model:GetBoundingBox(); modelOffset=cf:Inverse()*model:GetPivot() end
  model.Parent=stageView
 end
 refreshStrip()
 previewPill.Visible=preview~=nil and stripOpen
 refreshDetail()
end
equipButton.Activated:Connect(function()
 if not equipButton.Active then return end
 if weapons.IsUnlocked(player,selected) then equip(selected)
 else local oid=offerFor(selected); if oid and Prompt.Open then Prompt.Open(oid) end end -- cheaper daily offer id when there is one
end)
toggleStrip=function()
 if not Skins.Allowed(selected) then return end
 stripOpen=not stripOpen; preview=nil
 if stripOpen then detailMode=nil end
 refreshInfo()
end
setPreview=function(style)
 local eq=equippedStyle(selected) or false
 preview=style~=eq and style or nil
 if style==false and eq~=false then preview=false end
 refreshInfo()
end
stripButton.Activated:Connect(function()
 if not stripButton.Active or busy then return end
 local id=selected; local eq=equippedStyle(id) or false
 local view=preview; if view==nil then view=eq end
 if view==eq then return end
 if view==false or ownsSkin(id,view) then
  if not Prompt.EquipSkin then return end
  busy=true; refreshStrip()
  task.spawn(function()
   local res=Prompt.EquipSkin(id,view)
   busy=false
   if res and res.ok then if selected==id then preview=nil end; Audio.Play("equip") end
   refreshInfo()
  end)
 else
  local oid=offerFor(id,view)
  if oid and Prompt.Open then Prompt.Open(oid) end
 end
end)

local function select(id)
 if id~=selected then preview=nil end
 selected=id; refreshRows(); refreshInfo()
end
for i,definition in ipairs(weapons.Slots) do
 local b=UI.button(catRow,definition.label,0,0,0,34,function()
  activeCategory=i; select(weapons.GetId(player,i)); listFrame.CanvasPosition=Vector2.zero
 end)
 b.Position=UDim2.new((i-1)*.25,0,0,0); b.Size=UDim2.new(.25,-4,1,0); b.TextSize=14; categoryButtons[i]=b
end
for id,w in ipairs(weapons) do
 local b=Instance.new("TextButton"); b.Name=w.name; b.Text=""; b.AutoButtonColor=false; b.BackgroundColor3=C.background; b.BackgroundTransparency=1
 b.Size=UDim2.new(1,0,0,56); b.LayoutOrder=id; b.Parent=listFrame
 local bar=UI.frame(b,"Selected",0,8,4,40,C.accent); bar.Visible=false; UI.corner(bar,2)
 local n=UI.text(b,w.name,104,0,0,56,20,C.text,true); n.Size=UDim2.new(1,-150,1,0); n.TextSize=20; n.TextTruncate=Enum.TextTruncate.AtEnd; n.ZIndex=3
 local tag=pill(b,"✓"); tag.AnchorPoint=Vector2.new(1,.5); tag.Position=UDim2.new(1,-12,.5,0)
 local ribbon=pill(b,"-25%",GOLD); ribbon.AnchorPoint=Vector2.new(1,0); ribbon.Position=UDim2.new(1,-8,0,0); ribbon.Size=UDim2.fromOffset(0,16); ribbon.TextSize=11; ribbon.ZIndex=7; ribbon.Visible=false
 b.Activated:Connect(function() select(id); Audio.Play("equip") end)
 rows[id]={button=b,name=n,tag=tag,bar=bar,ribbon=ribbon}
end

-- Drag anywhere on the scene to rotate; slow auto-spin resumes after a moment.
stageView.InputBegan:Connect(function(io)
 if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dragging=true end
end)
input.InputEnded:Connect(function(io)
 if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dragging=false; lastDrag=os.clock() end
end)
input.InputChanged:Connect(function(io)
 if dragging and (io.UserInputType==Enum.UserInputType.MouseMovement or io.UserInputType==Enum.UserInputType.Touch) then
  yaw+=io.Delta.X*.012; pitch=math.clamp(pitch+io.Delta.Y*.008,-.7,.7); lastDrag=os.clock()
 end
end)
stageCam.FieldOfView=40
stageCam.CFrame=CFrame.lookAt(Vector3.new(1.2,2.2,9.5),Vector3.new(1.2,.6,0))

------------------------------------------------------------------ In-game loadout picker (M)
local picker=Instance.new("CanvasGroup"); picker.Name="LoadoutPicker"; picker.Size=UDim2.fromScale(1,1); picker.BackgroundColor3=C.background; picker.BackgroundTransparency=.4; picker.Parent=gui
local blur=Instance.new("BlurEffect"); blur.Name="RiftPickerBlur"; blur.Size=0
local content=UI.frame(picker,"Content",0,0,0,0); content.AnchorPoint=Vector2.new(.5,.5); content.Position=UDim2.fromScale(.5,.5); content.Size=UDim2.fromScale(.94,.92); content.BackgroundTransparency=1
local contentMax=Instance.new("UISizeConstraint"); contentMax.MaxSize=Vector2.new(980,760); contentMax.Parent=content
local pickerClose=Instance.new("TextButton"); pickerClose.Name="Close"; pickerClose.Text="✖"; pickerClose.Font=UI.Font.display; pickerClose.TextSize=26; pickerClose.TextColor3=C.text; pickerClose.AutoButtonColor=false
pickerClose.AnchorPoint=Vector2.new(1,0); pickerClose.Position=UDim2.fromScale(1,0); pickerClose.Size=UDim2.fromOffset(70,46); pickerClose.BackgroundColor3=C.danger; pickerClose.Parent=content; UI.corner(pickerClose,10); UI.shade(pickerClose,.22)
pickerClose.Activated:Connect(function() Controller:Set("Loadout",false) end)
local pickerHint=UI.text(content,"Changes apply when you next respawn — never mid-round   ·   M to close",0,0,0,22,16,C.text,true); pickerHint.AnchorPoint=Vector2.new(.5,1); pickerHint.Position=UDim2.new(.5,0,1,0); pickerHint.Size=UDim2.new(1,0,0,22); pickerHint.TextXAlignment=Enum.TextXAlignment.Center
local slotRow=UI.frame(content,"Slots",0,0,0,112); slotRow.Size=UDim2.new(1,-90,0,112); slotRow.BackgroundTransparency=1
local slotLayout=Instance.new("UIListLayout"); slotLayout.FillDirection=Enum.FillDirection.Horizontal; slotLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; slotLayout.Padding=UDim.new(0,14); slotLayout.SortOrder=Enum.SortOrder.LayoutOrder; slotLayout.Parent=slotRow
local grid=Instance.new("ScrollingFrame"); grid.Name="Grid"; grid.Position=UDim2.fromOffset(0,132); grid.Size=UDim2.new(1,0,1,-170); grid.BackgroundTransparency=1; grid.BorderSizePixel=0
grid.ScrollBarThickness=4; grid.ScrollBarImageColor3=C.text; grid.AutomaticCanvasSize=Enum.AutomaticSize.Y; grid.CanvasSize=UDim2.new(); grid.ClipsDescendants=true; grid.Parent=content
local gridPad=Instance.new("UIPadding"); gridPad.PaddingTop=UDim.new(0,28); gridPad.PaddingLeft=UDim.new(0,14); gridPad.PaddingRight=UDim.new(0,14); gridPad.Parent=grid
local gridLayout=Instance.new("UIGridLayout"); gridLayout.CellSize=UDim2.fromOffset(160,150); gridLayout.CellPadding=UDim2.fromOffset(16,34); gridLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; gridLayout.SortOrder=Enum.SortOrder.LayoutOrder; gridLayout.Parent=grid
local pickSlot=1
local slotCards,tiles,slotIcons={},{},{}
local function tileFrame(parent,name,order,dark)
 local b=Instance.new("TextButton"); b.Name=name; b.Text=""; b.AutoButtonColor=false; b.LayoutOrder=order; b.BackgroundColor3=dark and Color3.new(0,0,0) or C.panel; b.Parent=parent; UI.corner(b,14)
 local g=Instance.new("UIGradient"); g.Rotation=90; g.Color=ColorSequence.new(dark and Color3.fromRGB(40,40,46) or Color3.fromRGB(70,86,128),dark and Color3.new(0,0,0) or C.background); g.Parent=b
 local s=Instance.new("UIStroke"); s.Name="Border"; s.Color=C.text; s.Thickness=1.5; s.Transparency=.85; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=b
 return b,s
end
local function refreshPicker()
 for slot,cardInfo in slotCards do
  local id=weapons.GetId(player,slot); local pending=player:GetAttribute("RiftPending"..slot)
  local active=slot==pickSlot
  cardInfo.stroke.Color=C.text; cardInfo.stroke.Thickness=active and 5 or 1.5; cardInfo.stroke.Transparency=active and 0 or .8
  cardInfo.button.BackgroundTransparency=active and 0 or .35
  local showId=pending or id
  if slotIcons[slot]~=showId then
   if cardInfo.icon then cardInfo.icon:Destroy() end
   cardInfo.icon=icon3D(cardInfo.button,showId,math.rad(-60),1.15); cardInfo.icon.Size=UDim2.new(1,-8,1,-26); cardInfo.icon.Position=UDim2.fromOffset(4,2); slotIcons[slot]=showId
  end
  cardInfo.next.Visible=pending~=nil
 end
 local equippedId=weapons.GetId(player,pickSlot); local pendingId=player:GetAttribute("RiftPending"..pickSlot)
 for id,tile in tiles do
  local visible=weapons.SlotOf(id)==pickSlot
  tile.button.Visible=visible
  if visible and not tile.view then
   local v=icon3D(tile.button,id,math.rad(-58),1.0); v.Size=UDim2.new(1.3,0,1.05,0); v.Position=UDim2.new(-.15,0,-.24,0); v.ZIndex=2; tile.view=v
  end
  local locked=not weapons.IsUnlocked(player,id)
  local current=id==pendingId or (id==equippedId and not pendingId)
  tile.lock.Visible=locked; tile.button.Active=true
  if tile.view then tile.view.ImageTransparency=locked and .55 or 0 end
  local _o,price,cur,discount
  if locked and visible then _o,price,cur,discount=offerFor(id) end
  tile.price.Visible=price~=nil
  if price then
   local can=balance(cur)>=price
   tile.price.Text=money(cur,price)..(discount and " "..pct(discount) or "")
   tile.price.BackgroundColor3=can and C.accent or C.danger; tile.price.TextColor3=can and C.background or C.text
  end
  tile.stroke.Color=current and C.accent or C.text; tile.stroke.Thickness=current and 4 or 1.5; tile.stroke.Transparency=current and 0 or .85
  tile.tag.Visible=current; tile.tag.Text=id==pendingId and "NEXT" or "✓"
 end
end
for slot,definition in ipairs(weapons.Slots) do
 local b,stroke=tileFrame(slotRow,definition.label,slot,true); b.Size=UDim2.fromOffset(104,104)
 local l=UI.text(b,definition.label,0,0,0,20,13,C.text,true); l.AnchorPoint=Vector2.new(.5,1); l.Position=UDim2.new(.5,0,1,-4); l.Size=UDim2.new(1,0,0,20); l.TextXAlignment=Enum.TextXAlignment.Center; l.TextSize=14; l.ZIndex=4
 local nxt=pill(b,"NEXT"); nxt.AnchorPoint=Vector2.new(.5,.5); nxt.Position=UDim2.new(.5,0,0,0); nxt.Visible=false
 b.Activated:Connect(function() pickSlot=slot; refreshPicker(); grid.CanvasPosition=Vector2.zero end)
 slotCards[slot]={button=b,stroke=stroke,next=nxt}
end
-- Random sits top-left of the grid: any unlocked weapon for the selected slot.
local random=tileFrame(grid,"Random",-1,true)
local shuffle=UI.text(random,"🔀",0,18,0,70,32); shuffle.Size=UDim2.new(1,0,0,70); shuffle.TextXAlignment=Enum.TextXAlignment.Center; shuffle.TextSize=54; shuffle.TextTransparency=.15
local rl=UI.text(random,"Random",0,0,0,30,28,C.text,true); rl.AnchorPoint=Vector2.new(.5,1); rl.Position=UDim2.new(.5,0,1,10); rl.Size=UDim2.new(1.2,0,0,30); rl.TextXAlignment=Enum.TextXAlignment.Center; rl.TextSize=24; rl.ZIndex=4
random.Activated:Connect(function()
 local options={}
 for _,id in weapons.Loadouts[weapons.Slots[pickSlot].category] do if weapons.IsUnlocked(player,id) and id~=weapons.GetId(player,pickSlot) then table.insert(options,id) end end
 if #options>0 then equip(options[math.random(#options)]) end
end)
for id,w in ipairs(weapons) do
 local b,stroke=tileFrame(grid,w.name,id,false); b.Visible=false
 local n=UI.text(b,w.short,0,0,0,30,28,C.text,true); n.AnchorPoint=Vector2.new(.5,1); n.Position=UDim2.new(.5,0,1,10); n.Size=UDim2.new(1.25,0,0,30); n.TextXAlignment=Enum.TextXAlignment.Center; n.TextScaled=true; n.ZIndex=4
 local limit=Instance.new("UITextSizeConstraint"); limit.MaxTextSize=24; limit.Parent=n
 local lock=UI.text(b,"🔒",0,0,0,40,32); lock.AnchorPoint=Vector2.new(.5,.5); lock.Position=UDim2.fromScale(.5,.45); lock.Size=UDim2.fromOffset(60,40); lock.TextXAlignment=Enum.TextXAlignment.Center; lock.TextSize=36; lock.Visible=false; lock.ZIndex=5
 local tag=pill(b,"✓"); tag.AnchorPoint=Vector2.new(1,0); tag.Position=UDim2.new(1,-6,0,6)
 local price=pill(b,""); price.AnchorPoint=Vector2.new(0,0); price.Position=UDim2.fromOffset(6,6); price.Visible=false
 b.Activated:Connect(function()
  if weapons.IsUnlocked(player,id) then equip(id)
  else local oid=offerFor(id); if oid and Prompt.Open then Prompt.Open(oid) end end -- locked: open ShopConfirm
 end)
 tiles[id]={button=b,stroke=stroke,lock=lock,tag=tag,price=price}
end

------------------------------------------------------------------ Screen wiring
-- changed() fires on every modal switch: only a real open resets state, not being uncovered after ShopConfirm (26).
Controller:Register("Arsenal",screen,22,function(visible)
 local wanted=Controller.screens.Arsenal.wanted
 if wanted and not arsenalWanted then
  activeCategory=weapons.SlotOf(selected) or 1; detailMode=nil; preview=nil; stripOpen=false
  local shop=Controller.screens.Shop
  if shop and shop.wanted then task.defer(function() Controller:Set("Shop",false) end) end -- deferred: Set is mid-loop here
  if Prompt.Refresh and not Prompt.Snapshot() then task.spawn(Prompt.Refresh) end
 elseif not wanted then preview=nil; stripOpen=false end
 arsenalWanted=wanted
 if visible then refreshRows(); refreshInfo(); refreshWallet() end
end)
Controller:Register("Loadout",picker,22,function(visible)
 blur.Parent=workspace.CurrentCamera; blur.Size=visible and 18 or 0
 if visible then refreshPicker() end
end)
for slot,definition in ipairs(weapons.Slots) do
 for _,attribute in {definition.attribute,"RiftPending"..slot} do
  player:GetAttributeChangedSignal(attribute):Connect(function()
   if Controller.active=="Arsenal" then refreshRows(); refreshInfo() end
   if Controller.active=="Loadout" then refreshPicker() end
  end)
 end
end
player:GetAttributeChangedSignal("RiftMap"):Connect(function() Controller:Set("Loadout",false) end)
-- Shop state: balances, ownership and equipped skins. Covered screens refresh when uncovered.
local queued=false
local function refreshAll()
 if queued then return end
 queued=true
 task.defer(function()
  queued=false
  if Controller.active=="Arsenal" then refreshRows(); refreshInfo(); refreshWallet() end
  if Controller.active=="Loadout" then refreshPicker() end
 end)
end
local function dropIcons() -- icons are keyed by weapon id, so rebuild them after a skin change
 for id,v in rowIcons do v:Destroy(); rowIcons[id]=nil end
 for slot in slotIcons do slotIcons[slot]=nil end
 for _,tile in tiles do if tile.view then tile.view:Destroy(); tile.view=nil end end
 modelKey=nil
end
player.AttributeChanged:Connect(function(name)
 if name=="RiftSkins" then dropIcons(); refreshAll()
 elseif name=="RiftShards" or name=="RiftCores" or name:sub(1,10)=="RiftLocked" then refreshAll()
 elseif name=="RiftProfileState" and Prompt.Refresh and not Prompt.Snapshot() then task.spawn(Prompt.Refresh) end
end)
if Prompt.Changed then Prompt.Changed:Connect(refreshAll) end
if Prompt.Refresh then task.spawn(Prompt.Refresh) end
-- Deep link from the Shop ("Preview in Arsenal"): RiftArsenalSelect:Fire(weaponId, styleId?)
local playerScripts=player:WaitForChild("PlayerScripts")
local selectEvent=playerScripts:FindFirstChild("RiftArsenalSelect") or Instance.new("BindableEvent")
selectEvent.Name="RiftArsenalSelect"; selectEvent.Parent=playerScripts
selectEvent.Event:Connect(function(id,style)
 id=tonumber(id); if not id or not weapons[id] then return end
 if Controller.screens.Shop then Controller:Set("Shop",false) end
 Controller:Set("Arsenal",true)
 selected=id; activeCategory=weapons.SlotOf(id) or 1; preview=nil
 if type(style)=="string" and Skins.Get(style) and Skins.Allowed(id) then
  stripOpen=true; detailMode=nil
  if style~=(equippedStyle(id) or false) then preview=style end
 end
 listFrame.CanvasPosition=Vector2.zero
 refreshRows(); refreshInfo()
end)
run.RenderStepped:Connect(function(dt)
 if Controller.active~="Arsenal" or not model then return end
 if not dragging and os.clock()-lastDrag>2 then yaw+=dt*.45 end
 local bob=math.sin(os.clock()*1.6)*.18
 model:PivotTo(CFrame.new(0,1.1+bob,0)*CFrame.Angles(0,yaw,0)*CFrame.Angles(0,0,pitch)*modelOffset)
end)
