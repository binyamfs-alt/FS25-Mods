-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 BinyamFS. Updated 2026-10-08; unofficial CP companion.
--- Optional local HUD appearance. The palette follows Storage Alert Monitor's HUD.
CpHudSkin = {}

CpHudSkin.BINYAMFS = 1
CpHudSkin.headerColor = {0.9, 0.97, 0.9, 1}
CpHudSkin.hoverColor = {0.9, 0.97, 0.9, 1}
CpHudSkin.disabledColor = {0.76, 0.79, 0.76, 0.5}
CpHudSkin.palette = {
    {{0, 0, 0, 0.7}, {0, 0, 0, 0.67}},
    {{0, 0, 0, 0.8}, {0, 0, 0, 0.75}},
    {{0.22323, 0.40724, 0.00368, 1}, {0, 0, 0, 0.67}},
    {{0.2, 0.2, 0.2, 0.9}, {0.76, 0.79, 0.76, 0.9}},
    {{0, 0.6, 0, 0.9}, {0.9, 0.97, 0.9, 1}},
    {{0.6, 0.6, 0, 0.9}, {1, 0.82, 0.22, 1}},
    {{1, 0, 0, 0.9}, {1, 0.48, 0.28, 1}},
    {{0, 0.4, 0.6, 1}, {0.9, 0.97, 0.9, 1}},
    {{0, 1, 1, 1}, {0.9, 0.97, 0.9, 1}}
}

function CpHudSkin.isSelected()
    local settings = g_Courseplay and g_Courseplay.globalSettings
    return settings ~= nil and settings.binyamfsHudSkin ~= nil
        and settings.binyamfsHudSkin:getValue() == CpHudSkin.BINYAMFS
end

local function sameColor(a, b)
    if a == nil or b == nil then
        return false
    end
    for i = 1, 4 do
        if math.abs(a[i] - b[i]) > 0.00001 then
            return false
        end
    end
    return true
end

local function skinColor(color)
    for _, entry in ipairs(CpHudSkin.palette) do
        if sameColor(color, entry[1]) then
            return entry[2]
        end
    end
    return color
end

-- Track the last applied color separately from CP's live status colors. A worker
-- starting/stopping or a recorder changing state must still update its icon.
local function applyElement(element, selected)
    local overlay = element.overlay
    if overlay ~= nil then
        local current = {overlay.r, overlay.g, overlay.b, overlay.a}
        if not sameColor(current, element.skinAppliedColor) then
            element.skinOriginalColor = current
        end
        local color = selected and (element.skinHeaderPanel and {0, 0, 0, 0.88} or element.skinInfoPanel and {0, 0, 0, 0.67} or skinColor(element.skinOriginalColor)) or element.skinOriginalColor
        if selected and (element.skinCourseVisibility or element.skinPlayControl) then
            local original=element.skinOriginalColor
            if sameColor(original,{0.2,0.2,0.2,0.9}) then color={1,1,1,1}
            elseif sameColor(original,{0.6,0.6,0,0.9}) then color={1,0.82,0.22,1}
            elseif sameColor(original,{0,0.4,0.6,1}) then color={0.15,0.65,1,1}
            elseif sameColor(original,{0,0.6,0,0.9}) then color={0.35,0.85,0.25,1} end
        end
        overlay:setColor(unpack(color))
        element.skinAppliedColor = {unpack(color)}
    end
    if element.textColor ~= nil then
        if element.skinOriginalHoverColor == nil then
            element.skinOriginalHoverColor = element.highlightedColor
            element.skinOriginalDisabledColor = element.disabledColor
        end
        element.highlightedColor = selected and CpHudSkin.hoverColor or element.skinOriginalHoverColor
        element.disabledColor = selected and CpHudSkin.disabledColor or element.skinOriginalDisabledColor
        if element.skinTextSelected ~= selected then
            element:setTextDetails(element.skinSourceText or element.text)
            element.skinTextSelected = selected
        end
    end
    for _, child in ipairs(element.children or {}) do
        applyElement(child, selected)
    end
end

local units = {m=true, s=true, h=true, min=true, ha=true, ft=true, mph=true, km=true}

function CpHudSkin.formatText(text)
    -- Preserve acronyms, model identifiers, values and unit symbols.
    return (text:gsub('%S+', function(token)
        if token:find('[\128-\255]') then return token end
        return (token:gsub("(%a)([%w']*)", function(first, rest)
            local word = first .. rest
            if units[word] or word:find("%u") or word:find("%d") then return word end
            return first:upper() .. rest
        end))
    end))
end

function CpHudSkin.styleText(element, textSize, textBold)
    element.skinSourceSize = textSize or element.skinSourceSize or element.textSize
    if textBold ~= nil then
        element.skinSourceBold = textBold
    elseif element.skinSourceBold == nil then
        element.skinSourceBold = element.textBold
    end
    if CpHudSkin.isSelected() then
        element.textSize = element.skinHeader and 11 or 12
        element.textBold = element.skinHeader == true
        if not element.skinPreserveCase then
            element.text = CpHudSkin.formatText(element.text)
        end
    else
        element.textSize = element.skinSourceSize
        element.textBold = element.skinSourceBold
    end
end

function CpHudSkin.isButton(element)
    local callbacks = element.callbacks or {}
    return callbacks.onClickPrimary ~= nil or callbacks.onClickMouseWheel ~= nil
