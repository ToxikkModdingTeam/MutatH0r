class Roq3tConfig extends Object config(MutatH0r) perobjectconfig;

var config float Knockback;
var config float KnockbackFactorOthers;
var config float KnockbackFactorSelf;
var config float MinKnockbackVert;
var config float MaxKnockbackVert;
var config float FireInterval;
var config float DamageFactorDirect;
var config float DamageFactorSplash;
var config float DamageFactorSelf;
var config float DamageRadius;
var config bool DrawDamageRadius;

function SetDefaults()
{
  if (Knockback == 0)
    Knockback = 80000.0;
  if (KnockbackFactorOthers == 0)
    KnockbackFactorOthers = 1.0;
  if (KnockbackFactorSelf == 0)
    KnockbackFactorSelf = 1.0;
  if (MinKnockbackVert == 0)
    MinKnockbackVert = 0.0;
  if (MaxKnockbackVert == 0)
    MaxKnockbackVert = 1000000.0;
  if (FireInterval == 0)
    FireInterval = 1.0;
  if (DamageFactorDirect == 0)
    DamageFactorDirect = 1.0;
  if (DamageFactorSplash == 0)
    DamageFactorSplash = 1.0;
  if (DamageFactorSelf == 0)
    DamageFactorSelf = 1.0;
  if (DamageRadius == 0)
    DamageRadius = 220;
}