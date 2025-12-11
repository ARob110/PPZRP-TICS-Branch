local TICS_VERSION = require('tics/shared/Version')

local PandemUtilities = require('tics/client/PandemUtilities')
local OverheadBioRenderer = require('tics/client/ui/OverheadBioRenderer') -- Ensures the renderer file itself is loaded
local BioMeta                = require("tics/client/BioSync")

local ChatUI                 = require('tics/client/ui/ChatUI')
local ChatText               = require('tics/client/ui/Chat/ChatText')

local AvatarManager          = require('tics/client/AvatarManager')
local AvatarUploadWindow     = require('tics/client/ui/AvatarUploadWindow')
local AvatarValidationWindow = require('tics/client/ui/AvatarValidationWindow')
local Character              = require('tics/shared/utils/Character')
local LanguageManager        = require('tics/client/languages/LanguageManager')
local FakeRadioPacket        = require('tics/client/FakeRadioPacket')
local Parser                 = require('tics/client/parser/Parser')
local PlayerBubble           = require('tics/client/ui/bubble/PlayerBubble')
local RadioBubble            = require('tics/client/ui/bubble/RadioBubble')
local RadioRangeIndicator    = require('tics/client/ui/RadioRangeIndicator')
local RangeIndicator         = require('tics/client/ui/RangeIndicator')
local ClientSend             = require('tics/client/network/ClientSend')
local StringBuilder          = require('tics/client/parser/StringBuilder')
local StringFormat           = require('tics/shared/utils/StringFormat')
local StringParser           = require('tics/shared/utils/StringParser')
local TypingDots             = require('tics/client/ui/TypingDots')
local World                  = require('tics/shared/utils/World')

ISChat.sentMessages      = {}   -- ring-buffer (max 5)
ISChat.sentMessageIndex  = nil  -- current cursor in that buffer

ISChat.allChatStreams     = {}
ISChat.allChatStreams[1]  = { name = 'say', command = '/say ', shortCommand = '/s ', tabID = 1 }
ISChat.allChatStreams[2]  = { name = 'whisper', command = '/whisper ', shortCommand = '/w ', tabID = 1 }
ISChat.allChatStreams[3]  = { name = 'low', command = '/low ', shortCommand = '/l ', tabID = 1 }
ISChat.allChatStreams[4]  = { name = 'yell', command = '/yell ', shortCommand = '/y ', tabID = 1 }
ISChat.allChatStreams[5]  = { name = 'faction', command = '/faction ', shortCommand = '/f ', tabID = 1 }
ISChat.allChatStreams[6]  = { name = 'safehouse', command = '/safehouse ', shortCommand = '/sh ', tabID = 1 }
ISChat.allChatStreams[7]  = { name = 'general', command = '/all ', shortCommand = '/g ', tabID = 1 }
ISChat.allChatStreams[8]  = { name = 'scriptedRadio', command = nil, shortCommand = nil, tabID = 1 }
ISChat.allChatStreams[9]  = { name = 'ooc', command = '/ooc ', shortCommand = '/o ', tabID = 2 }
ISChat.allChatStreams[10] = { name = 'pm', command = '/pm ', shortCommand = '/p ', tabID = 3 }
ISChat.allChatStreams[11] = { name = 'admin', command = '/admin ', shortCommand = '/a ', tabID = 4 }
ISChat.allChatStreams[12] = { name = 'me', command = '/me ', shortCommand = nil, tabID = 1, forget = true }
ISChat.allChatStreams[13] = { name = 'do', command = '/do ', shortCommand = nil, tabID = 1, forget = true }
ISChat.allChatStreams[14] = { name = 'whisperme', command = '/whisperme', shortCommand = '/wme', tabID = 1 }
ISChat.allChatStreams[15] = { name = 'melow',     command = '/melow',     shortCommand = nil, tabID = 1 }
ISChat.allChatStreams[16] = { name = 'melong',    command = '/melong',    shortCommand = nil, tabID = 1 }
ISChat.allChatStreams[17] = { name = 'dolow',     command = '/dolow',     shortCommand = nil, tabID = 1 }
ISChat.allChatStreams[18] = { name = 'dolong',    command = '/dolong',    shortCommand = nil, tabID = 1 }
ISChat.allChatStreams[19] = { name = 'localevent',    command = '/localevent',    shortCommand = nil, tabID = 1, forget = true }
ISChat.allChatStreams[20] = { name = 'globalevent',    command = '/globalevent',    shortCommand = nil, tabID = 1, forget = true }
ISChat.allChatStreams[21] = { name = 'admindolong',    command = '/admindolong',    shortCommand = '/adl', tabID = 1 }
ISChat.allChatStreams[22] = { name = 'factionooc', command = '/factionooc ', shortCommand = '/fooc ', tabID = 5 }

ISChat.ticsCommand    = {}
ISChat.ticsCommand[1] = { name = 'color', command = '/color', shortCommand = nil }
ISChat.ticsCommand[2] = { name = 'pitch', command = '/pitch', shortCommand = nil }
ISChat.ticsCommand[3] = { name = 'roll', command = '/roll', shortCommand = nil }
ISChat.ticsCommand[4] = { name = 'language', command = '/language', shortCommand = '/la' }
ISChat.ticsCommand[5] = { name = 'roll', command = '/roll', shortCommand = nil }
ISChat.ticsCommand[6] = { name = 'name', command = '/name', shortCommand = nil }
ISChat.ticsCommand[7] = { name = 'stopsound', command = '/stopsound', shortCommand = '/ss' }
ISChat.ticsCommand[8] = { name = 'playsoundglobal', command = '/playsoundglobal', shortCommand = '/psg' }
ISChat.ticsCommand[9] = { name = 'coords', command = '/coords', shortCommand = nil }
ISChat.ticsCommand[10] = { name = 'hammer', command = '/hammer', shortCommand = nil }
ISChat.ticsCommand[11] = { name = 'removefoliage', command = '/removefoliage', shortCommand = '/rf' }
ISChat.ticsCommand[12] = { name = 'playsoundlocal', command = '/playsoundlocal', shortCommand = '/psl' }
ISChat.ticsCommand[13] = { name = 'playsoundquiet', command = '/playsoundquiet', shortCommand = '/psq' }
ISChat.ticsCommand[14] = { name = 'bio', command = '/bio', shortCommand = nil }
ISChat.ticsCommand[15] = { name = 'emotecolor', command = '/emotecolor', shortCommand = nil }


ISChat.defaultTabStream    = {}
ISChat.defaultTabStream[1] = ISChat.allChatStreams[1]
ISChat.defaultTabStream[2] = ISChat.allChatStreams[9]
ISChat.defaultTabStream[3] = ISChat.allChatStreams[10]
ISChat.defaultTabStream[4] = ISChat.allChatStreams[11]


ISChat.lastTabStream    = {}
ISChat.lastTabStream[1] = ISChat.defaultTabStream[1]
ISChat.lastTabStream[2] = ISChat.defaultTabStream[2]
ISChat.lastTabStream[3] = ISChat.defaultTabStream[3]
ISChat.lastTabStream[4] = ISChat.defaultTabStream[4]

-- Ensure this is defined only once per client
local lastBuffAppliedHour = 0
local lastReceiveBoredomHour = 0

local function IsOnlySpacesOrEmpty(command)
    local commandWithoutSpaces = command:gsub('%s+', '')
    return #commandWithoutSpaces == 0
end

local function GetCommandFromMessage(command)
    if not luautils.stringStarts(command, '/') then
        local defaultStream = ISChat.defaultTabStream[ISChat.instance.currentTabID]
        return defaultStream, '', false
    end
    if IsOnlySpacesOrEmpty(command) then
        return nil
    end
    for _, stream in ipairs(ISChat.allChatStreams) do
        if stream.command and luautils.stringStarts(command, stream.command) then
            return stream, stream.command, false
        elseif stream.shortCommand and luautils.stringStarts(command, stream.shortCommand) then
            return stream, stream.shortCommand, false
        end
    end
    return nil
end

local function GetTicsCommandFromMessage(command)
    if not luautils.stringStarts(command, '/') then
        return nil
    end
    if IsOnlySpacesOrEmpty(command) then
        return nil
    end
    for _, stream in ipairs(ISChat.ticsCommand) do
        if luautils.stringStarts(command, stream.command) then
            return stream, stream.command
        elseif stream.shortCommand and luautils.stringStarts(command, stream.shortCommand) then
            return stream, stream.shortCommand
        end
    end
    return nil
end

local function UpdateTabStreams(newTab, tabID)
    newTab.chatStreams = {}
    for _, stream in pairs(ISChat.allChatStreams) do
        local name = stream['name']
        if stream['tabID'] == tabID and TicsServerSettings and TicsServerSettings[name] and TicsServerSettings[name]['enabled'] then
            table.insert(newTab.chatStreams, stream)
        end
    end
    if #newTab.chatStreams >= 1 then
        ISChat.defaultTabStream[tabID] = newTab.chatStreams[1]
        newTab.lastChatCommand = newTab.chatStreams[1].command
    end
end

local function UpdateRangeIndicatorVisibility()
    if ISChat.instance.rangeButtonState == 'visible' then
        if ISChat.instance.rangeIndicator and ISChat.instance.focused then
            ISChat.instance.rangeIndicator:subscribe()
        end
    elseif ISChat.instance.rangeButtonState == 'hidden' then
        if ISChat.instance.rangeIndicator then
            ISChat.instance.rangeIndicator:unsubscribe()
        end
    else
        if ISChat.instance.rangeIndicator then
            ISChat.instance.rangeIndicator:subscribe()
        end
    end
end

local function UpdateRangeIndicator(stream)
    if TicsServerSettings ~= nil
            and TicsServerSettings[stream.name]['range'] ~= nil
            and TicsServerSettings[stream.name]['range'] ~= -1
            and TicsServerSettings[stream.name]['color'] ~= nil
    then
        if ISChat.instance.rangeIndicator then
            ISChat.instance.rangeIndicator:unsubscribe()
        end
        local range = TicsServerSettings[stream.name]['range']
        ISChat.instance.rangeIndicator = RangeIndicator:new(getPlayer(), range,
                TicsServerSettings[stream.name]['color'])
        UpdateRangeIndicatorVisibility()
    else
        if ISChat.instance.rangeIndicator then
            ISChat.instance.rangeIndicator:unsubscribe()
        end
        ISChat.instance.rangeIndicator = nil
    end
end

ISChat.onSwitchStream = function()
    if ISChat.focused then
        local t = ISChat.instance.textEntry
        local internalText = t:getInternalText()
        local data = luautils.split(internalText, " ")
        local onlineUsers = getOnlinePlayers()
        for i = 0, onlineUsers:size() - 1 do
            local username = onlineUsers:get(i):getUsername()
            if #data > 1 and string.match(string.lower(username), string.lower(data[#data])) then
                local txt = ""
                for i = 1, #data - 1 do
                    txt = txt .. data[i] .. " "
                end
                txt = txt .. username
                ISChat.instance.textEntry:setText(txt)
                return
            end
        end

        local curTxtPanel = ISChat.instance.chatText
        if curTxtPanel == nil then
            return
        end
        local chatStreams = curTxtPanel.chatStreams
        curTxtPanel.streamID = curTxtPanel.streamID % #chatStreams + 1
        local stream = chatStreams[curTxtPanel.streamID]
        ISChat.lastTabStream[ISChat.instance.currentTabID] = stream
        UpdateRangeIndicator(stream)
    end
end

local function AddTab(tabTitle, tabID)
    local chat = ISChat.instance
    if chat.tabs[tabID] ~= nil then
        return
    end
    local newTab = chat:createTab()
    newTab.parent = chat
    newTab.tabTitle = tabTitle
    newTab.tabID = tabID
    newTab.streamID = 1
    UpdateTabStreams(newTab, tabID)
    newTab:setUIName("chat text panel with title '" .. tabTitle .. "'")
    local pos = chat:calcTabPos()
    local size = chat:calcTabSize()
    newTab:setY(pos.y)
    newTab:setHeight(size.height)
    newTab:setWidth(size.width)
    if chat.tabCnt == 0 then
        chat:addChild(newTab)
        chat.chatText = newTab
        chat.chatText:setVisible(true)
        chat.currentTabID = tabID
    end
    if chat.tabCnt == 1 then
        chat.panel:setVisible(true)
        chat.chatText:setY(pos.y)
        chat.chatText:setHeight(size.height)
        chat.chatText:setWidth(size.width)
        chat:removeChild(chat.chatText)
        chat.panel:addView(chat.chatText.tabTitle, chat.chatText)
    end

    if chat.tabCnt >= 1 then
        chat.panel:addView(tabTitle, newTab)
        chat.minimumWidth = chat.panel:getWidthOfAllTabs() + 2 * chat.inset
    end
    chat.tabs[tabID] = newTab
    chat.tabCnt = chat.tabCnt + 1
end

Events.OnChatWindowInit.Remove(ISChat.initChat)

local function GetRandomInt(min, max)
    return ZombRand(max - min) + min
end

local function GenerateRandomColor()
    return { GetRandomInt(0, 254), GetRandomInt(0, 254), GetRandomInt(0, 254), }
end

local function SetPlayerColor(color)
    ISChat.instance.ticsModData['playerColor'] = color
    ModData.add('tics', ISChat.instance.ticsModData)
end

local function SetPlayerPitch(pitch)
    ISChat.instance.ticsModData['voicePitch'] = pitch
    ModData.add('tics', ISChat.instance.ticsModData)
end

local function RandomVoicePitch(isFemale)
    local randomPitch = ZombRandFloat(0.85, 1.15)
    if isFemale == true then
        randomPitch = randomPitch + 0.30
    end
    return randomPitch
end

local function InitGlobalModData()
    local ticsModData = ModData.getOrCreate("tics")
    ISChat.instance.ticsModData = ticsModData

    if ticsModData['playerColor'] == nil then
        SetPlayerColor(GenerateRandomColor())
    end
    if ticsModData['isVoiceEnabled'] == nil and ISChat.instance.isVoiceEnabled == nil then
        -- wait for the server settings to override this if voices are enabled by default
        ISChat.instance.isVoiceEnabled = false
    elseif ticsModData['isVoiceEnabled'] ~= nil then
        ISChat.instance.isVoiceEnabled = ticsModData['isVoiceEnabled']
    end
    if ticsModData['isRadioIconEnabled'] == nil and ISChat.instance.isRadioIconEnabled == nil then
        ISChat.instance.isRadioIconEnabled = true
    elseif ticsModData['isRadioIconEnabled'] ~= nil then
        ISChat.instance.isRadioIconEnabled = ticsModData['isRadioIconEnabled']
    end
    if ticsModData['isPortraitEnabled'] == nil and ISChat.instance.isPortraitEnabled == nil then
        ISChat.instance.isPortraitEnabled = true
    elseif ticsModData['isPortraitEnabled'] ~= nil then
        ISChat.instance.isPortraitEnabled = ticsModData['isPortraitEnabled']
    end
    if ticsModData['showChatBubbles'] == nil then
        ticsModData['showChatBubbles'] = true
    end
    ISChat.instance.showChatBubbles = ticsModData['showChatBubbles']
    if ticsModData['voicePitch'] == nil then
        local randomPitch = RandomVoicePitch(getPlayer():getVisual():isFemale())
        SetPlayerPitch(randomPitch)
    end
end

local lastAskedDataTime = Calendar.getInstance():getTimeInMillis() - 2000
local function AskServerData()
    local delta = Calendar.getInstance():getTimeInMillis() - lastAskedDataTime
    if delta < 2000 then
        return
    end
    lastAskedDataTime = Calendar.getInstance():getTimeInMillis()

    ClientSend.sendAskSandboxVars()
end

ISChat.initChat = function()
    TicsServerSettings = nil
    local instance = ISChat.instance
    if instance.tabCnt == 1 then
        instance.chatText:setVisible(false)
        instance:removeChild(instance.chatText)
        instance.chatText = nil
    elseif instance.tabCnt > 1 then
        instance.panel:setVisible(false)
        for tabId, tab in pairs(instance.tabs) do
            instance.panel:removeView(tab)
        end
    end
    instance.tabCnt = 0
    instance.tabs = {}
    instance.currentTabID = 0
    instance.rangeButtonState = 'hidden'
    instance.online = false
    instance.lastDiscordMessages = {}

    InitGlobalModData()
    AddTab('General', 1)
    AvatarManager:createRequestDirectory()
    Events.OnPostRender.Add(AskServerData)
end

Events.OnGameStart.Remove(ISChat.createChat)

local function CreateChat()
    if not isClient() then
        return
    end
    ISChat.chat = ISChat:new(15, getCore():getScreenHeight() - 400, 500, 200)
    ISChat.chat:initialise()
    ISChat.chat:addToUIManager()
    ISChat.chat:setVisible(true)
    ISChat.chat:bringToTop()
    ISLayoutManager.RegisterWindow('chat', ISChat, ISChat.chat)

    ISChat.instance:setVisible(true)

    Events.OnAddMessage.Add(ISChat.addLineInChat)
    Events.OnMouseDown.Add(ISChat.unfocusEvent)
    Events.OnKeyPressed.Add(ISChat.onToggleChatBox)
    Events.OnKeyKeepPressed.Add(ISChat.onKeyKeepPressed)
    Events.OnTabAdded.Add(ISChat.onTabAdded)
    Events.OnSetDefaultTab.Add(ISChat.onSetDefaultTab)
    Events.OnTabRemoved.Add(ISChat.onTabRemoved)
    Events.SwitchChatStream.Add(ISChat.onSwitchStream)
