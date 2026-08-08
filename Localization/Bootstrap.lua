local addonName, BFUF = ...

-- Initialize the existing shared localization table before TOC-loaded Settings
-- definitions capture localized labels. BFUF:Initialize refreshes this table later.
BFUF.Localization:Initialize()
