local addonName, BFUF = ...

local Media = {}
BFUF.Media = Media

Media.DEFAULT_TEXTURE = "blizzard"
Media.textures = {}
Media.textureOrder = {}

function Media:RegisterTexture(id, path, labelKey)
    if self.textures[id] then
        error("BFUF media texture already registered: " .. id)
    end

    self.textures[id] = {
        path = path,
        labelKey = labelKey,
    }
    table.insert(self.textureOrder, id)
end

function Media:GetTexture(id)
    local entry = self.textures[id] or self.textures[self.DEFAULT_TEXTURE]
    return entry and entry.path
end

function Media:GetTextureLabel(id)
    local entry = self.textures[id] or self.textures[self.DEFAULT_TEXTURE]
    if not entry then
        return id
    end

    return (BFUF.L and BFUF.L[entry.labelKey]) or entry.labelKey
end

function Media:GetTextureList()
    local textures = {}

    for _, id in ipairs(self.textureOrder) do
        textures[#textures + 1] = {
            value = id,
            label = self:GetTextureLabel(id),
        }
    end

    return textures
end

-- The first entry preserves BFUF's existing health-overlay appearance.
Media:RegisterTexture("blizzard", "Interface\\TargetingFrame\\UI-StatusBar", "MEDIA_TEXTURE_BLIZZARD")
Media:RegisterTexture("solid", "Interface\\Buttons\\WHITE8x8", "MEDIA_TEXTURE_SOLID")
Media:RegisterTexture("raid", "Interface\\RaidFrame\\Raid-Bar-Hp-Fill", "MEDIA_TEXTURE_RAID")
