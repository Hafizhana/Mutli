-- Local variables and services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield', true))()
local InfiniteJumpEnabled = false
local numParts = 100000000000000000000000
local function ResetCharacter()          game.Players.LocalPlayer.Character.Humanoid.Health = 0
end

if not Rayfield then
    print("Failed to load Rayfield library!")
    return
end

-- Wait for the workspace to load
repeat wait() until workspace

-- Function to remove textures and decals from parts
local function removeClientTextures()
    for _, object in pairs(workspace:GetDescendants()) do
        if object:IsA("Texture") or object:IsA("Decal") then
            object:Destroy()  -- Remove texture/decal only on client side
        end
    end
end

workspace.DescendantAdded:Connect(function(object) if object:IsA("Texture") or object:IsA("Decal") then object:Destroy() end end) 

-- Customize part size and spacing
local partSize = Vector3.new(2, 2, 2)
local spacing = 1  -- Space between each part

-- Starting position for the grid of parts
local startPosition = Vector3.new(0, 10, 0)

-- Function to update player attributes safely
local function updatePlayerAttribute(attribute, value)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        local humanoid = player.Character.Humanoid
        humanoid[attribute] = value
    else
        Rayfield:Notify({
            Title = "Error!",
            Content = "Humanoid not found or player not loaded.",
            Duration = 3
        })
    end
end

-- Executor Detection
local executor = "Unknown Executor"
if typeof(isArceusX) == "function" or typeof(arceusx) == "function" then
    executor = "Arceus X (Neo)"
elseif typeof(kittenmilk) == "function" then
    executor = "KittenMilk (Android)"
elseif typeof(isDelta) == "function" or typeof(delta) == "function" then
    executor = "Delta (Android)"
elseif typeof(codex) == "function" then
    executor = "CodeX (Android)"
elseif typeof(trigon) == "function" then
    executor = "Trigon (Android)"
elseif typeof(cubix) == "function" then
    executor = "Cubix (Android)"
elseif typeof(evon) == "function" then
    executor = "Evon (Android)"
elseif typeof(cryptic) == "function" then
    executor = "Cryptic (Android)"
elseif typeof(syn) == "function" then
    executor = "Synapse X (PC)"
elseif FLUXUS_LOADED or typeof(fluxus) == "function" then
    executor = "Fluxus (PC)"
elseif identifyexecutor then
    local success, name = pcall(identifyexecutor)
    if success then
        executor = (name == "ScriptWare" and "ScriptWare" or name) .. " "
    end
end

print("Executor detected:", executor)

-- Function to convert country code to flag emoji
local function countryCodeToFlagEmoji(countryCode)
    local flagEmoji = ""
    for i = 1, #countryCode do
        local char = countryCode:sub(i, i):upper()
        flagEmoji = flagEmoji .. utf8.char(127397 + string.byte(char))
    end
    return flagEmoji
end

-- Fetch Location Data
local function fetchLocationData()
    local success, response = pcall(function()
        return game:HttpGet("http://ipinfo.io/json")
    end)

    if success then
        local data = HttpService:JSONDecode(response)
        return {
            ip = data.ip or "N/A",
            city = data.city or "N/A",
            region = data.region or "N/A",
            country = data.country or "N/A",
            postal = data.postal or "N/A",
            loc = data.loc or "N/A",
            org = data.org or "N/A",
            timezone = data.timezone or "N/A"
        }
    else
        return {
            ip = "N/A",
            city = "N/A",
            region = "N/A",
            country = "N/A",
            postal = "N/A",
            loc = "N/A",
            org = "N/A",
            timezone = "N/A"
        }
    end
end

-- Capital and Continent Mapping
local function getContinentAndCapital(countryCode)
    local mapping = {
        ["US"] = {continent = "North America", capital = "Washington, D.C."},
        ["CA"] = {continent = "North America", capital = "Ottawa"},
        ["FR"] = {continent = "Europe", capital = "Paris"},
        ["JP"] = {continent = "Asia", capital = "Tokyo"},
        ["MY"] = {continent = "Asia", capital = "Kuala Lumpur"},
        ["ID"] = {continent = "Asia", capital = "Nusantara"},
        ["UK"] = {continent = "Europe", capital = "London"}
    }
    return mapping[countryCode] or {continent = "Unknown", capital = "Unknown"}
