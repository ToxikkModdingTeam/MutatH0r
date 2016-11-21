class SuperStingrayConfig extends Object config(MutatH0r) perobjectconfig;

var config bool SwapButtons;
var config float DamagePlasma, DamageBeam, DamageCombo;
var config float KnockbackPlasma, KnockbackBeam, DamageRadius;
var config float TagDuration;
var config float DamageFactorSelf, DamageFactorSplash, LevitationSelf, LevitationOthers;
var config float FireIntervalPlasma, FireIntervalBeam, DrawScalePlasma;
var config LinearColor TagColor;
var config bool DrawDamageRadius;
var config array<int> ShotCost;

function SetDefaults()
{
  if (DamagePlasma == 0)
  {
    DamagePlasma = 12;
    if (DamageCombo == 0)
      DamageCombo = 8;
    if (KnockbackPlasma == 0)
      KnockbackPlasma = 15000;
  }
  if (DamageBeam == 0)
    DamageBeam = 45;
  if (DamageFactorSelf == 0)
    DamageFactorSelf = 1;
  if (DrawScalePlasma == 0)
    DrawScalePlasma = 1.1;
  
  if (KnockbackBeam == 0)
    KnockbackBeam = 20000;
  
  if (FireIntervalPlasma == 0)
    FireIntervalPlasma = 0.125;
  if (FireIntervalBeam == 0)
    FireIntervalBeam = 0.77;

  if (TagColor.A == 0 && TagColor.R == 0 && TagColor.G == 0 && TagColor.B == 0)
  {
    TagColor.A = 255.0;
    TagColor.R = 0.0;
    TagColor.G = 128.0;
    TagColor.B = 0.0;
  }

  if (ShotCost.length < 1)
    ShotCost.AddItem(class'CRZWeap_ScionRifle'.default.ShotCost[0]);
  if (ShotCost.length < 2)
    ShotCost.AddItem(class'CRZWeap_ScionRifle'.default.ShotCost[1]);
}