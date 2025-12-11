--***********************************************************
--**                    PANDEMONIUM RP                     **
--**		  Author: ChaosKiller X7/SkyeHigh              **
--**            CODE BY: github.com/buffyuwu		       **
--***********************************************************

--require "ISUI/ISPanel"
--require "BuildingDefs"
--require "Chat/ISChat"

PandemUtilities = {};
PandemUtilities.Version = .07

-- teleporter function
function PandemUtilities.GlobalTeleportUser(args)
    local player = getPlayer()
    player:setX(args[1])
    player:setY(args[2])
    player:setZ(args[3])
    player:setLx(args[1])
    player:setLy(args[2])
    player:setLz(args[3])
end

--admin menu functions
PandemUtilities.adminMenu = function(player, context, worldobjects, test, items, square)
    local square = nil;
    for i,v in ipairs(worldobjects) do
        square = v:getSquare();
        break
    end
    local sq = getSpecificPlayer(player):getCurrentSquare()
    if isAdmin() then
        local menuOption = context:addOption("Pandemonium - PZRP", worldobjects, nil);
        local pandemSubMenu = ISContextMenu:getNew(context);
        context:addSubMenu(menuOption, pandemSubMenu);
        PandemUtilities.doRIPMenu(pandemSubMenu, player);
    end

    for _,obj in ipairs(worldobjects) do --filter for what we find when we right click
        local objname = obj:getName() or ""
        local objtexturename = obj:getTextureName() or ""
        local dx = (obj:getSquare():getX() - getSpecificPlayer(player):getSquare():getX()) or 0
        local dy = (obj:getSquare():getY() - getSpecificPlayer(player):getSquare():getY()) or 0
        local zGood = (math.abs(obj:getSquare():getZ() - getSpecificPlayer(player):getSquare():getZ()) < 2) or 0
        local dist = math.sqrt(dx*dx + dy*dy) or 0

        if instanceof(obj, "IsoThumpable") and obj:isDoor() then
            print("ISOTHUMPABLE")
            obj:getProperties():Set("forceLocked", "true")
            if isAdmin() then
                doorKeyId = doorKeyId or ZombRand(99,1099)
                context:addOption("[Get Door Key]", worldobjects, PandemUtilities.onGetDoorKey, player, door, doorKeyId);
                context:addOption(obj:isLocked() and "[Door Unlock]" or "[Door Lock]", worldobjects, DebugContextMenu.OnDoorLock, obj)
                context:addOption(string.format("[Set Door Key ID (%d)]", obj:getKeyId()), worldobjects, DebugContextMenu.OnSetDoorKeyID, obj)
            end
            if not zGood or dist > 2 then
                return
            else
                context:addOption("Knock", worldobjects, PandemUtilities.knockdoor, player, door);
            end
            return
        elseif instanceof(obj, "IsoDoor") then
            print("ISODOOR")
            obj:getProperties():Set("forceLocked", "true")
            if isAdmin() then
                doorKeyId = doorKeyId or ZombRand(99,1099)
                context:addOption("[Get Door Key]", worldobjects, PandemUtilities.onGetDoorKey, player, door, doorKeyId);
                context:addOption(obj:isLocked() and "[Door Unlock]" or "[Door Lock]", worldobjects, DebugContextMenu.OnDoorLock, obj)
                context:addOption(string.format("[Set Door Key ID (%d)]", obj:getKeyId()), worldobjects, DebugContextMenu.OnSetDoorKeyID, obj)
            end
            if not zGood or dist > 2 then
                return
            else
                context:addOption("Knock", worldobjects, PandemUtilities.knockdoor, player, door);
            end
            return
        elseif instanceof(obj, "IsoWindow") then
            if isAdmin() then
                context:addOption(obj:isLocked() and "[Window Unlock]" or "[Window Lock]", worldobjects, DebugContextMenu.OnWindowLock, obj)
                context:addOption(obj:isPermaLocked() and "[Window Perm Unlock]" or "[Window Perm Lock]", worldobjects, DebugContextMenu.OnWindowPermLock, obj)
            end
            if not zGood or dist > 2 then
                return
            else
                context:addOption("Knock", worldobjects, PandemUtilities.knockdoor, player, door);
            end
        end -- end of if
    end -- end of for
end

