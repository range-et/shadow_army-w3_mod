// Shadow Monarch 1.0.0-rc1 - Trophy Necromancy companion, target 5.0.0.1090142.
// No saved fields or custom facts; Trophy Necromancy owns its own summon/state.
@addField(W3PlayerWitcher)
var smController : SMController;

@addMethod(W3PlayerWitcher)
function SMEnsure() : SMController
{
    if(!smController)
    {
        smController = new SMController in this;
        smController.Init(this);
        RemoveTimer('SMUpdate');
        AddTimer('SMUpdate', 0.25, true);
    }
    return smController;
}

@addMethod(W3PlayerWitcher)
timer function SMUpdate(dt : float, id : int)
{
    if(smController) smController.Tick(dt);
}

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
    wrappedMethod(spawnData);
    SMEnsure();
}

@wrapMethod(W3PlayerWitcher)
function OnCombatStart()
{
    wrappedMethod();
    SMEnsure().Tick(0);
}

@wrapMethod(W3PlayerWitcher)
function OnCombatFinished()
{
    if(smController) smController.Cleanup(false);
    wrappedMethod();
}

@wrapMethod(W3PlayerWitcher)
function OnBlockingSceneStarted(scene : CStoryScene)
{
    if(smController) smController.Cleanup(true);
    wrappedMethod(scene);
}

@wrapMethod(W3PlayerWitcher)
function OnDeath(damageAction : W3DamageAction)
{
    if(smController) smController.Cleanup(true);
    wrappedMethod(damageAction);
}

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
    wrappedMethod(restored);
    if(GetWitcherPlayer()) GetWitcherPlayer().SMEnsure();
}

@wrapMethod(CR4Game)
function OnGameEnded()
{
    if(GetWitcherPlayer() && GetWitcherPlayer().smController)
        GetWitcherPlayer().smController.Cleanup(true);
    wrappedMethod();
}

@wrapMethod(CR4Game)
function SetIsDialogOrCutscenePlaying(b : bool)
{
    if(b && GetWitcherPlayer() && GetWitcherPlayer().smController)
        GetWitcherPlayer().smController.Cleanup(true);
    wrappedMethod(b);
}

@wrapMethod(CCommonMapManager)
function OnFastTravelInitiated(pinTag : name, areaID : name)
{
    if(GetWitcherPlayer() && GetWitcherPlayer().smController)
        GetWitcherPlayer().smController.Cleanup(true);
    wrappedMethod(pinTag, areaID);
}

@wrapMethod(CR4Player)
function OnTeleported()
{
    if(GetWitcherPlayer() && GetWitcherPlayer().smController)
        GetWitcherPlayer().smController.Cleanup(true);
    wrappedMethod();
}

@addField(CNewNPC)
var smOwned : bool;

// Apply the squad balance bonus to native, already processed hostile hits.
// Misses, attack cadence, armour and native combat equipment remain relevant.
@wrapMethod(CActor)
function OnTakeDamage(action : W3DamageAction)
{
    var source, victim : CNewNPC;
    var multiplier : float;
    source = (CNewNPC)action.attacker;
    victim = (CNewNPC)this;
    if(source && ((source.smOwned && (this == thePlayer || HasTag('TrophyNecromancy_npc') || HasTag('TrophyNecromancy_doppelganger') || (victim && victim.smOwned)
        || (GetAttitude(thePlayer) != AIA_Hostile && thePlayer.GetAttitude(this) != AIA_Hostile)))
        || ((source.HasTag('TrophyNecromancy_npc') || source.HasTag('TrophyNecromancy_doppelganger')) && victim && victim.smOwned)))
    {
        action.processedDmg.vitalityDamage = 0;
        action.processedDmg.essenceDamage = 0;
    }
    else if(source && source.smOwned && GetAttitude(thePlayer) == AIA_Hostile)
    {
        multiplier = 1;
        if(GetWitcherPlayer() && GetWitcherPlayer().smController) multiplier = GetWitcherPlayer().smController.damageMultiplier;
        if(action.processedDmg.vitalityDamage > 0) action.processedDmg.vitalityDamage *= multiplier;
        if(action.processedDmg.essenceDamage > 0) action.processedDmg.essenceDamage *= multiplier;
    }
    wrappedMethod(action);
}

// Prevent reference/vanilla wraith splitting from producing unowned minions.
@wrapMethod(CBTTaskWraithSummonDoppelganger)
function Main() : EBTNodeStatus
{
    var result : EBTNodeStatus;
    if(GetNPC() && GetNPC().smOwned) return BTNS_Completed;
    result = wrappedMethod();
    return result;
}

