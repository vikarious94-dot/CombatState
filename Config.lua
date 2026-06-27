local _, CombatState = ...

local configFrame
local fontSizeInput
local fontSizeSlider
local positionXInput
local positionYInput
local enterCombatMessageInput
local leaveCombatMessageInput
local enterCombatColorSwatch
local leaveCombatColorSwatch
local positionXSlider
local positionYSlider
local isRegisteredSpecialFrame = false

function CombatState:ApplyConfigSettings()
    self:SetInputValue(fontSizeInput, CombatStateDB.fontSize)
    self:SetInputValue(positionXInput, CombatStateDB.x)
    self:SetInputValue(positionYInput, CombatStateDB.y)
    self:SetTextInputValue(enterCombatMessageInput, CombatStateDB.enterCombatMessage)
    self:SetTextInputValue(leaveCombatMessageInput, CombatStateDB.leaveCombatMessage)
    self:SetColorSwatchValue(enterCombatColorSwatch, CombatStateDB.enterCombatColor)
    self:SetColorSwatchValue(leaveCombatColorSwatch, CombatStateDB.leaveCombatColor)
    self:SetSliderValue(fontSizeSlider, CombatStateDB.fontSize)
    self:SetSliderValue(positionXSlider, CombatStateDB.x)
    self:SetSliderValue(positionYSlider, CombatStateDB.y)
end

function CombatState:ApplySettings()
    self:EnsureDB()
    self:ApplyAlertSettings()
    self:ApplyConfigSettings()
end

local function CreateFontSizeSlider(parent, relativeTo)
    fontSizeSlider = CreateFrame("Slider", "CombatStateFontSizeSlider", parent, "OptionsSliderTemplate")
    fontSizeSlider:SetSize(220, 20)
    fontSizeSlider:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", 0, -18)
    fontSizeSlider:SetMinMaxValues(12, 96)
    fontSizeSlider:SetValueStep(1)
    fontSizeSlider:SetObeyStepOnDrag(true)

    _G[fontSizeSlider:GetName() .. "Low"]:SetText("12")
    _G[fontSizeSlider:GetName() .. "High"]:SetText("96")
    _G[fontSizeSlider:GetName() .. "Text"]:SetText("")

    fontSizeSlider:SetScript("OnValueChanged", function(_, value)
        CombatState:SetFontSize(math.floor(value + 0.5))
    end)
end

local function CreatePositionSlider(parent, name, label, input, point, relativeTo, relativePoint, x, y, axis)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetSize(220, 20)
    slider:SetPoint(point, relativeTo, relativePoint, x, y)
    slider:SetMinMaxValues(-1000, 1000)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)

    _G[slider:GetName() .. "Low"]:SetText("-1000")
    _G[slider:GetName() .. "High"]:SetText("1000")
    _G[slider:GetName() .. "Text"]:SetText("")

    local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 4)
    labelText:SetText(label)

    input:SetPoint("LEFT", labelText, "RIGHT", 18, 0)

    slider:SetScript("OnValueChanged", function(_, value)
        CombatState:SetPosition(axis, math.floor(value + 0.5))
    end)

    return slider
end

