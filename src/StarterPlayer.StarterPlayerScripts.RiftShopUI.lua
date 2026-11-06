-- RiftShopUI: lobby Shop (Home | Bundles | Skins | Daily | Keys), currency bar, end-of-match payout panel and in-match "+N" tally.
-- Display only: every buy goes through RiftPurchasePrompt.Open(offerId); the server resolves every price.
-- Views are built from RiftShopCatalog + player attributes; the RiftShop snapshot is only an overlay (owned skins, daily streak).
local player=game.Players.LocalPlayer
local run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Http=game:GetService("HttpService")
local storage=game.ReplicatedStorage
local weapons=require(storage:WaitForChild("RiftWeapons"))
local Models=require(storage:WaitForChild("RiftWeaponModels"))
local Cat=require(storage:WaitForChild("RiftShopCatalog"))
local S=require(storage:WaitForChild("RiftSkins"))
local Config=require(storage:WaitForChild("RiftEconomyConfig"))
local UI=require(storage:WaitForChild("RiftUI"))
local Controller=require(storage:WaitForChild("RiftUIController"))
local Audio=require(storage:WaitForChild("RiftAudio"))
local Prompt=require(storage:WaitForChild("RiftPurchasePrompt")) -- first requirer: also activates the ShopConfirm view and lobby "offer" events
local Sync=storage:WaitForChild("RiftShopSync")
if not Prompt.Open then return end -- helpers-only build (not a running client)
local C=UI.C
local Format,Glyph,Color=Prompt.Format,Prompt.Glyph,Prompt.Color
local DIM,GOLD,CYAN,EYE=Color3.fromRGB(138,147,168),Color3.fromRGB(255,196,64),Color3.fromRGB(64,220,255),Color3.fromRGB(20,150,255)
local PER_MATCH=Config.SHARDS_PER_MATCH_ESTIMATE or 170
local PAGE_SIZE=24

------------------------------------------------------------------ data
local snap=Prompt.Snapshot
local function serverNow() return math.floor(workspace:GetServerTimeNow()) end
local function today() return Cat.Today(serverNow()) end
local function profileState() return player:GetAttribute("RiftProfileState") or Prompt.State.state end
local function canSpend() local st=profileState() return st=="ready" or st=="nosave" end
local function balance(cur)
 local a=player:GetAttribute(cur=="cores" and "RiftCores" or "RiftShards")
 if tonumber(a) then return a end
 local s=snap(); return s and tonumber(s[cur=="cores" and "cores" or "shards"]) or 0
end
local function ownsWeapon(id)
 if Cat.IsStarter(id) then return true end
 if player:GetAttribute("RiftLocked"..id)==true then return false end
 local s=snap()
 if s and s.ownedWeapons then return s.ownedWeapons[tostring(id)]==true end
 local st=profileState(); return st=="ready" or st=="nosave" or st=="readonly" -- Mirror ran, no lock attribute
end
local function ownsSkin(id,style) local s=snap(); return s~=nil and s.ownedSkins~=nil and s.ownedSkins[S.Key(id,style)]==true end
local skinRaw,skinMap=false,{}
local function equippedStyle(id)
 if id==21 then return nil end
 local raw=player:GetAttribute("RiftSkins")
 if raw~=skinRaw then
  skinRaw=raw
  local ok,t=pcall(function() return Http:JSONDecode(raw or "{}") end)
  skinMap=ok and type(t)=="table" and t or {}
 end
 if raw==nil then local s=snap(); return s and s.equippedSkins and s.equippedSkins[tostring(id)] or nil end
 return skinMap[tostring(id)]
end
local dailyDay,dailyOffers
local function daily()
 local d=today()
 if d~=dailyDay then dailyDay=d; dailyOffers=Cat.Daily(d) end
 return dailyOffers,d
end
local function nextUnlock() -- cheapest locked weapon
 local best,bestPrice
 for id,price in Cat.WEAPON_PRICES do
  if weapons[id] and not Cat.IsStarter(id) and not ownsWeapon(id) and (not bestPrice or price<bestPrice or (price==bestPrice and id<best)) then best,bestPrice=id,price end
 end
 return best,bestPrice
end
local function matchesFor(need) return math.max(1,math.ceil(need/PER_MATCH)) end
local function matchText(need) local n=matchesFor(need) return "~"..n.." match"..(n==1 and "" or "es") end
local function keyOffer(id) -- today's slot-5 deal is always the cheaper way to unlock that weapon
 local d=daily()[5]
 if d and d.weapon==id then return d.id end
 return "w:"..id
end
local function tierColor(style) local st=S.Get(style); return st and (S.TIERS[st.tier] or S.TIERS.Standard).color or CYAN end
local function slotLabel(id) local slot=weapons.SlotOf(id); return slot and weapons.Slots[slot].label or "" end
local function hex(c) return "#"..c:ToHex() end
local function priceRich(cur,price,list)
 local s=string.format('<font color="%s">%s</font> %s',hex(Color(cur)),Glyph(cur),Format(price))
 if list and list>price then s=string.format('<font color="%s"><s>%s</s></font>  ',hex(DIM),Format(list))..s end
 return s
end
local function clock(secs)
 secs=math.max(0,math.floor(secs))
 return string.format("%02d:%02d:%02d",secs//3600,(secs%3600)//60,secs%60)
end
local function streakInfo() -- done = days ticked in the current 7-day cycle, nextDay = the day CLAIM pays
 local s=snap(); local d=s and s.daily
 if not d then return nil end
 local streak=tonumber(d.streak) or 0
 local claimable=d.canClaim==true
 local done=claimable and streak%7 or (streak<=0 and 0 or (streak-1)%7+1)
 return {streak=streak,canClaim=claimable,done=done,nextDay=claimable and streak%7+1 or done%7+1,reward=d.nextReward}
end
local function rewardRich(r,day)
 local sh=r and tonumber(r.shards) or (Config.STREAK[day] and Config.STREAK[day][1]) or 0
 local co=r and tonumber(r.cores) or (Config.STREAK[day] and Config.STREAK[day][2]) or 0
 local s=string.format('<font color="%s">%s</font> %s',hex(Color("shards")),Glyph("shards"),Format(sh))
 if co>0 then s..=string.format('  <font color="%s">%s</font> %s',hex(Color("cores")),Glyph("cores"),Format(co)) end
 return s
end

------------------------------------------------------------------ UI helpers
local function label(parent,text,x,y,w,h,size,color,bold,textSize)
 local t=UI.text(parent,text,x,y,w,h,size,color,bold); if textSize then t.TextSize=textSize end; return t
end
local function pill(parent,text,color,textColor)
 local p=Instance.new("TextLabel"); p.Name="Pill"; p.Text=text; p.Font=UI.Font.display; p.TextSize=13; p.TextColor3=textColor or C.background
 p.BackgroundColor3=color or C.accent; p.AutomaticSize=Enum.AutomaticSize.X; p.Size=UDim2.fromOffset(0,22); p.ZIndex=6; p.Parent=parent; UI.corner(p,11)
 local pad=Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,9); pad.PaddingRight=UDim.new(0,9); pad.Parent=p
 return p
end
local function panelCard(parent,name,x,y,w,h,button)
 local f=Instance.new(button and "TextButton" or "Frame"); f.Name=name; f.Position=UDim2.fromOffset(x,y); f.Size=UDim2.fromOffset(w,h)
 f.BackgroundColor3=C.background; f.BackgroundTransparency=.22; f.BorderSizePixel=0; f.Parent=parent; UI.corner(f,14)
 local s=Instance.new("UIStroke"); s.Name="Border"; s.Color=C.text; s.Transparency=.88; s.Thickness=1.5; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=f
 f:SetAttribute("Base",.88)
 if button then
  f.Text=""; f.AutoButtonColor=false
  f.MouseEnter:Connect(function() s.Transparency=math.min(f:GetAttribute("Base") or .88,.45) end)
  f.MouseLeave:Connect(function() s.Transparency=f:GetAttribute("Base") or .88 end)
 end
 return f,s
end
local function setBase(f,s,t) f:SetAttribute("Base",t); s.Transparency=t end
local function tierStrip(f,w,color) local t=UI.frame(f,"Tier",12,0,w-24,5,color); UI.corner(t,3); return t end
local function setActive(b,on) b.Active=on; b.BackgroundTransparency=on and 0 or .45; b.TextTransparency=on and 0 or .3 end
local function eyeButton(parent,x,y,callback)
 local b=Instance.new("TextButton"); b.Name="Preview"; b.Text="👁"; b.Font=UI.Font.display; b.TextSize=18; b.TextColor3=C.text; b.AutoButtonColor=false
 b.Position=UDim2.fromOffset(x,y); b.Size=UDim2.fromOffset(40,28); b.BackgroundColor3=EYE; b.ZIndex=6; b.Parent=parent; UI.corner(b,8); UI.shade(b,.22)
 b.Activated:Connect(callback)
 return b
