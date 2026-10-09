-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 BinyamFS. Updated 2026-10-08; unofficial CP companion.
--- Companion mod: wrap Courseplay's public mod namespace without changing its files.
CourseplayBinyamFS = {installed = false}
local M = CourseplayBinyamFS
local i18n = g_i18n

local function warn(message)
    if Logging ~= nil then Logging.warning('[BinyamFS HUD] %s', message) end
end

local function findHeader(hud)
    for _, child in ipairs(hud.baseHud.children or {}) do
        if child.text == 'Courseplay' then
            child.skinHeader = true
            hud.skinHeaderText = child
        elseif child.text == g_Courseplay.currentVersion then
            child.skinHeader = true
            hud.skinVersionText = child
        end
    end
end

function M.addSetting(settings, cp)
    if settings.binyamfsHudSkin ~= nil then return true end
    local userSection
    for _, section in ipairs(settings.settingsBySubTitle or {}) do
        if section.title == 'CP_global_setting_subTitle_userSettings' then
            userSection = section
            break
        end
    end
    if userSection == nil or settings.settings == nil then
        warn('Courseplay User Settings structure is unsupported; skin option was not added.')
        return false
    end
    local parameters = {
        classType = 'AIParameterSettingList', name = 'binyamfsHudSkin',
        setupName = 'BFS_HUD_SKIN', title = 'BFS_HUD_SKIN_TITLE', tooltip = 'BFS_HUD_SKIN_TOOLTIP',
        isUserSetting = true, isExpertModeOnly = false, default = 0,
        values = {0, 1}, texts = {i18n:getText('BFS_HUD_SKIN_COURSEPLAY'), i18n:getText('BFS_HUD_SKIN_BINYAMFS')},
        disabledValuesFuncs = {}, callbacks = {onChangeCallbackStr = 'onBinyamfsHudSkinChanged'},
        uniqueID = #settings.settings
    }
    local setting = cp.CpSettingsUtil.getSettingFromParameters(parameters, nil, settings)
    if setting == nil then warn('Courseplay could not create the HUD skin setting.'); return false end
    -- Resolve labels in this add-on's translation context, not CP's namespace.
    setting.getTitle = function() return i18n:getText('BFS_HUD_SKIN_TITLE') end
    setting.getTooltip = function() return i18n:getText('BFS_HUD_SKIN_TOOLTIP') end
    settings.binyamfsHudSkin = setting
    table.insert(settings.settings, setting)
    table.insert(userSection.elements, setting)
    return true
end

