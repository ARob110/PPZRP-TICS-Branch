--[[
    FocusManager.lua
    Client-side module for managing the Focus feature in TICS chat.
    
    Place this file at: media/lua/client/tics/client/FocusManager.lua
    
    The Focus feature allows players to select specific nearby players and have
    their messages displayed in a separate "Focus" tab, making it easier to
    follow conversations in crowded areas.
]]

local FocusManager = {}

-- Storage for focused player usernames (internal, not shown to user)
FocusManager.FocusedPlayers = {}

-- Cache for username -> character name mapping
FocusManager.CharacterNameCache = {}

-- Tab ID for the Focus tab
FocusManager.FocusTabID = 6

-- Whether the feature is enabled (controlled by sandbox)
FocusManager.Enabled = false

-----------------------------------------------------------
-- Character Name Resolution (for privacy/obfuscation)
-----------------------------------------------------------

--- Get character name for a username, with caching
---@param username string The username to look up
---@return string characterName The character name or "Unknown" if not found
function FocusManager.GetCharacterName(username)
    if not username then return "Unknown" end
    
    -- Check cache first
    if FocusManager.CharacterNameCache[username] then
        return FocusManager.CharacterNameCache[username]
    end
    
    -- Try to find the player and get their character name
    local onlinePlayers = getOnlinePlayers()
    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            local player = onlinePlayers:get(i)
            if player:getUsername() == username then
                local descriptor = player:getDescriptor()
                if descriptor then
                    local firstName = descriptor:getForename() or ""
                    local lastName = descriptor:getSurname() or ""
                    if firstName ~= "" then
                        local charName = firstName
                        if lastName ~= "" then
                            charName = charName .. " " .. lastName
                        end
                        FocusManager.CharacterNameCache[username] = charName
                        return charName
                    end
                end
            end
        end
    end
    
    -- Fallback - return a generic name
    return "Unknown Player"
end

--- Update the character name cache for a username
---@param username string
---@param characterName string
function FocusManager.UpdateCharacterNameCache(username, characterName)
    if username and characterName and characterName ~= "" then
        FocusManager.CharacterNameCache[username] = characterName
    end
end

--- Get a display-friendly list of focused players (shows character names, not usernames)
---@return table List of character names
function FocusManager.GetFocusedPlayerDisplayNames()
    local displayNames = {}
    for _, username in ipairs(FocusManager.FocusedPlayers) do
        table.insert(displayNames, FocusManager.GetCharacterName(username))
    end
    return displayNames
end

-----------------------------------------------------------
-- Admin/Invisibility Checks
-----------------------------------------------------------

--- Check if a player should be hidden from the focus list
--- Hides invisible admins to prevent metagaming their location
---@param player IsoPlayer The player to check
---@return boolean True if player should be hidden
function FocusManager.ShouldHidePlayer(player)
    if not player then return true end
    
    -- Check if player is invisible (admin invisibility)
    -- Project Zomboid uses isInvisible() method
    if player.isInvisible and player:isInvisible() then
        return true
    end
    
    -- Alternative check: isGhostMode (some PZ versions)
    if player.isGhostMode and player:isGhostMode() then
        return true
    end
    
    -- Check access level - hide admins/moderators who might be observing
    -- Only hide if they appear to be in "stealth" mode (invisible)
    local accessLevel = player:getAccessLevel()
    if accessLevel and accessLevel ~= "" and accessLevel ~= "None" then
        -- Admin/Moderator/Observer/GM - check if they're invisible
        -- If we can't determine invisibility, check if they have godmode
        -- (admins often enable godmode when going invisible for observation)
        if player.isGodMod and player:isGodMod() then
            -- Player has godmode - likely observing, hide them
            return true
        end
    end
    
    return false
end

--- Check if current player is an admin (can see all players)
---@return boolean
function FocusManager.IsCurrentPlayerAdmin()
    local player = getPlayer()
    if not player then return false end
    
    local accessLevel = player:getAccessLevel()
    return accessLevel and (accessLevel == "Admin" or accessLevel == "Moderator" or accessLevel == "GM" or accessLevel == "Observer")
end

-----------------------------------------------------------
-- Core Focus Management Functions
-----------------------------------------------------------

--- Check if the Focus feature is enabled via sandbox settings
---@return boolean
function FocusManager.IsEnabled()
    if TicsServerSettings and TicsServerSettings['options'] then
        local focusEnabled = TicsServerSettings['options']['focusEnabled']
        if focusEnabled ~= nil then
            FocusManager.Enabled = focusEnabled
            return focusEnabled
        end
    end
    return FocusManager.Enabled
end

