// MutatH0r.CRZMutator_Roq3t
// ----------------
// Modify rocket damage (direct, splash, self), knockback (horiz, vert) and fire rate
// by PredatH0r
//================================================================

class CRZMutator_Roq3t extends UTMutator config (MutatH0r);

var config float Knockback, KnockbackFactorHoriz, KnockbackFactorVertOthers, KnockbackFactorVertSelf, MinKnockbackVert, MaxKnockbackVert, FireInterval, DamageFactorDirect, DamageFactorSplash;
var config float DamageFactorSelf, DamageRadius;

replication
{
	if (Role == ENetRole.ROLE_Authority && (bNetInitial || bNetDirty))
		Knockback, FireInterval, DamageFactorDirect, DamageRadius;
}

function NotifyLogin(Controller newPlayer)
{
  local PlayerController pc;
  pc = PlayerController(newPlayer);
  if (pc != none)
  {
    //ShowInfo(pc);
    pc.ClientMessage("<font color='#880000'>Roq3t mutator</font>: Use console command <font color='#880000'>mutate ro help</font> to modify the Cerberus.");
  }

  super.NotifyLogin(newPlayer);
}

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	SetTickGroup(ETickingGroup.TG_PreAsyncWork);
	Enable('Tick');
}

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
  local float knockbackFactorVert;

	super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

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
  local Projectile proj;
	
	Super.Tick(Deltatime);

  // modify Cerberus
	if (Role == ROLE_Authority)
	{
		foreach WorldInfo.AllPawns(class'UTPawn', P)
			TweakCerberus(P);
	}
  else
  {
	  foreach WorldInfo.LocalPlayerControllers(class'PlayerController', PC)
		  TweakCerberus(PC.Pawn);
  }

  // modify rocket projectiles
  foreach WorldInfo.DynamicActors(class'Projectile', proj)
  {
    if (string(proj.Class) == "CRZProj_Rocket")
    {
      proj.Damage = 100 * DamageFactorDirect;
	    proj.DamageRadius = DamageRadius;
      proj.MomentumTransfer = Knockback;
    }
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
}

function Mutate(string MutateString, PlayerController sender)
{
  local PlayerController pc;
  local string cmd;
  local string arg;
  local int i;

  if (MutateString == "info") // dump info for all mutators
  {
    ShowInfo(sender);
    super.Mutate(MutateString, Sender);
    return;
  }

  if (left(MutateString, 3) != "ro ")
  {
    super.Mutate(MutateString, Sender);
    return;
  }

  cmd = mid(MutateString, 3);
  i = instr(cmd, " ");
  if (i >= 0)
  {
    arg = mid(cmd, i+1);
    cmd = left(cmd, i);
  }

  if (cmd == "info")
  {
    ShowInfo(Sender);
    return;
  }
  if (cmd == "help")
  {
    ShowHelp(Sender);
    return;
  }

  if (arg == "")
    return;

  // modifications
  if ((cmd $ arg) == "preset0")
  {
    Knockback=80000;
    KnockbackFactorHoriz = 1.0;
    KnockbackFactorVertSelf = 1.0;
    KnockbackFactorVertOthers = 1.0;
    MinKnockbackVert = 0.0;
    MaxKnockbackVert = 1000000.0;
    FireInterval = 1.0;
    DamageFactorDirect = 1.0;
    DamageFactorSplash = 1.0;
    DamageFactorSelf = 1.0;
    DamageRadius = 220;
  }
  else if ((cmd $ arg) == "preset1")
  {
    Knockback=80000;
    KnockbackFactorHoriz = 1.0;
    KnockbackFactorVertSelf = 1.25;
    KnockbackFactorVertOthers = 0.75;
    MinKnockbackVert = 0.0;
    MaxKnockbackVert = 1000000.0;
    FireInterval = 0.85;
    DamageFactorDirect = 1.0;
    DamageFactorSplash = 0.5;
    DamageFactorSelf = 2.0; // combines with Splash factor to 1.0
    DamageRadius = 220;
  }
  else if ((cmd $ arg) == "preset2")
  {
    Knockback=80000 * 0.75;
    KnockbackFactorHoriz = 1.0;
    KnockbackFactorVertOthers = 1.0;
    KnockbackFactorVertSelf = 1.25 / 0.75;
    MinKnockbackVert = 0.0;
    MaxKnockbackVert = 100000.0;
    FireInterval = 1.1;
    DamageFactorDirect = 1.0;
    DamageFactorSplash = 1.0;
    DamageFactorSelf = 1.0;
    DamageRadius = 220;
  }
	else if (cmd ~= "KnockbackFactorHoriz")
		KnockbackFactorHoriz = float(arg);
	else if (cmd ~= "KnockbackFactorVertSelf")
		KnockbackFactorVertSelf = float(arg);
	else if (cmd ~= "KnockbackFactorVertOthers")
		KnockbackFactorVertOthers = float(arg);
	else if (cmd ~= "MinKnockbackVert")
		MinKnockbackVert = float(arg);
	else if (cmd ~= "MaxKnockbackVert")
		MaxKnockbackVert = float(arg);
	else if (cmd ~= "FireInterval")
		FireInterval = float(arg);
	else if (cmd ~= "DamageFactorDirect")
		DamageFactorDirect = float(arg);
	else if (cmd ~= "DamageFactorSplash")
		DamageFactorSplash = float(arg);
	else if (cmd ~= "DamageFactorSelf")
		DamageFactorSelf = float(arg);
	else
	{
    sender.ClientMessage("Roq3t: unknown command: " $ cmd @ arg);
    return;
	}

  // tell everyone that a setting was changed
  foreach WorldInfo.AllControllers(class'PlayerController', pc)
  {
    pc.ClientMessage("Use <font color='#00ffff'>mutate ro info</font> to show the current settings.");
    pc.ClientMessage(sender.PlayerReplicationInfo.PlayerName $ " <font color='#ff0000'>modified Roq3t setting</font>: " $ cmd @ arg);
  }
}

function ShowHelp(PlayerController Sender)
{
  Sender.ClientMessage("mutate ro [setting] [value]: change [setting] to [value] (see 'mutate ro info')", 'Info');
  Sender.ClientMessage("mutate ro info: show current Stingray settings", 'Info');
  Sender.ClientMessage("mutate ro preset 2: reload=1.1, knockback=0.75, self-bounce=1.25", 'Info');
  Sender.ClientMessage("mutate ro preset 1: reload=0.85, splash=0.5, self-bounce: 1.25, other-bounce=0.75", 'Info');
  Sender.ClientMessage("mutate ro preset 0: TOXIKK defaults", 'Info');
  Sender.ClientMessage("_____ Roq3t help _____");
}

function ShowInfo(PlayerController Sender)
{
  // reverse order for chat log
  Sender.ClientMessage("MinKnockbackVert=" $ MinKnockbackVert $ ", MaxKnockbackVert=" $ MaxKnockbackVert, 'Info');
  Sender.ClientMessage("KnockbackFactorHoriz=" $ KnockbackFactorHoriz $ ", KnockbackFactorVertOthers=" $ KnockbackFactorVertOthers $ ", KnockbackFactorVertSelf=" $ KnockbackFactorVertOthers, 'Info');
  Sender.ClientMessage("FireInterval=" $ FireInterval $ ", DamageFactorDirect=" $ DamageFactorDirect $ ", DamageFactorSplash=" $ DamageFactorSplash $ ", DamageRadius=" $ DamageRadius, 'Info');
  Sender.ClientMessage("_____ Roq3t settings _____");
}


defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true
}
