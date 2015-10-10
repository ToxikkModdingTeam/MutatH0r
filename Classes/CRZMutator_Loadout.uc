class CRZMutator_Loadout extends UTMutator	config(MutatH0r);

function PostBeginPlay()
{
	local UTGame Game;

	Super.PostBeginPlay();

	Game = UTGame(WorldInfo.Game);
	if (Game != None)
	{
		Game.DefaultInventory.Length = 2;
		Game.DefaultInventory[0] = class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_ScionRifle", class'Class'));
		Game.DefaultInventory[1] = class<Weapon>(DynamicLoadObject("Cruzade.CRZWeap_RocketLauncher", class'Class'));
	}

  SetTickGroup(ETickingGroup.TG_DuringAsyncWork);
  Enable('Tick');
}

function bool CheckReplacement(Actor Other)
{
	return !Other.IsA('UTWeaponPickupFactory');
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
