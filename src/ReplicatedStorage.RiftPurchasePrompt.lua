-- RiftPurchasePrompt: client-only shop glue shared by Shop, Arsenal, Loadout and the lobby "offer" event.
-- Owns the ShopConfirm view (UIController priority 26), the cached snapshot and every RiftShop call.
local Prompt={}
local SHARDS,CORES=Color3.fromRGB(64,220,255),Color3.fromRGB(170,96,255)
function Prompt.Glyph(cur) return cur=="cores" and "⬢" or "◆" end
function Prompt.Color(cur) return cur=="cores" and CORES or SHARDS end
function Prompt.Format(n)
 n=math.floor(tonumber(n) or 0)
 local s=tostring(math.abs(n)):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
 return (n<0 and "-" or "")..s
end
local Run=game:GetService("RunService")
if Run:IsServer() or not Run:IsRunning() or not game.Players.LocalPlayer then return Prompt end -- helpers only outside a running client

local Http=game:GetService("HttpService")
local Tween=game:GetService("TweenService")
local player=game.Players.LocalPlayer
local storage=game.ReplicatedStorage
local Shop=storage:WaitForChild("RiftShop")
local Sync=storage:WaitForChild("RiftShopSync")
local action=storage:WaitForChild("RiftAction")
local weapons=require(storage:WaitForChild("RiftWeapons"))
local Models=require(storage:WaitForChild("RiftWeaponModels"))
local Cat=require(storage:WaitForChild("RiftShopCatalog"))
local S=require(storage:WaitForChild("RiftSkins"))
local Config=require(storage:WaitForChild("RiftEconomyConfig"))
local UI=require(storage:WaitForChild("RiftUI"))
local Controller=require(storage:WaitForChild("RiftUIController"))
local Audio=require(storage:WaitForChild("RiftAudio"))
local C=UI.C
local Format,Glyph,Color=Prompt.Format,Prompt.Glyph,Prompt.Color
local WEAPON_CYAN,BUNDLE_GOLD,DIM=Color3.fromRGB(64,220,255),Color3.fromRGB(255,196,64),Color3.fromRGB(138,147,168)

------------------------------------------------------------------ snapshot cache
local changed=Instance.new("BindableEvent")
Prompt.Changed=changed.Event
local snap,refreshing=nil,false
Prompt.State={state=player:GetAttribute("RiftProfileState")}
local function fire() changed:Fire(snap) end
local function invoke(name,payload)
 local ok,res=pcall(Shop.InvokeServer,Shop,name,payload)
 if ok and type(res)=="table" then return res end
 return {ok=false,code="ERROR"}
end
local function applyBalances(t)
 if snap and type(t)=="table" then
  if tonumber(t.shards) then snap.shards=t.shards end
  if tonumber(t.cores) then snap.cores=t.cores end
 end
end
function Prompt.Snapshot() return snap end
function Prompt.Refresh()
 if refreshing then while refreshing do task.wait() end return snap end
 refreshing=true
 local res=invoke("snapshot")
 refreshing=false
 if res.ok then snap=res; Prompt.State.state=res.state or Prompt.State.state
 elseif res.state then Prompt.State.state=res.state end
 fire()
 return res.ok and snap or nil,res.code
end
local function balance(cur)
 local a=player:GetAttribute(cur=="cores" and "RiftCores" or "RiftShards")
 if tonumber(a) then return a end
 return snap and tonumber(snap[cur=="cores" and "cores" or "shards"]) or 0
end
local function ctx()
 return {
  ownsWeapon=function(id)
   if Cat.IsStarter(id) then return true end
   if snap and snap.ownedWeapons then return snap.ownedWeapons[tostring(id)]==true end
   return player:GetAttribute("RiftLocked"..id)~=true
  end,
  ownsSkin=function(key) return snap~=nil and snap.ownedSkins~=nil and snap.ownedSkins[key]==true end,
  created=snap and snap.created or os.time(),
 }
end
function Prompt.Resolve(offerId) return Cat.Resolve(offerId,math.floor(workspace:GetServerTimeNow()),ctx()) end
function Prompt.EquipSkin(weaponId,style)
 local res=invoke("equipSkin",{weapon=weaponId,style=style or false})
 if res.ok and snap then snap.equippedSkins=res.equippedSkins or snap.equippedSkins; fire() end
 return res
