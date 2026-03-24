local config = require("tew.Sneaky Snatcher.config")

local metadata = toml.loadMetadata("Sneaky Snatcher")
local version = metadata.package.version
local debugLogOn = true

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
    local valid = (
        (
            config.useOwnership and tes3.hasOwnershipAccess { target = target } or not config.useOwnership
        ) and
        (
            (target.object.objectType == tes3.objectType.container and not target.lockNode) or
            (not target.context)
        )
    )

    debugLog("isValidTarget: %s -> %s", target.object.id, tostring(valid))
    return valid
end

-- Do our thing in the activate event
--- @param e activateEventData
local function activateCallback(e)
    local actTarget = e.target

    debugLog("Activate attempt: %s", actTarget.object.id)

    if (e.activator == tes3.player) and
        (tes3.mobilePlayer.isSneaking and not playerDetected) and
        (tes3.getSimulationTimestamp(false) - (lastChecked) < 2) and
        (isValidTarget(actTarget)) and
        (
            (not actTarget.tempData.sneakySnatcher) or
            (actTarget.tempData.sneakySnatcher and not actTarget.tempData.sneakySnatcher.accessed)
        ) then
        debugLog("Activate success: %s", actTarget.object.id)

        actTarget.tempData.sneakySnatcher = {}
        actTarget.tempData.sneakySnatcher.accessed = true
        table.insert(refs, actTarget)

        local skillGain = activateTypes[actTarget.object.objectType] or config.sneakSkillIncreaseObject
        debugLog("Skill gain: %d", skillGain)

        tes3.mobilePlayer:exerciseSkill(tes3.skill.sneak, skillGain)
    else
        debugLog("Activate rejected: %s", actTarget.object.id)
    end
end
event.register(tes3.event.activate, activateCallback)

-- Track detection attempts
--- @param e detectSneakEventData
local function detectSneakCallback(e)
    if (e.target == tes3.mobilePlayer) and (e.detector.object.objectType == tes3.objectType.npc) then
        playerDetected = e.detector.isPlayerDetected and not e.detector.isPlayerHidden
        lastChecked = tes3.getSimulationTimestamp(false)

        debugLog(
            "Detection: detected=%s hidden=%s time=%.2f",
            tostring(e.detector.isPlayerDetected),
            tostring(e.detector.isPlayerHidden),
            lastChecked
        )
    end
end
event.register(tes3.event.detectSneak, detectSneakCallback)

-- Clear flags and tracker on cell change
--- @param e cellChangedEventData
local function cellChangedCallback(e)
    debugLog("Cell changed: clearing %d refs", #refs)

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
    debugLog("Game loaded: reset lastChecked")
end
event.register(tes3.event.loaded, loadedCallback)

-- Registers MCM menu --
event.register(tes3.event.modConfigReady, function()
    dofile("Data Files\\MWSE\\mods\\tew\\Sneaky Snatcher\\mcm.lua")
end)
