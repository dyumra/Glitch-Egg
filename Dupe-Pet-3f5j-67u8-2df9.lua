-- Global settings for the script
_G.TargetEggs = { -- Use a table of tables to store name and found status
    {name = "Queen Bee", found = false},
    {name = "Dragonfly", found = false}
}

-- Essential Roblox services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

-- Script configuration
local rejoinDelay = 1 -- Delay before attempting to server hop (seconds)
local kickMessage = "System Notification: No designated target eggs were detected in this server. Initiating automatic server relocation."

-- Attempt to get DataService, add a check for robustness
local DataServiceModule = nil
local success, errorMessage = pcall(function()
    DataServiceModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataService"))
end)

if not success or not DataServiceModule then
    sendNotification("🚫 Script Error", "Failed to load DataService. Script may not function correctly. Error: " .. (errorMessage or "Unknown"), 15)
    print("Error: Could not load DataService. Script functionality may be impaired.")
    -- You might want to break or disable features here if DataService is crucial
end


-- Function to send in-game notifications using SetCore
local function sendNotification(title, text, duration, icon)
    -- Wrap in pcall to prevent script breaking if SetCore is blocked or fails
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5,
            Icon = icon or ""
        })
    end)
end

-- Function to update the GUI text displaying current targets in the main frame
local function updateTargetListDisplay()
    local currentTargetsNames = {}
    for _, eggData in ipairs(_G.TargetEggs) do
        table.insert(currentTargetsNames, eggData.name)
    end
    mainStatusLabel.Text = "Target Eggs: " .. table.concat(currentTargetsNames, ", ") .. "\nStatus: 🌐 Initializing...\nPowered by dyumra"
end

-- Function to update the right-side status display
local function updateRightStatusDisplay()
    local statusText = ""
    for _, eggData in ipairs(_G.TargetEggs) do
        statusText = statusText .. eggData.name .. ": " .. (eggData.found and "✅" or "❌") .. "\n"
    end
    rightStatusLabel.Text = statusText
end

-- Function to smoothly transition RGB colors for TextLabels
local function smoothRGBTransition(label)
    local hue = 0
    while task.wait(0.05) do -- Adjust speed of color change (lower for faster)
        hue = (hue + 0.01) % 1 -- Cycle hue from 0 to 1
        label.TextColor3 = Color3.fromHSV(hue, 1, 1) -- Set color using HSV
    end
end

--- GUI Creation ---

-- ScreenGui for Toggle Button (always visible)
local screenGuiToggle = Instance.new("ScreenGui")
screenGuiToggle.Name = "EggHunterToggleGUI"
screenGuiToggle.ResetOnSpawn = false
screenGuiToggle.Parent = StarterGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 80, 0, 30)
toggleButton.Position = UDim2.new(0.01, 0, 0.01, 0) -- Top-left corner, slightly above main GUI
toggleButton.Text = "Toggle UI"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.BackgroundTransparency = 0.2
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14
toggleButton.BorderSizePixel = 0
toggleButton.Parent = screenGuiToggle

local toggleButtonCorner = Instance.new("UICorner")
toggleButtonCorner.CornerRadius = UDim.new(0, 5)
toggleButtonCorner.Parent = toggleButton

-- ScreenGui for Main GUI Frame (Left Side, Draggable)
local screenGuiMain = Instance.new("ScreenGui")
screenGuiMain.Name = "EggHunterMainGUI"
screenGuiMain.ResetOnSpawn = false
screenGuiMain.Parent = StarterGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 220) -- Adjusted size to fit new elements
mainFrame.Position = UDim2.new(0.01, 0, 0.05, 0) -- Top-left corner
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Dark black
mainFrame.BackgroundTransparency = 0.7 -- Slightly transparent
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGuiMain -- Parented to its own ScreenGui

local mainCorner = Instance.new("UICorner") -- Create rounded corners for the main frame
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainUiListLayout = Instance.new("UIListLayout") -- Layout to stack elements vertically
mainUiListLayout.Parent = mainFrame
mainUiListLayout.FillDirection = Enum.FillDirection.Vertical
mainUiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
mainUiListLayout.Padding = UDim.new(0, 5) -- Add some padding between elements
mainUiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Main Status Text Label (RGB Text)
local mainStatusLabel = Instance.new("TextLabel")
mainStatusLabel.Name = "MainStatusLabel"
mainStatusLabel.Size = UDim2.new(1, -10, 0, 80) -- Full width of frame minus padding, fixed height
mainStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
mainStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
mainStatusLabel.TextColor3 = Color3.fromRGB(240, 240, 240) -- Initial color
mainStatusLabel.Font = Enum.Font.SourceSansBold
mainStatusLabel.TextSize = 16 -- Slightly smaller to fit more text
mainStatusLabel.TextWrapped = true
mainStatusLabel.BackgroundTransparency = 1 -- Make background transparent to show frame's background
mainStatusLabel.LayoutOrder = 1 -- Order in UIListLayout
mainStatusLabel.Parent = mainFrame
spawn(function() smoothRGBTransition(mainStatusLabel) end) -- Start RGB transition

