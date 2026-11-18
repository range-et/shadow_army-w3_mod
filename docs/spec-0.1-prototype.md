Historical standalone prototype specification. Superseded by ../spec.md for v1; its installation and roster instructions are not current.

# modShadowMonarch — Specification and Implementation Plan

## 1. Objective and target

Build a standalone WitcherScript mod inspired by Solo Leveling's Shadow Monarch. Geralt summons one trophy-selected monster leader and three or four allied wraiths. Summons fight his enemies, do not obstruct movement or attract player targeting, automatically materialize when combat starts, and dissolve away when combat ends or a safety transition occurs. No manual summon controls are provided.

Target the installed Windows build inspected on 2026-11-18:

- Game root: `E:\SteamLibrary\steamapps\common\The Witcher 3`.
- DX12 executable file/product version: `5.0.0.1090142`.
- Steam manifest build ID: `26238013`.
- Installed sources: `content/content0/scripts`.
- Version 4.04 compatibility is outside initial scope. Recheck signatures if the installation updates.

Use annotations and existing game resources where supported. Avoid full vanilla-file replacements, custom DLC, persistent companion systems, and runtime dependencies on reference mods. Annotations reduce conflicts; they do not guarantee compatibility with every mod or eliminate all possible merging needs.

This document describes intended behavior and the implementation plan. See docs/verification.md for completed compilation/runtime checks and remaining acceptance cases.

## 2. Source evidence and remaining discovery

The local reference directory is `references/`:

- Trophy Necromancy: `trophynecromancy.ws` provides trophy mappings, book integration, combat hooks, and spawning examples. Its facts, progression, and quest templates must not be copied wholesale.
- Multi Companion Mod Remastered (MCME): player/NPC hooks, `MultiCompanionModSpawn.ws`, `SpawnCompanionsSCMCC.ws`, and mount scripts provide initialization, collision, attitude, and persistence examples. Its persistent companion architecture is outside scope.

Trophy Necromancy is currently installed in the game's `Mods` directory. Disable it in the initial test profile to avoid competing book-triggered summons. Simultaneous operation is not an initial compatibility promise. Do not modify or remove its existing save data.

### Verified declarations and observed patterns

| Concern | Local evidence | Implementation consequence |
| --- | --- | --- |
| Combat | `W3PlayerWitcher.OnCombatStart()` and `OnCombatFinished()` | Use these names, not a presumed `OnCombatEnd`. |
| Blocking scenes | `W3PlayerWitcher.OnBlockingSceneStarted(scene : CStoryScene)` | Candidate for cleanup before scene handling; audit other scene paths. |
| Other lifecycle paths | Player `OnDeath`, `CR4Player.OnTeleported`, `CR4Game.OnGameStarting/OnGameStarted/OnGameEnded`, common map manager travel functions | Inspect call order and coverage before choosing wrappers. Post-teleport cleanup alone is insufficient for pre-transition safety. |
| Trophy | Reference uses `GetHorseManager().GetItemInSlot(EES_HorseTrophy)` and the horse inventory | Validate manager, inventory, and item before resolving its name. |
| Persistence | `engine/game.ws`: `CreateEntity` accepts `EPersistanceMode`; vanilla and MCME examples use `PM_DontPersist` | Explicit nonpersistent creation is required in addition to unsaved fields. |
| Targeting | `game/actor.ws`: `SetTatgetableByPlayer(isTargetAble : bool)` | Preserve that exact spelling. Do not assume `SetCanBeTargeted` exists. |
| Collision | `CActor.EnableCharacterCollisions(enable : bool) : bool`, used by MCME | First prototype candidate; attacks and grounding require runtime validation. |
| Movement | `SetPushable(bool)` exists; `SetVirtualRadiusImmediately` takes a `CName` preset | Neither proves pass-through behavior. Do not pass a numeric radius to the preset API. |
| Placement | `engine/world.ws`: `NavigationFindSafeSpot` and `NavigationComputeZ` | Use bounded, validated navigation placement. |
| AI | Trophy Necromancy uses `NoticeActor` and a `ForceTarget` event; MCME uses temporary attitude groups with `AGP_Default` | Candidate patterns, not guarantees for all templates. |
| Book | Trophy Necromancy references `lore_necromancy` and `IsBookReadByName` | Reuse the existing book; verify availability without that mod enabled. |

