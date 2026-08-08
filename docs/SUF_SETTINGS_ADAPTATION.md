# SUF Settings Architecture Adaptation

## Scope

This document records the approved architecture for evolving BFUF Settings after studying the installed Shadowed Unit Frames (SUF) and ShadowedUF_Options source code. It is a design reference, not a source-code port.

BFUF remains an independent addon. It keeps its standalone settings window, BFUF names, localization, AceDB database, Player/Target rendering, secure interaction, and Layout Engine.

## Reference source examined

The analysis used installed Retail source files, not screenshots:

- `H:\World of Warcraft\_retail_\Interface\AddOns\ShadowedUF_Options\config.lua`
- `H:\World of Warcraft\_retail_\Interface\AddOns\ShadowedUF_Options\ShadowedUF_Options.toc`
- `H:\World of Warcraft\_retail_\Interface\AddOns\ShadowedUnitFrames\ShadowedUnitFrames.lua`
- `H:\World of Warcraft\_retail_\Interface\AddOns\ShadowedUnitFrames\modules\units.lua`
- `H:\World of Warcraft\_retail_\Interface\AddOns\ShadowedUnitFrames\modules\layout.lua`
- `H:\World of Warcraft\_retail_\Interface\AddOns\ShadowedUnitFrames\modules\defaultlayout.lua`
- SUF option-library declarations in `libs/AceConfig-3.0`, `libs/AceGUI-3.0`, `libs/AceDBOptions-3.0`, and `libs/AceGUI-3.0-SharedMediaWidgets`.

## How SUF settings work

### Entry point and navigation

SUF separates the LoadOnDemand `ShadowedUF_Options` addon from the frame addon. Its single large `config.lua` constructs an AceConfig option tree and registers it with AceConfig. The tree combines global pages, profile management, enabled-unit pages, filters, tags, visibility, and unit configuration.

Unit configuration is data-driven: unit identifiers are grouped into categories, and a shared unit options table is instantiated for the selected unit. Nested groups use AceConfig tree/tab containers. The navigation state is retained by AceConfigDialog and changed through a registry notification.

### Data model

SUF creates one AceDB instance using a valid `profile` scope. Global options live in profile tables; unit-specific options live in `profile.units[unit]`; positions live separately in `profile.positions[unit]`. Sparse defaults are first generated for every known unit, then a default layout supplies concrete values.

The Options addon binds controls directly to those paths. A small temporary `globalConfig` table supports applying selected values across multiple units, rather than duplicating the widgets.

### Controls and bindings

AceConfig option definitions supply shared `get` and `set` handlers at group level. A control can override them only when it has special behavior. The generic handlers resolve an option path from metadata and read/write AceDB. Specialized setters handle colors, positions, text entries, filters, and multi-unit changes.

The visual controls come from AceGUI and shared-media widgets. This gives SUF one implementation each for checkbox, slider/edit box, dropdown, color, font, status-bar texture, border, and background controls.

### Refresh lifecycle

SUF distinguishes broad rebuilds from unit changes:

- global media changes call a media check followed by a full layout reload;
- normal unit settings call `Layout:Reload(unit)`;
- position settings update the stored position and reload the affected unit;
- dynamic option visibility and selection call `AceRegistry:NotifyChange`.

Profile changes are registered as AceDB callbacks. Profile changed/copied triggers a reload; profile reset additionally runs migration/normalization before reloading.

### Reset and profiles

Profiles are delegated to AceDBOptions, optionally enhanced by LibDualSpec. This provides current profile selection, create/copy/delete/reset, and profile bindings. Unit reset and reset position remain distinct: position resets only the position record; profile reset restores the full profile defaults.

## SUF to BFUF mapping

| SUF capability | SUF implementation | BFUF equivalent | BFUF action |
| --- | --- | --- | --- |
| Settings entry | LoadOnDemand AceConfig options addon | Standalone `SettingsShell` window | Keep standalone host; do not embed the UI in Blizzard Options. |
| Navigation | AceConfig tree/tab groups | SidebarNavigation + FrameNavigation + PageRegistry | Keep BFUF shell; make page definitions declarative. |
| Global options | `profile.*` option groups | `profile.General` plus future global sections | Add pages only when their functionality exists. |
| Unit configuration | `profile.units[unit]` and reusable unit table | Existing `profile.Player`, `profile.Target`, etc. | Preserve current schema; introduce an adapter, not a schema rewrite. |
| Position data | `profile.positions[unit]` | Existing per-frame `positionX/Y/Anchor` | Keep current fields; provide a single frame-position binding helper. |
| Reusable widgets | AceGUI/AceConfig widgets | BFUF UI widget factory | Consolidate BFUF widget contract without importing AceGUI. |
| Control binding | metadata path + group handlers | explicit BFUF binding object | Use `get`, `set`, `disabled`, `refresh`, and a named refresh intent. |
| Unit refresh | `Layout:Reload(unit)` | frame-specific refresh dispatcher | Map geometry to `UpdateLayout`, text to `UpdateTextElements`, portrait to portrait refresh, and full changes to an explicit rebuild. |
| Profile management | AceDBOptions/LibDualSpec | AceDB-backed BFUF Profiles page | Build a BFUF-native profile page on AceDB APIs; specialization support remains future work. |
| Unit/default reset | distinct position/profile operations | existing reset position/reset unit defaults | Preserve the distinction and make reset bindings reusable. |
| Auras and filters | dynamic filter option trees | reserved Aura pages | Reserve page IDs and binding types only; do not copy SUF filter logic. |

