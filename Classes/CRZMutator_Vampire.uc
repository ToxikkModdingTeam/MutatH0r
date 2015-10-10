// MutatH0r.CRZMutator_Vampire
// ----------------
// When a pawn takes damage, give part of the health lost to the dealing pawn
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_Vampire extends UTMutator config (MutatH0r);

var config float DamageHealingFactor;

function InitMutator(string Options, out string ErrorMessage)
{
	Super.InitMutator(Options, ErrorMessage);
	DamageHealingFactor = FClamp(DamageHealingFactor, 0, 2);
}

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
	local UTPawn Attacker;

	Super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

	Attacker = UTPawn(InstigatedBy.Pawn);
	if (Attacker != None && Attacker.Health < Attacker.SuperHealthMax)
	{
		Attacker.Health = Min(Attacker.Health + Min(Injured.Health, int(DamageHealingFactor * Damage)), Attacker.SuperHealthMax);
	}
}
