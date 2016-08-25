class H0Proj_RocketLauncher extends CRZProj_RocketLauncher;

var CRZMutator_Roq3t Mut;

simulated function PostBeginPlay()
{
  super.PostBeginPlay();
 
  Mut = class'CRZMutator_Roq3t'.static.GetInstance();
  ApplySettings();
}


simulated function ApplySettings()
{
  Speed = Mut.Speed;
  MaxSpeed = fmax(MaxSpeed, Mut.Speed);
  DamageRadius = Mut.DamageRadius;
  MomentumTransfer = Mut.Knockback;
}

DefaultProperties
{
  //Damage = 100
  //DamageRadius = 220
  //MomentumTransfer = 85000
  //TeamIndex=1
  Name="Default__H0Proj_RocketLauncher"
}
