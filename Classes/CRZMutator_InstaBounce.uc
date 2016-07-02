// MutatH0r.CRZMutator_InstaBounce
// ----------------
// Stingray Plasma bounces with no damage, Beam is insta-kill
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_InstaBounce extends CRZMutator config (MutatH0r);

const StingrayClassPath = "Cruzade.CRZWeap_ScionRifle";

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
	Game.DefaultInventory[0] = class<Weapon>(DynamicLoadObject(StingrayClassPath, class'Class'));
}

function bool CheckReplacement(Actor Other)
{
	return !Other.IsA('PickupFactory');
}

simulated function Tick(float DeltaTime)
{
  local Projectile proj;
  local UTWeapon w;
  local Actor a;
  local string className;
  local int count;

  foreach WorldInfo.DynamicActors(class'Actor', a)
  {
    ++count;
    className = string(a.Class);
    if (instr(className, "CRZProj_Scion") == 0) // handle blue and red projectile
    {
      proj = Projectile(a);
      if (proj.Damage != 0.01)
      {
        proj.Damage = 0.01;  // damage 0 would cause the explosion/knockback code to be skipped, so we use 0.01 here
        proj.DamageRadius = SplashRadius;
        proj.MomentumTransfer = KnockbackBall * 1000;
      }
    }
    else if (className == "CRZWeap_ScionRifle")
    {
      w = UTWeapon(a);
      w.ShotCost[0] = 0;
      w.ShotCost[1] = 0;
      w.FireInterval[0] = FireInterval/100.0;
      w.InstantHitDamage[1] = 1000;
    }
  }
}

static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
	super.PopulateConfigView(ConfigView, MutatorDataProvider);

  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_InstaBounce');

	AddSlider(ConfigView, MutatorDataProvider, 0, 0, 100, 1, default.KnockbackBall, OnKnockbackChanged);
	AddSlider(ConfigView, MutatorDataProvider, 1, 0, 300, 5, default.SplashRadius, OnSplashRadiusChanged);
	AddSlider(ConfigView, MutatorDataProvider, 2, 25, 200, 1, default.FireInterval, OnFireIntervalChanged);
}

private static function AddSlider(GFxCRZFrontEnd_ModularView ConfigView, CRZUIDataProvider_Mutator MutatorDataProvider, int index, float min, float max, float snap, float val, delegate<GFxClikWidget.EventListener> listener)
{
	local CRZSliderWidget Slider; 

	Slider = ConfigView.AddSlider( ConfigView.ListObject1, "CRZSlider", MutatorDataProvider.ListOptions[index].OptionLabel, MutatorDataProvider.ListOptions[index].OptionDesc);
  Slider.SetFloat("minimum", min);
	Slider.SetFloat("maximum", max);
	Slider.SetSnapInterval(snap);
  Slider.SetFloat("value", val);	
	Slider.AddEventListener('CLIK_change', listener);
}

function static OnKnockbackChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_InstaBounce', 'Knockback'))
    return;

	default.KnockbackBall = ev.target.GetFloat("value");
	StaticSaveConfig();
}

function static OnSplashRadiusChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_InstaBounce', 'SplashRadius'))
    return;

	default.SplashRadius = ev.target.GetFloat("value");
	StaticSaveConfig();
}

function static OnFireIntervalChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_InstaBounce', 'FireInterval'))
    return;

	default.FireInterval = ev.target.GetFloat("value");
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