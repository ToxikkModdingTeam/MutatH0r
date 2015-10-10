// MutatH0r.CRZMutator_LinkGun
// ----------------
// Replaces the Dragoneer with the UT LinkGun
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_LinkGun extends UTMutator;


function PreBeginPlay()
{
	local UTWeaponPickupFactory F;

	foreach WorldInfo.AllActors(class'UTWeaponPickupFactory', F)
	{
		if (string(F.WeaponPickupClass) == "CRZWeap_FlameThrower")
			F.WeaponPickupClass = class'UTWeap_LinkGun';
	}
}