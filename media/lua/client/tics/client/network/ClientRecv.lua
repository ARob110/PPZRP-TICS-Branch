local AvatarManager = require('tics/client/AvatarManager')
local Radio = require('tics/client/Radio')
local BioManager = require('tics/client/BioManager') -- Require the new manager
local BioMeta = require("tics/client/BioSync")

local ClientRecv = {}

ClientRecv['ChatMessage'] = function(args)
    -- Extract both colors explicitly
    local nameColor = args['nameColor']
    --local textColor = args['textColor']
    -- Pass them to onMessagePacket
    ISChat.onMessagePacket(args['type'], args['author'], args['characterName'],
            args['message'], args['language'], nameColor, nil, args['hideInChat'],
            args['target'], false, args['pitch'], args['disableVerb'])
end

ClientRecv['RadioMessage'] = function(args)
    -- Extract both colors explicitly
    local nameColor = args['nameColor']
    local textColor = args['textColor']
    -- Pass them to onRadioPacket
    ISChat.onRadioPacket(
            args['type'], args['author'], args['characterName'], args['message'], args['language'],
            nameColor, textColor, args['radios'], args['pitch'], args['disableVerb'])
end

ClientRecv['RadioEmittingMessage'] = function(args)
    -- Extract both colors explicitly
    local nameColor = args['nameColor']
    local textColor = args['textColor']
    -- Pass them to onRadioEmittingPacket
    ISChat.onRadioEmittingPacket(
            args['type'], args['author'], args['characterName'], args['message'], args['language'],
            nameColor, textColor, args['frequency'], args['disableVerb'])
end

ClientRecv['DiscordMessage'] = function(args)
    ISChat.onDiscordPacket(args['message'])
end

ClientRecv['Typing'] = function(args)
    ISChat.onTypingPacket(args['author'], args['type'])
end

ClientRecv['ChatError'] = function(args)
    ISChat.onChatErrorPacket(args['type'], args['message'])
end

ClientRecv['ServerPrint'] = function(args)
    print('Server: ' .. args.message)
end

ClientRecv['SendSandboxVars'] = function(args)
    ISChat.onRecvSandboxVars(args)
end

ClientRecv['RadioSquareState'] = function(args)
    Radio.SyncSquare(
            args.turnedOn, args.mute, args.power, args.volume,
            args.frequency, args.x, args.y, args.z)
end

ClientRecv['RadioInHandState'] = function(args)
    Radio.SyncInHand(
            args.id, args.turnedOn, args.mute, args.power, args.volume,
            args.frequency)
end

ClientRecv["SyncBio"] = function(args)
    local username = args.username
    local bio = args.bio
    
    -- Update the cache immediately
    BioMeta.Update(username, bio)
end

ClientRecv['ApprovedAvatar'] = function(args)
    local username  = args['username']
    local firstName = args['firstName']
    local lastName  = args['lastName']
    local extension = args['extension']
    local checksum  = args['checksum']
    local data      = args['data']

    if type(username) ~= 'string' then
        print('TICS error: ApprovedAvatar packet does not contain a valid "username"')
        return
    end
    if type(firstName) ~= 'string' then
        print('TICS error: ApprovedAvatar packet does not contain a valid "firstName"')
        return
    end
    if type(lastName) ~= 'string' then
        print('TICS error: ApprovedAvatar packet does not contain a valid "lastName"')
        return
    end
    if type(extension) ~= 'string' then
        print('TICS error: ApprovedAvatar packet does not contain a valid "extension"')
        return
    end
    if type(checksum) ~= 'number' then
        print('TICS error: ApprovedAvatar packet does not contain a valid "checksum"')
        return
    end
    if type(data) ~= 'table' then
        print('TICS error: ApprovedAvatar packet does not contain a valid "data"')
        return
    end

    AvatarManager:saveApprovedAvatar(username, firstName, lastName, extension, checksum, data)
end