--function convertPortalCoord(inputString)
--	local array = {}
--	local pattern = string.format("([^%s]+)", ", ")
--
--	for value in inputString:gmatch(pattern) do
--		table.insert(array, tonumber(value))
--	end
--	return array
--end
--
--PandemUtilities.addBuildMenu = function(context, playerObj, square, player)
--	local buildMenu = context:addOption("[BUILD]", nil, nil);
--	local mainSubMenu = ISContextMenu:getNew(context)
--	context:addSubMenu(buildMenu, mainSubMenu)
--
--
--	local inTeleportersOption = mainSubMenu:addOption("[IN TELEPORTERS]", nil, nil);
--	local inTeleportersMenu = ISContextMenu:getNew(mainSubMenu)
--	mainSubMenu:addSubMenu(inTeleportersOption, inTeleportersMenu)
--
--	local objectLouisvilleNorthIn = inTeleportersMenu:addOption("Louisville North Portal In", worldobjects, ISBuildMenu.LouisvilleNorthIn, player, square);
--
--	local outTeleportersOption = mainSubMenu:addOption("[OUT TELEPORTERS]", nil, nil);
--	local outTeleportersMenu = ISContextMenu:getNew(mainSubMenu)
--	mainSubMenu:addSubMenu(outTeleportersOption, outTeleportersMenu)
--
--	local objectLouisvilleNorthOut = outTeleportersMenu:addOption("Louisville North Portal Out", worldobjects, ISBuildMenu.LouisvilleNorthOut, player, square);
--end

PandemUtilities.onGetDoorKey = function(worldobjects, player, door, doorKeyId)
    local newKey = getSpecificPlayer(player):getInventory():AddItem("Base.Key1");
    newKey:setKeyId(doorKeyId);
    newKey:setName("Key ("..doorKeyId..")")
end

PandemUtilities.doRIPMenu = function(context, playerObj)
    local ripOption = context:addOption("[TOOLS]", nil, nil);
    local ripSubMenu = ISContextMenu:getNew(context)
    context:addSubMenu(ripOption, ripSubMenu)
    ripSubMenu:addOption("Sacrifice Self", playerObj, PandemUtilities.suicide);
    ripSubMenu:addOption("Teleport to Admin Island", playerObj, PandemUtilities.adminisland);
end

PandemUtilities.suicide = function()
    local person = getPlayer():getBodyDamage()
    person:getBodyPart(BodyPartType.Groin):generateDeepShardWound();
    person:getBodyPart(BodyPartType.Neck):generateDeepShardWound();
    person:getBodyPart(BodyPartType.Head):generateDeepShardWound();
    person:getBodyPart(BodyPartType.UpperLeg_R):generateDeepShardWound();
    person:getBodyPart(BodyPartType.UpperLeg_L):generateDeepShardWound();
    --processAdminChatMessage(getOnlineUsername() .. " used the sacrifice tool at X" .. square:getX() .. " Y" .. square:getY())
    print("I open my veins for her.")
end

PandemUtilities.knockdoor = function(playerObj, worldobject, obj, door)
    local range = 10
    getPlayer():getSquare():playSound("Knocking")
    addSound(getPlayer(), getPlayer():getX(),getPlayer():getY(),getPlayer():getZ(), range, 1)
end

local traveldelay = 3000
local threeseconds = 3000;
local fourseconds = 4000;
local musicdelay = 3000;
local timestamp = 0;
local musicvol = getCore():getOptionMusicVolume() or 0

if not PandemUtilities.pandemRemoveEvents then
    function PandemUtilities.pandemRemoveEvents()
        Events.OnTick.Remove(PandemUtilities.muteMusicTimer)
        Events.OnTick.Remove(PandemUtilities.resumeMusicTimer)
    end
end

function PandemUtilities.resumeMusicTimer()
    if musicdelay > 0 then
        local delta = getDeltaTimeInMillis(timestamp)
        timestamp = getTimeInMillis()
        musicdelay = math.max(0, musicdelay - delta)
        if musicdelay <= 0 then
            PandemUtilities.pandemRemoveEvents()
            PandemUtilities.ResumeMusicVol()
            if Events.OnTick.IsAdded(PandemUtilities.resumeMusicTimer) then
                Events.OnTick.Remove(PandemUtilities.resumeMusicTimer)
            end
        end
    end
end

