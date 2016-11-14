class H0Proj_ScionRifle extends CRZProj_ScionRifle;

var CRZMutator_SuperStingray Mut;

simulated function PostBeginPlay()
{
  super.PostBeginPlay();

  Mut = class'CRZMutator_SuperStingray'.static.GetInstance();
  ApplySettings();
}

simulated function ApplySettings()
{
  Damage = Mut.DamagePlasma;
  DamageRadius = Mut.DamageRadius;
  MomentumTransfer = Mut.KnockbackPlasma;
  //DrawScale = Mut.DrawScalePlasma;
}

DefaultProperties
{
  Damage = 17
  DamageRadius = 120
  MomentumTransfer = 20000

  DrawScale=0.75;

  TeamIndex=1
  Name="Default__H0Proj_ScionRifle"
}
