local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

if CoreGui:FindFirstChild("DeviceSwitcherUI") then
    CoreGui.DeviceSwitcherUI:Destroy()
end

local savedDevice = getgenv().SelectedDevice

local deviceLabels = {
    PC = "💻 كمبيوتر (PC)",
    PS5 = "🎮 سوني (PS5)",
    Mobile = "📱 جوال (Mobile)"
}

-- أرقام صور للأجهزة (تقدر تغيرها حسب أي Asset ID يناسبك)
local deviceIcons = {
    PC = "rbxassetid://11748880971",
    PS5 = "rbxassetid://11748883684",
    Mobile = "rbxassetid://11748878255"
}

local function looksLikeDeviceIcon(obj)
    if not (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
        return false
    end

    local nameLower = string.lower(obj.Name)
    if string.find(nameLower, "device")
        or string.find(nameLower, "platform")
        or string.find(nameLower, "console")
        or string.find(nameLower, "mobile")
        or string.find(nameLower, "icon") then
        return true
    end

    local parent = obj.Parent
    if parent then
        for _, sibling in ipairs(parent:GetChildren()) do
            if sibling:IsA("TextLabel") then
                local txt = string.lower(sibling.Text)
                if string.find(txt, string.lower(LocalPlayer.Name))
                    or string.find(txt, string.lower(LocalPlayer.DisplayName))
                    or string.find(txt, "qqq") then
                    return true
                end
            end
        end

        local grandParent = parent.Parent
        if grandParent then
            for _, desc in ipairs(grandParent:GetDescendants()) do
                if desc:IsA("TextLabel") then
                    local txt = string.lower(desc.Text)
                    if string.find(txt, string.lower(LocalPlayer.Name))
                        or string.find(txt, string.lower(LocalPlayer.DisplayName))
                        or string.find(txt, "qqq") then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function updateIconObject(obj, device)
    if not device or not deviceIcons[device] then return end
    if looksLikeDeviceIcon(obj) then
        pcall(function()
            obj.Image = deviceIcons[device]
        end)
    end
end

local function hookContainer(container, device)
    if not container then return end

    for _, desc in ipairs(container:GetDescendants()) do
        updateIconObject(desc, device)
    end

    container.DescendantAdded:Connect(function(desc)
        task.wait(0.1)
        updateIconObject(desc, device)
        if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
            desc:GetPropertyChangedSignal("Image"):Connect(function()
                if looksLikeDeviceIcon(desc) and desc.Image ~= deviceIcons[device] then
                    pcall(function()
                        desc.Image = deviceIcons[device]
                    end)
                end
            end)
        end
    end)
end

local function applyDeviceSpoof(device)
    if not device then return end

    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local oldIndex = mt.__index

        mt.__index = newcclosure(function(self, key)
            if not checkcaller() then
                if self == UserInputService then
                    if key == "TouchEnabled" then
                        return device == "Mobile"
                    elseif key == "KeyboardEnabled" or key == "MouseEnabled" then
                        return device == "PC"
                    elseif key == "GamepadEnabled" then
                        return device == "PS5"
                    elseif key == "PreferredInput" then
                        if device == "PC" then return Enum.PreferredInput.KeyboardAndMouse end
                        if device == "PS5" then return Enum.PreferredInput.Gamepad end
                        if device == "Mobile" then return Enum.PreferredInput.Touch end
                    end
                elseif self == GuiService then
                    if key == "IsTenFootInterface" then
                        return device == "PS5"
                    end
                end
            end
            return oldIndex(self, key)
        end)

        setreadonly(mt, true)
    end)

    task.spawn(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
        hookContainer(playerGui, device)
        hookContainer(workspace, device)
        hookContainer(CoreGui, device)

        for _ = 1, 15 do
            if playerGui then
                for _, desc in ipairs(playerGui:GetDescendants()) do
                    updateIconObject(desc, device)
                end
            end
            for _, desc in ipairs(workspace:GetDescendants()) do
                if desc:IsA("SurfaceGui") or desc:IsA("BillboardGui") then
                    for _, child in ipairs(desc:GetDescendants()) do
                        updateIconObject(child, device)
                    end
                end
            end
            task.wait(1)
        end
    end)
end