Both references contain annotated visibility modifiers, timers, and events. Replace the previous blanket compiler restrictions with a minimal compiler smoke test against this build. A reference file's existence is not proof that it compiles.

Record exact resource paths and DLC requirements during implementation. A path appearing in a reference script is not proof that it loads or behaves safely.

## 3. Functional requirements

### 3.1 Unlock and configuration

- Ownership and read status of the existing `lore_necromancy` book unlock automatic combat summoning.
- Do not require quick-slot equipment or copy the reference's radial-menu fact hacks.
- No replacement book, automatic book grant, or custom progression in the initial release.
- Settings: mod enabled (default on) and wraith count (3 or 4; default 4). Disabling the mod immediately cleans up the squad. The roster uses common enemy monsters, with wraiths preferred; no named story companions or hero copies.
- Use centralized defaults for the prototype, then a settings-menu XML with required menu registration for release. Invalid settings fall back safely.
- Trophy and composition changes affect the next summon, not the active squad.

### 3.2 Composition and formation

- One boss slot maps Roach's trophy item name to a tested monster template. Real identifiers include `q002_griffin_trophy`; do not guess generic item IDs.
- Use only approved generic enemy templates matching monster identity. Quest-specific actors and named-character templates are excluded from the initial roster.
- Missing/unsupported trophies, absent DLC, or failed mapped resources use one verified generic archgriffin fallback. If the fallback cannot load or fit safely, omit the boss and report the failure.
- Use tested generic wraiths as the army, preserving their native combat teleportation where supported. Prefer ordinary, commonly encountered enemy templates. Exclude Yennefer, Triss, Geralt/Ciri copies, named story characters, unique quest bosses, and doppler mappings that impersonate those characters. The trophy-selected leader must also resolve to a generic monster from an explicit allowlist; unsupported trophies use the verified generic archgriffin fallback. Nightwraith variants require individual validation; other army types are deferred.
- Current formation: leader 4.5 metres behind Geralt; wraiths use front/rear flank offsets, three metres to either side. Exact angular formation and alternating rear flanks are deferred.
- Placement checks navigation with 1.2-metre clearance and a four-metre search radius, checks height within two metres of Geralt, and requires a clear 0.4-metre navigation line from Geralt to the result. Try the formation position and up to four bounded front/side/rear alternatives. Reject points across walls. Template-derived clearance and arbitrary path connectivity remain pending.
- Bound placement attempts. Reject walls, unsuitable floors, cliffs, water, and disconnected navigation; omit failed slots rather than forcing placement.
- Formation describes initial placement. Continuous tactical flanking and a general exploration-following system are outside initial scope.

### 3.3 Fully automatic combat lifecycle

- Combat entry requests a squad when the book unlock is satisfied, the mod is enabled, and gameplay is safe. There is no manual key binding, input listener, or summon console command.
- Summoning is combat-only. Combat end cancels pending spawns/replacements and dissolves every owned unit, including distant, invisible, or teleporting wraiths. No exploration followers or stragglers remain.
- Reject spawning during dialogue/cutscenes, fistfights, scripted nonlethal combat, swimming/diving, death, loading, or world transitions. Initial support is Geralt only; clean up on player replacement.
- Repeated combat callbacks must not duplicate squads. After a safety interruption, reevaluate only when ordinary safe combat resumes; a cooldown expiry alone must not trigger spawning.
- Mounted combat spawning requires verified safe placement; otherwise defer until eligible combat resumes on foot.

### 3.4 Independent 10-second unit cooldowns

