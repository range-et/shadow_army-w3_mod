## Vitality upkeep revision (2026-11-18)

The current source replaces per-unit stamina upkeep with shared vitality upkeep (default 1 point/second for any nonempty army). Older stamina measurements below are historical and do not validate this revision. The four-unit player test below confirms shared upkeep, one successful Sign cast, stamina recovery during combat and normal cleanup. Remaining runtime acceptance includes a 1/4/10-unit rate comparison, a second Sign cast after recovery, paused/all-dead and 0-cost cases, the nonlethal 1-vitality floor, and ten-second/25%-vitality recovery. Production and combined Trophy Necromancy compatibility builds compiled successfully with REDkit; XML/menu-string round-trip validation passed. The observer now records both vitality and stamina. The integration driver uses the new setting but its short healthy-player sequence does not establish low-health recovery.

Player combat test (2026-11-18): the observer recorded two four-unit army activations. There were 141 sub-one-point vitality drain calls totalling 35.925475 points; individual payments were approximately 0.25 per quarter-second rather than multiplied by living unit count. These calls used the shared 1 vitality/second setting; health regeneration can mask net health loss. Igni performed once during combat with all four army units active. Stamina subsequently read 0, then 46.589428 while combat/army remained active, and 100 at combat end. Only one cast was logged, so a second-cast check remains unverified. Both encounters faded four units and reached living/fading/world=0 on the following sample; no upkeep payments were observed after cleanup. Later combat in the same log had eligibility=false and no army, and is not upkeep evidence. One/ten-unit rate comparison, zero-cost option and low-health floor/recovery tests remain pending. Evidence: build/logs/vitality-upkeep-player-test.txt. The production blob was restored to Vortex staging and its deployed link after evidence capture (hash verified). The already-running session retains observer logging until exit; the next launch uses production.

# V1 companion candidate — 2026-11-18

Version 1.0.0-rc1 replaces the standalone design. Trophy Necromancy 5.01.01 is required. Its summon is additional to our cap of ten configurable army units. Current spec.md supersedes all standalone installation/compatibility guidance in the historical report below.

## Implemented and checked

- Ten independent army slots and eleven generic monster choices; no implicit trophy leader. Settings XML parses and contains ten selectors with eleven choices each and a four-unit default.
- Native stamina upkeep and fatigue cleanup are measured with four and ten units. Ten units drained approximately ten stamina/second, dissolved on exhaustion while the trophy summon remained, and rearmed after the ten-second delay. Stamina had already recovered fully before that deadline; the separate 25% lower-bound gate still needs a controlled low-stamina test.
- Army-only configurable damage and animated/mesh component scaling; direct friendly damage guards and enemy-selection exclusions for Trophy Necromancy's summon/children.
- Dependency-owned combat activation fact is read only, with read/equipped book gating. No dependency source, facts, timers, progression or costs are rewritten. This is an activation handshake, not a definitive installation detector on saves with stale dependency facts.
- Production WitcherScript compiles and serializes successfully against the installed build. Separate combined-source compilation of this mod plus Trophy Necromancy also succeeds, including shared wrapped methods. Compiler logs are build/logs/compile-v1-driver.log and compile-compatibility-driver.log. Legacy engine/config warnings remain; this is not a warning-free compilation claim.
- All eleven selected resource files exist in REDkit's r4data/characters/npc_entities/monsters tree. Existence does not establish runtime safety or damage.
- Observer-only diagnostics compile separately. They log stamina, configured/living/fading/world counts, trophy actor and actual health loss from both systems. No enemy creation, book injection, immortality or eligibility bypass. Historical standalone automatic test harnesses are not valid v1 tests; -DamageTest is retired.
- Shipping archive uses only our production scripts/blob/XML and documentation. Combined reference-source and diagnostic blobs stay under ignored build directories.

## Still required before stable release

