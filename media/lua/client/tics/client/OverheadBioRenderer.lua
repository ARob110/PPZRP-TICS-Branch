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

    -- Mark all current elements as not seen initially for this frame
    -- We only track *potential* elements to avoid recalculating width constantly
    -- The actual drawing depends solely on the hover check this frame
    for id, ele in pairs(OverheadBioRenderer.OverheadElements) do
        ele.seen = false
    end

    -- Get current mouse position and convert to world coordinates at player's Z
    local mouseX = getMouseX()
    local mouseY = getMouseY()
    local mouseWorldX = screenToIsoX(0, mouseX, mouseY, player:getZ())
    local mouseWorldY = screenToIsoY(0, mouseX, mouseY, player:getZ())
    local worldZ = player:getZ() -- The Z level we are checking against

    local players = getOnlinePlayers()
    local hoveredPlayerID = nil -- Keep track if we actually hovered over someone

    for i = 0, players:size() - 1 do
        local otherPlayer = players:get(i)
        local key = otherPlayer:getUsername()

        -- Calculate distance from MOUSE cursor's world position to the other player
        local distSq = OverheadBioRenderer.GetDistanceSq(mouseWorldX, mouseWorldY, otherPlayer)

        -- *** HOVER CHECK ***
        -- Check if mouse is close enough to this player AND they are on the same Z level
        -- Optional: Add WRC.CanSeePlayer check if you have access to it and want line-of-sight
        if worldZ == otherPlayer:getZ() and distSq <= hoverMaxDistSq --[[and WRC and WRC.CanSeePlayer and WRC.CanSeePlayer(otherPlayer, true, 20)]] then
            local bio = BioMeta.Get(otherPlayer:getUsername())

            if bio then -- Only render if they have a bio set and are hovered
                hoveredPlayerID = onlineID -- Mark this player as the one being hovered

                local px = otherPlayer:getX()
                local py = otherPlayer:getY()
                local pz = otherPlayer:getZ()

                -- Calculate screen position (base above head)
                local sx = isoToScreenX(0, px, py, pz)
                local sy = isoToScreenY(0, px, py, pz)

                -- Adjust Y position to be above the name
                local yOffset = (nameOffsetY / zoom)
                -- Optional fine-tuning (like WRC) if needed:
                -- yOffset = yOffset - (3*zoom)

                local currentElement = OverheadBioRenderer.OverheadElements[key]
                local textWidth

                -- Calculate text width if needed (only if text changed or first time)
                if not currentElement or currentElement.bioText ~= bio then
                    textWidth = tm:MeasureStringX(bioFont, bio)
                    -- Update or create the cache entry
                    OverheadBioRenderer.OverheadElements[key] = { seen = true,
                                                                  textWidth = textWidth,
                                                                  bioText   = bio }
                else
                    textWidth = currentElement.textWidth -- Use cached width
                    currentElement.seen = true -- Mark as seen *in the cache* for this frame
                end

                -- Draw the text - Centered horizontally
                tm:DrawString(bioFont, sx - (textWidth / 2), sy - yOffset, bio, bioColor.r, bioColor.g, bioColor.b, bioColor.a)

                -- Since we found a hovered player, we can potentially break early
                -- if we only ever want to show ONE bio at a time (the topmost one).
                -- If multiple players could be under the cursor radius, remove the break.
                break
            end
        end
    end

    -- Clean up cache entries for players who weren't hovered *this frame*
    -- Note: This cleanup is mostly for the cache. Since we aren't using ISUIElements,
    -- nothing needs to be explicitly removed from a UI manager. The text simply
    -- won't be drawn next frame if the hover condition isn't met.
    local idsToRemove = {}
    for id, ele in pairs(OverheadBioRenderer.OverheadElements) do
        -- If an element was cached but *not* seen (hovered) this frame,
        -- we can potentially remove it from the cache to save memory,
        -- though it's not strictly necessary unless the cache grows huge.
        -- A simpler approach is to just let the cache keep entries.
        -- Let's keep it simple: We don't *need* to remove cache entries here
        -- unless BioManager.GetBio(id) becomes nil, which we don't check here.
        -- The 'seen' flag was primarily used by WRC to remove UIElements.
        -- We'll leave the cache as is for simplicity. If a player logs off,
        -- they won't be in getOnlinePlayers() anymore.
    end
    -- If you *did* want to prune the cache:
    -- for _, id in ipairs(idsToRemove) do
    --     OverheadBioRenderer.OverheadElements[id] = nil
    -- end
end

if not OverheadBioRenderer._hooked then
    Events.OnPreUIDraw.Add(OverheadBioRenderer.RenderBios)
    OverheadBioRenderer._hooked = true
end

return OverheadBioRenderer