end

Events.OnGameStart.Add(CreateChat)

local function ProcessChatCommand(stream, command)
    if TicsServerSettings and TicsServerSettings[stream.name] == false then
        return false
    end
    local pitch = ISChat.instance.ticsModData['voicePitch']
    local ticsCommand = Parser.ParseTicsMessage(command)
    local playerColor = ISChat.instance.ticsModData['playerColor']
    if ticsCommand == nil then
        return false
    end
    local language = LanguageManager:getCurrentLanguage()
    if stream.name == 'yell' then
        ClientSend.sendChatMessage(command, language, playerColor, 'yell', pitch, false)
    elseif stream.name == 'say' then
        ClientSend.sendChatMessage(command, language, playerColor, 'say', pitch, false)
    elseif stream.name == 'low' then
        ClientSend.sendChatMessage(command, language, playerColor, 'low', pitch, false)
    elseif stream.name == 'whisper' then
        ClientSend.sendChatMessage(command, language, playerColor, 'whisper', pitch, false)
    elseif stream.name == 'me' then
        ClientSend.sendChatMessage(command, language, playerColor, 'me', pitch, true)
    elseif stream.name == 'do' then
        ClientSend.sendChatMessage(command, language, playerColor, 'do', pitch, true)
    elseif stream.name == 'pm' then
        local targetStart, targetEnd = command:find('^%s*"%a+%s?%a+"')
        if targetStart == nil then
            targetStart, targetEnd = command:find('^%s*%a+')
        end
        if targetStart == nil or targetEnd + 1 >= #command or command:sub(targetEnd + 1, targetEnd + 1) ~= ' ' then
            return false
        end
        local target = command:sub(targetStart, targetEnd)
        local pmBody = command:sub(targetEnd + 2)
        ClientSend.sendPrivateMessage(pmBody, language, playerColor, target, pitch)
        ISChat.instance.chatText.lastChatCommand = ISChat.instance.chatText.lastChatCommand .. target .. ' '
    elseif stream.name == 'faction' then
        ClientSend.sendChatMessage(command, language, playerColor, 'faction', pitch, false)
    elseif stream.name == 'safehouse' then
        ClientSend.sendChatMessage(command, language, playerColor, 'safehouse', pitch, false)
    elseif stream.name == 'general' then
        ClientSend.sendChatMessage(command, language, playerColor, 'general', pitch, false)
    elseif stream.name == 'admin' then
        ClientSend.sendChatMessage(command, language, playerColor, 'admin', pitch, false)
    elseif stream.name == 'ooc' then
        ClientSend.sendChatMessage(command, language, playerColor, 'ooc', pitch, false)
    elseif stream.name == 'whisperme' then
        ClientSend.sendChatMessage(command, language, playerColor, 'whisperme', pitch, true)
    elseif stream.name == 'melow' then
        ClientSend.sendChatMessage(command, language, playerColor, 'melow', pitch, true)
    elseif stream.name == 'melong' then
        ClientSend.sendChatMessage(command, language, playerColor, 'melong', pitch, true)
    elseif stream.name == 'dolow' then
        ClientSend.sendChatMessage(command, language, playerColor, 'dolow', pitch, true)
    elseif stream.name == 'dolong' then
        ClientSend.sendChatMessage(command, language, playerColor, 'dolong', pitch, true)
    elseif stream.name == 'admindolong' then
        -- Check if player is admin client-side (optional, server check is primary)
        if not isAdmin() then
            ISChat.sendErrorToCurrentTab("You need admin privileges to use /admindolong.")
            return false -- Stop processing if not admin
        end
        -- Send it to server, type 'admindolong', disable verb like '/do'/'dolong'
        ClientSend.sendChatMessage(command, language, playerColor, 'admindolong', pitch, true)
    elseif stream.name == 'localevent' then
        ClientSend.sendChatMessage(command, language, playerColor, 'localevent', pitch, false)
    elseif stream.name == 'globalevent' then
        ClientSend.sendChatMessage(command, language, playerColor, 'globalevent', pitch, false)
        ISChat.sendInfoToCurrentTab("Global event sent (client-side).")
    elseif stream.name == 'factionooc' then
        -- Send like OOC (disableVerb = true), but with type 'factionooc'
        ClientSend.sendChatMessage(command, language, playerColor, 'factionooc', pitch, true)
    else
        return false
    end
end

local function RemoveLeadingSpaces(text)
    local trailingCount = 0
    for index = 1, #text do
        if text:byte(index) ~= 32 then -- 32 is ASCII code for space ' '
            break
        end
        trailingCount = trailingCount + 1
    end
    return text:sub(trailingCount)
end

local function GetArgumentsFromMessage(ticsCommand, message)
    local command = message:match('^/%a+')
    if #message < #command + 2 then -- command + space + chars
        return nil
    end
    local arguments = message:sub(#command + 2)
    arguments = RemoveLeadingSpaces(arguments)
    if #arguments == 0 then
        return nil
    end
    return arguments
end

local function ProcessColorCommand(arguments)
    local currentColor = ISChat.instance.ticsModData['playerColor']
    if arguments == nil then
        ISChat.sendInfoToCurrentTab('color value is ' .. StringFormat.color(currentColor))
        return true
    end
    local newColor = StringParser.rgbStringToRGB(arguments) or StringParser.hexaStringToRGB(arguments)
    if newColor == nil then
        return false
    end
    SetPlayerColor(newColor)
    ISChat.sendInfoToCurrentTab('player color updated to '
            .. StringFormat.color(newColor)
            .. ' from '
            .. StringFormat.color(currentColor))
    return true
end

local function ProcessPitchCommand(arguments)
    if arguments == nil then
        ISChat.sendInfoToCurrentTab('pitch value is ' .. ISChat.instance.ticsModData['voicePitch'])
        return true
    end
    local regex = '^(%d+.?%d*) *$'
    local valueAsText = arguments:match(regex)
    if valueAsText then
        local value = tonumber(valueAsText)
        if value ~= nil and value >= 0.85 and value <= 1.45 then
            local currentPitch = ISChat.instance.ticsModData['voicePitch']
            SetPlayerPitch(value)
            ISChat.sendInfoToCurrentTab('pitch value updated to ' .. value .. ' from ' .. currentPitch)
            return true
        end
    end
    return false
end

local function ProcessRollCommand(arguments)
    if arguments == nil then
        return false
    end
    local regex = '^(%d*)d(%d+)([+-]?)(%d*) *$'
    local m1, m2, m3, m4 = arguments:match(regex)
    local diceCount = tonumber(m1)
    local diceType = tonumber(m2)
    local sign     = m3 or ''
    local modStr   = m4 or ''          -- may be ''
    local addCount -- nil, positive, or negative number

    if sign ~= '' then                 -- user typed + or -
        if modStr == '' then return false end           -- “/roll 1d20+” is invalid
        addCount = tonumber(sign .. modStr)             -- '+4'→4, '-3'→-3
    end

    -- Default to 1 die if none specified
    if diceCount == nil then diceCount = 1 end

    -- Basic validation
    if diceType == nil or diceType < 1 then return false end
    if diceCount < 1 or diceCount > 20 then return false end

    -- Send the roll to the server (addCount may be nil or signed)
    ClientSend.sendRoll(diceCount, diceType, addCount)
    return true
end

local function ProcessLanguageCommand(arguments)
    if not TicsServerSettings or not TicsServerSettings['options']['languages'] then
        ISChat.sendErrorToCurrentTab(
                getText('UI_TICS_Messages_languages_disabled'))
        return true
    end
    if arguments == nil then
        local knownLanguages = LanguageManager:getKnownLanguages()
        local knownLanguagesFormatted = ''
        local first = true
        for _, languageCode in pairs(knownLanguages) do
            if not first then
                knownLanguagesFormatted = knownLanguagesFormatted .. ', '
            end
            knownLanguagesFormatted = knownLanguagesFormatted .. languageCode
            first = false
        end
        local currentLanguage = LanguageManager:getCurrentLanguage()
        local currentLanguageCode = LanguageManager.GetCodeFromLanguage(currentLanguage)
        local currentLanguageTranslated = LanguageManager.GetLanguageTranslated(currentLanguage)
        ISChat.sendInfoToCurrentTab(
                getText('UI_TICS_Messages_current_language',
                        currentLanguageTranslated,
                        currentLanguageCode))
        ISChat.sendInfoToCurrentTab(getText('UI_TICS_Messages_known_languages', knownLanguagesFormatted))
        return true
    end
    local regex = '^(%a%a%a?) *$'
    local languageCode = arguments:match(regex)
    if languageCode == nil then
        return false
    end
    if not LanguageManager:isCodeKnown(languageCode) then
        ISChat.sendErrorToCurrentTab(getText('UI_TICS_Messages_unknown_language_code', languageCode))
        return true
    end
    LanguageManager:setCurrentLanguageFromCode(languageCode)
    local languageTranslated = LanguageManager.GetLanguageTranslatedFromCode(languageCode)
    ISChat.sendInfoToCurrentTab(getText('UI_TICS_Messages_language_set_to', languageTranslated))
    return true
end

local function ProcessNameCommand(arguments)
    -- If no arguments, simply display the current name.
    if not arguments or arguments == "" then
        local character = getPlayer()
        local currentName = character:getDescriptor():getForename() .. " " .. character:getDescriptor():getSurname()
        ISChat.sendInfoToCurrentTab("Your name is " .. currentName)
        return true
    end

    -- The entire argument string is now the full name
    local fullName = arguments

    -- Validate length: for example, maximum 30 characters.
    if #fullName > 30 then -- Match server-side limit
        ISChat.sendErrorToCurrentTab("Your name must be 30 characters or less.")
        return false
    end

    -- Validate that names contain only letters and spaces.
    if not fullName:match("^[%a%d%s%-%(%)%[%]/'\"]+$") then-- Allow letters and spaces
        ISChat.sendErrorToCurrentTab("Name can only contain letters and spaces.")
        return false
    end

    -- Send the change to the server.
    ClientSend.sendChangeName(fullName) -- Send fullName
    return true
end

local PandemSounds = {}           -- stack of {id, emitter, name}

local function remember(id, emitter, name)
    if id and id ~= 0 then
        PandemSounds[#PandemSounds+1] = { id=id, emitter=emitter, name=name }
    end
end

ISChat.rememberSound = remember

function ProcessStopSoundCommand(arg)
    ------------------------------------------------------
    -- /stopsound            → stop the last Pandem sound
    -- /stopsound <name>     → stop every tracked copy
    -- /stopsound all        → (rare) nuke *everything*
    ------------------------------------------------------
    if arg == "all" then
        getSoundManager():stop()            -- old behaviour
        PandemSounds = {}
        ISChat.sendInfoToCurrentTab("[Pandemonium] Stopped ALL sounds.")
        return
    end

    local matcher = (arg and arg ~= "") and arg or nil
    local keep, stopped = {}, 0

    -- oldest→newest means bare /stopsound kills the *latest*
    for i=1,#PandemSounds do
        local s = PandemSounds[i]
        local match = (not matcher) or (s.name == matcher)
        if match and s.emitter and s.id then
            s.emitter:stopSound(s.id)        -- surgical strike
            stopped = stopped + 1
        else
            keep[#keep+1] = s                -- keep others
        end
    end
    PandemSounds = keep

    if stopped == 0 then
        ISChat.sendErrorToCurrentTab(
                matcher and ("No Pandemonium sound named '%s' is playing."):format(matcher)
                        or  "No Pandemonium sounds are currently playing.")
    else
        ISChat.sendInfoToCurrentTab(
                ("[Pandemonium] Stopped %d sound%s."):format(stopped, stopped==1 and "" or "s"))
    end
end


local function ProcessPlaySoundCommand(arguments)
    if not isAdmin() then
        ISChat.sendErrorToCurrentTab("You are not logged in as an Admin.")
        return false
    end
    if not arguments or arguments == "" then
        ISChat.sendErrorToCurrentTab("Usage: /playsound <sound_file_name>")
        return false
    end

    local soundFileName = arguments

    -- *** new approach ***
    ClientSend.sendPlaySoundGlobal(soundFileName)

    ISChat.sendInfoToCurrentTab("[Pandemonium] Triggering global sound '" .. soundFileName .. "'.")
    return true
end

local function ProcessPlaySoundGlobalCommand(arguments)
    return ProcessPlaySoundCommand(arguments)
end

local function ProcessPlaySoundLocalCommand(arguments)
    if not isAdmin() then
        ISChat.sendErrorToCurrentTab("You are not logged in as an Admin.")
        return false
    end
    if not arguments or arguments == "" then
        ISChat.sendErrorToCurrentTab("Usage: /playsoundlocal <sound_file_name>")
        return false
    end

    local soundFileName = arguments

    -- *** CORRECTED: Send command to SERVER to handle local sound ***
    ClientSend.sendPlaySoundLocal(soundFileName) -- Use ClientSend to send to server!

    ISChat.sendInfoToCurrentTab("[Pandemonium] Triggering local sound '" .. soundFileName .. "'.");
    return true;
end

local function ProcessPlaySoundQuietCommand(arguments)
    if not isAdmin() then
        ISChat.sendErrorToCurrentTab("You are not logged in as an Admin.")
        return false
    end
    if not arguments or arguments == "" then
        ISChat.sendErrorToCurrentTab("Usage: /playsoundquiet <sound_file_name>")
        return false
    end

    local soundFileName = arguments

    -- *** CORRECTED: Send command to SERVER to handle quiet sound ***
    ClientSend.sendPlaySoundQuiet(soundFileName) -- Use ClientSend to send to server!

    ISChat.sendInfoToCurrentTab("[Pandemonium] Triggering quiet sound '" .. soundFileName .. "'.");
    return true;
end



local function ProcessCoordsCommand(arguments)
    -- No param needed, so we ignore 'arguments'
    -- Could require admin? If so, do:
    -- if not isAdmin() then
    --    ISChat.sendErrorToCurrentTab("You are not logged in as an Admin.")
    --    return false
    -- end

    -- Just tell the server we want coords
    sendClientCommand("TICS", "Coords", {})

    return true
end

local function ProcessHammerCommand(arguments)
    -- usage: /hammer on/off
    if not isAdmin() then
        ISChat.sendErrorToCurrentTab("You are not logged in as an Admin.")
        return false
    end

    if not arguments or (arguments ~= "on" and arguments ~= "off") then
        ISChat.sendErrorToCurrentTab("Usage: /hammer on/off")
        return false
    end

    sendClientCommand("TICS", "Hammer", { state = arguments })

    return true
end

local function ProcessRemoveFoliageCommand(arguments)
    -- 1) Must be admin
    if not isAdmin() then
        ISChat.sendErrorToCurrentTab("You are not logged in as an Admin.")
        return false
    end

    -- 2) Parse radius argument, default to 10
    local radius = tonumber(arguments) or 10
    if radius > 50 then
        radius = 50
        ISChat.sendInfoToCurrentTab("[Pandemonium] Max radius is 50. Truncating.")
    end

    local player = getPlayer()
    local xvalue = player:getX()
    local yvalue = player:getY()
    local zvalue = player:getZ()
    local count = 0

    -- 3) Loop over squares in [x-r..x+r], [y-r..y+r]
    for x = xvalue - radius, xvalue + radius do
        for y = yvalue - radius, yvalue + radius do
            local sq = getCell():getGridSquare(x, y, zvalue)
            if sq then
                -- 4) Iterate objects in reverse
                for i = sq:getObjects():size(), 1, -1 do
                    local obj = sq:getObjects():get(i-1)
                    if obj then
                        -- a) Remove IsoTrees
                        if instanceof(obj, "IsoTree") then
                            sq:transmitRemoveItemFromSquare(obj)
                            count = count + 1
                        else
                            -- b) Check the sprite name for grass/foliage patterns
                            local spriteName = obj:getSprite() and obj:getSprite():getName()
                            if spriteName then
                                if luautils.stringStarts(spriteName, 'blends_natural_02')
                                        or luautils.stringStarts(spriteName, 'blends_grassoverlays')
                                        or luautils.stringStarts(spriteName, 'd_')
                                        or luautils.stringStarts(spriteName, 'e_')
                                        or luautils.stringStarts(spriteName, 'f_')
                                        or (luautils.stringStarts(spriteName, 'vegetation_')
                                        and not luautils.stringStarts(spriteName, 'vegetation_indoor'))
                                then
                                    sq:transmitRemoveItemFromSquare(obj)
                                    count = count + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- 5) Show a message in TICS chat
    ISChat.sendInfoToCurrentTab("[Pandemonium] Removed " .. tostring(count)
            .. " pieces of foliage in radius " .. tostring(radius))
    return true
end

