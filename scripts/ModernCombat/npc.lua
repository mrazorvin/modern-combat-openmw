local time = require("openmw_aux.time")
local self = require('openmw.self')
local core = require('openmw.core')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ai = require('openmw.interfaces').AI

-- @settings
local MOD_NAME = "ModernCombat"
local MOD_SETTINGS = MOD_NAME .. "Settings__"
local settings = storage.globalSection(MOD_SETTINGS)

-- @permanent
local os_conjuration = 0
local os_alteration = 0
local os_illusion = 0
local os_mysticism = 0
local os_restoration = 0
local os_destruction = 0

local os_longblade = 0
local os_shortblade = 0
local os_spear = 0
local os_axe = 0
local os_bluntweapon = 0
local os_marksman = 0

local os_athletics = 0

local oa_luck = 0
local oa_speed = 0

local is_actor_affected = false
local is_snapshot_created = false

-- @temporary
local is_creature = types.Creature.objectIsInstance(self)
local is_humanoid = not is_creature

local low_fatigue_timer = 0
local low_magicka_timer = 0
local prev_magicka = 0

function on_update(is_inactive)
    local target = ai.getActiveTarget('Combat') or ai.getActiveTarget('Pursue')
    local is_mod_disabled = settings:get("Disabled")
    local is_mod_enabled = not is_mod_disabled
    local is_script_active = not is_inactive
    local is_script_inactive = not is_script_active
    local is_in_combat = target ~= nil

    local skip_update = not is_actor_affected and (not is_in_combat or is_mod_disabled)
    if skip_update then
        return;
    else
        is_actor_affected = true
    end

    local skills = types.NPC.stats.skills
    local attributes = types.NPC.stats.attributes

    local s_conjuration = skills.conjuration(self)
    local s_alteration = skills.alteration(self)
    local s_illusion = skills.illusion(self)
    local s_mysticism = skills.mysticism(self)
    local s_restoration = skills.restoration(self)
    local s_destruction = skills.destruction(self)

    local s_longblade = skills.longblade(self)
    local s_shortblade = skills.shortblade(self)
    local s_spear = skills.spear(self)
    local s_axe = skills.axe(self)
    local s_bluntweapon = skills.bluntweapon(self)
    local s_marksman = skills.marksman(self)

    local s_athletics = skills.athletics(self)

    local a_speed = attributes.speed(self)
    local a_luck = attributes.luck(self)

    -- snapshot existed attributes
    if not is_snapshot_created then
        is_snapshot_created = true

        oa_speed = a_speed.base
        oa_luck = a_luck.base

        -- creature doesn't has attributes
        if is_creature then
            return
        end

        os_conjuration = s_conjuration.base
        os_alteration = s_alteration.base
        os_illusion = s_illusion.base
        os_mysticism = s_mysticism.base
        os_restoration = s_restoration.base
        os_destruction = s_destruction.base

        os_longblade = s_longblade.base
        os_shortblade = s_shortblade.base
        os_spear = s_spear.base
        os_axe = s_axe.base
        os_bluntweapon = s_bluntweapon.base
        os_marksman = s_marksman.base

        os_athletics = s_athletics.base

        return
    end

    -- restore existed attributes
    if is_snapshot_created and (is_mod_disabled or is_script_inactive or not is_in_combat) then
        is_snapshot_created = false
        is_actor_affected = false

        a_speed.base = oa_speed
        a_luck.base = oa_luck

        -- creature doesn't has attributes
        if is_creature then
            return
        end

        s_conjuration.base = os_conjuration
        s_alteration.base = os_alteration
        s_illusion.base = os_illusion
        s_mysticism.base = os_mysticism
        s_restoration.base = os_restoration
        s_destruction.base = os_destruction

        s_longblade.base = os_longblade
        s_shortblade.base = os_shortblade
        s_spear.base = os_spear
        s_axe.base = os_axe
        s_bluntweapon.base = os_bluntweapon
        s_marksman.base = os_marksman

        s_athletics.base = os_athletics

        return
    end

    -- @stats
    local d_magicka = types.NPC.stats.dynamic.magicka(self)
    local d_fatigue = types.NPC.stats.dynamic.fatigue(self)

    -- @modifiers
    local mod_destruction = 1

    -- @magicka
    local is_magick_user = d_magicka.current / d_magicka.base < 0.25
    local is_low_magick_active = low_magicka_timer ~= 0
    local is_low_magick_disabled = low_magicka_timer == 0
    if is_magick_user and is_low_magick_disabled then
        low_magicka_timer = 4
    end

    if is_low_magick_active then
        low_magicka_timer = low_magicka_timer - 1
    end

    if is_low_magick_active then
        mod_destruction = 0
        d_magicka.current = d_magicka.current + d_magicka.base * 0.25
    elseif d_magicka.current ~= prev_magicka then
        d_magicka.current = d_magicka.current - d_magicka.current * 0.1
    end
    prev_magicka = d_magicka.current

    -- @fatigue
    local is_low_fatigue = d_fatigue.current / d_fatigue.base < 0.05
    if is_low_fatigue then
        low_fatigue_timer = low_fatigue_timer + 1
    end
    if is_low_fatigue == 8 then
        low_fatigue_timer = 0
        d_fatigue.current = d_fatigue.base
    end

    -- @creature
    if is_creature then
        if a_luck.base < 1000 then
            a_luck.base = 1000
        end

        if a_speed.base < 10 then
            a_speed.base = 10
        end

        return;
    end

    -- @humanoid
    if s_athletics.base < 70 then
        s_athletics.base = 70
    end

    if a_speed.base < 50 then
        a_speed.base = 50
    end

    s_conjuration.base = os_conjuration + 100
    s_alteration.base = os_alteration + 100
    s_illusion.base = os_illusion + 100
    s_mysticism.base = os_mysticism + 100
    s_restoration.base = os_restoration + 100
    s_destruction.base = (os_destruction + 100) * mod_destruction

    s_longblade.base = os_longblade + 100
    s_shortblade.base = os_shortblade + 100
    s_spear.base = os_spear + 100
    s_axe.base = os_axe + 100
    s_bluntweapon.base = os_bluntweapon + 100
    s_marksman.base = os_marksman + 100
