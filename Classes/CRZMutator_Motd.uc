class CRZMutator_Motd extends Mutator config (MutatH0r);

/*
 * replicating long strings from server to client requires a bit of a hack:
 *- server .ini settings are dynamic string arrays, which can't be replicated directly
 * - ServerWelcomeMessageString can be too long to be replicated, so it's chunked into a static string array with strings <= 250 chars
 * 
 * In bootcamp and on listen servers there is no replication for the local player, so ShowWelcomeMessage is called from PostBeginPlay
 * That function is only executed server-side, so for remote clients we call ShowWelcomeMessage from ReplicatedEvent after the server message was received
 */

var private config string WelcomeHeader;  
var private config Array<string> WelcomeMessage;

var repnotify string ServerWelcomeHeader;
var repnotify string ServerWelcomeMessageLines[51];
var string ServerWelcomeMessageString;
const EndMarker = "---end-of-list---";

replication
{
  if (Role == ROLE_Authority && (bNetDirty || bNetInitial))
    ServerWelcomeHeader, ServerWelcomeMessageLines;
}

simulated function PostBeginPlay()
{
  local int i, c;
  super.PostBeginPlay();

  if (Role == ROLE_Authority)
  {
    ServerWelcomeHeader = WelcomeHeader;

    JoinArray(WelcomeMessage, ServerWelcomeMessageString, "\n", false);

    c = ArrayCount(ServerWelcomeMessageLines) - 1;
    for (i=0; i<WelcomeMessage.Length && i<c; i++)
      ServerWelcomeMessageLines[i] = WelcomeMessage[i];
    ServerWelcomeMessageLines[i] = EndMarker;
  }
}

function NotifyLogin(Controller newPlayer)
{
  super.NotifyLogin(newPlayer);
  ShowWelcomeMessage(PlayerController(newPlayer));
}

simulated function ReplicatedEvent(name varName)
{
  local int i;

  // combine lines into 
  if (varName == 'ServerWelcomeMessageLines')
  {
    ServerWelcomeMessageString = "";
    for (i=0; i<ArrayCount(ServerWelcomeMessageLines); i++)
    {
      if (ServerWelcomeMessageLines[i] == EndMarker)
        break;
      if (i > 0)
        ServerWelcomeMessageString $= "\n";
      ServerWelcomeMessageString $= ServerWelcomeMessageLines[i];
    }
  }

  ShowWelcomeMessage(GetALocalPlayerController());
}

simulated function ShowWelcomeMessage(PlayerController pc)
{
  if (pc == none || !pc.IsLocalPlayerController())
    return;  
  class'MotdInteraction'.static.Create(self, pc, true);
}

DefaultProperties
{
  bAlwaysRelevant = true;
  RemoteRole = ROLE_SimulatedProxy;
}
