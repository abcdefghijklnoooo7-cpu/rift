"""Original Rift port and railway power-station environments.
Every repeated detail belongs to a fabricated assembly: ribs, trusses, glazing,
ballast, handrails, fasteners and service equipment. No unstructured scatter.
"""
from architecture import Map, METAL, DARK, GLASS, matrix, multiply
import math
CREAM=[204,197,172];BLUE=[73,105,121];RUST=[143,78,49];BRICK=[132,83,64];ZINC=[106,125,131];BLACK=[35,45,50];LIME=[216,180,88]

def pipe(M,n,x,y,z,length=18,r=.6,axis='y',color=ZINC):
 rot={'y':[0,0,90],'z':[0,90,0],'x':[0,0,0]}[axis]
 M.box(n,(length,r*2,r*2),(x,y,z),color,'Metal',rot=rot,shape='Cylinder')
 for t in [-.4,.4]:
  p=[x,y,z];p['xyz'.index(axis)]+=length*t
  M.box(n+' coupling',(.4,r*2.5,r*2.5),p,DARK,'Metal',rot=rot,shape='Cylinder')

def truss(M,x,z,length,y=27,width=2,yaw=0):
 q=M.local(x,z,yaw)
 for yy in [-1,1]:q('Riveted truss chord',(length,.35,.35),(0,y+yy*width/2,0),DARK,'Metal')
 bays=max(2,int(length/7));step=length/bays
 for i in range(bays):
  a=math.degrees(math.atan2(width,step));q('Triangulated truss web',(math.hypot(step,width),.18,.22),(-length/2+step*(i+.5),y,0),ZINC,'Metal',rot=[0,0,a if i%2 else -a])
  for yy in [-1,1]:q('Truss gusset',(.65,.65,.1),(-length/2+step*i,y+yy*width/2,-.2),RUST,'Metal',decor=True)

def container(M,x,z,yaw=0,color=BLUE,length=24):
 q=M.local(x,z,yaw)
 q('Ribbed freight container',(9,9,length),(0,4.5,0),color,'Metal')
 for side in [-1,1]:
  for j in range(int(length/1.2)):
   q('Pressed corrugation',(.22,8.2,.22),(side*4.56,4.5,-length/2+.6+j*1.2),[min(255,v+14) for v in color],'Metal',decor=True)
  q('Container corner casting',(.7,9.3,.7),(side*4.25,4.5,-length/2),DARK,'Metal')
  q('Container door hinge',(.3,8.1,.3),(side*3.2,4.5,length/2+.15),ZINC,'Metal',decor=True)
  for yy in [1,4.5,8]:q('Door cross strap',(8.5,.18,.18),(0,yy,length/2+.18),ZINC,'Metal',decor=True)
 q('Freight identification plaque',(5,1.2,.08),(0,6.5,length/2+.2),CREAM,'Metal',decor=True,label='RIFT / 047')

