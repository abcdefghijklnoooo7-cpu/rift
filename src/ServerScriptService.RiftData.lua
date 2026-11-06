-- RiftData: player profiles, session-locked saves, ownership provider (stage 6 spec: profileSchema + saveStrategy).
-- Record = {schema, seq, lock, data}. Every write is UpdateAsync with a session + seq check. Failed loads never write.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local DataStoreService=game:GetService("DataStoreService")
local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService")
local weapons=require(RS:WaitForChild("RiftWeapons"))
local Cat=require(RS:WaitForChild("RiftShopCatalog"))
local Skins=require(RS:WaitForChild("RiftSkins"))
local Config=require(RS:WaitForChild("RiftEconomyConfig"))
local Sync=RS:WaitForChild("RiftShopSync")
local ResetCombat=SSS:WaitForChild("RiftResetCombat")

local RiftData={}
local IS_STUDIO=RunService:IsStudio()
local STORE_NAME=IS_STUDIO and "RiftProfile_v1_Studio" or "RiftProfile_v1"
local SESSION=HttpService:GenerateGUID(false)
local CURRENT=1
local STALE=300
local MIGRATIONS={} -- [n]=function(data) -> data at v n+1. Keep forever.
local MSG={loading="Loading your progress...",ready="",nosave="Studio test: progress is not saved",offline="Progress offline - rejoin to save",readonly="Progress is read-only this session"}
RiftData.SESSION=SESSION

RiftData.TEMPLATE={
 v=CURRENT,shards=Config.WELCOME_SHARDS or 500,cores=0,
 owned={weapons={},skins={}},
 equipped={loadout={1,2,21,23},skins={}},
 daily={day=0,earned=0,coresEarned=0,lastClaim=0,streak=0,firstWinDay=0},
 firsts={match=false,win=false},
 pairs={},txn={},ledger={},
 stats={kills=0,deaths=0,matches=0,wins=0,roundsWon=0,shardsEarned=0,shardsSpent=0,coresEarned=0,coresSpent=0,purchases=0},
 flags={review=false,founder=false},
 orphaned={},
 created=0,saved=0,saves=0,
}
for slot,def in ipairs(weapons.Slots) do RiftData.TEMPLATE.equipped.loadout[slot]=def.default end

local P={} -- [player]=rec
local closing=false
local store,useMock,anySuccess=nil,false,false

-- helpers
local function deepCopy(t)
 if type(t)~="table" then return t end
 local c={} for k,v in pairs(t) do c[k]=deepCopy(v) end return c
end
local function today() return os.time()//86400 end
local function finiteInt(v)
 if type(v)~="number" or v~=v or v==math.huge or v==-math.huge then return 0,true end
 local c=math.clamp(math.floor(v),0,1e9) return c,c~=v
end
local function trim(arr,n) while #arr>n do table.remove(arr,1) end end
local function asArray(t)
 if type(t)~="table" then return {} end
 local a={} for i=1,#t do if type(t[i])=="table" then table.insert(a,t[i]) end end return a
end
local function lockNow(now) return {session=SESSION,job=game.JobId,t=now} end
local function canWrite(r) return r and (r.state=="ready" or r.state=="nosave") end

function RiftData.Today() return today() end
function RiftData.Ledger(profile,k,o,s,c)
 if type(profile)~="table" then return end
 profile.ledger=profile.ledger or {}
 table.insert(profile.ledger,{t=os.time(),k=tostring(k or "earn"),o=string.sub(tostring(o or ""),1,48),s=s or 0,c=c or 0})
 trim(profile.ledger,50)
end

local function newProfile(now)
 local d=deepCopy(RiftData.TEMPLATE)
 d.created=now; d.daily.day=now//86400
 RiftData.Ledger(d,"grant","welcome",d.shards,0)
 return d
end

