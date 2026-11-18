# Shadow Monarch 1.0.0-rc1 — Trophy Necromancy Companion

Build a mixed monster army alongside **Trophy Necromancy 5.01.01**, which is required. Target: Witcher 3 Remastered 5.01c / executable 5.0.0.1090142. Release candidate with partial combined gameplay verification; see docs/verification.md for passed cases and remaining checks.

Install Trophy Necromancy, then this ZIP through Vortex. Enable and deploy both mods and their settings XMLs. Own, read and equip the original necromancy book, and equip a supported trophy on Roach. Trophy Necromancy keeps its trophy summon, progression, health cost and cooldown; our army follows its combat activation signal.

Upgrading from the 0.1 standalone prototype: replace/disable that old Shadow Monarch version before enabling this package. Keep only one Shadow Monarch version active. Existing Trophy Necromancy progression is retained; the old WraithCount setting is ignored.

Choose **0–10 army units**, plus a monster for each active slot. The trophy summon is additional. For four wraiths and two nekkers, choose size six; set units 1–4 to Wraith and 5–6 to Nekker. Size zero leaves Trophy Necromancy alone. There is no extra implicit trophy leader.

After installation, load a game once to initialize missing settings. Open Settings → Mods → Miscellaneous → Shadow Monarch → Army Settings. English menu text is included.

Choices: Wraith, Nekker, Ghoul, Drowner, Arachas, Wyvern, Chort, Fiend, Cockatrice, Griffin and Archgriffin. All are generic base-game templates; each new choice still needs gameplay validation.

Defaults: four wraiths, 150% army damage, 75% visual size and **one stamina per living unit per second**. Set upkeep between 0 and 5 stamina per unit per second; 0 disables it. Ten living units cost ten stamina/second. Running out dissolves only our army, which returns after at least ten seconds and 25% stamina recovery. These controls do not change Trophy Necromancy's summon.

Every lost member has an independent ten-second replacement cooldown. Combat end cancels replacements and dissolves our units. Quantity, roster and balance changes apply at the next army creation. Disable the army for immediate cleanup. Cramped terrain can omit a slot until safe placement succeeds.

Removal: leave combat, let the army dissolve, quit, disable/remove Shadow Monarch and deploy. Keep Trophy Necromancy if desired. Do not edit its progression facts to remove this companion. Reload/uninstall remains a final-test requirement.

Build: tools/compile.ps1. Combined source check: tools/compile.ps1 -CompatibilityCheck. Its combined blob is verification only and is never shipped. Package: tools/package.ps1. No dependency or diagnostic code is bundled. See spec.md, docs/verification.md and docs/nexus-release.md.

Downloaded reference mods are excluded from Git. See docs/reference-sources.md for their locations and the local reference layout needed by the compatibility/string-generation tools.

Built with The Witcher 3 REDkit, provided by CD PROJEKT RED. This is an unofficial fan mod; game assets and trademarks belong to their respective owners.
