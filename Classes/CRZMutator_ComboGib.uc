// MutatH0r.CRZMutator_ComboGib
// ----------------
// Stingray only kills in combos with either prim+sec or sec+prim.
// Individual shots don't make damage, but bounce the victims around.
// Stingray plasma balls have some splash damage and allow plasma climbs.
// ----------------
// by PredatH0r
//================================================================
 
class CRZMutator_ComboGib extends UTMutator config (MutatH0r);
 
const BallDirectHitDamage = 17;

var config float VolunerabilityDuration;
var config int BallArmor; // number of ball hits needed to get volunerable to the beam
var config bool TeamMateTag, TeamMateKill, TeamMateUntag;
var config float GravityZ;

var float BallFireRate, BeamFireRate, ExtraUpSelf;
var float BallKnockbackVert, BeamKnockbackVert;

var LinearColor VolunerabilityColorBeam;
var LinearColor VolunerabilityColorBall;
 
replication
{
  if ( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
    BallFireRate, BeamFireRate;
}
 
function InitMutator(string Options, out string ErrorMessage)
{
  Super.InitMutator(Options, ErrorMessage);
  if (GravityZ != 0)
	  WorldInfo.WorldGravityZ = GravityZ;
}
 
simulated function PostBeginPlay()
{
  Super.PostBeginPlay();
 
  VolunerabilityColorBeam.A = 255.0;
  VolunerabilityColorBeam.R = 128.0;
  VolunerabilityColorBeam.G = 128.0;
 
  VolunerabilityColorBall.A = 255.0;
  VolunerabilityColorBall.G = 128.0;
 
  SetTickGroup(ETickingGroup.TG_PreAsyncWork);
  Enable('Tick');
}
 
function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
  local UTPawn victim;
  local float knockbackVert;
  local bool isSelfDamage;
 
  Super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);
 
  if (instr(string(DamageType), "CRZDmgType_Scion") < 0)
    return;
  
  victim = UTPawn(Injured);
  if (victim == none || InstigatedBy == none || InstigatedBy.Pawn == none)
    return;

  isSelfDamage = Injured == InstigatedBy.Pawn;
 
  if (string(DamageType) == "CRZDmgType_Scion_Plasma")
  {
    if (isSelfDamage)
      Damage = 0;
    else
    {
      Damage = (Damage >= BallDirectHitDamage && victim.RemainingBodyMatDuration >= 0 && victim.BodyMatColor == VolunerabilityColorBall) ? 1000.0 : 0.0;
      if (Damage == 1000.0)
      {
        if (TeamMateKill || !Injured.IsSameTeam(InstigatedBy.Pawn))
          return;
        if (TeamMateUntag)
        {
          Damage = 0;
          victim.ClearBodyMatColor();
          victim.VestArmor = BallArmor;
        }
      }
      else if (TeamMateTag || !Injured.IsSameTeam(InstigatedBy.Pawn))
      {
        if (victim.VestArmor > 0)
          victim.VestArmor = FMax(0, Victim.VestArmor - 1);
        if (victim.VestArmor == 0)
          victim.SetBodyMatColor(VolunerabilityColorBeam, VolunerabilityDuration);
      }
 
      knockbackVert = BallKnockbackVert;
    }
  }
  else
  {
    Damage = (victim.RemainingBodyMatDuration >= 0 && victim.BodyMatColor == VolunerabilityColorBeam) ? 1000.0 : 0.0;
    if (Damage == 1000.0)
    {
      if (TeamMateKill || !Injured.IsSameTeam(InstigatedBy.Pawn))
        return;
      if (TeamMateUntag)
      {
        Damage = 0;
        victim.ClearBodyMatColor();
      }
    }
    else if (TeamMateTag || !Injured.IsSameTeam(InstigatedBy.Pawn))
      victim.SetBodyMatColor(VolunerabilityColorBall, VolunerabilityDuration);

    knockbackVert = BeamKnockbackVert;
  }
 
  Momentum.Z += isSelfDamage ? ExtraUpSelf : knockbackVert;
  if (Damage == 0)
    Damage = 0.1; // otherwise there would be no knockback
}
 

simulated event Tick(float DeltaTime)
{    
  local UTPawn P;
  local PlayerController PC;
  local Projectile proj;
     
  foreach WorldInfo.LocalPlayerControllers(class'PlayerController', PC)
    ReloadStingray(PC.Pawn);
 
  foreach WorldInfo.DynamicActors(class'Projectile', proj)
  {
    if (string(proj.Class) == "CRZProj_ScionRifle" && proj.Damage != BallDirectHitDamage)
    {
      proj.Damage = BallDirectHitDamage;
      proj.DamageRadius = 120;
      proj.MomentumTransfer = 20000;
    }
  }

  if (Role == ROLE_Authority)
  {
    foreach WorldInfo.AllPawns(class'UTPawn', P)
    {
      ReloadStingray(P);
      if (P.Physics == EPhysics.PHYS_Walking)
      {
        if (P.RemainingBodyMatDuration > 0)
          P.ClearBodyMatColor();
        P.VestArmor = BallArmor;
      }
    }
  }
}
 
simulated function ReloadStingray(Pawn P)
{
  local UTWeapon W;
 
  if (P == None)
    return;
  W = UTWeapon(P.Weapon);
  if (W != none && instr(string(W.Class), "ScionRifle") >= 0)
  {
    W.ShotCost[0] = 0;
    W.ShotCost[1] = 0;
    W.FireInterval[0] = BallFireRate;
    W.FireInterval[1] = BeamFireRate;
  }               
}
 

function Mutate(string value, PlayerController sender)
{
  if (value == "i")
  {
    `log("Ball: v=" $ BallKnockbackVert $ ", r=" $ BallFireRate $", a=" $ BallArmor);
    `log("Beam: v=" $ BeamKnockbackVert $ ", r=" $ BeamFireRate);
    `log("Team: t=" $ TeamMateTag $ ", k=" $ TeamMateKill $ ", u=" $ TeamMateUntag);
    `log("Grav=" $ WorldInfo.WorldGravityZ);
  }
  else if (Left(value, 3) == "bv ")
    BallKnockbackVert = float(Mid(value, 3));
  else if (Left(value, 3) == "ba ")
    BallArmor = float(Mid(value, 3));
  else if (Left(value, 3) == "rv ")
    BeamKnockbackVert = float(Mid(value, 3));
  else if (Left(value, 3) == "tt ")
    TeamMateTag = Mid(value, 3) != "0";
  else if (Left(value, 3) == "tk ")
    TeamMateKill = Mid(value, 3) != "0";
  else if (Left(value, 3) == "tu ")
    TeamMateUntag = Mid(value, 3) != "0";
  else if (Left(Value, 5) == "grav ")
    WorldInfo.WorldGravityZ = float(mid(Value, 5));
  else
    Super.Mutate(value, sender);
}
 
 
defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true

  BallFireRate=0.1667
  BallKnockbackVert=200
  BeamFireRate=0.5
  BeamKnockbackVert=550
  ExtraUpSelf=50
}