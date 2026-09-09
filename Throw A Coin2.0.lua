local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/mjzzy/001Lib/refs/heads/main/src.lua"
))()

-- ============================================================
-- Services & Locals
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

local plr    = Players.LocalPlayer
local Rem    = ReplicatedStorage.Assets.Events

-- ============================================================
-- Window
-- ============================================================
local Window = Library:CreateWindow({
    Title     = "Throw A Coin - 2.0",
    Accent    = Color3.fromRGB(255, 100, 242),
    ToggleKey = Enum.KeyCode.RightShift,
})

-- ============================================================
-- Tabs
-- ============================================================
local MainTab      = Window:CreateTab({ Name = "Main",      Icon = "house"   })
local MiscTab      = Window:CreateTab({ Name = "Misc",      Icon = "hammer-code" })
local GamepassTab  = Window:CreateTab({ Name = "Extra", Icon = "star"  })
local SettingsTab  = Window:CreateTab({ Name = "Settings",  Icon = "gear"   })

-- ============================================================
-- Shared State
-- ============================================================
local AutoThrowtime        = 2.5
getgenv().ThrowSequence    = 0
getgenv().AutoThrowCoin    = false
getgenv().AutoSellAll      = false
getgenv().AutoUpgrade1     = false
getgenv().AutoUpgrade2     = false
getgenv().AutoUpgrade3     = false
getgenv().antiafk          = false
getgenv().TargetWalkSpeed  = 16


local PREFIXES = { "Rainbow", "Astral", "Void", "Divine", "Huge", "Big", "Normal" }
-- ============================================================
-- Local Functions
-- ============================================================






local selectedSellPrefixes = {}
local selectedPrefixes = {}

local function sellByPrefixes(prefixes)
    local Event = ReplicatedStorage.Assets.Events.SellItem
    local count = 0

    for _, tool in plr.Backpack:GetChildren() do
        if tool:IsA("Tool") then
            local mutations = tool:GetAttribute("Mutations")
            for _, prefix in prefixes do
                if prefix == "Normal" then
                    if mutations == "[]" or mutations == "" or mutations == nil then
                        Event:FireServer(tool)
                        count += 1
                        break
                    end
                elseif mutations and mutations:find(prefix) then
                    Event:FireServer(tool)
                    count += 1
                    break
                end
            end
        end
    end

    return count
end

local function favoriteByPrefixes(prefixes)
    local Event = ReplicatedStorage.Assets.Events.ToggleFavorite
    local count = 0

    for _, tool in plr.Backpack:GetChildren() do
        if tool:IsA("Tool") then
            if tool:GetAttribute("Favorited") ~= false then continue end

            local mutations = tool:GetAttribute("Mutations")
            for _, prefix in prefixes do
                if prefix == "Normal" then
                    if mutations == "[]" or mutations == "" or mutations == nil then
                        firesignal(Event.OnClientEvent, tool, true)
                        count += 1
                        tool:SetAttribute("Favorited", true)
                        break
                    end
                elseif mutations and mutations:find(prefix) then
                    firesignal(Event.OnClientEvent, tool, true)
                    count += 1
                    tool:SetAttribute("Favorited", true)
                    break
                end
            end
        end
    end

    Library:Notify({ Title = "Favourited", Content = "Favourited " .. count .. " tool(s).", Duration = 3 })
    return count
end

local function unfavoriteByPrefixes(prefixes)
    local Event = ReplicatedStorage.Assets.Events.ToggleFavorite
    local count = 0

    for _, tool in plr.Backpack:GetChildren() do
        if tool:IsA("Tool") and tool:GetAttribute("Favorited") == true then
            local mutations = tool:GetAttribute("Mutations")
            for _, prefix in prefixes do
                if prefix == "Normal" then
                    if mutations == "[]" or mutations == "" or mutations == nil then
                        firesignal(Event.OnClientEvent, tool, false)
                        count += 1
                        tool:SetAttribute("Favorited", false)
                        break
                    end
                elseif mutations and mutations:find(prefix) then
                    firesignal(Event.OnClientEvent, tool, false)
                    count += 1
                    tool:SetAttribute("Favorited", false)
                    break
                end
            end
        end
    end

    Library:Notify({ Title = "Unfavourited", Content = "Unfavourited " .. count .. " tool(s).", Duration = 3 })
    return count
end