end
function Prompt.ClaimDaily()
 local res=invoke("claimDaily")
 if snap and snap.daily then
  if res.ok then applyBalances(res); snap.daily.streak=res.streak; snap.daily.canClaim=false; snap.daily.nextReward=res.nextReward or snap.daily.nextReward
  elseif res.code=="ALREADY_CLAIMED" then snap.daily.canClaim=false end
  fire()
 end
 return res
end
local function canSpend() local st=Prompt.State.state return st=="ready" or st=="nosave" end
local function equippedStyle(id)
 if id==21 then return nil end
 if snap and snap.equippedSkins then return snap.equippedSkins[tostring(id)] end
 local ok,t=pcall(function() return Http:JSONDecode(player:GetAttribute("RiftSkins") or "{}") end)
 return ok and type(t)=="table" and t[tostring(id)] or nil
end

------------------------------------------------------------------ view
local gui=Instance.new("ScreenGui"); gui.Name="RiftPurchasePrompt"; gui.ResetOnSpawn=false; gui.DisplayOrder=40; gui.IgnoreGuiInset=true; gui.Parent=player:WaitForChild("PlayerGui")
local root=UI.frame(gui,"ShopConfirm",0,0,0,0,C.background); root.Size=UDim2.fromScale(1,1); root.BackgroundTransparency=.25
local card=UI.frame(root,"Card",0,0,780,470,C.background); card.AnchorPoint=Vector2.new(.5,.5); card.Position=UDim2.fromScale(.5,.5); UI.surface(card); card.BackgroundColor3=C.background; card.ClipsDescendants=true
local scale=Instance.new("UIScale"); scale.Parent=card
local baseScale=1
local function fit() local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720); baseScale=math.min(1,v.X/840,v.Y/530); scale.Scale=baseScale end
fit(); if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
local strip=UI.frame(card,"TierStrip",0,0,780,6,C.accent)
local stage=UI.frame(card,"Stage",16,22,340,340,C.panel); UI.corner(stage,14); UI.shade(stage,.3)
local view=Instance.new("ViewportFrame"); view.BackgroundTransparency=1; view.Size=UDim2.fromScale(1,1); view.Ambient=Color3.fromRGB(175,182,200); view.LightColor=Color3.new(1,1,1); view.LightDirection=Vector3.new(-1,-1.4,-.8); view.Parent=stage
local cam=Instance.new("Camera"); cam.FieldOfView=30; cam.Parent=view; view.CurrentCamera=cam
local dots=UI.text(stage,"",0,306,340,26,13,C.text); dots.TextXAlignment=Enum.TextXAlignment.Center
local kindLabel=UI.text(card,"",376,22,388,22,13,C.accent,true); UI.outline(kindLabel,1.5)
local title=UI.text(card,"",376,46,388,42,32,C.text,true); title.TextScaled=true
local titleLimit=Instance.new("UITextSizeConstraint"); titleLimit.MaxTextSize=32; titleLimit.Parent=title
local grantBox=UI.frame(card,"Grants",376,96,388,148); grantBox.BackgroundTransparency=1
local grantLayout=Instance.new("UIListLayout"); grantLayout.Padding=UDim.new(0,4); grantLayout.SortOrder=Enum.SortOrder.LayoutOrder; grantLayout.Parent=grantBox
UI.line(card,376,252,388)
local price=UI.text(card,"",376,260,388,46,32,C.text,true); price.RichText=true
local balanceLabel=UI.text(card,"",376,306,388,24,16,DIM)
local status=UI.text(card,"",376,332,388,48,16,C.text); status.TextWrapped=true; status.TextYAlignment=Enum.TextYAlignment.Top; status.RichText=true
local banner=UI.frame(card,"Banner",16,370,340,30,C.danger); banner.BackgroundTransparency=.2; UI.corner(banner,8); banner.Visible=false
local bannerText=UI.text(banner,"",10,0,320,30,13,C.text,true)
local earnLink=Instance.new("TextButton"); earnLink.Text="How to earn Shards ›"; earnLink.Font=UI.Font.bold; earnLink.TextSize=16; earnLink.TextColor3=C.accent; earnLink.BackgroundTransparency=1
earnLink.TextXAlignment=Enum.TextXAlignment.Left; earnLink.Position=UDim2.fromOffset(18,410); earnLink.Size=UDim2.fromOffset(240,44); earnLink.Parent=card
local cancelButton,confirmButton
local spinner=UI.frame(card,"Spinner",0,0,26,26); spinner.BackgroundTransparency=1; spinner.AnchorPoint=Vector2.new(.5,.5); spinner.Visible=false; spinner.ZIndex=8; UI.corner(spinner,13)
local ring=Instance.new("UIStroke"); ring.Color=C.background; ring.Thickness=3; ring.Parent=spinner
local ringGrad=Instance.new("UIGradient"); ringGrad.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.6,.2),NumberSequenceKeypoint.new(1,1)}); ringGrad.Parent=ring
local flash=UI.frame(card,"Flash",0,0,0,0,C.text); flash.Size=UDim2.fromScale(1,1); flash.BackgroundTransparency=1; flash.ZIndex=10; flash.Active=false

