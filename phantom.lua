--[[════════════════════════════════════════════════
    PHANTOM HUB v11 — WindUI Edition
    Blue Lock Farm–inspired UI + key gate
════════════════════════════════════════════════]]

--═══════════════ CONFIG ═══════════════
local CFG = {
    SUPABASE_URL = "https://jehfieazzkglvkzgkfle.supabase.co",
    SUPABASE_KEY = "sb_publishable_HXKj5KRyIc3oc7CePaEY5w_9zYWXt5P",
    TABLE        = "Keys",

    LOOTLABS_KEY = "d78147882b52d09a32e23ff2af2ad8e882f52921a37d90e43c01c2b67c7a6b54",

    PROVIDERS = {
        {
            id        = "workink",
            name      = "Work.ink",
            logo      = "rbxassetid://100851789389252",
            baseUrl   = "https://work.ink/32gE/phantom",
            keySystem = true,
        },
        {
            id       = "lootlabs",
            name     = "LootLabs",
            logo     = "rbxassetid://102357888982176",
            apiMode  = true,
            only24h  = true,
        },
    },

    ACCENT       = Color3.fromRGB(130, 80, 255),
    LOGO_ASSET   = "rbxassetid://5028857084",
    VERSION      = "v11",
    KEY_FILE     = "phantom_hub_key.txt",
}

