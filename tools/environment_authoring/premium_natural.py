from architecture import Map,STONE,TRIM,DARK,WOOD,GLASS,METAL
import math,random
R=random.Random(26)
PINESTONE=[118,130,124];PINEWOOD=[109,79,53];LIGHTWOOD=[157,120,76];SLATE=[52,73,78]
ADOBE=[192,140,103];SAND=[213,175,128];COPPER=[102,136,126];DEEP=[116,78,59]

def cylinder(m,n,x,y,z,height,diam,c,mat='Metal',decor=False):
 return m.box(n,(height,diam,diam),(x,y,z),c,mat,rot=[0,0,90],shape='Cylinder',decor=decor)
def paving(m,x,z,w,d,material='Slate',c=[132,139,132],pitch=6):
 for ix in range(max(1,int(w/pitch))):
  for iz in range(max(1,int(d/pitch))):
   m.box('Cut paving flag',(pitch-.12,.05,pitch-.12),(x-w/2+pitch*(ix+.5),.04,z-d/2+pitch*(iz+.5)),[v+R.randrange(-4,5) for v in c],material,decor=True)
def pipe(m,x,z,height=18,y=0):
 cylinder(m,'Vertical service pipe',x,y+height/2,z,height,.55,[71,86,88])
 for yy in [y+2,y+height-2]:
  cylinder(m,'Pipe flange',x,yy,z,.22,.9,[111,125,123],decor=True)
  for a in [0,90,180,270]:
   rad=math.radians(a);cylinder(m,'Flange bolt',x+math.cos(rad)*.3,yy+.15,z+math.sin(rad)*.3,.13,.12,[174,180,168],decor=True)
def stonebench(m,x,z,w=12,c=PINESTONE):
 m.box('Dressed stone bench seat',(w,.6,3),(x,2.3,z),c,'Sandstone')
 for side in [-1,1]:m.box('Bench stone foot',(2,2,2.6),(x+side*(w/2-2),1,z),c,'Sandstone')
def trees(m):
 # Cedar canopies are restricted to backdrop/perimeter; playable centre remains clear.
 for x,z,h in [(-126,-112,29),(-120,-80,36),(-127,-35,31),(-124,14,35),(-127,65,32),(128,-113,37),(125,-77,29),(129,-18,34),(127,54,31),(124,98,33),(-91,-126,27),(-45,-127,35),(5,-128,30),(96,-126,29),(-91,128,30),(86,126,28)]:
  cylinder(m,'Cedar trunk',x,h/2,z,h,1.7,[90,66,45],'Wood')
  for level in range(5):
   span=13-level*2.0;cy=h*.47+level*3
   m.box('Layered cedar foliage',(span,5.6,span),(x,cy,z),[48+level*2,77+level*3,63+level],'Grass',shape='Ball',decor=True)
  for yy in [3,7,11]:
   m.box('Cedar bark fissure',(.07,2,.05),(x+.84,yy,z-.2),[59,49,38],'Wood',decor=True)

