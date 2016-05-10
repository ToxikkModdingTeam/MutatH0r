class CRZMutator_Motd extends Mutator config (MutatH0r);

/*
 * replicating long strings from server to client requires a bit of a hack:
 * - server .ini settings are dynamic string arrays, which can't be replicated directly
 * - ServerWelcomeMessageString can be too long to be replicated, so it's chunked into a static string array with strings <= 250 chars
 * 
 * In bootcamp and on listen servers there is no replication for the local player, so ShowWelcomeMessage is called from InitMutator
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

function InitMutator(string options, out string error)
{
  local string presetName;
  local array<string> lines;
  local MotdConfig preset;

  super.InitMutator(options, error);

  ServerWelcomeHeader = WelcomeHeader;
  SetServerWelcomeMessage(lines, WelcomeMessage);

  presetName = class 'Utils'.static.GetOption(options, "motd");
  if (presetName != "")
    preset = new(none, presetName) class'MotdConfig';
 
  if (preset != none)
  {
    if (preset.WelcomeHeader != "")
      ServerWelcomeHeader = preset.WelcomeHeader;    
    SetServerWelcomeMessage(preset.WelcomeMessage, WelcomeMessage);
  }

  if (WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_Standalone)
    ShowWelcomeMessage(GetALocalPlayerController());
}


function SetServerWelcomeMessage(array<string> lines1, array<string> lines2)
{
  local int i, j, maxLines;
  local string text1, text2;

  JoinArray(lines1, text1, "\n", false);
  JoinArray(lines2, text2, "\n", false);
  ServerWelcomeMessageString = text1 $ text2;

  maxLines = ArrayCount(ServerWelcomeMessageLines) - 1;
  for (i=0; i<lines1.Length && i<maxLines; i++)
    ServerWelcomeMessageLines[i] = lines1[i];
  j=i;
  for (i=0; i<lines2.Length && i<maxLines; i++)
    ServerWelcomeMessageLines[j+i] = lines2[i];
  ServerWelcomeMessageLines[j+i] = EndMarker;
}

function NotifyLogin(Controller newPlayer)
{
  super.NotifyLogin(newPlayer);
  ShowWelcomeMessage(PlayerController(newPlayer));
}

simulated function ReplicatedEvent(name varName)
{
  local int i;

  // combine lines into a ServerWelcomeMessageString
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
