local time = require("openmw_aux.time")
local self = require('openmw.self')
local types = require('openmw.types')

local throttle_offensive_spellcasting = 0
local reqiure_stats_patch = true 

local prev_conj = 0
local prev_alter = 0
local prev_illusin = 0
local prev_mystic = 0
local prev_restor = 0
local prev_destruction = 0

time.runRepeatedly(
  function()
    local luck = types.NPC.stats.attributes.luck(self)
    local speed = types.NPC.stats.attributes.speed(self)
    local athletics = types.NPC.stats.skills.athletics(self)
    local magicka = types.NPC.stats.dynamic.magicka(self)

    if magicka.current / magicka.base < 0.25 and throttle_offensive_spellcasting == 0 then 
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

      conjuration.base = 1000
      alteration.base = 1000
      illusion.base = 1000 
      mysticism.base = 1000
      restoration.base = 1000 

      destruction.base = -1000
      luck.base = -1000
    end

    if throttle_offensive_spellcasting ~= 0 then 
      magicka.current = magicka.base
      
      throttle_offensive_spellcasting = throttle_offensive_spellcasting - 2

      if throttle_offensive_spellcasting == 0 then
        local conjuration = types.NPC.stats.skills.conjuration(self)
        local alteration = types.NPC.stats.skills.alteration(self)
        local illusion = types.NPC.stats.skills.illusion(self)
        local mysticism = types.NPC.stats.skills.mysticism(self)
        local restoration = types.NPC.stats.skills.restoration(self)
        local destruction = types.NPC.stats.skills.destruction(self)

        conjuration.base = prev_conj
        alteration.base = prev_alter
        illusion.base = prev_illusin 
        mysticism.base = prev_mystic
        restoration.base = prev_restor 
        destruction.base = prev_destruction
        luck.base = 1000
      end 
    elseif magicka.current ~= magicka.base then
      magicka.current = magicka.current - magicka.base * 0.1
    end
    
    if reqiure_stats_patch then 
      if luck.base < 1000 then
        luck.base = 1000
      end

      if athletics and athletics.base < 70 then
        athletics.base = 70
      end

      if speed.base < 50 and not types.Creature.objectIsInstance(self) then 
        speed.base = 50
      end

      reqiure_stats_patch = false
    end 
  end, 
  2 * time.second
)


return {
  engineHandlers = {},
}
