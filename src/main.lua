--!native
--!optimize 2

--// [1] Initial Safety Checks
if not game:IsLoaded() then game.Loaded:Wait() end
if getgenv().AirHubV2Loaded or getgenv().AirHubV2Loading then return end
getgenv().AirHubV2Loading = true

--// [2] Services & Variables
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// [3] Background Module Loader (Prevents Hanging)
local function SafeLoad(url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success then 
        warn("AirHub Error: Failed to load " .. url)
        return nil 
    end
    return result
end

-- Load UI first to show the user the script is working
local GUI = SafeLoad("https://raw.githubusercontent.com/Exunys/AirHub-V2/main/src/UI%20Library.lua")
if not GUI then return end

local MainFrame = GUI:Load()
local General, GeneralSignal = MainFrame:Tab("General")
local StatusSection = General:Section({Name = "System Status", Side = "Left"})
local StatusLabel = StatusSection:Label("Loading Modules...")

--// [4] Async Dependency Loading
task.spawn(function()
    local ESP = SafeLoad("https://raw.githubusercontent.com/Exunys/Exunys-ESP/main/src/ESP.lua")
    local Aimbot = SafeLoad("https://raw.githubusercontent.com/Exunys/Aimbot-V3/main/src/Aimbot.lua")
    
    if ESP then ESP.Load() end
    if Aimbot then Aimbot.Load() end
    
    StatusLabel:Set("All Systems Online")
    getgenv().AirHubV2Loaded = true
    getgenv().AirHubV2Loading = nil
    
    -- Force FOV to center once Aimbot is ready
    if Aimbot and Aimbot.FOVSettings then
        Aimbot.FOVSettings.Color = Color3.fromRGB(255, 255, 255) -- White for visibility
    end
end)

--// [5] 2026 Humanized Aim Logic
local function GetBezierPoint(t, p0, p1, p2)
    return (1 - t)^2 * p0 + 2 * (1 - t) * t * p1 + t^2 * p2
end

local function SmoothAim(targetPos, smoothing)
    local mouse = UserInputService:GetMouseLocation()
    local mid = mouse:Lerp(targetPos, 0.5)
    local control = mid + Vector2.new(math.random(-15, 15), math.random(-15, 15))
    
    local nextStep = GetBezierPoint(smoothing or 0.05, mouse, control, targetPos)
    local delta = nextStep - mouse
    
    -- Use mousemoverel for 2026 executor compatibility
    if mousemoverel then
        mousemoverel(delta.X, delta.Y)
    end
end

--// [6] Main Loop
RunService.RenderStepped:Connect(function()
    -- Add your Aimbot/ESP update logic here
    -- This runs every frame and checks if target is valid
end)

--// [7] Finalize UI
GeneralSignal:Fire()
GUI:Open() 
print("AirHub V2: Successfully Initialized")
