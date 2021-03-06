// MutatH0r.CRZMutator_Roq3t
// ----------------
// Modify rocket damage (direct, splash, self), knockback (horiz, vert) and fire rate
// by PredatH0r
//================================================================

class CRZMutator_Roq3t extends CRZMutator config (MutatH0r);

const OPT_DrawDamageRadius = "DrawDamageRadius";
const OPT_Preset = "Roq3tPreset";
const OPT_Mutate = "Roq3tMutate";

var float Knockback, KnockbackFactorOthers, KnockbackFactorSelf, MinKnockbackVert, MaxKnockbackVert, FireInterval, DamageFactorDirect, DamageFactorSplash;
var float DamageFactorSelf, DamageRadius;
var float Speed;
var int InitialAmmo, MaxAmmo, PickupAmmo;
var bool DrawDamageRadius;
var bool AllowMutate;

var repnotify byte SettingsChanged;

var bool bAllowDisableTick;

replication
{
  if (Role == ENetRole.ROLE_Authority && (bNetInitial || bNetDirty))
    Knockback, FireInterval, DamageFactorDirect, DamageRadius, DrawDamageRadius, AllowMutate, Speed, 
      SettingsChanged;
}

static function CRZMutator_Roq3t GetInstance()
{
  local Mutator m;
  local CRZMutator_Roq3t r;
  local GameInfo game;
  
  game = class'WorldInfo'.static.GetWorldInfo().Game;
  if (game != none)
  {
    for (m = game.BaseMutator; m != None; m=m.NextMutator)
    {
      r = CRZMutator_Roq3t(m);
      if (r != none)
        return r;
    }
  }
  else
  {
    foreach class'WorldInfo'.static.GetWorldInfo().DynamicActors(class'CRZMutator_Roq3t', r)
      return r;
  }
  return none;
}

simulated event PostBeginPlay()
{
  super.PostBeginPlay();
  SetTickGroup(ETickingGroup.TG_PreAsyncWork);
}

function InitMutator(string options, out string error)
{
  local string val;

  super.InitMutator(options, error);

  ApplyPreset(class'GameInfo'.static.ParseOption(options, OPT_Preset));
  val = class'GameInfo'.static.ParseOption(options, OPT_DrawDamageRadius);
  if (val != "")
    DrawDamageRadius = bool(val);

  val = class'GameInfo'.static.ParseOption(options, OPT_Mutate);
  AllowMutate = val != "" ? bool(val) : (WorldInfo.NetMode == NM_Standalone);
}

function ApplyPreset(string presetName)
{
  local Roq3tConfig preset;

  if (presetName == "")
    presetName = "Preset1";
  preset = new(none, presetName) class'Roq3tConfig';
  preset.SetDefaults();
  ApplyConfig(preset);
}

function ApplyConfig(Roq3tConfig preset)
{
  Speed = preset.Speed;
  Knockback = preset.Knockback;
  KnockbackFactorSelf = preset.KnockbackFactorSelf;
  KnockbackFactorOthers = preset.KnockbackFactorOthers;
  MinKnockbackVert = preset.MinKnockbackVert;
  MaxKnockbackVert = preset.MaxKnockbackVert;
  FireInterval = preset.FireInterval;
  InitialAmmo = preset.InitialAmmo;
  MaxAmmo = preset.MaxAmmo;
  PickupAmmo = preset.PickupAmmo;
  DamageFactorDirect = preset.DamageFactorDirect;
  DamageFactorSplash = preset.DamageFactorSplash;
  DamageFactorSelf = preset.DamageFactorSelf;
  DamageRadius = preset.DamageRadius;
  DrawDamageRadius = preset.DrawDamageRadius;
  ApplySettings();
  ++SettingsChanged;
}

simulated function ApplySettings()
{
  local H0Weap_RocketLauncher w;
  local H0Proj_RocketLauncher p;

  foreach WorldInfo.DynamicActors(class'H0Weap_RocketLauncher', w)
    w.ApplySettings();
  foreach WorldInfo.DynamicActors(class'H0Proj_RocketLauncher', p)
    p.ApplySettings();

  if (DrawDamageRadius && WorldInfo.NetMode != NM_DedicatedServer)
    Enable('Tick');
  else if (bAllowDisableTick)
    Disable('Tick');
}

function bool CheckReplacement(Actor other)
{
  local CRZWeap_RocketLauncher w;
  local H0Weap_RocketLauncher r;
  w = CRZWeap_RocketLauncher(other);
  r = H0Weap_RocketLauncher(other);

  if (w != none && r == none)
  {
    ReplaceWith(other, "MutatH0r.H0Weap_RocketLauncher");
    //return false;
  }
  if (CRZWeaponPickupFactory(other) != none && CRZWeaponPickupFactory(other).WeaponPickupClass == class'Cruzade.CRZWeap_RocketLauncher')
  {
    CRZWeaponPickupFactory(other).WeaponPickupClass = class'MutatH0r.H0Weap_RocketLauncher';
    CRZWeaponPickupFactory(other).InventoryType = class'MutatH0r.H0Weap_RocketLauncher';
  }
  return true;
}

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
  local float kbFactor;

  super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

  if (DamageType != class'CRZDmgType_RocketLauncher')
    return;

  // MaxDamage (=InstigatedBy.Pawn.DamageScaling) seems to be applied later, so 100 is still ok here for a direct hit
  if (Damage == 100)
    Damage = Damage * DamageFactorDirect; 
  else
    Damage = FMin(Damage * DamageFactorSplash, 100); 
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
  local vector v;

  // draw splash radius
  if (DrawDamageRadius && WorldInfo.NetMode != NM_DedicatedServer)
  {
    foreach WorldInfo.DynamicActors(class'UTPawn', P)
    {
      v = P.CylinderComponent.GetPosition() + vect(0,0,-1) * P.CylinderComponent.CollisionHeight;
      P.DrawDebugCylinder(v, v, P.CylinderComponent.CollisionRadius + DamageRadius, 16, 255, 0, 0, false);
    }
  }
}

