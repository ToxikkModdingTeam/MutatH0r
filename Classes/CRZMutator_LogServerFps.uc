// MutatH0r.CRZMutator_LogServerFps
// ----------------
// Measures and logs the servers ticks/second
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_LogServerFps extends UTMutator;

var float serverTime;
var int serverTickCount;

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
      `log("ticks/sec: " $ (float(serverTickCount) / delta));
      serverTime = WorldInfo.RealTimeSeconds;
      serverTickCount = 0;
    }
  }
}