-- Studio-only in-memory store with UpdateAsync semantics (JSON round trip like the real thing).
local Mock={data={}}
function Mock:UpdateAsync(key,fn)
 local cur=self.data[key]
 local new=fn(cur and HttpService:JSONDecode(cur) or nil)
 if new==nil then return nil end
 self.data[key]=HttpService:JSONEncode(new)
 return HttpService:JSONDecode(self.data[key])
end
local function denied(e)
 e=tostring(e)
 return e:find("StudioAccessToApisNotAllowed",1,true) or e:find("403",1,true) or e:find("API Services",1,true) or e:lower():find("not allowed",1,true)
end
local function switchMock(e)
 if useMock then return end
 useMock=true
 warn("[RiftData] DataStore unavailable ("..tostring(e)..") - using in-memory MockStore. Enable Studio Access to API Services (Game Settings > Security) to test real saves.")
end
local function getStore()
 if useMock then return Mock end
 if store then return store end
 local ok,s=pcall(DataStoreService.GetDataStore,DataStoreService,STORE_NAME)
 if ok and s then store=s return s end
 if IS_STUDIO and not anySuccess and denied(s) then switchMock(s) return Mock end
 return nil,s
end
local function budget(min)
 local ok,b=pcall(DataStoreService.GetRequestBudgetForRequestType,DataStoreService,Enum.DataStoreRequestType.UpdateAsync)
 return (not ok) or b>=min
end
local function waitBudget()
 for _=1,10 do if budget(1) then return end task.wait(1) end
end
-- One UpdateAsync attempt. Returns ok,result.
local function request(key,fn)
 local s,err=getStore()
 if not s then return false,err end
 if s~=Mock then waitBudget() end
 local ok,res=pcall(function() return s:UpdateAsync(key,fn) end)
 if ok then if s~=Mock then anySuccess=true end return true,res end
 if s~=Mock and IS_STUDIO and not anySuccess and denied(res) then switchMock(res) return request(key,fn) end
 return false,res
end

-- records
local function rec(player)
 local r=P[player]
 if not r then
  r={state=nil,profile=nil,lastSeq=0,dirty=false,saving=false,again=false,release=false,releaseOnLoad=false,
   removed=false,released=false,finalFail=false,locked=false,lastWrite=-1e9,readyFns={},soon=0,nextAuto=nil,loading=false}
  P[player]=r
 end
 return r
end
local function setState(player,r,st)
 r.state=st
 player:SetAttribute("RiftProfileState",st)
 pcall(function() Sync:FireClient(player,"state",{state=st,msg=MSG[st] or ""}) end)
end

-- sanitize (load): clamps, orphans unknown ids, fixes loadout/skins
local function ownsW(d,id) return Cat.IsStarter(id) or d.owned.weapons[tostring(id)]==true end
local function sanitize(d)
 local now,day=os.time(),today()
 local bad
 d.shards,bad=finiteInt(d.shards); if bad then d.flags.review=true end
 d.cores,bad=finiteInt(d.cores); if bad then d.flags.review=true end
 if type(d.orphaned)~="table" then d.orphaned={} end
 local ow={}
 for k,v in pairs(d.owned.weapons) do
  local id=tonumber(k)
  if v==true and id and weapons[id] then if not Cat.IsStarter(id) then ow[tostring(id)]=true end
  else d.orphaned["w:"..tostring(k)]=true end
 end
 d.owned.weapons=ow
 local os_={}
 for k,v in pairs(d.owned.skins) do
  local w,st=tostring(k):match("^(%d+):([%w_%-]+)$")
  w=tonumber(w)
  if v==true and w and weapons[w] and Skins.BY_ID[st] and Skins.Allowed(w) then os_[Skins.Key(w,st)]=true
  else d.orphaned["s:"..tostring(k)]=true end
 end
 d.owned.skins=os_
 local lo=type(d.equipped.loadout)=="table" and d.equipped.loadout or {}
 local clean={}
 for slot,def in ipairs(weapons.Slots) do
  local id=tonumber(lo[slot])
  if id and table.find(weapons.Loadouts[def.category],id) and ownsW(d,id) then clean[slot]=id else clean[slot]=def.default end
 end
 d.equipped.loadout=clean
 local es={}
 for k,v in pairs(d.equipped.skins) do
  local w=tonumber(k)
  if w and type(v)=="string" and d.owned.skins[tostring(w)..":"..v] then es[tostring(w)]=v end
 end
 d.equipped.skins=es
 for k,v in pairs(RiftData.TEMPLATE.daily) do local n=d.daily[k]; if type(n)~="number" or n~=n then d.daily[k]=v end end
 if d.daily.day~=day then d.daily.day=day; d.daily.earned=0; d.daily.coresEarned=0 end
 for k,v in pairs(RiftData.TEMPLATE.stats) do local n=d.stats[k]; if type(n)~="number" or n~=n then d.stats[k]=v end end
 d.firsts.match=d.firsts.match==true; d.firsts.win=d.firsts.win==true
 d.txn=asArray(d.txn); trim(d.txn,32)
 d.ledger=asArray(d.ledger); trim(d.ledger,50)
 if type(d.created)~="number" or d.created<=0 or d.created>now+86400 then d.created=now end
