return {
    -- Sneak skill increases (progress percentage)
    sneakSkillIncreaseContainer = 2,
    sneakSkillIncreaseDoor = 3,
    sneakSkillIncreaseObject = 1,

    -- Ownership option
    useOwnership = false,

    -- Debug
    debugLogOn = false,

    -- Multiple gains options
    allowMultipleActivationGains = false, -- Activation events
    allowMultipleLockpickGains = true,    -- Lockpick events

    -- Detection settings
    npcs = true,
    creatures = true,
    npcDetectionDistance = 512,      -- Max distance for NPCs to detect player
    creatureDetectionDistance = 512, -- Max distance for creatures to detect player

    -- Distance multipliers
    multiplierVeryClose = 1.5,
    multiplierClose = 1.25,
    multiplierDefault = 1.0,

    -- Distance scaling exponent
    distanceExponent = 1.5, -- Higher values drop skill faster with distance (vertical/far)
}