-- state of the open prompt
local cur={gen=0} -- {gen,id,offer,txn,mode="confirm"|"busy"|"done"|"closed"|"blocked",price,cur,previews,index,model,rel,yaw}
local function setButton(b,text,enabled,color)
 b.Text=text; b.Active=enabled; b.AutoButtonColor=false
 b.BackgroundColor3=color or (b:GetAttribute("Primary") and C.accent or C.panel)
 b.BackgroundTransparency=enabled and 0 or .45
 b.TextColor3=(b:GetAttribute("Primary") and enabled and color~=C.panel) and C.background or C.text
 b.TextTransparency=enabled and 0 or .35
end
local function setStatus(text,color) status.Text=text or ""; status.TextColor3=color or C.text end
local function matchesFor(need) return math.max(1,math.ceil(need/Config.SHARDS_PER_MATCH_ESTIMATE)) end
local function hex(c) return "#"..c:ToHex() end

-- 3D preview
local function clearModel() if cur.model then cur.model:Destroy(); cur.model=nil end end
local function showPreview(i)
 clearModel()
 local list=cur.previews or {}
 local g=list[i]; if not g then dots.Text="" return end
 cur.index=i
 local w=weapons[g.weapon or g.id]; if not w then return end
 local skin=g.kind=="skin" and S.Model(g.style) or (equippedStyle(g.id) and S.Model(equippedStyle(g.id)))
 local m=Models.create(w,skin); m:PivotTo(CFrame.new())
 if w.name=="Fists" then pcall(Models.recolorFists,m,player) end
 local cf,size=m:GetBoundingBox()
 cur.rel=CFrame.new(cf.Position):Inverse()*m:GetPivot()
 local dist=math.max(size.Magnitude,1.2)*1.95
 cam.CFrame=CFrame.lookAt(Vector3.new(0,dist*.18,dist),Vector3.zero)
 m.Parent=view; cur.model=m
 if #list>1 then local t={} for k=1,#list do t[k]=k==i and "●" or "○" end dots.Text=table.concat(t," ") else dots.Text="" end
end

-- labels
local function tierOf(offer)
 local g=offer.grants[1]
 local off=offer.discount and offer.discount>0 and ("  -"..math.floor(offer.discount*100+.5).."%") or ""
 if offer.kind=="bundle" then return "BUNDLE"..off,BUNDLE_GOLD end
 if g.kind=="weapon" then local slot=weapons.SlotOf(g.id); return "WEAPON KEY · "..(slot and weapons.Slots[slot].label:upper() or "")..off,WEAPON_CYAN end
 local st=S.Get(g.style); local tier=st and st.tier or "Standard"
 return tier:upper().." SKIN"..off,(S.TIERS[tier] or S.TIERS.Standard).color