end
-- Static 3D icon of a weapon (optionally skinned).
local function modelView(parent,id,style,zoom,yaw)
 local v=Instance.new("ViewportFrame"); v.Name="View"; v.BackgroundTransparency=1; v.Size=UDim2.fromScale(1,1)
 v.Ambient=Color3.fromRGB(175,182,200); v.LightColor=Color3.new(1,1,1); v.LightDirection=Vector3.new(-1,-1.4,-.8); v.Parent=parent
 local cam=Instance.new("Camera"); cam.FieldOfView=30; cam.Parent=v; v.CurrentCamera=cam
 local w=weapons[id]; if not w then return v end
 local ok,m=pcall(Models.create,w,style and S.Model(style) or nil)
 if not ok or not m then return v end
 m:PivotTo(CFrame.new())
 if id==21 then pcall(Models.recolorFists,m,player) end
 local cf,size=m:GetBoundingBox()
 cam.CFrame=CFrame.new(cf.Position)*CFrame.Angles(0,yaw or math.rad(-62),0)*CFrame.Angles(-.18,0,0)*CFrame.new(0,0,math.max(size.Magnitude,1.2)*(zoom or 1.2))
 m.Parent=v
 return v
end
-- Price badge (bottom-right) + "Need X more" line. Returns set(cur,price,list) / set(nil,nil,nil,text), badge, need.
local function priceBadge(parent)
 local b=Instance.new("TextLabel"); b.Name="Price"; b.RichText=true; b.Font=UI.Font.display; b.TextSize=18; b.TextColor3=C.text; b.BackgroundColor3=C.panel
 b.AnchorPoint=Vector2.new(1,1); b.Position=UDim2.new(1,-8,1,-8); b.AutomaticSize=Enum.AutomaticSize.X; b.Size=UDim2.fromOffset(0,28); b.ZIndex=5; b.Parent=parent; UI.corner(b,8)
 local pad=Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,8); pad.PaddingRight=UDim.new(0,8); pad.Parent=b
 local need=Instance.new("TextLabel"); need.Name="Need"; need.BackgroundTransparency=1; need.Font=UI.Font.bold; need.TextSize=12; need.TextColor3=C.danger; need.Text=""
 need.TextXAlignment=Enum.TextXAlignment.Right; need.AnchorPoint=Vector2.new(1,1); need.Position=UDim2.new(1,-10,1,-38); need.Size=UDim2.fromOffset(160,14); need.ZIndex=5; need.Parent=parent
 return function(cur,price,list,text)
  if text then b.Text=text; b.TextTransparency=0; b.BackgroundTransparency=0; need.Text=""; return end
  local short=price-balance(cur)
  b.Text=priceRich(cur,price,list); b.TextTransparency=short>0 and .4 or 0; b.BackgroundTransparency=short>0 and .55 or 0
  need.Text=short>0 and ("Need "..Format(short).." more") or ""
 end,b,need
end

------------------------------------------------------------------ screen
local gui=Instance.new("ScreenGui"); gui.Name="RiftShopUI"; gui.ResetOnSpawn=false; gui.DisplayOrder=34; gui.IgnoreGuiInset=true; gui.Parent=player:WaitForChild("PlayerGui")
local screen=Instance.new("CanvasGroup"); screen.Name="ShopScreen"; screen.Size=UDim2.fromScale(1,1); screen.BackgroundColor3=C.panel; screen.Parent=gui
local sky=Instance.new("UIGradient"); sky.Rotation=90; sky.Color=ColorSequence.new(Color3.fromRGB(46,60,96),C.background); sky.Parent=screen
local root=UI.frame(screen,"Root",0,0,1200,700); root.AnchorPoint=Vector2.new(.5,.5); root.Position=UDim2.new(.5,0,.5,24); root.BackgroundTransparency=1
local rootScale=Instance.new("UIScale"); rootScale.Parent=root
local function fit()
 local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 rootScale.Scale=math.clamp(math.min(v.X/1240,(v.Y-64)/710),.3,1.25)
end
local shopVisible,current=false,"Home"
local showTab,markDirty -- forward declarations

-- toast
local toastLabel=label(root,"",0,0,700,40,16,C.text,true,18); toastLabel.AnchorPoint=Vector2.new(.5,1); toastLabel.Position=UDim2.new(.5,0,1,-8); toastLabel.TextXAlignment=Enum.TextXAlignment.Center
toastLabel.BackgroundColor3=C.background; toastLabel.BackgroundTransparency=.1; toastLabel.ZIndex=40; toastLabel.Visible=false; UI.corner(toastLabel,12)
local toastGen=0
local function toast(text,color)
 toastGen+=1; local gen=toastGen
 toastLabel.Text=text; toastLabel.TextColor3=color or C.text; toastLabel.Visible=true
 task.delay(2.6,function() if gen==toastGen then toastLabel.Visible=false end end)
end

-- Preview in Arsenal: BindableEvent RiftArsenalSelect(weaponId, styleOrNil) under PlayerScripts.
local function selectEvents()
 local ps=player:FindFirstChild("PlayerScripts") or player:WaitForChild("PlayerScripts",5)
 if not ps then return {} end
 local list={}
 for _,c in ps:GetChildren() do if c.Name=="RiftArsenalSelect" and c:IsA("BindableEvent") then table.insert(list,c) end end
 if #list==0 then local e=Instance.new("BindableEvent"); e.Name="RiftArsenalSelect"; e.Parent=ps; list[1]=e end
 return list
end
task.spawn(selectEvents) -- create early so RiftArsenal can connect
local function previewInArsenal(id,style)
 if not Controller.screens.Arsenal then toast("Arsenal is still loading",C.danger) return end
 local events=selectEvents()
 Controller:Set("Shop",false)
 if Controller.screens.Loadout then Controller:Set("Loadout",false) end
 Controller:Set("Arsenal",true)
 for _,e in events do e:Fire(id,style) end
end
local function equipSkin(id,style)
 task.spawn(function()
  local res=Prompt.EquipSkin(id,style or false)
  if res.ok then
   Audio.Play("equip")
   local st=style and S.Get(style)
   toast((st and (st.name.." equipped on ") or "Default finish on ")..weapons[id].name,C.success)
  else
   toast(res.code=="NOT_OWNED" and "You don't own that skin yet" or (not canSpend() and "View only - skins can't change right now" or "Couldn't equip - try again"),C.danger)
  end
  markDirty()
 end)
end
local claiming=false
local function claim()
 if claiming then return end
 local info=streakInfo()
 if not info or not info.canClaim or not canSpend() then return end
 claiming=true
 task.spawn(function()
  local res=Prompt.ClaimDaily()
  claiming=false
  if res.ok then
   UI.reward()
   local r=type(res.reward)=="table" and res.reward or {}
   toast("Daily reward: +"..Format(r.shards or 0).." Shards"..((tonumber(r.cores) or 0)>0 and (" +"..r.cores.." Cores") or ""),C.success)
  else
   toast(res.code=="ALREADY_CLAIMED" and "Already claimed - come back tomorrow" or ((res.code=="RATE" or res.code=="BUSY") and "Try again in a moment" or "Couldn't claim - try again"),C.danger)
  end
  markDirty()
 end)
end

------------------------------------------------------------------ header: title, currency pills, status chip, close
label(root,"SHOP",0,0,240,52,32,C.text,true,40)
local function float(parent,text,color)
 local f=label(parent,text,44,0,120,30,20,color,true,22); f.ZIndex=8; UI.outline(f,2)
 Tween:Create(f,TweenInfo.new(.9,Enum.EasingStyle.Quad),{Position=UDim2.fromOffset(44,-34),TextTransparency=1}):Play()
 local s=f:FindFirstChild("TextOutline"); if s then Tween:Create(s,TweenInfo.new(.9),{Transparency=1}):Play() end
 task.delay(.95,function() f:Destroy() end)
end
local function currencyPill(cur,x,w)
 local f=UI.frame(root,cur=="cores" and "Cores" or "Shards",x,4,w,46,C.background); f.BackgroundTransparency=.2; UI.corner(f,23)
 local s=Instance.new("UIStroke"); s.Color=Color(cur); s.Transparency=.5; s.Thickness=1.5; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=f
 local g=label(f,Glyph(cur),8,0,34,46,20,Color(cur),true,26); g.TextXAlignment=Enum.TextXAlignment.Center
 local amount=label(f,"0",44,0,w-96,46,20,C.text,true,22)
 local plus=UI.button(f,"+",w-46,1,44,44,function() Prompt.HowToEarn() end,true); plus.TextSize=24; UI.corner(plus,22)
 local value=Instance.new("NumberValue"); value.Value=balance(cur)
 amount.Text=Format(value.Value)
 value.Changed:Connect(function(v) amount.Text=Format(v) end)
 local tween,target=nil,value.Value
 return function(n,animate)
  if n==target then return end
  target=n
  if tween then tween:Cancel(); tween=nil end
  local from=value.Value
  if animate and n>from then
   tween=Tween:Create(value,TweenInfo.new(.4,Enum.EasingStyle.Quad),{Value=n}); tween:Play()
   float(f,"+"..Format(n-math.floor(from+.5)),Color(cur))
  else value.Value=n end
 end
