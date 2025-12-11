local Character    = require('tics/shared/utils/Character')
local Logger       = require('tics/server/Logger')
local RadioManager = require('tics/server/radio/RadioManager')
local ServerSend   = require('tics/server/network/ServerSend')
local StringParser = require('tics/shared/utils/StringParser')
local World        = require('tics/shared/utils/World')
local BioServer = require("tics/BioServer")

local ChatMessage  = {}

local function PlayersDistance(source, target)
    local stupidDistance = source:DistTo(target:getX(), target:getY())
    local accurateDistance = math.max(stupidDistance - 1, 0)
    return math.floor(accurateDistance + 0.5)
end

local function GetColorFromString(colorString)
    local defaultColor = { 255, 0, 255 }
    local rgb = StringParser.hexaStringToRGB(colorString)
    if rgb == nil then
        print('TICS error: invalid color string: "' .. colorString .. '"')
        return defaultColor
    end
    return rgb
end

local function GetColorSandbox(name)
    local colorString = SandboxVars.TICS[name .. 'Color']
    return GetColorFromString(colorString)
end

ChatMessage.MessageTypeSettings = nil

local function SetMessageTypeSettings()
    ChatMessage.MessageTypeSettings = {
        ['markdown'] = {
            ['italic'] = {
                ['color'] = GetColorSandbox('MarkdownOneAsterisk')
            },
            ['bold'] = {
                ['color'] = GetColorSandbox('MarkdownTwoAsterisks')
            },
        },
        ['whisper'] = {
            ['range'] = SandboxVars.TICS.WhisperRange,
            ['zombieRange'] = SandboxVars.TICS.WhisperZombieRange,
            ['enabled'] = SandboxVars.TICS.WhisperEnabled,
            ['color'] = GetColorSandbox('Whisper'),
            ['radio'] = true,
            ['aliveOnly'] = true,
            ['bubble'] = true,
        },
        ['low'] = {
            ['range'] = SandboxVars.TICS.LowRange,
            ['zombieRange'] = SandboxVars.TICS.LowZombieRange,
            ['enabled'] = SandboxVars.TICS.LowEnabled,
            ['color'] = GetColorSandbox('Low'),
            ['radio'] = true,
            ['aliveOnly'] = true,
            ['bubble'] = true,
        },
        ['say'] = {
            ['range'] = SandboxVars.TICS.SayRange,
            ['zombieRange'] = SandboxVars.TICS.SayZombieRange,
            ['enabled'] = SandboxVars.TICS.SayEnabled,
            ['color'] = GetColorSandbox('Say'),
            ['radio'] = true,
            ['aliveOnly'] = true,
            ['bubble'] = true,
        },
        ['yell'] = {
            ['range'] = SandboxVars.TICS.YellRange,
            ['zombieRange'] = SandboxVars.TICS.YellZombieRange,
            ['enabled'] = SandboxVars.TICS.YellEnabled,
            ['color'] = GetColorSandbox('Yell'),
            ['radio'] = true,
            ['aliveOnly'] = true,
            ['bubble'] = true,
        },
        ['pm'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.TICS.PrivateMessageEnabled,
            ['color'] = GetColorSandbox('PrivateMessage'),
            ['radio'] = false,
            ['aliveOnly'] = true,
            ['bubble'] = false,
        },
        ['me'] = {
            ['range'] = SandboxVars.TICS.MeRange,
            ['zombieRange'] = 0,
            ['enabled'] = SandboxVars.TICS.MeEnabled,
            ['color'] = GetColorSandbox('Me'),
            ['radio'] = false,
            ['aliveOnly'] = true,
            ['bubble'] = true,
        },
        ['do'] = {
            ['range'] = SandboxVars.TICS.DoRange,
            ['zombieRange'] = 0,
            ['enabled'] = SandboxVars.TICS.DoEnabled,
            ['color'] = GetColorSandbox('Do'),
            ['radio'] = false,
            ['aliveOnly'] = true,
            ['bubble'] = true,
            ['adminOnly'] = SandboxVars.TICS.DoAdminOnly,
        },
        ['faction'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.TICS.FactionMessageEnabled,
            ['color'] = GetColorSandbox('FactionMessage'),
            ['radio'] = false,
            ['aliveOnly'] = true,
            ['bubble'] = false,
        },
        ['factionooc'] = {
            ['range'] = -1, -- Global like regular faction
            ['zombieRange'] = -1, -- No zombie attraction
            -- Enabled if regular faction chat is enabled
            ['enabled'] = SandboxVars.TICS.FactionMessageEnabled,
            -- Use OOC color to visually distinguish it
            ['color'] = GetColorSandbox('OutOfCharacterMessage'),
            ['radio'] = false,
            ['aliveOnly'] = true,
            ['bubble'] = false, -- No bubble
            ['adminOnly'] = false,
        },
        ['safehouse'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.TICS.SafeHouseMessageEnabled,
            ['color'] = GetColorSandbox('SafeHouseMessage'),
            ['radio'] = false,
            ['aliveOnly'] = true,
            ['bubble'] = false,
        },
        ['general'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.TICS.GeneralMessageEnabled,
            ['color'] = GetColorSandbox('GeneralMessage'),
            ['radio'] = false,
            ['aliveOnly'] = true,
            ['discord'] = SandboxVars.TICS.GeneralDiscordEnabled,
            ['bubble'] = false,
        },
        ['admin'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.TICS.AdminMessageEnabled,
            ['color'] = GetColorSandbox('AdminMessage'),
            ['radio'] = false,
            ['aliveOnly'] = false,
            ['bubble'] = false,
            ['adminOnly'] = true,
        },
        ['ooc'] = {
            ['range'] = SandboxVars.TICS.OutOfCharacterMessageRange,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.TICS.OutOfCharacterMessageEnabled,
            ['color'] = GetColorSandbox('OutOfCharacterMessage'),
            ['radio'] = false,
            ['bubble'] = true,
        },
        ['server'] = {
            ['color'] = { 255, 86, 64 },
        },
        ['scriptedRadio'] = {
            ['enabled'] = true,
            ['color'] = GetColorFromString(SandboxVars.TICS.RadioColor),
        },
        ['options'] = {
            ['showCharacterName'] = SandboxVars.TICS.ShowCharacterName,
            ['boredomReduction'] = SandboxVars.TICS.BoredomReduction,
            ['languages'] = SandboxVars.TICS.Languages,
            ['verb'] = SandboxVars.TICS.VerbEnabled,
            ['capitalize'] = SandboxVars.TICS.Capitalize,
            ['bubble'] = {
                ['timer'] = SandboxVars.TICS.BubbleTimerInSeconds,
                ['opacity'] = SandboxVars.TICS.BubbleOpacity,
            },
            ['radio'] = {
                ['discord'] = SandboxVars.TICS.RadioDiscordEnabled,
                ['frequency'] = SandboxVars.TICS.RadioDiscordFrequency,
                ['soundMaxRange'] = SandboxVars.TICS.RadioSoundMaxRange,
            },
            ['hideCallout'] = SandboxVars.TICS.HideCallout,
            ['isVoiceEnabled'] = SandboxVars.TICS.VoiceEnabled,
            ['portrait'] = SandboxVars.TICS.BubblePortrait,
        },
        ['globalevent'] = {
            range       = -1,              -- infinite range, or set your own
            zombieRange = 0,
            enabled     = true,            -- must be true or it won't work
            color       = { 255, 165, 0 }, -- ORANGE color
            radio       = false,
            aliveOnly   = false,
            bubble      = false,
            adminOnly   = true,            -- if you only want admins to use it
        },
        ['localevent'] = {
            range       = 60,   -- infinite range
            zombieRange = 0,
            enabled     = true,
            color       = { 255, 0, 0 },
            radio       = false,
            aliveOnly   = false,
            bubble      = false,
            adminOnly = true,
        },
        ['whisperme'] = {
            range       = SandboxVars.TICS.WhisperRange,  -- same range as /whisper
            zombieRange = 0,
            enabled     = true,
            color       = GetColorSandbox('Me'),         -- or pick your own color
            radio       = false,
            aliveOnly   = true,
            bubble      = true,
        },

        ['melow'] = {
            range       = SandboxVars.TICS.LowRange,      -- same range as /low
            zombieRange = 0,
            enabled     = true,
            color       = GetColorSandbox('Me'),
            radio       = false,
            aliveOnly   = true,
            bubble      = true,
        },

        ['melong'] = {
            range       = 20,     -- same range as /yell
            zombieRange = 0,
            enabled     = true,
            color       = GetColorSandbox('Me'),
            radio       = false,
            aliveOnly   = true,
            bubble      = true,
        },
        ['dolow'] = {
            range = SandboxVars.TICS.LowRange,
            zombieRange = 0,
            enabled = true,
            color = GetColorSandbox('Do'),  -- or a custom color
            radio = false,
            aliveOnly = true,
            bubble = true,
            adminOnly = SandboxVars.TICS.DoAdminOnly,
        },

        ['dolong'] = {
            range = 60,
            zombieRange = 0,
            enabled = true,
            color = GetColorSandbox('Do'),
            radio = false,
            aliveOnly = true,
            bubble = true,
            adminOnly = false,
        },

        ['admindolong'] = {
            range       = 60,
            zombieRange = 0,
            enabled     = true,
            color       = GetColorSandbox('Do'), -- or pick any color
            radio       = false,
            aliveOnly   = true,
            bubble      = true,
            adminOnly   = true,  -- restrict to admin
        },
    }
