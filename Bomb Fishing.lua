
-- Load the official Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local currentIcon = "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=512&h=512"
local getGameName = game:GetService("MarketplaceService"):GetProductInfo(game.GameId).Name

-- Define Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local plr = game:GetService("Players").LocalPlayer



-- Function Time Settings
local AutoFarmDelay = 2.5
local AutoFishDelay = 0.3
local AutoSellDelay = 25


-- Create the Rayfield Window
local Window = Rayfield:CreateWindow({
    Theme = "DarkBlue",
    Icon = currentIcon,
    Name = "⭐ " .. getGameName .. " ⭐",
    LoadingTitle = "Bomb Fishing Autofarm 1.0 ",
    LoadingSubtitle = "by @Mizz",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false
})


-- Create Main Navigation Tab
local MainTab = Window:CreateTab("Main", nil)
local MiscTab = Window:CreateTab("Misc", nil)
local SettingsTab = Window:CreateTab("Settings", nil)

    -- Add automation header section
local AutoSection = MainTab:CreateSection("AutoFarm")
local MiscSection = MiscTab:CreateSection("Misc")
local SettingsSection = SettingsTab:CreateSection("Settings")


local BaseS = ReplicatedStorage.src.Modules.KnitClient.Services.BaseService.RE.SendTagData
local StartID = 0

---Get base / rep id------

local KnitClient = require(ReplicatedStorage.src.Modules.KnitClient)
local BaseController = KnitClient.GetController("BaseController")

-- Absolute live scanner for the network ID
local function GetCurrentReplicaId()
    -- Step 1: Try getting it from the BaseController classes
    for _, baseClass in pairs(BaseController.classes) do
        if baseClass.IsMine == true then
            if baseClass.Replica and baseClass.Replica.Id then
                return tonumber(baseClass.Replica.Id)
            end
        end
    end
    
    -- Step 2: Emergency Fallback - Scrape the Replica module cache directly
    local success, ReplicaClient = pcall(function() 
        return require(ReplicatedStorage.src.Modules.ReplicaClient) 
    end)
    
    if success and ReplicaClient and ReplicaClient.Test then
        local internalData = ReplicaClient.Test()
        if internalData and internalData.Replicas then
            for id, replicaObj in pairs(internalData.Replicas) do
                -- Look for the replica tracking your Base tokens
                if replicaObj.Token == "Base" and replicaObj.Data and replicaObj.Data.UniqueId then
                    return tonumber(id)
                end
            end
        end
    end
    
    return nil
end

-- 2. Environment Interceptor (workspace.Bases["4"])
local workspaceProxy = {
    Bases = setmetatable({}, {
        __index = function(_, key)
            if key == "0" then
                for _, baseClass in pairs(BaseController.classes) do
                    if baseClass.IsMine == true and baseClass.UniqueId then
                        return game.Workspace.Bases:FindFirstChild(tostring(baseClass.UniqueId))
                    end
                end
            end
            return game.Workspace.Bases:FindFirstChild(key)
        end
    })
}
local workspace = setmetatable(workspaceProxy, {
    __index = function(_, key) return game.Workspace[key] end
})

-- 3. Live Force-Interceptor for the Remote
local rawStartEvent = ReplicatedStorage.src.Modules.KnitClient.Services.BombService.RE.Start
local startEventProxy = {
    FireServer = function(self, value, ...)
        local liveId = GetCurrentReplicaId()
        
        if liveId ~= nil then
            -- We override whatever value (even 0) was provided with the verified ID
            return rawStartEvent:FireServer(liveId, ...)
        end
        
        warn("[-] Failed to find live replica ID anywhere. Sending original value.")
        return rawStartEvent:FireServer(value, ...)
    end
}
local startEvent = setmetatable(startEventProxy, {
    __index = function(_, key) return rawStartEvent[key] end
})




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

--------------


-- ====================================
-- Local Functions 
-- =====================================

local function UpgradeAquarium()
    local Event = BaseS
    Event:FireServer(
        "Aquarium",
        workspace.Bases["0"].Floor1.Interactables.Aquarium,
        "upgradeAquarium"
    )                  
end

local function UpgradeCage()
    local Event = BaseS
    Event:FireServer(
        "CageBridge",
        workspace.Bases["0"].Floor1.Interactables.CageBridge,
        "upgradeCage"
    )
end

local function CollectCash()
    local Event = BaseS
    Event:FireServer(
        "Collect",
        workspace.Bases["0"].Floor1.Interactables.Collect,
        "collectCash"
    )
end

local function Rebirth()
    local Event = ReplicatedStorage.src.Modules.KnitClient.Services.RebirthService.RE.Rebirth
    Event:FireServer()
end

