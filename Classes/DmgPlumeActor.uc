class DmgPlumeActor extends Actor dependson(CRZMutator_DmgPlume);

struct PlumeSpriteInfo
{
  var vector Location;
  var int Value;
  var float Age;
  var float SpeedX;
  var float SpeedY;
};

var DmgPlumeInteraction PlumeInteraction;
var array<PlumeSpriteInfo> Plumes;

simulated function PostBeginPlay()
{
  super.PostBeginPlay();

  if ( WorldInfo.NetMode != NM_DedicatedServer)
  {
    AddToHUD();
    SetTickGroup(TG_PostAsyncWork);
    Enable('Tick');
  }
  else
    Disable('Tick');
}

simulated function AddToHUD()
{
  local PlayerController PC;
 
  foreach LocalPlayerControllers(class'PlayerController', PC)
  {
    if (CRZHudWrapper(PC.myHud) != None)
    {
      PlumeInteraction = class'DmgPlumeInteraction'.static.Create(self, PC, true);
      ClearTimer('AddToHUD');
      break;
    }
  }
}

simulated event Tick(float deltaTime)
{
  local int i;

  if (WorldInfo.NetMode == NM_DedicatedServer || Owner == None)
  {
    Disable('Tick');
    return;
  }

  if (deltaTime < 0) // yep, quite often has -1
    return;
  for (i=0; i<Plumes.Length; i++)
  {
    Plumes[i].Age += deltaTime;
    if (Plumes[i].Age > class'DmgPlumeInteraction'.default.TimeToLive)
    {
      Plumes.Remove(i, 1);
      --i;
    }
  }
}

unreliable client function AddPlumes(PlumeRepInfo repInfo)
{
  local int i;
  local PlumeSpriteInfo plume;

  for (i=0; i<ArrayCount(repInfo.Plumes); i++)
  {
    if (repInfo.Plumes[i].Value == 0)
      break;

    plume.Location = repInfo.Plumes[i].Location;
    plume.Value = repInfo.Plumes[i].value;
    plume.SpeedX = (frand() < 0.5 ? -1 : 1) * (frand() * 20 + 60);
    plume.SpeedY = frand()*40+80;
    Plumes.AddItem(plume);
  }
}


DefaultProperties
{
  RemoteRole=ROLE_SimulatedProxy
  bOnlyRelevantToOwner = true
  bOnlyDirtyReplication = true
  bReplicateMovement = false
  bHidden = true
  CollisionType = COLLIDE_CustomDefault
}