end
local function grantLines(offer)
 local lines={}
 if offer.kind=="bundle" then
  for _,g in offer.grants do
   if g.kind=="weapon" then table.insert(lines,"✓ "..weapons[g.id].name.." - unlocks permanently")
   else local st=S.Get(g.style); table.insert(lines,"✓ "..(st and st.name or g.style).." skin for "..weapons[g.weapon].name) end
  end
 else
  local g=offer.grants[1]
  if g.kind=="weapon" then
   local w=weapons[g.id]; local slot=weapons.SlotOf(g.id)
   table.insert(lines,"✓ Unlocks permanently")
   table.insert(lines,"✓ "..(w.class or w.short or "")..(slot and (" · "..weapons.Slots[slot].label) or ""))
   table.insert(lines,"✓ A sidegrade - every weapon is balanced")
  else
   table.insert(lines,"✓ Skin for "..weapons[g.weapon].name)
   table.insert(lines,"✓ Cosmetic only - no stat changes")
  end
 end
 return lines
end
local function setGrants(lines)
 for _,c in grantBox:GetChildren() do if c:IsA("TextLabel") then c:Destroy() end end
 for i,l in lines do
  local t=UI.text(grantBox,l,0,0,388,22,16,C.text); t.LayoutOrder=i; t.TextTruncate=Enum.TextTruncate.AtEnd
  if i>6 then t.Text="+ "..(#lines-5).." more"; break end
 end
end
local function priceText(p,c,list)
 local s=string.format('<font color="%s">%s</font> %s',hex(Color(c)),Glyph(c),Format(p))
 if list and list>p then s..=string.format('  <font size="20" color="%s"><s>%s</s></font>',hex(DIM),Format(list)) end
 return s
end
local STATE_TEXT={loading="Loading your profile...",offline="Progress offline - rejoin to save",readonly="View only - progress is open in another server"}
local function refreshBanner()
 local st=Prompt.State.state
 local msg=not canSpend() and (Prompt.State.msg or STATE_TEXT[st or "loading"] or "Profile unavailable")
 banner.Visible=msg~=nil and msg~=false; bannerText.Text=msg or ""
end
-- Re-evaluates the confirm row (balance, affordability, state) without touching mode-specific text.
local function refreshConfirm()
 refreshBanner()
 if cur.mode~="confirm" or not cur.offer then return end
 local have=balance(cur.cur); local after=have-cur.price
 balanceLabel.Text="Balance  "..Glyph(cur.cur).." "..Format(have).."  →  "..Format(math.max(after,0))
 balanceLabel.TextColor3=after<0 and C.danger or DIM
 if not canSpend() then setButton(confirmButton,"UNAVAILABLE",false,C.panel)
 elseif after<0 then
  setButton(confirmButton,"NEED "..Format(-after).." MORE",false,C.panel)
  if status.Text=="" or cur.needShown then
   cur.needShown=true
   setStatus(cur.cur=="cores" and "Not enough Cores - win duels and keep your daily streak" or ("Not enough Shards - about "..matchesFor(-after).." match"..(matchesFor(-after)==1 and "" or "es")),C.danger)
  end
 else
  if cur.needShown then cur.needShown=false; setStatus("") end
  setButton(confirmButton,"CONFIRM",true)
 end
end
local function close()
 cur.gen+=1; cur.mode="closed"; cur.offer=nil; spinner.Visible=false
 clearModel(); Controller:Set("ShopConfirm",false)
end
local function showUnavailable(code)
 cur.mode="blocked"; cur.offer=nil; clearModel(); dots.Text=""
 strip.BackgroundColor3=C.panel; kindLabel.Text="OFFER"; kindLabel.TextColor3=DIM
 title.Text=code=="ALREADY_OWNED" and "Already owned" or code=="OFFER_EXPIRED" and "Offer ended" or "Unavailable"
 setGrants({}); price.Text=""; balanceLabel.Text=""
 setStatus(code=="ALREADY_OWNED" and "You already own everything in this offer." or code=="OFFER_EXPIRED" and "This offer rotated out." or "This offer is unavailable right now.",DIM)
 setButton(confirmButton,"OK",true); setButton(cancelButton,"CLOSE",true)
end
local function present(offer)
 cur.offer=offer; cur.price=offer.price; cur.cur=offer.cur; cur.mode="confirm"; cur.needShown=false
 local tier,color=tierOf(offer)
 strip.BackgroundColor3=color; kindLabel.Text=tier; kindLabel.TextColor3=color
 title.Text=offer.title or ""
 setGrants(grantLines(offer))
 price.Text=priceText(offer.price,offer.cur,offer.list)
 earnLink.Text=offer.cur=="cores" and "How to earn Cores ›" or "How to earn Shards ›"
 setStatus("")
 setButton(cancelButton,"CANCEL",true)
 cur.previews={}; for i,g in offer.grants do if i<=6 then table.insert(cur.previews,g) end end
 cur.yaw=math.rad(-62); cur.switchAt=os.clock()+3.2
 showPreview(1)
 refreshConfirm()
end

function Prompt.Open(offerId)
 cur.gen+=1; cur.id=offerId; cur.txn=Http:GenerateGUID(false) -- one txn per opening, reused on retries
 spinner.Visible=false
 local offer,code=Prompt.Resolve(offerId)
 if offer then present(offer) else showUnavailable(code) end
 Controller:Set("ShopConfirm",true)
 scale.Scale=baseScale*.94
 Tween:Create(scale,TweenInfo.new(.18,Enum.EasingStyle.Back),{Scale=baseScale}):Play()
 return offer,code
end

-- after a successful purchase: equip every grant (one weapon per slot), then close
local function equipAll(offer)
 local gen=cur.gen
 cur.mode="busy"; setButton(confirmButton,"",false); spinner.Visible=true; setButton(cancelButton,"CLOSE",false)
 local used,ok={},true
 for _,g in offer.grants do
  if g.kind=="weapon" then
   local slot=weapons.SlotOf(g.id)
   if slot and not used[slot] then used[slot]=true; action:FireServer("loadout",g.id,slot) end
  end
 end
 for _,g in offer.grants do
  if g.kind=="skin" then local res=Prompt.EquipSkin(g.weapon,g.style); ok=ok and res.ok end
 end
 if gen~=cur.gen then return end
 spinner.Visible=false; Audio.Play("equip")
 cur.mode="done"
 setStatus(ok and "Equipped." or "Equipped what we could - try again from the Arsenal.",ok and C.success or C.danger)
 setButton(confirmButton,"EQUIPPED",false); setButton(cancelButton,"CLOSE",true)
 task.delay(.7,function() if gen==cur.gen and ok then close() end end)
end
local function success(offer,res)
 cur.mode="done"; spinner.Visible=false
 if snap then
  applyBalances(res)
  snap.ownedWeapons=snap.ownedWeapons or {}; snap.ownedSkins=snap.ownedSkins or {}
  for _,g in offer.grants do if g.kind=="weapon" then snap.ownedWeapons[tostring(g.id)]=true else snap.ownedSkins[g.key]=true end end
 end
 fire()
 UI.reward()
 flash.BackgroundTransparency=.2; Tween:Create(flash,TweenInfo.new(.55,Enum.EasingStyle.Quad),{BackgroundTransparency=1}):Play()
 kindLabel.Text=offer.kind=="weapon" and "UNLOCKED" or offer.kind=="bundle" and "BUNDLE UNLOCKED" or "SKIN UNLOCKED"; kindLabel.TextColor3=C.success; strip.BackgroundColor3=C.success
 price.Text=""; balanceLabel.Text="Balance  "..Glyph(offer.cur).." "..Format(balance(offer.cur)); balanceLabel.TextColor3=DIM
 setStatus("It's yours - permanently.",C.success)
 local equippable=false
 for _,g in offer.grants do if g.kind=="weapon" or (g.kind=="skin" and S.Allowed(g.weapon)) then equippable=true end end
 if equippable then setButton(confirmButton,"EQUIP NOW",true,C.success) else setButton(confirmButton,"DONE",true) end
 setButton(cancelButton,"CLOSE",true)
end
local FAIL_TEXT={
 OFFER_EXPIRED="This offer rotated out.",ALREADY_OWNED="You already own this.",UNKNOWN_OFFER="This offer is unavailable right now.",
 BUSY="Try again.",RATE="Try again in a moment.",ERROR="Something went wrong - try again.",BAD_ARGS="Try again.",
 NOT_LOADED="Your profile is still loading - try again shortly.",OFFLINE="Progress offline - rejoin to save.",READ_ONLY="View only - purchases are off in this server.",CLOSING="Server is closing - purchases are paused.",
}
local function buy()
 local offer=cur.offer; if not offer or cur.mode~="confirm" then return end
 local gen=cur.gen
 cur.mode="busy"; setButton(confirmButton,"",false); setButton(cancelButton,"CANCEL",false); spinner.Visible=true; setStatus("")
 local res=invoke("purchase",{offer=cur.id,txn=cur.txn,price=cur.price,cur=cur.cur})
 applyBalances(res)
 if gen~=cur.gen then if res.ok then fire() end return end
 spinner.Visible=false; setButton(cancelButton,"CANCEL",true)
 if res.ok and (res.code==nil or res.code=="OK") then return success(offer,res) end
 local code=res.code or "ERROR"
 if code=="PRICE_CHANGED" and tonumber(res.price) then
  cur.price=res.price; cur.cur=res.cur=="cores" and "cores" or "shards"; cur.mode="confirm"
  price.Text=priceText(cur.price,cur.cur,tonumber(res.list))
  refreshConfirm()
  setStatus("The price changed to "..Glyph(cur.cur).." "..Format(cur.price)..". Confirm again?",BUNDLE_GOLD)
  return
 end
 if code=="INSUFFICIENT" then
  cur.mode="confirm"; refreshConfirm()
  local need=tonumber(res.need) or 0
  setStatus(res.cur=="cores" and "Not enough Cores - win duels and keep your daily streak" or ("Not enough Shards - about "..matchesFor(need).." match"..(matchesFor(need)==1 and "" or "es")),C.danger)
  fire(); return
 end
 if code=="OFFER_EXPIRED" or code=="ALREADY_OWNED" or code=="UNKNOWN_OFFER" then
  cur.mode="blocked"; setStatus(FAIL_TEXT[code],DIM); setButton(confirmButton,"OK",true); setButton(cancelButton,"CLOSE",true)
  if code=="ALREADY_OWNED" then task.spawn(Prompt.Refresh) end
  return
 end
 if code=="NOT_LOADED" or code=="OFFLINE" or code=="READ_ONLY" or code=="CLOSING" then
  banner.Visible=true; bannerText.Text=FAIL_TEXT[code]
 end
 cur.mode="confirm"; refreshConfirm()
 if confirmButton.Active then setButton(confirmButton,"TRY AGAIN",true) end
 setStatus(FAIL_TEXT[code] or "Try again.",C.danger)
end

cancelButton=UI.button(card,"CANCEL",376,404,150,52,function() close() end)
confirmButton=UI.button(card,"CONFIRM",538,404,226,52,function()
 if cur.mode=="confirm" then task.spawn(buy)
 elseif cur.mode=="done" then
  if confirmButton.Text=="EQUIP NOW" and cur.offer then task.spawn(equipAll,cur.offer) else close() end
 elseif cur.mode=="blocked" then close() end
end,true)
spinner.Parent=confirmButton; spinner.Position=UDim2.fromScale(.5,.5)

------------------------------------------------------------------ How to earn card
local earn=Instance.new("TextButton"); earn.Name="HowToEarn"; earn.Text=""; earn.AutoButtonColor=false; earn.Size=UDim2.fromScale(1,1); earn.BackgroundColor3=C.background; earn.BackgroundTransparency=.35; earn.Visible=false; earn.ZIndex=20; earn.Parent=gui
local earnCard=UI.frame(earn,"Card",0,0,440,420,C.background); earnCard.AnchorPoint=Vector2.new(.5,.5); earnCard.Position=UDim2.fromScale(.5,.5); UI.surface(earnCard); earnCard.BackgroundColor3=C.background; earnCard.ZIndex=21; earnCard.Active=true
local earnScale=Instance.new("UIScale"); earnScale.Parent=earnCard
local function earnText(text,y,size,color,bold,h)
 local t=UI.text(earnCard,text,24,y,392,h or 24,size,color,bold); t.ZIndex=22; t.RichText=true; t.TextWrapped=true; return t
end
do
 local sh=string.format('<font color="%s">◆</font>',hex(SHARDS)); local co=string.format('<font color="%s">⬢</font>',hex(CORES))
 earnText("HOW TO EARN",20,32,C.text,true,40)
 local rows={
  {"Duel kills",sh.." "..Config.KILL.." each"},
  {"Round wins",sh.." "..Config.ROUND_WIN.." each"},
  {"Finish a match",sh.." "..Config.MATCH_COMPLETE},
  {"Win a match",sh.." "..Config.MATCH_WIN.."  "..co.." "..Config.MATCH_WIN_CORES},
  {"First win of the day",sh.." "..Config.FIRST_WIN_OF_DAY.."  "..co.." "..Config.FIRST_WIN_OF_DAY_CORES},
  {"First match / first win ever",sh.." "..Config.FIRST_MATCH_EVER.." / "..Config.FIRST_WIN_EVER},
  {"Daily reward streak","up to "..sh.." "..Config.STREAK[#Config.STREAK][1].."  "..co.." "..Config.STREAK[#Config.STREAK][2]},
 }
 for i,r in rows do
  local y=68+(i-1)*36
  earnText(r[1],y,16,C.text,false,30)
  local v=earnText(r[2],y,16,C.text,true,30); v.TextXAlignment=Enum.TextXAlignment.Right
 end
 local foot=earnText("About "..Config.SHARDS_PER_MATCH_ESTIMATE.." Shards per match. Cores come from duel wins and streaks. Private servers pay nothing.",324,13,DIM,false,36); foot.TextWrapped=true
 local ok=UI.button(earnCard,"GOT IT",24,362,392,44,function() earn.Visible=false end,true); ok.ZIndex=22
end
earn.Activated:Connect(function() earn.Visible=false end)
function Prompt.HowToEarn()
 local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 earnScale.Scale=math.min(1,v.X/500,v.Y/480)
 earn.Visible=true
end
earnLink.Activated:Connect(Prompt.HowToEarn)

------------------------------------------------------------------ wiring
Controller:Register("ShopConfirm",root,26,function(visible)
 if visible then refreshConfirm() end
end)
Run.RenderStepped:Connect(function(dt)
 if spinner.Visible then ringGrad.Rotation=(ringGrad.Rotation+dt*360)%360 end
 if Controller.active~="ShopConfirm" or not cur.model then return end
 cur.yaw+=dt*.5
 cur.model:PivotTo(CFrame.Angles(0,cur.yaw,0)*CFrame.Angles(0,0,-.12)*cur.rel)
 if cur.previews and #cur.previews>1 and os.clock()>cur.switchAt then
  cur.switchAt=os.clock()+3.2; showPreview(cur.index%#cur.previews+1)
 end
end)
changed.Event:Connect(function() if Controller.active=="ShopConfirm" then refreshConfirm() end end)
for _,a in {"RiftShards","RiftCores"} do player:GetAttributeChangedSignal(a):Connect(function() if Controller.active=="ShopConfirm" then refreshConfirm() end end) end
player:GetAttributeChangedSignal("RiftProfileState"):Connect(function()
 local st=player:GetAttribute("RiftProfileState")
 if st==Prompt.State.state then return end
 Prompt.State.state=st; Prompt.State.msg=nil
 if snap then snap.state=st end
 if st=="ready" or st=="nosave" or st=="readonly" then task.spawn(Prompt.Refresh) else fire() end
end)
Sync.OnClientEvent:Connect(function(kind,data)
 if kind=="delta" and type(data)=="table" then applyBalances(data); fire()
 elseif kind=="owned" and type(data)=="table" then
  if snap then
   snap.ownedWeapons=data.weapons or snap.ownedWeapons; snap.ownedSkins=data.skins or snap.ownedSkins; snap.equippedSkins=data.equippedSkins or snap.equippedSkins
  end
  fire()
 elseif kind=="state" and type(data)=="table" then
  local was=Prompt.State.state
  Prompt.State.state=data.state; Prompt.State.msg=data.msg
  if snap then snap.state=data.state end
  if (data.state=="ready" or data.state=="nosave" or data.state=="readonly") and (not snap or was~=data.state) then task.spawn(Prompt.Refresh) else fire() end
 elseif kind=="offer" and typeof(data)=="string" then
  Prompt.Open(data)
 end
end)
task.spawn(Prompt.Refresh)
return Prompt
