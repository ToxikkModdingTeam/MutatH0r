class DmgPlumeConfig extends Object config(MutatH0r) perobjectconfig;

// client configuration

struct PlumeColor
{
  var config int Damage;
  var config Color Color;
};

struct PlumeSpeed
{
  var config int Fixed;
  var config int Random;
};

var config bool bValidConfig;
var config bool bEnablePlumes;
var config float ScaleSmall;
var config float ScaleLarge;
var config float ScaleDistance;
var config PlumeSpeed SpeedX;
var config PlumeSpeed SpeedY;
var config float TimeToLive;
var config array<PlumeColor> PlumeColors;

var config bool bEnableCrosshairNames;

// Fallback to create presets when mutator was auto-downloaded from a server and there is no local .ini
function SetDefaults(string preset)
{
  preset = locs(preset);
  if (preset == "off")
  {
    bEnablePlumes = false;
    bEnableCrosshairNames = false;
  }
  else if (preset == "large")
  {
    bEnablePlumes=true;
    bEnableCrosshairNames = true;
    ScaleSmall=0.5;
    ScaleLarge=2.0;
    ScaleDistance=500;
    SpeedX.Fixed = 200;
    SpeedX.Random = 100;
    SpeedY.Fixed = 300;
    SpeedY.Random = 100;
    TimeToLive=1.25;
  }
  else
  {
    bEnablePlumes=true;
    bEnableCrosshairNames = true;
    ScaleSmall=0.4;
    ScaleLarge=1.0;
    ScaleDistance=300;
    SpeedX.Fixed = 100;
    SpeedX.Random = 30;
    SpeedY.Fixed = 200;
    SpeedY.Random = 40;
    TimeToLive=1.25;
  }

  PlumeColors.AddItem(CreatePlumeColor(0,  255, 255, 255));
  PlumeColors.AddItem(CreatePlumeColor(20, 255, 255, 160));
  PlumeColors.AddItem(CreatePlumeColor(35, 255, 255,  64));
  PlumeColors.AddItem(CreatePlumeColor(45, 100, 255, 100));
  PlumeColors.AddItem(CreatePlumeColor(70, 255,  65, 255));
  PlumeColors.AddItem(CreatePlumeColor(100,255,  48,  48));
}

function PlumeColor CreatePlumeColor(int damage, int r, int g, int b)
{
  local PlumeColor pc;
  pc.Damage = damage;
  pc.Color.R = r;
  pc.Color.G = g;
  pc.Color.B = b;
  pc.Color.A = 255;
  return pc;
}

defaultproperties
{
}