if savedDevice then
    applyDeviceSpoof(savedDevice)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeviceSwitcherUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local function showDeviceBanner(text)
    local Banner = Instance.new("Frame", ScreenGui)
    Banner.Size = UDim2.new(0, 290, 0, 44)
    Banner.Position = UDim2.new(0.5, -145, 0, -60)
    Banner.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    Banner.BorderSizePixel = 0
    Instance.new("UICorner", Banner).CornerRadius = UDim.new(0, 12)

    local BStroke = Instance.new("UIStroke", Banner)
    BStroke.Color = Color3.fromRGB(255, 195, 0)
    BStroke.Thickness = 2

    local BLabel = Instance.new("TextLabel", Banner)
    BLabel.Size = UDim2.new(1, -16, 1, 0)
    BLabel.Position = UDim2.new(0, 8, 0, 0)
    BLabel.BackgroundTransparency = 1
    BLabel.Text = text
    BLabel.TextColor3 = Color3.fromRGB(255, 225, 90)
    BLabel.Font = Enum.Font.GothamBold
    BLabel.TextSize = 14

    TweenService:Create(Banner, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -145, 0, 18)
    }):Play()

    task.delay(4, function()
        if Banner and Banner.Parent then
            local hideTween = TweenService:Create(Banner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -145, 0, -60)
            })
            hideTween:Play()
            hideTween.Completed:Wait()
            Banner:Destroy()
        end
    end)
end