end
local setShards=currencyPill("shards",612,190)
local setCores=currencyPill("cores",812,150)
local chip=label(root,"",972,8,150,38,13,C.text,true,14); chip.TextXAlignment=Enum.TextXAlignment.Center; chip.BackgroundColor3=C.panel; chip.BackgroundTransparency=.1; UI.corner(chip,19)
local closeButton=Instance.new("TextButton"); closeButton.Name="Close"; closeButton.Text="✖"; closeButton.Font=UI.Font.display; closeButton.TextSize=26; closeButton.TextColor3=C.text; closeButton.AutoButtonColor=false
closeButton.Position=UDim2.fromOffset(1130,4); closeButton.Size=UDim2.fromOffset(70,46); closeButton.BackgroundColor3=C.danger; closeButton.Parent=root; UI.corner(closeButton,10); UI.shade(closeButton,.22)
closeButton.Activated:Connect(function() Controller:Set("Shop",false) end)
local banner=UI.frame(root,"Banner",820,62,380,46,C.danger); banner.BackgroundTransparency=.2; UI.corner(banner,10); banner.Visible=false
local bannerText=label(banner,"",12,0,356,46,13,C.text,true,14); bannerText.TextWrapped=true
local STATE_CHIP={ready={"✓ Saved",C.success},nosave={"Studio: saves off",GOLD},offline={"Offline",C.danger},readonly={"View only",C.danger},loading={"Loading...",DIM}}
local function refreshHeader()
 local st=profileState() or "loading"
 local c=STATE_CHIP[st] or STATE_CHIP.loading
 chip.Text=c[1]; chip.TextColor3=c[2]
 local msg
 if st=="offline" then msg=Prompt.State.msg or "Progress offline - rejoin to save. The Shop is view-only."
 elseif st=="readonly" then msg="View only - your profile is open in another server."
 elseif st=="loading" then msg="Loading your profile..." end
 banner.Visible=msg~=nil; bannerText.Text=msg or ""
end

------------------------------------------------------------------ tabs + pages
local TABS={"Home","Bundles","Skins","Daily","Keys"}
local tabButtons,tabDots,pages={},{},{}
for i,name in TABS do
 local b=UI.button(root,name,(i-1)*158,62,150,46,function() showTab(name) end); b.TextSize=18
 local dot=UI.frame(b,"Dot",0,0,12,12,C.danger); dot.AnchorPoint=Vector2.new(.5,.5); dot.Position=UDim2.new(1,-10,0,10); dot.ZIndex=5; dot.Visible=false; UI.corner(dot,6)
 tabButtons[name]=b; tabDots[name]=dot
 local page=UI.frame(root,name.."Page",0,122,1200,578); page.BackgroundTransparency=1; page.Visible=false
 pages[name]=page
end
local P={} -- name -> {build(updates), key()->string, built, updates}
local function render(force)
 local p=P[current]; if not p then return end
 local key=p.key()
 if force or p.built~=key then
  p.built=key; p.updates={}
  p.build(p.updates)
 end
 for _,fn in p.updates do fn() end
end
local function clearChildren(frame,keep)
 for _,c in frame:GetChildren() do if not (keep and keep[c]) then c:Destroy() end end
end

-- Item card: tier strip, 3D view, name + weapon line, price badge (dimmed + "Need X more"), discount ribbon, OWNED/EQUIPPED pill.
-- e={kind="skin"|"weapon"|"default", weapon, style?, offer, title, sub, color, w, h, order, zoom}
local function itemCard(parent,e,updates)
 local w,h=e.w,e.h
 local f,stroke=panelCard(parent,e.title,0,0,w,h,true); f.LayoutOrder=e.order or 0
 tierStrip(f,w,e.color or CYAN)
 local holder=UI.frame(f,"Stage",6,12,w-12,h-104); holder.BackgroundTransparency=1
 modelView(holder,e.weapon,e.style or (e.kind=="weapon" and equippedStyle(e.weapon)) or nil,e.zoom)
 local name=label(f,e.title,12,h-90,w-24,22,16,C.text,true,17); name.TextTruncate=Enum.TextTruncate.AtEnd
 local sub=label(f,e.sub or "",12,h-68,w-24,16,13,DIM,false,12); sub.TextTruncate=Enum.TextTruncate.AtEnd
 local setPrice=priceBadge(f)
 local ribbon=pill(f,"",C.danger,C.text); ribbon.Position=UDim2.fromOffset(10,12); ribbon.Visible=false
 local tag=pill(f,"OWNED",C.success); tag.AnchorPoint=Vector2.new(1,0); tag.Position=UDim2.new(1,-10,0,12); tag.Visible=false
 if e.kind~="default" then eyeButton(f,8,h-36,function() previewInArsenal(e.weapon,e.style) end) end
 local status={}
 local function update()
  local owned,equipped
  if e.kind=="default" then owned=true; equipped=equippedStyle(e.weapon)==nil
  elseif e.kind=="weapon" then owned=ownsWeapon(e.weapon)
  else owned=ownsSkin(e.weapon,e.style); equipped=owned and equippedStyle(e.weapon)==e.style end
  status.owned,status.equipped=owned,equipped
  tag.Visible=owned and e.kind~="default" or (e.kind=="default" and equipped)
  tag.Text=equipped and "EQUIPPED" or "OWNED"; tag.BackgroundColor3=equipped and C.accent or C.success
  stroke.Color=equipped and C.accent or C.text; setBase(f,stroke,equipped and .1 or .88)
  if owned then
   ribbon.Visible=false
   setPrice(nil,nil,nil,e.kind=="weapon" and "✓ Unlocked" or (equipped and "✓ Equipped" or "Equip"))
   return
  end
  local offer,code=Prompt.Resolve(e.offer)
  if not offer then
   ribbon.Visible=false; setPrice(nil,nil,nil,code=="ALREADY_OWNED" and "✓ Owned" or (code=="OFFER_EXPIRED" and "Ended" or "Unavailable")); return
  end
  local off=offer.discount or 0
  ribbon.Visible=off>0; ribbon.Text="-"..math.floor(off*100+.5).."%"
  setPrice(offer.cur,offer.price,offer.list)
 end
 f.Activated:Connect(function()
  if status.owned then
   if e.kind=="weapon" then previewInArsenal(e.weapon,nil)
   elseif not status.equipped then equipSkin(e.weapon,e.style) end
  else Prompt.Open(e.offer) end
 end)
 table.insert(updates,update)
 return f
end
local function dailyEntry(d,w,h,order)
 if d.kind=="weapon" then
  return {kind="weapon",weapon=d.weapon,offer=d.id,title=weapons[d.weapon].name,sub="Weapon key · "..slotLabel(d.weapon),color=CYAN,w=w,h=h,order=order}
 end
 local st=S.Get(d.style)
 return {kind="skin",weapon=d.weapon,style=d.style,offer=d.id,title=st and st.name or d.style,sub=(d.spotlight and "Spotlight · " or "")..weapons[d.weapon].name,color=tierColor(d.style),w=w,h=h,order=order}
end

------------------------------------------------------------------ HOME
local feat={} -- featured viewport state {view,cam,model,rel,items,index,switchAt,yaw}
local claimTile -- pulses when claimable
local function featShow(i)
 local it=feat.items and feat.items[i]; if not it or not feat.view then return end
 feat.index=i
 if feat.model then feat.model:Destroy(); feat.model=nil end
 local w=weapons[it.weapon]; if not w then return end
 local ok,m=pcall(Models.create,w,it.style and S.Model(it.style) or nil)
 if not ok or not m then return end
 m:PivotTo(CFrame.new())
 local cf,size=m:GetBoundingBox()
 feat.rel=CFrame.new(cf.Position):Inverse()*m:GetPivot()
 local dist=math.max(size.Magnitude,1.2)*1.7
 feat.cam.CFrame=CFrame.lookAt(Vector3.new(0,dist*.16,dist),Vector3.zero)
 m.Parent=feat.view; feat.model=m
 if feat.itemName then feat.itemName.Text=#feat.items>1 and (i.."/"..#feat.items.."  "..(it.style and ((S.Get(it.style) and S.Get(it.style).name or "").." ") or "")..w.name) or "" end
