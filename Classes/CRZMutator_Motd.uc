class CRZMutator_Motd extends Mutator config (MutatH0r);

/*
 * replicating long strings from server to client requires a bit of a hack:
 *- server .ini settings are dynamic string arrays, which can't be replicated directly
 * - WelcomeMessageString can be too long to be replicated, so it's chunked into a static string array with strings <= 250 chars
 * 
 * In bootcamp and on listen servers there is no replication for the local player, so ShowWelcomeMessage is called from PostBeginPlay
 * That function is only executed server-side, so for remote clients we call ShowWelcomeMessage from ReplicatedEvent after the server message was received
 */

var config repnotify string WelcomeHeader;  
var config Array<string> WelcomeMessage;
var string WelcomeMessageString;
var private repnotify string WelcomeMessageChunks[40];

replication
{
  if (Role == ROLE_Authority && (bNetDirty || bNetInitial))
    WelcomeHeader, WelcomeMessageChunks;
}

simulated function PostBeginPlay()
{
  local string s;
  local int i;
  super.PostBeginPlay();

  if (Role == ROLE_Authority)
  {
    JoinArray(WelcomeMessage, WelcomeMessageString, "\n", false);

    // slice the WelcomeMessageString into smaller strings that can be replicated
    s = WelcomeMessageString;
    while (len(s) > 250)
    {
      WelcomeMessageChunks[i++] = left(s, 250);
      s = mid(s, 250);
    }
    WelcomeMessageChunks[i++] = s;
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

  // recombine chunks into WelcomeMessageString and split it into lines
  if (varName == 'WelcomeMessageChunks')
  {
    WelcomeMessageString = "";
    for (i=0; i<ArrayCount(WelcomeMessageChunks); i++)
      WelcomeMessageString = WelcomeMessageString $ WelcomeMessageChunks[i];
    ParseStringIntoArray(WelcomeMessageString, WelcomeMessage, "\n", false);
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
