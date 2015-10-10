// MutatH0r.CRZMutator_RegenDecay
// ----------------
// ...
// ----------------
// by PredatH0r, based on work by Chatouille
//================================================================
class CRZMutator_RegenDecay extends UTMutator Config(MutatH0r);

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
