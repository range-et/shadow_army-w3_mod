# Shadow Monarch 1.0 — Trophy Necromancy Companion

Status: **1.0.0-rc1**, awaiting combined in-game acceptance. Supersedes the standalone design archived in docs/spec-0.1-prototype.md.

## Product and dependency

Trophy Necromancy is required and retains its trophy-selected summon, book integration, progression, health costs, duration and healing/cooldown rules. Shadow Monarch supplies a separate automatic army of **zero to ten units, in addition to the trophy summon**. The dependency may create its own children; those do not count toward our army cap.

Target: Witcher 3 Remastered 5.01c, executable 5.0.0.1090142, Steam build 26238013. Reference dependency: Trophy Necromancy 5.01.01. Other game/dependency versions are not verified.

Both mods must be installed and enabled. Own, read and equip the original necromancy book, and equip an eligible trophy on Roach. Read, but never write, TrophyNecromancy_timerstarted: the dependency's combat hooks provide this activation signal. A stale XML alone cannot activate an army. Stale saved dependency facts are not a reliable installation detector; installation instructions explicitly require the dependency.

## Squad settings

| Setting | Range | Default |
| --- | --- | --- |
| Enable army | On/off | On |
| Army size | 0–10 | 4 |
| Unit 1 … Unit 10 | Generic monster selector | Wraith |
| Army damage | 25–300% | 150% |
| Army size scale | 40–100% | 75% |
| Vitality upkeep | 0–5 vitality points per second for the entire army | 1 vitality/second |

Only the first Army size slots are active. Four wraiths and two nekkers: size six, slots 1–4 Wraith, slots 5–6 Nekker. Size zero permits the original trophy summon alone. Roster, quantity, damage, scale and upkeep snapshot at the next army creation. Disabling cleans up immediately. Clamp numeric values; missing settings use defaults. Retire WraithCount.

Fixed roster IDs: 0 Wraith, 1 Nekker, 2 Ghoul, 3 Drowner, 4 Arachas, 5 Wyvern, 6 Chort, 7 Fiend, 8 Cockatrice, 9 Griffin, 10 Archgriffin. Use generic base-game templates only. Never spawn named story actors, quest bosses, Triss/Yennefer/Geralt or hero copies in our army. Trophy Necromancy controls its own roster.

All eleven template files exist in installed REDkit. Existence and compilation do not approve AI, damage, scaling, children or death behavior; every advertised choice needs final runtime acceptance.

## Coexistence and ownership

- Remove our implicit trophy leader. An explicitly selected army griffin is allowed; no silent duplicate leader.
- Use smOwned/sm_shadow_unit and PM_DontPersist only for our actors. Never enroll them in TrophyNecromancy_npc/ent tags.
- Exclude the dependency's tagged summon/entities/doppelgangers from enemy selection; establish mutual friendship with its leader.
- Block direct friendly damage between both systems and among our army units. Apply our damage bonus only to positive processed damage from an owned attacker against a hostile. Do not stack our bonus onto the trophy summon.
- Keep replacement deadlines, upkeep costs and cleanup separate. Never change the dependency's counters, progression, health costs, immortality or leader lifecycle.
- Keep dependency files/settings independent. Do not redistribute its source, compiled patch or localization. Combined-source compilation is a verification artifact only, never the shipping blob.

## Balance

Charge one shared vitality cost only while at least one army unit is living and active during eligible combat. Default: **one vitality point per second for the entire army**, identical for one, four or ten units. This is additional to the dependency's own costs. Zero disables upkeep. Use native DrainVitality; never drain stamina or modify stamina regeneration. Do not charge while all slots are dead, missing, fading or on cooldown, or while paused/out of combat. Use the new VitalityPerSecond setting (default 1, range 0–5); ignore the obsolete UpkeepPerSecond value to avoid reinterpreting saved stamina choices.

