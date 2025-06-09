_G.TargetNames = {
    "Dragonfly",
    "Queen Bee",
    "Red Fox"
}

local DataSer = require(game:GetService("ReplicatedStorage").Modules.DataService)
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService") -- Get the TweenService for animations

local rejoinDelay = 1 -- Delay before attempting to rejoin (seconds)
-- Formal kick message, now includes a placeholder for attempt number
local kickMessageBase = "🌐 System Notification: No designated target eggs were detected in this server. Initiating automatic server relocation. \n 🟢 QN: Server-Finding... attempt(%d)"

-- Create the main ScreenGui for all GUI elements
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggHunterGUI"
screenGui.ResetOnSpawn = false

-- Create the main status TextLabel (top-left)
local textLabel = Instance.new("TextLabel")
textLabel.Name = "StatusLabel"
textLabel.Size = UDim2.new(0, 250, 0, 100) -- Adjust size as needed
textLabel.Position = UDim2.new(0.01, 0, 0.05, 0) -- Top-left corner (1% from left, 5% from top)
textLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Dark background
textLabel.BackgroundTransparency = 0.7 -- Slightly transparent
textLabel.TextColor3 = Color3.fromRGB(240, 240, 240) -- Light gray text
textLabel.Font = Enum.Font.SourceSansBold -- Bold font
textLabel.TextSize = 18
textLabel.TextWrapped = true
textLabel.TextXAlignment = Enum.TextXAlignment.Left
textLabel.TextYAlignment = Enum.TextYAlignment.Top
textLabel.Text = "🔍 Target Eggs: " .. table.concat(_G.TargetNames, ", ") .. "\nStatus: Initializing\nPowered by dyumra" -- Initial text
textLabel.BorderSizePixel = 0 -- Remove border for cleaner look
textLabel.ClipsDescendants = true -- Enable rounded corners
textLabel.Parent = screenGui

local corner = Instance.new("UICorner") -- Create rounded corners for StatusLabel
corner.CornerRadius = UDim.new(0, 10) -- Set corner radius
corner.Parent = textLabel

-- NEW: Create TextLabel for individual egg status (top-right)
local eggStatusLabel = Instance.new("TextLabel")
eggStatusLabel.Name = "EggStatusLabel"
eggStatusLabel.Size = UDim2.new(0, 200, 0, 100) -- Adjust size as needed
-- Position: 1 (right edge) - width - offset (10 pixels from right edge)
eggStatusLabel.Position = UDim2.new(1, -210, 0.05, 0)
eggStatusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
eggStatusLabel.BackgroundTransparency = 0.7
eggStatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Initial white, will be animated
eggStatusLabel.Font = Enum.Font.SourceSansBold
eggStatusLabel.TextSize = 16
eggStatusLabel.TextWrapped = true
eggStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
eggStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
eggStatusLabel.BorderSizePixel = 0
eggStatusLabel.ClipsDescendants = true
eggStatusLabel.Parent = screenGui

local eggStatusCorner = Instance.new("UICorner") -- Create rounded corners for EggStatusLabel
eggStatusCorner.CornerRadius = UDim.new(0, 10)
eggStatusCorner.Parent = eggStatusLabel

-- Parent the ScreenGui to StarterGui so it appears on the player's screen
screenGui.Parent = StarterGui

-- Initialize a map to store the found/not found status for each target egg
local eggFoundStatus = {}
for _, targetName in ipairs(_G.TargetNames) do
    eggFoundStatus[targetName] = "❌" -- Initially mark all as not found (❌)
end

-- Function to update the text of the individual egg status display
local function updateEggStatusDisplay()
    local statusText = ""
    for _, targetName in ipairs(_G.TargetNames) do
        -- Concatenate the egg name with its current status (✅ or ❌)
        statusText = statusText .. targetName .. ": " .. eggFoundStatus[targetName] .. "\n"
    end
    eggStatusLabel.Text = statusText
end

updateEggStatusDisplay() -- Call once to set initial text for EggStatusLabel

-- NEW: Function to animate TextLabel color, creating a smooth RGB effect
local function animateTextColor(labelToAnimate)
    -- Define a sequence of colors for the animation
    local colors = {
        Color3.fromRGB(255, 0, 0),    -- Red
        Color3.fromRGB(255, 255, 0),  -- Yellow
        Color3.fromRGB(0, 255, 0),    -- Green
        Color3.fromRGB(0, 255, 255),  -- Cyan
        Color3.fromRGB(0, 0, 255),    -- Blue
        Color3.fromRGB(255, 0, 255)   -- Magenta
    }
    -- TweenInfo defines how the animation will play (duration, easing style, direction)
    local tweenInfo = TweenInfo.new(
        2, -- Duration of each color transition in seconds
        Enum.EasingStyle.Linear, -- Smooth, linear transition
        Enum.EasingDirection.Out -- Easing direction
    )

    -- Use task.spawn to run this animation in a separate thread, so it doesn't block the main script
    task.spawn(function()
        while task.wait() do -- Loop indefinitely for continuous animation
            for i = 1, #colors do
                local nextColorIndex = (i % #colors) + 1 -- Calculate the index of the next color in the sequence
                -- Define the target properties for the tween
                local goal = { TextColor3 = colors[nextColorIndex] }
                -- Create a new tween for the label's TextColor3 property
                local tween = TweenService:Create(labelToAnimate, tweenInfo, goal)
                tween:Play() -- Start the tween animation
                tween.Completed:Wait() -- Wait for the current tween to complete before starting the next
            end
        end
    end)
end

animateTextColor(eggStatusLabel) -- Start animating the text color of the new EggStatusLabel

-- Function to send in-game notifications using StarterGui:SetCore
local function sendNotification(title, text, duration, icon)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 5, -- Default duration is 5 seconds
        Icon = icon or "" -- Optional icon asset ID
    })
