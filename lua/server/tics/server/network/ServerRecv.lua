local AvatarManager = require('tics/server/AvatarManager')
local Character     = require('tics/shared/utils/Character')
local ChatMessage   = require('tics/server/ChatMessage')
local ServerSend    = require('tics/server/network/ServerSend')
local Radio         = require('tics/server/radio/Radio')
local RadioManager  = require('tics/server/radio/RadioManager')
local World         = require('tics/shared/utils/World')


local function GetCoordsString(player)
    local x = math.floor(player:getX())
    local y = math.floor(player:getY())
    local z = math.floor(player:getZ())
    return x .. "," .. y .. "," .. z
end

local RecvServer = {}


RecvServer['MuteInHandRadio'] = function(player, args)
    local playerName = args['player']
    if playerName == nil then
        print('TICS error: MuteInHandRadio packet with null player name')
        return
    end
    if args['id'] == nil then
        print('TICS error: MuteInHandRadio packet with a null id')
        return
    end
    local id = args['id']
    if id == nil then
        print('TICS error: MuteInHandRadio packet has no id value')
        return
    end
    local radio = Character.getItemById(player, id) or Character.getFirstAttachedItemByType(player, args['belt'])
    if radio == nil or not instanceof(radio, 'Radio') then
        print('TICS error: MuteInHandRadio packet asking for id ' .. id ..
                ' but no radio was found')
        return
    end
    local muteState = args['mute']
    if type(muteState) ~= 'boolean' then
        print('TICS error: MuteInHandRadio packet has no "mute" variable')
        return
    end
    Radio.MuteRadio(radio, muteState)
    Radio.SyncHand(radio, player, id)
end


RecvServer['MuteSquareRadio'] = function(player, args)
    local x = args['x']
    local y = args['y']
    local z = args['z']
    if x == nil or y == nil or z == nil then
        print('TICS error: MuteSquareRadio packet with null coordinate')
        return
    end
    local square = getSquare(x, y, z)
    if square == nil then
        print('TICS error: MuteSquareRadio packet coordinate do not point to a square: x: ' ..
                x .. ', y: ' .. y .. ', z: ' .. z)
        return
    end
    local radios = World.getSquareItemsByGroup(square, 'IsoRadio')
    if radios == nil or #radios <= 0 then
        print('TICS error: MuteSquareRadio packet square does not contain a radio at: x: ' ..
                x .. ', y: ' .. y .. ', z: ' .. z)
        return
    end
    local radio = radios[1]
    if radio == nil or radio.getModData == nil or radio:getModData() == nil then
        print('TICS error: MuteSquareRadio packet lead to an impossible error where we found a corrupted radio')
        return
    end
    local muteState = args['mute']
    if type(muteState) ~= 'boolean' then
        print('TICS error: MuteSquareRadio packet has no "mute" variable')
        return
    end
    Radio.MuteRadio(radio, muteState)
    Radio.SyncSquare(radio)
end


RecvServer['ChatMessage'] = function(player, args)
    -- Explicitly extract colors if ProcessMessage needs them separately
    local messageData = {
        author = args.author,
        characterName = args.characterName,
        message = args.message,
        language = args.language,
        type = args.type,
        target = args.target, -- For PMs
        nameColor = args.nameColor, -- Pass explicitly
        textColor = args.textColor, -- Pass explicitly
        pitch = args.pitch,
        disableVerb = args.disableVerb,
        -- Include any other fields ProcessMessage expects
    }
    -- Call ProcessMessage with the structured data
    ChatMessage.ProcessMessage(player, messageData, 'ChatMessage', true)
end

RecvServer['ChangeName'] = function(player, args)
    ChatMessage.ChangeName(player, args.fullName) -- Pass args.fullName to ChatMessage.ChangeName
end

RecvServer['Typing'] = function(player, args)
    ChatMessage.ProcessMessage(player, args, 'Typing', false)
end


RecvServer['AskSandboxVars'] = function(player, args)
    ServerSend.Command(player, 'SendSandboxVars', ChatMessage.MessageTypeSettings)
end


