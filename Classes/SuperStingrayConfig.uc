class SuperStingrayConfig extends Object config(MutatH0r) perobjectconfig;


var config float DamagePlasma, DamageBeam, DamageCombo;
var config float KnockbackPlasma, KnockbackBeam, DamageRadius;
var config float TagDuration;
var config float DamageFactorSelf, DamageFactorSplash, LevitationSelf, LevitationOthers;
var config float FireIntervalPlasma, FireIntervalBeam;
var config LinearColor TagColor;
var config bool DrawDamageRadius;

function SetDefaults()
{
  if (DamagePlasma == 0)
    DamagePlasma = 35;
  if (DamageBeam == 0)
    DamageBeam = 45;
  if (DamageFactorSelf == 0)
    DamageFactorSelf = 1;
  
  if (KnockbackBeam == 0)
    KnockbackBeam = 20000;
  
  if (FireIntervalPlasma == 0)
    FireIntervalPlasma = 0.1667;
  if (FireIntervalBeam == 0)
    FireIntervalBeam = 0.77;

  if (TagColor.A == 0 && TagColor.R == 0 && TagColor.G == 0 && TagColor.B == 0)
  {
    TagColor.A = 255.0;
    TagColor.R = 0.0;
    TagColor.G = 128.0;
    TagColor.B = 0.0;
  }
}