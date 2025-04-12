require 'ISUI/ISPanel' -- Ensure base UI elements are loaded

local TICS_BioHover = {}

-- --- Configuration (Adapt defaults from WRC or set your own) ---
TICS_BioHover.HoverDistanceThreshold = 20 -- Pixel distance on screen to trigger hover
TICS_BioHover.MaxDisplayDistance = 20     -- Max world distance to check players
TICS_BioHover.TooltipXOffset = 10
TICS_BioHover.TooltipYOffset = -30        -- Offset from player's screen Y (negative = above)
TICS_BioHover.TooltipFont = UIFont.Small  -- Font for the bio text
TICS_BioHover.TooltipTextColor = {r=0.9, g=0.9, b=0.9, a=1.0} -- Text color
TICS_BioHover.TooltipBgColor = {r=0, g=0, b=0, a=0.6}       -- Background color
TICS_BioHover.TooltipPadding = 5          -- Padding inside the background box
TICS_BioHover.TooltipMaxWidth = 200       -- Max width before text wraps

-- --- Helper Functions (Adapted/Simplified from WRC_Utils or common patterns) ---

-- Basic distance calculation
local function getDistance(x1, y1, x2, y2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

-- Get player screen coordinates (Needs careful adaptation/testing - this is a simplified placeholder)
-- WRC's version might be more complex, handling zoom, isometric view, etc.
-- You might need to find and copy WRC's specific 'getPlayerScreenProperX/Y' if this isn't accurate enough.
local function getPlayerScreenPos(player)
    if not player then return nil, nil end
    local x = IsoUtils.XToScreen(player:getX(), player:getY(), player:getZ(), 0)
    local y = IsoUtils.YToScreen(player:getX(), player:getY(), player:getZ(), 0)

    -- Adjust for player model height and centering (approximate)
    local sprite = player:getSprite()
    local scale =_player:getRenderZoom() / 1.0 -- Base scale seems to be around 1.0 for default zoom
    if sprite and scale then
        --local spriteHeight = sprite:getFrameHeight()
        --y = y - (spriteHeight * 0.75 * scale) -- Adjust based on model height/offset (Trial and error)
        y = y - (64 * scale) -- Approximate adjustment assuming ~64px height offset
    end

    local plyr = getPlayer() -- Current player (for camera offset)
    x = x - IsoUtils.XToScreen(plyr:getX(), plyr:getY(), plyr:getZ(), 0) + getCore():getScreenWidth() / 2
    y = y - IsoUtils.YToScreen(plyr:getX(), plyr:getY(), plyr:getZ(), 0) + getCore():getScreenHeight() / 2

    return x, y
end


-- Split text into lines based on max width (Simplified version)
local function wrapText(text, maxWidth, font)
    local lines = {}
    local currentLine = ""
    local spaceWidth = getTextManager():MeasureStringX(font, " ")

    for word in string.gmatch(text, "[^%s]+") do
        local wordWidth = getTextManager():MeasureStringX(font, word)
        local testLine = currentLine == "" and word or (currentLine .. " " .. word)
        local lineWidth = getTextManager():MeasureStringX(font, testLine)

        if lineWidth <= maxWidth then
            currentLine = testLine
        else
            if currentLine ~= "" then table.insert(lines, currentLine) end
            currentLine = word
            -- Handle case where a single word is too long
            if wordWidth > maxWidth then
                -- TODO: Implement character-level splitting for very long words (complex)
                -- For now, just add the oversized word as its own line
                if currentLine ~= "" then table.insert(lines, currentLine) end
                currentLine = "" -- Reset after adding the long word
            end
        end
    end
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end
    return lines
end

-- Draw the tooltip box
local function drawTooltipBox(x, y, lines, font)
    if not lines or #lines == 0 then return end

    local textManager = getTextManager()
    local lineHeight = textManager:getLineHeight(font)
    local boxHeight = (#lines * lineHeight) + (TICS_BioHover.TooltipPadding * 2)
    local boxWidth = 0

    -- Find max width of the lines for box calculation
    for _, line in ipairs(lines) do
        local w = textManager:MeasureStringX(font, line)
        if w > boxWidth then boxWidth = w end
    end
    boxWidth = boxWidth + (TICS_BioHover.TooltipPadding * 2)
    boxWidth = math.min(boxWidth, TICS_BioHover.TooltipMaxWidth + (TICS_BioHover.TooltipPadding*2)) -- Apply max width constraint to box too

    -- Calculate top-left corner based on center-ish position and offset
    local boxX = x - (boxWidth / 2) + TICS_BioHover.TooltipXOffset
    local boxY = y - boxHeight + TICS_BioHover.TooltipYOffset -- Draw above the offset point

    -- Draw background
    local bg = TICS_BioHover.TooltipBgColor
    DrawTextureScaledCol(nil, boxX, boxY, boxWidth, boxHeight, bg.a, bg.r, bg.g, bg.b)

    -- Draw text lines
    local textCol = TICS_BioHover.TooltipTextColor
    for i, line in ipairs(lines) do
        textManager:DrawString(font,
                boxX + TICS_BioHover.TooltipPadding,
                boxY + TICS_BioHover.TooltipPadding + ((i - 1) * lineHeight),
                line, textCol.r, textCol.g, textCol.b, textCol.a)
    end
end

-- --- Main Render Function ---
function TICS_BioHover.Render()
    -- Basic checks: Is game running? Is UI visible? Is hover enabled via Sandbox?
    if not getPlayer() or not isClient() or getGameTime():isPaused() then return end
    -- TODO: Add Sandbox Var check: if SandboxVars.TICS and SandboxVars.TICS.BioHoverEnabled == false then return end

    local mx = getMouseX()
    local my = getMouseY()
    local selfPlayer = getPlayer()
    local selfPlayerIndex = selfPlayer:getPlayerNum()

    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        local player = players:get(i)

        -- Skip self, dead players, or invisible admins (optional)
        if player and player:isAlive() and player:isVisible() then
            local distToPlayer = getDistance(selfPlayer:getX(), selfPlayer:getY(), player:getX(), player:getY())

            -- Check if player is within world distance limit
            if distToPlayer <= TICS_BioHover.MaxDisplayDistance then
                -- Get player screen position
                local sx, sy = getPlayerScreenPos(player)

                if sx and sy then
                    -- Check distance between mouse and player screen pos
                    local distMouseToPlayer = getDistance(mx, my, sx, sy)

                    if distMouseToPlayer < TICS_BioHover.HoverDistanceThreshold then
                        -- Player is hovered! Get the bio from ModData.
                        local bio = player:getModData().ticsBio

                        if bio and bio ~= "" then
                            -- Wrap the text and draw the tooltip
                            local lines = wrapText(bio, TICS_BioHover.TooltipMaxWidth, TICS_BioHover.TooltipFont)
                            drawTooltipBox(sx, sy, lines, TICS_BioHover.TooltipFont)

                            -- Important: Break after drawing one tooltip to avoid overlap
                            return
                        end
                    end
                end
            end
        end
    end
end

return TICS_BioHover