end

local AuthorHasAccessByType = {
    ['whisper']   = function(author, args, sendError) return true end,
    ['low']       = function(author, args, sendError) return true end,

    ['say']       = function(author, args, sendError) return true end,

    ['yell']      = function(author, args, sendError) return true end,
    ['pm']        = function(author, args, sendError)
        if args.target == nil or World.getPlayerByUsername(args.target) == nil then
            if args.target ~= nil then
                if sendError then
                    ServerSend.ChatErrorMessage(author, args.type, 'unknown player "' .. args.target .. '".')
                end
            else
                print('TICS error: Received a private message from "' ..
                        author:getUsername() .. '" without a contact name')
            end
            return false
        end
        return true
    end,
    ['faction']   = function(author, args, sendError)
        local hasFaction = Faction.getPlayerFaction(author) ~= nil
        if not hasFaction and sendError then
            ServerSend.ChatErrorMessage(author, args.type, 'you are not part of a faction.')
        end
        return hasFaction
    end,
    ['safehouse'] = function(author, args, sendError)
        local hasSafeHouse = SafeHouse.hasSafehouse(author) ~= nil
        if not hasSafeHouse and sendError then
            ServerSend.ChatErrorMessage(author, args.type, 'you are not part of a safe house.')
        end
        return hasSafeHouse
    end,
    ['general']   = function(author, args, sendError) return true end,
    ['admin']     = function(author, args, sendError)
        return author:getAccessLevel() == 'Admin'
    end,
    ['ooc']       = function(author, args, sendError) return true end,
    ['me']        = function(author, args, sendError) return true end,
    ['do']        = function(author, args, sendError)
        if ChatMessage.MessageTypeSettings and
                (not ChatMessage.MessageTypeSettings['do']['adminOnly'] or
                        author:getAccessLevel() == 'Admin' or
                        author:getAccessLevel() == 'Moderator')
        then
            return true
        else
            if sendError then
                ServerSend.ChatErrorMessage(author, args.type, 'requires admin privileges.')
            end
            return false
        end
    end,
    ['factionooc'] = function(author, args, sendError)
        local hasFaction = Faction.getPlayerFaction(author) ~= nil
        if not hasFaction and sendError then
            ServerSend.ChatErrorMessage(author, args.type, 'you are not part of a faction.')
        end
        return hasFaction
    end,
    ['localevent'] = function(author, args, sendError)
        if ChatMessage.MessageTypeSettings and ChatMessage.MessageTypeSettings['localevent'].adminOnly then
            if author:getAccessLevel() == 'Admin' then
                return true
            else
                if sendError then
                    ServerSend.ChatErrorMessage(author, args.type, "requires admin privileges.")
                end
                return false
            end
        end
        return true
    end,
    ['globalevent'] = function(author, args, sendError)
        return author:getAccessLevel() == 'Admin' end,
    ['melow'] = function(author, args, sendError) return true end,
    ['melong'] = function(author, args, sendError) return true end,
    ['whisperme'] = function(author, args, sendError) return true end,
    ['dolow'] = function(author, args, sendError) return true end,
    ['dolong'] = function(author, args, sendError) return true end,
    ['admindolong'] = function(author, args, sendError)
        -- Must be admin
        if author:getAccessLevel() == "Admin" then
            return true
        end
        if sendError then
            ServerSend.ChatErrorMessage(author, args.type, "This command requires admin privileges.")
        end
        return false
    end,
}

