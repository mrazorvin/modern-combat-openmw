local types = require("openmw.types")

local function onActorActive(actor)
  if actor and (actor.type == types.NPC or actor.type == types.Creature) then
    actor:addScript("scripts/GameplaySettings/npc.lua")
  end
end

return {
    engineHandlers = {
        onActorActive = onActorActive
    },
}