--═══════════════ SCRIPT LIBRARY ═══════════════
-- game = "universal" (shows everywhere) or a placeId (shows only in that game)
local SCRIPTS = {
    { name = "Infinite Yield", desc = "Admin command suite", game = "universal",
      url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source" },

    -- Verified on ScriptBlox (published by verified users). "key" = needs its own key.
    { name = "Blox Fruits", desc = "Cash generator - keyless", game = 2753915549,
      url = "https://rawscripts.net/raw/XMAS-Blox-Fruits-Cash-Generator-OPEN-SOURCE-and-KEYLESS-25553" },
    { name = "Pet Simulator 99", desc = "ZapHub - needs key", game = 8737899170,
      url = "https://rawscripts.net/raw/18h-Pet-Simulator-99!-ZapHub-The-BEST-Auto-Farm-and-MORE-10049" },
    { name = "Fisch", desc = "Blackhub - needs key", game = 16732694052,
      url = "https://rawscripts.net/raw/Fisch-Blackhub-Best-Undetected-Script-53591" },
    { name = "Steal a Brainrot", desc = "Undetected - needs key", game = 109983668079237,
      url = "https://rawscripts.net/raw/Steal-a-Brainrot-UNDETECTED-SAB-216841" },
    { name = "99 Nights in the Forest", desc = "Neox Hub - needs key", game = 79546208627805,
      url = "https://rawscripts.net/raw/99-Nights-in-the-Forest-New-Neox-Hub-Script-With-Most-Features-43425" },
    { name = "Brookhaven RP", desc = "Sander XY - needs key", game = 4924922222,
      url = "https://rawscripts.net/raw/Brookhaven-RP-Sander-XY-35845" },
    { name = "Murder Mystery 2", desc = "Free script - needs key", game = 142823291,
      url = "https://rawscripts.net/raw/Murder-Mystery-2-The-best-free-script-lots-of-features-202764" },
    { name = "Adopt Me", desc = "Snowy Hub - needs key", game = 920587237,
      url = "https://rawscripts.net/raw/Adopt-Me!-Snowy-Hub-Auto-Farm-Auto-Hatch-Auto-Age-More-240470" },
    { name = "Bee Swarm Simulator", desc = "Kron Hub - needs key", game = 1537690962,
      url = "https://rawscripts.net/raw/Bee-Swarm-Simulator-Kron-Hub-20936" },
    { name = "Blade Ball", desc = "Project Stark - needs key", game = 13772394625,
      url = "https://rawscripts.net/raw/Blade-Ball-Project-Stark-Free-Hub-59919" },
    { name = "Dress to Impress", desc = "Snowy Hub - needs key", game = 15101393044,
      url = "https://rawscripts.net/raw/Dress-To-Impress-Snowy-Hub-or-Auto-Farm-Troll-Speed-Anti-AFK-Fling-and-More-225635" },

    { name = "Blue Lock Farm", desc = "Ouroboros - auto-farm", game = 132767904294856,
      url = "https://raw.githubusercontent.com/joustingmatch/Ouroboros/main/loader.lua" },
}

--═══════════════ SERVICES ═══════════════
local Players      = game:GetService("Players")
local HttpService  = game:GetService("HttpService")
local MPS          = game:GetService("MarketplaceService")
local GuiService   = game:GetService("GuiService")

local lp = Players.LocalPlayer

--═══════════════ HWID ═══════════════
local HWID
do
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    HWID = (ok and id and id ~= "") and tostring(id) or ("fb-" .. tostring(lp.UserId))
end

--═══════════════ HTTP ═══════════════
local httpReq = (syn and syn.request) or (http and http.request) or http_request or request

local function sbHeaders()
    return {
        ["apikey"]        = CFG.SUPABASE_KEY,
        ["Authorization"] = "Bearer " .. CFG.SUPABASE_KEY,
        ["Content-Type"]  = "application/json",
    }
end

local function parseISO(s)
    if type(s) ~= "string" then return nil end
    local y, mo, d, h, mi, se = s:match("(%d+)-(%d+)-(%d+)[T ](%d+):(%d+):(%d+)")
    if not y then return nil end
    return os.time({
        year = tonumber(y), month = tonumber(mo), day = tonumber(d),
        hour = tonumber(h), min = tonumber(mi), sec = tonumber(se),
    })
end

local function utcNow()
    return os.time(os.date("!*t"))
end

local keyExpiry = nil

local function verifyKey(key)
    if not httpReq then return false end
    key = tostring(key or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if key == "" then return false end

    local url = CFG.SUPABASE_URL .. "/rest/v1/" .. CFG.TABLE
        .. "?key=eq." .. HttpService:UrlEncode(key) .. "&select=*"

    local ok, res = pcall(function()
        return httpReq({ Url = url, Method = "GET", Headers = sbHeaders() })
    end)
    if not ok or not res then return false end
    if res.StatusCode and res.StatusCode >= 400 then return false end

    local okJ, data = pcall(function()
        return HttpService:JSONDecode(res.Body)
    end)
    if not okJ or type(data) ~= "table" or #data == 0 then return false end

    local row = data[1]
    local exp = parseISO(row.expires_at)
    if not exp then return false end
    if exp <= utcNow() then return false end

    if row.hwid == nil or row.hwid == "" then
        local pUrl = CFG.SUPABASE_URL .. "/rest/v1/" .. CFG.TABLE
            .. "?key=eq." .. HttpService:UrlEncode(key)
        local h2 = sbHeaders()
        h2["Prefer"] = "return=minimal"
        pcall(function()
            httpReq({
                Url = pUrl, Method = "PATCH", Headers = h2,
                Body = HttpService:JSONEncode({ hwid = HWID }),
            })
        end)
    elseif row.hwid ~= HWID then
        return false
    end

    keyExpiry = exp
    return true
end

local function openLink(url)
    if not url or url == "" then return false end
    local copied = false
    if setclipboard then
        local ok = pcall(function() setclipboard(url) end)
        if ok then copied = true end
    end
    pcall(function() GuiService:OpenBrowserWindow(url) end)
    return copied
end

local function createPendingToken(durationHours)
    if not httpReq then return nil end
    local ok, res = pcall(function()
        return httpReq({
            Url = CFG.SUPABASE_URL .. "/rest/v1/rpc/create_pending_token",
            Method = "POST",
            Headers = sbHeaders(),
            Body = HttpService:JSONEncode({ duration_hours = durationHours }),
        })
    end)
    if not ok or not res or (res.StatusCode and res.StatusCode >= 400) then return nil end
    local okJ, data = pcall(function()
        return HttpService:JSONDecode(res.Body)
    end)
    if not okJ or type(data) ~= "table" then return nil end
    return data.token
end

local function createLootLabsLink(destinationUrl)
    if not httpReq then return nil end
    local url = "https://creators.lootlabs.gg/api/public/content_locker"
        .. "?api_token=" .. CFG.LOOTLABS_KEY
        .. "&title=Phantom"
        .. "&url=" .. HttpService:UrlEncode(destinationUrl)
        .. "&tier_id=1"
        .. "&number_of_tasks=2"
        .. "&theme=5"
    local ok, res = pcall(function()
        return httpReq({ Url = url, Method = "GET" })
    end)
    if not ok or not res or (res.StatusCode and res.StatusCode >= 400) then return nil end
    local okJ, data = pcall(function()
        return HttpService:JSONDecode(res.Body)
    end)
    if not okJ or type(data) ~= "table" or type(data.message) ~= "table" or not data.message[1] then return nil end
    return data.message[1].loot_url
end

local function createWorkinkOverride(baseUrl, destinationUrl)
    if not httpReq then return nil end
    local url = "https://work.ink/_api/v2/override?destination=" .. HttpService:UrlEncode(destinationUrl)
    local ok, res = pcall(function()
        return httpReq({ Url = url, Method = "GET" })
    end)
    if not ok or not res or (res.StatusCode and res.StatusCode >= 400) then return nil end
    local okJ, data = pcall(function()
        return HttpService:JSONDecode(res.Body)
    end)
    if not okJ or type(data) ~= "table" or not data.sr then return nil end
    return baseUrl .. "?sr=" .. HttpService:UrlEncode(data.sr)
end


local function fmt(n)
    if not n then return "-" end
    if n >= 1e9 then return string.format("%.1fB", n / 1e9) end
    if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
    if n >= 1e3 then
        return (tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
    end
    return tostring(n)
end

--═══════════════ SAVED KEY ═══════════════
local function loadSavedKey()
    if not readfile then return nil end
    local ok, content = pcall(readfile, CFG.KEY_FILE)
    if ok and content and content ~= "" then
        return content:gsub("^%s+", ""):gsub("%s+$", "")
    end
    return nil
end

local function saveKey(key)
    if not writefile then return end
    pcall(writefile, CFG.KEY_FILE, key)
end

--═══════════════ UI HELPERS ═══════════════
local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function makeStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(50, 29, 41)
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function makeSpacer(parent, height, order)
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1, 0, 0, height)
    s.BackgroundTransparency = 1
    s.LayoutOrder = order
    s.Parent = parent
    return s
end

--═══════════════ FULLSCREEN KEY GATE ═══════════════
local function showKeyGate()
    local saved = loadSavedKey()
    if saved and verifyKey(saved) then
        return true
    end

    local guiParent = (typeof(gethui) == "function" and gethui()) or lp:WaitForChild("PlayerGui")
    local existing = guiParent:FindFirstChild("PhantomKeyGate")
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "PhantomKeyGate"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999
    gui.IgnoreGuiInset = true
    gui.Parent = guiParent

    local TweenService = game:GetService("TweenService")
    local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TWEEN_MED  = TweenInfo.new(0.2,  Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TWEEN_SLOW = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

    local function tween(obj, props, info)
        TweenService:Create(obj, info or TWEEN_FAST, props):Play()
    end

    local COL = {
        bg       = Color3.fromRGB(9, 9, 9),
        surface  = Color3.fromRGB(14, 14, 14),
        border   = Color3.fromRGB(41, 45, 48),
        borderHi = Color3.fromRGB(255, 255, 255),
        input    = Color3.fromRGB(13, 15, 19),
        text     = Color3.fromRGB(255, 255, 255),
        textDim  = Color3.fromRGB(161, 164, 165),
        textMute = Color3.fromRGB(90, 93, 95),
        accent   = Color3.fromRGB(255, 255, 255),
        success  = Color3.fromRGB(130, 200, 150),
        error    = Color3.fromRGB(235, 115, 110),
    }

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Parent = gui
    tween(overlay, {BackgroundTransparency = 0.6}, TWEEN_MED)

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 440, 0, 0)
    bg.AutomaticSize = Enum.AutomaticSize.Y
    bg.Position = UDim2.fromScale(0.5, 0.5)
    bg.AnchorPoint = Vector2.new(0.5, 0.5)
    bg.BackgroundColor3 = COL.bg
    bg.BackgroundTransparency = 0
    bg.BorderSizePixel = 0
    bg.Parent = gui
    makeCorner(bg, 16)
    makeStroke(bg, COL.border)

    bg.Position = UDim2.new(0.5, 0, 0.5, 18)
    bg.BackgroundTransparency = 1
    tween(bg, {Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 0}, TWEEN_SLOW)

    local bgPad = Instance.new("UIPadding")
    bgPad.PaddingLeft = UDim.new(0, 30)
    bgPad.PaddingRight = UDim.new(0, 30)
    bgPad.PaddingTop = UDim.new(0, 28)
    bgPad.PaddingBottom = UDim.new(0, 28)
    bgPad.Parent = bg

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 0, 0)
    content.BackgroundTransparency = 1
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.Parent = bg

    local mainLayout = Instance.new("UIListLayout")
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainLayout.Padding = UDim.new(0, 0)
    mainLayout.Parent = content

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(30, 30)
    closeBtn.Position = UDim2.new(1, 18, 0, -16)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.BackgroundColor3 = COL.surface
    closeBtn.BackgroundTransparency = 1
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "\195\151"
    closeBtn.TextColor3 = COL.textMute
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = bg
    makeCorner(closeBtn, 8)

    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, {BackgroundTransparency = 0, TextColor3 = COL.text})
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, {BackgroundTransparency = 1, TextColor3 = COL.textMute})
    end)
    local dismissed = false
    closeBtn.MouseButton1Click:Connect(function()
        dismissed = true
        gui:Destroy()
    end)

    local keyHeading = Instance.new("TextLabel")
    keyHeading.Size = UDim2.new(1, 0, 0, 26)
    keyHeading.BackgroundTransparency = 1
    keyHeading.Text = "Enter your access key"
    keyHeading.TextColor3 = COL.text
    keyHeading.TextSize = 18
    keyHeading.Font = Enum.Font.GothamBold
    keyHeading.TextXAlignment = Enum.TextXAlignment.Left
    keyHeading.LayoutOrder = 1
    keyHeading.Parent = content

    makeSpacer(content, 6, 2)

    local keySub = Instance.new("TextLabel")
    keySub.Size = UDim2.new(1, 0, 0, 16)
    keySub.BackgroundTransparency = 1
    keySub.Text = "Paste your key below to unlock the hub"
    keySub.TextColor3 = COL.textDim
    keySub.TextSize = 12
    keySub.Font = Enum.Font.Gotham
    keySub.TextXAlignment = Enum.TextXAlignment.Left
    keySub.LayoutOrder = 3
    keySub.Parent = content

    makeSpacer(content, 18, 4)

    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, 0, 0, 44)
    inputFrame.BackgroundColor3 = COL.input
    inputFrame.BorderSizePixel = 0
    inputFrame.LayoutOrder = 5
    inputFrame.Parent = content
    makeCorner(inputFrame, 8)
    local inputStroke = makeStroke(inputFrame, COL.border, 1)

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -24, 1, 0)
    textBox.Position = UDim2.new(0, 12, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.PlaceholderText = "XXXXX-XXXXX-XXXXX"
    textBox.PlaceholderColor3 = COL.textMute
    textBox.Text = ""
    textBox.TextColor3 = COL.text
    textBox.TextSize = 14
    textBox.TextXAlignment = Enum.TextXAlignment.Center
    textBox.Font = Enum.Font.GothamMedium
    textBox.ClearTextOnFocus = false
    textBox.Parent = inputFrame

    textBox.Focused:Connect(function()
        tween(inputStroke, {Color = COL.borderHi})
        tween(inputFrame, {BackgroundColor3 = Color3.fromRGB(18, 21, 28)})
    end)
    textBox.FocusLost:Connect(function()
        tween(inputStroke, {Color = COL.border})
        tween(inputFrame, {BackgroundColor3 = COL.input})
    end)

    makeSpacer(content, 10, 6)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 14)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = COL.error
    status.TextSize = 11
    status.Font = Enum.Font.GothamMedium
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.LayoutOrder = 7
    status.Parent = content

    makeSpacer(content, 6, 8)

    local verifyBtn = Instance.new("TextButton")
    verifyBtn.Size = UDim2.new(1, 0, 0, 44)
    verifyBtn.BackgroundColor3 = COL.text
    verifyBtn.BorderSizePixel = 0
    verifyBtn.Text = "Verify Key"
    verifyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    verifyBtn.TextSize = 14
    verifyBtn.Font = Enum.Font.GothamBold
    verifyBtn.AutoButtonColor = false
    verifyBtn.LayoutOrder = 9
    verifyBtn.Parent = content
    makeCorner(verifyBtn, 8)

    local verifyDefault = COL.text
    local verifyHover = Color3.fromRGB(214, 214, 214)
    verifyBtn.MouseEnter:Connect(function()
        tween(verifyBtn, {BackgroundColor3 = verifyHover})
    end)
    verifyBtn.MouseLeave:Connect(function()
        tween(verifyBtn, {BackgroundColor3 = verifyDefault})
    end)

    makeSpacer(content, 6, 10)

    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(1, 0, 0, 14)
    hint.BackgroundTransparency = 1
    hint.Text = "Press Enter to verify"
    hint.TextColor3 = COL.textMute
    hint.TextSize = 10
    hint.Font = Enum.Font.Gotham
    hint.TextXAlignment = Enum.TextXAlignment.Right
    hint.LayoutOrder = 11
    hint.Parent = content

    makeSpacer(content, 28, 12)

    local div2 = Instance.new("Frame")
    div2.Size = UDim2.new(1, 0, 0, 1)
    div2.BackgroundColor3 = COL.border
    div2.BorderSizePixel = 0
    div2.LayoutOrder = 13
    div2.Parent = content

    makeSpacer(content, 24, 14)

    local provHeading = Instance.new("TextLabel")
    provHeading.Size = UDim2.new(1, 0, 0, 18)
    provHeading.BackgroundTransparency = 1
    provHeading.Text = "Need a key? Choose a provider"
    provHeading.TextColor3 = COL.textDim
    provHeading.TextSize = 12
    provHeading.Font = Enum.Font.GothamMedium
    provHeading.TextXAlignment = Enum.TextXAlignment.Left
    provHeading.LayoutOrder = 15
    provHeading.Parent = content

    makeSpacer(content, 14, 16)

    local provList = Instance.new("Frame")
    provList.Size = UDim2.new(1, 0, 0, 0)
    provList.AutomaticSize = Enum.AutomaticSize.Y
    provList.BackgroundTransparency = 1
    provList.LayoutOrder = 17
    provList.Parent = content

    local provListLayout = Instance.new("UIListLayout")
    provListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    provListLayout.Padding = UDim.new(0, 10)
    provListLayout.Parent = provList

    -- Provider button palette: subtle illumination, never color fills
    local BTN_BG       = Color3.fromRGB(10, 10, 10)
    local BTN_BG_HOV   = Color3.fromRGB(22, 22, 25)
    local BTN_LINE     = Color3.fromRGB(40, 40, 40)
    local BTN_LINE_HOV = Color3.fromRGB(80, 80, 80)

    for i, prov in ipairs(CFG.PROVIDERS) do
        local provCard = Instance.new("Frame")
        provCard.Size = UDim2.new(1, 0, 0, 0)
        provCard.AutomaticSize = Enum.AutomaticSize.Y
        provCard.BackgroundColor3 = COL.surface
        provCard.BorderSizePixel = 0
        provCard.LayoutOrder = i
        provCard.Parent = provList
        makeCorner(provCard, 14)
        local cardStroke = makeStroke(provCard, COL.border)

        local cardPad = Instance.new("UIPadding")
        cardPad.PaddingLeft = UDim.new(0, 14)
        cardPad.PaddingRight = UDim.new(0, 14)
        cardPad.PaddingTop = UDim.new(0, 14)
        cardPad.PaddingBottom = UDim.new(0, 14)
        cardPad.Parent = provCard

        local cardLayout = Instance.new("UIListLayout")
        cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
        cardLayout.Padding = UDim.new(0, 10)
        cardLayout.Parent = provCard

        provCard.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                tween(cardStroke, {Color = BTN_LINE_HOV})
                tween(provCard, {BackgroundColor3 = Color3.fromRGB(20, 20, 20)})
            end
        end)
        provCard.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                tween(cardStroke, {Color = COL.border})
                tween(provCard, {BackgroundColor3 = COL.surface})
            end
        end)

        local headerRow = Instance.new("Frame")
        headerRow.Size = UDim2.new(1, 0, 0, 24)
        headerRow.BackgroundTransparency = 1
        headerRow.LayoutOrder = 1
        headerRow.Parent = provCard

        local logoImg = Instance.new("ImageLabel")
        logoImg.Size = UDim2.fromOffset(22, 22)
        logoImg.Position = UDim2.new(0, 0, 0, 1)
        logoImg.BackgroundTransparency = 1
        logoImg.Image = prov.logo
        logoImg.ScaleType = Enum.ScaleType.Fit
        logoImg.Parent = headerRow

        local provName = Instance.new("TextLabel")
        provName.Size = UDim2.new(1, -30, 1, 0)
        provName.Position = UDim2.new(0, 30, 0, 0)
        provName.BackgroundTransparency = 1
        provName.Text = prov.name
        provName.TextColor3 = COL.text
        provName.TextSize = 14
        provName.Font = Enum.Font.GothamBold
        provName.TextXAlignment = Enum.TextXAlignment.Left
        provName.Parent = headerRow

        local btnRow = Instance.new("Frame")
        btnRow.Size = UDim2.new(1, 0, 0, 36)
        btnRow.BackgroundTransparency = 1
        btnRow.LayoutOrder = 2
        btnRow.Parent = provCard

        local function makeProvBtn(label, xPos, width)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(width, 0, 1, 0)
            b.Position = UDim2.new(xPos, 0, 0, 0)
            b.BackgroundColor3 = BTN_BG
            b.BorderSizePixel = 0
            b.Text = label
            b.TextColor3 = COL.textDim
            b.TextSize = 12
            b.Font = Enum.Font.GothamBold
            b.AutoButtonColor = false
            b.Parent = btnRow
            makeCorner(b, 6)
            local s = makeStroke(b, BTN_LINE)
            return b, s
        end

        local btn24, btn24Stroke = makeProvBtn("24h \194\183 1 Step", 0, prov.only24h and 1 or 0.48)

        local busy24 = false
        btn24.MouseEnter:Connect(function()
            if busy24 then return end
            tween(btn24, {BackgroundColor3 = BTN_BG_HOV, TextColor3 = COL.text})
            tween(btn24Stroke, {Color = BTN_LINE_HOV})
        end)
        btn24.MouseLeave:Connect(function()
            if busy24 then return end
            tween(btn24, {BackgroundColor3 = BTN_BG, TextColor3 = COL.textDim})
            tween(btn24Stroke, {Color = BTN_LINE})
        end)

        btn24.MouseButton1Click:Connect(function()
            if busy24 then return end
            busy24 = true
            btn24.Text = "..."
            btn24.BackgroundColor3 = COL.bg
            btn24.TextColor3 = COL.textMute
            status.Text = ""

            task.spawn(function()
                local token = createPendingToken(24)
                if not token then
                    btn24.TextColor3 = COL.error
                    status.TextColor3 = COL.error
                    status.Text = "Failed to create token. Try again."
                    task.wait(2)
                    btn24.Text = "24h \194\183 1 Step"
                    btn24.BackgroundColor3 = BTN_BG
                    btn24.TextColor3 = COL.textDim
                    btn24Stroke.Color = BTN_LINE
                    busy24 = false
                    return
                end

                local redirect = "https://phantom-key-gilt.vercel.app/phantom?token=" .. token .. "&step=2&provider=" .. prov.id
                local url
                if prov.keySystem then
                    url = createWorkinkOverride(prov.baseUrl, redirect)
                elseif prov.apiMode then
                    url = createLootLabsLink(redirect)
                end

                if url then
                    local copied = openLink(url)
                    status.TextColor3 = copied and COL.success or COL.textDim
                    status.Text = copied and "Link copied! Paste in your browser." or "Opening link..."
                    btn24.Text = "Done"
                    btn24.BackgroundColor3 = Color3.fromRGB(16, 20, 17)
                    btn24.TextColor3 = COL.success
                    btn24Stroke.Color = COL.success
                else
                    status.TextColor3 = COL.error
                    status.Text = "Failed to generate link. Try again."
                    task.wait(2)
                    btn24.Text = "24h \194\183 1 Step"
                    btn24.BackgroundColor3 = BTN_BG
                    btn24.TextColor3 = COL.textDim
                    btn24Stroke.Color = BTN_LINE
                end
                busy24 = false
            end)
        end)

        if not prov.only24h then
        local btn48, btn48Stroke = makeProvBtn("48h \194\183 2 Steps", 0.52, 0.48)
        local busy48 = false
        local step1Done = false
        local token48 = nil

        btn48.MouseEnter:Connect(function()
            if busy48 then return end
            tween(btn48, {BackgroundColor3 = BTN_BG_HOV, TextColor3 = COL.text})
            tween(btn48Stroke, {Color = BTN_LINE_HOV})
        end)
        btn48.MouseLeave:Connect(function()
            if busy48 then return end
            if step1Done then
                tween(btn48, {BackgroundColor3 = BTN_BG, TextColor3 = COL.text})
                tween(btn48Stroke, {Color = BTN_LINE_HOV})
            else
                tween(btn48, {BackgroundColor3 = BTN_BG, TextColor3 = COL.textDim})
                tween(btn48Stroke, {Color = BTN_LINE})
            end
        end)

        btn48.MouseButton1Click:Connect(function()
            if busy48 then return end
            busy48 = true
            btn48.Text = "..."
            btn48.BackgroundColor3 = COL.bg
            btn48.TextColor3 = COL.textMute
            status.Text = ""

            task.spawn(function()
                if not token48 then
                    token48 = createPendingToken(48)
                end
                if not token48 then
                    status.TextColor3 = COL.error
                    status.Text = "Failed to create token. Try again."
                    task.wait(2)
                    btn48.Text = step1Done and "Step 2 \226\134\146" or "48h \194\183 2 Steps"
                    btn48.BackgroundColor3 = BTN_BG
                    btn48.TextColor3 = COL.textDim
                    btn48Stroke.Color = BTN_LINE
                    busy48 = false
                    return
                end

                local stepNum = step1Done and 2 or 1
                local redirect = "https://phantom-key-gilt.vercel.app/phantom?token=" .. token48 .. "&step=" .. stepNum .. "&provider=" .. prov.id
                local url
                if prov.keySystem then
                    url = createWorkinkOverride(prov.baseUrl, redirect)
                elseif prov.apiMode then
                    url = createLootLabsLink(redirect)
                end

                if url then
                    local copied = openLink(url)
                    if not step1Done then
                        status.TextColor3 = copied and COL.success or COL.textDim
                        status.Text = copied and "Link copied! Complete Step 1, then click Step 2." or "Complete Step 1, then click Step 2."
                        step1Done = true
                        btn48.Text = "Step 2 \226\134\146"
                        btn48.BackgroundColor3 = BTN_BG
                        btn48.TextColor3 = COL.text
                        btn48Stroke.Color = BTN_LINE_HOV
                    else
                        status.TextColor3 = copied and COL.success or COL.textDim
                        status.Text = copied and "Link copied! Paste in your browser." or "Opening link..."
                        btn48.Text = "Done"
                        btn48.BackgroundColor3 = Color3.fromRGB(16, 20, 17)
                        btn48.TextColor3 = COL.success
                        btn48Stroke.Color = COL.success
                    end
                else
                    status.TextColor3 = COL.error
                    status.Text = "Failed to generate link. Try again."
                    task.wait(2)
                    btn48.Text = step1Done and "Step 2 \226\134\146" or "48h \194\183 2 Steps"
                    btn48.BackgroundColor3 = BTN_BG
                    btn48.TextColor3 = COL.textDim
                    btn48Stroke.Color = BTN_LINE
                end
                busy48 = false
            end)
        end)
        end
    end

    makeSpacer(content, 24, 18)

    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, 0, 0, 14)
    footer.BackgroundTransparency = 1
    footer.Text = "HWID locked · " .. CFG.VERSION
    footer.TextColor3 = COL.textMute
    footer.TextSize = 10
    footer.Font = Enum.Font.Gotham
    footer.LayoutOrder = 19
    footer.Parent = content

    local verified = false
    local processing = false

    local function tryVerify()
        if processing then return end
        local key = textBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if key == "" then
            status.TextColor3 = COL.error
            status.Text = "Please enter a key"
            return
        end

        processing = true
        verifyBtn.Text = "Verifying..."
        verifyDefault = Color3.fromRGB(150, 150, 150)
        verifyBtn.BackgroundColor3 = verifyDefault
        verifyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        status.TextColor3 = COL.textDim
        status.Text = "Checking key..."
        hint.Text = ""

        task.spawn(function()
            local valid = verifyKey(key)
            if valid then
                status.TextColor3 = COL.success
                status.Text = "Key verified"
                verifyBtn.Text = "Loading hub..."
                verifyDefault = COL.success
                verifyBtn.BackgroundColor3 = COL.success
                verifyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                saveKey(key)

                task.wait(1)
                gui:Destroy()
                verified = true
            else
                status.TextColor3 = COL.error
                status.Text = "Invalid or expired key"
                verifyBtn.Text = "Verify Key"
                verifyDefault = COL.text
                verifyBtn.BackgroundColor3 = COL.text
                verifyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                hint.Text = "Press Enter to verify"
                processing = false
            end
        end)
    end

    verifyBtn.MouseButton1Click:Connect(tryVerify)
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then tryVerify() end
    end)

    while not verified and not dismissed do
        task.wait(0.1)
    end
    return verified