ClientRecv['PendingAvatar'] = function(args)
    local username  = args['username']
    local firstName = args['firstName']
    local lastName  = args['lastName']
    local extension = args['extension']
    local checksum  = args['checksum']
    local data      = args['data']

    if type(username) ~= 'string' then
        print('TICS error: PendingAvatar packet does not contain a valid "username"')
        return
    end
    if type(firstName) ~= 'string' then
        print('TICS error: PendingAvatar packet does not contain a valid "firstName"')
        return
    end
    if type(lastName) ~= 'string' then
        print('TICS error: PendingAvatar packet does not contain a valid "lastName"')
        return
    end
    if type(extension) ~= 'string' then
        print('TICS error: PendingAvatar packet does not contain a valid "extension"')
        return
    end
    if type(checksum) ~= 'number' then
        print('TICS error: PendingAvatar packet does not contain a valid "checksum"')
        return
    end
    if type(data) ~= 'table' then
        print('TICS error: PendingAvatar packet does not contain a valid "data"')
        return
    end

    AvatarManager:savePendingAvatar(username, firstName, lastName, extension, checksum, data)
end

ClientRecv['AvatarProcessed'] = function(args)
    local username  = args['username']
    local firstName = args['firstName']
    local lastName  = args['lastName']
    local checksum  = args['checksum']

    if type(username) ~= 'string' then
        print('TICS error: PendingAvatar packet does not contain a valid "username"')
        return
    end
    if type(firstName) ~= 'string' then
        print('TICS error: PendingAvatar packet does not contain a valid "firstName"')
        return
    end
    if type(lastName) ~= 'string' then
        print('TICS error: PendingAvatar packet does not contain a valid "lastName"')
        return
    end
    if type(checksum) ~= 'number' then
        print('TICS error: PendingAvatar packet does not contain a valid "checksum"')
        return
    end
    AvatarManager:removeAvatarPending(username, firstName, lastName, checksum)
end

ClientRecv['RollResult'] = function(args)
    local username      = args['username']
    local characterName = args['characterName']
    local diceCount     = args['diceCount']
    local diceType      = args['diceType']
    local addCount      = args['addCount']
    local diceResults   = args['diceResults']
    local finalResult   = args['finalResult']

    if type(username) ~= 'string' then
        print('TICS error: RollResult packet does not contain a valid "username"')
        return
    end
    if type(characterName) ~= 'string' then
        print('TICS error: RollResult packet does not contain a valid "characterName"')
        return
    end
    if type(diceCount) ~= 'number' then
        print('TICS error: RollResult packet does not contain a valid "diceCount"')
        return
    end
    if type(diceType) ~= 'number' then
        print('TICS error: RollResult packet does not contain a valid "diceType"')
        return
    end
    if addCount ~= nil and type(addCount) ~= 'number' then
        print('TICS error: RollResult packet does not contain a valid "addCount"')
        return
    end
    if type(diceResults) ~= 'table' then
        print('TICS error: RollResult packet does not contain a valid "diceResults"')
        return
    end
    if type(finalResult) ~= 'number' then
        print('TICS error: RollResult packet does not contain a valid "finalResult"')
        return
    end
    ISChat.onDiceResult(username, characterName, diceCount, diceType, addCount, diceResults, finalResult)
end

ClientRecv["OverheadNameChange"] = function(args) -- Shows new name over player's head
    local onlineID     = args.onlineID
    local overheadName = args.overheadName
    if not onlineID or not overheadName then
        print("TICS error: OverheadNameChange packet missing data.")
        return
    end
    local targetPlayer = getPlayerByOnlineID(onlineID)
    if targetPlayer then
        targetPlayer:setName(overheadName)
        print("Updated overhead name to: " .. overheadName .. " for onlineID " .. onlineID)
    else
        print("TICS error: No player found with onlineID:", onlineID)
    end
end

ClientRecv['ChatInfoMessage'] = function(args)
    local message = args['message']
    if not message then
        print('TICS Client: ChatInfoMessage command received without message argument.')
        return
    end

    print('TICS Client: Received ChatInfoMessage: ' .. message) -- Client-side log

    ISChat.sendInfoToCurrentTab(message) -- ***Use ISChat.sendInfoToCurrentTab to display the message in TICS chat***
