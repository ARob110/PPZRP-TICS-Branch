local Character = require('tics/shared/utils/Character')

local ClientSend = {}

function ClientSendCommand(commandName, args)
    sendClientCommand('TICS', commandName, args)
end

local function FormatCharacterName(player)
    local first, last = Character.getFirstAndLastName(player)
    return first .. ' ' .. last
end

function ClientSend.sendChatMessage(message, language, defaultNameColor, type, pitch, disableVerb)
    if not isClient() then return end
    local player = getPlayer()

    -- 1) Get the player's specific name color (from /color command)
    local nameColor = defaultNameColor -- This is already fetched from modData in ISChat.lua

    -- 2) Determine the text color
    local textColor = nil
    local modData = ISChat.instance and ISChat.instance.ticsModData -- Check if instance and modData exist
    if modData and modData.emoteColors and modData.emoteColors[type] then
        -- Use the custom color if set for this stream type
        textColor = modData.emoteColors[type]
    else
        -- Otherwise, use the default color for the stream type
        -- Need BuildColorFromMessageType here or access to TicsServerSettings/defaults
        -- It's cleaner to have BuildColorFromMessageType available here or pass defaults
        -- Let's try accessing it directly (assuming ISChat loaded it)
        if BuildColorFromMessageType then -- Check if the function is accessible
            textColor = BuildColorFromMessageType(type)
        else -- Fallback if not accessible (should not happen if ISChat ran)
            print("TICS WARNING: BuildColorFromMessageType not found in ClientSend.lua context. Falling back default text color.")
            textColor = {255, 255, 255} -- Default white as a last resort
        end
    end

    -- 3) Send both colors to the server
    ClientSendCommand('ChatMessage', {
        author         = player:getUsername(),
        characterName  = FormatCharacterName(player),
        message        = message,
        language       = language,
        type           = type,
        nameColor      = nameColor,  -- The user's name color (/color)
       -- textColor      = textColor,  -- The specific text color for this message type
        pitch          = pitch,
        disableVerb    = disableVerb,
    })
end



-- Let's assume PM uses default PM color unless specifically set via /emotecolor pm <color>
function ClientSend.sendPrivateMessage(message, language, defaultNameColor, target, pitch)
    if not isClient() then return end
    local player = getPlayer()
    local type = 'pm' -- Explicitly define type

    -- Determine text color for PM
    local textColor = nil
    local modData = ISChat.instance and ISChat.instance.ticsModData
    if modData and modData.emoteColors and modData.emoteColors[type] then
        textColor = modData.emoteColors[type]
    else
        if BuildColorFromMessageType then
            textColor = BuildColorFromMessageType(type)
        else
            textColor = {255, 149, 211} -- Default PM color fallback
        end
    end

    ClientSendCommand('ChatMessage', {
        author         = getPlayer():getUsername(),
        characterName  = FormatCharacterName(player),
        message        = message,
        language       = language,
        type           = type,
        target         = target,
        nameColor      = defaultNameColor, -- PM sender's name color
        textColor      = textColor,      -- PM text color
        pitch          = pitch,
        -- disableVerb likely true for PM, but let server decide based on type?
        -- Add disableVerb if needed based on ChatMessage.ProcessMessage logic
    })
end

-- Add BuildColorFromMessageType dependency (needs access to settings or defaults)
-- This might require passing TicsServerSettings to ClientSend or defining defaults here.
-- Simplest is to rely on it being loaded by ISChat.lua first.
-- We added a check 'if BuildColorFromMessageType then' above.

-- We also need MessageTypeToColor defaults defined or accessible here if BuildColorFromMessageType fails
local MessageTypeToColor_Default = {
    ['whisper'] = { 130, 200, 200 },
    ['low'] = { 180, 230, 230 },
    ['say'] = { 255, 255, 255 },
    ['yell'] = { 230, 150, 150 },
    ['radio'] = { 144, 122, 176 },
    ['pm'] = { 255, 149, 211 },
    ['faction'] = { 100, 255, 66 },
    ['safehouse'] = { 220, 255, 80 },
    ['general'] = { 109, 111, 170 },
    ['admin'] = { 230, 130, 111 },
    ['ooc'] = { 146, 255, 148 },
    ['me'] = { 196, 174, 149 }, -- Example default for /me
    ['do'] = { 149, 174, 196 }, -- Example default for /do
    ['whisperme'] = { 130, 200, 200 }, -- Example default
    ['melow'] = { 180, 230, 230 },     -- Example default
    ['melong'] = { 255, 255, 255 },    -- Example default
    ['dolow'] = { 149, 174, 196 },     -- Example default
    ['dolong'] = { 149, 174, 196 },    -- Example default
    ['admingdolong'] = { 149, 174, 196 },
    ['localevent'] = {255, 255, 0},   -- Example default
    ['globalevent'] = {255, 188, 0},  -- Example default (matches server)
    ['scriptedRadio'] = {171, 240, 140}, -- Example default
    -- Add other types as needed
}