- Each formation slot, including the monster leader, has its own cooldown. There is no shared army cooldown. Initially eligible slots spawn when combat begins.
- When a unit dies or is confirmed lost, clean up its remains and start that slot's 10-second replacement delay. Native invisibility, teleportation, or distance alone must not count as death/loss.
- If combat remains active and eligible when the delay ends, spawn one replacement in that slot at a safe position near Geralt. Other living units remain unchanged. A full squad wipe can recover through independent replacements.
- Combat-end or safety removal starts a 10-second delay for occupied slots. Preserve existing deadlines on empty slots; repeated cleanup must not restart them. Keep deadlines across adjacent encounters in the current session so combat flicker cannot bypass them.
- Count time using a verified unpaused gameplay clock. Cooldowns are transient and reset on loading/new session; do not introduce saved facts.
- Each slot permits at most one live/dissolving unit or pending spawn. Replacement must not overlap unfinished removal.
- Cancel pending replacements on combat end, disable, or safety transitions. At execution, recheck combat and eligibility. An expired deadline never authorizes an out-of-combat spawn.
- Failed loading/placement uses bounded attempts and a 10-second per-slot retry backoff, not a per-frame spawn loop.
- Snapshot trophy/composition for the encounter. Replacements use the same approved slot template; the next encounter uses current settings and trophy.

### 3.5 Combat and collision

- Attack living enemies hostile to Geralt; ignore Geralt and friendly/neutral actors. Enemies must be able to target and damage summons.
- Prototype a verified temporary attitude group with `AGP_Default` and test mutual attitudes. A group name alone is not proof of correct targeting.
- Validate targets before directing AI; reacquire safely after target death or invalidation. Never blindly dereference Geralt's target.
- Prefer Geralt's living hostile target; otherwise select the nearest living hostile within a bounded 30-metre/128-actor query. Exclude owned summons and tagged companions. Establish mutual hostility and request AI evaluation only when attitudes change; force a target only when it differs from the summon’s current target.
- Use `SetTatgetableByPlayer(false)` and test soft-lock, hard-lock, Whirl, and friendly-fire behavior.
- Prototype `EnableCharacterCollisions(false)` first. Geralt must walk, sprint, dodge, and roll through each supported unit while attacks still hit enemies and the unit stays grounded.
- Do not globally disable physics or attack collisions. Do not substitute immortality or stagger immunity for testing incoming damage.
- Preserve native combat inventory/monster weapons; suppress summon loot with clearInvOnDeath rather than clearing inventory at spawn. Measure actual victim health loss and a natural kill against a mortal enemy; a hit event alone is insufficient. Default to four wraiths, with three selectable. Initial balance: match Geralt's level at creation, preserve native AI/attacks and wraith teleportation, and multiply successful owned-summon hits against hostiles by 1.5. Apply the bonus once to positive processed vitality/essence damage; never inject damage for misses. Target roughly 20 seconds for four wraiths plus the archgriffin to defeat two same-level drowners with Geralt idle; record measured times and placement delays. No progression or health cost. A replacement is a new temporary unit after its independent cooldown, not a resurrected corpse.
- Summon deaths must not yield farmable loot or XP. Preserve normal enemy kill rewards where feasible without duplicate awards; validate summon kill credit explicitly.
- Exclude templates that create uncontrolled minions, quest side effects, or persistent artifacts until those behaviors can be safely managed.

## 4. Architecture and persistence

Keep the implementation primarily in `mods/modShadowMonarch/content/scripts/local/shadow_monarch.ws`, using a small controller, narrow wrappers, and uniquely prefixed symbols.

The controller owns eligibility checks, template resolution, placement, creation/initialization, live and dead unit tracking, pending work, per-slot cooldown deadlines, combat eligibility, and cleanup. Track ownership by entity handles, independent of distance, visibility, and teleport state.

Use explicitly initialized transient fields. Do not serialize the controller, army, cooldown state, or custom facts. Do not attach persistent bookkeeping to vanilla enemies or MCME systems.

