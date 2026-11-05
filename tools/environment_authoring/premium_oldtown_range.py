from architecture import *
import math
m=Map('Old Town',5100,True);m.floor(color=[153,148,131])
# Varied urban blocks define a winding market street, workshop alley, and elevated loggia.
m.building(-68,-65,w=43,d=38,yaw=8,c=[190,171,139],title='MERIDIAN / GUILD HALL')
m.building(72,65,w=39,d=32,yaw=-14,c=[195,151,119],title='THE COPPER FIG / INN')
m.building(-101,23,w=28,d=40,yaw=90,c=[143,159,146],title='BELL & BRASS / ATELIER')
m.building(92,-40,w=39,d=58,yaw=-90,c=[199,190,164],title='CIVIC ARCHIVE',roof='flat')
# Site boundaries are layered urban facades, not four bare perimeter slabs.
for side in [-1,1]:
 for j,z in enumerate([-108,-62,-12,42,99]):
  x=side*(132+(j%2)*2);w=33;h=31+(j%3)*5
  m.box('Distant townhouse mass',(9,h,39),(x,h/2,z),[[174,158,135],[161,172,160],[194,164,135]][j%3])
  for y in [9,22]:
   for zz in [z-11,z+2,z+13]:
    m.box('Distant recessed window',(.15,5,2.7),(x-side*4.6,y,zz),[54,83,87],'Glass',decor=True)
    m.box('Distant window stone sill',(.9,.3,3.5),(x-side*4.8,y-2.7,zz),TRIM,'Sandstone',decor=True)
  m.box('Distant roof cornice',(11,.8,42),(x,h,z),TRIM,'Sandstone')
 for z in [-135,135]:
  for x in [-80,-40,0,40,80]:
   if abs(x)<10:
    # Gate portals preserve safe spawn on either side of the street.
    m.arch(x,0,z,width=16,height=17,depth=3,c=[182,170,146])
   else:m.box('Town enclosure',(39,22,3),(x,11,z),[172,163,143])
# Continuous arcade, deep soffit, cut stone arches, structural spandrel masonry.
for x in [-42,-20,2,24]:
 m.arch(x,0,-5,width=15,height=14,depth=4,c=[206,193,164])
 for side in [-1,1]:m.box('Arcade stone pier',(3,14,5),(x+side*9,7,-5),[183,170,143],'Sandstone')
 m.box('Arcade upper spandrel',(21,3,5),(x,17,-5),[187,177,151],'Sandstone')
m.box('Arcade loggia deck',(92,1,13),(-9,18,-5),TRIM,'Sandstone')
m.rail(-9,18.5,1.3,90)
m.rail(-9,18.5,-11.3,90)
m.stairs(-53,-42,width=9,rise=18,run=38,c=[184,172,143])
# Tower is a composed landmark with clock faces, belfry apertures and stacked cornices.
x,z=-29,-25
m.box('Clock tower ashlar base',(19,3,18),(x,1.5,z),TRIM,'Sandstone')
m.box('Clock tower shaft',(15,40,14),(x,23,z),[185,166,135],'Sandstone')
for y in [5,18,32,43]:m.box('Tower projecting course',(17,.65,16),(x,y,z),TRIM,'Sandstone')
for face in [-1,1]:
 m.box('Clock face ceramic',(8,8,.3),(x,35,z+face*7.3),[220,215,187],'Marble',decor=True,label='XII\nIX  ●  III\nVI')
 for side in [-1,1]:
  m.box('Belfry corner pier',(2,10,2),(x+side*6.5,49,z+face*6),TRIM,'Sandstone')
 m.box('Bell louvre',(10,7,.25),(x,49,z+face*6.3),DARK,'Wood',decor=True)
 for i in range(6):m.box('Bell louvre slat',(10,.3,.5),(x,46.5+i,z+face*6.55),WOOD,'Wood',decor=True)