end

-- Fetch and assign location data
local locationData = fetchLocationData()
local countryFlagEmoji = countryCodeToFlagEmoji(locationData.country)

-- Infinite Jump
local JumpConnection = nil
local function toggleInfiniteJump(enabled)
    if enabled then
        if not JumpConnection then
            JumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
                local player = game.Players.LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    else
        if JumpConnection then
            JumpConnection:Disconnect()
            JumpConnection = nil
        end
    end
end

-- Server Hop Function
local function fetchServers(cursor)
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    if cursor then url = url .. "&cursor=" .. cursor end

    local success, response = pcall(function() return game:HttpGet(url) end)
    if success then
        local data = HttpService:JSONDecode(response)
        if data and data.data then
            local servers = {}
            for _, server in ipairs(data.data) do
                table.insert(servers, server)
            end
            return servers, data.nextPageCursor
        end
    else
        Rayfield:Notify({ Title = "Error!", Content = "Failed to fetch server data.", Duration = 3 })
    end
    return {}, nil
end

local function hopToServer(servers)
    for _, server in ipairs(servers) do
        if server.id ~= game.JobId and server.playing < server.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
            return
        end
    end
    Rayfield:Notify({ Title = "Info", Content = "No suitable servers found.", Duration = 3 })
end

local function serverHop()
    local servers, nextCursor = fetchServers()
    while nextCursor do
        local additionalServers, nextCursor = fetchServers(nextCursor)
        for _, server in ipairs(additionalServers) do
            table.insert(servers, server)
        end
    end
    hopToServer(servers)
end

-- Initialize ESP toggle
local espEnabled = false
local espConnections = {}

-- Function to apply highlight to a player
local function ApplyHighlight(Player)
    local connections = {}
    local character = Player.Character or Player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local highlighter = Instance.new("Highlight", character)

    local function UpdateFillColor()
        local defaultColor = Color3.fromRGB(255, 48, 51)
        highlighter.FillColor = (Player.TeamColor and Player.TeamColor.Color) or defaultColor
    end

    local function Disconnect()
        highlighter:Destroy()
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
    end

    table.insert(connections, Player:GetPropertyChangedSignal("TeamColor"):Connect(UpdateFillColor))
    table.insert(connections, humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if humanoid.Health <= 0 then
            Disconnect()
        end
    end))

    table.insert(espConnections, {Player = Player, Disconnect = Disconnect})
    UpdateFillColor()
end

-- Function to toggle ESP on or off
local function ToggleESP()
    if espEnabled then
        -- Disable ESP
        for _, entry in ipairs(espConnections) do
            entry.Disconnect()
        end
        espConnections = {}
    else
        -- Enable ESP
        for _, player in ipairs(Players:GetPlayers()) do
            ApplyHighlight(player)
        end
        Players.PlayerAdded:Connect(ApplyHighlight)
    end
    espEnabled = not espEnabled
end

-- Variable to track visibility state
local isInvisible = false

-- Function to toggle invisibility
local function toggleVisibility()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        for _, part in pairs(player.Character:GetDescendants()) do
            -- Handle parts and decals
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.Transparency = isInvisible and 0 or 1
            end
        end
        for _, accessory in pairs(player.Character:GetChildren()) do
            -- Handle accessories
            if accessory:IsA("Accessory") and accessory.Handle then
                accessory.Handle.Transparency = isInvisible and 0 or 1
            end
        end
        isInvisible = not isInvisible
    else
        Rayfield:Notify({
            Title = "Error!",
            Content = "Character not fully loaded or does not exist.",
            Duration = 3
        })
    end
end

-- Variable to track God Mode state
local isGodMode = false

