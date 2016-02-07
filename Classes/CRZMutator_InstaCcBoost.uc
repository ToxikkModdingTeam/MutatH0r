// CRZMutator_InstaCcBoost
// ----------------
// adds knockback to the instagib weapon and disables spawn protection
//================================================================

class CRZMutator_InstaCcBoost extends UTMutator config (MutatH0r);

var config bool SpawnProtection;
var config int TeamDamage; // defaults to 0
var config float HitMomentum; // defaults to 250000

function bool MutatorIsAllowed()
{
  return CRZCellCapture(WorldInfo.Game) != None && Super.MutatorIsAllowed();
}

function InitMutator(string Options, out string ErrorMessage)
{
  // team damage MUST NOT be 0, otherwise NetDamage() and momentum transfer would be bypassed
  CRZCellCapture(WorldInfo.Game).FriendlyFireScale = 1;
  if (!SpawnProtection)
    CRZGame(WorldInfo.Game).SpawnProtectionTime = 0;
  super.InitMutator(Options, ErrorMessage);
}

simulated event Tick(float DeltaTime)
{
  local CRZPlayerController pc;
  local UTPawn pawn;
  local CRZWeap_Instagib gun;

  foreach WorldInfo.AllControllers(class'CRZPlayerController', pc)
  {
    pawn = UTPawn(pc.Pawn);
    if (pawn == None)
      continue;

    // modify knockback
    gun = CRZWeap_Instagib(pawn.Weapon);
    if (gun != None)
      gun.InstantHitMomentum[0] = HitMomentum;
  }
}


function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
  if (InstigatedBy != None && Injured.IsSameTeam(InstigatedBy.Pawn))
    Damage = TeamDamage;
  Super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);
}

defaultproperties
{
  GroupNames(0)="FRIENDLYFIRE"
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true 
}