end

local last_update_time = core.getRealTime()
return {
    engineHandlers = {
        onInactive = function()
            on_update(true)
            core.sendGlobalEvent('ActorInactive', {self.object})
        end,
        onActive = function()
            on_update(false)
        end,
        onUpdate = function()
            local real_time = core.getRealTime()
            local seconds_passed_since_update = real_time - last_update_time

            if seconds_passed_since_update > 2 then
                on_update(false)
                last_update_time = real_time
            end
        end,
        onSave = function()
            return {
                os_conjuration = os_conjuration,
                os_alteration = os_alteration,
                os_illusion = os_illusion,
                os_mysticism = os_mysticism,
                os_restoration = os_restoration,
                os_destruction = os_destruction,

                os_longblade = os_longblade,
                os_shortblade = os_shortblade,
                os_spear = os_spear,
                os_axe = os_axe,
                os_bluntweapon = os_bluntweapon,
                os_marksman = os_marksman,

                os_athletics = os_athletics,

                oa_luck = oa_luck,
                oa_speed = oa_speed,

                is_actor_affected = is_actor_affected,
                is_snapshot_created = is_snapshot_created
            }
        end,
        onLoad = function(data)
            os_conjuration = data.os_conjuration
            os_alteration = data.os_alteration
            os_illusion = data.os_illusion
            os_mysticism = data.os_mysticism
            os_restoration = data.os_restoration
            os_destruction = data.os_destruction

            os_longblade = data.os_longblade
            os_shortblade = data.os_shortblade
            os_spear = data.os_spear
            os_axe = data.os_axe
            os_bluntweapon = data.os_bluntweapon
            os_marksman = data.os_marksman

            os_athletics = data.os_athletics

            oa_luck = data.oa_luck
            oa_speed = data.oa_speed

            is_actor_affected = data.is_actor_affected
            is_snapshot_created = data.is_snapshot_created
        end
    }
}