## BFUF target settings architecture

```text
SettingsModule
├── StandaloneWindow
│   └── SettingsShell
│       ├── SidebarNavigation
│       ├── FrameNavigation
│       └── ScrollablePageHost
│           └── ActivePage
├── PageRegistry
│   ├── General pages
│   ├── Frame pages
│   └── Future reserved pages
├── WidgetFactory
│   ├── CheckboxRow
│   ├── SliderRow + numeric edit box
│   ├── DropdownRow
│   ├── ColorRow
│   ├── ButtonRow
│   ├── SectionPanel
│   └── ExpandableSection
├── BindingFactory
│   ├── profile-path binding
│   ├── frame-position binding
│   ├── reset binding
│   └── refresh dispatcher
└── ProfileService
    └── AceDB profile operations and lifecycle callbacks
```

The initial navigation tree remains:

```text
General
├── General
├── Profiles
├── Colors
├── Fonts
├── Bars
├── Range
├── Aura Filters
├── Indicators
└── About

Unit Configuration
├── Player
│   ├── General
│   ├── Bars
│   ├── Portrait
│   ├── Text
│   ├── Indicators
│   ├── Resources
│   └── Auras
├── Target
├── Target Target
├── Focus
├── Focus Target
├── Pet
├── Pet Target
└── Boss
```

Party, Raid, and Arena are intentionally excluded from this target.

## BFUF binding contract

Every interactive BFUF widget must receive a binding object, never a frame module or direct AceDB knowledge:

```lua
{
    label = localizedText,
    get = function() return value end,
    set = function(value) end,
    disabled = function() return false end,
    refresh = function(widget) end,
    refreshIntent = "geometry" | "portrait" | "text" | "indicators" | "appearance" | "none",
}
```

A central dispatcher resolves the intent to the smallest valid update path. It must not call `UpdateLayout()` for text-only or appearance-only changes.

## Database and defaults

BFUF retains its valid AceDB shape:

```text
BFUF.Defaults.profile
├── General
├── Player
├── Target
├── TargetTarget
├── Boss
├── Focus
├── FocusTarget
├── Pet
└── PetTarget
```

Shared immutable metadata stays outside iterable AceDB defaults, as it does now through `BFUF.Defaults.UnitFrame`. No SUF schema is copied. Existing frame defaults remain:

- width: 324
- height: 55
- scale: 1.0
- portraitWidth: 54
- portraitMode: 2d

## Migration rules

1. Keep all existing Player and Target keys readable.
2. Never overwrite a user's existing profile while introducing an adapter.
3. Migrate a key only when an old representation has a proven replacement.
4. Preserve reset position as an X/Y-only operation.
5. Preserve reset frame defaults as a deep copy of only the selected frame section.
6. Register AceDB profile lifecycle callbacks before the new Profiles page is exposed.
7. Rebuild or refresh only the affected runtime subsystem.
8. Keep all user-facing text in `ruRU` and `enUS` localization.

## What BFUF adopts

- Declarative navigation and page registration.
- Reusable control definitions and a uniform binding contract.
- Explicit separation of global, frame, and profile concerns.
- Dedicated profile lifecycle callbacks.
- Narrow, intentional refresh paths.
- Dynamic page availability without duplicating widget code.

## What BFUF adapts

- SUF's metadata-driven options become BFUF page definitions and binding objects.
- SUF's `units[unit]` data model maps to BFUF's existing per-frame profile sections.
- SUF's full `Layout:Reload(unit)` maps to BFUF-specific refresh intents.
- SUF's profile UX is recreated with direct AceDB APIs inside the BFUF standalone window.

## What BFUF does not adopt

- SUF source code, AceConfig tables, AceGUI implementation, or visual style.
- SUF's monolithic multi-thousand-line configuration module.
- SUF's global multi-unit modifier model in the initial migration.
- SUF's tag, import/export, filter, visibility, party, raid, arena, or specialization logic.
- Any changes to BFUF rendering, secure interaction, Layout Engine, or portrait renderer.

## Implementation sequence

1. Introduce BindingFactory and RefreshDispatcher while preserving existing SettingsShell behavior.
2. Move existing Player and Target controls onto bindings one page at a time.
3. Add AceDB profile lifecycle callbacks and implement the BFUF Profiles page.
4. Complete reusable controls: slider edit box, dropdown, color, font, and expandable section.
5. Add only implemented global pages.
6. Reserve Aura Filters and other future pages without runtime logic.
7. Remove legacy page code only after each replacement has passed in-game validation.

## Current first architecture stage

This document is the completed analysis and target-contract stage. No Player/Target rendering, geometry, secure interaction, portrait renderer, defaults, or AceDB schema was changed. The next code stage is BindingFactory plus RefreshDispatcher; it must be introduced behind the existing SettingsShell and validated before moving controls.
