-- RiftShopServer: RiftShop RemoteFunction handler (snapshot/purchase/equipSkin/claimDaily). Server-authoritative; never InvokeClient.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RiftData=require(script.Parent:WaitForChild("RiftData"))
local Cat=require(RS:WaitForChild("RiftShopCatalog"))
local S=require(RS:WaitForChild("RiftSkins"))
local Config=require(RS:WaitForChild("RiftEconomyConfig"))
local weapons=require(RS:WaitForChild("RiftWeapons"))
local Shop=RS:WaitForChild("RiftShop")

local ACTIONS={snapshot=true,purchase=true,equipSkin=true,claimDaily=true}
local BUCKET,REFILL,SLOW=6,3,2
local STRIKE_MAX,STRIKE_WIN,BLOCK=60,60,30
local STATE_CODE={readonly="READ_ONLY",offline="OFFLINE",loading="NOT_LOADED"}
local R={} -- per-player rate state

local function rs(p)
 local r=R[p]
 if not r then r={tok=BUCKET,t=os.clock(),strikes=0,sw=os.clock(),block=0,last={},busy=false}; R[p]=r end
 return r
end
local function strike(p,r)
 local now=os.clock()
 if now-r.sw>STRIKE_WIN then r.sw=now; r.strikes=0 end
 r.strikes+=1
 if r.strikes>=STRIKE_MAX then r.block=now+BLOCK; r.strikes=0; r.sw=now; warn("[RiftShop] ignoring "..p.Name.." for "..BLOCK.." s (strikes)") end
end

-- validation
local function okStr(s,min,max) return typeof(s)=="string" and #s>=(min or 1) and #s<=(max or 48) and s:match("^[%w_:%-]+$")~=nil end
local function okNum(n) return typeof(n)=="number" and n==n and math.abs(n)<1e7 and n%1==0 end
local function okPayload(t)
 if t==nil then return true end
 if typeof(t)~="table" then return false end
 local n=0
 for k,v in pairs(t) do
  n+=1
  if n>4 or typeof(k)~="string" or #k>16 then return false end
  local tv=typeof(v)
  if tv=="string" then if not okStr(v) then return false end
  elseif tv=="number" then if not okNum(v) then return false end
  elseif tv~="boolean" then return false end
 end
 return true
end
local function validate(action,payload)
 if typeof(action)~="string" or not ACTIONS[action] or not okPayload(payload) then return false end
 if action=="purchase" then
  if typeof(payload)~="table" then return false end
  return okStr(payload.offer) and okStr(payload.txn,8,48) and okNum(payload.price) and (payload.cur=="shards" or payload.cur=="cores")
 elseif action=="equipSkin" then
  if typeof(payload)~="table" or not okNum(payload.weapon) or payload.weapon<1 or payload.weapon>#weapons then return false end
  local st=payload.style
  return st==false or (okStr(st) and S.Get(st)~=nil)
 end
 return true
end

-- state gate for mutations
local function gate(p)
 if RiftData.IsClosing() then return nil,"CLOSING" end
 local st=RiftData.State(p)
 if st~="ready" and st~="nosave" then return nil,STATE_CODE[st] or "NOT_LOADED" end
 local d=RiftData.Get(p)
 if not d or not RiftData.CanSpend(p) then return nil,"NOT_LOADED" end
 return d
end
local function fail(code,extra) local t=extra or {}; t.ok=false; t.code=code; return t end

