class CRZMutator_Piledriver extends CRZMutator config(MutatH0r);

struct ClientActor
{
  var Controller c;
  var PiledriverActor actor;
};

var config int StompDamage;  // damage dealt when landing on a player's head
var config bool DisableWeapon;  // a player stomped in the ground can't fire his weapon
var config bool StompIntoGround; // whether the player should be stomped below the floor surface
var array<ClientActor> clientActors;

function InitMutator(string options, out string error)
{
  local ClientActor ca;

  super.InitMutator(options, error);

  ca.c = None;
  ca.actor = Spawn(class'PiledriverActor', None);
  clientActors.AddItem(ca);
}

function NotifyLogin(Controller c)
{
  local ClientActor ca;

  super.NotifyLogin(c);

  if (!c.IsLocalController())
  {
    ca.c = c;
    ca.actor =  Spawn(class'PiledriverActor', c);
    clientActors.AddItem(ca);
  }
}

function NotifyLogout(Controller c)
{
  local int i;

  super.NotifyLogout(c);

  for (i=0; i<clientActors.Length; i++)
  {
    if (clientActors[i].c == c)
    {
      clientActors.Remove(i, 1);
      break;
    }
  }
}

function NetDamage(int originalDamage, out int damage, Pawn injured, Controller instigatedBy, Vector hitLocation, out Vector momentum, class<DamageType> damageType, Actor damageCauser)
{
  local int i;

  super.NetDamage(originalDamage, damage, injured, instigatedBy, hitLocation, momentum, damageType, damageCauser);

  if (damageType == class'DmgType_Crushed' && instigatedBy != None && instigatedBy.Pawn != None)
  {
    damage = 1;
    if (injured.Physics == PHYS_Walking)
    {
      if (StompIntoGround)
      {
        // if you stomp someone deep enough into the ground, you deal 300 dmg
        for (i=1; i<clientActors.Length; i++)
          clientActors[i].actor.NotifyStomped(injured, DisableWeapon);
        if (clientActors[0].actor.Stomp(UTPawn(injured), DisableWeapon))
          damage = StompDamage;
      }
      else
        damage = StompDamage;
    }
    else if (injured.Physics == PHYS_Falling)
    {
      // if you can jump onto someone mid-air, you deal 300 damage
      damage = StompDamage;
    }
  }
}


static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
  super.PopulateConfigView(ConfigView, MutatorDataProvider);
  
  ConfigView.SetMaskBounds(ConfigView.ListObject1, 400, 975, true);
  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_Piledriver');
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Ram Into Ground", "Ram a player into the ground when you land on his head", default.StompIntoGround, OnCheckboxClick);
  class'MutConfigHelper'.static.AddCheckBox(ConfigView, "Disable Weapon", "Disable a player's weapon when stuck in the ground", default.DisableWeapon, OnCheckboxClick);
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Damage", "Damage dealt when landing on a (stuck) player's head", 0, 400, 10, default.StompDamage, OnSliderChanged);
}

static function OnCheckboxClick(string label, bool value, GFxClikWidget.EventData ev)
{
  if (label == "Ram Into Ground")
    default.StompIntoGround = value;
  else if (label == "Disable Weapon")
    default.DisableWeapon = value;
  StaticSaveConfig();
}

function static OnSliderChanged(string label, float value, GFxClikWidget.EventData ev)
{
  default.StompDamage = value;
  StaticSaveConfig();
}

defaultproperties
{
  bAllowMXPSave=true
  bAllowSCSave=false
  bRequiresDownloadOnClient=true
}