-- Textbox for adding new targets
local newTargetTextBox = Instance.new("TextBox")
newTargetTextBox.Name = "NewTargetInput"
newTargetTextBox.PlaceholderText = "Add new egg name..."
newTargetTextBox.Text = ""
newTargetTextBox.Size = UDim2.new(1, -10, 0, 30) -- Full width of frame minus padding, fixed height
newTargetTextBox.TextXAlignment = Enum.TextXAlignment.Left
newTargetTextBox.TextColor3 = Color3.fromRGB(240, 240, 240)
newTargetTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Darker background for input
newTargetTextBox.BackgroundTransparency = 0.5
newTargetTextBox.Font = Enum.Font.SourceSans
newTargetTextBox.TextSize = 16
newTargetTextBox.ClearTextOnFocus = true
newTargetTextBox.LayoutOrder = 2
newTargetTextBox.Parent = mainFrame

local textboxCorner = Instance.new("UICorner")
textboxCorner.CornerRadius = UDim.new(0, 5) -- Slightly smaller corner radius for textbox
textboxCorner.Parent = newTargetTextBox

-- Button to add new targets
local addButton = Instance.new("TextButton")
addButton.Name = "AddTargetButton"
addButton.Size = UDim2.new(1, -10, 0, 30) -- Full width, fixed height
addButton.Text = "Add Target"
addButton.TextColor3 = Color3.fromRGB(255, 255, 255)
addButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180) -- SteelBlue, a nice accent color
addButton.BackgroundTransparency = 0.2
addButton.Font = Enum.Font.SourceSansBold
addButton.TextSize = 18
addButton.LayoutOrder = 3
addButton.Parent = mainFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 5) -- Rounded corners for button
buttonCorner.Parent = addButton

-- ServerHop Button
local serverHopButton = Instance.new("TextButton")
serverHopButton.Name = "ServerHopButton"
serverHopButton.Size = UDim2.new(1, -10, 0, 30) -- Full width, fixed height
serverHopButton.Text = "Server Hop"
serverHopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
serverHopButton.BackgroundColor3 = Color3.fromRGB(200, 100, 50) -- Orange/Brown accent
serverHopButton.BackgroundTransparency = 0.2
serverHopButton.Font = Enum.Font.SourceSansBold
serverHopButton.TextSize = 18
serverHopButton.LayoutOrder = 4 -- Placed after add button
serverHopButton.Parent = mainFrame

local hopButtonCorner = Instance.new("UICorner")
hopButtonCorner.CornerRadius = UDim.new(0, 5)
hopButtonCorner.Parent = serverHopButton

-- Beta Warning Label
local betaWarningLabel = Instance.new("TextLabel")
betaWarningLabel.Name = "BetaWarningLabel"
betaWarningLabel.Size = UDim2.new(1, -10, 0, 30) -- Full width, fixed height
betaWarningLabel.Text = "Warning: This script is currently in beta and may not be fully stable."
betaWarningLabel.TextXAlignment = Enum.TextXAlignment.Center
betaWarningLabel.TextYAlignment = Enum.TextYAlignment.Center
betaWarningLabel.TextColor3 = Color3.fromRGB(255, 200, 0) -- Yellow warning color
betaWarningLabel.Font = Enum.Font.SourceSans
betaWarningLabel.TextSize = 12
betaWarningLabel.TextWrapped = true
betaWarningLabel.BackgroundTransparency = 1
betaWarningLabel.LayoutOrder = 5
betaWarningLabel.Parent = mainFrame

-- --- Draggable GUI Logic ---
local dragging = false
local dragStart = Vector2.new(0, 0)
local startPos = UDim2.new(0, 0, 0, 0)

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Handled = true -- Prevent other UI elements from reacting
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end
end)


-- --- Right Side Status GUI ---
local screenGuiRight = Instance.new("ScreenGui")
screenGuiRight.Name = "EggHunterStatusGUI"
screenGuiRight.ResetOnSpawn = false
screenGuiRight.Parent = StarterGui

local rightFrame = Instance.new("Frame")
rightFrame.Name = "RightStatusFrame"
rightFrame.Size = UDim2.new(0, 180, 0, 120) -- Size adjusted based on content
rightFrame.Position = UDim2.new(1, -190, 0.05, 0) -- Top-right corner
rightFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
rightFrame.BackgroundTransparency = 0.7
rightFrame.BorderSizePixel = 0
rightFrame.Parent = screenGuiRight

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 10)
rightCorner.Parent = rightFrame

local rightStatusLabel = Instance.new("TextLabel")
rightStatusLabel.Name = "IndividualStatusLabel"
rightStatusLabel.Size = UDim2.new(1, -10, 1, -10) -- Fill parent frame with padding
rightStatusLabel.Position = UDim2.new(0, 5, 0, 5) -- Padding
rightStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
rightStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
rightStatusLabel.TextColor3 = Color3.fromRGB(240, 240, 240) -- Initial color
rightStatusLabel.Font = Enum.Font.SourceSansBold
rightStatusLabel.TextSize = 16
rightStatusLabel.TextWrapped = true
rightStatusLabel.BackgroundTransparency = 1
rightStatusLabel.Parent = rightFrame
spawn(function() smoothRGBTransition(rightStatusLabel) end) -- Start RGB transition


