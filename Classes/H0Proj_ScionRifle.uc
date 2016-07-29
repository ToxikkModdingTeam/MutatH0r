class H0Proj_ScionRifle extends CRZProj_ScionRifle;

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
  Damage = Mut.DamagePlasma;
  DamageRadius = Mut.DamageRadius;
  MomentumTransfer = Mut.KnockbackPlasma;
}

DefaultProperties
{
   Damage = 17
   DamageRadius = 120
   MomentumTransfer = 20000

   TeamIndex=1
   Name="Default__H0Proj_ScionRifle"
}
