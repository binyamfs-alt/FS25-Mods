from pathlib import Path
from lupa.lua51 import LuaRuntime

root = Path(__file__).parent
lua = LuaRuntime()
lua.execute((root / 'scripts/RowPlanner.lua').read_text())
lua.execute('''
for spacing=1,10 do
    for _, length in ipairs({0,0.05,1,4.99,5,5.01,35,35.01,100,499.9,500}) do
        local points, measured = ADParkingRowPlanner.points(10,20,10+length,20,spacing)
        assert(points ~= nil and #points >= 1)
        if length >= 0.1 then
            assert(math.abs(measured-length)<1e-8)
            assert(math.abs(points[#points].x-(10+length))<1e-8)
            assert(#points==math.ceil(length/spacing)+1)
        end
        for i,p in ipairs(points) do
            assert(p.z==20)
            if i>1 then assert(p.x-points[i-1].x<=spacing+1e-8) end
        end
    end
end
local p,l=ADParkingRowPlanner.points(0,0,30,40,5)
assert(l==50 and #p==11)
for _,point in ipairs(p) do assert(math.abs(point.x*4-point.z*3)<1e-8) end
assert(ADParkingRowPlanner.points(0,0,501,0,5)==nil)
assert(ADParkingRowPlanner.points(0,0,10,0,0)==nil)
assert(ADParkingRowPlanner.points(0,0,10,0,11)==nil)
local calls={};local graph={createWayPointWithConnections=function(self,x,y,z,out,incoming,flags,connect,reverse,dual,event)
 assert(#out==0 and #incoming==0 and not connect and not reverse and not dual and event==true)
 assert(flags==1 and y==x+z)
 calls[#calls+1]={out=out,incoming=incoming}
end}
assert(ADParkingRowPlanner.create(graph,p,1,function(x,z)return x+z end)==11)
assert(calls[1].out~=calls[2].out and calls[1].incoming~=calls[2].incoming)
local before=#calls
local ok=pcall(ADParkingRowPlanner.create,graph,p,1,function(x,z) if x>10 then error('height unavailable') end return x+z end)
assert(not ok and #calls==before) -- preflight before writing graph
''')
lua.execute('''
function Class(c,base) c.__index=c;setmetatable(c,{__index=base});return {__index=c,__metatable='protected'} end
ConstructionBrush={new=function(mt,...)assert(select('#',...)==0);return setmetatable({},mt)end}
Logging={info=function()end,warning=function()end,error=function()end}
addModEventListener=function()end
ConstructionBrushPlaceable={new=function(item,cursor,...)return 'originalFactory',nil,select('#',...)end}
ConstructionScreen={onButtonPrimary=function()return 'original' end,onButtonSecondary=function()end,
 onButtonTertiary=function()end,onButtonFourth=function()end,onAxisSecondary=function()end,onAxisPrimary=function()end,
 draw=function(self)self.wasDrawn=true;return 4,nil,6 end,
 loadCurrentConfiguration=function(self,item) self.defaultPreviewLoaded=true;return 'standardPreview',nil,3 end}
getTerrainHeightAtWorldPos=function(_,x,_,z)return x+z end
g_terrainNode=1
drawDebugLine=function()end;setTextColor=function()end;renderText=function()end
local calls={}
FS25_AutoDrive={AutoDrive={FLAG_NONE=0,FLAG_SUBPRIO=1},ADGraphManager={createWayPointWithConnections=function(self,...)
 calls[#calls+1]={...}
end}}
graphCalls=calls
''')
lua.execute((root / 'scripts/ParkingBrush.lua').read_text())
lua.execute((root / 'scripts/ADParkingNodes.lua').read_text())
lua.execute('''
local cursor={getHitTerrainPosition=function()return 0,0,0 end}
local b=ADParkingBrush.new({},cursor)
local s={brush=b,selectorBrush={},setBrush=function(self,new)self.brush=new end}
b:update(16);ConstructionScreen.onButtonPrimary(s);assert(b.anchor.x==0 and #graphCalls==0)
cursor.getHitTerrainPosition=function()return 35,0,0 end
b:update(16);assert(#b.preview==8)
ConstructionScreen.onButtonTertiary(s);assert(b.secondary)
ConstructionScreen.onButtonPrimary(s);assert(#graphCalls==8 and graphCalls[1][6]==1 and b.anchor==nil)
for i=1,20 do ConstructionScreen.onAxisPrimary(s,'size',1) end;assert(b.spacing==10)
for i=1,20 do ConstructionScreen.onAxisPrimary(s,'size',-1) end;assert(b.spacing==1)
ConstructionScreen.onButtonPrimary(s);assert(b.anchor~=nil)
ConstructionScreen.onButtonSecondary(s);assert(b.anchor==nil)
ConstructionScreen.onButtonSecondary(s);assert(s.brush==s.selectorBrush)
assert(ConstructionScreen.onButtonPrimary(s)=='original')
local fn=ConstructionScreen.onButtonPrimary;ADParkingNodes.install();assert(fn==ConstructionScreen.onButtonPrimary)
local item={xmlFilename='C:/mods/FS25_z_ADRowTool/parkingNodes.xml'}
local custom=ConstructionBrushPlaceable.new(item,cursor)
assert(custom.isADParkingBrush and custom.storeItem==item)
local a,b,c=ConstructionBrushPlaceable.new({xmlFilename='C:/mods/other/parkingNodes.xml'},cursor,1,nil,3)
assert(a=='originalFactory' and b==nil and c==3)
-- Actual screen lifecycle: reusable brush constructed with no selected item.
assert(ConstructionBrushPlaceable.new(nil,cursor)=='originalFactory')
local deferred={cursor=cursor,brush={},selectorBrush={activate=function()end},setBrush=function(self,brush)
 self.brush=brush
 brush:activate() -- the real screen immediately calls the new brush
end}
ConstructionScreen.loadCurrentConfiguration(deferred,item)
assert(deferred.brush.isADParkingBrush and not deferred.defaultPreviewLoaded)
local active=deferred.brush
ConstructionScreen.loadCurrentConfiguration(deferred,item);assert(deferred.brush==active)
a,b,c=ConstructionScreen.loadCurrentConfiguration(deferred,{xmlFilename='C:/other/tool.xml'})
assert(a=='standardPreview' and b==nil and c==3)
-- Cached screen callback bypasses configuration/factory hooks: recover from
-- actual Placeable.configFileName, not guessed catalog arguments.
g_storeManager={getItemByXMLFilename=function(self,name)assert(name==item.xmlFilename);return item end}
local cached={cursor=cursor,brush={placeable={configFileName=item.xmlFilename}},setBrush=deferred.setBrush}
a,b,c=ConstructionScreen.draw(cached)
assert(cached.brush.isADParkingBrush and cached.wasDrawn and a==4 and b==nil and c==6)
cached.brush:update(16);cached.brush:draw();cached.brush:deactivate()
local unrelated={cursor=cursor,brush={placeable={configFileName='C:/mods/other/shed.xml'}},setBrush=deferred.setBrush}
local originalBrush=unrelated.brush;ConstructionScreen.draw(unrelated);assert(unrelated.brush==originalBrush)
-- Constructor regression: broken results must not remain in the screen.
local newBrush=ADParkingBrush.new;ADParkingBrush.new=function()return {}end
local failed={cursor=cursor,brush={},selectorBrush={activate=function()end},setBrush=deferred.setBrush}
assert(not ADParkingNodes.setParkingBrush(failed,item))
assert(failed.brush==failed.selectorBrush and ADParkingNodes.activationFailed)
ADParkingBrush.new=newBrush
''')
import xml.etree.ElementTree as E
assert E.parse(root/'parkingNodes.xml').findtext('storeData/brush/type') == 'placeable'
print('PASS: Lua 5.1 spacing 1-10 m, endpoints, diagonal geometry, node-count thresholds, empty connections, AD network API, preflight, preview, confirm/cancel, type switch, controls, unrelated brushes and idempotence.')

