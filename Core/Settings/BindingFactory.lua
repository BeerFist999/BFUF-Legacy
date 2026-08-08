local addonName, BFUF = ...

BFUF.Core = BFUF.Core or {}

local infrastructure = BFUF.Core.SettingsInfrastructure

-- Preserve the existing implementation while exposing a stable location for
-- declarative pages and future settings modules.
BFUF.Core.SettingsBindingFactory = infrastructure.BindingFactory
BFUF.Core.SettingsRefreshDispatcher = infrastructure.RefreshDispatcher
