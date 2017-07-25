class CRZMutator_ItemSpawn extends CRZMutator config(MutatH0r);

var config bool bRavager;
var config bool bRaven;
var config bool bBullcraft;
var config bool bViolator;
var config bool bFalcon;
var config bool bStingray;
var config bool bDragoneer;
var config bool bCerberus;
var config bool bHellraiser;
var config bool bAmmo;
var config bool bDroppedWeapon;

var config bool bArmorShard;
var config bool bSmallArmor;
var config bool bMegaArmor;

var config bool bHealthVial;
var config bool bHealthPack;
var config bool bMegaHealth;
var config bool bDroppedHealth;

var config bool bJetPack;
var config bool bMaxDamage;
var config bool bSpeedShot;

var config bool bStreamer;
var config bool bRhino;
var config bool bBanshee;
var config bool bPhantom;
var config bool bDemon;

var array<DroppedPickup> deferedCheckReplacement;

function InitMutator(string options, out string error)
{
  local UTGame game;

  super.InitMutator(options, error);

  game = UTGame(WorldInfo.Game);
  if (!bRavager) game.DefaultInventory.RemoveItem(class'CRZWeap_Impactor');
  if (!bRaven) game.DefaultInventory.RemoveItem(class'CRZWeap_PistolAW29');

  if (!bDroppedWeapon)
  {
    SetTickGroup(TG_PostAsyncWork);
    Enable('Tick');
  }
}

function bool CheckReplacement(Actor Other)
{
  local UTPickupFactory F;
  local CRZWeaponPickupFactory wf;
  local CRZAmmoPickupFactory apf;
  local DroppedPickup dp; 
  local CRZVehicleFactory vf;

  wf = CRZWeaponPickupFactory(other);
  if (wf != none)
    return CheckWeapon(wf.WeaponPickupClass);

  apf = CRZAmmoPickupFactory(other);
  if (apf != none)
    return bAmmo && CheckWeapon(apf.TargetWeapon);

  if (CRZDropped_HealthPack(other) != none)
    return bDroppedHealth;

  dp = DroppedPickup(other);
  if (dp != none && !bDroppedWeapon)
  {
    // when this method executes, the DroppedPickup.InventoryClass and .Inventory are not set yet, so we defer the check to the end of the Tick
    deferedCheckReplacement.AddItem(dp);
    return true;
  }

  F = UTPickupFactory(Other);
  if (F != none)
  {
    if (F.IsA('CRZPickupFactory_HealthVial')) return bHealthVial;
    if (F.IsA('CRZPickupFactory_HealthPack')) return bHealthPack;
    if (F.IsA('CRZPickupFactory_SuperHealth')) return bMegaHealth;
    if (F.IsA('CRZArmorPickup_ArmorPack')) return bArmorShard;
    if (F.IsA('CRZArmorPickup_ShieldVestBig')) return bMegaArmor;
    if (F.IsA('CRZArmorPickup_ShieldVest')) return bSmallArmor;
    if (F.IsA('CRZPickupFactory_JetPack')) return bJetPack;
    if (F.IsA('CRZPickupFactory_Steroids')) return bMaxDamage; 
    if (F.IsA('CRZPickupFactory_Adrenaline')) return bSpeedShot;
    return true;
  }

  VF = CRZVehicleFactory(other);
  if (VF != none)
  {
    if (VF.IsA('CRZVehicleFactory_Streamer')) return bStreamer;
    if (VF.IsA('CRZVehicleFactory_Rhino')) return bRhino;
    if (VF.IsA('CRZVehicleFactory_Banshee')) return bBanshee;
    if (VF.IsA('CRZVehicleFactory_Phantom')) return bPhantom;
    if (VF.IsA('CRZVehicleFactory_Demon')) return bDemon;
    return true;
  }

  return true;
}

function bool CheckWeapon(class<UTWeapon> weaponClass)
{
  if (weaponClass == class'CRZWeap_Impactor') return bRavager;
  if (weaponClass == class'CRZWeap_PistolAW29') return bRaven;
  if (weaponClass == class'CRZWeap_ShotgunSG12') return bBullcraft;
  if (weaponClass == class'CRZWeap_PulseRifle') return bViolator;
  if (weaponClass == class'CRZWeap_SniperRifle') return bFalcon;
  if (weaponClass == class'CRZWeap_ScionRifle') return bStingray;
  if (weaponClass == class'CRZWeap_FlameThrower') return bDragoneer;
  if (weaponClass == class'CRZWeap_RocketLauncher') return bCerberus;
  if (weaponClass == class'CRZWeap_Hellraiser') return bHellraiser;
  return true;
}

