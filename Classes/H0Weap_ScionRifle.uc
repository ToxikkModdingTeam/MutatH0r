class H0Weap_ScionRifle extends CRZWeap_ScionRifle;

var CRZMutator_SuperStingray Mut;

simulated function PostBeginPlay()
{
  local CRZMutator_SuperStingray m; 

  super.PostBeginPlay();

  foreach WorldInfo.DynamicActors(class'CRZMutator_SuperStingray', m)
    Mut = m;
  ApplySettings();
}

simulated function ApplySettings()
{
  FireInterval[0] = Mut.FireIntervalPlasma;
  FireInterval[1] = Mut.FireIntervalBeam;
  InstantHitDamage[1] = Mut.DamageBeam;
  InstantHitMomentum[1] = Mut.KnockbackBeam;
  ShotCost[0] = Mut.ShotCostPlasma;
  ShotCost[1] = Mut.ShotCostBeam;
}

simulated function StartFire(byte fireModeNum)
{
  if (Mut.SwapButtons)
  {
    if (fireModeNum == 0) 
      fireModeNum = 1;
    else if (fireModeNum == 1) 
      fireModeNum = 0;
  }
  super.StartFire(fireModeNum);
}

simulated function StopFire(byte fireModeNum)
{
  if (Mut.SwapButtons)
  {
    if (fireModeNum == 0) 
      fireModeNum = 1;
    else if (fireModeNum == 1) 
      fireModeNum = 0;
  }
  super.StopFire(fireModeNum);
}

DefaultProperties
{
   AttachmentClass=Class'MutatH0r.H0Attachment_ScionRifle'
   TeamProjectiles(0)=Class'MutatH0r.H0Proj_ScionRifle_Red'
   TeamProjectiles(1)=Class'MutatH0r.H0Proj_ScionRifle'
   WeaponProjectiles(0)=Class'MutatH0r.H0Proj_ScionRifle'
   WeaponProjectiles(1)=none
}
