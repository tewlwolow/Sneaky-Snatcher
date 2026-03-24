local config = require("tew.Sneaky Snatcher.config")

local metadata = toml.loadMetadata("Sneaky Snatcher")
local version = metadata.package.version
local debugLogOn = config.debugLogOn

local function debugLog(message, ...)
    if debugLogOn then
        local info = debug.getinfo(2, "Sl")
        local module = info.short_src:match("^.+\\(.+).lua$")
        local prepend = ("[%s.%s.%s:%s]:"):format(metadata.package.name, version, module, info.currentline)
        local aligned = ("%-36s"):format(prepend)
        mwse.log(aligned .. " -- " .. string.format("%s", message), ...)
    end
end

-- Flag to control whether player has been detected by NPCs
---@type boolean
local playerDetected

-- Timestamp for last detection attempt
---@type number
local lastChecked = 0

-- A table to track references (yes, again and again)
---@type tes3reference[]
local refs = {}

--- A table to hold our skill increase values for activate targets
local activateTypes = {
    [tes3.objectType.container] = config.sneakSkillIncreaseContainer,
    [tes3.objectType.door] = config.sneakSkillIncreaseDoor,
}

--- Determine if we have a valid target for our action
--- @param target tes3reference
local function isValidTarget(target)
    local ownershipOk = (config.useOwnership and tes3.hasOwnershipAccess { target = target } or not config.useOwnership)
    local typeOk = (
        (target.object.objectType == tes3.objectType.container and not target.lockNode) or
        (not target.context)
    )

    local valid = ownershipOk and typeOk

    if debugLogOn and not valid then
        debugLog(
            "Invalid target: %s | ownership=%s type=%s",
            target.object.id,
            tostring(ownershipOk),
            tostring(typeOk)
        )
    end

    return valid
end

-- Do our thing in the activate event
--- @param e activateEventData
local function activateCallback(e)
    local actTarget = e.target

    if debugLogOn then
        debugLog("Activate attempt: %s", actTarget.object.id)
    end

    if e.activator ~= tes3.player then
        if debugLogOn then debugLog("Rejected: not player") end
        return
    end

    if not tes3.mobilePlayer.isSneaking then
        if debugLogOn then debugLog("Rejected: not sneaking") end
        return
    end

    if playerDetected then
        if debugLogOn then debugLog("Rejected: player detected") end
        return
    end

    local delta = tes3.getSimulationTimestamp(false) - lastChecked
    if delta >= 2 then
        if debugLogOn then
            debugLog("Rejected: detection window expired (delta=%.2f)", delta)
        end
        return
    end

    if not isValidTarget(actTarget) then
        if debugLogOn then debugLog("Rejected: invalid target") end
        return
    end

    if actTarget.tempData.sneakySnatcher and actTarget.tempData.sneakySnatcher.accessed then
        if debugLogOn then debugLog("Rejected: already accessed") end
        return
    end

    if debugLogOn then
        debugLog("Activate success: %s", actTarget.object.id)
    end

    actTarget.tempData.sneakySnatcher = {}
    actTarget.tempData.sneakySnatcher.accessed = true
    table.insert(refs, actTarget)

    local skillGain = activateTypes[actTarget.object.objectType] or config.sneakSkillIncreaseObject

    if debugLogOn then
        debugLog("Skill gain: %d", skillGain)
    end

    tes3.mobilePlayer:exerciseSkill(tes3.skill.sneak, skillGain)
end
event.register(tes3.event.activate, activateCallback)

-- Track detection attempts
--- @param e detectSneakEventData
local function detectSneakCallback(e)
    if (e.target == tes3.mobilePlayer) and
        (config.npcs and e.detector.object.objectType == tes3.objectType.npc)
        or
        (config.creatures and e.detector.object.objectType == tes3.objectType.creature) then
        playerDetected = e.detector.isPlayerDetected and not e.detector.isPlayerHidden
        lastChecked = tes3.getSimulationTimestamp(false)

        if debugLogOn then
            debugLog(
                "Detection: detected=%s hidden=%s time=%.2f",
                tostring(e.detector.isPlayerDetected),
                tostring(e.detector.isPlayerHidden),
                lastChecked
            )
        end
    end
end
event.register(tes3.event.detectSneak, detectSneakCallback)

-- Clear flags and tracker on cell change
--- @param e cellChangedEventData
local function cellChangedCallback(e)
    if debugLogOn then
        debugLog("Cell changed: clearing %d refs", #refs)
    end

    for _, ref in ipairs(refs) do
        ref.tempData.sneakySnatcher = {}
    end
    refs = {}
end
event.register(tes3.event.cellChanged, cellChangedCallback)

-- Reset timestamp on game loaded
--- @param e loadedEventData
local function loadedCallback(e)
    lastChecked = 0
    if debugLogOn then
        debugLog("Game loaded: reset lastChecked")
    end
end
event.register(tes3.event.loaded, loadedCallback)

-- Registers MCM menu --
event.register(tes3.event.modConfigReady, function()
    if debugLogOn then
        debugLog("Registering MCM")
    end
    dofile("Data Files\\MWSE\\mods\\tew\\Sneaky Snatcher\\mcm.lua")
end)
