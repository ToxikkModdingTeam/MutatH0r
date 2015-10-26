// MutatH0r.CRZMutator_Roq3t
// ----------------
// Modify rocket damage (direct, splash, self), knockback (horiz, vert) and fire rate
// by PredatH0r
//================================================================

class CRZMutator_Roq3t extends UTMutator config (MutatH0r);

var config float Knockback, KnockbackFactorOthers, KnockbackFactor, KnockbackFactorSelf, MinKnockbackVert, MaxKnockbackVert, FireInterval, DamageFactorDirect, DamageFactorSplash;
var config float DamageFactorSelf, DamageRadius;
var bool DrawDamageRadius;
var bool receivedWelcomeMessage;

replication
{
  if (Role == ENetRole.ROLE_Authority && (bNetInitial || bNetDirty))
    Knockback, FireInterval, DamageFactorDirect, DamageRadius, DrawDamageRadius;
}

simulated event PostBeginPlay()
{
  super.PostBeginPlay();
  SetTickGroup(ETickingGroup.TG_PreAsyncWork);
  Enable('Tick');

  DrawDamageRadius = true;
  Mutate("ro preset 1", none);

  // in NM_Standalone, messages aren't printed at this time, so set a timer
  if (WorldInfo.NetMode == NM_Client || WorldInfo.NetMode == NM_Standalone) 
    SetTimer(1.0, true, 'ShowWelcomeMessage');
}

simulated function ShowWelcomeMessage()
{
  local PlayerController pc;

  if (receivedWelcomeMessage)
    return;

  foreach WorldInfo.LocalPlayerControllers(class'PlayerController', pc)
  {
    pc.ClientMessage("Use console command <font color='#cc0000'>mutate ro help</font> to modify the <font color='#cc0000'>Cerberus</font>.");
    receivedWelcomeMessage = true;
  }

  if (receivedWelcomeMessage)
    ClearTimer('ShowWelcomeMessage');
}

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
  local float kbFactor;

  super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

  if (string(DamageType) != "CRZDmgType_RocketLauncher")
    return;

  Damage *= Damage == 100 ? DamageFactorDirect : DamageFactorSplash; // FIXME: doesn't work for MaxDamage powerup
  if (Injured == InstigatedBy.Pawn)
  {
    Damage *= DamageFactorSelf;
    kbFactor = KnockbackFactorSelf;
  }
  else
    kbFactor = KnockbackFactorOthers;
  
  Momentum.X = Momentum.X * kbFactor;
  Momentum.Y = Momentum.Y * kbFactor;
  Momentum.Z = FClamp(Momentum.Z * kbFactor, MinKnockbackVert, MaxKnockbackVert);	
}

