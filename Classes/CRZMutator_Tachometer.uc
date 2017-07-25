class CRZMutator_Tachometer extends CRZMutator;

simulated function PostBeginPlay()
{
  super.PostBeginPlay();

  if (WorldInfo.NetMode == NM_Client) // only a client has a local player controller when PostBeginPlay is called
    CreateInteraction(GetALocalPlayerController());
}

function NotifyLogin(Controller newPlayer)
{
  super.NotifyLogin(newPlayer);

  // for dedicated server, listen server and bootcamp
  CreateInteraction(PlayerController(newPlayer));
}

simulated function CreateInteraction(PlayerController pc)
{
  if (pc == none || !pc.IsLocalPlayerController())
    return;  
  class'TachometerInteraction'.static.Create(self, pc, true);
}

DefaultProperties
{
  bAlwaysRelevant = true;
  RemoteRole = ROLE_SimulatedProxy;
  bAllowMXPSave=true
  bAllowSCSave=true
  bRequiresDownloadOnClient=true
}
