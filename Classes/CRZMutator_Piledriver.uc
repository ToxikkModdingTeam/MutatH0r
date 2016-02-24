class CRZMutator_Piledriver extends Mutator;

const StompDepth = 25.0;
const DeathDepth = 35.0;
const ExcavateDelay = 1.0;
const ExcavateSpeed = 20.0; // = StompDepth / 1.75sec

struct StompInfo
{
  var CRZPawn pawn;
  var float time;
  var vector location;
  var float deltaZ;
};

var array<StompInfo> Stomped;

function InitMutator(string options, out string errorMessage)
{
  SetTickGroup(TG_PostAsyncWork);
  Enable('Tick');
}

function NetDamage(int originalDamage, out int damage, Pawn injured, Controller instigatedBy, Vector hitLocation, out Vector momentum, class<DamageType> damageType, Actor damageCauser)
{
  super.NetDamage(originalDamage, damage, injured, instigatedBy, hitLocation, momentum, damageType, damageCauser);

  if (damageType == class'DmgType_Crushed' && instigatedBy != None && instigatedBy.Pawn != None)
  {
    damage = 1;
    if (injured.Physics == PHYS_Walking)
    {
      // if you stomp someone deep enough into the ground, you deal 300 dmg
      if (Stomp(CRZPawn(injured)))
        damage = 300;
    }
    else if (injured.Physics == PHYS_Falling)
    {
      // if you can jump onto someone mid-air, you deal 300 damage
      damage = 300;
    }
  }
}

function bool Stomp(CRZPawn injured)
{
  local vector loc;
  local int i;

  if (injured == None)
    return false;

  loc = injured.Location;

  for (i=0; i<Stomped.Length; i++)
  {
    if (Stomped[i].pawn == injured)
    {
      if (Stomped[i].time + 0.2 >= WorldInfo.TimeSeconds)
        return false;
      break;
    }
  }
  if (i == Stomped.Length)
  {
    Stomped.Add(1);
    Stomped[i].pawn = injured;
  }
  Stomped[i].time = WorldInfo.TimeSeconds;
  if (Stomped[i].deltaZ == 0)
    Stomped[i].location = loc;
  Stomped[i].deltaZ += StompDepth;

  
  loc.Z -= StompDepth;
  injured.CylinderComponent.SetCylinderSize(injured.CylinderComponent.CollisionRadius, injured.CylinderComponent.CollisionHeight - StompDepth);
  injured.SetLocation(loc);
  injured.BaseTranslationOffset -= StompDepth;
  injured.MovementSpeedModifier = 0;
  injured.Acceleration = vect(0,0,0);
  injured.Velocity = vect(0,0,0);
  injured.bCanCrouch = false;
  injured.bJumpCapable = false;
  return Stomped[i].deltaZ >= DeathDepth;
}

function Tick(float deltaTime)
{
  local int i;
  local StompInfo info;
  local float adj, time;
  local vector loc;

  time = WorldInfo.TimeSeconds;
  for (i=0; i<Stomped.Length; i++)
  {
    info = Stomped[i];
    if (info.deltaZ == 0 || info.pawn == None || !info.pawn.IsAliveAndWell())
    {
      Stomped.Remove(i, 1);
      --i;
      continue;
    }

    adj = ((time < info.time + ExcavateDelay) ? 0.0 : FMin(time - info.time - ExcavateDelay, deltaTime)) * ExcavateSpeed;
    adj = FMin(adj, info.deltaZ);
    Stomped[i].deltaZ -= adj;
    loc = info.location;
    loc.Z -= Stomped[i].deltaZ;
    info.pawn.SetLocation(loc);
    info.pawn.BaseTranslationOffset += adj;
    info.pawn.CylinderComponent.SetCylinderSize(info.pawn.CylinderComponent.CollisionRadius, info.pawn.CylinderComponent.CollisionHeight + adj);
    if (Stomped[i].deltaZ == 0)
    {
      info.pawn.MovementSpeedModifier = 1.0;
      info.pawn.bCanCrouch = true;
      info.pawn.bJumpCapable = true;
    }
  }
}


DefaultProperties
{
}
