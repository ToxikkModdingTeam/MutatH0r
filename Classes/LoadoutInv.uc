class LoadoutInv extends Inventory;

simulated function PostBeginPlay()
{
  super.PostBeginPlay();

  // when the inventory gets replicated, the client's Pawn isn't ready yet to switch to a weapon
  SetTimer(0.01, true);
}

simulated function Timer()
{
  local Pawn p;

  p = Pawn(InvManager.Owner);
  InvManager.SwitchToBestWeapon();
  if (p != none && p.Weapon != none || InvManager.PendingWeapon != none)
    ClearTimer();
}

DefaultProperties
{
}
