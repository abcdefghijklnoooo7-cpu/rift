local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local remote=game.ReplicatedStorage.RiftQueue
local resetCombat=script.Parent.RiftResetCombat
local eliminated=script.Parent.RiftElimination
local damaged=script.Parent.RiftDamage
local matchResult=script.Parent.RiftMatchResult
local lobby=workspace.RiftLobby
-- Every map with team spawns (SpawnA/SpawnB) is a duel arena: the RiftDuels maps plus the RiftMaps explore maps.
local arenas={}
for _,folder in {workspace.RiftDuels,workspace.RiftMaps} do
 for _,arena in folder:GetChildren() do
  if arena:GetAttribute("SpawnA") and arena:GetAttribute("SpawnB") then table.insert(arenas,arena) end
 end
end
table.sort(arenas,function(a,b) return a.Name<b.Name end)

local winsRequired=5
local roundSeconds=40
local queues={{},{},{}}
local queued={}
local occupied={}
local matches={}
local requestAt={}
local nextId=0
local votingMatch
local updateVote -- defined below; used by finish() to refresh the ballot when an arena frees up

local function living(player)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if humanoid and humanoid.Health>0 and root then return character,humanoid,root end
end

local function returnToLobby(player)
 player:SetAttribute("RiftMap","Lobby")
 local character,humanoid,root=living(player)
 if character then
  character:PivotTo(lobby.LobbySpawn.CFrame+Vector3.new(0,3,0))
  root.AssemblyLinearVelocity=Vector3.zero
  root.Anchored=false
  humanoid.Health=humanoid.MaxHealth
  resetCombat:Fire(player)
 end
end

