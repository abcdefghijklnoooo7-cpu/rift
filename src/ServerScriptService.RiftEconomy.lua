-- Match economy: escrowed payout at duel finish (spec "earning"). Client never reports anything.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local RiftData=require(script.Parent.RiftData)
local C=require(game.ReplicatedStorage.RiftEconomyConfig)
local matchResult=script.Parent.RiftMatchResult
local eliminated=script.Parent.RiftElimination
local IS_STUDIO=RunService:IsStudio()
local MAX_PAIRS=64

-- AccountAge cache so victims who already left can still be age-checked.
local ages={}
local function remember(p) if p.UserId then ages[p.UserId]=p.AccountAge end end
local function ageOk(uid)
 if IS_STUDIO and uid<=0 then return true end -- Studio test players have AccountAge 0
 local p=Players:GetPlayerByUserId(uid)
 local age=p and p.AccountAge or ages[uid]
 return age~=nil and age>=C.MIN_VICTIM_ACCOUNT_AGE
end

-- Live escrow display (RiftMatchEarn): bumps on duel kills, never credits.
local function clearEscrow(p) if p.Parent then p:SetAttribute("RiftMatchEarn",nil) end end
local function bind(p)
 remember(p)
 p:GetAttributeChangedSignal("RiftDuelId"):Connect(function()
  if p:GetAttribute("RiftDuelId")==nil then clearEscrow(p) end
 end)
end
Players.PlayerAdded:Connect(bind)
for _,p in Players:GetPlayers() do bind(p) end

eliminated.Event:Connect(function(attacker,victim)
 if typeof(attacker)~="Instance" or typeof(victim)~="Instance" or not attacker:IsA("Player") or not victim:IsA("Player") or attacker==victim then return end
 local id=attacker:GetAttribute("RiftDuelId")
 if id==nil or victim:GetAttribute("RiftDuelId")~=id or attacker:GetAttribute("RiftTeam")==victim:GetAttribute("RiftTeam") then return end
 if attacker:GetAttribute("RiftDuelPhase")~="Fight" then return end
 remember(victim)
 if not ageOk(victim.UserId) then return end
 attacker:SetAttribute("RiftMatchEarn",math.min((attacker:GetAttribute("RiftMatchEarn") or 0)+C.KILL,C.KILL_CAP*C.KILL))
end)

