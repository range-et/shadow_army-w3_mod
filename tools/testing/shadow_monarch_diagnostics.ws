// Acceptance-test harness only; does not bypass summon eligibility.
function SMStatus()
{
    var p : W3PlayerWitcher;
    var c : SMController;
    var i, owned : int;
    var entities : array<CEntity>;
    var message : string;
    p = GetWitcherPlayer();
    if(!p) return;
    c = p.SMEnsure();
    for(i = 0; i < c.units.Size(); i += 1)
        if(c.units[i]) owned += 1;
    theGame.GetEntitiesByTag('sm_shadow_unit', entities);
    message = "SM combat=" + p.IsInCombat() + " eligible=" + c.Eligible() + " handles=" + owned + " world=" + entities.Size();
    for(i = 0; i < c.units.Size(); i += 1)
        message += " [" + i + ":" + MaxF(0, c.readyAt[i] - c.clock) + "]";
    LogChannel('ShadowMonarch', message);
    theGame.GetGuiManager().ShowNotification(message);
}
function SMKillUnit(slot : int)
{
    var c : SMController;
    if(!GetWitcherPlayer()) return;
    c = GetWitcherPlayer().SMEnsure();
    if(slot >= 0 && slot < c.units.Size() && c.units[slot])
        c.units[slot].Kill('SMTest', true, thePlayer);
}

@addField(W3PlayerWitcher)
var smTestEnemy : CNewNPC;

function SMStartTest()
{
    var p : W3PlayerWitcher;
    var template : CEntityTemplate;
    var position : Vector;
    p = GetWitcherPlayer();
    if(!p || p.smTestEnemy) return;
    if(!theGame.GetWorld().NavigationFindSafeSpot(p.GetWorldPosition() + p.GetWorldForward() * 8, 1, 3, position)) return;
    template = (CEntityTemplate)LoadResource("characters/npc_entities/monsters/drowner_lvl1.w2ent", true);
    if(!template) return;
    p.smTestEnemy = (CNewNPC)theGame.CreateEntity(template, position, p.GetWorldRotation(), true, false, false, PM_DontPersist);
    if(!p.smTestEnemy) return;
    p.smTestEnemy.SetLevel(p.GetLevel());
    p.smTestEnemy.SetImmortalityMode(AIM_Immortal, AIC_Default, true);
    p.smTestEnemy.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
    p.smTestEnemy.SetAttitude(p, AIA_Hostile);
    p.smTestEnemy.NoticeActor(p);
    p.smTestEnemy.SignalGameplayEventParamObject('ForceTarget', p);
}

function SMEndTest()
{
    var p : W3PlayerWitcher;
    p = GetWitcherPlayer();
    if(p && p.smTestEnemy)
    {
        p.smTestEnemy.Destroy();
        p.smTestEnemy = NULL;
    }
}

@addField(W3PlayerWitcher)
var smTestTime : float;
@addField(W3PlayerWitcher)
var smTestPhase : int;

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
    wrappedMethod(spawnData);
    smTestTime = 0;
    smTestPhase = 0;
    AddTimer('SMTestSequence', 1, true);
}

@addMethod(W3PlayerWitcher)
timer function SMTestSequence(dt : float, id : int)
{
    var c : SMController;
    var i : int;
    var safe : Vector;
    if(theGame.IsPaused() || theGame.IsDialogOrCutscenePlaying()) return;
    smTestTime += dt;
    if(smTestPhase == 0 && smTestTime < 10) return;
    c = SMEnsure();
    if(smTestPhase > 0)
        for(i = 0; i < c.units.Size(); i += 1)
            if(c.units[i]) c.units[i].SetImmortalityMode(AIM_Immortal, AIC_Default, true);
    if(smTestPhase == 0)
    {
        if(inv.GetItemQuantityByName('lore_necromancy') == 0) inv.AddAnItem('lore_necromancy', 1);
        inv.ReadBookByName('lore_necromancy', false, true);
        if(theGame.GetWorld().NavigationFindSafeSpot(GetWorldPosition(), 4, 20, safe)) Teleport(safe);
        SetImmortalityMode(AIM_Immortal, AIC_Default, true);
        SMStartTest();
        smTestPhase = 1;
        smTestTime = 0;
        theGame.GetGuiManager().ShowNotification("SM TEST: hostile enemy created; waiting for native combat");
    }
    else if(smTestPhase == 1 && smTestTime >= 15)
    {
        for(i = 0; i < c.units.Size(); i += 1)
            if(c.units[i]) c.units[i].SetImmortalityMode(AIM_Immortal, AIC_Default, true);
        SMStatus();
        smTestPhase = 2;
        smTestTime = 0;
    }
    else if(smTestPhase == 2 && smTestTime >= 8)
    {
        SMKillUnit(1);
        theGame.GetGuiManager().ShowNotification("SM TEST: killed slot 1");
        smTestPhase = 3;
        smTestTime = 0;
    }
    else if(smTestPhase == 3 && smTestTime >= 4)
    {
        SMKillUnit(2);
        SMStatus();
        smTestPhase = 4;
        smTestTime = 0;
    }
    else if(smTestPhase == 4 && smTestTime >= 4)
    {
        SMStatus();
        smTestPhase = 5;
        smTestTime = 0;
    }
    else if(smTestPhase == 5 && smTestTime >= 4)
    {
        SMStatus();
        smTestPhase = 6;
        smTestTime = 0;
    }
    else if(smTestPhase == 6 && smTestTime >= 4)
    {
        SMStatus();
        smTestPhase = 7;
        smTestTime = 0;
    }
    else if(smTestPhase == 7 && smTestTime >= 8)
    {
        SMEndTest();
        theGame.GetGuiManager().ShowNotification("SM TEST: enemy removed; waiting for native combat end");
        smTestPhase = 8;
        smTestTime = 0;
    }
    else if(smTestPhase == 8 && smTestTime >= 15)
    {
        SMStatus();
        smTestPhase = 9;
        smTestTime = 0;
    }
    else if(smTestPhase == 9 && smTestTime >= 8)
    {
        SMStatus();
        RemoveTimer('SMTestSequence');
    }
}



@wrapMethod(CNewNPC)
function OnTakeDamage(action : W3DamageAction)
{
    var source : CNewNPC;
    source = (CNewNPC)action.attacker;
    if(source && source.smOwned)
        LogChannel('ShadowMonarch', "Owned attack -> " + this + " damage=" + action.processedDmg.vitalityDamage);
    wrappedMethod(action);
}
