// CRZMutator_InstaTeamBoost
// ----------------
// adds knockback to the instagib weapon and disables spawn protection
//================================================================

class CRZMutator_InstaTeamBoost extends CRZMutator config (MutatH0r);

var config bool SpawnProtection;
var config int TeamDamage; // defaults to 0
var config float HitMomentum; // defaults to 200000

function bool MutatorIsAllowed()
{
  return CRZTeamGame(WorldInfo.Game) != None && Super.MutatorIsAllowed();
}

function InitMutator(string Options, out string ErrorMessage)
{
  // team damage MUST NOT be 0, otherwise NetDamage() and momentum transfer would be bypassed
  CRZTeamGame(WorldInfo.Game).FriendlyFireScale = 1;
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


static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
  super.PopulateConfigView(ConfigView, MutatorDataProvider);
  
  ConfigView.SetMaskBounds(ConfigView.ListObject1, 400, 975, true);
  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_InstaTeamBoost');
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Pull/Push force", "pull (-) or push (+) your team mates with a hit", -350, 350, 10, int (default.HitMomentum/1000), OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Team Damage", "Damage dealt when hitting your team mates", 0, 100, 5, default.TeamDamage, OnSliderChanged);
}

function static OnSliderChanged(string label, float value, GFxClikWidget.EventData ev)
{
  switch(label)
  {
    case "Pull/Push force": default.HitMomentum = value * 1000; break;
    case "Team Damage": default.TeamDamage = value; break;
  }
  StaticSaveConfig();
}

defaultproperties
{
//  GroupNames(0)="FRIENDLYFIRE"
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true 
}