function M.install(cp)
    if M.installed then return true end
    if cp == nil or cp.g_Courseplay == nil then return false end
    local required = {
        {'CpGlobalSettings', 'loadSettingsSetup'}, {'CpSettingsUtil', 'getSettingFromParameters'},
        {'CpBaseHud', 'init'}, {'CpBaseHud', 'updateContent'}, {'CpBaseHud', 'draw'},
        {'CpHudInfoTexts', 'init'}, {'CpHudInfoTexts', 'update'},
        {'CpTextHudElement', 'setTextDetails'}, {'CpTextHudElement', 'draw'},
        {'CpHudButtonElement', 'draw'}, {'CpHudButtonElement', 'delete'}, {'CpHudElement', 'isMouseOverArea'}
    }
    for _, entry in ipairs(required) do
        if cp[entry[1]] == nil or type(cp[entry[1]][entry[2]]) ~= 'function' then
            warn('Unsupported Courseplay HUD interface: ' .. entry[1] .. '.' .. entry[2])
            return false
        end
    end
    -- These aliases belong to this add-on's script environment only.
    g_Courseplay, CpBaseHud, CpTextHudElement = cp.g_Courseplay, cp.CpBaseHud, cp.CpTextHudElement

    local loadSetup = cp.CpGlobalSettings.loadSettingsSetup
    cp.CpGlobalSettings.loadSettingsSetup = function(settings, ...)
        loadSetup(settings, ...)
        M.addSetting(settings, cp)
    end
    cp.CpGlobalSettings.onBinyamfsHudSkinChanged = function()
        -- Persist for hosts and clients immediately; CP's existing client callback
        -- may also save the same local preference. This never broadcasts a setting.
        if g_Courseplay.infoTextsHud ~= nil then g_Courseplay:saveUserSettings() end
    end

    local setText = cp.CpTextHudElement.setTextDetails
    cp.CpTextHudElement.setTextDetails = function(element, text, size, align, color, bold, width)
        element.skinSourceText = text or element.skinSourceText or element.text
        element.text = element.skinSourceText
        CpHudSkin.styleText(element, size, bold)
        local display = element.text
        setText(element, display, element.textSize, align, color, element.textBold, width)
    end
    local drawText = cp.CpTextHudElement.draw
    cp.CpTextHudElement.draw = function(element, ...)
        -- CP 8.1 uses a class-level hover color. Scope that color to this draw so
        -- existing text rendering (including shadows and tooltips) stays intact.
        local original = cp.CpTextHudElement.highlightedColor
        cp.CpTextHudElement.highlightedColor = element.highlightedColor or original
        local x,y=element.overlay.x,element.overlay.y
        if CpHudSkin.isSelected() and element.skinDisplayPosition then
            element.overlay.x,element.overlay.y=unpack(element.skinDisplayPosition)
        end
        element.skinDrawingText = true
        CpHudSkin.drawControlText(element, drawText, ...)
        element.skinDrawingText = nil
        element.overlay.x,element.overlay.y=x,y
        cp.CpTextHudElement.highlightedColor = original
    end

    local drawButton = cp.CpHudButtonElement.draw
    cp.CpHudButtonElement.draw = function(element, ...)
        if CpHudSkin.isSelected() and element.skinSettings then
            CpHudSkin.drawSettings(element, drawButton)
        else
            if CpHudSkin.isSelected() and element.text == nil and CpHudSkin.isButton(element) then
                CpHudSkin.drawIcon(element, drawButton, ...)
            else
                drawButton(element, ...)
            end
        end
    end
    local deleteButton = cp.CpHudButtonElement.delete
    cp.CpHudButtonElement.delete = function(element, ...)
        if element.skinBorderOverlay ~= nil then element.skinBorderOverlay:delete(); element.skinBorderOverlay = nil end
        if element.skinTooltipOverlay ~= nil then element.skinTooltipOverlay:delete(); element.skinTooltipOverlay = nil end
        deleteButton(element, ...)
    end
    local mouseOver = cp.CpHudElement.isMouseOverArea
    cp.CpHudElement.isMouseOverArea = function(element, posX, posY)
        CpHudSkin.pointerX,CpHudSkin.pointerY=posX,posY
        if CpHudSkin.isSelected() and element.skinInfoPanel and element.skinPanelBounds then
            local b=element.skinPanelBounds
            return GuiUtils.checkOverlayOverlap(posX,posY,b[1],b[2]-b[4],b[3],b[4])
        end
        if CpHudSkin.isSelected() and CpHudSkin.isButton(element) then
            local x,y,w,h = CpHudSkin.buttonBounds(element)
            return GuiUtils.checkOverlayOverlap(posX, posY, x, y, w, h)
        end
        return mouseOver(element, posX, posY)
    end

    for _, name in ipairs({'CpBaseHud', 'CpHudInfoTexts'}) do
        local init = cp[name].init
        cp[name].init = function(hud, ...)
            init(hud, ...)
            findHeader(hud)
        end
    end
    local updateHud = cp.CpBaseHud.updateContent
    cp.CpBaseHud.updateContent = function(hud, vehicle, ...)
        updateHud(hud, vehicle, ...)
        CpHudSkin.layoutIdentityRow(hud)
        CpHudSkin.prepareLayout(hud)
        CpHudSkin.updateVehicleName(hud, vehicle)
        CpHudSkin.apply(hud.baseHud, hud.skinHeaderText)
    end
    local drawHud = cp.CpBaseHud.draw
    cp.CpBaseHud.draw = function(hud, ...)
        drawHud(hud, ...)
        M.tooltipHud=hud
        M:updateTooltipCapture()
        CpHudSkin.drawIdentityRow(hud)
        CpHudSkin.drawTooltipHint(hud)
        -- The tooltip is drawn after the mission HUD, so later vehicle HUD
        -- passes cannot paint their value text over its opaque background.
        M.tooltipDrawPending=hud
    end
    local updateInfo = cp.CpHudInfoTexts.update
    cp.CpHudInfoTexts.update = function(hud, ...)
        updateInfo(hud, ...)
        CpHudSkin.prepareInfoLayout(hud)
        CpHudSkin.apply(hud.baseHud, hud.skinHeaderText)
    end
    M.installed = true
    return true
