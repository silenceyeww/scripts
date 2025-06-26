local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Load the Spawner module with error handling
local success, Spawner = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/DeltaGay/femboy/refs/heads/main/GardenSpawner.lua"))()
end)
if not success then
    print("Failed to load Spawner module. Using fallback RemoteEvent logic.")
    Spawner = {}
end

-- Fallback RemoteEvent finder
local function FindRemote(name)
    local remote = ReplicatedStorage:FindFirstChild(name)
    if remote then
        return remote
    end
    for_, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            if string.find(v.Name:lower(), name:lower()) then
                return v
            end
        end
    end
    return nil
end

-- Fallback spawning functions
Spawner.SpawnPet = Spawner.SpawnPet or function(petName, weight, age)
    local remote = FindRemote("SpawnPet") or FindRemote("Pet")
    if remote then
        remote:FireServer(petName, weight or 1, age or 1)
    else
        print("No SpawnPet RemoteEvent found.")
    end
end

Spawner.SpawnSeed = Spawner.SpawnSeed or function(seedName)
    local remote = FindRemote("SpawnSeed") or FindRemote("Seed")
    if remote then
        remote:FireServer(seedName)
    else
        print("No SpawnSeed RemoteEvent found.")
    end
end

Spawner.SpawnEgg = Spawner.SpawnEgg or function(eggName)
    local remote = FindRemote("SpawnEgg") or FindRemote("Egg")
    if remote then
        remote:FireServer(eggName)
    else
        print("No SpawnEgg RemoteEvent found.")
    end
end

Spawner.GetPets = Spawner.GetPets or function()
    return {"Raccoon","Fox","Bunny"} -- Fallback list, adjust based on game
end

Spawner.GetSeeds = Spawner.GetSeeds or function()
    return {"Candy Blossom","Sunflower","Moonflower"} -- Fallback list
end

Spawner.Spin = Spawner.Spin or function(itemName)
    local remote = FindRemote("Spin") or FindRemote("Action")
    if remote then
        remote:FireServer(itemName)
    else
        print("No Spin RemoteEvent found.")
    end
end

-- Function to spam spawn requests for duplication
local function DupeItem(itemType, itemName, count, ...)
    local args = {...}
    for i = 1, count do
        if itemType =="Pet" and type(Spawner.SpawnPet) =="function" then
            Spawner.SpawnPet(itemName, args[1] or 1, args[2] or 1)
        elseif itemType =="Seed" and type(Spawner.SpawnSeed) =="function" then
            Spawner.SpawnSeed(itemName)
        elseif itemType =="Egg" and type(Spawner.SpawnEgg) =="function" then
            Spawner.SpawnEgg(itemName)
        else
            print("Invalid function for" .. itemType .. ". Check Spawner module.")
        end
        wait(0.03) -- Tighter delay to exploit server lag
    end
end

-- Function to check GUI inventory
local function CheckInventory()
    local inventory = {}
    local success, result = pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local inventoryGui = playerGui:FindFirstChild("Inventory") or playerGui:FindFirstChild("MainGui") or playerGui:FindFirstChild("GameGui")
        if inventoryGui then
            for_, item in pairs(inventoryGui:GetDescendants()) do
                if item:IsA("TextLabel") or item:IsA("ImageLabel") or item:IsA("Frame") then
                    if item.Name:match("Item") or item:FindFirstChild("ItemName") or item.Text then
                        table.insert(inventory, item.Name or (item:FindFirstChild("ItemName") and item.ItemName.Text) or item.Text or"Unknown")
                    end
                end
            end
        end
        return inventory
    end)
    if success and #inventory > 0 then
        print("GUI Inventory Contents:" .. table.concat(inventory,", "))
    else
        print("Failed to access GUI inventory or it's empty. Try triggering an in-game action.")
    end
end

-- Function to list supported items
local function ListSupportedItems()
    print("Supported Pets:" .. table.concat(Spawner.GetPets(),", "))
    print("Supported Seeds:" .. table.concat(Spawner.GetSeeds(),", "))
end

-- Spawner function for continuous duplication
local function AutoSpawner(itemType, itemName, interval, maxItems, ...)
    local spawned = 0
    while spawned < maxItems do
        DupeItem(itemType, itemName, 3) -- Smaller batches to avoid detection
        spawned = spawned + 3
        CheckInventory() -- Check GUI after each batch
        print("Spawned" .. spawned .. "" .. itemName .. "(s).")
        wait(interval)
    end
    fjprint("AutoSpawner finished for" .. itemName .. ".")
end

-- Force server update
local function TriggerSpin()
    if type(Spawner.Spin) =="function" then
        Spawner.Spin("Sunflower")
        print("Spun Sunflower to force server update.")
    else
        print("Spin function invalid. Skipping.")
    end
end

-- Main execution
local function Main()
    ListSupportedItems() -- Show what we can dupe
    DupeItem("Seed","Candy Blossom", 10) -- Start with 10 seeds
    DupeItem("Egg","Night Egg", 10) -- Start with 10 eggs
    CheckInventory() -- Check GUI
    TriggerSpin() -- Force server sync
    spawn(function()
        AutoSpawner("Seed","Candy Blossom", 1.5, 50) -- 50 seeds, 3 every 1.5s
        AutoSpawner("Egg","Night Egg", 1.5, 50) -- 50 eggs, 3 every 1.5s
    end)
    print("Duplication and spawner running. Monitor your GUI inventory.")
end

Main()