function Tick(float deltaTime)
{
  local int i;
  local DroppedPickup dp;

  for (i=0; i<deferedCheckReplacement.length; i++)
  {
    dp = deferedCheckReplacement[i];
    if (class<UTWeapon>(dp.InventoryClass) != none)
      dp.Destroy();
  }
  deferedCheckReplacement.length = 0;
}

static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
  super.PopulateConfigView(ConfigView, MutatorDataProvider);

  ConfigView.SetMaskBounds(ConfigView.ListObject1, 400, 975, true);
  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_ItemSpawn');
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Ravager", "Allow Ravager Spawn", default.bRavager, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Raven", "Allow Raven Spawn", default.bRaven, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Bullcraft", "Allow Bullcraft Spawn", default.bBullcraft, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Violator", "Allow Violator Spawn", default.bViolator, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Falcon", "Allow Falcon Spawn", default.bFalcon, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Stingray", "Allow Stingray Spawn", default.bStingray, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Dragoneer", "Allow Dragoneer Spawn", default.bDragoneer, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Cerberus", "Allow Cerberus Spawn", default.bCerberus, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Hellraiser", "Allow Hellraiser Spawn", default.bHellraiser, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Dropped Weapon", "Weapons dropped manually or upon death", default.bDroppedWeapon, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Ammo", "Allow Ammo Spawn", default.bAmmo, OnCheckboxClick);

  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Dropped Health", "Health packs dropped upon death", default.bDroppedHealth, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Health Vial", "Allow Health Vial Spawn", default.bHealthVial, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Health Pack", "Allow Health Pack Spawn", default.bHealthPack, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Mega Health", "Allow Mega Health Spawn", default.bMegaHealth, OnCheckboxClick);

  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Armor Shard", "Allow Armor Shard Spawn", default.bArmorShard, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Small Armor", "Allow Small Armor Spawn", default.bSmallArmor, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Mega Armor", "Allow Mega Armor Spawn", default.bMegaArmor, OnCheckboxClick);

  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "JetPack", "Allow JetPack Spawn", default.bJetPack, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "MaxDamage", "Allow MaxDamage Spawn", default.bMaxDamage, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "SpeedShot", "Allow SpeedShot Spawn", default.bSpeedShot, OnCheckboxClick);

  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Streamer", "Allow Streamer Spawn", default.bStreamer, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Rhino", "Allow Rhino Spawn", default.bRhino, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Banshee", "Allow Banshee Spawn", default.bBanshee, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Phantom", "Allow Phantom Spawn", default.bPhantom, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Demon", "Allow Demon Spawn", default.bDemon, OnCheckboxClick);
}

static function OnCheckboxClick(string label, bool value, GFxClikWidget.EventData ev)
{
  switch(label)
  {
    case "Ravager": default.bRavager = value; break;
    case "Raven": default.bRaven = value; break;
    case "Bullcraft": default.bBullcraft = value; break;
    case "Violator": default.bViolator = value; break;
    case "Falcon": default.bFalcon = value; break;
    case "Stingray": default.bStingray = value; break;
    case "Dragoneer": default.bDragoneer = value; break;
    case "Cerberus": default.bCerberus = value; break;
    case "Hellraiser": default.bHellraiser = value; break;
    case "Ammo": default.bAmmo = value; break;
    case "Dropped Weapon": default.bDroppedWeapon = value; break;
    case "Dropped Health": default.bDroppedHealth = value; break;
    case "Health Vial": default.bHealthVial = value; break;
    case "Health Pack": default.bHealthPack = value; break;
    case "Mega Health": default.bMegaHealth = value; break;
    case "Armor Shard": default.bArmorShard = value; break;
    case "Small Armor": default.bSmallArmor = value; break;
    case "Mega Armor": default.bMegaArmor = value; break;
    case "JetPack": default.bJetPack = value; break;
    case "MaxDamage": default.bMaxDamage = value; break;
    case "SpeedShot": default.bSpeedShot = value; break;
    case "Streamer": default.bStreamer = value; break;
    case "Rhino": default.bRhino = value; break;
    case "Banshee": default.bBanshee = value; break;
    case "Phantom": default.bPhantom = value; break;
    case "Demon": default.bDemon = value; break;
  }

  StaticSaveConfig();
}

defaultproperties
{
//  GroupNames[0]="WEAPONRESPAWN"
  bAllowMXPSave=true
  bAllowSCSave=false
  bRequiresDownloadOnClient=false
}
