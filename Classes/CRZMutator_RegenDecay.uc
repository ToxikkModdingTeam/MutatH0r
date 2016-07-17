// MutatH0r.CRZMutator_RegenDecay
// ----------------
// ...
// ----------------
// by PredatH0r, based on work by Chatouille
//================================================================
class CRZMutator_RegenDecay extends CRZMutator Config(MutatH0r);

/** Update rate (interval between two ticks) */
var config float TickInterval;

// health regen/decay

/** if a Pawn's health is below this limit, it will be increased by HealthRegenAmount */
var config int HealthRegenLimit;

/** Amount of health received per tick, when health is below HealthRegenLimit */
var config int HealthRegenAmount;

/** if a Pawn's health is above this limit, it will be reduced by HealthDecayUpperAmount */
var config int HealthDecayUpperLimit;

/** Amount of health lost per tick, when health is above HealthDecayUpperLimit */
var config int HealthDecayUpperAmount;

/** if a Pawn's health is above this limit, it will be reduced by HealthDecayLowerAmount */
var config int HealthDecayLowerLimit;

/** Amount of health lost per tick, when health is above HealthDecayLowerLimit */
var config int HealthDecayLowerAmount;

// armor regen / decay

/** if a Pawn's armor is below this limit, it will be increased by ArmorRegenAmount */
var config int ArmorRegenLimit;

/** Amount of Armor received per tick */
var config int ArmorRegenAmount;

/** if a Pawn's armor is above this limit, it will be reduced by ArmorDecayLowerAmount */
var config int ArmorDecayLimit;

/** Amount of Armor lost per tick */
var config int ArmorDecayAmount;


function InitMutator(string Options, out string ErrorMessage)
{
	Super.InitMutator(Options, ErrorMessage);

	if (HealthRegenAmount > 0 || HealthDecayLowerAmount > 0 || HealthDecayUpperAmount > 0 || ArmorRegenAmount > 0 || ArmorDecayAmount > 0)
		SetTimer(TickInterval, true);
}

function Timer()
{
	local UTPawn P;
		
	foreach WorldInfo.AllPawns(class'UTPawn', P)
	{
		// health regen
		if (HealthRegenAmount > 0 && P.Health < HealthRegenLimit)
			P.Health = Min(P.Health + HealthRegenAmount, HealthRegenLimit);
		
		// health decay
		if (HealthDecayUpperAmount > 0 && P.Health > HealthDecayUpperLimit)
			P.Health = Max(P.Health - HealthDecayUpperAmount, HealthDecayUpperLimit - HealthDecayLowerAmount);
		else if (HealthDecayLowerAmount > 0 && P.Health > HealthDecayLowerLimit)
			P.Health = Max(P.Health - HealthDecayLowerAmount, HealthDecayLowerLimit);
		if (P.Health <= 0)
			P.Died(None, class'DmgType_Crushed', vect(0,0,0));

		// armor regen
		if (ArmorRegenAmount > 0 && P.VestArmor < ArmorRegenLimit)
			P.VestArmor = Min(P.VestArmor + ArmorRegenAmount, ArmorRegenLimit);
		
		// armor decay
		if (ArmorDecayAmount > 0 && P.VestArmor > ArmorDecayLimit)
			P.VestArmor = Max(P.VestArmor - ArmorDecayAmount, ArmorDecayLimit);
	}
}


static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
	super.PopulateConfigView(ConfigView, MutatorDataProvider);

  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_RegenDecay');

  class'MutConfigHelper'.static.AddSlider(ConfigView, "H. Regen Rate", "Health received per second from auto regeneration", 0.0, 10.0, 1.0, default.HealthRegenAmount, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "H. Regen Limit", "Maximum health from auto regeneration", 0.0, 200.0, 5.0, default.HealthRegenLimit, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "H. Decay Rate #1", "Health lost per second when above limit #1", 0.0, 10.0, 1.0, default.HealthDecayUpperAmount, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "H. Decay Limit #1", "Health above this value will be reduced by Rate #1", 0.0, 200.0, 5.0, default.HealthDecayUpperLimit, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "H. Decay Rate #2", "Health lost per second when above limit #2", 0.0, 10.0, 1.0, default.HealthDecayLowerAmount, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "H. Decay Limit #2", "Health above this value will be reduced by Rate #2", 0.0, 200.0, 5.0, default.HealthDecayLowerLimit, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "A. Regen Rate", "Armor received per second from auto regeneration", 0.0, 10.0, 1.0, default.ArmorRegenAmount, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "A. Regen Limit", "Maximum armor from auto regeneration", 0.0, 200.0, 5.0, default.ArmorRegenLimit, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "A. Decay Rate", "Armor lost per second when above Limit", 0.0, 10.0, 1.0, default.ArmorDecayAmount, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "A. Decay Limit", "Armor above this value will be reduced at the given Rate", 0.0, 200.0, 5.0, default.ArmorDecayLimit, OnSliderChanged);
}

function static OnSliderChanged(string label, float value, GFxClikWidget.EventData ev)
{
  switch(label)
  {
    case "H. Regen Rate": default.HealthRegenAmount = value; break;
    case "H. Regen Limit": default.HealthRegenLimit = value; break;
    case "H. Decay Rate #1": default.HealthDecayUpperAmount = value; break;
    case "H. Decay Limit #1": default.HealthDecayUpperLimit = value; break;
    case "H. Decay Rate #2": default.HealthDecayLowerAmount = value; break;
    case "H. Decay Limit #2": default.HealthDecayLowerLimit = value; break;
    case "A. Regen Rate": default.ArmorRegenAmount = value; break;
    case "A. Regen Limit": default.ArmorRegenLimit = value; break;
    case "A. Decay Rate": default.ArmorDecayAmount = value; break;
    case "A. Decay Limit": default.ArmorDecayLimit = value; break;
  }
	StaticSaveConfig();
}