local function ClaimPlaytimeRewards()
local Gifts1 ={
    1,
    2,
    3,
}

local Gifts2 ={
    4,
    5,
    6,
    7
}

    local Event = ReplicatedStorage.src.Modules.KnitClient.Services.PlaytimeRewardService.RE.Claim
    local randomGift1 = Gifts1[math.random(1, #Gifts1)]
    local randomGift2 = Gifts2[math.random(1, #Gifts2)]
    Event:FireServer(
        randomGift1
    )

    task.wait()

    Event:FireServer(
        randomGift2 
    )
end

local function BuyBombs()
    for i,v in pairs(ReplicatedStorage.Assets.Bombs:GetChildren()) do 
        local Event = ReplicatedStorage.src.Modules.KnitClient.Services.BombShopService.RE.Purchase
        Event:FireServer(
            v.Name
        )
    end
end

local function Sellinv()   
    local Event = ReplicatedStorage.src.Modules.KnitClient.Services.SellService.RE.SellInventory
    Event:FireServer()
end

local function EquipBestFish()
    local Event = BaseS
    Event:FireServer(
        "Aquarium",
        workspace.Bases["0"].Floor1.Interactables.Aquarium,
        "equipBest"
    )
end

local function ClaimFish()
    local Event = BaseS
    Event:FireServer(
        "CageBridge",
        workspace.Bases["0"].Floor1.Interactables.CageBridge,
        "claimFishes"
    )
    task.wait(0.5)
end

local function StartFishing()
    -- 1. Fire the start remote
    local startEvent = ReplicatedStorage.src.Modules.KnitClient.Services.BombService.RE.Start
    startEvent:FireServer(StartID)
    
    -- 2. Wait 0.3 second
    task.wait(0.4)
    
    -- 3. Fire the throw remote
    local throwEvent = ReplicatedStorage.src.Modules.KnitClient.Services.BombService.RE.Throw
    throwEvent:FireServer(1)

    task.wait()
    local SkipEvent = ReplicatedStorage.src.Modules.KnitClient.Services.BombService.RE.Skip
    SkipEvent:FireServer()

end

local function BuyPotions()
    -- 1. Define the list of potion IDs
    local pots = {1, 2, 3}
    
    -- 2. Define the exact path to the remote event
    local Event = ReplicatedStorage.src.Modules.KnitClient.Services.MerchantService.RE.Purchase

    -- 3. Loop through the list and buy each one
    for _, potionId in pairs(pots) do
        Event:FireServer(potionId)
        task.wait(0.5) -- Small delay to prevent network lag
    end
end

local function BuyBWeather()

    -- 2. Define the exact path to the remote event
    local Event = ReplicatedStorage.src.Modules.KnitClient.Services.EventService.RE.Purchase
    Event:FireServer("Candy")
        task.wait(1) -- Small delay to prevent network lag
    end
-- ====================================
-- Main Tab Toggles
-- =====================================

MainTab:CreateToggle({
    Name = "⋆ Auto Farm",
    CurrentValue = false,
    Flag = "Toggle_AutoFarm", 
    Callback = function(enabled)
        getgenv().AutoFarm = enabled
        
        if enabled then  
            task.spawn(function()
                while getgenv().AutoFarm do 
                    task.wait(1)
                    if not getgenv().AutoFarm then break end
                    ClaimFish()                  
                    
                    task.wait(1.5)
                    if not getgenv().AutoFarm then break end
                    CollectCash()

                    task.wait(3)
                    if not getgenv().AutoFarm then break end
                    UpgradeAquarium()
                    
                    task.wait(1)
                    if not getgenv().AutoFarm then break end
                    UpgradeCage()

                    task.wait(11)
                    if not getgenv().AutoFarm then break end
                    BuyBombs()

                    task.wait(16)
                    if not getgenv().AutoFarm then break end
                    Rebirth()

                    task.wait(AutoFarmDelay)              
                end 
            end)
        end
    end,
})

MainTab:CreateToggle({
    Name = "⋆ Auto Fish",
    CurrentValue = false,
    Flag = "Toggle_AutoFish", 
    Callback = function(enabled)
        getgenv().AutoFish = enabled
        
        if enabled then  
            task.spawn(function()
                while getgenv().AutoFish do 
                    StartFishing() -- Called the renamed function here
                    task.wait(AutoFishDelay)              
                end 
            end)
        end
    end,
})

MainTab:CreateToggle({
    Name = "⋆ Auto SellAll",
    CurrentValue = false,
    Flag = "Toggle_AutoSell", 
    Callback = function(enabled)
        getgenv().AutoSell = enabled
        
        if enabled then  
            task.spawn(function()
                while getgenv().AutoSell do 
                    Sellinv()
                    task.wait(AutoSellDelay)              
                end 
            end)
        end
    end,
})

MainTab:CreateToggle({
    Name = "⋆ Auto EquipBest",
    CurrentValue = false,
    Flag = "Toggle_AutoEquipBestFish", 
    Callback = function(enabled)
        getgenv().AutoEquipBestFish = enabled
        
        if enabled then  
            task.spawn(function()
                while getgenv().AutoEquipBestFish do 
                    EquipBestFish()
                    task.wait(7)              
                end 
            end)
        end
    end,
})
-- ====================================
-- Misc Tab Toggles
-- =====================================

MiscTab:CreateToggle({
    Name = "Claim all [PT]Rewards",
    CurrentValue = false,
    Flag = "Toggle_AutoClaimRewards", 
    Callback = function(enabled)
        getgenv().AutoClaimRewards = enabled
        
        if enabled then  
            task.spawn(function()
                while getgenv().AutoClaimRewards do 
                    ClaimPlaytimeRewards()
                    task.wait(0.3)              
                end 
            end)
        end
    end,
})

MiscTab:CreateToggle({
    Name = "Auto Buy Potions",
    CurrentValue = false,
    Flag = "Toggle_AutoBuyPotions", 
    Callback = function(enabled)
        getgenv().AutoBuyPotions = enabled
        
        if enabled then  
            task.spawn(function()
                while getgenv().AutoBuyPotions do 
                    BuyPotions()
                    task.wait(0.2)              
                end 
            end)
        end
    end,
})

MiscTab:CreateToggle({
    Name = "Auto Buy [BEST]Weather",
    CurrentValue = false,
    Flag = "Toggle_AutoBuyWeather", 
    Callback = function(enabled)
        getgenv().AutoBuyWeather = enabled
        
        if enabled then  
            task.spawn(function()
                while getgenv().AutoBuyWeather do 
                    BuyBWeather()
                    task.wait(120)              
                end 
            end)
        end
    end,
})

-- ====================================
-- Settings Tab Toggles
-- =====================================

-- =====================================
-- Background Anti-AFK Handler
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


SettingsTab:CreateKeybind({
    Name = "Toggle Menu Visibility",
    CurrentKeybind = "RightControl",
    HoldToInteract = false,
    Flag = "ToggleKeybind",
    Callback = function(Keybind)
        -- Rayfield's built-in toggle command (varies slightly by fork, but usually managed via Window)
        Rayfield:Destroy() -- Or Window:Toggle() depending on how you initialized your UI
    end,
})



-- Delay Settings Section Label
-- Rayfield creates standard labels by passing the text string directly.
SettingsTab:CreateLabel("Delay Settings")

-- 2. Editable Delay Settings

-- Auto Farm Delay
SettingsTab:CreateInput({
    Name = "Auto Farm Delay (seconds)",
    CurrentValue = tostring(AutoFarmDelay), -- Fills the box with your default (2.5)
    PlaceholderText = "e.g., 2.5",
    RemoveTextAfterFocusLost = false,
    Flag = "AutoFarmDelayInput", -- Useful if you use Rayfield's auto-saving feature
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue and numValue >= 0 then
            AutoFarmDelay = numValue
            print("Auto Farm Delay updated to: " .. AutoFarmDelay)
        else
            warn("Invalid input for Auto Farm Delay. Please enter a valid number.")
        end
    end,
})

-- Auto Fish Delay
SettingsTab:CreateInput({
    Name = "Auto Fish Delay (seconds)",
    CurrentValue = tostring(AutoFishDelay), -- Fills the box with your default (0.3)
    PlaceholderText = "e.g., 0.3",
    RemoveTextAfterFocusLost = false,
    Flag = "AutoFishDelayInput",
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue and numValue >= 0 then
            AutoFishDelay = numValue
            print("Auto Fish Delay updated to: " .. AutoFishDelay)
        else
            warn("Invalid input for Auto Fish Delay. Please enter a valid number.")
        end
    end,
})

-- Auto Sell Delay
SettingsTab:CreateInput({
    Name = "Auto Sell Delay (seconds)",
    CurrentValue = tostring(AutoSellDelay), -- Fills the box with your default (25)
    PlaceholderText = "e.g., 25",
    RemoveTextAfterFocusLost = false,
    Flag = "AutoSellDelayInput",
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue and numValue >= 0 then
            AutoSellDelay = numValue
            print("Auto Sell Delay updated to: " .. AutoSellDelay)
        else
            warn("Invalid input for Auto Sell Delay. Please enter a valid number.")
        end
    end,
})


Rayfield:Notify({
   Title = "Bomb Fishing",
   Content = "Loaded | by @Mizz",
   Duration = 7.5,
   Image = currentIcon,
})