end

function CpHudSkin.buttonBounds(element)
    local o = element.overlay
    local x, y = o.x + o.offsetX, o.y + o.offsetY
    if element.skinDrawingBounds then return unpack(element.skinDrawingBounds) end
    if element.skinLayoutBounds then return unpack(element.skinLayoutBounds) end
    if element.skinSettings then
        return x + o.width - 86/g_screenWidth, y + 2/g_screenHeight, 88/g_screenWidth, 20/g_screenHeight
    end
    local scale = element.scaleY or 1
    local height = 20 * scale / g_screenHeight
    local width = element.skinControlWidth or (element.text ~= nil and 150 * scale / g_screenWidth or 22 * scale / g_screenWidth)
    if element.text ~= nil and element.textAlignment == RenderText.ALIGN_RIGHT then
        x = o.x - width + 6 * scale / g_screenWidth
    else
        x = x - 6 * scale / g_screenWidth
    end
    return x, y - 4 * scale / g_screenHeight, width, height
end

function CpHudSkin.drawButtonBorder(element)
    if not CpHudSkin.isSelected() or not element.visible or not CpHudSkin.isButton(element) then
        return
    end
    if element.skinBorderOverlay == nil then
        element.skinBorderOverlay = Overlay.new('dataS/menu/base/graph_pixel.dds', 0, 0, 1, 1)
    end
    local border = element.skinBorderOverlay
    local color = element.hovered and CpHudSkin.hoverColor or {0.16, 0.20, 0.16, 0.7}
    local x, y, width, height = CpHudSkin.buttonBounds(element)
    if element.skinInfoCardBounds then x,y,width,height=unpack(element.skinInfoCardBounds) end
    local px, py = 1 / g_screenWidth, 1 / g_screenHeight
    local disabled = element.disabled or element.isDisabled
    local function rect(rx, ry, rw, rh, r, g, b, alpha)
        border:setColor(r,g,b, disabled and alpha * 0.45 or alpha)
        border:setPosition(rx,ry); border:setDimension(rw,rh); border:render()
    end
    local fr,fg,fb=element.hovered and 0.026 or 0.008,element.hovered and 0.034 or 0.011,element.hovered and 0.026 or 0.008
    -- Two physical pixels of corner radius; fills and borders share the mask.
    rect(x,y+2*py,width,height-4*py,fr,fg,fb,0.94)
    rect(x+2*px,y,width-4*px,py,fr,fg,fb,0.94)
    rect(x+px,y+py,width-2*px,py,fr,fg,fb,0.94)
    rect(x+px,y+height-2*py,width-2*px,py,fr,fg,fb,0.94)
    rect(x+2*px,y+height-py,width-4*px,py,fr,fg,fb,0.94)
    rect(x+2*px,y,width-4*px,py,0.025,0.03,0.025,1)
    rect(x+2*px,y+height-py,width-4*px,py,color[1],color[2],color[3],0.65)
    rect(x,y+2*py,px,height-4*py,color[1],color[2],color[3],0.45)
    rect(x+width-px,y+2*py,px,height-4*py,0.025,0.03,0.025,1)
    rect(x+px,y+py,px,py,color[1],color[2],color[3],0.45)
    rect(x+px,y+height-2*py,px,py,color[1],color[2],color[3],0.65)
    rect(x+width-2*px,y+py,px,py,0.025,0.03,0.025,1)
    rect(x+width-2*px,y+height-2*py,px,py,color[1],color[2],color[3],0.65)
    if element.skinInfoCardBounds then
        rect(x,y+height,width,py,0,0,0,1)
    end
end

local shortBrands = {
    {'john deere', 'JD'}, {'new holland', 'NH'}, {'massey ferguson', 'MF'},
    {'deutz-fahr', 'DF'}, {'case ih', 'Case'}
}

