// MutatH0r.CRZMutator_SuperStingray
// ----------------
// Dynamically configurable weapon, which allows changing weapon and projectile settings on the fly
// 
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_SuperStingray extends CRZMutator config (MutatH0r);

struct TaggedPawnInfo
{
  var Pawn Pawn;
  var float ExpirationTime;
  var float ComboExtraDamage;
};

const OPT_DrawDamageRadius = "DrawDamageRadius";
const OPT_Preset = "SuperRayPreset";
const OPT_Mutate = "SuperRayMutate";

var float DamagePlasma, DamageBeam, DamageCombo;
var float KnockbackPlasma, KnockbackBeam, DamageRadius;
var float TagDuration;
var float DamageFactorSelf, DamageFactorSplash, LevitationSelf, LevitationOthers;
var float FireIntervalPlasma, FireIntervalBeam;
var bool receivedWelcomeMessage;
var LinearColor TagColor;
var bool DrawDamageRadius;
var bool AllowMutate;
var int ShotCostPlasma, ShotCostBeam;
var bool SwapButtons;

var repnotify byte SettingsChanged;


var bool bConfigWidgets;
var bool bAllowDisableTick;

// server only
var array<TaggedPawnInfo> TaggedPawns;


replication
{
  if (Role == ENetRole.ROLE_Authority && (bNetInitial || bNetDirty))
    DamagePlasma, DamageRadius, KnockbackPlasma, FireIntervalPlasma, FireIntervalBeam, DamageBeam, DrawDamageRadius, AllowMutate, ShotCostPlasma, ShotCostBeam, SwapButtons,
      SettingsChanged;
}

static function CRZMutator_SuperStingray GetInstance()
{
  local Mutator m;
  local CRZMutator_SuperStingray r;
  local GameInfo game;
  
  game = class'WorldInfo'.static.GetWorldInfo().Game;
  if (game != none)
  {
    for (m = game.BaseMutator; m != None; m=m.NextMutator)
    {
      r = CRZMutator_SuperStingray(m);
      if (r != none)
        return r;
    }
  }
  else
  {
    foreach class'WorldInfo'.static.GetWorldInfo().DynamicActors(class'CRZMutator_SuperStingray', r)
      return r;
  }
  return none;
}

simulated event PostBeginPlay()
{
  super.PostBeginPlay();
  SetTickGroup(ETickingGroup.TG_PreAsyncWork);

  if (Role == ROLE_Authority)
    SetTimer(1.0, true, 'CleanupTaggedPawns');
}

function InitMutator(string options, out string error)
{
  local string val;


  super.InitMutator(options, error);

  ApplyPresetName(class'GameInfo'.static.ParseOption(options, OPT_Preset));
  val = class'GameInfo'.static.ParseOption(options, OPT_DrawDamageRadius);
  if (val != "")
    DrawDamageRadius = bool(val);

  val = class'GameInfo'.static.ParseOption(options, OPT_Mutate);
  AllowMutate = val != "" ? bool(val) : (WorldInfo.NetMode == NM_Standalone);
}

function ApplyPresetName(string presetName)
{
  local SuperStingrayConfig preset;

  if (presetName == "")
    presetName = "Preset1";
  preset = new(none, presetName) class'SuperStingrayConfig';
  preset.SetDefaults();
  ApplyPreset(preset);
}

function ApplyPreset(SuperStingrayConfig preset)
{
  DamagePlasma = preset.DamagePlasma;
  DamageBeam = preset.DamageBeam;
  DamageCombo = preset.DamageCombo;
  DamageRadius = preset.DamageRadius;
  DrawDamageRadius = preset.DrawDamageRadius;
  DamageFactorSelf = preset.DamageFactorSelf;
  DamageFactorSplash = preset.DamageFactorSplash;
  KnockbackPlasma = preset.KnockbackPlasma;
  KnockbackBeam = preset.KnockbackBeam;
  LevitationSelf = preset.LevitationSelf;
  LevitationOthers = preset.LevitationOthers;
  FireIntervalPlasma = preset.FireIntervalPlasma;
  FireIntervalBeam = preset.FireIntervalBeam;
  TagColor = preset.TagColor;
  TagDuration = preset.TagDuration;
  SwapButtons = preset.SwapButtons;
  ShotCostPlasma = preset.ShotCost[0];
  ShotCostBeam = preset.ShotCost[1];

  ApplySettings();
  ++SettingsChanged;
}

