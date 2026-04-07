local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- // Signal Class (Standard)
local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({_c = {}}, Signal) end
function Signal:Connect(f)
    self._c[#self._c+1] = f
    return {Disconnect = function()
        local i = table.find(self._c, f)
        if i then table.remove(self._c, i) end
    end}
end
function Signal:Fire(...) for _, f in next, self._c do f(...) end end

-- // Modern Theme (Light Mode)
local Theme = {
    Background = Color3.fromRGB(245, 246, 250), -- Soft White
    Surface    = Color3.fromRGB(255, 255, 255), -- Pure White
    Accent     = Color3.fromRGB(116, 125, 246), -- Modern Indigo
    Text       = Color3.fromRGB(47, 54, 64),    -- Deep Gray
    Secondary  = Color3.fromRGB(220, 221, 225), -- Borders/Dividers
    Hover      = Color3.fromRGB(240, 240, 245)
}

local objects = {}
local hovering = nil

-- // Utility: Bounding Box Check
local function inside(o, m)
    local p, s = o.Position, o.Size
    return m.X >= p.X and m.Y >= p.Y and m.X <= p.X + s.X and m.Y <= p.Y + s.Y
end

-- // Input Logic
UIS.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local m = input.Position

    for o in next, objects do
        if o.Visible and inside(o, m) then
            if hovering ~= o then
                if hovering then hovering.MouseLeave:Fire() end
                hovering = o
                o.MouseEnter:Fire()
            end
            o.MouseMoved:Fire(m)
        elseif hovering == o then
            hovering = nil
            o.MouseLeave:Fire()
        end
    end
end)

-- Combined Input Handler
local function handleInput(input, isBegan)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local m = UIS:GetMouseLocation()

    for o in next, objects do
        if isBegan then
            if o.Visible and inside(o, m) then
                o._down = true
                o.MouseDown:Fire()
            end
        else
            if o._down then
                o._down = nil
                if inside(o, m) then o.Click:Fire() end
                o.MouseUp:Fire()
            end
        end
    end
end

UIS.InputBegan:Connect(function(i) handleInput(i, true) end)
UIS.InputEnded:Connect(function(i) handleInput(i, false) end)

-- // UI Class
local UI = {}

function UI.new(type)
    local d = Drawing.new(type or "Square")
    d.Visible = false
    
    local o = {
        Instance = d,
        Visible = false,
        Position = Vector2.zero,
        Size = Vector2.new(100, 100),
        
        -- Signals
        MouseEnter = Signal.new(),
        MouseLeave = Signal.new(),
        MouseMoved = Signal.new(),
        MouseDown  = Signal.new(),
        MouseUp    = Signal.new(),
        Click      = Signal.new()
    }

    -- Default Styling
    if type == "Square" then
        d.Thickness = 1
        d.Filled = true
        d.Color = Theme.Surface
    end

    function o:Set(prop, v)
        if self[prop] ~= nil then self[prop] = v end
        -- Map specific drawing properties
        if prop == "Visible" then self.Instance.Visible = v
        elseif prop == "Position" then self.Instance.Position = v
        elseif prop == "Size" then self.Instance.Size = v
        elseif prop == "Color" then self.Instance.Color = v
        else self.Instance[prop] = v end
    end

    -- Modern Interactive Transitions
    o.MouseEnter:Connect(function()
        o:Set("Color", Theme.Hover)
    end)
    
    o.MouseLeave:Connect(function()
        o:Set("Color", Theme.Surface)
    end)

    function o:Destroy()
        objects[self] = nil
        self.Instance:Remove()
    end

    objects[o] = true
    return o
end

-- // Modern Dragging (with smoothing)
function UI.makeDraggable(o)
    local dragging, startPos, startMouse
    
    o.MouseDown:Connect(function()
        dragging = true
        startMouse = UIS:GetMouseLocation()
        startPos = o.Position
    end)

    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - startMouse
            o:Set("Position", startPos + delta)
        end
    end)

    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

return {UI = UI, Theme = Theme}
