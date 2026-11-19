# Nexus release preparation — unpublished draft

Proposed name: **Shadow Monarch — Army Companion for Trophy Necromancy**.
Version: 1.0.0-rc1. Do not present the candidate as a tested stable v1.

## Description draft

Build your own necromancy squad alongside Trophy Necromancy. Pick up to ten additional generic monsters, mixing wraiths, nekkers and other creatures slot by slot. The original trophy summon remains controlled by Trophy Necromancy.

The army arrives automatically during eligible combat and dissolves afterward. Lost members have independent ten-second replacement cooldowns. Configure damage, size and shared vitality upkeep: the entire army costs one vitality point per second by default, regardless of size. Stamina and Signs are unaffected. At one vitality the army dismisses until Geralt recovers. Upkeep can be disabled.

Requires Trophy Necromancy 5.01.01 and the tested Witcher 3 Remastered build. Install/enable both in Vortex and use Trophy Necromancy's normal read/equipped book and trophy unlock.

## Before publication

- Pass spec.md's combined gameplay matrix, including every advertised monster, ten-unit load, vitality floor and Sign casting, cleanup and save/reload.
- Verify menu labels, selectors and settings persistence. Capture mixed squads/both menus and record performance configuration.
- Confirm the dependency's title, author, version and redistribution/compatibility terms on its actual Nexus page. Credit the original Trophy Necromancy system and local references. Bundle none of its source/resources/compiled patch.
- Keep README.txt's CD PROJEKT RED modding-tool attribution. Select a license for this project's original source; none is assumed here.
- List Trophy Necromancy as required and explain that its summon/children are outside our ten-unit army cap.
- Obtain user approval for the concrete listing and archive before uploading. No Nexus publication/account action has occurred.

## Changelog draft

- Converted the standalone prototype into a Trophy Necromancy companion.
- Added ten configurable army slots and eleven generic monster choices.
- Removed the implicit duplicate trophy leader.
- Added shared vitality upkeep/recovery, damage controls and visual scaling.
- Added ally exclusions and friendly damage handling.
- Retained automatic cleanup, independent replacement and bounded placement.
