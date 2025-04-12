require "client/TICS_BioData"

local ALL_BIOS_MODDATA_KEY = "TICS_AllPlayerBios" -- Must match server constant

local function OnConnected_RequestBios()
    print("[TICS BioSync] Connected to server. Requesting all player bios via ModData key: " .. ALL_BIOS_MODDATA_KEY)
    ModData.request(ALL_BIOS_MODDATA_KEY)
end

local function OnReceiveGlobalModData_HandleBios(key, modData)
    if key == ALL_BIOS_MODDATA_KEY then
        print("[TICS BioSync] Received global bio data update. Updating local cache.")
        if type(modData) == "table" then
            TICS_PlayerBios = modData -- Overwrite entire local cache
            -- Optional: Print cache size for debug
            local count = 0
            for _ in pairs(TICS_PlayerBios) do count = count + 1 end
            print("[TICS BioSync] Local bio cache updated. Size: " .. count)
        else
            print("[TICS BioSync] ERROR: Received non-table data for " .. ALL_BIOS_MODDATA_KEY)
            TICS_PlayerBios = {} -- Reset cache on error
        end
    end
end

-- Hook the event handlers
Events.OnConnected.Add(OnConnected_RequestBios)
Events.OnReceiveGlobalModData.Add(OnReceiveGlobalModData_HandleBios)

print("[TICS BioSync] Sync event handlers registered.")