end

if not showKeyGate() then return end

--═══════════════ FETCH GAME INFO ═══════════════
local gameInfo = { name = "Unknown", creator = "", playing = nil, visits = nil, maxPlayers = nil }

do
    local ok, info = pcall(function()
        return MPS:GetProductInfo(game.PlaceId)
    end)
    if ok and info then
        gameInfo.name = info.Name or "Unknown"
        gameInfo.creator = (info.Creator and info.Creator.Name) or ""
        if info.MaxPlayers then
            gameInfo.maxPlayers = info.MaxPlayers
        end
    end

    if httpReq then
        local ok2, res = pcall(function()
            return httpReq({
                Url = "https://games.roblox.com/v1/games?universeIds=" .. tostring(game.GameId),
                Method = "GET",
            })
        end)
        if ok2 and res and res.Body then
            local ok3, data = pcall(function()
                return HttpService:JSONDecode(res.Body)
            end)
            if ok3 and data and data.data and data.data[1] then
                gameInfo.playing = data.data[1].playing
                gameInfo.visits = data.data[1].visits
                if data.data[1].creator and data.data[1].creator.name then
                    gameInfo.creator = data.data[1].creator.name
                end
                if data.data[1].maxPlayers then
                    gameInfo.maxPlayers = data.data[1].maxPlayers
                end
            end
        end
    end