Combined v1 testing has begun. The first valid case spawned two mortal level-39 drowners (1,820 HP each), four mortal army wraiths and the original Trophy Necromancy quest griffin. Both enemies died after 17.109 seconds. Wraith hits removed 453.425 HP each at 150% army damage; the trophy griffin delivered the finishing 6.298 HP on one enemy. Subsequent combat=false/world=0 observations establish normal cleanup for this case. This was the narrow Beauclair street, not an open-road benchmark. Evidence: build/logs/v1-integration-first-run.txt.

Later cases in that first sequence created zero of one requested targets and are INVALID, not passes. The test driver now tries eight clear navigation candidates; incomplete setups log INVALID and wait 35 seconds before retrying from a new position. It creates temporary enemies and protects Geralt. Later invulnerable targets isolate upkeep/cooldowns and cannot establish damage balance. The first mixed-run target used AIM_Immortal but a finishing attack killed it; the runner now uses AIM_Invulnerable for these isolation cases. It does not grant/read/equip the book or rewrite the dependency's facts/costs/progression. Do not save diagnostic sessions.

A second recorded combined run killed both mortal drowners after 41.322639 seconds. That variability does not meet a consistent twenty-second benchmark. Five wraiths plus five nekkers then reached ten owned actors alongside the trophy griffin; the maximum recorded owned world count, including fade windows, was ten. They exhausted stamina, all dissolved, recovered after the delay, returned to ten, and cleaned up to zero when combat ended. Nekker and wraith attacks caused actual native health loss. The next zero-unit target failed placement near stairs, so that case and the following cooldown case were not signed off by this run. Evidence: build/logs/v1-integration-mixed-road.txt.

Complete spec.md's acceptance matrix: both menus/settings, dependency gating, zero/ten/mixed configurations, every advertised template, stamina costs and recovery, scale/hit detection, ally behavior/rewards, crowding/performance, cleanup, save/reload/uninstall and open-road damage timing.

Vortex now has the v1 candidate and Trophy Necromancy enabled; the old 0.1 prototype is disabled. No Nexus upload has occurred. The release description/credit/license preparation is in docs/nexus-release.md.

The menu startup test found missing localization/path registration. Added a stable Mods.miscellaneous.ShadowMonarch.ShadowMonarchArmy path and a native v164 UTF-8 English string table. Both mod entries and our settings panel now open. The value-label check revealed the game's preset_value_ prefix; aliases were added. Missing settings initialize to documented defaults on loading a game without overwriting explicit values. The encoder verifies a known reference label and round-trips every generated entry. Production and combined-source compatibility compilation passed again after the initialization change (compile-menu-defaults-driver.log and compile-menu-defaults-compatibility-driver.log). IDs are provisional local-development IDs; reserve a public ID space and add translations before publishing. Final value-label/default visual verification remains open because automated gameplay keyboard input did not reopen the pause menu reliably.

## Final local integration results

The final tail sequence used an invulnerable temporary target, and therefore provides no damage-balance evidence. It starts at phase 5 via tools/compile.ps1 -IntegrationTail; ordinary -IntegrationTest still starts with phase 1. Diagnostics require launching witcher3.exe with -debugscripts; omitting that option left the second launch without a fresh log, and that unlogged run was not accepted as evidence.

- ArmySize=0: a valid hostile encounter lasted 15.112408 seconds, our living/world counts remained zero, stamina stayed 100, and the original trophy griffin appeared. Both mods cleaned up normally.
- ArmySize=10, upkeep=0: all ten wraith slots spawned, the original trophy griffin coexisted, and stamina stayed 100 throughout the case. Maximum owned world count was ten.
- Forced slot 0 death was detected at controller time 176.320831; its first replacement attempt was 186.511703 (10.190872 seconds). Slot 1 died at 180.403519; its attempt was 190.612534 (10.209015 seconds). The other eight survived. Both attempts were blocked by placement checks, as were later retries. This verifies separate attempt deadlines and survivor retention, **not successful v1 replacement spawning**. A clear-terrain replacement-return test remains required.
- Combat ended with eight fading actors, then world/living/fading=0; subsequent observations stayed zero with no late spawns. No diagnostic manual save was made.

