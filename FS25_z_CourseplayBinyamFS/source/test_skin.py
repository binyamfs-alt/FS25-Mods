"""Companion checks using Lua 5.1 and the original CP 8.1.0.3 source as a fixture."""
import hashlib
import xml.etree.ElementTree as ET
import zipfile
from lupa.lua51 import LuaRuntime
from build import ROOT, source_files, build

files = source_files()
lua = LuaRuntime(unpack_returned_tuples=True)
compile_lua = lua.eval('function(code, name) local f,e=loadstring(code,name); assert(f,e) end')
for path, data in files.items():
    if path.endswith('.lua'):
        compile_lua(data.decode('utf-8-sig'), path)
desc = ET.fromstring(files['modDesc.xml'])
assert desc.findtext('./dependencies/dependency') == 'FS25_Courseplay'
sources = [e.get('filename') for e in desc.findall('./extraSourceFiles/sourceFile')]
assert sources == ['scripts/CpHudSkin.lua', 'scripts/CourseplayBinyamFS.lua']
assert all(path in files for path in sources)
assert not any(path.startswith(('config/', 'translations/', 'scripts/gui/')) for path in files)
assert 'Courseplay.lua' not in files and 'FS25_Courseplay.zip' not in files
fixture = __import__('pathlib').Path(r'C:/Users/benbu/Documents/Codex/2026-10-08/i-w/work/FS25-Courseplay-BinyamFS/FS25_Courseplay.zip')
assert hashlib.sha256(fixture.read_bytes()).hexdigest() == '44ce9c9fc6f193b7180a4ff6f147975fe75e2591ccae773ccfd254b96bcdc022'
baseline = zipfile.ZipFile(fixture)
lua.execute('''
unpack = unpack or table.unpack
function CpObject() return {} end
AIParameterSetting = {}
Overlay = {}
g_i18n = {getText=function(_, key) return key end}
CpTextHudElement = {highlightedColor={42/255,193/255,237/255,1}, disabledColor={64/255,64/255,64/255,0.5}}
selectedSkin = 0
g_Courseplay = {globalSettings={binyamfsHudSkin={getValue=function() return selectedSkin end}}}
function overlay(r,g,b,a)
    return {r=r,g=g,b=b,a=a,setColor=function(self,r,g,b,a) self.r,self.g,self.b,self.a=r,g,b,a end}
end
function element(color)
    return {overlay=overlay(unpack(color)),children={}}
end
function header()
    local e=element({1,1,1,1})
    e.textColor={1,1,1,1}; e.textBold=false; e.highlightedColor=CpTextHudElement.highlightedColor
    e.disabledColor=CpTextHudElement.disabledColor
    e.setTextDetails=function(self,text,_,__,color) self.text=text or self.text; self.textColor=color or self.textColor end
    return e
end
function equals(a,b)
    for i=1,4 do assert(math.abs(a[i]-b[i])<0.00001, 'Color mismatch at channel '..i) end
end
function checkColor(e,color) equals({e.overlay.r,e.overlay.g,e.overlay.b,e.overlay.a},color) end
''')
lua.execute(files['scripts/CpHudSkin.lua'].decode())
lua.execute('''
root=element({0,0,0,0.7}); title=header()
bar=element({0.22323,0.40724,0.00368,1}); status=element({0.2,0.2,0.2,0.9})
root.children={title,bar,status}
CpHudSkin.apply(root,title)
checkColor(root,{0,0,0,0.7}); assert(title.text=='Courseplay' and not title.textBold)
selectedSkin=1; CpHudSkin.apply(root,title)
checkColor(root,{0,0,0,0.67}); checkColor(bar,{0,0,0,0.67})
checkColor(status,{0.76,0.79,0.76,0.9}); assert(title.text=='Courseplay' and title.textBold)
equals(title.textColor,{0.9,0.97,0.9,1}); equals(title.highlightedColor,{0.9,0.97,0.9,1})
-- Repeated frames must retain the canonical CP color, then reflect live state changes.
for i=1,30 do CpHudSkin.apply(root,title) end
status.overlay:setColor(0,0.6,0,0.9); CpHudSkin.apply(root,title)
checkColor(status,{0.9,0.97,0.9,1})
status.overlay:setColor(1,0,0,0.9); CpHudSkin.apply(root,title)
checkColor(status,{1,0.48,0.28,1})
status.overlay:setColor(0.6,0.6,0,0.9); CpHudSkin.apply(root,title)
checkColor(status,{1,0.82,0.22,1})
selectedSkin=0; CpHudSkin.apply(root,title)
checkColor(root,{0,0,0,0.7}); checkColor(bar,{0.22323,0.40724,0.00368,1})
checkColor(status,{0.6,0.6,0,0.9}); assert(title.text=='Courseplay' and not title.textBold)
equals(title.textColor,{1,1,1,1}); equals(title.highlightedColor,CpTextHudElement.highlightedColor)
-- A newly constructed vehicle receives the selected skin, independently of the old one.
selectedSkin=1; other=element({0,0,0,0.7}); CpHudSkin.apply(other,nil)
checkColor(other,{0,0,0,0.67}); checkColor(root,{0,0,0,0.7})
g_Courseplay.globalSettings.binyamfsHudSkin=nil; CpHudSkin.apply(other,nil)
checkColor(other,{0,0,0,0.7})
g_Courseplay.globalSettings.binyamfsHudSkin={getValue=function() return selectedSkin end}
''')
lua.execute('''
assert(CpHudSkin.formatText('nearest waypoint')=='Nearest Waypoint')
assert(CpHudSkin.formatText('auto | AI | 8R 410 | 10 km/h')=='Auto | AI | 8R 410 | 10 km/h')
local styled={text='nearest waypoint',textSize=18,textBold=false}
CpHudSkin.styleText(styled,nil,nil)
assert(styled.textSize==12 and not styled.textBold and styled.text=='Nearest Waypoint')
selectedSkin=0; styled.text='nearest waypoint'; CpHudSkin.styleText(styled,nil,nil)
assert(styled.textSize==18 and not styled.textBold and styled.text=='nearest waypoint')
selectedSkin=1
g_screenWidth,g_screenHeight=1920,1080
getTextWidth=function(size,text) return size * #text * 0.55 * g_screenHeight/g_screenWidth end
local full='John Deere 8R 410 (2026 Edition)'
local short=CpHudSkin.compactVehicleName(full,14/1080,0.10)
assert(short=='JD 8R 410')
local fitted=CpHudSkin.compactVehicleName('Very Long Manufacturer Special Model 1234',14/1080,0.07)
assert(getTextWidth(14/1080,fitted)<=0.07 and fitted:find('1234',1,true))
local renders={}
Overlay.new=function()
    local o=overlay(1,1,1,1)
    o.setPosition=function(self,x,y) self.x,self.y=x,y end
    o.setDimension=function(self,w,h) self.width,self.height=w,h end
    o.render=function(self) table.insert(renders,{x=self.x,y=self.y,w=self.width,h=self.height}) end
    return o
end
local button=element({1,1,1,1})
button.overlay.x,button.overlay.y=0.2,0.3
button.overlay.width,button.overlay.height=0.03,0.02
button.overlay.offsetX,button.overlay.offsetY=-0.03,0
button.visible=true; button.callbacks={onClickPrimary={}}
CpHudSkin.drawButtonBorder(button)
assert(#renders==13)
local rx,ry,rw,rh=CpHudSkin.buttonBounds(button)
for _,r in ipairs(renders) do
 assert(not (r.x<=rx and r.y<=ry)) -- transparent rounded corner
 assert(r.x>=rx and r.y>=ry and r.x+r.w<=rx+rw+0.000001 and r.y+r.h<=ry+rh+0.000001)
end
assert(math.abs(renders[6].h*g_screenHeight-1)<0.00001)
assert(math.abs(renders[8].w*g_screenWidth-1)<0.00001)
local bx,by,bw,bh=CpHudSkin.buttonBounds(button)
assert(math.abs(bx-(0.17-6/1920))<0.00001)
assert(math.abs(bw-(22/1920))<0.00001)
RenderText={ALIGN_LEFT=0,ALIGN_RIGHT=1,ALIGN_CENTER=2}; button.text='Short'; local _,_,w1,h1=CpHudSkin.buttonBounds(button)
button.text='A much longer selection'; local _,_,w2,h2=CpHudSkin.buttonBounds(button)
assert(w1==w2 and h1==h2)
button.text=nil
button.skinSettings=true
local sx,sy,sw,sh=CpHudSkin.buttonBounds(button)
assert(math.abs(sw*g_screenWidth-88)<0.00001)
local originalWidth=button.overlay.width
RenderText={ALIGN_LEFT=0}; setTextBold=function() end; setTextAlignment=function() end; setTextColor=function() end; renderText=function(x,y,size,text) assert(text=='Settings') end
CpHudSkin.drawSettings(button,function(e) assert(math.abs(e.overlay.width*g_screenWidth-12)<0.00001) end)
assert(button.overlay.width==originalWidth and button.skinDrawingBounds==nil)
button.skinSettings=nil
renders={}
CpHudSkin.drawButtonBorder(button)
selectedSkin=0; CpHudSkin.drawButtonBorder(button); assert(#renders==13)
selectedSkin=1; button.callbacks={}; CpHudSkin.drawButtonBorder(button); assert(#renders==13)
''')