Create summons and mod-owned effects explicitly with `PM_DontPersist`. Unsaved references alone are insufficient. Audit template-created children, corpses, loot, and effects too.

Normal book inventory/read status, external configuration, and legitimate combat outcomes may persist. The requirement is **no persistent mod-owned summon or progression state**, not byte-identical saves or no ordinary gameplay changes. Do not delete existing Trophy Necromancy facts.

Choose synchronous or asynchronous creation after API inspection and loading measurements. Bound initialization work. Asynchronous creation, if used, must invalidate cancelled requests and destroy late arrivals after combat end, scenes, disable, or world changes.

Use file-scope annotations on the correct defining class, one added field per annotation, and compile-tested signatures. Each wrapper calls `wrappedMethod` exactly once per execution path and preserves its return value. Select a verified update hook or supported timer; avoid unbounded per-frame scans.

## 5. Cleanup and effects

Clean up on combat end, mod disable, dialogue/blocking scene or cutscene entry, death/player replacement, fast travel/world transition, and shutdown/reload where hooks permit.

1. Prevent new spawning and invalidate pending work.
2. Destroy only controller-owned entities, handling invalid handles and dead actors safely.
3. Clear ownership and reset appropriate transient state. Preserve existing per-slot deadlines and prevent respawning until combat is eligible again.
4. Reinitialize transient state after loading without restored summons or duplicate controllers.

Cleanup must be idempotent and cover all owned units, corpses, controlled children, and late spawn callbacks, including invisible, teleporting, distant, and off-screen wraiths. Never restrict cleanup to a proximity or visibility query.

Materialization on combat entry/replacement and dissolve on normal combat end are required release behavior, using Trophy Necromancy's griffin as the presentation reference. Inspect that reference's actual effects and verify compatible resources on each approved template; do not assume effects transfer unchanged.

Stop combat activity immediately on normal cleanup and enforce a short, bounded destruction deadline selected during visual testing. Retain ownership through dissolution, or use a separately owned nonpersistent effect after removing the actor if that achieves the intended appearance. Safety cleanup bypasses visual delays. Missing effects must never prevent destruction. Every effect and child entity needs bounded cleanup; no stragglers may remain.

Scene safety and Frame Generation behavior are regression tests, not a claim that this mod fixes an established engine crash.

## 6. Implementation phases

### Phase 1 — Compiler and API foundation

Verify build, annotations, wrapper ownership/signatures, persistence arguments, and update/timer support. Audit scene, travel, reload, and player-replacement paths. Compile a minimal mod before gameplay work.

**Exit:** minimal lifecycle hooks compile; API and hook decisions are documented against installed sources.

### Phase 2 — Single-summon feasibility prototype

Create one generic wraith with explicit nonpersistence. Prove safe placement, attitudes, AI attacks, player targeting exclusion, pass-through movement, incoming damage, native teleportation, materialization/dissolve, cleanup during teleportation, and save/load behavior. Validate its independent 10-second replacement cycle. Inspect child entities and death side effects.

**Exit:** all core checks pass in game. If available script APIs cannot satisfy them together, document the failure and revise scope before expanding the squad. Do not silently weaken requirements.

### Phase 3 — Controller and lifecycle

Implement ownership, bounded spawn attempts, automatic combat eligibility, independent cooldowns/replacements, dead-unit handling, pending-work cancellation, and safety hooks.

**Exit:** staggered deaths produce independent replacements after 10 seconds. Combat end and safety transitions cancel replacements and remove every actor without duplicates or stragglers.

### Phase 4 — Trophy squad and formation

Build an audited trophy mapping, verify fallback/DLC behavior, add three/four vanguard slots, and test size-aware placement. Validate each additional template independently.

**Exit:** supported mappings load reliably; unsafe or missing slots fail gracefully without retry loops or quest side effects.

### Phase 5 — Book, settings, and presentation

