_G.TargetNames = {"Dragonfly", "Queen Bee"} -- Add all the Pet Egg names you want to find here. E.g., {"Dragonfly", "Queen Bee", "Phoenix Egg"}



local DataSer = require(game:GetService("ReplicatedStorage").Modules.DataService)

local TeleportService = game:GetService("TeleportService")

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local StarterGui = game:GetService("StarterGui")



local rejoinDelay = 1 -- Delay before attempting to rejoin (seconds)

local kickMessage = "🌐 System Notification: No designated target eggs were detected in this server. Initiating automatic server relocation. \n 🟢 QN: Server-Finding... attempt(s)" -- Formal kick message



-- Create the GUI

local screenGui = Instance.new("ScreenGui")

screenGui.Name = "EggHunterGUI"

screenGui.ResetOnSpawn = false



local textLabel = Instance.new("TextLabel")

textLabel.Name = "StatusLabel"

textLabel.Size = UDim2.new(0, 250, 0, 100) -- Adjust size as needed

textLabel.Position = UDim2.new(0.01, 0, 0.05, 0) -- Top-left corner

textLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Dark black

textLabel.BackgroundTransparency = 0.7 -- Slightly transparent

textLabel.TextColor3 = Color3.fromRGB(240, 240, 240) -- Light gray text

textLabel.Font = Enum.Font.SourceSansBold -- Bold font

textLabel.TextSize = 18

textLabel.TextWrapped = true

textLabel.TextXAlignment = Enum.TextXAlignment.Left

textLabel.TextYAlignment = Enum.TextYAlignment.Top

textLabel.Text = "Target Eggs: " .. table.concat(_G.TargetNames, ", ") .. "\nStatus: Initializing\nPowered by dyumra" -- Initial text

textLabel.BorderSizePixel = 0 -- Remove border

textLabel.ClipsDescendants = true -- Enable rounded corners

textLabel.Parent = screenGui



local corner = Instance.new("UICorner") -- Create rounded corners

corner.CornerRadius = UDim.new(0, 10) -- Set corner radius

corner.Parent = textLabel



screenGui.Parent = StarterGui



-- Function to send in-game notifications

local function sendNotification(title, text, duration, icon)

    StarterGui:SetCore("SendNotification", {

        Title = title,

        Text = text,

        Duration = duration or 5,

        Icon = icon or ""

    })

end



while true do

    local foundAnyTargetEgg = false

    local foundEggName = ""

    

    textLabel.Text = "Target Eggs: " .. table.concat(_G.TargetNames, ", ") .. "\nStatus: Scanning Server...\nPowered by dyumra"

    sendNotification("System Notification", "Commencing server scan for target eggs.", 3, "rbxassetid://6034177218") -- Initial scan notification



    for _, obj in pairs(DataSer:GetData().SavedObjects) do

        if obj.ObjectType == "PetEgg" then

            if obj.Data.RandomPetData ~= nil and obj.Data.CanHatch then

                -- Check if the egg's name is in our list of target names

                for _, targetName in ipairs(_G.TargetNames) do

                    if obj.Data.RandomPetData.Name == targetName then

                        foundAnyTargetEgg = true

                        foundEggName = targetName

                        break -- Found one, no need to check other targets or eggs

                    end

                end

                if foundAnyTargetEgg then

                    break -- Stop searching through saved objects

                end

            end

        end

    end



    if foundAnyTargetEgg then

        textLabel.Text = "Target Eggs: " .. table.concat(_G.TargetNames, ", ") .. "\nStatus: Target Found: " .. foundEggName .. "\nPowered by dyumra"

        sendNotification("System Notification", "Target identified: " .. foundEggName .. ". Process complete.", 10, "rbxassetid://6034177218")

        break -- Stop the script as a target was found

    else

        textLabel.Text = "Target Eggs: " .. table.concat(_G.TargetNames, ", ") .. "\nStatus: Rejoining Server...\nPowered by dyumra"

        sendNotification("System Notification", "No designated target eggs detected. Initiating server rejoin sequence.", 5, "rbxassetid://6034177218")

        LocalPlayer:Kick(kickMessage)

        

        task.wait(rejoinDelay) 

        

        TeleportService:Teleport(game.PlaceId, LocalPlayer)

    end

    

    task.wait(1)

end