-- Redefine BuildColorFromMessageType locally within ClientSend.lua as a fallback/primary source
-- This avoids dependency issues if ISChat hasn't loaded/defined it globally when ClientSend runs.
local function BuildColorFromMessageType(type)
    -- Prioritize server settings if available (though ClientSend might not have easy access)
    if TicsServerSettings and TicsServerSettings[type] and TicsServerSettings[type]['color'] then
        return TicsServerSettings[type]['color']
    elseif MessageTypeToColor_Default[type] then
        return MessageTypeToColor_Default[type]
    else
        print("TICS WARNING: Unknown message type '" .. type .. "' in BuildColorFromMessageType (ClientSend). Defaulting white.")
        return { 255, 255, 255 } -- Default white for unknown types
    end
end

function ClientSend.sendTyping(author, type)
    if not isClient() then return end
    ClientSendCommand('Typing', {
        author = author,
        type = type,
    })
end

function ClientSend.sendAskSandboxVars()
    if not isClient() then return end
    ClientSendCommand('AskSandboxVars', {})
end

function ClientSend.sendMuteRadio(radio, state)
    if not isClient() then return end
    -- If "radioOrPart" is actually a VehiclePart (the 'Radio' part from the car)
    if instanceof(radioOrPart, "VehiclePart") then
        local vehicle = radioOrPart:getVehicle()
        if not vehicle then
            print("TICS error: sendMuteRadio given a part with no vehicle!")
            return
        end
        ClientSendCommand("MuteVehicleRadio", {
            vehicleId = vehicle:getId(),
            mute = state
        })
        return
    end

    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('TICS error: ClientSend.sendMuteRadio: no radioData found')
        return
    end
    if radioData:isIsoDevice() then
        ClientSendCommand('MuteSquareRadio', {
            mute = state,
            x = radio:getX(),
            y = radio:getY(),
            z = radio:getZ(),
        })
    elseif instanceof(radio, 'Radio') then -- is an inventoryItem radio
        local id = radio:getID()
        local player = getPlayer()
        local primary = player:getPrimaryHandItem()
        local secondary = player:getSecondaryHandItem()
        local beltType = nil
        if (primary == nil or primary:getID() ~= id)
                and (secondary == nil or secondary:getID() ~= id)
        then
            -- the ID is unreliable for non-in-hand items so we're going with the type
            -- and pray to find the right radio, or (un)mute the wrong one...
            beltType = radio:getType()
        end
        if id == nil then
            print('TICS error: ClientSend.sendMuteRadio: no id found')
            return
        end
        ClientSendCommand('MuteInHandRadio', {
            mute = state,
            id = id,
            belt = beltType,
            player = getPlayer():getUsername(),
        })
    end
end

function ClientSend.sendVehicleRadioState(part)
    if not instanceof(part, "VehiclePart") then
        print("TICS ERROR: sendVehicleRadioState called on non-VehiclePart:", tostring(part))
        return
    end

    local radioData = part:getDeviceData()
    if not radioData then
        print("TICS ERROR: VehiclePart has no device data.")
        return
    end

    ClientSendCommand("GiveVehicleRadioState", {
        vehicleId  = part:getVehicle():getId(),
        turnedOn   = radioData:getIsTurnedOn(),
        mute       = radioData:getMicIsMuted(),
        volume     = radioData:getDeviceVolume(),
        frequency  = radioData:getChannel()
    })
end

function ClientSend.sendChangeName(fullName) -- Sending ChangeName to server
    ClientSendCommand('ChangeName', { fullName = fullName }) -- Send fullName as fullName
