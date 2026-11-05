local E={}
function E.Build()
 local function sign(root,title,pos)
  local p=Instance.new('Part');p.Name='Facility wayfinding';p.Size=Vector3.new(20,3,.2);p.Position=pos;p.Color=Color3.fromRGB(34,52,62);p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.Parent=root
  local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(900,130);gui.Parent=p
  local t=Instance.new('TextLabel');t.BackgroundTransparency=1;t.Size=UDim2.fromScale(1,1);t.TextColor3=Color3.fromRGB(199,222,218);t.Font=Enum.Font.GothamBold;t.TextScaled=true;t.Text=title;t.Parent=gui
 end
 for _,root in {workspace.RiftMaps,workspace.RiftDuels} do for _,map in root:GetChildren() do local spawn=map:GetAttribute('Spawn') or map:GetAttribute('SpawnA');sign(map,map.Name:upper()..' / RIFT',Vector3.new(spawn.X,19,121)) end end
 for i,x in {-110,-66,-22,22,66,110} do
  sign(workspace.RiftArena,'0'..i..' / LIVE FIRE',Vector3.new(x,29,-5))
  sign(workspace.RiftArena,'PRECISION / 225',Vector3.new(x,22,-244))
 end
 sign(workspace.RiftArena,'RIFT / TACTICAL TRAINING',Vector3.new(0,24,125))
end
return E