Evidence: build/logs/v1-integration-tail.txt. All original save files match the pretest manifest. The diagnostic game session was closed, production blob restored, and Vortex staging updated with the production source/blob/XML and our generated strings. The user settings backup was restored; mods remain v1 + Trophy Necromancy enabled, 0.1 disabled. These are local release-candidate results, not a stable/Nexus acceptance signoff.

---

# Historical 0.1 prototype evidence (not v1 acceptance)

# Verification — 2026-11-18

Development build tested locally on Witcher 3 Remastered 5.01c, executable 5.0.0.1090142. Core automatic spawning, independent replacement, and normal combat-end cleanup passed the controlled runtime test. This is not full acceptance of every requirement in spec.md.

## Build and deployment

Steam installed REDkit to D:\SteamLibrary\steamapps\common\The Witcher 3 REDkit. Production and diagnostic WitcherScript patches compile successfully with its wcc_lite compilescripts commandlet against the installed game scripts. Compiler exits are zero and patch serialization succeeds. Legacy configuration/init messages and vanilla warnings occur in compiler logs; successful compilation does not imply a warning-free engine.

Reproduce with tools/compile.ps1; -Diagnostics builds the separate automatic harness from tools/testing. Production excludes the harness, temporary enemy, book injection, immortality, and automatic test sequence. Source and production precompiled.rsblob are deployed to both the game Mods folder and Vortex staging. Trophy Necromancy remains disabled. The settings XML is deployed.

## Runtime evidence

Tests loaded the backed-up Beauclair save without manually saving diagnostic changes. The harness adds/reads the existing book in memory, creates a temporary hostile drowner, and relies on normal game combat detection and production eligibility. Later passes temporarily protect actors to isolate forced unit deaths. This protection is diagnostic only.

- Wraiths automatically materialized and used native movement/teleport effects. The leader appeared too. Initial narrow placement caused failed attempts; expanding the navigation search from two to four metres let all four slots spawn together on the final pass.
- Final pass spawned slots 0–3 at controller time 10.723731.
- Slot 1 loss was detected at 33.284512 and its replacement spawned at 43.535027: 10.251 seconds later.
- Slot 2 loss was detected at 37.379822 and its replacement spawned at 47.422092: 10.042 seconds later. Deaths were four seconds apart; separate deadlines were preserved and living units were retained.
- Removing the test enemy allowed native combat to end. All summons disappeared visually. The diagnostic world-tag query and controller both returned zero. Repeated post-combat checks in earlier passes also stayed at zero with no delayed respawns.
- A targeting gap found during testing was corrected with explicit mutual hostility, nearest-hostile fallback when Geralt has no valid selected target, and ForceTarget only on target changes. The final log records an owned attack reaching the drowner damage handler. Its pre-processing damage value is a sentinel (-2), so this is hit-event evidence, not a measured damage/kill-balance result.

Raw local evidence is in build/logs/runtime-first-test.log, runtime-second-test.log, runtime-third-test.log and compile-production.log / compile-diagnostic.log. The build directory is excluded from distribution. Save backup and original general.ini are in the Windows temporary folder ShadowMonarch-test-backup-20261118.

## Remaining verification and limits

Normal combat lifecycle passed; fast-travel, dialogue, death, player replacement, save during combat/reload, uninstall, combat ending during pending cooldown, all trophy variants, still need dedicated runtime cases. Four wraiths plus Archgriffin were tested later below. Safety hooks compile but are not gameplay-proven by the normal cleanup test. No test deliberately synchronized cleanup with a wraith's invisible teleport frame or an unloaded distant actor.

Incoming/outgoing damage amounts, kill credit, loot/XP suppression, civilian behavior, and walking/rolling/Whirl targeting need normal gameplay testing without diagnostic immortality. Visual spawn/disappearance was observed; exact griffin-like dissolve polish is not signed off.

