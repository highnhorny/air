--!native
--!optimize 2

if getgenv().AirHubV2Loaded or getgenv().AirHubV2Loading then return end
getgenv().AirHubV2Loading = true

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function SecureLoad(url)
    local s, r = pcall(function() return loadstring(game:HttpGet(url))() end)
    return s and r or nil
end

local GUI = SecureLoad("https://raw.githubusercontent.com/Exunys/AirHub-V2/main/src/UI%20Library.lua")
local ESP = SecureLoad("https://raw.githubusercontent.com/Exunys/Exunys-ESP/main/src/ESP.lua")
local Aimbot = SecureLoad("https://raw.githubusercontent.com/Exunys/Aimbot-V3/main/src/Aimbot.lua")

if not (GUI and ESP and Aimbot) then return end

local Aimbot_Settings = Aimbot.Settings
Aimbot_Settings.Smoothing = 0.05

local function IsValidStream(player)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        return player.Character.HumanoidRootPart.ReceiveAge == 0 
    end
    return false
end

local function GetBezierPoint(t, p0, p1, p2)
    return (1 - t)^2 * p0 + 2 * (1 - t) * t * p1 + t^2 * p2
end

local function SmoothAim(targetPos: Vector2)
    local mouse = UserInputService:GetMouseLocation()
    local mid = mouse:Lerp(targetPos, 0.5)
    local r = math.random
    local control = mid + Vector2.new(r(-6,6), r(-6,6))
    local nextStep = GetBezierPoint(Aimbot_Settings.Smoothing, mouse, control, targetPos)
    local delta = nextStep - mouse
    mousemoverel(delta.X, delta.Y)
end

local MainFrame = GUI:Load()
local General, GeneralSignal = MainFrame:Tab("General")
local _Aimbot = MainFrame:Tab("Aimbot")
local _Settings = MainFrame:Tab("Settings")

local AimSec = _Aimbot:Section({Name = "Advanced Aim", Side = "Left"})
AimSec:Toggle({
    Name = "Bezier Smoothing",
    Flag = "Aim_Bezier",
    Default = true,
    Callback = function(val) Aimbot_Settings.UseBezier = val end
})

RunService.RenderStepped:Connect(function()
    if Aimbot_Settings.Enabled and Aimbot.Target then
        if IsValidStream(Aimbot.TargetPlayer) then
            if Aimbot_Settings.UseBezier then
                SmoothAim(Aimbot.Target)
            end
        end
    end
end)

ESP.Load()
Aimbot.Load()
getgenv().AirHubV2Loaded = true
getgenv().AirHubV2Loading = nil
GUI:Close()
