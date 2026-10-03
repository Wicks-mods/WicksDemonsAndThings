# Wick's Demons and Things

> Warlock bars for World of Warcraft: TBC Classic Anniversary. Stones and rituals, demons, cooldowns and procs, and your shard count.

Part of the **[Wick suite](https://github.com/Wicksmods/WickSuite)**: precision addons built around a single fel-green-on-deep-purple aesthetic. Built on [WickCore](https://github.com/Wicksmods/WickCore).

This is the TBC build, on the `tbc` branch. The Forever build lives on `main`.

## What it does

- **Soul bar.** Use a Healthstone or a Soulstone from your bags with one
  click, whichever rank you carry. Create Healthstone, Create Soulstone,
  Ritual of Summoning, Ritual of Souls and Eye of Kilrogg join it as you
  learn them.
- **Pet bar.** A summon button for each demon you know: Imp, Voidwalker,
  Succubus, Felhunter, and Felguard once talented. Soul Link and
  Sacrifice too. The demon that is out is lit up.
- **Cooldown bar.** Banish, Curse of Doom, Death Coil, Howl of Terror, Fel
  Domination, Conflagrate, Shadowfury and Soulshatter, each shown only if you
  know it, plus the Shadow Trance and Shadow Vulnerability procs for your
  spec. It rebuilds when you respec.
- **Shard counter.** A small badge with your soul shard count.

Every bar follows the look and theme you pick under Wick's Mods in the
game's Options. With Wick's UI loaded, move them with `/wui move`.

## Install

Requires **[WickCore](https://github.com/Wicksmods/WickCore)**. Extract both
folders into `World of Warcraft\_anniversary_\Interface\AddOns\`.

## Usage

| Command | Effect |
|---|---|
| `/wdt` | Options panel |
| `/wdt soul` | Show or hide the soul bar |
| `/wdt pet` | Show or hide the pet bar |
| `/wdt cd` | Show or hide the cooldown bar |
| `/wdt shard` | Show or hide the shard counter |
| `/wdt lock` / `/wdt unlock` | Lock the bars in place, or let them be dragged |
| `/wdt reset` | Put every bar back where it started |
| `/wdt status` | Diagnostic info |

Each bar also has a key binding under Key Bindings, Wick's Demons and Things.

## License

Code is MIT. The Wick name, logomark and visual system are trademarks; see
[LICENSE](LICENSE).
