local addonName, BFUF = ...

local SettingsModule = {}
BFUF.Core.Settings = SettingsModule

-- Create a simple placeholder subcategory without live controls.
function SettingsModule:CreatePlaceholderCategory(parentCategory, title, description)
    local frame = CreateFrame("Frame")
    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16)
    text:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -16)
    text:SetJustifyH("LEFT")
    text:SetText(description)

    return Settings.RegisterCanvasLayoutSubcategory(parentCategory, frame, title)
end

-- Register the BFUF root category and its placeholder subcategories.
function SettingsModule:Initialize()
    if self.category then
        return
    end

    local rootFrame = CreateFrame("Frame")
    self.category = Settings.RegisterCanvasLayoutCategory(rootFrame, BFUF.L.ADDON_NAME)
    Settings.RegisterAddOnCategory(self.category)

    self.categories = {
        General = BFUF.Config.General:Create(self.category),
        Player = BFUF.Config.Player:Create(self.category),
        Indicators = BFUF.Config.Indicators:Create(self.category),
        Profiles = BFUF.Config.Profiles:Create(self.category),
        About = BFUF.Config.About:Create(self.category),
    }
end

-- Open the root BFUF category in Blizzard Settings.
function SettingsModule:Open()
    self:Initialize()
    Settings.OpenToCategory(self.category:GetID())
end