simulated event ReplicatedEvent(name varName)
{
  if (varName == 'SettingsChanged')
    ApplySettings();
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

  if (arg == "" )
    return;

  if (!AllowMutate)
  {
    sender.ClientMessage("<font color='#00ffff'>ro:</font> modifications are disabled");
    return;
  }

  if (cmd == "preset")
    ApplyPreset("preset" $ arg);
  else if (cmd ~= "RocketSpeed")
    Speed = float(arg);
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
  else if (cmd ~= "DamageRadius")
    DamageRadius = float(arg);
  else
  {
    sender.ClientMessage("Roq3t: unknown command: " $ cmd @ arg);
    return;
  }

  `log("Roq3t mutated:" @ cmd @ arg);

  ++SettingsChanged;
  ApplySettings();

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
  pc.ClientMessage("mutate ro DrawDamageRadius 0/1", 'Info');
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
  pc.ClientMessage("FireInterval=" $ FireInterval $ ", DamageRadius=" $ DamageRadius $ ", RocketSpeed=" $ Speed, 'Info');
  pc.ClientMessage("_____ Roq3t settings _____");
}


static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
  local Roq3tConfig preset;

  super.PopulateConfigView(ConfigView, MutatorDataProvider);

  preset = new(none, "Preset1") class'Roq3tConfig';
  ConfigView.SetMaskBounds(ConfigView.ListObject1, 400, 975, true);
  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_Roq3t');
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Rocket Speed", "Speed of the rocket projectile [1800]", 500, 7500, 50, preset.Speed, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Knockback", "Force pushing players away from point of impact [80]", 0, 200, 1, preset.Knockback / 1000, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "KB Factor Self", "Knockback factor when rocket-jumping [100%]", 0, 200, 1, preset.KnockbackFactorSelf * 100, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "KB Factor Others", "Knockback factor when hitting other players [100%]", 0, 200, 1, preset.KnockbackFactorOthers * 100, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Min Vertical KB", "Minimum vertical knockback [0]", 0, 1000, 10, preset.MinKnockbackVert, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Max Vertical KB", "Maximum vertical knockback [1000]", 0, 2000, 10, preset.MaxKnockbackVert, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Fire Rate", "Time between firing 2 rockets [1000 millisec]", 500, 2000, 10, preset.FireInterval * 1000, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Direct Damage %", "Factor to adjust damage of a direct hit [100]", 0, 400, 1, preset.DamageFactorDirect * 100, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Splash Damage %", "Factor to adjust splash damage hits [100]", 0, 400, 1, preset.DamageFactorSplash * 100, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Self Damage %", "Splash damage you do to yourself [100]", 0, 400, 1, preset.DamageFactorSelf*100, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Splash Radius", "Radius around ball impact for splash damage [190]", 0, 300, 10, preset.DamageRadius, OnSliderChanged);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Draw Splash Rad.", "Draw a circle indicating the splash damage area", preset.DrawDamageRadius, OnCheckboxClick);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Initial Ammo", "Ammo when you pick up a fresh Cerberus [10]", 1, 50, 1, preset.InitialAmmo, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Max Ammo", "Max amount of ammo you can hold [20]", 1, 50, 1, preset.MaxAmmo, OnSliderChanged);
//  class'MutConfigHelper'.static.AddSlider(ConfigView, "Pickup Ammo", "Amount of ammo added from a pickup [5]", 1, 10, 1, preset.PickupAmmo, OnSliderChanged);
}

function static OnSliderChanged(string label, float value, GFxClikWidget.EventData ev)
{
  local Roq3tConfig preset;

  preset = new(none, "Preset1") class'Roq3tConfig';

  // replacing 0 with 0.01 to allow the preset to identify settings that are missing in the config file (defaulting to value 0.00)
  switch(label)
  {
    case "Rocket Speed": preset.Speed = value; break;
    case "Knockback": preset.Knockback = value * 1000; break;
    case "KB Factor Self": preset.KnockbackFactorSelf = fmax(0.01, value/100); break;
    case "KB Factor Others": preset.KnockbackFactorOthers = fmax(0.01, value/100); break;
    case "Min Vertical KB": preset.MinKnockbackVert = fmax(0.01, value); break;
    case "Max Vertical KB": preset.MaxKnockbackVert = fmax(0.01, value); break;
    case "Fire Rate": preset.FireInterval = value / 1000; break;
    case "Direct Damage %": preset.DamageFactorDirect = fmax(0.01, value/100); break;
    case "Splash Damage %": preset.DamageFactorSplash = fmax(0.01, value/100); break;
    case "Self Damage %": preset.DamageFactorSelf = fmax(0.01, value/100); break;
    case "Splash Radius": preset.DamageRadius = fmax(0.01, value); break;
    case "Initial Ammo": preset.InitialAmmo = value; break;
    case "Max Ammo": preset.MaxAmmo = value; break;
    case "Pickup Ammo": preset.PickupAmmo = value; break;
  }

  preset.SaveConfig();
}

static function OnCheckboxClick(string label, bool value, GFxClikWidget.EventData ev)
{
  local Roq3tConfig preset;
  preset = new(none, "Preset1") class'Roq3tConfig';
  preset.DrawDamageRadius = value;
  preset.SaveConfig();
}

defaultproperties
{
  bAllowDisableTick=true
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true
//  GroupNames[0]="CERBERUS"
  bAllowMXPSave=true
  bAllowSCSave=false
  bRequiresDownloadOnClient=true
}
