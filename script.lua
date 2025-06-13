
-- Obfuscated with Script Source Converter
local _GREUmVPt = function() return "MC40MjM1MzY1NDgwMTMzNDM3" end
local _EYwVISmQ = {0.4367895517045356,0.5627385834292966,0.7958371261913538,0.36265504577216334,0.3733846107804988}
if _bNfiyMvV ~= nil then _iqGUSeYO = nil end
-- ESP Hack Script
local _vOwOKRBA = game:GetService("Players")
local _mJTxNAfi = game:GetService("RunService")
local _DEjOBHUQ = _vOwOKRBA.LocalPlayer
local _pKVAgjUf = workspace.CurrentCamera

-- Configuration
local _uiqGUYOt = true
local _TNbcdsMA = Color3.fromRGB(255, 0, 0)
local _ycFbZepe = 0.5
local _QlQDGCLY = 14

-- Create ESP objects
local _BdFIVZTR = {}

-- Function to create ESP for a player
local _kvWiiKnx createESP(player)
    if player == _DEjOBHUQ then return end
    
    local _snfbvPCG = Drawing.new("Text")
    _snfbvPCG.Visible = false
    _snfbvPCG.Center = true
    _snfbvPCG.Outline = true
    _snfbvPCG.Color = _TNbcdsMA
    _snfbvPCG.Size = _QlQDGCLY
    _snfbvPCG.Transparency = 1
    
    _BdFIVZTR[player] = _snfbvPCG
end

-- Function to update ESP
local _kvWiiKnx updateESP()
    for player, _snfbvPCG in pairs(_BdFIVZTR) do
        if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            _snfbvPCG.Visible = false
            continue
        end
        
        local _psTsxRNm = player.Character.HumanoidRootPart
        local _NORcxryq = player.Character:FindFirstChild("Humanoid")
        
        local _GuYwFBjR, onScreen = _pKVAgjUf:WorldToScreenPoint(_psTsxRNm.Position)
        
        if onScreen and _NORcxryq and _NORcxryq.Health > 0 and _uiqGUYOt then
            _snfbvPCG.Position = Vector2.new(_GuYwFBjR.X, _GuYwFBjR.Y)
            _snfbvPCG.Text = player.Name .. " [" .. math.floor(_NORcxryq.Health) .. " HP]"
            _snfbvPCG.Visible = true
            
            -- Calculate _TqSsPuXi for scaling
            local _TqSsPuXi = (_pKVAgjUf.CFrame.Position - _psTsxRNm.Position).Magnitude
            _snfbvPCG.Size = math.clamp(_QlQDGCLY * (100 / _TqSsPuXi), 10, 30)
        else
            _snfbvPCG.Visible = false
        end
    end
end

-- Create ESP for existing _vOwOKRBA
for _, player in ipairs(_vOwOKRBA:GetPlayers()) do
    createESP(player)
end

-- Create ESP for new _vOwOKRBA
_vOwOKRBA.PlayerAdded:Connect(createESP)

-- Remove ESP when _vOwOKRBA leave
_vOwOKRBA.PlayerRemoving:Connect(_kvWiiKnx(player)
    if _BdFIVZTR[player] then
        _BdFIVZTR[player]:Remove()
        _BdFIVZTR[player] = nil
    end
end)

-- Toggle ESP with Z key
game:GetService("UserInputService").InputBegan:Connect(_kvWiiKnx(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Z then
        _uiqGUYOt = not _uiqGUYOt
        print("ESP " .. (_uiqGUYOt and "enabled" or "disabled"))
    end
end)

-- Update ESP on each frame
_mJTxNAfi:BindToRenderStep("ESP", 200, updateESP)

print("ESP hack activated! Press Z to toggle")