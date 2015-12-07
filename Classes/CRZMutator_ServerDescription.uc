// MutatH0r.CRZMutator_ServerDescription
// ----------------
// updates the server description from the options URL "?ServerDescription=..." value, 
// so it can be changed through the map/mutator voting system
//
// by PredatH0r
//================================================================

class CRZMutator_ServerDescription extends UTMutator config (MutatH0r);

`include(UTGame\Classes\UTOnlineConstants.uci)

const OPT_ServerDescription = "?ServerDescription=";
var string _options;

function InitMutator(string options, out string error)
{
  super.InitMutator(options, error);

  _options = options;
  // at the time InitMutator is executed, WorldInfo.Game.GameInterface isn't initialized yet, so we need to delay our work
  SetTimer(1.0, false, 'SetServerName');
}

function SetServerName()
{
  local int idx;
  local string serverDescription, blob;
  local OnlineGameInterface gameInterface;
  local OnlineGameSettings gameSettings;

  idx = instr(_options, OPT_ServerDescription, false, true);
  if (idx < 0)
    return;
  
  serverDescription = mid(_options, idx + len(OPT_ServerDescription));
  idx = instr(serverDescription, "?");
  if (idx >= 0)
    serverDescription = left(serverDescription, idx);

  if (len(serverDescription) == 0)
    return;
  
  gameInterface = self.WorldInfo.Game.GameInterface;
  if (gameInterface == None)
    return;

  gameSettings = gameInterface.GetGameSettings(self.WorldInfo.Game.PlayerReplicationInfoClass.default.SessionName);
  if (gameSettings == None)
    return;
  
  // TODO: there might be some other special chars to handle. ":" breaks map travelling
  serverDescription = repl(repl(serverDescription, "_", " "), ":", ";"); 
  gameSettings.SetStringProperty(PROPERTY_SERVERDESCRIPTION, serverDescription);
}