function bool CheckReplacement(Actor other)
{
  local CRZWeap_ScionRifle w;
  local H0Weap_ScionRifle r;
  w = CRZWeap_ScionRifle(other);
  r = H0Weap_ScionRifle(other);

  if (w != none && r == none)
  {
    ReplaceWith(other, "MutatH0r.H0Weap_ScionRifle");
    //return false;
  }
  if (CRZWeaponPickupFactory(other) != none && CRZWeaponPickupFactory(other).WeaponPickupClass == class'Cruzade.CRZWeap_ScionRifle')
  {
    CRZWeaponPickupFactory(other).WeaponPickupClass = class'MutatH0r.H0Weap_ScionRifle';
    CRZWeaponPickupFactory(other).InventoryType = class'MutatH0r.H0Weap_ScionRifle';
  }
  return true;
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
  local UTPawn p;
  local Vector v;

  // draw splash radius
  if (DrawDamageRadius && WorldInfo.NetMode != NM_DedicatedServer)
  {
    foreach WorldInfo.DynamicActors(class'UTPawn', P)
    {
      v = P.CylinderComponent.GetPosition() + vect(0,0,-1) * P.CylinderComponent.CollisionHeight;
      P.DrawDebugCylinder(v, v, P.CylinderComponent.CollisionRadius + DamageRadius, 16, 0, 255, 255, false);
    }
  }
}


simulated function ApplySettings()
{
  local H0Weap_ScionRifle w;
  local H0Proj_ScionRifle p;

  foreach WorldInfo.DynamicActors(class'H0Weap_ScionRifle', w)
    w.ApplySettings();
  foreach WorldInfo.DynamicActors(class'H0Proj_ScionRifle', p)
    p.ApplySettings();

  if (DrawDamageRadius && WorldInfo.NetMode != NM_DedicatedServer)
    Enable('Tick');
  else if (bAllowDisableTick)
    Disable('Tick');
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
      else if (string(DamageType) == "CRZDmgType_ScionRifle" || string(DamageType) == "CRZDmgType_ScionRifle_Headshot")
      {
        //`log("Added bonus damage: " $ tagInfo.ComboExtraDamage);
        Damage += tagInfo.ComboExtraDamage;
        tagInfo.ComboExtraDamage = 0;
      }
 
      TaggedPawns[tagInfoIndex] = tagInfo;
      //victim.SetBodyMatColor(TagColor, TagDuration);
    }

    // modify self damage (plasma splash)
    if (isSelfDamage)
      Damage *= DamageFactorSelf;

    // add knockback
    if (string(DamageType) == "CRZDmgType_Scion_Plasma")
      Momentum.Z += isSelfDamage ? LevitationSelf : LevitationOthers;
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

  if (!AllowMutate)
  {
    super.Mutate(MutateString, Sender);
    return;
  }

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

  if (!AllowMutate)
  {
    sender.ClientMessage("<font color='#00ffff'>sr:</font> modifications are disabled");
    return;
  }

  if (cmd == "preset")
    ApplyPresetName("preset" $ arg);
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

  ApplySettings();
  ++SettingsChanged;

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
  pc.ClientMessage("mutate sr DrawDamageRadius 0/1", 'Info');
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

simulated event ReplicatedEvent(name varName)
{
  if (varName == 'SettingsChanged')
    ApplySettings();
}


