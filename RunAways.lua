local Loot = {}
local Player = game:GetService("Players").LocalPlayer.Character
local PlayerHrp = Player.HumanoidRootPart
local Dropdown
local Event = game:GetService("ReplicatedStorage").FlowClient.ClientRunner.Event

local ESPLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/MSESP/refs/heads/main/source.luau"))()
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

--Damage Remote Hook (for the One Tap)
getgenv().OneTap = false
local OneTapHook
OneTapHook = hookmetamethod(game, "__namecall", newcclosure(function(Self, arg1, arg2, arg3, damage, ...)
    local Method = getnamecallmethod()
    if OneTap and
       Self == Event and
       Method == "FireServer" and
       typeof(arg1) == "string" and
       typeof(arg2) == "string" and arg2 == "Damage" and
       typeof(arg3) == "Instance" and
       typeof(damage) == "number" then
        return OneTapHook(Self, arg1, arg2, arg3, 9999, ...)
    end
    return OneTapHook(Self, arg1, arg2, arg3, damage, ...)
end))
--

--ESP
local function partAdded(Part)    
    if not Part:IsA("Model") then return end
    
    if (Part.Name == "Safe" or 
       Part.Name == "ATM" or
       Part.Name == "Vault") and 
       Part.Health.Value >= 0 then
        local PartColor = Color3.fromRGB(100, 255, 100)
        local PartESP = ESPLibrary:Add({
            Name = Part.Name,
            Model = Part,

            Color = PartColor,
            MaxDistance = 10000,
            TextSize = 17,

            ESPType = "Highlight",
            FillColor = PartColor,
            OutlineColor = PartColor,
        })

        local PartHealth = Part.Health
        PartHealth.Changed:Connect(function(NewValue)
            if NewValue <= 0 then
                PartESP:Destroy()
            end
        end)
    end
end

local function ESP(Enabled)
    if not Enabled then ESPLibrary:Clear() end
    
    local Buildings = game.Workspace.Map.Buildings
    local BuldingsDescendants = Buildings:GetDescendants()

    for _,Descendant in BuldingsDescendants do
        partAdded(Descendant)
    end

    Buildings.DescendantAdded:Connect(function(Descendant)
        partAdded(Descendant)
    end)
end
--

--Loot TP
local function PickupEvent(Tool)
    local Event = game:GetService("ReplicatedStorage").FlowClient.ClientRunner.Function
    Event:InvokeServer(
        "Loot",
        "LootEquip",
        Tool.Handle
    )
end

local function pickupItemAndReturntoPos(SelectedItem)
    if not SelectedItem then return end

    local LootLoc = game.Workspace.Loot
    local Item = LootLoc:FindFirstChild(SelectedItem)
    if Item then
        local ItemPos = Item.Handle.CFrame.Position
        local PlayerPos = PlayerHrp.CFrame.Position
        PlayerHrp.CFrame = CFrame.new(ItemPos)
        task.wait(0.5)
        PickupEvent(Item)
        task.wait(1)
        PlayerHrp.CFrame = CFrame.new(PlayerPos)
     end
end

local function LootTP()
    local LootLoc = game.Workspace.Loot
    Loot = LootLoc:GetChildren()

    for i,Item in Loot do
        if Item.Name == "Coin" then -- bugs your player
            table.remove(Loot, i)
        end
        Loot[i] = Item.Name
    end

    LootLoc.ChildRemoved:Connect(function(Item)
        Dropdown:Set({})
        local Index = table.find(Loot,Item.Name)
        table.remove(Loot, Index)
        Dropdown:Refresh(Loot)
    end)

    LootLoc.ChildAdded:Connect(function(Item)
        if Item.Name == "Coin" then return end -- bugs your player
        Dropdown:Set({})
        table.insert(Loot, Item.Name)
        Dropdown:Refresh(Loot)
    end)

    return Loot
end
--


--Kill Aura
local function NpcsInRange(Npcs, PlrPos, MaxDistance)
    local Distance
    local NpcsInDinstance = {}

    for _,Npc in Npcs do
        if Npc:WaitForChild("Humanoid").Health <= 0 then continue end
        local NpcHrp = Npc:FindFirstChild("HumanoidRootPart")
        local NpcPos
        if NpcHrp then
            NpcPos = NpcHrp.CFrame.Position
        else continue end

        Distance = (PlrPos - NpcPos).magnitude

        if Distance <= MaxDistance then
            table.insert(NpcsInDinstance, Npc)
        end
    end

    return NpcsInDinstance
end

local function DamageNPCsEvent(Npcs)
    for _ , Npc in Npcs do
        local Event = game:GetService("ReplicatedStorage").FlowClient.ClientRunner.Event
        Event:FireServer(
            "NPCs",
            "Damage",
            Npc:WaitForChild("Humanoid"),
            1000
        )
    end
end

