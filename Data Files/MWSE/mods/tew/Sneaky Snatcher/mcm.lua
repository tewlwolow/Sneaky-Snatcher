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
    headerImagePath = "\\Textures\\tew\\Sneaky Snatcher\\logo.dds",
}

local mainPage = template:createPage { label = "Main Settings", noScroll = true }

mainPage:createCategory {
    label = metadata.package.name .. " " .. metadata.package.version .. " by tewlwolow.\n"
        .. metadata.package.description .. "\n\nSettings:",
}

-- Existing ownership / skill sliders...
mainPage:createYesNoButton {
    label = string.format(
        "Cover only objects player has no ownership for?\nDefault - %s",
        defaults.useOwnership and "Yes" or "No"
    ),
    variable = registerVariable("useOwnership"),
}

mainPage:createSlider {
    label = string.format(
        "Controls Sneak skill increase (progress percentage) on a successful snatch for containers.\nDefault - %s\nSkill increase for containers",
        defaults.sneakSkillIncreaseContainer
    ),
    min = 0,
    max = 100,
    step = 1,
    jump = 10,
    variable = registerVariable("sneakSkillIncreaseContainer"),
}

mainPage:createSlider {
    label = string.format(
        "Controls Sneak skill increase (progress percentage) on a successful snatch for doors.\nDefault - %s\nSkill increase for doors",
        defaults.sneakSkillIncreaseDoor
    ),
    min = 0,
    max = 100,
    step = 1,
    jump = 10,
    variable = registerVariable("sneakSkillIncreaseDoor"),
}

mainPage:createSlider {
    label = string.format(
        "Controls Sneak skill increase (progress percentage) on a successful snatch for all other objects.\nDefault - %s\nSkill increase for other objects",
        defaults.sneakSkillIncreaseObject
    ),
    min = 0,
    max = 100,
    step = 1,
    jump = 10,
    variable = registerVariable("sneakSkillIncreaseObject"),
}

-- Detection settings
mainPage:createCategory { label = "Detection Settings" }

mainPage:createYesNoButton {
    label = string.format(
        "Allow NPCs to count for distance checks?\nDefault - %s",
        defaults.npcs and "Yes" or "No"
    ),
    description = "If enabled, NPCs will count toward sneak detection checks.",
    variable = registerVariable("npcs"),
}

mainPage:createYesNoButton {
    label = string.format(
        "Allow creatures to count for distance checks?\nDefault - %s",
        defaults.creatures and "Yes" or "No"
    ),
    description = "If enabled, creatures will count toward sneak detection checks.",
    variable = registerVariable("creatures"),
}

-- Maximum detection distances
mainPage:createSlider {
    label = string.format(
        "Maximum detection distance for NPCs (units).\nDefault - %s",
        defaults.npcDetectionDistance
    ),
    min = 256,
    max = 8192,
    step = 128,
    jump = 512,
    variable = registerVariable("npcDetectionDistance"),
}

mainPage:createSlider {
    label = string.format(
        "Maximum detection distance for creatures (units).\nDefault - %s",
        defaults.creatureDetectionDistance
    ),
    min = 256,
    max = 8192,
    step = 128,
    jump = 512,
    variable = registerVariable("creatureDetectionDistance"),
}

-- Distance-based skill multipliers
mainPage:createCategory { label = "Distance Skill Multipliers" }

mainPage:createSlider {
    label = string.format(
        "Multiplier for very close detectors (<=25%% of max distance)\nDefault - %.2f",
        defaults.multiplierVeryClose
    ),
    min = 1.0,
    max = 3.0,
    step = 0.05,
    jump = 0.1,
    variable = registerVariable("multiplierVeryClose"),
}

mainPage:createSlider {
    label = string.format(
        "Multiplier for close detectors (<=50%% of max distance)\nDefault - %.2f",
        defaults.multiplierClose
    ),
    min = 1.0,
    max = 2.0,
    step = 0.05,
    jump = 0.1,
    variable = registerVariable("multiplierClose"),
}

mainPage:createSlider {
    label = string.format(
        "Multiplier for default/far detectors (>50%% of max distance)\nDefault - %.2f",
        defaults.multiplierDefault
    ),
    min = 0.5,
    max = 1.0,
    step = 0.05,
    jump = 0.05,
    variable = registerVariable("multiplierDefault"),
}

-- Debug mode
mainPage:createYesNoButton {
    label = "Enable debug mode?",
    description = "Activates detailed logging for troubleshooting. Requires restart.",
    variable = registerVariable("debugLogOn"),
    restartRequired = true,
}

template:saveOnClose(configPath, config)
mwse.mcm.register(template)