@wrapMethod(CNewNPC)
function ShouldGiveExp(attacker : CGameplayEntity) : bool
{
    var result : bool;
    var source : CNewNPC;
    result = wrappedMethod(attacker);
    if(smOwned) return false;
    source = (CNewNPC)attacker;
    if(source && source.smOwned && GetAttitude(thePlayer) == AIA_Hostile && VecDistance(thePlayer.GetWorldPosition(), GetWorldPosition()) <= 30) return true;
    return result;
}

class SMController
{
    var player : W3PlayerWitcher;
    var units : array<CNewNPC>;
    var readyAt : array<float>;
    var removeAt : array<float>;
    var paths : array<string>;
    var templates : array<CEntityTemplate>;
    var occupied : array<bool>;
    var clock : float;
    var encounter : bool;
    var count : int;
    var damageMultiplier : float;
    var sizeMultiplier : float;
    var upkeep : float;
    var fatigued : bool;
    var recoverAt : float;
    var rosterKeys : array<name>;

    function Init(p : W3PlayerWitcher)
    {
        var i : int;
        player = p;
        units.Resize(10);
        occupied.Resize(10);
        readyAt.Resize(10);
        removeAt.Resize(10);
        paths.Resize(10);
        templates.Resize(10);
        damageMultiplier = 1.5;
        sizeMultiplier = 0.75;
        rosterKeys.PushBack('Unit1');
        rosterKeys.PushBack('Unit2');
        rosterKeys.PushBack('Unit3');
        rosterKeys.PushBack('Unit4');
        rosterKeys.PushBack('Unit5');
        rosterKeys.PushBack('Unit6');
        rosterKeys.PushBack('Unit7');
        rosterKeys.PushBack('Unit8');
        rosterKeys.PushBack('Unit9');
        rosterKeys.PushBack('Unit10');
        // Initialize missing settings after loading a game so the menu and
        // runtime fallbacks agree. Preserve every explicit player value.
        DefaultSetting('Enabled', "true");
        DefaultSetting('ArmySize', "4");
        DefaultSetting('DamagePercent', "150");
        DefaultSetting('SizePercent', "75");
        DefaultSetting('UpkeepPerSecond', "1");
        for(i = 0; i < rosterKeys.Size(); i += 1) DefaultSetting(rosterKeys[i], "0");
    }

    function DefaultSetting(id : name, value : string)
    {
        if(theGame.GetInGameConfigWrapper().GetVarValue('ShadowMonarch', id) == "")
            theGame.GetInGameConfigWrapper().SetVarValue('ShadowMonarch', id, value);
    }

    function Enabled() : bool
    {
        var value : string;
        value = theGame.GetInGameConfigWrapper().GetVarValue('ShadowMonarch', 'Enabled');
        return value != "false" && value != "0";
    }

    function Eligible() : bool
    {
        return player && thePlayer == player && player.IsAlive() && player.IsInCombat()
            && Enabled() && !theGame.IsDialogOrCutscenePlaying()
            && !player.IsSwimming() && !player.GetHorseCurrentlyMounted() && !player.IsInFistFight()
            && !player.IsSwordWooden() && !player.IsItemEquippedByName('Snow Ball')
            // Read-only dependency handshake: set/cleared by Trophy Necromancy's
            // own combat hooks. A stale settings XML alone cannot start an army.
            && FactsQuerySum("TrophyNecromancy_timerstarted") > 0
            && player.IsItemEquippedByName('lore_necromancy')
            && player.inv.GetItemQuantityByName('lore_necromancy') > 0
            && player.inv.IsBookReadByName('lore_necromancy');
    }

    function MonsterPath(kind : int) : string
    {
        switch(kind)
        {
            case 1: return "characters/npc_entities/monsters/nekker_lvl1.w2ent";
            case 2: return "characters/npc_entities/monsters/ghoul_lvl1.w2ent";
            case 3: return "characters/npc_entities/monsters/drowner_lvl1.w2ent";
            case 4: return "characters/npc_entities/monsters/arachas_lvl1.w2ent";
            case 5: return "characters/npc_entities/monsters/wyvern_lvl1.w2ent";
            case 6: return "characters/npc_entities/monsters/czart_lvl1.w2ent";
            case 7: return "characters/npc_entities/monsters/bies_lvl1.w2ent";
            case 8: return "characters/npc_entities/monsters/cockatrice_lvl1.w2ent";
            case 9: return "characters/npc_entities/monsters/gryphon_lvl1.w2ent";
            case 10: return "characters/npc_entities/monsters/gryphon_lvl3__volcanic.w2ent";
        }
        return "characters/npc_entities/monsters/wraith_lvl1.w2ent";
    }

    function Setting(id : name, fallback : int, minimum : int, maximum : int) : int
    {
        var value : string;
        value = theGame.GetInGameConfigWrapper().GetVarValue('ShadowMonarch', id);
        if(value == "") return fallback;
        return Clamp(StringToInt(value), minimum, maximum);
    }