local function ProcessEmoteColorCommand(arguments)
    if not arguments or #arguments == 0 then
        -- Optional: Could add functionality here to list current emote colors
        -- For now, just return false to trigger the usage error
        return false
    end

    -- Match "streamName colorString"
    local streamName, colorStr = arguments:match("^(%S+)%s+(.*)$")
    if not streamName or not colorStr then
        ISChat.sendErrorToCurrentTab("Invalid format. Use: /emotecolor <stream> <color>")
        return false -- Indicate error, but handled internally
    end

    -- Validate stream name (check if it's a known stream, especially one users might want to color like me, do, say etc.)
    local isValidStream = false
    for _, streamData in ipairs(ISChat.allChatStreams) do
        if streamData.name == streamName then
            isValidStream = true
            break
        end
    end
    -- Allow potentially other/future streams too, but warn if it's not in the main list? Or restrict strictly?
    -- Let's be lenient for now. If needed, add stricter validation.
    -- if not isValidStream then
    --    ISChat.sendErrorToCurrentTab("Unknown or invalid chat stream name: " .. streamName)
    --    return false
    -- end

    -- Try parsing the color string
    local newColor = StringParser.rgbStringToRGB(colorStr) or StringParser.hexaStringToRGB(colorStr)
    if not newColor then
        ISChat.sendErrorToCurrentTab("Invalid color format. Use RGB (e.g., 255,0,0) or Hex (e.g., #FF0000).")
        return false -- Indicate error, but handled internally
    end

    -- Ensure modData structure exists
    ISChat.instance.ticsModData = ISChat.instance.ticsModData or {}
    ISChat.instance.ticsModData.emoteColors = ISChat.instance.ticsModData.emoteColors or {}

    -- Store the color
    ISChat.instance.ticsModData.emoteColors[streamName] = newColor

    -- Save the updated modData
    ModData.add('tics', ISChat.instance.ticsModData)

    -- Provide feedback
    ISChat.sendInfoToCurrentTab(string.format("Text color for /%s stream set to R:%d G:%d B:%d",
            streamName, newColor[1], newColor[2], newColor[3]))
    return true -- Indicate success
end


local function ProcessTicsCommand(ticsCommand, message)
    local arguments = GetArgumentsFromMessage(ticsCommand, message)
    if ticsCommand['name'] == 'color' then
        if ProcessColorCommand(arguments) == false then
            ISChat.sendErrorToCurrentTab(
                    'color command expects the format: "/color value" with value as 255, 255, 255 or #FFFFFF')
            return false
        end
    elseif ticsCommand['name'] == 'pitch' then
        if ProcessPitchCommand(arguments) == false then
            ISChat.sendErrorToCurrentTab('pitch command expects the format: "/pitch value" with value from 0.85 to 1.45')
            return false
        end
    elseif ticsCommand['name'] == 'roll' then
        if ProcessRollCommand(arguments) == false then
            ISChat.sendErrorToCurrentTab(
                    'roll command expects the format: "/roll xdy" with x and y numbers and x from 1 to 20')
            return false
        end
    elseif ticsCommand['name'] == 'language' then
        if ProcessLanguageCommand(arguments) == false then
            ISChat.sendErrorToCurrentTab(
                    'language command expects the format: "/language en" with "en" the language code')
            return false
        end
    elseif ticsCommand['name'] == 'name' then
        -- If name changes are disabled by an admin, then exit.
        if not SandboxVars.TICS.NameChangeEnabled then
            getPlayer():addLineChatElement("Name Changing has been disabled by an Admin.", 1, 0, 0)
            doKeyPress(false)
            ISChat.instance.timerTextEntry = 20
            ISChat.instance:unfocus()
            return false
        end

        -- Extract the arguments (the new name text)
        local arguments = GetArgumentsFromMessage(ticsCommand, message)
        if not arguments or arguments == "" then
            local character = getPlayer()
            local currentName = character:getDescriptor():getForename() .. " " .. character:getDescriptor():getSurname()
            ISChat.sendInfoToCurrentTab("Your name is " .. currentName)
            return true
        end

        -- The entire argument string is now the full name
        local fullName = arguments

        -- Validate lengths.
        if #fullName > 30 then -- **Increased to 30 characters**
            ISChat.sendErrorToCurrentTab("Your name must be 30 characters or less.") -- **Updated message**
            return false
        end

        -- Validate that names contain only letters and spaces.
        if not fullName:match("^[%a%d%s%-%(%)%[%]/'\"]+$") then -- **Comprehensive regex WITH parentheses and brackets**
            ISChat.sendErrorToCurrentTab("Name is invalid.")
            return
        end

        -- Process the name change on the client:
        local player = getPlayer()
        local descriptor = player:getDescriptor()
        if descriptor then
            descriptor:setForename(fullName) -- Now set forename to fullName directly
            if descriptor.setSurname then
                descriptor:setSurname("") -- Clear surname, or set a default surname if you prefer
            else
                print("DEBUG: descriptor.setSurname is nil; surname not updated.")
            end
        end

        -- Sync with the server so other clients eventually update:
        sendPlayerStatsChange(player)

        -- Have the player announce the change.
        player:Say(getText("UI_name_change_roleplaychat") .. fullName) -- Announce with fullName // currently doesn't broadcast, local only

        return true

    elseif ticsCommand['name'] == 'stopsound' then
        ProcessStopSoundCommand(arguments)

    elseif ticsCommand['name'] == 'playsoundglobal' then
        ProcessPlaySoundGlobalCommand(arguments)

    elseif ticsCommand['name'] == 'localevent' then
        ProcessLocalEventCommand(arguments)

    elseif ticsCommand['name'] == 'coords' then
        ProcessCoordsCommand(arguments)

    elseif ticsCommand['name'] == 'hammer' then
        ProcessHammerCommand(arguments)

    elseif ticsCommand['name'] == 'removefoliage' then
        ProcessRemoveFoliageCommand(arguments)

    elseif ticsCommand['name'] == 'playsoundlocal' then
        ProcessPlaySoundLocalCommand(arguments)

    elseif ticsCommand['name'] == 'playsoundquiet' then
        ProcessPlaySoundQuietCommand(arguments)

    elseif ticsCommand['name'] == 'bio' then
        ------------------------------------------------------------
        -- /bio  (show / set / clear)
        ------------------------------------------------------------
        local args = GetArgumentsFromMessage(ticsCommand, message) or ""
        local me   = getPlayer():getUsername()
        local max  = 100                     -- must match server limit

        -- Trim whitespace
        args = args:match("^%s*(.-)%s*$")

        -- 1)  Show current bio
        if args == "" then
            local current = BioMeta.Get(me) or "none set"
            ISChat.sendInfoToCurrentTab("Current bio: " .. current)
            return true
        end

        -- 2)  Clear
        if args:lower() == "clear" then
            ClientSend.SetBio(nil)
            BioMeta.SetLocal(me, nil)        -- optimistic
            return true
        end

        -- 3)  Length validation
        if #args < 8 then
            ISChat.sendErrorToCurrentTab("Bio too short (min 8 chars).")
            return true
        elseif #args > max then
            ISChat.sendErrorToCurrentTab("Bio too long (max " .. max .. " chars).")
            return true
        end

        -- 4)  Send to server
        ClientSend.SetBio(args)
        BioMeta.SetLocal(me, args)           -- optimistic
        return true

    elseif ticsCommand['name'] == 'emotecolor' then
        -- ProcessEmoteColorCommand now handles its own errors/feedback mostly
        if not ProcessEmoteColorCommand(arguments) then
            -- Only show usage if the initial argument parsing failed in ProcessEmoteColorCommand
            ISChat.sendErrorToCurrentTab("Usage: /emotecolor <stream> <color> (e.g. /emotecolor me 255,0,0 or /emotecolor say #FFFF00)")
            -- Return true because the command was recognized, even if args were bad
            return true
        end
        return true -- Indicate command was handled

    end
end