def pine():
 m=Map('Pine Ridge',700);m.floor(282,282,[119,126,111],'Ground')
 # Terraced retaining edges form the scene silhouette, avoiding a bare square arena wall.
 for side in [-1,1]:
  for k in range(8):
   z=-120+k*34;h=15+(k%3)*4
   m.box('Stratified ridge escarpment',(15,h,32),(side*136,h/2-1,z),[91+k%2*7,108,99],'Rock',yaw=side*(4+k%2*5))
   m.box('Ridge moss shelf',(18,.5,28),(side*134,h-.8,z),[83,105,76],'Grass',decor=True)
   for j in range(3):m.box('Rock sediment seam',(.12,.12,24),(side*(128.4-j*.02),3+j*3.5,z),[67,84,79],'Rock',decor=True)
 for x in range(-120,130,24):
  m.box('Rear retaining ashlar',(23,10,3),(x,5,136),PINESTONE,'Sandstone')
  m.box('Retaining capstone',(24,.5,4),(x,10.2,136),[156,165,149],'Sandstone')
 # Lodge and service annex have different proportions, rooflines and functions.
 m.building(-61,-55,w=56,d=40,h=14,floors=2,yaw=0,c=[156,148,120],trim=[171,171,147],title='RIDGE / HYDROGRAPHIC STATION')
 # Structural timber rhythm and deep porch distinguish the alpine lodge from masonry city assets.
 q=m.local(-61,-55)
 for level in range(2):
  for x in [-28,-14,0,14,28]:q('Lodge timber frame',(.8,13.5,1.1),(x,7+level*14,-20.7),PINEWOOD,'Wood')
  for yy in [1.4,13.6,27.3]:q('Lodge continuous timber beam',(57,.65,1.2),(0,yy,-20.7),PINEWOOD,'Wood')
  for x in [-21,21]:
   for k in range(7):q('Alpine cladding board',(11.5,.6,.28),(x,2.3+level*14+k*1.65,-20.6),[147,122,86],'WoodPlanks',decor=True)
 for x in [-22,-11,0,11,22]:
  q('Covered porch post',(.85,11,.85),(x,5.5,-29),PINEWOOD,'Wood')
  q('Porch post stone shoe',(1.3,1.4,1.3),(x,.7,-29),PINESTONE,'Sandstone')
 q('Deep lodge porch floor',(62,.45,13),(0,.25,-26),[143,129,100],'WoodPlanks')
 q('Porch canopy',(63,.45,15),(0,11.8,-26),SLATE,'Slate',rot=[-5,0,0])
 for k in range(9):q('Canopy standing seam',(.1,.17,15),(-30+k*7.5,12,-26),[81,104,104],'Metal',decor=True)
 # Lodge furnishing reads through real open doorways and a traverse through the lower floor.
 for x in [-18,18]:
  q('Survey worktable',(9,.6,4),(x,3,7),PINEWOOD,'Wood')
  for side in [-1,1]:q('Table leg',(.5,2.7,.5),(x+side*3,1.5,7),[65,76,72],'Metal')
  q('Chart folio',(5,.04,2.7),(x,3.35,7),[191,191,158],'Fabric',decor=True)
 q('Stone chimney hearth',(7,8,3),(-23,4,17),PINESTONE,'Slate')
 q('Hearth opening',(4.7,4,.1),(-23,2.4,15.4),[37,42,37],'Slate',decor=True)
 # Two-storey turbine hall bespoke long-span industrial timber structure.
 hall=m.local(67,8)
 hall('Turbine hall foundation',(48,1,68),(0,.5,0),PINESTONE,'Concrete')
 hall('Turbine hall rear',(49,20.8,1.4),(0,10.4,-34),[114,139,134],'Metal')
 # Complete a continuous solid wall envelope; only framed maintenance/gallery doors remain open.
 for side in [-1,1]:
  if side==-1:
   hall('Turbine lower side wall',(1.3,10.6,69),(side*24,5.3,0),[122,119,91],'WoodPlanks')
  else:
   for zz in [-22,22]:hall('Turbine lower door pier',(1.3,10.6,24),(side*24,5.3,zz),[122,119,91],'WoodPlanks')
   hall('Side maintenance lintel',(1.3,2.6,20),(side*24,9.3,0),PINEWOOD,'Wood')
  hall('Turbine side cornice',(1.5,1.8,69),(side*24,20.3,0),PINEWOOD,'Wood')
 for side in [-1,1]:hall('Front maintenance door pier',(17.5,20.8,1.4),(side*15.25,10.4,34),[114,139,134],'Metal')
 hall('Front maintenance door lintel',(14.5,8.3,1.4),(0,16.65,34),[114,139,134],'Metal')
 for zz in [-34,34]:
  for k in range(12):
   y=20.35+k*.49;ww=max(.3,min(49,2*(26.1-y)/math.tan(math.radians(13))))
   hall('Hall gable end infill',(ww,.51,1.4),(0,y,zz),[114,139,134],'Metal')
 hall('Upper gallery door lintel',(1.6,.6,11),(24,20.8,-5),PINEWOOD,'Wood')
 for zz in [-10.2,.2]:hall('Upper gallery door jamb',(1.6,8.5,.5),(24,16.55,zz),PINEWOOD,'Wood')
 for side in [-1,1]:
  # side openings divide work bays while leaving large maintenance doors
  for z in [-27,-9,9,27]:
   hall('Glulam structural column',(1.3,21,1.3),(side*24,10.5,z),PINEWOOD,'Wood')
   if side==1 and z==-9:
    hall('Gallery door side glazing',(1.05,10.6,8.1),(24,15.5,-14.05),[100,153,151],'Glass',alpha=.25)
    hall('Gallery door lower infill',(1.05,2.5,10.2),(24,11.75,-5),[122,119,91],'WoodPlanks')
   else:
    hall('Industrial glazing',(1.05,10.6,18.2),(side*24,15.5,z),[100,153,151],'Glass',alpha=.25)
   for zz in [-7.5,0,7.5]:hall('Industrial glazing mullion',(1.1,9.6,.16),(side*24,14.8,z+zz),[55,82,82],'Metal',decor=True)
  hall('Service gallery',(6,1,64),(side*20,12.5,0),[135,130,100],'WoodPlanks')
  for z in [-29,-11,7,25]:
   hall('Gallery stanchion',(.15,3,.15),(side*17,14.5,z),METAL,'Metal')
  hall('Gallery handrail',(.15,.18,64),(side*17,16,0),METAL,'Metal')
  hall('Gallery solid glass guard',(.1,2.8,64),(side*17,14.5,0),[120,157,151],'Glass',alpha=.6)
 hall('Back service bridge',(42,1,9),(0,12.5,-28),[126,133,118],'WoodPlanks')
 for side in [-1,1]:
  hall('Standing seam hall roof',(26,.55,72),(side*12.5,23.2,0),SLATE,'Metal',rot=[0,0,-side*13])
  for x in [2,7,12,17,22]:hall('Roof seam ridge',(.11,.1,72),(side*x,26.05-x*.23,0),[90,114,112],'Metal',decor=True)
 for z in [-27,-9,9,27]:hall('Glulam roof crossbeam',(49,1.3,1.2),(0,20.5,z),PINEWOOD,'Wood')
 hall('Service fascia',(22,2,.2),(0,18,34.7),DARK,'Metal',label='02 / TURBINE WORKS')
 m.stairs(100,-25,width=8,rise=13,run=26,yaw=0,c=PINESTONE)
 m.box('Gallery external connection',(16,1,8),(91,12.5,3),PINESTONE,'Concrete')
 # Three distinct turbines and service plinths: macro silhouette before fine details.
 for z in [-17,9]:
  cylinder(m,'Turbine pressure casing',66,4.2,z,6.5,9,[73,115,111],'Metal')
  cylinder(m,'Turbine top flange',66,7.7,z,.6,10,[117,149,139],'Metal')
  cylinder(m,'Generator spindle',66,9.2,z,2.6,2,[82,94,94],'Metal')
  for a in range(0,360,30):
   r=math.radians(a);cylinder(m,'Pressure flange fixing',66+math.cos(r)*4.3,8.1,z+math.sin(r)*4.3,.3,.4,[178,181,161],'Metal',True)
  m.box('Turbine console',(4,5,3),(74,2.5,z+1),[74,92,90],'Metal')
  m.box('Turbine console panel',(3.5,1.5,.12),(74,4.2,z-.55),[132,174,161],'Glass',decor=True)
  for k in range(4):m.box('Control-panel toggle',(.3,.2,.16),(72.8+k*.8,3.5,z-.66),[208,193,134],'Metal',decor=True)
 # Concrete-lined raceway cuts diagonally through composition; two bridges form alternate routes.
 for z in range(-112,80,16):
  m.box('Raceway water surface',(14,.08,15.9),(2,.12,z),[67,139,143],'Glass',decor=True,alpha=.28)
  for side in [-1,1]:m.box('Raceway stone coping',(1.2,1,16),(2+side*7.6,.5,z),[153,164,148],'Sandstone')
  for k in [-4,0,4]:m.box('Raceway current glint',(.12,.03,4),(2+k,.18,z+R.uniform(-3,3)),[129,185,179],'Glass',decor=True,alpha=.5)
 for z in [-76,39]:
  m.box('Raceway pedestrian bridge',(24,.7,12),(2,1.2,z),[138,121,87],'WoodPlanks')
  for side in [-1,1]:m.rail(2,1.55,z+side*6,24,c=[85,101,94])
  # gentle approach ramps are actual sloped surfaces
  for side in [-1,1]:m.box('Bridge ramp',(12,.5,12),(2+side*18,.5,z),[138,121,87],'WoodPlanks',rot=[0,0,-side*5.5])
 # Weir landmark, flanking route through moss-stained hydro infrastructure.
 m.box('Weir wall',(43,12,5),(0,6,-112),PINESTONE,'Concrete')
 m.box('Weir deck',(49,.7,11),(0,12.3,-112),[141,151,136],'Concrete')
 for x in [-15,0,15]:
  m.box('Weir spill opening',(9,7,.2),(x,5,-109.4),[46,68,66],'Slate',decor=True)
  m.box('Weir water curtain',(8,6.7,.08),(x,5,-109.2),[86,156,152],'Glass',decor=True,alpha=.4)
  m.box('Weir gate beam',(1,11,2),(x+5.2,6,-108.5),[83,111,106],'Metal')
 for x in [-22,22]:pipe(m,x,-109,18)
 m.stairs(-31,-135,width=8,rise=12.7,run=24,c=PINESTONE)
 m.box('Weir stair landing',(16,1,12),(-22,12.2,-111),PINESTONE)
 # Trail surface, guardhouse cover and planted pockets remain clear of the spawn centre.
 paving(m,-39,50,30,60,'Slate',[126,139,125]);paving(m,40,86,60,24,'Slate',[126,139,125])
 for x,z in [(-52,30),(-20,-10),(24,68),(44,-66),(-75,85)]:
  m.planter(x,z,12,5);stonebench(m,x,z+5)
 for x,z in [(-34,80),(28,80),(-102,-91),(106,77),(-36,-99),(35,-100)]:m.lamp(x,z)
 for x,z in [(-48,25),(88,69),(-92,-7)]:
  m.box('Stacked cordwood shelter',(13,1,7),(x,.5,z),PINESTONE,'Sandstone')
  for row in range(3):
   for col in range(7):m.box('Seasoned cordwood',(1.4,1.4,5),(x-4.8+col*1.5,1.6+row*1.3,z),[134+row*4,102,61],'Wood',shape='Cylinder',rot=[0,90,0])
  m.box('Cordwood rain roof',(15,.5,9),(x,6,z),SLATE,'Slate',rot=[-8,0,0])
 trees(m)
 # Siding rows on turbine hall and textured lodge foundation (architectural detail, not clutter).
 for side in [-1,1]:
  for z in range(-23,42,4):
   for yy in [1.8,3.2,4.6,6.0,7.4]:m.box('Turbine lower timber infill',(.4,1.15,3.8),(67+side*24.3,yy,z),[126,112,80],'WoodPlanks',decor=True)
 for z in [-35,-75]:
  for x in range(-88,-31,4):
   for yy in [1,2]:m.box('Lodge foundation coursing',(3.8,.12,.08),(x,yy,z-.6),[115,121,105],'Sandstone',decor=True)
 m.save('work/premium_Pine_Ridge.json');return m

