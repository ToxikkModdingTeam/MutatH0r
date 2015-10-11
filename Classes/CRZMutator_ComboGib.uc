// MutatH0r.CRZMutator_ComboGib
// ----------------
// Stingray only kills in combos with either prim+sec or sec+prim
// Individual shots don't make damage, but bounce the victims around
// ----------------
// by PredatH0r
//================================================================
 
class CRZMutator_ComboGib extends UTMutator config (MutatH0r);
 
const BallDirectHitDamage = 10;

var config float VolunerabilityDuration;
var config int BallArmor; // number of ball hits needed to get volunerable to the beam
var config float BallKnockbackHoriz, BallKnockbackVert, BallSweetSpotDistance, BallSweetSpotSpread, BallFireRate;
var config float BeamKnockbackHoriz, BeamKnockbackVert, BeamSweetSpotDistance, BeamSweetSpotSpread, BeamFireRate;
var config bool TeamMateTag, TeamMateKill, TeamMateUntag;
var config float GravityZ;
var float _BallFireRate, _BeamFireRate;

var LinearColor VolunerabilityColorBeam;
var LinearColor VolunerabilityColorBall;
 
replication
{
  if ( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
    _BallFireRate, _BeamFireRate;
}
 
function InitMutator(string Options, out string ErrorMessage)
{
  Super.InitMutator(Options, ErrorMessage);
  _BallFireRate = BallFireRate;
  _BeamFireRate = BeamFireRate;
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
  local vector v,n,sweetSpot;
  local float d;
  local float knockbackHoriz,knockbackVert,sweetDistance,sweetSpread;
 
  Super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);
 
  if (instr(string(DamageType), "CRZDmgType_Scion") < 0)
    return;
  
  victim = UTPawn(Injured);
  if (victim == none || InstigatedBy == none || InstigatedBy.Pawn == none)
    return;
 
  v = Injured.Location - InstigatedBy.Pawn.Location;
 
  if (string(DamageType) == "CRZDmgType_Scion_Plasma")
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
 
    knockbackHoriz = BallKnockbackHoriz;
    knockbackVert = BallKnockbackVert;
    sweetDistance = BallSweetSpotDistance;
    sweetSpread = BallSweetSpotSpread; 
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

    knockbackHoriz = BeamKnockbackHoriz;
    knockbackVert = BeamKnockbackVert;
    sweetDistance = BeamSweetSpotDistance;
    sweetSpread = BeamSweetSpotSpread;
  }
 
  if (sweetSpread != 0)
  {
    n.X = (frand() - 0.5) * sweetSpread;
    n.Y = (frand() - 0.5) * sweetSpread;
    n.Z = (frand() - 0.5) * sweetSpread;
  }
  sweetSpot = InstigatedBy.Pawn.Location + Normal(v) * sweetDistance + n;
 
  n = sweetSpot - Injured.Location;
  n.Z = 0;
  d = VSize(n);
  if (d > knockbackHoriz)
    n = Normal(n) * knockbackHoriz;
    
  Momentum.X = n.X;
  Momentum.Y = n.Y;
  Momentum.Z = knockbackVert;
 
  Momentum -= victim.Velocity/2;
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
      proj.DamageRadius = 80;
      proj.MomentumTransfer = 0;
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
    W.FireInterval[0] = _BallFireRate;
    W.FireInterval[1] = _BeamFireRate;
  }               
}
 

function Mutate(string value, PlayerController sender)
{
  if (value == "i")
  {
    `log("Ball: h=" $ BallKnockbackHoriz $ ", v=" $ BallKnockbackVert $ ", d=" $ BallSweetSpotDistance $ ", s=" $ BallSweetSpotSpread $ ", r=" $ _BallFireRate $ ", a=" $ BallArmor);
    `log("Beam: h=" $ BeamKnockbackHoriz $ ", v=" $ BeamKnockbackVert $ ", d=" $ BeamSweetSpotDistance $ ", s=" $ BeamSweetSpotSpread $ ", r=" $ _BeamFireRate);
    `log("Team: t=" $ TeamMateTag $ ", k=" $ TeamMateKill $ ", u=" $ TeamMateUntag);
    `log("Grav=" $ WorldInfo.WorldGravityZ);
  }
  else if (Left(value, 3) == "bh ")
    BallKnockbackHoriz = float(Mid(value, 3));
  else if (Left(value, 3) == "bv ")
    BallKnockbackVert = float(Mid(value, 3));
  else if (Left(value, 3) == "bd ")
    BallSweetSpotDistance = float(Mid(value, 3));
  else if (Left(value, 3) == "bs ")
    BallSweetSpotSpread = float(Mid(value, 3));
  else if (Left(value, 3) == "br ")
    _BallFireRate = float(Mid(value, 3));
  else if (Left(value, 3) == "ba ")
    BallArmor = float(Mid(value, 3));
  else if (Left(value, 3) == "rh ")
    BeamKnockbackHoriz = float(Mid(value, 3));
  else if (Left(value, 3) == "rv ")
    BeamKnockbackVert = float(Mid(value, 3));
  else if (Left(value, 3) == "rd ")
    BeamSweetSpotDistance = float(Mid(value, 3));
  else if (Left(value, 3) == "rs ")
    BeamSweetSpotSpread = float(Mid(value, 3));
  else if (Left(value, 3) == "rr ")
    _BeamFireRate = float(Mid(value, 3));
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
}