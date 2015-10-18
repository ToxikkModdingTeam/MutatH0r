// MutatH0r.CRZMutator_Roq3t
// ----------------
// Modify rocket damage (direct, splash, self), knockback (horiz, vert) and fire rate
// by PredatH0r
//================================================================

class CRZMutator_Roq3t extends UTMutator config (MutatH0r);

var config float KnockbackFactorHoriz, KnockbackFactorVert, MinKnockbackVert, MaxKnockbackVert, FireInterval, DamageFactorDirect, DamageFactorSplash;
var config float DamageFactorSelf;

replication
{
	if ( bNetInitial || bNetDirty )
		FireInterval, DamageFactorSplash;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	SetTickGroup(ETickingGroup.TG_PreAsyncWork);
	Enable('Tick');
}

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
	Super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

	if (string(DamageType) != "CRZDmgType_RocketLauncher")
		return;

	Damage *= Damage >= 100 ? DamageFactorDirect : DamageFactorSplash;
	if (Injured == InstigatedBy.Pawn)
		Damage *= DamageFactorSelf;

  
	Momentum.X = Momentum.X * KnockbackFactorHoriz;
	Momentum.Y = Momentum.Y * KnockbackFactorHoriz;
	Momentum.Z = FClamp(Momentum.Z * KnockbackFactorVert, MinKnockbackVert, MaxKnockbackVert);	
}

simulated event Tick(float DeltaTime)
{	
	local UTPawn P;
	local PlayerController PC;
	
	Super.Tick(Deltatime);

	foreach WorldInfo.LocalPlayerControllers(class'PlayerController', PC)
		TweakCerberus(PC.Pawn);

	if (Role == ROLE_Authority)
	{
		foreach WorldInfo.AllPawns(class'UTPawn', P)
			TweakCerberus(P);
	}
}

function TweakCerberus(Pawn p)
{
	local UTWeapon w;

	if (p != none && p.Weapon != none && string(p.Weapon.Class) == "CRZWeap_RocketLauncher")
	{
		w = UTWeapon(p.Weapon);
		w.FireInterval[0] = FireInterval;
	}
	if (p != none && DamageFactorSplash == 0 && p.Health > 0)
		p.Health = 100;
}

/*
function Mutate(string value, PlayerController sender)
{
	if (value == "i")
	{
		`log("kfh=" $ KnockbackFactorHoriz $ ", khv=" $ KnockbackFactorVert $ ", min=" $ MinKnockbackVert $ ", max=" $ MaxKnockbackVert $ ", fi=" $ FireInterval);
		`log("dfd=" $ DamageFactorDirect $ ", dfs=" $DamageFactorSplash $ ", dfi=" $ DamageFactorSelf);
	}
	else if (Left(value, 4) == "kfh ")
		KnockbackFactorHoriz = float(Mid(value, 4));
	else if (Left(value, 4) == "kfv ")
		KnockbackFactorVert = float(Mid(value, 4));
	else if (Left(value, 4) == "min ")
		MinKnockbackVert = float(Mid(value, 4));
	else if (Left(value, 4) == "max ")
		MaxKnockbackVert = float(Mid(value, 4));
	else if (Left(value, 3) == "fi ")
		FireInterval = float(Mid(value, 3));
	else if (Left(value, 4) == "dfd ")
		DamageFactorDirect = float(Mid(value, 4));
	else if (Left(value, 4) == "dfs ")
		DamageFactorSplash = float(Mid(value, 4));
	else if (Left(value, 4) == "dfi ")
		DamageFactorSelf = float(Mid(value, 4));
	else
		Super.Mutate(value, sender);
}
*/

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true
}
