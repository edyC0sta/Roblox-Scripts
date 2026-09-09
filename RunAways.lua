local loot = {}
local playerHrp = game:GetService("Players").LocalPlayer.Character.HumanoidRootPart
local dropdown
local Event = game:GetService("ReplicatedStorage").FlowClient.ClientRunner.Event

local ESPLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/MSESP/refs/heads/main/source.luau"))()
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

--Ammo Remote hook
getgenv().InfiniteAmmo = false
local ammoHook
ammoHook = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if getgenv().InfiniteAmmo and (method == "GetAttribute") then
        local attributeName = args[1]
        if attributeName == "Ammo" then
            return 999
        end
    end
    return ammoHook(self, ...)
end)
--

--Damage Remote Hook (for the One Tap)
getgenv().OneTap = false
local oneTapHook
oneTapHook = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}  
    if getgenv().OneTap and
       self == Event and
       method == "FireServer" then
        if args[2] == "Damage" then
            args[4] = 9999
            return oneTapHook(self, unpack(args))
        end
    end
    return oneTapHook(self, ...)
end)
--

--Infinite Fuel Value hook
getgenv().InfiniteFuel = false
local gas = workspace.Vehicles.Claptima.gasLevel
local infiniteFuelHook
infiniteFuelHook = hookmetamethod(game, "__index", function(self,v)
    if getgenv().InfiniteFuel and
       self == gas and 
       v == "Value" then
        return 50
    end
    return infiniteFuelHook(self, v)
end)

--ESP
local function partAdded(part)    
    if not part:IsA("Model") then return end
    
    if (part.Name == "Safe" or 
       part.Name == "ATM" or
       part.Name == "Vault") and 
       part.Health.Value >= 0 then
        local PartColor = Color3.fromRGB(100, 255, 100)
        local partESP = ESPLibrary:Add({
            Name = part.Name,
            Model = part,

            Color = PartColor,
            MaxDistance = 10000,
            TextSize = 17,

            ESPType = "Highlight",
            FillColor = PartColor,
            OutlineColor = PartColor,
        })

        local partHealth = part.Health
        partHealth.Changed:Connect(function(newvalue)
            if newvalue <= 0 then
                print("No health")
                partESP:Destroy()
            end
        end)
    end
end

local function ESP(bool)
    if bool then
        local buildings = game.Workspace.Map.Buildings
        local buldingsDescendants = buildings:GetDescendants()

        for _,descendant in buldingsDescendants do
            partAdded(descendant)
        end

        buildings.DescendantAdded:Connect(function(descendant)
            partAdded(descendant)
        end)
    else ESPLibrary:Clear()
    end
end
--

--Loot TP
local function pickupEvent(tool)
    local Event = game:GetService("ReplicatedStorage").FlowClient.ClientRunner.Function
    Event:InvokeServer(
        "Loot",
        "LootEquip",
        tool.Handle
    )
end

local function pickupItemAndReturntoPos(selectedItem)
    if not selectedItem then return end

    local lootLoc = game.Workspace.Loot
    local item = lootLoc:FindFirstChild(selectedItem)
    if item then
        local itemPos = item.Handle.CFrame.Position
        local playerPos = playerHrp.CFrame.Position
        playerHrp.CFrame = CFrame.new(itemPos)
        task.wait(0.2)
        pickupEvent(item)
        task.wait(0.8)
        playerHrp.CFrame = CFrame.new(playerPos)
     end
end

local function lootTP()
    local lootLoc = game.Workspace.Loot
    loot = lootLoc:GetChildren()

    for i,item in loot do
        if item.Name == "Coin" then -- bugs your player
            table.remove(loot, i)
        end
        loot[i] = item.Name
    end

    lootLoc.ChildRemoved:Connect(function(item)
        dropdown:Set({})
        local index = table.find(loot,item.Name)
        table.remove(loot, index)
        dropdown:Refresh(loot)
    end)

    lootLoc.ChildAdded:Connect(function(item)
        if item.Name == "Coin" then return end -- bugs your player
        dropdown:Set({})
        table.insert(loot, item.Name)
        dropdown:Refresh(loot)
    end)

    return loot
end
--