RecvServer['GiveBeltRadioState'] = function(player, args)
    local playerName = args['player']
    if playerName == nil then
        print('TICS error: GiveBeltRadioState packet with null player name')
        return
    end
    local beltType = args['belt']
    if beltType == nil then
        print('TICS error: GiveBeltRadioState packet has no "belt" variable')
        return
    end
    local turnedOn = args['turnedOn']
    if type(turnedOn) ~= 'boolean' then
        print('TICS error: GiveBeltRadioState packet has no "turnedOn" variable')
        return
    end
    local muteState = args['mute']
    if type(muteState) ~= 'boolean' then
        print('TICS error: GiveBeltRadioState packet has no "mute" variable')
        return
    end
    local volume = args['volume']
    if type(volume) ~= 'number' then
        print('TICS error: GiveBeltRadioState packet has no "volume" variable')
        return
    end
    local frequency = args['frequency']
    if type(frequency) ~= 'number' then
        print('TICS error: GiveBeltRadioState packet has no "frequency" variable')
        return
    end
    local battery = args['battery']
    if type(battery) ~= 'number' then
        print('TICS error: GiveBeltRadioState packet has no "battery" variable')
        return
    end
    local headphone = args['headphone']
    if type(headphone) ~= 'number' then
        print('TICS error: GiveBeltRadioState packet has no "headphone" variable')
        return
    end
    local isTwoWay = args['isTwoWay']
    if type(isTwoWay) ~= 'boolean' then
        print('TICS error: GiveBeltRadioState packet has no "isTwoWay" variable')
        return
    end
    local transmitRange = args['transmitRange']
    if type(transmitRange) ~= 'number' then
        print('TICS error: GiveBeltRadioState packet has no "transmitRange" variable')
        return
    end
    local radio = Character.getFirstAttachedItemByType(player, beltType)
    if radio == nil or not instanceof(radio, 'Radio') then
        print('TICS error: GiveBeltRadioState packet asking for a belt radio of type ' .. beltType ..
                ' but no radio was found')
        return
    end
    radio = RadioManager:getOrCreateFakeBeltRadio(player)
    Radio.MuteRadio(radio, muteState)
    Radio.SyncBelt(radio, player, turnedOn, muteState, volume, frequency, battery, headphone, isTwoWay, transmitRange)
end


RecvServer['AskInHandRadioState'] = function(player, args)
    local playerName = args['player']
    if playerName == nil then
        print('TICS error: AskInHandRadioState packet with null player name')
        return
    end
    local id = args['id']
    if id == nil then
        print('TICS error: AskInHandRadioState packet with a null id')
        return
    end
    local radio = Character.getItemById(player, id) or Character.getFirstAttachedItemByType(player, args['belt'])
    if radio == nil or not instanceof(radio, 'Radio') then
        print('TICS error: AskInHandRadioState packet asking for id ' .. id ..
                ' but no radio was found')
        return
    end
    Radio.SyncHand(radio, player, id)
end


RecvServer['AskSquareRadioState'] = function(player, args)
    local x = args['x']
    local y = args['y']
    local z = args['z']
    if x == nil or y == nil or z == nil then
        print('TICS error: AskSquareRadioState packet with null coordinate')
        return
    end
    local square = getSquare(x, y, z)
    if square == nil then
        print('TICS error: AskSquareRadioState packet coordinate do not point to a square: x: ' ..
                x .. ', y: ' .. y .. ', z: ' .. z)
        return
    end
    local radios = World.getSquareItemsByGroup(square, 'IsoRadio')
    if radios == nil or #radios <= 0 then
        print('TICS error: AskSquareRadioState packet square does not contain a radio at: x: ' ..
                x .. ', y: ' .. y .. ', z: ' .. z)
        return
    end
    local radio = radios[1]
    Radio.SyncSquare(radio, player)
end


RecvServer['KnownAvatars'] = function(player, args)
    local avatars = args['avatars']
    if avatars == nil or type(avatars) ~= 'table' then
        print('TICS error: KnownAvatars packet does not contain an "avatars" variable')
    end
    AvatarManager:registerPlayerAvatars(player, avatars)
