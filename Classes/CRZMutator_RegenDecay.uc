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

  AddSlider(ConfigView, MutatorDataProvider, 0, 0.0, 10.0, 1.0, default.HealthRegenAmount, OnHealthRegenAmountChanged);
  AddSlider(ConfigView, MutatorDataProvider, 1, 0.0, 200.0, 5.0, default.HealthRegenLimit, OnHealthRegenLimitChanged);
  AddSlider(ConfigView, MutatorDataProvider, 2, 0.0, 10.0, 1.0, default.HealthDecayUpperAmount, OnHealthDecayUpperAmountChanged);
  AddSlider(ConfigView, MutatorDataProvider, 3, 0.0, 200.0, 5.0, default.HealthDecayUpperLimit, OnHealthDecayUpperLimitChanged);
  AddSlider(ConfigView, MutatorDataProvider, 4, 0.0, 10.0, 1.0, default.HealthDecayLowerAmount, OnHealthDecayLowerAmountChanged);
  AddSlider(ConfigView, MutatorDataProvider, 5, 0.0, 200.0, 5.0, default.HealthDecayLowerLimit, OnHealthDecayLowerLimitChanged);
  AddSlider(ConfigView, MutatorDataProvider, 6, 0.0, 10.0, 1.0, default.ArmorRegenAmount, OnArmorRegenAmountChanged);
  AddSlider(ConfigView, MutatorDataProvider, 7, 0.0, 200.0, 5.0, default.ArmorRegenLimit, OnArmorRegenLimitChanged);
  AddSlider(ConfigView, MutatorDataProvider, 8, 0.0, 10.0, 1.0, default.ArmorDecayAmount, OnArmorDecayAmountChanged);
  AddSlider(ConfigView, MutatorDataProvider, 9, 0.0, 200.0, 5.0, default.ArmorDecayLimit, OnArmorDecayLimitChanged);
}

private static function AddSlider(GFxCRZFrontEnd_ModularView ConfigView, CRZUIDataProvider_Mutator MutatorDataProvider, int index, float min, float max, float snap, float val, delegate<GFxClikWidget.EventListener> listener)
{
	local CRZSliderWidget Slider; 

	Slider = ConfigView.AddSlider( ConfigView.ListObject1, "CRZSlider", MutatorDataProvider.ListOptions[index].OptionLabel, MutatorDataProvider.ListOptions[index].OptionDesc);
  Slider.SetFloat("minimum", min);
	Slider.SetFloat("maximum", max);
	Slider.SetSnapInterval(snap);
	//Slider.SetString("smallSnap","1"); // smallSnap overwrites the SnapInterval above
  Slider.SetFloat("value", val);	
	Slider.AddEventListener('CLIK_change', listener);
}

function static OnHealthRegenAmountChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_RegenDecay', 'HealthRegenAmount'))
    return;
	default.HealthRegenAmount = ev.target.GetFloat("value");
	StaticSaveConfig();
}

function static OnHealthRegenLimitChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_RegenDecay', 'HealthRegenLimit'))
    return;
	default.HealthRegenLimit = ev.target.GetFloat("value");
	StaticSaveConfig();
}

function static OnHealthDecayUpperAmountChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_RegenDecay', 'HealthDecayUpperAmount'))
    return;
	default.HealthDecayUpperAmount = ev.target.GetFloat("value");
	StaticSaveConfig();
}

function static OnHealthDecayUpperLimitChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_RegenDecay', 'HealthDecayUpperLimit'))
    return;
	default.HealthDecayUpperLimit = ev.target.GetFloat("value");
	StaticSaveConfig();
}

function static OnHealthDecayLowerAmountChanged(GFxClikWidget.EventData ev)
{ 
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_RegenDecay', 'HealthDecayLowerAmount'))
    return;
	default.HealthDecayLowerAmount = ev.target.GetFloat("value");
	StaticSaveConfig();
}

function static OnHealthDecayLowerLimitChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_RegenDecay', 'HealthDecayLowerLimit'))
    return;
	default.HealthDecayLowerLimit = ev.target.GetFloat("value");
	StaticSaveConfig();
}

/******** Armor ************/

function static OnArmorRegenAmountChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_RegenDecay', 'ArmorRegenAmount'))
    return;
	default.ArmorRegenAmount = ev.target.GetFloat("value");
	StaticSaveConfig();
}

function static OnArmorRegenLimitChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_RegenDecay', 'ArmorRegenLimit'))
    return;
	default.ArmorRegenLimit = ev.target.GetFloat("value");
	StaticSaveConfig();
}

function static OnArmorDecayAmountChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_RegenDecay', 'ArmorDecayAmount'))
    return;
	default.ArmorDecayAmount = ev.target.GetFloat("value");
	StaticSaveConfig();
}

function static OnArmorDecayLimitChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_RegenDecay', 'ArmorDecayLimit'))
    return;
	default.ArmorDecayLimit = ev.target.GetFloat("value");
	StaticSaveConfig();
}