if savedDevice and deviceLabels[savedDevice] then
    task.spawn(function()
        task.wait(0.6)
        showDeviceBanner("تم الدخول كـ: " .. deviceLabels[savedDevice])
    end)
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 235)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -117)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(255, 195, 0)
MainStroke.Thickness = 2

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -90, 0, 46)
Title.Position = UDim2.new(0, 45, 0, 2)
Title.BackgroundTransparency = 1
Title.Text = "👑 VIP - اختر الجهاز (سيتم إعادة دخولك)"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(0, 10, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(205, 45, 45)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

local Footer = Instance.new("TextLabel", MainFrame)
Footer.Size = UDim2.new(1, 0, 0, 28)
Footer.Position = UDim2.new(0, 0, 1, -32)
Footer.BackgroundTransparency = 1
Footer.Text = "اضغط على الجهاز ليطلعك ويدخلك به تلقائياً • اضغط الأسد للإخفاء/الإظهار"
Footer.TextColor3 = Color3.fromRGB(165, 165, 175)
Footer.Font = Enum.Font.Gotham
Footer.TextSize = 11

local function createCard(titleText, subText, accentColor, posX, deviceKey)
    local Btn = Instance.new("TextButton", MainFrame)
    Btn.Size = UDim2.new(0, 130, 0, 125)
    Btn.Position = UDim2.new(0, posX, 0, 56)
    Btn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    Btn.Text = ""
    Btn.AutoButtonColor = true
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 12)

    local BtnStroke = Instance.new("UIStroke", Btn)
    BtnStroke.Color = accentColor
    BtnStroke.Thickness = 1.4
    BtnStroke.Transparency = 0.35

    local Label = Instance.new("TextLabel", Btn)
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = titleText .. "\n" .. subText
    Label.TextColor3 = accentColor
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 16

    Btn.MouseButton1Click:Connect(function()
        getgenv().SelectedDevice = deviceKey
        if queue_on_teleport then
            queue_on_teleport('getgenv().SelectedDevice = "' .. deviceKey .. '"')
        end
        showDeviceBanner("جاري نقلك إلى: " .. deviceLabels[deviceKey])
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

createCard("💻\nPC", "كمبيوتر", Color3.fromRGB(0, 215, 255), 18, "PC")
createCard("🎮\nPS5", "سوني", Color3.fromRGB(75, 145, 255), 160, "PS5")
createCard("📱\nMobile", "جوال", Color3.fromRGB(70, 235, 115), 302, "Mobile")

local LionButton = Instance.new("ImageButton", ScreenGui)
LionButton.Name = "LionToggleButton"
LionButton.Size = UDim2.new(0, 58, 0, 58)
LionButton.Position = UDim2.new(0, 18, 0.5, -29)
LionButton.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
LionButton.Image = "rbxassetid://11262730266"
LionButton.ScaleType = Enum.ScaleType.Crop
LionButton.Active = true
LionButton.Draggable = true
Instance.new("UICorner", LionButton).CornerRadius = UDim.new(1, 0)

local LionStroke = Instance.new("UIStroke", LionButton)
LionStroke.Color = Color3.fromRGB(255, 195, 0)
LionStroke.Thickness = 2.5

local LionFallback = Instance.new("TextLabel", LionButton)
LionFallback.Size = UDim2.new(1, 0, 1, 0)
LionFallback.BackgroundTransparency = 1
LionFallback.Text = "🦁"
LionFallback.TextSize = 30
LionFallback.Visible = not LionButton.IsLoaded

LionButton:GetPropertyChangedSignal("IsLoaded"):Connect(function()
    LionFallback.Visible = not LionButton.IsLoaded
end)

local moved = false
LionButton.MouseButton1Click:Connect(function()
    if not moved then
        MainFrame.Visible = not MainFrame.Visible
    end
    moved = false
end)
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function getNextServerJobId()
    local ok, res = pcall(function()
        local url = string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
            game.PlaceId
        )
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if ok and res and res.data then
        local list = {}
        for _, srv in ipairs(res.data) do
            if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                table.insert(list, srv.id)
            end
        end
        if #list > 0 then
            return list[math.random(1, #list)]
        end
    end
    return nil
end

local function switchDeviceAndServer(deviceKey)
    local labelText = (deviceLabels and deviceLabels[deviceKey]) or deviceKey
    getgenv().SelectedDevice = deviceKey
    getgenv().PreviousJobId = game.JobId
    getgenv().JoinedNewServer = true

    local persist = string.format([[
        getgenv().SelectedDevice = %q
        getgenv().PreviousJobId = %q
        getgenv().JoinedNewServer = true
    ]], deviceKey, game.JobId)

    if queue_on_teleport then
        queue_on_teleport(persist)
    elseif syn and syn.queue_on_teleport then
        syn.queue_on_teleport(persist)
    end

    if typeof(showBanner) == "function" then
        showBanner("جاري تدقيق السيرفرات والانتقال بوضع: " .. tostring(labelText))
    end

    local targetId = getNextServerJobId()
    local sent = pcall(function()
        if targetId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetId, LocalPlayer)
        else
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)

    if not sent then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end

-- ربط تلقائي لأزرار الأجهزة (سوني PS5، تلفون Mobile، كمبيوتر PC)
local function bindDeviceButtons()
    local root = (typeof(MainFrame) == "Instance" and MainFrame) or game:GetService("CoreGui"):FindFirstChild("DeviceSwitcherUI")
    if not root then return end

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("GuiButton") then
            local combined = string.lower(obj.Name .. " " .. (obj:IsA("TextButton") and obj.Text or ""))
            if string.find(combined, "ps5") or string.find(combined, "سوني") then
                obj.MouseButton1Click:Connect(function()
                    switchDeviceAndServer("PS5")
                end)
            elseif string.find(combined, "mobile") or string.find(combined, "تلفون") or string.find(combined, "جوال") then
                obj.MouseButton1Click:Connect(function()
                    switchDeviceAndServer("Mobile")
                end)
            elseif string.find(combined, "pc") or string.find(combined, "كمبيوتر") then
                obj.MouseButton1Click:Connect(function()
                    switchDeviceAndServer("PC")
                end)
            end
        end
    end
end

pcall(bindDeviceButtons)

-- Post-teleport server verification and banner
task.spawn(function()
    task.wait(0.8)
    local dev = getgenv().SelectedDevice
    if dev and typeof(showBanner) == "function" then
        local labelText = (deviceLabels and deviceLabels[dev]) or dev
        if getgenv().JoinedNewServer then
            local isNewSrv = (getgenv().PreviousJobId ~= nil and getgenv().PreviousJobId ~= game.JobId)
            if isNewSrv then
                showBanner("Joined new server | Mode: " .. tostring(labelText))
            else
                showBanner("Joined server | Mode: " .. tostring(labelText) .. " (Verified)")
            end
            getgenv().JoinedNewServer = false
        else
            showBanner("Current Mode: " .. tostring(labelText))
        end
    end
end)