static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
  local SuperStingrayConfig preset;

  super.PopulateConfigView(ConfigView, MutatorDataProvider);

  if (!default.bConfigWidgets)
    return;

  ConfigView.SetMaskBounds(ConfigView.ListObject1, 400, 975, true);

  preset = new(none, "Preset1") class'SuperStingrayConfig';
  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_SuperStingray');

  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Swap Buttons", "Swap primary and secondary fire", preset.SwapButtons, OnCheckboxClick);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Damage Ball", "Damage dealt by a direct plasma ball hit [17]", 0, 400, 1, preset.DamagePlasma, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Damage Beam", "Damage dealt by a beam hit [45]", 0, 400, 1, preset.DamageBeam, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Damage Combo", "Extra damage per ball when following up with a beam [8]", 0, 100, 1, preset.DamageCombo, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Fire Rate Ball", "Time between firing 2 plasma balls [167 millisec]", 0, 2000, 10, preset.FireIntervalPlasma * 1000, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Fire Rate Beam", "Time between firing 2 beams [770 millisec]", 0, 2000, 10, preset.FireIntervalBeam * 1000, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Knockback Ball", "Force pushing player away from point of impact [200]", 0, 350, 10, preset.KnockbackPlasma / 100, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Knockback Beam", "Force pushing player away [200]", -1000, 1000, 10, preset.KnockbackBeam / 100, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Lift yourself", "Lifting yourself up with splash damage [50]", 0, 200, 5, preset.LevitationSelf, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Lift others", "Lifting other players up with splash damage [100]", 0, 200, 5, preset.LevitationOthers, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Self Damage %", "Splash damage you do to yourself [100]", 0, 400, 5, preset.DamageFactorSelf*100, OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Splash Radius", "Radius around ball impact for splash damage [120]", 0, 200, 10, preset.DamageRadius, OnSliderChanged);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Draw Splash Rad.", "Draw a circle indicating the splash damage area", preset.DrawDamageRadius, OnCheckboxClick);
}

function static OnSliderChanged(string label, float value, GFxClikWidget.EventData ev)
{
  local SuperStingrayConfig preset;

  preset = new(none, "Preset1") class'SuperStingrayConfig';

  switch(label)
  {
    case "Damage Ball": preset.DamagePlasma = value; break;
    case "Damage Beam": preset.DamageBeam = value; break;
    case "Damage Combo": preset.DamageCombo = value; break;
    case "Fire Rate Ball": preset.FireIntervalPlasma = value / 1000; break;
    case "Fire Rate Beam": preset.FireIntervalBeam = value / 1000; break;
    case "Knockback Ball": preset.KnockbackPlasma = value * 100; break;
    case "Knockback Beam": preset.KnockbackBeam = value * 100; break;
    case "Lift yourself": preset.LevitationSelf = value; break;
    case "Lift others": preset.LevitationOthers = value; break;
    case "Splash Radius": preset.DamageRadius = value; break;
    case "Self Damage %": preset.DamageFactorSelf = value/100; break;
  }

  preset.SaveConfig();
}

static function OnCheckboxClick(string label, bool value, GFxClikWidget.EventData ev)
{
  local SuperStingrayConfig preset;
  preset = new(none, "Preset1") class'SuperStingrayConfig';
  if (label == "Swap Buttons") 
    preset.SwapButtons = value;
  else if (label == "Draw Splash Rad.") 
    preset.DrawDamageRadius = value;
  preset.SaveConfig();
}


defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true
 
  bConfigWidgets=true
  bAllowDisableTick=true

  //TagDuration=1.0
  TagColor=(A=255.0, R=0.0, G=128.0, B=0.0)
  //DamagePlasma=17
  //DamageRadius=120
  //DamageBeam=50
  //DamageCombo=50
  //KnockbackPlasma=20000
  //LevitationSelf=50
  //LevitationOthers=100
  //SelfDamageFactor=0
  GroupNames[0]="STINGRAY"
}