def warehouse(M,x,z,w,d,height=23,yaw=0,title='PORT AUTHORITY'):
 q=M.local(x,z,yaw)
 q('Raised warehouse slab',(w+1,1.2,d+1),(0,.6,0),CREAM)
 # bays front and rear are actual openings with a clerestory over them
 for side in [-1,1]:
  for edge in [-1,1]:q('Warehouse end pier',(w/2-7,height,1.5),(edge*(w/4+3.5),height/2,side*d/2),CREAM)
  q('Loading bay header',(14,height-12,1.5),(0,12+(height-12)/2,side*d/2),CREAM)
  for xx in [-w/2,w/2]:q('Steel portal column',(.65,height+1,.65),(xx,height/2,side*d/2),DARK,'Metal')
  q('Loading door track',(.35,13,.35),(-7.4,6.5,side*(d/2+.7)),ZINC,'Metal')
  q('Loading door track',(.35,13,.35),(7.4,6.5,side*(d/2+.7)),ZINC,'Metal')
  q('Door caution header',(16,.7,.6),(0,12.5,side*(d/2+.8)),LIME,'Metal')
  for xx in [-5,-3,-1,1,3,5]:q('Striped caution marker',(.8,.72,.1),(xx,12.5,side*(d/2+1.15)),BLACK,'Metal',rot=[0,0,25],decor=True)
 for side in [-1,1]:
  q('Weathered warehouse side',(1.2,height,d),(side*w/2,height/2,0),BLUE,'Metal')
  for j in range(int(d/2)):
   q('Wall standing seam',(.15,height-.8,.16),(side*(w/2+.65),height/2,-d/2+1+j*2),ZINC,'Metal',decor=True)
  for zz in [-d/2,d/2]:q('Steel corner plate',(.2,height+1,1.3),(side*(w/2+.7),height/2,zz),DARK,'Metal',decor=True)
 # Four sawtooth cells give stepped skyline and glazed north lights.
 cells=4;span=d/cells
 for i in range(cells):
  zz=-d/2+span*(i+.5);rise=5;theta=math.degrees(math.atan2(rise,span))
  q('Sawtooth standing seam roof',(w+3,.45,math.hypot(span,rise)),(0,height+rise/2,zz),ZINC,'Metal',rot=[-theta,0,0])
  q('Sawtooth glazed north light',(w+1,rise,.15),(0,height+rise/2,zz+span/2),GLASS,'Glass',alpha=.22,decor=False)
  for side in [-1,1]:
   seal=q('Sawtooth triangular side infill',(1.25,rise,span+.08),(side*w/2,height+rise/2,zz),BLUE,'Metal');seal['class']='WedgePart'
  for xx in range(-int(w/2),int(w/2)+1,4):q('Clerestory mullion',(.12,rise,.28),(xx,height+rise/2,zz+span/2+.1),DARK,'Metal',decor=True)
  for xx in range(-int(w/2),int(w/2)+1,3):q('Roof folded seam',(.1,.1,math.hypot(span,rise)),(xx,height+rise/2+.3,zz),[139,153,154],'Metal',rot=[-theta,0,0],decor=True)
 # actual interior cross-girders and wall electrical equipment
 for zz in [-d/2+2,0,d/2-2]:
  a=math.radians(yaw);px=x+zz*math.sin(a);pz=z+zz*math.cos(a)
  truss(M,px,pz,w,height-1,3,yaw)
 q('Industrial enamel fascia',(min(w-2,34),2.3,.25),(0,18,-d/2-.9),DARK,'Metal',decor=True,label=title)
 for xx in [-w*.28,w*.28]:
  q('Loading dock bumper',(2,2,1),(xx,1,-d/2-1),BLACK,'Rubber')
  q('Interior luminaire',(8,.3,.7),(xx,height-2,0),[222,221,182],'Neon',decor=True)
 return height