Verify the book independently of Trophy Necromancy. Add ownership/read gating, settings XML/menu registration, and required tested materialization/dissolve effects.

**Exit:** unlock and configuration work without either reference mod; the roster contains only approved generic enemy monsters and compatibility limits are documented.

### Phase 6 — Packaging and regression validation

Produce a Vortex-installable package. Test clean deployment first, then the intended mod combination in a disposable profile/save. Record performance, compatibility, and limitations.

**Exit:** the acceptance matrix passes for supported templates on the tested build. Compilation alone cannot satisfy runtime checks.

## 7. Acceptance matrix

| Scenario | Required result |
| --- | --- |
| Compilation/startup | No mod-attributable compilation errors; one controller. |
| Book gating | Automatic summoning obeys ownership/read status without custom facts. |
| Automatic lifecycle | Combat begins: eligible slots materialize. Combat ends: all units dissolve and pending replacements are cancelled. No manual controls or out-of-combat summons. |
| Independent cooldowns | Kill two units several seconds apart: each returns no earlier than 10 seconds after its own death; living units remain unchanged. The leader follows the same rule. |
| Squad wipe | Slots refill independently while combat is eligible; no duplicate full-army spawn. |
| Combat end during cooldown | No pending replacement appears after combat; deadlines carry across adjacent encounters. |
| Teleport/dissolve | Cleanup during invisibility, teleportation, or off-screen combat leaves no actors, corpses, children, or lingering effects. |
| Roster | Only allowlisted generic enemy monsters spawn, including for doppler/unsupported trophies; never Triss, Yennefer, or other named-character copies. |
| Combat | Units engage hostiles, ignore friendlies, and deal/receive damage. |
| Movement/targeting | Walking, sprinting, dodging, and rolling through units work; soft-lock, hard-lock, and Whirl do not select them. |
| Placement | Rooms, doorways, slopes, stairs, bridges, cliffs, and large bosses fail safely when space is insufficient. |
| Missing resources | Unknown/no trophy, missing DLC, failed loads/casts, and invalid navigation do not crash or leave unmanaged actors. |
| Lifecycle | Combat end, scenes, death, fast travel, world change, and player replacement remove owned units and prevent late spawning. |
| Save/reload | Save with active summons where the game permits it (including combat autosaves if available); reload restores no army, orphaned actors/effects, or mod-owned persistent state. |
| Uninstall/reload | Loading a disposable test save after removal leaves no summon dependency or stranded actor. |
| Rewards/children | No summon loot/XP farming, duplicate kill rewards, uncontrolled minions, or persistent death artifacts. |
| Repeated operation | Repeated deaths, replacements, encounters, and enable/disable cycles do not grow entity/controller counts or cause accumulating frame-time cost. |
| Vortex | Install, disable, and redeploy without input edits or packaging reference mods. |
| Rendering | Test the user's normal DX12/Frame Generation setup for scene regressions and record its configuration. |

Use meaningful in-game checks and lightweight static validation where useful. Verify the actual diagnostic/log locations and command-line options before documenting `-debugscripts` or `scriptlog.txt` as supported. Supplement reload/uninstall checks with save inspection where tooling permits; save size alone cannot prove the absence of serialized state.

## 8. Deliverables

1. `mods/modShadowMonarch/content/scripts/local/shadow_monarch.ws`, with comments explaining engine-sensitive decisions.
2. Settings-menu XML and required registration files/instructions for the target build.
3. Documentation of the automatic lifecycle, per-unit cooldown semantics, and required book unlock. No `input.settings` edits or summon console commands.
4. Supported trophy/template list, DLC requirements, excluded quest-specific variants, and fallback behavior.
5. Vortex-ready package containing only this mod's required files, plus installation, configuration, compatibility, and removal instructions.
6. Verification checklist and test report distinguishing source-verified declarations, compilation, completed runtime checks, and unresolved limitations.

The first gameplay milestone is the single-summon feasibility prototype. Full squad implementation depends on its collision, combat, lifecycle, and persistence results.
