class CRZMutator_Piledriver extends Mutator;

const StompDepth = 25.0;
const DeathDepth = 35.0;
const ExcavateDelay = 3.0;
const ExcavateTime = 1.5;

struct StompInfo
{
  var CRZPawn pawn;
  var float time;
  var float deltaZ;
};

var array<StompInfo> LastStomped;

function InitMutator(string options, out string errorMessage)
{
  SetTickGroup(TG_PreAsyncWork);
  Enable('Tick');
}

function Mutate(string cmd, PlayerController sender)
{
  if (cmd == "pile")
    Stomp(CRZPawn(sender.Pawn));
  else
    super.Mutate(cmd, sender);
}

function NetDamage(int originalDamage, out int damage, Pawn injured, Controller instigatedBy, Vector hitLocation, out Vector momentum, class<DamageType> damageType, Actor damageCauser)
{
  super.NetDamage(originalDamage, damage, injured, instigatedBy, hitLocation, momentum, damageType, damageCauser);

  if (damageType == class'DmgType_Crushed' && instigatedBy != None && instigatedBy.Pawn != None)
  {
    damage = 1;
    if (injured.Physics == PHYS_Walking)
    {
      if (Stomp(CRZPawn(injured)))
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

  for (i=0; i<LastStomped.Length; i++)
  {
    if (LastStomped[i].pawn == injured)
    {
      if (LastStomped[i].time + 0.2 >= WorldInfo.TimeSeconds)
        return false;
      break;
    }
  }
  if (i == LastStomped.Length)
  {
    LastStomped.Add(1);
    LastStomped[i].pawn = injured;
  }
  LastStomped[i].time = WorldInfo.TimeSeconds;
  LastStomped[i].deltaZ += StompDepth;

  loc = injured.Location;
  loc.Z += StompDepth;
  injured.SetLocation(loc);
  injured.BaseTranslationOffset -= StompDepth;
  injured.CylinderComponent.SetCylinderSize(injured.CylinderComponent.CollisionRadius, injured.CylinderComponent.CollisionHeight - StompDepth);
  injured.MovementSpeedModifier = 0;
  return LastStomped[i].deltaZ >= DeathDepth;
}

function Tick(float deltaTime)
{
  local int i;
  local StompInfo info;
  local float time, adj;

  time = WorldInfo.TimeSeconds;
  for (i=0; i<LastStomped.Length; i++)
  {
    info = LastStomped[i];
    if (info.deltaZ == 0 || time-info.time < ExcavateDelay)
      continue;
    adj = info.deltaZ - (1 - FMin(time - info.time - ExcavateDelay, ExcavateTime)/ExcavateTime) * StompDepth;
    info.pawn.SetLocation(info.pawn.Location - vect(0,0,1) * adj);
    info.pawn.BaseTranslationOffset += adj;
    info.pawn.CylinderComponent.SetCylinderSize(info.pawn.CylinderComponent.CollisionRadius, info.pawn.CylinderComponent.CollisionHeight + adj);
    LastStomped[i].deltaZ -= adj;
    if (LastStomped[i].deltaZ < 0.0001)
      info.pawn.MovementSpeedModifier = 1.0;
  }
}


DefaultProperties
{
}