def dockyard():
 M=Map('Dockyard',2800)
 M.floor(280,280,[111,124,130],'Concrete')
 # Floor articulation distinguishes vehicle apron, pedestrian concourse, and drydock.
 M.box('Port apron asphalt',(116,.06,248),(4,.03,0),[67,79,86],'Asphalt',decor=True)
 for z in range(-115,122,12):M.box('Apron lane centreline',(.35,.03,5),(8,.08,z),CREAM,'SmoothPlastic',decor=True)
 for x in [-49,61]:
  M.box('Apron drainage channel',(1,.08,248),(x,.08,0),DARK,'Metal',decor=True)
  for z in range(-120,125,3):M.box('Drain grate crossbar',(1,.1,.15),(x,.12,z),ZINC,'Metal',decor=True)
 # Left terminal is a long working warehouse; customs office occupies a different footprint.
 warehouse(M,-76,-15,42,104,23,0,'NORTH QUAY / WAREHOUSE 04')
 # Oversized lateral loading opening on east wall, remove a 14-wide section of that wall.
 # Left warehouse's open end doors connect its interior to both halves of the map.
 warehouse(M,76,-70,44,56,20,90,'RIFT CUSTOMS / INSPECTION')
 # Bespoke raised customs office with glazed control room, walkable open underside.
 for x in [47,91]:
  for z in [29,65]:M.box('Office pilotis',(1.4,14,1.4),(x,7,z),CREAM)
 M.box('Customs upper floor',(46,1,38),(69,13.5,47),CREAM)
 for side in [-1,1]:
  M.box('Control room solid end',(1,11,38),(69+side*23,19.5,47),BLUE,'Metal')
  M.box('Control room glazing',(45.2,7,.22),(69,20,47+side*19),GLASS,'Glass',alpha=.2,decor=False)
  M.box('Control room sill',(46,3,1),(69,15.5,47+side*19),CREAM)
  for x in range(49,92,6):M.box('Control room window mullion',(.16,7,.3),(x,20,47+side*19),DARK,'Metal',decor=True)
 M.box('Customs canopy roof',(50,1.2,42),(69,25.5,47),ZINC,'Metal')
 M.box('Office briefing counter',(18,3,3),(65,15.5,59),BLUE,'Metal')
 M.box('Office access terrace',(50,1,10),(69,13.5,72),CREAM)
 for z in [28,66]:M.box('Control room upper wall closure',(46,1.6,1),(69,24.2,z),BLUE,'Metal')
 M.box('Office entry gap header',(10,2,.7),(69,24,66),BLUE,'Metal')
 # Doorway removes a centre segment of rear glazing to keep access genuine.
 M.parts=[p for p in M.parts if not (p['n'] in ['Control room glazing','Control room sill'] and abs(p['p'][2]-66)<.01)]
 for x in [55,83]:M.box('Control room doorway sill wing',(18,3,1),(x,15.5,66),CREAM)
 for x in [55,83]:M.box('Control room rear glazing wing',(18,7,.22),(x,20,66),GLASS,'Glass',alpha=.2,decor=False)
 M.stairs(100,42,width=9,rise=14,run=28,c=CREAM)
 M.box('Office stair arrival bridge',(16,1,10),(96,13.5,72),CREAM)
 M.rail(69,14,77,50);M.rail(94,14,72,10,yaw=90)
 # Left elevated maintenance catwalk, reach via two different stairs, not a floating prop.
 M.box('Warehouse maintenance gallery',(10,.7,122),(-48,13.65,-15),ZINC,'DiamondPlate')
 for z in [-68,-35,0,35]:M.box('Gallery steel knee bracket',(3,3,.5),(-50,12,z),DARK,'Metal',rot=[0,0,35])
 M.rail(-43,14,-15,122,yaw=90)
 M.stairs(-48,49,width=8,rise=14,run=28,yaw=180,c=CREAM)
 M.box('Gallery front connection',(10,1,8),(-48,13.5,20),CREAM)
 M.stairs(-48,-106,width=8,rise=14,run=28,c=CREAM)
 # Tactical cargo chicanes: staggered, never a straight spawn-to-spawn channel.
 for x,z,yaw,c in [(-15,48,90,BLUE),(24,-11,0,RUST),(-8,-65,90,[100,130,119]),(85,102,90,BLUE),(-88,104,90,RUST)]:container(M,x,z,yaw,c)
 # The yard is an operating customs apron: grouped handling assemblies serve as tactical cover.
 # Pallet stacks stay beside the warehouse bay, leaving its central 14-stud doorway open.
 for x,z,levels in [(-91,-80,5),(-59,-80,3),(-91,57,4),(-61,59,3)]:
  for level in range(levels):
   yy=.35+level*.65
   for dx in [-2.5,0,2.5]:M.box('Pallet bearing block',(1,.42,4.8),(x+dx,yy,z),[110,87,60],'Wood')
   for dz in [-2,-1,0,1,2]:M.box('Pallet deck board',(6.5,.18,.7),(x,yy+.3,z+dz),[146,119,80],'WoodPlanks')
  M.box('Freight stack tie band',(.2,levels*.65+.2,5.2),(x,levels*.325+.2,z),[78,86,80],'Fabric',decor=True)
 # Original electric forklift: deliberate full-height carried crate breaks the centreline.
 q=M.local(1,22,-12)
 q('Forklift steel chassis',(8,2.2,10),(0,2.3,0),[186,139,57],'Metal')
 q('Forklift rear counterweight',(8.3,4,3),(0,3.5,4),[177,127,50],'Metal')
 q('Forklift driver floor',(7,.5,5),(0,3.7,.2),BLACK,'DiamondPlate')
 for side in [-1,1]:
  for zz in [-3.3,3.1]:
   q('Forklift rubber tyre',(1.3,3.2,3.2),(side*4,1.7,zz),BLACK,'Rubber',shape='Cylinder')
   q('Forklift wheel hub',(1.4,1.5,1.5),(side*4.1,1.7,zz),[184,170,126],'Metal',shape='Cylinder')
   q('Forklift wheel centre pin',(1.5,.42,.42),(side*4.15,1.7,zz),DARK,'Metal',shape='Cylinder',decor=True)
  for zz in [-2.6,2.2]:q('Forklift canopy upright',(.3,6,.3),(side*3.1,6.7,zz),DARK,'Metal')
  q('Forklift mast channel',(.5,10,.65),(side*2.8,6,-5.3),DARK,'Metal')
  q('Forklift lift fork',(.7,.45,8),(side*2.5,1.4,-9.5),[101,113,116],'Metal')
  q('Forklift hydraulic cylinder',(6,.6,.6),(side*1.6,4.6,-5.5),ZINC,'Metal',shape='Cylinder',rot=[0,0,90])
 q('Forklift protective roof',(7.4,.4,6.8),(0,9.9,.1),DARK,'Metal')
 for xx in [-2,-1,0,1,2]:q('Forklift roof safety slat',(.15,.2,6.5),(xx,10.2,.1),ZINC,'Metal',decor=True)
 q('Forklift padded seat',(3,1,2.6),(0,4.6,1),BLACK,'Rubber')
 q('Forklift seat back',(3,2.5,.6),(0,5.9,2.3),BLACK,'Rubber')
 q('Forklift steering column',(.35,2,.35),(0,4.8,-1.5),DARK,'Metal',rot=[-20,0,0])
 q('Forklift instrument console',(4,.8,1.2),(0,5.3,-2.3),[98,114,115],'Metal')
 q('Forklift enamel number',(4,1,.1),(0,3.7,5.55),DARK,'Metal',decor=True,label='RIFT / E-06')
 q('Forklift carriage plate',(7,3,.5),(0,3,-5.8),DARK,'Metal')
 q('Forklift carried customs crate',(9,7,7),(0,5.3,-9.8),[134,106,72],'WoodPlanks')
 for yy in [2.1,8.5]:q('Crate steel edge strap',(9.3,.25,7.3),(0,yy,-9.8),DARK,'Metal')
 for xx in [-4.3,4.3]:
  for zz in [-13.3,-6.3]:q('Crate steel corner strap',(.3,6.6,.3),(xx,5.3,zz),DARK,'Metal')
 q('Cargo handling label',(4,1.6,.08),(0,6.2,-13.4),DARK,'Metal',decor=True,label='CUSTOMS / HOLD')
 # Offset security booth is a small usable room, rather than another sealed cover box.
 q=M.local(-24,-24,0)
 q('Security booth foundation',(17,1,12),(0,.5,0),CREAM)
 q('Security booth rear wall',(16,10,.7),(0,5.8,5.5),BLUE,'Metal')
 for side in [-1,1]:
  q('Security booth side sill',(.7,3.8,11),(side*8,2.9,0),BLUE,'Metal')
  q('Security booth side glazing',(.22,5.2,11.2),(side*8,7.3,0),GLASS,'Glass',decor=False,alpha=.23)
  q('Security booth front pier',(3.7,10,.7),(side*6.2,5.8,-5.5),BLUE,'Metal')
  q('Security booth corner post',(.4,10,.4),(side*8,5.8,-5.5),DARK,'Metal')
  q('Security booth glazing bar',(.3,4.6,.3),(side*8,7.3,0),DARK,'Metal',decor=True)
  q('Security booth side upper closure',(.7,1.2,11.2),(side*8,10.2,0),BLUE,'Metal')
 q('Security booth front lintel',(8.7,2,.7),(0,9.8,-5.5),BLUE,'Metal')
 q('Security booth canopy',(20,.7,15),(0,11.1,-1),ZINC,'Metal')
 q('Security booth scanner counter',(7,3,2),(0,2.5,3),CREAM,'Metal')
 q('Security booth display',(2,1.4,.2),(0,4.8,3),[74,151,152],'Neon',decor=True)
 q('Security booth fascia',(14,1.6,.16),(0,10,-6.1),DARK,'Metal',decor=True,label='QUAY SECURITY / 04')
 # A curb makes the booth approach legible; the return remains a clear alternate route.
 for x in [-34,-14]:M.box('Security island curb',(1,.5,20),(x,.25,-24),CREAM)
 for z in [-34,-14]:M.box('Security island curb',(21,.5,1),(-24,.25,z),CREAM)
 # Parked handcart lies flush to the loading edge, with recognizable deck and handle.
 q=M.local(-37,74,8)
 q('Port handcart load deck',(5,.4,7),(0,1.2,0),BLUE,'Metal')
 for side in [-1,1]:
  for zz in [-2.5,2.5]:q('Handcart rubber wheel',(.5,1.3,1.3),(side*2.2,.65,zz),BLACK,'Rubber',shape='Cylinder')
  q('Handcart handle upright',(.18,3.5,.18),(side*2,2.9,3.3),ZINC,'Metal')
 q('Handcart push handle',(4.2,.2,.2),(0,4.6,3.3),BLACK,'Rubber')
 for xx in [-1.2,1.2]:q('Handcart mail case',(2,2.3,3.7),(xx,2.55,0),[134,108,77],'WoodPlanks')
 # Quay edge dry canal is protected by continuous retaining parapet; no unsupported drop.
 for z in [-114,-60,0,60,114]:
  M.box('Quay retaining wall',(6,8,26),(133,4,z),CREAM)
  M.box('Quay coping',(7,.6,27),(133,8.2,z),[174,183,175])
  pipe(M,'Mooring bollard',126,2,z,3,1,'y',BLACK)
 for side in [-1,1]:
  # Dockside rail crane defines skyline, using articulated steel components and a diagonal boom.
  x=side*115;z=-110
  for dx in [-5,5]:
   M.box('Crane gantry leg',(1.8,33,2),(x+dx,16.5,z),DARK,'Metal')
   for yy in [3,13,23]:M.box('Crane diagonal knee',(.5,13,1),(x+dx,yy+3,z),ZINC,'Metal',rot=[0,0,side*20])
  M.box('Crane bridge',(26,2,8),(x,34,z),BLUE,'Metal')
  M.box('Crane operator cab',(8,6,7),(x,38,z),BLUE,'Metal')
  M.box('Crane cab glazing',(6,3,.1),(x,39,z+3.6),GLASS,'Glass',decor=True,alpha=.2)
  M.box('Crane cantilever boom',(1.2,1.2,55),(x,44,z+20),DARK,'Metal',rot=[-12,0,0])
  M.box('Crane lifting cable',(.12,24,.12),(x,29,z+45),BLACK,'Metal',decor=True)
  pipe(M,'Crane pulley',x,42,z+42,1.2,1.1,'x',RUST)
 # Background port walls, layered facade columns, and roof vents enclose the playable volume.
 for z in [-138,138]:
  M.box('Port perimeter masonry',(280,19,3),(0,9.5,z),CREAM)
  for x in range(-132,139,12):
   M.box('Boundary pier',(2,21,4),(x,10.5,z),BLUE)
   M.box('Pier cap',(3,.6,5),(x,21.3,z),ZINC,'Metal')
 for x in [-138,138]:M.box('Dock perimeter',(3,20,280),(x,10,0),CREAM)
 # Pipework attached to terminal, painted safety details, wall lamps and fasteners.
 for z in [-56,-24,8,40]:
  pipe(M,'Warehouse rainwater leader',-98,12,z,24,.32,'y',ZINC)
  for y in [3,12,21]:M.box('Downpipe wall strap',(.8,.3,.6),(-98,y,z),DARK,'Metal',decor=True)
  M.box('Wall light canopy',(1.4,.4,2),(-53,16,z),DARK,'Metal')
  M.box('Wall light diffuser',(.8,.2,1.5),(-52.9,15.7,z),[222,220,185],'Neon',decor=True)
 for x,z in [(-27,105),(29,105),(-30,-110),(34,-110),(110,16)]:
  M.bollard(x,z);M.box('Port pavement hatch',(6,.04,6),(x,.1,z),[150,154,144],'Metal',decor=True)
 for x,z in [(-24,83),(27,82),(-33,-36),(36,45)]:M.box('Freight bay floor stencil',(11,.025,2),(x,.11,z),[190,176,126],'SmoothPlastic',decor=True)
 M.box('Port entry overhead sign',(36,3,.5),(0,18,123),DARK,'Metal',decor=True,label='NORTH QUAY / RIFT CUSTOMS')
 for x in [-18,18]:M.box('Entry sign column',(.6,18,.6),(x,9,123),ZINC,'Metal')
 return M