function ISChat:onCommandEntered()
    local command = ISChat.instance.textEntry:getText()
    local chat = ISChat.instance

    -- *** Store the raw command IMMEDIATELY ***
    if command and command ~= '' then
        -- push to history, keep only the latest 5
        table.insert(ISChat.sentMessages, command)
        if #ISChat.sentMessages > 5 then
            table.remove(ISChat.sentMessages, 1)      -- drop oldest
        end
        ISChat.sentMessageIndex = nil                -- reset cursor
    end

    -- ******************************************

    -- If the command is empty, just unfocus and do nothing else
    if not command or command == '' then
        ISChat.instance:unfocus() -- Call unfocus here for the empty case
        --doKeyPress(false)         -- Still consume the Enter press
        return
    end

    -- Keep a separate variable for processing if needed, or just use 'command' carefully
    local processedCommand = command -- Use this if you modify it below

    local stream, commandName = GetCommandFromMessage(processedCommand)
    local ticsCommand = GetTicsCommandFromMessage(processedCommand)
    local commandWasProcessed = false -- Keep track if we actually did something

    if stream then -- chat message
        local messageBody = processedCommand
        if #commandName > 0 and #processedCommand >= #commandName then
            messageBody = string.sub(processedCommand, #commandName + 1)
        end
        if not IsOnlySpacesOrEmpty(messageBody) then
            if ProcessChatCommand(stream, messageBody) then -- Check if it succeeded
                chat.chatText.lastChatCommand = commandName
                chat:logChatCommand(command)
                commandWasProcessed = true
            end
            -- If ProcessChatCommand returned false (e.g., invalid PM target),
            -- we might want to *not* clear/unfocus, but for now, let's assume
            -- any attempt means we finish the sequence.
        end

    elseif ticsCommand ~= nil then
        -- Assuming ProcessTicsCommand handles its own errors/feedback
        ProcessTicsCommand(ticsCommand, command)
        commandWasProcessed = true -- Assume TICS commands always "process"
        -- even if they show an error message in chat.
    elseif luautils.stringStarts(command, '/') then -- server command
        SendCommandToServer(command)
        chat:logChatCommand(command)
        commandWasProcessed = true
        -- else: It wasn't a command recognized by TICS, likely plain text intended for the default stream
        -- This case seems missing in the original logic if the user just types "hello" without a command prefix.
        -- Let's add handling for the default stream if no command matched:
    else
        -- Get the default stream for the current tab
        local defaultStream = ISChat.defaultTabStream[ISChat.instance.currentTabID]
        if defaultStream and not IsOnlySpacesOrEmpty(command) then
            -- Process using the default stream (e.g., /say)
            if ProcessChatCommand(defaultStream, command) then -- Pass the whole text
                chat.chatText.lastChatCommand = defaultStream.command -- Store default command used
                chat:logChatCommand(defaultStream.command .. command) -- Log as if command was typed
                commandWasProcessed = true
            end
        end
    end

    -- *** Now, AFTER processing, unfocus and clean up ***
    ISChat.instance:unfocus() -- This clears text, sets flags, makes non-editable

    -- Consume the Enter key press to prevent other actions
    doKeyPress(false)
    ISChat.instance.timerTextEntry = 20 -- Reset the timer (likely for fade effects)

end




function ISChat.onPressUp(textEntryBox)
    if #ISChat.sentMessages == 0 then return end

    -- first ↑ after sending / typing
    if ISChat.sentMessageIndex == nil then
        ISChat.sentMessageIndex = #ISChat.sentMessages
        -- subsequent ↑ presses
    elseif ISChat.sentMessageIndex > 1 then
        ISChat.sentMessageIndex = ISChat.sentMessageIndex - 1
    end

    local msg = ISChat.sentMessages[ISChat.sentMessageIndex]
    textEntryBox:setText(msg)
    textEntryBox:setCursorPos(#msg)
end

function ISChat.onPressDown(textEntryBox)
    if #ISChat.sentMessages == 0 or ISChat.sentMessageIndex == nil then return end

    if ISChat.sentMessageIndex < #ISChat.sentMessages then
        ISChat.sentMessageIndex = ISChat.sentMessageIndex + 1
        local msg = ISChat.sentMessages[ISChat.sentMessageIndex]
        textEntryBox:setText(msg)
        textEntryBox:setCursorPos(#msg)
    else
        -- past newest → clear
        ISChat.sentMessageIndex = nil
        textEntryBox:setText('')
    end
end

local function BuildChannelPrefixString(channel)
    if channel == nil then
        return ''
    end
    local color
    if TicsServerSettings ~= nil then
        color = TicsServerSettings[channel]['color']
    else
        color = { 255, 255, 255 }
    end
    return StringBuilder.BuildBracketColorString(color) .. '[' .. channel .. '] '
end


local function BuildLanguagePrefixString(languageCode)
    if languageCode == nil then
        return ''
    end
    local color = { 162, 162, 185 }
    return StringBuilder.BuildBracketColorString(color) .. '(' .. languageCode .. ') '
end

local function FontStringToEnum(fontString)
    if fontString == 'small' then
        return UIFont.NewSmall
    elseif fontString == 'medium' then
        return UIFont.Medium
    else
        return UIFont.Large
    end
end

function ISChat:updateChatPrefixSettings()
    updateChatSettings(self.chatFont, self.showTimestamp, self.showTitle)
    for tabNumber, chatText in pairs(self.tabs) do
        chatText.firstPrintableLine = 1
        chatText.text = ""
        local newText = ""
        chatText.chatTextLines = {}
        chatText.chatTextRawLines = chatText.chatTextRawLines or {}
        chatText.defaultFont = FontStringToEnum(self.chatFont or 'medium')
        for i, msg in ipairs(chatText.chatTextRawLines) do
            self.chatFont = self.chatFont or 'medium'
            local showLanguage = TicsServerSettings and TicsServerSettings['options']['languages']
            local line = BuildChatMessage(self.chatFont, self.showTimestamp, self.showTitle, showLanguage, msg.language,
                    msg.line, msg.time, msg.channel)
            line = line .. StringBuilder.BuildNewLine()
            table.insert(chatText.chatTextLines, line)
            if i == #chatText.chatTextRawLines then
                line = string.gsub(line, " <LINE> $", "")
            end
            newText = newText .. line
        end
        chatText.text = newText
        chatText:paginate()
        chatText:scrollToBottom()
    end
end

local MessageTypeToColor = {
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
}

function BuildColorFromMessageType(type)
    if TicsServerSettings ~= nil
            and TicsServerSettings[type]
            and TicsServerSettings[type]['color']
    then
        return TicsServerSettings[type]['color']
    elseif MessageTypeToColor[type] == nil then
        error('unknown message type "' .. type .. '"')
    end
    return MessageTypeToColor[type]
end

local MessageTypeToVerb = {
    ['whisper'] = ' whispers, ',
    ['low'] = ' says quietly, ',
    ['say'] = ' says, ',
    ['yell'] = ' yells, ',
    ['radio'] = ' over the radio, ',
    ['scriptedRadio'] = 'over the radio, ',
    ['pm'] = ' ',
    ['faction'] = ' ',
    ['safehouse'] = ' ',
    ['general'] = ' ',
    ['admin'] = ' ',
    ['ooc'] = ' ',
    ['factionooc'] = ' ',
    ['globalevent'] = ' ',
    ['localevent'] = ' ! ',
}

function BuildVerbString(type)
    if MessageTypeToVerb[type] == nil then
        error('unknown message type "' .. type .. '"')
    end
    return MessageTypeToVerb[type]
end

local NoQuoteTypes = {
    ['general'] = true,
    ['safehouse'] = true,
    ['factionooc'] = true,
    ['admin'] = true,
    ['pm'] = true,
    ['ooc'] = true,
    ['localevent'] = true,
    ['globalevent'] = true,
}

function BuildQuote(type)
    if NoQuoteTypes[type] == true then
        return ''
    end
    return '"'
end

local function BuildPlayerNameString(playerName, playerColor)
    local colorToUse = playerColor or {255, 255, 255} -- Default white if nil
    return StringBuilder.BuildBracketColorString(colorToUse) .. playerName
end

local function highlightQuotedText(original, highlightColor, defaultColor)
    local highlightTag = StringBuilder.BuildBracketColorString(highlightColor)
    local defaultTag   = StringBuilder.BuildBracketColorString(defaultColor)

    -- Anything between straight quotes
    return original:gsub("\"(.-)\"", function(captured)
        -- 1.  Keep italic/bold colour where it appears.
        -- 2.  But every reset to the *message* colour inside the quote
        --     must become a reset to the *highlight* colour instead.
        local fixed = captured:gsub(defaultTag, highlightTag)

        return highlightTag .. "\"" .. fixed .. "\"" .. defaultTag
    end)
end


function BuildMessageFromPacket(type, message, name, nameColor, textColor, frequency, disableVerb) -- Added textColor
    -- Determine the message body color
    local messageColor = textColor -- Use the specific text color if provided
    if not messageColor then
        -- Fallback if no specific text color was sent (shouldn't happen often with ClientSend changes)
        messageColor = BuildColorFromMessageType(type)
    end

    -- Keep name color separate
    local playerNameColor = nameColor or {255, 255, 255} -- Default name color if none provided

    -- Parse the message using the determined message body color
    local parsedMessage = Parser.ParseTicsMessage(message, messageColor, 20, 200)

    if type == "me" or "melow" or "melong" or "whisperme" or "do" or "dolong" or "dolow" or "localevent" or
            "globalevent" then
        -- Suppose we pick bright yellow for quotes
        local highlightColor = { 255, 255, 255 }
        -- Overwrite the parsed body with highlighted quotes
        parsedMessage.body = highlightQuotedText(parsedMessage.body, highlightColor, messageColor)
    end

    local radioPrefix = ''
    if frequency then
        radioPrefix = '(' .. string.format('%.1fMHz', frequency / 1000) .. ') '
    end
    local messageColorString = StringBuilder.BuildBracketColorString(messageColor)
    local quote
    local verbString
    if not disableVerb and (TicsServerSettings == nil or TicsServerSettings['options']['verb'] == true)
            and type ~= 'do' and type ~= 'me' and type ~= 'whisperme' and type ~= 'melow' and type ~= 'melong' and type ~= 'dolow'
            and type ~= 'dolong' and type ~= 'localevent' and type ~= 'globalevent' -- Added emote types here
    then
        quote = BuildQuote(type)
        verbString = BuildVerbString(type)
    else
        quote = ''
        verbString = ' '
    end
    local formatedMessage = ''

    -- Handle emote prefixes like '*' or '**' - Should these use nameColor or messageColor? Usually messageColor.
    local emotePrefixColorString = messageColorString -- Use message color for *, **
    if type == 'do'  then
        formatedMessage = formatedMessage .. emotePrefixColorString .. '** ' -- Apply color to prefix
    elseif type == 'dolong' or type == 'melong' then
        formatedMessage = formatedMessage .. emotePrefixColorString .. '[long] '
    elseif type == 'me'  then -- Added whisperme, melow, melong
        formatedMessage = formatedMessage .. emotePrefixColorString .. '* ' -- Apply color to prefix
    elseif type == 'globalevent' then
        formatedMessage = formatedMessage .. emotePrefixColorString .. '[DM Event]' -- Apply color? Probably yes.
    elseif type == 'localevent' then
        formatedMessage = formatedMessage .. emotePrefixColorString .. '[Local Event]' -- Added local event prefix (example)
    elseif type == 'faction' then
        formatedMessage = formatedMessage .. emotePrefixColorString .. '(faction) '
    elseif type == 'whisperme' then
        formatedMessage = formatedMessage .. emotePrefixColorString .. '[whisper] '
    elseif type == 'melow' or type == 'dolow' then
        -- Both use "[low]"
        formatedMessage = formatedMessage .. emotePrefixColorString .. '[low] '
    elseif type == 'admindolong' then
        -- The new admin-only “long” => prefix "[DM]"
        formatedMessage = formatedMessage .. emotePrefixColorString .. '[DM] '

    end

    -- Player name uses nameColor
    if name ~= nil and type ~= 'do' and type ~= 'dolow' and type ~= 'dolong'
            and type ~= 'localevent' and type ~= 'globalevent' and type ~= 'admindolong' then
        -- BuildPlayerNameString uses the nameColor passed to it
        formatedMessage = formatedMessage .. BuildPlayerNameString(name, playerNameColor) -- Pass playerNameColor explicitly
    end

    -- Verb, radio prefix, message body
    local separatorColor = StringBuilder.BuildBracketColorString({ 150, 150, 150 }) -- Color for verb/separator
    local bodyColorTag = messageColorString -- Color tag for the message body and parentheses

    if type == 'ooc' or type == 'factionooc' then
        -- Special formatting for OOC / Faction OOC (quote is '', verbString is ' ')
        formatedMessage = formatedMessage .. separatorColor .. verbString ..
                bodyColorTag .. "(" .. parsedMessage.body .. ")"
        -- START ADDITION: Special handling for faction quotes --
    elseif type == 'faction' then
        -- Manually add quotes for faction, verbString is ' ' from exclusion above
        formatedMessage = formatedMessage ..
                separatorColor .. verbString .. radioPrefix ..
                bodyColorTag .. '"' .. parsedMessage.body .. bodyColorTag .. '"'
        -- END ADDITION --
    else
        -- Standard formatting for other types (uses quote/verbString determined by the combined logic)
        formatedMessage = formatedMessage ..
                separatorColor .. verbString .. radioPrefix ..
                bodyColorTag .. quote .. parsedMessage.body .. bodyColorTag .. quote
    end

    return formatedMessage, parsedMessage
end


function BuildChatMessage(fontSize, showTimestamp, showTitle, showLanguage, language, rawMessage, time, channel)
    local line = StringBuilder.BuildFontSizeString(fontSize)
    if showTimestamp and time then
        line = line .. StringBuilder.BuildTimePrefixString(time)
    end
    if showTitle and channel ~= nil then
        line = line .. BuildChannelPrefixString(channel)
    end
    if showLanguage and language and language ~= LanguageManager.DefaultLanguage then
        local languageCode = LanguageManager.GetCodeFromLanguage(language)
        line = line .. BuildLanguagePrefixString(languageCode)
    end
    line = line .. rawMessage
    return line
end

function CreatePlayerBubble(author, type, message, color, voiceEnabled, voicePitch, showPlayerName, authorName,
                            authorColor)
    ISChat.instance.bubble = ISChat.instance.bubble or {}
    ISChat.instance.typingDots = ISChat.instance.typingDots or {}
    if author == nil then
        print('TICS error: CreatePlayerBubble: author is null')
        return
    end
    local authorObj = World.getPlayerByUsername(author)
    if authorObj == nil then
        print('TICS error: CreatePlayerBubble: author not found ' .. author)
        return
    end
    local timer = 10
    local opacity = 70
    if TicsServerSettings then
        timer = TicsServerSettings['options']['bubble']['timer']
        opacity = TicsServerSettings['options']['bubble']['opacity']
    end
    local portrait = (TicsServerSettings and ISChat.instance.isPortraitEnabled and TicsServerSettings['options']['portrait'])
            or 1
    local isContext = type == 'me'
    local bubble = PlayerBubble:new(
            authorObj, isContext, message, color, timer, opacity, voiceEnabled, voicePitch, portrait, showPlayerName,
            authorName, authorColor)
    ISChat.instance.bubble[author] = bubble
    -- the player is not typing anymore if his bubble appears
    if ISChat.instance.typingDots[author] ~= nil then
        ISChat.instance.typingDots[author] = nil
    end
end

local function CreateSquareRadioBubble(position, message, messageColor, voicePitch)
    ISChat.instance.radioBubble = ISChat.instance.radioBubble or {}
    if position ~= nil then
        local x, y, z = position['x'], position['y'], position['z']
        if x == nil or y == nil or z == nil then
            print('TICS error: CreateSquareRadioBubble: nil position for a square radio')
            return
        end
        x, y, z = math.abs(x), math.abs(y), math.abs(z)
        if ISChat.instance.radioBubble['x' .. x .. 'y' .. y .. 'z' .. z] ~= nil then
            ISChat.instance.radioBubble['x' .. x .. 'y' .. y .. 'z' .. z].dead = true
        end
        local timer = 10
        local opacity = 70
        local square = getSquare(x, y, z)
        local radios = World.getSquareItemsByGroup(square, 'IsoRadio')
        local offsetY = 0
        if radios ~= nil and #radios > 0 then
            local radio = radios[1]
            offsetY = radio:getRenderYOffset()
        end
        local bubble = RadioBubble:new(
                square, message, messageColor, timer, opacity, RadioBubble.types.square,
                ISChat.instance.isVoiceEnabled, voicePitch, offsetY)
        ISChat.instance.radioBubble['x' .. x .. 'y' .. y .. 'z' .. z] = bubble
    end
end

function CreatePlayerRadioBubble(author, message, messageColor, voicePitch)
    ISChat.instance.playerRadioBubble = ISChat.instance.playerRadioBubble or {}
    if author == nil then
        print('TICS error: CreatePlayerRadioBubble: author is null')
        return
    end
    local authorObj = World.getPlayerByUsername(author)
    if authorObj == nil then
        print('TICS error: CreatePlayerRadioBubble: author not found ' .. author)
        return
    end
    local timer = 10
    local opacity = 70
    if TicsServerSettings then
        timer = TicsServerSettings['options']['bubble']['timer']
        opacity = TicsServerSettings['options']['bubble']['opacity']
    end
    local bubble = RadioBubble:new(authorObj, message, messageColor, timer, opacity,
            RadioBubble.types.player, ISChat.instance.isVoiceEnabled, voicePitch)
    ISChat.instance.playerRadioBubble[author] = bubble
end

function CreateVehicleRadioBubble(vehicle, message, messageColor, voicePitch)
    ISChat.instance.vehicleRadioBubble = ISChat.instance.vehicleRadioBubble or {}
    local timer = 10
    local opacity = 70
    if TicsServerSettings then
        timer = TicsServerSettings['options']['bubble']['timer']
        opacity = TicsServerSettings['options']['bubble']['opacity']
    end
    local keyId = vehicle:getKeyId()
    if keyId == nil then
        print('TICS error: CreateVehicleBubble: key id is null')
        return
    end
    local bubble = RadioBubble:new(vehicle, message, messageColor, timer, opacity,
            RadioBubble.types.vehicle, ISChat.instance.isVoiceEnabled, voicePitch)
    ISChat.instance.vehicleRadioBubble[keyId] = bubble
end

function ISChat.onTypingPacket(author, type)
    ISChat.instance.typingDots = ISChat.instance.typingDots or {}
    local onlineUsers = getOnlinePlayers()
    local authorObj = nil
    for i = 0, onlineUsers:size() - 1 do
        local user = onlineUsers:get(i)
        if user:getUsername() == author then
            authorObj = onlineUsers:get(i)
            break
        end
    end
    if authorObj == nil then
        return
    end
    if ISChat.instance.typingDots[author] then
        ISChat.instance.typingDots[author]:refresh()
    else
        ISChat.instance.typingDots[author] = TypingDots:new(authorObj, 1)
    end
end

local function GetStreamFromType(type)
    for _, stream in ipairs(ISChat.allChatStreams) do
        if type == stream['name'] then
            return stream
        end
    end
    return nil
end

local function AddMessageToTab(tabID, language, time, formattedMessage, line, channel)
    if not ISChat.instance.chatText then
        ISChat.instance.chatText = ISChat.instance.defaultTab
        ISChat.instance:onActivateView()
    end
    local chatText = ISChat.instance.tabs[tabID]

    chatText.chatTextRawLines = chatText.chatTextRawLines or {}
    table.insert(chatText.chatTextRawLines,
            {
                time = time,
                line = formattedMessage,
                channel = channel,
                language = language,
            })
    local chatTextRawLinesSize = #chatText.chatTextRawLines
    local maxRawMessages = chatText.maxLines
    if chatTextRawLinesSize > maxRawMessages then
        local newRawLines = {}
        for i = chatTextRawLinesSize - maxRawMessages, chatTextRawLinesSize do
            table.insert(newRawLines, chatText.chatTextRawLines[i])
        end
        chatText.chatTextRawLines = newRawLines
    end
    if chatText.tabTitle ~= ISChat.instance.chatText.tabTitle then
        local alreadyExist = false
        for _, blinkedTab in pairs(ISChat.instance.panel.blinkTabs) do
            if blinkedTab == chatText.tabTitle then
                alreadyExist = true
                break
            end
        end
        if alreadyExist == false then
            table.insert(ISChat.instance.panel.blinkTabs, chatText.tabTitle)
        end
    end
    local vscroll = chatText.vscroll
    local scrolledToBottom = (chatText:getScrollHeight() <= chatText:getHeight()) or (vscroll and vscroll.pos == 1)
    if #chatText.chatTextLines > ISChat.maxLine then
        local newLines = {}
        for i, v in ipairs(chatText.chatTextLines) do
            if i ~= 1 then
                table.insert(newLines, v)
            end
        end
        table.insert(newLines, line .. StringBuilder.BuildNewLine())
        chatText.chatTextLines = newLines
    else
        table.insert(chatText.chatTextLines, line .. StringBuilder.BuildNewLine())
    end
    chatText.text = ''
    local newText = ''
    local chatTextLinesCount = #chatText.chatTextLines
    for i, v in ipairs(chatText.chatTextLines) do
        if i == chatTextLinesCount then
            v = string.gsub(v, ' <LINE> $', '')
        end
        newText = newText .. v
    end
    chatText.text = newText
    chatText:paginate()
    if scrolledToBottom then
        chatText:scrollToBottom()
    end
end

local lastHungerThirstHour = -1

local function ReduceBoredomOnReceive()
    local player = getPlayer()
    local body = player:getBodyDamage()
    local stats = player:getStats()

    -- 🟣 Always reduce boredom
    local boredom = body:getBoredomLevel()
    local boredomReduction = 0
    if TicsServerSettings then
        boredomReduction = TicsServerSettings['options']['boredomReduction']
    end
    body:setBoredomLevel(boredom - boredomReduction)

    -- 🔵 Reduce hunger/thirst once per in-game hour
    local currentHour = getGameTime():getHour()
    if currentHour ~= lastHungerThirstHour then
        -- Hunger
        local hunger = stats:getHunger()
        local hungerReduction = 0.30
        stats:setHunger(math.max(0, hunger - hungerReduction))

        -- Thirst
        local thirst = stats:getThirst()
        local thirstReduction = 0.30
        stats:setThirst(math.max(0, thirst - thirstReduction))

        -- Update cooldown timestamp
        lastHungerThirstHour = currentHour

        -- ✅ Show message in the player’s chatbox
        -- ISChat.sendInfoToCurrentTab("You feel less stressed!")
    end
end


function ISChat.onDiceResult(author, characterName, diceCount, diceType, addCount, diceResults, finalResult)
    local name = characterName
    if TicsServerSettings and not TicsServerSettings['options']['showCharacterName'] then
        name = author
    end
    local message = name .. ' rolled ' .. diceCount .. 'd' .. diceType
    if addCount then
        if addCount >= 0 then
            message = message .. '+' .. addCount
        else
            message = message .. addCount          -- already carries the '-'
        end
    end
    message = message .. ' ('
    local first = true
    for _, r in pairs(diceResults) do
        if first then
            first = false
        else
            message = message .. ', '
        end
        message = message .. r
    end
    message = message .. ')'
    if addCount ~= nil then
        if addCount >= 0 then
            message = message .. '+' .. addCount
        else
            message = message .. addCount        -- already carries the ‘‑’
        end
    end
    message = message .. ' = ' .. finalResult
    ISChat.sendInfoToCurrentTab(message)
end

local function CapitalizeAndPonctuate(message)
    message = message:gsub("^%l", string.upper)
    local lastChar = string.sub(message, message:len())
    if not (lastChar == "." or lastChar == "!" or lastChar == "?") then
        message = message .. "."
    end
    return message
end

-- Create a set of chat types that trigger the stat buff
local buffTriggerTypes = {
    say       = true,
    yell      = true,
    me        = true,
    melow     = true,
    whisperme = true,  -- if /wme is recognized internally as whisperme
    low       = true,
    whisper   = true,
}

-- Pass the received textColor to BuildMessageFromPacket
-- Completely REPLACE your existing ISChat.onMessagePacket function with this:

function ISChat.onMessagePacket(
        type, author, characterName, message, language,
        nameColor, textColorFromServer, hideInChat, target, isFromDiscord, voicePitch, disableVerb
)
    -- 1) Possibly reduce boredom if it’s chat from someone else
    if author ~= getPlayer():getUsername() then
        ReduceBoredomOnReceive()
    end

    -- 2) If server config says “hide character name,” we fall back to just the author’s username
    local displayName = characterName
    if TicsServerSettings and not TicsServerSettings['options']['showCharacterName'] then
        displayName = author
    end

    -- 3) If server config wants to auto-capitalize, do that
    local updatedMessage = message
    if TicsServerSettings ~= nil and TicsServerSettings['options']['capitalize'] == true then
        updatedMessage = CapitalizeAndPonctuate(updatedMessage)
    end

    -- 4) If it’s a /pm to me, record the sender so we can reply with /r
    if type == 'pm' and target and target:lower() == getPlayer():getUsername():lower() then
        ISChat.instance.lastPrivateMessageAuthor = author
    end

    -- 5) Because some code depends on these existing variables
    ISChat.instance.chatFont   = ISChat.instance.chatFont or 'medium'
    local showLanguage         = TicsServerSettings and TicsServerSettings['options']['languages']
    local showBubble           = TicsServerSettings and TicsServerSettings[type] and TicsServerSettings[type]['bubble']

    -- ─────────────────────────────────────────────────────────────────────────
    --         THIS IS WHERE WE IGNORE SERVER `textColor` AND USE OURS
    -- ─────────────────────────────────────────────────────────────────────────

    -- a) Grab local modData
    local modData = ISChat.instance and ISChat.instance.ticsModData
    local emoteColors = modData and modData.emoteColors

    -- b) Check if the user has a local custom color for this chat type
    local localColor
    if emoteColors and emoteColors[type] then
        localColor = emoteColors[type]            -- /emotecolor setting
    else
        localColor = BuildColorFromMessageType(type)  -- fallback
    end

    -- ─────────────────────────────────────────────────────────────────────────
    --         BUBBLE (speech bubble) logic – uses localColor
    -- ─────────────────────────────────────────────────────────────────────────

    -- Add the check for ISChat.instance.showChatBubbles here!
    if ISChat.instance.showChatBubbles and not isFromDiscord and voicePitch ~= nil and showBubble
            and type ~= 'do' and type ~= 'dolow' and type ~= 'dolong' -- Added the new check
    then
        -- If the server uses languages but we *don’t* know the language, scramble message
        local isAdmin = getPlayer():getAccessLevel() == "Admin"
        local knowsLanguage = LanguageManager:isKnown(language)

        if showLanguage and not isAdmin and not knowsLanguage then
            -- For emotes, only scramble quoted parts
            if type == 'me' or type == 'do'
                    or type == 'whisperme' or type == 'melow'
                    or type == 'melong' or type == 'dolow'
                    or type == 'dolong'
            then
                updatedMessage = updatedMessage:gsub('"([^"]+)"', function(quotedText)
                    return '"' .. LanguageManager:getRandomMessage(quotedText, language) .. '"'
                end)
            else
                updatedMessage = LanguageManager:getRandomMessage(updatedMessage, language)
            end
        end

        -- Create a separate variable for the bubble text
        local bubbleMessageText = updatedMessage

        -- Add parentheses specifically for the bubble if it's OOC
        if type == 'ooc' then
            bubbleMessageText = "(" .. bubbleMessageText .. ")"
        end

        -- If it’s /ooc, skip voice
        local voiceEnabled = ISChat.instance.isVoiceEnabled and (type ~= 'ooc')

        CreatePlayerBubble(
                author,
                type,
                bubbleMessageText,   -- <<< USE THE CORRECT VARIABLE HERE
                localColor,          -- bubble color
                voiceEnabled,
                voicePitch,
                (type == 'me' or type == 'whisperme' or type == 'melow' or type == 'melong'),
                displayName,         -- what name to show
                nameColor            -- color for the *name*
        )
    end

    -- ─────────────────────────────────────────────────────────────────────────
    --         Admin Knows ALl / Language Obfuscation for non-say
    -- ─────────────────────────────────────────────────────────────────────────

    -- Language obfuscation logic
    local player = getPlayer()
    local isAdmin = player:getAccessLevel() == "Admin"
    local knowsLanguage = LanguageManager:isKnown(language)

    if showLanguage and not isAdmin and not knowsLanguage then
        -- Emote-type: scramble ONLY quoted dialogue ("...")
        if type == 'me' or type == 'do'
                or type == 'whisperme' or type == 'melow'
                or type == 'melong' or type == 'dolow'
                or type == 'dolong'
        then
            updatedMessage = updatedMessage:gsub('"([^"]+)"', function(quotedText)
                return '"' .. LanguageManager:getRandomMessage(quotedText, language) .. '"'
            end)
        else
            -- say, yell, low, whisper, etc. — scramble everything
            updatedMessage = LanguageManager:getRandomMessage(updatedMessage, language)
        end
    end



    -- ─────────────────────────────────────────────────────────────────────────
    --         MAIN CHAT WINDOW logic – also uses localColor
    -- ─────────────────────────────────────────────────────────────────────────

    -- 1) Build the chat line we’ll display locally
    local formattedMessage, parsedMessage =
    BuildMessageFromPacket(
            type,
            updatedMessage,
            displayName,
            nameColor,
            localColor,      -- <== Our local color, ignoring textColorFromServer
            nil,             -- no frequency
            disableVerb
    )

    -- 2) Build the final line with timestamp, tags, language code, etc.
    local time = Calendar.getInstance():getTimeInMillis()
    local line = BuildChatMessage(
            ISChat.instance.chatFont,
            ISChat.instance.showTimestamp,
            ISChat.instance.showTitle,
            showLanguage,
            language,
            formattedMessage,
            time,
            type
    )

    -- 3) Figure out which “stream” (like “say” vs. “whisper”) we should display it in
    local stream = GetStreamFromType(type)
    if not stream then
        print('TICS error: onMessagePacket: stream not found for type ' .. type)
        -- fallback to “say” if you like
        stream = ISChat.allChatStreams[1]
        if not stream then
            return
        end
    end

    -- 4) Actually show it, unless the server says “hideInChat”
    if not hideInChat then
        AddMessageToTab(
                stream['tabID'],
                language,
                time,
                formattedMessage,
                line,
                stream['name']
        )
    end
