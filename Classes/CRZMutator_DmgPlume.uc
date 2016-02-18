class CRZMutator_DmgPlume extends Mutator config (MutatH0r);

// structures sent from server to clients

struct PlumeRepItem
{
  var vector Location;
  var int Value;
};

struct PlumeRepInfo
{
  var PlumeRepItem Plumes[16];
};

// server internal structures to aggregate damage within one tick for each client and victim

struct PlumeVictimInfo
{
  var Pawn Victim;
  var PlumeRepItem RepItem;
};

struct PlumeReceiver
{
  var Controller Controller;
  var DmgPlumeActor Actor;
  var array<PlumeVictimInfo> Victims;
};

// server
var array<PlumeReceiver> PlumeReceivers;


function PostBeginPlay()
{
  super.PostBeginPlay();

  if (Role == ROLE_Authority)
  {
    SetTickGroup(TG_PostAsyncWork);
    Enable('Tick');
  }
}


function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
  local int i, j;
  local PlayerController pc;
  
  super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

  pc = PlayerController(InstigatedBy);
  if (pc == none)
    return;
  
  // find or create plume receiver
  for (i=0; i<PlumeReceivers.Length; i++)
  {
    if (PlumeReceivers[i].Controller == InstigatedBy)
      break;
  }
  if (i >= PlumeReceivers.Length)
  {
    PlumeReceivers.Add(1);
    PlumeReceivers[i].Controller = InstigatedBy;
    PlumeReceivers[i].Actor = Spawn(class'DmgPlumeActor', pc);
  }

  // find or create plume for victim and aggregate damage
  for (j=0; j<PlumeReceivers[i].Victims.Length; j++)
  {
    if (PlumeReceivers[i].Victims[j].Victim == Injured)
      break;
  }
  if (j>=PlumeReceivers[i].Victims.Length)
  {
    PlumeReceivers[i].Victims.Add(1);
    PlumeReceivers[i].Victims[j].Victim = Injured;
    PlumeReceivers[i].Victims[j].RepItem.Location = Injured.Location + vect(0,0,1)*(Injured.CylinderComponent.CollisionHeight + 3);
  }
  PlumeReceivers[i].Victims[j].RepItem.Value += round(Damage * pc.Pawn.DamageScaling);
}

function Tick(float deltaTime)
{
  local int i, j;
  local PlumeReceiver rec;
  local PlumeRepInfo repInfo;

  if (Role != ROLE_Authority)
    return;

  for (i=0; i<PlumeReceivers.Length; i++)
  {
    rec = PlumeReceivers[i];
    if (rec.Victims.Length == 0)
      continue;
    
    for (j=0; j<rec.Victims.Length && j<ArrayCount(repInfo.Plumes); j++)
      repInfo.Plumes[j] = rec.Victims[j].RepItem;
    if (j < ArrayCount(repInfo.Plumes)) // mark as end-of-list
      repInfo.Plumes[j].Value = 0;
    rec.Actor.AddPlumes(repInfo);
    PlumeReceivers[i].Victims.Length = 0; // must use full path to set original struct member and not the local copy
  }
}

function NotifyLogout(Controller C)
{
  local int i;

  for (i=0; i<PlumeReceivers.Length; i++)
  {
    if (PlumeReceivers[i].Controller == C)
    {
      PlumeReceivers[i].Actor.Destroy();
      PlumeReceivers.Remove(i, 1);
      break;
    }
  }

  super.NotifyLogout(C);
}

DefaultProperties
{
}
