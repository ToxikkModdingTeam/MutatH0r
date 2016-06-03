// MutatH0r.CRZMutator_StimHead
// ----------------
// Scales Pawn head size depending on health + armor
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_StimHead extends UTMutator config (MutatH0r);


var config float MinSize;
var config float MaxSize;

function InitMutator(string Options, out string ErrorMessage)
{
	Super.InitMutator(Options, ErrorMessage);
	MinSize = FMax(MinSize, 0.5);
	MaxSize = FMin(MaxSize, 3.0);
	SetTimer(0.05, true);
}

function Timer()
{
	local UTPawn P;
	local float HeadScale;
	foreach WorldInfo.AllPawns(class'UTPawn', P)
	{
		HeadScale = (P.Health + P.VestArmor) / 100.0f;
		P.SetHeadScale(FClamp(HeadScale, MinSize, MaxSize));
	}
}

defaultproperties
{
	GroupNames[0]="HEADSIZE";
}