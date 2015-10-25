// MutatH0r.CRZMutator_SuperStingray
// ----------------
// Less damage per plasma ball, but splash damage and levitation effect
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_SuperStingray extends UTMutator config (MutatH0r);

struct TaggedPawnInfo
{
  var Pawn Pawn;
  var float ExpirationTime;
  var float ComboExtraDamage;
};

var config float DamagePlasma, DamageBeam, DamageCombo;
var config float KnockbackPlasma, DamageRadius;
var config float TagDuration;
var config float DamageFactorSelf, DamageFactorSplash, LevitationSelf, LevitationOthers;
var array<TaggedPawnInfo> TaggedPawns;
var LinearColor TagColor;


replication
{
  if (bNetInitial && Role == ENetRole.ROLE_Authority)
    DamagePlasma, DamageRadius, KnockbackPlasma; // DamageBeam, DamageCombo, 
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
  local int i;

  // clean up list of pawns tagged for combo-damage
  for (i=0; i<TaggedPawns.Length; i++)
  {
    if (WorldInfo.TimeSeconds >= TaggedPawns[i].ExpirationTime)
    {
      TaggedPawns.Remove(i, 1);
      --i;
    }
  }

  // tweak plasma Plasmas
  foreach WorldInfo.DynamicActors(class'Projectile', proj)
  {
    if (string(proj.Class) == "CRZProj_ScionRifle" && proj.Damage != DamagePlasma)
    {
      proj.Damage = DamagePlasma;
      proj.DamageRadius = DamageRadius;
      proj.MomentumTransfer = KnockbackPlasma;
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
  local int tagInfoIndex;
  local TaggedPawnInfo tagInfo;

  Super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

  if (instr(string(DamageType), "CRZDmgType_Scion") >=0)
  {
    victim = UTPawn(Injured);
    isSelfDamage = Injured == InstigatedBy.Pawn;

    if (!isSelfDamage && DamageCombo != 0 && TagDuration != 0)
    {
      tagInfoIndex = GetTaggedPawnInfoIndex(victim);
      if (tagInfoIndex >= 0)
        tagInfo = TaggedPawns[tagInfoIndex];

      if (string(DamageType) == "CRZDmgType_Scion_Plasma")
      {
        tagInfo.ExpirationTime = WorldInfo.TimeSeconds + TagDuration;
        tagInfo.ComboExtraDamage += DamageCombo;
        if (tagInfoIndex < 0)
        {
          tagInfo.Pawn = Injured;
          TaggedPawns.Add(1);
          tagInfoIndex = TaggedPawns.Length - 1;
        }
        TaggedPawns[tagInfoIndex] = tagInfo;
        victim.SetBodyMatColor(TagColor, TagDuration);

        if (Damage != DamagePlasma)
          Damage *= DamageFactorSplash;
      }
      else if (string(DamageType) == "CRZDmgType_ScionRifle")
        Damage += tagInfo.ComboExtraDamage;
    }

    if (isSelfDamage)
      Damage *= DamageFactorSelf;

    if (string(DamageType) == "CRZDmgType_Scion_Plasma")
    {
      Momentum.Z += isSelfDamage ? LevitationSelf : LevitationOthers;
    }
  }
}

function int GetTaggedPawnInfoIndex(Pawn pawn)
{
  local int i;
  for (i=0; i<TaggedPawns.Length; i++)
  {
    if (TaggedPawns[i].Pawn == pawn)
      return i;
  }
  return -1;
}


function Mutate(string MutateString, PlayerController Sender)
{
  local string msg;
  if (MutateString == "sr_info")
  {
    msg = "Plasma: dp=" $ DamagePlasma $ ", dr=" $ DamageRadius $ ", dfs=" $ DamageFactorSplash $ ", dfi=" $ DamageFactorSelf $ ", kbp=" $ KnockbackPlasma;
    `log(msg); Sender.ClientMessage(msg, 'Info');
    msg = "Beam:   db=" $ DamageBeam $ ", dc=" $ DamageCombo $ ", td=" $ TagDuration;
    `log(msg); Sender.ClientMessage(msg, 'Info');
    msg = "Levitation: lo=" $ LevitationOthers $ ", ls=" $ LevitationSelf;
    `log(msg); Sender.ClientMessage(msg, 'Info');
  }
  else if (left(MutateString, 6) == "sr_dp ")
    DamagePlasma = float(mid(MutateString, 6));
  else if (left(MutateString, 6) == "sr_dr ")
    DamageRadius = float(mid(MutateString, 6));
  else if (left(MutateString, 7) == "sr_dfs ")
    DamageFactorSplash = float(mid(MutateString, 7));
  else if (left(MutateString, 7) == "sr_dfi ")
    DamageFactorSelf = float(mid(MutateString, 7));
  else if (left(MutateString, 7) == "sr_kbp ")
    KnockbackPlasma = float(mid(MutateString, 7));
  else if (left(MutateString, 6) == "sr_db ")
    DamageBeam = float(mid(MutateString, 6));
  else if (left(MutateString, 6) == "sr_dc ")
    DamageCombo = float(mid(MutateString, 6));
  else if (left(MutateString, 6) == "sr_td ")
    TagDuration = float(mid(MutateString, 6));
  else if (left(MutateString, 6) == "sr_ls ")
    LevitationSelf = float(mid(MutateString, 6));
  else if (left(MutateString, 6) == "sr_lo ")
    LevitationOthers = float(mid(MutateString, 6));
  else
    super.Mutate(MutateString, Sender);
}

defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true

  //TagDuration=1.0
  TagColor=(A=255.0, R=0.0, G=128.0, B=0.0)
  //DamagePlasma=17
  //DamageRadius=120
  //DamageBeam=50
  //DamageCombo=50
  //KnockbackPlasma=20000
  //LevitationSelf=50
  //ExtraUpOthers=100
  //SelfDamageFactor=0
}