-- --- Event Connections ---

-- Toggle button click event
toggleButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

-- Connect the add button click event
addButton.MouseButton1Click:Connect(function()
    local newEggName = newTargetTextBox.Text:strip() -- Get text and remove leading/trailing spaces
    if newEggName == "" then
        sendNotification("🚫 Input Error", "Please enter a valid egg name.", 3)
        return
    end

    local alreadyExists = false
    for _, eggData in ipairs(_G.TargetEggs) do
        if eggData.name == newEggName then
            alreadyExists = true
            break
        end
    end

    if alreadyExists then
        sendNotification("🚫 Duplicate Target", "'" .. newEggName .. "' is already in the list.", 3)
    else
        table.insert(_G.TargetEggs, {name = newEggName, found = false})
        updateTargetListDisplay() -- Update the main GUI
        updateRightStatusDisplay() -- Update the right-side GUI
        newTargetTextBox.Text = "" -- Clear the textbox
        sendNotification("🌐 Target Added", "Added '" .. newEggName .. "' to target list.", 3)
    end
end)

-- Connect the ServerHop button click event
serverHopButton.MouseButton1Click:Connect(function()
    sendNotification("🌐 System Notification", "Initiating manual server hop...", 3)
    pcall(function() -- Wrap in pcall for teleport service in case it's blocked
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end)


-- --- Initial GUI Updates ---
updateTargetListDisplay()
updateRightStatusDisplay()

-- --- Main Hunting Logic ---
-- Only proceed if DataServiceModule was loaded successfully
if DataServiceModule then
    while true do
        local foundAnyTargetEggInCurrentServer = false
        local foundEggName = ""
        
        -- Reset found status for all eggs at the start of each server scan
        for i, eggData in ipairs(_G.TargetEggs) do
            _G.TargetEggs[i].found = false
        end
        updateRightStatusDisplay() -- Update right GUI to show all ❌
    
        mainStatusLabel.Text = "Target Eggs: " .. table.concat(
            (function() local names = {} for _, ed in ipairs(_G.TargetEggs) do table.insert(names, ed.name) end return names end)(), ", ") .. "\nStatus: 🌐 Scanning Server...\nPowered by dyumra"
        sendNotification("🌐 System Notification", "Commencing server scan for target eggs.", 3, "rbxassetid://6034177218")
    
        -- Wrap DataService access in pcall for robustness
        local savedObjects = nil
        local successScan, scanError = pcall(function()
            savedObjects = DataServiceModule:GetData().SavedObjects
        end)

        if not successScan then
            sendNotification("🚫 Scan Error", "Could not read game data. Retrying... Error: " .. (scanError or "Unknown"), 5)
            print("Scan Error: " .. (scanError or "Unknown"))
            -- Continue loop to retry or hop
        elseif savedObjects then
            for _, obj in pairs(savedObjects) do
                if obj.ObjectType == "PetEgg" then
                    if obj.Data.RandomPetData ~= nil and obj.Data.CanHatch then
                        for i, eggData in ipairs(_G.TargetEggs) do
                            if obj.Data.RandomPetData.Name == eggData.name then
                                _G.TargetEggs[i].found = true
                                foundAnyTargetEggInCurrentServer = true
                                foundEggName = eggData.name
                            end
                        end
                    end
                end
            end
        end
        updateRightStatusDisplay() -- Update right GUI once after scan is complete
    
        if foundAnyTargetEggInCurrentServer then
            mainStatusLabel.Text = "Target Eggs: " .. table.concat(
                (function() local names = {} for _, ed in ipairs(_G.TargetEggs) do table.insert(names, ed.name) end return names end)(), ", ") .. "\nStatus: 🎉 Target Found! " .. foundEggName .. "\nPowered by dyumra"
            sendNotification("🎉 System Notification", "One or more target eggs identified! (" .. foundEggName .. ").", 10, "rbxassetid://6034177218")
            
            task.wait(10) -- Wait a bit if target found before re-scanning
        else
            mainStatusLabel.Text = "Target Eggs: " .. table.concat(
                (function() local names = {} for _, ed in ipairs(_G.TargetEggs) do table.insert(names, ed.name) end return names end)(), ", ") .. "\nStatus: 🚫 No Target Found. Hopping...\nPowered by dyumra"
            sendNotification("🚫 System Notification", "No designated target eggs detected. Initiating automatic server relocation.", 5, "rbxassetid://6034177218")
            
            pcall(function() -- Wrap in pcall for teleport service in case it's blocked
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
            
            task.wait(rejoinDelay) 
        end
        
        task.wait(1) -- Short delay between scan attempts (if staying in server)
    end
else
    -- If DataServiceModule failed to load, display an error message and stop the main loop
    mainStatusLabel.Text = "Target Eggs: N/A\nStatus: ❌ Error: DataService Load Failed!\nPowered by dyumra"
    sendNotification("🚫 Script Fatal Error", "DataService could not be loaded. Please ensure the game's API structure is compatible or contact support.", 30)
end
