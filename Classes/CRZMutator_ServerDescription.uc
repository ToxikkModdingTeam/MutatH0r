// MutatH0r.CRZMutator_ServerDescription
// ----------------
// * updates the server description from the options URL "?ServerDescription=..." value, 
//   so it can be changed through the map/mutator voting system
// * updates the announced mutator names (they are stuck to the server startup muts)
//
// by PredatH0r
//================================================================

class CRZMutator_ServerDescription extends UTMutator config (MutatH0r);

`include(UTGame\Classes\UTOnlineConstants.uci)

const OPT_ServerDescription = "ServerDescription";
var string _options;

function InitMutator(string options, out string error)
{
  super.InitMutator(options, error);

  _options = options;
  // at the time InitMutator is executed, WorldInfo.Game.GameInterface isn't initialized yet, so we need to delay our work
  SetTimer(1.0, false, 'UpdateGameSettings');
}

function UpdateGameSettings()
{
  local string serverDescription, sep, muts;
  local OnlineGameInterface gameInterface;
  local OnlineGameSettings gameSettings;
  local Mutator mut;
  local CRZUIDataProvider_Mutator mutInfo;
  local Object obj;
  local string mutClassName;

  serverDescription = class'GameInfo'.static.ParseOption(_options, OPT_ServerDescription);
  if (serverDescription == "")
    return;
    
  gameInterface = self.WorldInfo.Game.GameInterface;
  if (gameInterface == None)
    return;

  gameSettings = gameInterface.GetGameSettings(self.WorldInfo.Game.PlayerReplicationInfoClass.default.SessionName);
  if (gameSettings == None)
    return;
  
  // Some special chars cannot be used in the description, because they break the URL parsing and map travelling
  // There is nothing this mutator can do about it, because parsing already happenes before the mut is initialized
  // Known to cause issues : / # &
  serverDescription = repl(serverDescription, "_", " "); 
  if (serverDescription != "")
    gameSettings.SetStringProperty(PROPERTY_SERVERDESCRIPTION, serverDescription);

  // update mutator list (currently stuck at whatever muts were active when the server launched)
  sep = "";
  for (mut = self.WorldInfo.Game.BaseMutator; mut != none; mut = mut.NextMutator)
  {
    // get full package.class name of mutator
    mutClassName = string(mut.class.Name);
    for (obj = mut.class.outer; obj != none && obj.outer != none; obj = obj.outer)
    {
    }
    mutClassName = string(obj) $ "." $ mutClassName;

    mutInfo = class 'Cruzade.CRZUIDataProvider_Mutator'.static.GetDataProvider_MutatorByClassName(mutClassName);
    if (mutInfo != none)
    {
      muts = muts $ sep $ mutInfo.FriendlyName;
      sep = chr(0x1C);
    }
    //else
    //  `log("No mutator info for " $ mutClassName);
  }
  gameSettings.SetStringProperty(1073741828, muts);

  // force update
  gameInterface.UpdateOnlineGame(self.WorldInfo.Game.PlayerReplicationInfoClass.default.SessionName, gameSettings);
}

