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
  local CRZSliderWidget slider; 

  super.PopulateConfigView(ConfigView, MutatorDataProvider);
  
  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_InstaTeamBoost');

  slider = ConfigView.AddSlider(ConfigView.ListObject1, "CRZSlider", "Pull/Push force", "pull (-) or push (+) your team mates with a hit");
  slider.SetFloat("minimum", -350.0);
  slider.SetFloat("maximum", +350.0);
  slider.SetFloat("smallSnap", 10);
  slider.SetInt("value", int(default.HitMomentum / 1000));
  slider.AddEventListener('CLIK_change', OnKnockbackChanged);

  slider = ConfigView.AddSlider(ConfigView.ListObject1, "CRZSlider", "Team Damage", "Damage dealt when hitting your team mates");
  slider.SetFloat("minimum", 0.0);
  slider.SetFloat("maximum", 100.0);
  slider.SetFloat("smallSnap", 5);
  slider.SetInt("value", default.TeamDamage);
  slider.AddEventListener('CLIK_change', OnTeamDamageChanged);
}

function static OnKnockbackChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_InstaTeamBoost', 'HitMomentum'))
    return;
  default.HitMomentum = ev.target.GetFloat("value") * 1000;
  StaticSaveConfig();
}

function static OnTeamDamageChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_InstaTeamBoost', 'TeamDamage'))
    return;
  default.TeamDamage = ev.target.GetInt("value");
  StaticSaveConfig();
}

defaultproperties
{
  GroupNames(0)="FRIENDLYFIRE"
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true 
}