end


RecvServer['AvatarRequest'] = function(player, args)
    local data = args['data']
    if data == nil or type(data) ~= 'table' then
        print('TICS error: AvatarRequest packet does not contain a "data" variable')
        return
    end
    local checksum = args['checksum']
    if checksum == nil or type(checksum) ~= 'number' then
        print('TICS error: AvatarRequest packet does not contain a "checksum" variable')
        return
    end
    local extension = args['extension']
    if extension == nil or type(extension) ~= 'string' then
        print('TICS error: AvatarRequest packet does not contain an "extension" variable')
        return
    end
    local username = player:getUsername()
    if username == nil or type(username) ~= 'string' then
        print('TICS error: AvatarRequest packet does not contain an "username" variable')
        return
    end
    local firstName = args['firstName']
    if firstName == nil or type(firstName) ~= 'string' then
        print('TICS error: AvatarRequest packet does not contain a "firstName" variable')
        return
    end
    local lastName = args['lastName']
    if lastName == nil or type(lastName) ~= 'string' then
        print('TICS error: AvatarRequest packet does not contain a "lastName" variable')
        return
    end
    AvatarManager:registerAvatarRequest(username, firstName, lastName, extension, checksum, data)
end

RecvServer['ApproveAvatar'] = function(player, args)
    local username  = args['username']
    local firstName = args['firstName']
    local lastName  = args['lastName']
    local checksum  = args['checksum']
    if type(username) ~= 'string' then
        print('TICS error: ApproveAvatar packet does not contain a "username" variable')
        return
    end
    if type(firstName) ~= 'string' then
        print('TICS error: ApproveAvatar packet does not contain a "firstName" variable')
        return
    end
    if type(lastName) ~= 'string' then
        print('TICS error: ApproveAvatar packet does not contain a "lastName" variable')
        return
    end
    if type(checksum) ~= 'number' then
        print('TICS error: ApproveAvatar packet does not contain a "checksum" variable')
        return
    end
    AvatarManager:approveAvatar(player, username, firstName, lastName, checksum)
end

RecvServer['RejectAvatar'] = function(player, args)
    local username  = args['username']
    local firstName = args['firstName']
    local lastName  = args['lastName']
    local checksum  = args['checksum']
    if type(username) ~= 'string' then
        print('TICS error: RejectAvatar packet does not contain a "username" variable')
        return
    end
    if type(firstName) ~= 'string' then
        print('TICS error: RejectAvatar packet does not contain a "firstName" variable')
        return
    end
    if type(lastName) ~= 'string' then
        print('TICS error: RejectAvatar packet does not contain a "lastName" variable')
        return
    end
    if type(checksum) ~= 'number' then
        print('TICS error: RejectAvatar packet does not contain a "checksum" variable')
        return
    end
    AvatarManager:rejectAvatar(player, username, firstName, lastName, checksum)
end

RecvServer['Roll'] = function(player, args)
    local diceCount = args['diceCount']
    local diceType  = args['diceType']
    local addCount  = args['addCount']
    if type(diceCount) ~= 'number' then
        print('TICS error: Roll packet does not contain a "diceCount" variable')
        return
    end
    if type(diceType) ~= 'number' then
        print('TICS error: Roll packet does not contain a "diceType" variable')
        return
    end
    if addCount ~= nil and type(addCount) ~= 'number' then
        print('TICS error: Roll packet does not contain a "diceType" variable')
        return
    end
    ChatMessage.RollDice(player, diceCount, diceType, addCount)
end

RecvServer['PlaySoundGlobal'] = function(player, args)
    -- 1) Make sure the player is an admin
    if player:getAccessLevel() ~= "Admin" then
        ServerSend.ChatErrorMessage(player, nil, "Requires admin privileges.")
        return
    end

    -- 2) Get the sound file name
    local soundFile = args['soundFile']
    if not soundFile then
        ServerSend.ChatErrorMessage(player, nil, "No soundFile specified.")
        return
    end

    -- 3) Loop over all players and send them a client-side command to play the sound
    local onlinePlayers = getOnlinePlayers()
    for i = 0, onlinePlayers:size() - 1 do
        local targetPlayer = onlinePlayers:get(i)
        -- pass the command & arguments
        ServerSend.Command(targetPlayer, "PlaySoundClientSide", { soundFile = soundFile })

        ServerSend.ChatInfoMessage(targetPlayer,
                "A global sound was triggered. Type /stopsound to stop sounds on your client.")
    end

