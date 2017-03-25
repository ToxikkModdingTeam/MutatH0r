class DmgPlumeActor extends Actor dependson(CRZMutator_DmgPlume) config(MutatH0r);

/*
 * The Mutator spawns a DmgPlumeActor for every CRZPlayerController to allow RPC calls in both directions.
 * 
 * The server sends damage plume information to the client and notifications when players start/end typing.
 * It also tells the client to play a sound after a kill.
 * 
 * On a client the Actor may or may not have a local .ini file with configuration of the damage numbers, kill sound and chat icon.
 * The client notifies the server whether it wants to receive damage plumes and the player starts/ends typing.
 *  
 */

struct TypingInfo
{
  var int PlayerId;
  var bool bTyping;
};

struct ResourceInfo
{
  var string Label;
  var string Uri;
};

// server side

var CRZMutator_DmgPlume Mut;

// client side

var config string DmgPlumeConfig;
var config bool bDisableChatIcon;
var config array<ResourceInfo> PlumeFonts;
var config array<ResourceInfo> KillSounds;
var config string KillSound;
var config float KillSoundVolume;

var bool waitingForOwner;

var DmgPlumeInteraction PlumeInteraction;
var SoundCue KillSoundCue;

var bool isTyping; // last status of whether the owning player was typing (or had console open)
var array<TypingInfo> typingPlayers; // players known to be typing



simulated function PostBeginPlay()
{
  super.PostBeginPlay(); 

  waitingForOwner = true;
  SetTickGroup(TG_PostAsyncWork);
  Enable('Tick');
}

simulated function InitAfterReceivingOwner()
{
  // ignore server-side actors for remote players
  if (!PlayerController(Owner).IsLocalPlayerController())
  {
    Disable('Tick');
    return;
  }

  // kill sound
  if (KillSound == "") // no local .ini file
    KillSound = "$$$";
  SetKillSound(KillSound, false);

  // HUD for chat icon
  AddToHUD();
}

simulated event Tick(float deltaTime)
{
  if (Owner == None)
    return;

  if (waitingForOwner)
  {
    InitAfterReceivingOwner();
    waitingForOwner = false;
    return;
  }

  UpdateTypingStatus();

  if (deltaTime < 0) // yep, quite often has -1
    return;
}

simulated function AddToHUD()
{
  local CRZPlayerController PC;
 
  PC = CRZPlayerController(Owner);
  if (CRZHud(PC.myHud) != None)
    PlumeInteraction = class'DmgPlumeInteraction'.static.Create(self, PC, true);
}


//==================================================
// play sound when a player kills an opponent
//==================================================

simulated static function SoundCue GetKillSound(string label)
{
  local int i;
  local SoundNodeWave wave;
  local SoundCue cue;

  for (i=0; i<default.KillSounds.Length; i++)
  {
    if (default.KillSounds[i].Label ~= label)
    {
      if (default.KillSounds[i].Uri == "")
        return none;
      wave = SoundNodeWave(class'WorldInfo'.static.GetWorldInfo().DynamicLoadObject(default.KillSounds[i].Uri, class'SoundNodeWave'));
      if (wave == none)
        return none;
      cue = new class'SoundCue';
      cue.FirstNode = wave;
      cue.VolumeMultiplier = 0.25 * default.KillSoundVolume;
      return cue;
    }
  }
  return none;
}

simulated function bool SetKillSound(string label, optional bool saveIni = true)
{
  local SoundCue cue;

  if (label ~= "off")
    cue = none;
  else
  {
    cue = GetKillsound(label);
    if (cue == none)
      return false;
    cue.VolumeMultiplier = 0.75 * KillSoundVolume;
  }

  KillSoundCue = cue;
  KillSound = label;
  if (saveIni)
     self.SaveConfig();
  return true;
}

unreliable client function PlayKillSound()
{
  if (KillSoundCue != none)
    PlumeInteraction.PC.ClientPlaySound(KillSoundCue);
}


//==================================================
// overhead icon when player is in console / typing
//==================================================

simulated function UpdateTypingStatus()
{
  local LocalPlayer lp;
  local bool typing;
  local name stateName;
  local PlayerController pc;

  foreach WorldInfo.LocalPlayerControllers(class'PlayerController', pc)
  {
    lp = LocalPlayer(PC.Player);
    if (lp != None && lp.ViewportClient != none && lp.ViewportClient.ViewportConsole != none)
    {
      stateName = lp.ViewportClient.ViewportConsole.GetStateName();
      typing = stateName == 'Open' || stateName == 'Typing';
      if (typing != self.isTyping)
      {
        self.isTyping = typing;
        ServerSetTyping(typing);
      }
    }
  }
}

reliable server function ServerSetTyping(bool typing)
{
  local int i;
  local int playerId;
  local CRZPlayerController c;

  playerId = CRZPlayerController(self.Owner).PlayerReplicationInfo.PlayerID;
  foreach WorldInfo.AllControllers(class'CRZPlayerController', c)
  {
    if (c == self.Owner)
      continue;
    i = Mut.GetOrAddPlumeReceiver(c);
    Mut.PlumeReceivers[i].Actor.ClientNotifyIsTyping(playerId, typing);
  }
}


reliable client function ClientNotifyIsTyping(int playerId, bool typing)
{
  local int i;

  for (i=0; i<typingPlayers.Length; i++)
  {
    if (typingPlayers[i].PlayerId == playerId)
      break;
  }
  if (i == typingPlayers.Length)
  {
    typingPlayers.Add(1);
    typingPlayers[i].PlayerId = playerId;
  }
  typingPlayers[i].bTyping = typing;
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