local ListenerHasAccessByType = {
    ['whisper']   = function(author, player, args) return true end,
    ['low']       = function(author, player, args) return true end,

    ['say']       = function(author, player, args) return true end,

    ['yell']      = function(author, player, args) return true end,
    ['pm']        = function(author, player, args)
        return args.target ~= nil and args.author ~= nil and
                (player:getUsername():lower() == args.target:lower() or player:getUsername():lower() == args.author:lower())
    end,
    ['faction']   = function(author, player, args)
        local authorFaction = Faction.getPlayerFaction(author)
        local playerFaction = Faction.getPlayerFaction(player)
        return playerFaction ~= nil and authorFaction ~= nil and playerFaction:getName() == authorFaction:getName()
    end,
    ['safehouse'] = function(author, player, args)
        local playerSafeHouse = SafeHouse.hasSafehouse(player)
        local authorSafeHouse = SafeHouse.hasSafehouse(author)
        return playerSafeHouse ~= nil and authorSafeHouse ~= nil and
                playerSafeHouse:getTitle() == authorSafeHouse:getTitle()
    end,
    ['factionooc'] = function(author, player, args)
        local authorFaction = Faction.getPlayerFaction(author)
        local playerFaction = Faction.getPlayerFaction(player)
        -- Check both are in a faction AND the factions are the same
        return playerFaction ~= nil and authorFaction ~= nil and playerFaction:getName() == authorFaction:getName()
    end,
    ['general']   = function(author, player, args) return true end,
    ['admin']     = function(author, player, args)
        return player:getAccessLevel() == 'Admin'
    end,
    ['ooc']       = function(author, player, args) return true end,
    ['me']        = function(author, args, sendError) return true end,
    ['do']        = function(author, args, sendError) return true end,
    ['melow']     = function(author, player, args) return true end,
    ['melong']    = function(author, player, args) return true end,
    ['whisperme'] = function(author, player, args) return true end,
    ['dolow']     = function(author, player, args) return true end,
    ['dolong']    = function(author, player, args) return true end,
    ['localevent']    = function(author, player, args) return true end,
    ['globalevent']   = function(author, player, args) return true end,
    ['admindolong'] = function(author, player, args) return true end,

}

