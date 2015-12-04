class CRZMutator_Loadout extends UTMutator config(MutatH0r);

var config bool Ravager;
var config bool Raven;
var config bool Bullcraft;
var config bool Violator;
var config bool Falcon;
var config bool Stingray;
var config bool Dragoneer;
var config bool Cerberus;
var config bool AllowWeaponPickups;
var config bool InfiniteAmmo;
var config bool RandomWeapon;
var int mask;

//replication
//{
//  if (Role == ROLE_Authority && (bNetInitial || bNetDirty))
//    InfiniteAmmo;
//}

function PostBeginPlay()
{
	Super.PostBeginPlay();

  if (InfiniteAmmo)
  {
    // UTInvManager.bInfiniteAmmo only resets the ammo count back to MaxValue when it goes below 0, which prevents shots that need more than 1 ammo
    // Without the SDKK and the ability to subclass the weapons, the only way to modify them on the client side is through Tick
    SetTickGroup(ETickingGroup.TG_DuringAsyncWork);
    Enable('Tick');
  }
}

function InitMutator(string options, out string error)
{
  local int idx;

  idx = instr(caps(options), "?LOADOUTFLAGS=");
  if (idx >= 0)
  {
    mask = int(mid(options, idx + 14));
    InfiniteAmmo = (mask & 0x1000) != 0;
    RandomWeapon = (mask & 0x2000) != 0;
    mask = mask & 0x0FFF;
  }
  else
  {
    if (Ravager) mask = mask | 0x0001;
    if (Raven) mask = mask | 0x0002;
    if (Bullcraft) mask = mask | 0x0004;
    if (Violator) mask = mask | 0x0008;
    if (Falcon) mask = mask | 0x0010;
    if (Stingray) mask = mask | 0x0020;
    if (Dragoneer) mask = mask | 0x0040;
    if (Cerberus) mask = mask | 0x0080;
  }

  SetDefaultInventory(mask);
}

function SetDefaultInventory(int m)
{
	local UTGame Game;
	Game = UTGame(WorldInfo.Game);
	if (Game != None)
	{
		Game.DefaultInventory.Length = 0;
    if ((m & 0x0001) != 0)
		  Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_Impactor", class'Class')));
    if ((m & 0x0002) != 0)
      Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_PistolAW29", class'Class')));
    if ((m & 0x0004) != 0)
      Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_ShotgunSG12", class'Class')));
    if ((m & 0x0008) != 0)
      Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_PulseRifle", class'Class')));
    if ((m & 0x0010) != 0)
      Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_SniperRifle", class'Class')));
    if ((m & 0x0020) != 0)
	    Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_ScionRifle", class'Class')));
    if ((m & 0x0040) != 0)
      Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_FlameThrower", class'Class')));
    if ((m & 0x0080) != 0)
		  Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_RocketLauncher", class'Class')));
	}
}

function bool CheckReplacement(Actor Other)
{
  local UTPawn pawn;
  local array<int> enabledLoadouts;
  local int m;

  // toxikk doesn't derive from UTAmmoPickupFactory, so check for it the dirty way
  if (InfiniteAmmo && Other.IsA('UTItemPickupFactory') && instr(string(Other.class), "CRZAmmo_") == 0)
    return false;

  if (!AllowWeaponPickups && (Other.IsA('UTWeaponPickupFactory') || Other.IsA('UTWeaponLocker')))
    return false;

  if (RandomWeapon)
  {
    pawn = UTPawn(Other);
    if (pawn != None)
    {
      for (m = 0x0001; m < 0x0100; m = m << 1)
      {
        if ((mask & m) != 0)
          enabledLoadouts.AddItem(m);
      }
      m = enabledLoadouts[rand(enabledLoadouts.Length)];
      SetDefaultInventory(m);
    }
  }

  return super.CheckReplacement(Other);
}

simulated function Tick(float DeltaTime)
{
  local UTWeapon w;

  if (InfiniteAmmo)
  {
    foreach WorldInfo.DynamicActors(class'UTWeapon', w)
    {
      w.ShotCost[0] = 0;
      w.ShotCost[1] = 0;
    }
  }
}

defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true
	GroupNames[0]="WEAPONMOD"
	GroupNames[1]="WEAPONRESPAWN"
}
