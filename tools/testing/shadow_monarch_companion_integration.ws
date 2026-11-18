// Disposable-save controlled driver. Real Trophy Necromancy must be enabled.
// No dependency fact/counter edits or book/unlock injection. Only Geralt is
// temporarily immortal. Stage 1 enemies are mortal; later targets isolate
// upkeep/slot behavior and are explicitly invulnerable, never balance evidence.
@addField(W3PlayerWitcher) var smITPhase : int;
@addField(W3PlayerWitcher) var smITTime : float;
@addField(W3PlayerWitcher) var smITTotal : float;
@addField(W3PlayerWitcher) var smITIdle : float;
@addField(W3PlayerWitcher) var smITLast : Vector;
@addField(W3PlayerWitcher) var smITEnemies : array<CNewNPC>;
@addField(W3PlayerWitcher) var smITKeys : array<name>;
@addField(W3PlayerWitcher) var smITValues : array<string>;
@addField(W3PlayerWitcher) var smITKilled1 : bool;
@addField(W3PlayerWitcher) var smITKilled2 : bool;

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
    wrappedMethod(spawnData);
    smITPhase = 0;
    smITTime = 0;
    smITTotal = 0;
    smITIdle = 0;
    smITLast = GetWorldPosition();
    AddTimer('SMIntegrationSequence', 1, true);
}

@addMethod(W3PlayerWitcher)
function SMITConfigure(phase : int)
{
    var c : SMController;
    var i : int;
    c = SMEnsure();
    if(phase == 1) theGame.GetInGameConfigWrapper().SetVarValue('ShadowMonarch', 'ArmySize', "4");
    else if(phase == 5) theGame.GetInGameConfigWrapper().SetVarValue('ShadowMonarch', 'ArmySize', "0");
    else theGame.GetInGameConfigWrapper().SetVarValue('ShadowMonarch', 'ArmySize', "10");
    theGame.GetInGameConfigWrapper().SetVarValue('ShadowMonarch', 'Enabled', "true");
    theGame.GetInGameConfigWrapper().SetVarValue('ShadowMonarch', 'DamagePercent', "150");
    theGame.GetInGameConfigWrapper().SetVarValue('ShadowMonarch', 'SizePercent', "75");
    theGame.GetInGameConfigWrapper().SetVarValue('ShadowMonarch', 'UpkeepPerSecond', "1");
    if(phase == 7) theGame.GetInGameConfigWrapper().SetVarValue('ShadowMonarch', 'UpkeepPerSecond', "0");
    for(i = 0; i < c.rosterKeys.Size(); i += 1)
    {
        theGame.GetInGameConfigWrapper().SetVarValue('ShadowMonarch', c.rosterKeys[i], "0");
        if(phase == 3 && i >= 5) theGame.GetInGameConfigWrapper().SetVarValue('ShadowMonarch', c.rosterKeys[i], "1");
    }
    GainStat(BCS_Stamina, GetStatMax(BCS_Stamina));
}

@addMethod(W3PlayerWitcher)
function SMITSpawn(phase : int)
{
    var i, number, attempt : int;
    var origin, desired, safe, right, forward : Vector;
    var z : float;
    var template : CEntityTemplate;
    var enemy : CNewNPC;
    origin = GetWorldPosition();
    forward = GetWorldForward();
    right = Vector(forward.Y, -forward.X, 0);
    template = (CEntityTemplate)LoadResource("characters/npc_entities/monsters/drowner_lvl1.w2ent", true);
    smITEnemies.Clear();
    number = 1;
    if(phase == 1) number = 2;
    for(i = 0; i < number; i += 1)
    {
        enemy = NULL;
        for(attempt = 0; attempt < 8; attempt += 1)
        {
            if(attempt == 0) desired = origin + forward * 4 + right * (i * 3 - 1.5);
            else if(attempt == 1) desired = origin - forward * 4;
            else if(attempt == 2) desired = origin + right * 4;
            else if(attempt == 3) desired = origin - right * 4;
            else if(attempt == 4) desired = origin + forward * 2;
            else if(attempt == 5) desired = origin - forward * 2;
            else if(attempt == 6) desired = origin + right * 2;
            else desired = origin - right * 2;
            if(!theGame.GetWorld().NavigationFindSafeSpot(desired, 0.5, 2, safe)) continue;
            if(!theGame.GetWorld().NavigationComputeZ(safe, origin.Z - 2, origin.Z + 2, z)) continue;
            safe.Z = z;
            if(!theGame.GetWorld().NavigationLineTest(origin, safe, 0.4)) continue;
            enemy = (CNewNPC)theGame.CreateEntity(template, safe, GetWorldRotation(), true, false, false, PM_DontPersist);
            if(enemy) break;
        }
        if(!enemy) continue;
        enemy.SetLevel(GetLevel());
        if(phase != 1) enemy.SetImmortalityMode(AIM_Invulnerable, AIC_Default, true);
        enemy.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
        enemy.SetAttitude(this, AIA_Hostile);
        enemy.NoticeActor(this);
        enemy.SignalGameplayEventParamObject('ForceTarget', this);
        smITEnemies.PushBack(enemy);
    }
    LogChannel('ShadowMonarch', "IT START phase=" + phase + " enemies=" + smITEnemies.Size() + " expected=" + number);
    if(smITEnemies.Size() != number)
    {
        LogChannel('ShadowMonarch', "IT INVALID SETUP; waiting 35 seconds to retry from a new position");
        for(i = 0; i < smITEnemies.Size(); i += 1) if(smITEnemies[i]) smITEnemies[i].Destroy();
        smITEnemies.Clear();
        smITPhase = phase - 1;
        smITTime = 0;
    }
}

