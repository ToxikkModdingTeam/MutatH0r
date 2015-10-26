// MutatH0r.CRZMutator_SuperStingray
// ----------------
// Less damage per plasma ball, but splash damage and levitation effect
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_SuperStingray extends UTMutator config (MutatH0r);

struct TaggedPawnInfo
{
  var Pawn Pawn;
  var float ExpirationTime;
  var float ComboExtraDamage;
};

var config float DamagePlasma, DamageBeam, DamageCombo;
var config float KnockbackPlasma, KnockbackBeam, DamageRadius;
var config float TagDuration;
var config float DamageFactorSelf, DamageFactorSplash, LevitationSelf, LevitationOthers;
var config float FireIntervalPlasma, FireIntervalBeam;
var bool receivedWelcomeMessage;
var LinearColor TagColor;
var bool DrawDamageRadius;

// server only
var array<TaggedPawnInfo> TaggedPawns;


replication
{
  if (Role == ENetRole.ROLE_Authority && (bNetInitial || bNetDirty))
    DamagePlasma, DamageRadius, KnockbackPlasma, FireIntervalPlasma, FireIntervalBeam, DamageBeam, DrawDamageRadius;
}

simulated event PostBeginPlay()
{
  super.PostBeginPlay();
  SetTickGroup(ETickingGroup.TG_PreAsyncWork);
  Enable('Tick');

  DrawDamageRadius=true;
  Mutate("sr preset 1", none);

  // in NM_Standalone, messages aren't printed at this time, so set a timer
  if (WorldInfo.NetMode == NM_Client || WorldInfo.NetMode == NM_Standalone) 
    SetTimer(1.0, true, 'ShowWelcomeMessage');
  
  if (Role == ROLE_Authority)
    SetTimer(1.0, true, 'CleanupTaggedPawns');
}

simulated function ShowWelcomeMessage()
{
  local PlayerController pc;

  if (receivedWelcomeMessage)
    return;

  foreach WorldInfo.LocalPlayerControllers(class'PlayerController', pc)
  {
    pc.ClientMessage("Use console command <font color='#00ffff'>mutate sr help</font> to modify the <font color='#00ffff'>Stingray</font>.");
    receivedWelcomeMessage = true;
  }

  if (receivedWelcomeMessage)
    ClearTimer('ShowWelcomeMessage');
}

function CleanupTaggedPawns()
{
  local int i;

  // clean up list of pawns tagged for combo-damage
  for (i=0; i<TaggedPawns.Length; i++)
  {
    if (TaggedPawns[i].ExpirationTime < WorldInfo.TimeSeconds)
    {
      TaggedPawns.Remove(i, 1);
      --i;
    }
  }
}

simulated function Tick(float DeltaTime)
{
  local PlayerController pc;
  local UTPawn p;
  local Projectile proj;
  local Vector v;

  // modify fire interval
  if (Role == ROLE_Authority)
  {
    foreach WorldInfo.AllPawns(class'UTPawn', p)
      TweakStingray(p);
  }
  else
  {
    foreach WorldInfo.LocalPlayerControllers(class'PlayerController', pc)
      TweakStingray(pc.Pawn);
  }

  // tweak plasma balls
  foreach WorldInfo.DynamicActors(class'Projectile', proj)
  {
    if (string(proj.Class) == "CRZProj_ScionRifle" && proj.Damage != DamagePlasma)
    {
      proj.Damage = DamagePlasma;
      proj.DamageRadius = DamageRadius;
      proj.MomentumTransfer = KnockbackPlasma;
    }
  }

  // draw splash radius
  if (DrawDamageRadius && (WorldInfo.NetMode == NM_Client || WorldInfo.NetMode == NM_Standalone))
  {
    foreach WorldInfo.DynamicActors(class'UTPawn', P)
    {
      v = P.CylinderComponent.GetPosition() + vect(0,0,-1) * P.CylinderComponent.CollisionHeight;
      P.DrawDebugCylinder(v, v, P.CylinderComponent.CollisionRadius + DamageRadius, 16, 0, 255, 255, false);
    }
  }
}