m.box('Belfry cornice',(20,1.5,19),(x,54.5,z),TRIM,'Sandstone')
for side in [-1,1]:m.box('Clock tower hipped canopy',(22,.6,12),(x,58,z+side*5),[109,125,114],'Slate',rot=[side*28,0,0])
# Market fountain with stone coping, a real circular basin and concentric geometry.
fx,fz=28,34
m.box('Fountain plinth',(20,.6,20),(fx,.3,fz),TRIM,'Sandstone',shape='Cylinder',rot=[0,0,90]) # replace axial sizes below
m.parts[-1]['s']=[.6,20,20]
m.box('Fountain water',(.15,16,16),(fx,1,fz),[83,143,144],'Glass',shape='Cylinder',rot=[0,0,90],alpha=.35,decor=True)
for i in range(24):
 a=i*math.pi/12
 m.box('Fountain coping block',(2.25,2,1.2),(fx+math.sin(a)*9,1,fz+math.cos(a)*9),TRIM,'Sandstone',yaw=math.degrees(a),decor=False)
m.box('Fountain central pedestal',(3,4,3),(fx,3,fz),[178,164,136],'Sandstone')
m.box('Fountain upper dish',(.5,7,7),(fx,5.2,fz),TRIM,'Sandstone',shape='Cylinder',rot=[0,0,90])
# Covered stalls are purposeful mid-route cover with distinct shop identities.
for sx,sz,angle,title in [(-12,35,12,'VERDE / FRUIT MARKET'),(27,-62,-12,'CERAMICA / POTTERY'),(0,75,0,'RIFT POST / COURIER')]:
 q=m.local(sx,sz,angle)
 for side in [-1,1]:
  for zz in [-5,5]:q('Market timber post',(.6,10,.6),(side*8,5,zz),WOOD,'Wood')
 q('Market counter',(17,3.5,5),(0,1.75,1),[127,89,56],'WoodPlanks')
 for side in [-1,1]:q('Market canopy',(19,.35,6.5),(0,10,side*3),[135,91,60] if sx<0 else [77,116,105],'Fabric',rot=[side*12,0,0])
 for i in range(8):q('Canopy seam',(.07,.07,12),(i*2.5-8.5,10.2,0),TRIM,'Fabric',decor=True)
 q('Market business plaque',(16,1.7,.15),(0,8.5,-5.4),DARK,'Metal',decor=True,label=title)
 for i in range(5):
  q('Market wicker bin',(2.4,.8,2.8),(-6+i*3,3.9,1),[159,123,77],'Wood',decor=True)
  for j in range(3):q('Displayed market goods',(.5,.65,.5),(-6+i*3+.5*(j-1),4.5,1),[119,136,67] if sx<0 else [181,112,71],'SmoothPlastic',shape='Ball',decor=True)
# Winding paving cues, drainage, planted corners and low defensive garden walls.
for z in range(-120,125,8):
 centre=math.sin(z/65)*12
 for x in [-7,0,7]:m.box('Street paving course',(6.5,.035,7.4),(x+centre,.025,z),[174,165,142],'Slate',yaw=8,decor=True)
for x,z in [(-55,42),(50,84),(-55,-100),(60,-94),(-108,92),(103,22)]:
 m.planter(x,z,w=14,d=5);m.lamp(x+10,z)
for z in [-112,112]:
 for side in [-1,1]:
  m.box('Protected spawn garden wall',(20,5,3),(side*19,2.5,z-10 if z>0 else z+10),[179,167,143],'Sandstone')
  m.planter(side*24,z+side*3,w=12,d=5)
for x,z in [(-63,12),(61,11),(-18,101),(19,-101)]:m.bollard(x,z)
# Distinct side routes use walk-through stone portals.
for x,z,yaw in [(-88,81,90),(100,11,90),(-55,-33,0),(42,-104,0)]:m.arch(x,0,z,width=9,height=12,depth=2,yaw=yaw)
m.save('work/premium_Old_Town.json')

