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

function PostBeginPlay()
{
	local UTGame Game;
	Super.PostBeginPlay();

	Game = UTGame(WorldInfo.Game);
	if (Game != None)
	{
		Game.DefaultInventory.Length = 0;
    if (Ravager)
		  Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_Impactor", class'Class')));
    if (Raven)
      Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_PistolAW29", class'Class')));
    if (Bullcraft)
      Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_ShotgunSG12", class'Class')));
    if (Violator)
      Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_PulseRifle", class'Class')));
    if (Falcon)
      Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_SniperRifle", class'Class')));
    if (Stingray)
	    Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_ScionRifle", class'Class')));
    if (Dragoneer)
      Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_FlameThrower", class'Class')));
    if (Cerberus)
		  Game.DefaultInventory.AddItem(class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_RocketLauncher", class'Class')));
	}

  if (InfiniteAmmo)
  {
    // UTInvManager.bInfiniteAmmo only resets the ammo count back to MaxValue when it goes below 0, which prevents shots that need more than 1 ammo
    // Without the SDKK and the ability to subclass the weapons, the only way to modify them on the client side is through Tick
    SetTickGroup(ETickingGroup.TG_DuringAsyncWork);
    Enable('Tick');
  }
}

function bool CheckReplacement(Actor Other)
{
  // toxikk doesn't derive from UTAmmoPickupFactory, so check for it the dirty way
  if (InfiniteAmmo && Other.IsA('UTItemPickupFactory') && instr(string(Other.class), "CRZAmmo_") == 0)
    return false;

  if (!AllowWeaponPickups && (Other.IsA('UTWeaponPickupFactory') || Other.IsA('UTWeaponLocker')))
    return false;

  return super.CheckReplacement(Other);
}

simulated function Tick(float DeltaTime)
{
  local UTWeapon w;

  foreach WorldInfo.DynamicActors(class'UTWeapon', w)
  {
    w.ShotCost[0] = 0;
    w.ShotCost[1] = 0;
  }
}

defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true
	GroupNames[0]="WEAPONMOD"
	GroupNames[1]="WEAPONRESPAWN"
}
