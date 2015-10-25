// MutatH0r.CRZMutator_Roq3t
// ----------------
// Modify rocket damage (direct, splash, self), knockback (horiz, vert) and fire rate
// by PredatH0r
//================================================================

class CRZMutator_Roq3t extends UTMutator config (MutatH0r);

var config float KnockbackFactorHoriz, KnockbackFactorVertOthers, KnockbackFactorVertSelf, MinKnockbackVert, MaxKnockbackVert, FireInterval, DamageFactorDirect, DamageFactorSplash;
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
  local float knockbackFactorVert;

	Super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

	if (string(DamageType) != "CRZDmgType_RocketLauncher")
		return;

	Damage *= Damage >= 100 ? DamageFactorDirect : DamageFactorSplash;
	if (Injured == InstigatedBy.Pawn)
	{
		Damage *= DamageFactorSelf;
    knockbackFactorVert = KnockbackFactorVertSelf;
	}
  else
    knockbackFactorVert = KnockbackFactorVertOthers;
  
	Momentum.X = Momentum.X * KnockbackFactorHoriz;
	Momentum.Y = Momentum.Y * KnockbackFactorHoriz;
	Momentum.Z = FClamp(Momentum.Z * knockbackFactorVert, MinKnockbackVert, MaxKnockbackVert);	
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

function Mutate(string value, PlayerController sender)
{
  local string msg;

	if (value == "ro_info")
	{
    msg = "kfh=" $ KnockbackFactorHoriz $ ", kfvs=" $ KnockbackFactorVertSelf $ ", kfvo=" $ KnockbackFactorVertOthers $ ", min=" $ MinKnockbackVert $ ", max=" $ MaxKnockbackVert $ ", fi=" $ FireInterval;
		`log(msg); sender.ClientMessage(msg, 'Info');
    msg = "dfd=" $ DamageFactorDirect $ ", dfs=" $DamageFactorSplash $ ", dfi=" $ DamageFactorSelf;
		`log(msg); sender.ClientMessage(msg, 'Info');
	}
	else if (Left(value, 7) == "ro_kfh ")
		KnockbackFactorHoriz = float(Mid(value, 7));
	else if (Left(value, 8) == "ro_kfvs ")
		KnockbackFactorVertSelf = float(Mid(value, 8));
	else if (Left(value, 8) == "ro_kfvo ")
		KnockbackFactorVertOthers = float(Mid(value, 8));
	else if (Left(value, 7) == "ro_min ")
		MinKnockbackVert = float(Mid(value, 7));
	else if (Left(value, 7) == "ro_max ")
		MaxKnockbackVert = float(Mid(value, 7));
	else if (Left(value, 6) == "ro_fi ")
		FireInterval = float(Mid(value, 6));
	else if (Left(value, 7) == "ro_dfd ")
		DamageFactorDirect = float(Mid(value, 7));
	else if (Left(value, 7) == "ro_dfs ")
		DamageFactorSplash = float(Mid(value, 7));
	else if (Left(value, 7) == "ro_dfi ")
		DamageFactorSelf = float(Mid(value, 7));
  else if (value == "ro_0")
  {
    KnockbackFactorHoriz = 1.0;
    KnockbackFactorVertSelf = 1.0;
    KnockbackFactorVertOthers = 1.0;
    MinKnockbackVert = 0.0;
    MaxKnockbackVert = 1000000.0;
    FireInterval = 1.0;
    DamageFactorDirect = 1.0;
    DamageFactorSplash = 1.0;
    DamageFactorSelf = 1.0;
  }
  else if (value == "ro_1")
  {
    KnockbackFactorHoriz = 1.0;
    KnockbackFactorVertSelf = 1.25;
    KnockbackFactorVertOthers = 0.5;
    MinKnockbackVert = 0.0;
    MaxKnockbackVert = 1000000.0;
    FireInterval = 1.1;
    DamageFactorDirect = 1.0;
    DamageFactorSplash = 0.5;
    DamageFactorSelf = 2.0; // combines with Splash factor to 1.0
  }
  else if (value == "ro_1")
  {
    KnockbackFactorHoriz = 0.75;
    KnockbackFactorVertOthers = 0.75;
    KnockbackFactorVertSelf = 1.25;
    MinKnockbackVert = 0.0;
    MaxKnockbackVert = 100000.0;
    FireInterval = 1.1;
    DamageFactorDirect = 1.0;
    DamageFactorSplash = 1.0;
    DamageFactorSelf = 1.0;
  }
	else
		Super.Mutate(value, sender);
}


defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true
}