end
local function prunePairs(d)
 local day,n,keep=today(),0,{}
 if type(d.pairs)~="table" then d.pairs={} end
 for k,v in pairs(d.pairs) do
  if type(v)=="table" and v.d==day and n<64 then keep[tostring(k)]=v; n+=1 end
 end
 d.pairs=keep
end
local function reconcile(d,t)
 for k,v in pairs(t) do
  if d[k]==nil or (type(v)=="table" and type(d[k])~="table") then d[k]=deepCopy(v)
  elseif type(v)=="table" and next(v)~=nil and #v==0 then reconcile(d[k],v) end
 end
end

-- validate(data) before every write: returns the copy to write, or nil,reason
local function validate(r)
 local d=r.profile
 trim(d.txn,32); trim(d.ledger,50); prunePairs(d)
 for _,k in ipairs({"shards","cores"}) do
  local v=d[k]
  if type(v)~="number" or v~=v or v%1~=0 or v<0 or v>1e9 then return nil,"bad "..k end
 end
 local copy=deepCopy(d)
 local ok,json=pcall(HttpService.JSONEncode,HttpService,{schema=1,seq=r.lastSeq,lock=lockNow(os.time()),data=copy})
 if not ok then return nil,"json "..tostring(json) end
 if #json>=200000 then return nil,"size "..#json end
 return copy
end

-- Mirror: client-facing attributes (server writes only)
function RiftData.Mirror(player)
 local r=P[player]
 local d=r and r.profile
 local usable=d and (r.state=="ready" or r.state=="nosave" or r.state=="readonly")
 for id=1,#weapons do
  local locked=not Cat.IsStarter(id) and not (usable and d.owned.weapons[tostring(id)]==true)
  player:SetAttribute("RiftLocked"..id,locked or nil)
 end
 player:SetAttribute("RiftShards",usable and d.shards or 0)
 player:SetAttribute("RiftCores",usable and d.cores or 0)
 local ok,js=pcall(HttpService.JSONEncode,HttpService,usable and d.equipped.skins or {})
 player:SetAttribute("RiftSkins",ok and js or "{}")
 player:SetAttribute("RiftLifetimeWins",usable and d.stats.wins or 0)
 player:SetAttribute("RiftProfileState",r and r.state or "loading")
end

-- API
function RiftData.Get(player)
 local r=P[player]
 if r and r.profile and (r.state=="ready" or r.state=="nosave" or r.state=="readonly") then return r.profile end
 return nil
end
function RiftData.State(player) local r=P[player] return r and r.state or nil end
function RiftData.IsClosing() return closing end
function RiftData.CanSpend(player)
 local r=P[player]
 return canWrite(r) and r.profile~=nil and not closing and not r.released
