class DmgPlumeActor extends Actor dependson(CRZMutator_DmgPlume) config(MutatH0r);

struct PlumeSpriteInfo
{
  var vector Location;
  var int Value;
  var float Age;
  var float SpeedX;
  var float SpeedY;
};

var config string DmgPlumeConfig;

var DmgPlumeConfig Settings;
var DmgPlumeInteraction PlumeInteraction;
var array<PlumeSpriteInfo> Plumes;

simulated function PostBeginPlay()
{
  super.PostBeginPlay();

  if (DmgPlumeConfig == "")
    DmgPlumeConfig = "small";
  if (!LoadPreset(DmgPlumeConfig))
  {
    // when the mutator was auto-downloaded from a server, then there is no local .ini to initialize the settings, so we set up some defaults
    Settings = new class'DmgPlumeConfig';
    Settings.SetDefaults(DmgPlumeConfig);   
  }
  if (!Settings.bEnablePlumes)
    return;

  if (WorldInfo.NetMode != NM_DedicatedServer)
  {
    AddToHUD();
    SetTickGroup(TG_PostAsyncWork);
    Enable('Tick');
  }
  else
    Disable('Tick');
}

simulated function bool LoadPreset(string preset)
{
  local DmgPlumeConfig cfg;

  preset = Locs(preset);
  cfg = new(none, preset) class'DmgPlumeConfig';
  if (cfg == None || cfg.PlumeColors.Length == 0)
    return false;

  Settings = cfg;
  DmgPlumeConfig = preset;
  self.SaveConfig();
  return true;
}

simulated function AddToHUD()
{
  local PlayerController PC;
 
  foreach LocalPlayerControllers(class'PlayerController', PC)
  {
    if (CRZHudWrapper(PC.myHud) != None)
    {
      PlumeInteraction = class'DmgPlumeInteraction'.static.Create(self, PC, true);
      ClearTimer('AddToHUD');
      break;
    }
  }
}

simulated event Tick(float deltaTime)
{
  local int i;

  if (WorldInfo.NetMode == NM_DedicatedServer || Owner == None)
  {
    Disable('Tick');
    return;
  }

  if (!Settings.bEnablePlumes)
    return;

  if (deltaTime < 0) // yep, quite often has -1
    return;
  for (i=0; i<Plumes.Length; i++)
  {
    Plumes[i].Age += deltaTime;
    if (Plumes[i].Age > Settings.TimeToLive)
    {
      Plumes.Remove(i, 1);
      --i;
    }
  }
}

unreliable client function AddPlumes(PlumeRepInfo repInfo)
{
  local int i;
  local PlumeSpriteInfo plume;

  if (!Settings.bEnablePlumes)
    return;

  for (i=0; i<ArrayCount(repInfo.Plumes); i++)
  {
    if (repInfo.Plumes[i].Value == 0)
      break;

    plume.Location = repInfo.Plumes[i].Location;
    plume.Value = repInfo.Plumes[i].value;
    plume.SpeedX = (frand() < 0.5 ? -1 : 1) * (frand() * Settings.SpeedX.Random + Settings.SpeedX.Fixed);
    plume.SpeedY = frand()*Settings.SpeedY.Random + Settings.SpeedY.Fixed;
    Plumes.AddItem(plume);
  }
}


DefaultProperties
{
  RemoteRole=ROLE_SimulatedProxy
  bOnlyRelevantToOwner = true
  bOnlyDirtyReplication = true
  bReplicateMovement = false
  bHidden = true
  CollisionType = COLLIDE_CustomDefault
}
