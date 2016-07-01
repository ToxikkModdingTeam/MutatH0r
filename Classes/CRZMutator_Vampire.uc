// MutatH0r.CRZMutator_Vampire
// ----------------
// When a pawn takes damage, give part of the health lost to the dealing pawn
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_Vampire extends CRZMutator config (MutatH0r);

var config float DamageHealingFactor;

function InitMutator(string Options, out string ErrorMessage)
{
	Super.InitMutator(Options, ErrorMessage);
	DamageHealingFactor = FClamp(DamageHealingFactor, 0, 1);
}

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
	local UTPawn Attacker;

	Super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

	Attacker = InstigatedBy == None ? None : UTPawn(InstigatedBy.Pawn);
	if (Attacker != None && Attacker.Health < Attacker.SuperHealthMax)
		Attacker.Health = Min(Attacker.Health + Min(Injured.Health, int(DamageHealingFactor * Damage)), Attacker.SuperHealthMax);
}

static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
	local CRZSliderWidget Slider; 

	super.PopulateConfigView(ConfigView, MutatorDataProvider);

  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_Vampire');

	
	Slider = ConfigView.AddSlider( ConfigView.ListObject1, "CRZSlider", MutatorDataProvider.ListOptions[0].OptionLabel, MutatorDataProvider.ListOptions[0].OptionDesc);
	
  Slider.SetFloat("minimum", 0);
	Slider.SetFloat("maximum", 100);
	Slider.SetSnapInterval(5);
	Slider.SetString("smallSnap","1");
  Slider.SetFloat("value", default.DamageHealingFactor * 100);
	
	Slider.AddEventListener('CLIK_change', OnHealthGainChanged);
}

function static OnHealthGainChanged(GFxClikWidget.EventData ev)
{
  local float value;

  value = ev.target.GetFloat("value");

  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_Vampire'))
    return;

	default.DamageHealingFactor = value / 100.0;
	StaticSaveConfig();
}