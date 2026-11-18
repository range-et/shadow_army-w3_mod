// Three full-squad benchmarks. Only idle Geralt is immortal.
@addField(W3PlayerWitcher)
var smBenchTime : float;
@addField(W3PlayerWitcher)
var smBenchTotal : float;
@addField(W3PlayerWitcher)
var smBenchPhase : int;
@addField(W3PlayerWitcher)
var smBenchEnemies : array<CNewNPC>;
@addField(W3PlayerWitcher)
var smBenchLeaderLogged : bool;
@addField(W3PlayerWitcher)
var smBenchOrigin : Vector;
@addField(W3PlayerWitcher)
var smBenchRound : int;

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
    wrappedMethod(spawnData);
    smBenchTime = 0;
    smBenchTotal = 0;
    smBenchPhase = 0;
    smBenchRound = 0;
    AddTimer('SMBenchSequence', 1, true);
}

@wrapMethod(SMController)
function Begin()
{
    wrappedMethod();
    if(player.smBenchPhase == 1) count = 5;
    if(player.smBenchPhase == 3 || player.smBenchPhase == 5) count = 5;
}

@wrapMethod(SMController)
function Eligible() : bool
{
    return wrappedMethod() && (player.smBenchPhase == 1 || player.smBenchPhase == 3 || player.smBenchPhase == 5);
}

@addMethod(W3PlayerWitcher)
function SMBenchSpawnEnemies(number : int)
{
    var i : int;
    var template : CEntityTemplate;
    var position, origin : Vector;
    var enemy : CNewNPC;
    var z : float;
    smBenchEnemies.Clear();
    origin = GetWorldPosition();
    template = (CEntityTemplate)LoadResource("characters/npc_entities/monsters/drowner_lvl1.w2ent", true);
    for(i = 0; i < number; i += 1)
    {
        if(!theGame.GetWorld().NavigationFindSafeSpot(GetWorldPosition() + GetWorldForward() * 3 + Vector(i * 2, 0, 0), 0.5, 2, position)) continue;
        if(!theGame.GetWorld().NavigationComputeZ(position, origin.Z - 5, origin.Z + 5, z)) continue;
        position.Z = z;
        if(!theGame.GetWorld().NavigationLineTest(origin, position, 0.4)) continue;
        enemy = (CNewNPC)theGame.CreateEntity(template, position, GetWorldRotation(), true, false, false, PM_DontPersist);
        if(!enemy) continue;
        enemy.SetLevel(GetLevel());
        enemy.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
        enemy.SetAttitude(this, AIA_Hostile);
        enemy.NoticeActor(this);
        enemy.SignalGameplayEventParamObject('ForceTarget', this);
        smBenchEnemies.PushBack(enemy);
        LogChannel('ShadowMonarch', "BENCH enemy=" + i + " level=" + enemy.GetLevel() + " hp=" + enemy.GetHealth());
    }
    LogChannel('ShadowMonarch', "BENCH phase=" + smBenchPhase + " START enemies=" + smBenchEnemies.Size() + " total=" + smBenchTotal);
}

@addMethod(W3PlayerWitcher)
function SMBenchClear()
{
    var i : int;
    for(i = 0; i < smBenchEnemies.Size(); i += 1)
        if(smBenchEnemies[i]) smBenchEnemies[i].Destroy();
    smBenchEnemies.Clear();
    if(smController) smController.Cleanup(true);
}

