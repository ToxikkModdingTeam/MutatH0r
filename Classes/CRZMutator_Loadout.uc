// This mutators allows players to spawn with a set of specified weapons or a random weapon from a specified set
// It also has a working implementation of "Infinite Ammo"
// UTInvManager.bInfiniteAmmo only resets the ammo count back to MaxValue when it goes below 0, which prevents shots that need more than 1 ammo
// this implementation changes the ShotCost to 0, which shows up as INF in the ammo HUD and avoids any ammo issues
//
// URL-Options:
//   ?Loadout=123456789RPA 
//      "1"-"9" defines which weapons are in the loadout (1=Ravager, ... 9=Hellraiser) 
//      "R" will give you a random weapon from the loadout instead of all
//      "P" allows regular weapon pickups (with "P" they are removed from the map)
//      "A" gives infinite ammo
//   ?LoadoutPreset=presetname
//      loads config settings from [presetname CRZMutator_LoadoutPreset]

class CRZMutator_Loadout extends CRZMutator config(MutatH0r);

const OPT_LoadoutPreset = "LoadoutPreset";
const OPT_Loadout = "Loadout";

var CRZMutator_LoadoutPreset preset;
var array<class<Weapon> > weapons;
var bool InfiniteAmmo;
var string RandomPresets;
var array<Pawn> newPawns, prevNewPawns;

replication
{
  if (Role == ROLE_Authority && (bNetInitial || bNetDirty))
    InfiniteAmmo;
}

simulated function PostBeginPlay()
{
  super.PostBeginPlay();

  // on the server we can change the ShotCost during CheckReplacement.
  // on the client we can only change the ShotCost through Tick after the weapon has been created
  if (Role != ROLE_Authority && InfiniteAmmo)
  {
    SetTickGroup(ETickingGroup.TG_PreAsyncWork);
    Enable('Tick');
  }
}

function InitMutator(string options, out string error)
{
  local string presetId;
  local string s;
  
  super.InitMutator(options, error);

  s = class'GameInfo'.static.ParseOption(options, OPT_Loadout);
  if (s != "")
  {
    preset = new() class'CRZMutator_LoadoutPreset';
    ApplyOptionOverrides(s);
  }
  else
  {
    // extract preset name from ?LoadoutPreset=... parameter
    presetId = class'GameInfo'.static.ParseOption(options, OPT_LoadoutPreset);
    if (presetId == "")
      presetId = "Preset1";
    preset = new(none, presetId) class'CRZMutator_LoadoutPreset';
    RandomPresets = preset.RandomPresets;
  }

  InfiniteAmmo = preset.InfiniteAmmo;

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

  if (preset.RandomWeapon || RandomPresets != "")
    WorldInfo.bNoDefaultInventoryForPlayer = true;
  else
    SetDefaultInventory();
}

function ApplyOptionOverrides(string s)
{
  local int i;
  local string c;

  if (instr(s, "L") >= 0)
  {
    RandomPresets = "";
    for (i=0; i<len(s); i++)
    {
      c=mid(s, i, 1);
      if (c >= "1" && c <= "9")
        RandomPresets = RandomPresets $ c;
    }
    if (RandomPresets == "")
      RandomPresets="234";
    return;
  }

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
  weapons.Length = 0;
  if (preset.Ravager)
    weapons.AddItem(class'Cruzade.CRZWeap_Impactor');
  if (preset.Raven)
    weapons.AddItem(class'Cruzade.CRZWeap_PistolAW29');
  if (preset.Bullcraft)
    weapons.AddItem(class'Cruzade.CRZWeap_ShotgunSG12');
  if (preset.Violator)
    weapons.AddItem(class'Cruzade.CRZWeap_PulseRifle');
  if (preset.Falcon)
    weapons.AddItem(class'Cruzade.CRZWeap_SniperRifle');
  if (preset.Stingray)
    weapons.AddItem(class'Cruzade.CRZWeap_ScionRifle');
  if (preset.Dragoneer)
    weapons.AddItem(class'Cruzade.CRZWeap_FlameThrower');
  if (preset.Cerberus)
    weapons.AddItem(class'Cruzade.CRZWeap_RocketLauncher');
  if (preset.Hellraiser)
    weapons.AddItem(class'Cruzade.CRZWeap_Hellraiser');
}

function SetDefaultInventory()
{
  local UTGame Game;
  local int i;

  Game = UTGame(WorldInfo.Game);
  if (Game == None) return;

  Game.DefaultInventory.Length = 0;

  for (i=0; i<weapons.Length; i++)
    Game.DefaultInventory.AddItem(weapons[i]);  
}

function bool CheckReplacement(Actor Other)
{
  local UTWeapon weap;

  // toxikk doesn't derive from UTAmmoPickupFactory, so check for it the dirty way
  if (InfiniteAmmo && (Other.IsA('CRZAmmoPickupFactory') || Other.IsA('UTAmmoPickupFactory')))
    return false;

  // toxikk doesn't derive from UTWeaponPickupFactory
  if (!preset.AllowWeaponPickups && (Other.IsA('CRZWeaponPickupFactory') || Other.IsA('UTWeaponPickupFactory') || Other.IsA('UTWeaponLocker')))
    return false;

  if (InfiniteAmmo)
  {
    // infinite ammo handling for server
    weap = UTWeapon(other);
    if (weap != none)
    {
      weap.ShotCost[0]=0;
      weap.ShotCost[1]=0;
    }
  }

  return super.CheckReplacement(Other);
}

function ModifyPlayer(Pawn p)
{
  local int i;
  local class<Weapon> w;

  if (RandomPresets != "") // load a random preset
  {
    i = rand(len(RandomPresets));
    preset = new(none, "Preset" $ mid(RandomPresets, i, 1)) class'CRZMutator_LoadoutPreset';
    InitWeapons();
    for (i=0; i<weapons.length; i++)
      p.CreateInventory(weapons[i], true);
    p.CreateInventory(class'LoadoutInv', false); // it's client side PostBeginPlay is used to select the best weapon in the inventory
  }
  else if (preset.RandomWeapon)
  {
    w = weapons[rand(weapons.Length)];
    p.CreateInventory(w, false);
    p.CreateInventory(class'LoadoutInv', false); // it's client side PostBeginPlay is used to select the best weapon in the inventory
  }

  super.ModifyPlayer(p);
}

simulated function Tick(float DeltaTime)
{
  local UTWeapon w;
  
  if (InfiniteAmmo)
  {
    // infinite ammo handling for client
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

  pres = new(none, "Preset1") class'CRZMutator_LoadoutPreset';
  ConfigView.SetMaskBounds(ConfigView.ListObject1, 400, 975, true);
  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_Loadout');
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Random Preset", "Picks one of the predefined loadouts randomly", pres.RandomPresets != "", OnCheckboxClick);
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
    case "Random Preset": pres.RandomPresets = value ? "234" : ""; break;
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
}