end

local serverPlayers = #Players:GetPlayers()

--═══════════════ LOAD WINDUI ═══════════════
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

--═══════════════ WINDOW ═══════════════
local Window = WindUI:CreateWindow({
    Title = "Phantom",
    Icon = "ghost",
    Author = CFG.VERSION .. " · " .. gameInfo.name,
    Folder = "PhantomHub",
    Size = UDim2.fromOffset(620, 480),
    Theme = "Dark",
    Transparent = true,
    Acrylic = true,
    SideBarWidth = 180,
    HideSearchBar = false,
    ToggleKey = Enum.KeyCode.RightShift,
    User = {
        Enabled = true,
        Anonymous = false,
    },
})

--═══════════════ TABS ═══════════════
local tabScripts = Window:Tab({
    Title = "Scripts",
    Icon = "code",
})

local tabAllScripts = Window:Tab({
    Title = "All Scripts",
    Icon = "library",
})

local tabInfo = Window:Tab({
    Title = "Info",
    Icon = "info",
})

local tabSettings = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

--═══════════════ RUN HELPER ═══════════════
local function runScript(s)
    WindUI:Notify({ Title = "Phantom", Content = "Loading " .. s.name .. "...", Duration = 2, Icon = "download" })
    local ok, err = pcall(function()
        local src = game:HttpGet(s.url)
        if type(src) ~= "string" or #src == 0 then error("empty response", 0) end
        local fn, lerr = loadstring(src)
        if not fn then error(lerr or "compile error", 0) end
        return fn()
    end)
    if ok then
        WindUI:Notify({ Title = "Phantom", Content = s.name .. " loaded — closing hub", Duration = 3, Icon = "check" })
        -- script executed: tear down Phantom so only the loaded script's UI remains
        task.wait(0.6)
        pcall(function() Window:Destroy() end)
    else
        WindUI:Notify({ Title = "Phantom", Content = "Failed: " .. tostring(err):sub(1, 70), Duration = 5, Icon = "x" })
    end