# Tactical training campus, industrial joinery and coherent material zoning.
m=Map('RiftArena',0);m.floor(294,390,[119,130,137],'Concrete')
# Floor extends toward the precision backstop rather than being centred on old range.
m.parts[0]['p'][2]=-65
shell=[79,98,111];panel=[147,166,173];navy=[35,55,69];teal=[65,139,145]
# Ballistic range perimeter: segmented buttresses, individual acoustic panels, coping.
for side in [-1,1]:
 x=side*145
 for z in range(-238,139,22):
  m.box('Range perimeter pier',(3,23,3),(x,11.5,z),shell)
  m.box('Range acoustic infill',(1.5,13,18),(x,7,z+10),panel)
  m.box('Perimeter coping',(3,.5,21),(x,14,z+10),navy,'Metal')
  m.box('Range utility conduit',(.4,.4,22),(x-side*1.8,3,z+10),navy,'Metal',decor=True)
m.box('Precision terminal wall',(290,25,4),(0,12.5,-254),shell)
for x in range(-135,140,15):
 m.box('Backstop angled panel',(13,17,.7),(x,10,-251),[51,69,80],'Metal',rot=[-10,0,0])
 m.box('Backstop upper ventilation',(10,3,.25),(x,21,-251.8),navy,'Metal',decor=True)
 for j in range(5):m.box('Vent grille slat',(10,.12,.3),(x,20+j*.4,-251.5),panel,'Metal',decor=True)
lanes=[-110,-66,-22,22,66,110]
for i,x in enumerate(lanes):
 # lower lane walls leave a panoramic view from observation balcony
 for side in [-1,1]:
  for z in range(-226,-8,16):
   m.box('Lane ballistic backing',(.8,5.5,15),(x+side*18.5,2.75,z),shell)
   m.box('Replaceable acoustic cassette',(.18,4.2,13.8),(x+side*18,2.8,z),[47,66,76],'Fabric',decor=True)
   m.box('Cassette fixing rail',(.12,.12,15),(x+side*17.8,5,z),panel,'Metal',decor=True)
 # target rail heads with motor housing and wheels
 m.box('Target carrier extrusion',(.28,.5,222),(x,18,-128),navy,'Metal')
 for z in [-35,-85,-145,-225]:
  m.box('Target carrier motor',(2,1.2,2),(x,18.7,z),panel,'Metal')
  m.box('Target carrier yoke',(.18,3,.18),(x,16.5,z),navy,'Metal',decor=True)
  for side in [-1,1]:m.box('Carrier drive roller',(.25,.75,.75),(x+side*.7,18.6,z),navy,'Metal',shape='Cylinder',decor=True)
  m.box('Range distance stripe',(33,.035,.2),(x,.035,z),[184,194,183],'SmoothPlastic',decor=True)
 m.box('Firing station desk',(31,2.5,3),(x,1.25,-9),navy,'Metal')
 m.box('Firing station top',(32,.25,4),(x,2.65,-9),panel,'Metal')
 m.box('Firing rubber mat',(29,.05,10),(x,.04,0),[43,62,73],'Rubber',decor=True)
 m.box('Firing station enamel number',(6,2,.15),(x,1.4,-7.4),teal,'Metal',decor=True,label=f'0{i+1}')
 m.box('Recoil calibration backboard',(13,12,.8),(x,7,-243),[86,107,117])
 for j in range(-5,6):
  m.box('Recoil grid vertical',(.025,10,.03),(x+j,7,-242.55),[157,183,179],decor=True)
  m.box('Recoil grid horizontal',(10,.025,.03),(x,7+j,-242.55),[157,183,179],decor=True)
# Main roof: steel sawtooth forms with glazing and structural ribs.
for z in [4,22,40]:
 m.box('Firing gallery roof panel',(290,.5,20),(0,25,z),shell,'Metal',rot=[-10,0,0])
 m.box('Sawtooth clerestory glass',(287,3,.2),(0,26,z-9.8),[138,186,191],'Glass',alpha=.32,decor=True)
 m.box('Clerestory frame',(290,.3,.3),(0,27.6,z-10),navy,'Metal')
