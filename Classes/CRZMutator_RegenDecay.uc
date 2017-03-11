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

var config int HealthMax;

var config int HealthRegenLimit;
var config int HealthRegenAmount;

var config int HealthDecayUpperLimit;
var config int HealthDecayUpperAmount;
var config int HealthDecayLowerLimit;
var config int HealthDecayLowerAmount;

// armor regen / decay

var config int ArmorMax;

var config int ArmorRegenLimit;
var config int ArmorRegenAmount;

var config int ArmorDecayUpperLimit;
var config int ArmorDecayUpperAmount;
var config int ArmorDecayLowerLimit;
var config int ArmorDecayLowerAmount;


function InitMutator(string Options, out string ErrorMessage)
{
	Super.InitMutator(Options, ErrorMessage);

	if (HealthMax != class'CRZPawn'.default.SuperHealthMax
	  || HealthDecayUpperAmount != HealthDecayLowerAmount || HealthDecayLowerAmount != class'CRZPawn'.default.HealthDecayAmount
	  || HealthDecayUpperLimit != HealthDecayLowerLimit || HealthDecayLowerLimit != class'CRZPawn'.default.HealthDecayLimit  
	  || ArmorDecayUpperAmount != ArmorDecayLowerAmount || ArmorDecayLowerAmount != class'CRZPawn'.default.ShieldDecayAmount
	  || ArmorDecayUpperLimit != ArmorDecayLowerLimit || ArmorDecayLowerLimit != class 'CRZPawn'.default.ShieldDecayLimit)
	{
    SetTickGroup(TG_PreAsyncWork);
    Enable('Tick');
	}

	if (HealthRegenAmount > 0 || ArmorRegenAmount > 0)
		SetTimer(TickInterval, true, 'Regen');
}

simulated function PostBeginPlay()
{
  local CRZArmorPickupFactory apf;

  super.PostBeginPlay();

  foreach WorldInfo.AllActors(class'CRZArmorPickupFactory', apf)
  {
    apf.MaxShieldAmount = ArmorMax;
  }	
}


simulated function Tick(float deltaTime)
{
	local CRZPawn P;

	foreach WorldInfo.AllPawns(class'CRZPawn', P)
	{
    P.SuperHealthMax = Max(HealthMax, 100);
   
		// health decay
		if (P.Health > HealthDecayUpperLimit && HealthDecayUpperAmount > 0)
		{
      P.HealthDecayAmount = HealthDecayUpperAmount;
      P.HealthDecayLimit = HealthDecayUpperLimit;
		}
		else
		{
      P.HealthDecayAmount = HealthDecayLowerAmount;
      P.HealthDecayLimit = HealthDecayLowerLimit;
      if (P.Health > HealthDecayLowerLimit) // start decay timer
        P.SetHealth(P.Health);
		}

		// armor decay
		if (P.VestArmor > ArmorDecayUpperLimit && ArmorDecayUpperAmount > 0)
		{
      P.ShieldDecayAmount = ArmorDecayUpperAmount;
      P.ShieldDecayLimit = ArmorDecayUpperLimit;
		}
		else
		{
      P.ShieldDecayAmount = ArmorDecayLowerAmount;
      P.ShieldDecayLimit = ArmorDecayLowerLimit;
      if (P.VestArmor > ArmorDecayLowerLimit) // start decay timer
        P.SetArmor(P.VestArmor);
		}
	}
}

function Regen()
{
	local CRZPawn P;
		
	foreach WorldInfo.AllPawns(class'CRZPawn', P)
	{
		// health regen
		if (HealthRegenAmount > 0 && P.Health < HealthRegenLimit)
			P.Health = Min(P.Health + HealthRegenAmount, HealthRegenLimit);
		
		// armor regen
		if (ArmorRegenAmount > 0 && P.VestArmor < ArmorRegenLimit)
			P.VestArmor = Min(P.VestArmor + ArmorRegenAmount, ArmorRegenLimit);	
	}
}


static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
	super.PopulateConfigView(ConfigView, MutatorDataProvider);

  ConfigView.SetMaskBounds(ConfigView.ListObject1, 400, 975, true);
  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_RegenDecay');
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Health Maximum", "Maximum health", 100.0, 200.0, 5.0, default.HealthMax, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "H. Decay Limit #1", "Health above this value will be reduced by Rate #1", 0.0, 200.0, 5.0, default.HealthDecayUpperLimit, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "H. Decay Rate #1", "Health lost per second when above limit #1", 0.0, 25.0, 1.0, default.HealthDecayUpperAmount, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "H. Decay Limit #2", "Health above this value will be reduced by Rate #2", 0.0, 200.0, 5.0, default.HealthDecayLowerLimit, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "H. Decay Rate #2", "Health lost per second when above limit #2", 0.0, 25.0, 1.0, default.HealthDecayLowerAmount, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "H. Regen Limit", "Maximum health from auto regeneration", 0.0, 200.0, 5.0, default.HealthRegenLimit, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "H. Regen Rate", "Health received per second from auto regeneration", 0.0, 25.0, 1.0, default.HealthRegenAmount, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Armor Maximum", "Maximum armor", 0.0, 200.0, 5.0, default.ArmorMax, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "A. Decay Limit #1", "Armor above this value will be reduced by Rate #1", 0.0, 200.0, 5.0, default.ArmorDecayUpperLimit, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "A. Decay Rate #1", "Armor lost per second when above Limit #1", 0.0, 25.0, 1.0, default.ArmorDecayUpperAmount, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "A. Decay Limit #2", "Armor above this value will be reduced by Rate #1", 0.0, 200.0, 5.0, default.ArmorDecayLowerLimit, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "A. Decay Rate #2", "Armor lost per second when above Limit #1", 0.0, 25.0, 1.0, default.ArmorDecayLowerAmount, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "A. Regen Limit", "Maximum armor from auto regeneration", 0.0, 200.0, 5.0, default.ArmorRegenLimit, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "A. Regen Rate", "Armor received per second from auto regeneration", 0.0, 25.0, 1.0, default.ArmorRegenAmount, OnSliderChanged);
}

function static OnSliderChanged(string label, float value, GFxClikWidget.EventData ev)
{
  switch(label)
  {
    case "Health Maximum": default.HealthMax = value; break;
    case "H. Regen Rate": default.HealthRegenAmount = value; break;
    case "H. Regen Limit": default.HealthRegenLimit = value; break;
    case "H. Decay Rate #1": default.HealthDecayUpperAmount = value; break;
    case "H. Decay Limit #1": default.HealthDecayUpperLimit = value; break;
    case "H. Decay Rate #2": default.HealthDecayLowerAmount = value; break;
    case "H. Decay Limit #2": default.HealthDecayLowerLimit = value; break;
    case "Armor Maximum": default.ArmorMax = value; break;
    case "A. Regen Rate": default.ArmorRegenAmount = value; break;
    case "A. Regen Limit": default.ArmorRegenLimit = value; break;
    case "A. Decay Rate #1": default.ArmorDecayUpperAmount = value; break;
    case "A. Decay Limit #1": default.ArmorDecayUpperLimit = value; break;
    case "A. Decay Rate #2": default.ArmorDecayLowerAmount = value; break;
    case "A. Decay Limit #2": default.ArmorDecayLowerLimit = value; break;
  }
	StaticSaveConfig();
}

