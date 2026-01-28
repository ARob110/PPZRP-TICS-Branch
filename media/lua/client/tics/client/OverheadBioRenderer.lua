local BioMeta = require('tics/client/BioSync')

local OverheadBioRenderer = {}

-- Configuration
local hoverMaxDistSq = 1 -- Max squared distance for hover detection (like WRC, 1.5 tiles)
-- local maxDistSq = 100.0 -- Keep this if you want a fallback proximity view, otherwise remove
local bioFont = UIFont.Medium -- Or UIFont.Tiny
local bioColor = {r=1.0, g=1.0, b=1.0, a=1.0} -- White, slightly transparent
local nameOffsetY = 128 -- Base offset Y above player head (adjust based on name height/zoom)

-- State to manage UI elements (like WRC) - We'll use this to cache text width mainly
OverheadBioRenderer.OverheadElements = OverheadBioRenderer.OverheadElements or {} -- Key: onlineID, Value: {seen=true/false, textWidth=number, bioText=string}

-- Re-using the distance function, it's generic enough
function OverheadBioRenderer.GetDistanceSq(x1, y1, player)
    local x2 = player:getX()
    local y2 = player:getY()
    local dx = x1 - x2
    local dy = y1 - y2
    return dx * dx + dy * dy
end

function OverheadBioRenderer.RenderBios()
    if not isClient() then return end

    local player = getPlayer()
    if not player then return end

    local zoom = getCore():getZoom(0)
    local tm = getTextManager()

    -- Cache my admin status once per frame (optimization)
    local myAccess = player:getAccessLevel()
    local canSeeInvis = (myAccess == "Admin" or myAccess == "Moderator" or myAccess == "Overseer" or myAccess == "GM")

    -- Mark all current elements as not seen initially for this frame
    -- (Used for cache tracking if you ever wanted to debug, but harmless to keep)
    for id, ele in pairs(OverheadBioRenderer.OverheadElements) do
        ele.seen = false
    end

    local mouseX = getMouseX()
    local mouseY = getMouseY()
    local mouseWorldX = screenToIsoX(0, mouseX, mouseY, player:getZ())
    local mouseWorldY = screenToIsoY(0, mouseX, mouseY, player:getZ())
    local worldZ = player:getZ()

    local players = getOnlinePlayers()

    for i = 0, players:size() - 1 do
        local otherPlayer = players:get(i)

        -- Invisibility Check
        local skip = false
        if otherPlayer:isInvisible() and not canSeeInvis then
            skip = true
        end

        if not skip then
            local key = otherPlayer:getUsername()
            -- Calculate distance from MOUSE cursor to player
            local distSq = OverheadBioRenderer.GetDistanceSq(mouseWorldX, mouseWorldY, otherPlayer)

            -- Hover Check
            if worldZ == otherPlayer:getZ() and distSq <= hoverMaxDistSq then
                local bio = BioMeta.Get(otherPlayer)

                if bio then
                    local px = otherPlayer:getX()
                    local py = otherPlayer:getY()
                    local pz = otherPlayer:getZ()

                    local sx = isoToScreenX(0, px, py, pz)
                    local sy = isoToScreenY(0, px, py, pz)
                    local yOffset = (nameOffsetY / zoom)

                    local currentElement = OverheadBioRenderer.OverheadElements[key]
                    local textWidth

                    -- Recalculate width only if bio changed or new player
                    if not currentElement or currentElement.bioText ~= bio then
                        textWidth = tm:MeasureStringX(bioFont, bio)
                        OverheadBioRenderer.OverheadElements[key] = { seen = true, textWidth = textWidth, bioText = bio }
                    else
                        textWidth = currentElement.textWidth
                        currentElement.seen = true
                    end

                    -- Draw immediate (no cleanup needed)
                    tm:DrawString(bioFont, sx - (textWidth / 2), sy - yOffset, bio, bioColor.r, bioColor.g, bioColor.b, bioColor.a)
                    break
                end
            end
        end
    end
end

if not OverheadBioRenderer._hooked then
    Events.OnPreUIDraw.Add(OverheadBioRenderer.RenderBios)
    OverheadBioRenderer._hooked = true
end

return OverheadBioRenderer