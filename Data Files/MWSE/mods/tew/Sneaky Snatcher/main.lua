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

        local formattedMessage
        if select("#", ...) > 0 then
            formattedMessage = aligned .. " -- " .. string.format(message, ...)
        else
            formattedMessage = aligned .. " -- " .. tostring(message)
        end

        -- Log to MWSE
        mwse.log(formattedMessage)
        -- Show in-game message box
        tes3.messageBox(formattedMessage)
    end
end

-- A table to track references
---@type tes3reference[]
local refs = {}

--- Skill increase for different object types
local activateTypes = {
    [tes3.objectType.container] = config.sneakSkillIncreaseContainer,
    [tes3.objectType.door] = config.sneakSkillIncreaseDoor,
}

--- Determine if we have a valid target for our action
--- @param target tes3reference
local function isValidTarget(target)
    local ownershipOk = (config.useOwnership and tes3.hasOwnershipAccess { target = target } or not config.useOwnership)
    local typeOk = ((target.object.objectType == tes3.objectType.container and not target.lockNode) or (not target.context))

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

--- Get skill multiplier based on distance ratio
--- @param distance number
--- @param maxDistance number
local function getDistanceMultiplier(distance, maxDistance)
    local ratio = distance / maxDistance
    if ratio <= 0.25 then
        return config.multiplierVeryClose or 1.5
    elseif ratio <= 0.5 then
        return config.multiplierClose or 1.25
    else
        return config.multiplierDefault or 1.0
    end
end

--- Find the closest detector in the player’s current cell
local function findClosestDetector()
    local closestDistance = nil
    local maxDistance = 0
    local playerPos = tes3.player.position
    local cell = tes3.getPlayerCell()

    for ref in cell:iterateReferences() do
        local objType = ref.object.objectType
        local isNpc = objType == tes3.objectType.npc and config.npcs
        local isCreature = objType == tes3.objectType.creature and config.creatures

        if isNpc or isCreature then
            local dx = ref.position.x - playerPos.x
            local dy = ref.position.y - playerPos.y
            local dz = ref.position.z - playerPos.z
            local distance = math.sqrt(dx * dx + dy * dy + dz * dz)

            local detectorMax = isNpc and (config.npcDetectionDistance or 4096)
                or isCreature and (config.creatureDetectionDistance or 2048)

            if distance <= detectorMax then
                if not closestDistance or distance < closestDistance then
                    closestDistance = distance
                    maxDistance = detectorMax
                end
            end
        end
    end

    return closestDistance, maxDistance
end

-- UI workaround for player detection
local function isPlayerDetected()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if not menu then return false end
    local child = menu:findChild(tes3ui.registerID("MenuMulti_sneak_icon"))
    return child and not child.visible
end

-- Activation logic
--- @param e activateEventData
local function activateCallback(e)
    local actTarget = e.target
    if debugLogOn then debugLog("Activate attempt: %s", actTarget.object.id) end

    if e.activator ~= tes3.player then
        if debugLogOn then debugLog("Rejected: not player") end
        return
    end

    if not tes3.mobilePlayer.isSneaking then
        if debugLogOn then debugLog("Rejected: not sneaking") end
        return
    end

    if isPlayerDetected() then
        if debugLogOn then debugLog("Rejected: player detected") end
        return
    end

    if not isValidTarget(actTarget) then
        if debugLogOn then debugLog("Rejected: invalid target") end
        return
    end

    -- Optional multiple activation gains
    local accessed = actTarget.tempData.sneakySnatcher and actTarget.tempData.sneakySnatcher.accessed
    if accessed and not config.allowMultipleActivationGains then
        if debugLogOn then debugLog("Rejected: already accessed and multiple activation gains disabled") end
        return
    end

    local closestDistance, maxDistance = findClosestDetector()
    closestDistance = closestDistance or 0
    maxDistance = maxDistance or 1

    local baseSkillGain = activateTypes[actTarget.object.objectType] or config.sneakSkillIncreaseObject
    local multiplier = getDistanceMultiplier(closestDistance, maxDistance)
    local scaledGain = math.ceil(baseSkillGain * multiplier * (1 - (closestDistance / maxDistance)))

    if debugLogOn then
        debugLog(
            "Activate success: %s | closest detector distance=%.2f / max=%.2f | base=%d, multiplier=%.2f, scaled=%d",
            actTarget.object.id,
            closestDistance,
            maxDistance,
            baseSkillGain,
            multiplier,
            scaledGain
        )
    end

    actTarget.tempData.sneakySnatcher = actTarget.tempData.sneakySnatcher or {}
    actTarget.tempData.sneakySnatcher.accessed = true

    table.insert(refs, actTarget)
    tes3.mobilePlayer:exerciseSkill(tes3.skill.sneak, scaledGain)
end
event.register(tes3.event.activate, activateCallback)

-- Lockpick logic
--- @param e lockPickEventData
local function lockPickCallback(e)
    if e.picker ~= tes3.player then return end
    if not e.lockPresent then return end

    local ref = e.reference
    if not ref then return end

    if isPlayerDetected() then
        if debugLogOn then debugLog("Rejected: player detected during lockpick") end
        return
    end

    local lockpicked = ref.tempData.sneakySnatcher and ref.tempData.sneakySnatcher.lockpicked
    if lockpicked and not config.allowMultipleLockpickGains then
        if debugLogOn then debugLog("Rejected: lock already picked and multiple lockpick gains disabled") end
        return
    end

    local closestDistance, maxDistance = findClosestDetector()
    closestDistance = closestDistance or 0
    maxDistance = maxDistance or 1

    local baseSkillGain = config.sneakSkillIncreaseObject or 1
    local multiplier = getDistanceMultiplier(closestDistance, maxDistance)
    local scaledGain = math.ceil(baseSkillGain * multiplier * (1 - (closestDistance / maxDistance)))

    if debugLogOn then
        debugLog(
            "Lockpick sneak gain: %s | distance=%.2f / max=%.2f | base=%d, multiplier=%.2f, scaled=%d",
            ref.object.id,
            closestDistance,
            maxDistance,
            baseSkillGain,
            multiplier,
            scaledGain
        )
    end

    ref.tempData.sneakySnatcher = ref.tempData.sneakySnatcher or {}
    ref.tempData.sneakySnatcher.lockpicked = true

    tes3.mobilePlayer:exerciseSkill(tes3.skill.sneak, scaledGain)
end
event.register(tes3.event.lockPick, lockPickCallback)

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
    if debugLogOn then
        debugLog("Game loaded")
    end
end
event.register(tes3.event.loaded, loadedCallback)

-- Registers MCM menu
event.register(tes3.event.modConfigReady, function()
    if debugLogOn then debugLog("Registering MCM") end
    dofile("Data Files\\MWSE\\mods\\tew\\Sneaky Snatcher\\mcm.lua")
end)
