// Observer only. No enemies, book grants, immortality or eligibility overrides.
// Install only for disposable-save tests, alongside the real Trophy Necromancy.
@wrapMethod(CActor)
function DrainVitality(amount : float)
{
    var before : float;
    before = GetHealth();
    wrappedMethod(amount);
    if(this == thePlayer)
        LogChannel('ShadowMonarch', "UPKEEP vitality request=" + amount + " before=" + before + " after=" + GetHealth());
}

@wrapMethod(W3PlayerWitcher)
function OnSignCastPerformed(signType : ESignType, isAlternate : bool)
{
    wrappedMethod(signType, isAlternate);
    LogChannel('ShadowMonarch', "SIGN performed=" + signType + " combat=" + IsInCombat() + " stamina=" + GetStat(BCS_Stamina));
}

@addField(W3PlayerWitcher)
var smObserverTime : float;

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
    wrappedMethod(spawnData);
    smObserverTime = 0;
    AddTimer('SMCompanionObserver', 1, true);
}

@addMethod(W3PlayerWitcher)
timer function SMCompanionObserver(dt : float, id : int)
{
    var c : SMController;
    var trophy : CNewNPC;
    var entities : array<CEntity>;
    var i, living, fading : int;
    var position : Vector;
    if(theGame.IsPaused()) return;
    smObserverTime += dt;
    c = SMEnsure();
    for(i = 0; i < c.units.Size(); i += 1)
    {
        if(c.units[i] && c.units[i].IsAlive() && c.removeAt[i] == 0) living += 1;
        if(c.units[i] && c.removeAt[i] > 0) fading += 1;
    }
    trophy = theGame.GetNPCByTag('TrophyNecromancy_npc');
    theGame.GetEntitiesByTag('sm_shadow_unit', entities);
    position = GetWorldPosition();
    LogChannel('ShadowMonarch', "COMPANION t=" + smObserverTime + " combat=" + IsInCombat()
        + " eligible=" + c.Eligible() + " living=" + living + " fading=" + fading
        + " world=" + entities.Size() + " configured=" + c.count
        + " vitality=" + GetHealth() + " stamina=" + GetStat(BCS_Stamina) + " fatigued=" + c.fatigued
        + " trophy=" + trophy + " x=" + position.X + " y=" + position.Y + " z=" + position.Z);
}

@wrapMethod(CNewNPC)
function OnTakeDamage(action : W3DamageAction)
{
    var source : CNewNPC;
    var before : float;
    source = (CNewNPC)action.attacker;
    before = GetHealth();
    wrappedMethod(action);
    if(source && (source.smOwned || source.HasTag('TrophyNecromancy_npc') || source.HasTag('TrophyNecromancy_doppelganger')))
        LogChannel('ShadowMonarch', "COMPANION HIT source=" + source + " army=" + source.smOwned
            + " victim=" + this + " before=" + before + " after=" + GetHealth()
            + " actualLoss=" + (before - GetHealth()));
}