local SandboxVarsCopy = nil
local function CopyTicsSandboxVars()
    SandboxVarsCopy = {}
    for key, var in pairs(SandboxVars.TICS) do
        SandboxVarsCopy[key] = var
    end
end

local function HasTicsSandboxVarsChanged()
    if SandboxVarsCopy == nil then
        return false
    end
    for key, var in pairs(SandboxVars.TICS) do
        if SandboxVarsCopy[key] ~= var then
            return true
        end
    end
    return false
end

function ChatMessage.ChangeName(player, fullName)
    -- Validate the incoming name (Keep this section as it is)
    if not fullName or #fullName == 0 then
        ServerSend.ChatErrorMessage(player, nil, "Invalid name format.")
        return
    end
    if #fullName > 30 then
        ServerSend.ChatErrorMessage(player, nil, "Name length is too long (max 30 characters).")
        return
    end
    if not fullName:match("^[%a%d%s%-%(%)%[%]/]+$") then
        ServerSend.ChatErrorMessage(player, nil, "Name is invalid.");
        return
    end

    -- Update the player's descriptor (server-side) (Keep this section as it is)
    local descriptor = player:getDescriptor()
    if not descriptor then
        print("TICS error: player descriptor is nil.")
        return
    end
    local nameParts = luautils.split(fullName, " ", 2)
    local forename = nameParts[1] or fullName
    local surname = nameParts[2] or ""
    descriptor:setForename(forename)
    if descriptor.setSurname then
        descriptor:setSurname(surname)
    else
        print("DEBUG: descriptor.setSurname is nil; surname not updated.")
    end

    -- **[NEW SECTION - Bio Integration]**
    -- Construct the new overhead name (now including bio if set)
    local newName = fullName -- This is the base name from /name

    -- Retrieve the bio line from ModData (if it exists)
    local bioLine = player:getModData()["BioLine"] or "" -- Get bio, default to empty string

    local spacer = "   " -- Adjust spacing as needed
    local newOverheadName = newName .. spacer .. "\n" .. bioLine -- Combine name and bio

    ServerSend.ChatInfoMessage(player, "Your name has been changed to " .. newName .. ".")
    print("Player " .. player:getUsername() .. " changed their name to " .. newName)

    -- **[MODIFIED SECTION - Command and Command Name]**
    -- Broadcast OverheadBioChange command (use OverheadBioChange, not OverheadNameChange)
    local playerOnlineID = player:getOnlineID()
    local onlinePlayers = getOnlinePlayers()
    for i = 0, onlinePlayers:size() - 1 do
        local targetPlayer = onlinePlayers:get(i)
        ServerSend.Command(targetPlayer, "OverheadBioChange", { -- **Use OverheadBioChange**
            onlineID = playerOnlineID,
            overheadName = newOverheadName -- **Send the COMBINED name**
        })
    end
end




