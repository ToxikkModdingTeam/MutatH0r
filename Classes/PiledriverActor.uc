class PiledriverActor extends Actor;

const StompDepth = 30.0;
const DeathDepth = 35.0;
const ExcavateDelay = 2;
const ExcavateSpeed = 20.0; // = StompDepth / 1.5sec

struct StompInfo
{
  var UTPawn pawn;
  var float time;
  var vector location;
  var float deltaZ;
};

var array<StompInfo> Stomped;

simulated function PostBeginPlay()
{
  SetTickGroup(TG_PostAsyncWork);
  Enable('Tick');
}

reliable client function NotifyStomped(Pawn pawn)
{
  Stomp(UTPawn(pawn));
}

simulated function bool Stomp(UTPawn injured)
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
  injured.StopFiring();
  injured.bNoWeaponFiring = true;
  return Stomped[i].deltaZ >= DeathDepth;
}

simulated function Tick(float deltaTime)
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
      info.pawn.bNoWeaponFiring = false;
    }
  }
}


DefaultProperties
{
  RemoteRole = ROLE_SimulatedProxy;
  bOnlyRelevantToOwner = true
  bOnlyDirtyReplication = true
  bReplicateMovement = false
  bHidden = true
  CollisionType = COLLIDE_CustomDefault
}
