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
function Class(c,base) c.__index=c;setmetatable(c,{__index=base});return {__index=c} end
ConstructionBrush={new=function(item,cursor,mt)return setmetatable({storeItem=item,cursor=cursor},mt)end}
Logging={info=function()end,warning=function()end}
addModEventListener=function()end
ConstructionBrushPlaceable={new=function(item,cursor,...)return 'originalFactory',nil,select('#',...)end}
ConstructionScreen={onButtonPrimary=function()return 'original' end,onButtonSecondary=function()end,
 onButtonTertiary=function()end,onAxisPrimary=function()end,
 draw=function(self)self.wasDrawn=true;return 4,nil,6 end,
 loadCurrentConfiguration=function(self,item) self.defaultPreviewLoaded=true;return 'standardPreview',nil,3 end}
getTerrainHeightAtWorldPos=function(_,x,_,z)return x+z end
g_terrainNode=1
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
local item={xmlFilename='C:/mods/FS25_z_ADParkingNodes/parkingNodes.xml'}
local custom=ConstructionBrushPlaceable.new(item,cursor)
assert(custom.isADParkingBrush and custom.storeItem==item)
local a,b,c=ConstructionBrushPlaceable.new({xmlFilename='C:/mods/other/parkingNodes.xml'},cursor,1,nil,3)
assert(a=='originalFactory' and b==nil and c==3)
-- Actual screen lifecycle: reusable brush constructed with no selected item.
assert(ConstructionBrushPlaceable.new(nil,cursor)=='originalFactory')
local deferred={cursor=cursor,brush={},setBrush=function(self,brush)self.brush=brush end}
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
local unrelated={cursor=cursor,brush={placeable={configFileName='C:/mods/other/shed.xml'}},setBrush=deferred.setBrush}
local originalBrush=unrelated.brush;ConstructionScreen.draw(unrelated);assert(unrelated.brush==originalBrush)
''')
import xml.etree.ElementTree as E
assert E.parse(root/'parkingNodes.xml').findtext('storeData/brush/type') == 'placeable'
print('PASS: Lua 5.1 spacing 1-10 m, endpoints, diagonal geometry, node-count thresholds, empty connections, AD network API, preflight, preview, confirm/cancel, type switch, controls, unrelated brushes and idempotence.')