# Placeables must not hide or intercept the terrain target, including a roof.
lua.execute('''
CollisionFlag={TERRAIN=32}
GuiTopDownCursor={RAYCAST_DISTANCE=1000}
local ray={x=1,y=100,z=2,dx=0,dy=-1,dz=0}
local castCount=0
RaycastUtil={raycastClosest=function(x,y,z,dx,dy,dz,distance,mask)
 assert(x==1 and y==100 and z==2 and dy==-1 and distance==1000 and mask==32)
 castCount=castCount+1
 return 1,20,0,30
end}
local brush=ADParkingBrush.new({}, {ray=ray,getHitTerrainPosition=function()error('placeable cursor must be bypassed')end})
brush.anchor={x=0,z=0};brush:update(16)
assert(castCount==1 and brush.target.x==20 and brush.target.z==30 and #brush.preview>1)
local lines=0
drawDebugLine=function(...)
 assert(select('#',...)==13 and select(13,...)==false, 'preview must render above placeables')
 lines=lines+1
end
brush:draw();assert(lines>0)
RaycastUtil.raycastClosest=function()return 0 end
brush:update(16);assert(brush.target==nil and brush.preview==nil)
''')
print('PASS: terrain-only cursor bypasses placeables; preview lines render on top; no-hit clears target.')

