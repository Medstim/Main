-- Load the official Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/source.lua'))()
local currentIcon = "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=512&h=512"

-- Define ReplicatedStorage first so the script knows what it is!
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- Create the Rayfield Window
local Window = Rayfield:CreateWindow({
    Name = "Slime RNG - AutoFarm",
    Icon = currentIcon,
    LoadingTitle = "Slime RNG Hub",
    LoadingSubtitle = "by @Mizz",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = "SlimeRNGAutomation", 
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

-- Create Main Navigation Tab
local MainTab = Window:CreateTab("Main", 4483362458)
local MiscTab = Window:CreateTab("Misc", 0)
local SettingsTab = Window:CreateTab("Settings", 0)

    -- Add automation header section
local AutoSection = MainTab:CreateSection("Automation")
local MiscSection = MiscTab:CreateSection("Misc")
local SettingsSection = SettingsTab:CreateSection("Settings")


-- FIX: Define SourceFolder safely so FeaturesFolder doesn't throw an error
local SourceFolder = ReplicatedStorage:WaitForChild("Source", 5) or ReplicatedStorage
local FeaturesFolder = SourceFolder:WaitForChild("Features", 5)

-- Safely require modules with fallback warnings
local RollServiceClient = FeaturesFolder and require(FeaturesFolder:WaitForChild("Roll"):WaitForChild("RollServiceClient"))
local UpgradeServiceClient = FeaturesFolder and require(FeaturesFolder:WaitForChild("Upgrades"):WaitForChild("UpgradeServiceClient"))
local InventoryServiceClient = FeaturesFolder and require(FeaturesFolder:WaitForChild("Inventory"):WaitForChild("InventoryServiceClient"))

-------------------------------------



-- ====================================
-- Local Functions 
-- =====================================

local function ExampleFunction()
    print("This is an example function.")
end


-- ====================================
-- Auto Roll Toggle
-- =====================================
MainTab:CreateToggle({
    Name = "Auto Roll",
    CurrentValue = false,
    Flag = "Toggle_AutoRoll",
    Callback = function(enabled)
        getgenv().AutoRoll = enabled

        if enabled then
            task.spawn(function()
                while getgenv().AutoRoll do
                    local success, err = pcall(function()
                        if RollServiceClient.RequestRoll then
                            RollServiceClient:RequestRoll()
                        elseif RollServiceClient.Roll then
                            RollServiceClient:Roll()
                        else
                            local Event = ReplicatedStorage.Packages._Index["leifstout_networker@0.3.1"]
                                .networker._remotes.RollService.RemoteFunction
                            Event:InvokeServer("requestRoll")
                        end
                    end)

                    if not success then
                        warn("Roll error:", err)
                    end

                    task.wait(1)
                end
            end)
        end
    end,
})

-- =====================================
-- Auto Equip Toggle
-- =====================================
MainTab:CreateToggle({
    Name = "Auto Equip",
    CurrentValue = false,
    Flag = "Toggle_AutoEquip",
    Callback = function(enabled)
        getgenv().AutoEquip = enabled

        if enabled then
            task.spawn(function()
                while getgenv().AutoEquip do
                    local success, err = pcall(function()
                        -- Locate the networker RemoteFunction safely
                        local Packages = game:GetService("ReplicatedStorage"):WaitForChild("Packages", 5)
                        local Index = Packages and Packages:WaitForChild("_Index", 5)
                        local NetworkerFolder = Index and Index:FindFirstChild("leifstout_networker@0.3.1")
                        
                        if NetworkerFolder then
                            local Event = NetworkerFolder.networker._remotes.InventoryService.RemoteFunction
                            local Result = Event:InvokeServer("requestEquipBest")
                        else
                            -- Fallback to module methods if the remote path isn't ready
                            if InventoryServiceClient.RequestEquipBest then
                                InventoryServiceClient:RequestEquipBest()
                            elseif InventoryServiceClient.EquipBest then
                                InventoryServiceClient:EquipBest()
                            end
                        end
                    end)

                    if not success then
                        warn("Equip error:", err)
                    end

                    task.wait(60) -- Keep the 60-second delay to avoid spamming the server
                end
            end)
        end
    end,
})

-- =====================================
-- Auto Rebirth Toggle
-- =====================================
MainTab:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Flag = "Toggle_AutoRebirth",
    Callback = function(enabled)
        getgenv().AutoRebirth = enabled

        if enabled then
            task.spawn(function()
                while getgenv().AutoRebirth do
                    local success, err = pcall(function()
                        local Event = ReplicatedStorage.Packages._Index["leifstout_networker@0.3.1"]
                            .networker._remotes.RebirthService.RemoteFunction
                        Event:InvokeServer("requestRebirth")
                    end)

                    if not success then
                        warn("Rebirth error:", err)
                    end

                    task.wait(380) -- Keep the 60-second delay to avoid spamming the server
                end
            end)
        end
    end,
})