end

--═══════════════ SCRIPTS TAB (compatible with this game) ═══════════════
local compatible = {}
for _, s in ipairs(SCRIPTS) do
    if s.game == "universal" or s.game == game.PlaceId then
        table.insert(compatible, s)
    end
end

if #compatible == 0 then
    tabScripts:Paragraph({
        Title = "No compatible scripts",
        Desc = 'Nothing curated for "' .. gameInfo.name .. '" yet.',
        Icon = "file-code",
    })
else
    tabScripts:Paragraph({
        Title = "Compatible with " .. gameInfo.name,
        Desc = #compatible .. (#compatible == 1 and " script available" or " scripts available"),
        Icon = "circle-check",
    })
    for _, s in ipairs(compatible) do
        tabScripts:Button({
            Title = s.name,
            Desc = s.desc .. (s.game == "universal" and "  ·  Universal" or ""),
            Icon = "play",
            Callback = function() runScript(s) end,
        })
    end
end

--═══════════════ ALL SCRIPTS TAB (full library, compatible first) ═══════════════
tabAllScripts:Paragraph({
    Title = "Script Library",
    Desc = #SCRIPTS .. (#SCRIPTS == 1 and " script total" or " scripts total"),
    Icon = "folder-open",
})
local ordered = {}
for _, s in ipairs(SCRIPTS) do
    if s.game == "universal" or s.game == game.PlaceId then table.insert(ordered, s) end
