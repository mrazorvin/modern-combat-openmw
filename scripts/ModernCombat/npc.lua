local time = require("openmw_aux.time")
local self = require('openmw.self')
local core = require('openmw.core')
local storage = require('openmw.storage')
local types = require('openmw.types')

local MOD_NAME = "ModernCombat"
local MOD_SETTINGS = MOD_NAME .. "Settings__"

local settings = storage.globalSection(MOD_SETTINGS)

local is_stats_adjusted = false
local is_magick_skill_adjusted = false

local origin_conjuration = 0
local origin_alteration = 0
local origin_illusion = 0
local origin_mystic = 0
local origin_restoration = 0
local origin_destruction = 0
local origin_athletics = 0

local origin_luck = 0
local origin_speed = 0

local is_creature = types.Creature.objectIsInstance(self)
local is_humanoid = not is_creature

local throttle_offensive_spellcasting_timer = 0

time.runRepeatedly(function()
    local is_mod_disabled = settings:get("Disabled")
    local is_mod_enabled = not is_mod_disabled

    local magicka = types.NPC.stats.dynamic.magicka(self)

    local is_magick_user = magicka.current / magicka.base < 0.25
    local is_not_started = throttle_offensive_spellcasting_timer == 0
    if is_mod_enabled and is_magick_user and is_not_started then
        throttle_offensive_spellcasting_timer = 8
        adjust_magick_skills()
    end

    if is_mod_enabled and throttle_offensive_spellcasting_timer ~= 0 then
        magicka.current = magicka.base

        throttle_offensive_spellcasting_timer = throttle_offensive_spellcasting_timer - 2
        if throttle_offensive_spellcasting_timer == 0 then
            restore_magick_skills()
        end
    elseif is_mod_enabled and magicka.current ~= magicka.base then
        magicka.current = magicka.current - magicka.current * 0.1
    end

    if is_mod_enabled and not is_stats_adjusted then
        adjust_stats()
    elseif is_mod_disabled and is_stats_adjusted then
        restore_stats()
    end
end, 2 * time.second)

function adjust_stats()
    if is_stats_adjusted then
        return;
    else
        is_stats_adjusted = true
    end

    local luck = types.NPC.stats.attributes.luck(self)
    origin_luck = luck.base
    if luck.base < 1000 then
        luck.base = 1000
    end

    local speed = types.NPC.stats.attributes.speed(self)
    if is_humanoid then
        local athletics = types.NPC.stats.skills.athletics(self)

        origin_athletics = athletics.base
        if athletics.base < 70 then
            athletics.base = 70
        end

        origin_speed = speed.base
        if speed.base < 50 then
            speed.base = 50
        end
    elseif is_creature then
        origin_speed = speed.base
        if speed.base < 10 then
            speed.base = 10
        end
    end
end

function restore_stats()
    if not is_stats_adjusted then
        return;
    else
        is_stats_adjusted = false
    end

    local is_humanoid = not types.Creature.objectIsInstance(self)
    if is_humanoid then
        local athletics = types.NPC.stats.skills.athletics(self)
        athletics.base = origin_athletics
        restore_magick_skills()
    end

    local speed = types.NPC.stats.attributes.speed(self)
    local luck = types.NPC.stats.attributes.luck(self)

    luck.base = origin_luck
    speed.base = origin_speed
end

function restore_magick_skills()
    if not is_magick_skill_adjusted then
        return
    else
        is_magick_skill_adjusted = false
    end

    local conjuration = types.NPC.stats.skills.conjuration(self)
    local alteration = types.NPC.stats.skills.alteration(self)
    local illusion = types.NPC.stats.skills.illusion(self)
    local mysticism = types.NPC.stats.skills.mysticism(self)
    local restoration = types.NPC.stats.skills.restoration(self)
    local destruction = types.NPC.stats.skills.destruction(self)
    local athletics = types.NPC.stats.skills.athletics(self)

    conjuration.base = origin_conjuration
    alteration.base = origin_alteration
    illusion.base = origin_illusion
    mysticism.base = origin_mystic
    restoration.base = origin_restoration
    destruction.base = origin_destruction
end

function adjust_magick_skills()
    if is_magick_skill_adjusted then
        return
    else
        is_magick_skill_adjusted = true
    end

    local conjuration = types.NPC.stats.skills.conjuration(self)
    local alteration = types.NPC.stats.skills.alteration(self)
    local illusion = types.NPC.stats.skills.illusion(self)
    local mysticism = types.NPC.stats.skills.mysticism(self)
    local restoration = types.NPC.stats.skills.restoration(self)
    local destruction = types.NPC.stats.skills.destruction(self)

    origin_conjuration = conjuration.base
    origin_alteration = alteration.base
    origin_illusion = illusion.base
    origin_mystic = mysticism.base
    origin_restoration = restoration.base
    origin_destruction = destruction.base

    conjuration.base = 1000
    alteration.base = 1000
    illusion.base = 1000
    mysticism.base = 1000
    restoration.base = 1000

    -- offensive skills suprresion
    destruction.base = -1000
end

return {
    engineHandlers = {
        onInactive = function()
            core.sendGlobalEvent('ActorInactive', {self.object})
            restore_stats()
        end,
        onActive = function()
            adjust_stats()
        end,
        onSave = function()
            return {
                is_stats_adjusted = is_stats_adjusted,
                is_magick_skill_adjusted = is_magick_skill_adjusted,

                origin_conjuration = origin_conjuration,
                origin_alteration = origin_alteration,
                origin_illusion = origin_illusion,
                origin_mystic = origin_mystic,
                origin_restoration = origin_restoration,
                origin_destruction = origin_destruction,
                origin_athletics = origin_athletics,

                origin_luck = origin_luck,
                origin_speed = origin_speed
            }
        end,
        onLoad = function(data)
            is_stats_adjusted = data.is_stats_adjusted
            is_magick_skill_adjusted = data.is_magick_skill_adjusted

            origin_conjuration = data.origin_conjuration
            origin_alteration = data.origin_alteration
            origin_illusion = data.origin_illusion
            origin_mystic = data.origin_mystic
            origin_restoration = data.origin_restoration
            origin_destruction = data.origin_destruction
            origin_athletics = data.origin_athletics

            origin_luck = data.origin_luck
            origin_speed = data.origin_speed
        end
    }
}