-- =====================================
-- Services and Dependencies
-- =====================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local client = require(ReplicatedStorage.Packages.DataService).client

-- =====================================
-- Auto Buy zone / Auto Max zone tp Toggle
-- =====================================

MainTab:CreateToggle({
    Name = "Auto buy Zone",
    CurrentValue = false,
    Flag = "Toggle_AutoPurchaseZone",
    Callback = function(enabled)
        getgenv().AutoPurchaseZone = enabled

        if enabled then
            task.spawn(function()
                while getgenv().AutoPurchaseZone do
                    -- 1. Track what your zone is BEFORE trying to buy
                    local currentZone = math.max(client:get("maxZone") or 1, 1)
                    local purchaseSuccess = false

                    -- 2. Try to purchase the zone
                    pcall(function()
                        local Event = ReplicatedStorage.Packages._Index["leifstout_networker@0.3.1"]
                            .networker._remotes.ZonesService.RemoteFunction
                        
                        local result = Event:InvokeServer("requestPurchaseZone")
                        if result == true then
                            purchaseSuccess = true
                        end
                    end)

                    -- 3. STRICTLY only teleport once if the purchase went through
                    if purchaseSuccess then
                        task.wait(1) -- Brief pause for server synchronization

                        pcall(function()
                            local newZone = currentZone + 1

                            local Event = ReplicatedStorage.Packages._Index["leifstout_networker@0.3.1"]
                                .networker._remotes.ZonesService.RemoteFunction
                            
                            -- This fires exactly once per successful purchase
                            Event:InvokeServer("requestTeleportZone", newZone)
                        end)
                    end

                    -- 4. Cooldown before the loop checks for the next purchase opportunity
                    task.wait(12) 
                end
            end)
        end
    end,
})


-- =====================================
-- Auto Spin (Claim & Consume)
-- =====================================

local SpinsTable = {
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
}

MiscTab:CreateToggle({
    Name = "Auto Spin",
    CurrentValue = false,
    Flag = "Toggle_AutoSpin",
    Callback = function(enabled)
        getgenv().AutoSpin = enabled

        if enabled then
            task.spawn(function()
                -- Flat line path to prevent executor syntax parsing issues
                local LoginService = game:GetService("ReplicatedStorage"):WaitForChild("Packages")._Index["leifstout_networker@0.3.1"].networker._remotes.LoginStreakServiceServer.RemoteFunction
                
                while getgenv().AutoSpin do
                    for _, spinId in ipairs(SpinsTable) do
                        if not getgenv().AutoSpin then break end
                        
                        -- 1. Try to CLAIM the spin (expects a number based on your log)
                        pcall(function()
                            local numericId = tonumber(spinId) or 1
                            LoginService:InvokeServer("tryClaimingSpin", numericId)
                        end)
                        
                        task.wait(0.5) -- Small delay between actions
                        
                        -- 2. Try to CONSUME the spin (expects a string based on your log)
                        pcall(function()
                            LoginService:InvokeServer("tryConsumingSpin", tostring(spinId))
                        end)
                        
                        task.wait(0.5) -- Small delay before trying the next spin ID
                    end
                    
                    -- Cooldown before checking/running through all spin IDs again
                    task.wait(180) 
                end
            end)
        end
    end,
})