function CombatState:CreateConfigFrame()
    if configFrame then
        return
    end

    local L = self.L

    configFrame = CreateFrame("Frame", "CombatStateConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    configFrame:SetSize(380, 520)
    configFrame:SetPoint("CENTER")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    configFrame:Hide()

    if not isRegisteredSpecialFrame then
        table.insert(UISpecialFrames, configFrame:GetName())
        isRegisteredSpecialFrame = true
    end

    local titleIcon = configFrame:CreateTexture(nil, "OVERLAY")
    titleIcon:SetSize(18, 18)
    titleIcon:SetPoint("LEFT", configFrame.TitleBg, "LEFT", 6, 0)
    titleIcon:SetTexture("Interface\\AddOns\\CombatState\\Media\\Icon.tga")

    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("LEFT", titleIcon, "RIGHT", 6, 0)
    title:SetText(L.title)

    local sizeLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sizeLabel:SetPoint("TOPLEFT", 18, -244)
    sizeLabel:SetText(L.fontSize)

    local enterCombatMessageLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enterCombatMessageLabel:SetPoint("TOPLEFT", 18, -44)
    enterCombatMessageLabel:SetText(L.enterCombatMessage)

    enterCombatMessageInput = self:CreateTextInput(configFrame, 320, function()
        return CombatStateDB.enterCombatMessage
    end, function(value)
        CombatState:SetCombatMessage("enter", value)
    end)
    enterCombatMessageInput:SetPoint("TOPLEFT", enterCombatMessageLabel, "BOTTOMLEFT", 0, -6)

    local leaveCombatMessageLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leaveCombatMessageLabel:SetPoint("TOPLEFT", enterCombatMessageInput, "BOTTOMLEFT", 0, -12)
    leaveCombatMessageLabel:SetText(L.leaveCombatMessage)

    leaveCombatMessageInput = self:CreateTextInput(configFrame, 320, function()
        return CombatStateDB.leaveCombatMessage
    end, function(value)
        CombatState:SetCombatMessage("leave", value)
    end)
    leaveCombatMessageInput:SetPoint("TOPLEFT", leaveCombatMessageLabel, "BOTTOMLEFT", 0, -6)

    local enterCombatColorLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enterCombatColorLabel:SetPoint("TOPLEFT", leaveCombatMessageInput, "BOTTOMLEFT", 0, -16)
    enterCombatColorLabel:SetWidth(100)
    enterCombatColorLabel:SetJustifyH("LEFT")
    enterCombatColorLabel:SetText(L.enterCombatColor)

    enterCombatColorSwatch = self:CreateColorSwatch(configFrame, function()
        CombatState:OpenCombatColorPicker("enter")
    end)
    enterCombatColorSwatch:SetPoint("LEFT", enterCombatColorLabel, "RIGHT", 8, 0)

    local resetEnterCombatColorButton = self:CreateButton(configFrame, L.reset, 72, 22, "LEFT", enterCombatColorSwatch, "RIGHT", 12, 0)
    resetEnterCombatColorButton:SetScript("OnClick", function()
        CombatState:ResetCombatColor("enter")
    end)

    local leaveCombatColorLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leaveCombatColorLabel:SetPoint("TOPLEFT", enterCombatColorLabel, "BOTTOMLEFT", 0, -8)
    leaveCombatColorLabel:SetWidth(100)
    leaveCombatColorLabel:SetJustifyH("LEFT")
    leaveCombatColorLabel:SetText(L.leaveCombatColor)

    leaveCombatColorSwatch = self:CreateColorSwatch(configFrame, function()
        CombatState:OpenCombatColorPicker("leave")
    end)
    leaveCombatColorSwatch:SetPoint("CENTER", enterCombatColorSwatch, "CENTER", 0, -30)

    local resetLeaveCombatColorButton = self:CreateButton(configFrame, L.reset, 72, 22, "CENTER", resetEnterCombatColorButton, "CENTER", 0, -30)
    resetLeaveCombatColorButton:SetScript("OnClick", function()
        CombatState:ResetCombatColor("leave")
    end)

    fontSizeInput = self:CreateNumberInput(configFrame, 54, function()
        return CombatStateDB.fontSize
    end, function(value)
        CombatState:SetFontSize(value)
    end)
    fontSizeInput:SetPoint("LEFT", sizeLabel, "RIGHT", 18, 0)

    CreateFontSizeSlider(configFrame, sizeLabel)

    positionXInput = self:CreateNumberInput(configFrame, 64, function()
        return CombatStateDB.x
    end, function(value)
        CombatState:SetPosition("x", value)
    end)
    positionXSlider = CreatePositionSlider(
        configFrame,
        "CombatStatePositionXSlider",
        L.positionX,
        positionXInput,
        "TOPLEFT",
        fontSizeSlider,
        "BOTTOMLEFT",
        0,
        -36,
        "x"
    )

    positionYInput = self:CreateNumberInput(configFrame, 64, function()
        return CombatStateDB.y
    end, function(value)
        CombatState:SetPosition("y", value)
    end)
    positionYSlider = CreatePositionSlider(
        configFrame,
        "CombatStatePositionYSlider",
        L.positionY,
        positionYInput,
        "TOPLEFT",
        positionXSlider,
        "BOTTOMLEFT",
        0,
        -36,
        "y"
    )

    local hint = configFrame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    hint:SetPoint("TOPLEFT", positionYSlider, "BOTTOMLEFT", 0, -18)
    hint:SetWidth(340)
    hint:SetJustifyH("LEFT")
    hint:SetText(L.moveHint)

    local previewEnterButton = self:CreateButton(configFrame, L.previewEnter, 112, 24, "BOTTOMLEFT", configFrame, "BOTTOMLEFT", 18, 50)
    previewEnterButton:SetScript("OnClick", function()
        CombatState:PreviewEnterCombat()
    end)

    local previewLeaveButton = self:CreateButton(configFrame, L.previewLeave, 112, 24, "LEFT", previewEnterButton, "RIGHT", 8, 0)
    previewLeaveButton:SetScript("OnClick", function()
        CombatState:PreviewLeaveCombat()
    end)

    local resetButton = self:CreateButton(configFrame, L.reset, 110, 24, "BOTTOMLEFT", configFrame, "BOTTOMLEFT", 18, 18)
    resetButton:SetScript("OnClick", function()
        CombatState:ResetDB()
        CombatState:ApplySettings()
        CombatState:UpdatePreview()
    end)

    local closeButton = self:CreateButton(configFrame, L.close, 82, 24, "BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -18, 18)
    closeButton:SetScript("OnClick", function()
        configFrame:Hide()
    end)

    configFrame:SetScript("OnShow", function()
        CombatState:ApplySettings()
        CombatState:SetConfigMode(true)
        CombatState:UpdatePreview()
    end)

    configFrame:SetScript("OnHide", function()
        CombatState:SetConfigMode(false)
        CombatState:HideAlert()
    end)
end

function CombatState:IsConfigShown()
    return configFrame and configFrame:IsShown()
end

function CombatState:ToggleConfig()
    self:CreateConfigFrame()

    if configFrame:IsShown() then
        configFrame:Hide()
    else
        configFrame:Show()
    end
end
