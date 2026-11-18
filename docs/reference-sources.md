# Local reference sources

Downloaded third-party mods remain under the ignored `references/` directory. They are not redistributed in this repository or the release archive.

- [Trophy Necromancy](https://www.nexusmods.com/witcher3/mods/12985), local reference version 5.01.01. Required at runtime. Its original summon, progression, costs, timers and localization belong to that mod.
- [Multi Companion Mod Remastered](https://www.nexusmods.com/witcher3/mods/13144), local reference version 3. Used during investigation of companion behavior and configuration.

For `tools/compile.ps1 -CompatibilityCheck`, place the original Trophy Necromancy distribution under `references/` so exactly one `trophynecromancy.ws` is present. The combined output is a verification artifact and must never replace the shipping production blob.

`node tools/build-menu-strings.cjs` currently also checks the original Trophy Necromancy `en.w3strings` in that local reference tree before generating our own menu strings. Keep the original distribution layout (`mods/modtrophynecromancy/content/en.w3strings`).

The native v164 string-container format was checked against the [Witcher3StringEditor source](https://github.com/0x7A2C9E5D/Witcher3StringEditor). Our generator and its generated menu text are included; downloaded format-investigation sources stay in the ignored build directory.

Built with The Witcher 3 REDkit, provided by CD PROJEKT RED. The Witcher game assets and trademarks remain the property of their respective owners. This is an unofficial fan mod.
