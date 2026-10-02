# Wick's Demons and Things - Changelog

## 0.9.0

The warlock kit's first release for the WoW Forever beta. It carries the
suite's single version number, so the suite goes to 1.0.0 together at
launch.

- Soul bar: Healthstone and Soulstone, one button each that uses the stone
  if you carry one and makes one if you do not, with Ritual of Summoning,
  Ritual of Souls and Eye of Kilrogg as you learn them.
- Pet bar: a summon button for each demon you know, the one that is out lit
  up, with Soul Link and Sacrifice once talented.
- Shard counter: your soul shards at a glance.
- Cooldown bar: a row of icons for the spells you name, off until you turn
  it on under Options or with /wdt cd.
- Talents, a pre-pull checklist and racials in the kit window (/wdt kit).
- A locked bar moves while you hold Shift, so a lock only stops an
  accidental nudge.
- The bars take the look and theme you pick in WickCore.
- Without WickCore it says so once, with a link to get it.

## 1.0.0 - 2026-09-17 (Forever)

### Rebuilt as a loadout kit on WickCore

Forever inherits Midnight's addon rules, so the cooldown and proc tracker is
gone: those values are secret in combat. The soul bar, pet bar and shard
counter carry over on WickCore's dialect shim, and the kit gains the talent
layer, a pre-pull checklist and a racials row.

- Requires WickCore. Interface 16001.
- Settings move into a WickCore profile.
- Cooldown tracker removed. Cooldown display on the bars passes secret values
  straight to the widget and never compares them.
- Aura reads route through WickCore's guard and return nothing while blocked.
- Shard counter falls back to the soul shard resource when the bag count is zero.
- Talents: export, import, save, apply, through Blizzard's own parser.
- Pre-pull checklist and racials in the kit panel (/wdt kit).
- Minimap launcher and a page under Options, Wick's Mods.

## 0.1.1 (TBC)

Previous TBC Anniversary builds lived in the deployed AddOns folder only.
