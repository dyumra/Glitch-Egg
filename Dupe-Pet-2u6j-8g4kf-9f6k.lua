-- Version: Disabled Auto ServerHop

_G.TargetNames = {
    "Dragonfly",
    "Queen Bee",
    "Red Fox",
    "Disco Bee"
}

local DataSer = require(game:GetService("ReplicatedStorage").Modules.DataService)
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local rejoinDelay = 1
local noTargetMessage = "🌐 System Notification: No designated target eggs were detected in this server. Do you want to search for a new server?\n 🟢 QN: Server-Finding... attempt(%d)"
local rejoinAttemptStatusMessage = "⚙️ NF: Dragonfly: ❌ attempt(%d) \n ⚙️ NF: Queen Bee: ❌ attempt(%d) \n ⚙️ NF: Red Fox: ❌ attempt(%d) \n ⚙️ NF: Disco Bee: ❌ attempt(%d)"

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggHunterGUI"
screenGui.ResetOnSpawn = false

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
textLabel.Text = "🔍 Target Eggs: " .. table.concat(_G.TargetNames, ", ") .. "\nStatus: Initializing\nPowered by dyumra"
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
targetDisplayLabel.Position = UDim2.new(0.01, 0, 0.95, -50)
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

screenGui.Parent = StarterGui

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
        statusText = statusText .. targetName .. ": " .. eggFoundStatus[targetName] .. "\n"
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

local function sendNotificationWithButtons(title, text, buttons, duration, icon)
    local success, result = pcall(function()
        return StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5,
            Icon = icon or "",
            Button1 = buttons[1] and buttons[1].Text or nil,
            Button2 = buttons[2] and buttons[2].Text or nil,
            Button1Click = buttons[1] and buttons[1].Callback or nil,
            Button2Click = buttons[2] and buttons[2].Callback or nil,
        })
    end)
    if not success then
        warn("Failed to send notification with buttons: " .. tostring(result))
    end
end

local function sendNotification(title, text, duration, icon)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 5,
        Icon = icon or ""
    })
}

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
}

local rejoinAttempts = 0

while true do
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

    textLabel.Text = "🔍 Target Eggs: " .. table.concat(_G.TargetNames, ", ") .. "\nStatus: Scanning Server...\nPowered by dyumra"
    sendNotification("⚙️ System Notification", "Commencing server scan for target eggs.", 3, "rbxassetid://6034177218")

    local data = DataSer:GetData()
    if data and data.SavedObjects then
        for _, obj in pairs(data.SavedObjects) do
            if obj.ObjectType == "PetEgg" then
                if obj.Data.RandomPetData ~= nil and obj.Data.CanHatch then
                    local eggDisplayName = obj.Data.RandomPetData.DisplayName or obj.Data.RandomPetData.Name

                    for _, targetName in ipairs(_G.TargetNames) do
                        if eggDisplayName == targetName then
                            foundAnyTargetEggInCurrentScan = true
                            foundEggNameInCurrentScan = targetName
                            eggFoundStatus[targetName] = "✅"

                            local highlightColor = highlightColors[obj.Data.RandomPetData.Name]
                            if highlightColor then
                                setHighlight(obj.Model, highlightColor)
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
            end
        end
    else
        sendNotification("⚠️ Error", "Failed to retrieve game data. Please try again or rejoin manually.", 3)
        task.wait(5)
        continue
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
        textLabel.Text = "🔍 Target Eggs: " .. table.concat(_G.TargetNames, ", ") .. "\nStatus 🟢: Target Found: " .. foundEggNameInCurrentScan .. "\nPowered by dyumra"
        sendNotification("✅ System Notification", "Target identified: " .. foundEggNameInCurrentScan .. ". Process complete.", 10, "rbxassetid://6034177218")
        
        for part, highlight in pairs(activeHighlights) do
            highlight:Destroy()
        end
        activeHighlights = {}
        screenGui:Destroy()
        break
    else
        rejoinAttempts = rejoinAttempts + 1
        local fullNoTargetMessage = string.format(noTargetMessage, rejoinAttempts) .. "\n" .. string.format(rejoinAttemptStatusMessage, rejoinAttempts, rejoinAttempts, rejoinAttempts, rejoinAttempts)

        textLabel.Text = "🚫 Target Eggs: " .. table.concat(_G.TargetNames, ", ") .. "\nStatus: Waiting for user input (Attempt " .. rejoinAttempts .. ")...\nPowered by dyumra"
        
        sendNotificationWithButtons(
            "⚙️ System Notification",
            fullNoTargetMessage,
            {
                {
                    Text = "Yes",
                    Callback = function()
                        textLabel.Text = "🚫 Target Eggs: " .. table.concat(_G.TargetNames, ", ") .. "\nStatus: Rejoining Server...\nPowered by dyumra"
                        sendNotification("⚙️ System Notification", "Initiating server rejoin sequence.", 3, "rbxassetid://6034177218")
                        task.wait(rejoinDelay)
                        local success, err = pcall(function()
                            TeleportService:Teleport(game.PlaceId, LocalPlayer)
                        end)
                        if not success then
                            warn("Teleport failed: " .. err)
                            sendNotification("⚠️ Error", "Teleport failed. Retrying...", 3)
                            task.wait(5)
                        end
                    end
                },
                {
                    Text = "No",
                    Callback = function()
                        textLabel.Text = "🚫 Target Eggs: " .. table.concat(_G.TargetNames, ", ") .. "\nStatus: Staying in server.\nPowered by dyumra"
                        sendNotification("ℹ️ System Notification", "Staying in current server.", 3)
                    end
                }
            },
            15,
            "rbxassetid://6034177218"
        )
    end

    task.wait(1)
end