local function DetectMessageTypeSettingsUpdate()
    if ChatMessage.MessageTypeSettings == nil then
        return
    end
    if SandboxVarsCopy == nil then
        CopyTicsSandboxVars()
        return
    end
    if HasTicsSandboxVarsChanged() then
        CopyTicsSandboxVars()
        SetMessageTypeSettings()
        World.forAllPlayers(function(player)
            ServerSend.Command(player, 'SendSandboxVars', ChatMessage.MessageTypeSettings)
        end)
    end
end

local function GetPlayerRadio(player)
    local radio = Character.getFirstHandItemByGroup(player, 'Radio')
    if radio == nil then
        local attachedRadio = Character.getFirstAttachedItemByGroup(player, 'Radio')
        if attachedRadio then
            radio = RadioManager:getFakeBeltRadio(player)
        end
    end
    return radio
end

local function GetRangeForMessageType(type)
    local messageSettings = ChatMessage.MessageTypeSettings[type]
    if messageSettings ~= nil then
        return messageSettings['range']
    end
    error('unknown message type "' .. type .. '"')
    return nil
end

local function IsAllowedToTalk(author, args, sendError)
    if args.type == nil then
        print('TICS error: args.type is null')
        return false
    end
    if AuthorHasAccessByType[args.type] == nil then
        print('TICS error: AuthorHasAccessByType has no method for type ' .. args.type)
        return false
    end
    if ChatMessage.MessageTypeSettings[args.type] == nil then
        print('TICS error: ChatMessage.MessageTypeSettings of ' .. args.type .. ' is null')
        return false
    end
    if AuthorHasAccessByType[args.type] == nil then
        print('TICS error: AuthorHasAccessByType has no method for ' .. args.type)
        return false
    end
    return ChatMessage.MessageTypeSettings[args.type]['enabled'] == true
            and (not ChatMessage.MessageTypeSettings[args.type]['aliveOnly'] or author:getBodyDamage():getHealth() > 0)
            and AuthorHasAccessByType[args.type](author, args, sendError)
end

local function IsAllowedToListen(author, player, args)
    if ListenerHasAccessByType[args.type] == nil then
        print('TICS error: IsAllowedToListen: MessageHasAccessByType has no method for ' .. args.type)
        return false
    end
    return ListenerHasAccessByType[args.type](author, player, args)
end

local function IsInRadioEmittingRange(radioEmitters, receiver)
    if radioEmitters == nil then
        return false, -1
    end
    for _, radioEmitter in pairs(radioEmitters) do
        local radioData = radioEmitter:getDeviceData()
        if radioData ~= nil then
            local transmitRange = radioData:getTransmitRange()
            local distance = World.distanceManhatten(radioEmitter, receiver)
            if distance <= transmitRange then
                return true, distance
            end
        end
    end
    return false, -1
end

local function GetSquaresRadios(player, args, radioFrequencies, range)
    if ChatMessage.MessageTypeSettings == nil then
        print('TICS error: GetSquaresRadios: tried to get radios before server settings were initialized')
        return {}, false
    end
    local maxSoundRange = ChatMessage.MessageTypeSettings['options']['radio']['soundMaxRange']
    local radiosByFrequency = {}
    local radios = World.getItemsInRangeByGroup(player, range, 'IsoRadio')
    local found = false
    for _, radio in pairs(radios) do
        local pos = {
            x = radio:getX(),
            y = radio:getY(),
            z = radio:getZ(),
        }
        -- radio:getSquare() is unreliable
        local radioSquare = getSquare(radio:getX(), radio:getY(), radio:getZ())
        RadioManager:subscribeSquare(radioSquare)
        local radioData = radio:getDeviceData()
        if radioData ~= nil then
            local frequency = radioData:getChannel()
            local turnedOn = radioData:getIsTurnedOn()
            local volume = radioData:getDeviceVolume()
            if volume == nil then
                volume = 0
            end
            volume = math.abs(volume)
            local isInRange, distance = IsInRadioEmittingRange(radioFrequencies[frequency], radio)
            if turnedOn and frequency ~= nil and radioFrequencies[frequency] ~= nil
                    and isInRange
                    and Character.canHearRadioSound(player, radio, radioData, maxSoundRange)
            then
                if radiosByFrequency[frequency] == nil then
                    radiosByFrequency[frequency] = {}
                end
                table.insert(radiosByFrequency[frequency], {
                    position = pos,
                    distance = distance
                })
                found = true
            end
        end
    end
    return radiosByFrequency, found
end