function CpHudSkin.compactVehicleName(name, fontSize, maxWidth)
    local short = name:gsub('%s*%b()', ''):gsub('%s*%b[]', ''):gsub('%s+', ' ')
    for _, brand in ipairs(shortBrands) do
        if short:sub(1, #brand[1]):lower() == brand[1]
                and short:sub(#brand[1] + 1, #brand[1] + 1) == ' ' then
            short = brand[2] .. short:sub(#brand[1] + 1)
            break
        end
    end
    if short == '' then short = name end
    if getTextWidth(fontSize, short) <= maxWidth then return short end
    -- Keep the model suffix visible. Remove complete UTF-8 characters from the
    -- middle rather than letting the renderer chop the name at a button edge.
    local left, right = short, ''
    local suffix = short:match('(%S+%s+%S+)$') or short:match('(%S+)$') or ''
    if #suffix < #short then
        left, right = short:sub(1, #short - #suffix), suffix
    end
    while #left > 0 and getTextWidth(fontSize, left .. '... ' .. right) > maxWidth do
        left = left:gsub('[%z\1-\127\194-\244][\128-\191]*$', '')
    end
    local fitted = left:gsub('%s+$', '') .. '... ' .. right
    while #right > 0 and getTextWidth(fontSize, fitted) > maxWidth do
        right = right:gsub('^[%z\1-\127\194-\244][\128-\191]*', '')
        fitted = '...' .. right
    end
    return fitted
end

function CpHudSkin.updateVehicleName(hud, vehicle)
    local element, full = hud.vehicleNameBtn, vehicle:getName()
    if not CpHudSkin.isSelected() then
        element.skinFullVehicleName = nil
        element:setTextDetails(full, nil, nil, nil, nil, hud.width * 4/7)
        return
    end
    element.skinPreserveCase = true
    local x = element.overlay.x + element.overlay.offsetX
    -- Reserve the complete top-row control cluster, including hidden controls
    -- that can become visible when recording or switching job pages.
    local edge = CpBaseHud.x + hud.width - hud.wMargin
    local rowY = hud.onOffButton.overlay.y
    local function findControls(parent)
        for _, child in ipairs(parent.children or {}) do
            if child ~= element and child.overlay ~= nil and CpHudSkin.isButton(child)
                    and math.abs(child.overlay.y - rowY) < hud.lineHeight / 2 then
                local buttonX = child.overlay.x + child.overlay.offsetX
                if buttonX > x then edge = math.min(edge, buttonX) end
            end
            findControls(child)
        end
    end
    findControls(hud.baseHud)
    local maxWidth = math.max(12 / g_screenWidth, (element.skinControlWidth or hud.width * 0.48) - 12 / g_screenWidth)
    local fontSize = element:scalePixelToScreenHeight(12)
    local cacheKey = full .. ':' .. tostring(fontSize) .. ':' .. tostring(maxWidth)
    if element.skinVehicleCacheKey ~= cacheKey then
        element.skinVehicleShortName = CpHudSkin.compactVehicleName(full, fontSize, maxWidth)
        element.skinVehicleCacheKey = cacheKey
    end
    element.skinFullVehicleName = full
    element:setTextDetails(element.skinVehicleShortName, nil, nil, nil, nil, maxWidth)
end

function CpHudSkin.drawVehicleTooltip(element)
    if element == nil or not CpHudSkin.isSelected() or not element.hovered or not element.skinFullVehicleName then return end
    local fontSize = element:scalePixelToScreenHeight(12)
    local paddingX, paddingY = 6 / g_screenWidth, 6 / g_screenHeight
    local width = math.min(0.45, getTextWidth(fontSize, element.skinFullVehicleName) + 2 * paddingX)
    setTextBold(false); setTextAlignment(RenderText.ALIGN_LEFT)
    setTextWrapWidth(width - 2 * paddingX); setTextLineBounds(0, 6)
    local height = getTextHeight(fontSize, element.skinFullVehicleName) + 2 * paddingY
    local x = math.max(paddingX, math.min(1 - width - paddingX, element.overlay.x))
    local y = math.max(paddingY, math.min(1 - height - paddingY, element.overlay.y + element.overlay.height + paddingY))
    if element.skinTooltipOverlay == nil then
        element.skinTooltipOverlay = Overlay.new('dataS/menu/base/graph_pixel.dds', 0, 0, 1, 1)
    end
    local background = element.skinTooltipOverlay
    background:setPosition(x, y); background:setDimension(width, height)
    background:setColor(0, 0, 0, 0.95); background:render()
    setTextColor(1, 1, 1, 1)
    renderText(x + paddingX, y + height - paddingY - fontSize, fontSize, element.skinFullVehicleName)
    setTextWrapWidth(0); setTextLineBounds(0, 2); setTextColor(1, 1, 1, 1)
end

function CpHudSkin.apply(root, header)
    local selected = CpHudSkin.isSelected()
    applyElement(root, selected)
    if header ~= nil and header.skinSelected ~= selected then
        if header.skinOriginalTextColor == nil then
            header.skinOriginalTextColor = header.textColor
            header.skinOriginalBold = header.textBold
        end
        header.textBold = selected or header.skinOriginalBold
        header:setTextDetails("Courseplay", nil, nil,
            selected and CpHudSkin.headerColor or header.skinOriginalTextColor)
        header.skinSelected = selected
    end
end

-- Keep column widths independent of changing text; native positions remain intact.
function CpHudSkin.prepareLayout(hud)
    local root = hud.baseHud
    local scale = hud.uiScale or 1
    local px,py=scale/g_screenWidth,scale/g_screenHeight
    local gap,height=4/g_screenWidth,24*py
    local line= hud.lineHeight or 23*py
    local nameY=hud.vehicleNameBtn and hud.vehicleNameBtn.overlay.y or root.overlay.y+8*line
    local topY=nameY-6*py
    local headerBottom=root.overlay.y+root.overlay.height-(hud.hMargin or line)
    local headerHeight=math.max((hud.hMargin or line)+2*py,height+2*py)
    local headerExtra=headerHeight-(hud.hMargin or line)
    local inset=math.max(2*py,headerBottom-topY-height)
    local insetX=inset/py*px
    local left=root.overlay.x+insetX
    local right=root.overlay.x+hud.width-insetX
    local columnGap=20*px
    local column=(right-left-columnGap)/2
    local rightX=right-column
    local toolbarCell=22*px
    local numericCell=24*px
    local numericValue=column-2*numericCell-2*gap
    local bottom=root.overlay.y+(hud.hMargin or line)
    local function bounds(e,x,y,w)
        if e then e.skinLayoutBounds={x,y,w,height}; e.skinControlWidth=w end
    end
    local function row(e)
        return math.floor((e.overlay.y-bottom)/line+0.5)+1
    end
    local rowPitch=math.max(line,height+2/g_screenHeight)
    local sectionGap=6*py
    local identityBottom=nameY+(hud.vehicleNameBtn and hud.vehicleNameBtn.overlay.offsetY or 0)-26*py
    local modeY=identityBottom-sectionGap-height
    local separatorY=modeY-sectionGap-2*py
    local bodyTop=separatorY-sectionGap-2*py
    local function rowY(index) return bodyTop-height+(index-5)*rowPitch end
    local groups={}
    local function visit(parent)
        parent.skinLayoutBounds=nil
        parent.skinCenterText=nil
        for _,child in ipairs(parent.children or {}) do visit(child) end
        if parent.overlay and parent.text == nil and parent ~= root
            and parent.overlay.width >= hud.width*0.95 then
            parent.skinHeaderPanel=parent.overlay.height>(hud.hMargin or line)*0.5
        end
        if parent.text ~= nil and CpHudSkin.isButton(parent) then
            local x=parent.textAlignment==RenderText.ALIGN_RIGHT and rightX or left
            bounds(parent,x,rowY(row(parent)),column)
        elseif parent.overlay and CpHudSkin.isButton(parent) then
            local o=parent.overlay
            -- All body icon buttons occupy the same right-hand column cell.
            bounds(parent,rightX,rowY(row(parent)),column)
        end
        if parent.labelElement and parent.textElement then table.insert(groups,parent) end
    end
    visit(root)
    -- CP keeps setting labels/values as siblings of their group container.
    -- Assign groups after traversing the whole tree so sibling visits cannot
    -- replace the shared numeric row with independently sized controls.
    for _,parent in ipairs(groups) do
        local y=rowY(row(parent.labelElement))
        bounds(parent.labelElement,left,y,column)
        if parent.incrementalElement or parent.decrementalElement then
            bounds(parent.decrementalElement,rightX,y,numericCell)
            bounds(parent.textElement,rightX+numericCell+gap,y,numericValue)
            parent.textElement.skinCenterText=true
            bounds(parent.incrementalElement,right-numericCell,y,numericCell)
        else
            bounds(parent.textElement,rightX,y,column)
        end
    end
    bounds(hud.vehicleNameBtn,left,topY,column)
    bounds(hud.selectedJobBtn,left,modeY,column)
    local font=hud.vehicleNameBtn and hud.vehicleNameBtn:scalePixelToScreenHeight(12) or 12*py
    setTextBold(false)
    local iconH=font*0.8
    local iconW=iconH*g_screenHeight/g_screenWidth
    local settingsWidth=16*px+iconW+5*px+getTextWidth(font,'Settings')
    bounds(hud.goalBtn,right-settingsWidth,modeY,settingsWidth)
    if hud.goalBtn then
        hud.goalBtn.skinSettingsFont=font; hud.goalBtn.skinSettingsIconWidth=iconW
        hud.goalBtn.skinSettingsIconHeight=iconH
        hud.goalBtn.skinSettingsPadding=8*px; hud.goalBtn.skinSettingsGap=5*px
    end
    if hud.goalBtn then hud.goalBtn.skinSettings=true end
    local toolbar={}
    local function add(e)
        if e and e.visible then table.insert(toolbar,e) end
    end
    add(hud.cpIcon)
    local pages={}
    for _,pageName in ipairs({'fieldworkLayout','baleFinderLayout','combineUnloaderLayout','bunkerSiloWorkerLayout','siloLoaderWorkerLayout'}) do
        local page=hud[pageName]
        if page then table.insert(pages,page) end
        if page and page.visible then add(page.reverseCourseBtn); add(page.driveNowBtn) end
        if page and page.timeRemainingText then
            page.timeRemainingText.skinGridText=true
            bounds(page.timeRemainingText,rightX,rowY(5),column)
        end
    end
    if hud.onOffButton then hud.onOffButton.skinPlayControl=true end
    add(hud.clearCourseBtn); add(hud.startStopRecordingBtn)
    for _,page in ipairs(pages) do
        if page.courseVisibilityBtn then page.courseVisibilityBtn.skinCourseVisibility=true end
        if page.visible then add(page.courseVisibilityBtn) end
        bounds(page.clearCacheBtn,right-2*toolbarCell-gap,rowY(1),toolbarCell)
        bounds(page.copyButton,right-toolbarCell,rowY(1),toolbarCell)
        bounds(page.pasteButton,right-toolbarCell,rowY(1),toolbarCell)
        for _,button in pairs({page.clearCacheBtn,page.copyButton,page.pasteButton}) do
            if button then button.skinLayoutBounds[4]=22*py; button.skinLayoutBounds[2]=rowY(1)+py end
        end
        if page.copyButton then page.copyButton.skinClipboard=true end
        if page.pasteButton then page.pasteButton.skinClipboard=true end
    end
    add(hud.onOffButton); add(hud.pauseRecordingBtn)
    local toolbarX=right-#toolbar*toolbarCell-math.max(0,#toolbar-1)*gap
    for i,element in ipairs(toolbar) do bounds(element,toolbarX+(i-1)*(toolbarCell+gap),topY,toolbarCell) end
    bounds(hud.vehicleNameBtn,left,topY,toolbarX-left-gap)
    -- Header icons use equal cells and a shared baseline too.
    local headerY=headerBottom+(headerHeight-height)/2
    bounds(hud.exitBtn,right-toolbarCell,headerY,toolbarCell)
    bounds(hud.helpMenuBtn,right-2*toolbarCell-gap,headerY,toolbarCell)
    if hud.skinVersionText then
        hud.skinVersionText.skinDisplayPosition={right-2*toolbarCell-2*gap-4*px,headerY+(height-(hud.skinVersionText.screenTextSize or 11*py))/2}
    end
    if hud.skinHeaderText then
        hud.skinHeaderText.skinDisplayPosition={root.overlay.x+4*px,headerBottom+(headerHeight-(hud.skinHeaderText.screenTextSize or 11*py))/2}
    end
    -- Crop only the drawn background; native coordinates stay stable for dragging.
    local panelBottom=rowY(1)-inset
    root.skinPanelBounds={root.overlay.x,panelBottom,hud.width,root.overlay.y+root.overlay.height+headerExtra-panelBottom}
    CpHudSkin.setRenderBounds(root,root.skinPanelBounds)
    local function alignSeparators(parent)
        for _,child in ipairs(parent.children or {}) do
            local o=child.overlay
            if o and child.text==nil and not CpHudSkin.isButton(child)
                and o.width>hud.width*0.8 and o.height<line*0.3 then
                CpHudSkin.setRenderBounds(child,{left,separatorY,right-left,2*py})
            elseif child.skinHeaderPanel then
                CpHudSkin.setRenderBounds(child,{root.overlay.x,headerBottom,hud.width,headerHeight})
            end
            alignSeparators(child)
        end
    end
    alignSeparators(root)
    CpHudSkin.assignTooltips(hud,groups)
    hud.skinGrid={
        left=left,right=right,rightX=rightX,column=column,height=height,gap=gap,columnGap=columnGap,
        toolbarX=toolbarX,toolbarCell=toolbarCell,numericCell=numericCell,numericValue=numericValue,footerY=rowY(1),
        inset=inset,insetX=insetX,panelBottom=panelBottom,headerBottom=headerBottom,headerHeight=headerHeight}
end

-- Draw text at the control's inset, independent of CP's changing measured width.
function CpHudSkin.drawControlText(element, originalDraw, ...)
    if not CpHudSkin.isSelected() or not (CpHudSkin.isButton(element) or element.skinGridText) then
        return originalDraw(element, ...)
    end
    local o=element.overlay
    local x,y,text,hoveredText,width,align=o.x,o.y,element.text,element.hoveredText,element.maxWidth,element.textAlignment
    local bx,by,bw,bh=CpHudSkin.buttonBounds(element)
    local padding=8/g_screenWidth
    element.skinDrawingBounds={bx,by,bw,bh}
    if not element.skinGridText then CpHudSkin.drawButtonBorder(element) end
    o.x=element.textAlignment==RenderText.ALIGN_RIGHT and bx+bw-padding or bx+padding
    o.y=by+6/g_screenHeight
    if element.skinCenterText then
        element.textAlignment=RenderText.ALIGN_CENTER
        o.x=bx+bw/2
    end
    element.maxWidth=bw-2*padding
    element.text=CpHudSkin.fitIdentityText(text,element.screenTextSize,element.maxWidth)
    if hoveredText then element.hoveredText=CpHudSkin.fitIdentityText(hoveredText,element.screenTextSize,element.maxWidth) end
    originalDraw(element,...)
    o.x,o.y,element.text,element.hoveredText,element.maxWidth=x,y,text,hoveredText,width
    element.textAlignment=align
    element.skinDrawingBounds=nil
end

function CpHudSkin.drawSettings(element, originalDraw)
    if not element.visible then return end
    local o = element.overlay
    local x,y,w,h = o.x,o.y,o.width,o.height
    local ox,oy = o.offsetX,o.offsetY
    local bounds={CpHudSkin.buttonBounds(element)}
    element.skinDrawingBounds=bounds
    local font=element.skinSettingsFont or 12/g_screenHeight
    o.x=bounds[1]+(element.skinSettingsPadding or 8/g_screenWidth)
    o.y=bounds[2]+(bounds[4]-(element.skinSettingsIconHeight or font))/2-1/g_screenHeight
    o.offsetX,o.offsetY = 0,0
    o.width,o.height = element.skinSettingsIconWidth or 12/g_screenWidth,element.skinSettingsIconHeight or font
    CpHudSkin.drawButtonBorder(element)
    originalDraw(element)
    setTextBold(false); setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(0.9,0.97,0.9,1)
    renderText(o.x + o.width + (element.skinSettingsGap or 5/g_screenWidth),bounds[2]+(bounds[4]-font)/2,font,'Settings')
    setTextColor(1,1,1,1)
    o.x,o.y,o.width,o.height,o.offsetX,o.offsetY=x,y,w,h,ox,oy
    element.skinDrawingBounds = nil
end

function CpHudSkin.drawIcon(element, originalDraw, ...)
    if not element.visible then return end
    local o = element.overlay
    local x,y,w,h,ox,oy = o.x,o.y,o.width,o.height,o.offsetX,o.offsetY
    local bounds = {CpHudSkin.buttonBounds(element)}
    element.skinDrawingBounds = bounds
    CpHudSkin.drawButtonBorder(element)
    if element.skinClipboard then
        local pixel=element.skinBorderOverlay
        local px,py=1/g_screenWidth,1/g_screenHeight
        local cx,cy=bounds[1]+bounds[3]/2,bounds[2]+bounds[4]/2
        pixel:setColor(0.9,0.97,0.9,1)
        local function rect(x,y,w,h)
            pixel:setPosition(cx+x*px,cy+y*py); pixel:setDimension(w*px,h*py); pixel:render()
        end
        -- A single clipboard silhouette with a clip and three inset lines.
        rect(-5,-7,1,12); rect(4,-7,1,12); rect(-5,-7,10,1)
        rect(-5,5,3,1); rect(2,5,3,1); rect(-2,4,4,3)
        for y=-4,2,3 do rect(-2,y,4,1) end
        element.skinDrawingBounds=nil
        return
    end
    local size = 14 / g_screenHeight
    o.width,o.height = 14/g_screenWidth,size
    o.x,o.y = bounds[1] + (bounds[3]-o.width)/2, bounds[2] + (bounds[4]-o.height)/2
    o.offsetX,o.offsetY=0,0
    originalDraw(element, ...)
    o.x,o.y,o.width,o.height,o.offsetX,o.offsetY=x,y,w,h,ox,oy
    element.skinDrawingBounds=nil
end

-- AFM loads the vehicles.xml nickname into this specialization and appends it
-- to getName(), which is the same name CP receives. Read live data for MP/renames.
function CpHudSkin.getCustomVehicleName(vehicle)
    local spec = vehicle.spec_hotKeyVehicle
    if spec and type(spec.nickname) == 'string' then return spec.nickname end
    local name = vehicle:getName()
    return name:match('%s%[([^%]]+)%]$') or ''
end

function CpHudSkin.getImplementNames(vehicle)
    local names, seen = {}, {[vehicle]=true}
    local function visit(parent)
        if not parent.getAttachedImplements then return end
        for _, attachment in ipairs(parent:getAttachedImplements() or {}) do
            local object = attachment.object
            if object and not seen[object] then
                seen[object] = true
                if object.getName then table.insert(names, object:getName()) end
                visit(object)
            end
        end
    end
    visit(vehicle)
    return names
end

-- Reserve a real second row above the existing job controls. Undo our previous
-- offsets first so repeated updates, skin switching and HUD dragging do not drift.
function CpHudSkin.layoutIdentityRow(hud)
    local root = hud.baseHud
    local function restore(element)
        if element.skinIdentityShift then
            element.overlay.y = element.overlay.y - element.skinIdentityShift
            element.skinIdentityShift = nil
        end
        for _,child in ipairs(element.children or {}) do restore(child) end
    end
    restore(root)
    if hud.skinIdentityHeight then
        root.overlay.height = root.overlay.height - hud.skinIdentityHeight
        hud.skinIdentityHeight = nil
    end
    if not CpHudSkin.isSelected() or not hud.vehicleNameBtn then return end
    local scale = hud.uiScale or 1
    local extra = 28 * scale / g_screenHeight
    local name = hud.vehicleNameBtn.overlay
    local cutoff = name.y - (hud.hMargin or hud.lineHeight or 0.02) * 0.5
    local function shift(parent)
        for _,child in ipairs(parent.children or {}) do
            if child.overlay and child.overlay.y >= cutoff then
                child.overlay.y = child.overlay.y + extra
                child.skinIdentityShift = extra
            end
            shift(child)
        end
    end
    shift(root)
    root.overlay.height = root.overlay.height + extra
    hud.skinIdentityHeight = extra
end

function CpHudSkin.drawIdentityRow(hud)
    if not CpHudSkin.isSelected() or not hud.vehicle or not hud.vehicleNameBtn
        or not hud.baseHud.visible then return end
    local name = hud.vehicleNameBtn.overlay
    local scale = hud.uiScale or 1
    local font = hud.vehicleNameBtn:scalePixelToScreenHeight(10)
    local left = hud.skinGrid and hud.skinGrid.left or hud.baseHud.overlay.x + hud.wMargin
    local right = hud.skinGrid and hud.skinGrid.right or hud.baseHud.overlay.x + hud.width - hud.wMargin
    local width = math.max(0, (right-left-12*scale/g_screenWidth)/2)
    local y = name.y + name.offsetY - 26 * scale / g_screenHeight
    local nickname = CpHudSkin.getCustomVehicleName(hud.vehicle)
    local implements = CpHudSkin.getImplementNames(hud.vehicle)
    local implement = table.concat(implements, ' / ')
    setTextBold(false); setTextWrapWidth(0); setTextLineBounds(0,1)
    setTextColor(0.76,0.79,0.76,1)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(left,y,font,CpHudSkin.fitIdentityText(nickname,font,width))
    setTextAlignment(RenderText.ALIGN_RIGHT)
    renderText(right,y,font,CpHudSkin.compactVehicleName(implement,font,width))
    setTextAlignment(RenderText.ALIGN_LEFT); setTextLineBounds(0,2); setTextColor(1,1,1,1)
end

function CpHudSkin.fitIdentityText(text,font,width)
    if getTextWidth(font,text) <= width then return text end
    while #text > 0 and getTextWidth(font,text .. '...') > width do
        text = text:gsub('[%z\1-\127\194-\244][\128-\191]*$', '')
    end
    return text .. '...'
end

function CpHudSkin.assignTooltips(hud,groups)
    local actions={cpIcon='Open Courseplay Global Settings',vehicleNameBtn='Open Vehicle Settings',
        selectedJobBtn='Change Courseplay Job',goalBtn='Open Course Generator',
        onOffButton='Start/Stop Courseplay Driver',startStopRecordingBtn='Start/Stop Course Recording',
        pauseRecordingBtn='Pause/Resume Course Recording',clearCourseBtn='Remove Course From Vehicle',
        exitBtn='Close Courseplay HUD',helpMenuBtn='Open Courseplay Help',
        reverseCourseBtn='Reverse Course Direction',courseVisibilityBtn='Change Course Visibility',
        startingPointBtn='Change Starting Waypoint',laneOffsetBtn='Change Lane Offset',
        courseNameBtn='Open Course Generator',waypointProgressBtn='Open Course Manager',
        balesProgressBtn='Open Course Manager',driveNowBtn='Start Unloading Now',
        copyButton='Copy Course or Job Settings',pasteButton='Paste Copied Course or Job Settings',
        clearCacheBtn='Clear Copied Course or Job Settings'}
    local function annotate(container)
        for name,text in pairs(actions) do
            if container[name] then container[name].skinTooltipText=text end
        end
    end
    annotate(hud)
    for _,name in ipairs({'fieldworkLayout','baleFinderLayout','combineUnloaderLayout','bunkerSiloWorkerLayout','siloLoaderWorkerLayout'}) do
        if hud[name] then annotate(hud[name]) end
    end
    for _,group in ipairs(groups) do
        local label=group.labelElement.skinSourceText or group.labelElement.text or 'Setting'
        if group.incrementalElement or group.decrementalElement then
            group.labelElement.skinTooltipText='Reset ' .. label .. ' to Default'
            group.textElement.skinTooltipText='Scroll to Adjust ' .. label
            if group.incrementalElement then group.incrementalElement.skinTooltipText='Increase ' .. label end
            if group.decrementalElement then group.decrementalElement.skinTooltipText='Decrease ' .. label end
        else
            group.labelElement.skinTooltipText='Change ' .. label
            group.textElement.skinTooltipText='Change ' .. label
        end
    end
end

function CpHudSkin.drawHudTooltip(hud)
    if not CpHudSkin.tooltipHeld then return end
    if not CpHudSkin.isSelected() or not hud.baseHud.visible then return end
    local target
    local function find(parent)
        if not parent.visible then return end
        if parent.hovered and CpHudSkin.isButton(parent) then target=parent end
        for _,child in ipairs(parent.children or {}) do find(child) end
    end
    find(hud.baseHud)
    if not target then return end
    local text=target.skinTooltipText
    if not text then
        local callback=(target.callbacks or {}).onClickPrimary or (target.callbacks or {}).onClickMouseWheel
        local setting=callback and callback.class
        if setting and type(setting.getTitle)=='function' then text='Change ' .. setting:getTitle() end
        text=text or ('Change ' .. (target.skinSourceText or target.text or 'Courseplay Setting'))
    end
    if target.skinFullVehicleName then text=target.skinFullVehicleName .. '\n' .. text end
    if target.disabled then text=text .. '\nCurrently Unavailable' end
    local owner=hud.vehicleNameBtn
    if not owner then return end
    if not owner.skinTooltipOverlay then owner.skinTooltipOverlay=Overlay.new('dataS/menu/base/graph_pixel.dds',0,0,1,1) end
    local font=owner:scalePixelToScreenHeight(12)
    local padX,padY=8/g_screenWidth,8/g_screenHeight
    setTextBold(false); setTextAlignment(RenderText.ALIGN_LEFT)
    setTextWrapWidth(0); setTextLineBounds(0,1)
    local maxWidth=0.4-2*padX
    local lines={}
    for paragraph in (text .. '\n'):gmatch('(.-)\n') do
        local current=''
        for word in paragraph:gmatch('%S+') do
            local candidate=current=='' and word or current .. ' ' .. word
            if current~='' and getTextWidth(font,candidate)>maxWidth then
                table.insert(lines,current); current=word
            else current=candidate end
        end
        table.insert(lines,CpHudSkin.fitIdentityText(current,font,maxWidth))
    end
    local contentWidth=0
    for _,line in ipairs(lines) do contentWidth=math.max(contentWidth,getTextWidth(font,line)) end
    -- Lines are wrapped above and drawn individually. Keep their spacing in
    -- normalized screen units instead of inheriting the engine's text bounds.
    local lineHeight=font*1.35
    local width=contentWidth+2*padX
    local height=#lines*lineHeight+2*padY
    local bx,by,bw,bh=CpHudSkin.buttonBounds(target)
    local pointerX=CpHudSkin.pointerX or bx+bw
    local pointerY=CpHudSkin.pointerY or by+bh
    local x=pointerX+12/g_screenWidth
    if x+width>1-padX then x=pointerX-width-12/g_screenWidth end
    x=math.max(padX,math.min(1-width-padX,x))
    local y=math.max(padY,math.min(1-height-padY,pointerY-height+lineHeight))
    local overlay=owner.skinTooltipOverlay
    overlay:setPosition(x,y); overlay:setDimension(width,height)
    overlay:setColor(0,0,0,1); overlay:render()
    setTextColor(0.9,0.97,0.9,1)
    for i,line in ipairs(lines) do
        renderText(x+padX,y+height-padY-i*lineHeight+(lineHeight-font)/2,font,line)
    end
    setTextWrapWidth(0); setTextLineBounds(0,2); setTextColor(1,1,1,1)
end

function CpHudSkin.setRenderBounds(element,bounds)
    element.skinRenderBounds=bounds
    local o=element.overlay
    if element.skinOriginalRender then return end
    element.skinOriginalRender=o.render
    o.render=function(overlay,...)
        if not CpHudSkin.isSelected() or not element.skinRenderBounds then
            return element.skinOriginalRender(overlay,...)
        end
        local x,y,w,h=overlay.x,overlay.y,overlay.width,overlay.height
        local b=element.skinRenderBounds
        overlay:setPosition(b[1],b[2]); overlay:setDimension(b[3],b[4])
        if element.skinInfoPanel or element.skinHeaderPanel then
            overlay:setColor(0,0,0,element.skinHeaderPanel and 0.88 or 0.67)
        end
        element.skinOriginalRender(overlay,...)
        overlay:setPosition(x,y); overlay:setDimension(w,h)
    end
end

function CpHudSkin.drawTooltipHint(hud)
    if not CpHudSkin.isSelected() or not hud.baseHud.visible or not hud.skinGrid then return end
    local grid=hud.skinGrid
    local font=hud.vehicleNameBtn:scalePixelToScreenHeight(10)
    local brand='BinyamFS Edition'
    local brandRight=grid.right-grid.toolbarCell-grid.gap-6/g_screenWidth
    local width=brandRight-getTextWidth(font,brand)-grid.left-12/g_screenWidth
    local text=CpHudSkin.fitIdentityText('Hold Left Alt for tooltip',font,width)
    setTextBold(false); setTextAlignment(RenderText.ALIGN_LEFT)
    setTextWrapWidth(0); setTextLineBounds(0,1)
    setTextColor(0.76,0.79,0.76,1)
    renderText(grid.left,grid.footerY+(grid.height-font)/2,font,text)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    renderText(brandRight,grid.footerY+(grid.height-font)/2,font,brand)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextLineBounds(0,2); setTextColor(1,1,1,1)
end

-- CP's information window has its own top-aligned panel and row controls.
function CpHudSkin.prepareInfoLayout(hud)
    local root=hud.baseHud
    root.skinInfoPanel=true
    if not CpHudSkin.isSelected() then
        root.skinPanelBounds=nil
        for _,child in ipairs(root.children or {}) do
            child.skinLayoutBounds=nil
            child.skinDisplayPosition=nil
            child.skinInfoCardBounds=nil
            child.skinGridText=nil
        end
        return
    end
    local scale=hud.uiScale or 1
    local px,py=scale/g_screenWidth,scale/g_screenHeight
    local inset,gap,cell,height,headerHeight=4*px,3*px,22*px,24*py,22*py
    local top=root.overlay.y
    -- Fixed width: message and hover text are fitted within the same card.
    local width=math.min(350*px,1-12*px)
    local left=math.max(6*px,math.min(root.overlay.x,1-width-6*px))
    local count=hud.activeTexts or 0
    local panelHeight=headerHeight+(count>0 and 5*py+count*height+math.max(0,count-1)*py or 0)
    root.skinPanelBounds={left,top,width,panelHeight}
    CpHudSkin.setRenderBounds(root,root.skinPanelBounds)
    for _,child in ipairs(root.children or {}) do
        if child.text=='Courseplay' or child.text==g_Courseplay.currentVersion then
            child.skinHeader=true
            child.skinDisplayPosition={child.text=='Courseplay' and left+inset or left+width-inset,top-headerHeight+(headerHeight-11*py)/2}
            if child.text=='Courseplay' then hud.skinHeaderText=child end
        elseif child.text==nil and not CpHudSkin.isButton(child) and child.overlay and child.overlay.width>=(hud.width or root.overlay.width)*0.95 then
            child.skinHeaderPanel=true
            CpHudSkin.setRenderBounds(child,{left,top,width,headerHeight})
        end
    end
    for i,line in ipairs(hud.infoTextsElements or {}) do
        local y=top-headerHeight-py-i*height-(i-1)*py
        line.vehicleBtn.skinLayoutBounds={left+inset,y,cell,height}
        line.vehicleBtn.skinInfoCardBounds={left,y,width,height}
        line.text.skinGridText=true
        local currentVehicle=CourseplayBinyamFS and CourseplayBinyamFS.cp and CourseplayBinyamFS.cp.CpUtil and CourseplayBinyamFS.cp.CpUtil.getCurrentVehicle and CourseplayBinyamFS.cp.CpUtil.getCurrentVehicle()
        -- CP exposes its classes in the mod environment; the info record keeps
        -- the exact owning vehicle, so switching vehicles updates immediately.
        if currentVehicle == nil and CpUtil ~= nil and CpUtil.getCurrentVehicle ~= nil then currentVehicle=CpUtil.getCurrentVehicle() end
        local current=line.lastInfo ~= nil and line.lastInfo.vehicle == currentVehicle and currentVehicle ~= nil
        line.text:setTextColorChannels(current and 0.35 or 1, current and 0.85 or 1, current and 0.25 or 1, 1)
        line.text.skinLayoutBounds={left+inset+cell+gap,y,width-2*inset-cell-gap,height}
        line.text.skinPreserveCase=true
    end
end

