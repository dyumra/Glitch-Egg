-- ★★★ CONFIG ★★★
local TARGET_NAMES = {
    ["Dragonfly"] = true,
    ["Red Fox"] = true,
    ["Queen Bee"] = true,
    ["Disco Bee"] = true
}

local ICONS = {
    ["Dragonfly"] = "🐉",
    ["Red Fox"] = "🦊",
    ["Queen Bee"] = "👑🐝",
    ["Disco Bee"] = "🌈🐝",
    Default = "🔍"
}

local MAX_ROWS = 5
local SCAN_DELAY = 3
local MAX_ATTEMPTS = 5

-- SERVICES
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RepStore = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local DataService = require(RepStore.Modules.DataService)
local plr = Players.LocalPlayer

-- STATE
local attempts = 0
local serverHopEnabled = true

-- UI SETUP
local gui = Instance.new("ScreenGui", plr:WaitForChild("PlayerGui"))
gui.Name = "PetScannerUI"; gui.ResetOnSpawn = false

local function roundCorner(inst, radius)
    local cr = Instance.new("UICorner", inst)
    cr.CornerRadius = UDim.new(0, radius)
end

-- ListMain Frame
local listF = Instance.new("Frame", gui)
listF.Size = UDim2.new(0, 360, 0, 220)
listF.Position = UDim2.new(0,10,0,10)
listF.BackgroundColor3 = Color3.new(0,0,0)
listF.BackgroundTransparency = 0.7
roundCorner(listF, 12)

local listMain = Instance.new("TextLabel", listF)
listMain.Size = UDim2.new(1, -10, 0.5, -10)
listMain.Position = UDim2.new(0,5,0,5)
listMain.TextWrapped = true
listMain.RichText = true
listMain.TextXAlignment = Enum.TextXAlignment.Left
listMain.TextYAlignment = Enum.TextYAlignment.Top
listMain.Font = Enum.Font.SourceSansBold
listMain.TextSize = 18
listMain.BackgroundTransparency = 1
listMain.Text = ""
listMain.ClipsDescendants = true

-- List Check Frame
local checkF = Instance.new("Frame", gui)
checkF.Size = UDim2.new(0, 360, 0, 170)
checkF.Position = UDim2.new(0,10,0,240)
checkF.BackgroundColor3 = Color3.new(0,0,0)
checkF.BackgroundTransparency = 0.7
roundCorner(checkF, 12)

local checkMain = Instance.new("TextLabel", checkF)
checkMain.Size = UDim2.new(1,-10,1,-10)
checkMain.Position = UDim2.new(0,5,0,5)
checkMain.TextWrapped = true
checkMain.RichText = true
checkMain.TextXAlignment = Enum.TextXAlignment.Left
checkMain.TextYAlignment = Enum.TextYAlignment.Top
checkMain.Font = Enum.Font.SourceSansBold
checkMain.TextSize = 18
checkMain.BackgroundTransparency = 1

-- LogMenu Frame
local logF = Instance.new("Frame", gui)
logF.Size = UDim2.new(0, 360, 0, 160)
logF.Position = UDim2.new(0,10,0,430)
logF.BackgroundColor3 = Color3.new(0,0,0)
logF.BackgroundTransparency = 0.7
roundCorner(logF, 12)

local logLabel = Instance.new("TextLabel", logF)
logLabel.Size = UDim2.new(1,-10,1,-50)
logLabel.Position = UDim2.new(0,5,0,5)
logLabel.TextWrapped = true
logLabel.RichText = true
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.Font = Enum.Font.SourceSansBold
logLabel.TextSize = 18
logLabel.BackgroundTransparency = 1

-- Buttons
local btnFrame = Instance.new("Frame", logF)
btnFrame.Size = UDim2.new(1,-10,0,40)
btnFrame.Position = UDim2.new(0,5,1,-45)
btnFrame.BackgroundTransparency = 1

