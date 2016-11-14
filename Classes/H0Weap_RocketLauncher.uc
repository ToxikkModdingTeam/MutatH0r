class H0Weap_RocketLauncher extends CRZWeap_RocketLauncher;

var CRZMutator_Roq3t Mut;

simulated function PostBeginPlay()
{
  super.PostBeginPlay();

  Mut = class'CRZMutator_Roq3t'.static.GetInstance();
  ApplySettings();
}

simulated function ApplySettings()
{
  FireInterval[0] = Mut.FireInterval;
  AmmoCount = Mut.InitialAmmo;
  MaxAmmoCount = Mut.MaxAmmo;
}

DefaultProperties
{
  AttachmentClass=Class'MutatH0r.H0Attachment_RocketLauncher'
  TeamProjectiles(0)=Class'MutatH0r.H0Proj_RocketLauncher'
  TeamProjectiles(1)=Class'MutatH0r.H0Proj_RocketLauncher'
  WeaponProjectiles(0)=Class'MutatH0r.H0Proj_RocketLauncher'
  WeaponProjectiles(1)=none
}