--- Add a player to the focus list
---@param username string The username of the player to focus on
---@return boolean success Whether the operation succeeded
---@return string message Status message (uses character name for display)
function FocusManager.FocusOn(username)
    if not FocusManager.IsEnabled() then
        return false, "Focus feature is not enabled on this server."
    end
    
    if not username or username == "" then
        return false, "Invalid player."
    end
    
    -- Check if already focused
    if FocusManager.IsFocusedOn(username) then
        local charName = FocusManager.GetCharacterName(username)
        return false, "You are already focused on " .. charName .. "."
    end
    
    -- Check if trying to focus on self
    local player = getPlayer()
    if player and player:getUsername():lower() == username:lower() then
        return false, "You cannot focus on yourself."
    end
    
    -- Add to focus list (store username internally)
    table.insert(FocusManager.FocusedPlayers, username)
    
    -- Save to ModData for persistence
    FocusManager.SaveFocusData()
    
    -- Return message with character name
    local charName = FocusManager.GetCharacterName(username)
    return true, "Now focused on " .. charName .. "."
end

--- Remove a player from the focus list
---@param username string The username of the player to unfocus
---@return boolean success Whether the operation succeeded
---@return string message Status message (uses character name for display)
function FocusManager.UnfocusOn(username)
    if not FocusManager.IsEnabled() then
        return false, "Focus feature is not enabled on this server."
    end
    
    if not username or username == "" then
        return false, "Invalid player."
    end
    
    local normalizedUsername = username:lower()
    local found = false
    local newFocused = {}
    local removedUsername = nil
    
    for _, focusedName in ipairs(FocusManager.FocusedPlayers) do
        if focusedName:lower() ~= normalizedUsername then
            table.insert(newFocused, focusedName)
        else
            found = true
            removedUsername = focusedName
        end
    end
    
    if not found then
        local charName = FocusManager.GetCharacterName(username)
        return false, "You are not focused on " .. charName .. "."
    end
    
    FocusManager.FocusedPlayers = newFocused
    FocusManager.SaveFocusData()
    
    local charName = FocusManager.GetCharacterName(removedUsername or username)
    return true, "No longer focused on " .. charName .. "."
end

--- Remove all players from the focus list
---@return boolean success Whether the operation succeeded
---@return string message Status message
function FocusManager.UnfocusAll()
    if not FocusManager.IsEnabled() then
        return false, "Focus feature is not enabled on this server."
    end
    
    local count = #FocusManager.FocusedPlayers
    
    if count == 0 then
        return false, "You are not focused on anyone."
    end
    
    FocusManager.FocusedPlayers = {}
    FocusManager.SaveFocusData()
    
    return true, "Cleared focus from " .. count .. " player(s)."
end

--- Check if currently focused on a specific player
---@param username string The username to check
---@return boolean
function FocusManager.IsFocusedOn(username)
    if not username then return false end
    
    local normalizedUsername = username:lower()
    
    for _, focusedName in ipairs(FocusManager.FocusedPlayers) do
        if focusedName:lower() == normalizedUsername then
            return true
        end
    end
    
    return false
end

--- Check if there are any focused players
---@return boolean
function FocusManager.HasFocus()
    return #FocusManager.FocusedPlayers > 0
end

--- Get the list of currently focused players (usernames - internal use)
---@return table
function FocusManager.GetFocusedPlayers()
    return FocusManager.FocusedPlayers
end

--- Get the count of focused players
---@return number
function FocusManager.GetFocusCount()
    return #FocusManager.FocusedPlayers
end

-----------------------------------------------------------
-- Persistence Functions
-----------------------------------------------------------

--- Save focus data to ModData for persistence across sessions
function FocusManager.SaveFocusData()
    local player = getPlayer()
    if not player then return end
    
    local modData = player:getModData()
    if not modData then return end
    
    modData['TICS_FocusedPlayers'] = FocusManager.FocusedPlayers
end

--- Load focus data from ModData
function FocusManager.LoadFocusData()
    local player = getPlayer()
    if not player then return end
    
    local modData = player:getModData()
    if not modData then return end
    
    local savedFocus = modData['TICS_FocusedPlayers']
    if savedFocus and type(savedFocus) == 'table' then
        FocusManager.FocusedPlayers = savedFocus
    else
        FocusManager.FocusedPlayers = {}
    end
end

-----------------------------------------------------------
-- Helper Functions
-----------------------------------------------------------