-- Optionally: also send the admin a direct confirmation
ServerSend.ChatInfoMessage(player,
        "Global sound triggered for '" .. soundFile .. "', and notice sent to all players.")
end

RecvServer['globalevent'] = function(player, args)
    print("DEBUG: globalevent received from", player:getUsername())

    if ChatMessage.MessageTypeSettings and ChatMessage.MessageTypeSettings['globalevent'].adminOnly then
        print("DEBUG: Checking admin rights for", player:getUsername(), "Access Level:", player:getAccessLevel())
        if player:getAccessLevel() ~= 'Admin' then
            print("DEBUG: Access denied for", player:getUsername())
            ServerSend.ChatErrorMessage(player, nil, "Requires admin privileges.")
            return
        end
    end

    print("DEBUG: globalevent is proceeding, message:", args.message or "nil")

    ChatMessage.ProcessMessage(player, {
        author        = player:getUsername(),
        characterName = "GM Event",
        message       = args.message,
        type          = 'globalevent',
        color         = {255, 188, 0},
    }, "ChatMessage", true)

    print("DEBUG: Message sent to ProcessMessage")
    ServerSend.ChatInfoMessage(player, "Global event message broadcast to all players.")
end




RecvServer['Coords'] = function(player, args)
    -- No param needed
    -- We'll just build the coords and send them to that user via TICS chat
    local coordsString = GetCoordsString(player)
    local message = "[Pandemonium] Coordinates: " .. coordsString

    -- If you only want *this player* to see it:
    ServerSend.ChatInfoMessage(player, message)

    -- Or if you wanted *everyone* to see it, you could do a broadcast:
    -- local onlinePlayers = getOnlinePlayers()
    -- for i=0, onlinePlayers:size()-1 do
    --     local p = onlinePlayers:get(i)
    --     ServerSend.ChatInfoMessage(p, message)
    -- end
end


RecvServer['Hammer'] = function(player, args)
    -- 1) Check if the player is an Admin
    if player:getAccessLevel() ~= "Admin" then
        ServerSend.ChatErrorMessage(player, nil, "Requires admin privileges.")
        print("TICS WARNING: Non-admin " .. player:getUsername() .. " attempted /hammer.") -- Keep
        return
    end

    -- 2) Validate the state argument ('on' or 'off')
    local state = args and args.state
    if not state or (state ~= "on" and state ~= "off") then
        ServerSend.ChatErrorMessage(player, nil, "Usage: /hammer on/off")
        print("TICS ERROR: Invalid state received for /hammer from " .. player:getUsername() .. ": " .. tostring(state)) -- Keep
        return
    end

    -- 3) Get the player's ModData table
    local modData = player:getModData()
    if not modData then
        print("TICS WARNING: ModData was nil for player " .. player:getUsername() .. " during /hammer. Cannot set hammer state.") -- Keep
        ServerSend.ChatErrorMessage(player, nil, "Internal error: Could not retrieve player data.")
        return
    end

    -- 4) Modify the table directly
    -- Removed DEBUG SERVER print line here
    modData['_hammer'] = state
    -- Removed DEBUG SERVER print line here

    -- 5) Transmit the updated data
    player:transmitModData()
    -- Removed DEBUG SERVER print line here

    -- 6) Verify the change immediately (optional server-side check, but logs are removed anyway)
    local checkData = player:getModData()
    local verifiedState = checkData and checkData['_hammer']
    -- Removed DEBUG SERVER print line here

    -- 7) Send confirmation feedback to the player
    ServerSend.ChatInfoMessage(player, "[Pandemonium] Hammer turned " .. state)
    print("TICS INFO: Player " .. player:getUsername() .. " hammer mode set to: " .. state) -- Keep