def mesa():
 m=Map('Red Mesa',1400);m.floor(282,282,[177,135,94],'Sandstone')
 # Escarpment is layered and setback, creating a canyon site instead of four perimeter boxes.
 for side in [-1,1]:
  for i in range(9):
   z=-128+i*32;x=side*(130+4*math.sin(i*1.7));height=24+5*math.sin(i*.7)
   for band in range(5):
    w=17-band*1.5;yy=band*5
    m.box('Eroded sandstone stratum',(w,5.2,34),(x+side*band*.8,yy+2.4,z),[174+band*8,119+band*7,78+band*5],'Sandstone',yaw=side*(i%3*5-4))
   for k in range(3):m.box('Bedded stone crack',(.09,.08,25),(x-side*9,4+k*6,z),DEEP,'Rock',decor=True)
 for x in range(-120,130,25):
  m.box('Adobe perimeter buttress',(24,18,5),(x,9,136),ADOBE,'Concrete')
  m.box('Perimeter mud coping',(25,1,6),(x,18.3,136),SAND,'Sandstone')
 # Southwest courtyard house: cool shaded arcades, deep reveals, flat roof silhouette.
 m.building(-68,36,w=44,d=37,h=13,floors=2,c=ADOBE,trim=SAND,roof='flat',title='CASA DEL SOL / SURVEY ARCHIVE')
 q=m.local(-68,36)
 for face in [-1,1]:
  for x in [-24,-12,0,12,24]:
   if abs(x)<1:continue
   q('Projecting vigas',(1,1,4),(x,25,face*20),[102,70,48],'Wood')
 q('Adobe roof access doorway',(9,9,1),(8,30,8),ADOBE)
 q('Roof doorway lintel',(10,1,2),(8,35,8),SAND)
 for side in [-1,1]:q('Roof equipment alcove',(1,8,7),(8+side*5,30,11),ADOBE)
 # Archive uses the shared rear-terrace stair only; no disconnected second stair.
 # Observatory: cylindrical drum with true open entry segments and upper annular gallery.
 cx,cz=61,-64;radius=23
 cylinder(m,'Observatory foundation',cx,.6,cz,1.2,52,SAND,'Sandstone')
 # circular walls leave four metre-wide entry gaps front and rear
 for i in range(32):
  a=2*math.pi*i/32;x=cx+math.sin(a)*radius;z=cz+math.cos(a)*radius
  if abs(math.sin(a))<.27:continue
  m.box('Observatory curved adobe drum',(4.8,16,2),(x,8,z),ADOBE,'Concrete',yaw=math.degrees(a))
  m.box('Observatory cut-stone socle',(5.2,1.1,2.5),(x,.7,z),SAND,'Sandstone',yaw=math.degrees(a))
  m.box('Observatory cornice',(5.2,.7,3),(x,16.2,z),SAND,'Sandstone',yaw=math.degrees(a))
  for yy in [4,8,12]:m.box('Drum plaster band',(4.6,.06,.08),(x+math.sin(a)*1.05,yy,z+math.cos(a)*1.05),[170,115,81],'Concrete',yaw=math.degrees(a),decor=True)
 # Frame the two intended ground-level entries; matching lintels close the upper wall gap.
 for side in [-1,1]:
  zz=cz+side*22
  m.box('Observatory entry lintel',(18,5.2,2.6),(cx,13.6,zz),ADOBE,'Concrete')
  for xx in [-8.8,8.8]:m.box('Observatory entry jamb',(1.4,11.3,2.8),(cx+xx,5.65,zz),SAND,'Sandstone')
 # flat upper disk, huge oxidized dome as landmark; lower dome rim begins above accessible gallery
 cylinder(m,'Observation deck',cx,16,cz,1,51,SAND,'Sandstone')
 m.box('Patinated observatory dome',(39,25,39),(cx,29.5,cz),COPPER,'Metal',shape='Ball')
 cylinder(m,'Dome equatorial band',cx,23,cz,.8,39.5,[69,109,104],'Metal')
 # slit shell atop dome; silhouette evokes a telescope enclosure without pretending a copied asset
 m.box('Dome telescope aperture',(4.6,15,1),(cx,30.5,cz+18),[37,64,65],'Metal',decor=True)
 for side in [-1,1]:m.box('Dome aperture shutter',(.5,17,2),(cx+side*2.8,30.5,cz+18),[130,156,139],'Metal',decor=True)
 for i in range(24):
  a=2*math.pi*i/24
  m.box('Deck baluster',(.18,3.1,.18),(cx+math.sin(a)*25.1,18,cz+math.cos(a)*25.1),DEEP,'Metal')
  m.box('Deck curved top rail',(6.7,.18,.18),(cx+math.sin(a)*25.1,19.5,cz+math.cos(a)*25.1),DEEP,'Metal',yaw=math.degrees(a)+90)
 # Broad south stair, gallery connector and sheltered lower workroom.
 m.stairs(61,-7,width=12,rise=16.5,run=33,yaw=180,c=SAND)
 m.box('Observatory stair arrival',(16,1,16),(61,16,-44),SAND,'Sandstone')
 for x in [48,74]:
  m.box('Astronomer desk',(8,.7,3.5),(x,3.2,-65),[123,81,47],'Wood')
  for side in [-1,1]:m.box('Desk trestle',(.7,3,.7),(x+side*2.5,1.5,-65),DEEP,'Wood')
  m.box('Celestial chart',(6,.05,3),(x,3.6,-65),[214,196,145],'Fabric',decor=True)
 cylinder(m,'Survey telescope pier',61,4,-68,7,3,[92,103,98],'Metal')
 m.box('Telescope optical barrel',(12,2,2),(61,8,-68),[125,146,130],'Metal',rot=[-20,90,0],shape='Cylinder')
 # Main arcade: continuous covered bend that blocks the spawn-to-spawn centreline.
 for x in [-35,-18,-1,16]:
  m.arch(x,0,7,width=12,height=13,depth=2.5,c=SAND)
  m.arch(x,0,-10,width=12,height=13,depth=2.5,c=SAND)
 m.box('Arcade vaulted roof',(70,1.5,21),(-10,15.5,-1.5),ADOBE,'Concrete')
 for x in [-43,-27,-10,7,24]:m.box('Arcade roof coping',(1.3,1,22),(x,16.5,-1.5),SAND,'Sandstone')
 for x in range(-40,26,5):
  for z in [-8,-3,2,7]:m.box('Arcade terracotta floor tile',(4.8,.07,4.8),(x,.06,z),[177,114,75],'Brick',decor=True)
 # Covered cloister exit walls, with offset arches rather than a single box obstruction.
 m.box('Archive courtyard privacy wall',(6,12,47),(-36,6,68),ADOBE,'Concrete')
 m.arch(-26,0,83,width=13,height=14,depth=3,c=SAND)
 m.box('Courtyard gateway cornice',(22,1.2,5),(-26,15,83),ADOBE)
 # Rooftop ridge route via low caravansary service wing.
 m.building(-65,-70,w=43,d=27,h=11,floors=1,yaw=0,c=[178,123,88],trim=SAND,roof='flat',title='NORTH / CARAVANSERAI')
 m.stairs(-96,-98,width=9,rise=11,run=23,c=SAND)
 m.box('Caravansary roof arrival',(18,1,8),(-87,10.5,-73),SAND)
 for x in [-81,-62,-43]:m.arch(x,0,-53,width=10,height=11,depth=2,c=SAND)
 m.box('Caravansary shaded porch',(60,1,12),(-62,11.5,-49),ADOBE)
 # Central fountain: octagonal stepped basin, low tactical silhouette, no tall visual clutter.
 for i in range(8):
  a=math.pi*i/4;x=math.sin(a)*12;z=47+math.cos(a)*12
  m.box('Fountain octagonal curb',(10,.7,1.5),(x,.65,z),SAND,'Sandstone',yaw=math.degrees(a)+90)
  m.box('Fountain stepped base',(11,.4,3),(x,.2,z),[180,143,103],'Sandstone',yaw=math.degrees(a)+90)
 cylinder(m,'Fountain water surface',0,.42,47,.08,23,[88,151,147],'Glass',True)
 cylinder(m,'Fountain carved plinth',0,1.8,47,3,3.5,SAND,'Sandstone')
 cylinder(m,'Fountain shallow dish',0,3.2,47,.6,8,SAND,'Sandstone')
 # Rill leads away from spawn and frames two paths around the basin.
 for z in range(67,102,7):
  m.box('Courtyard water rill',(1.3,.08,6.9),(0,.12,z),[88,151,147],'Glass',decor=True,alpha=.28)
  for side in [-1,1]:m.box('Rill edge',(1.1,.25,7),(side*1.15,.12,z),SAND,'Sandstone')
 paving(m,0,46,48,48,'Sandstone',[205,165,119]);paving(m,40,92,48,24,'Sandstone',[205,165,119])
 # Eastern botanical wall: barrel cacti, azulejo niches, dense native pots as authored groups.
 for x,z in [(95,73),(107,25),(-111,83),(-108,-24),(31,-112)]:
  m.box('Garden terrace',(14,1,10),(x,.5,z),SAND,'Sandstone')
  for dx,dz,scale in [(-3,0,1),(3,2,.8),(0,-2,.6)]:
   cylinder(m,'Terracotta planter',x+dx,1.7,z+dz,2.4*scale,3*scale,[159,89,57],'Brick')
   m.box('Cactus barrel',(2.4*scale,4.6*scale,2.4*scale),(x+dx,3.8*scale,z+dz),[89,118,78],'Grass',shape='Ball',decor=True)
   for side in [-1,1]:m.box('Cactus rib',(.1,3*scale,.1),(x+dx+side*.65*scale,3.7*scale,z+dz-.9*scale),[126,145,91],'Grass',decor=True)
 # Niches and seating create plausible occupied courtyards and predictable cover.
 for x,z in [(-8,-37),(92,51),(-100,5),(52,69)]:
  stonebench(m,x,z,12,SAND)
  m.box('Adobe garden screen',(14,6,2),(x,3,z+4),ADOBE,'Concrete')
  for dx in [-4,0,4]:
   m.box('Screen inset tile',(2,2,.1),(x+dx,3.5,z+2.95),[85,128,125],'Slate',decor=True)
   for yy in [2.7,4.3]:m.box('Tile pattern line',(1.6,.08,.08),(x+dx,yy,z+2.87),SAND,'Sandstone',decor=True)
 for x,z in [(-26,104),(28,105),(-103,-101),(103,-111),(-16,-38),(98,13)]:m.lamp(x,z)
 # Detailed parapet channels and shutter screens on archive flank.
 for side in [-1,1]:
  for z in range(21,54,4):
   for yy in [4,8,12,17,21]:m.box('Adobe settlement joint',(.08,.04,3.6),(-68+side*22.55,yy,z),[158,108,77],'Concrete',decor=True)
 # Observatory annular pavers and drum radial ribbing visibly resolve its curvature.
 for i in range(48):
  a=2*math.pi*i/48
  m.box('Radial deck stone',(2.8,.05,4.3),(61+math.sin(a)*22.7,16.55,-64+math.cos(a)*22.7),[207+(i%3)*2,172,126],'Sandstone',yaw=math.degrees(a),decor=True)
  if i%2==0:m.box('Observatory copper seam',(.12,14,.12),(61+math.sin(a)*18,30,-64+math.cos(a)*18),[65,110,103],'Metal',decor=True)
 m.save('work/premium_Red_Mesa.json');return m
if __name__=='__main__':
 for m in [pine(),mesa()]:print(m.name,len(m.parts))