def switchyard():
 M=Map('Switchyard',3700,True)
 M.floor(280,280,[128,125,112],'Concrete')
 # Rail ballast strips and precise, continuous sleepers with clips.
 for x in [-93,92]:
  M.box('Ballast bed',(19,.25,250),(x,.125,0),[83,82,76],'Slate')
  for z in range(-120,124,5):
   M.box('Creosote sleeper',(16,.3,1),(x,.3,z),[75,62,47],'WoodPlanks')
   for dx in [-4,4]:
    M.box('Rail fixing plate',(1.3,.12,1.3),(x+dx,.53,z),DARK,'Metal',decor=True)
    M.box('Rail clip',(.18,.12,.8),(x+dx+.3,.65,z),RUST,'Metal',decor=True)
  for dx in [-4,4]:M.box('Polished rail',(.45,.55,250),(x+dx,.7,0),[139,147,143],'Metal')
 # Turbine hall has a circular lower rhythm but large open doorways on four axes.
 cx=-6;radius=34
 for i in range(24):
  a=math.radians(i*15+7.5)
  # Open entire sectors around each cardinal doorway, preserving 16-stud access.
  if i%6 in [0,5]:continue
  x=cx+math.sin(a)*radius;z=math.cos(a)*radius
  M.box('Turbine hall drum pier',(9.3,24,2.2),(x,12,z),BRICK,'Brick',yaw=i*15+7.5)
  M.box('Drum pilaster',(1.1,27,2.8),(x,13.5,z),CREAM,'Sandstone',yaw=i*15+7.5)
  for yy in [2,11,22]:M.box('Circular stone stringcourse',(8,.5,2.8),(x,yy,z),CREAM,'Sandstone',yaw=i*15+7.5)
 # Upper ring segment roof; transparent high clerestory makes a sophisticated skyline.
 for i in range(32):
  a=math.radians(i*360/32);x=cx+math.sin(a)*32;z=math.cos(a)*32
  M.box('Turbine clerestory glass',(6.6,5,.35),(x,27,z),GLASS,'Glass',yaw=i*360/32,decor=False,alpha=.28)
  M.box('Clerestory iron mullion',(.18,5.5,.4),(x,27,z),DARK,'Metal',yaw=i*360/32,decor=True)
  roof=M.box('Radial standing seam roof',(7,.5,35),(cx+math.sin(a)*18,31.2,math.cos(a)*18),ZINC,'Metal');roof['r']=multiply(matrix([0,i*360/32,0]),matrix([8,0,0]))
  M.box('Turbine clerestory base closure',(6.8,1.2,5),(cx+math.sin(a)*33,24.3,math.cos(a)*33),CREAM,'Sandstone',yaw=i*360/32)
 pipe(M,'Roof ventilator',cx,35,0,5,5,'y',RUST)
 pipe(M,'Roof lantern cap',cx,38,0,1,6,'y',DARK)
 for face in [-1,1]:
  # Portal beams above north/south entrances leave the path clear.
  M.box('Hall entrance lintel',(19,7,2),(cx,20.8,face*33),CREAM)
  M.arch(cx,0,face*35,width=15,height=17,depth=2,c=CREAM)
 # Central turbine assembly is the primary central sightline break, not a generic crate.
 M.box('Turbine concrete plinth',(22,2,15),(cx,1,0),CREAM)
 pipe(M,'Riveted turbine main casing',cx,6,0,20,5.3,'x',BLUE)
 for x in [-16,-10,-3,4]:
  pipe(M,'Turbine split flange',x,6,0,.6,5.8,'x',DARK)
  for i in range(12):
   a=i*math.pi/6;M.box('Turbine flange bolt',(.8,.28,.28),(x-.4,6+math.sin(a)*5.2,math.cos(a)*5.2),[166,165,143],'Metal',decor=True)
 for side in [-1,1]:
  pipe(M,'Main steam riser',cx+side*18,8,-12,16,1.3,'y',RUST)
  pipe(M,'Steam delivery pipe',cx+side*12,15,-12,12,1.3,'x',RUST)
  pipe(M,'Pressure valve',cx+side*18,6,-13.8,.5,2,'z',DARK)
 # Elevated open galleries flank the central hall and connect to service rooms.
 for side in [-1,1]:
  x=side*53
  M.box('Service gallery deck',(16,1,100),(x,12.5,0),ZINC,'DiamondPlate')
  for z in [-40,0,40]:
   M.box('Gallery stanchion',(1.5,13,1.5),(x,6.5,z),DARK,'Metal')
   M.box('Gallery knee brace',(.6,6,1),(x+side*3,10,z),ZINC,'Metal',rot=[0,0,side*35])
  # Outer safety rail only. Inner edge is an entry to hall gallery bridges.
  M.rail(x+side*8,13,0,100,yaw=90)
  for z in [-42,42]:
   M.box('Hall gallery connection',(25,1,12),(side*36,12.5,z),ZINC,'DiamondPlate')
  M.stairs(x,-86,width=10,rise=13,run=30,c=CREAM)
  M.box('North gallery landing',(16,1,10),(x,12.5,-51),ZINC,'DiamondPlate')
  M.stairs(x,86,width=10,rise=13,run=30,yaw=180,c=CREAM)
  M.box('South gallery landing',(16,1,10),(x,12.5,51),ZINC,'DiamondPlate')
 # An annular inspection gallery inside the drum connects both exterior galleries.
 # Bridges pass through the genuine east/west portal gaps rather than through walls.
 for i in range(32):
  theta=i*360/32;a=math.radians(theta)
  M.box('Annular turbine inspection deck',(6.1,1,8),(cx+math.sin(a)*27,12.5,math.cos(a)*27),ZINC,'DiamondPlate',yaw=theta)
  if i%8 not in [0,7]:
   M.box('Inner gallery handrail',(5.7,.18,.18),(cx+math.sin(a)*23,16,math.cos(a)*23),DARK,'Metal',yaw=theta)
   M.box('Inner gallery upright',(.16,3,.16),(cx+math.sin(a)*23,14.5,math.cos(a)*23),DARK,'Metal')
 for side in [-1,1]:
  M.box('Portal inspection bridge',(25,1,10),(cx+side*42,12.5,0),ZINC,'DiamondPlate')
  for zz in [-5,5]:M.rail(cx+side*42,13,zz,25)
 # Gallery connection arches form alcoves and cover on each far route.
 for x in [-123,123]:
  for z in [-90,-45,0,45,90]:
   M.arch(x,0,z,width=22,height=19,depth=5,yaw=90,c=CREAM)
   M.box('Viaduct upper parapet',(5,5,31),(x,23,z),BRICK,'Brick')
  M.box('Viaduct stringer',(7,2,250),(x,20,0),CREAM,'Sandstone')
 # Bespoke rail carriages provide diagonal side-lane breaks with open passenger doors.
 for x,z,yaw in [(-93,12,0),(92,-23,0)]:
  q=M.local(x,z,yaw)
  q('Passenger coach underframe',(12,2,38),(0,3,0),DARK,'Metal')
  q('Coach timber floor',(12,.6,38),(0,4.2,0),[93,72,52],'WoodPlanks')
  for side in [-1,1]:
   # side wall leaves central 8-stud door gap
   for end in [-1,1]:
    q('Coach enamel side',(.7,8,15),(side*6,8.3,end*11.5),[76,115,108],'Metal')
    for zz in [end*8,end*14]:
     q('Coach window surround',(.2,4.8,4.8),(side*6.45,9,zz),CREAM,'Metal',decor=True)
     q('Coach window glass',(.12,3.6,3.7),(side*6.6,9,zz),GLASS,'Glass',decor=True,alpha=.3)
   q('Coach door lintel',(.8,1.5,8),(side*6,12,0),CREAM,'Metal')
   q('Coach eave closure',(.8,.5,38),(side*6,12.3,0),CREAM,'Metal')
   for zz in [-12,12]:
    q('Rail wheel',(.8,4,4),(side*5.7,2,zz),DARK,'Metal',shape='Cylinder')
    q('Wheel hub',(1,1.3,1.3),(side*6.2,2,zz),ZINC,'Metal',shape='Cylinder')
    q('Bogie leaf spring',(.7,.4,7),(side*5,2.9,zz),RUST,'Metal',decor=True)
  q('Coach crown roof',(12.8,.65,40),(0,12.7,0),ZINC,'Metal')
  for end in [-1,1]:q('Coach end wall',(12,8,.7),(0,8.3,end*19),[76,115,108],'Metal')
  # 4-stud coach doorway reached by a wide 8-stud run of gentle steps on both sides.
  for side in [-1,1]:
   for i in range(8):q('Carriage boarding step',(1, .5*(i+1),8),(side*(14-i),.25*(i+1),0),CREAM)
 # Workshop bays at asymmetric corners create deliberate flank loops.
 for x,z in [(-63,-118),(65,118)]:
  q=M.local(x,z,0)
  q('Workshop back masonry',(50,16,2),(0,8,0),BRICK,'Brick')
  q('Workshop canopy',(52,1,18),(0,17,-8 if z>0 else 8),ZINC,'Metal')
  for dx in [-20,20]:q('Canopy steel bracket',(.5,15,.5),(dx,8,-14 if z>0 else 14),DARK,'Metal')
  for dx in [-15,15]:
   q('Utility cable cabinet',(6,7,2),(dx,3.5,-2 if z>0 else 2),BLUE,'Metal')
   for k in range(7):q('Cabinet cooling louvre',(4,.12,.15),(dx,1.5+k*.7,-3.2 if z>0 else 3.2),ZINC,'Metal',decor=True)
 # Spawn sightline baffles have symmetric travel cost while central composition stays asymmetric.
 for side in [-1,1]:
  z=side*78
  M.box('Spawn privacy masonry',(24,10,2),(-side*14,5,z),BRICK,'Brick')
  M.box('Spawn baffle stone cap',(25,.6,3),(-side*14,10.3,z),CREAM,'Sandstone')
  M.box('Spawn privacy return',(2,10,16),(-side*26,5,z-side*7),BRICK,'Brick')
  M.box('Team court paving',(38,.08,20),(0,.08,side*111),[164,162,144],'Concrete',decor=True)
  M.box('Railway enamel wayfinding',(28,2.5,.2),(0,15,side*128),DARK,'Metal',label='TURBINE HALL / '+('NORTH' if side<0 else 'SOUTH'),decor=True)
 # Layered back boundary in brick rather than a featureless tall box.
 for z in [-139,139]:
  M.box('Boundary retaining masonry',(280,12,2),(0,6,z),BRICK,'Brick')
  for x in range(-132,140,12):
   M.box('Boundary pilaster',(1.7,15,3),(x,7.5,z),CREAM,'Sandstone')
   M.box('Pilaster cap',(2.5,.6,3.5),(x,15.3,z),DARK,'Metal')
 for x in [-139,139]:M.box('Viaduct rear boundary',(2,28,280),(x,14,0),BRICK,'Brick')
 for x,z in [(-26,-101),(26,101),(-30,58),(27,-59)]:M.lamp(x,z)
 # Surface joints, electrical conduits and riveted skirting support architecture.
 for z in range(-120,125,12):
  M.box('Central paving expansion seam',(74,.03,.12),(0,.06,z),[93,96,88],'Concrete',decor=True)
 for side in [-1,1]:
  for z in [-30,-10,10,30]:
   pipe(M,'Gallery cable conduit',side*58,10.7,z,18,.18,'z',RUST)
   for y in [3,8]:M.box('Column fixing plate',(.2,1,1.5),(side*53+.85,y,z),ZINC,'Metal',decor=True)
 return M

if __name__=='__main__':
 for fn,path in [(dockyard,'work/premium_Dockyard.json'),(switchyard,'work/premium_Switchyard.json')]:
  m=fn();m.save(path);print(m.name,len(m.parts))
