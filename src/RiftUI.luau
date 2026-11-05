local Tween=game:GetService("TweenService")
local Sound=game:GetService("SoundService")
local UI={C=require(script.Parent:WaitForChild("RiftTheme"))}
local C=UI.C
local click=Instance.new("Sound")
click.Name="RiftUIClick"; click.SoundId="rbxasset://sounds/volume_slider.ogg"; click.Volume=.08; click.Parent=Sound
local reward=click:Clone(); reward.Name="RiftUIReward"; reward.PlaybackSpeed=1.5; reward.Parent=Sound
function UI.reward() reward.Volume=.08*(game.Players.LocalPlayer:GetAttribute("RiftVolume") or 1); reward:Play() end
function UI.corner(object,radius)
 local c=object:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
 c.CornerRadius=UDim.new(0,radius or 12); c.Parent=object
end
function UI.frame(parent,name,x,y,w,h,color)
 local f=Instance.new("Frame"); f.Name=name; f.Position=UDim2.fromOffset(x,y); f.Size=UDim2.fromOffset(w,h)
 f.BorderSizePixel=0; f.BackgroundColor3=color or C.panel; f.Parent=parent; return f
end
function UI.surface(object)
 object.BorderSizePixel=0; object.BackgroundColor3=C.panel; UI.corner(object)
 local s=object:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
 s.Color=C.text; s.Transparency=.85; s.Thickness=1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=object
end
function UI.padding(object,n)
 local p=Instance.new("UIPadding"); for _,side in {"Top","Bottom","Left","Right"} do p["Padding"..side]=UDim.new(0,n or 16) end; p.Parent=object; return p
end
function UI.typeSize(size)
 if size>=28 then return 32 elseif size>=19 then return 20 elseif size>=14 then return 16 else return 13 end
end
function UI.text(parent,caption,x,y,w,h,size,color,bold)
 local t=Instance.new("TextLabel"); t.Text=caption; t.BackgroundTransparency=1; t.BorderSizePixel=0
 t.Position=UDim2.fromOffset(x,y); t.Size=UDim2.fromOffset(w,h); t.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
 t.TextStrokeTransparency=1; t.TextSize=UI.typeSize(size or 16); t.TextColor3=color or C.text; t.TextXAlignment=Enum.TextXAlignment.Left
 t.TextYAlignment=Enum.TextYAlignment.Center; t.Parent=parent; return t
end
function UI.button(parent,caption,x,y,w,h,callback,primary)
 local b=Instance.new("TextButton"); b.Name=caption; b.Text=caption; b.Position=UDim2.fromOffset(x,y); b.Size=UDim2.fromOffset(math.max(w,44),math.max(h,44))
 b.AutoButtonColor=false; b.BackgroundColor3=primary and C.accent or C.panel; b.BorderSizePixel=0
 b.TextColor3=primary and C.panel or C.text; b.Font=Enum.Font.Gotham; b.TextSize=16; b.Parent=parent; UI.corner(b,8)
 local stroke=Instance.new("UIStroke"); stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; stroke.Color=C.text; stroke.Transparency=primary and 1 or .82; stroke.Parent=b
 local press=Instance.new("UIScale"); press.Name="PressScale"; press.Parent=b
 local anim
 local function scale(value)
  if anim then anim:Cancel() end
  anim=Tween:Create(press,TweenInfo.new(.12,Enum.EasingStyle.Quad),{Scale=value}); anim:Play()
 end
 b.MouseButton1Down:Connect(function() if b.Active then scale(.95) end end)
 b.MouseButton1Up:Connect(function() scale(1) end)
 b.MouseLeave:Connect(function() scale(1) end)
 b.Activated:Connect(function()
  if b.Active then
   scale(1); click.Volume=.08*(game.Players.LocalPlayer:GetAttribute("RiftVolume") or 1); click:Play(); callback()
  end
 end)
 return b
end
function UI.select(button,selected)
 button:SetAttribute("Selected",selected); button.BackgroundColor3=selected and C.background or C.panel
 button.TextColor3=selected and C.panel or C.text
end
function UI.line(parent,x,y,w)
 local f=UI.frame(parent,"Divider",x,y,w,1,C.text); f.BackgroundTransparency=.85; return f
end
return UI
