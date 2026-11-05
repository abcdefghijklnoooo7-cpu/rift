local player=game.Players.LocalPlayer
local UI=require(game.ReplicatedStorage:WaitForChild("RiftUI"))
local Controller=require(game.ReplicatedStorage:WaitForChild("RiftUIController"))
local C=UI.C
local queue=game.ReplicatedStorage:WaitForChild("RiftQueue")
local input=game:GetService("UserInputService")
local run=game:GetService("RunService")
local http=game:GetService("HttpService")
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false)
local gui=Instance.new("ScreenGui"); gui.Name="RiftDuelHUD"; gui.DisplayOrder=25; gui.ResetOnSpawn=false; gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets; gui.Parent=player:WaitForChild("PlayerGui")
local function panel(name,width,height)
 local f=UI.frame(gui,name,0,0,0,height); f.Size=UDim2.new(.9,0,0,height); f.Position=UDim2.fromScale(.5,.5); f.AnchorPoint=Vector2.new(.5,.5); UI.surface(f)
 local max=Instance.new("UISizeConstraint"); max.MaxSize=Vector2.new(width,height); max.Parent=f; return f
end
local banner=panel("MatchStatus",440,56); banner.Position=UDim2.new(.5,0,0,8); banner.AnchorPoint=Vector2.new(.5,0)
local status=UI.text(banner,"",16,8,0,40,16); status.Size=UDim2.new(1,-32,1,-16); status.TextWrapped=true; status.TextXAlignment=Enum.TextXAlignment.Center
local vote=panel("MapVote",480,264)
UI.text(vote,"Choose a map",16,12,300,32,20,C.text,true)
local voteButtons={}
local board=panel("Scoreboard",520,328)
UI.text(board,"Match scoreboard",16,12,280,32,20,C.text,true)
local function cell(parent,text,x,width,y,bold)
 local l=UI.text(parent,text,0,y,0,32,13,C.text,bold); l.Position=UDim2.new(x,0,0,y); l.Size=UDim2.new(width,0,0,32); return l
end
cell(board,"Player",.04,.48,48,true)
for i,title in {"K","D","W"} do local t=cell(board,title,.52+(i-1)*.15,.14,48,true); t.TextXAlignment=Enum.TextXAlignment.Center end
local cells={}
for i=1,6 do
 local row={cell(board,"",.04,.48,80+(i-1)*36)}
 row[1].TextTruncate=Enum.TextTruncate.AtEnd
 for col=1,3 do row[col+1]=cell(board,"",.52+(col-1)*.15,.14,80+(i-1)*36); row[col+1].TextXAlignment=Enum.TextXAlignment.Center end
 cells[i]=row
end
Controller:Register("Vote",vote,30)
Controller:Register("Scoreboard",board,10)
local scoreboardHeld=false
local scoreboardPinned=false
local scoreButton=UI.button(gui,"Score",0,8,72,48,function() scoreboardPinned=not scoreboardPinned end)
scoreButton.Position=UDim2.new(1,-88,0,8)
local voting={}
local picked
local lastPhase
local function readAttribute(name)
 local source=player:GetAttribute(name)
 local ok,value=pcall(function() return source and http:JSONDecode(source) or {} end)
 return ok and value or {}
end
local function choose(index)
 if player:GetAttribute("RiftDuelPhase")~="Voting" or not voting[index] then return end
 picked=voting[index].name; queue:FireServer("vote",picked)
 for i,b in voteButtons do UI.select(b,voting[i] and voting[i].name==picked) end
end
for i=1,3 do
 local b=UI.button(vote,"",16,56+(i-1)*56,0,48,function() choose(i) end)
 b.Size=UDim2.new(1,-32,0,48); voteButtons[i]=b
end
local function refreshVotes()
 voting=readAttribute("RiftVoteMaps")
 for i,b in voteButtons do
  local option=voting[i]; b.Visible=option~=nil
  if option then b.Text=option.name.." · "..option.count.." votes"; UI.select(b,picked==option.name) end
 end