local function GetPlayerRadios(player, args, radioFrequencies, range)
    local radiosByFrequency = {}
    local radio = GetPlayerRadio(player)
    local found = false
    if radio == nil then
        return radiosByFrequency
    end
    local radioData = radio and radio:getDeviceData() or nil
    if radioData then
        local frequency = radioData:getChannel()
        local isInRange, distance = IsInRadioEmittingRange(radioFrequencies[frequency], player)
        if radioData:getIsTurnedOn()
                and frequency ~= nil and radioFrequencies[frequency] ~= nil
                and isInRange
        then
            if radiosByFrequency[frequency] == nil then
                radiosByFrequency[frequency] = {}
            end
            table.insert(radiosByFrequency[frequency], {
                username = player:getUsername(),
                distance = distance
            })
            found = true
        end
    end
    return radiosByFrequency, found
end

local function GetVehiclesRadios(player, args, radioFrequencies, range)
    if ChatMessage.MessageTypeSettings == nil then
        print('TICS error: GetVehiclesRadios: tried to get radios before server settings were initialized')
        return {}, false
    end
    local maxSoundRange = ChatMessage.MessageTypeSettings['options']['radio']['soundMaxRange']
    local vehiclesByFrequency = {}
    local vehicles = World.getVehiclesInRange(player, range)
    local found = false
    for _, vehicle in pairs(vehicles) do
        local radio = vehicle:getPartById('Radio')
        if radio ~= nil then
            RadioManager:subscribeVehicle(vehicle)
            local radioData = radio:getDeviceData()
            if radioData ~= nil then
                local frequency = radioData:getChannel()
                local isInRange, distance = IsInRadioEmittingRange(radioFrequencies[frequency], vehicle)
                if radioData:getIsTurnedOn()
                        and frequency ~= nil and radioFrequencies[frequency] ~= nil
                        and isInRange
                        and Character.canHearRadioSound(player, vehicle, radioData, maxSoundRange)
                then
                    if vehiclesByFrequency[frequency] == nil then
                        vehiclesByFrequency[frequency] = {}
                    end
                    table.insert(vehiclesByFrequency[frequency], {
                        key = vehicle:getKeyId(),
                        distance = distance
                    })
                    found = true
                end
            end
        end
    end
    return vehiclesByFrequency, found
end

local function SendRadioPackets(author, player, args, sourceRadioByFrequencies)
    local range = ChatMessage.MessageTypeSettings['options']['radio']['soundMaxRange']
    local squaresRadios, squaresRadiosFound = GetSquaresRadios(player, args, sourceRadioByFrequencies, range)
    local playersRadios, playersRadiosFound = GetPlayerRadios(player, args, sourceRadioByFrequencies, range)
    local vehiclesRadios, vehiclesRadiosFound = GetVehiclesRadios(player, args, sourceRadioByFrequencies, range)

    if not squaresRadiosFound and not playersRadiosFound and not vehiclesRadiosFound then
        return
    end

    local targetRadiosByFrequencies = {}
    for frequency, _ in pairs(sourceRadioByFrequencies) do
        targetRadiosByFrequencies[frequency] = {
            squares = squaresRadios[frequency] or {},
            players = playersRadios[frequency] or {},
            vehicles = vehiclesRadios[frequency] or {},
        }
        RadioManager:makeNoise(frequency, range)
    end

    ServerSend.Command(player, 'RadioMessage', {
        author = args.author,
        characterName = args.characterName,
        message = args.message,
        -- color = args.color, -- DEPRECATED, use nameColor and textColor
        nameColor = args.nameColor,   -- Add nameColor
        textColor = args.textColor,   -- Add textColor
        type = args.type,
        radios = targetRadiosByFrequencies,
        pitch = args.pitch,
        disableVerb = args.disableVerb,
        language = args.language,
    })
end


local function GetEmittingRadios(player, packetType, messageType, range)
    local radioEmission = false
    local radioFrequencies = {}
    if ChatMessage.MessageTypeSettings[messageType] and ChatMessage.MessageTypeSettings[messageType]['radio'] == true
            and packetType == 'ChatMessage' and range > 0
    then
        local radios = World.getItemsInRangeByGroup(player, range, 'IsoRadio')
        for _, radio in pairs(radios) do
            local radioData = radio:getDeviceData()
            if radioData ~= nil then
                local frequency = radioData:getChannel()
                if radioData:getIsTwoWay() and radioData:getIsTurnedOn()
                        and not radioData:getMicIsMuted() and frequency ~= nil
                then
                    if radioFrequencies[frequency] == nil then
                        radioFrequencies[frequency] = {}
                    end
                    table.insert(radioFrequencies[frequency], radio)
                    radioEmission = true
                end
            end
        end
        local radio = GetPlayerRadio(player)
        local radioData = radio and radio:getDeviceData() or nil
        if radioData then
            local frequency = radioData:getChannel()
            if radioData and radioData:getIsTwoWay() and radioData:getIsTurnedOn()
                    and not radioData:getMicIsMuted() and frequency ~= nil
            then
                if radioFrequencies[frequency] == nil then
                    radioFrequencies[frequency] = {}
                end
                table.insert(radioFrequencies[frequency], radio)
                radioEmission = true
            end
        end
    end
    return radioEmission, radioFrequencies
