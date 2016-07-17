class CRZMutator_Piledriver extends CRZMutator config(MutatH0r);

struct ClientActor
{
  var Controller c;
  var PiledriverActor actor;
};

var config int StompDamage;
var config bool DisableWeapon;
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
      // if you stomp someone deep enough into the ground, you deal 300 dmg
      for (i=1; i<clientActors.Length; i++)
        clientActors[i].actor.NotifyStomped(injured, DisableWeapon);
      if (clientActors[0].actor.Stomp(UTPawn(injured), DisableWeapon))
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
  local GfxClikWidget checkBox;
  local CRZSliderWidget slider; 

  super.PopulateConfigView(ConfigView, MutatorDataProvider);
  
  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_Piledriver');
 
  checkBox = GfxClikWidget(ConfigView.AddItem( ConfigView.ListObject1, "CheckBox", "Disable Weapon", "Disable a player's weapon when stomped in the ground"));
  checkBox.SetBool("selected", default.DisableWeapon);	
  checkBox.AddEventListener('CLIK_click', OnDisableWeaponClick);

  slider = ConfigView.AddSlider(ConfigView.ListObject1, "CRZSlider", "Stomp Damage", "Damage dealt when jumping on a stomped player's head");
  slider.SetFloat("minimum", 0.0);
  slider.SetFloat("maximum", 400.0);
  slider.SetFloat("smallSnap", 10);
  slider.SetInt("value", default.StompDamage);
  slider.AddEventListener('CLIK_change', OnStompDamageChanged);
}

static function OnDisableWeaponClick(GFxClikWidget.EventData ev)
{
  default.DisableWeapon = ev.target.GetBool("selected");
  StaticSaveConfig();
}

function static OnStompDamageChanged(GFxClikWidget.EventData ev)
{
  if (class'MutConfigHelper'.static.IgnoreChange(class'CRZMutator_Piledriver', 'StompDamage'))
    return;
  default.StompDamage = ev.target.GetInt("value");
  StaticSaveConfig();
}
