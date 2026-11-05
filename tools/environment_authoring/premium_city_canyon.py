from architecture import Map,STONE,TRIM,DARK,WOOD,METAL,GLASS
import math

# Detailed original urban street network: diagonally opposed blocks, a dogleg tramway,
# a raised station concourse and continuous ground-level underpass.
m=Map('Metro District',2100)
m.floor(color=[151,144,129],material='Cobblestone')
cream=[204,190,160];terracotta=[173,112,86];teal=[72,111,108];ivory=[227,214,185]
m.building(-81,-37,w=40,d=44,h=14,floors=2,yaw=90,c=cream,trim=ivory,title='ATELIER / 17')
m.building(87,65,w=42,d=34,h=14,floors=2,yaw=180,c=terracotta,trim=ivory,title='CASA MERIDIAN')
# Mapped streets bend around the station rather than creating one uninterrupted lane.
for x,z,w,d in [(-3,81,32,110),(-20,-72,30,94),(45,-3,100,28),(-75,51,32,86),(85,-76,38,88)]:
 m.box('Basalt street paving',(w,.06,d),(x,.03,z),[91,98,98],'Basalt')
 for side in [-1,1]:m.box('Street kerbstone',(1,.26,d),(x+side*(w/2+.4),.13,z),ivory,'Sandstone')
# Tramline rails have carefully modelled narrow gauge and sleepers under a continuous route.
for x,z,length,yaw in [(-12,82,104,0),(-20,-80,94,0),(10,10,67,48)]:
 q=m.local(x,z,yaw)
 for side in [-1,1]:q('Embedded tram rail',(.2,.12,length),(side*3.1,.12,0),[82,88,86],'Metal')
 for i in range(int(length/5)):
  q('Inset track tie',(7,.07,.7),(0,.08,-length/2+2.5+i*5),[117,106,88],'WoodPlanks',decor=True)
# Station underpass: roof is a walkable mezzanine, not a solid block.
q=m.local(27,-9)
q('Station mezzanine',(31,1.2,78),(0,12,0),ivory,'Sandstone')
for x in [-14,14]:
 for z in [-35,-12,12,35]:
  q('Station cast-iron column',(.75,11.4,.75),(x,5.7,z),DARK,'Metal')
  q('Column capital',(1.65,.6,1.65),(x,11.1,z),ivory,'Concrete')
  for yy in [1.2,10]:q('Column ferrule',(1,.25,1),(x,yy,z),teal,'Metal',decor=True)
for z in [-37,37]:
 m.arch(27,0,-9+z,width=18,height=11,depth=1.3,c=ivory)
q('Station central storage kiosk',(12,9,14),(0,4.5,0),teal,'Concrete')
q('Station route map',(7,4,.2),(0,6,-7.2),ivory,'Metal',decor=True,label='MERIDIAN / TRAM 04')
for side in [-1,1]:
 for z in [-31,-19,19,31]:
  q('Platform glass canopy rib',(.45,10.4,.45),(side*15,17.8,z),DARK,'Metal')
 q('Station canopy eave',(1,.4,79),(side*16,23,-1),teal,'Metal')
q('Station glass canopy',(33,.28,80),(0,23,0),[132,175,177],'Glass',alpha=.35)
for z in range(-37,40,7):q('Canopy transverse mullion',(33,.15,.22),(0,23.2,z),DARK,'Metal',decor=True)
q('Station roof ridge',(1,.3,80),(0,23.4,0),DARK,'Metal')
m.rail(12,12.65,-1,54,yaw=90)
m.rail(42,12.65,-35,20,yaw=90);m.rail(42,12.65,9,32,yaw=90)
m.stairs(1,-69,width=11,rise=12.6,run=28,c=ivory)
m.box('Concourse transfer landing',(24,1,9),(10,12.2,-38),ivory,'Sandstone')
# Accessible east ramp reaches the same concourse from a second direction.
run=46;rise=12.6;angle=math.degrees(math.atan2(rise,run))
m.box('Station accessible ramp',(12,.8,math.hypot(run,rise)),(53,6.3,10),ivory,'Concrete',rot=[angle,0,0])
m.box('Ramp concourse landing',(25,1,10),(46,12.2,-16),ivory,'Sandstone')
for side in [-1,1]:m.box('Ramp handrail',(.18,.18,math.hypot(run,rise)),(53+side*5.7,9.2,10),DARK,'Metal',rot=[angle,0,0])
# Staggered street-side arcade and cafe building: shopfronts open onto covered passage.
q=m.local(-78,72)
q('Cafe back wall',(52,18,1),(0,9,11),[183,170,139])
q('Cafe west party wall',(1,18,24),(-26,9,0),[183,170,139])
q('Cafe roof terrace',(54,1,26),(0,18,0),ivory,'Sandstone')
# A closed east elevation retains one deliberate 10-stud side doorway.
for zz in [-8.75,8.75]:q('Cafe east doorway pier',(1,18,7.5),(26,9,zz),[183,170,139])
q('Cafe east doorway lintel',(1,8,10.2),(26,14,0),[183,170,139])
# Structural piers join adjacent arches from the floor to the roof. Cut spandrels
# fill the wall above the curved door openings instead of leaving open voids.
for xx in [-9.5,9.5]:q('Arcade structural pier',(6.1,18,1),(xx,9,-12.55),[183,170,139])
for xx in [-26,26]:q('Arcade end pier',(1.1,18,1),(xx,9,-12.55),[183,170,139])
for centre in [-19,0,19]:
 for index in range(26):
  xx=-6.5+(index+.5)*.5
  edge=max(0,abs(xx)-.25)
  openingTop=6.5+math.sqrt(max(0,6.5**2-edge**2))
  height=18-openingTop+.08
  q('Arcade masonry spandrel',(.51,height,1),(centre+xx,18-height/2,-12.55),[183,170,139])
