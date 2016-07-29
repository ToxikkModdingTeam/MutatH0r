// MutatH0r.CRZMutator_InstaBounce
// ----------------
// Stingray Plasma bounces with no damage, Beam is insta-kill
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_InstaBounce extends CRZMutator_SuperStingray config(MutatH0r);

var config float KnockbackBall;
var config float SplashRadius;
var config float FireInterval;


function InitMutator(string options, out string error)
{
  local SuperStingrayConfig preset;

  super.InitMutator(options, error);

  if (KnockbackBall == 0)
    KnockbackBall = 50;
  if (SplashRadius == 0)
    SplashRadius = 150;
  if (FireInterval == 0)
    FireInterval = 50;

  preset = new class'SuperStingrayConfig';
  preset.SetDefaults();
  preset.SwapButtons = true;
  preset.KnockbackPlasma = KnockbackBall * 1000;
  preset.DamageRadius = SplashRadius;
  preset.FireIntervalPlasma = FireInterval / 100;
  preset.DamagePlasma = 0.1;
  preset.DamageBeam = 1000;
  preset.ShotCost[0] = 0;
  preset.ShotCost[1] = 0;
  super.ApplyPreset(preset);
}

simulated function PostBeginPlay()
{
  local UTGame Game;

  Super.PostBeginPlay();

  Game = UTGame(WorldInfo.Game);
  Game.DefaultInventory.Length = 1;
  Game.DefaultInventory[0] = class'H0Weap_ScionRifle';
}

function bool CheckReplacement(Actor Other)
{
  return !Other.IsA('PickupFactory') && !Other.IsA('UTDroppedPickup');
}

static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
  super.PopulateConfigView(ConfigView, MutatorDataProvider);

  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_InstaBounce');

  class'MutConfigHelper'.static.AddSlider(ConfigView, "Knockback", "Force of the splash blast [85]", 0, 100, 1, default.KnockbackBall, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Splash Radius", "Radius of the splash blast [150]", 0, 300, 5, default.SplashRadius, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Ball Fire Rate", "Time between firing two balls [500 millisec]", 100, 2000, 10, default.FireInterval * 10, OnSliderChanged);
}

function static OnSliderChanged(string label, float value, GFxClikWidget.EventData ev)
{
  if (label == "Knockback") default.KnockbackBall = value;
  else if (label == "Splash Radius") default.SplashRadius = value;
  else if (label == "Ball Fire Rate") default.FireInterval = value / 10;
  StaticSaveConfig();
}

defaultproperties
{
  bConfigWidgets=false // prevent SuperStingray from adding its widgets to the config screen
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true
  GroupNames[0]="WEAPONMOD"
  GroupNames[1]="WEAPONRESPAWN"
  GroupNames[2]="STINGRAY"
}