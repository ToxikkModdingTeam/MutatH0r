// MutatH0r.CRZMutator_SuperStingray
// ----------------
// Little plasma ball damage, but splash damage and strong knockback
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_SuperStingray extends UTMutator config (MutatH0r);

var float DamageBall, DamageBeam, DamageCombo;
var float KnockbackBall, DamageRadius, ExtraUpOthers;
var float TagDuration;
var LinearColor TagColor;
var config float SelfDamageFactor, ExtraUpSelf;
var bool EnableCombos;


replication
{
  if (bNetInitial && Role == ENetRole.ROLE_Authority)
    DamageBall, DamageRadius, KnockbackBall; // DamageBeam, DamageCombo, 
}


simulated event PreBeginPlay()
{
  super.PreBeginPlay();
  SetTickGroup(ETickingGroup.TG_PreAsyncWork);
  Enable('Tick');
}

simulated function Tick(float DeltaTime)
{
  local Projectile proj;

  foreach WorldInfo.DynamicActors(class'Projectile', proj)
  {
    if (string(proj.Class) == "CRZProj_ScionRifle" && proj.Damage != DamageBall)
    {
      proj.Damage = DamageBall;
      proj.DamageRadius = DamageRadius;
      proj.MomentumTransfer = KnockbackBall;
    }
  }
}

function bool CheckReplacement(Actor Other)
{
  local UTWeapon w;

  if (string(Other.Class) == "CRZWeap_ScionRifle")
  {
    w = UTWeapon(Other);
    w.InstantHitDamage[1] = DamageBeam;
  }

  return Super.CheckReplacement(Other);
}


function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
  local UTPawn victim;
  local bool isSelfDamage;

  Super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

  if (instr(string(DamageType), "CRZDmgType_Scion") >=0)
  {
    isSelfDamage = Injured == InstigatedBy.Pawn;

    if (isSelfDamage)
      Damage *= SelfDamageFactor;

    if (EnableCombos && !isSelfDamage)
    {
      victim = UTPawn(Injured);
      if (string(DamageType) == "CRZDmgType_Scion_Plasma")
        victim.SetBodyMatColor(TagColor, TagDuration);
      else if (string(DamageType) == "CRZDmgType_Scion_Rifle")
      {
        if (victim.BodyMatColor == TagColor && victim.RemainingBodyMatDuration >= 0)
          Damage = DamageCombo;
      }
    }

    if (string(DamageType) == "CRZDmgType_Scion_Plasma")
    {
      Momentum.Z += isSelfDamage ? ExtraUpSelf : ExtraUpOthers;
    }
  }
}


function Mutate(string MutateString, PlayerController Sender)
{  
  if (left(MutateString, 3) == "kb ")
    KnockbackBall = float(mid(MutateString, 3));
  else if (left(MutateString, 3) == "up ")
    ExtraUpOthers = float(mid(MutateString, 3));
  else if (left(MutateString, 3) == "us ")
    ExtraUpSelf = float(mid(MutateString, 3));
  else if (left(MutateString, 3) == "dr ")
    DamageRadius = float(mid(MutateString, 3));
  else if (left(MutateString, 3) == "db ")
    DamageBall = float(mid(MutateString, 3));
  else if (left(MutateString, 3) == "sd ")
    SelfDamageFactor = float(mid(MutateString, 3));
  else
    super.Mutate(MutateString, Sender);
}

defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true

  TagDuration=1.0
  TagColor=(A=255.0, G=128.0, B=128.0)
  DamageBall=17
  DamageRadius=120
  DamageBeam=45
  DamageCombo=65
  KnockbackBall=20000
  //ExtraUpSelf=50
  ExtraUpOthers=200
  //SelfDamageFactor=0
  EnableCombos=false
}