end
function RiftData.MarkDirty(player) local r=P[player] if r then r.dirty=true end end
function RiftData.Sync(player,msgType,data) pcall(function() Sync:FireClient(player,msgType,data) end) end
function RiftData.OwnsWeapon(player,id)
 id=tonumber(id); if not id or not weapons[id] then return false end
 if Cat.IsStarter(id) then return true end
 local d=RiftData.Get(player)
 return d~=nil and d.owned.weapons[tostring(id)]==true
end
function RiftData.OwnsSkin(player,key)
 local d=RiftData.Get(player)
 return d~=nil and type(key)=="string" and d.owned.skins[key]==true
end
function RiftData.OnReady(player,fn)
 if not player.Parent then return end
 local r=rec(player)
 if canWrite(r) and r.profile then task.spawn(fn,r.profile) else table.insert(r.readyFns,fn) end
end
function RiftData.Grant(player,shards,cores,reason,kind)
 if not RiftData.CanSpend(player) then return false end
 local d=P[player].profile
 local s,c=tonumber(shards) or 0,tonumber(cores) or 0
 if s~=s or c~=c then return false end
 s,c=math.floor(math.clamp(s,-1e9,1e9)),math.floor(math.clamp(c,-1e9,1e9))
 local s0,c0=d.shards,d.cores
 d.shards=math.clamp(s0+s,0,1e9); d.cores=math.clamp(c0+c,0,1e9)
 local ds,dc=d.shards-s0,d.cores-c0
 if ds>0 then d.stats.shardsEarned+=ds end
 if dc>0 then d.stats.coresEarned+=dc end
 RiftData.Ledger(d,kind or "earn",reason,ds,dc)
 RiftData.Mirror(player); RiftData.MarkDirty(player)
 RiftData.Sync(player,"delta",{shards=d.shards,cores=d.cores,granted={shards=ds,cores=dc},reason=reason})
 return true
end
-- Studio-only test grant (server code only; no remote reaches this).
function RiftData.DevGrant(player,shards,cores)
 if not IS_STUDIO then return false end
 return RiftData.Grant(player,shards or 0,cores or 0,"dev","grant")
end

-- SAVE
local function drop(player)
 local r=P[player]
 if r and r.removed and not r.saving and not r.loading then P[player]=nil end
end
local function releaseLock(player,r)
 if not r.locked then return end
 r.saving=true
 local key="u_"..player.UserId
 local ok=request(key,function(old)
  if type(old)=="table" and type(old.lock)=="table" and old.lock.session==SESSION then old.lock=nil; return old,{player.UserId} end
  return nil
 end)
 r.locked=false; r.released=true; r.saving=false
 if not ok then warn("[RiftData] lock release failed for "..player.Name.." (expires in "..STALE.." s)") end
end

local function save(player,release)
 local r=P[player]
 if not r or r.released then return end
 if release then r.release=true end
 if r.saving then r.again=true return end
 if not canWrite(r) or not r.profile then
  if r.release and r.state=="readonly" and r.locked then releaseLock(player,r) end
  if r.release then drop(player) end
  return
 end
 r.saving=true
 local key="u_"..player.UserId
 repeat
  r.again=false
  local rel=r.release
  if not useMock then
   local gap=(closing and 6 or 7)-(os.clock()-r.lastWrite)
   if gap>0 then task.wait(gap) end
  end
  if not canWrite(r) then break end
  local copy,why=validate(r)
  if not copy then
   warn("[RiftData] validate failed for "..player.Name..": "..tostring(why).." - write refused")
   r.profile.flags.review=true; r.dirty=true
   if rel then r.finalFail=true end
   break
  end
  r.dirty=false
  local lost,newSeq,now
  local fn=function(old)
   lost,newSeq=nil,nil; now=os.time()
   if type(old)~="table" or type(old.lock)~="table" or old.lock.session~=SESSION then lost="LOCK" return nil end
   if old.seq~=r.lastSeq then lost="SEQ" return nil end
   old.data=deepCopy(copy); old.data.saved=now; old.data.saves=(tonumber(old.data.saves) or 0)+1
   old.seq+=1
   if rel then old.lock=nil else old.lock=lockNow(now) end
   newSeq=old.seq
   return old,{player.UserId}
  end
  local ok,err
  for i,w in ipairs({0,1,2,4}) do
   if w>0 then task.wait(w+math.random()*0.5) end
   ok,err=request(key,fn)
   if ok then break end
   warn("[RiftData] save attempt "..i.." failed for "..player.Name..": "..tostring(err))
  end
  r.lastWrite=os.clock()
  if ok and lost then
   warn("[RiftData] session lost ("..lost..") for "..player.Name.." - now read-only")
   r.locked=false; r.released=true
   setState(player,r,"readonly"); RiftData.Mirror(player)
   if player.Parent and not r.removed then player:Kick("Your session moved to another server.") end
   break
  elseif ok and newSeq then
   r.lastSeq=newSeq; r.profile.saved=now; r.profile.saves=(r.profile.saves or 0)+1
   if rel then r.locked=false; r.released=true; break end
  else
   r.dirty=true
   if rel then r.finalFail=true; break end
  end
 until not r.again
 r.saving=false
 if r.release then drop(player) end
