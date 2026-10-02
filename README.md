# Wick's Demons and Things

> Warlock loadout kit for World of Warcraft: Forever. Soul bar, pet bar, shard counter, talents, pre-pull checklist, racials.

Part of the **[Wick suite](https://github.com/Wicksmods/WickSuite)**: precision addons built around a single fel-green-on-deep-purple aesthetic. Built on [WickCore](https://github.com/Wicksmods/WickCore).

## What it is on Forever

Forever runs retail's engine with Midnight's addon rules. In combat the
player's own cooldowns, buffs, health and power are secret, and aura queries
throw. So this is a loadout kit, not a combat tracker: everything a warlock
sets up before the pull, all of it readable out of combat.

- **Soul bar.** Healthstone and Soulstone, one button each: it uses the stone
  if you carry one and makes one if you do not. Ritual of Summoning, Ritual of
  Souls and Eye of Kilrogg join it as you learn them.
- **Pet bar.** A summon button for each demon you know (Imp, Voidwalker,
  Succubus, Felhunter, Felguard), the one that is out lit up. Soul Link and
  Sacrifice too, once talented.
- **Shard counter.** Bag count, falling back to the soul shard resource.
- **Cooldown bar.** A row of icons for the spells you name. Off until you turn
  it on under Options or with `/wdt cd`.
- **Talents.** Export the active build as a Blizzard import string, import a
  string as a new loadout, save builds to an account-wide library, apply one
  with a click. Blizzard's own parser does the work.
- **Pre-pull checklist.** Demon armor, Shadow Ward, Healthstone, Soulstone,
  shards, demon out. Rows go quiet the moment combat starts.
- **Racials.** Your race's actives as cast buttons with cooldown display.

## Install

Requires **[WickCore](https://github.com/Wicksmods/WickCore)**. Extract both
folders into the Forever client's `Interface\AddOns\`.

## Usage

| Command | Effect |
|---|---|
| `/wdt` | Options panel |
| `/wdt kit` | Talents, checklist, racials |
| `/wdt soul` / `pet` / `shard` | Toggle a bar |
| `/wdt cd` | The cooldown bar |
| `/wdt lock` / `unlock` | Lock or unlock all bars (hold Shift to move a locked one) |
| `/wdt reset` | Reset bar positions |
| `/wdt status` | Diagnostics |

Keybinds for each bar and the kit are under Key Bindings, AddOns.

## Compatibility

World of Warcraft: Forever, 1.60.x, Interface 16001. Requires WickCore.

## License

MIT for code (see [LICENSE](LICENSE)). Brand chrome and the "Wick's" wordmark are trademarked, see [TRADEMARK.md](https://github.com/Wicksmods/WickSuite/blob/main/TRADEMARK.md). Racial data from [talentsforever.com](https://talentsforever.com) (CC BY 4.0) via WickCore.