local function setLocalVIP(value)
    local state = (value == true)
    plr:SetAttribute("VIP", state)

    local vipWall = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("vipWall")
    if vipWall then vipWall.CanCollide = not state end

    pcall(function()
        local map        = workspace:FindFirstChild("Map")
        local fountain   = map and map:FindFirstChild("VIPFountain")
        local mainF      = fountain and fountain:FindFirstChild("Fountain")
        local model      = mainF and mainF:FindFirstChild("Model")
        local innerV     = model and model:FindFirstChild("v")
        local targetV    = innerV and innerV:FindFirstChild("v")
        local particles  = targetV and targetV:FindFirstChild("VIPLuck")
        if particles and particles:IsA("ParticleEmitter") then
            particles.Enabled = state
        end
    end)
end

local function setLocalDoubleCash(value)
    plr:SetAttribute("DoubleCash", value == true)
    local ev = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Events"):FindFirstChild("SyncUpgrades")
    if ev then ev:FireServer() end
end

local function setLocalDoubleThrow(value)
    plr:SetAttribute("DoubleThrow", value == true)
    local ev = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Events"):FindFirstChild("SyncUpgrades")
    if ev then ev:FireServer() end
end

local function setLocalInsaneLuck(value)
    plr:SetAttribute("InsaneLuck", value == true)
    local ev = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Events"):FindFirstChild("SyncUpgrades")
    if ev then ev:FireServer() end
end

local function setLocalMoreLuck(value)
    plr:SetAttribute("MoreLuck", value == true)
    local ev = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Events"):FindFirstChild("SyncUpgrades")
    if ev then ev:FireServer() end
end

local function setLocalMegaPotion(value)
    plr:SetAttribute("MegaPotionActive", value == true)
    local ev = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Events"):FindFirstChild("SyncBoosts")
    if ev then ev:FireServer() end
end

local function setLocalTradeWorld(value)
    plr:SetAttribute("TradeWorldUnlocked", value == true)
    local ev = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Events"):FindFirstChild("SyncWorlds")
    if ev then ev:FireServer() end
end

local function SellAll()
    Rem.SellAll:FireServer()
end

local function CoinLanded()
    local char = plr.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
    local MyPos = char.HumanoidRootPart.Position
    local coin  = plr.PlayerGui.UiFolder.Main.HUD.Coin.Main.CoinName.Text
    Rem.CoinLanded:FireServer(3, Vector3.new(MyPos.X, MyPos.Y, MyPos.Z), coin, Vector3.new(MyPos.X, MyPos.Y, MyPos.Z), 1)
end

local function CleanCoinLanded(isFastMode)
    local Character = plr.Character
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end

    local waypoints = workspace:FindFirstChild("Waypoints")
    local target = (plr:GetAttribute("VIP") and waypoints:FindFirstChild("CoinTargetVIP"))
                or (waypoints and waypoints:FindFirstChild("CoinTarget"))
    if not target then return end

    local ok, coin = pcall(function()
        return plr.PlayerGui.UiFolder.Main.HUD.Coin.Main.CoinName.Text
    end)
    coin = ok and coin or "Basic Coin"

    local lookDir          = (target.Position - HRP.Position).Unit
    local crossVec         = Vector3.new(-lookDir.Z, 0, lookDir.X)
    local mainLandingPos   = target.Position + lookDir * 8
    local secondaryPos     = plr:GetAttribute("DoubleThrow") and (mainLandingPos - crossVec * 3) or nil
    if secondaryPos then mainLandingPos = mainLandingPos + crossVec * 3 end

    if isFastMode and Rem:FindFirstChild("CoinThrow") then
        if secondaryPos then
            Rem.CoinThrow:FireServer(coin, mainLandingPos, secondaryPos)
        else
            Rem.CoinThrow:FireServer(coin, mainLandingPos)
        end
    end

    if Rem:FindFirstChild("CoinLanded") then
        plr:SetAttribute("ThrowSentAt", os.clock())
        Rem.CoinLanded:FireServer(
            3, mainLandingPos, coin, secondaryPos,
            tonumber(plr:GetAttribute("DesiredLuck")) or 1,
            tonumber(getgenv().ThrowSequence) or 0
        )
    end
    getgenv().ThrowSequence = (getgenv().ThrowSequence or 0) + 1
end

local function BuyAllCoins()
    for _, v in pairs(plr.PlayerGui.UiFolder.Main.Frames.CoinShop.SFcontainer.SF:GetChildren()) do
        if v:IsA("Frame") then Rem.BuyCoin:FireServer(v.Name) end
    end
end