end
local function refreshScoreboard()
 local stats=readAttribute("RiftScoreboard")
 table.sort(stats,function(a,b) return a.team<b.team end)
 for i,row in cells do
  local info=stats[i]
  for _,label in row do label.Visible=info~=nil end
  if info then
   row[1].Text=(info.team==1 and "A · " or "B · ")..info.name; row[2].Text=tostring(info.kills); row[3].Text=tostring(info.deaths); row[4].Text=tostring(info.wins)
   row[1].Font=info.name==player.Name and Enum.Font.GothamBold or Enum.Font.Gotham
  end
 end
end
player:GetAttributeChangedSignal("RiftVoteMaps"):Connect(refreshVotes)
player:GetAttributeChangedSignal("RiftScoreboard"):Connect(refreshScoreboard)
refreshVotes(); refreshScoreboard()
local numberKeys={[Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,[Enum.KeyCode.Three]=3}
input.InputBegan:Connect(function(key,processed)
 if processed or player:GetAttribute("RiftMenuOpen") then return end
 if key.KeyCode==Enum.KeyCode.Tab then scoreboardHeld=true end
 if player:GetAttribute("RiftDuelPhase")=="Voting" then choose(numberKeys[key.KeyCode]); return end
 if player:GetAttribute("RiftMap")~="Lobby" then return end
 local mode=player:GetAttribute("RiftSelectedMode") or 1
 if key.KeyCode==Enum.KeyCode.J then queue:FireServer("queue",mode)
 elseif key.KeyCode==Enum.KeyCode.N and not player:GetAttribute("RiftQueued") then mode=mode%3+1; player:SetAttribute("RiftSelectedMode",mode); queue:FireServer("mode",mode) end
end)
input.InputEnded:Connect(function(key) if key.KeyCode==Enum.KeyCode.Tab then scoreboardHeld=false end end)
input.WindowFocusReleased:Connect(function() scoreboardHeld=false end)
run.RenderStepped:Connect(function()
 local phase=player:GetAttribute("RiftDuelPhase")
 if phase~=lastPhase then
  if phase=="Voting" then picked=nil; refreshVotes() end
  if phase=="Finished" and lastPhase~="Finished" and player:GetAttribute("RiftDuelMessage")~="DEFEAT" then UI.reward() end
  scoreboardPinned=false; lastPhase=phase
 end
 Controller:Set("Vote",phase=="Voting")
 Controller:Set("Scoreboard",phase~=nil and phase~="Voting" and (scoreboardHeld or scoreboardPinned or phase=="Finished"))
 local clear=not player:GetAttribute("RiftMenuOpen")
 banner.Visible=phase~=nil and clear
 scoreButton.Visible=phase~=nil and phase~="Voting" and Controller.active~="Menu"
 if not banner.Visible then return end
 local seconds=math.max(0,math.ceil((player:GetAttribute("RiftDuelDeadline") or 0)-workspace:GetServerTimeNow()))
 local score=player:GetAttribute("RiftDuelScore") or "0 – 0"
 local message=player:GetAttribute("RiftDuelMessage") or ""
 status.TextColor3=C.text
 if phase=="Voting" then status.Text="Choose a map · "..seconds.."s"
 elseif phase=="Finished" then
  status.Text=message.." · "..score.." · Lobby in "..seconds.."s"
  status.TextColor3=message=="DEFEAT" and C.danger or C.success
 else
  local detail=phase=="Countdown" and ("Starts in "..seconds.."s") or (player:GetAttribute("RiftRoundAlive") and (seconds.."s") or "Respawn next round")
  status.Text=(player:GetAttribute("RiftTeam")==1 and "Team A · " or "Team B · ")..score.." · "..(player:GetAttribute("RiftDuelArena") or "Match").."\n"..detail
 end
end)
