# BFUF Settings Architecture

## BindingFactory

`BindingFactory` creates reusable bindings over existing AceDB profile paths. A binding contains a stable key, `get()`, `set(value)`, default provider, optional disabled predicate, values, refresh intent, and context.

Settings widgets receive a binding and never access Player, Target, or AceDB directly.

## RefreshDispatcher

`RefreshDispatcher` maps a refresh intent to the narrowest current runtime update.

- `PLAYER_LAYOUT`: Player layout only.
- `TARGET_LAYOUT`: Target layout and target visual refresh.
- `PORTRAIT`: the selected frame portrait refresh path.
- `TEXT`: Player text refresh only.
- `HEALTH`: Player health style only.
- `POWER`: Player power style only.
- `AURA`: reserved until Auras exists.
- `INDICATORS`: Player indicator layout path.

Batched reset operations coalesce requests and avoid repeated layout updates.

## Control contract

Reusable controls accept a binding object:

```lua
{
    label = localizedText,
    binding = binding,
    values = values,
    disabled = function() return false end,
}
```

The current compatibility signatures remain available while pages migrate.

## Current migration

The standalone SettingsShell visual structure is unchanged. These existing pages now use profile bindings:

- Player General: width, height, scale, position X, position Y.
- Target General: width, height, scale, position X, position Y.
- Player Portrait: mode and width.
- Target Portrait: mode and width.

Reset Position resets only position X/Y and clears the stored native anchor. Reset To Defaults restores only the selected profile section through the common default provider.

## SUF principles adapted

BFUF adopts declarative pages, reusable controls, centralized bindings, narrow refresh paths, and separate reset operations. It does not import AceConfig, AceGUI, SUF code, SUF profile schema, or SUF rendering logic.

## Migration strategy

Move one existing page at a time to bindings. New controls must use bindings from the start. Existing direct bindings remain until their replacement is verified in-game. The AceDB schema remains unchanged.