-- =====================================
-- Auto Claim All Rewards
-- =====================================
local Index = {
    "basic",
    "big",
    "huge",
    "shiny",
    "inverted",
}

MiscTab:CreateToggle({
    Name = "Auto Claim Index",
    CurrentValue = false,
    Flag = "Toggle_AutoClaimRewards",
    Callback = function(enabled)
        getgenv().AutoClaimRewards = enabled

        if enabled then
            task.spawn(function()
                while getgenv().AutoClaimRewards do
                    local success, err = pcall(function()
                        local Event = ReplicatedStorage.Packages._Index["leifstout_networker@0.3.1"]
                            .networker._remotes.IndexService.RemoteFunction
                        Event:InvokeServer("requestClaimReward", "" .. Index[math.random(1, #Index)] .. "")
                    end)

                    if not success then
                        warn("Claim error:", err)
                    end

                    task.wait(0.5) -- Keep the 1-minute delay to avoid spamming the server
                end
            end)
        end
    end,
})

-- =====================================
-- Auto Collect Items
-- =====================================
MiscTab:CreateToggle({
    Name = "Auto Collect items",
    CurrentValue = false,
    Flag = "Toggle_AutoCollect",
    Callback = function(enabled)
        getgenv().AutoCollect = enabled

        if enabled then
            task.spawn(function()
                -- Flat line path to prevent executor syntax parsing issues
                local LootService = game:GetService("ReplicatedStorage"):WaitForChild("Packages")._Index["leifstout_networker@0.3.1"].networker._remotes.LootService.RemoteFunction
                
                while getgenv().AutoCollect do
                    local lootFolder = workspace:FindFirstChild("Loot")
                    
                    if lootFolder then
                        for _, v in pairs(lootFolder:GetChildren()) do
                            if not getgenv().AutoCollect then break end
                            
                            pcall(function()
                                LootService:InvokeServer("requestCollect", v.Name)
                            end)
                            
                            task.wait()
                        end
                    end
                    
                    task.wait(10)
                end
            end)
        end
    end, -- Make sure this comma is here if there are more UI elements below it!
})

-- =====================================
-- Auto use loot Toggle
-- =====================================
local Boosts = {
    "luck",
    "currency",
    "rollSpeed",
    "ultraLuck",
}

local Dices = {
    "bigDice",
    "invertedDice",
    "shinyDice",
}

MiscTab:CreateToggle({
    Name = "Auto Use Loot",
    CurrentValue = false,
    Flag = "Toggle_AutoUseLoot",
    Callback = function(enabled)
        getgenv().AutoUseLoot = enabled

        if enabled then
            task.spawn(function()
                -- Flat line paths to completely prevent executor syntax parsing issues
                local BoostEvent = game:GetService("ReplicatedStorage"):WaitForChild("Packages")._Index["leifstout_networker@0.3.1"].networker._remotes.BoostService.RemoteFunction
                local DiceEvent = game:GetService("ReplicatedStorage"):WaitForChild("Packages")._Index["leifstout_networker@0.3.1"].networker._remotes.InventoryService.RemoteFunction

                while getgenv().AutoUseLoot do
                    -- 1. Use a random Boost
                    local successBoost, errBoost = pcall(function()
                        local randomBoost = tostring(Boosts[math.random(1, #Boosts)])
                        BoostEvent:InvokeServer("requestUseBoost", randomBoost)
                    end)

                    if not successBoost then
                        warn("Boost Error:", errBoost)
                    end

                    task.wait(0.2) -- Tiny gap between distinct network actions
                    if not getgenv().AutoUseLoot then break end

                    -- 2. Use a random Dice
                    local successDice, errDice = pcall(function()
                        local randomDice = tostring(Dices[math.random(1, #Dices)])
                        DiceEvent:InvokeServer("requestUseItem", randomDice)
                    end)

                    if not successDice then
                        warn("Dice Error:", errDice)
                    end

                    task.wait(1) -- Delay before looping the process again
                end
            end)
        end
    end,
})























-- =====================================
-- settings Disable all 
-- =====================================
local storedStates = {} -- Temporary table to remember your settings

SettingsTab:CreateToggle({
    Name = "Disable All Automation",
    CurrentValue = false,
    Flag = "Toggle_DisableAllAutomation",
    Callback = function(enabled)
        getgenv().DisableAllAutomation = enabled
        
        -- The list of all your automation variables
        local automationFeatures = {
            "AutoRoll", "AutoEquip", "AutoRebirth", "AutoPurchaseZone", 
            "AutoSpin", "AutoClaimRewards", "AutoCollectItems", "AutoUseBoosts"
        }

        if enabled then
            -- 1. SAVE current states, then TURN OFF everything
            for _, feature in ipairs(automationFeatures) do
                storedStates[feature] = getgenv()[feature] -- Save the current true/false value
                getgenv()[feature] = false                 -- Turn it off
            end
        else
            -- 2. RESTORE the previous states when untoggled
            for _, feature in ipairs(automationFeatures) do
                -- If we have a saved state, restore it. Otherwise, default to false.
                if storedStates[feature] ~= nil then
                    getgenv()[feature] = storedStates[feature]
                end
            end
            -- Clear the storage table until the next time it's toggled on
            storedStates = {}
        end
    end,
})

-- =====================================
-- Settings WalkSpeed Edit
-- =====================================
getgenv().TargetWalkSpeed = 16 -- 16 is default speed


task.spawn(function()
    while true do
        task.wait(0.1) 
        pcall(function()
            local player = game:GetService("Players").LocalPlayer
            if player and player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.WalkSpeed ~= getgenv().TargetWalkSpeed then
                    humanoid.WalkSpeed = getgenv().TargetWalkSpeed
                end
            end
        end)
    end
end)


-- =====================================
-- Settings Anti-AFK 
-- =====================================

getgenv().antiafk = true

-- Listens for when your avatar goes idle and clicks the camera to prevent disconnecting
plr.Idled:Connect(function()
    if not getgenv().antiafk then return end
    local virtualUser = game:GetService("VirtualUser")
    virtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(0.8)
    virtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)


-- 1. Disable 3D Rendering (Perfect for overnight farming to save PC/Mobile energy)
SettingsTab:CreateToggle({
    Name = "Disable 3D Rendering",
    CurrentValue = false,
    Flag = "Toggle_Disable3DRendering", 
    Callback = function(enabled)
        -- 'not enabled' because when the toggle is true (on), we want rendering to be false (off)
        game:GetService("RunService"):Set3dRenderingEnabled(not enabled)
    end,
})


-- 2. Anti AFK Toggle
SettingsTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true, -- Matches our global default state
    Flag = "Toggle_AntiAFK", 
    Callback = function(enabled)
        getgenv().antiafk = enabled
    end,
})

SettingsTab:CreateSlider({
    Name = "Player WalkSpeed",
    Info = "Increases your movement speed, Default is 16.",
    Range = {16, 150}, -- 16 (Normal) 
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 16,
    Flag = "Slider_WalkSpeed",
    Callback = function(Value)
        getgenv().TargetWalkSpeed = Value
    end,
})

Rayfield:Notify({
   Title = "Slime RNG",
   Content = "Loaded | by @Mizz",
   Duration = 7.5,
   Image = currentIcon,
})