    function Begin()
    {
        var i : int;
        count = Setting('ArmySize', 4, 0, 10);
        damageMultiplier = Setting('DamagePercent', 150, 25, 300) / 100.0;
        sizeMultiplier = Setting('SizePercent', 75, 40, 100) / 100.0;
        upkeep = FloatSetting('UpkeepPerSecond', 1, 0, 5);
        for(i = 0; i < count; i += 1)
        {
            paths[i] = MonsterPath(Setting(rosterKeys[i], 0, 0, 10));
            templates[i] = NULL;
        }
        encounter = true;
        LogChannel('ShadowMonarch', "Army begin count=" + count + " upkeep=" + upkeep + " damage=" + damageMultiplier + " scale=" + sizeMultiplier);
    }

    function FloatSetting(id : name, fallback : float, minimum : float, maximum : float) : float
    {
        var value : string;
        value = theGame.GetInGameConfigWrapper().GetVarValue('ShadowMonarch', id);
        if(value == "") return fallback;
        return MaxF(minimum, MinF(maximum, StringToFloat(value)));
    }

    function Cleanup(immediate : bool)
    {
        var i : int;
        encounter = false;
        for(i = 0; i < units.Size(); i += 1)
        {
            if(units[i])
            {
                if(removeAt[i] == 0)
                {
                    readyAt[i] = clock + 10;
                    units[i].StopAllEffects();
                    units[i].PlayEffect('demonic_possession');
                    units[i].Fade(false);
                    units[i].SetTemporaryAttitudeGroup('neutral_to_player', AGP_Default);
                    units[i].EnableCharacterCollisions(false);
                    removeAt[i] = clock + 1.0;
                }
                if(immediate)
                {
                    units[i].Destroy();
                    units[i] = NULL;
                    occupied[i] = false;
                    removeAt[i] = 0;
                }
            }
        }
    }

    function Tick(dt : float)
    {
        var i, j, spawned, living : int;
        var cost : float;
        var target : CActor;
        var trophy : CNewNPC;
        var nearby : array<CActor>;
        if(theGame.IsPaused()) return;
        clock += dt;
        for(i = 0; i < units.Size(); i += 1)
        {
            if(removeAt[i] > 0 && clock >= removeAt[i])
            {
                if(units[i]) units[i].Destroy();
                units[i] = NULL;
                    occupied[i] = false;
                removeAt[i] = 0;
            }
        }
        if(!Eligible())
        {
            Cleanup(theGame.IsDialogOrCutscenePlaying() || !player.IsAlive() || thePlayer != player || !Enabled());
            return;
        }
        if(fatigued)
        {
            if(clock < recoverAt || player.GetStatPercents(BCS_Stamina) < 0.25) return;
            fatigued = false;
        }
        if(!encounter) Begin();
        trophy = theGame.GetNPCByTag('TrophyNecromancy_npc');
        target = player.GetTarget();
        if(!IsEnemy(target))
        {
            target = NULL;
            nearby = player.GetNPCsAndPlayersInRange(30, 128, '', FLAG_OnlyAliveActors);
            for(j = 0; j < nearby.Size(); j += 1)
                if(IsEnemy(nearby[j]) && (!target || VecDistanceSquared(nearby[j].GetWorldPosition(), player.GetWorldPosition()) < VecDistanceSquared(target.GetWorldPosition(), player.GetWorldPosition())))
                    target = nearby[j];
        }
        for(i = 0; i < count; i += 1)
        {
            if(removeAt[i] > 0) continue;
            if(occupied[i] && (!units[i] || !units[i].IsAlive()))
            {
                LogChannel('ShadowMonarch', "Lost slot=" + i + " time=" + clock);
                if(units[i]) units[i].Destroy();
                units[i] = NULL;
                    occupied[i] = false;
                readyAt[i] = clock + 10;
            }
            if(!units[i] && clock >= readyAt[i] && spawned < 2)
            {
                Spawn(i);
                spawned += 1;
            }
            if(units[i] && units[i].IsAlive())
            {
                living += 1;
                if(trophy)
                {
                    units[i].SetAttitude(trophy, AIA_Friendly);
                    trophy.SetAttitude(units[i], AIA_Friendly);
                }
            }
            if(units[i] && target)
            {
                if(units[i].GetAttitude(target) != AIA_Hostile)
                {
                    units[i].SetAttitude(target, AIA_Hostile);
                    units[i].SignalGameplayEvent('AI_RequestCombatEvaluation');
                }
                if(target.GetAttitude(units[i]) != AIA_Hostile)
                {
                    target.SetAttitude(units[i], AIA_Hostile);
                    target.SignalGameplayEvent('AI_RequestCombatEvaluation');
                }
                if(units[i].GetTarget() != target)
                {
                    units[i].NoticeActor(target);
                    units[i].SignalGameplayEventParamObject('ForceTarget', target);
                }
            }
        }
        cost = living * upkeep * MaxF(0, MinF(dt, 1));
        if(cost > 0)
        {
            if(player.GetStat(BCS_Stamina) <= cost)
            {
                player.DrainStamina(ESAT_FixedValue, cost, 0.35);
                fatigued = true;
                recoverAt = clock + 10;
                Cleanup(false);
                LogChannel('ShadowMonarch', "Army exhausted; recovery requires 10 seconds and 25 percent stamina");
            }
            else player.DrainStamina(ESAT_FixedValue, cost, 0.35);
        }
    }

