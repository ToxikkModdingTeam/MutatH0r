// CRZMutator_SaveShaderCache
// ----------------
// Hack to save shader caches to speed up map load time
//================================================================

class CRZMutator_SaveShaderCache extends UTMutator;

function InitMutator(string Options, out string ErrorMessage)
{
  super.InitMutator(Options, ErrorMessage);
  WorldInfo.Game.ConsoleCommand("SAVESHADERS");  
}
