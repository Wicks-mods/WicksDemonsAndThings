# Changelog

## 0.2.0 - 2026-10-03

### Fixed

- No errors at login about Bindings.xml. The file was listed in the TOC as
  well, so the game read it twice; the key bindings are unchanged.

### Added

- The four bars and the panel draw in WickCore's chrome: colours, borders
  and corner marks come from the look and theme chosen under Wick's Mods in
  the game's Options, and follow a change at once. The look's font too.
- A page under Wick's Mods: which bars show, and a button to the panel. The
  suite's launcher opens the panel.
- Chat lines carry the theme's accent colour.

### Changed

- Wick's Demons and Things now needs WickCore, which is in the same download
  as the rest of the suite. Without it the addon says so once at login and
  does nothing else. Your settings are untouched.

## v0.1.1 - 2026-05-07

Performance pass plus a TBC 2.5.5 API namespace fix. No feature changes.

- **SoulBar**: `GetItemCooldown`, `GetContainerNumSlots`, `GetContainerItemLink`, and `GetContainerItemInfo` were all moved into the `C_Container` namespace in TBC Anniversary 2.5.5. SoulBar's existing `X and X(...)` defensive pattern silently returned nil for all four, so bag-item detection and cooldown spirals stopped working without a visible error. Now resolves each at load time with a fallback to the legacy global, and wraps `GetContainerItemInfo` to handle both the legacy multi-return form and the new table-with-named-fields form.
- **SoulBar**: bag scans (findBagItemByName) are now event-driven, not polled. The 0.25s tick previously walked every slot in every bag for each item entry on every tick (~80-160 GetContainerItemLink calls per second for two item entries). Now the scan only runs when BAG_UPDATE marks the cache dirty, and the cooldown spiral updates from a cached itemId on every tick.
- **Cooldowns** + **PetBar**: 0.25s pollers now early-exit when the bar is hidden, matching the Totems v0.2.4 fix. Cuts the per-entry findAura / GetSpellCooldown work to zero when the user has the bar toggled off.
- **Show** on all three bars now triggers an immediate Refresh so re-toggling visible doesn't show up to 0.25s of stale state.

## v0.1.0

Initial release.
