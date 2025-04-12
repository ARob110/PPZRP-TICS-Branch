TICS_BioManager = {}
TICS_BioManager.PlayerBios = {} -- Key: onlineID, Value: bio string or nil

function TICS_BioManager.UpdateBio(onlineID, bio)
    TICS_BioManager.PlayerBios[onlineID] = bio
    -- Optional: Trigger an event or callback if UI needs immediate refresh
end

function TICS_BioManager.GetBio(onlineID)
    return TICS_BioManager.PlayerBios[onlineID]
end

-- Function to remove bio when player disconnects (needs player disconnect event)
function TICS_BioManager.OnPlayerDisconnect(player)
    if player then
        TICS_BioManager.PlayerBios[player:getOnlineID()] = nil
    end
end
-- Events.OnPlayerDisconnect.Add(TICS_BioManager.OnPlayerDisconnect) -- Hook this up

-- Function to potentially request bios on connect or periodically
-- (Might need a server command to send all current bios, or rely on ModData sync)

return TICS_BioManager