end
local function featuredPick(day)
 if day%2==1 then
  local b=Cat.BUNDLES[(day//7)%#Cat.BUNDLES+1]
  local offer=b and Prompt.Resolve("b:"..b.id)
  if offer then return {bundle=b} end
 end
 return {daily=daily()[6]}
end
P.Home={key=function() local _,d=daily() return tostring(d) end,build=function(updates)
 local page=pages.Home; clearChildren(page)
 feat.model=nil; feat.view=nil
 local _,day=daily()
 local pick=featuredPick(day)
 -- featured panel (left ~60%)
 local fp=panelCard(page,"Featured",0,0,700,578,false); fp.BackgroundColor3=C.panel; fp.BackgroundTransparency=.15
 local fg=Instance.new("UIGradient"); fg.Rotation=90; fg.Color=ColorSequence.new(Color3.fromRGB(46,60,96),C.background); fg.Parent=fp
 local color,kindText,title,sub,offerId,items
 if pick.bundle then
  local b=pick.bundle
  color,kindText,title,offerId=GOLD,"FEATURED BUNDLE",b.name,"b:"..b.id
  local names={}; items={}
  for _,it in b.items do
   if it[1]=="w" then table.insert(items,{weapon=it[2],style=equippedStyle(it[2])}); table.insert(names,weapons[it[2]].name)
   else local st=S.Get(it[3]); table.insert(items,{weapon=it[2],style=it[3]}); table.insert(names,(st and st.name or it[3]).." "..weapons[it[2]].short) end
  end
  sub=table.concat(names," + ")
 else
  local d=pick.daily; local st=S.Get(d.style)
  color,kindText,offerId=tierColor(d.style),"TODAY'S SPOTLIGHT · "..((st and st.tier or "Elite"):upper()).." SKIN",d.id
  title=(st and st.name or d.style).." · "..weapons[d.weapon].name; sub="Skin for "..weapons[d.weapon].name.." · cosmetic only"
  items={{weapon=d.weapon,style=d.style,skin=true}}
 end
 tierStrip(fp,700,color)
 local stage=UI.frame(fp,"Stage",0,36,700,394); stage.BackgroundTransparency=1
 local view=Instance.new("ViewportFrame"); view.BackgroundTransparency=1; view.Size=UDim2.fromScale(1,1); view.Ambient=Color3.fromRGB(175,182,200); view.LightColor=Color3.new(1,1,1); view.LightDirection=Vector3.new(-1,-1.4,-.8); view.Parent=stage
 local cam=Instance.new("Camera"); cam.FieldOfView=30; cam.Parent=view; view.CurrentCamera=cam
 local kind=label(fp,kindText,24,14,460,22,13,color,true,14); UI.outline(kind,1.5)
 local ribbon=pill(fp,"",C.danger,C.text); ribbon.AnchorPoint=Vector2.new(1,0); ribbon.Position=UDim2.new(1,-20,0,16); ribbon.TextSize=16; ribbon.Size=UDim2.fromOffset(0,28); ribbon.Visible=false
 local itemName=label(fp,"",24,400,500,20,13,DIM,false,13)
 local titleLabel=label(fp,title,24,428,420,44,32,C.text,true,30); titleLabel.TextScaled=true
 local tl=Instance.new("UITextSizeConstraint"); tl.MaxTextSize=30; tl.Parent=titleLabel
 local subLabel=label(fp,sub,24,472,420,30,13,DIM,false,13); subLabel.TextWrapped=true; subLabel.TextYAlignment=Enum.TextYAlignment.Top
 local price=label(fp,"",440,428,236,40,28,C.text,true,26); price.RichText=true; price.TextXAlignment=Enum.TextXAlignment.Right
 local need=label(fp,"",440,470,236,18,13,C.danger,false,13); need.TextXAlignment=Enum.TextXAlignment.Right
 local preview=UI.button(fp,"PREVIEW IN ARSENAL",24,508,280,52,function()
  local it=feat.items and feat.items[feat.index or 1]; if it then previewInArsenal(it.weapon,it.style) end
 end)
 preview.TextSize=16
 local buyState={}
 local buy=UI.button(fp,"BUY",436,508,240,52,function()
  if buyState.equip then local it=items[1]; equipSkin(it.weapon,it.style)
  elseif buyState.open then Prompt.Open(offerId) end
 end,true)
 buy.TextSize=20
 feat.view,feat.cam,feat.items,feat.itemName,feat.yaw,feat.switchAt=view,cam,items,itemName,math.rad(-40),os.clock()+3.2
 featShow(1)
 table.insert(updates,function()
  local offer,code=Prompt.Resolve(offerId)
  buyState.equip,buyState.open=false,false
  if offer then
   local off=offer.discount or 0
   ribbon.Visible=off>0; ribbon.Text="-"..math.floor(off*100+.5).."%"
   price.Text=priceRich(offer.cur,offer.price,offer.list)
   local short=offer.price-balance(offer.cur)
   price.TextTransparency=short>0 and .35 or 0
   need.Text=short>0 and ("Need "..Format(short).." more · "..matchText(short)) or ""
   buy.Text=short>0 and "VIEW OFFER" or "BUY"; buyState.open=true; setActive(buy,true)
  else
   ribbon.Visible=false; need.Text=""
   local owned=code=="ALREADY_OWNED"
   price.Text=owned and "OWNED" or "Ended"; price.TextTransparency=0
   local it=items[1]
   if owned and pick.daily and equippedStyle(it.weapon)~=it.style then buy.Text="EQUIP"; buyState.equip=true; setActive(buy,true)
   else buy.Text=owned and (pick.daily and "EQUIPPED" or "OWNED") or "ENDED"; setActive(buy,false) end
  end
 end)
 -- NEXT UNLOCK goal card
 local nc,ns=panelCard(page,"NextUnlock",716,0,484,140,true)
 label(nc,"NEXT UNLOCK",16,10,200,18,13,C.accent,true,13)
 local ncName=label(nc,"",16,30,300,30,20,C.text,true,22); ncName.TextTruncate=Enum.TextTruncate.AtEnd
 local ncProg=label(nc,"",16,62,300,22,16,C.text,true,17); ncProg.RichText=true
 local ncStage=UI.frame(nc,"Stage",314,6,164,92); ncStage.BackgroundTransparency=1
 local track=UI.frame(nc,"Track",16,96,452,12,C.panel); UI.corner(track,6)
 local fill=UI.frame(track,"Fill",0,0,0,12,C.accent); fill.Size=UDim2.fromScale(0,1); UI.corner(fill,6); UI.shade(fill,.25)
 local ncEta=label(nc,"",16,112,452,22,13,DIM,false,13)
 local ncId=false
 nc.Activated:Connect(function() if ncId then Prompt.Open(keyOffer(ncId)) end end)
 table.insert(updates,function()
  local id,priceN=nextUnlock()
  if id~=ncId then ncId=id or false; clearChildren(ncStage); if id then modelView(ncStage,id,equippedStyle(id),1.05) end end
  if not id then
   ncName.Text="Arsenal complete"; ncProg.Text="Every weapon unlocked"; fill.Size=UDim2.fromScale(1,1); ncEta.Text="Skins and the Core Vault are next."; return
  end
  local bal=balance("shards")
  ncName.Text=weapons[id].name
  ncProg.Text=string.format('<font color="%s">%s</font> %s / %s',hex(Color("shards")),Glyph("shards"),Format(math.min(bal,priceN)),Format(priceN))
  fill.Size=UDim2.fromScale(math.clamp(bal/priceN,0,1),1)
  fill.BackgroundColor3=bal>=priceN and C.success or C.accent
  ncEta.Text=bal>=priceN and "Ready to unlock - tap to buy" or (matchText(priceN-bal).." · "..slotLabel(id))
 end)
 -- first 3 daily offers
 label(page,"TODAY'S DEALS",716,148,300,24,20,C.text,true,20)
 local seeAll=Instance.new("TextButton"); seeAll.Text="See all ›"; seeAll.Font=UI.Font.bold; seeAll.TextSize=16; seeAll.TextColor3=C.accent; seeAll.BackgroundTransparency=1
 seeAll.TextXAlignment=Enum.TextXAlignment.Right; seeAll.Position=UDim2.fromOffset(1080,142); seeAll.Size=UDim2.fromOffset(120,36); seeAll.Parent=page
 seeAll.Activated:Connect(function() showTab("Daily") end)
 local offers=daily()
 for i=1,3 do
  local f=itemCard(page,dailyEntry(offers[i],154,236,i),updates); f.Position=UDim2.fromOffset(716+(i-1)*165,178)
 end
 -- claim tile
 local ct,cs=panelCard(page,"Claim",716,426,484,152,false); claimTile=ct
 local pulse=Instance.new("UIScale"); pulse.Name="Pulse"; pulse.Parent=ct
 label(ct,"DAILY REWARD",16,12,200,18,13,C.accent,true,13)
 local ctDay=label(ct,"",16,32,290,30,20,C.text,true,22)
 local ctReward=label(ct,"",16,64,290,34,28,C.text,true,26); ctReward.RichText=true
 local ctSub=label(ct,"",16,100,290,40,13,DIM,false,12); ctSub.TextWrapped=true; ctSub.TextYAlignment=Enum.TextYAlignment.Top
 local ctButton=UI.button(ct,"CLAIM",318,48,150,56,claim,true); ctButton.TextSize=22
 table.insert(updates,function()
  local info=streakInfo()
  if not info then
   ctDay.Text="Daily streak"; ctReward.Text=rewardRich(nil,1); ctSub.Text=canSpend() and "Loading your streak..." or "Available once your profile loads."
   ctButton.Text="CLAIM"; setActive(ctButton,false); cs.Color=C.text; return
  end
  ctDay.Text=info.canClaim and ("Day "..info.nextDay.." of 7") or ("Tomorrow: day "..info.nextDay)
  ctReward.Text=rewardRich(info.reward,info.nextDay)
  ctSub.Text=info.canClaim and "Claim every day - miss two and the streak resets." or (info.streak.." day streak · come back after the reset")
  local ready=info.canClaim and canSpend()
  ctButton.Text=info.canClaim and "CLAIM" or "CLAIMED"; setActive(ctButton,ready)
  cs.Color=ready and C.accent or C.text; cs.Transparency=ready and .2 or .88
 end)
end}

------------------------------------------------------------------ BUNDLES
local bundlesSeen=false
local function bundleCard(parent,b,order,updates)
 local W,H=1176,176
 local f=panelCard(parent,b.name,0,0,W,H,false); f.LayoutOrder=order
 tierStrip(f,W,GOLD)
 local thumbs,names={},{}
 for i,it in b.items do
  if i>3 then break end
  local id,style=it[2],it[1]=="s" and it[3] or nil
  local st=style and S.Get(style)
  local t=UI.frame(f,"Item"..i,16+(i-1)*162,18,150,142,C.panel); t.BackgroundTransparency=.4; UI.corner(t,12)
  local holder=UI.frame(t,"Stage",0,0,150,100); holder.BackgroundTransparency=1
  modelView(holder,id,style or equippedStyle(id),1.15)
  local n=label(t,style and ((st and st.name or style).." skin") or weapons[id].name,8,100,134,20,13,C.text,true,14); n.TextTruncate=Enum.TextTruncate.AtEnd
  local k=label(t,style and ("for "..weapons[id].name) or ("Weapon key · "..slotLabel(id)),8,118,134,18,13,DIM,false,11); k.TextTruncate=Enum.TextTruncate.AtEnd
  local tick=pill(t,"✓ OWNED",C.success); tick.Position=UDim2.fromOffset(6,6); tick.Visible=false
  table.insert(thumbs,{id=id,style=style,tick=tick,frame=t})
  table.insert(names,style and ((st and st.name or style).." "..weapons[id].short) or weapons[id].name)
 end
 local x=16+3*162+8
 label(f,b.name,x,16,360,40,28,C.text,true,30)
 local contents=label(f,table.concat(names," + "),x,58,360,40,13,DIM,false,13); contents.TextWrapped=true; contents.TextYAlignment=Enum.TextYAlignment.Top
 local note=label(f,"Buying grants only what you don't own yet.",x,100,360,18,13,DIM,false,12)
 local ends=pill(f,"",GOLD); ends.Position=UDim2.fromOffset(x,126); ends.TextSize=14; ends.Visible=false
 local off=pill(f,"",C.danger,C.text); off.AnchorPoint=Vector2.new(1,0); off.Position=UDim2.new(1,-16,0,16); off.TextSize=16; off.Size=UDim2.fromOffset(0,28)
 local price=label(f,"",870,46,290,40,28,C.text,true,28); price.RichText=true; price.TextXAlignment=Enum.TextXAlignment.Right
 local need=label(f,"",870,86,290,18,13,C.danger,false,12); need.TextXAlignment=Enum.TextXAlignment.Right
 local buy=UI.button(f,"BUY",W-216,H-64,200,48,function() Prompt.Open("b:"..b.id) end,true)
 table.insert(updates,function()
  local offer,code=Prompt.Resolve("b:"..b.id)
  f.Visible=code~="OFFER_EXPIRED" and code~="UNKNOWN_OFFER"
  for _,t in thumbs do t.tick.Visible=(t.style and ownsSkin(t.id,t.style)) or (not t.style and ownsWeapon(t.id)) end
  if b.newPlayerDays then
   local s=snap(); local created=s and tonumber(s.created)
   if created then
    local left=created+b.newPlayerDays*86400-serverNow()
    ends.Visible=left>0; ends.Text=left>=86400 and ("NEW PLAYER · Ends in "..math.floor(left/86400).."d") or ("NEW PLAYER · Ends in "..math.max(1,math.floor(left/3600)).."h")
   else ends.Visible=true; ends.Text="NEW PLAYER OFFER" end
  end
  if offer then
   off.Visible=true; off.Text="-"..math.floor((offer.discount or 0)*100+.5).."%"
   price.Text=priceRich(offer.cur,offer.price,offer.list)
   local short=offer.price-balance(offer.cur)
   price.TextTransparency=short>0 and .35 or 0
   need.Text=short>0 and ("Need "..Format(short).." more · "..matchText(short)) or ""
   note.Visible=true; buy.Text="BUY"; setActive(buy,true)
  else
   off.Visible=false; need.Text=""; price.TextTransparency=0
   price.Text=code=="ALREADY_OWNED" and "OWNED" or "Unavailable"
   note.Visible=false; buy.Text=code=="ALREADY_OWNED" and "OWNED" or "—"; setActive(buy,false)
  end
 end)
end
P.Bundles={key=function() local _,d=daily() return tostring(d) end,build=function(updates)
 local page=pages.Bundles; clearChildren(page)
 local scroll=Instance.new("ScrollingFrame"); scroll.Name="List"; scroll.Size=UDim2.fromScale(1,1); scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
 scroll.ScrollBarThickness=4; scroll.ScrollBarImageColor3=C.text; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.CanvasSize=UDim2.new(); scroll.Parent=page
 local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,12); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=scroll
 for i,b in Cat.BUNDLES do bundleCard(scroll,b,i,updates) end
end}

------------------------------------------------------------------ SKINS (slot chips, weapon dropdown, tier chips, paged grid)
local skinSlot,skinWeapon,skinTier,skinPage,skinPagesN=0,nil,"All",1,1
local skinsPage=pages.Skins
local slotChips,tierChips={},{}
local dropButton,dropList
local function skinWeapons()
 local ids={}
 for id=1,#weapons do if S.Allowed(id) and (skinSlot==0 or weapons.SlotOf(id)==skinSlot) then table.insert(ids,id) end end
 return ids
end
local function defaultWeapon(slot)
 local id=weapons.GetId(player,slot==0 and 1 or slot)
 if id and S.Allowed(id) then return id end
 return "all"
end
local function setSkinFilter(slot,weapon,tier)
 if slot~=nil then skinSlot=slot; skinWeapon=defaultWeapon(slot) end
 if weapon~=nil then skinWeapon=weapon end
 if tier~=nil then skinTier=tier end
 skinPage=1; dropList.Visible=false
 render(false)
end
for i,name in {"All","Primary","Secondary","Melee","Utility"} do
 local slot=i-1
 local b=UI.button(skinsPage,name,(i-1)*112,0,106,44,function() setSkinFilter(slot,nil,nil) end); b.TextSize=14; slotChips[slot]=b
end
dropButton=UI.button(skinsPage,"Weapon ▾",572,0,280,44,function()
 dropList.Visible=not dropList.Visible
 if not dropList.Visible then return end
 local keep={}; for _,c in dropList:GetChildren() do if c:IsA("UIListLayout") or c:IsA("UIPadding") or c:IsA("UICorner") then keep[c]=true end end
 clearChildren(dropList,keep)
 local options={"all"}; for _,id in skinWeapons() do table.insert(options,id) end
 for i,id in options do
  local o=UI.button(dropList,id=="all" and "All weapons" or weapons[id].name,0,0,256,40,function() setSkinFilter(nil,id,nil) end)
  o.Size=UDim2.new(1,-8,0,40); o.TextSize=14; o.LayoutOrder=i; o.ZIndex=31; UI.select(o,id==skinWeapon)
 end
end)
dropButton.TextSize=15; dropButton.TextTruncate=Enum.TextTruncate.AtEnd
for i,tier in {"All","Standard","Refined","Elite","Vault"} do
 local b=UI.button(skinsPage,tier=="Standard" and "Std" or (tier=="Refined" and "Refined" or tier),864+(i-1)*67,0,63,44,function() setSkinFilter(nil,nil,tier) end)
 b.TextSize=13; b.Size=UDim2.fromOffset(63,44); tierChips[tier]=b
 if tier~="All" then local bar=UI.frame(b,"Tier",8,38,47,3,S.TIERS[tier].color); UI.corner(bar,2) end
end
local grid=Instance.new("ScrollingFrame"); grid.Name="Grid"; grid.Position=UDim2.fromOffset(0,56); grid.Size=UDim2.fromOffset(1200,466); grid.BackgroundTransparency=1; grid.BorderSizePixel=0
grid.ScrollBarThickness=4; grid.ScrollBarImageColor3=C.text; grid.AutomaticCanvasSize=Enum.AutomaticSize.Y; grid.CanvasSize=UDim2.new(); grid.Parent=skinsPage
local gridLayout=Instance.new("UIGridLayout"); gridLayout.CellSize=UDim2.fromOffset(184,232); gridLayout.CellPadding=UDim2.fromOffset(12,12); gridLayout.SortOrder=Enum.SortOrder.LayoutOrder; gridLayout.Parent=grid
local gridPad=Instance.new("UIPadding"); gridPad.PaddingLeft=UDim.new(0,6); gridPad.PaddingTop=UDim.new(0,4); gridPad.Parent=grid
local gridKeep={[gridLayout]=true,[gridPad]=true}
local pager=UI.frame(skinsPage,"Pager",400,528,400,48); pager.BackgroundTransparency=1
local pageLabel=label(pager,"",60,0,280,48,16,C.text,true,18); pageLabel.TextXAlignment=Enum.TextXAlignment.Center
UI.button(pager,"‹",0,2,52,44,function() skinPage=math.clamp(skinPage-1,1,skinPagesN); render(false); grid.CanvasPosition=Vector2.zero end)
UI.button(pager,"›",348,2,52,44,function() skinPage=math.clamp(skinPage+1,1,skinPagesN); render(false); grid.CanvasPosition=Vector2.zero end)
local emptyLabel=label(skinsPage,"No skins match these filters.",0,120,1200,40,16,DIM,false,16); emptyLabel.TextXAlignment=Enum.TextXAlignment.Center; emptyLabel.Visible=false
dropList=Instance.new("ScrollingFrame"); dropList.Name="WeaponDropdown"; dropList.Position=UDim2.fromOffset(572,48); dropList.Size=UDim2.fromOffset(280,330); dropList.BackgroundColor3=C.background; dropList.BackgroundTransparency=.05
dropList.BorderSizePixel=0; dropList.ScrollBarThickness=4; dropList.ScrollBarImageColor3=C.text; dropList.AutomaticCanvasSize=Enum.AutomaticSize.Y; dropList.CanvasSize=UDim2.new(); dropList.ZIndex=30; dropList.Visible=false; dropList.Parent=skinsPage; UI.corner(dropList,12)
local dropLayout=Instance.new("UIListLayout"); dropLayout.Padding=UDim.new(0,4); dropLayout.SortOrder=Enum.SortOrder.LayoutOrder; dropLayout.Parent=dropList
local dropPad=Instance.new("UIPadding"); dropPad.PaddingTop=UDim.new(0,6); dropPad.PaddingLeft=UDim.new(0,6); dropPad.Parent=dropList
local function skinEntries()
 local ids=skinWeapon=="all" and skinWeapons() or {skinWeapon}
 local list={}
 for _,id in ids do
  if skinWeapon~="all" and (skinTier=="All") then table.insert(list,{id=id}) end -- "Default" finish card
  for _,st in S.LIST do if skinTier=="All" or st.tier==skinTier then table.insert(list,{id=id,style=st}) end end
 end
 return list
end
P.Skins={key=function()
 if skinWeapon==nil then skinWeapon=defaultWeapon(1) end
 return table.concat({today(),skinSlot,tostring(skinWeapon),skinTier,skinPage},"|")
end,build=function(updates)
 clearChildren(grid,gridKeep)
 for slot,b in slotChips do UI.select(b,slot==skinSlot) end
 for tier,b in tierChips do UI.select(b,tier==skinTier) end
 dropButton.Text=(skinWeapon=="all" and "All weapons" or weapons[skinWeapon].name).."  ▾"
 local list=skinEntries()
 local pagesN=math.max(1,math.ceil(#list/PAGE_SIZE))
 skinPage=math.clamp(skinPage,1,pagesN); skinPagesN=pagesN
 local p=P.Skins; p.built=p.key() -- clamp may change the key
 pager.Visible=pagesN>1; pageLabel.Text="Page "..skinPage.." / "..pagesN
 emptyLabel.Visible=#list==0
 for i=(skinPage-1)*PAGE_SIZE+1,math.min(#list,skinPage*PAGE_SIZE) do
  local e=list[i]
  if e.style then
   itemCard(grid,{kind="skin",weapon=e.id,style=e.style.id,offer="s:"..e.id..":"..e.style.id,title=e.style.name,sub=e.style.tier.." · "..weapons[e.id].name,color=(S.TIERS[e.style.tier] or S.TIERS.Standard).color,w=184,h=232,order=i},updates)
  else
   itemCard(grid,{kind="default",weapon=e.id,title="Default",sub="Factory finish · "..weapons[e.id].name,color=DIM,w=184,h=232,order=i},updates)
  end
 end
end}

------------------------------------------------------------------ DAILY
local resetLabels={}
P.Daily={key=function() local _,d=daily() return tostring(d) end,build=function(updates)
 local page=pages.Daily; clearChildren(page)
 label(page,"DAILY DEALS",0,0,400,40,28,C.text,true,30)
 local reset=label(page,"",700,0,500,40,20,C.text,true,20); reset.TextXAlignment=Enum.TextXAlignment.Right; resetLabels.Daily=reset
 local offers=daily()
 for i=1,6 do
  local f=itemCard(page,dailyEntry(offers[i],186,250,i),updates); f.Position=UDim2.fromOffset((i-1)*202,48)
 end
 label(page,"DAILY STREAK",0,312,300,32,20,C.text,true,22)
 local streakText=label(page,"",220,312,600,32,16,DIM,false,15)
 local tiles={}
 for day=1,7 do
  local t,ts=panelCard(page,"Day"..day,(day-1)*150,350,140,130,false)
  local dl=label(t,"DAY "..day,0,10,140,20,13,DIM,true,14); dl.TextXAlignment=Enum.TextXAlignment.Center
  local r=label(t,"",0,38,140,30,20,C.text,true,20); r.RichText=true; r.TextXAlignment=Enum.TextXAlignment.Center
  local reward=Config.STREAK[day] or {0,0}
  r.Text=string.format('<font color="%s">%s</font> %s',hex(Color("shards")),Glyph("shards"),Format(reward[1]))
  if (reward[2] or 0)>0 then local c=label(t,"",0,66,140,24,16,C.text,true,17); c.RichText=true; c.TextXAlignment=Enum.TextXAlignment.Center; c.Text=string.format('+ <font color="%s">%s</font> %s',hex(Color("cores")),Glyph("cores"),reward[2]) end
  local check=pill(t,"✓ CLAIMED",C.success); check.AnchorPoint=Vector2.new(.5,1); check.Position=UDim2.new(.5,0,1,-10); check.Visible=false
  local nextTag=pill(t,"TODAY",C.accent); nextTag.AnchorPoint=Vector2.new(.5,1); nextTag.Position=UDim2.new(.5,0,1,-10); nextTag.Visible=false
  tiles[day]={frame=t,stroke=ts,check=check,nextTag=nextTag}
 end
 local claimButton=UI.button(page,"CLAIM",1052,350,148,130,claim,true); claimButton.TextSize=24
 local foot=label(page,"Claim once per UTC day. Miss two days in a row and the streak starts again from day 1. Days 5 and 7 also pay Cores.",0,494,1040,36,13,DIM,false,13); foot.TextWrapped=true
 table.insert(updates,function()
  local info=streakInfo()
  for day,t in tiles do
   local done=info and day<=info.done
   local isNext=info and info.canClaim and day==info.nextDay
   t.check.Visible=done==true; t.nextTag.Visible=isNext==true
   t.frame.BackgroundTransparency=done and .5 or .22
   t.stroke.Color=isNext and C.accent or (done and C.success or C.text); t.stroke.Thickness=isNext and 3 or 1.5
   setBase(t.frame,t.stroke,(isNext or done) and .1 or .88)
  end
  if not info then streakText.Text=canSpend() and "Loading your streak..." or "Your streak shows once your profile loads."; claimButton.Text="CLAIM"; setActive(claimButton,false); return end
  streakText.Text=info.streak>0 and (info.streak.." day streak") or "Start your streak today"
  claimButton.Text=info.canClaim and "CLAIM" or "CLAIMED"; setActive(claimButton,info.canClaim and canSpend())
 end)
end}

------------------------------------------------------------------ KEYS (weapon keys by slot + Core Vault)
local function keyCard(parent,id,order,updates)
 local W,H=386,124
 local w=weapons[id]
 local f,stroke=panelCard(parent,w.name,0,0,W,H,true); f.LayoutOrder=order
 tierStrip(f,W,CYAN)
 local holder=UI.frame(f,"Stage",4,10,130,110); holder.BackgroundTransparency=1
 modelView(holder,id,equippedStyle(id),1.1)
 local n=label(f,w.name,140,12,W-150,24,20,C.text,true,19); n.TextTruncate=Enum.TextTruncate.AtEnd
 local family=w.family and (w.family:sub(1,1):upper()..w.family:sub(2)) or nil
 local role=label(f,(w.class or w.short or "").." · "..slotLabel(id)..(family and (" · "..family) or ""),140,36,W-150,16,13,DIM,false,12); role.TextTruncate=Enum.TextTruncate.AtEnd
 local desc=label(f,w.description or "",140,54,W-150,30,13,C.text,false,11); desc.TextWrapped=true; desc.TextYAlignment=Enum.TextYAlignment.Top; desc.TextTransparency=.3; desc.TextTruncate=Enum.TextTruncate.AtEnd
 local setPrice,_,need=priceBadge(f)
 need.AnchorPoint=Vector2.new(0,1); need.Position=UDim2.new(0,140,1,-14); need.TextXAlignment=Enum.TextXAlignment.Left; need.Size=UDim2.fromOffset(120,14)
 local ribbon=pill(f,"",C.danger,C.text); ribbon.Position=UDim2.fromOffset(8,12); ribbon.Visible=false
 local tag=pill(f,"OWNED",C.success); tag.AnchorPoint=Vector2.new(1,0); tag.Position=UDim2.new(1,-10,0,12); tag.Visible=false
 local owned,offerId=false,"w:"..id
 table.insert(updates,function()
  owned=ownsWeapon(id); offerId=keyOffer(id)
  tag.Visible=owned
  if owned then ribbon.Visible=false; setPrice(nil,nil,nil,"✓ Unlocked"); return end
  local offer,code=Prompt.Resolve(offerId)
  if not offer and offerId~="w:"..id then offerId="w:"..id; offer,code=Prompt.Resolve(offerId) end
  if not offer then ribbon.Visible=false; setPrice(nil,nil,nil,code=="ALREADY_OWNED" and "✓ Unlocked" or "Unavailable"); return end
  local off=offer.discount or 0
  ribbon.Visible=off>0; ribbon.Text="-"..math.floor(off*100+.5).."% TODAY"
  setPrice(offer.cur,offer.price,offer.list)
 end)
 f.Activated:Connect(function() if owned then previewInArsenal(id,nil) else Prompt.Open(offerId) end end)
 return f
end
local function vaultWeapon() return type(skinWeapon)=="number" and skinWeapon or defaultWeapon(1)~="all" and defaultWeapon(1) or 1 end
P.Keys={key=function() local _,d=daily() return d.."|"..tostring(vaultWeapon()) end,build=function(updates)
 local page=pages.Keys; clearChildren(page)
 local scroll=Instance.new("ScrollingFrame"); scroll.Name="List"; scroll.Size=UDim2.fromScale(1,1); scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
 scroll.ScrollBarThickness=4; scroll.ScrollBarImageColor3=C.text; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.CanvasSize=UDim2.new(); scroll.Parent=page
 local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,10); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=scroll
 local order=0
 local function header(title,hint,h)
  order+=1
  local r=UI.frame(scroll,title,0,0,1180,h or 58); r.BackgroundTransparency=1; r.LayoutOrder=order
  label(r,title,0,0,700,34,28,C.text,true,28)
  if hint then local t=label(r,hint,0,34,1180,20,13,DIM,false,13) end
  return r
 end
 local function gridFrame(cell)
  order+=1
  local g=UI.frame(scroll,"Grid"..order,0,0,1180,0); g.BackgroundTransparency=1; g.AutomaticSize=Enum.AutomaticSize.Y; g.LayoutOrder=order
  local gl=Instance.new("UIGridLayout"); gl.CellSize=cell; gl.CellPadding=UDim2.fromOffset(11,11); gl.SortOrder=Enum.SortOrder.LayoutOrder; gl.Parent=g
  return g
 end
 header("WEAPON KEYS","Every weapon is a sidegrade - unlocks are permanent. Locked weapons are listed cheapest first.")
 local priced={}
 for id,price in Cat.WEAPON_PRICES do if weapons[id] and not Cat.IsStarter(id) then table.insert(priced,{id=id,price=price}) end end
 table.sort(priced,function(a,b) if a.price~=b.price then return a.price<b.price end return a.id<b.id end)
 for slot,def in ipairs(weapons.Slots) do
  local ids={}
  for _,p in priced do if weapons.SlotOf(p.id)==slot then table.insert(ids,p.id) end end
  if #ids>0 then
   order+=1
   local r=UI.frame(scroll,def.label,0,0,1180,28); r.BackgroundTransparency=1; r.LayoutOrder=order
   label(r,def.label:upper(),0,0,400,28,20,C.accent,true,20)
   local g=gridFrame(UDim2.fromOffset(386,124))
   for i,id in ids do keyCard(g,id,i,updates) end
  end
 end
 order+=1; local gap=UI.frame(scroll,"Gap",0,0,1180,8); gap.BackgroundTransparency=1; gap.LayoutOrder=order
 local vw=vaultWeapon()
 header("CORE VAULT","Cores come from duel wins and streaks. Shown on "..weapons[vw].name.." - pick a weapon in Skins to preview another.")
 local g=gridFrame(UDim2.fromOffset(280,300))
 local i=0
 for _,st in S.LIST do
  if st.tier=="Vault" then
   i+=1
   itemCard(g,{kind="skin",weapon=vw,style=st.id,offer="s:"..vw..":"..st.id,title=st.name,sub="Vault · "..weapons[vw].name,color=S.TIERS.Vault.color,w=280,h=300,order=i,zoom=1.1},updates)
  end
 end
end}

------------------------------------------------------------------ badges + refresh
local viewedDay
local function updateBadges()
 local info=streakInfo()
 local canClaim=info~=nil and info.canClaim and canSpend()
 local d=today()
 player:SetAttribute("RiftBadgeShop",(canClaim and 1 or 0)+(viewedDay~=d and 1 or 0))
 tabDots.Home.Visible=canClaim
 tabDots.Daily.Visible=canClaim or viewedDay~=d
 local recruit=Cat.BUNDLE_BY_ID.recruit
 tabDots.Bundles.Visible=not bundlesSeen and recruit~=nil and Prompt.Resolve("b:recruit")~=nil
 local affordable=false
 local bal=balance("shards")
 for id,price in Cat.WEAPON_PRICES do if weapons[id] and not Cat.IsStarter(id) and price<=bal and not ownsWeapon(id) then affordable=true; break end end
 tabDots.Keys.Visible=affordable
 tabDots.Skins.Visible=false
end
local dirty=true
markDirty=function() dirty=true end
showTab=function(name)
 current=name; dropList.Visible=false
 for n,b in tabButtons do UI.select(b,n==name); pages[n].Visible=n==name end
 if shopVisible then
  if name=="Home" or name=="Daily" then viewedDay=today() end -- Home shows the first 3 daily deals
  if name=="Bundles" then bundlesSeen=true end
 end
 if shopVisible then render(false) end
 markDirty()
end
local lastRefresh=0
Controller:Register("Shop",screen,22,function(visible)
 shopVisible=visible
 if visible then
  task.defer(function() if shopVisible then fit(); showTab(current) end end) -- deferred: Controller:Set is mid-loop here
  if not snap() or os.clock()-lastRefresh>30 then lastRefresh=os.clock(); task.spawn(Prompt.Refresh) end
 else dropList.Visible=false end
end)
Prompt.Changed:Connect(function()
 setShards(balance("shards"),true); setCores(balance("cores"),true)
 markDirty()
end)
player:GetAttributeChangedSignal("RiftShards"):Connect(function() setShards(balance("shards"),true) end)
player:GetAttributeChangedSignal("RiftCores"):Connect(function() setCores(balance("cores"),true) end)
player.AttributeChanged:Connect(function(name)
 if name=="RiftShards" or name=="RiftCores" or name=="RiftSkins" or name=="RiftProfileState" or name:sub(1,10)=="RiftLocked" then markDirty() end
end)
-- Leave the Shop when travelling or when a match starts.
player:GetAttributeChangedSignal("RiftMap"):Connect(function() Controller:Set("Shop",false) end)
player:GetAttributeChangedSignal("RiftDuelPhase"):Connect(function() if player:GetAttribute("RiftDuelPhase") then Controller:Set("Shop",false) end end)

local lastDay,wasShop,nextTick=today(),false,0
run.Heartbeat:Connect(function()
 local d=today()
 if d~=lastDay then lastDay=d; markDirty() end
 -- Shop and Arsenal share priority 22: whichever was opened last wins.
 local A,Sh=Controller.screens.Arsenal,Controller.screens.Shop
 if A and Sh and A.wanted and Sh.wanted then
  if not wasShop then Controller:Set("Arsenal",false) else Controller:Set("Shop",false) end
 end
 wasShop=Sh~=nil and Sh.wanted
 if dirty then
  dirty=false
  updateBadges(); refreshHeader()
  if shopVisible then render(false) end
 end
end)
run.RenderStepped:Connect(function(dt)
 if Controller.active~="Shop" then return end
 if os.clock()>nextTick then
  nextTick=os.clock()+.25; fit()
  local left=(today()+1)*86400-workspace:GetServerTimeNow()
  if resetLabels.Daily and resetLabels.Daily.Parent then resetLabels.Daily.Text="Resets in "..clock(left) end
 end
 if current=="Home" then
  if feat.model and feat.rel then
   feat.yaw+=dt*.5
   feat.model:PivotTo(CFrame.Angles(0,feat.yaw,0)*CFrame.Angles(0,0,-.12)*feat.rel)
   if feat.items and #feat.items>1 and os.clock()>feat.switchAt then feat.switchAt=os.clock()+3.2; featShow((feat.index or 1)%#feat.items+1) end
  end
  if claimTile and claimTile.Parent then
   local info=streakInfo(); local pulse=claimTile:FindFirstChild("Pulse")
   if pulse then pulse.Scale=(info and info.canClaim and canSpend()) and 1+.015*math.sin(os.clock()*4) or 1 end
  end
 end
end)

------------------------------------------------------------------ end-of-match payout panel + in-match tally (own ScreenGui, not a Controller screen)
local pgui=Instance.new("ScreenGui"); pgui.Name="RiftPayout"; pgui.ResetOnSpawn=false; pgui.DisplayOrder=45; pgui.Parent=player:WaitForChild("PlayerGui")
local payout=UI.frame(pgui,"Payout",0,0,340,0,C.background); payout.AnchorPoint=Vector2.new(1,.5); payout.Position=UDim2.new(1,-20,.45,0)
payout.AutomaticSize=Enum.AutomaticSize.Y; payout.BackgroundTransparency=.12; payout.Active=false; payout.Visible=false; UI.corner(payout,16); UI.padding(payout,14)
local pStroke=Instance.new("UIStroke"); pStroke.Color=C.accent; pStroke.Transparency=.4; pStroke.Thickness=2; pStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; pStroke.Parent=payout
local payoutScale=Instance.new("UIScale"); payoutScale.Parent=payout
local pLayout=Instance.new("UIListLayout"); pLayout.Padding=UDim.new(0,6); pLayout.SortOrder=Enum.SortOrder.LayoutOrder; pLayout.Parent=payout
local pTitle=label(payout,"MATCH REWARDS",0,0,312,30,20,C.text,true,22); pTitle.Size=UDim2.new(1,0,0,30); pTitle.LayoutOrder=1
local pLines=UI.frame(payout,"Lines",0,0,312,0); pLines.Size=UDim2.new(1,0,0,0); pLines.AutomaticSize=Enum.AutomaticSize.Y; pLines.BackgroundTransparency=1; pLines.LayoutOrder=2
local plLayout=Instance.new("UIListLayout"); plLayout.Padding=UDim.new(0,2); plLayout.SortOrder=Enum.SortOrder.LayoutOrder; plLayout.Parent=pLines
local pNotes=UI.frame(payout,"Notes",0,0,312,0); pNotes.Size=UDim2.new(1,0,0,0); pNotes.AutomaticSize=Enum.AutomaticSize.Y; pNotes.BackgroundTransparency=1; pNotes.LayoutOrder=3
local pnLayout=Instance.new("UIListLayout"); pnLayout.Padding=UDim.new(0,2); pnLayout.SortOrder=Enum.SortOrder.LayoutOrder; pnLayout.Parent=pNotes
local pDivider=UI.frame(payout,"Divider",0,0,312,1,C.text); pDivider.Size=UDim2.new(1,0,0,1); pDivider.BackgroundTransparency=.8; pDivider.LayoutOrder=4
local pTotal=label(payout,"",0,0,312,34,28,C.text,true,26); pTotal.Size=UDim2.new(1,0,0,34); pTotal.RichText=true; pTotal.LayoutOrder=5
local pNext=label(payout,"",0,0,312,18,13,DIM,true,13); pNext.Size=UDim2.new(1,0,0,18); pNext.LayoutOrder=6; pNext.RichText=true
local pTrack=UI.frame(payout,"Track",0,0,312,10,C.panel); pTrack.Size=UDim2.new(1,0,0,10); pTrack.LayoutOrder=7; UI.corner(pTrack,5)
local pFill=UI.frame(pTrack,"Fill",0,0,0,10,C.accent); pFill.Size=UDim2.fromScale(0,1); UI.corner(pFill,5); UI.shade(pFill,.25)
local payoutGen=0
local function countUp(lbl,to,delay,dur,prefix,gen)
 task.delay(delay,function()
  local t0=os.clock()
  while gen==payoutGen do
   local a=math.min(1,(os.clock()-t0)/dur)
   lbl.Text=prefix..Format(math.floor(to*(1-(1-a)^2)+.5))
   if a>=1 then break end
   task.wait()
  end
 end)
end
local function showPayout(data)
 payoutGen+=1; local gen=payoutGen
 clearChildren(pLines,{[plLayout]=true}); clearChildren(pNotes,{[pnLayout]=true})
 local lines=type(data.lines)=="table" and data.lines or {}
 for i,l in lines do
  if type(l)=="table" then
   local text,amount=tostring(l[1] or l.label or ""),tonumber(l[2] or l.amount) or 0
   local r=UI.frame(pLines,"Line"..i,0,0,312,22); r.Size=UDim2.new(1,0,0,22); r.BackgroundTransparency=1; r.LayoutOrder=i
   local a=label(r,text,0,0,220,22,16,C.text,false,15); a.Size=UDim2.new(1,-90,1,0); a.TextTruncate=Enum.TextTruncate.AtEnd
   local v=label(r,"+0",0,0,90,22,16,Color("shards"),true,16); v.AnchorPoint=Vector2.new(1,0); v.Position=UDim2.fromScale(1,0); v.TextXAlignment=Enum.TextXAlignment.Right
   countUp(v,amount,.15+(i-1)*.18,.45,"+",gen)
  end
 end
 local notes=type(data.notes)=="table" and data.notes or {}
 for i,n in notes do
  local t=label(pNotes,"• "..tostring(n),0,0,312,18,13,GOLD,false,12); t.Size=UDim2.new(1,0,0,18); t.TextWrapped=true; t.LayoutOrder=i
 end
 pNotes.Visible=#notes>0
 local shards,cores=tonumber(data.shards) or 0,tonumber(data.cores) or 0
 pTotal.Text=string.format('<font color="%s">%s</font> +%s',hex(Color("shards")),Glyph("shards"),Format(shards))..(cores>0 and string.format('   <font color="%s">%s</font> +%s',hex(Color("cores")),Glyph("cores"),Format(cores)) or "")
 local id,price=nextUnlock()
 local after=balance("shards"); local before=math.max(0,after-shards)
 if id then
  pNext.Text="NEXT UNLOCK · "..weapons[id].name:upper().."  "..Format(math.min(after,price)).." / "..Format(price)
  pFill.Size=UDim2.fromScale(math.clamp(before/price,0,1),1); pFill.BackgroundColor3=after>=price and C.success or C.accent
  task.delay(.6+#lines*.18,function() if gen==payoutGen then Tween:Create(pFill,TweenInfo.new(1.1,Enum.EasingStyle.Quad),{Size=UDim2.fromScale(math.clamp(after/price,0,1),1)}):Play() end end)
  pTrack.Visible=true
 else pNext.Text="ARSENAL COMPLETE"; pTrack.Visible=false end
 local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 payoutScale.Scale=math.clamp(math.min(v.X/900,v.Y/600),.6,1)
 payout.Visible=true; payout.Position=UDim2.new(1,380,.45,0)
 Tween:Create(payout,TweenInfo.new(.35,Enum.EasingStyle.Back),{Position=UDim2.new(1,-20,.45,0)}):Play()
 if shards>0 or cores>0 then UI.reward() end
 task.delay(6.5,function()
  if gen~=payoutGen then return end
  Tween:Create(payout,TweenInfo.new(.35,Enum.EasingStyle.Quad),{Position=UDim2.new(1,380,.45,0)}):Play()
  task.delay(.4,function() if gen==payoutGen then payout.Visible=false end end)
 end)
end
Sync.OnClientEvent:Connect(function(kind,data)
 if kind=="payout" and type(data)=="table" then showPayout(data); markDirty() end
end)
-- In-match tally: escrowed Shards (RiftMatchEarn), paid only when the match finishes.
local tally=label(pgui,"",0,0,0,32,16,C.text,true,16); tally.AnchorPoint=Vector2.new(1,0); tally.Position=UDim2.new(1,-16,0,8); tally.AutomaticSize=Enum.AutomaticSize.X; tally.Size=UDim2.fromOffset(0,32)
tally.RichText=true; tally.BackgroundColor3=C.background; tally.BackgroundTransparency=.25; tally.TextXAlignment=Enum.TextXAlignment.Center; tally.Visible=false; UI.corner(tally,16)
local tPad=Instance.new("UIPadding"); tPad.PaddingLeft=UDim.new(0,12); tPad.PaddingRight=UDim.new(0,12); tPad.Parent=tally
local tPop=Instance.new("UIScale"); tPop.Parent=tally
local lastEarn=0
local function refreshTally()
 local v=tonumber(player:GetAttribute("RiftMatchEarn"))
 tally.Visible=v~=nil
 if not v then lastEarn=0; return end
 tally.Text=string.format('<font color="%s">%s</font> +%s <font color="%s" size="12">pending</font>',hex(Color("shards")),Glyph("shards"),Format(v),hex(DIM))
 if v>lastEarn then tPop.Scale=1.25; Tween:Create(tPop,TweenInfo.new(.3,Enum.EasingStyle.Back),{Scale=1}):Play() end
 lastEarn=v
end
player:GetAttributeChangedSignal("RiftMatchEarn"):Connect(refreshTally)
refreshTally()

------------------------------------------------------------------ init
for tab,b in tabButtons do UI.select(b,tab==current) end
pages[current].Visible=true
setShards(balance("shards"),false); setCores(balance("cores"),false)
refreshHeader(); updateBadges()
