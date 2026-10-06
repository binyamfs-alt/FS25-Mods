HoneyCadenceSettings = {intervals={250, 500, 1000, 5000, 10000}, state=5, revision=0}
local S = HoneyCadenceSettings

function S.setState(state)
    if type(state) ~= "number" or S.intervals[state] == nil then return false end
    if S.state ~= state then
        S.state = state
        S.revision = S.revision + 1
        print(string.format("[FasterHoneyCadence] Spawn interval: %d ms", S.intervals[state]))
    end
    return true
end

function S.getPath()
    local mission = g_currentMission
    local info = mission ~= nil and mission.missionInfo or nil
    if info ~= nil and info.savegameDirectory ~= nil then
        return info.savegameDirectory .. "/honeyCadence.xml"
    end
end

function S.load()
    S.state = 5
    S.revision = S.revision + 1
    if g_server == nil then return end
    local path = S.getPath()
    if path == nil then return end
    local xml = XMLFile.loadIfExists("honeyCadence", path)
    if xml ~= nil then
        local interval = xml:getInt("honeyCadence#intervalMs", 10000)
        for state, value in ipairs(S.intervals) do
            if interval == value then S.setState(state) end
        end
        xml:delete()
    end
end

function S.save()
    if g_server == nil then return end
    local path = S.getPath()
    if path == nil then return end
    local xml = XMLFile.create("honeyCadence", path, "honeyCadence")
    if xml ~= nil then
        xml:setInt("honeyCadence#intervalMs", S.intervals[S.state])
        xml:save()
        xml:delete()
    end
end

-- Server-to-client display synchronization only. Clients cannot change cadence.
HoneyCadenceSettingsEvent = {}
local Event_mt = Class(HoneyCadenceSettingsEvent, Event)
InitEventClass(HoneyCadenceSettingsEvent, "HoneyCadenceSettingsEvent")
function HoneyCadenceSettingsEvent.emptyNew()
    return Event.new(Event_mt)
end
function HoneyCadenceSettingsEvent.new()
    local event = HoneyCadenceSettingsEvent.emptyNew()
    event.state = S.state
    return event
end
function HoneyCadenceSettingsEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.state, 3)
end
function HoneyCadenceSettingsEvent:readStream(streamId, connection)
    self.state = streamReadUIntN(streamId, 3)
    self:run(connection)
end
function HoneyCadenceSettingsEvent:run(connection)
    if connection:getIsServer() then S.setState(self.state) end
end

function S.updateGui(frame)
    local layout = frame.generalSettingsLayout
    if layout == nil then return end
    if frame.honeyCadenceOption == nil then
        local heading
        local template = frame.multiVolumeVoiceBox
        for _, row in ipairs(layout.elements) do
            if heading == nil and row.name == "sectionHeader" then heading = row end
            local option = row.elements ~= nil and row.elements[1] or nil
            if template == nil and row.typeName == "Bitmap" and option ~= nil
                and option.typeName == "MultiTextOption" then template = row end
        end
        if heading == nil or template == nil then
            if not S.warned then
                print("[FasterHoneyCadence] Settings UI templates unavailable.")
                S.warned = true
            end
            return
        end
        local header = heading:clone(layout, false)
        header:setText("Honey Pallet Spawning")
        local function assignFocus(element)
            element.focusId = FocusManager:serveAutoFocusId()
            for _, child in ipairs(element.elements or {}) do assignFocus(child) end
        end
        assignFocus(header)
        table.insert(frame.controlsList, header)
        local row = template:clone(layout, false)
        row.id = nil
        local option = row.elements[1]
        option.id = "honeyCadenceInterval"
        option:setTexts({"250 ms", "500 ms", "1 second", "5 seconds", "10 seconds"})
        row.elements[2]:setText("Spawn interval")
        option.elements[1]:setText("Wait between honey pallet spawning rounds. Changes apply immediately and are saved per savegame. Only the host can change this setting.")
        option.onClickCallback = function(_, state)
            if g_server ~= nil and S.setState(state) then
                S.save()
                g_server:broadcastEvent(HoneyCadenceSettingsEvent.new())
            end
            option:setState(S.state)
        end
        row:setVisible(true)
        row:setDisabled(false)
        option:setVisible(true)
        assignFocus(row)
        table.insert(frame.controlsList, row)
        frame.honeyCadenceOption = option
        layout:invalidateLayout()
    end
    frame.honeyCadenceOption:setState(S.state)
    frame.honeyCadenceOption:setDisabled(g_server == nil)
end

Mission00.loadItemsFinished = Utils.appendedFunction(Mission00.loadItemsFinished, S.load)
FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, S.save)
InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, S.updateGui)
FSBaseMission.sendInitialClientState = Utils.appendedFunction(FSBaseMission.sendInitialClientState,
    function(_, connection) connection:sendEvent(HoneyCadenceSettingsEvent.new()) end)
