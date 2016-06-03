// MutatH0r.CRZMutator_TickRate
// ----------------
// Measures the server's ticks/second and displays it in a client canvas
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_TickRate extends UTMutator config (MutatH0r);

// NOTE: WorldInfo.RealTimeSeconds is a float and loses precision when the map is running for an expanded period of time
// After some hours a servers starts to show 64 instead of 60ticks using the float, so we use a more accurate method now.
var int prevDate;
var int prevTime;
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
  local int y, mon, d, wd, h, min, s, ms;
  local int date, time;
  local int delta;

  if (!ready)
    return;

  GetSystemTime(y,mon,d,wd,h,min,s,ms);
  date = y*10000 + mon*100 + d;
  time = h*3600000 + min*60000 + s*1000 + ms;

  if (date != prevDate)
  {
    // initial call or when the clocks wraps from 23:59:59.999 to 00:00:00.000
    prevDate = date;
    prevTime = time;
    serverTickCount = 0;
  }
  else
  {
    ++serverTickCount;
    delta = time - prevTime;
    if (delta >= 995) // 5ms margin for finishing a tick too early
    {
      TickRate = serverTickCount;
      prevTime = time;
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