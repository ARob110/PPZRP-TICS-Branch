--------------------------------------------------
--  Client‑side bio cache & ModData listeners
--------------------------------------------------
local key = "TICS_PlayerBios"
TICS_PlayerBios = {}        -- global table; safe to overwrite

-- Receive full table (server push or request response)
local function onGlobalModData(k, data)
    if k == key and type(data) == "table" then
        TICS_PlayerBios = data
    end
end
Events.OnReceiveGlobalModData.Add(onGlobalModData)

-- Request table when we join a server
local function onConnected()
    ModData.request(key)
end
Events.OnConnected.Add(onConnected)

-- Lightweight helper API
local BioMeta = {}

function BioMeta.Get(username)              -- returns string or nil
    return TICS_PlayerBios[username]
end

-- local cache set (used when you want optimistic update;
--   not strictly required, but handy for UI feedback)
function BioMeta.SetLocal(username, text)
    TICS_PlayerBios[username] = text
end

return BioMeta