    function IsEnemy(actor : CActor) : bool
    {
        var npc : CNewNPC;
        if(!actor || actor == player || !actor.IsAlive() || actor.HasTag('GeraltsBFF')
            || actor.HasTag('TrophyNecromancy_npc') || actor.HasTag('TrophyNecromancy_ent')
            || actor.HasTag('TrophyNecromancy_doppelganger')) return false;
        npc = (CNewNPC)actor;
        if(npc && npc.smOwned) return false;
        return actor.GetAttitude(player) == AIA_Hostile || player.GetAttitude(actor) == AIA_Hostile;
    }

    function Spawn(slot : int)
    {
        var desired, safe, forward, right, origin, candidate : Vector;
        var z, side, distance : float;
        var attempt : int;
        var placed : bool;
        var entity : CEntity;
        var npc : CNewNPC;
        var animated, mesh : CComponent;
        // Backoff even on failure; no busy retry loops or duplicate requests.
        readyAt[slot] = clock + 10;
        if(!templates[slot]) templates[slot] = (CEntityTemplate)LoadResource(paths[slot], true);
        if(!templates[slot]) return;
        forward = player.GetWorldForward();
        origin = player.GetWorldPosition();
        right = Vector(forward.Y, -forward.X, 0);
        side = 1;
        if(slot % 2 == 1) side = -1;
        distance = 3.5 - (slot / 2) * 2.0;
        desired = player.GetWorldPosition() + forward * distance + right * side * 3;
        // A safe point alone can lie across a wall or inside a building.
        // Prefer formation, then test four bounded alternatives on Geralt's side.
        for(attempt = 0; attempt < 5; attempt += 1)
        {
            candidate = desired;
            if(attempt == 1) candidate = origin + forward * 4.5;
            if(attempt == 2) candidate = origin + right * 4.5;
            if(attempt == 3) candidate = origin - right * 4.5;
            if(attempt == 4) candidate = origin - forward * 4.5;
            if(!theGame.GetWorld().NavigationFindSafeSpot(candidate, 1.2, 4, safe)) continue;
            if(!theGame.GetWorld().NavigationComputeZ(safe, origin.Z - 2, origin.Z + 2, z)) continue;
            safe.Z = z;
            if(!theGame.GetWorld().NavigationLineTest(origin, safe, 0.4)) continue;
            placed = true;
            break;
        }
        if(!placed)
        {
            LogChannel('ShadowMonarch', "Placement blocked slot=" + slot + " time=" + clock);
            return;
        }
        entity = theGame.CreateEntity(templates[slot], safe, player.GetWorldRotation(), true, false, false, PM_DontPersist);
        npc = (CNewNPC)entity;
        if(!npc)
        {
            if(entity) entity.Destroy();
            return;
        }
        units[slot] = npc;
        occupied[slot] = true;
        npc.smOwned = true;
        npc.AddTag('sm_shadow_unit');
        LogChannel('ShadowMonarch', "Spawn slot=" + slot + " time=" + clock);
        npc.clearInvOnDeath = true;
        // Native monster weapons live in inventory too. Keep them equipped;
        // clearInvOnDeath suppresses loot in the native death task.
        npc.SetLevel(player.GetLevel());
        animated = npc.GetComponentByClassName('CAnimatedComponent');
        mesh = npc.GetComponentByClassName('CMeshComponent');
        if(animated) animated.SetScale(Vector(sizeMultiplier, sizeMultiplier, sizeMultiplier, 1));
        if(mesh) mesh.SetScale(Vector(sizeMultiplier, sizeMultiplier, sizeMultiplier, 1));
        npc.SetTemporaryAttitudeGroup('player', AGP_Default);
        npc.SetAttitude(player, AIA_Friendly);
        player.SetAttitude(npc, AIA_Friendly);
        npc.SetTatgetableByPlayer(false);
        npc.EnableCharacterCollisions(false);
        npc.PlayEffect('demonic_possession');
        npc.Fade(true);
    }
}
