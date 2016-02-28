class DmgPlumeActor extends Actor dependson(CRZMutator_DmgPlume) config(MutatH0r);

struct PlumeSpriteInfo
{
  var vector Location;
  var int Value;
  var float Age;
  var float SpeedX;
  var float SpeedY;
};

struct TypingInfo
{
  var int PlayerId;
  var bool bTyping;
};

var config string DmgPlumeConfig;
var config bool bDisablePlumes;
var config bool bDisableCrosshairNames;
var config bool bDisableChatIcon;

var CRZMutator_DmgPlume Mut;
var DmgPlumeConfig Settings;
var DmgPlumeInteraction PlumeInteraction;
var array<PlumeSpriteInfo> Plumes;

var bool isTyping;
var array<TypingInfo> areTyping;

simulated function PostBeginPlay()
{
  super.PostBeginPlay();

  if (DmgPlumeConfig == "")
    DmgPlumeConfig = "small";
  if (!LoadPreset(DmgPlumeConfig))
    LoadPreset("small");

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
  {
    // when the mutator was auto-downloaded from a server, then there is no local .ini to initialize the settings, so we set up some defaults
    cfg = new class'DmgPlumeConfig';
    if (!cfg.SetDefaults(preset))
      return false;
  }

  Settings = cfg;
  DmgPlumeConfig = preset;
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

  UpdateTypingStatus();

  if (bDisablePlumes)
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

  if (bDisablePlumes)
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


simulated function UpdateTypingStatus()
{
  local LocalPlayer lp;
  local bool typing;
  local name stateName;

  if (PlumeInteraction == None)
    return;
  lp = LocalPlayer(PlumeInteraction.PC.Player);
  if (lp != None && lp.ViewportClient != none && lp.ViewportClient.ViewportConsole != none)
  {
    stateName = lp.ViewportClient.ViewportConsole.GetStateName();
    typing = stateName == 'Open' || stateName == 'Typing';
    if (typing != self.isTyping)
    {
      self.isTyping = typing;
      SetTyping(PlumeInteraction.PC.PlayerReplicationInfo.PlayerID, typing);
    }
  }
}

reliable server function SetTyping(int playerId, bool typing)
{
  local int i;
  for (i=0; i<Mut.PlumeReceivers.Length; i++)
  {
    if (Mut.PlumeReceivers[i].Controller != self.Owner)
    {
      Mut.PlumeReceivers[i].Actor.NotifyIsTyping(playerId, typing);
    }
  }
}


reliable client function NotifyIsTyping(int playerId, bool typing)
{
  local int i;
  for (i=0; i<areTyping.Length; i++)
  {
    if (areTyping[i].PlayerId == playerId)
      break;
  }
  if (i == areTyping.Length)
  {
    areTyping.Add(1);
    areTyping[i].PlayerId = playerId;
  }
  areTyping[i].bTyping = typing;
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