@addMethod(W3PlayerWitcher)
timer function SMBenchSequence(dt : float, id : int)
{
    var c : SMController;
    var i, alive, squad : int;
    var safe : Vector;
    var origin, forward, right, candidate : Vector;
    var z : float;
    var entities : array<CEntity>;
    if(theGame.IsPaused() || theGame.IsDialogOrCutscenePlaying()) return;
    smBenchTime += dt;
    smBenchTotal += dt;
    c = SMEnsure();
    if(smBenchPhase == 0 && smBenchTime >= 10)
    {
        if(inv.GetItemQuantityByName('lore_necromancy') == 0) inv.AddAnItem('lore_necromancy', 1);
        inv.ReadBookByName('lore_necromancy', false, true);
        SetImmortalityMode(AIM_Immortal, AIC_Default, true);
        smBenchOrigin = GetWorldPosition();
        origin = smBenchOrigin;
        forward = GetWorldForward();
        right = Vector(forward.Y, -forward.X, 0);
        // Diagnostic location only: seek nearby open ground while requiring
        // the same floor and a clear navigation line from the loaded street.
        for(i = 0; i < 8; i += 1)
        {
            candidate = origin + forward * 12;
            if(i == 1) candidate = origin - forward * 12;
            if(i == 2) candidate = origin + right * 12;
            if(i == 3) candidate = origin - right * 12;
            if(i == 4) candidate = origin + (forward + right) * 10;
            if(i == 5) candidate = origin + (forward - right) * 10;
            if(i == 6) candidate = origin + (right - forward) * 10;
            if(i == 7) candidate = origin - (right + forward) * 10;
            if(!theGame.GetWorld().NavigationFindSafeSpot(candidate, 3, 4, safe)) continue;
            if(!theGame.GetWorld().NavigationComputeZ(safe, origin.Z - 2, origin.Z + 2, z)) continue;
            safe.Z = z;
            if(!theGame.GetWorld().NavigationLineTest(origin, safe, 0.4)) continue;
            smBenchOrigin = safe;
            Teleport(safe);
            LogChannel('ShadowMonarch', "BENCH OPEN LOCATION x=" + safe.X + " y=" + safe.Y + " z=" + safe.Z);
            break;
        }
        // Retain the loaded save's known playable street; never teleport to
        // a large-radius navigation result inside unmodelled city interiors.
        smBenchPhase = -1;
        smBenchTime = 0;
        smBenchLeaderLogged = false;
    }
    else if(smBenchPhase == -1 && smBenchTime >= 3)
    {
        smBenchPhase = 1;
        smBenchTime = 0;
        SMBenchSpawnEnemies(2);
    }
    else if(smBenchPhase == 1 || smBenchPhase == 3 || smBenchPhase == 5)
    {
        for(i = 0; i < smBenchEnemies.Size(); i += 1)
        {
            if(smBenchEnemies[i] && smBenchEnemies[i].IsAlive()) alive += 1;
            if(smBenchEnemies[i]) LogChannel('ShadowMonarch', "BENCH phase=" + smBenchPhase + " t=" + smBenchTime + " enemy=" + i + " hp=" + smBenchEnemies[i].GetHealth());
        }
        for(i = 0; i < c.units.Size(); i += 1)
            if(c.units[i] && c.units[i].IsAlive()) squad += 1;
        if(c.units[0] && !smBenchLeaderLogged)
        {
            smBenchLeaderLogged = true;
            LogChannel('ShadowMonarch', "BENCH LEADER display=" + c.units[0].GetDisplayName() + " path=" + c.paths[0] + " level=" + c.units[0].GetLevel());
        }
        LogChannel('ShadowMonarch', "BENCH phase=" + smBenchPhase + " t=" + smBenchTime + " alive=" + alive + " squad=" + squad);
        if(alive == 0 || smBenchTime >= 75)
        {
            LogChannel('ShadowMonarch', "BENCH RESULT phase=" + smBenchPhase + " elapsed=" + smBenchTime + " survivors=" + alive);
            if(alive > 0) SMBenchClear();
            else smBenchEnemies.Clear();
            smBenchPhase += 1;
            smBenchTime = 0;
        }
    }
    else if((smBenchPhase == 2 || smBenchPhase == 4) && smBenchTime >= 10)
    {
        theGame.GetEntitiesByTag('sm_shadow_unit', entities);
        LogChannel('ShadowMonarch', "BENCH INTERMISSION combat=" + IsInCombat() + " world=" + entities.Size());
        Teleport(smBenchOrigin);
        smBenchPhase = -smBenchPhase;
        smBenchTime = 0;
    }
    else if((smBenchPhase == -2 || smBenchPhase == -4) && smBenchTime >= 5)
    {
        smBenchPhase = -smBenchPhase + 1;
        smBenchTime = 0;
        smBenchLeaderLogged = false;
        SMBenchSpawnEnemies(2);
    }
    else if(smBenchPhase == 6 && smBenchTime >= 15)
    {
        theGame.GetEntitiesByTag('sm_shadow_unit', entities);
        LogChannel('ShadowMonarch', "BENCH CLEANUP combat=" + IsInCombat() + " world=" + entities.Size());
        if(smBenchTime >= 25)
        {
            smBenchRound += 1;
            if(smBenchRound >= 2) RemoveTimer('SMBenchSequence');
            else
            {
                smBenchOrigin = GetWorldPosition();
                smBenchPhase = -1;
                smBenchTime = 0;
                smBenchLeaderLogged = false;
                LogChannel('ShadowMonarch', "BENCH ROUND=" + smBenchRound);
            }
        }
    }
}

@wrapMethod(CNewNPC)
function OnTakeDamage(action : W3DamageAction)
{
    var source : CNewNPC;
    var before : float;
    source = (CNewNPC)action.attacker;
    before = GetHealth();
    wrappedMethod(action);
    if(source && source.smOwned)
        LogChannel('ShadowMonarch', "BENCH HIT phase=" + GetWitcherPlayer().smBenchPhase + " t=" + GetWitcherPlayer().smBenchTime + " source=" + source + " before=" + before + " after=" + GetHealth() + " dealt=" + action.GetDamageDealt());
}
