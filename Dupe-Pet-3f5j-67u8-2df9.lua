local Players = game:GetService("Players")
local player = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

-- Target names list
_G.TargetNames = {
    "Dragonfly",
    "Queen Bee",
    "Red Fox",
    "Disco Bee"
}

-- Icon mapping
local ICONS = {
    ["Dragonfly"] = "🐉",
    ["Red Fox"] = "🦊",
    ["Queen Bee"] = "👑🐝",
    ["Disco Bee"] = "🌈🐝",
    Default = "🔍"
}

local DataSer = require(game:GetService("ReplicatedStorage").Modules.DataService)

-- Function to send notification
local function showNotify(text)
    StarterGui:SetCore("SendNotification", {
        Title = "System Notification | @dyumra",
        Text = text,
        Duration = 3,
    })
end

-- Variables for scan attempts
local scanAttempts = 0
local maxAttempts = 5

-- Function to create main GUI
local function createListMain(foundPets, targetStatus)
    -- Remove old GUI if any
    if player.PlayerGui:FindFirstChild("ListMain") then
        player.PlayerGui.ListMain:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ListMain"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player.PlayerGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 350, 0, 250)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Color3.new(0,0,0)
    mainFrame.BackgroundTransparency = 0.7
    mainFrame.Parent = screenGui
    mainFrame.AnchorPoint = Vector2.new(0,0)
    mainFrame.ClipsDescendants = true
    mainFrame.AutoButtonColor = false
    mainFrame.BorderSizePixel = 0
    mainFrame.Name = "ListMainFrame"
    mainFrame.Roundness = 10
    
    -- UICorner for rounded edges
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Title Label (Default List - rainbow color effect)
    local defaultLabel = Instance.new("TextLabel")
    defaultLabel.Size = UDim2.new(1, -20, 0, 90)
    defaultLabel.Position = UDim2.new(0, 10, 0, 10)
    defaultLabel.BackgroundTransparency = 1
    defaultLabel.TextXAlignment = Enum.TextXAlignment.Left
    defaultLabel.TextYAlignment = Enum.TextYAlignment.Top
    defaultLabel.Font = Enum.Font.SourceSansBold
    defaultLabel.TextSize = 18
    defaultLabel.Parent = mainFrame
    defaultLabel.Name = "DefaultList"
    defaultLabel.TextWrapped = true
    
    -- Generate rainbow text for Default list
    local function rainbowText(text)
        local colors = {
            Color3.fromRGB(255,0,0), -- red
            Color3.fromRGB(255,127,0), -- orange
            Color3.fromRGB(255,255,0), -- yellow
            Color3.fromRGB(0,255,0), -- green
            Color3.fromRGB(0,0,255), -- blue
            Color3.fromRGB(75,0,130), -- indigo
            Color3.fromRGB(148,0,211) -- violet
        }
        -- Simple approach: cycle colors for each character (this only works if using rich text)
        local output = ""
        local len = #text
        for i = 1, len do
            local c = text:sub(i,i)
            local color = colors[(i % #colors) + 1]
            local hex = string.format("#%02x%02x%02x", color.R*255, color.G*255, color.B*255)
            output = output .. '<font color="'..hex..'">'..c..'</font>'
        end
        return output
    end
    
    local defaultTextLines = {}
    for _, name in ipairs(_G.TargetNames) do
        local icon = ICONS[name] or ICONS.Default
        local status = (targetStatus[name] and "✅") or "❌"
        table.insert(defaultTextLines, string.format("(%s) %s: %s", icon, name, status))
    end
    defaultLabel.RichText = true
    defaultLabel.Text = rainbowText(table.concat(defaultTextLines, "\n"))
    
    -- Check List Label (white color)
    local checkLabel = Instance.new("TextLabel")
    checkLabel.Size = UDim2.new(1, -20, 0, 120)
    checkLabel.Position = UDim2.new(0, 10, 0, 110)
    checkLabel.BackgroundTransparency = 1
    checkLabel.TextXAlignment = Enum.TextXAlignment.Left
    checkLabel.TextYAlignment = Enum.TextYAlignment.Top
    checkLabel.Font = Enum.Font.SourceSans
    checkLabel.TextSize = 18
    checkLabel.TextColor3 = Color3.new(1,1,1)
    checkLabel.Parent = mainFrame
    checkLabel.Name = "CheckList"
    checkLabel.TextWrapped = true
    
    -- Build Check List (real-time found pets, max 5, min 1)
    local count = #foundPets
    if count == 0 then count = 1 end
    if count > 5 then count = 5 end
    
    local checkLines = {}
    for i = 1, count do
        local petName = foundPets[i] or "N/A"
        local icon = ICONS.Default
        local status = (targetStatus[petName] and "✅") or "❌"
        table.insert(checkLines, string.format("%d.(%s) %s: %s", i, icon, petName, status))
    end
    checkLabel.Text = table.concat(checkLines, "\n")
    
    -- LogMenu frame below ListMain
    local logFrame = Instance.new("Frame")
    logFrame.Size = UDim2.new(0, 350, 0, 100)
    logFrame.Position = UDim2.new(0, 10, 0, 270)
    logFrame.BackgroundColor3 = Color3.new(0,0,0)
    logFrame.BackgroundTransparency = 0.7
    logFrame.Parent = screenGui
    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0,10)
    logCorner.Parent = logFrame
    
    local logLabel = Instance.new("TextLabel")
    logLabel.Size = UDim2.new(1, -20, 0, 80)
    logLabel.Position = UDim2.new(0, 10, 0, 10)
    logLabel.BackgroundTransparency = 1
    logLabel.TextColor3 = Color3.new(1,1,1)
    logLabel.Font = Enum.Font.SourceSans
    logLabel.TextSize = 16
    logLabel.TextXAlignment = Enum.TextXAlignment.Left
    logLabel.TextYAlignment = Enum.TextYAlignment.Top
    logLabel.TextWrapped = true
    logLabel.Parent = logFrame
    
    local targetNamesStr = table.concat(foundPets, ", ")
    if targetNamesStr == "" then
        targetNamesStr = "N/A"
    end
    
    logLabel.Text = string.format("⚙️ Log:\n🎯 Target: %s\n🛡️ Target Scan: %d attempted(s)\n🔗 Dev: https://github.com/dyumra/", targetNamesStr, scanAttempts)
    
    -- Buttons below logFrame
    local btnFrame = Instance.new("Frame")
    btnFrame.Size = UDim2.new(1, -20, 0, 30)
    btnFrame.Position = UDim2.new(0, 10, 0, 80)
    btnFrame.BackgroundTransparency = 1
    btnFrame.Parent = logFrame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0.5, -5, 1, 0)
    toggleButton.Position = UDim2.new(0, 0, 0, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(0,0,0)
    toggleButton.BackgroundTransparency = 0.7
    toggleButton.TextColor3 = Color3.new(1,1,1)
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.TextSize = 16
    toggleButton.Text = "Disable/Enable Server-Hop"
    toggleButton.Parent = btnFrame
    local toggleState = true
    
    toggleButton.MouseButton1Click:Connect(function()
        toggleState = not toggleState
        screenGui.Enabled = toggleState
        local msg = toggleState and "Server-Hop GUI Enabled." or "Server-Hop GUI Disabled."
        showNotify(msg)
    end)
    
    local devButton = Instance.new("TextButton")
    devButton.Size = UDim2.new(0.5, -5, 1, 0)
    devButton.Position = UDim2.new(0.5, 5, 0, 0)
    devButton.BackgroundColor3 = Color3.fromRGB(0,0,0)
    devButton.BackgroundTransparency = 0.7
    devButton.TextColor3 = Color3.new(1,1,1)
    devButton.Font = Enum.Font.SourceSansBold
    devButton.TextSize = 16
    devButton.Text = "Powered by @ dyumra."
    devButton.Parent = btnFrame
    
    devButton.MouseButton1Click:Connect(function()
        setclipboard("https://github.com/dyumra/")
        showNotify("GitHub link copied to clipboard!")
    end)
end

-- Main loop
while true do
    wait(2)
    local savedObjects = DataSer:GetData().SavedObjects
    local foundPets = {}
    local targetStatus = {}
    
    -- Initialize all target status to false
    for _, name in pairs(_G.TargetNames) do
        targetStatus[name] = false
    end
    
    for i, v in pairs(savedObjects) do
        if v.ObjectType == "PetEgg" and v.Data.RandomPetData then
            local petName = v.Data.RandomPetData.Name
            for _, targetName in pairs(_G.TargetNames) do
                if petName == targetName then
                    targetStatus[petName] = true
                    table.insert(foundPets, petName)
                end
            end
        end
    end
    
    -- Remove duplicates from foundPets
    local uniqueFoundPets = {}
    local hash = {}
    for _, v in ipairs(foundPets) do
        if not hash[v] then
            table.insert(uniqueFoundPets, v)
            hash[v] = true
        end
    end
    
    scanAttempts = scanAttempts + 1
    
    -- Create or update GUI
    createListMain(uniqueFoundPets, targetStatus)
    
    -- Send notification about scan result
    if #uniqueFoundPets > 0 then
        showNotify("Found pets: " .. table.concat(uniqueFoundPets, ", "))
    else
        showNotify("No target pets found.")
    end
    
    print("[Scan #" .. scanAttempts .. "] Found pets: " .. table.concat(uniqueFoundPets, ", "))
    
    if scanAttempts >= maxAttempts then
        break
    end
end
