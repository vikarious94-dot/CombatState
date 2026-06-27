local _, CombatState = ...

local DEFAULT_ENTER_COMBAT_COLOR = { r = 1, g = 0.2, b = 0.2, a = 1 }
local DEFAULT_LEAVE_COMBAT_COLOR = { r = 0.2, g = 1, b = 0.2, a = 1 }

local function Clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

function CombatState:SetFontSize(fontSize)
    self:EnsureDB()
    CombatStateDB.fontSize = Clamp(fontSize, 12, 96)
    self:ApplySettings()
    self:UpdatePreview()
end

function CombatState:SetPosition(axis, value)
    self:EnsureDB()

    if axis == "x" then
        CombatStateDB.x = Clamp(value, -1000, 1000)
    elseif axis == "y" then
        CombatStateDB.y = Clamp(value, -1000, 1000)
    end

    self:ApplySettings()
    self:UpdatePreview()
end

function CombatState:SetCombatMessage(messageType, message)
    self:EnsureDB()

    if message == "" then
        if messageType == "enter" then
            message = self.defaults.enterCombatMessage
        elseif messageType == "leave" then
            message = self.defaults.leaveCombatMessage
        end
    end

    if messageType == "enter" then
        CombatStateDB.enterCombatMessage = message
        self:ApplySettings()
        self:PreviewEnterCombat()
    elseif messageType == "leave" then
        CombatStateDB.leaveCombatMessage = message
        self:ApplySettings()
        self:PreviewLeaveCombat()
    end
end

function CombatState:SetCombatColor(messageType, red, green, blue, alpha)
    local color = self:GetCombatColor(messageType)

    color.r = Clamp(red, 0, 1)
    color.g = Clamp(green, 0, 1)
    color.b = Clamp(blue, 0, 1)
    color.a = Clamp(alpha or 1, 0, 1)

    self:ApplySettings()

    if messageType == "leave" then
        self:PreviewLeaveCombat()
    else
        self:PreviewEnterCombat()
    end
end

function CombatState:ResetCombatColor(messageType)
    local defaultColor = messageType == "leave" and DEFAULT_LEAVE_COMBAT_COLOR or DEFAULT_ENTER_COMBAT_COLOR

    self:SetCombatColor(messageType, defaultColor.r, defaultColor.g, defaultColor.b, defaultColor.a)
end

function CombatState:OpenCombatColorPicker(messageType)
    local color = self:GetCombatColor(messageType)
    local previousColor = { r = color.r, g = color.g, b = color.b, a = color.a }
    local usesModernColorPicker = ColorPickerFrame.SetupColorPickerAndShow ~= nil

    local function GetPickerAlpha()
        if usesModernColorPicker and ColorPickerFrame.GetColorAlpha then
            return ColorPickerFrame:GetColorAlpha()
        end

        return 1 - (ColorPickerFrame.opacity or 0)
    end

    local function UpdateColor()
        local red, green, blue = ColorPickerFrame:GetColorRGB()
        local alpha = GetPickerAlpha()

        self:SetCombatColor(messageType, red, green, blue, alpha)
    end

    local function CancelColor()
        self:SetCombatColor(messageType, previousColor.r, previousColor.g, previousColor.b, previousColor.a)
    end

    if usesModernColorPicker then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = color.r,
            g = color.g,
            b = color.b,
            opacity = color.a,
            hasOpacity = true,
            swatchFunc = UpdateColor,
            opacityFunc = UpdateColor,
            cancelFunc = CancelColor,
        })

        return
    end

    ColorPickerFrame.func = UpdateColor
    ColorPickerFrame.opacityFunc = UpdateColor
    ColorPickerFrame.cancelFunc = CancelColor
    ColorPickerFrame.hasOpacity = true
    ColorPickerFrame.opacity = 1 - color.a
    ColorPickerFrame.previousValues = previousColor
    ColorPickerFrame:SetColorRGB(color.r, color.g, color.b)
    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
end
