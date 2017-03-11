// MutatH0r.CRZMutator_ServerDescription
// ----------------
// * updates the server description from the options URL "?ServerDescription=..." value, 
//   so it can be changed through the map/mutator voting system. supports $xx to escape hex chars
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

  // testing
  //`log("URL-Decode: (empty): " $ UrlDecode(""));
  //`log("URL-Decode: a:" $ UrlDecode("a"));
  //`log("URL-Decode: ab:" $ UrlDecode("ab"));
  //`log("URL-Decode: abc:" $ UrlDecode("abc"));
  //`log("URL-Decode: ?:" $ UrlDecode("$3F"));
  //`log("URL-Decode: x?y:" $ UrlDecode("x$3Fy"));
  //`log("URL-Decode: $a:" $ UrlDecode("$a")); // invalid encoding
}

function UpdateGameSettings()
{
  local OnlineGameInterface gameInterface;
  local OnlineGameSettings gameSettings;
     
  gameInterface = self.WorldInfo.Game.GameInterface;
  if (gameInterface == None)
    return;

  gameSettings = gameInterface.GetGameSettings(self.WorldInfo.Game.PlayerReplicationInfoClass.default.SessionName);
  if (gameSettings == None)
    return;
  
  UpdateServerDescription(gameSettings);
  UpdateMutatorList(gameSettings);

  gameInterface.UpdateOnlineGame(self.WorldInfo.Game.PlayerReplicationInfoClass.default.SessionName, gameSettings);
}

function UpdateServerDescription(OnlineGameSettings gameSettings)
{
  local string serverDescription;

  serverDescription = class'GameInfo'.static.ParseOption(_options, OPT_ServerDescription);
  if (serverDescription == "")
    return;

  // Some special chars cannot be used in the description, because they break the URL parsing and map travelling
  // There is nothing this mutator can do about it, because parsing already happenes before the mut is initialized
  // Known to cause issues : / # & %
  // To allow special characters, spaces can be encoded as _ and other chars using URL-encoding as % followed by 2 hex digits
  serverDescription = repl(serverDescription, "_", " ");
  serverDescription = UrlDecode(serverDescription);

  gameSettings.SetStringProperty(PROPERTY_SERVERDESCRIPTION, serverDescription);
}

function string UrlDecode(string encoded)
{
  local int i, d1, d2;
  local string c, decoded;

  for (i=0; i<len(encoded)-2; i++)
  {
    c = mid(encoded, i, 1);
    if (c == "$")
    {
      d1 = instr("0123456789ABCDEF", caps(mid(encoded, i+1, 1)));
      d2 = instr("0123456789ABCDEF", caps(mid(encoded, i+2, 1)));
      if (d1 >= 0 && d2 >= 0)
      {
        decoded = decoded $ chr(d1*16 + d2);
        i += 2;
        continue;
      }
    }
    decoded = decoded $ c;
  }
  return decoded $ mid(encoded, i);
}

function UpdateMutatorList(OnlineGameSettings gameSettings)
{
  local string sep, muts, mutClassName;
  local Mutator mut;
  local CRZUIDataProvider_Mutator mutInfo;
  local Object obj;

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
}
