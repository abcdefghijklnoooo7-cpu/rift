-- Detailed original geometry shared by Arsenal previews and first-person models.
-- Flat BasePart hierarchy keeps the equipped-only renderer inexpensive.
local Models={}
function Models.create(w)
 local model=Instance.new("Model"); model.Name=w.name
 if w.name=="Fists" then model:SetAttribute("FistsModel",true) end
 local steel=Color3.fromRGB(150,158,164)
 local dark=Color3.fromRGB(27,32,36)
 local rubber=Color3.fromRGB(42,47,49)
 local trim=Color3.fromRGB(193,160,96)
 local paint=({Color3.fromRGB(113,130,116),Color3.fromRGB(101,120,137),Color3.fromRGB(144,119,92)})[(w.finish or 0)+1]
 local function shape(name,size,pos,color,material,rotation,class)
  local p=Instance.new(class or "Part"); p.Name=name;p.Size=size;p.Color=color or dark;p.Material=material or Enum.Material.Metal
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
  local cf=CFrame.new(pos)*(rotation or CFrame.identity)
  p:SetAttribute("Offset",pos);p:SetAttribute("LocalCFrame",cf);p:SetAttribute("Yaw",0)
  p.CFrame=cf;p.Parent=model;return p
 end
 local function box(n,x,y,z,px,py,pz,c,m,r) return shape(n,Vector3.new(x,y,z),Vector3.new(px,py,pz),c,m,r) end
 local rawBox=box
 local rounded={ ["Upper receiver"]=true,["Lower receiver"]=true,["Slide"]=true,["Frame"]=true,["Engine housing"]=true,["Lower crankcase"]=true,["Case body"]=true,["Lid"]=true,["Adjustable stock"]=true,["Recoil pad"]=true,["Moulded grip"]=true,["Shield core"]=true,["Forged head"]=true,["Belt box"]=true,["Magazine"]=true,["Handguard"]=true,["Rear handle"]=true }
 box=function(n,x,y,z,px,py,pz,c,m,r)
  if not rounded[n] or math.min(x,y,z)<.11 then return rawBox(n,x,y,z,px,py,pz,c,m,r) end
  local radius=math.min(.045,math.min(x,y,z)*.18)
  local cf=CFrame.new(px,py,pz)*(r or CFrame.identity)
  local function piece(suffix,size,offset,rotation,kind)
   local localCF=cf*CFrame.new(offset)*(rotation or CFrame.identity)
   local p=shape(n..suffix,size,localCF.Position,c,m,localCF.Rotation)
   if kind then p.Shape=kind end
   return p
  end
  local core=piece(" centre",Vector3.new(x-2*radius,y-2*radius,z),Vector3.zero)
  piece(" horizontal face",Vector3.new(x-2*radius,y,z-2*radius),Vector3.zero)
  piece(" vertical face",Vector3.new(x,y-2*radius,z-2*radius),Vector3.zero)
  local half=Vector3.new(x/2-radius,y/2-radius,z/2-radius)
  for _,a in {-1,1} do for _,b in {-1,1} do
   piece(" rounded X edge",Vector3.new(x-2*radius,2*radius,2*radius),Vector3.new(0,a*half.Y,b*half.Z),nil,Enum.PartType.Cylinder)
   piece(" rounded Y edge",Vector3.new(y-2*radius,2*radius,2*radius),Vector3.new(a*half.X,0,b*half.Z),CFrame.Angles(0,0,math.pi/2),Enum.PartType.Cylinder)
   piece(" rounded Z edge",Vector3.new(z-2*radius,2*radius,2*radius),Vector3.new(a*half.X,b*half.Y,0),CFrame.Angles(0,math.pi/2,0),Enum.PartType.Cylinder)
   for _,d in {-1,1} do piece(" corner",Vector3.one*(2*radius),Vector3.new(a*half.X,b*half.Y,d*half.Z),nil,Enum.PartType.Ball) end
  end end
  return core
 end
 local function tube(n,length,diameter,x,y,z,c,axis)
  local r=axis=="x" and CFrame.identity or axis=="y" and CFrame.Angles(0,0,math.pi/2) or CFrame.Angles(0,math.pi/2,0)
  local p=shape(n,Vector3.new(length,diameter,diameter),Vector3.new(x,y,z),c,Enum.Material.Metal,r);p.Shape=Enum.PartType.Cylinder;return p
 end
 local function ball(n,x,y,z,px,py,pz,c,m)
  local p=box(n,x,y,z,px,py,pz,c,m);p.Shape=Enum.PartType.Ball;return p
 end
 local function wedge(n,x,y,z,px,py,pz,c,r)
  return shape(n,Vector3.new(x,y,z),Vector3.new(px,py,pz),c,Enum.Material.Metal,r,"WedgePart")
 end
 local function bolt(x,y,z) tube("Flush fastener",.018,.065,x,y,z,steel,"x") end
 local function grip(x,y,z,height)
  box("Moulded grip",.23,height,.27,x,y,z,rubber,Enum.Material.SmoothPlastic,CFrame.Angles(-.15,0,0))
  for i=1,5 do box("Grip checkering",.244,.018,.19,x,y-height*.4+i*height*.13,z,rubber,Enum.Material.Fabric) end
 end
 local function rail(z,length,y)
  box("Rail spine",.22,.04,length,0,y,z,steel)
  for i=0,math.floor(length/.12) do box("Rail tooth",.27,.035,.055,0,y+.035,z-length/2+i*.12,dark) end
 end
 local function guard(z,y,width)
  box("Guard bottom",width,.035,.32,0,y-.16,z,steel)
  for _,side in {-1,1} do box("Guard side",.03,.2,.32,side*width/2,y-.06,z,dark) end
  box("Curved trigger",.04,.13,.045,0,y-.05,z+.035,steel,Enum.Material.Metal,CFrame.Angles(.25,0,0))
 end
 local function ring(n,cx,cy,cz,radius,axis,c)
  for i=0,63 do local a=i*math.pi/32
   if axis=="x" then box(n,.035,.05,radius*.1045,cx,cy+math.cos(a)*radius,cz+math.sin(a)*radius,c,nil,CFrame.Angles(a,0,0))
   else box(n,radius*.1045,.045,.035,cx+math.cos(a)*radius,cy+math.sin(a)*radius,cz,c,nil,CFrame.Angles(0,0,a+math.pi/2)) end
  end
 end
 local name,family=w.name,w.family
 if family=="melee" then
  if name=="Fists" then
   for _,side in {-1,1} do
    local x=side*.43
    local armSide=side==1 and "Right" or "Left"
    local cuff=box("Fingerless glove cuff",.39,.43,.42,x,-.34,.04,dark,Enum.Material.SmoothPlastic)
    for i=1,3 do box("Cuff rib",.402,.025,.432,x,-.49+i*.075,.04,rubber,Enum.Material.Fabric) end
    -- Exposed skin panel across the knuckles, recolored from this player's matching arm.
    local skin=box("Exposed knuckles",.43,.19,.19,x,.11,-.39,Color3.fromRGB(205,165,130),Enum.Material.SmoothPlastic,CFrame.Angles(0,0,side*.12));skin:SetAttribute("ArmSide",armSide)
    local glove=box("Fingerless glove back",.48,.34,.48,x,-.06,-.16,dark,Enum.Material.SmoothPlastic,CFrame.Angles(0,0,side*.08))
    -- Keep the skin panel visible as a broad band at the front edge of the glove.
    local skinBand=box("Exposed finger band",.445,.12,.055,x,.095,-.423,Color3.fromRGB(205,165,130),Enum.Material.SmoothPlastic);skinBand:SetAttribute("ArmSide",armSide)
    local thumb=ball("Glove thumb",.17,.25,.28,x-side*.23,-.03,-.12,dark,Enum.Material.SmoothPlastic)
    local thumbSkin=ball("Exposed thumb knuckle",.17,.12,.12,x-side*.25,.08,-.28,Color3.fromRGB(205,165,130),Enum.Material.SmoothPlastic);thumbSkin:SetAttribute("ArmSide",armSide)
   end
  elseif name=="Chainsaw" then
   box("Engine housing",.56,.48,.73,0,0,.03,paint,Enum.Material.SmoothPlastic)
   box("Lower crankcase",.53,.16,.65,0,-.28,.03,dark)
   ball("Chain bar nose",.12,.34,.37,0,.03,-1.77,steel)
   box("Guide bar",.1,.32,1.56,0,.03,-1.01,steel)
   for _,side in {-1,1} do
    box("Bar inset",.014,.16,1.37,side*.06,.03,-1.01,dark)
    for i=0,11 do
     wedge("Cutting tooth",.17,.07,.09,0,side*.21+.03,-.35-i*.12,steel,side==1 and CFrame.identity or CFrame.Angles(0,0,math.pi))
    end
    for i=0,6 do box("Cooling fin",.02,.025,.39,side*.29,-.13+i*.045,.11,dark) end
    bolt(side*.3,.12,-.12);bolt(side*.3,-.14,.25)
   end
   box("Hand guard",.72,.42,.07,0,.28,-.34,dark)
   for _,side in {-1,1} do box("Handle riser",.08,.34,.09,side*.29,.39,.1,rubber) end
   box("Top handle",.65,.09,.12,0,.58,.1,rubber)
   box("Rear handle",.23,.15,.56,0,-.08,.57,rubber)
   tube("Fuel cap",.06,.17,.12,.27,.24,trim,"y")
  elseif name=="Riot Shield" then
   box("Shield core",1.3,1.8,.13,0,.18,-.6,paint)
   for _,side in {-1,1} do
    box("Reinforced rim",.07,1.88,.2,side*.67,.18,-.6,dark)
    for i=0,4 do bolt(side*.64,-.6+i*.38,-.72) end
   end
   box("Top rim",1.32,.07,.2,0,1.12,-.6,dark);box("Bottom rim",1.32,.1,.2,0,-.76,-.6,dark)
   box("Viewport surround",.91,.36,.18,0,.63,-.69,dark)
   local glass=box("Armoured viewport",.76,.22,.04,0,.63,-.8,Color3.fromRGB(94,141,151),Enum.Material.Glass);glass.Transparency=.28
   box("Centre reinforcement",1.1,.14,.04,0,-.05,-.69,steel)
   grip(.18,.12,-.42,.5);box("Arm brace",.5,.12,.2,-.25,-.3,-.43,rubber)
  else
   local long=name=="Spear" or name=="Scythe"
   local shaft=long and 1.9 or 1.0
   tube("Handle core",shaft,.13,0,0,-shaft*.3,paint)
   for i=0,7 do tube("Wrapped handle band",.06,.17,0,0,.25-i*.09,rubber) end
   tube("Pommel",.1,.2,0,0,.35,trim)
   local tip=long and -1.8 or -1.0
   if name=="Maul" then
    box("Forged head",.9,.53,.45,0,0,tip,steel)
    for _,side in {-1,1} do box("Striking face",.13,.6,.52,side*.5,0,tip,dark);box("Head bevel",.95,.08,.32,0,side*.29,tip,paint) end
    tube("Head collar",.2,.24,0,0,tip+.25,trim)
   elseif name=="Battle Axe" or name=="Scythe" then
    local length=name=="Scythe" and 1.2 or .72
    box("Blade spine",length,.09,.26,length*.34,0,tip,steel)
    wedge("Forged tapered edge",length,.16,.65,length*.34,0,tip-.18,steel,CFrame.Angles(0,0,math.pi/2))
    wedge("Blade point",.45,.12,.5,length*.8,0,tip-.31,steel,CFrame.Angles(0,math.pi/2,0))
    box("Socket",.26,.22,.33,0,0,tip,paint)
   else
    local broad=name=="Trowel" and .5 or .25
    box("Blade spine",broad,.07,.6,0,0,tip,steel)
    wedge("Tapered blade tip",broad,.07,.44,0,0,tip-.5,steel,CFrame.Angles(0,0,math.pi))
    for _,side in {-1,1} do wedge("Sharpened bevel",.07,.06,.65,side*broad*.5,0,tip,Color3.fromRGB(204,209,210),CFrame.Angles(0,0,side*math.pi/2)) end
    box("Hand guard",.47,.1,.09,0,0,tip+.38,trim)
    if name=="Katana" then
     box("Long blade",.22,.065,1.2,0,0,tip-.75,steel)
     for i=0,4 do box("Handle binding",.18,.08,.05,0,0,.2-i*.13,dark,nil,CFrame.Angles(0,0,.4)) end
    end
   end
  end
 elseif family=="utility" then
  if name=="Medkit" or name=="Satchel" then
   box("Case body",.9,.57,.42,0,0,-.2,paint,Enum.Material.SmoothPlastic)
   box("Lid",.94,.13,.46,0,.34,-.2,dark)
   for _,side in {-1,1} do box("Corner bumper",.13,.65,.48,side*.44,0,-.2,rubber);box("Latch",.12,.2,.05,side*.24,.2,-.45,steel) end
   box("Carry handle",.4,.07,.1,0,.54,-.2,rubber)
   for _,side in {-1,1} do box("Handle mount",.06,.17,.1,side*.2,.43,-.2,steel) end
   if name=="Medkit" then box("Medical cross",.4,.12,.025,0,0,-.43,Color3.fromRGB(213,74,65));box("Medical cross upright",.12,.38,.025,0,0,-.44,Color3.fromRGB(213,74,65))
   else
    box("Detonator",.35,.22,.09,0,.02,-.46,dark);box("Status diode",.05,.05,.02,.1,.05,-.52,Color3.fromRGB(217,76,54),Enum.Material.Neon)
    for i=0,3 do tube("Charge cylinder",.65,.13,-.27+i*.18,-.04,-.2,steel,"y") end
   end
  elseif name=="Trowel" then box("Unused",.1,.1,.1,0,0,0,dark)
  elseif name=="Warper" or name=="Warpstone" then
   ball("Crystal core",.43,.65,.43,0,0,-.2,Color3.fromRGB(83,158,169),Enum.Material.Glass)
   for _,side in {-1,1} do box("Crystal cage",.055,.75,.07,side*.24,0,-.2,trim,nil,CFrame.Angles(0,0,-side*.12)) end
   tube("Base collar",.12,.61,0,-.38,-.2,dark,"y");tube("Top collar",.08,.44,0,.33,-.2,steel,"y")
   ring("Energy ring",0,0,-.2,.38,"z",trim)
  elseif name=="Subspace Tripmine" then
   tube("Mine casing",.18,.85,0,0,-.2,paint,"y");tube("Armour plate",.08,.7,0,.13,-.2,dark,"y")
   for i=0,5 do local a=i*math.pi/3;box("Sensor pod",.12,.12,.13,math.cos(a)*.31,.2,-.2+math.sin(a)*.31,steel) end
   ball("Sensor lens",.13,.07,.13,0,.2,-.2,Color3.fromRGB(221,73,52),Enum.Material.Neon)
  else
   local bottle=name=="Molotov" or name=="Elixir"
   if bottle then
    local glass= tube("Bottle body",.62,.43,0,-.04,-.2,name=="Molotov" and Color3.fromRGB(77,108,67) or Color3.fromRGB(72,150,166),"y");glass.Material=Enum.Material.Glass;glass.Transparency=.2
    ball("Bottle shoulder",.43,.26,.43,0,.28,-.2,glass.Color,Enum.Material.Glass)
    tube("Bottle neck",.32,.19,0,.5,-.2,glass.Color,"y")
    box("Paper label",.32,.27,.02,0,-.04,-.43,Color3.fromRGB(199,187,150),Enum.Material.Fabric)
    if name=="Molotov" then box("Cloth wick",.1,.4,.09,.04,.82,-.2,Color3.fromRGB(188,167,128),Enum.Material.Fabric,CFrame.Angles(0,0,-.3)) else tube("Stopper",.12,.23,0,.7,-.2,trim,"y") end
   else
    tube("Grenade body",.62,.51,0,0,-.2,paint,"y")
    ball("Rounded base",.51,.18,.51,0,-.31,-.2,dark)
    for i=1,4 do tube("Casing band",.035,.53,0,-.3+i*.13,-.2,dark,"y") end
    if name=="Grenade" then for _,side in {-1,1} do for i=0,3 do box("Fragmentation segment",.17,.1,.04,side*.18,-.2+i*.14,-.45,paint) end end end
    tube("Fuse cap",.13,.29,0,.38,-.2,steel,"y")
    box("Safety spoon",.08,.08,.53,.12,.48,-.2,steel,nil,CFrame.Angles(0,0,.12))
    ring("Pull ring",-.19,.46,-.2,.12,"x",steel)
    if name=="Flashbang" then for _,side in {-1,1} do for i=1,3 do box("Vent slot",.09,.04,.025,side*.14,-.25+i*.15,-.46,dark) end end end
    if name=="Smoke Grenade" then box("Smoke identification band",.52,.13,.04,0,0,-.47,Color3.fromRGB(176,188,171)) end
   end
  end
 else
  local pistol=family=="pistol" or family=="revolver"
  local sniper=family=="sniper" or family=="marksman"
  local compact=family=="smg"
  if family=="launcher" then
   tube("Launch tube",1.65,.56,0,.06,-.55,paint)
   for _,z in {-.4,-1.37,.27} do tube("Barrel reinforcement",.08,.63,0,.06,z,steel) end
   tube("Muzzle opening",.025,.47,0,.06,-1.43,dark)
   box("Heat shield",.42,.09,.95,0,.4,-.52,dark)
   rail(-.35,.65,.47);grip(0,-.37,.1,.45);guard(-.1,-.24,.24)
   for _,side in {-1,1} do for i=1,5 do box("Cooling port",.02,.1,.09,side*.29,.08,-.15-i*.19,dark) end;bolt(side*.32,.06,.23) end
   if w.magazine>1 then tube("Rotary chamber",.49,.77,0,-.25,-.12,steel,"x") end
  elseif pistol then
   box("Slide",.29,.23,.84,0,.11,-.2,paint);wedge("Bevelled slide nose",.29,.1,.18,0,.24,-.55,steel,CFrame.Angles(0,math.pi,0))
   box("Frame",.28,.13,.75,0,-.08,-.14,dark);grip(0,-.35,.12,.45);guard(-.18,-.17,.24)
   tube("Barrel",.15,.16,0,.12,-.67,steel);tube("Bore",.018,.1,0,.12,-.755,dark)
   box("Ejection port",.015,.12,.22,.153,.13,-.14,dark)
   for _,side in {-1,1} do for i=0,5 do box("Slide serration",.016,.16,.025,side*.15,.13,.03+i*.045,steel) end;bolt(side*.15,-.06,.16) end
   box("Magazine shoe",.29,.06,.3,0,-.61,.12,dark)
   for _,side in {-1,1} do box("Rear sight prong",.045,.07,.08,side*.1,.29,.14,dark) end;ball("Front sight dot",.04,.045,.04,0,.29,-.55,trim)
   if family=="revolver" then
    tube("Cylinder",.38,.41,0,.03,-.12,steel)
    for i=0,5 do local a=i*math.pi/3;tube("Chamber recess",.03,.07,math.cos(a)*.14,.03+math.sin(a)*.14,-.32,dark) end
    tube("Extended barrel",.5,.19,0,.12,-.85,paint)
   end
  else
   local length=compact and .48 or .79
   box("Upper receiver",.34,.25,.89,0,.08,0,paint);box("Lower receiver",.29,.16,.78,0,-.13,.01,dark)
   wedge("Receiver bevel",.3,.1,.68,0,.25,-.05,steel,CFrame.Angles(0,math.pi,0))
   box("Handguard",.31,.28,length,0,.06,-.55-length/2,rubber)
   local barrel=sniper and 1.0 or compact and .25 or .47
   tube("Barrel",barrel,.12,0,.08,-.55-length-barrel/2,steel)
   tube("Muzzle brake",.18,.21,0,.08,-.65-length-barrel,paint)
   tube("Muzzle bore",.018,.11,0,.08,-.75-length-barrel,dark)
   for _,side in {-1,1} do
    for i=0,4 do box("Handguard vent",.02,.07,.08,side*.162,.08,-.65-i*length/6,dark) end
    bolt(side*.18,.04,.18);bolt(side*.18,-.09,-.25)
    box("Receiver panel",.016,.1,.3,side*.178,.06,.02,steel)
   end
   box("Ejection well",.02,.11,.23,.19,.11,-.16,dark)
   tube("Charging handle",.26,.065,0,.17,.4,steel,"x")
   rail(-.42,1.15,.3);grip(0,-.37,.24,.47);guard(-.02,-.2,.26)
   box("Stock strut",.17,.15,.47,0,.1,.66,steel)
   box("Adjustable stock",.3,.33,.43,0,.04,.97,paint)
   wedge("Cheek rest bevel",.3,.1,.34,0,.25,.93,rubber)
   box("Recoil pad",.33,.43,.09,0,0,1.22,rubber,Enum.Material.SmoothPlastic)
   if family=="lmg" then
    box("Belt box",.62,.47,.5,0,-.4,-.2,paint)
    for i=0,5 do tube("Feed cartridge",.28,.065,.21+i*.025,.01-i*.06,-.1,trim) end
   elseif family=="shotgun" then
    tube("Shell tube",.9,.16,0,-.12,-1.0,steel)
    for i=0,5 do box("Pump rib",.37,.27,.035,0,.03,-.65-i*.075,dark) end
   else
    box("Magazine",.22,.43,.3,0,-.4,-.23,paint,nil,CFrame.Angles(-.1,0,0))
    box("Magazine floorplate",.27,.055,.34,0,-.64,-.21,dark)
    for i=0,3 do box("Magazine rib",.23,.025,.23,0,-.29-i*.08,-.23,dark) end
   end
   if sniper then
    box("Scope riser",.18,.12,.43,0,.4,-.1,dark)
    local body=tube("Scope body",.7,.25,0,.57,-.12,dark);body.Transparency=1
    for _,z in {-.42,-.12,.17} do ring("Hollow scope tube",0,.57,z,.125,"z",dark) end
    for _,z in {-.4,.14} do local bell=tube("Scope bell",.13,.34,0,.57,z,paint);bell.Transparency=1; ring("Scope bell rim",0,.57,z,.17,"z",paint) end
    local lens=tube("Coated objective",.015,.27,0,.57,-.475,Color3.fromRGB(81,155,166));lens.Material=Enum.Material.Glass;lens.Transparency=.8
    tube("Elevation turret",.13,.15,0,.77,-.11,steel,"y")
    tube("Windage turret",.12,.14,.17,.57,-.11,steel,"x")
   else
    for _,side in {-1,1} do box("Rear sight prong",.045,.16,.12,side*.1,.47,.18,dark) end;box("Front sight post",.045,.16,.07,0,.43,-.93,dark)
   end
  end
 end
 local muzzle
 for _,p in model:GetChildren() do
  if p.Name=="Muzzle bore" or p.Name=="Bore" or p.Name=="Muzzle opening" then muzzle=p.Position end
 end
 if muzzle then model:SetAttribute("MuzzleLocal",muzzle) end
 model:SetAttribute("SightHeight",(family=="sniper" or family=="marksman") and .57 or ((family=="pistol" or family=="revolver") and .29 or (family=="launcher" and .58 or .52)))
 return model
end
function Models.recolorFists(model,player)
 if not model or (model.Name~="Fists" and not model:GetAttribute("FistsModel")) or not player then return end
 local character=player.Character; if not character then return end
 local colors=character:FindFirstChildOfClass("BodyColors")
 for _,part in model:GetChildren() do
  local side=part:GetAttribute("ArmSide")
  if side then
   local arm=character:FindFirstChild(side.."Hand") or character:FindFirstChild(side.." Arm") or character:FindFirstChild(side.."LowerArm")
   if arm and arm:IsA("BasePart") then part.Color=arm.Color
   elseif colors then part.Color=side=="Right" and colors.RightArmColor3 or colors.LeftArmColor3 end
  end
 end
end
return Models