end

local function SendRadioEmittingPackets(player, args, radioFrequencies)
    for frequency, _ in pairs(radioFrequencies) do
        if ChatMessage.MessageTypeSettings and ChatMessage.MessageTypeSettings['options']['radio']['discord']
                and frequency == ChatMessage.MessageTypeSettings['options']['radio']['frequency']
        then
            ServerSend.Command(player, 'DiscordMessage', {
                message = args.message,
            })
        end
        ServerSend.Command(player, 'RadioEmittingMessage', {
            type = args.type,
            author = args.author,
            characterName = args.characterName,
            message = args.message,
            -- color = args.color, -- DEPRECATED, use nameColor and textColor
            nameColor = args.nameColor,   -- Add nameColor
            textColor = args.textColor,   -- Add textColor
            frequency = frequency,
            disableVerb = args.disableVerb,
            language = args.language,
        })
    end
end

local function IsHammerOn(player)
    return player:getModData() and player:getModData()['_hammer'] == 'on'
end

-- In ChatMessage.lua
function ChatMessage.ProcessMessage(player, args, packetType, sendError)
    if args._echo then args._echo = nil end      -- swallow helper packets
    if args.type == nil then
        print('TICS error: Received a message from "' .. player:getUsername() .. '" with no type') -- Keep actual errors
        return
    end

    if not IsAllowedToTalk(player, args, sendError) then
        return
    end

    if args.type == 'general' and
            ChatMessage.MessageTypeSettings and ChatMessage.MessageTypeSettings['general']['discord'] and
            packetType ~= 'Typing'
    then
        ServerSend.Command(player, 'DiscordMessage', {
            message = args.message,
        })
    end

    local range = GetRangeForMessageType(args.type)
    if range == nil then
        error('TICS error: No range for message type "' .. args.type .. '".') -- Keep actual errors
        return
    end

    local hammerActive = IsHammerOn(player)

    -- Apply sender-side hammer effects (prefix, tag, range)
    if player:getAccessLevel() == "Admin" and hammerActive then
        args.author = "*spiffo* " .. args.author
        args.characterName = "[ADMIN]" .. (args.characterName or player:getDescriptor():getForename() or player:getUsername())
        if range > 0 then
            range = range * 2
        end
    end
    -- Removed TICS DEBUG print lines here

    -- Player Loop
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        local dist = PlayersDistance(player, connectedPlayer)

        if IsAllowedToListen(player, connectedPlayer, args) then
            local receiverHasHammer = IsHammerOn(connectedPlayer)
            local baseBroadcastRange = range
            local effectiveHearingRange = baseBroadcastRange

            if receiverHasHammer and connectedPlayer:getAccessLevel() == "Admin" then
                if baseBroadcastRange > 0 then
                    local hammeredHearingRange = baseBroadcastRange * 2
                    effectiveHearingRange = math.max(baseBroadcastRange, hammeredHearingRange)
                elseif baseBroadcastRange == -1 then
                    effectiveHearingRange = -1
                end
            end

            if type(dist) ~= "number" then print("TICS ERROR: 'dist' is not a number! Value: "..tostring(dist)) end -- Keep actual errors
            if type(effectiveHearingRange) ~= "number" then print("TICS ERROR: 'effectiveHearingRange' is not a number! Value: "..tostring(effectiveHearingRange)) end -- Keep actual errors

            local shouldReceive = false
            if connectedPlayer:getOnlineID() == player:getOnlineID() then
                shouldReceive = true
            elseif type(effectiveHearingRange) == "number" and effectiveHearingRange == -1 then
                shouldReceive = true
            elseif type(dist) == "number" and type(effectiveHearingRange) == "number" and dist < effectiveHearingRange + 0.001 then
                shouldReceive = true
            elseif Character.areInSameVehicle(player, connectedPlayer) then
                shouldReceive = true
            end

            if shouldReceive then
                -- ░░ Duplicate‑filter: skip the /low echo for mates who already got the /faction line ░░
                local sameFaction = false
                if args._echo and args.type == 'low' then
                    local sf = Faction.getPlayerFaction(player)
                    local rf = Faction.getPlayerFaction(connectedPlayer)
                    sameFaction = sf and rf and sf:getName() == rf:getName()
                end

                if not sameFaction then
                    ServerSend.Command(connectedPlayer, packetType, args)
                end
            end
            -- Removed TICS DEBUG print lines here
        else
            -- Removed TICS DEBUG print lines here
        end
    end
    -- End of Player Loop

    -- Handle Radio Emissions and Logging
    local radioEmission = false
    local radioFrequencies = {}
    if packetType ~= 'Typing' then
        radioEmission, radioFrequencies = GetEmittingRadios(player, packetType, args['type'], range)
        SendRadioEmittingPackets(player, args, radioFrequencies)

        if radioEmission then
            local radioConnectedPlayers = getOnlinePlayers()
            for i = 0, radioConnectedPlayers:size() - 1 do
                local radioListener = radioConnectedPlayers:get(i)
                if IsAllowedToListen(player, radioListener, args) then
                    SendRadioPackets(player, radioListener, args, radioFrequencies) -- Changed author to player
                end
            end
        end

        local radiosFrequenciesList = {}
        for frequency, _ in pairs(radioFrequencies) do
            table.insert(radiosFrequenciesList, frequency)
        end
        if Logger and Logger.LogChat then
            Logger.LogChat(args.type, args.author, args.characterName, args.message, radiosFrequenciesList, args.target)
        end
        if args.type ~= "admin" then
            print(string.format("[TICS Chat] (%s) %s: %s", -- Keep this console log
                    args.type,
                    args.author,
                    args.message))
        end
    end
