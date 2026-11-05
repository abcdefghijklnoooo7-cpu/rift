-- One owner arbitrates modals, including match voting and the scoreboard.
local Tween=game:GetService("TweenService")
local Controller={screens={},active=nil}
function Controller:Register(name,view,priority,changed)
 assert(not self.screens[name],"Duplicate UI screen: "..name)
 self.screens[name]={view=view,priority=priority or 0,wanted=false,changed=changed}
 view.Visible=false
end
function Controller:Set(name,wanted)
 local screen=assert(self.screens[name],"Unknown UI screen: "..name)
 if screen.wanted==wanted then return end
 screen.wanted=wanted
 local best,bestPriority=nil,-math.huge
 for key,item in self.screens do
  if item.wanted and item.priority>bestPriority then best,bestPriority=key,item.priority end
 end
 if self.active==best then return end
 self.active=best
 for key,item in self.screens do
  local visible=key==best
  item.view.Interactable=visible
  if item.tween then item.tween:Cancel(); item.tween=nil end
  item.generation=(item.generation or 0)+1
  local generation=item.generation
  if item.view:IsA("CanvasGroup") then
   if visible then item.view.Visible=true; item.view.GroupTransparency=1 end
   item.tween=Tween:Create(item.view,TweenInfo.new(.2,Enum.EasingStyle.Quad),{GroupTransparency=visible and 0 or 1})
   item.tween:Play()
   if not visible then task.delay(.2,function() if item.generation==generation then item.view.Visible=false end end) end
  else item.view.Visible=visible end
  if item.changed then item.changed(visible) end
 end
 game.Players.LocalPlayer:SetAttribute("RiftModalOpen",best)
end
return Controller