Placement now uses fixed 1.2-metre navigation clearance, a bounded four-metre search at up to five candidate positions, a height check relative to Geralt, and a clear 0.4-metre navigation-line check. It does not derive clearance from the template or prove arbitrary path connectivity. Failed placement/resource attempts back off ten seconds per slot; cramped areas can delay a unit beyond its death cooldown. Only the generic griffin leader and wraith army have runtime spawn evidence. Resource paths for the other approved generic leaders were checked against the installed bundle file table.

## Damage regression fix (later on 2026-11-18)

User testing reported that summons dealt no damage. Spawn initialization was clearing the entire native inventory, which also holds monster combat equipment. Removed that clearing operation. Retained clearInvOnDeath: the installed CBTTaskDeath loot routine returns early when this flag is true, so stripping combat equipment is unnecessary for suppressing loot. No artificial damage bonus or direct damage injection was added.

Compiled and ran a separate mortal-target harness (tools/compile.ps1 -DamageTest). Geralt remained idle and was the only actor granted test immortality. Summons and the level-39 drowner were mortal. The drowner began at 1,820 health; wraith hits dealt 302.283661 actual health loss, confirmed by before/after GetHealth readings. Seven recorded wraith strikes reduced it to zero by approximately test time 26 seconds, versus creation at approximately 10 seconds. First hit was between 14 and 15 seconds: approximately 12 seconds from first contact to death. The griffin spawned late due to placement and did not produce a logged damaging hit, so this proves wraith damage and a natural kill, not griffin damage or a two-enemy benchmark.

Repeated post-test cleanup checks report combat=false and world=0. Evidence: build/logs/runtime-damage-inventory-fix.log. Incoming damage was not established: the single recorded incoming wraith hit caused no health loss, which still needs checking against native wraith immunity behavior. Human enemies and all leader templates need separate damage tests.

Default army size is now four wraiths, retaining three as an explicit setting. The damage benchmark above used the previous three-wraith default; it does not establish a measured time for four wraiths plus leader against two drowners. The generic gryphon_lvl1 fallback remains unchanged; archgriffin-specific appearance/variant selection is not part of this damage fix. Final production compilation and game/Vortex copies exclude all test hooks and immortality.


## Archgriffin damage, variant and placement regression

Runtime display names distinguish gryphon_lvl1 (Griffin) from gryphon_lvl3__volcanic (Archgriffin). Added explicit q002_griffin_trophy → generic Griffin and mh301_gryphon_trophy → generic Archgriffin mappings; unsupported/no trophy now falls back to generic Archgriffin. No named quest actor is used.

The initial unboosted Archgriffin/full four-wraith run killed two level-39 drowners (1,820 HP each) in 30.165760 seconds from creation. Archgriffin hits caused 302.283661 actual health loss. A later isolated Archgriffin test confirmed a 453.425476-health hit with the new 1.5× hostile-hit bonus, but the street's obstructed placement prevented a reliable solo kill. Both enemies and summons remained mortal; only idle Geralt had test immortality.

User observation and the benchmark exposed unsafe placement across building geometry. The production fix checks navigation height relative to Geralt, rejects points without a clear navigation line to him, and tries four alternate front/side/rear candidates after the formation point before backing off. The initial squad then spawned all five slots at controller time 13.550849, without the earlier ten-second leader placement delay.

Three subsequent two-drowner encounters with the 1.5× bonus and placement fix completed in 17.107471, 37.286488 and 43.280533 seconds. All five units were present; the first encounter recorded multiple Archgriffin hits and its finishing blow. This proves Archgriffin damage and natural full-squad kills, but does not establish a consistent twenty-second benchmark in a cramped stairway. Intermission and final checks report combat=false/world=0. The benchmark gates eligibility between its phases, so these are end-of-test cleanup checks rather than an independent reproof of natural combat-end timing.

Evidence: build/logs/runtime-griffin-solo.log, runtime-archgriffin-baseline.log, runtime-archgriffin-balance-before-placement-fix.log and runtime-archgriffin-placement-fix.log. Failed setup runs are retained separately and are not accepted as balance evidence. Earlier sections describe historical builds; the later variant/balance/placement changes supersede their fallback and damage assumptions.
