// MutatH0r.CRZMutator_TickRate
// ----------------
// Measures the server's ticks/second and displays it in a client canvas
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_TickRate extends UTMutator config (MutatH0r);

var float serverTime;
var int serverTickCount;
var int TickRate;

var config bool LogCurrentTicks;
var config bool LogSummaryTicks;
var int tickCount[61];
var bool ready;
var bool prevMatchIsOver;

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
  ready = true;
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

  if (!ready)
    return;

  if (serverTime == 0)
    serverTime = WorldInfo.RealTimeSeconds;
  else
  {
    ++serverTickCount;
    delta = WorldInfo.RealTimeSeconds - serverTime;
    if (delta >= 1)
    {
      TickRate = int(float(serverTickCount) / delta + 0.499);
      serverTime = WorldInfo.RealTimeSeconds;
      serverTickCount = 0;
      ++tickCount[clamp(TickRate,0,60)];

      // write ticks to server log, if enabled via config
      if (LogCurrentTicks)
        `Log("Ticks: " $ TickRate);
    }
  }

  // write map summary stats to server log
  if (WorldInfo.GRI.bMatchIsOver != prevMatchIsOver && WorldInfo.GRI.bMatchIsOver)
    LogSummary();
  prevMatchIsOver = WorldInfo.GRI.bMatchIsOver;
}

function LogSummary()
{
  local int i;

  if (LogSummaryTicks)
  {
    for (i=0; i<ArrayCount(tickCount); i++)
    {
      `Log("Tick count " $ i $ ": " $ tickCount[i]);
      tickCount[i]=0;
    }
  }
}

defaultproperties
{
  bAlwaysRelevant = true;
  RemoteRole = ROLE_SimulatedProxy;
}