end

ClientRecv['PlaySoundClientSide'] = function(args)
    local soundFile = args['soundFile']
    if not soundFile then
        print('TICS Client: PlaySoundClientSide command received without message argument.')
        return
    end

    print('TICS Client: Playing sound client-side: ' .. soundFile)

    local emitter = getPlayer():getEmitter()              -- real BaseSoundEmitter
    local handle  = emitter:playSoundImpl(soundFile, nil)
    if ISChat.rememberSound then
        ISChat.rememberSound(handle, emitter, soundFile)
    end
end

ClientRecv['PlaySoundClientSideLocal'] = function(args)
    local soundFile = args['soundFile']
    if not soundFile then
        print('TICS Client: PlaySoundClientSideLocal called without soundFile.')
        return
    end

    print('TICS Client: playing sound *locally*: ' .. tostring(soundFile))

    local player = getPlayer()
    if player then
        -- we need the handle so /stopsound can kill it later
        local emitter = getPlayer():getEmitter()              -- real BaseSoundEmitter
        local handle  = emitter:playSoundImpl(soundFile, nil)

        -- register it in PandemSounds
        if ISChat.rememberSound then
            ISChat.rememberSound(handle, emitter, soundFile)
        end
    else
        print('TICS Client: couldn’t get player position to play local sound.')
    end
end

ClientRecv['PlaySoundClientSideQuiet'] = function(args)
    local soundFile = args['soundFile']
    local range     = args['range'] or 15      -- default 15 if not supplied

    if not soundFile then
        print('TICS Client: PlaySoundClientSideQuiet called without soundFile.')
        return
    end

    print('TICS Client: playing QUIET sound "' .. tostring(soundFile) ..
            '" (range ' .. range .. ').')

    local player = getPlayer()
    if player then
        local emitter = getPlayer():getEmitter()              -- real BaseSoundEmitter
        local handle  = emitter:playSoundImpl(soundFile, nil)

        -- store so /stopsound can find it
        if ISChat.rememberSound then
            ISChat.rememberSound(handle, emitter, soundFile)
        end
    else
        print('TICS Client: couldn’t get player position to play quiet sound.')
    end
end

ClientRecv["OverheadBioChange"] = function(args)
    local onlineID = args.onlineID
    local overheadName = args.overheadName
    if not onlineID or not overheadName then
        print("TICS error: OverheadBioChange packet missing data.")
        return
    end
    local targetPlayer = getPlayerByOnlineID(onlineID)
    if targetPlayer then
        -- Use setDisplayName to update the overhead name correctly
        targetPlayer:setDisplayName(overheadName)
        print("Updated overhead name to: " .. overheadName .. " for onlineID " .. onlineID)
    else
        print("TICS error: No player found with onlineID:", onlineID)
    end
end

-- In ClientRecv.lua
ClientRecv['ReceiveKitItems'] = function(args)
    local player = getPlayer()
    local inv = player:getInventory()

    for i = 1, 10 do
        inv:AddItem("Dire.MoneyHundred")
    end
    inv:AddItem("Dire.DriversLicense")
    inv:AddItem("Base.Wallet4")
    inv:AddItem("Base.Bandage")
    inv:AddItem("Base.Bandage")
    inv:AddItem("Base.SkillRecoveryBoundJournal")
    inv:AddItem("Base.PBBaseballBatAlu")
    inv:AddItem("Base.Pencil")
    inv:AddItem("Base.Scissors")
    inv:AddItem("Base.Needle")
    inv:AddItem("Base.Thread")
    inv:AddItem("Base.Crisps3")
    inv:AddItem("AuthenticZClothing.Bag_Schoolbag_Spiffo2_Tier_1")

    -- Force a UI refresh
    player:getInventory():setDrawDirty(true)
end

function OnServerCommand(module, command, args)
    if module == 'TICS' and ClientRecv[command] then
        ClientRecv[command](args)
    end
end

Events.OnServerCommand.Add(OnServerCommand)

return ClientRecv