end

-- Counter for rejoin attempts, used in the kick message and notifications
local rejoinAttempts = 0

-- Main script loop: Continuously scan, rejoin, or stop if target found
while true do
    local foundAnyTargetEggInCurrentScan = false -- Flag to check if any target egg was found in this specific scan iteration
    local foundEggNameInCurrentScan = "" -- Stores the name of the first target egg found in this scan

    -- Reset all individual egg statuses to 'not found' at the beginning of each server scan
    for k in pairs(eggFoundStatus) do
        eggFoundStatus[k] = "❌"
    end

    -- Update main status label and send notification for scanning
    textLabel.Text = "Target Eggs: " .. table.concat(_G.TargetNames, ", ") .. "\nStatus: Scanning Server...\nPowered by dyumra"
    sendNotification("⚙️ System Notification", "Commencing server scan for target eggs.", 3, "rbxassetid://6034177218")

    -- Robust error handling for DataService:GetData()
    local data = DataSer:GetData()
    if data and data.SavedObjects then
        -- Iterate through all saved objects to find PetEggs
        for _, obj in pairs(data.SavedObjects) do
            if obj.ObjectType == "PetEgg" then
                -- Check if the egg has valid data and can be hatched
                if obj.Data.RandomPetData ~= nil and obj.Data.CanHatch then
                    -- Check if the egg's name matches any of our target names
                    for _, targetName in ipairs(_G.TargetNames) do
                        if obj.Data.RandomPetData.Name == targetName then
                            foundAnyTargetEggInCurrentScan = true -- Mark that at least one target was found
                            foundEggNameInCurrentScan = targetName -- Store the name of the found egg
                            eggFoundStatus[targetName] = "✅" -- Update specific egg status to 'found'
                            -- Do NOT break here, continue checking if other target eggs are also present in this server
                        end
                    end
                end
            end
        end
    else
        -- If DataService:GetData() fails, send an error notification and proceed to rejoin
        sendNotification("⚠️ Error", "Failed to retrieve game data. Rejoining server.", 3)
        -- The logic will fall through to the 'else' block below to initiate a rejoin
    end

    updateEggStatusDisplay() -- Update the individual egg status label after the scan is complete

    -- Determine action based on scan results
    if foundAnyTargetEggInCurrentScan then
        -- Target found: update status, send success notification, and stop the script
        textLabel.Text = "🔍 Target Eggs: " .. table.concat(_G.TargetNames, ", ") .. "\nStatus 🟢: Target Found: " .. foundEggNameInCurrentScan .. "\nPowered by dyumra"
        sendNotification("✅ System Notification", "Target identified: " .. foundEggNameInCurrentScan .. ". Process complete.", 10, "rbxassetid://6034177218")
        screenGui:Destroy() -- Clean up the GUI once the task is complete
        break -- Exit the main while loop, stopping the script
    else
        -- No target found: increment attempt counter, prepare kick message, and initiate rejoin
        rejoinAttempts = rejoinAttempts + 1
        local currentKickMessage = string.format(kickMessageBase, rejoinAttempts) -- Format the kick message with the current attempt number

        textLabel.Text = "🚫 Target Eggs: " .. table.concat(_G.TargetNames, ", ") .. "\nStatus: Rejoining Server (Attempt " .. rejoinAttempts .. ")...\nPowered by dyumra"
        sendNotification("⚙️ System Notification", "No designated target eggs detected. Initiating server rejoin sequence. Attempt: " .. rejoinAttempts, 5, "rbxassetid://6034177218")
        LocalPlayer:Kick(currentKickMessage) -- Kick the player from the current server

        task.wait(rejoinDelay) -- Wait for the specified rejoin delay

        -- Attempt to teleport the player back to the game (usually handled by Kick, but good for robustness)
        local success, err = pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
        if not success then
            warn("Teleport failed after kick: " .. err)
            sendNotification("⚠️ Error", "Teleport failed after kick. Retrying...", 3)
            task.wait(5) -- Longer wait if teleport explicitly failed
        end
    end

    task.wait(1) -- Small delay before the next iteration of the main loop
end
