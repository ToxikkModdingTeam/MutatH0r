class CRZMutator_1v1 extends CRZMutator;

/*
 * Composite mutator for duel gameplay in combination with ArchRival gametype
 * 
 * - add RegenDecay mutator with armor and health decay of 1/sec if above 100
 * - prevent spawn of max damage, speed shot and hellraiser
 * - delay initial spawn of mega armor and mega health by 30sec
 * - delay initial spawn of 50 armor by 15sec
 * - respawn 50 armor every 30sec (instead of 60)
 * 
 * NOTE: this class is NOT using PickupFactory.bIsSuperItem, but using a timer instead to allow
 * an arbitrary initial spawn delay and not just a full respawn interval
 * */

var CRZMutator_RegenDecay decay;
var float initialSuperItemSpawnDelay;
var float initial50ArmorSpawnDelay;

function PostBeginPlay()
{
  super.PostBeginPlay();
  decay = Spawn(class'CRZMutator_RegenDecay', self);
  
  //worldInfo.Game.MaxPlayers = 2;

  SetMegaItemState('Disabled');
  Set50ArmorState('Disabled');
}

function InitMutator(string options, out string errorMsg)
{
  local CRZGame game;

  super.InitMutator(options, errorMsg);
  decay.InitMutator(options, errorMsg);

  decay.HealthRegenLimit=0;
  decay.HealthRegenAmount=0;
  decay.HealthDecayUpperLimit=150;
  decay.HealthDecayUpperAmount=1;
  decay.HealthDecayLowerLimit=150;
  decay.HealthDecayLowerAmount=1;
  decay.ArmorRegenLimit=0;
  decay.ArmorRegenAmount=0;
  decay.ArmorDecayLimit=100;
  decay.ArmorDecayAmount=1;

  game = CRZGame(WorldInfo.Game);
  if (game != none)
  {
    //game.MinRespawnDelay = 1.0;
    //game.bForceRespawn = true;
    //game.SpawnProtectionTime = 0.0;
    game.bPlayersMustBeReady = true;
  }
}

function bool CheckReplacement(Actor other)
{
  local CRZWeaponPickupFactory wf;
  local CRZArmorPickup_ShieldVest armor;

  if (other.IsA('CRZPickupFactory_Steroids')) return false; // max damage
  if (other.IsA('CRZPickupFactory_Adrenaline')) return false; // speed shot

  wf = CRZWeaponPickupFactory(other);
  if (wf != none && wf.WeaponPickupClass == class'CRZWeap_Hellraiser') return false;

  // change respawn interval of the 50 armor (but not its ShieldVestBig subclass - the 100 armor)
  armor = CRZArmorPickup_ShieldVest(other);
  if (armor != none && armor.class == class'CRZArmorPickup_ShieldVest')
    armor.RespawnTime = 30.00;

  return super.CheckReplacement(other);
}

function MatchStarting()
{
  super.MatchStarting();
  SetTimer(initialSuperItemSpawnDelay, false, 'EnableMegaItems');
  SetTimer(initial50ArmorSpawnDelay, false, 'Enable50Armor');
}

function EnableMegaItems()
{
  SetMegaItemState('Pickup');
}

function Enable50Armor()
{
  Set50ArmorState('Pickup');
}

function SetMegaItemState(name state)
{
  local CRZPickupFactory_SuperHealth health100;
  local CRZArmorPickup_ShieldVestBig armor100;

  foreach WorldInfo.AllActors(class'CRZPickupFactory_SuperHealth', health100)
  {
    if (state == 'Pickup')
    {
      health100.RespawnEffect();
      health100.SetCollision(true,true);
    }
    health100.GotoState(state);
  }

  foreach WorldInfo.AllActors(class'CRZArmorPickup_ShieldVestBig', armor100)
  {
    if (state == 'Pickup')
    {
      armor100.RespawnEffect();
      armor100.SetCollision(true,true);
    }
    armor100.GotoState(state);
  }
}

function Set50ArmorState(name state)
{
  local CRZArmorPickup_ShieldVest armor;

  foreach WorldInfo.AllActors(class'CRZArmorPickup_ShieldVest', armor)
  {
    if (armor.class != class'CRZArmorPickup_ShieldVest') // ignore subclasses like ShieldVestBig
      continue;
    if (state == 'Pickup')
    {
      armor.RespawnEffect();
      armor.SetCollision(true,true);
    }
    armor.GotoState(state);
  }
}


DefaultProperties
{
  initialSuperItemSpawnDelay = 30;
  initial50ArmorSpawnDelay = 15;
}
