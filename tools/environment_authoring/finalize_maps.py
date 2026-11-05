import json
from pathlib import Path
files=['Pine_Ridge','Red_Mesa','Metro_District','Dockyard','Switchyard','Canyon_Crossing','Old_Town','RiftArena']
for f in files:
 path=Path('work/premium_'+f+'.json');m=json.loads(path.read_text());m['parts']=[p for p in m['parts'] if not p['n'].startswith('Map containment') and p['n']!='Sculpted sandstone escarpment' and p['n']!='Range entrance apron']
 cx=m['cx'];training=m['name']=='RiftArena';xmin,xmax=(-149,149) if training else (-142,142);zmin,zmax=(-260,154) if training else (-142,142)
 for axis,value in [('West',xmin),('East',xmax),('South',zmax),('North',zmin)]:
  side=axis in ['West','East'];s=[2,180,zmax-zmin+2] if side else [xmax-xmin+2,180,2];p=[cx+value,80,(zmax+zmin)/2] if side else [cx+(xmax+xmin)/2,80,value]
  m['parts'].append(dict(n='Map containment '+axis,s=s,p=p,c=[80,80,80],m='SmoothPlastic',yaw=0,d=False,alpha=1))
 if training:m['parts'].append(dict(n='Range entrance apron',s=[294,2,25],p=[0,9,141],c=[119,130,137],m='Concrete',yaw=0,d=False))
 if m['name'] in ['Canyon Crossing','Red Mesa']:
  for side in [-1,1]:
   for z in [-103,-30,49,116]:
    m['parts'].append(dict(n='Sculpted sandstone escarpment',s=[43,37,22],p=[cx+side*140,28,z],c=[255,255,255],m='SmoothPlastic',yaw=side*90,d=True,**{'class':'MeshPart','mesh':'rbxassetid://83854563742889','texture':'rbxassetid://74617959013200','initialSize':[23.088438,23.497683,22.999998]}))
 path.write_text(json.dumps(m,separators=(',',':')))
print('Added continuous map boundaries, range apron, and authored cliff asset')
