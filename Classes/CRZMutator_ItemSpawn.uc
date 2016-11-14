class CRZMutator_ItemSpawn extends CRZMutator config(MutatH0r);

var config bool bBullcraft;
var config bool bViolator;
var config bool bFalcon;
var config bool bStingray;
var config bool bDragoneer;
var config bool bCerberus;
var config bool bHellraiser;

var config bool bMegaHealth;
var config bool bMegaArmor;

var config bool bMaxDamage;
var config bool bSpeedShot;

function bool CheckReplacement(Actor Other)
{
	local UTPickupFactory F;
  local CRZWeaponPickupFactory wf;
  local CRZArmorPickupFactory af;

	wf = CRZWeaponPickupFactory(other);
  if (wf != none)
  {
    if (wf.WeaponPickupClass == class'CRZWeap_ShotgunSG12') return bBullcraft;
    if (wf.WeaponPickupClass == class'CRZWeap_PulseRifle') return bViolator;
    if (wf.WeaponPickupClass == class'CRZWeap_SniperRifle') return bFalcon;
    if (wf.WeaponPickupClass == class'CRZWeap_ScionRifle') return bStingray;
    if (wf.WeaponPickupClass == class'CRZWeap_FlameThrower') return bDragoneer;
    if (wf.WeaponPickupClass == class'CRZWeap_RocketLauncher') return bCerberus;
    if (wf.WeaponPickupClass == class'CRZWeap_Hellraiser') return bHellraiser;
    return true;
  }

  af = CRZArmorPickupFactory(other);
  if (af != none)
  {
    if (af.ShieldAmount == 100) return bMegaArmor;
    return true;
  }

	F = UTPickupFactory(Other);
	if (F != none)
	{
	  if (F.IsA('CRZPickupFactory_Steroids')) return bMaxDamage; 
	  if (F.IsA('CRZPickupFactory_Adrenaline')) return bSpeedShot;
    if (F.IsA('CRZPickupFactory_SuperHealth')) return bMegaHealth;
	  return true;
	}

  return true;
}


static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
  super.PopulateConfigView(ConfigView, MutatorDataProvider);

  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_ItemSpawn');

  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Bullcraft", "Allow Bullcraft Spawn", default.bBullcraft, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Violator", "Allow Violator Spawn", default.bViolator, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Falcon", "Allow Falcon Spawn", default.bFalcon, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Stingray", "Allow Stingray Spawn", default.bStingray, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Dragoneer", "Allow Dragoneer Spawn", default.bDragoneer, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Cerberus", "Allow Cerberus Spawn", default.bCerberus, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Hellraiser", "Allow Hellraiser Spawn", default.bHellraiser, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Mega Health", "Allow Mega Health Spawn", default.bMegaHealth, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Mega Armor", "Allow Mega Armor Spawn", default.bMegaArmor, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "MaxDamage", "Allow MaxDamage Spawn", default.bMaxDamage, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "SpeedShot", "Allow SpeedShot Spawn", default.bSpeedShot, OnCheckboxClick);
}

static function OnCheckboxClick(string label, bool value, GFxClikWidget.EventData ev)
{
  switch(label)
  {
    case "Bullcraft": default.bBullcraft = value; break;
    case "Violator": default.bViolator = value; break;
    case "Falcon": default.bFalcon = value; break;
    case "Stingray": default.bStingray = value; break;
    case "Dragoneer": default.bDragoneer = value; break;
    case "Cerberus": default.bCerberus = value; break;
    case "Hellraiser": default.bHellraiser = value; break;
    case "Mega Health": default.bMegaHealth = value; break;
    case "Mega Armor": default.bMegaArmor = value; break;
    case "MaxDamage": default.bMaxDamage = value; break;
    case "SpeedShot": default.bSpeedShot = value; break;
  }

  StaticSaveConfig();
}

defaultproperties
{
	GroupNames[0]="POWERUPS"
}
