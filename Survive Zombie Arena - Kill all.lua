local player = game:GetService("Players").LocalPlayer
local char = player.Character
local zombieDirectory = game.Workspace.Zombies_Local
local zombies = {}
local remote = game:GetService("ReplicatedStorage").Remotes.GunRemotes.GunHit
local hrp = char.HumanoidRootPart

hrp.CFrame = CFrame.new(596,2162,300)

local function processZombie(zombie)
    local num = tonumber(zombie.Name:sub(8))
    if num and not table.find(zombies, num) then
        table.insert(zombies, num)
    end
end

for _, zombie in zombieDirectory:GetChildren() do
    processZombie(zombie)
end
zombieDirectory.ChildAdded:Connect(processZombie)

zombieDirectory.ChildRemoved:Connect(function(zombie)
    local num = tonumber(zombie.Name:sub(8))
    if num then
        local index = table.find(zombies, num)
        if index then
            table.remove(zombies, index)
        end
    end
end)

while task.wait(0.1) do
    if #zombies > 0 then
        local tool = char:FindFirstChildOfClass("Tool")
        local toolName
        if tool then
            toolName = tool.Name
        end

        for _, zombieNum in zombies do
            local zombieName = "Zombie_" .. tostring(zombieNum)
            local zombieModel = zombieDirectory:WaitForChild(zombieName)
            
            if zombieModel then
                local zombiePos = zombieModel:WaitForChild("HumanoidRootPart").CFrame.Position
                    remote:FireServer(
                        toolName,
                        zombieNum,
                        zombiePos
                    )
            else continue
            end
        end
    end
end
