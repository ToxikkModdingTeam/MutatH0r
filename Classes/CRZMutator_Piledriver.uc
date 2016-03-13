class CRZMutator_Piledriver extends Mutator;


struct ClientActor
{
  var Controller c;
  var PiledriverActor actor;
};

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
        clientActors[i].actor.NotifyStomped(injured);
      if (clientActors[0].actor.Stomp(UTPawn(injured)))
        damage = 300;
    }
    else if (injured.Physics == PHYS_Falling)
    {
      // if you can jump onto someone mid-air, you deal 300 damage
      damage = 300;
    }
  }
}