for x in [-19,0,19]:
 m.arch(-78+x,0,59,width=13,height=13,depth=1.6,c=ivory)
 for side in [-1,1]:q('Arcade tiled dado',(6,3,.25),(x+side*7,1.5,-12.9),teal,'CeramicTiles',decor=True)
q('Cafe sign',(26,2.5,.3),(0,15,-13),teal,'Metal',decor=True,label='CAFE / ORIEL')
for x in [-19,0,19]:
 q('Shop glazing',(13,8,.18),(x,7,10.3),GLASS,'Glass',alpha=.2,decor=True)
 for dx in [-6.4,0,6.4]:q('Shop door mullion',(.15,8,.3),(x+dx,7,10.1),DARK,'Metal',decor=True)
for x in [-17,15]:
 q('Cafe table',(5,.25,3.5),(x,3,-2),WOOD,'Wood')
 for dx in [-2,2]:q('Cafe table trestle',(.3,2.8,2.4),(x+dx,1.4,-2),DARK,'Metal')
 q('Cafe bench',(5,.4,1.2),(x,1.7,1.4),WOOD,'Wood')
 q('Cafe bench plinth',(4.5,1.4,.7),(x,.7,1.4),ivory,'Concrete')
for x in [-22,22]:q('Roof pergola upright',(.35,7,.35),(x,22,-8),WOOD,'Wood')
for z in [-9,-3,3,9]:q('Roof pergola beam',(50,.4,.7),(0,25.5,z),WOOD,'Wood')
m.stairs(-111,57,width=9,rise=18,run=36,c=ivory)
m.box('Cafe roof arrival',(15,.8,12),(-106,17.8,99),ivory,'Sandstone')
m.box('Cafe roof connecting catwalk',(14,.8,24),(-104,17.8,90),ivory,'Sandstone')
m.rail(-78,18.5,85,50)
# Rear facades form the city silhouette and prevent escaping the designed streets.
for x,z,w,h,c,yaw in [(-92,-119,75,47,terracotta,0),(72,-125,102,55,cream,0),(-134,10,2,39,cream,0),(134,-33,2,44,terracotta,0),(-132,96,2,44,cream,0),(123,122,33,38,cream,0)]:
 q=m.local(x,z,yaw)
 q('District perimeter facade',(w,h,3),(0,h/2,0),c)
 q('District facade cornice',(w+1,.8,4),(0,h+.2,0),ivory,'Sandstone')
 if w>10:
  for xx in range(int(-w/2+6),int(w/2-4),10):
   for yy in range(7,int(h-4),11):
    q('Background window surround',(5,7,.3),(xx,yy,1.65),ivory,'Sandstone',decor=True)
    q('Background window glazing',(4,5.8,.15),(xx,yy,1.85),GLASS,'Glass',decor=True,alpha=.2)
    q('Background window mullion',(.15,5.8,.2),(xx,yy,2),DARK,'Metal',decor=True)
# Dressed ground plane, utility infrastructure and restrained street furniture.
for z in range(-112,120,12):
 for x in [-51,64]:
  m.box('Sidewalk paving module',(8,.04,10),(x,.04,z),[190,181,161],'Sandstone',decor=True)
  m.box('Sidewalk expansion joint',(.08,.06,9.5),(x,.07,z),[109,112,104],'Concrete',decor=True)