local function broadcastQueue(size)
 workspace:SetAttribute("RiftQueueCount"..size,#queues[size])
end

local function removeFromQueue(player)
 local size=queued[player]
 if size then
  local index=table.find(queues[size],player)
  if index then table.remove(queues[size],index) end
  queued[player]=nil
  broadcastQueue(size)
 end
 player:SetAttribute("RiftQueued",false)
end

local function scoreboard(match)
 local rows={}
 for _,player in match.players do
  local stats=match.stats[player]
  table.insert(rows,{
   name=player.DisplayName,
   team=match.teams[player],
   kills=stats.kills,
   deaths=stats.deaths,
   wins=player:GetAttribute("RiftMatchWins") or 0,
  })
 end
 local data=Http:JSONEncode(rows)
 for _,player in match.players do
  if player.Parent==Players then player:SetAttribute("RiftScoreboard",data) end
 end
end

-- Fight-time bookkeeping for the economy's counted-match rule (closeFight is idempotent).
local function closeFight(match)
 if match.fightStart then match.fightSeconds+=os.clock()-match.fightStart; match.fightStart=nil end
end

local function status(match,phase,seconds,message,winner)
 if phase~="Fight" then closeFight(match) elseif not match.fightStart then match.fightStart=os.clock() end
 match.phase=phase
 local deadline=workspace:GetServerTimeNow()+seconds
 for _,player in match.players do
  if player.Parent~=Players then continue end
  local team=match.teams[player]
  player:SetAttribute("RiftDuelPhase",phase)
  player:SetAttribute("RiftDuelDeadline",deadline)
  player:SetAttribute("RiftDuelScore",string.format("%d  –  %d",match.score[team],match.score[3-team]))
  player:SetAttribute("RiftDuelMessage",phase=="Finished" and winner and (team==winner and "VICTORY" or "DEFEAT") or message)
 end
end

local function clearRound(match)
 for _,connection in match.deaths do connection:Disconnect() end
 table.clear(match.deaths)
 for _,player in match.players do
  match.alive[player]=nil
  if player.Parent==Players then player:SetAttribute("RiftRoundAlive",false) end
 end
 if match.effects then
  match.effects:Destroy()
  match.effects=nil
 end
end

local function finish(match,message,winner)
 if match.phase=="Finished" then return end
 closeFight(match)
 if votingMatch==match then votingMatch=nil end
 clearRound(match)
 if winner then
  for _,player in match.players do
   if player.Parent==Players and match.teams[player]==winner then
    player:SetAttribute("RiftMatchWins",(player:GetAttribute("RiftMatchWins") or 0)+1)
   end
  end
 end
 status(match,"Finished",4,message,winner)
 scoreboard(match)
 -- Economy summary (escrow payout happens in RiftEconomy; only players still present are listed).
 -- Bindables stringify Instance keys, so entries/userTeams carry the same data in transport-safe form.
 local present,teams,stats,entries,userTeams={},{},{},{},{}
 for _,player in match.players do
  userTeams[tostring(player.UserId)]=match.teams[player]
  if player.Parent~=Players then continue end
  local s=match.stats[player]
  local copy={kills=s.kills,deaths=s.deaths,victims=table.clone(s.victims),damage=s.damage}
  table.insert(present,player)
  teams[player]=match.teams[player]
  stats[player]=copy
  table.insert(entries,{player=player,team=match.teams[player],stats=copy})
 end
 message=message or ""
 local ok,err=pcall(function()
  matchResult:Fire({id=match.id,size=match.size,players=present,teams=teams,winner=winner,message=message,
   forfeit=message:find("forfeit")~=nil,timedOut=message:find("respawn timed out")~=nil,
   rounds=match.round,fightSeconds=match.fightSeconds,roundWinners=table.clone(match.roundWinners),
   score={match.score[1],match.score[2]},stats=stats,entries=entries,userTeams=userTeams,
   private=game.PrivateServerId~="" and game.PrivateServerOwnerId~=0})
 end)
 if not ok then warn("[RiftDuel] RiftMatchResult fire failed: "..tostring(err)) end
 task.delay(4,function()
  for _,player in match.players do
   matches[player]=nil
   if player.Parent~=Players then continue end
   for _,attribute in {"RiftDuelId","RiftDuelPhase","RiftDuelArena","RiftTeam","RiftVoteMaps","RiftScoreboard","RiftRoundAlive"} do
    player:SetAttribute(attribute,nil)
   end
   returnToLobby(player)
  end
  if match.arena then occupied[match.arena]=nil; match.arena:SetAttribute("RiftInUse",nil) end
  if votingMatch then updateVote(votingMatch) end
 end)
end

local startRound
local function endRound(match,winner)
 if match.phase~="Fight" then return end
 closeFight(match)
 clearRound(match)
 local message="Round drawn"
 match.roundWinners[match.round]=winner or 0
 if winner then match.score[winner]+=1 end
 -- Per-player round result for the client's round-end banner + stinger (RiftRoundSeq changes every round).
 for _,player in match.players do
  if player.Parent==Players then
   local team=match.teams[player]
   player:SetAttribute("RiftRoundResult",winner==nil and "draw" or (team==winner and "won" or "lost"))
   player:SetAttribute("RiftRoundSeq",(player:GetAttribute("RiftRoundSeq") or 0)+1)
  end
 end
 if winner then
  message=winner==1 and "Blue wins the round" or "Orange wins the round"
  if match.score[winner]>=winsRequired then
   finish(match,message,winner)
   return
  end
 end
 status(match,"Intermission",3.5,message)
 task.delay(3.5,function()
  if match.phase=="Intermission" then startRound(match) end
 end)
end

local function liveTotals(match)
 local count={0,0}
 local health={0,0}
 for _,player in match.players do
  if not match.alive[player] or player.Parent~=Players then continue end
  local _,humanoid=living(player)
  if humanoid then
   local team=match.teams[player]
   count[team]+=1
   health[team]+=humanoid.Health
  end
 end
 return count,health
end

local function resolveElimination(match)
 if match.phase~="Fight" then return end
 local count=liveTotals(match)
 if count[1]==0 or count[2]==0 then
  local winner
  if count[1]~=count[2] then winner=count[1]>0 and 1 or 2 end
  endRound(match,winner)
 end
end

startRound=function(match)
 match.round+=1
 status(match,"Preparing",0,"Preparing round "..match.round)
 local function ready()
  for _,player in match.players do
   if player.Parent==Players and not living(player) then return false end
  end
  return true
 end
 local limit=os.clock()+12
 while match.phase=="Preparing" and not ready() and os.clock()<limit do task.wait(.15) end
 if match.phase~="Preparing" then return end
 if not ready() then finish(match,"Match ended · respawn timed out"); return end

 local spawns={match.arena:GetAttribute("SpawnA"),match.arena:GetAttribute("SpawnB")}
 local offsets={0,0}
 local roots={}
 for _,player in match.players do
  if player.Parent~=Players then continue end
  local team=match.teams[player]
  local index=offsets[team]
  offsets[team]+=1
  local position=spawns[team]+Vector3.new((index-(match.size-1)*.5)*6,0,0)
  local character,humanoid,root=living(player)
  character:PivotTo(CFrame.lookAt(position,spawns[3-team]))
  root.AssemblyLinearVelocity=Vector3.zero
  root.Anchored=true
  table.insert(roots,root)
  humanoid.Health=humanoid.MaxHealth
  resetCombat:Fire(player)
  match.alive[player]=true
  player:SetAttribute("RiftRoundAlive",true)
  table.insert(match.deaths,humanoid.Died:Connect(function()
   if not match.alive[player] then return end
   match.alive[player]=nil
   player:SetAttribute("RiftRoundAlive",false)
   match.stats[player].deaths+=1
   scoreboard(match)
   task.defer(resolveElimination,match)
  end))
 end
 status(match,"Countdown",2.5,"Round "..match.round)
 task.wait(2.5)
 for _,root in roots do if root.Parent then root.Anchored=false end end
 if match.phase~="Countdown" then return end
 local effects=Instance.new("Folder")
 effects.Name="RoundEffects"
 effects.Parent=match.arena
 match.effects=effects
 status(match,"Fight",roundSeconds,"Round "..match.round)
 resolveElimination(match)
 local round=match.round
 task.delay(roundSeconds,function()
  if match.phase~="Fight" or match.round~=round then return end
  local alive,hp=liveTotals(match)
  local winner
  if alive[1]~=alive[2] then winner=alive[1]>alive[2] and 1 or 2
  elseif math.abs(hp[1]-hp[2])>.01 then winner=hp[1]>hp[2] and 1 or 2 end
  endRound(match,winner)
 end)
end

local function voteData(match)
 local counts={}
 for player,map in match.votes do
  if player.Parent==Players then counts[map]=(counts[map] or 0)+1 end
 end
 local data={}
 for _,arena in match.options do
  local busy=occupied[arena]~=nil and occupied[arena]~=match
  table.insert(data,{name=arena.Name,count=busy and 0 or (counts[arena.Name] or 0),busy=busy})
 end
 return data
end

updateVote=function(match)
 local encoded=Http:JSONEncode(voteData(match))
 for _,player in match.players do
  if player.Parent==Players then player:SetAttribute("RiftVoteMaps",encoded) end
 end
end

local function startVote(match)
 status(match,"Voting",8,"Vote for the arena")
 updateVote(match)
 task.delay(8,function()
  if match.phase~="Voting" then return end
  local results=voteData(match)
  local leaders={}
  local top=-1
  for index,entry in results do
   if entry.count>top then top=entry.count; table.clear(leaders) end
   if entry.count==top then table.insert(leaders,index) end
  end
  local open={}
  for _,index in leaders do if not occupied[match.options[index]] then table.insert(open,index) end end
  if #open==0 then for index,arena in match.options do if not occupied[arena] then table.insert(open,index) end end end
  if #open==0 then for index in match.options do table.insert(open,index) end end
  local arena=match.options[open[math.random(#open)]]
  match.arena=arena
  match.startedAt=os.clock()
  occupied[arena]=match
  arena:SetAttribute("RiftInUse",true)
  votingMatch=nil
  -- Explore maps double as arenas: send anyone exploring this map back to the lobby (RiftTravel blocks new arrivals while in use).
  if arena.Parent==workspace.RiftMaps then
   for _,other in Players:GetPlayers() do
    if other:GetAttribute("RiftMap")==arena.Name and not other:GetAttribute("RiftDuelId") then returnToLobby(other) end
   end
  end
  for _,player in match.players do
   if player.Parent==Players then
    player:SetAttribute("RiftDuelArena",arena.Name)
    player:SetAttribute("RiftVoteMaps",nil)
   end
  end
  startRound(match)
 end)
end

local function matchmake()
 if votingMatch then return end
 local free={}
 for _,arena in arenas do if not occupied[arena] then table.insert(free,arena) end end
 if #free==0 then return end
 for size=3,1,-1 do
  local queue=queues[size]
  if #queue<size*2 then continue end
  local match={size=size,players={},teams={},stats={},alive={},score={0,0},round=0,deaths={},options=table.clone(arenas),votes={},fightSeconds=0,roundWinners={}}
  votingMatch=match
  nextId+=1
  match.id=nextId
  for index=1,size*2 do
   local player=queue[1]
   removeFromQueue(player)
   table.insert(match.players,player)
   local team=(index-1)%2+1
   match.teams[player]=team
   match.stats[player]={kills=0,deaths=0,victims={},damage=0}
   matches[player]=match
   player:SetAttribute("RiftDuelId",nextId)
   player:SetAttribute("RiftTeam",team)
   player:SetAttribute("RiftMap",nil)
   player:SetAttribute("RiftRoundAlive",false)
  end
  scoreboard(match)
  startVote(match)
  return
 end
end

local function toggleQueue(player,size)
 if matches[player] or player:GetAttribute("RiftMap")~="Lobby" then return end
 if size~=1 and size~=2 and size~=3 then return end
 local _,_,root=living(player)
 -- Must be inside the lobby hall (the old 113-stud radius from the spawn excluded the queue terminal itself).
 local offset=root and lobby:GetPivot():PointToObjectSpace(root.Position)
 if not root or math.abs(offset.X)>130 or math.abs(offset.Z)>100 then return end
 local now=os.clock()
 if now-(requestAt[player] or -10)<.5 then return end
 requestAt[player]=now
 if queued[player] then
  removeFromQueue(player)
 else
  table.insert(queues[size],player)
  queued[player]=size
  player:SetAttribute("RiftQueueSize",size)
  player:SetAttribute("RiftQueued",true)
  broadcastQueue(size)
  matchmake()
 end
end

local function bind(player)
 if player:GetAttribute("RiftMap")==nil then player:SetAttribute("RiftMap","Lobby") end
 player.CharacterAdded:Connect(function() removeFromQueue(player) end)
end
Players.PlayerAdded:Connect(bind)
for _,player in Players:GetPlayers() do bind(player) end
Players.PlayerRemoving:Connect(function(player)
 removeFromQueue(player)
 requestAt[player]=nil
 local match=matches[player]
 if not match or match.phase=="Finished" then return end
 match.alive[player]=nil
 local team=match.teams[player]
 for _,teammate in match.players do
  if teammate~=player and teammate.Parent==Players and match.teams[teammate]==team then
   resolveElimination(match)
   return
  end
 end
 finish(match,"Match ended by forfeit",3-team)
end)

eliminated.Event:Connect(function(attacker,victim)
 local match=matches[attacker]
 if not match or match.phase~="Fight" or matches[victim]~=match or match.teams[attacker]==match.teams[victim] then return end
 match.stats[attacker].kills+=1
 table.insert(match.stats[attacker].victims,victim.UserId)
 scoreboard(match)
end)
-- Activity signal for the economy (AFK rule): damage dealt to opponents in the same match.
damaged.Event:Connect(function(attacker,victim,dealt)
 local match=matches[attacker]
 if not match or matches[victim]~=match or match.teams[attacker]==match.teams[victim] or type(dealt)~="number" or dealt~=dealt then return end
 match.stats[attacker].damage+=math.max(dealt,0)
end)

remote.OnServerEvent:Connect(function(player,action,value)
 if action=="mode" then
  if not queued[player] and not matches[player] and player:GetAttribute("RiftMap")=="Lobby" and (value==1 or value==2 or value==3) then
   player:SetAttribute("RiftQueueSize",value)
  end
 elseif action=="vote" then
  local match=matches[player]
  if not match or match.phase~="Voting" or typeof(value)~="string" then return end
  for _,arena in match.options do
   if arena.Name==value and match.votes[player]~=value and not (occupied[arena] and occupied[arena]~=match) then
    match.votes[player]=value
    updateVote(match)
    return
   end
  end
 elseif action==nil or action=="queue" then
  toggleQueue(player,value or 1)
 end
end)
-- Queue pads: standing on a pad queues you for that mode; stepping off leaves the queue.
-- Players who queued from the menu or terminal are not removed just for being off a pad.
local pads={}
for _,pad in lobby:WaitForChild("QueuePads"):GetChildren() do
 table.insert(pads,{size=pad:GetAttribute("QueueSize"),center=pad:GetAttribute("Center")})
end
local padQueued={}
local function padUnder(root)
 for _,pad in pads do
  local d=root.Position-pad.center
  if Vector2.new(d.X,d.Z).Magnitude<=6 and d.Y>-1 and d.Y<8 then return pad.size end
 end
end
task.spawn(function()
 while task.wait(.2) do
  for _,player in Players:GetPlayers() do
   if matches[player] or player:GetAttribute("RiftMap")~="Lobby" then padQueued[player]=nil; continue end
   local _,_,root=living(player)
   local size=root and padUnder(root)
   if size then
    if queued[player]~=size then
     if queued[player] then removeFromQueue(player) end
     requestAt[player]=nil
     toggleQueue(player,size)
     if queued[player]==size then padQueued[player]=true end
    end
   elseif padQueued[player] then
    padQueued[player]=nil
    if queued[player] then removeFromQueue(player) end
   end
  end
 end
end)
Players.PlayerRemoving:Connect(function(player) padQueued[player]=nil end)

lobby.QueueTerminal.JoinDuel.Triggered:Connect(function(player)
 toggleQueue(player,player:GetAttribute("RiftQueueSize") or 1)
end)
task.spawn(function()
 while task.wait(.5) do matchmake() end
end)