# Minimal engine stand-ins, followed by CP's actual unchanged HUD and settings code.
lua.execute('''
g_time=0
RenderText={ALIGN_LEFT=0,ALIGN_RIGHT=1,ALIGN_CENTER=2}
function noop() end
setTextBold=noop; setTextAlignment=noop; setTextWrapWidth=noop
setTextLineBounds=noop; setTextColor=noop; renderText=noop
getTextHeight=function(size,text) return size end
function table.clone(t) local copy={} for k,v in pairs(t) do copy[k]=v end return copy end
CpUtil={debugFormat=noop,debugVehicle=noop,info=noop,error=function(msg) error(msg) end}
CpDebug={DBG_HUD=1}; AIParameterType={SELECTOR=1}
MathUtil={round=function(n) return n end}
Overlay.ALIGN_VERTICAL_BOTTOM=0; Overlay.ALIGN_HORIZONTAL_LEFT=0; Overlay.ALIGN_HORIZONTAL_RIGHT=1
local drawCount,deleted=0,0
Overlay.new=function(filename,x,y,w,h)
    local o={x=x or 0,y=y or 0,width=w or 0,height=h or 0,r=1,g=1,b=1,a=1,offsetX=0,offsetY=0}
    o.setColor=function(self,r,g,b,a) self.r,self.g,self.b,self.a=r,g,b,a end
    o.setPosition=function(self,x,y) self.x,self.y=x,y end
    o.setDimension=function(self,w,h) self.width,self.height=w,h; self.offsetX=self.right and -w or 0 end
    o.setAlignment=function(self,v,h) self.right=(h==1); self.offsetX=self.right and -self.width or 0 end
    o.render=function(self) drawCount=drawCount+1 end
    o.delete=function(self) self.deleted=true; deleted=deleted+1 end
    return o
end
function Class(cls,base)
    cls.__index=cls
    setmetatable(cls,{__index=base})
    cls.superClass=function() return base end
    return {__index=cls}
end
HUDElement={}
function HUDElement.new(o,parent,mt)
    local self=setmetatable({overlay=o,children={},visible=true},mt)
    if parent then table.insert(parent.children,self) end
    return self
end
function HUDElement:draw()
    if not self.visible then return end
    self.overlay:render()
    for _,child in ipairs(self.children) do child:draw() end
end
function HUDElement:delete() for _,child in ipairs(self.children) do child:delete() end self.overlay:delete() end
function HUDElement:setPosition(x,y) self.overlay:setPosition(x,y) end
function HUDElement:getPosition() return self.overlay.x,self.overlay.y end
function HUDElement:setDimension(w,h) self.overlay:setDimension(w,h) end
function HUDElement:getWidth() return self.overlay.width end
function HUDElement:setAlignment(v,h) self.overlay:setAlignment(v,h) end
function HUDElement:scalePixelToScreenHeight(px) return px/g_screenHeight end
function HUDElement:setVisible(v) self.visible=v end
function HUDElement:getVisible() return self.visible end
GuiUtils={checkOverlayOverlap=function(px,py,x,y,w,h) return px>=x and px<=x+w and py>=y and py<=y+h end}
''')
for path in ('scripts/CpObject.lua', 'scripts/ai/parameters/AIParameterSettingInterface.lua',
             'scripts/ai/parameters/AIParameterSetting.lua', 'scripts/ai/parameters/AIParameterSettingList.lua',
             'scripts/CpGlobalSettings.lua', 'scripts/gui/hud/HudElements.lua',
             'scripts/gui/hud/CpBaseHud.lua', 'scripts/gui/hud/CpHudInfoTexts.lua'):
    lua.execute(baseline.read(path).decode('utf-8-sig'))