for x,z in [(-43,12),(67,49),(-36,97),(71,-110)]:
 m.planter(x,z,16,5);m.lamp(x+9,z)
for x,z in [(-42,-68),(-42,97),(62,-42),(69,29)]:
 m.box('Tram catenary pole',(.3,25,.3),(x,12.5,z),DARK,'Metal')
 m.box('Tram catenary arm',(22,.22,.22),(x+10,24,z),DARK,'Metal')
for x in [-12,-6]:m.box('Overhead tram cable',(.06,.06,225),(x,24,0),DARK,'Metal',decor=True)
for x,z in [(-38,25),(58,63),(-49,-93),(72,-104)]:
 m.box('Public bin',(2.2,3.2,2.2),(x,1.6,z),teal,'Metal');m.box('Bin crown',(2.5,.3,2.5),(x,3.35,z),DARK,'Metal')
# Spawn shields use the same streetscape vocabulary and leave the spawn point open.
for side in [-1,1]:
 m.planter(side*20,109,14,6)
 m.box('Tram depot spawn screen',(12,9,2),(side*25,4.5,95),cream,'Concrete')
for x,z,yaw in [(-46,11,0),(61,-66,90)]:
 q=m.local(x,z,yaw);q('Street direction plaque',(13,2,.15),(0,8,0),teal,'Metal',decor=True,label='CONCOURSE  /  TRAM 04')
m.save('work/premium_Metro_District.json')

# Aqueduct campus. Dense sandstone engineering and new research galleries create
# three genuinely different paths: west colonnade, central underpass, east ramp.
c=Map('Canyon Crossing',4400,True)
sand=[183,146,109];cut=[215,185,143];rock=[141,109,81];campus=[179,188,181];bronze=[104,92,69]
c.floor(color=[157,139,114],material='Sandstone')
# Overlapping battered cliff faces: bevelled slabs and oval weathered masses break
# the silhouette, with sparse interrupted bedding ledges instead of rectangular seams.
for side in [-1,1]:
 for j in range(9):
  z=-124+j*31
  height=35+(j%3)*4
  c.box('Battered canyon escarpment',(20,height,37),(side*134,height/2,z),rock,'Rock',rot=[(j%3-1)*7,side*(j%4-1.5)*7,side*(8+j%3*3)])
  c.box('Eroded sandstone outcrop',(23,height*.8,32),(side*129,height*.42,z+8),[151,116,85],'Rock',rot=[4+j%3*3,side*(j%3)*11,side*15],shape='Ball')
  c.box('Slanted fractured rock face',(15,height*.65,26),(side*124,height*.31,z-5),[160,125,91],'Rock',rot=[-7,side*13,side*23])
  for k in range(5):
   ledge=13+(j+k)%4*3
   c.box('Interrupted geological bedding',(ledge,.32,17+(k%3)*4),(side*(126+(k%2)*2),3+k*6+(j%3),z+(k%3-1)*7),[161+k*2,124+k*2,91+k*2],'Sandstone',rot=[(j%3-1)*4,side*(k%3-1)*6,side*5],decor=True)
 for z in [-133,133]:
  for j in range(4):
   c.box('Terminal weathered escarpment',(35,30+(j%2)*5,20),(side*(23+j*31),15+(j%2)*2.5,z),rock,'Rock',rot=[(j%3-1)*8,(j%3-1)*9,side*(j%2*7-3)])
   c.box('Terminal rounded sandstone crown',(37,13,25),(side*(23+j*31),29+(j%2)*5,z),[155,121,88],'Rock',rot=[0,j*8,0],shape='Ball')
# Aqueduct is an open arcade across X, located clear of spawn sightlines.
for x in [-96,-72,-48,-24,0,24,48,72,96]:
 c.arch(x,0,3,width=18,height=18,depth=6,c=cut)
 c.box('Aqueduct crown wall',(24,4.5,7),(x,21.5,3),sand,'Sandstone')
 c.box('Aqueduct parapet coping',(24,.7,8),(x,24,3),cut,'Sandstone')
 for side in [-1,1]:
  c.box('Aqueduct walkway edge',(24,.8,.7),(x,20,3+side*5),cut,'Sandstone')
  for j in range(5):c.box('Aqueduct cut masonry joint',(4.6,.04,.1),(x-9.6+j*4.8,22,3+side*3.55),rock,'Concrete',decor=True)
