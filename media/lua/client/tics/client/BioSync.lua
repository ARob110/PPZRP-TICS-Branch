local ClientSend = require('tics/client/network/ClientSend')

local BioMeta = {}
local BioCache = {} -- Stores bios locally: { ["Username"] = "Bio Text", ... }
local Requested = {} -- Prevents spamming requests: { ["Username"] = true, ... }

function BioMeta.Get(playerObj)
    if not playerObj then return nil end
    local username = playerObj:getUsername()

    -- 1. If we have it in cache, return it immediately
    if BioCache[username] ~= nil then
        return BioCache[username]
    end

    -- 2. If we haven't asked for it yet, ask the server now (Lazy Load)
    if not Requested[username] then
        Requested[username] = true
        ClientSend.sendAskBio(username)
    end
end

-- Update the local cache (called by ClientRecv)
function BioMeta.Update(username, text)
    BioCache[username] = text
end

-- Helper for your own bio
function BioMeta.SetLocal(username, text)
    BioCache[username] = text
end

return BioMeta