end


function BuildServerMessage(fontSize, showTimestamp, showTitle, rawMessage, time, channel)
    local line = StringBuilder.BuildFontSizeString(fontSize)
    if showTimestamp then
        line = line .. StringBuilder.BuildTimePrefixString(time)
    end
    if showTitle and channel ~= nil then
        line = line .. BuildChannelPrefixString(channel)
    end
    line = line .. rawMessage
    return line
end

function ISChat.onServerMessage(message)
    local color = (TicsServerSettings and TicsServerSettings['server']['color']) or { 255, 86, 64 }
    local time = Calendar.getInstance():getTimeInMillis()
    local stream = GetStreamFromType('general')
    if stream == nil then
        print('TICS error: onMessagePacket: stream not found')
        return
    end
    local parsedMessage = Parser.ParseTicsMessage(message, color, 20, 200)
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, ISChat.instance.showTitle,
            false, nil, parsedMessage.body, time, 'server')
    AddMessageToTab(stream['tabID'], nil, time, parsedMessage.body, line, 'server')
end

local function CreateSquaresRadiosBubbles(message, messageColor, squaresInfo, voicePitch)
    if squaresInfo == nil then
        print('TICS error: CreateSquaresRadiosBubbles: squaresInfo table is null')
        return
    end
    for _, info in pairs(squaresInfo) do
        local position = info['position']
        if position ~= nil then
            CreateSquareRadioBubble(position, message, messageColor, voicePitch)
            local square = getSquare(position['x'], position['y'], position['z'])
            if square ~= nil then
                local radio = World.getFirstSquareItem(square, 'IsoRadio')
                if radio ~= nil then
                    local radioData = radio:getDeviceData()
                    if radioData ~= nil then
                        local distance = info['distance']
                        if distance ~= nil then
                            radioData:doReceiveSignal(distance)
                        else
                            print('TICS error: received radio packet for a square radio without distance')
                        end
                    else
                        print('TICS error: received radio packet for a square radio without data')
                    end
                else
                    print('TICS error: received radio packet for a square with no radio')
                end
            else
                print('TICS error: received radio packet for a null square')
            end
        else
            print('TICS error: received radio packet for a square without position')
        end
    end
end

local function CreatePlayersRadiosBubbles(message, messageColor, playersInfo, voicePitch)
    if playersInfo == nil then
        print('TICS error: CreatePlayersRadiosBubbles: playersInfo table is null')
        return
    end
    for _, info in pairs(playersInfo) do
        local username = info['username']
        if username ~= nil then
            CreatePlayerRadioBubble(
                    getPlayer():getUsername(), message, messageColor, voicePitch)
            if username:upper() == getPlayer():getUsername():upper() then
                local radio = Character.getFirstHandOrBeltItemByGroup(getPlayer(), 'Radio')
                if radio ~= nil then
                    local radioData = radio:getDeviceData()
                    if radioData ~= nil then
                        local distance = info['distance']
                        if distance ~= nil then
                            radioData:doReceiveSignal(distance)
                        else
                            print('TICS error: received radio packet for a player radio without distance')
                        end
                    else
                        print('TICS error: received radio packet for a player radio without data')
                    end
                else
                    print('TICS error: received radio packet for a player with no radio in hand')
                end
            end
        else
            print('TICS error: received radio packet for a player without username')
        end
    end
end

local function CreateVehiclesRadiosBubbles(message, messageColor, vehiclesInfo, voicePitch)
    if vehiclesInfo == nil then
        print('TICS error: CreateVehiclesRadiosBubbles: vehiclesKeyIds table is null')
        return
    end
    local range = (TicsServerSettings and TicsServerSettings['say']['range']) or 15
    local vehicles = World.getVehiclesInRange(getPlayer(), range)
    for _, info in pairs(vehiclesInfo) do
        local vehicleKeyId = info['key']
        if vehicleKeyId ~= nil then
            local vehicle = vehicles[vehicleKeyId]
            if vehicle ~= nil then
                CreateVehicleRadioBubble(vehicle, message, messageColor, voicePitch)
                local radio = vehicle:getPartById('Radio')
                if radio ~= nil then
                    local radioData = radio:getDeviceData()
                    if radioData ~= nil then
                        local distance = info['distance']
                        if distance ~= nil then
                            radioData:doReceiveSignal(distance)
                        else
                            print('TICS error: received radio packet for a vehicle radio without distance')
                        end
                    else
                        print('TICS error: received radio packet for a vehicle radio without data')
                    end
                else
                    print('TICS error: received radio packet for a vehicle with no radio')
                end
            else
                print('TICS error: CreateVehiclesRadiosBubble: vehicle not found for key id ' .. vehicleKeyId)
            end
        else
            print('TICS error: received vehicle packet for a vehicle with no key')
        end
    end
end

function ISChat.onDiscordPacket(message)
    processGeneralMessage(message)
end

-- Pass textColor (likely nil for radio, but maintain signature)
function ISChat.onRadioEmittingPacket(type, author, characterName, message, language, nameColor, textColor, frequency, disableVerb) -- Added textColor
    local time = Calendar.getInstance():getTimeInMillis()
    local stream = GetStreamFromType(type)
    if stream == nil then
        print('TICS error: onRadioEmittingPacket: stream not found for type '.. type)
        stream = ISChat.allChatStreams[1] -- Fallback
        if not stream then return end
    end
    local name = characterName
    if TicsServerSettings and not TicsServerSettings['options']['showCharacterName'] then
        name = author
    end
    local cleanMessage = message
    if TicsServerSettings ~= nil and TicsServerSettings['options']['capitalize'] == true then
        cleanMessage = CapitalizeAndPonctuate(message)
    end
    -- Pass nameColor and textColor
    local formattedMessage, parsedMessages = BuildMessageFromPacket(type, cleanMessage, name, nameColor, textColor, frequency, disableVerb)
    local showLanguage = TicsServerSettings and TicsServerSettings['options']['languages']
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, ISChat.instance.showTitle,
            showLanguage, language, formattedMessage, time, type)
    AddMessageToTab(stream['tabID'], language, time, formattedMessage, line, stream['name'])
end

-- Pass textColor
function ISChat.onRadioPacket(type, author, characterName, message, language, nameColor, textColor, radiosInfo, voicePitch, disableVerb) -- Added textColor
    if _G.type(radiosInfo) ~= "table" then
        -- shift everything one slot to the right
        disableVerb  = voicePitch        -- bool  ← was arg 9
        voicePitch   = radiosInfo        -- number ← was arg 8
        radiosInfo   = textColor         -- table  ← was arg 7
        textColor    = nameColor         -- RGB    ← was arg 6
        nameColor    = textColor         -- use the single colour for both
    end
    local time = Calendar.getInstance():getTimeInMillis()
    local stream = GetStreamFromType(type)
    if stream == nil then
        print('TICS error: onRadioPacket: stream not found for type ' .. type)
        stream = ISChat.allChatStreams[1] -- Fallback
        if not stream then return end
    end

    local playerName = getPlayer():getUsername()
    if author ~= playerName then
        ReduceBoredomOnReceive()
    end
    local name = characterName
    if TicsServerSettings and not TicsServerSettings['options']['showCharacterName'] then
        name = author
    end
    local updatedMessage = message
    if TicsServerSettings ~= nil and TicsServerSettings['options']['capitalize'] == true then
        updatedMessage = CapitalizeAndPonctuate(updatedMessage)
    end
    local showLanguage = TicsServerSettings and TicsServerSettings['options']['languages']

    -- Bubble color for radio: Use textColor if provided, else default radio color
    local bubbleColor = textColor or BuildColorFromMessageType(type)

    for frequency, radios in pairs(radiosInfo) do
        if showLanguage and not LanguageManager:isKnown(language) then
            updatedMessage = LanguageManager:getRandomMessage(updatedMessage, language)
        end
        -- Use bubbleColor determined above
        CreateSquaresRadiosBubbles(updatedMessage, bubbleColor, radios['squares'], voicePitch)
        CreatePlayersRadiosBubbles(updatedMessage, bubbleColor, radios['players'], voicePitch)
        CreateVehiclesRadiosBubbles(updatedMessage, bubbleColor, radios['vehicles'], voicePitch)

        -- Pass nameColor and textColor
        local formattedMessage, parsedMessages = BuildMessageFromPacket(type, updatedMessage, name, nameColor, textColor, frequency, disableVerb)
        local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, ISChat.instance.showTitle,
                showLanguage, language, formattedMessage, time, type)
        -- ... (rest of logic for not adding message if author is self) ...
        if author ~= playerName then
            AddMessageToTab(stream['tabID'], language, time, formattedMessage, line, stream['name'])
        end
    end
end

function ISChat.sendInfoToCurrentTab(message)
    local time = Calendar.getInstance():getTimeInMillis()
    local formattedMessage = StringBuilder.BuildBracketColorString({ 255, 255, 255 }) .. message
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, false,
            false, nil, formattedMessage, time, nil)
    local tabID = ISChat.defaultTabStream[ISChat.instance.currentTabID]['tabID']
    AddMessageToTab(tabID, nil, time, formattedMessage, line, nil)
end

function ISChat.sendErrorToCurrentTab(message)
    local time = Calendar.getInstance():getTimeInMillis()
    local formattedMessage = StringBuilder.BuildBracketColorString({ 255, 40, 40 }) ..
            'error: ' .. StringBuilder.BuildBracketColorString({ 255, 70, 70 }) .. message
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, false,
            false, nil, formattedMessage, time, nil)
    local tabID = ISChat.defaultTabStream[ISChat.instance.currentTabID]['tabID']
    AddMessageToTab(tabID, nil, time, formattedMessage, line, nil)
end

function ISChat.onChatErrorPacket(type, message)
    local time = Calendar.getInstance():getTimeInMillis()
    local formattedMessage = StringBuilder.BuildBracketColorString({ 255, 50, 50 }) ..
            'error: ' .. StringBuilder.BuildBracketColorString({ 255, 60, 60 }) .. message
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, ISChat.instance.showTitle,
            false, nil, formattedMessage, time, type)
    local stream
    if type == nil then
        stream = ISChat.defaultTabStream[ISChat.instance.currentTabID]
    else
        stream = GetStreamFromType(type)
        if stream == nil then
            stream = ISChat.defaultTabStream[ISChat.instance.currentTabID]
        end
    end
    AddMessageToTab(stream['tabID'], nil, time, formattedMessage, line)
end

local function GetMessageType(message)
    if message.toString == nil then
        return nil
    end
    local stringRep = message:toString()
    return stringRep:match('^ChatMessage{chat=(%a*),')
end

local function GenerateRadiosPacketFromListeningRadiosInRange(frequency)
    if TicsServerSettings == nil then
        return nil
    end
    local maxSoundRange = TicsServerSettings['options']['radio']['soundMaxRange']
    local radios = FakeRadioPacket.getListeningRadiosPositions(getPlayer(), maxSoundRange, frequency)
    if radios == nil then
        return nil
    end
    return {
        [frequency] = radios
    }
end

local function RemoveDiscordMessagePrefix(message)
    local regex = '<@%d+>(.*)'
    return message:match(regex)
end

