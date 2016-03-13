class CRZMutator_Motd extends Mutator config (MutatH0r);

var config Array<string> WelcomeHeader;
var config Array<string> WelcomeMessage;
var string WelcomeHeaderString;
var string WelcomeMessageString;

//replication
//{
//  if (Role == ROLE_Authority && (bNetDirty || bNetInitial))
//    WelcomeMessage;
//}

simulated function PostBeginPlay()
{
  local PlayerController pc;

  super.PostBeginPlay();

  pc = GetALocalPlayerController();
  if (pc != None)
    ShowWelcomeMessage(pc);
}

function NotifyLogin(Controller newPlayer)
{
  local PlayerController pc;

  super.NotifyLogin(newPlayer);

  pc = PlayerController(newPlayer);
  if (pc != None)
    ShowWelcomeMessage(pc); // bootcamp
}

simulated function ShowWelcomeMessage(PlayerController pc)
{
  WelcomeHeaderString = ArrayToString(WelcomeHeader);
  WelcomeMessageString = ArrayToString(WelcomeMessage);
  class'MotdInteraction'.static.Create(self, pc, true);
}

simulated function string ArrayToString(Array<string> arr)
{
  local int i;
  local string str;

  str = "";
  for (i=0; i<arr.Length; i++)
  {
    if (i > 0)
      str = str $ "\n";
    str = str $ arr[i];
  }
  return str;
}

DefaultProperties
{
  bAlwaysRelevant = true;
  RemoteRole = ROLE_SimulatedProxy;
}