lua.execute('''
local instance=g_Courseplay
local saves,dirty=0,0
instance.saveUserSettings=function() saves=saves+1 end
instance.infoTextsHud={}; instance.currentVersion='8.1.0.3'
local function initHud(hud)
    hud.baseHud=CpHudElement.new(Overlay.new(nil,0.2,0.3,0.2,0.1))
    hud.baseHud.overlay:setColor(0,0,0,0.7)
    local title=CpTextHudElement.new(hud.baseHud,0.2,0.38,14)
    title:setTextDetails('Courseplay')
end
CpBaseHud.init=initHud; CpHudInfoTexts.init=initHud
-- Exercise CP's original draw methods with a small deterministic content source.
CpBaseHud.updateContent=function(hud)
    hud.testText:setTextDetails('nearest waypoint',18)
    hud.testIcon.overlay:setColor(0,0.6,0,0.9)
end
CpHudInfoTexts.update=function(hud) hud.testIcon.overlay:setColor(0.2,0.2,0.2,0.9) end
CpHudInfoTexts.isVisible=function() return true end
CpGlobalSettings.loadSettingsSetup=function(settings)
    settings.settings={{original=true},{original=true}}
    settings.settingsBySubTitle={{title='CP_global_setting_subTitle_userSettings',elements={}}}
end
CpGlobalSettings.raiseDirtyFlag=function() dirty=dirty+1 end
CpSettingsUtil={getSettingFromParameters=function(data,vehicle,settings)
    return AIParameterSettingList(data,vehicle,settings)
end}
FS25_Courseplay={g_Courseplay=instance,CpGlobalSettings=CpGlobalSettings,CpSettingsUtil=CpSettingsUtil,
    CpBaseHud=CpBaseHud,CpHudInfoTexts=CpHudInfoTexts,CpHudElement=CpHudElement,
    CpHudButtonElement=CpHudButtonElement,CpTextHudElement=CpTextHudElement}
g_modManager={CP_MOD_NAME='FS25_Courseplay'}
Logging={warning=noop}
function verifySaves() assert(saves>0 and dirty==0) end
''')
lua.execute(files['scripts/CourseplayBinyamFS.lua'].decode())
lua.execute('''
assert(CourseplayBinyamFS.installed)
local settings=setmetatable({}, {__index=CpGlobalSettings})
settings:loadSettingsSetup()
g_Courseplay.globalSettings=settings
local selection=settings.binyamfsHudSkin
assert(selection:getValue()==0 and selection:getIsUserSetting() and not selection:getIsExpertModeSetting())
assert(selection.data.uniqueID==2 and #settings.settings==3 and settings.settings[1].original)
assert(#settings.settingsBySubTitle[1].elements==1)
assert(selection:getTitle()=='BFS_HUD_SKIN_TITLE')
CourseplayBinyamFS.addSetting(settings,FS25_Courseplay)
assert(#settings.settings==3)
local wrapped=CpBaseHud.draw
assert(CourseplayBinyamFS.install(FS25_Courseplay) and wrapped==CpBaseHud.draw)
g_server={}; selection:setNextItem(); verifySaves()
local xml={data={},setString=function(self,k,v) self.data[k]=v end,
    getString=function(self,k) return self.data[k] end}
selection:saveToXMLFile(xml,'skin')
selection:setNextItem(); assert(selection:getValue()==0)
selection:loadFromXMLFile(xml,'skin'); assert(selection:getValue()==1)
g_server=nil; selection.isSynchronized=true; selection:setNextItem(); verifySaves()
selection:setNextItem(); assert(selection:getValue()==1)
local hud=setmetatable({}, {__index=CpBaseHud})
hud:init()
assert(hud.skinHeaderText and hud.skinHeaderText.skinHeader)
hud.testText=CpTextHudElement.new(hud.baseHud,0.2,0.34,18)
hud.testText:setCallback('onClickPrimary',{},noop)
hud.testIcon=CpHudButtonElement.new(Overlay.new(nil,0.4,0.34,0.02,0.02),hud.baseHud)
hud.testIcon:setCallback('onClickPrimary',{},noop)
hud.vehicleNameBtn=CpTextHudElement.new(hud.baseHud,0.2,0.36,16)
hud.vehicleNameBtn:setCallback('onClickPrimary',{},noop)
hud.onOffButton=hud.testIcon; hud.width=0.25; hud.wMargin=0.01; hud.lineHeight=0.025; CpBaseHud.x=0.2
hud.vehicle={getName=function() return 'John Deere 8R 410 (Long description)' end}
local altHeld=true
Input={KEY_lalt=1,isKeyPressed=function(key) return altHeld end}
local initialContext='VEHICLE'
g_inputBinding={getContextName=function() return initialContext end,
 setContext=function(self,name) initialContext=name end,
 revertContext=function() initialContext='VEHICLE' end,
 getShowMouseCursor=function() return true end}
CpHudSkin.pointerX,CpHudSkin.pointerY=0.22,0.38
CpHudSkin.tooltipHeld=true
hud:draw({})
assert(hud.testText.text=='Nearest Waypoint' and hud.testText.textSize==12 and not hud.testText.textBold)
assert(hud.skinHeaderText.textSize==11 and hud.skinHeaderText.textBold)
assert(hud.testText.skinBorderOverlay and hud.testIcon.skinBorderOverlay)
assert(hud.vehicleNameBtn.skinFullVehicleName==hud.vehicle:getName())
assert(hud.vehicleNameBtn.text=='JD 8R 410')
assert(hud.baseHud.overlay.a==0.67)
local ix,iy,iw,ih=CpHudSkin.buttonBounds(hud.testIcon)
local boundX,boundY=ix+iw/2,iy+ih/2
assert(hud.testIcon:isMouseOverArea(boundX,boundY))
local hover=CpTextHudElement.highlightedColor
hud.testText.hovered=true; hud.testText:draw()
assert(hover==CpTextHudElement.highlightedColor)
local missionDrawn=false
FSBaseMission={draw=function() missionDrawn=true end}
CourseplayBinyamFS:loadMap()
hud.vehicleNameBtn.hovered=true; hud:draw({})
assert(CourseplayBinyamFS.tooltipDrawPending==hud)
local drawTip=CpHudSkin.drawHudTooltip
CpHudSkin.drawHudTooltip=function(h) assert(missionDrawn); return drawTip(h) end
FSBaseMission.draw({})
CpHudSkin.drawHudTooltip=drawTip
assert(CourseplayBinyamFS.tooltipDrawPending==nil)
assert(hud.vehicleNameBtn.skinTooltipOverlay)
local info=setmetatable({}, {__index=CpHudInfoTexts})
info:init(); info.testIcon=CpHudButtonElement.new(Overlay.new(nil,0.2,0.3,0.02,0.02),info.baseHud)
info:draw(); assert(info.baseHud.overlay.a==0.67 and info.skinHeaderText.textSize==11)
selection:setNextItem(); hud:draw({}); info:draw()
assert(hud.testText.text=='nearest waypoint' and hud.testText.textSize==18)
assert(hud.baseHud.overlay.a==0.7 and info.baseHud.overlay.a==0.7)
assert(hud.vehicleNameBtn.text==hud.vehicle:getName())
assert(not hud.testIcon:isMouseOverArea(boundX,boundY))
-- Identity row reads the loaded save data without duplicating it in the model name.
selection:setNextItem()
hud.vehicle.spec_hotKeyVehicle={nickname='Big Cat (North)'}
hud.vehicle.getName=function() return 'John Deere 8R 410 [Big Cat (North)]' end
local leaf={getName=function() return 'Seeder 6000' end}
local dolly={getName=function() return 'Dolly' end,getAttachedImplements=function() return {{object=leaf}} end}
hud.vehicle.getAttachedImplements=function() return {{object=dolly}} end
assert(CpHudSkin.getCustomVehicleName(hud.vehicle)=='Big Cat (North)')
assert(#CpHudSkin.getImplementNames(hud.vehicle)==2)
leaf.getAttachedImplements=function() return {{object=hud.vehicle}} end
assert(#CpHudSkin.getImplementNames(hud.vehicle)==2) -- cycle guard
-- Right-aligned numeric boxes use fixed geometry, not the text overlay offset.
local numeric=CpHudElement.new(nil,hud.baseHud)
numeric.labelElement=CpTextHudElement.new(hud.baseHud,0.21,0.325,12)
numeric.labelElement:setCallback('onClickPrimary',{},noop)
numeric.textElement=CpTextHudElement.new(hud.baseHud,0.42,0.325,12,RenderText.ALIGN_RIGHT)
numeric.textElement:setCallback('onClickPrimary',{},noop)
numeric.textElement:setTextDetails('10.0 m')
numeric.textElement.overlay.offsetX=-numeric.textElement.overlay.width
numeric.incrementalElement=CpHudButtonElement.new(Overlay.new(nil,0.44,0.325,0.01,0.01),hud.baseHud)
numeric.decrementalElement=CpHudButtonElement.new(Overlay.new(nil,0.40,0.325,0.01,0.01),hud.baseHud)
numeric.incrementalElement:setCallback('onClickPrimary',{},noop)
numeric.decrementalElement:setCallback('onClickPrimary',{},noop)
CpHudSkin.prepareLayout(hud)
local mx,my,mw,mh=CpHudSkin.buttonBounds(numeric.decrementalElement)
local vx,vy,vw,vh=CpHudSkin.buttonBounds(numeric.textElement)
local ax,ay,aw,ah=CpHudSkin.buttonBounds(numeric.incrementalElement)
assert(mx+mw<vx and vx+vw<ax and my==ay and math.abs(my+mh/2-vy-vh/2)<0.000001 and mh==ah)
numeric.textElement:setTextDetails('0.0 m')
CpHudSkin.prepareLayout(hud)
local nx,ny,nw,nh=CpHudSkin.buttonBounds(numeric.textElement)
assert(nx==vx and nw==vw)
local oldX=numeric.textElement.overlay.x
CpHudSkin.drawControlText(numeric.textElement,function(e)
    assert(math.abs(e.overlay.x-(vx+vw/2))<0.000001)
end)
assert(numeric.textElement.overlay.x==oldX and numeric.textElement.skinDrawingBounds==nil)
hud.onOffButton.overlay.y=hud.vehicleNameBtn.overlay.y-0.005
-- A shared grid governs columns, top toolbar, settings and numeric subcells.
hud.selectedJobBtn=CpTextHudElement.new(hud.baseHud,0.212,0.35,12)
hud.selectedJobBtn:setCallback('onClickPrimary',{},noop)
hud.goalBtn=CpHudButtonElement.new(Overlay.new(nil,0.43,0.345,0.03,0.03),hud.baseHud)
hud.goalBtn:setCallback('onClickPrimary',{},noop)
hud.cpIcon=CpHudButtonElement.new(Overlay.new(nil,0.21,0.36,0.03,0.03),hud.baseHud)
hud.cpIcon:setCallback('onClickPrimary',{},noop)
local page=CpHudElement.new(nil,hud.baseHud); hud.fieldworkLayout=page
page.timeRemainingText=CpTextHudElement.new(page,0.43,0.38,12,RenderText.ALIGN_RIGHT)
page.timeRemainingText:setTextDetails('8m:23s')
page.startingPointBtn=CpTextHudElement.new(page,0.2,hud.baseHud.overlay.y+(hud.hMargin or hud.lineHeight or 0.02)+4*(hud.lineHeight or 23/g_screenHeight),12)
page.startingPointBtn:setCallback('onClickPrimary',{},noop)
page.reverseCourseBtn=CpHudButtonElement.new(Overlay.new(nil,0.38,0.356,0.018,0.018),page)
page.courseVisibilityBtn=CpHudButtonElement.new(Overlay.new(nil,0.41,0.357,0.02,0.02),page)
page.reverseCourseBtn:setCallback('onClickPrimary',{},noop)
page.courseVisibilityBtn:setCallback('onClickPrimary',{},noop)
CpHudSkin.prepareLayout(hud)
local remaining=hud.fieldworkLayout.timeRemainingText
assert(remaining.skinGridText)
assert(remaining.skinLayoutBounds[2]==hud.fieldworkLayout.startingPointBtn.skinLayoutBounds[2])
assert(remaining.skinLayoutBounds[1]==hud.skinGrid.rightX)
assert(remaining.skinLayoutBounds[3]==hud.skinGrid.column)
local gx,gy,gw,gh=CpHudSkin.buttonBounds(hud.goalBtn)
local jx,jy,jw,jh=CpHudSkin.buttonBounds(hud.selectedJobBtn)
local lx,ly,lw,lh=CpHudSkin.buttonBounds(numeric.labelElement)
assert(gw<jw and jw==lw and gh==jh and jh==lh and gy==jy)
local c0x,c0y,c0w,c0h=CpHudSkin.buttonBounds(hud.cpIcon)
local c1x,c1y,c1w,c1h=CpHudSkin.buttonBounds(page.reverseCourseBtn)
local c4x,c4y,c4w,c4h=CpHudSkin.buttonBounds(page.courseVisibilityBtn)
local c5x,c5y,c5w,c5h=CpHudSkin.buttonBounds(hud.onOffButton)
assert(c0w==c1w and c1w==c4w and c4w==c5w)
assert(c0y==c1y and c1y==c4y and c4y==c5y)
assert(c0h==c1h and c1h==c4h and c4h==c5h)
assert(math.abs((c1x-c0x)-(c5x-c4x))<0.000001)
local _,_,n1w,n1h=CpHudSkin.buttonBounds(numeric.decrementalElement)
local _,_,n2w,n2h=CpHudSkin.buttonBounds(numeric.textElement)
local _,_,n3w,n3h=CpHudSkin.buttonBounds(numeric.incrementalElement)
assert(n1w==n3w and n2w>n1w and n1h==n3h and n2h==n1h)
-- Compact square +/- buttons leave the width for the centered value field.
assert(math.abs(n1w*g_screenWidth-n1h*g_screenHeight)<0.000001)
local grid=hud.skinGrid
assert(math.abs((grid.left-hud.baseHud.overlay.x)*g_screenWidth-grid.inset*g_screenHeight)<0.000001)
assert(math.abs((grid.right-grid.left)-(2*grid.column+grid.columnGap))<0.000001)
assert(math.abs(grid.gap*g_screenWidth-4)<0.000001)
local savedNativeRender=hud.baseHud.skinOriginalRender
local panelY,panelH
hud.baseHud.skinOriginalRender=function(o) panelY,panelH=o.y,o.height end
local nativeY,nativeH=hud.baseHud.overlay.y,hud.baseHud.overlay.height
hud.baseHud.overlay:render()
assert(panelY==grid.panelBottom and hud.baseHud.overlay.y==nativeY and hud.baseHud.overlay.height==nativeH)
hud.baseHud.skinOriginalRender=savedNativeRender
-- Hidden toolbar actions leave no interior hole.
page.reverseCourseBtn.visible=false
CpHudSkin.prepareLayout(hud)
local tx,ty,tw,th=CpHudSkin.buttonBounds(hud.cpIcon)
local ux,uy,uw,uh=CpHudSkin.buttonBounds(page.courseVisibilityBtn)
assert(math.abs(ux-tx-tw-hud.skinGrid.gap)<0.000001 and ty==uy)
page.reverseCourseBtn.visible=true
-- Header buttons are vertically centered in the header strip.
hud.exitBtn=CpHudButtonElement.new(Overlay.new(nil,0.44,0.38,0.02,0.02),hud.baseHud)
hud.helpMenuBtn=CpHudButtonElement.new(Overlay.new(nil,0.42,0.38,0.02,0.02),hud.baseHud)
hud.exitBtn:setCallback('onClickPrimary',{},noop); hud.helpMenuBtn:setCallback('onClickPrimary',{},noop)
CpHudSkin.prepareLayout(hud)
local _,hy,_,hh=CpHudSkin.buttonBounds(hud.exitBtn)
assert(math.abs(hy+hh/2-hud.skinGrid.headerBottom-hud.skinGrid.headerHeight/2)<0.000001)
local function clearHover(e) e.hovered=false; for _,child in ipairs(e.children or {}) do clearHover(child) end end
altHeld=true; CourseplayBinyamFS:mouseEvent(0.25,0.38)
clearHover(hud.baseHud); hud.goalBtn.hovered=true
local tipText; local originalRender=renderText
renderText=function(x,y,size,text) tipText=text end
CpHudSkin.drawHudTooltip(hud); assert(tipText=='Open Course Generator')
clearHover(hud.baseHud); numeric.decrementalElement.hovered=true
CpHudSkin.drawHudTooltip(hud); assert(tipText:find('Decrease',1,true)==1,tipText)
clearHover(hud.baseHud); hud.vehicleNameBtn.hovered=true
CpHudSkin.drawHudTooltip(hud); assert(tipText:find('Open Vehicle Settings',1,true))
renderText=originalRender

-- Snug settings width, wider title, compact clipboard and modifier-only tooltips.
local sx,sy,sw,sh=CpHudSkin.buttonBounds(hud.goalBtn)
assert(math.abs(sx+sw-hud.skinGrid.right)<0.000001)
assert(hud.goalBtn.skinSettingsFont==hud.vehicleNameBtn:scalePixelToScreenHeight(12))
local _,_,titleWidth=CpHudSkin.buttonBounds(hud.vehicleNameBtn)
assert(titleWidth>hud.skinGrid.column)
page.copyButton=CpHudButtonElement.new(Overlay.new(nil,0.44,0.31,0.02,0.02),page)
page.copyButton:setCallback('onClickPrimary',{},noop)
CpHudSkin.prepareLayout(hud)
local cx,cy,cw,ch=CpHudSkin.buttonBounds(page.copyButton)
assert(math.abs(cx+cw-hud.skinGrid.right)<0.000001)
assert(math.abs(cw*g_screenWidth-ch*g_screenHeight)<0.000001)
local context='VEHICLE'
local previous
local tooltipDispatches,normalDispatches=0,0
local cursor=true
local binding={
 getContextName=function() return context end,
 getShowMouseCursor=function() return cursor end,
 setContext=function(self,name,create,deletePrevious) assert(create and not deletePrevious); previous=context; context=name end,
 revertContext=function(self,deleteCurrent) assert(deleteCurrent); context=previous end,
 setPreviousContext=function(self,name,parent) assert(name==context); previous=parent end,
 update=function() if context=='BINYAMFS_CP_TOOLTIP' then tooltipDispatches=tooltipDispatches+1 else normalDispatches=normalDispatches+1 end end
}
g_inputBinding=binding
local nativeUpdate=binding.update
CourseplayBinyamFS.tooltipHud=hud
CourseplayBinyamFS:installInputCapture()
clearHover(hud.baseHud); hud.goalBtn.hovered=true
local tipLines={}
renderText=function(x,y,size,text) table.insert(tipLines,{x=x,y=y,size=size,text=text}) end
altHeld=false; CourseplayBinyamFS:mouseEvent(0.25,0.38)
binding:update(); assert(context=='VEHICLE' and not CpHudSkin.tooltipHeld)
CpHudSkin.drawHudTooltip(hud); assert(#tipLines==0)
altHeld=true; binding:update()
assert(CpHudSkin.tooltipHeld and context=='BINYAMFS_CP_TOOLTIP' and tooltipDispatches==1)
assert(normalDispatches==1) -- ordinary action dispatch is not entered while captured
local originalHeight=getTextHeight
getTextHeight=function() return 100 end -- unrelated engine text bounds must not stretch the tooltip
CpHudSkin.drawHudTooltip(hud)
getTextHeight=originalHeight
local panel=hud.vehicleNameBtn.skinTooltipOverlay
assert(panel.height<0.1 and panel.y>=0 and panel.y+panel.height<=1)
assert(panel.a==1 and panel.x>CpHudSkin.pointerX)
for _,line in ipairs(tipLines) do
 assert(line.x>panel.x and line.x<panel.x+panel.width)
 assert(line.y>panel.y and line.y+line.size<panel.y+panel.height)
end
CourseplayBinyamFS:mouseEvent(0.99,0.99)
assert(context=='VEHICLE' and not CpHudSkin.tooltipHeld)
CourseplayBinyamFS:mouseEvent(0.25,0.38)
assert(context=='BINYAMFS_CP_TOOLTIP')
altHeld=false; binding:update(); assert(context=='VEHICLE' and not CpHudSkin.tooltipHeld)
tipLines={}; CpHudSkin.drawHudTooltip(hud); assert(#tipLines==0)
altHeld=true; binding:update(); assert(context=='BINYAMFS_CP_TOOLTIP')
-- An opening dialog retains control and returns to the original vehicle context.
context='MENU'; g_gui={getIsGuiVisible=function() return true end}
binding:update(); assert(context=='MENU' and previous=='VEHICLE' and not CpHudSkin.tooltipHeld)
g_gui=nil; context='VEHICLE'; cursor=false; binding:update()
assert(not CpHudSkin.tooltipHeld and context=='VEHICLE')
cursor=true; binding:update(); assert(context=='BINYAMFS_CP_TOOLTIP')
hud.baseHud.visible=false; binding:update(); assert(context=='VEHICLE' and not CpHudSkin.tooltipHeld)
hud.baseHud.visible=true; binding:update(); assert(context=='BINYAMFS_CP_TOOLTIP')
CourseplayBinyamFS:deleteMap()
assert(context=='VEHICLE' and binding.update==nativeUpdate and not CpHudSkin.tooltipHeld)
CourseplayBinyamFS.tooltipHud=hud
CourseplayBinyamFS:installInputCapture()
CourseplayBinyamFS:mouseEvent(0.25,0.38)
CpHudSkin.tooltipHeld=true
local hints={}
renderText=function(x,y,size,text) hints[#hints+1]={text=text,y=y,size=size} end
CpHudSkin.drawTooltipHint(hud); assert(hints[1].text=='Hold Left Alt for tooltip' and hints[2].text=='BinyamFS Edition')
assert(hints[1].y==hints[2].y and hints[1].size==hints[2].size)
renderText=originalRender

local oldHeight=hud.baseHud.overlay.height
hud:draw({})
local rowY=hud.vehicleNameBtn.overlay.y
local rowHeight=hud.baseHud.overlay.height
assert(rowHeight>oldHeight and hud.vehicleNameBtn.text=='JD 8R 410')
local _,topBottom=CpHudSkin.buttonBounds(hud.onOffButton)
local secondRowTop=hud.vehicleNameBtn.overlay.y-26/g_screenHeight+10/g_screenHeight
assert(secondRowTop<topBottom)
for i=1,10 do hud:draw({}) end
assert(hud.vehicleNameBtn.overlay.y==rowY and hud.baseHud.overlay.height==rowHeight)
local rendered={}; local savedRender=renderText
renderText=function(x,y,size,text) table.insert(rendered,{x=x,y=y,size=size,text=text}) end
CpHudSkin.drawIdentityRow(hud)
assert(#rendered==2 and rendered[1].text=='Big Cat (North)')
assert(rendered[1].x<rendered[2].x and rendered[1].y==rendered[2].y)
assert(rendered[1].size<hud.vehicleNameBtn.screenTextSize)
hud.vehicle.spec_hotKeyVehicle.nickname='Blitz'
hud.vehicle.getAttachedImplements=function() return {} end
rendered={}; CpHudSkin.drawIdentityRow(hud)
assert(rendered[1].text=='Blitz' and rendered[2].text=='')
hud.vehicle.spec_hotKeyVehicle.nickname=''
assert(CpHudSkin.getCustomVehicleName(hud.vehicle)=='')
assert(CpHudSkin.getCustomVehicleName({getName=function() return 'Tractor [Fallback]' end})=='Fallback')
assert(CpHudSkin.fitIdentityText('Big Cat (North)',10/1080,0.5)=='Big Cat (North)')
local fit=CpHudSkin.fitIdentityText('Very long nickname including UTF-8: Éléphant',10/1080,0.035)
assert(getTextWidth(10/1080,fit)<=0.035)
selection:setNextItem(); hud:draw({})
assert(math.abs(hud.baseHud.overlay.height-oldHeight)<0.000001)
rendered={}; CpHudSkin.drawIdentityRow(hud); assert(#rendered==0)
renderText=savedRender
local border=hud.testText.skinBorderOverlay
local tooltip=hud.vehicleNameBtn.skinTooltipOverlay
hud.baseHud:delete(); assert(border.deleted and tooltip.deleted)
''')
lua.execute("""
g_Courseplay.globalSettings.binyamfsHudSkin.current=1
local selected=CpHudSkin.isSelected
CpHudSkin.isSelected=function() return true end
local root=CpHudElement.new(Overlay.new(nil,0.1,0.8,0.2,0.2))
local header=CpHudElement.new(Overlay.new(nil,0.1,0.8,0.2,0.02),root)
local title=CpTextHudElement.new(root,0.1,0.78,14)
title:setTextDetails('Courseplay')
local text=CpTextHudElement.new(root,0.13,0.75,18)
text:setTextDetails('Blocked by an object. Very long vehicle status message')
text:setCallback('onClickPrimary',{},noop)
local icon=CpHudButtonElement.new(Overlay.new(nil,0.1,0.75,0.02,0.02),root)
icon:setCallback('onClickPrimary',{},noop)
local info={baseHud=root,width=0.2,uiScale=1,activeTexts=1,infoTextsElements={{text=text,vehicleBtn=icon}}}
CpHudSkin.prepareInfoLayout(info); CpHudSkin.apply(root,title)
assert(root.overlay.r==0 and root.overlay.a==0.67)
assert(header.overlay.r==0 and header.overlay.a==0.88)
assert(text.skinLayoutBounds[2]==icon.skinLayoutBounds[2])
local vehicle={}
CourseplayBinyamFS.cp.CpUtil={}
CourseplayBinyamFS.cp.CpUtil.getCurrentVehicle=function() return vehicle end
info.infoTextsElements[1].lastInfo={vehicle=vehicle}
CpHudSkin.prepareInfoLayout(info)
assert(text.textColor[2]==0.85 and text.textColor[1]==0.35)
info.infoTextsElements[1].lastInfo.vehicle={}
CpHudSkin.prepareInfoLayout(info)
assert(text.textColor[1]==1 and text.textColor[2]==1 and text.textColor[3]==1)
local fixedWidth=root.skinPanelBounds[3]
assert(math.abs(fixedWidth-350/g_screenWidth)<0.000001)
assert(icon.skinInfoCardBounds[3]==fixedWidth-8/g_screenWidth)
local oneHeight=root.skinPanelBounds[4]
info.activeTexts=3; text.text='Short'; CpHudSkin.prepareInfoLayout(info)
assert(root.skinPanelBounds[3]==fixedWidth)
assert(math.abs(root.skinPanelBounds[4]-oneHeight-50/g_screenHeight)<0.000001)
assert(root.skinPanelBounds[2]==0.8)
local originalX=root.overlay.x
root.overlay.x=0.8; CpHudSkin.prepareInfoLayout(info)
assert(root.skinPanelBounds[1]+root.skinPanelBounds[3]<=1)
CpHudSkin.isSelected=function() return false end
CpHudSkin.prepareInfoLayout(info); CpHudSkin.apply(root,title)
assert(text.skinLayoutBounds==nil and title.skinDisplayPosition==nil)
CpHudSkin.isSelected=selected
""")
absent = LuaRuntime(unpack_returned_tuples=True)
absent.execute('g_i18n={}; Logging={warning=function() end}; CpHudSkin={}')
absent.execute(files['scripts/CourseplayBinyamFS.lua'].decode())
assert not absent.globals().CourseplayBinyamFS.installed
print('PASS: separate package, original CP constructors/settings/save callbacks, live switching, font restoration, status colors, compact names/full tooltip, 1px borders/hit areas, cleanup, repeated-install guard, missing-CP fallback.')