end
for _, s in ipairs(SCRIPTS) do
    if not (s.game == "universal" or s.game == game.PlaceId) then table.insert(ordered, s) end
end
for _, s in ipairs(ordered) do
    local tag
    if s.game == game.PlaceId then tag = "\226\156\147 This game"
    elseif s.game == "universal" then tag = "Universal"
    else tag = "Place " .. tostring(s.game) end
    tabAllScripts:Button({
        Title = s.name,
        Desc = s.desc .. "  \194\183  " .. tag,
        Icon = "play",
        Callback = function() runScript(s) end,
    })
end

--═══════════════ INFO TAB ═══════════════
tabInfo:Paragraph({
    Title = gameInfo.name,
    Desc = (gameInfo.creator ~= "" and ("by " .. gameInfo.creator) or "Unknown creator"),
    Icon = "gamepad-2",
})

tabInfo:Paragraph({
    Title = "Players & Visits",
    Desc = fmt(gameInfo.playing) .. " playing  ·  " .. fmt(gameInfo.visits) .. " total visits",
    Icon = "users",
})

tabInfo:Paragraph({
    Title = "IDs",
    Desc = "Place: " .. tostring(game.PlaceId) .. "  ·  Universe: " .. tostring(game.GameId),
    Icon = "hash",
})