--Kill Aura
local function npcsInRange(npcs, plrPos, maxDistance)
    local distance
    local NpcsInDinstance = {}

    for _,npc in pairs(npcs) do
        local npcPos = npc.HumanoidRootPart.CFrame.Position
        distance = (plrPos - npcPos).magnitude

        if distance <= maxDistance then
            table.insert(NpcsInDinstance, npc)
        end
    end

    return NpcsInDinstance
end

local function DamageNPCsEvent(npcs)
    for _ , npc in pairs(npcs) do
        local Event = game:GetService("ReplicatedStorage").FlowClient.ClientRunner.Event
        Event:FireServer(
            "NPCs",
            "Damage",
            npc.Humanoid,
            1000
        )
    end
end

local function killaura(bool, maxDistance)
    if bool then
        local NPCSLocation = game.Workspace.NPCs
        local NPCS = NPCSLocation:GetChildren()
        local plrPos = playerHrp.CFrame.Position
        local goodNPCS = npcsInRange(NPCS, plrPos, maxDistance)

        DamageNPCsEvent(goodNPCS)

        NPCSLocation.ChildRemoved:Connect(function(npc)
            for _,v in pairs(goodNPCS) do
                if npc == v then
                    table.remove(goodNPCS,v)
                end
            end
        end)
    end
end
--

--One Tap
local function oneTap(bool)
    getgenv().OneTap = bool
end
--

--Infinite Ammo
local function infiniteAmmo(bool)
    getgenv().InfiniteAmmo = bool
end
--

-- "Infinite Fuel"
local function infiniteFuel(bool)
    getgenv().InfiniteFuel = bool
end
--

--Vehicle Mods
local function vehicleMods(mod, value)
    local vehicle = game.Workspace.Vehicles:FindFirstChildOfClass("Model").VehicleProperty

    if mod == "Acceleration" then
    vehicle:SetAttribute("Acceleration", value)
    else
    vehicle:SetAttribute("TopSpeedMPH", value)
    end
end

local function setupUI()
    local window = Rayfield:CreateWindow({
        name = "RunAways Scripts",
        subtitle = "Made by Edy_Synner",
        sidebarLayout = true,
    })

    local itemsAndesp = window:CreateTab({ name = "Items & ESP", icon = 127234874352422 })
    local combat = window:CreateTab({ name = "Combat", icon = 101060850237115 })
    local carMods = window:CreateTab({ name = "Car Mods", icon = 91451724283877 })

    dropdown = itemsAndesp:CreateDropdown({
        name = "Items",
        description = "Select the Items to pick Up",
        multiSelect = false,
        options = loot,
        callback = function(selected)
            pickupItemAndReturntoPos(selected)
            dropdown:Refresh(loot)
        end,
    })

    itemsAndesp:CreateToggle({
    name = "ESP",
    description = "ESP on ATMs, Safes and Vaults",
    value = false,
    callback = function(value)
        ESP(value)
    end,
    })
    
    local maxDistance
    combat:CreateInput({
    name = "Kill aura Distance",
    numeric = true,
    placeholder = "Enter a number",
    callback = function(distance)
        maxDistance = distance
    end,
    })

    combat:CreateToggle({
    name = "Kill aura",
    description = "Will kill all npcs on the said distance",
    callback = function(value)
        killaura(value, tonumber(maxDistance))
    end,
    })

    combat:CreateToggle({
    name = "One Tap",
    description = "This is make it so you can one tap things that can be damaged (npcs, cars, atms...)",
    callback = function(value)
        oneTap(value)
    end,
    })

    combat:CreateToggle({
    name = "Infinite Ammo",
    description = "Give you infinite ammo on any gun",
    callback = function(value)
        infiniteAmmo(value)
    end,
    })

    carMods:CreateToggle({
    name = "Infinite Fuel",
    description = "Makes it so you can drive the car even when it doesn't have fuel",
    value = false,
    callback = function(value)
        infiniteFuel(value)
    end,
    })

    carMods:CreateInput({
    name = "Acceleration",
    description = "Allows you to change the vehicle acceleration",
    numeric = true,
    placeholder = "Enter a number",
    callback = function(number)
        vehicleMods("Acceleration", number)
    end,
    })

    carMods:CreateInput({
    name = "Top Speed",
    description = "Allows you to change the vehicle top speed",
    numeric = true,
    placeholder = "Enter a number",
    callback = function(number)
        vehicleMods("TopSpeedMPH", number)
    end,
    })
    
end


loot = lootTP()
setupUI()