# Walkable gallery above arches and two opposing stair approaches.
c.box('Aqueduct maintenance deck',(224,1,12),(0,19.5,3),cut,'Sandstone')
c.rail(0,20,9,218);c.rail(0,20,-3,218)
c.stairs(-110,-42,width=10,rise=20,run=40,c=cut)
c.stairs(110,48,width=10,rise=20,run=40,yaw=180,c=cut)
c.box('West gallery arrival',(13,1,14),(-108,19.5,2),cut,'Sandstone')
c.box('East gallery arrival',(13,1,14),(108,19.5,2),cut,'Sandstone')
# Western monastery workshop: two stories, barrel-vault entry and sheltered court.
c.building(-76,-77,w=47,d=32,h=13,floors=2,c=sand,trim=cut,roof='flat',title='ARCHIVE / 08')
c.arch(-76,0,-95,width=12,height=12,depth=2,c=cut)
# Roof terrace reached from upper rear deck by a switchback stair inside west yard.
c.stairs(-113,-56,width=8,rise=13,run=26,y=13,c=cut)
c.box('Archive roof landing',(17,1,8),(-107,25.5,-27),cut,'Sandstone')
c.box('Archive roof access bridge',(17,1,40),(-99,25.5,-46),cut,'Sandstone')
# Cliff-cut eastern observatory: open piloted hall rather than another repeated building.
q=c.local(77,66)
q('Laboratory terrace',(60,1.2,50),(0,.6,0),cut,'Sandstone')
q('Lab north wall',(60,17.1,1),(0,8.55,-25),campus)
for x in [-29,29]:q('Laboratory side wing',(1,17.1,51),(x,8.55,0),campus)
for x in [-21,21]:q('Laboratory access pier',(16,17.1,1),(x,8.55,25),campus)
q('Lab lintel',(26.2,5.2,1),(0,14.5,25),campus)
q('Observatory terrace deck',(61,1,51),(0,17.5,0),cut,'Sandstone')
for side in [-1,1]:
 q('Observation glass curtain',(16,9,.18),(side*21,10,25.6),GLASS,'Glass',alpha=.3,decor=True)
 for x in [side*13,side*21,side*29]:q('Observation curtain mullion',(.18,9,.3),(x,10,25.8),bronze,'Metal',decor=True)
q('Lab entrance sign',(20,2,.3),(0,12.5,26),DARK,'Metal',label='KESTREL / FIELD LAB',decor=True)
for x in [-20,20]:
 q('Laboratory workbench',(12,3,4),(x,1.5,-13),METAL,'Metal')
 q('Worktop',(12.5,.25,4.5),(x,3.1,-13),[130,157,157],'Metal')
 for k in range(4):q('Cabinet panel',(2.6,2.4,.1),(x-4.4+k*2.9,1.7,-10.9),campus,'Metal',decor=True)
q('Interior central service core',(8,12,9),(0,6,-6),campus)
# Continuous copper shell: its lower hemisphere is wholly concealed inside a
# tall drum above the laboratory roof. Ribs and seams sit directly on the shell.
q('Observatory sandstone drum',(12,36,36),(0,24,0),cut,'Sandstone',shape='Cylinder',rot=[0,0,90])
q('Continuous patinated copper dome',(36,20,36),(0,30,0),[76,119,108],'Metal',shape='Ball')
# Narrow coping rings conceal the drum/shell join and articulate the masonry base.
for y,radius in [(18.5,18.4),(29.8,18.35)]:
 for seg in range(48):
  theta=seg*math.pi/24
  q('Drum circumferential coping',(2*math.pi*radius/48+.04,.45,.55),(math.cos(theta)*radius,y,math.sin(theta)*radius),bronze,'Metal',rot=[0,90-math.degrees(theta),0],decor=True)
# Meridian ribs follow the ellipsoid surface from equator to ocular.
for seg in range(16):
 theta=seg*math.pi/8
 for arc in range(9):
  a=(arc+.5)*math.pi/20
  radius=18.08*math.cos(a);yy=30+10.08*math.sin(a)
  length=math.hypot(18.08*math.sin(a),10.08*math.cos(a))*math.pi/20+.1
  tilt=math.degrees(math.atan2(10.08*math.cos(a),18.08*math.sin(a)))
  rib=q('Copper standing-seam meridian',(.12,.13,length),(math.cos(theta)*radius,yy,math.sin(theta)*radius),[110,142,119],'Metal',decor=True)
  norm=math.hypot(18.08*math.sin(a),10.08*math.cos(a))
  vx=(-math.sin(theta),0,math.cos(theta));vz=(-18.08*math.sin(a)*math.cos(theta)/norm,10.08*math.cos(a)/norm,-18.08*math.sin(a)*math.sin(theta)/norm)
  vy=(vz[1]*vx[2],vz[2]*vx[0]-vz[0]*vx[2],-vz[1]*vx[0])
  rib['r']=[vx[0],vy[0],vz[0],vx[1],vy[1],vz[1],vx[2],vy[2],vz[2]]