function PandemUtilities.muteMusicTimer(vol, timer)
    if not Events.OnTick.IsAdded(PandemUtilities.resumeMusicTimer) then
        musicdelay = 10000
        Events.OnTick.Add(PandemUtilities.resumeMusicTimer)
    end

    musicvol = vol
    if timer then musicdelay = timer end

    if musicdelay > 0 then
        local delta = getDeltaTimeInMillis(timestamp)
        timestamp = getTimeInMillis()
        musicdelay = math.max(0, musicdelay - delta)

        if musicdelay <= 0 then
            if PandemUtilities.pandemRemoveEvents then
                PandemUtilities.pandemRemoveEvents()
            end
            if PandemUtilities.ZeroMusicVol then
                PandemUtilities.ZeroMusicVol()
            end

            if PandemUtilities.resumeMusicTimer then
                musicdelay = 10000
                Events.OnTick.Add(PandemUtilities.resumeMusicTimer)
            end
        end
    end
end


if not PandemUtilities.ZeroMusicVol then
    function PandemUtilities.ZeroMusicVol()
        getCore():setOptionMusicVolume(0)
    end
end

function PandemUtilities.ResumeMusicVol()
    getCore():setOptionMusicVolume(musicvol)
end

function PandemUtilities.round(num, numDecimalPlaces)
    if not num then return end
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function getDeltaTimeInMillis(ts)
    return getTimeInMillis() - ts;
end

PandemUtilities.checkTailoring = function(player)
    local player = getPlayer()
    local playerX = player:getSquare():getX()

    if player:getPerkLevel(Perks.Tailoring) < 8 then
        while player:getPerkLevel(Perks.Tailoring) ~= 8 do
            player:LevelPerk(Perks.Tailoring);
        end
        player:getXp():setXPToLevel(Perks.Tailoring, 8);
    end
    ---- todo: more accurate math to determine which area of Louisville a player is in
    --if playerX > 11699 and not SandboxVars.POIs.PortalStatus and not isAdmin() then
    --	TPUser(player, {2301,1226,0}, false)
    --	processSayMessage("��� ".."[Pandemonium] You wander your way around Louisville, but the dangers prove to be too much for you. You barely manage to locate the nearest portal, and escape from Louisville just in time.")
    --end
end

function PandemUtilities.adminisland()
    local player = getPlayer()
    player:getEmitter():playSound("Teleport")
    player:setX(10444)
    player:setY(6082)
    player:setZ(0)
    player:setLx(10444)
    player:setLy(6082)
    player:setLz(0)
end

function PandemUtilities.cleanCharacter()
    local playerObj = getPlayer()
    if not playerObj then return end
    for i = 1, BloodBodyPartType.MAX:index() do
        local part = BloodBodyPartType.FromIndex(i - 1)
        playerObj:getHumanVisual():setBlood(part, 0)
        playerObj:getHumanVisual():setDirt(part, 0)
    end
    sendVisual(playerObj)
    triggerEvent("OnClothingUpdated", playerObj)
    playerObj:resetModel()
end

local function playAndRemember(emitter, soundName, clipFn)
    local id
    if clipFn == "clip" then
        id = emitter:playClip(soundName, nil)   -- True-Music uses clips
    else
        id = emitter:playSoundImpl(soundName, nil)
    end
    remember(id, emitter, soundName)            -- <-- the important line
    return id
end

function ISChat.applyRGBHairColor(str)
    -- 1) Split input by commas
    local r,g,b = str:match("^(%d+)%D+(%d+)%D+(%d+)$")
    if not r then
        ISChat.sendInfoToCurrentTab("Invalid RGB color format. Example: 128,128,255")
        return
    end

    -- 2) Convert them from string to numbers (0..255)
    r = tonumber(r)
    g = tonumber(g)
    b = tonumber(b)
    if not r or not g or not b then
        ISChat.sendInfoToCurrentTab("Invalid RGB color format.")
        return
    end

    -- 3) Clamp them (if needed)
    if r > 255 then r = 255 end
    if g > 255 then g = 255 end
    if b > 255 then b = 255 end

    -- 4) Actually set the hair color
    local playerObj = getPlayer()
    local visual = playerObj:getHumanVisual()

    local colorR = r / 255
    local colorG = g / 255
    local colorB = b / 255

    visual:setHairColor(ImmutableColor.new(colorR, colorG, colorB, 1))
    visual:setBeardColor(ImmutableColor.new(colorR, colorG, colorB, 1))

    sendVisual(playerObj)
    triggerEvent("OnClothingUpdated", playerObj)
    playerObj:resetModel()

    ISChat.sendInfoToCurrentTab("Hair color updated to " .. r .. "," .. g .. "," .. b .. " !")