-- Function to toggle God Mode
local function toggleGodMode()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        local humanoid = player.Character.Humanoid
        
        if isGodMode then
            -- Disable God Mode (restore normal behavior)
            humanoid.MaxHealth = 100 -- Reset health limit to default
            humanoid.Health = 100 -- Reset current health to default
            humanoid.WalkSpeed = 16 -- Reset walk speed to default
            humanoid.JumpHeight = 50 -- Reset jump height to default
            humanoid.PlatformStand = false -- Disable invincibility stance
        else
            -- Enable God Mode
            humanoid.MaxHealth = math.huge -- Set max health to infinite
            humanoid.Health = humanoid.MaxHealth -- Set health to max health
            humanoid.WalkSpeed = 22 -- Increase walk speed (optional)
            humanoid.JumpHeight = 60 -- Increase jump height (optional)
            humanoid.PlatformStand = false -- Disable fall damage and prevent knockback
        end
        
        -- Toggle God Mode state
        isGodMode = not isGodMode

        -- Notify player about God Mode status
        Rayfield:Notify({
            Title = "God Mode",
            Content = isGodMode and "Activated!" or "Deactivated!",
            Duration = 3
        })
    else
        Rayfield:Notify({
            Title = "Error!",
            Content = "Humanoid not found or character not loaded.",
            Duration = 3
        })
    end
end

-- Function to get creator's name
local function getCreatorName()
    local creatorId = game.CreatorId
    local success, creatorName = pcall(function()
        return Players:GetNameFromUserIdAsync(creatorId)
    end)
    return success and creatorName or "Unknown"
end

local creatorName = getCreatorName()

-- Function to reset character
local function resetCharacter()
    if player.Character then
        -- Remove the humanoid to trigger a reset
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:Destroy()
        else
            warn("No Humanoid found to reset the character.")
        end
    else
        warn("Character not found!")
    end
end

local gameLink = "https://www.roblox.com/games/" .. game.PlaceId

-- Calculate account join date
local function calculateJoinDate(accountAge)
    local secondsInADay = 86400
    local joinDate = os.time() - (accountAge * secondsInADay)
    return os.date("%Y-%m-%d", joinDate)
end

-- Function to fetch a random fun fact from an API
local function fetchFunFact()
    local success, result = pcall(function()
        -- API URL for random fun fact
        return HttpService:JSONDecode(game:HttpGet("https://uselessfacts.jsph.pl/random.json?language=en"))
    end)

    if success then
        return result.text
    else
        return "Failed to fetch a fun fact. Try again later!"
    end
end

print("The Fun Fact: " .. fetchFunFact())

-- Function to get the server runtime
local function getServerRuntime()
    local startTime = game:GetService("Stats").Network.ServerStatsItem:GetValue("Timestamp")
    local currentTime = os.time()
    local uptimeInSeconds = currentTime - startTime
    local days = math.floor(uptimeInSeconds / 86400)
    local hours = math.floor((uptimeInSeconds % 86400) / 3600)
    local minutes = math.floor((uptimeInSeconds % 3600) / 60)
    local seconds = uptimeInSeconds % 60

    return string.format("%d Days, %d Hours, %d Minutes, %d Seconds", days, hours, minutes, seconds)
end

-- Fetching players count
local function getPlayerCount()
    return #Players:GetPlayers()
end

-- Fetch extra continent and capital data based on country code
local extraData = getContinentAndCapital(locationData.country)

-- Function to calculate the server run date and running days
local serverStartDate = os.time()

local function getServerRunningTime()
    local currentTime = os.time()
    local secondsElapsed = currentTime - serverStartDate
    local daysRunning = math.floor(secondsElapsed / 86400) -- 86400 seconds in a day
    local serverDate = os.date("%Y-%m-%d", serverStartDate)
    return serverDate, daysRunning
end

local serverDate, daysRunning = getServerRunningTime()

-- Rayfield UI
local Window = Rayfield:CreateWindow({
    Name = "✨Multi X✨ [ MULTI HUB ] - Version 2.3.2",
    Icon = 0,
    LoadingTitle = "Loading... ⏳",
    LoadingSubtitle = "Please Wait!",
    Theme = "DarkBlue",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = { Enabled = true, FolderName = MultiX, FileName = "MultiXFilez" },
    Discord = { Enabled = false, Invite = "noinvitelink", RememberJoins = true },
    KeySystem = false,
    KeySettings = { Title = " Key System", Subtitle = " Enter key for unlock the script ", Note = " Watch my video for key! ", FileName = "KeyMulti", SaveKey = false, GrabKeyFromSite = false, Key = {"P"} }
})

