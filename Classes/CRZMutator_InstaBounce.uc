// MutatH0r.CRZMutator_InstaBounce
// ----------------
// Stingray Plasma bounces with no damage, Beam is insta-kill
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_InstaBounce extends CRZMutator config (MutatH0r);

var config float KnockbackBall;
var config float SplashRadius;
var config float FireInterval;

simulated event PreBeginPlay()
{
  super.PreBeginPlay();
  SetTickGroup(ETickingGroup.TG_PreAsyncWork);
  Enable('Tick');

  KnockbackBall = FClamp(KnockBackBall, 0, 100);
  SplashRadius = FClamp(SplashRadius, 0, 300);
  FireInterval = FClamp(FireInterval, 25, 200);
}

function PostBeginPlay()
{
  local UTGame Game;

  Super.PostBeginPlay();

  Game = UTGame(WorldInfo.Game);
  Game.DefaultInventory.Length = 1;
  Game.DefaultInventory[0] = class'CRZWeap_ScionRifle';
}

function bool CheckReplacement(Actor Other)
{
  return !Other.IsA('PickupFactory');
}

simulated function Tick(float DeltaTime)
{
  local CRZWeap_ScionRifle w;
  local CRZProj_ScionRifle proj;

  foreach WorldInfo.DynamicActors(class'CRZWeap_ScionRifle', w)
  {
    w.ShotCost[0] = 0;
    w.ShotCost[1] = 0;
    w.FireInterval[0] = FireInterval/100.0;
    w.InstantHitDamage[1] = 1000;
  }

  foreach WorldInfo.DynamicActors(class'CRZProj_ScionRifle', proj)
  {
    if (proj.Damage != 0.01)
    {
      proj.Damage = 0.01;  // damage 0 would cause the explosion/knockback code to be skipped, so we use 0.01 here
      proj.DamageRadius = SplashRadius;
      proj.MomentumTransfer = KnockbackBall * 1000;
    }
  }
}

static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
  super.PopulateConfigView(ConfigView, MutatorDataProvider);

  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_InstaBounce');

  class'MutConfigHelper'.static.AddSlider(ConfigView, "Knockback", "Force of the splash blast [85]", 0, 100, 1, default.KnockbackBall, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Splash Radius", "Radius of the splash blast [150]", 0, 300, 5, default.SplashRadius, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Ball Fire Rate", "Time between firing two balls [500 millisec]", 250, 2000, 10, default.FireInterval * 10, OnSliderChanged);
}

function static OnSliderChanged(string label, float value, GFxClikWidget.EventData ev)
{
  switch(label)
  {
    case "Knockback": default.KnockbackBall = value; break;
    case "Splash Radius": default.SplashRadius = value; break;
    case "Ball Fire Rate": default.FireInterval = value / 10; break;
  }
  StaticSaveConfig();
}

defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true
  GroupNames[0]="WEAPONMOD"
  GroupNames[1]="WEAPONRESPAWN"
  GroupNames[2]="STINGRAY"
}