--- Find a player by username or character name
---@param identifier string Username or character name (can be quoted)
---@return IsoPlayer|nil player The found player or nil
---@return string|nil username The username if found
function FocusManager.FindPlayerByIdentifier(identifier)
    if not identifier then return nil, nil end
    
    -- Remove quotes if present
    identifier = identifier:gsub('^"', ''):gsub('"$', '')
    identifier = identifier:gsub("^%s+", ""):gsub("%s+$", "") -- trim whitespace
    
    local onlinePlayers = getOnlinePlayers()
    if not onlinePlayers then return nil, nil end
    
    local lowerIdentifier = identifier:lower()
    local isAdmin = FocusManager.IsCurrentPlayerAdmin()
    
    for i = 0, onlinePlayers:size() - 1 do
        local player = onlinePlayers:get(i)
        local username = player:getUsername()
        
        -- Skip invisible players unless current player is admin
        if not isAdmin and FocusManager.ShouldHidePlayer(player) then
            -- Skip this player - they're invisible/hidden
        else
            -- Check username match (exact)
            if username:lower() == lowerIdentifier then
                return player, username
            end
            
            -- Check character name match
            local descriptor = player:getDescriptor()
            if descriptor then
                local firstName = descriptor:getForename() or ""
                local lastName = descriptor:getSurname() or ""
                local fullName = (firstName .. " " .. lastName):lower():gsub("^%s+", ""):gsub("%s+$", "")
                local firstNameLower = firstName:lower()
                
                if fullName == lowerIdentifier or firstNameLower == lowerIdentifier then
                    -- Also cache this mapping
                    local charName = firstName
                    if lastName ~= "" then
                        charName = charName .. " " .. lastName
                    end
                    FocusManager.CharacterNameCache[username] = charName
                    return player, username
                end
            end
        end
    end
    
    return nil, nil
end

--- Get nearby players that can be focused on
--- Filters out invisible admins to prevent metagaming
---@param range number The range in tiles to search (default 30)
---@return table players List of {username, characterName, distance, isFocused} tables
function FocusManager.GetNearbyFocusablePlayers(range)
    range = range or 30  -- Default to say range
    
    -- Try to get range from server settings if available
    if TicsServerSettings and TicsServerSettings['options'] and TicsServerSettings['options']['focusRange'] then
        range = TicsServerSettings['options']['focusRange']
    end
    
    local result = {}
    local myPlayer = getPlayer()
    if not myPlayer then return result end
    
    local myUsername = myPlayer:getUsername()
    local onlinePlayers = getOnlinePlayers()
    if not onlinePlayers then return result end
    
    -- Check if current player is admin (admins can see everyone)
    local isAdmin = FocusManager.IsCurrentPlayerAdmin()
    
    for i = 0, onlinePlayers:size() - 1 do
        local player = onlinePlayers:get(i)
        local username = player:getUsername()
        
        -- Skip self
        if username ~= myUsername then
            -- Skip invisible/hidden players unless current player is admin
            if not isAdmin and FocusManager.ShouldHidePlayer(player) then
                -- Skip this player - they're invisible/hidden
            else
                local distance = myPlayer:DistTo(player:getX(), player:getY())
                
                if distance <= range then
                    local descriptor = player:getDescriptor()
                    local characterName = "Unknown"
                    
                    if descriptor then
                        local firstName = descriptor:getForename() or ""
                        local lastName = descriptor:getSurname() or ""
                        if firstName ~= "" then
                            characterName = firstName
                            if lastName ~= "" then
                                characterName = characterName .. " " .. lastName
                            end
                            -- Cache this mapping
                            FocusManager.CharacterNameCache[username] = characterName
                        end
                    end
                    
                    table.insert(result, {
                        username = username,
                        characterName = characterName,
                        distance = math.floor(distance),
                        isFocused = FocusManager.IsFocusedOn(username)
                    })
                end
            end
        end
    end
    
    -- Sort by distance
    table.sort(result, function(a, b)
        return a.distance < b.distance
    end)
    
    return result
end

-----------------------------------------------------------
-- Message Filtering
-----------------------------------------------------------

--- Check if a message should be shown in the Focus tab
--- Shows messages from focused players AND from the current player (so you can see your own messages)
---@param author string The author's username
---@return boolean
function FocusManager.ShouldShowInFocusTab(author)
    if not FocusManager.IsEnabled() then
        return false
    end
    
    if not FocusManager.HasFocus() then
        return false
    end
    
    -- Check if author is focused
    if FocusManager.IsFocusedOn(author) then
        return true
    end
    
    -- Also show own messages so the player can see their conversation
    local player = getPlayer()
    if player and player:getUsername() == author then
        return true
    end
    
    return false
end

-----------------------------------------------------------
-- Initialization
-----------------------------------------------------------

--- Initialize the FocusManager (call on game start)
--- Clears focus list on each login - Focus is meant for real-time conversation
--- tracking, not persistent player following across sessions
function FocusManager.Initialize()
    -- Clear focus list on login - don't persist across sessions
    -- This prevents stale focuses on players who logged off, changed characters, etc.
    FocusManager.FocusedPlayers = {}
    FocusManager.SaveFocusData()  -- Clear the persisted data too
    
    -- Clear the character name cache on init to ensure fresh data
    FocusManager.CharacterNameCache = {}
    print("TICS FocusManager initialized (focus list cleared for new session).")
end

return FocusManager
