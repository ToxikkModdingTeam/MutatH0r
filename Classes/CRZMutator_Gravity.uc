// MutatH0r.CRZMutator_Gravity
// ----------------
// Sets a custom gravity value
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_Gravity extends UTMutator config (MutatH0r);

var config float GravityZ;

function InitMutator(string Options, out string ErrorMessage)
{
	WorldInfo.WorldGravityZ = GravityZ;
	Super.InitMutator(Options, ErrorMessage);
}

defaultproperties
{
	GroupNames[0]="JUMPING"
}
