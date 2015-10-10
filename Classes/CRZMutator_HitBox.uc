// MutatH0r.CRZMutator_HitBox
// ----------------
// draws the collision cylinder around all bots and detaches their controller
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_HitBox extends UTMutator config(MutatH0r);

var bool DrawCylinder;
var bool Crouch;
var bool DetachBots;

function InitMutator(string Options, out string ErrorMessage)
{
	Super.InitMutator(Options, ErrorMessage);

	DrawCylinder = true;
	//SetTimer(0.01, true);
}

function PreBeginPlay()
{
  base.PreBeginPlay();
  SetTickGroup(ETickingGroup.TG_PostUpdateWork);
  Enable('Tick');
}

function Tick(float DeltaTime)
{
  Timer();
}

function Timer()
{
	local UTPawn P;

	foreach WorldInfo.AllPawns(class'UTPawn', P)
	{
		if (DetachBots && P.Controller != None && PlayerController(P.Controller) == None)
			P.DetachFromController(true);

		if (DrawCylinder && PlayerController(P.Controller) == none)
		{
			P.DrawDebugCylinder(
				P.CylinderComponent.GetPosition() + vect(0,0,1) * P.CylinderComponent.CollisionHeight, 
				P.CylinderComponent.GetPosition() + vect(0,0,-1) * P.CylinderComponent.CollisionHeight, 
				P.CylinderComponent.CollisionRadius,
				16, 255, 255, 0, false);
		}
	}
}

function Mutate(string MutateString, PlayerController Sender)
{
	if (MutateString == "dump")
		DumpInformation();
	else if (MutateString == "hitbox")
		DrawCylinder = !DrawCylinder;
	else if (MutateString == "crouch")
		ToggleCrouchForAllBots();
	else if (MutateString == "detach")
		DetachBots = !DetachBots;
	else if (MutateString == "upd")
		DummyMove();
	else if (Left(MutateString, 4) == "pos ")
		ChangePos(float(Mid(MutateString,4)));
	else if (Left(MutateString, 4) == "cyl ")
		ChangeHeight(float(Mid(MutateString,4)));
	else if (Left(MutateString, 4) == "off ")
		ChangeOffset(float(Mid(MutateString,4)));
	else
		Super.Mutate(MutateString, Sender);
}

function DumpInformation()
{
	local UTPawn P;

	foreach WorldInfo.AllPawns(class'UTPawn', P)
	{
		if (PlayerController(P.Controller) != None)
			continue;
		`log("Pawn: " $ P.Name);
		`log("  Location=" $ P.Location $ "; BaseTranslationOffset=" $ P.BaseTranslationOffset $ "; MeshTranslationOffset=" $ P.MeshTranslationOffset);
		`log("  CrouchTranslationOffset=" $ P.CrouchTranslationOffset $ "; CrouchHeight=" $ P.CrouchHeight $ "; CrouchMeshZOffset=" $ P.CrouchMeshZOffset);
		`log("  Cylinder: Position=" $ P.CylinderComponent.GetPosition() $ "; CollHeight=" $ P.CylinderComponent.CollisionHeight);
		break;
	}
}

function ToggleCrouchForAllBots()
{
	local UTPawn P;

	Crouch = !Crouch;
	foreach WorldInfo.AllPawns(class'UTPawn', P)
	{
		if (PlayerController(P.Controller) != None)
			continue;
		if (Crouch && !P.bIsCrouched)
			P.ShouldCrouch(true);
		else if (!Crouch && P.bIsCrouched)
			P.UnCrouch();
	}		
}

function ChangePos(float delta)
{
	local UTPawn P;

	Crouch = !Crouch;
	foreach WorldInfo.AllPawns(class'UTPawn', P)
	{
		if (PlayerController(P.Controller) == None)
			P.Move(vect(0,0,1) * delta);
	}		
}

function ChangeHeight(float delta)
{
	local UTPawn P;

	Crouch = !Crouch;
	foreach WorldInfo.AllPawns(class'UTPawn', P)
	{
		if (PlayerController(P.Controller) != None)
			continue;
		P.CylinderComponent.SetCylinderSize(P.CylinderComponent.CollisionRadius, P.CylinderComponent.CollisionHeight + delta);
		P.Move(vect(0,0,1));
		P.Move(vect(0,0,-1));
	}		
}

function ChangeOffset(float delta)
{
	local UTPawn P;

	Crouch = !Crouch;
	foreach WorldInfo.AllPawns(class'UTPawn', P)
	{
		if (PlayerController(P.Controller) != None)
			continue;
		P.BaseTranslationOffset += delta;
		P.Move(vect(0,0,1));
		P.Move(vect(0,0,-1));
	}		
}

function DummyMove()
{
	local UTPawn P;

	foreach WorldInfo.AllPawns(class'UTPawn', P)
	{
		if (PlayerController(P.Controller) != None)
			continue;
		P.Move(vect(0,0,1));
		P.Move(vect(0,0,-1));
	}
}

defaultproperties
{
	GroupNames[0]="HITBOX";
}