end
RiftData.Save=save
function RiftData.SaveNow(player) task.spawn(save,player,false) end
function RiftData.SaveSoon(player)
 local r=P[player]; if not r then return end
 r.dirty=true; r.soon+=1
 local token=r.soon
 task.delay(6,function() if P[player]==r and r.soon==token then save(player,false) end end)
end

-- LOAD
local load
local function onLoaded(player,r,data,state)
 r.profile=data
 if state~="readonly" and data.created<(Config.FOUNDER_END or 0) and not data.flags.founder then
  local add=Config.FOUNDER_SHARDS or 1500
  data.shards=math.clamp(data.shards+add,0,1e9); data.flags.founder=true
  RiftData.Ledger(data,"grant","founder",add,0); r.dirty=true
 end
 setState(player,r,state)
 for slot,def in ipairs(weapons.Slots) do player:SetAttribute(def.attribute,data.equipped.loadout[slot]) end
 RiftData.Mirror(player)
 if player.Character then ResetCombat:Fire(player) end
 r.nextAuto=os.clock()+7+(player.UserId%60)
 if state~="readonly" then
  local fns=r.readyFns; r.readyFns={}
  for _,fn in ipairs(fns) do task.spawn(fn,data) end
 end
end
local function goOffline(player,r)
 r.profile=nil
 setState(player,r,"offline"); RiftData.Mirror(player)
 task.delay(60,function()
  if P[player]==r and r.state=="offline" and not r.removed and not closing and player.Parent then load(player,true) end
 end)
end

