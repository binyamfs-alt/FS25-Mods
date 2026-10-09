"""Regression checks for production unloading and mixed-type loading guards.
Run with Python and lupa installed (pip install lupa).
"""
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT = Path(__file__).resolve().parents[1]
mod = ROOT / 'FS25_z_LivestockCapacityHUD'
r = LuaRuntime()
for p in mod.rglob('*.lua'):
    r.execute('assert(loadstring(...))', p.read_text(encoding='utf-8'))
r.execute('''
g_currentModName='FS25_z_LivestockCapacityHUD'
moves=0; notices=0; warnings=0; successes=0; cancelled=0; allowed=false
AnimalScreen={
 onYesNoSource=function(self,yes,...) if yes then self.controller:applySource(...); successes=successes+1 else cancelled=cancelled+1 end end,
 onYesNoTarget=function(self,yes,...) if yes then self.controller:applyTarget(...); successes=successes+1 else cancelled=cancelled+1 end end}
Utils={overwrittenFunction=function(base,hook) return function(self,...) return hook(self,base,...) end end}
InfoDialog={show=function() notices=notices+1 end}
g_i18n={getText=function(_,key) return key end}
g_specializationManager={getSpecializationObjectByName=function() return {
 isTypeAllowed=function() return allowed end,warn=function() warnings=warnings+1 end,
 getLoad=function() return 4000,{[3]=true} end} end}
g_currentMission={animalSystem={getTypeByIndex=function(_,i) return {typeIndex=i} end}}
function makeController(production)
 local h={getAnimalTypeIndex=function() return 2 end}
 if production then h.animalsTypeData={[3]={}};h.animalSubTypeToFillType={[7]=22} end
 return {trailer={},husbandry=h,
 applySource=function(self,t,i,n) moves=moves+n; return 'source',t,i,n end,
 applyTarget=function(self,t,i,n) moves=moves+n; return 'target',t,i,n end,
 getSourceAnimalTypes=function() return {{typeIndex=2}} end}
end
''')
r.execute((mod/'scripts/AnimalDialogGuard.lua').read_text(encoding='utf-8'))
r.execute('''
local G=LivestockAnimalDialogGuard
local production=makeController(true); G.installController({controller=production})
local a,t,i,n=production:applySource(3,1,250)
assert(a=='source' and t==3 and i==1 and n==250 and moves==250 and warnings==0)
local screen=setmetatable({controller=production},{__index=AnimalScreen})
screen:onYesNoSource(true,3,1,250)
assert(moves==500 and successes==1 and notices==0)
-- Loading remains guarded even for a production-shaped destination.
screen:onYesNoTarget(true,2,1,1)
assert(moves==500 and successes==1 and notices==1)
production:applyTarget(2,1,1); assert(moves==500 and warnings==1)
screen:onYesNoSource(false,3,1,250); assert(moves==500 and cancelled==1)
-- A partial production marker must not disable the guard.
local partial=makeController(false);partial.husbandry.animalsTypeData={}
assert(not G.isProductionUnload(partial,true))
local farm=makeController(false);G.installController({controller=farm})
local farmScreen=setmetatable({controller=farm},{__index=AnimalScreen})
farmScreen:onYesNoSource(true,2,1,1);farmScreen:onYesNoTarget(true,2,1,1)
assert(moves==500 and successes==1 and notices==3)
farm:applySource(2,1,1);farm:applyTarget(2,1,1)
assert(moves==500 and warnings==3)
allowed=true
farmScreen:onYesNoSource(true,3,1,1);farmScreen:onYesNoTarget(true,3,1,1)
assert(moves==502 and successes==3 and notices==3)
assert(farm:getSourceAnimalTypes(true)[1].typeIndex==3)
assert(farm:getSourceAnimalTypes(false)[1].typeIndex==2)
''')
print('PASS: Lua 5.1 syntax, butcher source unloading, both guard layers, protected loading, farm transfers, cancellation, native arguments/returns and trailer views')