-- daily streak
local function streakInfo(d)
 local today=RiftData.Today()
 local dl=d.daily or {}
 local last,streak=tonumber(dl.lastClaim) or 0,tonumber(dl.streak) or 0
 if today-last>=2 then streak=0 end
 local canClaim=last<today
 local nr=Config.STREAK[(streak%#Config.STREAK)+1] or {0,0}
 return today,streak,canClaim,{shards=nr[1] or 0,cores=nr[2] or 0}
end

local function copyKeys(t) local o={} for k,v in pairs(t or {}) do o[k]=v end return o end
local function owned(d) return {weapons=copyKeys(d.owned.weapons),skins=copyKeys(d.owned.skins),equippedSkins=copyKeys(d.equipped.skins)} end

local function snapshot(p)
 local d=RiftData.Get(p)
 local st=RiftData.State(p)
 if not d then return fail(STATE_CODE[st] or "NOT_LOADED",{state=st}) end
 local today,streak,canClaim,nr=streakInfo(d)
 return {ok=true,code="OK",shards=d.shards,cores=d.cores,ownedWeapons=copyKeys(d.owned.weapons),ownedSkins=copyKeys(d.owned.skins),equippedSkins=copyKeys(d.equipped.skins),
  daily={day=today,offers=Cat.Daily(today),streak=streak,canClaim=canClaim and (st=="ready" or st=="nosave"),resetAt=(today+1)*86400,nextReward=nr},
  firsts={match=d.firsts.match==true,win=d.firsts.win==true},created=d.created,catalogVersion=Cat.VERSION,state=st}
end

local function purchase(p,pl)
 local d,code=gate(p); if not d then return fail(code) end
 -- 3. idempotency
 for _,t in ipairs(d.txn) do
  if t.id==pl.txn then return {ok=true,dup=true,code=t.code,shards=d.shards,cores=d.cores,granted={shards=0,cores=0}} end
 end
 -- 4-5. resolve (server time, profile ctx)
 local offer,rc=Cat.Resolve(pl.offer,os.time(),{
  ownsWeapon=function(id) return Cat.IsStarter(id) or d.owned.weapons[tostring(id)]==true end,
  ownsSkin=function(k) return d.owned.skins[k]==true end,
  created=d.created})
 if not offer then return fail(rc or "UNKNOWN_OFFER",{shards=d.shards,cores=d.cores}) end
 -- 6. price check
 if pl.price~=offer.price or pl.cur~=offer.cur then return fail("PRICE_CHANGED",{price=offer.price,cur=offer.cur,list=offer.list}) end
 -- 7. balance
 local cur=offer.cur=="cores" and "cores" or "shards"
 if d[cur]<offer.price then return fail("INSUFFICIENT",{need=offer.price-d[cur],cur=cur,shards=d.shards,cores=d.cores}) end
 -- 8. mutate (no yields)
 d[cur]-=offer.price
 local gw,gs={},{}
 for _,g in ipairs(offer.grants) do
  if g.kind=="weapon" then
   local k=tostring(g.id)
   if not Cat.IsStarter(g.id) and not d.owned.weapons[k] then d.owned.weapons[k]=true; table.insert(gw,g.id) end
  elseif g.kind=="skin" and typeof(g.key)=="string" then
   if not d.owned.skins[g.key] then d.owned.skins[g.key]=true; table.insert(gs,g.key) end
  end
 end
 local st=d.stats
 if cur=="cores" then st.coresSpent+=offer.price else st.shardsSpent+=offer.price end
 st.purchases+=1
 table.insert(d.txn,{id=pl.txn,code="OK"})
 while #d.txn>32 do table.remove(d.txn,1) end
 RiftData.Ledger(d,"buy",offer.id,cur=="shards" and -offer.price or 0,cur=="cores" and -offer.price or 0)
 -- 9. publish
 local granted={shards=cur=="shards" and -offer.price or 0,cores=cur=="cores" and -offer.price or 0,weapons=gw,skins=gs}
 RiftData.Mirror(p); RiftData.MarkDirty(p); RiftData.SaveSoon(p)
 RiftData.Sync(p,"delta",{shards=d.shards,cores=d.cores,granted={shards=granted.shards,cores=granted.cores},reason="buy"})
 RiftData.Sync(p,"owned",owned(d))
 return {ok=true,code="OK",shards=d.shards,cores=d.cores,granted=granted,offer=offer.id}
end

local function equipSkin(p,pl)
 local d,code=gate(p); if not d then return fail(code) end
 local w,style=pl.weapon,pl.style
 if not weapons[w] or not S.Allowed(w) then return fail("BAD_ARGS") end
 local wk=tostring(w)
 if style==false then
  d.equipped.skins[wk]=nil
 else
  local key=S.Key(w,style)
  if d.owned.skins[key]~=true then return fail("NOT_OWNED") end
  d.equipped.skins[wk]=style
 end
 RiftData.Mirror(p); RiftData.MarkDirty(p); RiftData.SaveSoon(p)
 RiftData.Sync(p,"owned",owned(d))
 return {ok=true,code="OK",weapon=w,style=style,equippedSkins=copyKeys(d.equipped.skins)}
end

local function claimDaily(p)
 local d,code=gate(p); if not d then return fail(code) end
 local today,streak,canClaim,nr=streakInfo(d)
 if not canClaim then return fail("ALREADY_CLAIMED",{streak=streak,resetAt=(today+1)*86400}) end
 -- mutate streak first (no yields), then grant (exempt from match multipliers)
 local ps,pl0=d.daily.streak,d.daily.lastClaim
 d.daily.streak=streak+1; d.daily.lastClaim=today
 if not RiftData.Grant(p,nr.shards,nr.cores,"daily","daily") then d.daily.streak=ps; d.daily.lastClaim=pl0; return fail("NOT_LOADED") end
 RiftData.SaveSoon(p)
 local _,s2,_,nx=streakInfo(d)
 return {ok=true,code="OK",shards=d.shards,cores=d.cores,streak=s2,reward=nr,nextReward=nx,day=((s2-1)%#Config.STREAK)+1}
end

Shop.OnServerInvoke=function(p,action,payload)
 local r=rs(p)
 local now=os.clock()
 if now<r.block then return fail("RATE") end
 -- token bucket
 r.tok=math.min(BUCKET,r.tok+(now-r.t)*REFILL); r.t=now
 if r.tok<1 then strike(p,r) return fail("RATE") end
 r.tok-=1
 if not validate(action,payload) then strike(p,r) return fail("BAD_ARGS") end
 -- slow actions: 1 per 2 s
 if action=="snapshot" or action=="claimDaily" then
  local last=r.last[action]
  if last and now-last<SLOW then
   if action=="claimDaily" then return fail("RATE") end
   if r.snap then return r.snap end -- cached copy; rebuilt only if a change invalidated it
  else r.last[action]=now end
 end
 if action=="snapshot" then
  local ok,res=pcall(snapshot,p)
  if not ok then warn("[RiftShop] snapshot: "..tostring(res)) return fail("ERROR") end
  if res.ok then r.snap=res end
  return res
 end
 if r.busy then return fail("BUSY") end
 r.busy=true
 local fn=action=="purchase" and purchase or action=="equipSkin" and equipSkin or claimDaily
 local ok,res=pcall(fn,p,payload)
 r.busy=false
 if not ok then warn("[RiftShop] "..action..": "..tostring(res)) return fail("ERROR") end
 if res.ok then r.snap=nil end -- invalidate cached snapshot after a change
 return res
end

Players.PlayerRemoving:Connect(function(p) R[p]=nil end)