tabInfo:Divider()

tabInfo:Paragraph({
    Title = "Server",
    Desc = serverPlayers .. " / " .. (gameInfo.maxPlayers or "?") .. " players  ·  Job: " .. tostring(game.JobId):sub(1, 20) .. "...",
    Icon = "server",
})

tabInfo:Divider()

tabInfo:Button({
    Title = "Copy Place ID",
    Desc = "Copy the current Place ID",
    Icon = "copy",
    Callback = function()
        if setclipboard then
            pcall(function() setclipboard(tostring(game.PlaceId)) end)
            WindUI:Notify({ Title = "Phantom", Content = "Place ID copied", Duration = 3, Icon = "check" })
        end
    end,
})

tabInfo:Button({
    Title = "Copy Universe ID",
    Desc = "Copy the current Universe/Game ID",
    Icon = "copy",
    Callback = function()
        if setclipboard then
            pcall(function() setclipboard(tostring(game.GameId)) end)
            WindUI:Notify({ Title = "Phantom", Content = "Universe ID copied", Duration = 3, Icon = "check" })
        end
    end,
})

tabInfo:Button({
    Title = "Copy Join Link",
    Desc = "Copy a link to join this exact server",
    Icon = "link",
    Callback = function()
        local link = "roblox://placeId=" .. tostring(game.PlaceId) .. "&gameInstanceId=" .. tostring(game.JobId)
        if setclipboard then
            pcall(function() setclipboard(link) end)
            WindUI:Notify({ Title = "Phantom", Content = "Join link copied", Duration = 3, Icon = "check" })
        end
    end,
})