end

local cpName = g_modManager and g_modManager.CP_MOD_NAME
if not M.install(cpName and _G[cpName]) then
    warn('Courseplay was not available or compatible. Load FS25_Courseplay alongside this add-on; its HUD remains unchanged.')
end

-- Poll the physical modifier before input dispatch. The tooltip no longer
-- depends on registration of a modifier-only game action.
M.TOOLTIP_CONTEXT='BINYAMFS_CP_TOOLTIP'
function M:isPointerOverHud()
    local hud=self.tooltipHud
    if not self.installed or not CpHudSkin.isSelected() or not hud or not hud.baseHud.visible then return false end
    if g_gui and g_gui.getIsGuiVisible and g_gui:getIsGuiVisible() then return false end
    if g_inputBinding and g_inputBinding.getShowMouseCursor and not g_inputBinding:getShowMouseCursor() then return false end
    local x,y=CpHudSkin.pointerX,CpHudSkin.pointerY
    if not x or not y then return false end
    local b=hud.baseHud.skinPanelBounds
    if not b then return false end
    return GuiUtils.checkOverlayOverlap(x,y,unpack(b))
end

function M:releaseTooltipCapture()
    local binding=g_inputBinding
    if self.tooltipCaptured and binding then
        local current=binding:getContextName()
        if current==self.TOOLTIP_CONTEXT then
            binding:revertContext(true)
        elseif binding.setPreviousContext and self.tooltipPreviousContext then
            -- A dialog opened from a CP button while Alt was held. Preserve the
            -- dialog, but remove our temporary context from its return path.
            binding:setPreviousContext(current,self.tooltipPreviousContext)
        end
    end
    self.tooltipCaptured=false
    self.tooltipPreviousContext=nil
    CpHudSkin.tooltipHeld=false
end

function M:updateTooltipCapture()
    local held=Input and Input.isKeyPressed and Input.KEY_lalt and Input.isKeyPressed(Input.KEY_lalt)
    local wanted=held and self:isPointerOverHud()
    local binding=g_inputBinding
    if wanted and binding and binding.setContext and binding.getContextName and binding.revertContext then
        if not self.tooltipCaptured then
            self.tooltipPreviousContext=binding:getContextName()
            binding:setContext(self.TOOLTIP_CONTEXT,true,false)
            self.tooltipCaptured=true
        elseif binding:getContextName()~=self.TOOLTIP_CONTEXT then
            self:releaseTooltipCapture()
            return
        end
        CpHudSkin.tooltipHeld=true
    else
        self:releaseTooltipCapture()
    end
end

function M:installInputCapture()
    local binding=g_inputBinding
    if not binding or self.inputBindingHook==binding or type(binding.update)~='function' then return end
    self.inputBindingHook=binding
    local original=binding.update
    self.originalInputUpdate=original
    self.inputUpdateWrapper=function(manager,...)
        M:updateTooltipCapture()
        return original(manager,...)
    end
    binding.update=self.inputUpdateWrapper
end
function M:loadMap()
    self:installInputCapture()
    if FSBaseMission and type(FSBaseMission.draw)=='function' and not self.tooltipDrawHook then
        self.tooltipDrawHook=true
        local draw=FSBaseMission.draw
        FSBaseMission.draw=function(mission,...)
            draw(mission,...)
            local hud=M.tooltipDrawPending
            M.tooltipDrawPending=nil
            if hud then CpHudSkin.drawHudTooltip(hud) end
        end
    end
end
function M:update() self:installInputCapture(); self:updateTooltipCapture() end
function M:mouseEvent(x,y)
    CpHudSkin.pointerX,CpHudSkin.pointerY=x,y
    self:updateTooltipCapture()
end
function M:keyEvent() self:updateTooltipCapture() end
function M:deleteMap()
    self:releaseTooltipCapture()
    if self.inputBindingHook and self.inputBindingHook.update==self.inputUpdateWrapper then
        self.inputBindingHook.update=self.originalInputUpdate
    end
    self.inputBindingHook=nil; self.originalInputUpdate=nil; self.inputUpdateWrapper=nil; self.tooltipHud=nil
    self.tooltipDrawPending=nil
end
if addModEventListener then addModEventListener(M) end