for x in range(-140,145,28):
 for z in [-5,49]:
  m.box('Steel column web',(.35,25,2),(x,12.5,z),navy,'Metal')
  for zz in [-.8,.8]:m.box('Steel column flange',(1.8,25,.25),(x,12.5,z+zz),navy,'Metal')
  m.box('Column shoe',(3,.4,3),(x,.2,z),panel,'Metal')
 m.box('Gallery structural crossbeam',(1.4,1.7,58),(x,23.5,22),navy,'Metal')
 m.box('Suspended linear light',(17,.12,.5),(x,23,17),[174,216,214],'Neon',decor=True)
 for z in [2,24,40]:m.box('Suspended sound baffle',(18,2.4,.25),(x,21.5,z),[45,66,78],'Fabric',decor=True)
# Observation mezzanine and glazed control suite.
m.box('Observation mezzanine',(286,1,16),(0,14,60),panel,'Concrete')
m.rail(0,14.5,51.8,282)
m.stairs(128,97,width=10,rise=14.5,run=32,yaw=180,c=panel)
q=m.local(0,0)
m.box('Control booth floor',(70,.7,21),(0,14.5,78),panel)
m.box('Control booth roof',(74,.8,24),(0,26,78),navy,'Metal')
for side in [-1,1]:
 m.box('Control booth back wall',(70,11,.7),(0,20,88.3),shell)
 m.box('Control booth side pier',(.7,11,21),(side*35,20,78),shell)
 m.box('Control booth panoramic glazing',(32,8,.15),(side*18,20.5,67.7),[115,169,177],'Glass',alpha=.48,decor=True)
for x in [-33,-17,0,17,33]:m.box('Control room window mullion',(.2,9,.3),(x,20.5,67.5),navy,'Metal')
for x in [-22,0,22]:
 m.box('Observation operator desk',(12,3,4),(x,16.5,81),navy,'Metal')
 m.box('Observation monitor',(5,3,.25),(x,19,80),teal,'Neon',decor=True,label='RIFT / RANGE CONTROL')
# Interactive controls preserve exact names consumed by Training module.
for x in [-105,-55,0,55,105]:
 m.box('Drill console',(8,4,4),(x,2,104),navy,'Metal')
 m.box('Console chamfered top',(8.4,.5,4.4),(x,4.1,104),panel,'Metal',rot=[10,0,0])
 m.box('Console display',(6,2,.15),(x,4.5,101.8),teal,'Neon',decor=True)
 for xx in [-2.3,0,2.3]:m.box('Console tactile control',(.45,.25,.45),(x+xx,4.4,103),[166,184,181],'SmoothPlastic',decor=True)
# Outdoor preparation court, equipment niches, planted islands, entrance portal.
for x in [-85,85]:
 m.box('Outdoor equipment bay back',(32,12,1),(x,6,132),shell)
 for side in [-1,1]:m.box('Equipment bay pier',(1,12,12),(x+side*16,6,126),panel)
 m.box('Equipment bay canopy',(35,.6,16),(x,12.3,126),navy,'Metal')
 for xx in [-10,0,10]:
  m.box('Equipment locker',(7,8,2),(x+xx,4,130.3),[77,105,119],'Metal')
  for j in range(5):m.box('Locker vent',(5,.1,.1),(x+xx,5+j*.35,129.2),panel,'Metal',decor=True)
  m.box('Locker handle',(.15,1,.25),(x+xx+2,3.5,129),panel,'Metal',decor=True)
for x in [-53,53]:m.planter(x,78,w=22,d=6)
for z in range(71,145,8):m.box('Campus path inset',(24,.035,6),(0,.03,z),[165,179,181],'Slate',decor=True)
m.box('Training entrance header',(73,4,3),(0,19,143),navy,'Metal',label='RIFT / TACTICAL DEVELOPMENT CAMPUS')
for side in [-1,1]:m.box('Training entrance pier',(3,21,3),(side*36,10.5,143),panel)
m.save('work/premium_RiftArena.json')
print('Old Town and range authored')
