-- Global table for target names (assuming this is accessible)
_G.TargetNames = {
    "Dragonfly",
    "Queen Bee",
    "Red Fox",
    "Disco Bee"
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local rejoinDelay = 1
local kickMessageBase = "🌐 System Notification: No designated target eggs were detected in this server. Initiating automatic server relocation. \n 🟢 QN: Server-Finding... attempt(%d) \n ⚙️ NF: Dragonfly: ❌ attempt(%d) \n ⚙️ NF: Queen Bee: ❌ attempt(%d) \n ⚙️ NF: Red Fox: ❌ attempt(%d) \n ⚙️ NF: Disco Bee: ❌ attempt(%d)"
local maxRejoinAttempts = 5

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggHunterGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

local textLabel = Instance.new("TextLabel")
textLabel.Name = "StatusLabel"
textLabel.Size = UDim2.new(0, 250, 0, 100)
textLabel.Position = UDim2.new(0.01, 0, 0.05, 0)
textLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
textLabel.BackgroundTransparency = 0.7
textLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
textLabel.Font = Enum.Font.SourceSansBold
textLabel.TextSize = 18
textLabel.TextWrapped = true
textLabel.TextXAlignment = Enum.TextXAlignment.Left
textLabel.TextYAlignment = Enum.TextYAlignment.Top
textLabel.Text = "🔍 List Target ( 🐉 ) Dragonfly: , ( 🐝👑 ) Queen Bee: , ( 🦊 ) Red Fox: , ( 🐝🪩 ) Disco Bee:\nStatus: Initializing\nPowered by dyumra"
textLabel.BorderSizePixel = 0
textLabel.ClipsDescendants = true
textLabel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = textLabel

local eggStatusLabel = Instance.new("TextLabel")
eggStatusLabel.Name = "EggStatusLabel"
eggStatusLabel.Size = UDim2.new(0, 200, 0, 100)
eggStatusLabel.Position = UDim2.new(1, -210, 0.05, 0)
eggStatusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
eggStatusLabel.BackgroundTransparency = 0.7
eggStatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
eggStatusLabel.Font = Enum.Font.SourceSansBold
eggStatusLabel.TextSize = 16
eggStatusLabel.TextWrapped = true
eggStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
eggStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
eggStatusLabel.BorderSizePixel = 0
eggStatusLabel.ClipsDescendants = true
eggStatusLabel.Parent = screenGui

local eggStatusCorner = Instance.new("UICorner")
eggStatusCorner.CornerRadius = UDim.new(0, 10)
eggStatusCorner.Parent = eggStatusLabel

local targetDisplayLabel = Instance.new("TextLabel")
targetDisplayLabel.Name = "TargetDisplayLabel"
targetDisplayLabel.Size = UDim2.new(0, 300, 0, 50)
targetDisplayLabel.Position = UDim2.new(0.01, 0, 1, -60)
targetDisplayLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
targetDisplayLabel.BackgroundTransparency = 0.7
targetDisplayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
targetDisplayLabel.Font = Enum.Font.SourceSansBold
targetDisplayLabel.TextSize = 24
targetDisplayLabel.TextWrapped = true
targetDisplayLabel.TextXAlignment = Enum.TextXAlignment.Center
targetDisplayLabel.TextYAlignment = Enum.TextYAlignment.Center
targetDisplayLabel.BorderSizePixel = 0
targetDisplayLabel.ClipsDescendants = true
targetDisplayLabel.Parent = screenGui

local targetDisplayCorner = Instance.new("UICorner")
targetDisplayCorner.CornerRadius = UDim.new(0, 10)
targetDisplayCorner.Parent = targetDisplayLabel

local eggFoundStatus = {}
for _, targetName in ipairs(_G.TargetNames) do
    eggFoundStatus[targetName] = "❌"
end

local highlightColors = {
    ["Bug Egg"] = Color3.fromRGB(0, 255, 0),
    ["Anti Bee Egg"] = Color3.fromRGB(255, 0, 0),
    ["Bee Egg"] = Color3.fromRGB(255, 165, 0)
}

local activeHighlights = {}

local function updateEggStatusDisplay()
    local statusText = ""
    for _, targetName in ipairs(_G.TargetNames) do
        local emoji = ""
        if targetName == "Dragonfly" then
            emoji = "🐉"
        elseif targetName == "Queen Bee" then
            emoji = "🐝👑"
        elseif targetName == "Red Fox" then
            emoji = "🦊"
        elseif targetName == "Disco Bee" then
            emoji = "🐝🪩"
        end
        statusText = statusText .. emoji .. " " .. targetName .. ": " .. eggFoundStatus[targetName] .. "\n"
    end
    eggStatusLabel.Text = statusText
end

updateEggStatusDisplay()

local function animateTextColor(labelToAnimate, isRainbow)
    local colors = {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(255, 0, 255)
    }
    local tweenInfo = TweenInfo.new(
        2,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    task.spawn(function()
        while task.wait() do
            if isRainbow and labelToAnimate.Parent then
                for i = 1, #colors do
                    local nextColorIndex = (i % #colors) + 1
                    local goal = { TextColor3 = colors[nextColorIndex] }
                    local tween = TweenService:Create(labelToAnimate, tweenInfo, goal)
                    tween:Play()
                    tween.Completed:Wait()
                end
            else
                break
            end
        end
    end)
end

animateTextColor(eggStatusLabel, true)

local function sendNotification(title, text, duration, icon)
    print("Notification: " .. title .. " - " .. text)
end

local function setHighlight(part, color)
    if activeHighlights[part] then
        activeHighlights[part]:Destroy()
        activeHighlights[part] = nil
    end

    if part and color then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.Parent = part
        activeHighlights[part] = highlight
    end
end

local confirmationFrame = Instance.new("Frame")
confirmationFrame.Name = "ServerHopConfirmation"
confirmationFrame.Size = UDim2.new(0, 300, 0, 150)
confirmationFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
confirmationFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
confirmationFrame.BackgroundTransparency = 0.1
confirmationFrame.BorderSizePixel = 0
confirmationFrame.Visible = false
confirmationFrame.Parent = screenGui

local confirmationCorner = Instance.new("UICorner")
confirmationCorner.CornerRadius = UDim.new(0, 10)
confirmationCorner.Parent = confirmationFrame

local confirmationText = Instance.new("TextLabel")
confirmationText.Name = "ConfirmationText"
confirmationText.Size = UDim2.new(1, 0, 0.6, 0)
confirmationText.Position = UDim2.new(0, 0, 0, 0)
confirmationText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
confirmationText.BackgroundTransparency = 1
confirmationText.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmationText.Font = Enum.Font.SourceSansBold
confirmationText.TextSize = 20
confirmationText.TextWrapped = true
confirmationText.TextXAlignment = Enum.TextXAlignment.Center
confirmationText.TextYAlignment = Enum.TextYAlignment.Center
confirmationText.Text = "No target eggs found after 5 attempts.\nDo you want to Server-Hop?"
confirmationText.Parent = confirmationFrame

local yesButton = Instance.new("TextButton")
yesButton.Name = "YesButton"
yesButton.Size = UDim2.new(0.4, 0, 0.3, 0)
yesButton.Position = UDim2.new(0.05, 0, 0.65, 0)
yesButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
yesButton.Font = Enum.Font.SourceSansBold
yesButton.TextSize = 20
yesButton.Text = "Yes"
yesButton.BorderSizePixel = 0
yesButton.Parent = confirmationFrame

local yesButtonCorner = Instance.new("UICorner")
yesButtonCorner.CornerRadius = UDim.new(0, 5)
yesButtonCorner.Parent = yesButton

local noButton = Instance.new("TextButton")
noButton.Name = "NoButton"
noButton.Size = UDim2.new(0.4, 0, 0.3, 0)
noButton.Position = UDim2.new(0.55, 0, 0.65, 0)
noButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
noButton.TextColor3 = Color3.fromRGB(255, 255, 255)
noButton.Font = Enum.Font.SourceSansBold
noButton.TextSize = 20
noButton.Text = "No"
noButton.BorderSizePixel = 0
noButton.Parent = confirmationFrame

local noButtonCorner = Instance.new("UICorner")
noButtonCorner.CornerRadius = UDim.new(0, 5)
noButtonCorner.Parent = noButton

local rejoinAttempts = 0
local serverHopConfirmed = false

local function showConfirmationPrompt()
    confirmationFrame.Visible = true
    local originalText = textLabel.Text
    textLabel.Text = "Waiting for Server-Hop confirmation..."

    serverHopConfirmed = false
    local promptResponse = nil

    local function onYesClicked()
        promptResponse = true
        confirmationFrame.Visible = false
    end

    local function onNoClicked()
        promptResponse = false
        confirmationFrame.Visible = false
    end

    yesButton.MouseButton1Click:Connect(onYesClicked)
    noButton.MouseButton1Click:Connect(onNoClicked)

    repeat task.wait() until promptResponse ~= nil

    textLabel.Text = originalText
    return promptResponse
end

while task.wait(1) do
    local foundAnyTargetEggInCurrentScan = false
    local foundEggNameInCurrentScan = ""
    local currentTargetEggName = "None"

    for part, highlight in pairs(activeHighlights) do
        highlight:Destroy()
    end
    activeHighlights = {}

    for k in pairs(eggFoundStatus) do
        eggFoundStatus[k] = "❌"
    end

    textLabel.Text = "🔍 List Target ( 🐉 ) Dragonfly: , ( 🐝👑 ) Queen Bee: , ( 🦊 ) Red Fox: , ( 🐝🪩 ) Disco Bee:\nStatus: Scanning Server...\nPowered by dyumra"
    sendNotification("⚙️ System Notification", "Commencing server scan for target eggs.", 3)

    local potentialEggContainers = {game.Workspace} 
    
    local foundEggsInWorkspace = {}
    for _, container in ipairs(potentialEggContainers) do
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:find("Egg") then
                local eggDisplayName = nil
                if obj:FindFirstChild("DisplayName") and obj.DisplayName:IsA("StringValue") then
                    eggDisplayName = obj.DisplayName.Value
                elseif obj.Name then
                    eggDisplayName = obj.Name 
                end

                if eggDisplayName then
                    for _, targetName in ipairs(_G.TargetNames) do
                        if eggDisplayName:find(targetName) then
                            table.insert(foundEggsInWorkspace, {Model = obj, DisplayName = eggDisplayName, RawName = obj.Name})
                            break
                        end
                    end
                end
            end
        end
    end

    if #foundEggsInWorkspace > 0 then
        for _, eggData in ipairs(foundEggsInWorkspace) do
            local eggDisplayName = eggData.DisplayName
            local eggModel = eggData.Model
            local eggRawName = eggData.RawName

            for _, targetName in ipairs(_G.TargetNames) do
                if eggDisplayName:find(targetName) then
                    foundAnyTargetEggInCurrentScan = true
                    foundEggNameInCurrentScan = targetName
                    eggFoundStatus[targetName] = "✅"

                    local highlightColor = highlightColors[eggRawName] or Color3.fromRGB(0, 255, 255)
                    if highlightColor then
                        setHighlight(eggModel, highlightColor)
                    end

                    if targetName == "Queen Bee" then
                        currentTargetEggName = "Queen Bee"
                        targetDisplayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        animateTextColor(targetDisplayLabel, true)
                    elseif targetName == "Disco Bee" then 
                        currentTargetEggName = "Disco Bee"
                        targetDisplayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        animateTextColor(targetDisplayLabel, true)
                    end
                end
            end
        end
    else
        sendNotification("⚠️ Info", "No eggs found in accessible game objects.", 3)
    end

    updateEggStatusDisplay()

    if currentTargetEggName == "None" then
        targetDisplayLabel.Text = "Target: None"
        targetDisplayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        animateTextColor(targetDisplayLabel, false)
    else
        targetDisplayLabel.Text = "Target: " .. currentTargetEggName
    end

    if foundAnyTargetEggInCurrentScan then
        textLabel.Text = "🔍 List Target ( 🐉 ) Dragonfly: , ( 🐝👑 ) Queen Bee: , ( 🦊 ) Red Fox: , ( 🐝🪩 ) Disco Bee:\nStatus 🟢: Target Found: " .. foundEggNameInCurrentScan .. "\nPowered by dyumra"
        sendNotification("✅ System Notification", "Target identified: " .. foundEggNameInCurrentScan .. ". Process complete.", 10)
        
        for part, highlight in pairs(activeHighlights) do
            highlight:Destroy()
        end
        activeHighlights = {}
        screenGui:Destroy()
        break
    else
        rejoinAttempts = rejoinAttempts + 1
        local currentKickMessage = string.format(kickMessageBase, rejoinAttempts, rejoinAttempts, rejoinAttempts, rejoinAttempts, rejoinAttempts)

        textLabel.Text = "🚫 List Target ( 🐉 ) Dragonfly: , ( 🐝👑 ) Queen Bee: , ( 🦊 ) Red Fox: , ( 🐝🪩 ) Disco Bee:\nStatus: No targets. Scan again (Attempt " .. rejoinAttempts .. ")...\nPowered by dyumra"
        sendNotification("⚙️ System Notification", "No designated target eggs detected. Scanning again. Attempt: " .. rejoinAttempts, 5)
        
        if rejoinAttempts >= maxRejoinAttempts then
            sendNotification("🌐 System Notification", "Max scan attempts reached. Prompting for Server-Hop.", 5)
            local shouldServerHop = showConfirmationPrompt()

            if shouldServerHop then
                if LocalPlayer then
                    print("User confirmed Server-Hop. Initiating teleport.")
                    if pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) then
                         print("Teleport initiated successfully.")
                    else
                        print("Teleport failed or is not supported by the current executor environment.")
                    end
                    
                    for part, highlight in pairs(activeHighlights) do
                        highlight:Destroy()
                    end
                    activeHighlights = {}
                    screenGui:Destroy()
                    break
                else
                    print("LocalPlayer not found, cannot initiate teleport.")
                end
            else
                print("User chose NOT to Server-Hop. Resetting attempts and continuing scan.")
                rejoinAttempts = 0
                task.wait(rejoinDelay)
            end
        else
            task.wait(rejoinDelay)
        end
    end
end