end

-- A helper function to compute Euclidean distance between two players.
local function GetDistanceBetweenPlayers(player1, player2)
    local dx = player1:getX() - player2:getX()
    local dy = player1:getY() - player2:getY()
    return math.sqrt(dx * dx + dy * dy)
end

RecvServer['PlaySoundLocal'] = function(player, args)
    if player:getAccessLevel() ~= "Admin" then
        ServerSend.ChatErrorMessage(player, nil, "Requires admin privileges.")
        return
    end

    local soundFile = args['soundFile']
    if not soundFile then
        ServerSend.ChatErrorMessage(player, nil, "No soundFile specified.")
        return
    end

    local localRange = 150

    local onlinePlayers = getOnlinePlayers()
    for i = 0, onlinePlayers:size() - 1 do
        local targetPlayer = onlinePlayers:get(i)

        -- If target is in hearing range (or is the admin themself)
        if targetPlayer:getOnlineID() == player:getOnlineID()
                or GetDistanceBetweenPlayers(player, targetPlayer) <= localRange then

            -- 1) Send the local sound
            ServerSend.Command(targetPlayer, "PlaySoundClientSideLocal", { soundFile = soundFile })

            -- 2) Send the chat hint about /stopsound
            ServerSend.ChatInfoMessage(targetPlayer,
                    "A local sound was triggered: /stopsound to stop sounds on your client.")
        end
    end

    -- If you want to reassure only the admin as well:
    ServerSend.ChatInfoMessage(player,
            "Local sound triggered for '" .. soundFile .. "' (range " .. localRange .. ").")
end


RecvServer['PlaySoundQuiet'] = function(player, args)
    if player:getAccessLevel() ~= "Admin" then
        ServerSend.ChatErrorMessage(player, nil, "Requires admin privileges.")
        return
    end

    local soundFile = args['soundFile']
    if not soundFile then
        ServerSend.ChatErrorMessage(player, nil, "No soundFile specified.")
        return
    end

    local quietRange = 15

    local onlinePlayers = getOnlinePlayers()
    for i = 0, onlinePlayers:size() - 1 do
        local targetPlayer = onlinePlayers:get(i)

        if targetPlayer:getOnlineID() == player:getOnlineID()
                or GetDistanceBetweenPlayers(player, targetPlayer) <= quietRange then

            -- 1) Send the quiet sound
            ServerSend.Command(targetPlayer, "PlaySoundClientSideQuiet", { soundFile = soundFile })

            -- 2) Show a ChatInfoMessage so they know about /stopsound
            ServerSend.ChatInfoMessage(targetPlayer,
                    "A quiet sound was triggered: Type /stopsound to stop sounds on your client.")
        end
    end

    -- Just for the admin’s own chat:
    ServerSend.ChatInfoMessage(player,
            "Quiet sound triggered for '" .. soundFile .. "' (range " .. quietRange .. ").")
end

RecvServer["SetBio"] = function(player, args)
    if not args or type(args.bioText) ~= "string" then
        print("TICS Error: Invalid 'SetBio' command received from " .. player:getUsername())
        ServerSend.ChatErrorMessage(player, nil, "Invalid bio command format.")
        return
    end
    ChatMessage.SaveBio(player, args.bioText)
end

RecvServer["SetChatColor"] = function(player, args)
    local r = tonumber(args.r)
    local g = tonumber(args.g)
    local b = tonumber(args.b)

    if not r or not g or not b then
        ServerSend.ChatErrorMessage(player, nil, "Usage: /setcolor r g b")
        return
    end

    local modData = player:getModData()
    modData["ChatColor"] = { r = r, g = g, b = b }
    player:transmitModData()

    ServerSend.ChatInfoMessage(player, string.format("Chat color set to RGB(%d, %d, %d)", r, g, b))
end

local function OnClientCommand(module, command, player, args)
    if module == 'TICS' and RecvServer[command] then
        RecvServer[command](player, args)
    end
end


Events.OnClientCommand.Add(OnClientCommand)