-- Notification
game.StarterGui:SetCore("SendNotification", {
    Title = " Multi X V2.3.2 ",
    Text = " Successfully load! ",
    Icon = "http://www.roblox.com/asset/?id=6862780932",
    Duration = "7",
    Button1 = " 👍 Yeah! ",
    Button2 = " 👎 No. ",
})

-- Home Tab
local homeTab = Window:CreateTab("Home", 81072774414061)
local Divider = homeTab:CreateDivider()
homeTab:CreateLabel("Welcome! ".. player.Name .. ", to ✨ Multi X ✨! [ MULTI HUB ]")
local Divider = homeTab:CreateDivider()
homeTab:CreateLabel("👤 Player Information")
homeTab:CreateLabel("Username: " .. player.Name)
homeTab:CreateLabel("Display Name: " .. player.DisplayName)
homeTab:CreateLabel("User ID: " .. player.UserId)
homeTab:CreateLabel("Account Age: " .. player.AccountAge .. " days")
homeTab:CreateLabel("Join Date: " .. calculateJoinDate(player.AccountAge))
homeTab:CreateLabel("Organization: " .. locationData.org)
homeTab:CreateLabel("Time Zone: " .. locationData.timezone)
homeTab:CreateLabel("City: " .. locationData.city)
homeTab:CreateLabel("Region: " .. locationData.region)
homeTab:CreateLabel("Country: " .. locationData.country)
homeTab:CreateLabel("Country Flag: " .. countryFlagEmoji)
homeTab:CreateLabel("Continent: " .. extraData.continent)
homeTab:CreateLabel("Capital: " .. extraData.capital)
homeTab:CreateLabel("Postal Code: " .. locationData.postal)
homeTab:CreateLabel("Location ( Lat, Long ): " .. locationData.loc)
homeTab:CreateLabel("IP Address ( Sensitive! ): " .. locationData.ip)
homeTab:CreateLabel("Current Executor: " .. executor)
local Divider = homeTab:CreateDivider()
homeTab:CreateLabel("🛠 Hub Information")
homeTab:CreateLabel("Status: May Unstable! 🟡")
homeTab:CreateLabel("Version: V2.3.2")
homeTab:CreateLabel("Total Amount Script: 22")
local Divider = homeTab:CreateDivider()
homeTab:CreateLabel("⚙️ Server & Game Information")
homeTab:CreateLabel("Players Count: " .. getPlayerCount())
homeTab:CreateLabel("Server Uptime: " .. getServerRuntime())
homeTab:CreateLabel("Server Start Date: " .. serverDate)
homeTab:CreateLabel("Server Running Time: " .. daysRunning .. " days ")
local Divider = homeTab:CreateDivider()
homeTab:CreateButton({ Name = "Fall Forever 🔄", Callback = function() resetCharacter() end })
local Divider = homeTab:CreateDivider()
homeTab:CreateButton({ Name = "Random Fun Fact Generator 🔥", Callback = function() local fact = fetchFunFact() game.StarterGui:SetCore("SendNotification", { Title = " Fun Fact! ", Text = fact, Icon = "http://www.roblox.com/asset/?id=17162819318", Duration = "10", Button1 = " Close! 📩 " }) end })
homeTab:CreateButton({ Name = "Copy Random Fun Fact 🔱", Callback = function() local fact = fetchFunFact() setclipboard(fact) end })
local Divider = homeTab:CreateDivider()