end

-- only for belt items
function ClientSend.sendGiveRadioState(radio)
    if not isClient() then return end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('TICS error: ClientSend.sendTellRadioState: no radioData found')
        return
    end

    if instanceof(radio, 'Radio') then -- is an inventoryItem radio
        local player = getPlayer()
        local primary = player:getPrimaryHandItem()
        local secondary = player:getSecondaryHandItem()
        local beltType = nil
        local id = radio:getID()
        -- is not in-hand (so the server is not sync with it already)
        if (primary == nil or primary:getID() ~= id)
                and (secondary == nil or secondary:getID() ~= id)
        then
            -- the ID is unreliable for non-in-hand items so we're going with the type
            -- and pray to find the right radio, or sync the wrong one...
            beltType = radio:getType()

            ClientSendCommand('GiveBeltRadioState', {
                belt = beltType,
                player = getPlayer():getUsername(),
                turnedOn = radioData:getIsTurnedOn(),
                mute = radioData:getMicIsMuted(),
                volume = radioData:getDeviceVolume(),
                frequency = radioData:getChannel(),
                battery = radioData:getPower(),
                headphone = radioData:getHeadphoneType(),
                isTwoWay = radioData:getIsTwoWay(),
                transmitRange = radioData:getTransmitRange(),
            })
        end
    end
end

function ClientSend.sendAskRadioState(radio)
    if not isClient() then return end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('TICS error: ClientSend.sendAskRadioState: no radioData found')
        return
    end
    if radioData:isIsoDevice() then
        ClientSendCommand('AskSquareRadioState', {
            x = radio:getX(),
            y = radio:getY(),
            z = radio:getZ(),
        })
    elseif instanceof(radio, 'Radio') then -- is an inventoryItem radio
        local id = radio:getID()
        local player = getPlayer()
        local primary = player:getPrimaryHandItem()
        local secondary = player:getSecondaryHandItem()
        local beltType = nil
        if (primary == nil or primary:getID() ~= id)
                and (secondary == nil or secondary:getID() ~= id)
        then
            -- the ID is unreliable for non-in-hand items so we're going with the type
            -- and pray to find the right radio, or (un)mute the wrong one...
            beltType = radio:getType()
        end
        if id == nil then
            print('TICS error: ClientSend.sendAskRadioState: no id found')
            return
        end
        ClientSendCommand('AskInHandRadioState', {
            id = id,
            belt = beltType,
            player = getPlayer():getUsername(),
        })
    end
end

function ClientSend.sendKnownAvatars(knownAvatars)
    ClientSendCommand('KnownAvatars', {
        avatars = knownAvatars,
    })
end

function ClientSend.sendAvatarRequest(avatarRequest)
    ClientSendCommand('AvatarRequest', avatarRequest)
end

function ClientSend.sendApprovePendingAvatar(username, firstName, lastName, checksum)
    ClientSendCommand('ApproveAvatar', {
        username = username,
        firstName = firstName,
        lastName = lastName,
        checksum = checksum,
    })
end

function ClientSend.sendRejectPendingAvatar(username, firstName, lastName, checksum)
    ClientSendCommand('RejectAvatar', {
        username = username,
        firstName = firstName,
        lastName = lastName,
        checksum = checksum,
    })
end

function ClientSend.sendRoll(diceCount, diceType, addCount)
    ClientSendCommand('Roll', {
        diceCount = diceCount,
        diceType = diceType,
        addCount = addCount,
    })
end

function ClientSend.sendPlaySoundGlobal(soundFileName)
    if not isClient() then return end
    ClientSendCommand('PlaySoundGlobal', {
        soundFile = soundFileName
    })
end

function ClientSend.sendPlaySoundLocal(soundFileName)
    if not isClient() then return end
    ClientSendCommand('PlaySoundLocal', { soundFile = soundFileName })
end

function ClientSend.sendPlaySoundQuiet(soundFileName)
    if not isClient() then return end
    ClientSendCommand('PlaySoundQuiet', { soundFile = soundFileName })
end

function ClientSend.sendSetBio(bioText)
    if not isClient() then return end
    -- Sends the 'SetBio' command to the server with the bio text
    ClientSendCommand('SetBio', { bioText = bioText })
end

return ClientSend