end


function PandemUtilities.automatedTipMessages()
    local player = getPlayer()
    local tips = {"Knox County, a diverse and wide-ranging county... now under lock and key.",
                  "Tune into 90.8 to hear your fellow survivors and the Automated Emergency Broadcast Signal!",
                  "There are quite a few towns in the local area, but be wary, some of them harbor more danger than just regular zombies.",
                  "Not sure if a faction is online? Want to start up a crew to go out exploring? Check out #looking-for-rp in the discord and send out a message!",
                  "Only you can prevent littering! Tin cans from eating and soda cans from drinking can be broken down into metal parts which can become scrap metal. Recycle Cans under Metalworking.",
                  "Casings from your gun have been enhanced to go straight into space. This means about 50% of your casings to eject out onto the ground. Those are great savings!",
                  "Our #ic-map channel in discord shows all common knowledge faction base locations!",
                  "Guns handle a bit differently. Different than traditional Zomboid, try to think of real life tips and techniques to perform better.",
                  "Remember, in these trying times, you can only look out for you and your fellow man.",
                  "Rumors exist that if you're willing to sacrifice the mobility of a car, there exists a sewer system you can use to traverse the county...",
                  "Not sure where to find the dice panel? Trying to look how to roll? Take a look at the website -> Making your Survivor! The website has great information, make sure to review it!",
                  "Have too much unusable metal? Wish you had more nails? Check the crafting recipe, more nails are simply inches away!",
                  "Wish you could invite friends and allies over but they have a safehouse? No worries, you're allowed multiple safehouses! Make sure to own a safehouse before being invited to another!",
                  "Life is fragile. You can only survive 2 Severe Wounds. The third is fatal, be careful out there.",
                  "Not sure on our infection rules? Check out our website -> Dice -> Infection for more information!",
                  "Not all weapons can hit multiple zombies, check out the discord post on multi-hit limits!",
                  "We value feedback! Look in Server Suggestions -> Daily Flash Polls for any active polls that help give insight to shape the server's future!",
                  "Sometimes, events happen and there's audio associated. /stopsound stops this sound! Be careful, it also stops boombox music from playing for everyone...",
                  "Want to not hear the boombox? Head to your settings -> Audio -> Ambient Volume this controls all sorts of sounds!",
                  "The rumors about Mayor McPhebes having a twin brother named Mayor McCarthy is hearsay.",
                  "Want to make connections? Trying to trade? Utilize the #looking-for-rp channel and the pingable roles to get something going!",
                  "Traits can be gained and lost, such as Smoker! It's all thanks to Dynamic Traits-- make sure to experiment and see what you get!",
                  "Our occupations reflect general archetypes. If you're unsure about them, make sure to check the 'Creating your Character' section on the pandemonium website.",
                  "The Infection is spreading and possibly changing everyone here in Knox county. How do you know that you haven't been affected?",
                  "Need help? Make sure to open a ticket in the discord! Want to help? Check announcements, we're always looking for staff to help run things smoothly!",
                  "There are in-game radio stations that play music, broadcasts, and in-universe announcements. They're at 94, 94.2, and 94.4 MHz respectively!",
                  "There are rumors of Zones within Knox that only the Brave or Foolhardy enter. Many aspects and answers of the virus lay within...",
                  "Want to send a message across the county? Need an advertisement for a public event? Seek out one of the two player-owned radio POIs!",
                  "Confused on some chat commands? Not sure what our chat mod does? Check out the guide in #pande-help!"
    }
    if ZombRand(1,20) > 10 then --50/50ish to fire everyhours
        ISChat.sendInfoToCurrentTab("[Tip] "..tips[ZombRand(1,math.max(1,#tips+1))])
    end
end

Events.EveryHours.Add(PandemUtilities.automatedTipMessages)
Events.OnCreatePlayer.Add(PandemUtilities.checkTailoring);

Events.OnFillWorldObjectContextMenu.Add(PandemUtilities.adminMenu);

return PandemUtilities