local function pairMult(n)
 for _,step in C.PAIR_STEPS do if n<=step.max then return step.mult end end
 return C.PAIR_STEPS[#C.PAIR_STEPS].mult
end

-- Daily soft cap: full rate to SOFT_CAP_FULL, then x SOFT_CAP_MULT until SOFT_CAP_REDUCED, then 0.
local function softCap(s,earned)
 local full=math.min(s,math.max(0,C.SOFT_CAP_FULL-earned))
 local rest=s-full
 local room=math.max(0,C.SOFT_CAP_REDUCED-math.max(earned+full,C.SOFT_CAP_FULL))
 return full+math.min(math.floor(rest*C.SOFT_CAP_MULT),room)
end

local function payOne(p,team,st,summary,counted)
 if not RiftData.CanSpend(p) then
  RiftData.Sync(p,"payout",{lines={},notes={"Progress offline - no rewards"},shards=0,cores=0})
  clearEscrow(p)
  return
 end
 local d=RiftData.Get(p)
 local today=RiftData.Today()
 if d.daily.day~=today then d.daily.day=today; d.daily.earned=0; d.daily.coresEarned=0 end
 for k,v in d.pairs do if type(v)~="table" or v.d~=today then d.pairs[k]=nil end end
 local won=summary.winner~=nil and summary.winner==team
 local active=(st.damage or 0)>0 or (st.kills or 0)>0
 local private=summary.private==true
 local userTeams=summary.userTeams or {}
 local lines,notes={},{}
 local s,c=0,0
 local pendingWinCores=0
 local bonus=0 -- one-time bonuses (firsts) bypass the per-match clamp/review
 local function line(label,amount) table.insert(lines,{label,amount}) end

 -- Kills: recorded in Fight, opposite team, victim AccountAge gate, capped.
 local kills=0
 for _,uid in st.victims or {} do
  local vt=userTeams[tostring(uid)]
  if uid~=p.UserId and (vt==nil or vt~=team) and ageOk(uid) then kills+=1 end
 end
 kills=math.min(kills,C.KILL_CAP)
 if kills>0 then line("Kills x"..kills,kills*C.KILL); s+=kills*C.KILL end
 -- Rounds won by this player's team.
 local roundsWon=(summary.score and summary.score[team]) or 0
 if roundsWon>0 then line("Rounds x"..roundsWon,roundsWon*C.ROUND_WIN); s+=roundsWon*C.ROUND_WIN end

 if counted and active then
  line("Match complete",C.MATCH_COMPLETE); s+=C.MATCH_COMPLETE
  if won then
   local winCores=math.max(0,math.min(C.MATCH_WIN_CORES,C.DAILY_WIN_CORE_CAP-d.daily.coresEarned))
   line("Match won",C.MATCH_WIN); s+=C.MATCH_WIN; c+=winCores
   if winCores<C.MATCH_WIN_CORES then table.insert(notes,"Daily win Core cap reached") end
   pendingWinCores=winCores
   if d.daily.firstWinDay~=today then
    line("First win today",C.FIRST_WIN_OF_DAY); s+=C.FIRST_WIN_OF_DAY; bonus+=C.FIRST_WIN_OF_DAY; c+=C.FIRST_WIN_OF_DAY_CORES
    if not private then d.daily.firstWinDay=today end
   end
   if not d.firsts.win then
    line("First win ever",C.FIRST_WIN_EVER); s+=C.FIRST_WIN_EVER; bonus+=C.FIRST_WIN_EVER; c+=C.FIRST_WIN_EVER_CORES
    if not private then d.firsts.win=true end
   end
  elseif roundsWon>0 then
   line("Loss bonus x"..roundsWon,roundsWon*C.LOSS_PER_ROUND); s+=roundsWon*C.LOSS_PER_ROUND
  end
  if not d.firsts.match then
   line("First match",C.FIRST_MATCH_EVER); s+=C.FIRST_MATCH_EVER; bonus+=C.FIRST_MATCH_EVER
   if not private then d.firsts.match=true end
  end
 elseif not counted then
  table.insert(notes,summary.timedOut and "Match timed out: kills and rounds only" or "Short match: kills and rounds only")
 else
  table.insert(notes,"No activity: no match bonus")
 end

 -- Multipliers, in order.
 -- a) private server
 if private then
  s=math.floor(s*C.PRIVATE_SERVER_MULT); c=math.floor(c*C.PRIVATE_SERVER_MULT)
  table.insert(notes,"Private server: no rewards")
 end
 -- b) repeat opponents (persisted per UTC day; only counted matches increment)
 local maxN=0
 for uidStr,t in userTeams do
  if t==team or uidStr==tostring(p.UserId) then continue end
  local e=d.pairs[uidStr]
  if counted and not private then
   if not e then
    local n=0 for _ in d.pairs do n+=1 end
    if n>=MAX_PAIRS then
     local lowK,lowN
     for k,v in d.pairs do if not lowN or v.n<lowN then lowK,lowN=k,v.n end end
     if lowK then d.pairs[lowK]=nil end
    end
    e={d=today,n=0}; d.pairs[uidStr]=e
   end
   e.n+=1
  end
  if e then maxN=math.max(maxN,e.n) end
 end
 local pm=pairMult(math.max(maxN,1))
 if pm<1 then
  s=math.floor(s*pm); c=math.floor(c*pm); bonus=math.floor(bonus*pm)
  table.insert(notes,"Repeat opponent x"..pm)
 end
 -- c) daily soft cap on match Shards
 local before=s
 s=softCap(s,d.daily.earned)
 if before>0 then bonus=math.floor(bonus*s/before) end
 if s<before then table.insert(notes,s==0 and "Daily Shard cap reached" or "Daily soft cap x"..C.SOFT_CAP_MULT) end
 -- d) sanity clamp + review flag
 local review=summary.size==1 and C.REVIEW_1V1 or C.REVIEW_TEAM
 if private then bonus=0 end
 local base=s-bonus
 if base>review then
  warn(("[RiftEconomy] review: %s earned %d Shards in match %s"):format(p.Name,base,tostring(summary.id)))
  d.flags.review=true
 end
 if base>C.MATCH_CLAMP then s=C.MATCH_CLAMP+bonus; table.insert(notes,"Match cap "..C.MATCH_CLAMP) end
 s,c=math.max(0,math.floor(s)),math.max(0,math.floor(c))

 -- Stats for counted matches only.
 if counted then
  local stats=d.stats
  stats.matches+=1
  if won then stats.wins+=1 end
  stats.roundsWon+=roundsWon
  stats.kills+=st.kills or 0
  stats.deaths+=st.deaths or 0
 end
 if s>0 or c>0 then
  if RiftData.Grant(p,s,c,"match") then d.daily.earned+=s; d.daily.coresEarned+=math.min(pendingWinCores,c)
  else s,c=0,0; table.insert(notes,"Progress offline - no rewards") end
 end
 RiftData.Mirror(p); RiftData.MarkDirty(p)
 RiftData.Sync(p,"payout",{lines=lines,notes=notes,shards=s,cores=c})
 RiftData.SaveNow(p)
 clearEscrow(p)
end

matchResult.Event:Connect(function(summary)
 if type(summary)~="table" then return end
 local counted=(summary.rounds or 0)>=C.COUNTED_MIN_ROUNDS and (summary.fightSeconds or 0)>=C.COUNTED_MIN_FIGHT_SECONDS and not summary.timedOut
 -- Forfeit wins only pay in full if the match already counted; uncounted pays kills/rounds only (handled by counted).
 -- Only players still present are paid (leavers forfeit everything).
 for _,e in summary.entries or {} do
  local p=e.player
  if typeof(p)~="Instance" or not p:IsA("Player") or p.Parent~=Players or type(e.stats)~="table" then continue end
  local ok,err=pcall(payOne,p,e.team,e.stats,summary,counted)
  if not ok then warn("[RiftEconomy] payout failed for "..p.Name..": "..tostring(err)); clearEscrow(p) end
 end
end)