simulated function TweakStingray(Pawn P)
{
  local UTWeapon W;
 
  if (P == None)
    return;
  W = UTWeapon(P.Weapon);
  if (W != none && string(W.Class) == "CRZWeap_ScionRifle")
  {
    W.InstantHitDamage[1] = DamageBeam;
    W.FireInterval[0] = FireIntervalPlasma;
    W.FireInterval[1] = FireIntervalBeam;
  }               
}


function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
  local UTPawn victim;
  local bool isSelfDamage;
  local int tagInfoIndex;
  local TaggedPawnInfo tagInfo;

  Super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

  if (instr(string(DamageType), "CRZDmgType_Scion") >=0)
  {
    victim = UTPawn(Injured);
    isSelfDamage = Injured == InstigatedBy.Pawn;

    // combo handling
    if (!isSelfDamage && DamageCombo != 0 && TagDuration != 0)
    {
      tagInfoIndex = GetTaggedPawnInfoIndex(victim);
      //`log("Target was" $ (tagInfoIndex < 0 ? " NOT " : "") $ " tagged before");
      if (tagInfoIndex >= 0)
      {
        tagInfo = TaggedPawns[tagInfoIndex];
        if (tagInfo.ExpirationTime < WorldInfo.TimeSeconds)
          tagInfo.ComboExtraDamage = 0;
      }
      else
      {
        tagInfo.Pawn = Injured;
        TaggedPawns.Add(1);
        tagInfoIndex = TaggedPawns.Length - 1;
      }
      tagInfo.ExpirationTime = WorldInfo.TimeSeconds + TagDuration;

      if (string(DamageType) == "CRZDmgType_Scion_Plasma")
      {
        tagInfo.ComboExtraDamage += DamageCombo;
        if (Damage != DamagePlasma)
          Damage *= DamageFactorSplash;
      }
      else if (string(DamageType) == "CRZDmgType_ScionRifle")
      {
        `log("Added bonus damage: " $ tagInfo.ComboExtraDamage);
        Damage += tagInfo.ComboExtraDamage;
      }
 
      TaggedPawns[tagInfoIndex] = tagInfo;
      victim.SetBodyMatColor(TagColor, TagDuration);
    }

    // modify self damage (plasma splash)
    if (isSelfDamage)
      Damage *= DamageFactorSelf;

    // add knockback
    if (string(DamageType) == "CRZDmgType_Scion_Plasma")
      Momentum.Z += isSelfDamage ? LevitationSelf : LevitationOthers;
    else if (KnockbackBeam != 0 && InstigatedBy != none)
      Momentum += normal(Injured.Location - InstigatedBy.Pawn.Location) * KnockbackBeam;
  }
}

function int GetTaggedPawnInfoIndex(Pawn pawn)
{
  local int i;
  for (i=0; i<TaggedPawns.Length; i++)
  {
    if (TaggedPawns[i].Pawn == pawn)
      return i;
  }
  return -1;
}


function Mutate(string MutateString, PlayerController Sender)
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

  if (left(MutateString, 3) != "sr ")
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
    DamagePlasma = 35;
    DamageRadius = 0;
    DamageFactorSplash = 0;
    DamageFactorSelf = 0;
    KnockbackPlasma = 0;
    KnockbackBeam = 0;
    DamageBeam = 45;
    DamageCombo = 0;
    TagDuration = 0;
    LevitationSelf = 0;
    LevitationOthers = 0;
    FireIntervalPlasma = 0.1667;
    FireIntervalBeam = 0.85;
  }
  else if ((cmd $ arg) == "preset1")
  {
    DamagePlasma = 17;
    DamageRadius = 120;
    DamageFactorSplash = 1.0;
    DamageFactorSelf = 0.5;
    KnockbackPlasma = 20000;
    KnockbackBeam = 0;
    DamageBeam = 45;
    DamageCombo = 8;
    TagDuration = 2;
    LevitationSelf = 50;
    LevitationOthers = 100;
    FireIntervalPlasma = 0.1667;
    FireIntervalBeam = 0.85;
  }
  else if ((cmd $ arg) == "preset2")
  {
    DamagePlasma = 17;
    DamageRadius = 120;
    DamageFactorSplash = 1.0;
    DamageFactorSelf = 1.0;
    KnockbackPlasma = 20000;
    KnockbackBeam = 200;
    DamageBeam = 30;
    DamageCombo = 13;
    TagDuration = 1.5;
    LevitationSelf = 50;
    LevitationOthers = 100;
    FireIntervalPlasma = 0.1667;
    FireIntervalBeam = 0.6667;
  }
  else if (cmd ~= "DamagePlasma")
    DamagePlasma = float(arg);
  else if (cmd ~= "DamageRadius")
    DamageRadius = float(arg);
  else if (cmd ~= "DamageFactorSplash")
    DamageFactorSplash = float(arg);
  else if (cmd ~= "DamageFactorSelf")
    DamageFactorSelf = float(arg);
  else if (cmd ~= "KnockbackPlasma")
    KnockbackPlasma = float(arg);
  else if (cmd ~= "KnockbackBeam")
    KnockbackBeam = float(arg);
  else if (cmd ~= "DamageBeam")
    DamageBeam = float(arg);
  else if (cmd ~= "DamageCombo")
    DamageCombo = float(arg);
  else if (cmd ~= "TagDuration")
    TagDuration = float(arg);
  else if (cmd ~= "LevitationSelf")
    LevitationSelf = float(arg);
  else if (cmd ~= "LevitationOthers")
    LevitationOthers = float(arg);
  else if (cmd ~= "FireIntervalPlasma")
    FireIntervalPlasma = float(arg);
  else if (cmd ~= "FireIntervalBeam")
    FireIntervalBeam = float(arg);
  else if (cmd ~= "DrawDamageRadius")
    DrawDamageRadius = bool(arg);
  else
  {
    sender.ClientMessage("SuperStingray: unknown command: " $ cmd @ arg);
    return;
  }

  `log("SuperStingray mutated:" @ cmd @ arg);

  if (sender == none)
    return;

  // tell everyone that a setting was changed
  foreach WorldInfo.AllControllers(class'PlayerController', pc)
  {
    pc.ClientMessage("Use <font color='#00ffff'>mutate sr info</font> to show the current settings.");
    pc.ClientMessage(sender.PlayerReplicationInfo.PlayerName $ " <font color='#ff0000'>modified SuperStingray setting</font>: " $ cmd @ arg);
  }
}

function ShowHelp(PlayerController pc)
{
  // reverse order for chat log
  pc.ClientMessage("mutate sr [setting] [value]: change [setting] to [value] (see 'mutate sr info')", 'Info');
  pc.ClientMessage("mutate sr info: show current Stingray settings", 'Info');
  pc.ClientMessage("mutate sr preset 2: plasma=17, combo bonus=13, beam=30 with faster reload", 'Info');
  pc.ClientMessage("mutate sr preset 1: plasma=17, combo bonus=8, beam=45", 'Info');
  pc.ClientMessage("mutate sr preset 0: TOXIKK defaults", 'Info');
  pc.ClientMessage("_____ SuperStingray help _____");
}

function ShowInfo(PlayerController pc)
{
  // reverse order for chat log
  pc.ClientMessage("LevitationOthers=" $ LevitationOthers $ ", LevitationSelf=" $ LevitationSelf, 'Info');
  pc.ClientMessage("DamageBeam=" $ DamageBeam $ ", FireIntervalBeam=" $ FireIntervalBeam $ ", KnockbackBeam=" $ KnockbackBeam, 'Info');
  pc.ClientMessage("DamageCombo=" $ DamageCombo $ ", TagDuration=" $ TagDuration, 'Info');
  pc.ClientMessage("DamageFactorSplash=" $ DamageFactorSplash $ ", DamageFactorSelf=" $ DamageFactorSelf $ ", KnockbackPlasma=" $ KnockbackPlasma, 'Info');
  pc.ClientMessage("DamagePlasma=" $ DamagePlasma $ ", FireIntervalPlasma=" $ FireIntervalPlasma $ ", DamageRadius=" $ DamageRadius, 'Info');
  pc.ClientMessage("_____ SuperStingray settings _____");
}

defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true

  //TagDuration=1.0
  TagColor=(A=255.0, R=0.0, G=128.0, B=0.0)
  //DamagePlasma=17
  //DamageRadius=120
  //DamageBeam=50
  //DamageCombo=50
  //KnockbackPlasma=20000
  //LevitationSelf=50
  //ExtraUpOthers=100
  //SelfDamageFactor=0
}