local FX={}
local Debris=game:GetService('Debris')
local Tween=game:GetService('TweenService')
local active=0
local function node(pos)
 local p=Instance.new('Part');p.Name='Local gun effects';p.Size=Vector3.one*.1;p.Transparency=1;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Position=pos;p.Parent=workspace.CurrentCamera;Debris:AddItem(p,2);return p
end
local function particles(p,color,count,speed,smoke)
 local e=Instance.new('ParticleEmitter');e.Texture=smoke and 'rbxasset://textures/particles/smoke_main.dds' or 'rbxasset://textures/particles/sparkles_main.dds';e.Color=ColorSequence.new(color);e.Rate=0;e.Lifetime=NumberRange.new(smoke and .18 or .06,smoke and .4 or .15);e.Speed=NumberRange.new(speed*.5,speed);e.SpreadAngle=Vector2.new(30,30);e.LightEmission=smoke and 0 or .6;e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,smoke and .22 or .09),NumberSequenceKeypoint.new(1,smoke and .65 or 0)});e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.3),NumberSequenceKeypoint.new(1,1)});e.Parent=p;e:Emit(count)
end
function FX.Muzzle(position,w,direction)
 if w.item or active>24 then return end;active+=1;task.delay(.15,function()active-=1 end)
 local p=node(position);p.CFrame=CFrame.lookAt(position,position+direction)
 particles(p,Color3.fromRGB(255,210,128),w.family=='shotgun' and 7 or 3,9,false);particles(p,Color3.fromRGB(129,137,145),2,2,true)
 local l=Instance.new('PointLight');l.Color=Color3.fromRGB(255,196,113);l.Range=w.family=='sniper' and 11 or 7;l.Brightness=1.4;l.Shadows=false;l.Parent=p;Debris:AddItem(l,.045)
 if w.family~='launcher' then
  local shell=Instance.new('Part');shell.Name='Local casing';shell.Size=Vector3.new(.055,.055,.16);shell.Material=Enum.Material.Metal;shell.Color=Color3.fromRGB(178,142,75);shell.CanCollide=false;shell.CanQuery=false;shell.CanTouch=false;shell.CFrame=p.CFrame*CFrame.new(.12,-.15,.5);shell.Parent=workspace.CurrentCamera;shell.AssemblyLinearVelocity=p.CFrame.RightVector*8+Vector3.new(0,5,0);shell.AssemblyAngularVelocity=Vector3.new(12,8,4);Debris:AddItem(shell,.65)
 end
end
function FX.Impact(origin,position,normal,material,character)
 if (position-workspace.CurrentCamera.CFrame.Position).Magnitude>220 then return end
 local p=node(position+normal*.02);p.CFrame=CFrame.lookAt(p.Position,p.Position+normal)
 local metal=material==Enum.Material.Metal or material==Enum.Material.DiamondPlate
 local wood=material==Enum.Material.Wood or material==Enum.Material.WoodPlanks
 particles(p,character and Color3.fromRGB(168,220,218) or (metal and Color3.fromRGB(255,207,114) or (wood and Color3.fromRGB(156,118,77) or Color3.fromRGB(151,151,143))),metal and 9 or 5,metal and 15 or 7,not metal)
 local sound=Instance.new("Sound");sound.SoundId=metal and "rbxasset://sounds/action_footsteps_metal.mp3" or (wood and "rbxasset://sounds/action_footsteps_wood.mp3" or "rbxasset://sounds/action_footsteps_plastic.mp3");sound.Volume=character and .045 or .12;sound.PlaybackSpeed=metal and 1.7 or (wood and 1.3 or 1.9);sound.RollOffMinDistance=5;sound.RollOffMaxDistance=65;sound.SoundGroup=game:GetService("SoundService"):FindFirstChild("RiftEffects");sound.Parent=p;sound:Play()
 local d=(position-origin).Magnitude
 if d>.1 then
  local beam=Instance.new('Part');beam.Name='Local tracer';beam.Anchored=true;beam.CanCollide=false;beam.CanTouch=false;beam.CanQuery=false;beam.Material=Enum.Material.Neon;beam.Color=Color3.fromRGB(255,219,157);beam.Size=Vector3.new(.025,.025,math.min(d,20));beam.CFrame=CFrame.lookAt(position,origin)*CFrame.new(0,0,-math.min(d,20)/2);beam.Transparency=.3;beam.Parent=workspace.CurrentCamera;Tween:Create(beam,TweenInfo.new(.07),{Transparency=1}):Play();Debris:AddItem(beam,.09)
 end
 if not character then
  local mark=Instance.new('Part');mark.Name='Local impact mark';mark.Size=Vector3.new(.13,.13,.015);mark.CFrame=p.CFrame;mark.Anchored=true;mark.CanCollide=false;mark.CanTouch=false;mark.CanQuery=false;mark.Color=Color3.fromRGB(36,37,35);mark.Parent=workspace.CurrentCamera;Debris:AddItem(mark,3)
 end
end
return FX
