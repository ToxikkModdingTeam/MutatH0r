class CRZMutator_Loadout extends CRZMutator config(MutatH0r);

const OPT_LoadoutPreset = "?LoadoutPreset=";
const OPT_Loadout = "?Loadout=";

var CRZMutator_LoadoutPreset preset;
var array<class<Weapon> > weapons;
var bool InfiniteAmmo;

replication
{
  if (Role == ROLE_Authority && (bNetInitial || bNetDirty))
    InfiniteAmmo;
}

function PostBeginPlay()
{
  Super.PostBeginPlay();

  // UTInvManager.bInfiniteAmmo only resets the ammo count back to MaxValue when it goes below 0, which prevents shots that need more than 1 ammo
  // Without the SDKK and the ability to subclass the weapons, the only way to modify them on the client side is through Tick
  SetTickGroup(ETickingGroup.TG_DuringAsyncWork);
  Enable('Tick');
}

function InitMutator(string options, out string error)
{
  local int idx;
  local string s, presetId;
  
  super.InitMutator(options, error);

  // extract preset number from ?LoadoutPreset=... parameter
  idx = instr(options, OPT_LoadoutPreset, false, true);
  if (idx >= 0)
  {
    s = mid(options, idx + len(OPT_LoadoutPreset));
    idx = instr(s, "?");
    if (idx >= 0)
      s = left(s, idx);
    presetId = s;
  }
  if (presetId == "")
    presetId = "Preset1";

  // load the preset and initialize internal variables
  preset = new(none, presetId) class'CRZMutator_LoadoutPreset';
  ApplyOptionOverrides(options);
  InitWeapons();
  if (weapons.Length == 0)
  {
    // failsafe for bad config or preset name
    preset = new() class'CRZMutator_LoadoutPreset';
    preset.Ravager = true;
    preset.Raven = true;
    preset.AllowWeaponPickups = true;
    InitWeapons();
  }

  InfiniteAmmo = preset.InfiniteAmmo;
  if (!preset.RandomWeapon)
    SetDefaultInventory();
}

function ApplyOptionOverrides(string options)
{
  local int idx;
  local string s;
  
  // extract ?Loadout=... parameter
  idx = instr(options, OPT_Loadout, false, true);
  if (idx < 0) 
    return;
  
  s = mid(options, idx + len(OPT_Loadout));
  idx = instr(s, "?");
  if (idx >= 0)
    s = left(s, idx);
  if (s == "")
    return;

  preset.Ravager = instr(s, "1") >= 0;
  preset.Raven = instr(s, "2") >= 0;
  preset.Bullcraft = instr(s, "3") >= 0;
  preset.Violator = instr(s, "4") >= 0;
  preset.Falcon = instr(s, "5") >= 0;
  preset.Stingray = instr(s, "6") >= 0;
  preset.Dragoneer = instr(s, "7") >= 0;
  preset.Cerberus = instr(s, "8") >= 0;
  preset.Hellraiser = instr(s, "9") >= 0;
  preset.AllowWeaponPickups = instr(s, "P", false, true) >= 0;
  preset.InfiniteAmmo = instr(s, "A", false, true) >= 0;
  preset.RandomWeapon = instr(s, "R", false, true) >= 0;
}

function InitWeapons()
{
  if (preset.Ravager)
    weapons.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_Impactor", class'Class')));
  if (preset.Raven)
    weapons.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_PistolAW29", class'Class')));
  if (preset.Bullcraft)
    weapons.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_ShotgunSG12", class'Class')));
  if (preset.Violator)
    weapons.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_PulseRifle", class'Class')));
  if (preset.Falcon)
    weapons.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_SniperRifle", class'Class')));
  if (preset.Stingray)
    weapons.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_ScionRifle", class'Class')));
  if (preset.Dragoneer)
    weapons.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_FlameThrower", class'Class')));
  if (preset.Cerberus)
    weapons.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_RocketLauncher", class'Class')));
  if (preset.Hellraiser)
    weapons.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_Hellraiser", class'Class')));
}

function SetDefaultInventory()
{
  local UTGame Game;
  local int i;

  Game = UTGame(WorldInfo.Game);
  if (Game == None) return;

  Game.DefaultInventory.Length = 0;

  if (preset.RandomWeapon)
    Game.DefaultInventory.AddItem(weapons[rand(weapons.Length)]);
  else
  {
    for (i=0; i<weapons.Length; i++)
      Game.DefaultInventory.AddItem(weapons[i]);  
  }
}

function bool CheckReplacement(Actor Other)
{
  local UTPawn pawn;

  // toxikk doesn't derive from UTAmmoPickupFactory, so check for it the dirty way
  if (InfiniteAmmo && Other.IsA('UTItemPickupFactory') && instr(string(Other.class), "CRZAmmo_") == 0)
    return false;

  if (!preset.AllowWeaponPickups && (Other.IsA('UTWeaponPickupFactory') || Other.IsA('UTWeaponLocker')))
    return false;

  if (preset.RandomWeapon)
  {
    pawn = UTPawn(Other);
    if (pawn != None)
      SetDefaultInventory();
  }

  return super.CheckReplacement(Other);
}

simulated function Tick(float DeltaTime)
{
  local UTWeapon w;

  if (InfiniteAmmo)
  {
    foreach WorldInfo.DynamicActors(class'UTWeapon', w)
    {
      w.ShotCost[0] = 0;
      w.ShotCost[1] = 0;
    }
  }
}

static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
  local CRZMutator_LoadoutPreset pres;

  super.PopulateConfigView(ConfigView, MutatorDataProvider);

  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_Loadout');

  pres = new(none, "Preset1") class'CRZMutator_LoadoutPreset';
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Infinite Ammo", "Never running out of ammo", pres.InfiniteAmmo, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Weapon Pickups", "Allow regular weapon pickups", pres.AllowWeaponPickups, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Random Gun", "Spawn with a random gun from the enabled ones below", pres.RandomWeapon, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Ravager", "Melee drill and welding tool", pres.Ravager, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Raven", "Pistol", pres.Raven, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Bullcraft", "Double barell shotgun", pres.Bullcraft, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Violator", "Assault rifle and grenade launcher", pres.Violator, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Falcon", "Sniper rifle", pres.Falcon, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Stingray", "Plasma balls and engery beam", pres.Stingray, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Dragoneer", "Flame thrower", pres.Dragoneer, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Cerberus", "Rocket launcher", pres.Cerberus, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Hellraiser", "Remote controlled nuke missile", pres.Hellraiser, OnCheckboxClick);
}

static function OnCheckboxClick(string label, bool value, GFxClikWidget.EventData ev)
{
  local CRZMutator_LoadoutPreset pres;

  pres = new(none, "Preset1") class'CRZMutator_LoadoutPreset';

  switch(label)
  {
    case "Infinite Ammo": pres.InfiniteAmmo = value; break;
    case "Random Gun": pres.RandomWeapon = value; break;
    case "Weapon Pickups": pres.AllowWeaponPickups = value; break;
    case "Ravager": pres.Ravager = value; break;
    case "Raven": pres.Raven = value; break;
    case "Bullcraft": pres.Bullcraft = value; break;
    case "Violator": pres.Violator = value; break;
    case "Falcon": pres.Falcon = value; break;
    case "Stingray": pres.Stingray = value; break;
    case "Dragoneer": pres.Dragoneer = value; break;
    case "Cerberus": pres.Cerberus = value; break;
    case "Hellraiser": pres.Hellraiser = value; break;
  }

  pres.SaveConfig();
}



defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true
  GroupNames[0]="WEAPONMOD"
  GroupNames[1]="WEAPONRESPAWN"
}