end -- End of ChatMessage.ProcessMessage

function ChatMessage.RollDice(player, diceCount, diceType, addCount)
    if diceCount < 1 or diceCount > 20 or diceType < 1 then
        return
    end
    local results = {}
    local result = 0
    for _ = 1, diceCount do
        local diceResult = ZombRand(diceType) + 1
        table.insert(results, diceResult)
        result = result + diceResult
    end
    if addCount ~= nil then
        result = result + addCount
    end
    local firstName, lastName = Character.getFirstAndLastName(player)
    local username = player:getUsername()
    local characterName = firstName .. ' ' .. lastName
    local messageRange = 20
    if ChatMessage.MessageTypeSettings and ChatMessage.MessageTypeSettings['say'] and ChatMessage.MessageTypeSettings['say']['range'] then
        messageRange = ChatMessage.MessageTypeSettings['say']['range']
    end
    World.forAllPlayers(function(targetPlayer)
        if PlayersDistance(player, targetPlayer) < messageRange then
            ServerSend.RollResult(targetPlayer, username, characterName, diceCount, diceType, addCount, results, result)
        end
    end)
end

----[[ WRC Bad Word Check (Optional - Add if you want this feature)
--local badWords = { "underboob", "boob", "boobs", "boobies", "booby", "rump", "cleavage", "hooters", "breasts",
--                   "breasted", "hips", "tits", "hickey", "hickie", "curves", "busty", "derriere", "sultry", "bulge",
--                   "perky", "ample", "voluptuous", "bosom", "badonkadonks", "titty", "titties", "tiddy", "tiddies",
--                   "breasticles", "teat", "milkers",
--}
--local function containsBadWord(text)
--    local lowerText = text:lower()
--    for word in lowerText:gmatch("%S+") do
--        for _, badWord in ipairs(badWords) do
--            if word == badWord:lower() then
--                return badWord
--            end
--        end
--    end
--    return nil
--end

function ChatMessage.SaveBio(player, rawText)
    if type(rawText) ~= "string" then
        ServerSend.ChatErrorMessage(player, nil, "Invalid bio.")
        return
    end

    local text = rawText:match("^%s*(.-)%s*$")  -- trim

    -- Handle "clear"
    if text:lower() == "clear" then
        BioServer.Set(player, nil)
        ServerSend.ChatInfoMessage(player, "Bio cleared.")
        return
    end

    -- Length check
    local maxLen = 100
    if #text < 8 then
        ServerSend.ChatErrorMessage(player, nil, "Bio too short (min 8 chars).")
        return
    elseif #text > maxLen then
        ServerSend.ChatErrorMessage(player, nil, "Bio too long (max " .. maxLen .. ").")
        return
    end

    -- (optional) profanity check here …

    BioServer.Set(player, text)
    ServerSend.ChatInfoMessage(player, "Bio updated.")
end

Events.OnServerStarted.Add(SetMessageTypeSettings)
Events.EveryOneMinute.Add(DetectMessageTypeSettingsUpdate)

return ChatMessage