simulated event Tick(float DeltaTime)
{	
  local UTPawn P;
  local PlayerController PC;
  local Projectile proj;
  local vector v;
  
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

  // draw splash radius
  if (DrawDamageRadius && (WorldInfo.NetMode == NM_Client || WorldInfo.NetMode == NM_Standalone))
  {
    foreach WorldInfo.DynamicActors(class'UTPawn', P)
    {
      v = P.CylinderComponent.GetPosition() + vect(0,0,-1) * P.CylinderComponent.CollisionHeight;
      P.DrawDebugCylinder(v, v, P.CylinderComponent.CollisionRadius + DamageRadius, 16, 255, 0, 0, false);
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
    super.Mutate(MutateString, Sender);
    ShowInfo(sender);
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

  if (cmd == "help")
  {
    ShowHelp(Sender);
    return;
  }
  if (cmd == "info")
  {
    ShowInfo(Sender);
    return;
  }

  if (arg == "")
    return;

  // modifications
  if ((cmd $ arg) == "preset0")
  {
    Knockback=80000;
    KnockbackFactorOthers = 1.0;
    KnockbackFactorSelf = 1.0;
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
    Knockback=80000 * 0.75;
    KnockbackFactorOthers = 1.0;
    KnockbackFactorSelf = 1.0 / 0.75;
    MinKnockbackVert = 0.0;
    MaxKnockbackVert = 100000.0;
    FireInterval = 1.1;
    DamageFactorDirect = 1.0;
    DamageFactorSplash = 1.0;
    DamageFactorSelf = 1.0; // server-side self damage is twice the bootcamp dmg (66)
    DamageRadius = 220;
  }
  else if ((cmd $ arg) == "preset2")
  {
    Knockback=80000;
    KnockbackFactorOthers = 0.75;
    KnockbackFactorSelf = 1.25;
    MinKnockbackVert = 0.0;
    MaxKnockbackVert = 1000000.0;
    FireInterval = 1.1;
    DamageFactorDirect = 1.0;
    DamageFactorSplash = 1.0;
    DamageFactorSelf = 1.0;
    DamageRadius = 160;
  }
  else if ((cmd $ arg) == "preset3")
  {
    Knockback=80000;
    KnockbackFactorOthers = 0.75;
    KnockbackFactorSelf = 1.25;
    MinKnockbackVert = 0.0;
    MaxKnockbackVert = 1000000.0;
    FireInterval = 0.85;
    DamageFactorDirect = 1.0;
    DamageFactorSplash = 0.5;
    DamageFactorSelf = 2.0; // combines with Splash factor to 1.0
    DamageRadius = 220;
  }
  else if (cmd ~= "KnockbackFactorOthers")
    KnockbackFactorOthers = float(arg);
  else if (cmd ~= "KnockbackFactorSelf")
    KnockbackFactorSelf = float(arg);
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
  else if (cmd ~= "DrawDamageRadius")
    DrawDamageRadius = bool(arg);
  else
  {
    sender.ClientMessage("Roq3t: unknown command: " $ cmd @ arg);
    return;
  }

  `log("Roq3t mutated:" @ cmd @ arg);

  if (sender == none)
    return;

  // tell everyone that a setting was changed
  foreach WorldInfo.AllControllers(class'PlayerController', pc)
  {
    pc.ClientMessage("Use <font color='#00ffff'>mutate ro info</font> to show the current settings.");
    pc.ClientMessage(sender.PlayerReplicationInfo.PlayerName $ " <font color='#ff0000'>modified Roq3t setting</font>: " $ cmd @ arg);
  }
}

function ShowHelp(PlayerController pc)
{
  pc.ClientMessage("mutate ro [setting] [value]: change [setting] to [value] (see 'mutate ro info')", 'Info');
  pc.ClientMessage("mutate ro info: show current Stingray settings", 'Info');
  pc.ClientMessage("mutate ro preset 3: reload=0.85, splash=0.5, self-bounce: 1.25, other-bounce=0.75", 'Info');
  pc.ClientMessage("mutate ro preset 2: reload=1.1, smaller splash radius, self-bounce=1.25, other-bounce=0.75", 'Info');
  pc.ClientMessage("mutate ro preset 1: reload=1.1, knockback=0.75, self-bounce=1.25", 'Info');
  pc.ClientMessage("mutate ro preset 0: TOXIKK defaults", 'Info');
  pc.ClientMessage("_____ Roq3t help _____");
}

function ShowInfo(PlayerController pc)
{
  // reverse order for chat log
  pc.ClientMessage("MinKnockbackVert=" $ MinKnockbackVert $ ", MaxKnockbackVert=" $ MaxKnockbackVert, 'Info');
  pc.ClientMessage("Knockback=" $ Knockback $ ", KnockbackFactorOthers=" $ KnockbackFactorOthers $ ", KnockbackFactorSelf=" $ KnockbackFactorSelf, 'Info');
  pc.ClientMessage("DamageFactorDirect=" $ DamageFactorDirect $ ", DamageFactorSplash=" $ DamageFactorSplash $ ", DamageFactorSelf=" $ DamageFactorSelf, 'Info');
  pc.ClientMessage("FireInterval=" $ FireInterval $ ", DamageRadius=" $ DamageRadius, 'Info');
  pc.ClientMessage("_____ Roq3t settings _____");
}


defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true
}