load=function(player,background)
 local r=rec(player)
 if r.loading or closing then return end
 r.loading=true
 if not background then setState(player,r,"loading"); RiftData.Mirror(player) end
 local key="u_"..player.UserId
 local errs,busies=0,0
 local waits={1,2,4,8,8}
 while true do
  if r.removed or closing then r.loading=false; drop(player) return end
  local busy,newer,corrupt,seen=false,false,false,nil
  local ok,res=request(key,function(old)
   busy,newer,corrupt,seen=false,false,false,nil
   local now=os.time()
   if old==nil then return {schema=1,seq=0,lock=lockNow(now),data=newProfile(now)},{player.UserId} end
   if type(old)~="table" or type(old.data)~="table" or type(old.seq)~="number" then corrupt=true return nil end
   if type(old.data.v)~="number" or old.data.v>CURRENT then newer=true; seen=old return nil end
   local lk=old.lock
   if type(lk)=="table" and lk.session~=SESSION and not IS_STUDIO and now-(tonumber(lk.t) or 0)<STALE then busy=true return nil end
   old.lock=lockNow(now)
   return old,{player.UserId}
  end)
  if ok and busy then
   busies+=1
   if busies>6 then
    r.loading=false
    if player.Parent then player:Kick("Your Rift progress is still saving on another server. Rejoin in a minute.") end
    r.removed=true; drop(player) return
   end
   task.wait(5)
  elseif ok and (newer or corrupt) then
   r.loading=false
   warn("[RiftData] "..(newer and "newer save version" or "corrupt record").." for "..player.Name.." - read-only")
   local d=deepCopy(RiftData.TEMPLATE); d.shards=0; d.created=os.time(); d.flags.founder=true
   if newer and type(seen.data)=="table" then
    -- show what we can, never write it back
    local s=deepCopy(seen.data); s.v=CURRENT
    local okR=pcall(function() reconcile(s,RiftData.TEMPLATE); sanitize(s) end)
    if okR then d=s end
   end
   onLoaded(player,r,d,"readonly")
   if r.removed then drop(player) end
   return
  elseif ok and type(res)=="table" and type(res.data)=="table" then
   r.lastSeq=res.seq; r.locked=true; r.lastWrite=os.clock()
   local data,state=res.data,(useMock and "nosave" or "ready")
   for n=data.v,CURRENT-1 do
    local okM,out=pcall(function() return MIGRATIONS[n](deepCopy(data)) end)
    if not okM or type(out)~="table" then warn("[RiftData] migration "..n.." failed: "..tostring(out)); state="readonly"; break end
    data=out; data.v=n+1
   end
   local okS,e=pcall(function() reconcile(data,RiftData.TEMPLATE); sanitize(data); prunePairs(data) end)
   if not okS then warn("[RiftData] sanitize failed: "..tostring(e)); state="readonly"; data=deepCopy(RiftData.TEMPLATE) end
   r.loading=false
   onLoaded(player,r,data,state)
   if r.removed or r.releaseOnLoad or closing then save(player,true) end
   return
  else
   errs+=1
   warn("[RiftData] load attempt "..errs.." failed for "..player.Name..": "..tostring(res))
   if errs>=#waits then r.loading=false; goOffline(player,r); if r.removed then drop(player) end return end
   task.wait(waits[errs]+math.random()*0.5)
  end
 end
end

-- Ownership provider (server): closes every equip path that goes through weapons.IsUnlocked.
weapons.OwnershipProvider=function(player,id)
 id=tonumber(id)
 if not id then return false end
 if Cat.IsStarter(id) then return true end
 local r=P[player]
 if not r or not r.profile then return false end
 local st=r.state
 if st~="ready" and st~="nosave" and st~="readonly" then return false end
 return r.profile.owned.weapons[tostring(id)]==true
end

-- lifecycle
local function onAdded(player)
 if closing then return end
 rec(player)
 task.spawn(load,player,false)
end
Players.PlayerAdded:Connect(onAdded)
for _,p in ipairs(Players:GetPlayers()) do if not P[p] then onAdded(p) end end
Players.PlayerRemoving:Connect(function(player)
 local r=P[player]; if not r then return end
 r.removed=true
 if r.loading then r.releaseOnLoad=true return end
 if canWrite(r) or (r.state=="readonly" and r.locked) then task.spawn(save,player,true) else drop(player) end
end)

-- autosave (staggered per player; writes even when clean to refresh lock.t)
task.spawn(function()
 while true do
  task.wait(1)
  if not closing then
   local now=os.clock()
   for p,r in pairs(P) do
    if canWrite(r) and not r.saving and not r.released and not r.removed and r.nextAuto and now>=r.nextAuto then
     r.nextAuto=now+60
     if r.dirty or useMock or budget(3) then task.spawn(save,p,false) end
    end
   end
  end
 end
end)

game:BindToClose(function()
 closing=true
 for p,r in pairs(P) do
  if (canWrite(r) or (r.state=="readonly" and r.locked)) and not r.released then task.spawn(save,p,true) end
 end
 local limit=os.clock()+(IS_STUDIO and 5 or 25)
 while os.clock()<limit do
  local busy=false
  for _,r in pairs(P) do
   if r.saving or r.loading or (canWrite(r) and not r.released and not r.finalFail) then busy=true break end
  end
  if not busy then break end
  task.wait(0.25)
 end
end)

return RiftData