local function BuyAllUpgrades()
    for _, v in pairs(plr.PlayerGui.UiFolder.Main.Frames.Upgrades.SFHolder:GetChildren()) do
        if v:IsA("Frame") then Rem.RequestUpgrade:FireServer(v.Name) end
    end
end

-- ============================================================
-- WalkSpeed enforcer loop
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.1)
        pcall(function()
            if plr and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.WalkSpeed ~= getgenv().TargetWalkSpeed then
                    hum.WalkSpeed = getgenv().TargetWalkSpeed
                end
            end
        end)
    end
end)

-- Anti-AFK
plr.Idled:Connect(function()
    if not getgenv().antiafk then return end
    local vu = game:GetService("VirtualUser")
    vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(0.8)
    vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- ============================================================
-- MAIN TAB
-- ============================================================
MainTab:CreateLabel("── Automation ──")

MainTab:CreateToggle({
    Name    = "Auto Throw Coin",
    Default = false,
    Callback = function(enabled)
        getgenv().AutoThrowCoin = enabled
        if not enabled then return end
        task.spawn(function()
            while getgenv().AutoThrowCoin do
                task.wait(0.1)
                if not getgenv().AutoThrowCoin then break end
                CoinLanded()
                task.wait(0.5)
                local ev = ReplicatedStorage.Assets.Events.ThrowReady
                firesignal(ev.OnClientEvent, nil)
                task.wait(AutoThrowtime)
            end
        end)
    end,
})

MainTab:CreateToggle({
    Name    = "Faster Auto Throw",
    Default = false,
    Callback = function(enabled)
        getgenv().AutoThrowCoin = enabled
        if not enabled then return end
        task.spawn(function()
            while getgenv().AutoThrowCoin do
                CleanCoinLanded(true)

                local serverReady = false
                local connection
                connection = Rem.ThrowReady.OnClientEvent:Connect(function(seqId)
                    if tonumber(seqId) == tonumber(getgenv().ThrowSequence) - 1 then
                        serverReady = true
                    end
                end)

                local start = os.clock()
                while not serverReady and getgenv().AutoThrowCoin and (os.clock() - start < 1.5) do
                    task.wait()
                end
                if connection then connection:Disconnect() end
            end
        end)
    end,
})

MainTab:CreateLabel("── Auto Sell ──")

MainTab:CreateToggle({
    Name    = "Auto Sell",
    Default = false,
    Callback = function(enabled)
        getgenv().AutoSell = enabled
        if not enabled then return end

        task.spawn(function()
            while getgenv().AutoSell do
                if #selectedSellPrefixes == 0 then
                    Library:Notify({ Title = "Nothing Selected", Content = "Pick at least one Mutation first. ", Duration = 3 })
                    getgenv().AutoSell = false
                    break
                end

                sellByPrefixes(selectedSellPrefixes)
                task.wait(0.5)
            end
        end)
    end,
})

MainTab:CreateDropdown({
    Name    = "Select Mutations",
    Options = PREFIXES,
    Multi   = true,
    Callback = function(choices)
        selectedSellPrefixes = choices
    end,
})


MainTab:CreateToggle({
    Name    = "Auto Sell All",
    Default = false,
    Callback = function(enabled)
        getgenv().AutoSellAll = enabled
        if not enabled then return end
        task.spawn(function()
            while getgenv().AutoSellAll do
                task.wait(0.1)
                if not getgenv().AutoSellAll then break end
                SellAll()
                task.wait(15)
            end
        end)
    end,
})


-- ============================================================
-- MISC TAB
-- ============================================================
MiscTab:CreateLabel("── Upgrades ──")

local selectedUpgrades = {}

MiscTab:CreateDropdown({
    Name    = "Select Upgrades",
    Options = { "All Upgrades", "Luck Multiplier", "Value Multiplier", "Throw Speed" },
    Multi   = true,
    Callback = function(choices)
        selectedUpgrades = choices
    end,
})

MiscTab:CreateToggle({
    Name    = "Auto Upgrade",
    Default = false,
    Callback = function(enabled)
        getgenv().AutoUpgrade = enabled
        if not enabled then return end

        task.spawn(function()
            while getgenv().AutoUpgrade do
                for _, choice in selectedUpgrades do
                    if choice == "All Upgrades" then
                        BuyAllUpgrades()
                    else
                        ReplicatedStorage.Assets.Events.RequestUpgrade:FireServer(choice)
                    end
                end
                task.wait(0.5)
            end
        end)
    end,
})


MiscTab:CreateLabel("── Favourite items ──")


MiscTab:CreateDropdown({
    Name    = "Select Mutations",
    Options = PREFIXES,
    Multi   = true,
    Callback = function(choices)
        selectedPrefixes = choices
    end,
})


MiscTab:CreateButton({
    Name     = "Favourite Selected",
    Callback = function()
        if #selectedPrefixes == 0 then
            Library:Notify({ Title = "Nothing Selected", Content = "Pick at least one mutation first.", Duration = 3 })
            return
        end

        local count = favoriteByPrefixes(selectedPrefixes)
        Library:Notify({ Title = "Done", Content = "Favourited " .. count .. " tool(s).", Duration = 3 })
    end,
})

MiscTab:CreateButton({
    Name     = "Unfavourite Selected",
    Callback = function()
        if #selectedPrefixes == 0 then
            Library:Notify({ Title = "Nothing Selected", Content = "Pick at least one rarity first.", Duration = 3 })
            return
        end
        unfavoriteByPrefixes(selectedPrefixes)
    end,
})
-- ============================================================
-- GAMEPASSES TAB
-- ============================================================
GamepassTab:CreateLabel("── Gamepass Spoofs ──")
GamepassTab:CreateWarning("These are local-only and do not grant real gamepasses.")

local gpFunctions = {
    ["VIP"]         = setLocalVIP,
    ["Double Cash"] = setLocalDoubleCash,
    ["Double Throw"] = setLocalDoubleThrow,
    ["Insane Luck"] = setLocalInsaneLuck,
    ["More Luck"]   = setLocalMoreLuck,
    ["Mega Potion"] = setLocalMegaPotion,
}

local gpOrder = { "VIP", "Double Cash", "Double Throw", "Insane Luck", "More Luck", "Mega Potion" }

GamepassTab:CreateDropdown({
    Name    = "Active Spoofs",
    Options = gpOrder,
    Multi   = true,
    Callback = function(selected)
        -- Build a set of what's currently selected
        local active = {}
        for _, name in selected do active[name] = true end

        -- Enable or disable each one based on selection
        for _, name in gpOrder do
            gpFunctions[name](active[name] == true)
        end
    end,
})

GamepassTab:CreateLabel("── Unlocks ──")

GamepassTab:CreateToggle({
    Name    = "Trade World",
    Default = false,
    Callback = function(enabled)
        setLocalTradeWorld(enabled)
    end,
})
-- ============================================================
-- SETTINGS TAB
-- ============================================================
SettingsTab:CreateLabel("── Performance ──")

SettingsTab:CreateToggle({
    Name    = "Block Throw Rejected Event",
    Default = false,
    Callback = function(enabled)
        local ev = ReplicatedStorage.Assets.Events.ThrowRejected
        for _, connection in ipairs(getconnections(ev.OnClientEvent)) do
            if enabled then connection:Disable() else connection:Enable() end
        end
    end,
})

SettingsTab:CreateToggle({
    Name    = "Disable 3D Rendering",
    Default = false,
    Callback = function(enabled)
        game:GetService("RunService"):Set3dRenderingEnabled(not enabled)
    end,
})

SettingsTab:CreateToggle({
    Name    = "Anti AFK",
    Default = false,
    Callback = function(enabled)
        getgenv().antiafk = enabled
    end,
})

SettingsTab:CreateLabel("── Speed ──")

SettingsTab:CreateSlider({
    Name      = "Walk Speed",
    Min       = 16,
    Max       = 150,
    Default   = 16,
    Increment = 1,
    Callback  = function(value)
        getgenv().TargetWalkSpeed = value
    end,
})

SettingsTab:CreateLabel("── Delay ──")

SettingsTab:CreateTextbox({
    Name        = "Auto Throw Delay",
    Default     = tostring(AutoThrowtime),
    Placeholder = "e.g. 2.5",
    Callback    = function(value)
        local n = tonumber(value)
        if n and n >= 0 then
            AutoThrowtime = n
            Library:Notify({
                Title   = "Delay Updated",
                Content = "Auto Throw delay set to " .. n .. "s",
                Duration = 3,
            })
        else
            Library:Notify({
                Title   = "Invalid Input",
                Content = "Please enter a valid number (e.g. 2.5)",
                Duration = 3,
            })
        end
    end,
})

-- ============================================================
-- Ready notification
-- ============================================================
Library:Notify({
    Title   = "Throw A Coin Loaded",
    Content = "Press RightShift to toggle the window.",
    Duration = 7,
})