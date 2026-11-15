<p align="center"><img src="images/wick-thumb-demons.png" alt="Wick's Demons and Things"></p>

# Wick's Demons and Things

<!-- wick:badges:start -->
[![Downloads](https://img.shields.io/curseforge/dt/1724608?style=flat-square&labelColor=171124&label=downloads&color=4FC778)](https://www.curseforge.com/wow/addons/wicks-demons-and-things)
![Forever](https://img.shields.io/badge/client-Forever-383058?style=flat-square&labelColor=171124)
[![License](https://img.shields.io/badge/license-MIT%20%2B%20trademark-383058?style=flat-square&labelColor=171124)](LICENSE)
[![Discord](https://img.shields.io/badge/discord-join-4FC778?style=flat-square&labelColor=171124)](https://discord.gg/GWGTMhYBZY)
<!-- wick:badges:end -->

> Warlock loadout kit for World of Warcraft: Forever. Soul bar, pet bar, shard counter, talents, pre-pull checklist, racials.

Part of the **[Wick suite](https://github.com/Wicks-mods/WickSuite)**: precision addons built around a single fel-green-on-deep-purple aesthetic. Built on [WickCore](https://github.com/Wicks-mods/WickCore).

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

Requires **[WickCore](https://github.com/Wicks-mods/WickCore)**. Extract both
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

## More from Wick

<!-- wick:suite-table:start -->
| Addon | GitHub | CurseForge |
|---|---|---|
| **WickCore** | [repo](https://github.com/Wicks-mods/WickCore) | [CurseForge](https://www.curseforge.com/wow/addons/wickcore) |
| **Wick's Comforts** | [repo](https://github.com/Wicks-mods/WicksComforts) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-comforts) |
| **Wick's Beasts and Things** | [repo](https://github.com/Wicks-mods/WicksBeastsAndThings) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-beasts-and-things) |
| **Wick's Stances and Things** | [repo](https://github.com/Wicks-mods/WicksStancesAndThings) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-stances-and-things) |
| **Wick's Seals and Things** | [repo](https://github.com/Wicks-mods/WicksSealsAndThings) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-seals-and-things) |
| **Wick's Conjures and Things** | [repo](https://github.com/Wicks-mods/WicksConjuresAndThings) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-conjures-and-things) |
| **Wick's Poisons and Things** | [repo](https://github.com/Wicks-mods/WicksPoisonsAndThings) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-poisons-and-things) |
| **Wick's Demons and Things** | [repo](https://github.com/Wicks-mods/WicksDemonsAndThings) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-demons-and-things) |
| **Wick's Bags** | [repo](https://github.com/Wicks-mods/WicksBags) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-bags) |
| **Wick's Trade Hall** | [repo](https://github.com/Wicks-mods/WicksTradeHall) | [CurseForge](https://www.curseforge.com/wow/addons/trade-hall) |
| **Wick's Gear** | [repo](https://github.com/Wicks-mods/WicksGear) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-gear) |
| **Wick's UI** | [repo](https://github.com/Wicks-mods/WicksUIForever) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-ui) |
| **Wick's Reminders** | [repo](https://github.com/Wicks-mods/WicksReminders) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-reminders) |
| **Wick's Map** | [repo](https://github.com/Wicks-mods/WicksMap) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-map) |

**Community:** [Discord](https://discord.gg/GWGTMhYBZY)
<!-- wick:suite-table:end -->

## License

MIT for code (see [LICENSE](LICENSE)). Brand chrome and the "Wick's" wordmark are trademarked, see [TRADEMARK.md](https://github.com/Wicks-mods/WickSuite/blob/main/TRADEMARK.md). Racial data from [talentsforever.com](https://talentsforever.com) (CC BY 4.0) via WickCore.
