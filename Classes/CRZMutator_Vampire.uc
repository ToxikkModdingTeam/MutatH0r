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
  super.PopulateConfigView(ConfigView, MutatorDataProvider);

  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_Vampire');	
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Health Gain", "Amount of health you get for the damage you deal [75%]", 0, 100, 5, default.DamageHealingFactor * 100, OnSliderChanged);
}

function static OnSliderChanged(string label, float value, GFxClikWidget.EventData ev)
{
  default.DamageHealingFactor = value / 100.0;
  StaticSaveConfig();
}