local function killaura(MaxDistance)
    if not KillAuraStatus then return end

    local NPCSLocation = game.Workspace.NPCs
    local NPCS = NPCSLocation:GetChildren()
    local GoodNPCS

    NPCSLocation.ChildAdded:Connect(function(Npc)
        table.insert(NPCS, Npc)
    end)

    NPCSLocation.ChildRemoved:Connect(function(Npc)
        if GoodNPCS then
            local Index1 = table.find(GoodNPCS, Npc)
            if Index1 then
                table.remove(GoodNPCS, Index1)
            end
        end

        if NPCS then
            local Index2 = table.find(NPCS, Npc)
            if Index2 then
                table.remove(NPCS, Index2)
            end
        end
    end)

    while KillAuraStatus do
        task.wait(0.1)
        local PlrPos = PlayerHrp.CFrame.Position
        GoodNPCS = NpcsInRange(NPCS, PlrPos, MaxDistance)
        DamageNPCsEvent(GoodNPCS)
    end
end
--

--One Tap
local function oneTap(BoolValue)
    OneTap = BoolValue
end
--

--Infinite Ammo
local function InfiniteAmmo()
    Player.ChildAdded:Connect(function(Child)
        if not Child:isA("Tool") then return end
        local Tool = Child

        Tool.AttributeChanged:Connect(function(Attribute)
            if Attribute == "Ammo" then
                Tool:SetAttribute("Ammo", 999)
            end
        end)
    end)
end
--

-- "Infinite Fuel"
local function InfiniteFuel(Vehicle)
    local Fuel = Vehicle.gasLevel

    Fuel.Changed:Connect(function()
        Fuel.Value = 50
    end)
end
--

--Vehicle Mods
local function VehicleMods(Mod, Value, Vehicle)

    if Mod == "Acceleration" then
    Vehicle.VehicleProperty:SetAttribute("Acceleration", Value)
    else
    Vehicle.VehicleProperty:SetAttribute("TopSpeedMPH", Value)
    end
end

local function SetupUI()
    local Window = Rayfield:CreateWindow({
        name = "RunAways Scripts",
        subtitle = "Made by Edy_Synner",
        sidebarLayout = true,
    })

    local ItemsAndesp = Window:CreateTab({ name = "Items & ESP", icon = 127234874352422 })
    local Combat = Window:CreateTab({ name = "Combat", icon = 101060850237115 })
    local CarMods = Window:CreateTab({ name = "Car Mods", icon = 91451724283877 })

    Dropdown = ItemsAndesp:CreateDropdown({
        name = "Items",
        description = "Select the Items to pick Up",
        multiSelect = false,
        options = Loot,
        callback = function(selected)
            pickupItemAndReturntoPos(selected)
            Dropdown:Refresh(Loot)
        end,
    })

    ItemsAndesp:CreateToggle({
    name = "ESP",
    description = "ESP on ATMs, Safes and Vaults",
    value = false,
    callback = function(Enabled)
        ESP(Enabled)
    end,
    })
    
    local MaxDistance
    Combat:CreateInput({
    name = "Kill aura Distance",
    numeric = true,
    placeholder = "Enter a number",
    callback = function(Distance)
        MaxDistance = Distance
    end,
    })

    getgenv().KillAuraStatus = false
    Combat:CreateToggle({
    name = "Kill aura",
    description = "Will kill all npcs on the said distance",
    callback = function(BoolValue)
        KillAuraStatus = BoolValue
        killaura(tonumber(MaxDistance))
    end,
    })

    Combat:CreateToggle({
    name = "One Tap",
    description = "This is make it so you can one tap things that can be damaged (npcs, cars, atms...)",
    callback = function(BoolValue)
        oneTap(BoolValue)
    end,
    })

    Combat:CreateButton({
    name = "Infinite Ammo",
    description = "Give you infinite ammo on any gun",
    callback = function()
        InfiniteAmmo()
    end,
    })

    local Vehicle = game.Workspace.Vehicles:FindFirstChildOfClass("Model")

    CarMods:CreateButton({
    name = "Infinite Fuel",
    description = "Makes it so you can drive the car even when it doesn't have fuel",
    value = false,
    callback = function()
        InfiniteFuel(Vehicle)
    end,
    })

    CarMods:CreateInput({
    name = "Acceleration",
    description = "Allows you to change the vehicle acceleration",
    numeric = true,
    placeholder = "Enter a number",
    callback = function(Number)
        VehicleMods("Acceleration", Number, Vehicle)
    end,
    })

    CarMods:CreateInput({
    name = "Top Speed",
    description = "Allows you to change the vehicle top speed",
    numeric = true,
    placeholder = "Enter a number",
    callback = function(Number)
        VehicleMods("TopSpeedMPH", Number, Vehicle)
    end,
    })
    
end


Loot = LootTP()
SetupUI()
