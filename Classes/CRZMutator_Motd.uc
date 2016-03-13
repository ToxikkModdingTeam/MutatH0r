class CRZMutator_Motd extends Mutator config (MutatH0r);

var config Array<string> WelcomeHeader;
var config Array<string> WelcomeMessage;
var repnotify string WelcomeHeaderString;
var repnotify string WelcomeMessageStrings[40];
var string WelcomeMessageString;

replication
{
  if (Role == ROLE_Authority && (bNetDirty || bNetInitial))
    WelcomeHeaderString, WelcomeMessageStrings;
}

simulated function PostBeginPlay()
{
  local string s;
  local int i;
  super.PostBeginPlay();

  if (Role == ROLE_Authority)
  {
    JoinArray(WelcomeHeader, WelcomeHeaderString, "\n", false);
    JoinArray(WelcomeMessage, WelcomeMessageString, "\n", false);
    s = WelcomeMessageString;
    while (len(s) > 250)
    {
      WelcomeMessageStrings[i++] = left(s, 250);
      s = mid(s, 250);
    }
    WelcomeMessageStrings[i++] = s;
  }
}

function NotifyLogin(Controller newPlayer)
{
  super.NotifyLogin(newPlayer);
  ShowWelcomeMessage(PlayerController(newPlayer));
}

simulated function ShowWelcomeMessage(PlayerController pc)
{
  if (pc == none || !pc.IsLocalPlayerController())
    return;  
  class'MotdInteraction'.static.Create(self, pc, true);
}

simulated function ReplicatedEvent(name varName)
{
  local int i;

  // override the client's local .ini values with the server's strings
  if (varName == 'WelcomeHeaderString')
    ParseStringIntoArray(WelcomeHeaderString, WelcomeHeader, "\n", false);
  else if (varName == 'WelcomeMessageStrings')
  {
    WelcomeMessageString = "";
    for (i=0; i<ArrayCount(WelcomeMessageStrings); i++)
      WelcomeMessageString = WelcomeMessageString $ WelcomeMessageStrings[i];
    ParseStringIntoArray(WelcomeMessageString, WelcomeMessage, "\n", false);
  }

  ShowWelcomeMessage(GetALocalPlayerController());
}

DefaultProperties
{
  bAlwaysRelevant = true;
  RemoteRole = ROLE_SimulatedProxy;
}