lua.execute('''
-- Connected rows use native creation links without touching existing nodes.
g_server={}
for mode=0,2 do
 local count=100
 local graph={getWayPointsCount=function()return count end,
 createWayPointWithConnections=function(self,x,y,z,out,incoming,flags,connect,reverse,dual,event)
  assert(flags==1 and event and not reverse)
  if mode==0 or count==100 then assert(not connect and #out==0 and #incoming==0)
  else assert(connect and out[1]==count+1 and incoming[1]==count and dual==(mode==2)) end
  count=count+1
 end}
 local points=ADParkingRowPlanner.points(0,0,10,0,5)
 assert(ADParkingRowPlanner.create(graph,points,1,function()return 0 end,mode)==3 and count==103)
end
local brush=ADParkingBrush.new({}, {})
local screen={brush=brush}
assert(brush.connectionMode==0 and brush.supportsFourthButton)
for expected=1,3 do
 ConstructionScreen.onButtonFourth(screen)
 assert(brush.connectionMode==expected%3)
end
g_server=nil
local writes=0
local ok=pcall(ADParkingRowPlanner.create,{createWayPointWithConnections=function()writes=writes+1 end},{{x=0,z=0}},0,function()return 0 end,1)
assert(not ok and writes==0)
''')
print('PASS: unconnected, forward and dual links; existing nodes untouched; mode cycling; remote-client guard.')

lua.execute('''
for degrees=0,180,5 do
 for spacing=1,10 do
  local points,length=ADParkingRowPlanner.points(10,20,40,60,spacing,degrees)
  assert(points[1].x==10 and points[1].z==20)
  assert(points[#points].x==40 and points[#points].z==60)
  assert(#points==math.ceil(length/spacing)+1)
  for i=2,#points do
   local dx,dz=points[i].x-points[i-1].x,points[i].z-points[i-1].z
   assert(math.sqrt(dx*dx+dz*dz)<=spacing+1e-8)
  end
 end
end
local p,l=ADParkingRowPlanner.points(0,0,20,0,5,180)
assert(math.abs(l-10*math.pi)<1e-8)
for _,v in ipairs(p) do assert(math.abs((v.x-10)^2+v.z^2-100)<1e-7 and v.z<=1e-8) end
local q=ADParkingRowPlanner.points(20,0,0,0,5,180)
for _,v in ipairs(q) do assert(v.z>=-1e-8) end
assert(ADParkingRowPlanner.points(0,0,400,0,5,180)==nil)
assert(ADParkingRowPlanner.points(0,0,10,0,5,7)==nil)
local brush=ADParkingBrush.new({},{});local screen={brush=brush}
for i=1,50 do ConstructionScreen.onAxisSecondary(screen,'curve',1) end
assert(brush.curveDegrees==180)
for i=1,50 do ConstructionScreen.onAxisSecondary(screen,'curve',-1) end
assert(brush.curveDegrees==0)
ConstructionScreen.onAxisSecondary(screen,'curve',1);assert(brush.curveDegrees==5)
''')
print('PASS: every 5-degree arc, all spacings, exact endpoints, semicircle radius/length, mirrored bends, path limit and angle controls.')