@addMethod(W3PlayerWitcher)
function SMITFinishPhase(alive : int)
{
    var i : int;
    LogChannel('ShadowMonarch', "IT RESULT phase=" + smITPhase + " seconds=" + smITTime + " survivors=" + alive);
    // Leave army/dependency cleanup to their own real combat-end hooks.
    for(i = 0; i < smITEnemies.Size(); i += 1)
        if(smITEnemies[i]) smITEnemies[i].Destroy();
    smITEnemies.Clear();
    smITPhase += 1;
    smITTime = 0;
}

@addMethod(W3PlayerWitcher)
timer function SMIntegrationSequence(dt : float, id : int)
{
    var c : SMController;
    var i, alive : int;
    var trophy : SItemUniqueId;
    var entities : array<CEntity>;
    if(theGame.IsPaused() || theGame.IsDialogOrCutscenePlaying()) return;
    smITTime += dt;
    smITTotal += dt;
    c = SMEnsure();
    if(smITPhase == 0)
    {
        if(VecDistanceSquared(smITLast, GetWorldPosition()) < 0.25) smITIdle += dt;
        else smITIdle = 0;
        smITLast = GetWorldPosition();
        if(!GetHorseManager() || !GetHorseManager().GetInventoryComponent()) return;
        trophy = GetHorseManager().GetItemInSlot(EES_HorseTrophy);
        if(smITTotal < 45 || smITIdle < 10 || IsInCombat() || !IsItemEquippedByName('lore_necromancy')
            || !inv.IsBookReadByName('lore_necromancy') || !GetHorseManager().GetInventoryComponent().IsIdValid(trophy)) return;
        smITKeys.PushBack('Enabled');
        smITKeys.PushBack('ArmySize');
        smITKeys.PushBack('DamagePercent');
        smITKeys.PushBack('SizePercent');
        smITKeys.PushBack('UpkeepPerSecond');
        for(i = 0; i < c.rosterKeys.Size(); i += 1) smITKeys.PushBack(c.rosterKeys[i]);
        for(i = 0; i < smITKeys.Size(); i += 1) smITValues.PushBack(theGame.GetInGameConfigWrapper().GetVarValue('ShadowMonarch', smITKeys[i]));
        SetImmortalityMode(AIM_Immortal, AIC_Default, true);
        smITPhase = 1;
        smITTime = 0;
        SMITConfigure(smITPhase);
        SMITSpawn(smITPhase);
    }
    else if(smITPhase == 1 || smITPhase == 3 || smITPhase == 5 || smITPhase == 7)
    {
        for(i = 0; i < smITEnemies.Size(); i += 1)
        {
            if(smITEnemies[i] && smITEnemies[i].IsAlive()) alive += 1;
            if(smITEnemies[i]) LogChannel('ShadowMonarch', "IT HP phase=" + smITPhase + " t=" + smITTime + " enemy=" + i + " hp=" + smITEnemies[i].GetHealth());
        }
        if(smITPhase == 7)
        {
            if(smITTime >= 10 && !smITKilled1 && c.units[0])
            {
                smITKilled1 = true;
                c.units[0].Kill('SMIntegrationTest', true, this);
            }
            if(smITTime >= 14 && !smITKilled2 && c.units[1])
            {
                smITKilled2 = true;
                c.units[1].Kill('SMIntegrationTest', true, this);
            }
        }
        if(alive == 0 || (smITPhase == 1 && smITTime >= 75)
            || (smITPhase == 3 && smITTime >= 45) || (smITPhase == 5 && smITTime >= 15)
            || (smITPhase == 7 && smITTime >= 35)) SMITFinishPhase(alive);
    }
    else
    {
        if(smITTime >= 10)
        {
            theGame.GetEntitiesByTag('sm_shadow_unit', entities);
            LogChannel('ShadowMonarch', "IT INTERMISSION phase=" + smITPhase + " combat=" + IsInCombat() + " world=" + entities.Size());
        }
        if(smITPhase == 8 && smITTime >= 15)
        {
            for(i = 0; i < smITKeys.Size(); i += 1) theGame.GetInGameConfigWrapper().SetVarValue('ShadowMonarch', smITKeys[i], smITValues[i]);
            LogChannel('ShadowMonarch', "IT COMPLETE; quit without saving diagnostic immortality");
            RemoveTimer('SMIntegrationSequence');
        }
        else if(smITPhase < 8 && smITTime >= 35 && !IsInCombat())
        {
            smITPhase += 1;
            smITTime = 0;
            SMITConfigure(smITPhase);
            SMITSpawn(smITPhase);
        }
    }
}