tabInfo:Divider()

tabInfo:Paragraph({
    Title = lp.DisplayName .. " (@" .. lp.Name .. ")",
    Desc = "User ID: " .. tostring(lp.UserId),
    Icon = "user",
})

--═══════════════ SETTINGS TAB ═══════════════
tabSettings:Paragraph({
    Title = "Phantom " .. CFG.VERSION,
    Desc = "Script hub with key system powered by Supabase.",
    Icon = "ghost",
})

if keyExpiry then
    local remaining = keyExpiry - utcNow()
    local hrs = math.max(0, math.floor(remaining / 3600))
    local mins = math.max(0, math.floor((remaining % 3600) / 60))
    tabSettings:Paragraph({
        Title = "Key Active",
        Desc = hrs .. "h " .. mins .. "m remaining",
        Icon = "key",
    })
else
    tabSettings:Paragraph({
        Title = "Key Status",
        Desc = "Active",
        Icon = "key",
    })
end

tabSettings:Paragraph({
    Title = "HWID",
    Desc = (#HWID > 28 and (HWID:sub(1, 28) .. "...") or HWID),
    Icon = "fingerprint",
})

tabSettings:Divider()

tabSettings:Button({
    Title = "Copy HWID",
    Desc = "Copy your hardware ID",
    Icon = "clipboard",
    Callback = function()
        if setclipboard then
            pcall(function() setclipboard(HWID) end)
            WindUI:Notify({ Title = "Phantom", Content = "HWID copied", Duration = 3, Icon = "check" })
        end
    end,
})

tabSettings:Button({
    Title = "Rejoin Server",
    Desc = "Rejoin this same server instance",
    Icon = "rotate-ccw",
    Callback = function()
        WindUI:Popup({
            Title = "Rejoin",
            Icon = "rotate-ccw",
            Content = "Are you sure you want to rejoin this server?",
            Buttons = {
                {
                    Title = "Cancel",
                    Variant = "Tertiary",
                    Callback = function() end,
                },
                {
                    Title = "Confirm",
                    Icon = "check",
                    Variant = "Primary",
                    Callback = function()
                        pcall(function()
                            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
                        end)
                    end,
                },
            },
        })
    end,
})

tabSettings:Button({
    Title = "Server Hop",
    Desc = "Teleport to a different server",
    Icon = "shuffle",
    Callback = function()
        WindUI:Popup({
            Title = "Server Hop",
            Icon = "shuffle",
            Content = "Teleport to a different server?",
            Buttons = {
                {
                    Title = "Cancel",
                    Variant = "Tertiary",
                    Callback = function() end,
                },
                {
                    Title = "Confirm",
                    Icon = "check",
                    Variant = "Primary",
                    Callback = function()
                        pcall(function()
                            local TS = game:GetService("TeleportService")
                            local hopped = false
                            if httpReq then
                                local ok, res = pcall(function()
                                    return httpReq({ Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100", Method = "GET" })
                                end)
                                if ok and res and res.Body then
                                    local okJ, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
                                    if okJ and data and data.data then
                                        local pool = {}
                                        for _, srv in ipairs(data.data) do
                                            if srv.id ~= game.JobId and (srv.playing or 0) < (srv.maxPlayers or 0) then
                                                table.insert(pool, srv.id)
                                            end
                                        end
                                        if #pool > 0 then
                                            TS:TeleportToPlaceInstance(game.PlaceId, pool[math.random(1, #pool)])
                                            hopped = true
                                        end
                                    end
                                end
                            end
                            if not hopped then TS:Teleport(game.PlaceId) end
                        end)
                    end,
                },
            },
        })
    end,
})

tabSettings:Divider()

tabSettings:Button({
    Title = "Destroy Hub",
    Desc = "Completely unload Phantom",
    Icon = "trash-2",
    Callback = function()
        WindUI:Popup({
            Title = "Destroy Hub",
            Icon = "alert-triangle",
            Content = "This will unload Phantom entirely. Are you sure?",
            Buttons = {
                {
                    Title = "Cancel",
                    Variant = "Tertiary",
                    Callback = function() end,
                },
                {
                    Title = "Destroy",
                    Icon = "trash-2",
                    Variant = "Primary",
                    Callback = function()
                        Window:Destroy()
                    end,
                },
            },
        })
    end,
})

--═══════════════ FINALIZE ═══════════════
WindUI:Notify({
    Title = "Phantom",
    Content = "Welcome back, " .. lp.DisplayName .. "! Playing " .. gameInfo.name,
    Duration = 5,
    Icon = "ghost",
})
