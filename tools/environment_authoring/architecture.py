"""Shared authored architecture primitives. Coordinates relative to map ground y=10."""
import math,json
from pathlib import Path
def matrix(rot):
 x,y,z=[math.radians(v) for v in rot];cx,sx=math.cos(x),math.sin(x);cy,sy=math.cos(y),math.sin(y);cz,sz=math.cos(z),math.sin(z)
 return [cy*cz,-cy*sz,sy,cx*sz+sx*sy*cz,cx*cz-sx*sy*sz,-sx*cy,sx*sz-cx*sy*cz,sx*cz+cx*sy*sz,cx*cy]
def multiply(a,b):return [sum(a[i*3+k]*b[k*3+j] for k in range(3)) for i in range(3) for j in range(3)]
STONE=[188,174,149];TRIM=[218,207,181];DARK=[48,58,61];WOOD=[99,70,48];GLASS=[92,142,146];METAL=[67,78,82]
class Map:
 def __init__(self,name,cx,duel=False):self.name=name;self.cx=cx;self.duel=duel;self.parts=[]
 def box(self,n,s,p,c=STONE,m='Concrete',yaw=0,rot=None,decor=False,shape=None,alpha=0,label=None):
  d=dict(n=n,s=list(s),p=[p[0]+self.cx,p[1]+10,p[2]],c=c,m=m,yaw=yaw,d=decor)
  if rot:d['rot']=rot
  if shape:d['shape']=shape
  if alpha:d['alpha']=alpha
  if label:d['label']=label
  self.parts.append(d);return d
 def local(self,x,z,yaw=0):
  def place(n,s,p,c=STONE,m='Concrete',**kw):
   a=math.radians(yaw);xx=x+p[0]*math.cos(a)+p[2]*math.sin(a);zz=z-p[0]*math.sin(a)+p[2]*math.cos(a)
   r=kw.pop('rot',None)
   if r is not None:
    result=self.box(n,s,[xx,p[1],zz],c,m,**kw);result['r']=multiply(matrix([0,yaw,0]),matrix(r));return result
   kw['yaw']=kw.get('yaw',0)+yaw
   return self.box(n,s,[xx,p[1],zz],c,m,**kw)
  return place
 def floor(self,w=280,d=280,color=[130,130,120],material='Cobblestone'):
  self.box('Structural ground',(w,2,d),(0,-1,0),color,material)
 def stairs(self,x,z,width=9,rise=14,run=28,y=0,yaw=0,c=STONE):
  q=self.local(x,z,yaw);steps=math.ceil(rise/.5)
  for i in range(steps):
   h=rise*(i+1)/steps;zz=run*(i+.5)/steps
   q('Dressed stone stair tread',(width,h,run/steps+.015),(0,y+h/2,zz),c)
   q('Stair nosing',(width+.15,.07,.18),(0,y+h,run*i/steps+.08),TRIM,decor=True)
  q('Stair top landing',(width+2,.6,6),(0,y+rise-.3,run+2.5),c)
  # inclined handrails and posts parallel to stair centreline
  slope=math.degrees(math.atan2(rise,run))
  for side in [-1,1]:
   q('Inclined handrail',(.18,.18,math.hypot(run,rise)),(side*(width/2+.1),y+rise/2+3,run/2),METAL,'Metal',rot=[-slope,0,0])
   for i in range(5):q('Balustrade post',(.18,3,.18),(side*(width/2+.1),y+rise*i/4+1.5,run*i/4),METAL,'Metal')
 def arch(self,x,y,z,width=10,height=12,depth=2,yaw=0,c=TRIM):
  q=self.local(x,z,yaw);r=width/2;spring=height-r
  for side in [-1,1]:q('Arch jamb',(1.3,spring,depth),(side*(r+.65),y+spring/2,0),c,'Sandstone')
  for i in range(13):
   a=math.pi*(i+.5)/13
   q('Cut arch voussoir',(math.pi*(r+.6)/13+.035,1.3,depth),(math.cos(a)*(r+.65),y+spring+math.sin(a)*(r+.65),0),c,'Sandstone',rot=[0,0,math.degrees(a)-90])
 def rail(self,x,y,z,length,yaw=0,c=METAL):
  q=self.local(x,z,yaw)
  for xx in [-length/2+i*3 for i in range(math.ceil(length/3)+1)]:q('Balcony iron baluster',(.12,3.2,.12),(min(xx,length/2),y+1.6,0),c,'Metal')
  for yy in [.4,3.2]:q('Wrought iron railing',(length,.16,.16),(0,y+yy,0),c,'Metal')
 def building(self,x,z,w=36,d=30,h=14,floors=2,yaw=0,c=STONE,trim=TRIM,roof='gable',title=None):
  q=self.local(x,z,yaw)
  q('Foundation ashlar',(w+1,1,d+1),(0,.5,0),trim,'Sandstone')
  for level in range(floors):
   y=level*h
   if level:q('Timber upper floor',(w,1,d),(0,y-.5,0),WOOD,'WoodPlanks')
   # bays keep a full-height doorway in the centre on BOTH storeys
   for face in [-1,1]:
    for side in [-1,1]:
     q('Facade door pier',(w/2-5,h,.9),(side*(w/4+2.5),y+h/2,face*d/2),c)
     # inset decorative sash on solid pier; no black cutout box
     wx=side*(w/4+2.5)
     q('Deep window reveal',(5.8,7,.22),(wx,y+7.6,face*(d/2+.5)),trim,'Sandstone',decor=True)
     q('Recessed window glazing',(4.5,5.8,.12),(wx,y+7.6,face*(d/2+.65)),GLASS,'Glass',decor=True,alpha=.24)
     for dx in [-2.25,0,2.25]:q('Window mullion',(.13,6,.16),(wx+dx,y+7.6,face*(d/2+.77)),WOOD,'Wood',decor=True)
     q('Window transom',(4.6,.15,.17),(wx,y+7.4,face*(d/2+.8)),WOOD,'Wood',decor=True)
     q('Projecting sill',(6.3,.35,1),(wx,y+4.45,face*(d/2+.65)),trim,'Sandstone')
     for shutter in [-1,1]:
      q('Louvred shutter',(1.6,6,.28),(wx+shutter*3.5,y+7.6,face*(d/2+.6)),[76,110,101],'WoodPlanks',decor=True)
      for k in range(7):q('Shutter slat',(1.45,.12,.38),(wx+shutter*3.5,y+5.2+k*.8,face*(d/2+.78)),[91,125,113],'Wood',decor=True)
    q('Door lintel',(10,4,.9),(0,y+h-2,face*d/2),c)
    if level>0 and face==-1:
     q('Sealed upper window apron',(10,4.5,1.05),(0,y+2.25,face*d/2),c)
     q('Sealed upper window glass',(10,5.5,.35),(0,y+7.25,face*d/2),GLASS,'Glass',alpha=.25)
     for xx in [-5,0,5]:q('Upper window safety frame',(.2,5.6,.5),(xx,y+7.25,face*d/2),WOOD,'Wood')
    for side in [-1,1]:q('Doorway stone surround',(.55,10.3,1.2),(side*5.1,y+5.15,face*d/2),trim,'Sandstone')
    q('Doorway lintel trim',(10.7,.55,1.2),(0,y+10.3,face*d/2),trim,'Sandstone')
   for side in [-1,1]:
    q('Party wall',(.9,h,d),(side*w/2,y+h/2,0),c)
    for face in [-1,1]:
     for k in range(int(h/1.7)):q('Dressed corner quoin',(1.5,.75,1.5),(side*w/2,y+.6+k*1.7,face*d/2),trim,'Sandstone',decor=True)
   q('Interior dado rail',(w-.9,.12,.12),(0,y+3,d/2-.6),trim,'Wood',decor=True)
   q('Interior room divider',(.7,8,d*.25),(w*.22,y+4,d*.21),c)
   q('Interior storage cabinet',(4,6,2.2),(-w*.33,y+3,d*.32),WOOD,'WoodPlanks')
   for k in range(3):q('Cabinet shelf',(4.1,.15,2.3),(-w*.33,y+1+k*1.7,d*.32),trim,'Wood',decor=True)
  top=floors*h
  for face in [-1,1]:
   q('Continuous cornice',(w+2,.6,1.5),(0,top,face*d/2),trim,'Sandstone')
  if roof=='gable':
   angle=24;half=d/2+2;length=half/math.cos(math.radians(angle));rise=half*math.tan(math.radians(angle))
   for side in [-1,1]:
    q('Sloped tiled roof',(w+4,.6,length),(0,top+rise/2+1,side*half/2),[139,79,58],'Slate',rot=[side*angle,0,0])
    q('Rain gutter',(w+4,.28,.35),(0,top+1,side*(half+.1)),METAL,'Metal')
    for row in range(6):q('Tile course',(w+4,.09,.18),(0,top+1+rise*(1-row/6),side*half*row/6),[166,99,70],'Slate',decor=True)
   # Close both triangular gable ends; roof panels alone leave a walk-through hole.
   for end in [-1,1]:
    for halfside in [-1,1]:
     dpart=q('Sealed triangular gable end',(.9,rise,half),(end*w/2,top+.7+rise/2,halfside*half/2),c,rot=[0,180 if halfside>0 else 0,0])
     dpart['class']='WedgePart'
   q('Roof ridge cap',(w+4,.55,.6),(0,top+rise+1,0),[158,89,63],'Slate')
   q('Chimney stack',(3,7,3),(w*.28,top+rise+2,0),c,'Brick')
   q('Chimney cap',(3.6,.6,3.6),(w*.28,top+rise+5.5,0),trim,'Sandstone')
  else:
   q('Accessible roof deck',(w+1,1,d+1),(0,top-.5,0),trim)
   for side in [-1,1]:q('Roof parapet',(.7,2,d),(side*w/2,top+1,0),c)
  # reachable upper rear terrace and stair arrival in line with its doorway
  if floors>1:
   q('Rear upper access terrace',(w+6,1,9),(0,h-.5,d/2+4),trim,'Sandstone')
   a=math.radians(yaw);lx=-w/2-7;lz=d/2-24
   sx=x+lx*math.cos(a)+lz*math.sin(a);sz=z-lx*math.sin(a)+lz*math.cos(a)
   self.stairs(sx,sz,width=8,rise=h,run=28,yaw=yaw,c=trim)
   q('Stair arrival connection',(12,1,8),(-w/2-3,h-.5,d/2+4),trim,'Sandstone')
  if title:q('Enamel business sign',(min(w-2,24),2,.2),(0,12,-d/2-.8),DARK,'Metal',decor=True,label=title)
  return top
 def planter(self,x,z,w=12,d=5):
  self.box('Raised planter',(w,2,d),(x,1,z),TRIM,'Sandstone')
  self.box('Planter soil',(w-1,.2,d-1),(x,2.05,z),[71,65,49],'Ground',decor=True)
  for i in range(max(2,int(w/3))):self.box('Clipped foliage',(3,2.4,d-.8),(x-w/2+2+i*2.7,3.1,z),[64,93,64],'Grass',shape='Ball',decor=True)
 def bollard(self,x,z):
  self.box('Stone bollard',(.8,3,.8),(x,1.5,z),TRIM,'Sandstone')
  self.box('Bollard cap',(1,.25,1),(x,3.1,z),DARK,'Metal',decor=True)
 def lamp(self,x,z,y=0):
  self.box('Lamp iron column',(.22,10,.22),(x,y+5,z),DARK,'Metal')
  self.box('Lantern housing',(1.4,2,1.4),(x,y+10.6,z),DARK,'Metal')
  self.box('Lantern warm glass',(1.15,1.6,1.15),(x,y+10.6,z),[229,205,153],'Neon',decor=True)
  self.box('Lantern crown',(1.9,.35,1.9),(x,y+11.8,z),DARK,'Metal')
 def save(self,path):
  Path(path).write_text(json.dumps(dict(name=self.name,cx=self.cx,duel=self.duel,parts=self.parts),separators=(',',':')))