-- TODO: try to clean this mess copied from the base game
ISChat.addLineInChat = function(message, tabID)
    if UdderlyUpToDate and
            message.setOverHeadSpeech == nil and
            message.isFromDiscord == nil and
            message.getDatetimeStr == nil
    then -- probably a fake message from UdderlyUpToDate mod
        ISChat.sendErrorToCurrentTab(message:getText())
        return
    end

    local messageType = GetMessageType(message)
    local line = message:getText()
    if messageType == nil then
        ISChat.sendInfoToCurrentTab(line)
        return
    end

    if message:getAuthor() == 'Server' then
        ISChat.sendInfoToCurrentTab(line)
    elseif message:getRadioChannel() ~= -1 then -- scripted radio message
        local messageWithoutColorPrefix = message:getText():gsub('*%d+,%d+,%d+*', '')
        message:setText(messageWithoutColorPrefix)
        local color = (TicsServerSettings and TicsServerSettings['scriptedRadio']['color']) or {
            171, 240, 140,
        }
        ISChat.onRadioPacket(
                'scriptedRadio',
                nil,
                nil,
                messageWithoutColorPrefix,
                'en',
                color,
                {}, -- todo find a way to locate the radio
                message:getRadioChannel(),
                false
        )
    else
        message:setOverHeadSpeech(false)
    end

    if messageType == 'Local' then -- when pressing Q to shout
        local player = World.getPlayerByUsername(message:getAuthor())
        local firstName, lastName = Character.getFirstAndLastName(player)
        local characterName = firstName .. ' ' .. lastName
        ISChat.onMessagePacket(
                'yell',
                message:getAuthor(),
                characterName,
                line,
                LanguageManager.DefaultLanguage,
                { 255, 255, 255 },
                TicsServerSettings and TicsServerSettings['options'] and
                        TicsServerSettings['options']['hideCallout'] or nil,
                nil,
                false,
                ISChat.instance.ticsModData['voicePitch'],
                false
        )
    end

    if message:isFromDiscord() then
        local currentDiscordMessage = message:getDatetimeStr() .. message:getText()
        local currentTime = Calendar.getInstance():getTimeInMillis()
        local isDuplicate = false
        local toRemove = {}
        for key, discordMessageInfo in pairs(ISChat.instance.lastDiscordMessages) do
            local discordMessage = discordMessageInfo['message']
            local discordMessageTime = discordMessageInfo['time']
            if currentTime - discordMessageTime < 2000 then
                if discordMessage == currentDiscordMessage then
                    isDuplicate = true
                end
            else
                table.insert(toRemove, key)
            end
        end
        for _, key in pairs(toRemove) do
            ISChat.instance.lastDiscordMessages[key] = nil
        end
        if isDuplicate then
            return
        end
        table.insert(ISChat.instance.lastDiscordMessages, {
            message = currentDiscordMessage,
            time = currentTime
        })
        local discordColor = { 88, 101, 242 } -- discord logo color
        local messageWithoutPrefix = RemoveDiscordMessagePrefix(line)
        if messageWithoutPrefix == nil then
            -- for some reason some servers receive discord messages without the @discord-id-of-bot prefix
            messageWithoutPrefix = line
        end
        if TicsServerSettings and TicsServerSettings['general']
                and TicsServerSettings['general']['discord']
                and TicsServerSettings['general']['enabled']
        then
            ISChat.onMessagePacket(
                    'general',
                    message:getAuthor(),
                    message:getAuthor(),
                    messageWithoutPrefix,
                    'en',
                    discordColor,
                    false,
                    nil,
                    true,
                    1.15, -- voice pitch, should not be used anyway
                    false
            )
        end
        if TicsServerSettings and TicsServerSettings['options']
                and TicsServerSettings['options']['radio']
                and TicsServerSettings['options']['radio']['discord']
        then
            local frequency = TicsServerSettings['options']['radio']['frequency']
            if frequency then
                local radiosInfo = GenerateRadiosPacketFromListeningRadiosInRange(frequency)
                if radiosInfo ~= nil then
                    ISChat.onRadioPacket(
                            'say',
                            message:getAuthor(),
                            message:getAuthor(),
                            messageWithoutPrefix,
                            'en',
                            discordColor,
                            radiosInfo,
                            1.15,
                            false
                    )
                end
            end
        end
        return
    elseif message:isServerAlert() then
        ISChat.instance.servermsg = ''
        if message:isShowAuthor() then
            ISChat.instance.servermsg = message:getAuthor() .. ': '
        end
        ISChat.instance.servermsg = ISChat.instance.servermsg .. message:getText()
        ISChat.instance.servermsgTimer = 5000
        ISChat.instance.onServerMessage(line)
        return
    else
        return
    end
end

function ISChat:render()
    ChatUI.render(self)
end

function ISChat:prerender()
    local instance = ISChat.instance

    instance:createValidationWindowButton()

    if instance.rangeIndicator ~= nil then
        if instance.rangeButtonState == 'visible' then
            if ISChat.instance.focused then
                instance.rangeIndicator:subscribe()
            else
                instance.rangeIndicator:unsubscribe()
            end
        elseif instance.rangeButtonState == 'hidden' then
            instance.rangeIndicator:unsubscribe()
        else
            instance.rangeIndicator:subscribe()
        end
    end

    local allBubbles = {
        instance.radioBubble,
        instance.vehicleRadioBubble,
        instance.playerRadioBubble,
        instance.bubble,
        instance.typingDots
    }
    for _, bubbles in pairs(allBubbles) do
        local indexToDelete = {}
        for index, bubble in pairs(bubbles) do
            if bubble.dead then
                table.insert(indexToDelete, index)
            else
                bubble:render()
            end
        end
        for _, index in pairs(indexToDelete) do
            bubbles[index] = nil
        end
    end
    ChatUI.prerender(self)
end

function IsOnlyCommand(text)
    return text:match('/%a* *') == text
end

