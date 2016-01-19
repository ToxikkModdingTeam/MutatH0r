// MutatH0r.CRZMutator_InstaBounce
// ----------------
// Stingray Plasma bounces with no damage, Beam is insta-kill
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_InstaBounce extends UTMutator config (MutatH0r);

const KnockbackBall = 85000.0;
const StingrayClassPath = "Cruzade.CRZWeap_ScionRifle";

simulated event PreBeginPlay()
{
  super.PreBeginPlay();
  SetTickGroup(ETickingGroup.TG_PreAsyncWork);
  Enable('Tick');
}

function PostBeginPlay()
{
	local UTGame Game;

	Super.PostBeginPlay();

	Game = UTGame(WorldInfo.Game);
  Game.DefaultInventory.Length = 1;
	Game.DefaultInventory[0] = class<Weapon>(DynamicLoadObject(StingrayClassPath, class'Class'));
}

function bool CheckReplacement(Actor Other)
{
	return !Other.IsA('PickupFactory');
}

simulated function Tick(float DeltaTime)
{
  local Projectile proj;
  local UTWeapon w;
  local Actor a;
  local string className;
  local int count;

  foreach WorldInfo.DynamicActors(class'Actor', a)
  {
    ++count;
    className = string(a.Class);
    if (instr(className, "CRZProj_Scion") == 0) // handle blue and red projectile
    {
      proj = Projectile(a);
      if (proj.Damage != 0.01)
      {
        proj.Damage = 0.01;  // damage 0 would cause the explosion/knockback code to be skipped, so we use 0.01 here
        proj.DamageRadius = 220;
        proj.MomentumTransfer = KnockbackBall;
      }
    }
    else if (className == "CRZWeap_ScionRifle")
    {
      w = UTWeapon(a);
      w.ShotCost[0] = 0;
      w.ShotCost[1] = 0;
      w.FireInterval[0] = 0.5;
      w.InstantHitDamage[1] = 1000;
    }
  }
}


defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true
	GroupNames[0]="WEAPONMOD"
	GroupNames[1]="WEAPONRESPAWN"
  GroupNames[2]="STINGRAY"
}