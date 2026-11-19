# Shadow Monarch 1.0.0-rc1 — Trophy Necromancy Companion

Build a mixed monster army alongside **Trophy Necromancy 5.01.01**. The beta targets Witcher 3 Remastered 5.01c (executable 5.0.0.1090142). See the [verification notes](docs/verification.md) for completed and pending gameplay checks.

## Install with Vortex

The beta ZIP is pending release. If you have a local test copy, install Trophy Necromancy 5.01.01, then select **Mods → Install From File** in Vortex and choose the Shadow Monarch ZIP. Enable both mods and select **Deploy**.

When upgrading, quit the game, disable any previous Shadow Monarch version in Vortex and deploy before installing the beta. If you previously installed Shadow Monarch by hand, use the legacy file check below. Keep only one version enabled. Existing Trophy Necromancy progression is retained. The old `WraithCount` setting is ignored.

Choose **0–10 army units**, plus a monster for each active slot. The trophy summon is additional. For four wraiths and two nekkers, choose size six; set units 1–4 to Wraith and 5–6 to Nekker. Size zero leaves Trophy Necromancy alone. There is no extra implicit trophy leader.

After installation, load a game once to initialize missing settings. Read and equip Trophy Necromancy's book and equip a supported trophy on Roach. Open Settings → Mods → Miscellaneous → Shadow Monarch → Army Settings. Trophy Necromancy keeps its trophy summon, progression, health cost and cooldown. Shadow Monarch follows its combat activation signal.

Choices: Wraith, Nekker, Ghoul, Drowner, Arachas, Wyvern, Chort, Fiend, Cockatrice, Griffin and Archgriffin. All are generic base-game templates; each new choice still needs gameplay validation.

Defaults: four wraiths, 150% army damage, 75% visual size and **one vitality point per second for the entire army**, regardless of unit count. Set upkeep between 0 and 5 vitality/second; 0 disables it. Upkeep never consumes stamina or delays its regeneration, so Signs remain available. It applies only while at least one army unit is alive in eligible combat. At one vitality, only our army dissolves; it returns after at least ten seconds and 25% vitality recovery (and more than one vitality). Upkeep cannot kill Geralt. Trophy Necromancy's own summon costs are unchanged. The new VitalityPerSecond setting replaces the obsolete stamina setting and defaults to 1 for existing installations.

Every lost member has an independent ten-second replacement cooldown. Combat end cancels replacements and dissolves our units. Quantity, roster and balance changes apply at the next army creation. Disable the army for immediate cleanup. Cramped terrain can omit a slot until safe placement succeeds.

## Uninstall

Leave combat, let the army dissolve, save out of combat and quit. Disable or remove Shadow Monarch in Vortex and deploy. Run the legacy file check before loading your save. You can keep Trophy Necromancy installed with its progression intact.

### Legacy file check

After deploying with every Shadow Monarch version disabled, check these paths inside the Witcher 3 game folder.

- `Mods/modShadowMonarch/`
- `bin/config/r4game/user_config_matrix/pc/modShadowMonarch.xml`

Vortex can restore older files that were present before it managed the mod. If either Shadow Monarch path remains, move it to a backup outside the game folder. Leave Trophy Necromancy's folder and settings XML in place.

Report problems using the [GitHub bug report form](https://github.com/range-et/shadow_army-w3_mod/issues/new?template=bug_report.yml).

## Build from source

To reproduce the Vortex-tested rc1 ZIP from a clean checkout, run these commands from the repo root with PowerShell 7.6.9 on Windows. The packaging script uses the checked-in production files.

```powershell
pwsh -NoProfile -File .\tools\package.ps1
Get-FileHash -Algorithm SHA256 .\dist\ShadowMonarch-1.0.0-rc1.zip
```

Expected SHA-256: `37b00479170d2ac0c6f297e6a8537e8ac6449070ca8deeda50279349b184b2ae`.

After editing WitcherScript, regenerate the compiled blob with `tools/compile.ps1`. Use `tools/compile.ps1 -CompatibilityCheck` to compile with Trophy Necromancy for verification. See [the specification](spec.md) for implementation details.

Downloaded reference mods are excluded from Git. See docs/reference-sources.md for their locations and the local reference layout needed by the compatibility/string-generation tools.

The project's original code is available under the [MIT License](LICENSE). See the [third-party notices](docs/third-party-notices.md) for the menu-string format reference.

Built with The Witcher 3 REDkit, provided by CD PROJEKT RED. This is an unofficial fan mod. Game assets, trademarks and separately distributed mods belong to their respective owners and remain subject to their own terms.
