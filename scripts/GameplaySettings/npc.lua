local time = require("openmw_aux.time")
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')

local throttle_offensive_spellcasting = 0
local reqiure_stats_patch = true

local prev_conj = 0
local prev_alter = 0
local prev_illusin = 0
local prev_mystic = 0
local prev_restor = 0
local prev_destruction = 0

local prev_luck = 0
local prev_speed = 0
local prev_athletics = 0

local MOD_NAME = "ModernCombat"
local MOD_SETTINGS = MOD_NAME .. "Settings__"

local settings = storage.globalSection(MOD_SETTINGS)

time.runRepeatedly(function()
    local is_mod_disabled = settings:get("Disabled")
    local is_mod_enabled = not is_mod_disabled

    local luck = types.NPC.stats.attributes.luck(self)
    local speed = types.NPC.stats.attributes.speed(self)
    local athletics = types.NPC.stats.skills.athletics(self)
    local magicka = types.NPC.stats.dynamic.magicka(self)

    if is_mod_enabled and magicka.current / magicka.base < 0.25 and throttle_offensive_spellcasting == 0 then
        throttle_offensive_spellcasting = 8

        local conjuration = types.NPC.stats.skills.conjuration(self)
        local alteration = types.NPC.stats.skills.alteration(self)
        local illusion = types.NPC.stats.skills.illusion(self)
        local mysticism = types.NPC.stats.skills.mysticism(self)
        local restoration = types.NPC.stats.skills.restoration(self)
        local destruction = types.NPC.stats.skills.destruction(self)

        prev_conj = conjuration.base
        prev_alter = alteration.base
        prev_illusin = illusion.base
        prev_mystic = mysticism.base
        prev_restor = restoration.base
        prev_destruction = destruction.base
        prev_luck = luck.base

        conjuration.base = 1000
        alteration.base = 1000
        illusion.base = 1000
        mysticism.base = 1000
        restoration.base = 1000

        -- offensive skills suprresion
        destruction.base = -1000
        luck.base = -1000
    end

    if is_mod_enabled and throttle_offensive_spellcasting ~= 0 then
        magicka.current = magicka.base

        throttle_offensive_spellcasting = throttle_offensive_spellcasting - 2
        if throttle_offensive_spellcasting == 0 then
            restore_magick_skills()
            luck.base = prev_luck
        end
    elseif is_mod_enabled and magicka.current ~= magicka.base then
        magicka.current = magicka.current - magicka.base * 0.1
    end

    if is_mod_enabled and reqiure_stats_patch then
        reqiure_stats_patch = false

        prev_luck = luck.base
        if luck.base < 1000 then
            luck.base = 1000
        else
            prev_luck = 100
        end

        if athletics and athletics.base < 70 then
            prev_athletics = athletics.base
            athletics.base = 70
        end

        prev_speed = speed.speed
        if speed.base < 50 and not types.Creature.objectIsInstance(self) then
            speed.base = 50
        end
    elseif is_mod_disabled and not reqiure_stats_patch then
        reqiure_stats_patch = true

        if athletics then
            restore_magick_skills()
            athletics.base = prev_athletics
        end
        luck.base = prev_luck
        speed.base = prev_speed
    elseif is_mod_disabled and prev_luck == 1000 then
        luck.base = 100
    end
end, 2 * time.second)

function restore_magick_skills()
    local conjuration = types.NPC.stats.skills.conjuration(self)
    local alteration = types.NPC.stats.skills.alteration(self)
    local illusion = types.NPC.stats.skills.illusion(self)
    local mysticism = types.NPC.stats.skills.mysticism(self)
    local restoration = types.NPC.stats.skills.restoration(self)
    local destruction = types.NPC.stats.skills.destruction(self)
    local athletics = types.NPC.stats.skills.athletics(self)

    if prev_destruction ~= 0 or prev_restor ~= 0 then
        conjuration.base = prev_conj
        alteration.base = prev_alter
        illusion.base = prev_illusin
        mysticism.base = prev_mystic
        restoration.base = prev_restor
        destruction.base = prev_destruction
    end
end

return {
    engineHandlers = {
        onInactive = function()
            local luck = types.NPC.stats.attributes.luck(self)
            local speed = types.NPC.stats.attributes.speed(self)
            local athletics = types.NPC.stats.skills.athletics(self)
            if prev_luck ~= 0 then
                if athletics then
                    restore_magick_skills()
                    athletics.base = prev_athletics
                end
                luck.base = prev_luck
                speed.base = prev_speed
            end
        end
    }
}
