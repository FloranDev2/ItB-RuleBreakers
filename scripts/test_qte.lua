--[[
1073741906: UP ▲
1073741905: DOWN ▼
1073741904: LEFT ◄
1073741903: RIGHT ►
]]

local handler = function(scancode)
    LOGF("Key with scancode %s is being released and processed", scancode)
    LOG("-------- type: "..type(scancode))

    if scancode     == 1073741906 then --UP
        LOG(" -> Up!")
    elseif scancode == 1073741905 then --DOWN
        LOG(" -> Down!")
    elseif scancode == 1073741904 then --LEFT
        LOG(" -> Left!")
    elseif scancode == 1073741903 then --RIGHT
        LOG(" -> Right!")
    end
end

modApi.events.onKeyReleased:subscribe(handler)

--Interesting stuff:
--https://github.com/itb-community/ITB-ModUtils/blob/6de99f3ad720f879601bc446a74a8f92e35da47a/scripts/pawn.lua#L132
--[[
function pawn:getHighlighted()
    return Board:GetPawn(mouseTile())
end
]]

--it comes from here:
--https://github.com/itb-community/ITB-ModLoader/blob/cf3c15dcbc905ba679bd6c1c2dc6a0b871c694e7/scripts/mod_loader/modapi/global.lua#L129
