-- Persisted bio registry  (server‑side only)
local key = "TICS_PlayerBios"
local BioServer = {}

-- 1A · Init on world load
local function init()
    local data = ModData.getOrCreate(key)
    if type(data) ~= "table" then
        ModData.add(key, {})          -- seed an empty table on first run
    end
end
Events.OnInitGlobalModData.Add(init)

-- 1B · Setter / Getter
function BioServer.Set(playerObj, text)            -- text may be nil (“clear”)
    local bios = ModData.getOrCreate(key)
    bios[playerObj:getUsername()] = text
    ModData.transmit(key)                          -- push to all clients
end

function BioServer.Get(username)
    local bios = ModData.getOrCreate(key)
    return bios[username]
end

return BioServer