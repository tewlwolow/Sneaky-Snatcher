local configPath = "Sneaky Snatcher"
local config = require("tew.Sneaky Snatcher.config")
local defaults = require("tew.Sneaky Snatcher.defaults")
local metadata = toml.loadMetadata("Sneaky Snatcher")

local function registerVariable(id)
    return mwse.mcm.createTableVariable {
        id = id,
        table = config,
    }
end

local template = mwse.mcm.createTemplate {
    name = metadata.package.name,
    headerImagePath = "\\Textures\\tew\\Sneaky Snatcher\\logo.dds" }

local mainPage = template:createPage { label = "Main Settings", noScroll = true }
mainPage:createCategory {
    label = metadata.package.name .. " " .. metadata.package.version .. " by tewlwolow.\n" .. metadata.package.description .. "\n\nSettings:",
}

mainPage:createSlider {
    label = string.format("Controls sneak skill increase on a successful snatch.\nDefault - %s\nSkill increase", defaults.sneakSkillIncrease),
    min = 0,
    max = 100,
    step = 1,
    jump = 10,
    variable = registerVariable("sneakSkillIncrease"),
}

template.onClose = function()
    mwse.saveConfig(configPath, config)
    dofile("Data Files\\MWSE\\mods\\tew\\Sneaky Snatcher\\components\\events.lua")
end
mwse.mcm.register(template)