Clamp each payment to available vitality above one point. If the payment reaches that floor, dissolve only our army. Require at least **ten seconds, 25% vitality and more than one vitality** to rearm; preserve per-slot deadlines and prevent immediate collapse/respawn loops. Upkeep cannot kill Geralt and must not heal him if his vitality is already below one. Enemy attacks and the dependency retain their own damage/cost behavior.

Match Geralt's level at creation. Preserve native combat inventory/monster weapons; suppress summon loot through clearInvOnDeath. Apply size to the same animated/mesh component types used by the reference. Visual scale does not prove a proportional collision capsule. Keep configurable damage and upkeep settings limited to our units.

## Combat lifecycle and placement

Each of ten slots has an independent ten-second replacement deadline. Preserve living members when another dies. Failed placement/resource attempts back off ten seconds per slot. Limit spawn attempts to two per quarter-second update. Missing resources omit that slot without silently changing monster identity.

Ordinary combat end fades owned actors and destroys them after one second. Existing hooks clean up for scenes, death, fast travel, teleport, disabling and game end. No manual summon input, exploration followers, saved controller fields or new progression facts. Pending replacements and invisible/distant/teleporting actors must not leave stragglers.

Use five paired flank rows for ten units. Prefer formation, then four bounded alternatives. Check 1.2-metre navigation clearance, four-metre search radius, height within two metres of Geralt, and a clear 0.4-metre navigation line. This addresses observed across-wall placement; it is not a general mesh intersection test or template-derived footprint.

## Implementation and release sequence

1. Replace fixed roster/implicit leader with ten configurable army slots.
2. Add dependency activation, ally exclusions and damage handling while retaining wrapped calls.
3. Add shared vitality upkeep/recovery and bounded damage/size controls.
4. Compile production and a separate combined-source compatibility check; validate XML and archive contents.
5. Install both production mods in a disposable profile and complete acceptance below. Restore production after diagnostics; never save test immortality/book grants to a real save.
6. Prepare Nexus description, dependency requirement, credits/license and changelog. Publish only after acceptance and explicit upload authorization.

## Final acceptance

| Case | Required evidence |
| --- | --- |
| Both mods | Both menus visible; trophy summon and army coexist without duplicate implicit leader or shared cooldown. |
| Dependency | Read/equipped book and eligible trophy start both; fresh save without dependency cannot activate army. Audit stale dependency facts on reload. |
| Configuration | Sizes 0/1/4/10, mixed roster, unused slots, invalid values, settings persistence and next-encounter changes; never over ten owned army actors including fade windows. |
| Every monster | Safe placement, actual native health loss/incoming damage, scale/animations, death, no unowned children or summon loot/XP farming. |
| Allies/rewards | Neither mod selects or damages the other's units; verify no duplicate rewards or unintended progression effects. |
| Upkeep | Compare 1/4/10 living units: all cost 1 vitality/second by default; no stamina drain or regeneration delay; verify Signs still cast. Exclude all-dead/cooldown/fading states and pauses; zero cost option; clamp to one vitality without killing/healing Geralt; dismiss army only; rearm after ten seconds AND 25% vitality AND more than one vitality. Verify migration ignores old stamina settings. |
| Independent loss | Stagger two deaths; replacements respect separate ten-second deadlines and preserve survivors. |
| Cleanup | Combat end during cooldown, scenes/travel/teleport/swimming/death/disable: zero owned actors and no late spawns. |
| Road benchmark | Four wraiths plus original trophy leader versus two same-level mortal drowners, idle Geralt. Log health loss/time/stamina/settings; target roughly twenty seconds, not a claim based on one fast run. |
| Crowding/performance | Ten varied units plus trophy summon on open/confined terrain; bounded requests, no accumulating entities or unsafe floor/wall spawns. |
| Persistence | Disposable save/reload/uninstall leaves no saved army/controller dependency. |
| Packaging | Fresh Vortex installation of both mods, startup, menus, disable/redeploy; no reference/diagnostic/combined blob. |

Historical prototype evidence in docs/verification.md does not sign off this companion version.
