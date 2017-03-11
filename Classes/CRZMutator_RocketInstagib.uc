class CRZMutator_RocketInstagib extends CRZMutator_Roq3t;

/*
 * Composite mutator for Rocket Instagib
 * 
 * - Roq3t mutator as base class to change damage and knockback of Cerberus
 * - Loadout mutator to spawn with rockets and disable all other weapons
 * - NoStealth
 * 
 * */

var CRZMutator_Loadout loadout;
var CRZMutator_NoStealth noStealth;
var CRZMutator_ItemSpawn itemSpawn;

simulated function PostBeginPlay()
{
  local CRZGame Game;

  super.PostBeginPlay();
  loadout = Spawn(class'CRZMutator_Loadout', self);
  noStealth = Spawn(class'Cruzade.CRZMutator_NoStealth');
  itemSpawn = Spawn(class'CRZMutator_ItemSpawn', self);

  Game = CRZGame(WorldInfo.Game);
  Game.bAllowStealth = false;
  Game.MinRespawnDelay = 0.5;
  //Game.bForceRespawn = true;  
}

function InitMutator(string options, out string errorMsg)
{
  super.InitMutator(options, errorMsg);
  loadout.InitMutator("?Loadout=8A", errorMsg); // 8=cerberus, A=infinite ammo. everything else is disabled
  noStealth.InitMutator(options, errorMsg);

  itemSpawn.InitMutator(options, errorMsg);
  itemSpawn.bAmmo = false;
  itemSpawn.bArmorShard = false;
  itemSpawn.bSmallArmor = false;
  itemSpawn.bMegaArmor = false;
  itemSpawn.bHealthVial = false;
  itemSpawn.bMegaHealth = false;
  itemSpawn.bDroppedWeapon = false;
  itemSpawn.bJetPack = false;
  itemSpawn.bMaxDamage = false;
  itemSpawn.bSpeedShot = false;

  self.Speed = 1800;
  self.Knockback = 85000;
  self.KnockbackFactorOthers = 1.0;
  self.KnockbackFactorself = 1.0;
  self.MinKnockbackVert = 600;
  self.MaxKnockbackVert = 1000000;
  self.FireInterval = 1.0;
  self.DamageRadius = 180;
  self.DamageFactorDirect = 10.0;
  self.DamageFactorSplash = 0.10;
  self.DamageFactorself = 1.0;
}

function bool CheckReplacement(Actor other)
{
  return super.CheckReplacement(other) 
    && loadout.CheckReplacement(other) 
    && noStealth.CheckReplacement(other)
    && itemSpawn.CheckReplacement(other);
}

defaultproperties
{
  //GroupNames[0]="WEAPONMOD"
  //GroupNames[1]="WEAPONRESPAWN"
  //GroupNames[2]="STEALTH"
}