// MutatH0r.CRZMutator_ComboGib
// ----------------
// Stingray only kills in combos with either prim+sec or sec+prim.
// Individual shots don't make damage, but bounce the victims around.
// Stingray plasma balls have some splash damage and allow plasma climbs.
// ----------------
// by PredatH0r
//================================================================
 
class CRZMutator_ComboGib extends CRZMutator_SuperStingray config (MutatH0r);

const BallDirectHitDamage = 17; // a random magic number

var config float VolunerabilityDuration;
var config int PlasmaArmor; // number of ball hits needed to get volunerable to the beam
var config bool TeamMateTag, TeamMateKill, TeamMateUntag;
var config float GravityZ;

var float ExtraUpSelf;
var float PlasmaKnockbackVert, BeamKnockbackVert;

var LinearColor VolunerabilityColorBeam;
var LinearColor VolunerabilityColorBall;
 
 
function InitMutator(string Options, out string ErrorMessage)
{
  local SuperStingrayConfig preset;

  Super.InitMutator(Options, ErrorMessage);

  if (GravityZ != 0)
    WorldInfo.WorldGravityZ = GravityZ;
  
  preset = new class'SuperStingrayConfig';
  preset.SetDefaults();
  preset.SwapButtons = false;
  preset.DamageRadius = 120;
  preset.DamagePlasma = BallDirectHitDamage;
  preset.KnockbackPlasma = 20000;
  preset.FireIntervalPlasma = 0.1667;
  preset.FireIntervalBeam = 0.5;
  preset.ShotCost[0] = 0;
  preset.ShotCost[1] = 0;
  super.ApplyPreset(preset);
}

simulated function PostBeginPlay()
{
  local UTGame Game;

  Super.PostBeginPlay();
 
  VolunerabilityColorBeam.A = 255.0;
  VolunerabilityColorBeam.R = 128.0;
  VolunerabilityColorBeam.G = 128.0;
 
  VolunerabilityColorBall.A = 255.0;
  VolunerabilityColorBall.G = 128.0;

  Game = UTGame(WorldInfo.Game);
  Game.DefaultInventory.Length = 1;
  Game.DefaultInventory[0] = class'H0Weap_ScionRifle';

  if (Role == ROLE_Authority)
  {
    SetTickGroup(ETickingGroup.TG_PreAsyncWork);
    Enable('Tick');
  }
}

function bool CheckReplacement(Actor Other)
{
  return !Other.IsA('PickupFactory') && !Other.IsA('UTDroppedPickup');
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
          victim.VestArmor = PlasmaArmor;
        }
      }
      else if (TeamMateTag || !Injured.IsSameTeam(InstigatedBy.Pawn))
      {
        if (victim.VestArmor > 0)
          victim.VestArmor = FMax(0, Victim.VestArmor - 1);
        if (victim.VestArmor == 0)
          victim.SetBodyMatColor(VolunerabilityColorBeam, VolunerabilityDuration);
      }
 
      knockbackVert = PlasmaKnockbackVert;
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
 

simulated function Tick(float DeltaTime)
{    
  local UTPawn P;     

  if (Role == ROLE_Authority)
  {
    foreach WorldInfo.AllPawns(class'UTPawn', P)
    {
      if (P.Physics == EPhysics.PHYS_Walking)
      {
        if (P.RemainingBodyMatDuration > 0)
          P.ClearBodyMatColor();
        P.VestArmor = PlasmaArmor;
      }
    }
  }
}
 

function Mutate(string value, PlayerController sender)
{
  if (instr(value, "cg ") < 0)
  {
    super.Mutate(value, sender);
    return;
  }
  
  value = mid(value, 3, len(value)-3);

  if (value == "info")
  {
    `log("Ball: bv=" $ PlasmaKnockbackVert $ ", ba=" $ PlasmaArmor);
    `log("Beam: rv=" $ BeamKnockbackVert);
    `log("Team: tt=" $ TeamMateTag $ ", tk=" $ TeamMateKill $ ", tu=" $ TeamMateUntag);
    `log("Self: up=" $ ExtraUpSelf);
    `log("Grav=" $ WorldInfo.WorldGravityZ);
    return;
  }

  if (!AllowMutate)
    return;

  if (Left(value, 3) == "bv ")
    PlasmaKnockbackVert = float(Mid(value, 3));
  else if (Left(value, 3) == "ba ")
    PlasmaArmor = float(Mid(value, 3));
  else if (Left(value, 3) == "rv ")
    BeamKnockbackVert = float(Mid(value, 3));
  else if (Left(value, 3) == "tt ")
    TeamMateTag = Mid(value, 3) != "0";
  else if (Left(value, 3) == "tk ")
    TeamMateKill = Mid(value, 3) != "0";
  else if (Left(value, 3) == "tu ")
    TeamMateUntag = Mid(value, 3) != "0";
  else if (Left(value, 3) == "up ")
    ExtraUpSelf = float(Mid(Value, 3));
  else if (Left(Value, 5) == "grav ")
    WorldInfo.WorldGravityZ = float(mid(Value, 5));
}
 
 
defaultproperties
{
  bConfigWidgets=false // suppress SuperStingray config controls
  bAllowDisableTick=false // prevent SuperStingray from disabling Tick

  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true

  PlasmaKnockbackVert=200
  BeamKnockbackVert=550
  ExtraUpSelf=50

//  GroupNames[0]="WEAPONMOD"
//  GroupNames[1]="WEAPONRESPAWN"
//  GroupNames[2]="STINGRAY"
}