local toggleBtn = Instance.new("TextButton", btnFrame)
toggleBtn.Size = UDim2.new(0.48,0,1,0)
toggleBtn.Position = UDim2.new(0,0,0,0)
toggleBtn.Text = "Disable Server‑Hop"
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 18
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.BackgroundColor3 = Color3.new(0,0,0)
toggleBtn.BackgroundTransparency = 0.7
roundCorner(toggleBtn, 10)

local devBtn = Instance.new("TextButton", btnFrame)
devBtn.Size = UDim2.new(0.48,0,1,0)
devBtn.Position = UDim2.new(0.52,0,0,0)
devBtn.Text = "Powered by @dyumra."
devBtn.Font = Enum.Font.SourceSansBold
devBtn.TextSize = 18
devBtn.TextColor3 = Color3.new(1,1,1)
devBtn.BackgroundColor3 = Color3.new(0,0,0)
devBtn.BackgroundTransparency = 0.7
roundCorner(devBtn, 10)

-- NOTIFY
local function showNotify(text)
    StarterGui:SetCore("SendNotification",{
        Title = "System Notification | @dyumra",
        Text = text, Duration = 3
    })
end

-- DATA HANDLERS
local function hasEgg(name)
    for _, o in pairs(DataService:GetData().SavedObjects) do
        if o.ObjectType=="PetEgg" and o.Data.RandomPetData and o.Data.CanHatch and o.Data.RandomPetData.Name==name then
            return true
        end
    end
    return false
end

local function getFoundList()
    local t, seen = {}, {}
    for _, o in pairs(DataService:GetData().SavedObjects) do
        if o.ObjectType=="PetEgg" and o.Data.RandomPetData and o.Data.CanHatch then
            local n = o.Data.RandomPetData.Name
            if not seen[n] then
                seen[n] = true
                table.insert(t, n)
                if #t >= MAX_ROWS then break
            end
        end
    end
    return t
end

local function refreshUI()
    -- ListMain (rainbow color)
    local ltxt = ""
    for _, n in ipairs(TARGET_NAMES) do
        local icon = ICONS[n] or ICONS.Default
        local mark = hasEgg(n) and "✅" or "❌"
        ltxt ..= string.format("<font color=\"rgb(%d,%d,%d)\">(%s) %s: %s</font>\n",
            tick()%2*127+128,  -- dynamic rainbow
            tick()%3*85+85,
            tick()%5*51+51,
            icon, n, mark)
    end
    listMain.Text = ltxt

    -- CheckList (white)
    local fnd = getFoundList()
    local cl = ""
    for i=1,MAX_ROWS do
        local name = fnd[i] or "N/A"
        local icon = ICONS.Default
        local mark = name=="N/A" and "❌" or "✅"
        cl ..= string.format("%d.(%s) %s: %s\n", i, icon, name, mark)
    end
    checkMain.Text = cl

    -- LogMenu
    local targets = table.concat(fnd, ", ")
    logLabel.Text = string.format(
        "⚙️ Log:\n🎯 Target: %s\n🛡️ Target Scan: %s attempted(s)\n🌐 N/A\n🔗 Dev: https://github.com/dyumra/",
        (targets ~= "" and targets) or "N/A", attempts
    )
end

-- SCAN LOOP
spawn(function()
    while true do
        wait(SCAN_DELAY)
        attempts += 1
        if serverHopEnabled and attempts >= MAX_ATTEMPTS then
            showNotify("No target eggs found after "..attempts.." attempts.")
            TeleportService:Teleport(game.PlaceId, plr)
            return
        end
        refreshUI()
    end
end)

-- BUTTON EVENTS
toggleBtn.MouseButton1Click:Connect(function()
    serverHopEnabled = not serverHopEnabled
    toggleBtn.Text = serverHopEnabled and "Disable Server‑Hop" or "Enable Server‑Hop"
    showNotify("Server‑Hop is now "..(serverHopEnabled and "ENABLED" or "DISABLED"))
end)

devBtn.MouseButton1Click:Connect(function()
    setclipboard("https://github.com/dyumra/")
    showNotify("GitHub link copied!")
end)

-- INIT
refreshUI()
