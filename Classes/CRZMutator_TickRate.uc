// MutatH0r.CRZMutator_TickRate
// ----------------
// Measures the server's ticks/second and displays it in a client canvas
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_TickRate extends UTMutator;

var float serverTime;
var int serverTickCount;
var int TickRate;

replication
{
  if ((bNetInitial || bNetDirty) && Role == ROLE_Authority)
    TickRate;
}

simulated function PostBeginPlay()
{
  super.PostBeginPlay();

  if (WorldInfo.NetMode == NM_Client) // only a client has a local player controller when PostBeginPlay is called
    CreateInteraction(GetALocalPlayerController());
}

function NotifyLogin(Controller newPlayer)
{
  super.NotifyLogin(newPlayer);

  // for dedicated server, listen server and bootcamp
  CreateInteraction(PlayerController(newPlayer));
}

simulated function CreateInteraction(PlayerController pc)
{
  if (pc == none || !pc.IsLocalPlayerController())
    return;  
  class'TickRateInteraction'.static.Create(self, pc, true);
}

function Tick(float DeltaTime)
{
  local float delta;

  if (serverTime == 0)
    serverTime = WorldInfo.RealTimeSeconds;
  else
  {
    ++serverTickCount;
    delta = WorldInfo.RealTimeSeconds - serverTime;
    if (delta >= 1)
    {
      TickRate = int(float(serverTickCount) / delta + 0.5);
      serverTime = WorldInfo.RealTimeSeconds;
      serverTickCount = 0;
    }
  }
}


defaultproperties
{
  bAlwaysRelevant = true;
  RemoteRole = ROLE_SimulatedProxy;
}