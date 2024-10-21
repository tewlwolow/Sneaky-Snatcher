local config = require("tew.Sneaky Snatcher.config")

---@type boolean
local playerDetected

---@type number
local lastChecked = 0

---@type boolean
local accessed = true

---@type tes3reference[]
local refs = {}

--- @param e activateEventData
local function activateCallback(e)
    if (e.activator == tes3.player) and
        (not playerDetected) and
        (tes3.getSimulationTimestamp(false) - (lastChecked) < 2) and
        (tes3.mobilePlayer.isSneaking) and
        (e.target.object.objectType == tes3.objectType.container and not e.target.lockNode) and
        not tes3.hasOwnershipAccess { target = e.target } and
        ((not e.target.tempData.sneakySnatcher) or
            (e.target.tempData.sneakySnatcher and not e.target.tempData.sneakySnatcher.accessed)) then
        tes3.messageBox { message = "First time accessed, progressing sneak..." }
        accessed = true
        e.target.tempData.sneakySnatcher = {}
        e.target.tempData.sneakySnatcher.accessed = accessed
        table.insert(refs, e.target)
        tes3.mobilePlayer:exerciseSkill(tes3.skill.sneak, config.sneakSkillIncrease)
    end
end
event.register(tes3.event.activate, activateCallback)

--- @param e detectSneakEventData
local function detectSneakCallback(e)
    if (e.target == tes3.mobilePlayer) and (e.detector.object.objectType == tes3.objectType.npc) then
        playerDetected = e.detector.isPlayerDetected and not e.detector.isPlayerHidden
        lastChecked = tes3.getSimulationTimestamp(false)
    end
end
event.register(tes3.event.detectSneak, detectSneakCallback)

-- Registers MCM menu --
event.register(tes3.event.modConfigReady, function()
    dofile("Data Files\\MWSE\\mods\\tew\\Sneaky Snatcher\\mcm.lua")
end)

--- @param e cellChangedEventData
local function cellChangedCallback(e)
    for _, ref in ipairs(refs) do
        ref.tempData.sneakySnatcher = {}
    end
    refs = {}
end
event.register(tes3.event.cellChanged, cellChangedCallback)

--- @param e loadedEventData
local function loadedCallback(e)
    lastChecked = 0
end
event.register(tes3.event.loaded, loadedCallback)
