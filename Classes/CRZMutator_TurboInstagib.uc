class CRZMutator_TurboInstagib extends CRZMutator_InstaBounce;

/*
 * Composite mutator for Turbo Instagib
 * 
 * - based on Instagib mutator
 * - disable stealth
 * - change gamespeed to 135%
 * - change gravity to -350 (to keep timing for movement the same)
 * */

simulated function PostBeginPlay()
{
  local CRZGame Game;

  super.PostBeginPlay();

  if (Role == ENetRole.ROLE_Authority)
  {
    WorldInfo.WorldGravityZ = -350;
    Game = CRZGame(WorldInfo.Game);
    Game.SetGameSpeed(1.35);
    Game.MinRespawnDelay = 0.5;
    Game.bAllowStealth = false;
    //Game.bForceRespawn = true;
  }
}

simulated function InitPreset(SuperStingrayConfig preset)
{
  super.InitPreset(preset);
  preset.KnockbackPlasma = 50*1000;
}

DefaultProperties
{
  GroupNames[0]="WEAPONMOD"
  GroupNames[1]="WEAPONRESPAWN"
  GroupNames[2]="STEALTH"
}