# One restrained upper seam ring is flush to the solid shell, with no open bands.
a=math.pi/4;radius=18.08*math.cos(a);yy=30+10.08*math.sin(a)
for seg in range(48):
 theta=seg*math.pi/24
 q('Copper dome seam',(2*math.pi*radius/48+.03,.12,.14),(math.cos(theta)*radius,yy,math.sin(theta)*radius),[100,133,114],'Metal',rot=[0,90-math.degrees(theta),0],decor=True)
q('Dome ocular housing',(1.3,4.8,4.8),(0,40.2,0),bronze,'Metal',shape='Cylinder',rot=[0,0,90])
q('Ocular glazing',(.15,3.8,3.8),(0,40.95,0),GLASS,'Glass',shape='Cylinder',rot=[0,0,90],alpha=.2,decor=True)
c.stairs(111,27,width=10,rise=18,run=36,c=cut)
c.box('Lab roof arrival',(15,1,13),(107,17.5,68),cut,'Sandstone')
# East branch ramp creates an alternative elevation route to the central aqueduct.
run=54;rise=20;angle=math.degrees(math.atan2(rise,run))
c.box('East aqueduct access ramp',(12,.8,math.hypot(run,rise)),(86,10,-32),campus,'Concrete',rot=[angle,0,0])
c.box('East ramp upper landing',(31,1,12),(92,19.5,-62),cut,'Sandstone')
# Clear gap at aqueduct end allows route to its deck, with lateral transfer.
c.box('East ramp gallery link',(12,1,62),(110,19.5,-31),cut,'Sandstone')
for side in [-1,1]:c.box('East ramp handrail',(.18,.18,math.hypot(run,rise)),(86+side*5.7,13,-32),bronze,'Metal',rot=[angle,0,0])
# Distinct central court: reflecting rill, staggered raised gardens, protected bridge.
c.box('Courtyard rill surround',(16,.7,58),(-16,.35,65),cut,'Sandstone')
c.box('Shallow reflecting rill',(13,.12,54),(-16,.73,65),[77,134,139],'Glass',alpha=.3,decor=True)
for z in [46,76]:c.box('Rill stepping bridge',(20,.45,7),(-16,1,z),cut,'Sandstone')
for x,z in [(-32,-31),(29,37),(-34,94),(31,-96)]:
 c.box('Dressed tactical garden wall',(17,5,5),(x,2.5,z),sand,'Sandstone')
 c.box('Garden wall coping',(18,.5,6),(x,5.25,z),cut,'Sandstone')
 for k in range(7):c.box('Garden wall ashlar division',(.07,4.7,.05),(x-7.2+k*2.4,2.5,z-2.55),rock,'Concrete',decor=True)
# A ceremonial west colonnade gives a sheltered flank with multiple crossovers.
for z in [-32,-10,12,34,56]:
 c.arch(-78,0,z,width=14,height=12,depth=1.8,yaw=90,c=cut)
 c.box('Colonnade entablature',(19,2,22),(-78,13,z),cut,'Sandstone')
 for side in [-1,1]:c.box('Colonnade frieze',(1,.25,21),(-78+side*9,13.2,z),[135,108,79],'Sandstone',decor=True)
# Site utility and stonework are aligned to structures, not scattered clutter.
for side in [-1,1]:
 for z in [-114,111]:
  c.box('Protected spawn wing',(22,8,3),(side*22,4,z-side*8),sand,'Sandstone')
  c.box('Spawn shelter canopy',(22,.8,10),(side*22,9,z-side*8),cut,'Sandstone')
for x,z in [(-45,63),(44,-65),(-46,-114),(46,112)]:c.lamp(x,z)
for z in range(-115,120,12):
 for x in [-47,44]:c.box('Dressed path module',(9,.045,10),(x,.045,z),[192,169,132],'Sandstone',decor=True)
# Geologist reference markings and purposeful expansion joints in plaza stone.
for x in range(-105,110,15):
 for z in [-113,113]:c.box('Courtyard paving inlay',(12,.025,.5),(x,.03,z),bronze,'Metal',decor=True)
for x,z,title in [(-75,-97,'ARCHIVE / WEST'),(78,96,'KESTREL OBSERVATORY'),(-32,20,'AQUEDUCT / 02')]:
 c.box('Campus enamel plaque',(18,2.3,.15),(x,9,z),DARK,'Metal',label=title,decor=True)
c.save('work/premium_Canyon_Crossing.json')
print('Metro',len(m.parts),'Canyon',len(c.parts))