function ISChat.onTextChange()
    ISChat.sentMessageIndex = nil   -- typing resets history cursor
    local t = ISChat.instance.textEntry
    local internalText = t:getInternalText()
    if #internalText > 1
            and IsOnlyCommand(internalText:sub(1, #internalText - 1))
            and internalText:sub(#internalText) == '/'
    then
        t:setText("/")
        if ISChat.instance.rangeIndicator then
            ISChat.instance.rangeIndicator:unsubscribe()
        end
        ISChat.instance.rangeIndicator = nil
        ISChat.instance.lastStream = nil
        return
    end

    if internalText == '/r' and ISChat.instance.lastPrivateMessageAuthor ~= nil
            and ISChat.instance.currentTabID == 3
    then
        t:setText('/pm ' .. ISChat.instance.lastPrivateMessageAuthor .. ' ')
        return
    end
    local stream = GetCommandFromMessage(internalText)
    if stream ~= nil then
        if ISChat.instance.lastStream ~= stream then
            UpdateRangeIndicator(stream)
        end
        -- you are allowed to use a command from another tab but it wont be remembered for the next message
        -- /me* commands are also not remembered as they should be occasional
        if ISChat.instance.currentTabID == stream['tabID'] and not stream['forget'] then
            ISChat.lastTabStream[ISChat.instance.currentTabID] = stream
        end
        local streamName = stream['name']
        ClientSend.sendTyping(getPlayer():getUsername(), streamName)
    else
        if ISChat.instance.rangeIndicator then
            ISChat.instance.rangeIndicator:unsubscribe()
        end
        ISChat.instance.rangeIndicator = nil
    end
    ISChat.instance.lastStream = stream
end

function ISChat:onActivateView()
    if self.tabCnt > 1 then
        self.chatText = self.panel.activeView.view
    end
    for i, blinkedTab in ipairs(self.panel.blinkTabs) do
        if self.chatText.tabTitle and self.chatText.tabTitle == blinkedTab then
            table.remove(self.panel.blinkTabs, i)
            break
        end
    end
end

local function RenderChatText(chat)
    chat:setStencilRect(0, 0, chat.width, chat.height)
    ChatText.render(chat)
    chat:clearStencilRect()
end

function ISChat:createTab()
    local chatY = self:titleBarHeight() + self.btnHeight + 2 * self.inset
    local chatHeight = self.textEntry:getY() - chatY
    local chatText = ChatText:new(0, chatY, self:getWidth(), chatHeight)
    chatText.maxLines = 100
    chatText:initialise()
    chatText.background = false
    chatText:setAnchorBottom(true)
    chatText:setAnchorRight(true)
    chatText:setAnchorTop(true)
    chatText:setAnchorLeft(true)
    chatText.log = {}
    chatText.logIndex = 0
    chatText.marginTop = 2
    chatText.marginBottom = 0
    chatText.onRightMouseUp = nil
    chatText.render = RenderChatText
    chatText.autosetheight = false
    chatText:addScrollBars()
    chatText.vscroll:setVisible(false)
    chatText.vscroll.background = false
    chatText:ignoreHeightChange()
    chatText:setVisible(false)
    chatText.chatTextLines = {}
    chatText.chatMessages = {}
    chatText.onRightMouseUp = ISChat.onRightMouseUp
    chatText.onRightMouseDown = ISChat.onRightMouseDown
    chatText.onMouseUp = ISChat.onMouseUp
    chatText.onMouseDown = ISChat.onMouseDown
    return chatText
end

ISChat.onTabAdded = function(tabTitle, tabID)
    -- callback from the Java
    -- 0 is General
    -- 1 is Admin
    if tabID == 1 then
        if TicsServerSettings ~= nil and TicsServerSettings['admin']['enabled']
                and ISChat.instance.tabs[4] == nil then
            AddTab('Admin', 4)
        end
    end
end

local function GetFirstTab()
    if ISChat.instance.tabs == nil then
        return nil
    end
    for tabId, tab in pairs(ISChat.instance.tabs) do
        return tabId, tab
    end
end

local function UpdateInfoWindow()
    local info = getText('SurvivalGuide_TICS', TICS_VERSION)
    info = info .. getText('SurvivalGuide_TICS_Markdown')
    if TicsServerSettings['whisper']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Whisper')
    end
    if TicsServerSettings['low']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Low')
    end
    if TicsServerSettings['say']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Say')
    end
    if TicsServerSettings['yell']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Yell')
    end
    if TicsServerSettings['me']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Me')
    end
    if TicsServerSettings['do']['enabled'] and not TicsServerSettings['do']['adminOnly'] then
        info = info .. getText('SurvivalGuide_TICS_Do')
    end
    if TicsServerSettings['pm']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Pm')
    end
    if TicsServerSettings['faction']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Faction')
    end
    if TicsServerSettings['safehouse']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_SafeHouse')
    end
    if TicsServerSettings['general']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_General')
    end
    if TicsServerSettings['admin']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Admin')
    end
    if TicsServerSettings['ooc']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Ooc')
    end
    info = info .. getText('SurvivalGuide_TICS_Color')
    info = info .. getText('SurvivalGuide_TICS_Pitch')
    info = info .. getText('SurvivalGuide_TICS_Roll')
    if TicsServerSettings['options']['languages'] then
        info = info .. getText('SurvivalGuide_TICS_Languages')
    end
    ISChat.instance:setInfo(info)
end

local function HasAtLeastOneChanelEnabled(tabId)
    if TicsServerSettings == nil then
        return false
    end
    for _, stream in pairs(ISChat.allChatStreams) do
        local name = stream['name']
        if stream['tabID'] == tabId and TicsServerSettings[name] and TicsServerSettings[name]['enabled'] then
            return true
        end
    end
    return false
end

local function RemoveTab(tabTitle, tabID)
    local foundTab
    if ISChat.instance.tabs[tabID] ~= nil then
        foundTab = ISChat.instance.tabs[tabID]
        ISChat.instance.tabs[tabID] = nil
    else
        return
    end
    if ISChat.instance.tabCnt > 1 then
        for i, blinkedTab in ipairs(ISChat.instance.panel.blinkTabs) do
            if tabTitle == blinkedTab then
                table.remove(ISChat.instance.panel.blinkTabs, i)
                break
            end
        end
        ISChat.instance.panel:removeView(foundTab)
        ISChat.instance.minimumWidth = ISChat.instance.panel:getWidthOfAllTabs() + 2 * ISChat.instance.inset
    end
    ISChat.instance.tabCnt = ISChat.instance.tabCnt - 1
    local firstTabId, firstTab = GetFirstTab()
    if firstTabId == nil then
        return
    end
    if ISChat.instance.currentTabID == tabID then
        ISChat.instance.currentTabID = firstTabId
        local chat = ISChat.instance
        chat.panel:activateView(chat.tabs[chat.currentTabID].tabTitle)
    end
    if ISChat.instance.tabCnt == 1 then
        local lastTab = firstTab
        ISChat.instance.panel:setVisible(false)
        ISChat.instance.panel:removeView(lastTab)
        ISChat.instance.chatText = lastTab
        ISChat.instance:addChild(ISChat.instance.chatText)
        ISChat.instance.chatText:setVisible(true)
    end
    ISChat.instance:onActivateView()
end

ISChat.onRecvSandboxVars = function(messageTypeSettings)
    if TicsServerSettings == nil then
        Events.OnPostRender.Remove(AskServerData)
    end

    local knownAvatars = AvatarManager:getKnownAvatars()
    ClientSend.sendKnownAvatars(knownAvatars)

    TicsServerSettings = messageTypeSettings -- a global

    if HasAtLeastOneChanelEnabled(2) == true then
        AddTab('Out Of Character', 2)
    elseif ISChat.instance.tabs[2] ~= nil then
        RemoveTab('Out Of Character', 2)
    end
    if HasAtLeastOneChanelEnabled(3) == true then
        AddTab('Private Message', 3)
    elseif ISChat.instance.tabs[3] ~= nil then
        RemoveTab('Private Message', 3)
    end
    if getPlayer():getAccessLevel() == 'Admin' and messageTypeSettings['admin']['enabled'] then
        AddTab('Admin', 4)
    elseif ISChat.instance.tabs[4] ~= nil then
        RemoveTab('Admin', 4)
    end
    -- We use HasAtLeastOneChanelEnabled(5) which checks if *any* stream for tab 5 is enabled.
    if HasAtLeastOneChanelEnabled(5) == true then
        AddTab('Faction OOC', 5) -- Add the new tab if enabled
    elseif ISChat.instance.tabs[5] ~= nil then
        RemoveTab('Faction OOC', 5) -- Remove if not enabled
    end
    if ISChat.instance.tabCnt > 1 and not HasAtLeastOneChanelEnabled(1) then
        RemoveTab('General', 1)
    else
        UpdateTabStreams(ISChat.instance.tabs[1], 1)
    end

    UpdateRangeIndicator(ISChat.defaultTabStream[ISChat.instance.currentTabID])
    UpdateInfoWindow()
    if ISChat.instance.ticsModData == nil or ISChat.instance.ticsModData['isVoiceEnabled'] == nil then
        ISChat.instance.isVoiceEnabled = messageTypeSettings['options']['isVoiceEnabled']
    end
    local radioMaxRange = TicsServerSettings['options']['radio']['soundMaxRange']
    if ISChat.instance.radioRangeIndicator then
        ISChat.instance.radioRangeIndicator:unsubscribe()
    end
    ISChat.instance.radioRangeIndicator = RadioRangeIndicator:new(25, radioMaxRange, ISChat.instance.isRadioIconEnabled)
    if ISChat.instance.radioButtonState == true then
        ISChat.instance.radioRangeIndicator:subscribe()
    end
    ISChat.instance.online = true
end

ISChat.onTabRemoved = function(tabTitle, tabID)
    if tabID ~= 1 then -- Admin tab is 1 in the Java code
        return
    end
    RemoveTab('Admin', 4) -- Admin tab is 4 in our table
end

ISChat.onSetDefaultTab = function(defaultTabTitle)
end

local function GetNextTabId(currentTabId)
    local firstId = nil
    local found = false
    for tabId, _ in pairs(ISChat.instance.tabs) do
        if firstId == nil then
            firstId = tabId
        end
        if currentTabId == tabId then
            found = true
        elseif found == true then
            return tabId
        end
    end
    return firstId
end

ISChat.onToggleChatBox = function(key)
    if ISChat.instance == nil then return end
    if key == getCore():getKey("Toggle chat") or key == getCore():getKey("Alt toggle chat") then
        ISChat.instance:focus()
    end
    local chat = ISChat.instance
    if key == getCore():getKey("Switch chat stream") then
        local nextTabId = GetNextTabId(chat.currentTabID)
        if nextTabId == nil then
            print('TICS error: onToggleChatBox: next tab ID not found')
            return
        end
        chat.currentTabID = nextTabId
        chat.panel:activateView(chat.tabs[chat.currentTabID].tabTitle)
        ISChat.instance:onActivateView()
    end
end

local function GetTabFromOrder(tabIndex)
    local index = 1
    for tabId, tab in pairs(ISChat.instance.tabs) do
        if tabIndex == index then
            return tabId
        end
        index = index + 1
    end
    return nil
end

ISChat.ISTabPanelOnMouseDown = function(target, x, y)
    if target:getMouseY() >= 0 and target:getMouseY() < target.tabHeight then
        if target:getScrollButtonAtX(x) == "left" then
            target:onMouseWheel(-1)
            return true
        end
        if target:getScrollButtonAtX(x) == "right" then
            target:onMouseWheel(1)
            return true
        end
        local tabIndex = target:getTabIndexAtX(target:getMouseX())
        local tabId = GetTabFromOrder(tabIndex)
        if tabId ~= nil then
            ISChat.instance.currentTabID = tabId
        end
        -- if we clicked on a tab, the first time we set up the x,y of the mouse, so next time we can see if the player moved the mouse (moved the tab)
        if tabIndex >= 1 and tabIndex <= #target.viewList and ISTabPanel.xMouse == -1 and ISTabPanel.yMouse == -1 then
            ISTabPanel.xMouse = target:getMouseX()
            ISTabPanel.yMouse = target:getMouseY()
            target.draggingTab = tabIndex - 1
            local clickedTab = target.viewList[target.draggingTab + 1]
            target:activateView(clickedTab.name)
        end
    end
    return false
end

local function OnRangeButtonClick()
    if TicsServerSettings == nil then
        return
    end
    if ISChat.instance.rangeButtonState == 'visible' then
        ISChat.instance.rangeButtonState = 'always-visible'
        ISChat.instance.rangeButton:setImage(getTexture("media/ui/tics/icons/eye-on-plus.png"))
    elseif ISChat.instance.rangeButtonState == 'always-visible' then
        ISChat.instance.rangeButtonState = 'hidden'
        ISChat.instance.rangeButton:setImage(getTexture("media/ui/tics/icons/eye-off.png"))
    else
        ISChat.instance.rangeButtonState = 'visible'
        ISChat.instance.rangeButton:setImage(getTexture("media/ui/tics/icons/eye-on.png"))
    end
    UpdateRangeIndicator(ISChat.lastTabStream[ISChat.instance.currentTabID])
end

local function OnRadioButtonClick()
    if TicsServerSettings == nil or ISChat.instance.radioRangeIndicator == nil then
        return
    end
    ISChat.instance.radioButtonState = not ISChat.instance.radioButtonState
    if ISChat.instance.radioButtonState == true then
        ISChat.instance.radioRangeIndicator:subscribe()
        ISChat.instance.radioButton:setImage(getTexture("media/ui/tics/icons/mic-on.png"))
    else
        ISChat.instance.radioRangeIndicator:unsubscribe()
        ISChat.instance.radioButton:setImage(getTexture("media/ui/tics/icons/mic-off.png"))
    end
end

local function OnAvatarUploadButtonClick()
    if ISChat.instance.avatarUploadWindow then
        ISChat.instance.avatarUploadWindow:unsubscribe()
    end
    ISChat.instance.avatarUploadWindow = AvatarUploadWindow:new()
    ISChat.instance.avatarUploadWindow:subscribe()
end

local function OnAvatarValidationWindowButtonClick()
    if ISChat.instance.avatarValidationWindow then
        ISChat.instance.avatarValidationWindow:unsubscribe()
    end
    ISChat.instance.avatarValidationWindow = AvatarValidationWindow:new()
    ISChat.instance.avatarValidationWindow:subscribe()
end

-- redefining ISTabPanel:activateView to remove the update of the info button
local function PanelActivateView(panel, viewName)
    local self = panel
    for ind, value in ipairs(self.viewList) do
        -- we get the view we want to display
        if value.name == viewName then
            self.activeView.view:setVisible(false)
            value.view:setVisible(true)
            self.activeView = value
            self:ensureVisible(ind)

            if self.onActivateView and self.target then
                self.onActivateView(self.target, self)
            end

            return true
        end
    end
    return false
end

function ISChat:createValidationWindowButton()
    if TicsServerSettings == nil or TicsServerSettings['options']['portrait'] ~= 2 then
        if self.avatarUploadButton then
            self:removeChild(self.avatarUploadButton)
            self.avatarUploadButton = nil
        end
        if self.avatarValidationWindowButton then
            self:removeChild(self.avatarValidationWindowButton)
            self.avatarValidationWindowButton = nil
        end
        return
    end

    local th = self:titleBarHeight()
    if self.avatarUploadButton == nil then
        --avatar upload button
        ISChat.avatarUploadButtonName = "avatar upload"
        self.avatarUploadButton = ISButton:new(self.radioButton:getX() - th / 2 - th, 1, th, th, "", self,
                OnAvatarUploadButtonClick)
        self.avatarUploadButton.anchorRight = true
        self.avatarUploadButton.anchorLeft = false
        self.avatarUploadButton:initialise()
        self.avatarUploadButton.borderColor.a = 0.0
        self.avatarUploadButton.backgroundColor.a = 0
        self.avatarUploadButton.backgroundColorMouseOver.a = 0.5
        self.avatarUploadButton:setImage(getTexture("media/ui/tics/icons/upload.png"))
        self.avatarUploadButton:setUIName(ISChat.avatarUploadButtonName)
        self:addChild(self.avatarUploadButton)
        self.avatarUploadButton:setVisible(true)
    end

    if self.avatarValidationWindowButton == nil then
        local accessLevel = getPlayer():getAccessLevel()
        if accessLevel == 'Admin' or accessLevel == 'Moderator' then
            ISChat.avatarValidationWindowButtonName = 'avatar validation window button'
            self.avatarValidationWindowButton = ISButton:new(self.avatarUploadButton:getX() - th / 2 - th, 1, th, th,
                    '', self, OnAvatarValidationWindowButtonClick)
            self.avatarValidationWindowButton.anchorRight = true
            self.avatarValidationWindowButton.anchorLeft = false
            self.avatarValidationWindowButton:initialise()
            self.avatarValidationWindowButton.borderColor.a = 0.0
            self.avatarValidationWindowButton.backgroundColor.a = 0
            self.avatarValidationWindowButton.backgroundColorMouseOver.a = 0.5
            self.avatarValidationWindowButton:setImage(getTexture('media/ui/tics/icons/portrait.png'))
            self.avatarValidationWindowButton:setUIName(ISChat.avatarValidationWindowButtonName)
            self:addChild(self.avatarValidationWindowButton)
            self.avatarValidationWindowButton:setVisible(true)
        end
    end
end

function ISChat:createChildren()
    --window stuff
    -- Do corner x + y widget
    local rh = self:resizeWidgetHeight()
    local resizeWidget = ISResizeWidget:new(self.width - rh, self.height - rh, rh, rh, self)
    resizeWidget:initialise()
    resizeWidget.onMouseDown = ISChat.onMouseDown
    resizeWidget.onMouseUp = ISChat.onMouseUp
    resizeWidget:setVisible(self.resizable)
    resizeWidget:bringToTop()
    resizeWidget:setUIName(ISChat.xyResizeWidgetName)
    self:addChild(resizeWidget)
    self.resizeWidget = resizeWidget

    -- Do bottom y widget
    local resizeWidget2 = ISResizeWidget:new(0, self.height - rh, self.width - rh, rh, self, true)
    resizeWidget2.anchorLeft = true
    resizeWidget2.anchorRight = true
    resizeWidget2:initialise()
    resizeWidget2.onMouseDown = ISChat.onMouseDown
    resizeWidget2.onMouseUp = ISChat.onMouseUp
    resizeWidget2:setVisible(self.resizable)
    resizeWidget2:setUIName(ISChat.yResizeWidgetName)
    self:addChild(resizeWidget2)
    self.resizeWidget2 = resizeWidget2

    -- close button
    local th = self:titleBarHeight()
    self.closeButton = ISButton:new(3, 0, th, th, "", self, self.close)
    self.closeButton:initialise()
    self.closeButton.borderColor.a = 0.0
    self.closeButton.backgroundColor.a = 0
    self.closeButton.backgroundColorMouseOver.a = 0.5
    self.closeButton:setImage(self.closeButtonTexture)
    self.closeButton:setUIName(ISChat.closeButtonName)
    self:addChild(self.closeButton)

    -- lock button
    self.lockButton = ISButton:new(self.width - 19, 0, th, th, "", self, ISChat.pin)
    self.lockButton.anchorRight = true
    self.lockButton.anchorLeft = false
    self.lockButton:initialise()
    self.lockButton.borderColor.a = 0.0
    self.lockButton.backgroundColor.a = 0
    self.lockButton.backgroundColorMouseOver.a = 0.5
    if self.locked then
        self.lockButton:setImage(self.chatLockedButtonTexture)
    else
        self.lockButton:setImage(self.chatUnLockedButtonTexture)
    end
    self.lockButton:setUIName(ISChat.lockButtonName)
    self:addChild(self.lockButton)
    self.lockButton:setVisible(true)

    --gear button
    self.gearButton = ISButton:new(self.lockButton:getX() - th / 2 - th, 1, th, th, "", self, ISChat.onGearButtonClick)
    self.gearButton.anchorRight = true
    self.gearButton.anchorLeft = false
    self.gearButton:initialise()
    self.gearButton.borderColor.a = 0.0
    self.gearButton.backgroundColor.a = 0
    self.gearButton.backgroundColorMouseOver.a = 0.5
    self.gearButton:setImage(getTexture("media/ui/Panel_Icon_Gear.png"))
    self.gearButton:setUIName(ISChat.gearButtonName)
    self:addChild(self.gearButton)
    self.gearButton:setVisible(true)

    --info button
    ISChat.infoButtonName = "chat info button"
    self.infoButton = ISButton:new(self.gearButton:getX() - th / 2 - th, 1, th, th, "", self, ISCollapsableWindow.onInfo)
    self.infoButton.anchorRight = true
    self.infoButton.anchorLeft = false
    self.infoButton:initialise()
    self.infoButton.borderColor.a = 0.0
    self.infoButton.backgroundColor.a = 0
    self.infoButton.backgroundColorMouseOver.a = 0.5
    self.infoButton:setImage(getTexture("media/ui/Panel_info_button.png"))
    self.infoButton:setUIName(ISChat.infoButtonName)
    self:addChild(self.infoButton)
    self.infoButton:setVisible(true)
    local info = getText('SurvivalGuide_TICS', TICS_VERSION)
    info = info .. getText('SurvivalGuide_TICS_Color')
    self:setInfo(info)


    --range button
    ISChat.rangeButtonName = "chat range button"
    self.rangeButton = ISButton:new(self.infoButton:getX() - th / 2 - th, 1, th, th, "", self, OnRangeButtonClick)
    self.rangeButton.anchorRight = true
    self.rangeButton.anchorLeft = false
    self.rangeButton:initialise()
    self.rangeButton.borderColor.a = 0.0
    self.rangeButton.backgroundColor.a = 0
    self.rangeButton.backgroundColorMouseOver.a = 0.5
    self.rangeButton:setImage(getTexture("media/ui/tics/icons/eye-off.png"))
    self.rangeButton:setUIName(ISChat.rangeButtonName)
    self:addChild(self.rangeButton)
    self.rangeButton:setVisible(true)

    --radio button
    ISChat.radioButtonName = "radio button"
    self.radioButton = ISButton:new(self.rangeButton:getX() - th / 2 - th, 1, th, th, "", self, OnRadioButtonClick)
    self.radioButton.anchorRight = true
    self.radioButton.anchorLeft = false
    self.radioButton:initialise()
    self.radioButton.borderColor.a = 0.0
    self.radioButton.backgroundColor.a = 0
    self.radioButton.backgroundColorMouseOver.a = 0.5
    self.radioButton:setImage(getTexture("media/ui/tics/icons/mic-off.png"))
    self.radioButton:setUIName(ISChat.radioButtonName)
    self:addChild(self.radioButton)
    self.radioButton:setVisible(true)

    --avatar validation window button
    self:createValidationWindowButton()

    --general stuff
    self.minimumHeight = 90
    self.minimumWidth = 200
    self:setResizable(true)
    self:setDrawFrame(true)
    self:addToUIManager()

    self.tabs = {}
    self.tabCnt = 0
    self.btnHeight = 25
    self.currentTabID = 0
    self.inset = 2
    self.fontHgt = getTextManager():getFontFromEnum(UIFont.Medium):getLineHeight()

    --text entry stuff
    local inset, EdgeSize, fontHgt = self.inset, 5, self.fontHgt

    -- EdgeSize must match UITextBox2.EdgeSize
    local height = EdgeSize * 2 + fontHgt
    self.textEntry = ISTextEntryBox:new("", inset, self:getHeight() - 8 - inset - height, self:getWidth() - inset * 2,
            height)
    self.textEntry.font = UIFont.Medium
    self.textEntry:initialise()
    -- self.textEntry:instantiate()
    ChatUI.textEntry.instantiate(self.textEntry)
    self.textEntry.backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 }
    self.textEntry.borderColor = { r = 1, g = 1, b = 1, a = 0.0 }
    self.textEntry:setHasFrame(true)
    self.textEntry:setAnchorTop(false)
    self.textEntry:setAnchorBottom(true)
    self.textEntry:setAnchorRight(true)
    self.textEntry.onCommandEntered = ISChat.onCommandEntered
    self.textEntry.onTextChange = ISChat.onTextChange
    self.textEntry.onPressDown = ISChat.onPressDown
    self.textEntry.onPressUp = ISChat.onPressUp
    self.textEntry.onOtherKey = ISChat.onOtherKey
    self.textEntry.onClick = ISChat.onMouseDown
    self.textEntry:setUIName(ISChat.textEntryName) -- need to be right this. If it will empty or another then focus will lost on click in chat
    self.textEntry:setHasFrame(true)
    self:addChild(self.textEntry)
    self.textEntry.prerender = ChatUI.textEntry.prerender
    ISChat.maxTextEntryOpaque = self.textEntry:getFrameAlpha()

    --tab panel stuff
    local panelHeight = self.textEntry:getY() - self:titleBarHeight() - self.inset
    self.panel = ISTabPanel:new(0, self:titleBarHeight(), self.width - inset, panelHeight)
    self.panel:initialise()
    self.panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.panel.onActivateView = ISChat.onActivateView
    self.panel.target = self
    self.panel:setAnchorTop(true)
    self.panel:setAnchorLeft(true)
    self.panel:setAnchorRight(true)
    self.panel:setAnchorBottom(true)
    self.panel:setEqualTabWidth(false)
    self.panel:setVisible(false)
    self.panel.onRightMouseUp = ISChat.onRightMouseUp
    self.panel.onRightMouseDown = ISChat.onRightMouseDown
    self.panel.onMouseUp = ISChat.onMouseUp
    self.panel.onMouseDown = ISChat.ISTabPanelOnMouseDown
    self.panel:setUIName(ISChat.tabPanelName)
    self:addChild(self.panel)
    self.panel.activateView = PanelActivateView
    self.panel.render = ChatUI.tabPanel.render
    self.panel.prerender = ChatUI.tabPanel.prerender

    self:bringToTop()
    self.textEntry:bringToTop()
    self.minimumWidth = self.panel:getWidthOfAllTabs() + 2 * inset
    self.minimumHeight = self.textEntry:getHeight() + self:titleBarHeight() + 2 * inset + self.panel.tabHeight +
            fontHgt * 4
    self:unfocus()

    self.mutedUsers = {}
end

function ISChat:focus()
    self:setVisible(true)
    ISChat.focused = true
    self.textEntry:setEditable(true)
    self.textEntry:focus()
    self.textEntry:ignoreFirstInput()
    local stream = ISChat.lastTabStream[ISChat.instance.currentTabID]
    UpdateRangeIndicator(stream)
    self.fade:reset()
    self.fade:update() --reset fraction to start value
end

function ISChat:unfocus()
    -- This is the standard Java/Lua call to remove focus from the text entry widget itself.
    -- It tells the UI system that this element is no longer the primary input target.
    self.textEntry:unfocus()

    -- Clear the text box content after sending/unfocusing.
    self.textEntry:setText("")

    -- We are removing setEditable(false). The text box should naturally become
    -- editable again when the player *explicitly* gives it focus (e.g., by pressing 'T').
    -- Making it non-editable here seems to be causing input trapping issues.

    -- Handle internal logic like fading if the chat *was* focused before this call.
    if ISChat.focused then
        self.fade:reset()
    end

    -- Update your mod's internal tracking flag for focus state.
    ISChat.focused = false
end



function ISChat.saveBubbleSetting()
    local ticsModData = ISChat.instance.ticsModData
    -- Ensure ticsModData exists, though it should from InitGlobalModData
    if not ticsModData then
        ticsModData = ModData.getOrCreate("tics")
        ISChat.instance.ticsModData = ticsModData
    end
    ticsModData['showChatBubbles'] = ISChat.instance.showChatBubbles
    ModData.add('tics', ticsModData)
end

local function TICS_GetBodyParts()
    local parts = {}
    for i = 0, BodyPartType.ToIndex(BodyPartType.MAX) - 1 do
        local partType = BodyPartType.FromIndex(i)
        -- Exclude Index and MAX itself if they appear, and potentially others if desired
        if partType ~= BodyPartType.Index and partType ~= BodyPartType.MAX then
            table.insert(parts, BodyPartType.ToString(partType))
        end
    end
    table.sort(parts)
    return parts
end

-- Helper function to get the list of applicable injuries
local function TICS_GetInjuries()
    -- These should match the injuries handled in TICS_ApplySelfInjury
    return {
        "Bite",
        "Bleeding",
        "Bullet", -- Note: Causes deep wound + bleed too
        "Burned",
        "Deep Wound",
        "Fracture",
        "Glass Shards", -- Note: Causes deep wound + bleed too
        "Infected",     -- Note: Applies scratch if no wound exists
        "Laceration",
        "Scratched"
        -- Add more here if your apply function supports them
    }
end

-- Function to apply the selected injury (client-side)
-- Takes args in the format '"BodyPartString" "InjuryString"'
-- ISChat.lua

-- Function to apply the selected injury (client-side)
-- Takes args in the format '"BodyPartString" "InjuryString"'
local function TICS_ApplySelfInjury(args)
    -- Safety check for ISChat functions first
    if not ISChat or not ISChat.sendErrorToCurrentTab or not ISChat.sendInfoToCurrentTab then
        print("TICS CRITICAL ERROR: ISChat or its feedback functions are nil in TICS_ApplySelfInjury context!")
        return
    end

    if not args then
        ISChat.sendErrorToCurrentTab("Internal error: No arguments provided for injury.")
        return
    end

    -- Parse arguments like '"Hand_L" "Bleeding"'
    local bodyPartStr, injuryStr = args:match('^"([^"]+)"%s*"([^"]+)"$')

    if not bodyPartStr or not injuryStr then
        ISChat.sendErrorToCurrentTab("Internal error: Invalid argument format for injury: " .. tostring(args))
        return
    end

    local player = getPlayer()
    if not player then
        print("TICS Error: TICS_ApplySelfInjury - Could not get player object.")
        return
    end

    local bodyPartType = BodyPartType.FromString(bodyPartStr)
    if not bodyPartType then
        ISChat.sendErrorToCurrentTab("Invalid body part specified: " .. bodyPartStr)
        return
    end

    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then
        print("TICS Error: TICS_ApplySelfInjury - Could not get body damage object.")
        return
    end

    local bodyPart = bodyDamage:getBodyPart(bodyPartType)
    if not bodyPart then
        ISChat.sendErrorToCurrentTab("Could not get body part object for: " .. bodyPartStr)
        return
    end

    -- Use a simpler display name for feedback, avoiding the potentially problematic API call initially
    local bodyPartDisplayName = string.gsub(bodyPartStr, "_", " ") -- e.g., "Hand L"

    local injuryApplied = false
    local feedbackMsg = injuryStr .. " applied to " .. bodyPartDisplayName .. "!" -- Default message

    -- Apply the injury based on the injury string
    if injuryStr == "Bleeding" then
        bodyPart:setBleedingTime(10)
        bodyPart:setBandaged(false, 0)
        bodyPart:setStitched(false)
        bodyPart:setCleanTime(0)
        injuryApplied = true
    elseif injuryStr == "Bullet" then
        bodyPart:setHaveBullet(true, 0)
        bodyPart:generateDeepWound()
        bodyPart:setBleedingTime(15)
        bodyPart:setBandaged(false, 0)
        bodyPart:setStitched(false)
        bodyPart:setCleanTime(0)
        feedbackMsg = "Bullet lodged in and bleeding from " .. bodyPartDisplayName .. "!"
        injuryApplied = true
    elseif injuryStr == "Burned" then
        bodyPart:setBurnTime(50)
        bodyPart:setBandaged(false, 0)
        bodyPart:setStitched(false)
        bodyPart:setCleanTime(0)
        injuryApplied = true
    elseif injuryStr == "Deep Wound" then
        bodyPart:generateDeepWound()
        bodyPart:setBleedingTime(15)
        bodyPart:setBandaged(false, 0)
        bodyPart:setStitched(false)
        bodyPart:setCleanTime(0)
        injuryApplied = true
    elseif injuryStr == "Fracture" then
        if bodyPart:isCanHaveFracture() then
            bodyPart:setFractureTime(21)
            bodyPart:setSplint(false, 0)
            bodyPart:setAdditionalPain(bodyPart:getAdditionalPain() + 50)
            injuryApplied = true
        else
            feedbackMsg = bodyPartDisplayName .. " cannot be fractured."
            injuryApplied = false
        end
    elseif injuryStr == "Glass Shards" then
        bodyPart:generateDeepShardWound()
        bodyPart:setBleedingTime(10)
        bodyPart:setBandaged(false, 0)
        bodyPart:setStitched(false)
        bodyPart:setCleanTime(0)
        feedbackMsg = "Glass shards lodged in " .. bodyPartDisplayName .. "!"
        injuryApplied = true
    elseif injuryStr == "Infected" then
        if not bodyPart:HasInjury() then
            bodyPart:setScratched(true, true)
            bodyPart:setBleedingTime(2)
            bodyPart:setBandaged(false, 0)
            bodyPart:setStitched(false)
            feedbackMsg = "Scratch applied and infected on " .. bodyPartDisplayName .. "!"
        else
            feedbackMsg = bodyPartDisplayName .. " wound infected!"
        end
        bodyPart:setWoundInfectionLevel(10)
        bodyPart:setCleanTime(0)
        injuryApplied = true
    elseif injuryStr == "Scratched" then
        bodyPart:setScratched(true, true)
        bodyPart:setBleedingTime(5)
        bodyPart:setBandaged(false, 0)
        bodyPart:setStitched(false)
        bodyPart:setCleanTime(0)
        injuryApplied = true
    elseif injuryStr == "Laceration" then
        bodyPart:setCut(true)
        bodyPart:setBleedingTime(10)
        bodyPart:setBandaged(false, 0)
        bodyPart:setStitched(false)
        bodyPart:setCleanTime(0)
        injuryApplied = true
    elseif injuryStr == "Bite" then
        bodyPart:SetBitten(true)
        bodyPart:SetInfected(false)
        bodyPart:SetFakeInfected(false)
        bodyPart:setBleedingTime(20)
        bodyPart:setBandaged(false, 0)
        bodyPart:setStitched(false)
        bodyPart:setCleanTime(0)
        injuryApplied = true
    else
        ISChat.sendErrorToCurrentTab("Unknown injury type specified: " .. injuryStr)
        return
    end

    -- Send feedback to chat (with added safety check)
    if injuryApplied then
        if ISChat and ISChat.sendInfoToCurrentTab then
            ISChat.sendInfoToCurrentTab("<RGB:1.0,0.5,0.5>" .. feedbackMsg)  -- reddish success
        else
            print("TICS ERROR: Could not send injury success feedback - ISChat.sendInfoToCurrentTab is nil")
        end

        -- ✦ Safe UI update / health panel refresh
        if bodyDamage.Update then
            bodyDamage:Update()
        end

        if type(getPlayerHealthPanel) == "function" then
            local healthPanel = getPlayerHealthPanel(player:getPlayerNum())
            if healthPanel and healthPanel.update then
                healthPanel:update()
            end
        end

        if type(triggerEvent) == "function" then
            triggerEvent("OnBodyPartUpdated", bodyPart)
        end

    elseif feedbackMsg then  -- Handle “cannot fracture” or other non-applied cases
        if ISChat and ISChat.sendInfoToCurrentTab then
            ISChat.sendInfoToCurrentTab("<RGB:1.0,1.0,0.5>" .. feedbackMsg)  -- yellowish warning/info
        else
            print("TICS ERROR: Could not send injury info feedback - ISChat.sendInfoToCurrentTab is nil")
        end
    end
end

function ISChat:onGearButtonClick()
    local context = ISContextMenu.get(0, self:getAbsoluteX() + self:getWidth() / 2,
            self:getAbsoluteY() + self.gearButton:getY())
    if context == nil then
        print('TICS error: ISChat:onGearButtonClick: gear button context is null')
        return
    end

    local timestampOptionName = getText("UI_chat_context_enable_timestamp")
    if self.showTimestamp then
        timestampOptionName = getText("UI_chat_context_disable_timestamp")
    end
    context:addOption(timestampOptionName, ISChat.instance, ISChat.onToggleTimestampPrefix)

    local tagOptionName = getText("UI_chat_context_enable_tags")
    if self.showTitle then
        tagOptionName = getText("UI_chat_context_disable_tags")
    end
    context:addOption(tagOptionName, ISChat.instance, ISChat.onToggleTagPrefix)

    local fontSizeOption = context:addOption(getText("UI_chat_context_font_submenu_name"), ISChat.instance)
    local fontSubMenu = context:getNew(context)
    context:addSubMenu(fontSizeOption, fontSubMenu)
    fontSubMenu:addOption(getText("UI_chat_context_font_small"), ISChat.instance, ISChat.onFontSizeChange, "small")
    fontSubMenu:addOption(getText("UI_chat_context_font_medium"), ISChat.instance, ISChat.onFontSizeChange, "medium")
    fontSubMenu:addOption(getText("UI_chat_context_font_large"), ISChat.instance, ISChat.onFontSizeChange, "large")
    if self.chatFont == "small" then
        fontSubMenu:setOptionChecked(fontSubMenu.options[1], true)
    elseif self.chatFont == "medium" then
        fontSubMenu:setOptionChecked(fontSubMenu.options[2], true)
    elseif self.chatFont == "large" then
        fontSubMenu:setOptionChecked(fontSubMenu.options[3], true)
    end

    local minOpaqueOption = context:addOption(getText("UI_chat_context_opaque_min"), ISChat.instance)
    local minOpaqueSubMenu = context:getNew(context)
    context:addSubMenu(minOpaqueOption, minOpaqueSubMenu)
    local opaques = { 0, 0.25, 0.5, 0.6, 0.75, 1 }
    for i = 1, #opaques do
        if logTo01(opaques[i]) <= self.maxOpaque then
            local option = minOpaqueSubMenu:addOption((opaques[i] * 100) .. "%", ISChat.instance,
                    ISChat.onMinOpaqueChange, opaques[i])
            local current = math.floor(self.minOpaque * 1000)
            local value = math.floor(logTo01(opaques[i]) * 1000)
            if current == value then
                minOpaqueSubMenu:setOptionChecked(option, true)
            end
        end
    end

    local maxOpaqueOption = context:addOption(getText("UI_chat_context_opaque_max"), ISChat.instance)
    local maxOpaqueSubMenu = context:getNew(context)
    context:addSubMenu(maxOpaqueOption, maxOpaqueSubMenu)
    for i = 1, #opaques do
        if logTo01(opaques[i]) >= self.minOpaque then
            local option = maxOpaqueSubMenu:addOption((opaques[i] * 100) .. "%", ISChat.instance,
                    ISChat.onMaxOpaqueChange, opaques[i])
            local current = math.floor(self.maxOpaque * 1000)
            local value = math.floor(logTo01(opaques[i]) * 1000)
            if current == value then
                maxOpaqueSubMenu:setOptionChecked(option, true)
            end
        end
    end

    local fadeTimeOption = context:addOption(getText("UI_chat_context_opaque_fade_time_submenu_name"), ISChat.instance)
    local fadeTimeSubMenu = context:getNew(context)
    context:addSubMenu(fadeTimeOption, fadeTimeSubMenu)
    local availFadeTime = { 0, 1, 2, 3, 5, 10 }
    local option = fadeTimeSubMenu:addOption(getText("UI_chat_context_disable"), ISChat.instance, ISChat
            .onFadeTimeChange, 0)
    if 0 == self.fadeTime then
        fadeTimeSubMenu:setOptionChecked(option, true)
    end
    for i = 2, #availFadeTime do
        local time = availFadeTime[i]
        option = fadeTimeSubMenu:addOption(time .. " s", ISChat.instance, ISChat.onFadeTimeChange, time)
        if time == self.fadeTime then
            fadeTimeSubMenu:setOptionChecked(option, true)
        end
    end

    local opaqueOnFocusOption = context:addOption(getText("UI_chat_context_opaque_on_focus"), ISChat.instance)
    local opaqueOnFocusSubMenu = context:getNew(context)
    context:addSubMenu(opaqueOnFocusOption, opaqueOnFocusSubMenu)
    opaqueOnFocusSubMenu:addOption(getText("UI_chat_context_disable"), ISChat.instance, ISChat.onFocusOpaqueChange, false)
    opaqueOnFocusSubMenu:addOption(getText("UI_chat_context_enable"), ISChat.instance, ISChat.onFocusOpaqueChange, true)
    opaqueOnFocusSubMenu:setOptionChecked(opaqueOnFocusSubMenu.options[self.opaqueOnFocus and 2 or 1], true)

    local voiceOptionName = getText("UI_TICS_chat_enable_voices")
    if self.isVoiceEnabled then
        voiceOptionName = getText("UI_TICS_chat_disable_voices")
    end
    context:addOption(voiceOptionName, ISChat.instance, ISChat.onToggleVoice)

    local radioIconOptionName = getText("UI_TICS_enable_radio_icon")
    if self.isRadioIconEnabled then
        radioIconOptionName = getText("UI_TICS_disable_radio_icon")
    end
    context:addOption(radioIconOptionName, ISChat.instance, ISChat.onToggleRadioIcon)

    if TicsServerSettings and TicsServerSettings['options']['portrait'] ~= 1 then
        local portraitOptionName = getText("UI_TICS_enable_portrait")
        if self.isPortraitEnabled then
            portraitOptionName = getText("UI_TICS_disable_portrait")
        end
        context:addOption(portraitOptionName, ISChat.instance, ISChat.onTogglePortrait)
    end

    -- cleaning character

    context:addOption(getText("UI_TICS_clean_character"), ISChat.instance, function()
        PandemUtilities.cleanCharacter()
        ISChat.sendInfoToCurrentTab("Your character has been cleaned!")
    end)

    -- defining hair menu options for growing hair

    local hairOption = context:addOption("Hair Options", nil)
    local hairSubMenu = context:getNew(context)
    context:addSubMenu(hairOption, hairSubMenu)

    -- adding grow hair long
    hairSubMenu:addOption("Grow Long Hair", nil, function()
        local playerObj = getPlayer()

        -- Use Buffy’s logic: “Long2” if female, “Fabian” if male
        if playerObj:isFemale() then
            ISCharacterScreen.onCutHair(playerObj, "Long2", 10)
        else
            ISCharacterScreen.onCutHair(playerObj, "Fabian", 10)
        end

        -- Force a refresh so we see the new hair
        sendVisual(playerObj)
        triggerEvent("OnClothingUpdated", playerObj)
        playerObj:resetModel()
    end)

    -- adding grow beard
    hairSubMenu:addOption("Grow Beard", nil, function()
        local playerObj = getPlayer()

        -- Check if we have a razor
        local hasRazor = playerObj:getInventory():contains("Base.Razor")
        if not hasRazor then
            playerObj:Say("You need a razor to style your beard!")
            return
        end

        -- Trim/grow beard to “Long”
        ISCharacterScreen.onTrimBeard(playerObj, "Long")

        -- Refresh visuals
        sendVisual(playerObj)
        triggerEvent("OnClothingUpdated", playerObj)
        playerObj:resetModel()
    end)

    local injureOption = context:addOption("Add Injury", nil, nil)
    local injureContext = context:getNew(context)
    context:addSubMenu(injureOption, injureContext)

    -- Loop through body parts provided by our helper function
    for _, bodyPartStr in ipairs(TICS_GetBodyParts()) do
        local bodyPartType = BodyPartType.FromString(bodyPartStr)
        if bodyPartType then -- Check conversion ok
            local displayName = BodyPartType.getDisplayName(bodyPartType)
            -- Create option for this body part (e.g., "Left Hand")
            local bodyPartOption = injureContext:addOption(displayName, nil, nil)
            local bodyPartContext = injureContext:getNew(injureContext)
            injureContext:addSubMenu(bodyPartOption, bodyPartContext)

            -- Loop through injuries provided by our helper function
            for _, injuryStr in ipairs(TICS_GetInjuries()) do
                -- Format arguments for the TICS_ApplySelfInjury function
                local args = '"' .. bodyPartStr .. '" "' .. injuryStr .. '"'
                -- Add the injury option (e.g., "Bleeding") which calls our function
                bodyPartContext:addOption(injuryStr, args, TICS_ApplySelfInjury)
            end
        else
            print("TICS Warning: Could not get BodyPartType for string: " .. bodyPartStr .. " in context menu.")
        end
    end

    local label = getText("UI_TICS_enable_chat_bubbles")
    if self.showChatBubbles then
        label = getText("UI_TICS_disable_chat_bubbles")
    end
    context:addOption(label, self, ISChat.onToggleBubbles)

    local hairColorOption = context:addOption("Set Hair Color (RGB)", nil)
    local hairColorSubMenu = context:getNew(context)
    context:addSubMenu(hairColorOption, hairColorSubMenu)

    hairColorSubMenu:addOption("Choose Hair Color", self, function()
        -- Prompt the user with a text box
        local modal = ISTextBox:new(
                0, 0, 520, 180,
                "Enter a hair color in R,G,B format (e.g. 128,128,255):",
                "",
                nil,
                function(_, button)
                    if button.internal == "OK" then
                        local input = button.parent.entry:getText() or ""
                        ISChat.applyRGBHairColor(input)
                    elseif button.internal == "CANCEL" then
                        return
                    end
                end,
                false  -- Make sure this is false if you want OK/Cancel
        )
        modal:initialise()
        modal:addToUIManager()
    end)
end


function ISChat.onToggleBubbles()
    -- Flip the boolean state
    ISChat.instance.showChatBubbles = not ISChat.instance.showChatBubbles
    -- Save the new setting
    ISChat.saveBubbleSetting()
    -- Optional: Provide feedback to the user
    local status = ISChat.instance.showChatBubbles and "enabled" or "disabled"
    ISChat.sendInfoToCurrentTab("Chat bubbles " .. status .. ".")
end



function ISChat.onToggleVoice()
    ISChat.instance.isVoiceEnabled = not ISChat.instance.isVoiceEnabled

    -- the player has set this option at least once, that means he is aware of its existence
    -- we'll use this settings in the future instead of the server default behavior
    ISChat.instance.ticsModData['isVoiceEnabled'] = ISChat.instance.isVoiceEnabled
    ModData.add('tics', ISChat.instance.ticsModData)
end

function ISChat.onToggleRadioIcon()
    ISChat.instance.isRadioIconEnabled = not ISChat.instance.isRadioIconEnabled
    ISChat.instance.ticsModData['isRadioIconEnabled'] = ISChat.instance.isRadioIconEnabled
    ModData.add('tics', ISChat.instance.ticsModData)
    if ISChat.instance.radioRangeIndicator then
        ISChat.instance.radioRangeIndicator.showIcon = ISChat.instance.isRadioIconEnabled
    end
end

function ISChat.onTogglePortrait()
    ISChat.instance.isPortraitEnabled = not ISChat.instance.isPortraitEnabled
    ISChat.instance.ticsModData['isPortraitEnabled'] = ISChat.instance.isRadioIconEnabled
    ModData.add('tics', ISChat.instance.ticsModData)
end

Events.OnChatWindowInit.Add(ISChat.initChat)