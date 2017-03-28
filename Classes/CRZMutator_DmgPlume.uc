class CRZMutator_DmgPlume extends CRZMutator config (MutatH0r);


struct PlumeReceiver
{
  var CRZPlayerController Controller;
  var DmgPlumeActor Actor;
};


// server
var array<PlumeReceiver> PlumeReceivers;

// labels for the config controls, also used to identify value changes
const LBL_DamageNumbers = "Damage Numbers";
const LBL_Font = "  Font";
const LBL_Scale = "  Scale (1/16)";
const LBL_Time = "  Time (1/4sec)";
const LBL_HSpeed = "  Horiz. Speed";
const LBL_HSpread = "  Horiz. Spread";
const LBL_VSpeed = "  Vert. Speed";
const LBL_VSpread = "  Vert. Spread";
const LBL_KillSound = "Kill Sound";
const LBL_KillSoundVolume = "Kill Sound Vol.";

function bool HasPovOfAttacker(CRZPlayerController player, Controller attacker)
{
  return player.RealViewTarget == none ? (player == attacker) : (player.RealViewTarget == attacker.PlayerReplicationInfo);
}


function int GetOrAddPlumeReceiver(CRZPlayerController C)
{
  local int i;

  if (C == none)
    return -1;

  // find or create plume receiver
  for (i=0; i<PlumeReceivers.Length; i++)
  {
    if (PlumeReceivers[i].Controller == C)
      return i;
  }

  PlumeReceivers.Add(1);
  PlumeReceivers[i].Controller = C;
  PlumeReceivers[i].Actor = Spawn(class'DmgPlumeActor', C);
  PlumeReceivers[i].Actor.Mut = self;
  return i;
}

function NotifyLogin(Controller C)
{
  local CRZPlayerController pc;

  super.NotifyLogin(C);

  // DmgPlumeActor must be instantiated on the client to know if he is typing status
  pc = CRZPlayerController(C);
  if (pc != None)
    GetOrAddPlumeReceiver(pc);
}

function NotifyLogout(Controller C)
{
  local int i, j, playerId;

  if (CRZPlayerController(C) != None)
  {
    for (i=0; i<PlumeReceivers.Length; i++)
    {
      if (PlumeReceivers[i].Controller == C)
      { 
        // tell all clients that the player isn't typing anymore (he may reconnect later, and should not have a chat bubble)
        if (PlumeReceivers[i].Actor.isTyping)
        {
          playerId = C.PlayerReplicationInfo.PlayerID;
          for (j=0; j<PlumeReceivers.Length; j++)
          {
            if (PlumeReceivers[j].Controller != C)
              PlumeReceivers[j].Actor.ClientNotifyIsTyping(playerId, false);
          }
        }

        PlumeReceivers[i].Actor.Destroy();
        PlumeReceivers.Remove(i, 1);
        break;
      }
    }
  }

  super.NotifyLogout(C);
}

function ScoreKill (Controller killer, Controller killed)
{
  local int i;
  local CRZPlayerController pc;

  super.ScoreKill(killer, killed);

  if (killer == none || killer == killed)
    return;

  foreach WorldInfo.AllControllers(class'CRZPlayerController', PC)
  {
    if (!HasPovOfAttacker(pc, killer))
      continue;
    i = GetOrAddPlumeReceiver(pc);
    PlumeReceivers[i].Actor.PlayKillSound();
  }
}


static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
  local DmgPlumeConfigScreen configScreen;

  super.PopulateConfigView(ConfigView, MutatorDataProvider);

  configScreen = class'WorldInfo'.static.GetWorldInfo().Spawn(class'DmgPlumeConfigScreen');
  configScreen.PopulateConfigView(ConfigView, MutatorDataProvider);
}

defaultproperties
{
}