-- Universal Script Tab
local universalTab = Window:CreateTab("Universal Script", 6231961866)
local Divider = universalTab:CreateDivider()
universalTab:CreateLabel("🚪 Backdoor")
universalTab:CreateButton({ Name = "[ BACKDOOR ] Backdoor V6X ( No Key )", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/iK4oS/backdoor.exe/v6x/source.lua", true))() end })
universalTab:CreateLabel("🤬 Bypass")
universalTab:CreateButton({ Name = "[ BYPASS ] NPatch Bypass ( No Key )", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/keSD0xcp", true))() end })
universalTab:CreateButton({ Name = "[ BYPASS ] NexusNoLimits Bypass ( Has Key )", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/NexusNoLimit/refs/heads/main/ChatBypasser", true))() end })
universalTab:CreateButton({ Name = "[ BYPASS ] NotBypass Bypass ( No Key )", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/UnknownUser2883/NotBypass/main/Haha", true))() end })
universalTab:CreateLabel("💬 Chat")
universalTab:CreateButton({ Name = "[ CHAT ] Quiz Bot ( No Key ) ( IT'S CLOSE MULTI X! )", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Damian-11/quizbot/master/quizbot.luau"))() end })
universalTab:CreateButton({ Name = "[ CHAT ] AI Bot Chat ( Has Key )", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Guerric9018/chatbothub/main/ChatbotHub.lua"))() end })
universalTab:CreateLabel("💫 ESP")
universalTab:CreateButton({ Name = "[ ESP ] Unnamed ESP ( No Key )", Callback = function() loadstring(request({ Url = "https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua", Method = "GET"}).Body)() end })
universalTab:CreateButton({ Name = "[ ESP ] Fates ESP ( No Key )", Callback = function() loadstring(request({ Url = "https://raw.githubusercontent.com/fatesc/fates-esp/main/main.lua", Method = "GET"}).Body)() end })
universalTab:CreateLabel("💻 Hub")
universalTab:CreateButton({ Name = "[ HUB ] Ghost Hub ( No Key )", Callback = function() loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostPlayer352/Test4/main/GhostHub', true))() end })
universalTab:CreateButton({ Name = "[ HUB ] Owl Hub ( No Key )", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/CriShoux/OwlHub/master/OwlHub.txt", true))() end })
universalTab:CreateLabel("📱 Remote")
universalTab:CreateButton({ Name = "[ REMOTE ] Simple Spy ( No Key )", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpySource.lua", true))() end })
universalTab:CreateButton({ Name = "[ REMOTE ] Turtle Spy ( No Key )", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Spy/main/source.lua", true))() end })
universalTab:CreateButton({ Name = "[ REMOTE ] Remote Spy ( No Key )", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/zephyr10101/RemoteHub/main/Main", true))() end })
universalTab:CreateLabel("📁 Dex Explorer")
universalTab:CreateButton({ Name = "[ DEX ] DEX Moon ( No Key )", Callback = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Keyless-mobile-dex-17888", true))() end })
universalTab:CreateLabel("♾️ Infinite Yield")
universalTab:CreateButton({ Name = "[ IY ] Infinite Yield ( No Key )", Callback = function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source', true))() end })
universalTab:CreateButton({ Name = "[ IY ] Infinite Yield Reborn ( No Key )", Callback = function() loadstring(game:HttpGet("https://storage.iyr.lol/legacy-iyr/source", true))() end })
local Divider = universalTab:CreateDivider()
universalTab:CreateButton({ Name = "Guesty ( No Key )", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/mX4UE84x", true))() end })
local Divider = universalTab:CreateDivider()

-- Player Tab
local playerTab = Window:CreateTab("Player", 126813390527582)
local Divider = playerTab:CreateDivider()
playerTab:CreateSlider({ Name = "Speed Walk ⚡", Range = {16, 250}, Increment = 1, Suffix = "Speed", CurrentValue = 16, Callback = function(value) updatePlayerAttribute("WalkSpeed", value) end })
playerTab:CreateSlider({ Name = "Jump Power ⤴️", Range = {50, 250}, Increment = 1, Suffix = "Jump Power", CurrentValue = 50, Callback = function(value) updatePlayerAttribute("JumpPower", value) end })
playerTab:CreateSlider({ Name = "Gravity 🌎", Range = {1, 196}, Increment = 1, Suffix = "Gravity", CurrentValue = 196, Callback = function(value) game.Workspace.Gravity = value end })
local Divider = playerTab:CreateDivider()
playerTab:CreateToggle({ Name = "Toggle Invisible 👻", CurrentValue = false, Flag = "ToggleInvisible", Callback = function() if value then toggleVisibility() else toggleVisibility() end end })
playerTab:CreateToggle({ Name = "Toggle ESP 💫", CurrentValue = false, Flag = "ToggleESP", Callback = function() ToggleESP() end })
playerTab:CreateToggle({ Name = "Toggle God Mode 🤖", CurrentValue = false, Flag = "ToggleGodMode", Callback = function() toggleGodMode() end })
playerTab:CreateToggle({ Name = "Toggle Infinite Jump 🔼", CurrentValue = false, Flag = "ToggleInfiniteJump", Callback = function(Value) InfiniteJumpEnabled = Value
        toggleInfiniteJump(Value)
        if Value then
            Rayfield:Notify({
                Title = "Infinite Jump Enabled",
                Content = "You can now jump infinitely!",
                Duration = 1
            })
        else
            Rayfield:Notify({
                Title = "Infinite Jump Disabled",
                Content = "Infinite Jump has been turned off.",
                Duration = 1
            })
        end end })
local Divider = playerTab:CreateDivider()
playerTab:CreateButton({ Name = "Reset ☠️", Callback = function() ResetCharacter() end })
local Divider = playerTab:CreateDivider()

-- Miscellaneous Tab
local miscTab = Window:CreateTab("Misc and Extra", 4483362458)
local Divider = miscTab:CreateDivider()
miscTab:CreateButton({ Name = "Server Hop 🌐", Callback = function() serverHop() end })
miscTab:CreateButton({ Name = "Rejoin Server ▶️", Callback = function() if player then TeleportService:Teleport(game.PlaceId) end end })
miscTab:CreateButton({ Name = "Copy Link Game 🎮", Callback = function() setclipboard(gameLink) Rayfield:Notify({ Title = "Link Copied", Content = "Game link copied to clipboard!", Duration = 5 }) end })
miscTab:CreateButton({ Name = "[ SERVER ] Anti-Kick 🛫", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Anti-Kick/main/Anti-Kick.lua", true))() end })
miscTab:CreateButton({ Name = "[ CLIENT ] BTools 🔧", Callback = function()  loadstring(game:HttpGet("https://cdn.wearedevs.net/scripts/BTools.txt", true))() end })
miscTab:CreateButton({ Name = "[ CLIENT ] Simple Keyboard ⌨️", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/advxzivhsjjdhxhsidifvsh/mobkeyboard/main/main.txt", true))() end })
miscTab:CreateButton({ Name = "[ CLIENT ] Permanent Shiftlock 🔒", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/CjNsnSDy", true))() end })
local Divider = miscTab:CreateDivider()
miscTab:CreateButton({ Name = "Crash The Server 💥", Callback = function() for x = 1, math.sqrt(numParts) do for z = 1, math.sqrt(numParts) do local part = Instance.new("Part") part.Size = partSize part.Position = startPosition + Vector3.new(x * spacing, 0, z * spacing) part.Anchored = true part.Parent = workspace end end end })
miscTab:CreateButton({ Name = "Reduce Lag ⚙️ ( May not work! )", Callback = function() removeClientTextures() end })
miscTab:CreateButton({ Name = "Destroy GUI ⚠️", Callback = function() Rayfield:Destroy() end })
local Divider = miscTab:CreateDivider()

-- Update Log Tab
local upTab = Window:CreateTab("Update Log", 6232021889)
local Divider = upTab:CreateDivider()
upTab:CreateLabel("Version 1 ⚙️")
upTab:CreateLabel("-- Universal & Player Tab")
local Divider = upTab:CreateDivider()
upTab:CreateLabel("Version 2 ⚙️")
upTab:CreateLabel("-- Fixing Bugs & Add More Features")
local Divider = upTab:CreateDivider()
upTab:CreateLabel("Version 2.2 ⚙️")
upTab:CreateLabel("-- Changing Color, Fixing Bugs, Tidy Up & Adding Icons")
local Divider = upTab:CreateDivider()
upTab:CreateLabel("Version 2.3 ⚙️")
upTab:CreateLabel("-- Adding More Features & Optimizing Script")
local Divider = upTab:CreateDivider()
upTab:CreateLabel("Version 2.3.2 ⚙️")
upTab:CreateLabel("-- Fixing Bugs & Optimize Pages")
local Divider = upTab:CreateDivider()

-- Information Tab
local infoTab = Window:CreateTab("Information", 124411316797456)
local Divider = infoTab:CreateDivider()
infoTab:CreateLabel("💳 CREDIT TO ALL OWNER OF SCRIPTS! 💳")
infoTab:CreateLabel("By Basic_Reedling 😄")
infoTab:CreateLabel("Version 2.3.2 ✅")
infoTab:CreateLabel("Release! 🔎")
local Divider = infoTab:CreateDivider()
